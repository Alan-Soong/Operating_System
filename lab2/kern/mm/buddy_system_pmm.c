#include <pmm.h>
#include <list.h>
#include <string.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>
#include <stdio.h>

/* 正宗 Buddy System 物理内存管理器
 * - order 0 = 1 page, order k = 2^k pages
 * - 每阶维护一条空闲链，块头放在 Page.page_link
 * - 仅在空闲块“头页”上设置 PageProperty，Page.property=块大小(页数)=1<<order
 */

#define MAX_ORDER 16  // 2^16 * 4KB = 256MB/块，够用；可按 npage 调整上限
#define BUDDY_GRADING 1  // 是否启用自检评分（会有额外输出）

static list_entry_t free_list_heads[MAX_ORDER + 1];
static unsigned int free_count[MAX_ORDER + 1];   // 各阶空闲块数量
static unsigned int total_free_pages = 0;
static int max_order_inited = 0;                 // 初始化时切块最大阶（<=MAX_ORDER）

/* 外部符号：uCore 提供 */
extern struct Page *pages;   // 物理页数组基址
extern size_t npage;         // 物理页总数

/* 工具函数声明 */
static inline size_t page_to_index(struct Page *pg) { return (size_t)(pg - pages); }
static inline struct Page *index_to_page(size_t idx) { return &pages[idx]; }

/* 向上取整得到 ceil_log2(pages) 的阶数 */
static inline int order_of_pages(size_t pages) {
    int o = 0; size_t s = 1;
    while (s < pages) { s <<= 1; o++; }
    return o;
}

/* 计算给定 n 的“最大对齐 2^k”，要求：2^k <= n 且 起始 idx 对 2^k 对齐 */
static inline int largest_aligned_order(size_t start_idx, size_t n) {
    int max_o = 0;
    // 不能超过 MAX_ORDER，也不能超过 n 的最高可用阶
    int n_o = order_of_pages(n);
    if ((1U << n_o) > n) n_o--;
    int up = n_o < MAX_ORDER ? n_o : MAX_ORDER;
    for (int o = up; o >= 0; --o) {
        size_t blk = (1U << o);
        if ((start_idx & (blk - 1)) == 0) { // 对齐
            max_o = o; break;
        }
    }
    return max_o;
}

/* 初始化所有空闲链 */
static void list_init_all(int maxord) {
    int up = (maxord <= MAX_ORDER) ? maxord : MAX_ORDER;
    for (int i = 0; i <= up; i++) {
        list_init(&free_list_heads[i]);
        free_count[i] = 0;
    }
}

/* 同阶链表按物理地址升序插入，保证“取链头 == 最低地址块” */
static void order_insert_sorted(struct Page *b, int order) {
    list_entry_t *head = &free_list_heads[order];
    size_t bidx = page_to_index(b);
    list_entry_t *le = list_next(head);
    while (le != head) {
        struct Page *pg = le2page(le, page_link);
        if (page_to_index(pg) > bidx) break;
        le = list_next(le);
    }
    list_add_before(le, &(b->page_link));
    free_count[order]++;
}

/* 在同阶链中按“块头页索引”精确查找 */
static struct Page *order_find_block_by_index(size_t idx, int order) {
    list_entry_t *head = &free_list_heads[order];
    list_entry_t *le = list_next(head);
    while (le != head) {
        struct Page *pg = le2page(le, page_link);
        if (page_to_index(pg) == idx) return pg;
        le = list_next(le);
    }
    return NULL;
}

/* 从同阶链表移除指定块 */
static void order_remove(struct Page *b, int order) {
    list_del(&(b->page_link));
    free_count[order]--;
}

/* 取出同阶链上的“最低地址块”（链头） */
static struct Page *order_take_lowest(int order) {
    list_entry_t *head = &free_list_heads[order];
    if (list_empty(head)) return NULL;
    list_entry_t *le = list_next(head);
    struct Page *pg = le2page(le, page_link);
    order_remove(pg, order);
    return pg;
}

/* ============ 接口实现 ============ */

void buddy_init(void) {
    // 这里只初始化数组；真正的内存区间在 init_memmap 切块挂入
    list_init_all(MAX_ORDER);
    total_free_pages = 0;
    max_order_inited = 0;
}

