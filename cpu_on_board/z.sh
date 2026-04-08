cat riscv64.v > z2.txt 
cat cpu_on_board.v >> z2.txt 
cat clock_slower.v >> z2.txt 
cat sd_controller.v >> z2.txt 
cat sdram_controller.v >> z2.txt 
cat header.vh >> z2.txt 
echo "---------- rom inner isr.s---------" >> z2.txt
cat isr.s >> z2.txt 
echo "---------- ram test assembly code ---------" >> z2.txt
cat bootloader.s >> z2.txt
echo "---------- device tree ---------" >> z2.txt
cat opensbi/b.dts >> z2.txt
cat opensbi/bash_opensbi.sh >> z2.txt
#echo "---------- fw_jump.bin ---------" >> z2.txt
#cat fw_jump.bin.txt >> z2.txt
