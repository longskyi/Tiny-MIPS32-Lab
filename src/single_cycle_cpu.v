`include "macro.v"

`timescale 1ns/1ps


module single_cycle_CPU (
    input CLK,RST
);

    reg [31:0] inst;
    reg [31:0] inst_PC,inst_PC__;
    wire [31:0] inst__;
    wire ALU_ZF;
    wire MemToReg,MemWrite,PCSrc,ALUSrc,RegDst,RegWrite,Jump;
    wire [2:0] ALUControl;
    reg now_RST;
    
    always @(posedge CLK) begin
        if(RST) begin
            now_RST = 1;
            inst_PC <= 0;
            inst <= 0;
        end 
        else begin
            now_RST = 0; 
            inst <= inst__;
            inst_PC <= inst_PC__;    
        end 
    end

    IMem        ROM1(.A1(inst_PC__[31:2]),.RD1(inst__));

    Controller  cu1(.Op(inst[31:26]),
                    .Funct(inst[5:0]),
                    .Zero(ALU_ZF),
                    .MemToReg(MemToReg),
                    .MemWrite(MemWrite),
                    .PCSrc(PCSrc),
                    .ALUSrc(ALUSrc),
                    .RegDst(RegDst),
                    .RegWrite(RegWrite),
                    .Jump(Jump),
                    .ALUControl(ALUControl)
                    );

    always @(*) begin
        if(now_RST) inst_PC__ <= 0;
        else
        if(Jump) begin
            inst_PC__ <= {inst_PC[31:28],inst[27:0],4'b0};
        end
        else if(PCSrc) begin
            if(inst[15])
                inst_PC__ <= inst_PC  + {12'b1,inst[15:0],4'b0};
            else
                inst_PC__ <= inst_PC  + {12'b0,inst[15:0],4'b0};     
        end
        else
            inst_PC__ <= inst_PC+4;
    end

    reg  [31:0] ALU_A,ALU_B;
    reg W1E;
    reg [4:0] RAddr1,RAddr2,WAddr1;
    wire [31:0] RData1,RData2;
    reg [31:0] WData1;
    wire [31:0] ALU_F;

    always @(*) begin
        if(RegDst) begin
            RAddr1 <= inst[25:21];
            RAddr2 <= inst[20:16];
            ALU_A <= RData1;
            ALU_B <= RData2;
        end
        else if(inst[31:26]==`_OP_lui) begin
            RAddr1 <= inst[25:21];
            ALU_A <= RData1;
            ALU_B <= 12;
        end 
        else if(ALUSrc) begin
            RAddr1 <= inst[25:21];
            ALU_A <= RData1;
            if(inst[15])
                ALU_B <= {16'b1,inst[15:0]};
            else
                ALU_B <= {16'b0,inst[15:0]};
        end
        else begin
            //beq
            RAddr1 <= inst[25:21];
            RAddr2 <= inst[20:16];
            ALU_A <= RData1;
            ALU_B <= RData2;
        end
    end

    

    

    ALU alu1(.OP({1'b0,ALUControl}),
            .A(ALU_A),
            .B(ALU_B),
            .F(ALU_F),
            .ZF(ALU_ZF)
            ); 
    
    RegFile regfile1(.CLK(CLK),
                    .RST(RST),
                    .W1E(W1E),    
                    .RAddr1(RAddr1),
                    .RAddr2(RAddr2),
                    .RData1(RData1),
                    .RData2(RData2),
                    .WAddr1(WAddr1),
                    .WData1(WData1)
                    );

    wire [31:0] RAM_Data_wire;
    wire R_W;
    assign RAM_Data_wire = (MemWrite) ? RData2 : 16'bz;
    assign R_W = (MemWrite) ? 1'b0 : 1'b1;

    RAM_4Kx32_inout ram11(
        .Data(RAM_Data_wire),  // 数据输出
        .Addr({2'b0,ALU_F[31:2]}),   // 地址输入
        .Rst(RST),                      // 复位信号
        .R_W(R_W)                      // 读写信号
    );


    always @(*) begin
        if(RegWrite && RegDst) begin
            W1E <= 1;
            WAddr1 <= inst[15:11];
        end
        else if(RegWrite) begin
            W1E <= 1;
            WAddr1 <= inst[20:16];
        end
        else begin
            W1E <= 0;
            WAddr1 <= 0;
        end
    end

    always @(*) begin
        if(MemToReg) begin
            WData1 <= RAM_Data_wire;
        end
        else begin
            WData1 <= ALU_F;
        end
    end


endmodule