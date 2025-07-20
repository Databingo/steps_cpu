// llama2.go
package main

import (
	"encoding/binary"
	"math"
	"unsafe"
)

type Config struct {
	Dim       int
	HiddenDim int
	NLayers   int
	NHeads    int
	NKvHeads  int
	VocabSize int
	SeqLen    int
}

type TransformerWeights struct {
	TokenEmbeddingTable []float32
	RmsAttWeight        []float32
	RmsFfnWeight        []float32
	Wq                  []float32
	Wk                  []float32
	Wv                  []float32
	Wo                  []float32
	W1                  []float32
	W2                  []float32
	W3                  []float32
	RmsFinalWeight      []float32
	Wcls                []float32
}

type RunState struct {
	X          []float32
	Xb         []float32
	Xb2        []float32
	Hb         []float32
	Hb2        []float32
	Q          []float32
	K          []float32
	V          []float32
	Att        []float32
	Logits     []float32
	KeyCache   []float32
	ValueCache []float32
}

type Vocab struct {
	Words          []string
	Scores         []float32
	maxTokenLength int32
}

func (v *Vocab) id(s string) int {
	for idx, w := range v.Words {
		if w == s {
			return idx
		}
	}
	return -1
}

func (v *Vocab) Encode(text string) []int {
	tokens := make([]int, 0, len(text)+2)
	for _, r := range text {
		id := v.id(string(r))
		if id != -1 {
			tokens = append(tokens, id)
		}
	}

	for {
		bestScore := float32(-1e10)
		bestID := -1
		bestIdx := -1
		for i := 0; i < len(tokens)-1; i++ {
			str := v.Words[tokens[i]] + v.Words[tokens[i+1]]
			id := v.id(str)
			if id != -1 && v.Scores[id] > bestScore {
				bestScore = v.Scores[id]
				bestID = id
				bestIdx = i
			}
		}
		if bestIdx == -1 {
			break
		}
		tokens[bestIdx] = bestID
		tokens = append(tokens[:bestIdx+1], tokens[bestIdx+2:]...)
	}
	return tokens
}

func NewRunState(c *Config) *RunState {
	return &RunState{
		X:          make([]float32, c.Dim),
		Xb:         make([]float32, c.Dim),
		Xb2:        make([]float32, c.Dim),
		Hb:         make([]float32, c.HiddenDim),
		Hb2:        make([]float32, c.HiddenDim),
		Q:          make([]float32, c.Dim),
		K:          make([]float32, c.Dim),
		V:          make([]float32, c.Dim),
		Att:        make([]float32, c.NHeads*c.SeqLen),
		Logits:     make([]float32, c.VocabSize),
		KeyCache:   make([]float32, c.NLayers*c.SeqLen*c.Dim),
		ValueCache: make([]float32, c.NLayers*c.SeqLen*c.Dim),
	}
}

func Transformer(token, pos int, c *Config, s *RunState, w *TransformerWeights) {
	headSize := c.Dim / c.NHeads

	copy(s.X, w.TokenEmbeddingTable[token*c.Dim:(token+1)*c.Dim])

	for l := 0; l < c.NLayers; l++ {
		rmsnorm(s.Xb, s.X, w.RmsAttWeight[l*c.Dim:(l+1)*c.Dim])

		// For bare metal, we remove goroutines and do this sequentially.
		matmul(s.Q, s.Xb, w.Wq[l*c.Dim*c.Dim:(l+1)*c.Dim*c.Dim])
		matmul(s.K, s.Xb, w.Wk[l*c.Dim*c.Dim:(l+1)*c.Dim*c.Dim])
		matmul(s.V, s.Xb, w.Wv[l*c.Dim*c.Dim:(l+1)*c.Dim*c.Dim])

		// RoPE is skipped in stories models. This part would need the FreqCis tables.

		loff := l * c.SeqLen * c.Dim
		copy(s.KeyCache[loff+pos*c.Dim:], s.K)
		copy(s.ValueCache[loff+pos*c.Dim:], s.V)

		for h := 0; h < c.NHeads; h++ {
			q := s.Q[h*headSize : (h+1)*headSize]
			att := s.Att[h*c.SeqLen : (h+1)*c.SeqLen]
			for t := 0; t <= pos; t++ {
				k := s.KeyCache[loff+t*c.Dim+h*headSize : loff+t*c.Dim+(h+1)*headSize]
				var score float32
				for i := 0; i < headSize; i++ {
					score += q[i] * k[i]
				}

				att[t] = score / float32(math.Sqrt(float64(headSize)))
			}

			SoftMax(att[:pos+1])

			xb := s.Xb[h*headSize : (h+1)*headSize]
			for i := range xb {
				xb[i] = 0.0
			}
			for t := 0; t <= pos; t++ {
				v := s.ValueCache[loff+t*c.Dim+h*headSize : loff+t*c.Dim+(h+1)*headSize]
				a := att[t]
				for i := range v {
					xb[i] += a * v[i]
				}
			}
		}

		matmul(s.Xb2, s.Xb, w.Wo[l*c.Dim*c.Dim:(l+1)*c.Dim*c.Dim])
		accum(s.X, s.Xb2)
		rmsnorm(s.Xb, s.X, w.RmsFfnWeight[l*c.Dim:(l+1)*c.Dim])

		// FFN
		matmul(s.Hb, s.Xb, w.W1[l*c.Dim*c.HiddenDim:(l+1)*c.Dim*c.HiddenDim])
		matmul(s.Hb2, s.Xb, w.W3[l*c.Dim*c.HiddenDim:(l+1)*c.Dim*c.HiddenDim])

		for i := 0; i < c.HiddenDim; i++ {
			s.Hb[i] = s.Hb[i] * (1.0 / (1.0 + float32(math.Exp(-float64(s.Hb[i])))))
			s.Hb[i] = s.Hb[i] * s.Hb2[i]
		}

		matmul(s.Xb, s.Hb, w.W2[l*c.HiddenDim*c.Dim:(l+1)*c.HiddenDim*c.Dim])
		accum(s.X, s.Xb)
	}

	rmsnorm(s.X, s.X, w.RmsFinalWeight)
	matmul(s.Logits, s.X, w.Wcls)
}

// Helper functions that should be in nn.go but are here for simplicity
func accum(a, b []float32) {
	for i := range a {
		a[i] += b[i]
	}
}

func matmul(xout, x, w []float32) {
	n := len(x)
	d := len(w) / n
	for i := 0; i < d; i++ {
		var val float32
		for j := 0; j < n; j++ {
			val += w[i*n+j] * x[j]
		}
		xout[i] = val
	}
}

func rmsnorm(o, x, weight []float32) {
	var ss float32
	for _, v := range x {
		ss += v * v
	}
	ss /= float32(len(x))
	ss += 1e-5
	ss = 1.0 / float32(math.Sqrt(float64(ss)))
	for j := range o {
		o[j] = weight[j] * ss * x[j]
	}
}
