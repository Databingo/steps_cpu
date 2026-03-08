file combined.o
riscv64-unknown-elf-ld -o final.elf combined.o  -Ttext 0x0 -Tdata 0x1000 
riscv64-unknown-elf-objcopy -O binary final.elf final.bin
#riscv64-unknown-elf-objdump -d final.elf
