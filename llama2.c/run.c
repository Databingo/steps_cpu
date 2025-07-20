/*
 * Bare-metal Inference for Llama-2 Transformer model in pure C
 * Altered for a naked qemu-riscv64 target.
 * All OS dependencies (malloc, file I/O, mmap, printf) have been removed.
 */

// --- BARE-METAL CHANGE: DEFINITIONS ---
// We are in a freestanding environment, so we must define fundamental types
// that are normally in <stddef.h> and <stdint.h>.
#define NULL ((void*)0)
typedef unsigned long size_t;
typedef signed char         int8_t;
typedef unsigned char       uint8_t;
typedef short               int16_t;
typedef unsigned short      uint16_t;
typedef int                 int32_t;
typedef unsigned int        uint32_t;
typedef long long           int64_t;
typedef unsigned long long  uint64_t;

// --- BARE-METAL CHANGE ---
// Include our own data and drivers.
#include "uart.c"
#include "model.h"
#include "tokenizer.h"

// --- BARE-METAL CHANGE ---
// Provide our own simple math and memory function implementations
void* memcpy(void* dest, const void* src, size_t n) {
    char* d = (char*)dest;
    const char* s = (const char*)src;
    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
    return dest;
}

void* memset(void* s, int c, size_t n) {
    unsigned char* p = (unsigned char*)s;
    while(n--)
        *p++ = (unsigned char)c;
    return s;
}

// NOTE: These are placeholder math functions. They are NOT efficient or robust.
//float sqrtf(float x) {
//    if (x == 0.0f) return 0.0f;
//    float guess = x;
//    for(int i=0; i<10; i++) {
//        guess = 0.5f * (guess + x / guess);
//    }
//    return guess;
//}
//
//float expf_taylor(float x) {
//    float sum = 1.0f; float term = 1.0f;
//    for (int i = 1; i < 10; ++i) { term *= x / i; sum += term; }
//    return sum;
//}
//#define expf expf_taylor
//
//float powf(float base, float exp) { return 1.0f; } // HACK
//float cosf(float x) { return 1.0f; } // HACK
//float sinf(float x) { return x; }   // HACK

size_t strlen(const char* s) {
    const char* p = s;
    while (*p) p++;
    return p - s;
}

int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

// ----------------------------------------------------------------------------
// Data structures

typedef struct {
    int dim; int hidden_dim; int n_layers; int n_heads; int n_kv_heads; int vocab_size; int seq_len;
} Config;

typedef struct {
    float* token_embedding_table; float* rms_att_weight; float* rms_ffn_weight;
    float* wq; float* wk; float* wv; float* wo;
    float* w1; float* w2; float* w3;
    float* rms_final_weight; float* wcls;
} TransformerWeights;

typedef struct {
    float *x; float *xb; float *xb2; float *hb; float *hb2; float *q; float *k; float *v;
    float *att; float *logits; float* key_cache; float* value_cache;
} RunState;

#define RUN_STATE_ARENA_SIZE 8000000
static unsigned char g_run_state_arena[RUN_STATE_ARENA_SIZE];
static unsigned long g_arena_next_offset = 0;

void* arena_alloc(size_t size) {
    size = (size + 15) & ~15; // Align to 16 bytes
    if (g_arena_next_offset + size > RUN_STATE_ARENA_SIZE) {
        uart_puts("ERROR: RunState arena out of memory!\n");
        while(1); // Halt
    }
    void* ptr = &g_run_state_arena[g_arena_next_offset];
    g_arena_next_offset += size;
    return ptr;
}

typedef struct {
    Config config;
    TransformerWeights weights;
    RunState state;
} Transformer;

typedef struct {
    char *str; int id;
} TokenIndex;

typedef struct {
    char** vocab; float* vocab_scores; TokenIndex *sorted_vocab;
    int vocab_size; unsigned int max_token_length; unsigned char byte_pieces[512];
} Tokenizer;

typedef struct {
    float prob; int index;
} ProbIndex;

typedef struct {
    int vocab_size; ProbIndex* probindex; float temperature; float topp; unsigned long long rng_state;
} Sampler;

// --- BARE-METAL CHANGE: FUNCTION PROTOTYPES (MOVED HERE) ---
// Now that all the typedefs (Tokenizer, Sampler) are defined,
// we can declare our functions using those clean names.
void encode(Tokenizer* t, char *text, int8_t bos, int8_t eos, int *tokens, int *n_tokens);
void simple_qsort(void* base, size_t nitems, size_t size, int (*compar)(const void*, const void*));
char* decode(Tokenizer* t, int prev_token, int token);
int sample(Sampler* sampler, float* logits);

