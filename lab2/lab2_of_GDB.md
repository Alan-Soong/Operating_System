# 实验报告：深入 QEMU 源码调试 RISC-V 地址翻译与 TLB 机制

> Debugged by Lifeng He (何立烽)

## 一、 实验目的
利用“双重 GDB”调试架构（即一个 GDB 调试 ucore 内核，另一个 GDB 调试 QEMU 模拟器源码），深入观察 QEMU 4.1.1 模拟 RISC-V 处理器时的内部行为。重点在于理解 **虚拟地址到物理地址的翻译流程 (Page Table Walk)**、**TLB 缺失的处理机制**以及**模拟器 TLB 与真实硬件 TLB 的逻辑差异**。

## 二、 QEMU 地址翻译流程分析
### 2.1 关键调用路径 (Call Stack Analysis)
通过在 QEMU 源码端（宿主机侧）使用 GDB 的 `bt` (Backtrace) 命令，我们捕捉到了触发地址翻译的完整函数调用链。

**调试证据：**

```text
#0  get_physical_address (env=0x..., physical=0x..., addr=18446744072637923320, ...) 
    at target/riscv/cpu_helper.c:158
#1  riscv_cpu_tlb_fill (cs=0x..., address=18446744072637923320, ...) 
    at target/riscv/cpu_helper.c:451
#2  tlb_fill (cpu=0x..., addr=18446744072637923320, ...) 
    at accel/tcg/cputlb.c:878
#3  store_helper (..., addr=18446744072637923320, ...) 
    at accel/tcg/cputlb.c:1522

```

**路径分析：**

1. **`store_helper`**: CPU 尝试执行一条存储指令 (`Store`)，向虚拟地址 `0xffffffffc0203ff8` 写入数据。
2. **`tlb_fill`**: 由于这是第一次访问该页面，软件 TLB 中没有缓存，触发了 **TLB Miss**，因此调用填充函数。
3. **`riscv_cpu_tlb_fill`**: 架构相关的 TLB 填充入口。
4. **`get_physical_address`**: 核心函数，执行页表遍历 (Page Table Walk) 以计算物理地址。

### 2.2 关键分支语句与逻辑在 `get_physical_address` 函数中，我们观察到了以下决定硬件行为的关键分支：

1. **模式检查**: `if (mode == PRV_M ...)`
* 判断当前特权级。如果是机器模式 (M-Mode) 且未开启分页，则直接物理映射。


2. **SATP 读取**: `base = get_field(env->satp, SATP_PPN) << PGSHIFT;`
* 模拟硬件读取 `satp` 寄存器，获取根页表的物理基地址。


3. **多级遍历循环**: `for (i = 0; i < levels; i++, ptshift -= ptidxbits)`
* 对应 RISC-V SV39 的三级页表结构。`i=0` 对应 Level 2 (1GB)，`i=1` 对应 Level 1 (2MB)，`i=2` 对应 Level 0 (4KB)。


4. **大页判断 (关键发现)**: `else if (!(pte & (PTE_R | PTE_W | PTE_X)))`
* 这是判断当前页表项是“目录”还是“叶子”的关键。如果 R/W/X 位被置位，说明找到了物理页（可能是大页），停止循环。



### 2.3 地址翻译演示 (Trace)
我们追踪了虚拟地址 **`0xffffffffc0203ff8`** 的翻译过程：

1. **获取根页表**: GDB 显示 `base = 0x80204000`。这与 ucore 启动日志中的 `satp physical address` 完全一致。
2. **读取 PTE**: 在第 0 层循环 (Level 2)，代码执行 `ldq_phys` 从物理内存读取页表项。
* 观测值: `pte = 0x200000cf`。
* 解析: 二进制末尾为 `1100 1111`，即 V=1, R=1, W=1, X=1。


3. **大页识别**: 由于 R/W/X 均为 1，代码判定这是一个 **1GB 大页 (Gigapage)**，直接跳出了后续循环。
4. **物理地址计算**:
* 公式: `(PPN | Offset) << PGSHIFT`
* PPN 来自 PTE: `0x80000`
* Offset 来自虚拟地址低 30 位。
* GDB 计算结果: `*physical = 0x80203ff8`。
* **结论**: 实现了 `0xffffffffc0...` 到 `0x80...` 的线性直接映射。



## 三、 单步调试

### 3.1 为什么会有三个循环？
代码中的 `for (i = 0; i < levels; ...)` 是对硬件 **Page Table Walk (页表游走)** 状态机的完整模拟。

