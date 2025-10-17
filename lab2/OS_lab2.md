# 操作系统lab2实验报告
<center><p><font face="黑体" size=7><b>操作系统lab2实验报告</b></font></p></center>
<center><p><font face="楷体" size=4>姓名：宋卓伦，赵雨萱，何立烽&nbsp;&nbsp;&nbsp;&nbsp;学号：2311095，2311100，2311101</font></p></center>
<center><p><font face="楷体" size=4>南开大学计算机学院、密码与网络空间安全学院</font></p></center>
<!-- <br> -->

## 实验名称：物理内存管理

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

## 练习1
### 理解 First-Fit 连续物理内存分配算法（思考题）
First-Fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。

请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析`default_init`，`default_init_memmap`，`default_alloc_pages`， `default_free_pages`等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：
- 你的 First-Fit 算法是否有进一步的改进空间？

---

### 各函数作用及物理内存分配过程分析

程序通过 `default_pmm_manager` 结构体，利用函数指针将具体的内存管理算法（First-Fit）封装起来。物理内存的分配和释放过程主要围绕一个按地址排序的空闲块双向链表 `free_list` 展开。

**各核心函数作用分析如下：**

* **`default_init()`**
    * **作用**: 初始化内存管理器。
    * **描述**: 这是系统启动时调用的第一个函数。它通过调用 `list_init(&free_list)` 创建一个空的双向链表，然后将全局空闲页总数 `nr_free` 设置为0。
    ```c++
    list_init(list_entry_t *elm) {
        elm->prev = elm->next = elm;
    }
    ```
    在这一阶段，内核还不知道具体有哪些物理内存是可用的。

* **`default_init_memmap()`**
    * **作用**: 将一块新发现的、可用的物理内存区域，格式化后加入到空闲链表中。
    * **描述**: 函数接收一个指向 `Page` 结构体的指针 `base` 和连续页的数量 `n`。它首先遍历这 `n` 个页，清除它们的 `flags` 标志位并将引用计数 `ref` 置为0。
    ```c++
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    ```
    接着，它将起始页 `base` 的 `property` 字段设置为 `n`，并调用 `SetPageProperty(base)`，以此明确标记这是一个大小为 `n` 的空闲块的“头部”。最后，将 `n` 加到 `nr_free` 上，
    ```c++
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    ```
    并通过一个 `while` 循环找到正确的位置(从头开始寻找比它大的空闲块，如果没有就放在最后)，将这个新的空闲块插入到 `free_list` 中，确保整个链表始终按照物理地址从小到大排序。
    ```c++
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
    ```

* **`default_alloc_pages()`**
    * **作用**: 实现 First-Fit 算法的核心，负责查找并分配 `n` 个连续的物理页。
    * **描述**:
        1.  **检查**: 首先进行合法性检查，确保 `n > 0` 且总空闲页数 `nr_free` 足够，否则返回 `NULL`。
        ```c++
        assert(n > 0);
        if (n > nr_free) {
            return NULL;
        }
        ```
        2.  **查找**: 从 `free_list` 的头部开始遍历，寻找**第一个** `property >= n` 的空闲块。一旦找到，立刻用 `break` 停止搜索。
        ```c++
        while ((le = list_next(le)) != &free_list) {
            struct Page *p = le2page(le, page_link);
            if (p->property >= n) {
                page = p;
                break;
            }
        }
        ```
        3.  **分割**: 如果找到的块 `page` 比请求的 `n` 大 (`page->property > n`)，则进行分割。将 `page` 从 `free_list` 中移除，然后计算出剩余部分（从 `page + n` 开始），将其大小（`page->property - n`）记录在新头部，并作为一个新的小空闲块重新插入 `free_list`。
        ```c++
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
        ```
        如果找到的块大小和请求的大小一样时就直接占用，无需分割。

        4.  **更新**: 从 `nr_free` 中减去 `n`，调用 `ClearPageProperty(page)` 清除已分配块的“空闲头部”标志。
        ```c++
        nr_free -= n;
        ClearPageProperty(page);
        ```
        5.  **返回**: 返回指向已分配内存块头部的指针 `page`。

