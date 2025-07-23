/*
 * Bare-metal FP32 Inference for Llama-2 Transformer model in pure C
 * Based on run.c from karpathy/llama2.c, adapted for RISC-V bare-metal
 * Uses FP32 weights to avoid quantization issues (e.g., zero-scale in matmul)
 * Includes UART I/O, static memory arena, and embedded model/tokenizer data
 * Fixed uint32_t definition and arena_alloc typo
 * Added build_transformer prototype
 */

// --- BARE-METAL DEFINITIONS ---
#define NULL ((void*)0)
typedef unsigned long size_t;
typedef signed char   int8_t;
typedef unsigned char uint8_t;
typedef int           int32_t;
typedef unsigned int  uint32_t; // For model header validation
int __errno;

// --- BARE-METAL INCLUDES ---
#include "uart.c"
#include "model.h"      // Contains stories15M_bin (FP32 weights)
#include "tokenizer.h"  // Tokenizer data (same as runq_baremetal.c)

// --- BARE-METAL HELPERS ---
void* memcpy(void* d, const void* s, size_t n) {
    char* dd = (char*)d;
    const char* ss = (const char*)s;
    for (size_t i = 0; i < n; i++) dd[i] = ss[i];
    return d;
}
void* memset(void* s, int c, size_t n) {
    unsigned char* p = (unsigned char*)s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}
size_t strlen(const char* s) {
    const char* p = s;
    while (*p) p++;
    return p - s;
}
int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) { s1++; s2++; }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}
void itoa(int n, char* b) {
    if (n == 0) { b[0] = '0'; b[1] = '\0'; return; }
    int i = 0, neg = 0;
    if (n < 0) { neg = 1; n = -n; }
    while (n != 0) { b[i++] = (n % 10) + '0'; n /= 10; }
    if (neg) b[i++] = '-';
    int s = 0, e = i - 1;
    while (s < e) { char t = b[s]; b[s] = b[e]; b[e] = t; s++; e--; }
    b[i] = '\0';
}

// libm function declarations
float sqrtf(float);
float expf(float);
float cosf(float);
float sinf(float);
float powf(float, float);

// Alignment helper
void* align_ptr(void* p, size_t align) {
    size_t addr = (size_t)p;
    size_t misalignment = addr % align;
    if (misalignment != 0) {
        p = (void*)(addr + (align - misalignment));
    }
    return p;
}

// Input reading function
#define MAX_INPUT_LEN 256
void read_line(char* buffer, int max_len) {
    int i = 0;
    while (i < max_len - 1) {
        char c = uart_getc();
        if (c == '\r' || c == '\n') {
            uart_puts("\n");
            break;
        } else if (c == 127 || c == '\b') {
            if (i > 0) {
                i--;
                uart_puts("\b \b");
            }
        } else {
            buffer[i++] = c;
            uart_putc(c);
        }
    }
    buffer[i] = '\0';
}

// ----------------------------------------------------------------------------
// Globals and Data Structures
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
    float *x;
    float *xb;
    float *xb2;
    float *hb;
    float *hb2;
    float *q;
    float *k;
    float *v;
    float *att;
    float *logits;
    float *key_cache;
    float *value_cache;
} RunState;

#define ARENA_SIZE 1280000000
static unsigned char g_arena[ARENA_SIZE];
static size_t g_arena_offset = 0;

