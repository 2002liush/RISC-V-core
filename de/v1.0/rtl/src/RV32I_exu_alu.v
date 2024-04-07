//version:v1.0
//author:lsh
//date:2024.4.1

module RV32I_exu_alu #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter WB_MUX_WTH      = 2,
    parameter FORW_MUX_WTH    = 2,
    parameter REG_INX_WTH     = 5,
    parameter ALU_OP_WTH      = 5
)(
    input [WORD_WTH-1:0]        alu_data1_i,
    input [WORD_WTH-1:0]        alu_data2_i,

    input [ALU_OP_WTH-1:0]      alu_opcode_i,

    output[WORD_WTH-1:0]        alu_res_o,
    output                      alu_br_taken_o
);
    //ALU opcode
    localparam ADD        = 5'b00000;
    localparam SUB        = 5'b01000;
    localparam XOR        = 5'b00100;
    localparam OR         = 5'b00110;
    localparam AND        = 5'b00111;
    localparam SLL        = 5'b00001;
    localparam SRL        = 5'b00101;
    localparam SRA        = 5'b01101;
    localparam SLT        = 5'b00010;
    localparam SLTU       = 5'b00011;
    localparam BEQ        = 5'b10000;
    localparam BNE        = 5'b10001;
    localparam BLT        = 5'b10100;
    localparam BGE        = 5'b10101;
    localparam BLTU       = 5'b10110;
    localparam BGEU       = 5'b10111;

    wire signed [WORD_WTH-1:0]              data1;
    wire signed [WORD_WTH-1:0]              data2;
    wire [WORD_WTH-1:0]                     data1_u;
    wire [WORD_WTH-1:0]                     data2_u;

    wire signed [WORD_WTH-1:0]              add_res;
    wire signed [WORD_WTH-1:0]              sub_res;
    wire [WORD_WTH-1:0]                     xor_res;
    wire [WORD_WTH-1:0]                     or_res;
    wire [WORD_WTH-1:0]                     and_res;
    wire [WORD_WTH-1:0]                     sll_res;
    wire [WORD_WTH-1:0]                     srl_res;
    wire [WORD_WTH-1:0]                     sra_res;
    wire [WORD_WTH-1:0]                     slt_res;
    wire [WORD_WTH-1:0]                     sltu_res;
    wire                                    beq_res;
    wire                                    bne_res;
    wire                                    blt_res;
    wire                                    bge_res;
    wire                                    bltu_res;
    wire                                    bgeu_res;
    
    reg [WORD_WTH-1:0]                      dout;
    reg                                     br_taken;

    assign data1   = alu_data1_i;
    assign data2   = alu_data2_i;
    assign data1_u = alu_data1_i;
    assign data2_u = alu_data2_i;

    assign add_res = data1 + data2;
    assign sub_res = data1 + ~data2 + 1'b1;
    assign xor_res = data1 ^ data2;
    assign or_res  = data1 | data2;
    assign and_res = data1 & data2;
    assign sll_res = data1 <<  data2[4:0];
    assign srl_res = data1 >>  data2[4:0];
    assign sra_res = data1 >>> data2[4:0];
    assign slt_res = data1 < data2 ? 32'b1 : 32'b0;
    assign sltu_res = data1_u < data2_u ? 32'b1 : 32'b0;

    assign beq_res = data1 == data2 ? 1'b1 : 1'b0;
    assign bne_res = data1 != data2 ? 1'b1 : 1'b0;
    assign blt_res = data1 <  data2 ? 1'b1 : 1'b0;
    assign bge_res = data1 >= data2 ? 1'b1 : 1'b0;
    assign bltu_res = data1_u < data2_u ? 1'b1 : 1'b0;
    assign bgeu_res = data1_u >= data2_u ? 1'b1 : 1'b0;

    always @(*) begin
        case(alu_opcode_i[ALU_OP_WTH-1:0])
            ADD : begin    dout = add_res;   end
            SUB : begin    dout = sub_res;   end    
            XOR : begin    dout = xor_res;   end
            OR  : begin    dout = or_res;    end
            AND : begin    dout = and_res;   end
            SLL : begin    dout = sll_res;   end    
            SRL : begin    dout = srl_res;   end
            SRA : begin    dout = sra_res;   end
            SLT : begin    dout = slt_res;   end
            SLTU: begin    dout = sltu_res;  end    
            default : begin dout = {WORD_WTH{1'b0}}; end
        endcase
    end

    always @(*) begin
        case(alu_opcode_i[ALU_OP_WTH-1:0]) 
            BEQ : begin    br_taken = beq_res;    end
            BNE : begin    br_taken = bne_res;    end    
            BLT : begin    br_taken = blt_res;    end
            BGE : begin    br_taken = bge_res;    end
            BLTU: begin    br_taken = bltu_res;   end
            BGEU: begin    br_taken = bgeu_res;   end     
            default : begin br_taken = 1'b0; end
        endcase
    end

    assign alu_res_o = dout;
    assign alu_br_taken_o = br_taken;

endmodule //RV32I_exu_alu