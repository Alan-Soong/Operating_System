#  SLUB 分配器设计文档

## 1. 概述与目标

本文档旨在阐述一个为 ucore 教学操作系统设计的、简化版 SLUB 内存分配器的核心思想、数据结构与算法实现。

**目标**: 

在 ucore 已有的页级物理内存管理器（PMM）之上，构建一个高效的、用于分配**小于一页的、固定大小内存对象**的上层分配器。该分配器借鉴了 Linux 内核 SLUB 分配器的核心思想，并针对教学环境进行了大幅简化。

## 2. 核心设计思想

本次实现的核心是**两层架构**和**专用缓存**的思想。

1.  **两层架构**:
    * **后端 (Backend)**: 底层是 ucore 的页级物理内存管理器 (`pmm_manager`，例如 Best-Fit 分配器)。它负责提供以"页"为单位的大块内存。
    * **前端 (Frontend)**: SLUB 分配器作为前端，向后端申请整页内存（称为 **Slab**），然后将这些 Slab "雕刻"成一堆固定大小的小对象（**Object**），并高效地管理这些小对象。

2.  **专用缓存 (`kmem_cache`)**:
    * 针对**每一种大小**的对象（例如 `kmalloc-32`, `kmalloc-64`），我们都创建一个专门的"缓存管理器"（`struct kmem_cache`）。这个管理器只负责这一种大小对象的分配和释放，实现了专事专办，提高了效率。

3.  **Slab 状态管理**:
    * 每个 `kmem_cache` 通过两个链表来管理其拥有的所有 Slabs：
      * `partial_slabs` (部分空闲链表): 存放尚有空闲对象的 Slab。**这是分配新对象的首选来源**。
      * `full_slabs` (全满链表): 存放所有对象都已被分配出去的 Slab。
    * **简化策略**：当一个 Slab 变为空闲时（`inuse == 0`），我们不为它设置单独的 `empty_slabs` 链表进行缓存，而是**立即将其归还**给底层的页级物理内存管理器，以简化实现。

4.  **高效的空闲链表 (Freelist)**:
    * 为了最大限度地减少元数据开销，我们借鉴了 SLUB 的精髓：利用**空闲对象自身的内存空间**来构建一个单向链表。每个空闲对象的开头几个字节被用作指针，指向下一个空闲对象。

5.  **同步机制**:
    * 考虑到 ucore 是一个教学内核，且为了避免引入复杂的锁机制，我们采用**屏蔽/恢复中断** (`local_intr_save`/`restore`) 的方式作为同步原语。这可以有效防止在操作 `kmem_cache` 的全局链表时，因中断发生而导致的数据竞争问题。

## 3. 数据结构

#### 3.1. `struct Page` 扩展

为了将 Slab 的元数据与物理页帧本身绑定，我们对 `struct Page` 进行了外部扩展。当一个物理页被 SLUB 用作 Slab 时，以下字段将被启用：

```c
// ——“拓展字段单独结构体”（side-car），不改 struct Page —— //
typedef struct SlubMeta {
    kmem_cache_t *cache;     // 该页若作为 slab，其归属的 cache
    void *freelist;          // slab 内部空闲对象单链（指向对象头）
    uint32_t inuse;          // 已分配对象数（大块时复用存放页数=2^k）
    list_entry_t slab_link;  // 挂接到 cache 链表（partial）
} SlubMeta;
```

#### 3.2. `struct kmem_cache`

这是 SLUB 分配器的核心控制器，每种大小的对象都对应一个该结构体实例。

```c
typedef struct kmem_cache {
    char name[16];
    unsigned object_size;
    unsigned objects_per_slab;
    list_entry_t partial_slabs;  // 常态：只维护 partial
#if SLUB_DEBUG
    list_entry_t full_slabs;     // 仅调试用
#endif
} kmem_cache_t;

```

#### 3.3. `通用 kmalloc 缓存` 

为了提供一个通用的 `kmalloc` 接口，我们在 `slub_init` 中预先创建了一系列大小按2的幂递增的缓存。

```c
#define KMALLOC_CLASS_NUM 12     // 8,16,...,4096
static kmem_cache_t *kmalloc_caches[KMALLOC_CLASS_NUM] = {0};
```

## 4. 算法与 API 实现

### 4.1. `kmem_cache_alloc`（对象分配）

1. **屏蔽中断**，以保证操作的原子性。  
2. **查找 Slab**：优先从当前缓存的 `partial_slabs` 链表中获取第一个 Slab。  
3. **创建 Slab（如果需要）**：  
   - 若 `partial_slabs` 为空，则临时恢复中断。  
   - 调用底层的 `alloc_page()` 申请一个新的物理页。  
   - 调用 `kmem_cache_grow()` 辅助函数，将该页初始化为一个 Slab（即“雕刻”对象并构建内部 `freelist`）。  
   - 再次屏蔽中断，将新 Slab 加入 `partial_slabs` 链表，并重新开始分配流程。  
4. **分配对象**：  
   - 从选定 Slab 的 `freelist` 中弹出一个对象。  
   - 更新 `freelist` 指针，并使 Slab 的 `inuse` 计数加一。  
   - 若分配后该 Slab 已满（`inuse == objects_per_slab`），则将其从 `partial_slabs` 移动到 `full_slabs` 链表。  
5. **恢复中断**，返回对象指针。

---

### 4.2. `kmem_cache_free`（对象释放）

1. **屏蔽中断**。  
2. **定位 Slab**：  
   - 根据要释放的对象指针，通过 `obj_to_page` 宏找到它所属的 `struct Page`，进而找到对应的 Slab 和其所属的 `kmem_cache`。  
3. **归还对象**：  
   - 将对象头插法加入到 Slab 的 `freelist` 中，并使 `inuse` 计数减一。  
4. **更新 Slab 状态**：  
   - 若 Slab 之前是满的（`inuse` 从 `objects_per_slab` 变为 `objects_per_slab - 1`），则将其从 `full_slabs` 移回到 `partial_slabs` 链表。  
   - 若 Slab 已完全空闲（`inuse == 0`），则将其从 `partial_slabs` 移除，恢复中断后调用 `free_page()` 将其彻底归还给底层物理内存管理器。  
   - 若 Slab 未被释放完，则直接恢复中断。  

---

### 4.3. `kmalloc` / `kfree`（通用接口）

- **`kmalloc(size)`**：  
  - 根据请求的 `size`，通过 `size_to_index` 辅助函数快速定位到最合适的 `kmalloc_caches` 中的一个，然后调用 `kmem_cache_alloc()`。

- **`kfree(obj)`**：  
  - 通过 `obj_to_page(obj)->cache` 反向查找到对象所属的 `kmem_cache`，然后调用 `kmem_cache_free()`。

---

## 5. 测试策略

通过在 `pmm_init` 中调用 `slub_check()` 函数进行自检，覆盖以下关键场景：

- **基本功能**：验证单个 `kmalloc` 与 `kfree` 操作的正确性。  

- **Slab 状态转换**： 

  反复分配直到填满一个 Slab，再逐步释放，验证 Slab 是否能在 `partial` 和 `full` 链表之间正确迁移，并在空时被回收。  

- **多缓存隔离**： 

  同时对不同大小的 `kmalloc` 缓存进行操作，验证它们之间不会相互干扰。
