addi x1, x0, 1
addi x2, x0, 8
add  x6, x2, x0 # 被加数
add  x5, x2, x0 # 加数
loop: @
sub  x3, x2, x1 # loop 1
sub  x4, x2, x1 # loop 2
loop2: @
add  x6, x6, x5 
sub  x4, x4, x1
blt  x0, x4, @loop2
add  x6, x6, x0 # 被加数
add  x5, x6, x0 # 加数
beq  x0, x4, @loop
add  x1, x6, x0 



