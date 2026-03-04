import sys
import os

def bin_to_text(input_file, output_file, word_size=32):
    """
    Convert a raw binary file to a text file for $readmemb.
    Each 32-bit word is written as a binary string (e.g., 10110011...).
    """
    try:
        with open(input_file, 'rb') as f:
            binary_data = f.read()
        
        with open(output_file, 'w') as f:
            # Process binary data in 32-bit chunks (4 bytes)
            for i in range(0, len(binary_data), 4):
                word = binary_data[i:i+4]
                if len(word) < 4:
                    # Pad with zeros if last word is incomplete
                    word = word + b'\x00' * (4 - len(word))
                # Convert to 32-bit binary string (big-endian)
                word_int = int.from_bytes(word, byteorder='little')
                binary_str = format(word_int, f'0{word_size}b')
                f.write(binary_str + '\n')
        print(f"Converted {input_file} to {output_file}")
    except Exception as e:
        print(f"Error converting binary: {e}")
        sys.exit(1)

if __name__ == "__main__":
    input_bin = "runq_baremetal.bin"
    output_txt = "binary_instructions.txt"
    if len(sys.argv) > 1:
        input_bin = sys.argv[1]
    if len(sys.argv) > 2:
        output_txt = sys.argv[2]
    if not os.path.exists(input_bin):
        print(f"Input file {input_bin} does not exist")
        sys.exit(1)
    bin_to_text(input_bin, output_txt)