// ----------------------------------------------------------------------------
// Model and memory management

void malloc_run_state(RunState* s, Config* p) {
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    s->x = arena_alloc(p->dim * sizeof(float));
    s->xb = arena_alloc(p->dim * sizeof(float));
    s->xb2 = arena_alloc(p->dim * sizeof(float));
    s->hb = arena_alloc(p->hidden_dim * sizeof(float));
    s->hb2 = arena_alloc(p->hidden_dim * sizeof(float));
    s->q = arena_alloc(p->dim * sizeof(float));
    s->key_cache = arena_alloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->value_cache = arena_alloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->att = arena_alloc(p->n_heads * p->seq_len * sizeof(float));
    s->logits = arena_alloc(p->vocab_size * sizeof(float));
}

void memory_map_weights(TransformerWeights *w, Config* p, float* ptr, int shared_weights) {
    int head_size = p->dim / p->n_heads;
    unsigned long long n_layers = p->n_layers;
    w->token_embedding_table = ptr;
    ptr += p->vocab_size * p->dim;
    w->rms_att_weight = ptr;
    ptr += n_layers * p->dim;
    w->wq = ptr;
    ptr += n_layers * p->dim * (p->n_heads * head_size);
    w->wk = ptr;
    ptr += n_layers * p->dim * (p->n_kv_heads * head_size);
    w->wv = ptr;
    ptr += n_layers * p->dim * (p->n_kv_heads * head_size);
    w->wo = ptr;
    ptr += n_layers * (p->n_heads * head_size) * p->dim;
    w->rms_ffn_weight = ptr;
    ptr += n_layers * p->dim;
    w->w1 = ptr;
    ptr += n_layers * p->dim * p->hidden_dim;
    w->w2 = ptr;
    ptr += n_layers * p->hidden_dim * p->dim;
    w->w3 = ptr;
    ptr += n_layers * p->dim * p->hidden_dim;
    w->rms_final_weight = ptr;
    ptr += p->dim;
    ptr += p->seq_len * head_size / 2;
    ptr += p->seq_len * head_size / 2;
    w->wcls = shared_weights ? w->token_embedding_table : ptr;
}

void build_transformer(Transformer *t) {
    unsigned char* model_data = stories15M_bin;
    memcpy(&t->config, model_data, sizeof(Config));
    int shared_weights = t->config.vocab_size > 0 ? 1 : 0;
    t->config.vocab_size = (t->config.vocab_size < 0) ? -t->config.vocab_size : t->config.vocab_size;
    float* weights_ptr = (float*)(model_data + sizeof(Config));
    memory_map_weights(&t->weights, &t->config, weights_ptr, shared_weights);
    malloc_run_state(&t->state, &t->config);
}

// ----------------------------------------------------------------------------
// neural net blocks

void rmsnorm(float* o, float* x, float* weight, int size) {
    float ss = 0.0f;
    for (int j = 0; j < size; j++) { ss += x[j] * x[j]; }
    ss /= size;
    ss += 1e-5f;
    ss = 1.0f / sqrtf(ss);
    for (int j = 0; j < size; j++) { o[j] = weight[j] * (ss * x[j]); }
}

void softmax(float* x, int size) {
    if (size <= 0) return;
    float max_val = x[0];
    for (int i = 1; i < size; i++) { if (x[i] > max_val) { max_val = x[i]; } }
    float sum = 0.0f;
    for (int i = 0; i < size; i++) { x[i] = expf(x[i] - max_val); sum += x[i]; }
    for (int i = 0; i < size; i++) { x[i] /= sum; }
}

void matmul(float* xout, float* x, float* w, int n, int d) {
    for (int i = 0; i < d; i++) {
        float val = 0.0f;
        for (int j = 0; j < n; j++) { val += w[i * n + j] * x[j]; }
        xout[i] = val;
    }
}

