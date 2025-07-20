/* linker.ld - Improved version */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  /* QEMU 'virt' machine has RAM at 0x80000000 */
  /* We define separate regions for code (RX) and data (RW) */
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS {
  . = ORIGIN(RAM);

  .text : {
    *(.text.init)
    *(.text .text.*)
  } > RAM

  .rodata : {
    . = ALIGN(8);
    *(.rodata .rodata.*)
  } > RAM
  
  .data : {
    . = ALIGN(8);
    *(.data .data.*)
  } > RAM

  .bss : {
    . = ALIGN(8);
    __bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  . = ALIGN(8);
  __stack_bottom = .;
  . += 4096 * 16; /* 64 KB stack */
  __stack_top = .;
}
