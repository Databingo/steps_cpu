go run ../rvas.go isr.s
cat bin.txt > rom.mif  # write ROM program


#go run ../rvas.go test.s
go run ../rvas.go addi.s
cat bin.txt > ram.mif  # write RAM program


