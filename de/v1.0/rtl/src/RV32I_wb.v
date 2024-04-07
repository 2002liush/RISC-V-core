//version:v1.0
//author:lsh
//date:2024.4.1
module RV32I_wb #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter FORW_MUX_WTH    = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    input                       clk,
    input                       rst,
    //from mem stage
    input                       wb_RegW_EN_i,
    input [WB_MUX_WTH-1:0]      wb_RegW_sel_i,
    input [WORD_WTH-1:0]        wb_reg_wdata1_i,
    input [WORD_WTH-1:0]        wb_reg_wdata2_i,
    input [REG_INX_WTH-1:0]     wb_rd_inx_i,

    //to hazard unit
    output                      wb_RegW_EN_har_o,
    output[REG_INX_WTH-1:0]     wb_rd_inx_har_o,
    //to exu stage
    output[WORD_WTH-1:0]        wb_exu_fd,
    //to dec stage
    output[WORD_WTH-1:0]        wb_RegW_data_o,
    output                      wb_RegW_EN_o,
    output[REG_INX_WTH-1:0]     wb_rd_inx_o
);

    assign wb_RegW_data_o = (wb_RegW_sel_i == 2'b01) ? wb_reg_wdata1_i : wb_reg_wdata2_i;
    assign wb_exu_fd = wb_RegW_data_o;
    assign wb_RegW_EN_har_o = wb_RegW_EN_i;
    assign wb_RegW_EN_o = wb_RegW_EN_i;
    assign wb_rd_inx_har_o = wb_rd_inx_i;
    assign wb_rd_inx_o = wb_rd_inx_i;
endmodule //RV32I_wb