# s1
#iverilog -g2012 -o s1 1_read_program.v 1tb.v &&
#vvp s1 

# s2
#iverilog -g2012 -o s2 2_load_program.v 2tb.v &&
#vvp s2 

# s3
#iverilog -g2012 -o s3 3_decode_instruction.v 3tb.v &&
#vvp s3 |less

# s4.1
#iverilog -g2012 -o s4 4_execute_instruction_1_jump.v 4tb.v &&
#vvp s4 |less

echo "" > binary_instructions.txt
#go run rvasm64I.go test.s &&
#go run rvasm64I.go li.s &&
#go run rvasm64I.go lui.s &&
#go run rvasm64I.go lb_lbu.s &&
#go run rvasm64I.go lh_lhu.s &&
go run rvasm64I.go lw_lwu.s &&
# s4.2
#iverilog -g2012 -o s4 4_execute_instruction_2_64I.v 4tb.v &&
#iverilog -g2012 -o s4 4_mini.v 4tb.v &&
iverilog -g2012 -o s4 4_execute_instruction_3_onecircle_64I.v 4tb.v &&
vvp s4 |less



#----
#gtkwave 2.vcd
