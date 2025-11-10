### 1. 内存虚拟化 

这是所有高级功能的基础，目标是提供内存的**抽象**与**保护**。

* **核心原理：虚拟内存**
    * **目标**：为每个进程提供一个独立的、连续的地址空间，实现进程间内存隔离和访问保护。
    * **实现**：通过**多级页表 (Multi-Level Page Tables)** 机制，将虚拟地址 (VA) 映射到物理地址 (PA)。
* **Sv39 页表规范 (RISC-V)**
    * 这是一个 3 级页表结构，虚拟地址被分为：
        * `PDX1` (9位): 1 级页目录索引
        * `PDX0` (9位): 2 级页目录索引
        * `PTX` (9位): 最终页表索引
        * `PGOFF` (12位): 页内偏移
    * **页表项 (PTE)**：PTE 是页表的核心，它存储了物理页号 (PPN) 和一系列标志位。
    * **关键标志位**：
        * `PTE_V` (Valid): 页表项是否有效。
        * `PTE_R`/`W`/`X` (Read/Write/Execute): 权限位，硬件据此进行访问保护。
        * `PTE_U` (User): 标记该页是否允许用户态（U-Mode）访问。
* **关键函数 (PMM)**
    * **`get_pte(pgdir, la, create)`**：
        * **核心功能**：遍历多级页表，查找虚拟地址 `la` 对应的**最终 PTE 的地址**。
        * `create=1` ：如果遍历过程中发现下一级页表不存在（`PTE_V = 0`），它会自动分配一个新页作为下一级页表，并更新当前 PTE 指向它。这是实现按需分配页表（而非一次性分配所有）的关键。
    * **`page_insert` / `page_remove`**：
        * 基于 `get_pte` 提供的上层 API，用于建立和解除一个物理页 `struct Page` 和一个虚拟地址 `la` 之间的映射关系，并正确维护页的引用计数 `page_ref`。

---

### 2. 中断与异常处理


* **核心原理：软件与硬件协同**
    * **硬件 (CPU)**：负责**发现**事件（如时钟中断、非法指令、缺页）。
    * **软件 (OS)**：负责**处理**事件。
* **第一阶段：硬件自动处理（陷阱发生时）**
    1.  **保存现场（部分）**：硬件自动将关键寄存器保存到 CSRs 中：
        * `sepc`：保存被中断的指令地址 (PC)。
        * `scause`：保存陷阱的原因（是中断还是异常？具体类型？）。
        * `stval`：保存导致异常的地址（如缺页时的坏地址）。
    2.  **切换特权级**：
        * 将**当前特权级**（如 U-Mode）保存到 `sstatus.SPP`。
        * 将**当前中断使能**状态 (`sstatus.SIE`) 保存到 `sstatus.SPIE`。
    3.  **关闭中断**：硬件**自动清除 `sstatus.SIE` 位**，防止在处理陷阱时被新的中断打断。
    4.  **跳转**：CPU 跳转到 `stvec` 寄存器指向的地址，在 uCore 中，该地址被设置为 `__alltraps`。
* **第二阶段：软件接管（`__alltraps`）**
    1.  **保存现场（全部）**：执行汇编宏 `SAVE_ALL`。
        * **目的**：保存所有硬件没有自动保存的**通用寄存器**（x1-x31）。
        * **方式**：在当前栈顶分配空间，创建一个 `struct trapframe`（中断帧），并将所有寄存器（包括从 `sepc` 等 CSR 读出的值）存入该结构体。
    2.  **调用 C 函数**：将 `sp`（即 `trapframe` 的地址）作为参数，调用 C 语言的 `trap()` 函数。
    3.  **分发与处理**：`trap()` 函数根据 `scause` 的值，将陷阱分发给 `interrupt_handler`（中断）或 `exception_handler`（异常）。
    4.  **返回**：C 函数处理完毕后返回到汇编。
* **第三阶段：软件返回（`__trapret`）**
    1.  **恢复现场（全部）**：执行 `RESTORE_ALL`（`SAVE_ALL` 的逆操作）。
        * 从栈顶的 `trapframe` 中，将所有值加载回通用寄存器和 `sepc`, `sstatus` 等 CSR。
    2.  **执行 `sret`**：
        * `sret` 指令会**原子地**执行以下操作：
        * PC $\leftarrow$ `sepc`（跳转回被中断的地方）。
        * 特权级 $\leftarrow$ `sstatus.SPP`（从 S-Mode 降回 U-Mode）。
        * `sstatus.SIE` $\leftarrow$ `sstatus.SPIE`（**重新打开中断**）。
