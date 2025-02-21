`timescale 1ns/1ps


module MIPS32_CPU (
    input CLK,RST,
    //连接到外部的ROM
    output [5:0] ROM_A1,
    output [5:0] ROM_A2,
    input [31:0] ROM_RD1,
    input [31:0] ROM_RD2
);
    wire FI_ex_setPC;
    wire [31:0] FI_ex_PC;
    wire [31:0] FI_out_PC1,FI_out_PC2,FI_inst_1,FI_inst_2;
    
    //流水线执行单元外的寄存器

    // EX pipeline

    //接受输入
    reg [31:0] EX_sig1_i,EX_sig2_i;
    reg [31:0] sw_data1_i,sw_data2_i;   //Reg to Mem
    //输出
    reg [31:0] EX_sig1_o,EX_sig2_o;
    reg [31:0] sw_data1_o,sw_data2_o;   //Reg to Mem
    // EX end

    // MA pipeline
    //接受输入
    reg [31:0] MA_sig1_i,MA_sig2_i;
    reg [31:0] MA_ALU1_TMP,MA_ALU2_TMP; //may ALU to Reg (skip MA)
    //输出
    reg [31:0] MA_sig1_o,MA_sig2_o;
    reg [31:0] MA_Data1_o,MA_Data2_o;   //chose ALU or MemR
    // MA end

    // WB pipeline
    //输入
    reg [31:0] WB_sig1_i,WB_sig2_i; //处于MA阶段
    //输出
    reg [31:0] ID_clr_w_mask;

    // WB end

    //end


    FI_stage FI_1(
        .RST(RST),
        .CLK(CLK),

        .ROM_A1(ROM_A1),
        .ROM_A2(ROM_A2),
        .ROM_RD1(ROM_RD1),
        .ROM_RD2(ROM_RD2),
        
        .ex_setPC(FI_ex_setPC),
        .ex_PC(FI_ex_PC),
        .out_PC1(FI_out_PC1),
        .out_PC2(FI_out_PC2),
        .inst_1(FI_inst_1),
        .inst_2(FI_inst_2)
    );

    
    wire [4:0] reg_read_addr[0:3];
    wire [31:0] reg_read_data[0:3];
    wire EX_ex_set_PC;
    wire [31:0] EX_ex_PC;

    wire [31:0] IDo_src0,IDo_src1,IDo_src2,IDo_src3;
    wire [31:0] IDo_imm1,IDo_imm2;
    wire [31:0] IDo_PC1,IDo_PC2;
    //以下内容需要额外寄存器保存
    wire [31:0] IDo_sig1,IDo_sig2;
    wire [31:0] IDo_sw_data_1,IDo_sw_data_2;
    //内容需要额外寄存器保存 end

    ID_stage ID_1(
        .CLK(CLK),
        .RST(RST),
        .pipeline_hang(1'b0),
        .clr_w_mask(ID_clr_w_mask),

        .PC1(FI_out_PC1),
        .PC2(FI_out_PC2),
        .inst_1(FI_inst_1),
        .inst_2(FI_inst_2),

        .RAddr1(reg_read_addr[0]),
        .RAddr2(reg_read_addr[1]),
        .RAddr3(reg_read_addr[2]),
        .RAddr4(reg_read_addr[3]),
        .ID_set_PC(FI_ex_setPC),
        .ID_PC(FI_ex_PC),
        .RData1(reg_read_data[0]),
        .RData2(reg_read_data[1]),
        .RData3(reg_read_data[2]),
        .RData4(reg_read_data[3]),
        .EX_set_PC(EX_ex_set_PC),
        .EX_PC(EX_ex_PC),
        //.EX_clear_pipeline2(0),

        .src0(IDo_src0),
        .src1(IDo_src1),
        .src2(IDo_src2),
        .src3(IDo_src3),
        .imm1(IDo_imm1),
        .imm2(IDo_imm2),
        .PC1_o(IDo_PC1),
        .PC2_o(IDo_PC2),

        .inst1_signal(IDo_sig1),
        .inst2_signal(IDo_sig2),

        .sw_data_1(IDo_sw_data_1),
        .sw_data_2(IDo_sw_data_2)
    );

    wire [31:0] EX_bypass0,EX_bypass1,EX_bypass2,EX_bypass3;
    wire EX_clear_pipeline2;
    wire [31:0] EXo_ALU1,EXo_ALU2;

    EX_stage EX_1(
        .CLK(CLK),
        .RST(RST),

        .src0(IDo_src0),
        .src1(IDo_src1),
        .src2(IDo_src2),
        .src3(IDo_src3),
        .PC1(IDo_PC1),
        .PC2(IDo_PC2),
        .imm1(IDo_imm1),
        .imm2(IDo_imm2),
        .PCSRC1(IDo_sig1[31:30]),
        .PCSRC2(IDo_sig2[31:30]),
        .exsign1(IDo_sig1[29]),
        .exsign2(IDo_sig2[29]),
        .ALU1_SRCA(IDo_sig1[28:27]),
        .ALU1_SRCB(IDo_sig1[26:25]),
        .ALU2_SRCA(IDo_sig2[28:27]),
        .ALU2_SRCB(IDo_sig2[26:25]),
        .ALU_OP1(IDo_sig1[24:21]),
        .ALU_OP2(IDo_sig2[24:21]),
        .src_by_0(EX_bypass0),
        .src_by_1(EX_bypass1),
        .src_by_2(EX_bypass2),
        .src_by_3(EX_bypass3),

        .set_PC(EX_ex_set_PC),
        .ex_PC(EX_ex_PC),
        .clear_pipeline2(EX_clear_pipeline2),

        .ALU_out1(EXo_ALU1),
        .ALU_out2(EXo_ALU2)
    );

    
    wire [31:0] MAo_data1,MAo_data2;
    DRAM DRAM_1(
        .CLK(CLK),
        .RST(RST),
        .Data1in(sw_data1_o),
        .Data2in(sw_data2_o),
        .Addr1(EXo_ALU1),
        .Addr2(EXo_ALU2),
        .R_W1(EX_sig1_o[18]),
        .R_W2(EX_sig2_o[18]),
        .CS1(EX_sig1_o[20]),
        .CS2(EX_sig2_o[20]),
        .DSRC1(EX_sig1_o[19]),
        .DSRC2(EX_sig2_o[19]),

        .Data1out(MAo_data1),
        .Data2out(MAo_data2)
    );
    

    RegFile MIPS32_REG(
        .CLK(CLK),
        .RST(RST),
        .W1E(MA_sig1_o[17]),
        .W2E(MA_sig2_o[17]),
        .RAddr1(reg_read_addr[0]),
        .RAddr2(reg_read_addr[1]),
        .RAddr3(reg_read_addr[2]),
        .RAddr4(reg_read_addr[3]),
        .WAddr1(MA_sig1_o[16:12]),
        .WAddr2(MA_sig2_o[16:12]),
        .WData1(MA_Data1_o),
        .WData2(MA_Data2_o),
        .RData1(reg_read_data[0]),
        .RData2(reg_read_data[1]),
        .RData3(reg_read_data[2]),
        .RData4(reg_read_data[3])
    );


    always @(posedge CLK) begin
        if(RST) begin
            //清空流水线输入寄存器
            EX_sig1_i <= 0; EX_sig2_i <= 0;
            sw_data1_i <= 0; sw_data2_i <=0;

            MA_sig1_i <= 0 ; MA_sig2_i <=0;
            MA_ALU1_TMP <= 0; MA_ALU2_TMP <= 0;

            WB_sig1_i <= 0; WB_sig2_i <= 0; 

        end
        else begin
            //流水线交付
            EX_sig1_i <= IDo_sig1;      EX_sig2_i <= IDo_sig2;
            sw_data1_i <= IDo_src1;     sw_data2_i <= IDo_src3;

            MA_sig1_i <= EX_sig1_o ;    MA_sig2_i<= EX_sig2_o;
            MA_ALU1_TMP <= EXo_ALU1;    MA_ALU2_TMP <= EXo_ALU2;

            WB_sig1_i <= MA_sig1_o;     WB_sig2_i <= MA_sig2_o;
            
        end
    end

    reg now_RST;    //唯一的作用就是说明当前周期是不是RST
    always @(posedge CLK) begin
        if(RST) now_RST <= 1;
        else now_RST <= 0;
    end

    always @(*) begin
        //维护旁路数据连接情况与流水线清空 
        if(now_RST) begin
            //EX
            sw_data1_o <= 0;    sw_data2_o <= 0;
            EX_sig1_o <= 0;     EX_sig2_o <= 0;    
            //EX end
            //MA
            MA_sig1_o <= 0; MA_sig2_o <= 0;
            MA_Data1_o <= 0;
            MA_Data2_o <= 0;
            //MA end
            ID_clr_w_mask <= 0;
        end
        //EX
        sw_data1_o <= sw_data1_i;
        sw_data2_o <= sw_data2_i;
        EX_sig1_o <= EX_sig1_i;
        if(EX_clear_pipeline2) begin
            EX_sig2_o <= 0;    
        end
        else begin
            EX_sig2_o <= EX_sig2_i;    
        end
        //EX end

        //MA
        MA_sig1_o <= MA_sig1_i;
        MA_sig2_o <= MA_sig2_i;

        if(MA_sig1_o[20] && MA_sig1_o[18]) begin //MemToReg
            MA_Data1_o <= MAo_data1;
        end
        else begin
            MA_Data1_o <= MA_ALU1_TMP;
        end
        if(MA_sig2_o[20] && MA_sig2_o[18]) begin //MemToReg
            MA_Data2_o <= MAo_data2;
        end
        else begin
            MA_Data2_o <= MA_ALU2_TMP;
        end
        //MA end

        ID_clr_w_mask <= 0;
        ID_clr_w_mask[MA_sig1_o[16:12]] <= 1'b1;
        ID_clr_w_mask[MA_sig2_o[16:12]] <= 1'b1;
        
    end
endmodule