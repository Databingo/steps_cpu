bash test.sh
file caled.o
#file combined.o
riscv64-unknown-elf-ld -o final.elf caled.o  -Ttext 0x0 -Tdata 0x1000  # linker
#riscv64-unknown-elf-ld -o final.elf combined.o  -Ttext 0x0 -Tdata 0x1000  # linker
riscv64-unknown-elf-readelf -h final.elf
riscv64-unknown-elf-objcopy -O binary final.elf final.bin  # to binary
#riscv64-unknown-elf-readelf -S final.elf
riscv64-unknown-elf-objdump -b binary -m riscv -D final.bin


hexdump -v -e '1/4 "%08x" "\n"' final.bin | perl -ne 'print unpack("B32", pack("N", hex($_))) . "\n"' > bin.txt

