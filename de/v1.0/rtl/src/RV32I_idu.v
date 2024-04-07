//version:v1.0
//author:lsh
//date:2024.4.1
module RV32I_idu #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    input                               clk,
    input                               rst,
    //from ifu
    input[WORD_WTH-1:0]                 idu_instr_i,
    input[ADDR_WTH-1:0]                 idu_pc_i,
    input[ADDR_WTH-1:0]                 idu_pc_plus_4_i,
    //control signal to exu stage
    output                              idu_jump_o,
    output                              idu_RegW_EN_o,
    output[WB_MUX_WTH-1:0]              idu_RegW_sel_o,
    output                              idu_MemW_EN_o,
    output                              idu_TakenAddr_sel_o,
    output                              idu_auipc_sel_o,
    output[ALU_OP_WTH-1:0]              idu_ALU_opcode_o,
    output                              idu_ALU_src2_sel_o,
    output                              idu_is_lw_o,
    //from write back stage
    input                               idu_reg_we_i,
    input[WORD_WTH-1:0]                 idu_wdata_i,
    output[REG_INX_WTH-1:0]             idu_rd_inx_i,       
    //to exu
    output[WORD_WTH-1:0]                idu_rdata1_o,
    output[WORD_WTH-1:0]                idu_rdata2_o,
    output[WORD_WTH-1:0]                idu_imm_o,
    output[REG_INX_WTH-1:0]             idu_rd_inx_o,
    output[REG_INX_WTH-1:0]             idu_src1_inx_o,
    output[REG_INX_WTH-1:0]             idu_src2_inx_o,
    output[ADDR_WTH-1:0]                idu_pc_o,
    output[ADDR_WTH-1:0]                idu_pc_plus_4_o,
    //to Harzard unit
    output[REG_INX_WTH-1:0]             idu_src1_inx_har_o,
    output[REG_INX_WTH-1:0]             idu_src2_inx_har_o,
    //from Harzard unit
    input                               idu_flush_i
);

    //register declaration
    reg                     idu_jump_r;
    reg                     idu_RegW_EN_r;
    reg [WB_MUX_WTH-1:0]    idu_RegW_sel_r;
    reg                     idu_MemW_EN_r;
    reg                     idu_TakenAddr_sel_r;
    reg                     idu_auipc_sel_r;
    reg [ALU_OP_WTH-1:0]    idu_ALU_opcode_r;
    reg                     idu_ALU_src2_sel_r;
    reg                     idu_is_lw_r;
    reg [REG_INX_WTH-1:0]   idu_src1_inx_r;
    reg [REG_INX_WTH-1:0]   idu_src2_inx_r;
    reg [REG_INX_WTH-1:0]   idu_rd_inx_r;
    reg [WORD_WTH-1:0]      idu_imm_r;
    reg [WORD_WTH-1:0]      idu_rdata1_r;
    reg [WORD_WTH-1:0]      idu_rdata2_r;
    reg [ADDR_WTH-1:0]      idu_pc_r;
    reg [ADDR_WTH-1:0]      idu_pc_plus_4_r;

    wire                     idu_jump;
    wire                     idu_RegW_EN;
    wire [WB_MUX_WTH-1:0]    idu_RegW_sel;
    wire                     idu_MemW_EN;
    wire                     idu_TakenAddr_sel;
    wire                     idu_auipc_sel;
    wire [ALU_OP_WTH-1:0]    idu_ALU_opcode;
    wire                     idu_ALU_src2_sel;
    wire                     idu_is_lw;
    wire [REG_INX_WTH-1:0]   idu_src1_inx;
    wire [REG_INX_WTH-1:0]   idu_src2_inx;
    wire [REG_INX_WTH-1:0]   idu_rd_inx;
    wire [WORD_WTH-1:0]      idu_imm;
    wire [WORD_WTH-1:0]      idu_rdata1;
    wire [WORD_WTH-1:0]      idu_rdata2;
    wire [ADDR_WTH-1:0]      idu_pc;
    wire [ADDR_WTH-1:0]      idu_pc_plus_4;

    assign idu_pc = idu_pc_i;
    assign idu_pc_plus_4 = idu_pc_plus_4_i;

    RV32I_regfile RV32I_regfile_inst (
    .clk           (clk ),
    .rst           (rst ),
    .read_src1_idx (idu_src1_inx ),
    .read_src2_idx (idu_src2_inx ),
    .read_src1_dat (idu_rdata1 ),
    .read_src2_dat (idu_rdata2 ),
    .wbck_dest_wen (idu_reg_we_i ),
    .wbck_dest_idx (idu_rd_inx_i ),
    .wbck_dest_dat (idu_wdata_i )
    );


    RV32I_idu_dec RV32I_idu_dec_inst (
      .idu_instr_i (idu_instr_i ),
      .idu_jump_o (idu_jump ),
      .idu_RegW_EN_o (idu_RegW_EN ),
      .idu_RegW_sel_o (idu_RegW_sel ),
      .idu_MemW_EN_o (idu_MemW_EN ),
      .idu_TakenAddr_sel_o (idu_TakenAddr_sel ),
      .idu_auipc_sel_o(idu_auipc_sel),
      .idu_ALU_opcode_o (idu_ALU_opcode ),
      .idu_ALU_src2_sel_o (idu_ALU_src2_sel ),
      .idu_is_lw_o(idu_is_lw),
      .idu_src1_inx_o (idu_src1_inx ),
      .idu_src2_inx_o (idu_src2_inx ),
      .idu_rd_inx_o (idu_rd_inx ),
      .idu_imm_o  ( idu_imm)
    );
  
    always @(posedge clk) begin
        if(rst) begin
            idu_jump_r              <= 1'b0;
            idu_RegW_EN_r           <= 1'b0;
            idu_RegW_sel_r          <= {WB_MUX_WTH{1'b0}};
            idu_MemW_EN_r           <= 1'b0;
            idu_TakenAddr_sel_r     <= 1'b0;
            idu_auipc_sel_r         <= 1'b0;
            idu_ALU_opcode_r        <= {ALU_OP_WTH{1'b0}};
            idu_ALU_src2_sel_r      <= 1'b0;
            idu_is_lw_r             <= 1'b0;
            idu_src1_inx_r          <= {REG_INX_WTH{1'b0}};
            idu_src2_inx_r          <= {REG_INX_WTH{1'b0}};
            idu_rd_inx_r            <= {REG_INX_WTH{1'b0}};
            idu_imm_r               <= {WORD_WTH{1'b0}};
            idu_rdata1_r            <= {WORD_WTH{1'b0}};
            idu_rdata2_r            <= {WORD_WTH{1'b0}};
            idu_pc_r                <= {ADDR_WTH{1'b0}};
            idu_pc_plus_4_r         <= {ADDR_WTH{1'b0}};
        end
        else if(idu_flush_i) begin
            idu_jump_r              <= 1'b0;
            idu_RegW_EN_r           <= 1'b0;
            idu_RegW_sel_r          <= {WB_MUX_WTH{1'b0}};
            idu_MemW_EN_r           <= 1'b0;
            idu_TakenAddr_sel_r     <= 1'b0;
            idu_auipc_sel_r         <= 1'b0;
            idu_ALU_opcode_r        <= {ALU_OP_WTH{1'b0}};
            idu_ALU_src2_sel_r      <= 1'b0;
            idu_is_lw_r             <= 1'b0;
            idu_src1_inx_r          <= {REG_INX_WTH{1'b0}};
            idu_src2_inx_r          <= {REG_INX_WTH{1'b0}};
            idu_rd_inx_r            <= {REG_INX_WTH{1'b0}};
            idu_imm_r               <= {WORD_WTH{1'b0}};
            idu_rdata1_r            <= {WORD_WTH{1'b0}};
            idu_rdata2_r            <= {WORD_WTH{1'b0}};
            idu_pc_r                <= {ADDR_WTH{1'b0}};
            idu_pc_plus_4_r         <= {ADDR_WTH{1'b0}};
        end
        else begin
            idu_jump_r              <= idu_jump;
            idu_RegW_EN_r           <= idu_RegW_EN;
            idu_RegW_sel_r          <= idu_RegW_sel;
            idu_MemW_EN_r           <= idu_MemW_EN;
            idu_TakenAddr_sel_r     <= idu_TakenAddr_sel;
            idu_auipc_sel_r         <= idu_auipc_sel;
            idu_ALU_opcode_r        <= idu_ALU_opcode;
            idu_ALU_src2_sel_r      <= idu_ALU_src2_sel;
            idu_is_lw_r             <= idu_is_lw;
            idu_src1_inx_r          <= idu_src1_inx;
            idu_src2_inx_r          <= idu_src2_inx;
            idu_rd_inx_r            <= idu_rd_inx;
            idu_imm_r               <= idu_imm;
            idu_rdata1_r            <= idu_rdata1;
            idu_rdata2_r            <= idu_rdata2;
            idu_pc_r                <= idu_pc;
            idu_pc_plus_4_r         <= idu_pc_plus_4;
        end
    end

    assign idu_jump_o              = idu_jump_r;
    assign idu_RegW_EN_o           = idu_RegW_EN_r;
    assign idu_RegW_sel_o          = idu_RegW_sel_r;
    assign idu_MemW_EN_o           = idu_MemW_EN_r;
    assign idu_TakenAddr_sel_o     = idu_TakenAddr_sel_r;
    assign idu_auipc_sel_o         = idu_auipc_sel_r;
    assign idu_ALU_opcode_o        = idu_ALU_opcode_r;
    assign idu_ALU_src2_sel_o      = idu_ALU_src2_sel_r;
    assign idu_is_lw_o             = idu_is_lw_r;
    assign idu_src1_inx_o          = idu_src1_inx_r;
    assign idu_src2_inx_o          = idu_src2_inx_r;
    assign idu_rd_inx_o            = idu_rd_inx_r;
    assign idu_imm_o               = idu_imm_r;
    assign idu_rdata1_o            = idu_rdata1_r;
    assign idu_rdata2_o            = idu_rdata2_r;
    assign idu_pc_o                = idu_pc_r;
    assign idu_pc_plus_4_o         = idu_pc_plus_4_r;

    assign idu_src1_inx_har_o      = idu_src1_inx;
    assign idu_src2_inx_har_o      = idu_src2_inx;
    
endmodule //RV32I_idu