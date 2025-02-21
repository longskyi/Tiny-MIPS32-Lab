`timescale 1ns/1ps
`define DATA_WIDTH 32


//设计目标
//维护内部PC，ex_setPC为外部控制信号，要求为逻辑电路
//不存在上一流水线内容


module FI_stage (
    input RST,
    input CLK,


    //连接到外部IMem
    output [5:0] ROM_A1,
    output [5:0] ROM_A2,
    input [31:0] ROM_RD1,
    input [31:0] ROM_RD2,
    //连接到外部IMem end
    //控制信号，实时变化来自其他流水线输出
    input ex_setPC,
    input wire [31:0] ex_PC,
    //end

    //交付给下级流水线
    output [31:0] out_PC1,   // 第一条指令输出时的PC(即指向第二条指令开始位置)
    output [31:0] out_PC2,   // 第一条指令输出时的PC(即指向第二条指令开始位置)
    output [31:0] inst_1,  // 第一条指令输出
    output [31:0] inst_2  // 第二条指令输出
    //end
    
);
    // 计算指令地址
    wire [5:0] inst1_addr;
    wire [5:0] inst2_addr;
    reg [31:0] PC;


    assign inst1_addr = (ex_setPC) ? ex_PC[7:2] : PC[7:2];
    assign inst2_addr = (ex_setPC) ? ex_PC[7:2] + 1 : PC[7:2] + 1;
    assign out_PC1 = (ex_setPC) ? ex_PC + 4 : PC + 4;
    assign out_PC2 = (ex_setPC) ? ex_PC + 8 : PC + 8;
    // 其实可以改为always @(*)类型
    
    // 将指令存储器搬到cpu外部
    assign ROM_A1 = inst1_addr;
    assign ROM_A2 = inst2_addr;
    assign inst_1 = ROM_RD1;
    assign inst_2 = ROM_RD2;
    // 将指令存储器搬到cpu外部 end

    // IMem imem (
    //     .A1(inst1_addr),
    //     .A2(inst2_addr),
    //     .RD1(inst_1),
    //     .RD2(inst_2)
    // );

    reg last_RST;
    always @(posedge CLK) begin
        if (RST) begin
            PC=32'b0;
            last_RST <= 1;
        end else begin
            if(last_RST) begin
                last_RST <= 0;
                PC = PC + 8;
            end
            else if(ex_setPC) begin
                //意味上一刻使用的是expc
                PC = ex_PC + 8;
            end
            else begin
                //意味着上一刻使用的内置pc
                PC = PC + 8 ;
            end
        end
    end
endmodule
    