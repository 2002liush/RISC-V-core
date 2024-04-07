//version:v1.0
//author:lsh
//date:2024.4.1
module RV32I_regfile #(
    parameter WORD_WTH        = 32,
    parameter REG_INX_WTH     = 5,
    parameter REG_NUM         = 32
)(
    input  clk,
    input  rst,

    input  [REG_INX_WTH-1:0]        read_src1_idx,
    input  [REG_INX_WTH-1:0]        read_src2_idx,
    output [WORD_WTH-1:0]           read_src1_dat,
    output [WORD_WTH-1:0]           read_src2_dat,
  
    input                           wbck_dest_wen,
    input  [REG_INX_WTH-1:0]        wbck_dest_idx,
    input  [WORD_WTH-1:0]           wbck_dest_dat
);

  wire [WORD_WTH-1:0] rf_r [REG_NUM-1:0];
  wire [REG_NUM-1:0] rf_wen;
  
  genvar i;
  generate //{
  
      for (i=0; i<REG_NUM; i=i+1) begin:regfile//{
  
        if(i==0) begin: rf0
            // x0 cannot be wrote since it is constant-zeros
            assign rf_wen[i] = 1'b0;
            assign rf_r[i] = {WORD_WTH{1'b0}};
        end
        else begin: rfno0
            assign rf_wen[i] = wbck_dest_wen & (wbck_dest_idx == i) ;
            sirv_gnrl_dffl #(WORD_WTH) rf_dffl (rf_wen[i], wbck_dest_dat, rf_r[i], clk);
        end
  
      end//}
  endgenerate//}
  
  //if write index == read index, bypass the write data to the read data port directly
  assign read_src1_dat = (wbck_dest_wen & (read_src1_idx==wbck_dest_idx) & (read_src1_idx!={REG_INX_WTH{1'b0}})) ? wbck_dest_dat : rf_r[read_src1_idx];
  assign read_src2_dat = (wbck_dest_wen & (read_src2_idx==wbck_dest_idx) & (read_src2_idx!={REG_INX_WTH{1'b0}})) ? wbck_dest_dat : rf_r[read_src2_idx];
  

endmodule //RV32I_regfile