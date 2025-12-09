# 操作系统 Lab 5 实验知识点总结与原理对比

## 1. 本实验核心知识点与 OS 原理对应表

| 实验中的知识点 (ucore Lab 5) | OS 原理中的知识点 | 含义、关系与差异理解 |
| :--- | :--- | :--- |
| **User Mode / Kernel Mode** <br> (sstatus 寄存器的 SPP 位) | **特权级 / 双重模式** <br> (Privilege Level) | **含义**: 保护硬件资源，防止用户程序直接破坏内核。<br>**Lab实现**: 通过 RISC-V 的 `sstatus` 寄存器控制。`ecall` 升格到 S 模式，`sret` 降格回 U 模式。<br>**差异**: 实验中通过软件手动构建 `trapframe` 来模拟第一次“返回”用户态（欺骗 CPU）。 |
| **System Call** <br> (syscall.c, ecall, trap.c) | **系统调用** <br> (System Call Interface) | **含义**: 用户程序请求内核服务的接口。<br>**Lab实现**: 使用 `ecall` 指令触发异常 (Cause 8)，传递参数在寄存器 a0-a7。<br>**特殊点**: `kernel_execve` 使用了 `ebreak` (Cause 3) 来模拟内核态发起的系统调用，这是一种非标准的取巧实现，真实 OS 通常不需要在内核态模拟系统调用。 |
| **Process Lifecycle** <br> (alloc, run, wait, exit) | **进程状态机** <br> (Process State Transition) | **关系**: 实验完整实现了 5 状态模型 (New, Ready, Running, Waiting, Terminated)。<br>**Lab实现**: `PROC_RUNNABLE` 对应 Ready, `PROC_ZOMBIE` 对应 Terminated。<br>**差异**: ucore 的 ZOMBIE 状态必须由父进程回收，否则内存泄漏，这与 Linux 机制一致。 |
| **Context Switch** <br> (switch_to, trapframe) | **上下文切换** <br> (Context Switch) | **含义**: 切换 CPU 寄存器状态以运行另一个进程。<br>**Lab实现**: 分为两部分。1. 线程上下文 (`switch_to` 切换内核栈和 callee-saved 寄存器)；2. 中断上下文 (`trapframe` 保存通用寄存器)。<br>**理解**: 进程切换 = 切换到内核态 -> 切换内核栈/PCB -> 切换回用户态。 |
| **Memory Isolation** <br> (load_icode, mm_struct) | **地址空间隔离** <br> (Address Space) | **含义**: 每个进程拥有独立的虚拟地址空间。<br>**Lab实现**: 每个进程有独立的 `mm_struct` 和页表 (`pgdir`)。切换进程时必须切换 `satp` 寄存器（`lsatp`）。<br>**差异**: 内核空间（高于 KERNBASE）在所有进程页表中是共享的，这优化了陷入内核的开销。 |
| **Fork / Exec** <br> (do_fork, load_icode) | **进程创建与加载** | **关系**: 遵循 Unix 经典的 Fork-Exec 模型。<br>**Lab实现**: `fork` 复制内存（目前是深拷贝，Challenge 为 COW），`exec` 替换内存镜像。<br>**特殊点**: 用户程序是作为二进制数据内嵌在内核镜像中的（Linked-in），而不是从磁盘文件系统加载。 |

## 2. OS 原理中重要但本实验未涉及的知识点

1.  **进程间通信 (IPC)**
    * **原理**: 管道 (Pipe)、消息队列、共享内存、信号 (Signal)。
    * **缺失**: Lab 5 中父子进程除了 `wait` 获取 exit_code 外，无法进行数据交换。`kill` 仅仅是设置标志位，并非完整的信号机制。

2.  **文件系统 (File System)**
    * **原理**: 文件的存储、目录结构、inode、磁盘驱动。
    * **缺失**: `execve` 并不是从磁盘加载 ELF 文件，而是从内存的特定位置拷贝。所有的“程序”其实都在内核启动时就存在于 RAM 中了。

3.  **高级调度算法 (Scheduling Algorithms)**
    * **原理**: CFS (完全公平调度), 多级反馈队列, 优先级调度。
    * **缺失**: Lab 5 沿用了简单的 FIFO 或 Stride 调度，没有实现复杂的优先级抢占或多核负载均衡。

4.  **写时复制 (Copy On Write) 的完整支持**
    * **原理**: 优化 fork 性能，延迟内存分配。
    * **现状**: 虽然作为 Challenge 提出，但在基础实验代码中使用的是 `memcpy` 深拷贝，这在实际生产级 OS 中效率极低。

5.  **内核抢占 (Kernel Preemption)**
    * **原理**: 允许高优先级进程中断正在内核态运行的低优先级进程。
    * **缺失**: ucore 目前是不可抢占内核 (Non-preemptive Kernel)，只有在内核主动调用 `schedule` 或返回用户态时才会发生调度。



