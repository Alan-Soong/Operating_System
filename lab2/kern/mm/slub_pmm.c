// SLUB (简化版) 小对象分配器 + 内置 buddy（sb_）页级分配 + pmm_manager
// - 页级分配：使用本文件内置的正宗伙伴法 sb_*（不复用外部 buddy_*）
// - 小对象：SLUB 使用旁路元数据（side-car），不修改 struct Page
// - 导出 const struct pmm_manager slub_pmm_manager

#include <pmm.h>
#include <list.h>
#include <string.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>
#include <stdio.h>
#include <assert.h>
// #include <stddef.h> // offsetof

// ===================== Debug 开关 =====================
#define SLUB_DEBUG 0
#if SLUB_DEBUG
#  define dprintf(...) cprintf(__VA_ARGS__)
#else
#  define dprintf(...) do {} while (0)
#endif

static inline void *page2kva_compat(struct Page *pg) {
    return KADDR(page2pa(pg));
}

extern struct Page *pages;
extern size_t npage;

// 与 buddy 样例一致的页下标工具
static inline size_t page_to_index(struct Page *pg) { return (size_t)(pg - pages); }
static inline struct Page *index_to_page(size_t idx) { return &pages[idx]; }

// ===================== 内置 Buddy（仅供本 SLUB 使用） =====================
#define SB_MAX_ORDER 16  // 按需求可调

typedef struct {
    list_entry_t head;
    unsigned int count;
} sb_free_area_t;

static sb_free_area_t sb_free_areas[SB_MAX_ORDER + 1];
static unsigned int sb_total_free_pages = 0;
static int sb_inited = 0;

static inline int sb_is_pow2(size_t x){ return x && !(x & (x - 1)); }
static inline size_t sb_ceil_pow2(size_t x){
    size_t p = 1;
    while (p < x) p <<= 1;
    return p;
}
static inline size_t sb_block_order(size_t npages) {
    size_t o = 0, x = 1;
    while (x < npages) { x <<= 1; o++; }
    return o;
}
static inline size_t sb_align_block_down(size_t idx, size_t order) {
    size_t blk = (size_t)1 << order;
    return idx & ~(blk - 1);
}
static inline size_t sb_buddy_index(size_t idx, size_t order) {
    return idx ^ ((size_t)1 << order);
}

static inline struct Page *le2page_hdr(list_entry_t *le) {
    return (struct Page *)((char*)le - offsetof(struct Page, page_link));
}

static void sb_area_init(void) {
    for (int o = 0; o <= SB_MAX_ORDER; ++o) {
        list_init(&sb_free_areas[o].head);
        sb_free_areas[o].count = 0;
    }
    sb_total_free_pages = 0;
    sb_inited = 1;
}

static inline void sb_add_block(size_t idx, size_t order) {
    struct Page *pg = index_to_page(idx);
    SetPageProperty(pg);
    pg->property = (1u << order); // 以“页数”记录块大小
    list_add(&sb_free_areas[order].head, &(pg->page_link));
    sb_free_areas[order].count++;
    sb_total_free_pages += (1u << order);
}

static inline void sb_del_block(struct Page *pg, size_t order) {
    list_del(&(pg->page_link));
    sb_free_areas[order].count--;
    ClearPageProperty(pg);
    sb_total_free_pages -= (1u << order);
}

// 只清标记，不改变 pages 数组本身
static void sb_sanitize_range(size_t start_idx, size_t n) {
    for (size_t i = 0; i < n; ++i) {
        struct Page *p = index_to_page(start_idx + i);
        ClearPageProperty(p);
        p->property = 0;
        list_init(&p->page_link);
    }
}

static void sb_init(void) {
    if (!sb_inited) sb_area_init();
}

// 把 [base, base+n) 登记为空闲，采用贪心按最大对齐块切分
static void sb_init_memmap(struct Page *base, size_t n) {
    assert(sb_inited);
    size_t idx = page_to_index(base);
    size_t remain = n;

    sb_sanitize_range(idx, n);

    while (remain) {
        size_t order = SB_MAX_ORDER;
        while (order > 0) {
            size_t blk = (size_t)1 << order;
            if ((idx & (blk - 1)) == 0 && remain >= blk) break;
            order--;
        }
        sb_add_block(idx, order);
        idx    += ((size_t)1 << order);
        remain -= ((size_t)1 << order);
    }
}

