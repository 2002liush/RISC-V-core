//version:v1.0
//author:lsh
//date:2024.4.1

module RV32I_mem  #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter FORW_MUX_WTH    = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    input                           clk,
    input                           rst,
    //from exu stage
    input [WORD_WTH-1:0]            mem_alu_res_i,
    input [WORD_WTH-1:0]            mem_imm_i,
    input [ADDR_WTH-1:0]            mem_pc_plus_imm_i,
    input [ADDR_WTH-1:0]            mem_pc_plus_4_i,
    input [WORD_WTH-1:0]            mem_rdata2_i,
    input [REG_INX_WTH-1:0]         mem_rd_inx_i,
    //control signals from exu stage
    input                           mem_RegW_EN_i,
    input [WB_MUX_WTH-1:0]          mem_RegW_sel_i,
    input                           mem_MemW_EN_i,
    input                           mem_TakenAddr_sel_i,
    input                           mem_br_taken_i,
    input                           mem_auipc_sel_i,
    //to wb stage
    output                          mem_RegW_EN_o,
    output [WB_MUX_WTH-1:0]         mem_RegW_sel_o,
    output [WORD_WTH-1:0]           mem_reg_wdata1_o,
    output [WORD_WTH-1:0]           mem_reg_wdata2_o,
    output [REG_INX_WTH-1:0]        mem_rd_inx_o,
    //to hazard unit
    output                          mem_RegW_EN_har_o,
    output [REG_INX_WTH-1:0]        mem_rd_inx_har_o, 
    output                          mem_br_taken_har_o,

    //forward data to exu stage 
    output [WORD_WTH-1:0]           mem_fd_data_o,
    //to ifu stage
    output [ADDR_WTH-1:0]           mem_taken_addr_o, 
    output                          mem_br_taken_o,
    //interface with DTCM
    output [ADDR_WTH-1:0]           mem_dtcm_addr_o,
    output [WORD_WTH-1:0]           mem_dtcm_wdata_o,
    output                          mem_dtcm_we_o,
    input  [WORD_WTH-1:0]           mem_dtcm_rdata_i
);
    reg [WORD_WTH-1:0]              mem_reg_wdata2_r;
    reg [WORD_WTH-1:0]              mem_reg_wdata1_r;
    reg [REG_INX_WTH-1:0]           mem_rd_inx_r;
    reg                             mem_RegW_EN_r;
    reg [WB_MUX_WTH-1:0]            mem_RegW_sel_r;

    wire [WORD_WTH-1:0]             wdata2;


    //mem_RegW_sel_i = 00 : auipc/lui, 01 : load, 10 : pc+4(jal), 11 : alu_res
    assign wdata2 = (mem_RegW_sel_i == 2'b00) ? (mem_auipc_sel_i ? mem_pc_plus_imm_i : mem_imm_i) : 
                    (mem_RegW_sel_i == 2'b10) ? mem_pc_plus_4_i : 
                    (mem_RegW_sel_i == 2'b11) ? mem_alu_res_i : {WORD_WTH{1'b0}};

    assign mem_fd_data_o = wdata2;
    assign mem_taken_addr_o = mem_TakenAddr_sel_i ? mem_pc_plus_imm_i : mem_alu_res_i;
    assign mem_rd_inx_har_o = mem_rd_inx_i;
    assign mem_RegW_EN_har_o = mem_RegW_EN_i;
    assign mem_dtcm_addr_o = mem_alu_res_i;
    assign mem_dtcm_wdata_o = mem_rdata2_i;
    assign mem_dtcm_we_o = mem_MemW_EN_i;
    
    always @(posedge clk) begin
        if(rst) begin
            mem_reg_wdata1_r <= {WORD_WTH{1'b0}};
            mem_reg_wdata2_r <= {WORD_WTH{1'b0}};
            mem_rd_inx_r <= {REG_INX_WTH{1'b0}};
            mem_RegW_EN_r <= 1'b0;
            mem_RegW_sel_r <= {WB_MUX_WTH{1'b0}};
        end
        else begin
            mem_reg_wdata1_r <= mem_dtcm_rdata_i;
            mem_reg_wdata2_r <= wdata2;
            mem_rd_inx_r <= mem_rd_inx_i;
            mem_RegW_EN_r <= mem_RegW_EN_i;
            mem_RegW_sel_r <= mem_RegW_sel_i;
        end
    end

    assign mem_RegW_EN_o = mem_RegW_EN_r;
    assign mem_RegW_sel_o = mem_RegW_sel_r;
    assign mem_reg_wdata1_o = mem_reg_wdata1_r;
    assign mem_reg_wdata2_o = mem_reg_wdata2_r;
    assign mem_rd_inx_o = mem_rd_inx_r;
    assign mem_br_taken_har_o = mem_br_taken_i;

    assign mem_br_taken_o = mem_br_taken_i;

endmodule //RV32I_mem