void* arena_alloc(size_t size) {
    size = (size + 15) & ~15; // Align to 16 bytes
    if (g_arena_offset + size > ARENA_SIZE) {
        char buf[32];
        uart_puts("ERROR: Arena out of memory! Offset: ");
        itoa(g_arena_offset, buf); uart_puts(buf);
        uart_puts(" Requested: "); itoa(size, buf); uart_puts(buf);
        uart_puts("\n");
        while(1);
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
    char *str;
    int id;
} TokenIndex;

typedef struct {
    char** vocab;
    float* vocab_scores;
    TokenIndex *sorted_vocab;
    int vocab_size;
    unsigned int max_token_length;
    unsigned char byte_pieces[512];
} Tokenizer;

typedef struct {
    int vocab_size;
    float temperature;
    unsigned long long rng_state;
} Sampler;

// Function Prototypes
void build_transformer(Transformer* t); // Added prototype
void encode(Tokenizer* t, char *text, int8_t bos, int8_t eos, int *tokens, int *n_tokens);
void simple_qsort(void* base, size_t nitems, size_t size, int (*compar)(const void*, const void*));
char* decode(Tokenizer* t, int prev_token, int token);
int sample(Sampler* sampler, float* logits);

// ----------------------------------------------------------------------------
// Transformer functions
void accum(float *a, float *b, int n) {
    for (int i = 0; i < n; i++) {
        a[i] += b[i];
    }
}

void rmsnorm(float* o, float* x, float* weight, int size) {
    char buf[32];
    float ss = 0.0f;
    for (int j = 0; j < size; j++) {
        ss += x[j] * x[j];
    }
    ss /= size;
    ss += 1e-5f;
    if (ss == 0.0f) {
        uart_puts("ERROR: rmsnorm ss is zero!\n");
        return;
    }
    ss = 1.0f / sqrtf(ss);
    for (int j = 0; j < size; j++) {
        o[j] = weight[j] * (ss * x[j]);
    }
    // Debug: Print first few outputs
    if (size >= 4) {
        uart_puts("rmsnorm o[0:3]: ");
        for (int i = 0; i < 4; i++) {
            int* fval = (int*)&o[i];
            itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
        }
        uart_puts("\n");
    }
}

void softmax(float* x, int size) {
    if (size <= 0) return;
    float max_val = x[0];
    for (int i = 1; i < size; i++) {
        if (x[i] > max_val) max_val = x[i];
    }
    float sum = 0.0f;
    for (int i = 0; i < size; i++) {
        x[i] = expf(x[i] - max_val);
        sum += x[i];
    }
    if (sum == 0.0f) {
        uart_puts("ERROR: softmax sum is zero!\n");
        return;
    }
    for (int i = 0; i < size; i++) {
        x[i] /= sum;
    }
}

void matmul(float* xout, float* x, float* w, int n, int d) {
    char buf[32];
    for (int i = 0; i < d; i++) {
        float val = 0.0f;
        for (int j = 0; j < n; j++) {
            val += w[i * n + j] * x[j];
        }
        xout[i] = val;
        // Debug: Print first few outputs
        if (i < 4) {
            int* fval = (int*)&xout[i];
            uart_puts("matmul xout["); itoa(i, buf); uart_puts(buf); uart_puts("]: "); 
            itoa(*fval, buf); uart_puts(buf); uart_puts("\n");
        }
    }
}

float* forward(Transformer* transformer, int token, int pos) {
    char buf[32];
    Config* p = &transformer->config;
    TransformerWeights* w = &transformer->weights;
    RunState* s = &transformer->state;
    float* x = s->x;
    int dim = p->dim;
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    int kv_mul = p->n_heads / p->n_kv_heads;
    int hidden_dim = p->hidden_dim;
    int head_size = dim / p->n_heads;

    if (token < 0 || token >= p->vocab_size) {
        uart_puts("ERROR: Invalid token ID in forward: "); itoa(token, buf); uart_puts(buf); uart_puts("\n");
        return s->logits;
    }

    memcpy(x, &w->token_embedding_table[token * dim], dim * sizeof(float));
    // Debug: Print first few x values
    if (pos == 0) {
        uart_puts("forward x[0:3]: ");
        for (int i = 0; i < 4 && i < dim; i++) {
            int* fval = (int*)&x[i];
            itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
        }
        uart_puts("\n");
    }

    for (int l = 0; l < p->n_layers; l++) {
        rmsnorm(s->xb, x, w->rms_att_weight + l*dim, dim);
        int loff = l * p->seq_len * kv_dim;
        matmul(s->q, s->xb, w->wq + l*dim*dim, dim, dim);
        matmul(s->k, s->xb, w->wk + l*dim*kv_dim, dim, kv_dim);
        matmul(s->v, s->xb, w->wv + l*dim*kv_dim, dim, kv_dim);
        // Debug: Print first few q, k, v values
        if (pos == 0 && l == 0) {
            uart_puts("forward q[0:3]: ");
            for (int i = 0; i < 4 && i < dim; i++) {
                int* fval = (int*)&s->q[i];
                itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
            }
            uart_puts("\nforward k[0:3]: ");
            for (int i = 0; i < 4 && i < kv_dim; i++) {
                int* fval = (int*)&s->k[i];
                itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
            }
            uart_puts("\nforward v[0:3]: ");
            for (int i = 0; i < 4 && i < kv_dim; i++) {
                int* fval = (int*)&s->v[i];
                itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
            }
            uart_puts("\n");
        }
        for (int i = 0; i < dim; i += 2) {
            float q0 = s->q[i];
            float q1 = s->q[i+1];
            int head_dim_idx = i % head_size;
            float freq = 1.0f / powf(10000.0f, ((float)head_dim_idx) / head_size);
            float val = pos * freq;
            float fcr = cosf(val);
            float fci = sinf(val);
            s->q[i] = q0 * fcr - q1 * fci;
            s->q[i+1] = q0 * fci + q1 * fcr;
            if (i < kv_dim) {
                float k0 = s->k[i];
                float k1 = s->k[i+1];
                s->k[i] = k0 * fcr - k1 * fci;
                s->k[i+1] = k0 * fci + k1 * fcr;
            }
        }
        memcpy(s->key_cache + loff + pos*kv_dim, s->k, kv_dim * sizeof(float));
        memcpy(s->value_cache + loff + pos*kv_dim, s->v, kv_dim * sizeof(float));
        for (int h = 0; h < p->n_heads; h++) {
            float* q = s->q + h * head_size;
            float* att = s->att + h * p->seq_len;
            for (int t = 0; t <= pos; t++) {
                float score = 0.0f;
                float* k = s->key_cache + loff + t*kv_dim + (h/kv_mul)*head_size;
                for (int i = 0; i < head_size; i++) {
                    score += q[i] * k[i];
                }
                score /= sqrtf(head_size);
                att[t] = score;
            }
            softmax(att, pos + 1);
            float* xb = s->xb + h * head_size;
            memset(xb, 0, head_size * sizeof(float));
            for (int t = 0; t <= pos; t++) {
                float* v = s->value_cache + loff + t*kv_dim + (h/kv_mul)*head_size;
                float a = att[t];
                for (int i = 0; i < head_size; i++) {
                    xb[i] += a * v[i];
                }
            }
        }
        matmul(s->xb2, s->xb, w->wo + l*dim*dim, dim, dim);
        accum(x, s->xb2, dim);
        rmsnorm(s->xb, x, w->rms_ffn_weight + l*dim, dim);
        matmul(s->hb, s->xb, w->w1 + l*dim*hidden_dim, dim, hidden_dim);
        matmul(s->hb2, s->xb, w->w3 + l*dim*hidden_dim, dim, hidden_dim);
        for (int i = 0; i < hidden_dim; i++) {
            s->hb[i] = s->hb[i] * (1.0f / (1.0f + expf(-s->hb[i])));
            s->hb[i] *= s->hb2[i];
        }
        matmul(s->xb, s->hb, w->w2 + l*hidden_dim*dim, hidden_dim, dim);
        accum(x, s->xb, dim);
    }
    rmsnorm(x, x, w->rms_final_weight, dim);
    matmul(s->logits, x, w->wcls, dim, p->vocab_size);
    // Debug: Print final logits
    if (pos < 3) {
        uart_puts("Final logits[0:3]: ");
        for (int i = 0; i < 4 && i < p->vocab_size; i++) {
            int* fval = (int*)&s->logits[i];
            itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
        }
        uart_puts("\n");
    }
    return s->logits;
}

// ----------------------------------------------------------------------------
// Tokenizer and Sampler (same as runq_baremetal.c)
int compare_tokens(const void* a, const void* b) {
    return strcmp(((TokenIndex*)a)->str, ((TokenIndex*)b)->str);
}

void simple_qsort(void* b, size_t n, size_t s, int (*c)(const void*, const void*)) {
    char* base = (char*)b;
    if (n == 0) return;
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

void build_tokenizer(Tokenizer* t, int vocab_size) {
    char buf[32];
    uart_puts("   - Starting build_tokenizer...\n");
    unsigned char* tokenizer_data = tokenizer_bin;
    if (tokenizer_data == NULL) {
        uart_puts("ERROR: Tokenizer data pointer is NULL!\n");
        while(1);
    }
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
    uart_puts("     - Max token length: "); itoa(t->max_token_length, buf); uart_puts(buf); uart_puts("\n");
    offset += sizeof(int);
    for (int i = 0; i < vocab_size; i++) {
        memcpy(t->vocab_scores + i, tokenizer_data + offset, sizeof(float));
        offset += sizeof(float);
        int len;
        memcpy(&len, tokenizer_data + offset, sizeof(int));
        offset += sizeof(int);
        if (len <= 0 || len > 256) {
            uart_puts("ERROR: Invalid token length at index "); itoa(i, buf); uart_puts(buf);
            uart_puts(": "); itoa(len, buf); uart_puts(buf); uart_puts("\n");
            while(1);
        }
        t->vocab[i] = (char*)arena_alloc(len + 1);
        memcpy(t->vocab[i], tokenizer_data + offset, len);
        offset += len;
        t->vocab[i][len] = '\0';
        // Debug: Print vocab entries around token 31999 and first few
        if (i < 5 || (i >= 31995 && i <= 32000)) {
            int* fval = (int*)&t->vocab_scores[i];
            uart_puts("     - Vocab["); itoa(i, buf); uart_puts(buf); uart_puts("]: ");
            uart_puts(t->vocab[i]); uart_puts(" (score: "); itoa(*fval, buf); uart_puts(buf); uart_puts(")\n");
        }
    }
    uart_puts("   - build_tokenizer complete.\n");
}

char* decode(Tokenizer* t, int prev, int token) {
    char buf[32];
    if (token < 0 || token >= t->vocab_size) {
        uart_puts("ERROR: Invalid token ID: "); itoa(token, buf); uart_puts(buf); uart_puts("\n");
        return "";
    }
    uart_puts("Decode token ID: "); itoa(token, buf); uart_puts(buf); uart_puts(" -> "); uart_puts(t->vocab[token]); uart_puts("\n");
    char* p = t->vocab[token];
    if (prev == 1 && p[0] == ' ') { p++; }
    if (p[0] == '<' && p[1] == '0' && p[2] == 'x') {
        char b1 = p[3] >= 'a' ? (p[3] - 'a' + 10) : (p[3] - '0');
        char b2 = p[4] >= 'a' ? (p[4] - 'a' + 10) : (p[4] - '0');
        unsigned char byte = (b1 << 4) | b2;
        p = (char*)t->byte_pieces + byte * 2;
    }
    return p;
}

void safe_printf(char *p) {
    if (p != NULL && p[0] != '\0') uart_puts(p);
}

int str_lookup(char* s, TokenIndex* v, int n) {
    for (int i = 0; i < n; i++) {
        if (strcmp(s, v[i].str) == 0) return v[i].id;
    }
    return -1;
}

void encode(Tokenizer* t, char* text, int8_t bos, int8_t eos, int* tokens, int* n) {
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
    if (bos) tokens[(*n)++] = 1;
    if (text[0] != '\0') {
        int dummy_prefix = str_lookup(" ", t->sorted_vocab, t->vocab_size);
        if (dummy_prefix != -1) tokens[(*n)++] = dummy_prefix;
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
        if (best_idx == -1) break;
        tokens[best_idx] = best_id;
        for (int i = best_idx + 1; i < (*n - 1); i++) {
            tokens[i] = tokens[i + 1];
        }
        (*n)--;
    }
    if (eos) tokens[(*n)++] = 2;
}

int sample_argmax(float* probabilities, int n) {
    int max_i = 0;
    float max_p = probabilities[0];
    for (int i = 1; i < n; i++) {
        if (probabilities[i] > max_p) {
            max_i = i;
            max_p = probabilities[i];
        }
    }
    return max_i;
}

unsigned int random_u32(unsigned long long *state) {
    *state ^= *state >> 12;
    *state ^= *state << 25;
    *state ^= *state >> 27;
    return (unsigned int)((*state * 0x2545F4914F6CDD1DULL) >> 32);
}

float random_f32(unsigned long long *state) {
    return (random_u32(state) >> 8) / 16777216.0f;
}

int sample(Sampler* sampler, float* logits) {
    char buf[32];
    // Check for invalid logits
    float sum = 0.0f;
    int non_zero_count = 0;
    for (int i = 0; i < sampler->vocab_size; i++) {
        sum += logits[i];
        if (logits[i] != 0.0f) non_zero_count++;
    }
    if (sum == 0.0f || non_zero_count < 10) {
        uart_puts("ERROR: Logits are mostly zero or invalid! Non-zero count: ");
        itoa(non_zero_count, buf); uart_puts(buf); uart_puts("\n");
        return 1; // Return BOS token as fallback
    }
    // Debug: Print top 5 logits
    uart_puts("Top 5 logits: ");
    for (int i = 0; i < 5 && i < sampler->vocab_size; i++) {
        int* fval = (int*)&logits[i];
        itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");
    // Check for repetitive tokens
    static int last_token = -1;
    static int repeat_count = 0;
    if (sampler->temperature == 0.0f) {
        int token = sample_argmax(logits, sampler->vocab_size);
        if (token == last_token) {
            repeat_count++;
            if (repeat_count >= 3) {
                uart_puts("WARNING: Detected repetitive token "); itoa(token, buf); uart_puts(buf); uart_puts("\n");
                token = 1; // Fallback to BOS
                repeat_count = 0;
            }
        } else {
            repeat_count = 0;
        }
        last_token = token;
        uart_puts("Sampled (argmax) token ID: "); itoa(token, buf); uart_puts(buf); uart_puts("\n");
        return token;
    }
    for (int q = 0; q < sampler->vocab_size; q++) {
        logits[q] /= sampler->temperature;
    }
    softmax(logits, sampler->vocab_size);
    float coin = random_f32(&sampler->rng_state);
    float cdf = 0.0f;
    for (int i = 0; i < sampler->vocab_size; i++) {
        cdf += logits[i];
        if (coin < cdf) {
            if (i == last_token) {
                repeat_count++;
                if (repeat_count >= 3) {
                    uart_puts("WARNING: Detected repetitive token "); itoa(i, buf); uart_puts(buf); uart_puts("\n");
                    i = 1; // Fallback to BOS
                    repeat_count = 0;
                }
            } else {
                repeat_count = 0;
            }
            last_token = i;
            uart_puts("Sampled (softmax) token ID: "); itoa(i, buf); uart_puts(buf); uart_puts("\n");
            return i;
        }
    }
    last_token = sampler->vocab_size - 1;
    uart_puts("Sampled (fallback) token ID: "); itoa(sampler->vocab_size - 1, buf); uart_puts(buf); uart_puts("\n");
    return sampler->vocab_size - 1;
}

void build_sampler(Sampler* s, int vocab_size, float temp, unsigned long long seed) {
    s->vocab_size = vocab_size;
    s->temperature = temp;
    s->rng_state = seed;
}

void generate(Transformer* t, Tokenizer* tok, Sampler* sampler, char* prompt, int steps) {
    char buf[64];
    int num_prompt_tokens = 0;
    int* prompt_tokens = arena_alloc((strlen(prompt) + 3) * sizeof(int));
    encode(tok, prompt, 1, 0, prompt_tokens, &num_prompt_tokens);
    if (num_prompt_tokens < 1) {
        uart_puts("ERROR: Prompt tokenization failed.\n");
        return;
    }

    // Debug: Print prompt tokens
    uart_puts("Prompt tokens: ");
    for (int i = 0; i < num_prompt_tokens; i++) {
        itoa(prompt_tokens[i], buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");

    int token = prompt_tokens[0];
    int pos = 0;
    while (1) {
        float* logits = forward(t, token, pos);
        int next;
        if (pos < num_prompt_tokens - 1) {
            next = prompt_tokens[pos + 1];
        } else {
            next = sample(sampler, logits);
        }
        pos++;
        if (next == 2) break; // EOS token
        if (pos >= steps) break;
        char* piece = decode(tok, token, next);
        safe_printf(piece);
        token = next;
        // Debug: Print progress
        uart_puts("[ Token "); itoa(pos + 1, buf); uart_puts(buf);
        uart_puts(" / "); itoa(steps, buf); uart_puts(buf); uart_puts(" ]\n");
    }
    uart_puts("\n");
}

typedef struct {
    int n_layers;     // 6
    int n_heads;      // 6
    int n_kv_heads;   // 6
    int vocab_size;   // 32000
    int seq_len;      // 256
} TempConfig;

void build_transformer(Transformer *t) {
    char buf[32];
    uart_puts("   - Starting build_transformer...\n");
    unsigned char* model_ptr = stories15M_bin;
    if (model_ptr == NULL) {
        uart_puts("ERROR: Model data pointer is NULL!\n");
        while(1);
    }
    // Debug: Print first 8 bytes of model data
    uart_puts("     - Model data first 8 bytes: ");
    for (int i = 0; i < 8; i++) {
        itoa(model_ptr[i], buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");

    int header_size = 256;
    // Validate header
    uint32_t magic = *(uint32_t*)model_ptr;
    if (magic != 0x67676d66 && magic != 0x67676d6c && magic != 0x00000120) {
        uart_puts("ERROR: Invalid model magic number: "); itoa(magic, buf); uart_puts(buf); uart_puts("\n");
        while(1);
    }

    uart_puts("   - Reading header...\n");
    TempConfig temp_config;
    memcpy(&temp_config, model_ptr + 8, sizeof(TempConfig)); // Offset 8 based on xxd
    t->config.dim = 288; // Hardcode for stories15M
    t->config.hidden_dim = 768; // Hardcode for stories15M
    t->config.n_layers = temp_config.n_layers;
    t->config.n_heads = temp_config.n_heads;
    t->config.n_kv_heads = temp_config.n_kv_heads;
    t->config.vocab_size = temp_config.vocab_size;
    t->config.seq_len = temp_config.seq_len;

    uart_puts("     - Config: dim="); itoa(t->config.dim, buf); uart_puts(buf);
    uart_puts(" hidden_dim="); itoa(t->config.hidden_dim, buf); uart_puts(buf);
    uart_puts(" n_layers="); itoa(t->config.n_layers, buf); uart_puts(buf);
    uart_puts(" vocab_size="); itoa(t->config.vocab_size, buf); uart_puts(buf);
    uart_puts(" seq_len="); itoa(t->config.seq_len, buf); uart_puts(buf); uart_puts("\n");

    // Validate config
    if (t->config.dim <= 0 || t->config.vocab_size <= 0 || t->config.n_layers <= 0 || t->config.seq_len <= 0) {
        uart_puts("ERROR: Invalid config: dim="); itoa(t->config.dim, buf); uart_puts(buf);
        uart_puts(" vocab_size="); itoa(t->config.vocab_size, buf); uart_puts(buf);
        uart_puts(" n_layers="); itoa(t->config.n_layers, buf); uart_puts(buf);
        uart_puts(" seq_len="); itoa(t->config.seq_len, buf); uart_puts(buf); uart_puts("\n");
        while(1);
    }

    // Rest of the function remains unchanged
    unsigned char* weights_ptr = model_ptr + header_size;
    Config* p = &t->config;
    TransformerWeights* w = &t->weights;
    int head_size = p->dim / p->n_heads;
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;

    uart_puts("   - Mapping weights...\n");
    w->token_embedding_table = (float*)weights_ptr;
    weights_ptr += p->vocab_size * p->dim * sizeof(float);
    w->rms_att_weight = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * sizeof(float);
    w->wq = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * (p->n_heads * head_size) * sizeof(float);
    w->wk = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * (p->n_kv_heads * head_size) * sizeof(float);
    w->wv = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * (p->n_kv_heads * head_size) * sizeof(float);
    w->wo = (float*)weights_ptr;
    weights_ptr += p->n_layers * (p->n_heads * head_size) * p->dim * sizeof(float);
    w->rms_ffn_weight = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * sizeof(float);
    w->w1 = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * p->hidden_dim * sizeof(float);
    w->w2 = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->hidden_dim * p->dim * sizeof(float);
    w->w3 = (float*)weights_ptr;
    weights_ptr += p->n_layers * p->dim * p->hidden_dim * sizeof(float);
    w->rms_final_weight = (float*)weights_ptr;
    weights_ptr += p->dim * sizeof(float);
    w->wcls = shared_classifier ? w->token_embedding_table : (float*)weights_ptr;
    weights_ptr += shared_classifier ? 0 : p->dim * p->vocab_size * sizeof(float);

    uart_puts("     - token_embedding_table[0:3]: ");
    for (int i = 0; i < 4 && i < p->vocab_size * p->dim; i++) {
        int* fval = (int*)&w->token_embedding_table[i];
        itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");

    uart_puts("   - Allocating RunState...\n");
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

    uart_puts("   - build_transformer complete. Arena used: ");
    itoa(g_arena_offset, buf); uart_puts(buf); uart_puts(" / "); itoa(ARENA_SIZE, buf); uart_puts(buf); uart_puts("\n");
}
// Enable FPU in machine mode
void enable_fpu() {
    asm volatile (
        "csrr t0, mstatus\n"
        "li t1, 0b11 << 13\n"   // Set FS field to Dirty (enable FPU)
        "or t0, t0, t1\n"
        "csrw mstatus, t0\n"
        "csrw fcsr, zero\n"     // Clear FPU control/status register
    );
}

static Transformer transformer;
static Tokenizer tokenizer;
static Sampler sampler;

int main() {
    char buf[32];
    uart_puts("Initializing UART...\n");
    //enable_fpu();
    // Test FPU
    float test_float = 1.0f;
    test_float = test_float * 2.0f;
    int* fval = (int*)&test_float;
    uart_puts("FPU test (2.0f): "); itoa(*fval, buf); uart_puts(buf); uart_puts("\n");

    float temperature = 0.9f;
    int steps = 256;
    unsigned long long rng_seed = 1337;

    uart_puts("Bare-metal FP32 Llama2.c for RISC-V\n--------------------------------\n");

    uart_puts("1. Building transformer...\n");
    build_transformer(&transformer);
    uart_puts("   - Transformer built.\n");

    if (steps <= 0 || steps > transformer.config.seq_len) {
        steps = transformer.config.seq_len;
    }

    uart_puts("2. Building tokenizer...\n");
    build_tokenizer(&tokenizer, transformer.config.vocab_size);
    uart_puts("   - Tokenizer built.\n");

    uart_puts("3. Building sampler...\n");
    build_sampler(&sampler, transformer.config.vocab_size, temperature, rng_seed);
    uart_puts("   - Sampler built.\n");

    char prompt[MAX_INPUT_LEN];
    while (1) {
        uart_puts("\n--------------------------------\n");
        uart_puts("Enter prompt (or 'exit' to quit):\n> ");
        read_line(prompt, MAX_INPUT_LEN);
        if (strcmp(prompt, "exit") == 0) {
            uart_puts("Exiting...\n");
            break;
        }
        if (strlen(prompt) == 0) {
            uart_puts("Please enter a prompt\n");
            continue;
        }
        uart_puts("\nGenerating response...\n");
        uart_puts("--------------------------------\n");
        generate(&transformer, &tokenizer, &sampler, prompt, steps);
    }

    uart_puts("\n--------------------------------\n--- DONE ---\n");
    while (1); // Halt
    return 0;
}
