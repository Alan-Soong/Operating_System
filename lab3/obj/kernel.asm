
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	673010ef          	jal	ffffffffc0201ede <memset>
    dtb_init();
ffffffffc0200070:	40a000ef          	jal	ffffffffc020047a <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3f8000ef          	jal	ffffffffc020046c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e7850513          	addi	a0,a0,-392 # ffffffffc0201ef0 <etext>
ffffffffc0200080:	08e000ef          	jal	ffffffffc020010e <cputs>

    print_kerninfo();
ffffffffc0200084:	0e8000ef          	jal	ffffffffc020016c <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	77a000ef          	jal	ffffffffc0200802 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	69c010ef          	jal	ffffffffc0201728 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	772000ef          	jal	ffffffffc0200802 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	396000ef          	jal	ffffffffc020042a <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	75e000ef          	jal	ffffffffc02007f6 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3c8000ef          	jal	ffffffffc020046e <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	0cf010ef          	jal	ffffffffc020199a <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000de:	f42e                	sd	a1,40(sp)
ffffffffc02000e0:	f832                	sd	a2,48(sp)
ffffffffc02000e2:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	862a                	mv	a2,a0
ffffffffc02000e6:	004c                	addi	a1,sp,4
ffffffffc02000e8:	00000517          	auipc	a0,0x0
ffffffffc02000ec:	fb650513          	addi	a0,a0,-74 # ffffffffc020009e <cputch>
ffffffffc02000f0:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e0ba                	sd	a4,64(sp)
ffffffffc02000f6:	e4be                	sd	a5,72(sp)
ffffffffc02000f8:	e8c2                	sd	a6,80(sp)
ffffffffc02000fa:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fc:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000fe:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200100:	09b010ef          	jal	ffffffffc020199a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200104:	60e2                	ld	ra,24(sp)
ffffffffc0200106:	4512                	lw	a0,4(sp)
ffffffffc0200108:	6125                	addi	sp,sp,96
ffffffffc020010a:	8082                	ret

ffffffffc020010c <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010c:	a68d                	j	ffffffffc020046e <cons_putc>

ffffffffc020010e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020010e:	1101                	addi	sp,sp,-32
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200116:	00054503          	lbu	a0,0(a0)
ffffffffc020011a:	c905                	beqz	a0,ffffffffc020014a <cputs+0x3c>
ffffffffc020011c:	e426                	sd	s1,8(sp)
ffffffffc020011e:	00178493          	addi	s1,a5,1
ffffffffc0200122:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200124:	34a000ef          	jal	ffffffffc020046e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200128:	00044503          	lbu	a0,0(s0)
ffffffffc020012c:	87a2                	mv	a5,s0
ffffffffc020012e:	0405                	addi	s0,s0,1
ffffffffc0200130:	f975                	bnez	a0,ffffffffc0200124 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200132:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc0200134:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200136:	0027841b          	addiw	s0,a5,2
ffffffffc020013a:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc020013c:	332000ef          	jal	ffffffffc020046e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret
    cons_putc(c);
ffffffffc020014a:	4529                	li	a0,10
ffffffffc020014c:	322000ef          	jal	ffffffffc020046e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200150:	4405                	li	s0,1
}
ffffffffc0200152:	60e2                	ld	ra,24(sp)
ffffffffc0200154:	8522                	mv	a0,s0
ffffffffc0200156:	6442                	ld	s0,16(sp)
ffffffffc0200158:	6105                	addi	sp,sp,32
ffffffffc020015a:	8082                	ret

ffffffffc020015c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020015c:	1141                	addi	sp,sp,-16
ffffffffc020015e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200160:	316000ef          	jal	ffffffffc0200476 <cons_getc>
ffffffffc0200164:	dd75                	beqz	a0,ffffffffc0200160 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200166:	60a2                	ld	ra,8(sp)
ffffffffc0200168:	0141                	addi	sp,sp,16
ffffffffc020016a:	8082                	ret

ffffffffc020016c <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020016c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016e:	00002517          	auipc	a0,0x2
ffffffffc0200172:	da250513          	addi	a0,a0,-606 # ffffffffc0201f10 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200176:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200178:	f61ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020017c:	00000597          	auipc	a1,0x0
ffffffffc0200180:	ed858593          	addi	a1,a1,-296 # ffffffffc0200054 <kern_init>
ffffffffc0200184:	00002517          	auipc	a0,0x2
ffffffffc0200188:	dac50513          	addi	a0,a0,-596 # ffffffffc0201f30 <etext+0x40>
ffffffffc020018c:	f4dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200190:	00002597          	auipc	a1,0x2
ffffffffc0200194:	d6058593          	addi	a1,a1,-672 # ffffffffc0201ef0 <etext>
ffffffffc0200198:	00002517          	auipc	a0,0x2
ffffffffc020019c:	db850513          	addi	a0,a0,-584 # ffffffffc0201f50 <etext+0x60>
ffffffffc02001a0:	f39ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a4:	00006597          	auipc	a1,0x6
ffffffffc02001a8:	e8458593          	addi	a1,a1,-380 # ffffffffc0206028 <free_area>
ffffffffc02001ac:	00002517          	auipc	a0,0x2
ffffffffc02001b0:	dc450513          	addi	a0,a0,-572 # ffffffffc0201f70 <etext+0x80>
ffffffffc02001b4:	f25ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b8:	00006597          	auipc	a1,0x6
ffffffffc02001bc:	2e858593          	addi	a1,a1,744 # ffffffffc02064a0 <end>
ffffffffc02001c0:	00002517          	auipc	a0,0x2
ffffffffc02001c4:	dd050513          	addi	a0,a0,-560 # ffffffffc0201f90 <etext+0xa0>
ffffffffc02001c8:	f11ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001cc:	00006797          	auipc	a5,0x6
ffffffffc02001d0:	6d378793          	addi	a5,a5,1747 # ffffffffc020689f <end+0x3ff>
ffffffffc02001d4:	00000717          	auipc	a4,0x0
ffffffffc02001d8:	e8070713          	addi	a4,a4,-384 # ffffffffc0200054 <kern_init>
ffffffffc02001dc:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001de:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e8:	95be                	add	a1,a1,a5
ffffffffc02001ea:	85a9                	srai	a1,a1,0xa
ffffffffc02001ec:	00002517          	auipc	a0,0x2
ffffffffc02001f0:	dc450513          	addi	a0,a0,-572 # ffffffffc0201fb0 <etext+0xc0>
}
ffffffffc02001f4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f6:	b5cd                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001f8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001fa:	00002617          	auipc	a2,0x2
ffffffffc02001fe:	de660613          	addi	a2,a2,-538 # ffffffffc0201fe0 <etext+0xf0>
ffffffffc0200202:	04d00593          	li	a1,77
ffffffffc0200206:	00002517          	auipc	a0,0x2
ffffffffc020020a:	df250513          	addi	a0,a0,-526 # ffffffffc0201ff8 <etext+0x108>
void print_stackframe(void) {
ffffffffc020020e:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200210:	1bc000ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0200214 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200214:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200216:	00002617          	auipc	a2,0x2
ffffffffc020021a:	dfa60613          	addi	a2,a2,-518 # ffffffffc0202010 <etext+0x120>
ffffffffc020021e:	00002597          	auipc	a1,0x2
ffffffffc0200222:	e1258593          	addi	a1,a1,-494 # ffffffffc0202030 <etext+0x140>
ffffffffc0200226:	00002517          	auipc	a0,0x2
ffffffffc020022a:	e1250513          	addi	a0,a0,-494 # ffffffffc0202038 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200230:	ea9ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200234:	00002617          	auipc	a2,0x2
ffffffffc0200238:	e1460613          	addi	a2,a2,-492 # ffffffffc0202048 <etext+0x158>
ffffffffc020023c:	00002597          	auipc	a1,0x2
ffffffffc0200240:	e3458593          	addi	a1,a1,-460 # ffffffffc0202070 <etext+0x180>
ffffffffc0200244:	00002517          	auipc	a0,0x2
ffffffffc0200248:	df450513          	addi	a0,a0,-524 # ffffffffc0202038 <etext+0x148>
ffffffffc020024c:	e8dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200250:	00002617          	auipc	a2,0x2
ffffffffc0200254:	e3060613          	addi	a2,a2,-464 # ffffffffc0202080 <etext+0x190>
ffffffffc0200258:	00002597          	auipc	a1,0x2
ffffffffc020025c:	e4858593          	addi	a1,a1,-440 # ffffffffc02020a0 <etext+0x1b0>
ffffffffc0200260:	00002517          	auipc	a0,0x2
ffffffffc0200264:	dd850513          	addi	a0,a0,-552 # ffffffffc0202038 <etext+0x148>
ffffffffc0200268:	e71ff0ef          	jal	ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc020026c:	60a2                	ld	ra,8(sp)
ffffffffc020026e:	4501                	li	a0,0
ffffffffc0200270:	0141                	addi	sp,sp,16
ffffffffc0200272:	8082                	ret

ffffffffc0200274 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200274:	1141                	addi	sp,sp,-16
ffffffffc0200276:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200278:	ef5ff0ef          	jal	ffffffffc020016c <print_kerninfo>
    return 0;
}
ffffffffc020027c:	60a2                	ld	ra,8(sp)
ffffffffc020027e:	4501                	li	a0,0
ffffffffc0200280:	0141                	addi	sp,sp,16
ffffffffc0200282:	8082                	ret

ffffffffc0200284 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200284:	1141                	addi	sp,sp,-16
ffffffffc0200286:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200288:	f71ff0ef          	jal	ffffffffc02001f8 <print_stackframe>
    return 0;
}
ffffffffc020028c:	60a2                	ld	ra,8(sp)
ffffffffc020028e:	4501                	li	a0,0
ffffffffc0200290:	0141                	addi	sp,sp,16
ffffffffc0200292:	8082                	ret

ffffffffc0200294 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200294:	7115                	addi	sp,sp,-224
ffffffffc0200296:	f15a                	sd	s6,160(sp)
ffffffffc0200298:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020029a:	00002517          	auipc	a0,0x2
ffffffffc020029e:	e1650513          	addi	a0,a0,-490 # ffffffffc02020b0 <etext+0x1c0>
kmonitor(struct trapframe *tf) {
ffffffffc02002a2:	ed86                	sd	ra,216(sp)
ffffffffc02002a4:	e9a2                	sd	s0,208(sp)
ffffffffc02002a6:	e5a6                	sd	s1,200(sp)
ffffffffc02002a8:	e1ca                	sd	s2,192(sp)
ffffffffc02002aa:	fd4e                	sd	s3,184(sp)
ffffffffc02002ac:	f952                	sd	s4,176(sp)
ffffffffc02002ae:	f556                	sd	s5,168(sp)
ffffffffc02002b0:	ed5e                	sd	s7,152(sp)
ffffffffc02002b2:	e962                	sd	s8,144(sp)
ffffffffc02002b4:	e566                	sd	s9,136(sp)
ffffffffc02002b6:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b8:	e21ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002bc:	00002517          	auipc	a0,0x2
ffffffffc02002c0:	e1c50513          	addi	a0,a0,-484 # ffffffffc02020d8 <etext+0x1e8>
ffffffffc02002c4:	e15ff0ef          	jal	ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002c8:	000b0563          	beqz	s6,ffffffffc02002d2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002cc:	855a                	mv	a0,s6
ffffffffc02002ce:	714000ef          	jal	ffffffffc02009e2 <print_trapframe>
ffffffffc02002d2:	00003c17          	auipc	s8,0x3
ffffffffc02002d6:	a3ec0c13          	addi	s8,s8,-1474 # ffffffffc0202d10 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002da:	00002917          	auipc	s2,0x2
ffffffffc02002de:	e2690913          	addi	s2,s2,-474 # ffffffffc0202100 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	00002497          	auipc	s1,0x2
ffffffffc02002e6:	e2648493          	addi	s1,s1,-474 # ffffffffc0202108 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002ea:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ec:	00002a97          	auipc	s5,0x2
ffffffffc02002f0:	e24a8a93          	addi	s5,s5,-476 # ffffffffc0202110 <etext+0x220>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f4:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002f6:	00002b97          	auipc	s7,0x2
ffffffffc02002fa:	e3ab8b93          	addi	s7,s7,-454 # ffffffffc0202130 <etext+0x240>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fe:	854a                	mv	a0,s2
ffffffffc0200300:	215010ef          	jal	ffffffffc0201d14 <readline>
ffffffffc0200304:	842a                	mv	s0,a0
ffffffffc0200306:	dd65                	beqz	a0,ffffffffc02002fe <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200308:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030c:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	e59d                	bnez	a1,ffffffffc020033c <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc0200310:	fe0c87e3          	beqz	s9,ffffffffc02002fe <kmonitor+0x6a>
ffffffffc0200314:	00003d17          	auipc	s10,0x3
ffffffffc0200318:	9fcd0d13          	addi	s10,s10,-1540 # ffffffffc0202d10 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031e:	6582                	ld	a1,0(sp)
ffffffffc0200320:	000d3503          	ld	a0,0(s10)
ffffffffc0200324:	345010ef          	jal	ffffffffc0201e68 <strcmp>
ffffffffc0200328:	c53d                	beqz	a0,ffffffffc0200396 <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	2405                	addiw	s0,s0,1
ffffffffc020032c:	0d61                	addi	s10,s10,24
ffffffffc020032e:	ff4418e3          	bne	s0,s4,ffffffffc020031e <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200332:	6582                	ld	a1,0(sp)
ffffffffc0200334:	855e                	mv	a0,s7
ffffffffc0200336:	da3ff0ef          	jal	ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020033a:	b7d1                	j	ffffffffc02002fe <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	8526                	mv	a0,s1
ffffffffc020033e:	38b010ef          	jal	ffffffffc0201ec8 <strchr>
ffffffffc0200342:	c901                	beqz	a0,ffffffffc0200352 <kmonitor+0xbe>
ffffffffc0200344:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200348:	00040023          	sb	zero,0(s0)
ffffffffc020034c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020034e:	d1e9                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc0200350:	b7f5                	j	ffffffffc020033c <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc0200352:	00044783          	lbu	a5,0(s0)
ffffffffc0200356:	dfcd                	beqz	a5,ffffffffc0200310 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200358:	033c8a63          	beq	s9,s3,ffffffffc020038c <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc020035c:	003c9793          	slli	a5,s9,0x3
ffffffffc0200360:	08078793          	addi	a5,a5,128
ffffffffc0200364:	978a                	add	a5,a5,sp
ffffffffc0200366:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020036a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020036e:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	e591                	bnez	a1,ffffffffc020037c <kmonitor+0xe8>
ffffffffc0200372:	bf79                	j	ffffffffc0200310 <kmonitor+0x7c>
ffffffffc0200374:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200378:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037a:	d9d9                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc020037c:	8526                	mv	a0,s1
ffffffffc020037e:	34b010ef          	jal	ffffffffc0201ec8 <strchr>
ffffffffc0200382:	d96d                	beqz	a0,ffffffffc0200374 <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200384:	00044583          	lbu	a1,0(s0)
ffffffffc0200388:	d5c1                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc020038a:	bf4d                	j	ffffffffc020033c <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038c:	45c1                	li	a1,16
ffffffffc020038e:	8556                	mv	a0,s5
ffffffffc0200390:	d49ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200394:	b7e1                	j	ffffffffc020035c <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200396:	00141793          	slli	a5,s0,0x1
ffffffffc020039a:	97a2                	add	a5,a5,s0
ffffffffc020039c:	078e                	slli	a5,a5,0x3
ffffffffc020039e:	97e2                	add	a5,a5,s8
ffffffffc02003a0:	6b9c                	ld	a5,16(a5)
ffffffffc02003a2:	865a                	mv	a2,s6
ffffffffc02003a4:	002c                	addi	a1,sp,8
ffffffffc02003a6:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003aa:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003ac:	f40559e3          	bgez	a0,ffffffffc02002fe <kmonitor+0x6a>
}
ffffffffc02003b0:	60ee                	ld	ra,216(sp)
ffffffffc02003b2:	644e                	ld	s0,208(sp)
ffffffffc02003b4:	64ae                	ld	s1,200(sp)
ffffffffc02003b6:	690e                	ld	s2,192(sp)
ffffffffc02003b8:	79ea                	ld	s3,184(sp)
ffffffffc02003ba:	7a4a                	ld	s4,176(sp)
ffffffffc02003bc:	7aaa                	ld	s5,168(sp)
ffffffffc02003be:	7b0a                	ld	s6,160(sp)
ffffffffc02003c0:	6bea                	ld	s7,152(sp)
ffffffffc02003c2:	6c4a                	ld	s8,144(sp)
ffffffffc02003c4:	6caa                	ld	s9,136(sp)
ffffffffc02003c6:	6d0a                	ld	s10,128(sp)
ffffffffc02003c8:	612d                	addi	sp,sp,224
ffffffffc02003ca:	8082                	ret

ffffffffc02003cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003cc:	00006317          	auipc	t1,0x6
ffffffffc02003d0:	07430313          	addi	t1,t1,116 # ffffffffc0206440 <is_panic>
ffffffffc02003d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003d8:	715d                	addi	sp,sp,-80
ffffffffc02003da:	ec06                	sd	ra,24(sp)
ffffffffc02003dc:	f436                	sd	a3,40(sp)
ffffffffc02003de:	f83a                	sd	a4,48(sp)
ffffffffc02003e0:	fc3e                	sd	a5,56(sp)
ffffffffc02003e2:	e0c2                	sd	a6,64(sp)
ffffffffc02003e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003e6:	020e1c63          	bnez	t3,ffffffffc020041e <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003ea:	4785                	li	a5,1
ffffffffc02003ec:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f0:	e822                	sd	s0,16(sp)
ffffffffc02003f2:	103c                	addi	a5,sp,40
ffffffffc02003f4:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003f6:	862e                	mv	a2,a1
ffffffffc02003f8:	85aa                	mv	a1,a0
ffffffffc02003fa:	00002517          	auipc	a0,0x2
ffffffffc02003fe:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202148 <etext+0x258>
    va_start(ap, fmt);
