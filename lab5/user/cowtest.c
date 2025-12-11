#include <stdio.h>
#include <ulib.h>

/* simple Copy-On-Write test
 * - use a global variable in .data so it's mapped in user memory
 * - parent sets shared=42, forks; child writes 100 and prints; parent waits and checks value
 */
static volatile int shared = 42;

int main(void) {
    int pid = fork();
    if (pid < 0) {
        cprintf("fork failed\n");
        return -1;
    }
    if (pid == 0) {
        /* child */
        shared = 100;
        cprintf("child shared=%d\n", shared);
        exit(0);
    } else {
        /* parent */
        int w = wait();
        (void)w;
        cprintf("parent shared=%d\n", shared);
        if (shared == 42) {
            cprintf("cowtest pass.\n");
            return 0;
        } else {
            cprintf("cowtest fail: parent sees %d\n", shared);
            return -1;
        }
    }
}