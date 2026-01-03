

# ucore Lab 8 实验报告：文件系统

## 1. 实验目的

通过完成本次实验，达到以下目标：

* **理解文件系统抽象层**：深入分析 VFS（虚拟文件系统）的数据结构（`inode`, `file`, `dentry` 等）及其在屏蔽不同文件系统差异中的作用。
* **掌握 SFS 实现细节**：通过实现 `sfs_io_nolock`，理解基于索引节点（Inode）的磁盘数据组织方式及块设备读写逻辑。
* **实现进程加载机制**：通过重写 `load_icode`，掌握如何从文件系统中解析 ELF 格式并加载到用户内存空间，以及用户栈参数（argc/argv）的构建。
* **理解“一切皆文件”**：分析设备文件（如 `stdin`, `stdout`）是如何挂载到文件系统中并被统一管理的。

---

## 2. 练习 0：填写已有实验

本实验依赖于 Lab 2~7 的代码。除了常规的代码合并外，为了支持文件系统和进程参数传递，对已有代码进行了以下关键改进：

1. **`kern/process/proc.c` - `alloc_proc**`：
* 在进程控制块初始化时，新增了 `proc->filesp = NULL;`。这是为了确保新创建的进程不会拥有野指针形式的文件描述符表，防止后续 `do_fork` 或 `do_exit` 崩溃。


2. **`kern/process/proc.c` - `do_fork**`：
* 在创建子进程时，插入了 `copy_files(clone_flags, proc)` 调用。这使得子进程能够继承（或者共享）父进程已经打开的文件描述符（例如 Shell 中的重定向或管道操作依赖此机制）。


3. **`kern/mm/pmm.c` - `boot_map_segment**`：
* 修复了在 64 位 RISC-V 环境下指针与整数转换的类型匹配问题，将指针显式转换为 `uintptr_t`，确保编译通过且地址计算正确。



---

## 3. 练习 1：完成读文件操作的实现

### 3.1 设计思路与函数作用

该练习的核心任务是实现 **`sfs_io_nolock`** 函数。该函数位于 SFS（Simple File System）层，是连接 VFS 抽象层与底层磁盘块设备的桥梁。

#### 函数：`sfs_io_nolock`

**作用**：
该函数负责将用户视角的“**字节流读写请求**”（从文件 offset 处读写 length 个字节）转换为底层视角的“**磁盘块读写请求**”（读写第 N 个 Block）。由于用户的读写范围可能不与磁盘块（4096 字节）对齐，因此该函数必须处理“首部不对齐”、“中间对齐块”和“尾部不对齐”三种情况。

**详细处理流程**：

1. **参数准备与边界检查**：
* 计算结束位置 `endpos`。
* 计算起始块索引 `blkno` 和跨越的块数 `nblks`。


2. **处理起始不对齐部分 (Head Misalignment)**：
* **判断条件**：`offset % SFS_BLKSIZE != 0`。
* **操作**：
1. 调用 `sfs_bmap_load_nolock` 将逻辑块号转换为物理块号（`ino`）。
2. 调用 `sfs_buf_op`（即 `sfs_rbuf` 或 `sfs_wbuf`）仅读写该块中从 `offset` 到块末尾的部分。


* **意义**：保护该块中不属于本次读写范围的数据不被覆盖或错误读取。


3. **处理中间完整块 (Body Alignment)**：
* **判断条件**：`nblks > 0`（排除首尾后剩余的完整块）。
* **操作**：
1. 循环遍历每一个完整块。
2. 调用 `sfs_bmap_load_nolock` 获取物理块号。
3. 调用 `sfs_block_op`（即 `sfs_rblock` 或 `sfs_wblock`）直接对整个 4KB 块进行读写。


* **意义**：整块读写通常直接通过 DMA 或高效的块设备接口进行，性能最高。


