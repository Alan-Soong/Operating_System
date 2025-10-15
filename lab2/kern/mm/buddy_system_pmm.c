#include <pmm.h>
#include <list.h>
#include <string.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>
#include <stdio.h>

/* Buddy system physical memory manager
 * - order 0 = 1 page, order k = 2^k pages
 * - maintain free lists per order, store free block head in Page.page_link
 * - use Page.property to hold block size (in pages) for free block heads
 */

#define MAX_ORDER 16

static list_entry_t free_list_heads[MAX_ORDER + 1];
static unsigned int free_count[MAX_ORDER + 1];
static unsigned int total_free_pages = 0;
static int max_order_inited = 0;

#if 1
/* forward declarations used by debug helpers */
static inline size_t page_to_index(struct Page *pg);
#endif

/* Debug switch: set to 1 to enable debug prints (uses cprintf) */
#define BUDDY_DEBUG 0

#if BUDDY_DEBUG
static void dump_free_state(const char *msg) {
    cprintf("[buddy debug] %s\n", msg);
    cprintf("  max_order_inited=%d total_free_pages=%u\n", max_order_inited, total_free_pages);
    for (int o = 0; o <= max_order_inited; o++) {
        cprintf("  order %d: free_count=%u list:", o, free_count[o]);
        list_entry_t *le = &free_list_heads[o];
        for (le = list_next(le); le != &free_list_heads[o]; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            cprintf(" [idx=%lu,prop=%u]", page_to_index(p), p->property);
        }
        cprintf("\n");
    }
}
#else
#define dump_free_state(msg) do {} while(0)
#endif

static inline size_t pages_round_up_to_pow2(size_t pages) {
    size_t p = 1;
    while (p < pages) p <<= 1;
    return p;
}

static inline int order_of_pages(size_t pages) {
    int order = 0;
    size_t p = 1;
    while (p < pages) { p <<= 1; order++; }
    return order;
}

static inline size_t page_to_index(struct Page *pg) { return pg - pages; }
static inline struct Page *index_to_page(size_t idx) { return &pages[idx]; }

static void list_init_all(int maxord) {
    for (int i = 0; i <= maxord; i++) {
        list_init(&free_list_heads[i]);
        free_count[i] = 0;
    }
}

static void recompute_total_free_pages(void) {
    unsigned int total = 0;
    /* recompute free_count as number of blocks in each order, and total_free_pages in pages */
    for (int o = 0; o <= max_order_inited; o++) {
        unsigned int cnt = 0;
        list_entry_t *le = &free_list_heads[o];
        for (le = list_next(le); le != &free_list_heads[o]; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            cnt++;
            total += p->property; /* property stores pages in this free block */
        }
        free_count[o] = cnt;
    }
    total_free_pages = total;
}

static inline size_t buddy_idx(size_t idx, int order) {
    return idx ^ (1UL << order);
}

static void buddy_init(void) {
    /* empty: real init occurs in init_memmap */
    max_order_inited = 0;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    /* initialize pages in region */
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }

    /* decide max order for this manager based on total npage and region size */
    int region_max = 0; size_t t = 1;
    while ((t << 1) <= n && region_max < MAX_ORDER) { t <<= 1; region_max++; }
    int global_max = 0; t = 1;
    while ((t << 1) <= npage && global_max < MAX_ORDER) { t <<= 1; global_max++; }
    max_order_inited = region_max < global_max ? region_max : global_max;
    if (max_order_inited > MAX_ORDER) max_order_inited = MAX_ORDER;

    list_init_all(max_order_inited);

    /* partition region into largest aligned power-of-two blocks */
    size_t start = page_to_index(base);
    size_t end = start + n;
    size_t idx = start;
    while (idx < end) {
        int ord;
        for (ord = max_order_inited; ord >= 0; ord--) {
            size_t block = 1UL << ord;
            if ((idx % block) == 0 && idx + block <= end) break;
        }
        if (ord < 0) ord = 0;
        struct Page *hp = index_to_page(idx);
        hp->property = 1UL << ord;
        SetPageProperty(hp);
        list_init(&hp->page_link);
        list_add(&free_list_heads[ord], &hp->page_link);
        free_count[ord] += 1;
        idx += (1UL << ord);
    }

    recompute_total_free_pages();
}

