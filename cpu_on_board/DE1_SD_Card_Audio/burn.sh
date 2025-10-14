#!/bin/bash

# ==========================================================
# Quartus II Command-Line Programming Script (for v13.0)
# ==========================================================

# --- Configuration ---
PROJECT_NAME="DE1_SD_Card_Audio"
SOF_FILE="output_files/${PROJECT_NAME}.sof"
# Get the device ID from jtagconfig. Example: 020B30DD
# You can uncomment and set this for more robust programming.
# DEVICE_ID="@1" # @1 means the first device on the chain

# --- Stop on any error ---
set -e

# --- Programming Flow ---

echo "========================================="
echo "Starting Quartus II Programmer..."
echo "SOF File: $SOF_FILE"
echo "========================================="
echo ""

# In Quartus 13.0, you don't use the '-p' flag.
# You create a temporary chain and specify the action and file together.
# --operation="P;${SOF_FILE}${DEVICE_ID}" means:
# P = Program
# ; = separator
# ${SOF_FILE} = The file to use
# ${DEVICE_ID} = (Optional) The specific device on the chain to program

quartus_pgm -m JTAG -c 1 --operation="P;${SOF_FILE}"

echo ""
echo "========================================="
echo "Programming Successful!"
echo "========================================="