* **`default_free_pages()`**
    * **作用**: 将一块使用完毕的内存归还给系统，并尝试与相邻的空闲块合并。
    * **描述**:
        1.  **标记**: 函数接收要释放的内存块 `base` 和大小 `n`，重置其内部所有页的标志位和引用计数。然后将其标记为一个新的、大小为 `n` 的空闲块。
        ```c++
        for (; p != base + n; p ++) {
            assert(!PageReserved(p) && !PageProperty(p));
            p->flags = 0;
            set_page_ref(p, 0);
        }
        base->property = n;
        SetPageProperty(base);
        nr_free += n;
         ```
        2.  **插入**: 将这个新释放的块按地址顺序插入到 `free_list` 中。仍然需要升序插入。
        ```c++
        if (list_empty(&free_list)) {
            list_add(&free_list, &(base->page_link));
        } else {
            list_entry_t* le = &free_list;
            while ((le = list_next(le)) != &free_list) {
                struct Page* page = le2page(le, page_link);
                if (base < page) {
                    list_add_before(le, &(base->page_link));
                    break;
                } else if (list_next(le) == &free_list) {
                    list_add(le, &(base->page_link));
                }
            }
        }
        ```
        3.  **合并**: 这是防止内存碎片化的关键。它会检查新插入块在链表中的**前一个**和**后一个**空闲块，判断它们在物理地址上是否紧邻。如果紧邻，就将它们合并成一个更大的空闲块，更新 `property` 值，并从链表中删除被“吃掉”的那个块。
        ```c++
        list_entry_t* le = list_prev(&(base->page_link));
        if (le != &free_list) {
            p = le2page(le, page_link);
            if (p + p->property == base) {
                p->property += base->property;
                ClearPageProperty(base);
                list_del(&(base->page_link));
                base = p;
            }
        }

        le = list_next(&(base->page_link));
        if (le != &free_list) {
            p = le2page(le, page_link);
            if (base + base->property == p) {
                base->property += p->property;
                ClearPageProperty(p);
                list_del(&(p->page_link));
            }
        }
        ```
* **`default_nr_free_pages()`**
    * **作用**: 查询当前空闲页的总数。
    * **描述**: 直接返回全局变量 `nr_free` 的值。

* **`default_check()`**
    * **作用**: 内置的自检程序，用于验证内存管理算法的正确性。
    * **描述**: 通过一系列预设的分配和释放操作，以及 `assert` 断言，来测试分配、释放、分割和合并等核心逻辑是否按预期工作。

---
### **你的 First-Fit 算法是否有进一步的改进空间？**
是的，First-Fit 算法虽然实现简单直观，但其策略本身和实现方式都存在很大的改进空间。

#### 一、采用更优秀的分配算法进行替代

**1.缺点：** First-Fit 算法的核心缺陷在于其简单的查找策略容易导致内存布局的恶化。由于每次分配都固定从链表头部开始搜索，这会使得内存的低地址区域被反复切割，从而产生大量难以再利用的微小内存碎片。与此同时，随着头部碎片的累积，后续需要较大内存的分配请求，将不得不耗费更多时间跳过这些无用的小碎片，导致查找效率降低。

**2. 改进方案（即采用新算法）：**
   针对这些固有缺陷，其“改进空间”主要体现在采用更优越的分配策略来替代它，而这些方法在后面的练习与challenge中都有设计，比如说**练习二**的 **Best-Fit**（每次选择与需求大小最接近的空闲块），**挑战练习**的 **Buddy System**（以2的倍数进行切割，选择最适合的大小），也可用**Next-Fit**（一个指针进行遍历，下次选择从指针位置开始搜索First-Fit）

#### 二、在保持 First-Fit 核心思想不变的前提下进行优化

当前 `default_pmm.c` 的实现是基于一个简单的双向链表，查找第一个足够大的块的时间复杂度是 **O(n)**，其中 n 是空闲块的数量。当空闲块非常多时，这个线性扫描的效率会很低。

一个可行的改进方案是**优化承载空闲块的数据结构**，例如：

**1.使用多级链表/分离适配 (Segregated Lists)**：
  我们可以创建多个空闲链表，每个链表负责一个特定的大小范围（例如，一个链表只存放 1-8 页的块，另一个存放 9-16 页的块，等等）。当请求一个大小为 `k` 的块时，我们只需要在对应大小范围的链表里进行 First-Fit 查找即可。这极大地减少了需要扫描的节点数量，是一种典型的空间换时间优化。

 **2.使用更高级的数据结构**：
  例如，我们可以用**平衡二叉搜索树**或**跳表 (Skip List)** 来组织空闲块（按大小排序）。这些数据结构可以将查找“第一个大于等于 k 的块”这个操作的时间复杂度从 O(n) 优化到 **O(log n)**。虽然这会增加实现的复杂度和插入/删除操作的开销，但在查找密集型的场景下，性能提升将是显著的。


