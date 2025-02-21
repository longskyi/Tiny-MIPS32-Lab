`define DATA_WIDTH 32


//支持4读2写
module RegFile  // 寄存器文件
    #(parameter ADDR_SIZE = 5) //2^5=32
    (input CLK, RST ,W1E, W2E,   
    input [ADDR_SIZE-1:0] RAddr1, RAddr2, RAddr3, RAddr4, WAddr1, WAddr2,
    input [`DATA_WIDTH-1:0] WData1, WData2,
    output [`DATA_WIDTH-1:0] RData1, RData2, RData3, RData4
);
    integer i;
    reg [`DATA_WIDTH-1:0] rf[2**ADDR_SIZE-1:0];  // 寄存器数组

    // 数据写入需要时钟同步
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // 复位时，将所有寄存器初始化为0
            for (i = 0; i < 2**ADDR_SIZE; i = i + 1) begin
                rf[i] <= 0;  
            end
        end
        else begin
            if (W1E) rf[WAddr1] <= WData1;
            if (W2E) rf[WAddr2] <= WData2;
        end
    end

    // 数据读取
    assign RData1 = (RAddr1 != 0) ? rf[RAddr1] : 0;
    assign RData2 = (RAddr2 != 0) ? rf[RAddr2] : 0;
    assign RData3 = (RAddr3 != 0) ? rf[RAddr3] : 0;
    assign RData4 = (RAddr4 != 0) ? rf[RAddr4] : 0;

    // initial begin
    //     $readmemh("C:/code/vivado/jz04/jz04.srcs/sources_1/memfile.txt", rf);  // 从文件读取数据
    // end

endmodule