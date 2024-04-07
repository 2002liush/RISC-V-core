//version:v1.0
//author:lsh
//date:2024.4.1
module RV32I_idu_dec #(
    parameter WORD_WTH        = 32,
    parameter ADDR_WTH        = 32,
    parameter ALU_OP_WTH      = 5,  
    parameter WB_MUX_WTH      = 2,
    parameter REG_INX_WTH     = 5,
    parameter RS1_INX         = 15,
    parameter RS2_INX         = 20,
    parameter RD_INX          = 7,
    parameter OPCODE_INX      = 0,
    parameter OPCODE_WTH      = 7,
    parameter FUNCT3_INX      = 12,
    parameter FUNCT3_WTH      = 3,
    parameter FUNCT7_INX      = 25, 
    parameter FUNCT7_WTH      = 7
)(
    //from ifu
    input[WORD_WTH-1:0]                 idu_instr_i,

    //control signal
    output                              idu_jump_o,
    output                              idu_RegW_EN_o,
    output[WB_MUX_WTH-1:0]              idu_RegW_sel_o,
    output                              idu_MemW_EN_o,
    output                              idu_TakenAddr_sel_o,
    output                              idu_auipc_sel_o,
    output[ALU_OP_WTH-1:0]              idu_ALU_opcode_o,
    output                              idu_ALU_src2_sel_o,
    output                              idu_is_lw_o,

    //other signal
    output[REG_INX_WTH-1:0]             idu_src1_inx_o,
    output[REG_INX_WTH-1:0]             idu_src2_inx_o,
    output[REG_INX_WTH-1:0]             idu_rd_inx_o,
    output[WORD_WTH-1:0]                idu_imm_o
);

    localparam COMPU_R_OP = 7'b0110011;  //R-type compute instr opcode
    localparam COMPU_I_OP = 7'b0010011;
    localparam LOAD_OP    = 7'b0000011;
    localparam STORE_OP   = 7'b0100011;
    localparam BRANCH_OP  = 7'b1100011;
    localparam JAL_OP     = 7'b1101111;
    localparam JALR_OP    = 7'b1100111;
    localparam LUI_OP     = 7'b0110111;
    localparam AUIPC_OP   = 7'b0010111;
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

    wire                                jump;
    wire                                RegW_en;
    wire[WB_MUX_WTH-1:0]                RegW_sel;
    wire                                MemW_en;
    wire                                TakenAddr_sel;
    wire                                auipc_sel;
    wire[ALU_OP_WTH-1:0]                ALU_op;
    wire                                ALU_src2_sel;

    wire [WORD_WTH-1:0]                 instr;
    wire [REG_INX_WTH-1:0]              rs1_inx;
    wire [REG_INX_WTH-1:0]              rs2_inx;
    wire [REG_INX_WTH-1:0]              rd_inx;
    wire [OPCODE_WTH-1:0]               opcode;
    wire [FUNCT3_WTH-1:0]               funct3;
    wire [FUNCT7_WTH-1:0]               funct7;
    wire [FUNCT7_WTH-1:0]               I_type_op; 
    wire signed [WORD_WTH-1:0]          imm;
    wire signed [WORD_WTH-1:0]          imm_I;//I_type
    wire signed [WORD_WTH-1:0]          imm_S;
    wire signed [WORD_WTH-1:0]          imm_B;
    wire signed [WORD_WTH-1:0]          imm_U;
    wire signed [WORD_WTH-1:0]          imm_J;

    assign instr = idu_instr_i;


    assign rs1_inx = instr[RS1_INX+REG_INX_WTH-1:RS1_INX];
    assign rs2_inx = instr[RS2_INX+REG_INX_WTH-1:RS2_INX];
    assign rd_inx  = instr[RD_INX+REG_INX_WTH-1:RD_INX];
    assign opcode  = instr[OPCODE_INX+OPCODE_WTH-1:OPCODE_INX];
    assign funct3  = instr[FUNCT3_INX+FUNCT3_WTH-1:FUNCT3_INX];
    assign funct7  = instr[FUNCT7_INX+FUNCT7_WTH-1:FUNCT7_INX];
    assign I_type_op  = (funct3 == 3'b101) ? instr[31:25] : 7'b0;

    assign imm_I[31:1]   = {{20{instr[31]}},instr[31:21]};  //compute instr
    assign imm_I[0] = (opcode==JALR_OP) ? 1'b0 : instr[20]; //jalr

    assign imm_S   = {{20{instr[31]}},instr[31:25],instr[11:7]};  //store
    assign imm_B   = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};//branch

    assign imm_U   = {instr[31:12],12'b0};//lui, auipc
    assign imm_J   = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};    //jal


    assign imm = (opcode == COMPU_I_OP) ? imm_I : 
                 (opcode == STORE_OP)   ? imm_S : 
                 (opcode == BRANCH_OP)  ? imm_B :
                 ((opcode == LUI_OP) || opcode == (AUIPC_OP)) ? imm_U : 
                 (opcode == JAL_OP) ? imm_J : {WORD_WTH{1'b0}};


    assign jump = ((opcode == JAL_OP) || (opcode == JALR_OP)) ? 1'b1 : 1'b0;
    assign RegW_en = ((opcode == STORE_OP) || (opcode == BRANCH_OP)) ? 1'b0 : 1'b1;
    assign RegW_sel = ((opcode == AUIPC_OP) || (opcode == LUI_OP)) ? 2'b00 :    
                      (opcode == LOAD_OP) ? 2'b01 : 
                      (opcode == JAL_OP) ? 2'b10 : 2'b11;
    assign MemW_en = (opcode == STORE_OP) ? 1'b1 : 1'b0;
    assign TakenAddr_sel = (opcode == JALR_OP) ? 1'b0 : 1'b1;
    assign auipc_sel = opcode == AUIPC_OP ? 1'b1 : 1'b0;
    assign ALU_op = (opcode == LOAD_OP || opcode == STORE_OP || opcode == JALR_OP) ? ADD : 
                    (opcode == BRANCH_OP) ? {2'b10,funct3} : 
                    (opcode == COMPU_I_OP) ? {1'b0,I_type_op[5],funct3} : 
                    (opcode == COMPU_R_OP) ? {1'b0,funct7[5],funct3} : ADD;

    assign ALU_src2_sel = (opcode == COMPU_R_OP || opcode == BRANCH_OP) ? 1'b0 : 1'b1;



    assign idu_jump_o = jump;
    assign idu_RegW_EN_o = RegW_en;
    assign idu_RegW_sel_o = RegW_sel;
    assign idu_MemW_EN_o = MemW_en;
    assign idu_TakenAddr_sel_o = TakenAddr_sel;
    assign idu_ALU_opcode_o = ALU_op;
    assign idu_ALU_src2_sel_o = ALU_src2_sel;

    assign idu_src1_inx_o = rs1_inx;
    assign idu_src2_inx_o = rs2_inx;
    assign idu_rd_inx_o = rd_inx;
    assign idu_imm_o = imm;
    assign idu_auipc_sel_o = auipc_sel;
    assign idu_is_lw_o = opcode == LOAD_OP;

endmodule //RV32I_idu