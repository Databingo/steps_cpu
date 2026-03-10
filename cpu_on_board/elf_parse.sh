bash test.sh
file combined.o
riscv64-unknown-elf-ld -o final.elf combined.o  -Ttext 0x0 -Tdata 0x1000  # linker
riscv64-unknown-elf-readelf -h final.elf
riscv64-unknown-elf-objcopy -O binary final.elf final.bin  # to binary
#riscv64-unknown-elf-readelf -S final.elf
riscv64-unknown-elf-objdump -b binary -m riscv -D final.bin

