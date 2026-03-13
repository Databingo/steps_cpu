#!/bin/bash

# For example, if your project is "cpu_on_board.qpf", the name is "cpu_on_board".
PROJECT_NAME="cpu_on_board"
SOF_FILE="output_files/${PROJECT_NAME}.sof"

# --- Stop on any error ---
set -e

# --- Compilation Flow ---

echo "========================================="
echo "Starting Quartus II Compilation Flow..."
echo "Project: $PROJECT_NAME"
echo "========================================="
echo ""

## update mif
#quartus_cdb --update_mif ${PROJECT_NAME} -c ${PROJECT_NAME}
## Step 3: Assembler (quartus_asm) to SoF
#echo "[3/3] Running Assembler..."
#quartus_asm --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
#echo "Assembler complete."
#echo ""

quartus_asm --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}

# --- Stop on any error ---
set -e

quartus_pgm -m JTAG -c 1 --operation="P;${SOF_FILE}"

echo ""
echo "========================================="
echo "Programming Update Successful!"
echo "========================================="

bash monitor.sh
