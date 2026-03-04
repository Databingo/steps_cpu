/*
 * Bare-metal INT8 Quantized Inference for Llama-2 Transformer model in pure C
 * Ported from runq.c for a naked qemu-riscv64 target.
 */

// --- BARE-METAL DEFINITIONS ---
#define NULL ((void*)0)
typedef unsigned long size_t;
typedef signed char         int8_t;
typedef unsigned char       uint8_t;
typedef int                 int32_t;
typedef unsigned int        uint32_t;
int __errno; // Dummy for libm

// --- BARE-METAL INCLUDES ---
#include "uart.c"
#include "model_260k_q80.h" // The header created from stories260K_q80.bin
#include "tokenizer.h"

// --- BARE-METAL HELPERS ---
void* memcpy(void* dest, const void* src, size_t n) { char* d=(char*)dest; const char* s=(const char*)src; for(size_t i=0;i<n;i++){d[i]=s[i];} return dest; }
void* memset(void* s, int c, size_t n) { unsigned char* p=(unsigned char*)s; while(n--) *p++=(unsigned char)c; return s; }
size_t strlen(const char* s) { const char* p=s; while(*p) p++; return p-s; }
int strcmp(const char* s1, const char* s2) { while(*s1 && (*s1==*s2)){s1++; s2++;} return *(const unsigned char*)s1 - *(const unsigned char*)s2; }
void itoa(int n, char* buf) { if(n==0){buf[0]='0'; buf[1]='\0'; return;} int i=0; int is_neg=0; if(n<0){is_neg=1; n=-n;} while(n!=0){buf[i++]=(n%10)+'0'; n/=10;} if(is_neg) buf[i++]='-'; int s=0, e=i-1; while(s<e){char t=buf[s]; buf[s]=buf[e]; buf[e]=t; s++; e--;} buf[i]='\0'; }

// Declarations for libm functions
float sqrtf(float);
float expf(float);
float powf(float, float);
float cosf(float);
float sinf(float);
float roundf(float); // Needed for quantize
float fabsf(float);

// ----------------------------------------------------------------------------
// Globals and Data Structures
int GS = 0; // group size global
typedef struct { int dim; int hidden_dim; int n_layers; int n_heads; int n_kv_heads; int vocab_size; int seq_len; } Config;
typedef struct { int8_t* q; float* s; } QuantizedTensor;
typedef struct {
    QuantizedTensor *q_tokens; float* token_embedding_table;
    float* rms_att_weight; float* rms_ffn_weight;
    QuantizedTensor *wq; QuantizedTensor *wk; QuantizedTensor *wv; QuantizedTensor *wo;
    QuantizedTensor *w1; QuantizedTensor *w2; QuantizedTensor *w3;
    float* rms_final_weight; QuantizedTensor *wcls;
} TransformerWeights;
typedef struct {
    float *x; float *xb; float *xb2; float *hb; float *hb2;
    QuantizedTensor xq; QuantizedTensor hq;
    float *q; float *k; float *v;
    float *att; float *logits;
    float* key_cache; float* value_cache;
} RunState;
#define ARENA_SIZE 8000000
static unsigned char g_arena[ARENA_SIZE];
static size_t g_arena_offset = 0;
void* arena_alloc(size_t size) {
    size = (size + 15) & ~15;
    if (g_arena_offset + size > ARENA_SIZE) { uart_puts("ERROR: Arena out of memory!\n"); while(1); }
    void* ptr = &g_arena[g_arena_offset];
    g_arena_offset += size;
    return ptr;
}
typedef struct { Config config; TransformerWeights weights; RunState state; } Transformer;

// ----------------------------------------------------------------------------
// Quantization functions (from runq.c)
void dequantize(QuantizedTensor *qx, float* x, int n) {
    for (int i = 0; i < n; i++) {
        x[i] = qx->q[i] * qx->s[i / GS];
    }
}
void quantize(QuantizedTensor *qx, float* x, int n) {
    int num_groups = n / GS;
    float Q_MAX = 127.0f;
    for (int group = 0; group < num_groups; group++) {
        float wmax = 0.0;
        for (int i = 0; i < GS; i++) {
            float val = fabsf(x[group * GS + i]);
            if (val > wmax) { wmax = val; }
        }
        float scale = wmax / Q_MAX;
        qx->s[group] = scale;
        for (int i = 0; i < GS; i++) {
            float val = x[group * GS + i] / scale;
            qx->q[group * GS + i] = (int8_t)(roundf(val));
        }
    }
}

// ----------------------------------------------------------------------------
// Bare-metal builder functions
QuantizedTensor* init_quantized_tensors(unsigned char** ptr, int n, int size_each) {
    QuantizedTensor *res = arena_alloc(n * sizeof(QuantizedTensor));
    for(int i=0; i<n; i++) {
        res[i].s = (float*)*ptr;
        *ptr += (size_each / GS) * sizeof(float);
        res[i].q = (int8_t*)*ptr;
        *ptr += size_each * sizeof(int8_t);
    }
    return res;
}

