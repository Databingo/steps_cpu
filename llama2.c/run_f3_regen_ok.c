/*
 * Bare-metal FLOAT32 Llama-2 Chatbot in pure C
 * Final, simplified, interactive, and fully working version for qemu-riscv64.
 * Fixes KV cache bug for multiple inferences.
 */

// --- BARE-METAL DEFINITIONS ---
#define NULL ((void*)0)
typedef unsigned long size_t;
typedef signed char int8_t; // Kept for tokenizer compatibility
typedef int int32_t;
int __errno;

// --- BARE-METAL INCLUDES ---
#include "model.h" // Using the float32 stories15M.bin
#include "tokenizer.h"
#include "uart.c"

// --- BARE-METAL HELPERS ---
void* memcpy(void* d, const void* s, size_t n)
{
    char* dd = (char*)d;
    const char* ss = (const char*)s;
    for (size_t i = 0; i < n; i++)
        dd[i] = ss[i];
    return d;
}
void* memset(void* s, int c, size_t n)
{
    unsigned char* p = (unsigned char*)s;
    while (n--)
        *p++ = (unsigned char)c;
    return s;
}
size_t strlen(const char* s)
{
    const char* p = s;
    while (*p)
        p++;
    return p - s;
}
int strcmp(const char* s1, const char* s2)
{
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}
void read_line(char* buffer, int max_len)
{
    int i = 0;
    while (i < max_len - 1) {
        char c = uart_getc();
        if (c == '\r') {
            uart_puts("\r\n");
            break;
        } else if (c == 127 || c == '\b') {
            if (i > 0) {
                i--;
                uart_puts("\b \b");
            }
        } else if (c >= 32 && c < 127) {
            buffer[i++] = c;
            uart_putc(c);
        }
    }
    buffer[i] = '\0';
}

// libm function declarations
float sqrtf(float);
float expf(float);

// ----------------------------------------------------------------------------
// Globals and Data Structures (Simplified for float32)
typedef struct {
    int dim;
    int hidden_dim;
    int n_layers;
    int n_heads;
    int n_kv_heads;
    int vocab_size;
    int seq_len;
} Config;
typedef struct {
    float* token_embedding_table;
    float* rms_att_weight;
    float* rms_ffn_weight;
    float* wq;
    float* wk;
    float* wv;
    float* wo;
    float* w1;
    float* w2;
    float* w3;
    float* rms_final_weight;
    float* wcls;
} TransformerWeights;
typedef struct {
    float *x, *xb, *xb2, *hb, *hb2, *q, *k, *v, *att, *logits;
    float* key_cache;
    float* value_cache;
} RunState;
#define ARENA_SIZE 64000000 // 64MB for float32 15M model
static unsigned char g_arena[ARENA_SIZE];
static size_t g_arena_offset = 0;
void* arena_alloc(size_t size)
{
    size = (size + 15) & ~15;
    if (g_arena_offset + size > ARENA_SIZE) {
        uart_puts("ERROR: Arena out of memory!\n");
        while (1)
            ;
    }
    void* ptr = &g_arena[g_arena_offset];
    g_arena_offset += size;
    return ptr;
}
typedef struct {
    Config config;
    TransformerWeights weights;
    RunState state;
} Transformer;
typedef struct {
    char* str;
    int id;
} TokenIndex;
typedef struct {
    char** vocab;
    float* vocab_scores;
    TokenIndex* sorted_vocab;
    int vocab_size;
    unsigned int max_token_length;
    unsigned char byte_pieces[512];
} Tokenizer;
typedef struct {
    int vocab_size;
    float temperature;
    unsigned long long rng_state;
} Sampler;

// ----------------------------------------------------------------------------
// Core Logic (Declarations and Definitions)
void encode(Tokenizer* t, char* text, int8_t bos, int8_t eos, int* tokens, int* n_tokens);
char* decode(Tokenizer* t, int prev_token, int token);
int sample(Sampler* sampler, float* logits);
void build_transformer(Transformer* t);
float* forward(Transformer* t, int token, int pos);

