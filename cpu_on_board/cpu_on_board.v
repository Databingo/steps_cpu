//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
//);
//
//// =======================================================
//// Heartbeat LED
//// =======================================================
//reg [23:0] blink_counter;
//assign LEDR0 = blink_counter[23];
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//end
//
//// =======================================================
//// JTAG UART
//// =======================================================
//reg [31:0] uart_data;
//reg        uart_write;
//
//jtag_uart_system uart0 (
//    .clk_clk(CLOCK_50),
//    .reset_reset_n(KEY0),
//    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//);
//
//// =======================================================
//// SD SPI lines
//// =======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//reg [15:0] clk_div;
//reg sd_clk_reg;
//
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//assign SD_CLK = sd_clk_reg;
//assign SD_DAT3 = 1'b1;  // CS high (not used)
//assign SD_DAT0 = 1'bz;   // read only for now
//
//// Slow clock for SD (~100 kHz)
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        clk_div <= 0;
//        sd_clk_reg <= 0;
//    end else begin
//        clk_div <= clk_div + 1;
//        if (clk_div == 250) begin   // 50MHz / 250 / 2 = 100 kHz
//            sd_clk_reg <= ~sd_clk_reg;
//            clk_div <= 0;
//        end
//    end
//end
//
//// =======================================================
//// SD CMD0 sequence
//// =======================================================
//reg [7:0]  init_cnt;
//reg [5:0]  bit_cnt;
//reg [47:0] cmd_shift;
//reg        cmd_start;
//reg [7:0]  response;
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        init_cnt <= 0;
//        bit_cnt <= 0;
//        cmd_start <= 0;
//        sd_cmd_oe <= 0;
//        sd_cmd_out <= 1;
//        cmd_shift <= 48'h40_00_00_00_00_95; // CMD0 with CRC
//        uart_write <= 0;
//        uart_data <= 0;
//    end else begin
//        uart_write <= 0;
//
//        // 80 clocks with CMD high before CMD0
//        if (init_cnt < 80) begin
//            sd_cmd_oe <= 1;
//            sd_cmd_out <= 1;
//            init_cnt <= init_cnt + 1;
//        end
//        // Send CMD0
//        else if (init_cnt < 80+48) begin
//            sd_cmd_oe <= 1;
//            sd_cmd_out <= cmd_shift[47];
//            cmd_shift <= {cmd_shift[46:0],1'b1};
//            bit_cnt <= bit_cnt + 1;
//            init_cnt <= init_cnt + 1;
//        end
//        // Release CMD line
//        else if (init_cnt == 80+48) begin
//            sd_cmd_oe <= 0;
//            init_cnt <= init_cnt + 1;
//        end
//        // Read response (simplified: just read DAT0 after 8 clocks)
//        else if (init_cnt > 80+48 && init_cnt < 80+48+16) begin
//            // This is just a placeholder; real SPI read requires proper sampling
//            // Here we assume card responds and just print success
//            if (init_cnt == 80+48+15) begin
//                uart_data <= {24'd0, "C"}; // CMD0 OK
//                uart_write <= 1;
//            end
//            init_cnt <= init_cnt + 1;
//        end
//    end
//end
//
//endmodule