float* forward(Transformer* transformer, int token, int pos) {
    Config* p = &transformer->config;
    TransformerWeights* w = &transformer->weights;
    RunState* s = &transformer->state;
    float *x = s->x;
    int dim = p->dim;
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    int kv_mul = p->n_heads / p->n_kv_heads;
    int hidden_dim =  p->hidden_dim;
    int head_size = dim / p->n_heads;

    float* content_row = w->token_embedding_table + token * dim;
    memcpy(x, content_row, dim*sizeof(*x));

    for(unsigned long long l = 0; l < p->n_layers; l++) {
        rmsnorm(s->xb, x, w->rms_att_weight + l*dim, dim);
        int loff = l * p->seq_len * kv_dim;
        s->k = s->key_cache + loff + pos * kv_dim;
        s->v = s->value_cache + loff + pos * kv_dim;
        matmul(s->q, s->xb, w->wq + l*dim*dim, dim, dim);
        matmul(s->k, s->xb, w->wk + l*dim*kv_dim, dim, kv_dim);
        matmul(s->v, s->xb, w->wv + l*dim*kv_dim, dim, kv_dim);

        for (int i = 0; i < dim; i+=2) {
            int head_dim_idx = i % head_size;
            float freq = 1.0f / powf(10000.0f, head_dim_idx / (float)head_size);
            float val = pos * freq;
            float fcr = cosf(val);
            float fci = sinf(val);
            int rotn = i < kv_dim ? 2 : 1;
            for (int v_idx = 0; v_idx < rotn; v_idx++) {
                float* vec = v_idx == 0 ? s->q : s->k;
                float v0 = vec[i];
                float v1 = vec[i+1];
                vec[i]   = v0 * fcr - v1 * fci;
                vec[i+1] = v0 * fci + v1 * fcr;
            }
        }

        for (int h = 0; h < p->n_heads; h++) {
            float* q = s->q + h * head_size;
            float* att = s->att + h * p->seq_len;
            for (int t = 0; t <= pos; t++) {
                float* k = s->key_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                float score = 0.0f;
                for (int i = 0; i < head_size; i++) { score += q[i] * k[i]; }
                score /= sqrtf(head_size);
                att[t] = score;
            }
            softmax(att, pos + 1);
            float* xb = s->xb + h * head_size;
            memset(xb, 0, head_size * sizeof(float));
            for (int t = 0; t <= pos; t++) {
                float* v = s->value_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                float a = att[t];
                for (int i = 0; i < head_size; i++) { xb[i] += a * v[i]; }
            }
        }
        matmul(s->xb2, s->xb, w->wo + l*dim*dim, dim, dim);
        for (int i = 0; i < dim; i++) { x[i] += s->xb2[i]; }
        rmsnorm(s->xb, x, w->rms_ffn_weight + l*dim, dim);
        matmul(s->hb, s->xb, w->w1 + l*dim*hidden_dim, dim, hidden_dim);
        matmul(s->hb2, s->xb, w->w3 + l*dim*hidden_dim, dim, hidden_dim);
        for (int i = 0; i < hidden_dim; i++) {
            float val = s->hb[i];
            val *= (1.0f / (1.0f + expf(-val)));
            val *= s->hb2[i];
            s->hb[i] = val;
        }
        matmul(s->xb, s->hb, w->w2 + l*dim*hidden_dim, hidden_dim, dim);
        for (int i = 0; i < dim; i++) { x[i] += s->xb[i]; }
    }
    rmsnorm(x, x, w->rms_final_weight, dim);
    matmul(s->logits, x, w->wcls, p->dim, p->vocab_size);
    return s->logits;
}

// ----------------------------------------------------------------------------
// Tokenizer


int compare_tokens(const void *a, const void *b) {
    return strcmp(((TokenIndex*)a)->str, ((TokenIndex*)b)->str);
}

void build_tokenizer(Tokenizer* t, int vocab_size) {
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
        t->vocab[i] = (char *)arena_alloc(len + 1);
        memcpy(t->vocab[i], tokenizer_data + offset, len);
        offset += len;
        t->vocab[i][len] = '\0';
    }
}

char* decode(Tokenizer* t, int prev_token, int token) {
    char *piece = t->vocab[token];
    if (prev_token == 1 && piece[0] == ' ') { piece++; }
    if (piece[0] == '<' && piece[1] == '0' && piece[2] == 'x') {
        char b1 = piece[3] >= 'a' ? (piece[3] - 'a' + 10) : (piece[3] - '0');
        char b2 = piece[4] >= 'a' ? (piece[4] - 'a' + 10) : (piece[4] - '0');
        unsigned char byte_val = b1 * 16 + b2;
        piece = (char*)t->byte_pieces + byte_val * 2;
    }
    return piece;
}

