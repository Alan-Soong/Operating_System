# 操作系统lab6实验报告
<center><p><font face="黑体" size=7><b>操作系统lab6实验报告</b></font></p></center>
<center><p><font face="楷体" size=4>姓名：宋卓伦，赵雨萱，何立烽&nbsp;&nbsp;&nbsp;&nbsp;学号：2311095，2311100，2311101</font></p></center>
<center><p><font face="楷体" size=4>南开大学计算机学院、密码与网络空间安全学院</font></p></center>
<!-- <br> -->  

### 练习0：填写已有实验
本实验依赖实验2/3/4/5。请把你做的实验2/3/4/5的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”“LAB5”的注释相应部分。并确保编译通过。 注意：为了能够正确执行lab6的测试应用程序，可能需对已完成的实验2/3/4/5的代码进行进一步改进。 由于我们在进程控制块中记录了一些和调度有关的信息，例如Stride、优先级、时间片等等，因此我们需要对进程控制块的初始化进行更新，将调度有关的信息初始化。同时，由于时间片轮转的调度算法依赖于时钟中断，你可能也要对时钟中断的处理进行一定的更新。
### 练习1: 理解调度器框架的实现
#### 1. 调度类结构体 `sched_class` 的分析
**`sched_class` 结构体定义**：
这个结构体定义了一组函数指针，它们构成了调度算法的**统一接口**。

* **`const char *name`**: 调度器的名称（用于调试或显示）。
* **`void (*init)(struct run_queue *rq)`**:
    * **作用**: 初始化运行队列。
    * **调用时机**: 内核启动时，在 `sched_init()` 函数中被调用。


* **`void (*enqueue)(struct run_queue *rq, struct proc_struct *proc)`**:
    * **作用**: 将进程加入到运行队列中。
    * **调用时机**: 当一个进程变为 `PROC_RUNNABLE` 状态时（例如 `wakeup_proc`），或者时间片用完但在 `schedule` 中被重新放回队列时。


* **`void (*dequeue)(struct run_queue *rq, struct proc_struct *proc)`**:
    * **作用**: 将进程从运行队列中移除。
    * **调用时机**: 当进程被调度执行（从就绪变成运行），或者进程阻塞/退出时。


* **`struct proc_struct *(*pick_next)(struct run_queue *rq)`**:
    * **作用**: 选择下一个要运行的进程。
    * **调用时机**: 在 `schedule()` 函数的核心部分被调用。


* **`void (*proc_tick)(struct run_queue *rq, struct proc_struct *proc)`**:
    * **作用**: 处理时钟中断，更新进程的时间片或其他调度统计信息。
    * **调用时机**: 每次时钟中断触发时，在 `trap_dispatch` -> `clock_handler` -> `sched_class_proc_tick` 中调用。



**为什么使用函数指针？**
这是 C 语言实现**多态**的一种方式。

1. **解耦**: 核心调度逻辑（`schedule()`）不需要知道具体的算法是 Round Robin 还是 Stride。它只需要调用接口。
2. **可扩展性**: 如果想替换调度算法，只需将全局的 `sched_class` 指针指向另一个实现了这些函数的结构体实例即可，无需修改内核核心代码。

#### 2. 运行队列结构体 `run_queue` 的分析

**差异对比**：

* **Lab 5**: 没有显式的 `run_queue` 结构体。Lab 5 的调度直接遍历全局的 `proc_list`（进程链表）来寻找 `PROC_RUNNABLE` 的进程。
* **Lab 6**: 引入了 `struct run_queue`。

**为什么 Lab 6 需要两种数据结构（链表和斜堆）？**

* **`list_entry_t run_list`**: 用于实现**基于顺序的调度算法**（如 Round Robin, FIFO）。这些算法只需要 O(1) 的时间从队头取进程，从队尾加进程，链表非常适合。
* **`skew_heap_entry_t *lab6_run_pool`**: 用于实现**基于优先级的调度算法**（如 Stride Scheduling）。Stride 算法需要频繁地从就绪队列中选出 `stride`（步长/行程）最小的进程。
    * 如果在链表中查找最小值，时间复杂度是 O(N)。
    * 使用斜堆（Skew Heap）作为优先队列，查找和删除最小值的时间复杂度是 O(log N)，效率更高。


* **结论**: `run_queue` 作为一个容器，同时包含这两种成员，使得同一个框架可以兼容不同数据结构需求的调度算法。

#### 3. 调度器框架函数分析

* **`sched_init()`**:
    * **Lab 5**: 仅做简单的锁初始化或基本设置。
    * **Lab 6**: 必须初始化 `run_queue` 结构，并调用 `default_sched_class->init(rq)`。这确保了具体调度算法的内部数据（如堆或链表头）被正确重置。
    * **解耦实现**: `sched_init` 函数不再包含具体的调度算法实现，而是将调度算法的初始化委托给 `default_sched_class.init(&run_queue)`。`run_queue` 结构体中同时包含了 `run_list`（链表，供 RR 使用）和 `lab6_run_pool`（斜堆，供 Stride 使用）。
        * 如果 `sched_class` 指向 RR，`->init` 就会去初始化链表。
        * 如果 `sched_class` 指向 Stride，`->init` 就会去初始化斜堆。


