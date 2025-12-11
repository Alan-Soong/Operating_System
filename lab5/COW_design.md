# Copy-On-Write (COW) 设计文档

## 一、摘要
本文档描述在教学型 RISC‑V 内核中引入 Copy-On-Write（COW）机制的设计与实现方案。目标是在 `fork()` 或进程克隆时延迟物理页复制，通过写时复制提高内存利用率和性能，同时保证内核稳定性与安全性。

## 二、目标与动机
- 减少内存占用：在 `fork()` 后子进程通常立即调用 `exec()`，复制所有页会浪费；COW 可共享只读页直到写发生。
- 提升性能：避免大量即时页复制，降低 `fork()` 延迟。
- 兼容现有页表/内存管理：尽量小的内核修改，保持与现有 MM 子系统接口兼容。

## 三、术语与假设
- PTE：页表项（含物理页帧、权限及标志）。
- writable 标志：表示页可写。
- COW 标志（new）：标识当前页为写时复制共享页。
- refcount[]：每个物理页帧的引用计数，用于判断是否需要实际复制。
- 假设：内核已有页表、物理页分配/释放、缺页异常（page fault）处理机制。

## 四、高层设计概览
1. 在 `fork()` 时：
   - 复制父进程页表结构时，不把父页设为可写；改为清除 PTE 的 `W`(write) 并设置 `COW` 标志（或使用 PTE 中的只读并在内核维护另一个共享标志）。
   - 增加对应物理页的 `refcount++`。
2. 当任一进程写入该页导致缺页（写保护触发 page fault）时：
   - 内核在缺页处理里识别这是对 COW 页的写。
   - 若 `refcount > 1`：分配新物理页，拷贝原页内容，更新当前进程页表使 PTE 指向新页并设为可写，`refcount` 原页--，新页 `refcount = 1`。
   - 若 `refcount == 1`：可以直接把该 PTE 恢复为可写（清除 COW 标志），不拷贝。
3. 释放页时：
   - 成员进程终止或页表解除映射时做 `refcount--`，当为 0 时释放物理页。

## 五、数据结构与 PTE 扩展
- 物理页引用计数表 `page_refcount[]`：以页为单位的原子计数（位于内核数据段或页管理结构中）。
- PTE 扩展：如果现有 PTE 空位不足，可利用现有的 `W`/`R` 标志配合内核侧元数据。优先方案：在 PTE 中增加 `PTE_COW` 标志（若 PTE 空间允许），否则：在 PTE 中清 `W` 并在内核维护一张二级位图/哈希表记录哪些虚拟页为 COW。

Pseudocode: PTE 字段
- PTE: [ppn | flags]
- flags 包含: V,R,W,X,U,G,A,D,COW

## 六、关键算法（伪代码）

1) fork() 时页面处理

```
for each mapped user page va in parent:
    pte = parent.pagetable.walk(va)
    if pte.valid():
        pte.flags &= ~W            // 清写权限
        pte.flags |= COW          // 标记为 COW
        child.pagetable.map(va, pte.ppn, pte.flags)
        atomic_inc(page_refcount[pte.ppn])
```

2) 写时缺页处理（page fault handler）

```
if fault is write to a mapped page:
    pte = cur.pagetable.walk(fault_va)
    if pte.flags has COW or (not W but exists and marked shared):
        ppn = pte.ppn
        if page_refcount[ppn] > 1:
            new_ppn = alloc_page()
            copy_page(new_ppn, ppn)
            atomic_dec(page_refcount[ppn])
            page_refcount[new_ppn] = 1
            update cur.pagetable: map fault_va -> new_ppn with W and clear COW
        else:
            // refcount == 1，独占页，可以直接设置为可写
            pte.flags |= W
            pte.flags &= ~COW
        flush_tlb_entry(fault_va)
        return handled
    else:
        // 其它写缺页，按原来策略处理（如堆扩展/非法访问）
```

注意：对 `page_refcount` 的操作必须为原子，并在 SMP 环境下使用自旋锁/原子指令保护 PTE 修改和引用计数的一致性。

## 七、同步与并发
- 对于每个物理页帧的 `refcount` 使用原子增减。
- 在执行从共享到独占转换（即拷贝）时，需对该页执行短临界区保护以避免竞态：
  - 使用页级锁（per-page lock）或在修改 PTE 前抓取所在进程页表锁。
  - 步骤：查 `refcount` -> 若 >1，尝试获取页锁 -> 再次确认 `refcount` -> 拷贝 -> 更新 PTE -> 释放锁。
- 必须确保 TLB 在 PTE 修改后被刷新（或使用 TLB shootdown 在多核上保持一致）。

## 八、性能考虑
- 延迟复制可显著降低 `fork()` 的开销，尤其当父/子进程大多调用 `exec()`。
- 需要衡量额外的页表写保护/清写操作引入的 page fault 成本；通常写入热点页会触发拷贝，导致开销分散到首次写时。
- 推荐：在实现中给出开关（CONFIG_COW），便于在教学或调试时启用/禁用。

## 九、安全与正确性
- 确保内核能区分用户内存与内核内存的写保护；绝不能把内核页标记为 COW。
- 严格维护 `refcount` 与 PTE 的一致性，防止 double-free 或内存泄漏。
- 处理异常路径（如分配新页失败）时，要返回错误并保证系统状态一致（如杀死触发异常的进程或发送 SIGKILL）。

## 十、兼容性与接口变化
- 对现有 `fork()`：不改变外部接口，内部实现改为共享页与 COW。
- 需要在内核的页分配/释放模块中加入 `page_refcount` 管理函数：`inc_ref(ppn)`, `dec_ref(ppn)`。
- 在页表管理中加入 `set_cow(va)` / `clear_cow(va)` 辅助函数（或直接在 PTE 操作中处理）。

