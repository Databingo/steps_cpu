#python3 export.py stories15M_q80.bin --checkpoint stories15M.pt --version 2
#xxd -i stories15M_q80.bin > model_q80.h 
bash buildq.sh
bash qemuq.sh