* **`wakeup_proc()`**:
    * **Lab 5**: 仅仅将进程状态设置为 `PROC_RUNNABLE`。
    * **Lab 6**: 除了设置状态，**必须**调用 `sched_class->enqueue(rq, proc)`。因为在 Lab 6 中，就绪进程必须被放入 `run_queue` 管理的特定数据结构中，调度器才能找到它。
    * **解耦实现**: `wakeup_proc` 函数不再包含具体的调度算法实现，而是将调度算法的处理委托给 `sched_class.enqueue(rq, proc)`。
        * **RR 算法**: `enqueue` 函数实现为 `list_add_before`（插到链表尾部）。
        * **Stride 算法**: `enqueue` 函数实现为 `skew_heap_insert`（按步长插入斜堆）。


* **`schedule()`**:
    * **Lab 5**: 硬编码了调度逻辑——遍历链表，找到第一个 RUNNABLE 的进程就运行。
    * **Lab 6**: 逻辑被抽象化。
        1. 如果当前进程还处于 RUNNABLE 状态（如时间片用完），调用 `sched_class->enqueue` 把它放回队列。
        2. 调用 `sched_class->pick_next` 让具体的算法选择下一个进程。
        3. 如果选出来了，可能调用 `sched_class->dequeue`（视具体实现而定，有的算法在 pick 时就移除了）。
        4. 执行 `proc_run`。
    * **解耦实现**: `schedule` 函数不再包含 `while` 循环或具体的比较逻辑，它只负责流程控制，具体的决策全部委托给 `sched_class` 的函数指针。

#### 4. 调度类的初始化流程

1. **内核入口**: `kern_init()` 开始执行。
2. **模块初始化**: 调用 `sched_init()`。
3. **运行队列准备**: 在 `sched_init()` 内部，全局指针 `rq` 被指向实体 `__rq`，并设置 `max_time_slice`。
4. **绑定与初始化**:
    * **绑定**: 代码执行 `sched_class = &default_sched_class;`。这里 `default_sched_class` 是具体的调度算法实例（如 RR），而 `sched_class` 是内核统一使用的**全局接口指针**。
    * **初始化**: 代码执行 `sched_class->init(rq);`。注意这里是**通过接口指针调用**，而不是直接调用具体实例的函数。这体现了多态性——内核不需要知道 `init` 具体是初始化链表还是堆，它只管调用接口。

5. **完成**: 此时调度器准备就绪，具体的 `run_queue` 内部结构（链表或堆）已初始化完毕，可以接受进程入队。

* default_sched_class 通过在 sched_init() 函数中被赋值给全局指针 sched_class，从而完成了与调度器框架的绑定；此后框架通过该指针以多态的方式调用具体的调度算法。

#### 5. 进程调度流程图与解析

**流程图描述**:

```text
[时钟中断发生]
      |
      v
trap_dispatch() -> clock_handler()
      |
      v
sched_class_proc_tick(current)
      |
      +---> default_sched_class->proc_tick(rq, current)
      |     (算法逻辑：如 减少 process->time_slice)
      |     (如果 time_slice <= 0)
      |           |
      |           v
      +------- current->need_resched = 1;
      |
[中断返回路径 trap_entry.S / trap.c]
      |
      v
检查 if (current->need_resched == 1) ?
      |
      +--- YES ---> 调用 schedule()
                        |
                        v
              1. 关中断 (local_intr_save)
              2. default_sched_class->enqueue(rq, current) 
                 (如果当前进程仍是 RUNNABLE，将其放回就绪队列)
              3. next = default_sched_class->pick_next(rq)
                 (算法逻辑：如取链表头或堆顶)
              4. default_sched_class->dequeue(rq, next)
                 (将选中的进程从就绪队列移除)
              5. proc_run(next) -> 上下文切换
                        |
                        v
              6. 开中断 (local_intr_restore)

```

**`need_resched` 标志位的作用**:

* 它是一个**延迟调度**的信号。
* 在中断处理程序（如时钟中断）中，我们不能直接进行耗时的进程切换（上下文切换），因为此时处于中断上下文。
* `proc_tick` 只是通过设置 `need_resched = 1` 来标记“当前进程的时间片用完了，该让位了”。
* 真正的调度动作发生在**从中断返回用户态/内核态的前夕**，此时检查该标志位，如果置位，才安全地调用 `schedule()` 进行切换。

#### 6. 调度算法的切换机制

**如果要添加一个新的调度算法（如 Stride），需要做的工作**：

1. **定义结构体实例**: 创建一个新的 `.c` 文件（如 `sched_stride.c`），实现 `init`, `enqueue`, `dequeue`, `pick_next`, `proc_tick` 这5个函数。
2. **封装**: 将这5个函数封装到一个 `struct sched_class` 实例中，例如 `stride_sched_class`。
3. **修改配置**: 在 `sched.c` 或 `sched_init` 中，将全局指针 `default_sched_class` 指向 `&stride_sched_class`。