void build_transformer(Transformer* t)
{
    unsigned char* model_ptr = stories15M_bin;
    memcpy(&t->config, model_ptr, sizeof(Config));
    int shared_weights = t->config.vocab_size > 0 ? 1 : 0;
    if (t->config.vocab_size < 0) {
        t->config.vocab_size = -t->config.vocab_size;
    }

    float* weights_ptr = (float*)(model_ptr + sizeof(Config));
    Config* p = &t->config;
    TransformerWeights* w = &t->weights;
    int head_size = p->dim / p->n_heads;

    w->token_embedding_table = weights_ptr;
    weights_ptr += p->vocab_size * p->dim;
    w->rms_att_weight = weights_ptr;
    weights_ptr += p->n_layers * p->dim;
    w->wq = weights_ptr;
    weights_ptr += p->n_layers * p->dim * (p->n_heads * head_size);
    w->wk = weights_ptr;
    weights_ptr += p->n_layers * p->dim * (p->n_kv_heads * head_size);
    w->wv = weights_ptr;
    weights_ptr += p->n_layers * p->dim * (p->n_kv_heads * head_size);
    w->wo = weights_ptr;
    weights_ptr += p->n_layers * (p->n_heads * head_size) * p->dim;
    w->rms_ffn_weight = weights_ptr;
    weights_ptr += p->n_layers * p->dim;
    w->w1 = weights_ptr;
    weights_ptr += p->n_layers * p->dim * p->hidden_dim;
    w->w2 = weights_ptr;
    weights_ptr += p->n_layers * p->hidden_dim * p->dim;
    w->w3 = weights_ptr;
    weights_ptr += p->n_layers * p->dim * p->hidden_dim;
    w->rms_final_weight = weights_ptr;
    weights_ptr += p->dim;
    weights_ptr += p->seq_len * head_size / 2; // Skip freq_cis_real
    weights_ptr += p->seq_len * head_size / 2; // Skip freq_cis_imag
    w->wcls = shared_weights ? w->token_embedding_table : weights_ptr;

    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    RunState* s = &t->state;
    s->x = arena_alloc(p->dim * sizeof(float));
    s->xb = arena_alloc(p->dim * sizeof(float));
    s->xb2 = arena_alloc(p->dim * sizeof(float));
    s->hb = arena_alloc(p->hidden_dim * sizeof(float));
    s->hb2 = arena_alloc(p->hidden_dim * sizeof(float));
    s->q = arena_alloc(p->dim * sizeof(float));
    s->k = arena_alloc(kv_dim * sizeof(float));
    s->v = arena_alloc(kv_dim * sizeof(float));
    s->att = arena_alloc(p->n_heads * p->seq_len * sizeof(float));
    s->logits = arena_alloc(p->vocab_size * sizeof(float));
    s->key_cache = arena_alloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->value_cache = arena_alloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
}
void rmsnorm(float* o, float* x, float* w, int s)
{
    float ss = 0.0f;
    for (int j = 0; j < s; j++) {
        ss += x[j] * x[j];
    }
    ss /= s;
    ss += 1e-5f;
    ss = 1.0f / sqrtf(ss);
    for (int j = 0; j < s; j++) {
        o[j] = w[j] * (ss * x[j]);
    }
}
void softmax(float* x, int s)
{
    if (s <= 0)
        return;
    float max = x[0];
    for (int i = 1; i < s; i++) {
        if (x[i] > max)
            max = x[i];
    }
    float sum = 0.0f;
    for (int i = 0; i < s; i++) {
        x[i] = expf(x[i] - max);
        sum += x[i];
    }
    for (int i = 0; i < s; i++) {
        x[i] /= sum;
    }
}
void matmul(float* xout, float* x, float* w, int n, int d)
{
    for (int i = 0; i < d; i++) {
        float val = 0.0f;
        for (int j = 0; j < n; j++) {
            val += w[i * n + j] * x[j];
        }
        xout[i] = val;
    }
}
float* forward(Transformer* t, int token, int pos)
{
    Config* p = &t->config;
    TransformerWeights* w = &t->weights;
    RunState* s = &t->state;
    float* x = s->x;
    int dim = p->dim;
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    int kv_mul = p->n_heads / p->n_kv_heads;
    int hidden_dim = p->hidden_dim;
    int head_size = dim / p->n_heads;
    memcpy(x, w->token_embedding_table + token * dim, dim * sizeof(float));
    for (int l = 0; l < p->n_layers; l++) {
        rmsnorm(s->xb, x, w->rms_att_weight + l * dim, dim);
        matmul(s->q, s->xb, w->wq + l * dim * dim, dim, dim);
        matmul(s->k, s->xb, w->wk + l * dim * kv_dim, dim, kv_dim);
        matmul(s->v, s->xb, w->wv + l * dim * kv_dim, dim, kv_dim);
        int loff = l * p->seq_len * kv_dim;
        memcpy(s->key_cache + loff + pos * kv_dim, s->k, kv_dim * sizeof(float));
        memcpy(s->value_cache + loff + pos * kv_dim, s->v, kv_dim * sizeof(float));
        for (int h = 0; h < p->n_heads; h++) {
            float* q = s->q + h * head_size;
            float* att = s->att + h * p->seq_len;
            for (int t_step = 0; t_step <= pos; t_step++) {
                float* k_t = s->key_cache + loff + t_step * kv_dim + (h / kv_mul) * head_size;
                float score = 0.0f;
                for (int i = 0; i < head_size; i++) {
                    score += q[i] * k_t[i];
                }
                att[t_step] = score / sqrtf(head_size);
            }
            softmax(att, pos + 1);
            float* xb = s->xb + h * head_size;
            memset(xb, 0, head_size * sizeof(float));
            for (int t_step = 0; t_step <= pos; t_step++) {
                float* v_t = s->value_cache + loff + t_step * kv_dim + (h / kv_mul) * head_size;
                float a = att[t_step];
                for (int i = 0; i < head_size; i++) {
                    xb[i] += a * v_t[i];
                }
            }
        }
        matmul(s->xb2, s->xb, w->wo + l * dim * dim, dim, dim);
        for (int i = 0; i < dim; i++) {
            x[i] += s->xb2[i];
        }
        rmsnorm(s->xb, x, w->rms_ffn_weight + l * dim, dim);
        matmul(s->hb, s->xb, w->w1 + l * dim * hidden_dim, dim, hidden_dim);
        matmul(s->hb2, s->xb, w->w3 + l * dim * hidden_dim, dim, hidden_dim);
        for (int i = 0; i < hidden_dim; i++) {
            float val = s->hb[i];
            val *= (1.0f / (1.0f + expf(-val)));
            val *= s->hb2[i];
            s->hb[i] = val;
        }
        matmul(s->xb, s->hb, w->w2 + l * hidden_dim * dim, hidden_dim, dim);
        for (int i = 0; i < dim; i++) {
            x[i] += s->xb[i];
        }
    }
    rmsnorm(x, x, w->rms_final_weight, dim);
    matmul(s->logits, x, w->wcls, dim, p->vocab_size);
    return s->logits;
}
int compare_tokens(const void* a, const void* b) { return strcmp(((TokenIndex*)a)->str, ((TokenIndex*)b)->str); }
void simple_qsort(void* b, size_t n, size_t s, int (*c)(const void*, const void*))
{
    char* base = (char*)b;
    if (n == 0)
        return;
    for (size_t i = 0; i < n - 1; i++) {
        for (size_t j = 0; j < n - i - 1; j++) {
            if (c(base + j * s, base + (j + 1) * s) > 0) {
                char t[s];
                memcpy(t, base + j * s, s);
                memcpy(base + j * s, base + (j + 1) * s, s);
                memcpy(base + (j + 1) * s, t, s);
            }
        }
    }
}
#define qsort simple_qsort
void build_tokenizer(Tokenizer* t, int vocab_size)
{
    unsigned char* tokenizer_data = tokenizer_bin;
    size_t offset = 0;
    t->vocab_size = vocab_size;
    t->vocab = arena_alloc(vocab_size * sizeof(char*));
    t->vocab_scores = arena_alloc(vocab_size * sizeof(float));
    t->sorted_vocab = NULL;
    for (int i = 0; i < 256; i++) {
        t->byte_pieces[i * 2] = (unsigned char)i;
        t->byte_pieces[i * 2 + 1] = '\0';
    }
    memcpy(&t->max_token_length, tokenizer_data, sizeof(int));
    offset += sizeof(int);
    for (int i = 0; i < vocab_size; i++) {
        memcpy(t->vocab_scores + i, tokenizer_data + offset, sizeof(float));
        offset += sizeof(float);
        int len;
        memcpy(&len, tokenizer_data + offset, sizeof(int));
        offset += sizeof(int);
        t->vocab[i] = (char*)arena_alloc(len + 1);
        memcpy(t->vocab[i], tokenizer_data + offset, len);
        offset += len;
        t->vocab[i][len] = '\0';
    }
}
char* decode(Tokenizer* t, int prev, int token)
{
    if (token < 0 || token >= t->vocab_size) {
        return "";
    }
    char* p = t->vocab[token];
    if (prev == 1 && p[0] == ' ') {
        p++;
    }
    if (p[0] == '<' && p[1] == '0' && p[2] == 'x') {
        char b1 = p[3] >= 'a' ? (p[3] - 'a' + 10) : (p[3] - '0');
        char b2 = p[4] >= 'a' ? (p[4] - 'a' + 10) : (p[4] - 'a' + 10);
        unsigned char byte = (b1 << 4) | b2;
        p = (char*)t->byte_pieces + byte * 2;
    }
    return p;
}
void safe_printf(char* p)
{
    if (p != NULL && p[0] != '\0')
        uart_puts(p);
}
int str_lookup(char* s, TokenIndex* v, int n)
{
    for (int i = 0; i < n; i++) {
        if (strcmp(s, v[i].str) == 0)
            return v[i].id;
    }
    return -1;
}
void encode(Tokenizer* t, char* text, int8_t bos, int8_t eos, int* tokens, int* n)
{
    if (t->sorted_vocab == NULL) {
        t->sorted_vocab = arena_alloc(t->vocab_size * sizeof(TokenIndex));
        for (int i = 0; i < t->vocab_size; i++) {
            t->sorted_vocab[i].str = t->vocab[i];
            t->sorted_vocab[i].id = i;
        }
        qsort(t->sorted_vocab, t->vocab_size, sizeof(TokenIndex), compare_tokens);
    }
    char* str_buffer = arena_alloc((t->max_token_length * 2 + 3));
    *n = 0;
    if (bos)
        tokens[(*n)++] = 1;
    if (text[0] != '\0') {
        int dummy_prefix = str_lookup(" ", t->sorted_vocab, t->vocab_size);
        if (dummy_prefix != -1)
            tokens[(*n)++] = dummy_prefix;
    }
    for (char* c = text; *c != '\0'; c++) {
        str_buffer[0] = *c;
        str_buffer[1] = '\0';
        int id = str_lookup(str_buffer, t->sorted_vocab, t->vocab_size);
        if (id != -1) {
            tokens[(*n)++] = id;
        } else {
            tokens[(*n)++] = (unsigned char)str_buffer[0] + 3;
        }
    }
    while (1) {
        float best_score = -1e10;
        int best_id = -1;
        int best_idx = -1;
        for (int i = 0; i < (*n - 1); i++) {
            char* s1 = t->vocab[tokens[i]];
            char* s2 = t->vocab[tokens[i + 1]];
            int l1 = strlen(s1), l2 = strlen(s2);
            memcpy(str_buffer, s1, l1);
            memcpy(str_buffer + l1, s2, l2);
            str_buffer[l1 + l2] = '\0';
            int id = str_lookup(str_buffer, t->sorted_vocab, t->vocab_size);
            if (id != -1 && t->vocab_scores[id] > best_score) {
                best_score = t->vocab_scores[id];
                best_id = id;
                best_idx = i;
            }
        }
        if (best_idx == -1)
            break;
        tokens[best_idx] = best_id;
        for (int i = best_idx + 1; i < (*n - 1); i++) {
            tokens[i] = tokens[i + 1];
        }
        (*n)--;
    }
    if (eos)
        tokens[(*n)++] = 2;
}
int sample_argmax(float* p, int n)
{
    int max_i = 0;
    float max_p = p[0];
    for (int i = 1; i < n; i++) {
        if (p[i] > max_p) {
            max_i = i;
            max_p = p[i];
        }
    }
    return max_i;
}
unsigned int random_u32(unsigned long long* s)
{
    *s ^= *s >> 12;
    *s ^= *s << 25;
    *s ^= *s >> 27;
    return (*s * 0x2545F4914F6CDD1Dull) >> 32;
}
float random_f32(unsigned long long* s) { return (random_u32(s) >> 8) / 16777216.0f; }
int sample(Sampler* s, float* logits)
{
    if (s->temperature == 0.0f) {
        return sample_argmax(logits, s->vocab_size);
    } else {
        for (int q = 0; q < s->vocab_size; q++) {
            logits[q] /= s->temperature;
        }
        softmax(logits, s->vocab_size);
        float coin = random_f32(&s->rng_state);
        float cdf = 0.0f;
        for (int i = 0; i < s->vocab_size; i++) {
            cdf += logits[i];
            if (coin < cdf)
                return i;
        }
        return s->vocab_size - 1;
    }
}
void build_sampler(Sampler* s, int vocab_size, float temp, unsigned long long seed)
{
    s->vocab_size = vocab_size;
    s->temperature = temp;
    s->rng_state = seed;
}
void generate(Transformer* t, Tokenizer* tok, Sampler* sampler, char* prompt, int steps)
{
    // size_t arena_checkpoint = g_arena_offset;
    int prompt_tokens[512]; // Use static buffer instead of arena_alloc
    int num_prompt;
    encode(tok, prompt, 1, 0, prompt_tokens, &num_prompt);
    if (num_prompt < 1) {
        return;
    }

    // --- BUG FIX: Clear KV Cache before generation ---
    int kv_dim = (t->config.dim * t->config.n_kv_heads) / t->config.n_heads;
    memset(t->state.key_cache, 0, t->config.n_layers * t->config.seq_len * kv_dim * sizeof(float));
    memset(t->state.value_cache, 0, t->config.n_layers * t->config.seq_len * kv_dim * sizeof(float));

    int token = (num_prompt > 0) ? prompt_tokens[0] : 1, pos = 0, next;
    while (pos < steps) {
        float* logits = forward(t, token, pos);
        if (pos < num_prompt - 1) {
            next = prompt_tokens[pos + 1];
        } else {
            next = sample(sampler, logits);
        }
        pos++;
        if (next == 1)
            break;
        char* p = decode(tok, token, next);
        safe_printf(p);
        token = next;
    }
    // g_arena_offset = arena_checkpoint; // Do not restore arena offset!
}

static Transformer transformer;
static Tokenizer tokenizer;
static Sampler sampler;

int main()
{
    float temp = 0.8f;
    int steps = 256;
    unsigned long long seed = 1337;
    uart_puts("Bare-metal Llama2.c Chatbot for RISC-V (float32)\n--------------------------------\n");

    uart_puts("1. Building transformer...\n");
    build_transformer(&transformer);
    uart_puts("   - Transformer built.\n");

    uart_puts("2. Building tokenizer...\n");
    build_tokenizer(&tokenizer, transformer.config.vocab_size);
    uart_puts("   - Tokenizer built.\n");

    uart_puts("3. Building sampler...\n");
    build_sampler(&sampler, transformer.config.vocab_size, temp, seed);
    uart_puts("   - Sampler built.\n");

    uart_puts("\nInitialization complete. Ready for interaction.\n");
    uart_puts("--------------------------------\n");

    char prompt_buffer[256];
    while (1) {
        uart_puts("\nUser: ");
        read_line(prompt_buffer, sizeof(prompt_buffer));
        if (strlen(prompt_buffer) == 0) {
            continue;
        }

        uart_puts("Assistant: ");
        generate(&transformer, &tokenizer, &sampler, prompt_buffer, steps);
    }
    return 0;
}
