#!/bin/bash
source ~/.zshrc || source ~/.bashrc
cm

PROJECT_NAME="cpu_on_board"
SOF_FILE="output_files/${PROJECT_NAME}.sof"

# --- Stop on any error ---
set -e

# Create roam.mif base on rom.mif and ram.mif
bash roam.sh

# Update mif
quartus_cdb --read_settings_files=on --update_mif ${PROJECT_NAME} -c ${PROJECT_NAME}
rm -f output_files/${PROJECT_NAME}.sof

# Assembly
quartus_asm --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}

# Burn
set -e
quartus_pgm -m JTAG -c 1 --operation="P;${SOF_FILE}"

echo ""
echo "========================================="
echo "Programming Update Successful!"
echo "========================================="
 
bash monitor.sh