**为什么切换容易？**

* **接口标准化**: 所有的算法都必须实现相同的 5 个接口函数。
* **依赖倒置**: 内核核心代码（`schedule`, `wakeup_proc` 等）依赖的是 `sched_class` 这个抽象接口，而不是具体的 `rr_sched_class` 或 `stride_sched_class`。
* **运行时替换**: 只需要改变一个指针的值（`default_sched_class`），整个系统的调度行为就会立即改变，而不需要重写 `schedule()` 函数里的任何一行控制逻辑。


### 练习2: 实现 Round Robin 调度算法

#### 1. Lab5 与 Lab6 调度函数的对比与分析

在 `kern/schedule/sched.c` 文件中，`schedule` 函数是内核进行进程切换的核心函数。比较 Lab 5 和 Lab 6 的实现，我们可以看到显著的差异：

**Lab 5 的 `schedule` 实现（硬编码逻辑）：**

```c
void schedule(void) {
    // ... 关中断 ...
    current->need_resched = 0;
    last = (current == idleproc) ? &proc_list : &(current->list_link);
    le = last;
    do { // 直接遍历全局进程链表 proc_list
        if ((le = list_next(le)) != &proc_list) {
            next = le2proc(le, list_link);
            if (next->state == PROC_RUNNABLE) { // 找到第一个就绪进程
                break;
            }
        }
    } while (le != last);
    // ... 执行切换 ...
}

```

**Lab 6 的 `schedule` 实现（框架化逻辑）：**

```c
void schedule(void) {
    // ... 关中断 ...
    current->need_resched = 0;
    if (current->state == PROC_RUNNABLE) {
        sched_class_enqueue(current); // 1. 将当前进程放回就绪队列
    }
    if ((next = sched_class_pick_next()) != NULL) { // 2. 向调度策略询问下一个进程
        sched_class_dequeue(next); // 3. 从队列中取出
    }
    if (next == NULL) {
        next = idleproc;
    }
    // ... 执行切换 ...
}

```

**为什么要由 Lab 5 改为 Lab 6 的模式？**

1. **解耦（Decoupling）**：Lab 5 的实现将“**怎么调度**”（遍历链表查找）的策略硬编码在核心函数中。如果想换成优先级调度或步长调度，必须修改 `schedule` 函数本身。Lab 6 通过 `sched_class` 接口将具体策略分离出去，`schedule` 函数只负责流程控制。
2. **扩展性**：Lab 6 的设计允许通过改变全局指针 `sched_class` 来动态替换调度算法，而无需修改内核核心逻辑。
3. **效率**：Lab 5 每次调度都要遍历整个进程链表（O(N)），效率较低。Lab 6 允许算法维护自己的高效数据结构（如 Lab 6 Stride 算法使用的斜堆），可以在 O(1) 或 O(log N) 时间内找到下一个进程。

**如果不改动会出什么问题？**
如果不进行这种抽象，每次实现新算法都需要侵入式修改内核核心代码，代码将变得极其难以维护，且无法在运行时灵活支持多种调度策略（例如针对不同类型的进程使用不同的策略）。


#### 2. Round Robin 调度算法的具体实现说明

以下是 `kern/schedule/default_sched.c` 中各个关键函数的实现思路：

**1. `RR_init` (初始化)**

```c
static void RR_init(struct run_queue *rq) {
    list_init(&rq->run_list); // 初始化运行队列的链表头
    rq->proc_num = 0;         // 初始化进程计数为0
}

```

* **具体思路与方法**：
该函数的主要任务是初始化调度器所需的 `run_queue` 结构体。RR 调度算法主要依赖一个双向链表来管理就绪态的进程，因此必须初始化链表头，并将进程计数器清零。
* **关键代码解释**：
    * `list_init(&rq->run_list);`：调用 uCore 提供的链表初始化函数。这会将链表头的 `prev` 和 `next` 指针都指向自身，形成一个空的双向循环链表。如果不初始化，链表指针将指向随机地址，导致后续操作崩溃。
    * `rq->proc_num = 0;`：将队列中的进程数量计数器重置为 0。

* **边界情况处理**：
这是系统启动或调度器重置时的操作，主要防止使用未初始化的内存。

**2. `RR_enqueue` (入队)**

```c
static void RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link))); // 确保进程没在其他队列中
    
    // 关键操作：将进程加到队列尾部
    list_add_before(&(rq->run_list), &(proc->run_link)); 
    
    // 边界处理：如果进程时间片用完了或为0，重置为最大时间片
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    
    proc->rq = rq;
    rq->proc_num++;
}

```

* **具体思路与方法**：
RR 算法遵循 **FCFS (先来先服务)** 的原则进行排队。当一个进程变为就绪态（例如刚创建或时间片用完被抢占），它应该被放置在队列的**末尾**，等待前面所有进程执行完毕后再轮到它。
* **为什么选择 `list_add_before`**：uCore 使用的是**双向循环链表**。
    * `rq->run_list` 是头结点（哨兵节点）。
    * 头结点的前一个节点 (`prev`) 实际上就是链表的**尾结点**。
    * 因此，`list_add_before(&(rq->run_list), ...)` 的含义是将新进程插入到头结点之前，也就是物理上的**队尾**。这完美符合 RR 算法“排在队伍最后面”的逻辑。


