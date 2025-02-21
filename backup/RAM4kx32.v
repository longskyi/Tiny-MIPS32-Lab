`timescale 1ns/1ps

module Decoder24(
    input [1:0] A,
    output [3:0] Y
    );
    assign Y={A[1] & A[0],A[1] & (~A[0]),(~A[1]) & A[0], ~A[1] & (~ A[0])};
endmodule

module RAM_1Kx16_inout(Data, Addr, Rst, R_W, CS, CLK);
    parameter Addr_Width = 10;  // 参数化地址线宽
    parameter Data_Width = 16;   // 参数化数据线宽
    parameter SIZE = 2 ** Addr_Width;  // 参数化大小为1024

    inout [Data_Width-1:0] Data;  // 数据，输入输出类型
    input [Addr_Width-1:0] Addr;   // 地址
    input Rst;                      // 复位信号
    input R_W;                      // 1为读，0为写信号
    input CS;                       // 使能信号
    input CLK;                      // 时钟信号

    integer i;                     // 临时变量，用于for循环
    reg [Data_Width-1:0] Data_i;  // 数据寄存器
    reg [Data_Width-1:0] RAM [SIZE-1:0];  // 1024*16的RAM

    initial begin
        // $readmemb 和 $readmemh 是用来从文件加载初始化数据的
        // $readmemb("C:/code/vivado/jz04/jz04.srcs/sources_1/ram_data_b.txt", RAM); // 读取二进制数据文件
        //$readmemh("C:/code/vivado/jz04/jz04.srcs/sources_1/ram_data_h.txt", RAM, 0, 64); // 读取十六进制数据文件，存储到0-64号地址空间
    end

    // inout类型接口，输入输出控制
    assign Data = (R_W) ? Data_i : 16'bz;  // 根据读写信号选择数据

    always @(posedge CLK or negedge CLK) begin  // 时钟触发
    //always @(*) begin  // 异步
    if(CLK) begin
        casex({CS, Rst, R_W})
            4'bx1x: for (i = 0; i <= SIZE-1; i = i + 1) RAM[i] = 0;  // 初始化RAM
            4'b101: Data_i <= RAM[Addr];  // 读数据
            4'b100: RAM[Addr] <= Data;    // 写数据
            default: Data_i = 16'bz;      // 默认状态
        endcase
    end
    else begin
        casex({CS, Rst, R_W})
            4'bx1x: for (i = 0; i <= SIZE-1; i = i + 1) RAM[i] = 0;  // 初始化RAM
            4'b101: Data_i <= RAM[Addr];  // 读数据
            4'b100: RAM[Addr] <= Data;    // 写数据
            default: Data_i = 16'bz;      // 默认状态
        endcase
    end
        
    end
endmodule

module RAM_4Kx32_inout  // 4K x 32位RAM
    #(
        parameter Addr_Width = 12,  // 参数化地址宽度
        parameter Data_Width = 32    // 参数化数据宽度
    )
    (
        inout [Data_Width-1:0] Data,  // 数据输出
        input [Addr_Width-1:0] Addr,   // 地址输入
        input Rst,                      // 复位信号
        input R_W,                      // 读写信号
        input CS,                       // 使能信号
        input CLK                       // 时钟信号
    );

    wire [3:0] CS_i;  // 片选信号组
    Decoder24 Decoder24_1(.Y(CS_i),.A(Addr[Addr_Width-1:Addr_Width-2]));  // 24译码器生成片选信号
    // 数据层，位移层
    RAM_1Kx16_inout     CS0_H_16bit(Data[Data_Width-1:Data_Width/2], Addr[Addr_Width-3:0], Rst, R_W, CS_i[0], CLK),
                        CS0_L_16bit(Data[Data_Width/2-1:0], Addr[Addr_Width-3:0], Rst, R_W, CS_i[0], CLK);

    RAM_1Kx16_inout     CS1_H_16bit(Data[Data_Width-1:Data_Width/2], Addr[Addr_Width-3:0], Rst, R_W, CS_i[1], CLK),
                        CS1_L_16bit(Data[Data_Width/2-1:0], Addr[Addr_Width-3:0], Rst, R_W, CS_i[1], CLK);

    RAM_1Kx16_inout     CS2_H_16bit(Data[Data_Width-1:Data_Width/2], Addr[Addr_Width-3:0], Rst, R_W, CS_i[2], CLK),
                        CS2_L_16bit(Data[Data_Width/2-1:0], Addr[Addr_Width-3:0], Rst, R_W, CS_i[2], CLK);

    RAM_1Kx16_inout     CS3_H_16bit(Data[Data_Width-1:Data_Width/2], Addr[Addr_Width-3:0], Rst, R_W, CS_i[3], CLK),
                        CS3_L_16bit(Data[Data_Width/2-1:0], Addr[Addr_Width-3:0], Rst, R_W, CS_i[3], CLK);
endmodule