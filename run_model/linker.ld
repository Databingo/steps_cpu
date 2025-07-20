/* linker.ld */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  /* QEMU 'virt' machine has RAM at 0x80000000 */
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS {
  .text : {
    *(.text.init)
    *(.text .text.*)
  } > RAM

  .rodata : {
    *(.rodata .rodata.*)
  } > RAM

  .data : {
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
  . += 4096 * 4; /* 16 KB stack */
  __stack_top = .;
}
