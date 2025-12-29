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
#### 1. 核心设计思路
基于ucore现有虚拟内存框架，在`fork`时父子进程共享物理页（移除写权限+标记COW），首次写操作触发缺页异常时完成页面拷贝，核心依赖**页引用计数**和**缺页异常处理**实现。

#### 2. 有限状态自动机（COW页状态转换）
| 状态 | 触发条件 | 转换目标 | 操作 |
|------|----------|----------|------|
| 初始态（父进程独占页） | fork创建子进程 | 共享态（COW） | 1. 清除PTE_W（写权限）；2. 页引用计数+1；3. 子进程映射同物理页并标记COW |
| 共享态（COW） | 进程首次写页且refcount>1 | 独占态（新页） | 1. 分配新物理页；2. 拷贝原页数据；3. 当前进程PTE指向新页并恢复写权限；4. 原页refcount-1；5. 刷新TLB |
| 共享态（COW） | 进程首次写页且refcount=1 | 独占态（原页） | 1. 恢复PTE_W；2. 清除COW标记；3. 刷新TLB |
| 共享态/独占态 | 进程退出/解除映射 | 释放态 | 1. refcount-1；2. 若refcount=0，释放物理页 |

#### 3. 关键数据结构扩展
- **页引用计数**：复用ucore`struct Page`的`ref`字段（原子操作保护），表示物理页被多少进程共享。
- **PTE标记**：利用PTE的保留位或复用`PTE_RSW`作为COW标记（`PTE_COW`），与`PTE_W`互斥。


#### 4. DirtyCOW漏洞模拟与修复
##### 漏洞原理
DirtyCOW利用COW写时拷贝的竞态：多个进程同时写COW页，绕过权限检查修改只读内存。
##### 漏洞复现（简化版）
```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

int *shared;
void *write_thread(void *arg) {
    while (1) {
        *shared = 999; // 持续写COW页
    }
}

int main() {
    shared = malloc(4);
    *shared = 100;
    mprotect(shared, PGSIZE, PROT_READ); // 标记为只读
    pid_t pid = fork();
    if (pid == 0) {
        pthread_t tid;
        pthread_create(&tid, NULL, write_thread, NULL);
        while (1) {
            // 竞态触发：在COW拷贝前修改数据
            printf("子进程：shared=%d\n", *shared);
            sleep(1);
        }
    } else {
        wait(NULL);
        return 0;
    }
}
```
##### 修复方案
在`do_pgfault`中增加**二次校验**，加锁后重新检查引用计数和PTE状态：
```c
// 在do_pgfault的COW处理逻辑中
spin_lock(&page_lock);
// 二次校验：防止加锁前refcount已变化
if (page_ref(old_page) != ref || !(*ptep & PTE_COW)) {
    spin_unlock(&page_lock);
    return -E_PERM;
}
// 后续拷贝/权限修改逻辑
```

本实现基于ucore现有虚拟内存框架，通过`fork`时共享页+写时拷贝，减少内存冗余和`fork`开销。核心状态转换通过有限状态机明确，覆盖了COW页的创建、写触发拷贝、释放全流程。针对DirtyCOW漏洞，通过加锁和二次校验修复竞态问题，保证内存安全。测试用例验证了COW的核心功能，同时模拟了经典漏洞并给出修复方案。

##### 关于 Dirty Cow

Dirty Cow 漏洞源于 Linux 内核在处理 Copy-on-Write 时存在竞态条件。攻击者通过利用该漏洞，可以在只读映射被解除前的一瞬间写入数据，从而修改只读文件（如 `/etc/passwd`）。
**在 ucore 中模拟建议**：由于 ucore 是单核且不支持抢占式内核（Lab5 阶段），很难复现真实的竞态条件。但在多核 SMP 实现中，如果在“检查引用计数”和“执行写入”之间发生了上下文切换或另一核修改了页表，就可能引入类似 Bug。
##### **具体设计文档源码及测试样例见COW_design.md文档**

### 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

在 ucore lab5 中，用户程序是在编译内核时，通过链接器脚本（Makefile 中的 `ld` 命令）直接链接到内核镜像的数据段中的。代码中的 `KERNEL_EXECVE` 宏引用了 `_binary_obj___user_exit_out_start` 这样的符号，这些符号是由 `ld` 将二进制文件转为目标文件时自动生成的。
**与常用操作系统区别**: 常用 OS（如 Windows/Linux）是从**文件系统**中读取可执行文件到内存。
**原因**: ucore 目前还没有完善的文件系统，为了简化实验，暂时将用户程序二进制数据内嵌到内核代码中，通过 `do_execve` -\> `load_icode` 就像读取文件一样读取这段内存区域。