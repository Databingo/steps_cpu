addi x1, x0, 1
addi x2, x0, 8
add  x6, x0, x0 # 0
add  x5, x2, x0 # 加数
add  x3, x2, x0 # 8
add  x4, x3, x0 # 8
loop1: sub  x3, x3, x1 # loop 1
sub  x4, x3, x0 # loop 2
loop2: 
sub  x4, x4, x1
add  x6, x6, x5 
blt  x0, x4, loop2
add  x5, x6, x0 # 加数
add  x2, x6, x0 # 结果
add  x6, x0, x0 # 0
blt  x1, x3, loop1



