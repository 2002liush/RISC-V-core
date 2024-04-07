//version:v1.0
//author:lsh
//date:2024.4.1

module RV32I_top #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter FORW_MUX_WTH    = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    input                       clk,
    input                       rst,
    input [ADDR_WTH-1:0]        init_pc,

    //interface with itcm
    output[ADDR_WTH-1:0]        itcm_addr,
    output                      itcm_we,
    input [WORD_WTH-1:0]        itcm_rdata,
    
    //interface with dtcm
    output[ADDR_WTH-1:0]        dtcm_addr,
    output                      dtcm_we,
    output[WORD_WTH-1:0]        dtcm_wdata,
    input [WORD_WTH-1:0]        dtcm_rdata
);

    wire [ADDR_WTH-1:0]             ifu_idu_pc;
    wire [ADDR_WTH-1:0]             ifu_idu_pc_plus_4;
    wire [WORD_WTH-1:0]             ifu_idu_instr;
    
    wire                            idu_exu_jump;
    wire                            idu_exu_RegW_EN;
    wire [WB_MUX_WTH-1:0]           idu_exu_RegW_sel;
    wire                            idu_exu_MemW_EN;
    wire                            idu_exu_TakenAddr_sel;
    wire                            idu_eux_auipc_sel;
    wire [ALU_OP_WTH-1:0]           idu_exu_ALU_opcode;
    wire                            idu_exu_ALU_src2_sel;
    wire                            idu_exu_is_lw;
    wire [WORD_WTH-1:0]             idu_exu_rdata1;
    wire [WORD_WTH-1:0]             idu_exu_rdata2;
    wire [WORD_WTH-1:0]             idu_exu_imm;
    wire [REG_INX_WTH-1:0]          idu_exu_rd_inx;
    wire [REG_INX_WTH-1:0]          idu_exu_src1_inx;
    wire [REG_INX_WTH-1:0]          idu_exu_src2_inx;
    wire [ADDR_WTH-1:0]             idu_exu_pc;
    wire [ADDR_WTH-1:0]             idu_exu_pc_plus_4;
    wire [REG_INX_WTH-1:0]          idu_har_src1_inx;
    wire [REG_INX_WTH-1:0]          idu_har_src2_inx;
    

    wire [WORD_WTH-1:0]             exu_mem_alu_res;
    wire [WORD_WTH-1:0]             exu_mem_imm;
    wire [ADDR_WTH-1:0]             exu_mem_pc_plus_imm;
    wire [ADDR_WTH-1:0]             exu_mem_pc_plus_4;
    wire [WORD_WTH-1:0]             exu_mem_rdata2;
    wire [REG_INX_WTH-1:0]          exu_mem_rd_inx;
    wire                            exu_mem_br_taken;
    wire                            exu_mem_RegW_EN;
    wire [WB_MUX_WTH-1:0]           exu_mem_RegW_sel;
    wire                            exu_mem_MemW_EN;
    wire                            exu_mem_TakenAddr_sel;
    wire                            exu_mem_auipc_sel;
    wire                            exu_har_is_lw;
    wire [REG_INX_WTH-1:0]          exu_har_src1_inx;
    wire [REG_INX_WTH-1:0]          exu_har_src2_inx;  
    wire [REG_INX_WTH-1:0]          exu_har_rd_inx;                                     
        
    wire                            mem_wb_RegW_EN;
    wire [WB_MUX_WTH-1:0]           mem_wb_RegW_sel;
    wire [WORD_WTH-1:0]             mem_wb_reg_wdata1;
    wire [WORD_WTH-1:0]             mem_wb_reg_wdata2;
    wire [REG_INX_WTH-1:0]          mem_wb_rd_inx;
    wire                            mem_har_RegW_EN;
    wire [REG_INX_WTH-1:0]          mem_har_rd_inx;
    wire                            mem_har_br_taken;
    wire [WORD_WTH-1:0]             mem_exu_fd;
    wire [ADDR_WTH-1:0]             mem_ifu_taken_addr;
    wire                            mem_ifu_br_taken;

    wire                            wb_har_RegW_EN;
    wire [REG_INX_WTH-1:0]          wb_har_rd_inx;
    wire [WORD_WTH-1:0]             wb_idu_wdata;
    wire [REG_INX_WTH-1:0]          wb_idu_rd_inx;
    wire                            wb_idu_reg_we;
    wire [WORD_WTH-1:0]             wb_exu_fd;

    wire                            har_ifu_stall_pc;
    wire                            har_ifu_stall;
    wire                            har_ifu_flush;
    wire                            har_idu_flush;
    wire                            har_exu_flush;
    wire [1:0]                      har_exu_src1_sel;
    wire [1:0]                      har_exu_src2_sel;

    assign itcm_we = 1'b0;

    RV32I_ifu RV32I_ifu_inst (
    .clk (clk ),
    .rst (rst ),
    .ifu_BranchTaken_i (mem_ifu_br_taken ),
    .ifu_TakenAddr_i (mem_ifu_taken_addr ),
    .init_pc_i (init_pc ),
    .ifu_stall_pc_i (har_ifu_stall_pc ),
    .ifu_stall_i (har_ifu_stall ),
    .ifu_flush_i (har_ifu_flush ),
    .ifu_current_pc_o (ifu_idu_pc ),
    .ifu_pc_plus_4_o (ifu_idu_pc_plus_4 ),
    .ifu_instr_o (ifu_idu_instr ),
    .ifu_itcm_addr_o (itcm_addr ),
    .ifu_instr_i  ( itcm_rdata)
    );


    RV32I_idu RV32I_idu_inst (
      .clk (clk ),
      .rst (rst ),
      .idu_instr_i (ifu_idu_instr ),
      .idu_pc_i (ifu_idu_pc ),
      .idu_pc_plus_4_i (ifu_idu_pc_plus_4 ),
      .idu_jump_o (idu_exu_jump ),
      .idu_RegW_EN_o (idu_exu_RegW_EN ),
      .idu_RegW_sel_o (idu_exu_RegW_sel ),
      .idu_MemW_EN_o (idu_exu_MemW_EN ),
      .idu_TakenAddr_sel_o (idu_exu_TakenAddr_sel ),
      .idu_auipc_sel_o (idu_eux_auipc_sel ),
      .idu_ALU_opcode_o (idu_exu_ALU_opcode ),
      .idu_ALU_src2_sel_o (idu_exu_ALU_src2_sel ),
      .idu_is_lw_o (idu_exu_is_lw ),
      .idu_reg_we_i (wb_idu_reg_we ),
      .idu_wdata_i (wb_idu_wdata ),
      .idu_rd_inx_i (wb_idu_rd_inx ),
      .idu_rdata1_o (idu_exu_rdata1 ),
      .idu_rdata2_o (idu_exu_rdata2 ),
      .idu_imm_o (idu_exu_imm ),
      .idu_rd_inx_o (idu_exu_rd_inx ),
      .idu_src1_inx_o (idu_exu_src1_inx ),
      .idu_src2_inx_o (idu_exu_src2_inx ),
      .idu_pc_o (idu_exu_pc),
      .idu_pc_plus_4_o(idu_exu_pc_plus_4),
      .idu_src1_inx_har_o (idu_har_src1_inx ),
      .idu_src2_inx_har_o (idu_har_src2_inx ),
      .idu_flush_i  ( har_idu_flush)
    );
    
    RV32I_exu RV32I_exu_inst (
      .clk (clk ),
      .rst (rst ),
      .exu_pc_i (idu_exu_pc ),
      .exu_pc_plus_4_i (idu_exu_pc_plus_4 ),
      .exu_jump_i (idu_exu_jump ),
      .exu_RegW_EN_i (idu_exu_RegW_EN ),
      .exu_RegW_sel_i (idu_exu_RegW_sel ),
      .exu_MemW_EN_i (idu_exu_MemW_EN ),
      .exu_TakenAddr_sel_i (idu_exu_TakenAddr_sel ),
      .exu_auipc_sel_i (idu_eux_auipc_sel ),
      .exu_ALU_opcode_i (idu_exu_ALU_opcode ),
      .exu_ALU_src2_sel_i (idu_exu_ALU_src2_sel ),
      .exu_is_lw_i (idu_exu_is_lw ),
      .exu_src1_inx_i (idu_exu_src1_inx ),
      .exu_src2_inx_i (idu_exu_src2_inx ),
      .exu_rd_inx_i (idu_exu_rd_inx ),
      .exu_rdata1_i (idu_exu_rdata1 ),
      .exu_rdata2_i (idu_exu_rdata2 ),
      .exu_imm_i (idu_exu_imm ),
      .exu_alu_res_o (exu_mem_alu_res ),
      .exu_imm_o (exu_mem_imm ),
      .exu_pc_plus_imm_o (exu_mem_pc_plus_imm ),
      .exu_pc_plus_4_o (exu_mem_pc_plus_4 ),
      .exu_rdata2_o (exu_mem_rdata2 ),
      .exu_rd_inx_o (exu_mem_rd_inx ),
      .exu_br_taken_o (exu_mem_br_taken ),
      .exu_RegW_EN_o (exu_mem_RegW_EN ),
      .exu_RegW_sel_o (exu_mem_RegW_sel ),
      .exu_MemW_EN_o (exu_mem_MemW_EN ),
      .exu_TakenAddr_sel_o (exu_mem_TakenAddr_sel ),
      .exu_auipc_sel_o (exu_mem_auipc_sel ),
      .exu_har_is_lw_o (exu_har_is_lw),
      .exu_src1_inx_har_o (exu_har_src1_inx ),
      .exu_src2_inx_har_o (exu_har_src2_inx ),
      .exu_har_rd_inx (exu_har_rd_inx),
      .exu_src1_har_sel_i (har_exu_src1_sel ),
      .exu_src2_har_sel_i (har_exu_src2_sel ),
      .exu_flush_i(har_exu_flush),
      .exu_mem_fd_i (mem_exu_fd ),
      .exu_wb_fd_i  (wb_exu_fd)
    );
    
    RV32I_mem RV32I_mem_inst (
      .clk (clk ),
      .rst (rst ),
      .mem_alu_res_i (exu_mem_alu_res ),
      .mem_imm_i (exu_mem_imm ),
      .mem_pc_plus_imm_i (exu_mem_pc_plus_imm ),
      .mem_pc_plus_4_i (exu_mem_pc_plus_4 ),
      .mem_rdata2_i (exu_mem_rdata2 ),
      .mem_rd_inx_i (exu_mem_rd_inx ),
      .mem_RegW_EN_i (exu_mem_RegW_EN ),
      .mem_RegW_sel_i (exu_mem_RegW_sel ),
      .mem_MemW_EN_i (exu_mem_MemW_EN ),
      .mem_TakenAddr_sel_i (exu_mem_TakenAddr_sel ),
      .mem_br_taken_i (exu_mem_br_taken ),
      .mem_auipc_sel_i (exu_mem_auipc_sel ),
      .mem_RegW_EN_o (mem_wb_RegW_EN ),
      .mem_RegW_sel_o (mem_wb_RegW_sel ),
      .mem_reg_wdata1_o (mem_wb_reg_wdata1 ),
      .mem_reg_wdata2_o (mem_wb_reg_wdata2 ),
      .mem_rd_inx_o (mem_wb_rd_inx ),
      .mem_RegW_EN_har_o (mem_har_RegW_EN ),
      .mem_rd_inx_har_o (mem_har_rd_inx ),
      .mem_br_taken_har_o (mem_har_br_taken ),
      .mem_fd_data_o (mem_exu_fd ),
      .mem_taken_addr_o (mem_ifu_taken_addr ),
      .mem_br_taken_o(mem_ifu_br_taken),
      .mem_dtcm_addr_o (dtcm_addr ),
      .mem_dtcm_wdata_o (dtcm_wdata ),
      .mem_dtcm_we_o (dtcm_we ),
      .mem_dtcm_rdata_i  ( dtcm_rdata)
    );
    
    RV32I_wb RV32I_wb_inst (
      .clk (clk ),
      .rst (rst ),
      .wb_RegW_EN_i (mem_wb_RegW_EN ),
      .wb_RegW_sel_i (mem_wb_RegW_sel ),
      .wb_reg_wdata1_i (mem_wb_reg_wdata1 ),
      .wb_reg_wdata2_i (mem_wb_reg_wdata2 ),
      .wb_rd_inx_i (mem_wb_rd_inx ),
      .wb_RegW_EN_har_o (wb_har_RegW_EN ),
      .wb_rd_inx_har_o (wb_har_rd_inx ),
      .wb_RegW_data_o (wb_idu_wdata ),
      .wb_RegW_EN_o(wb_idu_reg_we),
      .wb_rd_inx_o  ( wb_idu_rd_inx),
      .wb_exu_fd(wb_exu_fd)
    );
    
    RV32I_hazard_unit RV32I_hazard_unit_inst (
      .dec_src1_inx_i (idu_har_src1_inx ),
      .dec_src2_inx_i (idu_har_src2_inx ),
      .exu_src1_inx_i (exu_har_src1_inx ),
      .exu_src2_inx_i (exu_har_src2_inx ),
      .exu_is_lw_i (exu_har_is_lw ),
      .exu_rd_inx_i (exu_har_rd_inx ),
      .mem_rd_inx_i (mem_har_rd_inx ),
      .mem_RegW_EN_i (mem_har_RegW_EN ),
      .mem_br_taken_i (mem_har_br_taken ),
      .wb_rd_inx_i (wb_har_rd_inx ),
      .wb_RegW_EN_i (wb_har_RegW_EN ),
      .pc_stall_o (har_ifu_stall_pc ),
      .dec_stall_o (har_ifu_stall ),
      .dec_flush_o (har_ifu_flush ),
      .exu_flush_o (har_idu_flush ),
      .mem_flush_o (har_exu_flush ),
      .exu_src1_har_sel_o (har_exu_src1_sel ),
      .exu_src2_har_sel_o  ( har_exu_src2_sel)
    );



endmodule //RV32I_top