ffffffffc0200402:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200404:	cd5ff0ef          	jal	ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200408:	65a2                	ld	a1,8(sp)
ffffffffc020040a:	8522                	mv	a0,s0
ffffffffc020040c:	cadff0ef          	jal	ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200410:	00002517          	auipc	a0,0x2
ffffffffc0200414:	d5850513          	addi	a0,a0,-680 # ffffffffc0202168 <etext+0x278>
ffffffffc0200418:	cc1ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020041c:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020041e:	3de000ef          	jal	ffffffffc02007fc <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200422:	4501                	li	a0,0
ffffffffc0200424:	e71ff0ef          	jal	ffffffffc0200294 <kmonitor>
    while (1) {
ffffffffc0200428:	bfed                	j	ffffffffc0200422 <__panic+0x56>

ffffffffc020042a <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042a:	1141                	addi	sp,sp,-16
ffffffffc020042c:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020042e:	02000793          	li	a5,32
ffffffffc0200432:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	1a1010ef          	jal	ffffffffc0201de2 <sbi_set_timer>
}
ffffffffc0200446:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200448:	00006797          	auipc	a5,0x6
ffffffffc020044c:	0007b023          	sd	zero,0(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200450:	00002517          	auipc	a0,0x2
ffffffffc0200454:	d2050513          	addi	a0,a0,-736 # ffffffffc0202170 <etext+0x280>
}
ffffffffc0200458:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045a:	b9bd                	j	ffffffffc02000d8 <cprintf>

ffffffffc020045c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020045c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200460:	67e1                	lui	a5,0x18
ffffffffc0200462:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200466:	953e                	add	a0,a0,a5
ffffffffc0200468:	17b0106f          	j	ffffffffc0201de2 <sbi_set_timer>

ffffffffc020046c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020046c:	8082                	ret

ffffffffc020046e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020046e:	0ff57513          	zext.b	a0,a0
ffffffffc0200472:	1570106f          	j	ffffffffc0201dc8 <sbi_console_putchar>

ffffffffc0200476 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200476:	1870106f          	j	ffffffffc0201dfc <sbi_console_getchar>

