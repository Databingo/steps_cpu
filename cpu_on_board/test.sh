go run ../rvas.go test.s
cat bin.txt > ram.mif  # write RAM program


go run ../rvas.go isr.s
cat bin.txt > rom.mif  # write ROM program
