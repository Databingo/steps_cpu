go run ../rvas.go isr.s
cat bin.txt > rom.mif  # write ROM program


#go run ../rvas.go addi_sb.s  # sb just for UART need full test future
#go run ../rvas.go lb.s       # addi sb lb uart for test (sb tested too)
#go run ../rvas.go srli.s     # addi -2 srli sb
#go run ../rvas.go lui.s      # addi srli sb uart for test
#go run ../rvas.go sw.s       # lui addi sw lb sb uart for test
#go run ../rvas.go lw.s       # lui addi sw lw sb uart for test
#go run ../rvas.go sh.s       # lui addi sh lw sb uart for test
#go run ../rvas.go lh.s       # lui addi sw lh sb uart for test
#go run ../rvas.go slli.s     # lui addi slli sb uart
#go run ../rvas.go sd.s       # lui addi slli addi sd lw sb uart for test
#go run ../rvas.go ld.s       # lui addi slli addi sd ld sb uart for test
#go run ../rvas.go lbu.s      # addi -1 sb lb sb uart #include lbu lhu lwu     
#----tested again---
#go run ../rvas.go beq.s ok
#go run ../rvas.go add.s ok
#go run ../rvas.go li32.s
#go run ../rvas.go li.s  # ok
#go run ../rvas.go jalr.s
#go run ../rvas.go jal.s
#go run ../rvas.go j_jr_ret.s  #
#go run ../rvas.go auipc.s
#go run ../rvas.go call.s # ok
go run ../rvas.go ori.s # ok


 
#go run ../rvas.go load.s #
#go run ../rvas.go sd_ld.s
#go run ../rvas.go sd.s
#go run ../rvas.go jal_ra.s
#go run ../rvas.go slt.s
#go run ../rvas.go stack.s
#
#
#
#go run ../rvas.go sw_unalign_support.s 
#go run ../rvas.go lw_unalign_support.s
#
#
#
cat bin.txt > ram.mif  # write RAM program


