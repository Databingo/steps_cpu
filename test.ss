addi x1, x0, 1
addi x2, x0, 8
add  x6, x2, x0 # 被加数
add  x5, x2, x0 # 加数
sub  x3, x2, x1
sub  x4, x3, x0
loop1: @
sub  x4, x3, x1 # loop 2
loop2: @
add  x6, x6, x5 
sub  x4, x4, x1
blt  x1, x4, @loop2
add  x6, x6, x0 # 被加数
add  x5, x6, x0 # 加数
sub  x3, x3, x1 # loop 1
beq  x1, x3, @end
blt  x1, x3, @loop1
end: @
add  x1, x6, x0 



