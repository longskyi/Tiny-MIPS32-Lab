# Tiny-MIPS32-Lab
XJTU-COMP450905  2024年秋
西安交通大学-计算机组成与结构专题实验  
期末用一坤天设计的MIPS32-CPU

---
### 支持的汇编指令MIPS32
`add` | `sub` | `addi` | `addu` | `subu` | `lw` | `sw` | `beq` | `j` | `nop` | `lui` | `ori`
### 设计指标
- **架构特性**
  - 五级流水线
  - 双发射超标量
  - 旁路数据前推
  - "总是不采用"分支预测方法
- **限制说明**
  - 不包含中断处理
  - 不处理所有异常（如：lw/sw非对齐访问异常、add溢出异常）

### 设计经过
1. 花了2小时认真学习了计组第六第七章，计组书具有很大参考价值。  
2. 进一步学习vivado verilog，了解阻塞赋值与非阻塞赋值与流水线。
3. 确定各个模块的IO指标（即设计数据通路）  
---
设计顺序：ROM-RAM-RegFile-EX-ID  
RAM使用DDR的思路，RAM内部有一个小流水线。
RegFile支持4异步读2同步写。
### 声明
仅是一个很小的课程实验产物，不保证运行正确性，不要直接使用。
use at your own risk  