4. **处理末尾不对齐部分 (Tail Misalignment)**：
* **判断条件**：`endpos % SFS_BLKSIZE != 0`。
* **操作**：
1. 获取最后一个块的物理块号。
2. 调用 `sfs_buf_op` 读写该块从 0 开始到 `endpos` 偏移的部分。





### 3.2 关键代码实现片段

```c
// (1) 处理起始不对齐
if ((blkoff = offset % SFS_BLKSIZE) != 0) {
    size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) goto out;
    if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) goto out;
    // 更新偏移量和剩余块数...
}

// (2) 处理中间对齐块
while (nblks > 0) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) goto out;
    if ((ret = sfs_block_op(sfs, buf, ino, 1)) != 0) goto out;
    // 更新偏移量...
}

// (3) 处理末尾不对齐
if ((size = endpos % SFS_BLKSIZE) != 0) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) goto out;
    if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) goto out;
}

```

---

## 4. 练习 2：基于文件系统的执行程序机制

### 4.1 设计思路与函数作用

该练习的核心是重写 **`load_icode`** 函数。在 Lab 5 中，该函数直接从内存读取二进制；而在 Lab 8 中，程序存储在磁盘上，且必须支持命令行参数传递（如 `sh` 传递参数给 `ls`）。

#### 函数：`load_icode`

**作用**：
加载并解析磁盘上的 ELF 可执行文件，建立用户进程的内存空间，设置用户栈，并将 `argc` 和 `argv` 参数压入用户栈，最终构建 `Trapframe` 以便切换到用户态。

**详细步骤说明**：

1. **建立内存空间**：
* 调用 `mm_create` 和 `setup_pgdir` 创建新的内存管理结构和页表。


2. **解析并加载 ELF 段**：
* **读取文件**：利用 `load_icode_read`（封装了 `sysfile_seek` 和 `sysfile_read`）从文件描述符 `fd` 读取 ELF Header 和 Program Header。
* **建立 VMA**：根据 ELF Header 信息，调用 `mm_map` 建立虚拟内存区域（代码段、数据段）。
* **数据拷贝**：按页申请物理内存，并再次调用 `load_icode_read` 将磁盘上的代码和数据读入内存。
* **BSS 处理**：对于 `memsz > filesz` 的部分（BSS 段），将其清零。


3. **构建用户栈 (User Stack)**：
* 调用 `mm_map` 建立用户栈的 VMA（`USTACKTOP` 向下增长）。
* 预先分配物理页（例如 4 页）以防止栈访问缺页。


4. **参数压栈**：
* **压入字符串**：将 `kargv` 中的字符串逐个拷贝到栈顶（`sp` 向下移动）。
* **对齐**：将 `sp` 进行指针大小对齐（RISC-V 要求）。
* **压入指针数组**：在栈上开辟一个 `char *argv[]` 数组，将刚才字符串在栈中的地址填入数组，并以 `NULL` 结尾。


5. **设置中断帧 (Trapframe)**：
* `tf->gpr.sp`：设置为此时的用户栈顶。
* `tf->gpr.a0`：设置为 `argc`。
* `tf->gpr.a1`：设置为 `argv` 数组在栈上的首地址。
* `tf->epc`：设置为 ELF 的入口地址 (`e_entry`)。



此过程确保了程序启动时，`main(int argc, char **argv)` 函数能从寄存器 `a0` 和 `a1` 获取到正确的参数。


---

## 5. 扩展练习 Challenge 1：UNIX PIPE 机制设计方案

### 5.1 设计概述

UNIX 管道（Pipe）本质上是内核中的一块**环形缓冲区（Ring Buffer）**。它不对应磁盘上的任何物理数据块，而是由内核内存模拟的一个虚拟文件。为了融入 ucore 的 VFS 架构，我们需要创建一个特殊的 `inode`，将其类型标记为管道，并挂载相应的内存缓冲区。

### 5.2 核心数据结构设计

我们需要定义一个 `pipe_info` 结构体，用于管理缓冲区的状态和同步。该结构体通常作为 `inode` 的私有数据存在。

