# s1
#iverilog -g2012 -o s1 1_read_program.v  1tb.v &&
#vvp s1 
#
#exit

# s2
iverilog -g2012 -o s2 2_load_program.v  2tb.v &&
vvp s2 









#gtkwave 2.vcd
