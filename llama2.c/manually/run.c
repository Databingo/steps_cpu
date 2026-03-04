/* Inference for Llama-2 Transformer model in pure C without libc */

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
    float* key_cache;
    float* value_cache;
} RunState;

typedef struct {
    Config config;
    TransformerWeights weights;
    RunState state;
    float* data;
} Transformer;

/* Custom Utility Functions */
unsigned long my_strlen(const char *s) {
    unsigned long len = 0;
    while (s[len]) len++;
    return len;
}

void my_memcpy(void *dest, const void *src, unsigned long n) {
    char *d = (char*)dest;
    const char *s = (char*)src;
    for (unsigned long i = 0; i < n; i++) d[i] = s[i];
}

void my_memset(void *s, int c, unsigned long n) {
    char *p = (char*)s;
    for (unsigned long i = 0; i < n; i++) p[i] = (char)c;
}

int my_strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char*)s1 - *(unsigned char*)s2;
}

/* Custom Math Functions */
float my_sqrtf(float x) {
    if (x <= 0.0f) return 0.0f;
    float guess = x;
    for (int i = 0; i < 10; i++) {
        guess = 0.5f * (guess + x / guess);
    }
    return guess;
}

float my_expf(float x) {
    float sum = 1.0f, term = 1.0f;
    for (int i = 1; i < 10; i++) {
        term *= x / i;
        sum += term;
    }
    return sum;
}

float my_powf(float base, float exp) {
    float result = 1.0f;
    for (int i = 0; i < (int)exp; i++) result *= base;
    return result;
}

float my_cosf(float x) {
    float sum = 1.0f, term = 1.0f;
    for (int i = 1; i < 5; i++) {
        term *= -x * x / (2 * i * (2 * i - 1));
        sum += term;
    }
    return sum;
}

float my_sinf(float x) {
    float sum = x, term = x;
    for (int i = 1; i < 5; i++) {
        term *= -x * x / (2 * i * (2 * i + 1));
        sum += term;
    }
    return sum;
}

/* Static Memory Pool */
#define MEMORY_POOL_SIZE (1024 * 1024 * 100) // 100 MB
static char memory_pool[MEMORY_POOL_SIZE];
static unsigned long memory_offset = 0;

void* my_alloc(unsigned long size) {
    if (memory_offset + size > MEMORY_POOL_SIZE) return (void*)0;
    void *ptr = &memory_pool[memory_offset];
    memory_offset += size;
    return ptr;
}

/* Transformer Functions */
void malloc_run_state(RunState* s, Config* p) {
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    s->x = (float*)my_alloc(p->dim * sizeof(float));
    s->xb = (float*)my_alloc(p->dim * sizeof(float));
    s->xb2 = (float*)my_alloc(p->dim * sizeof(float));
    s->hb = (float*)my_alloc(p->hidden_dim * sizeof(float));
    s->hb2 = (float*)my_alloc(p->hidden_dim * sizeof(float));
    s->q = (float*)my_alloc(p->dim * sizeof(float));
    s->key_cache = (float*)my_alloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->value_cache = (float*)my_alloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->att = (float*)my_alloc(p->n_heads * p->seq_len * sizeof(float));
    s->logits = (float*)my_alloc(p->vocab_size * sizeof(float));
    my_memset(s->x, 0, p->dim * sizeof(float));
    my_memset(s->xb, 0, p->dim * sizeof(float));
    my_memset(s->xb2, 0, p->dim * sizeof(float));
    my_memset(s->hb, 0, p->hidden_dim * sizeof(float));
    my_memset(s->hb2, 0, p->hidden_dim * sizeof(float));
    my_memset(s->q, 0, p->dim * sizeof(float));
    my_memset(s->key_cache, 0, p->n_layers * p->seq_len * kv_dim * sizeof(float));
    my_memset(s->value_cache, 0, p->n_layers * p->seq_len * kv_dim * sizeof(float));
    my_memset(s->att, 0, p->n_heads * p->seq_len * sizeof(float));
    my_memset(s->logits, 0, p->vocab_size * sizeof(float));
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
    ptr += p->seq_len * head_size; // Skip freq_cis_real and freq_cis_imag
    w->wcls = shared_weights ? w->token_embedding_table : ptr;
}

void build_transformer(Transformer *t, float* checkpoint_data) {
    t->data = checkpoint_data;
    my_memcpy(&t->config, checkpoint_data, sizeof(Config));
    int shared_weights = t->config.vocab_size > 0 ? 1 : 0;
    t->config.vocab_size = t->config.vocab_size < 0 ? -t->config.vocab_size : t->config.vocab_size;
    float* weights_ptr = checkpoint_data + sizeof(Config) / sizeof(float);
    memory_map_weights(&t->weights, &t->config, weights_ptr, shared_weights);
    malloc_run_state(&t->state, &t->config);
}

