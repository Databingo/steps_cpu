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
#go run rvas.go test.s &&
#go run rvas.go li.s &&
#go run rvas.go lui.s &&
#go run rvas.go lb_lbu.s &&
#go run rvas.go lh_lhu.s &&
#go run rvas.go lw_lwu.s &&
go run rvas.go ld.s &&
#go run rvas.go s.s &&
#go run rvas.go add_sub.s &&
#go run rvas.go slt_u.s &&
#go run rvas.go slti_u.s &&
#go run rvas.go gate.s &&
#go run rvas.go gate_i.s &&
#go run rvas.go sh.s &&
#go run rvas.go sh_i.s &&
#go run rvas.go b.s &&
# go run rvas.go auipc.s &&
#go run rvas.go j.s &&
#
#go run rvas.go jr.s && #>> binary_instructions.txt
# s4.2
#iverilog -g2012 -o s4 4_execute_instruction_2_64I.v 4tb.v &&
#iverilog -g2012 -o s4 4_mini.v 4tb.v &&
#iverilog -g2012 -o s4 4_execute_instruction_3_onecircle_64I.v 4tb.v &&
iverilog -g2012 -o s4  4_x5_burn_to_FPGA_from_easy.v 4tb.v &&
vvp s4 |less



#----
#gtkwave 2.vcd