static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > total_free_pages) return NULL;
    struct Page *page = NULL;
    list_entry_t *found_le = NULL;
    int found_ord = -1;
    for (int o = 0; o <= max_order_inited; o++) {
        list_entry_t *le = &free_list_heads[o];
        while ((le = list_next(le)) != &free_list_heads[o]) {
            struct Page *p = le2page(le, page_link);
            if (p->property >= n) {
                page = p;
                found_le = le;
                found_ord = o;
                goto found;
            }
        }
    }
    if (page == NULL) {
        dump_free_state("alloc_pages: no suitable block");
        return NULL;
    }
found:
    list_del(found_le);
    free_count[found_ord]--;
    if (page->property > n) {
        struct Page *p = page + n;
        p->property = page->property - n;
        SetPageProperty(p);
        list_init(&p->page_link);
        int p_ord = order_of_pages(p->property);
        if (p_ord > max_order_inited) p_ord = max_order_inited;
        list_add(&free_list_heads[p_ord], &p->page_link);
        free_count[p_ord]++;
    }
    page->property = n;
    ClearPageProperty(page);
    total_free_pages -= n;
    recompute_total_free_pages();
    dump_free_state("alloc_pages: allocated block");
    return page;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    base->property = n;
    SetPageProperty(base);
    list_init(&base->page_link);
    int ord = order_of_pages(n);
    if (ord > max_order_inited) ord = max_order_inited;
    list_add(&free_list_heads[ord], &base->page_link);
    free_count[ord]++;
    total_free_pages += n;
}

static size_t buddy_nr_free_pages(void) {
    return total_free_pages;
}

/* adapted checks */
static void buddy_basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t store_heads[MAX_ORDER + 1];
    unsigned int store_counts[MAX_ORDER + 1];
    for (int i = 0; i <= max_order_inited; i++) { store_heads[i] = free_list_heads[i]; store_counts[i] = free_count[i]; list_init(&free_list_heads[i]); free_count[i] = 0; }
    unsigned int store_total = total_free_pages;
    total_free_pages = 0;

    assert(alloc_page() == NULL);

    free_page(p0); free_page(p1); free_page(p2);
    assert(total_free_pages == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list_heads[0]));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(total_free_pages == 0);
    for (int i = 0; i <= max_order_inited; i++) { free_list_heads[i] = store_heads[i]; free_count[i] = store_counts[i]; }
    total_free_pages = store_total;

    free_page(p); free_page(p1); free_page(p2);
}

static void buddy_check(void) {
    buddy_basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t store_heads[MAX_ORDER + 1];
    unsigned int store_counts[MAX_ORDER + 1];
    for (int i = 0; i <= max_order_inited; i++) { store_heads[i] = free_list_heads[i]; store_counts[i] = free_count[i]; list_init(&free_list_heads[i]); free_count[i] = 0; }
    unsigned int store_total = total_free_pages;
    total_free_pages = 0;

    dump_free_state("before free_pages(p0+1,2)");
    free_pages(p0 + 1, 2);
    dump_free_state("after free_pages(p0+1,2)");
    dump_free_state("before free_pages(p0+4,1)");
    free_pages(p0 + 4, 1);
    dump_free_state("after free_pages(p0+4,1)");
    assert(alloc_pages(4) == NULL);
    dump_free_state("after attempted alloc_pages(4)");
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
    assert((p1 = alloc_pages(1)) != NULL);
    assert(alloc_pages(2) != NULL);
    assert(p0 + 4 == p1);

    p2 = p0 + 1;
    free_pages(p0, 5);
    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(total_free_pages == 0);
    total_free_pages = store_total;

    for (int i = 0; i <= max_order_inited; i++) { free_list_heads[i] = store_heads[i]; free_count[i] = store_counts[i]; }

    int count = 0; int total = 0;
    for (int i = 0; i <= max_order_inited; i++) {
        list_entry_t *le = &free_list_heads[i];
        for (le = list_next(le); le != &free_list_heads[i]; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            count++; total += p->property;
        }
    }
    assert(total == nr_free_pages());

    for (int i = 0; i <= max_order_inited; i++) {
        list_entry_t *le = &free_list_heads[i];
        for (le = list_next(le); le != &free_list_heads[i]; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            count--; total -= p->property;
        }
    }
    assert(count == 0);
    assert(total == 0);
}

const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

