bash test.sh
file relocatable.elf
riscv64-unknown-elf-objdump  -d  relocatable.elf 
riscv64-unknown-elf-objdump  -r  relocatable.elf 



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
exit


riscv64-unknown-elf-objcopy -O binary final.elf final.bin  # to binary
#riscv64-unknown-elf-readelf -S final.elf
riscv64-unknown-elf-objdump -b binary -m riscv -D final.bin
riscv64-unknown-elf-objdump -s -j .data final.elf


hexdump -v -e '1/4 "%08x" "\n"' final.bin | perl -ne 'print unpack("B32", pack("N", hex($_))) . "\n"' > bin.txt

