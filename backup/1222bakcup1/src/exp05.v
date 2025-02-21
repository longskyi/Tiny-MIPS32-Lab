`timescale 1ns/1ps

module MainDec (
    input [5:0] Op,
    output MemToReg,MemWrite,
    output Branch,ALUSrc,
    output RegDst,RegWrite,
    output Jump,
    output [1:0] ALUOp);

    reg [8:0] Controls;
    assign {RegWrite,RegDst,ALUSrc,Branch,MemWrite,MemToReg,Jump,ALUOp} = Controls;

    always @(*) begin
        case (Op)
            6'b000000: Controls <= 9'b110000010;    //RTYPE
            6'b100011: Controls <= 9'b101001000;    //LW
            6'b101011: Controls <= 9'b001010000;    //SW
            6'b000100: Controls <= 9'b000100001;    //BEQ
            6'b001000: Controls <= 9'b101000000;    //ADDI
            6'b000010: Controls <= 9'b000000100;    //J
            default:   Controls <= 9'bxxxxxxxxx;       // illegal Op
        endcase
    end
    
endmodule


module ALUDec(
    input [5:0] Funct,
    input [1:0] ALUOp,
    output reg [2:0] ALUControl);

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl <= 3'b010;    // add (for lw/sw/addi)
            2'b01: ALUControl <= 3'b110;    // sub (for beq) 
            default: case (Funct)
                6'b100000: ALUControl <= 3'b010;    //add
                6'b100010: ALUControl <= 3'b110;    //sub
                6'b100100: ALUControl <= 3'b000;    //and
                6'b100101: ALUControl <= 3'b001;    //or
                6'b101010: ALUControl <= 3'b111;    //slt
                default:   ALUControl   <= 3'bxxx;  //???
            endcase
        endcase
    end
endmodule


module Controller(
    input [5:0] Op,Funct,
    input Zero,
    output MemToReg,MemWrite,
    output PCSrc,ALUSrc,
    output RegDst,RegWrite,
    output Jump,
    output [2:0] ALUControl);

    wire [1:0] ALUOp;
    wire Branch;

    MainDec MainDec_1(Op,MemToReg,MemWrite,Branch,ALUSrc,RegDst,RegWrite,Jump,ALUOp);

    ALUDec ALUDec_1(Funct,ALUOp,ALUControl);

    assign PCSrc = Branch & Zero;

endmodule