## 十一、测试方案
1. 单元测试
   - fork 后验证父子进程共享物理页（检查 refcount 增加）。
   - 子进程写某页后，确保发生拷贝且两个进程看到不同物理页。
2. 回归/压力测试
   - 大内存进程 fork 多次并马上 exec，评估内存占用和 fork 延迟。
   - 并发写测试，确保多核环境下不会丢失数据或造成内存泄漏。
3. 故障注入
   - 模拟物理页分配失败，确认异常路径正确处理。

## 十二、潜在限制与替代方案
- 如果内核页表/硬件 PTE 位受限，需用内核侧数据结构（如哈希）记录 COW 状态，增加查找开销。
- 替代：使用内核级的 `fork()` 优化（如写时复制合并策略、hugepage 处理）以减少频繁小页拷贝的开销。

## 十三、与仓库中已有实现的对应
下面把设计与仓库中已有代码对应起来，便于理解与扩展（代码文件以项目相对路径表示）。

- **写时复制（COW）已在项目中部分实现**：主要集中在 [lab5/kern/mm/vmm.c](lab5/kern/mm/vmm.c) 中的 `do_pgfault()`、`dup_mmap()`、`vma`/`mm` 管理函数以及 [lab5/kern/process/proc.c](lab5/kern/process/proc.c) 的 `copy_mm()`/`do_fork()` 调用路径。

- **关键实现点（代码位置与行为）**:
   - `dup_mmap()` (vmm.c)：遍历父进程的 `vma` 列表，为子进程创建对应的 `vma` 并调用 `copy_range(..., share)`。当 `share = 1` 时，页表复制会产生共享映射（父子共享同一物理页），并且没有直接把页设为可写。这个是 COW 的起点（fork 后不立即复制物理页）。
   - `do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)` (vmm.c)：缺页/写保护异常处理。
      - 代码里当页表项存在但写导致异常（`error_code == 1` 且 `*ptep & PTE_W` 不存在）时，调用 `pte2page(*ptep)` 得到对应 `struct Page *`，并通过 `page_ref(page)` 判断引用数：
         - `page_ref(page) > 1`：分配新页 `alloc_page()`、拷贝内容、`page_insert(mm->pgdir, npage, addr, perm)`，然后释放失败的情况处理 —— 这是 COW 的拷贝路径（多引用时复制）。
         - `page_ref(page) == 1`：直接给 PTE 恢复写权限（`*ptep |= PTE_W`）并调用 `tlb_invalidate(mm->pgdir, addr)` —— 快路径，不拷贝。
      - 该实现依赖于 `page_ref()`、`pte2page()`、`page_insert()`、`alloc_page()/free_page()` 等 pmm 接口。
   - `get_pte()` / `pgdir_alloc_page()`：负责获得/分配页表项与新物理页，用于缺页处理中新建映射或映射 PT 本身。

- **pmm/引用计数：**
   - 代码中使用 `page_ref(page)` 查询页引用计数，`alloc_page()`/`free_page()` 分配释放物理页。确认引用计数的原子性和在 SMP 下的一致性对于正确的 COW 行为至关重要（当前实现假定 `page_ref()` 与页管理操作是安全的）。

- **TLB 处理：**
   - `tlb_invalidate(mm->pgdir, addr)` 在将 PTE 改为可写后被调用，用以刷新对应 TLB 条目；在多核系统上还需要做跨 CPU 的 TLB shootdown（代码中已调用局部失效函数，应核实是否做了全局同步）。

- **外部接口/调用链**:
   - `do_fork()` -> `copy_mm()` -> `dup_mmap()`/`copy_range()`（vma/page 映射复制）
   - 运行时触发写时缺页：用户写页 -> 产生 page fault -> 内核调用 `do_pgfault()` -> 如果为 COW 场景则按上文进行复制或恢复写权限。

## 十四、基于现有代码的实现细节与校验建议
下面给出若干具体建议，便于维护/增强 COW：

- 保证 `page_ref()` 的原子性：在 `do_pgfault()` 中依赖 `page_ref(page)` 判定是否要复制，必须确保 `page_ref` 的增减与 `page_insert`/`page_remove` 的顺序语义一致。若在多核环境，请使用原子操作或页级锁（或在页表修改路径使用 mm 锁）。

- 在 `dup_mmap()`/`copy_range()` 中，确保父/子页表的 PTE 在共享时去掉 `PTE_W`（只读）并保证同时 `page_ref++`。目前仓库实现通过 `share=1` 路径实现共享，此处应核实 `copy_range()` 内部确实做了 `ref`++ 与清写权限的操作。

- 异常路径处理：当 `alloc_page()` 失败时应返回明确错误并由上层处理（当前 `do_pgfault()` 已在分配失败时返回 `-E_NO_MEM`）。确保在复制失败情形下不会造成引用计数不一致或泄漏已分配资源。

- 测试：新增或运行以下验证用例：
   - fork 后父子进程共享页（检查 `page_ref` 增加）；
   - 子/父对同一页写入，会触发 `do_pgfault()`，并导致物理页拷贝（检测两进程页物理地址不同且数据一致）；
   - `execve` 路径：fork 后子进程调用 `execve`（常见场景），确保不会不必要复制页面。

## 十五、总结

通过上述设计与现有代码的对应分析，可以有效理解和维护教学型 RISC-V 内核中的 Copy-On-Write 机制，提升内存管理效率与系统性能。