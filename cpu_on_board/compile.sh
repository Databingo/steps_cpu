#!/bin/bash

# ==========================================================
# Quartus II Command-Line Compilation Script
# ==========================================================

# --- Configuration ---
# Your project's top-level name. This should match your .qpf file name.
# For example, if your project is "cpu_on_board.qpf", the name is "cpu_on_board".
PROJECT_NAME="cpu_on_board"

# --- Stop on any error ---
set -e

# --- Compilation Flow ---

echo "========================================="
echo "Starting Quartus II Compilation Flow..."
echo "Project: $PROJECT_NAME"
echo "========================================="
echo ""
#quartus_sh --flow compile ${PROJECT_NAME} --set_file_type riscv64.v=systemverilog
quartus_sh --toplevel ${PROJECT_NAME} --set_file_type riscv64.v=systemverilog

# Step 1: Analysis & Synthesis (quartus_map)
echo "[1/3] Running Analysis & Synthesis..."
quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
echo "Analysis & Synthesis complete."
echo ""

# Step 2: Fitter (quartus_fit)
echo "[2/3] Running Fitter (Place & Route)..."
quartus_fit --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
echo "Fitter complete."
echo ""

# Step 3: Assembler (quartus_asm)
echo "[3/3] Running Assembler..."
quartus_asm --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
echo "Assembler complete."
echo ""

echo "========================================="
echo "Compilation Successful!"
echo "Output file: output_files/${PROJECT_NAME}.sof"
echo "========================================="
