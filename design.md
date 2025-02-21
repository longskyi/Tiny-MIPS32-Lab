### 支持的汇编指令
add, sub, addi, addu, subu, lw, sw, beq, j, nop ,lui , ori


R-type
add rd,rs,rt    :   rd <- (rs) + (rt)
sub rd,rs,rt    :   rd <- (rs) - (rt)

溢出需要进入中断处理 --- 不支持


I-type

addi rt,rs,immm :   rt <- (rs) + immm (有符号扩展)

lw rt,offset(rs) :  rt <- ROM[offset+(rs)]
sw rt,offset(rs) :  ROM[offset+(rs)] <- rt

sw和lw都要求4字节对齐，否则需要进入中断处理

beq rs,rt,offset if(rs==rt) ip <- ip+(offsetx4) offset是指令为单位的，所以实际上要x4（32位）

j target 无条件跳转到target（26位）
当前指令高8位和后26位拼接

NOP 空指令


设计目标：
5级流水线(FI指令获取并解码,ID读寄存器,EX使用ALU,MA读写RAM,WB写寄存器)
静态分支预测
超标量，双发射（双流水线）暂不考虑乱序执行

数据冒险 采用后推
控制冒险 采用分支预测（总是为真）



分支预测考虑

beq指令
FI->ID->ALU->获得结果   下一条指令
    FI->ID -> ALU -> MA

只需要在获得结果的时候，发信号，清空流水线，恢复信号，修改IP，因为下一个流水线还没有修改任何可见东西。


控制信号

ROM读写能力 一次读2个指令的能力

RAM读写能力

1个时钟周期内支持2个操作  （使用）DDR

双ALU

寄存器读写能力
支持4读2写



解码时候的资源占用情况分析方式

FI实时信号

input ex_setPC,
input wire [31:0] ex_PC,


FI交付
output [31:0] out_PC1,   // 第一条指令输出时的PC(即指向第二条指令开始位置)  
output [31:0] out_PC2,   // 第一条指令输出时的PC(即指向第二条指令开始位置)  
output [31:0] inst_1,  // 第一条指令输出  
output [31:0] inst_2  // 第二条指令输出  


EX需求信号  
input [31:0] src0,src1,src2,src3,  
input [31:0] PC1,PC2,  
input [31:0] imm1,imm2,  
input [1:0] PCSRC1,PCSRC2,                //00不更改PC，01使用beq（PC+ sigext(imm1) << 2），10使用j（pc高4位 拼接 26位target 拼接 00）  
input exsign1,exsign2,  
input [1:0] ALU1_SRCA,ALU1_SRCB,  
input [1:0] ALU2_SRCA,ALU2_SRCB,  
input [3:0] ALU_OP1,ALU_OP2,  
                                    //SRCA1  01： 使用src0寄存器  00：使用32’b0                                 11:使用src_by_0  
                                    //SRCB1  01： 使用src1寄存器  00：使用32’b0  10：使用sigext16(imm1)符号扩展  11:使用src_by_0  
                                    //SRCA2  01： 使用src2寄存器  00：使用32’b0                                 11:使用src_by_1  
                                    //SRCB2  01： 使用src3寄存器  00：使用32’b0  10：使用sigext16(imm2)符号扩展  11:使用src_by_1  


EX输出实时信号
output reg set_PC,  
output reg [31:0] ex_PC,  
output reg clear_pipeline2,//如果beq/j在第1条流水线上，则要清空第2条流水线内容 实际上如果第一条是j，第二条就不应该进内容  


DRAM需求内容

input [31:0] Data1in, Data2in,  // 数据输入输出复用  
input [31:0] Addr1, Addr2,  // 地址输入  
input R_W1, R_W2,           // 双流水线读写信号，0写1读  
input CS1,CS2,                   // 使能信号  
input SRC1,SRC2,    //暂时保留，赋值为z  


WB需求内容  
input W1E, W2E,    
input [ADDR_SIZE-1:0] WAddr1, WAddr2,（寄存器编号2^5）  
input [`DATA_WIDTH-1:0] WData1, WData2,  


单条流水线需要的信号  
PCSRC ， exsign （都赋值1），ALUSRCA，ALUSRCB，ALUOP，CS，DSRC（都赋值0），R_W, W1E , WTARGET  

单条流水线需要的数据  
src0,src1,imm1,sw要写入的数据（唯一不交付给ex），  