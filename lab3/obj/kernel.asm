
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
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	637010ef          	jal	ra,ffffffffc0201ea2 <memset>
    dtb_init();
ffffffffc0200070:	40e000ef          	jal	ra,ffffffffc020047e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3fc000ef          	jal	ra,ffffffffc0200470 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e4050513          	addi	a0,a0,-448 # ffffffffc0201eb8 <etext+0x4>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	0dc000ef          	jal	ra,ffffffffc0200160 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b2000ef          	jal	ra,ffffffffc020083a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	69a010ef          	jal	ra,ffffffffc0201726 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7aa000ef          	jal	ra,ffffffffc020083a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	39a000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	796000ef          	jal	ra,ffffffffc020082e <intr_enable>

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
ffffffffc02000a6:	3cc000ef          	jal	ra,ffffffffc0200472 <cons_putc>
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
ffffffffc02000cc:	0a7010ef          	jal	ra,ffffffffc0201972 <vprintfmt>
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
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	071010ef          	jal	ra,ffffffffc0201972 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	a695                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	34c000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	336000ef          	jal	ra,ffffffffc0200472 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	326000ef          	jal	ra,ffffffffc020047a <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200160:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200162:	00002517          	auipc	a0,0x2
ffffffffc0200166:	d7650513          	addi	a0,a0,-650 # ffffffffc0201ed8 <etext+0x24>
void print_kerninfo(void) {
ffffffffc020016a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016c:	f6dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200170:	00000597          	auipc	a1,0x0
ffffffffc0200174:	ee458593          	addi	a1,a1,-284 # ffffffffc0200054 <kern_init>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	d8050513          	addi	a0,a0,-640 # ffffffffc0201ef8 <etext+0x44>
ffffffffc0200180:	f59ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200184:	00002597          	auipc	a1,0x2
ffffffffc0200188:	d3058593          	addi	a1,a1,-720 # ffffffffc0201eb4 <etext>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	d8c50513          	addi	a0,a0,-628 # ffffffffc0201f18 <etext+0x64>
ffffffffc0200194:	f45ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	e9058593          	addi	a1,a1,-368 # ffffffffc0206028 <free_area>
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	d9850513          	addi	a0,a0,-616 # ffffffffc0201f38 <etext+0x84>
ffffffffc02001a8:	f31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ac:	00006597          	auipc	a1,0x6
ffffffffc02001b0:	2f458593          	addi	a1,a1,756 # ffffffffc02064a0 <end>
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	da450513          	addi	a0,a0,-604 # ffffffffc0201f58 <etext+0xa4>
ffffffffc02001bc:	f1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c0:	00006597          	auipc	a1,0x6
ffffffffc02001c4:	6df58593          	addi	a1,a1,1759 # ffffffffc020689f <end+0x3ff>
ffffffffc02001c8:	00000797          	auipc	a5,0x0
ffffffffc02001cc:	e8c78793          	addi	a5,a5,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d4:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d8:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001de:	95be                	add	a1,a1,a5
ffffffffc02001e0:	85a9                	srai	a1,a1,0xa
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	d9650513          	addi	a0,a0,-618 # ffffffffc0201f78 <etext+0xc4>
}
ffffffffc02001ea:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ec:	b5f5                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001ee <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	db860613          	addi	a2,a2,-584 # ffffffffc0201fa8 <etext+0xf4>
ffffffffc02001f8:	04d00593          	li	a1,77
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	dc450513          	addi	a0,a0,-572 # ffffffffc0201fc0 <etext+0x10c>
void print_stackframe(void) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200206:	1cc000ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020020a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	dcc60613          	addi	a2,a2,-564 # ffffffffc0201fd8 <etext+0x124>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	de458593          	addi	a1,a1,-540 # ffffffffc0201ff8 <etext+0x144>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	de450513          	addi	a0,a0,-540 # ffffffffc0202000 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200224:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200226:	eb3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	de660613          	addi	a2,a2,-538 # ffffffffc0202010 <etext+0x15c>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	e0658593          	addi	a1,a1,-506 # ffffffffc0202038 <etext+0x184>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	dc650513          	addi	a0,a0,-570 # ffffffffc0202000 <etext+0x14c>
ffffffffc0200242:	e97ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	e0260613          	addi	a2,a2,-510 # ffffffffc0202048 <etext+0x194>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	e1a58593          	addi	a1,a1,-486 # ffffffffc0202068 <etext+0x1b4>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	daa50513          	addi	a0,a0,-598 # ffffffffc0202000 <etext+0x14c>
ffffffffc020025e:	e7bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026a:	1141                	addi	sp,sp,-16
ffffffffc020026c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026e:	ef3ff0ef          	jal	ra,ffffffffc0200160 <print_kerninfo>
    return 0;
}
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027e:	f71ff0ef          	jal	ra,ffffffffc02001ee <print_stackframe>
    return 0;
}
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028a:	7115                	addi	sp,sp,-224
ffffffffc020028c:	ed5e                	sd	s7,152(sp)
ffffffffc020028e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	de850513          	addi	a0,a0,-536 # ffffffffc0202078 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc0200298:	ed86                	sd	ra,216(sp)
ffffffffc020029a:	e9a2                	sd	s0,208(sp)
ffffffffc020029c:	e5a6                	sd	s1,200(sp)
ffffffffc020029e:	e1ca                	sd	s2,192(sp)
ffffffffc02002a0:	fd4e                	sd	s3,184(sp)
ffffffffc02002a2:	f952                	sd	s4,176(sp)
ffffffffc02002a4:	f556                	sd	s5,168(sp)
ffffffffc02002a6:	f15a                	sd	s6,160(sp)
ffffffffc02002a8:	e962                	sd	s8,144(sp)
ffffffffc02002aa:	e566                	sd	s9,136(sp)
ffffffffc02002ac:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ae:	e2bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	dee50513          	addi	a0,a0,-530 # ffffffffc02020a0 <etext+0x1ec>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002be:	000b8563          	beqz	s7,ffffffffc02002c8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c2:	855e                	mv	a0,s7
ffffffffc02002c4:	756000ef          	jal	ra,ffffffffc0200a1a <print_trapframe>
ffffffffc02002c8:	00002c17          	auipc	s8,0x2
ffffffffc02002cc:	e48c0c13          	addi	s8,s8,-440 # ffffffffc0202110 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d0:	00002917          	auipc	s2,0x2
ffffffffc02002d4:	df890913          	addi	s2,s2,-520 # ffffffffc02020c8 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00002497          	auipc	s1,0x2
ffffffffc02002dc:	df848493          	addi	s1,s1,-520 # ffffffffc02020d0 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002e0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e2:	00002b17          	auipc	s6,0x2
ffffffffc02002e6:	df6b0b13          	addi	s6,s6,-522 # ffffffffc02020d8 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002ea:	00002a17          	auipc	s4,0x2
ffffffffc02002ee:	d0ea0a13          	addi	s4,s4,-754 # ffffffffc0201ff8 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f4:	854a                	mv	a0,s2
ffffffffc02002f6:	1ff010ef          	jal	ra,ffffffffc0201cf4 <readline>
ffffffffc02002fa:	842a                	mv	s0,a0
ffffffffc02002fc:	dd65                	beqz	a0,ffffffffc02002f4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fe:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200302:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	e1bd                	bnez	a1,ffffffffc020036a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200306:	fe0c87e3          	beqz	s9,ffffffffc02002f4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	6582                	ld	a1,0(sp)
ffffffffc020030c:	00002d17          	auipc	s10,0x2
ffffffffc0200310:	e04d0d13          	addi	s10,s10,-508 # ffffffffc0202110 <commands>
        argv[argc ++] = buf;
ffffffffc0200314:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200316:	4401                	li	s0,0
ffffffffc0200318:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031a:	32f010ef          	jal	ra,ffffffffc0201e48 <strcmp>
ffffffffc020031e:	c919                	beqz	a0,ffffffffc0200334 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200320:	2405                	addiw	s0,s0,1
ffffffffc0200322:	0b540063          	beq	s0,s5,ffffffffc02003c2 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	31b010ef          	jal	ra,ffffffffc0201e48 <strcmp>
ffffffffc0200332:	f57d                	bnez	a0,ffffffffc0200320 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200334:	00141793          	slli	a5,s0,0x1
ffffffffc0200338:	97a2                	add	a5,a5,s0
ffffffffc020033a:	078e                	slli	a5,a5,0x3
ffffffffc020033c:	97e2                	add	a5,a5,s8
ffffffffc020033e:	6b9c                	ld	a5,16(a5)
ffffffffc0200340:	865e                	mv	a2,s7
ffffffffc0200342:	002c                	addi	a1,sp,8
ffffffffc0200344:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200348:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020034a:	fa0555e3          	bgez	a0,ffffffffc02002f4 <kmonitor+0x6a>
}
ffffffffc020034e:	60ee                	ld	ra,216(sp)
ffffffffc0200350:	644e                	ld	s0,208(sp)
ffffffffc0200352:	64ae                	ld	s1,200(sp)
ffffffffc0200354:	690e                	ld	s2,192(sp)
ffffffffc0200356:	79ea                	ld	s3,184(sp)
ffffffffc0200358:	7a4a                	ld	s4,176(sp)
ffffffffc020035a:	7aaa                	ld	s5,168(sp)
ffffffffc020035c:	7b0a                	ld	s6,160(sp)
ffffffffc020035e:	6bea                	ld	s7,152(sp)
ffffffffc0200360:	6c4a                	ld	s8,144(sp)
ffffffffc0200362:	6caa                	ld	s9,136(sp)
ffffffffc0200364:	6d0a                	ld	s10,128(sp)
ffffffffc0200366:	612d                	addi	sp,sp,224
ffffffffc0200368:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036a:	8526                	mv	a0,s1
ffffffffc020036c:	321010ef          	jal	ra,ffffffffc0201e8c <strchr>
ffffffffc0200370:	c901                	beqz	a0,ffffffffc0200380 <kmonitor+0xf6>
ffffffffc0200372:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200376:	00040023          	sb	zero,0(s0)
ffffffffc020037a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037c:	d5c9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc020037e:	b7f5                	j	ffffffffc020036a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	d3c9                	beqz	a5,ffffffffc0200306 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200386:	033c8963          	beq	s9,s3,ffffffffc02003b8 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020038a:	003c9793          	slli	a5,s9,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11e>
ffffffffc020039e:	b7b5                	j	ffffffffc020030a <kmonitor+0x80>
ffffffffc02003a0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	d1a5                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003a8:	8526                	mv	a0,s1
ffffffffc02003aa:	2e3010ef          	jal	ra,ffffffffc0201e8c <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	d9a9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003b6:	bf55                	j	ffffffffc020036a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b8:	45c1                	li	a1,16
ffffffffc02003ba:	855a                	mv	a0,s6
ffffffffc02003bc:	d1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02003c0:	b7e9                	j	ffffffffc020038a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c2:	6582                	ld	a1,0(sp)
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	d3450513          	addi	a0,a0,-716 # ffffffffc02020f8 <etext+0x244>
ffffffffc02003cc:	d0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc02003d0:	b715                	j	ffffffffc02002f4 <kmonitor+0x6a>

