// kern/mm/slub_pmm.c

#include <pmm.h>
#include <slub_pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <error.h>
#include <assert.h>
#include <riscv.h> // 确保包含了这个核心头文件

// ==================================================================================
// ==================== 辅助函数与宏定义 (为适配 ucore 环境新增) ====================
// ==================================================================================

// --- 1. 手动实现 fls 函数 ---
// 查找一个整数中最高有效位(Most Significant Bit)的位置
static inline int simple_fls(unsigned int x) {
    if (x == 0) return 0;
    int position = 0;
    // 使用 32 位无符号整数防止位移问题
    uint32_t temp = x;
    while (temp > 0) {
        temp >>= 1;
        position++;
    }
    return position;
}

// --- 2. 实现 KADDR 和 page2kva 宏 ---
// 将物理地址转换为内核虚拟地址
#define KADDR(pa) ((void *)((uintptr_t)(pa) + va_pa_offset))

// 将 struct Page* 转换为内核虚拟地址
#define page2kva(page) (KADDR(page2pa(page)))

// --- 3. 重新实现正确的中断控制宏 ---
// 这些宏直接操作 sstatus 寄存器，不依赖其他函数

// 保存当前中断状态到 flag 变量，然后屏蔽中断
#define local_intr_save(flag) do { \
    asm volatile("csrr %0, sstatus" : "=r"(flag)); \
    asm volatile("csrc sstatus, %0" : : "r"(SSTATUS_SIE)); \
} while (0)

// 根据 flag 变量恢复之前的中断状态
#define local_intr_restore(flag) do { \
    asm volatile("csrw sstatus, %0" : : "r"(flag)); \
} while (0)


// ==================================================================================
// =============================== SLUB 核心代码开始 ===============================
// ==================================================================================

// 缓存描述符结构体 (每种大小的对象一个)
struct kmem_cache {
    char name[16];
    unsigned int object_size;
    unsigned int objects_per_slab;
    list_entry_t partial_slabs;
    list_entry_t full_slabs;
};

#define KMALLOC_MIN_SIZE 8
#define KMALLOC_MAX_SIZE 4096

static kmem_cache_t *kmalloc_caches[12];

static inline int size_to_index(size_t size) {
    if (size <= 8) return 0;
    // 使用我们自己实现的 simple_fls
    return simple_fls(size - 1) - 3;
}

static inline struct Page *obj_to_page(void *obj) {
    return pa2page(PADDR(obj));
}

static struct Page *
kmem_cache_grow(kmem_cache_t *cache) {
    struct Page *slab_page = alloc_page();
    if (slab_page == NULL) {
        cprintf("kmem_cache_grow: failed to allocate page for cache %s\n", cache->name);
        return NULL;
    }

    slab_page->cache = cache;
    slab_page->inuse = 0;
    slab_page->freelist = NULL;

    void *slab_addr = page2kva(slab_page);
    for (int i = 0; i < cache->objects_per_slab; ++i) {
        void *obj = (char*)slab_addr + i * cache->object_size;
        *(void**)obj = slab_page->freelist;
        slab_page->freelist = obj;
    }
    return slab_page;
}

kmem_cache_t *
kmem_cache_create(const char *name, size_t size, size_t align) {
    kmem_cache_t *cache = kmalloc(sizeof(kmem_cache_t));
    if (cache == NULL) return NULL;

    strncpy(cache->name, name, sizeof(cache->name) - 1);
    cache->name[sizeof(cache->name) - 1] = '\0';
    cache->object_size = size;
    cache->objects_per_slab = PGSIZE / size;
    list_init(&(cache->partial_slabs));
    list_init(&(cache->full_slabs));

    cprintf("SLUB: created cache '%s' with object size %u, %u objects per slab.\n",
            cache->name, cache->object_size, cache->objects_per_slab);
    return cache;
}

void *
kmem_cache_alloc(kmem_cache_t *cache) {
    void *obj = NULL;
    struct Page *slab_page = NULL;
    uintptr_t intr_flag; // 用于保存 sstatus 寄存器的值

    local_intr_save(intr_flag);
    {
    retry:
        if (!list_empty(&(cache->partial_slabs))) {
            slab_page = le2page(list_next(&(cache->partial_slabs)), slab_link);
        } else {
            local_intr_restore(intr_flag);
            slab_page = kmem_cache_grow(cache);
            if (slab_page == NULL) return NULL;
            local_intr_save(intr_flag);
            list_add(&(cache->partial_slabs), &(slab_page->slab_link));
            goto retry;
        }

        if (slab_page->freelist != NULL) {
            obj = slab_page->freelist;
            slab_page->freelist = *(void**)obj;
            slab_page->inuse++;

            if (slab_page->inuse == cache->objects_per_slab) {
                list_del(&(slab_page->slab_link));
                list_add(&(cache->full_slabs), &(slab_page->slab_link));
            }
        } else {
            panic("SLUB: slab on partial list has no free objects!");
        }
    }
    local_intr_restore(intr_flag);
    
    if (obj != NULL) {
        memset(obj, 0, cache->object_size);
    }
    return obj;
}

