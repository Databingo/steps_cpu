module s4 (
    input reset_n, clock,
    output [31:0] oir,
    output [63:0] opc, ox0, ox1, ox2, ox3, ox4, ox5, ox6, ox7, ox8, ox9, ox10, ox11, ox12, ox13, ox14, ox15,
                  ox16, ox17, ox18, ox19, ox20, ox21, ox22, ox23, ox24, ox25, ox26, ox27, ox28, ox29, ox30, ox31,
    output [63:0] osign_extended_bimm,
    output [6:0] oop,
    output [2:0] of3,
    output [6:0] of7,
    output [11:0] oimm,
    output [19:0] oupimm,
    output [5:0] oshamt
);

    localparam M_mode = 2'b11, S_mode = 2'b01, U_mode = 2'b00;
    reg [1:0] current_privilege_mode;
    reg [63:0] pc, re[0:31], csre[0:4096];
    reg [7:0] irom[0:9999], drom[0:9999], srom[0:399];
    reg [31:0] ir;

    // CSR indices
    localparam sstatus = 12'h100, sedeleg = 12'h102, sideleg = 12'h103, sie = 12'h104, stvec = 12'h105,
               scounteren = 12'h106, sscratch = 12'h140, sepc = 12'h141, scause = 12'h142, stval = 12'h143,
               sip = 12'h144, satp = 12'h180, scontext = 12'h5a8, mvendorid = 12'hF11, marchid = 12'hF12,
               mimpid = 12'hF13, mhartid = 12'hF14, mconfigptr = 12'hF15, mstatus = 12'h300, misa = 12'h301,
               medeleg = 12'h302, mideleg = 12'h303, mie = 12'h304, mtvec = 12'h305, mcounteren = 12'h306,
               mtvt = 12'h307, mstatush = 12'h310, mscratch = 12'h340, mepc = 12'h341, mcause = 12'h342,
               mtval = 12'h343, mip = 12'h344, mtinst = 12'h34A, mtval2 = 12'h34B, menvcfg = 12'h30A,
               menvcfgh = 12'h31A, mseccfg = 12'h747, mseccfgh = 12'h757;

    // Instruction decoding
    wire [31:0] w_ir = {irom[pc+3], irom[pc+2], irom[pc+1], irom[pc]};
    wire [6:0] wire_op = w_ir[6:0];
    wire [4:0] w_rd = w_ir[11:7];
    wire [4:0] w_rs1 = w_ir[19:15];
    wire [4:0] w_rs2 = w_ir[24:20];
    wire [2:0] wire_f3 = w_ir[14:12];
    wire [6:0] wire_f7 = w_ir[31:25];
    wire [11:0] w_imm = w_ir[31:20];
    wire [19:0] w_upimm = w_ir[31:12];
    wire [20:0] w_jimm = {w_ir[31], w_ir[19:12], w_ir[20], w_ir[30:21], 1'b0};
    wire [11:0] w_simm = {w_ir[31:25], w_ir[11:7]};
    wire [12:0] w_bimm = {w_ir[31], w_ir[7], w_ir[30:25], w_ir[11:8], 1'b0};
    wire [5:0] w_shamt = w_ir[25:20];
    wire [11:0] w_csr = w_ir[31:20];
    wire [4:0] w_zimm = w_ir[19:15];

    // Outputs
    assign oir = w_ir;
    assign opc = pc;
    assign oop = wire_op;
    assign of3 = wire_f3;
    assign of7 = wire_f7;
    assign oimm = w_imm;
    assign oupimm = w_upimm;
    assign oshamt = w_shamt;
    assign {ox31, ox30, ox29, ox28, ox27, ox26, ox25, ox24, ox23, ox22, ox21, ox20, ox19, ox18, ox17, ox16,
            ox15, ox14, ox13, ox12, ox11, ox10, ox9, ox8, ox7, ox6, ox5, ox4, ox3, ox2, ox1, ox0} = re;
    assign osign_extended_bimm = {{51{w_ir[31]}}, w_bimm};

    // Combinational logic
    wire [63:0] sum = re[w_rs1] + re[w_rs2];
    wire [63:0] s_imm = re[w_rs1] + {{52{w_imm[11]}}, w_imm};
    wire [31:0] s_imm_32 = re[w_rs1][31:0] + {{20{w_imm[11]}}, w_imm};
    wire [63:0] sub = re[w_rs1] - re[w_rs2];
    wire [63:0] sub_imm = re[w_rs1] - {{52{w_imm[11]}}, w_imm};

    // Load/store helper functions
    function [63:0] load_data(input [63:0] addr, input [2:0] f3);
        reg [63:0] data;
        integer i;
        begin
            case (f3)
                3'b000: data = {{56{drom[addr][7]}}, drom[addr]}; // LB
                3'b100: data = {56'b0, drom[addr]}; // LBU
                3'b001: data = {{48{drom[addr+1][7]}}, drom[addr+1], drom[addr]}; // LH
                3'b101: data = {48'b0, drom[addr+1], drom[addr]}; // LHU
                3'b010: data = {{32{drom[addr+3][7]}}, drom[addr+3], drom[addr+2], drom[addr+1], drom[addr]}; // LW
                3'b110: data = {32'b0, drom[addr+3], drom[addr+2], drom[addr+1], drom[addr]}; // LWU
                3'b011: begin // LD
                    for (i = 0; i < 8; i = i + 1)
                        data[i*8 +: 8] = drom[addr+i];
                end
                default: data = 64'b0;
            endcase
            load_data = data;
        end
    endfunction

    function store_data(input [63:0] addr, input [63:0] value, input [2:0] f3);
        integer i;
        begin
            case (f3)
                3'b000: drom[addr] = value[7:0]; // SB
                3'b001: begin // SH
                    drom[addr] = value[7:0];
                    drom[addr+1] = value[15:8];
                end
                3'b010: begin // SW
                    for (i = 0; i < 4; i = i + 1)
                        drom[addr+i] = value[i*8 +: 8];
                end
                3'b011: begin // SD
                    for (i = 0; i < 8; i = i + 1)
                        drom[addr+i] = value[i*8 +: 8];
                end
            endcase
        end
    endfunction

    // CSR index function
    function [4:0] csr_id(input [11:0] csr);
        case (csr)
            12'h100: csr_id = 5'd1;  // sstatus
            12'hF11: csr_id = 5'd2;  // mvendorid
            12'hF12: csr_id = 5'd3;  // marchid
            12'hF13: csr_id = 5'd4;  // mimpid
            12'hF14: csr_id = 5'd5;  // mhartid
            12'h300: csr_id = 5'd6;  // mstatus
            12'h302: csr_id = 5'd7;  // medeleg
            12'h305: csr_id = 5'd8;  // mtvec
            12'h341: csr_id = 5'd9;  // mepc
            12'h342: csr_id = 5'd10; // mcause
            default: csr_id = 5'd0;
        endcase
    endfunction

    // Main sequential logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc <= 0;
            current_privilege_mode <= M_mode;
            for (integer i = 0; i < 32; i = i + 1) re[i] <= 64'h0;
        end else begin
            pc <= pc + 4;
            ir <= w_ir;
            casez (w_ir)
                32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= {{32{w_upimm[19]}}, w_upimm, 12'b0}; // LUI
                32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= pc + {{32{w_upimm[19]}}, w_upimm, 12'b0}; // AUIPC
                32'b???????_?????_?????_000_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b000); // LB
                32'b???????_?????_?????_100_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b100); // LBU
                32'b???????_?????_?????_001_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b001); // LH
                32'b???????_?????_?????_101_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b101); // LHU
                32'b???????_?????_?????_010_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b010); // LW
                32'b???????_?????_?????_110_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b110); // LWU
                32'b???????_?????_?????_011_?????_0000011: re[w_rd] <= load_data(re[w_rs1] + {{52{w_imm[11]}}, w_imm}, 3'b011); // LD
                32'b???????_?????_?????_000_?????_0100011: store_data(re[w_rs1] + {{52{w_simm[11]}}, w_simm}, re[w_rs2], 3'b000); // SB
                32'b???????_?????_?????_001_?????_0100011: store_data(re[w_rs1] + {{52{w_simm[11]}}, w_simm}, re[w_rs2], 3'b001); // SH
                32'b???????_?????_?????_010_?????_0100011: store_data(re[w_rs1] + {{52{w_simm[11]}}, w_simm}, re[w_rs2], 3'b010); // SW
                32'b???????_?????_?????_011_?????_0100011: store_data(re[w_rs1] + {{52{w_simm[11]}}, w_simm}, re[w_rs2], 3'b011); // SD
                32'b0000000_?????_?????_000_?????_0110011: begin re[w_rd] <= sum; if (sum[63] != re[w_rs1][63] && re[w_rs1][63] == re[w_rs2][63]) {re[3], re[4]} <= {1'b1, re[w_rs1][63]}; end // ADD
                32'b0100000_?????_?????_000_?????_0110011: begin re[w_rd] <= sub; if (sub[63] != re[w_rs1][63] && re[w_rs1][63] == ~re[w_rs2][63]) {re[3], re[4]} <= {1'b1, re[w_rs1][63]}; end // SUB
                32'b0000000_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 1'b1 : 1'b0; // SLT
                32'b0000000_?????_?????_011_?????_0110011: re[w_rd] <= re[w_rs1] < re[w_rs2] ? 1'b1 : 1'b0; // SLTU
                32'b0000000_?????_?????_110_?????_0110011: re[w_rd] <= re[w_rs1] | re[w_rs2]; // OR
                32'b0000000_?????_?????_111_?????_0110011: re[w_rd] <= re[w_rs1] & re[w_rs2]; // AND
                32'b0000000_?????_?????_100_?????_0110011: re[w_rd] <= re[w_rs1] ^ re[w_rs2]; // XOR
                32'b0000000_?????_?????_001_?????_0110011: re[w_rd] <= re[w_rs1] << re[w_rs2][5:0]; // SLL
                32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= re[w_rs1] >> re[w_rs2][5:0]; // SRL
                32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) >>> re[w_rs2][5:0]; // SRA
                32'b???????_?????_?????_000_?????_0010011: begin re[w_rd] <= s_imm; if (s_imm[63] != re[w_rs1][63] && re[w_rs1][63] == w_imm[11]) {re[3], re[4]} <= {1'b1, re[w_rs1][63]}; end // ADDI
                32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= ($signed(re[w_rs1]) < $signed({{52{w_imm[11]}}, w_imm})) ? 1'b1 : 1'b0; // SLTI
                32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= re[w_rs1] < {{52{w_imm[11]}}, w_imm} ? 1'b1 : 1'b0; // SLTIU
                32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= re[w_rs1] | {{52{w_imm[11]}}, w_imm}; // ORI
                32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= re[w_rs1] & {{52{w_imm[11]}}, w_imm}; // ANDI
                32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= re[w_rs1] ^ {{52{w_imm[11]}}, w_imm}; // XORI
                32'b000000?_?????_?????_001_?????_0010011: re[w_rd] <= re[w_rs1] << w_shamt; // SLLI
                32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= re[w_rs1] >> w_shamt; // SRLI
                32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) >>> w_shamt; // SRAI
                32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= {{32{s_imm_32[31]}}, s_imm_32}; // ADDIW
                32'b0000000_?????_?????_001_?????_0011011: re[w_rd] <= {{32{re[w_rs1][31]}}, re[w_rs1][31:0] << w_shamt[4:0]}; // SLLIW
                32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{re[w_rs1][31]}}, re[w_rs1][31:0] >> w_shamt[4:0]}; // SRLIW
                32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{re[w_rs1][31]}}, $signed(re[w_rs1][31:0]) >>> w_shamt[4:0]}; // SRAIW
                32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= {{32{sum[31]}}, sum[31:0]}; // ADDW
                32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= {{32{sub[31]}}, sub[31:0]}; // SUBW
                32'b0000000_?????_?????_001_?????_0111011: re[w_rd] <= {{32{re[w_rs1][31-re[w_rs2][4:0]]}}, re[w_rs1][31:0] << re[w_rs2][4:0]}; // SLLW
                32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= re[w_rs2][4:0] == 0 ? {{32{re[w_rs1][31]}}, re[w_rs1][31:0]} : re[w_rs1][31:0] >> re[w_rs2][4:0]; // SRLW
                32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= {{32{re[w_rs1][31]}}, $signed(re[w_rs1][31:0]) >>> re[w_rs2][4:0]}; // SRAW
                32'b???????_?????_?????_???_?????_1101111: begin re[w_rd] <= pc + 4; pc <= pc + {{43{w_jimm[20]}}, w_jimm}; end // JAL
                32'b???????_?????_?????_000_?????_1100111: begin re[w_rd] <= pc + 4; pc <= (re[w_rs1] + {{52{w_imm[11]}}, w_imm}) & 64'hFFFFFFFFFFFFFFFE; end // JALR
                32'b???????_?????_?????_000_?????_1100011: pc <= re[w_rs1] == re[w_rs2] ? pc + {{51{w_ir[31]}}, w_bimm} : pc + 4; // BEQ
                32'b???????_?????_?????_001_?????_1100011: pc <= re[w_rs1] != re[w_rs2] ? pc + {{51{w_ir[31]}}, w_bimm} : pc + 4; // BNE
                32'b???????_?????_?????_100_?????_1100011: pc <= $signed(re[w_rs1]) < $signed(re[w_rs2]) ? pc + {{51{w_ir[31]}}, w_bimm} : pc + 4; // BLT
                32'b???????_?????_?????_101_?????_1100011: pc <= $signed(re[w_rs1]) >= $signed(re[w_rs2]) ? pc + {{51{w_ir[31]}}, w_bimm} : pc + 4; // BGE
                32'b???????_?????_?????_110_?????_1100011: pc <= re[w_rs1] < re[w_rs2] ? pc + {{51{w_ir[31]}}, w_bimm} : pc + 4; // BLTU
                32'b???????_?????_?????_111_?????_1100011: pc <= re[w_rs1] >= re[w_rs2] ? pc + {{51{w_ir[31]}}, w_bimm} : pc + 4; // BGEU
                32'b???????_?????_?????_000_?????_0001111: begin end // FENCE
                32'b0000000_00000_00000_001_00000_0001111: begin end // FENCE.I
                32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 5'b0) re[w_rd] <= csre[csr_id(w_csr)]; csre[csr_id(w_csr)] <= re[w_rs1]; end // CSRRW
                32'b???????_?????_?????_010_?????_1110011: begin re[w_rd] <= csre[csr_id(w_csr)]; if (w_rs1 != 5'b0) csre[csr_id(w_csr)] <= re[w_rs1] | csre[csr_id(w_csr)]; end // CSRRS
                32'b???????_?????_?????_011_?????_1110011: begin re[w_rd] <= csre[csr_id(w_csr)]; if (w_rs1 != 5'b0) csre[csr_id(w_csr)] <= ~re[w_rs1] & csre[csr_id(w_csr)]; end // CSRRC
                32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 5'b0) re[w_rd] <= csre[csr_id(w_csr)]; csre[csr_id(w_csr)] <= {59'b0, w_zimm}; end // CSRRWI
                32'b???????_?????_?????_110_?????_1110011: begin re[w_rd] <= csre[csr_id(w_csr)]; if (w_zimm != 5'b0) csre[csr_id(w_csr)] <= {59'b0, w_zimm} | csre[csr_id(w_csr)]; end // CSRRSI
                32'b???????_?????_?????_111_?????_1110011: begin re[w_rd] <= csre[csr_id(w_csr)]; if (w_zimm != 5'b0) csre[csr_id(w_csr)] <= ~{59'b0, w_zimm} & csre[csr_id(w_csr)]; end // CSRRCI
                32'b0000000_00000_00000_000_00000_1110011: begin
                    if (current_privilege_mode == U_mode && csre[medeleg][8]) begin
                        csre[scause] <= {1'b0, 63'd8};
                        csre[sepc] <= pc;
                        csre[sstatus][8] <= 0;
                        csre[sstatus][5] <= csre[sstatus][1];
                        csre[sstatus][1] <= 0;
                        pc <= csre[stvec][63:2] << 2;
                        current_privilege_mode <= S_mode;
                    end else begin
                        csre[mcause] <= {1'b0, (current_privilege_mode == U_mode) ? 63'd8 : (current_privilege_mode == S_mode) ? 63'd9 : 63'd11};
                        csre[mepc] <= pc;
                        csre[mstatus][7] <= csre[mstatus][3];
                        csre[mstatus][3] <= 0;
                        csre[mstatus][12:11] <= current_privilege_mode;
                        pc <= csre[mtvec][63:2] << 2;
                        current_privilege_mode <= M_mode;
                    end
                end // ECALL
                32'b000000000001_00000_000_00000_1110011: begin end // EBREAK
                32'b000100000010_00000_000_00000_1110011: begin
                    current_privilege_mode <= csre[sstatus][8] ? S_mode : U_mode;
                    csre[sstatus][1] <= csre[sstatus][5];
                    csre[sstatus][5] <= 1;
                    csre[sstatus][8] <= 0;
                    pc <= csre[sepc];
                end // SRET
                32'b001100000010_00000_000_00000_1110011: begin
                    csre[mstatus][3] <= csre[mstatus][7];
                    csre[mstatus][7] <= 1;
                    if (csre[mstatus][12:11] < M_mode) csre[mstatus][17] <= 0;
                    current_privilege_mode <= csre[mstatus][12:11];
                    csre[mstatus][12:11] <= 2'b00;
                    pc <= csre[mepc];
                end // MRET
                default: begin
                    if (current_privilege_mode == U_mode && csre[medeleg][2]) begin
                        csre[scause] <= {1'b0, 63'd2};
                        csre[sepc] <= pc;
                        csre[sstatus][8] <= 0;
                        csre[sstatus][5] <= csre[sstatus][1];
                        csre[sstatus][1] <= 0;
                        pc <= csre[stvec][63:2] << 2;
                        current_privilege_mode <= S_mode;
                    end else begin
                        csre[mcause] <= {1'b0, 63'd2};
                        csre[mepc] <= pc;
                        csre[mstatus][7] <= csre[mstatus][3];
                        csre[mstatus][3] <= 0;
                        csre[mstatus][12:11] <= current_privilege_mode;
                        pc <= csre[mtvec][63:2] << 2;
                        current_privilege_mode <= M_mode;
                    end
                end // Illegal instruction
            endcase
            re[0] <= 64'h0;
        end
    end

    initial begin
        $readmemb("./binary_instructions.txt", irom);
        $readmemh("./data_test.txt", drom);
    end
endmodule
