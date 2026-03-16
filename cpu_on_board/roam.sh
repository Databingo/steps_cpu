##!/bin/bash
## script: make_unified_mif.sh
#
## 1. Ensure rom.mif has exactly 512 lines (pad with zeros if needed)
## head -n 512 takes up to 512 lines.
## If it's short, yes '' | head -n ... generates the remaining zero lines.
#LINES_ROM=$(wc -l < rom.mif)
#PAD_ROM=$((512 - LINES_ROM))
#
#cat rom.mif > roam.txt
#if [ $PAD_ROM -gt 0 ]; then
#    yes '00000000000000000000000000000000' | head -n $PAD_ROM >> roam.txt
#fi
#
## 2. Ensure ram.mif has exactly 512 lines (pad with zeros if needed)
#LINES_RAM=$(wc -l < ram.mif)
#PAD_RAM=$((512 - LINES_RAM))
#
#cat ram.mif >> roam.txt
#if [ $PAD_RAM -gt 0 ]; then
#    yes '00000000000000000000000000000000' | head -n $PAD_RAM >> roam.txt
#fi
#
#echo "Created roam.txt (1024 lines)."


#!/bin/bash
# make_unified_mif.sh

#echo "DEPTH = 1024;" > roam.mif
echo "DEPTH = 2048;" > roam.mif
echo "WIDTH = 32;" >> roam.mif
echo "ADDRESS_RADIX = DEC;" >> roam.mif
echo "DATA_RADIX = BIN;" >> roam.mif
echo "" >> roam.mif
echo "CONTENT BEGIN" >> roam.mif

# Combine your rom and ram files into a temp file
cat rom.mif > temp.txt
LINES_ROM=$(wc -l < rom.mif)
PAD_ROM=$((512 - LINES_ROM))
if [ $PAD_ROM -gt 0 ]; then
    yes '00000000000000000000000000000000' | head -n $PAD_ROM >> temp.txt
fi

cat ram.mif >> temp.txt
LINES_RAM=$(wc -l < ram.mif)
#PAD_RAM=$((512 - LINES_RAM))
PAD_RAM=$((1024 - LINES_RAM))
if [ $PAD_RAM -gt 0 ]; then
    yes '00000000000000000000000000000000' | head -n $PAD_RAM >> temp.txt
fi

# Read temp file and format it into Altera MIF syntax
ADDRESS=0
while read -r line; do
    echo "$ADDRESS : $line;" >> roam.mif
    ADDRESS=$((ADDRESS + 1))
done < temp.txt

echo "END;" >> roam.mif
rm temp.txt

echo "Created valid Altera roam.mif"