void
kmem_cache_free(kmem_cache_t *cache, void *obj) {
    if (obj == NULL) return;

    struct Page *slab_page = obj_to_page(obj);
    uintptr_t intr_flag;

    if (cache == NULL) {
        cache = slab_page->cache;
    }
    assert(cache == slab_page->cache);

    local_intr_save(intr_flag);
    {
        *(void**)obj = slab_page->freelist;
        slab_page->freelist = obj;
        slab_page->inuse--;

        if (slab_page->inuse == cache->objects_per_slab - 1) {
            list_del(&(slab_page->slab_link));
            list_add(&(cache->partial_slabs), &(slab_page->slab_link));
        } else if (slab_page->inuse == 0) {
            list_del(&(slab_page->slab_link));
            local_intr_restore(intr_flag);
            free_page(slab_page);
            return;
        }
    }
    local_intr_restore(intr_flag);
}

void
slub_init(void) {
    cprintf("slub_init: initializing kmalloc caches...\n");
    static kmem_cache_t caches_storage[12];
    for (int i = 0; i < 12; i++) {
        size_t size = KMALLOC_MIN_SIZE << i;
        char name[16];
        snprintf(name, 16, "kmalloc-%d", size);
        
        kmem_cache_t *cache = &caches_storage[i];
        strncpy(cache->name, name, sizeof(cache->name) - 1);
        cache->name[sizeof(cache->name) - 1] = '\0';
        cache->object_size = size;
        cache->objects_per_slab = PGSIZE / size;
        list_init(&(cache->partial_slabs));
        list_init(&(cache->full_slabs));
        
        kmalloc_caches[i] = cache;
        cprintf("  - created cache '%s'\n", cache->name);
    }
}

void *
kmalloc(size_t size) {
    if (kmalloc_caches[0] == NULL) {
        cprintf("Warning: kmalloc called before slub_init. Falling back to alloc_pages.\n");
        int num_pages = (size + PGSIZE - 1) / PGSIZE;
        struct Page *p = alloc_pages(num_pages);
        if (p == NULL) return NULL;
        return page2kva(p);
    }
    
    if (size == 0) return NULL;

    if (size > KMALLOC_MAX_SIZE) {
        panic("kmalloc does not support size > 4096 in this simplified version");
        return NULL;
    }
    int index = size_to_index(size);
    return kmem_cache_alloc(kmalloc_caches[index]);
}

void
kfree(void *obj) {
    if (obj == NULL) return;

    struct Page *slab_page = obj_to_page(obj);
    
    if (slab_page->cache == NULL) {
        cprintf("Warning: kfree called on non-slub page. Using free_pages.\n");
        free_page(slab_page);
        return;
    }

    kmem_cache_free(slab_page->cache, obj);
}

void
slub_check(void) {
    cprintf("\n--- Running SLUB Allocator Check ---\n");

    cprintf("1. Basic allocation and free test...\n");
    void *p1 = kmalloc(30);
    assert(p1 != NULL);
    struct Page *page1 = obj_to_page(p1);
    assert(page1->cache == kmalloc_caches[size_to_index(30)]);
    cprintf("   - kmalloc(30) allocated from '%s'. OK.\n", page1->cache->name);
    kfree(p1);
    cprintf("   - kfree(p1) OK.\n");

    cprintf("2. Slab state transition test (using kmalloc-128)...\n");
    kmem_cache_t *cache128 = kmalloc_caches[size_to_index(128)];
    int count = cache128->objects_per_slab;
    void **arr = kmalloc(sizeof(void*) * count);
    assert(arr != NULL);

    cprintf("   - Allocating %d objects to fill a slab...\n", count);
    for (int i = 0; i < count; i++) {
        arr[i] = kmem_cache_alloc(cache128);
        assert(arr[i] != NULL);
    }
    assert(list_empty(&(cache128->partial_slabs)));
    assert(!list_empty(&(cache128->full_slabs)));
    cprintf("   - Slab moved to 'full' list. OK.\n");

    cprintf("   - Freeing one object...\n");
    kfree(arr[count-1]);
    assert(!list_empty(&(cache128->partial_slabs)));
    assert(list_empty(&(cache128->full_slabs)));
    cprintf("   - Slab moved back to 'partial' list. OK.\n");

    cprintf("   - Freeing all remaining objects...\n");
    for (int i = 0; i < count - 1; i++) {
        kfree(arr[i]);
    }
    assert(list_empty(&(cache128->partial_slabs)));
    cprintf("   - Slab was freed back to page manager. OK.\n");
    kfree(arr);

    cprintf("3. Multi-cache test...\n");
    void *p_small = kmalloc(8);
    void *p_large = kmalloc(1000);
    assert(obj_to_page(p_small)->cache == kmalloc_caches[0]);
    assert(obj_to_page(p_large)->cache == kmalloc_caches[size_to_index(1000)]);
    cprintf("   - kmalloc(8) and kmalloc(1000) allocated from correct caches. OK.\n");
    kfree(p_small);
    kfree(p_large);
    cprintf("   - Both objects freed. OK.\n");

    cprintf("--- SLUB Allocator Check Passed ---\n\n");
}