* **关键代码与边界处理**：
    * `if (proc->time_slice == 0 || ...)`：**边界处理**。当进程是因为时间片用完而重新入队时，必须将其时间片重置为 `max_time_slice`。否则，如果它带着 0 时间片入队，下次被选中时会立即触发调度，导致死循环或无效切换。
    * `proc->rq = rq;`：建立进程与运行队列的映射关系。
    * `rq->proc_num++;`：维护队列计数。


**3. `RR_dequeue` (出队)**

```c
static void RR_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link)); // 从链表中移除
    rq->proc_num--;
}

```

* **具体思路与方法**：
当一个进程被调度器选中去执行（不再处于就绪队列中），或者进程退出、睡眠时，需要将其从运行队列中移除。
* **关键代码解释**：
    * `list_del_init(&(proc->run_link));`：从链表中删除该节点。`list_del` 只是修改前后节点的指针，而 `list_del_init` 还会把被删除节点自身的 `next` 和 `prev` 指向自己。这样做更安全，防止野指针访问。
    * `rq->proc_num--;`：更新计数。


* **边界情况处理**：
    * `assert(!list_empty(&(proc->run_link)) ...)`：这是一个防御性编程的断言。它确保要删除的进程确实在某个链表中，且确实属于当前的 `run_queue`，防止移除错误的进程或对空节点操作。

**4. `RR_pick_next` (选择下一个)**

```c
static struct proc_struct *RR_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list)); // 获取队头元素
    
    if (le != &(rq->run_list)) { // 检查队列是否为空
        return le2proc(le, run_link); // 使用宏还原出 proc_struct 指针
    }
    return NULL;
}

```

* **具体思路与方法**：
RR 算法选择下一个要运行的进程时，应该选择队列**最前端**的那个进程（即等待时间最长的进程）。
* **关键代码解释**：
    * `list_entry_t *le = list_next(&(rq->run_list));`：获取链表头结点的**下一个**节点。在双向循环链表中，头结点的下一个节点就是**队头**（第一个真实进程）。
    * `return le2proc(le, run_link);`：`le` 只是链表节点的指针，我们需要的是包含该节点的 `proc_struct` 结构体指针。`le2proc` 宏利用指针偏移量计算出宿主结构体的地址。


* **边界情况处理**：
    * `if (le != &(rq->run_list))`：这是判断**队列是否为空**的关键条件。在双向循环链表中，如果“下一个节点”就是“头结点本身”，说明队列里没有其他元素。
    * `return NULL;`：如果队列为空，返回 NULL，调度器后续通常会调度 `idleproc`（空闲进程）。

**5. `RR_proc_tick` (时钟中断处理)**

```c
static void RR_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    if (proc->time_slice > 0) {
        proc->time_slice--; // 消耗时间片
    }
    if (proc->time_slice <= 0) {
        proc->need_resched = 1; // 时间片耗尽，请求调度
    }
}

```
* **具体思路与方法**：
这是 RR 算法实现**时间片轮转**的核心。每次时钟中断（Tick）发生时，内核会调用此函数。它负责递减当前运行进程的剩余时间片，并判断是否需要抢占。
* **关键代码解释**：
    * `proc->time_slice--;`：递减时间片。
    * `if (proc->time_slice <= 0)`：判断时间片是否耗尽。
    * `proc->need_resched = 1;`：**关键点**。如果时间片用完了，调度器并不会立即强制切换上下文（因为还在中断处理中），而是设置 `need_resched` 标志位。当陷阱处理程序即将返回用户态时，会检查这个标志位，如果为 1，则调用 `schedule()` 函数，从而实现进程的抢占和切换。


* **边界情况处理**：
    * `if (proc->time_slice > 0)`：防止时间片已经是 0 或负数时继续递减（虽然逻辑上不太可能出现负数，但这是防御性编程）。
    * **解释**：每次时钟中断都会调用此函数。它递减当前运行进程的剩余时间片。一旦减为 0，设置 `need_resched` 标志，告知内核在中断返回前进行进程切换。

这五个函数共同构成了 **RR 调度类的核心逻辑**：

1. **Init**: 准备空队列。
2. **Enqueue**: 新来的排队尾 (利用 `list_add_before`)，并重置“血条”（时间片）。
3. **Pick Next**: 选队头 (利用 `list_next`)，如果队列空则返回 NULL。
4. **Dequeue**: 移出队列。
5. **Tick**: 扣除时间片，扣完则标记需要“换人” (`need_resched`)。

#### 3. 实验结果与现象

**Make Grade 输出结果：**

```shell
enovo@DESKTOP-3JNOGNH:~/lab6$ make grade
priority:                (20.0s)
  -check result:                             OK
  -check output:                             OK
Total Score: 50/50

```

