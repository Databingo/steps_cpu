	.file	"c_nake_2_assembly.c"
	.option nopic
	.option norelax
	.attribute arch, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	_start
	.type	_start, @function
_start:
	li	a5,4096
	li	a4,100
	sw	a4,0(a5)
.L2:
	j	.L2
	.size	_start, .-_start
	.globl	OUTPUT_ADDR
	.section	.srodata,"a"
	.align	3
	.type	OUTPUT_ADDR, @object
	.size	OUTPUT_ADDR, 8
OUTPUT_ADDR:
	.dword	4096
	.ident	"GCC: (xPack GNU RISC-V Embedded GCC x86_64) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