```c
/* kern/fs/pipe/pipe.h */

// 定义管道缓冲区大小，通常为 4KB (一页)
#define PIPE_SIZE 4096

struct pipe_info {
    // === 数据缓冲区 ===
    char data[PIPE_SIZE];    // 环形数据缓冲区
    uint16_t head;           // 写指针 (Write Pointer)，指向下一个写入位置
    uint16_t tail;           // 读指针 (Read Pointer)，指向下一个读取位置
    
    // === 状态管理 ===
    bool is_closed;          // 管道是否已关闭标记
    uint32_t nreaders;       // 当前打开此管道读端的进程数
    uint32_t nwriters;       // 当前打开此管道写端的进程数
    
    // === 同步互斥 ===
    semaphore_t mutex;       // 互斥锁：保证对缓冲区、指针、计数的原子操作
    wait_queue_t wait_reader;// 条件变量：缓冲区空时，读者在此等待
    wait_queue_t wait_writer;// 条件变量：缓冲区满时，写者在此等待
};

```

### 5.3 接口逻辑与同步互斥设计

在 ucore 中，`pipe` 的读写操作将通过 VFS 的 `vop_read`和 `vop_write` 映射到具体的管道操作函数。

#### 1. 创建管道：`pipe(int fd[2])`

* **语义**：创建一对文件描述符，`fd[0]` 为读端，`fd[1]` 为写端。
* **实现流程**：
1. 分配一个新的 `inode` 和 `pipe_info` 结构。
2. 初始化环形缓冲区 `head = tail = 0`，初始化信号量和等待队列。
3. 创建两个 `file` 结构体：
* File A (读端): 关联该 `inode`，模式设为 `O_RDONLY`。
* File B (写端): 关联该 `inode`，模式设为 `O_WRONLY`。


4. `pipe_info->nreaders = 1`, `pipe_info->nwriters = 1`。



#### 2. 读操作：`pipe_read` (消费者)

* **同步互斥逻辑**：
1. **加锁** (`down(&mutex)`)。
2. **循环检查 (While Loop)**：如果缓冲区为空 (`head == tail`)：
* **边界情况**：如果 `nwriters == 0`（所有写端已关闭），说明数据已传输完毕，**释放锁并返回 0 (EOF)**。
* 否则，执行 **等待**：调用 `wait_current_set` 将自己加入 `wait_reader` 队列，**释放锁** 并调用 `schedule()` 让出 CPU。被唤醒后重新加锁检查。


3. **读取数据**：
* 计算可读字节数，从 `data[tail]` 开始读取。
* 利用取模运算处理环形回绕：`idx = tail % PIPE_SIZE`。
* 更新读指针：`tail = (tail + len) % PIPE_SIZE`。


4. **唤醒写者**：既然读走了数据，缓冲区有了空位，调用 `wakeup_queue(&wait_writer)` 唤醒阻塞的写者。
5. **解锁** (`up(&mutex)`) 并返回读取字节数。



#### 3. 写操作：`pipe_write` (生产者)

* **同步互斥逻辑**：
1. **加锁** (`down(&mutex)`)。
2. **循环检查**：如果缓冲区已满 (`(head + 1) % PIPE_SIZE == tail`)：
* **边界情况**：如果 `nreaders == 0`（所有读端已关闭），写入无意义。发送 `SIGPIPE` 信号给当前进程，或者**释放锁并返回 -E_PIPE 错误**。
* 否则，执行 **等待**：加入 `wait_writer` 队列，释放锁并调度。


3. **写入数据**：
* 将数据写入 `data[head]`，利用取模运算处理回绕。
* 更新写指针：`head = (head + len) % PIPE_SIZE`。


4. **唤醒读者**：缓冲区有了新数据，调用 `wakeup_queue(&wait_reader)` 唤醒阻塞的读者。
5. **解锁** (`up(&mutex)`)。



---

## 6. 扩展练习 Challenge 2：UNIX 软连接与硬连接机制设计方案

