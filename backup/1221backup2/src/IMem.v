`timescale 1ns/1ps



`define DATA_WIDTH 32

module IMem(  // 指令存储器
    input [5:0] A1,
    input [5:0] A2,
    output [`DATA_WIDTH-1:0] RD1,
    output [`DATA_WIDTH-1:0] RD2
);
    parameter IMEM_SIZE = 64;  // 指令存储器大小

    // 指令存储器
    reg [`DATA_WIDTH-1:0] ROM[IMEM_SIZE-1:0];

    initial begin
        //$readmemh("C:/code/vivado/jz00_simpleCPU/test/memfile.txt", ROM);  // 从文件读取数据
        //加载指令（机器码）
        ROM[0] = 32'h34080005;  // ori $t0, $zero, 5
        ROM[1] = 32'h3409000A;  // ori $t1, $zero, 10
        ROM[2] = 32'h01095021;  // addu $t2, $t0, $t1
        ROM[3] = 32'h01285823;  // subu $t3, $t1, $t0
        ROM[4] = 32'h200E0002;  // addi $t6 $zero 0x2
        ROM[5] = 32'h01697820;  // add $t7 $t3 $t1
        ROM[6] = 32'hAD0A0000;  // sw $t2, 0($t0)
        ROM[7] = 32'h8D0C0000;  // lw $t4, 0($t0)
        ROM[8] = 32'h114C0002;  // beq $t2, $t4, label
        ROM[9] = 32'h3C0D1234;  // lui $t5, 0x1234
        ROM[10] = 32'h00000000;  // nop
        ROM[11] = 32'h00000000;  // nop (label 后续指令)
        ROM[12] = 32'h00000000;  // nop 
        ROM[13] = 32'h00000000;  // nop 
        ROM[14] = 32'h00000000;  // nop 
    end
    assign RD1 = ROM[A1];  // 指令输出
    assign RD2 = ROM[A2];  // 指令输出
endmodule