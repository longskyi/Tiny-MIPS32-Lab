`include "macro.v"

`timescale 1ns/1ps

//module ALU_8 (F,A,B,OP,ZF,CF,OF,SF,PF);
module ALU (OP,A,B,F,ZF,CF,OF,SF,PF);
    output reg ZF,OF,SF,PF;
    parameter SIZE = 32;
    input [ 3:0] OP;
    input [SIZE-1:0] A;
    input [SIZE-1:0] B;
    output reg [SIZE-1:0] F;
    output reg CF;
    

    // parameter ALU_AND = 4'b0000;    parameter ALU_OR  = 4'b0001;    parameter ALU_XOR = 4'b0010;
    // parameter ALU_NOR = 4'b0011;    parameter ALU_ADD = 4'b0100; //4
    // parameter ALU_SUB = 4'b0101;    parameter ALU_SLT = 4'b0110;    parameter ALU_SLL = 4'b0111;

    parameter ALU_AND = `ALU_OP_BITWISE_AND;
    parameter ALU_OR  = `ALU_OP_BITWISE_OR;
    parameter ALU_XOR = `ALU_OP_BITWISE_XOR;
    parameter ALU_NOR = `ALU_OP_BITWISE_NOR;
    parameter ALU_ADD = `ALU_OP_ADD;
    parameter ALU_SUB = `ALU_OP_SUBTRACT;
    parameter ALU_SLT = `ALU_OP_SIGNED_COMPARISON;
    parameter ALU_SLL = `ALU_OP_LOGIC_LEFTSHIFT;

    wire [7:0] EN;
    wire [SIZE-1:0] Fw,Fa;
    wire C;
    assign Fa = A&B;
    always @(*) begin
        case(OP)
            ALU_AND : begin F<=Fa; CF=0; OF=0; end
            ALU_OR  : begin F<=A|B; CF=0; OF=0; end
            ALU_XOR : begin F<=A^B; CF=0; OF=0; end
            ALU_NOR : begin F<=~(A|B); CF=0; OF=0; end
            ALU_SLT : begin F=Fw; CF=0; OF=0; end
            ALU_SLL : begin F=Fw; CF=0+C; OF=0; end
            default : begin F=Fw; CF=0+C; OF = A[SIZE-1]^B[SIZE-1]^F[SIZE-1]^CF; end
        endcase
        ZF = (F==0);
        SF = F[SIZE-1];
        PF = (^F);
    end

    Decoder38 decoder38_1(OP[2:0],EN);

    ADD add_1(Fw,C,A,B,EN[4]);

    SUB sub_1(Fw,C,A,B,EN[5]);
    
    SLT slt_1(Fw,A,B,EN[6]); 

    SLL sll_1(Fw,A,B,EN[7],C);
    
    
endmodule


module Decoder38(
    input [2:0] A,
    output [7:0] Y
    );
    assign Y[7]= ~(~A[2] | ~ A[1] | ~A[0]);
    assign Y[6]= ~(~A[2] | ~ A[1] |  A[0]);
    assign Y[5]= ~(~A[2] |  A[1]  | ~A[0]);
    assign Y[4]= ~(~A[2] |  A[1]  |  A[0]);
    assign Y[3]= ~(A[2] | ~ A[1] | ~A[0]);
    assign Y[2]= ~(A[2] | ~ A[1] |  A[0]);
    assign Y[1]= ~(A[2] |   A[1] | ~A[0]);
    assign Y[0]= ~(A[2] |   A[1] |  A[0]);
    
endmodule


module SLL (F,A,B,EN,CF);
    output reg CF;
    parameter SIZE=32;
    output reg [SIZE-1:0] F;
    input [SIZE-1:0] A,B;
    input EN;

    always @(A,B,EN) begin
        if(EN==1) {CF,F}<= (B<<A);
        else begin
            F<=32'bz;
            CF<=1'bz;
        end
    end
endmodule

module SLT (F,A,B,EN);
    output reg [31:0] F;
    input [31:0] A,B;
    input EN; 
    always @(A,B,EN) begin
        if(EN==1)
        begin
            F<= (A<B);
        end
        else begin
            F<=32'bz;
        end
    end
endmodule

module SUB (F,CF,A,B,EN);
parameter SIZE = 32;
    output reg [SIZE-1:0] F;
    input wire [SIZE-1:0] A,B;
    output reg CF;
    input EN;

    always @(A,B,EN) begin
        if(EN==1) begin
            {CF,F}=A[SIZE-1:0]-B[SIZE-1:0];
        end 
        else begin 
            F<=32'bz;
            CF <= 1'bz;
        end
    end

endmodule

