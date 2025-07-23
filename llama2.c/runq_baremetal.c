/*
 * Bare-metal INT8 Quantized Inference for Llama-2 Transformer model in pure C
 * Optimized version with alignment fix for float arrays and extra debug output.
 * Fixed dequantize to process all elements, enhanced forward and sample to prevent repetitive tokens.
 * Added debug checks for logits and intermediate states to diagnose hanging and output issues.
 */

// --- BARE-METAL DEFINITIONS ---
#define NULL ((void*)0)
typedef unsigned long size_t;
typedef signed char         int8_t;
typedef unsigned char       uint8_t;
typedef int                 int32_t;
int __errno;

// --- BARE-METAL INCLUDES ---
#include "uart.c"
#include "model_q80.h"
#include "tokenizer.h"

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
float roundf(float);
float fabsf(float);
float powf(float, float);
float cosf(float);
float sinf(float);

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
        if (c == '\r' || c == '\n') { // Enter key
            uart_puts("\n");
            break;
        } else if (c == 127 || c == '\b') { // Backspace
            if (i > 0) {
                i--;
                uart_puts("\b \b"); // Erase character on screen
            }
        } else {
            buffer[i++] = c;
            uart_putc(c); // Echo character
        }
    }
    buffer[i] = '\0';
}

// ----------------------------------------------------------------------------
// Globals and Data Structures
int GS = 0;
typedef struct { int dim; int hidden_dim; int n_layers; int n_heads; int n_kv_heads; int vocab_size; int seq_len; } Config;
typedef struct { int8_t* q; float* s; } QuantizedTensor;
typedef struct {
    float* rms_att_weight; float* rms_ffn_weight; float* rms_final_weight;
    QuantizedTensor* q_tokens; float* token_embedding_table;
    QuantizedTensor* wq; QuantizedTensor* wk; QuantizedTensor* wv; QuantizedTensor* wo;
    QuantizedTensor* w1; QuantizedTensor* w2; QuantizedTensor* w3;
    QuantizedTensor* wcls;
} TransformerWeights;
typedef struct {
    float *x; float *xb; float *xb2; float *hb; float *hb2;
    QuantizedTensor xq; QuantizedTensor hq;
    float *q; float *k; float *v;
    float *att; float *logits;
    float* key_cache; float* value_cache;
} RunState;
#define ARENA_SIZE 128000000
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
typedef struct { Config config; TransformerWeights weights; RunState state; } Transformer;
typedef struct { char *str; int id; } TokenIndex;
typedef struct {
    char** vocab; float* vocab_scores; TokenIndex *sorted_vocab;
    int vocab_size; unsigned int max_token_length; unsigned char byte_pieces[512];
} Tokenizer;
typedef struct { int vocab_size; float temperature; unsigned long long rng_state; } Sampler;

// Function Prototypes
void encode(Tokenizer* t, char *text, int8_t bos, int8_t eos, int *tokens, int *n_tokens);
void simple_qsort(void* base, size_t nitems, size_t size, int (*compar)(const void*, const void*));
char* decode(Tokenizer* t, int prev_token, int token);
int sample(Sampler* sampler, float* logits);

