# 操作系统lab5实验报告
<center><p><font face="黑体" size=7><b>操作系统lab5实验报告</b></font></p></center>
<center><p><font face="楷体" size=4>姓名：宋卓伦，赵雨萱，何立烽&nbsp;&nbsp;&nbsp;&nbsp;学号：2311095，2311100，2311101</font></p></center>
<center><p><font face="楷体" size=4>南开大学计算机学院、密码与网络空间安全学院</font></p></center>
<!-- <br> -->  

### 练习0：填写已有实验
本实验依赖实验2/3/4。请把你做的实验2/3/4的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行 lab5 的测试应用程序，可能需对已完成的实验2/3/4的代码进行进一步改进。
### 1\.alloc_proc 函数更新 (位于 kern/process/proc.c)
初始化 Lab 5 新增的成员变量（**进程关系链表指针`*cptr, *yptr, *optr`和等待状态`wait_state`**）。
```c
// LAB5 YOUR CODE : (update LAB4 steps) 2311100
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;
```
### 2\.do_fork 函数更新 (位于 kern/process/proc.c)
需要修改 Lab 4 中的第1步和第5步。
- **第1步更新**：不仅要分配内存，还要显式设置 parent 指针，并确保当前进程（父进程）没有处于等待状态。
- **第5步更新**：不再简单地使用 list_add，而是使用 set_links 函数。set_links 会自动处理 proc_list 的插入以及 cptr、yptr、optr 等父子兄弟关系的连接。
```c
 // 1. 调用 alloc_proc 分配一个 proc_struct
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    // 建立父子关系
    proc->parent = current; 
    current->wait_state = 0;
    // assert(current->wait_state == 0); // 确保当前进程的 wait_state 为 0
...
    {
    	// 5. 将 proc_struct 插入 hash_list 和 proc_list
    	proc->pid = get_pid(); // 获取一个唯一的 PID
    	hash_proc(proc);       // 加入哈希表，用于 find_proc
    	// list_add_before(&proc_list, &(proc->list_link)); // 加入全局进程链表
    	// nr_process++;
        set_links(proc);
    }
...
    // LAB5 YOUR CODE : (update LAB4 steps) 2311100
    // TIPS: you should modify your written code in lab4(step1 and step5), not add more code.
    /* Some Functions
     *    set_links:  set the relation links of process.  ALSO SEE: remove_links:  lean the relation links of process
     *    -------------------
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */
```
### 练习1: 加载应用程序并执行
do_execve函数调用load_icode（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充load_icode的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好proc_struct结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。

请在实验报告中简要说明你的设计实现过程。

请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。


#### 1\. 代码实现

```c
//(6) setup trapframe for user environment
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 YOUR CODE: 2311101
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */

    tf->gpr.sp = USTACKTOP;               // 设置用户栈顶指针
    tf->epc = elf->e_entry;               // 设置程序入口点
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
```

#### 2\. 设计实现过程

  * **设置栈指针 (`sp`)**: 用户程序需要栈来存放局部变量和函数调用链。已经映射了用户栈空间，`USTACKTOP` 是用户栈的虚拟地址顶端，将其赋值给 trapframe 的 `sp` 寄存器，否则用户程序无法进行函数调用。
  * **设置程序计数器 (`epc`)**: `load_icode` 解析 ELF 头部获取了程序的入口地址 `e_entry`。将 `tf->epc` 设为此值，`sret` 后 CPU 会跳转到此地址执行。
  * **设置状态寄存器 (`status`)**:
      * 清除 `SSTATUS_SPP` 位：这将确保执行 `sret` 指令后，CPU 的特权级（Privilege Level）从 Supervisor 模式切换回 User 模式。
      * 设置 `SSTATUS_SPIE` 位：这将确保返回用户态后，中断是被允许的（Opened），防止用户进程无法响应中断。

#### 3\. 简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

1.  **调度**: `schedule()` 函数选择该进程，将其状态设为 `RUNNING`，并调用 `proc_run(next)`。
2.  **上下文切换**: `proc_run` 调用 `switch_to`，，保存当前内核线程上下文，加载新用户进程的内核上下文。
3.  **中断返回**: `switch_to` 返回到 `forkret`函数，`forkret` 调用 `forkrets(current->tf)`。
4.  **恢复 Trapframe**: `forkrets` 接收 `current->tf` 作为参数，通过汇编代码（通常在 `trapentry.S` 中的 `__trapret`）将 `tf` 中的内容（包括我们刚才设置的 `sp`, `epc`, `status`）恢复到 CPU 的寄存器中。
5.  **特权级切换**: 执行 `sret` 指令。CPU 根据 `sstatus.SPP` (0) 切换到用户态，跳转到 `sepc` 指向的地址（即应用程序入口），并根据 `sstatus.SPIE` 打开中断。
6.  **执行**: CPU 开始执行应用程序的第一条指令。

-----

