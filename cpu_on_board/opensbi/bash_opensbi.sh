#dtc -I dts -O dtb -o my_board.dtb my_board.dts # boot time use at register a1, hardid(core number) in a0

make CROSS_COMPILE=/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf- \
     PLATFORM=generic \
     FW_TEXT_START=0x80000000 \
     FW_PIC=n \
     PLATFORM_RISCV_ISA=rv64ima_zicsr_zifencei \
     PLATFORM_RISCV_ABI=lp64 \
     FW_PAYLOAD=y \
     FW_PAYLOAD_OFFSET=0x200000 \
    #FW_PAYLOAD_PATH= add.o \
    #FW_PAYLOAD_ALIGN=0x1000

#make CROSS_COMPILE=/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf- \
#     PLATFORM=custom/my_board \
#     FW_TEXT_START=0x80000000 \
#     FW_PIC=n \
#     PLATFORM_RISCV_ISA=rv64ima_zicsr_zifencei \
#     PLATFORM_RISCV_ABI=lp64 \
#     FW_PAYLOAD=y \
#     FW_PAYLOAD_PATH= add.o \
#     FW_PAYLOAD_ALIGN=0x1000


# use opensbi v13.0 for disable FW_PIC
# align 4KB