// ----------------------------------------------------------------------------
// Quantization functions
void dequantize(QuantizedTensor *qx, float* x, int n) { 
    char buf[32];
    uart_puts("   - Dequantizing token embeddings...\n");
    
    // Validate inputs
    if (qx == NULL || qx->q == NULL || qx->s == NULL || x == NULL) {
        uart_puts("ERROR: NULL pointer in dequantize!\n");
        while(1);
    }
    if (GS == 0) {
        uart_puts("ERROR: GS is 0, division by zero imminent!\n");
        while(1);
    }
    if (n % GS != 0) {
        uart_puts("ERROR: n is not divisible by GS!\n");
        itoa(n, buf); uart_puts("n: "); uart_puts(buf); uart_puts("\n");
        itoa(GS, buf); uart_puts("GS: "); uart_puts(buf); uart_puts("\n");
        while(1);
    }

    // Debug: Print input pointers and parameters
    uart_puts("     - qx->q pointer: "); itoa((int)(size_t)qx->q, buf); uart_puts(buf); uart_puts("\n");
    uart_puts("     - qx->s pointer: "); itoa((int)(size_t)qx->s, buf); uart_puts(buf); uart_puts("\n");
    uart_puts("     - x pointer: "); itoa((int)(size_t)x, buf); uart_puts(buf); uart_puts("\n");
    uart_puts("     - n value: "); itoa(n, buf); uart_puts(buf); uart_puts("\n");
    uart_puts("     - GS value: "); itoa(GS, buf); uart_puts(buf); uart_puts("\n");

    // Debug: Print first few q and s values
    uart_puts("     - First 4 q values: ");
    for (int k = 0; k < 4 && k < n; k++) {
        itoa(qx->q[k], buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");
    uart_puts("     - First 4 s values: ");
    for (int k = 0; k < 4 && k < n/GS; k++) {
        int* ival = (int*)&qx->s[k];
        itoa(*ival, buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");

    // Dequantize all elements
    int num_groups = n / GS;
    for (int group = 0; group < num_groups; group++) {
        float scale = qx->s[group];
        if (scale == 0.0f) {
            uart_puts("WARNING: Zero scale in group "); itoa(group, buf); uart_puts(buf); uart_puts("\n");
            scale = 1.0f; // Avoid division by zero
        }
        for (int i = 0; i < GS; i++) {
            int idx = group * GS + i;
            x[idx] = qx->q[idx] * scale;
            // Debug: Print first few dequantized values
            if (idx < 4) {
                int* fval = (int*)&x[idx];
                uart_puts("     - x["); itoa(idx, buf); uart_puts(buf); uart_puts("] = ");
                itoa(*fval, buf); uart_puts(buf); uart_puts("\n");
            }
        }
    }
    uart_puts("   - Dequantization complete.\n");
}
void quantize(QuantizedTensor *qx, float* x, int n) {
    int num_groups = n / GS;
    char buf[16];
    for (int group = 0; group < num_groups; group++) {
        float wmax = 0.0f;
        for (int i = 0; i < GS; i++) { float val = fabsf(x[group * GS + i]); if (val > wmax) { wmax = val; } }
        float scale = wmax / 127.0f;
        qx->s[group] = scale;
        for (int i = 0; i < GS; i++) { qx->q[group * GS + i] = (int8_t)(roundf(x[group * GS + i] / scale)); }
    }
}

// ----------------------------------------------------------------------------
// Bare-metal builder functions
QuantizedTensor* init_qtensor(unsigned char** ptr, int n, int size_each) {
    char buf[32];
    QuantizedTensor *res = arena_alloc(n * sizeof(QuantizedTensor));
    for (int i = 0; i < n; i++) {
        // Align *ptr to 4 bytes for float access
        size_t addr = (size_t)(*ptr);
        size_t misalignment = addr % 4;
        if (misalignment != 0) {
            *ptr += (4 - misalignment);
            uart_puts("     - Aligned ptr for qtensor "); itoa(i, buf); uart_puts(buf); uart_puts(" by ");
            itoa(4 - misalignment, buf); uart_puts(buf); uart_puts(" bytes\n");
        }
        res[i].s = (float*)*ptr;
        *ptr += (size_each / GS) * sizeof(float);
        res[i].q = (int8_t*)*ptr;
        *ptr += size_each * sizeof(int8_t);
    }
    return res;
}
void build_transformer(Transformer *t) {
    char buf[32];
    uart_puts("   - Starting build_transformer...\n");
    unsigned char* model_ptr = stories15M_q80_bin;
    if (model_ptr == NULL) {
        uart_puts("ERROR: Model data pointer is NULL!\n");
        while(1);
    }
    int header_size = 256;

    uart_puts("   - Reading header...\n");
    memcpy(&t->config, model_ptr + 8, sizeof(Config));
    uint8_t shared_classifier = *(uint8_t*)(model_ptr + 8 + sizeof(Config));
    GS = *(int*)(model_ptr + 8 + sizeof(Config) + 1);
    uart_puts("     - Config: dim="); itoa(t->config.dim, buf); uart_puts(buf);
    uart_puts(" hidden_dim="); itoa(t->config.hidden_dim, buf); uart_puts(buf);
    uart_puts(" n_layers="); itoa(t->config.n_layers, buf); uart_puts(buf);
    uart_puts(" vocab_size="); itoa(t->config.vocab_size, buf); uart_puts(buf);
    uart_puts(" seq_len="); itoa(t->config.seq_len, buf); uart_puts(buf);
    uart_puts("\n     - GS="); itoa(GS, buf); uart_puts(buf); uart_puts("\n");

    unsigned char* weights_ptr = model_ptr + header_size;
    Config* p = &t->config;
    TransformerWeights* w = &t->weights;
    int head_size = p->dim / p->n_heads;

    uart_puts("   - Mapping float weights...\n");
    w->rms_att_weight = (float*)weights_ptr; weights_ptr += p->n_layers * p->dim * sizeof(float);
    w->rms_ffn_weight = (float*)weights_ptr; weights_ptr += p->n_layers * p->dim * sizeof(float);
    w->rms_final_weight = (float*)weights_ptr; weights_ptr += p->dim * sizeof(float);

    uart_puts("   - Mapping quantized tokens...\n");
    w->q_tokens = init_qtensor(&weights_ptr, 1, p->vocab_size * p->dim);
    // Debug: Check q_tokens data
    uart_puts("     - q_tokens.q[0:3]: ");
    for (int i = 0; i < 4 && i < p->vocab_size * p->dim; i++) {
        itoa(w->q_tokens[0].q[i], buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n     - q_tokens.s[0:3]: ");
    for (int i = 0; i < 4 && i < p->vocab_size * p->dim / GS; i++) {
        int* fval = (int*)&w->q_tokens[0].s[i];
        itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");

    uart_puts("   - Allocating dequantized token table...\n");
    w->token_embedding_table = arena_alloc(p->vocab_size * p->dim * sizeof(float));
    
    uart_puts("   - Dequantizing token embeddings...\n");
    dequantize(w->q_tokens, w->token_embedding_table, p->vocab_size * p->dim);

    uart_puts("   - Mapping attention weights...\n");
    w->wq = init_qtensor(&weights_ptr, p->n_layers, p->dim * (p->n_heads * head_size));
    w->wk = init_qtensor(&weights_ptr, p->n_layers, p->dim * (p->n_kv_heads * head_size));
    w->wv = init_qtensor(&weights_ptr, p->n_layers, p->dim * (p->n_kv_heads * head_size));
    w->wo = init_qtensor(&weights_ptr, p->n_layers, (p->n_heads * head_size) * p->dim);

    uart_puts("   - Mapping FFN weights...\n");
    w->w1 = init_qtensor(&weights_ptr, p->n_layers, p->dim * p->hidden_dim);
    w->w2 = init_qtensor(&weights_ptr, p->n_layers, p->hidden_dim * p->dim);
    w->w3 = init_qtensor(&weights_ptr, p->n_layers, p->dim * p->hidden_dim);

    uart_puts("   - Mapping classifier...\n");
    w->wcls = shared_classifier ? w->q_tokens : init_qtensor(&weights_ptr, 1, p->dim * p->vocab_size);

    uart_puts("   - Allocating RunState...\n");
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    RunState* s = &t->state;
    s->x = arena_alloc(p->dim * sizeof(float));
    s->xb = arena_alloc(p->dim * sizeof(float));
    s->xb2 = arena_alloc(p->dim * sizeof(float));
    s->hb = arena_alloc(p->hidden_dim * sizeof(float));
    s->hb2 = arena_alloc(p->hidden_dim * sizeof(float));
    s->xq.q = arena_alloc(p->dim * sizeof(int8_t));
    s->xq.s = arena_alloc(p->dim / GS * sizeof(float));
    s->hq.q = arena_alloc(p->hidden_dim * sizeof(int8_t));
    s->hq.s = arena_alloc(p->hidden_dim / GS * sizeof(float));
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

// ----------------------------------------------------------------------------
// The forward pass (quantized)
void rmsnorm(float* o, float* x, float* w, int s) {
    char buf[32];
    float ss = 0.0f;
    for (int j = 0; j < s; j++) { ss += x[j] * x[j]; }
    ss /= s;
    ss += 1e-5f;
    if (ss == 0.0f) {
        uart_puts("ERROR: rmsnorm ss is zero!\n");
        return;
    }
    ss = 1.0f / sqrtf(ss);
    // Debug: Print ss for first call
    static int first_call = 1;
    if (first_call) {
        int* fval = (int*)&ss;
        uart_puts("rmsnorm ss: "); itoa(*fval, buf); uart_puts(buf); uart_puts("\n");
        first_call = 0;
    }
    for (int j = 0; j < s; j++) { o[j] = w[j] * (ss * x[j]); }
}
void softmax(float* x, int s) {
    if (s <= 0) return;
    float max = x[0];
    for (int i = 1; i < s; i++) { if (x[i] > max) max = x[i]; }
    float sum = 0.0f;
    for (int i = 0; i < s; i++) { x[i] = expf(x[i] - max); sum += x[i]; }
    if (sum == 0.0f) {
        uart_puts("ERROR: softmax sum is zero!\n");
        return;
    }
    for (int i = 0; i < s; i++) { x[i] /= sum; }
}
void matmul(float* xout, QuantizedTensor *x, QuantizedTensor *w, int n, int d) {
    char buf[32];
    for (int i = 0; i < d; i++) {
        float val = 0.0f;
        int32_t ival = 0;
        int in = i * n;
        for (int j = 0; j < n; j++) {
            ival += ((int32_t)x->q[j]) * ((int32_t)w->q[in + j]);
            if ((j + 1) % GS == 0) {
                float scale = w->s[(in + j) / GS] * x->s[j / GS];
                if (scale == 0.0f) {
                    uart_puts("WARNING: Zero scale in matmul, group "); itoa((in + j) / GS, buf); uart_puts(buf); uart_puts("\n");
                }
                val += ((float)ival) * scale;
                ival = 0;
            }
        }
        xout[i] = val;
        // Debug: Print first few outputs
        if (i < 4) {
            int* fval = (int*)&xout[i];
            uart_puts("matmul xout["); itoa(i, buf); uart_puts(buf); uart_puts("]: "); itoa(*fval, buf); uart_puts(buf); uart_puts("\n");
        }
    }
}
float* forward(Transformer* t, int token, int pos) {
    char buf[32];
    Config* p = &t->config;
    TransformerWeights* w = &t->weights;
    RunState* s = &t->state;
    float *x = s->x;
    int dim = p->dim;
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    int kv_mul = p->n_heads / p->n_kv_heads;
    int hidden_dim = p->hidden_dim;
    int head_size = dim / p->n_heads;
    if (token < 0 || token >= p->vocab_size) {
        uart_puts("ERROR: Invalid token ID in forward: "); itoa(token, buf); uart_puts(buf); uart_puts("\n");
        return s->logits;
    }
    memcpy(x, w->token_embedding_table + token * dim, dim * sizeof(float));
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
        rmsnorm(s->xb, x, w->rms_att_weight + l * dim, dim);
        quantize(&s->xq, s->xb, dim);
        matmul(s->q, &s->xq, w->wq + l, dim, dim);
        matmul(s->k, &s->xq, w->wk + l, dim, kv_dim);
        matmul(s->v, &s->xq, w->wv + l, dim, kv_dim);
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
            int head_dim_idx = i % head_size;
            float freq = 1.0f / powf(10000.0f, head_dim_idx / (float)head_size);
            float val = pos * freq;
            float fcr = cosf(val);
            float fci = sinf(val);
            int rotn = i < kv_dim ? 2 : 1;
            for (int v_idx = 0; v_idx < rotn; v_idx++) {
                float* vec = v_idx == 0 ? s->q : s->k;
                float v0 = vec[i];
                float v1 = vec[i + 1];
                vec[i] = v0 * fcr - v1 * fci;
                vec[i + 1] = v0 * fci + v1 * fcr;
            }
        }
        int loff = l * p->seq_len * kv_dim;
        memcpy(s->key_cache + loff + pos * kv_dim, s->k, kv_dim * sizeof(float));
        memcpy(s->value_cache + loff + pos * kv_dim, s->v, kv_dim * sizeof(float));
        for (int h = 0; h < p->n_heads; h++) {
            float* q = s->q + h * head_size;
            float* att = s->att + h * p->seq_len;
            for (int t_step = 0; t_step <= pos; t_step++) {
                float* k_t = s->key_cache + loff + t_step * kv_dim + (h / kv_mul) * head_size;
                float score = 0.0f;
                for (int i = 0; i < head_size; i++) { score += q[i] * k_t[i]; }
                att[t_step] = score / sqrtf(head_size);
            }
            softmax(att, pos + 1);
            float* xb = s->xb + h * head_size;
            memset(xb, 0, head_size * sizeof(float));
            for (int t_step = 0; t_step <= pos; t_step++) {
                float* v_t = s->value_cache + loff + t_step * kv_dim + (h / kv_mul) * head_size;
                float a = att[t_step];
                for (int i = 0; i < head_size; i++) { xb[i] += a * v_t[i]; }
            }
        }
        quantize(&s->xq, s->xb, dim);
        matmul(s->xb2, &s->xq, w->wo + l, dim, dim);
        for (int i = 0; i < dim; i++) { x[i] += s->xb2[i]; }
        rmsnorm(s->xb, x, w->rms_ffn_weight + l * dim, dim);
        quantize(&s->xq, s->xb, dim);
        matmul(s->hb, &s->xq, w->w1 + l, dim, hidden_dim);
        matmul(s->hb2, &s->xq, w->w3 + l, dim, hidden_dim);
        for (int i = 0; i < hidden_dim; i++) {
            float val = s->hb[i];
            val *= (1.0f / (1.0f + expf(-val)));
            val *= s->hb2[i];
            s->hb[i] = val;
        }
        quantize(&s->hq, s->hb, hidden_dim);
        matmul(s->xb, &s->hq, w->w2 + l, hidden_dim, dim);
        for (int i = 0; i < dim; i++) { x[i] += s->xb[i]; }
    }
    rmsnorm(x, x, w->rms_final_weight, dim);
    quantize(&s->xq, x, dim);
    matmul(s->logits, &s->xq, w->wcls, dim, p->vocab_size);
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
// Tokenizer, Sampler, and Main loop
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
    for (int i = 0; i < 256; i++) { t->byte_pieces[i * 2] = (unsigned char)i; t->byte_pieces[i * 2 + 1] = '\0'; }
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
            uart_puts("ERROR: Invalid token length at index "); itoa(i, buf); uart_puts(buf); uart_puts(": "); itoa(len, buf); uart_puts(buf); uart_puts("\n");
            while(1);
        }
        t->vocab[i] = (char*)arena_alloc(len + 1);
        memcpy(t->vocab[i], tokenizer_data + offset, len);
        offset += len;
        t->vocab[i][len] = '\0';
        // Debug: Print vocab entries around token 31999 and first few
        if (i < 5 || (i >= 31995 && i <= 32000)) {
            uart_puts("     - Vocab["); itoa(i, buf); uart_puts(buf); uart_puts("]: "); uart_puts(t->vocab[i]); uart_puts("\n");
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
    // Debug: Print token ID and string
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
    for (int i = 0; i < n; i++) { if (strcmp(s, v[i].str) == 0) return v[i].id; }
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
        if (id != -1) { tokens[(*n)++] = id; }
        else { tokens[(*n)++] = (unsigned char)str_buffer[0] + 3; }
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
        for (int i = best_idx + 1; i < (*n - 1); i++) { tokens[i] = tokens[i + 1]; }
        (*n)--;
    }
    if (eos) tokens[(*n)++] = 2;
}
int sample_argmax(float* p, int n) {
    int max_i = 0;
    float max_p = p[0];
    for (int i = 1; i < n; i++) { if (p[i] > max_p) { max_i = i; max_p = p[i]; } }
    return max_i;
}
unsigned int random_u32(unsigned long long* s) {
    *s ^= *s >> 12;
    *s ^= *s << 25;
    *s ^= *s >> 27;
    return (*s * 0x2545F4914F6CDD1Dull) >> 32;
}
float random_f32(unsigned long long* s) {
    return (random_u32(s) >> 8) / 16777216.0f;
}
int sample(Sampler* s, float* logits) {
    char buf[32];
    // Check for invalid logits
    float sum = 0.0f;
    int non_zero_count = 0;
    for (int i = 0; i < s->vocab_size; i++) {
        sum += logits[i];
        if (logits[i] != 0.0f) non_zero_count++;
    }
    if (sum == 0.0f || non_zero_count == 0) {
        uart_puts("ERROR: All logits are zero or invalid! Returning default token.\n");
        return 1; // Return BOS token as fallback
    }
    // Debug: Print top 5 logits
    uart_puts("Top 5 logits: ");
    for (int i = 0; i < 5 && i < s->vocab_size; i++) {
        int* fval = (int*)&logits[i];
        itoa(*fval, buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");
    if (s->temperature == 0.0f) {
        int token = sample_argmax(logits, s->vocab_size);
        uart_puts("Sampled (argmax) token ID: "); itoa(token, buf); uart_puts(buf); uart_puts("\n");
        return token;
    } else {
        for (int q = 0; q < s->vocab_size; q++) { logits[q] /= s->temperature; }
        softmax(logits, s->vocab_size);
        float coin = random_f32(&s->rng_state);
        // Debug: Print random value
        int* fval = (int*)&coin;
        uart_puts("Random coin: "); itoa(*fval, buf); uart_puts(buf); uart_puts("\n");
        float cdf = 0.0f;
        for (int i = 0; i < s->vocab_size; i++) {
            cdf += logits[i];
            if (coin < cdf) {
                uart_puts("Sampled (softmax) token ID: "); itoa(i, buf); uart_puts(buf); uart_puts("\n");
                return i;
            }
        }
        uart_puts("Sampled (fallback) token ID: "); itoa(s->vocab_size - 1, buf); uart_puts(buf); uart_puts("\n");
        return s->vocab_size - 1;
    }
}
void build_sampler(Sampler* s, int vocab_size, float temp, unsigned long long seed) {
    s->vocab_size = vocab_size;
    s->temperature = temp;
    s->rng_state = seed;
}
void generate(Transformer* t, Tokenizer* tok, Sampler* sampler, char* prompt, int steps) {
    char buf[64];
    int num_prompt;
    int* prompt_tokens = arena_alloc((strlen(prompt) + 3) * sizeof(int));
    encode(tok, prompt, 1, 0, prompt_tokens, &num_prompt);
    if (num_prompt < 1) {
        uart_puts("ERROR: Prompt tokenization failed.\n");
        return;
    }

    // Debug: Print prompt tokens
    uart_puts("Prompt tokens: ");
    for (int i = 0; i < num_prompt; i++) {
        itoa(prompt_tokens[i], buf); uart_puts(buf); uart_puts(" ");
    }
    uart_puts("\n");

    int token = prompt_tokens[0], pos = 0, next;
    while (pos < steps) {
        uart_puts("[ Token "); itoa(pos + 1, buf); uart_puts(buf);
        uart_puts(" / "); itoa(steps, buf); uart_puts(buf); uart_puts(" ] -> ");

        float* logits = forward(t, token, pos);
        if (pos < num_prompt - 1) {
            next = prompt_tokens[pos + 1];
        } else {
            next = sample(sampler, logits);
        }

        pos++;
        if (next == 1) break; // BOS token
        char* p = decode(tok, token, next);
        safe_printf(p);
        token = next;
    }
    uart_puts("\n");
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
    // Initialize UART (ensure uart.c initializes hardware correctly)
    // Assuming uart_init() exists in uart.c
    // uart_init();

    uart_puts("Enabling FPU...\n");
    //enable_fpu();
    // Test FPU
    float test_float = 1.0f;
    test_float = test_float * 2.0f;
    int* fval = (int*)&test_float;
    uart_puts("FPU test (2.0f): "); itoa(*fval, buf); uart_puts(buf); uart_puts("\n");

    float temp = 0.8f;
    int steps = 10; // Reduced for faster debugging
    unsigned long long seed = 1337;
    
    uart_puts("Bare-metal INT8 Llama2.c for RISC-V\n--------------------------------\n");
    
    uart_puts("1. Building transformer...\n");
    build_transformer(&transformer);
    uart_puts("   - Transformer built.\n");
    
    if (steps <= 0 || steps > transformer.config.seq_len)
        steps = transformer.config.seq_len;
    
    uart_puts("2. Building tokenizer...\n");
    build_tokenizer(&tokenizer, transformer.config.vocab_size);
    uart_puts("   - Tokenizer built.\n");
    
    uart_puts("3. Building sampler...\n");
    build_sampler(&sampler, transformer.config.vocab_size, temp, seed);
    uart_puts("   - Sampler built.\n");

    // Interactive prompt loop
    char input[MAX_INPUT_LEN];
    while (1) {
        uart_puts("\n--------------------------------\n");
        uart_puts("Enter prompt (or 'exit' to quit):\n> ");
        read_line(input, MAX_INPUT_LEN);
        
        // Check for exit command
        if (strcmp(input, "exit") == 0) {
            uart_puts("Exiting...\n");
            break;
        }
        
        // Skip empty input
        if (strlen(input) == 0) {
            uart_puts("Please enter a prompt\n");
            continue;
        }
        
        uart_puts("\nGenerating response...\n");
        uart_puts("--------------------------------\n");
        generate(&transformer, &tokenizer, &sampler, input, steps);
    }

    uart_puts("\n--------------------------------\n--- DONE ---\n");
    while (1); // Halt
    return 0;
}
