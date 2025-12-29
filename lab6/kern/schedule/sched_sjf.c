#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

static void
SJF_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

static void
SJF_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    
    // SJF 核心逻辑：插入排序
    // 找到队列中第一个“作业长度(priority)”比当前进程大的节点，插在它前面
    list_entry_t *le = list_next(&(rq->run_list));
    while (le != &(rq->run_list)) {
        struct proc_struct *next_proc = le2proc(le, run_link);
        // 这里假设 priority 代表作业长度，越小越短
        if (proc->lab6_priority < next_proc->lab6_priority) {
            break;
        }
        le = list_next(le);
    }
    list_add_before(le, &(proc->run_link));
    
    proc->rq = rq;
    rq->proc_num ++;
}

static void
SJF_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num --;
}

static struct proc_struct *
SJF_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}

static void
SJF_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // SJF 通常是非抢占式的
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = SJF_init,
    .enqueue = SJF_enqueue,
    .dequeue = SJF_dequeue,
    .pick_next = SJF_pick_next,
    .proc_tick = SJF_proc_tick,
};