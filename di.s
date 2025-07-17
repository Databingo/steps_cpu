.global main
.global msg

.section .data
msg:
    .string "Hello from assembly main!\n"

.section   .text
main:
    la      a0, msg      # argument: pointer to string
    call    puts         # call libc's puts
    li      a0, 0        # return 0
    ret
