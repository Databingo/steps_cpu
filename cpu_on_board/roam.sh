#!/bin/bash
# script: make_unified_mif.sh

# 1. Ensure rom.mif has exactly 512 lines (pad with zeros if needed)
# head -n 512 takes up to 512 lines.
# If it's short, yes '' | head -n ... generates the remaining zero lines.
LINES_ROM=$(wc -l < rom.mif)
PAD_ROM=$((512 - LINES_ROM))

cat rom.mif > roam.txt
if [ $PAD_ROM -gt 0 ]; then
    yes '00000000000000000000000000000000' | head -n $PAD_ROM >> roam.txt
fi

# 2. Ensure ram.mif has exactly 512 lines (pad with zeros if needed)
LINES_RAM=$(wc -l < ram.mif)
PAD_RAM=$((512 - LINES_RAM))

cat ram.mif >> roam.txt
if [ $PAD_RAM -gt 0 ]; then
    yes '00000000000000000000000000000000' | head -n $PAD_RAM >> roam.txt
fi

echo "Created roam.txt (1024 lines)."