void safe_printf(char *piece) {
    if (piece == NULL || piece[0] == '\0') { return; }
    uart_puts(piece);
}

int str_lookup(char *str, TokenIndex *sorted_vocab, int vocab_size) {
    // bsearch is a stdlib function, so we use linear search.
    for(int i = 0; i < vocab_size; i++) {
        if (strcmp(str, sorted_vocab[i].str) == 0) {
            return sorted_vocab[i].id;
        }
    }
    return -1;
}

void simple_qsort(void* base, size_t nitems, size_t size, int (*compar)(const void*, const void*)) {
    char* arr = (char*)base;
    if (nitems == 0) return;
    for (size_t i = 0; i < nitems - 1; i++) {
        for (size_t j = 0; j < nitems - i - 1; j++) {
            if (compar(arr + j * size, arr + (j + 1) * size) > 0) {
                char temp[size];
                memcpy(temp, arr + j * size, size);
                memcpy(arr + j * size, arr + (j + 1) * size, size);
                memcpy(arr + (j + 1) * size, temp, size);
            }
        }
    }
}
#define qsort simple_qsort

void encode(Tokenizer* t, char *text, int8_t bos, int8_t eos, int *tokens, int *n_tokens) {
    if (t->sorted_vocab == NULL) {
        t->sorted_vocab = arena_alloc(t->vocab_size * sizeof(TokenIndex));
        for (int i = 0; i < t->vocab_size; i++) {
            t->sorted_vocab[i].str = t->vocab[i];
            t->sorted_vocab[i].id = i;
        }
        qsort(t->sorted_vocab, t->vocab_size, sizeof(TokenIndex), compare_tokens);
    }
    char* str_buffer = arena_alloc((t->max_token_length*2 + 3) * sizeof(char));
    *n_tokens = 0;
    if (bos) tokens[(*n_tokens)++] = 1;
    if (text[0] != '\0') {
        int dummy_prefix = str_lookup(" ", t->sorted_vocab, t->vocab_size);
        if(dummy_prefix != -1) tokens[(*n_tokens)++] = dummy_prefix;
    }

    for (char *c = text; *c != '\0'; c++) {
        size_t str_len = 1;
        str_buffer[0] = *c;
        str_buffer[1] = '\0';
        int id = str_lookup(str_buffer, t->sorted_vocab, t->vocab_size);
        if (id != -1) {
            tokens[(*n_tokens)++] = id;
        } else {
            tokens[(*n_tokens)++] = (unsigned char)str_buffer[0] + 3;
        }
    }
    while (1) {
        float best_score = -1e10; int best_id = -1; int best_idx = -1;
        for (int i=0; i < (*n_tokens-1); i++) {
            char* s1 = t->vocab[tokens[i]];
            char* s2 = t->vocab[tokens[i+1]];
            int l1 = strlen(s1); int l2 = strlen(s2);
            memcpy(str_buffer, s1, l1);
            memcpy(str_buffer + l1, s2, l2);
            str_buffer[l1+l2] = '\0';
            int id = str_lookup(str_buffer, t->sorted_vocab, t->vocab_size);
            if (id != -1 && t->vocab_scores[id] > best_score) {
                best_score = t->vocab_scores[id]; best_id = id; best_idx = i;
            }
        }
        if (best_idx == -1) { break; }
        tokens[best_idx] = best_id;
        for (int i = best_idx+1; i < (*n_tokens-1); i++) { tokens[i] = tokens[i+1]; }
        (*n_tokens)--;
    }
    if (eos) tokens[(*n_tokens)++] = 2;
}

// ----------------------------------------------------------------------------
// Sampler

int sample_argmax(float* probabilities, int n) {
    int max_i = 0; float max_p = probabilities[0];
    for (int i = 1; i < n; i++) { if (probabilities[i] > max_p) { max_i = i; max_p = probabilities[i]; } }
    return max_i;
}

int sample_mult(float* probabilities, int n, float coin) {
    float cdf = 0.0f;
    for (int i = 0; i < n; i++) { cdf += probabilities[i]; if (coin < cdf) { return i; } }
    return n - 1;
}

int compare_prob_index(const void* a, const void* b) {
    ProbIndex* a_ = (ProbIndex*) a; ProbIndex* b_ = (ProbIndex*) b;
    if (a_->prob > b_->prob) return -1; if (a_->prob < b_->prob) return 1; return 0;
}