* **RISC-V SV39 标准**: 规定了三级页表结构。
* **模拟过程**:
* **Loop 0 (Level 2)**: QEMU 拿着虚拟地址的高 9 位索引，去查根页表。如果这里指向的是下一个页表，就进入 Loop 1；如果这里已经标记为物理页（如实验中遇到的 1GB 大页），就**提前终止循环**。
* **Loop 1 (Level 1)**: 查中间页表（2MB 粒度）。
* **Loop 2 (Level 0)**: 查末级页表（4KB 粒度）。

**步骤 1：获取根页表基址**

* **[实验数据]**: `(gdb) print/x base`  `$15 = 0x80204000`
* **[分析]**: 此值与 ucore 启动日志中打印的 `satp physical address: 0x0000000080204000` 完全吻合。证明模拟器成功读取了操作系统设置的页表。

**步骤 2：读取页表项 (PTE)**

* **[实验数据]**: 在第 0 层循环 (Level 2) 读取物理内存后：
* `(gdb) print/x pte`  `$8 = 0x200000cf`


* **[PTE 解码]**:
* **标志位**: 低 8 位 `0xcf` (`1100 1111`)  **V=1, R=1, W=1, X=1**。
* **物理页号 (PPN)**: `0x200000cf >> 10` = `0x80000`。


* **[重大发现]**: 由于 R/W/X 均为 1，代码判定这是一个 **1GB 大页 (Huge Page)**。GDB 显示程序直接跳出了后续的 Level 1 和 Level 0 循环。这验证了 ucore 内核使用大页进行线性映射的策略。

**步骤 3：物理地址计算验证**

* **[计算公式]**: `(PPN << 12) | (VirtAddr & OffsetMask)`
* 大页基址: `0x80000 << 12` = `0x80000000`
* 页内偏移: 虚拟地址 `...c0203ff8` 的低 30 位 = `0x203ff8`


* **[实验数据]**: `(gdb) print/x *physical`  `$10 = 0x80203ff8`
* **[结论]**: 验证通过。`0x80000000 + 0x203ff8 = 0x80203ff8`。实现了虚拟地址到物理地址的正确转换。

---


### 3.2 如何从当前页表取出页表项？
我们在调试中定位到了这两行核心代码：

1. `target_ulong pte_addr = base + idx * ptesize;`
* **解释**: 计算物理地址。`base` 是当前页表的起始位置，`idx` 是我们要查第几项，`ptesize` 是每一项的大小 (8字节)。这相当于算出“柜子的坐标”。


2. `target_ulong pte = ldq_phys(cs->as, pte_addr);`
* **解释**: **这是最关键的硬件模拟动作**。
* `ldq_phys` = **L**oa**d** **Q**uad **Phys**ical。
* 它模拟 MMU 向内存总线发送读请求，从刚才算出的 `pte_addr` 读取 64 位数据。这就是“取出页表项”的动作。



## 四、 模拟 CPU 查找 TLB 的代码与细节
### 4.1 查找代码在哪里？
在调试过程中，我们发现断点总是停在 `riscv_cpu_tlb_fill`，这让我产生了“为什么不先查 TLB”的疑问。通过分析调用栈 (`bt`) 和查阅 `accel/tcg/cputlb.c` 源码，我们找到了答案：

* **查找 (Lookup)**: 位于 `store_helper` 函数内部（通过 `tlb_hit` 等宏实现）。这是 **Fast Path**，由 TCG 生成高效代码，直接检查软件 TLB 数组。如果命中，直接访问内存，**不会调用 C 函数**，因此 GDB 很难断下来。
* **填充 (Fill)**: 只有当查找 **失败 (Miss)** 时，才会调用 `tlb_fill`  `riscv_cpu_tlb_fill`。

### 4.2 逻辑验证实验证据链如下：

1. CPU 执行指令，触发 `#3 store_helper`。
2. `store_helper` 先执行隐形的 TLB 查找。
3. 查找失败，进入 Slow Path，调用 `#2 tlb_fill`。
4. 最后调用 `#0 get_physical_address` 查表。
**结论**: QEMU 严格遵循了 **先查 TLB  Miss 后查页表  填入 TLB** 的硬件标准流程。

## 五、 QEMU TLB 与真实 CPU TLB 的逻辑区别
通过对比实验中的两次不同访存（内核虚存 vs M模式直通），我们揭示了模拟器 TLB 的本质区别。

