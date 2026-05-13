#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

int main() {
    // 0. Setup environment
    mkdir("/dev", 0755);
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);

    long result = 0;
    long scratch = 0;

    // --- TEST 1: ALU I-Type ---
    asm volatile ("li t0, 10; addi t0, t0, -5; xori t0, t0, 1; addi %0, t0, 0" : "=r"(result) : : "t0");
    if (result != 4) return 101; 

    // --- TEST 2: RV64W (Word instructions) ---
    asm volatile ("li t0, 0x7FFFFFFF; addiw %0, t0, 1" : "=r"(result) : : "t0");
    if (result != (long)0xFFFFFFFF80000000) return 102;

    // --- TEST 3: Multiplication ---
    asm volatile ("li t0, 12; li t1, 9; mul %0, t0, t1" : "=r"(result) : : "t0", "t1");
    if (result != 108) return 103;

    // --- TEST 4: Division ---
    asm volatile ("li t0, 100; li t1, 3; div %0, t0, t1" : "=r"(result) : : "t0", "t1");
    if (result != 33) return 104;

    // --- TEST 5: Atomic LR/SC (Single attempt) ---
    scratch = 55;
    asm volatile ("lr.d t1, (%1); addi t1, t1, 5; sc.d t2, t1, (%1); mv %0, t1" 
                  : "=r"(result) : "r"(&scratch) : "t1", "t2", "memory");
    if (result != 60 || scratch != 60) return 105;

    // --- TEST 6: Atomic AMOADD ---
    scratch = 100;
    asm volatile ("li t0, 50; amoadd.d %0, t0, (%1)" : "=r"(result) : "r"(&scratch) : "t0");
    if (result != 100 || scratch != 150) return 106;

    // --- TEST 7: Branch & Jump ---
    asm volatile ("li t0, 1; li t1, 2; blt t0, t1, 1f; li %0, 0; j 2f; 1: li %0, 77; 2:" : "=r"(result) : : "t0", "t1");
    if (result != 77) return 107;

    // --- TEST 8: JALR (FIXED COLON SYNTAX) ---
    asm volatile ("la t0, 1f; jalr ra, t0, 0; li %0, 0; j 2f; 1: li %0, 88; 2:" : "=r"(result) : : "t0", "ra");
    if (result != 88) return 108;

    // --- TEST 9: Shift Logic ---
    asm volatile ("li t0, 0xFF; slli t0, t0, 8; srli %0, t0, 4" : "=r"(result) : : "t0");
    if (result != 0xFF0) return 109;

    // --- TEST 10: Little-Endian Memory Widths ---
    scratch = 0;
    asm volatile (
        "li t0, 0x12\n"
        "sb t0, 0(%1)\n"
        "li t0, 0x3456\n"
        "sh t0, 2(%1)\n"
        "li t0, 0x789ABCDE\n"
        "sw t0, 4(%1)\n"
        "ld %0, 0(%1)"
        : "=r"(result) : "r"(&scratch) : "t0", "memory"
    );
    if (result != 0x789ABCDE34560012) return 110;

    // --- TEST 11: Sign Extension ---
    scratch = 0xFFFFFFFFFFFFFF80; 
    asm volatile ("lb %0, 0(%1)" : "=r"(result) : "r"(&scratch));
    if (result != -128) return 111;

    return 123; 
}
