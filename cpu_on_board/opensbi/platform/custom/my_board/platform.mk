# Custom board for your CPU (2026 minimal OpenSBI)

# Core config
PLATFORM_RISCV_XLEN  = 64
PLATFORM_RISCV_ISA   = rv64ima_zicsr_zifencei
PLATFORM_RISCV_ABI   = lp64

# Firmware base
FW_TEXT_START        = 0x80000000
FW_PIC               = n

# Payload 配置（关键！）
FW_PAYLOAD           = n
#FW_PAYLOAD_ALIGN     = 0x1000

# 如果你已经有 Linux Image，就加上这一行（推荐）
# FW_PAYLOAD_PATH      = /path/to/linux/arch/riscv/boot/Image
# FW_PAYLOAD_FDT_PATH  = /path/to/your_board.dtb   # 可选
