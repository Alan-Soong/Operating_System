# 操作系统lab4实验报告
<center><p><font face="黑体" size=7><b>操作系统lab4实验报告</b></font></p></center>
<center><p><font face="楷体" size=4>姓名：宋卓伦，赵雨萱，何立烽&nbsp;&nbsp;&nbsp;&nbsp;学号：2311095，2311100，2311101</font></p></center>
<center><p><font face="楷体" size=4>南开大学计算机学院、密码与网络空间安全学院</font></p></center>
<!-- <br> -->  

## 实验名称：进程管理
对实验报告的要求：  
基于markdown格式来完成，以文本方式为主  
填写各个基本练习中要求完成的报告内容  
列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）  
列出你认为OS原理中很重要，但在实验中没有对应上的知识点  

## 练习0：填写已有实验

本实验依赖于 Lab 2 的物理内存管理和 Lab 3 的中断处理。我们已将之前实验中编写并测试通过的代码复制至本实验的对应位置。

-----

## 练习1：分配并初始化一个进程控制块

### 1\. 设计实现过程

`alloc_proc` 函数的主要职责是创建一个新的 `struct proc_struct` 结构体并进行初步初始化。这个结构体是操作系统管理进程/线程的核心数据结构（PCB）。

实现步骤如下：

1.  调用 `kmalloc` 分配一块内存空间给 `proc_struct`。
2.  检查分配是否成功。如果成功，我们立即调用 `memset` 将整块内存清零。这里主要是为了避免未初始化的脏数据导致的不可预见错误。
3.  初始化必要的成员变量以满足 `proc_init` 中的断言检查：
      * `proc->state = PROC_UNINIT;`：标记状态为未初始化。
      * `proc->pid = -1;`：标记尚未分配有效的 PID。
      * `proc->pgdir = boot_pgdir_pa;`：对于内核线程，它们共享内核的地址空间，因此页目录表基址设置为内核页表的物理地址。


<!-- end list -->

```c
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        memset(proc, 0, sizeof(struct proc_struct));
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->pgdir = boot_pgdir_pa; 
    }
    return proc;
}
```

### 2\. 问题回答

> 请说明 proc\_struct 中 struct context context 和 struct trapframe \*tf 成员变量含义和在本实验中的作用是啥？

  * **`struct context context` (进程上下文)**

      * **含义**：保存了进程在**主动**进行上下文切换（即调用 `switch_to` 函数）时的 CPU 寄存器状态。主要包括被调用者保存（callee-saved）的寄存器（如 `ra`, `sp`, `s0-s11`）。
      * **作用**：当内核决定挂起当前进程并运行另一个进程时，会调用 `switch_to`。此时，当前进程的执行现场会被保存在其 PCB 的 `context` 中；而下一个进程的 `context` 会被加载到 CPU 中，从而恢复其之前的执行现场。在线程创建时，我们将 `context.ra` 设置为 `forkret` 的地址，使得新线程第一次被切换到时能够从 `forkret` 开始执行。

  * **`struct trapframe *tf` (中断帧指针)**

      * **含义**：指向内核栈顶的一个结构体，用于保存进程在发生**被动**切换（如中断、异常、系统调用）时的完整 CPU 状态（包括所有通用寄存器、`epc`, `sstatus` 等）。
      * **作用**：
        1.  在正常运行中，当发生中断时，硬件和软件（trapentry.S）会将现场保存到 `tf` 指向的内核栈位置，以便中断处理完成后恢复。
        2.  **在本实验中的关键作用**：在创建新线程时，我们通过 `copy_thread` 函数“伪造”了一个中断帧放在新线程的内核栈顶。我们设置 `tf->epc` 指向线程的入口函数（`kernel_thread_entry`）。当新线程第一次被调度运行时，它会经由 `switch_to` -\> `forkret` -\> `__trapret` 的路径，最终从这个伪造的中断帧中“恢复”现场，从而跳转到 `kernel_thread_entry` 开始执行实际的线程代码。

