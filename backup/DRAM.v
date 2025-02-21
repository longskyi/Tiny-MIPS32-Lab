module DRAM
    (
        inout [31:0] Data1, Data2,  // 数据输入输出复用
        input [31:0] Addr1, Addr2,  // 地址输入
        input RST,                  // 复位信号
        input R_W1, R_W2,           // 双流水线读写信号，0写1读
        input CS1,CS2,                   // 使能信号
        input CLK                   // 时钟信号
    );

    // 内部信号
    wire [31:0] ram_data_inout;     // 从RAM输出的数据
    wire [31:0] ram_addr;
    reg [31:0] tmp_in_data2;
    reg tmp_in_CS2;
    reg tmp_R_W2;
    reg [31:0] tmp_addr2;
    reg [31:0] dram_out1,dram_out2; // 暂存输出数据
    reg sig_chose;       // 信号接收选择位
    wire ram_RW;        // 写入标志

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
        if(RST && CLK) begin
            sig_chose <=1'b1;
            dram_out1 <= 0;
        end
        else if(RST && ~CLK) begin
            sig_chose <=1'b0;
            dram_out2 <= 0;
        end
        else begin
            if(CLK) begin
                //时钟上升沿
                tmp_in_data2 = Data2;
                tmp_R_W2 = R_W2;
                tmp_in_CS2 = CS2;
                tmp_addr2 = Addr2;
                sig_chose <= 1'b1;
                //if(R_W1)    dram_out1 <= ram_data_inout;
            end
            else begin
                sig_chose <= 1'b0;
                if(R_W1)    dram_out1 <= ram_data_inout;
                //if(tmp_R_W2)    dram_out2 <= ram_data_inout;
            end
        end
    end
    
    assign ram_RW = (~sig_chose) ? R_W1 : tmp_R_W2;
    assign ram_cs = (~sig_chose) ? CS1 : tmp_in_CS2;
    assign ram_addr = (~sig_chose) ? Addr1 : tmp_addr2;
    //assign ram_data_inout = (sig_chose) ? Data1 : Data2;
    assign ram_data_inout = (~sig_chose) ? ((R_W1) ? 32'bz : Data1) : 32'bz; // When sig_chose is true, drive Data1
    assign ram_data_inout = (sig_chose) ?  ((tmp_R_W2) ? 32'bz : tmp_in_data2) : 32'bz; // When sig_chose is false, drive Data2
    // 处理Data1的赋值
    assign Data1 = (CS1 && R_W1) ? dram_out1 : 32'bz; // 读Data1
    // 处理Data2的赋值
    assign Data2 = (CS2 && R_W2) ? ram_data_inout : 32'bz; // 读Data2

endmodule