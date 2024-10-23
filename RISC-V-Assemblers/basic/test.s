Main: @000
addi x1, x0, 1
addi x2, x0, 8
addi x3, x2, 1 # yi jie 
add  x4, x3, x0 # er jie 
loop: @
add  x5, x2, x2
addi x4, x4, -1
blt  x4, x3, @loop

