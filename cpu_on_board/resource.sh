#!/bin/bash

# ==========================================================
# Quartus II Command-Line Compilation Script
# ==========================================================

# --- Configuration ---
PROJECT_NAME="cpu_on_board"

# --- Stop on any error ---
set -e

# --- Compilation Flow ---

echo "========================================="
echo "Starting Quartus II Compilation Flow..."
echo "Project: $PROJECT_NAME"
echo "========================================="
echo ""

## Step 1: Analysis & Synthesis (quartus_map)
#echo "[1/3] Running Analysis & Synthesis..."
#quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
#echo "Analysis & Synthesis complete."
#echo ""
#
## Step 2: Fitter (quartus_fit)
#echo "[2/3] Running Fitter (Place & Route)..."
#quartus_fit --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
#echo "Fitter complete."
#echo ""
#
## Step 3: Assembler (quartus_asm)
#echo "[3/3] Running Assembler..."
#quartus_asm --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
#echo "Assembler complete."
#echo ""
#
## ==========================================================
## Step 4: Extract and Print Resource Usage
## ==========================================================
echo "========================================="
echo "        RESOURCE USAGE SUMMARY           "
echo "========================================="

# Quartus puts the report in output_files/ by default, but sometimes in the root directory.
SUMMARY_FILE="output_files/${PROJECT_NAME}.fit.summary"
if [ ! -f "$SUMMARY_FILE" ]; then
    SUMMARY_FILE="${PROJECT_NAME}.fit.summary"
fi

if [ -f "$SUMMARY_FILE" ]; then
    # We use grep to filter out the date/version lines and only show the hardware stats
    grep -E "Family|Device|Total logic elements|Total combinational functions|Dedicated logic registers|Total registers|Total pins|Total memory bits|Embedded Multiplier|Total RAM|Total PLLs" "$SUMMARY_FILE"
else
    echo "Warning: Could not find $SUMMARY_FILE to display resource usage."
fi

echo ""
echo "========================================="
echo "Compilation Successful!"
echo "Output file: output_files/${PROJECT_NAME}.sof"
echo "========================================="