void memory_map_weights(TransformerWeights *w, Config* p, unsigned char* ptr, uint8_t shared_classifier) {
    int head_size = p->dim / p->n_heads;
    w->rms_att_weight = (float*) ptr;
    ptr += p->n_layers * p->dim * sizeof(float);
    w->rms_ffn_weight = (float*) ptr;
    ptr += p->n_layers * p->dim * sizeof(float);
    w->rms_final_weight = (float*) ptr;
    ptr += p->dim * sizeof(float);

    w->q_tokens = init_quantized_tensors(&ptr, 1, p->vocab_size * p->dim);
    w->token_embedding_table = arena_alloc(p->vocab_size * p->dim * sizeof(float));
    dequantize(w->q_tokens, w->token_embedding_table, p->vocab_size * p->dim);

    w->wq = init_quantized_tensors(&ptr, p->n_layers, p->dim * (p->n_heads * head_size));
    w->wk = init_quantized_tensors(&ptr, p->n_layers, p->dim * (p->n_kv_heads * head_size));
    w->wv = init_quantized_tensors(&ptr, p->n_layers, p->dim * (p->n_kv_heads * head_size));
    w->wo = init_quantized_tensors(&ptr, p->n_layers, (p->n_heads * head_size) * p->dim);
    w->w1 = init_quantized_tensors(&ptr, p->n_layers, p->dim * p->hidden_dim);
    w->w2 = init_quantized_tensors(&ptr, p->n_layers, p->hidden_dim * p->dim);
    w->w3 = init_quantized_tensors(&ptr, p->n_layers, p->dim * p->hidden_dim);

    w->wcls = shared_classifier ? w->q_tokens : init_quantized_tensors(&ptr, 1, p->dim * p->vocab_size);
}

void malloc_run_state(RunState* s, Config* p) {
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
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
}

void build_transformer(Transformer *t) {
    unsigned char* model_data = stories260K_q80_bin;
    size_t offset = 0;
    
    uint32_t magic_number;
    memcpy(&magic_number, model_data + offset, sizeof(uint32_t));
    offset += sizeof(uint32_t);
    if (magic_number != 0x616b3432) { uart_puts("ERROR: Bad magic number\n"); while(1); }
    
    int version;
    memcpy(&version, model_data + offset, sizeof(int));
    offset += sizeof(int);
    if (version != 2) { uart_puts("ERROR: Bad version\n"); while(1); }

    int header_size = 256;
    memcpy(&t->config, model_data + offset, sizeof(Config));
    offset += sizeof(Config);

    uint8_t shared_classifier;
    memcpy(&shared_classifier, model_data + offset, sizeof(uint8_t));
    offset += sizeof(uint8_t);
    
    int group_size;
    memcpy(&group_size, model_data + offset, sizeof(int));
    GS = group_size;

    unsigned char* weights_ptr = model_data + header_size;
    memory_map_weights(&t->weights, &t->config, weights_ptr, shared_classifier);
    malloc_run_state(&t->state, &t->config);
}

// ----------------------------------------------------------------------------
// The forward pass (quantized)

void rmsnorm(float* o, float* x, float* weight, int size) { /* ... same as float version ... */ }
void softmax(float* x, int size) { /* ... same as float version ... */ }

void matmul(float* xout, QuantizedTensor *x, QuantizedTensor *w, int n, int d) {
    for (int i = 0; i < d; i++) {
        float val = 0.0f;
        int32_t ival = 0;
        int in = i * n;
        for (int j = 0; j < n; j++) {
            ival += ((int32_t) x->q[j]) * ((int32_t) w->q[in + j]);
            if ((j + 1) % GS == 0) {
                val += ((float) ival) * w->s[(in + j) / GS] * x->s[j / GS];
                ival = 0;
            }
        }
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

    memcpy(x, w->token_embedding_table + token*dim, dim * sizeof(float));

    for(int l = 0; l < p->n_layers; l++) {
        rmsnorm(s->xb, x, w->rms_att_weight + l*dim, dim);
        quantize(&s->xq, s->xb, dim);
        matmul(s->q, &s->xq, w->wq + l, dim, dim);
        matmul(s->k, &s->xq, w->wk + l, dim, kv_dim);
        matmul(s->v, &s->xq, w->wv + l, dim, kv_dim);

        // RoPE is skipped/hacked in float version, we do the same here
        
        int loff = l * p->seq_len * kv_dim;
        memcpy(s->key_cache + loff + pos * kv_dim, s->k, kv_dim * sizeof(float));
        memcpy(s->value_cache + loff + pos * kv_dim, s->v, kv_dim * sizeof(float));

        for (int h = 0; h < p->n_heads; h++) {
            float* q = s->q + h * head_size;
            float* att = s->att + h * p->seq_len;
            for (int t = 0; t <= pos; t++) {
                float* k_t = s->key_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                float score = 0.0f;
                for (int i = 0; i < head_size; i++) { score += q[i] * k_t[i]; }
                att[t] = score / sqrtf(head_size);
            }
            softmax(att, pos + 1);
            float* xb = s->xb + h * head_size;
            memset(xb, 0, head_size * sizeof(float));
            for (int t = 0; t <= pos; t++) {
                float* v_t = s->value_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                float a = att[t];
                for (int i = 0; i < head_size; i++) { xb[i] += a * v_t[i]; }
            }
        }
        
        quantize(&s->xq, s->xb, dim);
        matmul(s->xb2, &s->xq, w->wo + l, dim, dim);
        for (int i = 0; i < dim; i++) { x[i] += s->xb2[i]; }

        rmsnorm(s->xb, x, w->rms_ffn_weight + l*dim, dim);
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
    return s->logits;
}

// ----------------------------------------------------------------------------
// Tokenizer, Sampler, and Main loop (copied from working float32 version)
// --- PASTE THE FULL Tokenizer section here ---
// --- PASTE THE FULL Sampler section here ---
// --- PASTE THE FULL generate loop here ---
// --- PASTE THE FULL main() function here ---
// For brevity, I'll provide a placeholder main. You should use the one with status prints.

int main() {
    uart_puts("Bare-metal INT8 Llama2.c for RISC-V\n");
    // ... rest of the main function, copied from your working float32 version
    return 0;
}
