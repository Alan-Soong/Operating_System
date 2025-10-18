# 伙伴系统物理内存管理器（Buddy System PMM）说明文档

## 1. 功能概述

该代码实现了一个经典的**伙伴系统（Buddy System）物理内存分配算法。它以 $2^k$ 页（Page）为单位管理物理内存块，其中 $k$ 是块的阶（Order）**。

- **分配原则：** 当需要 $n$ 个页时，向上取整找到最小的 $2^{\text{need}} \ge n$ 的块大小。如果找不到直接匹配的空闲块，则从更高的阶 $o$ 中取出一个块，并将其递归地二等分（分裂）直到达到 $\text{need}$ 阶。分裂出的右半部分（伙伴块）会被放回低一阶的空闲链表中。
- **释放原则：** 释放一个 $2^k$ 页的块时，会检查其伙伴块是否空闲。如果空闲，则将两者合并成一个 $2^{k+1}$ 页的块，并递归地尝试向上合并，直到达到最高阶或其伙伴块被占用。
- **链表管理：** 系统维护了 $MAX\_ORDER + 1$ 条空闲链表，`free_list_heads[o]` 存储着阶为 $o$ 的空闲块。每个空闲块的**头页**通过 `Page.page_link` 链接，并且其 `Page.property` 字段记录了该块的大小（页数 $2^o$），同时设置了 `PageProperty` 标志。

## 2. 关键宏定义与数据结构

| **名称**                                                     | **描述**                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `MAX_ORDER`                                                  | 允许的最大块阶数（最大块大小为 $2^{MAX\_ORDER}$ 页）。设置为 16，即最大块为 $2^{16}$ 页（约 256MB）。 |
| `free_list_heads[]`                                          | 存储各阶空闲块链表头的数组，共 $MAX\_ORDER + 1$ 条。         |
| `free_count[]`                                               | 各阶空闲块的数量统计。                                       |
| `total_free_pages`                                           | 当前系统中所有空闲页的总数。                                 |
| `PageReserved(p)` / `ClearPageReserved(p)`                   | uCore 提供的宏，用于检查/清除页的保留标志。                  |
| `PageProperty(p)` / `SetPageProperty(p)` / `ClearPageProperty(p)` | uCore 提供的宏，用于检查/设置/清除页的属性标志（本 PMM 用来标记空闲块的头页）。 |
| `Page.property`                                              | 空闲块头页存储该块的页数（$2^o$）。                          |
| `Page.page_link`                                             | 用于将空闲块头页链接到 `free_list_heads` 的双向链表节点。    |

## 3. 工具函数

| **函数名**                                          | **描述**                                                     |
| --------------------------------------------------- | ------------------------------------------------------------ |
| `page_to_index(struct Page *pg)`                    | 计算 `pg` 在全局 `pages` 数组中的索引。                      |
| `index_to_page(size_t idx)`                         | 根据索引计算 `pages` 数组中的页结构体指针。                  |
| `order_of_pages(size_t pages)`                      | 向上取整计算给定页数所需的最小阶 $o$ ($2^o \ge \text{pages}$)。 |
| `largest_aligned_order(size_t start_idx, size_t n)` | 计算从 `start_idx` 开始的 `n` 页连续区间内，满足 $2^k \le n$ 且起始索引对 $2^k$ **对齐**的最大阶 $k$。用于 `buddy_init_memmap` 和 `buddy_free_pages` 的切分。 |
| `list_init_all(int maxord)`                         | 初始化所有空闲链表和计数器。                                 |
| `order_insert_sorted(struct Page *b, int order)`    | 将空闲块 `b` 插入到指定阶 `order` 的链表中，确保链表按物理地址升序排列。 |
| `order_find_block_by_index(size_t idx, int order)`  | 在指定阶的空闲链中，通过页索引精确查找块。用于伙伴合并时的查找。 |
| `order_remove(struct Page *b, int order)`           | 从指定阶的空闲链中移除块 `b`。                               |
| `order_take_lowest(int order)`                      | 取出指定阶空闲链上的**最低物理地址**的空闲块（链头）。       |

## 4. 接口函数（`pmm_manager` 结构体）

Buddy System PMM 通过 `buddy_system_pmm_manager` 结构体实现了标准的物理内存管理接口。

### 4.1. `buddy_init()`

```c
void buddy_init(void);
```

**功能：** 伙伴系统 PMM 的初始化入口。主要工作是调用 `list_init_all` 初始化所有空闲链表头和计数器。

