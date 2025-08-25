module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR7_0, // 8 red LEDs right

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT 
);

    // -- ROM --
    (* ram_style = "block" *) reg [31:0] Rom [0:1023]; // 4KB ROM
    initial $readmemb("rom.mif", Rom);

    // -- RAM --
    (* ram_style = "block" *) reg [31:0] Ram [0:2999]; // Unified Memory
    initial $readmemb("ram.mif", Ram);

    wire [31:0] pc;
    wire [31:0] ir_bd; assign ir_bd = Ram[pc>>2];
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap

    // -- CPU --
    riscv64 cpu (
        .clk(clock_1hz), 
        .reset(KEY0),     // Active-low reset button
        .instruction(ir_ld),
        .pc(pc),
        .ir(LEDG),
        //.re(re),
        .heartbeat(LEDR9),

        .bus_address(bus_address),
        .bus_write_data(bus_write_data),
        .bus_write_enable(bus_write_enable),
        .bus_read_enable(bus_read_enable),
        .bus_read_data(bus_read_data)
    );
     
    // -- Bus --
    wire [63:0] bus_address;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    wire        bus_read_enable;
    wire [63:0] bus_read_data;

    // -- Clock --
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

   // -- Keyboard -- 
   reg [31:0] data;
   wire key_pressed;
   wire key_released;
   reg key_pressed_delay;
   always @(posedge CLOCK_50) begin key_pressed_delay <= key_pressed; end
   ps2_decoder ps2_decoder_inst (
       .clk(CLOCK_50),
       .ps2_clk_async(PS2_CLK),
       .ps2_data_async(PS2_DAT),
       //.scan_code(data[7:0])
       .ascii_code(data[7:0]),
       .key_pressed(key_pressed),
       .key_released(key_released)
   );

   // -- Monitor --
    wire [0:0]  avalon_address;
    wire        avalon_write;
    wire [31:0] avalon_writedata;

    jtag_uart_system my_jtag_system (
        .clk_clk                             (CLOCK_50),
        .reset_reset_n                       (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (avalon_address),
        .jtag_uart_0_avalon_jtag_slave_writedata (avalon_writedata),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~avalon_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

   // -- Bus --
   wire key_pressed_edge = key_pressed && !key_pressed_delay;
   assign avalon_write     = key_pressed_edge; // Force the write signal high every cycle
   assign avalon_address   = 1'b0;            // Always write to the data register (address 0)
   assign avalon_writedata = {24'b0, data};    

endmodule



// Cyclone II FPGA Starter Board EP2C20F484C7 
// Onchip M4K 239616~=29.95 KB
