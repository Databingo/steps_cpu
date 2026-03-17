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

# --- Compilation Flow ---

echo "========================================="
echo "Starting Quartus II Compilation Flow..."
echo "Project: $PROJECT_NAME"
echo "========================================="
echo ""




## ==========================================================
## Step 1.5: Extract and Print Resource Usage
## ==========================================================

echo "========================================="
echo "    SYNTHESIS RESOURCE USAGE ESTIMATE    "
echo "========================================="

# Quartus synthesis report
#MAP_SUMMARY="output_files/${PROJECT_NAME}.map.summary"
MAP_SUMMARY="output_files/${PROJECT_NAME}.fit.summary"
if [ ! -f "$MAP_SUMMARY" ]; then
    #MAP_SUMMARY="${PROJECT_NAME}.map.summary"
    MAP_SUMMARY="${PROJECT_NAME}.fit.summary"
fi

if [ -f "$MAP_SUMMARY" ]; then
    # Print the detailed hardware stats
    grep -E "Family|Device|logic elements|combinational functions|registers|pins|memory bits|Multiplier|PLLs" "$MAP_SUMMARY"
    
    # Extract just the number for combinational functions (removes text, spaces, and commas)
   #COMB_COUNT=$(grep -i "Total combinational functions" "$MAP_SUMMARY" | awk -F ':' '{print $2}' | tr -d ' ,')
    # Extract just the number for combinational functions (removes text, spaces, and commas)
    COMB_COUNT=$(grep -i "Total combinational functions" "$MAP_SUMMARY" | awk -F ':' '{print $2}' | awk -F '/' '{print $1}' | tr -d ' ,')
    
    # Failsafe in case extraction fails
    if [ -z "$COMB_COUNT" ]; then COMB_COUNT=0; fi

    echo "-----------------------------------------"
    echo "Resource Limit Check:"
    echo "Current Combinational Nodes: $COMB_COUNT"
    echo "Device Maximum Nodes:        $MAX_COMB_NODES"

    # Compare usage vs limits
    if [ "$COMB_COUNT" -gt "$MAX_COMB_NODES" ]; then
        echo "-----------------------------------------"
        echo "❌ ERROR: Design exceeds device capacity!"
        echo "Compilation aborted before Place & Route to save time."
        echo "Please optimize your combinational logic."
        echo "========================================="
        exit 1 # <--- THIS BREAKS AND STOPS THE SCRIPT
    else
        echo "✅ Resource check passed. Proceeding to Fitter..."
    fi
else
    echo "Warning: Could not find $MAP_SUMMARY to display resource usage."
fi
echo "========================================="
echo ""










