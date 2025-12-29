#include <stdio.h>
#include <ulib.h>

/* enhanced Copy-On-Write test
 * - test global variable and array in .data/.bss
 * - parent sets values, forks; child modifies and prints; parent checks isolation
 */
static volatile int shared = 42;
static volatile int array[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};

int main(void) {
    int pid = fork();
    if (pid < 0) {
        cprintf("fork failed\n");
        return -1;
    }
    if (pid == 0) {
        /* child: modify shared and array */
        shared = 100;
        array[0] = 999;
        cprintf("child shared=%d\n", shared);
        exit(0);
    } else {
        /* parent: wait and check */
        int w = wait();
        (void)w;
        cprintf("parent shared=%d\n", shared);
        if (shared == 42 && array[0] == 0) {
            cprintf("cowtest pass.\n");
            return 0;
        } else {
            cprintf("cowtest fail: parent sees shared=%d, array[0]=%d\n", shared, array[0]);
            return -1;
        }
    }
}