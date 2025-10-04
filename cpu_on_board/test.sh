go run ../rvas.go isr.s
cat bin.txt > rom.mif  # write ROM program


#go run ../rvas.go addi_sw.s 

go run ../rvas.go lw.s 
#go run ../rvas.go sw.s #
#go run ../rvas.go lui.s
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
#go run ../rvas.go lb.s #
#
#go run ../rvas.go sb.s #
#go run ../rvas.go load.s #
#go run ../rvas.go sd_ld.s
#go run ../rvas.go sd.s
#go run ../rvas.go jal_ra.s
#go run ../rvas.go slt.s
#go run ../rvas.go stack.s
cat bin.txt > ram.mif  # write RAM program


