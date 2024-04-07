//version:v1.0
//author:lsh
//date:2024.4.1
module RV32I_exu #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter FORW_MUX_WTH    = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    input                               clk,
    input                               rst,
    //from idu
    input[ADDR_WTH-1:0]                 exu_pc_i,
    input[ADDR_WTH-1:0]                 exu_pc_plus_4_i,
    //control signals from idu stage
    input                               exu_jump_i,
    input                               exu_RegW_EN_i,
    input[WB_MUX_WTH-1:0]               exu_RegW_sel_i,
    input                               exu_MemW_EN_i,
    input                               exu_TakenAddr_sel_i,
    input                               exu_auipc_sel_i,
    input[ALU_OP_WTH-1:0]               exu_ALU_opcode_i,
    input                               exu_ALU_src2_sel_i,
    input                               exu_is_lw_i,
    input[REG_INX_WTH-1:0]              exu_src1_inx_i,
    input[REG_INX_WTH-1:0]              exu_src2_inx_i,
    input[REG_INX_WTH-1:0]              exu_rd_inx_i,

    input[WORD_WTH-1:0]                 exu_rdata1_i,
    input[WORD_WTH-1:0]                 exu_rdata2_i,
    input[WORD_WTH-1:0]                 exu_imm_i,
    //to mem stage
    output[WORD_WTH-1:0]                exu_alu_res_o,
    output[WORD_WTH-1:0]                exu_imm_o,
    output[ADDR_WTH-1:0]                exu_pc_plus_imm_o,
    output[ADDR_WTH-1:0]                exu_pc_plus_4_o,
    output[WORD_WTH-1:0]                exu_rdata2_o,
    output[REG_INX_WTH-1:0]             exu_rd_inx_o,

    output                              exu_br_taken_o,
    output                              exu_RegW_EN_o,
    output[WB_MUX_WTH-1:0]              exu_RegW_sel_o,
    output                              exu_MemW_EN_o,
    output                              exu_TakenAddr_sel_o,
    output                              exu_auipc_sel_o,
    
    //to Harzard unit
    output[REG_INX_WTH-1:0]             exu_src1_inx_har_o,
    output[REG_INX_WTH-1:0]             exu_src2_inx_har_o,
    output                              exu_har_is_lw_o,
    output[REG_INX_WTH-1:0]             exu_har_rd_inx,
    //from Harzard unit
    input [FORW_MUX_WTH-1:0]            exu_src1_har_sel_i,        
    input [FORW_MUX_WTH-1:0]            exu_src2_har_sel_i,
    input                               exu_flush_i,
    
    //from mem and wb stage
    input [WORD_WTH-1:0]                exu_mem_fd_i,//forward data from mem stage
    input [WORD_WTH-1:0]                exu_wb_fd_i
);

    wire[WORD_WTH-1:0]                  alu_src1;
    wire[WORD_WTH-1:0]                  alu_src2;
    wire[WORD_WTH-1:0]                  forward_data_1;
    wire[WORD_WTH-1:0]                  forward_data_2;
    wire[WORD_WTH-1:0]                  alu_res;
    wire                                alu_br_taken;
    wire                                br_taken;

    wire signed [ADDR_WTH-1:0]          pc;
    wire signed [ADDR_WTH-1:0]          imm;
    wire signed [ADDR_WTH-1:0]          pc_plus_imm;
    wire[ADDR_WTH-1:0]                  pc_plus_4;
    wire[REG_INX_WTH-1:0]               rd_inx;

    reg                                 exu_RegW_EN_r;
    reg [WB_MUX_WTH-1:0]                exu_RegW_sel_r;
    reg                                 exu_MemW_EN_r;
    reg                                 exu_TakenAddr_sel_r;
    reg                                 exu_auipc_sel_r;
    reg                                 exu_br_taken_r;
    reg [WORD_WTH-1:0]                  exu_imm_r;
    reg [WORD_WTH-1:0]                  exu_alu_res_r;
    reg [WORD_WTH-1:0]                  exu_rdata2_r;
    reg [REG_INX_WTH-1:0]               exu_rd_inx_r;
    reg [ADDR_WTH-1:0]                  exu_pc_plus_imm_r;
    reg [ADDR_WTH-1:0]                  exu_pc_plus_4_r;


    //exu_src1_har_sel_i = 00/01:regfile data1,11:mem_fd,10:wb_fd
    assign forward_data_1 = exu_src1_har_sel_i[0] ? exu_mem_fd_i : exu_wb_fd_i;
    assign alu_src1 = exu_src1_har_sel_i[1] ? forward_data_1 : exu_rdata1_i;
    //exu_src2_har_sel_i = 00/01:regfile data2,11:mem_fd,10:wb_fd
    assign forward_data_2 = exu_src2_har_sel_i[0] ? exu_mem_fd_i : exu_wb_fd_i;
    assign alu_src2 = exu_ALU_src2_sel_i ? exu_imm_i : (exu_src2_har_sel_i[1] ? forward_data_2 : exu_rdata2_i);
    
    assign pc = exu_pc_i;
    assign imm = exu_imm_i;
    assign pc_plus_4 = exu_pc_plus_4_i;
    assign pc_plus_imm = pc + imm;

    assign rd_inx = exu_rd_inx_i;

    assign br_taken = exu_jump_i || alu_br_taken;

    //alu inst
    RV32I_exu_alu RV32I_exu_alu_inst (
      .alu_data1_i (alu_src1 ),
      .alu_data2_i (alu_src2 ),
      .alu_opcode_i (exu_ALU_opcode_i ),
      .alu_res_o (alu_res ),
      .alu_br_taken_o  ( alu_br_taken)
    );
    
    always @(posedge clk) begin
        if(rst) begin
            exu_RegW_EN_r <= 1'b0;
            exu_RegW_sel_r <= {WB_MUX_WTH{1'b0}};
            exu_MemW_EN_r <= 1'b0;
            exu_TakenAddr_sel_r <= 1'b0;
            exu_auipc_sel_r <= 1'b0;
            exu_br_taken_r <= 1'b0;
            exu_imm_r <= {WORD_WTH{1'b0}};
            exu_alu_res_r <= {WORD_WTH{1'b0}};
            exu_rdata2_r <= {WORD_WTH{1'b0}};
            exu_rd_inx_r <= {REG_INX_WTH{1'b0}};
            exu_pc_plus_imm_r <= {ADDR_WTH{1'b0}};
            exu_pc_plus_4_r <= {ADDR_WTH{1'b0}};
        end
        else if(exu_flush_i) begin
            exu_RegW_EN_r <= 1'b0;
            exu_RegW_sel_r <= {WB_MUX_WTH{1'b0}};
            exu_MemW_EN_r <= 1'b0;
            exu_TakenAddr_sel_r <= 1'b0;
            exu_auipc_sel_r <= 1'b0;
            exu_br_taken_r <= 1'b0;
            exu_imm_r <= {WORD_WTH{1'b0}};
            exu_alu_res_r <= {WORD_WTH{1'b0}};
            exu_rdata2_r <= {WORD_WTH{1'b0}};
            exu_rd_inx_r <= {REG_INX_WTH{1'b0}};
            exu_pc_plus_imm_r <= {ADDR_WTH{1'b0}};
            exu_pc_plus_4_r <= {ADDR_WTH{1'b0}};
        end
        else begin
            exu_RegW_EN_r       <= exu_RegW_EN_i;
            exu_RegW_sel_r      <= exu_RegW_sel_i;
            exu_MemW_EN_r       <= exu_MemW_EN_i;
            exu_TakenAddr_sel_r <= exu_TakenAddr_sel_i;
            exu_auipc_sel_r     <= exu_auipc_sel_i;
            exu_br_taken_r      <= br_taken;
            exu_imm_r           <= imm;
            exu_alu_res_r       <= alu_res;
            exu_rdata2_r        <= exu_rdata2_i;
            exu_rd_inx_r        <= exu_rd_inx_i;
            exu_pc_plus_imm_r   <= pc_plus_imm;
            exu_pc_plus_4_r     <= pc_plus_4;
        end
    end

    //to mem stage
    //contorl signals
    assign exu_RegW_EN_o = exu_RegW_EN_r;
    assign exu_RegW_sel_o = exu_RegW_sel_r;
    assign exu_MemW_EN_o = exu_MemW_EN_r;
    assign exu_TakenAddr_sel_o = exu_TakenAddr_sel_r;
    assign exu_har_is_lw_o   = exu_is_lw_i;
    assign exu_auipc_sel_o = exu_auipc_sel_r;
    assign exu_br_taken_o = exu_br_taken_r;
    //data signals
    assign exu_alu_res_o = exu_alu_res_r;
    assign exu_imm_o = exu_imm_r;
    assign exu_pc_plus_imm_o = exu_pc_plus_imm_r;
    assign exu_pc_plus_4_o = exu_pc_plus_4_r;
    assign exu_rdata2_o = exu_rdata2_r;
    assign exu_rd_inx_o = exu_rd_inx_r;

    //to hazard unit
    assign exu_src1_inx_har_o = exu_src1_inx_i;
    assign exu_src2_inx_har_o = exu_src2_inx_i;
    assign exu_har_rd_inx = exu_rd_inx_i;

endmodule //RV32I_exu