这份文档整合了你提供的实验资料、代码片段以及 ucore 操作系统中关于用户进程管理的核心知识点。它旨在梳理从内核态到用户态的切换、系统调用的实现机制以及进程生命周期的管理。

-----

# ucore Lab 5 知识点梳理：用户进程管理

## 1\. 核心概念：特权级与执行环境

在 RISC-V 架构下，操作系统利用特权级来实现内核与用户程序的隔离与保护。

### 1.1 三种特权级

  * **M Mode (Machine)**: 最高权限，运行 OpenSBI（固件），负责硬件底层初始化。
  * **S Mode (Supervisor)**: 内核态，ucore 操作系统运行于此。可以执行特权指令，访问所有内存，管理中断。
  * **U Mode (User)**: 用户态，普通应用程序运行于此。
      * 无法直接访问硬件。
      * 无法执行特权指令（如修改页表基址 `satp`，关闭中断等）。
      * **内存受限**：只能访问低于 `USTACKTOP` 的用户地址空间。

### 1.2 穿越特权级的桥梁

  * **U -\> S (陷入内核)**: 通过 `ecall` 指令（Environment Call）。通常用于系统调用。
  * **S -\> U (返回用户)**: 通过 `sret` 指令（Supervisor Return）。CPU 会恢复 `sstatus` 和 `sepc` 寄存器中保存的状态。

-----

## 2\. 第一个用户进程的诞生

在 ucore 启动之初，系统完全运行在 S Mode。为了运行第一个用户进程，我们需要解决“鸡生蛋”的问题：如何从内核态“凭空”创造一个用户态环境？

### 2.1 流程总览

1.  **Init Proc**: 内核启动 `initproc` (pid=1)。
2.  **User Main**: `initproc` 创建内核线程 `user_main`。
3.  **Kernel Execve**: `user_main` 调用 `kernel_execve` 加载用户程序（如 `exit` 或 `hello`）。
4.  **Load Icode**: 解析 ELF 文件，构建用户内存空间，**伪造**一个用户态的中断现场 (`trapframe`)。
5.  **SRET**: 内核执行 `sret`，假装从中断返回，利用伪造的现场跳转到用户程序入口，CPU 降级为 U Mode。

### 2.2 关键实现：`load_icode` 的伪造现场

为了让 CPU 在执行 `sret` 后确信自己应该回到用户态，必须在 `proc_struct->tf` (中断帧) 中设置以下关键信息：

  * **`tf->gpr.sp = USTACKTOP`**: 设置用户栈顶。
  * **`tf->epc = elf->e_entry`**: 设置程序入口地址（`sret` 后 PC 指向这里）。
  * **`tf->status`**: 修改 SSTATUS 寄存器状态。
      * **清零 SPP (Supervisor Previous Privilege)**: 设为 0，表示“之前的特权级是 User Mode”。
      * **置位 SPIE (Supervisor Previous Interrupt Enable)**: 设为 1，表示返回用户态后**开启中断**（允许时间片轮转调度）。

### 2.3 程序的加载位置

由于 Lab 5 尚未实现文件系统，用户程序（如 `exit.c`）是在编译时通过链接脚本 (`user.ld`) 直接链接到内核镜像的数据段中的。

  * 宏 `KERNEL_EXECVE` 使用链接器生成的符号 `_binary_obj___user_exit_out_start` 来定位程序二进制数据。

-----

## 3\. 系统调用 (System Call) 机制

系统调用是用户程序获取内核服务的唯一合法途径。

### 3.1 调用链路

1.  **用户库 (`ulib.c`)**: 用户调用 `fork()`。
2.  **Syscall Wrapper (`syscall.c`)**: 将参数存入寄存器 `a0`\~`a4`，系统调用号存入 `a0`。
3.  **触发异常**: 执行内联汇编 `ecall`。
4.  **Trap Handler (`trapentry.S`)**: 保存用户态寄存器到内核栈 (`trapframe`)。
5.  **分发 (`trap.c` -\> `syscall.c`)**: 根据 `tf->cause` 识别为 `CAUSE_USER_ECALL`，调用 `syscall()`。
6.  **内核实现**: 根据系统调用号（如 `SYS_fork`）执行对应的内核函数（如 `do_fork`）。
7.  **返回**: 结果存入 `tf->gpr.a0`，`sret` 返回用户态。

### 3.2 为什么 `kernel_execve` 使用 `ebreak`？

  * **问题**: `kernel_execve` 是在内核态执行的，如果在 S Mode 下执行 `ecall`，通常代表请求 M Mode 服务（OpenSBI），而不是系统调用。
  * **Hack 方案**: 使用 `ebreak` (断点指令) 触发异常，并在 `a7` 寄存器设置特殊标记 (10)。
  * **处理**: `trap.c` 检测到断点异常且 `a7==10`，手动转发给 `syscall()` 处理。

-----

## 4\. 进程生命周期管理