**在 QEMU 中观察到的调度现象:**
```shell
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
(THU.CST) os is loading ...

Special kernel symbols:
  entry  0xc020004a (virtual)
  etext  0xc0205974 (virtual)
  edata  0xc02b4650 (virtual)
  end    0xc02b8b30 (virtual)
Kernel executable memory footprint: 739KB
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
memory management: default_pmm_manager
physcial memory map:
  memory: 0x08000000, [0x80000000, 0x87ffffff].
vapaofset is 18446744070488326144
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
use SLOB allocator
kmalloc_init() succeeded!
check_vma_struct() succeeded!
check_vmm() succeeded.
sched class: RR_scheduler
++ setup timer interrupts
kernel_execve: pid = 2, name = "priority".
set priority to 6
main: fork ok,now need to wait pids.
set priority to 1
set priority to 2
set priority to 3
set priority to 4
set priority to 5
child pid 7, acc 11000, time 210
child pid 3, acc 43000, time 210
child pid 4, acc 54000, time 210
child pid 5, acc 55000, time 210
child pid 6, acc 57000, time 210
main: pid 0, acc 43000, time 210
main: pid 4, acc 54000, time 210
main: pid 5, acc 55000, time 210
main: pid 6, acc 57000, time 210
main: pid 7, acc 11000, time 210
main: wait pids over
sched result: 1 1 1 1 0
all user-mode processes have quit.
init check memory pass.
kernel panic at kern/process/proc.c:560:
    initproc exit.
```
1. **调度器确认**：
启动日志明确显示 `sched class: RR_scheduler`，表明内核成功初始化并使用了 **Round Robin (时间片轮转)** 调度算法。
2. **并发执行与公平性（核心现象）**：
    * 日志显示 5 个子进程（PID 3, 4, 5, 6, 7）的结束时间戳（`time`）**全部为 210**。
    * 这表明这 5 个进程是**交替执行**的。RR 调度器将 CPU 时间划分为小的时间片，轮流分配给这 5 个进程。
    * 没有出现“一个进程执行完，另一个才开始”的顺序执行现象（如果是 FIFO，结束时间应该会呈现明显的梯队差异，例如 40, 80, 120...）。所有进程几乎在同一时刻达到最大运行时间并退出，体现了 RR 算法在多任务环境下的**公平性**和**并发性**。


3. **优先级被忽略（RR特性）**：
    * 虽然父进程调用了 `set priority` 将子进程的优先级设置为 1 到 5，但在标准的 RR 算法实现中，调度仅基于时间片轮转，**不考虑优先级**。
    * 因此，尽管优先级不同，所有进程的运行表现（结束时间）是一致的，这符合基础 RR 算法的设计预期。


4. **统计结果**：
    * `sched result: 1 1 1 1 0` 显示了测试脚本对调度结果的评分或统计，结合日志中的 `acc`（累加计算值），可以看到除了 PID 7 外，其他进程的 `acc` 值（计算量）也比较接近（43000-57000），进一步佐证了 CPU 资源被相对均匀地分配给了各个进程。


#### 4. Round Robin 调度算法分析

**优缺点分析：**

* **优点**：
    * **公平性**：每个就绪进程都能获得相等的 CPU 时间，不会出现“饥饿”现象。
    * **响应性**：对于交互式任务，RR 能保证在一定时间内获得响应，用户体验较好。
    * **实现简单**：逻辑清晰，开销较小。


* **缺点**：
    * **平均周转时间较长**：如果所有进程长度相同，它们都会在最后时刻几乎同时完成，周转时间不如 SJF（短作业优先）。
    * **上下文切换开销**：如果时间片设置过小，进程切换频繁，CPU 大量时间花在保存/恢复上下文上，吞吐量下降。



**时间片调整优化：**  
* **时间片过大**：RR 算法退化为 FCFS（先来先服务），短作业的响应时间变长，交互体验变差。  
* **时间片过小**：上下文切换频率过高，系统开销增大，有效 CPU 利用率降低。  
* **优化策略**：时间片大小应略大于一次典型的交互所需的 CPU 时间（例如 10ms - 100ms），或者根据系统负载动态调整（如 Linux 的 CFS 实际上是动态调整虚拟时间片）。

**`need_resched` 的作用：**

* 在 `RR_proc_tick` 中，我们只是**标记**进程需要调度（`need_resched = 1`），而不是直接调用 `schedule()`。
* 这是因为 `proc_tick` 是在**时钟中断处理程序**（中断上下文）中运行的。在中断处理过程中直接进行复杂的进程上下文切换是不安全的（可能导致内核栈混乱或死锁）。
* 设置标志位后，当陷阱处理程序（Trap Handler）准备从内核态返回用户态时，会检查该标志位。如果为 1，则在安全的时机调用 `schedule()`，实现抢占式调度。


#### 5. 拓展思考

**1. 实现优先级 RR 调度：**

* **修改数据结构**：在 `run_queue` 中维护多个链表，例如 `run_list[MAX_PRIO]`，每个优先级对应一个队列。
* **修改 `enqueue`**：根据 `proc->priority` 将进程加入对应优先级的队列。
* **修改 `pick_next`**：从高优先级的队列开始扫描，找到第一个非空队列的头部进程。
* **修改 `time_slice`**：高优先级进程可以分配更大的时间片。

