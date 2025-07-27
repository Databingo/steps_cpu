# Memory Optimization for llama2.c Export (Version 2 - Int8 Quantized)

This document explains the memory optimization features added to the `export.py` script to handle large models with limited RAM, specifically for **version 2 (int8 quantized)** export.

## Problem

The original export script loads the entire HuggingFace model into memory at once, which requires approximately 2x the model size in RAM. For a 7B model, this means ~14GB of RAM, which can cause out-of-memory errors on systems with limited resources.

## Version 2 Benefits

**Version 2 export creates int8 quantized models** which:
- Reduces model size by ~75% (from ~13GB to ~3.5GB for 7B model)
- Uses Q8_0 quantization (symmetric int8, range [-127, 127])
- Keeps normalization parameters in fp32 for accuracy
- Quantizes weights in groups to minimize quantization error

## Solution

Three levels of memory optimization have been implemented:

### 1. Memory-Efficient Loading (Default)

**Memory usage**: ~1.2x model size
**Command**: `python3 export.py output.bin --version 2 --hf <model_path>`

- Loads the model with `low_cpu_mem_usage=True`
- Processes weights layer by layer
- Immediately converts and frees memory after each layer
- Forces garbage collection between layers
- **Creates int8 quantized output (~75% smaller)**

### 2. Low Memory Mode

**Memory usage**: ~1.1x model size
**Command**: `python3 export.py output.bin --version 2 --hf <model_path> --low-memory`

- Enables additional memory optimizations
- Sets CUDA memory allocation limits
- Disables CUDA optimizations that use extra memory
- Uses deterministic operations
- **Creates int8 quantized output (~75% smaller)**

### 3. Ultra-Low Memory Mode (Safetensors)

**Memory usage**: ~0.6x model size
**Command**: `python3 export.py output.bin --version 2 --hf <model_path> --ultra-low-memory`

- Loads weights directly from safetensors files
- Never loads the full model into memory
- Processes one layer at a time
- Requires safetensors files to be present
- **Creates int8 quantized output (~75% smaller)**

## Memory Requirements by Model Size (Version 2 - Int8 Quantized)

| Model Size | Standard Loading | Memory-Efficient | Ultra-Low Memory | Output Size |
|------------|------------------|------------------|------------------|-------------|
| 7B         | ~14 GB          | ~8 GB           | ~4 GB           | ~3.5 GB     |
| 13B        | ~26 GB          | ~16 GB          | ~8 GB           | ~6.5 GB     |
| 30B        | ~60 GB          | ~36 GB          | ~18 GB          | ~15 GB      |
| 70B        | ~140 GB         | ~84 GB          | ~42 GB          | ~35 GB      |

**Note**: Output size is the final quantized .bin file size, which is ~75% smaller than the original model.

## Usage Examples (Version 2 - Int8 Quantized)

### For 7B models with 8GB RAM:
```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf --low-memory
```

### For 13B models with 16GB RAM:
```bash
python3 export.py llama_13b_q80.bin --version 2 --hf ../../Llama-2-13b-hf --low-memory
```

### For any model with safetensors files:
```bash
python3 export.py model_q80.bin --version 2 --hf <model_path> --ultra-low-memory
```

### Using GPU (if available):
```bash
python3 export.py model_q80.bin --version 2 --hf <model_path> --device-map auto --low-memory
```

### Your specific case (7B model):
```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf --low-memory
```

## Memory Helper Script

Use the memory helper script to analyze your system and get recommendations:

```bash
python3 export_memory_helper.py --model-path ../../Llama-2-7b-hf --model-size 7
```

This will:
- Check your available system memory
- Verify safetensors availability
- Estimate memory requirements
- Provide specific command recommendations for version 2 export

## Troubleshooting

### Out of Memory Errors

1. **Try memory-efficient mode first**:
   ```bash
   python3 export.py output_q80.bin --version 2 --hf <model_path> --low-memory
   ```

2. **If safetensors files are available, use ultra-low memory mode**:
   ```bash
   python3 export.py output_q80.bin --version 2 --hf <model_path> --ultra-low-memory
   ```

3. **Close other applications** to free up RAM

4. **Use a smaller model** if available

5. **Version 2 is more memory-efficient** than version 0/1 because it quantizes weights

### Missing Dependencies

Install required packages:
```bash
pip install transformers safetensors psutil
```

### Slow Performance

- Memory-efficient modes are slower but use less RAM
- Consider using GPU if available: `--device-map auto`
- The trade-off is between speed and memory usage

## Technical Details

### Memory-Efficient Loading
- Uses `AutoModelForCausalLM.from_pretrained()` with `low_cpu_mem_usage=True`
- Processes state dict entries one by one
- Immediately moves tensors to CPU and frees GPU memory
- Forces garbage collection after each layer

### Ultra-Low Memory Loading
- Uses `safetensors.safe_open()` to read weights directly
- Never loads the full model structure
- Processes one layer at a time from disk
- Requires safetensors format (faster and safer than pickle)

### Device Mapping
- `cpu`: Load everything on CPU (safest, slowest)
- `auto`: Automatically distribute across available devices
- Specific device: `cuda:0`, `cuda:1`, etc.

## Performance Comparison

| Mode | Memory Usage | Speed | Compatibility |
|------|-------------|-------|---------------|
| Standard | High | Fast | All models |
| Memory-Efficient | Medium | Medium | All models |
| Ultra-Low | Low | Slow | Safetensors only |

Choose the mode that best fits your available memory and time constraints. 