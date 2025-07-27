#python3 export.py stories15M_q80.bin --checkpoint stories15M.pt --version 2
#xxd -i stories15M_q80.bin > model_q80.h 
#qemu-system-riscv64 -machine help
#smaller llama2 LLM:SparseLlama-2-7b-pruned_50.2of4 
#
bash buildq.sh
bash qemuq.sh
#
#bash build.sh
#bash qemu.sh
#
#bash buildf.sh
#bash qemuf.sh
