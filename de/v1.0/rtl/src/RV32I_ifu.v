//version:v1.0
//author:lsh
//date:2024.4.1
module RV32I_ifu #(
    parameter WORD_WTH = 32,
    parameter ADDR_WTH = 32
)(
    input                           clk,
    input                           rst,                //高有效复位
    input                           ifu_BranchTaken_i,
    input[ADDR_WTH-1:0]             ifu_TakenAddr_i,

    input[ADDR_WTH-1:0]             init_pc_i,
    
    //from hazard unit
    input                           ifu_stall_pc_i,
    input                           ifu_stall_i,
    input                           ifu_flush_i,
    //to instr decode unit
    output[ADDR_WTH-1:0]            ifu_current_pc_o,
    output[ADDR_WTH-1:0]            ifu_pc_plus_4_o,
    output[WORD_WTH-1:0]            ifu_instr_o,        

    //interface with ITCM
    output[ADDR_WTH-1:0]            ifu_itcm_addr_o,    //to ITCM
    input [WORD_WTH-1:0]            ifu_instr_i         //from ITCM
);

    reg [ADDR_WTH-1:0]     pc;
    reg [ADDR_WTH-1:0]     current_pc_r;
    reg [ADDR_WTH-1:0]     pc_plus_4_r;
    reg [WORD_WTH-1:0]     instr_r;

    wire [ADDR_WTH-1:0]    pc_plus_4;

    
    //generate pc
    assign pc_plus_4 = pc + 32'd4;

    always @(posedge clk) begin
        if(rst) begin
            pc <= init_pc_i;
        end
        else if(ifu_BranchTaken_i) begin
            pc <= ifu_TakenAddr_i;
        end
        else if(ifu_stall_pc_i) begin
            pc <= pc;
        end
        else begin
            pc <= pc_plus_4;
        end
    end

    //generate current pc
    always @(posedge clk) begin
        if(rst) begin
            current_pc_r <= {ADDR_WTH{1'b0}};
        end
        else if(ifu_flush_i) begin
            current_pc_r <= {ADDR_WTH{1'b0}};
        end
        else if(ifu_stall_i) begin
            current_pc_r <= current_pc_r;
        end
        else begin
            current_pc_r <= pc;
        end
    end

    //generate pc plus 4
    always @(posedge clk) begin
        if(rst) begin
            pc_plus_4_r <= {ADDR_WTH{1'b0}};
        end
        else if(ifu_flush_i) begin
            pc_plus_4_r <= {ADDR_WTH{1'b0}};
        end
        else if(ifu_stall_i) begin
            pc_plus_4_r <= pc_plus_4_r;
        end
        else begin
            pc_plus_4_r <= pc_plus_4;
        end
    end

    //generate instr
    always @(posedge clk) begin
        if(rst) begin
            instr_r <= {WORD_WTH{1'b0}};
        end
        else if(ifu_flush_i) begin
            instr_r <= {WORD_WTH{1'b0}};
        end
        else if(ifu_stall_i) begin
            instr_r <= instr_r;
        end
        else begin
            instr_r <= ifu_instr_i;
        end
    end

    //generate output signal
    assign ifu_current_pc_o = current_pc_r;
    assign ifu_pc_plus_4_o = pc_plus_4_r;
    assign ifu_itcm_addr_o = pc;
    assign ifu_instr_o = instr_r;

endmodule //RV32I_ifu