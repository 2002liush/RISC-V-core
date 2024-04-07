//version:v1.0
//author:lsh
//date:2024.4.1

`include "RV32I_defines.v"
module cpu_top #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter MEM_ADDR_WTH    = 16,
    parameter MASK_WTH        = 4
)(
    input                                   clk,
    input                                   rst,
    input [ADDR_WTH-1:0]                    init_pc,
    //external interface with itcm
    input            					              ext_itcm_ram_cs  ,
    input  [MEM_ADDR_WTH-1:0]    			      ext_itcm_ram_addr,
    input  [MASK_WTH-1:0]                   ext_itcm_ram_wen ,
    input  [WORD_WTH-1:0]                   ext_itcm_ram_wdata ,
    output [WORD_WTH-1:0]                   ext_itcm_ram_rdata,
    output            					            ext_itcm_ready,
    //external interface with dtcm
    input            					              ext_dtcm_ram_cs  ,
    input  [MEM_ADDR_WTH-1:0]    			      ext_dtcm_ram_addr,
    input  [MASK_WTH-1:0]                   ext_dtcm_ram_wen ,
    input  [WORD_WTH-1:0]                   ext_dtcm_ram_wdata ,
    output [WORD_WTH-1:0]                   ext_dtcm_ram_rdata,
    output            					            ext_dtcm_ready,
    //data bus
    output                                  bus_we,
    output [ADDR_WTH-1:0]                   bus_addr,
    input  [WORD_WTH-1:0]                   bus_rdata,
    output [WORD_WTH-1:0]                   bus_wdata
);

    wire [MASK_WTH-1:0]                     itcm_wen;
    wire [MEM_ADDR_WTH-1:0]                 itcm_addr;
    wire [WORD_WTH-1:0]                     itcm_wdata;
    wire [WORD_WTH-1:0]                     itcm_rdata;

    wire [MASK_WTH-1:0]                     dtcm_wen;
    wire [MEM_ADDR_WTH-1:0]                 dtcm_addr;
    wire [WORD_WTH-1:0]                     dtcm_wdata;
    wire [WORD_WTH-1:0]                     dtcm_rdata;

    wire                                    cpu_itcm_we;
    wire [ADDR_WTH-1:0]                     cpu_itcm_addr;
    wire [WORD_WTH-1:0]                     cpu_itcm_rdata;
    wire [WORD_WTH-1:0]                     cpu_itcm_wdata;
    wire                                    cpu_dtcm_we;
    wire [ADDR_WTH-1:0]                     cpu_dtcm_addr;
    wire [WORD_WTH-1:0]                     cpu_dtcm_rdata;
    wire [WORD_WTH-1:0]                     cpu_dtcm_wdata;

    wire                                    is_dtcm_domain;
    wire                                    is_bus_domain;

    assign cpu_itcm_wdata = {WORD_WTH{1'b0}}; //not allow cpu to write data to itcm
    assign is_dtcm_domain = (cpu_dtcm_addr >> 16) == (`DTCM_START >> 16);
    assign is_bus_domain  = (cpu_dtcm_addr >> 16) == (`BUS_START  >> 16);


    assign itcm_wen = ext_itcm_ram_cs ? ext_itcm_ram_wen : {4{cpu_itcm_we}};
    assign itcm_addr = ext_itcm_ram_cs ? ext_itcm_ram_addr : cpu_itcm_addr[MEM_ADDR_WTH-1:0];
    assign itcm_wdata = ext_itcm_ram_cs ? ext_itcm_ram_wdata : cpu_itcm_wdata;

    assign dtcm_wen = ext_dtcm_ram_cs ? ext_dtcm_ram_wen : is_dtcm_domain ? {4{cpu_dtcm_we}} : {MASK_WTH{1'b0}};
    assign dtcm_addr = ext_dtcm_ram_cs ? ext_dtcm_ram_addr : is_dtcm_domain ? cpu_dtcm_addr[MEM_ADDR_WTH-1:0] : {ADDR_WTH{1'b0}};
    assign dtcm_wdata = ext_dtcm_ram_cs ? ext_dtcm_ram_wdata : is_dtcm_domain ? cpu_dtcm_wdata : {WORD_WTH{1'b0}};

    assign bus_we = is_bus_domain;
    assign bus_addr = is_bus_domain ? cpu_dtcm_addr : {ADDR_WTH{1'b0}};
    assign bus_wdata = is_bus_domain ? cpu_dtcm_wdata : {WORD_WTH{1'b0}};

    assign cpu_itcm_rdata = itcm_rdata;
    assign cpu_dtcm_rdata = is_dtcm_domain ? dtcm_rdata : is_bus_domain ? bus_rdata : {WORD_WTH{1'b0}};

    assign ext_dtcm_ready = 1'b1;
    assign ext_itcm_ready = 1'b1;

    
    RV32I_top RV32I_top_inst (
    .clk (clk ),
    .rst (rst ),
    .init_pc (init_pc ),
    .itcm_addr (cpu_itcm_addr ),
    .itcm_we (cpu_itcm_we ), // cpu_itcm_we = 1'b0
    .itcm_rdata (cpu_itcm_rdata ),
    .dtcm_addr (cpu_dtcm_addr ),
    .dtcm_we (cpu_dtcm_we ),
    .dtcm_wdata (cpu_dtcm_wdata ),
    .dtcm_rdata  ( cpu_dtcm_rdata)
    );

    //DTCM instacne 
    RV32I_dtcm RV32I_dtcm_inst (
      .clk (clk ),
      .wen (dtcm_wen ),
      .addr (dtcm_addr ),   
      .wdata (dtcm_wdata ),
      .rdata  ( dtcm_rdata)
    );  

    //ITCM instance
    RV32I_itcm RV32I_itcm_inst (
      .clk (clk ),
      .wen (itcm_wen ),
      .addr (itcm_addr ),
      .wdata (itcm_wdata ),
      .rdata  ( itcm_rdata)
    );
  

endmodule //cpu_top