### 6.1 设计原理对比

* **硬连接 (Hard Link)**：是文件系统层面的“别名”。多个目录项（Dentry）指向同一个 Inode。删除其中一个别名不影响文件内容，只有引用计数归零时才真正删除。
* **软连接 (Symbolic Link)**：是应用层面的“快捷方式”。它是一个独立的文件（有自己的 Inode），文件内容是目标文件的路径字符串。

### 6.2 硬连接 (Hard Link) 详细设计

#### 1. 数据结构复用

不需要新增复杂结构，关键在于激活 SFS Inode 中的引用计数器：

```c
struct sfs_disk_inode {
    // ... 其他字段 ...
    uint16_t nlinks; // 硬链接计数：指向该 Inode 的目录项数量
};

```

#### 2. 接口实现逻辑

* **`sys_link(old_path, new_path)`**：
1. 解析 `old_path` 获得 `old_inode`。**互斥检查**：防止在链接过程中 `old_inode` 被删除。
2. **目录限制**：检查 `old_inode` 是否为目录。通常禁止对目录建立硬链接（防止文件系统出现环路）。
3. 在 `new_path` 所在的父目录下新建一个目录项 (Entry)。
4. **关键操作**：将新目录项的 `ino` (索引节点号) 直接设置为 `old_inode` 的编号。
5. **原子更新**：`old_inode->nlinks++`，标记 Inode 为 Dirty 并写回磁盘。


* **`sys_unlink(path)`**：
1. 找到 `path` 对应的目录项和 Inode。
2. 删除目录项。
3. `inode->nlinks--`。
4. **资源回收判断**：如果 `nlinks == 0` **且** 该文件的内存引用计数（`open_count`）为 0，则调用 `sfs_reclaim` 释放数据块和 Inode；否则仅更新 `nlinks`。



### 6.3 软连接 (Soft Link) 详细设计

#### 1. 数据结构扩展

软连接需要一种新的文件类型标识，以便 VFS 识别并特殊处理。

```c
/* kern/fs/sfs/sfs.h */
#define SFS_TYPE_LINK  3  // 新增类型：符号链接

```

#### 2. 接口实现逻辑

* **`sys_symlink(target_path, link_path)`**：
1. 创建一个新文件 `link_path`。
2. 将新文件的 Inode `type` 设置为 `SFS_TYPE_LINK`。
3. 将 `target_path` 字符串作为**文件内容**写入该 Inode 的数据块中。


* **路径查找 (`vfs_lookup`) 的递归处理**：
这是实现软连接的核心。当 `vfs_lookup` 解析路径时（例如解析 `/a/b/c`）：
1. 如果发现中间节点 `b` 的 Inode 类型是 `SFS_TYPE_LINK`。
2. **读取内容**：从 `b` 的数据块中读取目标路径字符串（例如 `/x/y`）。
3. **路径替换**：将当前剩余路径 `/c` 接在目标路径后，形成 `/x/y/c`。
4. **递归解析**：对新路径 `/x/y/c` 重新调用查找逻辑。
5. **死循环防护**：必须维护一个递归深度计数器（如 `max_follows = 5`）。如果链式指向过深（A->B->A），则返回 `-ELOOP` 错误，防止内核栈溢出或死锁。



---

### 总结：关键差异表

| 特性 | UNIX Pipe (管道) | Hard Link (硬连接) | Soft Link (软连接) |
| --- | --- | --- | --- |
| **存储介质** | 内存 (RAM) | 磁盘 (引用计数) | 磁盘 (数据块) |
| **对象本质** | 环形缓冲区 | 同一个 Inode 的多入口 | 存储路径的特殊文件 |
| **跨文件系统** | 不涉及 (进程间内存) | **否** (Inode 编号唯一性限制) | **是** (基于路径字符串) |
| **同步互斥重点** | 读写指针的原子性、条件变量唤醒 | `nlinks` 的原子增减 | 路径解析的死循环检测 |