// 分配：返回 2^k 大小、且 2^k >= n 的连续块（教学实现：向上取整）
// 注意：返回块头页，块大小为 (1<<order)；调用者若需要“恰好 n 页”，请按需自己分片。
// kmalloc(>4KB) / slub_alloc_pages 都按 2^k 使用，free 时按 2^k 归还。
static struct Page *sb_alloc_pages_pow2(size_t n) {
    assert(n > 0);
    size_t need = sb_ceil_pow2(n);
    size_t order = sb_block_order(need);

    int o = (int)order;
    while (o <= SB_MAX_ORDER && list_empty(&sb_free_areas[o].head)) o++;
    if (o > SB_MAX_ORDER) return NULL;

    // 从 o 阶拿块，不断拆分到 order
    list_entry_t *le = list_next(&sb_free_areas[o].head);
    struct Page *pg = le2page_hdr(le);
    sb_del_block(pg, (size_t)o);

    size_t idx = page_to_index(pg);
    while (o > (int)order) {
        o--;
        size_t buddy_idx = idx + ((size_t)1 << o);
        sb_add_block(buddy_idx, (size_t)o);
        // 当前块继续向下 split
    }
    // 标记为“已分配”：不保留 PageProperty；property 清零
    pg->property = 0;
    return pg;
}

// 归还：允许传入任意 n（不必 2^k），按最大对齐块逐段合并回去
static void sb_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    size_t idx = page_to_index(base);
    size_t remain = n;

    while (remain) {
        // 选最大 2^k，且对齐且不超过 remain
        size_t order = 0;
        while (order < SB_MAX_ORDER) {
            size_t next_blk = (size_t)1 << (order + 1);
            if ((idx & (next_blk - 1)) || next_blk > remain) break;
            order++;
        }

        // 尝试向上合并兄弟
        size_t cur_idx = idx;
        size_t cur_order = order;

        while (cur_order < SB_MAX_ORDER) {
            size_t bud_idx = sb_buddy_index(cur_idx, cur_order);
            struct Page *bud = index_to_page(bud_idx);
            if (!PageProperty(bud) || bud->property != ((size_t)1 << cur_order)) break;

            // 从空闲链摘掉兄弟块
            list_del(&(bud->page_link));
            sb_free_areas[cur_order].count--;
            ClearPageProperty(bud);
            sb_total_free_pages -= ((size_t)1 << cur_order);

            // 合并为更高一阶，头为较小索引
            cur_idx = (bud_idx < cur_idx) ? bud_idx : cur_idx;
            cur_order++;
        }
        sb_add_block(cur_idx, cur_order);

        idx    += ((size_t)1 << order);
        remain -= ((size_t)1 << order);
    }
}

static size_t sb_nr_free_pages(void) { return sb_total_free_pages; }

// ===================== SLUB 常量与类型 =====================
#define KMALLOC_MIN_SIZE 8
#define KMALLOC_MAX_SIZE 4096
#define KMALLOC_CLASS_NUM 12     // 8,16,...,4096

typedef struct kmem_cache {
    char name[16];
    unsigned object_size;
    unsigned objects_per_slab;
    list_entry_t partial_slabs;  // 常态：只维护 partial
#if SLUB_DEBUG
    list_entry_t full_slabs;     // 仅调试用
#endif
} kmem_cache_t;

// ——“拓展字段单独结构体”（side-car），不改 struct Page —— //
typedef struct SlubMeta {
    kmem_cache_t *cache;     // 该页若作为 slab，其归属的 cache
    void *freelist;          // slab 内部空闲对象单链（指向对象头）
    uint32_t inuse;          // 已分配对象数（大块时复用存放页数=2^k）
    list_entry_t slab_link;  // 挂接到 cache 链表（partial）
} SlubMeta;

static SlubMeta *g_slub_meta = NULL;     // 指向全局旁路元数据数组（大小 npage）
static size_t g_slub_meta_base_idx = 0;  // 该数组对应的“pages 起始下标”
static kmem_cache_t *kmalloc_caches[KMALLOC_CLASS_NUM] = {0};

// 把 list_entry_t 指回 SlubMeta
static inline SlubMeta *le2slubmeta(list_entry_t *le) {
    return (SlubMeta *)((char *)le - offsetof(SlubMeta, slab_link));
}

// ===================== 通用工具 =====================
static inline int simple_fls(unsigned x) {
    if (!x) return 0;
    int r = 0; while (x) { x >>= 1; r++; } return r;
}

// size 映射到 kmalloc 等级下标
static inline int size_to_index(size_t size) {
    if (size <= KMALLOC_MIN_SIZE) return 0;
    int idx = simple_fls((unsigned)(size - 1)) - 3; // 8->0, 16->1, ...
    if (idx < 0) idx = 0;
    if (idx >= KMALLOC_CLASS_NUM) idx = KMALLOC_CLASS_NUM - 1;
    return idx;
}

