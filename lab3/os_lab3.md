# 操作系统lab3实验报告
<center><p><font face="黑体" size=7><b>操作系统lab3实验报告</b></font></p></center>
<center><p><font face="楷体" size=4>姓名：宋卓伦，赵雨萱，何立烽&nbsp;&nbsp;&nbsp;&nbsp;学号：2311095，2311100，2311101</font></p></center>
<center><p><font face="楷体" size=4>南开大学计算机学院、密码与网络空间安全学院</font></p></center>
<!-- <br> -->  

## 实验名称：中断与中断处理
对实验报告的要求：  
基于markdown格式来完成，以文本方式为主  
填写各个基本练习中要求完成的报告内容  
列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）  
列出你认为OS原理中很重要，但在实验中没有对应上的知识点  

### 练习1：完善中断处理 （需要编程）
请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

### 扩展练习 Challenge1：描述与理解中断流程
回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

### 扩增练习 Challenge2：理解上下文切换机制
回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？
  
#### 在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

```asm
csrw sscratch, sp
```

* 含义：将当前栈指针 `sp` 写入 CSR `sscratch`。
* 目的：当陷入异常时，硬件不会自动保存原先的 `sp`，
所以我们人为地在陷入开始时，把“陷入前的内核栈顶”放到 `sscratch` 中，以备后续使用。    
```asm
csrrw s0, sscratch, x0
```

* 含义：
  这是一个**原子交换（read-write）**指令，执行以下动作：
  1. 读出 `sscratch` 当前的值（也就是先前保存的 `sp`），放入 `s0`
  2. 将 `x0`（即 0）写回 `sscratch`

所以执行完后：

* `s0` ← 原来的 `sp`（陷入前的栈指针）
* `sscratch` ← 0  

**这两条指令配合的意图： 在陷入时保存并识别异常来源。**

1. **保存原栈指针（sp）**

   * 进入 trap 时立即保存 `sp` 到 `sscratch`
   * 避免后续切换栈或压栈时破坏原值

2. **区分异常来源（内核 or 用户态）**

   * 如果下一次异常发生时 `sscratch == 0`，说明当前已经在内核态（因为上一次 trap 已经清空了 `sscratch`）
   * 如果 `sscratch != 0`，说明是用户态 trap（因为用户态不会写 `sscratch`）

这是一种经典的 **递归陷入检测** 设计技巧。

---

#### save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？  

在 `SAVE_ALL` 里保存这些寄存器：

```asm
csrr s1, sstatus
csrr s2, sepc
csrr s3, sbadaddr
csrr s4, scause
STORE s1, 32*REGBYTES(sp)
STORE s2, 33*REGBYTES(sp)
STORE s3, 34*REGBYTES(sp)
STORE s4, 35*REGBYTES(sp)
```

这些寄存器内容是 **陷入现场的信息**：

| CSR                  | 含义                   |
| -------------------- | -------------------- |
| `sstatus`            | 陷入前的状态寄存器（中断开关、特权级等） |
| `sepc`               | 陷入前的 PC（返回地址）        |
| `sbadaddr` / `stval` | 异常相关的错误地址            |
| `scause`             | 异常原因（如非法指令、中断类型等）    |

这些信息是 **trap 处理函数（即 `trap()` C 函数）需要读取的内容**。

> `SAVE_ALL` 保存它们的目的是 **把陷入现场完整封装在 trapframe（栈帧）中**，
> 以便 C 语言的 `trap()` 函数能直接读取这些字段（如 `tf->scause`, `tf->stval`）。

---

 `RESTORE_ALL` 不需要恢复它们，因为这些 CSR 是**只在陷入时有意义的状态信息**：

* 它们描述的是“上一次 trap 的原因和现场”；
* 当 trap 处理完毕要返回时（通过 `sret`），硬件只关心两样东西：

  * `sstatus` — 处理完后恢复的状态（是否重新启用中断、回到哪个特权级）
  * `sepc` — 返回的 PC 地址（从哪继续执行）  

  而像 `stval`、`scause` 是只读的 trap 诊断信息，不影响程序恢复执行。  
---
### 扩展练习Challenge3：完善异常中断
编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。