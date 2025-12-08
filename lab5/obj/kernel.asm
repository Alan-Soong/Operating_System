
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	36e50513          	addi	a0,a0,878 # ffffffffc02a63b8 <buf>
ffffffffc0200052:	000ab617          	auipc	a2,0xab
ffffffffc0200056:	81a60613          	addi	a2,a2,-2022 # ffffffffc02aa86c <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	1cd050ef          	jal	ra,ffffffffc0205a2e <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	9ea58593          	addi	a1,a1,-1558 # ffffffffc0205a58 <etext>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	a0250513          	addi	a0,a0,-1534 # ffffffffc0205a78 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6fc020ef          	jal	ra,ffffffffc0202782 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	24b030ef          	jal	ra,ffffffffc0203adc <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	0ea050ef          	jal	ra,ffffffffc0205180 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	276050ef          	jal	ra,ffffffffc0205318 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0205a80 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	2e6b8b93          	addi	s7,s7,742 # ffffffffc02a63b8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	28a50513          	addi	a0,a0,650 # ffffffffc02a63b8 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	482050ef          	jal	ra,ffffffffc020560a <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	44c050ef          	jal	ra,ffffffffc020560a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00006517          	auipc	a0,0x6
ffffffffc0200222:	86a50513          	addi	a0,a0,-1942 # ffffffffc0205a88 <etext+0x30>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	87450513          	addi	a0,a0,-1932 # ffffffffc0205aa8 <etext+0x50>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00006597          	auipc	a1,0x6
ffffffffc0200244:	81858593          	addi	a1,a1,-2024 # ffffffffc0205a58 <etext>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	88050513          	addi	a0,a0,-1920 # ffffffffc0205ac8 <etext+0x70>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	16458593          	addi	a1,a1,356 # ffffffffc02a63b8 <buf>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	88c50513          	addi	a0,a0,-1908 # ffffffffc0205ae8 <etext+0x90>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	60458593          	addi	a1,a1,1540 # ffffffffc02aa86c <end>
ffffffffc0200270:	00006517          	auipc	a0,0x6
ffffffffc0200274:	89850513          	addi	a0,a0,-1896 # ffffffffc0205b08 <etext+0xb0>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	9ef58593          	addi	a1,a1,-1553 # ffffffffc02aac6b <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00006517          	auipc	a0,0x6
ffffffffc02002a2:	88a50513          	addi	a0,a0,-1910 # ffffffffc0205b28 <etext+0xd0>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00006617          	auipc	a2,0x6
ffffffffc02002b0:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0205b58 <etext+0x100>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00006517          	auipc	a0,0x6
ffffffffc02002bc:	8b850513          	addi	a0,a0,-1864 # ffffffffc0205b70 <etext+0x118>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00006617          	auipc	a2,0x6
ffffffffc02002cc:	8c060613          	addi	a2,a2,-1856 # ffffffffc0205b88 <etext+0x130>
ffffffffc02002d0:	00006597          	auipc	a1,0x6
ffffffffc02002d4:	8d858593          	addi	a1,a1,-1832 # ffffffffc0205ba8 <etext+0x150>
ffffffffc02002d8:	00006517          	auipc	a0,0x6
ffffffffc02002dc:	8d850513          	addi	a0,a0,-1832 # ffffffffc0205bb0 <etext+0x158>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00006617          	auipc	a2,0x6
ffffffffc02002ea:	8da60613          	addi	a2,a2,-1830 # ffffffffc0205bc0 <etext+0x168>
ffffffffc02002ee:	00006597          	auipc	a1,0x6
ffffffffc02002f2:	8fa58593          	addi	a1,a1,-1798 # ffffffffc0205be8 <etext+0x190>
ffffffffc02002f6:	00006517          	auipc	a0,0x6
ffffffffc02002fa:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0205bb0 <etext+0x158>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00006617          	auipc	a2,0x6
ffffffffc0200306:	8f660613          	addi	a2,a2,-1802 # ffffffffc0205bf8 <etext+0x1a0>
ffffffffc020030a:	00006597          	auipc	a1,0x6
ffffffffc020030e:	90e58593          	addi	a1,a1,-1778 # ffffffffc0205c18 <etext+0x1c0>
ffffffffc0200312:	00006517          	auipc	a0,0x6
ffffffffc0200316:	89e50513          	addi	a0,a0,-1890 # ffffffffc0205bb0 <etext+0x158>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00006517          	auipc	a0,0x6
ffffffffc0200350:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0205c28 <etext+0x1d0>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00006517          	auipc	a0,0x6
ffffffffc0200372:	8e250513          	addi	a0,a0,-1822 # ffffffffc0205c50 <etext+0x1f8>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00006c17          	auipc	s8,0x6
ffffffffc0200388:	93cc0c13          	addi	s8,s8,-1732 # ffffffffc0205cc0 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00006917          	auipc	s2,0x6
ffffffffc0200390:	8ec90913          	addi	s2,s2,-1812 # ffffffffc0205c78 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00006497          	auipc	s1,0x6
ffffffffc0200398:	8ec48493          	addi	s1,s1,-1812 # ffffffffc0205c80 <etext+0x228>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00006b17          	auipc	s6,0x6
ffffffffc02003a2:	8eab0b13          	addi	s6,s6,-1814 # ffffffffc0205c88 <etext+0x230>
        argv[argc++] = buf;
ffffffffc02003a6:	00006a17          	auipc	s4,0x6
ffffffffc02003aa:	802a0a13          	addi	s4,s4,-2046 # ffffffffc0205ba8 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00006d17          	auipc	s10,0x6
ffffffffc02003cc:	8f8d0d13          	addi	s10,s10,-1800 # ffffffffc0205cc0 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	5fe050ef          	jal	ra,ffffffffc02059d4 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	5ea050ef          	jal	ra,ffffffffc02059d4 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	5f0050ef          	jal	ra,ffffffffc0205a18 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	5b2050ef          	jal	ra,ffffffffc0205a18 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00006517          	auipc	a0,0x6
ffffffffc0200484:	82850513          	addi	a0,a0,-2008 # ffffffffc0205ca8 <etext+0x250>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	35230313          	addi	t1,t1,850 # ffffffffc02aa7e0 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00006517          	auipc	a0,0x6
ffffffffc02004c0:	84c50513          	addi	a0,a0,-1972 # ffffffffc0205d08 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00007517          	auipc	a0,0x7
ffffffffc02004d6:	93e50513          	addi	a0,a0,-1730 # ffffffffc0206e10 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00006517          	auipc	a0,0x6
ffffffffc020050a:	82250513          	addi	a0,a0,-2014 # ffffffffc0205d28 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00007517          	auipc	a0,0x7
ffffffffc020052a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0206e10 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd570>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	2af73823          	sd	a5,688(a4) # ffffffffc02aa7f0 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	7e850513          	addi	a0,a0,2024 # ffffffffc0205d48 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	2807b023          	sd	zero,640(a5) # ffffffffc02aa7e8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	27a7b783          	ld	a5,634(a5) # ffffffffc02aa7f0 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	76850513          	addi	a0,a0,1896 # ffffffffc0205d68 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	74a50513          	addi	a0,a0,1866 # ffffffffc0205d78 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	74450513          	addi	a0,a0,1860 # ffffffffc0205d88 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	74c50513          	addi	a0,a0,1868 # ffffffffc0205da0 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe35681>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	6e290913          	addi	s2,s2,1762 # ffffffffc0205df0 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	6cc48493          	addi	s1,s1,1740 # ffffffffc0205de8 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	6f850513          	addi	a0,a0,1784 # ffffffffc0205e68 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	72450513          	addi	a0,a0,1828 # ffffffffc0205ea0 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	60450513          	addi	a0,a0,1540 # ffffffffc0205dc0 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	1c2050ef          	jal	ra,ffffffffc020598c <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	21a050ef          	jal	ra,ffffffffc02059f2 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	166050ef          	jal	ra,ffffffffc02059d4 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	57650513          	addi	a0,a0,1398 # ffffffffc0205df8 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	4c850513          	addi	a0,a0,1224 # ffffffffc0205e18 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	4ce50513          	addi	a0,a0,1230 # ffffffffc0205e30 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205e50 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	52050513          	addi	a0,a0,1312 # ffffffffc0205ea0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	e687b823          	sd	s0,-400(a5) # ffffffffc02aa7f8 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	e767b823          	sd	s6,-400(a5) # ffffffffc02aa800 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	e5e53503          	ld	a0,-418(a0) # ffffffffc02aa7f8 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	e5c53503          	ld	a0,-420(a0) # ffffffffc02aa800 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	4f078793          	addi	a5,a5,1264 # ffffffffc0200eb0 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	4da50513          	addi	a0,a0,1242 # ffffffffc0205eb8 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	4e250513          	addi	a0,a0,1250 # ffffffffc0205ed0 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	4ec50513          	addi	a0,a0,1260 # ffffffffc0205ee8 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	4f650513          	addi	a0,a0,1270 # ffffffffc0205f00 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	50050513          	addi	a0,a0,1280 # ffffffffc0205f18 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	50a50513          	addi	a0,a0,1290 # ffffffffc0205f30 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	51450513          	addi	a0,a0,1300 # ffffffffc0205f48 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	51e50513          	addi	a0,a0,1310 # ffffffffc0205f60 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	52850513          	addi	a0,a0,1320 # ffffffffc0205f78 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	53250513          	addi	a0,a0,1330 # ffffffffc0205f90 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	53c50513          	addi	a0,a0,1340 # ffffffffc0205fa8 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	54650513          	addi	a0,a0,1350 # ffffffffc0205fc0 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	55050513          	addi	a0,a0,1360 # ffffffffc0205fd8 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	55a50513          	addi	a0,a0,1370 # ffffffffc0205ff0 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	56450513          	addi	a0,a0,1380 # ffffffffc0206008 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	56e50513          	addi	a0,a0,1390 # ffffffffc0206020 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	57850513          	addi	a0,a0,1400 # ffffffffc0206038 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	58250513          	addi	a0,a0,1410 # ffffffffc0206050 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	58c50513          	addi	a0,a0,1420 # ffffffffc0206068 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	59650513          	addi	a0,a0,1430 # ffffffffc0206080 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	5a050513          	addi	a0,a0,1440 # ffffffffc0206098 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	5aa50513          	addi	a0,a0,1450 # ffffffffc02060b0 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	5b450513          	addi	a0,a0,1460 # ffffffffc02060c8 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	5be50513          	addi	a0,a0,1470 # ffffffffc02060e0 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	5c850513          	addi	a0,a0,1480 # ffffffffc02060f8 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	5d250513          	addi	a0,a0,1490 # ffffffffc0206110 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	5dc50513          	addi	a0,a0,1500 # ffffffffc0206128 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	5e650513          	addi	a0,a0,1510 # ffffffffc0206140 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	5f050513          	addi	a0,a0,1520 # ffffffffc0206158 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0206170 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	60450513          	addi	a0,a0,1540 # ffffffffc0206188 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	60a50513          	addi	a0,a0,1546 # ffffffffc02061a0 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	60c50513          	addi	a0,a0,1548 # ffffffffc02061b8 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	60c50513          	addi	a0,a0,1548 # ffffffffc02061d0 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	61450513          	addi	a0,a0,1556 # ffffffffc02061e8 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	61c50513          	addi	a0,a0,1564 # ffffffffc0206200 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	61850513          	addi	a0,a0,1560 # ffffffffc0206210 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	06f76c63          	bltu	a4,a5,ffffffffc0200c88 <interrupt_handler+0x82>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	6c470713          	addi	a4,a4,1732 # ffffffffc02062d8 <commands+0x618>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	66250513          	addi	a0,a0,1634 # ffffffffc0206288 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	63650513          	addi	a0,a0,1590 # ffffffffc0206268 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	5ea50513          	addi	a0,a0,1514 # ffffffffc0206228 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	5fe50513          	addi	a0,a0,1534 # ffffffffc0206248 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200c5e:	000aa697          	auipc	a3,0xaa
ffffffffc0200c62:	b8a68693          	addi	a3,a3,-1142 # ffffffffc02aa7e8 <ticks>
ffffffffc0200c66:	629c                	ld	a5,0(a3)
ffffffffc0200c68:	06400713          	li	a4,100
ffffffffc0200c6c:	0785                	addi	a5,a5,1
ffffffffc0200c6e:	02e7f733          	remu	a4,a5,a4
ffffffffc0200c72:	e29c                	sd	a5,0(a3)
ffffffffc0200c74:	cb19                	beqz	a4,ffffffffc0200c8a <interrupt_handler+0x84>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c76:	60a2                	ld	ra,8(sp)
ffffffffc0200c78:	0141                	addi	sp,sp,16
ffffffffc0200c7a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c7c:	00005517          	auipc	a0,0x5
ffffffffc0200c80:	63c50513          	addi	a0,a0,1596 # ffffffffc02062b8 <commands+0x5f8>
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c88:	bf31                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c8a:	06400593          	li	a1,100
ffffffffc0200c8e:	00005517          	auipc	a0,0x5
ffffffffc0200c92:	61a50513          	addi	a0,a0,1562 # ffffffffc02062a8 <commands+0x5e8>
ffffffffc0200c96:	cfeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_count++;
ffffffffc0200c9a:	000aa717          	auipc	a4,0xaa
ffffffffc0200c9e:	b6e70713          	addi	a4,a4,-1170 # ffffffffc02aa808 <print_count.0>
ffffffffc0200ca2:	431c                	lw	a5,0(a4)
            if (print_count == 10) {
ffffffffc0200ca4:	46a9                	li	a3,10
            print_count++;
ffffffffc0200ca6:	0017861b          	addiw	a2,a5,1
ffffffffc0200caa:	c310                	sw	a2,0(a4)
            if (print_count == 10) {
ffffffffc0200cac:	00d61863          	bne	a2,a3,ffffffffc0200cbc <interrupt_handler+0xb6>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200cb0:	4501                	li	a0,0
ffffffffc0200cb2:	4581                	li	a1,0
ffffffffc0200cb4:	4601                	li	a2,0
ffffffffc0200cb6:	48a1                	li	a7,8
ffffffffc0200cb8:	00000073          	ecall
            if (current != NULL) {
ffffffffc0200cbc:	000aa797          	auipc	a5,0xaa
ffffffffc0200cc0:	b947b783          	ld	a5,-1132(a5) # ffffffffc02aa850 <current>
ffffffffc0200cc4:	dbcd                	beqz	a5,ffffffffc0200c76 <interrupt_handler+0x70>
                current->need_resched = 1;
ffffffffc0200cc6:	4705                	li	a4,1
ffffffffc0200cc8:	ef98                	sd	a4,24(a5)
ffffffffc0200cca:	b775                	j	ffffffffc0200c76 <interrupt_handler+0x70>

ffffffffc0200ccc <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200ccc:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cd0:	1141                	addi	sp,sp,-16
ffffffffc0200cd2:	e022                	sd	s0,0(sp)
ffffffffc0200cd4:	e406                	sd	ra,8(sp)
ffffffffc0200cd6:	473d                	li	a4,15
ffffffffc0200cd8:	842a                	mv	s0,a0
ffffffffc0200cda:	12f76563          	bltu	a4,a5,ffffffffc0200e04 <exception_handler+0x138>
ffffffffc0200cde:	00005717          	auipc	a4,0x5
ffffffffc0200ce2:	7ba70713          	addi	a4,a4,1978 # ffffffffc0206498 <commands+0x7d8>
ffffffffc0200ce6:	078a                	slli	a5,a5,0x2
ffffffffc0200ce8:	97ba                	add	a5,a5,a4
ffffffffc0200cea:	439c                	lw	a5,0(a5)
ffffffffc0200cec:	97ba                	add	a5,a5,a4
ffffffffc0200cee:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cf0:	00005517          	auipc	a0,0x5
ffffffffc0200cf4:	70050513          	addi	a0,a0,1792 # ffffffffc02063f0 <commands+0x730>
ffffffffc0200cf8:	c9cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cfc:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d00:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200d02:	0791                	addi	a5,a5,4
ffffffffc0200d04:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d08:	6402                	ld	s0,0(sp)
ffffffffc0200d0a:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200d0c:	7fc0406f          	j	ffffffffc0205508 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	70050513          	addi	a0,a0,1792 # ffffffffc0206410 <commands+0x750>
}
ffffffffc0200d18:	6402                	ld	s0,0(sp)
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d1e:	c76ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	70e50513          	addi	a0,a0,1806 # ffffffffc0206430 <commands+0x770>
ffffffffc0200d2a:	b7fd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	72450513          	addi	a0,a0,1828 # ffffffffc0206450 <commands+0x790>
ffffffffc0200d34:	c60ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if ((ret = do_pgfault(current->mm, 0, tf->tval)) != 0) {
ffffffffc0200d38:	000aa797          	auipc	a5,0xaa
ffffffffc0200d3c:	b187b783          	ld	a5,-1256(a5) # ffffffffc02aa850 <current>
ffffffffc0200d40:	11043603          	ld	a2,272(s0)
ffffffffc0200d44:	7788                	ld	a0,40(a5)
ffffffffc0200d46:	4581                	li	a1,0
ffffffffc0200d48:	231020ef          	jal	ra,ffffffffc0203778 <do_pgfault>
ffffffffc0200d4c:	e91d                	bnez	a0,ffffffffc0200d82 <exception_handler+0xb6>
}
ffffffffc0200d4e:	60a2                	ld	ra,8(sp)
ffffffffc0200d50:	6402                	ld	s0,0(sp)
ffffffffc0200d52:	0141                	addi	sp,sp,16
ffffffffc0200d54:	8082                	ret
        cprintf("Load page fault\n");
ffffffffc0200d56:	00005517          	auipc	a0,0x5
ffffffffc0200d5a:	71250513          	addi	a0,a0,1810 # ffffffffc0206468 <commands+0x7a8>
ffffffffc0200d5e:	bfd9                	j	ffffffffc0200d34 <exception_handler+0x68>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d60:	00005517          	auipc	a0,0x5
ffffffffc0200d64:	72050513          	addi	a0,a0,1824 # ffffffffc0206480 <commands+0x7c0>
ffffffffc0200d68:	c2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if ((ret = do_pgfault(current->mm, 1, tf->tval)) != 0) {
ffffffffc0200d6c:	000aa797          	auipc	a5,0xaa
ffffffffc0200d70:	ae47b783          	ld	a5,-1308(a5) # ffffffffc02aa850 <current>
ffffffffc0200d74:	11043603          	ld	a2,272(s0)
ffffffffc0200d78:	7788                	ld	a0,40(a5)
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	1fd020ef          	jal	ra,ffffffffc0203778 <do_pgfault>
ffffffffc0200d80:	d579                	beqz	a0,ffffffffc0200d4e <exception_handler+0x82>
}
ffffffffc0200d82:	6402                	ld	s0,0(sp)
ffffffffc0200d84:	60a2                	ld	ra,8(sp)
            do_exit(-E_FAULT);
ffffffffc0200d86:	5569                	li	a0,-6
}
ffffffffc0200d88:	0141                	addi	sp,sp,16
            do_exit(-E_FAULT);
ffffffffc0200d8a:	1d90306f          	j	ffffffffc0204762 <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d8e:	00005517          	auipc	a0,0x5
ffffffffc0200d92:	57a50513          	addi	a0,a0,1402 # ffffffffc0206308 <commands+0x648>
ffffffffc0200d96:	b749                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d98:	00005517          	auipc	a0,0x5
ffffffffc0200d9c:	59050513          	addi	a0,a0,1424 # ffffffffc0206328 <commands+0x668>
ffffffffc0200da0:	bfa5                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200da2:	00005517          	auipc	a0,0x5
ffffffffc0200da6:	5a650513          	addi	a0,a0,1446 # ffffffffc0206348 <commands+0x688>
ffffffffc0200daa:	b7bd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200dac:	00005517          	auipc	a0,0x5
ffffffffc0200db0:	5b450513          	addi	a0,a0,1460 # ffffffffc0206360 <commands+0x6a0>
ffffffffc0200db4:	be0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200db8:	6458                	ld	a4,136(s0)
ffffffffc0200dba:	47a9                	li	a5,10
ffffffffc0200dbc:	f8f719e3          	bne	a4,a5,ffffffffc0200d4e <exception_handler+0x82>
            tf->epc += 4;
ffffffffc0200dc0:	10843783          	ld	a5,264(s0)
ffffffffc0200dc4:	0791                	addi	a5,a5,4
ffffffffc0200dc6:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200dca:	73e040ef          	jal	ra,ffffffffc0205508 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dce:	000aa797          	auipc	a5,0xaa
ffffffffc0200dd2:	a827b783          	ld	a5,-1406(a5) # ffffffffc02aa850 <current>
ffffffffc0200dd6:	6b9c                	ld	a5,16(a5)
ffffffffc0200dd8:	8522                	mv	a0,s0
}
ffffffffc0200dda:	6402                	ld	s0,0(sp)
ffffffffc0200ddc:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dde:	6589                	lui	a1,0x2
ffffffffc0200de0:	95be                	add	a1,a1,a5
}
ffffffffc0200de2:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200de4:	aa69                	j	ffffffffc0200f7e <kernel_execve_ret>
        cprintf("Load address misaligned\n");
ffffffffc0200de6:	00005517          	auipc	a0,0x5
ffffffffc0200dea:	58a50513          	addi	a0,a0,1418 # ffffffffc0206370 <commands+0x6b0>
ffffffffc0200dee:	b72d                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200df0:	00005517          	auipc	a0,0x5
ffffffffc0200df4:	5a050513          	addi	a0,a0,1440 # ffffffffc0206390 <commands+0x6d0>
ffffffffc0200df8:	b705                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200dfa:	00005517          	auipc	a0,0x5
ffffffffc0200dfe:	5de50513          	addi	a0,a0,1502 # ffffffffc02063d8 <commands+0x718>
ffffffffc0200e02:	bf19                	j	ffffffffc0200d18 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200e04:	8522                	mv	a0,s0
}
ffffffffc0200e06:	6402                	ld	s0,0(sp)
ffffffffc0200e08:	60a2                	ld	ra,8(sp)
ffffffffc0200e0a:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200e0c:	bb61                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e0e:	00005617          	auipc	a2,0x5
ffffffffc0200e12:	59a60613          	addi	a2,a2,1434 # ffffffffc02063a8 <commands+0x6e8>
ffffffffc0200e16:	0cd00593          	li	a1,205
ffffffffc0200e1a:	00005517          	auipc	a0,0x5
ffffffffc0200e1e:	5a650513          	addi	a0,a0,1446 # ffffffffc02063c0 <commands+0x700>
ffffffffc0200e22:	e6cff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e26 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e26:	1101                	addi	sp,sp,-32
ffffffffc0200e28:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e2a:	000aa417          	auipc	s0,0xaa
ffffffffc0200e2e:	a2640413          	addi	s0,s0,-1498 # ffffffffc02aa850 <current>
ffffffffc0200e32:	6018                	ld	a4,0(s0)
{
ffffffffc0200e34:	ec06                	sd	ra,24(sp)
ffffffffc0200e36:	e426                	sd	s1,8(sp)
ffffffffc0200e38:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e3a:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e3e:	cf1d                	beqz	a4,ffffffffc0200e7c <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e40:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e44:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e48:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e4a:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e4e:	0206c463          	bltz	a3,ffffffffc0200e76 <trap+0x50>
        exception_handler(tf);
ffffffffc0200e52:	e7bff0ef          	jal	ra,ffffffffc0200ccc <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e56:	601c                	ld	a5,0(s0)
ffffffffc0200e58:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e5c:	e499                	bnez	s1,ffffffffc0200e6a <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e5e:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e62:	8b05                	andi	a4,a4,1
ffffffffc0200e64:	e329                	bnez	a4,ffffffffc0200ea6 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e66:	6f9c                	ld	a5,24(a5)
ffffffffc0200e68:	eb85                	bnez	a5,ffffffffc0200e98 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e6a:	60e2                	ld	ra,24(sp)
ffffffffc0200e6c:	6442                	ld	s0,16(sp)
ffffffffc0200e6e:	64a2                	ld	s1,8(sp)
ffffffffc0200e70:	6902                	ld	s2,0(sp)
ffffffffc0200e72:	6105                	addi	sp,sp,32
ffffffffc0200e74:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e76:	d91ff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e7a:	bff1                	j	ffffffffc0200e56 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e7c:	0006c863          	bltz	a3,ffffffffc0200e8c <trap+0x66>
}
ffffffffc0200e80:	6442                	ld	s0,16(sp)
ffffffffc0200e82:	60e2                	ld	ra,24(sp)
ffffffffc0200e84:	64a2                	ld	s1,8(sp)
ffffffffc0200e86:	6902                	ld	s2,0(sp)
ffffffffc0200e88:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e8a:	b589                	j	ffffffffc0200ccc <exception_handler>
}
ffffffffc0200e8c:	6442                	ld	s0,16(sp)
ffffffffc0200e8e:	60e2                	ld	ra,24(sp)
ffffffffc0200e90:	64a2                	ld	s1,8(sp)
ffffffffc0200e92:	6902                	ld	s2,0(sp)
ffffffffc0200e94:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e96:	bb85                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e98:	6442                	ld	s0,16(sp)
ffffffffc0200e9a:	60e2                	ld	ra,24(sp)
ffffffffc0200e9c:	64a2                	ld	s1,8(sp)
ffffffffc0200e9e:	6902                	ld	s2,0(sp)
ffffffffc0200ea0:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200ea2:	57a0406f          	j	ffffffffc020541c <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ea6:	555d                	li	a0,-9
ffffffffc0200ea8:	0bb030ef          	jal	ra,ffffffffc0204762 <do_exit>
            if (current->need_resched)
ffffffffc0200eac:	601c                	ld	a5,0(s0)
ffffffffc0200eae:	bf65                	j	ffffffffc0200e66 <trap+0x40>

ffffffffc0200eb0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200eb0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200eb4:	00011463          	bnez	sp,ffffffffc0200ebc <__alltraps+0xc>
ffffffffc0200eb8:	14002173          	csrr	sp,sscratch
ffffffffc0200ebc:	712d                	addi	sp,sp,-288
ffffffffc0200ebe:	e002                	sd	zero,0(sp)
ffffffffc0200ec0:	e406                	sd	ra,8(sp)
ffffffffc0200ec2:	ec0e                	sd	gp,24(sp)
ffffffffc0200ec4:	f012                	sd	tp,32(sp)
ffffffffc0200ec6:	f416                	sd	t0,40(sp)
ffffffffc0200ec8:	f81a                	sd	t1,48(sp)
ffffffffc0200eca:	fc1e                	sd	t2,56(sp)
ffffffffc0200ecc:	e0a2                	sd	s0,64(sp)
ffffffffc0200ece:	e4a6                	sd	s1,72(sp)
ffffffffc0200ed0:	e8aa                	sd	a0,80(sp)
ffffffffc0200ed2:	ecae                	sd	a1,88(sp)
ffffffffc0200ed4:	f0b2                	sd	a2,96(sp)
ffffffffc0200ed6:	f4b6                	sd	a3,104(sp)
ffffffffc0200ed8:	f8ba                	sd	a4,112(sp)
ffffffffc0200eda:	fcbe                	sd	a5,120(sp)
ffffffffc0200edc:	e142                	sd	a6,128(sp)
ffffffffc0200ede:	e546                	sd	a7,136(sp)
ffffffffc0200ee0:	e94a                	sd	s2,144(sp)
ffffffffc0200ee2:	ed4e                	sd	s3,152(sp)
ffffffffc0200ee4:	f152                	sd	s4,160(sp)
ffffffffc0200ee6:	f556                	sd	s5,168(sp)
ffffffffc0200ee8:	f95a                	sd	s6,176(sp)
ffffffffc0200eea:	fd5e                	sd	s7,184(sp)
ffffffffc0200eec:	e1e2                	sd	s8,192(sp)
ffffffffc0200eee:	e5e6                	sd	s9,200(sp)
ffffffffc0200ef0:	e9ea                	sd	s10,208(sp)
ffffffffc0200ef2:	edee                	sd	s11,216(sp)
ffffffffc0200ef4:	f1f2                	sd	t3,224(sp)
ffffffffc0200ef6:	f5f6                	sd	t4,232(sp)
ffffffffc0200ef8:	f9fa                	sd	t5,240(sp)
ffffffffc0200efa:	fdfe                	sd	t6,248(sp)
ffffffffc0200efc:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f00:	100024f3          	csrr	s1,sstatus
ffffffffc0200f04:	14102973          	csrr	s2,sepc
ffffffffc0200f08:	143029f3          	csrr	s3,stval
ffffffffc0200f0c:	14202a73          	csrr	s4,scause
ffffffffc0200f10:	e822                	sd	s0,16(sp)
ffffffffc0200f12:	e226                	sd	s1,256(sp)
ffffffffc0200f14:	e64a                	sd	s2,264(sp)
ffffffffc0200f16:	ea4e                	sd	s3,272(sp)
ffffffffc0200f18:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f1a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f1c:	f0bff0ef          	jal	ra,ffffffffc0200e26 <trap>

ffffffffc0200f20 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f20:	6492                	ld	s1,256(sp)
ffffffffc0200f22:	6932                	ld	s2,264(sp)
ffffffffc0200f24:	1004f413          	andi	s0,s1,256
ffffffffc0200f28:	e401                	bnez	s0,ffffffffc0200f30 <__trapret+0x10>
ffffffffc0200f2a:	1200                	addi	s0,sp,288
ffffffffc0200f2c:	14041073          	csrw	sscratch,s0
ffffffffc0200f30:	10049073          	csrw	sstatus,s1
ffffffffc0200f34:	14191073          	csrw	sepc,s2
ffffffffc0200f38:	60a2                	ld	ra,8(sp)
ffffffffc0200f3a:	61e2                	ld	gp,24(sp)
ffffffffc0200f3c:	7202                	ld	tp,32(sp)
ffffffffc0200f3e:	72a2                	ld	t0,40(sp)
ffffffffc0200f40:	7342                	ld	t1,48(sp)
ffffffffc0200f42:	73e2                	ld	t2,56(sp)
ffffffffc0200f44:	6406                	ld	s0,64(sp)
ffffffffc0200f46:	64a6                	ld	s1,72(sp)
ffffffffc0200f48:	6546                	ld	a0,80(sp)
ffffffffc0200f4a:	65e6                	ld	a1,88(sp)
ffffffffc0200f4c:	7606                	ld	a2,96(sp)
ffffffffc0200f4e:	76a6                	ld	a3,104(sp)
ffffffffc0200f50:	7746                	ld	a4,112(sp)
ffffffffc0200f52:	77e6                	ld	a5,120(sp)
ffffffffc0200f54:	680a                	ld	a6,128(sp)
ffffffffc0200f56:	68aa                	ld	a7,136(sp)
ffffffffc0200f58:	694a                	ld	s2,144(sp)
ffffffffc0200f5a:	69ea                	ld	s3,152(sp)
ffffffffc0200f5c:	7a0a                	ld	s4,160(sp)
ffffffffc0200f5e:	7aaa                	ld	s5,168(sp)
ffffffffc0200f60:	7b4a                	ld	s6,176(sp)
ffffffffc0200f62:	7bea                	ld	s7,184(sp)
ffffffffc0200f64:	6c0e                	ld	s8,192(sp)
ffffffffc0200f66:	6cae                	ld	s9,200(sp)
ffffffffc0200f68:	6d4e                	ld	s10,208(sp)
ffffffffc0200f6a:	6dee                	ld	s11,216(sp)
ffffffffc0200f6c:	7e0e                	ld	t3,224(sp)
ffffffffc0200f6e:	7eae                	ld	t4,232(sp)
ffffffffc0200f70:	7f4e                	ld	t5,240(sp)
ffffffffc0200f72:	7fee                	ld	t6,248(sp)
ffffffffc0200f74:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f76:	10200073          	sret

ffffffffc0200f7a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f7a:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f7c:	b755                	j	ffffffffc0200f20 <__trapret>

ffffffffc0200f7e <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f7e:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f82:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f86:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f8a:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f8e:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f92:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f96:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f9a:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f9e:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200fa2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200fa4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200fa6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200fa8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200faa:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200fac:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200fae:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200fb0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200fb2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200fb4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200fb6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200fb8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200fba:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200fbc:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200fbe:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200fc0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200fc2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200fc4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200fc6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200fc8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200fca:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200fcc:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200fce:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200fd0:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200fd2:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200fd4:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200fd6:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200fd8:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200fda:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200fdc:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200fde:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200fe0:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200fe2:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200fe4:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200fe6:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200fe8:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200fea:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200fec:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200fee:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200ff0:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200ff2:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200ff4:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200ff6:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200ff8:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200ffa:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200ffc:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200ffe:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201000:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0201002:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0201004:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0201006:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201008:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc020100a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc020100c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc020100e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201010:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0201012:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0201014:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0201016:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201018:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc020101a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc020101c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc020101e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201020:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0201022:	812e                	mv	sp,a1
ffffffffc0201024:	bdf5                	j	ffffffffc0200f20 <__trapret>

ffffffffc0201026 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201026:	000a5797          	auipc	a5,0xa5
ffffffffc020102a:	79278793          	addi	a5,a5,1938 # ffffffffc02a67b8 <free_area>
ffffffffc020102e:	e79c                	sd	a5,8(a5)
ffffffffc0201030:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201032:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201036:	8082                	ret

ffffffffc0201038 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201038:	000a5517          	auipc	a0,0xa5
ffffffffc020103c:	79056503          	lwu	a0,1936(a0) # ffffffffc02a67c8 <free_area+0x10>
ffffffffc0201040:	8082                	ret

ffffffffc0201042 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0201042:	715d                	addi	sp,sp,-80
ffffffffc0201044:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201046:	000a5417          	auipc	s0,0xa5
ffffffffc020104a:	77240413          	addi	s0,s0,1906 # ffffffffc02a67b8 <free_area>
ffffffffc020104e:	641c                	ld	a5,8(s0)
ffffffffc0201050:	e486                	sd	ra,72(sp)
ffffffffc0201052:	fc26                	sd	s1,56(sp)
ffffffffc0201054:	f84a                	sd	s2,48(sp)
ffffffffc0201056:	f44e                	sd	s3,40(sp)
ffffffffc0201058:	f052                	sd	s4,32(sp)
ffffffffc020105a:	ec56                	sd	s5,24(sp)
ffffffffc020105c:	e85a                	sd	s6,16(sp)
ffffffffc020105e:	e45e                	sd	s7,8(sp)
ffffffffc0201060:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201062:	2a878d63          	beq	a5,s0,ffffffffc020131c <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0201066:	4481                	li	s1,0
ffffffffc0201068:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020106a:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020106e:	8b09                	andi	a4,a4,2
ffffffffc0201070:	2a070a63          	beqz	a4,ffffffffc0201324 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0201074:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201078:	679c                	ld	a5,8(a5)
ffffffffc020107a:	2905                	addiw	s2,s2,1
ffffffffc020107c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020107e:	fe8796e3          	bne	a5,s0,ffffffffc020106a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201082:	89a6                	mv	s3,s1
ffffffffc0201084:	6df000ef          	jal	ra,ffffffffc0201f62 <nr_free_pages>
ffffffffc0201088:	6f351e63          	bne	a0,s3,ffffffffc0201784 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020108c:	4505                	li	a0,1
ffffffffc020108e:	657000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0201092:	8aaa                	mv	s5,a0
ffffffffc0201094:	42050863          	beqz	a0,ffffffffc02014c4 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201098:	4505                	li	a0,1
ffffffffc020109a:	64b000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc020109e:	89aa                	mv	s3,a0
ffffffffc02010a0:	70050263          	beqz	a0,ffffffffc02017a4 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010a4:	4505                	li	a0,1
ffffffffc02010a6:	63f000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02010aa:	8a2a                	mv	s4,a0
ffffffffc02010ac:	48050c63          	beqz	a0,ffffffffc0201544 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010b0:	293a8a63          	beq	s5,s3,ffffffffc0201344 <default_check+0x302>
ffffffffc02010b4:	28aa8863          	beq	s5,a0,ffffffffc0201344 <default_check+0x302>
ffffffffc02010b8:	28a98663          	beq	s3,a0,ffffffffc0201344 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010bc:	000aa783          	lw	a5,0(s5)
ffffffffc02010c0:	2a079263          	bnez	a5,ffffffffc0201364 <default_check+0x322>
ffffffffc02010c4:	0009a783          	lw	a5,0(s3)
ffffffffc02010c8:	28079e63          	bnez	a5,ffffffffc0201364 <default_check+0x322>
ffffffffc02010cc:	411c                	lw	a5,0(a0)
ffffffffc02010ce:	28079b63          	bnez	a5,ffffffffc0201364 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc02010d2:	000a9797          	auipc	a5,0xa9
ffffffffc02010d6:	75e7b783          	ld	a5,1886(a5) # ffffffffc02aa830 <pages>
ffffffffc02010da:	40fa8733          	sub	a4,s5,a5
ffffffffc02010de:	00007617          	auipc	a2,0x7
ffffffffc02010e2:	b5a63603          	ld	a2,-1190(a2) # ffffffffc0207c38 <nbase>
ffffffffc02010e6:	8719                	srai	a4,a4,0x6
ffffffffc02010e8:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010ea:	000a9697          	auipc	a3,0xa9
ffffffffc02010ee:	73e6b683          	ld	a3,1854(a3) # ffffffffc02aa828 <npage>
ffffffffc02010f2:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010f4:	0732                	slli	a4,a4,0xc
ffffffffc02010f6:	28d77763          	bgeu	a4,a3,ffffffffc0201384 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02010fa:	40f98733          	sub	a4,s3,a5
ffffffffc02010fe:	8719                	srai	a4,a4,0x6
ffffffffc0201100:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201102:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201104:	4cd77063          	bgeu	a4,a3,ffffffffc02015c4 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201108:	40f507b3          	sub	a5,a0,a5
ffffffffc020110c:	8799                	srai	a5,a5,0x6
ffffffffc020110e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201110:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201112:	30d7f963          	bgeu	a5,a3,ffffffffc0201424 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0201116:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201118:	00043c03          	ld	s8,0(s0)
ffffffffc020111c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201120:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201124:	e400                	sd	s0,8(s0)
ffffffffc0201126:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201128:	000a5797          	auipc	a5,0xa5
ffffffffc020112c:	6a07a023          	sw	zero,1696(a5) # ffffffffc02a67c8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201130:	5b5000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0201134:	2c051863          	bnez	a0,ffffffffc0201404 <default_check+0x3c2>
    free_page(p0);
ffffffffc0201138:	4585                	li	a1,1
ffffffffc020113a:	8556                	mv	a0,s5
ffffffffc020113c:	5e7000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    free_page(p1);
ffffffffc0201140:	4585                	li	a1,1
ffffffffc0201142:	854e                	mv	a0,s3
ffffffffc0201144:	5df000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    free_page(p2);
ffffffffc0201148:	4585                	li	a1,1
ffffffffc020114a:	8552                	mv	a0,s4
ffffffffc020114c:	5d7000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    assert(nr_free == 3);
ffffffffc0201150:	4818                	lw	a4,16(s0)
ffffffffc0201152:	478d                	li	a5,3
ffffffffc0201154:	28f71863          	bne	a4,a5,ffffffffc02013e4 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201158:	4505                	li	a0,1
ffffffffc020115a:	58b000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc020115e:	89aa                	mv	s3,a0
ffffffffc0201160:	26050263          	beqz	a0,ffffffffc02013c4 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201164:	4505                	li	a0,1
ffffffffc0201166:	57f000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc020116a:	8aaa                	mv	s5,a0
ffffffffc020116c:	3a050c63          	beqz	a0,ffffffffc0201524 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201170:	4505                	li	a0,1
ffffffffc0201172:	573000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0201176:	8a2a                	mv	s4,a0
ffffffffc0201178:	38050663          	beqz	a0,ffffffffc0201504 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc020117c:	4505                	li	a0,1
ffffffffc020117e:	567000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0201182:	36051163          	bnez	a0,ffffffffc02014e4 <default_check+0x4a2>
    free_page(p0);
ffffffffc0201186:	4585                	li	a1,1
ffffffffc0201188:	854e                	mv	a0,s3
ffffffffc020118a:	599000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020118e:	641c                	ld	a5,8(s0)
ffffffffc0201190:	20878a63          	beq	a5,s0,ffffffffc02013a4 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201194:	4505                	li	a0,1
ffffffffc0201196:	54f000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc020119a:	30a99563          	bne	s3,a0,ffffffffc02014a4 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020119e:	4505                	li	a0,1
ffffffffc02011a0:	545000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02011a4:	2e051063          	bnez	a0,ffffffffc0201484 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02011a8:	481c                	lw	a5,16(s0)
ffffffffc02011aa:	2a079d63          	bnez	a5,ffffffffc0201464 <default_check+0x422>
    free_page(p);
ffffffffc02011ae:	854e                	mv	a0,s3
ffffffffc02011b0:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02011b2:	01843023          	sd	s8,0(s0)
ffffffffc02011b6:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02011ba:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02011be:	565000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    free_page(p1);
ffffffffc02011c2:	4585                	li	a1,1
ffffffffc02011c4:	8556                	mv	a0,s5
ffffffffc02011c6:	55d000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    free_page(p2);
ffffffffc02011ca:	4585                	li	a1,1
ffffffffc02011cc:	8552                	mv	a0,s4
ffffffffc02011ce:	555000ef          	jal	ra,ffffffffc0201f22 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02011d2:	4515                	li	a0,5
ffffffffc02011d4:	511000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02011d8:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011da:	26050563          	beqz	a0,ffffffffc0201444 <default_check+0x402>
ffffffffc02011de:	651c                	ld	a5,8(a0)
ffffffffc02011e0:	8385                	srli	a5,a5,0x1
ffffffffc02011e2:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02011e4:	54079063          	bnez	a5,ffffffffc0201724 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011e8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011ea:	00043b03          	ld	s6,0(s0)
ffffffffc02011ee:	00843a83          	ld	s5,8(s0)
ffffffffc02011f2:	e000                	sd	s0,0(s0)
ffffffffc02011f4:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011f6:	4ef000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02011fa:	50051563          	bnez	a0,ffffffffc0201704 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011fe:	08098a13          	addi	s4,s3,128
ffffffffc0201202:	8552                	mv	a0,s4
ffffffffc0201204:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201206:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020120a:	000a5797          	auipc	a5,0xa5
ffffffffc020120e:	5a07af23          	sw	zero,1470(a5) # ffffffffc02a67c8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201212:	511000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201216:	4511                	li	a0,4
ffffffffc0201218:	4cd000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc020121c:	4c051463          	bnez	a0,ffffffffc02016e4 <default_check+0x6a2>
ffffffffc0201220:	0889b783          	ld	a5,136(s3)
ffffffffc0201224:	8385                	srli	a5,a5,0x1
ffffffffc0201226:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201228:	48078e63          	beqz	a5,ffffffffc02016c4 <default_check+0x682>
ffffffffc020122c:	0909a703          	lw	a4,144(s3)
ffffffffc0201230:	478d                	li	a5,3
ffffffffc0201232:	48f71963          	bne	a4,a5,ffffffffc02016c4 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201236:	450d                	li	a0,3
ffffffffc0201238:	4ad000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc020123c:	8c2a                	mv	s8,a0
ffffffffc020123e:	46050363          	beqz	a0,ffffffffc02016a4 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201242:	4505                	li	a0,1
ffffffffc0201244:	4a1000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0201248:	42051e63          	bnez	a0,ffffffffc0201684 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc020124c:	418a1c63          	bne	s4,s8,ffffffffc0201664 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201250:	4585                	li	a1,1
ffffffffc0201252:	854e                	mv	a0,s3
ffffffffc0201254:	4cf000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    free_pages(p1, 3);
ffffffffc0201258:	458d                	li	a1,3
ffffffffc020125a:	8552                	mv	a0,s4
ffffffffc020125c:	4c7000ef          	jal	ra,ffffffffc0201f22 <free_pages>
ffffffffc0201260:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201264:	04098c13          	addi	s8,s3,64
ffffffffc0201268:	8385                	srli	a5,a5,0x1
ffffffffc020126a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020126c:	3c078c63          	beqz	a5,ffffffffc0201644 <default_check+0x602>
ffffffffc0201270:	0109a703          	lw	a4,16(s3)
ffffffffc0201274:	4785                	li	a5,1
ffffffffc0201276:	3cf71763          	bne	a4,a5,ffffffffc0201644 <default_check+0x602>
ffffffffc020127a:	008a3783          	ld	a5,8(s4)
ffffffffc020127e:	8385                	srli	a5,a5,0x1
ffffffffc0201280:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201282:	3a078163          	beqz	a5,ffffffffc0201624 <default_check+0x5e2>
ffffffffc0201286:	010a2703          	lw	a4,16(s4)
ffffffffc020128a:	478d                	li	a5,3
ffffffffc020128c:	38f71c63          	bne	a4,a5,ffffffffc0201624 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201290:	4505                	li	a0,1
ffffffffc0201292:	453000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0201296:	36a99763          	bne	s3,a0,ffffffffc0201604 <default_check+0x5c2>
    free_page(p0);
ffffffffc020129a:	4585                	li	a1,1
ffffffffc020129c:	487000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012a0:	4509                	li	a0,2
ffffffffc02012a2:	443000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02012a6:	32aa1f63          	bne	s4,a0,ffffffffc02015e4 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02012aa:	4589                	li	a1,2
ffffffffc02012ac:	477000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    free_page(p2);
ffffffffc02012b0:	4585                	li	a1,1
ffffffffc02012b2:	8562                	mv	a0,s8
ffffffffc02012b4:	46f000ef          	jal	ra,ffffffffc0201f22 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012b8:	4515                	li	a0,5
ffffffffc02012ba:	42b000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02012be:	89aa                	mv	s3,a0
ffffffffc02012c0:	48050263          	beqz	a0,ffffffffc0201744 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02012c4:	4505                	li	a0,1
ffffffffc02012c6:	41f000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02012ca:	2c051d63          	bnez	a0,ffffffffc02015a4 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02012ce:	481c                	lw	a5,16(s0)
ffffffffc02012d0:	2a079a63          	bnez	a5,ffffffffc0201584 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012d4:	4595                	li	a1,5
ffffffffc02012d6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02012d8:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02012dc:	01643023          	sd	s6,0(s0)
ffffffffc02012e0:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02012e4:	43f000ef          	jal	ra,ffffffffc0201f22 <free_pages>
    return listelm->next;
ffffffffc02012e8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012ea:	00878963          	beq	a5,s0,ffffffffc02012fc <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012ee:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012f2:	679c                	ld	a5,8(a5)
ffffffffc02012f4:	397d                	addiw	s2,s2,-1
ffffffffc02012f6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012f8:	fe879be3          	bne	a5,s0,ffffffffc02012ee <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02012fc:	26091463          	bnez	s2,ffffffffc0201564 <default_check+0x522>
    assert(total == 0);
ffffffffc0201300:	46049263          	bnez	s1,ffffffffc0201764 <default_check+0x722>
}
ffffffffc0201304:	60a6                	ld	ra,72(sp)
ffffffffc0201306:	6406                	ld	s0,64(sp)
ffffffffc0201308:	74e2                	ld	s1,56(sp)
ffffffffc020130a:	7942                	ld	s2,48(sp)
ffffffffc020130c:	79a2                	ld	s3,40(sp)
ffffffffc020130e:	7a02                	ld	s4,32(sp)
ffffffffc0201310:	6ae2                	ld	s5,24(sp)
ffffffffc0201312:	6b42                	ld	s6,16(sp)
ffffffffc0201314:	6ba2                	ld	s7,8(sp)
ffffffffc0201316:	6c02                	ld	s8,0(sp)
ffffffffc0201318:	6161                	addi	sp,sp,80
ffffffffc020131a:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc020131c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020131e:	4481                	li	s1,0
ffffffffc0201320:	4901                	li	s2,0
ffffffffc0201322:	b38d                	j	ffffffffc0201084 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201324:	00005697          	auipc	a3,0x5
ffffffffc0201328:	1b468693          	addi	a3,a3,436 # ffffffffc02064d8 <commands+0x818>
ffffffffc020132c:	00005617          	auipc	a2,0x5
ffffffffc0201330:	1bc60613          	addi	a2,a2,444 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201334:	11000593          	li	a1,272
ffffffffc0201338:	00005517          	auipc	a0,0x5
ffffffffc020133c:	1c850513          	addi	a0,a0,456 # ffffffffc0206500 <commands+0x840>
ffffffffc0201340:	94eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201344:	00005697          	auipc	a3,0x5
ffffffffc0201348:	25468693          	addi	a3,a3,596 # ffffffffc0206598 <commands+0x8d8>
ffffffffc020134c:	00005617          	auipc	a2,0x5
ffffffffc0201350:	19c60613          	addi	a2,a2,412 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201354:	0db00593          	li	a1,219
ffffffffc0201358:	00005517          	auipc	a0,0x5
ffffffffc020135c:	1a850513          	addi	a0,a0,424 # ffffffffc0206500 <commands+0x840>
ffffffffc0201360:	92eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201364:	00005697          	auipc	a3,0x5
ffffffffc0201368:	25c68693          	addi	a3,a3,604 # ffffffffc02065c0 <commands+0x900>
ffffffffc020136c:	00005617          	auipc	a2,0x5
ffffffffc0201370:	17c60613          	addi	a2,a2,380 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201374:	0dc00593          	li	a1,220
ffffffffc0201378:	00005517          	auipc	a0,0x5
ffffffffc020137c:	18850513          	addi	a0,a0,392 # ffffffffc0206500 <commands+0x840>
ffffffffc0201380:	90eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201384:	00005697          	auipc	a3,0x5
ffffffffc0201388:	27c68693          	addi	a3,a3,636 # ffffffffc0206600 <commands+0x940>
ffffffffc020138c:	00005617          	auipc	a2,0x5
ffffffffc0201390:	15c60613          	addi	a2,a2,348 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201394:	0de00593          	li	a1,222
ffffffffc0201398:	00005517          	auipc	a0,0x5
ffffffffc020139c:	16850513          	addi	a0,a0,360 # ffffffffc0206500 <commands+0x840>
ffffffffc02013a0:	8eeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02013a4:	00005697          	auipc	a3,0x5
ffffffffc02013a8:	2e468693          	addi	a3,a3,740 # ffffffffc0206688 <commands+0x9c8>
ffffffffc02013ac:	00005617          	auipc	a2,0x5
ffffffffc02013b0:	13c60613          	addi	a2,a2,316 # ffffffffc02064e8 <commands+0x828>
ffffffffc02013b4:	0f700593          	li	a1,247
ffffffffc02013b8:	00005517          	auipc	a0,0x5
ffffffffc02013bc:	14850513          	addi	a0,a0,328 # ffffffffc0206500 <commands+0x840>
ffffffffc02013c0:	8ceff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013c4:	00005697          	auipc	a3,0x5
ffffffffc02013c8:	17468693          	addi	a3,a3,372 # ffffffffc0206538 <commands+0x878>
ffffffffc02013cc:	00005617          	auipc	a2,0x5
ffffffffc02013d0:	11c60613          	addi	a2,a2,284 # ffffffffc02064e8 <commands+0x828>
ffffffffc02013d4:	0f000593          	li	a1,240
ffffffffc02013d8:	00005517          	auipc	a0,0x5
ffffffffc02013dc:	12850513          	addi	a0,a0,296 # ffffffffc0206500 <commands+0x840>
ffffffffc02013e0:	8aeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02013e4:	00005697          	auipc	a3,0x5
ffffffffc02013e8:	29468693          	addi	a3,a3,660 # ffffffffc0206678 <commands+0x9b8>
ffffffffc02013ec:	00005617          	auipc	a2,0x5
ffffffffc02013f0:	0fc60613          	addi	a2,a2,252 # ffffffffc02064e8 <commands+0x828>
ffffffffc02013f4:	0ee00593          	li	a1,238
ffffffffc02013f8:	00005517          	auipc	a0,0x5
ffffffffc02013fc:	10850513          	addi	a0,a0,264 # ffffffffc0206500 <commands+0x840>
ffffffffc0201400:	88eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201404:	00005697          	auipc	a3,0x5
ffffffffc0201408:	25c68693          	addi	a3,a3,604 # ffffffffc0206660 <commands+0x9a0>
ffffffffc020140c:	00005617          	auipc	a2,0x5
ffffffffc0201410:	0dc60613          	addi	a2,a2,220 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201414:	0e900593          	li	a1,233
ffffffffc0201418:	00005517          	auipc	a0,0x5
ffffffffc020141c:	0e850513          	addi	a0,a0,232 # ffffffffc0206500 <commands+0x840>
ffffffffc0201420:	86eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201424:	00005697          	auipc	a3,0x5
ffffffffc0201428:	21c68693          	addi	a3,a3,540 # ffffffffc0206640 <commands+0x980>
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	0bc60613          	addi	a2,a2,188 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201434:	0e000593          	li	a1,224
ffffffffc0201438:	00005517          	auipc	a0,0x5
ffffffffc020143c:	0c850513          	addi	a0,a0,200 # ffffffffc0206500 <commands+0x840>
ffffffffc0201440:	84eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc0201444:	00005697          	auipc	a3,0x5
ffffffffc0201448:	28c68693          	addi	a3,a3,652 # ffffffffc02066d0 <commands+0xa10>
ffffffffc020144c:	00005617          	auipc	a2,0x5
ffffffffc0201450:	09c60613          	addi	a2,a2,156 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201454:	11800593          	li	a1,280
ffffffffc0201458:	00005517          	auipc	a0,0x5
ffffffffc020145c:	0a850513          	addi	a0,a0,168 # ffffffffc0206500 <commands+0x840>
ffffffffc0201460:	82eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201464:	00005697          	auipc	a3,0x5
ffffffffc0201468:	25c68693          	addi	a3,a3,604 # ffffffffc02066c0 <commands+0xa00>
ffffffffc020146c:	00005617          	auipc	a2,0x5
ffffffffc0201470:	07c60613          	addi	a2,a2,124 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201474:	0fd00593          	li	a1,253
ffffffffc0201478:	00005517          	auipc	a0,0x5
ffffffffc020147c:	08850513          	addi	a0,a0,136 # ffffffffc0206500 <commands+0x840>
ffffffffc0201480:	80eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201484:	00005697          	auipc	a3,0x5
ffffffffc0201488:	1dc68693          	addi	a3,a3,476 # ffffffffc0206660 <commands+0x9a0>
ffffffffc020148c:	00005617          	auipc	a2,0x5
ffffffffc0201490:	05c60613          	addi	a2,a2,92 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201494:	0fb00593          	li	a1,251
ffffffffc0201498:	00005517          	auipc	a0,0x5
ffffffffc020149c:	06850513          	addi	a0,a0,104 # ffffffffc0206500 <commands+0x840>
ffffffffc02014a0:	feffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02014a4:	00005697          	auipc	a3,0x5
ffffffffc02014a8:	1fc68693          	addi	a3,a3,508 # ffffffffc02066a0 <commands+0x9e0>
ffffffffc02014ac:	00005617          	auipc	a2,0x5
ffffffffc02014b0:	03c60613          	addi	a2,a2,60 # ffffffffc02064e8 <commands+0x828>
ffffffffc02014b4:	0fa00593          	li	a1,250
ffffffffc02014b8:	00005517          	auipc	a0,0x5
ffffffffc02014bc:	04850513          	addi	a0,a0,72 # ffffffffc0206500 <commands+0x840>
ffffffffc02014c0:	fcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014c4:	00005697          	auipc	a3,0x5
ffffffffc02014c8:	07468693          	addi	a3,a3,116 # ffffffffc0206538 <commands+0x878>
ffffffffc02014cc:	00005617          	auipc	a2,0x5
ffffffffc02014d0:	01c60613          	addi	a2,a2,28 # ffffffffc02064e8 <commands+0x828>
ffffffffc02014d4:	0d700593          	li	a1,215
ffffffffc02014d8:	00005517          	auipc	a0,0x5
ffffffffc02014dc:	02850513          	addi	a0,a0,40 # ffffffffc0206500 <commands+0x840>
ffffffffc02014e0:	faffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e4:	00005697          	auipc	a3,0x5
ffffffffc02014e8:	17c68693          	addi	a3,a3,380 # ffffffffc0206660 <commands+0x9a0>
ffffffffc02014ec:	00005617          	auipc	a2,0x5
ffffffffc02014f0:	ffc60613          	addi	a2,a2,-4 # ffffffffc02064e8 <commands+0x828>
ffffffffc02014f4:	0f400593          	li	a1,244
ffffffffc02014f8:	00005517          	auipc	a0,0x5
ffffffffc02014fc:	00850513          	addi	a0,a0,8 # ffffffffc0206500 <commands+0x840>
ffffffffc0201500:	f8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201504:	00005697          	auipc	a3,0x5
ffffffffc0201508:	07468693          	addi	a3,a3,116 # ffffffffc0206578 <commands+0x8b8>
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	fdc60613          	addi	a2,a2,-36 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201514:	0f200593          	li	a1,242
ffffffffc0201518:	00005517          	auipc	a0,0x5
ffffffffc020151c:	fe850513          	addi	a0,a0,-24 # ffffffffc0206500 <commands+0x840>
ffffffffc0201520:	f6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201524:	00005697          	auipc	a3,0x5
ffffffffc0201528:	03468693          	addi	a3,a3,52 # ffffffffc0206558 <commands+0x898>
ffffffffc020152c:	00005617          	auipc	a2,0x5
ffffffffc0201530:	fbc60613          	addi	a2,a2,-68 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201534:	0f100593          	li	a1,241
ffffffffc0201538:	00005517          	auipc	a0,0x5
ffffffffc020153c:	fc850513          	addi	a0,a0,-56 # ffffffffc0206500 <commands+0x840>
ffffffffc0201540:	f4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201544:	00005697          	auipc	a3,0x5
ffffffffc0201548:	03468693          	addi	a3,a3,52 # ffffffffc0206578 <commands+0x8b8>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	f9c60613          	addi	a2,a2,-100 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201554:	0d900593          	li	a1,217
ffffffffc0201558:	00005517          	auipc	a0,0x5
ffffffffc020155c:	fa850513          	addi	a0,a0,-88 # ffffffffc0206500 <commands+0x840>
ffffffffc0201560:	f2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201564:	00005697          	auipc	a3,0x5
ffffffffc0201568:	2bc68693          	addi	a3,a3,700 # ffffffffc0206820 <commands+0xb60>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	f7c60613          	addi	a2,a2,-132 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201574:	14600593          	li	a1,326
ffffffffc0201578:	00005517          	auipc	a0,0x5
ffffffffc020157c:	f8850513          	addi	a0,a0,-120 # ffffffffc0206500 <commands+0x840>
ffffffffc0201580:	f0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201584:	00005697          	auipc	a3,0x5
ffffffffc0201588:	13c68693          	addi	a3,a3,316 # ffffffffc02066c0 <commands+0xa00>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	f5c60613          	addi	a2,a2,-164 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201594:	13a00593          	li	a1,314
ffffffffc0201598:	00005517          	auipc	a0,0x5
ffffffffc020159c:	f6850513          	addi	a0,a0,-152 # ffffffffc0206500 <commands+0x840>
ffffffffc02015a0:	eeffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015a4:	00005697          	auipc	a3,0x5
ffffffffc02015a8:	0bc68693          	addi	a3,a3,188 # ffffffffc0206660 <commands+0x9a0>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	f3c60613          	addi	a2,a2,-196 # ffffffffc02064e8 <commands+0x828>
ffffffffc02015b4:	13800593          	li	a1,312
ffffffffc02015b8:	00005517          	auipc	a0,0x5
ffffffffc02015bc:	f4850513          	addi	a0,a0,-184 # ffffffffc0206500 <commands+0x840>
ffffffffc02015c0:	ecffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015c4:	00005697          	auipc	a3,0x5
ffffffffc02015c8:	05c68693          	addi	a3,a3,92 # ffffffffc0206620 <commands+0x960>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	f1c60613          	addi	a2,a2,-228 # ffffffffc02064e8 <commands+0x828>
ffffffffc02015d4:	0df00593          	li	a1,223
ffffffffc02015d8:	00005517          	auipc	a0,0x5
ffffffffc02015dc:	f2850513          	addi	a0,a0,-216 # ffffffffc0206500 <commands+0x840>
ffffffffc02015e0:	eaffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015e4:	00005697          	auipc	a3,0x5
ffffffffc02015e8:	1fc68693          	addi	a3,a3,508 # ffffffffc02067e0 <commands+0xb20>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	efc60613          	addi	a2,a2,-260 # ffffffffc02064e8 <commands+0x828>
ffffffffc02015f4:	13200593          	li	a1,306
ffffffffc02015f8:	00005517          	auipc	a0,0x5
ffffffffc02015fc:	f0850513          	addi	a0,a0,-248 # ffffffffc0206500 <commands+0x840>
ffffffffc0201600:	e8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201604:	00005697          	auipc	a3,0x5
ffffffffc0201608:	1bc68693          	addi	a3,a3,444 # ffffffffc02067c0 <commands+0xb00>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	edc60613          	addi	a2,a2,-292 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201614:	13000593          	li	a1,304
ffffffffc0201618:	00005517          	auipc	a0,0x5
ffffffffc020161c:	ee850513          	addi	a0,a0,-280 # ffffffffc0206500 <commands+0x840>
ffffffffc0201620:	e6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201624:	00005697          	auipc	a3,0x5
ffffffffc0201628:	17468693          	addi	a3,a3,372 # ffffffffc0206798 <commands+0xad8>
ffffffffc020162c:	00005617          	auipc	a2,0x5
ffffffffc0201630:	ebc60613          	addi	a2,a2,-324 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201634:	12e00593          	li	a1,302
ffffffffc0201638:	00005517          	auipc	a0,0x5
ffffffffc020163c:	ec850513          	addi	a0,a0,-312 # ffffffffc0206500 <commands+0x840>
ffffffffc0201640:	e4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201644:	00005697          	auipc	a3,0x5
ffffffffc0201648:	12c68693          	addi	a3,a3,300 # ffffffffc0206770 <commands+0xab0>
ffffffffc020164c:	00005617          	auipc	a2,0x5
ffffffffc0201650:	e9c60613          	addi	a2,a2,-356 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201654:	12d00593          	li	a1,301
ffffffffc0201658:	00005517          	auipc	a0,0x5
ffffffffc020165c:	ea850513          	addi	a0,a0,-344 # ffffffffc0206500 <commands+0x840>
ffffffffc0201660:	e2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201664:	00005697          	auipc	a3,0x5
ffffffffc0201668:	0fc68693          	addi	a3,a3,252 # ffffffffc0206760 <commands+0xaa0>
ffffffffc020166c:	00005617          	auipc	a2,0x5
ffffffffc0201670:	e7c60613          	addi	a2,a2,-388 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201674:	12800593          	li	a1,296
ffffffffc0201678:	00005517          	auipc	a0,0x5
ffffffffc020167c:	e8850513          	addi	a0,a0,-376 # ffffffffc0206500 <commands+0x840>
ffffffffc0201680:	e0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201684:	00005697          	auipc	a3,0x5
ffffffffc0201688:	fdc68693          	addi	a3,a3,-36 # ffffffffc0206660 <commands+0x9a0>
ffffffffc020168c:	00005617          	auipc	a2,0x5
ffffffffc0201690:	e5c60613          	addi	a2,a2,-420 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201694:	12700593          	li	a1,295
ffffffffc0201698:	00005517          	auipc	a0,0x5
ffffffffc020169c:	e6850513          	addi	a0,a0,-408 # ffffffffc0206500 <commands+0x840>
ffffffffc02016a0:	deffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02016a4:	00005697          	auipc	a3,0x5
ffffffffc02016a8:	09c68693          	addi	a3,a3,156 # ffffffffc0206740 <commands+0xa80>
ffffffffc02016ac:	00005617          	auipc	a2,0x5
ffffffffc02016b0:	e3c60613          	addi	a2,a2,-452 # ffffffffc02064e8 <commands+0x828>
ffffffffc02016b4:	12600593          	li	a1,294
ffffffffc02016b8:	00005517          	auipc	a0,0x5
ffffffffc02016bc:	e4850513          	addi	a0,a0,-440 # ffffffffc0206500 <commands+0x840>
ffffffffc02016c0:	dcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016c4:	00005697          	auipc	a3,0x5
ffffffffc02016c8:	04c68693          	addi	a3,a3,76 # ffffffffc0206710 <commands+0xa50>
ffffffffc02016cc:	00005617          	auipc	a2,0x5
ffffffffc02016d0:	e1c60613          	addi	a2,a2,-484 # ffffffffc02064e8 <commands+0x828>
ffffffffc02016d4:	12500593          	li	a1,293
ffffffffc02016d8:	00005517          	auipc	a0,0x5
ffffffffc02016dc:	e2850513          	addi	a0,a0,-472 # ffffffffc0206500 <commands+0x840>
ffffffffc02016e0:	daffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016e4:	00005697          	auipc	a3,0x5
ffffffffc02016e8:	01468693          	addi	a3,a3,20 # ffffffffc02066f8 <commands+0xa38>
ffffffffc02016ec:	00005617          	auipc	a2,0x5
ffffffffc02016f0:	dfc60613          	addi	a2,a2,-516 # ffffffffc02064e8 <commands+0x828>
ffffffffc02016f4:	12400593          	li	a1,292
ffffffffc02016f8:	00005517          	auipc	a0,0x5
ffffffffc02016fc:	e0850513          	addi	a0,a0,-504 # ffffffffc0206500 <commands+0x840>
ffffffffc0201700:	d8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201704:	00005697          	auipc	a3,0x5
ffffffffc0201708:	f5c68693          	addi	a3,a3,-164 # ffffffffc0206660 <commands+0x9a0>
ffffffffc020170c:	00005617          	auipc	a2,0x5
ffffffffc0201710:	ddc60613          	addi	a2,a2,-548 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201714:	11e00593          	li	a1,286
ffffffffc0201718:	00005517          	auipc	a0,0x5
ffffffffc020171c:	de850513          	addi	a0,a0,-536 # ffffffffc0206500 <commands+0x840>
ffffffffc0201720:	d6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201724:	00005697          	auipc	a3,0x5
ffffffffc0201728:	fbc68693          	addi	a3,a3,-68 # ffffffffc02066e0 <commands+0xa20>
ffffffffc020172c:	00005617          	auipc	a2,0x5
ffffffffc0201730:	dbc60613          	addi	a2,a2,-580 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201734:	11900593          	li	a1,281
ffffffffc0201738:	00005517          	auipc	a0,0x5
ffffffffc020173c:	dc850513          	addi	a0,a0,-568 # ffffffffc0206500 <commands+0x840>
ffffffffc0201740:	d4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201744:	00005697          	auipc	a3,0x5
ffffffffc0201748:	0bc68693          	addi	a3,a3,188 # ffffffffc0206800 <commands+0xb40>
ffffffffc020174c:	00005617          	auipc	a2,0x5
ffffffffc0201750:	d9c60613          	addi	a2,a2,-612 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201754:	13700593          	li	a1,311
ffffffffc0201758:	00005517          	auipc	a0,0x5
ffffffffc020175c:	da850513          	addi	a0,a0,-600 # ffffffffc0206500 <commands+0x840>
ffffffffc0201760:	d2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201764:	00005697          	auipc	a3,0x5
ffffffffc0201768:	0cc68693          	addi	a3,a3,204 # ffffffffc0206830 <commands+0xb70>
ffffffffc020176c:	00005617          	auipc	a2,0x5
ffffffffc0201770:	d7c60613          	addi	a2,a2,-644 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201774:	14700593          	li	a1,327
ffffffffc0201778:	00005517          	auipc	a0,0x5
ffffffffc020177c:	d8850513          	addi	a0,a0,-632 # ffffffffc0206500 <commands+0x840>
ffffffffc0201780:	d0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201784:	00005697          	auipc	a3,0x5
ffffffffc0201788:	d9468693          	addi	a3,a3,-620 # ffffffffc0206518 <commands+0x858>
ffffffffc020178c:	00005617          	auipc	a2,0x5
ffffffffc0201790:	d5c60613          	addi	a2,a2,-676 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201794:	11300593          	li	a1,275
ffffffffc0201798:	00005517          	auipc	a0,0x5
ffffffffc020179c:	d6850513          	addi	a0,a0,-664 # ffffffffc0206500 <commands+0x840>
ffffffffc02017a0:	ceffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02017a4:	00005697          	auipc	a3,0x5
ffffffffc02017a8:	db468693          	addi	a3,a3,-588 # ffffffffc0206558 <commands+0x898>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	d3c60613          	addi	a2,a2,-708 # ffffffffc02064e8 <commands+0x828>
ffffffffc02017b4:	0d800593          	li	a1,216
ffffffffc02017b8:	00005517          	auipc	a0,0x5
ffffffffc02017bc:	d4850513          	addi	a0,a0,-696 # ffffffffc0206500 <commands+0x840>
ffffffffc02017c0:	ccffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02017c4 <default_free_pages>:
{
ffffffffc02017c4:	1141                	addi	sp,sp,-16
ffffffffc02017c6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017c8:	14058463          	beqz	a1,ffffffffc0201910 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02017cc:	00659693          	slli	a3,a1,0x6
ffffffffc02017d0:	96aa                	add	a3,a3,a0
ffffffffc02017d2:	87aa                	mv	a5,a0
ffffffffc02017d4:	02d50263          	beq	a0,a3,ffffffffc02017f8 <default_free_pages+0x34>
ffffffffc02017d8:	6798                	ld	a4,8(a5)
ffffffffc02017da:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017dc:	10071a63          	bnez	a4,ffffffffc02018f0 <default_free_pages+0x12c>
ffffffffc02017e0:	6798                	ld	a4,8(a5)
ffffffffc02017e2:	8b09                	andi	a4,a4,2
ffffffffc02017e4:	10071663          	bnez	a4,ffffffffc02018f0 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02017e8:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017ec:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017f0:	04078793          	addi	a5,a5,64
ffffffffc02017f4:	fed792e3          	bne	a5,a3,ffffffffc02017d8 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017f8:	2581                	sext.w	a1,a1
ffffffffc02017fa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017fc:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201800:	4789                	li	a5,2
ffffffffc0201802:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201806:	000a5697          	auipc	a3,0xa5
ffffffffc020180a:	fb268693          	addi	a3,a3,-78 # ffffffffc02a67b8 <free_area>
ffffffffc020180e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201810:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201812:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201816:	9db9                	addw	a1,a1,a4
ffffffffc0201818:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020181a:	0ad78463          	beq	a5,a3,ffffffffc02018c2 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc020181e:	fe878713          	addi	a4,a5,-24
ffffffffc0201822:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201826:	4581                	li	a1,0
            if (base < page)
ffffffffc0201828:	00e56a63          	bltu	a0,a4,ffffffffc020183c <default_free_pages+0x78>
    return listelm->next;
ffffffffc020182c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020182e:	04d70c63          	beq	a4,a3,ffffffffc0201886 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201832:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201834:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201838:	fee57ae3          	bgeu	a0,a4,ffffffffc020182c <default_free_pages+0x68>
ffffffffc020183c:	c199                	beqz	a1,ffffffffc0201842 <default_free_pages+0x7e>
ffffffffc020183e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201842:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201844:	e390                	sd	a2,0(a5)
ffffffffc0201846:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201848:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020184a:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc020184c:	00d70d63          	beq	a4,a3,ffffffffc0201866 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201850:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201854:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201858:	02059813          	slli	a6,a1,0x20
ffffffffc020185c:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201860:	97b2                	add	a5,a5,a2
ffffffffc0201862:	02f50c63          	beq	a0,a5,ffffffffc020189a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201866:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201868:	00d78c63          	beq	a5,a3,ffffffffc0201880 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc020186c:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020186e:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201872:	02061593          	slli	a1,a2,0x20
ffffffffc0201876:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020187a:	972a                	add	a4,a4,a0
ffffffffc020187c:	04e68a63          	beq	a3,a4,ffffffffc02018d0 <default_free_pages+0x10c>
}
ffffffffc0201880:	60a2                	ld	ra,8(sp)
ffffffffc0201882:	0141                	addi	sp,sp,16
ffffffffc0201884:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201886:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201888:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020188a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020188c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020188e:	02d70763          	beq	a4,a3,ffffffffc02018bc <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201892:	8832                	mv	a6,a2
ffffffffc0201894:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201896:	87ba                	mv	a5,a4
ffffffffc0201898:	bf71                	j	ffffffffc0201834 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020189a:	491c                	lw	a5,16(a0)
ffffffffc020189c:	9dbd                	addw	a1,a1,a5
ffffffffc020189e:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018a2:	57f5                	li	a5,-3
ffffffffc02018a4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018a8:	01853803          	ld	a6,24(a0)
ffffffffc02018ac:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02018ae:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02018b0:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02018b4:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02018b6:	0105b023          	sd	a6,0(a1)
ffffffffc02018ba:	b77d                	j	ffffffffc0201868 <default_free_pages+0xa4>
ffffffffc02018bc:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018be:	873e                	mv	a4,a5
ffffffffc02018c0:	bf41                	j	ffffffffc0201850 <default_free_pages+0x8c>
}
ffffffffc02018c2:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018c4:	e390                	sd	a2,0(a5)
ffffffffc02018c6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018c8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018ca:	ed1c                	sd	a5,24(a0)
ffffffffc02018cc:	0141                	addi	sp,sp,16
ffffffffc02018ce:	8082                	ret
            base->property += p->property;
ffffffffc02018d0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018d4:	ff078693          	addi	a3,a5,-16
ffffffffc02018d8:	9e39                	addw	a2,a2,a4
ffffffffc02018da:	c910                	sw	a2,16(a0)
ffffffffc02018dc:	5775                	li	a4,-3
ffffffffc02018de:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018e2:	6398                	ld	a4,0(a5)
ffffffffc02018e4:	679c                	ld	a5,8(a5)
}
ffffffffc02018e6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018e8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018ea:	e398                	sd	a4,0(a5)
ffffffffc02018ec:	0141                	addi	sp,sp,16
ffffffffc02018ee:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018f0:	00005697          	auipc	a3,0x5
ffffffffc02018f4:	f5868693          	addi	a3,a3,-168 # ffffffffc0206848 <commands+0xb88>
ffffffffc02018f8:	00005617          	auipc	a2,0x5
ffffffffc02018fc:	bf060613          	addi	a2,a2,-1040 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201900:	09400593          	li	a1,148
ffffffffc0201904:	00005517          	auipc	a0,0x5
ffffffffc0201908:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0206500 <commands+0x840>
ffffffffc020190c:	b83fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201910:	00005697          	auipc	a3,0x5
ffffffffc0201914:	f3068693          	addi	a3,a3,-208 # ffffffffc0206840 <commands+0xb80>
ffffffffc0201918:	00005617          	auipc	a2,0x5
ffffffffc020191c:	bd060613          	addi	a2,a2,-1072 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201920:	09000593          	li	a1,144
ffffffffc0201924:	00005517          	auipc	a0,0x5
ffffffffc0201928:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0206500 <commands+0x840>
ffffffffc020192c:	b63fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201930 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201930:	c941                	beqz	a0,ffffffffc02019c0 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201932:	000a5597          	auipc	a1,0xa5
ffffffffc0201936:	e8658593          	addi	a1,a1,-378 # ffffffffc02a67b8 <free_area>
ffffffffc020193a:	0105a803          	lw	a6,16(a1)
ffffffffc020193e:	872a                	mv	a4,a0
ffffffffc0201940:	02081793          	slli	a5,a6,0x20
ffffffffc0201944:	9381                	srli	a5,a5,0x20
ffffffffc0201946:	00a7ee63          	bltu	a5,a0,ffffffffc0201962 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020194a:	87ae                	mv	a5,a1
ffffffffc020194c:	a801                	j	ffffffffc020195c <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc020194e:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201952:	02069613          	slli	a2,a3,0x20
ffffffffc0201956:	9201                	srli	a2,a2,0x20
ffffffffc0201958:	00e67763          	bgeu	a2,a4,ffffffffc0201966 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020195c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020195e:	feb798e3          	bne	a5,a1,ffffffffc020194e <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201962:	4501                	li	a0,0
}
ffffffffc0201964:	8082                	ret
    return listelm->prev;
ffffffffc0201966:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020196a:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020196e:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201972:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201976:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020197a:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc020197e:	02c77863          	bgeu	a4,a2,ffffffffc02019ae <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201982:	071a                	slli	a4,a4,0x6
ffffffffc0201984:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201986:	41c686bb          	subw	a3,a3,t3
ffffffffc020198a:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020198c:	00870613          	addi	a2,a4,8
ffffffffc0201990:	4689                	li	a3,2
ffffffffc0201992:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201996:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020199a:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020199e:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02019a2:	e290                	sd	a2,0(a3)
ffffffffc02019a4:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02019a8:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02019aa:	01173c23          	sd	a7,24(a4)
ffffffffc02019ae:	41c8083b          	subw	a6,a6,t3
ffffffffc02019b2:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019b6:	5775                	li	a4,-3
ffffffffc02019b8:	17c1                	addi	a5,a5,-16
ffffffffc02019ba:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02019be:	8082                	ret
{
ffffffffc02019c0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02019c2:	00005697          	auipc	a3,0x5
ffffffffc02019c6:	e7e68693          	addi	a3,a3,-386 # ffffffffc0206840 <commands+0xb80>
ffffffffc02019ca:	00005617          	auipc	a2,0x5
ffffffffc02019ce:	b1e60613          	addi	a2,a2,-1250 # ffffffffc02064e8 <commands+0x828>
ffffffffc02019d2:	06c00593          	li	a1,108
ffffffffc02019d6:	00005517          	auipc	a0,0x5
ffffffffc02019da:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0206500 <commands+0x840>
{
ffffffffc02019de:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019e0:	aaffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02019e4 <default_init_memmap>:
{
ffffffffc02019e4:	1141                	addi	sp,sp,-16
ffffffffc02019e6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019e8:	c5f1                	beqz	a1,ffffffffc0201ab4 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc02019ea:	00659693          	slli	a3,a1,0x6
ffffffffc02019ee:	96aa                	add	a3,a3,a0
ffffffffc02019f0:	87aa                	mv	a5,a0
ffffffffc02019f2:	00d50f63          	beq	a0,a3,ffffffffc0201a10 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019f6:	6798                	ld	a4,8(a5)
ffffffffc02019f8:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02019fa:	cf49                	beqz	a4,ffffffffc0201a94 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02019fc:	0007a823          	sw	zero,16(a5)
ffffffffc0201a00:	0007b423          	sd	zero,8(a5)
ffffffffc0201a04:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a08:	04078793          	addi	a5,a5,64
ffffffffc0201a0c:	fed795e3          	bne	a5,a3,ffffffffc02019f6 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a10:	2581                	sext.w	a1,a1
ffffffffc0201a12:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a14:	4789                	li	a5,2
ffffffffc0201a16:	00850713          	addi	a4,a0,8
ffffffffc0201a1a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a1e:	000a5697          	auipc	a3,0xa5
ffffffffc0201a22:	d9a68693          	addi	a3,a3,-614 # ffffffffc02a67b8 <free_area>
ffffffffc0201a26:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a28:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a2a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a2e:	9db9                	addw	a1,a1,a4
ffffffffc0201a30:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a32:	04d78a63          	beq	a5,a3,ffffffffc0201a86 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a36:	fe878713          	addi	a4,a5,-24
ffffffffc0201a3a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a3e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a40:	00e56a63          	bltu	a0,a4,ffffffffc0201a54 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a44:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a46:	02d70263          	beq	a4,a3,ffffffffc0201a6a <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201a4a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a4c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a50:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a44 <default_init_memmap+0x60>
ffffffffc0201a54:	c199                	beqz	a1,ffffffffc0201a5a <default_init_memmap+0x76>
ffffffffc0201a56:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a5a:	6398                	ld	a4,0(a5)
}
ffffffffc0201a5c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a5e:	e390                	sd	a2,0(a5)
ffffffffc0201a60:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a62:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a64:	ed18                	sd	a4,24(a0)
ffffffffc0201a66:	0141                	addi	sp,sp,16
ffffffffc0201a68:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a6a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a6c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a6e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a70:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a72:	00d70663          	beq	a4,a3,ffffffffc0201a7e <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a76:	8832                	mv	a6,a2
ffffffffc0201a78:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a7a:	87ba                	mv	a5,a4
ffffffffc0201a7c:	bfc1                	j	ffffffffc0201a4c <default_init_memmap+0x68>
}
ffffffffc0201a7e:	60a2                	ld	ra,8(sp)
ffffffffc0201a80:	e290                	sd	a2,0(a3)
ffffffffc0201a82:	0141                	addi	sp,sp,16
ffffffffc0201a84:	8082                	ret
ffffffffc0201a86:	60a2                	ld	ra,8(sp)
ffffffffc0201a88:	e390                	sd	a2,0(a5)
ffffffffc0201a8a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a8c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a8e:	ed1c                	sd	a5,24(a0)
ffffffffc0201a90:	0141                	addi	sp,sp,16
ffffffffc0201a92:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a94:	00005697          	auipc	a3,0x5
ffffffffc0201a98:	ddc68693          	addi	a3,a3,-548 # ffffffffc0206870 <commands+0xbb0>
ffffffffc0201a9c:	00005617          	auipc	a2,0x5
ffffffffc0201aa0:	a4c60613          	addi	a2,a2,-1460 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201aa4:	04b00593          	li	a1,75
ffffffffc0201aa8:	00005517          	auipc	a0,0x5
ffffffffc0201aac:	a5850513          	addi	a0,a0,-1448 # ffffffffc0206500 <commands+0x840>
ffffffffc0201ab0:	9dffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201ab4:	00005697          	auipc	a3,0x5
ffffffffc0201ab8:	d8c68693          	addi	a3,a3,-628 # ffffffffc0206840 <commands+0xb80>
ffffffffc0201abc:	00005617          	auipc	a2,0x5
ffffffffc0201ac0:	a2c60613          	addi	a2,a2,-1492 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201ac4:	04700593          	li	a1,71
ffffffffc0201ac8:	00005517          	auipc	a0,0x5
ffffffffc0201acc:	a3850513          	addi	a0,a0,-1480 # ffffffffc0206500 <commands+0x840>
ffffffffc0201ad0:	9bffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ad4 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201ad4:	c94d                	beqz	a0,ffffffffc0201b86 <slob_free+0xb2>
{
ffffffffc0201ad6:	1141                	addi	sp,sp,-16
ffffffffc0201ad8:	e022                	sd	s0,0(sp)
ffffffffc0201ada:	e406                	sd	ra,8(sp)
ffffffffc0201adc:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201ade:	e9c1                	bnez	a1,ffffffffc0201b6e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ae0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ae4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ae6:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ae8:	ebd9                	bnez	a5,ffffffffc0201b7e <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aea:	000a5617          	auipc	a2,0xa5
ffffffffc0201aee:	8be60613          	addi	a2,a2,-1858 # ffffffffc02a63a8 <slobfree>
ffffffffc0201af2:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201af4:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201af6:	679c                	ld	a5,8(a5)
ffffffffc0201af8:	02877a63          	bgeu	a4,s0,ffffffffc0201b2c <slob_free+0x58>
ffffffffc0201afc:	00f46463          	bltu	s0,a5,ffffffffc0201b04 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b00:	fef76ae3          	bltu	a4,a5,ffffffffc0201af4 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201b04:	400c                	lw	a1,0(s0)
ffffffffc0201b06:	00459693          	slli	a3,a1,0x4
ffffffffc0201b0a:	96a2                	add	a3,a3,s0
ffffffffc0201b0c:	02d78a63          	beq	a5,a3,ffffffffc0201b40 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b10:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b12:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b14:	00469793          	slli	a5,a3,0x4
ffffffffc0201b18:	97ba                	add	a5,a5,a4
ffffffffc0201b1a:	02f40e63          	beq	s0,a5,ffffffffc0201b56 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b1e:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b20:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b22:	e129                	bnez	a0,ffffffffc0201b64 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b24:	60a2                	ld	ra,8(sp)
ffffffffc0201b26:	6402                	ld	s0,0(sp)
ffffffffc0201b28:	0141                	addi	sp,sp,16
ffffffffc0201b2a:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b2c:	fcf764e3          	bltu	a4,a5,ffffffffc0201af4 <slob_free+0x20>
ffffffffc0201b30:	fcf472e3          	bgeu	s0,a5,ffffffffc0201af4 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b34:	400c                	lw	a1,0(s0)
ffffffffc0201b36:	00459693          	slli	a3,a1,0x4
ffffffffc0201b3a:	96a2                	add	a3,a3,s0
ffffffffc0201b3c:	fcd79ae3          	bne	a5,a3,ffffffffc0201b10 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b40:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b42:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b44:	9db5                	addw	a1,a1,a3
ffffffffc0201b46:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201b48:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201b4a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b4c:	00469793          	slli	a5,a3,0x4
ffffffffc0201b50:	97ba                	add	a5,a5,a4
ffffffffc0201b52:	fcf416e3          	bne	s0,a5,ffffffffc0201b1e <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b56:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b58:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b5a:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b5c:	9ebd                	addw	a3,a3,a5
ffffffffc0201b5e:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b60:	e70c                	sd	a1,8(a4)
ffffffffc0201b62:	d169                	beqz	a0,ffffffffc0201b24 <slob_free+0x50>
}
ffffffffc0201b64:	6402                	ld	s0,0(sp)
ffffffffc0201b66:	60a2                	ld	ra,8(sp)
ffffffffc0201b68:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b6a:	e45fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b6e:	25bd                	addiw	a1,a1,15
ffffffffc0201b70:	8191                	srli	a1,a1,0x4
ffffffffc0201b72:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b74:	100027f3          	csrr	a5,sstatus
ffffffffc0201b78:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b7a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b7c:	d7bd                	beqz	a5,ffffffffc0201aea <slob_free+0x16>
        intr_disable();
ffffffffc0201b7e:	e37fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b82:	4505                	li	a0,1
ffffffffc0201b84:	b79d                	j	ffffffffc0201aea <slob_free+0x16>
ffffffffc0201b86:	8082                	ret

ffffffffc0201b88 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b88:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b8a:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b8c:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b90:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b92:	352000ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
	if (!page)
ffffffffc0201b96:	c91d                	beqz	a0,ffffffffc0201bcc <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b98:	000a9697          	auipc	a3,0xa9
ffffffffc0201b9c:	c986b683          	ld	a3,-872(a3) # ffffffffc02aa830 <pages>
ffffffffc0201ba0:	8d15                	sub	a0,a0,a3
ffffffffc0201ba2:	8519                	srai	a0,a0,0x6
ffffffffc0201ba4:	00006697          	auipc	a3,0x6
ffffffffc0201ba8:	0946b683          	ld	a3,148(a3) # ffffffffc0207c38 <nbase>
ffffffffc0201bac:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201bae:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bb2:	83b1                	srli	a5,a5,0xc
ffffffffc0201bb4:	000a9717          	auipc	a4,0xa9
ffffffffc0201bb8:	c7473703          	ld	a4,-908(a4) # ffffffffc02aa828 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bbc:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bbe:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bd2 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bc2:	000a9697          	auipc	a3,0xa9
ffffffffc0201bc6:	c7e6b683          	ld	a3,-898(a3) # ffffffffc02aa840 <va_pa_offset>
ffffffffc0201bca:	9536                	add	a0,a0,a3
}
ffffffffc0201bcc:	60a2                	ld	ra,8(sp)
ffffffffc0201bce:	0141                	addi	sp,sp,16
ffffffffc0201bd0:	8082                	ret
ffffffffc0201bd2:	86aa                	mv	a3,a0
ffffffffc0201bd4:	00005617          	auipc	a2,0x5
ffffffffc0201bd8:	cfc60613          	addi	a2,a2,-772 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0201bdc:	07100593          	li	a1,113
ffffffffc0201be0:	00005517          	auipc	a0,0x5
ffffffffc0201be4:	d1850513          	addi	a0,a0,-744 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0201be8:	8a7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201bec <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bec:	1101                	addi	sp,sp,-32
ffffffffc0201bee:	ec06                	sd	ra,24(sp)
ffffffffc0201bf0:	e822                	sd	s0,16(sp)
ffffffffc0201bf2:	e426                	sd	s1,8(sp)
ffffffffc0201bf4:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bf6:	01050713          	addi	a4,a0,16
ffffffffc0201bfa:	6785                	lui	a5,0x1
ffffffffc0201bfc:	0cf77363          	bgeu	a4,a5,ffffffffc0201cc2 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c00:	00f50493          	addi	s1,a0,15
ffffffffc0201c04:	8091                	srli	s1,s1,0x4
ffffffffc0201c06:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c08:	10002673          	csrr	a2,sstatus
ffffffffc0201c0c:	8a09                	andi	a2,a2,2
ffffffffc0201c0e:	e25d                	bnez	a2,ffffffffc0201cb4 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c10:	000a4917          	auipc	s2,0xa4
ffffffffc0201c14:	79890913          	addi	s2,s2,1944 # ffffffffc02a63a8 <slobfree>
ffffffffc0201c18:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c1c:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c1e:	4398                	lw	a4,0(a5)
ffffffffc0201c20:	08975e63          	bge	a4,s1,ffffffffc0201cbc <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c24:	00f68b63          	beq	a3,a5,ffffffffc0201c3a <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c28:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c2a:	4018                	lw	a4,0(s0)
ffffffffc0201c2c:	02975a63          	bge	a4,s1,ffffffffc0201c60 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c30:	00093683          	ld	a3,0(s2)
ffffffffc0201c34:	87a2                	mv	a5,s0
ffffffffc0201c36:	fef699e3          	bne	a3,a5,ffffffffc0201c28 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c3a:	ee31                	bnez	a2,ffffffffc0201c96 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c3c:	4501                	li	a0,0
ffffffffc0201c3e:	f4bff0ef          	jal	ra,ffffffffc0201b88 <__slob_get_free_pages.constprop.0>
ffffffffc0201c42:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c44:	cd05                	beqz	a0,ffffffffc0201c7c <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c46:	6585                	lui	a1,0x1
ffffffffc0201c48:	e8dff0ef          	jal	ra,ffffffffc0201ad4 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c4c:	10002673          	csrr	a2,sstatus
ffffffffc0201c50:	8a09                	andi	a2,a2,2
ffffffffc0201c52:	ee05                	bnez	a2,ffffffffc0201c8a <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c54:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c58:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c5a:	4018                	lw	a4,0(s0)
ffffffffc0201c5c:	fc974ae3          	blt	a4,s1,ffffffffc0201c30 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c60:	04e48763          	beq	s1,a4,ffffffffc0201cae <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c64:	00449693          	slli	a3,s1,0x4
ffffffffc0201c68:	96a2                	add	a3,a3,s0
ffffffffc0201c6a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c6c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c6e:	9f05                	subw	a4,a4,s1
ffffffffc0201c70:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c72:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c74:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c76:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c7a:	e20d                	bnez	a2,ffffffffc0201c9c <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c7c:	60e2                	ld	ra,24(sp)
ffffffffc0201c7e:	8522                	mv	a0,s0
ffffffffc0201c80:	6442                	ld	s0,16(sp)
ffffffffc0201c82:	64a2                	ld	s1,8(sp)
ffffffffc0201c84:	6902                	ld	s2,0(sp)
ffffffffc0201c86:	6105                	addi	sp,sp,32
ffffffffc0201c88:	8082                	ret
        intr_disable();
ffffffffc0201c8a:	d2bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c8e:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c92:	4605                	li	a2,1
ffffffffc0201c94:	b7d1                	j	ffffffffc0201c58 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c96:	d19fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c9a:	b74d                	j	ffffffffc0201c3c <slob_alloc.constprop.0+0x50>
ffffffffc0201c9c:	d13fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201ca0:	60e2                	ld	ra,24(sp)
ffffffffc0201ca2:	8522                	mv	a0,s0
ffffffffc0201ca4:	6442                	ld	s0,16(sp)
ffffffffc0201ca6:	64a2                	ld	s1,8(sp)
ffffffffc0201ca8:	6902                	ld	s2,0(sp)
ffffffffc0201caa:	6105                	addi	sp,sp,32
ffffffffc0201cac:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201cae:	6418                	ld	a4,8(s0)
ffffffffc0201cb0:	e798                	sd	a4,8(a5)
ffffffffc0201cb2:	b7d1                	j	ffffffffc0201c76 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201cb4:	d01fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201cb8:	4605                	li	a2,1
ffffffffc0201cba:	bf99                	j	ffffffffc0201c10 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201cbc:	843e                	mv	s0,a5
ffffffffc0201cbe:	87b6                	mv	a5,a3
ffffffffc0201cc0:	b745                	j	ffffffffc0201c60 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201cc2:	00005697          	auipc	a3,0x5
ffffffffc0201cc6:	c4668693          	addi	a3,a3,-954 # ffffffffc0206908 <default_pmm_manager+0x70>
ffffffffc0201cca:	00005617          	auipc	a2,0x5
ffffffffc0201cce:	81e60613          	addi	a2,a2,-2018 # ffffffffc02064e8 <commands+0x828>
ffffffffc0201cd2:	06300593          	li	a1,99
ffffffffc0201cd6:	00005517          	auipc	a0,0x5
ffffffffc0201cda:	c5250513          	addi	a0,a0,-942 # ffffffffc0206928 <default_pmm_manager+0x90>
ffffffffc0201cde:	fb0fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ce2 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201ce2:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201ce4:	00005517          	auipc	a0,0x5
ffffffffc0201ce8:	c5c50513          	addi	a0,a0,-932 # ffffffffc0206940 <default_pmm_manager+0xa8>
{
ffffffffc0201cec:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cee:	ca6fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cf2:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cf4:	00005517          	auipc	a0,0x5
ffffffffc0201cf8:	c6450513          	addi	a0,a0,-924 # ffffffffc0206958 <default_pmm_manager+0xc0>
}
ffffffffc0201cfc:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cfe:	c96fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d02 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d02:	4501                	li	a0,0
ffffffffc0201d04:	8082                	ret

ffffffffc0201d06 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d06:	1101                	addi	sp,sp,-32
ffffffffc0201d08:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d0a:	6905                	lui	s2,0x1
{
ffffffffc0201d0c:	e822                	sd	s0,16(sp)
ffffffffc0201d0e:	ec06                	sd	ra,24(sp)
ffffffffc0201d10:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d12:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bd1>
{
ffffffffc0201d16:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d18:	04a7f963          	bgeu	a5,a0,ffffffffc0201d6a <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d1c:	4561                	li	a0,24
ffffffffc0201d1e:	ecfff0ef          	jal	ra,ffffffffc0201bec <slob_alloc.constprop.0>
ffffffffc0201d22:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d24:	c929                	beqz	a0,ffffffffc0201d76 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d26:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d2a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d2c:	00f95763          	bge	s2,a5,ffffffffc0201d3a <kmalloc+0x34>
ffffffffc0201d30:	6705                	lui	a4,0x1
ffffffffc0201d32:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d34:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d36:	fef74ee3          	blt	a4,a5,ffffffffc0201d32 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d3a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d3c:	e4dff0ef          	jal	ra,ffffffffc0201b88 <__slob_get_free_pages.constprop.0>
ffffffffc0201d40:	e488                	sd	a0,8(s1)
ffffffffc0201d42:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d44:	c525                	beqz	a0,ffffffffc0201dac <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d46:	100027f3          	csrr	a5,sstatus
ffffffffc0201d4a:	8b89                	andi	a5,a5,2
ffffffffc0201d4c:	ef8d                	bnez	a5,ffffffffc0201d86 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d4e:	000a9797          	auipc	a5,0xa9
ffffffffc0201d52:	ac278793          	addi	a5,a5,-1342 # ffffffffc02aa810 <bigblocks>
ffffffffc0201d56:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d58:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d5a:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d5c:	60e2                	ld	ra,24(sp)
ffffffffc0201d5e:	8522                	mv	a0,s0
ffffffffc0201d60:	6442                	ld	s0,16(sp)
ffffffffc0201d62:	64a2                	ld	s1,8(sp)
ffffffffc0201d64:	6902                	ld	s2,0(sp)
ffffffffc0201d66:	6105                	addi	sp,sp,32
ffffffffc0201d68:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d6a:	0541                	addi	a0,a0,16
ffffffffc0201d6c:	e81ff0ef          	jal	ra,ffffffffc0201bec <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d70:	01050413          	addi	s0,a0,16
ffffffffc0201d74:	f565                	bnez	a0,ffffffffc0201d5c <kmalloc+0x56>
ffffffffc0201d76:	4401                	li	s0,0
}
ffffffffc0201d78:	60e2                	ld	ra,24(sp)
ffffffffc0201d7a:	8522                	mv	a0,s0
ffffffffc0201d7c:	6442                	ld	s0,16(sp)
ffffffffc0201d7e:	64a2                	ld	s1,8(sp)
ffffffffc0201d80:	6902                	ld	s2,0(sp)
ffffffffc0201d82:	6105                	addi	sp,sp,32
ffffffffc0201d84:	8082                	ret
        intr_disable();
ffffffffc0201d86:	c2ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d8a:	000a9797          	auipc	a5,0xa9
ffffffffc0201d8e:	a8678793          	addi	a5,a5,-1402 # ffffffffc02aa810 <bigblocks>
ffffffffc0201d92:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d94:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d96:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d98:	c17fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d9c:	6480                	ld	s0,8(s1)
}
ffffffffc0201d9e:	60e2                	ld	ra,24(sp)
ffffffffc0201da0:	64a2                	ld	s1,8(sp)
ffffffffc0201da2:	8522                	mv	a0,s0
ffffffffc0201da4:	6442                	ld	s0,16(sp)
ffffffffc0201da6:	6902                	ld	s2,0(sp)
ffffffffc0201da8:	6105                	addi	sp,sp,32
ffffffffc0201daa:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dac:	45e1                	li	a1,24
ffffffffc0201dae:	8526                	mv	a0,s1
ffffffffc0201db0:	d25ff0ef          	jal	ra,ffffffffc0201ad4 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201db4:	b765                	j	ffffffffc0201d5c <kmalloc+0x56>

ffffffffc0201db6 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201db6:	c169                	beqz	a0,ffffffffc0201e78 <kfree+0xc2>
{
ffffffffc0201db8:	1101                	addi	sp,sp,-32
ffffffffc0201dba:	e822                	sd	s0,16(sp)
ffffffffc0201dbc:	ec06                	sd	ra,24(sp)
ffffffffc0201dbe:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201dc0:	03451793          	slli	a5,a0,0x34
ffffffffc0201dc4:	842a                	mv	s0,a0
ffffffffc0201dc6:	e3d9                	bnez	a5,ffffffffc0201e4c <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dc8:	100027f3          	csrr	a5,sstatus
ffffffffc0201dcc:	8b89                	andi	a5,a5,2
ffffffffc0201dce:	e7d9                	bnez	a5,ffffffffc0201e5c <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dd0:	000a9797          	auipc	a5,0xa9
ffffffffc0201dd4:	a407b783          	ld	a5,-1472(a5) # ffffffffc02aa810 <bigblocks>
    return 0;
ffffffffc0201dd8:	4601                	li	a2,0
ffffffffc0201dda:	cbad                	beqz	a5,ffffffffc0201e4c <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201ddc:	000a9697          	auipc	a3,0xa9
ffffffffc0201de0:	a3468693          	addi	a3,a3,-1484 # ffffffffc02aa810 <bigblocks>
ffffffffc0201de4:	a021                	j	ffffffffc0201dec <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201de6:	01048693          	addi	a3,s1,16
ffffffffc0201dea:	c3a5                	beqz	a5,ffffffffc0201e4a <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201dec:	6798                	ld	a4,8(a5)
ffffffffc0201dee:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201df0:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201df2:	fe871ae3          	bne	a4,s0,ffffffffc0201de6 <kfree+0x30>
				*last = bb->next;
ffffffffc0201df6:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201df8:	ee2d                	bnez	a2,ffffffffc0201e72 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201dfa:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201dfe:	4098                	lw	a4,0(s1)
ffffffffc0201e00:	08f46963          	bltu	s0,a5,ffffffffc0201e92 <kfree+0xdc>
ffffffffc0201e04:	000a9697          	auipc	a3,0xa9
ffffffffc0201e08:	a3c6b683          	ld	a3,-1476(a3) # ffffffffc02aa840 <va_pa_offset>
ffffffffc0201e0c:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e0e:	8031                	srli	s0,s0,0xc
ffffffffc0201e10:	000a9797          	auipc	a5,0xa9
ffffffffc0201e14:	a187b783          	ld	a5,-1512(a5) # ffffffffc02aa828 <npage>
ffffffffc0201e18:	06f47163          	bgeu	s0,a5,ffffffffc0201e7a <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e1c:	00006517          	auipc	a0,0x6
ffffffffc0201e20:	e1c53503          	ld	a0,-484(a0) # ffffffffc0207c38 <nbase>
ffffffffc0201e24:	8c09                	sub	s0,s0,a0
ffffffffc0201e26:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201e28:	000a9517          	auipc	a0,0xa9
ffffffffc0201e2c:	a0853503          	ld	a0,-1528(a0) # ffffffffc02aa830 <pages>
ffffffffc0201e30:	4585                	li	a1,1
ffffffffc0201e32:	9522                	add	a0,a0,s0
ffffffffc0201e34:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e38:	0ea000ef          	jal	ra,ffffffffc0201f22 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e3c:	6442                	ld	s0,16(sp)
ffffffffc0201e3e:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e40:	8526                	mv	a0,s1
}
ffffffffc0201e42:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e44:	45e1                	li	a1,24
}
ffffffffc0201e46:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e48:	b171                	j	ffffffffc0201ad4 <slob_free>
ffffffffc0201e4a:	e20d                	bnez	a2,ffffffffc0201e6c <kfree+0xb6>
ffffffffc0201e4c:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e50:	6442                	ld	s0,16(sp)
ffffffffc0201e52:	60e2                	ld	ra,24(sp)
ffffffffc0201e54:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e56:	4581                	li	a1,0
}
ffffffffc0201e58:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e5a:	b9ad                	j	ffffffffc0201ad4 <slob_free>
        intr_disable();
ffffffffc0201e5c:	b59fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e60:	000a9797          	auipc	a5,0xa9
ffffffffc0201e64:	9b07b783          	ld	a5,-1616(a5) # ffffffffc02aa810 <bigblocks>
        return 1;
ffffffffc0201e68:	4605                	li	a2,1
ffffffffc0201e6a:	fbad                	bnez	a5,ffffffffc0201ddc <kfree+0x26>
        intr_enable();
ffffffffc0201e6c:	b43fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e70:	bff1                	j	ffffffffc0201e4c <kfree+0x96>
ffffffffc0201e72:	b3dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e76:	b751                	j	ffffffffc0201dfa <kfree+0x44>
ffffffffc0201e78:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e7a:	00005617          	auipc	a2,0x5
ffffffffc0201e7e:	b2660613          	addi	a2,a2,-1242 # ffffffffc02069a0 <default_pmm_manager+0x108>
ffffffffc0201e82:	06900593          	li	a1,105
ffffffffc0201e86:	00005517          	auipc	a0,0x5
ffffffffc0201e8a:	a7250513          	addi	a0,a0,-1422 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0201e8e:	e00fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e92:	86a2                	mv	a3,s0
ffffffffc0201e94:	00005617          	auipc	a2,0x5
ffffffffc0201e98:	ae460613          	addi	a2,a2,-1308 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc0201e9c:	07700593          	li	a1,119
ffffffffc0201ea0:	00005517          	auipc	a0,0x5
ffffffffc0201ea4:	a5850513          	addi	a0,a0,-1448 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0201ea8:	de6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201eac <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201eac:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201eae:	00005617          	auipc	a2,0x5
ffffffffc0201eb2:	af260613          	addi	a2,a2,-1294 # ffffffffc02069a0 <default_pmm_manager+0x108>
ffffffffc0201eb6:	06900593          	li	a1,105
ffffffffc0201eba:	00005517          	auipc	a0,0x5
ffffffffc0201ebe:	a3e50513          	addi	a0,a0,-1474 # ffffffffc02068f8 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201ec2:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201ec4:	dcafe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ec8 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201ec8:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201eca:	00005617          	auipc	a2,0x5
ffffffffc0201ece:	af660613          	addi	a2,a2,-1290 # ffffffffc02069c0 <default_pmm_manager+0x128>
ffffffffc0201ed2:	07f00593          	li	a1,127
ffffffffc0201ed6:	00005517          	auipc	a0,0x5
ffffffffc0201eda:	a2250513          	addi	a0,a0,-1502 # ffffffffc02068f8 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201ede:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201ee0:	daefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ee4 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ee4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ee8:	8b89                	andi	a5,a5,2
ffffffffc0201eea:	e799                	bnez	a5,ffffffffc0201ef8 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eec:	000a9797          	auipc	a5,0xa9
ffffffffc0201ef0:	94c7b783          	ld	a5,-1716(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201ef4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ef6:	8782                	jr	a5
{
ffffffffc0201ef8:	1141                	addi	sp,sp,-16
ffffffffc0201efa:	e406                	sd	ra,8(sp)
ffffffffc0201efc:	e022                	sd	s0,0(sp)
ffffffffc0201efe:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201f00:	ab5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f04:	000a9797          	auipc	a5,0xa9
ffffffffc0201f08:	9347b783          	ld	a5,-1740(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201f0c:	6f9c                	ld	a5,24(a5)
ffffffffc0201f0e:	8522                	mv	a0,s0
ffffffffc0201f10:	9782                	jalr	a5
ffffffffc0201f12:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f14:	a9bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f18:	60a2                	ld	ra,8(sp)
ffffffffc0201f1a:	8522                	mv	a0,s0
ffffffffc0201f1c:	6402                	ld	s0,0(sp)
ffffffffc0201f1e:	0141                	addi	sp,sp,16
ffffffffc0201f20:	8082                	ret

ffffffffc0201f22 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f22:	100027f3          	csrr	a5,sstatus
ffffffffc0201f26:	8b89                	andi	a5,a5,2
ffffffffc0201f28:	e799                	bnez	a5,ffffffffc0201f36 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f2a:	000a9797          	auipc	a5,0xa9
ffffffffc0201f2e:	90e7b783          	ld	a5,-1778(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201f32:	739c                	ld	a5,32(a5)
ffffffffc0201f34:	8782                	jr	a5
{
ffffffffc0201f36:	1101                	addi	sp,sp,-32
ffffffffc0201f38:	ec06                	sd	ra,24(sp)
ffffffffc0201f3a:	e822                	sd	s0,16(sp)
ffffffffc0201f3c:	e426                	sd	s1,8(sp)
ffffffffc0201f3e:	842a                	mv	s0,a0
ffffffffc0201f40:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f42:	a73fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f46:	000a9797          	auipc	a5,0xa9
ffffffffc0201f4a:	8f27b783          	ld	a5,-1806(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201f4e:	739c                	ld	a5,32(a5)
ffffffffc0201f50:	85a6                	mv	a1,s1
ffffffffc0201f52:	8522                	mv	a0,s0
ffffffffc0201f54:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f56:	6442                	ld	s0,16(sp)
ffffffffc0201f58:	60e2                	ld	ra,24(sp)
ffffffffc0201f5a:	64a2                	ld	s1,8(sp)
ffffffffc0201f5c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f5e:	a51fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f62 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f62:	100027f3          	csrr	a5,sstatus
ffffffffc0201f66:	8b89                	andi	a5,a5,2
ffffffffc0201f68:	e799                	bnez	a5,ffffffffc0201f76 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f6a:	000a9797          	auipc	a5,0xa9
ffffffffc0201f6e:	8ce7b783          	ld	a5,-1842(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201f72:	779c                	ld	a5,40(a5)
ffffffffc0201f74:	8782                	jr	a5
{
ffffffffc0201f76:	1141                	addi	sp,sp,-16
ffffffffc0201f78:	e406                	sd	ra,8(sp)
ffffffffc0201f7a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f7c:	a39fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f80:	000a9797          	auipc	a5,0xa9
ffffffffc0201f84:	8b87b783          	ld	a5,-1864(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201f88:	779c                	ld	a5,40(a5)
ffffffffc0201f8a:	9782                	jalr	a5
ffffffffc0201f8c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f8e:	a21fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f92:	60a2                	ld	ra,8(sp)
ffffffffc0201f94:	8522                	mv	a0,s0
ffffffffc0201f96:	6402                	ld	s0,0(sp)
ffffffffc0201f98:	0141                	addi	sp,sp,16
ffffffffc0201f9a:	8082                	ret

ffffffffc0201f9c <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f9c:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201fa0:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201fa4:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fa6:	078e                	slli	a5,a5,0x3
{
ffffffffc0201fa8:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201faa:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fae:	6094                	ld	a3,0(s1)
{
ffffffffc0201fb0:	f04a                	sd	s2,32(sp)
ffffffffc0201fb2:	ec4e                	sd	s3,24(sp)
ffffffffc0201fb4:	e852                	sd	s4,16(sp)
ffffffffc0201fb6:	fc06                	sd	ra,56(sp)
ffffffffc0201fb8:	f822                	sd	s0,48(sp)
ffffffffc0201fba:	e456                	sd	s5,8(sp)
ffffffffc0201fbc:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fbe:	0016f793          	andi	a5,a3,1
{
ffffffffc0201fc2:	892e                	mv	s2,a1
ffffffffc0201fc4:	8a32                	mv	s4,a2
ffffffffc0201fc6:	000a9997          	auipc	s3,0xa9
ffffffffc0201fca:	86298993          	addi	s3,s3,-1950 # ffffffffc02aa828 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fce:	efbd                	bnez	a5,ffffffffc020204c <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fd0:	14060c63          	beqz	a2,ffffffffc0202128 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fd4:	100027f3          	csrr	a5,sstatus
ffffffffc0201fd8:	8b89                	andi	a5,a5,2
ffffffffc0201fda:	14079963          	bnez	a5,ffffffffc020212c <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fde:	000a9797          	auipc	a5,0xa9
ffffffffc0201fe2:	85a7b783          	ld	a5,-1958(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0201fe6:	6f9c                	ld	a5,24(a5)
ffffffffc0201fe8:	4505                	li	a0,1
ffffffffc0201fea:	9782                	jalr	a5
ffffffffc0201fec:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fee:	12040d63          	beqz	s0,ffffffffc0202128 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201ff2:	000a9b17          	auipc	s6,0xa9
ffffffffc0201ff6:	83eb0b13          	addi	s6,s6,-1986 # ffffffffc02aa830 <pages>
ffffffffc0201ffa:	000b3503          	ld	a0,0(s6)
ffffffffc0201ffe:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202002:	000a9997          	auipc	s3,0xa9
ffffffffc0202006:	82698993          	addi	s3,s3,-2010 # ffffffffc02aa828 <npage>
ffffffffc020200a:	40a40533          	sub	a0,s0,a0
ffffffffc020200e:	8519                	srai	a0,a0,0x6
ffffffffc0202010:	9556                	add	a0,a0,s5
ffffffffc0202012:	0009b703          	ld	a4,0(s3)
ffffffffc0202016:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020201a:	4685                	li	a3,1
ffffffffc020201c:	c014                	sw	a3,0(s0)
ffffffffc020201e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202020:	0532                	slli	a0,a0,0xc
ffffffffc0202022:	16e7f763          	bgeu	a5,a4,ffffffffc0202190 <get_pte+0x1f4>
ffffffffc0202026:	000a9797          	auipc	a5,0xa9
ffffffffc020202a:	81a7b783          	ld	a5,-2022(a5) # ffffffffc02aa840 <va_pa_offset>
ffffffffc020202e:	6605                	lui	a2,0x1
ffffffffc0202030:	4581                	li	a1,0
ffffffffc0202032:	953e                	add	a0,a0,a5
ffffffffc0202034:	1fb030ef          	jal	ra,ffffffffc0205a2e <memset>
    return page - pages + nbase;
ffffffffc0202038:	000b3683          	ld	a3,0(s6)
ffffffffc020203c:	40d406b3          	sub	a3,s0,a3
ffffffffc0202040:	8699                	srai	a3,a3,0x6
ffffffffc0202042:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202044:	06aa                	slli	a3,a3,0xa
ffffffffc0202046:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020204a:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020204c:	77fd                	lui	a5,0xfffff
ffffffffc020204e:	068a                	slli	a3,a3,0x2
ffffffffc0202050:	0009b703          	ld	a4,0(s3)
ffffffffc0202054:	8efd                	and	a3,a3,a5
ffffffffc0202056:	00c6d793          	srli	a5,a3,0xc
ffffffffc020205a:	10e7ff63          	bgeu	a5,a4,ffffffffc0202178 <get_pte+0x1dc>
ffffffffc020205e:	000a8a97          	auipc	s5,0xa8
ffffffffc0202062:	7e2a8a93          	addi	s5,s5,2018 # ffffffffc02aa840 <va_pa_offset>
ffffffffc0202066:	000ab403          	ld	s0,0(s5)
ffffffffc020206a:	01595793          	srli	a5,s2,0x15
ffffffffc020206e:	1ff7f793          	andi	a5,a5,511
ffffffffc0202072:	96a2                	add	a3,a3,s0
ffffffffc0202074:	00379413          	slli	s0,a5,0x3
ffffffffc0202078:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020207a:	6014                	ld	a3,0(s0)
ffffffffc020207c:	0016f793          	andi	a5,a3,1
ffffffffc0202080:	ebad                	bnez	a5,ffffffffc02020f2 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202082:	0a0a0363          	beqz	s4,ffffffffc0202128 <get_pte+0x18c>
ffffffffc0202086:	100027f3          	csrr	a5,sstatus
ffffffffc020208a:	8b89                	andi	a5,a5,2
ffffffffc020208c:	efcd                	bnez	a5,ffffffffc0202146 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc020208e:	000a8797          	auipc	a5,0xa8
ffffffffc0202092:	7aa7b783          	ld	a5,1962(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0202096:	6f9c                	ld	a5,24(a5)
ffffffffc0202098:	4505                	li	a0,1
ffffffffc020209a:	9782                	jalr	a5
ffffffffc020209c:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020209e:	c4c9                	beqz	s1,ffffffffc0202128 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020a0:	000a8b17          	auipc	s6,0xa8
ffffffffc02020a4:	790b0b13          	addi	s6,s6,1936 # ffffffffc02aa830 <pages>
ffffffffc02020a8:	000b3503          	ld	a0,0(s6)
ffffffffc02020ac:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020b0:	0009b703          	ld	a4,0(s3)
ffffffffc02020b4:	40a48533          	sub	a0,s1,a0
ffffffffc02020b8:	8519                	srai	a0,a0,0x6
ffffffffc02020ba:	9552                	add	a0,a0,s4
ffffffffc02020bc:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02020c0:	4685                	li	a3,1
ffffffffc02020c2:	c094                	sw	a3,0(s1)
ffffffffc02020c4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02020c6:	0532                	slli	a0,a0,0xc
ffffffffc02020c8:	0ee7f163          	bgeu	a5,a4,ffffffffc02021aa <get_pte+0x20e>
ffffffffc02020cc:	000ab783          	ld	a5,0(s5)
ffffffffc02020d0:	6605                	lui	a2,0x1
ffffffffc02020d2:	4581                	li	a1,0
ffffffffc02020d4:	953e                	add	a0,a0,a5
ffffffffc02020d6:	159030ef          	jal	ra,ffffffffc0205a2e <memset>
    return page - pages + nbase;
ffffffffc02020da:	000b3683          	ld	a3,0(s6)
ffffffffc02020de:	40d486b3          	sub	a3,s1,a3
ffffffffc02020e2:	8699                	srai	a3,a3,0x6
ffffffffc02020e4:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020e6:	06aa                	slli	a3,a3,0xa
ffffffffc02020e8:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020ec:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020ee:	0009b703          	ld	a4,0(s3)
ffffffffc02020f2:	068a                	slli	a3,a3,0x2
ffffffffc02020f4:	757d                	lui	a0,0xfffff
ffffffffc02020f6:	8ee9                	and	a3,a3,a0
ffffffffc02020f8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020fc:	06e7f263          	bgeu	a5,a4,ffffffffc0202160 <get_pte+0x1c4>
ffffffffc0202100:	000ab503          	ld	a0,0(s5)
ffffffffc0202104:	00c95913          	srli	s2,s2,0xc
ffffffffc0202108:	1ff97913          	andi	s2,s2,511
ffffffffc020210c:	96aa                	add	a3,a3,a0
ffffffffc020210e:	00391513          	slli	a0,s2,0x3
ffffffffc0202112:	9536                	add	a0,a0,a3
}
ffffffffc0202114:	70e2                	ld	ra,56(sp)
ffffffffc0202116:	7442                	ld	s0,48(sp)
ffffffffc0202118:	74a2                	ld	s1,40(sp)
ffffffffc020211a:	7902                	ld	s2,32(sp)
ffffffffc020211c:	69e2                	ld	s3,24(sp)
ffffffffc020211e:	6a42                	ld	s4,16(sp)
ffffffffc0202120:	6aa2                	ld	s5,8(sp)
ffffffffc0202122:	6b02                	ld	s6,0(sp)
ffffffffc0202124:	6121                	addi	sp,sp,64
ffffffffc0202126:	8082                	ret
            return NULL;
ffffffffc0202128:	4501                	li	a0,0
ffffffffc020212a:	b7ed                	j	ffffffffc0202114 <get_pte+0x178>
        intr_disable();
ffffffffc020212c:	889fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202130:	000a8797          	auipc	a5,0xa8
ffffffffc0202134:	7087b783          	ld	a5,1800(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0202138:	6f9c                	ld	a5,24(a5)
ffffffffc020213a:	4505                	li	a0,1
ffffffffc020213c:	9782                	jalr	a5
ffffffffc020213e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202140:	86ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202144:	b56d                	j	ffffffffc0201fee <get_pte+0x52>
        intr_disable();
ffffffffc0202146:	86ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020214a:	000a8797          	auipc	a5,0xa8
ffffffffc020214e:	6ee7b783          	ld	a5,1774(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0202152:	6f9c                	ld	a5,24(a5)
ffffffffc0202154:	4505                	li	a0,1
ffffffffc0202156:	9782                	jalr	a5
ffffffffc0202158:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020215a:	855fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020215e:	b781                	j	ffffffffc020209e <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202160:	00004617          	auipc	a2,0x4
ffffffffc0202164:	77060613          	addi	a2,a2,1904 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0202168:	0fa00593          	li	a1,250
ffffffffc020216c:	00005517          	auipc	a0,0x5
ffffffffc0202170:	87c50513          	addi	a0,a0,-1924 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202174:	b1afe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202178:	00004617          	auipc	a2,0x4
ffffffffc020217c:	75860613          	addi	a2,a2,1880 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0202180:	0ed00593          	li	a1,237
ffffffffc0202184:	00005517          	auipc	a0,0x5
ffffffffc0202188:	86450513          	addi	a0,a0,-1948 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020218c:	b02fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202190:	86aa                	mv	a3,a0
ffffffffc0202192:	00004617          	auipc	a2,0x4
ffffffffc0202196:	73e60613          	addi	a2,a2,1854 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc020219a:	0e900593          	li	a1,233
ffffffffc020219e:	00005517          	auipc	a0,0x5
ffffffffc02021a2:	84a50513          	addi	a0,a0,-1974 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02021a6:	ae8fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021aa:	86aa                	mv	a3,a0
ffffffffc02021ac:	00004617          	auipc	a2,0x4
ffffffffc02021b0:	72460613          	addi	a2,a2,1828 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc02021b4:	0f700593          	li	a1,247
ffffffffc02021b8:	00005517          	auipc	a0,0x5
ffffffffc02021bc:	83050513          	addi	a0,a0,-2000 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02021c0:	acefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02021c4 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021c4:	1141                	addi	sp,sp,-16
ffffffffc02021c6:	e022                	sd	s0,0(sp)
ffffffffc02021c8:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021ca:	4601                	li	a2,0
{
ffffffffc02021cc:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021ce:	dcfff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    if (ptep_store != NULL)
ffffffffc02021d2:	c011                	beqz	s0,ffffffffc02021d6 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021d4:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021d6:	c511                	beqz	a0,ffffffffc02021e2 <get_page+0x1e>
ffffffffc02021d8:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021da:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021dc:	0017f713          	andi	a4,a5,1
ffffffffc02021e0:	e709                	bnez	a4,ffffffffc02021ea <get_page+0x26>
}
ffffffffc02021e2:	60a2                	ld	ra,8(sp)
ffffffffc02021e4:	6402                	ld	s0,0(sp)
ffffffffc02021e6:	0141                	addi	sp,sp,16
ffffffffc02021e8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02021ea:	078a                	slli	a5,a5,0x2
ffffffffc02021ec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021ee:	000a8717          	auipc	a4,0xa8
ffffffffc02021f2:	63a73703          	ld	a4,1594(a4) # ffffffffc02aa828 <npage>
ffffffffc02021f6:	00e7ff63          	bgeu	a5,a4,ffffffffc0202214 <get_page+0x50>
ffffffffc02021fa:	60a2                	ld	ra,8(sp)
ffffffffc02021fc:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021fe:	fff80537          	lui	a0,0xfff80
ffffffffc0202202:	97aa                	add	a5,a5,a0
ffffffffc0202204:	079a                	slli	a5,a5,0x6
ffffffffc0202206:	000a8517          	auipc	a0,0xa8
ffffffffc020220a:	62a53503          	ld	a0,1578(a0) # ffffffffc02aa830 <pages>
ffffffffc020220e:	953e                	add	a0,a0,a5
ffffffffc0202210:	0141                	addi	sp,sp,16
ffffffffc0202212:	8082                	ret
ffffffffc0202214:	c99ff0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>

ffffffffc0202218 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202218:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020221a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020221e:	f486                	sd	ra,104(sp)
ffffffffc0202220:	f0a2                	sd	s0,96(sp)
ffffffffc0202222:	eca6                	sd	s1,88(sp)
ffffffffc0202224:	e8ca                	sd	s2,80(sp)
ffffffffc0202226:	e4ce                	sd	s3,72(sp)
ffffffffc0202228:	e0d2                	sd	s4,64(sp)
ffffffffc020222a:	fc56                	sd	s5,56(sp)
ffffffffc020222c:	f85a                	sd	s6,48(sp)
ffffffffc020222e:	f45e                	sd	s7,40(sp)
ffffffffc0202230:	f062                	sd	s8,32(sp)
ffffffffc0202232:	ec66                	sd	s9,24(sp)
ffffffffc0202234:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202236:	17d2                	slli	a5,a5,0x34
ffffffffc0202238:	e3ed                	bnez	a5,ffffffffc020231a <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc020223a:	002007b7          	lui	a5,0x200
ffffffffc020223e:	842e                	mv	s0,a1
ffffffffc0202240:	0ef5ed63          	bltu	a1,a5,ffffffffc020233a <unmap_range+0x122>
ffffffffc0202244:	8932                	mv	s2,a2
ffffffffc0202246:	0ec5fa63          	bgeu	a1,a2,ffffffffc020233a <unmap_range+0x122>
ffffffffc020224a:	4785                	li	a5,1
ffffffffc020224c:	07fe                	slli	a5,a5,0x1f
ffffffffc020224e:	0ec7e663          	bltu	a5,a2,ffffffffc020233a <unmap_range+0x122>
ffffffffc0202252:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202254:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0202256:	000a8c97          	auipc	s9,0xa8
ffffffffc020225a:	5d2c8c93          	addi	s9,s9,1490 # ffffffffc02aa828 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020225e:	000a8c17          	auipc	s8,0xa8
ffffffffc0202262:	5d2c0c13          	addi	s8,s8,1490 # ffffffffc02aa830 <pages>
ffffffffc0202266:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020226a:	000a8d17          	auipc	s10,0xa8
ffffffffc020226e:	5ced0d13          	addi	s10,s10,1486 # ffffffffc02aa838 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202272:	00200b37          	lui	s6,0x200
ffffffffc0202276:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020227a:	4601                	li	a2,0
ffffffffc020227c:	85a2                	mv	a1,s0
ffffffffc020227e:	854e                	mv	a0,s3
ffffffffc0202280:	d1dff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc0202284:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0202286:	cd29                	beqz	a0,ffffffffc02022e0 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202288:	611c                	ld	a5,0(a0)
ffffffffc020228a:	e395                	bnez	a5,ffffffffc02022ae <unmap_range+0x96>
        start += PGSIZE;
ffffffffc020228c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020228e:	ff2466e3          	bltu	s0,s2,ffffffffc020227a <unmap_range+0x62>
}
ffffffffc0202292:	70a6                	ld	ra,104(sp)
ffffffffc0202294:	7406                	ld	s0,96(sp)
ffffffffc0202296:	64e6                	ld	s1,88(sp)
ffffffffc0202298:	6946                	ld	s2,80(sp)
ffffffffc020229a:	69a6                	ld	s3,72(sp)
ffffffffc020229c:	6a06                	ld	s4,64(sp)
ffffffffc020229e:	7ae2                	ld	s5,56(sp)
ffffffffc02022a0:	7b42                	ld	s6,48(sp)
ffffffffc02022a2:	7ba2                	ld	s7,40(sp)
ffffffffc02022a4:	7c02                	ld	s8,32(sp)
ffffffffc02022a6:	6ce2                	ld	s9,24(sp)
ffffffffc02022a8:	6d42                	ld	s10,16(sp)
ffffffffc02022aa:	6165                	addi	sp,sp,112
ffffffffc02022ac:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022ae:	0017f713          	andi	a4,a5,1
ffffffffc02022b2:	df69                	beqz	a4,ffffffffc020228c <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02022b4:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022b8:	078a                	slli	a5,a5,0x2
ffffffffc02022ba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022bc:	08e7ff63          	bgeu	a5,a4,ffffffffc020235a <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02022c0:	000c3503          	ld	a0,0(s8)
ffffffffc02022c4:	97de                	add	a5,a5,s7
ffffffffc02022c6:	079a                	slli	a5,a5,0x6
ffffffffc02022c8:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02022ca:	411c                	lw	a5,0(a0)
ffffffffc02022cc:	fff7871b          	addiw	a4,a5,-1
ffffffffc02022d0:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02022d2:	cf11                	beqz	a4,ffffffffc02022ee <unmap_range+0xd6>
        *ptep = 0;
ffffffffc02022d4:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02022d8:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02022dc:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022de:	bf45                	j	ffffffffc020228e <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022e0:	945a                	add	s0,s0,s6
ffffffffc02022e2:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02022e6:	d455                	beqz	s0,ffffffffc0202292 <unmap_range+0x7a>
ffffffffc02022e8:	f92469e3          	bltu	s0,s2,ffffffffc020227a <unmap_range+0x62>
ffffffffc02022ec:	b75d                	j	ffffffffc0202292 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022ee:	100027f3          	csrr	a5,sstatus
ffffffffc02022f2:	8b89                	andi	a5,a5,2
ffffffffc02022f4:	e799                	bnez	a5,ffffffffc0202302 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02022f6:	000d3783          	ld	a5,0(s10)
ffffffffc02022fa:	4585                	li	a1,1
ffffffffc02022fc:	739c                	ld	a5,32(a5)
ffffffffc02022fe:	9782                	jalr	a5
    if (flag)
ffffffffc0202300:	bfd1                	j	ffffffffc02022d4 <unmap_range+0xbc>
ffffffffc0202302:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202304:	eb0fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202308:	000d3783          	ld	a5,0(s10)
ffffffffc020230c:	6522                	ld	a0,8(sp)
ffffffffc020230e:	4585                	li	a1,1
ffffffffc0202310:	739c                	ld	a5,32(a5)
ffffffffc0202312:	9782                	jalr	a5
        intr_enable();
ffffffffc0202314:	e9afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202318:	bf75                	j	ffffffffc02022d4 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020231a:	00004697          	auipc	a3,0x4
ffffffffc020231e:	6de68693          	addi	a3,a3,1758 # ffffffffc02069f8 <default_pmm_manager+0x160>
ffffffffc0202322:	00004617          	auipc	a2,0x4
ffffffffc0202326:	1c660613          	addi	a2,a2,454 # ffffffffc02064e8 <commands+0x828>
ffffffffc020232a:	12000593          	li	a1,288
ffffffffc020232e:	00004517          	auipc	a0,0x4
ffffffffc0202332:	6ba50513          	addi	a0,a0,1722 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202336:	958fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020233a:	00004697          	auipc	a3,0x4
ffffffffc020233e:	6ee68693          	addi	a3,a3,1774 # ffffffffc0206a28 <default_pmm_manager+0x190>
ffffffffc0202342:	00004617          	auipc	a2,0x4
ffffffffc0202346:	1a660613          	addi	a2,a2,422 # ffffffffc02064e8 <commands+0x828>
ffffffffc020234a:	12100593          	li	a1,289
ffffffffc020234e:	00004517          	auipc	a0,0x4
ffffffffc0202352:	69a50513          	addi	a0,a0,1690 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202356:	938fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020235a:	b53ff0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>

ffffffffc020235e <exit_range>:
{
ffffffffc020235e:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202360:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202364:	fc86                	sd	ra,120(sp)
ffffffffc0202366:	f8a2                	sd	s0,112(sp)
ffffffffc0202368:	f4a6                	sd	s1,104(sp)
ffffffffc020236a:	f0ca                	sd	s2,96(sp)
ffffffffc020236c:	ecce                	sd	s3,88(sp)
ffffffffc020236e:	e8d2                	sd	s4,80(sp)
ffffffffc0202370:	e4d6                	sd	s5,72(sp)
ffffffffc0202372:	e0da                	sd	s6,64(sp)
ffffffffc0202374:	fc5e                	sd	s7,56(sp)
ffffffffc0202376:	f862                	sd	s8,48(sp)
ffffffffc0202378:	f466                	sd	s9,40(sp)
ffffffffc020237a:	f06a                	sd	s10,32(sp)
ffffffffc020237c:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020237e:	17d2                	slli	a5,a5,0x34
ffffffffc0202380:	20079a63          	bnez	a5,ffffffffc0202594 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202384:	002007b7          	lui	a5,0x200
ffffffffc0202388:	24f5e463          	bltu	a1,a5,ffffffffc02025d0 <exit_range+0x272>
ffffffffc020238c:	8ab2                	mv	s5,a2
ffffffffc020238e:	24c5f163          	bgeu	a1,a2,ffffffffc02025d0 <exit_range+0x272>
ffffffffc0202392:	4785                	li	a5,1
ffffffffc0202394:	07fe                	slli	a5,a5,0x1f
ffffffffc0202396:	22c7ed63          	bltu	a5,a2,ffffffffc02025d0 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020239a:	c00009b7          	lui	s3,0xc0000
ffffffffc020239e:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023a2:	ffe00937          	lui	s2,0xffe00
ffffffffc02023a6:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02023aa:	5cfd                	li	s9,-1
ffffffffc02023ac:	8c2a                	mv	s8,a0
ffffffffc02023ae:	0125f933          	and	s2,a1,s2
ffffffffc02023b2:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02023b4:	000a8d17          	auipc	s10,0xa8
ffffffffc02023b8:	474d0d13          	addi	s10,s10,1140 # ffffffffc02aa828 <npage>
    return KADDR(page2pa(page));
ffffffffc02023bc:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023c0:	000a8717          	auipc	a4,0xa8
ffffffffc02023c4:	47070713          	addi	a4,a4,1136 # ffffffffc02aa830 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02023c8:	000a8d97          	auipc	s11,0xa8
ffffffffc02023cc:	470d8d93          	addi	s11,s11,1136 # ffffffffc02aa838 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023d0:	c0000437          	lui	s0,0xc0000
ffffffffc02023d4:	944e                	add	s0,s0,s3
ffffffffc02023d6:	8079                	srli	s0,s0,0x1e
ffffffffc02023d8:	1ff47413          	andi	s0,s0,511
ffffffffc02023dc:	040e                	slli	s0,s0,0x3
ffffffffc02023de:	9462                	add	s0,s0,s8
ffffffffc02023e0:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
        if (pde1 & PTE_V)
ffffffffc02023e4:	001a7793          	andi	a5,s4,1
ffffffffc02023e8:	eb99                	bnez	a5,ffffffffc02023fe <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02023ea:	12098463          	beqz	s3,ffffffffc0202512 <exit_range+0x1b4>
ffffffffc02023ee:	400007b7          	lui	a5,0x40000
ffffffffc02023f2:	97ce                	add	a5,a5,s3
ffffffffc02023f4:	894e                	mv	s2,s3
ffffffffc02023f6:	1159fe63          	bgeu	s3,s5,ffffffffc0202512 <exit_range+0x1b4>
ffffffffc02023fa:	89be                	mv	s3,a5
ffffffffc02023fc:	bfd1                	j	ffffffffc02023d0 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02023fe:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202402:	0a0a                	slli	s4,s4,0x2
ffffffffc0202404:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202408:	1cfa7263          	bgeu	s4,a5,ffffffffc02025cc <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020240c:	fff80637          	lui	a2,0xfff80
ffffffffc0202410:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0202412:	000806b7          	lui	a3,0x80
ffffffffc0202416:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202418:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020241c:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020241e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202420:	18f5fa63          	bgeu	a1,a5,ffffffffc02025b4 <exit_range+0x256>
ffffffffc0202424:	000a8817          	auipc	a6,0xa8
ffffffffc0202428:	41c80813          	addi	a6,a6,1052 # ffffffffc02aa840 <va_pa_offset>
ffffffffc020242c:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202430:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202432:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202436:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202438:	00080337          	lui	t1,0x80
ffffffffc020243c:	6885                	lui	a7,0x1
ffffffffc020243e:	a819                	j	ffffffffc0202454 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202440:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc0202442:	002007b7          	lui	a5,0x200
ffffffffc0202446:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202448:	08090c63          	beqz	s2,ffffffffc02024e0 <exit_range+0x182>
ffffffffc020244c:	09397a63          	bgeu	s2,s3,ffffffffc02024e0 <exit_range+0x182>
ffffffffc0202450:	0f597063          	bgeu	s2,s5,ffffffffc0202530 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202454:	01595493          	srli	s1,s2,0x15
ffffffffc0202458:	1ff4f493          	andi	s1,s1,511
ffffffffc020245c:	048e                	slli	s1,s1,0x3
ffffffffc020245e:	94da                	add	s1,s1,s6
ffffffffc0202460:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc0202462:	0017f693          	andi	a3,a5,1
ffffffffc0202466:	dee9                	beqz	a3,ffffffffc0202440 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202468:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020246c:	078a                	slli	a5,a5,0x2
ffffffffc020246e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202470:	14b7fe63          	bgeu	a5,a1,ffffffffc02025cc <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202474:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202476:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020247a:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020247e:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202482:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202484:	12bef863          	bgeu	t4,a1,ffffffffc02025b4 <exit_range+0x256>
ffffffffc0202488:	00083783          	ld	a5,0(a6)
ffffffffc020248c:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020248e:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202492:	629c                	ld	a5,0(a3)
ffffffffc0202494:	8b85                	andi	a5,a5,1
ffffffffc0202496:	f7d5                	bnez	a5,ffffffffc0202442 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202498:	06a1                	addi	a3,a3,8
ffffffffc020249a:	fed59ce3          	bne	a1,a3,ffffffffc0202492 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc020249e:	631c                	ld	a5,0(a4)
ffffffffc02024a0:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024a2:	100027f3          	csrr	a5,sstatus
ffffffffc02024a6:	8b89                	andi	a5,a5,2
ffffffffc02024a8:	e7d9                	bnez	a5,ffffffffc0202536 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02024aa:	000db783          	ld	a5,0(s11)
ffffffffc02024ae:	4585                	li	a1,1
ffffffffc02024b0:	e032                	sd	a2,0(sp)
ffffffffc02024b2:	739c                	ld	a5,32(a5)
ffffffffc02024b4:	9782                	jalr	a5
    if (flag)
ffffffffc02024b6:	6602                	ld	a2,0(sp)
ffffffffc02024b8:	000a8817          	auipc	a6,0xa8
ffffffffc02024bc:	38880813          	addi	a6,a6,904 # ffffffffc02aa840 <va_pa_offset>
ffffffffc02024c0:	fff80e37          	lui	t3,0xfff80
ffffffffc02024c4:	00080337          	lui	t1,0x80
ffffffffc02024c8:	6885                	lui	a7,0x1
ffffffffc02024ca:	000a8717          	auipc	a4,0xa8
ffffffffc02024ce:	36670713          	addi	a4,a4,870 # ffffffffc02aa830 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024d2:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02024d6:	002007b7          	lui	a5,0x200
ffffffffc02024da:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024dc:	f60918e3          	bnez	s2,ffffffffc020244c <exit_range+0xee>
            if (free_pd0)
ffffffffc02024e0:	f00b85e3          	beqz	s7,ffffffffc02023ea <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02024e4:	000d3783          	ld	a5,0(s10)
ffffffffc02024e8:	0efa7263          	bgeu	s4,a5,ffffffffc02025cc <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ec:	6308                	ld	a0,0(a4)
ffffffffc02024ee:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024f0:	100027f3          	csrr	a5,sstatus
ffffffffc02024f4:	8b89                	andi	a5,a5,2
ffffffffc02024f6:	efad                	bnez	a5,ffffffffc0202570 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02024f8:	000db783          	ld	a5,0(s11)
ffffffffc02024fc:	4585                	li	a1,1
ffffffffc02024fe:	739c                	ld	a5,32(a5)
ffffffffc0202500:	9782                	jalr	a5
ffffffffc0202502:	000a8717          	auipc	a4,0xa8
ffffffffc0202506:	32e70713          	addi	a4,a4,814 # ffffffffc02aa830 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020250a:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc020250e:	ee0990e3          	bnez	s3,ffffffffc02023ee <exit_range+0x90>
}
ffffffffc0202512:	70e6                	ld	ra,120(sp)
ffffffffc0202514:	7446                	ld	s0,112(sp)
ffffffffc0202516:	74a6                	ld	s1,104(sp)
ffffffffc0202518:	7906                	ld	s2,96(sp)
ffffffffc020251a:	69e6                	ld	s3,88(sp)
ffffffffc020251c:	6a46                	ld	s4,80(sp)
ffffffffc020251e:	6aa6                	ld	s5,72(sp)
ffffffffc0202520:	6b06                	ld	s6,64(sp)
ffffffffc0202522:	7be2                	ld	s7,56(sp)
ffffffffc0202524:	7c42                	ld	s8,48(sp)
ffffffffc0202526:	7ca2                	ld	s9,40(sp)
ffffffffc0202528:	7d02                	ld	s10,32(sp)
ffffffffc020252a:	6de2                	ld	s11,24(sp)
ffffffffc020252c:	6109                	addi	sp,sp,128
ffffffffc020252e:	8082                	ret
            if (free_pd0)
ffffffffc0202530:	ea0b8fe3          	beqz	s7,ffffffffc02023ee <exit_range+0x90>
ffffffffc0202534:	bf45                	j	ffffffffc02024e4 <exit_range+0x186>
ffffffffc0202536:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202538:	e42a                	sd	a0,8(sp)
ffffffffc020253a:	c7afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020253e:	000db783          	ld	a5,0(s11)
ffffffffc0202542:	6522                	ld	a0,8(sp)
ffffffffc0202544:	4585                	li	a1,1
ffffffffc0202546:	739c                	ld	a5,32(a5)
ffffffffc0202548:	9782                	jalr	a5
        intr_enable();
ffffffffc020254a:	c64fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020254e:	6602                	ld	a2,0(sp)
ffffffffc0202550:	000a8717          	auipc	a4,0xa8
ffffffffc0202554:	2e070713          	addi	a4,a4,736 # ffffffffc02aa830 <pages>
ffffffffc0202558:	6885                	lui	a7,0x1
ffffffffc020255a:	00080337          	lui	t1,0x80
ffffffffc020255e:	fff80e37          	lui	t3,0xfff80
ffffffffc0202562:	000a8817          	auipc	a6,0xa8
ffffffffc0202566:	2de80813          	addi	a6,a6,734 # ffffffffc02aa840 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020256a:	0004b023          	sd	zero,0(s1)
ffffffffc020256e:	b7a5                	j	ffffffffc02024d6 <exit_range+0x178>
ffffffffc0202570:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202572:	c42fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202576:	000db783          	ld	a5,0(s11)
ffffffffc020257a:	6502                	ld	a0,0(sp)
ffffffffc020257c:	4585                	li	a1,1
ffffffffc020257e:	739c                	ld	a5,32(a5)
ffffffffc0202580:	9782                	jalr	a5
        intr_enable();
ffffffffc0202582:	c2cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202586:	000a8717          	auipc	a4,0xa8
ffffffffc020258a:	2aa70713          	addi	a4,a4,682 # ffffffffc02aa830 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020258e:	00043023          	sd	zero,0(s0)
ffffffffc0202592:	bfb5                	j	ffffffffc020250e <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202594:	00004697          	auipc	a3,0x4
ffffffffc0202598:	46468693          	addi	a3,a3,1124 # ffffffffc02069f8 <default_pmm_manager+0x160>
ffffffffc020259c:	00004617          	auipc	a2,0x4
ffffffffc02025a0:	f4c60613          	addi	a2,a2,-180 # ffffffffc02064e8 <commands+0x828>
ffffffffc02025a4:	13500593          	li	a1,309
ffffffffc02025a8:	00004517          	auipc	a0,0x4
ffffffffc02025ac:	44050513          	addi	a0,a0,1088 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02025b0:	edffd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025b4:	00004617          	auipc	a2,0x4
ffffffffc02025b8:	31c60613          	addi	a2,a2,796 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc02025bc:	07100593          	li	a1,113
ffffffffc02025c0:	00004517          	auipc	a0,0x4
ffffffffc02025c4:	33850513          	addi	a0,a0,824 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02025c8:	ec7fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02025cc:	8e1ff0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025d0:	00004697          	auipc	a3,0x4
ffffffffc02025d4:	45868693          	addi	a3,a3,1112 # ffffffffc0206a28 <default_pmm_manager+0x190>
ffffffffc02025d8:	00004617          	auipc	a2,0x4
ffffffffc02025dc:	f1060613          	addi	a2,a2,-240 # ffffffffc02064e8 <commands+0x828>
ffffffffc02025e0:	13600593          	li	a1,310
ffffffffc02025e4:	00004517          	auipc	a0,0x4
ffffffffc02025e8:	40450513          	addi	a0,a0,1028 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02025ec:	ea3fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02025f0 <page_remove>:
{
ffffffffc02025f0:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025f2:	4601                	li	a2,0
{
ffffffffc02025f4:	ec26                	sd	s1,24(sp)
ffffffffc02025f6:	f406                	sd	ra,40(sp)
ffffffffc02025f8:	f022                	sd	s0,32(sp)
ffffffffc02025fa:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025fc:	9a1ff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    if (ptep != NULL)
ffffffffc0202600:	c511                	beqz	a0,ffffffffc020260c <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0202602:	611c                	ld	a5,0(a0)
ffffffffc0202604:	842a                	mv	s0,a0
ffffffffc0202606:	0017f713          	andi	a4,a5,1
ffffffffc020260a:	e711                	bnez	a4,ffffffffc0202616 <page_remove+0x26>
}
ffffffffc020260c:	70a2                	ld	ra,40(sp)
ffffffffc020260e:	7402                	ld	s0,32(sp)
ffffffffc0202610:	64e2                	ld	s1,24(sp)
ffffffffc0202612:	6145                	addi	sp,sp,48
ffffffffc0202614:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202616:	078a                	slli	a5,a5,0x2
ffffffffc0202618:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020261a:	000a8717          	auipc	a4,0xa8
ffffffffc020261e:	20e73703          	ld	a4,526(a4) # ffffffffc02aa828 <npage>
ffffffffc0202622:	06e7f363          	bgeu	a5,a4,ffffffffc0202688 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202626:	fff80537          	lui	a0,0xfff80
ffffffffc020262a:	97aa                	add	a5,a5,a0
ffffffffc020262c:	079a                	slli	a5,a5,0x6
ffffffffc020262e:	000a8517          	auipc	a0,0xa8
ffffffffc0202632:	20253503          	ld	a0,514(a0) # ffffffffc02aa830 <pages>
ffffffffc0202636:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202638:	411c                	lw	a5,0(a0)
ffffffffc020263a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020263e:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202640:	cb11                	beqz	a4,ffffffffc0202654 <page_remove+0x64>
        *ptep = 0;
ffffffffc0202642:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202646:	12048073          	sfence.vma	s1
}
ffffffffc020264a:	70a2                	ld	ra,40(sp)
ffffffffc020264c:	7402                	ld	s0,32(sp)
ffffffffc020264e:	64e2                	ld	s1,24(sp)
ffffffffc0202650:	6145                	addi	sp,sp,48
ffffffffc0202652:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202654:	100027f3          	csrr	a5,sstatus
ffffffffc0202658:	8b89                	andi	a5,a5,2
ffffffffc020265a:	eb89                	bnez	a5,ffffffffc020266c <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc020265c:	000a8797          	auipc	a5,0xa8
ffffffffc0202660:	1dc7b783          	ld	a5,476(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0202664:	739c                	ld	a5,32(a5)
ffffffffc0202666:	4585                	li	a1,1
ffffffffc0202668:	9782                	jalr	a5
    if (flag)
ffffffffc020266a:	bfe1                	j	ffffffffc0202642 <page_remove+0x52>
        intr_disable();
ffffffffc020266c:	e42a                	sd	a0,8(sp)
ffffffffc020266e:	b46fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202672:	000a8797          	auipc	a5,0xa8
ffffffffc0202676:	1c67b783          	ld	a5,454(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc020267a:	739c                	ld	a5,32(a5)
ffffffffc020267c:	6522                	ld	a0,8(sp)
ffffffffc020267e:	4585                	li	a1,1
ffffffffc0202680:	9782                	jalr	a5
        intr_enable();
ffffffffc0202682:	b2cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202686:	bf75                	j	ffffffffc0202642 <page_remove+0x52>
ffffffffc0202688:	825ff0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>

ffffffffc020268c <page_insert>:
{
ffffffffc020268c:	7139                	addi	sp,sp,-64
ffffffffc020268e:	e852                	sd	s4,16(sp)
ffffffffc0202690:	8a32                	mv	s4,a2
ffffffffc0202692:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202694:	4605                	li	a2,1
{
ffffffffc0202696:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202698:	85d2                	mv	a1,s4
{
ffffffffc020269a:	f426                	sd	s1,40(sp)
ffffffffc020269c:	fc06                	sd	ra,56(sp)
ffffffffc020269e:	f04a                	sd	s2,32(sp)
ffffffffc02026a0:	ec4e                	sd	s3,24(sp)
ffffffffc02026a2:	e456                	sd	s5,8(sp)
ffffffffc02026a4:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026a6:	8f7ff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    if (ptep == NULL)
ffffffffc02026aa:	c961                	beqz	a0,ffffffffc020277a <page_insert+0xee>
    page->ref += 1;
ffffffffc02026ac:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026ae:	611c                	ld	a5,0(a0)
ffffffffc02026b0:	89aa                	mv	s3,a0
ffffffffc02026b2:	0016871b          	addiw	a4,a3,1
ffffffffc02026b6:	c018                	sw	a4,0(s0)
ffffffffc02026b8:	0017f713          	andi	a4,a5,1
ffffffffc02026bc:	ef05                	bnez	a4,ffffffffc02026f4 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02026be:	000a8717          	auipc	a4,0xa8
ffffffffc02026c2:	17273703          	ld	a4,370(a4) # ffffffffc02aa830 <pages>
ffffffffc02026c6:	8c19                	sub	s0,s0,a4
ffffffffc02026c8:	000807b7          	lui	a5,0x80
ffffffffc02026cc:	8419                	srai	s0,s0,0x6
ffffffffc02026ce:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026d0:	042a                	slli	s0,s0,0xa
ffffffffc02026d2:	8cc1                	or	s1,s1,s0
ffffffffc02026d4:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026d8:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026dc:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02026e0:	4501                	li	a0,0
}
ffffffffc02026e2:	70e2                	ld	ra,56(sp)
ffffffffc02026e4:	7442                	ld	s0,48(sp)
ffffffffc02026e6:	74a2                	ld	s1,40(sp)
ffffffffc02026e8:	7902                	ld	s2,32(sp)
ffffffffc02026ea:	69e2                	ld	s3,24(sp)
ffffffffc02026ec:	6a42                	ld	s4,16(sp)
ffffffffc02026ee:	6aa2                	ld	s5,8(sp)
ffffffffc02026f0:	6121                	addi	sp,sp,64
ffffffffc02026f2:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02026f4:	078a                	slli	a5,a5,0x2
ffffffffc02026f6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026f8:	000a8717          	auipc	a4,0xa8
ffffffffc02026fc:	13073703          	ld	a4,304(a4) # ffffffffc02aa828 <npage>
ffffffffc0202700:	06e7ff63          	bgeu	a5,a4,ffffffffc020277e <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202704:	000a8a97          	auipc	s5,0xa8
ffffffffc0202708:	12ca8a93          	addi	s5,s5,300 # ffffffffc02aa830 <pages>
ffffffffc020270c:	000ab703          	ld	a4,0(s5)
ffffffffc0202710:	fff80937          	lui	s2,0xfff80
ffffffffc0202714:	993e                	add	s2,s2,a5
ffffffffc0202716:	091a                	slli	s2,s2,0x6
ffffffffc0202718:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020271a:	01240c63          	beq	s0,s2,ffffffffc0202732 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020271e:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd5794>
ffffffffc0202722:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202726:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc020272a:	c691                	beqz	a3,ffffffffc0202736 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020272c:	120a0073          	sfence.vma	s4
}
ffffffffc0202730:	bf59                	j	ffffffffc02026c6 <page_insert+0x3a>
ffffffffc0202732:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202734:	bf49                	j	ffffffffc02026c6 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202736:	100027f3          	csrr	a5,sstatus
ffffffffc020273a:	8b89                	andi	a5,a5,2
ffffffffc020273c:	ef91                	bnez	a5,ffffffffc0202758 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020273e:	000a8797          	auipc	a5,0xa8
ffffffffc0202742:	0fa7b783          	ld	a5,250(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0202746:	739c                	ld	a5,32(a5)
ffffffffc0202748:	4585                	li	a1,1
ffffffffc020274a:	854a                	mv	a0,s2
ffffffffc020274c:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020274e:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202752:	120a0073          	sfence.vma	s4
ffffffffc0202756:	bf85                	j	ffffffffc02026c6 <page_insert+0x3a>
        intr_disable();
ffffffffc0202758:	a5cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020275c:	000a8797          	auipc	a5,0xa8
ffffffffc0202760:	0dc7b783          	ld	a5,220(a5) # ffffffffc02aa838 <pmm_manager>
ffffffffc0202764:	739c                	ld	a5,32(a5)
ffffffffc0202766:	4585                	li	a1,1
ffffffffc0202768:	854a                	mv	a0,s2
ffffffffc020276a:	9782                	jalr	a5
        intr_enable();
ffffffffc020276c:	a42fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202770:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202774:	120a0073          	sfence.vma	s4
ffffffffc0202778:	b7b9                	j	ffffffffc02026c6 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020277a:	5571                	li	a0,-4
ffffffffc020277c:	b79d                	j	ffffffffc02026e2 <page_insert+0x56>
ffffffffc020277e:	f2eff0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>

ffffffffc0202782 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202782:	00004797          	auipc	a5,0x4
ffffffffc0202786:	11678793          	addi	a5,a5,278 # ffffffffc0206898 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020278a:	638c                	ld	a1,0(a5)
{
ffffffffc020278c:	7159                	addi	sp,sp,-112
ffffffffc020278e:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202790:	00004517          	auipc	a0,0x4
ffffffffc0202794:	2b050513          	addi	a0,a0,688 # ffffffffc0206a40 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202798:	000a8b17          	auipc	s6,0xa8
ffffffffc020279c:	0a0b0b13          	addi	s6,s6,160 # ffffffffc02aa838 <pmm_manager>
{
ffffffffc02027a0:	f486                	sd	ra,104(sp)
ffffffffc02027a2:	e8ca                	sd	s2,80(sp)
ffffffffc02027a4:	e4ce                	sd	s3,72(sp)
ffffffffc02027a6:	f0a2                	sd	s0,96(sp)
ffffffffc02027a8:	eca6                	sd	s1,88(sp)
ffffffffc02027aa:	e0d2                	sd	s4,64(sp)
ffffffffc02027ac:	fc56                	sd	s5,56(sp)
ffffffffc02027ae:	f45e                	sd	s7,40(sp)
ffffffffc02027b0:	f062                	sd	s8,32(sp)
ffffffffc02027b2:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027b4:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027b8:	9ddfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027bc:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027c0:	000a8997          	auipc	s3,0xa8
ffffffffc02027c4:	08098993          	addi	s3,s3,128 # ffffffffc02aa840 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027c8:	679c                	ld	a5,8(a5)
ffffffffc02027ca:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027cc:	57f5                	li	a5,-3
ffffffffc02027ce:	07fa                	slli	a5,a5,0x1e
ffffffffc02027d0:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027d4:	9c6fe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc02027d8:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027da:	9cafe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027de:	200505e3          	beqz	a0,ffffffffc02031e8 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027e2:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027e4:	00004517          	auipc	a0,0x4
ffffffffc02027e8:	29450513          	addi	a0,a0,660 # ffffffffc0206a78 <default_pmm_manager+0x1e0>
ffffffffc02027ec:	9a9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027f0:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027f4:	fff40693          	addi	a3,s0,-1
ffffffffc02027f8:	864a                	mv	a2,s2
ffffffffc02027fa:	85a6                	mv	a1,s1
ffffffffc02027fc:	00004517          	auipc	a0,0x4
ffffffffc0202800:	29450513          	addi	a0,a0,660 # ffffffffc0206a90 <default_pmm_manager+0x1f8>
ffffffffc0202804:	991fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202808:	c8000737          	lui	a4,0xc8000
ffffffffc020280c:	87a2                	mv	a5,s0
ffffffffc020280e:	54876163          	bltu	a4,s0,ffffffffc0202d50 <pmm_init+0x5ce>
ffffffffc0202812:	757d                	lui	a0,0xfffff
ffffffffc0202814:	000a9617          	auipc	a2,0xa9
ffffffffc0202818:	05760613          	addi	a2,a2,87 # ffffffffc02ab86b <end+0xfff>
ffffffffc020281c:	8e69                	and	a2,a2,a0
ffffffffc020281e:	000a8497          	auipc	s1,0xa8
ffffffffc0202822:	00a48493          	addi	s1,s1,10 # ffffffffc02aa828 <npage>
ffffffffc0202826:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020282a:	000a8b97          	auipc	s7,0xa8
ffffffffc020282e:	006b8b93          	addi	s7,s7,6 # ffffffffc02aa830 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202832:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202834:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202838:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020283c:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020283e:	02f50863          	beq	a0,a5,ffffffffc020286e <pmm_init+0xec>
ffffffffc0202842:	4781                	li	a5,0
ffffffffc0202844:	4585                	li	a1,1
ffffffffc0202846:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020284a:	00679513          	slli	a0,a5,0x6
ffffffffc020284e:	9532                	add	a0,a0,a2
ffffffffc0202850:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd5479c>
ffffffffc0202854:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202858:	6088                	ld	a0,0(s1)
ffffffffc020285a:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020285c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202860:	00d50733          	add	a4,a0,a3
ffffffffc0202864:	fee7e3e3          	bltu	a5,a4,ffffffffc020284a <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202868:	071a                	slli	a4,a4,0x6
ffffffffc020286a:	00e606b3          	add	a3,a2,a4
ffffffffc020286e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202872:	2ef6ece3          	bltu	a3,a5,ffffffffc020336a <pmm_init+0xbe8>
ffffffffc0202876:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020287a:	77fd                	lui	a5,0xfffff
ffffffffc020287c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020287e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202880:	5086eb63          	bltu	a3,s0,ffffffffc0202d96 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202884:	00004517          	auipc	a0,0x4
ffffffffc0202888:	23450513          	addi	a0,a0,564 # ffffffffc0206ab8 <default_pmm_manager+0x220>
ffffffffc020288c:	909fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202890:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202894:	000a8917          	auipc	s2,0xa8
ffffffffc0202898:	f8c90913          	addi	s2,s2,-116 # ffffffffc02aa820 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020289c:	7b9c                	ld	a5,48(a5)
ffffffffc020289e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028a0:	00004517          	auipc	a0,0x4
ffffffffc02028a4:	23050513          	addi	a0,a0,560 # ffffffffc0206ad0 <default_pmm_manager+0x238>
ffffffffc02028a8:	8edfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028ac:	00007697          	auipc	a3,0x7
ffffffffc02028b0:	75468693          	addi	a3,a3,1876 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02028b4:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028b8:	c02007b7          	lui	a5,0xc0200
ffffffffc02028bc:	28f6ebe3          	bltu	a3,a5,ffffffffc0203352 <pmm_init+0xbd0>
ffffffffc02028c0:	0009b783          	ld	a5,0(s3)
ffffffffc02028c4:	8e9d                	sub	a3,a3,a5
ffffffffc02028c6:	000a8797          	auipc	a5,0xa8
ffffffffc02028ca:	f4d7b923          	sd	a3,-174(a5) # ffffffffc02aa818 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028ce:	100027f3          	csrr	a5,sstatus
ffffffffc02028d2:	8b89                	andi	a5,a5,2
ffffffffc02028d4:	4a079763          	bnez	a5,ffffffffc0202d82 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028d8:	000b3783          	ld	a5,0(s6)
ffffffffc02028dc:	779c                	ld	a5,40(a5)
ffffffffc02028de:	9782                	jalr	a5
ffffffffc02028e0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028e2:	6098                	ld	a4,0(s1)
ffffffffc02028e4:	c80007b7          	lui	a5,0xc8000
ffffffffc02028e8:	83b1                	srli	a5,a5,0xc
ffffffffc02028ea:	66e7e363          	bltu	a5,a4,ffffffffc0202f50 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028ee:	00093503          	ld	a0,0(s2)
ffffffffc02028f2:	62050f63          	beqz	a0,ffffffffc0202f30 <pmm_init+0x7ae>
ffffffffc02028f6:	03451793          	slli	a5,a0,0x34
ffffffffc02028fa:	62079b63          	bnez	a5,ffffffffc0202f30 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028fe:	4601                	li	a2,0
ffffffffc0202900:	4581                	li	a1,0
ffffffffc0202902:	8c3ff0ef          	jal	ra,ffffffffc02021c4 <get_page>
ffffffffc0202906:	60051563          	bnez	a0,ffffffffc0202f10 <pmm_init+0x78e>
ffffffffc020290a:	100027f3          	csrr	a5,sstatus
ffffffffc020290e:	8b89                	andi	a5,a5,2
ffffffffc0202910:	44079e63          	bnez	a5,ffffffffc0202d6c <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202914:	000b3783          	ld	a5,0(s6)
ffffffffc0202918:	4505                	li	a0,1
ffffffffc020291a:	6f9c                	ld	a5,24(a5)
ffffffffc020291c:	9782                	jalr	a5
ffffffffc020291e:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202920:	00093503          	ld	a0,0(s2)
ffffffffc0202924:	4681                	li	a3,0
ffffffffc0202926:	4601                	li	a2,0
ffffffffc0202928:	85d2                	mv	a1,s4
ffffffffc020292a:	d63ff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc020292e:	26051ae3          	bnez	a0,ffffffffc02033a2 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202932:	00093503          	ld	a0,0(s2)
ffffffffc0202936:	4601                	li	a2,0
ffffffffc0202938:	4581                	li	a1,0
ffffffffc020293a:	e62ff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc020293e:	240502e3          	beqz	a0,ffffffffc0203382 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202942:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202944:	0017f713          	andi	a4,a5,1
ffffffffc0202948:	5a070263          	beqz	a4,ffffffffc0202eec <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020294c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020294e:	078a                	slli	a5,a5,0x2
ffffffffc0202950:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202952:	58e7fb63          	bgeu	a5,a4,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202956:	000bb683          	ld	a3,0(s7)
ffffffffc020295a:	fff80637          	lui	a2,0xfff80
ffffffffc020295e:	97b2                	add	a5,a5,a2
ffffffffc0202960:	079a                	slli	a5,a5,0x6
ffffffffc0202962:	97b6                	add	a5,a5,a3
ffffffffc0202964:	14fa17e3          	bne	s4,a5,ffffffffc02032b2 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202968:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>
ffffffffc020296c:	4785                	li	a5,1
ffffffffc020296e:	12f692e3          	bne	a3,a5,ffffffffc0203292 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202972:	00093503          	ld	a0,0(s2)
ffffffffc0202976:	77fd                	lui	a5,0xfffff
ffffffffc0202978:	6114                	ld	a3,0(a0)
ffffffffc020297a:	068a                	slli	a3,a3,0x2
ffffffffc020297c:	8efd                	and	a3,a3,a5
ffffffffc020297e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202982:	0ee67ce3          	bgeu	a2,a4,ffffffffc020327a <pmm_init+0xaf8>
ffffffffc0202986:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020298a:	96e2                	add	a3,a3,s8
ffffffffc020298c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202990:	0a8a                	slli	s5,s5,0x2
ffffffffc0202992:	00fafab3          	and	s5,s5,a5
ffffffffc0202996:	00cad793          	srli	a5,s5,0xc
ffffffffc020299a:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203260 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020299e:	4601                	li	a2,0
ffffffffc02029a0:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029a2:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029a4:	df8ff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029a8:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029aa:	55551363          	bne	a0,s5,ffffffffc0202ef0 <pmm_init+0x76e>
ffffffffc02029ae:	100027f3          	csrr	a5,sstatus
ffffffffc02029b2:	8b89                	andi	a5,a5,2
ffffffffc02029b4:	3a079163          	bnez	a5,ffffffffc0202d56 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029b8:	000b3783          	ld	a5,0(s6)
ffffffffc02029bc:	4505                	li	a0,1
ffffffffc02029be:	6f9c                	ld	a5,24(a5)
ffffffffc02029c0:	9782                	jalr	a5
ffffffffc02029c2:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029c4:	00093503          	ld	a0,0(s2)
ffffffffc02029c8:	46d1                	li	a3,20
ffffffffc02029ca:	6605                	lui	a2,0x1
ffffffffc02029cc:	85e2                	mv	a1,s8
ffffffffc02029ce:	cbfff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc02029d2:	060517e3          	bnez	a0,ffffffffc0203240 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029d6:	00093503          	ld	a0,0(s2)
ffffffffc02029da:	4601                	li	a2,0
ffffffffc02029dc:	6585                	lui	a1,0x1
ffffffffc02029de:	dbeff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc02029e2:	02050fe3          	beqz	a0,ffffffffc0203220 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02029e6:	611c                	ld	a5,0(a0)
ffffffffc02029e8:	0107f713          	andi	a4,a5,16
ffffffffc02029ec:	7c070e63          	beqz	a4,ffffffffc02031c8 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02029f0:	8b91                	andi	a5,a5,4
ffffffffc02029f2:	7a078b63          	beqz	a5,ffffffffc02031a8 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029f6:	00093503          	ld	a0,0(s2)
ffffffffc02029fa:	611c                	ld	a5,0(a0)
ffffffffc02029fc:	8bc1                	andi	a5,a5,16
ffffffffc02029fe:	78078563          	beqz	a5,ffffffffc0203188 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a02:	000c2703          	lw	a4,0(s8)
ffffffffc0202a06:	4785                	li	a5,1
ffffffffc0202a08:	76f71063          	bne	a4,a5,ffffffffc0203168 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a0c:	4681                	li	a3,0
ffffffffc0202a0e:	6605                	lui	a2,0x1
ffffffffc0202a10:	85d2                	mv	a1,s4
ffffffffc0202a12:	c7bff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc0202a16:	72051963          	bnez	a0,ffffffffc0203148 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a1a:	000a2703          	lw	a4,0(s4)
ffffffffc0202a1e:	4789                	li	a5,2
ffffffffc0202a20:	70f71463          	bne	a4,a5,ffffffffc0203128 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a24:	000c2783          	lw	a5,0(s8)
ffffffffc0202a28:	6e079063          	bnez	a5,ffffffffc0203108 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a2c:	00093503          	ld	a0,0(s2)
ffffffffc0202a30:	4601                	li	a2,0
ffffffffc0202a32:	6585                	lui	a1,0x1
ffffffffc0202a34:	d68ff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc0202a38:	6a050863          	beqz	a0,ffffffffc02030e8 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a3c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a3e:	00177793          	andi	a5,a4,1
ffffffffc0202a42:	4a078563          	beqz	a5,ffffffffc0202eec <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a46:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a48:	00271793          	slli	a5,a4,0x2
ffffffffc0202a4c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a4e:	48d7fd63          	bgeu	a5,a3,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a52:	000bb683          	ld	a3,0(s7)
ffffffffc0202a56:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a5a:	97d6                	add	a5,a5,s5
ffffffffc0202a5c:	079a                	slli	a5,a5,0x6
ffffffffc0202a5e:	97b6                	add	a5,a5,a3
ffffffffc0202a60:	66fa1463          	bne	s4,a5,ffffffffc02030c8 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a64:	8b41                	andi	a4,a4,16
ffffffffc0202a66:	64071163          	bnez	a4,ffffffffc02030a8 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a6a:	00093503          	ld	a0,0(s2)
ffffffffc0202a6e:	4581                	li	a1,0
ffffffffc0202a70:	b81ff0ef          	jal	ra,ffffffffc02025f0 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a74:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a78:	4785                	li	a5,1
ffffffffc0202a7a:	60fc9763          	bne	s9,a5,ffffffffc0203088 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a7e:	000c2783          	lw	a5,0(s8)
ffffffffc0202a82:	5e079363          	bnez	a5,ffffffffc0203068 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a86:	00093503          	ld	a0,0(s2)
ffffffffc0202a8a:	6585                	lui	a1,0x1
ffffffffc0202a8c:	b65ff0ef          	jal	ra,ffffffffc02025f0 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a90:	000a2783          	lw	a5,0(s4)
ffffffffc0202a94:	52079a63          	bnez	a5,ffffffffc0202fc8 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a98:	000c2783          	lw	a5,0(s8)
ffffffffc0202a9c:	50079663          	bnez	a5,ffffffffc0202fa8 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202aa0:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202aa4:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aa6:	000a3683          	ld	a3,0(s4)
ffffffffc0202aaa:	068a                	slli	a3,a3,0x2
ffffffffc0202aac:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aae:	42b6fd63          	bgeu	a3,a1,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ab2:	000bb503          	ld	a0,0(s7)
ffffffffc0202ab6:	96d6                	add	a3,a3,s5
ffffffffc0202ab8:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202aba:	00d507b3          	add	a5,a0,a3
ffffffffc0202abe:	439c                	lw	a5,0(a5)
ffffffffc0202ac0:	4d979463          	bne	a5,s9,ffffffffc0202f88 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202ac4:	8699                	srai	a3,a3,0x6
ffffffffc0202ac6:	00080637          	lui	a2,0x80
ffffffffc0202aca:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202acc:	00c69713          	slli	a4,a3,0xc
ffffffffc0202ad0:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ad2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ad4:	48b77e63          	bgeu	a4,a1,ffffffffc0202f70 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ad8:	0009b703          	ld	a4,0(s3)
ffffffffc0202adc:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ade:	629c                	ld	a5,0(a3)
ffffffffc0202ae0:	078a                	slli	a5,a5,0x2
ffffffffc0202ae2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ae4:	40b7f263          	bgeu	a5,a1,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ae8:	8f91                	sub	a5,a5,a2
ffffffffc0202aea:	079a                	slli	a5,a5,0x6
ffffffffc0202aec:	953e                	add	a0,a0,a5
ffffffffc0202aee:	100027f3          	csrr	a5,sstatus
ffffffffc0202af2:	8b89                	andi	a5,a5,2
ffffffffc0202af4:	30079963          	bnez	a5,ffffffffc0202e06 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202af8:	000b3783          	ld	a5,0(s6)
ffffffffc0202afc:	4585                	li	a1,1
ffffffffc0202afe:	739c                	ld	a5,32(a5)
ffffffffc0202b00:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b02:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b06:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b08:	078a                	slli	a5,a5,0x2
ffffffffc0202b0a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b0c:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b10:	000bb503          	ld	a0,0(s7)
ffffffffc0202b14:	fff80737          	lui	a4,0xfff80
ffffffffc0202b18:	97ba                	add	a5,a5,a4
ffffffffc0202b1a:	079a                	slli	a5,a5,0x6
ffffffffc0202b1c:	953e                	add	a0,a0,a5
ffffffffc0202b1e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b22:	8b89                	andi	a5,a5,2
ffffffffc0202b24:	2c079563          	bnez	a5,ffffffffc0202dee <pmm_init+0x66c>
ffffffffc0202b28:	000b3783          	ld	a5,0(s6)
ffffffffc0202b2c:	4585                	li	a1,1
ffffffffc0202b2e:	739c                	ld	a5,32(a5)
ffffffffc0202b30:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b32:	00093783          	ld	a5,0(s2)
ffffffffc0202b36:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd54794>
    asm volatile("sfence.vma");
ffffffffc0202b3a:	12000073          	sfence.vma
ffffffffc0202b3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b42:	8b89                	andi	a5,a5,2
ffffffffc0202b44:	28079b63          	bnez	a5,ffffffffc0202dda <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b48:	000b3783          	ld	a5,0(s6)
ffffffffc0202b4c:	779c                	ld	a5,40(a5)
ffffffffc0202b4e:	9782                	jalr	a5
ffffffffc0202b50:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b52:	4b441b63          	bne	s0,s4,ffffffffc0203008 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b56:	00004517          	auipc	a0,0x4
ffffffffc0202b5a:	2a250513          	addi	a0,a0,674 # ffffffffc0206df8 <default_pmm_manager+0x560>
ffffffffc0202b5e:	e36fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b62:	100027f3          	csrr	a5,sstatus
ffffffffc0202b66:	8b89                	andi	a5,a5,2
ffffffffc0202b68:	24079f63          	bnez	a5,ffffffffc0202dc6 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b6c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b70:	779c                	ld	a5,40(a5)
ffffffffc0202b72:	9782                	jalr	a5
ffffffffc0202b74:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b76:	6098                	ld	a4,0(s1)
ffffffffc0202b78:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b7c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b7e:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b82:	6a05                	lui	s4,0x1
ffffffffc0202b84:	02f47c63          	bgeu	s0,a5,ffffffffc0202bbc <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b88:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b8c:	00093503          	ld	a0,0(s2)
ffffffffc0202b90:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e8e <pmm_init+0x70c>
ffffffffc0202b94:	0009b583          	ld	a1,0(s3)
ffffffffc0202b98:	4601                	li	a2,0
ffffffffc0202b9a:	95a2                	add	a1,a1,s0
ffffffffc0202b9c:	c00ff0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc0202ba0:	32050463          	beqz	a0,ffffffffc0202ec8 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ba4:	611c                	ld	a5,0(a0)
ffffffffc0202ba6:	078a                	slli	a5,a5,0x2
ffffffffc0202ba8:	0157f7b3          	and	a5,a5,s5
ffffffffc0202bac:	2e879e63          	bne	a5,s0,ffffffffc0202ea8 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bb0:	6098                	ld	a4,0(s1)
ffffffffc0202bb2:	9452                	add	s0,s0,s4
ffffffffc0202bb4:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bb8:	fcf468e3          	bltu	s0,a5,ffffffffc0202b88 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bbc:	00093783          	ld	a5,0(s2)
ffffffffc0202bc0:	639c                	ld	a5,0(a5)
ffffffffc0202bc2:	42079363          	bnez	a5,ffffffffc0202fe8 <pmm_init+0x866>
ffffffffc0202bc6:	100027f3          	csrr	a5,sstatus
ffffffffc0202bca:	8b89                	andi	a5,a5,2
ffffffffc0202bcc:	24079963          	bnez	a5,ffffffffc0202e1e <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bd0:	000b3783          	ld	a5,0(s6)
ffffffffc0202bd4:	4505                	li	a0,1
ffffffffc0202bd6:	6f9c                	ld	a5,24(a5)
ffffffffc0202bd8:	9782                	jalr	a5
ffffffffc0202bda:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bdc:	00093503          	ld	a0,0(s2)
ffffffffc0202be0:	4699                	li	a3,6
ffffffffc0202be2:	10000613          	li	a2,256
ffffffffc0202be6:	85d2                	mv	a1,s4
ffffffffc0202be8:	aa5ff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc0202bec:	44051e63          	bnez	a0,ffffffffc0203048 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202bf0:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>
ffffffffc0202bf4:	4785                	li	a5,1
ffffffffc0202bf6:	42f71963          	bne	a4,a5,ffffffffc0203028 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bfa:	00093503          	ld	a0,0(s2)
ffffffffc0202bfe:	6405                	lui	s0,0x1
ffffffffc0202c00:	4699                	li	a3,6
ffffffffc0202c02:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ac0>
ffffffffc0202c06:	85d2                	mv	a1,s4
ffffffffc0202c08:	a85ff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc0202c0c:	72051363          	bnez	a0,ffffffffc0203332 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c10:	000a2703          	lw	a4,0(s4)
ffffffffc0202c14:	4789                	li	a5,2
ffffffffc0202c16:	6ef71e63          	bne	a4,a5,ffffffffc0203312 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c1a:	00004597          	auipc	a1,0x4
ffffffffc0202c1e:	32658593          	addi	a1,a1,806 # ffffffffc0206f40 <default_pmm_manager+0x6a8>
ffffffffc0202c22:	10000513          	li	a0,256
ffffffffc0202c26:	59d020ef          	jal	ra,ffffffffc02059c2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c2a:	10040593          	addi	a1,s0,256
ffffffffc0202c2e:	10000513          	li	a0,256
ffffffffc0202c32:	5a3020ef          	jal	ra,ffffffffc02059d4 <strcmp>
ffffffffc0202c36:	6a051e63          	bnez	a0,ffffffffc02032f2 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c3a:	000bb683          	ld	a3,0(s7)
ffffffffc0202c3e:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c42:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c44:	40da06b3          	sub	a3,s4,a3
ffffffffc0202c48:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202c4a:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c4c:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c4e:	8031                	srli	s0,s0,0xc
ffffffffc0202c50:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c54:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c56:	30f77d63          	bgeu	a4,a5,ffffffffc0202f70 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c5a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c5e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c62:	96be                	add	a3,a3,a5
ffffffffc0202c64:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c68:	525020ef          	jal	ra,ffffffffc020598c <strlen>
ffffffffc0202c6c:	66051363          	bnez	a0,ffffffffc02032d2 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c70:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c74:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c76:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd54794>
ffffffffc0202c7a:	068a                	slli	a3,a3,0x2
ffffffffc0202c7c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c7e:	26f6f563          	bgeu	a3,a5,ffffffffc0202ee8 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c82:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c84:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c86:	2ef47563          	bgeu	s0,a5,ffffffffc0202f70 <pmm_init+0x7ee>
ffffffffc0202c8a:	0009b403          	ld	s0,0(s3)
ffffffffc0202c8e:	9436                	add	s0,s0,a3
ffffffffc0202c90:	100027f3          	csrr	a5,sstatus
ffffffffc0202c94:	8b89                	andi	a5,a5,2
ffffffffc0202c96:	1e079163          	bnez	a5,ffffffffc0202e78 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c9e:	4585                	li	a1,1
ffffffffc0202ca0:	8552                	mv	a0,s4
ffffffffc0202ca2:	739c                	ld	a5,32(a5)
ffffffffc0202ca4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ca6:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202ca8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202caa:	078a                	slli	a5,a5,0x2
ffffffffc0202cac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cae:	22e7fd63          	bgeu	a5,a4,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cb2:	000bb503          	ld	a0,0(s7)
ffffffffc0202cb6:	fff80737          	lui	a4,0xfff80
ffffffffc0202cba:	97ba                	add	a5,a5,a4
ffffffffc0202cbc:	079a                	slli	a5,a5,0x6
ffffffffc0202cbe:	953e                	add	a0,a0,a5
ffffffffc0202cc0:	100027f3          	csrr	a5,sstatus
ffffffffc0202cc4:	8b89                	andi	a5,a5,2
ffffffffc0202cc6:	18079d63          	bnez	a5,ffffffffc0202e60 <pmm_init+0x6de>
ffffffffc0202cca:	000b3783          	ld	a5,0(s6)
ffffffffc0202cce:	4585                	li	a1,1
ffffffffc0202cd0:	739c                	ld	a5,32(a5)
ffffffffc0202cd2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cd4:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202cd8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cda:	078a                	slli	a5,a5,0x2
ffffffffc0202cdc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cde:	20e7f563          	bgeu	a5,a4,ffffffffc0202ee8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ce2:	000bb503          	ld	a0,0(s7)
ffffffffc0202ce6:	fff80737          	lui	a4,0xfff80
ffffffffc0202cea:	97ba                	add	a5,a5,a4
ffffffffc0202cec:	079a                	slli	a5,a5,0x6
ffffffffc0202cee:	953e                	add	a0,a0,a5
ffffffffc0202cf0:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf4:	8b89                	andi	a5,a5,2
ffffffffc0202cf6:	14079963          	bnez	a5,ffffffffc0202e48 <pmm_init+0x6c6>
ffffffffc0202cfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfe:	4585                	li	a1,1
ffffffffc0202d00:	739c                	ld	a5,32(a5)
ffffffffc0202d02:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d04:	00093783          	ld	a5,0(s2)
ffffffffc0202d08:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d0c:	12000073          	sfence.vma
ffffffffc0202d10:	100027f3          	csrr	a5,sstatus
ffffffffc0202d14:	8b89                	andi	a5,a5,2
ffffffffc0202d16:	10079f63          	bnez	a5,ffffffffc0202e34 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d1e:	779c                	ld	a5,40(a5)
ffffffffc0202d20:	9782                	jalr	a5
ffffffffc0202d22:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d24:	4c8c1e63          	bne	s8,s0,ffffffffc0203200 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d28:	00004517          	auipc	a0,0x4
ffffffffc0202d2c:	29050513          	addi	a0,a0,656 # ffffffffc0206fb8 <default_pmm_manager+0x720>
ffffffffc0202d30:	c64fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d34:	7406                	ld	s0,96(sp)
ffffffffc0202d36:	70a6                	ld	ra,104(sp)
ffffffffc0202d38:	64e6                	ld	s1,88(sp)
ffffffffc0202d3a:	6946                	ld	s2,80(sp)
ffffffffc0202d3c:	69a6                	ld	s3,72(sp)
ffffffffc0202d3e:	6a06                	ld	s4,64(sp)
ffffffffc0202d40:	7ae2                	ld	s5,56(sp)
ffffffffc0202d42:	7b42                	ld	s6,48(sp)
ffffffffc0202d44:	7ba2                	ld	s7,40(sp)
ffffffffc0202d46:	7c02                	ld	s8,32(sp)
ffffffffc0202d48:	6ce2                	ld	s9,24(sp)
ffffffffc0202d4a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d4c:	f97fe06f          	j	ffffffffc0201ce2 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d50:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d54:	bc7d                	j	ffffffffc0202812 <pmm_init+0x90>
        intr_disable();
ffffffffc0202d56:	c5ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d5a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5e:	4505                	li	a0,1
ffffffffc0202d60:	6f9c                	ld	a5,24(a5)
ffffffffc0202d62:	9782                	jalr	a5
ffffffffc0202d64:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d66:	c49fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d6a:	b9a9                	j	ffffffffc02029c4 <pmm_init+0x242>
        intr_disable();
ffffffffc0202d6c:	c49fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d70:	000b3783          	ld	a5,0(s6)
ffffffffc0202d74:	4505                	li	a0,1
ffffffffc0202d76:	6f9c                	ld	a5,24(a5)
ffffffffc0202d78:	9782                	jalr	a5
ffffffffc0202d7a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d7c:	c33fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d80:	b645                	j	ffffffffc0202920 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d82:	c33fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d86:	000b3783          	ld	a5,0(s6)
ffffffffc0202d8a:	779c                	ld	a5,40(a5)
ffffffffc0202d8c:	9782                	jalr	a5
ffffffffc0202d8e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d90:	c1ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d94:	b6b9                	j	ffffffffc02028e2 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d96:	6705                	lui	a4,0x1
ffffffffc0202d98:	177d                	addi	a4,a4,-1
ffffffffc0202d9a:	96ba                	add	a3,a3,a4
ffffffffc0202d9c:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d9e:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202da2:	14a77363          	bgeu	a4,a0,ffffffffc0202ee8 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202da6:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202daa:	fff80537          	lui	a0,0xfff80
ffffffffc0202dae:	972a                	add	a4,a4,a0
ffffffffc0202db0:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202db2:	8c1d                	sub	s0,s0,a5
ffffffffc0202db4:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202db8:	00c45593          	srli	a1,s0,0xc
ffffffffc0202dbc:	9532                	add	a0,a0,a2
ffffffffc0202dbe:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202dc0:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202dc4:	b4c1                	j	ffffffffc0202884 <pmm_init+0x102>
        intr_disable();
ffffffffc0202dc6:	beffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dca:	000b3783          	ld	a5,0(s6)
ffffffffc0202dce:	779c                	ld	a5,40(a5)
ffffffffc0202dd0:	9782                	jalr	a5
ffffffffc0202dd2:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dd4:	bdbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd8:	bb79                	j	ffffffffc0202b76 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202dda:	bdbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dde:	000b3783          	ld	a5,0(s6)
ffffffffc0202de2:	779c                	ld	a5,40(a5)
ffffffffc0202de4:	9782                	jalr	a5
ffffffffc0202de6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202de8:	bc7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dec:	b39d                	j	ffffffffc0202b52 <pmm_init+0x3d0>
ffffffffc0202dee:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202df0:	bc5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202df4:	000b3783          	ld	a5,0(s6)
ffffffffc0202df8:	6522                	ld	a0,8(sp)
ffffffffc0202dfa:	4585                	li	a1,1
ffffffffc0202dfc:	739c                	ld	a5,32(a5)
ffffffffc0202dfe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e00:	baffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e04:	b33d                	j	ffffffffc0202b32 <pmm_init+0x3b0>
ffffffffc0202e06:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e08:	badfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e10:	6522                	ld	a0,8(sp)
ffffffffc0202e12:	4585                	li	a1,1
ffffffffc0202e14:	739c                	ld	a5,32(a5)
ffffffffc0202e16:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e18:	b97fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e1c:	b1dd                	j	ffffffffc0202b02 <pmm_init+0x380>
        intr_disable();
ffffffffc0202e1e:	b97fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e22:	000b3783          	ld	a5,0(s6)
ffffffffc0202e26:	4505                	li	a0,1
ffffffffc0202e28:	6f9c                	ld	a5,24(a5)
ffffffffc0202e2a:	9782                	jalr	a5
ffffffffc0202e2c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e2e:	b81fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e32:	b36d                	j	ffffffffc0202bdc <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e34:	b81fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e38:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3c:	779c                	ld	a5,40(a5)
ffffffffc0202e3e:	9782                	jalr	a5
ffffffffc0202e40:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e42:	b6dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e46:	bdf9                	j	ffffffffc0202d24 <pmm_init+0x5a2>
ffffffffc0202e48:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e4a:	b6bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e52:	6522                	ld	a0,8(sp)
ffffffffc0202e54:	4585                	li	a1,1
ffffffffc0202e56:	739c                	ld	a5,32(a5)
ffffffffc0202e58:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e5a:	b55fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e5e:	b55d                	j	ffffffffc0202d04 <pmm_init+0x582>
ffffffffc0202e60:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e62:	b53fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e66:	000b3783          	ld	a5,0(s6)
ffffffffc0202e6a:	6522                	ld	a0,8(sp)
ffffffffc0202e6c:	4585                	li	a1,1
ffffffffc0202e6e:	739c                	ld	a5,32(a5)
ffffffffc0202e70:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e72:	b3dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e76:	bdb9                	j	ffffffffc0202cd4 <pmm_init+0x552>
        intr_disable();
ffffffffc0202e78:	b3dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e7c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e80:	4585                	li	a1,1
ffffffffc0202e82:	8552                	mv	a0,s4
ffffffffc0202e84:	739c                	ld	a5,32(a5)
ffffffffc0202e86:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e88:	b27fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e8c:	bd29                	j	ffffffffc0202ca6 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e8e:	86a2                	mv	a3,s0
ffffffffc0202e90:	00004617          	auipc	a2,0x4
ffffffffc0202e94:	a4060613          	addi	a2,a2,-1472 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0202e98:	25600593          	li	a1,598
ffffffffc0202e9c:	00004517          	auipc	a0,0x4
ffffffffc0202ea0:	b4c50513          	addi	a0,a0,-1204 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202ea4:	deafd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ea8:	00004697          	auipc	a3,0x4
ffffffffc0202eac:	fb068693          	addi	a3,a3,-80 # ffffffffc0206e58 <default_pmm_manager+0x5c0>
ffffffffc0202eb0:	00003617          	auipc	a2,0x3
ffffffffc0202eb4:	63860613          	addi	a2,a2,1592 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202eb8:	25700593          	li	a1,599
ffffffffc0202ebc:	00004517          	auipc	a0,0x4
ffffffffc0202ec0:	b2c50513          	addi	a0,a0,-1236 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202ec4:	dcafd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ec8:	00004697          	auipc	a3,0x4
ffffffffc0202ecc:	f5068693          	addi	a3,a3,-176 # ffffffffc0206e18 <default_pmm_manager+0x580>
ffffffffc0202ed0:	00003617          	auipc	a2,0x3
ffffffffc0202ed4:	61860613          	addi	a2,a2,1560 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202ed8:	25600593          	li	a1,598
ffffffffc0202edc:	00004517          	auipc	a0,0x4
ffffffffc0202ee0:	b0c50513          	addi	a0,a0,-1268 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202ee4:	daafd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202ee8:	fc5fe0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>
ffffffffc0202eec:	fddfe0ef          	jal	ra,ffffffffc0201ec8 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202ef0:	00004697          	auipc	a3,0x4
ffffffffc0202ef4:	d2068693          	addi	a3,a3,-736 # ffffffffc0206c10 <default_pmm_manager+0x378>
ffffffffc0202ef8:	00003617          	auipc	a2,0x3
ffffffffc0202efc:	5f060613          	addi	a2,a2,1520 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202f00:	22600593          	li	a1,550
ffffffffc0202f04:	00004517          	auipc	a0,0x4
ffffffffc0202f08:	ae450513          	addi	a0,a0,-1308 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202f0c:	d82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f10:	00004697          	auipc	a3,0x4
ffffffffc0202f14:	c4068693          	addi	a3,a3,-960 # ffffffffc0206b50 <default_pmm_manager+0x2b8>
ffffffffc0202f18:	00003617          	auipc	a2,0x3
ffffffffc0202f1c:	5d060613          	addi	a2,a2,1488 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202f20:	21900593          	li	a1,537
ffffffffc0202f24:	00004517          	auipc	a0,0x4
ffffffffc0202f28:	ac450513          	addi	a0,a0,-1340 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202f2c:	d62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f30:	00004697          	auipc	a3,0x4
ffffffffc0202f34:	be068693          	addi	a3,a3,-1056 # ffffffffc0206b10 <default_pmm_manager+0x278>
ffffffffc0202f38:	00003617          	auipc	a2,0x3
ffffffffc0202f3c:	5b060613          	addi	a2,a2,1456 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202f40:	21800593          	li	a1,536
ffffffffc0202f44:	00004517          	auipc	a0,0x4
ffffffffc0202f48:	aa450513          	addi	a0,a0,-1372 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202f4c:	d42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f50:	00004697          	auipc	a3,0x4
ffffffffc0202f54:	ba068693          	addi	a3,a3,-1120 # ffffffffc0206af0 <default_pmm_manager+0x258>
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	59060613          	addi	a2,a2,1424 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202f60:	21700593          	li	a1,535
ffffffffc0202f64:	00004517          	auipc	a0,0x4
ffffffffc0202f68:	a8450513          	addi	a0,a0,-1404 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202f6c:	d22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f70:	00004617          	auipc	a2,0x4
ffffffffc0202f74:	96060613          	addi	a2,a2,-1696 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0202f78:	07100593          	li	a1,113
ffffffffc0202f7c:	00004517          	auipc	a0,0x4
ffffffffc0202f80:	97c50513          	addi	a0,a0,-1668 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0202f84:	d0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	e1868693          	addi	a3,a3,-488 # ffffffffc0206da0 <default_pmm_manager+0x508>
ffffffffc0202f90:	00003617          	auipc	a2,0x3
ffffffffc0202f94:	55860613          	addi	a2,a2,1368 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202f98:	23f00593          	li	a1,575
ffffffffc0202f9c:	00004517          	auipc	a0,0x4
ffffffffc0202fa0:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202fa4:	ceafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fa8:	00004697          	auipc	a3,0x4
ffffffffc0202fac:	db068693          	addi	a3,a3,-592 # ffffffffc0206d58 <default_pmm_manager+0x4c0>
ffffffffc0202fb0:	00003617          	auipc	a2,0x3
ffffffffc0202fb4:	53860613          	addi	a2,a2,1336 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202fb8:	23d00593          	li	a1,573
ffffffffc0202fbc:	00004517          	auipc	a0,0x4
ffffffffc0202fc0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202fc4:	ccafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fc8:	00004697          	auipc	a3,0x4
ffffffffc0202fcc:	dc068693          	addi	a3,a3,-576 # ffffffffc0206d88 <default_pmm_manager+0x4f0>
ffffffffc0202fd0:	00003617          	auipc	a2,0x3
ffffffffc0202fd4:	51860613          	addi	a2,a2,1304 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202fd8:	23c00593          	li	a1,572
ffffffffc0202fdc:	00004517          	auipc	a0,0x4
ffffffffc0202fe0:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0202fe4:	caafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fe8:	00004697          	auipc	a3,0x4
ffffffffc0202fec:	e8868693          	addi	a3,a3,-376 # ffffffffc0206e70 <default_pmm_manager+0x5d8>
ffffffffc0202ff0:	00003617          	auipc	a2,0x3
ffffffffc0202ff4:	4f860613          	addi	a2,a2,1272 # ffffffffc02064e8 <commands+0x828>
ffffffffc0202ff8:	25a00593          	li	a1,602
ffffffffc0202ffc:	00004517          	auipc	a0,0x4
ffffffffc0203000:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203004:	c8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203008:	00004697          	auipc	a3,0x4
ffffffffc020300c:	dc868693          	addi	a3,a3,-568 # ffffffffc0206dd0 <default_pmm_manager+0x538>
ffffffffc0203010:	00003617          	auipc	a2,0x3
ffffffffc0203014:	4d860613          	addi	a2,a2,1240 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203018:	24700593          	li	a1,583
ffffffffc020301c:	00004517          	auipc	a0,0x4
ffffffffc0203020:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203024:	c6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203028:	00004697          	auipc	a3,0x4
ffffffffc020302c:	ea068693          	addi	a3,a3,-352 # ffffffffc0206ec8 <default_pmm_manager+0x630>
ffffffffc0203030:	00003617          	auipc	a2,0x3
ffffffffc0203034:	4b860613          	addi	a2,a2,1208 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203038:	25f00593          	li	a1,607
ffffffffc020303c:	00004517          	auipc	a0,0x4
ffffffffc0203040:	9ac50513          	addi	a0,a0,-1620 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203044:	c4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203048:	00004697          	auipc	a3,0x4
ffffffffc020304c:	e4068693          	addi	a3,a3,-448 # ffffffffc0206e88 <default_pmm_manager+0x5f0>
ffffffffc0203050:	00003617          	auipc	a2,0x3
ffffffffc0203054:	49860613          	addi	a2,a2,1176 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203058:	25e00593          	li	a1,606
ffffffffc020305c:	00004517          	auipc	a0,0x4
ffffffffc0203060:	98c50513          	addi	a0,a0,-1652 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203064:	c2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203068:	00004697          	auipc	a3,0x4
ffffffffc020306c:	cf068693          	addi	a3,a3,-784 # ffffffffc0206d58 <default_pmm_manager+0x4c0>
ffffffffc0203070:	00003617          	auipc	a2,0x3
ffffffffc0203074:	47860613          	addi	a2,a2,1144 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203078:	23900593          	li	a1,569
ffffffffc020307c:	00004517          	auipc	a0,0x4
ffffffffc0203080:	96c50513          	addi	a0,a0,-1684 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203084:	c0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203088:	00004697          	auipc	a3,0x4
ffffffffc020308c:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206bf8 <default_pmm_manager+0x360>
ffffffffc0203090:	00003617          	auipc	a2,0x3
ffffffffc0203094:	45860613          	addi	a2,a2,1112 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203098:	23800593          	li	a1,568
ffffffffc020309c:	00004517          	auipc	a0,0x4
ffffffffc02030a0:	94c50513          	addi	a0,a0,-1716 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02030a4:	beafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030a8:	00004697          	auipc	a3,0x4
ffffffffc02030ac:	cc868693          	addi	a3,a3,-824 # ffffffffc0206d70 <default_pmm_manager+0x4d8>
ffffffffc02030b0:	00003617          	auipc	a2,0x3
ffffffffc02030b4:	43860613          	addi	a2,a2,1080 # ffffffffc02064e8 <commands+0x828>
ffffffffc02030b8:	23500593          	li	a1,565
ffffffffc02030bc:	00004517          	auipc	a0,0x4
ffffffffc02030c0:	92c50513          	addi	a0,a0,-1748 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02030c4:	bcafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030c8:	00004697          	auipc	a3,0x4
ffffffffc02030cc:	b1868693          	addi	a3,a3,-1256 # ffffffffc0206be0 <default_pmm_manager+0x348>
ffffffffc02030d0:	00003617          	auipc	a2,0x3
ffffffffc02030d4:	41860613          	addi	a2,a2,1048 # ffffffffc02064e8 <commands+0x828>
ffffffffc02030d8:	23400593          	li	a1,564
ffffffffc02030dc:	00004517          	auipc	a0,0x4
ffffffffc02030e0:	90c50513          	addi	a0,a0,-1780 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02030e4:	baafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030e8:	00004697          	auipc	a3,0x4
ffffffffc02030ec:	b9868693          	addi	a3,a3,-1128 # ffffffffc0206c80 <default_pmm_manager+0x3e8>
ffffffffc02030f0:	00003617          	auipc	a2,0x3
ffffffffc02030f4:	3f860613          	addi	a2,a2,1016 # ffffffffc02064e8 <commands+0x828>
ffffffffc02030f8:	23300593          	li	a1,563
ffffffffc02030fc:	00004517          	auipc	a0,0x4
ffffffffc0203100:	8ec50513          	addi	a0,a0,-1812 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203104:	b8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203108:	00004697          	auipc	a3,0x4
ffffffffc020310c:	c5068693          	addi	a3,a3,-944 # ffffffffc0206d58 <default_pmm_manager+0x4c0>
ffffffffc0203110:	00003617          	auipc	a2,0x3
ffffffffc0203114:	3d860613          	addi	a2,a2,984 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203118:	23200593          	li	a1,562
ffffffffc020311c:	00004517          	auipc	a0,0x4
ffffffffc0203120:	8cc50513          	addi	a0,a0,-1844 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203124:	b6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203128:	00004697          	auipc	a3,0x4
ffffffffc020312c:	c1868693          	addi	a3,a3,-1000 # ffffffffc0206d40 <default_pmm_manager+0x4a8>
ffffffffc0203130:	00003617          	auipc	a2,0x3
ffffffffc0203134:	3b860613          	addi	a2,a2,952 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203138:	23100593          	li	a1,561
ffffffffc020313c:	00004517          	auipc	a0,0x4
ffffffffc0203140:	8ac50513          	addi	a0,a0,-1876 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203144:	b4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203148:	00004697          	auipc	a3,0x4
ffffffffc020314c:	bc868693          	addi	a3,a3,-1080 # ffffffffc0206d10 <default_pmm_manager+0x478>
ffffffffc0203150:	00003617          	auipc	a2,0x3
ffffffffc0203154:	39860613          	addi	a2,a2,920 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203158:	23000593          	li	a1,560
ffffffffc020315c:	00004517          	auipc	a0,0x4
ffffffffc0203160:	88c50513          	addi	a0,a0,-1908 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203164:	b2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203168:	00004697          	auipc	a3,0x4
ffffffffc020316c:	b9068693          	addi	a3,a3,-1136 # ffffffffc0206cf8 <default_pmm_manager+0x460>
ffffffffc0203170:	00003617          	auipc	a2,0x3
ffffffffc0203174:	37860613          	addi	a2,a2,888 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203178:	22e00593          	li	a1,558
ffffffffc020317c:	00004517          	auipc	a0,0x4
ffffffffc0203180:	86c50513          	addi	a0,a0,-1940 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203184:	b0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203188:	00004697          	auipc	a3,0x4
ffffffffc020318c:	b5068693          	addi	a3,a3,-1200 # ffffffffc0206cd8 <default_pmm_manager+0x440>
ffffffffc0203190:	00003617          	auipc	a2,0x3
ffffffffc0203194:	35860613          	addi	a2,a2,856 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203198:	22d00593          	li	a1,557
ffffffffc020319c:	00004517          	auipc	a0,0x4
ffffffffc02031a0:	84c50513          	addi	a0,a0,-1972 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02031a4:	aeafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031a8:	00004697          	auipc	a3,0x4
ffffffffc02031ac:	b2068693          	addi	a3,a3,-1248 # ffffffffc0206cc8 <default_pmm_manager+0x430>
ffffffffc02031b0:	00003617          	auipc	a2,0x3
ffffffffc02031b4:	33860613          	addi	a2,a2,824 # ffffffffc02064e8 <commands+0x828>
ffffffffc02031b8:	22c00593          	li	a1,556
ffffffffc02031bc:	00004517          	auipc	a0,0x4
ffffffffc02031c0:	82c50513          	addi	a0,a0,-2004 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02031c4:	acafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031c8:	00004697          	auipc	a3,0x4
ffffffffc02031cc:	af068693          	addi	a3,a3,-1296 # ffffffffc0206cb8 <default_pmm_manager+0x420>
ffffffffc02031d0:	00003617          	auipc	a2,0x3
ffffffffc02031d4:	31860613          	addi	a2,a2,792 # ffffffffc02064e8 <commands+0x828>
ffffffffc02031d8:	22b00593          	li	a1,555
ffffffffc02031dc:	00004517          	auipc	a0,0x4
ffffffffc02031e0:	80c50513          	addi	a0,a0,-2036 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02031e4:	aaafd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc02031e8:	00004617          	auipc	a2,0x4
ffffffffc02031ec:	87060613          	addi	a2,a2,-1936 # ffffffffc0206a58 <default_pmm_manager+0x1c0>
ffffffffc02031f0:	06500593          	li	a1,101
ffffffffc02031f4:	00003517          	auipc	a0,0x3
ffffffffc02031f8:	7f450513          	addi	a0,a0,2036 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02031fc:	a92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	bd068693          	addi	a3,a3,-1072 # ffffffffc0206dd0 <default_pmm_manager+0x538>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	2e060613          	addi	a2,a2,736 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203210:	27100593          	li	a1,625
ffffffffc0203214:	00003517          	auipc	a0,0x3
ffffffffc0203218:	7d450513          	addi	a0,a0,2004 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020321c:	a72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	a6068693          	addi	a3,a3,-1440 # ffffffffc0206c80 <default_pmm_manager+0x3e8>
ffffffffc0203228:	00003617          	auipc	a2,0x3
ffffffffc020322c:	2c060613          	addi	a2,a2,704 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203230:	22a00593          	li	a1,554
ffffffffc0203234:	00003517          	auipc	a0,0x3
ffffffffc0203238:	7b450513          	addi	a0,a0,1972 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020323c:	a52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203240:	00004697          	auipc	a3,0x4
ffffffffc0203244:	a0068693          	addi	a3,a3,-1536 # ffffffffc0206c40 <default_pmm_manager+0x3a8>
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	2a060613          	addi	a2,a2,672 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203250:	22900593          	li	a1,553
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	79450513          	addi	a0,a0,1940 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020325c:	a32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203260:	86d6                	mv	a3,s5
ffffffffc0203262:	00003617          	auipc	a2,0x3
ffffffffc0203266:	66e60613          	addi	a2,a2,1646 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc020326a:	22500593          	li	a1,549
ffffffffc020326e:	00003517          	auipc	a0,0x3
ffffffffc0203272:	77a50513          	addi	a0,a0,1914 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203276:	a18fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020327a:	00003617          	auipc	a2,0x3
ffffffffc020327e:	65660613          	addi	a2,a2,1622 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0203282:	22400593          	li	a1,548
ffffffffc0203286:	00003517          	auipc	a0,0x3
ffffffffc020328a:	76250513          	addi	a0,a0,1890 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020328e:	a00fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203292:	00004697          	auipc	a3,0x4
ffffffffc0203296:	96668693          	addi	a3,a3,-1690 # ffffffffc0206bf8 <default_pmm_manager+0x360>
ffffffffc020329a:	00003617          	auipc	a2,0x3
ffffffffc020329e:	24e60613          	addi	a2,a2,590 # ffffffffc02064e8 <commands+0x828>
ffffffffc02032a2:	22200593          	li	a1,546
ffffffffc02032a6:	00003517          	auipc	a0,0x3
ffffffffc02032aa:	74250513          	addi	a0,a0,1858 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02032ae:	9e0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032b2:	00004697          	auipc	a3,0x4
ffffffffc02032b6:	92e68693          	addi	a3,a3,-1746 # ffffffffc0206be0 <default_pmm_manager+0x348>
ffffffffc02032ba:	00003617          	auipc	a2,0x3
ffffffffc02032be:	22e60613          	addi	a2,a2,558 # ffffffffc02064e8 <commands+0x828>
ffffffffc02032c2:	22100593          	li	a1,545
ffffffffc02032c6:	00003517          	auipc	a0,0x3
ffffffffc02032ca:	72250513          	addi	a0,a0,1826 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02032ce:	9c0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032d2:	00004697          	auipc	a3,0x4
ffffffffc02032d6:	cbe68693          	addi	a3,a3,-834 # ffffffffc0206f90 <default_pmm_manager+0x6f8>
ffffffffc02032da:	00003617          	auipc	a2,0x3
ffffffffc02032de:	20e60613          	addi	a2,a2,526 # ffffffffc02064e8 <commands+0x828>
ffffffffc02032e2:	26800593          	li	a1,616
ffffffffc02032e6:	00003517          	auipc	a0,0x3
ffffffffc02032ea:	70250513          	addi	a0,a0,1794 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02032ee:	9a0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032f2:	00004697          	auipc	a3,0x4
ffffffffc02032f6:	c6668693          	addi	a3,a3,-922 # ffffffffc0206f58 <default_pmm_manager+0x6c0>
ffffffffc02032fa:	00003617          	auipc	a2,0x3
ffffffffc02032fe:	1ee60613          	addi	a2,a2,494 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203302:	26500593          	li	a1,613
ffffffffc0203306:	00003517          	auipc	a0,0x3
ffffffffc020330a:	6e250513          	addi	a0,a0,1762 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020330e:	980fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203312:	00004697          	auipc	a3,0x4
ffffffffc0203316:	c1668693          	addi	a3,a3,-1002 # ffffffffc0206f28 <default_pmm_manager+0x690>
ffffffffc020331a:	00003617          	auipc	a2,0x3
ffffffffc020331e:	1ce60613          	addi	a2,a2,462 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203322:	26100593          	li	a1,609
ffffffffc0203326:	00003517          	auipc	a0,0x3
ffffffffc020332a:	6c250513          	addi	a0,a0,1730 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020332e:	960fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203332:	00004697          	auipc	a3,0x4
ffffffffc0203336:	bae68693          	addi	a3,a3,-1106 # ffffffffc0206ee0 <default_pmm_manager+0x648>
ffffffffc020333a:	00003617          	auipc	a2,0x3
ffffffffc020333e:	1ae60613          	addi	a2,a2,430 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203342:	26000593          	li	a1,608
ffffffffc0203346:	00003517          	auipc	a0,0x3
ffffffffc020334a:	6a250513          	addi	a0,a0,1698 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020334e:	940fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	62660613          	addi	a2,a2,1574 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc020335a:	0c900593          	li	a1,201
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	68a50513          	addi	a0,a0,1674 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203366:	928fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020336a:	00003617          	auipc	a2,0x3
ffffffffc020336e:	60e60613          	addi	a2,a2,1550 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc0203372:	08100593          	li	a1,129
ffffffffc0203376:	00003517          	auipc	a0,0x3
ffffffffc020337a:	67250513          	addi	a0,a0,1650 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020337e:	910fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203382:	00004697          	auipc	a3,0x4
ffffffffc0203386:	82e68693          	addi	a3,a3,-2002 # ffffffffc0206bb0 <default_pmm_manager+0x318>
ffffffffc020338a:	00003617          	auipc	a2,0x3
ffffffffc020338e:	15e60613          	addi	a2,a2,350 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203392:	22000593          	li	a1,544
ffffffffc0203396:	00003517          	auipc	a0,0x3
ffffffffc020339a:	65250513          	addi	a0,a0,1618 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020339e:	8f0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033a2:	00003697          	auipc	a3,0x3
ffffffffc02033a6:	7de68693          	addi	a3,a3,2014 # ffffffffc0206b80 <default_pmm_manager+0x2e8>
ffffffffc02033aa:	00003617          	auipc	a2,0x3
ffffffffc02033ae:	13e60613          	addi	a2,a2,318 # ffffffffc02064e8 <commands+0x828>
ffffffffc02033b2:	21d00593          	li	a1,541
ffffffffc02033b6:	00003517          	auipc	a0,0x3
ffffffffc02033ba:	63250513          	addi	a0,a0,1586 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02033be:	8d0fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02033c2 <copy_range>:
{
ffffffffc02033c2:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033c4:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033c8:	f486                	sd	ra,104(sp)
ffffffffc02033ca:	f0a2                	sd	s0,96(sp)
ffffffffc02033cc:	eca6                	sd	s1,88(sp)
ffffffffc02033ce:	e8ca                	sd	s2,80(sp)
ffffffffc02033d0:	e4ce                	sd	s3,72(sp)
ffffffffc02033d2:	e0d2                	sd	s4,64(sp)
ffffffffc02033d4:	fc56                	sd	s5,56(sp)
ffffffffc02033d6:	f85a                	sd	s6,48(sp)
ffffffffc02033d8:	f45e                	sd	s7,40(sp)
ffffffffc02033da:	f062                	sd	s8,32(sp)
ffffffffc02033dc:	ec66                	sd	s9,24(sp)
ffffffffc02033de:	e86a                	sd	s10,16(sp)
ffffffffc02033e0:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033e2:	17d2                	slli	a5,a5,0x34
ffffffffc02033e4:	20079f63          	bnez	a5,ffffffffc0203602 <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc02033e8:	002007b7          	lui	a5,0x200
ffffffffc02033ec:	8432                	mv	s0,a2
ffffffffc02033ee:	1af66263          	bltu	a2,a5,ffffffffc0203592 <copy_range+0x1d0>
ffffffffc02033f2:	8936                	mv	s2,a3
ffffffffc02033f4:	18d67f63          	bgeu	a2,a3,ffffffffc0203592 <copy_range+0x1d0>
ffffffffc02033f8:	4785                	li	a5,1
ffffffffc02033fa:	07fe                	slli	a5,a5,0x1f
ffffffffc02033fc:	18d7eb63          	bltu	a5,a3,ffffffffc0203592 <copy_range+0x1d0>
ffffffffc0203400:	5b7d                	li	s6,-1
ffffffffc0203402:	8aaa                	mv	s5,a0
ffffffffc0203404:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0203406:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0203408:	000a7c17          	auipc	s8,0xa7
ffffffffc020340c:	420c0c13          	addi	s8,s8,1056 # ffffffffc02aa828 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203410:	000a7b97          	auipc	s7,0xa7
ffffffffc0203414:	420b8b93          	addi	s7,s7,1056 # ffffffffc02aa830 <pages>
    return KADDR(page2pa(page));
ffffffffc0203418:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc020341c:	000a7c97          	auipc	s9,0xa7
ffffffffc0203420:	41cc8c93          	addi	s9,s9,1052 # ffffffffc02aa838 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203424:	4601                	li	a2,0
ffffffffc0203426:	85a2                	mv	a1,s0
ffffffffc0203428:	854e                	mv	a0,s3
ffffffffc020342a:	b73fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc020342e:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203430:	0e050c63          	beqz	a0,ffffffffc0203528 <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc0203434:	611c                	ld	a5,0(a0)
ffffffffc0203436:	8b85                	andi	a5,a5,1
ffffffffc0203438:	e785                	bnez	a5,ffffffffc0203460 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc020343a:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020343c:	ff2464e3          	bltu	s0,s2,ffffffffc0203424 <copy_range+0x62>
    return 0;
ffffffffc0203440:	4501                	li	a0,0
}
ffffffffc0203442:	70a6                	ld	ra,104(sp)
ffffffffc0203444:	7406                	ld	s0,96(sp)
ffffffffc0203446:	64e6                	ld	s1,88(sp)
ffffffffc0203448:	6946                	ld	s2,80(sp)
ffffffffc020344a:	69a6                	ld	s3,72(sp)
ffffffffc020344c:	6a06                	ld	s4,64(sp)
ffffffffc020344e:	7ae2                	ld	s5,56(sp)
ffffffffc0203450:	7b42                	ld	s6,48(sp)
ffffffffc0203452:	7ba2                	ld	s7,40(sp)
ffffffffc0203454:	7c02                	ld	s8,32(sp)
ffffffffc0203456:	6ce2                	ld	s9,24(sp)
ffffffffc0203458:	6d42                	ld	s10,16(sp)
ffffffffc020345a:	6da2                	ld	s11,8(sp)
ffffffffc020345c:	6165                	addi	sp,sp,112
ffffffffc020345e:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203460:	4605                	li	a2,1
ffffffffc0203462:	85a2                	mv	a1,s0
ffffffffc0203464:	8556                	mv	a0,s5
ffffffffc0203466:	b37fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc020346a:	c56d                	beqz	a0,ffffffffc0203554 <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020346c:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc020346e:	0017f713          	andi	a4,a5,1
ffffffffc0203472:	01f7f493          	andi	s1,a5,31
ffffffffc0203476:	16070a63          	beqz	a4,ffffffffc02035ea <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc020347a:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020347e:	078a                	slli	a5,a5,0x2
ffffffffc0203480:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203484:	14d77763          	bgeu	a4,a3,ffffffffc02035d2 <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc0203488:	000bb783          	ld	a5,0(s7)
ffffffffc020348c:	fff806b7          	lui	a3,0xfff80
ffffffffc0203490:	9736                	add	a4,a4,a3
ffffffffc0203492:	071a                	slli	a4,a4,0x6
ffffffffc0203494:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203498:	10002773          	csrr	a4,sstatus
ffffffffc020349c:	8b09                	andi	a4,a4,2
ffffffffc020349e:	e345                	bnez	a4,ffffffffc020353e <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034a0:	000cb703          	ld	a4,0(s9)
ffffffffc02034a4:	4505                	li	a0,1
ffffffffc02034a6:	6f18                	ld	a4,24(a4)
ffffffffc02034a8:	9702                	jalr	a4
ffffffffc02034aa:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02034ac:	0c0d8363          	beqz	s11,ffffffffc0203572 <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc02034b0:	100d0163          	beqz	s10,ffffffffc02035b2 <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc02034b4:	000bb703          	ld	a4,0(s7)
ffffffffc02034b8:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc02034bc:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02034c0:	40ed86b3          	sub	a3,s11,a4
ffffffffc02034c4:	8699                	srai	a3,a3,0x6
ffffffffc02034c6:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02034c8:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034cc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034ce:	08c7f663          	bgeu	a5,a2,ffffffffc020355a <copy_range+0x198>
    return page - pages + nbase;
ffffffffc02034d2:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc02034d6:	000a7717          	auipc	a4,0xa7
ffffffffc02034da:	36a70713          	addi	a4,a4,874 # ffffffffc02aa840 <va_pa_offset>
ffffffffc02034de:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02034e0:	8799                	srai	a5,a5,0x6
ffffffffc02034e2:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc02034e4:	0167f733          	and	a4,a5,s6
ffffffffc02034e8:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02034ec:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034ee:	06c77563          	bgeu	a4,a2,ffffffffc0203558 <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034f2:	6605                	lui	a2,0x1
ffffffffc02034f4:	953e                	add	a0,a0,a5
ffffffffc02034f6:	54a020ef          	jal	ra,ffffffffc0205a40 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034fa:	86a6                	mv	a3,s1
ffffffffc02034fc:	8622                	mv	a2,s0
ffffffffc02034fe:	85ea                	mv	a1,s10
ffffffffc0203500:	8556                	mv	a0,s5
ffffffffc0203502:	98aff0ef          	jal	ra,ffffffffc020268c <page_insert>
            assert(ret == 0);
ffffffffc0203506:	d915                	beqz	a0,ffffffffc020343a <copy_range+0x78>
ffffffffc0203508:	00004697          	auipc	a3,0x4
ffffffffc020350c:	af068693          	addi	a3,a3,-1296 # ffffffffc0206ff8 <default_pmm_manager+0x760>
ffffffffc0203510:	00003617          	auipc	a2,0x3
ffffffffc0203514:	fd860613          	addi	a2,a2,-40 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203518:	1b500593          	li	a1,437
ffffffffc020351c:	00003517          	auipc	a0,0x3
ffffffffc0203520:	4cc50513          	addi	a0,a0,1228 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc0203524:	f6bfc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203528:	00200637          	lui	a2,0x200
ffffffffc020352c:	9432                	add	s0,s0,a2
ffffffffc020352e:	ffe00637          	lui	a2,0xffe00
ffffffffc0203532:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc0203534:	f00406e3          	beqz	s0,ffffffffc0203440 <copy_range+0x7e>
ffffffffc0203538:	ef2466e3          	bltu	s0,s2,ffffffffc0203424 <copy_range+0x62>
ffffffffc020353c:	b711                	j	ffffffffc0203440 <copy_range+0x7e>
        intr_disable();
ffffffffc020353e:	c76fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203542:	000cb703          	ld	a4,0(s9)
ffffffffc0203546:	4505                	li	a0,1
ffffffffc0203548:	6f18                	ld	a4,24(a4)
ffffffffc020354a:	9702                	jalr	a4
ffffffffc020354c:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc020354e:	c60fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203552:	bfa9                	j	ffffffffc02034ac <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc0203554:	5571                	li	a0,-4
ffffffffc0203556:	b5f5                	j	ffffffffc0203442 <copy_range+0x80>
ffffffffc0203558:	86be                	mv	a3,a5
ffffffffc020355a:	00003617          	auipc	a2,0x3
ffffffffc020355e:	37660613          	addi	a2,a2,886 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0203562:	07100593          	li	a1,113
ffffffffc0203566:	00003517          	auipc	a0,0x3
ffffffffc020356a:	39250513          	addi	a0,a0,914 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc020356e:	f21fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203572:	00004697          	auipc	a3,0x4
ffffffffc0203576:	a6668693          	addi	a3,a3,-1434 # ffffffffc0206fd8 <default_pmm_manager+0x740>
ffffffffc020357a:	00003617          	auipc	a2,0x3
ffffffffc020357e:	f6e60613          	addi	a2,a2,-146 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203582:	19400593          	li	a1,404
ffffffffc0203586:	00003517          	auipc	a0,0x3
ffffffffc020358a:	46250513          	addi	a0,a0,1122 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020358e:	f01fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203592:	00003697          	auipc	a3,0x3
ffffffffc0203596:	49668693          	addi	a3,a3,1174 # ffffffffc0206a28 <default_pmm_manager+0x190>
ffffffffc020359a:	00003617          	auipc	a2,0x3
ffffffffc020359e:	f4e60613          	addi	a2,a2,-178 # ffffffffc02064e8 <commands+0x828>
ffffffffc02035a2:	17c00593          	li	a1,380
ffffffffc02035a6:	00003517          	auipc	a0,0x3
ffffffffc02035aa:	44250513          	addi	a0,a0,1090 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02035ae:	ee1fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc02035b2:	00004697          	auipc	a3,0x4
ffffffffc02035b6:	a3668693          	addi	a3,a3,-1482 # ffffffffc0206fe8 <default_pmm_manager+0x750>
ffffffffc02035ba:	00003617          	auipc	a2,0x3
ffffffffc02035be:	f2e60613          	addi	a2,a2,-210 # ffffffffc02064e8 <commands+0x828>
ffffffffc02035c2:	19500593          	li	a1,405
ffffffffc02035c6:	00003517          	auipc	a0,0x3
ffffffffc02035ca:	42250513          	addi	a0,a0,1058 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02035ce:	ec1fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035d2:	00003617          	auipc	a2,0x3
ffffffffc02035d6:	3ce60613          	addi	a2,a2,974 # ffffffffc02069a0 <default_pmm_manager+0x108>
ffffffffc02035da:	06900593          	li	a1,105
ffffffffc02035de:	00003517          	auipc	a0,0x3
ffffffffc02035e2:	31a50513          	addi	a0,a0,794 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02035e6:	ea9fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035ea:	00003617          	auipc	a2,0x3
ffffffffc02035ee:	3d660613          	addi	a2,a2,982 # ffffffffc02069c0 <default_pmm_manager+0x128>
ffffffffc02035f2:	07f00593          	li	a1,127
ffffffffc02035f6:	00003517          	auipc	a0,0x3
ffffffffc02035fa:	30250513          	addi	a0,a0,770 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02035fe:	e91fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203602:	00003697          	auipc	a3,0x3
ffffffffc0203606:	3f668693          	addi	a3,a3,1014 # ffffffffc02069f8 <default_pmm_manager+0x160>
ffffffffc020360a:	00003617          	auipc	a2,0x3
ffffffffc020360e:	ede60613          	addi	a2,a2,-290 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203612:	17b00593          	li	a1,379
ffffffffc0203616:	00003517          	auipc	a0,0x3
ffffffffc020361a:	3d250513          	addi	a0,a0,978 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc020361e:	e71fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203622 <pgdir_alloc_page>:
{
ffffffffc0203622:	7179                	addi	sp,sp,-48
ffffffffc0203624:	ec26                	sd	s1,24(sp)
ffffffffc0203626:	e84a                	sd	s2,16(sp)
ffffffffc0203628:	e052                	sd	s4,0(sp)
ffffffffc020362a:	f406                	sd	ra,40(sp)
ffffffffc020362c:	f022                	sd	s0,32(sp)
ffffffffc020362e:	e44e                	sd	s3,8(sp)
ffffffffc0203630:	8a2a                	mv	s4,a0
ffffffffc0203632:	84ae                	mv	s1,a1
ffffffffc0203634:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203636:	100027f3          	csrr	a5,sstatus
ffffffffc020363a:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc020363c:	000a7997          	auipc	s3,0xa7
ffffffffc0203640:	1fc98993          	addi	s3,s3,508 # ffffffffc02aa838 <pmm_manager>
ffffffffc0203644:	ef8d                	bnez	a5,ffffffffc020367e <pgdir_alloc_page+0x5c>
ffffffffc0203646:	0009b783          	ld	a5,0(s3)
ffffffffc020364a:	4505                	li	a0,1
ffffffffc020364c:	6f9c                	ld	a5,24(a5)
ffffffffc020364e:	9782                	jalr	a5
ffffffffc0203650:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203652:	cc09                	beqz	s0,ffffffffc020366c <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203654:	86ca                	mv	a3,s2
ffffffffc0203656:	8626                	mv	a2,s1
ffffffffc0203658:	85a2                	mv	a1,s0
ffffffffc020365a:	8552                	mv	a0,s4
ffffffffc020365c:	830ff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc0203660:	e915                	bnez	a0,ffffffffc0203694 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203662:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203664:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203666:	4785                	li	a5,1
ffffffffc0203668:	04f71e63          	bne	a4,a5,ffffffffc02036c4 <pgdir_alloc_page+0xa2>
}
ffffffffc020366c:	70a2                	ld	ra,40(sp)
ffffffffc020366e:	8522                	mv	a0,s0
ffffffffc0203670:	7402                	ld	s0,32(sp)
ffffffffc0203672:	64e2                	ld	s1,24(sp)
ffffffffc0203674:	6942                	ld	s2,16(sp)
ffffffffc0203676:	69a2                	ld	s3,8(sp)
ffffffffc0203678:	6a02                	ld	s4,0(sp)
ffffffffc020367a:	6145                	addi	sp,sp,48
ffffffffc020367c:	8082                	ret
        intr_disable();
ffffffffc020367e:	b36fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203682:	0009b783          	ld	a5,0(s3)
ffffffffc0203686:	4505                	li	a0,1
ffffffffc0203688:	6f9c                	ld	a5,24(a5)
ffffffffc020368a:	9782                	jalr	a5
ffffffffc020368c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020368e:	b20fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203692:	b7c1                	j	ffffffffc0203652 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203694:	100027f3          	csrr	a5,sstatus
ffffffffc0203698:	8b89                	andi	a5,a5,2
ffffffffc020369a:	eb89                	bnez	a5,ffffffffc02036ac <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020369c:	0009b783          	ld	a5,0(s3)
ffffffffc02036a0:	8522                	mv	a0,s0
ffffffffc02036a2:	4585                	li	a1,1
ffffffffc02036a4:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02036a6:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02036a8:	9782                	jalr	a5
    if (flag)
ffffffffc02036aa:	b7c9                	j	ffffffffc020366c <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc02036ac:	b08fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02036b0:	0009b783          	ld	a5,0(s3)
ffffffffc02036b4:	8522                	mv	a0,s0
ffffffffc02036b6:	4585                	li	a1,1
ffffffffc02036b8:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02036ba:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02036bc:	9782                	jalr	a5
        intr_enable();
ffffffffc02036be:	af0fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02036c2:	b76d                	j	ffffffffc020366c <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc02036c4:	00004697          	auipc	a3,0x4
ffffffffc02036c8:	94468693          	addi	a3,a3,-1724 # ffffffffc0207008 <default_pmm_manager+0x770>
ffffffffc02036cc:	00003617          	auipc	a2,0x3
ffffffffc02036d0:	e1c60613          	addi	a2,a2,-484 # ffffffffc02064e8 <commands+0x828>
ffffffffc02036d4:	1fe00593          	li	a1,510
ffffffffc02036d8:	00003517          	auipc	a0,0x3
ffffffffc02036dc:	31050513          	addi	a0,a0,784 # ffffffffc02069e8 <default_pmm_manager+0x150>
ffffffffc02036e0:	daffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036e4 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036e4:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036e6:	00004697          	auipc	a3,0x4
ffffffffc02036ea:	93a68693          	addi	a3,a3,-1734 # ffffffffc0207020 <default_pmm_manager+0x788>
ffffffffc02036ee:	00003617          	auipc	a2,0x3
ffffffffc02036f2:	dfa60613          	addi	a2,a2,-518 # ffffffffc02064e8 <commands+0x828>
ffffffffc02036f6:	0d800593          	li	a1,216
ffffffffc02036fa:	00004517          	auipc	a0,0x4
ffffffffc02036fe:	94650513          	addi	a0,a0,-1722 # ffffffffc0207040 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203702:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203704:	d8bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203708 <mm_create>:
{
ffffffffc0203708:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020370a:	04000513          	li	a0,64
{
ffffffffc020370e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203710:	df6fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
    if (mm != NULL)
ffffffffc0203714:	cd19                	beqz	a0,ffffffffc0203732 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203716:	e508                	sd	a0,8(a0)
ffffffffc0203718:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020371a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020371e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203722:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203726:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020372a:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020372e:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203732:	60a2                	ld	ra,8(sp)
ffffffffc0203734:	0141                	addi	sp,sp,16
ffffffffc0203736:	8082                	ret

ffffffffc0203738 <find_vma>:
{
ffffffffc0203738:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc020373a:	c505                	beqz	a0,ffffffffc0203762 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020373c:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020373e:	c501                	beqz	a0,ffffffffc0203746 <find_vma+0xe>
ffffffffc0203740:	651c                	ld	a5,8(a0)
ffffffffc0203742:	02f5f263          	bgeu	a1,a5,ffffffffc0203766 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203746:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0203748:	00f68d63          	beq	a3,a5,ffffffffc0203762 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020374c:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4eb8>
ffffffffc0203750:	00e5e663          	bltu	a1,a4,ffffffffc020375c <find_vma+0x24>
ffffffffc0203754:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203758:	00e5ec63          	bltu	a1,a4,ffffffffc0203770 <find_vma+0x38>
ffffffffc020375c:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020375e:	fef697e3          	bne	a3,a5,ffffffffc020374c <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203762:	4501                	li	a0,0
}
ffffffffc0203764:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203766:	691c                	ld	a5,16(a0)
ffffffffc0203768:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203746 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020376c:	ea88                	sd	a0,16(a3)
ffffffffc020376e:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203770:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203774:	ea88                	sd	a0,16(a3)
ffffffffc0203776:	8082                	ret

ffffffffc0203778 <do_pgfault>:
{
ffffffffc0203778:	1101                	addi	sp,sp,-32
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020377a:	85b2                	mv	a1,a2
{
ffffffffc020377c:	e822                	sd	s0,16(sp)
ffffffffc020377e:	e426                	sd	s1,8(sp)
ffffffffc0203780:	ec06                	sd	ra,24(sp)
ffffffffc0203782:	e04a                	sd	s2,0(sp)
ffffffffc0203784:	8432                	mv	s0,a2
ffffffffc0203786:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203788:	fb1ff0ef          	jal	ra,ffffffffc0203738 <find_vma>
    pgfault_num++;
ffffffffc020378c:	000a7797          	auipc	a5,0xa7
ffffffffc0203790:	0bc7a783          	lw	a5,188(a5) # ffffffffc02aa848 <pgfault_num>
ffffffffc0203794:	2785                	addiw	a5,a5,1
ffffffffc0203796:	000a7717          	auipc	a4,0xa7
ffffffffc020379a:	0af72923          	sw	a5,178(a4) # ffffffffc02aa848 <pgfault_num>
    if (vma == NULL || vma->vm_start > addr)
ffffffffc020379e:	cd21                	beqz	a0,ffffffffc02037f6 <do_pgfault+0x7e>
ffffffffc02037a0:	651c                	ld	a5,8(a0)
ffffffffc02037a2:	04f46a63          	bltu	s0,a5,ffffffffc02037f6 <do_pgfault+0x7e>
    if (vma->vm_flags & VM_READ)
ffffffffc02037a6:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02037a8:	4941                	li	s2,16
    if (vma->vm_flags & VM_READ)
ffffffffc02037aa:	0017f713          	andi	a4,a5,1
ffffffffc02037ae:	c311                	beqz	a4,ffffffffc02037b2 <do_pgfault+0x3a>
        perm |= PTE_R;
ffffffffc02037b0:	4949                	li	s2,18
    if (vma->vm_flags & VM_WRITE)
ffffffffc02037b2:	0027f713          	andi	a4,a5,2
ffffffffc02037b6:	c311                	beqz	a4,ffffffffc02037ba <do_pgfault+0x42>
        perm |= (PTE_W | PTE_R);
ffffffffc02037b8:	4959                	li	s2,22
    if (vma->vm_flags & VM_EXEC)
ffffffffc02037ba:	8b91                	andi	a5,a5,4
ffffffffc02037bc:	e395                	bnez	a5,ffffffffc02037e0 <do_pgfault+0x68>
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02037be:	75fd                	lui	a1,0xfffff
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc02037c0:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02037c2:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc02037c4:	4605                	li	a2,1
ffffffffc02037c6:	85a2                	mv	a1,s0
ffffffffc02037c8:	fd4fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc02037cc:	c11d                	beqz	a0,ffffffffc02037f2 <do_pgfault+0x7a>
    if (*ptep == 0)
ffffffffc02037ce:	611c                	ld	a5,0(a0)
ffffffffc02037d0:	cb99                	beqz	a5,ffffffffc02037e6 <do_pgfault+0x6e>
    ret = 0;
ffffffffc02037d2:	4501                	li	a0,0
}
ffffffffc02037d4:	60e2                	ld	ra,24(sp)
ffffffffc02037d6:	6442                	ld	s0,16(sp)
ffffffffc02037d8:	64a2                	ld	s1,8(sp)
ffffffffc02037da:	6902                	ld	s2,0(sp)
ffffffffc02037dc:	6105                	addi	sp,sp,32
ffffffffc02037de:	8082                	ret
        perm |= PTE_X;
ffffffffc02037e0:	00896913          	ori	s2,s2,8
ffffffffc02037e4:	bfe9                	j	ffffffffc02037be <do_pgfault+0x46>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc02037e6:	6c88                	ld	a0,24(s1)
ffffffffc02037e8:	864a                	mv	a2,s2
ffffffffc02037ea:	85a2                	mv	a1,s0
ffffffffc02037ec:	e37ff0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc02037f0:	f16d                	bnez	a0,ffffffffc02037d2 <do_pgfault+0x5a>
    ret = -E_NO_MEM;
ffffffffc02037f2:	5571                	li	a0,-4
            goto failed;
ffffffffc02037f4:	b7c5                	j	ffffffffc02037d4 <do_pgfault+0x5c>
    int ret = -E_INVAL;
ffffffffc02037f6:	5575                	li	a0,-3
ffffffffc02037f8:	bff1                	j	ffffffffc02037d4 <do_pgfault+0x5c>

ffffffffc02037fa <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037fa:	6590                	ld	a2,8(a1)
ffffffffc02037fc:	0105b803          	ld	a6,16(a1) # fffffffffffff010 <end+0x3fd547a4>
{
ffffffffc0203800:	1141                	addi	sp,sp,-16
ffffffffc0203802:	e406                	sd	ra,8(sp)
ffffffffc0203804:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203806:	01066763          	bltu	a2,a6,ffffffffc0203814 <insert_vma_struct+0x1a>
ffffffffc020380a:	a085                	j	ffffffffc020386a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020380c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203810:	04e66863          	bltu	a2,a4,ffffffffc0203860 <insert_vma_struct+0x66>
ffffffffc0203814:	86be                	mv	a3,a5
ffffffffc0203816:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203818:	fef51ae3          	bne	a0,a5,ffffffffc020380c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020381c:	02a68463          	beq	a3,a0,ffffffffc0203844 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203820:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203824:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203828:	08e8f163          	bgeu	a7,a4,ffffffffc02038aa <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020382c:	04e66f63          	bltu	a2,a4,ffffffffc020388a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203830:	00f50a63          	beq	a0,a5,ffffffffc0203844 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203834:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203838:	05076963          	bltu	a4,a6,ffffffffc020388a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020383c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203840:	02c77363          	bgeu	a4,a2,ffffffffc0203866 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203844:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203846:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203848:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020384c:	e390                	sd	a2,0(a5)
ffffffffc020384e:	e690                	sd	a2,8(a3)
}
ffffffffc0203850:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203852:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203854:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203856:	0017079b          	addiw	a5,a4,1
ffffffffc020385a:	d11c                	sw	a5,32(a0)
}
ffffffffc020385c:	0141                	addi	sp,sp,16
ffffffffc020385e:	8082                	ret
    if (le_prev != list)
ffffffffc0203860:	fca690e3          	bne	a3,a0,ffffffffc0203820 <insert_vma_struct+0x26>
ffffffffc0203864:	bfd1                	j	ffffffffc0203838 <insert_vma_struct+0x3e>
ffffffffc0203866:	e7fff0ef          	jal	ra,ffffffffc02036e4 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020386a:	00003697          	auipc	a3,0x3
ffffffffc020386e:	7e668693          	addi	a3,a3,2022 # ffffffffc0207050 <default_pmm_manager+0x7b8>
ffffffffc0203872:	00003617          	auipc	a2,0x3
ffffffffc0203876:	c7660613          	addi	a2,a2,-906 # ffffffffc02064e8 <commands+0x828>
ffffffffc020387a:	0de00593          	li	a1,222
ffffffffc020387e:	00003517          	auipc	a0,0x3
ffffffffc0203882:	7c250513          	addi	a0,a0,1986 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203886:	c09fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020388a:	00004697          	auipc	a3,0x4
ffffffffc020388e:	80668693          	addi	a3,a3,-2042 # ffffffffc0207090 <default_pmm_manager+0x7f8>
ffffffffc0203892:	00003617          	auipc	a2,0x3
ffffffffc0203896:	c5660613          	addi	a2,a2,-938 # ffffffffc02064e8 <commands+0x828>
ffffffffc020389a:	0d700593          	li	a1,215
ffffffffc020389e:	00003517          	auipc	a0,0x3
ffffffffc02038a2:	7a250513          	addi	a0,a0,1954 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc02038a6:	be9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02038aa:	00003697          	auipc	a3,0x3
ffffffffc02038ae:	7c668693          	addi	a3,a3,1990 # ffffffffc0207070 <default_pmm_manager+0x7d8>
ffffffffc02038b2:	00003617          	auipc	a2,0x3
ffffffffc02038b6:	c3660613          	addi	a2,a2,-970 # ffffffffc02064e8 <commands+0x828>
ffffffffc02038ba:	0d600593          	li	a1,214
ffffffffc02038be:	00003517          	auipc	a0,0x3
ffffffffc02038c2:	78250513          	addi	a0,a0,1922 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc02038c6:	bc9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038ca <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02038ca:	591c                	lw	a5,48(a0)
{
ffffffffc02038cc:	1141                	addi	sp,sp,-16
ffffffffc02038ce:	e406                	sd	ra,8(sp)
ffffffffc02038d0:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02038d2:	e78d                	bnez	a5,ffffffffc02038fc <mm_destroy+0x32>
ffffffffc02038d4:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02038d6:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02038d8:	00a40c63          	beq	s0,a0,ffffffffc02038f0 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038dc:	6118                	ld	a4,0(a0)
ffffffffc02038de:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02038e0:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02038e2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038e4:	e398                	sd	a4,0(a5)
ffffffffc02038e6:	cd0fe0ef          	jal	ra,ffffffffc0201db6 <kfree>
    return listelm->next;
ffffffffc02038ea:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02038ec:	fea418e3          	bne	s0,a0,ffffffffc02038dc <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02038f0:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038f2:	6402                	ld	s0,0(sp)
ffffffffc02038f4:	60a2                	ld	ra,8(sp)
ffffffffc02038f6:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038f8:	cbefe06f          	j	ffffffffc0201db6 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038fc:	00003697          	auipc	a3,0x3
ffffffffc0203900:	7b468693          	addi	a3,a3,1972 # ffffffffc02070b0 <default_pmm_manager+0x818>
ffffffffc0203904:	00003617          	auipc	a2,0x3
ffffffffc0203908:	be460613          	addi	a2,a2,-1052 # ffffffffc02064e8 <commands+0x828>
ffffffffc020390c:	10200593          	li	a1,258
ffffffffc0203910:	00003517          	auipc	a0,0x3
ffffffffc0203914:	73050513          	addi	a0,a0,1840 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203918:	b77fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020391c <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020391c:	7139                	addi	sp,sp,-64
ffffffffc020391e:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203920:	6405                	lui	s0,0x1
ffffffffc0203922:	147d                	addi	s0,s0,-1
ffffffffc0203924:	77fd                	lui	a5,0xfffff
ffffffffc0203926:	9622                	add	a2,a2,s0
ffffffffc0203928:	962e                	add	a2,a2,a1
{
ffffffffc020392a:	f426                	sd	s1,40(sp)
ffffffffc020392c:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020392e:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203932:	f04a                	sd	s2,32(sp)
ffffffffc0203934:	ec4e                	sd	s3,24(sp)
ffffffffc0203936:	e852                	sd	s4,16(sp)
ffffffffc0203938:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020393a:	002005b7          	lui	a1,0x200
ffffffffc020393e:	00f67433          	and	s0,a2,a5
ffffffffc0203942:	06b4e363          	bltu	s1,a1,ffffffffc02039a8 <mm_map+0x8c>
ffffffffc0203946:	0684f163          	bgeu	s1,s0,ffffffffc02039a8 <mm_map+0x8c>
ffffffffc020394a:	4785                	li	a5,1
ffffffffc020394c:	07fe                	slli	a5,a5,0x1f
ffffffffc020394e:	0487ed63          	bltu	a5,s0,ffffffffc02039a8 <mm_map+0x8c>
ffffffffc0203952:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203954:	cd21                	beqz	a0,ffffffffc02039ac <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203956:	85a6                	mv	a1,s1
ffffffffc0203958:	8ab6                	mv	s5,a3
ffffffffc020395a:	8a3a                	mv	s4,a4
ffffffffc020395c:	dddff0ef          	jal	ra,ffffffffc0203738 <find_vma>
ffffffffc0203960:	c501                	beqz	a0,ffffffffc0203968 <mm_map+0x4c>
ffffffffc0203962:	651c                	ld	a5,8(a0)
ffffffffc0203964:	0487e263          	bltu	a5,s0,ffffffffc02039a8 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203968:	03000513          	li	a0,48
ffffffffc020396c:	b9afe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203970:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203972:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203974:	02090163          	beqz	s2,ffffffffc0203996 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203978:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020397a:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020397e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203982:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203986:	85ca                	mv	a1,s2
ffffffffc0203988:	e73ff0ef          	jal	ra,ffffffffc02037fa <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc020398c:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc020398e:	000a0463          	beqz	s4,ffffffffc0203996 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203992:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>

out:
    return ret;
}
ffffffffc0203996:	70e2                	ld	ra,56(sp)
ffffffffc0203998:	7442                	ld	s0,48(sp)
ffffffffc020399a:	74a2                	ld	s1,40(sp)
ffffffffc020399c:	7902                	ld	s2,32(sp)
ffffffffc020399e:	69e2                	ld	s3,24(sp)
ffffffffc02039a0:	6a42                	ld	s4,16(sp)
ffffffffc02039a2:	6aa2                	ld	s5,8(sp)
ffffffffc02039a4:	6121                	addi	sp,sp,64
ffffffffc02039a6:	8082                	ret
        return -E_INVAL;
ffffffffc02039a8:	5575                	li	a0,-3
ffffffffc02039aa:	b7f5                	j	ffffffffc0203996 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02039ac:	00003697          	auipc	a3,0x3
ffffffffc02039b0:	71c68693          	addi	a3,a3,1820 # ffffffffc02070c8 <default_pmm_manager+0x830>
ffffffffc02039b4:	00003617          	auipc	a2,0x3
ffffffffc02039b8:	b3460613          	addi	a2,a2,-1228 # ffffffffc02064e8 <commands+0x828>
ffffffffc02039bc:	11700593          	li	a1,279
ffffffffc02039c0:	00003517          	auipc	a0,0x3
ffffffffc02039c4:	68050513          	addi	a0,a0,1664 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc02039c8:	ac7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039cc <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02039cc:	7139                	addi	sp,sp,-64
ffffffffc02039ce:	fc06                	sd	ra,56(sp)
ffffffffc02039d0:	f822                	sd	s0,48(sp)
ffffffffc02039d2:	f426                	sd	s1,40(sp)
ffffffffc02039d4:	f04a                	sd	s2,32(sp)
ffffffffc02039d6:	ec4e                	sd	s3,24(sp)
ffffffffc02039d8:	e852                	sd	s4,16(sp)
ffffffffc02039da:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039dc:	c52d                	beqz	a0,ffffffffc0203a46 <dup_mmap+0x7a>
ffffffffc02039de:	892a                	mv	s2,a0
ffffffffc02039e0:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039e2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039e4:	e595                	bnez	a1,ffffffffc0203a10 <dup_mmap+0x44>
ffffffffc02039e6:	a085                	j	ffffffffc0203a46 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039e8:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02039ea:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ed8>
        vma->vm_end = vm_end;
ffffffffc02039ee:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02039f2:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02039f6:	e05ff0ef          	jal	ra,ffffffffc02037fa <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039fa:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc02039fe:	fe843603          	ld	a2,-24(s0)
ffffffffc0203a02:	6c8c                	ld	a1,24(s1)
ffffffffc0203a04:	01893503          	ld	a0,24(s2)
ffffffffc0203a08:	4701                	li	a4,0
ffffffffc0203a0a:	9b9ff0ef          	jal	ra,ffffffffc02033c2 <copy_range>
ffffffffc0203a0e:	e105                	bnez	a0,ffffffffc0203a2e <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203a10:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203a12:	02848863          	beq	s1,s0,ffffffffc0203a42 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a16:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203a1a:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203a1e:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203a22:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a26:	ae0fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203a2a:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203a2c:	fd55                	bnez	a0,ffffffffc02039e8 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203a2e:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203a30:	70e2                	ld	ra,56(sp)
ffffffffc0203a32:	7442                	ld	s0,48(sp)
ffffffffc0203a34:	74a2                	ld	s1,40(sp)
ffffffffc0203a36:	7902                	ld	s2,32(sp)
ffffffffc0203a38:	69e2                	ld	s3,24(sp)
ffffffffc0203a3a:	6a42                	ld	s4,16(sp)
ffffffffc0203a3c:	6aa2                	ld	s5,8(sp)
ffffffffc0203a3e:	6121                	addi	sp,sp,64
ffffffffc0203a40:	8082                	ret
    return 0;
ffffffffc0203a42:	4501                	li	a0,0
ffffffffc0203a44:	b7f5                	j	ffffffffc0203a30 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203a46:	00003697          	auipc	a3,0x3
ffffffffc0203a4a:	69268693          	addi	a3,a3,1682 # ffffffffc02070d8 <default_pmm_manager+0x840>
ffffffffc0203a4e:	00003617          	auipc	a2,0x3
ffffffffc0203a52:	a9a60613          	addi	a2,a2,-1382 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203a56:	13300593          	li	a1,307
ffffffffc0203a5a:	00003517          	auipc	a0,0x3
ffffffffc0203a5e:	5e650513          	addi	a0,a0,1510 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203a62:	a2dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a66 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a66:	1101                	addi	sp,sp,-32
ffffffffc0203a68:	ec06                	sd	ra,24(sp)
ffffffffc0203a6a:	e822                	sd	s0,16(sp)
ffffffffc0203a6c:	e426                	sd	s1,8(sp)
ffffffffc0203a6e:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a70:	c531                	beqz	a0,ffffffffc0203abc <exit_mmap+0x56>
ffffffffc0203a72:	591c                	lw	a5,48(a0)
ffffffffc0203a74:	84aa                	mv	s1,a0
ffffffffc0203a76:	e3b9                	bnez	a5,ffffffffc0203abc <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a78:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a7a:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a7e:	02850663          	beq	a0,s0,ffffffffc0203aaa <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a82:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a86:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a8a:	854a                	mv	a0,s2
ffffffffc0203a8c:	f8cfe0ef          	jal	ra,ffffffffc0202218 <unmap_range>
ffffffffc0203a90:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a92:	fe8498e3          	bne	s1,s0,ffffffffc0203a82 <exit_mmap+0x1c>
ffffffffc0203a96:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a98:	00848c63          	beq	s1,s0,ffffffffc0203ab0 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a9c:	ff043603          	ld	a2,-16(s0)
ffffffffc0203aa0:	fe843583          	ld	a1,-24(s0)
ffffffffc0203aa4:	854a                	mv	a0,s2
ffffffffc0203aa6:	8b9fe0ef          	jal	ra,ffffffffc020235e <exit_range>
ffffffffc0203aaa:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203aac:	fe8498e3          	bne	s1,s0,ffffffffc0203a9c <exit_mmap+0x36>
    }
}
ffffffffc0203ab0:	60e2                	ld	ra,24(sp)
ffffffffc0203ab2:	6442                	ld	s0,16(sp)
ffffffffc0203ab4:	64a2                	ld	s1,8(sp)
ffffffffc0203ab6:	6902                	ld	s2,0(sp)
ffffffffc0203ab8:	6105                	addi	sp,sp,32
ffffffffc0203aba:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203abc:	00003697          	auipc	a3,0x3
ffffffffc0203ac0:	63c68693          	addi	a3,a3,1596 # ffffffffc02070f8 <default_pmm_manager+0x860>
ffffffffc0203ac4:	00003617          	auipc	a2,0x3
ffffffffc0203ac8:	a2460613          	addi	a2,a2,-1500 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203acc:	14c00593          	li	a1,332
ffffffffc0203ad0:	00003517          	auipc	a0,0x3
ffffffffc0203ad4:	57050513          	addi	a0,a0,1392 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203ad8:	9b7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203adc <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203adc:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ade:	04000513          	li	a0,64
{
ffffffffc0203ae2:	fc06                	sd	ra,56(sp)
ffffffffc0203ae4:	f822                	sd	s0,48(sp)
ffffffffc0203ae6:	f426                	sd	s1,40(sp)
ffffffffc0203ae8:	f04a                	sd	s2,32(sp)
ffffffffc0203aea:	ec4e                	sd	s3,24(sp)
ffffffffc0203aec:	e852                	sd	s4,16(sp)
ffffffffc0203aee:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203af0:	a16fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
    if (mm != NULL)
ffffffffc0203af4:	50050d63          	beqz	a0,ffffffffc020400e <vmm_init+0x532>
ffffffffc0203af8:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203afa:	e508                	sd	a0,8(a0)
ffffffffc0203afc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203afe:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203b02:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203b06:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203b0a:	02053423          	sd	zero,40(a0)
ffffffffc0203b0e:	02052823          	sw	zero,48(a0)
ffffffffc0203b12:	02053c23          	sd	zero,56(a0)
ffffffffc0203b16:	03200413          	li	s0,50
ffffffffc0203b1a:	a811                	j	ffffffffc0203b2e <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203b1c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b1e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b20:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203b24:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b26:	8526                	mv	a0,s1
ffffffffc0203b28:	cd3ff0ef          	jal	ra,ffffffffc02037fa <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b2c:	c80d                	beqz	s0,ffffffffc0203b5e <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b2e:	03000513          	li	a0,48
ffffffffc0203b32:	9d4fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203b36:	85aa                	mv	a1,a0
ffffffffc0203b38:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b3c:	f165                	bnez	a0,ffffffffc0203b1c <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203b3e:	00003697          	auipc	a3,0x3
ffffffffc0203b42:	7ea68693          	addi	a3,a3,2026 # ffffffffc0207328 <default_pmm_manager+0xa90>
ffffffffc0203b46:	00003617          	auipc	a2,0x3
ffffffffc0203b4a:	9a260613          	addi	a2,a2,-1630 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203b4e:	19000593          	li	a1,400
ffffffffc0203b52:	00003517          	auipc	a0,0x3
ffffffffc0203b56:	4ee50513          	addi	a0,a0,1262 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203b5a:	935fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203b5e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b62:	1f900913          	li	s2,505
ffffffffc0203b66:	a819                	j	ffffffffc0203b7c <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203b68:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b6a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b6c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b70:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b72:	8526                	mv	a0,s1
ffffffffc0203b74:	c87ff0ef          	jal	ra,ffffffffc02037fa <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b78:	03240a63          	beq	s0,s2,ffffffffc0203bac <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b7c:	03000513          	li	a0,48
ffffffffc0203b80:	986fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203b84:	85aa                	mv	a1,a0
ffffffffc0203b86:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b8a:	fd79                	bnez	a0,ffffffffc0203b68 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203b8c:	00003697          	auipc	a3,0x3
ffffffffc0203b90:	79c68693          	addi	a3,a3,1948 # ffffffffc0207328 <default_pmm_manager+0xa90>
ffffffffc0203b94:	00003617          	auipc	a2,0x3
ffffffffc0203b98:	95460613          	addi	a2,a2,-1708 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203b9c:	19700593          	li	a1,407
ffffffffc0203ba0:	00003517          	auipc	a0,0x3
ffffffffc0203ba4:	4a050513          	addi	a0,a0,1184 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203ba8:	8e7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203bac:	649c                	ld	a5,8(s1)
ffffffffc0203bae:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203bb0:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203bb4:	2cf48563          	beq	s1,a5,ffffffffc0203e7e <vmm_init+0x3a2>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bb8:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd5477c>
ffffffffc0203bbc:	ffe70693          	addi	a3,a4,-2
ffffffffc0203bc0:	20d61f63          	bne	a2,a3,ffffffffc0203dde <vmm_init+0x302>
ffffffffc0203bc4:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203bc8:	20e69b63          	bne	a3,a4,ffffffffc0203dde <vmm_init+0x302>
    for (i = 1; i <= step2; i++)
ffffffffc0203bcc:	0715                	addi	a4,a4,5
ffffffffc0203bce:	679c                	ld	a5,8(a5)
ffffffffc0203bd0:	feb712e3          	bne	a4,a1,ffffffffc0203bb4 <vmm_init+0xd8>
ffffffffc0203bd4:	4a1d                	li	s4,7
ffffffffc0203bd6:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bd8:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203bdc:	85a2                	mv	a1,s0
ffffffffc0203bde:	8526                	mv	a0,s1
ffffffffc0203be0:	b59ff0ef          	jal	ra,ffffffffc0203738 <find_vma>
ffffffffc0203be4:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203be6:	2a050c63          	beqz	a0,ffffffffc0203e9e <vmm_init+0x3c2>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203bea:	00140593          	addi	a1,s0,1
ffffffffc0203bee:	8526                	mv	a0,s1
ffffffffc0203bf0:	b49ff0ef          	jal	ra,ffffffffc0203738 <find_vma>
ffffffffc0203bf4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203bf6:	32050463          	beqz	a0,ffffffffc0203f1e <vmm_init+0x442>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203bfa:	85d2                	mv	a1,s4
ffffffffc0203bfc:	8526                	mv	a0,s1
ffffffffc0203bfe:	b3bff0ef          	jal	ra,ffffffffc0203738 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203c02:	2c051e63          	bnez	a0,ffffffffc0203ede <vmm_init+0x402>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203c06:	00340593          	addi	a1,s0,3
ffffffffc0203c0a:	8526                	mv	a0,s1
ffffffffc0203c0c:	b2dff0ef          	jal	ra,ffffffffc0203738 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203c10:	2a051763          	bnez	a0,ffffffffc0203ebe <vmm_init+0x3e2>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203c14:	00440593          	addi	a1,s0,4
ffffffffc0203c18:	8526                	mv	a0,s1
ffffffffc0203c1a:	b1fff0ef          	jal	ra,ffffffffc0203738 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203c1e:	2e051063          	bnez	a0,ffffffffc0203efe <vmm_init+0x422>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c22:	00893783          	ld	a5,8(s2)
ffffffffc0203c26:	1c879c63          	bne	a5,s0,ffffffffc0203dfe <vmm_init+0x322>
ffffffffc0203c2a:	01093783          	ld	a5,16(s2)
ffffffffc0203c2e:	1cfa1863          	bne	s4,a5,ffffffffc0203dfe <vmm_init+0x322>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c32:	0089b783          	ld	a5,8(s3)
ffffffffc0203c36:	1e879463          	bne	a5,s0,ffffffffc0203e1e <vmm_init+0x342>
ffffffffc0203c3a:	0109b783          	ld	a5,16(s3)
ffffffffc0203c3e:	1efa1063          	bne	s4,a5,ffffffffc0203e1e <vmm_init+0x342>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203c42:	0415                	addi	s0,s0,5
ffffffffc0203c44:	0a15                	addi	s4,s4,5
ffffffffc0203c46:	f9541be3          	bne	s0,s5,ffffffffc0203bdc <vmm_init+0x100>
ffffffffc0203c4a:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203c4c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203c4e:	85a2                	mv	a1,s0
ffffffffc0203c50:	8526                	mv	a0,s1
ffffffffc0203c52:	ae7ff0ef          	jal	ra,ffffffffc0203738 <find_vma>
ffffffffc0203c56:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203c5a:	c90d                	beqz	a0,ffffffffc0203c8c <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203c5c:	6914                	ld	a3,16(a0)
ffffffffc0203c5e:	6510                	ld	a2,8(a0)
ffffffffc0203c60:	00003517          	auipc	a0,0x3
ffffffffc0203c64:	5b850513          	addi	a0,a0,1464 # ffffffffc0207218 <default_pmm_manager+0x980>
ffffffffc0203c68:	d2cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203c6c:	00003697          	auipc	a3,0x3
ffffffffc0203c70:	5d468693          	addi	a3,a3,1492 # ffffffffc0207240 <default_pmm_manager+0x9a8>
ffffffffc0203c74:	00003617          	auipc	a2,0x3
ffffffffc0203c78:	87460613          	addi	a2,a2,-1932 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203c7c:	1bd00593          	li	a1,445
ffffffffc0203c80:	00003517          	auipc	a0,0x3
ffffffffc0203c84:	3c050513          	addi	a0,a0,960 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203c88:	807fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203c8c:	147d                	addi	s0,s0,-1
ffffffffc0203c8e:	fd2410e3          	bne	s0,s2,ffffffffc0203c4e <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203c92:	8526                	mv	a0,s1
ffffffffc0203c94:	c37ff0ef          	jal	ra,ffffffffc02038ca <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203c98:	00003517          	auipc	a0,0x3
ffffffffc0203c9c:	5c050513          	addi	a0,a0,1472 # ffffffffc0207258 <default_pmm_manager+0x9c0>
ffffffffc0203ca0:	cf4fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ca4:	04000513          	li	a0,64
ffffffffc0203ca8:	85efe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203cac:	84aa                	mv	s1,a0
    if (mm != NULL)
ffffffffc0203cae:	1a050863          	beqz	a0,ffffffffc0203e5e <vmm_init+0x382>
    elm->prev = elm->next = elm;
ffffffffc0203cb2:	e508                	sd	a0,8(a0)
ffffffffc0203cb4:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203cb6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203cba:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203cbe:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203cc2:	02053423          	sd	zero,40(a0)
ffffffffc0203cc6:	02052823          	sw	zero,48(a0)
ffffffffc0203cca:	02053c23          	sd	zero,56(a0)
    if ((page = alloc_page()) == NULL)
ffffffffc0203cce:	4505                	li	a0,1
ffffffffc0203cd0:	a14fe0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0203cd4:	26050563          	beqz	a0,ffffffffc0203f3e <vmm_init+0x462>
    return page - pages + nbase;
ffffffffc0203cd8:	000a7717          	auipc	a4,0xa7
ffffffffc0203cdc:	b5873703          	ld	a4,-1192(a4) # ffffffffc02aa830 <pages>
ffffffffc0203ce0:	40e50733          	sub	a4,a0,a4
ffffffffc0203ce4:	00004797          	auipc	a5,0x4
ffffffffc0203ce8:	f547b783          	ld	a5,-172(a5) # ffffffffc0207c38 <nbase>
ffffffffc0203cec:	8719                	srai	a4,a4,0x6
ffffffffc0203cee:	973e                	add	a4,a4,a5
    return KADDR(page2pa(page));
ffffffffc0203cf0:	00c45793          	srli	a5,s0,0xc
ffffffffc0203cf4:	8ff9                	and	a5,a5,a4
ffffffffc0203cf6:	000a7617          	auipc	a2,0xa7
ffffffffc0203cfa:	b3263603          	ld	a2,-1230(a2) # ffffffffc02aa828 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cfe:	00c71693          	slli	a3,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0203d02:	28c7fa63          	bgeu	a5,a2,ffffffffc0203f96 <vmm_init+0x4ba>
ffffffffc0203d06:	000a7417          	auipc	s0,0xa7
ffffffffc0203d0a:	b3a43403          	ld	s0,-1222(s0) # ffffffffc02aa840 <va_pa_offset>
ffffffffc0203d0e:	9436                	add	s0,s0,a3
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0203d10:	6605                	lui	a2,0x1
ffffffffc0203d12:	000a7597          	auipc	a1,0xa7
ffffffffc0203d16:	b0e5b583          	ld	a1,-1266(a1) # ffffffffc02aa820 <boot_pgdir_va>
ffffffffc0203d1a:	8522                	mv	a0,s0
ffffffffc0203d1c:	525010ef          	jal	ra,ffffffffc0205a40 <memcpy>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d20:	03000513          	li	a0,48
    mm->pgdir = pgdir;
ffffffffc0203d24:	ec80                	sd	s0,24(s1)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d26:	fe1fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203d2a:	842a                	mv	s0,a0
    if (vma != NULL)
ffffffffc0203d2c:	10050963          	beqz	a0,ffffffffc0203e3e <vmm_init+0x362>
        vma->vm_end = vm_end;
ffffffffc0203d30:	002007b7          	lui	a5,0x200
ffffffffc0203d34:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0203d36:	4789                	li	a5,2
    }

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203d38:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203d3a:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0203d3e:	8526                	mv	a0,s1
        vma->vm_flags = vm_flags;
ffffffffc0203d40:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0203d42:	ab9ff0ef          	jal	ra,ffffffffc02037fa <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203d46:	10000593          	li	a1,256
ffffffffc0203d4a:	8526                	mv	a0,s1
ffffffffc0203d4c:	9edff0ef          	jal	ra,ffffffffc0203738 <find_vma>
ffffffffc0203d50:	2ca41f63          	bne	s0,a0,ffffffffc020402e <vmm_init+0x552>

    int ret = 0;
    ret = do_pgfault(mm, 0, addr);
ffffffffc0203d54:	10000613          	li	a2,256
ffffffffc0203d58:	4581                	li	a1,0
ffffffffc0203d5a:	8526                	mv	a0,s1
ffffffffc0203d5c:	a1dff0ef          	jal	ra,ffffffffc0203778 <do_pgfault>
    assert(ret == 0);
ffffffffc0203d60:	30051763          	bnez	a0,ffffffffc020406e <vmm_init+0x592>

    // check the correctness of page table
    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203d64:	6c88                	ld	a0,24(s1)
ffffffffc0203d66:	4601                	li	a2,0
ffffffffc0203d68:	10000593          	li	a1,256
ffffffffc0203d6c:	a30fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    assert(ptep != NULL);
ffffffffc0203d70:	2c050f63          	beqz	a0,ffffffffc020404e <vmm_init+0x572>
    assert((*ptep & PTE_U) != 0);
ffffffffc0203d74:	611c                	ld	a5,0(a0)
ffffffffc0203d76:	0107f713          	andi	a4,a5,16
ffffffffc0203d7a:	26070a63          	beqz	a4,ffffffffc0203fee <vmm_init+0x512>
    assert((*ptep & PTE_W) != 0);
ffffffffc0203d7e:	8b91                	andi	a5,a5,4
ffffffffc0203d80:	24078763          	beqz	a5,ffffffffc0203fce <vmm_init+0x4f2>

    addr = 0x1000;
    ret = do_pgfault(mm, 0, addr);
ffffffffc0203d84:	6605                	lui	a2,0x1
ffffffffc0203d86:	4581                	li	a1,0
ffffffffc0203d88:	8526                	mv	a0,s1
ffffffffc0203d8a:	9efff0ef          	jal	ra,ffffffffc0203778 <do_pgfault>
    assert(ret == 0);
ffffffffc0203d8e:	22051063          	bnez	a0,ffffffffc0203fae <vmm_init+0x4d2>

    ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203d92:	6c88                	ld	a0,24(s1)
ffffffffc0203d94:	4601                	li	a2,0
ffffffffc0203d96:	6585                	lui	a1,0x1
ffffffffc0203d98:	a04fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    assert(ptep != NULL);
ffffffffc0203d9c:	1a050d63          	beqz	a0,ffffffffc0203f56 <vmm_init+0x47a>
    assert((*ptep & PTE_U) != 0);
ffffffffc0203da0:	611c                	ld	a5,0(a0)
ffffffffc0203da2:	0107f713          	andi	a4,a5,16
ffffffffc0203da6:	1c070863          	beqz	a4,ffffffffc0203f76 <vmm_init+0x49a>
    assert((*ptep & PTE_W) != 0);
ffffffffc0203daa:	8b91                	andi	a5,a5,4
ffffffffc0203dac:	2e078163          	beqz	a5,ffffffffc020408e <vmm_init+0x5b2>

    mm_destroy(mm);
ffffffffc0203db0:	8526                	mv	a0,s1
ffffffffc0203db2:	b19ff0ef          	jal	ra,ffffffffc02038ca <mm_destroy>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203db6:	00003517          	auipc	a0,0x3
ffffffffc0203dba:	53a50513          	addi	a0,a0,1338 # ffffffffc02072f0 <default_pmm_manager+0xa58>
ffffffffc0203dbe:	bd6fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203dc2:	7442                	ld	s0,48(sp)
ffffffffc0203dc4:	70e2                	ld	ra,56(sp)
ffffffffc0203dc6:	74a2                	ld	s1,40(sp)
ffffffffc0203dc8:	7902                	ld	s2,32(sp)
ffffffffc0203dca:	69e2                	ld	s3,24(sp)
ffffffffc0203dcc:	6a42                	ld	s4,16(sp)
ffffffffc0203dce:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dd0:	00003517          	auipc	a0,0x3
ffffffffc0203dd4:	54050513          	addi	a0,a0,1344 # ffffffffc0207310 <default_pmm_manager+0xa78>
}
ffffffffc0203dd8:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dda:	bbafc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203dde:	00003697          	auipc	a3,0x3
ffffffffc0203de2:	35268693          	addi	a3,a3,850 # ffffffffc0207130 <default_pmm_manager+0x898>
ffffffffc0203de6:	00002617          	auipc	a2,0x2
ffffffffc0203dea:	70260613          	addi	a2,a2,1794 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203dee:	1a100593          	li	a1,417
ffffffffc0203df2:	00003517          	auipc	a0,0x3
ffffffffc0203df6:	24e50513          	addi	a0,a0,590 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203dfa:	e94fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203dfe:	00003697          	auipc	a3,0x3
ffffffffc0203e02:	3ba68693          	addi	a3,a3,954 # ffffffffc02071b8 <default_pmm_manager+0x920>
ffffffffc0203e06:	00002617          	auipc	a2,0x2
ffffffffc0203e0a:	6e260613          	addi	a2,a2,1762 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203e0e:	1b200593          	li	a1,434
ffffffffc0203e12:	00003517          	auipc	a0,0x3
ffffffffc0203e16:	22e50513          	addi	a0,a0,558 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203e1a:	e74fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203e1e:	00003697          	auipc	a3,0x3
ffffffffc0203e22:	3ca68693          	addi	a3,a3,970 # ffffffffc02071e8 <default_pmm_manager+0x950>
ffffffffc0203e26:	00002617          	auipc	a2,0x2
ffffffffc0203e2a:	6c260613          	addi	a2,a2,1730 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203e2e:	1b300593          	li	a1,435
ffffffffc0203e32:	00003517          	auipc	a0,0x3
ffffffffc0203e36:	20e50513          	addi	a0,a0,526 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203e3a:	e54fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(vma != NULL);
ffffffffc0203e3e:	00003697          	auipc	a3,0x3
ffffffffc0203e42:	4ea68693          	addi	a3,a3,1258 # ffffffffc0207328 <default_pmm_manager+0xa90>
ffffffffc0203e46:	00002617          	auipc	a2,0x2
ffffffffc0203e4a:	6a260613          	addi	a2,a2,1698 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203e4e:	1d500593          	li	a1,469
ffffffffc0203e52:	00003517          	auipc	a0,0x3
ffffffffc0203e56:	1ee50513          	addi	a0,a0,494 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203e5a:	e34fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203e5e:	00003697          	auipc	a3,0x3
ffffffffc0203e62:	26a68693          	addi	a3,a3,618 # ffffffffc02070c8 <default_pmm_manager+0x830>
ffffffffc0203e66:	00002617          	auipc	a2,0x2
ffffffffc0203e6a:	68260613          	addi	a2,a2,1666 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203e6e:	1cc00593          	li	a1,460
ffffffffc0203e72:	00003517          	auipc	a0,0x3
ffffffffc0203e76:	1ce50513          	addi	a0,a0,462 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203e7a:	e14fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203e7e:	00003697          	auipc	a3,0x3
ffffffffc0203e82:	29a68693          	addi	a3,a3,666 # ffffffffc0207118 <default_pmm_manager+0x880>
ffffffffc0203e86:	00002617          	auipc	a2,0x2
ffffffffc0203e8a:	66260613          	addi	a2,a2,1634 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203e8e:	19f00593          	li	a1,415
ffffffffc0203e92:	00003517          	auipc	a0,0x3
ffffffffc0203e96:	1ae50513          	addi	a0,a0,430 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203e9a:	df4fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203e9e:	00003697          	auipc	a3,0x3
ffffffffc0203ea2:	2ca68693          	addi	a3,a3,714 # ffffffffc0207168 <default_pmm_manager+0x8d0>
ffffffffc0203ea6:	00002617          	auipc	a2,0x2
ffffffffc0203eaa:	64260613          	addi	a2,a2,1602 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203eae:	1a800593          	li	a1,424
ffffffffc0203eb2:	00003517          	auipc	a0,0x3
ffffffffc0203eb6:	18e50513          	addi	a0,a0,398 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203eba:	dd4fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203ebe:	00003697          	auipc	a3,0x3
ffffffffc0203ec2:	2da68693          	addi	a3,a3,730 # ffffffffc0207198 <default_pmm_manager+0x900>
ffffffffc0203ec6:	00002617          	auipc	a2,0x2
ffffffffc0203eca:	62260613          	addi	a2,a2,1570 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203ece:	1ae00593          	li	a1,430
ffffffffc0203ed2:	00003517          	auipc	a0,0x3
ffffffffc0203ed6:	16e50513          	addi	a0,a0,366 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203eda:	db4fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203ede:	00003697          	auipc	a3,0x3
ffffffffc0203ee2:	2aa68693          	addi	a3,a3,682 # ffffffffc0207188 <default_pmm_manager+0x8f0>
ffffffffc0203ee6:	00002617          	auipc	a2,0x2
ffffffffc0203eea:	60260613          	addi	a2,a2,1538 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203eee:	1ac00593          	li	a1,428
ffffffffc0203ef2:	00003517          	auipc	a0,0x3
ffffffffc0203ef6:	14e50513          	addi	a0,a0,334 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203efa:	d94fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203efe:	00003697          	auipc	a3,0x3
ffffffffc0203f02:	2aa68693          	addi	a3,a3,682 # ffffffffc02071a8 <default_pmm_manager+0x910>
ffffffffc0203f06:	00002617          	auipc	a2,0x2
ffffffffc0203f0a:	5e260613          	addi	a2,a2,1506 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203f0e:	1b000593          	li	a1,432
ffffffffc0203f12:	00003517          	auipc	a0,0x3
ffffffffc0203f16:	12e50513          	addi	a0,a0,302 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203f1a:	d74fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203f1e:	00003697          	auipc	a3,0x3
ffffffffc0203f22:	25a68693          	addi	a3,a3,602 # ffffffffc0207178 <default_pmm_manager+0x8e0>
ffffffffc0203f26:	00002617          	auipc	a2,0x2
ffffffffc0203f2a:	5c260613          	addi	a2,a2,1474 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203f2e:	1aa00593          	li	a1,426
ffffffffc0203f32:	00003517          	auipc	a0,0x3
ffffffffc0203f36:	10e50513          	addi	a0,a0,270 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203f3a:	d54fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("setup_pgdir failed\n");
ffffffffc0203f3e:	00003617          	auipc	a2,0x3
ffffffffc0203f42:	33a60613          	addi	a2,a2,826 # ffffffffc0207278 <default_pmm_manager+0x9e0>
ffffffffc0203f46:	1d100593          	li	a1,465
ffffffffc0203f4a:	00003517          	auipc	a0,0x3
ffffffffc0203f4e:	0f650513          	addi	a0,a0,246 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203f52:	d3cfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ptep != NULL);
ffffffffc0203f56:	00003697          	auipc	a3,0x3
ffffffffc0203f5a:	35a68693          	addi	a3,a3,858 # ffffffffc02072b0 <default_pmm_manager+0xa18>
ffffffffc0203f5e:	00002617          	auipc	a2,0x2
ffffffffc0203f62:	58a60613          	addi	a2,a2,1418 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203f66:	1eb00593          	li	a1,491
ffffffffc0203f6a:	00003517          	auipc	a0,0x3
ffffffffc0203f6e:	0d650513          	addi	a0,a0,214 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203f72:	d1cfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) != 0);
ffffffffc0203f76:	00003697          	auipc	a3,0x3
ffffffffc0203f7a:	34a68693          	addi	a3,a3,842 # ffffffffc02072c0 <default_pmm_manager+0xa28>
ffffffffc0203f7e:	00002617          	auipc	a2,0x2
ffffffffc0203f82:	56a60613          	addi	a2,a2,1386 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203f86:	1ec00593          	li	a1,492
ffffffffc0203f8a:	00003517          	auipc	a0,0x3
ffffffffc0203f8e:	0b650513          	addi	a0,a0,182 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203f92:	cfcfc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203f96:	00003617          	auipc	a2,0x3
ffffffffc0203f9a:	93a60613          	addi	a2,a2,-1734 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0203f9e:	07100593          	li	a1,113
ffffffffc0203fa2:	00003517          	auipc	a0,0x3
ffffffffc0203fa6:	95650513          	addi	a0,a0,-1706 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0203faa:	ce4fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ret == 0);
ffffffffc0203fae:	00003697          	auipc	a3,0x3
ffffffffc0203fb2:	04a68693          	addi	a3,a3,74 # ffffffffc0206ff8 <default_pmm_manager+0x760>
ffffffffc0203fb6:	00002617          	auipc	a2,0x2
ffffffffc0203fba:	53260613          	addi	a2,a2,1330 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203fbe:	1e800593          	li	a1,488
ffffffffc0203fc2:	00003517          	auipc	a0,0x3
ffffffffc0203fc6:	07e50513          	addi	a0,a0,126 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203fca:	cc4fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_W) != 0);
ffffffffc0203fce:	00003697          	auipc	a3,0x3
ffffffffc0203fd2:	30a68693          	addi	a3,a3,778 # ffffffffc02072d8 <default_pmm_manager+0xa40>
ffffffffc0203fd6:	00002617          	auipc	a2,0x2
ffffffffc0203fda:	51260613          	addi	a2,a2,1298 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203fde:	1e400593          	li	a1,484
ffffffffc0203fe2:	00003517          	auipc	a0,0x3
ffffffffc0203fe6:	05e50513          	addi	a0,a0,94 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc0203fea:	ca4fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) != 0);
ffffffffc0203fee:	00003697          	auipc	a3,0x3
ffffffffc0203ff2:	2d268693          	addi	a3,a3,722 # ffffffffc02072c0 <default_pmm_manager+0xa28>
ffffffffc0203ff6:	00002617          	auipc	a2,0x2
ffffffffc0203ffa:	4f260613          	addi	a2,a2,1266 # ffffffffc02064e8 <commands+0x828>
ffffffffc0203ffe:	1e300593          	li	a1,483
ffffffffc0204002:	00003517          	auipc	a0,0x3
ffffffffc0204006:	03e50513          	addi	a0,a0,62 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc020400a:	c84fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc020400e:	00003697          	auipc	a3,0x3
ffffffffc0204012:	0ba68693          	addi	a3,a3,186 # ffffffffc02070c8 <default_pmm_manager+0x830>
ffffffffc0204016:	00002617          	auipc	a2,0x2
ffffffffc020401a:	4d260613          	addi	a2,a2,1234 # ffffffffc02064e8 <commands+0x828>
ffffffffc020401e:	18800593          	li	a1,392
ffffffffc0204022:	00003517          	auipc	a0,0x3
ffffffffc0204026:	01e50513          	addi	a0,a0,30 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc020402a:	c64fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020402e:	00003697          	auipc	a3,0x3
ffffffffc0204032:	26268693          	addi	a3,a3,610 # ffffffffc0207290 <default_pmm_manager+0x9f8>
ffffffffc0204036:	00002617          	auipc	a2,0x2
ffffffffc020403a:	4b260613          	addi	a2,a2,1202 # ffffffffc02064e8 <commands+0x828>
ffffffffc020403e:	1da00593          	li	a1,474
ffffffffc0204042:	00003517          	auipc	a0,0x3
ffffffffc0204046:	ffe50513          	addi	a0,a0,-2 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc020404a:	c44fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ptep != NULL);
ffffffffc020404e:	00003697          	auipc	a3,0x3
ffffffffc0204052:	26268693          	addi	a3,a3,610 # ffffffffc02072b0 <default_pmm_manager+0xa18>
ffffffffc0204056:	00002617          	auipc	a2,0x2
ffffffffc020405a:	49260613          	addi	a2,a2,1170 # ffffffffc02064e8 <commands+0x828>
ffffffffc020405e:	1e200593          	li	a1,482
ffffffffc0204062:	00003517          	auipc	a0,0x3
ffffffffc0204066:	fde50513          	addi	a0,a0,-34 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc020406a:	c24fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ret == 0);
ffffffffc020406e:	00003697          	auipc	a3,0x3
ffffffffc0204072:	f8a68693          	addi	a3,a3,-118 # ffffffffc0206ff8 <default_pmm_manager+0x760>
ffffffffc0204076:	00002617          	auipc	a2,0x2
ffffffffc020407a:	47260613          	addi	a2,a2,1138 # ffffffffc02064e8 <commands+0x828>
ffffffffc020407e:	1de00593          	li	a1,478
ffffffffc0204082:	00003517          	auipc	a0,0x3
ffffffffc0204086:	fbe50513          	addi	a0,a0,-66 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc020408a:	c04fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_W) != 0);
ffffffffc020408e:	00003697          	auipc	a3,0x3
ffffffffc0204092:	24a68693          	addi	a3,a3,586 # ffffffffc02072d8 <default_pmm_manager+0xa40>
ffffffffc0204096:	00002617          	auipc	a2,0x2
ffffffffc020409a:	45260613          	addi	a2,a2,1106 # ffffffffc02064e8 <commands+0x828>
ffffffffc020409e:	1ed00593          	li	a1,493
ffffffffc02040a2:	00003517          	auipc	a0,0x3
ffffffffc02040a6:	f9e50513          	addi	a0,a0,-98 # ffffffffc0207040 <default_pmm_manager+0x7a8>
ffffffffc02040aa:	be4fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040ae <user_mem_check>:
}

bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc02040ae:	7179                	addi	sp,sp,-48
ffffffffc02040b0:	f022                	sd	s0,32(sp)
ffffffffc02040b2:	f406                	sd	ra,40(sp)
ffffffffc02040b4:	ec26                	sd	s1,24(sp)
ffffffffc02040b6:	e84a                	sd	s2,16(sp)
ffffffffc02040b8:	e44e                	sd	s3,8(sp)
ffffffffc02040ba:	e052                	sd	s4,0(sp)
ffffffffc02040bc:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc02040be:	c135                	beqz	a0,ffffffffc0204122 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc02040c0:	002007b7          	lui	a5,0x200
ffffffffc02040c4:	04f5e663          	bltu	a1,a5,ffffffffc0204110 <user_mem_check+0x62>
ffffffffc02040c8:	00c584b3          	add	s1,a1,a2
ffffffffc02040cc:	0495f263          	bgeu	a1,s1,ffffffffc0204110 <user_mem_check+0x62>
ffffffffc02040d0:	4785                	li	a5,1
ffffffffc02040d2:	07fe                	slli	a5,a5,0x1f
ffffffffc02040d4:	0297ee63          	bltu	a5,s1,ffffffffc0204110 <user_mem_check+0x62>
ffffffffc02040d8:	892a                	mv	s2,a0
ffffffffc02040da:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc02040dc:	6a05                	lui	s4,0x1
ffffffffc02040de:	a821                	j	ffffffffc02040f6 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc02040e0:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc02040e4:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc02040e6:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc02040e8:	c685                	beqz	a3,ffffffffc0204110 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc02040ea:	c399                	beqz	a5,ffffffffc02040f0 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc02040ec:	02e46263          	bltu	s0,a4,ffffffffc0204110 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc02040f0:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc02040f2:	04947663          	bgeu	s0,s1,ffffffffc020413e <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc02040f6:	85a2                	mv	a1,s0
ffffffffc02040f8:	854a                	mv	a0,s2
ffffffffc02040fa:	e3eff0ef          	jal	ra,ffffffffc0203738 <find_vma>
ffffffffc02040fe:	c909                	beqz	a0,ffffffffc0204110 <user_mem_check+0x62>
ffffffffc0204100:	6518                	ld	a4,8(a0)
ffffffffc0204102:	00e46763          	bltu	s0,a4,ffffffffc0204110 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204106:	4d1c                	lw	a5,24(a0)
ffffffffc0204108:	fc099ce3          	bnez	s3,ffffffffc02040e0 <user_mem_check+0x32>
ffffffffc020410c:	8b85                	andi	a5,a5,1
ffffffffc020410e:	f3ed                	bnez	a5,ffffffffc02040f0 <user_mem_check+0x42>
            return 0;
ffffffffc0204110:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204112:	70a2                	ld	ra,40(sp)
ffffffffc0204114:	7402                	ld	s0,32(sp)
ffffffffc0204116:	64e2                	ld	s1,24(sp)
ffffffffc0204118:	6942                	ld	s2,16(sp)
ffffffffc020411a:	69a2                	ld	s3,8(sp)
ffffffffc020411c:	6a02                	ld	s4,0(sp)
ffffffffc020411e:	6145                	addi	sp,sp,48
ffffffffc0204120:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204122:	c02007b7          	lui	a5,0xc0200
ffffffffc0204126:	4501                	li	a0,0
ffffffffc0204128:	fef5e5e3          	bltu	a1,a5,ffffffffc0204112 <user_mem_check+0x64>
ffffffffc020412c:	962e                	add	a2,a2,a1
ffffffffc020412e:	fec5f2e3          	bgeu	a1,a2,ffffffffc0204112 <user_mem_check+0x64>
ffffffffc0204132:	c8000537          	lui	a0,0xc8000
ffffffffc0204136:	0505                	addi	a0,a0,1
ffffffffc0204138:	00a63533          	sltu	a0,a2,a0
ffffffffc020413c:	bfd9                	j	ffffffffc0204112 <user_mem_check+0x64>
        return 1;
ffffffffc020413e:	4505                	li	a0,1
ffffffffc0204140:	bfc9                	j	ffffffffc0204112 <user_mem_check+0x64>

ffffffffc0204142 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204142:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204144:	9402                	jalr	s0

	jal do_exit
ffffffffc0204146:	61c000ef          	jal	ra,ffffffffc0204762 <do_exit>

ffffffffc020414a <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020414a:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020414c:	10800513          	li	a0,264
{
ffffffffc0204150:	e022                	sd	s0,0(sp)
ffffffffc0204152:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204154:	bb3fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0204158:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020415a:	c12d                	beqz	a0,ffffffffc02041bc <alloc_proc+0x72>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc020415c:	10800613          	li	a2,264
ffffffffc0204160:	4581                	li	a1,0
ffffffffc0204162:	0cd010ef          	jal	ra,ffffffffc0205a2e <memset>
        
        // 初始化所有字段
        proc->state = PROC_UNINIT;      // 进程状态：未初始化
ffffffffc0204166:	57fd                	li	a5,-1
ffffffffc0204168:	1782                	slli	a5,a5,0x20
        proc->runs = 0;                 // 运行次数：初始为0
        proc->kstack = 0;               // 内核栈：初始为0
        proc->need_resched = 0;         // 不需要重新调度
        proc->parent = NULL;            // 父进程：空
        proc->mm = NULL;                // 内存管理：空（内核线程）
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文清零
ffffffffc020416a:	07000613          	li	a2,112
ffffffffc020416e:	4581                	li	a1,0
        proc->state = PROC_UNINIT;      // 进程状态：未初始化
ffffffffc0204170:	e01c                	sd	a5,0(s0)
        proc->runs = 0;                 // 运行次数：初始为0
ffffffffc0204172:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;               // 内核栈：初始为0
ffffffffc0204176:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;         // 不需要重新调度
ffffffffc020417a:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;            // 父进程：空
ffffffffc020417e:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;                // 内存管理：空（内核线程）
ffffffffc0204182:	02043423          	sd	zero,40(s0)
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文清零
ffffffffc0204186:	03040513          	addi	a0,s0,48
ffffffffc020418a:	0a5010ef          	jal	ra,ffffffffc0205a2e <memset>
        proc->tf = NULL;                // 陷阱帧：空
        proc->pgdir = boot_pgdir_pa;    // 页目录：使用内核页表
ffffffffc020418e:	000a6797          	auipc	a5,0xa6
ffffffffc0204192:	68a7b783          	ld	a5,1674(a5) # ffffffffc02aa818 <boot_pgdir_pa>
        proc->tf = NULL;                // 陷阱帧：空
ffffffffc0204196:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;    // 页目录：使用内核页表
ffffffffc020419a:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                // 进程标志：0
ffffffffc020419c:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);  // 进程名清零
ffffffffc02041a0:	4641                	li	a2,16
ffffffffc02041a2:	4581                	li	a1,0
ffffffffc02041a4:	0b440513          	addi	a0,s0,180
ffffffffc02041a8:	087010ef          	jal	ra,ffffffffc0205a2e <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
ffffffffc02041ac:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc02041b0:	10043023          	sd	zero,256(s0)
ffffffffc02041b4:	0e043c23          	sd	zero,248(s0)
ffffffffc02041b8:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc02041bc:	60a2                	ld	ra,8(sp)
ffffffffc02041be:	8522                	mv	a0,s0
ffffffffc02041c0:	6402                	ld	s0,0(sp)
ffffffffc02041c2:	0141                	addi	sp,sp,16
ffffffffc02041c4:	8082                	ret

ffffffffc02041c6 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02041c6:	000a6797          	auipc	a5,0xa6
ffffffffc02041ca:	68a7b783          	ld	a5,1674(a5) # ffffffffc02aa850 <current>
ffffffffc02041ce:	73c8                	ld	a0,160(a5)
ffffffffc02041d0:	dabfc06f          	j	ffffffffc0200f7a <forkrets>

ffffffffc02041d4 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02041d4:	000a6797          	auipc	a5,0xa6
ffffffffc02041d8:	67c7b783          	ld	a5,1660(a5) # ffffffffc02aa850 <current>
ffffffffc02041dc:	43cc                	lw	a1,4(a5)
{
ffffffffc02041de:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02041e0:	00003617          	auipc	a2,0x3
ffffffffc02041e4:	15860613          	addi	a2,a2,344 # ffffffffc0207338 <default_pmm_manager+0xaa0>
ffffffffc02041e8:	00003517          	auipc	a0,0x3
ffffffffc02041ec:	16050513          	addi	a0,a0,352 # ffffffffc0207348 <default_pmm_manager+0xab0>
{
ffffffffc02041f0:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02041f2:	fa3fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02041f6:	3fe06797          	auipc	a5,0x3fe06
ffffffffc02041fa:	78278793          	addi	a5,a5,1922 # a978 <_binary_obj___user_forktest_out_size>
ffffffffc02041fe:	e43e                	sd	a5,8(sp)
ffffffffc0204200:	00003517          	auipc	a0,0x3
ffffffffc0204204:	13850513          	addi	a0,a0,312 # ffffffffc0207338 <default_pmm_manager+0xaa0>
ffffffffc0204208:	00045797          	auipc	a5,0x45
ffffffffc020420c:	56878793          	addi	a5,a5,1384 # ffffffffc0249770 <_binary_obj___user_forktest_out_start>
ffffffffc0204210:	f03e                	sd	a5,32(sp)
ffffffffc0204212:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204214:	e802                	sd	zero,16(sp)
ffffffffc0204216:	776010ef          	jal	ra,ffffffffc020598c <strlen>
ffffffffc020421a:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc020421c:	4511                	li	a0,4
ffffffffc020421e:	55a2                	lw	a1,40(sp)
ffffffffc0204220:	4662                	lw	a2,24(sp)
ffffffffc0204222:	5682                	lw	a3,32(sp)
ffffffffc0204224:	4722                	lw	a4,8(sp)
ffffffffc0204226:	48a9                	li	a7,10
ffffffffc0204228:	9002                	ebreak
ffffffffc020422a:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc020422c:	65c2                	ld	a1,16(sp)
ffffffffc020422e:	00003517          	auipc	a0,0x3
ffffffffc0204232:	14250513          	addi	a0,a0,322 # ffffffffc0207370 <default_pmm_manager+0xad8>
ffffffffc0204236:	f5ffb0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc020423a:	00003617          	auipc	a2,0x3
ffffffffc020423e:	14660613          	addi	a2,a2,326 # ffffffffc0207380 <default_pmm_manager+0xae8>
ffffffffc0204242:	3ca00593          	li	a1,970
ffffffffc0204246:	00003517          	auipc	a0,0x3
ffffffffc020424a:	15a50513          	addi	a0,a0,346 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc020424e:	a40fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204252 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204252:	6d14                	ld	a3,24(a0)
{
ffffffffc0204254:	1141                	addi	sp,sp,-16
ffffffffc0204256:	e406                	sd	ra,8(sp)
ffffffffc0204258:	c02007b7          	lui	a5,0xc0200
ffffffffc020425c:	02f6ee63          	bltu	a3,a5,ffffffffc0204298 <put_pgdir+0x46>
ffffffffc0204260:	000a6517          	auipc	a0,0xa6
ffffffffc0204264:	5e053503          	ld	a0,1504(a0) # ffffffffc02aa840 <va_pa_offset>
ffffffffc0204268:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc020426a:	82b1                	srli	a3,a3,0xc
ffffffffc020426c:	000a6797          	auipc	a5,0xa6
ffffffffc0204270:	5bc7b783          	ld	a5,1468(a5) # ffffffffc02aa828 <npage>
ffffffffc0204274:	02f6fe63          	bgeu	a3,a5,ffffffffc02042b0 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204278:	00004517          	auipc	a0,0x4
ffffffffc020427c:	9c053503          	ld	a0,-1600(a0) # ffffffffc0207c38 <nbase>
}
ffffffffc0204280:	60a2                	ld	ra,8(sp)
ffffffffc0204282:	8e89                	sub	a3,a3,a0
ffffffffc0204284:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204286:	000a6517          	auipc	a0,0xa6
ffffffffc020428a:	5aa53503          	ld	a0,1450(a0) # ffffffffc02aa830 <pages>
ffffffffc020428e:	4585                	li	a1,1
ffffffffc0204290:	9536                	add	a0,a0,a3
}
ffffffffc0204292:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204294:	c8ffd06f          	j	ffffffffc0201f22 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204298:	00002617          	auipc	a2,0x2
ffffffffc020429c:	6e060613          	addi	a2,a2,1760 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc02042a0:	07700593          	li	a1,119
ffffffffc02042a4:	00002517          	auipc	a0,0x2
ffffffffc02042a8:	65450513          	addi	a0,a0,1620 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02042ac:	9e2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02042b0:	00002617          	auipc	a2,0x2
ffffffffc02042b4:	6f060613          	addi	a2,a2,1776 # ffffffffc02069a0 <default_pmm_manager+0x108>
ffffffffc02042b8:	06900593          	li	a1,105
ffffffffc02042bc:	00002517          	auipc	a0,0x2
ffffffffc02042c0:	63c50513          	addi	a0,a0,1596 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02042c4:	9cafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02042c8 <proc_run>:
{
ffffffffc02042c8:	7179                	addi	sp,sp,-48
ffffffffc02042ca:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02042cc:	000a6917          	auipc	s2,0xa6
ffffffffc02042d0:	58490913          	addi	s2,s2,1412 # ffffffffc02aa850 <current>
{
ffffffffc02042d4:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02042d6:	00093483          	ld	s1,0(s2)
{
ffffffffc02042da:	f406                	sd	ra,40(sp)
ffffffffc02042dc:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc02042de:	02a48863          	beq	s1,a0,ffffffffc020430e <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042e2:	100027f3          	csrr	a5,sstatus
ffffffffc02042e6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02042e8:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042ea:	ef9d                	bnez	a5,ffffffffc0204328 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc02042ec:	755c                	ld	a5,168(a0)
ffffffffc02042ee:	577d                	li	a4,-1
ffffffffc02042f0:	177e                	slli	a4,a4,0x3f
ffffffffc02042f2:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc02042f4:	00a93023          	sd	a0,0(s2)
ffffffffc02042f8:	8fd9                	or	a5,a5,a4
ffffffffc02042fa:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(current->context));
ffffffffc02042fe:	03050593          	addi	a1,a0,48
ffffffffc0204302:	03048513          	addi	a0,s1,48
ffffffffc0204306:	02c010ef          	jal	ra,ffffffffc0205332 <switch_to>
    if (flag)
ffffffffc020430a:	00099863          	bnez	s3,ffffffffc020431a <proc_run+0x52>
}
ffffffffc020430e:	70a2                	ld	ra,40(sp)
ffffffffc0204310:	7482                	ld	s1,32(sp)
ffffffffc0204312:	6962                	ld	s2,24(sp)
ffffffffc0204314:	69c2                	ld	s3,16(sp)
ffffffffc0204316:	6145                	addi	sp,sp,48
ffffffffc0204318:	8082                	ret
ffffffffc020431a:	70a2                	ld	ra,40(sp)
ffffffffc020431c:	7482                	ld	s1,32(sp)
ffffffffc020431e:	6962                	ld	s2,24(sp)
ffffffffc0204320:	69c2                	ld	s3,16(sp)
ffffffffc0204322:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204324:	e8afc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204328:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020432a:	e8afc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020432e:	6522                	ld	a0,8(sp)
ffffffffc0204330:	4985                	li	s3,1
ffffffffc0204332:	bf6d                	j	ffffffffc02042ec <proc_run+0x24>

ffffffffc0204334 <do_fork>:
{
ffffffffc0204334:	7119                	addi	sp,sp,-128
ffffffffc0204336:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204338:	000a6917          	auipc	s2,0xa6
ffffffffc020433c:	53090913          	addi	s2,s2,1328 # ffffffffc02aa868 <nr_process>
ffffffffc0204340:	00092703          	lw	a4,0(s2)
{
ffffffffc0204344:	fc86                	sd	ra,120(sp)
ffffffffc0204346:	f8a2                	sd	s0,112(sp)
ffffffffc0204348:	f4a6                	sd	s1,104(sp)
ffffffffc020434a:	ecce                	sd	s3,88(sp)
ffffffffc020434c:	e8d2                	sd	s4,80(sp)
ffffffffc020434e:	e4d6                	sd	s5,72(sp)
ffffffffc0204350:	e0da                	sd	s6,64(sp)
ffffffffc0204352:	fc5e                	sd	s7,56(sp)
ffffffffc0204354:	f862                	sd	s8,48(sp)
ffffffffc0204356:	f466                	sd	s9,40(sp)
ffffffffc0204358:	f06a                	sd	s10,32(sp)
ffffffffc020435a:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020435c:	6785                	lui	a5,0x1
ffffffffc020435e:	32f75863          	bge	a4,a5,ffffffffc020468e <do_fork+0x35a>
ffffffffc0204362:	8a2a                	mv	s4,a0
ffffffffc0204364:	89ae                	mv	s3,a1
ffffffffc0204366:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0204368:	de3ff0ef          	jal	ra,ffffffffc020414a <alloc_proc>
ffffffffc020436c:	84aa                	mv	s1,a0
ffffffffc020436e:	30050163          	beqz	a0,ffffffffc0204670 <do_fork+0x33c>
    proc->parent = current; 
ffffffffc0204372:	000a6c17          	auipc	s8,0xa6
ffffffffc0204376:	4dec0c13          	addi	s8,s8,1246 # ffffffffc02aa850 <current>
ffffffffc020437a:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020437e:	4509                	li	a0,2
    proc->parent = current; 
ffffffffc0204380:	f09c                	sd	a5,32(s1)
    current->wait_state = 0;
ffffffffc0204382:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ad4>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204386:	b5ffd0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
    if (page != NULL)
ffffffffc020438a:	2e050063          	beqz	a0,ffffffffc020466a <do_fork+0x336>
    return page - pages + nbase;
ffffffffc020438e:	000a6a97          	auipc	s5,0xa6
ffffffffc0204392:	4a2a8a93          	addi	s5,s5,1186 # ffffffffc02aa830 <pages>
ffffffffc0204396:	000ab683          	ld	a3,0(s5)
ffffffffc020439a:	00004b17          	auipc	s6,0x4
ffffffffc020439e:	89eb0b13          	addi	s6,s6,-1890 # ffffffffc0207c38 <nbase>
ffffffffc02043a2:	000b3783          	ld	a5,0(s6)
ffffffffc02043a6:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02043aa:	000a6b97          	auipc	s7,0xa6
ffffffffc02043ae:	47eb8b93          	addi	s7,s7,1150 # ffffffffc02aa828 <npage>
    return page - pages + nbase;
ffffffffc02043b2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02043b4:	5dfd                	li	s11,-1
ffffffffc02043b6:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02043ba:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02043bc:	00cddd93          	srli	s11,s11,0xc
ffffffffc02043c0:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02043c4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043c6:	32e67a63          	bgeu	a2,a4,ffffffffc02046fa <do_fork+0x3c6>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02043ca:	000c3603          	ld	a2,0(s8)
ffffffffc02043ce:	000a6c17          	auipc	s8,0xa6
ffffffffc02043d2:	472c0c13          	addi	s8,s8,1138 # ffffffffc02aa840 <va_pa_offset>
ffffffffc02043d6:	000c3703          	ld	a4,0(s8)
ffffffffc02043da:	02863d03          	ld	s10,40(a2)
ffffffffc02043de:	e43e                	sd	a5,8(sp)
ffffffffc02043e0:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02043e2:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02043e4:	020d0863          	beqz	s10,ffffffffc0204414 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc02043e8:	100a7a13          	andi	s4,s4,256
ffffffffc02043ec:	1c0a0163          	beqz	s4,ffffffffc02045ae <do_fork+0x27a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02043f0:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02043f4:	018d3783          	ld	a5,24(s10)
ffffffffc02043f8:	c02006b7          	lui	a3,0xc0200
ffffffffc02043fc:	2705                	addiw	a4,a4,1
ffffffffc02043fe:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204402:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204406:	2cd7e163          	bltu	a5,a3,ffffffffc02046c8 <do_fork+0x394>
ffffffffc020440a:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020440e:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204410:	8f99                	sub	a5,a5,a4
ffffffffc0204412:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204414:	6789                	lui	a5,0x2
ffffffffc0204416:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce0>
ffffffffc020441a:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020441c:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020441e:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204420:	87b6                	mv	a5,a3
ffffffffc0204422:	12040893          	addi	a7,s0,288
ffffffffc0204426:	00063803          	ld	a6,0(a2)
ffffffffc020442a:	6608                	ld	a0,8(a2)
ffffffffc020442c:	6a0c                	ld	a1,16(a2)
ffffffffc020442e:	6e18                	ld	a4,24(a2)
ffffffffc0204430:	0107b023          	sd	a6,0(a5)
ffffffffc0204434:	e788                	sd	a0,8(a5)
ffffffffc0204436:	eb8c                	sd	a1,16(a5)
ffffffffc0204438:	ef98                	sd	a4,24(a5)
ffffffffc020443a:	02060613          	addi	a2,a2,32
ffffffffc020443e:	02078793          	addi	a5,a5,32
ffffffffc0204442:	ff1612e3          	bne	a2,a7,ffffffffc0204426 <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc0204446:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020444a:	12098f63          	beqz	s3,ffffffffc0204588 <do_fork+0x254>
ffffffffc020444e:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204452:	00000797          	auipc	a5,0x0
ffffffffc0204456:	d7478793          	addi	a5,a5,-652 # ffffffffc02041c6 <forkret>
ffffffffc020445a:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020445c:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020445e:	100027f3          	csrr	a5,sstatus
ffffffffc0204462:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204464:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204466:	14079063          	bnez	a5,ffffffffc02045a6 <do_fork+0x272>
    if (++last_pid >= MAX_PID)
ffffffffc020446a:	000a2817          	auipc	a6,0xa2
ffffffffc020446e:	f4680813          	addi	a6,a6,-186 # ffffffffc02a63b0 <last_pid.1>
ffffffffc0204472:	00082783          	lw	a5,0(a6)
ffffffffc0204476:	6709                	lui	a4,0x2
ffffffffc0204478:	0017851b          	addiw	a0,a5,1
ffffffffc020447c:	00a82023          	sw	a0,0(a6)
ffffffffc0204480:	08e55d63          	bge	a0,a4,ffffffffc020451a <do_fork+0x1e6>
    if (last_pid >= next_safe)
ffffffffc0204484:	000a2317          	auipc	t1,0xa2
ffffffffc0204488:	f3030313          	addi	t1,t1,-208 # ffffffffc02a63b4 <next_safe.0>
ffffffffc020448c:	00032783          	lw	a5,0(t1)
ffffffffc0204490:	000a6417          	auipc	s0,0xa6
ffffffffc0204494:	34040413          	addi	s0,s0,832 # ffffffffc02aa7d0 <proc_list>
ffffffffc0204498:	08f55963          	bge	a0,a5,ffffffffc020452a <do_fork+0x1f6>
    	proc->pid = get_pid(); // 获取一个唯一的 PID
ffffffffc020449c:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020449e:	45a9                	li	a1,10
ffffffffc02044a0:	2501                	sext.w	a0,a0
ffffffffc02044a2:	0e6010ef          	jal	ra,ffffffffc0205588 <hash32>
ffffffffc02044a6:	02051793          	slli	a5,a0,0x20
ffffffffc02044aa:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02044ae:	000a2797          	auipc	a5,0xa2
ffffffffc02044b2:	32278793          	addi	a5,a5,802 # ffffffffc02a67d0 <hash_list>
ffffffffc02044b6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02044b8:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02044ba:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02044bc:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02044c0:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02044c2:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02044c4:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02044c6:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02044c8:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02044cc:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02044ce:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02044d0:	e21c                	sd	a5,0(a2)
ffffffffc02044d2:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02044d4:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02044d6:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02044d8:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02044dc:	10e4b023          	sd	a4,256(s1)
ffffffffc02044e0:	c311                	beqz	a4,ffffffffc02044e4 <do_fork+0x1b0>
        proc->optr->yptr = proc;
ffffffffc02044e2:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02044e4:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02044e8:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02044ea:	2785                	addiw	a5,a5,1
ffffffffc02044ec:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc02044f0:	18099263          	bnez	s3,ffffffffc0204674 <do_fork+0x340>
    wakeup_proc(proc); // 将 proc->state 设置为 PROC_RUNNABLE
ffffffffc02044f4:	8526                	mv	a0,s1
ffffffffc02044f6:	6a7000ef          	jal	ra,ffffffffc020539c <wakeup_proc>
    ret = proc->pid;
ffffffffc02044fa:	40c8                	lw	a0,4(s1)
}
ffffffffc02044fc:	70e6                	ld	ra,120(sp)
ffffffffc02044fe:	7446                	ld	s0,112(sp)
ffffffffc0204500:	74a6                	ld	s1,104(sp)
ffffffffc0204502:	7906                	ld	s2,96(sp)
ffffffffc0204504:	69e6                	ld	s3,88(sp)
ffffffffc0204506:	6a46                	ld	s4,80(sp)
ffffffffc0204508:	6aa6                	ld	s5,72(sp)
ffffffffc020450a:	6b06                	ld	s6,64(sp)
ffffffffc020450c:	7be2                	ld	s7,56(sp)
ffffffffc020450e:	7c42                	ld	s8,48(sp)
ffffffffc0204510:	7ca2                	ld	s9,40(sp)
ffffffffc0204512:	7d02                	ld	s10,32(sp)
ffffffffc0204514:	6de2                	ld	s11,24(sp)
ffffffffc0204516:	6109                	addi	sp,sp,128
ffffffffc0204518:	8082                	ret
        last_pid = 1;
ffffffffc020451a:	4785                	li	a5,1
ffffffffc020451c:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204520:	4505                	li	a0,1
ffffffffc0204522:	000a2317          	auipc	t1,0xa2
ffffffffc0204526:	e9230313          	addi	t1,t1,-366 # ffffffffc02a63b4 <next_safe.0>
    return listelm->next;
ffffffffc020452a:	000a6417          	auipc	s0,0xa6
ffffffffc020452e:	2a640413          	addi	s0,s0,678 # ffffffffc02aa7d0 <proc_list>
ffffffffc0204532:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204536:	6789                	lui	a5,0x2
ffffffffc0204538:	00f32023          	sw	a5,0(t1)
ffffffffc020453c:	86aa                	mv	a3,a0
ffffffffc020453e:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204540:	6e89                	lui	t4,0x2
ffffffffc0204542:	148e0163          	beq	t3,s0,ffffffffc0204684 <do_fork+0x350>
ffffffffc0204546:	88ae                	mv	a7,a1
ffffffffc0204548:	87f2                	mv	a5,t3
ffffffffc020454a:	6609                	lui	a2,0x2
ffffffffc020454c:	a811                	j	ffffffffc0204560 <do_fork+0x22c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020454e:	00e6d663          	bge	a3,a4,ffffffffc020455a <do_fork+0x226>
ffffffffc0204552:	00c75463          	bge	a4,a2,ffffffffc020455a <do_fork+0x226>
ffffffffc0204556:	863a                	mv	a2,a4
ffffffffc0204558:	4885                	li	a7,1
ffffffffc020455a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020455c:	00878d63          	beq	a5,s0,ffffffffc0204576 <do_fork+0x242>
            if (proc->pid == last_pid)
ffffffffc0204560:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c84>
ffffffffc0204564:	fed715e3          	bne	a4,a3,ffffffffc020454e <do_fork+0x21a>
                if (++last_pid >= next_safe)
ffffffffc0204568:	2685                	addiw	a3,a3,1
ffffffffc020456a:	10c6d863          	bge	a3,a2,ffffffffc020467a <do_fork+0x346>
ffffffffc020456e:	679c                	ld	a5,8(a5)
ffffffffc0204570:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204572:	fe8797e3          	bne	a5,s0,ffffffffc0204560 <do_fork+0x22c>
ffffffffc0204576:	c581                	beqz	a1,ffffffffc020457e <do_fork+0x24a>
ffffffffc0204578:	00d82023          	sw	a3,0(a6)
ffffffffc020457c:	8536                	mv	a0,a3
ffffffffc020457e:	f0088fe3          	beqz	a7,ffffffffc020449c <do_fork+0x168>
ffffffffc0204582:	00c32023          	sw	a2,0(t1)
ffffffffc0204586:	bf19                	j	ffffffffc020449c <do_fork+0x168>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204588:	89b6                	mv	s3,a3
ffffffffc020458a:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020458e:	00000797          	auipc	a5,0x0
ffffffffc0204592:	c3878793          	addi	a5,a5,-968 # ffffffffc02041c6 <forkret>
ffffffffc0204596:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204598:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020459a:	100027f3          	csrr	a5,sstatus
ffffffffc020459e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045a0:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045a2:	ec0784e3          	beqz	a5,ffffffffc020446a <do_fork+0x136>
        intr_disable();
ffffffffc02045a6:	c0efc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02045aa:	4985                	li	s3,1
ffffffffc02045ac:	bd7d                	j	ffffffffc020446a <do_fork+0x136>
    if ((mm = mm_create()) == NULL)
ffffffffc02045ae:	95aff0ef          	jal	ra,ffffffffc0203708 <mm_create>
ffffffffc02045b2:	8caa                	mv	s9,a0
ffffffffc02045b4:	c159                	beqz	a0,ffffffffc020463a <do_fork+0x306>
    if ((page = alloc_page()) == NULL)
ffffffffc02045b6:	4505                	li	a0,1
ffffffffc02045b8:	92dfd0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02045bc:	cd25                	beqz	a0,ffffffffc0204634 <do_fork+0x300>
    return page - pages + nbase;
ffffffffc02045be:	000ab683          	ld	a3,0(s5)
ffffffffc02045c2:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02045c4:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02045c8:	40d506b3          	sub	a3,a0,a3
ffffffffc02045cc:	8699                	srai	a3,a3,0x6
ffffffffc02045ce:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02045d0:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02045d4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02045d6:	12edf263          	bgeu	s11,a4,ffffffffc02046fa <do_fork+0x3c6>
ffffffffc02045da:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02045de:	6605                	lui	a2,0x1
ffffffffc02045e0:	000a6597          	auipc	a1,0xa6
ffffffffc02045e4:	2405b583          	ld	a1,576(a1) # ffffffffc02aa820 <boot_pgdir_va>
ffffffffc02045e8:	9a36                	add	s4,s4,a3
ffffffffc02045ea:	8552                	mv	a0,s4
ffffffffc02045ec:	454010ef          	jal	ra,ffffffffc0205a40 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02045f0:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02045f4:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02045f8:	4785                	li	a5,1
ffffffffc02045fa:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02045fe:	8b85                	andi	a5,a5,1
ffffffffc0204600:	4a05                	li	s4,1
ffffffffc0204602:	c799                	beqz	a5,ffffffffc0204610 <do_fork+0x2dc>
    {
        schedule();
ffffffffc0204604:	619000ef          	jal	ra,ffffffffc020541c <schedule>
ffffffffc0204608:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020460c:	8b85                	andi	a5,a5,1
ffffffffc020460e:	fbfd                	bnez	a5,ffffffffc0204604 <do_fork+0x2d0>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204610:	85ea                	mv	a1,s10
ffffffffc0204612:	8566                	mv	a0,s9
ffffffffc0204614:	bb8ff0ef          	jal	ra,ffffffffc02039cc <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204618:	57f9                	li	a5,-2
ffffffffc020461a:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020461e:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204620:	cfa5                	beqz	a5,ffffffffc0204698 <do_fork+0x364>
good_mm:
ffffffffc0204622:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204624:	dc0506e3          	beqz	a0,ffffffffc02043f0 <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc0204628:	8566                	mv	a0,s9
ffffffffc020462a:	c3cff0ef          	jal	ra,ffffffffc0203a66 <exit_mmap>
    put_pgdir(mm);
ffffffffc020462e:	8566                	mv	a0,s9
ffffffffc0204630:	c23ff0ef          	jal	ra,ffffffffc0204252 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204634:	8566                	mv	a0,s9
ffffffffc0204636:	a94ff0ef          	jal	ra,ffffffffc02038ca <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020463a:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020463c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204640:	0af6e163          	bltu	a3,a5,ffffffffc02046e2 <do_fork+0x3ae>
ffffffffc0204644:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204648:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020464c:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204650:	83b1                	srli	a5,a5,0xc
ffffffffc0204652:	04e7ff63          	bgeu	a5,a4,ffffffffc02046b0 <do_fork+0x37c>
    return &pages[PPN(pa) - nbase];
ffffffffc0204656:	000b3703          	ld	a4,0(s6)
ffffffffc020465a:	000ab503          	ld	a0,0(s5)
ffffffffc020465e:	4589                	li	a1,2
ffffffffc0204660:	8f99                	sub	a5,a5,a4
ffffffffc0204662:	079a                	slli	a5,a5,0x6
ffffffffc0204664:	953e                	add	a0,a0,a5
ffffffffc0204666:	8bdfd0ef          	jal	ra,ffffffffc0201f22 <free_pages>
    kfree(proc);
ffffffffc020466a:	8526                	mv	a0,s1
ffffffffc020466c:	f4afd0ef          	jal	ra,ffffffffc0201db6 <kfree>
    ret = -E_NO_MEM;
ffffffffc0204670:	5571                	li	a0,-4
    return ret;
ffffffffc0204672:	b569                	j	ffffffffc02044fc <do_fork+0x1c8>
        intr_enable();
ffffffffc0204674:	b3afc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204678:	bdb5                	j	ffffffffc02044f4 <do_fork+0x1c0>
                    if (last_pid >= MAX_PID)
ffffffffc020467a:	01d6c363          	blt	a3,t4,ffffffffc0204680 <do_fork+0x34c>
                        last_pid = 1;
ffffffffc020467e:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204680:	4585                	li	a1,1
ffffffffc0204682:	b5c1                	j	ffffffffc0204542 <do_fork+0x20e>
ffffffffc0204684:	c599                	beqz	a1,ffffffffc0204692 <do_fork+0x35e>
ffffffffc0204686:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020468a:	8536                	mv	a0,a3
ffffffffc020468c:	bd01                	j	ffffffffc020449c <do_fork+0x168>
    int ret = -E_NO_FREE_PROC;
ffffffffc020468e:	556d                	li	a0,-5
ffffffffc0204690:	b5b5                	j	ffffffffc02044fc <do_fork+0x1c8>
    return last_pid;
ffffffffc0204692:	00082503          	lw	a0,0(a6)
ffffffffc0204696:	b519                	j	ffffffffc020449c <do_fork+0x168>
    {
        panic("Unlock failed.\n");
ffffffffc0204698:	00003617          	auipc	a2,0x3
ffffffffc020469c:	d2060613          	addi	a2,a2,-736 # ffffffffc02073b8 <default_pmm_manager+0xb20>
ffffffffc02046a0:	03f00593          	li	a1,63
ffffffffc02046a4:	00003517          	auipc	a0,0x3
ffffffffc02046a8:	d2450513          	addi	a0,a0,-732 # ffffffffc02073c8 <default_pmm_manager+0xb30>
ffffffffc02046ac:	de3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046b0:	00002617          	auipc	a2,0x2
ffffffffc02046b4:	2f060613          	addi	a2,a2,752 # ffffffffc02069a0 <default_pmm_manager+0x108>
ffffffffc02046b8:	06900593          	li	a1,105
ffffffffc02046bc:	00002517          	auipc	a0,0x2
ffffffffc02046c0:	23c50513          	addi	a0,a0,572 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02046c4:	dcbfb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02046c8:	86be                	mv	a3,a5
ffffffffc02046ca:	00002617          	auipc	a2,0x2
ffffffffc02046ce:	2ae60613          	addi	a2,a2,686 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc02046d2:	19600593          	li	a1,406
ffffffffc02046d6:	00003517          	auipc	a0,0x3
ffffffffc02046da:	cca50513          	addi	a0,a0,-822 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc02046de:	db1fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02046e2:	00002617          	auipc	a2,0x2
ffffffffc02046e6:	29660613          	addi	a2,a2,662 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc02046ea:	07700593          	li	a1,119
ffffffffc02046ee:	00002517          	auipc	a0,0x2
ffffffffc02046f2:	20a50513          	addi	a0,a0,522 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc02046f6:	d99fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02046fa:	00002617          	auipc	a2,0x2
ffffffffc02046fe:	1d660613          	addi	a2,a2,470 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc0204702:	07100593          	li	a1,113
ffffffffc0204706:	00002517          	auipc	a0,0x2
ffffffffc020470a:	1f250513          	addi	a0,a0,498 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc020470e:	d81fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204712 <kernel_thread>:
{
ffffffffc0204712:	7129                	addi	sp,sp,-320
ffffffffc0204714:	fa22                	sd	s0,304(sp)
ffffffffc0204716:	f626                	sd	s1,296(sp)
ffffffffc0204718:	f24a                	sd	s2,288(sp)
ffffffffc020471a:	84ae                	mv	s1,a1
ffffffffc020471c:	892a                	mv	s2,a0
ffffffffc020471e:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204720:	4581                	li	a1,0
ffffffffc0204722:	12000613          	li	a2,288
ffffffffc0204726:	850a                	mv	a0,sp
{
ffffffffc0204728:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020472a:	304010ef          	jal	ra,ffffffffc0205a2e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020472e:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204730:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204732:	100027f3          	csrr	a5,sstatus
ffffffffc0204736:	edd7f793          	andi	a5,a5,-291
ffffffffc020473a:	1207e793          	ori	a5,a5,288
ffffffffc020473e:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204740:	860a                	mv	a2,sp
ffffffffc0204742:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204746:	00000797          	auipc	a5,0x0
ffffffffc020474a:	9fc78793          	addi	a5,a5,-1540 # ffffffffc0204142 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020474e:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204750:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204752:	be3ff0ef          	jal	ra,ffffffffc0204334 <do_fork>
}
ffffffffc0204756:	70f2                	ld	ra,312(sp)
ffffffffc0204758:	7452                	ld	s0,304(sp)
ffffffffc020475a:	74b2                	ld	s1,296(sp)
ffffffffc020475c:	7912                	ld	s2,288(sp)
ffffffffc020475e:	6131                	addi	sp,sp,320
ffffffffc0204760:	8082                	ret

ffffffffc0204762 <do_exit>:
{
ffffffffc0204762:	7179                	addi	sp,sp,-48
ffffffffc0204764:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204766:	000a6417          	auipc	s0,0xa6
ffffffffc020476a:	0ea40413          	addi	s0,s0,234 # ffffffffc02aa850 <current>
ffffffffc020476e:	601c                	ld	a5,0(s0)
{
ffffffffc0204770:	f406                	sd	ra,40(sp)
ffffffffc0204772:	ec26                	sd	s1,24(sp)
ffffffffc0204774:	e84a                	sd	s2,16(sp)
ffffffffc0204776:	e44e                	sd	s3,8(sp)
ffffffffc0204778:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020477a:	000a6717          	auipc	a4,0xa6
ffffffffc020477e:	0de73703          	ld	a4,222(a4) # ffffffffc02aa858 <idleproc>
ffffffffc0204782:	0ce78c63          	beq	a5,a4,ffffffffc020485a <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204786:	000a6497          	auipc	s1,0xa6
ffffffffc020478a:	0da48493          	addi	s1,s1,218 # ffffffffc02aa860 <initproc>
ffffffffc020478e:	6098                	ld	a4,0(s1)
ffffffffc0204790:	0ee78b63          	beq	a5,a4,ffffffffc0204886 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204794:	0287b983          	ld	s3,40(a5)
ffffffffc0204798:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020479a:	02098663          	beqz	s3,ffffffffc02047c6 <do_exit+0x64>
ffffffffc020479e:	000a6797          	auipc	a5,0xa6
ffffffffc02047a2:	07a7b783          	ld	a5,122(a5) # ffffffffc02aa818 <boot_pgdir_pa>
ffffffffc02047a6:	577d                	li	a4,-1
ffffffffc02047a8:	177e                	slli	a4,a4,0x3f
ffffffffc02047aa:	83b1                	srli	a5,a5,0xc
ffffffffc02047ac:	8fd9                	or	a5,a5,a4
ffffffffc02047ae:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02047b2:	0309a783          	lw	a5,48(s3)
ffffffffc02047b6:	fff7871b          	addiw	a4,a5,-1
ffffffffc02047ba:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02047be:	cb55                	beqz	a4,ffffffffc0204872 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02047c0:	601c                	ld	a5,0(s0)
ffffffffc02047c2:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02047c6:	601c                	ld	a5,0(s0)
ffffffffc02047c8:	470d                	li	a4,3
ffffffffc02047ca:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02047cc:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047d0:	100027f3          	csrr	a5,sstatus
ffffffffc02047d4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047d6:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047d8:	e3f9                	bnez	a5,ffffffffc020489e <do_exit+0x13c>
        proc = current->parent;
ffffffffc02047da:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02047dc:	800007b7          	lui	a5,0x80000
ffffffffc02047e0:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02047e2:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02047e4:	0ec52703          	lw	a4,236(a0)
ffffffffc02047e8:	0af70f63          	beq	a4,a5,ffffffffc02048a6 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc02047ec:	6018                	ld	a4,0(s0)
ffffffffc02047ee:	7b7c                	ld	a5,240(a4)
ffffffffc02047f0:	c3a1                	beqz	a5,ffffffffc0204830 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02047f2:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047f6:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02047f8:	0985                	addi	s3,s3,1
ffffffffc02047fa:	a021                	j	ffffffffc0204802 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02047fc:	6018                	ld	a4,0(s0)
ffffffffc02047fe:	7b7c                	ld	a5,240(a4)
ffffffffc0204800:	cb85                	beqz	a5,ffffffffc0204830 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204802:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204806:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204808:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020480a:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020480c:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204810:	10e7b023          	sd	a4,256(a5)
ffffffffc0204814:	c311                	beqz	a4,ffffffffc0204818 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204816:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204818:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020481a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020481c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020481e:	fd271fe3          	bne	a4,s2,ffffffffc02047fc <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204822:	0ec52783          	lw	a5,236(a0)
ffffffffc0204826:	fd379be3          	bne	a5,s3,ffffffffc02047fc <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020482a:	373000ef          	jal	ra,ffffffffc020539c <wakeup_proc>
ffffffffc020482e:	b7f9                	j	ffffffffc02047fc <do_exit+0x9a>
    if (flag)
ffffffffc0204830:	020a1263          	bnez	s4,ffffffffc0204854 <do_exit+0xf2>
    schedule();
ffffffffc0204834:	3e9000ef          	jal	ra,ffffffffc020541c <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204838:	601c                	ld	a5,0(s0)
ffffffffc020483a:	00003617          	auipc	a2,0x3
ffffffffc020483e:	bc660613          	addi	a2,a2,-1082 # ffffffffc0207400 <default_pmm_manager+0xb68>
ffffffffc0204842:	25000593          	li	a1,592
ffffffffc0204846:	43d4                	lw	a3,4(a5)
ffffffffc0204848:	00003517          	auipc	a0,0x3
ffffffffc020484c:	b5850513          	addi	a0,a0,-1192 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204850:	c3ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204854:	95afc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204858:	bff1                	j	ffffffffc0204834 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020485a:	00003617          	auipc	a2,0x3
ffffffffc020485e:	b8660613          	addi	a2,a2,-1146 # ffffffffc02073e0 <default_pmm_manager+0xb48>
ffffffffc0204862:	21c00593          	li	a1,540
ffffffffc0204866:	00003517          	auipc	a0,0x3
ffffffffc020486a:	b3a50513          	addi	a0,a0,-1222 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc020486e:	c21fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204872:	854e                	mv	a0,s3
ffffffffc0204874:	9f2ff0ef          	jal	ra,ffffffffc0203a66 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204878:	854e                	mv	a0,s3
ffffffffc020487a:	9d9ff0ef          	jal	ra,ffffffffc0204252 <put_pgdir>
            mm_destroy(mm);
ffffffffc020487e:	854e                	mv	a0,s3
ffffffffc0204880:	84aff0ef          	jal	ra,ffffffffc02038ca <mm_destroy>
ffffffffc0204884:	bf35                	j	ffffffffc02047c0 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204886:	00003617          	auipc	a2,0x3
ffffffffc020488a:	b6a60613          	addi	a2,a2,-1174 # ffffffffc02073f0 <default_pmm_manager+0xb58>
ffffffffc020488e:	22000593          	li	a1,544
ffffffffc0204892:	00003517          	auipc	a0,0x3
ffffffffc0204896:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc020489a:	bf5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc020489e:	916fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02048a2:	4a05                	li	s4,1
ffffffffc02048a4:	bf1d                	j	ffffffffc02047da <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02048a6:	2f7000ef          	jal	ra,ffffffffc020539c <wakeup_proc>
ffffffffc02048aa:	b789                	j	ffffffffc02047ec <do_exit+0x8a>

ffffffffc02048ac <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02048ac:	715d                	addi	sp,sp,-80
ffffffffc02048ae:	f84a                	sd	s2,48(sp)
ffffffffc02048b0:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02048b2:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02048b6:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02048b8:	fc26                	sd	s1,56(sp)
ffffffffc02048ba:	f052                	sd	s4,32(sp)
ffffffffc02048bc:	ec56                	sd	s5,24(sp)
ffffffffc02048be:	e85a                	sd	s6,16(sp)
ffffffffc02048c0:	e45e                	sd	s7,8(sp)
ffffffffc02048c2:	e486                	sd	ra,72(sp)
ffffffffc02048c4:	e0a2                	sd	s0,64(sp)
ffffffffc02048c6:	84aa                	mv	s1,a0
ffffffffc02048c8:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02048ca:	000a6b97          	auipc	s7,0xa6
ffffffffc02048ce:	f86b8b93          	addi	s7,s7,-122 # ffffffffc02aa850 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02048d2:	00050b1b          	sext.w	s6,a0
ffffffffc02048d6:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02048da:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02048dc:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02048de:	ccbd                	beqz	s1,ffffffffc020495c <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02048e0:	0359e863          	bltu	s3,s5,ffffffffc0204910 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02048e4:	45a9                	li	a1,10
ffffffffc02048e6:	855a                	mv	a0,s6
ffffffffc02048e8:	4a1000ef          	jal	ra,ffffffffc0205588 <hash32>
ffffffffc02048ec:	02051793          	slli	a5,a0,0x20
ffffffffc02048f0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02048f4:	000a2797          	auipc	a5,0xa2
ffffffffc02048f8:	edc78793          	addi	a5,a5,-292 # ffffffffc02a67d0 <hash_list>
ffffffffc02048fc:	953e                	add	a0,a0,a5
ffffffffc02048fe:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204900:	a029                	j	ffffffffc020490a <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204902:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204906:	02978163          	beq	a5,s1,ffffffffc0204928 <do_wait.part.0+0x7c>
ffffffffc020490a:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020490c:	fe851be3          	bne	a0,s0,ffffffffc0204902 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204910:	5579                	li	a0,-2
}
ffffffffc0204912:	60a6                	ld	ra,72(sp)
ffffffffc0204914:	6406                	ld	s0,64(sp)
ffffffffc0204916:	74e2                	ld	s1,56(sp)
ffffffffc0204918:	7942                	ld	s2,48(sp)
ffffffffc020491a:	79a2                	ld	s3,40(sp)
ffffffffc020491c:	7a02                	ld	s4,32(sp)
ffffffffc020491e:	6ae2                	ld	s5,24(sp)
ffffffffc0204920:	6b42                	ld	s6,16(sp)
ffffffffc0204922:	6ba2                	ld	s7,8(sp)
ffffffffc0204924:	6161                	addi	sp,sp,80
ffffffffc0204926:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204928:	000bb683          	ld	a3,0(s7)
ffffffffc020492c:	f4843783          	ld	a5,-184(s0)
ffffffffc0204930:	fed790e3          	bne	a5,a3,ffffffffc0204910 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204934:	f2842703          	lw	a4,-216(s0)
ffffffffc0204938:	478d                	li	a5,3
ffffffffc020493a:	0ef70b63          	beq	a4,a5,ffffffffc0204a30 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020493e:	4785                	li	a5,1
ffffffffc0204940:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204942:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204946:	2d7000ef          	jal	ra,ffffffffc020541c <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020494a:	000bb783          	ld	a5,0(s7)
ffffffffc020494e:	0b07a783          	lw	a5,176(a5)
ffffffffc0204952:	8b85                	andi	a5,a5,1
ffffffffc0204954:	d7c9                	beqz	a5,ffffffffc02048de <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204956:	555d                	li	a0,-9
ffffffffc0204958:	e0bff0ef          	jal	ra,ffffffffc0204762 <do_exit>
        proc = current->cptr;
ffffffffc020495c:	000bb683          	ld	a3,0(s7)
ffffffffc0204960:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204962:	d45d                	beqz	s0,ffffffffc0204910 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204964:	470d                	li	a4,3
ffffffffc0204966:	a021                	j	ffffffffc020496e <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204968:	10043403          	ld	s0,256(s0)
ffffffffc020496c:	d869                	beqz	s0,ffffffffc020493e <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020496e:	401c                	lw	a5,0(s0)
ffffffffc0204970:	fee79ce3          	bne	a5,a4,ffffffffc0204968 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204974:	000a6797          	auipc	a5,0xa6
ffffffffc0204978:	ee47b783          	ld	a5,-284(a5) # ffffffffc02aa858 <idleproc>
ffffffffc020497c:	0c878963          	beq	a5,s0,ffffffffc0204a4e <do_wait.part.0+0x1a2>
ffffffffc0204980:	000a6797          	auipc	a5,0xa6
ffffffffc0204984:	ee07b783          	ld	a5,-288(a5) # ffffffffc02aa860 <initproc>
ffffffffc0204988:	0cf40363          	beq	s0,a5,ffffffffc0204a4e <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc020498c:	000a0663          	beqz	s4,ffffffffc0204998 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204990:	0e842783          	lw	a5,232(s0)
ffffffffc0204994:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204998:	100027f3          	csrr	a5,sstatus
ffffffffc020499c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020499e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02049a0:	e7c1                	bnez	a5,ffffffffc0204a28 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02049a2:	6c70                	ld	a2,216(s0)
ffffffffc02049a4:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02049a6:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02049aa:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02049ac:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02049ae:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02049b0:	6470                	ld	a2,200(s0)
ffffffffc02049b2:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02049b4:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02049b6:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02049b8:	c319                	beqz	a4,ffffffffc02049be <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02049ba:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02049bc:	7c7c                	ld	a5,248(s0)
ffffffffc02049be:	c3b5                	beqz	a5,ffffffffc0204a22 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02049c0:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02049c4:	000a6717          	auipc	a4,0xa6
ffffffffc02049c8:	ea470713          	addi	a4,a4,-348 # ffffffffc02aa868 <nr_process>
ffffffffc02049cc:	431c                	lw	a5,0(a4)
ffffffffc02049ce:	37fd                	addiw	a5,a5,-1
ffffffffc02049d0:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02049d2:	e5a9                	bnez	a1,ffffffffc0204a1c <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02049d4:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02049d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02049da:	04f6ee63          	bltu	a3,a5,ffffffffc0204a36 <do_wait.part.0+0x18a>
ffffffffc02049de:	000a6797          	auipc	a5,0xa6
ffffffffc02049e2:	e627b783          	ld	a5,-414(a5) # ffffffffc02aa840 <va_pa_offset>
ffffffffc02049e6:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02049e8:	82b1                	srli	a3,a3,0xc
ffffffffc02049ea:	000a6797          	auipc	a5,0xa6
ffffffffc02049ee:	e3e7b783          	ld	a5,-450(a5) # ffffffffc02aa828 <npage>
ffffffffc02049f2:	06f6fa63          	bgeu	a3,a5,ffffffffc0204a66 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02049f6:	00003517          	auipc	a0,0x3
ffffffffc02049fa:	24253503          	ld	a0,578(a0) # ffffffffc0207c38 <nbase>
ffffffffc02049fe:	8e89                	sub	a3,a3,a0
ffffffffc0204a00:	069a                	slli	a3,a3,0x6
ffffffffc0204a02:	000a6517          	auipc	a0,0xa6
ffffffffc0204a06:	e2e53503          	ld	a0,-466(a0) # ffffffffc02aa830 <pages>
ffffffffc0204a0a:	9536                	add	a0,a0,a3
ffffffffc0204a0c:	4589                	li	a1,2
ffffffffc0204a0e:	d14fd0ef          	jal	ra,ffffffffc0201f22 <free_pages>
    kfree(proc);
ffffffffc0204a12:	8522                	mv	a0,s0
ffffffffc0204a14:	ba2fd0ef          	jal	ra,ffffffffc0201db6 <kfree>
    return 0;
ffffffffc0204a18:	4501                	li	a0,0
ffffffffc0204a1a:	bde5                	j	ffffffffc0204912 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204a1c:	f93fb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204a20:	bf55                	j	ffffffffc02049d4 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204a22:	701c                	ld	a5,32(s0)
ffffffffc0204a24:	fbf8                	sd	a4,240(a5)
ffffffffc0204a26:	bf79                	j	ffffffffc02049c4 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204a28:	f8dfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204a2c:	4585                	li	a1,1
ffffffffc0204a2e:	bf95                	j	ffffffffc02049a2 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204a30:	f2840413          	addi	s0,s0,-216
ffffffffc0204a34:	b781                	j	ffffffffc0204974 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204a36:	00002617          	auipc	a2,0x2
ffffffffc0204a3a:	f4260613          	addi	a2,a2,-190 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc0204a3e:	07700593          	li	a1,119
ffffffffc0204a42:	00002517          	auipc	a0,0x2
ffffffffc0204a46:	eb650513          	addi	a0,a0,-330 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0204a4a:	a45fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204a4e:	00003617          	auipc	a2,0x3
ffffffffc0204a52:	9d260613          	addi	a2,a2,-1582 # ffffffffc0207420 <default_pmm_manager+0xb88>
ffffffffc0204a56:	37200593          	li	a1,882
ffffffffc0204a5a:	00003517          	auipc	a0,0x3
ffffffffc0204a5e:	94650513          	addi	a0,a0,-1722 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204a62:	a2dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204a66:	00002617          	auipc	a2,0x2
ffffffffc0204a6a:	f3a60613          	addi	a2,a2,-198 # ffffffffc02069a0 <default_pmm_manager+0x108>
ffffffffc0204a6e:	06900593          	li	a1,105
ffffffffc0204a72:	00002517          	auipc	a0,0x2
ffffffffc0204a76:	e8650513          	addi	a0,a0,-378 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc0204a7a:	a15fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204a7e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204a7e:	1141                	addi	sp,sp,-16
ffffffffc0204a80:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204a82:	ce0fd0ef          	jal	ra,ffffffffc0201f62 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204a86:	a7cfd0ef          	jal	ra,ffffffffc0201d02 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204a8a:	4601                	li	a2,0
ffffffffc0204a8c:	4581                	li	a1,0
ffffffffc0204a8e:	fffff517          	auipc	a0,0xfffff
ffffffffc0204a92:	74650513          	addi	a0,a0,1862 # ffffffffc02041d4 <user_main>
ffffffffc0204a96:	c7dff0ef          	jal	ra,ffffffffc0204712 <kernel_thread>
    if (pid <= 0)
ffffffffc0204a9a:	00a04563          	bgtz	a0,ffffffffc0204aa4 <init_main+0x26>
ffffffffc0204a9e:	a071                	j	ffffffffc0204b2a <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204aa0:	17d000ef          	jal	ra,ffffffffc020541c <schedule>
    if (code_store != NULL)
ffffffffc0204aa4:	4581                	li	a1,0
ffffffffc0204aa6:	4501                	li	a0,0
ffffffffc0204aa8:	e05ff0ef          	jal	ra,ffffffffc02048ac <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204aac:	d975                	beqz	a0,ffffffffc0204aa0 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204aae:	00003517          	auipc	a0,0x3
ffffffffc0204ab2:	9b250513          	addi	a0,a0,-1614 # ffffffffc0207460 <default_pmm_manager+0xbc8>
ffffffffc0204ab6:	edefb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204aba:	000a6797          	auipc	a5,0xa6
ffffffffc0204abe:	da67b783          	ld	a5,-602(a5) # ffffffffc02aa860 <initproc>
ffffffffc0204ac2:	7bf8                	ld	a4,240(a5)
ffffffffc0204ac4:	e339                	bnez	a4,ffffffffc0204b0a <init_main+0x8c>
ffffffffc0204ac6:	7ff8                	ld	a4,248(a5)
ffffffffc0204ac8:	e329                	bnez	a4,ffffffffc0204b0a <init_main+0x8c>
ffffffffc0204aca:	1007b703          	ld	a4,256(a5)
ffffffffc0204ace:	ef15                	bnez	a4,ffffffffc0204b0a <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204ad0:	000a6697          	auipc	a3,0xa6
ffffffffc0204ad4:	d986a683          	lw	a3,-616(a3) # ffffffffc02aa868 <nr_process>
ffffffffc0204ad8:	4709                	li	a4,2
ffffffffc0204ada:	0ae69463          	bne	a3,a4,ffffffffc0204b82 <init_main+0x104>
    return listelm->next;
ffffffffc0204ade:	000a6697          	auipc	a3,0xa6
ffffffffc0204ae2:	cf268693          	addi	a3,a3,-782 # ffffffffc02aa7d0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204ae6:	6698                	ld	a4,8(a3)
ffffffffc0204ae8:	0c878793          	addi	a5,a5,200
ffffffffc0204aec:	06f71b63          	bne	a4,a5,ffffffffc0204b62 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204af0:	629c                	ld	a5,0(a3)
ffffffffc0204af2:	04f71863          	bne	a4,a5,ffffffffc0204b42 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204af6:	00003517          	auipc	a0,0x3
ffffffffc0204afa:	a5250513          	addi	a0,a0,-1454 # ffffffffc0207548 <default_pmm_manager+0xcb0>
ffffffffc0204afe:	e96fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204b02:	60a2                	ld	ra,8(sp)
ffffffffc0204b04:	4501                	li	a0,0
ffffffffc0204b06:	0141                	addi	sp,sp,16
ffffffffc0204b08:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204b0a:	00003697          	auipc	a3,0x3
ffffffffc0204b0e:	97e68693          	addi	a3,a3,-1666 # ffffffffc0207488 <default_pmm_manager+0xbf0>
ffffffffc0204b12:	00002617          	auipc	a2,0x2
ffffffffc0204b16:	9d660613          	addi	a2,a2,-1578 # ffffffffc02064e8 <commands+0x828>
ffffffffc0204b1a:	3e000593          	li	a1,992
ffffffffc0204b1e:	00003517          	auipc	a0,0x3
ffffffffc0204b22:	88250513          	addi	a0,a0,-1918 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204b26:	969fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204b2a:	00003617          	auipc	a2,0x3
ffffffffc0204b2e:	91660613          	addi	a2,a2,-1770 # ffffffffc0207440 <default_pmm_manager+0xba8>
ffffffffc0204b32:	3d700593          	li	a1,983
ffffffffc0204b36:	00003517          	auipc	a0,0x3
ffffffffc0204b3a:	86a50513          	addi	a0,a0,-1942 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204b3e:	951fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204b42:	00003697          	auipc	a3,0x3
ffffffffc0204b46:	9d668693          	addi	a3,a3,-1578 # ffffffffc0207518 <default_pmm_manager+0xc80>
ffffffffc0204b4a:	00002617          	auipc	a2,0x2
ffffffffc0204b4e:	99e60613          	addi	a2,a2,-1634 # ffffffffc02064e8 <commands+0x828>
ffffffffc0204b52:	3e300593          	li	a1,995
ffffffffc0204b56:	00003517          	auipc	a0,0x3
ffffffffc0204b5a:	84a50513          	addi	a0,a0,-1974 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204b5e:	931fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204b62:	00003697          	auipc	a3,0x3
ffffffffc0204b66:	98668693          	addi	a3,a3,-1658 # ffffffffc02074e8 <default_pmm_manager+0xc50>
ffffffffc0204b6a:	00002617          	auipc	a2,0x2
ffffffffc0204b6e:	97e60613          	addi	a2,a2,-1666 # ffffffffc02064e8 <commands+0x828>
ffffffffc0204b72:	3e200593          	li	a1,994
ffffffffc0204b76:	00003517          	auipc	a0,0x3
ffffffffc0204b7a:	82a50513          	addi	a0,a0,-2006 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204b7e:	911fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204b82:	00003697          	auipc	a3,0x3
ffffffffc0204b86:	95668693          	addi	a3,a3,-1706 # ffffffffc02074d8 <default_pmm_manager+0xc40>
ffffffffc0204b8a:	00002617          	auipc	a2,0x2
ffffffffc0204b8e:	95e60613          	addi	a2,a2,-1698 # ffffffffc02064e8 <commands+0x828>
ffffffffc0204b92:	3e100593          	li	a1,993
ffffffffc0204b96:	00003517          	auipc	a0,0x3
ffffffffc0204b9a:	80a50513          	addi	a0,a0,-2038 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204b9e:	8f1fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204ba2 <do_execve>:
{
ffffffffc0204ba2:	7171                	addi	sp,sp,-176
ffffffffc0204ba4:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204ba6:	000a6d97          	auipc	s11,0xa6
ffffffffc0204baa:	caad8d93          	addi	s11,s11,-854 # ffffffffc02aa850 <current>
ffffffffc0204bae:	000db783          	ld	a5,0(s11)
{
ffffffffc0204bb2:	e94a                	sd	s2,144(sp)
ffffffffc0204bb4:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204bb6:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204bba:	ed26                	sd	s1,152(sp)
ffffffffc0204bbc:	f8da                	sd	s6,112(sp)
ffffffffc0204bbe:	84aa                	mv	s1,a0
ffffffffc0204bc0:	8b32                	mv	s6,a2
ffffffffc0204bc2:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204bc4:	862e                	mv	a2,a1
ffffffffc0204bc6:	4681                	li	a3,0
ffffffffc0204bc8:	85aa                	mv	a1,a0
ffffffffc0204bca:	854a                	mv	a0,s2
{
ffffffffc0204bcc:	f506                	sd	ra,168(sp)
ffffffffc0204bce:	e54e                	sd	s3,136(sp)
ffffffffc0204bd0:	e152                	sd	s4,128(sp)
ffffffffc0204bd2:	fcd6                	sd	s5,120(sp)
ffffffffc0204bd4:	f4de                	sd	s7,104(sp)
ffffffffc0204bd6:	f0e2                	sd	s8,96(sp)
ffffffffc0204bd8:	ece6                	sd	s9,88(sp)
ffffffffc0204bda:	e8ea                	sd	s10,80(sp)
ffffffffc0204bdc:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204bde:	cd0ff0ef          	jal	ra,ffffffffc02040ae <user_mem_check>
ffffffffc0204be2:	40050a63          	beqz	a0,ffffffffc0204ff6 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204be6:	4641                	li	a2,16
ffffffffc0204be8:	4581                	li	a1,0
ffffffffc0204bea:	1808                	addi	a0,sp,48
ffffffffc0204bec:	643000ef          	jal	ra,ffffffffc0205a2e <memset>
    memcpy(local_name, name, len);
ffffffffc0204bf0:	47bd                	li	a5,15
ffffffffc0204bf2:	8622                	mv	a2,s0
ffffffffc0204bf4:	1e87e263          	bltu	a5,s0,ffffffffc0204dd8 <do_execve+0x236>
ffffffffc0204bf8:	85a6                	mv	a1,s1
ffffffffc0204bfa:	1808                	addi	a0,sp,48
ffffffffc0204bfc:	645000ef          	jal	ra,ffffffffc0205a40 <memcpy>
    if (mm != NULL)
ffffffffc0204c00:	1e090363          	beqz	s2,ffffffffc0204de6 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204c04:	00002517          	auipc	a0,0x2
ffffffffc0204c08:	4c450513          	addi	a0,a0,1220 # ffffffffc02070c8 <default_pmm_manager+0x830>
ffffffffc0204c0c:	dc0fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204c10:	000a6797          	auipc	a5,0xa6
ffffffffc0204c14:	c087b783          	ld	a5,-1016(a5) # ffffffffc02aa818 <boot_pgdir_pa>
ffffffffc0204c18:	577d                	li	a4,-1
ffffffffc0204c1a:	177e                	slli	a4,a4,0x3f
ffffffffc0204c1c:	83b1                	srli	a5,a5,0xc
ffffffffc0204c1e:	8fd9                	or	a5,a5,a4
ffffffffc0204c20:	18079073          	csrw	satp,a5
ffffffffc0204c24:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_exit_out_size+0xffffffff7fff4f00>
ffffffffc0204c28:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204c2c:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204c30:	2c070463          	beqz	a4,ffffffffc0204ef8 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204c34:	000db783          	ld	a5,0(s11)
ffffffffc0204c38:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204c3c:	acdfe0ef          	jal	ra,ffffffffc0203708 <mm_create>
ffffffffc0204c40:	842a                	mv	s0,a0
ffffffffc0204c42:	1c050d63          	beqz	a0,ffffffffc0204e1c <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204c46:	4505                	li	a0,1
ffffffffc0204c48:	a9cfd0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0204c4c:	3a050963          	beqz	a0,ffffffffc0204ffe <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204c50:	000a6c97          	auipc	s9,0xa6
ffffffffc0204c54:	be0c8c93          	addi	s9,s9,-1056 # ffffffffc02aa830 <pages>
ffffffffc0204c58:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204c5c:	000a6c17          	auipc	s8,0xa6
ffffffffc0204c60:	bccc0c13          	addi	s8,s8,-1076 # ffffffffc02aa828 <npage>
    return page - pages + nbase;
ffffffffc0204c64:	00003717          	auipc	a4,0x3
ffffffffc0204c68:	fd473703          	ld	a4,-44(a4) # ffffffffc0207c38 <nbase>
ffffffffc0204c6c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204c70:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204c72:	5a7d                	li	s4,-1
ffffffffc0204c74:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204c78:	96ba                	add	a3,a3,a4
ffffffffc0204c7a:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c7c:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204c80:	ec3a                	sd	a4,24(sp)
ffffffffc0204c82:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c84:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c86:	38f77063          	bgeu	a4,a5,ffffffffc0205006 <do_execve+0x464>
ffffffffc0204c8a:	000a6a97          	auipc	s5,0xa6
ffffffffc0204c8e:	bb6a8a93          	addi	s5,s5,-1098 # ffffffffc02aa840 <va_pa_offset>
ffffffffc0204c92:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204c96:	6605                	lui	a2,0x1
ffffffffc0204c98:	000a6597          	auipc	a1,0xa6
ffffffffc0204c9c:	b885b583          	ld	a1,-1144(a1) # ffffffffc02aa820 <boot_pgdir_va>
ffffffffc0204ca0:	94b6                	add	s1,s1,a3
ffffffffc0204ca2:	8526                	mv	a0,s1
ffffffffc0204ca4:	59d000ef          	jal	ra,ffffffffc0205a40 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204ca8:	7782                	ld	a5,32(sp)
ffffffffc0204caa:	4398                	lw	a4,0(a5)
ffffffffc0204cac:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204cb0:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204cb2:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b944f>
ffffffffc0204cb6:	14f71963          	bne	a4,a5,ffffffffc0204e08 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204cba:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc0204cbc:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204cbe:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204cc2:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204cc6:	00371793          	slli	a5,a4,0x3
ffffffffc0204cca:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204ccc:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204cce:	078e                	slli	a5,a5,0x3
ffffffffc0204cd0:	97ca                	add	a5,a5,s2
ffffffffc0204cd2:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204cd4:	00f97c63          	bgeu	s2,a5,ffffffffc0204cec <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204cd8:	00092783          	lw	a5,0(s2)
ffffffffc0204cdc:	4705                	li	a4,1
ffffffffc0204cde:	14e78163          	beq	a5,a4,ffffffffc0204e20 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204ce2:	77a2                	ld	a5,40(sp)
ffffffffc0204ce4:	03890913          	addi	s2,s2,56
ffffffffc0204ce8:	fef968e3          	bltu	s2,a5,ffffffffc0204cd8 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204cec:	4701                	li	a4,0
ffffffffc0204cee:	46ad                	li	a3,11
ffffffffc0204cf0:	00100637          	lui	a2,0x100
ffffffffc0204cf4:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204cf8:	8522                	mv	a0,s0
ffffffffc0204cfa:	c23fe0ef          	jal	ra,ffffffffc020391c <mm_map>
ffffffffc0204cfe:	89aa                	mv	s3,a0
ffffffffc0204d00:	1e051263          	bnez	a0,ffffffffc0204ee4 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d04:	6c08                	ld	a0,24(s0)
ffffffffc0204d06:	467d                	li	a2,31
ffffffffc0204d08:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204d0c:	917fe0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc0204d10:	38050363          	beqz	a0,ffffffffc0205096 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d14:	6c08                	ld	a0,24(s0)
ffffffffc0204d16:	467d                	li	a2,31
ffffffffc0204d18:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204d1c:	907fe0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc0204d20:	34050b63          	beqz	a0,ffffffffc0205076 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d24:	6c08                	ld	a0,24(s0)
ffffffffc0204d26:	467d                	li	a2,31
ffffffffc0204d28:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204d2c:	8f7fe0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc0204d30:	32050363          	beqz	a0,ffffffffc0205056 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d34:	6c08                	ld	a0,24(s0)
ffffffffc0204d36:	467d                	li	a2,31
ffffffffc0204d38:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204d3c:	8e7fe0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc0204d40:	2e050b63          	beqz	a0,ffffffffc0205036 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204d44:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc0204d46:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d4a:	6c14                	ld	a3,24(s0)
ffffffffc0204d4c:	2785                	addiw	a5,a5,1
ffffffffc0204d4e:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204d50:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d52:	c02007b7          	lui	a5,0xc0200
ffffffffc0204d56:	2cf6e463          	bltu	a3,a5,ffffffffc020501e <do_execve+0x47c>
ffffffffc0204d5a:	000ab783          	ld	a5,0(s5)
ffffffffc0204d5e:	577d                	li	a4,-1
ffffffffc0204d60:	177e                	slli	a4,a4,0x3f
ffffffffc0204d62:	8e9d                	sub	a3,a3,a5
ffffffffc0204d64:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d68:	f654                	sd	a3,168(a2)
ffffffffc0204d6a:	8fd9                	or	a5,a5,a4
ffffffffc0204d6c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204d70:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204d72:	4581                	li	a1,0
ffffffffc0204d74:	12000613          	li	a2,288
ffffffffc0204d78:	8526                	mv	a0,s1
ffffffffc0204d7a:	4b5000ef          	jal	ra,ffffffffc0205a2e <memset>
    tf->epc = elf->e_entry;               // 设置程序入口点
ffffffffc0204d7e:	7782                	ld	a5,32(sp)
ffffffffc0204d80:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;               // 设置用户栈顶指针
ffffffffc0204d82:	4785                	li	a5,1
ffffffffc0204d84:	07fe                	slli	a5,a5,0x1f
ffffffffc0204d86:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;               // 设置程序入口点
ffffffffc0204d88:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0204d8c:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d90:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0204d94:	edf7f793          	andi	a5,a5,-289
ffffffffc0204d98:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d9c:	0b440413          	addi	s0,s0,180
ffffffffc0204da0:	4641                	li	a2,16
ffffffffc0204da2:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0204da4:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204da8:	8522                	mv	a0,s0
ffffffffc0204daa:	485000ef          	jal	ra,ffffffffc0205a2e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204dae:	463d                	li	a2,15
ffffffffc0204db0:	180c                	addi	a1,sp,48
ffffffffc0204db2:	8522                	mv	a0,s0
ffffffffc0204db4:	48d000ef          	jal	ra,ffffffffc0205a40 <memcpy>
}
ffffffffc0204db8:	70aa                	ld	ra,168(sp)
ffffffffc0204dba:	740a                	ld	s0,160(sp)
ffffffffc0204dbc:	64ea                	ld	s1,152(sp)
ffffffffc0204dbe:	694a                	ld	s2,144(sp)
ffffffffc0204dc0:	6a0a                	ld	s4,128(sp)
ffffffffc0204dc2:	7ae6                	ld	s5,120(sp)
ffffffffc0204dc4:	7b46                	ld	s6,112(sp)
ffffffffc0204dc6:	7ba6                	ld	s7,104(sp)
ffffffffc0204dc8:	7c06                	ld	s8,96(sp)
ffffffffc0204dca:	6ce6                	ld	s9,88(sp)
ffffffffc0204dcc:	6d46                	ld	s10,80(sp)
ffffffffc0204dce:	6da6                	ld	s11,72(sp)
ffffffffc0204dd0:	854e                	mv	a0,s3
ffffffffc0204dd2:	69aa                	ld	s3,136(sp)
ffffffffc0204dd4:	614d                	addi	sp,sp,176
ffffffffc0204dd6:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204dd8:	463d                	li	a2,15
ffffffffc0204dda:	85a6                	mv	a1,s1
ffffffffc0204ddc:	1808                	addi	a0,sp,48
ffffffffc0204dde:	463000ef          	jal	ra,ffffffffc0205a40 <memcpy>
    if (mm != NULL)
ffffffffc0204de2:	e20911e3          	bnez	s2,ffffffffc0204c04 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204de6:	000db783          	ld	a5,0(s11)
ffffffffc0204dea:	779c                	ld	a5,40(a5)
ffffffffc0204dec:	e40788e3          	beqz	a5,ffffffffc0204c3c <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204df0:	00002617          	auipc	a2,0x2
ffffffffc0204df4:	77860613          	addi	a2,a2,1912 # ffffffffc0207568 <default_pmm_manager+0xcd0>
ffffffffc0204df8:	25c00593          	li	a1,604
ffffffffc0204dfc:	00002517          	auipc	a0,0x2
ffffffffc0204e00:	5a450513          	addi	a0,a0,1444 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204e04:	e8afb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204e08:	8522                	mv	a0,s0
ffffffffc0204e0a:	c48ff0ef          	jal	ra,ffffffffc0204252 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204e0e:	8522                	mv	a0,s0
ffffffffc0204e10:	abbfe0ef          	jal	ra,ffffffffc02038ca <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204e14:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0204e16:	854e                	mv	a0,s3
ffffffffc0204e18:	94bff0ef          	jal	ra,ffffffffc0204762 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204e1c:	59f1                	li	s3,-4
ffffffffc0204e1e:	bfe5                	j	ffffffffc0204e16 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204e20:	02893603          	ld	a2,40(s2)
ffffffffc0204e24:	02093783          	ld	a5,32(s2)
ffffffffc0204e28:	1cf66d63          	bltu	a2,a5,ffffffffc0205002 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204e2c:	00492783          	lw	a5,4(s2)
ffffffffc0204e30:	0017f693          	andi	a3,a5,1
ffffffffc0204e34:	c291                	beqz	a3,ffffffffc0204e38 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204e36:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204e38:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204e3c:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204e3e:	e779                	bnez	a4,ffffffffc0204f0c <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204e40:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204e42:	c781                	beqz	a5,ffffffffc0204e4a <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204e44:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204e48:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204e4a:	0026f793          	andi	a5,a3,2
ffffffffc0204e4e:	e3f1                	bnez	a5,ffffffffc0204f12 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204e50:	0046f793          	andi	a5,a3,4
ffffffffc0204e54:	c399                	beqz	a5,ffffffffc0204e5a <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204e56:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204e5a:	01093583          	ld	a1,16(s2)
ffffffffc0204e5e:	4701                	li	a4,0
ffffffffc0204e60:	8522                	mv	a0,s0
ffffffffc0204e62:	abbfe0ef          	jal	ra,ffffffffc020391c <mm_map>
ffffffffc0204e66:	89aa                	mv	s3,a0
ffffffffc0204e68:	ed35                	bnez	a0,ffffffffc0204ee4 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204e6a:	01093b03          	ld	s6,16(s2)
ffffffffc0204e6e:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204e70:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204e74:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204e78:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204e7c:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204e7e:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204e80:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0204e82:	053b6963          	bltu	s6,s3,ffffffffc0204ed4 <do_execve+0x332>
ffffffffc0204e86:	aa95                	j	ffffffffc0204ffa <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204e88:	6785                	lui	a5,0x1
ffffffffc0204e8a:	414b0533          	sub	a0,s6,s4
ffffffffc0204e8e:	9a3e                	add	s4,s4,a5
ffffffffc0204e90:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204e94:	0149f463          	bgeu	s3,s4,ffffffffc0204e9c <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204e98:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0204e9c:	000cb683          	ld	a3,0(s9)
ffffffffc0204ea0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ea2:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204ea6:	40db86b3          	sub	a3,s7,a3
ffffffffc0204eaa:	8699                	srai	a3,a3,0x6
ffffffffc0204eac:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204eae:	67e2                	ld	a5,24(sp)
ffffffffc0204eb0:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204eb4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204eb6:	14b8f863          	bgeu	a7,a1,ffffffffc0205006 <do_execve+0x464>
ffffffffc0204eba:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204ebe:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc0204ec0:	9b32                	add	s6,s6,a2
ffffffffc0204ec2:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204ec4:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204ec6:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204ec8:	379000ef          	jal	ra,ffffffffc0205a40 <memcpy>
            start += size, from += size;
ffffffffc0204ecc:	6622                	ld	a2,8(sp)
ffffffffc0204ece:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc0204ed0:	053b7363          	bgeu	s6,s3,ffffffffc0204f16 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ed4:	6c08                	ld	a0,24(s0)
ffffffffc0204ed6:	866a                	mv	a2,s10
ffffffffc0204ed8:	85d2                	mv	a1,s4
ffffffffc0204eda:	f48fe0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc0204ede:	8baa                	mv	s7,a0
ffffffffc0204ee0:	f545                	bnez	a0,ffffffffc0204e88 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204ee2:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0204ee4:	8522                	mv	a0,s0
ffffffffc0204ee6:	b81fe0ef          	jal	ra,ffffffffc0203a66 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204eea:	8522                	mv	a0,s0
ffffffffc0204eec:	b66ff0ef          	jal	ra,ffffffffc0204252 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204ef0:	8522                	mv	a0,s0
ffffffffc0204ef2:	9d9fe0ef          	jal	ra,ffffffffc02038ca <mm_destroy>
    return ret;
ffffffffc0204ef6:	b705                	j	ffffffffc0204e16 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204ef8:	854a                	mv	a0,s2
ffffffffc0204efa:	b6dfe0ef          	jal	ra,ffffffffc0203a66 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204efe:	854a                	mv	a0,s2
ffffffffc0204f00:	b52ff0ef          	jal	ra,ffffffffc0204252 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204f04:	854a                	mv	a0,s2
ffffffffc0204f06:	9c5fe0ef          	jal	ra,ffffffffc02038ca <mm_destroy>
ffffffffc0204f0a:	b32d                	j	ffffffffc0204c34 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204f0c:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204f10:	fb95                	bnez	a5,ffffffffc0204e44 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204f12:	4d5d                	li	s10,23
ffffffffc0204f14:	bf35                	j	ffffffffc0204e50 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204f16:	01093483          	ld	s1,16(s2)
ffffffffc0204f1a:	02893683          	ld	a3,40(s2)
ffffffffc0204f1e:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204f20:	074b7d63          	bgeu	s6,s4,ffffffffc0204f9a <do_execve+0x3f8>
            if (start == end)
ffffffffc0204f24:	db648fe3          	beq	s1,s6,ffffffffc0204ce2 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204f28:	6785                	lui	a5,0x1
ffffffffc0204f2a:	00fb0533          	add	a0,s6,a5
ffffffffc0204f2e:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0204f32:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204f36:	0b44fd63          	bgeu	s1,s4,ffffffffc0204ff0 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204f3a:	000cb683          	ld	a3,0(s9)
ffffffffc0204f3e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204f40:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204f44:	40db86b3          	sub	a3,s7,a3
ffffffffc0204f48:	8699                	srai	a3,a3,0x6
ffffffffc0204f4a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204f4c:	67e2                	ld	a5,24(sp)
ffffffffc0204f4e:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204f52:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204f54:	0ac5f963          	bgeu	a1,a2,ffffffffc0205006 <do_execve+0x464>
ffffffffc0204f58:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204f5c:	864e                	mv	a2,s3
ffffffffc0204f5e:	4581                	li	a1,0
ffffffffc0204f60:	96c6                	add	a3,a3,a7
ffffffffc0204f62:	9536                	add	a0,a0,a3
ffffffffc0204f64:	2cb000ef          	jal	ra,ffffffffc0205a2e <memset>
            start += size;
ffffffffc0204f68:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204f6c:	0344f463          	bgeu	s1,s4,ffffffffc0204f94 <do_execve+0x3f2>
ffffffffc0204f70:	d6e489e3          	beq	s1,a4,ffffffffc0204ce2 <do_execve+0x140>
ffffffffc0204f74:	00002697          	auipc	a3,0x2
ffffffffc0204f78:	61c68693          	addi	a3,a3,1564 # ffffffffc0207590 <default_pmm_manager+0xcf8>
ffffffffc0204f7c:	00001617          	auipc	a2,0x1
ffffffffc0204f80:	56c60613          	addi	a2,a2,1388 # ffffffffc02064e8 <commands+0x828>
ffffffffc0204f84:	2c500593          	li	a1,709
ffffffffc0204f88:	00002517          	auipc	a0,0x2
ffffffffc0204f8c:	41850513          	addi	a0,a0,1048 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0204f90:	cfefb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204f94:	ff4710e3          	bne	a4,s4,ffffffffc0204f74 <do_execve+0x3d2>
ffffffffc0204f98:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc0204f9a:	d49b74e3          	bgeu	s6,s1,ffffffffc0204ce2 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204f9e:	6c08                	ld	a0,24(s0)
ffffffffc0204fa0:	866a                	mv	a2,s10
ffffffffc0204fa2:	85d2                	mv	a1,s4
ffffffffc0204fa4:	e7efe0ef          	jal	ra,ffffffffc0203622 <pgdir_alloc_page>
ffffffffc0204fa8:	8baa                	mv	s7,a0
ffffffffc0204faa:	dd05                	beqz	a0,ffffffffc0204ee2 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204fac:	6785                	lui	a5,0x1
ffffffffc0204fae:	414b0533          	sub	a0,s6,s4
ffffffffc0204fb2:	9a3e                	add	s4,s4,a5
ffffffffc0204fb4:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204fb8:	0144f463          	bgeu	s1,s4,ffffffffc0204fc0 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204fbc:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc0204fc0:	000cb683          	ld	a3,0(s9)
ffffffffc0204fc4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204fc6:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204fca:	40db86b3          	sub	a3,s7,a3
ffffffffc0204fce:	8699                	srai	a3,a3,0x6
ffffffffc0204fd0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204fd2:	67e2                	ld	a5,24(sp)
ffffffffc0204fd4:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204fd8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204fda:	02b8f663          	bgeu	a7,a1,ffffffffc0205006 <do_execve+0x464>
ffffffffc0204fde:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204fe2:	4581                	li	a1,0
            start += size;
ffffffffc0204fe4:	9b32                	add	s6,s6,a2
ffffffffc0204fe6:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc0204fe8:	9536                	add	a0,a0,a3
ffffffffc0204fea:	245000ef          	jal	ra,ffffffffc0205a2e <memset>
ffffffffc0204fee:	b775                	j	ffffffffc0204f9a <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204ff0:	416a09b3          	sub	s3,s4,s6
ffffffffc0204ff4:	b799                	j	ffffffffc0204f3a <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204ff6:	59f5                	li	s3,-3
ffffffffc0204ff8:	b3c1                	j	ffffffffc0204db8 <do_execve+0x216>
        while (start < end)
ffffffffc0204ffa:	84da                	mv	s1,s6
ffffffffc0204ffc:	bf39                	j	ffffffffc0204f1a <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204ffe:	59f1                	li	s3,-4
ffffffffc0205000:	bdc5                	j	ffffffffc0204ef0 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0205002:	59e1                	li	s3,-8
ffffffffc0205004:	b5c5                	j	ffffffffc0204ee4 <do_execve+0x342>
ffffffffc0205006:	00002617          	auipc	a2,0x2
ffffffffc020500a:	8ca60613          	addi	a2,a2,-1846 # ffffffffc02068d0 <default_pmm_manager+0x38>
ffffffffc020500e:	07100593          	li	a1,113
ffffffffc0205012:	00002517          	auipc	a0,0x2
ffffffffc0205016:	8e650513          	addi	a0,a0,-1818 # ffffffffc02068f8 <default_pmm_manager+0x60>
ffffffffc020501a:	c74fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020501e:	00002617          	auipc	a2,0x2
ffffffffc0205022:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206978 <default_pmm_manager+0xe0>
ffffffffc0205026:	2e400593          	li	a1,740
ffffffffc020502a:	00002517          	auipc	a0,0x2
ffffffffc020502e:	37650513          	addi	a0,a0,886 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0205032:	c5cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205036:	00002697          	auipc	a3,0x2
ffffffffc020503a:	67268693          	addi	a3,a3,1650 # ffffffffc02076a8 <default_pmm_manager+0xe10>
ffffffffc020503e:	00001617          	auipc	a2,0x1
ffffffffc0205042:	4aa60613          	addi	a2,a2,1194 # ffffffffc02064e8 <commands+0x828>
ffffffffc0205046:	2df00593          	li	a1,735
ffffffffc020504a:	00002517          	auipc	a0,0x2
ffffffffc020504e:	35650513          	addi	a0,a0,854 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0205052:	c3cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205056:	00002697          	auipc	a3,0x2
ffffffffc020505a:	60a68693          	addi	a3,a3,1546 # ffffffffc0207660 <default_pmm_manager+0xdc8>
ffffffffc020505e:	00001617          	auipc	a2,0x1
ffffffffc0205062:	48a60613          	addi	a2,a2,1162 # ffffffffc02064e8 <commands+0x828>
ffffffffc0205066:	2de00593          	li	a1,734
ffffffffc020506a:	00002517          	auipc	a0,0x2
ffffffffc020506e:	33650513          	addi	a0,a0,822 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0205072:	c1cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205076:	00002697          	auipc	a3,0x2
ffffffffc020507a:	5a268693          	addi	a3,a3,1442 # ffffffffc0207618 <default_pmm_manager+0xd80>
ffffffffc020507e:	00001617          	auipc	a2,0x1
ffffffffc0205082:	46a60613          	addi	a2,a2,1130 # ffffffffc02064e8 <commands+0x828>
ffffffffc0205086:	2dd00593          	li	a1,733
ffffffffc020508a:	00002517          	auipc	a0,0x2
ffffffffc020508e:	31650513          	addi	a0,a0,790 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0205092:	bfcfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0205096:	00002697          	auipc	a3,0x2
ffffffffc020509a:	53a68693          	addi	a3,a3,1338 # ffffffffc02075d0 <default_pmm_manager+0xd38>
ffffffffc020509e:	00001617          	auipc	a2,0x1
ffffffffc02050a2:	44a60613          	addi	a2,a2,1098 # ffffffffc02064e8 <commands+0x828>
ffffffffc02050a6:	2dc00593          	li	a1,732
ffffffffc02050aa:	00002517          	auipc	a0,0x2
ffffffffc02050ae:	2f650513          	addi	a0,a0,758 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc02050b2:	bdcfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02050b6 <do_yield>:
    current->need_resched = 1;
ffffffffc02050b6:	000a5797          	auipc	a5,0xa5
ffffffffc02050ba:	79a7b783          	ld	a5,1946(a5) # ffffffffc02aa850 <current>
ffffffffc02050be:	4705                	li	a4,1
ffffffffc02050c0:	ef98                	sd	a4,24(a5)
}
ffffffffc02050c2:	4501                	li	a0,0
ffffffffc02050c4:	8082                	ret

ffffffffc02050c6 <do_wait>:
{
ffffffffc02050c6:	1101                	addi	sp,sp,-32
ffffffffc02050c8:	e822                	sd	s0,16(sp)
ffffffffc02050ca:	e426                	sd	s1,8(sp)
ffffffffc02050cc:	ec06                	sd	ra,24(sp)
ffffffffc02050ce:	842e                	mv	s0,a1
ffffffffc02050d0:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc02050d2:	c999                	beqz	a1,ffffffffc02050e8 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc02050d4:	000a5797          	auipc	a5,0xa5
ffffffffc02050d8:	77c7b783          	ld	a5,1916(a5) # ffffffffc02aa850 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc02050dc:	7788                	ld	a0,40(a5)
ffffffffc02050de:	4685                	li	a3,1
ffffffffc02050e0:	4611                	li	a2,4
ffffffffc02050e2:	fcdfe0ef          	jal	ra,ffffffffc02040ae <user_mem_check>
ffffffffc02050e6:	c909                	beqz	a0,ffffffffc02050f8 <do_wait+0x32>
ffffffffc02050e8:	85a2                	mv	a1,s0
}
ffffffffc02050ea:	6442                	ld	s0,16(sp)
ffffffffc02050ec:	60e2                	ld	ra,24(sp)
ffffffffc02050ee:	8526                	mv	a0,s1
ffffffffc02050f0:	64a2                	ld	s1,8(sp)
ffffffffc02050f2:	6105                	addi	sp,sp,32
ffffffffc02050f4:	fb8ff06f          	j	ffffffffc02048ac <do_wait.part.0>
ffffffffc02050f8:	60e2                	ld	ra,24(sp)
ffffffffc02050fa:	6442                	ld	s0,16(sp)
ffffffffc02050fc:	64a2                	ld	s1,8(sp)
ffffffffc02050fe:	5575                	li	a0,-3
ffffffffc0205100:	6105                	addi	sp,sp,32
ffffffffc0205102:	8082                	ret

ffffffffc0205104 <do_kill>:
{
ffffffffc0205104:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0205106:	6789                	lui	a5,0x2
{
ffffffffc0205108:	e406                	sd	ra,8(sp)
ffffffffc020510a:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc020510c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205110:	17f9                	addi	a5,a5,-2
ffffffffc0205112:	02e7e963          	bltu	a5,a4,ffffffffc0205144 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205116:	842a                	mv	s0,a0
ffffffffc0205118:	45a9                	li	a1,10
ffffffffc020511a:	2501                	sext.w	a0,a0
ffffffffc020511c:	46c000ef          	jal	ra,ffffffffc0205588 <hash32>
ffffffffc0205120:	02051793          	slli	a5,a0,0x20
ffffffffc0205124:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205128:	000a1797          	auipc	a5,0xa1
ffffffffc020512c:	6a878793          	addi	a5,a5,1704 # ffffffffc02a67d0 <hash_list>
ffffffffc0205130:	953e                	add	a0,a0,a5
ffffffffc0205132:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0205134:	a029                	j	ffffffffc020513e <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0205136:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020513a:	00870b63          	beq	a4,s0,ffffffffc0205150 <do_kill+0x4c>
ffffffffc020513e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205140:	fef51be3          	bne	a0,a5,ffffffffc0205136 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205144:	5475                	li	s0,-3
}
ffffffffc0205146:	60a2                	ld	ra,8(sp)
ffffffffc0205148:	8522                	mv	a0,s0
ffffffffc020514a:	6402                	ld	s0,0(sp)
ffffffffc020514c:	0141                	addi	sp,sp,16
ffffffffc020514e:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0205150:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205154:	00177693          	andi	a3,a4,1
ffffffffc0205158:	e295                	bnez	a3,ffffffffc020517c <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc020515a:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc020515c:	00176713          	ori	a4,a4,1
ffffffffc0205160:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205164:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205166:	fe06d0e3          	bgez	a3,ffffffffc0205146 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc020516a:	f2878513          	addi	a0,a5,-216
ffffffffc020516e:	22e000ef          	jal	ra,ffffffffc020539c <wakeup_proc>
}
ffffffffc0205172:	60a2                	ld	ra,8(sp)
ffffffffc0205174:	8522                	mv	a0,s0
ffffffffc0205176:	6402                	ld	s0,0(sp)
ffffffffc0205178:	0141                	addi	sp,sp,16
ffffffffc020517a:	8082                	ret
        return -E_KILLED;
ffffffffc020517c:	545d                	li	s0,-9
ffffffffc020517e:	b7e1                	j	ffffffffc0205146 <do_kill+0x42>

ffffffffc0205180 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205180:	1101                	addi	sp,sp,-32
ffffffffc0205182:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205184:	000a5797          	auipc	a5,0xa5
ffffffffc0205188:	64c78793          	addi	a5,a5,1612 # ffffffffc02aa7d0 <proc_list>
ffffffffc020518c:	ec06                	sd	ra,24(sp)
ffffffffc020518e:	e822                	sd	s0,16(sp)
ffffffffc0205190:	e04a                	sd	s2,0(sp)
ffffffffc0205192:	000a1497          	auipc	s1,0xa1
ffffffffc0205196:	63e48493          	addi	s1,s1,1598 # ffffffffc02a67d0 <hash_list>
ffffffffc020519a:	e79c                	sd	a5,8(a5)
ffffffffc020519c:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020519e:	000a5717          	auipc	a4,0xa5
ffffffffc02051a2:	63270713          	addi	a4,a4,1586 # ffffffffc02aa7d0 <proc_list>
ffffffffc02051a6:	87a6                	mv	a5,s1
ffffffffc02051a8:	e79c                	sd	a5,8(a5)
ffffffffc02051aa:	e39c                	sd	a5,0(a5)
ffffffffc02051ac:	07c1                	addi	a5,a5,16
ffffffffc02051ae:	fef71de3          	bne	a4,a5,ffffffffc02051a8 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02051b2:	f99fe0ef          	jal	ra,ffffffffc020414a <alloc_proc>
ffffffffc02051b6:	000a5917          	auipc	s2,0xa5
ffffffffc02051ba:	6a290913          	addi	s2,s2,1698 # ffffffffc02aa858 <idleproc>
ffffffffc02051be:	00a93023          	sd	a0,0(s2)
ffffffffc02051c2:	0e050f63          	beqz	a0,ffffffffc02052c0 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02051c6:	4789                	li	a5,2
ffffffffc02051c8:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02051ca:	00003797          	auipc	a5,0x3
ffffffffc02051ce:	e3678793          	addi	a5,a5,-458 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02051d2:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02051d6:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc02051d8:	4785                	li	a5,1
ffffffffc02051da:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02051dc:	4641                	li	a2,16
ffffffffc02051de:	4581                	li	a1,0
ffffffffc02051e0:	8522                	mv	a0,s0
ffffffffc02051e2:	04d000ef          	jal	ra,ffffffffc0205a2e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02051e6:	463d                	li	a2,15
ffffffffc02051e8:	00002597          	auipc	a1,0x2
ffffffffc02051ec:	52058593          	addi	a1,a1,1312 # ffffffffc0207708 <default_pmm_manager+0xe70>
ffffffffc02051f0:	8522                	mv	a0,s0
ffffffffc02051f2:	04f000ef          	jal	ra,ffffffffc0205a40 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02051f6:	000a5717          	auipc	a4,0xa5
ffffffffc02051fa:	67270713          	addi	a4,a4,1650 # ffffffffc02aa868 <nr_process>
ffffffffc02051fe:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205200:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205204:	4601                	li	a2,0
    nr_process++;
ffffffffc0205206:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205208:	4581                	li	a1,0
ffffffffc020520a:	00000517          	auipc	a0,0x0
ffffffffc020520e:	87450513          	addi	a0,a0,-1932 # ffffffffc0204a7e <init_main>
    nr_process++;
ffffffffc0205212:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205214:	000a5797          	auipc	a5,0xa5
ffffffffc0205218:	62d7be23          	sd	a3,1596(a5) # ffffffffc02aa850 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020521c:	cf6ff0ef          	jal	ra,ffffffffc0204712 <kernel_thread>
ffffffffc0205220:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205222:	08a05363          	blez	a0,ffffffffc02052a8 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205226:	6789                	lui	a5,0x2
ffffffffc0205228:	fff5071b          	addiw	a4,a0,-1
ffffffffc020522c:	17f9                	addi	a5,a5,-2
ffffffffc020522e:	2501                	sext.w	a0,a0
ffffffffc0205230:	02e7e363          	bltu	a5,a4,ffffffffc0205256 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205234:	45a9                	li	a1,10
ffffffffc0205236:	352000ef          	jal	ra,ffffffffc0205588 <hash32>
ffffffffc020523a:	02051793          	slli	a5,a0,0x20
ffffffffc020523e:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205242:	96a6                	add	a3,a3,s1
ffffffffc0205244:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205246:	a029                	j	ffffffffc0205250 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205248:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c94>
ffffffffc020524c:	04870b63          	beq	a4,s0,ffffffffc02052a2 <proc_init+0x122>
    return listelm->next;
ffffffffc0205250:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205252:	fef69be3          	bne	a3,a5,ffffffffc0205248 <proc_init+0xc8>
    return NULL;
ffffffffc0205256:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205258:	0b478493          	addi	s1,a5,180
ffffffffc020525c:	4641                	li	a2,16
ffffffffc020525e:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205260:	000a5417          	auipc	s0,0xa5
ffffffffc0205264:	60040413          	addi	s0,s0,1536 # ffffffffc02aa860 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205268:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020526a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020526c:	7c2000ef          	jal	ra,ffffffffc0205a2e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205270:	463d                	li	a2,15
ffffffffc0205272:	00002597          	auipc	a1,0x2
ffffffffc0205276:	4be58593          	addi	a1,a1,1214 # ffffffffc0207730 <default_pmm_manager+0xe98>
ffffffffc020527a:	8526                	mv	a0,s1
ffffffffc020527c:	7c4000ef          	jal	ra,ffffffffc0205a40 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205280:	00093783          	ld	a5,0(s2)
ffffffffc0205284:	cbb5                	beqz	a5,ffffffffc02052f8 <proc_init+0x178>
ffffffffc0205286:	43dc                	lw	a5,4(a5)
ffffffffc0205288:	eba5                	bnez	a5,ffffffffc02052f8 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020528a:	601c                	ld	a5,0(s0)
ffffffffc020528c:	c7b1                	beqz	a5,ffffffffc02052d8 <proc_init+0x158>
ffffffffc020528e:	43d8                	lw	a4,4(a5)
ffffffffc0205290:	4785                	li	a5,1
ffffffffc0205292:	04f71363          	bne	a4,a5,ffffffffc02052d8 <proc_init+0x158>
}
ffffffffc0205296:	60e2                	ld	ra,24(sp)
ffffffffc0205298:	6442                	ld	s0,16(sp)
ffffffffc020529a:	64a2                	ld	s1,8(sp)
ffffffffc020529c:	6902                	ld	s2,0(sp)
ffffffffc020529e:	6105                	addi	sp,sp,32
ffffffffc02052a0:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02052a2:	f2878793          	addi	a5,a5,-216
ffffffffc02052a6:	bf4d                	j	ffffffffc0205258 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02052a8:	00002617          	auipc	a2,0x2
ffffffffc02052ac:	46860613          	addi	a2,a2,1128 # ffffffffc0207710 <default_pmm_manager+0xe78>
ffffffffc02052b0:	40600593          	li	a1,1030
ffffffffc02052b4:	00002517          	auipc	a0,0x2
ffffffffc02052b8:	0ec50513          	addi	a0,a0,236 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc02052bc:	9d2fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02052c0:	00002617          	auipc	a2,0x2
ffffffffc02052c4:	43060613          	addi	a2,a2,1072 # ffffffffc02076f0 <default_pmm_manager+0xe58>
ffffffffc02052c8:	3f700593          	li	a1,1015
ffffffffc02052cc:	00002517          	auipc	a0,0x2
ffffffffc02052d0:	0d450513          	addi	a0,a0,212 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc02052d4:	9bafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02052d8:	00002697          	auipc	a3,0x2
ffffffffc02052dc:	48868693          	addi	a3,a3,1160 # ffffffffc0207760 <default_pmm_manager+0xec8>
ffffffffc02052e0:	00001617          	auipc	a2,0x1
ffffffffc02052e4:	20860613          	addi	a2,a2,520 # ffffffffc02064e8 <commands+0x828>
ffffffffc02052e8:	40d00593          	li	a1,1037
ffffffffc02052ec:	00002517          	auipc	a0,0x2
ffffffffc02052f0:	0b450513          	addi	a0,a0,180 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc02052f4:	99afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02052f8:	00002697          	auipc	a3,0x2
ffffffffc02052fc:	44068693          	addi	a3,a3,1088 # ffffffffc0207738 <default_pmm_manager+0xea0>
ffffffffc0205300:	00001617          	auipc	a2,0x1
ffffffffc0205304:	1e860613          	addi	a2,a2,488 # ffffffffc02064e8 <commands+0x828>
ffffffffc0205308:	40c00593          	li	a1,1036
ffffffffc020530c:	00002517          	auipc	a0,0x2
ffffffffc0205310:	09450513          	addi	a0,a0,148 # ffffffffc02073a0 <default_pmm_manager+0xb08>
ffffffffc0205314:	97afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205318 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205318:	1141                	addi	sp,sp,-16
ffffffffc020531a:	e022                	sd	s0,0(sp)
ffffffffc020531c:	e406                	sd	ra,8(sp)
ffffffffc020531e:	000a5417          	auipc	s0,0xa5
ffffffffc0205322:	53240413          	addi	s0,s0,1330 # ffffffffc02aa850 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205326:	6018                	ld	a4,0(s0)
ffffffffc0205328:	6f1c                	ld	a5,24(a4)
ffffffffc020532a:	dffd                	beqz	a5,ffffffffc0205328 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020532c:	0f0000ef          	jal	ra,ffffffffc020541c <schedule>
ffffffffc0205330:	bfdd                	j	ffffffffc0205326 <cpu_idle+0xe>

ffffffffc0205332 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205332:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205336:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020533a:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020533c:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020533e:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205342:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205346:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020534a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020534e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205352:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205356:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020535a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020535e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205362:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205366:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020536a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020536e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205370:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205372:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205376:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020537a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020537e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205382:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205386:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020538a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020538e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205392:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205396:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020539a:	8082                	ret

ffffffffc020539c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020539c:	4118                	lw	a4,0(a0)
{
ffffffffc020539e:	1101                	addi	sp,sp,-32
ffffffffc02053a0:	ec06                	sd	ra,24(sp)
ffffffffc02053a2:	e822                	sd	s0,16(sp)
ffffffffc02053a4:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02053a6:	478d                	li	a5,3
ffffffffc02053a8:	04f70b63          	beq	a4,a5,ffffffffc02053fe <wakeup_proc+0x62>
ffffffffc02053ac:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02053ae:	100027f3          	csrr	a5,sstatus
ffffffffc02053b2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02053b4:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02053b6:	ef9d                	bnez	a5,ffffffffc02053f4 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02053b8:	4789                	li	a5,2
ffffffffc02053ba:	02f70163          	beq	a4,a5,ffffffffc02053dc <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02053be:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02053c0:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02053c4:	e491                	bnez	s1,ffffffffc02053d0 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02053c6:	60e2                	ld	ra,24(sp)
ffffffffc02053c8:	6442                	ld	s0,16(sp)
ffffffffc02053ca:	64a2                	ld	s1,8(sp)
ffffffffc02053cc:	6105                	addi	sp,sp,32
ffffffffc02053ce:	8082                	ret
ffffffffc02053d0:	6442                	ld	s0,16(sp)
ffffffffc02053d2:	60e2                	ld	ra,24(sp)
ffffffffc02053d4:	64a2                	ld	s1,8(sp)
ffffffffc02053d6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02053d8:	dd6fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02053dc:	00002617          	auipc	a2,0x2
ffffffffc02053e0:	3e460613          	addi	a2,a2,996 # ffffffffc02077c0 <default_pmm_manager+0xf28>
ffffffffc02053e4:	45d1                	li	a1,20
ffffffffc02053e6:	00002517          	auipc	a0,0x2
ffffffffc02053ea:	3c250513          	addi	a0,a0,962 # ffffffffc02077a8 <default_pmm_manager+0xf10>
ffffffffc02053ee:	908fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc02053f2:	bfc9                	j	ffffffffc02053c4 <wakeup_proc+0x28>
        intr_disable();
ffffffffc02053f4:	dc0fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02053f8:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc02053fa:	4485                	li	s1,1
ffffffffc02053fc:	bf75                	j	ffffffffc02053b8 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02053fe:	00002697          	auipc	a3,0x2
ffffffffc0205402:	38a68693          	addi	a3,a3,906 # ffffffffc0207788 <default_pmm_manager+0xef0>
ffffffffc0205406:	00001617          	auipc	a2,0x1
ffffffffc020540a:	0e260613          	addi	a2,a2,226 # ffffffffc02064e8 <commands+0x828>
ffffffffc020540e:	45a5                	li	a1,9
ffffffffc0205410:	00002517          	auipc	a0,0x2
ffffffffc0205414:	39850513          	addi	a0,a0,920 # ffffffffc02077a8 <default_pmm_manager+0xf10>
ffffffffc0205418:	876fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020541c <schedule>:

void schedule(void)
{
ffffffffc020541c:	1141                	addi	sp,sp,-16
ffffffffc020541e:	e406                	sd	ra,8(sp)
ffffffffc0205420:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205422:	100027f3          	csrr	a5,sstatus
ffffffffc0205426:	8b89                	andi	a5,a5,2
ffffffffc0205428:	4401                	li	s0,0
ffffffffc020542a:	efbd                	bnez	a5,ffffffffc02054a8 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020542c:	000a5897          	auipc	a7,0xa5
ffffffffc0205430:	4248b883          	ld	a7,1060(a7) # ffffffffc02aa850 <current>
ffffffffc0205434:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205438:	000a5517          	auipc	a0,0xa5
ffffffffc020543c:	42053503          	ld	a0,1056(a0) # ffffffffc02aa858 <idleproc>
ffffffffc0205440:	04a88e63          	beq	a7,a0,ffffffffc020549c <schedule+0x80>
ffffffffc0205444:	0c888693          	addi	a3,a7,200
ffffffffc0205448:	000a5617          	auipc	a2,0xa5
ffffffffc020544c:	38860613          	addi	a2,a2,904 # ffffffffc02aa7d0 <proc_list>
        le = last;
ffffffffc0205450:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205452:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205454:	4809                	li	a6,2
ffffffffc0205456:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205458:	00c78863          	beq	a5,a2,ffffffffc0205468 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc020545c:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205460:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205464:	03070163          	beq	a4,a6,ffffffffc0205486 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205468:	fef697e3          	bne	a3,a5,ffffffffc0205456 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020546c:	ed89                	bnez	a1,ffffffffc0205486 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020546e:	451c                	lw	a5,8(a0)
ffffffffc0205470:	2785                	addiw	a5,a5,1
ffffffffc0205472:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205474:	00a88463          	beq	a7,a0,ffffffffc020547c <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205478:	e51fe0ef          	jal	ra,ffffffffc02042c8 <proc_run>
    if (flag)
ffffffffc020547c:	e819                	bnez	s0,ffffffffc0205492 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020547e:	60a2                	ld	ra,8(sp)
ffffffffc0205480:	6402                	ld	s0,0(sp)
ffffffffc0205482:	0141                	addi	sp,sp,16
ffffffffc0205484:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205486:	4198                	lw	a4,0(a1)
ffffffffc0205488:	4789                	li	a5,2
ffffffffc020548a:	fef712e3          	bne	a4,a5,ffffffffc020546e <schedule+0x52>
ffffffffc020548e:	852e                	mv	a0,a1
ffffffffc0205490:	bff9                	j	ffffffffc020546e <schedule+0x52>
}
ffffffffc0205492:	6402                	ld	s0,0(sp)
ffffffffc0205494:	60a2                	ld	ra,8(sp)
ffffffffc0205496:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205498:	d16fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020549c:	000a5617          	auipc	a2,0xa5
ffffffffc02054a0:	33460613          	addi	a2,a2,820 # ffffffffc02aa7d0 <proc_list>
ffffffffc02054a4:	86b2                	mv	a3,a2
ffffffffc02054a6:	b76d                	j	ffffffffc0205450 <schedule+0x34>
        intr_disable();
ffffffffc02054a8:	d0cfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02054ac:	4405                	li	s0,1
ffffffffc02054ae:	bfbd                	j	ffffffffc020542c <schedule+0x10>

ffffffffc02054b0 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02054b0:	000a5797          	auipc	a5,0xa5
ffffffffc02054b4:	3a07b783          	ld	a5,928(a5) # ffffffffc02aa850 <current>
}
ffffffffc02054b8:	43c8                	lw	a0,4(a5)
ffffffffc02054ba:	8082                	ret

ffffffffc02054bc <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02054bc:	4501                	li	a0,0
ffffffffc02054be:	8082                	ret

ffffffffc02054c0 <sys_putc>:
    cputchar(c);
ffffffffc02054c0:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02054c2:	1141                	addi	sp,sp,-16
ffffffffc02054c4:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02054c6:	d05fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02054ca:	60a2                	ld	ra,8(sp)
ffffffffc02054cc:	4501                	li	a0,0
ffffffffc02054ce:	0141                	addi	sp,sp,16
ffffffffc02054d0:	8082                	ret

ffffffffc02054d2 <sys_kill>:
    return do_kill(pid);
ffffffffc02054d2:	4108                	lw	a0,0(a0)
ffffffffc02054d4:	c31ff06f          	j	ffffffffc0205104 <do_kill>

ffffffffc02054d8 <sys_yield>:
    return do_yield();
ffffffffc02054d8:	bdfff06f          	j	ffffffffc02050b6 <do_yield>

ffffffffc02054dc <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02054dc:	6d14                	ld	a3,24(a0)
ffffffffc02054de:	6910                	ld	a2,16(a0)
ffffffffc02054e0:	650c                	ld	a1,8(a0)
ffffffffc02054e2:	6108                	ld	a0,0(a0)
ffffffffc02054e4:	ebeff06f          	j	ffffffffc0204ba2 <do_execve>

ffffffffc02054e8 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02054e8:	650c                	ld	a1,8(a0)
ffffffffc02054ea:	4108                	lw	a0,0(a0)
ffffffffc02054ec:	bdbff06f          	j	ffffffffc02050c6 <do_wait>

ffffffffc02054f0 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02054f0:	000a5797          	auipc	a5,0xa5
ffffffffc02054f4:	3607b783          	ld	a5,864(a5) # ffffffffc02aa850 <current>
ffffffffc02054f8:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02054fa:	4501                	li	a0,0
ffffffffc02054fc:	6a0c                	ld	a1,16(a2)
ffffffffc02054fe:	e37fe06f          	j	ffffffffc0204334 <do_fork>

ffffffffc0205502 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205502:	4108                	lw	a0,0(a0)
ffffffffc0205504:	a5eff06f          	j	ffffffffc0204762 <do_exit>

ffffffffc0205508 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205508:	715d                	addi	sp,sp,-80
ffffffffc020550a:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020550c:	000a5497          	auipc	s1,0xa5
ffffffffc0205510:	34448493          	addi	s1,s1,836 # ffffffffc02aa850 <current>
ffffffffc0205514:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205516:	e0a2                	sd	s0,64(sp)
ffffffffc0205518:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020551a:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020551c:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020551e:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205520:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205524:	0327ee63          	bltu	a5,s2,ffffffffc0205560 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205528:	00391713          	slli	a4,s2,0x3
ffffffffc020552c:	00002797          	auipc	a5,0x2
ffffffffc0205530:	2fc78793          	addi	a5,a5,764 # ffffffffc0207828 <syscalls>
ffffffffc0205534:	97ba                	add	a5,a5,a4
ffffffffc0205536:	639c                	ld	a5,0(a5)
ffffffffc0205538:	c785                	beqz	a5,ffffffffc0205560 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020553a:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020553c:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020553e:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205540:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205542:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205544:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205546:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205548:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020554a:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020554c:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020554e:	0028                	addi	a0,sp,8
ffffffffc0205550:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205552:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205554:	e828                	sd	a0,80(s0)
}
ffffffffc0205556:	6406                	ld	s0,64(sp)
ffffffffc0205558:	74e2                	ld	s1,56(sp)
ffffffffc020555a:	7942                	ld	s2,48(sp)
ffffffffc020555c:	6161                	addi	sp,sp,80
ffffffffc020555e:	8082                	ret
    print_trapframe(tf);
ffffffffc0205560:	8522                	mv	a0,s0
ffffffffc0205562:	e42fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205566:	609c                	ld	a5,0(s1)
ffffffffc0205568:	86ca                	mv	a3,s2
ffffffffc020556a:	00002617          	auipc	a2,0x2
ffffffffc020556e:	27660613          	addi	a2,a2,630 # ffffffffc02077e0 <default_pmm_manager+0xf48>
ffffffffc0205572:	43d8                	lw	a4,4(a5)
ffffffffc0205574:	06200593          	li	a1,98
ffffffffc0205578:	0b478793          	addi	a5,a5,180
ffffffffc020557c:	00002517          	auipc	a0,0x2
ffffffffc0205580:	29450513          	addi	a0,a0,660 # ffffffffc0207810 <default_pmm_manager+0xf78>
ffffffffc0205584:	f0bfa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205588 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205588:	9e3707b7          	lui	a5,0x9e370
ffffffffc020558c:	2785                	addiw	a5,a5,1
ffffffffc020558e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205592:	02000793          	li	a5,32
ffffffffc0205596:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205598:	00f5553b          	srlw	a0,a0,a5
ffffffffc020559c:	8082                	ret

ffffffffc020559e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020559e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02055a2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02055a4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02055a8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02055aa:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02055ae:	f022                	sd	s0,32(sp)
ffffffffc02055b0:	ec26                	sd	s1,24(sp)
ffffffffc02055b2:	e84a                	sd	s2,16(sp)
ffffffffc02055b4:	f406                	sd	ra,40(sp)
ffffffffc02055b6:	e44e                	sd	s3,8(sp)
ffffffffc02055b8:	84aa                	mv	s1,a0
ffffffffc02055ba:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02055bc:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02055c0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02055c2:	03067e63          	bgeu	a2,a6,ffffffffc02055fe <printnum+0x60>
ffffffffc02055c6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02055c8:	00805763          	blez	s0,ffffffffc02055d6 <printnum+0x38>
ffffffffc02055cc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02055ce:	85ca                	mv	a1,s2
ffffffffc02055d0:	854e                	mv	a0,s3
ffffffffc02055d2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02055d4:	fc65                	bnez	s0,ffffffffc02055cc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055d6:	1a02                	slli	s4,s4,0x20
ffffffffc02055d8:	00002797          	auipc	a5,0x2
ffffffffc02055dc:	35078793          	addi	a5,a5,848 # ffffffffc0207928 <syscalls+0x100>
ffffffffc02055e0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02055e4:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02055e6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055e8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02055ec:	70a2                	ld	ra,40(sp)
ffffffffc02055ee:	69a2                	ld	s3,8(sp)
ffffffffc02055f0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055f2:	85ca                	mv	a1,s2
ffffffffc02055f4:	87a6                	mv	a5,s1
}
ffffffffc02055f6:	6942                	ld	s2,16(sp)
ffffffffc02055f8:	64e2                	ld	s1,24(sp)
ffffffffc02055fa:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02055fc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02055fe:	03065633          	divu	a2,a2,a6
ffffffffc0205602:	8722                	mv	a4,s0
ffffffffc0205604:	f9bff0ef          	jal	ra,ffffffffc020559e <printnum>
ffffffffc0205608:	b7f9                	j	ffffffffc02055d6 <printnum+0x38>

ffffffffc020560a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020560a:	7119                	addi	sp,sp,-128
ffffffffc020560c:	f4a6                	sd	s1,104(sp)
ffffffffc020560e:	f0ca                	sd	s2,96(sp)
ffffffffc0205610:	ecce                	sd	s3,88(sp)
ffffffffc0205612:	e8d2                	sd	s4,80(sp)
ffffffffc0205614:	e4d6                	sd	s5,72(sp)
ffffffffc0205616:	e0da                	sd	s6,64(sp)
ffffffffc0205618:	fc5e                	sd	s7,56(sp)
ffffffffc020561a:	f06a                	sd	s10,32(sp)
ffffffffc020561c:	fc86                	sd	ra,120(sp)
ffffffffc020561e:	f8a2                	sd	s0,112(sp)
ffffffffc0205620:	f862                	sd	s8,48(sp)
ffffffffc0205622:	f466                	sd	s9,40(sp)
ffffffffc0205624:	ec6e                	sd	s11,24(sp)
ffffffffc0205626:	892a                	mv	s2,a0
ffffffffc0205628:	84ae                	mv	s1,a1
ffffffffc020562a:	8d32                	mv	s10,a2
ffffffffc020562c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020562e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205632:	5b7d                	li	s6,-1
ffffffffc0205634:	00002a97          	auipc	s5,0x2
ffffffffc0205638:	320a8a93          	addi	s5,s5,800 # ffffffffc0207954 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020563c:	00002b97          	auipc	s7,0x2
ffffffffc0205640:	534b8b93          	addi	s7,s7,1332 # ffffffffc0207b70 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205644:	000d4503          	lbu	a0,0(s10)
ffffffffc0205648:	001d0413          	addi	s0,s10,1
ffffffffc020564c:	01350a63          	beq	a0,s3,ffffffffc0205660 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205650:	c121                	beqz	a0,ffffffffc0205690 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205652:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205654:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205656:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205658:	fff44503          	lbu	a0,-1(s0)
ffffffffc020565c:	ff351ae3          	bne	a0,s3,ffffffffc0205650 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205660:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205664:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205668:	4c81                	li	s9,0
ffffffffc020566a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020566c:	5c7d                	li	s8,-1
ffffffffc020566e:	5dfd                	li	s11,-1
ffffffffc0205670:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205674:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205676:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020567a:	0ff5f593          	zext.b	a1,a1
ffffffffc020567e:	00140d13          	addi	s10,s0,1
ffffffffc0205682:	04b56263          	bltu	a0,a1,ffffffffc02056c6 <vprintfmt+0xbc>
ffffffffc0205686:	058a                	slli	a1,a1,0x2
ffffffffc0205688:	95d6                	add	a1,a1,s5
ffffffffc020568a:	4194                	lw	a3,0(a1)
ffffffffc020568c:	96d6                	add	a3,a3,s5
ffffffffc020568e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205690:	70e6                	ld	ra,120(sp)
ffffffffc0205692:	7446                	ld	s0,112(sp)
ffffffffc0205694:	74a6                	ld	s1,104(sp)
ffffffffc0205696:	7906                	ld	s2,96(sp)
ffffffffc0205698:	69e6                	ld	s3,88(sp)
ffffffffc020569a:	6a46                	ld	s4,80(sp)
ffffffffc020569c:	6aa6                	ld	s5,72(sp)
ffffffffc020569e:	6b06                	ld	s6,64(sp)
ffffffffc02056a0:	7be2                	ld	s7,56(sp)
ffffffffc02056a2:	7c42                	ld	s8,48(sp)
ffffffffc02056a4:	7ca2                	ld	s9,40(sp)
ffffffffc02056a6:	7d02                	ld	s10,32(sp)
ffffffffc02056a8:	6de2                	ld	s11,24(sp)
ffffffffc02056aa:	6109                	addi	sp,sp,128
ffffffffc02056ac:	8082                	ret
            padc = '0';
ffffffffc02056ae:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02056b0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056b4:	846a                	mv	s0,s10
ffffffffc02056b6:	00140d13          	addi	s10,s0,1
ffffffffc02056ba:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02056be:	0ff5f593          	zext.b	a1,a1
ffffffffc02056c2:	fcb572e3          	bgeu	a0,a1,ffffffffc0205686 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02056c6:	85a6                	mv	a1,s1
ffffffffc02056c8:	02500513          	li	a0,37
ffffffffc02056cc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02056ce:	fff44783          	lbu	a5,-1(s0)
ffffffffc02056d2:	8d22                	mv	s10,s0
ffffffffc02056d4:	f73788e3          	beq	a5,s3,ffffffffc0205644 <vprintfmt+0x3a>
ffffffffc02056d8:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02056dc:	1d7d                	addi	s10,s10,-1
ffffffffc02056de:	ff379de3          	bne	a5,s3,ffffffffc02056d8 <vprintfmt+0xce>
ffffffffc02056e2:	b78d                	j	ffffffffc0205644 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02056e4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02056e8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056ec:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02056ee:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02056f2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02056f6:	02d86463          	bltu	a6,a3,ffffffffc020571e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02056fa:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02056fe:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205702:	0186873b          	addw	a4,a3,s8
ffffffffc0205706:	0017171b          	slliw	a4,a4,0x1
ffffffffc020570a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020570c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205710:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205712:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205716:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020571a:	fed870e3          	bgeu	a6,a3,ffffffffc02056fa <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020571e:	f40ddce3          	bgez	s11,ffffffffc0205676 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205722:	8de2                	mv	s11,s8
ffffffffc0205724:	5c7d                	li	s8,-1
ffffffffc0205726:	bf81                	j	ffffffffc0205676 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205728:	fffdc693          	not	a3,s11
ffffffffc020572c:	96fd                	srai	a3,a3,0x3f
ffffffffc020572e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205732:	00144603          	lbu	a2,1(s0)
ffffffffc0205736:	2d81                	sext.w	s11,s11
ffffffffc0205738:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020573a:	bf35                	j	ffffffffc0205676 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020573c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205740:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205744:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205746:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205748:	bfd9                	j	ffffffffc020571e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020574a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020574c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205750:	01174463          	blt	a4,a7,ffffffffc0205758 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205754:	1a088e63          	beqz	a7,ffffffffc0205910 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205758:	000a3603          	ld	a2,0(s4)
ffffffffc020575c:	46c1                	li	a3,16
ffffffffc020575e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205760:	2781                	sext.w	a5,a5
ffffffffc0205762:	876e                	mv	a4,s11
ffffffffc0205764:	85a6                	mv	a1,s1
ffffffffc0205766:	854a                	mv	a0,s2
ffffffffc0205768:	e37ff0ef          	jal	ra,ffffffffc020559e <printnum>
            break;
ffffffffc020576c:	bde1                	j	ffffffffc0205644 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020576e:	000a2503          	lw	a0,0(s4)
ffffffffc0205772:	85a6                	mv	a1,s1
ffffffffc0205774:	0a21                	addi	s4,s4,8
ffffffffc0205776:	9902                	jalr	s2
            break;
ffffffffc0205778:	b5f1                	j	ffffffffc0205644 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020577a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020577c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205780:	01174463          	blt	a4,a7,ffffffffc0205788 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205784:	18088163          	beqz	a7,ffffffffc0205906 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205788:	000a3603          	ld	a2,0(s4)
ffffffffc020578c:	46a9                	li	a3,10
ffffffffc020578e:	8a2e                	mv	s4,a1
ffffffffc0205790:	bfc1                	j	ffffffffc0205760 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205792:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205796:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205798:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020579a:	bdf1                	j	ffffffffc0205676 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020579c:	85a6                	mv	a1,s1
ffffffffc020579e:	02500513          	li	a0,37
ffffffffc02057a2:	9902                	jalr	s2
            break;
ffffffffc02057a4:	b545                	j	ffffffffc0205644 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02057a6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02057aa:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02057ac:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02057ae:	b5e1                	j	ffffffffc0205676 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02057b0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02057b2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02057b6:	01174463          	blt	a4,a7,ffffffffc02057be <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02057ba:	14088163          	beqz	a7,ffffffffc02058fc <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02057be:	000a3603          	ld	a2,0(s4)
ffffffffc02057c2:	46a1                	li	a3,8
ffffffffc02057c4:	8a2e                	mv	s4,a1
ffffffffc02057c6:	bf69                	j	ffffffffc0205760 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02057c8:	03000513          	li	a0,48
ffffffffc02057cc:	85a6                	mv	a1,s1
ffffffffc02057ce:	e03e                	sd	a5,0(sp)
ffffffffc02057d0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02057d2:	85a6                	mv	a1,s1
ffffffffc02057d4:	07800513          	li	a0,120
ffffffffc02057d8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02057da:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02057dc:	6782                	ld	a5,0(sp)
ffffffffc02057de:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02057e0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02057e4:	bfb5                	j	ffffffffc0205760 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02057e6:	000a3403          	ld	s0,0(s4)
ffffffffc02057ea:	008a0713          	addi	a4,s4,8
ffffffffc02057ee:	e03a                	sd	a4,0(sp)
ffffffffc02057f0:	14040263          	beqz	s0,ffffffffc0205934 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02057f4:	0fb05763          	blez	s11,ffffffffc02058e2 <vprintfmt+0x2d8>
ffffffffc02057f8:	02d00693          	li	a3,45
ffffffffc02057fc:	0cd79163          	bne	a5,a3,ffffffffc02058be <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205800:	00044783          	lbu	a5,0(s0)
ffffffffc0205804:	0007851b          	sext.w	a0,a5
ffffffffc0205808:	cf85                	beqz	a5,ffffffffc0205840 <vprintfmt+0x236>
ffffffffc020580a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020580e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205812:	000c4563          	bltz	s8,ffffffffc020581c <vprintfmt+0x212>
ffffffffc0205816:	3c7d                	addiw	s8,s8,-1
ffffffffc0205818:	036c0263          	beq	s8,s6,ffffffffc020583c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020581c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020581e:	0e0c8e63          	beqz	s9,ffffffffc020591a <vprintfmt+0x310>
ffffffffc0205822:	3781                	addiw	a5,a5,-32
ffffffffc0205824:	0ef47b63          	bgeu	s0,a5,ffffffffc020591a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205828:	03f00513          	li	a0,63
ffffffffc020582c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020582e:	000a4783          	lbu	a5,0(s4)
ffffffffc0205832:	3dfd                	addiw	s11,s11,-1
ffffffffc0205834:	0a05                	addi	s4,s4,1
ffffffffc0205836:	0007851b          	sext.w	a0,a5
ffffffffc020583a:	ffe1                	bnez	a5,ffffffffc0205812 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020583c:	01b05963          	blez	s11,ffffffffc020584e <vprintfmt+0x244>
ffffffffc0205840:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205842:	85a6                	mv	a1,s1
ffffffffc0205844:	02000513          	li	a0,32
ffffffffc0205848:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020584a:	fe0d9be3          	bnez	s11,ffffffffc0205840 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020584e:	6a02                	ld	s4,0(sp)
ffffffffc0205850:	bbd5                	j	ffffffffc0205644 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205852:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205854:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205858:	01174463          	blt	a4,a7,ffffffffc0205860 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020585c:	08088d63          	beqz	a7,ffffffffc02058f6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205860:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205864:	0a044d63          	bltz	s0,ffffffffc020591e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205868:	8622                	mv	a2,s0
ffffffffc020586a:	8a66                	mv	s4,s9
ffffffffc020586c:	46a9                	li	a3,10
ffffffffc020586e:	bdcd                	j	ffffffffc0205760 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205870:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205874:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205876:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205878:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020587c:	8fb5                	xor	a5,a5,a3
ffffffffc020587e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205882:	02d74163          	blt	a4,a3,ffffffffc02058a4 <vprintfmt+0x29a>
ffffffffc0205886:	00369793          	slli	a5,a3,0x3
ffffffffc020588a:	97de                	add	a5,a5,s7
ffffffffc020588c:	639c                	ld	a5,0(a5)
ffffffffc020588e:	cb99                	beqz	a5,ffffffffc02058a4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205890:	86be                	mv	a3,a5
ffffffffc0205892:	00000617          	auipc	a2,0x0
ffffffffc0205896:	1ee60613          	addi	a2,a2,494 # ffffffffc0205a80 <etext+0x28>
ffffffffc020589a:	85a6                	mv	a1,s1
ffffffffc020589c:	854a                	mv	a0,s2
ffffffffc020589e:	0ce000ef          	jal	ra,ffffffffc020596c <printfmt>
ffffffffc02058a2:	b34d                	j	ffffffffc0205644 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02058a4:	00002617          	auipc	a2,0x2
ffffffffc02058a8:	0a460613          	addi	a2,a2,164 # ffffffffc0207948 <syscalls+0x120>
ffffffffc02058ac:	85a6                	mv	a1,s1
ffffffffc02058ae:	854a                	mv	a0,s2
ffffffffc02058b0:	0bc000ef          	jal	ra,ffffffffc020596c <printfmt>
ffffffffc02058b4:	bb41                	j	ffffffffc0205644 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02058b6:	00002417          	auipc	s0,0x2
ffffffffc02058ba:	08a40413          	addi	s0,s0,138 # ffffffffc0207940 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02058be:	85e2                	mv	a1,s8
ffffffffc02058c0:	8522                	mv	a0,s0
ffffffffc02058c2:	e43e                	sd	a5,8(sp)
ffffffffc02058c4:	0e2000ef          	jal	ra,ffffffffc02059a6 <strnlen>
ffffffffc02058c8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02058cc:	01b05b63          	blez	s11,ffffffffc02058e2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02058d0:	67a2                	ld	a5,8(sp)
ffffffffc02058d2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02058d6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02058d8:	85a6                	mv	a1,s1
ffffffffc02058da:	8552                	mv	a0,s4
ffffffffc02058dc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02058de:	fe0d9ce3          	bnez	s11,ffffffffc02058d6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02058e2:	00044783          	lbu	a5,0(s0)
ffffffffc02058e6:	00140a13          	addi	s4,s0,1
ffffffffc02058ea:	0007851b          	sext.w	a0,a5
ffffffffc02058ee:	d3a5                	beqz	a5,ffffffffc020584e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02058f0:	05e00413          	li	s0,94
ffffffffc02058f4:	bf39                	j	ffffffffc0205812 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02058f6:	000a2403          	lw	s0,0(s4)
ffffffffc02058fa:	b7ad                	j	ffffffffc0205864 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02058fc:	000a6603          	lwu	a2,0(s4)
ffffffffc0205900:	46a1                	li	a3,8
ffffffffc0205902:	8a2e                	mv	s4,a1
ffffffffc0205904:	bdb1                	j	ffffffffc0205760 <vprintfmt+0x156>
ffffffffc0205906:	000a6603          	lwu	a2,0(s4)
ffffffffc020590a:	46a9                	li	a3,10
ffffffffc020590c:	8a2e                	mv	s4,a1
ffffffffc020590e:	bd89                	j	ffffffffc0205760 <vprintfmt+0x156>
ffffffffc0205910:	000a6603          	lwu	a2,0(s4)
ffffffffc0205914:	46c1                	li	a3,16
ffffffffc0205916:	8a2e                	mv	s4,a1
ffffffffc0205918:	b5a1                	j	ffffffffc0205760 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020591a:	9902                	jalr	s2
ffffffffc020591c:	bf09                	j	ffffffffc020582e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020591e:	85a6                	mv	a1,s1
ffffffffc0205920:	02d00513          	li	a0,45
ffffffffc0205924:	e03e                	sd	a5,0(sp)
ffffffffc0205926:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205928:	6782                	ld	a5,0(sp)
ffffffffc020592a:	8a66                	mv	s4,s9
ffffffffc020592c:	40800633          	neg	a2,s0
ffffffffc0205930:	46a9                	li	a3,10
ffffffffc0205932:	b53d                	j	ffffffffc0205760 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205934:	03b05163          	blez	s11,ffffffffc0205956 <vprintfmt+0x34c>
ffffffffc0205938:	02d00693          	li	a3,45
ffffffffc020593c:	f6d79de3          	bne	a5,a3,ffffffffc02058b6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205940:	00002417          	auipc	s0,0x2
ffffffffc0205944:	00040413          	mv	s0,s0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205948:	02800793          	li	a5,40
ffffffffc020594c:	02800513          	li	a0,40
ffffffffc0205950:	00140a13          	addi	s4,s0,1 # ffffffffc0207941 <syscalls+0x119>
ffffffffc0205954:	bd6d                	j	ffffffffc020580e <vprintfmt+0x204>
ffffffffc0205956:	00002a17          	auipc	s4,0x2
ffffffffc020595a:	feba0a13          	addi	s4,s4,-21 # ffffffffc0207941 <syscalls+0x119>
ffffffffc020595e:	02800513          	li	a0,40
ffffffffc0205962:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205966:	05e00413          	li	s0,94
ffffffffc020596a:	b565                	j	ffffffffc0205812 <vprintfmt+0x208>

ffffffffc020596c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020596c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020596e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205972:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205974:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205976:	ec06                	sd	ra,24(sp)
ffffffffc0205978:	f83a                	sd	a4,48(sp)
ffffffffc020597a:	fc3e                	sd	a5,56(sp)
ffffffffc020597c:	e0c2                	sd	a6,64(sp)
ffffffffc020597e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205980:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205982:	c89ff0ef          	jal	ra,ffffffffc020560a <vprintfmt>
}
ffffffffc0205986:	60e2                	ld	ra,24(sp)
ffffffffc0205988:	6161                	addi	sp,sp,80
ffffffffc020598a:	8082                	ret

ffffffffc020598c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020598c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205990:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205992:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205994:	cb81                	beqz	a5,ffffffffc02059a4 <strlen+0x18>
        cnt ++;
ffffffffc0205996:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205998:	00a707b3          	add	a5,a4,a0
ffffffffc020599c:	0007c783          	lbu	a5,0(a5)
ffffffffc02059a0:	fbfd                	bnez	a5,ffffffffc0205996 <strlen+0xa>
ffffffffc02059a2:	8082                	ret
    }
    return cnt;
}
ffffffffc02059a4:	8082                	ret

ffffffffc02059a6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02059a6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02059a8:	e589                	bnez	a1,ffffffffc02059b2 <strnlen+0xc>
ffffffffc02059aa:	a811                	j	ffffffffc02059be <strnlen+0x18>
        cnt ++;
ffffffffc02059ac:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02059ae:	00f58863          	beq	a1,a5,ffffffffc02059be <strnlen+0x18>
ffffffffc02059b2:	00f50733          	add	a4,a0,a5
ffffffffc02059b6:	00074703          	lbu	a4,0(a4)
ffffffffc02059ba:	fb6d                	bnez	a4,ffffffffc02059ac <strnlen+0x6>
ffffffffc02059bc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02059be:	852e                	mv	a0,a1
ffffffffc02059c0:	8082                	ret

ffffffffc02059c2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02059c2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02059c4:	0005c703          	lbu	a4,0(a1)
ffffffffc02059c8:	0785                	addi	a5,a5,1
ffffffffc02059ca:	0585                	addi	a1,a1,1
ffffffffc02059cc:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02059d0:	fb75                	bnez	a4,ffffffffc02059c4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02059d2:	8082                	ret

ffffffffc02059d4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02059d4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059d8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02059dc:	cb89                	beqz	a5,ffffffffc02059ee <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02059de:	0505                	addi	a0,a0,1
ffffffffc02059e0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02059e2:	fee789e3          	beq	a5,a4,ffffffffc02059d4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059e6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02059ea:	9d19                	subw	a0,a0,a4
ffffffffc02059ec:	8082                	ret
ffffffffc02059ee:	4501                	li	a0,0
ffffffffc02059f0:	bfed                	j	ffffffffc02059ea <strcmp+0x16>

ffffffffc02059f2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059f2:	c20d                	beqz	a2,ffffffffc0205a14 <strncmp+0x22>
ffffffffc02059f4:	962e                	add	a2,a2,a1
ffffffffc02059f6:	a031                	j	ffffffffc0205a02 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02059f8:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059fa:	00e79a63          	bne	a5,a4,ffffffffc0205a0e <strncmp+0x1c>
ffffffffc02059fe:	00b60b63          	beq	a2,a1,ffffffffc0205a14 <strncmp+0x22>
ffffffffc0205a02:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205a06:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205a08:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205a0c:	f7f5                	bnez	a5,ffffffffc02059f8 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a0e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205a12:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a14:	4501                	li	a0,0
ffffffffc0205a16:	8082                	ret

ffffffffc0205a18 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205a18:	00054783          	lbu	a5,0(a0)
ffffffffc0205a1c:	c799                	beqz	a5,ffffffffc0205a2a <strchr+0x12>
        if (*s == c) {
ffffffffc0205a1e:	00f58763          	beq	a1,a5,ffffffffc0205a2c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205a22:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205a26:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205a28:	fbfd                	bnez	a5,ffffffffc0205a1e <strchr+0x6>
    }
    return NULL;
ffffffffc0205a2a:	4501                	li	a0,0
}
ffffffffc0205a2c:	8082                	ret

ffffffffc0205a2e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205a2e:	ca01                	beqz	a2,ffffffffc0205a3e <memset+0x10>
ffffffffc0205a30:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205a32:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205a34:	0785                	addi	a5,a5,1
ffffffffc0205a36:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205a3a:	fec79de3          	bne	a5,a2,ffffffffc0205a34 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205a3e:	8082                	ret

ffffffffc0205a40 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205a40:	ca19                	beqz	a2,ffffffffc0205a56 <memcpy+0x16>
ffffffffc0205a42:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205a44:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205a46:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a4a:	0585                	addi	a1,a1,1
ffffffffc0205a4c:	0785                	addi	a5,a5,1
ffffffffc0205a4e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205a52:	fec59ae3          	bne	a1,a2,ffffffffc0205a46 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205a56:	8082                	ret
