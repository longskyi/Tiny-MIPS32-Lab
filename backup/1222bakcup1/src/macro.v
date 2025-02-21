
//设计目标，5级流水线，超标量双发射（双流水线），DDRAM

// parameter ALU_AND = 4'b0000;
// parameter ALU_OR  = 4'b0001;
// parameter ALU_XOR = 4'b0010;
// parameter ALU_NOR = 4'b0011;
// parameter ALU_ADD = 4'b0100; //4
// parameter ALU_SUB = 4'b0101; //5
// parameter ALU_SLT = 4'b0110;
// parameter ALU_SLL = 4'b0111;



`define ALU_OP_LOGIC_LEFTSHIFT  4'b0111 // Result = X << Y  逻辑左移
`define ALU_OP_ARITH_RIGHTSHIFT 4'b1000 // Result = X >>> Y 算术右移
`define ALU_OP_LOGIC_RIGHTSHIFT 4'b1001 // Result = X >> Y  逻辑右移
`define ALU_OP_UNSIGNED_MULTIPLY 4'b1010 // Result = (X * Y)[31:0]; Result2 = (X * Y)[63:32] 无符号乘法
`define ALU_OP_UNSIGNED_DIVIDE   4'b1111 // Result = X / Y; Result2 = X % Y 无符号除法
`define ALU_OP_ADD               4'b0100 // Result = X + Y (Set OF/UOF)
`define ALU_OP_SUBTRACT          4'b0101 // Result = X - Y (Set OF/UOF)
`define ALU_OP_BITWISE_AND       4'b0000 // Result = X & Y   按位与
`define ALU_OP_BITWISE_OR        4'b0001 // Result = X | Y   按位或
`define ALU_OP_BITWISE_XOR       4'b0010 // Result = X ⊕ Y   按位异或
`define ALU_OP_BITWISE_NOR       4'b0011 // Result = ~(X | Y) 按位或非
`define ALU_OP_SIGNED_COMPARISON 4'b0110 // Result = (X < Y) ? 1 : 0 符号比较
`define ALU_OP_UNSIGNED_COMPARISON 4'b1100 // Result = (X < Y) ? 1 : 0 无符号比较

//所有指令{add, sub, addi,  lw, sw, beq, j, nop , ori , lui}
//以及 addu subu

//R-type
`define _OP_add  6'b100000
`define _OP_sub  6'b100010
`define _OP_addu 6'b100001
`define _OP_subu 6'b100011

`define _OP_addi 6'b001000
`define _OP_lw   6'b100011
`define _OP_sw   6'b101011
`define _OP_beq  6'b000100
`define _OP_j    6'b000010
`define _OP_ori  6'b001101
`define _OP_lui  6'b001111