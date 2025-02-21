`timescale 1ns/1ps
`include "macro.v"
module MainDec (
    input [5:0] Op,
    output MemToReg,MemWrite,
    output Branch,ALUSrc,
    output RegDst,RegWrite,
    output Jump,
    output [2:0] ALUOp);

    reg [9:0] Controls;
    assign {RegWrite,RegDst,ALUSrc,Branch,MemWrite,MemToReg,Jump,ALUOp} = Controls;
    //要求支持的指令为{addu, subu, ori, lw, sw, beq, lui, nop}
    always @(*) begin
        case (Op)
            6'b000000: Controls <= 10'b1100000100;    //RTYPE
            6'b100011: Controls <= 10'b1010010000;    //LW
            6'b101011: Controls <= 10'b0010100000;    //SW
            6'b000100: Controls <= 10'b0001000001;    //BEQ
            6'b001000: Controls <= 10'b1010000000;    //ADDI
            6'b000010: Controls <= 10'b0000001000;    //J
            `_OP_ori : Controls <= 10'b1010000010;
            `_OP_lui : Controls <= 10'b1010000011;
            default:   Controls <= 10'bxxxxxxxxxx;       // illegal Op
        endcase
    end
    
endmodule


module ALUDec(
    input [5:0] Funct,
    input [2:0] ALUOp,
    output reg [2:0] ALUControl);

    always @(*) begin
        case (ALUOp)
            3'b000: ALUControl <= 3'b010;    // add (for lw/sw/addi)
            3'b001: ALUControl <= 3'b110;    // sub (for beq)
            3'b010: ALUControl <= 3'b001;    // or (for ori)
            3'b011: ALUControl <= 3'b011;    // sll (for lui)
            default: case (Funct)           //3'b100
                6'b100000: ALUControl <= 3'b010;    //add
                6'b100010: ALUControl <= 3'b101;    //sub
                `_OP_addu: ALUControl <= 3'b010;
                `_OP_subu: ALUControl <= 3'b101;
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

    wire [2:0] ALUOp;
    wire Branch;

    MainDec MainDec_1(Op,MemToReg,MemWrite,Branch,ALUSrc,RegDst,RegWrite,Jump,ALUOp);

    ALUDec ALUDec_1(Funct,ALUOp,ALUControl);

    assign PCSrc = Branch & Zero;

endmodule