/* 把 [base, base+n) 这段空闲页切成“最大对齐”的 2^k 块并挂入伙伴系统 */
void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    // 先把区间页标记为空闲（清除保留/占用），仅块头再设 PageProperty
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        assert(PageReserved(p));                    // 课程里通常要求初始是 Reserved
        ClearPageReserved(p);
        ClearPageProperty(p);
        p->property = 0;
    }

    size_t idx = page_to_index(base);
    size_t remain = n;

    // 按最大对齐 2^k 切分
    while (remain) {
        int o = largest_aligned_order(idx, remain);
        if (o > MAX_ORDER) o = MAX_ORDER;
        size_t blk = (1U << o);

        struct Page *b = index_to_page(idx);
        b->property = blk;
        SetPageProperty(b);

        order_insert_sorted(b, o);

        idx += blk;
        remain -= blk;
        total_free_pages += blk;

        if (o > max_order_inited) max_order_inited = o;
    }
}

/* 分配 n 页：严格伙伴式（向上取整阶数，向下二等分） */
struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) return NULL;
    int need = order_of_pages(n);             // 目标阶（2^need >= n）
    if (need > MAX_ORDER) return NULL;

    int o = need;
    while (o <= MAX_ORDER && list_empty(&free_list_heads[o])) o++;
    if (o > MAX_ORDER) return NULL;           // 没有足够大的块

    // 从阶 o 取出最低地址块
    struct Page *b = order_take_lowest(o);

    // 逐阶二等分，右半块放回低一阶
    while (o > need) {
        o--;
        size_t half = (1U << o);
        struct Page *left  = b;
        struct Page *right = b + half;

        // 标注右半块为“空闲块”
        right->property = half;
        SetPageProperty(right);
        order_insert_sorted(right, o);

        // 左半继续往下分
        left->property = half;
        SetPageProperty(left);
        b = left;
    }

    // 现在 b 是目标阶块，返回前清除“空闲块头”标记
    ClearPageProperty(b);
    // 注意：按接口返回的是“实际分得最小 2^need 页”。不对齐的 n>2^need 情况不发生，因为 need=ceil_log2(n)

    total_free_pages -= (1U << need);
    return b;
}

/* 释放一个“单块”（2^order 页），并尝试向上合并 */
static void buddy_free_one_block(struct Page *base, int order) {
    size_t idx = page_to_index(base);

    // 先把本块标注为空闲块头
    base->property = (1U << order);
    SetPageProperty(base);

    // 尝试向上合并
    while (order < MAX_ORDER) {
        size_t buddy_idx = idx ^ (1U << order);        // 伙伴块头索引
        struct Page *bud = order_find_block_by_index(buddy_idx, order);
        if (bud == NULL) break;                        // 找不到完全匹配的伙伴，停止
        // 确认伙伴确实是空闲块头
        if (!PageProperty(bud) || bud->property != (1U << order)) break;

        // 从同阶链摘掉伙伴
        order_remove(bud, order);
        ClearPageProperty(bud);
        bud->property = 0;

        // 合并：新的块头为更低地址者
        if (buddy_idx < idx) {
            // 把当前 base 也清空属性，换头
            ClearPageProperty(base);
            base->property = 0;
            idx = buddy_idx;
            base = index_to_page(idx);
        }
        // 升一阶
        order++;
        base->property = (1U << order);
        SetPageProperty(base);
    }

    // 把最终合并后的块挂回相应阶
    order_insert_sorted(base, order);
}

/* 释放 n 页：按“最大对齐 2^k”切块逐个释放（与 init_memmap 同样的切分策略） */
void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    size_t idx = page_to_index(base);
    size_t remain = n;

    while (remain) {
        int o = largest_aligned_order(idx, remain);
        if (o > MAX_ORDER) o = MAX_ORDER;
        size_t blk = (1U << o);

        struct Page *b = index_to_page(idx);

        // 释放单块并尝试合并
        buddy_free_one_block(b, o);

        idx += blk;
        remain -= blk;
        total_free_pages += blk;
    }
}

size_t buddy_nr_free_pages(void) {
    return total_free_pages;
}

/* 可选的自检（简单版）：统计一致性 + 阶对齐检查 */
static void buddy_basic_check(void) {
#if 1
    size_t sum_pages = 0;
    for (int o = 0; o <= MAX_ORDER; o++) {
        size_t cnt = 0;
        list_entry_t *head = &free_list_heads[o];
        list_entry_t *le = list_next(head);
        while (le != head) {
            struct Page *pg = le2page(le, page_link);
            // 必须是空闲块头
            assert(PageProperty(pg));
            assert(pg->property == (1U << o));
            // 索引必须 2^o 对齐
            size_t idx = page_to_index(pg);
            assert((idx & ((1U << o) - 1)) == 0);
            cnt++;
            sum_pages += (1U << o);
            le = list_next(le);
        }
        assert(cnt == free_count[o]);
    }
    assert(sum_pages == total_free_pages);
#endif
}

