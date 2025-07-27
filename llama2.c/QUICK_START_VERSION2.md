# Quick Start: Version 2 (Int8 Quantized) Export

This guide helps you export HuggingFace models to llama2.c format with **int8 quantization** (version 2), which creates much smaller files (~75% reduction in size).

## Your Command (7B Model)

Based on your original command, here's the corrected version for int8 quantization:

```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf --low-memory
```

## What This Does

- **`--version 2`**: Creates int8 quantized model (Q8_0 format)
- **`--low-memory`**: Uses memory optimization to handle limited RAM
- **Output**: `llama_7b_q80.bin` (~3.5GB instead of ~13GB)

## Step-by-Step Process

### 1. Check Your System
```bash
python3 export_memory_helper.py --model-path ../../Llama-2-7b-hf --model-size 7
```

### 2. Install Dependencies (if needed)
```bash
pip install transformers safetensors psutil
```

### 3. Run the Export
```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf --low-memory
```

### 4. Monitor Progress
The script will show:
- Loading model configuration
- Converting embedding weights
- Converting layer weights (1/32, 2/32, etc.)
- Quantization progress for each weight tensor
- Final file size

## Memory Requirements

| Your RAM | Recommended Command |
|----------|-------------------|
| 8GB+     | `--low-memory` (recommended) |
| 4GB+     | `--ultra-low-memory` (if safetensors available) |
| <4GB     | Consider using a smaller model or more RAM |

## Alternative Commands

### If you have more RAM (16GB+):
```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf
```

### If you have safetensors files:
```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf --ultra-low-memory
```

### If you have GPU:
```bash
python3 export.py llama_7b_q80.bin --version 2 --hf ../../Llama-2-7b-hf --device-map auto --low-memory
```

## Expected Output

- **Input**: HuggingFace model (~13GB)
- **Output**: `llama_7b_q80.bin` (~3.5GB)
- **Time**: 10-30 minutes depending on your system
- **Memory**: ~8GB peak usage with `--low-memory`

## Troubleshooting

### Out of Memory Error
1. Close other applications
2. Use `--ultra-low-memory` if safetensors available
3. Consider using a machine with more RAM

### Slow Progress
- This is normal for memory-efficient modes
- The quantization process takes time
- Be patient, especially for larger models

### Missing Files
- Ensure the model path is correct
- Check that you have read permissions
- Verify the model is a valid HuggingFace format

## Success Indicators

When successful, you'll see:
- "Model loading completed!"
- Quantization progress for all layers
- "wrote llama_7b_q80.bin"
- File size around 3.5GB for 7B model

The resulting `llama_7b_q80.bin` file can be used with the llama2.c inference code. 