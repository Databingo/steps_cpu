// nn.go
package main

import (
	"math"
	"math/rand"
	"sort"
)

// ArgMax returns the index of the maximum value in a slice.
func ArgMax(v []float32) int {
	maxI := 0
	maxP := v[0]
	for i, p := range v[1:] {
		if p > maxP {
			maxI = i + 1
			maxP = p
		}
	}
	return maxI
}

// Sample returns an index from a probability distribution.
func Sample(probabilities []float32) int {
	r := rand.Float32()
	var cdf float32
	for i, p := range probabilities {
		cdf += p
		if r < cdf {
			return i
		}
	}
	return len(probabilities) - 1 // in case of rounding errors
}

type probIndex struct {
	index int
	prob  float32
}

// SampleTopP (nucleus sampling) samples from the smallest set of tokens that exceed probability topp.
func SampleTopP(probabilities []float32, topp float32) int {
	var probIndexList []probIndex
	for i, p := range probabilities {
		probIndexList = append(probIndexList, probIndex{index: i, prob: p})
	}

	sort.Slice(probIndexList, func(i, j int) bool {
		return probIndexList[i].prob > probIndexList[j].prob
	})

	var cumulativeProb float32
	lastIdx := -1
	for i, p := range probIndexList {
		cumulativeProb += p.prob
		if cumulativeProb > topp {
			lastIdx = i
			break
		}
	}

	if lastIdx == -1 {
		lastIdx = len(probIndexList) - 1
	}

	r := rand.Float32() * cumulativeProb
	var cdf float32
	for i := 0; i <= lastIdx; i++ {
		cdf += probIndexList[i].prob
		if r < cdf {
			return probIndexList[i].index
		}
	}

	return probIndexList[lastIdx].index // in case of rounding errors
}

// SoftMax normalizes a slice of floats into a probability distribution.
func SoftMax(x []float32) {
	if len(x) == 0 {
		return
	}
	maxVal := x[0]
	for _, v := range x[1:] {
		if v > maxVal {
			maxVal = v
		}
	}
	var sum float32
	for i := range x {
		x[i] = float32(math.Exp(float64(x[i] - maxVal)))
		sum += x[i]
	}
	for i := range x {
		x[i] /= sum
	}
}