// ===================== pmm_manager 接口（页级由 sb_* 提供） =====================
static struct Page *slub_alloc_pages(size_t n) {
    // 教学实现：统一按 2^k 分配，以简化 buddy 逻辑
    return sb_alloc_pages_pow2(n);
}
static void slub_free_pages(struct Page *base, size_t n) {
    // 允许非 2^k；内部会按最大对齐块分段归还并合并
    sb_free_pages(base, n);
}
static size_t slub_nr_free_pages(void) {
    return sb_nr_free_pages();
}

// 通过 page* 拿旁路元数据
static inline SlubMeta *slub_meta_of_page(struct Page *pg) {
    size_t idx = page_to_index(pg);
    assert(g_slub_meta != NULL);
    assert(idx >= g_slub_meta_base_idx);
    assert(idx < g_slub_meta_base_idx + npage);
    return &g_slub_meta[idx - g_slub_meta_base_idx];
}

// obj 指针 -> 对应页
static inline struct Page *obj_to_page(void *obj) {
    return pa2page(PADDR(obj));
}

// ===================== SLUB 内部实现 =====================
static struct Page *kmem_cache_grow(kmem_cache_t *cache) {
    // 向内置 buddy 要 1 页
    struct Page *slab_pg = sb_alloc_pages_pow2(1);
    if (!slab_pg) {
        // cprintf("SLUB: grow fail for %s\n", cache->name);
        return NULL;
    }
    SlubMeta *m = slub_meta_of_page(slab_pg);
    m->cache = cache;
    m->inuse = 0;
    m->freelist = NULL;
    list_init(&m->slab_link);

    // 将页切成对象串 freelist
    void *slab_base = page2kva_compat(slab_pg);
    for (unsigned i = 0; i < cache->objects_per_slab; ++i) {
        void *obj = (char *)slab_base + (size_t)i * cache->object_size;
        *(void **)obj = m->freelist;
        m->freelist = obj;
    }
    // 新页先挂 partial
    list_add(&cache->partial_slabs, &m->slab_link);
    dprintf("SLUB: grow cache=%s, per_slab=%u\n", cache->name, cache->objects_per_slab);
    return slab_pg;
}

static void *kmem_cache_alloc(kmem_cache_t *cache) {
    if (list_empty(&cache->partial_slabs)) {
        if (!kmem_cache_grow(cache)) return NULL;
    }
    // 取一个 partial slab
    list_entry_t *le = list_next(&cache->partial_slabs);
    SlubMeta *m = le2slubmeta(le);

    assert(m->freelist != NULL);
    void *obj = m->freelist;
    m->freelist = *(void **)obj;
    m->inuse++;

    if (m->inuse == cache->objects_per_slab) {
        // 满 -> 从 partial 摘掉（可选：DEBUG 下挂 full）
        list_del(&m->slab_link);
#if SLUB_DEBUG
        list_add(&cache->full_slabs, &m->slab_link);
#endif
    }

    memset(obj, 0, cache->object_size);
    return obj;
}

static void kmem_cache_free(kmem_cache_t *cache_hint, void *obj) {
    if (!obj) return;
    struct Page *pg = obj_to_page(obj);
    SlubMeta *m = slub_meta_of_page(pg);
    kmem_cache_t *cache = cache_hint ? cache_hint : m->cache;
    assert(cache == m->cache);

    // 头插回 slab freelist
    *(void **)obj = m->freelist;
    m->freelist = obj;
    uint32_t prev_inuse = m->inuse;
    m->inuse--;

    if (m->inuse == 0) {
        // 彻底空：若之前不是满，则在 partial 上，需要摘链；若之前是满，则不在任何链
        if (prev_inuse != cache->objects_per_slab) {
            list_del(&m->slab_link);
        }
#if SLUB_DEBUG
        else {
            // 若启用 full 链，这里也需要从 full 摘掉
            list_del(&m->slab_link);
        }
#endif
        m->cache = NULL;
        m->freelist = NULL;
        m->inuse = 0;
        list_init(&m->slab_link);
        sb_free_pages(pg, 1);
    } else if (prev_inuse == cache->objects_per_slab) {
        // 从满 -> partial（例如每 slab >1 个对象时）
#if SLUB_DEBUG
        // 若之前在 full 链，这里先摘掉
        list_del(&m->slab_link);
#endif
        list_add(&cache->partial_slabs, &m->slab_link);
    }
}

