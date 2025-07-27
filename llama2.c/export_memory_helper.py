#!/usr/bin/env python3
"""
Memory helper script for llama2.c export
This script helps estimate memory requirements and provides recommendations
for exporting different model sizes.
"""

import argparse
import psutil
import os

def get_available_memory():
    """Get available system memory in GB"""
    memory = psutil.virtual_memory()
    return memory.available / (1024**3)

def estimate_model_memory(model_size_billions):
    """Estimate memory requirements for different model sizes in GB"""
    # Rough estimates based on model size
    # These are approximate and may vary based on model architecture
    estimates = {
        7: {
            "full_model": 14,  # ~2x model size for full precision
            "memory_efficient": 8,  # Layer-by-layer loading
            "ultra_low": 4,  # Direct safetensors reading
        },
        13: {
            "full_model": 26,
            "memory_efficient": 16,
            "ultra_low": 8,
        },
        30: {
            "full_model": 60,
            "memory_efficient": 36,
            "ultra_low": 18,
        },
        70: {
            "full_model": 140,
            "memory_efficient": 84,
            "ultra_low": 42,
        }
    }
    return estimates.get(model_size_billions, {"full_model": model_size_billions * 2})

def check_safetensors_availability(model_path):
    """Check if safetensors files are available"""
    import glob
    safetensors_files = glob.glob(os.path.join(model_path, "*.safetensors"))
    return len(safetensors_files) > 0

def main():
    parser = argparse.ArgumentParser(description="Memory helper for llama2.c export")
    parser.add_argument("--model-path", type=str, required=True, 
                       help="Path to the HuggingFace model")
    parser.add_argument("--model-size", type=int, 
                       help="Model size in billions (e.g., 7 for 7B model)")
    args = parser.parse_args()

    print("=== Memory Analysis for llama2.c Export ===")
    print()

    # Get available memory
    available_memory = get_available_memory()
    print(f"Available system memory: {available_memory:.1f} GB")
    print()

    # Check safetensors availability
    has_safetensors = check_safetensors_availability(args.model_path)
    print(f"Safetensors files available: {'Yes' if has_safetensors else 'No'}")
    print()

    # Estimate memory requirements
    if args.model_size:
        estimates = estimate_model_memory(args.model_size)
        print(f"Estimated memory requirements for {args.model_size}B model:")
        print(f"  Full model loading: {estimates['full_model']:.1f} GB")
        print(f"  Memory-efficient loading: {estimates['memory_efficient']:.1f} GB")
        if has_safetensors:
            print(f"  Ultra-low memory (safetensors): {estimates['ultra_low']:.1f} GB")
        print()

        # Provide recommendations
        print("=== Recommendations ===")
        if available_memory >= estimates['full_model']:
            print("✅ You have enough memory for full model loading")
            print("   Command: python3 export.py output_q80.bin --version 2 --hf <model_path>")
        elif available_memory >= estimates['memory_efficient']:
            print("⚠️  Use memory-efficient loading")
            print("   Command: python3 export.py output_q80.bin --version 2 --hf <model_path> --low-memory")
        elif has_safetensors and available_memory >= estimates['ultra_low']:
            print("⚠️  Use ultra-low memory mode (safetensors)")
            print("   Command: python3 export.py output_q80.bin --version 2 --hf <model_path> --ultra-low-memory")
        else:
            print("❌ Insufficient memory for this model size")
            print("   Consider:")
            print("   - Using a smaller model")
            print("   - Adding more RAM")
            print("   - Using a machine with more memory")
            print("   - Converting on a cloud instance")

    print()
    print("=== Available Export Options (Version 2 - Int8 Quantized) ===")
    print("1. Standard loading:")
    print("   python3 export.py output_q80.bin --version 2 --hf <model_path>")
    print()
    print("2. Memory-efficient loading:")
    print("   python3 export.py output_q80.bin --version 2 --hf <model_path> --low-memory")
    print()
    if has_safetensors:
        print("3. Ultra-low memory (safetensors):")
        print("   python3 export.py output_q80.bin --version 2 --hf <model_path> --ultra-low-memory")
        print()
    print("4. With device mapping (for GPU):")
    print("   python3 export.py output_q80.bin --version 2 --hf <model_path> --device-map auto")

if __name__ == "__main__":
    main() 