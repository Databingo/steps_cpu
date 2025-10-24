`include "header.vh"

module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // red LED
    (* chip_pin = "R20" *) output wire LEDR0,
    (* chip_pin = "R19" *) output wire LEDR1,
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19" *) output wire [5:0] LEDR_PC,

    (* chip_pin = "F4" *)  output wire HEX30,
    (* chip_pin = "G5" *)  output wire HEX20,
    (* chip_pin = "G6" *)  output wire HEX21,
    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "H6" *)  output wire HEX11,
    (* chip_pin = "J2" *)  output wire HEX00,
    (* chip_pin = "J1" *)  output wire HEX01,
    (* chip_pin = "H2" *)  output wire HEX02,
    (* chip_pin = "H1" *)  output wire HEX03,

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT,

    // ==== GPT FIX START ====
    // Corrected SD pin directions to proper bidirectional setup
    (* chip_pin = "V20" *)  output wire SD_CLK,  // SPI Clock
    (* chip_pin = "Y20" *)  inout  wire SD_CMD,  // MOSI / CMD (bidirectional)
    (* chip_pin = "W20" *)  inout  wire SD_DAT0, // MISO / DAT0 (bidirectional)
    (* chip_pin = "U20" *)  output wire SD_DAT3  // CS
    // ==== GPT FIX END ====
);

    // =======================================================
    // -- MEM --
    // =======================================================
    //(* ram_style = "block" *) reg [31:0] Cache [0:3071];
    (* ram_style = "M4K" *) reg [31:0] Cache [0:2047];
    initial begin
        $readmemb("rom.mif", Cache, `Rom_base>>2);
        $readmemb("ram.mif", Cache, `Ram_base>>2);
    end

    // =======================================================
    // Clock & CPU
    // =======================================================
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    wire [63:0] pc;
    reg [31:0] ir_bd;
    always @(posedge CLOCK_50) begin
        ir_bd <= Cache[pc>>2];
    end
    wire [31:0] ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]};
    assign LEDR_PC = pc/4;

    riscv64 cpu (
        .clk(clock_1hz),
        .reset(KEY0),
        .instruction(ir_ld),
        .pc(pc),
        .ir(LEDG),
        .heartbeat(LEDR9),

        .interrupt_vector(interrupt_vector),
        .interrupt_ack(interrupt_ack),

        .bus_address(bus_address),
        .bus_write_data(bus_write_data),
        .bus_write_enable(bus_write_enable),
        .bus_read_enable(bus_read_enable),

        .bus_read_done(bus_read_done),
        .bus_read_data(bus_read_data)
    );

    // =======================================================
    // Keyboard
    // =======================================================
    reg [7:0] ascii;
    reg [7:0] scan;
    reg key_pressed_delay;
    wire key_pressed, key_released;

    ps2_decoder ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .scan_code(scan),
        .ascii_code(ascii),
        .key_pressed(key_pressed),
        .key_released(key_released)
    );

    always @(posedge CLOCK_50)
        key_pressed_delay <= key_pressed;
    wire key_pressed_edge = key_pressed && !key_pressed_delay;

    // =======================================================
    // UART (JTAG)
    // =======================================================
    jtag_uart_system my_jtag_system (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // =======================================================
    // BUS
    // =======================================================
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    reg         bus_read_done;

    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    wire Key_selected = (bus_address == `Key_base);
    wire Art_selected = (bus_address == `Art_base);
    wire Sdc_selected = (bus_address >= `Sdc_base && bus_address <= `Sdc_dirty);
    wire Sdc_addr_selected  = (bus_address == `Sdc_addr);
    wire Sdc_read_selected  = (bus_address == `Sdc_read);
    wire Sdc_write_selected = (bus_address == `Sdc_write);
    wire Sdc_ready_selected = (bus_address == `Sdc_ready);
    wire Sdc_cache_selected = (bus_address >= `Sdc_base && bus_address < (`Sdc_base + 512));

    // =======================================================
    // SD Memory interface
    // =======================================================
    wire [31:0] spo;
    reg [15:0] mem_a = 16'h3220;
    reg [31:0] mem_d = 0;
    reg mem_we = 0;
    wire sd_ncd = 1'b0;
    wire sd_wp  = 1'b0;
    wire irq;
    // ==== GPT FIX START ====
    // Proper bidirectional internal nets for SD_CMD and SD_DAT0
    wire sd_cmd_i  = SD_CMD;
    wire sd_dat0_i = SD_DAT0;
    wire sd_dat1   = 1'b1;
    wire sd_dat2   = 1'b1;
    // internal drive control (optional if sdcard module handles inout directly)
    // ==== GPT FIX END ====

    // =======================================================
    // sdcard module instantiation (unchanged interface)
    // =======================================================
    sdcard sd0 (
        .clk     (CLOCK_50),
        .rst     (~KEY0),
        .sd_dat0 (SD_DAT0), // MISO
        .sd_ncd  (sd_ncd),
        .sd_wp   (sd_wp),
        .sd_dat1 (sd_dat1),
        .sd_dat2 (sd_dat2),
        .sd_dat3 (SD_DAT3), // CS
        .sd_cmd  (SD_CMD),  // MOSI (inout)
        .sd_sck  (SD_CLK),  // SPI Clock

        // memory-mapped control
        .a   (mem_a),
        .d   (mem_d),
        .we  (mem_we),
        .spo (spo)
    );

    // =======================================================
    // BUS Access Logic
    // =======================================================
    reg [63:0] bus_address_reg;
    reg [2:0]  sd_read_step = 0;

    always @(posedge CLOCK_50) begin
        mem_we <= 0;
        bus_address_reg <= bus_address >> 2;
        bus_read_done <= 0;

        if (bus_write_enable) begin
            if (Ram_selected)
                Cache[bus_address[63:2]] <= bus_write_data[31:0];
            if (Sdc_addr_selected)  begin mem_a <= `Sdc_addr;  mem_d <= bus_write_data[31:0]; mem_we <= 1; end
            if (Sdc_read_selected)  begin mem_a <= `Sdc_read;  mem_d <= 1; mem_we <= 1; end
            if (Sdc_write_selected) begin mem_a <= `Sdc_write; mem_d <= 1; mem_we <= 1; end
        end

        if (bus_read_enable) begin
            if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
            if (Ram_selected) begin bus_read_data <= {32'd0, Cache[bus_address_reg]}; bus_read_done <= 1; end
            if (Sdc_ready_selected) begin
                case (sd_read_step)
                    0: begin mem_a <= `Sdc_ready; sd_read_step <= 1; end
                    1: begin bus_read_data <= {32'd0, spo}; sd_read_step <= 0; bus_read_done <= 1; end
                endcase
            end
            if (Sdc_cache_selected) begin
                case (sd_read_step)
                    0: begin mem_a <= bus_address; sd_read_step <= 1; end
                    1: begin bus_read_data <= {32'd0, spo}; sd_read_step <= 0; bus_read_done <= 1; end
                endcase
            end
        end
    end

    // =======================================================
    // UART Trigger
    // =======================================================
    wire uart_write_trigger = bus_write_enable && Art_selected;
    reg uart_write_trigger_dly;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) uart_write_trigger_dly <= 0;
        else       uart_write_trigger_dly <= uart_write_trigger;
    end
    assign uart_write_trigger_pulse = uart_write_trigger && !uart_write_trigger_dly;

    // =======================================================
    // Interrupt controller
    // =======================================================
    reg [3:0] interrupt_vector;
    wire interrupt_ack;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            interrupt_vector <= 0;
            LEDR0 <= 0;
        end else begin
            if (key_pressed && ascii) begin
                interrupt_vector <= 1;
                LEDR0 <= 1;
            end
            if (interrupt_vector != 0 && interrupt_ack == 1) begin
                interrupt_vector <= 0;
                LEDR0 <= 0;
            end
        end
    end

    // =======================================================
    // Debug LEDs
    // =======================================================
    assign HEX30 = ~Key_selected;
    assign HEX20 = ~|bus_read_data;
    assign HEX21 = ~bus_read_enable;
    assign HEX10 = ~|bus_write_data;
    assign HEX11 = ~bus_write_enable;
    assign HEX00 = ~Art_selected;
    assign HEX01 = ~Ram_selected;
    assign HEX02 = ~Rom_selected;
    assign HEX03 = ~Sdc_selected;

endmodule
