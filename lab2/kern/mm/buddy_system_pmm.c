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

static void buddy_init(void) {
    // 这里只初始化数组；真正的内存区间在 init_memmap 切块挂入
    list_init_all(MAX_ORDER);
    total_free_pages = 0;
    max_order_inited = 0;
}

/* 把 [base, base+n) 这段空闲页切成“最大对齐”的 2^k 块并挂入伙伴系统 */
static void buddy_init_memmap(struct Page *base, size_t n) {
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
static struct Page *buddy_alloc_pages(size_t n) {
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
static void buddy_free_pages(struct Page *base, size_t n) {
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

static size_t buddy_nr_free_pages(void) {
    return total_free_pages;
}

/* 可选的自检（简单版）：统计一致性 + 阶对齐检查 */
static void buddy_check(void) {
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
