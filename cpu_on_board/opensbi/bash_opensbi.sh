make PLATFORM=generic clean

#dtc -I dts -O dtb -o my_board.dtb my_board.dts # boot time use via its address at register a1, hardid(core number) in a0
#dtc -I dts -O dtb -o my_board.dtb qemu_virt.dts # boot time use via its address at register a1, hardid(core number) in a0
dtc -I dts -O dtb -o my_board.dtb b.dts      # boot time use via its address at register a1, hardid(core number) in a0
#dtc -I dts -O dtb -o my_board.dtb b.dts.qemu # boot time use via its address at register a1, hardid(core number) in a0
rm -rf build/platform/generic/firmware/*  \
# for opensbi test in qemy/soc
#make CROSS_COMPILE=/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf- \
#     PLATFORM=generic \
#     FW_TEXT_START=0x80000000 \
#     FW_JUMP_ADDR=0x80200000 \
#     FW_JUMP_FDT_ADDR=0x80100000 \
#     FW_PIC=n \
#     PLATFORM_RISCV_ISA=rv64ima_zicsr_zifencei \
#     PLATFORM_RISCV_ABI=lp64 \
#     EXTRA_CCASFLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64"\
#     EXTRA_CFLAGS="-mno-relax -march=rv64ima_zicsr_zifencei -mabi=lp64"\
#     FW_FDT_PATH=my_board.dtb \
#     FW_COLDBOOT_HART=0 \
#     FW_HART_COUNT=1 \
#     FW_PAYLOAD=n 
#    #FW_PAYLOAD_OFFSET=0x200000 \
#    #FW_PAYLOAD_FDT_ADDR=0x80100000 \

# for buildroot-linux-busybox   linxu fore payload offset = 2M ?
#make O=build_soc \
make CROSS_COMPILE=/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf- \
     PLATFORM=generic \
     FW_PIC=n \
     PLATFORM_RISCV_ISA=rv64ima_zicsr_zifencei \
     PLATFORM_RISCV_ABI=lp64 \
     EXTRA_CCASFLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64" \
     EXTRA_CFLAGS="-mno-relax -march=rv64ima_zicsr_zifencei -mabi=lp64" \
     FW_COLDBOOT_HART=0 \
     FW_HART_COUNT=1 \
     FW_TEXT_START=0x80000000 \
     FW_FDT_PATH=my_board.dtb \
     FW_JUMP_FDT_ADDR=0x80100000 \
     FW_PAYLOAD=n \
     FW_JUMP_ADDR=0x80200000 \
    #SBI_EXT_TIME=n\
    #FW_PAYLOAD_OFFSET=0x200000 \
    #FW_PAYLOAD_PATH=/usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image \
    #FW_PAYLOAD_ALIGN=0x1000 \
    #FW_PAYLOAD=y \
    #FW_PAYLOAD_PATH=/usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image \
    #FW_PAYLOAD_OFFSET=0x100000 \
    #FW_JUMP_ADDR=0x80100000 \
    #FW_PAYLOAD_ALIGN=0x1000 \
    #FW_OPTIONS=0x1 \














# Opensbi start from 0x80000000, DeviceTree at 0x80100000, Program at 0x80200000, Ram end at 0x80800000

    #EXTRA_CFLAGS="-mno-relax"\
    #CFLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64"\
    #ASFLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64"\


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


# use opensbi v13.0 for disable fw_pic
# align 4KB
#
#
#../../../bin/riscv64-unknown-elf-objdump -D -b binary -m riscv:rv64ima build/platform/generic/firmware/fw_payload.bin|less

#hexdump -C build/platform/generic/firmware/fw_jump.bin > ../fw_jump.bin.txt
cp build/platform/generic/firmware/fw_jump.bin ../fw_jump_ns16550a.bin
#cp my_board.dtb ../my_board.dtb
