//version:v1.0
//author:lsh
//date:2024.4.1

module RV32I_itcm #(
    parameter WORD_WIDTH = 32,
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 8,
	parameter MASK_WIDTH = 4,
	parameter RAM_SIZE   = 1024*64 // 64KB
)(
	input clk,
	input  [MASK_WIDTH-1 :0] wen,
	input  [ADDR_WIDTH-1 :0] addr,
	input  [WORD_WIDTH-1 :0] wdata,
	output [WORD_WIDTH-1 :0] rdata
);
    //wire [WORD_WIDTH-1 :0]  ram_din;
    wire [ADDR_WIDTH-3 :0]  ram_addr;
    //wire [WORD_WIDTH-1 :0]  ram_dout;
    wire                    ram_we;
    //wire [MASK_WIDTH-1 :0]  ram_wem;
    wire                    cs;

    assign ram_addr = addr[ADDR_WIDTH-1 :2];
    assign ram_we = wen[0];
    assign cs = 1'b1;
    
    sirv_sim_ram #(
        .DP(RAM_SIZE/4), // this is word size
        .FORCE_X2ZERO(0),
        .DW(WORD_WIDTH), // r/w data by word
        .MW(MASK_WIDTH),
        .AW(ADDR_WIDTH-2)
    ) ram_block(
        .clk(clk),
        .din(wdata),
        .addr(ram_addr),
        .cs(cs),
        .we(ram_we),
        .wem(wen),
        .dout(rdata)
    );
endmodule //RV32I_dtcm