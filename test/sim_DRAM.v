`timescale 1ns/1ps

module sim_DRAM(); // 测试基准模块

    // 信号定义
    reg [31:0] Addr1, Addr2;        // 地址输入
    wire [31:0] datar1,datar2;
    wire [31:0] dataout1 , dataout2;
    reg [31:0] Data1, Data2;        // 数据输入输出
    reg [31:0] Data3, Data4;
    reg RST;                        // 复位信号
    reg R_W1, R_W2;                 // 读写信号
    reg CS1, CS2;                   // 使能信号
    reg CLK;                        // 时钟信号

    DRAM dram_inst (
        .Data1in(datar1),
        .Data2in(datar2),
        .Data1out(dataout1),
        .Data2out(dataout2),
        .Addr1(Addr1),
        .Addr2(Addr2),
        .RST(RST),
        .R_W1(R_W1),
        .R_W2(R_W2),
        .CS1(CS1),
        .CS2(CS2),
        .CLK(CLK)
    );

    // 时钟生成
    initial begin
        CLK = 1;
        forever #5 CLK = ~CLK; // 每5ns反转时钟
    end

    assign datar1 = (~R_W1) ? Data1:32'bz;
    assign datar2 = (~R_W2) ? Data2:32'bz;
    // 测试过程
    initial begin
        // 初始化信号
        RST = 1;
        R_W1 = 0;
        R_W2 = 0;
        CS1 = 0;
        CS2 = 0;

        

        // 等待一段时间后解除复位
        #5 RST = 0;
        #2

        // 测试写入请求
        // 写入数据到Addr1
        Addr1 = 32'h0000_0000;
        Addr2 = 32'h0000_0001;
        Data1 = 32'hDEADBEEF; // 写入数据1
        Data2 = 32'hBAADF00D; // 写入数据2
        CS1 = 1; R_W1 = 0; // 使能CS1，设置为写入
        CS2 = 1; R_W2 = 0; // 使能CS2，设置为写入
        #10; // 等待一个周期
        Addr1 = 32'h0000_0002;
        Addr2 = 32'h0000_0003;
        Data1 = 32'hcccccccc; // 写入数据1
        Data2 = 32'h22222222; // 写入数据2
        CS1 = 1; R_W1 = 0; // 写
        CS2 = 1; R_W2 = 0; // 写
        #10
        // 测试读取请求
        // 读取数据从Addr1
        Addr1 = 32'h0000_0000;
        Addr2 = 32'h0000_0001;
        CS1 = 1; R_W1 = 1; // 使能CS1，设置为读取
        CS2 = 1; R_W2 = 1; // 使能CS2，设置为读取
        #10; // 等待一个周期
        Data3 = dataout1;
        Data4 = dataout2;
        CS1 = 0; R_W1 = 1; 
        CS2 = 0; R_W2 = 1; // 停止读取

        // 检查读取的数据（这里可以加入断言或者打印输出）
        #10;
        $display("Read Data1: %h", Data1);
        $display("Read Data2: %h", Data2);

        // 结束测试
        $stop;
    end
endmodule




`timescale 1ns/1ps

module sim_4kx32();
    parameter Addr_Width = 12;         // 参数化地址宽度
    parameter Data_Width = 32;         // 参数化数据宽度
    parameter SIZE = 2 ** Addr_Width;  // 4096（地址空间大小）

    // RAM 控制信号
    reg Rst, R_W, CLK;                  // 复位、读写信号、时钟信号
    reg [Addr_Width-1:0] Addr;         // 地址信号
    reg [Data_Width-1:0] Data_in;      // 输入数据
    wire [Data_Width-1:0] Data_out;    // 输出数据
    
    // 驱动 inout 数据信号
    wire [Data_Width-1:0] Data;         // 用于 inout 数据的信号
    assign Data = (R_W == 0) ? Data_in : {Data_Width{1'bz}}; // 当 R_W 为低时驱动数据，否则为高阻态

    integer i;                          // 循环变量

    initial begin
        Rst = 0; R_W = 1; CLK = 1;       // 初始化信号，默认读模式

        // 生成时钟信号
        fork
            forever begin
                #10 CLK = ~CLK; // 生成周期为10ns的时钟信号
            end
            begin
                // 仿真过程
                #2 Rst = 1; // 置位复位信号
                #10 Rst = 0; // 解除复位信号

                Addr = 0;

                // 读取操作
                for (i = 0; i < 20; i = i + 1) begin
                    #10 Addr = i; 
                    Data_in =  i; 
                    R_W = 0; // 使能写操作 
                end
                for (i = 0; i < 20; i = i + 1) begin
                    #10 Addr = i;
                    Data_in =  i; 
                    R_W = 1; // 使能读操作 
                end
                
                // 写入操作
                Addr = 'h0002; Data_in = 'h7F7F6262; #2 R_W = 0; #2 R_W = 1; // 写入数据
                Addr = 'h0004; Data_in = 'hAABB8822; #2 R_W = 0; #2 R_W = 1; // 写入数据
                Addr = 'h0006; Data_in = 'h27274433; #2 R_W = 0; #2 R_W = 1; // 写入数据

                // 检查是否正确写入数据
                Addr = 'h0002; #2 R_W = 1; #2 R_W = 1; // 读取返回的数据
                Addr = 'h0004; #2 R_W = 1; #2 R_W = 1; 
                Addr = 'h0006; #2 R_W = 1; #2 R_W = 1; 

                // 异步清零（如果支持的话）
                #2 {Rst, R_W} = 2'b10; #2 {Rst, R_W} = 2'b00; 
                Addr = 'h0002; #2 R_W = 1; #2 R_W = 1; 
            end
        join

        
    end

    // 实例化 RAM 模块
    RAM_4Kx32_inout  ram_a(.Data(Data), .Addr(Addr), .Rst(Rst), .R_W(R_W), .CLK(CLK));
endmodule