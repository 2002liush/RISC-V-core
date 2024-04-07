// // ---------------------------------------------------------------------------------------------------------------------
// // Copyright (c) 1986-2022, CAG(Cognitive Architecture Group), Institute of AI and Robotics, Xi'an Jiaotong University.
// // Proprietary and Confidential All Rights Reserved.
// // ---------------------------------------------------------------------------------------------------------------------
// // NOTICE: All information contained herein is, and remains the property of CAG, Institute of AI and Robotics,  Xi'an
// // Jiaotong University. The intellectual and technical concepts contained herein are proprietary to CAG team, and may be
// // covered by P.R.C. and Foreign Patents, patents in process, and are protected by trade secret or copyright law.
// //
// // This work may not be copied, modified, re-published, uploaded, executed, or distributed in any way, in any time, in
// // any medium, whether in whole or in part, without prior written permission from CAG, Institute of AI and Robotics,
// // Xi'an Jiaotong University.
// //
// // The copyright notice above does not evidence any actual or intended publication or disclosure of this source code,
// // which includes information that is confidential and/or proprietary, and is a trade secret of CAG.
// // ---------------------------------------------------------------------------------------------------------------------
// // FILE NAME  : tb_pure_swf.sv
// // DEPARTMENT : Cognitive Architecture Group
// // AUTHOR     : lsh
// // AUTHOR'S EMAIL : 
// // ---------------------------------------------------------------------------------------------------------------------
// // Ver 2.0  2022-01-01 initial version.
// // ---------------------------------------------------------------------------------------------------------------------

module tb_cpu;
    // Parameters
    localparam  WORD_WTH = 32;
    localparam  ADDR_WTH = 32;
    localparam  MEM_ADDR_WTH = 16;
    localparam  MASK_WTH = 4;

    // Ports
    reg                             clk = 0;
    reg                             rst = 0;
    reg[7:0]                        tmp_itcm[16384-1:0]; //16KB
    reg[7:0]                        tmp_dtcm[16384-1:0];
    reg [ADDR_WTH-1:0]              init_pc;
    reg                             ext_itcm_ram_cs = 0;
    reg [MEM_ADDR_WTH-1:0]          ext_itcm_ram_addr;
    reg [MASK_WTH-1:0]              ext_itcm_ram_wen;
    reg [WORD_WTH-1:0]              ext_itcm_ram_wdata;
    wire [WORD_WTH-1:0]             ext_itcm_ram_rdata;
    wire                            ext_itcm_ready;
    reg                             ext_dtcm_ram_cs = 0;
    reg [MEM_ADDR_WTH-1:0]          ext_dtcm_ram_addr;
    reg [MASK_WTH-1:0]              ext_dtcm_ram_wen;
    reg [WORD_WTH-1:0]              ext_dtcm_ram_wdata;
    wire [WORD_WTH-1:0]             ext_dtcm_ram_rdata;
    wire                            ext_dtcm_ready;
    wire                            bus_we;
    wire [ADDR_WTH-1:0]             bus_addr;
    reg [WORD_WTH-1:0]              bus_rdata = 32'b0;
    wire [WORD_WTH-1:0]             bus_wdata;

    reg [MEM_ADDR_WTH-1:0]          addr;  

    cpu_top cpu_top_inst (
        .clk (clk ),
        .rst (rst ),
        .init_pc (init_pc ),
        .ext_itcm_ram_cs (ext_itcm_ram_cs ),
        .ext_itcm_ram_addr (ext_itcm_ram_addr ),
        .ext_itcm_ram_wen (ext_itcm_ram_wen ),
        .ext_itcm_ram_wdata (ext_itcm_ram_wdata ),
        .ext_itcm_ram_rdata (ext_itcm_ram_rdata ),
        .ext_itcm_ready (ext_itcm_ready ),
        .ext_dtcm_ram_cs (ext_dtcm_ram_cs ),
        .ext_dtcm_ram_addr (ext_dtcm_ram_addr ),
        .ext_dtcm_ram_wen (ext_dtcm_ram_wen ),
        .ext_dtcm_ram_wdata (ext_dtcm_ram_wdata ),
        .ext_dtcm_ram_rdata (ext_dtcm_ram_rdata ),
        .ext_dtcm_ready (ext_dtcm_ready ),
        .bus_we (bus_we ),
        .bus_addr (bus_addr ),
        .bus_rdata (bus_rdata ),
        .bus_wdata  ( bus_wdata)
    );

    // clock generation
    initial begin
        clk = 1'b0;
        #1;
        forever begin
            #2 clk <= !clk; // 500MHz
        end
    end

    // // Initialize code and data sections

    
    initial begin:test
        reg [31:0]  i;
        rst = 1'b0;
        #30;
        rst = 1'b1;
        // config the ITCM data
        $readmemh("itcm.dat", tmp_itcm, 0, 16383); // 16KB
        addr = 16'h0000;
        ext_itcm_ram_cs = 1'b1;
        ext_itcm_ram_wen = 4'hf;
        for( i=0; i<4096; i=i+1) begin
            //itcm_wr_word(addr, {tmp_itcm[i*4+3],tmp_itcm[i*4+2],tmp_itcm[i*4+1],tmp_itcm[i*4+0]});
            ext_itcm_ram_addr <= addr;
            ext_itcm_ram_wdata<= {tmp_itcm[i*4+3],tmp_itcm[i*4+2],tmp_itcm[i*4+1],tmp_itcm[i*4+0]};
            @(posedge clk);
            addr = addr + 4;
        end
        ext_itcm_ram_cs = 1'b0;
        ext_itcm_ram_wen = 4'h0;
        // config the DTCM data
        $readmemh("dtcm.dat", tmp_dtcm, 0, 16383); // 16KB
        addr = 16'h0000;
        ext_dtcm_ram_cs = 1'b1;
        ext_dtcm_ram_wen = 4'hf;
        for( i=0; i<4096; i=i+1) begin
            //itcm_wr_word(addr, {tmp_itcm[i*4+3],tmp_itcm[i*4+2],tmp_itcm[i*4+1],tmp_itcm[i*4+0]});
            ext_dtcm_ram_addr <= addr;
            ext_dtcm_ram_wdata<= {tmp_dtcm[i*4+3],tmp_dtcm[i*4+2],tmp_dtcm[i*4+1],tmp_dtcm[i*4+0]};
            @(posedge clk);
            addr = addr + 4;
        end
        ext_dtcm_ram_cs = 1'b0;
        ext_dtcm_ram_wen = 4'h0;
        
        // Start to run
        # 30 rst = 1'b0;
    end

    initial begin
        $fsdbDumpfile("tb_cpu.fsdb");
        $fsdbDumpvars(0, tb_cpu, "+mda", "+all");
        //$vcdplusmemon();
    end

endmodule