-----

## 练习2：为新创建的内核线程分配资源

### 1\. 设计实现过程

`do_fork` 是创建新线程的核心函数。负责克隆父进程

实现步骤：

1.  **分配 PCB**：调用 `alloc_proc()` 获得一个新的 `proc_struct`。
2.  **分配内核栈**：调用 `setup_kstack(proc)` 为新线程分配 2 个物理页作为内核栈。
3.  **复制内存信息**：调用 `copy_mm(clone_flags, proc)`
4.  **设置线程上下文**：调用 `copy_thread(proc, stack, tf)`。它在内核栈顶设置了中断帧，并设置了 `proc->context`，使得 `context.ra` 指向 `forkret`，`context.sp` 指向新的内核栈顶。
5.  **加入进程管理结构**：
      * 调用 `get_pid()` 为新线程分配一个唯一的 PID。
      * 将新线程加入全局哈希表 `hash_list`。
      * 将新线程加入全局进程链表 `proc_list`。
      * 进程总数 `nr_process` 加 1。
6.  **唤醒新线程**：调用 `wakeup_proc(proc)`，将其状态设置为 `PROC_RUNNABLE`，使其可以被调度器选中。
7.  **返回 PID**：函数成功执行，返回新线程的 PID。


### 2\. 问题回答

> 请说明 ucore 是否做到给每个新 fork 的线程一个唯一的 id？请说明你的分析和理由。

  * **ucore 能够保证 PID 的唯一性。**
  * **分析**：PID 的分配由 `get_pid()` 函数完成。该函数内部维护了两个静态变量：`last_pid`（上一次分配的 PID）和 `next_safe`（下一个可能冲突的 PID 边界）。
      * 每次调用时，`last_pid` 会自增。
      * 如果 `last_pid` 达到 `MAX_PID`，它会回绕到 1。
      * **关键点**：当 `last_pid` 大于等于 `next_safe` 时，函数会遍历整个 `proc_list` 链表，检查当前的 `last_pid` 是否已被占用。如果被占用，就继续自增尝试下一个；同时，它会计算出一个新的 `next_safe` 值（即大于当前 `last_pid` 的最小的已占用 PID），在 `last_pid` 到达 `next_safe` 之前，都不需要再次遍历链表。
      * 这种机制确保了即使 PID 回绕，也能跳过那些仍在使用的 PID，从而保证分配出的 PID 在当前系统中是唯一的。

-----

## 练习3：编写 proc\_run 函数

### 1\. 设计实现过程

`proc_run` 函数负责将 CPU 的使用权从当前进程（`current`）切换到指定的进程（`proc`）。

实现步骤：

1.  **检查**：判断 `proc` 是否已经是 `current`，如果是则无需切换。
2.  **关中断**：调用 `local_intr_save(intr_flag)`。这是为了保证上下文切换过程的原子性，防止在切换了一半时被中断打断导致状态不一致。
3.  **切换当前进程指针**：`current = proc;`。
4.  **切换页表**：调用 `lsatp(proc->pgdir)`。将新进程的页表基址加载到 `satp` 寄存器，完成地址空间的切换（虽然内核线程共享内核地址空间，但该操作对于未来实现用户进程至关重要）。
5.  **切换上下文**：调用 `switch_to(&(prev->context), &(current->context))`。这会保存当前寄存器状态到 `prev->context`，并从 `current->context` 恢复寄存器状态。
6.  **开中断**：调用 `local_intr_restore(intr_flag)`。注意，这行代码实际上是由**下一次**该进程被调度回来时执行的。

### 2\. 问题回答

