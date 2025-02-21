
`include "macro.v"
`timescale 1ns/1ps
`define DATA_WIDTH 32


module ID_stage (
    input CLK,
    input RST,
    input pipeline_hang,              //请求流水线暂停，其他流水线上一刻输出(暂未实现)
    //上级流水线输出
    input [31:0] clr_w_mask, //（掩码类）当前时钟下寄存器写入完成

    input [31:0] PC1,   // 第一条指令输出时的PC(即指向第二条指令开始位置)
    input [31:0] PC2,   // 第二条指令输出时的PC
    input [31:0] inst_1,  // 第一条指令输出
    input [31:0] inst_2,  // 第二条指令输出
    //end

    //实时控制信号
    //输出 请求4个寄存器读地址 控制 FI实时数据
    output [4:0] RAddr1, RAddr2, RAddr3, RAddr4,

    output reg ID_set_PC,       //请求重新设置PC
    output reg [31:0] ID_PC,    //设置的PC值

    //输入 4个寄存器读数据 EX阶段的beq和j数据分支判断数据
    input [31:0] RData1,RData2,RData3,RData4,

    input EX_set_PC,
    input [31:0] EX_PC,
    //input EX_clear_pipeline2, // 应该没用
    //end

    //交付给下一级流水线数据
    output [31:0] src0,src1,src2,src3,              //ALU 4个寄存器
    output [31:0] imm1,imm2,
    output reg [31:0] PC1_o,PC2_o,
    //以上需要直接交付给ALU
    output reg [31:0] inst1_signal,inst2_signal,        //最重要的控制信号
    output [31:0] sw_data_1,sw_data_2               //想要sw的数据
    //end
  
);


    //内部寄存器
    reg [31:0] reg_w_mask;           //（掩码类）寄存器占用状态（写入）为1时，表示对应寄存器正在被写入
    reg [3:0] reg_w_status[0:31] ;   //寄存器占用原因（用于支持旁路数据） 是状态机

    reg [4:0] inst1_target_reg , inst2_target_reg; //标志两个指令如果发射分别设置的mask（set），是超标量计算结果
    reg [3:0] reg_w_status_1, reg_w_status_2 ;     //标志两个指令如果发射分别设置的status，是超标量的计算结果

    reg inst1_valid,inst2_valid ;    //标志两个指令是否可发射，是超标量计算结果
    reg inst1_launch,inst2_launch ;  //标志两个指令实际最终有没有发射。
    reg [3:0] by_pass_1,by_pass_2 ;   //标志两个指令旁路数据使用状态，影响signal的ALU_SRC DSRC以及状态


    //局部临时寄存器
    reg now_RST;    

    //保存上级流水线寄存器
    reg [31:0] clr_w_mask_in, PC1_in,PC2_in,inst_1_in,inst_2_in;
    //内部寄存器 end
    
    integer i,j,k;

    always @(posedge CLK) begin
        if(RST) begin
            now_RST <=1'b1;
            //清空所有内部寄存器
            reg_w_mask <= 32'b0;
            inst1_target_reg <= 0;
            inst2_target_reg <= 0;
            reg_w_status_1 <= 4'b0;
            reg_w_status_2 <= 4'b0;
            for (i = 0; i<=31 ; i = i+1 ) begin
                reg_w_status[i] <= 4'b0;
            end
            clr_w_mask_in <= 0;
            PC1_in <= 0;
            PC2_in <= 0;
            inst_1_in <= 0;
            inst_2_in <= 0;

            PC1_o <= 0;
            PC2_o <= 0;
        end
        else begin
            now_RST <= 1'b0;
            //时序电路，阻塞式函数
            //保存上级流水线数据
            PC1_o <= PC1;
            PC2_o <= PC2;
            clr_w_mask_in = clr_w_mask;
            PC1_in = PC1;
            PC2_in = PC2;
            inst_1_in = inst_1;
            inst_2_in = inst_2;
            //保存上级流水线数据 end

            //更新reg_w_mask 和 status 可能需要使用状态机

            //for(reg_w_status) 状态机进一步

            if(inst1_launch) begin
                reg_w_mask[inst1_target_reg] = 1;
                reg_w_status[inst1_target_reg] = reg_w_status_1;
            end 
            if(inst2_launch) begin 
                reg_w_mask[inst2_target_reg] = 1; //如果上一刻成功发射
                reg_w_status[inst2_target_reg] = reg_w_status_2;
            end
            reg_w_mask [0] = 0; //0号寄存器无论如何都不会被占用
            reg_w_mask = reg_w_mask & (~clr_w_mask_in); //这一刻完成寄存器写入的寄存器
            

            //更新reg_w_mask 和 status end
            
            //超标量-更新两个inst_vali 以及by_pass_
            
            inst1_valid = 1;
            inst2_valid = 1;

            //所有指令{add, sub, addi,  lw, sw, beq, j, nop , ori , lui}
            //需要写入到寄存器的指令 R-type(add sub) 写入到$rd  I-type(addi lw ori lui) 写入到rt
            case (inst_1_in[31:26])
                6'b000000: begin
                    //R-type
                    inst1_target_reg = inst_1_in[15:11];
                end 
                `_OP_addi , `_OP_lw , `_OP_ori , `_OP_lui : begin
                    //I-type
                    inst1_target_reg = inst_1_in[20:16]; 
                end
                default: inst1_target_reg = 0; 
            endcase

            case (inst_2_in[31:26])
                6'b000000: begin
                    //R-type
                    inst2_target_reg = inst_2_in[15:11];
                end 
                `_OP_addi , `_OP_lw , `_OP_ori , `_OP_lui : begin
                    //I-type
                    inst2_target_reg = inst_2_in[20:16]; 
                end
                default: inst2_target_reg = 0;
            endcase

            //如果要写入的寄存器正被写，则无效
            if(reg_w_mask[inst1_target_reg]==1) begin
                inst1_valid = 0;
            end
            if(reg_w_mask[inst2_target_reg]==1) begin
                inst2_valid = 0;
            end
            //如果两条指令写入寄存器相同，则第二条无效
            if(inst1_target_reg!= 0 && inst1_target_reg == inst2_target_reg) inst2_valid = 0;
            //计算要写入的寄存器 end
            
            //判断要读的寄存器有没有占用
            //所有指令{add, sub, addi,  lw, sw, beq, j, nop , ori , lui}
            //以及 addu subu
            case (inst_1_in[31:26])
                6'b000000 , `_OP_beq ,`_OP_sw : begin
                    //R-type
                    if(reg_w_mask[inst_1_in[25:21]]==1 || reg_w_mask[inst_1_in[20:16]]==1) begin
                        inst1_valid = 0;
                        //case(status)
                        //set by_pass_1
                    end
                end 
                `_OP_addi , `_OP_lw , `_OP_ori  : begin
                    //I-type
                    if(reg_w_mask[inst_1_in[25:21]]==1) begin
                        inst1_valid = 0;
                        //case(status)
                        //set by_pass_1
                    end
                end
                //default: inst1_valid = 1; 
            endcase

            case (inst_2[31:26])
                6'b000000 , `_OP_beq ,`_OP_sw  : begin
                    //R-type
                    if(inst_2_in[25:21] == inst1_target_reg || inst_2_in[20:16] == inst1_target_reg) begin
                        inst2_valid = 0;
                    end
                    else if(reg_w_mask[inst_2_in[25:21]]==1 || reg_w_mask[inst_2_in[20:16]]==1) begin
                        inst2_valid = 0;
                        //case(status)
                        //set by_pass_1
                    end
                end 
                `_OP_addi , `_OP_lw , `_OP_ori  : begin
                    //I-type
                    if(inst_2_in[25:21] == inst1_target_reg) begin
                        inst2_valid = 0;
                    end
                    else if(reg_w_mask[inst_2_in[25:21]]==1 ) begin
                        inst2_valid = 0;
                        //case(status)
                        //set by_pass_1
                    end
                end
                //default: inst2_valid = 1; 
            endcase

            //判断要读的寄存器有没有占用 end
            
            //如果第一条无效，第二条必定无效
            if(~inst1_valid) inst2_valid = 0;

            by_pass_1 <= 0;
            by_pass_2 <= 0;
            //超标量-更新两个inst_valid end

        end
        
    end



    //使用assign或者always的逻辑电路，主要考虑ex的beq和j的问题
    assign RAddr1 = inst_1_in[25:21];
    assign RAddr2 = inst_1_in[20:16];
    assign RAddr3 = inst_2_in[25:21];
    assign RAddr4 = inst_2_in[20:16];

    assign src0 = RData1;
    assign src1 = RData2;
    assign src2 = RData3;
    assign src3 = RData4;

    assign imm1 = {6'b0,inst_1_in[25:0]};
    assign imm2 = {6'b0,inst_2_in[25:0]};

    assign sw_data_1 = RData2;
    assign sw_data_2 = RData4;

    wire [31:0] dec_signal1,dec_signal2;
    MainDecoder maindec1(inst_1_in,by_pass_1,dec_signal1),
                maindec2(inst_2_in,by_pass_2,dec_signal2);


    always @(*) begin
        if(now_RST) begin
            ID_set_PC <= 0;
            ID_PC <= 0;
        end
        else begin
           //inst_valid决定输出到下级流水线的两个signal是否有效,同时决定下一个取回的PC
            if(inst1_valid) begin
                inst1_signal <= dec_signal1;
                ID_set_PC <= 1;
                ID_PC <= PC1_in;
            end
            else begin
                inst1_signal <= 0;
            end

            if(inst2_valid) begin
                inst2_signal <= dec_signal2;
                ID_set_PC <= 0; //inst2有效，说明inst1必有效
                ID_PC <= PC2_in;  
            end
            else begin
                inst2_signal <= 0;
            end
            //ex阶段beq/j返回决定下一个取回来的pc，以及两个signal是否有效
            //设置ID_set_PC和ID_PC 取决于两个valid（上方已完成） 取决于EX
            inst1_launch = inst1_valid;
            inst2_launch = inst2_valid;

            if(inst1_launch && inst2_launch) begin
                //发射双指令
                ID_set_PC <= 0;
                ID_PC <= 0;
            end
            else if(inst1_launch) begin
                //发射单指令
                ID_set_PC <= 1;
                ID_PC <= PC1_o;
            end 
            else begin
                //不发射指令
                ID_set_PC <= 1;
                ID_PC <= PC1_o-4;
            end

            if(EX_set_PC) begin
                //超控
                inst1_launch = 0;
                inst2_launch = 0;
                inst1_signal <= 0; //插入空泡nop
                inst2_signal <= 0; //插入空泡nop
                ID_set_PC <= 1;
                ID_PC <= EX_PC;
            end
            
        end
    end
    
endmodule


module MainDecoder (
    input [31:0] inst,
    input [3:0] by_pass_status,
    output reg [31:0] signal);

    wire [5:0] Op;
    assign Op = inst[31:26];

    always @(*) begin
        signal[7:0] <= 8'b0; //保留位
        case (Op)
            6'b000000: begin
                //RTYPE
                if(inst == 32'b0) begin
                    signal <= 32'b0;
                end
                else begin
                   signal[31:29] <= 3'b001;
                    signal[20] <= 1'b0; //使用DRAM
                    signal[18] <= 1'b1; //读=1/写=0 DRAM
                    signal[17] <= 1'b1; //写寄存器
                    signal[16:12] <= inst[15:11];

                    signal[28:25] = 4'b0101; //SRCA SRCB R-type
                    signal[19] = 1'b0; //DSRC 
                end
            end
            6'b100011: begin
                //LW
                signal[31:29] <= 3'b001;
                signal[20] <= 1'b1; //使用DRAM
                signal[18] <= 1'b1; //读=1/写=0 DRAM
                signal[17] <= 1'b1; //写寄存器
                signal[16:12] <= inst[20:16];   //I-type 

                signal[28:25] = 4'b0110; //SRCA SRCB I-type
                signal[19] = 1'b0; //DSRC
            end
            6'b101011: begin
                //SW
                signal[31:29] <= 3'b001;
                signal[20] <= 1'b1; //使用DRAM
                signal[18] <= 1'b0; //读=1/写=0 DRAM
                signal[17] <= 1'b0; //写寄存器
                signal[16:12] <= 5'b0;   //I-type    

                signal[28:25] = 4'b0110; //SRCA SRCB I-type
                signal[19] = 1'b0; //DSRC
            end
            6'b000100: begin
                //BEQ
                signal[31:29] <= 3'b011; //PCSRC-BEQ
                signal[20] <= 1'b0; //使用DRAM
                signal[18] <= 1'b1; //读=1/写=0 DRAM
                signal[17] <= 1'b0; //写寄存器
                signal[16:12] <= 5'b0;   //I-type    

                signal[28:25] = 4'b0101; //SRCA SRCB COMP-SUB
                signal[19] = 1'b0; //DSRC  
            end
            6'b001000: begin
                //ADDI
                signal[31:29] <= 3'b001;
                signal[20] <= 1'b0; //使用DRAM
                signal[18] <= 1'b1; //读=1/写=0 DRAM
                signal[17] <= 1'b1; //写寄存器
                signal[16:12] <= inst[20:16];   //I-type $rt

                signal[28:25] = 4'b0110; //SRCA SRCB I-type
                signal[19] = 1'b0; //DSRC
            end
            6'b001101: begin
                //ORI
                signal[31:29] <= 3'b000; //符号拓展
                signal[20] <= 1'b0; //使用DRAM
                signal[18] <= 1'b1; //读=1/写=0 DRAM
                signal[17] <= 1'b1; //写寄存器
                signal[16:12] <= inst[20:16];   //I-type $rt

                signal[28:25] = 4'b0110; //SRCA SRCB I-type
                signal[19] = 1'b0; //DSRC
            end
            6'b001111: begin
                //LUI
                signal[31:29] <= 3'b001;
                signal[20] <= 1'b0; //使用DRAM
                signal[18] <= 1'b1; //读=1/写=0 DRAM
                signal[17] <= 1'b1; //写寄存器
                signal[16:12] <= inst[20:16];   //I-type $rt

                signal[28:25] = 4'b0010; //SRCA SRCB SRCA置0
                signal[19] = 1'b0; //DSRC
            end
            6'b000010: begin
                //J
                signal[31:29] <= 3'b101; //PCSRC-J
                signal[20] <= 1'b0; //使用DRAM
                signal[18] <= 1'b1; //读=1/写=0 DRAM
                signal[17] <= 1'b0; //写寄存器
                signal[16:12] <= 5'b0;   //J-type  

                signal[28:25] = 4'b0000; //置0
                signal[19] = 1'b0; //DSRC
            end
            default: begin
                // illegal Op
                signal[31:29] <= 3'bzzz; //PCSRC-J
                signal[20] <= 1'bz; //使用DRAM
                signal[18] <= 1'bz; //读=1/写=0 DRAM
                signal[17] <= 1'bz; //写寄存器
                signal[16:12] <= 5'bz;   //J-type  

                signal[28:25] = 4'b0000; //置0
                signal[19] = 1'b0; //DSRC
            end
        endcase

        if(by_pass_status[2:0] != 3'b000) begin //不含首位
            //按照旁路规则修改ALU SRCA SRCB DSRC
        end

        else begin
            signal[11:8] <= 4'b0;
        end

        //操作计算ALUOP
        if(Op == 6'b0) begin
            //R-type
            case (inst[5:0])
                6'b100000: signal[24:21] <= `ALU_OP_ADD; //add
                6'b100001: signal[24:21] <= `ALU_OP_ADD; //addu
                6'b100010: signal[24:21] <= `ALU_OP_SUBTRACT; //sub
                6'b100011: signal[24:21] <= `ALU_OP_SUBTRACT; //subu
                default: signal[24:21] <= 6'b0; //nop
            endcase
        end
        else begin
            case (Op)
                6'b001000: signal[24:21] <= `ALU_OP_ADD; //ADDI
                6'b001101: signal[24:21] <= `ALU_OP_BITWISE_OR; //ORI
                6'b001111: signal[24:21] <= `ALU_OP_ADD; //LUI  imm+0
                6'b000100: signal[24:21] <= `ALU_OP_SUBTRACT; //beq
                default: signal[24:21] <= `ALU_OP_ADD; //lw,sw,j
            endcase
        end

    end
    
endmodule


