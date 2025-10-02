go run ../rvas.go isr.s
cat bin.txt > rom.mif  # write ROM program


#go run ../rvas.go addi_sd.s
#go run ../rvas.go ld.s
#go run ../rvas.go lui.s
#go run ../rvas.go li32.s
#go run ../rvas.go beq.s
#go run ../rvas.go add.s
go run ../rvas.go slli.s
#go run ../rvas.go sd_ld.s
#go run ../rvas.go test.s
#go run ../rvas.go stack.s
#go run ../rvas.go sd.s
#go run ../rvas.go addi.s
#go run ../rvas.go jal.s
#go run ../rvas.go jal_ra.s
#go run ../rvas.go jalr.s
#go run ../rvas.go call.s
#go run ../rvas.go beq.s
#go run ../rvas.go slt.s
cat bin.txt > ram.mif  # write RAM program


