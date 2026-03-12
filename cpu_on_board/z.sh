cat cpu_on_board.v > z2.txt 
cat riscv64.v >> z2.txt 
cat sd_controller.v >> z2.txt 
cat clock_slower.v >> z2.txt 
cat isr.s >> z2.txt 
cat copy_sd_to_sdram2.s >> z2.txt

cat z1.txt >  z.txt
cat z2.txt >> z.txt