/* Neural Net Blocks */
void rmsnorm(float* o, float* x, float* weight, int size) {
    float ss = 0.0f;
    for (int j = 0; j < size; j++) ss += x[j] * x[j];
    ss /= size;
    ss += 1e-5f;
    ss = 1.0f / my_sqrtf(ss);
    for (int j = 0; j < size; j++) o[j] = weight[j] * (ss * x[j]);
}

void softmax(float* x, int size) {
    float max_val = x[0];
    for (int i = 1; i < size; i++) if (x[i] > max_val) max_val = x[i];
    float sum = 0.0f;
    for (int i = 0; i < size; i++) {
        x[i] = my_expf(x[i] - max_val);
        sum += x[i];
    }
    for (int i = 0; i < size; i++) x[i] /= sum;
}

void matmul(float* xout, float* x, float* w, int n, int d) {
    for (int i = 0; i < d; i++) {
        float val = 0.0f;
        for (int j = 0; j < n; j++) val += w[i * n + j] * x[j];
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
    int hidden_dim = p->hidden_dim;
    int head_size = dim / p->n_heads;

    my_memcpy(x, w->token_embedding_table + token * dim, dim * sizeof(float));

    for (unsigned long long l = 0; l < p->n_layers; l++) {
        rmsnorm(s->xb, x, w->rms_att_weight + l * dim, dim);
        int loff = l * p->seq_len * kv_dim;
        s->k = s->key_cache + loff + pos * kv_dim;
        s->v = s->value_cache + loff + pos * kv_dim;
        matmul(s->q, s->xb, w->wq + l * dim * dim, dim, dim);
        matmul(s->k, s->xb, w->wk + l * dim * kv_dim, dim, kv_dim);
        matmul(s->v, s->xb, w->wv + l * dim * kv_dim, dim, kv_dim);

        for (int i = 0; i < dim; i += 2) {
            int head_dim = i % head_size;
            float freq = 1.0f / my_powf(10000.0f, head_dim / (float)head_size);
            float val = pos * freq;
            float fcr = my_cosf(val);
            float fci = my_sinf(val);
            int rotn = i < kv_dim ? 2 : 1;
            for (int v = 0; v < rotn; v++) {
                float* vec = v == 0 ? s->q : s->k;
                float v0 = vec[i];
                float v1 = vec[i + 1];
                vec[i] = v0 * fcr - v1 * fci;
                vec[i + 1] = v0 * fci + v1 * fcr;
            }
        }

        for (int h = 0; h < p->n_heads; h++) {
            float* q = s->q + h * head_size;
            float* att = s->att + h * p->seq_len;
            for (int t = 0; t <= pos; t++) {
                float* k = s->key_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                float score = 0.0f;
                for (int i = 0; i < head_size; i++) score += q[i] * k[i];
                score /= my_sqrtf(head_size);
                att[t] = score;
            }
            softmax(att, pos + 1);
            float* xb = s->xb + h * head_size;
            my_memset(xb, 0, head_size * sizeof(float));
            for (int t = 0; t <= pos; t++) {
                float* v = s->value_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                float a = att[t];
                for (int i = 0; i < head_size; i++) xb[i] += a * v[i];
            }
        }

        matmul(s->xb2, s->xb, w->wo + l * dim * dim, dim, dim);
        for (int i = 0; i < dim; i++) x[i] += s->xb2[i];
        rmsnorm(s->xb, x, w->rms_ffn_weight + l * dim, dim);
        matmul(s->hb, s->xb, w->w1 + l * dim * hidden_dim, dim, hidden_dim);
        matmul(s->hb2, s->xb, w->w3 + l * dim * hidden_dim, dim, hidden_dim);

        for (int i = 0; i < hidden_dim; i++) {
            float val = s->hb[i];
            val *= (1.0f / (1.0f + my_expf(-val)));
            val *= s->hb2[i];
            s->hb[i] = val;
        }

        matmul(s->xb, s->hb, w->w2 + l * dim * hidden_dim, hidden_dim, dim);
        for (int i = 0; i < dim; i++) x[i] += s->xb[i];
    }

    rmsnorm(x, x, w->rms_final_weight, dim);
    matmul(s->logits, x, w->wcls, p->dim, p->vocab_size);
    return s->logits;
}

/* Simplified Main for Testing */
int main(void) {
    /* Assume checkpoint_data is preloaded externally */
    float* checkpoint_data = (float*)0; /* Placeholder: replace with actual data */
    Transformer transformer;
    build_transformer(&transformer, checkpoint_data);
    float* logits = forward(&transformer, 1, 0); /* Example forward pass */
    return 0;
}