//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
//);
//
//// =======================================================
//// Heartbeat LED
//// =======================================================
//reg [23:0] blink_counter;
//assign LEDR0 = blink_counter[23];
//reg cmd_start;
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//end
//
//// =======================================================
//// JTAG UART
//// =======================================================
//reg [31:0] uart_data;
//reg        uart_write;
//
//jtag_uart_system uart0 (
//    .clk_clk(CLOCK_50),
//    .reset_reset_n(KEY0),
//    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//);
//
//// =======================================================
//// SD SPI lines
//// =======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//reg [15:0] clk_div;
//reg sd_clk_reg;
//
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//assign SD_CLK = sd_clk_reg;
//assign SD_DAT3 = 1'b1;  // CS high
//assign SD_DAT0 = 1'bz;   // read-only
//
//// Slow SD clock ~100 kHz
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        clk_div <= 0;
//        sd_clk_reg <= 0;
//    end else begin
//        clk_div <= clk_div + 1;
//        if (clk_div == 250) begin
//            sd_clk_reg <= ~sd_clk_reg;
//            clk_div <= 0;
//        end
//    end
//end
//
//// =======================================================
//// SD command FSM
//// =======================================================
//reg [7:0]  init_cnt;
//reg [5:0]  bit_cnt;
//reg [47:0] cmd_shift;
//reg [4:0]  state;
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        init_cnt <= 0;
//        bit_cnt <= 0;
//        cmd_shift <= 48'h40_00_00_00_00_95; // CMD0 reset
//        cmd_start <= 0;
//        sd_cmd_oe <= 0;
//        sd_cmd_out <= 1;
//        uart_write <= 0;
//        uart_data <= 0;
//        state <= 0;
//    end else begin
//        uart_write <= 0;
//
//        case(state)
//            0: begin
//                // 80 clocks CMD high before CMD0
//                if (init_cnt < 80) begin
//                    sd_cmd_oe <= 1;
//                    sd_cmd_out <= 1;
//                    init_cnt <= init_cnt + 1;
//                end else begin
//                    state <= 1;
//                    init_cnt <= 0;
//                    bit_cnt <= 0;
//                    cmd_shift <= 48'h40_00_00_00_00_95; // CMD0
//                end
//            end
//
//            // Send CMD0
//            1: begin
//                sd_cmd_oe <= 1;
//                sd_cmd_out <= cmd_shift[47];
//                cmd_shift <= {cmd_shift[46:0],1'b1};
//                bit_cnt <= bit_cnt + 1;
//                if (bit_cnt == 47) begin
//                    sd_cmd_oe <= 0;  // release CMD line
//                    state <= 2;
//                    init_cnt <= 0;
//                end
//            end
//
//            // Wait some clocks, print "0"
//            2: begin
//                if (init_cnt == 15) begin
//                    uart_data <= {24'd0, "0"}; uart_write <= 1;
//                    state <= 3;
//                end else
//                    init_cnt <= init_cnt + 1;
//            end
//
//            // CMD55 (APP_CMD)
//            3: begin
//                cmd_shift <= 48'h77_00_00_00_00_65; // CMD55
//                bit_cnt <= 0;
//                state <= 4;
//            end
//
//            4: begin
//                sd_cmd_oe <= 1;
//                sd_cmd_out <= cmd_shift[47];
//                cmd_shift <= {cmd_shift[46:0],1'b1};
//                bit_cnt <= bit_cnt + 1;
//                if (bit_cnt == 47) begin
//                    sd_cmd_oe <= 0;
//                    state <= 5;
//                end
//            end
//
//            5: begin
//                uart_data <= {24'd0, "5"}; uart_write <= 1;
//                state <= 6;
//            end
//
//            // ACMD41
//            6: begin
//                cmd_shift <= 48'h69_40_00_00_00_00; // ACMD41 simplified
//                bit_cnt <= 0;
//                state <= 7;
//            end
//
//            7: begin
//                sd_cmd_oe <= 1;
//                sd_cmd_out <= cmd_shift[47];
//                cmd_shift <= {cmd_shift[46:0],1'b1};
//                bit_cnt <= bit_cnt + 1;
//                if (bit_cnt == 47) begin
//                    sd_cmd_oe <= 0;
//                    state <= 8;
//                end
//            end
//
//            8: begin
//                uart_data <= {24'd0, "A"}; uart_write <= 1;
//                state <= 9;
//            end
//
//            9: begin
//                uart_data <= {24'd0, "D"}; uart_write <= 1;
//                state <= 10;
//            end
//
//            10: state <= 10; // stop
//        endcase
//    end
//end
//
//endmodule

