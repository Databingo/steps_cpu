#!/bin/bash

# ==========================================================
# Quartus II Command-Line Programming Script
# ==========================================================

# --- Configuration ---
PROJECT_NAME="cpu_on_board"
SOF_FILE="output_files/${PROJECT_NAME}.sof"

# --- Stop on any error ---
set -e

# --- Programming Flow ---

echo "========================================="
echo "Starting Quartus II Programmer..."
echo "SOF File: $SOF_FILE"
echo "========================================="
echo ""

# -m JTAG: Use JTAG mode
# -c 1: Use the first detected USB-Blaster cable
# -p <file>: Program the specified file
quartus_pgm -m JTAG -c 1 -p "${SOF_FILE}"

echo ""
echo "========================================="
echo "Programming Successful!"
echo "========================================="
