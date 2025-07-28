#python3 export.py stories15M_q80.bin --checkpoint stories15M.pt --version 2
#xxd -i stories15M_q80.bin > model_q80.h 
#qemu-system-riscv64 -machine help
#smaller llama2 LLM:SparseLlama-2-7b-pruned_50.2of4 
#
#bash buildq.sh
#bash qemuq.sh
#
##riscv64-unknown-elf-objdump -D \
#  -b binary \
#  -m riscv:rv64 \
#  --adjust-vma=0x80000000 \
#  -M no-aliases \
#  llama2.c/kernel_f.bin
bash buildf.sh
bash qemuf.sh