### 练习2: 父进程复制自己的内存空间给子进程
创建子进程的函数do_fork在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过copy_range函数（位于kern/mm/pmm.c中）实现的，请补充copy_range的实现，确保能够正确执行。
请在实验报告中简要说明你的设计实现过程。

#### 1\. 代码实现

这是标准的内存深拷贝（Deep Copy）实现，适用于非 COW 模式：

```c
/* LAB5:EXERCISE2 YOUR CODE: 2311095
             * replicate content of page to npage, build the map of phy addr of
             * nage with the linear addr start
             *
             * Some Useful MACROs and DEFINEs, you can use them in below
             * implementation.
             * MACROs or Functions:
             *    page2kva(struct Page *page): return the kernel vritual addr of
             * memory which page managed (SEE pmm.h)
             *    page_insert: build the map of phy addr of an Page with the
             * linear addr la
             *    memcpy: typical memory copy function
             *
             * (1) find src_kvaddr: the kernel virtual address of page
             * (2) find dst_kvaddr: the kernel virtual address of npage
             * (3) memory copy from src_kvaddr to dst_kvaddr, size is PGSIZE
             * (4) build the map of phy addr of  nage with the linear addr start
             */
            
            void *src_kvaddr = page2kva(page);
            void *dst_kvaddr = page2kva(npage);
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
            ret = page_insert(to, npage, start, perm);
            // if (ret != 0) {
            //     free_page(npage);
            //     return ret;
            // }
            // /* record the mapped linear address in the page metadata */
            // npage->pra_vaddr = start;

            assert(ret == 0);
```

#### 2\. 设计实现过程
* 该函数用于 do_fork 过程中，遍历父进程的内存空间。
* 对于父进程每一页有效的内存，我们为子进程申请一个新的物理页 (alloc_page)。
* 利用 page2kva 获得物理页在内核中的虚拟地址，使用 memcpy 将父进程这一页的数据完整拷贝到子进程的新页中（深拷贝）。
* 最后利用 page_insert 将新页映射到子进程的页表中，权限 (perm) 保持与父进程一致。

-----

### 练习3: 阅读分析源代码 (fork/exec/wait/exit)

#### 1\. fork/exec/wait/exit 执行流程分析

  * **fork (创建一个新进程)**

      * **流程**: `do_fork` -\> `alloc_proc` (分配PCB) -\> `setup_kstack` (分配内核栈) -\> `copy_mm` (复制内存) -\> `copy_thread` (复制上下文) -\> `wakeup_proc` (设为就绪)。
      * **态**: 全程在**内核态**完成。用户态通过系统调用 `sys_fork` 陷入内核。
      * **返回**: 父进程返回子进程 PID，子进程返回 0（通过修改 trapframe 中的 `a0` 寄存器）。

  * **exec (执行新程序)**

      * **流程**: `do_execve` -\> 检查文件名 -\> 回收当前进程内存 (`exit_mmap`) -\> `load_icode` (加载ELF，建立新内存映射，设置 trapframe)。
      * **态**: **内核态**完成。
      * **交错**: 原进程的内存空间被清空，替换为新程序的代码和数据。原进程身份保留（PID不变），但“灵魂”（代码数据）变了。

  * **wait (等待子进程)**

      * **流程**: `do_wait` -\> 查找子进程。
          * 如果有 ZOMBIE 子进程：回收其剩余资源（内核栈、PCB），返回。
          * 如果没有 ZOMBIE 但有子进程：`schedule` 让出 CPU，进入 `SLEEPING` 状态。
      * **态**: **内核态**。

  * **exit (进程退出)**

      * **流程**: `do_exit` -\> 回收大部分内存 (`mm_destroy`) -\> 设为 `ZOMBIE` 状态 -\> 唤醒父进程 -\> 主动调度 `schedule`。
      * **态**: **内核态**。

#### 2\. 用户态进程执行状态生命周期图

```text
(alloc_proc)           (wakeup_proc)
UNINIT --------------> RUNNABLE <=========> RUNNING
                          ^       (schedule)   |
                          |                    | (do_exit)
                          |                    V
(do_wait/do_sleep/yield)  |                 ZOMBIE
      +-------------------+                    |
      |   (event happens / timeout)            | (father calls do_wait)
      V                                        V
   SLEEPING                                  DEAD
                                     (kfree proc struct)
```
* UNINIT: 进程刚被创建 (alloc_proc)。
* RUNNABLE: 进程初始化完毕或被唤醒，在就绪队列中等待 CPU。
* RUNNING: 进程正在 CPU 上执行 (proc_run)。
* SLEEPING: 进程主动放弃 CPU (do_yield, do_sleep) 或等待子进程 (do_wait)。
* ZOMBIE: 进程已退出 (do_exit)，但父进程尚未回收其 PCB。
* DEAD: 父进程回收资源后，进程彻底消失。
-----

### 扩展练习 Challenge: 实现 Copy on Write (COW)

