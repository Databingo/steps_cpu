#iverilog -g2012 -o steps_cpu 2_load_program.v &&
iverilog -g2012 -o s2 2_load_program.v  2tb.v &&

vvp s2 

#echo "finish" | vvp 

#finish &&
#gtkwave 2.vcd