### 4.1 Fork (创建进程)

  * **功能**: 复制父进程，创建一个几乎完全一样的子进程。
  * **流程**:
    1.  `alloc_proc`: 分配 PCB。
    2.  `setup_kstack`: 分配内核栈。
    3.  `copy_mm`: **关键**。复制内存空间（页表）。
          * **Deep Copy (当前实现)**: 申请新物理页，`memcpy` 复制数据。
          * **COW (Challenge)**: 共享物理页，设为只读。
    4.  `copy_thread`: 复制中断帧和上下文。
          * **返回值差异**: 父进程 `a0` = 子进程 PID；子进程 `tf->gpr.a0` = 0。
    5.  `set_links`: 插入进程链表，设置父子/兄弟指针。

### 4.2 Exec (替换进程)

  * **功能**: 保持 PID 不变，用新程序替换当前进程的内存和代码。
  * **流程**:
    1.  `exit_mmap`: 释放旧的内存空间和页表。
    2.  `load_icode`: 加载新程序，建立新映射，重置 `trapframe`。
    3.  **不返回**: `exec` 成功后不会返回原程序下一行，而是直接开始运行新程序。

### 4.3 Wait (等待子进程)

  * **功能**: 父进程挂起，等待子进程退出，回收子进程剩余资源（PCB 和 内核栈）。
  * **状态转换**:
      * 若有 ZOMBIE 子进程 -\> 立即回收，返回。
      * 若有运行中子进程 -\> 设置状态 `PROC_SLEEPING`，`wait_state = WT_CHILD`，调用 `schedule()`。

### 4.4 Exit (进程退出)

  * **功能**: 进程结束运行，释放大部分资源。
  * **流程**:
    1.  `mm_destroy`: 释放页目录、虚拟内存。
    2.  状态变为 `PROC_ZOMBIE`。
    3.  **父子过继**: 将自己的所有子进程过继给 `initproc`（确保孤儿进程有人收尸）。
    4.  `wakeup_proc`: 唤醒父进程（如果是 `WT_CHILD` 状态）。
    5.  `schedule()`: 主动让出 CPU，进程虽然还在（PCB还在），但不再执行。

-----

## 5\. 内存管理细节

### 5.1 内存复制 (`copy_range`)

在 `fork` 时，内核需要处理父子进程的内存复制。

  * **输入**: 父进程页表，子进程页表，地址范围。
  * **逻辑**: 遍历父进程的每一页，如果有效：
    1.  `alloc_page()` 为子进程分配新物理页。
    2.  `page2kva()` 获取内核虚拟地址（因为无法直接操作物理地址）。
    3.  `memcpy()` 拷贝一整页数据 (4KB)。
    4.  `page_insert()` 建立子进程虚实映射。

### 5.2 栈的处理

用户进程有两个栈：

1.  **用户栈 (User Stack)**: 位于 `USTACKTOP` 之下，用于用户态函数调用、局部变量。在 `load_icode` 中建立映射。
2.  **内核栈 (Kernel Stack)**: 位于 `proc->kstack`，大小 8KB。
      * **用途**: 当进程从用户态陷入内核态（中断/系统调用）时，CPU 必须切换到安全的内核栈来保存上下文。
      * **切换机制**: `trapentry.S` 中利用 `sscratch` 寄存器协助 `sp` 指针在用户栈和内核栈之间切换。

-----

## 6\. 核心数据结构关系图

```text
proc_struct (PCB)
├── pid, name, state
├── mm_struct (内存管理)
│   ├── vma_struct (虚拟内存区域链表: 代码段, 数据段, 栈)
│   └── pgdir (页目录表物理地址 -> SATP)
├── trapframe (中断帧: 保存用户态寄存器)
│   ├── gpr (通用寄存器 x0-x31)
│   ├── sepc (异常发生地址/返回地址)
│   └── sstatus (状态寄存器)
├── context (内核上下文: 用于内核线程切换)
│   ├── ra (返回地址)
│   └── sp (内核栈顶)
└── parent, cptr, yptr, optr (家族关系指针)
```

## 7\. 常见问题总结

1.  **为什么 fork 返回两次？**

      * `fork` 实际上是让父进程继续运行，同时创建了一个子进程。
      * 父进程从系统调用返回，返回值是子进程 PID。
      * 子进程被调度运行时，它的上下文是父进程的副本，且内核强制将其 `a0` 寄存器置为 0，所以它也“返回”了，返回值是 0。

2.  **什么是僵尸进程 (Zombie)？**

      * 进程调用 `exit` 后，内存被释放，无法运行，但 `proc_struct` 和内核栈还保留在内存中，等待父进程读取其退出码 (`exit_code`)。
      * 如果父进程不调用 `wait`，这些僵尸进程会一直占用内核资源（内存泄漏）。

3.  **用户态能直接调用 `cprintf` 吗？**

      * 不能。`cprintf` 底层需要访问串口硬件或调用 SBI，这是特权操作。
      * 用户态库函数 `cprintf` 实际上是将字符串格式化后，通过 `SYS_putc` 系统调用委托内核打印的。