## 练习2

### 实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考`kern/mm/default_pmm.c`对 First-Fit 算法的实现，编程实现 Best-Fit 页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？

---

### 设计与实现过程

**核心逻辑修改**：我们需要对 `best_fit_alloc_pages` 函数进行修改。与 First-Fit 找到第一个满足条件的块就停止不同，Best-Fit 必须遍历整个空闲链表，找到那个能够满足需求（`size >= n`）且尺寸最接近的块。

### 物理内存的分配与释放

#### 内存分配 (`best_fit_alloc_pages`)

当系统请求分配 `n` 个页时，`best_fit_alloc_pages` 函数执行以下步骤：
1.  **初始化**：与 First-Fit 算法不同，我们定义一个 `page` 指针初始化为 `NULL`，用于记录最终找到的最佳空闲块，并初始化 `min_size` 进行 `nr_free + 1` 的操作，用于后面选择最合适的空闲块大小。
    ```c++
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
    ```

2.  **寻找最佳匹配**：使用 `while` 循环**遍历整个** `free_list` 链表，**不会提前 `break`**。在循环中，对每一个空闲块 `p`，进行判断：首先，检查块的大小 `p->property` 是否满足请求 (`>= n`)。如果满足，则进一步判断它是否是“更佳”的选择：即 `page` 还是 `NULL`（说明这是第一个找到的可用块），或者当前块 `p` 的大小比已记录的 `page` 的大小更小（`p->property < page->property`）。如果满足“更佳”条件，则更新 `page = p`。初始时我们把`page`的值设置的很大，比如说总空闲页数+1，这样方便第一次更新。
    ```c++
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) {
            page = p;
            min_size = p->property;
        }
    }
    ```
3.  **分配与分割**：循环结束后，`best_page` 指向了最合适的空闲块。后续的逻辑与 **First-Fit** 相同： 将 `best_page` 从 `free_list` 中移除。如果 `best_page` 的大小严格大于 `n`，则将多余的部分作为一个新的、更小的空闲块重新插入 `free_list`。更新全局空闲页数 `nr_free`，并清除已分配块的 `PG_property` 标志。
4.  **返回结果**：返回 `best_page` 指针。如果遍历完也未找到可用块，则返回 `NULL`。

#### 内存释放 (`best_fit_free_pages`)

内存释放的逻辑与 First-Fit 相同，核心在于**合并相邻空闲块**。函数首先将归还的内存块标记为新的空闲块，并根据其物理地址，将其插入到 `free_list` 的正确位置，以维持链表的地址有序性。检查新插入块在链表中的**前一个**空闲块，通过指针运算 (`p + p->property == base`) 判断两者在物理上是否紧邻。如果紧邻，则将两者合并成一个更大的块（更新前一地址块的 `property`），并从链表中删除当前块。同理，检查链表中的**后一个**空闲块，如果物理地址连续，也进行合并。

---

### **你的 Best-Fit 算法是否有进一步的改进空间？**

是的，它自身有一些缺陷还可以进行进一步的改进：

#### 性能开销大

其最大的缺点是性能。为了找到“最佳”的块，每一次内存分配都必须**遍历整个空闲链表**，时间复杂度为 $O(n)$。当系统长时间运行，`free_list` 变得很长且充满碎片时，分配性能会急剧下降。并且由于总是寻找最“贴身”的块进行分配，Best-Fit 算法最容易在分割后产生大量尺寸极小、几乎无法再被利用的外部碎片。

#### 改进方向

**优化数据结构**：最直接的改进是放弃单一链表。我们可以维护多个空闲链表，每个链表负责一个特定的大小范围。当需要分配 `n` 页时，只需在对应大小范围的链表中寻找 Best-Fit 即可，极大地减少了需要扫描的节点数量。

或者可以使用**平衡二叉搜索树**或类似的树形结构来组织空闲块（按块大小排序）。这样，查找最佳匹配块的时间复杂度可以从 $O(n)$ 优化到 $O(\log n)$，虽然这会增加实现的复杂度和插入/删除操作的开销，但在查找密集型的场景下，性能会显著提升。

## Challenge1

### buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
## Challenge2

### 任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

## Challenge3

### 硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

---

如果OS在启动时无法提前知道当前硬件的可用物理内存范围，那么它就必须自己主动探索。