### 4.2. `buddy_init_memmap(struct Page *base, size_t n)`

```c
void buddy_init_memmap(struct Page *base, size_t n);
```

功能： 将一段连续的物理页区间 [base, base + n) 初始化并加入到伙伴系统管理。

实现细节：

1. 将区间内所有页的保留标记清除，并清空属性字段。
2. 使用 `largest_aligned_order` 函数，将该连续区间按**最大对齐**的 $2^k$ 大小切分成多个块。
3. 对每个切分出的块，设置其头页的 `Page.property` 为块大小，设置 `PageProperty` 标志。
4. 调用 `order_insert_sorted` 将块挂入相应阶的空闲链表。
5. 更新 `total_free_pages` 和 `max_order_inited`。

### 4.3. `buddy_alloc_pages(size_t n)`

```c
struct Page *buddy_alloc_pages(size_t n);
```

功能： 从伙伴系统中分配至少 n 个连续的物理页。实际分配 $2^{need}$ 页，其中 $2^{need}≥n$ 且 $\text{need}$ 最小。

实现细节：

1. 计算所需的最小阶 $\text{need} = \lceil \log_2 n \rceil$。
2. 从 $\text{need}$ 阶开始，向上查找第一个非空闲链 $o$。
3. 从阶 $o$ 取出最低地址块 `b`（`order_take_lowest`）。
4. 如果 $o > \text{need}$，则递归地将块 `b` 二等分，直到达到 $\text{need}$ 阶：
   - 将右半块（伙伴块）标记为新的空闲块头，并插入到 $o-1$ 阶空闲链。
   - 将左半块（`b`）继续作为当前块，进入下一轮循环。
5. 返回最终 $\text{need}$ 阶的块 `b`，并清除其空闲块头标记。
6. 更新 `total_free_pages`。

### 4.4. `buddy_free_pages(struct Page *base, size_t n)`

```c
void buddy_free_pages(struct Page *base, size_t n);
```

功能： 释放从 base 开始的 n 个物理页。

实现细节：

1. 同样使用 `largest_aligned_order` 函数，将要释放的 `n` 页区间按**最大对齐**的 $2^k$ 大小切分成多个块。
2. 对每个切分出的 $2^o$ 页块，调用内部函数 `buddy_free_one_block(base, o)` 进行释放和合并。
3. 更新 `total_free_pages`。

**`buddy_free_one_block(struct Page \*base, int order)` 细节：**

1. 将本块标记为 $order$ 阶空闲块头。
2. **合并循环：** 在 `order < MAX_ORDER` 且找到空闲伙伴时循环。
   - 计算伙伴块的索引 `buddy_idx = idx ^ (1U << order)`。
   - 在当前 $order$ 阶空闲链中查找伙伴块 `bud`。
   - 如果找到且 `bud` 确实是 $order$ 阶空闲块，则：
     - 从链中移除 `bud` 并清除其空闲块头标记。
     - 将当前块 `base` 和伙伴块 `bud` 合并，新的块头为两者中地址较低者。
     - 阶数 `order` 递增 1。
     - 更新新块头的属性和标记。
3. 将最终合并后的块（最高阶）插入到对应阶的空闲链中。

### 4.5. `buddy_nr_free_pages()`

```c
size_t buddy_nr_free_pages(void);
```

**功能：** 返回当前系统中的空闲页总数（即 `total_free_pages`）。

### 4.6. `buddy_check()`

```c
static void buddy_check(void);
```

功能： 物理内存分配器的自检函数，用于在测试环境中验证伙伴系统的正确性。

测试内容（buddy_mul_check）：

- **基本检查：** 检查总空闲页数与各阶链表页数之和是否一致，以及空闲块头页的属性和对齐性。
- **分配/释放测试：** 针对非 $2^k$ 页（如 5 页、10 页）的分配，验证其按照 $2^k$ 粒度分配和回收的正确性。
- **边界/模式测试：** 测试最小、最大分配以及顺序分配/逆序释放等模式。
- **伙伴特性验证：** 验证块的拆分、伙伴块的精确回收、以及向上合并的正确性。
- **一致性/压力测试：** 多次循环分配释放后，验证空闲页数和内部数据结构的一致性。
- **平衡检查：** （可选，仅在 `BUDDY_GRADING` 宏启用时）通过 `buddy_repack_heap` 函数将当前空闲堆“抽干”再按地址顺序归还，以验证伙伴系统能够最大限度地合并空闲块，恢复到规范状态。