# quantize.py (Corrected for stories*.bin models)
import numpy as np
import struct
import sys
import os

def quantize_model(input_path, output_path):
    with open(input_path, 'rb') as f_in:
        header_bytes = f_in.read(28)
        if len(header_bytes) != 28:
            print("Error: Could not read header.")
            return

        config = struct.unpack('iiiiiii', header_bytes)
        dim, hidden_dim, n_layers, n_heads, n_kv_heads, vocab_size, seq_len = config
        
        shared_weights = vocab_size > 0
        vocab_size = abs(vocab_size)

        # --- KEY CHANGE: DETECT MODEL TYPE ---
        # The stories*.bin models have hidden_dim = 4 * dim
        # The llama2 models have a different ratio. This is a good heuristic.
        is_stories_model = (hidden_dim == 4 * dim)
        if is_stories_model:
            print("Detected stories*.bin (GPT-2 style) model format.")
        else:
            print("Detected Llama-2 style model format.")

        print(f"Config: dim={dim}, hidden_dim={hidden_dim}, n_layers={n_layers}, vocab_size={vocab_size}")

        with open(output_path, 'wb') as f_out:
            f_out.write(header_bytes)

            tensor_shapes = {
                "token_embedding_table": (vocab_size, dim),
                "rms_att_weight": (n_layers, dim),
                "wq": (n_layers, dim * dim),
                "wk": (n_layers, dim * dim),
                "wv": (n_layers, dim * dim),
                "wo": (n_layers, dim * dim),
                "rms_ffn_weight": (n_layers, dim),
                "w1": (n_layers, hidden_dim * dim), # fc_in in GPT-2
                "w2": (n_layers, dim * hidden_dim), # fc_out in GPT-2
            }
            
            # --- KEY CHANGE: Conditionally add w3 ---
            if not is_stories_model:
                tensor_shapes["w3"] = (n_layers, hidden_dim * dim)

            tensor_shapes["rms_final_weight"] = (dim,)
            if not shared_weights:
                tensor_shapes["wcls"] = (vocab_size, dim)

            for name, shape in tensor_shapes.items():
                num_elements = np.prod(shape)
                print(f"Processing {name} with {num_elements} elements...")
                
                tensor_f32 = np.fromfile(f_in, dtype=np.float32, count=num_elements)
                if tensor_f32.size != num_elements:
                    print(f"Error: Mismatch in tensor size for {name}. Read {tensor_f32.size}, expected {num_elements}")
                    return

                scale = np.max(np.abs(tensor_f32)) / 127.0
                tensor_int8 = (tensor_f32 / scale).round().astype(np.int8)

                f_out.write(struct.pack('f', scale))
                f_out.write(tensor_int8.tobytes())
        
        # Check if we have read the whole file
        remaining_bytes = f_in.read()
        if len(remaining_bytes) != 0:
            print(f"Warning: {len(remaining_bytes)} bytes left in the file after processing all tensors.")


    print(f"\nSuccessfully quantized '{input_path}' to '{output_path}'")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 quantize.py <input_model.bin> <output_model_q80.bin>")
    else:
        quantize_model(sys.argv[1], sys.argv[2])