### 5.1 对比实验
* **场景 A (开启虚存)**: 虚拟地址 `0xff...` 翻译为物理地址 `0x80...`。
* **场景 B (未开启虚存/直通)**: 调试发现，即使在 Machine Mode 下访问 `0x8001D040`（此时虚拟地址=物理地址），QEMU **依然触发了 TLB Refill 流程**。

### 5.2 核心差异* 
**真实 CPU TLB**: 缓存 **GVA (Guest Virtual Address)** 到 **GPA (Guest Physical Address)** 的映射。在直通模式下，硬件通常绕过 TLB。
* **QEMU 软件 TLB**: 缓存 **GVA** 到 **HVA (Host Virtual Address)** 的映射。
* **原因**: QEMU 是一个用户态进程，它模拟的“物理内存”实际上是宿主机上的一块 `malloc` 出来的内存区域。
* **结论**: 即使是直通模式，QEMU 也必须通过 TLB 将客户机的“物理地址”翻译成宿主机的“虚拟地址”，才能真正读写数据。QEMU 的 TLB 本质上是 **Guest 到 Host 的地址加速器**。



## 六、 调试过程中的“抓马”细节与知识获取
1. **GDB 的“谎言”**:
* 起初我以为在 `get_physical_address` 打断点是在观察每一次访存。后来发现，只有 TLB Miss 的时候才会停下来。

2. **窗口 3 的“假死”**:
* 当我暂停 QEMU (窗口 2) 时，ucore (窗口 3) 报错 `Invalid remote reply` 并卡死。我深刻理解了：**模拟器是客户机的时间之源**。模拟器按了暂停，操作系统就停止了转动。


3. **大页**:
* 原本准备好了观察三级循环 (`i=0,1,2`)，结果 GDB 显示代码在 `i=0` 时就直接跳出了循环。这意外地验证了 RISC-V 的大页机制，也证明了 ucore 在内核映射上做了优化。


4. **物理地址为 0 的错觉**:
* 当 GDB 停在 `*physical = ...` 这一行时，打印该变量显示为 0。我一度以为计算错了，后来在大模型提示下才明白，**GDB 停在代码执行之前**，必须再按一次 `n` 才能看到计算结果。



## 七、 大模型辅助解决的问题记录

1. **环境搭建困境 (Build ID Mismatch)**
* **情景**: GDB 报错 `Build ID mismatch`，断点无法命中。
* **交互**: 我上传了报错信息。模型敏锐地指出，是因为我的 `Makefile` 路径指向了系统自带的 QEMU，而 GDB 加载的是我编译的带符号表的 QEMU。
* **解决**: 指导我修改 Makefile 中的 `QEMU := ...` 路径，并重启调试，成功解决。


2. **GDB 符号加载问题**
* **情景**: `break get_physical_address` 提示 `Function not defined`。
* **交互**: 我询问为何找不到函数。模型解释说 GDB 此时只有 PID 没有符号表，指导我使用 `file` 命令或者在启动时附加可执行文件路径。
* **思路**: 从“盲人摸象”变成了“看着地图找人”。


3. **理解双重 GDB 的关系**
* **情景**: 我不理解为什么要在窗口 3 运行，却在窗口 2 打断点。
* **交互**: 模型使用了“射击者”与“高速摄像机”的比喻。窗口 3 是为了让 CPU 跑到指定位置（扣扳机），窗口 2 是为了观察微观的硬件实现（慢动作）。这让我彻底明白了模拟器调试的方法论。


4. **代码逻辑解读**
* **情景**: 我看不懂 `ldq_phys` 和那些位运算。
* **交互**: 模型将其“翻译”为硬件行为：“这是模拟内存读”，“这是检查 Valid 位”。特别是对 PTE 中 R/W/X 全为 1 代表大页的解释，直接帮我看懂了实验现象。

## 八、部分代码

```text
pgrep -f qemu-system-riscv64
break get_physical_address
break get_physical_address if addr > 0xc0000000
print/x base
sudo gdb /mnt/c/Users/hp/Desktop/OS_hw/Operating_System/lab2/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
handle SIGPIPE nostop noprint
target remote :1234
list
print/x addr
print/x *physical



file bin/kernel
add-symbol-file obj/__user_cowtest.out
break user/libs/syscall.c:syscall
continue
disassemble
x/30 $pc
break *0x8000a2

sudo gdb
file /mnt/c/Users/hp/Desktop/labcode/lab2/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
attach
break riscv_cpu_do_interrupt
print cause
print env->priv
566             riscv_cpu_set_mode(env, PRV_S);
```