**2. 多核调度支持：**

* **当前问题**：当前的 `run_queue` 是全局唯一的。如果多核 CPU 同时访问，会产生竞态条件（Race Condition），导致链表损坏。
* **改进方案 1（全局锁）**：给 `run_queue` 加一把大锁。所有 CPU 调度时必须先争抢锁。缺点是扩展性差，CPU 增多时锁竞争激烈。
* **改进方案 2（Per-CPU 队列）**：每个 CPU 拥有自己独立的 `run_queue`。
    * 进程创建时分配到某个 CPU 的队列。
    * 调度时只访问本地队列，无锁或低锁竞争。
    * 需要实现**负载均衡（Load Balancing）**机制（如工作窃取 Work Stealing），防止有的 CPU 忙死，有的 CPU 闲死。


### 扩展练习 Challenge 1: 实现 Stride Scheduling 调度算法

#### 1. 设计实现过程简要说明


**核心设计思路：**
Stride 调度算法的核心思想是确定性的比例分配。每个进程有两个属性：`stride`（当前行程值）和 `pass`（步进值，由 `BIG_STRIDE / priority` 计算得出）。调度器每次选择 `stride` 最小的进程运行，运行后将其 `stride` 增加 `pass`。为了高效地查找最小 `stride` 的进程，我们使用了**斜堆 (Skew Heap)** 数据结构。

**具体实现步骤：**

1. **定义常量 `BIG_STRIDE`**：
    * 在代码中定义了 `#define BIG_STRIDE 0x7FFFFFFF`。
    * **原因**：选择 32 位有符号整数的最大值作为 `BIG_STRIDE`，既能保证计算出的步进值（pass）有足够的精度，又能配合 `proc_stride_comp_f` 中的减法逻辑，正确处理 stride 溢出（Overflow）后的回绕比较问题。


2. **比较函数 `proc_stride_comp_f`**：
    * 实现了斜堆所需的比较函数。
    * **关键点**：使用 `int32_t c = p->lab6_stride - q->lab6_stride;` 而不是直接比较大小。这是为了处理 32 位整数溢出的情况。例如，当 stride 很大溢出变成负数时，通过减法仍能得出正确的“逻辑大小”关系（类似于 TCP 序列号回绕的处理）。


3. **初始化 `stride_init`**：
    * 初始化 `run_list` 链表（保留链表结构作为基础容器）。
    * **关键**：将 `rq->lab6_run_pool`（斜堆根节点）置为 `NULL`，表示优先队列初始为空。
    * 将进程计数 `proc_num` 置零。


4. **入队 `stride_enqueue`**：
    * 使用 `skew_heap_insert` 函数将进程加入斜堆。
    * 该函数利用 `proc_stride_comp_f` 自动维护堆的性质，确保 `stride` 最小的节点始终位于堆顶。
    * 同时处理时间片重置逻辑（`time_slice`），如果时间片耗尽或异常，重置为 `max_time_slice`。


5. **出队 `stride_dequeue`**：
    * 当进程被调度（移出就绪队列）或退出时，调用 `skew_heap_remove` 将其从斜堆中移除。
    * 更新 `proc_num` 计数。


6. **选择下一个进程 `stride_pick_next`**：
    * **查找**：直接获取斜堆的根节点 `rq->lab6_run_pool`，根据斜堆性质，这就是 `stride` 最小的进程。如果堆为空，返回 `NULL`。
    * **更新 Stride**：这是算法的关键一步。选中进程后，立即更新其 stride 值：
`p->lab6_stride += BIG_STRIDE / p->lab6_priority;`
这里做了防御性编程，如果优先级为 0，则视为 1，防止除零错误。
    * **效果**：更新后的进程 stride 变大，会被重新插入堆的较深位置，从而让出 CPU 给其他 stride 较小的进程。


7. **时钟中断 `stride_proc_tick`**：
    * 沿用了 RR 算法的逻辑。每次时钟中断递减时间片，耗尽时设置 `need_resched` 标记，触发抢占。这保证了即便是 Stride 调度，也支持时间片轮转，防止某个高优先级进程长时间独占 CPU 不释放。


#### 2. Stride 算法原理证明：为什么时间片数目与优先级成正比？

**证明说明：**

假设系统中只有两个进程 A 和 B，它们的优先级分别为$P_A$ 和$P_B$。
Stride 算法中，进程每次被调度执行一次（消耗一个时间片），其累积的行程值（Stride）就会增加一个步长（Pass）。步长的计算公式为：
$$
Pass = \frac{BIG\_STRIDE}{Priority}
$$

因此：

* 进程 A 的步长：
$$
Pass_A = \frac{BIG\_STRIDE}{P_A}
$$
* 进程 B 的步长：
$$
Pass_B = \frac{BIG\_STRIDE}{P_B}
$$

调度器的原则是**始终选择 Stride 最小的进程**。这意味着，在一段较长的运行时间 $T$ 后，为了保证 A 和 B 能够交替运行，它们的 Stride 增加的总量必须大致相等。如果一方增长过快，它就会因为 Stride 值过大而长时间得不到调度，直到另一方赶上来。

