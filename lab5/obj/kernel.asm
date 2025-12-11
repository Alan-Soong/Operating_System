
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
ffffffffc020004a:	000b1517          	auipc	a0,0xb1
ffffffffc020004e:	b4650513          	addi	a0,a0,-1210 # ffffffffc02b0b90 <buf>
ffffffffc0200052:	000b5617          	auipc	a2,0xb5
ffffffffc0200056:	ff260613          	addi	a2,a2,-14 # ffffffffc02b5044 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	3db050ef          	jal	ra,ffffffffc0205c3c <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	bfa58593          	addi	a1,a1,-1030 # ffffffffc0205c68 <etext+0x2>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0205c88 <etext+0x22>
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
ffffffffc0200092:	459030ef          	jal	ra,ffffffffc0203cea <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	2f8050ef          	jal	ra,ffffffffc020538e <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	484050ef          	jal	ra,ffffffffc0205526 <cpu_idle>

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
ffffffffc02000c0:	bd450513          	addi	a0,a0,-1068 # ffffffffc0205c90 <etext+0x2a>
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
ffffffffc02000d2:	000b1b97          	auipc	s7,0xb1
ffffffffc02000d6:	abeb8b93          	addi	s7,s7,-1346 # ffffffffc02b0b90 <buf>
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
ffffffffc020012e:	000b1517          	auipc	a0,0xb1
ffffffffc0200132:	a6250513          	addi	a0,a0,-1438 # ffffffffc02b0b90 <buf>
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
ffffffffc0200188:	690050ef          	jal	ra,ffffffffc0205818 <vprintfmt>
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
ffffffffc02001be:	65a050ef          	jal	ra,ffffffffc0205818 <vprintfmt>
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
ffffffffc0200222:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0205c98 <etext+0x32>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	a8450513          	addi	a0,a0,-1404 # ffffffffc0205cb8 <etext+0x52>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00006597          	auipc	a1,0x6
ffffffffc0200244:	a2658593          	addi	a1,a1,-1498 # ffffffffc0205c66 <etext>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	a9050513          	addi	a0,a0,-1392 # ffffffffc0205cd8 <etext+0x72>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000b1597          	auipc	a1,0xb1
ffffffffc0200258:	93c58593          	addi	a1,a1,-1732 # ffffffffc02b0b90 <buf>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0205cf8 <etext+0x92>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000b5597          	auipc	a1,0xb5
ffffffffc020026c:	ddc58593          	addi	a1,a1,-548 # ffffffffc02b5044 <end>
ffffffffc0200270:	00006517          	auipc	a0,0x6
ffffffffc0200274:	aa850513          	addi	a0,a0,-1368 # ffffffffc0205d18 <etext+0xb2>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000b5597          	auipc	a1,0xb5
ffffffffc0200280:	1c758593          	addi	a1,a1,455 # ffffffffc02b5443 <end+0x3ff>
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
ffffffffc02002a2:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0205d38 <etext+0xd2>
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
ffffffffc02002b0:	abc60613          	addi	a2,a2,-1348 # ffffffffc0205d68 <etext+0x102>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00006517          	auipc	a0,0x6
ffffffffc02002bc:	ac850513          	addi	a0,a0,-1336 # ffffffffc0205d80 <etext+0x11a>
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
ffffffffc02002cc:	ad060613          	addi	a2,a2,-1328 # ffffffffc0205d98 <etext+0x132>
ffffffffc02002d0:	00006597          	auipc	a1,0x6
ffffffffc02002d4:	ae858593          	addi	a1,a1,-1304 # ffffffffc0205db8 <etext+0x152>
ffffffffc02002d8:	00006517          	auipc	a0,0x6
ffffffffc02002dc:	ae850513          	addi	a0,a0,-1304 # ffffffffc0205dc0 <etext+0x15a>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00006617          	auipc	a2,0x6
ffffffffc02002ea:	aea60613          	addi	a2,a2,-1302 # ffffffffc0205dd0 <etext+0x16a>
ffffffffc02002ee:	00006597          	auipc	a1,0x6
ffffffffc02002f2:	b0a58593          	addi	a1,a1,-1270 # ffffffffc0205df8 <etext+0x192>
ffffffffc02002f6:	00006517          	auipc	a0,0x6
ffffffffc02002fa:	aca50513          	addi	a0,a0,-1334 # ffffffffc0205dc0 <etext+0x15a>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00006617          	auipc	a2,0x6
ffffffffc0200306:	b0660613          	addi	a2,a2,-1274 # ffffffffc0205e08 <etext+0x1a2>
ffffffffc020030a:	00006597          	auipc	a1,0x6
ffffffffc020030e:	b1e58593          	addi	a1,a1,-1250 # ffffffffc0205e28 <etext+0x1c2>
ffffffffc0200312:	00006517          	auipc	a0,0x6
ffffffffc0200316:	aae50513          	addi	a0,a0,-1362 # ffffffffc0205dc0 <etext+0x15a>
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
ffffffffc0200350:	aec50513          	addi	a0,a0,-1300 # ffffffffc0205e38 <etext+0x1d2>
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
ffffffffc0200372:	af250513          	addi	a0,a0,-1294 # ffffffffc0205e60 <etext+0x1fa>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00006c17          	auipc	s8,0x6
ffffffffc0200388:	b4cc0c13          	addi	s8,s8,-1204 # ffffffffc0205ed0 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00006917          	auipc	s2,0x6
ffffffffc0200390:	afc90913          	addi	s2,s2,-1284 # ffffffffc0205e88 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00006497          	auipc	s1,0x6
ffffffffc0200398:	afc48493          	addi	s1,s1,-1284 # ffffffffc0205e90 <etext+0x22a>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00006b17          	auipc	s6,0x6
ffffffffc02003a2:	afab0b13          	addi	s6,s6,-1286 # ffffffffc0205e98 <etext+0x232>
        argv[argc++] = buf;
ffffffffc02003a6:	00006a17          	auipc	s4,0x6
ffffffffc02003aa:	a12a0a13          	addi	s4,s4,-1518 # ffffffffc0205db8 <etext+0x152>
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
ffffffffc02003cc:	b08d0d13          	addi	s10,s10,-1272 # ffffffffc0205ed0 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	00d050ef          	jal	ra,ffffffffc0205be2 <strcmp>
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
ffffffffc02003ea:	7f8050ef          	jal	ra,ffffffffc0205be2 <strcmp>
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
ffffffffc0200428:	7fe050ef          	jal	ra,ffffffffc0205c26 <strchr>
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
ffffffffc0200466:	7c0050ef          	jal	ra,ffffffffc0205c26 <strchr>
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
ffffffffc0200484:	a3850513          	addi	a0,a0,-1480 # ffffffffc0205eb8 <etext+0x252>
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
ffffffffc020048e:	000b5317          	auipc	t1,0xb5
ffffffffc0200492:	b2a30313          	addi	t1,t1,-1238 # ffffffffc02b4fb8 <is_panic>
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
ffffffffc02004c0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0205f18 <commands+0x48>
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
ffffffffc02004d6:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0207020 <default_pmm_manager+0x578>
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
ffffffffc020050a:	a3250513          	addi	a0,a0,-1486 # ffffffffc0205f38 <commands+0x68>
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
ffffffffc020052a:	afa50513          	addi	a0,a0,-1286 # ffffffffc0207020 <default_pmm_manager+0x578>
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
ffffffffc0200540:	000b5717          	auipc	a4,0xb5
ffffffffc0200544:	a8f73423          	sd	a5,-1400(a4) # ffffffffc02b4fc8 <timebase>
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
ffffffffc0200560:	00006517          	auipc	a0,0x6
ffffffffc0200564:	9f850513          	addi	a0,a0,-1544 # ffffffffc0205f58 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000b5797          	auipc	a5,0xb5
ffffffffc020056c:	a407bc23          	sd	zero,-1448(a5) # ffffffffc02b4fc0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000b5797          	auipc	a5,0xb5
ffffffffc020057a:	a527b783          	ld	a5,-1454(a5) # ffffffffc02b4fc8 <timebase>
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
ffffffffc0200600:	00006517          	auipc	a0,0x6
ffffffffc0200604:	97850513          	addi	a0,a0,-1672 # ffffffffc0205f78 <commands+0xa8>
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
ffffffffc020062e:	00006517          	auipc	a0,0x6
ffffffffc0200632:	95a50513          	addi	a0,a0,-1702 # ffffffffc0205f88 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00006517          	auipc	a0,0x6
ffffffffc0200648:	95450513          	addi	a0,a0,-1708 # ffffffffc0205f98 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00006517          	auipc	a0,0x6
ffffffffc0200658:	95c50513          	addi	a0,a0,-1700 # ffffffffc0205fb0 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe2aea9>
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
ffffffffc020070e:	00006917          	auipc	s2,0x6
ffffffffc0200712:	8f290913          	addi	s2,s2,-1806 # ffffffffc0206000 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00006497          	auipc	s1,0x6
ffffffffc0200720:	8dc48493          	addi	s1,s1,-1828 # ffffffffc0205ff8 <commands+0x128>
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
ffffffffc0200770:	00006517          	auipc	a0,0x6
ffffffffc0200774:	90850513          	addi	a0,a0,-1784 # ffffffffc0206078 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	93450513          	addi	a0,a0,-1740 # ffffffffc02060b0 <commands+0x1e0>
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
ffffffffc02007bc:	00006517          	auipc	a0,0x6
ffffffffc02007c0:	81450513          	addi	a0,a0,-2028 # ffffffffc0205fd0 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	3d0050ef          	jal	ra,ffffffffc0205b9a <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	428050ef          	jal	ra,ffffffffc0205c00 <strncmp>
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
ffffffffc020086e:	374050ef          	jal	ra,ffffffffc0205be2 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	78650513          	addi	a0,a0,1926 # ffffffffc0206008 <commands+0x138>
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
ffffffffc0200954:	6d850513          	addi	a0,a0,1752 # ffffffffc0206028 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	6de50513          	addi	a0,a0,1758 # ffffffffc0206040 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206060 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	73050513          	addi	a0,a0,1840 # ffffffffc02060b0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000b4797          	auipc	a5,0xb4
ffffffffc020098c:	6487b423          	sd	s0,1608(a5) # ffffffffc02b4fd0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000b4797          	auipc	a5,0xb4
ffffffffc0200994:	6567b423          	sd	s6,1608(a5) # ffffffffc02b4fd8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000b4517          	auipc	a0,0xb4
ffffffffc020099e:	63653503          	ld	a0,1590(a0) # ffffffffc02b4fd0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000b4517          	auipc	a0,0xb4
ffffffffc02009a8:	63453503          	ld	a0,1588(a0) # ffffffffc02b4fd8 <memory_size>
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
ffffffffc02009e2:	6ea50513          	addi	a0,a0,1770 # ffffffffc02060c8 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	6f250513          	addi	a0,a0,1778 # ffffffffc02060e0 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	6fc50513          	addi	a0,a0,1788 # ffffffffc02060f8 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	70650513          	addi	a0,a0,1798 # ffffffffc0206110 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	71050513          	addi	a0,a0,1808 # ffffffffc0206128 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	71a50513          	addi	a0,a0,1818 # ffffffffc0206140 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	72450513          	addi	a0,a0,1828 # ffffffffc0206158 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	72e50513          	addi	a0,a0,1838 # ffffffffc0206170 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	73850513          	addi	a0,a0,1848 # ffffffffc0206188 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	74250513          	addi	a0,a0,1858 # ffffffffc02061a0 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	74c50513          	addi	a0,a0,1868 # ffffffffc02061b8 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	75650513          	addi	a0,a0,1878 # ffffffffc02061d0 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	76050513          	addi	a0,a0,1888 # ffffffffc02061e8 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	76a50513          	addi	a0,a0,1898 # ffffffffc0206200 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	77450513          	addi	a0,a0,1908 # ffffffffc0206218 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	77e50513          	addi	a0,a0,1918 # ffffffffc0206230 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	78850513          	addi	a0,a0,1928 # ffffffffc0206248 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	79250513          	addi	a0,a0,1938 # ffffffffc0206260 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	79c50513          	addi	a0,a0,1948 # ffffffffc0206278 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	7a650513          	addi	a0,a0,1958 # ffffffffc0206290 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	7b050513          	addi	a0,a0,1968 # ffffffffc02062a8 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	7ba50513          	addi	a0,a0,1978 # ffffffffc02062c0 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	7c450513          	addi	a0,a0,1988 # ffffffffc02062d8 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	7ce50513          	addi	a0,a0,1998 # ffffffffc02062f0 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	7d850513          	addi	a0,a0,2008 # ffffffffc0206308 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	7e250513          	addi	a0,a0,2018 # ffffffffc0206320 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	7ec50513          	addi	a0,a0,2028 # ffffffffc0206338 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	7f650513          	addi	a0,a0,2038 # ffffffffc0206350 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00006517          	auipc	a0,0x6
ffffffffc0200b6c:	80050513          	addi	a0,a0,-2048 # ffffffffc0206368 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00006517          	auipc	a0,0x6
ffffffffc0200b7a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0206380 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00006517          	auipc	a0,0x6
ffffffffc0200b88:	81450513          	addi	a0,a0,-2028 # ffffffffc0206398 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00006517          	auipc	a0,0x6
ffffffffc0200b9a:	81a50513          	addi	a0,a0,-2022 # ffffffffc02063b0 <commands+0x4e0>
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
ffffffffc0200bac:	00006517          	auipc	a0,0x6
ffffffffc0200bb0:	81c50513          	addi	a0,a0,-2020 # ffffffffc02063c8 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00006517          	auipc	a0,0x6
ffffffffc0200bc8:	81c50513          	addi	a0,a0,-2020 # ffffffffc02063e0 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00006517          	auipc	a0,0x6
ffffffffc0200bd8:	82450513          	addi	a0,a0,-2012 # ffffffffc02063f8 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00006517          	auipc	a0,0x6
ffffffffc0200be8:	82c50513          	addi	a0,a0,-2004 # ffffffffc0206410 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00006517          	auipc	a0,0x6
ffffffffc0200bfc:	82850513          	addi	a0,a0,-2008 # ffffffffc0206420 <commands+0x550>
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
ffffffffc0200c10:	08f76363          	bltu	a4,a5,ffffffffc0200c96 <interrupt_handler+0x90>
ffffffffc0200c14:	00006717          	auipc	a4,0x6
ffffffffc0200c18:	8d470713          	addi	a4,a4,-1836 # ffffffffc02064e8 <commands+0x618>
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
ffffffffc0200c26:	00006517          	auipc	a0,0x6
ffffffffc0200c2a:	87250513          	addi	a0,a0,-1934 # ffffffffc0206498 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00006517          	auipc	a0,0x6
ffffffffc0200c36:	84650513          	addi	a0,a0,-1978 # ffffffffc0206478 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	7fa50513          	addi	a0,a0,2042 # ffffffffc0206438 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00006517          	auipc	a0,0x6
ffffffffc0200c4e:	80e50513          	addi	a0,a0,-2034 # ffffffffc0206458 <commands+0x588>
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
ffffffffc0200c5e:	000b4697          	auipc	a3,0xb4
ffffffffc0200c62:	36268693          	addi	a3,a3,866 # ffffffffc02b4fc0 <ticks>
ffffffffc0200c66:	629c                	ld	a5,0(a3)
ffffffffc0200c68:	06400713          	li	a4,100
ffffffffc0200c6c:	0785                	addi	a5,a5,1
ffffffffc0200c6e:	02e7f733          	remu	a4,a5,a4
ffffffffc0200c72:	e29c                	sd	a5,0(a3)
ffffffffc0200c74:	c315                	beqz	a4,ffffffffc0200c98 <interrupt_handler+0x92>
            print_count++;
            if (print_count == 10) {
                sbi_shutdown(); // 关机
            }
        }
	    if (current != NULL) {
ffffffffc0200c76:	000b4797          	auipc	a5,0xb4
ffffffffc0200c7a:	3b27b783          	ld	a5,946(a5) # ffffffffc02b5028 <current>
ffffffffc0200c7e:	c399                	beqz	a5,ffffffffc0200c84 <interrupt_handler+0x7e>
            current->need_resched = 1;
ffffffffc0200c80:	4705                	li	a4,1
ffffffffc0200c82:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c84:	60a2                	ld	ra,8(sp)
ffffffffc0200c86:	0141                	addi	sp,sp,16
ffffffffc0200c88:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8a:	00006517          	auipc	a0,0x6
ffffffffc0200c8e:	83e50513          	addi	a0,a0,-1986 # ffffffffc02064c8 <commands+0x5f8>
ffffffffc0200c92:	d02ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c96:	b739                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c98:	06400593          	li	a1,100
ffffffffc0200c9c:	00006517          	auipc	a0,0x6
ffffffffc0200ca0:	81c50513          	addi	a0,a0,-2020 # ffffffffc02064b8 <commands+0x5e8>
ffffffffc0200ca4:	cf0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_count++;
ffffffffc0200ca8:	000b4717          	auipc	a4,0xb4
ffffffffc0200cac:	33870713          	addi	a4,a4,824 # ffffffffc02b4fe0 <print_count.0>
ffffffffc0200cb0:	431c                	lw	a5,0(a4)
            if (print_count == 10) {
ffffffffc0200cb2:	46a9                	li	a3,10
            print_count++;
ffffffffc0200cb4:	0017861b          	addiw	a2,a5,1
ffffffffc0200cb8:	c310                	sw	a2,0(a4)
            if (print_count == 10) {
ffffffffc0200cba:	fad61ee3          	bne	a2,a3,ffffffffc0200c76 <interrupt_handler+0x70>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200cbe:	4501                	li	a0,0
ffffffffc0200cc0:	4581                	li	a1,0
ffffffffc0200cc2:	4601                	li	a2,0
ffffffffc0200cc4:	48a1                	li	a7,8
ffffffffc0200cc6:	00000073          	ecall
}
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
ffffffffc0200cde:	00006717          	auipc	a4,0x6
ffffffffc0200ce2:	9ca70713          	addi	a4,a4,-1590 # ffffffffc02066a8 <commands+0x7d8>
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
ffffffffc0200cf0:	00006517          	auipc	a0,0x6
ffffffffc0200cf4:	91050513          	addi	a0,a0,-1776 # ffffffffc0206600 <commands+0x730>
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
ffffffffc0200d0c:	20b0406f          	j	ffffffffc0205716 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d10:	00006517          	auipc	a0,0x6
ffffffffc0200d14:	91050513          	addi	a0,a0,-1776 # ffffffffc0206620 <commands+0x750>
}
ffffffffc0200d18:	6402                	ld	s0,0(sp)
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d1e:	c76ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d22:	00006517          	auipc	a0,0x6
ffffffffc0200d26:	91e50513          	addi	a0,a0,-1762 # ffffffffc0206640 <commands+0x770>
ffffffffc0200d2a:	b7fd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d2c:	00006517          	auipc	a0,0x6
ffffffffc0200d30:	93450513          	addi	a0,a0,-1740 # ffffffffc0206660 <commands+0x790>
ffffffffc0200d34:	c60ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if ((ret = do_pgfault(current->mm, 0, tf->tval)) != 0) {
ffffffffc0200d38:	000b4797          	auipc	a5,0xb4
ffffffffc0200d3c:	2f07b783          	ld	a5,752(a5) # ffffffffc02b5028 <current>
ffffffffc0200d40:	11043603          	ld	a2,272(s0)
ffffffffc0200d44:	7788                	ld	a0,40(a5)
ffffffffc0200d46:	4581                	li	a1,0
ffffffffc0200d48:	2bb020ef          	jal	ra,ffffffffc0203802 <do_pgfault>
ffffffffc0200d4c:	e91d                	bnez	a0,ffffffffc0200d82 <exception_handler+0xb6>
}
ffffffffc0200d4e:	60a2                	ld	ra,8(sp)
ffffffffc0200d50:	6402                	ld	s0,0(sp)
ffffffffc0200d52:	0141                	addi	sp,sp,16
ffffffffc0200d54:	8082                	ret
        cprintf("Load page fault\n");
ffffffffc0200d56:	00006517          	auipc	a0,0x6
ffffffffc0200d5a:	92250513          	addi	a0,a0,-1758 # ffffffffc0206678 <commands+0x7a8>
ffffffffc0200d5e:	bfd9                	j	ffffffffc0200d34 <exception_handler+0x68>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d60:	00006517          	auipc	a0,0x6
ffffffffc0200d64:	93050513          	addi	a0,a0,-1744 # ffffffffc0206690 <commands+0x7c0>
ffffffffc0200d68:	c2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if ((ret = do_pgfault(current->mm, 1, tf->tval)) != 0) {
ffffffffc0200d6c:	000b4797          	auipc	a5,0xb4
ffffffffc0200d70:	2bc7b783          	ld	a5,700(a5) # ffffffffc02b5028 <current>
ffffffffc0200d74:	11043603          	ld	a2,272(s0)
ffffffffc0200d78:	7788                	ld	a0,40(a5)
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	287020ef          	jal	ra,ffffffffc0203802 <do_pgfault>
ffffffffc0200d80:	d579                	beqz	a0,ffffffffc0200d4e <exception_handler+0x82>
}
ffffffffc0200d82:	6402                	ld	s0,0(sp)
ffffffffc0200d84:	60a2                	ld	ra,8(sp)
            do_exit(-E_FAULT);
ffffffffc0200d86:	5569                	li	a0,-6
}
ffffffffc0200d88:	0141                	addi	sp,sp,16
            do_exit(-E_FAULT);
ffffffffc0200d8a:	3e70306f          	j	ffffffffc0204970 <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d8e:	00005517          	auipc	a0,0x5
ffffffffc0200d92:	78a50513          	addi	a0,a0,1930 # ffffffffc0206518 <commands+0x648>
ffffffffc0200d96:	b749                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d98:	00005517          	auipc	a0,0x5
ffffffffc0200d9c:	7a050513          	addi	a0,a0,1952 # ffffffffc0206538 <commands+0x668>
ffffffffc0200da0:	bfa5                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200da2:	00005517          	auipc	a0,0x5
ffffffffc0200da6:	7b650513          	addi	a0,a0,1974 # ffffffffc0206558 <commands+0x688>
ffffffffc0200daa:	b7bd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200dac:	00005517          	auipc	a0,0x5
ffffffffc0200db0:	7c450513          	addi	a0,a0,1988 # ffffffffc0206570 <commands+0x6a0>
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
ffffffffc0200dca:	14d040ef          	jal	ra,ffffffffc0205716 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dce:	000b4797          	auipc	a5,0xb4
ffffffffc0200dd2:	25a7b783          	ld	a5,602(a5) # ffffffffc02b5028 <current>
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
ffffffffc0200dea:	79a50513          	addi	a0,a0,1946 # ffffffffc0206580 <commands+0x6b0>
ffffffffc0200dee:	b72d                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200df0:	00005517          	auipc	a0,0x5
ffffffffc0200df4:	7b050513          	addi	a0,a0,1968 # ffffffffc02065a0 <commands+0x6d0>
ffffffffc0200df8:	b705                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200dfa:	00005517          	auipc	a0,0x5
ffffffffc0200dfe:	7ee50513          	addi	a0,a0,2030 # ffffffffc02065e8 <commands+0x718>
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
ffffffffc0200e12:	7aa60613          	addi	a2,a2,1962 # ffffffffc02065b8 <commands+0x6e8>
ffffffffc0200e16:	0cd00593          	li	a1,205
ffffffffc0200e1a:	00005517          	auipc	a0,0x5
ffffffffc0200e1e:	7b650513          	addi	a0,a0,1974 # ffffffffc02065d0 <commands+0x700>
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
ffffffffc0200e2a:	000b4417          	auipc	s0,0xb4
ffffffffc0200e2e:	1fe40413          	addi	s0,s0,510 # ffffffffc02b5028 <current>
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
ffffffffc0200ea2:	7880406f          	j	ffffffffc020562a <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ea6:	555d                	li	a0,-9
ffffffffc0200ea8:	2c9030ef          	jal	ra,ffffffffc0204970 <do_exit>
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
ffffffffc0201026:	000b0797          	auipc	a5,0xb0
ffffffffc020102a:	f6a78793          	addi	a5,a5,-150 # ffffffffc02b0f90 <free_area>
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
ffffffffc0201038:	000b0517          	auipc	a0,0xb0
ffffffffc020103c:	f6856503          	lwu	a0,-152(a0) # ffffffffc02b0fa0 <free_area+0x10>
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
ffffffffc0201046:	000b0417          	auipc	s0,0xb0
ffffffffc020104a:	f4a40413          	addi	s0,s0,-182 # ffffffffc02b0f90 <free_area>
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
ffffffffc02010d2:	000b4797          	auipc	a5,0xb4
ffffffffc02010d6:	f367b783          	ld	a5,-202(a5) # ffffffffc02b5008 <pages>
ffffffffc02010da:	40fa8733          	sub	a4,s5,a5
ffffffffc02010de:	00007617          	auipc	a2,0x7
ffffffffc02010e2:	eda63603          	ld	a2,-294(a2) # ffffffffc0207fb8 <nbase>
ffffffffc02010e6:	8719                	srai	a4,a4,0x6
ffffffffc02010e8:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010ea:	000b4697          	auipc	a3,0xb4
ffffffffc02010ee:	f166b683          	ld	a3,-234(a3) # ffffffffc02b5000 <npage>
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
ffffffffc0201128:	000b0797          	auipc	a5,0xb0
ffffffffc020112c:	e607ac23          	sw	zero,-392(a5) # ffffffffc02b0fa0 <free_area+0x10>
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
ffffffffc020120a:	000b0797          	auipc	a5,0xb0
ffffffffc020120e:	d807ab23          	sw	zero,-618(a5) # ffffffffc02b0fa0 <free_area+0x10>
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
ffffffffc0201328:	3c468693          	addi	a3,a3,964 # ffffffffc02066e8 <commands+0x818>
ffffffffc020132c:	00005617          	auipc	a2,0x5
ffffffffc0201330:	3cc60613          	addi	a2,a2,972 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201334:	11000593          	li	a1,272
ffffffffc0201338:	00005517          	auipc	a0,0x5
ffffffffc020133c:	3d850513          	addi	a0,a0,984 # ffffffffc0206710 <commands+0x840>
ffffffffc0201340:	94eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201344:	00005697          	auipc	a3,0x5
ffffffffc0201348:	46468693          	addi	a3,a3,1124 # ffffffffc02067a8 <commands+0x8d8>
ffffffffc020134c:	00005617          	auipc	a2,0x5
ffffffffc0201350:	3ac60613          	addi	a2,a2,940 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201354:	0db00593          	li	a1,219
ffffffffc0201358:	00005517          	auipc	a0,0x5
ffffffffc020135c:	3b850513          	addi	a0,a0,952 # ffffffffc0206710 <commands+0x840>
ffffffffc0201360:	92eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201364:	00005697          	auipc	a3,0x5
ffffffffc0201368:	46c68693          	addi	a3,a3,1132 # ffffffffc02067d0 <commands+0x900>
ffffffffc020136c:	00005617          	auipc	a2,0x5
ffffffffc0201370:	38c60613          	addi	a2,a2,908 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201374:	0dc00593          	li	a1,220
ffffffffc0201378:	00005517          	auipc	a0,0x5
ffffffffc020137c:	39850513          	addi	a0,a0,920 # ffffffffc0206710 <commands+0x840>
ffffffffc0201380:	90eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201384:	00005697          	auipc	a3,0x5
ffffffffc0201388:	48c68693          	addi	a3,a3,1164 # ffffffffc0206810 <commands+0x940>
ffffffffc020138c:	00005617          	auipc	a2,0x5
ffffffffc0201390:	36c60613          	addi	a2,a2,876 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201394:	0de00593          	li	a1,222
ffffffffc0201398:	00005517          	auipc	a0,0x5
ffffffffc020139c:	37850513          	addi	a0,a0,888 # ffffffffc0206710 <commands+0x840>
ffffffffc02013a0:	8eeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02013a4:	00005697          	auipc	a3,0x5
ffffffffc02013a8:	4f468693          	addi	a3,a3,1268 # ffffffffc0206898 <commands+0x9c8>
ffffffffc02013ac:	00005617          	auipc	a2,0x5
ffffffffc02013b0:	34c60613          	addi	a2,a2,844 # ffffffffc02066f8 <commands+0x828>
ffffffffc02013b4:	0f700593          	li	a1,247
ffffffffc02013b8:	00005517          	auipc	a0,0x5
ffffffffc02013bc:	35850513          	addi	a0,a0,856 # ffffffffc0206710 <commands+0x840>
ffffffffc02013c0:	8ceff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013c4:	00005697          	auipc	a3,0x5
ffffffffc02013c8:	38468693          	addi	a3,a3,900 # ffffffffc0206748 <commands+0x878>
ffffffffc02013cc:	00005617          	auipc	a2,0x5
ffffffffc02013d0:	32c60613          	addi	a2,a2,812 # ffffffffc02066f8 <commands+0x828>
ffffffffc02013d4:	0f000593          	li	a1,240
ffffffffc02013d8:	00005517          	auipc	a0,0x5
ffffffffc02013dc:	33850513          	addi	a0,a0,824 # ffffffffc0206710 <commands+0x840>
ffffffffc02013e0:	8aeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02013e4:	00005697          	auipc	a3,0x5
ffffffffc02013e8:	4a468693          	addi	a3,a3,1188 # ffffffffc0206888 <commands+0x9b8>
ffffffffc02013ec:	00005617          	auipc	a2,0x5
ffffffffc02013f0:	30c60613          	addi	a2,a2,780 # ffffffffc02066f8 <commands+0x828>
ffffffffc02013f4:	0ee00593          	li	a1,238
ffffffffc02013f8:	00005517          	auipc	a0,0x5
ffffffffc02013fc:	31850513          	addi	a0,a0,792 # ffffffffc0206710 <commands+0x840>
ffffffffc0201400:	88eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201404:	00005697          	auipc	a3,0x5
ffffffffc0201408:	46c68693          	addi	a3,a3,1132 # ffffffffc0206870 <commands+0x9a0>
ffffffffc020140c:	00005617          	auipc	a2,0x5
ffffffffc0201410:	2ec60613          	addi	a2,a2,748 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201414:	0e900593          	li	a1,233
ffffffffc0201418:	00005517          	auipc	a0,0x5
ffffffffc020141c:	2f850513          	addi	a0,a0,760 # ffffffffc0206710 <commands+0x840>
ffffffffc0201420:	86eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201424:	00005697          	auipc	a3,0x5
ffffffffc0201428:	42c68693          	addi	a3,a3,1068 # ffffffffc0206850 <commands+0x980>
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	2cc60613          	addi	a2,a2,716 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201434:	0e000593          	li	a1,224
ffffffffc0201438:	00005517          	auipc	a0,0x5
ffffffffc020143c:	2d850513          	addi	a0,a0,728 # ffffffffc0206710 <commands+0x840>
ffffffffc0201440:	84eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc0201444:	00005697          	auipc	a3,0x5
ffffffffc0201448:	49c68693          	addi	a3,a3,1180 # ffffffffc02068e0 <commands+0xa10>
ffffffffc020144c:	00005617          	auipc	a2,0x5
ffffffffc0201450:	2ac60613          	addi	a2,a2,684 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201454:	11800593          	li	a1,280
ffffffffc0201458:	00005517          	auipc	a0,0x5
ffffffffc020145c:	2b850513          	addi	a0,a0,696 # ffffffffc0206710 <commands+0x840>
ffffffffc0201460:	82eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201464:	00005697          	auipc	a3,0x5
ffffffffc0201468:	46c68693          	addi	a3,a3,1132 # ffffffffc02068d0 <commands+0xa00>
ffffffffc020146c:	00005617          	auipc	a2,0x5
ffffffffc0201470:	28c60613          	addi	a2,a2,652 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201474:	0fd00593          	li	a1,253
ffffffffc0201478:	00005517          	auipc	a0,0x5
ffffffffc020147c:	29850513          	addi	a0,a0,664 # ffffffffc0206710 <commands+0x840>
ffffffffc0201480:	80eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201484:	00005697          	auipc	a3,0x5
ffffffffc0201488:	3ec68693          	addi	a3,a3,1004 # ffffffffc0206870 <commands+0x9a0>
ffffffffc020148c:	00005617          	auipc	a2,0x5
ffffffffc0201490:	26c60613          	addi	a2,a2,620 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201494:	0fb00593          	li	a1,251
ffffffffc0201498:	00005517          	auipc	a0,0x5
ffffffffc020149c:	27850513          	addi	a0,a0,632 # ffffffffc0206710 <commands+0x840>
ffffffffc02014a0:	feffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02014a4:	00005697          	auipc	a3,0x5
ffffffffc02014a8:	40c68693          	addi	a3,a3,1036 # ffffffffc02068b0 <commands+0x9e0>
ffffffffc02014ac:	00005617          	auipc	a2,0x5
ffffffffc02014b0:	24c60613          	addi	a2,a2,588 # ffffffffc02066f8 <commands+0x828>
ffffffffc02014b4:	0fa00593          	li	a1,250
ffffffffc02014b8:	00005517          	auipc	a0,0x5
ffffffffc02014bc:	25850513          	addi	a0,a0,600 # ffffffffc0206710 <commands+0x840>
ffffffffc02014c0:	fcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014c4:	00005697          	auipc	a3,0x5
ffffffffc02014c8:	28468693          	addi	a3,a3,644 # ffffffffc0206748 <commands+0x878>
ffffffffc02014cc:	00005617          	auipc	a2,0x5
ffffffffc02014d0:	22c60613          	addi	a2,a2,556 # ffffffffc02066f8 <commands+0x828>
ffffffffc02014d4:	0d700593          	li	a1,215
ffffffffc02014d8:	00005517          	auipc	a0,0x5
ffffffffc02014dc:	23850513          	addi	a0,a0,568 # ffffffffc0206710 <commands+0x840>
ffffffffc02014e0:	faffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e4:	00005697          	auipc	a3,0x5
ffffffffc02014e8:	38c68693          	addi	a3,a3,908 # ffffffffc0206870 <commands+0x9a0>
ffffffffc02014ec:	00005617          	auipc	a2,0x5
ffffffffc02014f0:	20c60613          	addi	a2,a2,524 # ffffffffc02066f8 <commands+0x828>
ffffffffc02014f4:	0f400593          	li	a1,244
ffffffffc02014f8:	00005517          	auipc	a0,0x5
ffffffffc02014fc:	21850513          	addi	a0,a0,536 # ffffffffc0206710 <commands+0x840>
ffffffffc0201500:	f8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201504:	00005697          	auipc	a3,0x5
ffffffffc0201508:	28468693          	addi	a3,a3,644 # ffffffffc0206788 <commands+0x8b8>
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	1ec60613          	addi	a2,a2,492 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201514:	0f200593          	li	a1,242
ffffffffc0201518:	00005517          	auipc	a0,0x5
ffffffffc020151c:	1f850513          	addi	a0,a0,504 # ffffffffc0206710 <commands+0x840>
ffffffffc0201520:	f6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201524:	00005697          	auipc	a3,0x5
ffffffffc0201528:	24468693          	addi	a3,a3,580 # ffffffffc0206768 <commands+0x898>
ffffffffc020152c:	00005617          	auipc	a2,0x5
ffffffffc0201530:	1cc60613          	addi	a2,a2,460 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201534:	0f100593          	li	a1,241
ffffffffc0201538:	00005517          	auipc	a0,0x5
ffffffffc020153c:	1d850513          	addi	a0,a0,472 # ffffffffc0206710 <commands+0x840>
ffffffffc0201540:	f4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201544:	00005697          	auipc	a3,0x5
ffffffffc0201548:	24468693          	addi	a3,a3,580 # ffffffffc0206788 <commands+0x8b8>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	1ac60613          	addi	a2,a2,428 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201554:	0d900593          	li	a1,217
ffffffffc0201558:	00005517          	auipc	a0,0x5
ffffffffc020155c:	1b850513          	addi	a0,a0,440 # ffffffffc0206710 <commands+0x840>
ffffffffc0201560:	f2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201564:	00005697          	auipc	a3,0x5
ffffffffc0201568:	4cc68693          	addi	a3,a3,1228 # ffffffffc0206a30 <commands+0xb60>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	18c60613          	addi	a2,a2,396 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201574:	14600593          	li	a1,326
ffffffffc0201578:	00005517          	auipc	a0,0x5
ffffffffc020157c:	19850513          	addi	a0,a0,408 # ffffffffc0206710 <commands+0x840>
ffffffffc0201580:	f0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201584:	00005697          	auipc	a3,0x5
ffffffffc0201588:	34c68693          	addi	a3,a3,844 # ffffffffc02068d0 <commands+0xa00>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	16c60613          	addi	a2,a2,364 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201594:	13a00593          	li	a1,314
ffffffffc0201598:	00005517          	auipc	a0,0x5
ffffffffc020159c:	17850513          	addi	a0,a0,376 # ffffffffc0206710 <commands+0x840>
ffffffffc02015a0:	eeffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015a4:	00005697          	auipc	a3,0x5
ffffffffc02015a8:	2cc68693          	addi	a3,a3,716 # ffffffffc0206870 <commands+0x9a0>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	14c60613          	addi	a2,a2,332 # ffffffffc02066f8 <commands+0x828>
ffffffffc02015b4:	13800593          	li	a1,312
ffffffffc02015b8:	00005517          	auipc	a0,0x5
ffffffffc02015bc:	15850513          	addi	a0,a0,344 # ffffffffc0206710 <commands+0x840>
ffffffffc02015c0:	ecffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015c4:	00005697          	auipc	a3,0x5
ffffffffc02015c8:	26c68693          	addi	a3,a3,620 # ffffffffc0206830 <commands+0x960>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	12c60613          	addi	a2,a2,300 # ffffffffc02066f8 <commands+0x828>
ffffffffc02015d4:	0df00593          	li	a1,223
ffffffffc02015d8:	00005517          	auipc	a0,0x5
ffffffffc02015dc:	13850513          	addi	a0,a0,312 # ffffffffc0206710 <commands+0x840>
ffffffffc02015e0:	eaffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015e4:	00005697          	auipc	a3,0x5
ffffffffc02015e8:	40c68693          	addi	a3,a3,1036 # ffffffffc02069f0 <commands+0xb20>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	10c60613          	addi	a2,a2,268 # ffffffffc02066f8 <commands+0x828>
ffffffffc02015f4:	13200593          	li	a1,306
ffffffffc02015f8:	00005517          	auipc	a0,0x5
ffffffffc02015fc:	11850513          	addi	a0,a0,280 # ffffffffc0206710 <commands+0x840>
ffffffffc0201600:	e8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201604:	00005697          	auipc	a3,0x5
ffffffffc0201608:	3cc68693          	addi	a3,a3,972 # ffffffffc02069d0 <commands+0xb00>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	0ec60613          	addi	a2,a2,236 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201614:	13000593          	li	a1,304
ffffffffc0201618:	00005517          	auipc	a0,0x5
ffffffffc020161c:	0f850513          	addi	a0,a0,248 # ffffffffc0206710 <commands+0x840>
ffffffffc0201620:	e6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201624:	00005697          	auipc	a3,0x5
ffffffffc0201628:	38468693          	addi	a3,a3,900 # ffffffffc02069a8 <commands+0xad8>
ffffffffc020162c:	00005617          	auipc	a2,0x5
ffffffffc0201630:	0cc60613          	addi	a2,a2,204 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201634:	12e00593          	li	a1,302
ffffffffc0201638:	00005517          	auipc	a0,0x5
ffffffffc020163c:	0d850513          	addi	a0,a0,216 # ffffffffc0206710 <commands+0x840>
ffffffffc0201640:	e4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201644:	00005697          	auipc	a3,0x5
ffffffffc0201648:	33c68693          	addi	a3,a3,828 # ffffffffc0206980 <commands+0xab0>
ffffffffc020164c:	00005617          	auipc	a2,0x5
ffffffffc0201650:	0ac60613          	addi	a2,a2,172 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201654:	12d00593          	li	a1,301
ffffffffc0201658:	00005517          	auipc	a0,0x5
ffffffffc020165c:	0b850513          	addi	a0,a0,184 # ffffffffc0206710 <commands+0x840>
ffffffffc0201660:	e2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201664:	00005697          	auipc	a3,0x5
ffffffffc0201668:	30c68693          	addi	a3,a3,780 # ffffffffc0206970 <commands+0xaa0>
ffffffffc020166c:	00005617          	auipc	a2,0x5
ffffffffc0201670:	08c60613          	addi	a2,a2,140 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201674:	12800593          	li	a1,296
ffffffffc0201678:	00005517          	auipc	a0,0x5
ffffffffc020167c:	09850513          	addi	a0,a0,152 # ffffffffc0206710 <commands+0x840>
ffffffffc0201680:	e0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201684:	00005697          	auipc	a3,0x5
ffffffffc0201688:	1ec68693          	addi	a3,a3,492 # ffffffffc0206870 <commands+0x9a0>
ffffffffc020168c:	00005617          	auipc	a2,0x5
ffffffffc0201690:	06c60613          	addi	a2,a2,108 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201694:	12700593          	li	a1,295
ffffffffc0201698:	00005517          	auipc	a0,0x5
ffffffffc020169c:	07850513          	addi	a0,a0,120 # ffffffffc0206710 <commands+0x840>
ffffffffc02016a0:	deffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02016a4:	00005697          	auipc	a3,0x5
ffffffffc02016a8:	2ac68693          	addi	a3,a3,684 # ffffffffc0206950 <commands+0xa80>
ffffffffc02016ac:	00005617          	auipc	a2,0x5
ffffffffc02016b0:	04c60613          	addi	a2,a2,76 # ffffffffc02066f8 <commands+0x828>
ffffffffc02016b4:	12600593          	li	a1,294
ffffffffc02016b8:	00005517          	auipc	a0,0x5
ffffffffc02016bc:	05850513          	addi	a0,a0,88 # ffffffffc0206710 <commands+0x840>
ffffffffc02016c0:	dcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016c4:	00005697          	auipc	a3,0x5
ffffffffc02016c8:	25c68693          	addi	a3,a3,604 # ffffffffc0206920 <commands+0xa50>
ffffffffc02016cc:	00005617          	auipc	a2,0x5
ffffffffc02016d0:	02c60613          	addi	a2,a2,44 # ffffffffc02066f8 <commands+0x828>
ffffffffc02016d4:	12500593          	li	a1,293
ffffffffc02016d8:	00005517          	auipc	a0,0x5
ffffffffc02016dc:	03850513          	addi	a0,a0,56 # ffffffffc0206710 <commands+0x840>
ffffffffc02016e0:	daffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016e4:	00005697          	auipc	a3,0x5
ffffffffc02016e8:	22468693          	addi	a3,a3,548 # ffffffffc0206908 <commands+0xa38>
ffffffffc02016ec:	00005617          	auipc	a2,0x5
ffffffffc02016f0:	00c60613          	addi	a2,a2,12 # ffffffffc02066f8 <commands+0x828>
ffffffffc02016f4:	12400593          	li	a1,292
ffffffffc02016f8:	00005517          	auipc	a0,0x5
ffffffffc02016fc:	01850513          	addi	a0,a0,24 # ffffffffc0206710 <commands+0x840>
ffffffffc0201700:	d8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201704:	00005697          	auipc	a3,0x5
ffffffffc0201708:	16c68693          	addi	a3,a3,364 # ffffffffc0206870 <commands+0x9a0>
ffffffffc020170c:	00005617          	auipc	a2,0x5
ffffffffc0201710:	fec60613          	addi	a2,a2,-20 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201714:	11e00593          	li	a1,286
ffffffffc0201718:	00005517          	auipc	a0,0x5
ffffffffc020171c:	ff850513          	addi	a0,a0,-8 # ffffffffc0206710 <commands+0x840>
ffffffffc0201720:	d6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201724:	00005697          	auipc	a3,0x5
ffffffffc0201728:	1cc68693          	addi	a3,a3,460 # ffffffffc02068f0 <commands+0xa20>
ffffffffc020172c:	00005617          	auipc	a2,0x5
ffffffffc0201730:	fcc60613          	addi	a2,a2,-52 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201734:	11900593          	li	a1,281
ffffffffc0201738:	00005517          	auipc	a0,0x5
ffffffffc020173c:	fd850513          	addi	a0,a0,-40 # ffffffffc0206710 <commands+0x840>
ffffffffc0201740:	d4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201744:	00005697          	auipc	a3,0x5
ffffffffc0201748:	2cc68693          	addi	a3,a3,716 # ffffffffc0206a10 <commands+0xb40>
ffffffffc020174c:	00005617          	auipc	a2,0x5
ffffffffc0201750:	fac60613          	addi	a2,a2,-84 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201754:	13700593          	li	a1,311
ffffffffc0201758:	00005517          	auipc	a0,0x5
ffffffffc020175c:	fb850513          	addi	a0,a0,-72 # ffffffffc0206710 <commands+0x840>
ffffffffc0201760:	d2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201764:	00005697          	auipc	a3,0x5
ffffffffc0201768:	2dc68693          	addi	a3,a3,732 # ffffffffc0206a40 <commands+0xb70>
ffffffffc020176c:	00005617          	auipc	a2,0x5
ffffffffc0201770:	f8c60613          	addi	a2,a2,-116 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201774:	14700593          	li	a1,327
ffffffffc0201778:	00005517          	auipc	a0,0x5
ffffffffc020177c:	f9850513          	addi	a0,a0,-104 # ffffffffc0206710 <commands+0x840>
ffffffffc0201780:	d0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201784:	00005697          	auipc	a3,0x5
ffffffffc0201788:	fa468693          	addi	a3,a3,-92 # ffffffffc0206728 <commands+0x858>
ffffffffc020178c:	00005617          	auipc	a2,0x5
ffffffffc0201790:	f6c60613          	addi	a2,a2,-148 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201794:	11300593          	li	a1,275
ffffffffc0201798:	00005517          	auipc	a0,0x5
ffffffffc020179c:	f7850513          	addi	a0,a0,-136 # ffffffffc0206710 <commands+0x840>
ffffffffc02017a0:	ceffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02017a4:	00005697          	auipc	a3,0x5
ffffffffc02017a8:	fc468693          	addi	a3,a3,-60 # ffffffffc0206768 <commands+0x898>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	f4c60613          	addi	a2,a2,-180 # ffffffffc02066f8 <commands+0x828>
ffffffffc02017b4:	0d800593          	li	a1,216
ffffffffc02017b8:	00005517          	auipc	a0,0x5
ffffffffc02017bc:	f5850513          	addi	a0,a0,-168 # ffffffffc0206710 <commands+0x840>
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
ffffffffc0201806:	000af697          	auipc	a3,0xaf
ffffffffc020180a:	78a68693          	addi	a3,a3,1930 # ffffffffc02b0f90 <free_area>
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
ffffffffc02018f4:	16868693          	addi	a3,a3,360 # ffffffffc0206a58 <commands+0xb88>
ffffffffc02018f8:	00005617          	auipc	a2,0x5
ffffffffc02018fc:	e0060613          	addi	a2,a2,-512 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201900:	09400593          	li	a1,148
ffffffffc0201904:	00005517          	auipc	a0,0x5
ffffffffc0201908:	e0c50513          	addi	a0,a0,-500 # ffffffffc0206710 <commands+0x840>
ffffffffc020190c:	b83fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201910:	00005697          	auipc	a3,0x5
ffffffffc0201914:	14068693          	addi	a3,a3,320 # ffffffffc0206a50 <commands+0xb80>
ffffffffc0201918:	00005617          	auipc	a2,0x5
ffffffffc020191c:	de060613          	addi	a2,a2,-544 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201920:	09000593          	li	a1,144
ffffffffc0201924:	00005517          	auipc	a0,0x5
ffffffffc0201928:	dec50513          	addi	a0,a0,-532 # ffffffffc0206710 <commands+0x840>
ffffffffc020192c:	b63fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201930 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201930:	c941                	beqz	a0,ffffffffc02019c0 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201932:	000af597          	auipc	a1,0xaf
ffffffffc0201936:	65e58593          	addi	a1,a1,1630 # ffffffffc02b0f90 <free_area>
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
ffffffffc02019c6:	08e68693          	addi	a3,a3,142 # ffffffffc0206a50 <commands+0xb80>
ffffffffc02019ca:	00005617          	auipc	a2,0x5
ffffffffc02019ce:	d2e60613          	addi	a2,a2,-722 # ffffffffc02066f8 <commands+0x828>
ffffffffc02019d2:	06c00593          	li	a1,108
ffffffffc02019d6:	00005517          	auipc	a0,0x5
ffffffffc02019da:	d3a50513          	addi	a0,a0,-710 # ffffffffc0206710 <commands+0x840>
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
ffffffffc0201a1e:	000af697          	auipc	a3,0xaf
ffffffffc0201a22:	57268693          	addi	a3,a3,1394 # ffffffffc02b0f90 <free_area>
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
ffffffffc0201a98:	fec68693          	addi	a3,a3,-20 # ffffffffc0206a80 <commands+0xbb0>
ffffffffc0201a9c:	00005617          	auipc	a2,0x5
ffffffffc0201aa0:	c5c60613          	addi	a2,a2,-932 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201aa4:	04b00593          	li	a1,75
ffffffffc0201aa8:	00005517          	auipc	a0,0x5
ffffffffc0201aac:	c6850513          	addi	a0,a0,-920 # ffffffffc0206710 <commands+0x840>
ffffffffc0201ab0:	9dffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201ab4:	00005697          	auipc	a3,0x5
ffffffffc0201ab8:	f9c68693          	addi	a3,a3,-100 # ffffffffc0206a50 <commands+0xb80>
ffffffffc0201abc:	00005617          	auipc	a2,0x5
ffffffffc0201ac0:	c3c60613          	addi	a2,a2,-964 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201ac4:	04700593          	li	a1,71
ffffffffc0201ac8:	00005517          	auipc	a0,0x5
ffffffffc0201acc:	c4850513          	addi	a0,a0,-952 # ffffffffc0206710 <commands+0x840>
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
ffffffffc0201aea:	000af617          	auipc	a2,0xaf
ffffffffc0201aee:	09660613          	addi	a2,a2,150 # ffffffffc02b0b80 <slobfree>
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
ffffffffc0201b98:	000b3697          	auipc	a3,0xb3
ffffffffc0201b9c:	4706b683          	ld	a3,1136(a3) # ffffffffc02b5008 <pages>
ffffffffc0201ba0:	8d15                	sub	a0,a0,a3
ffffffffc0201ba2:	8519                	srai	a0,a0,0x6
ffffffffc0201ba4:	00006697          	auipc	a3,0x6
ffffffffc0201ba8:	4146b683          	ld	a3,1044(a3) # ffffffffc0207fb8 <nbase>
ffffffffc0201bac:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201bae:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bb2:	83b1                	srli	a5,a5,0xc
ffffffffc0201bb4:	000b3717          	auipc	a4,0xb3
ffffffffc0201bb8:	44c73703          	ld	a4,1100(a4) # ffffffffc02b5000 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bbc:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bbe:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bd2 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bc2:	000b3697          	auipc	a3,0xb3
ffffffffc0201bc6:	4566b683          	ld	a3,1110(a3) # ffffffffc02b5018 <va_pa_offset>
ffffffffc0201bca:	9536                	add	a0,a0,a3
}
ffffffffc0201bcc:	60a2                	ld	ra,8(sp)
ffffffffc0201bce:	0141                	addi	sp,sp,16
ffffffffc0201bd0:	8082                	ret
ffffffffc0201bd2:	86aa                	mv	a3,a0
ffffffffc0201bd4:	00005617          	auipc	a2,0x5
ffffffffc0201bd8:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0201bdc:	07100593          	li	a1,113
ffffffffc0201be0:	00005517          	auipc	a0,0x5
ffffffffc0201be4:	f2850513          	addi	a0,a0,-216 # ffffffffc0206b08 <default_pmm_manager+0x60>
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
ffffffffc0201c10:	000af917          	auipc	s2,0xaf
ffffffffc0201c14:	f7090913          	addi	s2,s2,-144 # ffffffffc02b0b80 <slobfree>
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
ffffffffc0201cc6:	e5668693          	addi	a3,a3,-426 # ffffffffc0206b18 <default_pmm_manager+0x70>
ffffffffc0201cca:	00005617          	auipc	a2,0x5
ffffffffc0201cce:	a2e60613          	addi	a2,a2,-1490 # ffffffffc02066f8 <commands+0x828>
ffffffffc0201cd2:	06300593          	li	a1,99
ffffffffc0201cd6:	00005517          	auipc	a0,0x5
ffffffffc0201cda:	e6250513          	addi	a0,a0,-414 # ffffffffc0206b38 <default_pmm_manager+0x90>
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
ffffffffc0201ce8:	e6c50513          	addi	a0,a0,-404 # ffffffffc0206b50 <default_pmm_manager+0xa8>
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
ffffffffc0201cf8:	e7450513          	addi	a0,a0,-396 # ffffffffc0206b68 <default_pmm_manager+0xc0>
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
ffffffffc0201d4e:	000b3797          	auipc	a5,0xb3
ffffffffc0201d52:	29a78793          	addi	a5,a5,666 # ffffffffc02b4fe8 <bigblocks>
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
ffffffffc0201d8a:	000b3797          	auipc	a5,0xb3
ffffffffc0201d8e:	25e78793          	addi	a5,a5,606 # ffffffffc02b4fe8 <bigblocks>
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
ffffffffc0201dd0:	000b3797          	auipc	a5,0xb3
ffffffffc0201dd4:	2187b783          	ld	a5,536(a5) # ffffffffc02b4fe8 <bigblocks>
    return 0;
ffffffffc0201dd8:	4601                	li	a2,0
ffffffffc0201dda:	cbad                	beqz	a5,ffffffffc0201e4c <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201ddc:	000b3697          	auipc	a3,0xb3
ffffffffc0201de0:	20c68693          	addi	a3,a3,524 # ffffffffc02b4fe8 <bigblocks>
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
ffffffffc0201e04:	000b3697          	auipc	a3,0xb3
ffffffffc0201e08:	2146b683          	ld	a3,532(a3) # ffffffffc02b5018 <va_pa_offset>
ffffffffc0201e0c:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e0e:	8031                	srli	s0,s0,0xc
ffffffffc0201e10:	000b3797          	auipc	a5,0xb3
ffffffffc0201e14:	1f07b783          	ld	a5,496(a5) # ffffffffc02b5000 <npage>
ffffffffc0201e18:	06f47163          	bgeu	s0,a5,ffffffffc0201e7a <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e1c:	00006517          	auipc	a0,0x6
ffffffffc0201e20:	19c53503          	ld	a0,412(a0) # ffffffffc0207fb8 <nbase>
ffffffffc0201e24:	8c09                	sub	s0,s0,a0
ffffffffc0201e26:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201e28:	000b3517          	auipc	a0,0xb3
ffffffffc0201e2c:	1e053503          	ld	a0,480(a0) # ffffffffc02b5008 <pages>
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
ffffffffc0201e60:	000b3797          	auipc	a5,0xb3
ffffffffc0201e64:	1887b783          	ld	a5,392(a5) # ffffffffc02b4fe8 <bigblocks>
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
ffffffffc0201e7e:	d3660613          	addi	a2,a2,-714 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc0201e82:	06900593          	li	a1,105
ffffffffc0201e86:	00005517          	auipc	a0,0x5
ffffffffc0201e8a:	c8250513          	addi	a0,a0,-894 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0201e8e:	e00fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e92:	86a2                	mv	a3,s0
ffffffffc0201e94:	00005617          	auipc	a2,0x5
ffffffffc0201e98:	cf460613          	addi	a2,a2,-780 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc0201e9c:	07700593          	li	a1,119
ffffffffc0201ea0:	00005517          	auipc	a0,0x5
ffffffffc0201ea4:	c6850513          	addi	a0,a0,-920 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0201ea8:	de6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201eac <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201eac:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201eae:	00005617          	auipc	a2,0x5
ffffffffc0201eb2:	d0260613          	addi	a2,a2,-766 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc0201eb6:	06900593          	li	a1,105
ffffffffc0201eba:	00005517          	auipc	a0,0x5
ffffffffc0201ebe:	c4e50513          	addi	a0,a0,-946 # ffffffffc0206b08 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201ec2:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201ec4:	dcafe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ec8 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201ec8:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201eca:	00005617          	auipc	a2,0x5
ffffffffc0201ece:	d0660613          	addi	a2,a2,-762 # ffffffffc0206bd0 <default_pmm_manager+0x128>
ffffffffc0201ed2:	07f00593          	li	a1,127
ffffffffc0201ed6:	00005517          	auipc	a0,0x5
ffffffffc0201eda:	c3250513          	addi	a0,a0,-974 # ffffffffc0206b08 <default_pmm_manager+0x60>
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
ffffffffc0201eec:	000b3797          	auipc	a5,0xb3
ffffffffc0201ef0:	1247b783          	ld	a5,292(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0201f04:	000b3797          	auipc	a5,0xb3
ffffffffc0201f08:	10c7b783          	ld	a5,268(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0201f2a:	000b3797          	auipc	a5,0xb3
ffffffffc0201f2e:	0e67b783          	ld	a5,230(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0201f46:	000b3797          	auipc	a5,0xb3
ffffffffc0201f4a:	0ca7b783          	ld	a5,202(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0201f6a:	000b3797          	auipc	a5,0xb3
ffffffffc0201f6e:	0a67b783          	ld	a5,166(a5) # ffffffffc02b5010 <pmm_manager>
ffffffffc0201f72:	779c                	ld	a5,40(a5)
ffffffffc0201f74:	8782                	jr	a5
{
ffffffffc0201f76:	1141                	addi	sp,sp,-16
ffffffffc0201f78:	e406                	sd	ra,8(sp)
ffffffffc0201f7a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f7c:	a39fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f80:	000b3797          	auipc	a5,0xb3
ffffffffc0201f84:	0907b783          	ld	a5,144(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0201fc6:	000b3997          	auipc	s3,0xb3
ffffffffc0201fca:	03a98993          	addi	s3,s3,58 # ffffffffc02b5000 <npage>
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
ffffffffc0201fde:	000b3797          	auipc	a5,0xb3
ffffffffc0201fe2:	0327b783          	ld	a5,50(a5) # ffffffffc02b5010 <pmm_manager>
ffffffffc0201fe6:	6f9c                	ld	a5,24(a5)
ffffffffc0201fe8:	4505                	li	a0,1
ffffffffc0201fea:	9782                	jalr	a5
ffffffffc0201fec:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fee:	12040d63          	beqz	s0,ffffffffc0202128 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201ff2:	000b3b17          	auipc	s6,0xb3
ffffffffc0201ff6:	016b0b13          	addi	s6,s6,22 # ffffffffc02b5008 <pages>
ffffffffc0201ffa:	000b3503          	ld	a0,0(s6)
ffffffffc0201ffe:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202002:	000b3997          	auipc	s3,0xb3
ffffffffc0202006:	ffe98993          	addi	s3,s3,-2 # ffffffffc02b5000 <npage>
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
ffffffffc0202026:	000b3797          	auipc	a5,0xb3
ffffffffc020202a:	ff27b783          	ld	a5,-14(a5) # ffffffffc02b5018 <va_pa_offset>
ffffffffc020202e:	6605                	lui	a2,0x1
ffffffffc0202030:	4581                	li	a1,0
ffffffffc0202032:	953e                	add	a0,a0,a5
ffffffffc0202034:	409030ef          	jal	ra,ffffffffc0205c3c <memset>
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
ffffffffc020205e:	000b3a97          	auipc	s5,0xb3
ffffffffc0202062:	fbaa8a93          	addi	s5,s5,-70 # ffffffffc02b5018 <va_pa_offset>
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
ffffffffc020208e:	000b3797          	auipc	a5,0xb3
ffffffffc0202092:	f827b783          	ld	a5,-126(a5) # ffffffffc02b5010 <pmm_manager>
ffffffffc0202096:	6f9c                	ld	a5,24(a5)
ffffffffc0202098:	4505                	li	a0,1
ffffffffc020209a:	9782                	jalr	a5
ffffffffc020209c:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020209e:	c4c9                	beqz	s1,ffffffffc0202128 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020a0:	000b3b17          	auipc	s6,0xb3
ffffffffc02020a4:	f68b0b13          	addi	s6,s6,-152 # ffffffffc02b5008 <pages>
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
ffffffffc02020d6:	367030ef          	jal	ra,ffffffffc0205c3c <memset>
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
ffffffffc0202130:	000b3797          	auipc	a5,0xb3
ffffffffc0202134:	ee07b783          	ld	a5,-288(a5) # ffffffffc02b5010 <pmm_manager>
ffffffffc0202138:	6f9c                	ld	a5,24(a5)
ffffffffc020213a:	4505                	li	a0,1
ffffffffc020213c:	9782                	jalr	a5
ffffffffc020213e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202140:	86ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202144:	b56d                	j	ffffffffc0201fee <get_pte+0x52>
        intr_disable();
ffffffffc0202146:	86ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020214a:	000b3797          	auipc	a5,0xb3
ffffffffc020214e:	ec67b783          	ld	a5,-314(a5) # ffffffffc02b5010 <pmm_manager>
ffffffffc0202152:	6f9c                	ld	a5,24(a5)
ffffffffc0202154:	4505                	li	a0,1
ffffffffc0202156:	9782                	jalr	a5
ffffffffc0202158:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020215a:	855fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020215e:	b781                	j	ffffffffc020209e <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202160:	00005617          	auipc	a2,0x5
ffffffffc0202164:	98060613          	addi	a2,a2,-1664 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0202168:	0fa00593          	li	a1,250
ffffffffc020216c:	00005517          	auipc	a0,0x5
ffffffffc0202170:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202174:	b1afe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202178:	00005617          	auipc	a2,0x5
ffffffffc020217c:	96860613          	addi	a2,a2,-1688 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0202180:	0ed00593          	li	a1,237
ffffffffc0202184:	00005517          	auipc	a0,0x5
ffffffffc0202188:	a7450513          	addi	a0,a0,-1420 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020218c:	b02fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202190:	86aa                	mv	a3,a0
ffffffffc0202192:	00005617          	auipc	a2,0x5
ffffffffc0202196:	94e60613          	addi	a2,a2,-1714 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc020219a:	0e900593          	li	a1,233
ffffffffc020219e:	00005517          	auipc	a0,0x5
ffffffffc02021a2:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02021a6:	ae8fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021aa:	86aa                	mv	a3,a0
ffffffffc02021ac:	00005617          	auipc	a2,0x5
ffffffffc02021b0:	93460613          	addi	a2,a2,-1740 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc02021b4:	0f700593          	li	a1,247
ffffffffc02021b8:	00005517          	auipc	a0,0x5
ffffffffc02021bc:	a4050513          	addi	a0,a0,-1472 # ffffffffc0206bf8 <default_pmm_manager+0x150>
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
ffffffffc02021ee:	000b3717          	auipc	a4,0xb3
ffffffffc02021f2:	e1273703          	ld	a4,-494(a4) # ffffffffc02b5000 <npage>
ffffffffc02021f6:	00e7ff63          	bgeu	a5,a4,ffffffffc0202214 <get_page+0x50>
ffffffffc02021fa:	60a2                	ld	ra,8(sp)
ffffffffc02021fc:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021fe:	fff80537          	lui	a0,0xfff80
ffffffffc0202202:	97aa                	add	a5,a5,a0
ffffffffc0202204:	079a                	slli	a5,a5,0x6
ffffffffc0202206:	000b3517          	auipc	a0,0xb3
ffffffffc020220a:	e0253503          	ld	a0,-510(a0) # ffffffffc02b5008 <pages>
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
ffffffffc0202256:	000b3c97          	auipc	s9,0xb3
ffffffffc020225a:	daac8c93          	addi	s9,s9,-598 # ffffffffc02b5000 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020225e:	000b3c17          	auipc	s8,0xb3
ffffffffc0202262:	daac0c13          	addi	s8,s8,-598 # ffffffffc02b5008 <pages>
ffffffffc0202266:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020226a:	000b3d17          	auipc	s10,0xb3
ffffffffc020226e:	da6d0d13          	addi	s10,s10,-602 # ffffffffc02b5010 <pmm_manager>
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
ffffffffc020231a:	00005697          	auipc	a3,0x5
ffffffffc020231e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0206c08 <default_pmm_manager+0x160>
ffffffffc0202322:	00004617          	auipc	a2,0x4
ffffffffc0202326:	3d660613          	addi	a2,a2,982 # ffffffffc02066f8 <commands+0x828>
ffffffffc020232a:	12000593          	li	a1,288
ffffffffc020232e:	00005517          	auipc	a0,0x5
ffffffffc0202332:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202336:	958fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020233a:	00005697          	auipc	a3,0x5
ffffffffc020233e:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0206c38 <default_pmm_manager+0x190>
ffffffffc0202342:	00004617          	auipc	a2,0x4
ffffffffc0202346:	3b660613          	addi	a2,a2,950 # ffffffffc02066f8 <commands+0x828>
ffffffffc020234a:	12100593          	li	a1,289
ffffffffc020234e:	00005517          	auipc	a0,0x5
ffffffffc0202352:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0206bf8 <default_pmm_manager+0x150>
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
ffffffffc02023b4:	000b3d17          	auipc	s10,0xb3
ffffffffc02023b8:	c4cd0d13          	addi	s10,s10,-948 # ffffffffc02b5000 <npage>
    return KADDR(page2pa(page));
ffffffffc02023bc:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023c0:	000b3717          	auipc	a4,0xb3
ffffffffc02023c4:	c4870713          	addi	a4,a4,-952 # ffffffffc02b5008 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02023c8:	000b3d97          	auipc	s11,0xb3
ffffffffc02023cc:	c48d8d93          	addi	s11,s11,-952 # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0202424:	000b3817          	auipc	a6,0xb3
ffffffffc0202428:	bf480813          	addi	a6,a6,-1036 # ffffffffc02b5018 <va_pa_offset>
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
ffffffffc02024b8:	000b3817          	auipc	a6,0xb3
ffffffffc02024bc:	b6080813          	addi	a6,a6,-1184 # ffffffffc02b5018 <va_pa_offset>
ffffffffc02024c0:	fff80e37          	lui	t3,0xfff80
ffffffffc02024c4:	00080337          	lui	t1,0x80
ffffffffc02024c8:	6885                	lui	a7,0x1
ffffffffc02024ca:	000b3717          	auipc	a4,0xb3
ffffffffc02024ce:	b3e70713          	addi	a4,a4,-1218 # ffffffffc02b5008 <pages>
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
ffffffffc0202502:	000b3717          	auipc	a4,0xb3
ffffffffc0202506:	b0670713          	addi	a4,a4,-1274 # ffffffffc02b5008 <pages>
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
ffffffffc0202550:	000b3717          	auipc	a4,0xb3
ffffffffc0202554:	ab870713          	addi	a4,a4,-1352 # ffffffffc02b5008 <pages>
ffffffffc0202558:	6885                	lui	a7,0x1
ffffffffc020255a:	00080337          	lui	t1,0x80
ffffffffc020255e:	fff80e37          	lui	t3,0xfff80
ffffffffc0202562:	000b3817          	auipc	a6,0xb3
ffffffffc0202566:	ab680813          	addi	a6,a6,-1354 # ffffffffc02b5018 <va_pa_offset>
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
ffffffffc0202586:	000b3717          	auipc	a4,0xb3
ffffffffc020258a:	a8270713          	addi	a4,a4,-1406 # ffffffffc02b5008 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020258e:	00043023          	sd	zero,0(s0)
ffffffffc0202592:	bfb5                	j	ffffffffc020250e <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202594:	00004697          	auipc	a3,0x4
ffffffffc0202598:	67468693          	addi	a3,a3,1652 # ffffffffc0206c08 <default_pmm_manager+0x160>
ffffffffc020259c:	00004617          	auipc	a2,0x4
ffffffffc02025a0:	15c60613          	addi	a2,a2,348 # ffffffffc02066f8 <commands+0x828>
ffffffffc02025a4:	13500593          	li	a1,309
ffffffffc02025a8:	00004517          	auipc	a0,0x4
ffffffffc02025ac:	65050513          	addi	a0,a0,1616 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02025b0:	edffd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025b4:	00004617          	auipc	a2,0x4
ffffffffc02025b8:	52c60613          	addi	a2,a2,1324 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc02025bc:	07100593          	li	a1,113
ffffffffc02025c0:	00004517          	auipc	a0,0x4
ffffffffc02025c4:	54850513          	addi	a0,a0,1352 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02025c8:	ec7fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02025cc:	8e1ff0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025d0:	00004697          	auipc	a3,0x4
ffffffffc02025d4:	66868693          	addi	a3,a3,1640 # ffffffffc0206c38 <default_pmm_manager+0x190>
ffffffffc02025d8:	00004617          	auipc	a2,0x4
ffffffffc02025dc:	12060613          	addi	a2,a2,288 # ffffffffc02066f8 <commands+0x828>
ffffffffc02025e0:	13600593          	li	a1,310
ffffffffc02025e4:	00004517          	auipc	a0,0x4
ffffffffc02025e8:	61450513          	addi	a0,a0,1556 # ffffffffc0206bf8 <default_pmm_manager+0x150>
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
ffffffffc020261a:	000b3717          	auipc	a4,0xb3
ffffffffc020261e:	9e673703          	ld	a4,-1562(a4) # ffffffffc02b5000 <npage>
ffffffffc0202622:	06e7f363          	bgeu	a5,a4,ffffffffc0202688 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202626:	fff80537          	lui	a0,0xfff80
ffffffffc020262a:	97aa                	add	a5,a5,a0
ffffffffc020262c:	079a                	slli	a5,a5,0x6
ffffffffc020262e:	000b3517          	auipc	a0,0xb3
ffffffffc0202632:	9da53503          	ld	a0,-1574(a0) # ffffffffc02b5008 <pages>
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
ffffffffc020265c:	000b3797          	auipc	a5,0xb3
ffffffffc0202660:	9b47b783          	ld	a5,-1612(a5) # ffffffffc02b5010 <pmm_manager>
ffffffffc0202664:	739c                	ld	a5,32(a5)
ffffffffc0202666:	4585                	li	a1,1
ffffffffc0202668:	9782                	jalr	a5
    if (flag)
ffffffffc020266a:	bfe1                	j	ffffffffc0202642 <page_remove+0x52>
        intr_disable();
ffffffffc020266c:	e42a                	sd	a0,8(sp)
ffffffffc020266e:	b46fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202672:	000b3797          	auipc	a5,0xb3
ffffffffc0202676:	99e7b783          	ld	a5,-1634(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc02026be:	000b3717          	auipc	a4,0xb3
ffffffffc02026c2:	94a73703          	ld	a4,-1718(a4) # ffffffffc02b5008 <pages>
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
ffffffffc02026f8:	000b3717          	auipc	a4,0xb3
ffffffffc02026fc:	90873703          	ld	a4,-1784(a4) # ffffffffc02b5000 <npage>
ffffffffc0202700:	06e7ff63          	bgeu	a5,a4,ffffffffc020277e <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202704:	000b3a97          	auipc	s5,0xb3
ffffffffc0202708:	904a8a93          	addi	s5,s5,-1788 # ffffffffc02b5008 <pages>
ffffffffc020270c:	000ab703          	ld	a4,0(s5)
ffffffffc0202710:	fff80937          	lui	s2,0xfff80
ffffffffc0202714:	993e                	add	s2,s2,a5
ffffffffc0202716:	091a                	slli	s2,s2,0x6
ffffffffc0202718:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020271a:	01240c63          	beq	s0,s2,ffffffffc0202732 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020271e:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccafbc>
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
ffffffffc020273e:	000b3797          	auipc	a5,0xb3
ffffffffc0202742:	8d27b783          	ld	a5,-1838(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc020275c:	000b3797          	auipc	a5,0xb3
ffffffffc0202760:	8b47b783          	ld	a5,-1868(a5) # ffffffffc02b5010 <pmm_manager>
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
ffffffffc0202786:	32678793          	addi	a5,a5,806 # ffffffffc0206aa8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020278a:	638c                	ld	a1,0(a5)
{
ffffffffc020278c:	7159                	addi	sp,sp,-112
ffffffffc020278e:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202790:	00004517          	auipc	a0,0x4
ffffffffc0202794:	4c050513          	addi	a0,a0,1216 # ffffffffc0206c50 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202798:	000b3b17          	auipc	s6,0xb3
ffffffffc020279c:	878b0b13          	addi	s6,s6,-1928 # ffffffffc02b5010 <pmm_manager>
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
ffffffffc02027c0:	000b3997          	auipc	s3,0xb3
ffffffffc02027c4:	85898993          	addi	s3,s3,-1960 # ffffffffc02b5018 <va_pa_offset>
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
ffffffffc02027e8:	4a450513          	addi	a0,a0,1188 # ffffffffc0206c88 <default_pmm_manager+0x1e0>
ffffffffc02027ec:	9a9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027f0:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027f4:	fff40693          	addi	a3,s0,-1
ffffffffc02027f8:	864a                	mv	a2,s2
ffffffffc02027fa:	85a6                	mv	a1,s1
ffffffffc02027fc:	00004517          	auipc	a0,0x4
ffffffffc0202800:	4a450513          	addi	a0,a0,1188 # ffffffffc0206ca0 <default_pmm_manager+0x1f8>
ffffffffc0202804:	991fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202808:	c8000737          	lui	a4,0xc8000
ffffffffc020280c:	87a2                	mv	a5,s0
ffffffffc020280e:	54876163          	bltu	a4,s0,ffffffffc0202d50 <pmm_init+0x5ce>
ffffffffc0202812:	757d                	lui	a0,0xfffff
ffffffffc0202814:	000b4617          	auipc	a2,0xb4
ffffffffc0202818:	82f60613          	addi	a2,a2,-2001 # ffffffffc02b6043 <end+0xfff>
ffffffffc020281c:	8e69                	and	a2,a2,a0
ffffffffc020281e:	000b2497          	auipc	s1,0xb2
ffffffffc0202822:	7e248493          	addi	s1,s1,2018 # ffffffffc02b5000 <npage>
ffffffffc0202826:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020282a:	000b2b97          	auipc	s7,0xb2
ffffffffc020282e:	7deb8b93          	addi	s7,s7,2014 # ffffffffc02b5008 <pages>
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
ffffffffc0202850:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd49fc4>
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
ffffffffc0202888:	44450513          	addi	a0,a0,1092 # ffffffffc0206cc8 <default_pmm_manager+0x220>
ffffffffc020288c:	909fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202890:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202894:	000b2917          	auipc	s2,0xb2
ffffffffc0202898:	76490913          	addi	s2,s2,1892 # ffffffffc02b4ff8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020289c:	7b9c                	ld	a5,48(a5)
ffffffffc020289e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028a0:	00004517          	auipc	a0,0x4
ffffffffc02028a4:	44050513          	addi	a0,a0,1088 # ffffffffc0206ce0 <default_pmm_manager+0x238>
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
ffffffffc02028c6:	000b2797          	auipc	a5,0xb2
ffffffffc02028ca:	72d7b523          	sd	a3,1834(a5) # ffffffffc02b4ff0 <boot_pgdir_pa>
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
ffffffffc0202b36:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd49fbc>
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
ffffffffc0202b5a:	4b250513          	addi	a0,a0,1202 # ffffffffc0207008 <default_pmm_manager+0x560>
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
ffffffffc0202c1e:	53658593          	addi	a1,a1,1334 # ffffffffc0207150 <default_pmm_manager+0x6a8>
ffffffffc0202c22:	10000513          	li	a0,256
ffffffffc0202c26:	7ab020ef          	jal	ra,ffffffffc0205bd0 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c2a:	10040593          	addi	a1,s0,256
ffffffffc0202c2e:	10000513          	li	a0,256
ffffffffc0202c32:	7b1020ef          	jal	ra,ffffffffc0205be2 <strcmp>
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
ffffffffc0202c68:	733020ef          	jal	ra,ffffffffc0205b9a <strlen>
ffffffffc0202c6c:	66051363          	bnez	a0,ffffffffc02032d2 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c70:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c74:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c76:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd49fbc>
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
ffffffffc0202d2c:	4a050513          	addi	a0,a0,1184 # ffffffffc02071c8 <default_pmm_manager+0x720>
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
ffffffffc0202e94:	c5060613          	addi	a2,a2,-944 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0202e98:	28e00593          	li	a1,654
ffffffffc0202e9c:	00004517          	auipc	a0,0x4
ffffffffc0202ea0:	d5c50513          	addi	a0,a0,-676 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202ea4:	deafd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ea8:	00004697          	auipc	a3,0x4
ffffffffc0202eac:	1c068693          	addi	a3,a3,448 # ffffffffc0207068 <default_pmm_manager+0x5c0>
ffffffffc0202eb0:	00004617          	auipc	a2,0x4
ffffffffc0202eb4:	84860613          	addi	a2,a2,-1976 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202eb8:	28f00593          	li	a1,655
ffffffffc0202ebc:	00004517          	auipc	a0,0x4
ffffffffc0202ec0:	d3c50513          	addi	a0,a0,-708 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202ec4:	dcafd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ec8:	00004697          	auipc	a3,0x4
ffffffffc0202ecc:	16068693          	addi	a3,a3,352 # ffffffffc0207028 <default_pmm_manager+0x580>
ffffffffc0202ed0:	00004617          	auipc	a2,0x4
ffffffffc0202ed4:	82860613          	addi	a2,a2,-2008 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202ed8:	28e00593          	li	a1,654
ffffffffc0202edc:	00004517          	auipc	a0,0x4
ffffffffc0202ee0:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202ee4:	daafd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202ee8:	fc5fe0ef          	jal	ra,ffffffffc0201eac <pa2page.part.0>
ffffffffc0202eec:	fddfe0ef          	jal	ra,ffffffffc0201ec8 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202ef0:	00004697          	auipc	a3,0x4
ffffffffc0202ef4:	f3068693          	addi	a3,a3,-208 # ffffffffc0206e20 <default_pmm_manager+0x378>
ffffffffc0202ef8:	00004617          	auipc	a2,0x4
ffffffffc0202efc:	80060613          	addi	a2,a2,-2048 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202f00:	25e00593          	li	a1,606
ffffffffc0202f04:	00004517          	auipc	a0,0x4
ffffffffc0202f08:	cf450513          	addi	a0,a0,-780 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202f0c:	d82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f10:	00004697          	auipc	a3,0x4
ffffffffc0202f14:	e5068693          	addi	a3,a3,-432 # ffffffffc0206d60 <default_pmm_manager+0x2b8>
ffffffffc0202f18:	00003617          	auipc	a2,0x3
ffffffffc0202f1c:	7e060613          	addi	a2,a2,2016 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202f20:	25100593          	li	a1,593
ffffffffc0202f24:	00004517          	auipc	a0,0x4
ffffffffc0202f28:	cd450513          	addi	a0,a0,-812 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202f2c:	d62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f30:	00004697          	auipc	a3,0x4
ffffffffc0202f34:	df068693          	addi	a3,a3,-528 # ffffffffc0206d20 <default_pmm_manager+0x278>
ffffffffc0202f38:	00003617          	auipc	a2,0x3
ffffffffc0202f3c:	7c060613          	addi	a2,a2,1984 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202f40:	25000593          	li	a1,592
ffffffffc0202f44:	00004517          	auipc	a0,0x4
ffffffffc0202f48:	cb450513          	addi	a0,a0,-844 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202f4c:	d42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f50:	00004697          	auipc	a3,0x4
ffffffffc0202f54:	db068693          	addi	a3,a3,-592 # ffffffffc0206d00 <default_pmm_manager+0x258>
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	7a060613          	addi	a2,a2,1952 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202f60:	24f00593          	li	a1,591
ffffffffc0202f64:	00004517          	auipc	a0,0x4
ffffffffc0202f68:	c9450513          	addi	a0,a0,-876 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202f6c:	d22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f70:	00004617          	auipc	a2,0x4
ffffffffc0202f74:	b7060613          	addi	a2,a2,-1168 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0202f78:	07100593          	li	a1,113
ffffffffc0202f7c:	00004517          	auipc	a0,0x4
ffffffffc0202f80:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0202f84:	d0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	02868693          	addi	a3,a3,40 # ffffffffc0206fb0 <default_pmm_manager+0x508>
ffffffffc0202f90:	00003617          	auipc	a2,0x3
ffffffffc0202f94:	76860613          	addi	a2,a2,1896 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202f98:	27700593          	li	a1,631
ffffffffc0202f9c:	00004517          	auipc	a0,0x4
ffffffffc0202fa0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202fa4:	ceafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fa8:	00004697          	auipc	a3,0x4
ffffffffc0202fac:	fc068693          	addi	a3,a3,-64 # ffffffffc0206f68 <default_pmm_manager+0x4c0>
ffffffffc0202fb0:	00003617          	auipc	a2,0x3
ffffffffc0202fb4:	74860613          	addi	a2,a2,1864 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202fb8:	27500593          	li	a1,629
ffffffffc0202fbc:	00004517          	auipc	a0,0x4
ffffffffc0202fc0:	c3c50513          	addi	a0,a0,-964 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202fc4:	ccafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fc8:	00004697          	auipc	a3,0x4
ffffffffc0202fcc:	fd068693          	addi	a3,a3,-48 # ffffffffc0206f98 <default_pmm_manager+0x4f0>
ffffffffc0202fd0:	00003617          	auipc	a2,0x3
ffffffffc0202fd4:	72860613          	addi	a2,a2,1832 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202fd8:	27400593          	li	a1,628
ffffffffc0202fdc:	00004517          	auipc	a0,0x4
ffffffffc0202fe0:	c1c50513          	addi	a0,a0,-996 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0202fe4:	caafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fe8:	00004697          	auipc	a3,0x4
ffffffffc0202fec:	09868693          	addi	a3,a3,152 # ffffffffc0207080 <default_pmm_manager+0x5d8>
ffffffffc0202ff0:	00003617          	auipc	a2,0x3
ffffffffc0202ff4:	70860613          	addi	a2,a2,1800 # ffffffffc02066f8 <commands+0x828>
ffffffffc0202ff8:	29200593          	li	a1,658
ffffffffc0202ffc:	00004517          	auipc	a0,0x4
ffffffffc0203000:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203004:	c8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203008:	00004697          	auipc	a3,0x4
ffffffffc020300c:	fd868693          	addi	a3,a3,-40 # ffffffffc0206fe0 <default_pmm_manager+0x538>
ffffffffc0203010:	00003617          	auipc	a2,0x3
ffffffffc0203014:	6e860613          	addi	a2,a2,1768 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203018:	27f00593          	li	a1,639
ffffffffc020301c:	00004517          	auipc	a0,0x4
ffffffffc0203020:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203024:	c6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203028:	00004697          	auipc	a3,0x4
ffffffffc020302c:	0b068693          	addi	a3,a3,176 # ffffffffc02070d8 <default_pmm_manager+0x630>
ffffffffc0203030:	00003617          	auipc	a2,0x3
ffffffffc0203034:	6c860613          	addi	a2,a2,1736 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203038:	29700593          	li	a1,663
ffffffffc020303c:	00004517          	auipc	a0,0x4
ffffffffc0203040:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203044:	c4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203048:	00004697          	auipc	a3,0x4
ffffffffc020304c:	05068693          	addi	a3,a3,80 # ffffffffc0207098 <default_pmm_manager+0x5f0>
ffffffffc0203050:	00003617          	auipc	a2,0x3
ffffffffc0203054:	6a860613          	addi	a2,a2,1704 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203058:	29600593          	li	a1,662
ffffffffc020305c:	00004517          	auipc	a0,0x4
ffffffffc0203060:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203064:	c2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203068:	00004697          	auipc	a3,0x4
ffffffffc020306c:	f0068693          	addi	a3,a3,-256 # ffffffffc0206f68 <default_pmm_manager+0x4c0>
ffffffffc0203070:	00003617          	auipc	a2,0x3
ffffffffc0203074:	68860613          	addi	a2,a2,1672 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203078:	27100593          	li	a1,625
ffffffffc020307c:	00004517          	auipc	a0,0x4
ffffffffc0203080:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203084:	c0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203088:	00004697          	auipc	a3,0x4
ffffffffc020308c:	d8068693          	addi	a3,a3,-640 # ffffffffc0206e08 <default_pmm_manager+0x360>
ffffffffc0203090:	00003617          	auipc	a2,0x3
ffffffffc0203094:	66860613          	addi	a2,a2,1640 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203098:	27000593          	li	a1,624
ffffffffc020309c:	00004517          	auipc	a0,0x4
ffffffffc02030a0:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02030a4:	beafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030a8:	00004697          	auipc	a3,0x4
ffffffffc02030ac:	ed868693          	addi	a3,a3,-296 # ffffffffc0206f80 <default_pmm_manager+0x4d8>
ffffffffc02030b0:	00003617          	auipc	a2,0x3
ffffffffc02030b4:	64860613          	addi	a2,a2,1608 # ffffffffc02066f8 <commands+0x828>
ffffffffc02030b8:	26d00593          	li	a1,621
ffffffffc02030bc:	00004517          	auipc	a0,0x4
ffffffffc02030c0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02030c4:	bcafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030c8:	00004697          	auipc	a3,0x4
ffffffffc02030cc:	d2868693          	addi	a3,a3,-728 # ffffffffc0206df0 <default_pmm_manager+0x348>
ffffffffc02030d0:	00003617          	auipc	a2,0x3
ffffffffc02030d4:	62860613          	addi	a2,a2,1576 # ffffffffc02066f8 <commands+0x828>
ffffffffc02030d8:	26c00593          	li	a1,620
ffffffffc02030dc:	00004517          	auipc	a0,0x4
ffffffffc02030e0:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02030e4:	baafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030e8:	00004697          	auipc	a3,0x4
ffffffffc02030ec:	da868693          	addi	a3,a3,-600 # ffffffffc0206e90 <default_pmm_manager+0x3e8>
ffffffffc02030f0:	00003617          	auipc	a2,0x3
ffffffffc02030f4:	60860613          	addi	a2,a2,1544 # ffffffffc02066f8 <commands+0x828>
ffffffffc02030f8:	26b00593          	li	a1,619
ffffffffc02030fc:	00004517          	auipc	a0,0x4
ffffffffc0203100:	afc50513          	addi	a0,a0,-1284 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203104:	b8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203108:	00004697          	auipc	a3,0x4
ffffffffc020310c:	e6068693          	addi	a3,a3,-416 # ffffffffc0206f68 <default_pmm_manager+0x4c0>
ffffffffc0203110:	00003617          	auipc	a2,0x3
ffffffffc0203114:	5e860613          	addi	a2,a2,1512 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203118:	26a00593          	li	a1,618
ffffffffc020311c:	00004517          	auipc	a0,0x4
ffffffffc0203120:	adc50513          	addi	a0,a0,-1316 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203124:	b6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203128:	00004697          	auipc	a3,0x4
ffffffffc020312c:	e2868693          	addi	a3,a3,-472 # ffffffffc0206f50 <default_pmm_manager+0x4a8>
ffffffffc0203130:	00003617          	auipc	a2,0x3
ffffffffc0203134:	5c860613          	addi	a2,a2,1480 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203138:	26900593          	li	a1,617
ffffffffc020313c:	00004517          	auipc	a0,0x4
ffffffffc0203140:	abc50513          	addi	a0,a0,-1348 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203144:	b4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203148:	00004697          	auipc	a3,0x4
ffffffffc020314c:	dd868693          	addi	a3,a3,-552 # ffffffffc0206f20 <default_pmm_manager+0x478>
ffffffffc0203150:	00003617          	auipc	a2,0x3
ffffffffc0203154:	5a860613          	addi	a2,a2,1448 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203158:	26800593          	li	a1,616
ffffffffc020315c:	00004517          	auipc	a0,0x4
ffffffffc0203160:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203164:	b2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203168:	00004697          	auipc	a3,0x4
ffffffffc020316c:	da068693          	addi	a3,a3,-608 # ffffffffc0206f08 <default_pmm_manager+0x460>
ffffffffc0203170:	00003617          	auipc	a2,0x3
ffffffffc0203174:	58860613          	addi	a2,a2,1416 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203178:	26600593          	li	a1,614
ffffffffc020317c:	00004517          	auipc	a0,0x4
ffffffffc0203180:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203184:	b0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203188:	00004697          	auipc	a3,0x4
ffffffffc020318c:	d6068693          	addi	a3,a3,-672 # ffffffffc0206ee8 <default_pmm_manager+0x440>
ffffffffc0203190:	00003617          	auipc	a2,0x3
ffffffffc0203194:	56860613          	addi	a2,a2,1384 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203198:	26500593          	li	a1,613
ffffffffc020319c:	00004517          	auipc	a0,0x4
ffffffffc02031a0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02031a4:	aeafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031a8:	00004697          	auipc	a3,0x4
ffffffffc02031ac:	d3068693          	addi	a3,a3,-720 # ffffffffc0206ed8 <default_pmm_manager+0x430>
ffffffffc02031b0:	00003617          	auipc	a2,0x3
ffffffffc02031b4:	54860613          	addi	a2,a2,1352 # ffffffffc02066f8 <commands+0x828>
ffffffffc02031b8:	26400593          	li	a1,612
ffffffffc02031bc:	00004517          	auipc	a0,0x4
ffffffffc02031c0:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02031c4:	acafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031c8:	00004697          	auipc	a3,0x4
ffffffffc02031cc:	d0068693          	addi	a3,a3,-768 # ffffffffc0206ec8 <default_pmm_manager+0x420>
ffffffffc02031d0:	00003617          	auipc	a2,0x3
ffffffffc02031d4:	52860613          	addi	a2,a2,1320 # ffffffffc02066f8 <commands+0x828>
ffffffffc02031d8:	26300593          	li	a1,611
ffffffffc02031dc:	00004517          	auipc	a0,0x4
ffffffffc02031e0:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02031e4:	aaafd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc02031e8:	00004617          	auipc	a2,0x4
ffffffffc02031ec:	a8060613          	addi	a2,a2,-1408 # ffffffffc0206c68 <default_pmm_manager+0x1c0>
ffffffffc02031f0:	06500593          	li	a1,101
ffffffffc02031f4:	00004517          	auipc	a0,0x4
ffffffffc02031f8:	a0450513          	addi	a0,a0,-1532 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02031fc:	a92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	de068693          	addi	a3,a3,-544 # ffffffffc0206fe0 <default_pmm_manager+0x538>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	4f060613          	addi	a2,a2,1264 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203210:	2a900593          	li	a1,681
ffffffffc0203214:	00004517          	auipc	a0,0x4
ffffffffc0203218:	9e450513          	addi	a0,a0,-1564 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020321c:	a72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	c7068693          	addi	a3,a3,-912 # ffffffffc0206e90 <default_pmm_manager+0x3e8>
ffffffffc0203228:	00003617          	auipc	a2,0x3
ffffffffc020322c:	4d060613          	addi	a2,a2,1232 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203230:	26200593          	li	a1,610
ffffffffc0203234:	00004517          	auipc	a0,0x4
ffffffffc0203238:	9c450513          	addi	a0,a0,-1596 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020323c:	a52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203240:	00004697          	auipc	a3,0x4
ffffffffc0203244:	c1068693          	addi	a3,a3,-1008 # ffffffffc0206e50 <default_pmm_manager+0x3a8>
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	4b060613          	addi	a2,a2,1200 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203250:	26100593          	li	a1,609
ffffffffc0203254:	00004517          	auipc	a0,0x4
ffffffffc0203258:	9a450513          	addi	a0,a0,-1628 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020325c:	a32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203260:	86d6                	mv	a3,s5
ffffffffc0203262:	00004617          	auipc	a2,0x4
ffffffffc0203266:	87e60613          	addi	a2,a2,-1922 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc020326a:	25d00593          	li	a1,605
ffffffffc020326e:	00004517          	auipc	a0,0x4
ffffffffc0203272:	98a50513          	addi	a0,a0,-1654 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203276:	a18fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020327a:	00004617          	auipc	a2,0x4
ffffffffc020327e:	86660613          	addi	a2,a2,-1946 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0203282:	25c00593          	li	a1,604
ffffffffc0203286:	00004517          	auipc	a0,0x4
ffffffffc020328a:	97250513          	addi	a0,a0,-1678 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020328e:	a00fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203292:	00004697          	auipc	a3,0x4
ffffffffc0203296:	b7668693          	addi	a3,a3,-1162 # ffffffffc0206e08 <default_pmm_manager+0x360>
ffffffffc020329a:	00003617          	auipc	a2,0x3
ffffffffc020329e:	45e60613          	addi	a2,a2,1118 # ffffffffc02066f8 <commands+0x828>
ffffffffc02032a2:	25a00593          	li	a1,602
ffffffffc02032a6:	00004517          	auipc	a0,0x4
ffffffffc02032aa:	95250513          	addi	a0,a0,-1710 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02032ae:	9e0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032b2:	00004697          	auipc	a3,0x4
ffffffffc02032b6:	b3e68693          	addi	a3,a3,-1218 # ffffffffc0206df0 <default_pmm_manager+0x348>
ffffffffc02032ba:	00003617          	auipc	a2,0x3
ffffffffc02032be:	43e60613          	addi	a2,a2,1086 # ffffffffc02066f8 <commands+0x828>
ffffffffc02032c2:	25900593          	li	a1,601
ffffffffc02032c6:	00004517          	auipc	a0,0x4
ffffffffc02032ca:	93250513          	addi	a0,a0,-1742 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02032ce:	9c0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032d2:	00004697          	auipc	a3,0x4
ffffffffc02032d6:	ece68693          	addi	a3,a3,-306 # ffffffffc02071a0 <default_pmm_manager+0x6f8>
ffffffffc02032da:	00003617          	auipc	a2,0x3
ffffffffc02032de:	41e60613          	addi	a2,a2,1054 # ffffffffc02066f8 <commands+0x828>
ffffffffc02032e2:	2a000593          	li	a1,672
ffffffffc02032e6:	00004517          	auipc	a0,0x4
ffffffffc02032ea:	91250513          	addi	a0,a0,-1774 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02032ee:	9a0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032f2:	00004697          	auipc	a3,0x4
ffffffffc02032f6:	e7668693          	addi	a3,a3,-394 # ffffffffc0207168 <default_pmm_manager+0x6c0>
ffffffffc02032fa:	00003617          	auipc	a2,0x3
ffffffffc02032fe:	3fe60613          	addi	a2,a2,1022 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203302:	29d00593          	li	a1,669
ffffffffc0203306:	00004517          	auipc	a0,0x4
ffffffffc020330a:	8f250513          	addi	a0,a0,-1806 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020330e:	980fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203312:	00004697          	auipc	a3,0x4
ffffffffc0203316:	e2668693          	addi	a3,a3,-474 # ffffffffc0207138 <default_pmm_manager+0x690>
ffffffffc020331a:	00003617          	auipc	a2,0x3
ffffffffc020331e:	3de60613          	addi	a2,a2,990 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203322:	29900593          	li	a1,665
ffffffffc0203326:	00004517          	auipc	a0,0x4
ffffffffc020332a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020332e:	960fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203332:	00004697          	auipc	a3,0x4
ffffffffc0203336:	dbe68693          	addi	a3,a3,-578 # ffffffffc02070f0 <default_pmm_manager+0x648>
ffffffffc020333a:	00003617          	auipc	a2,0x3
ffffffffc020333e:	3be60613          	addi	a2,a2,958 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203342:	29800593          	li	a1,664
ffffffffc0203346:	00004517          	auipc	a0,0x4
ffffffffc020334a:	8b250513          	addi	a0,a0,-1870 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020334e:	940fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203352:	00004617          	auipc	a2,0x4
ffffffffc0203356:	83660613          	addi	a2,a2,-1994 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc020335a:	0c900593          	li	a1,201
ffffffffc020335e:	00004517          	auipc	a0,0x4
ffffffffc0203362:	89a50513          	addi	a0,a0,-1894 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc0203366:	928fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020336a:	00004617          	auipc	a2,0x4
ffffffffc020336e:	81e60613          	addi	a2,a2,-2018 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc0203372:	08100593          	li	a1,129
ffffffffc0203376:	00004517          	auipc	a0,0x4
ffffffffc020337a:	88250513          	addi	a0,a0,-1918 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020337e:	910fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203382:	00004697          	auipc	a3,0x4
ffffffffc0203386:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0206dc0 <default_pmm_manager+0x318>
ffffffffc020338a:	00003617          	auipc	a2,0x3
ffffffffc020338e:	36e60613          	addi	a2,a2,878 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203392:	25800593          	li	a1,600
ffffffffc0203396:	00004517          	auipc	a0,0x4
ffffffffc020339a:	86250513          	addi	a0,a0,-1950 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020339e:	8f0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033a2:	00004697          	auipc	a3,0x4
ffffffffc02033a6:	9ee68693          	addi	a3,a3,-1554 # ffffffffc0206d90 <default_pmm_manager+0x2e8>
ffffffffc02033aa:	00003617          	auipc	a2,0x3
ffffffffc02033ae:	34e60613          	addi	a2,a2,846 # ffffffffc02066f8 <commands+0x828>
ffffffffc02033b2:	25500593          	li	a1,597
ffffffffc02033b6:	00004517          	auipc	a0,0x4
ffffffffc02033ba:	84250513          	addi	a0,a0,-1982 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02033be:	8d0fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02033c2 <copy_range>:
{
ffffffffc02033c2:	7119                	addi	sp,sp,-128
ffffffffc02033c4:	f4a6                	sd	s1,104(sp)
ffffffffc02033c6:	84b6                	mv	s1,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033c8:	8ed1                	or	a3,a3,a2
{
ffffffffc02033ca:	fc86                	sd	ra,120(sp)
ffffffffc02033cc:	f8a2                	sd	s0,112(sp)
ffffffffc02033ce:	f0ca                	sd	s2,96(sp)
ffffffffc02033d0:	ecce                	sd	s3,88(sp)
ffffffffc02033d2:	e8d2                	sd	s4,80(sp)
ffffffffc02033d4:	e4d6                	sd	s5,72(sp)
ffffffffc02033d6:	e0da                	sd	s6,64(sp)
ffffffffc02033d8:	fc5e                	sd	s7,56(sp)
ffffffffc02033da:	f862                	sd	s8,48(sp)
ffffffffc02033dc:	f466                	sd	s9,40(sp)
ffffffffc02033de:	f06a                	sd	s10,32(sp)
ffffffffc02033e0:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033e2:	16d2                	slli	a3,a3,0x34
{
ffffffffc02033e4:	e03a                	sd	a4,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033e6:	2a069063          	bnez	a3,ffffffffc0203686 <copy_range+0x2c4>
    assert(USER_ACCESS(start, end));
ffffffffc02033ea:	00200737          	lui	a4,0x200
ffffffffc02033ee:	8cb2                	mv	s9,a2
ffffffffc02033f0:	20e66f63          	bltu	a2,a4,ffffffffc020360e <copy_range+0x24c>
ffffffffc02033f4:	20967d63          	bgeu	a2,s1,ffffffffc020360e <copy_range+0x24c>
ffffffffc02033f8:	4705                	li	a4,1
ffffffffc02033fa:	077e                	slli	a4,a4,0x1f
ffffffffc02033fc:	20976963          	bltu	a4,s1,ffffffffc020360e <copy_range+0x24c>
ffffffffc0203400:	5c7d                	li	s8,-1
ffffffffc0203402:	00cc5793          	srli	a5,s8,0xc
ffffffffc0203406:	89aa                	mv	s3,a0
ffffffffc0203408:	892e                	mv	s2,a1
        start += PGSIZE;
ffffffffc020340a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020340c:	000b2b97          	auipc	s7,0xb2
ffffffffc0203410:	bf4b8b93          	addi	s7,s7,-1036 # ffffffffc02b5000 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203414:	000b2b17          	auipc	s6,0xb2
ffffffffc0203418:	bf4b0b13          	addi	s6,s6,-1036 # ffffffffc02b5008 <pages>
    return KADDR(page2pa(page));
ffffffffc020341c:	e43e                	sd	a5,8(sp)
        page = pmm_manager->alloc_pages(n);
ffffffffc020341e:	000b2d97          	auipc	s11,0xb2
ffffffffc0203422:	bf2d8d93          	addi	s11,s11,-1038 # ffffffffc02b5010 <pmm_manager>
                if (current != NULL) {
ffffffffc0203426:	000b2d17          	auipc	s10,0xb2
ffffffffc020342a:	c02d0d13          	addi	s10,s10,-1022 # ffffffffc02b5028 <current>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020342e:	4601                	li	a2,0
ffffffffc0203430:	85e6                	mv	a1,s9
ffffffffc0203432:	854a                	mv	a0,s2
ffffffffc0203434:	b69fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc0203438:	8c2a                	mv	s8,a0
        if (ptep == NULL)
ffffffffc020343a:	c571                	beqz	a0,ffffffffc0203506 <copy_range+0x144>
        if (*ptep & PTE_V)
ffffffffc020343c:	6114                	ld	a3,0(a0)
ffffffffc020343e:	8a85                	andi	a3,a3,1
ffffffffc0203440:	e685                	bnez	a3,ffffffffc0203468 <copy_range+0xa6>
        start += PGSIZE;
ffffffffc0203442:	9cd2                	add	s9,s9,s4
    } while (start != 0 && start < end);
ffffffffc0203444:	fe9ce5e3          	bltu	s9,s1,ffffffffc020342e <copy_range+0x6c>
    return 0;
ffffffffc0203448:	4501                	li	a0,0
}
ffffffffc020344a:	70e6                	ld	ra,120(sp)
ffffffffc020344c:	7446                	ld	s0,112(sp)
ffffffffc020344e:	74a6                	ld	s1,104(sp)
ffffffffc0203450:	7906                	ld	s2,96(sp)
ffffffffc0203452:	69e6                	ld	s3,88(sp)
ffffffffc0203454:	6a46                	ld	s4,80(sp)
ffffffffc0203456:	6aa6                	ld	s5,72(sp)
ffffffffc0203458:	6b06                	ld	s6,64(sp)
ffffffffc020345a:	7be2                	ld	s7,56(sp)
ffffffffc020345c:	7c42                	ld	s8,48(sp)
ffffffffc020345e:	7ca2                	ld	s9,40(sp)
ffffffffc0203460:	7d02                	ld	s10,32(sp)
ffffffffc0203462:	6de2                	ld	s11,24(sp)
ffffffffc0203464:	6109                	addi	sp,sp,128
ffffffffc0203466:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203468:	4605                	li	a2,1
ffffffffc020346a:	85e6                	mv	a1,s9
ffffffffc020346c:	854e                	mv	a0,s3
ffffffffc020346e:	b2ffe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc0203472:	16050363          	beqz	a0,ffffffffc02035d8 <copy_range+0x216>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203476:	000c3603          	ld	a2,0(s8)
    if (!(pte & PTE_V))
ffffffffc020347a:	00167693          	andi	a3,a2,1
ffffffffc020347e:	00060a9b          	sext.w	s5,a2
ffffffffc0203482:	1e068663          	beqz	a3,ffffffffc020366e <copy_range+0x2ac>
    if (PPN(pa) >= npage)
ffffffffc0203486:	000bb583          	ld	a1,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc020348a:	00261693          	slli	a3,a2,0x2
ffffffffc020348e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0203490:	14b6f663          	bgeu	a3,a1,ffffffffc02035dc <copy_range+0x21a>
    return &pages[PPN(pa) - nbase];
ffffffffc0203494:	000b3403          	ld	s0,0(s6)
ffffffffc0203498:	fff805b7          	lui	a1,0xfff80
ffffffffc020349c:	96ae                	add	a3,a3,a1
ffffffffc020349e:	069a                	slli	a3,a3,0x6
ffffffffc02034a0:	9436                	add	s0,s0,a3
            assert(page != NULL);
ffffffffc02034a2:	1a040663          	beqz	s0,ffffffffc020364e <copy_range+0x28c>
            if (share) {
ffffffffc02034a6:	6782                	ld	a5,0(sp)
ffffffffc02034a8:	cfa5                	beqz	a5,ffffffffc0203520 <copy_range+0x15e>
                *ptep = (*ptep & ~PTE_W);
ffffffffc02034aa:	9a6d                	andi	a2,a2,-5
ffffffffc02034ac:	00cc3023          	sd	a2,0(s8)
                perm_shared &= ~PTE_W;
ffffffffc02034b0:	01bafa93          	andi	s5,s5,27
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02034b4:	120c8073          	sfence.vma	s9
                if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02034b8:	4605                	li	a2,1
ffffffffc02034ba:	85e6                	mv	a1,s9
ffffffffc02034bc:	854e                	mv	a0,s3
ffffffffc02034be:	adffe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc02034c2:	10050b63          	beqz	a0,ffffffffc02035d8 <copy_range+0x216>
                if (page_insert(to, page, start, perm_shared) != 0)
ffffffffc02034c6:	86d6                	mv	a3,s5
ffffffffc02034c8:	8666                	mv	a2,s9
ffffffffc02034ca:	85a2                	mv	a1,s0
ffffffffc02034cc:	854e                	mv	a0,s3
ffffffffc02034ce:	9beff0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc02034d2:	0e051c63          	bnez	a0,ffffffffc02035ca <copy_range+0x208>
                if (current != NULL) {
ffffffffc02034d6:	000d3703          	ld	a4,0(s10)
ffffffffc02034da:	d725                	beqz	a4,ffffffffc0203442 <copy_range+0x80>
                    pte_t *newpte = get_pte(to, start, 0);
ffffffffc02034dc:	85e6                	mv	a1,s9
ffffffffc02034de:	4601                	li	a2,0
ffffffffc02034e0:	854e                	mv	a0,s3
ffffffffc02034e2:	abbfe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
                    cprintf("copy_range: after insert pid %d addr 0x%08x newpte 0x%08x ref %d\n",
ffffffffc02034e6:	000d3703          	ld	a4,0(s10)
ffffffffc02034ea:	4681                	li	a3,0
ffffffffc02034ec:	434c                	lw	a1,4(a4)
ffffffffc02034ee:	c111                	beqz	a0,ffffffffc02034f2 <copy_range+0x130>
ffffffffc02034f0:	4114                	lw	a3,0(a0)
ffffffffc02034f2:	4018                	lw	a4,0(s0)
ffffffffc02034f4:	8666                	mv	a2,s9
ffffffffc02034f6:	00004517          	auipc	a0,0x4
ffffffffc02034fa:	d3250513          	addi	a0,a0,-718 # ffffffffc0207228 <default_pmm_manager+0x780>
ffffffffc02034fe:	c97fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        start += PGSIZE;
ffffffffc0203502:	9cd2                	add	s9,s9,s4
    } while (start != 0 && start < end);
ffffffffc0203504:	b781                	j	ffffffffc0203444 <copy_range+0x82>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203506:	00200637          	lui	a2,0x200
ffffffffc020350a:	00cc87b3          	add	a5,s9,a2
ffffffffc020350e:	ffe00637          	lui	a2,0xffe00
ffffffffc0203512:	00c7fcb3          	and	s9,a5,a2
    } while (start != 0 && start < end);
ffffffffc0203516:	f20c89e3          	beqz	s9,ffffffffc0203448 <copy_range+0x86>
ffffffffc020351a:	f09ceae3          	bltu	s9,s1,ffffffffc020342e <copy_range+0x6c>
ffffffffc020351e:	b72d                	j	ffffffffc0203448 <copy_range+0x86>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203520:	10002773          	csrr	a4,sstatus
ffffffffc0203524:	8b09                	andi	a4,a4,2
ffffffffc0203526:	e759                	bnez	a4,ffffffffc02035b4 <copy_range+0x1f2>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203528:	000db703          	ld	a4,0(s11)
ffffffffc020352c:	4505                	li	a0,1
ffffffffc020352e:	6f18                	ld	a4,24(a4)
ffffffffc0203530:	9702                	jalr	a4
ffffffffc0203532:	8c2a                	mv	s8,a0
                assert(npage != NULL);
ffffffffc0203534:	0e0c0d63          	beqz	s8,ffffffffc020362e <copy_range+0x26c>
    return page - pages + nbase;
ffffffffc0203538:	000b3603          	ld	a2,0(s6)
    return KADDR(page2pa(page));
ffffffffc020353c:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc020353e:	000805b7          	lui	a1,0x80
ffffffffc0203542:	40c406b3          	sub	a3,s0,a2
ffffffffc0203546:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203548:	000bb883          	ld	a7,0(s7)
    return page - pages + nbase;
ffffffffc020354c:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020354e:	00f6f733          	and	a4,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0203552:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203554:	0b177163          	bgeu	a4,a7,ffffffffc02035f6 <copy_range+0x234>
ffffffffc0203558:	000b2797          	auipc	a5,0xb2
ffffffffc020355c:	ac078793          	addi	a5,a5,-1344 # ffffffffc02b5018 <va_pa_offset>
ffffffffc0203560:	6388                	ld	a0,0(a5)
    return page - pages + nbase;
ffffffffc0203562:	40cc0733          	sub	a4,s8,a2
    return KADDR(page2pa(page));
ffffffffc0203566:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0203568:	8719                	srai	a4,a4,0x6
ffffffffc020356a:	972e                	add	a4,a4,a1
    return KADDR(page2pa(page));
ffffffffc020356c:	00f77633          	and	a2,a4,a5
ffffffffc0203570:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203574:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0203576:	07167f63          	bgeu	a2,a7,ffffffffc02035f4 <copy_range+0x232>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020357a:	6605                	lui	a2,0x1
ffffffffc020357c:	953a                	add	a0,a0,a4
ffffffffc020357e:	6d0020ef          	jal	ra,ffffffffc0205c4e <memcpy>
                int ret = page_insert(to, npage, start, perm);
ffffffffc0203582:	01faf693          	andi	a3,s5,31
ffffffffc0203586:	8666                	mv	a2,s9
ffffffffc0203588:	85e2                	mv	a1,s8
ffffffffc020358a:	854e                	mv	a0,s3
ffffffffc020358c:	900ff0ef          	jal	ra,ffffffffc020268c <page_insert>
                assert(ret == 0);
ffffffffc0203590:	ea0509e3          	beqz	a0,ffffffffc0203442 <copy_range+0x80>
ffffffffc0203594:	00004697          	auipc	a3,0x4
ffffffffc0203598:	cec68693          	addi	a3,a3,-788 # ffffffffc0207280 <default_pmm_manager+0x7d8>
ffffffffc020359c:	00003617          	auipc	a2,0x3
ffffffffc02035a0:	15c60613          	addi	a2,a2,348 # ffffffffc02066f8 <commands+0x828>
ffffffffc02035a4:	1ec00593          	li	a1,492
ffffffffc02035a8:	00003517          	auipc	a0,0x3
ffffffffc02035ac:	65050513          	addi	a0,a0,1616 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02035b0:	edffc0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02035b4:	c00fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035b8:	000db703          	ld	a4,0(s11)
ffffffffc02035bc:	4505                	li	a0,1
ffffffffc02035be:	6f18                	ld	a4,24(a4)
ffffffffc02035c0:	9702                	jalr	a4
ffffffffc02035c2:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02035c4:	beafd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02035c8:	b7b5                	j	ffffffffc0203534 <copy_range+0x172>
                    cprintf("copy_range: page_insert failed for addr 0x%08x\n", start);
ffffffffc02035ca:	85e6                	mv	a1,s9
ffffffffc02035cc:	00004517          	auipc	a0,0x4
ffffffffc02035d0:	c2c50513          	addi	a0,a0,-980 # ffffffffc02071f8 <default_pmm_manager+0x750>
ffffffffc02035d4:	bc1fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
                    return -E_NO_MEM;
ffffffffc02035d8:	5571                	li	a0,-4
ffffffffc02035da:	bd85                	j	ffffffffc020344a <copy_range+0x88>
        panic("pa2page called with invalid pa");
ffffffffc02035dc:	00003617          	auipc	a2,0x3
ffffffffc02035e0:	5d460613          	addi	a2,a2,1492 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc02035e4:	06900593          	li	a1,105
ffffffffc02035e8:	00003517          	auipc	a0,0x3
ffffffffc02035ec:	52050513          	addi	a0,a0,1312 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02035f0:	e9ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02035f4:	86ba                	mv	a3,a4
ffffffffc02035f6:	00003617          	auipc	a2,0x3
ffffffffc02035fa:	4ea60613          	addi	a2,a2,1258 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc02035fe:	07100593          	li	a1,113
ffffffffc0203602:	00003517          	auipc	a0,0x3
ffffffffc0203606:	50650513          	addi	a0,a0,1286 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc020360a:	e85fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020360e:	00003697          	auipc	a3,0x3
ffffffffc0203612:	62a68693          	addi	a3,a3,1578 # ffffffffc0206c38 <default_pmm_manager+0x190>
ffffffffc0203616:	00003617          	auipc	a2,0x3
ffffffffc020361a:	0e260613          	addi	a2,a2,226 # ffffffffc02066f8 <commands+0x828>
ffffffffc020361e:	17c00593          	li	a1,380
ffffffffc0203622:	00003517          	auipc	a0,0x3
ffffffffc0203626:	5d650513          	addi	a0,a0,1494 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020362a:	e65fc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(npage != NULL);
ffffffffc020362e:	00004697          	auipc	a3,0x4
ffffffffc0203632:	c4268693          	addi	a3,a3,-958 # ffffffffc0207270 <default_pmm_manager+0x7c8>
ffffffffc0203636:	00003617          	auipc	a2,0x3
ffffffffc020363a:	0c260613          	addi	a2,a2,194 # ffffffffc02066f8 <commands+0x828>
ffffffffc020363e:	1e200593          	li	a1,482
ffffffffc0203642:	00003517          	auipc	a0,0x3
ffffffffc0203646:	5b650513          	addi	a0,a0,1462 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020364a:	e45fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc020364e:	00004697          	auipc	a3,0x4
ffffffffc0203652:	b9a68693          	addi	a3,a3,-1126 # ffffffffc02071e8 <default_pmm_manager+0x740>
ffffffffc0203656:	00003617          	auipc	a2,0x3
ffffffffc020365a:	0a260613          	addi	a2,a2,162 # ffffffffc02066f8 <commands+0x828>
ffffffffc020365e:	19900593          	li	a1,409
ffffffffc0203662:	00003517          	auipc	a0,0x3
ffffffffc0203666:	59650513          	addi	a0,a0,1430 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020366a:	e25fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020366e:	00003617          	auipc	a2,0x3
ffffffffc0203672:	56260613          	addi	a2,a2,1378 # ffffffffc0206bd0 <default_pmm_manager+0x128>
ffffffffc0203676:	07f00593          	li	a1,127
ffffffffc020367a:	00003517          	auipc	a0,0x3
ffffffffc020367e:	48e50513          	addi	a0,a0,1166 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0203682:	e0dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203686:	00003697          	auipc	a3,0x3
ffffffffc020368a:	58268693          	addi	a3,a3,1410 # ffffffffc0206c08 <default_pmm_manager+0x160>
ffffffffc020368e:	00003617          	auipc	a2,0x3
ffffffffc0203692:	06a60613          	addi	a2,a2,106 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203696:	17b00593          	li	a1,379
ffffffffc020369a:	00003517          	auipc	a0,0x3
ffffffffc020369e:	55e50513          	addi	a0,a0,1374 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc02036a2:	dedfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036a6 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02036a6:	12058073          	sfence.vma	a1
}
ffffffffc02036aa:	8082                	ret

ffffffffc02036ac <pgdir_alloc_page>:
{
ffffffffc02036ac:	7179                	addi	sp,sp,-48
ffffffffc02036ae:	ec26                	sd	s1,24(sp)
ffffffffc02036b0:	e84a                	sd	s2,16(sp)
ffffffffc02036b2:	e052                	sd	s4,0(sp)
ffffffffc02036b4:	f406                	sd	ra,40(sp)
ffffffffc02036b6:	f022                	sd	s0,32(sp)
ffffffffc02036b8:	e44e                	sd	s3,8(sp)
ffffffffc02036ba:	8a2a                	mv	s4,a0
ffffffffc02036bc:	84ae                	mv	s1,a1
ffffffffc02036be:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02036c0:	100027f3          	csrr	a5,sstatus
ffffffffc02036c4:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02036c6:	000b2997          	auipc	s3,0xb2
ffffffffc02036ca:	94a98993          	addi	s3,s3,-1718 # ffffffffc02b5010 <pmm_manager>
ffffffffc02036ce:	ef8d                	bnez	a5,ffffffffc0203708 <pgdir_alloc_page+0x5c>
ffffffffc02036d0:	0009b783          	ld	a5,0(s3)
ffffffffc02036d4:	4505                	li	a0,1
ffffffffc02036d6:	6f9c                	ld	a5,24(a5)
ffffffffc02036d8:	9782                	jalr	a5
ffffffffc02036da:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02036dc:	cc09                	beqz	s0,ffffffffc02036f6 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02036de:	86ca                	mv	a3,s2
ffffffffc02036e0:	8626                	mv	a2,s1
ffffffffc02036e2:	85a2                	mv	a1,s0
ffffffffc02036e4:	8552                	mv	a0,s4
ffffffffc02036e6:	fa7fe0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc02036ea:	e915                	bnez	a0,ffffffffc020371e <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02036ec:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02036ee:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02036f0:	4785                	li	a5,1
ffffffffc02036f2:	04f71e63          	bne	a4,a5,ffffffffc020374e <pgdir_alloc_page+0xa2>
}
ffffffffc02036f6:	70a2                	ld	ra,40(sp)
ffffffffc02036f8:	8522                	mv	a0,s0
ffffffffc02036fa:	7402                	ld	s0,32(sp)
ffffffffc02036fc:	64e2                	ld	s1,24(sp)
ffffffffc02036fe:	6942                	ld	s2,16(sp)
ffffffffc0203700:	69a2                	ld	s3,8(sp)
ffffffffc0203702:	6a02                	ld	s4,0(sp)
ffffffffc0203704:	6145                	addi	sp,sp,48
ffffffffc0203706:	8082                	ret
        intr_disable();
ffffffffc0203708:	aacfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020370c:	0009b783          	ld	a5,0(s3)
ffffffffc0203710:	4505                	li	a0,1
ffffffffc0203712:	6f9c                	ld	a5,24(a5)
ffffffffc0203714:	9782                	jalr	a5
ffffffffc0203716:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203718:	a96fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020371c:	b7c1                	j	ffffffffc02036dc <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020371e:	100027f3          	csrr	a5,sstatus
ffffffffc0203722:	8b89                	andi	a5,a5,2
ffffffffc0203724:	eb89                	bnez	a5,ffffffffc0203736 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203726:	0009b783          	ld	a5,0(s3)
ffffffffc020372a:	8522                	mv	a0,s0
ffffffffc020372c:	4585                	li	a1,1
ffffffffc020372e:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203730:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203732:	9782                	jalr	a5
    if (flag)
ffffffffc0203734:	b7c9                	j	ffffffffc02036f6 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203736:	a7efd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020373a:	0009b783          	ld	a5,0(s3)
ffffffffc020373e:	8522                	mv	a0,s0
ffffffffc0203740:	4585                	li	a1,1
ffffffffc0203742:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203744:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203746:	9782                	jalr	a5
        intr_enable();
ffffffffc0203748:	a66fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020374c:	b76d                	j	ffffffffc02036f6 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020374e:	00004697          	auipc	a3,0x4
ffffffffc0203752:	b4268693          	addi	a3,a3,-1214 # ffffffffc0207290 <default_pmm_manager+0x7e8>
ffffffffc0203756:	00003617          	auipc	a2,0x3
ffffffffc020375a:	fa260613          	addi	a2,a2,-94 # ffffffffc02066f8 <commands+0x828>
ffffffffc020375e:	23600593          	li	a1,566
ffffffffc0203762:	00003517          	auipc	a0,0x3
ffffffffc0203766:	49650513          	addi	a0,a0,1174 # ffffffffc0206bf8 <default_pmm_manager+0x150>
ffffffffc020376a:	d25fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020376e <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020376e:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203770:	00004697          	auipc	a3,0x4
ffffffffc0203774:	b3868693          	addi	a3,a3,-1224 # ffffffffc02072a8 <default_pmm_manager+0x800>
ffffffffc0203778:	00003617          	auipc	a2,0x3
ffffffffc020377c:	f8060613          	addi	a2,a2,-128 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203780:	10600593          	li	a1,262
ffffffffc0203784:	00004517          	auipc	a0,0x4
ffffffffc0203788:	b4450513          	addi	a0,a0,-1212 # ffffffffc02072c8 <default_pmm_manager+0x820>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020378c:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020378e:	d01fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203792 <mm_create>:
{
ffffffffc0203792:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203794:	04000513          	li	a0,64
{
ffffffffc0203798:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020379a:	d6cfe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
    if (mm != NULL)
ffffffffc020379e:	cd19                	beqz	a0,ffffffffc02037bc <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02037a0:	e508                	sd	a0,8(a0)
ffffffffc02037a2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02037a4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02037a8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02037ac:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02037b0:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02037b4:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02037b8:	02053c23          	sd	zero,56(a0)
}
ffffffffc02037bc:	60a2                	ld	ra,8(sp)
ffffffffc02037be:	0141                	addi	sp,sp,16
ffffffffc02037c0:	8082                	ret

ffffffffc02037c2 <find_vma>:
{
ffffffffc02037c2:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02037c4:	c505                	beqz	a0,ffffffffc02037ec <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02037c6:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037c8:	c501                	beqz	a0,ffffffffc02037d0 <find_vma+0xe>
ffffffffc02037ca:	651c                	ld	a5,8(a0)
ffffffffc02037cc:	02f5f263          	bgeu	a1,a5,ffffffffc02037f0 <find_vma+0x2e>
    return listelm->next;
ffffffffc02037d0:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02037d2:	00f68d63          	beq	a3,a5,ffffffffc02037ec <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02037d6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037da:	00e5e663          	bltu	a1,a4,ffffffffc02037e6 <find_vma+0x24>
ffffffffc02037de:	ff07b703          	ld	a4,-16(a5)
ffffffffc02037e2:	00e5ec63          	bltu	a1,a4,ffffffffc02037fa <find_vma+0x38>
ffffffffc02037e6:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02037e8:	fef697e3          	bne	a3,a5,ffffffffc02037d6 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02037ec:	4501                	li	a0,0
}
ffffffffc02037ee:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037f0:	691c                	ld	a5,16(a0)
ffffffffc02037f2:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02037d0 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02037f6:	ea88                	sd	a0,16(a3)
ffffffffc02037f8:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037fa:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037fe:	ea88                	sd	a0,16(a3)
ffffffffc0203800:	8082                	ret

ffffffffc0203802 <do_pgfault>:
{
ffffffffc0203802:	715d                	addi	sp,sp,-80
ffffffffc0203804:	f44e                	sd	s3,40(sp)
ffffffffc0203806:	89ae                	mv	s3,a1
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203808:	85b2                	mv	a1,a2
{
ffffffffc020380a:	e0a2                	sd	s0,64(sp)
ffffffffc020380c:	f84a                	sd	s2,48(sp)
ffffffffc020380e:	e486                	sd	ra,72(sp)
ffffffffc0203810:	fc26                	sd	s1,56(sp)
ffffffffc0203812:	f052                	sd	s4,32(sp)
ffffffffc0203814:	ec56                	sd	s5,24(sp)
ffffffffc0203816:	e85a                	sd	s6,16(sp)
ffffffffc0203818:	e45e                	sd	s7,8(sp)
ffffffffc020381a:	e062                	sd	s8,0(sp)
ffffffffc020381c:	8432                	mv	s0,a2
ffffffffc020381e:	892a                	mv	s2,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203820:	fa3ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
    pgfault_num++;
ffffffffc0203824:	000b1797          	auipc	a5,0xb1
ffffffffc0203828:	7fc7a783          	lw	a5,2044(a5) # ffffffffc02b5020 <pgfault_num>
ffffffffc020382c:	2785                	addiw	a5,a5,1
ffffffffc020382e:	000b1717          	auipc	a4,0xb1
ffffffffc0203832:	7ef72923          	sw	a5,2034(a4) # ffffffffc02b5020 <pgfault_num>
    if (vma == NULL || vma->vm_start > addr)
ffffffffc0203836:	16050263          	beqz	a0,ffffffffc020399a <do_pgfault+0x198>
ffffffffc020383a:	651c                	ld	a5,8(a0)
ffffffffc020383c:	14f46f63          	bltu	s0,a5,ffffffffc020399a <do_pgfault+0x198>
    if (vma->vm_flags & VM_READ)
ffffffffc0203840:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0203842:	4a41                	li	s4,16
    if (vma->vm_flags & VM_READ)
ffffffffc0203844:	0017f713          	andi	a4,a5,1
ffffffffc0203848:	c311                	beqz	a4,ffffffffc020384c <do_pgfault+0x4a>
        perm |= PTE_R;
ffffffffc020384a:	4a49                	li	s4,18
    if (vma->vm_flags & VM_WRITE)
ffffffffc020384c:	0027f713          	andi	a4,a5,2
ffffffffc0203850:	c311                	beqz	a4,ffffffffc0203854 <do_pgfault+0x52>
        perm |= (PTE_W | PTE_R);
ffffffffc0203852:	4a59                	li	s4,22
    if (vma->vm_flags & VM_EXEC)
ffffffffc0203854:	8b91                	andi	a5,a5,4
ffffffffc0203856:	ef95                	bnez	a5,ffffffffc0203892 <do_pgfault+0x90>
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203858:	767d                	lui	a2,0xfffff
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc020385a:	01893503          	ld	a0,24(s2)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020385e:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc0203860:	85a2                	mv	a1,s0
ffffffffc0203862:	4605                	li	a2,1
ffffffffc0203864:	f38fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
ffffffffc0203868:	84aa                	mv	s1,a0
ffffffffc020386a:	14050163          	beqz	a0,ffffffffc02039ac <do_pgfault+0x1aa>
    if (*ptep == 0)
ffffffffc020386e:	611c                	ld	a5,0(a0)
ffffffffc0203870:	c785                	beqz	a5,ffffffffc0203898 <do_pgfault+0x96>
        if (error_code == 1)
ffffffffc0203872:	4785                	li	a5,1
ffffffffc0203874:	02f98b63          	beq	s3,a5,ffffffffc02038aa <do_pgfault+0xa8>
                    ret = 0;
ffffffffc0203878:	4501                	li	a0,0
}
ffffffffc020387a:	60a6                	ld	ra,72(sp)
ffffffffc020387c:	6406                	ld	s0,64(sp)
ffffffffc020387e:	74e2                	ld	s1,56(sp)
ffffffffc0203880:	7942                	ld	s2,48(sp)
ffffffffc0203882:	79a2                	ld	s3,40(sp)
ffffffffc0203884:	7a02                	ld	s4,32(sp)
ffffffffc0203886:	6ae2                	ld	s5,24(sp)
ffffffffc0203888:	6b42                	ld	s6,16(sp)
ffffffffc020388a:	6ba2                	ld	s7,8(sp)
ffffffffc020388c:	6c02                	ld	s8,0(sp)
ffffffffc020388e:	6161                	addi	sp,sp,80
ffffffffc0203890:	8082                	ret
        perm |= PTE_X;
ffffffffc0203892:	008a6a13          	ori	s4,s4,8
ffffffffc0203896:	b7c9                	j	ffffffffc0203858 <do_pgfault+0x56>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0203898:	01893503          	ld	a0,24(s2)
ffffffffc020389c:	8652                	mv	a2,s4
ffffffffc020389e:	85a2                	mv	a1,s0
ffffffffc02038a0:	e0dff0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc02038a4:	f971                	bnez	a0,ffffffffc0203878 <do_pgfault+0x76>
    ret = -E_NO_MEM;
ffffffffc02038a6:	5571                	li	a0,-4
                        goto failed;
ffffffffc02038a8:	bfc9                	j	ffffffffc020387a <do_pgfault+0x78>
            cprintf("do_pgfault: write fault for addr 0x%08x\n", addr);
ffffffffc02038aa:	85a2                	mv	a1,s0
ffffffffc02038ac:	00004517          	auipc	a0,0x4
ffffffffc02038b0:	a9450513          	addi	a0,a0,-1388 # ffffffffc0207340 <default_pmm_manager+0x898>
ffffffffc02038b4:	8e1fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
            if (*ptep & PTE_W)
ffffffffc02038b8:	6098                	ld	a4,0(s1)
ffffffffc02038ba:	00477793          	andi	a5,a4,4
ffffffffc02038be:	ffcd                	bnez	a5,ffffffffc0203878 <do_pgfault+0x76>
    if (!(pte & PTE_V))
ffffffffc02038c0:	00177793          	andi	a5,a4,1
ffffffffc02038c4:	12078663          	beqz	a5,ffffffffc02039f0 <do_pgfault+0x1ee>
    if (PPN(pa) >= npage)
ffffffffc02038c8:	000b1b97          	auipc	s7,0xb1
ffffffffc02038cc:	738b8b93          	addi	s7,s7,1848 # ffffffffc02b5000 <npage>
ffffffffc02038d0:	000bb783          	ld	a5,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc02038d4:	00271693          	slli	a3,a4,0x2
ffffffffc02038d8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02038da:	0ef6ff63          	bgeu	a3,a5,ffffffffc02039d8 <do_pgfault+0x1d6>
    return &pages[PPN(pa) - nbase];
ffffffffc02038de:	000b1c17          	auipc	s8,0xb1
ffffffffc02038e2:	72ac0c13          	addi	s8,s8,1834 # ffffffffc02b5008 <pages>
ffffffffc02038e6:	000c3a83          	ld	s5,0(s8)
ffffffffc02038ea:	00004b17          	auipc	s6,0x4
ffffffffc02038ee:	6ceb3b03          	ld	s6,1742(s6) # ffffffffc0207fb8 <nbase>
ffffffffc02038f2:	416686b3          	sub	a3,a3,s6
ffffffffc02038f6:	069a                	slli	a3,a3,0x6
ffffffffc02038f8:	9ab6                	add	s5,s5,a3
                if (page_ref(page) > 1)
ffffffffc02038fa:	000aa783          	lw	a5,0(s5)
ffffffffc02038fe:	06f9de63          	bge	s3,a5,ffffffffc020397a <do_pgfault+0x178>
                    cprintf("do_pgfault: shared page detected for addr 0x%08x\n", addr);
ffffffffc0203902:	85a2                	mv	a1,s0
ffffffffc0203904:	00004517          	auipc	a0,0x4
ffffffffc0203908:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0207370 <default_pmm_manager+0x8c8>
ffffffffc020390c:	889fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
                    struct Page *npage = alloc_page();
ffffffffc0203910:	4505                	li	a0,1
ffffffffc0203912:	dd2fe0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0203916:	84aa                	mv	s1,a0
                    if (npage == NULL)
ffffffffc0203918:	d559                	beqz	a0,ffffffffc02038a6 <do_pgfault+0xa4>
    return page - pages + nbase;
ffffffffc020391a:	000c3783          	ld	a5,0(s8)
    return KADDR(page2pa(page));
ffffffffc020391e:	577d                	li	a4,-1
ffffffffc0203920:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc0203924:	40f506b3          	sub	a3,a0,a5
ffffffffc0203928:	8699                	srai	a3,a3,0x6
ffffffffc020392a:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc020392c:	8331                	srli	a4,a4,0xc
ffffffffc020392e:	00e6f5b3          	and	a1,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203932:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203934:	08c5f663          	bgeu	a1,a2,ffffffffc02039c0 <do_pgfault+0x1be>
    return page - pages + nbase;
ffffffffc0203938:	40fa87b3          	sub	a5,s5,a5
ffffffffc020393c:	8799                	srai	a5,a5,0x6
ffffffffc020393e:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc0203940:	000b1597          	auipc	a1,0xb1
ffffffffc0203944:	6d85b583          	ld	a1,1752(a1) # ffffffffc02b5018 <va_pa_offset>
ffffffffc0203948:	8f7d                	and	a4,a4,a5
ffffffffc020394a:	00b68533          	add	a0,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc020394e:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203950:	06c77763          	bgeu	a4,a2,ffffffffc02039be <do_pgfault+0x1bc>
                    memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0203954:	6605                	lui	a2,0x1
ffffffffc0203956:	95be                	add	a1,a1,a5
ffffffffc0203958:	2f6020ef          	jal	ra,ffffffffc0205c4e <memcpy>
                    if (page_insert(mm->pgdir, npage, addr, perm) != 0)
ffffffffc020395c:	01893503          	ld	a0,24(s2)
ffffffffc0203960:	86d2                	mv	a3,s4
ffffffffc0203962:	8622                	mv	a2,s0
ffffffffc0203964:	85a6                	mv	a1,s1
ffffffffc0203966:	d27fe0ef          	jal	ra,ffffffffc020268c <page_insert>
ffffffffc020396a:	f00507e3          	beqz	a0,ffffffffc0203878 <do_pgfault+0x76>
                        free_page(npage);
ffffffffc020396e:	8526                	mv	a0,s1
ffffffffc0203970:	4585                	li	a1,1
ffffffffc0203972:	db0fe0ef          	jal	ra,ffffffffc0201f22 <free_pages>
    ret = -E_NO_MEM;
ffffffffc0203976:	5571                	li	a0,-4
ffffffffc0203978:	b709                	j	ffffffffc020387a <do_pgfault+0x78>
                    tlb_invalidate(mm->pgdir, addr);
ffffffffc020397a:	01893503          	ld	a0,24(s2)
                    *ptep |= PTE_W;
ffffffffc020397e:	00476713          	ori	a4,a4,4
                    tlb_invalidate(mm->pgdir, addr);
ffffffffc0203982:	85a2                	mv	a1,s0
                    *ptep |= PTE_W;
ffffffffc0203984:	e098                	sd	a4,0(s1)
                    tlb_invalidate(mm->pgdir, addr);
ffffffffc0203986:	d21ff0ef          	jal	ra,ffffffffc02036a6 <tlb_invalidate>
                    cprintf("do_pgfault: enabled write for addr 0x%08x\n", addr);
ffffffffc020398a:	85a2                	mv	a1,s0
ffffffffc020398c:	00004517          	auipc	a0,0x4
ffffffffc0203990:	a1c50513          	addi	a0,a0,-1508 # ffffffffc02073a8 <default_pmm_manager+0x900>
ffffffffc0203994:	801fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203998:	b5c5                	j	ffffffffc0203878 <do_pgfault+0x76>
        cprintf("do_pgfault: invalid vma for addr 0x%08x\n", addr);
ffffffffc020399a:	85a2                	mv	a1,s0
ffffffffc020399c:	00004517          	auipc	a0,0x4
ffffffffc02039a0:	93c50513          	addi	a0,a0,-1732 # ffffffffc02072d8 <default_pmm_manager+0x830>
ffffffffc02039a4:	ff0fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc02039a8:	5575                	li	a0,-3
        goto failed;
ffffffffc02039aa:	bdc1                	j	ffffffffc020387a <do_pgfault+0x78>
        cprintf("do_pgfault: get_pte returned NULL for addr 0x%08x\n", addr);
ffffffffc02039ac:	85a2                	mv	a1,s0
ffffffffc02039ae:	00004517          	auipc	a0,0x4
ffffffffc02039b2:	95a50513          	addi	a0,a0,-1702 # ffffffffc0207308 <default_pmm_manager+0x860>
ffffffffc02039b6:	fdefc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02039ba:	5571                	li	a0,-4
        goto failed;
ffffffffc02039bc:	bd7d                	j	ffffffffc020387a <do_pgfault+0x78>
ffffffffc02039be:	86be                	mv	a3,a5
ffffffffc02039c0:	00003617          	auipc	a2,0x3
ffffffffc02039c4:	12060613          	addi	a2,a2,288 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc02039c8:	07100593          	li	a1,113
ffffffffc02039cc:	00003517          	auipc	a0,0x3
ffffffffc02039d0:	13c50513          	addi	a0,a0,316 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02039d4:	abbfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02039d8:	00003617          	auipc	a2,0x3
ffffffffc02039dc:	1d860613          	addi	a2,a2,472 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc02039e0:	06900593          	li	a1,105
ffffffffc02039e4:	00003517          	auipc	a0,0x3
ffffffffc02039e8:	12450513          	addi	a0,a0,292 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02039ec:	aa3fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02039f0:	00003617          	auipc	a2,0x3
ffffffffc02039f4:	1e060613          	addi	a2,a2,480 # ffffffffc0206bd0 <default_pmm_manager+0x128>
ffffffffc02039f8:	07f00593          	li	a1,127
ffffffffc02039fc:	00003517          	auipc	a0,0x3
ffffffffc0203a00:	10c50513          	addi	a0,a0,268 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0203a04:	a8bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a08 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203a08:	6590                	ld	a2,8(a1)
ffffffffc0203a0a:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203a0e:	1141                	addi	sp,sp,-16
ffffffffc0203a10:	e406                	sd	ra,8(sp)
ffffffffc0203a12:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203a14:	01066763          	bltu	a2,a6,ffffffffc0203a22 <insert_vma_struct+0x1a>
ffffffffc0203a18:	a085                	j	ffffffffc0203a78 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203a1a:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203a1e:	04e66863          	bltu	a2,a4,ffffffffc0203a6e <insert_vma_struct+0x66>
ffffffffc0203a22:	86be                	mv	a3,a5
ffffffffc0203a24:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203a26:	fef51ae3          	bne	a0,a5,ffffffffc0203a1a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203a2a:	02a68463          	beq	a3,a0,ffffffffc0203a52 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203a2e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203a32:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203a36:	08e8f163          	bgeu	a7,a4,ffffffffc0203ab8 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a3a:	04e66f63          	bltu	a2,a4,ffffffffc0203a98 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203a3e:	00f50a63          	beq	a0,a5,ffffffffc0203a52 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203a42:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a46:	05076963          	bltu	a4,a6,ffffffffc0203a98 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203a4a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203a4e:	02c77363          	bgeu	a4,a2,ffffffffc0203a74 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203a52:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203a54:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203a56:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203a5a:	e390                	sd	a2,0(a5)
ffffffffc0203a5c:	e690                	sd	a2,8(a3)
}
ffffffffc0203a5e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203a60:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203a62:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203a64:	0017079b          	addiw	a5,a4,1
ffffffffc0203a68:	d11c                	sw	a5,32(a0)
}
ffffffffc0203a6a:	0141                	addi	sp,sp,16
ffffffffc0203a6c:	8082                	ret
    if (le_prev != list)
ffffffffc0203a6e:	fca690e3          	bne	a3,a0,ffffffffc0203a2e <insert_vma_struct+0x26>
ffffffffc0203a72:	bfd1                	j	ffffffffc0203a46 <insert_vma_struct+0x3e>
ffffffffc0203a74:	cfbff0ef          	jal	ra,ffffffffc020376e <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203a78:	00004697          	auipc	a3,0x4
ffffffffc0203a7c:	96068693          	addi	a3,a3,-1696 # ffffffffc02073d8 <default_pmm_manager+0x930>
ffffffffc0203a80:	00003617          	auipc	a2,0x3
ffffffffc0203a84:	c7860613          	addi	a2,a2,-904 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203a88:	10c00593          	li	a1,268
ffffffffc0203a8c:	00004517          	auipc	a0,0x4
ffffffffc0203a90:	83c50513          	addi	a0,a0,-1988 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203a94:	9fbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a98:	00004697          	auipc	a3,0x4
ffffffffc0203a9c:	98068693          	addi	a3,a3,-1664 # ffffffffc0207418 <default_pmm_manager+0x970>
ffffffffc0203aa0:	00003617          	auipc	a2,0x3
ffffffffc0203aa4:	c5860613          	addi	a2,a2,-936 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203aa8:	10500593          	li	a1,261
ffffffffc0203aac:	00004517          	auipc	a0,0x4
ffffffffc0203ab0:	81c50513          	addi	a0,a0,-2020 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203ab4:	9dbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203ab8:	00004697          	auipc	a3,0x4
ffffffffc0203abc:	94068693          	addi	a3,a3,-1728 # ffffffffc02073f8 <default_pmm_manager+0x950>
ffffffffc0203ac0:	00003617          	auipc	a2,0x3
ffffffffc0203ac4:	c3860613          	addi	a2,a2,-968 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203ac8:	10400593          	li	a1,260
ffffffffc0203acc:	00003517          	auipc	a0,0x3
ffffffffc0203ad0:	7fc50513          	addi	a0,a0,2044 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203ad4:	9bbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ad8 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203ad8:	591c                	lw	a5,48(a0)
{
ffffffffc0203ada:	1141                	addi	sp,sp,-16
ffffffffc0203adc:	e406                	sd	ra,8(sp)
ffffffffc0203ade:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203ae0:	e78d                	bnez	a5,ffffffffc0203b0a <mm_destroy+0x32>
ffffffffc0203ae2:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203ae4:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203ae6:	00a40c63          	beq	s0,a0,ffffffffc0203afe <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203aea:	6118                	ld	a4,0(a0)
ffffffffc0203aec:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203aee:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203af0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203af2:	e398                	sd	a4,0(a5)
ffffffffc0203af4:	ac2fe0ef          	jal	ra,ffffffffc0201db6 <kfree>
    return listelm->next;
ffffffffc0203af8:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203afa:	fea418e3          	bne	s0,a0,ffffffffc0203aea <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203afe:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203b00:	6402                	ld	s0,0(sp)
ffffffffc0203b02:	60a2                	ld	ra,8(sp)
ffffffffc0203b04:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203b06:	ab0fe06f          	j	ffffffffc0201db6 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203b0a:	00004697          	auipc	a3,0x4
ffffffffc0203b0e:	92e68693          	addi	a3,a3,-1746 # ffffffffc0207438 <default_pmm_manager+0x990>
ffffffffc0203b12:	00003617          	auipc	a2,0x3
ffffffffc0203b16:	be660613          	addi	a2,a2,-1050 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203b1a:	13000593          	li	a1,304
ffffffffc0203b1e:	00003517          	auipc	a0,0x3
ffffffffc0203b22:	7aa50513          	addi	a0,a0,1962 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203b26:	969fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b2a <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203b2a:	7139                	addi	sp,sp,-64
ffffffffc0203b2c:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203b2e:	6405                	lui	s0,0x1
ffffffffc0203b30:	147d                	addi	s0,s0,-1
ffffffffc0203b32:	77fd                	lui	a5,0xfffff
ffffffffc0203b34:	9622                	add	a2,a2,s0
ffffffffc0203b36:	962e                	add	a2,a2,a1
{
ffffffffc0203b38:	f426                	sd	s1,40(sp)
ffffffffc0203b3a:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203b3c:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203b40:	f04a                	sd	s2,32(sp)
ffffffffc0203b42:	ec4e                	sd	s3,24(sp)
ffffffffc0203b44:	e852                	sd	s4,16(sp)
ffffffffc0203b46:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203b48:	002005b7          	lui	a1,0x200
ffffffffc0203b4c:	00f67433          	and	s0,a2,a5
ffffffffc0203b50:	06b4e363          	bltu	s1,a1,ffffffffc0203bb6 <mm_map+0x8c>
ffffffffc0203b54:	0684f163          	bgeu	s1,s0,ffffffffc0203bb6 <mm_map+0x8c>
ffffffffc0203b58:	4785                	li	a5,1
ffffffffc0203b5a:	07fe                	slli	a5,a5,0x1f
ffffffffc0203b5c:	0487ed63          	bltu	a5,s0,ffffffffc0203bb6 <mm_map+0x8c>
ffffffffc0203b60:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203b62:	cd21                	beqz	a0,ffffffffc0203bba <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203b64:	85a6                	mv	a1,s1
ffffffffc0203b66:	8ab6                	mv	s5,a3
ffffffffc0203b68:	8a3a                	mv	s4,a4
ffffffffc0203b6a:	c59ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
ffffffffc0203b6e:	c501                	beqz	a0,ffffffffc0203b76 <mm_map+0x4c>
ffffffffc0203b70:	651c                	ld	a5,8(a0)
ffffffffc0203b72:	0487e263          	bltu	a5,s0,ffffffffc0203bb6 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b76:	03000513          	li	a0,48
ffffffffc0203b7a:	98cfe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203b7e:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203b80:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203b82:	02090163          	beqz	s2,ffffffffc0203ba4 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203b86:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203b88:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203b8c:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203b90:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203b94:	85ca                	mv	a1,s2
ffffffffc0203b96:	e73ff0ef          	jal	ra,ffffffffc0203a08 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203b9a:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203b9c:	000a0463          	beqz	s4,ffffffffc0203ba4 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203ba0:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>

out:
    return ret;
}
ffffffffc0203ba4:	70e2                	ld	ra,56(sp)
ffffffffc0203ba6:	7442                	ld	s0,48(sp)
ffffffffc0203ba8:	74a2                	ld	s1,40(sp)
ffffffffc0203baa:	7902                	ld	s2,32(sp)
ffffffffc0203bac:	69e2                	ld	s3,24(sp)
ffffffffc0203bae:	6a42                	ld	s4,16(sp)
ffffffffc0203bb0:	6aa2                	ld	s5,8(sp)
ffffffffc0203bb2:	6121                	addi	sp,sp,64
ffffffffc0203bb4:	8082                	ret
        return -E_INVAL;
ffffffffc0203bb6:	5575                	li	a0,-3
ffffffffc0203bb8:	b7f5                	j	ffffffffc0203ba4 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203bba:	00004697          	auipc	a3,0x4
ffffffffc0203bbe:	89668693          	addi	a3,a3,-1898 # ffffffffc0207450 <default_pmm_manager+0x9a8>
ffffffffc0203bc2:	00003617          	auipc	a2,0x3
ffffffffc0203bc6:	b3660613          	addi	a2,a2,-1226 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203bca:	14500593          	li	a1,325
ffffffffc0203bce:	00003517          	auipc	a0,0x3
ffffffffc0203bd2:	6fa50513          	addi	a0,a0,1786 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203bd6:	8b9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203bda <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203bda:	7139                	addi	sp,sp,-64
ffffffffc0203bdc:	fc06                	sd	ra,56(sp)
ffffffffc0203bde:	f822                	sd	s0,48(sp)
ffffffffc0203be0:	f426                	sd	s1,40(sp)
ffffffffc0203be2:	f04a                	sd	s2,32(sp)
ffffffffc0203be4:	ec4e                	sd	s3,24(sp)
ffffffffc0203be6:	e852                	sd	s4,16(sp)
ffffffffc0203be8:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203bea:	c52d                	beqz	a0,ffffffffc0203c54 <dup_mmap+0x7a>
ffffffffc0203bec:	892a                	mv	s2,a0
ffffffffc0203bee:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203bf0:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203bf2:	e595                	bnez	a1,ffffffffc0203c1e <dup_mmap+0x44>
ffffffffc0203bf4:	a085                	j	ffffffffc0203c54 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203bf6:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203bf8:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ed8>
        vma->vm_end = vm_end;
ffffffffc0203bfc:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203c00:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203c04:	e05ff0ef          	jal	ra,ffffffffc0203a08 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203c08:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0203c0c:	fe843603          	ld	a2,-24(s0)
ffffffffc0203c10:	6c8c                	ld	a1,24(s1)
ffffffffc0203c12:	01893503          	ld	a0,24(s2)
ffffffffc0203c16:	4701                	li	a4,0
ffffffffc0203c18:	faaff0ef          	jal	ra,ffffffffc02033c2 <copy_range>
ffffffffc0203c1c:	e105                	bnez	a0,ffffffffc0203c3c <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203c1e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203c20:	02848863          	beq	s1,s0,ffffffffc0203c50 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c24:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203c28:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203c2c:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203c30:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c34:	8d2fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203c38:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203c3a:	fd55                	bnez	a0,ffffffffc0203bf6 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203c3c:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203c3e:	70e2                	ld	ra,56(sp)
ffffffffc0203c40:	7442                	ld	s0,48(sp)
ffffffffc0203c42:	74a2                	ld	s1,40(sp)
ffffffffc0203c44:	7902                	ld	s2,32(sp)
ffffffffc0203c46:	69e2                	ld	s3,24(sp)
ffffffffc0203c48:	6a42                	ld	s4,16(sp)
ffffffffc0203c4a:	6aa2                	ld	s5,8(sp)
ffffffffc0203c4c:	6121                	addi	sp,sp,64
ffffffffc0203c4e:	8082                	ret
    return 0;
ffffffffc0203c50:	4501                	li	a0,0
ffffffffc0203c52:	b7f5                	j	ffffffffc0203c3e <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203c54:	00004697          	auipc	a3,0x4
ffffffffc0203c58:	80c68693          	addi	a3,a3,-2036 # ffffffffc0207460 <default_pmm_manager+0x9b8>
ffffffffc0203c5c:	00003617          	auipc	a2,0x3
ffffffffc0203c60:	a9c60613          	addi	a2,a2,-1380 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203c64:	16100593          	li	a1,353
ffffffffc0203c68:	00003517          	auipc	a0,0x3
ffffffffc0203c6c:	66050513          	addi	a0,a0,1632 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203c70:	81ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203c74 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203c74:	1101                	addi	sp,sp,-32
ffffffffc0203c76:	ec06                	sd	ra,24(sp)
ffffffffc0203c78:	e822                	sd	s0,16(sp)
ffffffffc0203c7a:	e426                	sd	s1,8(sp)
ffffffffc0203c7c:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203c7e:	c531                	beqz	a0,ffffffffc0203cca <exit_mmap+0x56>
ffffffffc0203c80:	591c                	lw	a5,48(a0)
ffffffffc0203c82:	84aa                	mv	s1,a0
ffffffffc0203c84:	e3b9                	bnez	a5,ffffffffc0203cca <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203c86:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203c88:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203c8c:	02850663          	beq	a0,s0,ffffffffc0203cb8 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203c90:	ff043603          	ld	a2,-16(s0)
ffffffffc0203c94:	fe843583          	ld	a1,-24(s0)
ffffffffc0203c98:	854a                	mv	a0,s2
ffffffffc0203c9a:	d7efe0ef          	jal	ra,ffffffffc0202218 <unmap_range>
ffffffffc0203c9e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203ca0:	fe8498e3          	bne	s1,s0,ffffffffc0203c90 <exit_mmap+0x1c>
ffffffffc0203ca4:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203ca6:	00848c63          	beq	s1,s0,ffffffffc0203cbe <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203caa:	ff043603          	ld	a2,-16(s0)
ffffffffc0203cae:	fe843583          	ld	a1,-24(s0)
ffffffffc0203cb2:	854a                	mv	a0,s2
ffffffffc0203cb4:	eaafe0ef          	jal	ra,ffffffffc020235e <exit_range>
ffffffffc0203cb8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203cba:	fe8498e3          	bne	s1,s0,ffffffffc0203caa <exit_mmap+0x36>
    }
}
ffffffffc0203cbe:	60e2                	ld	ra,24(sp)
ffffffffc0203cc0:	6442                	ld	s0,16(sp)
ffffffffc0203cc2:	64a2                	ld	s1,8(sp)
ffffffffc0203cc4:	6902                	ld	s2,0(sp)
ffffffffc0203cc6:	6105                	addi	sp,sp,32
ffffffffc0203cc8:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203cca:	00003697          	auipc	a3,0x3
ffffffffc0203cce:	7b668693          	addi	a3,a3,1974 # ffffffffc0207480 <default_pmm_manager+0x9d8>
ffffffffc0203cd2:	00003617          	auipc	a2,0x3
ffffffffc0203cd6:	a2660613          	addi	a2,a2,-1498 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203cda:	17a00593          	li	a1,378
ffffffffc0203cde:	00003517          	auipc	a0,0x3
ffffffffc0203ce2:	5ea50513          	addi	a0,a0,1514 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203ce6:	fa8fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203cea <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203cea:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203cec:	04000513          	li	a0,64
{
ffffffffc0203cf0:	fc06                	sd	ra,56(sp)
ffffffffc0203cf2:	f822                	sd	s0,48(sp)
ffffffffc0203cf4:	f426                	sd	s1,40(sp)
ffffffffc0203cf6:	f04a                	sd	s2,32(sp)
ffffffffc0203cf8:	ec4e                	sd	s3,24(sp)
ffffffffc0203cfa:	e852                	sd	s4,16(sp)
ffffffffc0203cfc:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203cfe:	808fe0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
    if (mm != NULL)
ffffffffc0203d02:	50050d63          	beqz	a0,ffffffffc020421c <vmm_init+0x532>
ffffffffc0203d06:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203d08:	e508                	sd	a0,8(a0)
ffffffffc0203d0a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203d0c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203d10:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203d14:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203d18:	02053423          	sd	zero,40(a0)
ffffffffc0203d1c:	02052823          	sw	zero,48(a0)
ffffffffc0203d20:	02053c23          	sd	zero,56(a0)
ffffffffc0203d24:	03200413          	li	s0,50
ffffffffc0203d28:	a811                	j	ffffffffc0203d3c <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203d2a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203d2c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203d2e:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203d32:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203d34:	8526                	mv	a0,s1
ffffffffc0203d36:	cd3ff0ef          	jal	ra,ffffffffc0203a08 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203d3a:	c80d                	beqz	s0,ffffffffc0203d6c <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d3c:	03000513          	li	a0,48
ffffffffc0203d40:	fc7fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203d44:	85aa                	mv	a1,a0
ffffffffc0203d46:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203d4a:	f165                	bnez	a0,ffffffffc0203d2a <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203d4c:	00004697          	auipc	a3,0x4
ffffffffc0203d50:	96468693          	addi	a3,a3,-1692 # ffffffffc02076b0 <default_pmm_manager+0xc08>
ffffffffc0203d54:	00003617          	auipc	a2,0x3
ffffffffc0203d58:	9a460613          	addi	a2,a2,-1628 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203d5c:	1be00593          	li	a1,446
ffffffffc0203d60:	00003517          	auipc	a0,0x3
ffffffffc0203d64:	56850513          	addi	a0,a0,1384 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203d68:	f26fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203d6c:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d70:	1f900913          	li	s2,505
ffffffffc0203d74:	a819                	j	ffffffffc0203d8a <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203d76:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203d78:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203d7a:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d7e:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203d80:	8526                	mv	a0,s1
ffffffffc0203d82:	c87ff0ef          	jal	ra,ffffffffc0203a08 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d86:	03240a63          	beq	s0,s2,ffffffffc0203dba <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d8a:	03000513          	li	a0,48
ffffffffc0203d8e:	f79fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203d92:	85aa                	mv	a1,a0
ffffffffc0203d94:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203d98:	fd79                	bnez	a0,ffffffffc0203d76 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203d9a:	00004697          	auipc	a3,0x4
ffffffffc0203d9e:	91668693          	addi	a3,a3,-1770 # ffffffffc02076b0 <default_pmm_manager+0xc08>
ffffffffc0203da2:	00003617          	auipc	a2,0x3
ffffffffc0203da6:	95660613          	addi	a2,a2,-1706 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203daa:	1c500593          	li	a1,453
ffffffffc0203dae:	00003517          	auipc	a0,0x3
ffffffffc0203db2:	51a50513          	addi	a0,a0,1306 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203db6:	ed8fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203dba:	649c                	ld	a5,8(s1)
ffffffffc0203dbc:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203dbe:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203dc2:	2cf48563          	beq	s1,a5,ffffffffc020408c <vmm_init+0x3a2>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203dc6:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd49fa4>
ffffffffc0203dca:	ffe70693          	addi	a3,a4,-2
ffffffffc0203dce:	20d61f63          	bne	a2,a3,ffffffffc0203fec <vmm_init+0x302>
ffffffffc0203dd2:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203dd6:	20e69b63          	bne	a3,a4,ffffffffc0203fec <vmm_init+0x302>
    for (i = 1; i <= step2; i++)
ffffffffc0203dda:	0715                	addi	a4,a4,5
ffffffffc0203ddc:	679c                	ld	a5,8(a5)
ffffffffc0203dde:	feb712e3          	bne	a4,a1,ffffffffc0203dc2 <vmm_init+0xd8>
ffffffffc0203de2:	4a1d                	li	s4,7
ffffffffc0203de4:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203de6:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203dea:	85a2                	mv	a1,s0
ffffffffc0203dec:	8526                	mv	a0,s1
ffffffffc0203dee:	9d5ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
ffffffffc0203df2:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203df4:	2a050c63          	beqz	a0,ffffffffc02040ac <vmm_init+0x3c2>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203df8:	00140593          	addi	a1,s0,1
ffffffffc0203dfc:	8526                	mv	a0,s1
ffffffffc0203dfe:	9c5ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
ffffffffc0203e02:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203e04:	32050463          	beqz	a0,ffffffffc020412c <vmm_init+0x442>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203e08:	85d2                	mv	a1,s4
ffffffffc0203e0a:	8526                	mv	a0,s1
ffffffffc0203e0c:	9b7ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203e10:	2c051e63          	bnez	a0,ffffffffc02040ec <vmm_init+0x402>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203e14:	00340593          	addi	a1,s0,3
ffffffffc0203e18:	8526                	mv	a0,s1
ffffffffc0203e1a:	9a9ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203e1e:	2a051763          	bnez	a0,ffffffffc02040cc <vmm_init+0x3e2>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203e22:	00440593          	addi	a1,s0,4
ffffffffc0203e26:	8526                	mv	a0,s1
ffffffffc0203e28:	99bff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203e2c:	2e051063          	bnez	a0,ffffffffc020410c <vmm_init+0x422>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203e30:	00893783          	ld	a5,8(s2)
ffffffffc0203e34:	1c879c63          	bne	a5,s0,ffffffffc020400c <vmm_init+0x322>
ffffffffc0203e38:	01093783          	ld	a5,16(s2)
ffffffffc0203e3c:	1cfa1863          	bne	s4,a5,ffffffffc020400c <vmm_init+0x322>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203e40:	0089b783          	ld	a5,8(s3)
ffffffffc0203e44:	1e879463          	bne	a5,s0,ffffffffc020402c <vmm_init+0x342>
ffffffffc0203e48:	0109b783          	ld	a5,16(s3)
ffffffffc0203e4c:	1efa1063          	bne	s4,a5,ffffffffc020402c <vmm_init+0x342>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203e50:	0415                	addi	s0,s0,5
ffffffffc0203e52:	0a15                	addi	s4,s4,5
ffffffffc0203e54:	f9541be3          	bne	s0,s5,ffffffffc0203dea <vmm_init+0x100>
ffffffffc0203e58:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203e5a:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203e5c:	85a2                	mv	a1,s0
ffffffffc0203e5e:	8526                	mv	a0,s1
ffffffffc0203e60:	963ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
ffffffffc0203e64:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203e68:	c90d                	beqz	a0,ffffffffc0203e9a <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203e6a:	6914                	ld	a3,16(a0)
ffffffffc0203e6c:	6510                	ld	a2,8(a0)
ffffffffc0203e6e:	00003517          	auipc	a0,0x3
ffffffffc0203e72:	73250513          	addi	a0,a0,1842 # ffffffffc02075a0 <default_pmm_manager+0xaf8>
ffffffffc0203e76:	b1efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203e7a:	00003697          	auipc	a3,0x3
ffffffffc0203e7e:	74e68693          	addi	a3,a3,1870 # ffffffffc02075c8 <default_pmm_manager+0xb20>
ffffffffc0203e82:	00003617          	auipc	a2,0x3
ffffffffc0203e86:	87660613          	addi	a2,a2,-1930 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203e8a:	1eb00593          	li	a1,491
ffffffffc0203e8e:	00003517          	auipc	a0,0x3
ffffffffc0203e92:	43a50513          	addi	a0,a0,1082 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0203e96:	df8fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203e9a:	147d                	addi	s0,s0,-1
ffffffffc0203e9c:	fd2410e3          	bne	s0,s2,ffffffffc0203e5c <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203ea0:	8526                	mv	a0,s1
ffffffffc0203ea2:	c37ff0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ea6:	00003517          	auipc	a0,0x3
ffffffffc0203eaa:	73a50513          	addi	a0,a0,1850 # ffffffffc02075e0 <default_pmm_manager+0xb38>
ffffffffc0203eae:	ae6fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203eb2:	04000513          	li	a0,64
ffffffffc0203eb6:	e51fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203eba:	84aa                	mv	s1,a0
    if (mm != NULL)
ffffffffc0203ebc:	1a050863          	beqz	a0,ffffffffc020406c <vmm_init+0x382>
    elm->prev = elm->next = elm;
ffffffffc0203ec0:	e508                	sd	a0,8(a0)
ffffffffc0203ec2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203ec4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203ec8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203ecc:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203ed0:	02053423          	sd	zero,40(a0)
ffffffffc0203ed4:	02052823          	sw	zero,48(a0)
ffffffffc0203ed8:	02053c23          	sd	zero,56(a0)
    if ((page = alloc_page()) == NULL)
ffffffffc0203edc:	4505                	li	a0,1
ffffffffc0203ede:	806fe0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0203ee2:	26050563          	beqz	a0,ffffffffc020414c <vmm_init+0x462>
    return page - pages + nbase;
ffffffffc0203ee6:	000b1717          	auipc	a4,0xb1
ffffffffc0203eea:	12273703          	ld	a4,290(a4) # ffffffffc02b5008 <pages>
ffffffffc0203eee:	40e50733          	sub	a4,a0,a4
ffffffffc0203ef2:	00004797          	auipc	a5,0x4
ffffffffc0203ef6:	0c67b783          	ld	a5,198(a5) # ffffffffc0207fb8 <nbase>
ffffffffc0203efa:	8719                	srai	a4,a4,0x6
ffffffffc0203efc:	973e                	add	a4,a4,a5
    return KADDR(page2pa(page));
ffffffffc0203efe:	00c45793          	srli	a5,s0,0xc
ffffffffc0203f02:	8ff9                	and	a5,a5,a4
ffffffffc0203f04:	000b1617          	auipc	a2,0xb1
ffffffffc0203f08:	0fc63603          	ld	a2,252(a2) # ffffffffc02b5000 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f0c:	00c71693          	slli	a3,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0203f10:	28c7fa63          	bgeu	a5,a2,ffffffffc02041a4 <vmm_init+0x4ba>
ffffffffc0203f14:	000b1417          	auipc	s0,0xb1
ffffffffc0203f18:	10443403          	ld	s0,260(s0) # ffffffffc02b5018 <va_pa_offset>
ffffffffc0203f1c:	9436                	add	s0,s0,a3
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0203f1e:	6605                	lui	a2,0x1
ffffffffc0203f20:	000b1597          	auipc	a1,0xb1
ffffffffc0203f24:	0d85b583          	ld	a1,216(a1) # ffffffffc02b4ff8 <boot_pgdir_va>
ffffffffc0203f28:	8522                	mv	a0,s0
ffffffffc0203f2a:	525010ef          	jal	ra,ffffffffc0205c4e <memcpy>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203f2e:	03000513          	li	a0,48
    mm->pgdir = pgdir;
ffffffffc0203f32:	ec80                	sd	s0,24(s1)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203f34:	dd3fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0203f38:	842a                	mv	s0,a0
    if (vma != NULL)
ffffffffc0203f3a:	10050963          	beqz	a0,ffffffffc020404c <vmm_init+0x362>
        vma->vm_end = vm_end;
ffffffffc0203f3e:	002007b7          	lui	a5,0x200
ffffffffc0203f42:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0203f44:	4789                	li	a5,2
    }

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203f46:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203f48:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0203f4c:	8526                	mv	a0,s1
        vma->vm_flags = vm_flags;
ffffffffc0203f4e:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0203f50:	ab9ff0ef          	jal	ra,ffffffffc0203a08 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203f54:	10000593          	li	a1,256
ffffffffc0203f58:	8526                	mv	a0,s1
ffffffffc0203f5a:	869ff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
ffffffffc0203f5e:	2ca41f63          	bne	s0,a0,ffffffffc020423c <vmm_init+0x552>

    int ret = 0;
    ret = do_pgfault(mm, 0, addr);
ffffffffc0203f62:	10000613          	li	a2,256
ffffffffc0203f66:	4581                	li	a1,0
ffffffffc0203f68:	8526                	mv	a0,s1
ffffffffc0203f6a:	899ff0ef          	jal	ra,ffffffffc0203802 <do_pgfault>
    assert(ret == 0);
ffffffffc0203f6e:	30051763          	bnez	a0,ffffffffc020427c <vmm_init+0x592>

    // check the correctness of page table
    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203f72:	6c88                	ld	a0,24(s1)
ffffffffc0203f74:	4601                	li	a2,0
ffffffffc0203f76:	10000593          	li	a1,256
ffffffffc0203f7a:	822fe0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    assert(ptep != NULL);
ffffffffc0203f7e:	2c050f63          	beqz	a0,ffffffffc020425c <vmm_init+0x572>
    assert((*ptep & PTE_U) != 0);
ffffffffc0203f82:	611c                	ld	a5,0(a0)
ffffffffc0203f84:	0107f713          	andi	a4,a5,16
ffffffffc0203f88:	26070a63          	beqz	a4,ffffffffc02041fc <vmm_init+0x512>
    assert((*ptep & PTE_W) != 0);
ffffffffc0203f8c:	8b91                	andi	a5,a5,4
ffffffffc0203f8e:	24078763          	beqz	a5,ffffffffc02041dc <vmm_init+0x4f2>

    addr = 0x1000;
    ret = do_pgfault(mm, 0, addr);
ffffffffc0203f92:	6605                	lui	a2,0x1
ffffffffc0203f94:	4581                	li	a1,0
ffffffffc0203f96:	8526                	mv	a0,s1
ffffffffc0203f98:	86bff0ef          	jal	ra,ffffffffc0203802 <do_pgfault>
    assert(ret == 0);
ffffffffc0203f9c:	22051063          	bnez	a0,ffffffffc02041bc <vmm_init+0x4d2>

    ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203fa0:	6c88                	ld	a0,24(s1)
ffffffffc0203fa2:	4601                	li	a2,0
ffffffffc0203fa4:	6585                	lui	a1,0x1
ffffffffc0203fa6:	ff7fd0ef          	jal	ra,ffffffffc0201f9c <get_pte>
    assert(ptep != NULL);
ffffffffc0203faa:	1a050d63          	beqz	a0,ffffffffc0204164 <vmm_init+0x47a>
    assert((*ptep & PTE_U) != 0);
ffffffffc0203fae:	611c                	ld	a5,0(a0)
ffffffffc0203fb0:	0107f713          	andi	a4,a5,16
ffffffffc0203fb4:	1c070863          	beqz	a4,ffffffffc0204184 <vmm_init+0x49a>
    assert((*ptep & PTE_W) != 0);
ffffffffc0203fb8:	8b91                	andi	a5,a5,4
ffffffffc0203fba:	2e078163          	beqz	a5,ffffffffc020429c <vmm_init+0x5b2>

    mm_destroy(mm);
ffffffffc0203fbe:	8526                	mv	a0,s1
ffffffffc0203fc0:	b19ff0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203fc4:	00003517          	auipc	a0,0x3
ffffffffc0203fc8:	6b450513          	addi	a0,a0,1716 # ffffffffc0207678 <default_pmm_manager+0xbd0>
ffffffffc0203fcc:	9c8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203fd0:	7442                	ld	s0,48(sp)
ffffffffc0203fd2:	70e2                	ld	ra,56(sp)
ffffffffc0203fd4:	74a2                	ld	s1,40(sp)
ffffffffc0203fd6:	7902                	ld	s2,32(sp)
ffffffffc0203fd8:	69e2                	ld	s3,24(sp)
ffffffffc0203fda:	6a42                	ld	s4,16(sp)
ffffffffc0203fdc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203fde:	00003517          	auipc	a0,0x3
ffffffffc0203fe2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0207698 <default_pmm_manager+0xbf0>
}
ffffffffc0203fe6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203fe8:	9acfc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203fec:	00003697          	auipc	a3,0x3
ffffffffc0203ff0:	4cc68693          	addi	a3,a3,1228 # ffffffffc02074b8 <default_pmm_manager+0xa10>
ffffffffc0203ff4:	00002617          	auipc	a2,0x2
ffffffffc0203ff8:	70460613          	addi	a2,a2,1796 # ffffffffc02066f8 <commands+0x828>
ffffffffc0203ffc:	1cf00593          	li	a1,463
ffffffffc0204000:	00003517          	auipc	a0,0x3
ffffffffc0204004:	2c850513          	addi	a0,a0,712 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204008:	c86fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020400c:	00003697          	auipc	a3,0x3
ffffffffc0204010:	53468693          	addi	a3,a3,1332 # ffffffffc0207540 <default_pmm_manager+0xa98>
ffffffffc0204014:	00002617          	auipc	a2,0x2
ffffffffc0204018:	6e460613          	addi	a2,a2,1764 # ffffffffc02066f8 <commands+0x828>
ffffffffc020401c:	1e000593          	li	a1,480
ffffffffc0204020:	00003517          	auipc	a0,0x3
ffffffffc0204024:	2a850513          	addi	a0,a0,680 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204028:	c66fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020402c:	00003697          	auipc	a3,0x3
ffffffffc0204030:	54468693          	addi	a3,a3,1348 # ffffffffc0207570 <default_pmm_manager+0xac8>
ffffffffc0204034:	00002617          	auipc	a2,0x2
ffffffffc0204038:	6c460613          	addi	a2,a2,1732 # ffffffffc02066f8 <commands+0x828>
ffffffffc020403c:	1e100593          	li	a1,481
ffffffffc0204040:	00003517          	auipc	a0,0x3
ffffffffc0204044:	28850513          	addi	a0,a0,648 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204048:	c46fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(vma != NULL);
ffffffffc020404c:	00003697          	auipc	a3,0x3
ffffffffc0204050:	66468693          	addi	a3,a3,1636 # ffffffffc02076b0 <default_pmm_manager+0xc08>
ffffffffc0204054:	00002617          	auipc	a2,0x2
ffffffffc0204058:	6a460613          	addi	a2,a2,1700 # ffffffffc02066f8 <commands+0x828>
ffffffffc020405c:	20300593          	li	a1,515
ffffffffc0204060:	00003517          	auipc	a0,0x3
ffffffffc0204064:	26850513          	addi	a0,a0,616 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204068:	c26fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc020406c:	00003697          	auipc	a3,0x3
ffffffffc0204070:	3e468693          	addi	a3,a3,996 # ffffffffc0207450 <default_pmm_manager+0x9a8>
ffffffffc0204074:	00002617          	auipc	a2,0x2
ffffffffc0204078:	68460613          	addi	a2,a2,1668 # ffffffffc02066f8 <commands+0x828>
ffffffffc020407c:	1fa00593          	li	a1,506
ffffffffc0204080:	00003517          	auipc	a0,0x3
ffffffffc0204084:	24850513          	addi	a0,a0,584 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204088:	c06fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020408c:	00003697          	auipc	a3,0x3
ffffffffc0204090:	41468693          	addi	a3,a3,1044 # ffffffffc02074a0 <default_pmm_manager+0x9f8>
ffffffffc0204094:	00002617          	auipc	a2,0x2
ffffffffc0204098:	66460613          	addi	a2,a2,1636 # ffffffffc02066f8 <commands+0x828>
ffffffffc020409c:	1cd00593          	li	a1,461
ffffffffc02040a0:	00003517          	auipc	a0,0x3
ffffffffc02040a4:	22850513          	addi	a0,a0,552 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02040a8:	be6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc02040ac:	00003697          	auipc	a3,0x3
ffffffffc02040b0:	44468693          	addi	a3,a3,1092 # ffffffffc02074f0 <default_pmm_manager+0xa48>
ffffffffc02040b4:	00002617          	auipc	a2,0x2
ffffffffc02040b8:	64460613          	addi	a2,a2,1604 # ffffffffc02066f8 <commands+0x828>
ffffffffc02040bc:	1d600593          	li	a1,470
ffffffffc02040c0:	00003517          	auipc	a0,0x3
ffffffffc02040c4:	20850513          	addi	a0,a0,520 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02040c8:	bc6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc02040cc:	00003697          	auipc	a3,0x3
ffffffffc02040d0:	45468693          	addi	a3,a3,1108 # ffffffffc0207520 <default_pmm_manager+0xa78>
ffffffffc02040d4:	00002617          	auipc	a2,0x2
ffffffffc02040d8:	62460613          	addi	a2,a2,1572 # ffffffffc02066f8 <commands+0x828>
ffffffffc02040dc:	1dc00593          	li	a1,476
ffffffffc02040e0:	00003517          	auipc	a0,0x3
ffffffffc02040e4:	1e850513          	addi	a0,a0,488 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02040e8:	ba6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc02040ec:	00003697          	auipc	a3,0x3
ffffffffc02040f0:	42468693          	addi	a3,a3,1060 # ffffffffc0207510 <default_pmm_manager+0xa68>
ffffffffc02040f4:	00002617          	auipc	a2,0x2
ffffffffc02040f8:	60460613          	addi	a2,a2,1540 # ffffffffc02066f8 <commands+0x828>
ffffffffc02040fc:	1da00593          	li	a1,474
ffffffffc0204100:	00003517          	auipc	a0,0x3
ffffffffc0204104:	1c850513          	addi	a0,a0,456 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204108:	b86fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc020410c:	00003697          	auipc	a3,0x3
ffffffffc0204110:	42468693          	addi	a3,a3,1060 # ffffffffc0207530 <default_pmm_manager+0xa88>
ffffffffc0204114:	00002617          	auipc	a2,0x2
ffffffffc0204118:	5e460613          	addi	a2,a2,1508 # ffffffffc02066f8 <commands+0x828>
ffffffffc020411c:	1de00593          	li	a1,478
ffffffffc0204120:	00003517          	auipc	a0,0x3
ffffffffc0204124:	1a850513          	addi	a0,a0,424 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204128:	b66fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc020412c:	00003697          	auipc	a3,0x3
ffffffffc0204130:	3d468693          	addi	a3,a3,980 # ffffffffc0207500 <default_pmm_manager+0xa58>
ffffffffc0204134:	00002617          	auipc	a2,0x2
ffffffffc0204138:	5c460613          	addi	a2,a2,1476 # ffffffffc02066f8 <commands+0x828>
ffffffffc020413c:	1d800593          	li	a1,472
ffffffffc0204140:	00003517          	auipc	a0,0x3
ffffffffc0204144:	18850513          	addi	a0,a0,392 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204148:	b46fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("setup_pgdir failed\n");
ffffffffc020414c:	00003617          	auipc	a2,0x3
ffffffffc0204150:	4b460613          	addi	a2,a2,1204 # ffffffffc0207600 <default_pmm_manager+0xb58>
ffffffffc0204154:	1ff00593          	li	a1,511
ffffffffc0204158:	00003517          	auipc	a0,0x3
ffffffffc020415c:	17050513          	addi	a0,a0,368 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204160:	b2efc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ptep != NULL);
ffffffffc0204164:	00003697          	auipc	a3,0x3
ffffffffc0204168:	4d468693          	addi	a3,a3,1236 # ffffffffc0207638 <default_pmm_manager+0xb90>
ffffffffc020416c:	00002617          	auipc	a2,0x2
ffffffffc0204170:	58c60613          	addi	a2,a2,1420 # ffffffffc02066f8 <commands+0x828>
ffffffffc0204174:	21900593          	li	a1,537
ffffffffc0204178:	00003517          	auipc	a0,0x3
ffffffffc020417c:	15050513          	addi	a0,a0,336 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204180:	b0efc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) != 0);
ffffffffc0204184:	00003697          	auipc	a3,0x3
ffffffffc0204188:	4c468693          	addi	a3,a3,1220 # ffffffffc0207648 <default_pmm_manager+0xba0>
ffffffffc020418c:	00002617          	auipc	a2,0x2
ffffffffc0204190:	56c60613          	addi	a2,a2,1388 # ffffffffc02066f8 <commands+0x828>
ffffffffc0204194:	21a00593          	li	a1,538
ffffffffc0204198:	00003517          	auipc	a0,0x3
ffffffffc020419c:	13050513          	addi	a0,a0,304 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02041a0:	aeefc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02041a4:	00003617          	auipc	a2,0x3
ffffffffc02041a8:	93c60613          	addi	a2,a2,-1732 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc02041ac:	07100593          	li	a1,113
ffffffffc02041b0:	00003517          	auipc	a0,0x3
ffffffffc02041b4:	95850513          	addi	a0,a0,-1704 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02041b8:	ad6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ret == 0);
ffffffffc02041bc:	00003697          	auipc	a3,0x3
ffffffffc02041c0:	0c468693          	addi	a3,a3,196 # ffffffffc0207280 <default_pmm_manager+0x7d8>
ffffffffc02041c4:	00002617          	auipc	a2,0x2
ffffffffc02041c8:	53460613          	addi	a2,a2,1332 # ffffffffc02066f8 <commands+0x828>
ffffffffc02041cc:	21600593          	li	a1,534
ffffffffc02041d0:	00003517          	auipc	a0,0x3
ffffffffc02041d4:	0f850513          	addi	a0,a0,248 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02041d8:	ab6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_W) != 0);
ffffffffc02041dc:	00003697          	auipc	a3,0x3
ffffffffc02041e0:	48468693          	addi	a3,a3,1156 # ffffffffc0207660 <default_pmm_manager+0xbb8>
ffffffffc02041e4:	00002617          	auipc	a2,0x2
ffffffffc02041e8:	51460613          	addi	a2,a2,1300 # ffffffffc02066f8 <commands+0x828>
ffffffffc02041ec:	21200593          	li	a1,530
ffffffffc02041f0:	00003517          	auipc	a0,0x3
ffffffffc02041f4:	0d850513          	addi	a0,a0,216 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02041f8:	a96fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) != 0);
ffffffffc02041fc:	00003697          	auipc	a3,0x3
ffffffffc0204200:	44c68693          	addi	a3,a3,1100 # ffffffffc0207648 <default_pmm_manager+0xba0>
ffffffffc0204204:	00002617          	auipc	a2,0x2
ffffffffc0204208:	4f460613          	addi	a2,a2,1268 # ffffffffc02066f8 <commands+0x828>
ffffffffc020420c:	21100593          	li	a1,529
ffffffffc0204210:	00003517          	auipc	a0,0x3
ffffffffc0204214:	0b850513          	addi	a0,a0,184 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204218:	a76fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc020421c:	00003697          	auipc	a3,0x3
ffffffffc0204220:	23468693          	addi	a3,a3,564 # ffffffffc0207450 <default_pmm_manager+0x9a8>
ffffffffc0204224:	00002617          	auipc	a2,0x2
ffffffffc0204228:	4d460613          	addi	a2,a2,1236 # ffffffffc02066f8 <commands+0x828>
ffffffffc020422c:	1b600593          	li	a1,438
ffffffffc0204230:	00003517          	auipc	a0,0x3
ffffffffc0204234:	09850513          	addi	a0,a0,152 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204238:	a56fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020423c:	00003697          	auipc	a3,0x3
ffffffffc0204240:	3dc68693          	addi	a3,a3,988 # ffffffffc0207618 <default_pmm_manager+0xb70>
ffffffffc0204244:	00002617          	auipc	a2,0x2
ffffffffc0204248:	4b460613          	addi	a2,a2,1204 # ffffffffc02066f8 <commands+0x828>
ffffffffc020424c:	20800593          	li	a1,520
ffffffffc0204250:	00003517          	auipc	a0,0x3
ffffffffc0204254:	07850513          	addi	a0,a0,120 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204258:	a36fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ptep != NULL);
ffffffffc020425c:	00003697          	auipc	a3,0x3
ffffffffc0204260:	3dc68693          	addi	a3,a3,988 # ffffffffc0207638 <default_pmm_manager+0xb90>
ffffffffc0204264:	00002617          	auipc	a2,0x2
ffffffffc0204268:	49460613          	addi	a2,a2,1172 # ffffffffc02066f8 <commands+0x828>
ffffffffc020426c:	21000593          	li	a1,528
ffffffffc0204270:	00003517          	auipc	a0,0x3
ffffffffc0204274:	05850513          	addi	a0,a0,88 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204278:	a16fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ret == 0);
ffffffffc020427c:	00003697          	auipc	a3,0x3
ffffffffc0204280:	00468693          	addi	a3,a3,4 # ffffffffc0207280 <default_pmm_manager+0x7d8>
ffffffffc0204284:	00002617          	auipc	a2,0x2
ffffffffc0204288:	47460613          	addi	a2,a2,1140 # ffffffffc02066f8 <commands+0x828>
ffffffffc020428c:	20c00593          	li	a1,524
ffffffffc0204290:	00003517          	auipc	a0,0x3
ffffffffc0204294:	03850513          	addi	a0,a0,56 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc0204298:	9f6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_W) != 0);
ffffffffc020429c:	00003697          	auipc	a3,0x3
ffffffffc02042a0:	3c468693          	addi	a3,a3,964 # ffffffffc0207660 <default_pmm_manager+0xbb8>
ffffffffc02042a4:	00002617          	auipc	a2,0x2
ffffffffc02042a8:	45460613          	addi	a2,a2,1108 # ffffffffc02066f8 <commands+0x828>
ffffffffc02042ac:	21b00593          	li	a1,539
ffffffffc02042b0:	00003517          	auipc	a0,0x3
ffffffffc02042b4:	01850513          	addi	a0,a0,24 # ffffffffc02072c8 <default_pmm_manager+0x820>
ffffffffc02042b8:	9d6fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02042bc <user_mem_check>:
}

bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc02042bc:	7179                	addi	sp,sp,-48
ffffffffc02042be:	f022                	sd	s0,32(sp)
ffffffffc02042c0:	f406                	sd	ra,40(sp)
ffffffffc02042c2:	ec26                	sd	s1,24(sp)
ffffffffc02042c4:	e84a                	sd	s2,16(sp)
ffffffffc02042c6:	e44e                	sd	s3,8(sp)
ffffffffc02042c8:	e052                	sd	s4,0(sp)
ffffffffc02042ca:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc02042cc:	c135                	beqz	a0,ffffffffc0204330 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc02042ce:	002007b7          	lui	a5,0x200
ffffffffc02042d2:	04f5e663          	bltu	a1,a5,ffffffffc020431e <user_mem_check+0x62>
ffffffffc02042d6:	00c584b3          	add	s1,a1,a2
ffffffffc02042da:	0495f263          	bgeu	a1,s1,ffffffffc020431e <user_mem_check+0x62>
ffffffffc02042de:	4785                	li	a5,1
ffffffffc02042e0:	07fe                	slli	a5,a5,0x1f
ffffffffc02042e2:	0297ee63          	bltu	a5,s1,ffffffffc020431e <user_mem_check+0x62>
ffffffffc02042e6:	892a                	mv	s2,a0
ffffffffc02042e8:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc02042ea:	6a05                	lui	s4,0x1
ffffffffc02042ec:	a821                	j	ffffffffc0204304 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc02042ee:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc02042f2:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc02042f4:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc02042f6:	c685                	beqz	a3,ffffffffc020431e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc02042f8:	c399                	beqz	a5,ffffffffc02042fe <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc02042fa:	02e46263          	bltu	s0,a4,ffffffffc020431e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc02042fe:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0204300:	04947663          	bgeu	s0,s1,ffffffffc020434c <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0204304:	85a2                	mv	a1,s0
ffffffffc0204306:	854a                	mv	a0,s2
ffffffffc0204308:	cbaff0ef          	jal	ra,ffffffffc02037c2 <find_vma>
ffffffffc020430c:	c909                	beqz	a0,ffffffffc020431e <user_mem_check+0x62>
ffffffffc020430e:	6518                	ld	a4,8(a0)
ffffffffc0204310:	00e46763          	bltu	s0,a4,ffffffffc020431e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204314:	4d1c                	lw	a5,24(a0)
ffffffffc0204316:	fc099ce3          	bnez	s3,ffffffffc02042ee <user_mem_check+0x32>
ffffffffc020431a:	8b85                	andi	a5,a5,1
ffffffffc020431c:	f3ed                	bnez	a5,ffffffffc02042fe <user_mem_check+0x42>
            return 0;
ffffffffc020431e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204320:	70a2                	ld	ra,40(sp)
ffffffffc0204322:	7402                	ld	s0,32(sp)
ffffffffc0204324:	64e2                	ld	s1,24(sp)
ffffffffc0204326:	6942                	ld	s2,16(sp)
ffffffffc0204328:	69a2                	ld	s3,8(sp)
ffffffffc020432a:	6a02                	ld	s4,0(sp)
ffffffffc020432c:	6145                	addi	sp,sp,48
ffffffffc020432e:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204330:	c02007b7          	lui	a5,0xc0200
ffffffffc0204334:	4501                	li	a0,0
ffffffffc0204336:	fef5e5e3          	bltu	a1,a5,ffffffffc0204320 <user_mem_check+0x64>
ffffffffc020433a:	962e                	add	a2,a2,a1
ffffffffc020433c:	fec5f2e3          	bgeu	a1,a2,ffffffffc0204320 <user_mem_check+0x64>
ffffffffc0204340:	c8000537          	lui	a0,0xc8000
ffffffffc0204344:	0505                	addi	a0,a0,1
ffffffffc0204346:	00a63533          	sltu	a0,a2,a0
ffffffffc020434a:	bfd9                	j	ffffffffc0204320 <user_mem_check+0x64>
        return 1;
ffffffffc020434c:	4505                	li	a0,1
ffffffffc020434e:	bfc9                	j	ffffffffc0204320 <user_mem_check+0x64>

ffffffffc0204350 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204350:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204352:	9402                	jalr	s0

	jal do_exit
ffffffffc0204354:	61c000ef          	jal	ra,ffffffffc0204970 <do_exit>

ffffffffc0204358 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0204358:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020435a:	10800513          	li	a0,264
{
ffffffffc020435e:	e022                	sd	s0,0(sp)
ffffffffc0204360:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204362:	9a5fd0ef          	jal	ra,ffffffffc0201d06 <kmalloc>
ffffffffc0204366:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0204368:	c12d                	beqz	a0,ffffffffc02043ca <alloc_proc+0x72>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc020436a:	10800613          	li	a2,264
ffffffffc020436e:	4581                	li	a1,0
ffffffffc0204370:	0cd010ef          	jal	ra,ffffffffc0205c3c <memset>
        
        // 初始化所有字段
        proc->state = PROC_UNINIT;      // 进程状态：未初始化
ffffffffc0204374:	57fd                	li	a5,-1
ffffffffc0204376:	1782                	slli	a5,a5,0x20
        proc->runs = 0;                 // 运行次数：初始为0
        proc->kstack = 0;               // 内核栈：初始为0
        proc->need_resched = 0;         // 不需要重新调度
        proc->parent = NULL;            // 父进程：空
        proc->mm = NULL;                // 内存管理：空（内核线程）
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文清零
ffffffffc0204378:	07000613          	li	a2,112
ffffffffc020437c:	4581                	li	a1,0
        proc->state = PROC_UNINIT;      // 进程状态：未初始化
ffffffffc020437e:	e01c                	sd	a5,0(s0)
        proc->runs = 0;                 // 运行次数：初始为0
ffffffffc0204380:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;               // 内核栈：初始为0
ffffffffc0204384:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;         // 不需要重新调度
ffffffffc0204388:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;            // 父进程：空
ffffffffc020438c:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;                // 内存管理：空（内核线程）
ffffffffc0204390:	02043423          	sd	zero,40(s0)
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文清零
ffffffffc0204394:	03040513          	addi	a0,s0,48
ffffffffc0204398:	0a5010ef          	jal	ra,ffffffffc0205c3c <memset>
        proc->tf = NULL;                // 陷阱帧：空
        proc->pgdir = boot_pgdir_pa;    // 页目录：使用内核页表
ffffffffc020439c:	000b1797          	auipc	a5,0xb1
ffffffffc02043a0:	c547b783          	ld	a5,-940(a5) # ffffffffc02b4ff0 <boot_pgdir_pa>
        proc->tf = NULL;                // 陷阱帧：空
ffffffffc02043a4:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;    // 页目录：使用内核页表
ffffffffc02043a8:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                // 进程标志：0
ffffffffc02043aa:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);  // 进程名清零
ffffffffc02043ae:	4641                	li	a2,16
ffffffffc02043b0:	4581                	li	a1,0
ffffffffc02043b2:	0b440513          	addi	a0,s0,180
ffffffffc02043b6:	087010ef          	jal	ra,ffffffffc0205c3c <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
ffffffffc02043ba:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc02043be:	10043023          	sd	zero,256(s0)
ffffffffc02043c2:	0e043c23          	sd	zero,248(s0)
ffffffffc02043c6:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc02043ca:	60a2                	ld	ra,8(sp)
ffffffffc02043cc:	8522                	mv	a0,s0
ffffffffc02043ce:	6402                	ld	s0,0(sp)
ffffffffc02043d0:	0141                	addi	sp,sp,16
ffffffffc02043d2:	8082                	ret

ffffffffc02043d4 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02043d4:	000b1797          	auipc	a5,0xb1
ffffffffc02043d8:	c547b783          	ld	a5,-940(a5) # ffffffffc02b5028 <current>
ffffffffc02043dc:	73c8                	ld	a0,160(a5)
ffffffffc02043de:	b9dfc06f          	j	ffffffffc0200f7a <forkrets>

ffffffffc02043e2 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02043e2:	000b1797          	auipc	a5,0xb1
ffffffffc02043e6:	c467b783          	ld	a5,-954(a5) # ffffffffc02b5028 <current>
ffffffffc02043ea:	43cc                	lw	a1,4(a5)
{
ffffffffc02043ec:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02043ee:	00003617          	auipc	a2,0x3
ffffffffc02043f2:	2d260613          	addi	a2,a2,722 # ffffffffc02076c0 <default_pmm_manager+0xc18>
ffffffffc02043f6:	00003517          	auipc	a0,0x3
ffffffffc02043fa:	2d250513          	addi	a0,a0,722 # ffffffffc02076c8 <default_pmm_manager+0xc20>
{
ffffffffc02043fe:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204400:	d95fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204404:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204408:	3d478793          	addi	a5,a5,980 # a7d8 <_binary_obj___user_cowtest_out_size>
ffffffffc020440c:	e43e                	sd	a5,8(sp)
ffffffffc020440e:	00003517          	auipc	a0,0x3
ffffffffc0204412:	2b250513          	addi	a0,a0,690 # ffffffffc02076c0 <default_pmm_manager+0xc18>
ffffffffc0204416:	0001c797          	auipc	a5,0x1c
ffffffffc020441a:	b9278793          	addi	a5,a5,-1134 # ffffffffc021ffa8 <_binary_obj___user_cowtest_out_start>
ffffffffc020441e:	f03e                	sd	a5,32(sp)
ffffffffc0204420:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204422:	e802                	sd	zero,16(sp)
ffffffffc0204424:	776010ef          	jal	ra,ffffffffc0205b9a <strlen>
ffffffffc0204428:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc020442a:	4511                	li	a0,4
ffffffffc020442c:	55a2                	lw	a1,40(sp)
ffffffffc020442e:	4662                	lw	a2,24(sp)
ffffffffc0204430:	5682                	lw	a3,32(sp)
ffffffffc0204432:	4722                	lw	a4,8(sp)
ffffffffc0204434:	48a9                	li	a7,10
ffffffffc0204436:	9002                	ebreak
ffffffffc0204438:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc020443a:	65c2                	ld	a1,16(sp)
ffffffffc020443c:	00003517          	auipc	a0,0x3
ffffffffc0204440:	2b450513          	addi	a0,a0,692 # ffffffffc02076f0 <default_pmm_manager+0xc48>
ffffffffc0204444:	d51fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204448:	00003617          	auipc	a2,0x3
ffffffffc020444c:	2b860613          	addi	a2,a2,696 # ffffffffc0207700 <default_pmm_manager+0xc58>
ffffffffc0204450:	3ca00593          	li	a1,970
ffffffffc0204454:	00003517          	auipc	a0,0x3
ffffffffc0204458:	2cc50513          	addi	a0,a0,716 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc020445c:	832fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204460 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204460:	6d14                	ld	a3,24(a0)
{
ffffffffc0204462:	1141                	addi	sp,sp,-16
ffffffffc0204464:	e406                	sd	ra,8(sp)
ffffffffc0204466:	c02007b7          	lui	a5,0xc0200
ffffffffc020446a:	02f6ee63          	bltu	a3,a5,ffffffffc02044a6 <put_pgdir+0x46>
ffffffffc020446e:	000b1517          	auipc	a0,0xb1
ffffffffc0204472:	baa53503          	ld	a0,-1110(a0) # ffffffffc02b5018 <va_pa_offset>
ffffffffc0204476:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204478:	82b1                	srli	a3,a3,0xc
ffffffffc020447a:	000b1797          	auipc	a5,0xb1
ffffffffc020447e:	b867b783          	ld	a5,-1146(a5) # ffffffffc02b5000 <npage>
ffffffffc0204482:	02f6fe63          	bgeu	a3,a5,ffffffffc02044be <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204486:	00004517          	auipc	a0,0x4
ffffffffc020448a:	b3253503          	ld	a0,-1230(a0) # ffffffffc0207fb8 <nbase>
}
ffffffffc020448e:	60a2                	ld	ra,8(sp)
ffffffffc0204490:	8e89                	sub	a3,a3,a0
ffffffffc0204492:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204494:	000b1517          	auipc	a0,0xb1
ffffffffc0204498:	b7453503          	ld	a0,-1164(a0) # ffffffffc02b5008 <pages>
ffffffffc020449c:	4585                	li	a1,1
ffffffffc020449e:	9536                	add	a0,a0,a3
}
ffffffffc02044a0:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02044a2:	a81fd06f          	j	ffffffffc0201f22 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02044a6:	00002617          	auipc	a2,0x2
ffffffffc02044aa:	6e260613          	addi	a2,a2,1762 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc02044ae:	07700593          	li	a1,119
ffffffffc02044b2:	00002517          	auipc	a0,0x2
ffffffffc02044b6:	65650513          	addi	a0,a0,1622 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02044ba:	fd5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02044be:	00002617          	auipc	a2,0x2
ffffffffc02044c2:	6f260613          	addi	a2,a2,1778 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc02044c6:	06900593          	li	a1,105
ffffffffc02044ca:	00002517          	auipc	a0,0x2
ffffffffc02044ce:	63e50513          	addi	a0,a0,1598 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02044d2:	fbdfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02044d6 <proc_run>:
{
ffffffffc02044d6:	7179                	addi	sp,sp,-48
ffffffffc02044d8:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02044da:	000b1917          	auipc	s2,0xb1
ffffffffc02044de:	b4e90913          	addi	s2,s2,-1202 # ffffffffc02b5028 <current>
{
ffffffffc02044e2:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02044e4:	00093483          	ld	s1,0(s2)
{
ffffffffc02044e8:	f406                	sd	ra,40(sp)
ffffffffc02044ea:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc02044ec:	02a48863          	beq	s1,a0,ffffffffc020451c <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044f0:	100027f3          	csrr	a5,sstatus
ffffffffc02044f4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02044f6:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044f8:	ef9d                	bnez	a5,ffffffffc0204536 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc02044fa:	755c                	ld	a5,168(a0)
ffffffffc02044fc:	577d                	li	a4,-1
ffffffffc02044fe:	177e                	slli	a4,a4,0x3f
ffffffffc0204500:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204502:	00a93023          	sd	a0,0(s2)
ffffffffc0204506:	8fd9                	or	a5,a5,a4
ffffffffc0204508:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(current->context));
ffffffffc020450c:	03050593          	addi	a1,a0,48
ffffffffc0204510:	03048513          	addi	a0,s1,48
ffffffffc0204514:	02c010ef          	jal	ra,ffffffffc0205540 <switch_to>
    if (flag)
ffffffffc0204518:	00099863          	bnez	s3,ffffffffc0204528 <proc_run+0x52>
}
ffffffffc020451c:	70a2                	ld	ra,40(sp)
ffffffffc020451e:	7482                	ld	s1,32(sp)
ffffffffc0204520:	6962                	ld	s2,24(sp)
ffffffffc0204522:	69c2                	ld	s3,16(sp)
ffffffffc0204524:	6145                	addi	sp,sp,48
ffffffffc0204526:	8082                	ret
ffffffffc0204528:	70a2                	ld	ra,40(sp)
ffffffffc020452a:	7482                	ld	s1,32(sp)
ffffffffc020452c:	6962                	ld	s2,24(sp)
ffffffffc020452e:	69c2                	ld	s3,16(sp)
ffffffffc0204530:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204532:	c7cfc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204536:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204538:	c7cfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020453c:	6522                	ld	a0,8(sp)
ffffffffc020453e:	4985                	li	s3,1
ffffffffc0204540:	bf6d                	j	ffffffffc02044fa <proc_run+0x24>

ffffffffc0204542 <do_fork>:
{
ffffffffc0204542:	7119                	addi	sp,sp,-128
ffffffffc0204544:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204546:	000b1917          	auipc	s2,0xb1
ffffffffc020454a:	afa90913          	addi	s2,s2,-1286 # ffffffffc02b5040 <nr_process>
ffffffffc020454e:	00092703          	lw	a4,0(s2)
{
ffffffffc0204552:	fc86                	sd	ra,120(sp)
ffffffffc0204554:	f8a2                	sd	s0,112(sp)
ffffffffc0204556:	f4a6                	sd	s1,104(sp)
ffffffffc0204558:	ecce                	sd	s3,88(sp)
ffffffffc020455a:	e8d2                	sd	s4,80(sp)
ffffffffc020455c:	e4d6                	sd	s5,72(sp)
ffffffffc020455e:	e0da                	sd	s6,64(sp)
ffffffffc0204560:	fc5e                	sd	s7,56(sp)
ffffffffc0204562:	f862                	sd	s8,48(sp)
ffffffffc0204564:	f466                	sd	s9,40(sp)
ffffffffc0204566:	f06a                	sd	s10,32(sp)
ffffffffc0204568:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020456a:	6785                	lui	a5,0x1
ffffffffc020456c:	32f75863          	bge	a4,a5,ffffffffc020489c <do_fork+0x35a>
ffffffffc0204570:	8a2a                	mv	s4,a0
ffffffffc0204572:	89ae                	mv	s3,a1
ffffffffc0204574:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0204576:	de3ff0ef          	jal	ra,ffffffffc0204358 <alloc_proc>
ffffffffc020457a:	84aa                	mv	s1,a0
ffffffffc020457c:	30050163          	beqz	a0,ffffffffc020487e <do_fork+0x33c>
    proc->parent = current; 
ffffffffc0204580:	000b1c17          	auipc	s8,0xb1
ffffffffc0204584:	aa8c0c13          	addi	s8,s8,-1368 # ffffffffc02b5028 <current>
ffffffffc0204588:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020458c:	4509                	li	a0,2
    proc->parent = current; 
ffffffffc020458e:	f09c                	sd	a5,32(s1)
    current->wait_state = 0;
ffffffffc0204590:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ad4>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204594:	951fd0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
    if (page != NULL)
ffffffffc0204598:	2e050063          	beqz	a0,ffffffffc0204878 <do_fork+0x336>
    return page - pages + nbase;
ffffffffc020459c:	000b1a97          	auipc	s5,0xb1
ffffffffc02045a0:	a6ca8a93          	addi	s5,s5,-1428 # ffffffffc02b5008 <pages>
ffffffffc02045a4:	000ab683          	ld	a3,0(s5)
ffffffffc02045a8:	00004b17          	auipc	s6,0x4
ffffffffc02045ac:	a10b0b13          	addi	s6,s6,-1520 # ffffffffc0207fb8 <nbase>
ffffffffc02045b0:	000b3783          	ld	a5,0(s6)
ffffffffc02045b4:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02045b8:	000b1b97          	auipc	s7,0xb1
ffffffffc02045bc:	a48b8b93          	addi	s7,s7,-1464 # ffffffffc02b5000 <npage>
    return page - pages + nbase;
ffffffffc02045c0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02045c2:	5dfd                	li	s11,-1
ffffffffc02045c4:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02045c8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02045ca:	00cddd93          	srli	s11,s11,0xc
ffffffffc02045ce:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02045d2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02045d4:	32e67a63          	bgeu	a2,a4,ffffffffc0204908 <do_fork+0x3c6>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02045d8:	000c3603          	ld	a2,0(s8)
ffffffffc02045dc:	000b1c17          	auipc	s8,0xb1
ffffffffc02045e0:	a3cc0c13          	addi	s8,s8,-1476 # ffffffffc02b5018 <va_pa_offset>
ffffffffc02045e4:	000c3703          	ld	a4,0(s8)
ffffffffc02045e8:	02863d03          	ld	s10,40(a2)
ffffffffc02045ec:	e43e                	sd	a5,8(sp)
ffffffffc02045ee:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02045f0:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02045f2:	020d0863          	beqz	s10,ffffffffc0204622 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc02045f6:	100a7a13          	andi	s4,s4,256
ffffffffc02045fa:	1c0a0163          	beqz	s4,ffffffffc02047bc <do_fork+0x27a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02045fe:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204602:	018d3783          	ld	a5,24(s10)
ffffffffc0204606:	c02006b7          	lui	a3,0xc0200
ffffffffc020460a:	2705                	addiw	a4,a4,1
ffffffffc020460c:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204610:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204614:	2cd7e163          	bltu	a5,a3,ffffffffc02048d6 <do_fork+0x394>
ffffffffc0204618:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020461c:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020461e:	8f99                	sub	a5,a5,a4
ffffffffc0204620:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204622:	6789                	lui	a5,0x2
ffffffffc0204624:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce0>
ffffffffc0204628:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020462a:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020462c:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020462e:	87b6                	mv	a5,a3
ffffffffc0204630:	12040893          	addi	a7,s0,288
ffffffffc0204634:	00063803          	ld	a6,0(a2)
ffffffffc0204638:	6608                	ld	a0,8(a2)
ffffffffc020463a:	6a0c                	ld	a1,16(a2)
ffffffffc020463c:	6e18                	ld	a4,24(a2)
ffffffffc020463e:	0107b023          	sd	a6,0(a5)
ffffffffc0204642:	e788                	sd	a0,8(a5)
ffffffffc0204644:	eb8c                	sd	a1,16(a5)
ffffffffc0204646:	ef98                	sd	a4,24(a5)
ffffffffc0204648:	02060613          	addi	a2,a2,32
ffffffffc020464c:	02078793          	addi	a5,a5,32
ffffffffc0204650:	ff1612e3          	bne	a2,a7,ffffffffc0204634 <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc0204654:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204658:	12098f63          	beqz	s3,ffffffffc0204796 <do_fork+0x254>
ffffffffc020465c:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204660:	00000797          	auipc	a5,0x0
ffffffffc0204664:	d7478793          	addi	a5,a5,-652 # ffffffffc02043d4 <forkret>
ffffffffc0204668:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020466a:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020466c:	100027f3          	csrr	a5,sstatus
ffffffffc0204670:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204672:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204674:	14079063          	bnez	a5,ffffffffc02047b4 <do_fork+0x272>
    if (++last_pid >= MAX_PID)
ffffffffc0204678:	000ac817          	auipc	a6,0xac
ffffffffc020467c:	51080813          	addi	a6,a6,1296 # ffffffffc02b0b88 <last_pid.1>
ffffffffc0204680:	00082783          	lw	a5,0(a6)
ffffffffc0204684:	6709                	lui	a4,0x2
ffffffffc0204686:	0017851b          	addiw	a0,a5,1
ffffffffc020468a:	00a82023          	sw	a0,0(a6)
ffffffffc020468e:	08e55d63          	bge	a0,a4,ffffffffc0204728 <do_fork+0x1e6>
    if (last_pid >= next_safe)
ffffffffc0204692:	000ac317          	auipc	t1,0xac
ffffffffc0204696:	4fa30313          	addi	t1,t1,1274 # ffffffffc02b0b8c <next_safe.0>
ffffffffc020469a:	00032783          	lw	a5,0(t1)
ffffffffc020469e:	000b1417          	auipc	s0,0xb1
ffffffffc02046a2:	90a40413          	addi	s0,s0,-1782 # ffffffffc02b4fa8 <proc_list>
ffffffffc02046a6:	08f55963          	bge	a0,a5,ffffffffc0204738 <do_fork+0x1f6>
    	proc->pid = get_pid(); // 获取一个唯一的 PID
ffffffffc02046aa:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02046ac:	45a9                	li	a1,10
ffffffffc02046ae:	2501                	sext.w	a0,a0
ffffffffc02046b0:	0e6010ef          	jal	ra,ffffffffc0205796 <hash32>
ffffffffc02046b4:	02051793          	slli	a5,a0,0x20
ffffffffc02046b8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02046bc:	000ad797          	auipc	a5,0xad
ffffffffc02046c0:	8ec78793          	addi	a5,a5,-1812 # ffffffffc02b0fa8 <hash_list>
ffffffffc02046c4:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02046c6:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02046c8:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02046ca:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02046ce:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02046d0:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02046d2:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02046d4:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02046d6:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02046da:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02046dc:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02046de:	e21c                	sd	a5,0(a2)
ffffffffc02046e0:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02046e2:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02046e4:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02046e6:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02046ea:	10e4b023          	sd	a4,256(s1)
ffffffffc02046ee:	c311                	beqz	a4,ffffffffc02046f2 <do_fork+0x1b0>
        proc->optr->yptr = proc;
ffffffffc02046f0:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02046f2:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02046f6:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02046f8:	2785                	addiw	a5,a5,1
ffffffffc02046fa:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc02046fe:	18099263          	bnez	s3,ffffffffc0204882 <do_fork+0x340>
    wakeup_proc(proc); // 将 proc->state 设置为 PROC_RUNNABLE
ffffffffc0204702:	8526                	mv	a0,s1
ffffffffc0204704:	6a7000ef          	jal	ra,ffffffffc02055aa <wakeup_proc>
    ret = proc->pid;
ffffffffc0204708:	40c8                	lw	a0,4(s1)
}
ffffffffc020470a:	70e6                	ld	ra,120(sp)
ffffffffc020470c:	7446                	ld	s0,112(sp)
ffffffffc020470e:	74a6                	ld	s1,104(sp)
ffffffffc0204710:	7906                	ld	s2,96(sp)
ffffffffc0204712:	69e6                	ld	s3,88(sp)
ffffffffc0204714:	6a46                	ld	s4,80(sp)
ffffffffc0204716:	6aa6                	ld	s5,72(sp)
ffffffffc0204718:	6b06                	ld	s6,64(sp)
ffffffffc020471a:	7be2                	ld	s7,56(sp)
ffffffffc020471c:	7c42                	ld	s8,48(sp)
ffffffffc020471e:	7ca2                	ld	s9,40(sp)
ffffffffc0204720:	7d02                	ld	s10,32(sp)
ffffffffc0204722:	6de2                	ld	s11,24(sp)
ffffffffc0204724:	6109                	addi	sp,sp,128
ffffffffc0204726:	8082                	ret
        last_pid = 1;
ffffffffc0204728:	4785                	li	a5,1
ffffffffc020472a:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020472e:	4505                	li	a0,1
ffffffffc0204730:	000ac317          	auipc	t1,0xac
ffffffffc0204734:	45c30313          	addi	t1,t1,1116 # ffffffffc02b0b8c <next_safe.0>
    return listelm->next;
ffffffffc0204738:	000b1417          	auipc	s0,0xb1
ffffffffc020473c:	87040413          	addi	s0,s0,-1936 # ffffffffc02b4fa8 <proc_list>
ffffffffc0204740:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204744:	6789                	lui	a5,0x2
ffffffffc0204746:	00f32023          	sw	a5,0(t1)
ffffffffc020474a:	86aa                	mv	a3,a0
ffffffffc020474c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020474e:	6e89                	lui	t4,0x2
ffffffffc0204750:	148e0163          	beq	t3,s0,ffffffffc0204892 <do_fork+0x350>
ffffffffc0204754:	88ae                	mv	a7,a1
ffffffffc0204756:	87f2                	mv	a5,t3
ffffffffc0204758:	6609                	lui	a2,0x2
ffffffffc020475a:	a811                	j	ffffffffc020476e <do_fork+0x22c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020475c:	00e6d663          	bge	a3,a4,ffffffffc0204768 <do_fork+0x226>
ffffffffc0204760:	00c75463          	bge	a4,a2,ffffffffc0204768 <do_fork+0x226>
ffffffffc0204764:	863a                	mv	a2,a4
ffffffffc0204766:	4885                	li	a7,1
ffffffffc0204768:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020476a:	00878d63          	beq	a5,s0,ffffffffc0204784 <do_fork+0x242>
            if (proc->pid == last_pid)
ffffffffc020476e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c84>
ffffffffc0204772:	fed715e3          	bne	a4,a3,ffffffffc020475c <do_fork+0x21a>
                if (++last_pid >= next_safe)
ffffffffc0204776:	2685                	addiw	a3,a3,1
ffffffffc0204778:	10c6d863          	bge	a3,a2,ffffffffc0204888 <do_fork+0x346>
ffffffffc020477c:	679c                	ld	a5,8(a5)
ffffffffc020477e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204780:	fe8797e3          	bne	a5,s0,ffffffffc020476e <do_fork+0x22c>
ffffffffc0204784:	c581                	beqz	a1,ffffffffc020478c <do_fork+0x24a>
ffffffffc0204786:	00d82023          	sw	a3,0(a6)
ffffffffc020478a:	8536                	mv	a0,a3
ffffffffc020478c:	f0088fe3          	beqz	a7,ffffffffc02046aa <do_fork+0x168>
ffffffffc0204790:	00c32023          	sw	a2,0(t1)
ffffffffc0204794:	bf19                	j	ffffffffc02046aa <do_fork+0x168>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204796:	89b6                	mv	s3,a3
ffffffffc0204798:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020479c:	00000797          	auipc	a5,0x0
ffffffffc02047a0:	c3878793          	addi	a5,a5,-968 # ffffffffc02043d4 <forkret>
ffffffffc02047a4:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02047a6:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047a8:	100027f3          	csrr	a5,sstatus
ffffffffc02047ac:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047ae:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047b0:	ec0784e3          	beqz	a5,ffffffffc0204678 <do_fork+0x136>
        intr_disable();
ffffffffc02047b4:	a00fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02047b8:	4985                	li	s3,1
ffffffffc02047ba:	bd7d                	j	ffffffffc0204678 <do_fork+0x136>
    if ((mm = mm_create()) == NULL)
ffffffffc02047bc:	fd7fe0ef          	jal	ra,ffffffffc0203792 <mm_create>
ffffffffc02047c0:	8caa                	mv	s9,a0
ffffffffc02047c2:	c159                	beqz	a0,ffffffffc0204848 <do_fork+0x306>
    if ((page = alloc_page()) == NULL)
ffffffffc02047c4:	4505                	li	a0,1
ffffffffc02047c6:	f1efd0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc02047ca:	cd25                	beqz	a0,ffffffffc0204842 <do_fork+0x300>
    return page - pages + nbase;
ffffffffc02047cc:	000ab683          	ld	a3,0(s5)
ffffffffc02047d0:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02047d2:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02047d6:	40d506b3          	sub	a3,a0,a3
ffffffffc02047da:	8699                	srai	a3,a3,0x6
ffffffffc02047dc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02047de:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02047e2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047e4:	12edf263          	bgeu	s11,a4,ffffffffc0204908 <do_fork+0x3c6>
ffffffffc02047e8:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02047ec:	6605                	lui	a2,0x1
ffffffffc02047ee:	000b1597          	auipc	a1,0xb1
ffffffffc02047f2:	80a5b583          	ld	a1,-2038(a1) # ffffffffc02b4ff8 <boot_pgdir_va>
ffffffffc02047f6:	9a36                	add	s4,s4,a3
ffffffffc02047f8:	8552                	mv	a0,s4
ffffffffc02047fa:	454010ef          	jal	ra,ffffffffc0205c4e <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02047fe:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204802:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204806:	4785                	li	a5,1
ffffffffc0204808:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020480c:	8b85                	andi	a5,a5,1
ffffffffc020480e:	4a05                	li	s4,1
ffffffffc0204810:	c799                	beqz	a5,ffffffffc020481e <do_fork+0x2dc>
    {
        schedule();
ffffffffc0204812:	619000ef          	jal	ra,ffffffffc020562a <schedule>
ffffffffc0204816:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020481a:	8b85                	andi	a5,a5,1
ffffffffc020481c:	fbfd                	bnez	a5,ffffffffc0204812 <do_fork+0x2d0>
        ret = dup_mmap(mm, oldmm);
ffffffffc020481e:	85ea                	mv	a1,s10
ffffffffc0204820:	8566                	mv	a0,s9
ffffffffc0204822:	bb8ff0ef          	jal	ra,ffffffffc0203bda <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204826:	57f9                	li	a5,-2
ffffffffc0204828:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020482c:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020482e:	cfa5                	beqz	a5,ffffffffc02048a6 <do_fork+0x364>
good_mm:
ffffffffc0204830:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204832:	dc0506e3          	beqz	a0,ffffffffc02045fe <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc0204836:	8566                	mv	a0,s9
ffffffffc0204838:	c3cff0ef          	jal	ra,ffffffffc0203c74 <exit_mmap>
    put_pgdir(mm);
ffffffffc020483c:	8566                	mv	a0,s9
ffffffffc020483e:	c23ff0ef          	jal	ra,ffffffffc0204460 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204842:	8566                	mv	a0,s9
ffffffffc0204844:	a94ff0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204848:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020484a:	c02007b7          	lui	a5,0xc0200
ffffffffc020484e:	0af6e163          	bltu	a3,a5,ffffffffc02048f0 <do_fork+0x3ae>
ffffffffc0204852:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204856:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020485a:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020485e:	83b1                	srli	a5,a5,0xc
ffffffffc0204860:	04e7ff63          	bgeu	a5,a4,ffffffffc02048be <do_fork+0x37c>
    return &pages[PPN(pa) - nbase];
ffffffffc0204864:	000b3703          	ld	a4,0(s6)
ffffffffc0204868:	000ab503          	ld	a0,0(s5)
ffffffffc020486c:	4589                	li	a1,2
ffffffffc020486e:	8f99                	sub	a5,a5,a4
ffffffffc0204870:	079a                	slli	a5,a5,0x6
ffffffffc0204872:	953e                	add	a0,a0,a5
ffffffffc0204874:	eaefd0ef          	jal	ra,ffffffffc0201f22 <free_pages>
    kfree(proc);
ffffffffc0204878:	8526                	mv	a0,s1
ffffffffc020487a:	d3cfd0ef          	jal	ra,ffffffffc0201db6 <kfree>
    ret = -E_NO_MEM;
ffffffffc020487e:	5571                	li	a0,-4
    return ret;
ffffffffc0204880:	b569                	j	ffffffffc020470a <do_fork+0x1c8>
        intr_enable();
ffffffffc0204882:	92cfc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204886:	bdb5                	j	ffffffffc0204702 <do_fork+0x1c0>
                    if (last_pid >= MAX_PID)
ffffffffc0204888:	01d6c363          	blt	a3,t4,ffffffffc020488e <do_fork+0x34c>
                        last_pid = 1;
ffffffffc020488c:	4685                	li	a3,1
                    goto repeat;
ffffffffc020488e:	4585                	li	a1,1
ffffffffc0204890:	b5c1                	j	ffffffffc0204750 <do_fork+0x20e>
ffffffffc0204892:	c599                	beqz	a1,ffffffffc02048a0 <do_fork+0x35e>
ffffffffc0204894:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204898:	8536                	mv	a0,a3
ffffffffc020489a:	bd01                	j	ffffffffc02046aa <do_fork+0x168>
    int ret = -E_NO_FREE_PROC;
ffffffffc020489c:	556d                	li	a0,-5
ffffffffc020489e:	b5b5                	j	ffffffffc020470a <do_fork+0x1c8>
    return last_pid;
ffffffffc02048a0:	00082503          	lw	a0,0(a6)
ffffffffc02048a4:	b519                	j	ffffffffc02046aa <do_fork+0x168>
    {
        panic("Unlock failed.\n");
ffffffffc02048a6:	00003617          	auipc	a2,0x3
ffffffffc02048aa:	e9260613          	addi	a2,a2,-366 # ffffffffc0207738 <default_pmm_manager+0xc90>
ffffffffc02048ae:	03f00593          	li	a1,63
ffffffffc02048b2:	00003517          	auipc	a0,0x3
ffffffffc02048b6:	e9650513          	addi	a0,a0,-362 # ffffffffc0207748 <default_pmm_manager+0xca0>
ffffffffc02048ba:	bd5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048be:	00002617          	auipc	a2,0x2
ffffffffc02048c2:	2f260613          	addi	a2,a2,754 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc02048c6:	06900593          	li	a1,105
ffffffffc02048ca:	00002517          	auipc	a0,0x2
ffffffffc02048ce:	23e50513          	addi	a0,a0,574 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc02048d2:	bbdfb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02048d6:	86be                	mv	a3,a5
ffffffffc02048d8:	00002617          	auipc	a2,0x2
ffffffffc02048dc:	2b060613          	addi	a2,a2,688 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc02048e0:	19600593          	li	a1,406
ffffffffc02048e4:	00003517          	auipc	a0,0x3
ffffffffc02048e8:	e3c50513          	addi	a0,a0,-452 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc02048ec:	ba3fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02048f0:	00002617          	auipc	a2,0x2
ffffffffc02048f4:	29860613          	addi	a2,a2,664 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc02048f8:	07700593          	li	a1,119
ffffffffc02048fc:	00002517          	auipc	a0,0x2
ffffffffc0204900:	20c50513          	addi	a0,a0,524 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0204904:	b8bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204908:	00002617          	auipc	a2,0x2
ffffffffc020490c:	1d860613          	addi	a2,a2,472 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc0204910:	07100593          	li	a1,113
ffffffffc0204914:	00002517          	auipc	a0,0x2
ffffffffc0204918:	1f450513          	addi	a0,a0,500 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc020491c:	b73fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204920 <kernel_thread>:
{
ffffffffc0204920:	7129                	addi	sp,sp,-320
ffffffffc0204922:	fa22                	sd	s0,304(sp)
ffffffffc0204924:	f626                	sd	s1,296(sp)
ffffffffc0204926:	f24a                	sd	s2,288(sp)
ffffffffc0204928:	84ae                	mv	s1,a1
ffffffffc020492a:	892a                	mv	s2,a0
ffffffffc020492c:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020492e:	4581                	li	a1,0
ffffffffc0204930:	12000613          	li	a2,288
ffffffffc0204934:	850a                	mv	a0,sp
{
ffffffffc0204936:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204938:	304010ef          	jal	ra,ffffffffc0205c3c <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020493c:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020493e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204940:	100027f3          	csrr	a5,sstatus
ffffffffc0204944:	edd7f793          	andi	a5,a5,-291
ffffffffc0204948:	1207e793          	ori	a5,a5,288
ffffffffc020494c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020494e:	860a                	mv	a2,sp
ffffffffc0204950:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204954:	00000797          	auipc	a5,0x0
ffffffffc0204958:	9fc78793          	addi	a5,a5,-1540 # ffffffffc0204350 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020495c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020495e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204960:	be3ff0ef          	jal	ra,ffffffffc0204542 <do_fork>
}
ffffffffc0204964:	70f2                	ld	ra,312(sp)
ffffffffc0204966:	7452                	ld	s0,304(sp)
ffffffffc0204968:	74b2                	ld	s1,296(sp)
ffffffffc020496a:	7912                	ld	s2,288(sp)
ffffffffc020496c:	6131                	addi	sp,sp,320
ffffffffc020496e:	8082                	ret

ffffffffc0204970 <do_exit>:
{
ffffffffc0204970:	7179                	addi	sp,sp,-48
ffffffffc0204972:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204974:	000b0417          	auipc	s0,0xb0
ffffffffc0204978:	6b440413          	addi	s0,s0,1716 # ffffffffc02b5028 <current>
ffffffffc020497c:	601c                	ld	a5,0(s0)
{
ffffffffc020497e:	f406                	sd	ra,40(sp)
ffffffffc0204980:	ec26                	sd	s1,24(sp)
ffffffffc0204982:	e84a                	sd	s2,16(sp)
ffffffffc0204984:	e44e                	sd	s3,8(sp)
ffffffffc0204986:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204988:	000b0717          	auipc	a4,0xb0
ffffffffc020498c:	6a873703          	ld	a4,1704(a4) # ffffffffc02b5030 <idleproc>
ffffffffc0204990:	0ce78c63          	beq	a5,a4,ffffffffc0204a68 <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204994:	000b0497          	auipc	s1,0xb0
ffffffffc0204998:	6a448493          	addi	s1,s1,1700 # ffffffffc02b5038 <initproc>
ffffffffc020499c:	6098                	ld	a4,0(s1)
ffffffffc020499e:	0ee78b63          	beq	a5,a4,ffffffffc0204a94 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02049a2:	0287b983          	ld	s3,40(a5)
ffffffffc02049a6:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02049a8:	02098663          	beqz	s3,ffffffffc02049d4 <do_exit+0x64>
ffffffffc02049ac:	000b0797          	auipc	a5,0xb0
ffffffffc02049b0:	6447b783          	ld	a5,1604(a5) # ffffffffc02b4ff0 <boot_pgdir_pa>
ffffffffc02049b4:	577d                	li	a4,-1
ffffffffc02049b6:	177e                	slli	a4,a4,0x3f
ffffffffc02049b8:	83b1                	srli	a5,a5,0xc
ffffffffc02049ba:	8fd9                	or	a5,a5,a4
ffffffffc02049bc:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02049c0:	0309a783          	lw	a5,48(s3)
ffffffffc02049c4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02049c8:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02049cc:	cb55                	beqz	a4,ffffffffc0204a80 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02049ce:	601c                	ld	a5,0(s0)
ffffffffc02049d0:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02049d4:	601c                	ld	a5,0(s0)
ffffffffc02049d6:	470d                	li	a4,3
ffffffffc02049d8:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02049da:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02049de:	100027f3          	csrr	a5,sstatus
ffffffffc02049e2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02049e4:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02049e6:	e3f9                	bnez	a5,ffffffffc0204aac <do_exit+0x13c>
        proc = current->parent;
ffffffffc02049e8:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02049ea:	800007b7          	lui	a5,0x80000
ffffffffc02049ee:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02049f0:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02049f2:	0ec52703          	lw	a4,236(a0)
ffffffffc02049f6:	0af70f63          	beq	a4,a5,ffffffffc0204ab4 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc02049fa:	6018                	ld	a4,0(s0)
ffffffffc02049fc:	7b7c                	ld	a5,240(a4)
ffffffffc02049fe:	c3a1                	beqz	a5,ffffffffc0204a3e <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204a00:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204a04:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204a06:	0985                	addi	s3,s3,1
ffffffffc0204a08:	a021                	j	ffffffffc0204a10 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204a0a:	6018                	ld	a4,0(s0)
ffffffffc0204a0c:	7b7c                	ld	a5,240(a4)
ffffffffc0204a0e:	cb85                	beqz	a5,ffffffffc0204a3e <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204a10:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204a14:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204a16:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204a18:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204a1a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204a1e:	10e7b023          	sd	a4,256(a5)
ffffffffc0204a22:	c311                	beqz	a4,ffffffffc0204a26 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204a24:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204a26:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204a28:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204a2a:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204a2c:	fd271fe3          	bne	a4,s2,ffffffffc0204a0a <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204a30:	0ec52783          	lw	a5,236(a0)
ffffffffc0204a34:	fd379be3          	bne	a5,s3,ffffffffc0204a0a <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204a38:	373000ef          	jal	ra,ffffffffc02055aa <wakeup_proc>
ffffffffc0204a3c:	b7f9                	j	ffffffffc0204a0a <do_exit+0x9a>
    if (flag)
ffffffffc0204a3e:	020a1263          	bnez	s4,ffffffffc0204a62 <do_exit+0xf2>
    schedule();
ffffffffc0204a42:	3e9000ef          	jal	ra,ffffffffc020562a <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204a46:	601c                	ld	a5,0(s0)
ffffffffc0204a48:	00003617          	auipc	a2,0x3
ffffffffc0204a4c:	d3860613          	addi	a2,a2,-712 # ffffffffc0207780 <default_pmm_manager+0xcd8>
ffffffffc0204a50:	25000593          	li	a1,592
ffffffffc0204a54:	43d4                	lw	a3,4(a5)
ffffffffc0204a56:	00003517          	auipc	a0,0x3
ffffffffc0204a5a:	cca50513          	addi	a0,a0,-822 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204a5e:	a31fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204a62:	f4dfb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204a66:	bff1                	j	ffffffffc0204a42 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204a68:	00003617          	auipc	a2,0x3
ffffffffc0204a6c:	cf860613          	addi	a2,a2,-776 # ffffffffc0207760 <default_pmm_manager+0xcb8>
ffffffffc0204a70:	21c00593          	li	a1,540
ffffffffc0204a74:	00003517          	auipc	a0,0x3
ffffffffc0204a78:	cac50513          	addi	a0,a0,-852 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204a7c:	a13fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204a80:	854e                	mv	a0,s3
ffffffffc0204a82:	9f2ff0ef          	jal	ra,ffffffffc0203c74 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a86:	854e                	mv	a0,s3
ffffffffc0204a88:	9d9ff0ef          	jal	ra,ffffffffc0204460 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a8c:	854e                	mv	a0,s3
ffffffffc0204a8e:	84aff0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>
ffffffffc0204a92:	bf35                	j	ffffffffc02049ce <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204a94:	00003617          	auipc	a2,0x3
ffffffffc0204a98:	cdc60613          	addi	a2,a2,-804 # ffffffffc0207770 <default_pmm_manager+0xcc8>
ffffffffc0204a9c:	22000593          	li	a1,544
ffffffffc0204aa0:	00003517          	auipc	a0,0x3
ffffffffc0204aa4:	c8050513          	addi	a0,a0,-896 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204aa8:	9e7fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204aac:	f09fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204ab0:	4a05                	li	s4,1
ffffffffc0204ab2:	bf1d                	j	ffffffffc02049e8 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204ab4:	2f7000ef          	jal	ra,ffffffffc02055aa <wakeup_proc>
ffffffffc0204ab8:	b789                	j	ffffffffc02049fa <do_exit+0x8a>

ffffffffc0204aba <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204aba:	715d                	addi	sp,sp,-80
ffffffffc0204abc:	f84a                	sd	s2,48(sp)
ffffffffc0204abe:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204ac0:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ac4:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204ac6:	fc26                	sd	s1,56(sp)
ffffffffc0204ac8:	f052                	sd	s4,32(sp)
ffffffffc0204aca:	ec56                	sd	s5,24(sp)
ffffffffc0204acc:	e85a                	sd	s6,16(sp)
ffffffffc0204ace:	e45e                	sd	s7,8(sp)
ffffffffc0204ad0:	e486                	sd	ra,72(sp)
ffffffffc0204ad2:	e0a2                	sd	s0,64(sp)
ffffffffc0204ad4:	84aa                	mv	s1,a0
ffffffffc0204ad6:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204ad8:	000b0b97          	auipc	s7,0xb0
ffffffffc0204adc:	550b8b93          	addi	s7,s7,1360 # ffffffffc02b5028 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ae0:	00050b1b          	sext.w	s6,a0
ffffffffc0204ae4:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204ae8:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204aea:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204aec:	ccbd                	beqz	s1,ffffffffc0204b6a <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204aee:	0359e863          	bltu	s3,s5,ffffffffc0204b1e <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204af2:	45a9                	li	a1,10
ffffffffc0204af4:	855a                	mv	a0,s6
ffffffffc0204af6:	4a1000ef          	jal	ra,ffffffffc0205796 <hash32>
ffffffffc0204afa:	02051793          	slli	a5,a0,0x20
ffffffffc0204afe:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204b02:	000ac797          	auipc	a5,0xac
ffffffffc0204b06:	4a678793          	addi	a5,a5,1190 # ffffffffc02b0fa8 <hash_list>
ffffffffc0204b0a:	953e                	add	a0,a0,a5
ffffffffc0204b0c:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204b0e:	a029                	j	ffffffffc0204b18 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204b10:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204b14:	02978163          	beq	a5,s1,ffffffffc0204b36 <do_wait.part.0+0x7c>
ffffffffc0204b18:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204b1a:	fe851be3          	bne	a0,s0,ffffffffc0204b10 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204b1e:	5579                	li	a0,-2
}
ffffffffc0204b20:	60a6                	ld	ra,72(sp)
ffffffffc0204b22:	6406                	ld	s0,64(sp)
ffffffffc0204b24:	74e2                	ld	s1,56(sp)
ffffffffc0204b26:	7942                	ld	s2,48(sp)
ffffffffc0204b28:	79a2                	ld	s3,40(sp)
ffffffffc0204b2a:	7a02                	ld	s4,32(sp)
ffffffffc0204b2c:	6ae2                	ld	s5,24(sp)
ffffffffc0204b2e:	6b42                	ld	s6,16(sp)
ffffffffc0204b30:	6ba2                	ld	s7,8(sp)
ffffffffc0204b32:	6161                	addi	sp,sp,80
ffffffffc0204b34:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204b36:	000bb683          	ld	a3,0(s7)
ffffffffc0204b3a:	f4843783          	ld	a5,-184(s0)
ffffffffc0204b3e:	fed790e3          	bne	a5,a3,ffffffffc0204b1e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204b42:	f2842703          	lw	a4,-216(s0)
ffffffffc0204b46:	478d                	li	a5,3
ffffffffc0204b48:	0ef70b63          	beq	a4,a5,ffffffffc0204c3e <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204b4c:	4785                	li	a5,1
ffffffffc0204b4e:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204b50:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204b54:	2d7000ef          	jal	ra,ffffffffc020562a <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204b58:	000bb783          	ld	a5,0(s7)
ffffffffc0204b5c:	0b07a783          	lw	a5,176(a5)
ffffffffc0204b60:	8b85                	andi	a5,a5,1
ffffffffc0204b62:	d7c9                	beqz	a5,ffffffffc0204aec <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204b64:	555d                	li	a0,-9
ffffffffc0204b66:	e0bff0ef          	jal	ra,ffffffffc0204970 <do_exit>
        proc = current->cptr;
ffffffffc0204b6a:	000bb683          	ld	a3,0(s7)
ffffffffc0204b6e:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204b70:	d45d                	beqz	s0,ffffffffc0204b1e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204b72:	470d                	li	a4,3
ffffffffc0204b74:	a021                	j	ffffffffc0204b7c <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204b76:	10043403          	ld	s0,256(s0)
ffffffffc0204b7a:	d869                	beqz	s0,ffffffffc0204b4c <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204b7c:	401c                	lw	a5,0(s0)
ffffffffc0204b7e:	fee79ce3          	bne	a5,a4,ffffffffc0204b76 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204b82:	000b0797          	auipc	a5,0xb0
ffffffffc0204b86:	4ae7b783          	ld	a5,1198(a5) # ffffffffc02b5030 <idleproc>
ffffffffc0204b8a:	0c878963          	beq	a5,s0,ffffffffc0204c5c <do_wait.part.0+0x1a2>
ffffffffc0204b8e:	000b0797          	auipc	a5,0xb0
ffffffffc0204b92:	4aa7b783          	ld	a5,1194(a5) # ffffffffc02b5038 <initproc>
ffffffffc0204b96:	0cf40363          	beq	s0,a5,ffffffffc0204c5c <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204b9a:	000a0663          	beqz	s4,ffffffffc0204ba6 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204b9e:	0e842783          	lw	a5,232(s0)
ffffffffc0204ba2:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204ba6:	100027f3          	csrr	a5,sstatus
ffffffffc0204baa:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204bac:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204bae:	e7c1                	bnez	a5,ffffffffc0204c36 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204bb0:	6c70                	ld	a2,216(s0)
ffffffffc0204bb2:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204bb4:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204bb8:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204bba:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204bbc:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204bbe:	6470                	ld	a2,200(s0)
ffffffffc0204bc0:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204bc2:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204bc4:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204bc6:	c319                	beqz	a4,ffffffffc0204bcc <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204bc8:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204bca:	7c7c                	ld	a5,248(s0)
ffffffffc0204bcc:	c3b5                	beqz	a5,ffffffffc0204c30 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204bce:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204bd2:	000b0717          	auipc	a4,0xb0
ffffffffc0204bd6:	46e70713          	addi	a4,a4,1134 # ffffffffc02b5040 <nr_process>
ffffffffc0204bda:	431c                	lw	a5,0(a4)
ffffffffc0204bdc:	37fd                	addiw	a5,a5,-1
ffffffffc0204bde:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204be0:	e5a9                	bnez	a1,ffffffffc0204c2a <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204be2:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204be4:	c02007b7          	lui	a5,0xc0200
ffffffffc0204be8:	04f6ee63          	bltu	a3,a5,ffffffffc0204c44 <do_wait.part.0+0x18a>
ffffffffc0204bec:	000b0797          	auipc	a5,0xb0
ffffffffc0204bf0:	42c7b783          	ld	a5,1068(a5) # ffffffffc02b5018 <va_pa_offset>
ffffffffc0204bf4:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204bf6:	82b1                	srli	a3,a3,0xc
ffffffffc0204bf8:	000b0797          	auipc	a5,0xb0
ffffffffc0204bfc:	4087b783          	ld	a5,1032(a5) # ffffffffc02b5000 <npage>
ffffffffc0204c00:	06f6fa63          	bgeu	a3,a5,ffffffffc0204c74 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204c04:	00003517          	auipc	a0,0x3
ffffffffc0204c08:	3b453503          	ld	a0,948(a0) # ffffffffc0207fb8 <nbase>
ffffffffc0204c0c:	8e89                	sub	a3,a3,a0
ffffffffc0204c0e:	069a                	slli	a3,a3,0x6
ffffffffc0204c10:	000b0517          	auipc	a0,0xb0
ffffffffc0204c14:	3f853503          	ld	a0,1016(a0) # ffffffffc02b5008 <pages>
ffffffffc0204c18:	9536                	add	a0,a0,a3
ffffffffc0204c1a:	4589                	li	a1,2
ffffffffc0204c1c:	b06fd0ef          	jal	ra,ffffffffc0201f22 <free_pages>
    kfree(proc);
ffffffffc0204c20:	8522                	mv	a0,s0
ffffffffc0204c22:	994fd0ef          	jal	ra,ffffffffc0201db6 <kfree>
    return 0;
ffffffffc0204c26:	4501                	li	a0,0
ffffffffc0204c28:	bde5                	j	ffffffffc0204b20 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204c2a:	d85fb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204c2e:	bf55                	j	ffffffffc0204be2 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204c30:	701c                	ld	a5,32(s0)
ffffffffc0204c32:	fbf8                	sd	a4,240(a5)
ffffffffc0204c34:	bf79                	j	ffffffffc0204bd2 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204c36:	d7ffb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204c3a:	4585                	li	a1,1
ffffffffc0204c3c:	bf95                	j	ffffffffc0204bb0 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204c3e:	f2840413          	addi	s0,s0,-216
ffffffffc0204c42:	b781                	j	ffffffffc0204b82 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204c44:	00002617          	auipc	a2,0x2
ffffffffc0204c48:	f4460613          	addi	a2,a2,-188 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc0204c4c:	07700593          	li	a1,119
ffffffffc0204c50:	00002517          	auipc	a0,0x2
ffffffffc0204c54:	eb850513          	addi	a0,a0,-328 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0204c58:	837fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204c5c:	00003617          	auipc	a2,0x3
ffffffffc0204c60:	b4460613          	addi	a2,a2,-1212 # ffffffffc02077a0 <default_pmm_manager+0xcf8>
ffffffffc0204c64:	37200593          	li	a1,882
ffffffffc0204c68:	00003517          	auipc	a0,0x3
ffffffffc0204c6c:	ab850513          	addi	a0,a0,-1352 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204c70:	81ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204c74:	00002617          	auipc	a2,0x2
ffffffffc0204c78:	f3c60613          	addi	a2,a2,-196 # ffffffffc0206bb0 <default_pmm_manager+0x108>
ffffffffc0204c7c:	06900593          	li	a1,105
ffffffffc0204c80:	00002517          	auipc	a0,0x2
ffffffffc0204c84:	e8850513          	addi	a0,a0,-376 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0204c88:	807fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204c8c <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204c8c:	1141                	addi	sp,sp,-16
ffffffffc0204c8e:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204c90:	ad2fd0ef          	jal	ra,ffffffffc0201f62 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204c94:	86efd0ef          	jal	ra,ffffffffc0201d02 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204c98:	4601                	li	a2,0
ffffffffc0204c9a:	4581                	li	a1,0
ffffffffc0204c9c:	fffff517          	auipc	a0,0xfffff
ffffffffc0204ca0:	74650513          	addi	a0,a0,1862 # ffffffffc02043e2 <user_main>
ffffffffc0204ca4:	c7dff0ef          	jal	ra,ffffffffc0204920 <kernel_thread>
    if (pid <= 0)
ffffffffc0204ca8:	00a04563          	bgtz	a0,ffffffffc0204cb2 <init_main+0x26>
ffffffffc0204cac:	a071                	j	ffffffffc0204d38 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204cae:	17d000ef          	jal	ra,ffffffffc020562a <schedule>
    if (code_store != NULL)
ffffffffc0204cb2:	4581                	li	a1,0
ffffffffc0204cb4:	4501                	li	a0,0
ffffffffc0204cb6:	e05ff0ef          	jal	ra,ffffffffc0204aba <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204cba:	d975                	beqz	a0,ffffffffc0204cae <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204cbc:	00003517          	auipc	a0,0x3
ffffffffc0204cc0:	b2450513          	addi	a0,a0,-1244 # ffffffffc02077e0 <default_pmm_manager+0xd38>
ffffffffc0204cc4:	cd0fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204cc8:	000b0797          	auipc	a5,0xb0
ffffffffc0204ccc:	3707b783          	ld	a5,880(a5) # ffffffffc02b5038 <initproc>
ffffffffc0204cd0:	7bf8                	ld	a4,240(a5)
ffffffffc0204cd2:	e339                	bnez	a4,ffffffffc0204d18 <init_main+0x8c>
ffffffffc0204cd4:	7ff8                	ld	a4,248(a5)
ffffffffc0204cd6:	e329                	bnez	a4,ffffffffc0204d18 <init_main+0x8c>
ffffffffc0204cd8:	1007b703          	ld	a4,256(a5)
ffffffffc0204cdc:	ef15                	bnez	a4,ffffffffc0204d18 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204cde:	000b0697          	auipc	a3,0xb0
ffffffffc0204ce2:	3626a683          	lw	a3,866(a3) # ffffffffc02b5040 <nr_process>
ffffffffc0204ce6:	4709                	li	a4,2
ffffffffc0204ce8:	0ae69463          	bne	a3,a4,ffffffffc0204d90 <init_main+0x104>
    return listelm->next;
ffffffffc0204cec:	000b0697          	auipc	a3,0xb0
ffffffffc0204cf0:	2bc68693          	addi	a3,a3,700 # ffffffffc02b4fa8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204cf4:	6698                	ld	a4,8(a3)
ffffffffc0204cf6:	0c878793          	addi	a5,a5,200
ffffffffc0204cfa:	06f71b63          	bne	a4,a5,ffffffffc0204d70 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204cfe:	629c                	ld	a5,0(a3)
ffffffffc0204d00:	04f71863          	bne	a4,a5,ffffffffc0204d50 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204d04:	00003517          	auipc	a0,0x3
ffffffffc0204d08:	bc450513          	addi	a0,a0,-1084 # ffffffffc02078c8 <default_pmm_manager+0xe20>
ffffffffc0204d0c:	c88fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204d10:	60a2                	ld	ra,8(sp)
ffffffffc0204d12:	4501                	li	a0,0
ffffffffc0204d14:	0141                	addi	sp,sp,16
ffffffffc0204d16:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204d18:	00003697          	auipc	a3,0x3
ffffffffc0204d1c:	af068693          	addi	a3,a3,-1296 # ffffffffc0207808 <default_pmm_manager+0xd60>
ffffffffc0204d20:	00002617          	auipc	a2,0x2
ffffffffc0204d24:	9d860613          	addi	a2,a2,-1576 # ffffffffc02066f8 <commands+0x828>
ffffffffc0204d28:	3e000593          	li	a1,992
ffffffffc0204d2c:	00003517          	auipc	a0,0x3
ffffffffc0204d30:	9f450513          	addi	a0,a0,-1548 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204d34:	f5afb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204d38:	00003617          	auipc	a2,0x3
ffffffffc0204d3c:	a8860613          	addi	a2,a2,-1400 # ffffffffc02077c0 <default_pmm_manager+0xd18>
ffffffffc0204d40:	3d700593          	li	a1,983
ffffffffc0204d44:	00003517          	auipc	a0,0x3
ffffffffc0204d48:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204d4c:	f42fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204d50:	00003697          	auipc	a3,0x3
ffffffffc0204d54:	b4868693          	addi	a3,a3,-1208 # ffffffffc0207898 <default_pmm_manager+0xdf0>
ffffffffc0204d58:	00002617          	auipc	a2,0x2
ffffffffc0204d5c:	9a060613          	addi	a2,a2,-1632 # ffffffffc02066f8 <commands+0x828>
ffffffffc0204d60:	3e300593          	li	a1,995
ffffffffc0204d64:	00003517          	auipc	a0,0x3
ffffffffc0204d68:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204d6c:	f22fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204d70:	00003697          	auipc	a3,0x3
ffffffffc0204d74:	af868693          	addi	a3,a3,-1288 # ffffffffc0207868 <default_pmm_manager+0xdc0>
ffffffffc0204d78:	00002617          	auipc	a2,0x2
ffffffffc0204d7c:	98060613          	addi	a2,a2,-1664 # ffffffffc02066f8 <commands+0x828>
ffffffffc0204d80:	3e200593          	li	a1,994
ffffffffc0204d84:	00003517          	auipc	a0,0x3
ffffffffc0204d88:	99c50513          	addi	a0,a0,-1636 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204d8c:	f02fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204d90:	00003697          	auipc	a3,0x3
ffffffffc0204d94:	ac868693          	addi	a3,a3,-1336 # ffffffffc0207858 <default_pmm_manager+0xdb0>
ffffffffc0204d98:	00002617          	auipc	a2,0x2
ffffffffc0204d9c:	96060613          	addi	a2,a2,-1696 # ffffffffc02066f8 <commands+0x828>
ffffffffc0204da0:	3e100593          	li	a1,993
ffffffffc0204da4:	00003517          	auipc	a0,0x3
ffffffffc0204da8:	97c50513          	addi	a0,a0,-1668 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0204dac:	ee2fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204db0 <do_execve>:
{
ffffffffc0204db0:	7171                	addi	sp,sp,-176
ffffffffc0204db2:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204db4:	000b0d97          	auipc	s11,0xb0
ffffffffc0204db8:	274d8d93          	addi	s11,s11,628 # ffffffffc02b5028 <current>
ffffffffc0204dbc:	000db783          	ld	a5,0(s11)
{
ffffffffc0204dc0:	e94a                	sd	s2,144(sp)
ffffffffc0204dc2:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204dc4:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204dc8:	ed26                	sd	s1,152(sp)
ffffffffc0204dca:	f8da                	sd	s6,112(sp)
ffffffffc0204dcc:	84aa                	mv	s1,a0
ffffffffc0204dce:	8b32                	mv	s6,a2
ffffffffc0204dd0:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204dd2:	862e                	mv	a2,a1
ffffffffc0204dd4:	4681                	li	a3,0
ffffffffc0204dd6:	85aa                	mv	a1,a0
ffffffffc0204dd8:	854a                	mv	a0,s2
{
ffffffffc0204dda:	f506                	sd	ra,168(sp)
ffffffffc0204ddc:	e54e                	sd	s3,136(sp)
ffffffffc0204dde:	e152                	sd	s4,128(sp)
ffffffffc0204de0:	fcd6                	sd	s5,120(sp)
ffffffffc0204de2:	f4de                	sd	s7,104(sp)
ffffffffc0204de4:	f0e2                	sd	s8,96(sp)
ffffffffc0204de6:	ece6                	sd	s9,88(sp)
ffffffffc0204de8:	e8ea                	sd	s10,80(sp)
ffffffffc0204dea:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204dec:	cd0ff0ef          	jal	ra,ffffffffc02042bc <user_mem_check>
ffffffffc0204df0:	40050a63          	beqz	a0,ffffffffc0205204 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204df4:	4641                	li	a2,16
ffffffffc0204df6:	4581                	li	a1,0
ffffffffc0204df8:	1808                	addi	a0,sp,48
ffffffffc0204dfa:	643000ef          	jal	ra,ffffffffc0205c3c <memset>
    memcpy(local_name, name, len);
ffffffffc0204dfe:	47bd                	li	a5,15
ffffffffc0204e00:	8622                	mv	a2,s0
ffffffffc0204e02:	1e87e263          	bltu	a5,s0,ffffffffc0204fe6 <do_execve+0x236>
ffffffffc0204e06:	85a6                	mv	a1,s1
ffffffffc0204e08:	1808                	addi	a0,sp,48
ffffffffc0204e0a:	645000ef          	jal	ra,ffffffffc0205c4e <memcpy>
    if (mm != NULL)
ffffffffc0204e0e:	1e090363          	beqz	s2,ffffffffc0204ff4 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204e12:	00002517          	auipc	a0,0x2
ffffffffc0204e16:	63e50513          	addi	a0,a0,1598 # ffffffffc0207450 <default_pmm_manager+0x9a8>
ffffffffc0204e1a:	bb2fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204e1e:	000b0797          	auipc	a5,0xb0
ffffffffc0204e22:	1d27b783          	ld	a5,466(a5) # ffffffffc02b4ff0 <boot_pgdir_pa>
ffffffffc0204e26:	577d                	li	a4,-1
ffffffffc0204e28:	177e                	slli	a4,a4,0x3f
ffffffffc0204e2a:	83b1                	srli	a5,a5,0xc
ffffffffc0204e2c:	8fd9                	or	a5,a5,a4
ffffffffc0204e2e:	18079073          	csrw	satp,a5
ffffffffc0204e32:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_exit_out_size+0xffffffff7fff4f00>
ffffffffc0204e36:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204e3a:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204e3e:	2c070463          	beqz	a4,ffffffffc0205106 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204e42:	000db783          	ld	a5,0(s11)
ffffffffc0204e46:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204e4a:	949fe0ef          	jal	ra,ffffffffc0203792 <mm_create>
ffffffffc0204e4e:	842a                	mv	s0,a0
ffffffffc0204e50:	1c050d63          	beqz	a0,ffffffffc020502a <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204e54:	4505                	li	a0,1
ffffffffc0204e56:	88efd0ef          	jal	ra,ffffffffc0201ee4 <alloc_pages>
ffffffffc0204e5a:	3a050963          	beqz	a0,ffffffffc020520c <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204e5e:	000b0c97          	auipc	s9,0xb0
ffffffffc0204e62:	1aac8c93          	addi	s9,s9,426 # ffffffffc02b5008 <pages>
ffffffffc0204e66:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204e6a:	000b0c17          	auipc	s8,0xb0
ffffffffc0204e6e:	196c0c13          	addi	s8,s8,406 # ffffffffc02b5000 <npage>
    return page - pages + nbase;
ffffffffc0204e72:	00003717          	auipc	a4,0x3
ffffffffc0204e76:	14673703          	ld	a4,326(a4) # ffffffffc0207fb8 <nbase>
ffffffffc0204e7a:	40d506b3          	sub	a3,a0,a3
ffffffffc0204e7e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204e80:	5a7d                	li	s4,-1
ffffffffc0204e82:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204e86:	96ba                	add	a3,a3,a4
ffffffffc0204e88:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204e8a:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204e8e:	ec3a                	sd	a4,24(sp)
ffffffffc0204e90:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e92:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e94:	38f77063          	bgeu	a4,a5,ffffffffc0205214 <do_execve+0x464>
ffffffffc0204e98:	000b0a97          	auipc	s5,0xb0
ffffffffc0204e9c:	180a8a93          	addi	s5,s5,384 # ffffffffc02b5018 <va_pa_offset>
ffffffffc0204ea0:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204ea4:	6605                	lui	a2,0x1
ffffffffc0204ea6:	000b0597          	auipc	a1,0xb0
ffffffffc0204eaa:	1525b583          	ld	a1,338(a1) # ffffffffc02b4ff8 <boot_pgdir_va>
ffffffffc0204eae:	94b6                	add	s1,s1,a3
ffffffffc0204eb0:	8526                	mv	a0,s1
ffffffffc0204eb2:	59d000ef          	jal	ra,ffffffffc0205c4e <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204eb6:	7782                	ld	a5,32(sp)
ffffffffc0204eb8:	4398                	lw	a4,0(a5)
ffffffffc0204eba:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204ebe:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204ec0:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b944f>
ffffffffc0204ec4:	14f71963          	bne	a4,a5,ffffffffc0205016 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ec8:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc0204eca:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ecc:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204ed0:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ed4:	00371793          	slli	a5,a4,0x3
ffffffffc0204ed8:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204eda:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204edc:	078e                	slli	a5,a5,0x3
ffffffffc0204ede:	97ca                	add	a5,a5,s2
ffffffffc0204ee0:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204ee2:	00f97c63          	bgeu	s2,a5,ffffffffc0204efa <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204ee6:	00092783          	lw	a5,0(s2)
ffffffffc0204eea:	4705                	li	a4,1
ffffffffc0204eec:	14e78163          	beq	a5,a4,ffffffffc020502e <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204ef0:	77a2                	ld	a5,40(sp)
ffffffffc0204ef2:	03890913          	addi	s2,s2,56
ffffffffc0204ef6:	fef968e3          	bltu	s2,a5,ffffffffc0204ee6 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204efa:	4701                	li	a4,0
ffffffffc0204efc:	46ad                	li	a3,11
ffffffffc0204efe:	00100637          	lui	a2,0x100
ffffffffc0204f02:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204f06:	8522                	mv	a0,s0
ffffffffc0204f08:	c23fe0ef          	jal	ra,ffffffffc0203b2a <mm_map>
ffffffffc0204f0c:	89aa                	mv	s3,a0
ffffffffc0204f0e:	1e051263          	bnez	a0,ffffffffc02050f2 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204f12:	6c08                	ld	a0,24(s0)
ffffffffc0204f14:	467d                	li	a2,31
ffffffffc0204f16:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204f1a:	f92fe0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc0204f1e:	38050363          	beqz	a0,ffffffffc02052a4 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f22:	6c08                	ld	a0,24(s0)
ffffffffc0204f24:	467d                	li	a2,31
ffffffffc0204f26:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204f2a:	f82fe0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc0204f2e:	34050b63          	beqz	a0,ffffffffc0205284 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f32:	6c08                	ld	a0,24(s0)
ffffffffc0204f34:	467d                	li	a2,31
ffffffffc0204f36:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204f3a:	f72fe0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc0204f3e:	32050363          	beqz	a0,ffffffffc0205264 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f42:	6c08                	ld	a0,24(s0)
ffffffffc0204f44:	467d                	li	a2,31
ffffffffc0204f46:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204f4a:	f62fe0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc0204f4e:	2e050b63          	beqz	a0,ffffffffc0205244 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204f52:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc0204f54:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204f58:	6c14                	ld	a3,24(s0)
ffffffffc0204f5a:	2785                	addiw	a5,a5,1
ffffffffc0204f5c:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204f5e:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204f60:	c02007b7          	lui	a5,0xc0200
ffffffffc0204f64:	2cf6e463          	bltu	a3,a5,ffffffffc020522c <do_execve+0x47c>
ffffffffc0204f68:	000ab783          	ld	a5,0(s5)
ffffffffc0204f6c:	577d                	li	a4,-1
ffffffffc0204f6e:	177e                	slli	a4,a4,0x3f
ffffffffc0204f70:	8e9d                	sub	a3,a3,a5
ffffffffc0204f72:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204f76:	f654                	sd	a3,168(a2)
ffffffffc0204f78:	8fd9                	or	a5,a5,a4
ffffffffc0204f7a:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204f7e:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204f80:	4581                	li	a1,0
ffffffffc0204f82:	12000613          	li	a2,288
ffffffffc0204f86:	8526                	mv	a0,s1
ffffffffc0204f88:	4b5000ef          	jal	ra,ffffffffc0205c3c <memset>
    tf->epc = elf->e_entry;               // 设置程序入口点
ffffffffc0204f8c:	7782                	ld	a5,32(sp)
ffffffffc0204f8e:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;               // 设置用户栈顶指针
ffffffffc0204f90:	4785                	li	a5,1
ffffffffc0204f92:	07fe                	slli	a5,a5,0x1f
ffffffffc0204f94:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;               // 设置程序入口点
ffffffffc0204f96:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0204f9a:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f9e:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0204fa2:	edf7f793          	andi	a5,a5,-289
ffffffffc0204fa6:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204faa:	0b440413          	addi	s0,s0,180
ffffffffc0204fae:	4641                	li	a2,16
ffffffffc0204fb0:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0204fb2:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fb6:	8522                	mv	a0,s0
ffffffffc0204fb8:	485000ef          	jal	ra,ffffffffc0205c3c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fbc:	463d                	li	a2,15
ffffffffc0204fbe:	180c                	addi	a1,sp,48
ffffffffc0204fc0:	8522                	mv	a0,s0
ffffffffc0204fc2:	48d000ef          	jal	ra,ffffffffc0205c4e <memcpy>
}
ffffffffc0204fc6:	70aa                	ld	ra,168(sp)
ffffffffc0204fc8:	740a                	ld	s0,160(sp)
ffffffffc0204fca:	64ea                	ld	s1,152(sp)
ffffffffc0204fcc:	694a                	ld	s2,144(sp)
ffffffffc0204fce:	6a0a                	ld	s4,128(sp)
ffffffffc0204fd0:	7ae6                	ld	s5,120(sp)
ffffffffc0204fd2:	7b46                	ld	s6,112(sp)
ffffffffc0204fd4:	7ba6                	ld	s7,104(sp)
ffffffffc0204fd6:	7c06                	ld	s8,96(sp)
ffffffffc0204fd8:	6ce6                	ld	s9,88(sp)
ffffffffc0204fda:	6d46                	ld	s10,80(sp)
ffffffffc0204fdc:	6da6                	ld	s11,72(sp)
ffffffffc0204fde:	854e                	mv	a0,s3
ffffffffc0204fe0:	69aa                	ld	s3,136(sp)
ffffffffc0204fe2:	614d                	addi	sp,sp,176
ffffffffc0204fe4:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204fe6:	463d                	li	a2,15
ffffffffc0204fe8:	85a6                	mv	a1,s1
ffffffffc0204fea:	1808                	addi	a0,sp,48
ffffffffc0204fec:	463000ef          	jal	ra,ffffffffc0205c4e <memcpy>
    if (mm != NULL)
ffffffffc0204ff0:	e20911e3          	bnez	s2,ffffffffc0204e12 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204ff4:	000db783          	ld	a5,0(s11)
ffffffffc0204ff8:	779c                	ld	a5,40(a5)
ffffffffc0204ffa:	e40788e3          	beqz	a5,ffffffffc0204e4a <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204ffe:	00003617          	auipc	a2,0x3
ffffffffc0205002:	8ea60613          	addi	a2,a2,-1814 # ffffffffc02078e8 <default_pmm_manager+0xe40>
ffffffffc0205006:	25c00593          	li	a1,604
ffffffffc020500a:	00002517          	auipc	a0,0x2
ffffffffc020500e:	71650513          	addi	a0,a0,1814 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0205012:	c7cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0205016:	8522                	mv	a0,s0
ffffffffc0205018:	c48ff0ef          	jal	ra,ffffffffc0204460 <put_pgdir>
    mm_destroy(mm);
ffffffffc020501c:	8522                	mv	a0,s0
ffffffffc020501e:	abbfe0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0205022:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0205024:	854e                	mv	a0,s3
ffffffffc0205026:	94bff0ef          	jal	ra,ffffffffc0204970 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc020502a:	59f1                	li	s3,-4
ffffffffc020502c:	bfe5                	j	ffffffffc0205024 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc020502e:	02893603          	ld	a2,40(s2)
ffffffffc0205032:	02093783          	ld	a5,32(s2)
ffffffffc0205036:	1cf66d63          	bltu	a2,a5,ffffffffc0205210 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc020503a:	00492783          	lw	a5,4(s2)
ffffffffc020503e:	0017f693          	andi	a3,a5,1
ffffffffc0205042:	c291                	beqz	a3,ffffffffc0205046 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0205044:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205046:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc020504a:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc020504c:	e779                	bnez	a4,ffffffffc020511a <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc020504e:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205050:	c781                	beqz	a5,ffffffffc0205058 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0205052:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0205056:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0205058:	0026f793          	andi	a5,a3,2
ffffffffc020505c:	e3f1                	bnez	a5,ffffffffc0205120 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc020505e:	0046f793          	andi	a5,a3,4
ffffffffc0205062:	c399                	beqz	a5,ffffffffc0205068 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0205064:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0205068:	01093583          	ld	a1,16(s2)
ffffffffc020506c:	4701                	li	a4,0
ffffffffc020506e:	8522                	mv	a0,s0
ffffffffc0205070:	abbfe0ef          	jal	ra,ffffffffc0203b2a <mm_map>
ffffffffc0205074:	89aa                	mv	s3,a0
ffffffffc0205076:	ed35                	bnez	a0,ffffffffc02050f2 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205078:	01093b03          	ld	s6,16(s2)
ffffffffc020507c:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc020507e:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205082:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205086:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc020508a:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc020508c:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc020508e:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0205090:	053b6963          	bltu	s6,s3,ffffffffc02050e2 <do_execve+0x332>
ffffffffc0205094:	aa95                	j	ffffffffc0205208 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205096:	6785                	lui	a5,0x1
ffffffffc0205098:	414b0533          	sub	a0,s6,s4
ffffffffc020509c:	9a3e                	add	s4,s4,a5
ffffffffc020509e:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc02050a2:	0149f463          	bgeu	s3,s4,ffffffffc02050aa <do_execve+0x2fa>
                size -= la - end;
ffffffffc02050a6:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc02050aa:	000cb683          	ld	a3,0(s9)
ffffffffc02050ae:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02050b0:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02050b4:	40db86b3          	sub	a3,s7,a3
ffffffffc02050b8:	8699                	srai	a3,a3,0x6
ffffffffc02050ba:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02050bc:	67e2                	ld	a5,24(sp)
ffffffffc02050be:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02050c2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02050c4:	14b8f863          	bgeu	a7,a1,ffffffffc0205214 <do_execve+0x464>
ffffffffc02050c8:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02050cc:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc02050ce:	9b32                	add	s6,s6,a2
ffffffffc02050d0:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc02050d2:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc02050d4:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02050d6:	379000ef          	jal	ra,ffffffffc0205c4e <memcpy>
            start += size, from += size;
ffffffffc02050da:	6622                	ld	a2,8(sp)
ffffffffc02050dc:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc02050de:	053b7363          	bgeu	s6,s3,ffffffffc0205124 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc02050e2:	6c08                	ld	a0,24(s0)
ffffffffc02050e4:	866a                	mv	a2,s10
ffffffffc02050e6:	85d2                	mv	a1,s4
ffffffffc02050e8:	dc4fe0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc02050ec:	8baa                	mv	s7,a0
ffffffffc02050ee:	f545                	bnez	a0,ffffffffc0205096 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc02050f0:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc02050f2:	8522                	mv	a0,s0
ffffffffc02050f4:	b81fe0ef          	jal	ra,ffffffffc0203c74 <exit_mmap>
    put_pgdir(mm);
ffffffffc02050f8:	8522                	mv	a0,s0
ffffffffc02050fa:	b66ff0ef          	jal	ra,ffffffffc0204460 <put_pgdir>
    mm_destroy(mm);
ffffffffc02050fe:	8522                	mv	a0,s0
ffffffffc0205100:	9d9fe0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>
    return ret;
ffffffffc0205104:	b705                	j	ffffffffc0205024 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0205106:	854a                	mv	a0,s2
ffffffffc0205108:	b6dfe0ef          	jal	ra,ffffffffc0203c74 <exit_mmap>
            put_pgdir(mm);
ffffffffc020510c:	854a                	mv	a0,s2
ffffffffc020510e:	b52ff0ef          	jal	ra,ffffffffc0204460 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205112:	854a                	mv	a0,s2
ffffffffc0205114:	9c5fe0ef          	jal	ra,ffffffffc0203ad8 <mm_destroy>
ffffffffc0205118:	b32d                	j	ffffffffc0204e42 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc020511a:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc020511e:	fb95                	bnez	a5,ffffffffc0205052 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0205120:	4d5d                	li	s10,23
ffffffffc0205122:	bf35                	j	ffffffffc020505e <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0205124:	01093483          	ld	s1,16(s2)
ffffffffc0205128:	02893683          	ld	a3,40(s2)
ffffffffc020512c:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc020512e:	074b7d63          	bgeu	s6,s4,ffffffffc02051a8 <do_execve+0x3f8>
            if (start == end)
ffffffffc0205132:	db648fe3          	beq	s1,s6,ffffffffc0204ef0 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205136:	6785                	lui	a5,0x1
ffffffffc0205138:	00fb0533          	add	a0,s6,a5
ffffffffc020513c:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0205140:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0205144:	0b44fd63          	bgeu	s1,s4,ffffffffc02051fe <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0205148:	000cb683          	ld	a3,0(s9)
ffffffffc020514c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020514e:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0205152:	40db86b3          	sub	a3,s7,a3
ffffffffc0205156:	8699                	srai	a3,a3,0x6
ffffffffc0205158:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020515a:	67e2                	ld	a5,24(sp)
ffffffffc020515c:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205160:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205162:	0ac5f963          	bgeu	a1,a2,ffffffffc0205214 <do_execve+0x464>
ffffffffc0205166:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc020516a:	864e                	mv	a2,s3
ffffffffc020516c:	4581                	li	a1,0
ffffffffc020516e:	96c6                	add	a3,a3,a7
ffffffffc0205170:	9536                	add	a0,a0,a3
ffffffffc0205172:	2cb000ef          	jal	ra,ffffffffc0205c3c <memset>
            start += size;
ffffffffc0205176:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc020517a:	0344f463          	bgeu	s1,s4,ffffffffc02051a2 <do_execve+0x3f2>
ffffffffc020517e:	d6e489e3          	beq	s1,a4,ffffffffc0204ef0 <do_execve+0x140>
ffffffffc0205182:	00002697          	auipc	a3,0x2
ffffffffc0205186:	78e68693          	addi	a3,a3,1934 # ffffffffc0207910 <default_pmm_manager+0xe68>
ffffffffc020518a:	00001617          	auipc	a2,0x1
ffffffffc020518e:	56e60613          	addi	a2,a2,1390 # ffffffffc02066f8 <commands+0x828>
ffffffffc0205192:	2c500593          	li	a1,709
ffffffffc0205196:	00002517          	auipc	a0,0x2
ffffffffc020519a:	58a50513          	addi	a0,a0,1418 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc020519e:	af0fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02051a2:	ff4710e3          	bne	a4,s4,ffffffffc0205182 <do_execve+0x3d2>
ffffffffc02051a6:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc02051a8:	d49b74e3          	bgeu	s6,s1,ffffffffc0204ef0 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc02051ac:	6c08                	ld	a0,24(s0)
ffffffffc02051ae:	866a                	mv	a2,s10
ffffffffc02051b0:	85d2                	mv	a1,s4
ffffffffc02051b2:	cfafe0ef          	jal	ra,ffffffffc02036ac <pgdir_alloc_page>
ffffffffc02051b6:	8baa                	mv	s7,a0
ffffffffc02051b8:	dd05                	beqz	a0,ffffffffc02050f0 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02051ba:	6785                	lui	a5,0x1
ffffffffc02051bc:	414b0533          	sub	a0,s6,s4
ffffffffc02051c0:	9a3e                	add	s4,s4,a5
ffffffffc02051c2:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc02051c6:	0144f463          	bgeu	s1,s4,ffffffffc02051ce <do_execve+0x41e>
                size -= la - end;
ffffffffc02051ca:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc02051ce:	000cb683          	ld	a3,0(s9)
ffffffffc02051d2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02051d4:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02051d8:	40db86b3          	sub	a3,s7,a3
ffffffffc02051dc:	8699                	srai	a3,a3,0x6
ffffffffc02051de:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02051e0:	67e2                	ld	a5,24(sp)
ffffffffc02051e2:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02051e6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02051e8:	02b8f663          	bgeu	a7,a1,ffffffffc0205214 <do_execve+0x464>
ffffffffc02051ec:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc02051f0:	4581                	li	a1,0
            start += size;
ffffffffc02051f2:	9b32                	add	s6,s6,a2
ffffffffc02051f4:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc02051f6:	9536                	add	a0,a0,a3
ffffffffc02051f8:	245000ef          	jal	ra,ffffffffc0205c3c <memset>
ffffffffc02051fc:	b775                	j	ffffffffc02051a8 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02051fe:	416a09b3          	sub	s3,s4,s6
ffffffffc0205202:	b799                	j	ffffffffc0205148 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0205204:	59f5                	li	s3,-3
ffffffffc0205206:	b3c1                	j	ffffffffc0204fc6 <do_execve+0x216>
        while (start < end)
ffffffffc0205208:	84da                	mv	s1,s6
ffffffffc020520a:	bf39                	j	ffffffffc0205128 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc020520c:	59f1                	li	s3,-4
ffffffffc020520e:	bdc5                	j	ffffffffc02050fe <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0205210:	59e1                	li	s3,-8
ffffffffc0205212:	b5c5                	j	ffffffffc02050f2 <do_execve+0x342>
ffffffffc0205214:	00002617          	auipc	a2,0x2
ffffffffc0205218:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0206ae0 <default_pmm_manager+0x38>
ffffffffc020521c:	07100593          	li	a1,113
ffffffffc0205220:	00002517          	auipc	a0,0x2
ffffffffc0205224:	8e850513          	addi	a0,a0,-1816 # ffffffffc0206b08 <default_pmm_manager+0x60>
ffffffffc0205228:	a66fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020522c:	00002617          	auipc	a2,0x2
ffffffffc0205230:	95c60613          	addi	a2,a2,-1700 # ffffffffc0206b88 <default_pmm_manager+0xe0>
ffffffffc0205234:	2e400593          	li	a1,740
ffffffffc0205238:	00002517          	auipc	a0,0x2
ffffffffc020523c:	4e850513          	addi	a0,a0,1256 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0205240:	a4efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205244:	00002697          	auipc	a3,0x2
ffffffffc0205248:	7e468693          	addi	a3,a3,2020 # ffffffffc0207a28 <default_pmm_manager+0xf80>
ffffffffc020524c:	00001617          	auipc	a2,0x1
ffffffffc0205250:	4ac60613          	addi	a2,a2,1196 # ffffffffc02066f8 <commands+0x828>
ffffffffc0205254:	2df00593          	li	a1,735
ffffffffc0205258:	00002517          	auipc	a0,0x2
ffffffffc020525c:	4c850513          	addi	a0,a0,1224 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0205260:	a2efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205264:	00002697          	auipc	a3,0x2
ffffffffc0205268:	77c68693          	addi	a3,a3,1916 # ffffffffc02079e0 <default_pmm_manager+0xf38>
ffffffffc020526c:	00001617          	auipc	a2,0x1
ffffffffc0205270:	48c60613          	addi	a2,a2,1164 # ffffffffc02066f8 <commands+0x828>
ffffffffc0205274:	2de00593          	li	a1,734
ffffffffc0205278:	00002517          	auipc	a0,0x2
ffffffffc020527c:	4a850513          	addi	a0,a0,1192 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0205280:	a0efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205284:	00002697          	auipc	a3,0x2
ffffffffc0205288:	71468693          	addi	a3,a3,1812 # ffffffffc0207998 <default_pmm_manager+0xef0>
ffffffffc020528c:	00001617          	auipc	a2,0x1
ffffffffc0205290:	46c60613          	addi	a2,a2,1132 # ffffffffc02066f8 <commands+0x828>
ffffffffc0205294:	2dd00593          	li	a1,733
ffffffffc0205298:	00002517          	auipc	a0,0x2
ffffffffc020529c:	48850513          	addi	a0,a0,1160 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc02052a0:	9eefb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02052a4:	00002697          	auipc	a3,0x2
ffffffffc02052a8:	6ac68693          	addi	a3,a3,1708 # ffffffffc0207950 <default_pmm_manager+0xea8>
ffffffffc02052ac:	00001617          	auipc	a2,0x1
ffffffffc02052b0:	44c60613          	addi	a2,a2,1100 # ffffffffc02066f8 <commands+0x828>
ffffffffc02052b4:	2dc00593          	li	a1,732
ffffffffc02052b8:	00002517          	auipc	a0,0x2
ffffffffc02052bc:	46850513          	addi	a0,a0,1128 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc02052c0:	9cefb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02052c4 <do_yield>:
    current->need_resched = 1;
ffffffffc02052c4:	000b0797          	auipc	a5,0xb0
ffffffffc02052c8:	d647b783          	ld	a5,-668(a5) # ffffffffc02b5028 <current>
ffffffffc02052cc:	4705                	li	a4,1
ffffffffc02052ce:	ef98                	sd	a4,24(a5)
}
ffffffffc02052d0:	4501                	li	a0,0
ffffffffc02052d2:	8082                	ret

ffffffffc02052d4 <do_wait>:
{
ffffffffc02052d4:	1101                	addi	sp,sp,-32
ffffffffc02052d6:	e822                	sd	s0,16(sp)
ffffffffc02052d8:	e426                	sd	s1,8(sp)
ffffffffc02052da:	ec06                	sd	ra,24(sp)
ffffffffc02052dc:	842e                	mv	s0,a1
ffffffffc02052de:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc02052e0:	c999                	beqz	a1,ffffffffc02052f6 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc02052e2:	000b0797          	auipc	a5,0xb0
ffffffffc02052e6:	d467b783          	ld	a5,-698(a5) # ffffffffc02b5028 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc02052ea:	7788                	ld	a0,40(a5)
ffffffffc02052ec:	4685                	li	a3,1
ffffffffc02052ee:	4611                	li	a2,4
ffffffffc02052f0:	fcdfe0ef          	jal	ra,ffffffffc02042bc <user_mem_check>
ffffffffc02052f4:	c909                	beqz	a0,ffffffffc0205306 <do_wait+0x32>
ffffffffc02052f6:	85a2                	mv	a1,s0
}
ffffffffc02052f8:	6442                	ld	s0,16(sp)
ffffffffc02052fa:	60e2                	ld	ra,24(sp)
ffffffffc02052fc:	8526                	mv	a0,s1
ffffffffc02052fe:	64a2                	ld	s1,8(sp)
ffffffffc0205300:	6105                	addi	sp,sp,32
ffffffffc0205302:	fb8ff06f          	j	ffffffffc0204aba <do_wait.part.0>
ffffffffc0205306:	60e2                	ld	ra,24(sp)
ffffffffc0205308:	6442                	ld	s0,16(sp)
ffffffffc020530a:	64a2                	ld	s1,8(sp)
ffffffffc020530c:	5575                	li	a0,-3
ffffffffc020530e:	6105                	addi	sp,sp,32
ffffffffc0205310:	8082                	ret

ffffffffc0205312 <do_kill>:
{
ffffffffc0205312:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0205314:	6789                	lui	a5,0x2
{
ffffffffc0205316:	e406                	sd	ra,8(sp)
ffffffffc0205318:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc020531a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020531e:	17f9                	addi	a5,a5,-2
ffffffffc0205320:	02e7e963          	bltu	a5,a4,ffffffffc0205352 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205324:	842a                	mv	s0,a0
ffffffffc0205326:	45a9                	li	a1,10
ffffffffc0205328:	2501                	sext.w	a0,a0
ffffffffc020532a:	46c000ef          	jal	ra,ffffffffc0205796 <hash32>
ffffffffc020532e:	02051793          	slli	a5,a0,0x20
ffffffffc0205332:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205336:	000ac797          	auipc	a5,0xac
ffffffffc020533a:	c7278793          	addi	a5,a5,-910 # ffffffffc02b0fa8 <hash_list>
ffffffffc020533e:	953e                	add	a0,a0,a5
ffffffffc0205340:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0205342:	a029                	j	ffffffffc020534c <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0205344:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205348:	00870b63          	beq	a4,s0,ffffffffc020535e <do_kill+0x4c>
ffffffffc020534c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020534e:	fef51be3          	bne	a0,a5,ffffffffc0205344 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205352:	5475                	li	s0,-3
}
ffffffffc0205354:	60a2                	ld	ra,8(sp)
ffffffffc0205356:	8522                	mv	a0,s0
ffffffffc0205358:	6402                	ld	s0,0(sp)
ffffffffc020535a:	0141                	addi	sp,sp,16
ffffffffc020535c:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc020535e:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205362:	00177693          	andi	a3,a4,1
ffffffffc0205366:	e295                	bnez	a3,ffffffffc020538a <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205368:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc020536a:	00176713          	ori	a4,a4,1
ffffffffc020536e:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205372:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205374:	fe06d0e3          	bgez	a3,ffffffffc0205354 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0205378:	f2878513          	addi	a0,a5,-216
ffffffffc020537c:	22e000ef          	jal	ra,ffffffffc02055aa <wakeup_proc>
}
ffffffffc0205380:	60a2                	ld	ra,8(sp)
ffffffffc0205382:	8522                	mv	a0,s0
ffffffffc0205384:	6402                	ld	s0,0(sp)
ffffffffc0205386:	0141                	addi	sp,sp,16
ffffffffc0205388:	8082                	ret
        return -E_KILLED;
ffffffffc020538a:	545d                	li	s0,-9
ffffffffc020538c:	b7e1                	j	ffffffffc0205354 <do_kill+0x42>

ffffffffc020538e <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc020538e:	1101                	addi	sp,sp,-32
ffffffffc0205390:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205392:	000b0797          	auipc	a5,0xb0
ffffffffc0205396:	c1678793          	addi	a5,a5,-1002 # ffffffffc02b4fa8 <proc_list>
ffffffffc020539a:	ec06                	sd	ra,24(sp)
ffffffffc020539c:	e822                	sd	s0,16(sp)
ffffffffc020539e:	e04a                	sd	s2,0(sp)
ffffffffc02053a0:	000ac497          	auipc	s1,0xac
ffffffffc02053a4:	c0848493          	addi	s1,s1,-1016 # ffffffffc02b0fa8 <hash_list>
ffffffffc02053a8:	e79c                	sd	a5,8(a5)
ffffffffc02053aa:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02053ac:	000b0717          	auipc	a4,0xb0
ffffffffc02053b0:	bfc70713          	addi	a4,a4,-1028 # ffffffffc02b4fa8 <proc_list>
ffffffffc02053b4:	87a6                	mv	a5,s1
ffffffffc02053b6:	e79c                	sd	a5,8(a5)
ffffffffc02053b8:	e39c                	sd	a5,0(a5)
ffffffffc02053ba:	07c1                	addi	a5,a5,16
ffffffffc02053bc:	fef71de3          	bne	a4,a5,ffffffffc02053b6 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02053c0:	f99fe0ef          	jal	ra,ffffffffc0204358 <alloc_proc>
ffffffffc02053c4:	000b0917          	auipc	s2,0xb0
ffffffffc02053c8:	c6c90913          	addi	s2,s2,-916 # ffffffffc02b5030 <idleproc>
ffffffffc02053cc:	00a93023          	sd	a0,0(s2)
ffffffffc02053d0:	0e050f63          	beqz	a0,ffffffffc02054ce <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02053d4:	4789                	li	a5,2
ffffffffc02053d6:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02053d8:	00003797          	auipc	a5,0x3
ffffffffc02053dc:	c2878793          	addi	a5,a5,-984 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02053e0:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02053e4:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc02053e6:	4785                	li	a5,1
ffffffffc02053e8:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02053ea:	4641                	li	a2,16
ffffffffc02053ec:	4581                	li	a1,0
ffffffffc02053ee:	8522                	mv	a0,s0
ffffffffc02053f0:	04d000ef          	jal	ra,ffffffffc0205c3c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02053f4:	463d                	li	a2,15
ffffffffc02053f6:	00002597          	auipc	a1,0x2
ffffffffc02053fa:	69258593          	addi	a1,a1,1682 # ffffffffc0207a88 <default_pmm_manager+0xfe0>
ffffffffc02053fe:	8522                	mv	a0,s0
ffffffffc0205400:	04f000ef          	jal	ra,ffffffffc0205c4e <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205404:	000b0717          	auipc	a4,0xb0
ffffffffc0205408:	c3c70713          	addi	a4,a4,-964 # ffffffffc02b5040 <nr_process>
ffffffffc020540c:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020540e:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205412:	4601                	li	a2,0
    nr_process++;
ffffffffc0205414:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205416:	4581                	li	a1,0
ffffffffc0205418:	00000517          	auipc	a0,0x0
ffffffffc020541c:	87450513          	addi	a0,a0,-1932 # ffffffffc0204c8c <init_main>
    nr_process++;
ffffffffc0205420:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205422:	000b0797          	auipc	a5,0xb0
ffffffffc0205426:	c0d7b323          	sd	a3,-1018(a5) # ffffffffc02b5028 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020542a:	cf6ff0ef          	jal	ra,ffffffffc0204920 <kernel_thread>
ffffffffc020542e:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205430:	08a05363          	blez	a0,ffffffffc02054b6 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205434:	6789                	lui	a5,0x2
ffffffffc0205436:	fff5071b          	addiw	a4,a0,-1
ffffffffc020543a:	17f9                	addi	a5,a5,-2
ffffffffc020543c:	2501                	sext.w	a0,a0
ffffffffc020543e:	02e7e363          	bltu	a5,a4,ffffffffc0205464 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205442:	45a9                	li	a1,10
ffffffffc0205444:	352000ef          	jal	ra,ffffffffc0205796 <hash32>
ffffffffc0205448:	02051793          	slli	a5,a0,0x20
ffffffffc020544c:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205450:	96a6                	add	a3,a3,s1
ffffffffc0205452:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205454:	a029                	j	ffffffffc020545e <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205456:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c94>
ffffffffc020545a:	04870b63          	beq	a4,s0,ffffffffc02054b0 <proc_init+0x122>
    return listelm->next;
ffffffffc020545e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205460:	fef69be3          	bne	a3,a5,ffffffffc0205456 <proc_init+0xc8>
    return NULL;
ffffffffc0205464:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205466:	0b478493          	addi	s1,a5,180
ffffffffc020546a:	4641                	li	a2,16
ffffffffc020546c:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc020546e:	000b0417          	auipc	s0,0xb0
ffffffffc0205472:	bca40413          	addi	s0,s0,-1078 # ffffffffc02b5038 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205476:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205478:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020547a:	7c2000ef          	jal	ra,ffffffffc0205c3c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020547e:	463d                	li	a2,15
ffffffffc0205480:	00002597          	auipc	a1,0x2
ffffffffc0205484:	63058593          	addi	a1,a1,1584 # ffffffffc0207ab0 <default_pmm_manager+0x1008>
ffffffffc0205488:	8526                	mv	a0,s1
ffffffffc020548a:	7c4000ef          	jal	ra,ffffffffc0205c4e <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020548e:	00093783          	ld	a5,0(s2)
ffffffffc0205492:	cbb5                	beqz	a5,ffffffffc0205506 <proc_init+0x178>
ffffffffc0205494:	43dc                	lw	a5,4(a5)
ffffffffc0205496:	eba5                	bnez	a5,ffffffffc0205506 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205498:	601c                	ld	a5,0(s0)
ffffffffc020549a:	c7b1                	beqz	a5,ffffffffc02054e6 <proc_init+0x158>
ffffffffc020549c:	43d8                	lw	a4,4(a5)
ffffffffc020549e:	4785                	li	a5,1
ffffffffc02054a0:	04f71363          	bne	a4,a5,ffffffffc02054e6 <proc_init+0x158>
}
ffffffffc02054a4:	60e2                	ld	ra,24(sp)
ffffffffc02054a6:	6442                	ld	s0,16(sp)
ffffffffc02054a8:	64a2                	ld	s1,8(sp)
ffffffffc02054aa:	6902                	ld	s2,0(sp)
ffffffffc02054ac:	6105                	addi	sp,sp,32
ffffffffc02054ae:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02054b0:	f2878793          	addi	a5,a5,-216
ffffffffc02054b4:	bf4d                	j	ffffffffc0205466 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02054b6:	00002617          	auipc	a2,0x2
ffffffffc02054ba:	5da60613          	addi	a2,a2,1498 # ffffffffc0207a90 <default_pmm_manager+0xfe8>
ffffffffc02054be:	40600593          	li	a1,1030
ffffffffc02054c2:	00002517          	auipc	a0,0x2
ffffffffc02054c6:	25e50513          	addi	a0,a0,606 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc02054ca:	fc5fa0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02054ce:	00002617          	auipc	a2,0x2
ffffffffc02054d2:	5a260613          	addi	a2,a2,1442 # ffffffffc0207a70 <default_pmm_manager+0xfc8>
ffffffffc02054d6:	3f700593          	li	a1,1015
ffffffffc02054da:	00002517          	auipc	a0,0x2
ffffffffc02054de:	24650513          	addi	a0,a0,582 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc02054e2:	fadfa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02054e6:	00002697          	auipc	a3,0x2
ffffffffc02054ea:	5fa68693          	addi	a3,a3,1530 # ffffffffc0207ae0 <default_pmm_manager+0x1038>
ffffffffc02054ee:	00001617          	auipc	a2,0x1
ffffffffc02054f2:	20a60613          	addi	a2,a2,522 # ffffffffc02066f8 <commands+0x828>
ffffffffc02054f6:	40d00593          	li	a1,1037
ffffffffc02054fa:	00002517          	auipc	a0,0x2
ffffffffc02054fe:	22650513          	addi	a0,a0,550 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0205502:	f8dfa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205506:	00002697          	auipc	a3,0x2
ffffffffc020550a:	5b268693          	addi	a3,a3,1458 # ffffffffc0207ab8 <default_pmm_manager+0x1010>
ffffffffc020550e:	00001617          	auipc	a2,0x1
ffffffffc0205512:	1ea60613          	addi	a2,a2,490 # ffffffffc02066f8 <commands+0x828>
ffffffffc0205516:	40c00593          	li	a1,1036
ffffffffc020551a:	00002517          	auipc	a0,0x2
ffffffffc020551e:	20650513          	addi	a0,a0,518 # ffffffffc0207720 <default_pmm_manager+0xc78>
ffffffffc0205522:	f6dfa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205526 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205526:	1141                	addi	sp,sp,-16
ffffffffc0205528:	e022                	sd	s0,0(sp)
ffffffffc020552a:	e406                	sd	ra,8(sp)
ffffffffc020552c:	000b0417          	auipc	s0,0xb0
ffffffffc0205530:	afc40413          	addi	s0,s0,-1284 # ffffffffc02b5028 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205534:	6018                	ld	a4,0(s0)
ffffffffc0205536:	6f1c                	ld	a5,24(a4)
ffffffffc0205538:	dffd                	beqz	a5,ffffffffc0205536 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020553a:	0f0000ef          	jal	ra,ffffffffc020562a <schedule>
ffffffffc020553e:	bfdd                	j	ffffffffc0205534 <cpu_idle+0xe>

ffffffffc0205540 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205540:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205544:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205548:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020554a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020554c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205550:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205554:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205558:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020555c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205560:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205564:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205568:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020556c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205570:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205574:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205578:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020557c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020557e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205580:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205584:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205588:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020558c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205590:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205594:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205598:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020559c:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02055a0:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02055a4:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02055a8:	8082                	ret

ffffffffc02055aa <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02055aa:	4118                	lw	a4,0(a0)
{
ffffffffc02055ac:	1101                	addi	sp,sp,-32
ffffffffc02055ae:	ec06                	sd	ra,24(sp)
ffffffffc02055b0:	e822                	sd	s0,16(sp)
ffffffffc02055b2:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02055b4:	478d                	li	a5,3
ffffffffc02055b6:	04f70b63          	beq	a4,a5,ffffffffc020560c <wakeup_proc+0x62>
ffffffffc02055ba:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02055bc:	100027f3          	csrr	a5,sstatus
ffffffffc02055c0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02055c2:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02055c4:	ef9d                	bnez	a5,ffffffffc0205602 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02055c6:	4789                	li	a5,2
ffffffffc02055c8:	02f70163          	beq	a4,a5,ffffffffc02055ea <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02055cc:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02055ce:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02055d2:	e491                	bnez	s1,ffffffffc02055de <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02055d4:	60e2                	ld	ra,24(sp)
ffffffffc02055d6:	6442                	ld	s0,16(sp)
ffffffffc02055d8:	64a2                	ld	s1,8(sp)
ffffffffc02055da:	6105                	addi	sp,sp,32
ffffffffc02055dc:	8082                	ret
ffffffffc02055de:	6442                	ld	s0,16(sp)
ffffffffc02055e0:	60e2                	ld	ra,24(sp)
ffffffffc02055e2:	64a2                	ld	s1,8(sp)
ffffffffc02055e4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02055e6:	bc8fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02055ea:	00002617          	auipc	a2,0x2
ffffffffc02055ee:	55660613          	addi	a2,a2,1366 # ffffffffc0207b40 <default_pmm_manager+0x1098>
ffffffffc02055f2:	45d1                	li	a1,20
ffffffffc02055f4:	00002517          	auipc	a0,0x2
ffffffffc02055f8:	53450513          	addi	a0,a0,1332 # ffffffffc0207b28 <default_pmm_manager+0x1080>
ffffffffc02055fc:	efbfa0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205600:	bfc9                	j	ffffffffc02055d2 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205602:	bb2fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205606:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205608:	4485                	li	s1,1
ffffffffc020560a:	bf75                	j	ffffffffc02055c6 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020560c:	00002697          	auipc	a3,0x2
ffffffffc0205610:	4fc68693          	addi	a3,a3,1276 # ffffffffc0207b08 <default_pmm_manager+0x1060>
ffffffffc0205614:	00001617          	auipc	a2,0x1
ffffffffc0205618:	0e460613          	addi	a2,a2,228 # ffffffffc02066f8 <commands+0x828>
ffffffffc020561c:	45a5                	li	a1,9
ffffffffc020561e:	00002517          	auipc	a0,0x2
ffffffffc0205622:	50a50513          	addi	a0,a0,1290 # ffffffffc0207b28 <default_pmm_manager+0x1080>
ffffffffc0205626:	e69fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020562a <schedule>:

void schedule(void)
{
ffffffffc020562a:	1141                	addi	sp,sp,-16
ffffffffc020562c:	e406                	sd	ra,8(sp)
ffffffffc020562e:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205630:	100027f3          	csrr	a5,sstatus
ffffffffc0205634:	8b89                	andi	a5,a5,2
ffffffffc0205636:	4401                	li	s0,0
ffffffffc0205638:	efbd                	bnez	a5,ffffffffc02056b6 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020563a:	000b0897          	auipc	a7,0xb0
ffffffffc020563e:	9ee8b883          	ld	a7,-1554(a7) # ffffffffc02b5028 <current>
ffffffffc0205642:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205646:	000b0517          	auipc	a0,0xb0
ffffffffc020564a:	9ea53503          	ld	a0,-1558(a0) # ffffffffc02b5030 <idleproc>
ffffffffc020564e:	04a88e63          	beq	a7,a0,ffffffffc02056aa <schedule+0x80>
ffffffffc0205652:	0c888693          	addi	a3,a7,200
ffffffffc0205656:	000b0617          	auipc	a2,0xb0
ffffffffc020565a:	95260613          	addi	a2,a2,-1710 # ffffffffc02b4fa8 <proc_list>
        le = last;
ffffffffc020565e:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205660:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205662:	4809                	li	a6,2
ffffffffc0205664:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205666:	00c78863          	beq	a5,a2,ffffffffc0205676 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc020566a:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020566e:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205672:	03070163          	beq	a4,a6,ffffffffc0205694 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205676:	fef697e3          	bne	a3,a5,ffffffffc0205664 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020567a:	ed89                	bnez	a1,ffffffffc0205694 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020567c:	451c                	lw	a5,8(a0)
ffffffffc020567e:	2785                	addiw	a5,a5,1
ffffffffc0205680:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205682:	00a88463          	beq	a7,a0,ffffffffc020568a <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205686:	e51fe0ef          	jal	ra,ffffffffc02044d6 <proc_run>
    if (flag)
ffffffffc020568a:	e819                	bnez	s0,ffffffffc02056a0 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020568c:	60a2                	ld	ra,8(sp)
ffffffffc020568e:	6402                	ld	s0,0(sp)
ffffffffc0205690:	0141                	addi	sp,sp,16
ffffffffc0205692:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205694:	4198                	lw	a4,0(a1)
ffffffffc0205696:	4789                	li	a5,2
ffffffffc0205698:	fef712e3          	bne	a4,a5,ffffffffc020567c <schedule+0x52>
ffffffffc020569c:	852e                	mv	a0,a1
ffffffffc020569e:	bff9                	j	ffffffffc020567c <schedule+0x52>
}
ffffffffc02056a0:	6402                	ld	s0,0(sp)
ffffffffc02056a2:	60a2                	ld	ra,8(sp)
ffffffffc02056a4:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02056a6:	b08fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02056aa:	000b0617          	auipc	a2,0xb0
ffffffffc02056ae:	8fe60613          	addi	a2,a2,-1794 # ffffffffc02b4fa8 <proc_list>
ffffffffc02056b2:	86b2                	mv	a3,a2
ffffffffc02056b4:	b76d                	j	ffffffffc020565e <schedule+0x34>
        intr_disable();
ffffffffc02056b6:	afefb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02056ba:	4405                	li	s0,1
ffffffffc02056bc:	bfbd                	j	ffffffffc020563a <schedule+0x10>

ffffffffc02056be <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02056be:	000b0797          	auipc	a5,0xb0
ffffffffc02056c2:	96a7b783          	ld	a5,-1686(a5) # ffffffffc02b5028 <current>
}
ffffffffc02056c6:	43c8                	lw	a0,4(a5)
ffffffffc02056c8:	8082                	ret

ffffffffc02056ca <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02056ca:	4501                	li	a0,0
ffffffffc02056cc:	8082                	ret

ffffffffc02056ce <sys_putc>:
    cputchar(c);
ffffffffc02056ce:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02056d0:	1141                	addi	sp,sp,-16
ffffffffc02056d2:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02056d4:	af7fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02056d8:	60a2                	ld	ra,8(sp)
ffffffffc02056da:	4501                	li	a0,0
ffffffffc02056dc:	0141                	addi	sp,sp,16
ffffffffc02056de:	8082                	ret

ffffffffc02056e0 <sys_kill>:
    return do_kill(pid);
ffffffffc02056e0:	4108                	lw	a0,0(a0)
ffffffffc02056e2:	c31ff06f          	j	ffffffffc0205312 <do_kill>

ffffffffc02056e6 <sys_yield>:
    return do_yield();
ffffffffc02056e6:	bdfff06f          	j	ffffffffc02052c4 <do_yield>

ffffffffc02056ea <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02056ea:	6d14                	ld	a3,24(a0)
ffffffffc02056ec:	6910                	ld	a2,16(a0)
ffffffffc02056ee:	650c                	ld	a1,8(a0)
ffffffffc02056f0:	6108                	ld	a0,0(a0)
ffffffffc02056f2:	ebeff06f          	j	ffffffffc0204db0 <do_execve>

ffffffffc02056f6 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02056f6:	650c                	ld	a1,8(a0)
ffffffffc02056f8:	4108                	lw	a0,0(a0)
ffffffffc02056fa:	bdbff06f          	j	ffffffffc02052d4 <do_wait>

ffffffffc02056fe <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02056fe:	000b0797          	auipc	a5,0xb0
ffffffffc0205702:	92a7b783          	ld	a5,-1750(a5) # ffffffffc02b5028 <current>
ffffffffc0205706:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205708:	4501                	li	a0,0
ffffffffc020570a:	6a0c                	ld	a1,16(a2)
ffffffffc020570c:	e37fe06f          	j	ffffffffc0204542 <do_fork>

ffffffffc0205710 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205710:	4108                	lw	a0,0(a0)
ffffffffc0205712:	a5eff06f          	j	ffffffffc0204970 <do_exit>

ffffffffc0205716 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205716:	715d                	addi	sp,sp,-80
ffffffffc0205718:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020571a:	000b0497          	auipc	s1,0xb0
ffffffffc020571e:	90e48493          	addi	s1,s1,-1778 # ffffffffc02b5028 <current>
ffffffffc0205722:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205724:	e0a2                	sd	s0,64(sp)
ffffffffc0205726:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205728:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020572a:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020572c:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020572e:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205732:	0327ee63          	bltu	a5,s2,ffffffffc020576e <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205736:	00391713          	slli	a4,s2,0x3
ffffffffc020573a:	00002797          	auipc	a5,0x2
ffffffffc020573e:	46e78793          	addi	a5,a5,1134 # ffffffffc0207ba8 <syscalls>
ffffffffc0205742:	97ba                	add	a5,a5,a4
ffffffffc0205744:	639c                	ld	a5,0(a5)
ffffffffc0205746:	c785                	beqz	a5,ffffffffc020576e <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205748:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020574a:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020574c:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020574e:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205750:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205752:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205754:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205756:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205758:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020575a:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020575c:	0028                	addi	a0,sp,8
ffffffffc020575e:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205760:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205762:	e828                	sd	a0,80(s0)
}
ffffffffc0205764:	6406                	ld	s0,64(sp)
ffffffffc0205766:	74e2                	ld	s1,56(sp)
ffffffffc0205768:	7942                	ld	s2,48(sp)
ffffffffc020576a:	6161                	addi	sp,sp,80
ffffffffc020576c:	8082                	ret
    print_trapframe(tf);
ffffffffc020576e:	8522                	mv	a0,s0
ffffffffc0205770:	c34fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205774:	609c                	ld	a5,0(s1)
ffffffffc0205776:	86ca                	mv	a3,s2
ffffffffc0205778:	00002617          	auipc	a2,0x2
ffffffffc020577c:	3e860613          	addi	a2,a2,1000 # ffffffffc0207b60 <default_pmm_manager+0x10b8>
ffffffffc0205780:	43d8                	lw	a4,4(a5)
ffffffffc0205782:	06200593          	li	a1,98
ffffffffc0205786:	0b478793          	addi	a5,a5,180
ffffffffc020578a:	00002517          	auipc	a0,0x2
ffffffffc020578e:	40650513          	addi	a0,a0,1030 # ffffffffc0207b90 <default_pmm_manager+0x10e8>
ffffffffc0205792:	cfdfa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205796 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205796:	9e3707b7          	lui	a5,0x9e370
ffffffffc020579a:	2785                	addiw	a5,a5,1
ffffffffc020579c:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02057a0:	02000793          	li	a5,32
ffffffffc02057a4:	9f8d                	subw	a5,a5,a1
}
ffffffffc02057a6:	00f5553b          	srlw	a0,a0,a5
ffffffffc02057aa:	8082                	ret

ffffffffc02057ac <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02057ac:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02057b0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02057b2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02057b6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02057b8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02057bc:	f022                	sd	s0,32(sp)
ffffffffc02057be:	ec26                	sd	s1,24(sp)
ffffffffc02057c0:	e84a                	sd	s2,16(sp)
ffffffffc02057c2:	f406                	sd	ra,40(sp)
ffffffffc02057c4:	e44e                	sd	s3,8(sp)
ffffffffc02057c6:	84aa                	mv	s1,a0
ffffffffc02057c8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02057ca:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02057ce:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02057d0:	03067e63          	bgeu	a2,a6,ffffffffc020580c <printnum+0x60>
ffffffffc02057d4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02057d6:	00805763          	blez	s0,ffffffffc02057e4 <printnum+0x38>
ffffffffc02057da:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02057dc:	85ca                	mv	a1,s2
ffffffffc02057de:	854e                	mv	a0,s3
ffffffffc02057e0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02057e2:	fc65                	bnez	s0,ffffffffc02057da <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02057e4:	1a02                	slli	s4,s4,0x20
ffffffffc02057e6:	00002797          	auipc	a5,0x2
ffffffffc02057ea:	4c278793          	addi	a5,a5,1218 # ffffffffc0207ca8 <syscalls+0x100>
ffffffffc02057ee:	020a5a13          	srli	s4,s4,0x20
ffffffffc02057f2:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02057f4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02057f6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02057fa:	70a2                	ld	ra,40(sp)
ffffffffc02057fc:	69a2                	ld	s3,8(sp)
ffffffffc02057fe:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205800:	85ca                	mv	a1,s2
ffffffffc0205802:	87a6                	mv	a5,s1
}
ffffffffc0205804:	6942                	ld	s2,16(sp)
ffffffffc0205806:	64e2                	ld	s1,24(sp)
ffffffffc0205808:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020580a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020580c:	03065633          	divu	a2,a2,a6
ffffffffc0205810:	8722                	mv	a4,s0
ffffffffc0205812:	f9bff0ef          	jal	ra,ffffffffc02057ac <printnum>
ffffffffc0205816:	b7f9                	j	ffffffffc02057e4 <printnum+0x38>

ffffffffc0205818 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205818:	7119                	addi	sp,sp,-128
ffffffffc020581a:	f4a6                	sd	s1,104(sp)
ffffffffc020581c:	f0ca                	sd	s2,96(sp)
ffffffffc020581e:	ecce                	sd	s3,88(sp)
ffffffffc0205820:	e8d2                	sd	s4,80(sp)
ffffffffc0205822:	e4d6                	sd	s5,72(sp)
ffffffffc0205824:	e0da                	sd	s6,64(sp)
ffffffffc0205826:	fc5e                	sd	s7,56(sp)
ffffffffc0205828:	f06a                	sd	s10,32(sp)
ffffffffc020582a:	fc86                	sd	ra,120(sp)
ffffffffc020582c:	f8a2                	sd	s0,112(sp)
ffffffffc020582e:	f862                	sd	s8,48(sp)
ffffffffc0205830:	f466                	sd	s9,40(sp)
ffffffffc0205832:	ec6e                	sd	s11,24(sp)
ffffffffc0205834:	892a                	mv	s2,a0
ffffffffc0205836:	84ae                	mv	s1,a1
ffffffffc0205838:	8d32                	mv	s10,a2
ffffffffc020583a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020583c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205840:	5b7d                	li	s6,-1
ffffffffc0205842:	00002a97          	auipc	s5,0x2
ffffffffc0205846:	492a8a93          	addi	s5,s5,1170 # ffffffffc0207cd4 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020584a:	00002b97          	auipc	s7,0x2
ffffffffc020584e:	6a6b8b93          	addi	s7,s7,1702 # ffffffffc0207ef0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205852:	000d4503          	lbu	a0,0(s10)
ffffffffc0205856:	001d0413          	addi	s0,s10,1
ffffffffc020585a:	01350a63          	beq	a0,s3,ffffffffc020586e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020585e:	c121                	beqz	a0,ffffffffc020589e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205860:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205862:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205864:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205866:	fff44503          	lbu	a0,-1(s0)
ffffffffc020586a:	ff351ae3          	bne	a0,s3,ffffffffc020585e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020586e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205872:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205876:	4c81                	li	s9,0
ffffffffc0205878:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020587a:	5c7d                	li	s8,-1
ffffffffc020587c:	5dfd                	li	s11,-1
ffffffffc020587e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205882:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205884:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205888:	0ff5f593          	zext.b	a1,a1
ffffffffc020588c:	00140d13          	addi	s10,s0,1
ffffffffc0205890:	04b56263          	bltu	a0,a1,ffffffffc02058d4 <vprintfmt+0xbc>
ffffffffc0205894:	058a                	slli	a1,a1,0x2
ffffffffc0205896:	95d6                	add	a1,a1,s5
ffffffffc0205898:	4194                	lw	a3,0(a1)
ffffffffc020589a:	96d6                	add	a3,a3,s5
ffffffffc020589c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020589e:	70e6                	ld	ra,120(sp)
ffffffffc02058a0:	7446                	ld	s0,112(sp)
ffffffffc02058a2:	74a6                	ld	s1,104(sp)
ffffffffc02058a4:	7906                	ld	s2,96(sp)
ffffffffc02058a6:	69e6                	ld	s3,88(sp)
ffffffffc02058a8:	6a46                	ld	s4,80(sp)
ffffffffc02058aa:	6aa6                	ld	s5,72(sp)
ffffffffc02058ac:	6b06                	ld	s6,64(sp)
ffffffffc02058ae:	7be2                	ld	s7,56(sp)
ffffffffc02058b0:	7c42                	ld	s8,48(sp)
ffffffffc02058b2:	7ca2                	ld	s9,40(sp)
ffffffffc02058b4:	7d02                	ld	s10,32(sp)
ffffffffc02058b6:	6de2                	ld	s11,24(sp)
ffffffffc02058b8:	6109                	addi	sp,sp,128
ffffffffc02058ba:	8082                	ret
            padc = '0';
ffffffffc02058bc:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02058be:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02058c2:	846a                	mv	s0,s10
ffffffffc02058c4:	00140d13          	addi	s10,s0,1
ffffffffc02058c8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02058cc:	0ff5f593          	zext.b	a1,a1
ffffffffc02058d0:	fcb572e3          	bgeu	a0,a1,ffffffffc0205894 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02058d4:	85a6                	mv	a1,s1
ffffffffc02058d6:	02500513          	li	a0,37
ffffffffc02058da:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02058dc:	fff44783          	lbu	a5,-1(s0)
ffffffffc02058e0:	8d22                	mv	s10,s0
ffffffffc02058e2:	f73788e3          	beq	a5,s3,ffffffffc0205852 <vprintfmt+0x3a>
ffffffffc02058e6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02058ea:	1d7d                	addi	s10,s10,-1
ffffffffc02058ec:	ff379de3          	bne	a5,s3,ffffffffc02058e6 <vprintfmt+0xce>
ffffffffc02058f0:	b78d                	j	ffffffffc0205852 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02058f2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02058f6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02058fa:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02058fc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205900:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205904:	02d86463          	bltu	a6,a3,ffffffffc020592c <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205908:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020590c:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205910:	0186873b          	addw	a4,a3,s8
ffffffffc0205914:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205918:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020591a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020591e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205920:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205924:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205928:	fed870e3          	bgeu	a6,a3,ffffffffc0205908 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020592c:	f40ddce3          	bgez	s11,ffffffffc0205884 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205930:	8de2                	mv	s11,s8
ffffffffc0205932:	5c7d                	li	s8,-1
ffffffffc0205934:	bf81                	j	ffffffffc0205884 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205936:	fffdc693          	not	a3,s11
ffffffffc020593a:	96fd                	srai	a3,a3,0x3f
ffffffffc020593c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205940:	00144603          	lbu	a2,1(s0)
ffffffffc0205944:	2d81                	sext.w	s11,s11
ffffffffc0205946:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205948:	bf35                	j	ffffffffc0205884 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020594a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020594e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205952:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205954:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205956:	bfd9                	j	ffffffffc020592c <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205958:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020595a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020595e:	01174463          	blt	a4,a7,ffffffffc0205966 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205962:	1a088e63          	beqz	a7,ffffffffc0205b1e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205966:	000a3603          	ld	a2,0(s4)
ffffffffc020596a:	46c1                	li	a3,16
ffffffffc020596c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020596e:	2781                	sext.w	a5,a5
ffffffffc0205970:	876e                	mv	a4,s11
ffffffffc0205972:	85a6                	mv	a1,s1
ffffffffc0205974:	854a                	mv	a0,s2
ffffffffc0205976:	e37ff0ef          	jal	ra,ffffffffc02057ac <printnum>
            break;
ffffffffc020597a:	bde1                	j	ffffffffc0205852 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020597c:	000a2503          	lw	a0,0(s4)
ffffffffc0205980:	85a6                	mv	a1,s1
ffffffffc0205982:	0a21                	addi	s4,s4,8
ffffffffc0205984:	9902                	jalr	s2
            break;
ffffffffc0205986:	b5f1                	j	ffffffffc0205852 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205988:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020598a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020598e:	01174463          	blt	a4,a7,ffffffffc0205996 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205992:	18088163          	beqz	a7,ffffffffc0205b14 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205996:	000a3603          	ld	a2,0(s4)
ffffffffc020599a:	46a9                	li	a3,10
ffffffffc020599c:	8a2e                	mv	s4,a1
ffffffffc020599e:	bfc1                	j	ffffffffc020596e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059a0:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02059a4:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059a6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02059a8:	bdf1                	j	ffffffffc0205884 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02059aa:	85a6                	mv	a1,s1
ffffffffc02059ac:	02500513          	li	a0,37
ffffffffc02059b0:	9902                	jalr	s2
            break;
ffffffffc02059b2:	b545                	j	ffffffffc0205852 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059b4:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02059b8:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059ba:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02059bc:	b5e1                	j	ffffffffc0205884 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02059be:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02059c0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02059c4:	01174463          	blt	a4,a7,ffffffffc02059cc <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02059c8:	14088163          	beqz	a7,ffffffffc0205b0a <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02059cc:	000a3603          	ld	a2,0(s4)
ffffffffc02059d0:	46a1                	li	a3,8
ffffffffc02059d2:	8a2e                	mv	s4,a1
ffffffffc02059d4:	bf69                	j	ffffffffc020596e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02059d6:	03000513          	li	a0,48
ffffffffc02059da:	85a6                	mv	a1,s1
ffffffffc02059dc:	e03e                	sd	a5,0(sp)
ffffffffc02059de:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02059e0:	85a6                	mv	a1,s1
ffffffffc02059e2:	07800513          	li	a0,120
ffffffffc02059e6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02059e8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02059ea:	6782                	ld	a5,0(sp)
ffffffffc02059ec:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02059ee:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02059f2:	bfb5                	j	ffffffffc020596e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02059f4:	000a3403          	ld	s0,0(s4)
ffffffffc02059f8:	008a0713          	addi	a4,s4,8
ffffffffc02059fc:	e03a                	sd	a4,0(sp)
ffffffffc02059fe:	14040263          	beqz	s0,ffffffffc0205b42 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205a02:	0fb05763          	blez	s11,ffffffffc0205af0 <vprintfmt+0x2d8>
ffffffffc0205a06:	02d00693          	li	a3,45
ffffffffc0205a0a:	0cd79163          	bne	a5,a3,ffffffffc0205acc <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a0e:	00044783          	lbu	a5,0(s0)
ffffffffc0205a12:	0007851b          	sext.w	a0,a5
ffffffffc0205a16:	cf85                	beqz	a5,ffffffffc0205a4e <vprintfmt+0x236>
ffffffffc0205a18:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205a1c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a20:	000c4563          	bltz	s8,ffffffffc0205a2a <vprintfmt+0x212>
ffffffffc0205a24:	3c7d                	addiw	s8,s8,-1
ffffffffc0205a26:	036c0263          	beq	s8,s6,ffffffffc0205a4a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205a2a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205a2c:	0e0c8e63          	beqz	s9,ffffffffc0205b28 <vprintfmt+0x310>
ffffffffc0205a30:	3781                	addiw	a5,a5,-32
ffffffffc0205a32:	0ef47b63          	bgeu	s0,a5,ffffffffc0205b28 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205a36:	03f00513          	li	a0,63
ffffffffc0205a3a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a3c:	000a4783          	lbu	a5,0(s4)
ffffffffc0205a40:	3dfd                	addiw	s11,s11,-1
ffffffffc0205a42:	0a05                	addi	s4,s4,1
ffffffffc0205a44:	0007851b          	sext.w	a0,a5
ffffffffc0205a48:	ffe1                	bnez	a5,ffffffffc0205a20 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205a4a:	01b05963          	blez	s11,ffffffffc0205a5c <vprintfmt+0x244>
ffffffffc0205a4e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205a50:	85a6                	mv	a1,s1
ffffffffc0205a52:	02000513          	li	a0,32
ffffffffc0205a56:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205a58:	fe0d9be3          	bnez	s11,ffffffffc0205a4e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205a5c:	6a02                	ld	s4,0(sp)
ffffffffc0205a5e:	bbd5                	j	ffffffffc0205852 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205a60:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205a62:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205a66:	01174463          	blt	a4,a7,ffffffffc0205a6e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205a6a:	08088d63          	beqz	a7,ffffffffc0205b04 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205a6e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205a72:	0a044d63          	bltz	s0,ffffffffc0205b2c <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205a76:	8622                	mv	a2,s0
ffffffffc0205a78:	8a66                	mv	s4,s9
ffffffffc0205a7a:	46a9                	li	a3,10
ffffffffc0205a7c:	bdcd                	j	ffffffffc020596e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205a7e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205a82:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205a84:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205a86:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205a8a:	8fb5                	xor	a5,a5,a3
ffffffffc0205a8c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205a90:	02d74163          	blt	a4,a3,ffffffffc0205ab2 <vprintfmt+0x29a>
ffffffffc0205a94:	00369793          	slli	a5,a3,0x3
ffffffffc0205a98:	97de                	add	a5,a5,s7
ffffffffc0205a9a:	639c                	ld	a5,0(a5)
ffffffffc0205a9c:	cb99                	beqz	a5,ffffffffc0205ab2 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205a9e:	86be                	mv	a3,a5
ffffffffc0205aa0:	00000617          	auipc	a2,0x0
ffffffffc0205aa4:	1f060613          	addi	a2,a2,496 # ffffffffc0205c90 <etext+0x2a>
ffffffffc0205aa8:	85a6                	mv	a1,s1
ffffffffc0205aaa:	854a                	mv	a0,s2
ffffffffc0205aac:	0ce000ef          	jal	ra,ffffffffc0205b7a <printfmt>
ffffffffc0205ab0:	b34d                	j	ffffffffc0205852 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205ab2:	00002617          	auipc	a2,0x2
ffffffffc0205ab6:	21660613          	addi	a2,a2,534 # ffffffffc0207cc8 <syscalls+0x120>
ffffffffc0205aba:	85a6                	mv	a1,s1
ffffffffc0205abc:	854a                	mv	a0,s2
ffffffffc0205abe:	0bc000ef          	jal	ra,ffffffffc0205b7a <printfmt>
ffffffffc0205ac2:	bb41                	j	ffffffffc0205852 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205ac4:	00002417          	auipc	s0,0x2
ffffffffc0205ac8:	1fc40413          	addi	s0,s0,508 # ffffffffc0207cc0 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205acc:	85e2                	mv	a1,s8
ffffffffc0205ace:	8522                	mv	a0,s0
ffffffffc0205ad0:	e43e                	sd	a5,8(sp)
ffffffffc0205ad2:	0e2000ef          	jal	ra,ffffffffc0205bb4 <strnlen>
ffffffffc0205ad6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205ada:	01b05b63          	blez	s11,ffffffffc0205af0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205ade:	67a2                	ld	a5,8(sp)
ffffffffc0205ae0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205ae4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205ae6:	85a6                	mv	a1,s1
ffffffffc0205ae8:	8552                	mv	a0,s4
ffffffffc0205aea:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205aec:	fe0d9ce3          	bnez	s11,ffffffffc0205ae4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205af0:	00044783          	lbu	a5,0(s0)
ffffffffc0205af4:	00140a13          	addi	s4,s0,1
ffffffffc0205af8:	0007851b          	sext.w	a0,a5
ffffffffc0205afc:	d3a5                	beqz	a5,ffffffffc0205a5c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205afe:	05e00413          	li	s0,94
ffffffffc0205b02:	bf39                	j	ffffffffc0205a20 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205b04:	000a2403          	lw	s0,0(s4)
ffffffffc0205b08:	b7ad                	j	ffffffffc0205a72 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205b0a:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b0e:	46a1                	li	a3,8
ffffffffc0205b10:	8a2e                	mv	s4,a1
ffffffffc0205b12:	bdb1                	j	ffffffffc020596e <vprintfmt+0x156>
ffffffffc0205b14:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b18:	46a9                	li	a3,10
ffffffffc0205b1a:	8a2e                	mv	s4,a1
ffffffffc0205b1c:	bd89                	j	ffffffffc020596e <vprintfmt+0x156>
ffffffffc0205b1e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b22:	46c1                	li	a3,16
ffffffffc0205b24:	8a2e                	mv	s4,a1
ffffffffc0205b26:	b5a1                	j	ffffffffc020596e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205b28:	9902                	jalr	s2
ffffffffc0205b2a:	bf09                	j	ffffffffc0205a3c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205b2c:	85a6                	mv	a1,s1
ffffffffc0205b2e:	02d00513          	li	a0,45
ffffffffc0205b32:	e03e                	sd	a5,0(sp)
ffffffffc0205b34:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205b36:	6782                	ld	a5,0(sp)
ffffffffc0205b38:	8a66                	mv	s4,s9
ffffffffc0205b3a:	40800633          	neg	a2,s0
ffffffffc0205b3e:	46a9                	li	a3,10
ffffffffc0205b40:	b53d                	j	ffffffffc020596e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205b42:	03b05163          	blez	s11,ffffffffc0205b64 <vprintfmt+0x34c>
ffffffffc0205b46:	02d00693          	li	a3,45
ffffffffc0205b4a:	f6d79de3          	bne	a5,a3,ffffffffc0205ac4 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205b4e:	00002417          	auipc	s0,0x2
ffffffffc0205b52:	17240413          	addi	s0,s0,370 # ffffffffc0207cc0 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b56:	02800793          	li	a5,40
ffffffffc0205b5a:	02800513          	li	a0,40
ffffffffc0205b5e:	00140a13          	addi	s4,s0,1
ffffffffc0205b62:	bd6d                	j	ffffffffc0205a1c <vprintfmt+0x204>
ffffffffc0205b64:	00002a17          	auipc	s4,0x2
ffffffffc0205b68:	15da0a13          	addi	s4,s4,349 # ffffffffc0207cc1 <syscalls+0x119>
ffffffffc0205b6c:	02800513          	li	a0,40
ffffffffc0205b70:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205b74:	05e00413          	li	s0,94
ffffffffc0205b78:	b565                	j	ffffffffc0205a20 <vprintfmt+0x208>

ffffffffc0205b7a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205b7a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205b7c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205b80:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205b82:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205b84:	ec06                	sd	ra,24(sp)
ffffffffc0205b86:	f83a                	sd	a4,48(sp)
ffffffffc0205b88:	fc3e                	sd	a5,56(sp)
ffffffffc0205b8a:	e0c2                	sd	a6,64(sp)
ffffffffc0205b8c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205b8e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205b90:	c89ff0ef          	jal	ra,ffffffffc0205818 <vprintfmt>
}
ffffffffc0205b94:	60e2                	ld	ra,24(sp)
ffffffffc0205b96:	6161                	addi	sp,sp,80
ffffffffc0205b98:	8082                	ret

ffffffffc0205b9a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205b9a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205b9e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205ba0:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205ba2:	cb81                	beqz	a5,ffffffffc0205bb2 <strlen+0x18>
        cnt ++;
ffffffffc0205ba4:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205ba6:	00a707b3          	add	a5,a4,a0
ffffffffc0205baa:	0007c783          	lbu	a5,0(a5)
ffffffffc0205bae:	fbfd                	bnez	a5,ffffffffc0205ba4 <strlen+0xa>
ffffffffc0205bb0:	8082                	ret
    }
    return cnt;
}
ffffffffc0205bb2:	8082                	ret

ffffffffc0205bb4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205bb4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205bb6:	e589                	bnez	a1,ffffffffc0205bc0 <strnlen+0xc>
ffffffffc0205bb8:	a811                	j	ffffffffc0205bcc <strnlen+0x18>
        cnt ++;
ffffffffc0205bba:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205bbc:	00f58863          	beq	a1,a5,ffffffffc0205bcc <strnlen+0x18>
ffffffffc0205bc0:	00f50733          	add	a4,a0,a5
ffffffffc0205bc4:	00074703          	lbu	a4,0(a4)
ffffffffc0205bc8:	fb6d                	bnez	a4,ffffffffc0205bba <strnlen+0x6>
ffffffffc0205bca:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205bcc:	852e                	mv	a0,a1
ffffffffc0205bce:	8082                	ret

ffffffffc0205bd0 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205bd0:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205bd2:	0005c703          	lbu	a4,0(a1)
ffffffffc0205bd6:	0785                	addi	a5,a5,1
ffffffffc0205bd8:	0585                	addi	a1,a1,1
ffffffffc0205bda:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205bde:	fb75                	bnez	a4,ffffffffc0205bd2 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205be0:	8082                	ret

ffffffffc0205be2 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205be2:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205be6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205bea:	cb89                	beqz	a5,ffffffffc0205bfc <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205bec:	0505                	addi	a0,a0,1
ffffffffc0205bee:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205bf0:	fee789e3          	beq	a5,a4,ffffffffc0205be2 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205bf4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205bf8:	9d19                	subw	a0,a0,a4
ffffffffc0205bfa:	8082                	ret
ffffffffc0205bfc:	4501                	li	a0,0
ffffffffc0205bfe:	bfed                	j	ffffffffc0205bf8 <strcmp+0x16>

ffffffffc0205c00 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c00:	c20d                	beqz	a2,ffffffffc0205c22 <strncmp+0x22>
ffffffffc0205c02:	962e                	add	a2,a2,a1
ffffffffc0205c04:	a031                	j	ffffffffc0205c10 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205c06:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c08:	00e79a63          	bne	a5,a4,ffffffffc0205c1c <strncmp+0x1c>
ffffffffc0205c0c:	00b60b63          	beq	a2,a1,ffffffffc0205c22 <strncmp+0x22>
ffffffffc0205c10:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205c14:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c16:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205c1a:	f7f5                	bnez	a5,ffffffffc0205c06 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c1c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205c20:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c22:	4501                	li	a0,0
ffffffffc0205c24:	8082                	ret

ffffffffc0205c26 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205c26:	00054783          	lbu	a5,0(a0)
ffffffffc0205c2a:	c799                	beqz	a5,ffffffffc0205c38 <strchr+0x12>
        if (*s == c) {
ffffffffc0205c2c:	00f58763          	beq	a1,a5,ffffffffc0205c3a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205c30:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205c34:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205c36:	fbfd                	bnez	a5,ffffffffc0205c2c <strchr+0x6>
    }
    return NULL;
ffffffffc0205c38:	4501                	li	a0,0
}
ffffffffc0205c3a:	8082                	ret

ffffffffc0205c3c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205c3c:	ca01                	beqz	a2,ffffffffc0205c4c <memset+0x10>
ffffffffc0205c3e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205c40:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205c42:	0785                	addi	a5,a5,1
ffffffffc0205c44:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205c48:	fec79de3          	bne	a5,a2,ffffffffc0205c42 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205c4c:	8082                	ret

ffffffffc0205c4e <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205c4e:	ca19                	beqz	a2,ffffffffc0205c64 <memcpy+0x16>
ffffffffc0205c50:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205c52:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205c54:	0005c703          	lbu	a4,0(a1)
ffffffffc0205c58:	0585                	addi	a1,a1,1
ffffffffc0205c5a:	0785                	addi	a5,a5,1
ffffffffc0205c5c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205c60:	fec59ae3          	bne	a1,a2,ffffffffc0205c54 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205c64:	8082                	ret
