module cpu (
    input wire clock,                    // Clock input
    input wire reset_n,                  // Active-low reset
    input wire [31:0] instruction,       // 32-bit instruction input
    output reg [63:0] mem_addr,          // Memory address for load/store
    output reg [63:0] mem_data_out,      // Data to write to memory (store)
    output reg mem_we,                   // Memory write enable
    input wire [63:0] mem_data_in        // Data read from memory (load)
    );

    // --- Privilege Modes ---
    localparam M_mode = 2'b11;
    localparam S_mode = 2'b01;
    localparam U_mode = 2'b00;
    reg [1:0] current_privilege_mode;

    // --- CSR Registers ---
    reg [63:0] csre [0:4096]; // CSR registers (4096 entries, 64-bit)
    integer mstatus = 12'h300;
    integer mtvec = 12'h305;
    integer mepc = 12'h341;
    integer mcause = 12'h342;
    integer sstatus = 12'h100;
    integer stvec = 12'h105;
    integer sepc = 12'h141;
    integer scause = 12'h142;
    integer medeleg = 12'h302;

    // --- CSR Index Function ---
    function [4:0] csr_index;
        input [11:0] csr_wire;
        begin
            case (csr_wire)
                12'hF11: csr_index = 5'd1;   // mvendorid
                12'hF12: csr_index = 5'd2;   // marchid
                12'hF13: csr_index = 5'd3;   // mimpid
                12'hF14: csr_index = 5'd4;   // mhartid
                12'hF15: csr_index = 5'd5;   // mconfigptr
                12'h300: csr_index = 5'd6;   // mstatus
                12'h301: csr_index = 5'd7;   // misa
                12'h302: csr_index = 5'd8;   // medeleg
                12'h303: csr_index = 5'd9;   // mideleg
                12'h304: csr_index = 5'd10;  // mie
                12'h305: csr_index = 5'd11;  // mtvec
                12'h306: csr_index = 5'd12;  // mcounteren
                12'h307: csr_index = 5'd13;  // mtvt
                12'h310: csr_index = 5'd14;  // mstatush
                12'h340: csr_index = 5'd15;  // mscratch
                12'h341: csr_index = 5'd16;  // mepc
                12'h342: csr_index = 5'd17;  // mcause
                12'h343: csr_index = 5'd18;  // mtval
                12'h344: csr_index = 5'd19;  // mip
                12'h34A: csr_index = 5'd20;  // mtinst
                12'h34B: csr_index = 5'd21;  // mtval2
                12'h30A: csr_index = 5'd22;  // menvcfg
                12'h31A: csr_index = 5'd23;  // menvcfgh
                12'h747: csr_index = 5'd24;  // mseccfg
                12'h757: csr_index = 5'd25;  // mseccfgh
                12'h100: csr_index = 5'd31;  // sstatus
                default: csr_index = 5'b00000;
            endcase
        end
    endfunction

    // --- Registers and Memories ---
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)
    (* ram_style = "block" *) reg [7:0] drom [0:9999]; // Data memory (8-bit, 10,000 bytes)
    reg [63:0] pc; // Program counter

    // --- Instruction Decoding ---
    wire [6:0] w_op = instruction[6:0];
    wire [4:0] w_rd = instruction[11:7];
    wire [2:0] w_f3 = instruction[14:12];
    wire [4:0] w_rs1 = instruction[19:15];
    wire [4:0] w_rs2 = instruction[24:20];
    wire [6:0] w_f7 = instruction[31:25];
    wire [11:0] w_imm = instruction[31:20];
    wire [19:0] w_upimm = instruction[31:12];
    wire [20:0] w_jimm = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
    wire [11:0] w_simm = {instruction[31:25], instruction[11:7]};
    wire [12:0] w_bimm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [5:0] w_shamt = instruction[25:20];
    wire [11:0] w_csr = instruction[31:20];
    wire [4:0] w_zimm = instruction[19:15];

    // --- Combinational Logic ---
    reg [63:0] sum, sum_imm, sub, mirro_rs2, mirro_imm, sign_extended_bimm;
    reg [31:0] sum_imm_32, slliw_s1, srliw_s1, sraiw_s1;
    always @(*) begin
        sum = re[w_rs1] + re[w_rs2];
        sum_imm = re[w_rs1] + {{52{w_imm[11]}}, w_imm};
        sum_imm_32 = re[w_rs1][31:0] + {{20{w_imm[11]}}, w_imm};
        mirro_rs2 = ~re[w_rs2] + 1;
        mirro_imm = ~{{52{w_imm[11]}}, w_imm} + 1;
        sub = re[w_rs1] + mirro_rs2;
        sign_extended_bimm = {{51{instruction[31]}}, w_bimm};
        slliw_s1 = re[w_rs1][31:0] << w_shamt[4:0];
        srliw_s1 = re[w_rs1][31:0] >> w_shamt[4:0];
        sraiw_s1 = $signed(re[w_rs1][31:0]) >>> w_shamt[4:0];
    end

    // --- Memory Access ---
    reg [63:0] l_addr, s_addr;
    always @(*) begin
        l_addr = re[w_rs1] + {{52{w_imm[11]}}, w_imm}; // Load address
        s_addr = re[w_rs1] + {{52{w_simm[11]}}, w_simm}; // Store address
    end

    // --- Instruction Execution ---
    reg [4:0] csr_id;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc <= 0;
            current_privilege_mode <= M_mode;
            for (integer i = 0; i < 32; i = i + 1) re[i] <= 64'h0;
            mem_we <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
        end else begin
            pc <= pc + 4; // Default PC increment
            csr_id = csr_index(w_csr);
            mem_we <= 0; // Default: no memory write

            casez (instruction)
                // --- U-type ---
                32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= {{32{w_upimm[19]}}, w_upimm, 12'b0}; // LUI
                32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= pc + {{32{w_upimm[19]}}, w_upimm, 12'b0}; // AUIPC
                // --- Load ---
                32'b???????_?????_?????_000_?????_0000011: begin // LB
                    mem_addr <= l_addr;
                    re[w_rd] <= {{56{mem_data_in[7]}}, mem_data_in[7:0]};
                end
                32'b???????_?????_?????_100_?????_0000011: begin // LBU
                    mem_addr <= l_addr;
                    re[w_rd] <= {56'b0, mem_data_in[7:0]};
                end
                32'b???????_?????_?????_001_?????_0000011: begin // LH
                    mem_addr <= l_addr;
                    re[w_rd] <= {{48{mem_data_in[15]}}, mem_data_in[15:0]};
                end
                32'b???????_?????_?????_101_?????_0000011: begin // LHU
                    mem_addr <= l_addr;
                    re[w_rd] <= {48'b0, mem_data_in[15:0]};
                end
                32'b???????_?????_?????_010_?????_0000011: begin // LW
                    mem_addr <= l_addr;
                    re[w_rd] <= {{32{mem_data_in[31]}}, mem_data_in[31:0]};
                end
                32'b???????_?????_?????_110_?????_0000011: begin // LWU
                    mem_addr <= l_addr;
                    re[w_rd] <= {32'b0, mem_data_in[31:0]};
                end
                32'b???????_?????_?????_011_?????_0000011: begin // LD
                    mem_addr <= l_addr;
                    re[w_rd] <= mem_data_in;
                end
                // --- Store ---
                32'b???????_?????_?????_000_?????_0100011: begin // SB
                    mem_addr <= s_addr;
                    mem_data_out <= re[w_rs2][7:0];
                    mem_we <= 1;
                end
                32'b???????_?????_?????_001_?????_0100011: begin // SH
                    mem_addr <= s_addr;
                    mem_data_out <= re[w_rs2][15:0];
                    mem_we <= 1;
                end
                32'b???????_?????_?????_010_?????_0100011: begin // SW
                    mem_addr <= s_addr;
                    mem_data_out <= re[w_rs2][31:0];
                    mem_we <= 1;
                end
                32'b???????_?????_?????_011_?????_0100011: begin // SD
                    mem_addr <= s_addr;
                    mem_data_out <= re[w_rs2];
                    mem_we <= 1;
                end
                // --- Math-R ---
                32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= sum; // ADD
                32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= sub; // SUB
                32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 64'h1 : 64'h0; // SLT
                32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= (re[w_rs1] < re[w_rs2]) ? 64'h1 : 64'h0; // SLTU
                32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= re[w_rs1] | re[w_rs2]; // OR
                32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= re[w_rs1] & re[w_rs2]; // AND
                32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= re[w_rs1] ^ re[w_rs2]; // XOR
                32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= re[w_rs1] << re[w_rs2][5:0]; // SLL
                32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= re[w_rs1] >> re[w_rs2][5:0]; // SRL
                32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) >>> re[w_rs2][5:0]; // SRA
                // --- Math-R (Word) ---
                32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= {{32{sum[31]}}, sum[31:0]}; // ADDW
                32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= {{32{sub[31]}}, sub[31:0]}; // SUBW
                32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= {{32{re[w_rs1][31-re[w_rs2][4:0]]}}, re[w_rs1][31:0] << re[w_rs2][4:0]}; // SLLW
                32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= (re[w_rs2][4:0] == 0) ? {{32{re[w_rs1][31]}}, re[w_rs1][31:0]} : {{32{(re[w_rs1][31:0] >> re[w_rs2][4:0])[31]}}, re[w_rs1][31:0] >> re[w_rs2][4:0]}; // SRLW
                32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= {{32{re[w_rs1][31]}}, $signed(re[w_rs1][31:0]) >>> re[w_rs2][4:0]}; // SRAW
                // --- Math-I ---
                32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= sum_imm; // ADDI
                32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= ($signed(re[w_rs1]) < $signed({{52{w_imm[11]}}, w_imm})) ? 64'h1 : 64'h0; // SLTI
                32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (re[w_rs1] < {{52{w_imm[11]}}, w_imm}) ? 64'h1 : 64'h0; // SLTIU
                32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= re[w_rs1] | {{52{w_imm[11]}}, w_imm}; // ORI
                32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= re[w_rs1] & {{52{w_imm[11]}}, w_imm}; // ANDI
                32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= re[w_rs1] ^ {{52{w_imm[11]}}, w_imm}; // XORI
                32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= re[w_rs1] << w_shamt; // SLLI
                32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= re[w_rs1] >> w_shamt; // SRLI
                32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) >>> w_shamt; // SRAI
                // --- Math-I (Word) ---
                32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= {{32{sum_imm_32[31]}}, sum_imm_32}; // ADDIW
                32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= {{32{slliw_s1[31]}}, slliw_s1}; // SLLIW
                32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{srliw_s1[31]}}, srliw_s1}; // SRLIW
                32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{sraiw_s1[31]}}, sraiw_s1}; // SRAIW
                // --- Jump ---
                32'b???????_?????_?????_???_?????_1101111: begin // JAL
                    re[w_rd] <= pc + 4;
                    pc <= pc + {{43{w_jimm[20]}}, w_jimm};
                end
                32'b???????_?????_?????_???_?????_1100111: begin // JALR
                    re[w_rd] <= pc + 4;
                    pc <= (re[w_rs1] + {{52{w_imm[11]}}, w_imm}) & 64'hFFFFFFFFFFFFFFFE;
                end
                // --- Branch ---
                32'b???????_?????_?????_000_?????_1100011: pc <= (re[w_rs1] == re[w_rs2]) ? pc + sign_extended_bimm : pc + 4; // BEQ
                32'b???????_?????_?????_001_?????_1100011: pc <= (re[w_rs1] != re[w_rs2]) ? pc + sign_extended_bimm : pc + 4; // BNE
                32'b???????_?????_?????_100_?????_1100011: pc <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? pc + sign_extended_bimm : pc + 4; // BLT
                32'b???????_?????_?????_101_?????_1100011: pc <= ($signed(re[w_rs1]) >= $signed(re[w_rs2])) ? pc + sign_extended_bimm : pc + 4; // BGE
                32'b???????_?????_?????_110_?????_1100011: pc <= (re[w_rs1] < re[w_rs2]) ? pc + sign_extended_bimm : pc + 4; // BLTU
                32'b???????_?????_?????_111_?????_1100011: pc <= (re[w_rs1] >= re[w_rs2]) ? pc + sign_extended_bimm : pc + 4; // BGEU
                // --- CSR ---
                32'b???????_?????_?????_001_?????_1110011: begin // CSRRW
                    if (w_rd != 5'b00000) re[w_rd] <= csre[csr_id];
                    csre[csr_id] <= re[w_rs1];
                end
                32'b???????_?????_?????_010_?????_1110011: begin // CSRRS
                    re[w_rd] <= csre[csr_id];
                    if (w_rs1 != 5'b00000) csre[csr_id] <= re[w_rs1] | csre[csr_id];
                end
                32'b???????_?????_?????_011_?????_1110011: begin // CSRRC
                    re[w_rd] <= csre[csr_id];
                    if (w_rs1 != 5'b00000) csre[csr_id] <= ~re[w_rs1] & csre[csr_id];
                end
                32'b???????_?????_?????_101_?????_1110011: begin // CSRRWI
                    if (w_rd != 5'b00000) re[w_rd] <= csre[csr_id];
                    csre[csr_id] <= {59'b0, w_zimm};
                end
                32'b???????_?????_?????_110_?????_1110011: begin // CSRRSI
                    re[w_rd] <= csre[csr_id];
                    if (w_zimm != 5'b00000) csre[csr_id] <= {59'b0, w_zimm} | csre[csr_id];
                end
                32'b???????_?????_?????_111_?????_1110011: begin // CSRRCI
                    re[w_rd] <= csre[csr_id];
                    if (w_zimm != 5'b00000) csre[csr_id] <= ~{59'b0, w_zimm} & csre[csr_id];
                end
                // --- Fence ---
                32'b???????_?????_?????_000_?????_0001111: begin end // FENCE
                32'b???????_?????_?????_001_?????_0001111: begin end // FENCE.I
                // --- Ecall ---
                32'b0000000_00000_?????_000_?????_1110011: begin
                    if (current_privilege_mode == U_mode && csre[medeleg][8] == 1) begin
                        csre[scause][63] <= 0;
                        csre[scause][62:0] <= 8;
                        csre[sepc] <= pc;
                        csre[sstatus][8] <= 0;
                        csre[sstatus][5] <= csre[sstatus][1];
                        csre[sstatus][1] <= 0;
                        pc <= (csre[stvec][63:2] << 2);
                        current_privilege_mode <= S_mode;
                    end else begin
                        csre[mcause][63] <= 0;
                        csre[mepc] <= pc;
                        csre[mstatus][7] <= csre[mstatus][3];
                        csre[mstatus][3] <= 0;
                        pc <= (csre[mtvec][63:2] << 2);
                        if (current_privilege_mode == U_mode && csre[medeleg][8] == 0) csre[mcause][62:0] <= 8;
                        else if (current_privilege_mode == S_mode) csre[mcause][62:0] <= 9;
                        else if (current_privilege_mode == M_mode) csre[mcause][62:0] <= 11;
                        csre[mstatus][12:11] <= current_privilege_mode;
                        current_privilege_mode <= M_mode;
                    end
                end
                // --- Ebreak ---
                32'b0000000_00001_?????_000_?????_1110011: begin end // EBREAK
                // --- Sret ---
                32'b0001000_00010_?????_000_?????_1110011: begin
                    if (csre[sstatus][8] == 0) current_privilege_mode <= U_mode;
                    else current_privilege_mode <= S_mode;
                    csre[sstatus][1] <= csre[sstatus][5];
                    csre[sstatus][5] <= 1;
                    csre[sstatus][8] <= 0;
                    pc <= csre[sepc];
                end
                // --- Mret ---
                32'b0011000_00010_?????_000_?????_1110011: begin
                    csre[mstatus][3] <= csre[mstatus][7];
                    csre[mstatus][7] <= 1;
                    if (csre[mstatus][12:11] < M_mode) csre[mstatus][17] <= 0;
                    current_privilege_mode <= csre[mstatus][12:11];
                    csre[mstatus][12:11] <= 2'b00;
                    pc <= csre[mepc];
                end
            endcase
            re[0] <= 64'h0; // x0 is always 0
        end
    end
endmodule