* **时钟中断 (Clock Interrupt)**
    * **触发三要素**：必须同时满足以下三个条件，CPU 才会响应时钟中断：
        1.  `sstatus.SIE = 1`：（S-Mode）全局中断使能。
        2.  `sie.STIP = 1`： supervisor 级时钟中断使能。
        3.  `sip.STIP = 1`： supervisor 级时钟中断挂起（由 OpenSBI 在定时器到期时设置）。
    * **处理**：`interrupt_handler` 中对应的 `case` 会调用 `clock_set_next_event()` 来设置**下一次**中断，并增加 `ticks` 计数器。
* **特权级与委托**
    * **默认**：所有陷阱（Interrupt/Exception）默认都由最高特权级 M-Mode 处理。
    * **委托 (Delegation)**：M-Mode（OpenSBI）为了效率，会通过 `medeleg` 和 `mideleg` 寄存器，将大部分来自 S-Mode 和 U-Mode 的陷阱**委托 (delegate)** 给 S-Mode 处理。这就是为什么 `stvec`（S-Mode 陷阱向量）会生效。
    * **主动陷入 (Ecall)**：
        * U-Mode `ecall` $\rightarrow$ S-Mode（系统调用）。
        * S-Mode `ecall` $\rightarrow$ M-Mode（如 `sbi_set_timer`，向 OpenSBI 请求服务）。

---

### 3. CPU 虚拟化 

让多个执行流（线程）分时共享 CPU。

* **核心原理：上下文切换 (Context Switch)**
    * **进程控制块 (PCB)**：使用 `struct proc_struct` 来描述一个线程。它包含了线程的所有信息，如 `pid`、`state`、`kstack`（内核栈地址）以及两个最关键的上下文：
        1.  **`struct trapframe *tf`**：**中断上下文**。用于处理**被动**（非自愿）的 CPU 控制权转移（如中断、异常）。它保存在内核栈顶，包含**所有**寄存器。
        2.  **`struct context context`**：**切换上下文**。用于**主动**（自愿）的 CPU 控制权转移（即调用 `schedule()`）。它只包含**被调用者保存 (callee-saved)** 的寄存器（`ra`, `sp`, `s0-s11`），因为调用者保存的寄存器由编译器在函数调用时自动处理。
* **线程创建 (The "Magic")**
    * 当 `kernel_thread` 调用 `do_fork` 创建新线程 `initproc` 时，`copy_thread` 函数会执行“魔法”般的初始化：
    1.  **伪造 `context`**：设置 `initproc->context.ra = (uintptr_t)forkret`。
    2.  **伪造 `trapframe`**：在 `initproc` 的内核栈顶创建一个 `tf`，并设置 `initproc->tf->epc = (uintptr_t)kernel_thread_entry`。
* **线程的首次运行 (The "Magic" Unfolds)**
    1.  `idleproc` (PID 0) 运行 `cpu_idle()`，调用 `schedule()`。
    2.  `schedule()` 决定运行 `initproc` (PID 1)，于是调用 `proc_run(initproc)`。
    3.  `proc_run()` 调用 `switch_to(&(idleproc->context), &(initproc->context))`。
    4.  `switch_to` (汇编) 执行：
        * 保存 `idleproc` 的 `ra`, `sp`, `sX` 到 `idleproc->context`。
        * 从 `initproc->context` 加载 `ra`, `sp`, `sX`。
        * 执行 `ret` 指令。
    5.  `ret` 指令会跳转到 `ra` 寄存器中保存的地址，也就是我们伪造的 **`forkret`**。
    6.  `forkret` (汇编) 执行：
        * `move sp, a0`：`switch_to` 切换时，`initproc->context.sp`（即 `a0`）指向伪造的 `trapframe`。此举将 `sp` 设置为 `trapframe` 的地址。
        * `j __trapret`：跳转到通用的陷阱返回代码。
    7.  `__trapret` (汇编) 执行：
        * 执行 `RESTORE_ALL`，从栈顶（即伪造的 `trapframe`）中恢复所有寄存器。
        * 执行 `sret`。
    8.  `sret` 指令会跳转到 `sepc` 寄存器中保存的地址，也就是我们伪造的 **`kernel_thread_entry`**。
    9. `kernel_thread_entry` (汇编) 执行：
        * `jalr s0`：跳转到 `s0` 寄存器中保存的函数地址，也就是 `init_main`。
    10. `init_main` (C 函数) 开始执行，打印 "Hello World"。