ffffffffc020047a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047a:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020047c:	00002517          	auipc	a0,0x2
ffffffffc0200480:	d1450513          	addi	a0,a0,-748 # ffffffffc0202190 <etext+0x2a0>
void dtb_init(void) {
ffffffffc0200484:	ec86                	sd	ra,88(sp)
ffffffffc0200486:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc0200488:	c51ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020048c:	00006597          	auipc	a1,0x6
ffffffffc0200490:	b745b583          	ld	a1,-1164(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	d0c50513          	addi	a0,a0,-756 # ffffffffc02021a0 <etext+0x2b0>
ffffffffc020049c:	c3dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004a0:	00006417          	auipc	s0,0x6
ffffffffc02004a4:	b6840413          	addi	s0,s0,-1176 # ffffffffc0206008 <boot_dtb>
ffffffffc02004a8:	600c                	ld	a1,0(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	d0650513          	addi	a0,a0,-762 # ffffffffc02021b0 <etext+0x2c0>
ffffffffc02004b2:	c27ff0ef          	jal	ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004b6:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	d1050513          	addi	a0,a0,-752 # ffffffffc02021c8 <etext+0x2d8>
    if (boot_dtb == 0) {
ffffffffc02004c0:	12070d63          	beqz	a4,ffffffffc02005fa <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004c4:	57f5                	li	a5,-3
ffffffffc02004c6:	07fa                	slli	a5,a5,0x1e
ffffffffc02004c8:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004ca:	431c                	lw	a5,0(a4)
ffffffffc02004cc:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ce:	00ff0637          	lui	a2,0xff0
ffffffffc02004d2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004d6:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004da:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004de:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02004e6:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ea:	8ec9                	or	a3,a3,a0
ffffffffc02004ec:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004f0:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02004f2:	0157f7b3          	and	a5,a5,s5
ffffffffc02004f6:	8dd5                	or	a1,a1,a3
ffffffffc02004f8:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004fa:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200500:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200504:	0ef59f63          	bne	a1,a5,ffffffffc0200602 <dtb_init+0x188>
ffffffffc0200508:	471c                	lw	a5,8(a4)
ffffffffc020050a:	4754                	lw	a3,12(a4)
ffffffffc020050c:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050e:	0087d99b          	srliw	s3,a5,0x8
ffffffffc0200512:	0086d41b          	srliw	s0,a3,0x8
ffffffffc0200516:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051e:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	8c71                	and	s0,s0,a2
ffffffffc0200538:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	01156533          	or	a0,a0,a7
ffffffffc0200540:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200544:	0105e633          	or	a2,a1,a6
ffffffffc0200548:	0087979b          	slliw	a5,a5,0x8
ffffffffc020054c:	8c49                	or	s0,s0,a0
ffffffffc020054e:	0156f6b3          	and	a3,a3,s5
ffffffffc0200552:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200556:	0157f7b3          	and	a5,a5,s5
ffffffffc020055a:	8c55                	or	s0,s0,a3
ffffffffc020055c:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200560:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200562:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200564:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200566:	0209d993          	srli	s3,s3,0x20
ffffffffc020056a:	e4a6                	sd	s1,72(sp)
ffffffffc020056c:	e0ca                	sd	s2,64(sp)
ffffffffc020056e:	ec5e                	sd	s7,24(sp)
ffffffffc0200570:	e862                	sd	s8,16(sp)
ffffffffc0200572:	e466                	sd	s9,8(sp)
ffffffffc0200574:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200576:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc0200578:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057e:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200582:	4c0d                	li	s8,3
ffffffffc0200584:	4911                	li	s2,4
ffffffffc0200586:	4d05                	li	s10,1
ffffffffc0200588:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020058a:	0009a703          	lw	a4,0(s3)
ffffffffc020058e:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200592:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200596:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005a6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a8:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ac:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005b0:	8fd5                	or	a5,a5,a3
ffffffffc02005b2:	00eaf733          	and	a4,s5,a4
ffffffffc02005b6:	8fd9                	or	a5,a5,a4
ffffffffc02005b8:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005ba:	09878263          	beq	a5,s8,ffffffffc020063e <dtb_init+0x1c4>
ffffffffc02005be:	00fc6963          	bltu	s8,a5,ffffffffc02005d0 <dtb_init+0x156>
ffffffffc02005c2:	05a78963          	beq	a5,s10,ffffffffc0200614 <dtb_init+0x19a>
ffffffffc02005c6:	00979763          	bne	a5,s1,ffffffffc02005d4 <dtb_init+0x15a>
ffffffffc02005ca:	4b81                	li	s7,0
ffffffffc02005cc:	89d2                	mv	s3,s4
ffffffffc02005ce:	bf75                	j	ffffffffc020058a <dtb_init+0x110>
ffffffffc02005d0:	ff278ee3          	beq	a5,s2,ffffffffc02005cc <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005d4:	00002517          	auipc	a0,0x2
ffffffffc02005d8:	cbc50513          	addi	a0,a0,-836 # ffffffffc0202290 <etext+0x3a0>
ffffffffc02005dc:	afdff0ef          	jal	ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005e0:	64a6                	ld	s1,72(sp)
ffffffffc02005e2:	6906                	ld	s2,64(sp)
ffffffffc02005e4:	79e2                	ld	s3,56(sp)
ffffffffc02005e6:	7a42                	ld	s4,48(sp)
ffffffffc02005e8:	7aa2                	ld	s5,40(sp)
ffffffffc02005ea:	6be2                	ld	s7,24(sp)
ffffffffc02005ec:	6c42                	ld	s8,16(sp)
ffffffffc02005ee:	6ca2                	ld	s9,8(sp)
ffffffffc02005f0:	6d02                	ld	s10,0(sp)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	cd650513          	addi	a0,a0,-810 # ffffffffc02022c8 <etext+0x3d8>
}
ffffffffc02005fa:	6446                	ld	s0,80(sp)
ffffffffc02005fc:	60e6                	ld	ra,88(sp)
ffffffffc02005fe:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc0200600:	bce1                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200602:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200604:	7aa2                	ld	s5,40(sp)
}
ffffffffc0200606:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	be050513          	addi	a0,a0,-1056 # ffffffffc02021e8 <etext+0x2f8>
}
ffffffffc0200610:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200612:	b4d9                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200614:	8552                	mv	a0,s4
ffffffffc0200616:	01d010ef          	jal	ffffffffc0201e32 <strlen>
ffffffffc020061a:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020061c:	4619                	li	a2,6
ffffffffc020061e:	00002597          	auipc	a1,0x2
ffffffffc0200622:	bf258593          	addi	a1,a1,-1038 # ffffffffc0202210 <etext+0x320>
ffffffffc0200626:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc0200628:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020062a:	077010ef          	jal	ffffffffc0201ea0 <strncmp>
ffffffffc020062e:	e111                	bnez	a0,ffffffffc0200632 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc0200630:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200632:	0a11                	addi	s4,s4,4
ffffffffc0200634:	9a4e                	add	s4,s4,s3
ffffffffc0200636:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc020063a:	89d2                	mv	s3,s4
ffffffffc020063c:	b7b9                	j	ffffffffc020058a <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0049a783          	lw	a5,4(s3)
ffffffffc0200642:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200644:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200648:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020064c:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200654:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020065c:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200660:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200664:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200668:	00eb6b33          	or	s6,s6,a4
ffffffffc020066c:	00faf7b3          	and	a5,s5,a5
ffffffffc0200670:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200674:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020067a:	000b9c63          	bnez	s7,ffffffffc0200692 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020067e:	1b02                	slli	s6,s6,0x20
ffffffffc0200680:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200684:	0a0d                	addi	s4,s4,3
ffffffffc0200686:	9a5a                	add	s4,s4,s6
ffffffffc0200688:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020068c:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc020068e:	89d2                	mv	s3,s4
ffffffffc0200690:	bded                	j	ffffffffc020058a <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200692:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200696:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006aa:	8fd9                	or	a5,a5,a4
ffffffffc02006ac:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006b0:	8d5d                	or	a0,a0,a5
ffffffffc02006b2:	00daf6b3          	and	a3,s5,a3
ffffffffc02006b6:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006b8:	1502                	slli	a0,a0,0x20
ffffffffc02006ba:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006bc:	00002597          	auipc	a1,0x2
ffffffffc02006c0:	b5c58593          	addi	a1,a1,-1188 # ffffffffc0202218 <etext+0x328>
ffffffffc02006c4:	9522                	add	a0,a0,s0
ffffffffc02006c6:	7a2010ef          	jal	ffffffffc0201e68 <strcmp>
ffffffffc02006ca:	f955                	bnez	a0,ffffffffc020067e <dtb_init+0x204>
ffffffffc02006cc:	47bd                	li	a5,15
ffffffffc02006ce:	fb67f8e3          	bgeu	a5,s6,ffffffffc020067e <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006d2:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006d6:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	b4650513          	addi	a0,a0,-1210 # ffffffffc0202220 <etext+0x330>
           fdt32_to_cpu(x >> 32);
ffffffffc02006e2:	4207d693          	srai	a3,a5,0x20
ffffffffc02006e6:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ea:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02006ee:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02006f2:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02006f6:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fa:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02006fe:	0087541b          	srliw	s0,a4,0x8
ffffffffc0200702:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	01869e1b          	slliw	t3,a3,0x18
ffffffffc020070e:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0188189b          	slliw	a7,a6,0x18
ffffffffc020071a:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0108581b          	srliw	a6,a6,0x10
ffffffffc0200726:	005e6e33          	or	t3,t3,t0
ffffffffc020072a:	01e8e8b3          	or	a7,a7,t5
ffffffffc020072e:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0104949b          	slliw	s1,s1,0x10
ffffffffc0200736:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073a:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200742:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200746:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074a:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074e:	00daf6b3          	and	a3,s5,a3
ffffffffc0200752:	007eeeb3          	or	t4,t4,t2
ffffffffc0200756:	01f36333          	or	t1,t1,t6
ffffffffc020075a:	01c7e7b3          	or	a5,a5,t3
ffffffffc020075e:	00caf633          	and	a2,s5,a2
ffffffffc0200762:	01176733          	or	a4,a4,a7
ffffffffc0200766:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076e:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200772:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200776:	01d4e4b3          	or	s1,s1,t4
ffffffffc020077a:	00646433          	or	s0,s0,t1
ffffffffc020077e:	8fd5                	or	a5,a5,a3
ffffffffc0200780:	01576733          	or	a4,a4,s5
ffffffffc0200784:	8c51                	or	s0,s0,a2
ffffffffc0200786:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc0200788:	1782                	slli	a5,a5,0x20
ffffffffc020078a:	1702                	slli	a4,a4,0x20
ffffffffc020078c:	9381                	srli	a5,a5,0x20
ffffffffc020078e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200790:	1482                	slli	s1,s1,0x20
ffffffffc0200792:	1402                	slli	s0,s0,0x20
ffffffffc0200794:	8cdd                	or	s1,s1,a5
ffffffffc0200796:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200798:	941ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020079c:	85a6                	mv	a1,s1
ffffffffc020079e:	00002517          	auipc	a0,0x2
ffffffffc02007a2:	aa250513          	addi	a0,a0,-1374 # ffffffffc0202240 <etext+0x350>
ffffffffc02007a6:	933ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007aa:	01445613          	srli	a2,s0,0x14
ffffffffc02007ae:	85a2                	mv	a1,s0
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	aa850513          	addi	a0,a0,-1368 # ffffffffc0202258 <etext+0x368>
ffffffffc02007b8:	921ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007bc:	009405b3          	add	a1,s0,s1
ffffffffc02007c0:	15fd                	addi	a1,a1,-1
ffffffffc02007c2:	00002517          	auipc	a0,0x2
ffffffffc02007c6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0202278 <etext+0x388>
ffffffffc02007ca:	90fff0ef          	jal	ffffffffc02000d8 <cprintf>
        memory_base = mem_base;
ffffffffc02007ce:	7b02                	ld	s6,32(sp)
ffffffffc02007d0:	00006797          	auipc	a5,0x6
ffffffffc02007d4:	c897b423          	sd	s1,-888(a5) # ffffffffc0206458 <memory_base>
        memory_size = mem_size;
ffffffffc02007d8:	00006797          	auipc	a5,0x6
ffffffffc02007dc:	c687bc23          	sd	s0,-904(a5) # ffffffffc0206450 <memory_size>
ffffffffc02007e0:	b501                	j	ffffffffc02005e0 <dtb_init+0x166>

ffffffffc02007e2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007e2:	00006517          	auipc	a0,0x6
ffffffffc02007e6:	c7653503          	ld	a0,-906(a0) # ffffffffc0206458 <memory_base>
ffffffffc02007ea:	8082                	ret

ffffffffc02007ec <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	c6453503          	ld	a0,-924(a0) # ffffffffc0206450 <memory_size>
ffffffffc02007f4:	8082                	ret

ffffffffc02007f6 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007f6:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02007fa:	8082                	ret

ffffffffc02007fc <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007fc:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200800:	8082                	ret

ffffffffc0200802 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200802:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200806:	00000797          	auipc	a5,0x0
ffffffffc020080a:	39678793          	addi	a5,a5,918 # ffffffffc0200b9c <__alltraps>
ffffffffc020080e:	10579073          	csrw	stvec,a5
}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200814:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200816:	1141                	addi	sp,sp,-16
ffffffffc0200818:	e022                	sd	s0,0(sp)
ffffffffc020081a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020081c:	00002517          	auipc	a0,0x2
ffffffffc0200820:	ac450513          	addi	a0,a0,-1340 # ffffffffc02022e0 <etext+0x3f0>
void print_regs(struct pushregs *gpr) {
ffffffffc0200824:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200826:	8b3ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020082a:	640c                	ld	a1,8(s0)
ffffffffc020082c:	00002517          	auipc	a0,0x2
ffffffffc0200830:	acc50513          	addi	a0,a0,-1332 # ffffffffc02022f8 <etext+0x408>
ffffffffc0200834:	8a5ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200838:	680c                	ld	a1,16(s0)
ffffffffc020083a:	00002517          	auipc	a0,0x2
ffffffffc020083e:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202310 <etext+0x420>
ffffffffc0200842:	897ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200846:	6c0c                	ld	a1,24(s0)
ffffffffc0200848:	00002517          	auipc	a0,0x2
ffffffffc020084c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202328 <etext+0x438>
ffffffffc0200850:	889ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200854:	700c                	ld	a1,32(s0)
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202340 <etext+0x450>
ffffffffc020085e:	87bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200862:	740c                	ld	a1,40(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	af450513          	addi	a0,a0,-1292 # ffffffffc0202358 <etext+0x468>
ffffffffc020086c:	86dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200870:	780c                	ld	a1,48(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	afe50513          	addi	a0,a0,-1282 # ffffffffc0202370 <etext+0x480>
ffffffffc020087a:	85fff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020087e:	7c0c                	ld	a1,56(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	b0850513          	addi	a0,a0,-1272 # ffffffffc0202388 <etext+0x498>
ffffffffc0200888:	851ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020088c:	602c                	ld	a1,64(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	b1250513          	addi	a0,a0,-1262 # ffffffffc02023a0 <etext+0x4b0>
ffffffffc0200896:	843ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020089a:	642c                	ld	a1,72(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02023b8 <etext+0x4c8>
ffffffffc02008a4:	835ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008a8:	682c                	ld	a1,80(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	b2650513          	addi	a0,a0,-1242 # ffffffffc02023d0 <etext+0x4e0>
ffffffffc02008b2:	827ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008b6:	6c2c                	ld	a1,88(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	b3050513          	addi	a0,a0,-1232 # ffffffffc02023e8 <etext+0x4f8>
ffffffffc02008c0:	819ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008c4:	702c                	ld	a1,96(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202400 <etext+0x510>
ffffffffc02008ce:	80bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008d2:	742c                	ld	a1,104(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202418 <etext+0x528>
ffffffffc02008dc:	ffcff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008e0:	782c                	ld	a1,112(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0202430 <etext+0x540>
ffffffffc02008ea:	feeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008ee:	7c2c                	ld	a1,120(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202448 <etext+0x558>
ffffffffc02008f8:	fe0ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02008fc:	604c                	ld	a1,128(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202460 <etext+0x570>
ffffffffc0200906:	fd2ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020090a:	644c                	ld	a1,136(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202478 <etext+0x588>
ffffffffc0200914:	fc4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200918:	684c                	ld	a1,144(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	b7650513          	addi	a0,a0,-1162 # ffffffffc0202490 <etext+0x5a0>
ffffffffc0200922:	fb6ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200926:	6c4c                	ld	a1,152(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	b8050513          	addi	a0,a0,-1152 # ffffffffc02024a8 <etext+0x5b8>
ffffffffc0200930:	fa8ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200934:	704c                	ld	a1,160(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc02024c0 <etext+0x5d0>
ffffffffc020093e:	f9aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200942:	744c                	ld	a1,168(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	b9450513          	addi	a0,a0,-1132 # ffffffffc02024d8 <etext+0x5e8>
ffffffffc020094c:	f8cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200950:	784c                	ld	a1,176(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02024f0 <etext+0x600>
ffffffffc020095a:	f7eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020095e:	7c4c                	ld	a1,184(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202508 <etext+0x618>
ffffffffc0200968:	f70ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020096c:	606c                	ld	a1,192(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202520 <etext+0x630>
ffffffffc0200976:	f62ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc020097a:	646c                	ld	a1,200(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202538 <etext+0x648>
ffffffffc0200984:	f54ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200988:	686c                	ld	a1,208(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202550 <etext+0x660>
ffffffffc0200992:	f46ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200996:	6c6c                	ld	a1,216(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202568 <etext+0x678>
ffffffffc02009a0:	f38ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009a4:	706c                	ld	a1,224(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202580 <etext+0x690>
ffffffffc02009ae:	f2aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009b2:	746c                	ld	a1,232(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	be450513          	addi	a0,a0,-1052 # ffffffffc0202598 <etext+0x6a8>
ffffffffc02009bc:	f1cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009c0:	786c                	ld	a1,240(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	bee50513          	addi	a0,a0,-1042 # ffffffffc02025b0 <etext+0x6c0>
ffffffffc02009ca:	f0eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ce:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009d0:	6402                	ld	s0,0(sp)
ffffffffc02009d2:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009d4:	00002517          	auipc	a0,0x2
ffffffffc02009d8:	bf450513          	addi	a0,a0,-1036 # ffffffffc02025c8 <etext+0x6d8>
}
ffffffffc02009dc:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009de:	efaff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc02009e2 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e2:	1141                	addi	sp,sp,-16
ffffffffc02009e4:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009e6:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e8:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	bf650513          	addi	a0,a0,-1034 # ffffffffc02025e0 <etext+0x6f0>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009f2:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009f4:	ee4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009f8:	8522                	mv	a0,s0
ffffffffc02009fa:	e1bff0ef          	jal	ffffffffc0200814 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02009fe:	10043583          	ld	a1,256(s0)
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	bf650513          	addi	a0,a0,-1034 # ffffffffc02025f8 <etext+0x708>
ffffffffc0200a0a:	eceff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a0e:	10843583          	ld	a1,264(s0)
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0202610 <etext+0x720>
ffffffffc0200a1a:	ebeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a1e:	11043583          	ld	a1,272(s0)
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202628 <etext+0x738>
ffffffffc0200a2a:	eaeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a2e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a32:	6402                	ld	s0,0(sp)
ffffffffc0200a34:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a36:	00002517          	auipc	a0,0x2
ffffffffc0200a3a:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202640 <etext+0x750>
}
ffffffffc0200a3e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a40:	e98ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a44 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc0200a44:	11853783          	ld	a5,280(a0)
ffffffffc0200a48:	472d                	li	a4,11
ffffffffc0200a4a:	0786                	slli	a5,a5,0x1
ffffffffc0200a4c:	8385                	srli	a5,a5,0x1
ffffffffc0200a4e:	08f76263          	bltu	a4,a5,ffffffffc0200ad2 <interrupt_handler+0x8e>
ffffffffc0200a52:	00002717          	auipc	a4,0x2
ffffffffc0200a56:	30670713          	addi	a4,a4,774 # ffffffffc0202d58 <commands+0x48>
ffffffffc0200a5a:	078a                	slli	a5,a5,0x2
ffffffffc0200a5c:	97ba                	add	a5,a5,a4
ffffffffc0200a5e:	439c                	lw	a5,0(a5)
ffffffffc0200a60:	97ba                	add	a5,a5,a4
ffffffffc0200a62:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	c5450513          	addi	a0,a0,-940 # ffffffffc02026b8 <etext+0x7c8>
ffffffffc0200a6c:	e6cff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	c2850513          	addi	a0,a0,-984 # ffffffffc0202698 <etext+0x7a8>
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a7c:	00002517          	auipc	a0,0x2
ffffffffc0200a80:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202658 <etext+0x768>
ffffffffc0200a84:	e54ff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a88:	00002517          	auipc	a0,0x2
ffffffffc0200a8c:	c5050513          	addi	a0,a0,-944 # ffffffffc02026d8 <etext+0x7e8>
ffffffffc0200a90:	e48ff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a94:	1141                	addi	sp,sp,-16
ffffffffc0200a96:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200a98:	9c5ff0ef          	jal	ffffffffc020045c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200a9c:	00006697          	auipc	a3,0x6
ffffffffc0200aa0:	9ac68693          	addi	a3,a3,-1620 # ffffffffc0206448 <ticks>
ffffffffc0200aa4:	629c                	ld	a5,0(a3)
ffffffffc0200aa6:	06400713          	li	a4,100
ffffffffc0200aaa:	0785                	addi	a5,a5,1
ffffffffc0200aac:	02e7f733          	remu	a4,a5,a4
ffffffffc0200ab0:	e29c                	sd	a5,0(a3)
ffffffffc0200ab2:	c30d                	beqz	a4,ffffffffc0200ad4 <interrupt_handler+0x90>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ab4:	60a2                	ld	ra,8(sp)
ffffffffc0200ab6:	0141                	addi	sp,sp,16
ffffffffc0200ab8:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200aba:	00002517          	auipc	a0,0x2
ffffffffc0200abe:	c4650513          	addi	a0,a0,-954 # ffffffffc0202700 <etext+0x810>
ffffffffc0200ac2:	e16ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ac6:	00002517          	auipc	a0,0x2
ffffffffc0200aca:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202678 <etext+0x788>
ffffffffc0200ace:	e0aff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200ad2:	bf01                	j	ffffffffc02009e2 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ad4:	06400593          	li	a1,100
ffffffffc0200ad8:	00002517          	auipc	a0,0x2
ffffffffc0200adc:	c1850513          	addi	a0,a0,-1000 # ffffffffc02026f0 <etext+0x800>
ffffffffc0200ae0:	df8ff0ef          	jal	ffffffffc02000d8 <cprintf>
                print_count++;
ffffffffc0200ae4:	00006717          	auipc	a4,0x6
ffffffffc0200ae8:	97c70713          	addi	a4,a4,-1668 # ffffffffc0206460 <print_count.0>
ffffffffc0200aec:	431c                	lw	a5,0(a4)
                if (print_count == 10) {
ffffffffc0200aee:	46a9                	li	a3,10
                print_count++;
ffffffffc0200af0:	0017861b          	addiw	a2,a5,1
ffffffffc0200af4:	c310                	sw	a2,0(a4)
                if (print_count == 10) {
ffffffffc0200af6:	fad61fe3          	bne	a2,a3,ffffffffc0200ab4 <interrupt_handler+0x70>
}
ffffffffc0200afa:	60a2                	ld	ra,8(sp)
ffffffffc0200afc:	0141                	addi	sp,sp,16
                    sbi_shutdown(); // 关机
ffffffffc0200afe:	31a0106f          	j	ffffffffc0201e18 <sbi_shutdown>

ffffffffc0200b02 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b02:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b06:	1141                	addi	sp,sp,-16
ffffffffc0200b08:	e022                	sd	s0,0(sp)
ffffffffc0200b0a:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b0c:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b0e:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b10:	04e78763          	beq	a5,a4,ffffffffc0200b5e <exception_handler+0x5c>
ffffffffc0200b14:	02f76d63          	bltu	a4,a5,ffffffffc0200b4e <exception_handler+0x4c>
ffffffffc0200b18:	4709                	li	a4,2
ffffffffc0200b1a:	02e79663          	bne	a5,a4,ffffffffc0200b46 <exception_handler+0x44>
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            // 非法指令异常处理
            // LAB3 CHALLENGE3   YOUR CODE : 
            cprintf("Illegal instruction caught at 0x%08x, epc = 0x%lx\n", tf->epc, tf->epc); // (1)
ffffffffc0200b1e:	10843603          	ld	a2,264(s0)
ffffffffc0200b22:	00002517          	auipc	a0,0x2
ffffffffc0200b26:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0202720 <etext+0x830>
ffffffffc0200b2a:	85b2                	mv	a1,a2
ffffffffc0200b2c:	dacff0ef          	jal	ffffffffc02000d8 <cprintf>
            cprintf("Exception type:Illegal instruction\n"); // (2)
ffffffffc0200b30:	00002517          	auipc	a0,0x2
ffffffffc0200b34:	c2850513          	addi	a0,a0,-984 # ffffffffc0202758 <etext+0x868>
ffffffffc0200b38:	da0ff0ef          	jal	ffffffffc02000d8 <cprintf>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200b3c:	10843783          	ld	a5,264(s0)
ffffffffc0200b40:	0791                	addi	a5,a5,4
ffffffffc0200b42:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
ffffffffc0200b48:	6402                	ld	s0,0(sp)
ffffffffc0200b4a:	0141                	addi	sp,sp,16
ffffffffc0200b4c:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b4e:	17f1                	addi	a5,a5,-4
ffffffffc0200b50:	471d                	li	a4,7
ffffffffc0200b52:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b46 <exception_handler+0x44>
}
ffffffffc0200b56:	6402                	ld	s0,0(sp)
ffffffffc0200b58:	60a2                	ld	ra,8(sp)
ffffffffc0200b5a:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b5c:	b559                	j	ffffffffc02009e2 <print_trapframe>
            cprintf("eBreak caught at 0x%08x, epc = 0x%lx\n", tf->epc, tf->epc); // (1)
ffffffffc0200b5e:	10843603          	ld	a2,264(s0)
ffffffffc0200b62:	00002517          	auipc	a0,0x2
ffffffffc0200b66:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202780 <etext+0x890>
ffffffffc0200b6a:	85b2                	mv	a1,a2
ffffffffc0200b6c:	d6cff0ef          	jal	ffffffffc02000d8 <cprintf>
            cprintf("Exception type:Breakpoint\n"); // (2)
ffffffffc0200b70:	00002517          	auipc	a0,0x2
ffffffffc0200b74:	c3850513          	addi	a0,a0,-968 # ffffffffc02027a8 <etext+0x8b8>
ffffffffc0200b78:	d60ff0ef          	jal	ffffffffc02000d8 <cprintf>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200b7c:	10843783          	ld	a5,264(s0)
}
ffffffffc0200b80:	60a2                	ld	ra,8(sp)
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200b82:	0791                	addi	a5,a5,4
ffffffffc0200b84:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200b88:	6402                	ld	s0,0(sp)
ffffffffc0200b8a:	0141                	addi	sp,sp,16
ffffffffc0200b8c:	8082                	ret

ffffffffc0200b8e <trap>:


static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b8e:	11853783          	ld	a5,280(a0)
ffffffffc0200b92:	0007c363          	bltz	a5,ffffffffc0200b98 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b96:	b7b5                	j	ffffffffc0200b02 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b98:	b575                	j	ffffffffc0200a44 <interrupt_handler>
	...

ffffffffc0200b9c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b9c:	14011073          	csrw	sscratch,sp
ffffffffc0200ba0:	712d                	addi	sp,sp,-288
ffffffffc0200ba2:	e002                	sd	zero,0(sp)
ffffffffc0200ba4:	e406                	sd	ra,8(sp)
ffffffffc0200ba6:	ec0e                	sd	gp,24(sp)
ffffffffc0200ba8:	f012                	sd	tp,32(sp)
ffffffffc0200baa:	f416                	sd	t0,40(sp)
ffffffffc0200bac:	f81a                	sd	t1,48(sp)
ffffffffc0200bae:	fc1e                	sd	t2,56(sp)
ffffffffc0200bb0:	e0a2                	sd	s0,64(sp)
ffffffffc0200bb2:	e4a6                	sd	s1,72(sp)
ffffffffc0200bb4:	e8aa                	sd	a0,80(sp)
ffffffffc0200bb6:	ecae                	sd	a1,88(sp)
ffffffffc0200bb8:	f0b2                	sd	a2,96(sp)
ffffffffc0200bba:	f4b6                	sd	a3,104(sp)
ffffffffc0200bbc:	f8ba                	sd	a4,112(sp)
ffffffffc0200bbe:	fcbe                	sd	a5,120(sp)
ffffffffc0200bc0:	e142                	sd	a6,128(sp)
ffffffffc0200bc2:	e546                	sd	a7,136(sp)
ffffffffc0200bc4:	e94a                	sd	s2,144(sp)
ffffffffc0200bc6:	ed4e                	sd	s3,152(sp)
ffffffffc0200bc8:	f152                	sd	s4,160(sp)
ffffffffc0200bca:	f556                	sd	s5,168(sp)
ffffffffc0200bcc:	f95a                	sd	s6,176(sp)
ffffffffc0200bce:	fd5e                	sd	s7,184(sp)
ffffffffc0200bd0:	e1e2                	sd	s8,192(sp)
ffffffffc0200bd2:	e5e6                	sd	s9,200(sp)
ffffffffc0200bd4:	e9ea                	sd	s10,208(sp)
ffffffffc0200bd6:	edee                	sd	s11,216(sp)
ffffffffc0200bd8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bda:	f5f6                	sd	t4,232(sp)
ffffffffc0200bdc:	f9fa                	sd	t5,240(sp)
ffffffffc0200bde:	fdfe                	sd	t6,248(sp)
ffffffffc0200be0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200be4:	100024f3          	csrr	s1,sstatus
ffffffffc0200be8:	14102973          	csrr	s2,sepc
ffffffffc0200bec:	143029f3          	csrr	s3,stval
ffffffffc0200bf0:	14202a73          	csrr	s4,scause
ffffffffc0200bf4:	e822                	sd	s0,16(sp)
ffffffffc0200bf6:	e226                	sd	s1,256(sp)
ffffffffc0200bf8:	e64a                	sd	s2,264(sp)
ffffffffc0200bfa:	ea4e                	sd	s3,272(sp)
ffffffffc0200bfc:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bfe:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c00:	f8fff0ef          	jal	ffffffffc0200b8e <trap>

ffffffffc0200c04 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c04:	6492                	ld	s1,256(sp)
ffffffffc0200c06:	6932                	ld	s2,264(sp)
ffffffffc0200c08:	10049073          	csrw	sstatus,s1
ffffffffc0200c0c:	14191073          	csrw	sepc,s2
ffffffffc0200c10:	60a2                	ld	ra,8(sp)
ffffffffc0200c12:	61e2                	ld	gp,24(sp)
ffffffffc0200c14:	7202                	ld	tp,32(sp)
ffffffffc0200c16:	72a2                	ld	t0,40(sp)
ffffffffc0200c18:	7342                	ld	t1,48(sp)
ffffffffc0200c1a:	73e2                	ld	t2,56(sp)
ffffffffc0200c1c:	6406                	ld	s0,64(sp)
ffffffffc0200c1e:	64a6                	ld	s1,72(sp)
ffffffffc0200c20:	6546                	ld	a0,80(sp)
ffffffffc0200c22:	65e6                	ld	a1,88(sp)
ffffffffc0200c24:	7606                	ld	a2,96(sp)
ffffffffc0200c26:	76a6                	ld	a3,104(sp)
ffffffffc0200c28:	7746                	ld	a4,112(sp)
ffffffffc0200c2a:	77e6                	ld	a5,120(sp)
ffffffffc0200c2c:	680a                	ld	a6,128(sp)
ffffffffc0200c2e:	68aa                	ld	a7,136(sp)
ffffffffc0200c30:	694a                	ld	s2,144(sp)
ffffffffc0200c32:	69ea                	ld	s3,152(sp)
ffffffffc0200c34:	7a0a                	ld	s4,160(sp)
ffffffffc0200c36:	7aaa                	ld	s5,168(sp)
ffffffffc0200c38:	7b4a                	ld	s6,176(sp)
ffffffffc0200c3a:	7bea                	ld	s7,184(sp)
ffffffffc0200c3c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c3e:	6cae                	ld	s9,200(sp)
ffffffffc0200c40:	6d4e                	ld	s10,208(sp)
ffffffffc0200c42:	6dee                	ld	s11,216(sp)
ffffffffc0200c44:	7e0e                	ld	t3,224(sp)
ffffffffc0200c46:	7eae                	ld	t4,232(sp)
ffffffffc0200c48:	7f4e                	ld	t5,240(sp)
ffffffffc0200c4a:	7fee                	ld	t6,248(sp)
ffffffffc0200c4c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c4e:	10200073          	sret

ffffffffc0200c52 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c52:	00005797          	auipc	a5,0x5
ffffffffc0200c56:	3d678793          	addi	a5,a5,982 # ffffffffc0206028 <free_area>
ffffffffc0200c5a:	e79c                	sd	a5,8(a5)
ffffffffc0200c5c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c5e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c62:	8082                	ret

ffffffffc0200c64 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c64:	00005517          	auipc	a0,0x5
ffffffffc0200c68:	3d456503          	lwu	a0,980(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200c6c:	8082                	ret

ffffffffc0200c6e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200c6e:	c14d                	beqz	a0,ffffffffc0200d10 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200c70:	00005617          	auipc	a2,0x5
ffffffffc0200c74:	3b860613          	addi	a2,a2,952 # ffffffffc0206028 <free_area>
ffffffffc0200c78:	01062803          	lw	a6,16(a2)
ffffffffc0200c7c:	86aa                	mv	a3,a0
ffffffffc0200c7e:	02081793          	slli	a5,a6,0x20
ffffffffc0200c82:	9381                	srli	a5,a5,0x20
ffffffffc0200c84:	08a7e463          	bltu	a5,a0,ffffffffc0200d0c <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c88:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200c8a:	0018059b          	addiw	a1,a6,1
ffffffffc0200c8e:	1582                	slli	a1,a1,0x20
ffffffffc0200c90:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200c92:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c94:	06c78b63          	beq	a5,a2,ffffffffc0200d0a <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200c98:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200c9c:	00d76763          	bltu	a4,a3,ffffffffc0200caa <best_fit_alloc_pages+0x3c>
ffffffffc0200ca0:	00b77563          	bgeu	a4,a1,ffffffffc0200caa <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200ca4:	fe878513          	addi	a0,a5,-24
            min_size = p->property;
ffffffffc0200ca8:	85ba                	mv	a1,a4
ffffffffc0200caa:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cac:	fec796e3          	bne	a5,a2,ffffffffc0200c98 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200cb0:	cd29                	beqz	a0,ffffffffc0200d0a <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200cb2:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200cb4:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200cb6:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200cb8:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200cbc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200cbe:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200cc0:	02059793          	slli	a5,a1,0x20
ffffffffc0200cc4:	9381                	srli	a5,a5,0x20
ffffffffc0200cc6:	02f6f863          	bgeu	a3,a5,ffffffffc0200cf6 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200cca:	00269793          	slli	a5,a3,0x2
ffffffffc0200cce:	97b6                	add	a5,a5,a3
ffffffffc0200cd0:	078e                	slli	a5,a5,0x3
ffffffffc0200cd2:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200cd4:	411585bb          	subw	a1,a1,a7
ffffffffc0200cd8:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200cda:	4689                	li	a3,2
ffffffffc0200cdc:	00878593          	addi	a1,a5,8
ffffffffc0200ce0:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200ce4:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200ce6:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200cea:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200cee:	e28c                	sd	a1,0(a3)
ffffffffc0200cf0:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200cf2:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200cf4:	ef98                	sd	a4,24(a5)
ffffffffc0200cf6:	4118083b          	subw	a6,a6,a7
ffffffffc0200cfa:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200cfe:	57f5                	li	a5,-3
ffffffffc0200d00:	00850713          	addi	a4,a0,8
ffffffffc0200d04:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200d08:	8082                	ret
}
ffffffffc0200d0a:	8082                	ret
        return NULL;
ffffffffc0200d0c:	4501                	li	a0,0
ffffffffc0200d0e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200d10:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200d12:	00002697          	auipc	a3,0x2
ffffffffc0200d16:	ab668693          	addi	a3,a3,-1354 # ffffffffc02027c8 <etext+0x8d8>
ffffffffc0200d1a:	00002617          	auipc	a2,0x2
ffffffffc0200d1e:	ab660613          	addi	a2,a2,-1354 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0200d22:	06b00593          	li	a1,107
ffffffffc0200d26:	00002517          	auipc	a0,0x2
ffffffffc0200d2a:	ac250513          	addi	a0,a0,-1342 # ffffffffc02027e8 <etext+0x8f8>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d2e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d30:	e9cff0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0200d34 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200d34:	715d                	addi	sp,sp,-80
ffffffffc0200d36:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200d38:	00005417          	auipc	s0,0x5
ffffffffc0200d3c:	2f040413          	addi	s0,s0,752 # ffffffffc0206028 <free_area>
ffffffffc0200d40:	641c                	ld	a5,8(s0)
ffffffffc0200d42:	e486                	sd	ra,72(sp)
ffffffffc0200d44:	fc26                	sd	s1,56(sp)
ffffffffc0200d46:	f84a                	sd	s2,48(sp)
ffffffffc0200d48:	f44e                	sd	s3,40(sp)
ffffffffc0200d4a:	f052                	sd	s4,32(sp)
ffffffffc0200d4c:	ec56                	sd	s5,24(sp)
ffffffffc0200d4e:	e85a                	sd	s6,16(sp)
ffffffffc0200d50:	e45e                	sd	s7,8(sp)
ffffffffc0200d52:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d54:	28878463          	beq	a5,s0,ffffffffc0200fdc <best_fit_check+0x2a8>
    int count = 0, total = 0;
ffffffffc0200d58:	4481                	li	s1,0
ffffffffc0200d5a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d5c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d60:	8b09                	andi	a4,a4,2
ffffffffc0200d62:	28070163          	beqz	a4,ffffffffc0200fe4 <best_fit_check+0x2b0>
        count ++, total += p->property;
ffffffffc0200d66:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d6a:	679c                	ld	a5,8(a5)
ffffffffc0200d6c:	2905                	addiw	s2,s2,1
ffffffffc0200d6e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d70:	fe8796e3          	bne	a5,s0,ffffffffc0200d5c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200d74:	89a6                	mv	s3,s1
ffffffffc0200d76:	179000ef          	jal	ffffffffc02016ee <nr_free_pages>
ffffffffc0200d7a:	35351563          	bne	a0,s3,ffffffffc02010c4 <best_fit_check+0x390>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d7e:	4505                	li	a0,1
ffffffffc0200d80:	0f1000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200d84:	8a2a                	mv	s4,a0
ffffffffc0200d86:	36050f63          	beqz	a0,ffffffffc0201104 <best_fit_check+0x3d0>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d8a:	4505                	li	a0,1
ffffffffc0200d8c:	0e5000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200d90:	89aa                	mv	s3,a0
ffffffffc0200d92:	34050963          	beqz	a0,ffffffffc02010e4 <best_fit_check+0x3b0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d96:	4505                	li	a0,1
ffffffffc0200d98:	0d9000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200d9c:	8aaa                	mv	s5,a0
ffffffffc0200d9e:	2e050363          	beqz	a0,ffffffffc0201084 <best_fit_check+0x350>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200da2:	273a0163          	beq	s4,s3,ffffffffc0201004 <best_fit_check+0x2d0>
ffffffffc0200da6:	24aa0f63          	beq	s4,a0,ffffffffc0201004 <best_fit_check+0x2d0>
ffffffffc0200daa:	24a98d63          	beq	s3,a0,ffffffffc0201004 <best_fit_check+0x2d0>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dae:	000a2783          	lw	a5,0(s4)
ffffffffc0200db2:	26079963          	bnez	a5,ffffffffc0201024 <best_fit_check+0x2f0>
ffffffffc0200db6:	0009a783          	lw	a5,0(s3)
ffffffffc0200dba:	26079563          	bnez	a5,ffffffffc0201024 <best_fit_check+0x2f0>
ffffffffc0200dbe:	411c                	lw	a5,0(a0)
ffffffffc0200dc0:	26079263          	bnez	a5,ffffffffc0201024 <best_fit_check+0x2f0>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dc4:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200dc8:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac682d>
ffffffffc0200dcc:	07b2                	slli	a5,a5,0xc
ffffffffc0200dce:	ccd78793          	addi	a5,a5,-819
ffffffffc0200dd2:	07b2                	slli	a5,a5,0xc
ffffffffc0200dd4:	00005717          	auipc	a4,0x5
ffffffffc0200dd8:	6bc73703          	ld	a4,1724(a4) # ffffffffc0206490 <pages>
ffffffffc0200ddc:	ccd78793          	addi	a5,a5,-819
ffffffffc0200de0:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200de4:	07b2                	slli	a5,a5,0xc
ffffffffc0200de6:	868d                	srai	a3,a3,0x3
ffffffffc0200de8:	ccd78793          	addi	a5,a5,-819
ffffffffc0200dec:	02f686b3          	mul	a3,a3,a5
ffffffffc0200df0:	00002597          	auipc	a1,0x2
ffffffffc0200df4:	1605b583          	ld	a1,352(a1) # ffffffffc0202f50 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200df8:	00005617          	auipc	a2,0x5
ffffffffc0200dfc:	69063603          	ld	a2,1680(a2) # ffffffffc0206488 <npage>
ffffffffc0200e00:	0632                	slli	a2,a2,0xc
ffffffffc0200e02:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e04:	06b2                	slli	a3,a3,0xc
ffffffffc0200e06:	22c6ff63          	bgeu	a3,a2,ffffffffc0201044 <best_fit_check+0x310>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e0a:	40e986b3          	sub	a3,s3,a4
ffffffffc0200e0e:	868d                	srai	a3,a3,0x3
ffffffffc0200e10:	02f686b3          	mul	a3,a3,a5
ffffffffc0200e14:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e16:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e18:	3ec6f663          	bgeu	a3,a2,ffffffffc0201204 <best_fit_check+0x4d0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e1c:	40e50733          	sub	a4,a0,a4
ffffffffc0200e20:	870d                	srai	a4,a4,0x3
ffffffffc0200e22:	02f707b3          	mul	a5,a4,a5
ffffffffc0200e26:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e28:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e2a:	3ac7fd63          	bgeu	a5,a2,ffffffffc02011e4 <best_fit_check+0x4b0>
    assert(alloc_page() == NULL);
ffffffffc0200e2e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e30:	00043c03          	ld	s8,0(s0)
ffffffffc0200e34:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e38:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e3c:	e400                	sd	s0,8(s0)
ffffffffc0200e3e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e40:	00005797          	auipc	a5,0x5
ffffffffc0200e44:	1e07ac23          	sw	zero,504(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e48:	029000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200e4c:	36051c63          	bnez	a0,ffffffffc02011c4 <best_fit_check+0x490>
    free_page(p0);
ffffffffc0200e50:	4585                	li	a1,1
ffffffffc0200e52:	8552                	mv	a0,s4
ffffffffc0200e54:	05b000ef          	jal	ffffffffc02016ae <free_pages>
    free_page(p1);
ffffffffc0200e58:	4585                	li	a1,1
ffffffffc0200e5a:	854e                	mv	a0,s3
ffffffffc0200e5c:	053000ef          	jal	ffffffffc02016ae <free_pages>
    free_page(p2);
ffffffffc0200e60:	4585                	li	a1,1
ffffffffc0200e62:	8556                	mv	a0,s5
ffffffffc0200e64:	04b000ef          	jal	ffffffffc02016ae <free_pages>
    assert(nr_free == 3);
ffffffffc0200e68:	4818                	lw	a4,16(s0)
ffffffffc0200e6a:	478d                	li	a5,3
ffffffffc0200e6c:	32f71c63          	bne	a4,a5,ffffffffc02011a4 <best_fit_check+0x470>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e70:	4505                	li	a0,1
ffffffffc0200e72:	7fe000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200e76:	89aa                	mv	s3,a0
ffffffffc0200e78:	30050663          	beqz	a0,ffffffffc0201184 <best_fit_check+0x450>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e7c:	4505                	li	a0,1
ffffffffc0200e7e:	7f2000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200e82:	8aaa                	mv	s5,a0
ffffffffc0200e84:	2e050063          	beqz	a0,ffffffffc0201164 <best_fit_check+0x430>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e88:	4505                	li	a0,1
ffffffffc0200e8a:	7e6000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200e8e:	8a2a                	mv	s4,a0
ffffffffc0200e90:	2a050a63          	beqz	a0,ffffffffc0201144 <best_fit_check+0x410>
    assert(alloc_page() == NULL);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	7da000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200e9a:	28051563          	bnez	a0,ffffffffc0201124 <best_fit_check+0x3f0>
    free_page(p0);
ffffffffc0200e9e:	4585                	li	a1,1
ffffffffc0200ea0:	854e                	mv	a0,s3
ffffffffc0200ea2:	00d000ef          	jal	ffffffffc02016ae <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ea6:	641c                	ld	a5,8(s0)
ffffffffc0200ea8:	1a878e63          	beq	a5,s0,ffffffffc0201064 <best_fit_check+0x330>
    assert((p = alloc_page()) == p0);
ffffffffc0200eac:	4505                	li	a0,1
ffffffffc0200eae:	7c2000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200eb2:	52a99963          	bne	s3,a0,ffffffffc02013e4 <best_fit_check+0x6b0>
    assert(alloc_page() == NULL);
ffffffffc0200eb6:	4505                	li	a0,1
ffffffffc0200eb8:	7b8000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200ebc:	50051463          	bnez	a0,ffffffffc02013c4 <best_fit_check+0x690>
    assert(nr_free == 0);
ffffffffc0200ec0:	481c                	lw	a5,16(s0)
ffffffffc0200ec2:	4e079163          	bnez	a5,ffffffffc02013a4 <best_fit_check+0x670>
    free_page(p);
ffffffffc0200ec6:	854e                	mv	a0,s3
ffffffffc0200ec8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200eca:	01843023          	sd	s8,0(s0)
ffffffffc0200ece:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200ed2:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200ed6:	7d8000ef          	jal	ffffffffc02016ae <free_pages>
    free_page(p1);
ffffffffc0200eda:	4585                	li	a1,1
ffffffffc0200edc:	8556                	mv	a0,s5
ffffffffc0200ede:	7d0000ef          	jal	ffffffffc02016ae <free_pages>
    free_page(p2);
ffffffffc0200ee2:	4585                	li	a1,1
ffffffffc0200ee4:	8552                	mv	a0,s4
ffffffffc0200ee6:	7c8000ef          	jal	ffffffffc02016ae <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200eea:	4515                	li	a0,5
ffffffffc0200eec:	784000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200ef0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200ef2:	48050963          	beqz	a0,ffffffffc0201384 <best_fit_check+0x650>
ffffffffc0200ef6:	651c                	ld	a5,8(a0)
ffffffffc0200ef8:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200efa:	8b85                	andi	a5,a5,1
ffffffffc0200efc:	46079463          	bnez	a5,ffffffffc0201364 <best_fit_check+0x630>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f00:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f02:	00043a83          	ld	s5,0(s0)
ffffffffc0200f06:	00843a03          	ld	s4,8(s0)
ffffffffc0200f0a:	e000                	sd	s0,0(s0)
ffffffffc0200f0c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f0e:	762000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200f12:	42051963          	bnez	a0,ffffffffc0201344 <best_fit_check+0x610>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f16:	4589                	li	a1,2
ffffffffc0200f18:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200f1c:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200f20:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200f24:	00005797          	auipc	a5,0x5
ffffffffc0200f28:	1007aa23          	sw	zero,276(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200f2c:	782000ef          	jal	ffffffffc02016ae <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200f30:	8562                	mv	a0,s8
ffffffffc0200f32:	4585                	li	a1,1
ffffffffc0200f34:	77a000ef          	jal	ffffffffc02016ae <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f38:	4511                	li	a0,4
ffffffffc0200f3a:	736000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200f3e:	3e051363          	bnez	a0,ffffffffc0201324 <best_fit_check+0x5f0>
ffffffffc0200f42:	0309b783          	ld	a5,48(s3)
ffffffffc0200f46:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f48:	8b85                	andi	a5,a5,1
ffffffffc0200f4a:	3a078d63          	beqz	a5,ffffffffc0201304 <best_fit_check+0x5d0>
ffffffffc0200f4e:	0389a703          	lw	a4,56(s3)
ffffffffc0200f52:	4789                	li	a5,2
ffffffffc0200f54:	3af71863          	bne	a4,a5,ffffffffc0201304 <best_fit_check+0x5d0>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f58:	4505                	li	a0,1
ffffffffc0200f5a:	716000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200f5e:	8baa                	mv	s7,a0
ffffffffc0200f60:	38050263          	beqz	a0,ffffffffc02012e4 <best_fit_check+0x5b0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f64:	4509                	li	a0,2
ffffffffc0200f66:	70a000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200f6a:	34050d63          	beqz	a0,ffffffffc02012c4 <best_fit_check+0x590>
    assert(p0 + 4 == p1);
ffffffffc0200f6e:	337c1b63          	bne	s8,s7,ffffffffc02012a4 <best_fit_check+0x570>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200f72:	854e                	mv	a0,s3
ffffffffc0200f74:	4595                	li	a1,5
ffffffffc0200f76:	738000ef          	jal	ffffffffc02016ae <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f7a:	4515                	li	a0,5
ffffffffc0200f7c:	6f4000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200f80:	89aa                	mv	s3,a0
ffffffffc0200f82:	30050163          	beqz	a0,ffffffffc0201284 <best_fit_check+0x550>
    assert(alloc_page() == NULL);
ffffffffc0200f86:	4505                	li	a0,1
ffffffffc0200f88:	6e8000ef          	jal	ffffffffc0201670 <alloc_pages>
ffffffffc0200f8c:	2c051c63          	bnez	a0,ffffffffc0201264 <best_fit_check+0x530>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200f90:	481c                	lw	a5,16(s0)
ffffffffc0200f92:	2a079963          	bnez	a5,ffffffffc0201244 <best_fit_check+0x510>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f96:	4595                	li	a1,5
ffffffffc0200f98:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f9a:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200f9e:	01543023          	sd	s5,0(s0)
ffffffffc0200fa2:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200fa6:	708000ef          	jal	ffffffffc02016ae <free_pages>
    return listelm->next;
ffffffffc0200faa:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fac:	00878963          	beq	a5,s0,ffffffffc0200fbe <best_fit_check+0x28a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fb0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fb4:	679c                	ld	a5,8(a5)
ffffffffc0200fb6:	397d                	addiw	s2,s2,-1
ffffffffc0200fb8:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fba:	fe879be3          	bne	a5,s0,ffffffffc0200fb0 <best_fit_check+0x27c>
    }
    assert(count == 0);
ffffffffc0200fbe:	26091363          	bnez	s2,ffffffffc0201224 <best_fit_check+0x4f0>
    assert(total == 0);
ffffffffc0200fc2:	e0ed                	bnez	s1,ffffffffc02010a4 <best_fit_check+0x370>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200fc4:	60a6                	ld	ra,72(sp)
ffffffffc0200fc6:	6406                	ld	s0,64(sp)
ffffffffc0200fc8:	74e2                	ld	s1,56(sp)
ffffffffc0200fca:	7942                	ld	s2,48(sp)
ffffffffc0200fcc:	79a2                	ld	s3,40(sp)
ffffffffc0200fce:	7a02                	ld	s4,32(sp)
ffffffffc0200fd0:	6ae2                	ld	s5,24(sp)
ffffffffc0200fd2:	6b42                	ld	s6,16(sp)
ffffffffc0200fd4:	6ba2                	ld	s7,8(sp)
ffffffffc0200fd6:	6c02                	ld	s8,0(sp)
ffffffffc0200fd8:	6161                	addi	sp,sp,80
ffffffffc0200fda:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fdc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200fde:	4481                	li	s1,0
ffffffffc0200fe0:	4901                	li	s2,0
ffffffffc0200fe2:	bb51                	j	ffffffffc0200d76 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200fe4:	00002697          	auipc	a3,0x2
ffffffffc0200fe8:	81c68693          	addi	a3,a3,-2020 # ffffffffc0202800 <etext+0x910>
ffffffffc0200fec:	00001617          	auipc	a2,0x1
ffffffffc0200ff0:	7e460613          	addi	a2,a2,2020 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0200ff4:	10d00593          	li	a1,269
ffffffffc0200ff8:	00001517          	auipc	a0,0x1
ffffffffc0200ffc:	7f050513          	addi	a0,a0,2032 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201000:	bccff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201004:	00002697          	auipc	a3,0x2
ffffffffc0201008:	88c68693          	addi	a3,a3,-1908 # ffffffffc0202890 <etext+0x9a0>
ffffffffc020100c:	00001617          	auipc	a2,0x1
ffffffffc0201010:	7c460613          	addi	a2,a2,1988 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201014:	0d900593          	li	a1,217
ffffffffc0201018:	00001517          	auipc	a0,0x1
ffffffffc020101c:	7d050513          	addi	a0,a0,2000 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201020:	bacff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201024:	00002697          	auipc	a3,0x2
ffffffffc0201028:	89468693          	addi	a3,a3,-1900 # ffffffffc02028b8 <etext+0x9c8>
ffffffffc020102c:	00001617          	auipc	a2,0x1
ffffffffc0201030:	7a460613          	addi	a2,a2,1956 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201034:	0da00593          	li	a1,218
ffffffffc0201038:	00001517          	auipc	a0,0x1
ffffffffc020103c:	7b050513          	addi	a0,a0,1968 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201040:	b8cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201044:	00002697          	auipc	a3,0x2
ffffffffc0201048:	8b468693          	addi	a3,a3,-1868 # ffffffffc02028f8 <etext+0xa08>
ffffffffc020104c:	00001617          	auipc	a2,0x1
ffffffffc0201050:	78460613          	addi	a2,a2,1924 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201054:	0dc00593          	li	a1,220
ffffffffc0201058:	00001517          	auipc	a0,0x1
ffffffffc020105c:	79050513          	addi	a0,a0,1936 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201060:	b6cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201064:	00002697          	auipc	a3,0x2
ffffffffc0201068:	91c68693          	addi	a3,a3,-1764 # ffffffffc0202980 <etext+0xa90>
ffffffffc020106c:	00001617          	auipc	a2,0x1
ffffffffc0201070:	76460613          	addi	a2,a2,1892 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201074:	0f500593          	li	a1,245
ffffffffc0201078:	00001517          	auipc	a0,0x1
ffffffffc020107c:	77050513          	addi	a0,a0,1904 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201080:	b4cff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201084:	00001697          	auipc	a3,0x1
ffffffffc0201088:	7ec68693          	addi	a3,a3,2028 # ffffffffc0202870 <etext+0x980>
ffffffffc020108c:	00001617          	auipc	a2,0x1
ffffffffc0201090:	74460613          	addi	a2,a2,1860 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201094:	0d700593          	li	a1,215
ffffffffc0201098:	00001517          	auipc	a0,0x1
ffffffffc020109c:	75050513          	addi	a0,a0,1872 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02010a0:	b2cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(total == 0);
ffffffffc02010a4:	00002697          	auipc	a3,0x2
ffffffffc02010a8:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0202ab0 <etext+0xbc0>
ffffffffc02010ac:	00001617          	auipc	a2,0x1
ffffffffc02010b0:	72460613          	addi	a2,a2,1828 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02010b4:	14f00593          	li	a1,335
ffffffffc02010b8:	00001517          	auipc	a0,0x1
ffffffffc02010bc:	73050513          	addi	a0,a0,1840 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02010c0:	b0cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(total == nr_free_pages());
ffffffffc02010c4:	00001697          	auipc	a3,0x1
ffffffffc02010c8:	74c68693          	addi	a3,a3,1868 # ffffffffc0202810 <etext+0x920>
ffffffffc02010cc:	00001617          	auipc	a2,0x1
ffffffffc02010d0:	70460613          	addi	a2,a2,1796 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02010d4:	11000593          	li	a1,272
ffffffffc02010d8:	00001517          	auipc	a0,0x1
ffffffffc02010dc:	71050513          	addi	a0,a0,1808 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02010e0:	aecff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010e4:	00001697          	auipc	a3,0x1
ffffffffc02010e8:	76c68693          	addi	a3,a3,1900 # ffffffffc0202850 <etext+0x960>
ffffffffc02010ec:	00001617          	auipc	a2,0x1
ffffffffc02010f0:	6e460613          	addi	a2,a2,1764 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02010f4:	0d600593          	li	a1,214
ffffffffc02010f8:	00001517          	auipc	a0,0x1
ffffffffc02010fc:	6f050513          	addi	a0,a0,1776 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201100:	accff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201104:	00001697          	auipc	a3,0x1
ffffffffc0201108:	72c68693          	addi	a3,a3,1836 # ffffffffc0202830 <etext+0x940>
ffffffffc020110c:	00001617          	auipc	a2,0x1
ffffffffc0201110:	6c460613          	addi	a2,a2,1732 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201114:	0d500593          	li	a1,213
ffffffffc0201118:	00001517          	auipc	a0,0x1
ffffffffc020111c:	6d050513          	addi	a0,a0,1744 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201120:	aacff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201124:	00002697          	auipc	a3,0x2
ffffffffc0201128:	83468693          	addi	a3,a3,-1996 # ffffffffc0202958 <etext+0xa68>
ffffffffc020112c:	00001617          	auipc	a2,0x1
ffffffffc0201130:	6a460613          	addi	a2,a2,1700 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201134:	0f200593          	li	a1,242
ffffffffc0201138:	00001517          	auipc	a0,0x1
ffffffffc020113c:	6b050513          	addi	a0,a0,1712 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201140:	a8cff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201144:	00001697          	auipc	a3,0x1
ffffffffc0201148:	72c68693          	addi	a3,a3,1836 # ffffffffc0202870 <etext+0x980>
ffffffffc020114c:	00001617          	auipc	a2,0x1
ffffffffc0201150:	68460613          	addi	a2,a2,1668 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201154:	0f000593          	li	a1,240
ffffffffc0201158:	00001517          	auipc	a0,0x1
ffffffffc020115c:	69050513          	addi	a0,a0,1680 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201160:	a6cff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201164:	00001697          	auipc	a3,0x1
ffffffffc0201168:	6ec68693          	addi	a3,a3,1772 # ffffffffc0202850 <etext+0x960>
ffffffffc020116c:	00001617          	auipc	a2,0x1
ffffffffc0201170:	66460613          	addi	a2,a2,1636 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201174:	0ef00593          	li	a1,239
ffffffffc0201178:	00001517          	auipc	a0,0x1
ffffffffc020117c:	67050513          	addi	a0,a0,1648 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201180:	a4cff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201184:	00001697          	auipc	a3,0x1
ffffffffc0201188:	6ac68693          	addi	a3,a3,1708 # ffffffffc0202830 <etext+0x940>
ffffffffc020118c:	00001617          	auipc	a2,0x1
ffffffffc0201190:	64460613          	addi	a2,a2,1604 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201194:	0ee00593          	li	a1,238
ffffffffc0201198:	00001517          	auipc	a0,0x1
ffffffffc020119c:	65050513          	addi	a0,a0,1616 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02011a0:	a2cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 3);
ffffffffc02011a4:	00001697          	auipc	a3,0x1
ffffffffc02011a8:	7cc68693          	addi	a3,a3,1996 # ffffffffc0202970 <etext+0xa80>
ffffffffc02011ac:	00001617          	auipc	a2,0x1
ffffffffc02011b0:	62460613          	addi	a2,a2,1572 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02011b4:	0ec00593          	li	a1,236
ffffffffc02011b8:	00001517          	auipc	a0,0x1
ffffffffc02011bc:	63050513          	addi	a0,a0,1584 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02011c0:	a0cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c4:	00001697          	auipc	a3,0x1
ffffffffc02011c8:	79468693          	addi	a3,a3,1940 # ffffffffc0202958 <etext+0xa68>
ffffffffc02011cc:	00001617          	auipc	a2,0x1
ffffffffc02011d0:	60460613          	addi	a2,a2,1540 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02011d4:	0e700593          	li	a1,231
ffffffffc02011d8:	00001517          	auipc	a0,0x1
ffffffffc02011dc:	61050513          	addi	a0,a0,1552 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02011e0:	9ecff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011e4:	00001697          	auipc	a3,0x1
ffffffffc02011e8:	75468693          	addi	a3,a3,1876 # ffffffffc0202938 <etext+0xa48>
ffffffffc02011ec:	00001617          	auipc	a2,0x1
ffffffffc02011f0:	5e460613          	addi	a2,a2,1508 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02011f4:	0de00593          	li	a1,222
ffffffffc02011f8:	00001517          	auipc	a0,0x1
ffffffffc02011fc:	5f050513          	addi	a0,a0,1520 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201200:	9ccff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201204:	00001697          	auipc	a3,0x1
ffffffffc0201208:	71468693          	addi	a3,a3,1812 # ffffffffc0202918 <etext+0xa28>
ffffffffc020120c:	00001617          	auipc	a2,0x1
ffffffffc0201210:	5c460613          	addi	a2,a2,1476 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201214:	0dd00593          	li	a1,221
ffffffffc0201218:	00001517          	auipc	a0,0x1
ffffffffc020121c:	5d050513          	addi	a0,a0,1488 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201220:	9acff0ef          	jal	ffffffffc02003cc <__panic>
    assert(count == 0);
ffffffffc0201224:	00002697          	auipc	a3,0x2
ffffffffc0201228:	87c68693          	addi	a3,a3,-1924 # ffffffffc0202aa0 <etext+0xbb0>
ffffffffc020122c:	00001617          	auipc	a2,0x1
ffffffffc0201230:	5a460613          	addi	a2,a2,1444 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201234:	14e00593          	li	a1,334
ffffffffc0201238:	00001517          	auipc	a0,0x1
ffffffffc020123c:	5b050513          	addi	a0,a0,1456 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201240:	98cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 0);
ffffffffc0201244:	00001697          	auipc	a3,0x1
ffffffffc0201248:	77468693          	addi	a3,a3,1908 # ffffffffc02029b8 <etext+0xac8>
ffffffffc020124c:	00001617          	auipc	a2,0x1
ffffffffc0201250:	58460613          	addi	a2,a2,1412 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201254:	14300593          	li	a1,323
ffffffffc0201258:	00001517          	auipc	a0,0x1
ffffffffc020125c:	59050513          	addi	a0,a0,1424 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201260:	96cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201264:	00001697          	auipc	a3,0x1
ffffffffc0201268:	6f468693          	addi	a3,a3,1780 # ffffffffc0202958 <etext+0xa68>
ffffffffc020126c:	00001617          	auipc	a2,0x1
ffffffffc0201270:	56460613          	addi	a2,a2,1380 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201274:	13d00593          	li	a1,317
ffffffffc0201278:	00001517          	auipc	a0,0x1
ffffffffc020127c:	57050513          	addi	a0,a0,1392 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201280:	94cff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201284:	00001697          	auipc	a3,0x1
ffffffffc0201288:	7fc68693          	addi	a3,a3,2044 # ffffffffc0202a80 <etext+0xb90>
ffffffffc020128c:	00001617          	auipc	a2,0x1
ffffffffc0201290:	54460613          	addi	a2,a2,1348 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201294:	13c00593          	li	a1,316
ffffffffc0201298:	00001517          	auipc	a0,0x1
ffffffffc020129c:	55050513          	addi	a0,a0,1360 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02012a0:	92cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 + 4 == p1);
ffffffffc02012a4:	00001697          	auipc	a3,0x1
ffffffffc02012a8:	7cc68693          	addi	a3,a3,1996 # ffffffffc0202a70 <etext+0xb80>
ffffffffc02012ac:	00001617          	auipc	a2,0x1
ffffffffc02012b0:	52460613          	addi	a2,a2,1316 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02012b4:	13400593          	li	a1,308
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	53050513          	addi	a0,a0,1328 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02012c0:	90cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02012c4:	00001697          	auipc	a3,0x1
ffffffffc02012c8:	79468693          	addi	a3,a3,1940 # ffffffffc0202a58 <etext+0xb68>
ffffffffc02012cc:	00001617          	auipc	a2,0x1
ffffffffc02012d0:	50460613          	addi	a2,a2,1284 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02012d4:	13300593          	li	a1,307
ffffffffc02012d8:	00001517          	auipc	a0,0x1
ffffffffc02012dc:	51050513          	addi	a0,a0,1296 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02012e0:	8ecff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02012e4:	00001697          	auipc	a3,0x1
ffffffffc02012e8:	75468693          	addi	a3,a3,1876 # ffffffffc0202a38 <etext+0xb48>
ffffffffc02012ec:	00001617          	auipc	a2,0x1
ffffffffc02012f0:	4e460613          	addi	a2,a2,1252 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02012f4:	13200593          	li	a1,306
ffffffffc02012f8:	00001517          	auipc	a0,0x1
ffffffffc02012fc:	4f050513          	addi	a0,a0,1264 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201300:	8ccff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201304:	00001697          	auipc	a3,0x1
ffffffffc0201308:	70468693          	addi	a3,a3,1796 # ffffffffc0202a08 <etext+0xb18>
ffffffffc020130c:	00001617          	auipc	a2,0x1
ffffffffc0201310:	4c460613          	addi	a2,a2,1220 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201314:	13000593          	li	a1,304
ffffffffc0201318:	00001517          	auipc	a0,0x1
ffffffffc020131c:	4d050513          	addi	a0,a0,1232 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201320:	8acff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201324:	00001697          	auipc	a3,0x1
ffffffffc0201328:	6cc68693          	addi	a3,a3,1740 # ffffffffc02029f0 <etext+0xb00>
ffffffffc020132c:	00001617          	auipc	a2,0x1
ffffffffc0201330:	4a460613          	addi	a2,a2,1188 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201334:	12f00593          	li	a1,303
ffffffffc0201338:	00001517          	auipc	a0,0x1
ffffffffc020133c:	4b050513          	addi	a0,a0,1200 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201340:	88cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201344:	00001697          	auipc	a3,0x1
ffffffffc0201348:	61468693          	addi	a3,a3,1556 # ffffffffc0202958 <etext+0xa68>
ffffffffc020134c:	00001617          	auipc	a2,0x1
ffffffffc0201350:	48460613          	addi	a2,a2,1156 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201354:	12300593          	li	a1,291
ffffffffc0201358:	00001517          	auipc	a0,0x1
ffffffffc020135c:	49050513          	addi	a0,a0,1168 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201360:	86cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(!PageProperty(p0));
ffffffffc0201364:	00001697          	auipc	a3,0x1
ffffffffc0201368:	67468693          	addi	a3,a3,1652 # ffffffffc02029d8 <etext+0xae8>
ffffffffc020136c:	00001617          	auipc	a2,0x1
ffffffffc0201370:	46460613          	addi	a2,a2,1124 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201374:	11a00593          	li	a1,282
ffffffffc0201378:	00001517          	auipc	a0,0x1
ffffffffc020137c:	47050513          	addi	a0,a0,1136 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201380:	84cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 != NULL);
ffffffffc0201384:	00001697          	auipc	a3,0x1
ffffffffc0201388:	64468693          	addi	a3,a3,1604 # ffffffffc02029c8 <etext+0xad8>
ffffffffc020138c:	00001617          	auipc	a2,0x1
ffffffffc0201390:	44460613          	addi	a2,a2,1092 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201394:	11900593          	li	a1,281
ffffffffc0201398:	00001517          	auipc	a0,0x1
ffffffffc020139c:	45050513          	addi	a0,a0,1104 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02013a0:	82cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 0);
ffffffffc02013a4:	00001697          	auipc	a3,0x1
ffffffffc02013a8:	61468693          	addi	a3,a3,1556 # ffffffffc02029b8 <etext+0xac8>
ffffffffc02013ac:	00001617          	auipc	a2,0x1
ffffffffc02013b0:	42460613          	addi	a2,a2,1060 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02013b4:	0fb00593          	li	a1,251
ffffffffc02013b8:	00001517          	auipc	a0,0x1
ffffffffc02013bc:	43050513          	addi	a0,a0,1072 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02013c0:	80cff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c4:	00001697          	auipc	a3,0x1
ffffffffc02013c8:	59468693          	addi	a3,a3,1428 # ffffffffc0202958 <etext+0xa68>
ffffffffc02013cc:	00001617          	auipc	a2,0x1
ffffffffc02013d0:	40460613          	addi	a2,a2,1028 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02013d4:	0f900593          	li	a1,249
ffffffffc02013d8:	00001517          	auipc	a0,0x1
ffffffffc02013dc:	41050513          	addi	a0,a0,1040 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc02013e0:	fedfe0ef          	jal	ffffffffc02003cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02013e4:	00001697          	auipc	a3,0x1
ffffffffc02013e8:	5b468693          	addi	a3,a3,1460 # ffffffffc0202998 <etext+0xaa8>
ffffffffc02013ec:	00001617          	auipc	a2,0x1
ffffffffc02013f0:	3e460613          	addi	a2,a2,996 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc02013f4:	0f800593          	li	a1,248
ffffffffc02013f8:	00001517          	auipc	a0,0x1
ffffffffc02013fc:	3f050513          	addi	a0,a0,1008 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201400:	fcdfe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0201404 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201404:	1141                	addi	sp,sp,-16
ffffffffc0201406:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201408:	14058a63          	beqz	a1,ffffffffc020155c <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020140c:	00259713          	slli	a4,a1,0x2
ffffffffc0201410:	972e                	add	a4,a4,a1
ffffffffc0201412:	070e                	slli	a4,a4,0x3
ffffffffc0201414:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201418:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020141a:	c30d                	beqz	a4,ffffffffc020143c <best_fit_free_pages+0x38>
ffffffffc020141c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020141e:	8b05                	andi	a4,a4,1
ffffffffc0201420:	10071e63          	bnez	a4,ffffffffc020153c <best_fit_free_pages+0x138>
ffffffffc0201424:	6798                	ld	a4,8(a5)
ffffffffc0201426:	8b09                	andi	a4,a4,2
ffffffffc0201428:	10071a63          	bnez	a4,ffffffffc020153c <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc020142c:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201430:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201434:	02878793          	addi	a5,a5,40
ffffffffc0201438:	fed792e3          	bne	a5,a3,ffffffffc020141c <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc020143c:	2581                	sext.w	a1,a1
ffffffffc020143e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201440:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201444:	4789                	li	a5,2
ffffffffc0201446:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020144a:	00005697          	auipc	a3,0x5
ffffffffc020144e:	bde68693          	addi	a3,a3,-1058 # ffffffffc0206028 <free_area>
ffffffffc0201452:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201454:	669c                	ld	a5,8(a3)
ffffffffc0201456:	9f2d                	addw	a4,a4,a1
ffffffffc0201458:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020145a:	0ad78563          	beq	a5,a3,ffffffffc0201504 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc020145e:	fe878713          	addi	a4,a5,-24
ffffffffc0201462:	4581                	li	a1,0
ffffffffc0201464:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201468:	00e56a63          	bltu	a0,a4,ffffffffc020147c <best_fit_free_pages+0x78>
    return listelm->next;
ffffffffc020146c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020146e:	06d70263          	beq	a4,a3,ffffffffc02014d2 <best_fit_free_pages+0xce>
    struct Page *p = base;
ffffffffc0201472:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201474:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201478:	fee57ae3          	bgeu	a0,a4,ffffffffc020146c <best_fit_free_pages+0x68>
ffffffffc020147c:	c199                	beqz	a1,ffffffffc0201482 <best_fit_free_pages+0x7e>
ffffffffc020147e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201482:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201484:	e390                	sd	a2,0(a5)
ffffffffc0201486:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201488:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020148a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020148c:	02d70063          	beq	a4,a3,ffffffffc02014ac <best_fit_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc0201490:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201494:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201498:	02081613          	slli	a2,a6,0x20
ffffffffc020149c:	9201                	srli	a2,a2,0x20
ffffffffc020149e:	00261793          	slli	a5,a2,0x2
ffffffffc02014a2:	97b2                	add	a5,a5,a2
ffffffffc02014a4:	078e                	slli	a5,a5,0x3
ffffffffc02014a6:	97ae                	add	a5,a5,a1
ffffffffc02014a8:	02f50f63          	beq	a0,a5,ffffffffc02014e6 <best_fit_free_pages+0xe2>
    return listelm->next;
ffffffffc02014ac:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014ae:	00d70f63          	beq	a4,a3,ffffffffc02014cc <best_fit_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc02014b2:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014b4:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014b8:	02059613          	slli	a2,a1,0x20
ffffffffc02014bc:	9201                	srli	a2,a2,0x20
ffffffffc02014be:	00261793          	slli	a5,a2,0x2
ffffffffc02014c2:	97b2                	add	a5,a5,a2
ffffffffc02014c4:	078e                	slli	a5,a5,0x3
ffffffffc02014c6:	97aa                	add	a5,a5,a0
ffffffffc02014c8:	04f68a63          	beq	a3,a5,ffffffffc020151c <best_fit_free_pages+0x118>
}
ffffffffc02014cc:	60a2                	ld	ra,8(sp)
ffffffffc02014ce:	0141                	addi	sp,sp,16
ffffffffc02014d0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014d2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014d4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014d6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014d8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02014da:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014dc:	02d70d63          	beq	a4,a3,ffffffffc0201516 <best_fit_free_pages+0x112>
ffffffffc02014e0:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02014e2:	87ba                	mv	a5,a4
ffffffffc02014e4:	bf41                	j	ffffffffc0201474 <best_fit_free_pages+0x70>
            p->property += base->property;
ffffffffc02014e6:	491c                	lw	a5,16(a0)
ffffffffc02014e8:	010787bb          	addw	a5,a5,a6
ffffffffc02014ec:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014f0:	57f5                	li	a5,-3
ffffffffc02014f2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014f6:	6d10                	ld	a2,24(a0)
ffffffffc02014f8:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014fa:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02014fc:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02014fe:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201500:	e390                	sd	a2,0(a5)
ffffffffc0201502:	b775                	j	ffffffffc02014ae <best_fit_free_pages+0xaa>
}
ffffffffc0201504:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201506:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020150a:	e398                	sd	a4,0(a5)
ffffffffc020150c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020150e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201510:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201512:	0141                	addi	sp,sp,16
ffffffffc0201514:	8082                	ret
ffffffffc0201516:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201518:	873e                	mv	a4,a5
ffffffffc020151a:	bf8d                	j	ffffffffc020148c <best_fit_free_pages+0x88>
            base->property += p->property;
ffffffffc020151c:	ff872783          	lw	a5,-8(a4)
ffffffffc0201520:	ff070693          	addi	a3,a4,-16
ffffffffc0201524:	9fad                	addw	a5,a5,a1
ffffffffc0201526:	c91c                	sw	a5,16(a0)
ffffffffc0201528:	57f5                	li	a5,-3
ffffffffc020152a:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020152e:	6314                	ld	a3,0(a4)
ffffffffc0201530:	671c                	ld	a5,8(a4)
}
ffffffffc0201532:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201534:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201536:	e394                	sd	a3,0(a5)
ffffffffc0201538:	0141                	addi	sp,sp,16
ffffffffc020153a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020153c:	00001697          	auipc	a3,0x1
ffffffffc0201540:	58468693          	addi	a3,a3,1412 # ffffffffc0202ac0 <etext+0xbd0>
ffffffffc0201544:	00001617          	auipc	a2,0x1
ffffffffc0201548:	28c60613          	addi	a2,a2,652 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc020154c:	09300593          	li	a1,147
ffffffffc0201550:	00001517          	auipc	a0,0x1
ffffffffc0201554:	29850513          	addi	a0,a0,664 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201558:	e75fe0ef          	jal	ffffffffc02003cc <__panic>
    assert(n > 0);
ffffffffc020155c:	00001697          	auipc	a3,0x1
ffffffffc0201560:	26c68693          	addi	a3,a3,620 # ffffffffc02027c8 <etext+0x8d8>
ffffffffc0201564:	00001617          	auipc	a2,0x1
ffffffffc0201568:	26c60613          	addi	a2,a2,620 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc020156c:	09000593          	li	a1,144
ffffffffc0201570:	00001517          	auipc	a0,0x1
ffffffffc0201574:	27850513          	addi	a0,a0,632 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc0201578:	e55fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc020157c <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020157c:	1141                	addi	sp,sp,-16
ffffffffc020157e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201580:	c9e1                	beqz	a1,ffffffffc0201650 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201582:	00259713          	slli	a4,a1,0x2
ffffffffc0201586:	972e                	add	a4,a4,a1
ffffffffc0201588:	070e                	slli	a4,a4,0x3
ffffffffc020158a:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020158e:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201590:	cf11                	beqz	a4,ffffffffc02015ac <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201592:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201594:	8b05                	andi	a4,a4,1
ffffffffc0201596:	cf49                	beqz	a4,ffffffffc0201630 <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201598:	0007a823          	sw	zero,16(a5)
ffffffffc020159c:	0007b423          	sd	zero,8(a5)
ffffffffc02015a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015a4:	02878793          	addi	a5,a5,40
ffffffffc02015a8:	fed795e3          	bne	a5,a3,ffffffffc0201592 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02015ac:	2581                	sext.w	a1,a1
ffffffffc02015ae:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015b0:	4789                	li	a5,2
ffffffffc02015b2:	00850713          	addi	a4,a0,8
ffffffffc02015b6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02015ba:	00005697          	auipc	a3,0x5
ffffffffc02015be:	a6e68693          	addi	a3,a3,-1426 # ffffffffc0206028 <free_area>
ffffffffc02015c2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015c4:	669c                	ld	a5,8(a3)
ffffffffc02015c6:	9f2d                	addw	a4,a4,a1
ffffffffc02015c8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ca:	04d78663          	beq	a5,a3,ffffffffc0201616 <best_fit_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc02015ce:	fe878713          	addi	a4,a5,-24
ffffffffc02015d2:	4581                	li	a1,0
ffffffffc02015d4:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02015d8:	00e56a63          	bltu	a0,a4,ffffffffc02015ec <best_fit_init_memmap+0x70>
    return listelm->next;
ffffffffc02015dc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015de:	02d70263          	beq	a4,a3,ffffffffc0201602 <best_fit_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02015e2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015e4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015e8:	fee57ae3          	bgeu	a0,a4,ffffffffc02015dc <best_fit_init_memmap+0x60>
ffffffffc02015ec:	c199                	beqz	a1,ffffffffc02015f2 <best_fit_init_memmap+0x76>
ffffffffc02015ee:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015f2:	6398                	ld	a4,0(a5)
}
ffffffffc02015f4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015f6:	e390                	sd	a2,0(a5)
ffffffffc02015f8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015fa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015fc:	ed18                	sd	a4,24(a0)
ffffffffc02015fe:	0141                	addi	sp,sp,16
ffffffffc0201600:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201602:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201604:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201606:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201608:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020160a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020160c:	00d70e63          	beq	a4,a3,ffffffffc0201628 <best_fit_init_memmap+0xac>
ffffffffc0201610:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201612:	87ba                	mv	a5,a4
ffffffffc0201614:	bfc1                	j	ffffffffc02015e4 <best_fit_init_memmap+0x68>
}
ffffffffc0201616:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201618:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020161c:	e398                	sd	a4,0(a5)
ffffffffc020161e:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201620:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201622:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201624:	0141                	addi	sp,sp,16
ffffffffc0201626:	8082                	ret
ffffffffc0201628:	60a2                	ld	ra,8(sp)
ffffffffc020162a:	e290                	sd	a2,0(a3)
ffffffffc020162c:	0141                	addi	sp,sp,16
ffffffffc020162e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201630:	00001697          	auipc	a3,0x1
ffffffffc0201634:	4b868693          	addi	a3,a3,1208 # ffffffffc0202ae8 <etext+0xbf8>
ffffffffc0201638:	00001617          	auipc	a2,0x1
ffffffffc020163c:	19860613          	addi	a2,a2,408 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201640:	04b00593          	li	a1,75
ffffffffc0201644:	00001517          	auipc	a0,0x1
ffffffffc0201648:	1a450513          	addi	a0,a0,420 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc020164c:	d81fe0ef          	jal	ffffffffc02003cc <__panic>
    assert(n > 0);
ffffffffc0201650:	00001697          	auipc	a3,0x1
ffffffffc0201654:	17868693          	addi	a3,a3,376 # ffffffffc02027c8 <etext+0x8d8>
ffffffffc0201658:	00001617          	auipc	a2,0x1
ffffffffc020165c:	17860613          	addi	a2,a2,376 # ffffffffc02027d0 <etext+0x8e0>
ffffffffc0201660:	04800593          	li	a1,72
ffffffffc0201664:	00001517          	auipc	a0,0x1
ffffffffc0201668:	18450513          	addi	a0,a0,388 # ffffffffc02027e8 <etext+0x8f8>
ffffffffc020166c:	d61fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0201670 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201670:	100027f3          	csrr	a5,sstatus
ffffffffc0201674:	8b89                	andi	a5,a5,2
ffffffffc0201676:	e799                	bnez	a5,ffffffffc0201684 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201678:	00005797          	auipc	a5,0x5
ffffffffc020167c:	df07b783          	ld	a5,-528(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201680:	6f9c                	ld	a5,24(a5)
ffffffffc0201682:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201684:	1141                	addi	sp,sp,-16
ffffffffc0201686:	e406                	sd	ra,8(sp)
ffffffffc0201688:	e022                	sd	s0,0(sp)
ffffffffc020168a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020168c:	970ff0ef          	jal	ffffffffc02007fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201690:	00005797          	auipc	a5,0x5
ffffffffc0201694:	dd87b783          	ld	a5,-552(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201698:	6f9c                	ld	a5,24(a5)
ffffffffc020169a:	8522                	mv	a0,s0
ffffffffc020169c:	9782                	jalr	a5
ffffffffc020169e:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02016a0:	956ff0ef          	jal	ffffffffc02007f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02016a4:	60a2                	ld	ra,8(sp)
ffffffffc02016a6:	8522                	mv	a0,s0
ffffffffc02016a8:	6402                	ld	s0,0(sp)
ffffffffc02016aa:	0141                	addi	sp,sp,16
ffffffffc02016ac:	8082                	ret

ffffffffc02016ae <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016ae:	100027f3          	csrr	a5,sstatus
ffffffffc02016b2:	8b89                	andi	a5,a5,2
ffffffffc02016b4:	e799                	bnez	a5,ffffffffc02016c2 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02016b6:	00005797          	auipc	a5,0x5
ffffffffc02016ba:	db27b783          	ld	a5,-590(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc02016be:	739c                	ld	a5,32(a5)
ffffffffc02016c0:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02016c2:	1101                	addi	sp,sp,-32
ffffffffc02016c4:	ec06                	sd	ra,24(sp)
ffffffffc02016c6:	e822                	sd	s0,16(sp)
ffffffffc02016c8:	e426                	sd	s1,8(sp)
ffffffffc02016ca:	842a                	mv	s0,a0
ffffffffc02016cc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02016ce:	92eff0ef          	jal	ffffffffc02007fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02016d2:	00005797          	auipc	a5,0x5
ffffffffc02016d6:	d967b783          	ld	a5,-618(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc02016da:	739c                	ld	a5,32(a5)
ffffffffc02016dc:	85a6                	mv	a1,s1
ffffffffc02016de:	8522                	mv	a0,s0
ffffffffc02016e0:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02016e2:	6442                	ld	s0,16(sp)
ffffffffc02016e4:	60e2                	ld	ra,24(sp)
ffffffffc02016e6:	64a2                	ld	s1,8(sp)
ffffffffc02016e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02016ea:	90cff06f          	j	ffffffffc02007f6 <intr_enable>

ffffffffc02016ee <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016ee:	100027f3          	csrr	a5,sstatus
ffffffffc02016f2:	8b89                	andi	a5,a5,2
ffffffffc02016f4:	e799                	bnez	a5,ffffffffc0201702 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02016f6:	00005797          	auipc	a5,0x5
ffffffffc02016fa:	d727b783          	ld	a5,-654(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc02016fe:	779c                	ld	a5,40(a5)
ffffffffc0201700:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201702:	1141                	addi	sp,sp,-16
ffffffffc0201704:	e406                	sd	ra,8(sp)
ffffffffc0201706:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201708:	8f4ff0ef          	jal	ffffffffc02007fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020170c:	00005797          	auipc	a5,0x5
ffffffffc0201710:	d5c7b783          	ld	a5,-676(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201714:	779c                	ld	a5,40(a5)
ffffffffc0201716:	9782                	jalr	a5
ffffffffc0201718:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020171a:	8dcff0ef          	jal	ffffffffc02007f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020171e:	60a2                	ld	ra,8(sp)
ffffffffc0201720:	8522                	mv	a0,s0
ffffffffc0201722:	6402                	ld	s0,0(sp)
ffffffffc0201724:	0141                	addi	sp,sp,16
ffffffffc0201726:	8082                	ret

ffffffffc0201728 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201728:	00001797          	auipc	a5,0x1
ffffffffc020172c:	66078793          	addi	a5,a5,1632 # ffffffffc0202d88 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201730:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201732:	7179                	addi	sp,sp,-48
ffffffffc0201734:	f406                	sd	ra,40(sp)
ffffffffc0201736:	f022                	sd	s0,32(sp)
ffffffffc0201738:	ec26                	sd	s1,24(sp)
ffffffffc020173a:	e052                	sd	s4,0(sp)
ffffffffc020173c:	e84a                	sd	s2,16(sp)
ffffffffc020173e:	e44e                	sd	s3,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201740:	00005417          	auipc	s0,0x5
ffffffffc0201744:	d2840413          	addi	s0,s0,-728 # ffffffffc0206468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201748:	00001517          	auipc	a0,0x1
ffffffffc020174c:	3c850513          	addi	a0,a0,968 # ffffffffc0202b10 <etext+0xc20>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201750:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201752:	987fe0ef          	jal	ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0201756:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201758:	00005497          	auipc	s1,0x5
ffffffffc020175c:	d2848493          	addi	s1,s1,-728 # ffffffffc0206480 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201760:	679c                	ld	a5,8(a5)
ffffffffc0201762:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201764:	57f5                	li	a5,-3
ffffffffc0201766:	07fa                	slli	a5,a5,0x1e
ffffffffc0201768:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020176a:	878ff0ef          	jal	ffffffffc02007e2 <get_memory_base>
ffffffffc020176e:	8a2a                	mv	s4,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201770:	87cff0ef          	jal	ffffffffc02007ec <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201774:	18050363          	beqz	a0,ffffffffc02018fa <pmm_init+0x1d2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201778:	89aa                	mv	s3,a0
    cprintf("physcial memory map:\n");
ffffffffc020177a:	00001517          	auipc	a0,0x1
ffffffffc020177e:	3de50513          	addi	a0,a0,990 # ffffffffc0202b58 <etext+0xc68>
ffffffffc0201782:	957fe0ef          	jal	ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201786:	013a0933          	add	s2,s4,s3
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020178a:	fff90693          	addi	a3,s2,-1
ffffffffc020178e:	8652                	mv	a2,s4
ffffffffc0201790:	85ce                	mv	a1,s3
ffffffffc0201792:	00001517          	auipc	a0,0x1
ffffffffc0201796:	3de50513          	addi	a0,a0,990 # ffffffffc0202b70 <etext+0xc80>
ffffffffc020179a:	93ffe0ef          	jal	ffffffffc02000d8 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020179e:	c8000737          	lui	a4,0xc8000
ffffffffc02017a2:	87ca                	mv	a5,s2
ffffffffc02017a4:	0f276863          	bltu	a4,s2,ffffffffc0201894 <pmm_init+0x16c>
ffffffffc02017a8:	00006697          	auipc	a3,0x6
ffffffffc02017ac:	cf768693          	addi	a3,a3,-777 # ffffffffc020749f <end+0xfff>
ffffffffc02017b0:	777d                	lui	a4,0xfffff
ffffffffc02017b2:	8ef9                	and	a3,a3,a4
    npage = maxpa / PGSIZE;
ffffffffc02017b4:	83b1                	srli	a5,a5,0xc
ffffffffc02017b6:	00005817          	auipc	a6,0x5
ffffffffc02017ba:	cd280813          	addi	a6,a6,-814 # ffffffffc0206488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017be:	00005597          	auipc	a1,0x5
ffffffffc02017c2:	cd258593          	addi	a1,a1,-814 # ffffffffc0206490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02017c6:	00f83023          	sd	a5,0(a6)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017ca:	e194                	sd	a3,0(a1)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017cc:	00080637          	lui	a2,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017d0:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017d2:	04c78463          	beq	a5,a2,ffffffffc020181a <pmm_init+0xf2>
ffffffffc02017d6:	4785                	li	a5,1
ffffffffc02017d8:	00868713          	addi	a4,a3,8
ffffffffc02017dc:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc02017e0:	00083783          	ld	a5,0(a6)
ffffffffc02017e4:	4705                	li	a4,1
ffffffffc02017e6:	02800693          	li	a3,40
ffffffffc02017ea:	40c78633          	sub	a2,a5,a2
ffffffffc02017ee:	4885                	li	a7,1
ffffffffc02017f0:	fff80537          	lui	a0,0xfff80
ffffffffc02017f4:	02c77063          	bgeu	a4,a2,ffffffffc0201814 <pmm_init+0xec>
        SetPageReserved(pages + i);
ffffffffc02017f8:	619c                	ld	a5,0(a1)
ffffffffc02017fa:	97b6                	add	a5,a5,a3
ffffffffc02017fc:	07a1                	addi	a5,a5,8
ffffffffc02017fe:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201802:	00083783          	ld	a5,0(a6)
ffffffffc0201806:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0x3fdf8b61>
ffffffffc0201808:	02868693          	addi	a3,a3,40
ffffffffc020180c:	00a78633          	add	a2,a5,a0
ffffffffc0201810:	fec764e3          	bltu	a4,a2,ffffffffc02017f8 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201814:	0005b883          	ld	a7,0(a1)
ffffffffc0201818:	86c6                	mv	a3,a7
ffffffffc020181a:	00279713          	slli	a4,a5,0x2
ffffffffc020181e:	973e                	add	a4,a4,a5
ffffffffc0201820:	fec00637          	lui	a2,0xfec00
ffffffffc0201824:	070e                	slli	a4,a4,0x3
ffffffffc0201826:	96b2                	add	a3,a3,a2
ffffffffc0201828:	96ba                	add	a3,a3,a4
ffffffffc020182a:	c0200737          	lui	a4,0xc0200
ffffffffc020182e:	0ae6ea63          	bltu	a3,a4,ffffffffc02018e2 <pmm_init+0x1ba>
ffffffffc0201832:	6090                	ld	a2,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201834:	777d                	lui	a4,0xfffff
ffffffffc0201836:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020183a:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc020183c:	0526ef63          	bltu	a3,s2,ffffffffc020189a <pmm_init+0x172>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201840:	601c                	ld	a5,0(s0)
ffffffffc0201842:	7b9c                	ld	a5,48(a5)
ffffffffc0201844:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201846:	00001517          	auipc	a0,0x1
ffffffffc020184a:	3b250513          	addi	a0,a0,946 # ffffffffc0202bf8 <etext+0xd08>
ffffffffc020184e:	88bfe0ef          	jal	ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201852:	00003597          	auipc	a1,0x3
ffffffffc0201856:	7ae58593          	addi	a1,a1,1966 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020185a:	00005797          	auipc	a5,0x5
ffffffffc020185e:	c0b7bf23          	sd	a1,-994(a5) # ffffffffc0206478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201862:	c02007b7          	lui	a5,0xc0200
ffffffffc0201866:	0af5e663          	bltu	a1,a5,ffffffffc0201912 <pmm_init+0x1ea>
ffffffffc020186a:	609c                	ld	a5,0(s1)
}
ffffffffc020186c:	7402                	ld	s0,32(sp)
ffffffffc020186e:	70a2                	ld	ra,40(sp)
ffffffffc0201870:	64e2                	ld	s1,24(sp)
ffffffffc0201872:	6942                	ld	s2,16(sp)
ffffffffc0201874:	69a2                	ld	s3,8(sp)
ffffffffc0201876:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201878:	40f586b3          	sub	a3,a1,a5
ffffffffc020187c:	00005797          	auipc	a5,0x5
ffffffffc0201880:	bed7ba23          	sd	a3,-1036(a5) # ffffffffc0206470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201884:	00001517          	auipc	a0,0x1
ffffffffc0201888:	39450513          	addi	a0,a0,916 # ffffffffc0202c18 <etext+0xd28>
ffffffffc020188c:	8636                	mv	a2,a3
}
ffffffffc020188e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201890:	849fe06f          	j	ffffffffc02000d8 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201894:	c80007b7          	lui	a5,0xc8000
ffffffffc0201898:	bf01                	j	ffffffffc02017a8 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020189a:	6605                	lui	a2,0x1
ffffffffc020189c:	167d                	addi	a2,a2,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020189e:	96b2                	add	a3,a3,a2
ffffffffc02018a0:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018a2:	00c6d713          	srli	a4,a3,0xc
ffffffffc02018a6:	02f77263          	bgeu	a4,a5,ffffffffc02018ca <pmm_init+0x1a2>
    pmm_manager->init_memmap(base, n);
ffffffffc02018aa:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02018ac:	fff807b7          	lui	a5,0xfff80
ffffffffc02018b0:	97ba                	add	a5,a5,a4
ffffffffc02018b2:	00279513          	slli	a0,a5,0x2
ffffffffc02018b6:	953e                	add	a0,a0,a5
ffffffffc02018b8:	6a1c                	ld	a5,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02018ba:	40d90933          	sub	s2,s2,a3
ffffffffc02018be:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02018c0:	00c95593          	srli	a1,s2,0xc
ffffffffc02018c4:	9546                	add	a0,a0,a7
ffffffffc02018c6:	9782                	jalr	a5
}
ffffffffc02018c8:	bfa5                	j	ffffffffc0201840 <pmm_init+0x118>
        panic("pa2page called with invalid pa");
ffffffffc02018ca:	00001617          	auipc	a2,0x1
ffffffffc02018ce:	2fe60613          	addi	a2,a2,766 # ffffffffc0202bc8 <etext+0xcd8>
ffffffffc02018d2:	06b00593          	li	a1,107
ffffffffc02018d6:	00001517          	auipc	a0,0x1
ffffffffc02018da:	31250513          	addi	a0,a0,786 # ffffffffc0202be8 <etext+0xcf8>
ffffffffc02018de:	aeffe0ef          	jal	ffffffffc02003cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018e2:	00001617          	auipc	a2,0x1
ffffffffc02018e6:	2be60613          	addi	a2,a2,702 # ffffffffc0202ba0 <etext+0xcb0>
ffffffffc02018ea:	07100593          	li	a1,113
ffffffffc02018ee:	00001517          	auipc	a0,0x1
ffffffffc02018f2:	25a50513          	addi	a0,a0,602 # ffffffffc0202b48 <etext+0xc58>
ffffffffc02018f6:	ad7fe0ef          	jal	ffffffffc02003cc <__panic>
        panic("DTB memory info not available");
ffffffffc02018fa:	00001617          	auipc	a2,0x1
ffffffffc02018fe:	22e60613          	addi	a2,a2,558 # ffffffffc0202b28 <etext+0xc38>
ffffffffc0201902:	05a00593          	li	a1,90
ffffffffc0201906:	00001517          	auipc	a0,0x1
ffffffffc020190a:	24250513          	addi	a0,a0,578 # ffffffffc0202b48 <etext+0xc58>
ffffffffc020190e:	abffe0ef          	jal	ffffffffc02003cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201912:	86ae                	mv	a3,a1
ffffffffc0201914:	00001617          	auipc	a2,0x1
ffffffffc0201918:	28c60613          	addi	a2,a2,652 # ffffffffc0202ba0 <etext+0xcb0>
ffffffffc020191c:	08c00593          	li	a1,140
ffffffffc0201920:	00001517          	auipc	a0,0x1
ffffffffc0201924:	22850513          	addi	a0,a0,552 # ffffffffc0202b48 <etext+0xc58>
ffffffffc0201928:	aa5fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc020192c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020192c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201930:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201932:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201936:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201938:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020193c:	f022                	sd	s0,32(sp)
ffffffffc020193e:	ec26                	sd	s1,24(sp)
ffffffffc0201940:	e84a                	sd	s2,16(sp)
ffffffffc0201942:	f406                	sd	ra,40(sp)
ffffffffc0201944:	84aa                	mv	s1,a0
ffffffffc0201946:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201948:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b5f>
    unsigned mod = do_div(result, base);
ffffffffc020194c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020194e:	05067063          	bgeu	a2,a6,ffffffffc020198e <printnum+0x62>
ffffffffc0201952:	e44e                	sd	s3,8(sp)
ffffffffc0201954:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201956:	4785                	li	a5,1
ffffffffc0201958:	00e7d763          	bge	a5,a4,ffffffffc0201966 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc020195c:	85ca                	mv	a1,s2
ffffffffc020195e:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201960:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201962:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201964:	fc65                	bnez	s0,ffffffffc020195c <printnum+0x30>
ffffffffc0201966:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201968:	1a02                	slli	s4,s4,0x20
ffffffffc020196a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020196e:	00001797          	auipc	a5,0x1
ffffffffc0201972:	2ea78793          	addi	a5,a5,746 # ffffffffc0202c58 <etext+0xd68>
ffffffffc0201976:	97d2                	add	a5,a5,s4
}
ffffffffc0201978:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020197a:	0007c503          	lbu	a0,0(a5)
}
ffffffffc020197e:	70a2                	ld	ra,40(sp)
ffffffffc0201980:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201982:	85ca                	mv	a1,s2
ffffffffc0201984:	87a6                	mv	a5,s1
}
ffffffffc0201986:	6942                	ld	s2,16(sp)
ffffffffc0201988:	64e2                	ld	s1,24(sp)
ffffffffc020198a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020198c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020198e:	03065633          	divu	a2,a2,a6
ffffffffc0201992:	8722                	mv	a4,s0
ffffffffc0201994:	f99ff0ef          	jal	ffffffffc020192c <printnum>
ffffffffc0201998:	bfc1                	j	ffffffffc0201968 <printnum+0x3c>

ffffffffc020199a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020199a:	7119                	addi	sp,sp,-128
ffffffffc020199c:	f4a6                	sd	s1,104(sp)
ffffffffc020199e:	f0ca                	sd	s2,96(sp)
ffffffffc02019a0:	ecce                	sd	s3,88(sp)
ffffffffc02019a2:	e8d2                	sd	s4,80(sp)
ffffffffc02019a4:	e4d6                	sd	s5,72(sp)
ffffffffc02019a6:	e0da                	sd	s6,64(sp)
ffffffffc02019a8:	f862                	sd	s8,48(sp)
ffffffffc02019aa:	fc86                	sd	ra,120(sp)
ffffffffc02019ac:	f8a2                	sd	s0,112(sp)
ffffffffc02019ae:	fc5e                	sd	s7,56(sp)
ffffffffc02019b0:	f466                	sd	s9,40(sp)
ffffffffc02019b2:	f06a                	sd	s10,32(sp)
ffffffffc02019b4:	ec6e                	sd	s11,24(sp)
ffffffffc02019b6:	892a                	mv	s2,a0
ffffffffc02019b8:	84ae                	mv	s1,a1
ffffffffc02019ba:	8c32                	mv	s8,a2
ffffffffc02019bc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019be:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019c2:	05500b13          	li	s6,85
ffffffffc02019c6:	00001a97          	auipc	s5,0x1
ffffffffc02019ca:	3faa8a93          	addi	s5,s5,1018 # ffffffffc0202dc0 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019ce:	000c4503          	lbu	a0,0(s8)
ffffffffc02019d2:	001c0413          	addi	s0,s8,1
ffffffffc02019d6:	01350a63          	beq	a0,s3,ffffffffc02019ea <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02019da:	cd0d                	beqz	a0,ffffffffc0201a14 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02019dc:	85a6                	mv	a1,s1
ffffffffc02019de:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019e0:	00044503          	lbu	a0,0(s0)
ffffffffc02019e4:	0405                	addi	s0,s0,1
ffffffffc02019e6:	ff351ae3          	bne	a0,s3,ffffffffc02019da <vprintfmt+0x40>
        char padc = ' ';
ffffffffc02019ea:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02019ee:	4b81                	li	s7,0
ffffffffc02019f0:	4601                	li	a2,0
        width = precision = -1;
ffffffffc02019f2:	5d7d                	li	s10,-1
ffffffffc02019f4:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019f6:	00044683          	lbu	a3,0(s0)
ffffffffc02019fa:	00140c13          	addi	s8,s0,1
ffffffffc02019fe:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201a02:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a06:	02bb6663          	bltu	s6,a1,ffffffffc0201a32 <vprintfmt+0x98>
ffffffffc0201a0a:	058a                	slli	a1,a1,0x2
ffffffffc0201a0c:	95d6                	add	a1,a1,s5
ffffffffc0201a0e:	4198                	lw	a4,0(a1)
ffffffffc0201a10:	9756                	add	a4,a4,s5
ffffffffc0201a12:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a14:	70e6                	ld	ra,120(sp)
ffffffffc0201a16:	7446                	ld	s0,112(sp)
ffffffffc0201a18:	74a6                	ld	s1,104(sp)
ffffffffc0201a1a:	7906                	ld	s2,96(sp)
ffffffffc0201a1c:	69e6                	ld	s3,88(sp)
ffffffffc0201a1e:	6a46                	ld	s4,80(sp)
ffffffffc0201a20:	6aa6                	ld	s5,72(sp)
ffffffffc0201a22:	6b06                	ld	s6,64(sp)
ffffffffc0201a24:	7be2                	ld	s7,56(sp)
ffffffffc0201a26:	7c42                	ld	s8,48(sp)
ffffffffc0201a28:	7ca2                	ld	s9,40(sp)
ffffffffc0201a2a:	7d02                	ld	s10,32(sp)
ffffffffc0201a2c:	6de2                	ld	s11,24(sp)
ffffffffc0201a2e:	6109                	addi	sp,sp,128
ffffffffc0201a30:	8082                	ret
            putch('%', putdat);
ffffffffc0201a32:	85a6                	mv	a1,s1
ffffffffc0201a34:	02500513          	li	a0,37
ffffffffc0201a38:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a3a:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201a3e:	02500793          	li	a5,37
ffffffffc0201a42:	8c22                	mv	s8,s0
ffffffffc0201a44:	f8f705e3          	beq	a4,a5,ffffffffc02019ce <vprintfmt+0x34>
ffffffffc0201a48:	02500713          	li	a4,37
ffffffffc0201a4c:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201a50:	1c7d                	addi	s8,s8,-1
ffffffffc0201a52:	fee79de3          	bne	a5,a4,ffffffffc0201a4c <vprintfmt+0xb2>
ffffffffc0201a56:	bfa5                	j	ffffffffc02019ce <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201a58:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201a5c:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201a5e:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201a62:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0201a66:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a6a:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201a6c:	02b76563          	bltu	a4,a1,ffffffffc0201a96 <vprintfmt+0xfc>
ffffffffc0201a70:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201a72:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201a76:	002d171b          	slliw	a4,s10,0x2
ffffffffc0201a7a:	01a7073b          	addw	a4,a4,s10
ffffffffc0201a7e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201a82:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201a84:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201a88:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201a8a:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201a8e:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201a92:	feb570e3          	bgeu	a0,a1,ffffffffc0201a72 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0201a96:	f60cd0e3          	bgez	s9,ffffffffc02019f6 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201a9a:	8cea                	mv	s9,s10
ffffffffc0201a9c:	5d7d                	li	s10,-1
ffffffffc0201a9e:	bfa1                	j	ffffffffc02019f6 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa0:	8db6                	mv	s11,a3
ffffffffc0201aa2:	8462                	mv	s0,s8
ffffffffc0201aa4:	bf89                	j	ffffffffc02019f6 <vprintfmt+0x5c>
ffffffffc0201aa6:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201aa8:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201aaa:	b7b1                	j	ffffffffc02019f6 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201aac:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201aae:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201ab2:	00c7c463          	blt	a5,a2,ffffffffc0201aba <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201ab6:	1a060163          	beqz	a2,ffffffffc0201c58 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201aba:	000a3603          	ld	a2,0(s4)
ffffffffc0201abe:	46c1                	li	a3,16
ffffffffc0201ac0:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201ac2:	000d879b          	sext.w	a5,s11
ffffffffc0201ac6:	8766                	mv	a4,s9
ffffffffc0201ac8:	85a6                	mv	a1,s1
ffffffffc0201aca:	854a                	mv	a0,s2
ffffffffc0201acc:	e61ff0ef          	jal	ffffffffc020192c <printnum>
            break;
ffffffffc0201ad0:	bdfd                	j	ffffffffc02019ce <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ad2:	000a2503          	lw	a0,0(s4)
ffffffffc0201ad6:	85a6                	mv	a1,s1
ffffffffc0201ad8:	0a21                	addi	s4,s4,8
ffffffffc0201ada:	9902                	jalr	s2
            break;
ffffffffc0201adc:	bdcd                	j	ffffffffc02019ce <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201ade:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201ae0:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201ae4:	00c7c463          	blt	a5,a2,ffffffffc0201aec <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201ae8:	16060363          	beqz	a2,ffffffffc0201c4e <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201aec:	000a3603          	ld	a2,0(s4)
ffffffffc0201af0:	46a9                	li	a3,10
ffffffffc0201af2:	8a3a                	mv	s4,a4
ffffffffc0201af4:	b7f9                	j	ffffffffc0201ac2 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201af6:	85a6                	mv	a1,s1
ffffffffc0201af8:	03000513          	li	a0,48
ffffffffc0201afc:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201afe:	85a6                	mv	a1,s1
ffffffffc0201b00:	07800513          	li	a0,120
ffffffffc0201b04:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b06:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201b0a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b0c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b0e:	bf55                	j	ffffffffc0201ac2 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201b10:	85a6                	mv	a1,s1
ffffffffc0201b12:	02500513          	li	a0,37
ffffffffc0201b16:	9902                	jalr	s2
            break;
ffffffffc0201b18:	bd5d                	j	ffffffffc02019ce <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201b1a:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b1e:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201b20:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201b22:	bf95                	j	ffffffffc0201a96 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201b24:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201b26:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201b2a:	00c7c463          	blt	a5,a2,ffffffffc0201b32 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201b2e:	10060b63          	beqz	a2,ffffffffc0201c44 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201b32:	000a3603          	ld	a2,0(s4)
ffffffffc0201b36:	46a1                	li	a3,8
ffffffffc0201b38:	8a3a                	mv	s4,a4
ffffffffc0201b3a:	b761                	j	ffffffffc0201ac2 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201b3c:	fffcc793          	not	a5,s9
ffffffffc0201b40:	97fd                	srai	a5,a5,0x3f
ffffffffc0201b42:	00fcf7b3          	and	a5,s9,a5
ffffffffc0201b46:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b4a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201b4c:	b56d                	j	ffffffffc02019f6 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b4e:	000a3403          	ld	s0,0(s4)
ffffffffc0201b52:	008a0793          	addi	a5,s4,8
ffffffffc0201b56:	e43e                	sd	a5,8(sp)
ffffffffc0201b58:	12040063          	beqz	s0,ffffffffc0201c78 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201b5c:	0d905963          	blez	s9,ffffffffc0201c2e <vprintfmt+0x294>
ffffffffc0201b60:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b64:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0201b68:	12fd9763          	bne	s11,a5,ffffffffc0201c96 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b6c:	00044783          	lbu	a5,0(s0)
ffffffffc0201b70:	0007851b          	sext.w	a0,a5
ffffffffc0201b74:	cb9d                	beqz	a5,ffffffffc0201baa <vprintfmt+0x210>
ffffffffc0201b76:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b78:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b7c:	000d4563          	bltz	s10,ffffffffc0201b86 <vprintfmt+0x1ec>
ffffffffc0201b80:	3d7d                	addiw	s10,s10,-1
ffffffffc0201b82:	028d0263          	beq	s10,s0,ffffffffc0201ba6 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0201b86:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b88:	0c0b8d63          	beqz	s7,ffffffffc0201c62 <vprintfmt+0x2c8>
ffffffffc0201b8c:	3781                	addiw	a5,a5,-32
ffffffffc0201b8e:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201c62 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201b92:	03f00513          	li	a0,63
ffffffffc0201b96:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b98:	000a4783          	lbu	a5,0(s4)
ffffffffc0201b9c:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0201b9e:	0a05                	addi	s4,s4,1
ffffffffc0201ba0:	0007851b          	sext.w	a0,a5
ffffffffc0201ba4:	ffe1                	bnez	a5,ffffffffc0201b7c <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201ba6:	01905963          	blez	s9,ffffffffc0201bb8 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201baa:	85a6                	mv	a1,s1
ffffffffc0201bac:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201bb0:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0201bb2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bb4:	fe0c9be3          	bnez	s9,ffffffffc0201baa <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bb8:	6a22                	ld	s4,8(sp)
ffffffffc0201bba:	bd11                	j	ffffffffc02019ce <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201bbc:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201bbe:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201bc2:	00c7c363          	blt	a5,a2,ffffffffc0201bc8 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201bc6:	ce25                	beqz	a2,ffffffffc0201c3e <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201bc8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201bcc:	08044d63          	bltz	s0,ffffffffc0201c66 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201bd0:	8622                	mv	a2,s0
ffffffffc0201bd2:	8a5e                	mv	s4,s7
ffffffffc0201bd4:	46a9                	li	a3,10
ffffffffc0201bd6:	b5f5                	j	ffffffffc0201ac2 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201bd8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201bdc:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201bde:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201be2:	8fb9                	xor	a5,a5,a4
ffffffffc0201be4:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201be8:	02d64663          	blt	a2,a3,ffffffffc0201c14 <vprintfmt+0x27a>
ffffffffc0201bec:	00369713          	slli	a4,a3,0x3
ffffffffc0201bf0:	00001797          	auipc	a5,0x1
ffffffffc0201bf4:	32878793          	addi	a5,a5,808 # ffffffffc0202f18 <error_string>
ffffffffc0201bf8:	97ba                	add	a5,a5,a4
ffffffffc0201bfa:	639c                	ld	a5,0(a5)
ffffffffc0201bfc:	cf81                	beqz	a5,ffffffffc0201c14 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201bfe:	86be                	mv	a3,a5
ffffffffc0201c00:	00001617          	auipc	a2,0x1
ffffffffc0201c04:	08860613          	addi	a2,a2,136 # ffffffffc0202c88 <etext+0xd98>
ffffffffc0201c08:	85a6                	mv	a1,s1
ffffffffc0201c0a:	854a                	mv	a0,s2
ffffffffc0201c0c:	0e8000ef          	jal	ffffffffc0201cf4 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201c10:	0a21                	addi	s4,s4,8
ffffffffc0201c12:	bb75                	j	ffffffffc02019ce <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c14:	00001617          	auipc	a2,0x1
ffffffffc0201c18:	06460613          	addi	a2,a2,100 # ffffffffc0202c78 <etext+0xd88>
ffffffffc0201c1c:	85a6                	mv	a1,s1
ffffffffc0201c1e:	854a                	mv	a0,s2
ffffffffc0201c20:	0d4000ef          	jal	ffffffffc0201cf4 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201c24:	0a21                	addi	s4,s4,8
ffffffffc0201c26:	b365                	j	ffffffffc02019ce <vprintfmt+0x34>
            lflag ++;
ffffffffc0201c28:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c2a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c2c:	b3e9                	j	ffffffffc02019f6 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c2e:	00044783          	lbu	a5,0(s0)
ffffffffc0201c32:	0007851b          	sext.w	a0,a5
ffffffffc0201c36:	d3c9                	beqz	a5,ffffffffc0201bb8 <vprintfmt+0x21e>
ffffffffc0201c38:	00140a13          	addi	s4,s0,1
ffffffffc0201c3c:	bf2d                	j	ffffffffc0201b76 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201c3e:	000a2403          	lw	s0,0(s4)
ffffffffc0201c42:	b769                	j	ffffffffc0201bcc <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201c44:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c48:	46a1                	li	a3,8
ffffffffc0201c4a:	8a3a                	mv	s4,a4
ffffffffc0201c4c:	bd9d                	j	ffffffffc0201ac2 <vprintfmt+0x128>
ffffffffc0201c4e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c52:	46a9                	li	a3,10
ffffffffc0201c54:	8a3a                	mv	s4,a4
ffffffffc0201c56:	b5b5                	j	ffffffffc0201ac2 <vprintfmt+0x128>
ffffffffc0201c58:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c5c:	46c1                	li	a3,16
ffffffffc0201c5e:	8a3a                	mv	s4,a4
ffffffffc0201c60:	b58d                	j	ffffffffc0201ac2 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201c62:	9902                	jalr	s2
ffffffffc0201c64:	bf15                	j	ffffffffc0201b98 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0201c66:	85a6                	mv	a1,s1
ffffffffc0201c68:	02d00513          	li	a0,45
ffffffffc0201c6c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201c6e:	40800633          	neg	a2,s0
ffffffffc0201c72:	8a5e                	mv	s4,s7
ffffffffc0201c74:	46a9                	li	a3,10
ffffffffc0201c76:	b5b1                	j	ffffffffc0201ac2 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0201c78:	01905663          	blez	s9,ffffffffc0201c84 <vprintfmt+0x2ea>
ffffffffc0201c7c:	02d00793          	li	a5,45
ffffffffc0201c80:	04fd9263          	bne	s11,a5,ffffffffc0201cc4 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c84:	02800793          	li	a5,40
ffffffffc0201c88:	00001a17          	auipc	s4,0x1
ffffffffc0201c8c:	fe9a0a13          	addi	s4,s4,-23 # ffffffffc0202c71 <etext+0xd81>
ffffffffc0201c90:	02800513          	li	a0,40
ffffffffc0201c94:	b5cd                	j	ffffffffc0201b76 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c96:	85ea                	mv	a1,s10
ffffffffc0201c98:	8522                	mv	a0,s0
ffffffffc0201c9a:	1b2000ef          	jal	ffffffffc0201e4c <strnlen>
ffffffffc0201c9e:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0201ca2:	01905963          	blez	s9,ffffffffc0201cb4 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201ca6:	2d81                	sext.w	s11,s11
ffffffffc0201ca8:	85a6                	mv	a1,s1
ffffffffc0201caa:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cac:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201cae:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cb0:	fe0c9ce3          	bnez	s9,ffffffffc0201ca8 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cb4:	00044783          	lbu	a5,0(s0)
ffffffffc0201cb8:	0007851b          	sext.w	a0,a5
ffffffffc0201cbc:	ea079de3          	bnez	a5,ffffffffc0201b76 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cc0:	6a22                	ld	s4,8(sp)
ffffffffc0201cc2:	b331                	j	ffffffffc02019ce <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cc4:	85ea                	mv	a1,s10
ffffffffc0201cc6:	00001517          	auipc	a0,0x1
ffffffffc0201cca:	faa50513          	addi	a0,a0,-86 # ffffffffc0202c70 <etext+0xd80>
ffffffffc0201cce:	17e000ef          	jal	ffffffffc0201e4c <strnlen>
ffffffffc0201cd2:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201cd6:	00001417          	auipc	s0,0x1
ffffffffc0201cda:	f9a40413          	addi	s0,s0,-102 # ffffffffc0202c70 <etext+0xd80>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cde:	00001a17          	auipc	s4,0x1
ffffffffc0201ce2:	f93a0a13          	addi	s4,s4,-109 # ffffffffc0202c71 <etext+0xd81>
ffffffffc0201ce6:	02800793          	li	a5,40
ffffffffc0201cea:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cee:	fb904ce3          	bgtz	s9,ffffffffc0201ca6 <vprintfmt+0x30c>
ffffffffc0201cf2:	b551                	j	ffffffffc0201b76 <vprintfmt+0x1dc>

ffffffffc0201cf4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cf4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201cf6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cfa:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201cfc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cfe:	ec06                	sd	ra,24(sp)
ffffffffc0201d00:	f83a                	sd	a4,48(sp)
ffffffffc0201d02:	fc3e                	sd	a5,56(sp)
ffffffffc0201d04:	e0c2                	sd	a6,64(sp)
ffffffffc0201d06:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d08:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d0a:	c91ff0ef          	jal	ffffffffc020199a <vprintfmt>
}
ffffffffc0201d0e:	60e2                	ld	ra,24(sp)
ffffffffc0201d10:	6161                	addi	sp,sp,80
ffffffffc0201d12:	8082                	ret

ffffffffc0201d14 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d14:	715d                	addi	sp,sp,-80
ffffffffc0201d16:	e486                	sd	ra,72(sp)
ffffffffc0201d18:	e0a2                	sd	s0,64(sp)
ffffffffc0201d1a:	fc26                	sd	s1,56(sp)
ffffffffc0201d1c:	f84a                	sd	s2,48(sp)
ffffffffc0201d1e:	f44e                	sd	s3,40(sp)
ffffffffc0201d20:	f052                	sd	s4,32(sp)
ffffffffc0201d22:	ec56                	sd	s5,24(sp)
ffffffffc0201d24:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0201d26:	c901                	beqz	a0,ffffffffc0201d36 <readline+0x22>
ffffffffc0201d28:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d2a:	00001517          	auipc	a0,0x1
ffffffffc0201d2e:	f5e50513          	addi	a0,a0,-162 # ffffffffc0202c88 <etext+0xd98>
ffffffffc0201d32:	ba6fe0ef          	jal	ffffffffc02000d8 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201d36:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d38:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d3a:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d3c:	4a29                	li	s4,10
ffffffffc0201d3e:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201d40:	00004b17          	auipc	s6,0x4
ffffffffc0201d44:	300b0b13          	addi	s6,s6,768 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d48:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0201d4c:	c10fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d50:	00054a63          	bltz	a0,ffffffffc0201d64 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d54:	00a4da63          	bge	s1,a0,ffffffffc0201d68 <readline+0x54>
ffffffffc0201d58:	0289d263          	bge	s3,s0,ffffffffc0201d7c <readline+0x68>
        c = getchar();
ffffffffc0201d5c:	c00fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d60:	fe055ae3          	bgez	a0,ffffffffc0201d54 <readline+0x40>
            return NULL;
ffffffffc0201d64:	4501                	li	a0,0
ffffffffc0201d66:	a091                	j	ffffffffc0201daa <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201d68:	03251463          	bne	a0,s2,ffffffffc0201d90 <readline+0x7c>
ffffffffc0201d6c:	04804963          	bgtz	s0,ffffffffc0201dbe <readline+0xaa>
        c = getchar();
ffffffffc0201d70:	becfe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d74:	fe0548e3          	bltz	a0,ffffffffc0201d64 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d78:	fea4d8e3          	bge	s1,a0,ffffffffc0201d68 <readline+0x54>
            cputchar(c);
ffffffffc0201d7c:	e42a                	sd	a0,8(sp)
ffffffffc0201d7e:	b8efe0ef          	jal	ffffffffc020010c <cputchar>
            buf[i ++] = c;
ffffffffc0201d82:	6522                	ld	a0,8(sp)
ffffffffc0201d84:	008b07b3          	add	a5,s6,s0
ffffffffc0201d88:	2405                	addiw	s0,s0,1
ffffffffc0201d8a:	00a78023          	sb	a0,0(a5)
ffffffffc0201d8e:	bf7d                	j	ffffffffc0201d4c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201d90:	01450463          	beq	a0,s4,ffffffffc0201d98 <readline+0x84>
ffffffffc0201d94:	fb551ce3          	bne	a0,s5,ffffffffc0201d4c <readline+0x38>
            cputchar(c);
ffffffffc0201d98:	b74fe0ef          	jal	ffffffffc020010c <cputchar>
            buf[i] = '\0';
ffffffffc0201d9c:	00004517          	auipc	a0,0x4
ffffffffc0201da0:	2a450513          	addi	a0,a0,676 # ffffffffc0206040 <buf>
ffffffffc0201da4:	942a                	add	s0,s0,a0
ffffffffc0201da6:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0201daa:	60a6                	ld	ra,72(sp)
ffffffffc0201dac:	6406                	ld	s0,64(sp)
ffffffffc0201dae:	74e2                	ld	s1,56(sp)
ffffffffc0201db0:	7942                	ld	s2,48(sp)
ffffffffc0201db2:	79a2                	ld	s3,40(sp)
ffffffffc0201db4:	7a02                	ld	s4,32(sp)
ffffffffc0201db6:	6ae2                	ld	s5,24(sp)
ffffffffc0201db8:	6b42                	ld	s6,16(sp)
ffffffffc0201dba:	6161                	addi	sp,sp,80
ffffffffc0201dbc:	8082                	ret
            cputchar(c);
ffffffffc0201dbe:	4521                	li	a0,8
ffffffffc0201dc0:	b4cfe0ef          	jal	ffffffffc020010c <cputchar>
            i --;
ffffffffc0201dc4:	347d                	addiw	s0,s0,-1
ffffffffc0201dc6:	b759                	j	ffffffffc0201d4c <readline+0x38>

ffffffffc0201dc8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201dc8:	4781                	li	a5,0
ffffffffc0201dca:	00004717          	auipc	a4,0x4
ffffffffc0201dce:	25673703          	ld	a4,598(a4) # ffffffffc0206020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dd2:	88ba                	mv	a7,a4
ffffffffc0201dd4:	852a                	mv	a0,a0
ffffffffc0201dd6:	85be                	mv	a1,a5
ffffffffc0201dd8:	863e                	mv	a2,a5
ffffffffc0201dda:	00000073          	ecall
ffffffffc0201dde:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201de0:	8082                	ret

ffffffffc0201de2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201de2:	4781                	li	a5,0
ffffffffc0201de4:	00004717          	auipc	a4,0x4
ffffffffc0201de8:	6b473703          	ld	a4,1716(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201dec:	88ba                	mv	a7,a4
ffffffffc0201dee:	852a                	mv	a0,a0
ffffffffc0201df0:	85be                	mv	a1,a5
ffffffffc0201df2:	863e                	mv	a2,a5
ffffffffc0201df4:	00000073          	ecall
ffffffffc0201df8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201dfa:	8082                	ret

ffffffffc0201dfc <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201dfc:	4501                	li	a0,0
ffffffffc0201dfe:	00004797          	auipc	a5,0x4
ffffffffc0201e02:	21a7b783          	ld	a5,538(a5) # ffffffffc0206018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e06:	88be                	mv	a7,a5
ffffffffc0201e08:	852a                	mv	a0,a0
ffffffffc0201e0a:	85aa                	mv	a1,a0
ffffffffc0201e0c:	862a                	mv	a2,a0
ffffffffc0201e0e:	00000073          	ecall
ffffffffc0201e12:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e14:	2501                	sext.w	a0,a0
ffffffffc0201e16:	8082                	ret

ffffffffc0201e18 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e18:	4781                	li	a5,0
ffffffffc0201e1a:	00004717          	auipc	a4,0x4
ffffffffc0201e1e:	1f673703          	ld	a4,502(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201e22:	88ba                	mv	a7,a4
ffffffffc0201e24:	853e                	mv	a0,a5
ffffffffc0201e26:	85be                	mv	a1,a5
ffffffffc0201e28:	863e                	mv	a2,a5
ffffffffc0201e2a:	00000073          	ecall
ffffffffc0201e2e:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e30:	8082                	ret

ffffffffc0201e32 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e32:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e36:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e38:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e3a:	cb81                	beqz	a5,ffffffffc0201e4a <strlen+0x18>
        cnt ++;
ffffffffc0201e3c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e3e:	00a707b3          	add	a5,a4,a0
ffffffffc0201e42:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e46:	fbfd                	bnez	a5,ffffffffc0201e3c <strlen+0xa>
ffffffffc0201e48:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e4a:	8082                	ret

ffffffffc0201e4c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e4c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e4e:	e589                	bnez	a1,ffffffffc0201e58 <strnlen+0xc>
ffffffffc0201e50:	a811                	j	ffffffffc0201e64 <strnlen+0x18>
        cnt ++;
ffffffffc0201e52:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e54:	00f58863          	beq	a1,a5,ffffffffc0201e64 <strnlen+0x18>
ffffffffc0201e58:	00f50733          	add	a4,a0,a5
ffffffffc0201e5c:	00074703          	lbu	a4,0(a4)
ffffffffc0201e60:	fb6d                	bnez	a4,ffffffffc0201e52 <strnlen+0x6>
ffffffffc0201e62:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e64:	852e                	mv	a0,a1
ffffffffc0201e66:	8082                	ret

ffffffffc0201e68 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e68:	00054783          	lbu	a5,0(a0)
ffffffffc0201e6c:	e791                	bnez	a5,ffffffffc0201e78 <strcmp+0x10>
ffffffffc0201e6e:	a02d                	j	ffffffffc0201e98 <strcmp+0x30>
ffffffffc0201e70:	00054783          	lbu	a5,0(a0)
ffffffffc0201e74:	cf89                	beqz	a5,ffffffffc0201e8e <strcmp+0x26>
ffffffffc0201e76:	85b6                	mv	a1,a3
ffffffffc0201e78:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201e7c:	0505                	addi	a0,a0,1
ffffffffc0201e7e:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e82:	fef707e3          	beq	a4,a5,ffffffffc0201e70 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e86:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201e8a:	9d19                	subw	a0,a0,a4
ffffffffc0201e8c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e8e:	0015c703          	lbu	a4,1(a1)
ffffffffc0201e92:	4501                	li	a0,0
}
ffffffffc0201e94:	9d19                	subw	a0,a0,a4
ffffffffc0201e96:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e98:	0005c703          	lbu	a4,0(a1)
ffffffffc0201e9c:	4501                	li	a0,0
ffffffffc0201e9e:	b7f5                	j	ffffffffc0201e8a <strcmp+0x22>

ffffffffc0201ea0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ea0:	ce01                	beqz	a2,ffffffffc0201eb8 <strncmp+0x18>
ffffffffc0201ea2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ea6:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ea8:	cb91                	beqz	a5,ffffffffc0201ebc <strncmp+0x1c>
ffffffffc0201eaa:	0005c703          	lbu	a4,0(a1)
ffffffffc0201eae:	00f71763          	bne	a4,a5,ffffffffc0201ebc <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201eb2:	0505                	addi	a0,a0,1
ffffffffc0201eb4:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201eb6:	f675                	bnez	a2,ffffffffc0201ea2 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eb8:	4501                	li	a0,0
ffffffffc0201eba:	8082                	ret
ffffffffc0201ebc:	00054503          	lbu	a0,0(a0)
ffffffffc0201ec0:	0005c783          	lbu	a5,0(a1)
ffffffffc0201ec4:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201ec6:	8082                	ret

ffffffffc0201ec8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201ec8:	00054783          	lbu	a5,0(a0)
ffffffffc0201ecc:	c799                	beqz	a5,ffffffffc0201eda <strchr+0x12>
        if (*s == c) {
ffffffffc0201ece:	00f58763          	beq	a1,a5,ffffffffc0201edc <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201ed2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201ed6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201ed8:	fbfd                	bnez	a5,ffffffffc0201ece <strchr+0x6>
    }
    return NULL;
ffffffffc0201eda:	4501                	li	a0,0
}
ffffffffc0201edc:	8082                	ret

ffffffffc0201ede <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ede:	ca01                	beqz	a2,ffffffffc0201eee <memset+0x10>
ffffffffc0201ee0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ee2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ee4:	0785                	addi	a5,a5,1
ffffffffc0201ee6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201eea:	fef61de3          	bne	a2,a5,ffffffffc0201ee4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201eee:	8082                	ret
