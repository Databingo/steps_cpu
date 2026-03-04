// main.go
package main

import (
	_ "embed"
	"encoding/binary"
	"machine"
	"math/rand"
	"unsafe"
)

//go:embed stories15M.bin
var modelData []byte

//go:embed tokenizer.bin
var tokenizerData []byte

func main() {
	uart := machine.UART0
	uart.Configure(machine.UARTConfig{})
	uart.Write([]byte("\n--- TinyGo Llama2 Bare-Metal for RISC-V ---\n"))

	// Hardcoded parameters
	temperature := 0.8
	steps := 256
	topp := 0.9
	prompt := "Once upon a time"
	rand.Seed(1337)

	// --- 1. Load Config ---
	config := readConfigFromBytes(modelData)
	isSharedWeights := config.VocabSize > 0
	if config.VocabSize < 0 {
		config.VocabSize = -config.VocabSize
	}

	// --- 2. Load Tokenizer ---
	vocab := readTokenizerFromBytes(tokenizerData, config.VocabSize)

	// --- 3. Load Weights ---
	weights := NewTransformerWeights(config, isSharedWeights, modelData[28:]) // 28 is sizeof(Config)

	// --- 4. Initialize State ---
	runState := NewRunState(config)
	promptTokens := vocab.Encode(prompt)

	// --- 5. Generation Loop ---
	token := 1 // BOS token
	pos := 0
	for pos < steps {
		Transformer(token, pos, config, runState, weights)

		var next int
		if pos < len(promptTokens) {
			next = promptTokens[pos]
		} else {
			if temperature == 0 {
				next = ArgMax(runState.Logits)
			} else {
				for q := 0; q < config.VocabSize; q++ {
					runState.Logits[q] /= float32(temperature)
				}
				SoftMax(runState.Logits)
				if topp <= 0 || topp >= 1 {
					next = Sample(runState.Logits)
				} else {
					next = SampleTopP(runState.Logits, float32(topp))
				}
			}
		}

		if next == 1 {
			break
		} // End of sequence

		tokenStr := vocab.Words[next]
		if token == 1 && tokenStr[0] == ' ' {
			uart.Write([]byte(tokenStr[1:]))
		} else {
			uart.Write([]byte(tokenStr))
		}

		token = next
		pos++
	}

	uart.Write([]byte("\n--- DONE ---\n"))
	for {
	} // Hang
}

func readConfigFromBytes(data []byte) *Config {
	return &Config{
		Dim:       int(binary.LittleEndian.Uint32(data[0:4])),
		HiddenDim: int(binary.LittleEndian.Uint32(data[4:8])),
		NLayers:   int(binary.LittleEndian.Uint32(data[8:12])),
		NHeads:    int(binary.LittleEndian.Uint32(data[12:16])),
		NKvHeads:  int(binary.LittleEndian.Uint32(data[16:20])),
		VocabSize: int(binary.LittleEndian.Uint32(data[20:24])),
		SeqLen:    int(binary.LittleEndian.Uint32(data[24:28])),
	}
}

func readTokenizerFromBytes(data []byte, vocabSize int) *Vocab {
	vocab := &Vocab{
		Words:  make([]string, vocabSize),
		Scores: make([]float32, vocabSize),
	}
	offset := 0
	vocab.maxTokenLength = int32(binary.LittleEndian.Uint32(data[offset:]))
	offset += 4

	for i := 0; i < vocabSize; i++ {
		// score
		vocab.Scores[i] = unsafe.Slice((*float32)(unsafe.Pointer(&data[offset])), 1)[0]
		offset += 4
		// len
		length := int(binary.LittleEndian.Uint32(data[offset:]))
		offset += 4
		// string
		vocab.Words[i] = string(data[offset : offset+length])
		offset += length
	}
	return vocab
}

func NewTransformerWeights(c *Config, sharedWeights bool, data []byte) *TransformerWeights {
	floatData := unsafe.Slice((*float32)(unsafe.Pointer(&data[0])), len(data)/4)
	w := &TransformerWeights{}
	offset := 0

	w.TokenEmbeddingTable = floatData[offset : offset+c.VocabSize*c.Dim]
	offset += len(w.TokenEmbeddingTable)
	w.RmsAttWeight = floatData[offset : offset+c.NLayers*c.Dim]
	offset += len(w.RmsAttWeight)
	w.Wq = floatData[offset : offset+c.NLayers*c.Dim*c.Dim]
	offset += len(w.Wq)
	w.Wk = floatData[offset : offset+c.NLayers*c.Dim*c.Dim]
	offset += len(w.Wk)
	w.Wv = floatData[offset : offset+c.NLayers*c.Dim*c.Dim]
	offset += len(w.Wv)
	w.Wo = floatData[offset : offset+c.NLayers*c.Dim*c.Dim]
	offset += len(w.Wo)
	w.RmsFfnWeight = floatData[offset : offset+c.NLayers*c.Dim]
	offset += len(w.RmsFfnWeight)
	w.W1 = floatData[offset : offset+c.NLayers*c.Dim*c.HiddenDim]
	offset += len(w.W1)
	w.W2 = floatData[offset : offset+c.NLayers*c.HiddenDim*c.Dim]
	offset += len(w.W2)
	w.W3 = floatData[offset : offset+c.NLayers*c.Dim*c.HiddenDim]
	offset += len(w.W3)
	w.RmsFinalWeight = floatData[offset : offset+c.Dim]
	offset += len(w.RmsFinalWeight)

	// Note: The stories checkpoints do not have freq_cis tables or a separate wcls.
	if sharedWeights {
		w.Wcls = w.TokenEmbeddingTable
	} else {
		w.Wcls = floatData[offset : offset+c.VocabSize*c.Dim]
	}

	return w
}
