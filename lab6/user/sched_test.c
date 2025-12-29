#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define TOTAL 5

/* * 1. 定义不同大小的工作量 (Workloads)
 * 数值越大，代表这个进程需要跑越久 (长作业)
 * 我们用 acc (累加器) 来模拟工作进度
 */
int workloads[TOTAL] = { 2000, 500, 4000, 1000, 250 };

/* * 2. 定义优先级 (Priorities)
 * SJF/Stride 需要用到。
 * 注意：Stride算法中，优先级越高(数值大)，步长越小，被调度概率越大。
 */
int priorities[TOTAL] = { 2000, 500, 4000, 1000, 250 };

unsigned int acc[TOTAL];
int status[TOTAL];
int pids[TOTAL];

static void
spin_delay(void)
{
     int i;
     volatile int j;
     for (i = 0; i != 200; ++ i)
     {
          j = !j;
     }
}

int
main(void) {
     int i, time;
     unsigned int start_time; // 用于记录开始时间
     
     memset(pids, 0, sizeof(pids));
     lab6_setpriority(TOTAL + 1);

     cprintf("Main: Start creating %d processes...\n", TOTAL);
     start_time = gettime_msec(); // 记录所有进程开始的时间点

     for (i = 0; i < TOTAL; i ++) {
          acc[i] = 0;
          if ((pids[i] = fork()) == 0) {
               // --- 子进程逻辑 ---
               
               // 设置优先级
               lab6_setpriority(priorities[i]);
               acc[i] = 0;
               
               while (1) {
                    spin_delay();
                    ++ acc[i];
                    
                    /* * 【关键修改 1】加入 yield() 
                     * 防止 CPU 独占，解决 Page Fault 和无输出问题
                     */
                    if (acc[i] % 100 == 0) {
                        yield();
                    }

                    /* * 【关键修改 2】根据工作量退出
                     * 原版是 > MAX_TIME (时间)，我们改成 > workloads[i] (工作量)
                     * 这样才能体现出 SJF (短作业) 和 长作业的区别
                     */
                    if (acc[i] >= workloads[i]) {
                         // 任务完成，打印信息并退出
                         // 注意：这里打印是为了调试，如果还是报错，可以注释掉这就话
                         cprintf("Child %d finished. Work %d\n", i, acc[i]);
                         exit(acc[i]);
                    }
               }
          }
          
          if (pids[i] < 0) {
               goto failed;
          }
     }

     cprintf("main: fork ok, now need to wait pids.\n");

     // --- 父进程逻辑 (参照你要求的 waitpid 写法) ---
     for (i = 0; i < TOTAL; i ++) {
          status[i] = 0;
          
          // 等待指定 PID 的子进程
          waitpid(pids[i], &status[i]);
          
          // 获取当前时间，计算周转时间
          time = gettime_msec() - start_time;
          
          cprintf("Task %d (Work %4d, Prio %4d) finished. PID: %d, Turnaround Time: %5d ms\n", 
                    i, workloads[i], priorities[i], pids[i], time);
     }
     
     cprintf("main: wait pids over\n");
     cprintf("main: all processes finished.\n");
     return 0;

failed:
     for (i = 0; i < TOTAL; i ++) {
          if (pids[i] > 0) {
               kill(pids[i]);
          }
     }
     panic("FAIL: T.T\n");
}