ffffffffc02003d2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d2:	00006317          	auipc	t1,0x6
ffffffffc02003d6:	06e30313          	addi	t1,t1,110 # ffffffffc0206440 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	e822                	sd	s0,16(sp)
ffffffffc02003e4:	f436                	sd	a3,40(sp)
ffffffffc02003e6:	f83a                	sd	a4,48(sp)
ffffffffc02003e8:	fc3e                	sd	a5,56(sp)
ffffffffc02003ea:	e0c2                	sd	a6,64(sp)
ffffffffc02003ec:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ee:	020e1a63          	bnez	t3,ffffffffc0200422 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f2:	4785                	li	a5,1
ffffffffc02003f4:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f8:	8432                	mv	s0,a2
ffffffffc02003fa:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	d5850513          	addi	a0,a0,-680 # ffffffffc0202158 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	ccfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	ca7ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0201fa0 <etext+0xec>
ffffffffc020041e:	cbbff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	412000ef          	jal	ra,ffffffffc0200834 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e63ff0ef          	jal	ra,ffffffffc020028a <kmonitor>
    while (1) {
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x54>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	17d010ef          	jal	ra,ffffffffc0201dc2 <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	fe07be23          	sd	zero,-4(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	d2450513          	addi	a0,a0,-732 # ffffffffc0202178 <commands+0x68>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9ad                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	1570106f          	j	ffffffffc0201dc2 <sbi_set_timer>

ffffffffc0200470 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200472:	0ff57513          	zext.b	a0,a0
ffffffffc0200476:	1330106f          	j	ffffffffc0201da8 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047a:	1630106f          	j	ffffffffc0201ddc <sbi_console_getchar>

ffffffffc020047e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	d1850513          	addi	a0,a0,-744 # ffffffffc0202198 <commands+0x88>
void dtb_init(void) {
ffffffffc0200488:	fc86                	sd	ra,120(sp)
ffffffffc020048a:	f8a2                	sd	s0,112(sp)
ffffffffc020048c:	e8d2                	sd	s4,80(sp)
ffffffffc020048e:	f4a6                	sd	s1,104(sp)
ffffffffc0200490:	f0ca                	sd	s2,96(sp)
ffffffffc0200492:	ecce                	sd	s3,88(sp)
ffffffffc0200494:	e4d6                	sd	s5,72(sp)
ffffffffc0200496:	e0da                	sd	s6,64(sp)
ffffffffc0200498:	fc5e                	sd	s7,56(sp)
ffffffffc020049a:	f862                	sd	s8,48(sp)
ffffffffc020049c:	f466                	sd	s9,40(sp)
ffffffffc020049e:	f06a                	sd	s10,32(sp)
ffffffffc02004a0:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004a2:	c37ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004a6:	00006597          	auipc	a1,0x6
ffffffffc02004aa:	b5a5b583          	ld	a1,-1190(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004ae:	00002517          	auipc	a0,0x2
ffffffffc02004b2:	cfa50513          	addi	a0,a0,-774 # ffffffffc02021a8 <commands+0x98>
ffffffffc02004b6:	c23ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004ba:	00006417          	auipc	s0,0x6
ffffffffc02004be:	b4e40413          	addi	s0,s0,-1202 # ffffffffc0206008 <boot_dtb>
ffffffffc02004c2:	600c                	ld	a1,0(s0)
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	cf450513          	addi	a0,a0,-780 # ffffffffc02021b8 <commands+0xa8>
ffffffffc02004cc:	c0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004d0:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	cfc50513          	addi	a0,a0,-772 # ffffffffc02021d0 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004dc:	120a0463          	beqz	s4,ffffffffc0200604 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004e0:	57f5                	li	a5,-3
ffffffffc02004e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004e4:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004e8:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004f4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200506:	8ec9                	or	a3,a3,a0
ffffffffc0200508:	0087979b          	slliw	a5,a5,0x8
ffffffffc020050c:	1b7d                	addi	s6,s6,-1
ffffffffc020050e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200512:	8dd5                	or	a1,a1,a3
ffffffffc0200514:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200516:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020051c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200520:	10f59163          	bne	a1,a5,ffffffffc0200622 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200524:	471c                	lw	a5,8(a4)
ffffffffc0200526:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200528:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200532:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053a:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	01146433          	or	s0,s0,a7
ffffffffc0200558:	0086969b          	slliw	a3,a3,0x8
ffffffffc020055c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200560:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200562:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200566:	8c49                	or	s0,s0,a0
ffffffffc0200568:	0166f6b3          	and	a3,a3,s6
ffffffffc020056c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200570:	0167f7b3          	and	a5,a5,s6
ffffffffc0200574:	8c55                	or	s0,s0,a3
ffffffffc0200576:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200580:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200584:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200586:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200588:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020058c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020058e:	00002917          	auipc	s2,0x2
ffffffffc0200592:	c9290913          	addi	s2,s2,-878 # ffffffffc0202220 <commands+0x110>
ffffffffc0200596:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200598:	4d91                	li	s11,4
ffffffffc020059a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020059c:	00002497          	auipc	s1,0x2
ffffffffc02005a0:	c7c48493          	addi	s1,s1,-900 # ffffffffc0202218 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005a4:	000a2703          	lw	a4,0(s4)
ffffffffc02005a8:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b0:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b4:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b8:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c0:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ca:	8fd5                	or	a5,a5,a3
ffffffffc02005cc:	00eb7733          	and	a4,s6,a4
ffffffffc02005d0:	8fd9                	or	a5,a5,a4
ffffffffc02005d2:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005d4:	09778c63          	beq	a5,s7,ffffffffc020066c <dtb_init+0x1ee>
ffffffffc02005d8:	00fbea63          	bltu	s7,a5,ffffffffc02005ec <dtb_init+0x16e>
ffffffffc02005dc:	07a78663          	beq	a5,s10,ffffffffc0200648 <dtb_init+0x1ca>
ffffffffc02005e0:	4709                	li	a4,2
ffffffffc02005e2:	00e79763          	bne	a5,a4,ffffffffc02005f0 <dtb_init+0x172>
ffffffffc02005e6:	4c81                	li	s9,0
ffffffffc02005e8:	8a56                	mv	s4,s5
ffffffffc02005ea:	bf6d                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc02005ec:	ffb78ee3          	beq	a5,s11,ffffffffc02005e8 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005f0:	00002517          	auipc	a0,0x2
ffffffffc02005f4:	ca850513          	addi	a0,a0,-856 # ffffffffc0202298 <commands+0x188>
ffffffffc02005f8:	ae1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	cd450513          	addi	a0,a0,-812 # ffffffffc02022d0 <commands+0x1c0>
}
ffffffffc0200604:	7446                	ld	s0,112(sp)
ffffffffc0200606:	70e6                	ld	ra,120(sp)
ffffffffc0200608:	74a6                	ld	s1,104(sp)
ffffffffc020060a:	7906                	ld	s2,96(sp)
ffffffffc020060c:	69e6                	ld	s3,88(sp)
ffffffffc020060e:	6a46                	ld	s4,80(sp)
ffffffffc0200610:	6aa6                	ld	s5,72(sp)
ffffffffc0200612:	6b06                	ld	s6,64(sp)
ffffffffc0200614:	7be2                	ld	s7,56(sp)
ffffffffc0200616:	7c42                	ld	s8,48(sp)
ffffffffc0200618:	7ca2                	ld	s9,40(sp)
ffffffffc020061a:	7d02                	ld	s10,32(sp)
ffffffffc020061c:	6de2                	ld	s11,24(sp)
ffffffffc020061e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200620:	bc65                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200622:	7446                	ld	s0,112(sp)
ffffffffc0200624:	70e6                	ld	ra,120(sp)
ffffffffc0200626:	74a6                	ld	s1,104(sp)
ffffffffc0200628:	7906                	ld	s2,96(sp)
ffffffffc020062a:	69e6                	ld	s3,88(sp)
ffffffffc020062c:	6a46                	ld	s4,80(sp)
ffffffffc020062e:	6aa6                	ld	s5,72(sp)
ffffffffc0200630:	6b06                	ld	s6,64(sp)
ffffffffc0200632:	7be2                	ld	s7,56(sp)
ffffffffc0200634:	7c42                	ld	s8,48(sp)
ffffffffc0200636:	7ca2                	ld	s9,40(sp)
ffffffffc0200638:	7d02                	ld	s10,32(sp)
ffffffffc020063a:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	bb450513          	addi	a0,a0,-1100 # ffffffffc02021f0 <commands+0xe0>
}
ffffffffc0200644:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200646:	bc49                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200648:	8556                	mv	a0,s5
ffffffffc020064a:	7c8010ef          	jal	ra,ffffffffc0201e12 <strlen>
ffffffffc020064e:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200650:	4619                	li	a2,6
ffffffffc0200652:	85a6                	mv	a1,s1
ffffffffc0200654:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200656:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200658:	00f010ef          	jal	ra,ffffffffc0201e66 <strncmp>
ffffffffc020065c:	e111                	bnez	a0,ffffffffc0200660 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020065e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200660:	0a91                	addi	s5,s5,4
ffffffffc0200662:	9ad2                	add	s5,s5,s4
ffffffffc0200664:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200668:	8a56                	mv	s4,s5
ffffffffc020066a:	bf2d                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200670:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200678:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200680:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200684:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200688:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200690:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200694:	00eaeab3          	or	s5,s5,a4
ffffffffc0200698:	00fb77b3          	and	a5,s6,a5
ffffffffc020069c:	00faeab3          	or	s5,s5,a5
ffffffffc02006a0:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006a2:	000c9c63          	bnez	s9,ffffffffc02006ba <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006a6:	1a82                	slli	s5,s5,0x20
ffffffffc02006a8:	00368793          	addi	a5,a3,3
ffffffffc02006ac:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b0:	9abe                	add	s5,s5,a5
ffffffffc02006b2:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006b6:	8a56                	mv	s4,s5
ffffffffc02006b8:	b5f5                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ba:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006be:	85ca                	mv	a1,s2
ffffffffc02006c0:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006ce:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006d6:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8d59                	or	a0,a0,a4
ffffffffc02006e2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006e6:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006e8:	1502                	slli	a0,a0,0x20
ffffffffc02006ea:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ec:	9522                	add	a0,a0,s0
ffffffffc02006ee:	75a010ef          	jal	ra,ffffffffc0201e48 <strcmp>
ffffffffc02006f2:	66a2                	ld	a3,8(sp)
ffffffffc02006f4:	f94d                	bnez	a0,ffffffffc02006a6 <dtb_init+0x228>
ffffffffc02006f6:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006a6 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006fa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006fe:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200702:	00002517          	auipc	a0,0x2
ffffffffc0200706:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202228 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc020070a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200712:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020071a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0187d693          	srli	a3,a5,0x18
ffffffffc020072a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020072e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200732:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0106561b          	srliw	a2,a2,0x10
ffffffffc020073a:	010f6f33          	or	t5,t5,a6
ffffffffc020073e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200742:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200746:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074a:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200752:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200756:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020075e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200762:	8361                	srli	a4,a4,0x18
ffffffffc0200764:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200768:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020076c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200770:	00cb7633          	and	a2,s6,a2
ffffffffc0200774:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200778:	0085959b          	slliw	a1,a1,0x8
ffffffffc020077c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200790:	011b78b3          	and	a7,s6,a7
ffffffffc0200794:	005eeeb3          	or	t4,t4,t0
ffffffffc0200798:	00c6e733          	or	a4,a3,a2
ffffffffc020079c:	006c6c33          	or	s8,s8,t1
ffffffffc02007a0:	010b76b3          	and	a3,s6,a6
ffffffffc02007a4:	00bb7b33          	and	s6,s6,a1
ffffffffc02007a8:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007ac:	016c6b33          	or	s6,s8,s6
ffffffffc02007b0:	01146433          	or	s0,s0,a7
ffffffffc02007b4:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007b6:	1702                	slli	a4,a4,0x20
ffffffffc02007b8:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ba:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007bc:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007be:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c0:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c4:	0167eb33          	or	s6,a5,s6
ffffffffc02007c8:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007ca:	90fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007ce:	85a2                	mv	a1,s0
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	a7850513          	addi	a0,a0,-1416 # ffffffffc0202248 <commands+0x138>
ffffffffc02007d8:	901ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007dc:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e0:	85da                	mv	a1,s6
ffffffffc02007e2:	00002517          	auipc	a0,0x2
ffffffffc02007e6:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0202260 <commands+0x150>
ffffffffc02007ea:	8efff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007ee:	008b05b3          	add	a1,s6,s0
ffffffffc02007f2:	15fd                	addi	a1,a1,-1
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0202280 <commands+0x170>
ffffffffc02007fc:	8ddff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	ad050513          	addi	a0,a0,-1328 # ffffffffc02022d0 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200808:	00006797          	auipc	a5,0x6
ffffffffc020080c:	c487b423          	sd	s0,-952(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc0200810:	00006797          	auipc	a5,0x6
ffffffffc0200814:	c567b423          	sd	s6,-952(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200818:	b3f5                	j	ffffffffc0200604 <dtb_init+0x186>

ffffffffc020081a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020081a:	00006517          	auipc	a0,0x6
ffffffffc020081e:	c3653503          	ld	a0,-970(a0) # ffffffffc0206450 <memory_base>
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200824:	00006517          	auipc	a0,0x6
ffffffffc0200828:	c3453503          	ld	a0,-972(a0) # ffffffffc0206458 <memory_size>
ffffffffc020082c:	8082                	ret

ffffffffc020082e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020082e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200834:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200838:	8082                	ret

ffffffffc020083a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020083a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020083e:	00000797          	auipc	a5,0x0
ffffffffc0200842:	36e78793          	addi	a5,a5,878 # ffffffffc0200bac <__alltraps>
ffffffffc0200846:	10579073          	csrw	stvec,a5
}
ffffffffc020084a:	8082                	ret

ffffffffc020084c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020084e:	1141                	addi	sp,sp,-16
ffffffffc0200850:	e022                	sd	s0,0(sp)
ffffffffc0200852:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200854:	00002517          	auipc	a0,0x2
ffffffffc0200858:	a9450513          	addi	a0,a0,-1388 # ffffffffc02022e8 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085e:	87bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200862:	640c                	ld	a1,8(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0202300 <commands+0x1f0>
ffffffffc020086c:	86dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200870:	680c                	ld	a1,16(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	aa650513          	addi	a0,a0,-1370 # ffffffffc0202318 <commands+0x208>
ffffffffc020087a:	85fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020087e:	6c0c                	ld	a1,24(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	ab050513          	addi	a0,a0,-1360 # ffffffffc0202330 <commands+0x220>
ffffffffc0200888:	851ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088c:	700c                	ld	a1,32(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	aba50513          	addi	a0,a0,-1350 # ffffffffc0202348 <commands+0x238>
ffffffffc0200896:	843ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089a:	740c                	ld	a1,40(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202360 <commands+0x250>
ffffffffc02008a4:	835ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008a8:	780c                	ld	a1,48(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	ace50513          	addi	a0,a0,-1330 # ffffffffc0202378 <commands+0x268>
ffffffffc02008b2:	827ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b6:	7c0c                	ld	a1,56(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	ad850513          	addi	a0,a0,-1320 # ffffffffc0202390 <commands+0x280>
ffffffffc02008c0:	819ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c4:	602c                	ld	a1,64(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	ae250513          	addi	a0,a0,-1310 # ffffffffc02023a8 <commands+0x298>
ffffffffc02008ce:	80bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d2:	642c                	ld	a1,72(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	aec50513          	addi	a0,a0,-1300 # ffffffffc02023c0 <commands+0x2b0>
ffffffffc02008dc:	ffcff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e0:	682c                	ld	a1,80(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	af650513          	addi	a0,a0,-1290 # ffffffffc02023d8 <commands+0x2c8>
ffffffffc02008ea:	feeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008ee:	6c2c                	ld	a1,88(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	b0050513          	addi	a0,a0,-1280 # ffffffffc02023f0 <commands+0x2e0>
ffffffffc02008f8:	fe0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fc:	702c                	ld	a1,96(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0202408 <commands+0x2f8>
ffffffffc0200906:	fd2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090a:	742c                	ld	a1,104(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	b1450513          	addi	a0,a0,-1260 # ffffffffc0202420 <commands+0x310>
ffffffffc0200914:	fc4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200918:	782c                	ld	a1,112(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0202438 <commands+0x328>
ffffffffc0200922:	fb6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200926:	7c2c                	ld	a1,120(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0202450 <commands+0x340>
ffffffffc0200930:	fa8ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200934:	604c                	ld	a1,128(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	b3250513          	addi	a0,a0,-1230 # ffffffffc0202468 <commands+0x358>
ffffffffc020093e:	f9aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200942:	644c                	ld	a1,136(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0202480 <commands+0x370>
ffffffffc020094c:	f8cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200950:	684c                	ld	a1,144(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	b4650513          	addi	a0,a0,-1210 # ffffffffc0202498 <commands+0x388>
ffffffffc020095a:	f7eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020095e:	6c4c                	ld	a1,152(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	b5050513          	addi	a0,a0,-1200 # ffffffffc02024b0 <commands+0x3a0>
ffffffffc0200968:	f70ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096c:	704c                	ld	a1,160(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	b5a50513          	addi	a0,a0,-1190 # ffffffffc02024c8 <commands+0x3b8>
ffffffffc0200976:	f62ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097a:	744c                	ld	a1,168(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	b6450513          	addi	a0,a0,-1180 # ffffffffc02024e0 <commands+0x3d0>
ffffffffc0200984:	f54ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200988:	784c                	ld	a1,176(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02024f8 <commands+0x3e8>
ffffffffc0200992:	f46ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200996:	7c4c                	ld	a1,184(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202510 <commands+0x400>
ffffffffc02009a0:	f38ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a4:	606c                	ld	a1,192(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202528 <commands+0x418>
ffffffffc02009ae:	f2aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b2:	646c                	ld	a1,200(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202540 <commands+0x430>
ffffffffc02009bc:	f1cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c0:	686c                	ld	a1,208(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202558 <commands+0x448>
ffffffffc02009ca:	f0eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009ce:	6c6c                	ld	a1,216(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202570 <commands+0x460>
ffffffffc02009d8:	f00ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009dc:	706c                	ld	a1,224(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202588 <commands+0x478>
ffffffffc02009e6:	ef2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ea:	746c                	ld	a1,232(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	bb450513          	addi	a0,a0,-1100 # ffffffffc02025a0 <commands+0x490>
ffffffffc02009f4:	ee4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009f8:	786c                	ld	a1,240(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02025b8 <commands+0x4a8>
ffffffffc0200a02:	ed6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a06:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a08:	6402                	ld	s0,0(sp)
ffffffffc0200a0a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0c:	00002517          	auipc	a0,0x2
ffffffffc0200a10:	bc450513          	addi	a0,a0,-1084 # ffffffffc02025d0 <commands+0x4c0>
}
ffffffffc0200a14:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a16:	ec2ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1a:	1141                	addi	sp,sp,-16
ffffffffc0200a1c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a1e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a20:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	bc650513          	addi	a0,a0,-1082 # ffffffffc02025e8 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2c:	eacff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a30:	8522                	mv	a0,s0
ffffffffc0200a32:	e1bff0ef          	jal	ra,ffffffffc020084c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a36:	10043583          	ld	a1,256(s0)
ffffffffc0200a3a:	00002517          	auipc	a0,0x2
ffffffffc0200a3e:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202600 <commands+0x4f0>
ffffffffc0200a42:	e96ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a46:	10843583          	ld	a1,264(s0)
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202618 <commands+0x508>
ffffffffc0200a52:	e86ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a56:	11043583          	ld	a1,272(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202630 <commands+0x520>
ffffffffc0200a62:	e76ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a66:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6a:	6402                	ld	s0,0(sp)
ffffffffc0200a6c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6e:	00002517          	auipc	a0,0x2
ffffffffc0200a72:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202648 <commands+0x538>
}
ffffffffc0200a76:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7c <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a7c:	11853783          	ld	a5,280(a0)
ffffffffc0200a80:	472d                	li	a4,11
ffffffffc0200a82:	0786                	slli	a5,a5,0x1
ffffffffc0200a84:	8385                	srli	a5,a5,0x1
ffffffffc0200a86:	08f76263          	bltu	a4,a5,ffffffffc0200b0a <interrupt_handler+0x8e>
ffffffffc0200a8a:	00002717          	auipc	a4,0x2
ffffffffc0200a8e:	c9e70713          	addi	a4,a4,-866 # ffffffffc0202728 <commands+0x618>
ffffffffc0200a92:	078a                	slli	a5,a5,0x2
ffffffffc0200a94:	97ba                	add	a5,a5,a4
ffffffffc0200a96:	439c                	lw	a5,0(a5)
ffffffffc0200a98:	97ba                	add	a5,a5,a4
ffffffffc0200a9a:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a9c:	00002517          	auipc	a0,0x2
ffffffffc0200aa0:	c2450513          	addi	a0,a0,-988 # ffffffffc02026c0 <commands+0x5b0>
ffffffffc0200aa4:	e34ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	bf850513          	addi	a0,a0,-1032 # ffffffffc02026a0 <commands+0x590>
ffffffffc0200ab0:	e28ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab4:	00002517          	auipc	a0,0x2
ffffffffc0200ab8:	bac50513          	addi	a0,a0,-1108 # ffffffffc0202660 <commands+0x550>
ffffffffc0200abc:	e1cff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	c2050513          	addi	a0,a0,-992 # ffffffffc02026e0 <commands+0x5d0>
ffffffffc0200ac8:	e10ff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200acc:	1141                	addi	sp,sp,-16
ffffffffc0200ace:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200ad0:	991ff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200ad4:	00006697          	auipc	a3,0x6
ffffffffc0200ad8:	97468693          	addi	a3,a3,-1676 # ffffffffc0206448 <ticks>
ffffffffc0200adc:	629c                	ld	a5,0(a3)
ffffffffc0200ade:	06400713          	li	a4,100
ffffffffc0200ae2:	0785                	addi	a5,a5,1
ffffffffc0200ae4:	02e7f733          	remu	a4,a5,a4
ffffffffc0200ae8:	e29c                	sd	a5,0(a3)
ffffffffc0200aea:	c30d                	beqz	a4,ffffffffc0200b0c <interrupt_handler+0x90>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aec:	60a2                	ld	ra,8(sp)
ffffffffc0200aee:	0141                	addi	sp,sp,16
ffffffffc0200af0:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200af2:	00002517          	auipc	a0,0x2
ffffffffc0200af6:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202708 <commands+0x5f8>
ffffffffc0200afa:	ddeff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200afe:	00002517          	auipc	a0,0x2
ffffffffc0200b02:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202680 <commands+0x570>
ffffffffc0200b06:	dd2ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b0a:	bf01                	j	ffffffffc0200a1a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b0c:	06400593          	li	a1,100
ffffffffc0200b10:	00002517          	auipc	a0,0x2
ffffffffc0200b14:	be850513          	addi	a0,a0,-1048 # ffffffffc02026f8 <commands+0x5e8>
ffffffffc0200b18:	dc0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                print_count++;
ffffffffc0200b1c:	00006717          	auipc	a4,0x6
ffffffffc0200b20:	94470713          	addi	a4,a4,-1724 # ffffffffc0206460 <print_count.0>
ffffffffc0200b24:	431c                	lw	a5,0(a4)
                if (print_count == 10) {
ffffffffc0200b26:	46a9                	li	a3,10
                print_count++;
ffffffffc0200b28:	0017861b          	addiw	a2,a5,1
ffffffffc0200b2c:	c310                	sw	a2,0(a4)
                if (print_count == 10) {
ffffffffc0200b2e:	fad61fe3          	bne	a2,a3,ffffffffc0200aec <interrupt_handler+0x70>
}
ffffffffc0200b32:	60a2                	ld	ra,8(sp)
ffffffffc0200b34:	0141                	addi	sp,sp,16
                    sbi_shutdown(); // 关机
ffffffffc0200b36:	2c20106f          	j	ffffffffc0201df8 <sbi_shutdown>

ffffffffc0200b3a <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b3a:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b3e:	1141                	addi	sp,sp,-16
ffffffffc0200b40:	e022                	sd	s0,0(sp)
ffffffffc0200b42:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b44:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b46:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b48:	04e78663          	beq	a5,a4,ffffffffc0200b94 <exception_handler+0x5a>
ffffffffc0200b4c:	02f76c63          	bltu	a4,a5,ffffffffc0200b84 <exception_handler+0x4a>
ffffffffc0200b50:	4709                	li	a4,2
        case CAUSE_FAULT_FETCH:
            break;
case CAUSE_ILLEGAL_INSTRUCTION:
            // 非法指令异常处理
            // LAB3 CHALLENGE3   YOUR CODE : 
            cprintf("Illegal instruction\n"); // (1)
ffffffffc0200b52:	00002517          	auipc	a0,0x2
ffffffffc0200b56:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202758 <commands+0x648>
    switch (tf->cause) {
ffffffffc0200b5a:	02e79163          	bne	a5,a4,ffffffffc0200b7c <exception_handler+0x42>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            // LAB3 CHALLLENGE3   YOUR CODE :  
             cprintf("Breakpoint\n"); // (1)
ffffffffc0200b5e:	d7aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            cprintf("epc = 0x%lx\n", tf->epc); // (2)
ffffffffc0200b62:	10843583          	ld	a1,264(s0)
ffffffffc0200b66:	00002517          	auipc	a0,0x2
ffffffffc0200b6a:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202770 <commands+0x660>
ffffffffc0200b6e:	d6aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200b72:	10843783          	ld	a5,264(s0)
ffffffffc0200b76:	0791                	addi	a5,a5,4
ffffffffc0200b78:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b7c:	60a2                	ld	ra,8(sp)
ffffffffc0200b7e:	6402                	ld	s0,0(sp)
ffffffffc0200b80:	0141                	addi	sp,sp,16
ffffffffc0200b82:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b84:	17f1                	addi	a5,a5,-4
ffffffffc0200b86:	471d                	li	a4,7
ffffffffc0200b88:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b7c <exception_handler+0x42>
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
ffffffffc0200b90:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b92:	b561                	j	ffffffffc0200a1a <print_trapframe>
             cprintf("Breakpoint\n"); // (1)
ffffffffc0200b94:	00002517          	auipc	a0,0x2
ffffffffc0200b98:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202780 <commands+0x670>
ffffffffc0200b9c:	b7c9                	j	ffffffffc0200b5e <exception_handler+0x24>

ffffffffc0200b9e <trap>:


static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b9e:	11853783          	ld	a5,280(a0)
ffffffffc0200ba2:	0007c363          	bltz	a5,ffffffffc0200ba8 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200ba6:	bf51                	j	ffffffffc0200b3a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ba8:	bdd1                	j	ffffffffc0200a7c <interrupt_handler>
	...

ffffffffc0200bac <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200bac:	14011073          	csrw	sscratch,sp
ffffffffc0200bb0:	712d                	addi	sp,sp,-288
ffffffffc0200bb2:	e002                	sd	zero,0(sp)
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
ffffffffc0200bb6:	ec0e                	sd	gp,24(sp)
ffffffffc0200bb8:	f012                	sd	tp,32(sp)
ffffffffc0200bba:	f416                	sd	t0,40(sp)
ffffffffc0200bbc:	f81a                	sd	t1,48(sp)
ffffffffc0200bbe:	fc1e                	sd	t2,56(sp)
ffffffffc0200bc0:	e0a2                	sd	s0,64(sp)
ffffffffc0200bc2:	e4a6                	sd	s1,72(sp)
ffffffffc0200bc4:	e8aa                	sd	a0,80(sp)
ffffffffc0200bc6:	ecae                	sd	a1,88(sp)
ffffffffc0200bc8:	f0b2                	sd	a2,96(sp)
ffffffffc0200bca:	f4b6                	sd	a3,104(sp)
ffffffffc0200bcc:	f8ba                	sd	a4,112(sp)
ffffffffc0200bce:	fcbe                	sd	a5,120(sp)
ffffffffc0200bd0:	e142                	sd	a6,128(sp)
ffffffffc0200bd2:	e546                	sd	a7,136(sp)
ffffffffc0200bd4:	e94a                	sd	s2,144(sp)
ffffffffc0200bd6:	ed4e                	sd	s3,152(sp)
ffffffffc0200bd8:	f152                	sd	s4,160(sp)
ffffffffc0200bda:	f556                	sd	s5,168(sp)
ffffffffc0200bdc:	f95a                	sd	s6,176(sp)
ffffffffc0200bde:	fd5e                	sd	s7,184(sp)
ffffffffc0200be0:	e1e2                	sd	s8,192(sp)
ffffffffc0200be2:	e5e6                	sd	s9,200(sp)
ffffffffc0200be4:	e9ea                	sd	s10,208(sp)
ffffffffc0200be6:	edee                	sd	s11,216(sp)
ffffffffc0200be8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bea:	f5f6                	sd	t4,232(sp)
ffffffffc0200bec:	f9fa                	sd	t5,240(sp)
ffffffffc0200bee:	fdfe                	sd	t6,248(sp)
ffffffffc0200bf0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200bf4:	100024f3          	csrr	s1,sstatus
ffffffffc0200bf8:	14102973          	csrr	s2,sepc
ffffffffc0200bfc:	143029f3          	csrr	s3,stval
ffffffffc0200c00:	14202a73          	csrr	s4,scause
ffffffffc0200c04:	e822                	sd	s0,16(sp)
ffffffffc0200c06:	e226                	sd	s1,256(sp)
ffffffffc0200c08:	e64a                	sd	s2,264(sp)
ffffffffc0200c0a:	ea4e                	sd	s3,272(sp)
ffffffffc0200c0c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c0e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c10:	f8fff0ef          	jal	ra,ffffffffc0200b9e <trap>

ffffffffc0200c14 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c14:	6492                	ld	s1,256(sp)
ffffffffc0200c16:	6932                	ld	s2,264(sp)
ffffffffc0200c18:	10049073          	csrw	sstatus,s1
ffffffffc0200c1c:	14191073          	csrw	sepc,s2
ffffffffc0200c20:	60a2                	ld	ra,8(sp)
ffffffffc0200c22:	61e2                	ld	gp,24(sp)
ffffffffc0200c24:	7202                	ld	tp,32(sp)
ffffffffc0200c26:	72a2                	ld	t0,40(sp)
ffffffffc0200c28:	7342                	ld	t1,48(sp)
ffffffffc0200c2a:	73e2                	ld	t2,56(sp)
ffffffffc0200c2c:	6406                	ld	s0,64(sp)
ffffffffc0200c2e:	64a6                	ld	s1,72(sp)
ffffffffc0200c30:	6546                	ld	a0,80(sp)
ffffffffc0200c32:	65e6                	ld	a1,88(sp)
ffffffffc0200c34:	7606                	ld	a2,96(sp)
ffffffffc0200c36:	76a6                	ld	a3,104(sp)
ffffffffc0200c38:	7746                	ld	a4,112(sp)
ffffffffc0200c3a:	77e6                	ld	a5,120(sp)
ffffffffc0200c3c:	680a                	ld	a6,128(sp)
ffffffffc0200c3e:	68aa                	ld	a7,136(sp)
ffffffffc0200c40:	694a                	ld	s2,144(sp)
ffffffffc0200c42:	69ea                	ld	s3,152(sp)
ffffffffc0200c44:	7a0a                	ld	s4,160(sp)
ffffffffc0200c46:	7aaa                	ld	s5,168(sp)
ffffffffc0200c48:	7b4a                	ld	s6,176(sp)
ffffffffc0200c4a:	7bea                	ld	s7,184(sp)
ffffffffc0200c4c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c4e:	6cae                	ld	s9,200(sp)
ffffffffc0200c50:	6d4e                	ld	s10,208(sp)
ffffffffc0200c52:	6dee                	ld	s11,216(sp)
ffffffffc0200c54:	7e0e                	ld	t3,224(sp)
ffffffffc0200c56:	7eae                	ld	t4,232(sp)
ffffffffc0200c58:	7f4e                	ld	t5,240(sp)
ffffffffc0200c5a:	7fee                	ld	t6,248(sp)
ffffffffc0200c5c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c5e:	10200073          	sret

ffffffffc0200c62 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c62:	00005797          	auipc	a5,0x5
ffffffffc0200c66:	3c678793          	addi	a5,a5,966 # ffffffffc0206028 <free_area>
ffffffffc0200c6a:	e79c                	sd	a5,8(a5)
ffffffffc0200c6c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c6e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c72:	8082                	ret

ffffffffc0200c74 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c74:	00005517          	auipc	a0,0x5
ffffffffc0200c78:	3c456503          	lwu	a0,964(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200c7c:	8082                	ret

ffffffffc0200c7e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200c7e:	c14d                	beqz	a0,ffffffffc0200d20 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200c80:	00005617          	auipc	a2,0x5
ffffffffc0200c84:	3a860613          	addi	a2,a2,936 # ffffffffc0206028 <free_area>
ffffffffc0200c88:	01062803          	lw	a6,16(a2)
ffffffffc0200c8c:	86aa                	mv	a3,a0
ffffffffc0200c8e:	02081793          	slli	a5,a6,0x20
ffffffffc0200c92:	9381                	srli	a5,a5,0x20
ffffffffc0200c94:	08a7e463          	bltu	a5,a0,ffffffffc0200d1c <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c98:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200c9a:	0018059b          	addiw	a1,a6,1
ffffffffc0200c9e:	1582                	slli	a1,a1,0x20
ffffffffc0200ca0:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200ca2:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ca4:	06c78b63          	beq	a5,a2,ffffffffc0200d1a <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200ca8:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200cac:	00d76763          	bltu	a4,a3,ffffffffc0200cba <best_fit_alloc_pages+0x3c>
ffffffffc0200cb0:	00b77563          	bgeu	a4,a1,ffffffffc0200cba <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200cb4:	fe878513          	addi	a0,a5,-24
ffffffffc0200cb8:	85ba                	mv	a1,a4
ffffffffc0200cba:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cbc:	fec796e3          	bne	a5,a2,ffffffffc0200ca8 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200cc0:	cd29                	beqz	a0,ffffffffc0200d1a <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200cc2:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200cc4:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200cc6:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200cc8:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200ccc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200cce:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200cd0:	02059793          	slli	a5,a1,0x20
ffffffffc0200cd4:	9381                	srli	a5,a5,0x20
ffffffffc0200cd6:	02f6f863          	bgeu	a3,a5,ffffffffc0200d06 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200cda:	00269793          	slli	a5,a3,0x2
ffffffffc0200cde:	97b6                	add	a5,a5,a3
ffffffffc0200ce0:	078e                	slli	a5,a5,0x3
ffffffffc0200ce2:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200ce4:	411585bb          	subw	a1,a1,a7
ffffffffc0200ce8:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200cea:	4689                	li	a3,2
ffffffffc0200cec:	00878593          	addi	a1,a5,8
ffffffffc0200cf0:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200cf4:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200cf6:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200cfa:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200cfe:	e28c                	sd	a1,0(a3)
ffffffffc0200d00:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200d02:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200d04:	ef98                	sd	a4,24(a5)
ffffffffc0200d06:	4118083b          	subw	a6,a6,a7
ffffffffc0200d0a:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200d0e:	57f5                	li	a5,-3
ffffffffc0200d10:	00850713          	addi	a4,a0,8
ffffffffc0200d14:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200d18:	8082                	ret
}
ffffffffc0200d1a:	8082                	ret
        return NULL;
ffffffffc0200d1c:	4501                	li	a0,0
ffffffffc0200d1e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200d20:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200d22:	00002697          	auipc	a3,0x2
ffffffffc0200d26:	a6e68693          	addi	a3,a3,-1426 # ffffffffc0202790 <commands+0x680>
ffffffffc0200d2a:	00002617          	auipc	a2,0x2
ffffffffc0200d2e:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0202798 <commands+0x688>
ffffffffc0200d32:	06b00593          	li	a1,107
ffffffffc0200d36:	00002517          	auipc	a0,0x2
ffffffffc0200d3a:	a7a50513          	addi	a0,a0,-1414 # ffffffffc02027b0 <commands+0x6a0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d3e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d40:	e92ff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0200d44 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200d44:	715d                	addi	sp,sp,-80
ffffffffc0200d46:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200d48:	00005417          	auipc	s0,0x5
ffffffffc0200d4c:	2e040413          	addi	s0,s0,736 # ffffffffc0206028 <free_area>
ffffffffc0200d50:	641c                	ld	a5,8(s0)
ffffffffc0200d52:	e486                	sd	ra,72(sp)
ffffffffc0200d54:	fc26                	sd	s1,56(sp)
ffffffffc0200d56:	f84a                	sd	s2,48(sp)
ffffffffc0200d58:	f44e                	sd	s3,40(sp)
ffffffffc0200d5a:	f052                	sd	s4,32(sp)
ffffffffc0200d5c:	ec56                	sd	s5,24(sp)
ffffffffc0200d5e:	e85a                	sd	s6,16(sp)
ffffffffc0200d60:	e45e                	sd	s7,8(sp)
ffffffffc0200d62:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d64:	26878b63          	beq	a5,s0,ffffffffc0200fda <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200d68:	4481                	li	s1,0
ffffffffc0200d6a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d6c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d70:	8b09                	andi	a4,a4,2
ffffffffc0200d72:	26070863          	beqz	a4,ffffffffc0200fe2 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200d76:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d7a:	679c                	ld	a5,8(a5)
ffffffffc0200d7c:	2905                	addiw	s2,s2,1
ffffffffc0200d7e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d80:	fe8796e3          	bne	a5,s0,ffffffffc0200d6c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200d84:	89a6                	mv	s3,s1
ffffffffc0200d86:	167000ef          	jal	ra,ffffffffc02016ec <nr_free_pages>
ffffffffc0200d8a:	33351c63          	bne	a0,s3,ffffffffc02010c2 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d8e:	4505                	li	a0,1
ffffffffc0200d90:	0df000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200d94:	8a2a                	mv	s4,a0
ffffffffc0200d96:	36050663          	beqz	a0,ffffffffc0201102 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d9a:	4505                	li	a0,1
ffffffffc0200d9c:	0d3000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200da0:	89aa                	mv	s3,a0
ffffffffc0200da2:	34050063          	beqz	a0,ffffffffc02010e2 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200da6:	4505                	li	a0,1
ffffffffc0200da8:	0c7000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200dac:	8aaa                	mv	s5,a0
ffffffffc0200dae:	2c050a63          	beqz	a0,ffffffffc0201082 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200db2:	253a0863          	beq	s4,s3,ffffffffc0201002 <best_fit_check+0x2be>
ffffffffc0200db6:	24aa0663          	beq	s4,a0,ffffffffc0201002 <best_fit_check+0x2be>
ffffffffc0200dba:	24a98463          	beq	s3,a0,ffffffffc0201002 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dbe:	000a2783          	lw	a5,0(s4)
ffffffffc0200dc2:	26079063          	bnez	a5,ffffffffc0201022 <best_fit_check+0x2de>
ffffffffc0200dc6:	0009a783          	lw	a5,0(s3)
ffffffffc0200dca:	24079c63          	bnez	a5,ffffffffc0201022 <best_fit_check+0x2de>
ffffffffc0200dce:	411c                	lw	a5,0(a0)
ffffffffc0200dd0:	24079963          	bnez	a5,ffffffffc0201022 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dd4:	00005797          	auipc	a5,0x5
ffffffffc0200dd8:	69c7b783          	ld	a5,1692(a5) # ffffffffc0206470 <pages>
ffffffffc0200ddc:	40fa0733          	sub	a4,s4,a5
ffffffffc0200de0:	870d                	srai	a4,a4,0x3
ffffffffc0200de2:	00002597          	auipc	a1,0x2
ffffffffc0200de6:	0be5b583          	ld	a1,190(a1) # ffffffffc0202ea0 <error_string+0x38>
ffffffffc0200dea:	02b70733          	mul	a4,a4,a1
ffffffffc0200dee:	00002617          	auipc	a2,0x2
ffffffffc0200df2:	0ba63603          	ld	a2,186(a2) # ffffffffc0202ea8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200df6:	00005697          	auipc	a3,0x5
ffffffffc0200dfa:	6726b683          	ld	a3,1650(a3) # ffffffffc0206468 <npage>
ffffffffc0200dfe:	06b2                	slli	a3,a3,0xc
ffffffffc0200e00:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e02:	0732                	slli	a4,a4,0xc
ffffffffc0200e04:	22d77f63          	bgeu	a4,a3,ffffffffc0201042 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e08:	40f98733          	sub	a4,s3,a5
ffffffffc0200e0c:	870d                	srai	a4,a4,0x3
ffffffffc0200e0e:	02b70733          	mul	a4,a4,a1
ffffffffc0200e12:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e14:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e16:	3ed77663          	bgeu	a4,a3,ffffffffc0201202 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e1a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e1e:	878d                	srai	a5,a5,0x3
ffffffffc0200e20:	02b787b3          	mul	a5,a5,a1
ffffffffc0200e24:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e26:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e28:	3ad7fd63          	bgeu	a5,a3,ffffffffc02011e2 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200e2c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e2e:	00043c03          	ld	s8,0(s0)
ffffffffc0200e32:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e36:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e3a:	e400                	sd	s0,8(s0)
ffffffffc0200e3c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e3e:	00005797          	auipc	a5,0x5
ffffffffc0200e42:	1e07ad23          	sw	zero,506(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e46:	029000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200e4a:	36051c63          	bnez	a0,ffffffffc02011c2 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200e4e:	4585                	li	a1,1
ffffffffc0200e50:	8552                	mv	a0,s4
ffffffffc0200e52:	05b000ef          	jal	ra,ffffffffc02016ac <free_pages>
    free_page(p1);
ffffffffc0200e56:	4585                	li	a1,1
ffffffffc0200e58:	854e                	mv	a0,s3
ffffffffc0200e5a:	053000ef          	jal	ra,ffffffffc02016ac <free_pages>
    free_page(p2);
ffffffffc0200e5e:	4585                	li	a1,1
ffffffffc0200e60:	8556                	mv	a0,s5
ffffffffc0200e62:	04b000ef          	jal	ra,ffffffffc02016ac <free_pages>
    assert(nr_free == 3);
ffffffffc0200e66:	4818                	lw	a4,16(s0)
ffffffffc0200e68:	478d                	li	a5,3
ffffffffc0200e6a:	32f71c63          	bne	a4,a5,ffffffffc02011a2 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e6e:	4505                	li	a0,1
ffffffffc0200e70:	7fe000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200e74:	89aa                	mv	s3,a0
ffffffffc0200e76:	30050663          	beqz	a0,ffffffffc0201182 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e7a:	4505                	li	a0,1
ffffffffc0200e7c:	7f2000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200e80:	8aaa                	mv	s5,a0
ffffffffc0200e82:	2e050063          	beqz	a0,ffffffffc0201162 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e86:	4505                	li	a0,1
ffffffffc0200e88:	7e6000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200e8c:	8a2a                	mv	s4,a0
ffffffffc0200e8e:	2a050a63          	beqz	a0,ffffffffc0201142 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200e92:	4505                	li	a0,1
ffffffffc0200e94:	7da000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200e98:	28051563          	bnez	a0,ffffffffc0201122 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200e9c:	4585                	li	a1,1
ffffffffc0200e9e:	854e                	mv	a0,s3
ffffffffc0200ea0:	00d000ef          	jal	ra,ffffffffc02016ac <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ea4:	641c                	ld	a5,8(s0)
ffffffffc0200ea6:	1a878e63          	beq	a5,s0,ffffffffc0201062 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200eaa:	4505                	li	a0,1
ffffffffc0200eac:	7c2000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200eb0:	52a99963          	bne	s3,a0,ffffffffc02013e2 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200eb4:	4505                	li	a0,1
ffffffffc0200eb6:	7b8000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200eba:	50051463          	bnez	a0,ffffffffc02013c2 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200ebe:	481c                	lw	a5,16(s0)
ffffffffc0200ec0:	4e079163          	bnez	a5,ffffffffc02013a2 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200ec4:	854e                	mv	a0,s3
ffffffffc0200ec6:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ec8:	01843023          	sd	s8,0(s0)
ffffffffc0200ecc:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200ed0:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200ed4:	7d8000ef          	jal	ra,ffffffffc02016ac <free_pages>
    free_page(p1);
ffffffffc0200ed8:	4585                	li	a1,1
ffffffffc0200eda:	8556                	mv	a0,s5
ffffffffc0200edc:	7d0000ef          	jal	ra,ffffffffc02016ac <free_pages>
    free_page(p2);
ffffffffc0200ee0:	4585                	li	a1,1
ffffffffc0200ee2:	8552                	mv	a0,s4
ffffffffc0200ee4:	7c8000ef          	jal	ra,ffffffffc02016ac <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200ee8:	4515                	li	a0,5
ffffffffc0200eea:	784000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200eee:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200ef0:	48050963          	beqz	a0,ffffffffc0201382 <best_fit_check+0x63e>
ffffffffc0200ef4:	651c                	ld	a5,8(a0)
ffffffffc0200ef6:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200ef8:	8b85                	andi	a5,a5,1
ffffffffc0200efa:	46079463          	bnez	a5,ffffffffc0201362 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200efe:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f00:	00043a83          	ld	s5,0(s0)
ffffffffc0200f04:	00843a03          	ld	s4,8(s0)
ffffffffc0200f08:	e000                	sd	s0,0(s0)
ffffffffc0200f0a:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f0c:	762000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200f10:	42051963          	bnez	a0,ffffffffc0201342 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f14:	4589                	li	a1,2
ffffffffc0200f16:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200f1a:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200f1e:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200f22:	00005797          	auipc	a5,0x5
ffffffffc0200f26:	1007ab23          	sw	zero,278(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200f2a:	782000ef          	jal	ra,ffffffffc02016ac <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200f2e:	8562                	mv	a0,s8
ffffffffc0200f30:	4585                	li	a1,1
ffffffffc0200f32:	77a000ef          	jal	ra,ffffffffc02016ac <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f36:	4511                	li	a0,4
ffffffffc0200f38:	736000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200f3c:	3e051363          	bnez	a0,ffffffffc0201322 <best_fit_check+0x5de>
ffffffffc0200f40:	0309b783          	ld	a5,48(s3)
ffffffffc0200f44:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f46:	8b85                	andi	a5,a5,1
ffffffffc0200f48:	3a078d63          	beqz	a5,ffffffffc0201302 <best_fit_check+0x5be>
ffffffffc0200f4c:	0389a703          	lw	a4,56(s3)
ffffffffc0200f50:	4789                	li	a5,2
ffffffffc0200f52:	3af71863          	bne	a4,a5,ffffffffc0201302 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f56:	4505                	li	a0,1
ffffffffc0200f58:	716000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200f5c:	8baa                	mv	s7,a0
ffffffffc0200f5e:	38050263          	beqz	a0,ffffffffc02012e2 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f62:	4509                	li	a0,2
ffffffffc0200f64:	70a000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200f68:	34050d63          	beqz	a0,ffffffffc02012c2 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200f6c:	337c1b63          	bne	s8,s7,ffffffffc02012a2 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200f70:	854e                	mv	a0,s3
ffffffffc0200f72:	4595                	li	a1,5
ffffffffc0200f74:	738000ef          	jal	ra,ffffffffc02016ac <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f78:	4515                	li	a0,5
ffffffffc0200f7a:	6f4000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200f7e:	89aa                	mv	s3,a0
ffffffffc0200f80:	30050163          	beqz	a0,ffffffffc0201282 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200f84:	4505                	li	a0,1
ffffffffc0200f86:	6e8000ef          	jal	ra,ffffffffc020166e <alloc_pages>
ffffffffc0200f8a:	2c051c63          	bnez	a0,ffffffffc0201262 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200f8e:	481c                	lw	a5,16(s0)
ffffffffc0200f90:	2a079963          	bnez	a5,ffffffffc0201242 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f94:	4595                	li	a1,5
ffffffffc0200f96:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f98:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200f9c:	01543023          	sd	s5,0(s0)
ffffffffc0200fa0:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200fa4:	708000ef          	jal	ra,ffffffffc02016ac <free_pages>
    return listelm->next;
ffffffffc0200fa8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200faa:	00878963          	beq	a5,s0,ffffffffc0200fbc <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fae:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fb2:	679c                	ld	a5,8(a5)
ffffffffc0200fb4:	397d                	addiw	s2,s2,-1
ffffffffc0200fb6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fb8:	fe879be3          	bne	a5,s0,ffffffffc0200fae <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200fbc:	26091363          	bnez	s2,ffffffffc0201222 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200fc0:	e0ed                	bnez	s1,ffffffffc02010a2 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200fc2:	60a6                	ld	ra,72(sp)
ffffffffc0200fc4:	6406                	ld	s0,64(sp)
ffffffffc0200fc6:	74e2                	ld	s1,56(sp)
ffffffffc0200fc8:	7942                	ld	s2,48(sp)
ffffffffc0200fca:	79a2                	ld	s3,40(sp)
ffffffffc0200fcc:	7a02                	ld	s4,32(sp)
ffffffffc0200fce:	6ae2                	ld	s5,24(sp)
ffffffffc0200fd0:	6b42                	ld	s6,16(sp)
ffffffffc0200fd2:	6ba2                	ld	s7,8(sp)
ffffffffc0200fd4:	6c02                	ld	s8,0(sp)
ffffffffc0200fd6:	6161                	addi	sp,sp,80
ffffffffc0200fd8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fda:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200fdc:	4481                	li	s1,0
ffffffffc0200fde:	4901                	li	s2,0
ffffffffc0200fe0:	b35d                	j	ffffffffc0200d86 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200fe2:	00001697          	auipc	a3,0x1
ffffffffc0200fe6:	7e668693          	addi	a3,a3,2022 # ffffffffc02027c8 <commands+0x6b8>
ffffffffc0200fea:	00001617          	auipc	a2,0x1
ffffffffc0200fee:	7ae60613          	addi	a2,a2,1966 # ffffffffc0202798 <commands+0x688>
ffffffffc0200ff2:	10d00593          	li	a1,269
ffffffffc0200ff6:	00001517          	auipc	a0,0x1
ffffffffc0200ffa:	7ba50513          	addi	a0,a0,1978 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc0200ffe:	bd4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201002:	00002697          	auipc	a3,0x2
ffffffffc0201006:	85668693          	addi	a3,a3,-1962 # ffffffffc0202858 <commands+0x748>
ffffffffc020100a:	00001617          	auipc	a2,0x1
ffffffffc020100e:	78e60613          	addi	a2,a2,1934 # ffffffffc0202798 <commands+0x688>
ffffffffc0201012:	0d900593          	li	a1,217
ffffffffc0201016:	00001517          	auipc	a0,0x1
ffffffffc020101a:	79a50513          	addi	a0,a0,1946 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020101e:	bb4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201022:	00002697          	auipc	a3,0x2
ffffffffc0201026:	85e68693          	addi	a3,a3,-1954 # ffffffffc0202880 <commands+0x770>
ffffffffc020102a:	00001617          	auipc	a2,0x1
ffffffffc020102e:	76e60613          	addi	a2,a2,1902 # ffffffffc0202798 <commands+0x688>
ffffffffc0201032:	0da00593          	li	a1,218
ffffffffc0201036:	00001517          	auipc	a0,0x1
ffffffffc020103a:	77a50513          	addi	a0,a0,1914 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020103e:	b94ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201042:	00002697          	auipc	a3,0x2
ffffffffc0201046:	87e68693          	addi	a3,a3,-1922 # ffffffffc02028c0 <commands+0x7b0>
ffffffffc020104a:	00001617          	auipc	a2,0x1
ffffffffc020104e:	74e60613          	addi	a2,a2,1870 # ffffffffc0202798 <commands+0x688>
ffffffffc0201052:	0dc00593          	li	a1,220
ffffffffc0201056:	00001517          	auipc	a0,0x1
ffffffffc020105a:	75a50513          	addi	a0,a0,1882 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020105e:	b74ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201062:	00002697          	auipc	a3,0x2
ffffffffc0201066:	8e668693          	addi	a3,a3,-1818 # ffffffffc0202948 <commands+0x838>
ffffffffc020106a:	00001617          	auipc	a2,0x1
ffffffffc020106e:	72e60613          	addi	a2,a2,1838 # ffffffffc0202798 <commands+0x688>
ffffffffc0201072:	0f500593          	li	a1,245
ffffffffc0201076:	00001517          	auipc	a0,0x1
ffffffffc020107a:	73a50513          	addi	a0,a0,1850 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020107e:	b54ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201082:	00001697          	auipc	a3,0x1
ffffffffc0201086:	7b668693          	addi	a3,a3,1974 # ffffffffc0202838 <commands+0x728>
ffffffffc020108a:	00001617          	auipc	a2,0x1
ffffffffc020108e:	70e60613          	addi	a2,a2,1806 # ffffffffc0202798 <commands+0x688>
ffffffffc0201092:	0d700593          	li	a1,215
ffffffffc0201096:	00001517          	auipc	a0,0x1
ffffffffc020109a:	71a50513          	addi	a0,a0,1818 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020109e:	b34ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == 0);
ffffffffc02010a2:	00002697          	auipc	a3,0x2
ffffffffc02010a6:	9d668693          	addi	a3,a3,-1578 # ffffffffc0202a78 <commands+0x968>
ffffffffc02010aa:	00001617          	auipc	a2,0x1
ffffffffc02010ae:	6ee60613          	addi	a2,a2,1774 # ffffffffc0202798 <commands+0x688>
ffffffffc02010b2:	14f00593          	li	a1,335
ffffffffc02010b6:	00001517          	auipc	a0,0x1
ffffffffc02010ba:	6fa50513          	addi	a0,a0,1786 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02010be:	b14ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == nr_free_pages());
ffffffffc02010c2:	00001697          	auipc	a3,0x1
ffffffffc02010c6:	71668693          	addi	a3,a3,1814 # ffffffffc02027d8 <commands+0x6c8>
ffffffffc02010ca:	00001617          	auipc	a2,0x1
ffffffffc02010ce:	6ce60613          	addi	a2,a2,1742 # ffffffffc0202798 <commands+0x688>
ffffffffc02010d2:	11000593          	li	a1,272
ffffffffc02010d6:	00001517          	auipc	a0,0x1
ffffffffc02010da:	6da50513          	addi	a0,a0,1754 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02010de:	af4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010e2:	00001697          	auipc	a3,0x1
ffffffffc02010e6:	73668693          	addi	a3,a3,1846 # ffffffffc0202818 <commands+0x708>
ffffffffc02010ea:	00001617          	auipc	a2,0x1
ffffffffc02010ee:	6ae60613          	addi	a2,a2,1710 # ffffffffc0202798 <commands+0x688>
ffffffffc02010f2:	0d600593          	li	a1,214
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	6ba50513          	addi	a0,a0,1722 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02010fe:	ad4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201102:	00001697          	auipc	a3,0x1
ffffffffc0201106:	6f668693          	addi	a3,a3,1782 # ffffffffc02027f8 <commands+0x6e8>
ffffffffc020110a:	00001617          	auipc	a2,0x1
ffffffffc020110e:	68e60613          	addi	a2,a2,1678 # ffffffffc0202798 <commands+0x688>
ffffffffc0201112:	0d500593          	li	a1,213
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	69a50513          	addi	a0,a0,1690 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020111e:	ab4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201122:	00001697          	auipc	a3,0x1
ffffffffc0201126:	7fe68693          	addi	a3,a3,2046 # ffffffffc0202920 <commands+0x810>
ffffffffc020112a:	00001617          	auipc	a2,0x1
ffffffffc020112e:	66e60613          	addi	a2,a2,1646 # ffffffffc0202798 <commands+0x688>
ffffffffc0201132:	0f200593          	li	a1,242
ffffffffc0201136:	00001517          	auipc	a0,0x1
ffffffffc020113a:	67a50513          	addi	a0,a0,1658 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020113e:	a94ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201142:	00001697          	auipc	a3,0x1
ffffffffc0201146:	6f668693          	addi	a3,a3,1782 # ffffffffc0202838 <commands+0x728>
ffffffffc020114a:	00001617          	auipc	a2,0x1
ffffffffc020114e:	64e60613          	addi	a2,a2,1614 # ffffffffc0202798 <commands+0x688>
ffffffffc0201152:	0f000593          	li	a1,240
ffffffffc0201156:	00001517          	auipc	a0,0x1
ffffffffc020115a:	65a50513          	addi	a0,a0,1626 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020115e:	a74ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201162:	00001697          	auipc	a3,0x1
ffffffffc0201166:	6b668693          	addi	a3,a3,1718 # ffffffffc0202818 <commands+0x708>
ffffffffc020116a:	00001617          	auipc	a2,0x1
ffffffffc020116e:	62e60613          	addi	a2,a2,1582 # ffffffffc0202798 <commands+0x688>
ffffffffc0201172:	0ef00593          	li	a1,239
ffffffffc0201176:	00001517          	auipc	a0,0x1
ffffffffc020117a:	63a50513          	addi	a0,a0,1594 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020117e:	a54ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201182:	00001697          	auipc	a3,0x1
ffffffffc0201186:	67668693          	addi	a3,a3,1654 # ffffffffc02027f8 <commands+0x6e8>
ffffffffc020118a:	00001617          	auipc	a2,0x1
ffffffffc020118e:	60e60613          	addi	a2,a2,1550 # ffffffffc0202798 <commands+0x688>
ffffffffc0201192:	0ee00593          	li	a1,238
ffffffffc0201196:	00001517          	auipc	a0,0x1
ffffffffc020119a:	61a50513          	addi	a0,a0,1562 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020119e:	a34ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 3);
ffffffffc02011a2:	00001697          	auipc	a3,0x1
ffffffffc02011a6:	79668693          	addi	a3,a3,1942 # ffffffffc0202938 <commands+0x828>
ffffffffc02011aa:	00001617          	auipc	a2,0x1
ffffffffc02011ae:	5ee60613          	addi	a2,a2,1518 # ffffffffc0202798 <commands+0x688>
ffffffffc02011b2:	0ec00593          	li	a1,236
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	5fa50513          	addi	a0,a0,1530 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02011be:	a14ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c2:	00001697          	auipc	a3,0x1
ffffffffc02011c6:	75e68693          	addi	a3,a3,1886 # ffffffffc0202920 <commands+0x810>
ffffffffc02011ca:	00001617          	auipc	a2,0x1
ffffffffc02011ce:	5ce60613          	addi	a2,a2,1486 # ffffffffc0202798 <commands+0x688>
ffffffffc02011d2:	0e700593          	li	a1,231
ffffffffc02011d6:	00001517          	auipc	a0,0x1
ffffffffc02011da:	5da50513          	addi	a0,a0,1498 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02011de:	9f4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011e2:	00001697          	auipc	a3,0x1
ffffffffc02011e6:	71e68693          	addi	a3,a3,1822 # ffffffffc0202900 <commands+0x7f0>
ffffffffc02011ea:	00001617          	auipc	a2,0x1
ffffffffc02011ee:	5ae60613          	addi	a2,a2,1454 # ffffffffc0202798 <commands+0x688>
ffffffffc02011f2:	0de00593          	li	a1,222
ffffffffc02011f6:	00001517          	auipc	a0,0x1
ffffffffc02011fa:	5ba50513          	addi	a0,a0,1466 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02011fe:	9d4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201202:	00001697          	auipc	a3,0x1
ffffffffc0201206:	6de68693          	addi	a3,a3,1758 # ffffffffc02028e0 <commands+0x7d0>
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	58e60613          	addi	a2,a2,1422 # ffffffffc0202798 <commands+0x688>
ffffffffc0201212:	0dd00593          	li	a1,221
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	59a50513          	addi	a0,a0,1434 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020121e:	9b4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(count == 0);
ffffffffc0201222:	00002697          	auipc	a3,0x2
ffffffffc0201226:	84668693          	addi	a3,a3,-1978 # ffffffffc0202a68 <commands+0x958>
ffffffffc020122a:	00001617          	auipc	a2,0x1
ffffffffc020122e:	56e60613          	addi	a2,a2,1390 # ffffffffc0202798 <commands+0x688>
ffffffffc0201232:	14e00593          	li	a1,334
ffffffffc0201236:	00001517          	auipc	a0,0x1
ffffffffc020123a:	57a50513          	addi	a0,a0,1402 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020123e:	994ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0201242:	00001697          	auipc	a3,0x1
ffffffffc0201246:	73e68693          	addi	a3,a3,1854 # ffffffffc0202980 <commands+0x870>
ffffffffc020124a:	00001617          	auipc	a2,0x1
ffffffffc020124e:	54e60613          	addi	a2,a2,1358 # ffffffffc0202798 <commands+0x688>
ffffffffc0201252:	14300593          	li	a1,323
ffffffffc0201256:	00001517          	auipc	a0,0x1
ffffffffc020125a:	55a50513          	addi	a0,a0,1370 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020125e:	974ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201262:	00001697          	auipc	a3,0x1
ffffffffc0201266:	6be68693          	addi	a3,a3,1726 # ffffffffc0202920 <commands+0x810>
ffffffffc020126a:	00001617          	auipc	a2,0x1
ffffffffc020126e:	52e60613          	addi	a2,a2,1326 # ffffffffc0202798 <commands+0x688>
ffffffffc0201272:	13d00593          	li	a1,317
ffffffffc0201276:	00001517          	auipc	a0,0x1
ffffffffc020127a:	53a50513          	addi	a0,a0,1338 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020127e:	954ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201282:	00001697          	auipc	a3,0x1
ffffffffc0201286:	7c668693          	addi	a3,a3,1990 # ffffffffc0202a48 <commands+0x938>
ffffffffc020128a:	00001617          	auipc	a2,0x1
ffffffffc020128e:	50e60613          	addi	a2,a2,1294 # ffffffffc0202798 <commands+0x688>
ffffffffc0201292:	13c00593          	li	a1,316
ffffffffc0201296:	00001517          	auipc	a0,0x1
ffffffffc020129a:	51a50513          	addi	a0,a0,1306 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020129e:	934ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc02012a2:	00001697          	auipc	a3,0x1
ffffffffc02012a6:	79668693          	addi	a3,a3,1942 # ffffffffc0202a38 <commands+0x928>
ffffffffc02012aa:	00001617          	auipc	a2,0x1
ffffffffc02012ae:	4ee60613          	addi	a2,a2,1262 # ffffffffc0202798 <commands+0x688>
ffffffffc02012b2:	13400593          	li	a1,308
ffffffffc02012b6:	00001517          	auipc	a0,0x1
ffffffffc02012ba:	4fa50513          	addi	a0,a0,1274 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02012be:	914ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02012c2:	00001697          	auipc	a3,0x1
ffffffffc02012c6:	75e68693          	addi	a3,a3,1886 # ffffffffc0202a20 <commands+0x910>
ffffffffc02012ca:	00001617          	auipc	a2,0x1
ffffffffc02012ce:	4ce60613          	addi	a2,a2,1230 # ffffffffc0202798 <commands+0x688>
ffffffffc02012d2:	13300593          	li	a1,307
ffffffffc02012d6:	00001517          	auipc	a0,0x1
ffffffffc02012da:	4da50513          	addi	a0,a0,1242 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02012de:	8f4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02012e2:	00001697          	auipc	a3,0x1
ffffffffc02012e6:	71e68693          	addi	a3,a3,1822 # ffffffffc0202a00 <commands+0x8f0>
ffffffffc02012ea:	00001617          	auipc	a2,0x1
ffffffffc02012ee:	4ae60613          	addi	a2,a2,1198 # ffffffffc0202798 <commands+0x688>
ffffffffc02012f2:	13200593          	li	a1,306
ffffffffc02012f6:	00001517          	auipc	a0,0x1
ffffffffc02012fa:	4ba50513          	addi	a0,a0,1210 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02012fe:	8d4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201302:	00001697          	auipc	a3,0x1
ffffffffc0201306:	6ce68693          	addi	a3,a3,1742 # ffffffffc02029d0 <commands+0x8c0>
ffffffffc020130a:	00001617          	auipc	a2,0x1
ffffffffc020130e:	48e60613          	addi	a2,a2,1166 # ffffffffc0202798 <commands+0x688>
ffffffffc0201312:	13000593          	li	a1,304
ffffffffc0201316:	00001517          	auipc	a0,0x1
ffffffffc020131a:	49a50513          	addi	a0,a0,1178 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020131e:	8b4ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201322:	00001697          	auipc	a3,0x1
ffffffffc0201326:	69668693          	addi	a3,a3,1686 # ffffffffc02029b8 <commands+0x8a8>
ffffffffc020132a:	00001617          	auipc	a2,0x1
ffffffffc020132e:	46e60613          	addi	a2,a2,1134 # ffffffffc0202798 <commands+0x688>
ffffffffc0201332:	12f00593          	li	a1,303
ffffffffc0201336:	00001517          	auipc	a0,0x1
ffffffffc020133a:	47a50513          	addi	a0,a0,1146 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020133e:	894ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201342:	00001697          	auipc	a3,0x1
ffffffffc0201346:	5de68693          	addi	a3,a3,1502 # ffffffffc0202920 <commands+0x810>
ffffffffc020134a:	00001617          	auipc	a2,0x1
ffffffffc020134e:	44e60613          	addi	a2,a2,1102 # ffffffffc0202798 <commands+0x688>
ffffffffc0201352:	12300593          	li	a1,291
ffffffffc0201356:	00001517          	auipc	a0,0x1
ffffffffc020135a:	45a50513          	addi	a0,a0,1114 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020135e:	874ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201362:	00001697          	auipc	a3,0x1
ffffffffc0201366:	63e68693          	addi	a3,a3,1598 # ffffffffc02029a0 <commands+0x890>
ffffffffc020136a:	00001617          	auipc	a2,0x1
ffffffffc020136e:	42e60613          	addi	a2,a2,1070 # ffffffffc0202798 <commands+0x688>
ffffffffc0201372:	11a00593          	li	a1,282
ffffffffc0201376:	00001517          	auipc	a0,0x1
ffffffffc020137a:	43a50513          	addi	a0,a0,1082 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020137e:	854ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != NULL);
ffffffffc0201382:	00001697          	auipc	a3,0x1
ffffffffc0201386:	60e68693          	addi	a3,a3,1550 # ffffffffc0202990 <commands+0x880>
ffffffffc020138a:	00001617          	auipc	a2,0x1
ffffffffc020138e:	40e60613          	addi	a2,a2,1038 # ffffffffc0202798 <commands+0x688>
ffffffffc0201392:	11900593          	li	a1,281
ffffffffc0201396:	00001517          	auipc	a0,0x1
ffffffffc020139a:	41a50513          	addi	a0,a0,1050 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020139e:	834ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc02013a2:	00001697          	auipc	a3,0x1
ffffffffc02013a6:	5de68693          	addi	a3,a3,1502 # ffffffffc0202980 <commands+0x870>
ffffffffc02013aa:	00001617          	auipc	a2,0x1
ffffffffc02013ae:	3ee60613          	addi	a2,a2,1006 # ffffffffc0202798 <commands+0x688>
ffffffffc02013b2:	0fb00593          	li	a1,251
ffffffffc02013b6:	00001517          	auipc	a0,0x1
ffffffffc02013ba:	3fa50513          	addi	a0,a0,1018 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02013be:	814ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c2:	00001697          	auipc	a3,0x1
ffffffffc02013c6:	55e68693          	addi	a3,a3,1374 # ffffffffc0202920 <commands+0x810>
ffffffffc02013ca:	00001617          	auipc	a2,0x1
ffffffffc02013ce:	3ce60613          	addi	a2,a2,974 # ffffffffc0202798 <commands+0x688>
ffffffffc02013d2:	0f900593          	li	a1,249
ffffffffc02013d6:	00001517          	auipc	a0,0x1
ffffffffc02013da:	3da50513          	addi	a0,a0,986 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02013de:	ff5fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02013e2:	00001697          	auipc	a3,0x1
ffffffffc02013e6:	57e68693          	addi	a3,a3,1406 # ffffffffc0202960 <commands+0x850>
ffffffffc02013ea:	00001617          	auipc	a2,0x1
ffffffffc02013ee:	3ae60613          	addi	a2,a2,942 # ffffffffc0202798 <commands+0x688>
ffffffffc02013f2:	0f800593          	li	a1,248
ffffffffc02013f6:	00001517          	auipc	a0,0x1
ffffffffc02013fa:	3ba50513          	addi	a0,a0,954 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc02013fe:	fd5fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201402 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201402:	1141                	addi	sp,sp,-16
ffffffffc0201404:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201406:	14058a63          	beqz	a1,ffffffffc020155a <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020140a:	00259693          	slli	a3,a1,0x2
ffffffffc020140e:	96ae                	add	a3,a3,a1
ffffffffc0201410:	068e                	slli	a3,a3,0x3
ffffffffc0201412:	96aa                	add	a3,a3,a0
ffffffffc0201414:	87aa                	mv	a5,a0
ffffffffc0201416:	02d50263          	beq	a0,a3,ffffffffc020143a <best_fit_free_pages+0x38>
ffffffffc020141a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020141c:	8b05                	andi	a4,a4,1
ffffffffc020141e:	10071e63          	bnez	a4,ffffffffc020153a <best_fit_free_pages+0x138>
ffffffffc0201422:	6798                	ld	a4,8(a5)
ffffffffc0201424:	8b09                	andi	a4,a4,2
ffffffffc0201426:	10071a63          	bnez	a4,ffffffffc020153a <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc020142a:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020142e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201432:	02878793          	addi	a5,a5,40
ffffffffc0201436:	fed792e3          	bne	a5,a3,ffffffffc020141a <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc020143a:	2581                	sext.w	a1,a1
ffffffffc020143c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020143e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201442:	4789                	li	a5,2
ffffffffc0201444:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201448:	00005697          	auipc	a3,0x5
ffffffffc020144c:	be068693          	addi	a3,a3,-1056 # ffffffffc0206028 <free_area>
ffffffffc0201450:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201452:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201454:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201458:	9db9                	addw	a1,a1,a4
ffffffffc020145a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020145c:	0ad78863          	beq	a5,a3,ffffffffc020150c <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201460:	fe878713          	addi	a4,a5,-24
ffffffffc0201464:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201468:	4581                	li	a1,0
            if (base < page) {
ffffffffc020146a:	00e56a63          	bltu	a0,a4,ffffffffc020147e <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020146e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201470:	06d70263          	beq	a4,a3,ffffffffc02014d4 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201474:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201476:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020147a:	fee57ae3          	bgeu	a0,a4,ffffffffc020146e <best_fit_free_pages+0x6c>
ffffffffc020147e:	c199                	beqz	a1,ffffffffc0201484 <best_fit_free_pages+0x82>
ffffffffc0201480:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201484:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201486:	e390                	sd	a2,0(a5)
ffffffffc0201488:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020148a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020148c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020148e:	02d70063          	beq	a4,a3,ffffffffc02014ae <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201492:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201496:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020149a:	02081613          	slli	a2,a6,0x20
ffffffffc020149e:	9201                	srli	a2,a2,0x20
ffffffffc02014a0:	00261793          	slli	a5,a2,0x2
ffffffffc02014a4:	97b2                	add	a5,a5,a2
ffffffffc02014a6:	078e                	slli	a5,a5,0x3
ffffffffc02014a8:	97ae                	add	a5,a5,a1
ffffffffc02014aa:	02f50f63          	beq	a0,a5,ffffffffc02014e8 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02014ae:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014b0:	00d70f63          	beq	a4,a3,ffffffffc02014ce <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02014b4:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014b6:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014ba:	02059613          	slli	a2,a1,0x20
ffffffffc02014be:	9201                	srli	a2,a2,0x20
ffffffffc02014c0:	00261793          	slli	a5,a2,0x2
ffffffffc02014c4:	97b2                	add	a5,a5,a2
ffffffffc02014c6:	078e                	slli	a5,a5,0x3
ffffffffc02014c8:	97aa                	add	a5,a5,a0
ffffffffc02014ca:	04f68863          	beq	a3,a5,ffffffffc020151a <best_fit_free_pages+0x118>
}
ffffffffc02014ce:	60a2                	ld	ra,8(sp)
ffffffffc02014d0:	0141                	addi	sp,sp,16
ffffffffc02014d2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014d4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014d6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014d8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014da:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014dc:	02d70563          	beq	a4,a3,ffffffffc0201506 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02014e0:	8832                	mv	a6,a2
ffffffffc02014e2:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02014e4:	87ba                	mv	a5,a4
ffffffffc02014e6:	bf41                	j	ffffffffc0201476 <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc02014e8:	491c                	lw	a5,16(a0)
ffffffffc02014ea:	0107883b          	addw	a6,a5,a6
ffffffffc02014ee:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014f2:	57f5                	li	a5,-3
ffffffffc02014f4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014f8:	6d10                	ld	a2,24(a0)
ffffffffc02014fa:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014fc:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02014fe:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201500:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201502:	e390                	sd	a2,0(a5)
ffffffffc0201504:	b775                	j	ffffffffc02014b0 <best_fit_free_pages+0xae>
ffffffffc0201506:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201508:	873e                	mv	a4,a5
ffffffffc020150a:	b761                	j	ffffffffc0201492 <best_fit_free_pages+0x90>
}
ffffffffc020150c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020150e:	e390                	sd	a2,0(a5)
ffffffffc0201510:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201512:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201514:	ed1c                	sd	a5,24(a0)
ffffffffc0201516:	0141                	addi	sp,sp,16
ffffffffc0201518:	8082                	ret
            base->property += p->property;
ffffffffc020151a:	ff872783          	lw	a5,-8(a4)
ffffffffc020151e:	ff070693          	addi	a3,a4,-16
ffffffffc0201522:	9dbd                	addw	a1,a1,a5
ffffffffc0201524:	c90c                	sw	a1,16(a0)
ffffffffc0201526:	57f5                	li	a5,-3
ffffffffc0201528:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020152c:	6314                	ld	a3,0(a4)
ffffffffc020152e:	671c                	ld	a5,8(a4)
}
ffffffffc0201530:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201532:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201534:	e394                	sd	a3,0(a5)
ffffffffc0201536:	0141                	addi	sp,sp,16
ffffffffc0201538:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020153a:	00001697          	auipc	a3,0x1
ffffffffc020153e:	54e68693          	addi	a3,a3,1358 # ffffffffc0202a88 <commands+0x978>
ffffffffc0201542:	00001617          	auipc	a2,0x1
ffffffffc0201546:	25660613          	addi	a2,a2,598 # ffffffffc0202798 <commands+0x688>
ffffffffc020154a:	09300593          	li	a1,147
ffffffffc020154e:	00001517          	auipc	a0,0x1
ffffffffc0201552:	26250513          	addi	a0,a0,610 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc0201556:	e7dfe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc020155a:	00001697          	auipc	a3,0x1
ffffffffc020155e:	23668693          	addi	a3,a3,566 # ffffffffc0202790 <commands+0x680>
ffffffffc0201562:	00001617          	auipc	a2,0x1
ffffffffc0201566:	23660613          	addi	a2,a2,566 # ffffffffc0202798 <commands+0x688>
ffffffffc020156a:	09000593          	li	a1,144
ffffffffc020156e:	00001517          	auipc	a0,0x1
ffffffffc0201572:	24250513          	addi	a0,a0,578 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc0201576:	e5dfe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020157a <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020157a:	1141                	addi	sp,sp,-16
ffffffffc020157c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020157e:	c9e1                	beqz	a1,ffffffffc020164e <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201580:	00259693          	slli	a3,a1,0x2
ffffffffc0201584:	96ae                	add	a3,a3,a1
ffffffffc0201586:	068e                	slli	a3,a3,0x3
ffffffffc0201588:	96aa                	add	a3,a3,a0
ffffffffc020158a:	87aa                	mv	a5,a0
ffffffffc020158c:	00d50f63          	beq	a0,a3,ffffffffc02015aa <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201590:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201592:	8b05                	andi	a4,a4,1
ffffffffc0201594:	cf49                	beqz	a4,ffffffffc020162e <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201596:	0007a823          	sw	zero,16(a5)
ffffffffc020159a:	0007b423          	sd	zero,8(a5)
ffffffffc020159e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015a2:	02878793          	addi	a5,a5,40
ffffffffc02015a6:	fed795e3          	bne	a5,a3,ffffffffc0201590 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02015aa:	2581                	sext.w	a1,a1
ffffffffc02015ac:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015ae:	4789                	li	a5,2
ffffffffc02015b0:	00850713          	addi	a4,a0,8
ffffffffc02015b4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206028 <free_area>
ffffffffc02015c0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015c2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015c4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015c8:	9db9                	addw	a1,a1,a4
ffffffffc02015ca:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015cc:	04d78a63          	beq	a5,a3,ffffffffc0201620 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02015d0:	fe878713          	addi	a4,a5,-24
ffffffffc02015d4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015d8:	4581                	li	a1,0
            if (base < page) {
ffffffffc02015da:	00e56a63          	bltu	a0,a4,ffffffffc02015ee <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc02015de:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015e0:	02d70263          	beq	a4,a3,ffffffffc0201604 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02015e4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015e6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015ea:	fee57ae3          	bgeu	a0,a4,ffffffffc02015de <best_fit_init_memmap+0x64>
ffffffffc02015ee:	c199                	beqz	a1,ffffffffc02015f4 <best_fit_init_memmap+0x7a>
ffffffffc02015f0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015f4:	6398                	ld	a4,0(a5)
}
ffffffffc02015f6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015f8:	e390                	sd	a2,0(a5)
ffffffffc02015fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015fe:	ed18                	sd	a4,24(a0)
ffffffffc0201600:	0141                	addi	sp,sp,16
ffffffffc0201602:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201604:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201606:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201608:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020160a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020160c:	00d70663          	beq	a4,a3,ffffffffc0201618 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201610:	8832                	mv	a6,a2
ffffffffc0201612:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201614:	87ba                	mv	a5,a4
ffffffffc0201616:	bfc1                	j	ffffffffc02015e6 <best_fit_init_memmap+0x6c>
}
ffffffffc0201618:	60a2                	ld	ra,8(sp)
ffffffffc020161a:	e290                	sd	a2,0(a3)
ffffffffc020161c:	0141                	addi	sp,sp,16
ffffffffc020161e:	8082                	ret
ffffffffc0201620:	60a2                	ld	ra,8(sp)
ffffffffc0201622:	e390                	sd	a2,0(a5)
ffffffffc0201624:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201626:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201628:	ed1c                	sd	a5,24(a0)
ffffffffc020162a:	0141                	addi	sp,sp,16
ffffffffc020162c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020162e:	00001697          	auipc	a3,0x1
ffffffffc0201632:	48268693          	addi	a3,a3,1154 # ffffffffc0202ab0 <commands+0x9a0>
ffffffffc0201636:	00001617          	auipc	a2,0x1
ffffffffc020163a:	16260613          	addi	a2,a2,354 # ffffffffc0202798 <commands+0x688>
ffffffffc020163e:	04b00593          	li	a1,75
ffffffffc0201642:	00001517          	auipc	a0,0x1
ffffffffc0201646:	16e50513          	addi	a0,a0,366 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020164a:	d89fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc020164e:	00001697          	auipc	a3,0x1
ffffffffc0201652:	14268693          	addi	a3,a3,322 # ffffffffc0202790 <commands+0x680>
ffffffffc0201656:	00001617          	auipc	a2,0x1
ffffffffc020165a:	14260613          	addi	a2,a2,322 # ffffffffc0202798 <commands+0x688>
ffffffffc020165e:	04800593          	li	a1,72
ffffffffc0201662:	00001517          	auipc	a0,0x1
ffffffffc0201666:	14e50513          	addi	a0,a0,334 # ffffffffc02027b0 <commands+0x6a0>
ffffffffc020166a:	d69fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020166e <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020166e:	100027f3          	csrr	a5,sstatus
ffffffffc0201672:	8b89                	andi	a5,a5,2
ffffffffc0201674:	e799                	bnez	a5,ffffffffc0201682 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201676:	00005797          	auipc	a5,0x5
ffffffffc020167a:	e027b783          	ld	a5,-510(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020167e:	6f9c                	ld	a5,24(a5)
ffffffffc0201680:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201682:	1141                	addi	sp,sp,-16
ffffffffc0201684:	e406                	sd	ra,8(sp)
ffffffffc0201686:	e022                	sd	s0,0(sp)
ffffffffc0201688:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020168a:	9aaff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020168e:	00005797          	auipc	a5,0x5
ffffffffc0201692:	dea7b783          	ld	a5,-534(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201696:	6f9c                	ld	a5,24(a5)
ffffffffc0201698:	8522                	mv	a0,s0
ffffffffc020169a:	9782                	jalr	a5
ffffffffc020169c:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020169e:	990ff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02016a2:	60a2                	ld	ra,8(sp)
ffffffffc02016a4:	8522                	mv	a0,s0
ffffffffc02016a6:	6402                	ld	s0,0(sp)
ffffffffc02016a8:	0141                	addi	sp,sp,16
ffffffffc02016aa:	8082                	ret

ffffffffc02016ac <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016ac:	100027f3          	csrr	a5,sstatus
ffffffffc02016b0:	8b89                	andi	a5,a5,2
ffffffffc02016b2:	e799                	bnez	a5,ffffffffc02016c0 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02016b4:	00005797          	auipc	a5,0x5
ffffffffc02016b8:	dc47b783          	ld	a5,-572(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016bc:	739c                	ld	a5,32(a5)
ffffffffc02016be:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02016c0:	1101                	addi	sp,sp,-32
ffffffffc02016c2:	ec06                	sd	ra,24(sp)
ffffffffc02016c4:	e822                	sd	s0,16(sp)
ffffffffc02016c6:	e426                	sd	s1,8(sp)
ffffffffc02016c8:	842a                	mv	s0,a0
ffffffffc02016ca:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02016cc:	968ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02016d0:	00005797          	auipc	a5,0x5
ffffffffc02016d4:	da87b783          	ld	a5,-600(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016d8:	739c                	ld	a5,32(a5)
ffffffffc02016da:	85a6                	mv	a1,s1
ffffffffc02016dc:	8522                	mv	a0,s0
ffffffffc02016de:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02016e0:	6442                	ld	s0,16(sp)
ffffffffc02016e2:	60e2                	ld	ra,24(sp)
ffffffffc02016e4:	64a2                	ld	s1,8(sp)
ffffffffc02016e6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02016e8:	946ff06f          	j	ffffffffc020082e <intr_enable>

ffffffffc02016ec <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016ec:	100027f3          	csrr	a5,sstatus
ffffffffc02016f0:	8b89                	andi	a5,a5,2
ffffffffc02016f2:	e799                	bnez	a5,ffffffffc0201700 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02016f4:	00005797          	auipc	a5,0x5
ffffffffc02016f8:	d847b783          	ld	a5,-636(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016fc:	779c                	ld	a5,40(a5)
ffffffffc02016fe:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201700:	1141                	addi	sp,sp,-16
ffffffffc0201702:	e406                	sd	ra,8(sp)
ffffffffc0201704:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201706:	92eff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020170a:	00005797          	auipc	a5,0x5
ffffffffc020170e:	d6e7b783          	ld	a5,-658(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201712:	779c                	ld	a5,40(a5)
ffffffffc0201714:	9782                	jalr	a5
ffffffffc0201716:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201718:	916ff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020171c:	60a2                	ld	ra,8(sp)
ffffffffc020171e:	8522                	mv	a0,s0
ffffffffc0201720:	6402                	ld	s0,0(sp)
ffffffffc0201722:	0141                	addi	sp,sp,16
ffffffffc0201724:	8082                	ret

ffffffffc0201726 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201726:	00001797          	auipc	a5,0x1
ffffffffc020172a:	3b278793          	addi	a5,a5,946 # ffffffffc0202ad8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020172e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201730:	7179                	addi	sp,sp,-48
ffffffffc0201732:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201734:	00001517          	auipc	a0,0x1
ffffffffc0201738:	3dc50513          	addi	a0,a0,988 # ffffffffc0202b10 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020173c:	00005417          	auipc	s0,0x5
ffffffffc0201740:	d3c40413          	addi	s0,s0,-708 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201744:	f406                	sd	ra,40(sp)
ffffffffc0201746:	ec26                	sd	s1,24(sp)
ffffffffc0201748:	e44e                	sd	s3,8(sp)
ffffffffc020174a:	e84a                	sd	s2,16(sp)
ffffffffc020174c:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020174e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201750:	989fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0201754:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201756:	00005497          	auipc	s1,0x5
ffffffffc020175a:	d3a48493          	addi	s1,s1,-710 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc020175e:	679c                	ld	a5,8(a5)
ffffffffc0201760:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201762:	57f5                	li	a5,-3
ffffffffc0201764:	07fa                	slli	a5,a5,0x1e
ffffffffc0201766:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201768:	8b2ff0ef          	jal	ra,ffffffffc020081a <get_memory_base>
ffffffffc020176c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020176e:	8b6ff0ef          	jal	ra,ffffffffc0200824 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201772:	16050163          	beqz	a0,ffffffffc02018d4 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201776:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201778:	00001517          	auipc	a0,0x1
ffffffffc020177c:	3e050513          	addi	a0,a0,992 # ffffffffc0202b58 <best_fit_pmm_manager+0x80>
ffffffffc0201780:	959fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201784:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201788:	864e                	mv	a2,s3
ffffffffc020178a:	fffa0693          	addi	a3,s4,-1
ffffffffc020178e:	85ca                	mv	a1,s2
ffffffffc0201790:	00001517          	auipc	a0,0x1
ffffffffc0201794:	3e050513          	addi	a0,a0,992 # ffffffffc0202b70 <best_fit_pmm_manager+0x98>
ffffffffc0201798:	941fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020179c:	c80007b7          	lui	a5,0xc8000
ffffffffc02017a0:	8652                	mv	a2,s4
ffffffffc02017a2:	0d47e863          	bltu	a5,s4,ffffffffc0201872 <pmm_init+0x14c>
ffffffffc02017a6:	00006797          	auipc	a5,0x6
ffffffffc02017aa:	cf978793          	addi	a5,a5,-775 # ffffffffc020749f <end+0xfff>
ffffffffc02017ae:	757d                	lui	a0,0xfffff
ffffffffc02017b0:	8d7d                	and	a0,a0,a5
ffffffffc02017b2:	8231                	srli	a2,a2,0xc
ffffffffc02017b4:	00005597          	auipc	a1,0x5
ffffffffc02017b8:	cb458593          	addi	a1,a1,-844 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017bc:	00005817          	auipc	a6,0x5
ffffffffc02017c0:	cb480813          	addi	a6,a6,-844 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02017c4:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017c6:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017ca:	000807b7          	lui	a5,0x80
ffffffffc02017ce:	02f60663          	beq	a2,a5,ffffffffc02017fa <pmm_init+0xd4>
ffffffffc02017d2:	4701                	li	a4,0
ffffffffc02017d4:	4781                	li	a5,0
ffffffffc02017d6:	4305                	li	t1,1
ffffffffc02017d8:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc02017dc:	953a                	add	a0,a0,a4
ffffffffc02017de:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc02017e2:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017e6:	6190                	ld	a2,0(a1)
ffffffffc02017e8:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02017ea:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017ee:	011606b3          	add	a3,a2,a7
ffffffffc02017f2:	02870713          	addi	a4,a4,40
ffffffffc02017f6:	fed7e3e3          	bltu	a5,a3,ffffffffc02017dc <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02017fa:	00261693          	slli	a3,a2,0x2
ffffffffc02017fe:	96b2                	add	a3,a3,a2
ffffffffc0201800:	fec007b7          	lui	a5,0xfec00
ffffffffc0201804:	97aa                	add	a5,a5,a0
ffffffffc0201806:	068e                	slli	a3,a3,0x3
ffffffffc0201808:	96be                	add	a3,a3,a5
ffffffffc020180a:	c02007b7          	lui	a5,0xc0200
ffffffffc020180e:	0af6e763          	bltu	a3,a5,ffffffffc02018bc <pmm_init+0x196>
ffffffffc0201812:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201814:	77fd                	lui	a5,0xfffff
ffffffffc0201816:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020181a:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020181c:	04b6ee63          	bltu	a3,a1,ffffffffc0201878 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201820:	601c                	ld	a5,0(s0)
ffffffffc0201822:	7b9c                	ld	a5,48(a5)
ffffffffc0201824:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201826:	00001517          	auipc	a0,0x1
ffffffffc020182a:	3d250513          	addi	a0,a0,978 # ffffffffc0202bf8 <best_fit_pmm_manager+0x120>
ffffffffc020182e:	8abfe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201832:	00003597          	auipc	a1,0x3
ffffffffc0201836:	7ce58593          	addi	a1,a1,1998 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020183a:	00005797          	auipc	a5,0x5
ffffffffc020183e:	c4b7b723          	sd	a1,-946(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201842:	c02007b7          	lui	a5,0xc0200
ffffffffc0201846:	0af5e363          	bltu	a1,a5,ffffffffc02018ec <pmm_init+0x1c6>
ffffffffc020184a:	6090                	ld	a2,0(s1)
}
ffffffffc020184c:	7402                	ld	s0,32(sp)
ffffffffc020184e:	70a2                	ld	ra,40(sp)
ffffffffc0201850:	64e2                	ld	s1,24(sp)
ffffffffc0201852:	6942                	ld	s2,16(sp)
ffffffffc0201854:	69a2                	ld	s3,8(sp)
ffffffffc0201856:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201858:	40c58633          	sub	a2,a1,a2
ffffffffc020185c:	00005797          	auipc	a5,0x5
ffffffffc0201860:	c2c7b223          	sd	a2,-988(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201864:	00001517          	auipc	a0,0x1
ffffffffc0201868:	3b450513          	addi	a0,a0,948 # ffffffffc0202c18 <best_fit_pmm_manager+0x140>
}
ffffffffc020186c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020186e:	86bfe06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201872:	c8000637          	lui	a2,0xc8000
ffffffffc0201876:	bf05                	j	ffffffffc02017a6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201878:	6705                	lui	a4,0x1
ffffffffc020187a:	177d                	addi	a4,a4,-1
ffffffffc020187c:	96ba                	add	a3,a3,a4
ffffffffc020187e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201880:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201884:	02c7f063          	bgeu	a5,a2,ffffffffc02018a4 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201888:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020188a:	fff80737          	lui	a4,0xfff80
ffffffffc020188e:	973e                	add	a4,a4,a5
ffffffffc0201890:	00271793          	slli	a5,a4,0x2
ffffffffc0201894:	97ba                	add	a5,a5,a4
ffffffffc0201896:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201898:	8d95                	sub	a1,a1,a3
ffffffffc020189a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020189c:	81b1                	srli	a1,a1,0xc
ffffffffc020189e:	953e                	add	a0,a0,a5
ffffffffc02018a0:	9702                	jalr	a4
}
ffffffffc02018a2:	bfbd                	j	ffffffffc0201820 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02018a4:	00001617          	auipc	a2,0x1
ffffffffc02018a8:	32460613          	addi	a2,a2,804 # ffffffffc0202bc8 <best_fit_pmm_manager+0xf0>
ffffffffc02018ac:	06b00593          	li	a1,107
ffffffffc02018b0:	00001517          	auipc	a0,0x1
ffffffffc02018b4:	33850513          	addi	a0,a0,824 # ffffffffc0202be8 <best_fit_pmm_manager+0x110>
ffffffffc02018b8:	b1bfe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018bc:	00001617          	auipc	a2,0x1
ffffffffc02018c0:	2e460613          	addi	a2,a2,740 # ffffffffc0202ba0 <best_fit_pmm_manager+0xc8>
ffffffffc02018c4:	07100593          	li	a1,113
ffffffffc02018c8:	00001517          	auipc	a0,0x1
ffffffffc02018cc:	28050513          	addi	a0,a0,640 # ffffffffc0202b48 <best_fit_pmm_manager+0x70>
ffffffffc02018d0:	b03fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
        panic("DTB memory info not available");
ffffffffc02018d4:	00001617          	auipc	a2,0x1
ffffffffc02018d8:	25460613          	addi	a2,a2,596 # ffffffffc0202b28 <best_fit_pmm_manager+0x50>
ffffffffc02018dc:	05a00593          	li	a1,90
ffffffffc02018e0:	00001517          	auipc	a0,0x1
ffffffffc02018e4:	26850513          	addi	a0,a0,616 # ffffffffc0202b48 <best_fit_pmm_manager+0x70>
ffffffffc02018e8:	aebfe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018ec:	86ae                	mv	a3,a1
ffffffffc02018ee:	00001617          	auipc	a2,0x1
ffffffffc02018f2:	2b260613          	addi	a2,a2,690 # ffffffffc0202ba0 <best_fit_pmm_manager+0xc8>
ffffffffc02018f6:	08c00593          	li	a1,140
ffffffffc02018fa:	00001517          	auipc	a0,0x1
ffffffffc02018fe:	24e50513          	addi	a0,a0,590 # ffffffffc0202b48 <best_fit_pmm_manager+0x70>
ffffffffc0201902:	ad1fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201906 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201906:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020190a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020190c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201910:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201912:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201916:	f022                	sd	s0,32(sp)
ffffffffc0201918:	ec26                	sd	s1,24(sp)
ffffffffc020191a:	e84a                	sd	s2,16(sp)
ffffffffc020191c:	f406                	sd	ra,40(sp)
ffffffffc020191e:	e44e                	sd	s3,8(sp)
ffffffffc0201920:	84aa                	mv	s1,a0
ffffffffc0201922:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201924:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201928:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020192a:	03067e63          	bgeu	a2,a6,ffffffffc0201966 <printnum+0x60>
ffffffffc020192e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201930:	00805763          	blez	s0,ffffffffc020193e <printnum+0x38>
ffffffffc0201934:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201936:	85ca                	mv	a1,s2
ffffffffc0201938:	854e                	mv	a0,s3
ffffffffc020193a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020193c:	fc65                	bnez	s0,ffffffffc0201934 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020193e:	1a02                	slli	s4,s4,0x20
ffffffffc0201940:	00001797          	auipc	a5,0x1
ffffffffc0201944:	31878793          	addi	a5,a5,792 # ffffffffc0202c58 <best_fit_pmm_manager+0x180>
ffffffffc0201948:	020a5a13          	srli	s4,s4,0x20
ffffffffc020194c:	9a3e                	add	s4,s4,a5
}
ffffffffc020194e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201950:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201954:	70a2                	ld	ra,40(sp)
ffffffffc0201956:	69a2                	ld	s3,8(sp)
ffffffffc0201958:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020195a:	85ca                	mv	a1,s2
ffffffffc020195c:	87a6                	mv	a5,s1
}
ffffffffc020195e:	6942                	ld	s2,16(sp)
ffffffffc0201960:	64e2                	ld	s1,24(sp)
ffffffffc0201962:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201964:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201966:	03065633          	divu	a2,a2,a6
ffffffffc020196a:	8722                	mv	a4,s0
ffffffffc020196c:	f9bff0ef          	jal	ra,ffffffffc0201906 <printnum>
ffffffffc0201970:	b7f9                	j	ffffffffc020193e <printnum+0x38>

ffffffffc0201972 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201972:	7119                	addi	sp,sp,-128
ffffffffc0201974:	f4a6                	sd	s1,104(sp)
ffffffffc0201976:	f0ca                	sd	s2,96(sp)
ffffffffc0201978:	ecce                	sd	s3,88(sp)
ffffffffc020197a:	e8d2                	sd	s4,80(sp)
ffffffffc020197c:	e4d6                	sd	s5,72(sp)
ffffffffc020197e:	e0da                	sd	s6,64(sp)
ffffffffc0201980:	fc5e                	sd	s7,56(sp)
ffffffffc0201982:	f06a                	sd	s10,32(sp)
ffffffffc0201984:	fc86                	sd	ra,120(sp)
ffffffffc0201986:	f8a2                	sd	s0,112(sp)
ffffffffc0201988:	f862                	sd	s8,48(sp)
ffffffffc020198a:	f466                	sd	s9,40(sp)
ffffffffc020198c:	ec6e                	sd	s11,24(sp)
ffffffffc020198e:	892a                	mv	s2,a0
ffffffffc0201990:	84ae                	mv	s1,a1
ffffffffc0201992:	8d32                	mv	s10,a2
ffffffffc0201994:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201996:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020199a:	5b7d                	li	s6,-1
ffffffffc020199c:	00001a97          	auipc	s5,0x1
ffffffffc02019a0:	2f0a8a93          	addi	s5,s5,752 # ffffffffc0202c8c <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019a4:	00001b97          	auipc	s7,0x1
ffffffffc02019a8:	4c4b8b93          	addi	s7,s7,1220 # ffffffffc0202e68 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019ac:	000d4503          	lbu	a0,0(s10)
ffffffffc02019b0:	001d0413          	addi	s0,s10,1
ffffffffc02019b4:	01350a63          	beq	a0,s3,ffffffffc02019c8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02019b8:	c121                	beqz	a0,ffffffffc02019f8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02019ba:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019bc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02019be:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019c0:	fff44503          	lbu	a0,-1(s0)
ffffffffc02019c4:	ff351ae3          	bne	a0,s3,ffffffffc02019b8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019c8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02019cc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02019d0:	4c81                	li	s9,0
ffffffffc02019d2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02019d4:	5c7d                	li	s8,-1
ffffffffc02019d6:	5dfd                	li	s11,-1
ffffffffc02019d8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02019dc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019de:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02019e2:	0ff5f593          	zext.b	a1,a1
ffffffffc02019e6:	00140d13          	addi	s10,s0,1
ffffffffc02019ea:	04b56263          	bltu	a0,a1,ffffffffc0201a2e <vprintfmt+0xbc>
ffffffffc02019ee:	058a                	slli	a1,a1,0x2
ffffffffc02019f0:	95d6                	add	a1,a1,s5
ffffffffc02019f2:	4194                	lw	a3,0(a1)
ffffffffc02019f4:	96d6                	add	a3,a3,s5
ffffffffc02019f6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02019f8:	70e6                	ld	ra,120(sp)
ffffffffc02019fa:	7446                	ld	s0,112(sp)
ffffffffc02019fc:	74a6                	ld	s1,104(sp)
ffffffffc02019fe:	7906                	ld	s2,96(sp)
ffffffffc0201a00:	69e6                	ld	s3,88(sp)
ffffffffc0201a02:	6a46                	ld	s4,80(sp)
ffffffffc0201a04:	6aa6                	ld	s5,72(sp)
ffffffffc0201a06:	6b06                	ld	s6,64(sp)
ffffffffc0201a08:	7be2                	ld	s7,56(sp)
ffffffffc0201a0a:	7c42                	ld	s8,48(sp)
ffffffffc0201a0c:	7ca2                	ld	s9,40(sp)
ffffffffc0201a0e:	7d02                	ld	s10,32(sp)
ffffffffc0201a10:	6de2                	ld	s11,24(sp)
ffffffffc0201a12:	6109                	addi	sp,sp,128
ffffffffc0201a14:	8082                	ret
            padc = '0';
ffffffffc0201a16:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a18:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a1c:	846a                	mv	s0,s10
ffffffffc0201a1e:	00140d13          	addi	s10,s0,1
ffffffffc0201a22:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a26:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a2a:	fcb572e3          	bgeu	a0,a1,ffffffffc02019ee <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201a2e:	85a6                	mv	a1,s1
ffffffffc0201a30:	02500513          	li	a0,37
ffffffffc0201a34:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a36:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a3a:	8d22                	mv	s10,s0
ffffffffc0201a3c:	f73788e3          	beq	a5,s3,ffffffffc02019ac <vprintfmt+0x3a>
ffffffffc0201a40:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a44:	1d7d                	addi	s10,s10,-1
ffffffffc0201a46:	ff379de3          	bne	a5,s3,ffffffffc0201a40 <vprintfmt+0xce>
ffffffffc0201a4a:	b78d                	j	ffffffffc02019ac <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201a4c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201a50:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a54:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201a56:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201a5a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201a5e:	02d86463          	bltu	a6,a3,ffffffffc0201a86 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201a62:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201a66:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201a6a:	0186873b          	addw	a4,a3,s8
ffffffffc0201a6e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201a72:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201a74:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201a78:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201a7a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201a7e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201a82:	fed870e3          	bgeu	a6,a3,ffffffffc0201a62 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201a86:	f40ddce3          	bgez	s11,ffffffffc02019de <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201a8a:	8de2                	mv	s11,s8
ffffffffc0201a8c:	5c7d                	li	s8,-1
ffffffffc0201a8e:	bf81                	j	ffffffffc02019de <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201a90:	fffdc693          	not	a3,s11
ffffffffc0201a94:	96fd                	srai	a3,a3,0x3f
ffffffffc0201a96:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a9a:	00144603          	lbu	a2,1(s0)
ffffffffc0201a9e:	2d81                	sext.w	s11,s11
ffffffffc0201aa0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201aa2:	bf35                	j	ffffffffc02019de <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201aa4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201aac:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aae:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201ab0:	bfd9                	j	ffffffffc0201a86 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201ab2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ab4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ab8:	01174463          	blt	a4,a7,ffffffffc0201ac0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201abc:	1a088e63          	beqz	a7,ffffffffc0201c78 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201ac0:	000a3603          	ld	a2,0(s4)
ffffffffc0201ac4:	46c1                	li	a3,16
ffffffffc0201ac6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201ac8:	2781                	sext.w	a5,a5
ffffffffc0201aca:	876e                	mv	a4,s11
ffffffffc0201acc:	85a6                	mv	a1,s1
ffffffffc0201ace:	854a                	mv	a0,s2
ffffffffc0201ad0:	e37ff0ef          	jal	ra,ffffffffc0201906 <printnum>
            break;
ffffffffc0201ad4:	bde1                	j	ffffffffc02019ac <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ad6:	000a2503          	lw	a0,0(s4)
ffffffffc0201ada:	85a6                	mv	a1,s1
ffffffffc0201adc:	0a21                	addi	s4,s4,8
ffffffffc0201ade:	9902                	jalr	s2
            break;
ffffffffc0201ae0:	b5f1                	j	ffffffffc02019ac <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201ae2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ae4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ae8:	01174463          	blt	a4,a7,ffffffffc0201af0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201aec:	18088163          	beqz	a7,ffffffffc0201c6e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201af0:	000a3603          	ld	a2,0(s4)
ffffffffc0201af4:	46a9                	li	a3,10
ffffffffc0201af6:	8a2e                	mv	s4,a1
ffffffffc0201af8:	bfc1                	j	ffffffffc0201ac8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201afa:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201afe:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b00:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b02:	bdf1                	j	ffffffffc02019de <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b04:	85a6                	mv	a1,s1
ffffffffc0201b06:	02500513          	li	a0,37
ffffffffc0201b0a:	9902                	jalr	s2
            break;
ffffffffc0201b0c:	b545                	j	ffffffffc02019ac <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b0e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b12:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b14:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b16:	b5e1                	j	ffffffffc02019de <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b18:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b1a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b1e:	01174463          	blt	a4,a7,ffffffffc0201b26 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b22:	14088163          	beqz	a7,ffffffffc0201c64 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b26:	000a3603          	ld	a2,0(s4)
ffffffffc0201b2a:	46a1                	li	a3,8
ffffffffc0201b2c:	8a2e                	mv	s4,a1
ffffffffc0201b2e:	bf69                	j	ffffffffc0201ac8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201b30:	03000513          	li	a0,48
ffffffffc0201b34:	85a6                	mv	a1,s1
ffffffffc0201b36:	e03e                	sd	a5,0(sp)
ffffffffc0201b38:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b3a:	85a6                	mv	a1,s1
ffffffffc0201b3c:	07800513          	li	a0,120
ffffffffc0201b40:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b42:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b44:	6782                	ld	a5,0(sp)
ffffffffc0201b46:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b48:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201b4c:	bfb5                	j	ffffffffc0201ac8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b4e:	000a3403          	ld	s0,0(s4)
ffffffffc0201b52:	008a0713          	addi	a4,s4,8
ffffffffc0201b56:	e03a                	sd	a4,0(sp)
ffffffffc0201b58:	14040263          	beqz	s0,ffffffffc0201c9c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201b5c:	0fb05763          	blez	s11,ffffffffc0201c4a <vprintfmt+0x2d8>
ffffffffc0201b60:	02d00693          	li	a3,45
ffffffffc0201b64:	0cd79163          	bne	a5,a3,ffffffffc0201c26 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b68:	00044783          	lbu	a5,0(s0)
ffffffffc0201b6c:	0007851b          	sext.w	a0,a5
ffffffffc0201b70:	cf85                	beqz	a5,ffffffffc0201ba8 <vprintfmt+0x236>
ffffffffc0201b72:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b76:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b7a:	000c4563          	bltz	s8,ffffffffc0201b84 <vprintfmt+0x212>
ffffffffc0201b7e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201b80:	036c0263          	beq	s8,s6,ffffffffc0201ba4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201b84:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b86:	0e0c8e63          	beqz	s9,ffffffffc0201c82 <vprintfmt+0x310>
ffffffffc0201b8a:	3781                	addiw	a5,a5,-32
ffffffffc0201b8c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201c82 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201b90:	03f00513          	li	a0,63
ffffffffc0201b94:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b96:	000a4783          	lbu	a5,0(s4)
ffffffffc0201b9a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201b9c:	0a05                	addi	s4,s4,1
ffffffffc0201b9e:	0007851b          	sext.w	a0,a5
ffffffffc0201ba2:	ffe1                	bnez	a5,ffffffffc0201b7a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201ba4:	01b05963          	blez	s11,ffffffffc0201bb6 <vprintfmt+0x244>
ffffffffc0201ba8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201baa:	85a6                	mv	a1,s1
ffffffffc0201bac:	02000513          	li	a0,32
ffffffffc0201bb0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bb2:	fe0d9be3          	bnez	s11,ffffffffc0201ba8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bb6:	6a02                	ld	s4,0(sp)
ffffffffc0201bb8:	bbd5                	j	ffffffffc02019ac <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bbc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201bc0:	01174463          	blt	a4,a7,ffffffffc0201bc8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201bc4:	08088d63          	beqz	a7,ffffffffc0201c5e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201bc8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201bcc:	0a044d63          	bltz	s0,ffffffffc0201c86 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201bd0:	8622                	mv	a2,s0
ffffffffc0201bd2:	8a66                	mv	s4,s9
ffffffffc0201bd4:	46a9                	li	a3,10
ffffffffc0201bd6:	bdcd                	j	ffffffffc0201ac8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201bd8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201bdc:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201bde:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201be0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201be4:	8fb5                	xor	a5,a5,a3
ffffffffc0201be6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201bea:	02d74163          	blt	a4,a3,ffffffffc0201c0c <vprintfmt+0x29a>
ffffffffc0201bee:	00369793          	slli	a5,a3,0x3
ffffffffc0201bf2:	97de                	add	a5,a5,s7
ffffffffc0201bf4:	639c                	ld	a5,0(a5)
ffffffffc0201bf6:	cb99                	beqz	a5,ffffffffc0201c0c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201bf8:	86be                	mv	a3,a5
ffffffffc0201bfa:	00001617          	auipc	a2,0x1
ffffffffc0201bfe:	08e60613          	addi	a2,a2,142 # ffffffffc0202c88 <best_fit_pmm_manager+0x1b0>
ffffffffc0201c02:	85a6                	mv	a1,s1
ffffffffc0201c04:	854a                	mv	a0,s2
ffffffffc0201c06:	0ce000ef          	jal	ra,ffffffffc0201cd4 <printfmt>
ffffffffc0201c0a:	b34d                	j	ffffffffc02019ac <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c0c:	00001617          	auipc	a2,0x1
ffffffffc0201c10:	06c60613          	addi	a2,a2,108 # ffffffffc0202c78 <best_fit_pmm_manager+0x1a0>
ffffffffc0201c14:	85a6                	mv	a1,s1
ffffffffc0201c16:	854a                	mv	a0,s2
ffffffffc0201c18:	0bc000ef          	jal	ra,ffffffffc0201cd4 <printfmt>
ffffffffc0201c1c:	bb41                	j	ffffffffc02019ac <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c1e:	00001417          	auipc	s0,0x1
ffffffffc0201c22:	05240413          	addi	s0,s0,82 # ffffffffc0202c70 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c26:	85e2                	mv	a1,s8
ffffffffc0201c28:	8522                	mv	a0,s0
ffffffffc0201c2a:	e43e                	sd	a5,8(sp)
ffffffffc0201c2c:	200000ef          	jal	ra,ffffffffc0201e2c <strnlen>
ffffffffc0201c30:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c34:	01b05b63          	blez	s11,ffffffffc0201c4a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201c38:	67a2                	ld	a5,8(sp)
ffffffffc0201c3a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c3e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201c40:	85a6                	mv	a1,s1
ffffffffc0201c42:	8552                	mv	a0,s4
ffffffffc0201c44:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c46:	fe0d9ce3          	bnez	s11,ffffffffc0201c3e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c4a:	00044783          	lbu	a5,0(s0)
ffffffffc0201c4e:	00140a13          	addi	s4,s0,1
ffffffffc0201c52:	0007851b          	sext.w	a0,a5
ffffffffc0201c56:	d3a5                	beqz	a5,ffffffffc0201bb6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c58:	05e00413          	li	s0,94
ffffffffc0201c5c:	bf39                	j	ffffffffc0201b7a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201c5e:	000a2403          	lw	s0,0(s4)
ffffffffc0201c62:	b7ad                	j	ffffffffc0201bcc <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201c64:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c68:	46a1                	li	a3,8
ffffffffc0201c6a:	8a2e                	mv	s4,a1
ffffffffc0201c6c:	bdb1                	j	ffffffffc0201ac8 <vprintfmt+0x156>
ffffffffc0201c6e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c72:	46a9                	li	a3,10
ffffffffc0201c74:	8a2e                	mv	s4,a1
ffffffffc0201c76:	bd89                	j	ffffffffc0201ac8 <vprintfmt+0x156>
ffffffffc0201c78:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c7c:	46c1                	li	a3,16
ffffffffc0201c7e:	8a2e                	mv	s4,a1
ffffffffc0201c80:	b5a1                	j	ffffffffc0201ac8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201c82:	9902                	jalr	s2
ffffffffc0201c84:	bf09                	j	ffffffffc0201b96 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201c86:	85a6                	mv	a1,s1
ffffffffc0201c88:	02d00513          	li	a0,45
ffffffffc0201c8c:	e03e                	sd	a5,0(sp)
ffffffffc0201c8e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201c90:	6782                	ld	a5,0(sp)
ffffffffc0201c92:	8a66                	mv	s4,s9
ffffffffc0201c94:	40800633          	neg	a2,s0
ffffffffc0201c98:	46a9                	li	a3,10
ffffffffc0201c9a:	b53d                	j	ffffffffc0201ac8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201c9c:	03b05163          	blez	s11,ffffffffc0201cbe <vprintfmt+0x34c>
ffffffffc0201ca0:	02d00693          	li	a3,45
ffffffffc0201ca4:	f6d79de3          	bne	a5,a3,ffffffffc0201c1e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201ca8:	00001417          	auipc	s0,0x1
ffffffffc0201cac:	fc840413          	addi	s0,s0,-56 # ffffffffc0202c70 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cb0:	02800793          	li	a5,40
ffffffffc0201cb4:	02800513          	li	a0,40
ffffffffc0201cb8:	00140a13          	addi	s4,s0,1
ffffffffc0201cbc:	bd6d                	j	ffffffffc0201b76 <vprintfmt+0x204>
ffffffffc0201cbe:	00001a17          	auipc	s4,0x1
ffffffffc0201cc2:	fb3a0a13          	addi	s4,s4,-77 # ffffffffc0202c71 <best_fit_pmm_manager+0x199>
ffffffffc0201cc6:	02800513          	li	a0,40
ffffffffc0201cca:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cce:	05e00413          	li	s0,94
ffffffffc0201cd2:	b565                	j	ffffffffc0201b7a <vprintfmt+0x208>

ffffffffc0201cd4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cd4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201cd6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cda:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201cdc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cde:	ec06                	sd	ra,24(sp)
ffffffffc0201ce0:	f83a                	sd	a4,48(sp)
ffffffffc0201ce2:	fc3e                	sd	a5,56(sp)
ffffffffc0201ce4:	e0c2                	sd	a6,64(sp)
ffffffffc0201ce6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201ce8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201cea:	c89ff0ef          	jal	ra,ffffffffc0201972 <vprintfmt>
}
ffffffffc0201cee:	60e2                	ld	ra,24(sp)
ffffffffc0201cf0:	6161                	addi	sp,sp,80
ffffffffc0201cf2:	8082                	ret

ffffffffc0201cf4 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201cf4:	715d                	addi	sp,sp,-80
ffffffffc0201cf6:	e486                	sd	ra,72(sp)
ffffffffc0201cf8:	e0a6                	sd	s1,64(sp)
ffffffffc0201cfa:	fc4a                	sd	s2,56(sp)
ffffffffc0201cfc:	f84e                	sd	s3,48(sp)
ffffffffc0201cfe:	f452                	sd	s4,40(sp)
ffffffffc0201d00:	f056                	sd	s5,32(sp)
ffffffffc0201d02:	ec5a                	sd	s6,24(sp)
ffffffffc0201d04:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d06:	c901                	beqz	a0,ffffffffc0201d16 <readline+0x22>
ffffffffc0201d08:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d0a:	00001517          	auipc	a0,0x1
ffffffffc0201d0e:	f7e50513          	addi	a0,a0,-130 # ffffffffc0202c88 <best_fit_pmm_manager+0x1b0>
ffffffffc0201d12:	bc6fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201d16:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d18:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d1a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d1c:	4aa9                	li	s5,10
ffffffffc0201d1e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d20:	00004b97          	auipc	s7,0x4
ffffffffc0201d24:	320b8b93          	addi	s7,s7,800 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d28:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201d2c:	c24fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d30:	00054a63          	bltz	a0,ffffffffc0201d44 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d34:	00a95a63          	bge	s2,a0,ffffffffc0201d48 <readline+0x54>
ffffffffc0201d38:	029a5263          	bge	s4,s1,ffffffffc0201d5c <readline+0x68>
        c = getchar();
ffffffffc0201d3c:	c14fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d40:	fe055ae3          	bgez	a0,ffffffffc0201d34 <readline+0x40>
            return NULL;
ffffffffc0201d44:	4501                	li	a0,0
ffffffffc0201d46:	a091                	j	ffffffffc0201d8a <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201d48:	03351463          	bne	a0,s3,ffffffffc0201d70 <readline+0x7c>
ffffffffc0201d4c:	e8a9                	bnez	s1,ffffffffc0201d9e <readline+0xaa>
        c = getchar();
ffffffffc0201d4e:	c02fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d52:	fe0549e3          	bltz	a0,ffffffffc0201d44 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d56:	fea959e3          	bge	s2,a0,ffffffffc0201d48 <readline+0x54>
ffffffffc0201d5a:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201d5c:	e42a                	sd	a0,8(sp)
ffffffffc0201d5e:	bb0fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201d62:	6522                	ld	a0,8(sp)
ffffffffc0201d64:	009b87b3          	add	a5,s7,s1
ffffffffc0201d68:	2485                	addiw	s1,s1,1
ffffffffc0201d6a:	00a78023          	sb	a0,0(a5)
ffffffffc0201d6e:	bf7d                	j	ffffffffc0201d2c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201d70:	01550463          	beq	a0,s5,ffffffffc0201d78 <readline+0x84>
ffffffffc0201d74:	fb651ce3          	bne	a0,s6,ffffffffc0201d2c <readline+0x38>
            cputchar(c);
ffffffffc0201d78:	b96fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201d7c:	00004517          	auipc	a0,0x4
ffffffffc0201d80:	2c450513          	addi	a0,a0,708 # ffffffffc0206040 <buf>
ffffffffc0201d84:	94aa                	add	s1,s1,a0
ffffffffc0201d86:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201d8a:	60a6                	ld	ra,72(sp)
ffffffffc0201d8c:	6486                	ld	s1,64(sp)
ffffffffc0201d8e:	7962                	ld	s2,56(sp)
ffffffffc0201d90:	79c2                	ld	s3,48(sp)
ffffffffc0201d92:	7a22                	ld	s4,40(sp)
ffffffffc0201d94:	7a82                	ld	s5,32(sp)
ffffffffc0201d96:	6b62                	ld	s6,24(sp)
ffffffffc0201d98:	6bc2                	ld	s7,16(sp)
ffffffffc0201d9a:	6161                	addi	sp,sp,80
ffffffffc0201d9c:	8082                	ret
            cputchar(c);
ffffffffc0201d9e:	4521                	li	a0,8
ffffffffc0201da0:	b6efe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201da4:	34fd                	addiw	s1,s1,-1
ffffffffc0201da6:	b759                	j	ffffffffc0201d2c <readline+0x38>

ffffffffc0201da8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201da8:	4781                	li	a5,0
ffffffffc0201daa:	00004717          	auipc	a4,0x4
ffffffffc0201dae:	26e73703          	ld	a4,622(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201db2:	88ba                	mv	a7,a4
ffffffffc0201db4:	852a                	mv	a0,a0
ffffffffc0201db6:	85be                	mv	a1,a5
ffffffffc0201db8:	863e                	mv	a2,a5
ffffffffc0201dba:	00000073          	ecall
ffffffffc0201dbe:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201dc0:	8082                	ret

ffffffffc0201dc2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201dc2:	4781                	li	a5,0
ffffffffc0201dc4:	00004717          	auipc	a4,0x4
ffffffffc0201dc8:	6d473703          	ld	a4,1748(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201dcc:	88ba                	mv	a7,a4
ffffffffc0201dce:	852a                	mv	a0,a0
ffffffffc0201dd0:	85be                	mv	a1,a5
ffffffffc0201dd2:	863e                	mv	a2,a5
ffffffffc0201dd4:	00000073          	ecall
ffffffffc0201dd8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201dda:	8082                	ret

ffffffffc0201ddc <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201ddc:	4501                	li	a0,0
ffffffffc0201dde:	00004797          	auipc	a5,0x4
ffffffffc0201de2:	2327b783          	ld	a5,562(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201de6:	88be                	mv	a7,a5
ffffffffc0201de8:	852a                	mv	a0,a0
ffffffffc0201dea:	85aa                	mv	a1,a0
ffffffffc0201dec:	862a                	mv	a2,a0
ffffffffc0201dee:	00000073          	ecall
ffffffffc0201df2:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201df4:	2501                	sext.w	a0,a0
ffffffffc0201df6:	8082                	ret

ffffffffc0201df8 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201df8:	4781                	li	a5,0
ffffffffc0201dfa:	00004717          	auipc	a4,0x4
ffffffffc0201dfe:	22673703          	ld	a4,550(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e02:	88ba                	mv	a7,a4
ffffffffc0201e04:	853e                	mv	a0,a5
ffffffffc0201e06:	85be                	mv	a1,a5
ffffffffc0201e08:	863e                	mv	a2,a5
ffffffffc0201e0a:	00000073          	ecall
ffffffffc0201e0e:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e10:	8082                	ret

ffffffffc0201e12 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e12:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e16:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e18:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e1a:	cb81                	beqz	a5,ffffffffc0201e2a <strlen+0x18>
        cnt ++;
ffffffffc0201e1c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e1e:	00a707b3          	add	a5,a4,a0
ffffffffc0201e22:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e26:	fbfd                	bnez	a5,ffffffffc0201e1c <strlen+0xa>
ffffffffc0201e28:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e2a:	8082                	ret

ffffffffc0201e2c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e2c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e2e:	e589                	bnez	a1,ffffffffc0201e38 <strnlen+0xc>
ffffffffc0201e30:	a811                	j	ffffffffc0201e44 <strnlen+0x18>
        cnt ++;
ffffffffc0201e32:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e34:	00f58863          	beq	a1,a5,ffffffffc0201e44 <strnlen+0x18>
ffffffffc0201e38:	00f50733          	add	a4,a0,a5
ffffffffc0201e3c:	00074703          	lbu	a4,0(a4)
ffffffffc0201e40:	fb6d                	bnez	a4,ffffffffc0201e32 <strnlen+0x6>
ffffffffc0201e42:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e44:	852e                	mv	a0,a1
ffffffffc0201e46:	8082                	ret

ffffffffc0201e48 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e48:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e4c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e50:	cb89                	beqz	a5,ffffffffc0201e62 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201e52:	0505                	addi	a0,a0,1
ffffffffc0201e54:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e56:	fee789e3          	beq	a5,a4,ffffffffc0201e48 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e5a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201e5e:	9d19                	subw	a0,a0,a4
ffffffffc0201e60:	8082                	ret
ffffffffc0201e62:	4501                	li	a0,0
ffffffffc0201e64:	bfed                	j	ffffffffc0201e5e <strcmp+0x16>

ffffffffc0201e66 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e66:	c20d                	beqz	a2,ffffffffc0201e88 <strncmp+0x22>
ffffffffc0201e68:	962e                	add	a2,a2,a1
ffffffffc0201e6a:	a031                	j	ffffffffc0201e76 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201e6c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e6e:	00e79a63          	bne	a5,a4,ffffffffc0201e82 <strncmp+0x1c>
ffffffffc0201e72:	00b60b63          	beq	a2,a1,ffffffffc0201e88 <strncmp+0x22>
ffffffffc0201e76:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201e7a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e7c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201e80:	f7f5                	bnez	a5,ffffffffc0201e6c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e82:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201e86:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e88:	4501                	li	a0,0
ffffffffc0201e8a:	8082                	ret

ffffffffc0201e8c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201e8c:	00054783          	lbu	a5,0(a0)
ffffffffc0201e90:	c799                	beqz	a5,ffffffffc0201e9e <strchr+0x12>
        if (*s == c) {
ffffffffc0201e92:	00f58763          	beq	a1,a5,ffffffffc0201ea0 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201e96:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201e9a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201e9c:	fbfd                	bnez	a5,ffffffffc0201e92 <strchr+0x6>
    }
    return NULL;
ffffffffc0201e9e:	4501                	li	a0,0
}
ffffffffc0201ea0:	8082                	ret

ffffffffc0201ea2 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ea2:	ca01                	beqz	a2,ffffffffc0201eb2 <memset+0x10>
ffffffffc0201ea4:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ea6:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ea8:	0785                	addi	a5,a5,1
ffffffffc0201eaa:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201eae:	fec79de3          	bne	a5,a2,ffffffffc0201ea8 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201eb2:	8082                	ret
