SECTIONS
{
  . = 0x80000000; /* QEMU default memory layouts */
  .text : { *(.text) }
  .data : { *(.data) }
  .bss  : { *(.bss) }
}
