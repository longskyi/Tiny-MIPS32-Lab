module DRAM
    (
        input CLK,                   // 时钟信号
        input RST,                  // 复位信号

        //来自上级流水线内容
        input [31:0] Data1in, Data2in,  // 数据输入输出
        input [31:0] Addr1, Addr2,  // 地址输入
        input R_W1, R_W2,           // 双流水线读写信号，0写1读
        input CS1,CS2,                   // 使能信号
        input DSRC1,DSRC2,                //SRC = 0 使用Datain SRC =1 使用Dataout
        //end

        //DRAM不接受可变中间控制信号，必须在上一时钟内确定全部信号

        //交付给下级流水线内容
        output reg [31:0] Data1out,         //支持旁路 DM->ALU DM->DM
        output [31:0] Data2out              
        //end
    );

    // 内部信号 控制ram
    wire [31:0] ram_data_inout;     // 从RAM输出的数据
    reg [31:0] ram_in_data;         //如果要写入
    reg [31:0] ram_addr;
    reg ram_RW;        // 写入标志
    reg ram_cs;
    //
    //pipeline reg for 2
    reg [31:0] tmp_in_data2;
    reg tmp_in_CS2;
    reg tmp_R_W2;
    reg [31:0] tmp_addr2;
    //pipeline reg for 2

    // 实例化RAM模块
    RAM_4Kx32_inout ram(
        .Data(ram_data_inout),      // RAM输出数据
        .Addr(ram_addr[11:0]),       // 地址输入（使用低12位）
        .Rst(RST),                // 复位信号
        .R_W(ram_RW),   // 读信号
        .CS(ram_cs),              // 使能信号
        .CLK(CLK)                 // 时钟信号(RAM内部是异步的，实际不使用时钟信号)
    );

    always @(posedge CLK or negedge CLK or posedge RST) begin
        ram_RW = 1;
        ram_cs = 0;
        if(RST && CLK) begin
            ram_cs <=0;
            Data1out <= 0;
            tmp_in_data2 <=0;
            tmp_in_CS2 <= 0;
            tmp_R_W2 <= 0;
            tmp_addr2 <=0;
        end
        else if(RST && ~CLK) begin
            ram_cs <=0;
            Data1out <= 0;
            tmp_in_data2 <=0;
            tmp_in_CS2 <= 0;
            tmp_R_W2 <= 0;
            tmp_addr2 <=0;
        end
        else begin
            if(CLK) begin
                //时钟上升沿

                //非阻塞式保存下级时钟流水线ASAP
                tmp_in_data2 <= Data2in;
                tmp_in_CS2 <= CS2;
                tmp_R_W2 <= R_W2;
                tmp_addr2 <= Addr2;
                //end

                //保存并输入来自上级流水线内容
                if(~R_W1) ram_in_data <= Data1in; //如果写入
                else ram_in_data <= 0; 

                ram_addr = Addr1;   //注意数据竞争，使用阻塞式，防止错误写入数据
                ram_cs = CS1;
                ram_RW = R_W1;
                //end
            end
            else begin
                //时钟下降沿
                Data1out <= ram_data_inout;

                ram_addr = tmp_addr2;

                ram_RW = tmp_R_W2;
                ram_cs = tmp_in_CS2;
                if(~R_W2) ram_in_data <= tmp_in_data2; //如果写入 
                else ram_in_data = 0;
            end
        end
    end

    assign ram_data_inout = (~ram_RW) ? ram_in_data : 32'bz;
    assign Data2out = ram_data_inout;
endmodule