// Print K
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD (MOSI)
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0 (MISO)
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
//);
//
//    // =======================================================
//    // Heartbeat LED
//    // =======================================================
//    reg [23:0] blink_counter;
//    assign LEDR0 = blink_counter[23];
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0)
//            blink_counter <= 0;
//        else
//            blink_counter <= blink_counter + 1'b1;
//    end
//
//    // =======================================================
//    // JTAG UART
//    // =======================================================
//    reg [31:0] uart_data;
//    reg        uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    // =======================================================
//    // Slow pulse clock for SD init (~100 kHz)
//    // =======================================================
//    reg [8:0] clkdiv = 0;
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0)
//            clkdiv <= 0;
//        else
//            clkdiv <= clkdiv + 1;
//    end
//    wire clk_pulse_slow = (clkdiv == 0);
//
//    // =======================================================
//    // SD controller connection
//    // =======================================================
//    wire [7:0] sd_dout;
//    wire sd_ready;
//    wire [4:0] sd_status;
//    wire sd_cs, sd_mosi, sd_sclk;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//
//        .rd(1'b0),
//        .wr(1'b0),
//        .dout(sd_dout),
//        .byte_available(),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(32'h00000000),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(clk_pulse_slow),
//        .status(sd_status),
//        .recv_data()
//    );
//
//    // Connect physical pins
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // UART debug: print when SD is ready
//    // =======================================================
//    reg printed = 0;
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed <= 0;
//        end else begin
//            uart_write <= 0;
//            if (sd_ready && !printed) begin
//                uart_data  <= {24'd0, "K"};  // Print "K" when SD ready
//                uart_write <= 1;
//                printed <= 1;
//            end
//        end
//    end
//
//endmodule




module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,
    
    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD (MOSI)
    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0 (MISO)
    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS

);

// =======================================================
// Heartbeat LED
// =======================================================
reg [23:0] blink_counter;
assign LEDR0 = blink_counter[23];

always @(posedge CLOCK_50 or negedge KEY0) begin
    if (!KEY0)
        blink_counter <= 0;
    else
        blink_counter <= blink_counter + 1'b1;
end

// =======================================================
// JTAG UART
// =======================================================
reg [31:0] uart_data;
reg        uart_write;

jtag_uart_system uart0 (
    .clk_clk(CLOCK_50),
    .reset_reset_n(KEY0),
    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
);

// =======================================================
// Slow pulse clock for SD init (~100 kHz)
// The `sd_controller.v` documentation suggests it handles slow clock generation.
// However, if your controller needs an external `clk_pulse_slow` for its initial phase,
// this is how you'd generate it. The given `sd_controller.v` uses this.
// =======================================================
reg [4:0] clkcounter = 0; // From your `sd_controller.v` docs
always @ (posedge CLOCK_50 or negedge KEY0) begin
    if (!KEY0) clkcounter <= 5'b0;
    else clkcounter <= clkcounter + 1;