> 在本实验的执行过程中，创建且运行了几个内核线程？

  * **在本实验中，创建且运行了 2 个内核线程。**
    1.  **`idleproc` (PID 0)**：这是第 0 个内核线程，在 `proc_init` 中手工创建。它代表了 CPU 空闲时的状态，其执行函数是 `cpu_idle`，在一个无限循环中不断检查是否需要调度。
    2.  **`initproc` (PID 1)**：这是第 1 个内核线程，在 `proc_init` 中通过调用 `kernel_thread` 创建。它的执行函数是 `init_main`，负责打印 "Hello World" 等信息。

-----

## 扩展练习 Challenge

### 1\. 中断开关实现机制

> 说明语句 local\_intr\_save(intr\_flag);....local\_intr\_restore(intr\_flag); 是如何实现开关中断的？

这两个宏定义在 `kern/sync/sync.h` 中，它们通过操作 RISC-V 的控制状态寄存器（CSR）`sstatus` 来实现。

  * **`local_intr_save(x)`**:
      * 它首先使用 `read_csr(sstatus)` 读取当前的 `sstatus` 寄存器值，并将其保存到变量 `x` 中。这一步是为了记录下“关中断之前”的中断使能状态（SIE 位）。
      * 然后，它使用 `clear_csr(sstatus, SSTATUS_SIE)` 指令清除 `sstatus` 寄存器中的 `SIE`（Supervisor Interrupt Enable）位。硬件一旦检测到 `SIE` 位被清零，就会屏蔽所有可屏蔽中断。
  * **`local_intr_restore(x)`**:
      * 它使用 `write_csr(sstatus, x)` 将之前保存的 `sstatus` 值（包含原来的 SIE 状态）写回寄存器。
      * 如果之前 SIE 是 1，那么写回后中断就被重新使能；如果之前本来就是 0，那么写回后依然保持关闭。这实现了对中断状态的精确还原，支持了中断开关的嵌套使用。

### 2\. 分页模式原理 (get\_pte)

> get\_pte() 函数中有两段形式类似的代码， 结合 sv32，sv39，sv48 的异同，解释这两段代码为什么如此相像。

  * **相似原因**：RISC-V 的 Sv32、Sv39、Sv48 分页模式都采用了**多级页表**结构。
      * Sv32 是二级页表（PD -\> PT）。
      * Sv39 是三级页表（PDX1 -\> PDX0 -\> PT）。
      * Sv48 是四级页表。
  * **代码逻辑**：无论分多少级，每一级的查找逻辑都是相同的：
    1.  根据虚拟地址的某一部分（VPN[i]）作为索引，在当前级页表中找到对应的页表项（PTE）。
    2.  检查该 PTE 的有效位（V位）。
    3.  如果无效且需要创建（`create=1`），则分配一个新的物理页作为下一级页表，并更新当前 PTE 指向它。
    4.  如果有效，则根据 PTE 中的物理页号（PPN）找到下一级页表的基址。
  * 在 uCore 的 Sv39 实现中，`get_pte` 需要先查找一级页目录，再查找二级页目录，最后找到三级页表。前两步的“查找或创建下一级”的代码逻辑是完全一致的，因此看起来非常相像。

> 目前 get\_pte() 函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

  * **观点：这种写法是可接受的，且在内核开发中很常见。**
  * **优点 (Good)**：
      * **便利性**：大多数时候，内核调用 `get_pte` 都是为了进行地址映射（`page_insert`），这意味着如果路径不存在，就必须创建。合在一起可以减少重复代码，简化调用者的逻辑。
      * **效率**：避免了先调用“查找”函数发现失败，再调用“创建”函数重新遍历一次页表的开销。
  * **缺点/拆开的必要性 (Bad/Trade-off)**：
      * **单一职责原则**：从软件工程角度，函数职责略显混杂。
      * 如果存在大量“仅查询，绝对不允许创建”的场景，拆开可能会更安全，避免错误的 `create=1` 传参导致意外的内存分配。
  * **结论**：在 uCore 当前的场景下，合并写法在实用性和简洁性上占优。
