bash test.sh
file relocatable.elf
riscv64-unknown-elf-objdump  -d  relocatable.elf 
riscv64-unknown-elf-objdump  -r  relocatable.elf 

exit

#file combined.o
 
#hexdump -v -e '1/4 "%08x" "\n"' caled.o
#riscv64-unknown-elf-objdump -b binary -m riscv -D caled.o
echo "---read relocatable.elf relacatbal elf --- "
riscv64-unknown-elf-readelf --all  relocatable.elf
 
riscv64-unknown-elf-ld -o linked.elf   relocatable.elf  -Ttext 0x0 -Tdata 0x1000  # linker
#riscv64-unknown-elf-ld -o final.elf combined.o  -Ttext 0x0 -Tdata 0x1000  # linker
#riscv64-unknown-elf-readelf -h  linked_caled.elf
#riscv64-unknown-elf-readelf -S  linked_caled.elf
echo "---read linked.elf  --- "
riscv64-unknown-elf-readelf --all  linked.elf

echo "---check linked.elf  --- "
riscv64-unknown-elf-objdump -d linked.elf
riscv64-unknown-elf-objdump -s -j .data linked.elf

echo "---extract raw instructions --- "
riscv64-unknown-elf-objcopy -O binary linked.elf final.bin  # to binary
hexdump -v -e '1/4 "%08x" "\n"' final.bin | perl -ne 'print unpack("B32", pack("N", hex($_))) . "\n"' > bin.txt 

#riscv64-unknown-elf-objdump -b binary -m riscv -D final.bin