end
wire clk_pulse_slow = (clkcounter == 5'b0);

// =======================================================
// SD controller connection
// =======================================================
wire [7:0] sd_dout;
wire sd_ready; // This now means controller is ready, not card is ready after full init
wire [4:0] sd_status;
wire sd_byte_available;
wire sd_ready_for_next_byte;
wire [7:0] sd_recv_data; // This is the R1, R3, R7 bytes for command responses

// Internal signals for SD controller control
reg  sd_rd;
reg  sd_wr;
reg  [31:0] sd_address; // Full 32-bit argument
// The sd_controller.v seems to accept 32-bit address directly, not 8-bit `sd_din`
// Let's assume `sd_address` is `CMD_INDEX | (ARG << 8)` or similar,
// but typically, `sd_address` is the command index and `sd_din` (or another port) is the argument.
// Based on the code, `sd_address` is for the command index.
// I will assume `sd_address` is the command index, and the *controller* handles the argument.
// If your sd_controller uses `sd_din` for arguments, we'll need to adapt.
// For now, I'll pass the argument via a combination, assuming the controller unpacks it.
// If the controller has separate ports for CMD and ARG, that's preferred.
// Let's assume `sd_address` is `CMD_INDEX`, and `sd_din` is the *first byte* of a multi-byte argument.
// Since the prompt doesn't clarify `sd_din`'s full role, I'll try to use `sd_address` for CMD_INDEX
// and explicitly provide argument bytes in sequence if needed.
// Re-reading: "address(32'h00000000)" suggests a 32-bit argument for the SD command.
// Let's change `sd_address` to represent the *command argument*, and we'll need a separate command register.
// This is a common point of confusion with generic `sd_controller` IPs.

// Let's assume:
//  `sd_address` is the 32-bit ARGUMENT for the command
//  We need a separate `sd_command` input to the controller to specify the command index.
//  Since it's not present, I'll revert to the previous assumption that `sd_address` *itself* encodes the command+arg.
//  This is less flexible but common for simplified controllers.
//  The previous code had `sd_address <= 10;` which implies `sd_address` IS the command index.
//  And `sd_din <= 8'h00;` implies `sd_din` IS the argument. This is contradictory.
//  Let's stick to the previous interpretation, which is `sd_address` is command index, `sd_din` is argument.
//  BUT, SD commands have 32-bit arguments. Your `sd_din` is 8-bit.
//  This implies the controller expects a series of 8-bit writes to `sd_din` for the 32-bit argument,
//  OR `sd_din` is only used for data *writes*, and the 32-bit argument is automatically handled by the controller
//  for standard commands once `sd_address` (command index) is set.
//  Given "read/write 0x1000: get/set <address> for R/W", this suggests `sd_address` is a general address, not command.
//  The `sd_controller.v`'s `address` port is probably for block addresses for R/W.
//  So your `sd_controller` is more likely to have a separate port for `command_index` and `command_argument`.
//  **CRITICAL:** You need to check the exact port definition and usage of your `sd_controller.v`.
//  For now, I'm going to *add* a `sd_command_index` and use `sd_address` as the 32-bit argument.
//  If `sd_controller.v` does *not* have `sd_command_index` as an input, then this won't synthesize.
//  You'll need to know how to pass the *command number* (e.g., 8 for CMD8) to your specific `sd_controller.v`.

// Let's assume a hypothetical `sd_controller` that looks like this:
//  .cmd_index(sd_cmd_idx),       // input, for command number (0-63)
//  .cmd_arg(sd_cmd_arg),         // input, for 32-bit argument
//  .cmd_trigger(sd_wr),          // input, pulse to send command
//  .data_read_trigger(sd_rd),    // input, pulse to read next byte
//  .dout(sd_dout),               // output, data byte
//  .byte_available(sd_byte_available), // output, data ready
//  .response_byte(sd_recv_data)  // output, R1/R3/R7 response byte

// Since we only have `sd_address` and `sd_din` (which is often for data *writes*),
// I will revert to the interpretation where `sd_address` is the command index,
// and `sd_din` serves as the low 8 bits of the argument, and the controller expands it.
// This is not ideal for 32-bit arguments but might be what your `sd_controller.v` expects in a simplified form.
// Let's assume `sd_address` gets the command *number* and `sd_din` gets the *argument* for now.
// If this isn't correct, we'll need to know the `sd_controller.v`'s exact ports.
reg [7:0] sd_command_index; // Assuming a separate command index port if sd_address is for argument
reg [31:0] sd_command_argument; // For 32-bit arguments

sd_controller sd0 (
    .cs(sd_cs),
    .mosi(sd_mosi),
    .miso(SD_DAT0),
    .sclk(sd_sclk),

    .rd(sd_rd),
    .wr(sd_wr),
    .dout(sd_dout),
    .byte_available(sd_byte_available),
    .din(sd_command_argument[7:0]), // If `din` is for argument, use LSB here
    .ready_for_next_byte(sd_ready_for_next_byte),
    .reset(~KEY0),
    .ready(sd_ready),
    .address(sd_command_index), // Using `address` as command index for now (as in previous code)
    .clk(CLOCK_50),
    .clk_pulse_slow(clk_pulse_slow), // Use the externally generated slow clock
    .status(sd_status),
    .recv_data(sd_recv_data)
);
// The `sd_controller.v` documentation needs to confirm how command number and 32-bit arguments are passed.
// I'm using `sd_command_index` into `.address` and `sd_command_argument` (LSB) into `.din` based on your previous code.
// This is a guess. The actual `sd_controller.v` definition is crucial here.

// Connect physical pins
assign SD_CLK  = sd_sclk;
assign SD_DAT3 = sd_cs;
assign SD_CMD  = sd_mosi;

// =======================================================
// SDHC Initialization FSM and UART debug
// =======================================================
localparam
    STATE_IDLE              = 3'd0,
    STATE_INIT_PRINT        = 3'd1,
    STATE_SEND_CMD0         = 3'd2, // Go-Idle state (Reset)
    STATE_SEND_CMD8         = 3'd3, // Read Interface Condition (SDHC check)
    STATE_READ_R7_BYTE0     = 3'd4,
    STATE_READ_R7_BYTE1     = 3'd5,
    STATE_READ_R7_BYTE2     = 3'd6,
    STATE_READ_R7_BYTE3     = 3'd7, // Full R7 response read
    STATE_LOOP_ACMD41       = 3'd8, // Loop until card is not busy
    STATE_SEND_CMD55        = 3'd9, // Prefix for ACMD
    STATE_SEND_ACMD41       = 3'd10, // Host Capacity Support (HCS)
    STATE_READ_R3_BYTE0     = 3'd11,
    STATE_READ_R3_BYTE1     = 3'd12,
    STATE_READ_R3_BYTE2     = 3'd13,
    STATE_READ_R3_BYTE3     = 3'd14, // Full R3 response read (OCR)
    STATE_INITIALIZED_OK    = 3'd15, // SD card is fully initialized
    STATE_ERROR             = 3'd16; // Error state
    // We need more than 3 bits here! 17 states = 5 bits minimum

localparam
    STATE_IDLE              = 5'd0,
    STATE_INIT_PRINT        = 5'd1,
    STATE_SEND_CMD0         = 5'd2,
    STATE_WAIT_CMD0_R1      = 5'd3, // Wait for R1 response after CMD0
    STATE_SEND_CMD8         = 5'd4,
    STATE_WAIT_CMD8_R7_START= 5'd5, // Wait for R7 start byte (first byte of 4)
    STATE_READ_R7_BYTE1     = 5'd6,
    STATE_READ_R7_BYTE2     = 5'd7,
    STATE_READ_R7_BYTE3     = 5'd8,
    STATE_READ_R7_BYTE4     = 5'd9, // Changed from 0-3 to 1-4 for clarity
    STATE_CHECK_CMD8_R7     = 5'd10, // Check R7 for voltage and check pattern
    STATE_SEND_CMD55_LOOP   = 5'd11, // Prefix for ACMD (loop state)
    STATE_WAIT_CMD55_R1     = 5'd12, // Wait for R1 response after CMD55
    STATE_SEND_ACMD41       = 5'd13,
    STATE_WAIT_ACMD41_R3_START = 5'd14, // Wait for R3 start byte (first byte of 4)
    STATE_READ_R3_BYTE1     = 5'd15,
    STATE_READ_R3_BYTE2     = 5'd16,
    STATE_READ_R3_BYTE3     = 5'd17,
    STATE_READ_R3_BYTE4     = 5'd18, // Full R3 response read (OCR)
    STATE_CHECK_ACMD41_R3   = 5'd19, // Check R3 for busy bit and HCS
    STATE_INITIALIZED_OK    = 5'd20,
    STATE_ERROR             = 5'd21;

reg [4:0] state = STATE_IDLE; // Increased width to 5 bits for 22 states
reg printed_ready = 0;
reg [7:0] r_response_buffer [0:3]; // Buffer for R3/R7 responses (4 bytes)
reg [2:0] r_byte_count = 0; // Counter for R3/R7 bytes

// Counters for retry loops
reg [15:0] retry_counter = 0;
reg [15:0] delay_counter = 0; // For introducing delays if needed

// Flags for SDHC detection
reg is_sdhc = 0;
reg card_is_busy = 1; // Initially busy until ACMD41 clears it

// Define arguments for commands
localparam CMD0_ARG = 32'h0;
localparam CMD8_ARG = 32'h000001AA; // VHS=0001 (2.7-3.6V), Check Pattern=10101010 (0xAA)
localparam ACMD41_ARG_HCS_NONBUSY = 32'h40000000; // HCS bit (bit 30) set, for SDHC/SDXC
localparam ACMD41_ARG_HCS_BUSY    = 32'h00000000; // No HCS, for SDSC or busy

always @(posedge CLOCK_50 or negedge KEY0) begin
    if (!KEY0) begin
        state               <= STATE_IDLE;
        printed_ready       <= 0;
        uart_write          <= 0;
        sd_rd               <= 0;
        sd_wr               <= 0;
        sd_command_index    <= 0;
        sd_command_argument <= 0;
        r_byte_count        <= 0;
        retry_counter       <= 0;
        delay_counter       <= 0;
        is_sdhc             <= 0;
        card_is_busy        <= 1;
    end else begin
        // Default to no UART write and no SD command
        uart_write <= 0;
        sd_rd      <= 0;
        sd_wr      <= 0;

        case (state)
            STATE_IDLE: begin
                // sd_ready usually means controller is powered up, not card is initialized
                if (sd_ready && !printed_ready) begin
                    state <= STATE_INIT_PRINT;
                    delay_counter <= 0;
                end
            end
            STATE_INIT_PRINT: begin
                uart_data     <= {24'd0, "K"};  // Print "K" after controller ready
                uart_write    <= 1;
                printed_ready <= 1;
                state         <= STATE_SEND_CMD0; // Start SD card initialization
                delay_counter <= 0;
            end

            // --- CMD0: Go to Idle State ---
            STATE_SEND_CMD0: begin
                sd_command_index <= 0; // CMD0
                sd_command_argument <= CMD0_ARG;
                sd_wr <= 1; // Assert write for one cycle
                state <= STATE_WAIT_CMD0_R1;
                delay_counter <= 0;
            end
            STATE_WAIT_CMD0_R1: begin
                sd_wr <= 0; // De-assert write
                if (delay_counter < 1000) begin // Give controller time for R1
                    delay_counter <= delay_counter + 1;
                end else begin
                    uart_data <= {16'h4330, sd_recv_data}; // Print "C0" + R1 status
                    uart_write <= 1;
                    if (sd_recv_data == 8'h01) begin // R1_IDLE_STATE expected
                        state <= STATE_SEND_CMD8; // CMD0 successful, proceed to CMD8
                    end else begin
                        state <= STATE_ERROR; // CMD0 failed
                    end
                    delay_counter <= 0;
                end
            end

            // --- CMD8: Send Interface Condition (for SDHC/SDXC) ---
            STATE_SEND_CMD8: begin
                sd_command_index <= 8; // CMD8
                sd_command_argument <= CMD8_ARG;
                sd_wr <= 1;
                state <= STATE_WAIT_CMD8_R7_START;
                delay_counter <= 0;
            end
            STATE_WAIT_CMD8_R7_START: begin
                sd_wr <= 0; // De-assert write
                if (delay_counter < 1000) begin
                    delay_counter <= delay_counter + 1;
                end else begin
                    // Read the 4 bytes of R7 response. First byte is R1 status.
                    r_byte_count <= 0; // Reset byte counter
                    sd_rd <= 1; // Request first byte of R7
                    state <= STATE_READ_R7_BYTE1; // Read actual R7 bytes
                    delay_counter <= 0; // Reset delay for next byte
                end
            end
            STATE_READ_R7_BYTE1: begin
                if (sd_byte_available) begin
                    r_response_buffer[0] <= sd_dout; // Store R1 response byte (status)
                    sd_rd <= 1;
                    state <= STATE_READ_R7_BYTE2;
                end else if (delay_counter < 1000) begin // Timeout if no byte
                    delay_counter <= delay_counter + 1;
                end else begin state <= STATE_ERROR; end
            end
            STATE_READ_R7_BYTE2: begin
                if (sd_byte_available) begin
                    r_response_buffer[1] <= sd_dout; // Store byte 2 (command version/reserved)
                    sd_rd <= 1;
                    state <= STATE_READ_R7_BYTE3;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_READ_R7_BYTE3: begin
                if (sd_byte_available) begin
                    r_response_buffer[2] <= sd_dout; // Store byte 3 (voltage accepted)
                    sd_rd <= 1;
                    state <= STATE_READ_R7_BYTE4;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_READ_R7_BYTE4: begin
                if (sd_byte_available) begin
                    r_response_buffer[3] <= sd_dout; // Store byte 4 (check pattern)
                    sd_rd <= 0; // Stop reading after last byte
                    state <= STATE_CHECK_CMD8_R7;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_CHECK_CMD8_R7: begin
                // Check if R7 indicates 2.7-3.6V and echoes the check pattern
                if (r_response_buffer[0] == 8'h01 && // R1_IDLE_STATE
                    r_response_buffer[2][3:0] == 4'b0001 && // VHS bits (2.7-3.6V)
                    r_response_buffer[3] == 8'hAA) begin // Check pattern (0xAA)
                    // If these conditions are met, it's an SDHC/SDXC card
                    is_sdhc <= 1;
                    uart_data <= {24'd0, "H"}; // Print "H" for SDHC detected
                    uart_write <= 1;
                    state <= STATE_LOOP_ACMD41;
                end else if (r_response_buffer[0] == 8'h05) begin // R1_ILLEGAL_COMMAND (old card, doesn't support CMD8)
                    is_sdhc <= 0;
                    uart_data <= {24'd0, "L"}; // Print "L" for Legacy SD card
                    uart_write <= 1;
                    state <= STATE_LOOP_ACMD41; // Still go to ACMD41, but without HCS bit
                end else begin
                    uart_data <= {16'h4538, r_response_buffer[0]}; // Print "E8" + R1 byte for error
                    uart_write <= 1;
                    state <= STATE_ERROR; // CMD8 failed for other reasons
                end
                delay_counter <= 0; // Reset for next state
            end

            // --- ACMD41: SD_SEND_OP_COND (Loop until card is not busy) ---
            STATE_LOOP_ACMD41: begin
                if (retry_counter > 500) begin // Timeout if card doesn't become ready
                    uart_data <= {24'd0, "T"}; // Print "T" for ACMD41 timeout
                    uart_write <= 1;
                    state <= STATE_ERROR;
                end else if (card_is_busy == 0) begin
                    state <= STATE_INITIALIZED_OK; // Card is ready!
                    retry_counter <= 0;
                end else begin
                    state <= STATE_SEND_CMD55_LOOP;
                end
                retry_counter <= retry_counter + 1;
                delay_counter <= 0;
            end
            STATE_SEND_CMD55_LOOP: begin
                sd_command_index <= 55; // CMD55 (prefix for ACMD)
                sd_command_argument <= 32'h0;
                sd_wr <= 1;
                state <= STATE_WAIT_CMD55_R1;
                delay_counter <= 0;
            end
            STATE_WAIT_CMD55_R1: begin
                sd_wr <= 0;
                if (delay_counter < 1000) begin
                    delay_counter <= delay_counter + 1;
                end else begin
                    if (sd_recv_data == 8'h01) begin // R1_IDLE_STATE expected for CMD55
                        state <= STATE_SEND_ACMD41;
                    end else begin
                        uart_data <= {16'h4535, sd_recv_data}; // Print "E5" + R1 byte for error
                        uart_write <= 1;
                        state <= STATE_ERROR; // CMD55 failed
                    end
                    delay_counter <= 0;
                end
            end
            STATE_SEND_ACMD41: begin
                sd_command_index <= 41; // ACMD41
                if (is_sdhc) sd_command_argument <= ACMD41_ARG_HCS_NONBUSY;
                else sd_command_argument <= ACMD41_ARG_HCS_BUSY; // For SDSC, no HCS bit
                sd_wr <= 1;
                state <= STATE_WAIT_ACMD41_R3_START;
                delay_counter <= 0;
            end
            STATE_WAIT_ACMD41_R3_START: begin
                sd_wr <= 0;
                if (delay_counter < 1000) begin
                    delay_counter <= delay_counter + 1;
                end else begin
                    r_byte_count <= 0; // Reset byte counter
                    sd_rd <= 1; // Request first byte of R3
                    state <= STATE_READ_R3_BYTE1;
                    delay_counter <= 0;
                end
            end
            STATE_READ_R3_BYTE1: begin
                if (sd_byte_available) begin
                    r_response_buffer[0] <= sd_dout; // Store R1 response byte (status)
                    sd_rd <= 1;
                    state <= STATE_READ_R3_BYTE2;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_READ_R3_BYTE2: begin
                if (sd_byte_available) begin
                    r_response_buffer[1] <= sd_dout;
                    sd_rd <= 1;
                    state <= STATE_READ_R3_BYTE3;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_READ_R3_BYTE3: begin
                if (sd_byte_available) begin
                    r_response_buffer[2] <= sd_dout;
                    sd_rd <= 1;
                    state <= STATE_READ_R3_BYTE4;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_READ_R3_BYTE4: begin
                if (sd_byte_available) begin
                    r_response_buffer[3] <= sd_dout;
                    sd_rd <= 0; // Stop reading
                    state <= STATE_CHECK_ACMD41_R3;
                end else if (delay_counter < 1000) begin delay_counter <= delay_counter + 1; end else begin state <= STATE_ERROR; end
            end
            STATE_CHECK_ACMD41_R3: begin
                // Check OCR (r_response_buffer[0] is R1, [1-3] are OCR register)
                // OCR[31] is the Card Capacity Status (CCS) bit (0=SDSC, 1=SDHC/SDXC)
                // OCR[31] is the Power Up Status (BUSY) bit (0=busy, 1=ready)
                if (r_response_buffer[0] == 8'h00) begin // R1_OK (card not busy, last bit of R1 is 0)
                    card_is_busy <= ~r_response_buffer[1][7]; // Busy bit (OCR[31]) is the MSB of the first byte
                                                              // Your controller's R3 response might pack it differently.
                                                              // For standard R3, it's bit 31 (MSB of the 4th byte read, or first byte of OCR data).
                                                              // Assuming `r_response_buffer[1]` is the first byte of the OCR.
                    if (is_sdhc) begin // Only check CCS for SDHC cards
                        if (r_response_buffer[1][6] == 1) begin // OCR[30] is HCS bit, should be 1 if SDHC
                           // Card confirmed SDHC by itself too, if we sent HCS
                        end
                    end
                    // Print OCR for debugging
                    uart_data <= {8'h4F, 8'h43, r_response_buffer[1], r_response_buffer[2]}; // Prints "OC" + first 2 bytes of OCR
                    uart_write <= 1;
                    state <= STATE_LOOP_ACMD41; // Loop until card_is_busy becomes 0
                end else begin
                    uart_data <= {16'h4531, r_response_buffer[0]}; // Print "E1" + R1 byte for error
                    uart_write <= 1;
                    state <= STATE_ERROR;
                end
                delay_counter <= 0;
            end

            STATE_INITIALIZED_OK: begin
                if (!printed_ready) begin // Print only once
                    uart_data <= {24'd0, "R"}; // Print "R" for Ready (fully initialized)
                    uart_write <= 1;
                    printed_ready <= 1;
                end
                // Now you can proceed to send CMD10 (Read CID) or other commands
                // For simplicity, let's just loop "R" after full init for now.
                state <= STATE_IDLE; // Loop back to idle
            end

            STATE_ERROR: begin
                uart_data <= {24'd0, "E"}; // Print "E" for error
                uart_write <= 1;
                state <= STATE_IDLE; // Go back to idle for now, or stay in error
            end
        endcase
    end
end

endmodule