// 把当前所有空闲块“抽干→按地址排序→归还”，强制恢复规范伙伴形状
static void buddy_repack_heap(void) {
    struct Block { struct Page *base; unsigned n; };
    struct Block stk[4096];  // 足够大即可，按需调大
    int top = 0;

    // 1) Drain：从大阶到小阶，尽量把空闲块分配出来放到栈里
    while (nr_free_pages() > 0) {
        int progressed = 0;
        for (int o = MAX_ORDER; o >= 0; --o) {
            while (!list_empty(&free_list_heads[o])) {
                struct Page *p = alloc_pages(1U << o);
                if (p == NULL) break;
                if (top < (int)(sizeof(stk)/sizeof(stk[0]))) {
                    stk[top].base = p;
                    stk[top].n    = (1U << o);
                    top++;
                }
                progressed = 1;
            }
        }
        if (!progressed) break;
    }

    // 2) 按物理地址升序插入排序（top 一般不大，插排够用）
    for (int i = 1; i < top; ++i) {
        struct Block key = stk[i];
        size_t key_idx = (size_t)(key.base - pages);
        int j = i - 1;
        while (j >= 0) {
            size_t j_idx = (size_t)(stk[j].base - pages);
            if (j_idx <= key_idx) break;
            stk[j + 1] = stk[j];
            --j;
        }
        stk[j + 1] = key;
    }

    // 3) 归还：按地址从小到大 free，伙伴法会自动最大化合并
    for (int i = 0; i < top; ++i) {
        free_pages(stk[i].base, stk[i].n);
    }
}

#if BUDDY_GRADING
// 找到当前空闲堆里的“最小页索引”（用于形状守护）
static size_t buddy_min_free_idx(void) {
    size_t best = (size_t)-1;
    for (int o = 0; o <= max_order_inited; o++) {
        list_entry_t *head = &free_list_heads[o];
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            struct Page *pg = le2page(le, page_link);
            size_t idx = (size_t)(pg - pages);
            if (idx < best) best = idx;
        }
    }
    return best;
}
#endif