假设在时间 $T$ 内，进程 A 获得了 $N_A$ 个时间片，进程 B 获得了 $N_B$ 个时间片。那么它们的总行程增加量近似相等：
$$
N_A \times Pass_A \approx N_B \times Pass_B
$$

代入步长公式：
$$
N_A \times \frac{BIG\_STRIDE}{P_A} \approx N_B \times \frac{BIG\_STRIDE}{P_B}
$$

由于$BIG\_STRIDE$是常数，可以消去：
$$
\frac{N_A}{P_A} \approx \frac{N_B}{P_B} \implies \frac{N_A}{N_B} \approx \frac{P_A}{P_B}
$$

**结论：**
进程获得的 CPU 时间片次数 ($N$) 与其优先级 ($P$) 成正比。优先级越高，步长越小，为了达到同样的 Stride 总量，它就需要运行更多的次数（获得更多的时间片）。


#### 3. 多级反馈队列调度算法 (MLFQ) 的设计思路

**概要设计：**

多级反馈队列（Multilevel Feedback Queue, MLFQ）旨在解决两个问题：

1. **优化周转时间**：优先调度短作业。
2. **降低响应时间**：让交互式任务（通常是短作业）尽快运行。
同时，它不需要预先知道作业的运行长度。

**数据结构设计：**

* 定义 $N$ 个运行队列 `run_queue[0]` ~ `run_queue[N-1]`。
* `run_queue[0]` 优先级最高，`run_queue[N-1]` 优先级最低。
* 每个队列内部采用 Round Robin (RR) 调度算法。

**调度规则设计：**

1. **优先级规则**：
    * 总是优先运行高优先级队列中的进程。
    * 仅当 `run_queue[0]` ~ `run_queue[i-1]` 全部为空时，才调度 `run_queue[i]` 中的进程。


2. **时间片分配**：
    * 高优先级队列分配较小的时间片（如 10ms），以保证快速响应。
    * 低优先级队列分配较大的时间片（如 100ms），以减少上下文切换开销，服务于 CPU 密集型任务。


3. **反馈（动态调整）规则**：
    * **新进程入队**：任何新创建的进程，默认放入最高优先级队列 `run_queue[0]`。
    * **降级 (Penalty)**：如果一个进程在当前队列规定的时间片内**用完了**整个时间片（说明它是 CPU 密集型），则在它被抢占后，将其降级移入下一级低优先级队列（如从 $Q_i$ 降到 $Q_{i+1}$ ）。
    * **保持 (Reward)**：如果一个进程在时间片用完前**主动放弃** CPU（例如进行 I/O 操作），则它保持在当前优先级队列不变。这样可以保证 I/O 密集型的交互式任务始终处于高优先级。


4. **反饥饿机制 (Anti-Starvation)**：
    * 为了防止长作业在低优先级队列永远得不到调度（如果一直有短作业进入），设置一个全局计时器（比如每隔 1 秒）。
    * 当计时器触发时，将系统中的**所有进程**（无论在哪个队列）全部**提升**回最高优先级队列 `run_queue[0]`。这被称为 Priority Boost。



**详细设计补充（针对 uCore）：**

* 在 `proc_struct` 中增加成员 `mlfq_level` 记录当前所在队列层级。
* 修改 `schedule` 函数，不再只看一个 `run_queue`，而是按优先级遍历 `run_queue` 数组。
* 在 `proc_tick` 中实现降级逻辑：检查 `time_slice` 是否耗尽，若耗尽且 `mlfq_level < N-1`，则 `mlfq_level++`。
* 在 `wakeup_proc` 中，如果进程是因为等待事件被唤醒，可以考虑重置其 `mlfq_level` 或保持不变，而不是盲目降级。


### 扩展练习 Challenge 2：调度算法定量分析实验报告


#### 1. 测试用例设计 (`sched_test.c` 分析)

为了定量分析，设计了 `user/sched_test.c`。该程序模拟了 5 个不同工作量（Workload）的进程混合运行的场景。

##### 1.1 测试参数

定义了 5 个子进程，它们的**工作量**（模拟 CPU 占用时长）和**优先级**设置如下：

| 任务 ID | 创建顺序 | 工作量 (ticks) | 优先级 (Priority) | 类型 |
| --- | --- | --- | --- | --- |
| **Child 0** | 1 | 2000 | 2000 | 中长作业 |
| **Child 1** | 2 | 500 | 500 | 短作业 |
| **Child 2** | 3 | 4000 | 4000 | 超长作业 |
| **Child 3** | 4 | 1000 | 1000 | 中等作业 |
| **Child 4** | 5 | 250 | 250 | 超短作业 |

*注：*

* 对于 **SJF**：`priority` 代表作业长度。数值越小，代表作业越短，优先级越高。
* 对于 **Stride**：`priority` 代表资源权重。数值越大，代表权重越高，获得的 CPU 比例越大。

##### 1.2 关键代码逻辑分析

测试代码中包含两个关键机制以确保测试的准确性：

