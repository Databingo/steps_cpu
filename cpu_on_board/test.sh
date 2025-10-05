go run ../rvas.go isr.s
cat bin.txt > rom.mif  # write ROM program



#go run ../rvas.go addi_sb.s  # sb just for UART need full test future
#go run ../rvas.go lb.s # addi sb lb uart for test
#go run ../rvas.go srli.s # addi -2 srli sb
#go run ../rvas.go lui.s # addi srli sb uart for test
#
#
#
go run ../rvas.go sw.s   # lui addi sw lb sb uart for test
#go run ../rvas.go lw.s  # sw lw for test
#go run ../rvas.go addi_sw.s  # pass
#
#
#
#

#go run ../rvas.go beq.s
#go run ../rvas.go add.s
#go run ../rvas.go slli.s
#go run ../rvas.go li32.s
#go run ../rvas.go li.s  #
#go run ../rvas.go jalr.s
#go run ../rvas.go jal.s
#go run ../rvas.go j_jr_ret.s  #
#go run ../rvas.go auipc.s
#go run ../rvas.go call.s #
#
#go run ../rvas.go load.s #
#go run ../rvas.go sd_ld.s
#go run ../rvas.go sd.s
#go run ../rvas.go jal_ra.s
#go run ../rvas.go slt.s
#go run ../rvas.go stack.s
cat bin.txt > ram.mif  # write RAM program


