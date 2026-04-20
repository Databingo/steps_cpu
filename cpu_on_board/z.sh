cat riscv64.v > z2.txt 
cat cpu_on_board.v >> z2.txt 
cat clock_slower.v >> z2.txt 
cat sd_controller.v >> z2.txt 
cat sdram_controller.v >> z2.txt 
cat header.vh >> z2.txt 
echo "---------- mmu-itlb-dtlb, icache isr.s code---------" >> z2.txt
cat isr.s >> z2.txt 
#echo "---------- mini_kernel test code ---------" >> z2.txt
#cat mini_kernel.s >> z2.txt
echo "---------- device tree ---------" >> z2.txt
cat opensbi/b.dts >> z2.txt
echo "---------- opensbi config ---------" >> z2.txt
cat opensbi/bash_opensbi.sh >> z2.txt
echo "---------- bootloader code ---------" >> z2.txt
cat bootloader.s >> z2.txt