这是一个 Big Challenge。要在 ucore 中实现 COW，你需要修改内存复制逻辑和页错误处理逻辑。

#### 1\. 设计思路

  * **核心**: `fork` 时不实际拷贝物理内存，而是让父子进程共享同一块物理内存。
  * **关键点**:
    1.  将共享的页表项（PTE）权限设置为 **只读 (Read-Only)**，同时在页表项的保留位（或软件位）中标记这是一个“COW页”。
    2.  当父子任何一方尝试**写**这个页面时，CPU 触发 Page Fault (Exception Cause 15: Store Page Fault)。
    3.  在 Page Fault 处理函数中，检测到是写 COW 页，则分配新物理页，拷贝数据，更新页表映射为可写 (`PTE_W`)，并取消共享。

#### 2\. 代码修改部分

**A. 修改 `kern/mm/pmm.c` 中的 `copy_range`**
不要使用 `memcpy`，而是建立共享映射。

```c
// 修改后的 copy_range (COW 版本)
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    
    do {
        pte_t *ptep = get_pte(from, start, 0);
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        
        if (*ptep & PTE_V) {
            struct Page *page = pte2page(*ptep);
            // 只有用户可写的页才需要 COW，只读页直接共享即可
            uint32_t perm = (*ptep & PTE_USER);
            
            if (perm & PTE_W) {
                // 去掉写权限，实现只读共享
                perm &= ~PTE_W;
                *ptep = pte_create(page2ppn(page), PTE_V | perm);
                tlb_invalidate(from, start); // 刷新 TLB
            }
            
            // 将该物理页映射到子进程页表，使用相同的只读权限
            // page_insert 会自动增加 page 的引用计数 (ref)
            int ret = page_insert(to, page, start, perm);
            if (ret != 0) return ret;
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```

**B. 修改 `kern/mm/vmm.c` 中的 `do_pgfault` (你需要自己找到这个文件)**
这是处理缺页异常的地方，需要增加对 COW 的支持。

```c
// 伪代码/参考代码逻辑，需放入 do_pgfault 函数中
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
    // ... 前置检查 ...
    
    // 获取对应的 PTE
    pte_t *ptep = NULL;
    // 假设 get_pte 已经找到页表项
    
    // 判断是否是 COW 情况：
    // 1. 异常原因是写错误 (Store/AMO page fault)
    // 2. PTE 存在且有效
    // 3. PTE 是只读的 (没有 PTE_W)
    // 4. 但 VMA (虚拟内存区域) 标记该段内存原本是可写的 (VM_WRITE)
    if ((error_code & 3) && (*ptep & PTE_V) && !(*ptep & PTE_W)) {
        struct Page *page = pte2page(*ptep);
        
        // 如果引用计数为 1，说明只剩当前进程在用，直接恢复写权限即可
        if (page_ref(page) == 1) {
             *ptep |= PTE_W;
             tlb_invalidate(mm->pgdir, addr);
        } 
        else {
            // 引用计数 > 1，需要分裂 (Copy)
            struct Page *npage = alloc_page();
            if (npage == NULL) return -E_NO_MEM;
            
            // 复制数据
            void *src_kvaddr = page2kva(page);
            void *dst_kvaddr = page2kva(npage);
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
            
            // 建立新映射：允许写
            // page_insert 会处理旧 page 的 ref 减 1，新 npage 的 ref 加 1
            page_insert(mm->pgdir, npage, addr, PTE_U | PTE_W | PTE_R | PTE_V);
        }
        return 0; // 处理成功
    }
    
    // ... 其他缺页处理 ...
}
```

#### 3\. 关于 Dirty Cow

Dirty Cow 漏洞源于 Linux 内核在处理 Copy-on-Write 时存在竞态条件。攻击者通过利用该漏洞，可以在只读映射被解除前的一瞬间写入数据，从而修改只读文件（如 `/etc/passwd`）。
**在 ucore 中模拟建议**：由于 ucore 是单核且不支持抢占式内核（Lab5 阶段），很难复现真实的竞态条件。但在多核 SMP 实现中，如果在“检查引用计数”和“执行写入”之间发生了上下文切换或另一核修改了页表，就可能引入类似 Bug。

### 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

在 ucore lab5 中，用户程序是在编译内核时，通过链接器脚本（Makefile 中的 `ld` 命令）直接链接到内核镜像的数据段中的。代码中的 `KERNEL_EXECVE` 宏引用了 `_binary_obj___user_exit_out_start` 这样的符号，这些符号是由 `ld` 将二进制文件转为目标文件时自动生成的。
**与常用操作系统区别**: 常用 OS（如 Windows/Linux）是从**文件系统**中读取可执行文件到内存。
**原因**: ucore 目前还没有完善的文件系统，为了简化实验，暂时将用户程序二进制数据内嵌到内核代码中，通过 `do_execve` -\> `load_icode` 就像读取文件一样读取这段内存区域。