int sample_topp(float* probabilities, int n, float topp, ProbIndex* probindex, float coin) {
    int n0 = 0;
    const float cutoff = (1.0f - topp) / (n - 1);
    for (int i = 0; i < n; i++) {
        if (probabilities[i] >= cutoff) { probindex[n0].index = i; probindex[n0].prob = probabilities[i]; n0++; }
    }
    qsort(probindex, n0, sizeof(ProbIndex), compare_prob_index);
    float cumulative_prob = 0.0f; int last_idx = n0 - 1;
    for (int i = 0; i < n0; i++) {
        cumulative_prob += probindex[i].prob;
        if (cumulative_prob > topp) { last_idx = i; break; }
    }
    float r = coin * cumulative_prob; float cdf = 0.0f;
    for (int i = 0; i <= last_idx; i++) {
        cdf += probindex[i].prob;
        if (r < cdf) { return probindex[i].index; }
    }
    return probindex[last_idx].index;
}

void build_sampler(Sampler* sampler, int vocab_size, float temperature, float topp, unsigned long long rng_seed) {
    sampler->vocab_size = vocab_size;
    sampler->temperature = temperature;
    sampler->topp = topp;
    sampler->rng_state = rng_seed;
    sampler->probindex = arena_alloc(sampler->vocab_size * sizeof(ProbIndex));
}

unsigned int random_u32(unsigned long long *state) {
    *state ^= *state >> 12; *state ^= *state << 25; *state ^= *state >> 27;
    return (*state * 0x2545F4914F6CDD1Dull) >> 32;
}
float random_f32(unsigned long long *state) {
    return (random_u32(state) >> 8) / 16777216.0f;
}

int sample(Sampler* sampler, float* logits) {
    int next;
    if (sampler->temperature == 0.0f) {
        next = sample_argmax(logits, sampler->vocab_size);
    } else {
        for (int q=0; q<sampler->vocab_size; q++) { logits[q] /= sampler->temperature; }
        softmax(logits, sampler->vocab_size);
        float coin = random_f32(&sampler->rng_state);
        if (sampler->topp <= 0 || sampler->topp >= 1) {
            next = sample_mult(logits, sampler->vocab_size, coin);
        } else {
            next = sample_topp(logits, sampler->vocab_size, sampler->topp, sampler->probindex, coin);
        }
    }
    return next;
}

// ----------------------------------------------------------------------------
// generation loop

void generate(Transformer *transformer, Tokenizer *tokenizer, Sampler *sampler, char *prompt, int steps) {
    char *empty_prompt = "";
    if (prompt == NULL) { prompt = empty_prompt; }

    int num_prompt_tokens = 0;
    int* prompt_tokens = arena_alloc((strlen(prompt)+3) * sizeof(int));
    encode(tokenizer, prompt, 1, 0, prompt_tokens, &num_prompt_tokens);

    if (num_prompt_tokens < 1) {
        uart_puts("ERROR: Prompt tokenization failed.\n");
        return;
    }

    int next;
    int token = prompt_tokens[0];
    int pos = 0;
    while (pos < steps) {
        float* logits = forward(transformer, token, pos);
        if (pos < num_prompt_tokens - 1) {
            next = prompt_tokens[pos + 1];
        } else {
            next = sample(sampler, logits);
        }
        pos++;
        if (next == 1) { break; }
        char* piece = decode(tokenizer, token, next);
        safe_printf(piece);
        token = next;
    }
    uart_puts("\n");
}

// ----------------------------------------------------------------------------
// main entry point

int main() {
    float temperature = 0.8f;
    float topp = 0.9f;
    int steps = 256;
    char *prompt = "I like cat";
    unsigned long long rng_seed = 1337;

    uart_puts("Bare-metal Llama2.c for RISC-V\n");
    uart_puts("--------------------------------\n");

    Transformer transformer;
    build_transformer(&transformer);
    if (steps <= 0 || steps > transformer.config.seq_len) steps = transformer.config.seq_len;

    Tokenizer tokenizer;
    build_tokenizer(&tokenizer, transformer.config.vocab_size);

    Sampler sampler;
    build_sampler(&sampler, transformer.config.vocab_size, temperature, topp, rng_seed);

    generate(&transformer, &tokenizer, &sampler, prompt, steps);

    uart_puts("\n--- DONE ---\n");

    return 0;
}
