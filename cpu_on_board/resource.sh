#!/bin/bash

# ==========================================================
# Quartus II Command-Line Compilation Script
# ==========================================================

# --- Configuration ---
# Your project's top-level name. This should match your .qpf file name.
# For example, if your project is "cpu_on_board.qpf", the name is "cpu_on_board".
PROJECT_NAME="cpu_on_board"
MAX_COMB_NODES=18752

# --- Stop on any error ---
set -e
# ==========================================================
# Step 4: Extract and Print Resource Usage
# ==========================================================
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
