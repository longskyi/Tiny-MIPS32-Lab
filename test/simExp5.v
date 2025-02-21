`timescale 1ns/1ps




module sim_exp5 ();

    reg [31:0] ROM[0:30];
    reg [31:0] inst;
    wire MemToReg,MemWrite,PCSrc,ALUSrc,RegDst,RegWrite,Jump;
    wire [2:0] ALUControl;
    integer i=0;
    initial begin
        inst = 0;
        ROM[0] = 32'h34080005;  // ori $t0, $zero, 5
        ROM[1] = 32'h3409000A;  // ori $t1, $zero, 10
        ROM[2] = 32'h01095021;  // addu $t2, $t0, $t1
        ROM[3] = 32'h01285823;  // subu $t3, $t1, $t0
        ROM[4] = 32'hAD0A0000;  // sw $t2, 0($t0)
        ROM[5] = 32'h8D0C0000;  // lw $t4, 0($t0)
        ROM[6] = 32'h114C0002;  // beq $t2, $t4, label
        ROM[7] = 32'h3C0D1234;  // lui $t5, 0x1234
        ROM[8] = 32'h08000001;  // j 0x1
        ROM[9] = 32'h00000000;  // nop       
        ROM[10] = 32'h00000000;  // nop       
        #5
        for (i = 0; i <= 12 ; i=i+1) begin
            #10 inst <= ROM[i];
        end 
        $stop;
    end

    Controller cu1(inst[31:26],inst[5:0],0,MemToReg,MemWrite,PCSrc,ALUSrc,RegDst,RegWrite,Jump,ALUControl);
    // module Controller(
    // input [5:0] Op,Funct,
    // input Zero,
    // output MemToReg,MemWrite,
    // output PCSrc,ALUSrc,
    // output RegDst,RegWrite,
    // output Jump,
    // output [2:0] ALUControl);

endmodule
