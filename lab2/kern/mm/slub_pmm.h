// kern/mm/slub_pmm.h

#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <list.h>

// 向前声明，隐藏实现细节
typedef struct kmem_cache kmem_cache_t;

// SLUB 系统初始化函数
void slub_init(void);

// 核心 API
kmem_cache_t *kmem_cache_create(const char *name, size_t size, size_t align);
void kmem_cache_destroy(kmem_cache_t *cache);
void *kmem_cache_alloc(kmem_cache_t *cache);
void kmem_cache_free(kmem_cache_t *cache, void *obj);

// 通用 kmalloc/kfree 接口
void *kmalloc(size_t size);
void kfree(void *obj);

// SLUB 系统的自检函数
void slub_check(void);

#endif /* __KERN_MM_SLUB_PMM_H__ */