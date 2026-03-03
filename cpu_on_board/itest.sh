iverilog -DTEST -o itest.out $1 && vvp itest.out && rm itest.out