// ===================== kmalloc / kfree / SLUB init =====================
static void slub_build_kmalloc_caches(void) {
    static kmem_cache_t caches_storage[KMALLOC_CLASS_NUM];
    for (int i = 0; i < KMALLOC_CLASS_NUM; ++i) {
        size_t sz = (size_t)KMALLOC_MIN_SIZE << i;
        kmem_cache_t *c = &caches_storage[i];
        snprintf(c->name, sizeof(c->name), "kmalloc-%u", (unsigned)sz);
        c->name[sizeof(c->name) - 1] = '\0';
        c->object_size = (unsigned)sz;
        c->objects_per_slab = PGSIZE / (unsigned)sz;
        list_init(&c->partial_slabs);
#if SLUB_DEBUG
        list_init(&c->full_slabs);
#endif
        kmalloc_caches[i] = c;
        dprintf("SLUB: built %s (obj=%u per=%u)\n",
                c->name, c->object_size, c->objects_per_slab);
    }
}

void slub_init(void) {
    // 初始化内置 buddy 框架（不占用物理内存）
    sb_init();
    // cache/sidecar 放到 init_memmap 之后做（此时页图就绪）
}

// 在底层 pages[] / npage 已就绪后调用
void slub_init_memmap(struct Page *base, size_t n) {
    // 1) 计算 sidecar 需要的页
    size_t need_bytes = npage * sizeof(SlubMeta);
    size_t need_pages = (need_bytes + PGSIZE - 1) / PGSIZE;

    // 2) 建立页级空闲结构，跳过前 need_pages 页（用于 sidecar）
    sb_init_memmap(base + need_pages, n - need_pages);

    // 3) sidecar 使用前 need_pages 页，清标记并初始化
    sb_sanitize_range(0, need_pages);
    void *base_kva = page2kva_compat(base);
    memset(base_kva, 0, need_bytes);
    g_slub_meta = (SlubMeta *)base_kva;
    g_slub_meta_base_idx = 0;

    // 4) 建立 kmalloc caches
    slub_build_kmalloc_caches();
}

void *kmalloc(size_t size) {
    if (size == 0) return NULL;

    if (size > KMALLOC_MAX_SIZE) {
        // 大块：回退到内置 buddy；为了简化，我们向上取整到 2^k 页
        size_t np = (size + PGSIZE - 1) / PGSIZE;
        size_t np2 = sb_ceil_pow2(np);
        struct Page *p = sb_alloc_pages_pow2(np2);
        if (p) {
            // 在 sidecar 记录实际归还页数（2^k）
            SlubMeta *m = slub_meta_of_page(p);
            m->cache = NULL;
            m->freelist = NULL;
            m->inuse = (uint32_t)np2; // 存回收用的页数
            return page2kva_compat(p);
        }
        return NULL;
    }
    return kmem_cache_alloc(kmalloc_caches[size_to_index(size)]);
}

void kfree(void *obj) {
    if (!obj) return;
    struct Page *pg = obj_to_page(obj);
    SlubMeta *m = slub_meta_of_page(pg);

    if (m->cache == NULL) {
        // 大块释放：按记录的 2^k 页数归还
        size_t np = m->inuse;
        m->inuse = 0;
        sb_free_pages(pg, np);
        return;
    }
    kmem_cache_free(m->cache, obj);
}

// ===================== 自检（简化：复用你的最小模式 + 少量 sanity） =====================
void slub_check(void) {
    cprintf("\n--- SLUB Allocator Check ---\n");

    // 你给的最简两句（保持风格）
    assert(slub_alloc_pages(1) != NULL);
    cprintf("SLUB: single page allocation OK\n");
    slub_free_pages(slub_alloc_pages(1), 1);
    cprintf("SLUB: single page free OK\n");

    // 再来一个大块（2^12 页 = 4096 页）
    struct Page *big = slub_alloc_pages(4096);
    assert(big != NULL);
    cprintf("SLUB: large page allocation OK\n");
    slub_free_pages(big, 4096);
    cprintf("SLUB: large page free OK\n");

    // 小对象冒烟（几档常用 size，每档分配/释放少量）
    const size_t sizes[] = {8, 16, 64, 256, 1024, 4096};
    for (unsigned si = 0; si < sizeof(sizes)/sizeof(sizes[0]); ++si) {
        void *ps[8]; int m = 0;
        for (int i = 0; i < 6; ++i) {
            void *p = kmalloc(sizes[si]);
            assert(p != NULL);
            ps[m++] = p;
        }
        while (m) kfree(ps[--m]);
    }
    cprintf("SLUB: small-object few-alloc/free OK\n");

    cprintf("--- SLUB Allocator Check Passed ---\n\n");
}

// ===================== 导出 pmm_manager =====================
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};
