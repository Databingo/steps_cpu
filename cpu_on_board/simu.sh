iverilog -g2012 -o soc  cpu_on_board.v riscv64.v ps2_decoder.v clock_slower.v jtag_uart_system/synthesis/jtag_uart_system.v jtag_uart_system/synthesis/submodules/altera_reset_controller.v jtag_uart_system/synthesis/submodules/altera_reset_synchronizer.v jtag_uart_system/synthesis/submodules/jtag_uart_system_jtag_uart_0.v &&
#jtag_uart_system/synthesis/jtag_uart_system.v
#altera_reset_synchronizer.v     jtag_uart_system_jtag_uart_0.v 
vvp soc |less
