cat riscv64.v > z2.txt 
cat cpu_on_board.v >> z2.txt 
cat clock_slower.v >> z2.txt 
cat sd_controller.v >> z2.txt 
cat sdram_controller.v >> z2.txt 
echo "---------- rom inner isr.s---------" >> z2.txt
cat isr.s >> z2.txt 
echo "---------- ram test assembly code ---------" >> z2.txt
cat mini_sbi.s >> z2.txt
echo "---------- rom and ram ---------" >> z2.txt
#cat roam.mif >> z2.txt

#cat z1.txt >  z.txt
#cat z2.txt >> z.txt