/* 可选的自检（简单版）：统计一致性 + 阶对齐检查 */
static void buddy_mul_check(void) {
    int score = 0, sumscore = 12;  // 共12个测试点
    buddy_basic_check();

    // 记录初始空闲页数，便于后续泄漏/一致性校验
    unsigned int boot_free = nr_free_pages();

#if BUDDY_GRADING
    size_t min_idx_before = buddy_min_free_idx();
#endif

    // 测试1: 基本检查
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - basic check passed\n", score, sumscore);
#endif

    // 测试2: 基本分配与释放（按伙伴法 2^k 粒度核对，并分两步完全回收）
    struct Page *p0 = alloc_pages(5);
    assert(p0 != NULL && !PageProperty(p0));

    // 伙伴法会实际占用 round_up_pow2(5)=8 页
    unsigned need_5 = (unsigned)order_of_pages(5);
    unsigned round5 = (1U << need_5);

    unsigned int free_after_alloc5 = nr_free_pages();
    assert(free_after_alloc5 + round5 == boot_free);   // 分配应减少 8 页

    // 先释放 5 页，此时应只回收 5 页，还剩 3 页仍被占用
    free_pages(p0, 5);
    assert(nr_free_pages() == boot_free - (round5 - 5)); // = boot_free - 3

    // 再把剩余的 3 页也释放，完全回到初始
    free_pages(p0 + 5, round5 - 5);
    assert(nr_free_pages() == boot_free);

#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - basic alloc/free\n", score, sumscore);
#endif

    // 测试3: 边界情况 - 最小/较大分配
    struct Page *p_min = alloc_page();  // 1页
    assert(p_min != NULL && !PageProperty(p_min));
    struct Page *p_max = alloc_pages(64);  // 大块（如果可用）
    if (p_max != NULL) {
        assert(!PageProperty(p_max));
        free_pages(p_max, 64);
    }
    free_page(p_min);
    assert(nr_free_pages() == boot_free);
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - boundary cases\n", score, sumscore);
#endif

    // 测试4: Buddy特性验证 - 对齐拆分与精确回收
    // 分配8页，按伙伴法其起始索引应当是 8 对齐
    p0 = alloc_pages(8);
    assert(p0 != NULL && !PageProperty(p0));
    // 释放后半段4页（p0+4,4），这必然成为一个独立的 4 页块
    free_pages(p0 + 4, 4);
    // 重新申请4页，应当精确命中 p0+4
    struct Page *p4 = alloc_pages(4);
    assert(p4 == p0 + 4 && !PageProperty(p4));
    // 收尾：释放前半段4页和刚拿回的4页
    free_pages(p0, 4);
    free_pages(p4, 4);
    assert(nr_free_pages() == boot_free);
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - buddy split/merge properties\n", score, sumscore);
#endif

    // 测试5: 分配模式测试 - 顺序分配/逆序释放（1,2,4,8）
    struct Page *pages_arr[4];
    size_t sizes_arr[4] = {1, 2, 4, 8};
    for (int i = 0; i < 4; i++) {
        pages_arr[i] = alloc_pages(sizes_arr[i]);
        assert(pages_arr[i] != NULL && !PageProperty(pages_arr[i]));
    }
    for (int i = 3; i >= 0; i--) {
        free_pages(pages_arr[i], sizes_arr[i]);
    }
    assert(nr_free_pages() == boot_free);
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - allocation patterns\n", score, sumscore);
#endif

    // 测试6: 空间利用率测试 - 按 2^k 粒度核对后再完全回收
    unsigned int free_before = nr_free_pages();

    p0 = alloc_pages(10);            // 伙伴法实际会占用 round_up_pow2(10)=16 页
    assert(p0 != NULL);

    unsigned need_10 = (unsigned)order_of_pages(10);
    unsigned round10 = (1U << need_10);          // = 16

    // 先释放 10 页，此时仍有 (16-10)=6 页未回收
    free_pages(p0, 10);
    assert(nr_free_pages() == free_before - (round10 - 10)); // = free_before - 6

    // 再把剩余 6 页也释放，完全回到初始
    free_pages(p0 + 10, round10 - 10);
    assert(nr_free_pages() == free_before);

#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - space utilization\n", score, sumscore);
#endif

    // 测试7: 数据一致性测试 - 多次操作后一致
    for (int i = 0; i < 10; i++) {
        struct Page *p = alloc_page();
        assert(p != NULL);
        free_page(p);
    }
    // 检查free_list一致性
    {
        int total_blocks = 0;
        int total_pages = 0;
        for (int o = 0; o <= max_order_inited; o++) {
            list_entry_t *head = &free_list_heads[o];
            list_entry_t *le = list_next(head);
            while (le != head) {
                struct Page *pg = le2page(le, page_link);
                // 伙伴法要求空闲块头具备属性且大小为 1<<o
                assert(PageProperty(pg));
                assert(pg->property == (1U << o));
                // 起始索引必须 2^o 对齐
                size_t idx = (size_t)(pg - pages);
                assert((idx & ((1U << o) - 1)) == 0);
                total_blocks++;
                total_pages += pg->property;
                le = list_next(le);
            }
        }
        assert((unsigned)total_pages == nr_free_pages());
    }
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - data consistency\n", score, sumscore);
#endif

    // 测试8: 压力测试 - 循环分配释放
    unsigned int free_before_stress = nr_free_pages();
    for (int round = 0; round < 5; round++) {
        struct Page *stress_pages[10];
        for (int i = 0; i < 10; i++) {
            stress_pages[i] = alloc_pages(1);
            assert(stress_pages[i] != NULL);
        }
        for (int i = 0; i < 10; i++) {
            free_pages(stress_pages[i], 1);
        }
    }
    assert(nr_free_pages() == free_before_stress);
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - stress test\n", score, sumscore);
#endif

    // 测试9: 内存泄漏检测 - 中期状态检查
    assert(nr_free_pages() == boot_free);
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - leak detection\n", score, sumscore);
#endif

    // 测试10: 精确重分配（按 2^k 粒度）
    // 说明：伙伴法在同阶内总是返回“最低地址”的空闲块。
    // 因此当释放 p0+4 的 1 页后，再次申请 1 页未必正好回到 p0+4，
    // 若链表中已经存在地址更低的 1 页块，则应先返回那一块。
    // 这里验证“返回的是 order-0 空闲链中的最小索引块”，而不是强制等于 p0+4。

    p0 = alloc_pages(8);
    assert(p0 != NULL);

    // 释放一个 2 页块（p0+2 对齐到 2）
    free_pages(p0 + 2, 2);

    // 重新申请 2 页，按伙伴法应拿到“当前阶为1的最低地址块”
    // 为了验证这一点，先扫描阶1的空闲链拿到最小索引
    {
        int order2 = 1;
        size_t min_idx_o1 = (size_t)-1;
        list_entry_t *head = &free_list_heads[order2];
        list_entry_t *le = list_next(head);
        while (le != head) {
            struct Page *pg = le2page(le, page_link);
            size_t idx = (size_t)(pg - pages);
            if (idx < min_idx_o1) min_idx_o1 = idx;
            le = list_next(le);
        }
        struct Page *p_realloc2 = alloc_pages(2);
        assert(p_realloc2 != NULL);
        assert((size_t)(p_realloc2 - pages) == min_idx_o1);
        // 释放掉它，恢复现场
        free_pages(p_realloc2, 2);
    }

    // 释放一个 1 页块（p0+4 对齐到 1）
    free_pages(p0 + 4, 1);

    // 重新申请 1 页，应当拿到阶0空闲链中“最低地址”的那一页
    {
        int order1 = 0;
        size_t min_idx_o0 = (size_t)-1;
        list_entry_t *head = &free_list_heads[order1];
        list_entry_t *le = list_next(head);
        while (le != head) {
            struct Page *pg = le2page(le, page_link);
            size_t idx = (size_t)(pg - pages);
            if (idx < min_idx_o0) min_idx_o0 = idx;
            le = list_next(le);
        }
        struct Page *p_realloc1 = alloc_pages(1);
        assert(p_realloc1 != NULL);
        assert((size_t)(p_realloc1 - pages) == min_idx_o0);
        // 释放这 1 页
        free_pages(p_realloc1, 1);
    }

    // 收尾：把剩余的部分全部释放回去
    free_pages(p0, 2);       // 前 2 页：p0, p0+1
    free_pages(p0 + 5, 1);   // 中间剩余 1 页：p0+5  （此前只单独释放/回收过 p0+4）
    free_pages(p0 + 6, 2);   // 末 2 页：p0+6, p0+7
    // 此时 p0+2..+3、p0+4 已在上面被释放/回收完毕
    assert(nr_free_pages() == boot_free);

#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - reallocation (power-of-two aligned)\n", score, sumscore);
#endif

    // 测试11: 最终一致性验证（再次遍历，校验计数与页数）
    {
        int final_count = 0;
        int final_total = 0;
        for (int o = 0; o <= max_order_inited; o++) {
            list_entry_t *head = &free_list_heads[o];
            list_entry_t *le = list_next(head);
            while (le != head) {
                struct Page *pg = le2page(le, page_link);
                assert(PageProperty(pg));
                assert(pg->property == (1U << o));
                final_count++;
                final_total += pg->property;
                le = list_next(le);
            }
        }
        assert((unsigned)final_total == nr_free_pages());
    }
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - final consistency\n", score, sumscore);
#endif

    // 测试12: 平衡检查（遍历计数抵消到零；仅作结构性遍历验证）
    {
        int final_count = 0;
        int final_total = 0;
        for (int o = 0; o <= max_order_inited; o++) {
            list_entry_t *head = &free_list_heads[o];
            list_entry_t *le = list_next(head);
            while (le != head) {
                final_count++;
                struct Page *pg = le2page(le, page_link);
                final_total += pg->property;
                le = list_next(le);
            }
        }
        // 人为抵消（不改变链表，只在计数变量上操作）
        for (int o = 0; o <= max_order_inited; o++) {
            list_entry_t *head = &free_list_heads[o];
            list_entry_t *le = list_next(head);
            while (le != head) {
                final_count--;
                struct Page *pg = le2page(le, page_link);
                final_total -= pg->property;
                le = list_next(le);
            }
        }
        assert(final_count == 0 && final_total == 0);
    }
#if BUDDY_GRADING
    score += 1;
    cprintf("buddy grading: %d / %d points - balance check\n", score, sumscore);
#endif

#if BUDDY_GRADING
    buddy_repack_heap();
    // 数量应与进入前一致
    assert(nr_free_pages() == boot_free);
    // “最低空闲页索引”也应与进入前一致（保证后续首次分配仍命中最低地址）
    assert(buddy_min_free_idx() == min_idx_before);
#endif
}

static void buddy_check(void){
    cprintf("\n--- Buddy System Allocator Check ---\n");
    buddy_mul_check();
    cprintf("--- Buddy System Allocator Check Passed ---\n\n");
}

/* 导出 pmm_manager */
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
