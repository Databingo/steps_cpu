-- MIF file generated from assembly
-- Prints "HELLO" to the JTAG UART

WIDTH=32;
DEPTH=3000;

ADDRESS_RADIX=HEX;
DATA_RADIX=HEX;

CONTENT BEGIN
[00..767] : 00000013; -- Fill with NOPs

00 : 80000537; -- lui a0, 0x80000
01 : 04800593; -- addi a1, zero, 72 ('H')
02 : 00b50023; -- sb a1, 0(a0)
03 : 04500593; -- addi a1, zero, 69 ('E')
04 : 00b50023; -- sb a1, 0(a0)
05 : 04c00593; -- addi a1, zero, 76 ('L')
06 : 00b50023; -- sb a1, 0(a0)
07 : 00b50023; -- sb a1, 0(a0)
08 : 04f00593; -- addi a1, zero, 79 ('O')
09 : 00b50023; -- sb a1, 0(a0)
0A : 00a00593; -- addi a1, zero, 10 ('\n')
0B : 00b50023; -- sb a1, 0(a0)
0C : 0000006f; -- j 0C
END;