### 方法一：与固件/引导加载程序通信

这是现代操作系统采用的**标准、安全且最高效**的方法。OS 依赖于在它之前运行的底层软件（如 BIOS/UEFI 或 OpenSBI）来提供硬件信息。

OS 可以通过以下几种标准接口来“询问”内存布局：

#### 1. x86 平台: BIOS/UEFI 服务
* 传统 BIOS - E820 中断:  
    * OS 在启动初期可以调用 BIOS 的 `INT 15h` 中断，并将 `AX` 寄存器设置为 `E820h`。BIOS 会返回一个详细的内存区域描述符列表（E820 内存映射），其中详细说明了物理地址空间中每个区域的起始地址、长度和类型（如可用内存、保留内存、ACPI 数据等）。 OS 凭借此列表，就能精确地构建出物理内存的全貌。
* 现代 UEFI - `GetMemoryMap()` 服务:
    * UEFI 启动服务提供了 `GetMemoryMap()` 函数。 OS 在调用 `ExitBootServices()` 之前，可以通过此函数获取比 E820 更丰富、更现代的内存映射表，这是现代 x86 操作系统的标准做法。

#### 2. RISC-V / ARM 平台: 设备树 (Device Tree Blob, DTB)
   - 像 OpenSBI (RISC-V) 或 U-Boot (ARM) 这样的 Bootloader 会探测硬件，并将硬件信息编译成一个名为**设备树**的标准化数据结构。Bootloader 启动内核时，会将 DTB 的物理地址通过寄存器（在 RISC-V 中通常是 `a1`）传递给内核。内核的首要任务之一就是解析此 DTB。DTB 中的 `/memory` 节点明确定义了 DRAM 的起始物理地址和大小。
     ```dts
     // 设备树中的内存节点示例
     memory@80000000 {
         device_type = "memory";
         reg = <0x0 0x80000000 0x0 0x8000000>; // 起始地址 0x80000000, 大小 128MB
     };
     ```
     通过读取该信息，OS 就能准确知道可用的 DRAM 范围。

#### 3. ACPI 
   - ACPI 是一种比 E820 更高级的规范，固件会提供一系列的系统描述表。OS 内核可以通过解析这些表来获取包括内存映射在内的极其详细的硬件信息。

## 方法二： OS 主动探测

假设引导加载程序非常简陋，未提供任何内存信息，那么可以对一个内存地址进行 **“写后读”** 测试，以验证它是否是可用的 RAM。

### 必要前提

我们需要 **一个可用的异常处理程序**。这是因为当 OS 试图访问一个不存在的地址时，CPU 会产生硬件异常。OS 必须能捕获此异常，记录该地址无效，然后安全地继续探测，否则会立即崩溃。此外， OS 自身代码和数据所在的内存区域，是已知的、可用的 RAM，可以作为探测的起点。并在探测期间禁用 CPU 的数据缓存，确保测试直接作用于物理内存。

### 探测步骤

1.  **选择探测粒度**: 以页（如 4KB）或更大的块为单位进行探测。
2.  **从已知地址开始**：从 `0x0` 或已知的安全区域向两端扩展。
3.  **执行测试模式**：对于一个起始地址 `A`：
    a. 保存 `A` 处的原始数据。
    b. 写入一个特定的“魔法数”（如 `0x55AA55AA`）。
    c. 读回并验证数据是否一致。
    d. 写入该魔法数的反码（如 `0xAA55AA55`）。
    e. 再次读回并验证。
    f. 恢复 `A` 处的原始数据。
4.  **建立内存映射**：
    - 如果所有步骤成功且未触发异常，则标记该内存块为**可用 RAM**。
    - 如果在读写过程中触发了硬件异常，则标记该地址为**无效**。
    - OS 不断重复此过程，扫描整个物理地址空间，最终拼凑出一张内存地图。

### 此方法的问题
- **可能触发硬件设备**：物理地址空间中不仅有 RAM，还有大量内存映射的 I/O 设备 (MMIO)。向一个网卡或磁盘控制器的寄存器地址写入“魔法数”，可能会导致设备异常、系统挂起甚至物理损坏。

因此，我们认为**操作系统应该优先通过标准接口（如 UEFI 服务、设备树）从引导加载程序获取内存映射。** 如果这些信息不可用，它可以在建立好异常处理机制后，**通过“写后读”的方式逐块探测物理地址空间**，并随时准备处理可能发生的硬件异常。