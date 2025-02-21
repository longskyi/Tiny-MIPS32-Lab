`include "macro.v"
`timescale 1ns/1ps


//执行阶段

module EX_stage (
    input CLK,
    input RST,
    //上级流水线交付内容，需及时保存
    input [31:0] src0,src1,src2,src3,
    input [31:0] PC1,PC2,
    input [31:0] imm1,imm2,
    input [1:0] PCSRC1,PCSRC2,                //00不更改PC，01使用beq（PC+ sigext(imm1) << 2），10使用j（pc高4位 拼接 26位target 拼接 00）
    input exsign1,exsign2,
    input [1:0] ALU1_SRCA,ALU1_SRCB,
    input [1:0] ALU2_SRCA,ALU2_SRCB,
                                        //SRCA1  01： 使用src0寄存器  00：使用32’b0                                 11:使用src_by_0
                                        //SRCB1  01： 使用src1寄存器  00：使用32’b0  10：使用sigext16(imm1)符号扩展  11:使用src_by_1
                                        //SRCA2  01： 使用src2寄存器  00：使用32’b0                                 11:使用src_by_2
                                        //SRCB2  01： 使用src3寄存器  00：使用32’b0  10：使用sigext16(imm2)符号扩展  11:使用src_by_3
    input [3:0] ALU_OP1,ALU_OP2,        //ALU OP定义见macro

    //旁路
    input [31:0] src_by_0,src_by_1,src_by_2,src_by_3,     //DM->ALU OR ALU->ALU 由外部决定
    //end

    //ex接受的逻辑电路控制信号
    //end

    //当前要实时向外输出的逻辑电路控制信号
    output reg set_PC,
    output reg [31:0] ex_PC,
    output reg clear_pipeline2,//如果beq/j在第1条流水线上，则要清空第2条流水线内容 实际上如果第一条是j，第二条就不应该进内容
    //end

    //向下级流水线交付内容 //后续支持也属于旁路 ALU->ALU
    output reg [31:0] ALU_out1,ALU_out2
    //end
);

    //内部保存流水线状态
    reg [31:0] src0_in,src1_in,src2_in,src3_in;
    reg [31:0] PC1_in,PC2_in;
    reg [31:0] imm1_in,imm2_in;
    reg [1:0] PCSRC1_in,PCSRC2_in;                
    reg exsign1_in,exsign2_in;
    reg [1:0] ALU1_SRCA_in,ALU1_SRCB_in;
    reg [1:0] ALU2_SRCA_in,ALU2_SRCB_in;
    reg [3:0] ALU_OP1_in,ALU_OP2_in;
    reg [31:0] src_by_0_in,src_by_1_in,src_by_2_in,src_by_3_in;

    
    wire [31:0] imm1_ext32 , imm2_ext32;
    reg [31:0] PC1_beq , PC1_j , PC2_beq , PC2_j;

    always @(*) begin
        PC1_beq <= PC1_in + (imm1_ext32 << 2) ;
        PC1_j   <= {PC1_in[31:28],imm1_ext32,2'b00};
        PC2_beq <= PC2_in + (imm2_ext32 << 2) ;
        PC2_j   <= {PC2_in[31:28],imm2_ext32,2'b00};
    end


    Extender    SigExt16_1(imm1_in[15:0],exsign1_in,imm1_ext32),
                SigExt16_2(imm2_in[15:0],exsign2_in,imm2_ext32);

    //需要处理ALU输入
    reg [31:0] ALU1_A,ALU1_B,ALU2_A,ALU2_B;
    wire [31:0] ALU1_F,ALU2_F;
    wire ZF1,CF1,OF1,SF1,PF1;
    wire ZF2,CF2,OF2,SF2,PF2;

    always @(*) begin
        case (ALU1_SRCA_in)
            2'b00: ALU1_A <= 0;
            2'b01: ALU1_A <= src0_in;
            2'b11: ALU1_A <= src_by_0_in;
            default: ALU1_A <= 32'bz;
        endcase
        case (ALU1_SRCB_in)
            2'b00: ALU1_B <= 0;
            2'b01: ALU1_B <= src1_in;
            2'b10: ALU1_B <= imm1_ext32;
            2'b11: ALU1_B <= src_by_1_in;
            default: ALU1_B <= 32'bz; 
        endcase
        case (ALU2_SRCA_in)
            2'b00: ALU2_A <= 0;
            2'b01: ALU2_A <= src2_in;
            2'b11: ALU2_A <= src_by_2_in;
            default:  ALU2_A <= 32'bz;
        endcase
        case (ALU2_SRCB_in)
            2'b00: ALU2_B <= 0;
            2'b01: ALU2_B <= src3_in;
            2'b10: ALU2_B <= imm2_ext32;
            2'b11: ALU2_B <= src_by_3_in;
            default: ALU2_B <= 32'bz; 
        endcase

        case (ALU_OP1_in)
            `ALU_OP_LUI_16TO32 : ALU_out1 <= {imm1_in[15:0],16'b0}; 
            default: ALU_out1 <= ALU1_F;
        endcase
        
        case (ALU_OP2_in)
            `ALU_OP_LUI_16TO32 : ALU_out2 <= {imm2_in[15:0],16'b0};
            default:  ALU_out2 <= ALU2_F;
        endcase
    end

    ALU         ALU1(
                    .OP(ALU_OP1_in),
                    .A(ALU1_A),
                    .B(ALU1_B),
                    .F(ALU1_F),
                    .ZF(ZF1),
                    .CF(CF1),
                    .OF(OF1),
                    .SF(SF1),
                    .PF(PF1)   
                ),
                ALU2 (
                    .OP(ALU_OP2_in),
                    .A(ALU2_A),
                    .B(ALU2_B),
                    .F(ALU2_F),
                    .ZF(ZF2),
                    .CF(CF2),
                    .OF(OF2),
                    .SF(SF2),
                    .PF(PF2)   
                );    


    always @(posedge CLK) begin
    if (RST) begin
        // 当复位信号为高时，清零所有内部寄存器
        src0_in <= 32'b0;
        src1_in <= 32'b0;
        src2_in <= 32'b0;
        src3_in <= 32'b0;
        PC1_in <= 32'b0;
        PC2_in <= 32'b0;
        imm1_in <= 32'b0;
        imm2_in <= 32'b0;
        PCSRC1_in <= 1'b0;
        PCSRC2_in <= 1'b0;
        exsign1_in <= 1'b0;
        exsign2_in <= 1'b0;
        ALU1_SRCA_in <= 2'b00;
        ALU1_SRCB_in <= 2'b00;
        ALU2_SRCA_in <= 2'b00;
        ALU2_SRCB_in <= 2'b00;
        ALU_OP1_in <= 4'b0000;
        ALU_OP2_in <= 4'b0000;
        src_by_0_in <= 32'b0;
        src_by_1_in <= 32'b0;
        src_by_2_in <= 32'b0;
        src_by_3_in <= 32'b0;
    end else begin
        // 当复位信号为低时，将上级流水线的信号复制到内部寄存器
        src0_in <= src0;
        src1_in <= src1;
        src2_in <= src2;
        src3_in <= src3;
        PC1_in <= PC1;
        PC2_in <= PC2;
        imm1_in <= imm1;
        imm2_in <= imm2;
        PCSRC1_in <= PCSRC1;
        PCSRC2_in <= PCSRC2;
        exsign1_in <= exsign1;
        exsign2_in <= exsign2;
        ALU1_SRCA_in <= ALU1_SRCA;
        ALU1_SRCB_in <= ALU1_SRCB;
        ALU2_SRCA_in <= ALU2_SRCA;
        ALU2_SRCB_in <= ALU2_SRCB;
        ALU_OP1_in <= ALU_OP1;
        ALU_OP2_in <= ALU_OP2;
        src_by_0_in <= src_by_0;
        src_by_1_in <= src_by_1;
        src_by_2_in <= src_by_2;
        src_by_3_in <= src_by_3;
    end    
end

    always @(*) begin
        //处理控制逻辑 
        clear_pipeline2 = 1'b0;
        if( PCSRC1_in != 2'b00) begin
            //第一条是跳转
            case (PCSRC1_in)
                2'b01: begin
                    //beq
                    if(ZF1) begin
                        //zf 需要跳转
                        set_PC = 1'b1;
                        ex_PC = PC1_beq;
                        clear_pipeline2 = 1'b1;
                    end
                    else begin
                        // 不跳转
                        set_PC = 1'b0;
                        ex_PC = PC1_beq;
                        clear_pipeline2 = 1'b0;
                    end
                end
                2'b10: begin
                    //j 必然跳转
                    set_PC = 1'b1;
                    ex_PC = PC1_j;
                    clear_pipeline2 = 1'b1;
                end 
                default: begin
                    set_PC = 1'bz;
                    ex_PC =  32'bz;
                    clear_pipeline2 = 1'bz;
                end 
            endcase
        end
        if(clear_pipeline2 == 0) begin
            if( PCSRC2_in != 2'b00) begin
                //第二条是跳转
                case (PCSRC2_in)
                    2'b01: begin
                        //beq
                        if(ZF2) begin
                            //zf 需要跳转
                            set_PC = 1'b1;
                            ex_PC = PC2_beq;
                        end
                        else begin
                            // 不跳转
                            set_PC = 1'b0;
                            ex_PC = PC2_beq;
                        end
                    end
                    2'b10: begin
                        //j 必然跳转
                        set_PC = 1'b1;
                        ex_PC = PC2_j;
                    end 
                    default: begin
                        set_PC = 1'bz;
                        ex_PC =  32'bz;
                    end 
                endcase
            end
            else begin
                //第一第二条都不是跳转
                set_PC = 0 ;
                ex_PC = 0 ;
                clear_pipeline2 = 0;
            end
        end
        
       
    end




endmodule


module Extender #(
    parameter X_WIDTH = 16 // 输入位宽
) (
    input  wire [X_WIDTH-1:0] in,          // 输入
    input  wire        is_signed,          // 符号扩展
    output wire [31:0] out                 // 输出
);
    // 符号扩展或无符号扩展逻辑
    assign out = is_signed ? { {32-X_WIDTH{in[X_WIDTH-1]}}, in }  : { 16'b0, in };     // 符号扩展 与 无符号扩展
endmodule

