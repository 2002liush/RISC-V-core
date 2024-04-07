//version:v1.0
//author:lsh
//date:2024.4.1

module RV32I_hazard_unit #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter FORW_MUX_WTH    = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    //from dec stage 
    input [REG_INX_WTH-1:0]               dec_src1_inx_i,
    input [REG_INX_WTH-1:0]               dec_src2_inx_i,
    //from exu stage
    input [REG_INX_WTH-1:0]               exu_src1_inx_i,
    input [REG_INX_WTH-1:0]               exu_src2_inx_i,
    input                                 exu_is_lw_i,
    input [REG_INX_WTH-1:0]               exu_rd_inx_i,
    //from mem stage
    input [REG_INX_WTH-1:0]               mem_rd_inx_i,
    input                                 mem_RegW_EN_i,
    input                                 mem_br_taken_i,

    //from wb stage
    input [REG_INX_WTH-1:0]               wb_rd_inx_i,
    input                                 wb_RegW_EN_i,

    //stall and flush siganl
    output                                pc_stall_o,
    output                                dec_stall_o,
    output                                dec_flush_o,
    output                                exu_flush_o,
    output                                mem_flush_o,
    //to exu stage to select forward data from mem or wb stage
    output [FORW_MUX_WTH-1:0]             exu_src1_har_sel_o,
    output [FORW_MUX_WTH-1:0]             exu_src2_har_sel_o
);

    wire            mem_exu_src1_raw;
    wire            mem_exu_src2_raw;
    wire            mem_exu_raw_har;
    wire            wb_exu_src1_raw;
    wire            wb_exu_src2_raw;
    wire            wb_exu_raw_har;
    wire            exu_dec_src1_raw;
    wire            exu_dec_src2_raw;
    wire            dec_lw_stall;
    wire            exu_lw_flush;
    wire            pc_lw_stall;

    //raw hazard between exu and mem stage
    assign mem_exu_src1_raw = (exu_src1_inx_i == mem_rd_inx_i) && mem_RegW_EN_i && (exu_src1_inx_i!=5'b0);
    assign mem_exu_src2_raw = (exu_src2_inx_i == mem_rd_inx_i) && mem_RegW_EN_i && (exu_src2_inx_i!=5'b0);
    assign mem_exu_raw_har = mem_exu_src1_raw || mem_exu_src2_raw;
    //raw hazard between exu and wb stage
    assign wb_exu_src1_raw = (exu_src1_inx_i == wb_rd_inx_i) && wb_RegW_EN_i && (exu_src1_inx_i!=5'b0);
    assign wb_exu_src2_raw = (exu_src2_inx_i == wb_rd_inx_i) && wb_RegW_EN_i && (exu_src2_inx_i!=5'b0);
    assign wb_exu_raw_har = wb_exu_src1_raw || wb_exu_src2_raw;
    //exu_src1_har_sel_i = 00/01:regfile data1,11:mem_fd,10:wb_fd
    assign exu_src1_har_sel_o = mem_exu_src1_raw ? 2'b11 : 
                                wb_exu_src1_raw ? 2'b10 : 2'b00;

    assign exu_src2_har_sel_o = mem_exu_src2_raw ? 2'b11 : 
                                wb_exu_src2_raw ? 2'b10 : 2'b00;      

    //stall pc/stall D/flush exu when last instr is load word
    assign exu_dec_src1_raw = (dec_src1_inx_i == exu_rd_inx_i) && (exu_rd_inx_i != 5'b0);
    assign exu_dec_src2_raw = (dec_src2_inx_i == exu_rd_inx_i) && (exu_rd_inx_i != 5'b0);
    assign dec_lw_stall = exu_is_lw_i && (exu_dec_src1_raw || exu_dec_src2_raw);
    assign exu_lw_flush = dec_lw_stall;
    assign pc_lw_stall = dec_lw_stall;

    //branch taken flush
    assign pc_stall_o = mem_br_taken_i ? 1'b0 : pc_lw_stall;
    assign dec_stall_o = dec_lw_stall;
    assign dec_flush_o = mem_br_taken_i;
    assign exu_flush_o = exu_lw_flush || mem_br_taken_i;
    assign mem_flush_o = mem_br_taken_i;

    

endmodule //RV32I_hazard_unit