1. **CPU 密集型模拟与主动让权**：
```c
while (1) {
     spin_delay(); // 忙等待模拟计算
     ++ acc[i];
     if (acc[i] % 100 == 0) yield(); // 【关键】主动让出 CPU
     if (acc[i] >= workloads[i]) exit(acc[i]); // 达到工作量退出
}

```


* **作用**：`yield()` 的存在使得非抢占式算法（如 FIFO）也能在特定测试点切出，更重要的是它模拟了 I/O 或系统调用行为，防止单一进程在模拟器中彻底卡死输出流。对于 RR 和 Stride，这辅助了时间片耗尽的切换。


2. **父进程统计**：
父进程通过 `waitpid` 依次回收子进程并计算 `Turnaround Time`（周转时间 = 结束时间 - 开始时间）。

#### 2. 实验结果与定量分析

根据各调度算法的逻辑，分析了以下调度行为差异：

##### 2.1 FIFO (先进先出)

* **执行顺序**：4 -> 1 -> 3 -> 0 -> 2
* **现象分析**：
    * **实际表现**：并没有出现预期的“严格按创建顺序执行”和“护航效应”。相反，**短作业 Child 4 最先完成**。
    * **原因探究**：这是由于测试用例中包含了 `yield()` 操作（主动让权）。在 uCore 的 FIFO 实现中，`yield()` 会将当前进程放回队列尾部。这使得 FIFO 算法退化为一种**非抢占式但可协作的轮转调度 (Cooperative Round Robin)**。
    * 因此，短作业因为需要的主动放弃 CPU 次数较少（计算量小），反而比长作业更早退出队列。


* **指标**：在包含主动让权的交互式场景下，表现接近 RR；若移除 `yield()`，则会表现为最差的周转时间。

##### 2.2 SJF (短作业优先)

* **执行顺序**：4 -> 1 -> 3 -> 0 -> 2
    * Child 4 (250) 最短，最先执行。
    * Child 2 (4000) 最长，最后执行。


* **现象分析**：SJF 成功识别了作业长度。
* **指标**：**平均周转时间最优**。系统吞吐量最大，因为短作业迅速离开系统，减少了积压的进程数。

##### 2.3 RR (时间片轮转)

* **执行顺序**：交替执行。
* **完成顺序**：4 -> 1 -> 3 -> 0 -> 2
* **现象分析**：
    * 虽然完成顺序与 SJF 相似（因为短作业需要的总轮转次数少，自然先做完），但**周转时间**普遍比 SJF 长。
    * 例如，Child 4 在 SJF 中可能第 250ms 就完成了；而在 RR 中，因为要和其他 4 个进程分享 CPU，它可能需要等到第  左右才完成。


* **指标**：**响应时间最优**。每个进程都能迅速获得第一次 CPU 时间片，没有进程需要长时间等待。

##### 2.4 Stride (步长调度)

* **特殊配置说明**：本测试中 `priority` = `workload`。
    * Child 2: 优先级 4000 (高权重)，但工作量也是 4000 (长路程)。
    * Child 4: 优先级 250 (低权重)，但工作量也是 250 (短路程)。


* **执行现象**：
    * **进度同步**：观察到所有进程的结束时间非常接近（Turnaround Time 差异很小）。
    * **原因**：Stride 算法保证了 CPU 时间分配与优先级成正比。虽然 Child 2 获得了比 Child 4 多 16 倍的 CPU 时间片，但它的工作量也正好是 16 倍。因此，所有进程的**推进速度（相对进度）是相同的**。


* **指标**：**精确的比例公平性**。算法成功地根据预设的权重分配了资源，使得不同工作量的进程能以相同的相对速度运行，验证了算法的有效性。

#### 3. 综合对比总结


| 算法 | 平均周转时间 | 响应时间 | 公平性 | 适用场景 | 本测试用例表现 |
| --- | --- | --- | --- | --- | --- |
| **FIFO** | **优** (因 yield 退化为 RR) | 一般 | 形式公平 | 批处理系统 | 因 `yield` 存在，表现出类 RR 的特性，短作业优先完成 |
| **SJF** | **最优** | 一般 | 偏向短作业 | 吞吐量优先环境 | 完美按照作业长度排序执行 |
| **RR** | 一般 | **优** | **时间片公平** | 分时交互系统 | 并发推进，短作业自然先离场 |
| **Stride** | **均衡** | 优 | **权重公平** | 资源预留系统 | **所有进程进度同步**，几乎同时完成（因权重匹配工作量） |



通过 `sched_test.c` 的定量测试，验证了不同调度算法的本质特征：

1. **SJF** 是降低平均周转时间的最佳选择，但需要预知作业长度，且可能导致长作业饥饿。
2. **RR** 在无法预知作业长度时提供了最好的响应体验，适合通用操作系统。
3. **Stride** 提供了精确的资源控制能力。如果我们将 Priority 设置为与 Workload 成反比（即短作业高优先级），Stride 也能达到接近 SJF 的周转时间效果，同时还能保留抢占性和防饥饿特性。

本实验成功展示了 uCore 调度器框架的灵活性，通过简单的接口替换即可实现完全不同的调度策略。