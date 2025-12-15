# lab5 GDB调试

> Debugged by Lifeng He (何立烽)

## 一、 调试流程与 QEMU 源码关键流程分析
### 1. `ecall` 指令的处理 (从用户态陷入内核)**调试现象：**

* **触发点**：用户程序执行 `ecall`。
* **Guest GDB**：单步执行 `ecall` 后，瞬间跳转到内核入口 `__alltraps`。
* **Host GDB**：在 `riscv_cpu_do_interrupt` 处捕获。
* **关键变化**：观察到 `env->priv` 从 `0` (User) 变为 `1` (Supervisor)。

**QEMU 源码分析 (`target/riscv/cpu_helper.c`)：**
`riscv_cpu_do_interrupt` 是处理异常的核心函数。对于 `ecall` (Cause 8)，关键流程如下：

1. **委托检查 (Delegation)**：QEMU 检查 `medeleg` 寄存器。如果是用户态系统调用，通常委托给 S 模式处理。
2. **上下文保存**：
* `env->sepc = env->pc`：将发生异常的指令地址（`ecall` 的地址）保存到 `sepc`。
* `env->scause = cause`：将原因（8）写入 `scause`。
* `env->stval = 0`：对于 `ecall`，这个寄存器通常置 0。


3. **状态更新**：
* `s = env->mstatus`：读取当前状态。
* `riscv_cpu_set_mode(env, PRV_S)`：**核心一步**，直接修改结构体中的 `priv` 变量，这就完成了特权级切换。
* `env->pc = ...`：将 PC 指针修改为 `stvec` (中断向量表基址)，从而让 Guest CPU 跳转到内核的中断处理程序。



### 2. `sret` 指令的处理 (从内核态返回用户态)

**关键流程分析 (`target/riscv/op_helper.c` -> `helper_sret`)：**
当 uCore 执行 `sret` 时，QEMU 会调用辅助函数 `helper_sret`：

1. **权限检查**：确保当前至少在 S 模式，否则触发非法指令异常。
2. **恢复特权级**：读取 `sstatus` 中的 `SPP` 位（Previous Privilege）。如果之前是用户态，这里 `SPP` 应该是 0。
3. **模式切换**：调用 `riscv_cpu_set_mode(env, prev_priv)`，将 `env->priv` 改回 0。
4. **恢复 PC**：`env->pc = env->sepc`。将 PC 设置为之前保存的 `ecall` 的下一条指令地址。

---

## 二、 指令翻译 (TCG Translation) 与双重 GDB 的联系
### 1. TCG 的角色QEMU 不是像解释器那样逐条“读指令 -> 执行指令”，而是使用 **TCG (Tiny Code Generator)** 进行 **JIT (即时编译)**：

* **翻译阶段**：它把 RISC-V 的汇编指令翻译成中间码 (TCG Ops)，然后再编译成你宿主机 (x86_64) 的机器码。
* **执行阶段**：CPU 直接执行这些编译好的 x86 代码。

### 2. 为什么需要 Helper Function？* 对于 `add`, `sub` 这种简单指令，TCG 直接生成对应的 x86 加减法指令，速度很快。
* 对于 `ecall`, `sret` 这种**涉及特权级切换、中断、修改系统状态**的复杂指令，TCG 无法简单翻译。因此，它生成的代码是**“调用一个 C 语言函数”**（即 `helper_riscv_do_interrupt` 或 `helper_sret`）。
* 这就是为什么我们能在 Host GDB 中对 C 函数打断点并捕获 Guest 的行为。

### 3. 与 Lab 2 (地址翻译) 实验的联系**是的，它们本质相同！**

* 在 Lab 2 中，我们调试的 `get_physical_address` 也是一个 **Helper Function**。
* 当 Guest CPU 执行 `load/store` 指令时，TCG 会先查软 TLB。如果 TLB 没命中 (Miss)，TCG 生成的代码就会调用 C 函数去查页表。
* **结论**：双重 GDB 实验的核心，就是通过拦截 QEMU 的 **Helper Function**，来观察软件如何模拟硬件的复杂行为（MMU 查表、中断处理）。

---

## 三、 抓马细节与模拟器知识
### 1. 抓马瞬间 (Drama Moments)
* **“幽灵断点”**：在 Guest GDB 已经把 `syscall` 设了断点，但因为程序跑的是 `cowtest` 而不是 `exit`，导致符号表不匹配，GDB 以为没断点，眼睁睁看着程序跑完并断开连接。
* **“消失的 ecall”**：`disassemble` 命令只显示了函数开头的一小段，导致找不到 `ecall`。必须用 `x/30i $pc` 强行往后看内存才找到。
* **“手滑”**：在 Guest GDB 里疯狂按 `si`，结果一不留神多按了一下，直接跨过了 `ecall` 进了内核，导致 Host GDB 没机会捕获。
* **“权限”**：Host GDB 试图 attach 进程时被拒绝（`ptrace: Operation not permitted`），因为试图调试一个属于系统层面的进程需要 `sudo` 这一“尚方宝剑”。

### 2. 获得的知识 (Hardware via Software)
* **特权级只是一个变量**：在硬件上，特权级是寄存器里的电压状态；但在 QEMU 里，它就是 `CPURISCVState` 结构体里的一个 `int priv` 变量。从 User 到 Kernel，本质上就是 `env->priv = 1;` 这一行 C 代码赋值。
* **硬件逻辑软件化**：硬件里的“电路连线”在模拟器里变成了 `if-else` 判断。例如，硬件会在每个周期检查中断引脚，QEMU 则是在每个基本块执行前检查 `cpu->interrupt_request` 标志位。

---

## 四、 大模型协作复盘 (Interaction Log)
在本次实验中，我们通过对话解决了一系列阻碍，以下是关键的几个回合：

| 遇到的问题 | 当时情景与我的思路 | 大模型 (我) 的解决策略 |
| --- | --- | --- |
| **GDB 崩溃** | 开局输入 `list` 导致 GDB 报错 Internal Error 并退出。 | **安抚与重启**：指出这是工具 Bug 并非操作错误，引导你重启并规范加载步骤 (`file` -> `target remote`)。 |
| **QEMU 无法连接** | `target remote` 报错，因为 QEMU 进程已死或没开。 | **状态检查**：教你使用 `pgrep` 确认进程，并建立“Terminal 1 开房，Terminal 2 连线”的标准操作流。 |
| **符号表不匹配** | 加载了 `exit` 的符号，但系统跑的是 `cowtest`，导致断点失效。 | **逻辑侦探**：分析 log 发现 `initproc exit` 和 `cowtest` 字样，指出目标程序不一致。提供“顺势调试 cowtest”或“修改源码跑 exit”两个方案。 |
| **找不到 ecall** | `disassemble` 看到的汇编代码没有 `ecall`。 | **工具技巧**：解释 GDB 反汇编的局限性，提供 `x/30i $pc` 命令，强行查看内存后方的指令，成功定位 `0x8000a2`。 |
| **attach 失败** | Host GDB 报错 `ptrace: Operation not permitted`。 | **权限知识**：指出 Linux 进程调试的权限模型，给出 `sudo gdb` 的关键指令。 |
| **变量未初始化** | 刚进函数 `riscv_cpu_do_interrupt` 时，`env` 指针报错或乱码。 | **调试经验**：指出断点停在函数入口时，局部变量初始化代码尚未执行。引导输入 `n` (next) 跨过初始化行，成功获取数据。 |
