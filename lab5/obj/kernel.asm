
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

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
ffffffffc020004a:	000b2517          	auipc	a0,0xb2
ffffffffc020004e:	c7650513          	addi	a0,a0,-906 # ffffffffc02b1cc0 <buf>
ffffffffc0200052:	000b6617          	auipc	a2,0xb6
ffffffffc0200056:	12260613          	addi	a2,a2,290 # ffffffffc02b6174 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	6df050ef          	jal	ra,ffffffffc0205f40 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	f0258593          	addi	a1,a1,-254 # ffffffffc0205f70 <etext+0x6>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	f1a50513          	addi	a0,a0,-230 # ffffffffc0205f90 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0cd020ef          	jal	ra,ffffffffc0202952 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	6cd030ef          	jal	ra,ffffffffc0203f5e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	5fc050ef          	jal	ra,ffffffffc0205692 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	788050ef          	jal	ra,ffffffffc020582a <cpu_idle>

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
ffffffffc02000c0:	edc50513          	addi	a0,a0,-292 # ffffffffc0205f98 <etext+0x2e>
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
ffffffffc02000d2:	000b2b97          	auipc	s7,0xb2
ffffffffc02000d6:	beeb8b93          	addi	s7,s7,-1042 # ffffffffc02b1cc0 <buf>
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
ffffffffc020012e:	000b2517          	auipc	a0,0xb2
ffffffffc0200132:	b9250513          	addi	a0,a0,-1134 # ffffffffc02b1cc0 <buf>
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
ffffffffc0200188:	195050ef          	jal	ra,ffffffffc0205b1c <vprintfmt>
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
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
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
ffffffffc02001be:	15f050ef          	jal	ra,ffffffffc0205b1c <vprintfmt>
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
ffffffffc0200222:	d8250513          	addi	a0,a0,-638 # ffffffffc0205fa0 <etext+0x36>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	d8c50513          	addi	a0,a0,-628 # ffffffffc0205fc0 <etext+0x56>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00006597          	auipc	a1,0x6
ffffffffc0200244:	d2a58593          	addi	a1,a1,-726 # ffffffffc0205f6a <etext>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	d9850513          	addi	a0,a0,-616 # ffffffffc0205fe0 <etext+0x76>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000b2597          	auipc	a1,0xb2
ffffffffc0200258:	a6c58593          	addi	a1,a1,-1428 # ffffffffc02b1cc0 <buf>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	da450513          	addi	a0,a0,-604 # ffffffffc0206000 <etext+0x96>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000b6597          	auipc	a1,0xb6
ffffffffc020026c:	f0c58593          	addi	a1,a1,-244 # ffffffffc02b6174 <end>
ffffffffc0200270:	00006517          	auipc	a0,0x6
ffffffffc0200274:	db050513          	addi	a0,a0,-592 # ffffffffc0206020 <etext+0xb6>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000b6597          	auipc	a1,0xb6
ffffffffc0200280:	2f758593          	addi	a1,a1,759 # ffffffffc02b6573 <end+0x3ff>
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
ffffffffc02002a2:	da250513          	addi	a0,a0,-606 # ffffffffc0206040 <etext+0xd6>
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
ffffffffc02002b0:	dc460613          	addi	a2,a2,-572 # ffffffffc0206070 <etext+0x106>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00006517          	auipc	a0,0x6
ffffffffc02002bc:	dd050513          	addi	a0,a0,-560 # ffffffffc0206088 <etext+0x11e>
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
ffffffffc02002cc:	dd860613          	addi	a2,a2,-552 # ffffffffc02060a0 <etext+0x136>
ffffffffc02002d0:	00006597          	auipc	a1,0x6
ffffffffc02002d4:	df058593          	addi	a1,a1,-528 # ffffffffc02060c0 <etext+0x156>
ffffffffc02002d8:	00006517          	auipc	a0,0x6
ffffffffc02002dc:	df050513          	addi	a0,a0,-528 # ffffffffc02060c8 <etext+0x15e>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00006617          	auipc	a2,0x6
ffffffffc02002ea:	df260613          	addi	a2,a2,-526 # ffffffffc02060d8 <etext+0x16e>
ffffffffc02002ee:	00006597          	auipc	a1,0x6
ffffffffc02002f2:	e1258593          	addi	a1,a1,-494 # ffffffffc0206100 <etext+0x196>
ffffffffc02002f6:	00006517          	auipc	a0,0x6
ffffffffc02002fa:	dd250513          	addi	a0,a0,-558 # ffffffffc02060c8 <etext+0x15e>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00006617          	auipc	a2,0x6
ffffffffc0200306:	e0e60613          	addi	a2,a2,-498 # ffffffffc0206110 <etext+0x1a6>
ffffffffc020030a:	00006597          	auipc	a1,0x6
ffffffffc020030e:	e2658593          	addi	a1,a1,-474 # ffffffffc0206130 <etext+0x1c6>
ffffffffc0200312:	00006517          	auipc	a0,0x6
ffffffffc0200316:	db650513          	addi	a0,a0,-586 # ffffffffc02060c8 <etext+0x15e>
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
ffffffffc0200350:	df450513          	addi	a0,a0,-524 # ffffffffc0206140 <etext+0x1d6>
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
ffffffffc0200372:	dfa50513          	addi	a0,a0,-518 # ffffffffc0206168 <etext+0x1fe>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00006c17          	auipc	s8,0x6
ffffffffc0200388:	e54c0c13          	addi	s8,s8,-428 # ffffffffc02061d8 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00006917          	auipc	s2,0x6
ffffffffc0200390:	e0490913          	addi	s2,s2,-508 # ffffffffc0206190 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00006497          	auipc	s1,0x6
ffffffffc0200398:	e0448493          	addi	s1,s1,-508 # ffffffffc0206198 <etext+0x22e>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00006b17          	auipc	s6,0x6
ffffffffc02003a2:	e02b0b13          	addi	s6,s6,-510 # ffffffffc02061a0 <etext+0x236>
        argv[argc++] = buf;
ffffffffc02003a6:	00006a17          	auipc	s4,0x6
ffffffffc02003aa:	d1aa0a13          	addi	s4,s4,-742 # ffffffffc02060c0 <etext+0x156>
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
ffffffffc02003cc:	e10d0d13          	addi	s10,s10,-496 # ffffffffc02061d8 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	311050ef          	jal	ra,ffffffffc0205ee6 <strcmp>
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
ffffffffc02003ea:	2fd050ef          	jal	ra,ffffffffc0205ee6 <strcmp>
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
ffffffffc0200428:	303050ef          	jal	ra,ffffffffc0205f2a <strchr>
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
ffffffffc0200466:	2c5050ef          	jal	ra,ffffffffc0205f2a <strchr>
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
ffffffffc0200484:	d4050513          	addi	a0,a0,-704 # ffffffffc02061c0 <etext+0x256>
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
ffffffffc020048e:	000b6317          	auipc	t1,0xb6
ffffffffc0200492:	c5a30313          	addi	t1,t1,-934 # ffffffffc02b60e8 <is_panic>
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
ffffffffc02004c0:	d6450513          	addi	a0,a0,-668 # ffffffffc0206220 <commands+0x48>
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
ffffffffc02004d6:	e9650513          	addi	a0,a0,-362 # ffffffffc0207368 <default_pmm_manager+0x578>
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
ffffffffc020050a:	d3a50513          	addi	a0,a0,-710 # ffffffffc0206240 <commands+0x68>
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
ffffffffc020052a:	e4250513          	addi	a0,a0,-446 # ffffffffc0207368 <default_pmm_manager+0x578>
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
ffffffffc0200540:	000b6717          	auipc	a4,0xb6
ffffffffc0200544:	baf73c23          	sd	a5,-1096(a4) # ffffffffc02b60f8 <timebase>
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
ffffffffc0200564:	d0050513          	addi	a0,a0,-768 # ffffffffc0206260 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000b6797          	auipc	a5,0xb6
ffffffffc020056c:	b807b423          	sd	zero,-1144(a5) # ffffffffc02b60f0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000b6797          	auipc	a5,0xb6
ffffffffc020057a:	b827b783          	ld	a5,-1150(a5) # ffffffffc02b60f8 <timebase>
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
ffffffffc0200604:	c8050513          	addi	a0,a0,-896 # ffffffffc0206280 <commands+0xa8>
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
ffffffffc0200626:	0000c597          	auipc	a1,0xc
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc020062e:	00006517          	auipc	a0,0x6
ffffffffc0200632:	c6250513          	addi	a0,a0,-926 # ffffffffc0206290 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000c417          	auipc	s0,0xc
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020c008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00006517          	auipc	a0,0x6
ffffffffc0200648:	c5c50513          	addi	a0,a0,-932 # ffffffffc02062a0 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00006517          	auipc	a0,0x6
ffffffffc0200658:	c6450513          	addi	a0,a0,-924 # ffffffffc02062b8 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe29d79>
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
ffffffffc0200712:	bfa90913          	addi	s2,s2,-1030 # ffffffffc0206308 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00006497          	auipc	s1,0x6
ffffffffc0200720:	be448493          	addi	s1,s1,-1052 # ffffffffc0206300 <commands+0x128>
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
ffffffffc0200774:	c1050513          	addi	a0,a0,-1008 # ffffffffc0206380 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	c3c50513          	addi	a0,a0,-964 # ffffffffc02063b8 <commands+0x1e0>
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
ffffffffc02007c0:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02062d8 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	6d4050ef          	jal	ra,ffffffffc0205e9e <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	72c050ef          	jal	ra,ffffffffc0205f04 <strncmp>
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
ffffffffc020086e:	678050ef          	jal	ra,ffffffffc0205ee6 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00006517          	auipc	a0,0x6
ffffffffc0200886:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0206310 <commands+0x138>
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
ffffffffc0200950:	00006517          	auipc	a0,0x6
ffffffffc0200954:	9e050513          	addi	a0,a0,-1568 # ffffffffc0206330 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00006517          	auipc	a0,0x6
ffffffffc0200966:	9e650513          	addi	a0,a0,-1562 # ffffffffc0206348 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00006517          	auipc	a0,0x6
ffffffffc0200978:	9f450513          	addi	a0,a0,-1548 # ffffffffc0206368 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00006517          	auipc	a0,0x6
ffffffffc0200984:	a3850513          	addi	a0,a0,-1480 # ffffffffc02063b8 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000b5797          	auipc	a5,0xb5
ffffffffc020098c:	7687bc23          	sd	s0,1912(a5) # ffffffffc02b6100 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000b5797          	auipc	a5,0xb5
ffffffffc0200994:	7767bc23          	sd	s6,1912(a5) # ffffffffc02b6108 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000b5517          	auipc	a0,0xb5
ffffffffc020099e:	76653503          	ld	a0,1894(a0) # ffffffffc02b6100 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000b5517          	auipc	a0,0xb5
ffffffffc02009a8:	76453503          	ld	a0,1892(a0) # ffffffffc02b6108 <memory_size>
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
ffffffffc02009c4:	5e478793          	addi	a5,a5,1508 # ffffffffc0200fa4 <__alltraps>
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
ffffffffc02009de:	00006517          	auipc	a0,0x6
ffffffffc02009e2:	9f250513          	addi	a0,a0,-1550 # ffffffffc02063d0 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02063e8 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00006517          	auipc	a0,0x6
ffffffffc0200a00:	a0450513          	addi	a0,a0,-1532 # ffffffffc0206400 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00006517          	auipc	a0,0x6
ffffffffc0200a0e:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0206418 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00006517          	auipc	a0,0x6
ffffffffc0200a1c:	a1850513          	addi	a0,a0,-1512 # ffffffffc0206430 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00006517          	auipc	a0,0x6
ffffffffc0200a2a:	a2250513          	addi	a0,a0,-1502 # ffffffffc0206448 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00006517          	auipc	a0,0x6
ffffffffc0200a38:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0206460 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00006517          	auipc	a0,0x6
ffffffffc0200a46:	a3650513          	addi	a0,a0,-1482 # ffffffffc0206478 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00006517          	auipc	a0,0x6
ffffffffc0200a54:	a4050513          	addi	a0,a0,-1472 # ffffffffc0206490 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00006517          	auipc	a0,0x6
ffffffffc0200a62:	a4a50513          	addi	a0,a0,-1462 # ffffffffc02064a8 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00006517          	auipc	a0,0x6
ffffffffc0200a70:	a5450513          	addi	a0,a0,-1452 # ffffffffc02064c0 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00006517          	auipc	a0,0x6
ffffffffc0200a7e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02064d8 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00006517          	auipc	a0,0x6
ffffffffc0200a8c:	a6850513          	addi	a0,a0,-1432 # ffffffffc02064f0 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00006517          	auipc	a0,0x6
ffffffffc0200a9a:	a7250513          	addi	a0,a0,-1422 # ffffffffc0206508 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00006517          	auipc	a0,0x6
ffffffffc0200aa8:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0206520 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	a8650513          	addi	a0,a0,-1402 # ffffffffc0206538 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00006517          	auipc	a0,0x6
ffffffffc0200ac4:	a9050513          	addi	a0,a0,-1392 # ffffffffc0206550 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00006517          	auipc	a0,0x6
ffffffffc0200ad2:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0206568 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00006517          	auipc	a0,0x6
ffffffffc0200ae0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0206580 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00006517          	auipc	a0,0x6
ffffffffc0200aee:	aae50513          	addi	a0,a0,-1362 # ffffffffc0206598 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00006517          	auipc	a0,0x6
ffffffffc0200afc:	ab850513          	addi	a0,a0,-1352 # ffffffffc02065b0 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00006517          	auipc	a0,0x6
ffffffffc0200b0a:	ac250513          	addi	a0,a0,-1342 # ffffffffc02065c8 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00006517          	auipc	a0,0x6
ffffffffc0200b18:	acc50513          	addi	a0,a0,-1332 # ffffffffc02065e0 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00006517          	auipc	a0,0x6
ffffffffc0200b26:	ad650513          	addi	a0,a0,-1322 # ffffffffc02065f8 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00006517          	auipc	a0,0x6
ffffffffc0200b34:	ae050513          	addi	a0,a0,-1312 # ffffffffc0206610 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00006517          	auipc	a0,0x6
ffffffffc0200b42:	aea50513          	addi	a0,a0,-1302 # ffffffffc0206628 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00006517          	auipc	a0,0x6
ffffffffc0200b50:	af450513          	addi	a0,a0,-1292 # ffffffffc0206640 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00006517          	auipc	a0,0x6
ffffffffc0200b5e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0206658 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00006517          	auipc	a0,0x6
ffffffffc0200b6c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206670 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00006517          	auipc	a0,0x6
ffffffffc0200b7a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0206688 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00006517          	auipc	a0,0x6
ffffffffc0200b88:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02066a0 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00006517          	auipc	a0,0x6
ffffffffc0200b9a:	b2250513          	addi	a0,a0,-1246 # ffffffffc02066b8 <commands+0x4e0>
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
ffffffffc0200bb0:	b2450513          	addi	a0,a0,-1244 # ffffffffc02066d0 <commands+0x4f8>
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
ffffffffc0200bc8:	b2450513          	addi	a0,a0,-1244 # ffffffffc02066e8 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00006517          	auipc	a0,0x6
ffffffffc0200bd8:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0206700 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00006517          	auipc	a0,0x6
ffffffffc0200be8:	b3450513          	addi	a0,a0,-1228 # ffffffffc0206718 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00006517          	auipc	a0,0x6
ffffffffc0200bfc:	b3050513          	addi	a0,a0,-1232 # ffffffffc0206728 <commands+0x550>
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
ffffffffc0200c14:	00006717          	auipc	a4,0x6
ffffffffc0200c18:	bdc70713          	addi	a4,a4,-1060 # ffffffffc02067f0 <commands+0x618>
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
ffffffffc0200c2a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc02067a0 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00006517          	auipc	a0,0x6
ffffffffc0200c36:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0206780 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00006517          	auipc	a0,0x6
ffffffffc0200c42:	b0250513          	addi	a0,a0,-1278 # ffffffffc0206740 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00006517          	auipc	a0,0x6
ffffffffc0200c4e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0206760 <commands+0x588>
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
ffffffffc0200c5e:	000b5697          	auipc	a3,0xb5
ffffffffc0200c62:	49268693          	addi	a3,a3,1170 # ffffffffc02b60f0 <ticks>
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
ffffffffc0200c7c:	00006517          	auipc	a0,0x6
ffffffffc0200c80:	b5450513          	addi	a0,a0,-1196 # ffffffffc02067d0 <commands+0x5f8>
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c88:	bf31                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c8a:	06400593          	li	a1,100
ffffffffc0200c8e:	00006517          	auipc	a0,0x6
ffffffffc0200c92:	b3250513          	addi	a0,a0,-1230 # ffffffffc02067c0 <commands+0x5e8>
ffffffffc0200c96:	cfeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_count++;
ffffffffc0200c9a:	000b5717          	auipc	a4,0xb5
ffffffffc0200c9e:	47670713          	addi	a4,a4,1142 # ffffffffc02b6110 <print_count.0>
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
ffffffffc0200cbc:	000b5797          	auipc	a5,0xb5
ffffffffc0200cc0:	49c7b783          	ld	a5,1180(a5) # ffffffffc02b6158 <current>
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
ffffffffc0200cda:	18f76c63          	bltu	a4,a5,ffffffffc0200e72 <exception_handler+0x1a6>
ffffffffc0200cde:	00006717          	auipc	a4,0x6
ffffffffc0200ce2:	d1270713          	addi	a4,a4,-750 # ffffffffc02069f0 <commands+0x818>
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
ffffffffc0200cf4:	c1850513          	addi	a0,a0,-1000 # ffffffffc0206908 <commands+0x730>
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
ffffffffc0200d0c:	50f0406f          	j	ffffffffc0205a1a <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d10:	00006517          	auipc	a0,0x6
ffffffffc0200d14:	c1850513          	addi	a0,a0,-1000 # ffffffffc0206928 <commands+0x750>
}
ffffffffc0200d18:	6402                	ld	s0,0(sp)
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d1e:	c76ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d22:	00006517          	auipc	a0,0x6
ffffffffc0200d26:	c2650513          	addi	a0,a0,-986 # ffffffffc0206948 <commands+0x770>
ffffffffc0200d2a:	b7fd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d2c:	00006517          	auipc	a0,0x6
ffffffffc0200d30:	c3c50513          	addi	a0,a0,-964 # ffffffffc0206968 <commands+0x790>
ffffffffc0200d34:	c60ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (USER_ACCESS(tf->tval, tf->tval + 1)) {
ffffffffc0200d38:	11043603          	ld	a2,272(s0)
ffffffffc0200d3c:	ffe007b7          	lui	a5,0xffe00
ffffffffc0200d40:	7fe00737          	lui	a4,0x7fe00
ffffffffc0200d44:	97b2                	add	a5,a5,a2
ffffffffc0200d46:	16e7fa63          	bgeu	a5,a4,ffffffffc0200eba <exception_handler+0x1ee>
            if ((ret = do_pgfault(current->mm, 0, tf->tval)) != 0) {
ffffffffc0200d4a:	000b5797          	auipc	a5,0xb5
ffffffffc0200d4e:	40e7b783          	ld	a5,1038(a5) # ffffffffc02b6158 <current>
ffffffffc0200d52:	7788                	ld	a0,40(a5)
ffffffffc0200d54:	4581                	li	a1,0
ffffffffc0200d56:	4e1020ef          	jal	ra,ffffffffc0203a36 <do_pgfault>
ffffffffc0200d5a:	0e050963          	beqz	a0,ffffffffc0200e4c <exception_handler+0x180>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d5e:	10043783          	ld	a5,256(s0)
ffffffffc0200d62:	1007f793          	andi	a5,a5,256
                if (trap_in_kernel(tf)) {
ffffffffc0200d66:	c7c5                	beqz	a5,ffffffffc0200e0e <exception_handler+0x142>
                    panic("kernel page fault on user address");
ffffffffc0200d68:	00006617          	auipc	a2,0x6
ffffffffc0200d6c:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206980 <commands+0x7a8>
ffffffffc0200d70:	0e700593          	li	a1,231
ffffffffc0200d74:	00006517          	auipc	a0,0x6
ffffffffc0200d78:	b6450513          	addi	a0,a0,-1180 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200d7c:	f12ff0ef          	jal	ra,ffffffffc020048e <__panic>
        cprintf("Load page fault\n");
ffffffffc0200d80:	00006517          	auipc	a0,0x6
ffffffffc0200d84:	c4050513          	addi	a0,a0,-960 # ffffffffc02069c0 <commands+0x7e8>
ffffffffc0200d88:	c0cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (USER_ACCESS(tf->tval, tf->tval + 1)) {
ffffffffc0200d8c:	11043603          	ld	a2,272(s0)
ffffffffc0200d90:	ffe007b7          	lui	a5,0xffe00
ffffffffc0200d94:	7fe00737          	lui	a4,0x7fe00
ffffffffc0200d98:	97b2                	add	a5,a5,a2
ffffffffc0200d9a:	14e7f863          	bgeu	a5,a4,ffffffffc0200eea <exception_handler+0x21e>
            if ((ret = do_pgfault(current->mm, 0, tf->tval)) != 0) {
ffffffffc0200d9e:	000b5797          	auipc	a5,0xb5
ffffffffc0200da2:	3ba7b783          	ld	a5,954(a5) # ffffffffc02b6158 <current>
ffffffffc0200da6:	7788                	ld	a0,40(a5)
ffffffffc0200da8:	4581                	li	a1,0
ffffffffc0200daa:	48d020ef          	jal	ra,ffffffffc0203a36 <do_pgfault>
ffffffffc0200dae:	cd59                	beqz	a0,ffffffffc0200e4c <exception_handler+0x180>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200db0:	10043783          	ld	a5,256(s0)
ffffffffc0200db4:	1007f793          	andi	a5,a5,256
                if (trap_in_kernel(tf)) {
ffffffffc0200db8:	cbb9                	beqz	a5,ffffffffc0200e0e <exception_handler+0x142>
                    panic("kernel page fault on user address");
ffffffffc0200dba:	00006617          	auipc	a2,0x6
ffffffffc0200dbe:	bc660613          	addi	a2,a2,-1082 # ffffffffc0206980 <commands+0x7a8>
ffffffffc0200dc2:	0f500593          	li	a1,245
ffffffffc0200dc6:	00006517          	auipc	a0,0x6
ffffffffc0200dca:	b1250513          	addi	a0,a0,-1262 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200dce:	ec0ff0ef          	jal	ra,ffffffffc020048e <__panic>
        cprintf("Store/AMO page fault\n");
ffffffffc0200dd2:	00006517          	auipc	a0,0x6
ffffffffc0200dd6:	c0650513          	addi	a0,a0,-1018 # ffffffffc02069d8 <commands+0x800>
ffffffffc0200dda:	bbaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (USER_ACCESS(tf->tval, tf->tval + 1)) {
ffffffffc0200dde:	11043603          	ld	a2,272(s0)
ffffffffc0200de2:	ffe007b7          	lui	a5,0xffe00
ffffffffc0200de6:	7fe00737          	lui	a4,0x7fe00
ffffffffc0200dea:	97b2                	add	a5,a5,a2
ffffffffc0200dec:	0ee7f363          	bgeu	a5,a4,ffffffffc0200ed2 <exception_handler+0x206>
            if ((ret = do_pgfault(current->mm, 1, tf->tval)) != 0) {
ffffffffc0200df0:	000b5797          	auipc	a5,0xb5
ffffffffc0200df4:	3687b783          	ld	a5,872(a5) # ffffffffc02b6158 <current>
ffffffffc0200df8:	7788                	ld	a0,40(a5)
ffffffffc0200dfa:	4585                	li	a1,1
ffffffffc0200dfc:	43b020ef          	jal	ra,ffffffffc0203a36 <do_pgfault>
ffffffffc0200e00:	c531                	beqz	a0,ffffffffc0200e4c <exception_handler+0x180>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e02:	10043783          	ld	a5,256(s0)
ffffffffc0200e06:	1007f793          	andi	a5,a5,256
                if (trap_in_kernel(tf)) {
ffffffffc0200e0a:	0e079c63          	bnez	a5,ffffffffc0200f02 <exception_handler+0x236>
}
ffffffffc0200e0e:	6402                	ld	s0,0(sp)
ffffffffc0200e10:	60a2                	ld	ra,8(sp)
                    do_exit(-E_FAULT);
ffffffffc0200e12:	5569                	li	a0,-6
}
ffffffffc0200e14:	0141                	addi	sp,sp,16
                    do_exit(-E_FAULT);
ffffffffc0200e16:	61b0306f          	j	ffffffffc0204c30 <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200e1a:	00006517          	auipc	a0,0x6
ffffffffc0200e1e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0206820 <commands+0x648>
ffffffffc0200e22:	bddd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200e24:	00006517          	auipc	a0,0x6
ffffffffc0200e28:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0206840 <commands+0x668>
ffffffffc0200e2c:	b5f5                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200e2e:	00006517          	auipc	a0,0x6
ffffffffc0200e32:	a3250513          	addi	a0,a0,-1486 # ffffffffc0206860 <commands+0x688>
ffffffffc0200e36:	b5cd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200e38:	00006517          	auipc	a0,0x6
ffffffffc0200e3c:	a4050513          	addi	a0,a0,-1472 # ffffffffc0206878 <commands+0x6a0>
ffffffffc0200e40:	b54ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200e44:	6458                	ld	a4,136(s0)
ffffffffc0200e46:	47a9                	li	a5,10
ffffffffc0200e48:	04f70663          	beq	a4,a5,ffffffffc0200e94 <exception_handler+0x1c8>
}
ffffffffc0200e4c:	60a2                	ld	ra,8(sp)
ffffffffc0200e4e:	6402                	ld	s0,0(sp)
ffffffffc0200e50:	0141                	addi	sp,sp,16
ffffffffc0200e52:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200e54:	00006517          	auipc	a0,0x6
ffffffffc0200e58:	a3450513          	addi	a0,a0,-1484 # ffffffffc0206888 <commands+0x6b0>
ffffffffc0200e5c:	bd75                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200e5e:	00006517          	auipc	a0,0x6
ffffffffc0200e62:	a4a50513          	addi	a0,a0,-1462 # ffffffffc02068a8 <commands+0x6d0>
ffffffffc0200e66:	bd4d                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200e68:	00006517          	auipc	a0,0x6
ffffffffc0200e6c:	a8850513          	addi	a0,a0,-1400 # ffffffffc02068f0 <commands+0x718>
ffffffffc0200e70:	b565                	j	ffffffffc0200d18 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200e72:	8522                	mv	a0,s0
}
ffffffffc0200e74:	6402                	ld	s0,0(sp)
ffffffffc0200e76:	60a2                	ld	ra,8(sp)
ffffffffc0200e78:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200e7a:	b32d                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e7c:	00006617          	auipc	a2,0x6
ffffffffc0200e80:	a4460613          	addi	a2,a2,-1468 # ffffffffc02068c0 <commands+0x6e8>
ffffffffc0200e84:	0cd00593          	li	a1,205
ffffffffc0200e88:	00006517          	auipc	a0,0x6
ffffffffc0200e8c:	a5050513          	addi	a0,a0,-1456 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200e90:	dfeff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200e94:	10843783          	ld	a5,264(s0)
ffffffffc0200e98:	0791                	addi	a5,a5,4
ffffffffc0200e9a:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200e9e:	37d040ef          	jal	ra,ffffffffc0205a1a <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200ea2:	000b5797          	auipc	a5,0xb5
ffffffffc0200ea6:	2b67b783          	ld	a5,694(a5) # ffffffffc02b6158 <current>
ffffffffc0200eaa:	6b9c                	ld	a5,16(a5)
ffffffffc0200eac:	8522                	mv	a0,s0
}
ffffffffc0200eae:	6402                	ld	s0,0(sp)
ffffffffc0200eb0:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200eb2:	6589                	lui	a1,0x2
ffffffffc0200eb4:	95be                	add	a1,a1,a5
}
ffffffffc0200eb6:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200eb8:	aa6d                	j	ffffffffc0201072 <kernel_execve_ret>
            panic("kernel page fault");
ffffffffc0200eba:	00006617          	auipc	a2,0x6
ffffffffc0200ebe:	aee60613          	addi	a2,a2,-1298 # ffffffffc02069a8 <commands+0x7d0>
ffffffffc0200ec2:	0ed00593          	li	a1,237
ffffffffc0200ec6:	00006517          	auipc	a0,0x6
ffffffffc0200eca:	a1250513          	addi	a0,a0,-1518 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200ece:	dc0ff0ef          	jal	ra,ffffffffc020048e <__panic>
            panic("kernel page fault");
ffffffffc0200ed2:	00006617          	auipc	a2,0x6
ffffffffc0200ed6:	ad660613          	addi	a2,a2,-1322 # ffffffffc02069a8 <commands+0x7d0>
ffffffffc0200eda:	10900593          	li	a1,265
ffffffffc0200ede:	00006517          	auipc	a0,0x6
ffffffffc0200ee2:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200ee6:	da8ff0ef          	jal	ra,ffffffffc020048e <__panic>
            panic("kernel page fault");
ffffffffc0200eea:	00006617          	auipc	a2,0x6
ffffffffc0200eee:	abe60613          	addi	a2,a2,-1346 # ffffffffc02069a8 <commands+0x7d0>
ffffffffc0200ef2:	0fb00593          	li	a1,251
ffffffffc0200ef6:	00006517          	auipc	a0,0x6
ffffffffc0200efa:	9e250513          	addi	a0,a0,-1566 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200efe:	d90ff0ef          	jal	ra,ffffffffc020048e <__panic>
                    panic("kernel page fault on user address");
ffffffffc0200f02:	00006617          	auipc	a2,0x6
ffffffffc0200f06:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0206980 <commands+0x7a8>
ffffffffc0200f0a:	10300593          	li	a1,259
ffffffffc0200f0e:	00006517          	auipc	a0,0x6
ffffffffc0200f12:	9ca50513          	addi	a0,a0,-1590 # ffffffffc02068d8 <commands+0x700>
ffffffffc0200f16:	d78ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200f1a <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200f1a:	1101                	addi	sp,sp,-32
ffffffffc0200f1c:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200f1e:	000b5417          	auipc	s0,0xb5
ffffffffc0200f22:	23a40413          	addi	s0,s0,570 # ffffffffc02b6158 <current>
ffffffffc0200f26:	6018                	ld	a4,0(s0)
{
ffffffffc0200f28:	ec06                	sd	ra,24(sp)
ffffffffc0200f2a:	e426                	sd	s1,8(sp)
ffffffffc0200f2c:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200f2e:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200f32:	cf1d                	beqz	a4,ffffffffc0200f70 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200f34:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200f38:	0a073903          	ld	s2,160(a4) # 7fe000a0 <_binary_obj___user_exit_out_size+0x7fdf4f70>
        current->tf = tf;
ffffffffc0200f3c:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200f3e:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200f42:	0206c463          	bltz	a3,ffffffffc0200f6a <trap+0x50>
        exception_handler(tf);
ffffffffc0200f46:	d87ff0ef          	jal	ra,ffffffffc0200ccc <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200f4a:	601c                	ld	a5,0(s0)
ffffffffc0200f4c:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200f50:	e499                	bnez	s1,ffffffffc0200f5e <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200f52:	0b07a703          	lw	a4,176(a5)
ffffffffc0200f56:	8b05                	andi	a4,a4,1
ffffffffc0200f58:	e329                	bnez	a4,ffffffffc0200f9a <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200f5a:	6f9c                	ld	a5,24(a5)
ffffffffc0200f5c:	eb85                	bnez	a5,ffffffffc0200f8c <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200f5e:	60e2                	ld	ra,24(sp)
ffffffffc0200f60:	6442                	ld	s0,16(sp)
ffffffffc0200f62:	64a2                	ld	s1,8(sp)
ffffffffc0200f64:	6902                	ld	s2,0(sp)
ffffffffc0200f66:	6105                	addi	sp,sp,32
ffffffffc0200f68:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200f6a:	c9dff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200f6e:	bff1                	j	ffffffffc0200f4a <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200f70:	0006c863          	bltz	a3,ffffffffc0200f80 <trap+0x66>
}
ffffffffc0200f74:	6442                	ld	s0,16(sp)
ffffffffc0200f76:	60e2                	ld	ra,24(sp)
ffffffffc0200f78:	64a2                	ld	s1,8(sp)
ffffffffc0200f7a:	6902                	ld	s2,0(sp)
ffffffffc0200f7c:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200f7e:	b3b9                	j	ffffffffc0200ccc <exception_handler>
}
ffffffffc0200f80:	6442                	ld	s0,16(sp)
ffffffffc0200f82:	60e2                	ld	ra,24(sp)
ffffffffc0200f84:	64a2                	ld	s1,8(sp)
ffffffffc0200f86:	6902                	ld	s2,0(sp)
ffffffffc0200f88:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200f8a:	b9b5                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200f8c:	6442                	ld	s0,16(sp)
ffffffffc0200f8e:	60e2                	ld	ra,24(sp)
ffffffffc0200f90:	64a2                	ld	s1,8(sp)
ffffffffc0200f92:	6902                	ld	s2,0(sp)
ffffffffc0200f94:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200f96:	1990406f          	j	ffffffffc020592e <schedule>
                do_exit(-E_KILLED);
ffffffffc0200f9a:	555d                	li	a0,-9
ffffffffc0200f9c:	495030ef          	jal	ra,ffffffffc0204c30 <do_exit>
            if (current->need_resched)
ffffffffc0200fa0:	601c                	ld	a5,0(s0)
ffffffffc0200fa2:	bf65                	j	ffffffffc0200f5a <trap+0x40>

ffffffffc0200fa4 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200fa4:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200fa8:	00011463          	bnez	sp,ffffffffc0200fb0 <__alltraps+0xc>
ffffffffc0200fac:	14002173          	csrr	sp,sscratch
ffffffffc0200fb0:	712d                	addi	sp,sp,-288
ffffffffc0200fb2:	e002                	sd	zero,0(sp)
ffffffffc0200fb4:	e406                	sd	ra,8(sp)
ffffffffc0200fb6:	ec0e                	sd	gp,24(sp)
ffffffffc0200fb8:	f012                	sd	tp,32(sp)
ffffffffc0200fba:	f416                	sd	t0,40(sp)
ffffffffc0200fbc:	f81a                	sd	t1,48(sp)
ffffffffc0200fbe:	fc1e                	sd	t2,56(sp)
ffffffffc0200fc0:	e0a2                	sd	s0,64(sp)
ffffffffc0200fc2:	e4a6                	sd	s1,72(sp)
ffffffffc0200fc4:	e8aa                	sd	a0,80(sp)
ffffffffc0200fc6:	ecae                	sd	a1,88(sp)
ffffffffc0200fc8:	f0b2                	sd	a2,96(sp)
ffffffffc0200fca:	f4b6                	sd	a3,104(sp)
ffffffffc0200fcc:	f8ba                	sd	a4,112(sp)
ffffffffc0200fce:	fcbe                	sd	a5,120(sp)
ffffffffc0200fd0:	e142                	sd	a6,128(sp)
ffffffffc0200fd2:	e546                	sd	a7,136(sp)
ffffffffc0200fd4:	e94a                	sd	s2,144(sp)
ffffffffc0200fd6:	ed4e                	sd	s3,152(sp)
ffffffffc0200fd8:	f152                	sd	s4,160(sp)
ffffffffc0200fda:	f556                	sd	s5,168(sp)
ffffffffc0200fdc:	f95a                	sd	s6,176(sp)
ffffffffc0200fde:	fd5e                	sd	s7,184(sp)
ffffffffc0200fe0:	e1e2                	sd	s8,192(sp)
ffffffffc0200fe2:	e5e6                	sd	s9,200(sp)
ffffffffc0200fe4:	e9ea                	sd	s10,208(sp)
ffffffffc0200fe6:	edee                	sd	s11,216(sp)
ffffffffc0200fe8:	f1f2                	sd	t3,224(sp)
ffffffffc0200fea:	f5f6                	sd	t4,232(sp)
ffffffffc0200fec:	f9fa                	sd	t5,240(sp)
ffffffffc0200fee:	fdfe                	sd	t6,248(sp)
ffffffffc0200ff0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ff4:	100024f3          	csrr	s1,sstatus
ffffffffc0200ff8:	14102973          	csrr	s2,sepc
ffffffffc0200ffc:	143029f3          	csrr	s3,stval
ffffffffc0201000:	14202a73          	csrr	s4,scause
ffffffffc0201004:	e822                	sd	s0,16(sp)
ffffffffc0201006:	e226                	sd	s1,256(sp)
ffffffffc0201008:	e64a                	sd	s2,264(sp)
ffffffffc020100a:	ea4e                	sd	s3,272(sp)
ffffffffc020100c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc020100e:	850a                	mv	a0,sp
    jal trap
ffffffffc0201010:	f0bff0ef          	jal	ra,ffffffffc0200f1a <trap>

ffffffffc0201014 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0201014:	6492                	ld	s1,256(sp)
ffffffffc0201016:	6932                	ld	s2,264(sp)
ffffffffc0201018:	1004f413          	andi	s0,s1,256
ffffffffc020101c:	e401                	bnez	s0,ffffffffc0201024 <__trapret+0x10>
ffffffffc020101e:	1200                	addi	s0,sp,288
ffffffffc0201020:	14041073          	csrw	sscratch,s0
ffffffffc0201024:	10049073          	csrw	sstatus,s1
ffffffffc0201028:	14191073          	csrw	sepc,s2
ffffffffc020102c:	60a2                	ld	ra,8(sp)
ffffffffc020102e:	61e2                	ld	gp,24(sp)
ffffffffc0201030:	7202                	ld	tp,32(sp)
ffffffffc0201032:	72a2                	ld	t0,40(sp)
ffffffffc0201034:	7342                	ld	t1,48(sp)
ffffffffc0201036:	73e2                	ld	t2,56(sp)
ffffffffc0201038:	6406                	ld	s0,64(sp)
ffffffffc020103a:	64a6                	ld	s1,72(sp)
ffffffffc020103c:	6546                	ld	a0,80(sp)
ffffffffc020103e:	65e6                	ld	a1,88(sp)
ffffffffc0201040:	7606                	ld	a2,96(sp)
ffffffffc0201042:	76a6                	ld	a3,104(sp)
ffffffffc0201044:	7746                	ld	a4,112(sp)
ffffffffc0201046:	77e6                	ld	a5,120(sp)
ffffffffc0201048:	680a                	ld	a6,128(sp)
ffffffffc020104a:	68aa                	ld	a7,136(sp)
ffffffffc020104c:	694a                	ld	s2,144(sp)
ffffffffc020104e:	69ea                	ld	s3,152(sp)
ffffffffc0201050:	7a0a                	ld	s4,160(sp)
ffffffffc0201052:	7aaa                	ld	s5,168(sp)
ffffffffc0201054:	7b4a                	ld	s6,176(sp)
ffffffffc0201056:	7bea                	ld	s7,184(sp)
ffffffffc0201058:	6c0e                	ld	s8,192(sp)
ffffffffc020105a:	6cae                	ld	s9,200(sp)
ffffffffc020105c:	6d4e                	ld	s10,208(sp)
ffffffffc020105e:	6dee                	ld	s11,216(sp)
ffffffffc0201060:	7e0e                	ld	t3,224(sp)
ffffffffc0201062:	7eae                	ld	t4,232(sp)
ffffffffc0201064:	7f4e                	ld	t5,240(sp)
ffffffffc0201066:	7fee                	ld	t6,248(sp)
ffffffffc0201068:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc020106a:	10200073          	sret

ffffffffc020106e <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc020106e:	812a                	mv	sp,a0
    j __trapret
ffffffffc0201070:	b755                	j	ffffffffc0201014 <__trapret>

ffffffffc0201072 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0201072:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0201076:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc020107a:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc020107e:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0201082:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0201086:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc020108a:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc020108e:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0201092:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0201096:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0201098:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc020109a:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc020109c:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc020109e:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc02010a0:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc02010a2:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc02010a4:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc02010a6:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc02010a8:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc02010aa:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc02010ac:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc02010ae:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc02010b0:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc02010b2:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc02010b4:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc02010b6:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc02010b8:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc02010ba:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc02010bc:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc02010be:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc02010c0:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc02010c2:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc02010c4:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc02010c6:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc02010c8:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc02010ca:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc02010cc:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc02010ce:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc02010d0:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc02010d2:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc02010d4:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc02010d6:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc02010d8:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc02010da:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc02010dc:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc02010de:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc02010e0:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc02010e2:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc02010e4:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc02010e6:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc02010e8:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc02010ea:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc02010ec:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc02010ee:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc02010f0:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc02010f2:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc02010f4:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc02010f6:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc02010f8:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc02010fa:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc02010fc:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc02010fe:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201100:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201102:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201104:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0201106:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0201108:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020110a:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc020110c:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc020110e:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201110:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201112:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201114:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0201116:	812e                	mv	sp,a1
ffffffffc0201118:	bdf5                	j	ffffffffc0201014 <__trapret>

ffffffffc020111a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020111a:	000b1797          	auipc	a5,0xb1
ffffffffc020111e:	fa678793          	addi	a5,a5,-90 # ffffffffc02b20c0 <free_area>
ffffffffc0201122:	e79c                	sd	a5,8(a5)
ffffffffc0201124:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201126:	0007a823          	sw	zero,16(a5)
}
ffffffffc020112a:	8082                	ret

ffffffffc020112c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc020112c:	000b1517          	auipc	a0,0xb1
ffffffffc0201130:	fa456503          	lwu	a0,-92(a0) # ffffffffc02b20d0 <free_area+0x10>
ffffffffc0201134:	8082                	ret

ffffffffc0201136 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0201136:	715d                	addi	sp,sp,-80
ffffffffc0201138:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020113a:	000b1417          	auipc	s0,0xb1
ffffffffc020113e:	f8640413          	addi	s0,s0,-122 # ffffffffc02b20c0 <free_area>
ffffffffc0201142:	641c                	ld	a5,8(s0)
ffffffffc0201144:	e486                	sd	ra,72(sp)
ffffffffc0201146:	fc26                	sd	s1,56(sp)
ffffffffc0201148:	f84a                	sd	s2,48(sp)
ffffffffc020114a:	f44e                	sd	s3,40(sp)
ffffffffc020114c:	f052                	sd	s4,32(sp)
ffffffffc020114e:	ec56                	sd	s5,24(sp)
ffffffffc0201150:	e85a                	sd	s6,16(sp)
ffffffffc0201152:	e45e                	sd	s7,8(sp)
ffffffffc0201154:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201156:	2c878763          	beq	a5,s0,ffffffffc0201424 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc020115a:	4481                	li	s1,0
ffffffffc020115c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020115e:	fe87b703          	ld	a4,-24(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201162:	8b09                	andi	a4,a4,2
ffffffffc0201164:	2c070463          	beqz	a4,ffffffffc020142c <default_check+0x2f6>
        count++, total += p->property;
ffffffffc0201168:	ff87a703          	lw	a4,-8(a5)
ffffffffc020116c:	679c                	ld	a5,8(a5)
ffffffffc020116e:	2905                	addiw	s2,s2,1
ffffffffc0201170:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201172:	fe8796e3          	bne	a5,s0,ffffffffc020115e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201176:	89a6                	mv	s3,s1
ffffffffc0201178:	723000ef          	jal	ra,ffffffffc020209a <nr_free_pages>
ffffffffc020117c:	71351863          	bne	a0,s3,ffffffffc020188c <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201180:	4505                	li	a0,1
ffffffffc0201182:	69b000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201186:	8a2a                	mv	s4,a0
ffffffffc0201188:	44050263          	beqz	a0,ffffffffc02015cc <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020118c:	4505                	li	a0,1
ffffffffc020118e:	68f000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201192:	89aa                	mv	s3,a0
ffffffffc0201194:	70050c63          	beqz	a0,ffffffffc02018ac <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201198:	4505                	li	a0,1
ffffffffc020119a:	683000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc020119e:	8aaa                	mv	s5,a0
ffffffffc02011a0:	4a050663          	beqz	a0,ffffffffc020164c <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011a4:	2b3a0463          	beq	s4,s3,ffffffffc020144c <default_check+0x316>
ffffffffc02011a8:	2aaa0263          	beq	s4,a0,ffffffffc020144c <default_check+0x316>
ffffffffc02011ac:	2aa98063          	beq	s3,a0,ffffffffc020144c <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011b0:	000a2783          	lw	a5,0(s4)
ffffffffc02011b4:	2a079c63          	bnez	a5,ffffffffc020146c <default_check+0x336>
ffffffffc02011b8:	0009a783          	lw	a5,0(s3)
ffffffffc02011bc:	2a079863          	bnez	a5,ffffffffc020146c <default_check+0x336>
ffffffffc02011c0:	411c                	lw	a5,0(a0)
ffffffffc02011c2:	2a079563          	bnez	a5,ffffffffc020146c <default_check+0x336>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc02011c6:	000b5797          	auipc	a5,0xb5
ffffffffc02011ca:	f727b783          	ld	a5,-142(a5) # ffffffffc02b6138 <pages>
ffffffffc02011ce:	40fa0733          	sub	a4,s4,a5
ffffffffc02011d2:	870d                	srai	a4,a4,0x3
ffffffffc02011d4:	00007597          	auipc	a1,0x7
ffffffffc02011d8:	fd45b583          	ld	a1,-44(a1) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc02011dc:	02b70733          	mul	a4,a4,a1
ffffffffc02011e0:	00007617          	auipc	a2,0x7
ffffffffc02011e4:	fd063603          	ld	a2,-48(a2) # ffffffffc02081b0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011e8:	000b5697          	auipc	a3,0xb5
ffffffffc02011ec:	f486b683          	ld	a3,-184(a3) # ffffffffc02b6130 <npage>
ffffffffc02011f0:	06b2                	slli	a3,a3,0xc
ffffffffc02011f2:	9732                	add	a4,a4,a2
    }
}
static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02011f4:	0732                	slli	a4,a4,0xc
ffffffffc02011f6:	28d77b63          	bgeu	a4,a3,ffffffffc020148c <default_check+0x356>
    return page - pages + nbase;
ffffffffc02011fa:	40f98733          	sub	a4,s3,a5
ffffffffc02011fe:	870d                	srai	a4,a4,0x3
ffffffffc0201200:	02b70733          	mul	a4,a4,a1
ffffffffc0201204:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201206:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201208:	4cd77263          	bgeu	a4,a3,ffffffffc02016cc <default_check+0x596>
    return page - pages + nbase;
ffffffffc020120c:	40f507b3          	sub	a5,a0,a5
ffffffffc0201210:	878d                	srai	a5,a5,0x3
ffffffffc0201212:	02b787b3          	mul	a5,a5,a1
ffffffffc0201216:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201218:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020121a:	30d7f963          	bgeu	a5,a3,ffffffffc020152c <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc020121e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201220:	00043c03          	ld	s8,0(s0)
ffffffffc0201224:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201228:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020122c:	e400                	sd	s0,8(s0)
ffffffffc020122e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201230:	000b1797          	auipc	a5,0xb1
ffffffffc0201234:	ea07a023          	sw	zero,-352(a5) # ffffffffc02b20d0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201238:	5e5000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc020123c:	2c051863          	bnez	a0,ffffffffc020150c <default_check+0x3d6>
    free_page(p0);
ffffffffc0201240:	4585                	li	a1,1
ffffffffc0201242:	8552                	mv	a0,s4
ffffffffc0201244:	617000ef          	jal	ra,ffffffffc020205a <free_pages>
    free_page(p1);
ffffffffc0201248:	4585                	li	a1,1
ffffffffc020124a:	854e                	mv	a0,s3
ffffffffc020124c:	60f000ef          	jal	ra,ffffffffc020205a <free_pages>
    free_page(p2);
ffffffffc0201250:	4585                	li	a1,1
ffffffffc0201252:	8556                	mv	a0,s5
ffffffffc0201254:	607000ef          	jal	ra,ffffffffc020205a <free_pages>
    assert(nr_free == 3);
ffffffffc0201258:	4818                	lw	a4,16(s0)
ffffffffc020125a:	478d                	li	a5,3
ffffffffc020125c:	28f71863          	bne	a4,a5,ffffffffc02014ec <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201260:	4505                	li	a0,1
ffffffffc0201262:	5bb000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201266:	89aa                	mv	s3,a0
ffffffffc0201268:	26050263          	beqz	a0,ffffffffc02014cc <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020126c:	4505                	li	a0,1
ffffffffc020126e:	5af000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201272:	8aaa                	mv	s5,a0
ffffffffc0201274:	3a050c63          	beqz	a0,ffffffffc020162c <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201278:	4505                	li	a0,1
ffffffffc020127a:	5a3000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc020127e:	8a2a                	mv	s4,a0
ffffffffc0201280:	38050663          	beqz	a0,ffffffffc020160c <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0201284:	4505                	li	a0,1
ffffffffc0201286:	597000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc020128a:	36051163          	bnez	a0,ffffffffc02015ec <default_check+0x4b6>
    free_page(p0);
ffffffffc020128e:	4585                	li	a1,1
ffffffffc0201290:	854e                	mv	a0,s3
ffffffffc0201292:	5c9000ef          	jal	ra,ffffffffc020205a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201296:	641c                	ld	a5,8(s0)
ffffffffc0201298:	20878a63          	beq	a5,s0,ffffffffc02014ac <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc020129c:	4505                	li	a0,1
ffffffffc020129e:	57f000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc02012a2:	30a99563          	bne	s3,a0,ffffffffc02015ac <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc02012a6:	4505                	li	a0,1
ffffffffc02012a8:	575000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc02012ac:	2e051063          	bnez	a0,ffffffffc020158c <default_check+0x456>
    assert(nr_free == 0);
ffffffffc02012b0:	481c                	lw	a5,16(s0)
ffffffffc02012b2:	2a079d63          	bnez	a5,ffffffffc020156c <default_check+0x436>
    free_page(p);
ffffffffc02012b6:	854e                	mv	a0,s3
ffffffffc02012b8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02012ba:	01843023          	sd	s8,0(s0)
ffffffffc02012be:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02012c2:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02012c6:	595000ef          	jal	ra,ffffffffc020205a <free_pages>
    free_page(p1);
ffffffffc02012ca:	4585                	li	a1,1
ffffffffc02012cc:	8556                	mv	a0,s5
ffffffffc02012ce:	58d000ef          	jal	ra,ffffffffc020205a <free_pages>
    free_page(p2);
ffffffffc02012d2:	4585                	li	a1,1
ffffffffc02012d4:	8552                	mv	a0,s4
ffffffffc02012d6:	585000ef          	jal	ra,ffffffffc020205a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02012da:	4515                	li	a0,5
ffffffffc02012dc:	541000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc02012e0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02012e2:	26050563          	beqz	a0,ffffffffc020154c <default_check+0x416>
ffffffffc02012e6:	651c                	ld	a5,8(a0)
ffffffffc02012e8:	8385                	srli	a5,a5,0x1
ffffffffc02012ea:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02012ec:	54079063          	bnez	a5,ffffffffc020182c <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02012f0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02012f2:	00043b03          	ld	s6,0(s0)
ffffffffc02012f6:	00843a83          	ld	s5,8(s0)
ffffffffc02012fa:	e000                	sd	s0,0(s0)
ffffffffc02012fc:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02012fe:	51f000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201302:	50051563          	bnez	a0,ffffffffc020180c <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201306:	09098a13          	addi	s4,s3,144
ffffffffc020130a:	8552                	mv	a0,s4
ffffffffc020130c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020130e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201312:	000b1797          	auipc	a5,0xb1
ffffffffc0201316:	da07af23          	sw	zero,-578(a5) # ffffffffc02b20d0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020131a:	541000ef          	jal	ra,ffffffffc020205a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020131e:	4511                	li	a0,4
ffffffffc0201320:	4fd000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201324:	4c051463          	bnez	a0,ffffffffc02017ec <default_check+0x6b6>
ffffffffc0201328:	0989b783          	ld	a5,152(s3)
ffffffffc020132c:	8385                	srli	a5,a5,0x1
ffffffffc020132e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201330:	48078e63          	beqz	a5,ffffffffc02017cc <default_check+0x696>
ffffffffc0201334:	0a89a703          	lw	a4,168(s3)
ffffffffc0201338:	478d                	li	a5,3
ffffffffc020133a:	48f71963          	bne	a4,a5,ffffffffc02017cc <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020133e:	450d                	li	a0,3
ffffffffc0201340:	4dd000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201344:	8c2a                	mv	s8,a0
ffffffffc0201346:	46050363          	beqz	a0,ffffffffc02017ac <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc020134a:	4505                	li	a0,1
ffffffffc020134c:	4d1000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0201350:	42051e63          	bnez	a0,ffffffffc020178c <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0201354:	418a1c63          	bne	s4,s8,ffffffffc020176c <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201358:	4585                	li	a1,1
ffffffffc020135a:	854e                	mv	a0,s3
ffffffffc020135c:	4ff000ef          	jal	ra,ffffffffc020205a <free_pages>
    free_pages(p1, 3);
ffffffffc0201360:	458d                	li	a1,3
ffffffffc0201362:	8552                	mv	a0,s4
ffffffffc0201364:	4f7000ef          	jal	ra,ffffffffc020205a <free_pages>
ffffffffc0201368:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020136c:	04898c13          	addi	s8,s3,72
ffffffffc0201370:	8385                	srli	a5,a5,0x1
ffffffffc0201372:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201374:	3c078c63          	beqz	a5,ffffffffc020174c <default_check+0x616>
ffffffffc0201378:	0189a703          	lw	a4,24(s3)
ffffffffc020137c:	4785                	li	a5,1
ffffffffc020137e:	3cf71763          	bne	a4,a5,ffffffffc020174c <default_check+0x616>
ffffffffc0201382:	008a3783          	ld	a5,8(s4)
ffffffffc0201386:	8385                	srli	a5,a5,0x1
ffffffffc0201388:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020138a:	3a078163          	beqz	a5,ffffffffc020172c <default_check+0x5f6>
ffffffffc020138e:	018a2703          	lw	a4,24(s4)
ffffffffc0201392:	478d                	li	a5,3
ffffffffc0201394:	38f71c63          	bne	a4,a5,ffffffffc020172c <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201398:	4505                	li	a0,1
ffffffffc020139a:	483000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc020139e:	36a99763          	bne	s3,a0,ffffffffc020170c <default_check+0x5d6>
    free_page(p0);
ffffffffc02013a2:	4585                	li	a1,1
ffffffffc02013a4:	4b7000ef          	jal	ra,ffffffffc020205a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013a8:	4509                	li	a0,2
ffffffffc02013aa:	473000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc02013ae:	32aa1f63          	bne	s4,a0,ffffffffc02016ec <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc02013b2:	4589                	li	a1,2
ffffffffc02013b4:	4a7000ef          	jal	ra,ffffffffc020205a <free_pages>
    free_page(p2);
ffffffffc02013b8:	4585                	li	a1,1
ffffffffc02013ba:	8562                	mv	a0,s8
ffffffffc02013bc:	49f000ef          	jal	ra,ffffffffc020205a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02013c0:	4515                	li	a0,5
ffffffffc02013c2:	45b000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc02013c6:	89aa                	mv	s3,a0
ffffffffc02013c8:	48050263          	beqz	a0,ffffffffc020184c <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc02013cc:	4505                	li	a0,1
ffffffffc02013ce:	44f000ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc02013d2:	2c051d63          	bnez	a0,ffffffffc02016ac <default_check+0x576>

    assert(nr_free == 0);
ffffffffc02013d6:	481c                	lw	a5,16(s0)
ffffffffc02013d8:	2a079a63          	bnez	a5,ffffffffc020168c <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02013dc:	4595                	li	a1,5
ffffffffc02013de:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02013e0:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02013e4:	01643023          	sd	s6,0(s0)
ffffffffc02013e8:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02013ec:	46f000ef          	jal	ra,ffffffffc020205a <free_pages>
    return listelm->next;
ffffffffc02013f0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02013f2:	00878963          	beq	a5,s0,ffffffffc0201404 <default_check+0x2ce>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02013f6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02013fa:	679c                	ld	a5,8(a5)
ffffffffc02013fc:	397d                	addiw	s2,s2,-1
ffffffffc02013fe:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201400:	fe879be3          	bne	a5,s0,ffffffffc02013f6 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0201404:	26091463          	bnez	s2,ffffffffc020166c <default_check+0x536>
    assert(total == 0);
ffffffffc0201408:	46049263          	bnez	s1,ffffffffc020186c <default_check+0x736>
}
ffffffffc020140c:	60a6                	ld	ra,72(sp)
ffffffffc020140e:	6406                	ld	s0,64(sp)
ffffffffc0201410:	74e2                	ld	s1,56(sp)
ffffffffc0201412:	7942                	ld	s2,48(sp)
ffffffffc0201414:	79a2                	ld	s3,40(sp)
ffffffffc0201416:	7a02                	ld	s4,32(sp)
ffffffffc0201418:	6ae2                	ld	s5,24(sp)
ffffffffc020141a:	6b42                	ld	s6,16(sp)
ffffffffc020141c:	6ba2                	ld	s7,8(sp)
ffffffffc020141e:	6c02                	ld	s8,0(sp)
ffffffffc0201420:	6161                	addi	sp,sp,80
ffffffffc0201422:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201424:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201426:	4481                	li	s1,0
ffffffffc0201428:	4901                	li	s2,0
ffffffffc020142a:	b3b9                	j	ffffffffc0201178 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	60468693          	addi	a3,a3,1540 # ffffffffc0206a30 <commands+0x858>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	60c60613          	addi	a2,a2,1548 # ffffffffc0206a40 <commands+0x868>
ffffffffc020143c:	11200593          	li	a1,274
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	61850513          	addi	a0,a0,1560 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201448:	846ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	6a468693          	addi	a3,a3,1700 # ffffffffc0206af0 <commands+0x918>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	5ec60613          	addi	a2,a2,1516 # ffffffffc0206a40 <commands+0x868>
ffffffffc020145c:	0dd00593          	li	a1,221
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	5f850513          	addi	a0,a0,1528 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201468:	826ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	6ac68693          	addi	a3,a3,1708 # ffffffffc0206b18 <commands+0x940>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	5cc60613          	addi	a2,a2,1484 # ffffffffc0206a40 <commands+0x868>
ffffffffc020147c:	0de00593          	li	a1,222
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	5d850513          	addi	a0,a0,1496 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201488:	806ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	6cc68693          	addi	a3,a3,1740 # ffffffffc0206b58 <commands+0x980>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	5ac60613          	addi	a2,a2,1452 # ffffffffc0206a40 <commands+0x868>
ffffffffc020149c:	0e000593          	li	a1,224
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	5b850513          	addi	a0,a0,1464 # ffffffffc0206a58 <commands+0x880>
ffffffffc02014a8:	fe7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	73468693          	addi	a3,a3,1844 # ffffffffc0206be0 <commands+0xa08>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	58c60613          	addi	a2,a2,1420 # ffffffffc0206a40 <commands+0x868>
ffffffffc02014bc:	0f900593          	li	a1,249
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	59850513          	addi	a0,a0,1432 # ffffffffc0206a58 <commands+0x880>
ffffffffc02014c8:	fc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	5c468693          	addi	a3,a3,1476 # ffffffffc0206a90 <commands+0x8b8>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	56c60613          	addi	a2,a2,1388 # ffffffffc0206a40 <commands+0x868>
ffffffffc02014dc:	0f200593          	li	a1,242
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	57850513          	addi	a0,a0,1400 # ffffffffc0206a58 <commands+0x880>
ffffffffc02014e8:	fa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	6e468693          	addi	a3,a3,1764 # ffffffffc0206bd0 <commands+0x9f8>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	54c60613          	addi	a2,a2,1356 # ffffffffc0206a40 <commands+0x868>
ffffffffc02014fc:	0f000593          	li	a1,240
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	55850513          	addi	a0,a0,1368 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201508:	f87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	6ac68693          	addi	a3,a3,1708 # ffffffffc0206bb8 <commands+0x9e0>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	52c60613          	addi	a2,a2,1324 # ffffffffc0206a40 <commands+0x868>
ffffffffc020151c:	0eb00593          	li	a1,235
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	53850513          	addi	a0,a0,1336 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201528:	f67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	66c68693          	addi	a3,a3,1644 # ffffffffc0206b98 <commands+0x9c0>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	50c60613          	addi	a2,a2,1292 # ffffffffc0206a40 <commands+0x868>
ffffffffc020153c:	0e200593          	li	a1,226
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	51850513          	addi	a0,a0,1304 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201548:	f47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	6dc68693          	addi	a3,a3,1756 # ffffffffc0206c28 <commands+0xa50>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	4ec60613          	addi	a2,a2,1260 # ffffffffc0206a40 <commands+0x868>
ffffffffc020155c:	11a00593          	li	a1,282
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	4f850513          	addi	a0,a0,1272 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201568:	f27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	6ac68693          	addi	a3,a3,1708 # ffffffffc0206c18 <commands+0xa40>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	4cc60613          	addi	a2,a2,1228 # ffffffffc0206a40 <commands+0x868>
ffffffffc020157c:	0ff00593          	li	a1,255
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	4d850513          	addi	a0,a0,1240 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201588:	f07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	62c68693          	addi	a3,a3,1580 # ffffffffc0206bb8 <commands+0x9e0>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	4ac60613          	addi	a2,a2,1196 # ffffffffc0206a40 <commands+0x868>
ffffffffc020159c:	0fd00593          	li	a1,253
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	4b850513          	addi	a0,a0,1208 # ffffffffc0206a58 <commands+0x880>
ffffffffc02015a8:	ee7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	64c68693          	addi	a3,a3,1612 # ffffffffc0206bf8 <commands+0xa20>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	48c60613          	addi	a2,a2,1164 # ffffffffc0206a40 <commands+0x868>
ffffffffc02015bc:	0fc00593          	li	a1,252
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	49850513          	addi	a0,a0,1176 # ffffffffc0206a58 <commands+0x880>
ffffffffc02015c8:	ec7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	4c468693          	addi	a3,a3,1220 # ffffffffc0206a90 <commands+0x8b8>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	46c60613          	addi	a2,a2,1132 # ffffffffc0206a40 <commands+0x868>
ffffffffc02015dc:	0d900593          	li	a1,217
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	47850513          	addi	a0,a0,1144 # ffffffffc0206a58 <commands+0x880>
ffffffffc02015e8:	ea7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	5cc68693          	addi	a3,a3,1484 # ffffffffc0206bb8 <commands+0x9e0>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	44c60613          	addi	a2,a2,1100 # ffffffffc0206a40 <commands+0x868>
ffffffffc02015fc:	0f600593          	li	a1,246
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	45850513          	addi	a0,a0,1112 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201608:	e87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	4c468693          	addi	a3,a3,1220 # ffffffffc0206ad0 <commands+0x8f8>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	42c60613          	addi	a2,a2,1068 # ffffffffc0206a40 <commands+0x868>
ffffffffc020161c:	0f400593          	li	a1,244
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	43850513          	addi	a0,a0,1080 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201628:	e67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	48468693          	addi	a3,a3,1156 # ffffffffc0206ab0 <commands+0x8d8>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	40c60613          	addi	a2,a2,1036 # ffffffffc0206a40 <commands+0x868>
ffffffffc020163c:	0f300593          	li	a1,243
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	41850513          	addi	a0,a0,1048 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201648:	e47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	48468693          	addi	a3,a3,1156 # ffffffffc0206ad0 <commands+0x8f8>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	3ec60613          	addi	a2,a2,1004 # ffffffffc0206a40 <commands+0x868>
ffffffffc020165c:	0db00593          	li	a1,219
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	3f850513          	addi	a0,a0,1016 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201668:	e27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	70c68693          	addi	a3,a3,1804 # ffffffffc0206d78 <commands+0xba0>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	3cc60613          	addi	a2,a2,972 # ffffffffc0206a40 <commands+0x868>
ffffffffc020167c:	14800593          	li	a1,328
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	3d850513          	addi	a0,a0,984 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201688:	e07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	58c68693          	addi	a3,a3,1420 # ffffffffc0206c18 <commands+0xa40>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	3ac60613          	addi	a2,a2,940 # ffffffffc0206a40 <commands+0x868>
ffffffffc020169c:	13c00593          	li	a1,316
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	3b850513          	addi	a0,a0,952 # ffffffffc0206a58 <commands+0x880>
ffffffffc02016a8:	de7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	50c68693          	addi	a3,a3,1292 # ffffffffc0206bb8 <commands+0x9e0>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	38c60613          	addi	a2,a2,908 # ffffffffc0206a40 <commands+0x868>
ffffffffc02016bc:	13a00593          	li	a1,314
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	39850513          	addi	a0,a0,920 # ffffffffc0206a58 <commands+0x880>
ffffffffc02016c8:	dc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	4ac68693          	addi	a3,a3,1196 # ffffffffc0206b78 <commands+0x9a0>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	36c60613          	addi	a2,a2,876 # ffffffffc0206a40 <commands+0x868>
ffffffffc02016dc:	0e100593          	li	a1,225
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	37850513          	addi	a0,a0,888 # ffffffffc0206a58 <commands+0x880>
ffffffffc02016e8:	da7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	64c68693          	addi	a3,a3,1612 # ffffffffc0206d38 <commands+0xb60>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	34c60613          	addi	a2,a2,844 # ffffffffc0206a40 <commands+0x868>
ffffffffc02016fc:	13400593          	li	a1,308
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	35850513          	addi	a0,a0,856 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201708:	d87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	60c68693          	addi	a3,a3,1548 # ffffffffc0206d18 <commands+0xb40>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	32c60613          	addi	a2,a2,812 # ffffffffc0206a40 <commands+0x868>
ffffffffc020171c:	13200593          	li	a1,306
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	33850513          	addi	a0,a0,824 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201728:	d67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	5c468693          	addi	a3,a3,1476 # ffffffffc0206cf0 <commands+0xb18>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	30c60613          	addi	a2,a2,780 # ffffffffc0206a40 <commands+0x868>
ffffffffc020173c:	13000593          	li	a1,304
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	31850513          	addi	a0,a0,792 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201748:	d47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	57c68693          	addi	a3,a3,1404 # ffffffffc0206cc8 <commands+0xaf0>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	2ec60613          	addi	a2,a2,748 # ffffffffc0206a40 <commands+0x868>
ffffffffc020175c:	12f00593          	li	a1,303
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	2f850513          	addi	a0,a0,760 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201768:	d27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020176c:	00005697          	auipc	a3,0x5
ffffffffc0201770:	54c68693          	addi	a3,a3,1356 # ffffffffc0206cb8 <commands+0xae0>
ffffffffc0201774:	00005617          	auipc	a2,0x5
ffffffffc0201778:	2cc60613          	addi	a2,a2,716 # ffffffffc0206a40 <commands+0x868>
ffffffffc020177c:	12a00593          	li	a1,298
ffffffffc0201780:	00005517          	auipc	a0,0x5
ffffffffc0201784:	2d850513          	addi	a0,a0,728 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201788:	d07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	42c68693          	addi	a3,a3,1068 # ffffffffc0206bb8 <commands+0x9e0>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	2ac60613          	addi	a2,a2,684 # ffffffffc0206a40 <commands+0x868>
ffffffffc020179c:	12900593          	li	a1,297
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	2b850513          	addi	a0,a0,696 # ffffffffc0206a58 <commands+0x880>
ffffffffc02017a8:	ce7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02017ac:	00005697          	auipc	a3,0x5
ffffffffc02017b0:	4ec68693          	addi	a3,a3,1260 # ffffffffc0206c98 <commands+0xac0>
ffffffffc02017b4:	00005617          	auipc	a2,0x5
ffffffffc02017b8:	28c60613          	addi	a2,a2,652 # ffffffffc0206a40 <commands+0x868>
ffffffffc02017bc:	12800593          	li	a1,296
ffffffffc02017c0:	00005517          	auipc	a0,0x5
ffffffffc02017c4:	29850513          	addi	a0,a0,664 # ffffffffc0206a58 <commands+0x880>
ffffffffc02017c8:	cc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02017cc:	00005697          	auipc	a3,0x5
ffffffffc02017d0:	49c68693          	addi	a3,a3,1180 # ffffffffc0206c68 <commands+0xa90>
ffffffffc02017d4:	00005617          	auipc	a2,0x5
ffffffffc02017d8:	26c60613          	addi	a2,a2,620 # ffffffffc0206a40 <commands+0x868>
ffffffffc02017dc:	12700593          	li	a1,295
ffffffffc02017e0:	00005517          	auipc	a0,0x5
ffffffffc02017e4:	27850513          	addi	a0,a0,632 # ffffffffc0206a58 <commands+0x880>
ffffffffc02017e8:	ca7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02017ec:	00005697          	auipc	a3,0x5
ffffffffc02017f0:	46468693          	addi	a3,a3,1124 # ffffffffc0206c50 <commands+0xa78>
ffffffffc02017f4:	00005617          	auipc	a2,0x5
ffffffffc02017f8:	24c60613          	addi	a2,a2,588 # ffffffffc0206a40 <commands+0x868>
ffffffffc02017fc:	12600593          	li	a1,294
ffffffffc0201800:	00005517          	auipc	a0,0x5
ffffffffc0201804:	25850513          	addi	a0,a0,600 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201808:	c87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020180c:	00005697          	auipc	a3,0x5
ffffffffc0201810:	3ac68693          	addi	a3,a3,940 # ffffffffc0206bb8 <commands+0x9e0>
ffffffffc0201814:	00005617          	auipc	a2,0x5
ffffffffc0201818:	22c60613          	addi	a2,a2,556 # ffffffffc0206a40 <commands+0x868>
ffffffffc020181c:	12000593          	li	a1,288
ffffffffc0201820:	00005517          	auipc	a0,0x5
ffffffffc0201824:	23850513          	addi	a0,a0,568 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201828:	c67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020182c:	00005697          	auipc	a3,0x5
ffffffffc0201830:	40c68693          	addi	a3,a3,1036 # ffffffffc0206c38 <commands+0xa60>
ffffffffc0201834:	00005617          	auipc	a2,0x5
ffffffffc0201838:	20c60613          	addi	a2,a2,524 # ffffffffc0206a40 <commands+0x868>
ffffffffc020183c:	11b00593          	li	a1,283
ffffffffc0201840:	00005517          	auipc	a0,0x5
ffffffffc0201844:	21850513          	addi	a0,a0,536 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201848:	c47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020184c:	00005697          	auipc	a3,0x5
ffffffffc0201850:	50c68693          	addi	a3,a3,1292 # ffffffffc0206d58 <commands+0xb80>
ffffffffc0201854:	00005617          	auipc	a2,0x5
ffffffffc0201858:	1ec60613          	addi	a2,a2,492 # ffffffffc0206a40 <commands+0x868>
ffffffffc020185c:	13900593          	li	a1,313
ffffffffc0201860:	00005517          	auipc	a0,0x5
ffffffffc0201864:	1f850513          	addi	a0,a0,504 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201868:	c27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020186c:	00005697          	auipc	a3,0x5
ffffffffc0201870:	51c68693          	addi	a3,a3,1308 # ffffffffc0206d88 <commands+0xbb0>
ffffffffc0201874:	00005617          	auipc	a2,0x5
ffffffffc0201878:	1cc60613          	addi	a2,a2,460 # ffffffffc0206a40 <commands+0x868>
ffffffffc020187c:	14900593          	li	a1,329
ffffffffc0201880:	00005517          	auipc	a0,0x5
ffffffffc0201884:	1d850513          	addi	a0,a0,472 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201888:	c07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020188c:	00005697          	auipc	a3,0x5
ffffffffc0201890:	1e468693          	addi	a3,a3,484 # ffffffffc0206a70 <commands+0x898>
ffffffffc0201894:	00005617          	auipc	a2,0x5
ffffffffc0201898:	1ac60613          	addi	a2,a2,428 # ffffffffc0206a40 <commands+0x868>
ffffffffc020189c:	11500593          	li	a1,277
ffffffffc02018a0:	00005517          	auipc	a0,0x5
ffffffffc02018a4:	1b850513          	addi	a0,a0,440 # ffffffffc0206a58 <commands+0x880>
ffffffffc02018a8:	be7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02018ac:	00005697          	auipc	a3,0x5
ffffffffc02018b0:	20468693          	addi	a3,a3,516 # ffffffffc0206ab0 <commands+0x8d8>
ffffffffc02018b4:	00005617          	auipc	a2,0x5
ffffffffc02018b8:	18c60613          	addi	a2,a2,396 # ffffffffc0206a40 <commands+0x868>
ffffffffc02018bc:	0da00593          	li	a1,218
ffffffffc02018c0:	00005517          	auipc	a0,0x5
ffffffffc02018c4:	19850513          	addi	a0,a0,408 # ffffffffc0206a58 <commands+0x880>
ffffffffc02018c8:	bc7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018cc <default_free_pages>:
{
ffffffffc02018cc:	1141                	addi	sp,sp,-16
ffffffffc02018ce:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018d0:	14058c63          	beqz	a1,ffffffffc0201a28 <default_free_pages+0x15c>
    for (; p != base + n; p++)
ffffffffc02018d4:	00359693          	slli	a3,a1,0x3
ffffffffc02018d8:	96ae                	add	a3,a3,a1
ffffffffc02018da:	068e                	slli	a3,a3,0x3
ffffffffc02018dc:	96aa                	add	a3,a3,a0
ffffffffc02018de:	87aa                	mv	a5,a0
ffffffffc02018e0:	02d50463          	beq	a0,a3,ffffffffc0201908 <default_free_pages+0x3c>
ffffffffc02018e4:	6798                	ld	a4,8(a5)
ffffffffc02018e6:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018e8:	12071063          	bnez	a4,ffffffffc0201a08 <default_free_pages+0x13c>
ffffffffc02018ec:	6798                	ld	a4,8(a5)
ffffffffc02018ee:	8b09                	andi	a4,a4,2
ffffffffc02018f0:	10071c63          	bnez	a4,ffffffffc0201a08 <default_free_pages+0x13c>
        p->flags = 0;
ffffffffc02018f4:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02018f8:	0007a023          	sw	zero,0(a5)
        p->lock = 0;
ffffffffc02018fc:	0007b823          	sd	zero,16(a5)
    for (; p != base + n; p++)
ffffffffc0201900:	04878793          	addi	a5,a5,72
ffffffffc0201904:	fed790e3          	bne	a5,a3,ffffffffc02018e4 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201908:	2581                	sext.w	a1,a1
ffffffffc020190a:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc020190c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201910:	4789                	li	a5,2
ffffffffc0201912:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201916:	000b0697          	auipc	a3,0xb0
ffffffffc020191a:	7aa68693          	addi	a3,a3,1962 # ffffffffc02b20c0 <free_area>
ffffffffc020191e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201920:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201922:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc0201926:	9db9                	addw	a1,a1,a4
ffffffffc0201928:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020192a:	0ad78863          	beq	a5,a3,ffffffffc02019da <default_free_pages+0x10e>
            struct Page *page = le2page(le, page_link);
ffffffffc020192e:	fe078713          	addi	a4,a5,-32
ffffffffc0201932:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201936:	4581                	li	a1,0
            if (base < page)
ffffffffc0201938:	00e56a63          	bltu	a0,a4,ffffffffc020194c <default_free_pages+0x80>
    return listelm->next;
ffffffffc020193c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020193e:	06d70263          	beq	a4,a3,ffffffffc02019a2 <default_free_pages+0xd6>
    for (; p != base + n; p++)
ffffffffc0201942:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201944:	fe078713          	addi	a4,a5,-32
            if (base < page)
ffffffffc0201948:	fee57ae3          	bgeu	a0,a4,ffffffffc020193c <default_free_pages+0x70>
ffffffffc020194c:	c199                	beqz	a1,ffffffffc0201952 <default_free_pages+0x86>
ffffffffc020194e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201952:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201954:	e390                	sd	a2,0(a5)
ffffffffc0201956:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201958:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020195a:	f118                	sd	a4,32(a0)
    if (le != &free_list)
ffffffffc020195c:	02d70063          	beq	a4,a3,ffffffffc020197c <default_free_pages+0xb0>
        if (p + p->property == base)
ffffffffc0201960:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201964:	fe070593          	addi	a1,a4,-32
        if (p + p->property == base)
ffffffffc0201968:	02081613          	slli	a2,a6,0x20
ffffffffc020196c:	9201                	srli	a2,a2,0x20
ffffffffc020196e:	00361793          	slli	a5,a2,0x3
ffffffffc0201972:	97b2                	add	a5,a5,a2
ffffffffc0201974:	078e                	slli	a5,a5,0x3
ffffffffc0201976:	97ae                	add	a5,a5,a1
ffffffffc0201978:	02f50f63          	beq	a0,a5,ffffffffc02019b6 <default_free_pages+0xea>
    return listelm->next;
ffffffffc020197c:	7518                	ld	a4,40(a0)
    if (le != &free_list)
ffffffffc020197e:	00d70f63          	beq	a4,a3,ffffffffc020199c <default_free_pages+0xd0>
        if (base + base->property == p)
ffffffffc0201982:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc0201984:	fe070693          	addi	a3,a4,-32
        if (base + base->property == p)
ffffffffc0201988:	02059613          	slli	a2,a1,0x20
ffffffffc020198c:	9201                	srli	a2,a2,0x20
ffffffffc020198e:	00361793          	slli	a5,a2,0x3
ffffffffc0201992:	97b2                	add	a5,a5,a2
ffffffffc0201994:	078e                	slli	a5,a5,0x3
ffffffffc0201996:	97aa                	add	a5,a5,a0
ffffffffc0201998:	04f68863          	beq	a3,a5,ffffffffc02019e8 <default_free_pages+0x11c>
}
ffffffffc020199c:	60a2                	ld	ra,8(sp)
ffffffffc020199e:	0141                	addi	sp,sp,16
ffffffffc02019a0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019a2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019a4:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc02019a6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019a8:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02019aa:	02d70563          	beq	a4,a3,ffffffffc02019d4 <default_free_pages+0x108>
    prev->next = next->prev = elm;
ffffffffc02019ae:	8832                	mv	a6,a2
ffffffffc02019b0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02019b2:	87ba                	mv	a5,a4
ffffffffc02019b4:	bf41                	j	ffffffffc0201944 <default_free_pages+0x78>
            p->property += base->property;
ffffffffc02019b6:	4d1c                	lw	a5,24(a0)
ffffffffc02019b8:	0107883b          	addw	a6,a5,a6
ffffffffc02019bc:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019c0:	57f5                	li	a5,-3
ffffffffc02019c2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019c6:	7110                	ld	a2,32(a0)
ffffffffc02019c8:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc02019ca:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02019cc:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02019ce:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02019d0:	e390                	sd	a2,0(a5)
ffffffffc02019d2:	b775                	j	ffffffffc020197e <default_free_pages+0xb2>
ffffffffc02019d4:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02019d6:	873e                	mv	a4,a5
ffffffffc02019d8:	b761                	j	ffffffffc0201960 <default_free_pages+0x94>
}
ffffffffc02019da:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019dc:	e390                	sd	a2,0(a5)
ffffffffc02019de:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e0:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02019e2:	f11c                	sd	a5,32(a0)
ffffffffc02019e4:	0141                	addi	sp,sp,16
ffffffffc02019e6:	8082                	ret
            base->property += p->property;
ffffffffc02019e8:	ff872783          	lw	a5,-8(a4)
ffffffffc02019ec:	fe870693          	addi	a3,a4,-24
ffffffffc02019f0:	9dbd                	addw	a1,a1,a5
ffffffffc02019f2:	cd0c                	sw	a1,24(a0)
ffffffffc02019f4:	57f5                	li	a5,-3
ffffffffc02019f6:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019fa:	6314                	ld	a3,0(a4)
ffffffffc02019fc:	671c                	ld	a5,8(a4)
}
ffffffffc02019fe:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201a00:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201a02:	e394                	sd	a3,0(a5)
ffffffffc0201a04:	0141                	addi	sp,sp,16
ffffffffc0201a06:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201a08:	00005697          	auipc	a3,0x5
ffffffffc0201a0c:	39868693          	addi	a3,a3,920 # ffffffffc0206da0 <commands+0xbc8>
ffffffffc0201a10:	00005617          	auipc	a2,0x5
ffffffffc0201a14:	03060613          	addi	a2,a2,48 # ffffffffc0206a40 <commands+0x868>
ffffffffc0201a18:	09500593          	li	a1,149
ffffffffc0201a1c:	00005517          	auipc	a0,0x5
ffffffffc0201a20:	03c50513          	addi	a0,a0,60 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201a24:	a6bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a28:	00005697          	auipc	a3,0x5
ffffffffc0201a2c:	37068693          	addi	a3,a3,880 # ffffffffc0206d98 <commands+0xbc0>
ffffffffc0201a30:	00005617          	auipc	a2,0x5
ffffffffc0201a34:	01060613          	addi	a2,a2,16 # ffffffffc0206a40 <commands+0x868>
ffffffffc0201a38:	09100593          	li	a1,145
ffffffffc0201a3c:	00005517          	auipc	a0,0x5
ffffffffc0201a40:	01c50513          	addi	a0,a0,28 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201a44:	a4bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a48 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201a48:	c959                	beqz	a0,ffffffffc0201ade <default_alloc_pages+0x96>
    if (n > nr_free)
ffffffffc0201a4a:	000b0597          	auipc	a1,0xb0
ffffffffc0201a4e:	67658593          	addi	a1,a1,1654 # ffffffffc02b20c0 <free_area>
ffffffffc0201a52:	0105a803          	lw	a6,16(a1)
ffffffffc0201a56:	862a                	mv	a2,a0
ffffffffc0201a58:	02081793          	slli	a5,a6,0x20
ffffffffc0201a5c:	9381                	srli	a5,a5,0x20
ffffffffc0201a5e:	00a7ee63          	bltu	a5,a0,ffffffffc0201a7a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201a62:	87ae                	mv	a5,a1
ffffffffc0201a64:	a801                	j	ffffffffc0201a74 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201a66:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201a6a:	02071693          	slli	a3,a4,0x20
ffffffffc0201a6e:	9281                	srli	a3,a3,0x20
ffffffffc0201a70:	00c6f763          	bgeu	a3,a2,ffffffffc0201a7e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201a74:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201a76:	feb798e3          	bne	a5,a1,ffffffffc0201a66 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201a7a:	4501                	li	a0,0
}
ffffffffc0201a7c:	8082                	ret
    return listelm->prev;
ffffffffc0201a7e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a82:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201a86:	fe078513          	addi	a0,a5,-32
            p->property = page->property - n;
ffffffffc0201a8a:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0201a8e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201a92:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201a96:	02d67b63          	bgeu	a2,a3,ffffffffc0201acc <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0201a9a:	00361693          	slli	a3,a2,0x3
ffffffffc0201a9e:	96b2                	add	a3,a3,a2
ffffffffc0201aa0:	068e                	slli	a3,a3,0x3
ffffffffc0201aa2:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201aa4:	41c7073b          	subw	a4,a4,t3
ffffffffc0201aa8:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201aaa:	00868613          	addi	a2,a3,8
ffffffffc0201aae:	4709                	li	a4,2
ffffffffc0201ab0:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201ab4:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201ab8:	02068613          	addi	a2,a3,32
        nr_free -= n;
ffffffffc0201abc:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201ac0:	e310                	sd	a2,0(a4)
ffffffffc0201ac2:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201ac6:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc0201ac8:	0316b023          	sd	a7,32(a3)
ffffffffc0201acc:	41c8083b          	subw	a6,a6,t3
ffffffffc0201ad0:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201ad4:	5775                	li	a4,-3
ffffffffc0201ad6:	17a1                	addi	a5,a5,-24
ffffffffc0201ad8:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201adc:	8082                	ret
{
ffffffffc0201ade:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201ae0:	00005697          	auipc	a3,0x5
ffffffffc0201ae4:	2b868693          	addi	a3,a3,696 # ffffffffc0206d98 <commands+0xbc0>
ffffffffc0201ae8:	00005617          	auipc	a2,0x5
ffffffffc0201aec:	f5860613          	addi	a2,a2,-168 # ffffffffc0206a40 <commands+0x868>
ffffffffc0201af0:	06d00593          	li	a1,109
ffffffffc0201af4:	00005517          	auipc	a0,0x5
ffffffffc0201af8:	f6450513          	addi	a0,a0,-156 # ffffffffc0206a58 <commands+0x880>
{
ffffffffc0201afc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201afe:	991fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b02 <default_init_memmap>:
{
ffffffffc0201b02:	1141                	addi	sp,sp,-16
ffffffffc0201b04:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201b06:	c9f1                	beqz	a1,ffffffffc0201bda <default_init_memmap+0xd8>
    for (; p != base + n; p++)
ffffffffc0201b08:	00359693          	slli	a3,a1,0x3
ffffffffc0201b0c:	96ae                	add	a3,a3,a1
ffffffffc0201b0e:	068e                	slli	a3,a3,0x3
ffffffffc0201b10:	96aa                	add	a3,a3,a0
ffffffffc0201b12:	87aa                	mv	a5,a0
ffffffffc0201b14:	02d50163          	beq	a0,a3,ffffffffc0201b36 <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201b18:	6798                	ld	a4,8(a5)
ffffffffc0201b1a:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201b1c:	cf59                	beqz	a4,ffffffffc0201bba <default_init_memmap+0xb8>
        p->flags = p->property = 0;
ffffffffc0201b1e:	0007ac23          	sw	zero,24(a5)
ffffffffc0201b22:	0007b423          	sd	zero,8(a5)
ffffffffc0201b26:	0007a023          	sw	zero,0(a5)
        p->lock = 0;
ffffffffc0201b2a:	0007b823          	sd	zero,16(a5)
    for (; p != base + n; p++)
ffffffffc0201b2e:	04878793          	addi	a5,a5,72
ffffffffc0201b32:	fed793e3          	bne	a5,a3,ffffffffc0201b18 <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201b36:	2581                	sext.w	a1,a1
ffffffffc0201b38:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201b3a:	4789                	li	a5,2
ffffffffc0201b3c:	00850713          	addi	a4,a0,8
ffffffffc0201b40:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201b44:	000b0697          	auipc	a3,0xb0
ffffffffc0201b48:	57c68693          	addi	a3,a3,1404 # ffffffffc02b20c0 <free_area>
ffffffffc0201b4c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201b4e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201b50:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc0201b54:	9db9                	addw	a1,a1,a4
ffffffffc0201b56:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201b58:	04d78a63          	beq	a5,a3,ffffffffc0201bac <default_init_memmap+0xaa>
            struct Page *page = le2page(le, page_link);
ffffffffc0201b5c:	fe078713          	addi	a4,a5,-32
ffffffffc0201b60:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201b64:	4581                	li	a1,0
            if (base < page)
ffffffffc0201b66:	00e56a63          	bltu	a0,a4,ffffffffc0201b7a <default_init_memmap+0x78>
    return listelm->next;
ffffffffc0201b6a:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201b6c:	02d70263          	beq	a4,a3,ffffffffc0201b90 <default_init_memmap+0x8e>
    for (; p != base + n; p++)
ffffffffc0201b70:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201b72:	fe078713          	addi	a4,a5,-32
            if (base < page)
ffffffffc0201b76:	fee57ae3          	bgeu	a0,a4,ffffffffc0201b6a <default_init_memmap+0x68>
ffffffffc0201b7a:	c199                	beqz	a1,ffffffffc0201b80 <default_init_memmap+0x7e>
ffffffffc0201b7c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201b80:	6398                	ld	a4,0(a5)
}
ffffffffc0201b82:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201b84:	e390                	sd	a2,0(a5)
ffffffffc0201b86:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201b88:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201b8a:	f118                	sd	a4,32(a0)
ffffffffc0201b8c:	0141                	addi	sp,sp,16
ffffffffc0201b8e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201b90:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201b92:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0201b94:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201b96:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201b98:	00d70663          	beq	a4,a3,ffffffffc0201ba4 <default_init_memmap+0xa2>
    prev->next = next->prev = elm;
ffffffffc0201b9c:	8832                	mv	a6,a2
ffffffffc0201b9e:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ba0:	87ba                	mv	a5,a4
ffffffffc0201ba2:	bfc1                	j	ffffffffc0201b72 <default_init_memmap+0x70>
}
ffffffffc0201ba4:	60a2                	ld	ra,8(sp)
ffffffffc0201ba6:	e290                	sd	a2,0(a3)
ffffffffc0201ba8:	0141                	addi	sp,sp,16
ffffffffc0201baa:	8082                	ret
ffffffffc0201bac:	60a2                	ld	ra,8(sp)
ffffffffc0201bae:	e390                	sd	a2,0(a5)
ffffffffc0201bb0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201bb2:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201bb4:	f11c                	sd	a5,32(a0)
ffffffffc0201bb6:	0141                	addi	sp,sp,16
ffffffffc0201bb8:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201bba:	00005697          	auipc	a3,0x5
ffffffffc0201bbe:	20e68693          	addi	a3,a3,526 # ffffffffc0206dc8 <commands+0xbf0>
ffffffffc0201bc2:	00005617          	auipc	a2,0x5
ffffffffc0201bc6:	e7e60613          	addi	a2,a2,-386 # ffffffffc0206a40 <commands+0x868>
ffffffffc0201bca:	04b00593          	li	a1,75
ffffffffc0201bce:	00005517          	auipc	a0,0x5
ffffffffc0201bd2:	e8a50513          	addi	a0,a0,-374 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201bd6:	8b9fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201bda:	00005697          	auipc	a3,0x5
ffffffffc0201bde:	1be68693          	addi	a3,a3,446 # ffffffffc0206d98 <commands+0xbc0>
ffffffffc0201be2:	00005617          	auipc	a2,0x5
ffffffffc0201be6:	e5e60613          	addi	a2,a2,-418 # ffffffffc0206a40 <commands+0x868>
ffffffffc0201bea:	04700593          	li	a1,71
ffffffffc0201bee:	00005517          	auipc	a0,0x5
ffffffffc0201bf2:	e6a50513          	addi	a0,a0,-406 # ffffffffc0206a58 <commands+0x880>
ffffffffc0201bf6:	899fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201bfa <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201bfa:	c94d                	beqz	a0,ffffffffc0201cac <slob_free+0xb2>
{
ffffffffc0201bfc:	1141                	addi	sp,sp,-16
ffffffffc0201bfe:	e022                	sd	s0,0(sp)
ffffffffc0201c00:	e406                	sd	ra,8(sp)
ffffffffc0201c02:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201c04:	e9c1                	bnez	a1,ffffffffc0201c94 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c06:	100027f3          	csrr	a5,sstatus
ffffffffc0201c0a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201c0c:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c0e:	ebd9                	bnez	a5,ffffffffc0201ca4 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201c10:	000b0617          	auipc	a2,0xb0
ffffffffc0201c14:	0a060613          	addi	a2,a2,160 # ffffffffc02b1cb0 <slobfree>
ffffffffc0201c18:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c1a:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201c1c:	679c                	ld	a5,8(a5)
ffffffffc0201c1e:	02877a63          	bgeu	a4,s0,ffffffffc0201c52 <slob_free+0x58>
ffffffffc0201c22:	00f46463          	bltu	s0,a5,ffffffffc0201c2a <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c26:	fef76ae3          	bltu	a4,a5,ffffffffc0201c1a <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201c2a:	400c                	lw	a1,0(s0)
ffffffffc0201c2c:	00459693          	slli	a3,a1,0x4
ffffffffc0201c30:	96a2                	add	a3,a3,s0
ffffffffc0201c32:	02d78a63          	beq	a5,a3,ffffffffc0201c66 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201c36:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201c38:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201c3a:	00469793          	slli	a5,a3,0x4
ffffffffc0201c3e:	97ba                	add	a5,a5,a4
ffffffffc0201c40:	02f40e63          	beq	s0,a5,ffffffffc0201c7c <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201c44:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201c46:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201c48:	e129                	bnez	a0,ffffffffc0201c8a <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201c4a:	60a2                	ld	ra,8(sp)
ffffffffc0201c4c:	6402                	ld	s0,0(sp)
ffffffffc0201c4e:	0141                	addi	sp,sp,16
ffffffffc0201c50:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c52:	fcf764e3          	bltu	a4,a5,ffffffffc0201c1a <slob_free+0x20>
ffffffffc0201c56:	fcf472e3          	bgeu	s0,a5,ffffffffc0201c1a <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201c5a:	400c                	lw	a1,0(s0)
ffffffffc0201c5c:	00459693          	slli	a3,a1,0x4
ffffffffc0201c60:	96a2                	add	a3,a3,s0
ffffffffc0201c62:	fcd79ae3          	bne	a5,a3,ffffffffc0201c36 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201c66:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201c68:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201c6a:	9db5                	addw	a1,a1,a3
ffffffffc0201c6c:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201c6e:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201c70:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201c72:	00469793          	slli	a5,a3,0x4
ffffffffc0201c76:	97ba                	add	a5,a5,a4
ffffffffc0201c78:	fcf416e3          	bne	s0,a5,ffffffffc0201c44 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201c7c:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201c7e:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201c80:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201c82:	9ebd                	addw	a3,a3,a5
ffffffffc0201c84:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201c86:	e70c                	sd	a1,8(a4)
ffffffffc0201c88:	d169                	beqz	a0,ffffffffc0201c4a <slob_free+0x50>
}
ffffffffc0201c8a:	6402                	ld	s0,0(sp)
ffffffffc0201c8c:	60a2                	ld	ra,8(sp)
ffffffffc0201c8e:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201c90:	d1ffe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201c94:	25bd                	addiw	a1,a1,15
ffffffffc0201c96:	8191                	srli	a1,a1,0x4
ffffffffc0201c98:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c9e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ca0:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ca2:	d7bd                	beqz	a5,ffffffffc0201c10 <slob_free+0x16>
        intr_disable();
ffffffffc0201ca4:	d11fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201ca8:	4505                	li	a0,1
ffffffffc0201caa:	b79d                	j	ffffffffc0201c10 <slob_free+0x16>
ffffffffc0201cac:	8082                	ret

ffffffffc0201cae <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201cae:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201cb0:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201cb2:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201cb6:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201cb8:	364000ef          	jal	ra,ffffffffc020201c <alloc_pages>
	if (!page)
ffffffffc0201cbc:	c129                	beqz	a0,ffffffffc0201cfe <__slob_get_free_pages.constprop.0+0x50>
    return page - pages + nbase;
ffffffffc0201cbe:	000b4697          	auipc	a3,0xb4
ffffffffc0201cc2:	47a6b683          	ld	a3,1146(a3) # ffffffffc02b6138 <pages>
ffffffffc0201cc6:	8d15                	sub	a0,a0,a3
ffffffffc0201cc8:	850d                	srai	a0,a0,0x3
ffffffffc0201cca:	00006697          	auipc	a3,0x6
ffffffffc0201cce:	4de6b683          	ld	a3,1246(a3) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0201cd2:	02d50533          	mul	a0,a0,a3
ffffffffc0201cd6:	00006697          	auipc	a3,0x6
ffffffffc0201cda:	4da6b683          	ld	a3,1242(a3) # ffffffffc02081b0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201cde:	000b4717          	auipc	a4,0xb4
ffffffffc0201ce2:	45273703          	ld	a4,1106(a4) # ffffffffc02b6130 <npage>
    return page - pages + nbase;
ffffffffc0201ce6:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201ce8:	00c51793          	slli	a5,a0,0xc
ffffffffc0201cec:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201cee:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201cf0:	00e7fa63          	bgeu	a5,a4,ffffffffc0201d04 <__slob_get_free_pages.constprop.0+0x56>
ffffffffc0201cf4:	000b4697          	auipc	a3,0xb4
ffffffffc0201cf8:	4546b683          	ld	a3,1108(a3) # ffffffffc02b6148 <va_pa_offset>
ffffffffc0201cfc:	9536                	add	a0,a0,a3
}
ffffffffc0201cfe:	60a2                	ld	ra,8(sp)
ffffffffc0201d00:	0141                	addi	sp,sp,16
ffffffffc0201d02:	8082                	ret
ffffffffc0201d04:	86aa                	mv	a3,a0
ffffffffc0201d06:	00005617          	auipc	a2,0x5
ffffffffc0201d0a:	12260613          	addi	a2,a2,290 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0201d0e:	08300593          	li	a1,131
ffffffffc0201d12:	00005517          	auipc	a0,0x5
ffffffffc0201d16:	13e50513          	addi	a0,a0,318 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0201d1a:	f74fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d1e <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201d1e:	1101                	addi	sp,sp,-32
ffffffffc0201d20:	ec06                	sd	ra,24(sp)
ffffffffc0201d22:	e822                	sd	s0,16(sp)
ffffffffc0201d24:	e426                	sd	s1,8(sp)
ffffffffc0201d26:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d28:	01050713          	addi	a4,a0,16
ffffffffc0201d2c:	6785                	lui	a5,0x1
ffffffffc0201d2e:	0cf77363          	bgeu	a4,a5,ffffffffc0201df4 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201d32:	00f50493          	addi	s1,a0,15
ffffffffc0201d36:	8091                	srli	s1,s1,0x4
ffffffffc0201d38:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d3a:	10002673          	csrr	a2,sstatus
ffffffffc0201d3e:	8a09                	andi	a2,a2,2
ffffffffc0201d40:	e25d                	bnez	a2,ffffffffc0201de6 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201d42:	000b0917          	auipc	s2,0xb0
ffffffffc0201d46:	f6e90913          	addi	s2,s2,-146 # ffffffffc02b1cb0 <slobfree>
ffffffffc0201d4a:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201d4e:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201d50:	4398                	lw	a4,0(a5)
ffffffffc0201d52:	08975e63          	bge	a4,s1,ffffffffc0201dee <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201d56:	00f68b63          	beq	a3,a5,ffffffffc0201d6c <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201d5a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201d5c:	4018                	lw	a4,0(s0)
ffffffffc0201d5e:	02975a63          	bge	a4,s1,ffffffffc0201d92 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201d62:	00093683          	ld	a3,0(s2)
ffffffffc0201d66:	87a2                	mv	a5,s0
ffffffffc0201d68:	fef699e3          	bne	a3,a5,ffffffffc0201d5a <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201d6c:	ee31                	bnez	a2,ffffffffc0201dc8 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201d6e:	4501                	li	a0,0
ffffffffc0201d70:	f3fff0ef          	jal	ra,ffffffffc0201cae <__slob_get_free_pages.constprop.0>
ffffffffc0201d74:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201d76:	cd05                	beqz	a0,ffffffffc0201dae <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201d78:	6585                	lui	a1,0x1
ffffffffc0201d7a:	e81ff0ef          	jal	ra,ffffffffc0201bfa <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d7e:	10002673          	csrr	a2,sstatus
ffffffffc0201d82:	8a09                	andi	a2,a2,2
ffffffffc0201d84:	ee05                	bnez	a2,ffffffffc0201dbc <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201d86:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201d8a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201d8c:	4018                	lw	a4,0(s0)
ffffffffc0201d8e:	fc974ae3          	blt	a4,s1,ffffffffc0201d62 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201d92:	04e48763          	beq	s1,a4,ffffffffc0201de0 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201d96:	00449693          	slli	a3,s1,0x4
ffffffffc0201d9a:	96a2                	add	a3,a3,s0
ffffffffc0201d9c:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201d9e:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201da0:	9f05                	subw	a4,a4,s1
ffffffffc0201da2:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201da4:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201da6:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201da8:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201dac:	e20d                	bnez	a2,ffffffffc0201dce <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201dae:	60e2                	ld	ra,24(sp)
ffffffffc0201db0:	8522                	mv	a0,s0
ffffffffc0201db2:	6442                	ld	s0,16(sp)
ffffffffc0201db4:	64a2                	ld	s1,8(sp)
ffffffffc0201db6:	6902                	ld	s2,0(sp)
ffffffffc0201db8:	6105                	addi	sp,sp,32
ffffffffc0201dba:	8082                	ret
        intr_disable();
ffffffffc0201dbc:	bf9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201dc0:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201dc4:	4605                	li	a2,1
ffffffffc0201dc6:	b7d1                	j	ffffffffc0201d8a <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201dc8:	be7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201dcc:	b74d                	j	ffffffffc0201d6e <slob_alloc.constprop.0+0x50>
ffffffffc0201dce:	be1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201dd2:	60e2                	ld	ra,24(sp)
ffffffffc0201dd4:	8522                	mv	a0,s0
ffffffffc0201dd6:	6442                	ld	s0,16(sp)
ffffffffc0201dd8:	64a2                	ld	s1,8(sp)
ffffffffc0201dda:	6902                	ld	s2,0(sp)
ffffffffc0201ddc:	6105                	addi	sp,sp,32
ffffffffc0201dde:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201de0:	6418                	ld	a4,8(s0)
ffffffffc0201de2:	e798                	sd	a4,8(a5)
ffffffffc0201de4:	b7d1                	j	ffffffffc0201da8 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201de6:	bcffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201dea:	4605                	li	a2,1
ffffffffc0201dec:	bf99                	j	ffffffffc0201d42 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201dee:	843e                	mv	s0,a5
ffffffffc0201df0:	87b6                	mv	a5,a3
ffffffffc0201df2:	b745                	j	ffffffffc0201d92 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201df4:	00005697          	auipc	a3,0x5
ffffffffc0201df8:	06c68693          	addi	a3,a3,108 # ffffffffc0206e60 <default_pmm_manager+0x70>
ffffffffc0201dfc:	00005617          	auipc	a2,0x5
ffffffffc0201e00:	c4460613          	addi	a2,a2,-956 # ffffffffc0206a40 <commands+0x868>
ffffffffc0201e04:	06300593          	li	a1,99
ffffffffc0201e08:	00005517          	auipc	a0,0x5
ffffffffc0201e0c:	07850513          	addi	a0,a0,120 # ffffffffc0206e80 <default_pmm_manager+0x90>
ffffffffc0201e10:	e7efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e14 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201e14:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201e16:	00005517          	auipc	a0,0x5
ffffffffc0201e1a:	08250513          	addi	a0,a0,130 # ffffffffc0206e98 <default_pmm_manager+0xa8>
{
ffffffffc0201e1e:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201e20:	b74fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201e24:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201e26:	00005517          	auipc	a0,0x5
ffffffffc0201e2a:	08a50513          	addi	a0,a0,138 # ffffffffc0206eb0 <default_pmm_manager+0xc0>
}
ffffffffc0201e2e:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201e30:	b64fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201e34 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201e34:	4501                	li	a0,0
ffffffffc0201e36:	8082                	ret

ffffffffc0201e38 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201e38:	1101                	addi	sp,sp,-32
ffffffffc0201e3a:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201e3c:	6905                	lui	s2,0x1
{
ffffffffc0201e3e:	e822                	sd	s0,16(sp)
ffffffffc0201e40:	ec06                	sd	ra,24(sp)
ffffffffc0201e42:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201e44:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bd1>
{
ffffffffc0201e48:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201e4a:	04a7f963          	bgeu	a5,a0,ffffffffc0201e9c <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201e4e:	4561                	li	a0,24
ffffffffc0201e50:	ecfff0ef          	jal	ra,ffffffffc0201d1e <slob_alloc.constprop.0>
ffffffffc0201e54:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201e56:	c929                	beqz	a0,ffffffffc0201ea8 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201e58:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201e5c:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201e5e:	00f95763          	bge	s2,a5,ffffffffc0201e6c <kmalloc+0x34>
ffffffffc0201e62:	6705                	lui	a4,0x1
ffffffffc0201e64:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201e66:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201e68:	fef74ee3          	blt	a4,a5,ffffffffc0201e64 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201e6c:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201e6e:	e41ff0ef          	jal	ra,ffffffffc0201cae <__slob_get_free_pages.constprop.0>
ffffffffc0201e72:	e488                	sd	a0,8(s1)
ffffffffc0201e74:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201e76:	c525                	beqz	a0,ffffffffc0201ede <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e78:	100027f3          	csrr	a5,sstatus
ffffffffc0201e7c:	8b89                	andi	a5,a5,2
ffffffffc0201e7e:	ef8d                	bnez	a5,ffffffffc0201eb8 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201e80:	000b4797          	auipc	a5,0xb4
ffffffffc0201e84:	29878793          	addi	a5,a5,664 # ffffffffc02b6118 <bigblocks>
ffffffffc0201e88:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201e8a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201e8c:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201e8e:	60e2                	ld	ra,24(sp)
ffffffffc0201e90:	8522                	mv	a0,s0
ffffffffc0201e92:	6442                	ld	s0,16(sp)
ffffffffc0201e94:	64a2                	ld	s1,8(sp)
ffffffffc0201e96:	6902                	ld	s2,0(sp)
ffffffffc0201e98:	6105                	addi	sp,sp,32
ffffffffc0201e9a:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201e9c:	0541                	addi	a0,a0,16
ffffffffc0201e9e:	e81ff0ef          	jal	ra,ffffffffc0201d1e <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201ea2:	01050413          	addi	s0,a0,16
ffffffffc0201ea6:	f565                	bnez	a0,ffffffffc0201e8e <kmalloc+0x56>
ffffffffc0201ea8:	4401                	li	s0,0
}
ffffffffc0201eaa:	60e2                	ld	ra,24(sp)
ffffffffc0201eac:	8522                	mv	a0,s0
ffffffffc0201eae:	6442                	ld	s0,16(sp)
ffffffffc0201eb0:	64a2                	ld	s1,8(sp)
ffffffffc0201eb2:	6902                	ld	s2,0(sp)
ffffffffc0201eb4:	6105                	addi	sp,sp,32
ffffffffc0201eb6:	8082                	ret
        intr_disable();
ffffffffc0201eb8:	afdfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ebc:	000b4797          	auipc	a5,0xb4
ffffffffc0201ec0:	25c78793          	addi	a5,a5,604 # ffffffffc02b6118 <bigblocks>
ffffffffc0201ec4:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201ec6:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201ec8:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201eca:	ae5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201ece:	6480                	ld	s0,8(s1)
}
ffffffffc0201ed0:	60e2                	ld	ra,24(sp)
ffffffffc0201ed2:	64a2                	ld	s1,8(sp)
ffffffffc0201ed4:	8522                	mv	a0,s0
ffffffffc0201ed6:	6442                	ld	s0,16(sp)
ffffffffc0201ed8:	6902                	ld	s2,0(sp)
ffffffffc0201eda:	6105                	addi	sp,sp,32
ffffffffc0201edc:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ede:	45e1                	li	a1,24
ffffffffc0201ee0:	8526                	mv	a0,s1
ffffffffc0201ee2:	d19ff0ef          	jal	ra,ffffffffc0201bfa <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201ee6:	b765                	j	ffffffffc0201e8e <kmalloc+0x56>

ffffffffc0201ee8 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201ee8:	c561                	beqz	a0,ffffffffc0201fb0 <kfree+0xc8>
{
ffffffffc0201eea:	1101                	addi	sp,sp,-32
ffffffffc0201eec:	e822                	sd	s0,16(sp)
ffffffffc0201eee:	ec06                	sd	ra,24(sp)
ffffffffc0201ef0:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201ef2:	03451793          	slli	a5,a0,0x34
ffffffffc0201ef6:	842a                	mv	s0,a0
ffffffffc0201ef8:	e7d1                	bnez	a5,ffffffffc0201f84 <kfree+0x9c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201efa:	100027f3          	csrr	a5,sstatus
ffffffffc0201efe:	8b89                	andi	a5,a5,2
ffffffffc0201f00:	ebd1                	bnez	a5,ffffffffc0201f94 <kfree+0xac>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f02:	000b4797          	auipc	a5,0xb4
ffffffffc0201f06:	2167b783          	ld	a5,534(a5) # ffffffffc02b6118 <bigblocks>
    return 0;
ffffffffc0201f0a:	4601                	li	a2,0
ffffffffc0201f0c:	cfa5                	beqz	a5,ffffffffc0201f84 <kfree+0x9c>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201f0e:	000b4697          	auipc	a3,0xb4
ffffffffc0201f12:	20a68693          	addi	a3,a3,522 # ffffffffc02b6118 <bigblocks>
ffffffffc0201f16:	a021                	j	ffffffffc0201f1e <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f18:	01048693          	addi	a3,s1,16
ffffffffc0201f1c:	c3bd                	beqz	a5,ffffffffc0201f82 <kfree+0x9a>
		{
			if (bb->pages == block)
ffffffffc0201f1e:	6798                	ld	a4,8(a5)
ffffffffc0201f20:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201f22:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201f24:	fe871ae3          	bne	a4,s0,ffffffffc0201f18 <kfree+0x30>
				*last = bb->next;
ffffffffc0201f28:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201f2a:	e241                	bnez	a2,ffffffffc0201faa <kfree+0xc2>
    return pa2page(PADDR(kva));
ffffffffc0201f2c:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201f30:	4098                	lw	a4,0(s1)
ffffffffc0201f32:	08f46c63          	bltu	s0,a5,ffffffffc0201fca <kfree+0xe2>
ffffffffc0201f36:	000b4697          	auipc	a3,0xb4
ffffffffc0201f3a:	2126b683          	ld	a3,530(a3) # ffffffffc02b6148 <va_pa_offset>
ffffffffc0201f3e:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201f40:	8031                	srli	s0,s0,0xc
ffffffffc0201f42:	000b4797          	auipc	a5,0xb4
ffffffffc0201f46:	1ee7b783          	ld	a5,494(a5) # ffffffffc02b6130 <npage>
ffffffffc0201f4a:	06f47463          	bgeu	s0,a5,ffffffffc0201fb2 <kfree+0xca>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f4e:	00006797          	auipc	a5,0x6
ffffffffc0201f52:	2627b783          	ld	a5,610(a5) # ffffffffc02081b0 <nbase>
ffffffffc0201f56:	8c1d                	sub	s0,s0,a5
ffffffffc0201f58:	00341513          	slli	a0,s0,0x3
ffffffffc0201f5c:	942a                	add	s0,s0,a0
ffffffffc0201f5e:	040e                	slli	s0,s0,0x3
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201f60:	000b4517          	auipc	a0,0xb4
ffffffffc0201f64:	1d853503          	ld	a0,472(a0) # ffffffffc02b6138 <pages>
ffffffffc0201f68:	4585                	li	a1,1
ffffffffc0201f6a:	9522                	add	a0,a0,s0
ffffffffc0201f6c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201f70:	0ea000ef          	jal	ra,ffffffffc020205a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201f74:	6442                	ld	s0,16(sp)
ffffffffc0201f76:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f78:	8526                	mv	a0,s1
}
ffffffffc0201f7a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f7c:	45e1                	li	a1,24
}
ffffffffc0201f7e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201f80:	b9ad                	j	ffffffffc0201bfa <slob_free>
ffffffffc0201f82:	e20d                	bnez	a2,ffffffffc0201fa4 <kfree+0xbc>
ffffffffc0201f84:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201f88:	6442                	ld	s0,16(sp)
ffffffffc0201f8a:	60e2                	ld	ra,24(sp)
ffffffffc0201f8c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201f8e:	4581                	li	a1,0
}
ffffffffc0201f90:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201f92:	b1a5                	j	ffffffffc0201bfa <slob_free>
        intr_disable();
ffffffffc0201f94:	a21fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f98:	000b4797          	auipc	a5,0xb4
ffffffffc0201f9c:	1807b783          	ld	a5,384(a5) # ffffffffc02b6118 <bigblocks>
        return 1;
ffffffffc0201fa0:	4605                	li	a2,1
ffffffffc0201fa2:	f7b5                	bnez	a5,ffffffffc0201f0e <kfree+0x26>
        intr_enable();
ffffffffc0201fa4:	a0bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201fa8:	bff1                	j	ffffffffc0201f84 <kfree+0x9c>
ffffffffc0201faa:	a05fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201fae:	bfbd                	j	ffffffffc0201f2c <kfree+0x44>
ffffffffc0201fb0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201fb2:	00005617          	auipc	a2,0x5
ffffffffc0201fb6:	f4660613          	addi	a2,a2,-186 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc0201fba:	07b00593          	li	a1,123
ffffffffc0201fbe:	00005517          	auipc	a0,0x5
ffffffffc0201fc2:	e9250513          	addi	a0,a0,-366 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0201fc6:	cc8fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201fca:	86a2                	mv	a3,s0
ffffffffc0201fcc:	00005617          	auipc	a2,0x5
ffffffffc0201fd0:	f0460613          	addi	a2,a2,-252 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0201fd4:	08900593          	li	a1,137
ffffffffc0201fd8:	00005517          	auipc	a0,0x5
ffffffffc0201fdc:	e7850513          	addi	a0,a0,-392 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0201fe0:	caefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201fe4 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201fe4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201fe6:	00005617          	auipc	a2,0x5
ffffffffc0201fea:	f1260613          	addi	a2,a2,-238 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc0201fee:	07b00593          	li	a1,123
ffffffffc0201ff2:	00005517          	auipc	a0,0x5
ffffffffc0201ff6:	e5e50513          	addi	a0,a0,-418 # ffffffffc0206e50 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201ffa:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201ffc:	c92fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202000 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0202000:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0202002:	00005617          	auipc	a2,0x5
ffffffffc0202006:	f1660613          	addi	a2,a2,-234 # ffffffffc0206f18 <default_pmm_manager+0x128>
ffffffffc020200a:	09100593          	li	a1,145
ffffffffc020200e:	00005517          	auipc	a0,0x5
ffffffffc0202012:	e4250513          	addi	a0,a0,-446 # ffffffffc0206e50 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0202016:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202018:	c76fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020201c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020201c:	100027f3          	csrr	a5,sstatus
ffffffffc0202020:	8b89                	andi	a5,a5,2
ffffffffc0202022:	e799                	bnez	a5,ffffffffc0202030 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0202024:	000b4797          	auipc	a5,0xb4
ffffffffc0202028:	11c7b783          	ld	a5,284(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc020202c:	6f9c                	ld	a5,24(a5)
ffffffffc020202e:	8782                	jr	a5
{
ffffffffc0202030:	1141                	addi	sp,sp,-16
ffffffffc0202032:	e406                	sd	ra,8(sp)
ffffffffc0202034:	e022                	sd	s0,0(sp)
ffffffffc0202036:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0202038:	97dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020203c:	000b4797          	auipc	a5,0xb4
ffffffffc0202040:	1047b783          	ld	a5,260(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202044:	6f9c                	ld	a5,24(a5)
ffffffffc0202046:	8522                	mv	a0,s0
ffffffffc0202048:	9782                	jalr	a5
ffffffffc020204a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020204c:	963fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0202050:	60a2                	ld	ra,8(sp)
ffffffffc0202052:	8522                	mv	a0,s0
ffffffffc0202054:	6402                	ld	s0,0(sp)
ffffffffc0202056:	0141                	addi	sp,sp,16
ffffffffc0202058:	8082                	ret

ffffffffc020205a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020205a:	100027f3          	csrr	a5,sstatus
ffffffffc020205e:	8b89                	andi	a5,a5,2
ffffffffc0202060:	e799                	bnez	a5,ffffffffc020206e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0202062:	000b4797          	auipc	a5,0xb4
ffffffffc0202066:	0de7b783          	ld	a5,222(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc020206a:	739c                	ld	a5,32(a5)
ffffffffc020206c:	8782                	jr	a5
{
ffffffffc020206e:	1101                	addi	sp,sp,-32
ffffffffc0202070:	ec06                	sd	ra,24(sp)
ffffffffc0202072:	e822                	sd	s0,16(sp)
ffffffffc0202074:	e426                	sd	s1,8(sp)
ffffffffc0202076:	842a                	mv	s0,a0
ffffffffc0202078:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020207a:	93bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020207e:	000b4797          	auipc	a5,0xb4
ffffffffc0202082:	0c27b783          	ld	a5,194(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202086:	739c                	ld	a5,32(a5)
ffffffffc0202088:	85a6                	mv	a1,s1
ffffffffc020208a:	8522                	mv	a0,s0
ffffffffc020208c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020208e:	6442                	ld	s0,16(sp)
ffffffffc0202090:	60e2                	ld	ra,24(sp)
ffffffffc0202092:	64a2                	ld	s1,8(sp)
ffffffffc0202094:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0202096:	919fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc020209a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020209a:	100027f3          	csrr	a5,sstatus
ffffffffc020209e:	8b89                	andi	a5,a5,2
ffffffffc02020a0:	e799                	bnez	a5,ffffffffc02020ae <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02020a2:	000b4797          	auipc	a5,0xb4
ffffffffc02020a6:	09e7b783          	ld	a5,158(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc02020aa:	779c                	ld	a5,40(a5)
ffffffffc02020ac:	8782                	jr	a5
{
ffffffffc02020ae:	1141                	addi	sp,sp,-16
ffffffffc02020b0:	e406                	sd	ra,8(sp)
ffffffffc02020b2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02020b4:	901fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02020b8:	000b4797          	auipc	a5,0xb4
ffffffffc02020bc:	0887b783          	ld	a5,136(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc02020c0:	779c                	ld	a5,40(a5)
ffffffffc02020c2:	9782                	jalr	a5
ffffffffc02020c4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020c6:	8e9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02020ca:	60a2                	ld	ra,8(sp)
ffffffffc02020cc:	8522                	mv	a0,s0
ffffffffc02020ce:	6402                	ld	s0,0(sp)
ffffffffc02020d0:	0141                	addi	sp,sp,16
ffffffffc02020d2:	8082                	ret

ffffffffc02020d4 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02020d4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02020d8:	1ff7f793          	andi	a5,a5,511
{
ffffffffc02020dc:	715d                	addi	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02020de:	078e                	slli	a5,a5,0x3
{
ffffffffc02020e0:	fc26                	sd	s1,56(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02020e2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc02020e6:	6094                	ld	a3,0(s1)
{
ffffffffc02020e8:	f84a                	sd	s2,48(sp)
ffffffffc02020ea:	f44e                	sd	s3,40(sp)
ffffffffc02020ec:	f052                	sd	s4,32(sp)
ffffffffc02020ee:	e486                	sd	ra,72(sp)
ffffffffc02020f0:	e0a2                	sd	s0,64(sp)
ffffffffc02020f2:	ec56                	sd	s5,24(sp)
ffffffffc02020f4:	e85a                	sd	s6,16(sp)
ffffffffc02020f6:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc02020f8:	0016f793          	andi	a5,a3,1
{
ffffffffc02020fc:	892e                	mv	s2,a1
ffffffffc02020fe:	8a32                	mv	s4,a2
ffffffffc0202100:	000b4997          	auipc	s3,0xb4
ffffffffc0202104:	03098993          	addi	s3,s3,48 # ffffffffc02b6130 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202108:	e7d9                	bnez	a5,ffffffffc0202196 <get_pte+0xc2>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020210a:	16060d63          	beqz	a2,ffffffffc0202284 <get_pte+0x1b0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020210e:	100027f3          	csrr	a5,sstatus
ffffffffc0202112:	8b89                	andi	a5,a5,2
ffffffffc0202114:	16079a63          	bnez	a5,ffffffffc0202288 <get_pte+0x1b4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202118:	000b4797          	auipc	a5,0xb4
ffffffffc020211c:	0287b783          	ld	a5,40(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202120:	6f9c                	ld	a5,24(a5)
ffffffffc0202122:	4505                	li	a0,1
ffffffffc0202124:	9782                	jalr	a5
ffffffffc0202126:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202128:	14040e63          	beqz	s0,ffffffffc0202284 <get_pte+0x1b0>
    return page - pages + nbase;
ffffffffc020212c:	000b4b97          	auipc	s7,0xb4
ffffffffc0202130:	00cb8b93          	addi	s7,s7,12 # ffffffffc02b6138 <pages>
ffffffffc0202134:	000bb503          	ld	a0,0(s7)
ffffffffc0202138:	00006b17          	auipc	s6,0x6
ffffffffc020213c:	070b3b03          	ld	s6,112(s6) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0202140:	00080ab7          	lui	s5,0x80
ffffffffc0202144:	40a40533          	sub	a0,s0,a0
ffffffffc0202148:	850d                	srai	a0,a0,0x3
ffffffffc020214a:	03650533          	mul	a0,a0,s6
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020214e:	000b4997          	auipc	s3,0xb4
ffffffffc0202152:	fe298993          	addi	s3,s3,-30 # ffffffffc02b6130 <npage>
    page->ref = val;
ffffffffc0202156:	4785                	li	a5,1
ffffffffc0202158:	0009b703          	ld	a4,0(s3)
ffffffffc020215c:	c01c                	sw	a5,0(s0)
    return page - pages + nbase;
ffffffffc020215e:	9556                	add	a0,a0,s5
ffffffffc0202160:	00c51793          	slli	a5,a0,0xc
ffffffffc0202164:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202166:	0532                	slli	a0,a0,0xc
ffffffffc0202168:	18e7f263          	bgeu	a5,a4,ffffffffc02022ec <get_pte+0x218>
ffffffffc020216c:	000b4797          	auipc	a5,0xb4
ffffffffc0202170:	fdc7b783          	ld	a5,-36(a5) # ffffffffc02b6148 <va_pa_offset>
ffffffffc0202174:	6605                	lui	a2,0x1
ffffffffc0202176:	4581                	li	a1,0
ffffffffc0202178:	953e                	add	a0,a0,a5
ffffffffc020217a:	5c7030ef          	jal	ra,ffffffffc0205f40 <memset>
    return page - pages + nbase;
ffffffffc020217e:	000bb683          	ld	a3,0(s7)
ffffffffc0202182:	40d406b3          	sub	a3,s0,a3
ffffffffc0202186:	868d                	srai	a3,a3,0x3
ffffffffc0202188:	036686b3          	mul	a3,a3,s6
ffffffffc020218c:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020218e:	06aa                	slli	a3,a3,0xa
ffffffffc0202190:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202194:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202196:	77fd                	lui	a5,0xfffff
ffffffffc0202198:	068a                	slli	a3,a3,0x2
ffffffffc020219a:	0009b703          	ld	a4,0(s3)
ffffffffc020219e:	8efd                	and	a3,a3,a5
ffffffffc02021a0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02021a4:	12e7f863          	bgeu	a5,a4,ffffffffc02022d4 <get_pte+0x200>
ffffffffc02021a8:	000b4a97          	auipc	s5,0xb4
ffffffffc02021ac:	fa0a8a93          	addi	s5,s5,-96 # ffffffffc02b6148 <va_pa_offset>
ffffffffc02021b0:	000ab403          	ld	s0,0(s5)
ffffffffc02021b4:	01595793          	srli	a5,s2,0x15
ffffffffc02021b8:	1ff7f793          	andi	a5,a5,511
ffffffffc02021bc:	96a2                	add	a3,a3,s0
ffffffffc02021be:	00379413          	slli	s0,a5,0x3
ffffffffc02021c2:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02021c4:	6014                	ld	a3,0(s0)
ffffffffc02021c6:	0016f793          	andi	a5,a3,1
ffffffffc02021ca:	e3c9                	bnez	a5,ffffffffc020224c <get_pte+0x178>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02021cc:	0a0a0c63          	beqz	s4,ffffffffc0202284 <get_pte+0x1b0>
ffffffffc02021d0:	100027f3          	csrr	a5,sstatus
ffffffffc02021d4:	8b89                	andi	a5,a5,2
ffffffffc02021d6:	e7f1                	bnez	a5,ffffffffc02022a2 <get_pte+0x1ce>
        page = pmm_manager->alloc_pages(n);
ffffffffc02021d8:	000b4797          	auipc	a5,0xb4
ffffffffc02021dc:	f687b783          	ld	a5,-152(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc02021e0:	6f9c                	ld	a5,24(a5)
ffffffffc02021e2:	4505                	li	a0,1
ffffffffc02021e4:	9782                	jalr	a5
ffffffffc02021e6:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02021e8:	ccd1                	beqz	s1,ffffffffc0202284 <get_pte+0x1b0>
    return page - pages + nbase;
ffffffffc02021ea:	000b4b97          	auipc	s7,0xb4
ffffffffc02021ee:	f4eb8b93          	addi	s7,s7,-178 # ffffffffc02b6138 <pages>
ffffffffc02021f2:	000bb503          	ld	a0,0(s7)
ffffffffc02021f6:	00006b17          	auipc	s6,0x6
ffffffffc02021fa:	fb2b3b03          	ld	s6,-78(s6) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc02021fe:	00080a37          	lui	s4,0x80
ffffffffc0202202:	40a48533          	sub	a0,s1,a0
ffffffffc0202206:	850d                	srai	a0,a0,0x3
ffffffffc0202208:	03650533          	mul	a0,a0,s6
    page->ref = val;
ffffffffc020220c:	4785                	li	a5,1
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020220e:	0009b703          	ld	a4,0(s3)
ffffffffc0202212:	c09c                	sw	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202214:	9552                	add	a0,a0,s4
ffffffffc0202216:	00c51793          	slli	a5,a0,0xc
ffffffffc020221a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020221c:	0532                	slli	a0,a0,0xc
ffffffffc020221e:	0ee7f463          	bgeu	a5,a4,ffffffffc0202306 <get_pte+0x232>
ffffffffc0202222:	000ab783          	ld	a5,0(s5)
ffffffffc0202226:	6605                	lui	a2,0x1
ffffffffc0202228:	4581                	li	a1,0
ffffffffc020222a:	953e                	add	a0,a0,a5
ffffffffc020222c:	515030ef          	jal	ra,ffffffffc0205f40 <memset>
    return page - pages + nbase;
ffffffffc0202230:	000bb683          	ld	a3,0(s7)
ffffffffc0202234:	40d486b3          	sub	a3,s1,a3
ffffffffc0202238:	868d                	srai	a3,a3,0x3
ffffffffc020223a:	036686b3          	mul	a3,a3,s6
ffffffffc020223e:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202240:	06aa                	slli	a3,a3,0xa
ffffffffc0202242:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202246:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202248:	0009b703          	ld	a4,0(s3)
ffffffffc020224c:	068a                	slli	a3,a3,0x2
ffffffffc020224e:	757d                	lui	a0,0xfffff
ffffffffc0202250:	8ee9                	and	a3,a3,a0
ffffffffc0202252:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202256:	06e7f363          	bgeu	a5,a4,ffffffffc02022bc <get_pte+0x1e8>
ffffffffc020225a:	000ab503          	ld	a0,0(s5)
ffffffffc020225e:	00c95913          	srli	s2,s2,0xc
ffffffffc0202262:	1ff97913          	andi	s2,s2,511
ffffffffc0202266:	96aa                	add	a3,a3,a0
ffffffffc0202268:	00391513          	slli	a0,s2,0x3
ffffffffc020226c:	9536                	add	a0,a0,a3
}
ffffffffc020226e:	60a6                	ld	ra,72(sp)
ffffffffc0202270:	6406                	ld	s0,64(sp)
ffffffffc0202272:	74e2                	ld	s1,56(sp)
ffffffffc0202274:	7942                	ld	s2,48(sp)
ffffffffc0202276:	79a2                	ld	s3,40(sp)
ffffffffc0202278:	7a02                	ld	s4,32(sp)
ffffffffc020227a:	6ae2                	ld	s5,24(sp)
ffffffffc020227c:	6b42                	ld	s6,16(sp)
ffffffffc020227e:	6ba2                	ld	s7,8(sp)
ffffffffc0202280:	6161                	addi	sp,sp,80
ffffffffc0202282:	8082                	ret
            return NULL;
ffffffffc0202284:	4501                	li	a0,0
ffffffffc0202286:	b7e5                	j	ffffffffc020226e <get_pte+0x19a>
        intr_disable();
ffffffffc0202288:	f2cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020228c:	000b4797          	auipc	a5,0xb4
ffffffffc0202290:	eb47b783          	ld	a5,-332(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202294:	6f9c                	ld	a5,24(a5)
ffffffffc0202296:	4505                	li	a0,1
ffffffffc0202298:	9782                	jalr	a5
ffffffffc020229a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020229c:	f12fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022a0:	b561                	j	ffffffffc0202128 <get_pte+0x54>
        intr_disable();
ffffffffc02022a2:	f12fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022a6:	000b4797          	auipc	a5,0xb4
ffffffffc02022aa:	e9a7b783          	ld	a5,-358(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc02022ae:	6f9c                	ld	a5,24(a5)
ffffffffc02022b0:	4505                	li	a0,1
ffffffffc02022b2:	9782                	jalr	a5
ffffffffc02022b4:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02022b6:	ef8fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022ba:	b73d                	j	ffffffffc02021e8 <get_pte+0x114>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02022bc:	00005617          	auipc	a2,0x5
ffffffffc02022c0:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02022c4:	0fa00593          	li	a1,250
ffffffffc02022c8:	00005517          	auipc	a0,0x5
ffffffffc02022cc:	c7850513          	addi	a0,a0,-904 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02022d0:	9befe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02022d4:	00005617          	auipc	a2,0x5
ffffffffc02022d8:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02022dc:	0ed00593          	li	a1,237
ffffffffc02022e0:	00005517          	auipc	a0,0x5
ffffffffc02022e4:	c6050513          	addi	a0,a0,-928 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02022e8:	9a6fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02022ec:	86aa                	mv	a3,a0
ffffffffc02022ee:	00005617          	auipc	a2,0x5
ffffffffc02022f2:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02022f6:	0e900593          	li	a1,233
ffffffffc02022fa:	00005517          	auipc	a0,0x5
ffffffffc02022fe:	c4650513          	addi	a0,a0,-954 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0202302:	98cfe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202306:	86aa                	mv	a3,a0
ffffffffc0202308:	00005617          	auipc	a2,0x5
ffffffffc020230c:	b2060613          	addi	a2,a2,-1248 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0202310:	0f700593          	li	a1,247
ffffffffc0202314:	00005517          	auipc	a0,0x5
ffffffffc0202318:	c2c50513          	addi	a0,a0,-980 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020231c:	972fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202320 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202320:	1141                	addi	sp,sp,-16
ffffffffc0202322:	e022                	sd	s0,0(sp)
ffffffffc0202324:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202326:	4601                	li	a2,0
{
ffffffffc0202328:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020232a:	dabff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
    if (ptep_store != NULL)
ffffffffc020232e:	c011                	beqz	s0,ffffffffc0202332 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202330:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202332:	c511                	beqz	a0,ffffffffc020233e <get_page+0x1e>
ffffffffc0202334:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202336:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202338:	0017f713          	andi	a4,a5,1
ffffffffc020233c:	e709                	bnez	a4,ffffffffc0202346 <get_page+0x26>
}
ffffffffc020233e:	60a2                	ld	ra,8(sp)
ffffffffc0202340:	6402                	ld	s0,0(sp)
ffffffffc0202342:	0141                	addi	sp,sp,16
ffffffffc0202344:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202346:	078a                	slli	a5,a5,0x2
ffffffffc0202348:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020234a:	000b4717          	auipc	a4,0xb4
ffffffffc020234e:	de673703          	ld	a4,-538(a4) # ffffffffc02b6130 <npage>
ffffffffc0202352:	02e7f263          	bgeu	a5,a4,ffffffffc0202376 <get_page+0x56>
    return &pages[PPN(pa) - nbase];
ffffffffc0202356:	fff80537          	lui	a0,0xfff80
ffffffffc020235a:	97aa                	add	a5,a5,a0
ffffffffc020235c:	60a2                	ld	ra,8(sp)
ffffffffc020235e:	6402                	ld	s0,0(sp)
ffffffffc0202360:	00379513          	slli	a0,a5,0x3
ffffffffc0202364:	97aa                	add	a5,a5,a0
ffffffffc0202366:	078e                	slli	a5,a5,0x3
ffffffffc0202368:	000b4517          	auipc	a0,0xb4
ffffffffc020236c:	dd053503          	ld	a0,-560(a0) # ffffffffc02b6138 <pages>
ffffffffc0202370:	953e                	add	a0,a0,a5
ffffffffc0202372:	0141                	addi	sp,sp,16
ffffffffc0202374:	8082                	ret
ffffffffc0202376:	c6fff0ef          	jal	ra,ffffffffc0201fe4 <pa2page.part.0>

ffffffffc020237a <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020237a:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020237c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202380:	f486                	sd	ra,104(sp)
ffffffffc0202382:	f0a2                	sd	s0,96(sp)
ffffffffc0202384:	eca6                	sd	s1,88(sp)
ffffffffc0202386:	e8ca                	sd	s2,80(sp)
ffffffffc0202388:	e4ce                	sd	s3,72(sp)
ffffffffc020238a:	e0d2                	sd	s4,64(sp)
ffffffffc020238c:	fc56                	sd	s5,56(sp)
ffffffffc020238e:	f85a                	sd	s6,48(sp)
ffffffffc0202390:	f45e                	sd	s7,40(sp)
ffffffffc0202392:	f062                	sd	s8,32(sp)
ffffffffc0202394:	ec66                	sd	s9,24(sp)
ffffffffc0202396:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202398:	17d2                	slli	a5,a5,0x34
ffffffffc020239a:	e7e5                	bnez	a5,ffffffffc0202482 <unmap_range+0x108>
    assert(USER_ACCESS(start, end));
ffffffffc020239c:	002007b7          	lui	a5,0x200
ffffffffc02023a0:	842e                	mv	s0,a1
ffffffffc02023a2:	10f5e063          	bltu	a1,a5,ffffffffc02024a2 <unmap_range+0x128>
ffffffffc02023a6:	8932                	mv	s2,a2
ffffffffc02023a8:	0ec5fd63          	bgeu	a1,a2,ffffffffc02024a2 <unmap_range+0x128>
ffffffffc02023ac:	4785                	li	a5,1
ffffffffc02023ae:	07fe                	slli	a5,a5,0x1f
ffffffffc02023b0:	0ec7e963          	bltu	a5,a2,ffffffffc02024a2 <unmap_range+0x128>
ffffffffc02023b4:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02023b6:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02023b8:	000b4c97          	auipc	s9,0xb4
ffffffffc02023bc:	d78c8c93          	addi	s9,s9,-648 # ffffffffc02b6130 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02023c0:	000b4c17          	auipc	s8,0xb4
ffffffffc02023c4:	d78c0c13          	addi	s8,s8,-648 # ffffffffc02b6138 <pages>
ffffffffc02023c8:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02023cc:	000b4d17          	auipc	s10,0xb4
ffffffffc02023d0:	d74d0d13          	addi	s10,s10,-652 # ffffffffc02b6140 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02023d4:	00200b37          	lui	s6,0x200
ffffffffc02023d8:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02023dc:	4601                	li	a2,0
ffffffffc02023de:	85a2                	mv	a1,s0
ffffffffc02023e0:	854e                	mv	a0,s3
ffffffffc02023e2:	cf3ff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc02023e6:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02023e8:	c125                	beqz	a0,ffffffffc0202448 <unmap_range+0xce>
        if (*ptep != 0)
ffffffffc02023ea:	611c                	ld	a5,0(a0)
ffffffffc02023ec:	e395                	bnez	a5,ffffffffc0202410 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02023ee:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02023f0:	ff2466e3          	bltu	s0,s2,ffffffffc02023dc <unmap_range+0x62>
}
ffffffffc02023f4:	70a6                	ld	ra,104(sp)
ffffffffc02023f6:	7406                	ld	s0,96(sp)
ffffffffc02023f8:	64e6                	ld	s1,88(sp)
ffffffffc02023fa:	6946                	ld	s2,80(sp)
ffffffffc02023fc:	69a6                	ld	s3,72(sp)
ffffffffc02023fe:	6a06                	ld	s4,64(sp)
ffffffffc0202400:	7ae2                	ld	s5,56(sp)
ffffffffc0202402:	7b42                	ld	s6,48(sp)
ffffffffc0202404:	7ba2                	ld	s7,40(sp)
ffffffffc0202406:	7c02                	ld	s8,32(sp)
ffffffffc0202408:	6ce2                	ld	s9,24(sp)
ffffffffc020240a:	6d42                	ld	s10,16(sp)
ffffffffc020240c:	6165                	addi	sp,sp,112
ffffffffc020240e:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202410:	0017f713          	andi	a4,a5,1
ffffffffc0202414:	df69                	beqz	a4,ffffffffc02023ee <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202416:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020241a:	078a                	slli	a5,a5,0x2
ffffffffc020241c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020241e:	0ae7f263          	bgeu	a5,a4,ffffffffc02024c2 <unmap_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc0202422:	97de                	add	a5,a5,s7
ffffffffc0202424:	000c3503          	ld	a0,0(s8)
ffffffffc0202428:	00379713          	slli	a4,a5,0x3
ffffffffc020242c:	97ba                	add	a5,a5,a4
ffffffffc020242e:	078e                	slli	a5,a5,0x3
ffffffffc0202430:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202432:	411c                	lw	a5,0(a0)
ffffffffc0202434:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202438:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020243a:	cf11                	beqz	a4,ffffffffc0202456 <unmap_range+0xdc>
        *ptep = 0;
ffffffffc020243c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202440:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202444:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202446:	b76d                	j	ffffffffc02023f0 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202448:	945a                	add	s0,s0,s6
ffffffffc020244a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020244e:	d05d                	beqz	s0,ffffffffc02023f4 <unmap_range+0x7a>
ffffffffc0202450:	f92466e3          	bltu	s0,s2,ffffffffc02023dc <unmap_range+0x62>
ffffffffc0202454:	b745                	j	ffffffffc02023f4 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202456:	100027f3          	csrr	a5,sstatus
ffffffffc020245a:	8b89                	andi	a5,a5,2
ffffffffc020245c:	e799                	bnez	a5,ffffffffc020246a <unmap_range+0xf0>
        pmm_manager->free_pages(base, n);
ffffffffc020245e:	000d3783          	ld	a5,0(s10)
ffffffffc0202462:	4585                	li	a1,1
ffffffffc0202464:	739c                	ld	a5,32(a5)
ffffffffc0202466:	9782                	jalr	a5
    if (flag)
ffffffffc0202468:	bfd1                	j	ffffffffc020243c <unmap_range+0xc2>
ffffffffc020246a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020246c:	d48fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202470:	000d3783          	ld	a5,0(s10)
ffffffffc0202474:	6522                	ld	a0,8(sp)
ffffffffc0202476:	4585                	li	a1,1
ffffffffc0202478:	739c                	ld	a5,32(a5)
ffffffffc020247a:	9782                	jalr	a5
        intr_enable();
ffffffffc020247c:	d32fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202480:	bf75                	j	ffffffffc020243c <unmap_range+0xc2>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202482:	00005697          	auipc	a3,0x5
ffffffffc0202486:	ace68693          	addi	a3,a3,-1330 # ffffffffc0206f50 <default_pmm_manager+0x160>
ffffffffc020248a:	00004617          	auipc	a2,0x4
ffffffffc020248e:	5b660613          	addi	a2,a2,1462 # ffffffffc0206a40 <commands+0x868>
ffffffffc0202492:	12000593          	li	a1,288
ffffffffc0202496:	00005517          	auipc	a0,0x5
ffffffffc020249a:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020249e:	ff1fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024a2:	00005697          	auipc	a3,0x5
ffffffffc02024a6:	ade68693          	addi	a3,a3,-1314 # ffffffffc0206f80 <default_pmm_manager+0x190>
ffffffffc02024aa:	00004617          	auipc	a2,0x4
ffffffffc02024ae:	59660613          	addi	a2,a2,1430 # ffffffffc0206a40 <commands+0x868>
ffffffffc02024b2:	12100593          	li	a1,289
ffffffffc02024b6:	00005517          	auipc	a0,0x5
ffffffffc02024ba:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02024be:	fd1fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02024c2:	b23ff0ef          	jal	ra,ffffffffc0201fe4 <pa2page.part.0>

ffffffffc02024c6 <exit_range>:
{
ffffffffc02024c6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024c8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02024cc:	fc86                	sd	ra,120(sp)
ffffffffc02024ce:	f8a2                	sd	s0,112(sp)
ffffffffc02024d0:	f4a6                	sd	s1,104(sp)
ffffffffc02024d2:	f0ca                	sd	s2,96(sp)
ffffffffc02024d4:	ecce                	sd	s3,88(sp)
ffffffffc02024d6:	e8d2                	sd	s4,80(sp)
ffffffffc02024d8:	e4d6                	sd	s5,72(sp)
ffffffffc02024da:	e0da                	sd	s6,64(sp)
ffffffffc02024dc:	fc5e                	sd	s7,56(sp)
ffffffffc02024de:	f862                	sd	s8,48(sp)
ffffffffc02024e0:	f466                	sd	s9,40(sp)
ffffffffc02024e2:	f06a                	sd	s10,32(sp)
ffffffffc02024e4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024e6:	17d2                	slli	a5,a5,0x34
ffffffffc02024e8:	26079063          	bnez	a5,ffffffffc0202748 <exit_range+0x282>
    assert(USER_ACCESS(start, end));
ffffffffc02024ec:	002007b7          	lui	a5,0x200
ffffffffc02024f0:	28f5ea63          	bltu	a1,a5,ffffffffc0202784 <exit_range+0x2be>
ffffffffc02024f4:	8ab2                	mv	s5,a2
ffffffffc02024f6:	28c5f763          	bgeu	a1,a2,ffffffffc0202784 <exit_range+0x2be>
ffffffffc02024fa:	4785                	li	a5,1
ffffffffc02024fc:	07fe                	slli	a5,a5,0x1f
ffffffffc02024fe:	28c7e363          	bltu	a5,a2,ffffffffc0202784 <exit_range+0x2be>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202502:	c00009b7          	lui	s3,0xc0000
ffffffffc0202506:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020250a:	ffe00937          	lui	s2,0xffe00
ffffffffc020250e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202512:	5d7d                	li	s10,-1
ffffffffc0202514:	8c2a                	mv	s8,a0
ffffffffc0202516:	0125f933          	and	s2,a1,s2
ffffffffc020251a:	99be                	add	s3,s3,a5
    return page - pages + nbase;
ffffffffc020251c:	00006d97          	auipc	s11,0x6
ffffffffc0202520:	c8cdbd83          	ld	s11,-884(s11) # ffffffffc02081a8 <error_string+0xc8>
    return KADDR(page2pa(page));
ffffffffc0202524:	00cd5d13          	srli	s10,s10,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202528:	000b4617          	auipc	a2,0xb4
ffffffffc020252c:	c1060613          	addi	a2,a2,-1008 # ffffffffc02b6138 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202530:	000b4717          	auipc	a4,0xb4
ffffffffc0202534:	c1070713          	addi	a4,a4,-1008 # ffffffffc02b6140 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202538:	c0000437          	lui	s0,0xc0000
ffffffffc020253c:	944e                	add	s0,s0,s3
ffffffffc020253e:	8079                	srli	s0,s0,0x1e
ffffffffc0202540:	1ff47413          	andi	s0,s0,511
ffffffffc0202544:	040e                	slli	s0,s0,0x3
ffffffffc0202546:	9462                	add	s0,s0,s8
ffffffffc0202548:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
        if (pde1 & PTE_V)
ffffffffc020254c:	001a7793          	andi	a5,s4,1
ffffffffc0202550:	eb99                	bnez	a5,ffffffffc0202566 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202552:	14098a63          	beqz	s3,ffffffffc02026a6 <exit_range+0x1e0>
ffffffffc0202556:	400007b7          	lui	a5,0x40000
ffffffffc020255a:	97ce                	add	a5,a5,s3
ffffffffc020255c:	894e                	mv	s2,s3
ffffffffc020255e:	1559f463          	bgeu	s3,s5,ffffffffc02026a6 <exit_range+0x1e0>
ffffffffc0202562:	89be                	mv	s3,a5
ffffffffc0202564:	bfd1                	j	ffffffffc0202538 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202566:	000b4817          	auipc	a6,0xb4
ffffffffc020256a:	bca80813          	addi	a6,a6,-1078 # ffffffffc02b6130 <npage>
ffffffffc020256e:	00083583          	ld	a1,0(a6)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202572:	0a0a                	slli	s4,s4,0x2
ffffffffc0202574:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202578:	20ba7463          	bgeu	s4,a1,ffffffffc0202780 <exit_range+0x2ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020257c:	fff80cb7          	lui	s9,0xfff80
ffffffffc0202580:	019a07b3          	add	a5,s4,s9
ffffffffc0202584:	00379c93          	slli	s9,a5,0x3
ffffffffc0202588:	9cbe                	add	s9,s9,a5
    return page - pages + nbase;
ffffffffc020258a:	03bc86b3          	mul	a3,s9,s11
ffffffffc020258e:	00080b37          	lui	s6,0x80
    return &pages[PPN(pa) - nbase];
ffffffffc0202592:	0c8e                	slli	s9,s9,0x3
    return page - pages + nbase;
ffffffffc0202594:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0202596:	01a6f7b3          	and	a5,a3,s10
    return page2ppn(page) << PGSHIFT;
ffffffffc020259a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020259c:	1cb7f663          	bgeu	a5,a1,ffffffffc0202768 <exit_range+0x2a2>
ffffffffc02025a0:	000b4897          	auipc	a7,0xb4
ffffffffc02025a4:	ba888893          	addi	a7,a7,-1112 # ffffffffc02b6148 <va_pa_offset>
ffffffffc02025a8:	0008bb03          	ld	s6,0(a7)
            free_pd0 = 1;
ffffffffc02025ac:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02025ae:	fff80eb7          	lui	t4,0xfff80
    return KADDR(page2pa(page));
ffffffffc02025b2:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02025b4:	00080e37          	lui	t3,0x80
ffffffffc02025b8:	6305                	lui	t1,0x1
ffffffffc02025ba:	a819                	j	ffffffffc02025d0 <exit_range+0x10a>
                    free_pd0 = 0;
ffffffffc02025bc:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02025be:	002007b7          	lui	a5,0x200
ffffffffc02025c2:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02025c4:	0a090563          	beqz	s2,ffffffffc020266e <exit_range+0x1a8>
ffffffffc02025c8:	0b397363          	bgeu	s2,s3,ffffffffc020266e <exit_range+0x1a8>
ffffffffc02025cc:	0f597c63          	bgeu	s2,s5,ffffffffc02026c4 <exit_range+0x1fe>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02025d0:	01595493          	srli	s1,s2,0x15
ffffffffc02025d4:	1ff4f493          	andi	s1,s1,511
ffffffffc02025d8:	048e                	slli	s1,s1,0x3
ffffffffc02025da:	94da                	add	s1,s1,s6
ffffffffc02025dc:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02025de:	0017f693          	andi	a3,a5,1
ffffffffc02025e2:	dee9                	beqz	a3,ffffffffc02025bc <exit_range+0xf6>
    if (PPN(pa) >= npage)
ffffffffc02025e4:	00083583          	ld	a1,0(a6)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025e8:	078a                	slli	a5,a5,0x2
ffffffffc02025ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025ec:	18b7fa63          	bgeu	a5,a1,ffffffffc0202780 <exit_range+0x2ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02025f0:	97f6                	add	a5,a5,t4
ffffffffc02025f2:	00379513          	slli	a0,a5,0x3
ffffffffc02025f6:	97aa                	add	a5,a5,a0
    return page - pages + nbase;
ffffffffc02025f8:	03b786b3          	mul	a3,a5,s11
    return &pages[PPN(pa) - nbase];
ffffffffc02025fc:	00379513          	slli	a0,a5,0x3
    return page - pages + nbase;
ffffffffc0202600:	96f2                	add	a3,a3,t3
    return KADDR(page2pa(page));
ffffffffc0202602:	01a6f7b3          	and	a5,a3,s10
    return page2ppn(page) << PGSHIFT;
ffffffffc0202606:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202608:	16b7f063          	bgeu	a5,a1,ffffffffc0202768 <exit_range+0x2a2>
ffffffffc020260c:	0008b783          	ld	a5,0(a7)
ffffffffc0202610:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202612:	006685b3          	add	a1,a3,t1
                        if (pt[i] & PTE_V)
ffffffffc0202616:	629c                	ld	a5,0(a3)
ffffffffc0202618:	8b85                	andi	a5,a5,1
ffffffffc020261a:	f3d5                	bnez	a5,ffffffffc02025be <exit_range+0xf8>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020261c:	06a1                	addi	a3,a3,8
ffffffffc020261e:	fed59ce3          	bne	a1,a3,ffffffffc0202616 <exit_range+0x150>
    return &pages[PPN(pa) - nbase];
ffffffffc0202622:	621c                	ld	a5,0(a2)
ffffffffc0202624:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202626:	100027f3          	csrr	a5,sstatus
ffffffffc020262a:	8b89                	andi	a5,a5,2
ffffffffc020262c:	efd9                	bnez	a5,ffffffffc02026ca <exit_range+0x204>
        pmm_manager->free_pages(base, n);
ffffffffc020262e:	631c                	ld	a5,0(a4)
ffffffffc0202630:	4585                	li	a1,1
ffffffffc0202632:	739c                	ld	a5,32(a5)
ffffffffc0202634:	9782                	jalr	a5
    if (flag)
ffffffffc0202636:	000b4717          	auipc	a4,0xb4
ffffffffc020263a:	b0a70713          	addi	a4,a4,-1270 # ffffffffc02b6140 <pmm_manager>
ffffffffc020263e:	000b4897          	auipc	a7,0xb4
ffffffffc0202642:	b0a88893          	addi	a7,a7,-1270 # ffffffffc02b6148 <va_pa_offset>
ffffffffc0202646:	000b4817          	auipc	a6,0xb4
ffffffffc020264a:	aea80813          	addi	a6,a6,-1302 # ffffffffc02b6130 <npage>
ffffffffc020264e:	fff80eb7          	lui	t4,0xfff80
ffffffffc0202652:	00080e37          	lui	t3,0x80
ffffffffc0202656:	6305                	lui	t1,0x1
ffffffffc0202658:	000b4617          	auipc	a2,0xb4
ffffffffc020265c:	ae060613          	addi	a2,a2,-1312 # ffffffffc02b6138 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202660:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202664:	002007b7          	lui	a5,0x200
ffffffffc0202668:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020266a:	f4091fe3          	bnez	s2,ffffffffc02025c8 <exit_range+0x102>
            if (free_pd0)
ffffffffc020266e:	ee0b82e3          	beqz	s7,ffffffffc0202552 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202672:	00083783          	ld	a5,0(a6)
ffffffffc0202676:	10fa7563          	bgeu	s4,a5,ffffffffc0202780 <exit_range+0x2ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020267a:	6208                	ld	a0,0(a2)
ffffffffc020267c:	9566                	add	a0,a0,s9
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020267e:	100027f3          	csrr	a5,sstatus
ffffffffc0202682:	8b89                	andi	a5,a5,2
ffffffffc0202684:	ebc9                	bnez	a5,ffffffffc0202716 <exit_range+0x250>
        pmm_manager->free_pages(base, n);
ffffffffc0202686:	631c                	ld	a5,0(a4)
ffffffffc0202688:	4585                	li	a1,1
ffffffffc020268a:	739c                	ld	a5,32(a5)
ffffffffc020268c:	9782                	jalr	a5
ffffffffc020268e:	000b4617          	auipc	a2,0xb4
ffffffffc0202692:	aaa60613          	addi	a2,a2,-1366 # ffffffffc02b6138 <pages>
ffffffffc0202696:	000b4717          	auipc	a4,0xb4
ffffffffc020269a:	aaa70713          	addi	a4,a4,-1366 # ffffffffc02b6140 <pmm_manager>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020269e:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02026a2:	ea099ae3          	bnez	s3,ffffffffc0202556 <exit_range+0x90>
}
ffffffffc02026a6:	70e6                	ld	ra,120(sp)
ffffffffc02026a8:	7446                	ld	s0,112(sp)
ffffffffc02026aa:	74a6                	ld	s1,104(sp)
ffffffffc02026ac:	7906                	ld	s2,96(sp)
ffffffffc02026ae:	69e6                	ld	s3,88(sp)
ffffffffc02026b0:	6a46                	ld	s4,80(sp)
ffffffffc02026b2:	6aa6                	ld	s5,72(sp)
ffffffffc02026b4:	6b06                	ld	s6,64(sp)
ffffffffc02026b6:	7be2                	ld	s7,56(sp)
ffffffffc02026b8:	7c42                	ld	s8,48(sp)
ffffffffc02026ba:	7ca2                	ld	s9,40(sp)
ffffffffc02026bc:	7d02                	ld	s10,32(sp)
ffffffffc02026be:	6de2                	ld	s11,24(sp)
ffffffffc02026c0:	6109                	addi	sp,sp,128
ffffffffc02026c2:	8082                	ret
            if (free_pd0)
ffffffffc02026c4:	e80b89e3          	beqz	s7,ffffffffc0202556 <exit_range+0x90>
ffffffffc02026c8:	b76d                	j	ffffffffc0202672 <exit_range+0x1ac>
ffffffffc02026ca:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02026cc:	ae8fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026d0:	000b4717          	auipc	a4,0xb4
ffffffffc02026d4:	a7070713          	addi	a4,a4,-1424 # ffffffffc02b6140 <pmm_manager>
ffffffffc02026d8:	631c                	ld	a5,0(a4)
ffffffffc02026da:	6522                	ld	a0,8(sp)
ffffffffc02026dc:	4585                	li	a1,1
ffffffffc02026de:	739c                	ld	a5,32(a5)
ffffffffc02026e0:	9782                	jalr	a5
        intr_enable();
ffffffffc02026e2:	accfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026e6:	000b4617          	auipc	a2,0xb4
ffffffffc02026ea:	a5260613          	addi	a2,a2,-1454 # ffffffffc02b6138 <pages>
ffffffffc02026ee:	6305                	lui	t1,0x1
ffffffffc02026f0:	00080e37          	lui	t3,0x80
ffffffffc02026f4:	fff80eb7          	lui	t4,0xfff80
ffffffffc02026f8:	000b4817          	auipc	a6,0xb4
ffffffffc02026fc:	a3880813          	addi	a6,a6,-1480 # ffffffffc02b6130 <npage>
ffffffffc0202700:	000b4897          	auipc	a7,0xb4
ffffffffc0202704:	a4888893          	addi	a7,a7,-1464 # ffffffffc02b6148 <va_pa_offset>
ffffffffc0202708:	000b4717          	auipc	a4,0xb4
ffffffffc020270c:	a3870713          	addi	a4,a4,-1480 # ffffffffc02b6140 <pmm_manager>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202710:	0004b023          	sd	zero,0(s1)
ffffffffc0202714:	bf81                	j	ffffffffc0202664 <exit_range+0x19e>
ffffffffc0202716:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202718:	a9cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020271c:	000b4717          	auipc	a4,0xb4
ffffffffc0202720:	a2470713          	addi	a4,a4,-1500 # ffffffffc02b6140 <pmm_manager>
ffffffffc0202724:	631c                	ld	a5,0(a4)
ffffffffc0202726:	6522                	ld	a0,8(sp)
ffffffffc0202728:	4585                	li	a1,1
ffffffffc020272a:	739c                	ld	a5,32(a5)
ffffffffc020272c:	9782                	jalr	a5
        intr_enable();
ffffffffc020272e:	a80fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202732:	000b4717          	auipc	a4,0xb4
ffffffffc0202736:	a0e70713          	addi	a4,a4,-1522 # ffffffffc02b6140 <pmm_manager>
ffffffffc020273a:	000b4617          	auipc	a2,0xb4
ffffffffc020273e:	9fe60613          	addi	a2,a2,-1538 # ffffffffc02b6138 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202742:	00043023          	sd	zero,0(s0)
ffffffffc0202746:	bfb1                	j	ffffffffc02026a2 <exit_range+0x1dc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202748:	00005697          	auipc	a3,0x5
ffffffffc020274c:	80868693          	addi	a3,a3,-2040 # ffffffffc0206f50 <default_pmm_manager+0x160>
ffffffffc0202750:	00004617          	auipc	a2,0x4
ffffffffc0202754:	2f060613          	addi	a2,a2,752 # ffffffffc0206a40 <commands+0x868>
ffffffffc0202758:	13500593          	li	a1,309
ffffffffc020275c:	00004517          	auipc	a0,0x4
ffffffffc0202760:	7e450513          	addi	a0,a0,2020 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0202764:	d2bfd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202768:	00004617          	auipc	a2,0x4
ffffffffc020276c:	6c060613          	addi	a2,a2,1728 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0202770:	08300593          	li	a1,131
ffffffffc0202774:	00004517          	auipc	a0,0x4
ffffffffc0202778:	6dc50513          	addi	a0,a0,1756 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc020277c:	d13fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202780:	865ff0ef          	jal	ra,ffffffffc0201fe4 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202784:	00004697          	auipc	a3,0x4
ffffffffc0202788:	7fc68693          	addi	a3,a3,2044 # ffffffffc0206f80 <default_pmm_manager+0x190>
ffffffffc020278c:	00004617          	auipc	a2,0x4
ffffffffc0202790:	2b460613          	addi	a2,a2,692 # ffffffffc0206a40 <commands+0x868>
ffffffffc0202794:	13600593          	li	a1,310
ffffffffc0202798:	00004517          	auipc	a0,0x4
ffffffffc020279c:	7a850513          	addi	a0,a0,1960 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02027a0:	ceffd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02027a4 <page_remove>:
{
ffffffffc02027a4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02027a6:	4601                	li	a2,0
{
ffffffffc02027a8:	ec26                	sd	s1,24(sp)
ffffffffc02027aa:	f406                	sd	ra,40(sp)
ffffffffc02027ac:	f022                	sd	s0,32(sp)
ffffffffc02027ae:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02027b0:	925ff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
    if (ptep != NULL)
ffffffffc02027b4:	c511                	beqz	a0,ffffffffc02027c0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02027b6:	611c                	ld	a5,0(a0)
ffffffffc02027b8:	842a                	mv	s0,a0
ffffffffc02027ba:	0017f713          	andi	a4,a5,1
ffffffffc02027be:	e711                	bnez	a4,ffffffffc02027ca <page_remove+0x26>
}
ffffffffc02027c0:	70a2                	ld	ra,40(sp)
ffffffffc02027c2:	7402                	ld	s0,32(sp)
ffffffffc02027c4:	64e2                	ld	s1,24(sp)
ffffffffc02027c6:	6145                	addi	sp,sp,48
ffffffffc02027c8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02027ca:	078a                	slli	a5,a5,0x2
ffffffffc02027cc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027ce:	000b4717          	auipc	a4,0xb4
ffffffffc02027d2:	96273703          	ld	a4,-1694(a4) # ffffffffc02b6130 <npage>
ffffffffc02027d6:	06e7f663          	bgeu	a5,a4,ffffffffc0202842 <page_remove+0x9e>
    return &pages[PPN(pa) - nbase];
ffffffffc02027da:	fff80737          	lui	a4,0xfff80
ffffffffc02027de:	97ba                	add	a5,a5,a4
ffffffffc02027e0:	00379513          	slli	a0,a5,0x3
ffffffffc02027e4:	97aa                	add	a5,a5,a0
ffffffffc02027e6:	078e                	slli	a5,a5,0x3
ffffffffc02027e8:	000b4517          	auipc	a0,0xb4
ffffffffc02027ec:	95053503          	ld	a0,-1712(a0) # ffffffffc02b6138 <pages>
ffffffffc02027f0:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02027f2:	411c                	lw	a5,0(a0)
ffffffffc02027f4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02027f8:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02027fa:	cb11                	beqz	a4,ffffffffc020280e <page_remove+0x6a>
        *ptep = 0;
ffffffffc02027fc:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202800:	12048073          	sfence.vma	s1
}
ffffffffc0202804:	70a2                	ld	ra,40(sp)
ffffffffc0202806:	7402                	ld	s0,32(sp)
ffffffffc0202808:	64e2                	ld	s1,24(sp)
ffffffffc020280a:	6145                	addi	sp,sp,48
ffffffffc020280c:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020280e:	100027f3          	csrr	a5,sstatus
ffffffffc0202812:	8b89                	andi	a5,a5,2
ffffffffc0202814:	eb89                	bnez	a5,ffffffffc0202826 <page_remove+0x82>
        pmm_manager->free_pages(base, n);
ffffffffc0202816:	000b4797          	auipc	a5,0xb4
ffffffffc020281a:	92a7b783          	ld	a5,-1750(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc020281e:	739c                	ld	a5,32(a5)
ffffffffc0202820:	4585                	li	a1,1
ffffffffc0202822:	9782                	jalr	a5
    if (flag)
ffffffffc0202824:	bfe1                	j	ffffffffc02027fc <page_remove+0x58>
        intr_disable();
ffffffffc0202826:	e42a                	sd	a0,8(sp)
ffffffffc0202828:	98cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020282c:	000b4797          	auipc	a5,0xb4
ffffffffc0202830:	9147b783          	ld	a5,-1772(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202834:	739c                	ld	a5,32(a5)
ffffffffc0202836:	6522                	ld	a0,8(sp)
ffffffffc0202838:	4585                	li	a1,1
ffffffffc020283a:	9782                	jalr	a5
        intr_enable();
ffffffffc020283c:	972fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202840:	bf75                	j	ffffffffc02027fc <page_remove+0x58>
ffffffffc0202842:	fa2ff0ef          	jal	ra,ffffffffc0201fe4 <pa2page.part.0>

ffffffffc0202846 <page_insert>:
{
ffffffffc0202846:	7139                	addi	sp,sp,-64
ffffffffc0202848:	ec4e                	sd	s3,24(sp)
ffffffffc020284a:	89b2                	mv	s3,a2
ffffffffc020284c:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020284e:	4605                	li	a2,1
{
ffffffffc0202850:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202852:	85ce                	mv	a1,s3
{
ffffffffc0202854:	f426                	sd	s1,40(sp)
ffffffffc0202856:	fc06                	sd	ra,56(sp)
ffffffffc0202858:	f04a                	sd	s2,32(sp)
ffffffffc020285a:	e852                	sd	s4,16(sp)
ffffffffc020285c:	e456                	sd	s5,8(sp)
ffffffffc020285e:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202860:	875ff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
    if (ptep == NULL)
ffffffffc0202864:	c17d                	beqz	a0,ffffffffc020294a <page_insert+0x104>
    page->ref += 1;
ffffffffc0202866:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202868:	611c                	ld	a5,0(a0)
ffffffffc020286a:	8a2a                	mv	s4,a0
ffffffffc020286c:	0016871b          	addiw	a4,a3,1
ffffffffc0202870:	c018                	sw	a4,0(s0)
ffffffffc0202872:	0017f713          	andi	a4,a5,1
ffffffffc0202876:	e339                	bnez	a4,ffffffffc02028bc <page_insert+0x76>
    return page - pages + nbase;
ffffffffc0202878:	000b4797          	auipc	a5,0xb4
ffffffffc020287c:	8c07b783          	ld	a5,-1856(a5) # ffffffffc02b6138 <pages>
ffffffffc0202880:	40f407b3          	sub	a5,s0,a5
ffffffffc0202884:	878d                	srai	a5,a5,0x3
ffffffffc0202886:	00006417          	auipc	s0,0x6
ffffffffc020288a:	92243403          	ld	s0,-1758(s0) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc020288e:	028787b3          	mul	a5,a5,s0
ffffffffc0202892:	00080437          	lui	s0,0x80
ffffffffc0202896:	97a2                	add	a5,a5,s0
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202898:	07aa                	slli	a5,a5,0xa
ffffffffc020289a:	8cdd                	or	s1,s1,a5
ffffffffc020289c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02028a0:	009a3023          	sd	s1,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028a4:	12098073          	sfence.vma	s3
    return 0;
ffffffffc02028a8:	4501                	li	a0,0
}
ffffffffc02028aa:	70e2                	ld	ra,56(sp)
ffffffffc02028ac:	7442                	ld	s0,48(sp)
ffffffffc02028ae:	74a2                	ld	s1,40(sp)
ffffffffc02028b0:	7902                	ld	s2,32(sp)
ffffffffc02028b2:	69e2                	ld	s3,24(sp)
ffffffffc02028b4:	6a42                	ld	s4,16(sp)
ffffffffc02028b6:	6aa2                	ld	s5,8(sp)
ffffffffc02028b8:	6121                	addi	sp,sp,64
ffffffffc02028ba:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02028bc:	00279713          	slli	a4,a5,0x2
ffffffffc02028c0:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02028c2:	000b4797          	auipc	a5,0xb4
ffffffffc02028c6:	86e7b783          	ld	a5,-1938(a5) # ffffffffc02b6130 <npage>
ffffffffc02028ca:	08f77263          	bgeu	a4,a5,ffffffffc020294e <page_insert+0x108>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ce:	fff807b7          	lui	a5,0xfff80
ffffffffc02028d2:	973e                	add	a4,a4,a5
ffffffffc02028d4:	000b4a97          	auipc	s5,0xb4
ffffffffc02028d8:	864a8a93          	addi	s5,s5,-1948 # ffffffffc02b6138 <pages>
ffffffffc02028dc:	000ab783          	ld	a5,0(s5)
ffffffffc02028e0:	00371913          	slli	s2,a4,0x3
ffffffffc02028e4:	993a                	add	s2,s2,a4
ffffffffc02028e6:	090e                	slli	s2,s2,0x3
ffffffffc02028e8:	993e                	add	s2,s2,a5
        if (p == page)
ffffffffc02028ea:	01240c63          	beq	s0,s2,ffffffffc0202902 <page_insert+0xbc>
    page->ref -= 1;
ffffffffc02028ee:	00092703          	lw	a4,0(s2) # ffffffffffe00000 <end+0x3fb49e8c>
ffffffffc02028f2:	fff7069b          	addiw	a3,a4,-1
ffffffffc02028f6:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02028fa:	c691                	beqz	a3,ffffffffc0202906 <page_insert+0xc0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028fc:	12098073          	sfence.vma	s3
}
ffffffffc0202900:	b741                	j	ffffffffc0202880 <page_insert+0x3a>
ffffffffc0202902:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202904:	bfb5                	j	ffffffffc0202880 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202906:	100027f3          	csrr	a5,sstatus
ffffffffc020290a:	8b89                	andi	a5,a5,2
ffffffffc020290c:	ef91                	bnez	a5,ffffffffc0202928 <page_insert+0xe2>
        pmm_manager->free_pages(base, n);
ffffffffc020290e:	000b4797          	auipc	a5,0xb4
ffffffffc0202912:	8327b783          	ld	a5,-1998(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202916:	739c                	ld	a5,32(a5)
ffffffffc0202918:	4585                	li	a1,1
ffffffffc020291a:	854a                	mv	a0,s2
ffffffffc020291c:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020291e:	000ab783          	ld	a5,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202922:	12098073          	sfence.vma	s3
ffffffffc0202926:	bfa9                	j	ffffffffc0202880 <page_insert+0x3a>
        intr_disable();
ffffffffc0202928:	88cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020292c:	000b4797          	auipc	a5,0xb4
ffffffffc0202930:	8147b783          	ld	a5,-2028(a5) # ffffffffc02b6140 <pmm_manager>
ffffffffc0202934:	739c                	ld	a5,32(a5)
ffffffffc0202936:	4585                	li	a1,1
ffffffffc0202938:	854a                	mv	a0,s2
ffffffffc020293a:	9782                	jalr	a5
        intr_enable();
ffffffffc020293c:	872fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202940:	000ab783          	ld	a5,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202944:	12098073          	sfence.vma	s3
ffffffffc0202948:	bf25                	j	ffffffffc0202880 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020294a:	5571                	li	a0,-4
ffffffffc020294c:	bfb9                	j	ffffffffc02028aa <page_insert+0x64>
ffffffffc020294e:	e96ff0ef          	jal	ra,ffffffffc0201fe4 <pa2page.part.0>

ffffffffc0202952 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202952:	00004797          	auipc	a5,0x4
ffffffffc0202956:	49e78793          	addi	a5,a5,1182 # ffffffffc0206df0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020295a:	638c                	ld	a1,0(a5)
{
ffffffffc020295c:	7159                	addi	sp,sp,-112
ffffffffc020295e:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202960:	00004517          	auipc	a0,0x4
ffffffffc0202964:	63850513          	addi	a0,a0,1592 # ffffffffc0206f98 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202968:	000b3b17          	auipc	s6,0xb3
ffffffffc020296c:	7d8b0b13          	addi	s6,s6,2008 # ffffffffc02b6140 <pmm_manager>
{
ffffffffc0202970:	f486                	sd	ra,104(sp)
ffffffffc0202972:	eca6                	sd	s1,88(sp)
ffffffffc0202974:	e4ce                	sd	s3,72(sp)
ffffffffc0202976:	f0a2                	sd	s0,96(sp)
ffffffffc0202978:	e8ca                	sd	s2,80(sp)
ffffffffc020297a:	e0d2                	sd	s4,64(sp)
ffffffffc020297c:	fc56                	sd	s5,56(sp)
ffffffffc020297e:	f45e                	sd	s7,40(sp)
ffffffffc0202980:	f062                	sd	s8,32(sp)
ffffffffc0202982:	ec66                	sd	s9,24(sp)
ffffffffc0202984:	e86a                	sd	s10,16(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202986:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020298a:	80bfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc020298e:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202992:	000b3997          	auipc	s3,0xb3
ffffffffc0202996:	7b698993          	addi	s3,s3,1974 # ffffffffc02b6148 <va_pa_offset>
    pmm_manager->init();
ffffffffc020299a:	679c                	ld	a5,8(a5)
ffffffffc020299c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020299e:	57f5                	li	a5,-3
ffffffffc02029a0:	07fa                	slli	a5,a5,0x1e
ffffffffc02029a2:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02029a6:	ff5fd0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc02029aa:	84aa                	mv	s1,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02029ac:	ff9fd0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02029b0:	260507e3          	beqz	a0,ffffffffc020341e <pmm_init+0xacc>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02029b4:	842a                	mv	s0,a0
    cprintf("physcial memory map:\n");
ffffffffc02029b6:	00004517          	auipc	a0,0x4
ffffffffc02029ba:	61a50513          	addi	a0,a0,1562 # ffffffffc0206fd0 <default_pmm_manager+0x1e0>
ffffffffc02029be:	fd6fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02029c2:	00848933          	add	s2,s1,s0
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02029c6:	8626                	mv	a2,s1
ffffffffc02029c8:	fff90693          	addi	a3,s2,-1
ffffffffc02029cc:	85a2                	mv	a1,s0
ffffffffc02029ce:	00004517          	auipc	a0,0x4
ffffffffc02029d2:	61a50513          	addi	a0,a0,1562 # ffffffffc0206fe8 <default_pmm_manager+0x1f8>
ffffffffc02029d6:	fbefd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02029da:	c80007b7          	lui	a5,0xc8000
ffffffffc02029de:	864a                	mv	a2,s2
ffffffffc02029e0:	5b27e063          	bltu	a5,s2,ffffffffc0202f80 <pmm_init+0x62e>
ffffffffc02029e4:	000b4797          	auipc	a5,0xb4
ffffffffc02029e8:	78f78793          	addi	a5,a5,1935 # ffffffffc02b7173 <end+0xfff>
ffffffffc02029ec:	757d                	lui	a0,0xfffff
ffffffffc02029ee:	8d7d                	and	a0,a0,a5
ffffffffc02029f0:	8231                	srli	a2,a2,0xc
ffffffffc02029f2:	000b3497          	auipc	s1,0xb3
ffffffffc02029f6:	73e48493          	addi	s1,s1,1854 # ffffffffc02b6130 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029fa:	000b3b97          	auipc	s7,0xb3
ffffffffc02029fe:	73eb8b93          	addi	s7,s7,1854 # ffffffffc02b6138 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202a02:	e090                	sd	a2,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202a04:	00abb023          	sd	a0,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202a08:	000807b7          	lui	a5,0x80
ffffffffc0202a0c:	02f60663          	beq	a2,a5,ffffffffc0202a38 <pmm_init+0xe6>
ffffffffc0202a10:	4701                	li	a4,0
ffffffffc0202a12:	4781                	li	a5,0
ffffffffc0202a14:	4805                	li	a6,1
ffffffffc0202a16:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202a1a:	953a                	add	a0,a0,a4
ffffffffc0202a1c:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fd48e94>
ffffffffc0202a20:	4106b02f          	amoor.d	zero,a6,(a3)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202a24:	6090                	ld	a2,0(s1)
ffffffffc0202a26:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202a28:	000bb503          	ld	a0,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202a2c:	00b606b3          	add	a3,a2,a1
ffffffffc0202a30:	04870713          	addi	a4,a4,72 # fffffffffff80048 <end+0x3fcc9ed4>
ffffffffc0202a34:	fed7e3e3          	bltu	a5,a3,ffffffffc0202a1a <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202a38:	00361693          	slli	a3,a2,0x3
ffffffffc0202a3c:	96b2                	add	a3,a3,a2
ffffffffc0202a3e:	fdc007b7          	lui	a5,0xfdc00
ffffffffc0202a42:	97aa                	add	a5,a5,a0
ffffffffc0202a44:	068e                	slli	a3,a3,0x3
ffffffffc0202a46:	96be                	add	a3,a3,a5
ffffffffc0202a48:	c02007b7          	lui	a5,0xc0200
ffffffffc0202a4c:	34f6eae3          	bltu	a3,a5,ffffffffc02035a0 <pmm_init+0xc4e>
ffffffffc0202a50:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202a54:	77fd                	lui	a5,0xfffff
ffffffffc0202a56:	00f97733          	and	a4,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202a5a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202a5c:	56e6e563          	bltu	a3,a4,ffffffffc0202fc6 <pmm_init+0x674>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202a60:	00004517          	auipc	a0,0x4
ffffffffc0202a64:	5b050513          	addi	a0,a0,1456 # ffffffffc0207010 <default_pmm_manager+0x220>
ffffffffc0202a68:	f2cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202a6c:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202a70:	000b3917          	auipc	s2,0xb3
ffffffffc0202a74:	6b890913          	addi	s2,s2,1720 # ffffffffc02b6128 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202a78:	7b9c                	ld	a5,48(a5)
ffffffffc0202a7a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202a7c:	00004517          	auipc	a0,0x4
ffffffffc0202a80:	5ac50513          	addi	a0,a0,1452 # ffffffffc0207028 <default_pmm_manager+0x238>
ffffffffc0202a84:	f10fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202a88:	00008697          	auipc	a3,0x8
ffffffffc0202a8c:	57868693          	addi	a3,a3,1400 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202a90:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202a94:	c02007b7          	lui	a5,0xc0200
ffffffffc0202a98:	2ef6e8e3          	bltu	a3,a5,ffffffffc0203588 <pmm_init+0xc36>
ffffffffc0202a9c:	0009b783          	ld	a5,0(s3)
ffffffffc0202aa0:	8e9d                	sub	a3,a3,a5
ffffffffc0202aa2:	000b3797          	auipc	a5,0xb3
ffffffffc0202aa6:	66d7bf23          	sd	a3,1662(a5) # ffffffffc02b6120 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202aaa:	100027f3          	csrr	a5,sstatus
ffffffffc0202aae:	8b89                	andi	a5,a5,2
ffffffffc0202ab0:	50079163          	bnez	a5,ffffffffc0202fb2 <pmm_init+0x660>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ab4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ab8:	779c                	ld	a5,40(a5)
ffffffffc0202aba:	9782                	jalr	a5
ffffffffc0202abc:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202abe:	6098                	ld	a4,0(s1)
ffffffffc0202ac0:	c80007b7          	lui	a5,0xc8000
ffffffffc0202ac4:	83b1                	srli	a5,a5,0xc
ffffffffc0202ac6:	6ce7e063          	bltu	a5,a4,ffffffffc0203186 <pmm_init+0x834>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202aca:	00093503          	ld	a0,0(s2)
ffffffffc0202ace:	68050c63          	beqz	a0,ffffffffc0203166 <pmm_init+0x814>
ffffffffc0202ad2:	03451793          	slli	a5,a0,0x34
ffffffffc0202ad6:	68079863          	bnez	a5,ffffffffc0203166 <pmm_init+0x814>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202ada:	4601                	li	a2,0
ffffffffc0202adc:	4581                	li	a1,0
ffffffffc0202ade:	843ff0ef          	jal	ra,ffffffffc0202320 <get_page>
ffffffffc0202ae2:	66051263          	bnez	a0,ffffffffc0203146 <pmm_init+0x7f4>
ffffffffc0202ae6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aea:	8b89                	andi	a5,a5,2
ffffffffc0202aec:	4a079863          	bnez	a5,ffffffffc0202f9c <pmm_init+0x64a>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202af0:	000b3783          	ld	a5,0(s6)
ffffffffc0202af4:	4505                	li	a0,1
ffffffffc0202af6:	6f9c                	ld	a5,24(a5)
ffffffffc0202af8:	9782                	jalr	a5
ffffffffc0202afa:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202afc:	00093503          	ld	a0,0(s2)
ffffffffc0202b00:	4681                	li	a3,0
ffffffffc0202b02:	4601                	li	a2,0
ffffffffc0202b04:	85d2                	mv	a1,s4
ffffffffc0202b06:	d41ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0202b0a:	2c0517e3          	bnez	a0,ffffffffc02035d8 <pmm_init+0xc86>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202b0e:	00093503          	ld	a0,0(s2)
ffffffffc0202b12:	4601                	li	a2,0
ffffffffc0202b14:	4581                	li	a1,0
ffffffffc0202b16:	dbeff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc0202b1a:	28050fe3          	beqz	a0,ffffffffc02035b8 <pmm_init+0xc66>
    assert(pte2page(*ptep) == p1);
ffffffffc0202b1e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202b20:	0017f713          	andi	a4,a5,1
ffffffffc0202b24:	5e070f63          	beqz	a4,ffffffffc0203122 <pmm_init+0x7d0>
    if (PPN(pa) >= npage)
ffffffffc0202b28:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202b2a:	078a                	slli	a5,a5,0x2
ffffffffc0202b2c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b2e:	5ec7f863          	bgeu	a5,a2,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b32:	fff80737          	lui	a4,0xfff80
ffffffffc0202b36:	97ba                	add	a5,a5,a4
ffffffffc0202b38:	000bb683          	ld	a3,0(s7)
ffffffffc0202b3c:	00379713          	slli	a4,a5,0x3
ffffffffc0202b40:	97ba                	add	a5,a5,a4
ffffffffc0202b42:	078e                	slli	a5,a5,0x3
ffffffffc0202b44:	97b6                	add	a5,a5,a3
ffffffffc0202b46:	1afa11e3          	bne	s4,a5,ffffffffc02034e8 <pmm_init+0xb96>
    assert(page_ref(p1) == 1);
ffffffffc0202b4a:	000a2703          	lw	a4,0(s4)
ffffffffc0202b4e:	4785                	li	a5,1
ffffffffc0202b50:	16f71ce3          	bne	a4,a5,ffffffffc02034c8 <pmm_init+0xb76>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202b54:	00093503          	ld	a0,0(s2)
ffffffffc0202b58:	77fd                	lui	a5,0xfffff
ffffffffc0202b5a:	6114                	ld	a3,0(a0)
ffffffffc0202b5c:	068a                	slli	a3,a3,0x2
ffffffffc0202b5e:	8efd                	and	a3,a3,a5
ffffffffc0202b60:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202b64:	14c776e3          	bgeu	a4,a2,ffffffffc02034b0 <pmm_init+0xb5e>
ffffffffc0202b68:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b6c:	96e2                	add	a3,a3,s8
ffffffffc0202b6e:	0006ba83          	ld	s5,0(a3)
ffffffffc0202b72:	0a8a                	slli	s5,s5,0x2
ffffffffc0202b74:	00fafab3          	and	s5,s5,a5
ffffffffc0202b78:	00cad793          	srli	a5,s5,0xc
ffffffffc0202b7c:	10c7fde3          	bgeu	a5,a2,ffffffffc0203496 <pmm_init+0xb44>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b80:	4601                	li	a2,0
ffffffffc0202b82:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b84:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b86:	d4eff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b8a:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b8c:	59551d63          	bne	a0,s5,ffffffffc0203126 <pmm_init+0x7d4>
ffffffffc0202b90:	100027f3          	csrr	a5,sstatus
ffffffffc0202b94:	8b89                	andi	a5,a5,2
ffffffffc0202b96:	3e079863          	bnez	a5,ffffffffc0202f86 <pmm_init+0x634>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202b9e:	4505                	li	a0,1
ffffffffc0202ba0:	6f9c                	ld	a5,24(a5)
ffffffffc0202ba2:	9782                	jalr	a5
ffffffffc0202ba4:	8aaa                	mv	s5,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202ba6:	00093503          	ld	a0,0(s2)
ffffffffc0202baa:	46d1                	li	a3,20
ffffffffc0202bac:	6605                	lui	a2,0x1
ffffffffc0202bae:	85d6                	mv	a1,s5
ffffffffc0202bb0:	c97ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0202bb4:	0c0511e3          	bnez	a0,ffffffffc0203476 <pmm_init+0xb24>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bb8:	00093503          	ld	a0,0(s2)
ffffffffc0202bbc:	4601                	li	a2,0
ffffffffc0202bbe:	6585                	lui	a1,0x1
ffffffffc0202bc0:	d14ff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc0202bc4:	080509e3          	beqz	a0,ffffffffc0203456 <pmm_init+0xb04>
    assert(*ptep & PTE_U);
ffffffffc0202bc8:	611c                	ld	a5,0(a0)
ffffffffc0202bca:	0107f713          	andi	a4,a5,16
ffffffffc0202bce:	020708e3          	beqz	a4,ffffffffc02033fe <pmm_init+0xaac>
    assert(*ptep & PTE_W);
ffffffffc0202bd2:	8b91                	andi	a5,a5,4
ffffffffc0202bd4:	000785e3          	beqz	a5,ffffffffc02033de <pmm_init+0xa8c>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202bd8:	00093503          	ld	a0,0(s2)
ffffffffc0202bdc:	611c                	ld	a5,0(a0)
ffffffffc0202bde:	8bc1                	andi	a5,a5,16
ffffffffc0202be0:	7c078f63          	beqz	a5,ffffffffc02033be <pmm_init+0xa6c>
    assert(page_ref(p2) == 1);
ffffffffc0202be4:	000aa703          	lw	a4,0(s5)
ffffffffc0202be8:	4785                	li	a5,1
ffffffffc0202bea:	7af71a63          	bne	a4,a5,ffffffffc020339e <pmm_init+0xa4c>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202bee:	4681                	li	a3,0
ffffffffc0202bf0:	6605                	lui	a2,0x1
ffffffffc0202bf2:	85d2                	mv	a1,s4
ffffffffc0202bf4:	c53ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0202bf8:	78051363          	bnez	a0,ffffffffc020337e <pmm_init+0xa2c>
    assert(page_ref(p1) == 2);
ffffffffc0202bfc:	000a2703          	lw	a4,0(s4)
ffffffffc0202c00:	4789                	li	a5,2
ffffffffc0202c02:	74f71e63          	bne	a4,a5,ffffffffc020335e <pmm_init+0xa0c>
    assert(page_ref(p2) == 0);
ffffffffc0202c06:	000aa783          	lw	a5,0(s5)
ffffffffc0202c0a:	72079a63          	bnez	a5,ffffffffc020333e <pmm_init+0x9ec>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202c0e:	00093503          	ld	a0,0(s2)
ffffffffc0202c12:	4601                	li	a2,0
ffffffffc0202c14:	6585                	lui	a1,0x1
ffffffffc0202c16:	cbeff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc0202c1a:	70050263          	beqz	a0,ffffffffc020331e <pmm_init+0x9cc>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c1e:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202c20:	00177793          	andi	a5,a4,1
ffffffffc0202c24:	4e078f63          	beqz	a5,ffffffffc0203122 <pmm_init+0x7d0>
    if (PPN(pa) >= npage)
ffffffffc0202c28:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c2a:	00271793          	slli	a5,a4,0x2
ffffffffc0202c2e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c30:	4ed7f763          	bgeu	a5,a3,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c34:	fff80c37          	lui	s8,0xfff80
ffffffffc0202c38:	97e2                	add	a5,a5,s8
ffffffffc0202c3a:	000bb603          	ld	a2,0(s7)
ffffffffc0202c3e:	00379693          	slli	a3,a5,0x3
ffffffffc0202c42:	97b6                	add	a5,a5,a3
ffffffffc0202c44:	078e                	slli	a5,a5,0x3
ffffffffc0202c46:	97b2                	add	a5,a5,a2
ffffffffc0202c48:	6afa1b63          	bne	s4,a5,ffffffffc02032fe <pmm_init+0x9ac>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202c4c:	8b41                	andi	a4,a4,16
ffffffffc0202c4e:	68071863          	bnez	a4,ffffffffc02032de <pmm_init+0x98c>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202c52:	00093503          	ld	a0,0(s2)
ffffffffc0202c56:	4581                	li	a1,0
ffffffffc0202c58:	b4dff0ef          	jal	ra,ffffffffc02027a4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202c5c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202c60:	4785                	li	a5,1
ffffffffc0202c62:	64fc9e63          	bne	s9,a5,ffffffffc02032be <pmm_init+0x96c>
    assert(page_ref(p2) == 0);
ffffffffc0202c66:	000aa783          	lw	a5,0(s5)
ffffffffc0202c6a:	62079a63          	bnez	a5,ffffffffc020329e <pmm_init+0x94c>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202c6e:	00093503          	ld	a0,0(s2)
ffffffffc0202c72:	6585                	lui	a1,0x1
ffffffffc0202c74:	b31ff0ef          	jal	ra,ffffffffc02027a4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202c78:	000a2783          	lw	a5,0(s4)
ffffffffc0202c7c:	58079163          	bnez	a5,ffffffffc02031fe <pmm_init+0x8ac>
    assert(page_ref(p2) == 0);
ffffffffc0202c80:	000aa783          	lw	a5,0(s5)
ffffffffc0202c84:	54079d63          	bnez	a5,ffffffffc02031de <pmm_init+0x88c>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202c88:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c8c:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c8e:	000a3783          	ld	a5,0(s4)
ffffffffc0202c92:	078a                	slli	a5,a5,0x2
ffffffffc0202c94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c96:	48c7f463          	bgeu	a5,a2,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c9a:	01878733          	add	a4,a5,s8
ffffffffc0202c9e:	00371793          	slli	a5,a4,0x3
ffffffffc0202ca2:	000bb503          	ld	a0,0(s7)
ffffffffc0202ca6:	97ba                	add	a5,a5,a4
ffffffffc0202ca8:	078e                	slli	a5,a5,0x3
    return page->ref;
ffffffffc0202caa:	00f50733          	add	a4,a0,a5
ffffffffc0202cae:	4318                	lw	a4,0(a4)
ffffffffc0202cb0:	51971763          	bne	a4,s9,ffffffffc02031be <pmm_init+0x86c>
    return page - pages + nbase;
ffffffffc0202cb4:	4037d693          	srai	a3,a5,0x3
ffffffffc0202cb8:	00005c97          	auipc	s9,0x5
ffffffffc0202cbc:	4f0cbc83          	ld	s9,1264(s9) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0202cc0:	039686b3          	mul	a3,a3,s9
ffffffffc0202cc4:	000805b7          	lui	a1,0x80
ffffffffc0202cc8:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0202cca:	00c69713          	slli	a4,a3,0xc
ffffffffc0202cce:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cd0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cd2:	4cc77a63          	bgeu	a4,a2,ffffffffc02031a6 <pmm_init+0x854>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202cd6:	0009b703          	ld	a4,0(s3)
ffffffffc0202cda:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cdc:	629c                	ld	a5,0(a3)
ffffffffc0202cde:	078a                	slli	a5,a5,0x2
ffffffffc0202ce0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ce2:	42c7fe63          	bgeu	a5,a2,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ce6:	8f8d                	sub	a5,a5,a1
ffffffffc0202ce8:	00379713          	slli	a4,a5,0x3
ffffffffc0202cec:	97ba                	add	a5,a5,a4
ffffffffc0202cee:	078e                	slli	a5,a5,0x3
ffffffffc0202cf0:	953e                	add	a0,a0,a5
ffffffffc0202cf2:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf6:	8b89                	andi	a5,a5,2
ffffffffc0202cf8:	34079263          	bnez	a5,ffffffffc020303c <pmm_init+0x6ea>
        pmm_manager->free_pages(base, n);
ffffffffc0202cfc:	000b3783          	ld	a5,0(s6)
ffffffffc0202d00:	4585                	li	a1,1
ffffffffc0202d02:	739c                	ld	a5,32(a5)
ffffffffc0202d04:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d06:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202d0a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d0c:	078a                	slli	a5,a5,0x2
ffffffffc0202d0e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d10:	40e7f763          	bgeu	a5,a4,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d14:	fff80737          	lui	a4,0xfff80
ffffffffc0202d18:	97ba                	add	a5,a5,a4
ffffffffc0202d1a:	000bb503          	ld	a0,0(s7)
ffffffffc0202d1e:	00379713          	slli	a4,a5,0x3
ffffffffc0202d22:	97ba                	add	a5,a5,a4
ffffffffc0202d24:	078e                	slli	a5,a5,0x3
ffffffffc0202d26:	953e                	add	a0,a0,a5
ffffffffc0202d28:	100027f3          	csrr	a5,sstatus
ffffffffc0202d2c:	8b89                	andi	a5,a5,2
ffffffffc0202d2e:	2e079b63          	bnez	a5,ffffffffc0203024 <pmm_init+0x6d2>
ffffffffc0202d32:	000b3783          	ld	a5,0(s6)
ffffffffc0202d36:	4585                	li	a1,1
ffffffffc0202d38:	739c                	ld	a5,32(a5)
ffffffffc0202d3a:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d3c:	00093783          	ld	a5,0(s2)
ffffffffc0202d40:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd48e8c>
    asm volatile("sfence.vma");
ffffffffc0202d44:	12000073          	sfence.vma
ffffffffc0202d48:	100027f3          	csrr	a5,sstatus
ffffffffc0202d4c:	8b89                	andi	a5,a5,2
ffffffffc0202d4e:	2c079163          	bnez	a5,ffffffffc0203010 <pmm_init+0x6be>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d52:	000b3783          	ld	a5,0(s6)
ffffffffc0202d56:	779c                	ld	a5,40(a5)
ffffffffc0202d58:	9782                	jalr	a5
ffffffffc0202d5a:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d5c:	4f441163          	bne	s0,s4,ffffffffc020323e <pmm_init+0x8ec>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202d60:	00004517          	auipc	a0,0x4
ffffffffc0202d64:	5f050513          	addi	a0,a0,1520 # ffffffffc0207350 <default_pmm_manager+0x560>
ffffffffc0202d68:	c2cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202d6c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d70:	8b89                	andi	a5,a5,2
ffffffffc0202d72:	28079563          	bnez	a5,ffffffffc0202ffc <pmm_init+0x6aa>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d76:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7a:	779c                	ld	a5,40(a5)
ffffffffc0202d7c:	9782                	jalr	a5
ffffffffc0202d7e:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d80:	6098                	ld	a4,0(s1)
ffffffffc0202d82:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d86:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d88:	00c71793          	slli	a5,a4,0xc
ffffffffc0202d8c:	6a05                	lui	s4,0x1
ffffffffc0202d8e:	02f47c63          	bgeu	s0,a5,ffffffffc0202dc6 <pmm_init+0x474>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d92:	00c45793          	srli	a5,s0,0xc
ffffffffc0202d96:	00093503          	ld	a0,0(s2)
ffffffffc0202d9a:	32e7f563          	bgeu	a5,a4,ffffffffc02030c4 <pmm_init+0x772>
ffffffffc0202d9e:	0009b583          	ld	a1,0(s3)
ffffffffc0202da2:	4601                	li	a2,0
ffffffffc0202da4:	95a2                	add	a1,a1,s0
ffffffffc0202da6:	b2eff0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc0202daa:	34050a63          	beqz	a0,ffffffffc02030fe <pmm_init+0x7ac>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202dae:	611c                	ld	a5,0(a0)
ffffffffc0202db0:	078a                	slli	a5,a5,0x2
ffffffffc0202db2:	0157f7b3          	and	a5,a5,s5
ffffffffc0202db6:	32879463          	bne	a5,s0,ffffffffc02030de <pmm_init+0x78c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202dba:	6098                	ld	a4,0(s1)
ffffffffc0202dbc:	9452                	add	s0,s0,s4
ffffffffc0202dbe:	00c71793          	slli	a5,a4,0xc
ffffffffc0202dc2:	fcf468e3          	bltu	s0,a5,ffffffffc0202d92 <pmm_init+0x440>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202dc6:	00093783          	ld	a5,0(s2)
ffffffffc0202dca:	639c                	ld	a5,0(a5)
ffffffffc0202dcc:	44079963          	bnez	a5,ffffffffc020321e <pmm_init+0x8cc>
ffffffffc0202dd0:	100027f3          	csrr	a5,sstatus
ffffffffc0202dd4:	8b89                	andi	a5,a5,2
ffffffffc0202dd6:	26079f63          	bnez	a5,ffffffffc0203054 <pmm_init+0x702>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dda:	000b3783          	ld	a5,0(s6)
ffffffffc0202dde:	4505                	li	a0,1
ffffffffc0202de0:	6f9c                	ld	a5,24(a5)
ffffffffc0202de2:	9782                	jalr	a5
ffffffffc0202de4:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202de6:	00093503          	ld	a0,0(s2)
ffffffffc0202dea:	4699                	li	a3,6
ffffffffc0202dec:	10000613          	li	a2,256
ffffffffc0202df0:	85a2                	mv	a1,s0
ffffffffc0202df2:	a55ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0202df6:	48051463          	bnez	a0,ffffffffc020327e <pmm_init+0x92c>
    assert(page_ref(p) == 1);
ffffffffc0202dfa:	4018                	lw	a4,0(s0)
ffffffffc0202dfc:	4785                	li	a5,1
ffffffffc0202dfe:	46f71063          	bne	a4,a5,ffffffffc020325e <pmm_init+0x90c>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e02:	00093503          	ld	a0,0(s2)
ffffffffc0202e06:	6a05                	lui	s4,0x1
ffffffffc0202e08:	4699                	li	a3,6
ffffffffc0202e0a:	100a0613          	addi	a2,s4,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ac0>
ffffffffc0202e0e:	85a2                	mv	a1,s0
ffffffffc0202e10:	a37ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0202e14:	74051a63          	bnez	a0,ffffffffc0203568 <pmm_init+0xc16>
    assert(page_ref(p) == 2);
ffffffffc0202e18:	4018                	lw	a4,0(s0)
ffffffffc0202e1a:	4789                	li	a5,2
ffffffffc0202e1c:	72f71663          	bne	a4,a5,ffffffffc0203548 <pmm_init+0xbf6>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202e20:	00004597          	auipc	a1,0x4
ffffffffc0202e24:	67858593          	addi	a1,a1,1656 # ffffffffc0207498 <default_pmm_manager+0x6a8>
ffffffffc0202e28:	10000513          	li	a0,256
ffffffffc0202e2c:	0a8030ef          	jal	ra,ffffffffc0205ed4 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202e30:	100a0593          	addi	a1,s4,256
ffffffffc0202e34:	10000513          	li	a0,256
ffffffffc0202e38:	0ae030ef          	jal	ra,ffffffffc0205ee6 <strcmp>
ffffffffc0202e3c:	6e051663          	bnez	a0,ffffffffc0203528 <pmm_init+0xbd6>
    return page - pages + nbase;
ffffffffc0202e40:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0202e44:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0202e46:	00080ab7          	lui	s5,0x80
ffffffffc0202e4a:	40d406b3          	sub	a3,s0,a3
ffffffffc0202e4e:	868d                	srai	a3,a3,0x3
ffffffffc0202e50:	039686b3          	mul	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0202e54:	6098                	ld	a4,0(s1)
ffffffffc0202e56:	00c7dd13          	srli	s10,a5,0xc
    return page - pages + nbase;
ffffffffc0202e5a:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0202e5c:	01a6f7b3          	and	a5,a3,s10
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e60:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e62:	34e7f263          	bgeu	a5,a4,ffffffffc02031a6 <pmm_init+0x854>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202e66:	0009b703          	ld	a4,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202e6a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202e6e:	96ba                	add	a3,a3,a4
ffffffffc0202e70:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202e74:	02a030ef          	jal	ra,ffffffffc0205e9e <strlen>
ffffffffc0202e78:	68051863          	bnez	a0,ffffffffc0203508 <pmm_init+0xbb6>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202e7c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202e80:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e82:	000a3783          	ld	a5,0(s4)
ffffffffc0202e86:	078a                	slli	a5,a5,0x2
ffffffffc0202e88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e8a:	28e7fa63          	bgeu	a5,a4,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e8e:	415787b3          	sub	a5,a5,s5
ffffffffc0202e92:	00379693          	slli	a3,a5,0x3
    return page - pages + nbase;
ffffffffc0202e96:	96be                	add	a3,a3,a5
ffffffffc0202e98:	03968cb3          	mul	s9,a3,s9
ffffffffc0202e9c:	015c86b3          	add	a3,s9,s5
    return KADDR(page2pa(page));
ffffffffc0202ea0:	01a6f7b3          	and	a5,a3,s10
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ea4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ea6:	30e7f063          	bgeu	a5,a4,ffffffffc02031a6 <pmm_init+0x854>
ffffffffc0202eaa:	0009b983          	ld	s3,0(s3)
ffffffffc0202eae:	99b6                	add	s3,s3,a3
ffffffffc0202eb0:	100027f3          	csrr	a5,sstatus
ffffffffc0202eb4:	8b89                	andi	a5,a5,2
ffffffffc0202eb6:	1e079c63          	bnez	a5,ffffffffc02030ae <pmm_init+0x75c>
        pmm_manager->free_pages(base, n);
ffffffffc0202eba:	000b3783          	ld	a5,0(s6)
ffffffffc0202ebe:	4585                	li	a1,1
ffffffffc0202ec0:	8522                	mv	a0,s0
ffffffffc0202ec2:	739c                	ld	a5,32(a5)
ffffffffc0202ec4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ec6:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202eca:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ecc:	078a                	slli	a5,a5,0x2
ffffffffc0202ece:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ed0:	24e7f763          	bgeu	a5,a4,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ed4:	fff80737          	lui	a4,0xfff80
ffffffffc0202ed8:	97ba                	add	a5,a5,a4
ffffffffc0202eda:	000bb503          	ld	a0,0(s7)
ffffffffc0202ede:	00379713          	slli	a4,a5,0x3
ffffffffc0202ee2:	97ba                	add	a5,a5,a4
ffffffffc0202ee4:	078e                	slli	a5,a5,0x3
ffffffffc0202ee6:	953e                	add	a0,a0,a5
ffffffffc0202ee8:	100027f3          	csrr	a5,sstatus
ffffffffc0202eec:	8b89                	andi	a5,a5,2
ffffffffc0202eee:	1a079463          	bnez	a5,ffffffffc0203096 <pmm_init+0x744>
ffffffffc0202ef2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ef6:	4585                	li	a1,1
ffffffffc0202ef8:	739c                	ld	a5,32(a5)
ffffffffc0202efa:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202efc:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202f00:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f02:	078a                	slli	a5,a5,0x2
ffffffffc0202f04:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202f06:	20e7fc63          	bgeu	a5,a4,ffffffffc020311e <pmm_init+0x7cc>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f0a:	fff80737          	lui	a4,0xfff80
ffffffffc0202f0e:	97ba                	add	a5,a5,a4
ffffffffc0202f10:	000bb503          	ld	a0,0(s7)
ffffffffc0202f14:	00379713          	slli	a4,a5,0x3
ffffffffc0202f18:	97ba                	add	a5,a5,a4
ffffffffc0202f1a:	078e                	slli	a5,a5,0x3
ffffffffc0202f1c:	953e                	add	a0,a0,a5
ffffffffc0202f1e:	100027f3          	csrr	a5,sstatus
ffffffffc0202f22:	8b89                	andi	a5,a5,2
ffffffffc0202f24:	14079d63          	bnez	a5,ffffffffc020307e <pmm_init+0x72c>
ffffffffc0202f28:	000b3783          	ld	a5,0(s6)
ffffffffc0202f2c:	4585                	li	a1,1
ffffffffc0202f2e:	739c                	ld	a5,32(a5)
ffffffffc0202f30:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202f32:	00093783          	ld	a5,0(s2)
ffffffffc0202f36:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202f3a:	12000073          	sfence.vma
ffffffffc0202f3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202f42:	8b89                	andi	a5,a5,2
ffffffffc0202f44:	12079363          	bnez	a5,ffffffffc020306a <pmm_init+0x718>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f48:	000b3783          	ld	a5,0(s6)
ffffffffc0202f4c:	779c                	ld	a5,40(a5)
ffffffffc0202f4e:	9782                	jalr	a5
ffffffffc0202f50:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202f52:	4e8c1263          	bne	s8,s0,ffffffffc0203436 <pmm_init+0xae4>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202f56:	00004517          	auipc	a0,0x4
ffffffffc0202f5a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0207510 <default_pmm_manager+0x720>
ffffffffc0202f5e:	a36fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202f62:	7406                	ld	s0,96(sp)
ffffffffc0202f64:	70a6                	ld	ra,104(sp)
ffffffffc0202f66:	64e6                	ld	s1,88(sp)
ffffffffc0202f68:	6946                	ld	s2,80(sp)
ffffffffc0202f6a:	69a6                	ld	s3,72(sp)
ffffffffc0202f6c:	6a06                	ld	s4,64(sp)
ffffffffc0202f6e:	7ae2                	ld	s5,56(sp)
ffffffffc0202f70:	7b42                	ld	s6,48(sp)
ffffffffc0202f72:	7ba2                	ld	s7,40(sp)
ffffffffc0202f74:	7c02                	ld	s8,32(sp)
ffffffffc0202f76:	6ce2                	ld	s9,24(sp)
ffffffffc0202f78:	6d42                	ld	s10,16(sp)
ffffffffc0202f7a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202f7c:	e99fe06f          	j	ffffffffc0201e14 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202f80:	c8000637          	lui	a2,0xc8000
ffffffffc0202f84:	b485                	j	ffffffffc02029e4 <pmm_init+0x92>
        intr_disable();
ffffffffc0202f86:	a2ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202f8a:	000b3783          	ld	a5,0(s6)
ffffffffc0202f8e:	4505                	li	a0,1
ffffffffc0202f90:	6f9c                	ld	a5,24(a5)
ffffffffc0202f92:	9782                	jalr	a5
ffffffffc0202f94:	8aaa                	mv	s5,a0
        intr_enable();
ffffffffc0202f96:	a19fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f9a:	b131                	j	ffffffffc0202ba6 <pmm_init+0x254>
        intr_disable();
ffffffffc0202f9c:	a19fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202fa0:	000b3783          	ld	a5,0(s6)
ffffffffc0202fa4:	4505                	li	a0,1
ffffffffc0202fa6:	6f9c                	ld	a5,24(a5)
ffffffffc0202fa8:	9782                	jalr	a5
ffffffffc0202faa:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202fac:	a03fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fb0:	b6b1                	j	ffffffffc0202afc <pmm_init+0x1aa>
        intr_disable();
ffffffffc0202fb2:	a03fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202fb6:	000b3783          	ld	a5,0(s6)
ffffffffc0202fba:	779c                	ld	a5,40(a5)
ffffffffc0202fbc:	9782                	jalr	a5
ffffffffc0202fbe:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202fc0:	9effd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fc4:	bced                	j	ffffffffc0202abe <pmm_init+0x16c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202fc6:	6585                	lui	a1,0x1
ffffffffc0202fc8:	15fd                	addi	a1,a1,-1
ffffffffc0202fca:	96ae                	add	a3,a3,a1
ffffffffc0202fcc:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202fce:	00c7d693          	srli	a3,a5,0xc
ffffffffc0202fd2:	14c6f663          	bgeu	a3,a2,ffffffffc020311e <pmm_init+0x7cc>
    pmm_manager->init_memmap(base, n);
ffffffffc0202fd6:	000b3583          	ld	a1,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202fda:	fff80637          	lui	a2,0xfff80
ffffffffc0202fde:	9636                	add	a2,a2,a3
ffffffffc0202fe0:	00361693          	slli	a3,a2,0x3
ffffffffc0202fe4:	96b2                	add	a3,a3,a2
ffffffffc0202fe6:	6990                	ld	a2,16(a1)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202fe8:	40f707b3          	sub	a5,a4,a5
ffffffffc0202fec:	068e                	slli	a3,a3,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0202fee:	00c7d593          	srli	a1,a5,0xc
ffffffffc0202ff2:	9536                	add	a0,a0,a3
ffffffffc0202ff4:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202ff6:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202ffa:	b49d                	j	ffffffffc0202a60 <pmm_init+0x10e>
        intr_disable();
ffffffffc0202ffc:	9b9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203000:	000b3783          	ld	a5,0(s6)
ffffffffc0203004:	779c                	ld	a5,40(a5)
ffffffffc0203006:	9782                	jalr	a5
ffffffffc0203008:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020300a:	9a5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020300e:	bb8d                	j	ffffffffc0202d80 <pmm_init+0x42e>
        intr_disable();
ffffffffc0203010:	9a5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203014:	000b3783          	ld	a5,0(s6)
ffffffffc0203018:	779c                	ld	a5,40(a5)
ffffffffc020301a:	9782                	jalr	a5
ffffffffc020301c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020301e:	991fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203022:	bb2d                	j	ffffffffc0202d5c <pmm_init+0x40a>
ffffffffc0203024:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203026:	98ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020302a:	000b3783          	ld	a5,0(s6)
ffffffffc020302e:	6522                	ld	a0,8(sp)
ffffffffc0203030:	4585                	li	a1,1
ffffffffc0203032:	739c                	ld	a5,32(a5)
ffffffffc0203034:	9782                	jalr	a5
        intr_enable();
ffffffffc0203036:	979fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020303a:	b309                	j	ffffffffc0202d3c <pmm_init+0x3ea>
ffffffffc020303c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020303e:	977fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203042:	000b3783          	ld	a5,0(s6)
ffffffffc0203046:	6522                	ld	a0,8(sp)
ffffffffc0203048:	4585                	li	a1,1
ffffffffc020304a:	739c                	ld	a5,32(a5)
ffffffffc020304c:	9782                	jalr	a5
        intr_enable();
ffffffffc020304e:	961fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203052:	b955                	j	ffffffffc0202d06 <pmm_init+0x3b4>
        intr_disable();
ffffffffc0203054:	961fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203058:	000b3783          	ld	a5,0(s6)
ffffffffc020305c:	4505                	li	a0,1
ffffffffc020305e:	6f9c                	ld	a5,24(a5)
ffffffffc0203060:	9782                	jalr	a5
ffffffffc0203062:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203064:	94bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203068:	bbbd                	j	ffffffffc0202de6 <pmm_init+0x494>
        intr_disable();
ffffffffc020306a:	94bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020306e:	000b3783          	ld	a5,0(s6)
ffffffffc0203072:	779c                	ld	a5,40(a5)
ffffffffc0203074:	9782                	jalr	a5
ffffffffc0203076:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203078:	937fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020307c:	bdd9                	j	ffffffffc0202f52 <pmm_init+0x600>
ffffffffc020307e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203080:	935fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203084:	000b3783          	ld	a5,0(s6)
ffffffffc0203088:	6522                	ld	a0,8(sp)
ffffffffc020308a:	4585                	li	a1,1
ffffffffc020308c:	739c                	ld	a5,32(a5)
ffffffffc020308e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203090:	91ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203094:	bd79                	j	ffffffffc0202f32 <pmm_init+0x5e0>
ffffffffc0203096:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203098:	91dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020309c:	000b3783          	ld	a5,0(s6)
ffffffffc02030a0:	6522                	ld	a0,8(sp)
ffffffffc02030a2:	4585                	li	a1,1
ffffffffc02030a4:	739c                	ld	a5,32(a5)
ffffffffc02030a6:	9782                	jalr	a5
        intr_enable();
ffffffffc02030a8:	907fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02030ac:	bd81                	j	ffffffffc0202efc <pmm_init+0x5aa>
        intr_disable();
ffffffffc02030ae:	907fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02030b2:	000b3783          	ld	a5,0(s6)
ffffffffc02030b6:	4585                	li	a1,1
ffffffffc02030b8:	8522                	mv	a0,s0
ffffffffc02030ba:	739c                	ld	a5,32(a5)
ffffffffc02030bc:	9782                	jalr	a5
        intr_enable();
ffffffffc02030be:	8f1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02030c2:	b511                	j	ffffffffc0202ec6 <pmm_init+0x574>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02030c4:	86a2                	mv	a3,s0
ffffffffc02030c6:	00004617          	auipc	a2,0x4
ffffffffc02030ca:	d6260613          	addi	a2,a2,-670 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02030ce:	28d00593          	li	a1,653
ffffffffc02030d2:	00004517          	auipc	a0,0x4
ffffffffc02030d6:	e6e50513          	addi	a0,a0,-402 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02030da:	bb4fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02030de:	00004697          	auipc	a3,0x4
ffffffffc02030e2:	2d268693          	addi	a3,a3,722 # ffffffffc02073b0 <default_pmm_manager+0x5c0>
ffffffffc02030e6:	00004617          	auipc	a2,0x4
ffffffffc02030ea:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206a40 <commands+0x868>
ffffffffc02030ee:	28e00593          	li	a1,654
ffffffffc02030f2:	00004517          	auipc	a0,0x4
ffffffffc02030f6:	e4e50513          	addi	a0,a0,-434 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02030fa:	b94fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02030fe:	00004697          	auipc	a3,0x4
ffffffffc0203102:	27268693          	addi	a3,a3,626 # ffffffffc0207370 <default_pmm_manager+0x580>
ffffffffc0203106:	00004617          	auipc	a2,0x4
ffffffffc020310a:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206a40 <commands+0x868>
ffffffffc020310e:	28d00593          	li	a1,653
ffffffffc0203112:	00004517          	auipc	a0,0x4
ffffffffc0203116:	e2e50513          	addi	a0,a0,-466 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020311a:	b74fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020311e:	ec7fe0ef          	jal	ra,ffffffffc0201fe4 <pa2page.part.0>
ffffffffc0203122:	edffe0ef          	jal	ra,ffffffffc0202000 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203126:	00004697          	auipc	a3,0x4
ffffffffc020312a:	04268693          	addi	a3,a3,66 # ffffffffc0207168 <default_pmm_manager+0x378>
ffffffffc020312e:	00004617          	auipc	a2,0x4
ffffffffc0203132:	91260613          	addi	a2,a2,-1774 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203136:	25d00593          	li	a1,605
ffffffffc020313a:	00004517          	auipc	a0,0x4
ffffffffc020313e:	e0650513          	addi	a0,a0,-506 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203142:	b4cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203146:	00004697          	auipc	a3,0x4
ffffffffc020314a:	f6268693          	addi	a3,a3,-158 # ffffffffc02070a8 <default_pmm_manager+0x2b8>
ffffffffc020314e:	00004617          	auipc	a2,0x4
ffffffffc0203152:	8f260613          	addi	a2,a2,-1806 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203156:	25000593          	li	a1,592
ffffffffc020315a:	00004517          	auipc	a0,0x4
ffffffffc020315e:	de650513          	addi	a0,a0,-538 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203162:	b2cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0203166:	00004697          	auipc	a3,0x4
ffffffffc020316a:	f0268693          	addi	a3,a3,-254 # ffffffffc0207068 <default_pmm_manager+0x278>
ffffffffc020316e:	00004617          	auipc	a2,0x4
ffffffffc0203172:	8d260613          	addi	a2,a2,-1838 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203176:	24f00593          	li	a1,591
ffffffffc020317a:	00004517          	auipc	a0,0x4
ffffffffc020317e:	dc650513          	addi	a0,a0,-570 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203182:	b0cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203186:	00004697          	auipc	a3,0x4
ffffffffc020318a:	ec268693          	addi	a3,a3,-318 # ffffffffc0207048 <default_pmm_manager+0x258>
ffffffffc020318e:	00004617          	auipc	a2,0x4
ffffffffc0203192:	8b260613          	addi	a2,a2,-1870 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203196:	24e00593          	li	a1,590
ffffffffc020319a:	00004517          	auipc	a0,0x4
ffffffffc020319e:	da650513          	addi	a0,a0,-602 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02031a2:	aecfd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02031a6:	00004617          	auipc	a2,0x4
ffffffffc02031aa:	c8260613          	addi	a2,a2,-894 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02031ae:	08300593          	li	a1,131
ffffffffc02031b2:	00004517          	auipc	a0,0x4
ffffffffc02031b6:	c9e50513          	addi	a0,a0,-866 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc02031ba:	ad4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02031be:	00004697          	auipc	a3,0x4
ffffffffc02031c2:	13a68693          	addi	a3,a3,314 # ffffffffc02072f8 <default_pmm_manager+0x508>
ffffffffc02031c6:	00004617          	auipc	a2,0x4
ffffffffc02031ca:	87a60613          	addi	a2,a2,-1926 # ffffffffc0206a40 <commands+0x868>
ffffffffc02031ce:	27600593          	li	a1,630
ffffffffc02031d2:	00004517          	auipc	a0,0x4
ffffffffc02031d6:	d6e50513          	addi	a0,a0,-658 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02031da:	ab4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02031de:	00004697          	auipc	a3,0x4
ffffffffc02031e2:	0d268693          	addi	a3,a3,210 # ffffffffc02072b0 <default_pmm_manager+0x4c0>
ffffffffc02031e6:	00004617          	auipc	a2,0x4
ffffffffc02031ea:	85a60613          	addi	a2,a2,-1958 # ffffffffc0206a40 <commands+0x868>
ffffffffc02031ee:	27400593          	li	a1,628
ffffffffc02031f2:	00004517          	auipc	a0,0x4
ffffffffc02031f6:	d4e50513          	addi	a0,a0,-690 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02031fa:	a94fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02031fe:	00004697          	auipc	a3,0x4
ffffffffc0203202:	0e268693          	addi	a3,a3,226 # ffffffffc02072e0 <default_pmm_manager+0x4f0>
ffffffffc0203206:	00004617          	auipc	a2,0x4
ffffffffc020320a:	83a60613          	addi	a2,a2,-1990 # ffffffffc0206a40 <commands+0x868>
ffffffffc020320e:	27300593          	li	a1,627
ffffffffc0203212:	00004517          	auipc	a0,0x4
ffffffffc0203216:	d2e50513          	addi	a0,a0,-722 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020321a:	a74fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020321e:	00004697          	auipc	a3,0x4
ffffffffc0203222:	1aa68693          	addi	a3,a3,426 # ffffffffc02073c8 <default_pmm_manager+0x5d8>
ffffffffc0203226:	00004617          	auipc	a2,0x4
ffffffffc020322a:	81a60613          	addi	a2,a2,-2022 # ffffffffc0206a40 <commands+0x868>
ffffffffc020322e:	29100593          	li	a1,657
ffffffffc0203232:	00004517          	auipc	a0,0x4
ffffffffc0203236:	d0e50513          	addi	a0,a0,-754 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020323a:	a54fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020323e:	00004697          	auipc	a3,0x4
ffffffffc0203242:	0ea68693          	addi	a3,a3,234 # ffffffffc0207328 <default_pmm_manager+0x538>
ffffffffc0203246:	00003617          	auipc	a2,0x3
ffffffffc020324a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0206a40 <commands+0x868>
ffffffffc020324e:	27e00593          	li	a1,638
ffffffffc0203252:	00004517          	auipc	a0,0x4
ffffffffc0203256:	cee50513          	addi	a0,a0,-786 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020325a:	a34fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc020325e:	00004697          	auipc	a3,0x4
ffffffffc0203262:	1c268693          	addi	a3,a3,450 # ffffffffc0207420 <default_pmm_manager+0x630>
ffffffffc0203266:	00003617          	auipc	a2,0x3
ffffffffc020326a:	7da60613          	addi	a2,a2,2010 # ffffffffc0206a40 <commands+0x868>
ffffffffc020326e:	29600593          	li	a1,662
ffffffffc0203272:	00004517          	auipc	a0,0x4
ffffffffc0203276:	cce50513          	addi	a0,a0,-818 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020327a:	a14fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020327e:	00004697          	auipc	a3,0x4
ffffffffc0203282:	16268693          	addi	a3,a3,354 # ffffffffc02073e0 <default_pmm_manager+0x5f0>
ffffffffc0203286:	00003617          	auipc	a2,0x3
ffffffffc020328a:	7ba60613          	addi	a2,a2,1978 # ffffffffc0206a40 <commands+0x868>
ffffffffc020328e:	29500593          	li	a1,661
ffffffffc0203292:	00004517          	auipc	a0,0x4
ffffffffc0203296:	cae50513          	addi	a0,a0,-850 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020329a:	9f4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020329e:	00004697          	auipc	a3,0x4
ffffffffc02032a2:	01268693          	addi	a3,a3,18 # ffffffffc02072b0 <default_pmm_manager+0x4c0>
ffffffffc02032a6:	00003617          	auipc	a2,0x3
ffffffffc02032aa:	79a60613          	addi	a2,a2,1946 # ffffffffc0206a40 <commands+0x868>
ffffffffc02032ae:	27000593          	li	a1,624
ffffffffc02032b2:	00004517          	auipc	a0,0x4
ffffffffc02032b6:	c8e50513          	addi	a0,a0,-882 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02032ba:	9d4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032be:	00004697          	auipc	a3,0x4
ffffffffc02032c2:	e9268693          	addi	a3,a3,-366 # ffffffffc0207150 <default_pmm_manager+0x360>
ffffffffc02032c6:	00003617          	auipc	a2,0x3
ffffffffc02032ca:	77a60613          	addi	a2,a2,1914 # ffffffffc0206a40 <commands+0x868>
ffffffffc02032ce:	26f00593          	li	a1,623
ffffffffc02032d2:	00004517          	auipc	a0,0x4
ffffffffc02032d6:	c6e50513          	addi	a0,a0,-914 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02032da:	9b4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02032de:	00004697          	auipc	a3,0x4
ffffffffc02032e2:	fea68693          	addi	a3,a3,-22 # ffffffffc02072c8 <default_pmm_manager+0x4d8>
ffffffffc02032e6:	00003617          	auipc	a2,0x3
ffffffffc02032ea:	75a60613          	addi	a2,a2,1882 # ffffffffc0206a40 <commands+0x868>
ffffffffc02032ee:	26c00593          	li	a1,620
ffffffffc02032f2:	00004517          	auipc	a0,0x4
ffffffffc02032f6:	c4e50513          	addi	a0,a0,-946 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02032fa:	994fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032fe:	00004697          	auipc	a3,0x4
ffffffffc0203302:	e3a68693          	addi	a3,a3,-454 # ffffffffc0207138 <default_pmm_manager+0x348>
ffffffffc0203306:	00003617          	auipc	a2,0x3
ffffffffc020330a:	73a60613          	addi	a2,a2,1850 # ffffffffc0206a40 <commands+0x868>
ffffffffc020330e:	26b00593          	li	a1,619
ffffffffc0203312:	00004517          	auipc	a0,0x4
ffffffffc0203316:	c2e50513          	addi	a0,a0,-978 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020331a:	974fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020331e:	00004697          	auipc	a3,0x4
ffffffffc0203322:	eba68693          	addi	a3,a3,-326 # ffffffffc02071d8 <default_pmm_manager+0x3e8>
ffffffffc0203326:	00003617          	auipc	a2,0x3
ffffffffc020332a:	71a60613          	addi	a2,a2,1818 # ffffffffc0206a40 <commands+0x868>
ffffffffc020332e:	26a00593          	li	a1,618
ffffffffc0203332:	00004517          	auipc	a0,0x4
ffffffffc0203336:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020333a:	954fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020333e:	00004697          	auipc	a3,0x4
ffffffffc0203342:	f7268693          	addi	a3,a3,-142 # ffffffffc02072b0 <default_pmm_manager+0x4c0>
ffffffffc0203346:	00003617          	auipc	a2,0x3
ffffffffc020334a:	6fa60613          	addi	a2,a2,1786 # ffffffffc0206a40 <commands+0x868>
ffffffffc020334e:	26900593          	li	a1,617
ffffffffc0203352:	00004517          	auipc	a0,0x4
ffffffffc0203356:	bee50513          	addi	a0,a0,-1042 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020335a:	934fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020335e:	00004697          	auipc	a3,0x4
ffffffffc0203362:	f3a68693          	addi	a3,a3,-198 # ffffffffc0207298 <default_pmm_manager+0x4a8>
ffffffffc0203366:	00003617          	auipc	a2,0x3
ffffffffc020336a:	6da60613          	addi	a2,a2,1754 # ffffffffc0206a40 <commands+0x868>
ffffffffc020336e:	26800593          	li	a1,616
ffffffffc0203372:	00004517          	auipc	a0,0x4
ffffffffc0203376:	bce50513          	addi	a0,a0,-1074 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020337a:	914fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020337e:	00004697          	auipc	a3,0x4
ffffffffc0203382:	eea68693          	addi	a3,a3,-278 # ffffffffc0207268 <default_pmm_manager+0x478>
ffffffffc0203386:	00003617          	auipc	a2,0x3
ffffffffc020338a:	6ba60613          	addi	a2,a2,1722 # ffffffffc0206a40 <commands+0x868>
ffffffffc020338e:	26700593          	li	a1,615
ffffffffc0203392:	00004517          	auipc	a0,0x4
ffffffffc0203396:	bae50513          	addi	a0,a0,-1106 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020339a:	8f4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020339e:	00004697          	auipc	a3,0x4
ffffffffc02033a2:	eb268693          	addi	a3,a3,-334 # ffffffffc0207250 <default_pmm_manager+0x460>
ffffffffc02033a6:	00003617          	auipc	a2,0x3
ffffffffc02033aa:	69a60613          	addi	a2,a2,1690 # ffffffffc0206a40 <commands+0x868>
ffffffffc02033ae:	26500593          	li	a1,613
ffffffffc02033b2:	00004517          	auipc	a0,0x4
ffffffffc02033b6:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02033ba:	8d4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02033be:	00004697          	auipc	a3,0x4
ffffffffc02033c2:	e7268693          	addi	a3,a3,-398 # ffffffffc0207230 <default_pmm_manager+0x440>
ffffffffc02033c6:	00003617          	auipc	a2,0x3
ffffffffc02033ca:	67a60613          	addi	a2,a2,1658 # ffffffffc0206a40 <commands+0x868>
ffffffffc02033ce:	26400593          	li	a1,612
ffffffffc02033d2:	00004517          	auipc	a0,0x4
ffffffffc02033d6:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02033da:	8b4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02033de:	00004697          	auipc	a3,0x4
ffffffffc02033e2:	e4268693          	addi	a3,a3,-446 # ffffffffc0207220 <default_pmm_manager+0x430>
ffffffffc02033e6:	00003617          	auipc	a2,0x3
ffffffffc02033ea:	65a60613          	addi	a2,a2,1626 # ffffffffc0206a40 <commands+0x868>
ffffffffc02033ee:	26300593          	li	a1,611
ffffffffc02033f2:	00004517          	auipc	a0,0x4
ffffffffc02033f6:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02033fa:	894fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc02033fe:	00004697          	auipc	a3,0x4
ffffffffc0203402:	e1268693          	addi	a3,a3,-494 # ffffffffc0207210 <default_pmm_manager+0x420>
ffffffffc0203406:	00003617          	auipc	a2,0x3
ffffffffc020340a:	63a60613          	addi	a2,a2,1594 # ffffffffc0206a40 <commands+0x868>
ffffffffc020340e:	26200593          	li	a1,610
ffffffffc0203412:	00004517          	auipc	a0,0x4
ffffffffc0203416:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020341a:	874fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc020341e:	00004617          	auipc	a2,0x4
ffffffffc0203422:	b9260613          	addi	a2,a2,-1134 # ffffffffc0206fb0 <default_pmm_manager+0x1c0>
ffffffffc0203426:	06500593          	li	a1,101
ffffffffc020342a:	00004517          	auipc	a0,0x4
ffffffffc020342e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203432:	85cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203436:	00004697          	auipc	a3,0x4
ffffffffc020343a:	ef268693          	addi	a3,a3,-270 # ffffffffc0207328 <default_pmm_manager+0x538>
ffffffffc020343e:	00003617          	auipc	a2,0x3
ffffffffc0203442:	60260613          	addi	a2,a2,1538 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203446:	2a800593          	li	a1,680
ffffffffc020344a:	00004517          	auipc	a0,0x4
ffffffffc020344e:	af650513          	addi	a0,a0,-1290 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203452:	83cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203456:	00004697          	auipc	a3,0x4
ffffffffc020345a:	d8268693          	addi	a3,a3,-638 # ffffffffc02071d8 <default_pmm_manager+0x3e8>
ffffffffc020345e:	00003617          	auipc	a2,0x3
ffffffffc0203462:	5e260613          	addi	a2,a2,1506 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203466:	26100593          	li	a1,609
ffffffffc020346a:	00004517          	auipc	a0,0x4
ffffffffc020346e:	ad650513          	addi	a0,a0,-1322 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203472:	81cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203476:	00004697          	auipc	a3,0x4
ffffffffc020347a:	d2268693          	addi	a3,a3,-734 # ffffffffc0207198 <default_pmm_manager+0x3a8>
ffffffffc020347e:	00003617          	auipc	a2,0x3
ffffffffc0203482:	5c260613          	addi	a2,a2,1474 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203486:	26000593          	li	a1,608
ffffffffc020348a:	00004517          	auipc	a0,0x4
ffffffffc020348e:	ab650513          	addi	a0,a0,-1354 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203492:	ffdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203496:	86d6                	mv	a3,s5
ffffffffc0203498:	00004617          	auipc	a2,0x4
ffffffffc020349c:	99060613          	addi	a2,a2,-1648 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02034a0:	25c00593          	li	a1,604
ffffffffc02034a4:	00004517          	auipc	a0,0x4
ffffffffc02034a8:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02034ac:	fe3fc0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02034b0:	00004617          	auipc	a2,0x4
ffffffffc02034b4:	97860613          	addi	a2,a2,-1672 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc02034b8:	25b00593          	li	a1,603
ffffffffc02034bc:	00004517          	auipc	a0,0x4
ffffffffc02034c0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02034c4:	fcbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02034c8:	00004697          	auipc	a3,0x4
ffffffffc02034cc:	c8868693          	addi	a3,a3,-888 # ffffffffc0207150 <default_pmm_manager+0x360>
ffffffffc02034d0:	00003617          	auipc	a2,0x3
ffffffffc02034d4:	57060613          	addi	a2,a2,1392 # ffffffffc0206a40 <commands+0x868>
ffffffffc02034d8:	25900593          	li	a1,601
ffffffffc02034dc:	00004517          	auipc	a0,0x4
ffffffffc02034e0:	a6450513          	addi	a0,a0,-1436 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02034e4:	fabfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02034e8:	00004697          	auipc	a3,0x4
ffffffffc02034ec:	c5068693          	addi	a3,a3,-944 # ffffffffc0207138 <default_pmm_manager+0x348>
ffffffffc02034f0:	00003617          	auipc	a2,0x3
ffffffffc02034f4:	55060613          	addi	a2,a2,1360 # ffffffffc0206a40 <commands+0x868>
ffffffffc02034f8:	25800593          	li	a1,600
ffffffffc02034fc:	00004517          	auipc	a0,0x4
ffffffffc0203500:	a4450513          	addi	a0,a0,-1468 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203504:	f8bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203508:	00004697          	auipc	a3,0x4
ffffffffc020350c:	fe068693          	addi	a3,a3,-32 # ffffffffc02074e8 <default_pmm_manager+0x6f8>
ffffffffc0203510:	00003617          	auipc	a2,0x3
ffffffffc0203514:	53060613          	addi	a2,a2,1328 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203518:	29f00593          	li	a1,671
ffffffffc020351c:	00004517          	auipc	a0,0x4
ffffffffc0203520:	a2450513          	addi	a0,a0,-1500 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203524:	f6bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203528:	00004697          	auipc	a3,0x4
ffffffffc020352c:	f8868693          	addi	a3,a3,-120 # ffffffffc02074b0 <default_pmm_manager+0x6c0>
ffffffffc0203530:	00003617          	auipc	a2,0x3
ffffffffc0203534:	51060613          	addi	a2,a2,1296 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203538:	29c00593          	li	a1,668
ffffffffc020353c:	00004517          	auipc	a0,0x4
ffffffffc0203540:	a0450513          	addi	a0,a0,-1532 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203544:	f4bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203548:	00004697          	auipc	a3,0x4
ffffffffc020354c:	f3868693          	addi	a3,a3,-200 # ffffffffc0207480 <default_pmm_manager+0x690>
ffffffffc0203550:	00003617          	auipc	a2,0x3
ffffffffc0203554:	4f060613          	addi	a2,a2,1264 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203558:	29800593          	li	a1,664
ffffffffc020355c:	00004517          	auipc	a0,0x4
ffffffffc0203560:	9e450513          	addi	a0,a0,-1564 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203564:	f2bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203568:	00004697          	auipc	a3,0x4
ffffffffc020356c:	ed068693          	addi	a3,a3,-304 # ffffffffc0207438 <default_pmm_manager+0x648>
ffffffffc0203570:	00003617          	auipc	a2,0x3
ffffffffc0203574:	4d060613          	addi	a2,a2,1232 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203578:	29700593          	li	a1,663
ffffffffc020357c:	00004517          	auipc	a0,0x4
ffffffffc0203580:	9c450513          	addi	a0,a0,-1596 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203584:	f0bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203588:	00004617          	auipc	a2,0x4
ffffffffc020358c:	94860613          	addi	a2,a2,-1720 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0203590:	0c900593          	li	a1,201
ffffffffc0203594:	00004517          	auipc	a0,0x4
ffffffffc0203598:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020359c:	ef3fc0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02035a0:	00004617          	auipc	a2,0x4
ffffffffc02035a4:	93060613          	addi	a2,a2,-1744 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc02035a8:	08100593          	li	a1,129
ffffffffc02035ac:	00004517          	auipc	a0,0x4
ffffffffc02035b0:	99450513          	addi	a0,a0,-1644 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02035b4:	edbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02035b8:	00004697          	auipc	a3,0x4
ffffffffc02035bc:	b5068693          	addi	a3,a3,-1200 # ffffffffc0207108 <default_pmm_manager+0x318>
ffffffffc02035c0:	00003617          	auipc	a2,0x3
ffffffffc02035c4:	48060613          	addi	a2,a2,1152 # ffffffffc0206a40 <commands+0x868>
ffffffffc02035c8:	25700593          	li	a1,599
ffffffffc02035cc:	00004517          	auipc	a0,0x4
ffffffffc02035d0:	97450513          	addi	a0,a0,-1676 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02035d4:	ebbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02035d8:	00004697          	auipc	a3,0x4
ffffffffc02035dc:	b0068693          	addi	a3,a3,-1280 # ffffffffc02070d8 <default_pmm_manager+0x2e8>
ffffffffc02035e0:	00003617          	auipc	a2,0x3
ffffffffc02035e4:	46060613          	addi	a2,a2,1120 # ffffffffc0206a40 <commands+0x868>
ffffffffc02035e8:	25400593          	li	a1,596
ffffffffc02035ec:	00004517          	auipc	a0,0x4
ffffffffc02035f0:	95450513          	addi	a0,a0,-1708 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02035f4:	e9bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035f8 <copy_range>:
{
ffffffffc02035f8:	7119                	addi	sp,sp,-128
ffffffffc02035fa:	f8a2                	sd	s0,112(sp)
ffffffffc02035fc:	8436                	mv	s0,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035fe:	8ed1                	or	a3,a3,a2
{
ffffffffc0203600:	fc86                	sd	ra,120(sp)
ffffffffc0203602:	f4a6                	sd	s1,104(sp)
ffffffffc0203604:	f0ca                	sd	s2,96(sp)
ffffffffc0203606:	ecce                	sd	s3,88(sp)
ffffffffc0203608:	e8d2                	sd	s4,80(sp)
ffffffffc020360a:	e4d6                	sd	s5,72(sp)
ffffffffc020360c:	e0da                	sd	s6,64(sp)
ffffffffc020360e:	fc5e                	sd	s7,56(sp)
ffffffffc0203610:	f862                	sd	s8,48(sp)
ffffffffc0203612:	f466                	sd	s9,40(sp)
ffffffffc0203614:	f06a                	sd	s10,32(sp)
ffffffffc0203616:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203618:	16d2                	slli	a3,a3,0x34
ffffffffc020361a:	28069263          	bnez	a3,ffffffffc020389e <copy_range+0x2a6>
ffffffffc020361e:	8b3a                	mv	s6,a4
    assert(USER_ACCESS(start, end));
ffffffffc0203620:	00200737          	lui	a4,0x200
ffffffffc0203624:	8d32                	mv	s10,a2
ffffffffc0203626:	22e66463          	bltu	a2,a4,ffffffffc020384e <copy_range+0x256>
ffffffffc020362a:	22867263          	bgeu	a2,s0,ffffffffc020384e <copy_range+0x256>
ffffffffc020362e:	4705                	li	a4,1
ffffffffc0203630:	077e                	slli	a4,a4,0x1f
ffffffffc0203632:	20876e63          	bltu	a4,s0,ffffffffc020384e <copy_range+0x256>
ffffffffc0203636:	5bfd                	li	s7,-1
ffffffffc0203638:	89aa                	mv	s3,a0
ffffffffc020363a:	84ae                	mv	s1,a1
    if (PPN(pa) >= npage)
ffffffffc020363c:	000b3a97          	auipc	s5,0xb3
ffffffffc0203640:	af4a8a93          	addi	s5,s5,-1292 # ffffffffc02b6130 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203644:	000b3a17          	auipc	s4,0xb3
ffffffffc0203648:	af4a0a13          	addi	s4,s4,-1292 # ffffffffc02b6138 <pages>
    return page - pages + nbase;
ffffffffc020364c:	00005c17          	auipc	s8,0x5
ffffffffc0203650:	b5cc3c03          	ld	s8,-1188(s8) # ffffffffc02081a8 <error_string+0xc8>
    return KADDR(page2pa(page));
ffffffffc0203654:	00cbdb93          	srli	s7,s7,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203658:	000b3c97          	auipc	s9,0xb3
ffffffffc020365c:	ae8c8c93          	addi	s9,s9,-1304 # ffffffffc02b6140 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203660:	4601                	li	a2,0
ffffffffc0203662:	85ea                	mv	a1,s10
ffffffffc0203664:	8526                	mv	a0,s1
ffffffffc0203666:	a6ffe0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc020366a:	8daa                	mv	s11,a0
        if (ptep == NULL)
ffffffffc020366c:	c95d                	beqz	a0,ffffffffc0203722 <copy_range+0x12a>
        if (*ptep & PTE_V)
ffffffffc020366e:	6114                	ld	a3,0(a0)
ffffffffc0203670:	8a85                	andi	a3,a3,1
ffffffffc0203672:	e68d                	bnez	a3,ffffffffc020369c <copy_range+0xa4>
        start += PGSIZE;
ffffffffc0203674:	6705                	lui	a4,0x1
ffffffffc0203676:	9d3a                	add	s10,s10,a4
    } while (start != 0 && start < end);
ffffffffc0203678:	fe8d64e3          	bltu	s10,s0,ffffffffc0203660 <copy_range+0x68>
    return 0;
ffffffffc020367c:	4501                	li	a0,0
}
ffffffffc020367e:	70e6                	ld	ra,120(sp)
ffffffffc0203680:	7446                	ld	s0,112(sp)
ffffffffc0203682:	74a6                	ld	s1,104(sp)
ffffffffc0203684:	7906                	ld	s2,96(sp)
ffffffffc0203686:	69e6                	ld	s3,88(sp)
ffffffffc0203688:	6a46                	ld	s4,80(sp)
ffffffffc020368a:	6aa6                	ld	s5,72(sp)
ffffffffc020368c:	6b06                	ld	s6,64(sp)
ffffffffc020368e:	7be2                	ld	s7,56(sp)
ffffffffc0203690:	7c42                	ld	s8,48(sp)
ffffffffc0203692:	7ca2                	ld	s9,40(sp)
ffffffffc0203694:	7d02                	ld	s10,32(sp)
ffffffffc0203696:	6de2                	ld	s11,24(sp)
ffffffffc0203698:	6109                	addi	sp,sp,128
ffffffffc020369a:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc020369c:	4605                	li	a2,1
ffffffffc020369e:	85ea                	mv	a1,s10
ffffffffc02036a0:	854e                	mv	a0,s3
ffffffffc02036a2:	a33fe0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc02036a6:	14050663          	beqz	a0,ffffffffc02037f2 <copy_range+0x1fa>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02036aa:	000db683          	ld	a3,0(s11)
    if (!(pte & PTE_V))
ffffffffc02036ae:	0016f613          	andi	a2,a3,1
ffffffffc02036b2:	0006891b          	sext.w	s2,a3
ffffffffc02036b6:	1c060863          	beqz	a2,ffffffffc0203886 <copy_range+0x28e>
    if (PPN(pa) >= npage)
ffffffffc02036ba:	000ab603          	ld	a2,0(s5)
    return pa2page(PTE_ADDR(pte));
ffffffffc02036be:	068a                	slli	a3,a3,0x2
ffffffffc02036c0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02036c2:	16c6fa63          	bgeu	a3,a2,ffffffffc0203836 <copy_range+0x23e>
    return &pages[PPN(pa) - nbase];
ffffffffc02036c6:	fff805b7          	lui	a1,0xfff80
ffffffffc02036ca:	96ae                	add	a3,a3,a1
ffffffffc02036cc:	00369613          	slli	a2,a3,0x3
ffffffffc02036d0:	000a3583          	ld	a1,0(s4)
ffffffffc02036d4:	96b2                	add	a3,a3,a2
ffffffffc02036d6:	068e                	slli	a3,a3,0x3
ffffffffc02036d8:	95b6                	add	a1,a1,a3
            assert(page != NULL);
ffffffffc02036da:	12058e63          	beqz	a1,ffffffffc0203816 <copy_range+0x21e>
            if (share) {
ffffffffc02036de:	040b0f63          	beqz	s6,ffffffffc020373c <copy_range+0x144>
                uint32_t perm_shared = ((uint32_t)(*ptep & PTE_USER) & ~PTE_W) | PTE_COW;
ffffffffc02036e2:	01b97693          	andi	a3,s2,27
                if (page_insert(to, page, start, perm_shared) != 0)
ffffffffc02036e6:	1006e693          	ori	a3,a3,256
ffffffffc02036ea:	866a                	mv	a2,s10
ffffffffc02036ec:	854e                	mv	a0,s3
ffffffffc02036ee:	958ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc02036f2:	10051063          	bnez	a0,ffffffffc02037f2 <copy_range+0x1fa>
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc02036f6:	000db683          	ld	a3,0(s11)
ffffffffc02036fa:	efb6f693          	andi	a3,a3,-261
ffffffffc02036fe:	1006e693          	ori	a3,a3,256
ffffffffc0203702:	00ddb023          	sd	a3,0(s11)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203706:	120d0073          	sfence.vma	s10
                if (current != NULL) {
ffffffffc020370a:	000b3797          	auipc	a5,0xb3
ffffffffc020370e:	a4e78793          	addi	a5,a5,-1458 # ffffffffc02b6158 <current>
ffffffffc0203712:	6398                	ld	a4,0(a5)
ffffffffc0203714:	d325                	beqz	a4,ffffffffc0203674 <copy_range+0x7c>
                    pte_t *newpte = get_pte(to, start, 0);
ffffffffc0203716:	4601                	li	a2,0
ffffffffc0203718:	85ea                	mv	a1,s10
ffffffffc020371a:	854e                	mv	a0,s3
ffffffffc020371c:	9b9fe0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc0203720:	bf91                	j	ffffffffc0203674 <copy_range+0x7c>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203722:	00200637          	lui	a2,0x200
ffffffffc0203726:	00cd07b3          	add	a5,s10,a2
ffffffffc020372a:	ffe00637          	lui	a2,0xffe00
ffffffffc020372e:	00c7fd33          	and	s10,a5,a2
    } while (start != 0 && start < end);
ffffffffc0203732:	f40d05e3          	beqz	s10,ffffffffc020367c <copy_range+0x84>
ffffffffc0203736:	f28d65e3          	bltu	s10,s0,ffffffffc0203660 <copy_range+0x68>
ffffffffc020373a:	b789                	j	ffffffffc020367c <copy_range+0x84>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020373c:	10002773          	csrr	a4,sstatus
ffffffffc0203740:	8b09                	andi	a4,a4,2
ffffffffc0203742:	e42e                	sd	a1,8(sp)
ffffffffc0203744:	eb59                	bnez	a4,ffffffffc02037da <copy_range+0x1e2>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203746:	000cb703          	ld	a4,0(s9)
ffffffffc020374a:	4505                	li	a0,1
ffffffffc020374c:	6f18                	ld	a4,24(a4)
ffffffffc020374e:	9702                	jalr	a4
ffffffffc0203750:	65a2                	ld	a1,8(sp)
ffffffffc0203752:	8daa                	mv	s11,a0
                assert(npage != NULL);
ffffffffc0203754:	0a0d8163          	beqz	s11,ffffffffc02037f6 <copy_range+0x1fe>
    return page - pages + nbase;
ffffffffc0203758:	000a3703          	ld	a4,0(s4)
ffffffffc020375c:	000808b7          	lui	a7,0x80
    return KADDR(page2pa(page));
ffffffffc0203760:	000ab603          	ld	a2,0(s5)
    return page - pages + nbase;
ffffffffc0203764:	40e586b3          	sub	a3,a1,a4
ffffffffc0203768:	868d                	srai	a3,a3,0x3
ffffffffc020376a:	038686b3          	mul	a3,a3,s8
ffffffffc020376e:	96c6                	add	a3,a3,a7
    return KADDR(page2pa(page));
ffffffffc0203770:	0176f5b3          	and	a1,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0203774:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203776:	0ec5fc63          	bgeu	a1,a2,ffffffffc020386e <copy_range+0x276>
    return page - pages + nbase;
ffffffffc020377a:	40ed8733          	sub	a4,s11,a4
ffffffffc020377e:	870d                	srai	a4,a4,0x3
ffffffffc0203780:	03870733          	mul	a4,a4,s8
    return KADDR(page2pa(page));
ffffffffc0203784:	000b3797          	auipc	a5,0xb3
ffffffffc0203788:	9c478793          	addi	a5,a5,-1596 # ffffffffc02b6148 <va_pa_offset>
ffffffffc020378c:	6388                	ld	a0,0(a5)
ffffffffc020378e:	00a685b3          	add	a1,a3,a0
    return page - pages + nbase;
ffffffffc0203792:	011706b3          	add	a3,a4,a7
    return KADDR(page2pa(page));
ffffffffc0203796:	0176f733          	and	a4,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc020379a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020379c:	0cc77963          	bgeu	a4,a2,ffffffffc020386e <copy_range+0x276>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02037a0:	6605                	lui	a2,0x1
ffffffffc02037a2:	9536                	add	a0,a0,a3
ffffffffc02037a4:	7ae020ef          	jal	ra,ffffffffc0205f52 <memcpy>
                int ret = page_insert(to, npage, start, perm);
ffffffffc02037a8:	01f97693          	andi	a3,s2,31
ffffffffc02037ac:	866a                	mv	a2,s10
ffffffffc02037ae:	85ee                	mv	a1,s11
ffffffffc02037b0:	854e                	mv	a0,s3
ffffffffc02037b2:	894ff0ef          	jal	ra,ffffffffc0202846 <page_insert>
                assert(ret == 0);
ffffffffc02037b6:	ea050fe3          	beqz	a0,ffffffffc0203674 <copy_range+0x7c>
ffffffffc02037ba:	00004697          	auipc	a3,0x4
ffffffffc02037be:	d9668693          	addi	a3,a3,-618 # ffffffffc0207550 <default_pmm_manager+0x760>
ffffffffc02037c2:	00003617          	auipc	a2,0x3
ffffffffc02037c6:	27e60613          	addi	a2,a2,638 # ffffffffc0206a40 <commands+0x868>
ffffffffc02037ca:	1eb00593          	li	a1,491
ffffffffc02037ce:	00003517          	auipc	a0,0x3
ffffffffc02037d2:	77250513          	addi	a0,a0,1906 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02037d6:	cb9fc0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02037da:	9dafd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02037de:	000cb703          	ld	a4,0(s9)
ffffffffc02037e2:	4505                	li	a0,1
ffffffffc02037e4:	6f18                	ld	a4,24(a4)
ffffffffc02037e6:	9702                	jalr	a4
ffffffffc02037e8:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc02037ea:	9c4fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02037ee:	65a2                	ld	a1,8(sp)
ffffffffc02037f0:	b795                	j	ffffffffc0203754 <copy_range+0x15c>
                return -E_NO_MEM;
ffffffffc02037f2:	5571                	li	a0,-4
ffffffffc02037f4:	b569                	j	ffffffffc020367e <copy_range+0x86>
                assert(npage != NULL);
ffffffffc02037f6:	00004697          	auipc	a3,0x4
ffffffffc02037fa:	d4a68693          	addi	a3,a3,-694 # ffffffffc0207540 <default_pmm_manager+0x750>
ffffffffc02037fe:	00003617          	auipc	a2,0x3
ffffffffc0203802:	24260613          	addi	a2,a2,578 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203806:	1e100593          	li	a1,481
ffffffffc020380a:	00003517          	auipc	a0,0x3
ffffffffc020380e:	73650513          	addi	a0,a0,1846 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203812:	c7dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203816:	00004697          	auipc	a3,0x4
ffffffffc020381a:	d1a68693          	addi	a3,a3,-742 # ffffffffc0207530 <default_pmm_manager+0x740>
ffffffffc020381e:	00003617          	auipc	a2,0x3
ffffffffc0203822:	22260613          	addi	a2,a2,546 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203826:	19900593          	li	a1,409
ffffffffc020382a:	00003517          	auipc	a0,0x3
ffffffffc020382e:	71650513          	addi	a0,a0,1814 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203832:	c5dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203836:	00003617          	auipc	a2,0x3
ffffffffc020383a:	6c260613          	addi	a2,a2,1730 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc020383e:	07b00593          	li	a1,123
ffffffffc0203842:	00003517          	auipc	a0,0x3
ffffffffc0203846:	60e50513          	addi	a0,a0,1550 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc020384a:	c45fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020384e:	00003697          	auipc	a3,0x3
ffffffffc0203852:	73268693          	addi	a3,a3,1842 # ffffffffc0206f80 <default_pmm_manager+0x190>
ffffffffc0203856:	00003617          	auipc	a2,0x3
ffffffffc020385a:	1ea60613          	addi	a2,a2,490 # ffffffffc0206a40 <commands+0x868>
ffffffffc020385e:	17c00593          	li	a1,380
ffffffffc0203862:	00003517          	auipc	a0,0x3
ffffffffc0203866:	6de50513          	addi	a0,a0,1758 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc020386a:	c25fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020386e:	00003617          	auipc	a2,0x3
ffffffffc0203872:	5ba60613          	addi	a2,a2,1466 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0203876:	08300593          	li	a1,131
ffffffffc020387a:	00003517          	auipc	a0,0x3
ffffffffc020387e:	5d650513          	addi	a0,a0,1494 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0203882:	c0dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203886:	00003617          	auipc	a2,0x3
ffffffffc020388a:	69260613          	addi	a2,a2,1682 # ffffffffc0206f18 <default_pmm_manager+0x128>
ffffffffc020388e:	09100593          	li	a1,145
ffffffffc0203892:	00003517          	auipc	a0,0x3
ffffffffc0203896:	5be50513          	addi	a0,a0,1470 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc020389a:	bf5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020389e:	00003697          	auipc	a3,0x3
ffffffffc02038a2:	6b268693          	addi	a3,a3,1714 # ffffffffc0206f50 <default_pmm_manager+0x160>
ffffffffc02038a6:	00003617          	auipc	a2,0x3
ffffffffc02038aa:	19a60613          	addi	a2,a2,410 # ffffffffc0206a40 <commands+0x868>
ffffffffc02038ae:	17b00593          	li	a1,379
ffffffffc02038b2:	00003517          	auipc	a0,0x3
ffffffffc02038b6:	68e50513          	addi	a0,a0,1678 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc02038ba:	bd5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038be <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02038be:	12058073          	sfence.vma	a1
}
ffffffffc02038c2:	8082                	ret

ffffffffc02038c4 <pgdir_alloc_page>:
{
ffffffffc02038c4:	7179                	addi	sp,sp,-48
ffffffffc02038c6:	ec26                	sd	s1,24(sp)
ffffffffc02038c8:	e84a                	sd	s2,16(sp)
ffffffffc02038ca:	e052                	sd	s4,0(sp)
ffffffffc02038cc:	f406                	sd	ra,40(sp)
ffffffffc02038ce:	f022                	sd	s0,32(sp)
ffffffffc02038d0:	e44e                	sd	s3,8(sp)
ffffffffc02038d2:	8a2a                	mv	s4,a0
ffffffffc02038d4:	84ae                	mv	s1,a1
ffffffffc02038d6:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02038d8:	100027f3          	csrr	a5,sstatus
ffffffffc02038dc:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02038de:	000b3997          	auipc	s3,0xb3
ffffffffc02038e2:	86298993          	addi	s3,s3,-1950 # ffffffffc02b6140 <pmm_manager>
ffffffffc02038e6:	ef8d                	bnez	a5,ffffffffc0203920 <pgdir_alloc_page+0x5c>
ffffffffc02038e8:	0009b783          	ld	a5,0(s3)
ffffffffc02038ec:	4505                	li	a0,1
ffffffffc02038ee:	6f9c                	ld	a5,24(a5)
ffffffffc02038f0:	9782                	jalr	a5
ffffffffc02038f2:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02038f4:	cc09                	beqz	s0,ffffffffc020390e <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02038f6:	86ca                	mv	a3,s2
ffffffffc02038f8:	8626                	mv	a2,s1
ffffffffc02038fa:	85a2                	mv	a1,s0
ffffffffc02038fc:	8552                	mv	a0,s4
ffffffffc02038fe:	f49fe0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0203902:	e915                	bnez	a0,ffffffffc0203936 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203904:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203906:	e024                	sd	s1,64(s0)
        assert(page_ref(page) == 1);
ffffffffc0203908:	4785                	li	a5,1
ffffffffc020390a:	04f71e63          	bne	a4,a5,ffffffffc0203966 <pgdir_alloc_page+0xa2>
}
ffffffffc020390e:	70a2                	ld	ra,40(sp)
ffffffffc0203910:	8522                	mv	a0,s0
ffffffffc0203912:	7402                	ld	s0,32(sp)
ffffffffc0203914:	64e2                	ld	s1,24(sp)
ffffffffc0203916:	6942                	ld	s2,16(sp)
ffffffffc0203918:	69a2                	ld	s3,8(sp)
ffffffffc020391a:	6a02                	ld	s4,0(sp)
ffffffffc020391c:	6145                	addi	sp,sp,48
ffffffffc020391e:	8082                	ret
        intr_disable();
ffffffffc0203920:	894fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203924:	0009b783          	ld	a5,0(s3)
ffffffffc0203928:	4505                	li	a0,1
ffffffffc020392a:	6f9c                	ld	a5,24(a5)
ffffffffc020392c:	9782                	jalr	a5
ffffffffc020392e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203930:	87efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203934:	b7c1                	j	ffffffffc02038f4 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203936:	100027f3          	csrr	a5,sstatus
ffffffffc020393a:	8b89                	andi	a5,a5,2
ffffffffc020393c:	eb89                	bnez	a5,ffffffffc020394e <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020393e:	0009b783          	ld	a5,0(s3)
ffffffffc0203942:	8522                	mv	a0,s0
ffffffffc0203944:	4585                	li	a1,1
ffffffffc0203946:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203948:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020394a:	9782                	jalr	a5
    if (flag)
ffffffffc020394c:	b7c9                	j	ffffffffc020390e <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020394e:	866fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203952:	0009b783          	ld	a5,0(s3)
ffffffffc0203956:	8522                	mv	a0,s0
ffffffffc0203958:	4585                	li	a1,1
ffffffffc020395a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020395c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020395e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203960:	84efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203964:	b76d                	j	ffffffffc020390e <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203966:	00004697          	auipc	a3,0x4
ffffffffc020396a:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0207560 <default_pmm_manager+0x770>
ffffffffc020396e:	00003617          	auipc	a2,0x3
ffffffffc0203972:	0d260613          	addi	a2,a2,210 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203976:	23500593          	li	a1,565
ffffffffc020397a:	00003517          	auipc	a0,0x3
ffffffffc020397e:	5c650513          	addi	a0,a0,1478 # ffffffffc0206f40 <default_pmm_manager+0x150>
ffffffffc0203982:	b0dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203986 <page_unlock.part.0>:
page_unlock(struct Page *page)
ffffffffc0203986:	1141                	addi	sp,sp,-16
        panic("page_unlock without lock");
ffffffffc0203988:	00004617          	auipc	a2,0x4
ffffffffc020398c:	bf060613          	addi	a2,a2,-1040 # ffffffffc0207578 <default_pmm_manager+0x788>
ffffffffc0203990:	06d00593          	li	a1,109
ffffffffc0203994:	00003517          	auipc	a0,0x3
ffffffffc0203998:	4bc50513          	addi	a0,a0,1212 # ffffffffc0206e50 <default_pmm_manager+0x60>
page_unlock(struct Page *page)
ffffffffc020399c:	e406                	sd	ra,8(sp)
        panic("page_unlock without lock");
ffffffffc020399e:	af1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039a2 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02039a2:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02039a4:	00004697          	auipc	a3,0x4
ffffffffc02039a8:	bf468693          	addi	a3,a3,-1036 # ffffffffc0207598 <default_pmm_manager+0x7a8>
ffffffffc02039ac:	00003617          	auipc	a2,0x3
ffffffffc02039b0:	09460613          	addi	a2,a2,148 # ffffffffc0206a40 <commands+0x868>
ffffffffc02039b4:	10f00593          	li	a1,271
ffffffffc02039b8:	00004517          	auipc	a0,0x4
ffffffffc02039bc:	c0050513          	addi	a0,a0,-1024 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02039c0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02039c2:	acdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039c6 <mm_create>:
{
ffffffffc02039c6:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039c8:	04000513          	li	a0,64
{
ffffffffc02039cc:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039ce:	c6afe0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
    if (mm != NULL)
ffffffffc02039d2:	cd19                	beqz	a0,ffffffffc02039f0 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02039d4:	e508                	sd	a0,8(a0)
ffffffffc02039d6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02039d8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02039dc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02039e0:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02039e4:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02039e8:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02039ec:	02053c23          	sd	zero,56(a0)
}
ffffffffc02039f0:	60a2                	ld	ra,8(sp)
ffffffffc02039f2:	0141                	addi	sp,sp,16
ffffffffc02039f4:	8082                	ret

ffffffffc02039f6 <find_vma>:
{
ffffffffc02039f6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02039f8:	c505                	beqz	a0,ffffffffc0203a20 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02039fa:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02039fc:	c501                	beqz	a0,ffffffffc0203a04 <find_vma+0xe>
ffffffffc02039fe:	651c                	ld	a5,8(a0)
ffffffffc0203a00:	02f5f263          	bgeu	a1,a5,ffffffffc0203a24 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203a04:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0203a06:	00f68d63          	beq	a3,a5,ffffffffc0203a20 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203a0a:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203a0e:	00e5e663          	bltu	a1,a4,ffffffffc0203a1a <find_vma+0x24>
ffffffffc0203a12:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203a16:	00e5ec63          	bltu	a1,a4,ffffffffc0203a2e <find_vma+0x38>
ffffffffc0203a1a:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203a1c:	fef697e3          	bne	a3,a5,ffffffffc0203a0a <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203a20:	4501                	li	a0,0
}
ffffffffc0203a22:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203a24:	691c                	ld	a5,16(a0)
ffffffffc0203a26:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203a04 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203a2a:	ea88                	sd	a0,16(a3)
ffffffffc0203a2c:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203a2e:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203a32:	ea88                	sd	a0,16(a3)
ffffffffc0203a34:	8082                	ret

ffffffffc0203a36 <do_pgfault>:
{
ffffffffc0203a36:	715d                	addi	sp,sp,-80
ffffffffc0203a38:	e0a2                	sd	s0,64(sp)
ffffffffc0203a3a:	842e                	mv	s0,a1
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203a3c:	85b2                	mv	a1,a2
{
ffffffffc0203a3e:	f84a                	sd	s2,48(sp)
ffffffffc0203a40:	f44e                	sd	s3,40(sp)
ffffffffc0203a42:	e486                	sd	ra,72(sp)
ffffffffc0203a44:	fc26                	sd	s1,56(sp)
ffffffffc0203a46:	f052                	sd	s4,32(sp)
ffffffffc0203a48:	ec56                	sd	s5,24(sp)
ffffffffc0203a4a:	e85a                	sd	s6,16(sp)
ffffffffc0203a4c:	e45e                	sd	s7,8(sp)
ffffffffc0203a4e:	e062                	sd	s8,0(sp)
ffffffffc0203a50:	89b2                	mv	s3,a2
ffffffffc0203a52:	892a                	mv	s2,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203a54:	fa3ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
    pgfault_num++;
ffffffffc0203a58:	000b2797          	auipc	a5,0xb2
ffffffffc0203a5c:	6f87a783          	lw	a5,1784(a5) # ffffffffc02b6150 <pgfault_num>
ffffffffc0203a60:	2785                	addiw	a5,a5,1
ffffffffc0203a62:	000b2717          	auipc	a4,0xb2
ffffffffc0203a66:	6ef72723          	sw	a5,1774(a4) # ffffffffc02b6150 <pgfault_num>
    if (vma == NULL || vma->vm_start > addr)
ffffffffc0203a6a:	1a050763          	beqz	a0,ffffffffc0203c18 <do_pgfault+0x1e2>
ffffffffc0203a6e:	651c                	ld	a5,8(a0)
ffffffffc0203a70:	1af9e463          	bltu	s3,a5,ffffffffc0203c18 <do_pgfault+0x1e2>
    if (vma->vm_flags & VM_READ)
ffffffffc0203a74:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0203a76:	4a41                	li	s4,16
    if (vma->vm_flags & VM_READ)
ffffffffc0203a78:	0017f713          	andi	a4,a5,1
ffffffffc0203a7c:	c311                	beqz	a4,ffffffffc0203a80 <do_pgfault+0x4a>
        perm |= PTE_R;
ffffffffc0203a7e:	4a49                	li	s4,18
    if (vma->vm_flags & VM_WRITE)
ffffffffc0203a80:	0027f713          	andi	a4,a5,2
ffffffffc0203a84:	c311                	beqz	a4,ffffffffc0203a88 <do_pgfault+0x52>
        perm |= (PTE_W | PTE_R);
ffffffffc0203a86:	4a59                	li	s4,22
    if (vma->vm_flags & VM_EXEC)
ffffffffc0203a88:	8b91                	andi	a5,a5,4
ffffffffc0203a8a:	ef9d                	bnez	a5,ffffffffc0203ac8 <do_pgfault+0x92>
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203a8c:	77fd                	lui	a5,0xfffff
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc0203a8e:	01893503          	ld	a0,24(s2)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203a92:	00f9f9b3          	and	s3,s3,a5
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc0203a96:	4605                	li	a2,1
ffffffffc0203a98:	85ce                	mv	a1,s3
ffffffffc0203a9a:	e3afe0ef          	jal	ra,ffffffffc02020d4 <get_pte>
ffffffffc0203a9e:	882a                	mv	a6,a0
ffffffffc0203aa0:	cd55                	beqz	a0,ffffffffc0203b5c <do_pgfault+0x126>
    if (*ptep == 0)
ffffffffc0203aa2:	611c                	ld	a5,0(a0)
ffffffffc0203aa4:	88be                	mv	a7,a5
ffffffffc0203aa6:	c7c5                	beqz	a5,ffffffffc0203b4e <do_pgfault+0x118>
    else if (error_code == 1)
ffffffffc0203aa8:	4705                	li	a4,1
ffffffffc0203aaa:	02e40263          	beq	s0,a4,ffffffffc0203ace <do_pgfault+0x98>
        ret = 0;
ffffffffc0203aae:	4501                	li	a0,0
}
ffffffffc0203ab0:	60a6                	ld	ra,72(sp)
ffffffffc0203ab2:	6406                	ld	s0,64(sp)
ffffffffc0203ab4:	74e2                	ld	s1,56(sp)
ffffffffc0203ab6:	7942                	ld	s2,48(sp)
ffffffffc0203ab8:	79a2                	ld	s3,40(sp)
ffffffffc0203aba:	7a02                	ld	s4,32(sp)
ffffffffc0203abc:	6ae2                	ld	s5,24(sp)
ffffffffc0203abe:	6b42                	ld	s6,16(sp)
ffffffffc0203ac0:	6ba2                	ld	s7,8(sp)
ffffffffc0203ac2:	6c02                	ld	s8,0(sp)
ffffffffc0203ac4:	6161                	addi	sp,sp,80
ffffffffc0203ac6:	8082                	ret
        perm |= PTE_X;
ffffffffc0203ac8:	008a6a13          	ori	s4,s4,8
ffffffffc0203acc:	b7c1                	j	ffffffffc0203a8c <do_pgfault+0x56>
    if (PPN(pa) >= npage)
ffffffffc0203ace:	000b2a97          	auipc	s5,0xb2
ffffffffc0203ad2:	662a8a93          	addi	s5,s5,1634 # ffffffffc02b6130 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ad6:	000b2b97          	auipc	s7,0xb2
ffffffffc0203ada:	662b8b93          	addi	s7,s7,1634 # ffffffffc02b6138 <pages>
ffffffffc0203ade:	00004b17          	auipc	s6,0x4
ffffffffc0203ae2:	6d2b0b13          	addi	s6,s6,1746 # ffffffffc02081b0 <nbase>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203ae6:	5579                	li	a0,-2
            if (entry & PTE_W)
ffffffffc0203ae8:	0047f693          	andi	a3,a5,4
ffffffffc0203aec:	f2e9                	bnez	a3,ffffffffc0203aae <do_pgfault+0x78>
            if (!(entry & PTE_COW))
ffffffffc0203aee:	1007f693          	andi	a3,a5,256
ffffffffc0203af2:	c6ad                	beqz	a3,ffffffffc0203b5c <do_pgfault+0x126>
    if (!(pte & PTE_V))
ffffffffc0203af4:	0017f693          	andi	a3,a5,1
ffffffffc0203af8:	12068263          	beqz	a3,ffffffffc0203c1c <do_pgfault+0x1e6>
    if (PPN(pa) >= npage)
ffffffffc0203afc:	000ab683          	ld	a3,0(s5)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203b00:	00279613          	slli	a2,a5,0x2
ffffffffc0203b04:	8231                	srli	a2,a2,0xc
    if (PPN(pa) >= npage)
ffffffffc0203b06:	14d67363          	bgeu	a2,a3,ffffffffc0203c4c <do_pgfault+0x216>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b0a:	000b3683          	ld	a3,0(s6)
ffffffffc0203b0e:	000bb483          	ld	s1,0(s7)
ffffffffc0203b12:	8e15                	sub	a2,a2,a3
ffffffffc0203b14:	00361593          	slli	a1,a2,0x3
ffffffffc0203b18:	962e                	add	a2,a2,a1
ffffffffc0203b1a:	060e                	slli	a2,a2,0x3
ffffffffc0203b1c:	94b2                	add	s1,s1,a2
    while (test_and_set_bit(0, &page->lock))
ffffffffc0203b1e:	01048413          	addi	s0,s1,16
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203b22:	40e4362f          	amoor.d	a2,a4,(s0)
ffffffffc0203b26:	8a05                	andi	a2,a2,1
ffffffffc0203b28:	ca01                	beqz	a2,ffffffffc0203b38 <do_pgfault+0x102>
        __asm__ __volatile__("nop");
ffffffffc0203b2a:	0001                	nop
ffffffffc0203b2c:	40e437af          	amoor.d	a5,a4,(s0)
ffffffffc0203b30:	8b85                	andi	a5,a5,1
    while (test_and_set_bit(0, &page->lock))
ffffffffc0203b32:	ffe5                	bnez	a5,ffffffffc0203b2a <do_pgfault+0xf4>
ffffffffc0203b34:	00083783          	ld	a5,0(a6)
            if (*ptep != entry)
ffffffffc0203b38:	03178463          	beq	a5,a7,ffffffffc0203b60 <do_pgfault+0x12a>
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203b3c:	01048693          	addi	a3,s1,16
ffffffffc0203b40:	60a6b62f          	amoand.d	a2,a0,(a3)
ffffffffc0203b44:	8a05                	andi	a2,a2,1
    if (!test_and_clear_bit(0, &page->lock))
ffffffffc0203b46:	10060f63          	beqz	a2,ffffffffc0203c64 <do_pgfault+0x22e>
            pte_t entry = *ptep;
ffffffffc0203b4a:	88be                	mv	a7,a5
ffffffffc0203b4c:	bf71                	j	ffffffffc0203ae8 <do_pgfault+0xb2>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0203b4e:	01893503          	ld	a0,24(s2)
ffffffffc0203b52:	8652                	mv	a2,s4
ffffffffc0203b54:	85ce                	mv	a1,s3
ffffffffc0203b56:	d6fff0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc0203b5a:	f931                	bnez	a0,ffffffffc0203aae <do_pgfault+0x78>
    ret = -E_NO_MEM;
ffffffffc0203b5c:	5571                	li	a0,-4
ffffffffc0203b5e:	bf89                	j	ffffffffc0203ab0 <do_pgfault+0x7a>
            if (ref == 1)
ffffffffc0203b60:	4094                	lw	a3,0(s1)
ffffffffc0203b62:	4705                	li	a4,1
ffffffffc0203b64:	08e68363          	beq	a3,a4,ffffffffc0203bea <do_pgfault+0x1b4>
            struct Page *npage = alloc_page();
ffffffffc0203b68:	4505                	li	a0,1
ffffffffc0203b6a:	cb2fe0ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0203b6e:	8c2a                	mv	s8,a0
            if (npage == NULL)
ffffffffc0203b70:	cd49                	beqz	a0,ffffffffc0203c0a <do_pgfault+0x1d4>
    return page - pages + nbase;
ffffffffc0203b72:	000bb783          	ld	a5,0(s7)
ffffffffc0203b76:	00004597          	auipc	a1,0x4
ffffffffc0203b7a:	6325b583          	ld	a1,1586(a1) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0203b7e:	000b3803          	ld	a6,0(s6)
ffffffffc0203b82:	40f506b3          	sub	a3,a0,a5
ffffffffc0203b86:	868d                	srai	a3,a3,0x3
ffffffffc0203b88:	02b686b3          	mul	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203b8c:	577d                	li	a4,-1
ffffffffc0203b8e:	000ab603          	ld	a2,0(s5)
ffffffffc0203b92:	8331                	srli	a4,a4,0xc
    return page - pages + nbase;
ffffffffc0203b94:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0203b96:	00e6f533          	and	a0,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203b9a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203b9c:	08c57c63          	bgeu	a0,a2,ffffffffc0203c34 <do_pgfault+0x1fe>
    return page - pages + nbase;
ffffffffc0203ba0:	40f487b3          	sub	a5,s1,a5
ffffffffc0203ba4:	878d                	srai	a5,a5,0x3
ffffffffc0203ba6:	02b787b3          	mul	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0203baa:	000b2597          	auipc	a1,0xb2
ffffffffc0203bae:	59e5b583          	ld	a1,1438(a1) # ffffffffc02b6148 <va_pa_offset>
ffffffffc0203bb2:	00b68533          	add	a0,a3,a1
    return page - pages + nbase;
ffffffffc0203bb6:	97c2                	add	a5,a5,a6
    return KADDR(page2pa(page));
ffffffffc0203bb8:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0203bba:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203bbe:	06c77b63          	bgeu	a4,a2,ffffffffc0203c34 <do_pgfault+0x1fe>
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0203bc2:	95b6                	add	a1,a1,a3
ffffffffc0203bc4:	6605                	lui	a2,0x1
ffffffffc0203bc6:	38c020ef          	jal	ra,ffffffffc0205f52 <memcpy>
            if (page_insert(mm->pgdir, npage, addr, perm) != 0)
ffffffffc0203bca:	01893503          	ld	a0,24(s2)
ffffffffc0203bce:	86d2                	mv	a3,s4
ffffffffc0203bd0:	864e                	mv	a2,s3
ffffffffc0203bd2:	85e2                	mv	a1,s8
ffffffffc0203bd4:	c73fe0ef          	jal	ra,ffffffffc0202846 <page_insert>
ffffffffc0203bd8:	e50d                	bnez	a0,ffffffffc0203c02 <do_pgfault+0x1cc>
ffffffffc0203bda:	57f9                	li	a5,-2
ffffffffc0203bdc:	60f437af          	amoand.d	a5,a5,(s0)
ffffffffc0203be0:	8b85                	andi	a5,a5,1
    if (!test_and_clear_bit(0, &page->lock))
ffffffffc0203be2:	ec0796e3          	bnez	a5,ffffffffc0203aae <do_pgfault+0x78>
ffffffffc0203be6:	da1ff0ef          	jal	ra,ffffffffc0203986 <page_unlock.part.0>
                tlb_invalidate(mm->pgdir, addr);
ffffffffc0203bea:	01893503          	ld	a0,24(s2)
                *ptep = (entry | PTE_W) & ~PTE_COW;
ffffffffc0203bee:	efb7f793          	andi	a5,a5,-261
ffffffffc0203bf2:	0047e793          	ori	a5,a5,4
ffffffffc0203bf6:	00f83023          	sd	a5,0(a6)
                tlb_invalidate(mm->pgdir, addr);
ffffffffc0203bfa:	85ce                	mv	a1,s3
ffffffffc0203bfc:	cc3ff0ef          	jal	ra,ffffffffc02038be <tlb_invalidate>
ffffffffc0203c00:	bfe9                	j	ffffffffc0203bda <do_pgfault+0x1a4>
                free_page(npage);
ffffffffc0203c02:	4585                	li	a1,1
ffffffffc0203c04:	8562                	mv	a0,s8
ffffffffc0203c06:	c54fe0ef          	jal	ra,ffffffffc020205a <free_pages>
ffffffffc0203c0a:	57f9                	li	a5,-2
ffffffffc0203c0c:	60f437af          	amoand.d	a5,a5,(s0)
ffffffffc0203c10:	8b85                	andi	a5,a5,1
ffffffffc0203c12:	dbf1                	beqz	a5,ffffffffc0203be6 <do_pgfault+0x1b0>
    ret = -E_NO_MEM;
ffffffffc0203c14:	5571                	li	a0,-4
ffffffffc0203c16:	bd69                	j	ffffffffc0203ab0 <do_pgfault+0x7a>
    int ret = -E_INVAL;
ffffffffc0203c18:	5575                	li	a0,-3
ffffffffc0203c1a:	bd59                	j	ffffffffc0203ab0 <do_pgfault+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc0203c1c:	00003617          	auipc	a2,0x3
ffffffffc0203c20:	2fc60613          	addi	a2,a2,764 # ffffffffc0206f18 <default_pmm_manager+0x128>
ffffffffc0203c24:	09100593          	li	a1,145
ffffffffc0203c28:	00003517          	auipc	a0,0x3
ffffffffc0203c2c:	22850513          	addi	a0,a0,552 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0203c30:	85ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203c34:	00003617          	auipc	a2,0x3
ffffffffc0203c38:	1f460613          	addi	a2,a2,500 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0203c3c:	08300593          	li	a1,131
ffffffffc0203c40:	00003517          	auipc	a0,0x3
ffffffffc0203c44:	21050513          	addi	a0,a0,528 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0203c48:	847fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203c4c:	00003617          	auipc	a2,0x3
ffffffffc0203c50:	2ac60613          	addi	a2,a2,684 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc0203c54:	07b00593          	li	a1,123
ffffffffc0203c58:	00003517          	auipc	a0,0x3
ffffffffc0203c5c:	1f850513          	addi	a0,a0,504 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0203c60:	82ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("page_unlock without lock");
ffffffffc0203c64:	00004617          	auipc	a2,0x4
ffffffffc0203c68:	91460613          	addi	a2,a2,-1772 # ffffffffc0207578 <default_pmm_manager+0x788>
ffffffffc0203c6c:	06d00593          	li	a1,109
ffffffffc0203c70:	00003517          	auipc	a0,0x3
ffffffffc0203c74:	1e050513          	addi	a0,a0,480 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0203c78:	817fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203c7c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203c7c:	6590                	ld	a2,8(a1)
ffffffffc0203c7e:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203c82:	1141                	addi	sp,sp,-16
ffffffffc0203c84:	e406                	sd	ra,8(sp)
ffffffffc0203c86:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203c88:	01066763          	bltu	a2,a6,ffffffffc0203c96 <insert_vma_struct+0x1a>
ffffffffc0203c8c:	a085                	j	ffffffffc0203cec <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203c8e:	fe87b703          	ld	a4,-24(a5) # ffffffffffffefe8 <end+0x3fd48e74>
ffffffffc0203c92:	04e66863          	bltu	a2,a4,ffffffffc0203ce2 <insert_vma_struct+0x66>
ffffffffc0203c96:	86be                	mv	a3,a5
ffffffffc0203c98:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203c9a:	fef51ae3          	bne	a0,a5,ffffffffc0203c8e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203c9e:	02a68463          	beq	a3,a0,ffffffffc0203cc6 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203ca2:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203ca6:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203caa:	08e8f163          	bgeu	a7,a4,ffffffffc0203d2c <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203cae:	04e66f63          	bltu	a2,a4,ffffffffc0203d0c <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203cb2:	00f50a63          	beq	a0,a5,ffffffffc0203cc6 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203cb6:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203cba:	05076963          	bltu	a4,a6,ffffffffc0203d0c <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203cbe:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203cc2:	02c77363          	bgeu	a4,a2,ffffffffc0203ce8 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203cc6:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203cc8:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203cca:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203cce:	e390                	sd	a2,0(a5)
ffffffffc0203cd0:	e690                	sd	a2,8(a3)
}
ffffffffc0203cd2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203cd4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203cd6:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203cd8:	0017079b          	addiw	a5,a4,1
ffffffffc0203cdc:	d11c                	sw	a5,32(a0)
}
ffffffffc0203cde:	0141                	addi	sp,sp,16
ffffffffc0203ce0:	8082                	ret
    if (le_prev != list)
ffffffffc0203ce2:	fca690e3          	bne	a3,a0,ffffffffc0203ca2 <insert_vma_struct+0x26>
ffffffffc0203ce6:	bfd1                	j	ffffffffc0203cba <insert_vma_struct+0x3e>
ffffffffc0203ce8:	cbbff0ef          	jal	ra,ffffffffc02039a2 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203cec:	00004697          	auipc	a3,0x4
ffffffffc0203cf0:	8dc68693          	addi	a3,a3,-1828 # ffffffffc02075c8 <default_pmm_manager+0x7d8>
ffffffffc0203cf4:	00003617          	auipc	a2,0x3
ffffffffc0203cf8:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203cfc:	11500593          	li	a1,277
ffffffffc0203d00:	00004517          	auipc	a0,0x4
ffffffffc0203d04:	8b850513          	addi	a0,a0,-1864 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203d08:	f86fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203d0c:	00004697          	auipc	a3,0x4
ffffffffc0203d10:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0207608 <default_pmm_manager+0x818>
ffffffffc0203d14:	00003617          	auipc	a2,0x3
ffffffffc0203d18:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203d1c:	10e00593          	li	a1,270
ffffffffc0203d20:	00004517          	auipc	a0,0x4
ffffffffc0203d24:	89850513          	addi	a0,a0,-1896 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203d28:	f66fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203d2c:	00004697          	auipc	a3,0x4
ffffffffc0203d30:	8bc68693          	addi	a3,a3,-1860 # ffffffffc02075e8 <default_pmm_manager+0x7f8>
ffffffffc0203d34:	00003617          	auipc	a2,0x3
ffffffffc0203d38:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203d3c:	10d00593          	li	a1,269
ffffffffc0203d40:	00004517          	auipc	a0,0x4
ffffffffc0203d44:	87850513          	addi	a0,a0,-1928 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203d48:	f46fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d4c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203d4c:	591c                	lw	a5,48(a0)
{
ffffffffc0203d4e:	1141                	addi	sp,sp,-16
ffffffffc0203d50:	e406                	sd	ra,8(sp)
ffffffffc0203d52:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203d54:	e78d                	bnez	a5,ffffffffc0203d7e <mm_destroy+0x32>
ffffffffc0203d56:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203d58:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203d5a:	00a40c63          	beq	s0,a0,ffffffffc0203d72 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203d5e:	6118                	ld	a4,0(a0)
ffffffffc0203d60:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203d62:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203d64:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203d66:	e398                	sd	a4,0(a5)
ffffffffc0203d68:	980fe0ef          	jal	ra,ffffffffc0201ee8 <kfree>
    return listelm->next;
ffffffffc0203d6c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203d6e:	fea418e3          	bne	s0,a0,ffffffffc0203d5e <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203d72:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203d74:	6402                	ld	s0,0(sp)
ffffffffc0203d76:	60a2                	ld	ra,8(sp)
ffffffffc0203d78:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203d7a:	96efe06f          	j	ffffffffc0201ee8 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203d7e:	00004697          	auipc	a3,0x4
ffffffffc0203d82:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0207628 <default_pmm_manager+0x838>
ffffffffc0203d86:	00003617          	auipc	a2,0x3
ffffffffc0203d8a:	cba60613          	addi	a2,a2,-838 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203d8e:	13900593          	li	a1,313
ffffffffc0203d92:	00004517          	auipc	a0,0x4
ffffffffc0203d96:	82650513          	addi	a0,a0,-2010 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203d9a:	ef4fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d9e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203d9e:	7139                	addi	sp,sp,-64
ffffffffc0203da0:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203da2:	6405                	lui	s0,0x1
ffffffffc0203da4:	147d                	addi	s0,s0,-1
ffffffffc0203da6:	77fd                	lui	a5,0xfffff
ffffffffc0203da8:	9622                	add	a2,a2,s0
ffffffffc0203daa:	962e                	add	a2,a2,a1
{
ffffffffc0203dac:	f426                	sd	s1,40(sp)
ffffffffc0203dae:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203db0:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203db4:	f04a                	sd	s2,32(sp)
ffffffffc0203db6:	ec4e                	sd	s3,24(sp)
ffffffffc0203db8:	e852                	sd	s4,16(sp)
ffffffffc0203dba:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203dbc:	002005b7          	lui	a1,0x200
ffffffffc0203dc0:	00f67433          	and	s0,a2,a5
ffffffffc0203dc4:	06b4e363          	bltu	s1,a1,ffffffffc0203e2a <mm_map+0x8c>
ffffffffc0203dc8:	0684f163          	bgeu	s1,s0,ffffffffc0203e2a <mm_map+0x8c>
ffffffffc0203dcc:	4785                	li	a5,1
ffffffffc0203dce:	07fe                	slli	a5,a5,0x1f
ffffffffc0203dd0:	0487ed63          	bltu	a5,s0,ffffffffc0203e2a <mm_map+0x8c>
ffffffffc0203dd4:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203dd6:	cd21                	beqz	a0,ffffffffc0203e2e <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203dd8:	85a6                	mv	a1,s1
ffffffffc0203dda:	8ab6                	mv	s5,a3
ffffffffc0203ddc:	8a3a                	mv	s4,a4
ffffffffc0203dde:	c19ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
ffffffffc0203de2:	c501                	beqz	a0,ffffffffc0203dea <mm_map+0x4c>
ffffffffc0203de4:	651c                	ld	a5,8(a0)
ffffffffc0203de6:	0487e263          	bltu	a5,s0,ffffffffc0203e2a <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203dea:	03000513          	li	a0,48
ffffffffc0203dee:	84afe0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc0203df2:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203df4:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203df6:	02090163          	beqz	s2,ffffffffc0203e18 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203dfa:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203dfc:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203e00:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203e04:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203e08:	85ca                	mv	a1,s2
ffffffffc0203e0a:	e73ff0ef          	jal	ra,ffffffffc0203c7c <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203e0e:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203e10:	000a0463          	beqz	s4,ffffffffc0203e18 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203e14:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203e18:	70e2                	ld	ra,56(sp)
ffffffffc0203e1a:	7442                	ld	s0,48(sp)
ffffffffc0203e1c:	74a2                	ld	s1,40(sp)
ffffffffc0203e1e:	7902                	ld	s2,32(sp)
ffffffffc0203e20:	69e2                	ld	s3,24(sp)
ffffffffc0203e22:	6a42                	ld	s4,16(sp)
ffffffffc0203e24:	6aa2                	ld	s5,8(sp)
ffffffffc0203e26:	6121                	addi	sp,sp,64
ffffffffc0203e28:	8082                	ret
        return -E_INVAL;
ffffffffc0203e2a:	5575                	li	a0,-3
ffffffffc0203e2c:	b7f5                	j	ffffffffc0203e18 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203e2e:	00004697          	auipc	a3,0x4
ffffffffc0203e32:	81268693          	addi	a3,a3,-2030 # ffffffffc0207640 <default_pmm_manager+0x850>
ffffffffc0203e36:	00003617          	auipc	a2,0x3
ffffffffc0203e3a:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203e3e:	14e00593          	li	a1,334
ffffffffc0203e42:	00003517          	auipc	a0,0x3
ffffffffc0203e46:	77650513          	addi	a0,a0,1910 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203e4a:	e44fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203e4e <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203e4e:	7139                	addi	sp,sp,-64
ffffffffc0203e50:	fc06                	sd	ra,56(sp)
ffffffffc0203e52:	f822                	sd	s0,48(sp)
ffffffffc0203e54:	f426                	sd	s1,40(sp)
ffffffffc0203e56:	f04a                	sd	s2,32(sp)
ffffffffc0203e58:	ec4e                	sd	s3,24(sp)
ffffffffc0203e5a:	e852                	sd	s4,16(sp)
ffffffffc0203e5c:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203e5e:	c52d                	beqz	a0,ffffffffc0203ec8 <dup_mmap+0x7a>
ffffffffc0203e60:	892a                	mv	s2,a0
ffffffffc0203e62:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203e64:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203e66:	e595                	bnez	a1,ffffffffc0203e92 <dup_mmap+0x44>
ffffffffc0203e68:	a085                	j	ffffffffc0203ec8 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203e6a:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203e6c:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ed8>
        vma->vm_end = vm_end;
ffffffffc0203e70:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203e74:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203e78:	e05ff0ef          	jal	ra,ffffffffc0203c7c <insert_vma_struct>

        bool share = 1;  // re-enable COW
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203e7c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0203e80:	fe843603          	ld	a2,-24(s0)
ffffffffc0203e84:	6c8c                	ld	a1,24(s1)
ffffffffc0203e86:	01893503          	ld	a0,24(s2)
ffffffffc0203e8a:	4705                	li	a4,1
ffffffffc0203e8c:	f6cff0ef          	jal	ra,ffffffffc02035f8 <copy_range>
ffffffffc0203e90:	e105                	bnez	a0,ffffffffc0203eb0 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203e92:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203e94:	02848863          	beq	s1,s0,ffffffffc0203ec4 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203e98:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203e9c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203ea0:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203ea4:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ea8:	f91fd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc0203eac:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203eae:	fd55                	bnez	a0,ffffffffc0203e6a <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203eb0:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203eb2:	70e2                	ld	ra,56(sp)
ffffffffc0203eb4:	7442                	ld	s0,48(sp)
ffffffffc0203eb6:	74a2                	ld	s1,40(sp)
ffffffffc0203eb8:	7902                	ld	s2,32(sp)
ffffffffc0203eba:	69e2                	ld	s3,24(sp)
ffffffffc0203ebc:	6a42                	ld	s4,16(sp)
ffffffffc0203ebe:	6aa2                	ld	s5,8(sp)
ffffffffc0203ec0:	6121                	addi	sp,sp,64
ffffffffc0203ec2:	8082                	ret
    return 0;
ffffffffc0203ec4:	4501                	li	a0,0
ffffffffc0203ec6:	b7f5                	j	ffffffffc0203eb2 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203ec8:	00003697          	auipc	a3,0x3
ffffffffc0203ecc:	78868693          	addi	a3,a3,1928 # ffffffffc0207650 <default_pmm_manager+0x860>
ffffffffc0203ed0:	00003617          	auipc	a2,0x3
ffffffffc0203ed4:	b7060613          	addi	a2,a2,-1168 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203ed8:	16a00593          	li	a1,362
ffffffffc0203edc:	00003517          	auipc	a0,0x3
ffffffffc0203ee0:	6dc50513          	addi	a0,a0,1756 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203ee4:	daafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ee8 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203ee8:	1101                	addi	sp,sp,-32
ffffffffc0203eea:	ec06                	sd	ra,24(sp)
ffffffffc0203eec:	e822                	sd	s0,16(sp)
ffffffffc0203eee:	e426                	sd	s1,8(sp)
ffffffffc0203ef0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203ef2:	c531                	beqz	a0,ffffffffc0203f3e <exit_mmap+0x56>
ffffffffc0203ef4:	591c                	lw	a5,48(a0)
ffffffffc0203ef6:	84aa                	mv	s1,a0
ffffffffc0203ef8:	e3b9                	bnez	a5,ffffffffc0203f3e <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203efa:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203efc:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203f00:	02850663          	beq	a0,s0,ffffffffc0203f2c <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203f04:	ff043603          	ld	a2,-16(s0)
ffffffffc0203f08:	fe843583          	ld	a1,-24(s0)
ffffffffc0203f0c:	854a                	mv	a0,s2
ffffffffc0203f0e:	c6cfe0ef          	jal	ra,ffffffffc020237a <unmap_range>
ffffffffc0203f12:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203f14:	fe8498e3          	bne	s1,s0,ffffffffc0203f04 <exit_mmap+0x1c>
ffffffffc0203f18:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203f1a:	00848c63          	beq	s1,s0,ffffffffc0203f32 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203f1e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203f22:	fe843583          	ld	a1,-24(s0)
ffffffffc0203f26:	854a                	mv	a0,s2
ffffffffc0203f28:	d9efe0ef          	jal	ra,ffffffffc02024c6 <exit_range>
ffffffffc0203f2c:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203f2e:	fe8498e3          	bne	s1,s0,ffffffffc0203f1e <exit_mmap+0x36>
    }
}
ffffffffc0203f32:	60e2                	ld	ra,24(sp)
ffffffffc0203f34:	6442                	ld	s0,16(sp)
ffffffffc0203f36:	64a2                	ld	s1,8(sp)
ffffffffc0203f38:	6902                	ld	s2,0(sp)
ffffffffc0203f3a:	6105                	addi	sp,sp,32
ffffffffc0203f3c:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203f3e:	00003697          	auipc	a3,0x3
ffffffffc0203f42:	73268693          	addi	a3,a3,1842 # ffffffffc0207670 <default_pmm_manager+0x880>
ffffffffc0203f46:	00003617          	auipc	a2,0x3
ffffffffc0203f4a:	afa60613          	addi	a2,a2,-1286 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203f4e:	18300593          	li	a1,387
ffffffffc0203f52:	00003517          	auipc	a0,0x3
ffffffffc0203f56:	66650513          	addi	a0,a0,1638 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203f5a:	d34fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f5e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203f5e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203f60:	04000513          	li	a0,64
{
ffffffffc0203f64:	fc06                	sd	ra,56(sp)
ffffffffc0203f66:	f822                	sd	s0,48(sp)
ffffffffc0203f68:	f426                	sd	s1,40(sp)
ffffffffc0203f6a:	f04a                	sd	s2,32(sp)
ffffffffc0203f6c:	ec4e                	sd	s3,24(sp)
ffffffffc0203f6e:	e852                	sd	s4,16(sp)
ffffffffc0203f70:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203f72:	ec7fd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
    if (mm != NULL)
ffffffffc0203f76:	52050363          	beqz	a0,ffffffffc020449c <vmm_init+0x53e>
ffffffffc0203f7a:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203f7c:	e508                	sd	a0,8(a0)
ffffffffc0203f7e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203f80:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203f84:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203f88:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203f8c:	02053423          	sd	zero,40(a0)
ffffffffc0203f90:	02052823          	sw	zero,48(a0)
ffffffffc0203f94:	02053c23          	sd	zero,56(a0)
ffffffffc0203f98:	03200413          	li	s0,50
ffffffffc0203f9c:	a811                	j	ffffffffc0203fb0 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203f9e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203fa0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203fa2:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203fa6:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203fa8:	8526                	mv	a0,s1
ffffffffc0203faa:	cd3ff0ef          	jal	ra,ffffffffc0203c7c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203fae:	c80d                	beqz	s0,ffffffffc0203fe0 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203fb0:	03000513          	li	a0,48
ffffffffc0203fb4:	e85fd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc0203fb8:	85aa                	mv	a1,a0
ffffffffc0203fba:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203fbe:	f165                	bnez	a0,ffffffffc0203f9e <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203fc0:	00004697          	auipc	a3,0x4
ffffffffc0203fc4:	8e068693          	addi	a3,a3,-1824 # ffffffffc02078a0 <default_pmm_manager+0xab0>
ffffffffc0203fc8:	00003617          	auipc	a2,0x3
ffffffffc0203fcc:	a7860613          	addi	a2,a2,-1416 # ffffffffc0206a40 <commands+0x868>
ffffffffc0203fd0:	1c700593          	li	a1,455
ffffffffc0203fd4:	00003517          	auipc	a0,0x3
ffffffffc0203fd8:	5e450513          	addi	a0,a0,1508 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0203fdc:	cb2fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203fe0:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203fe4:	1f900913          	li	s2,505
ffffffffc0203fe8:	a819                	j	ffffffffc0203ffe <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203fea:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203fec:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203fee:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ff2:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ff4:	8526                	mv	a0,s1
ffffffffc0203ff6:	c87ff0ef          	jal	ra,ffffffffc0203c7c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ffa:	03240a63          	beq	s0,s2,ffffffffc020402e <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ffe:	03000513          	li	a0,48
ffffffffc0204002:	e37fd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc0204006:	85aa                	mv	a1,a0
ffffffffc0204008:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020400c:	fd79                	bnez	a0,ffffffffc0203fea <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc020400e:	00004697          	auipc	a3,0x4
ffffffffc0204012:	89268693          	addi	a3,a3,-1902 # ffffffffc02078a0 <default_pmm_manager+0xab0>
ffffffffc0204016:	00003617          	auipc	a2,0x3
ffffffffc020401a:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0206a40 <commands+0x868>
ffffffffc020401e:	1ce00593          	li	a1,462
ffffffffc0204022:	00003517          	auipc	a0,0x3
ffffffffc0204026:	59650513          	addi	a0,a0,1430 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc020402a:	c64fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc020402e:	649c                	ld	a5,8(s1)
ffffffffc0204030:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0204032:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0204036:	2cf48b63          	beq	s1,a5,ffffffffc020430c <vmm_init+0x3ae>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020403a:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd48e74>
ffffffffc020403e:	ffe70693          	addi	a3,a4,-2
ffffffffc0204042:	22d61563          	bne	a2,a3,ffffffffc020426c <vmm_init+0x30e>
ffffffffc0204046:	ff07b683          	ld	a3,-16(a5)
ffffffffc020404a:	22e69163          	bne	a3,a4,ffffffffc020426c <vmm_init+0x30e>
    for (i = 1; i <= step2; i++)
ffffffffc020404e:	0715                	addi	a4,a4,5
ffffffffc0204050:	679c                	ld	a5,8(a5)
ffffffffc0204052:	feb712e3          	bne	a4,a1,ffffffffc0204036 <vmm_init+0xd8>
ffffffffc0204056:	4a1d                	li	s4,7
ffffffffc0204058:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020405a:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc020405e:	85a2                	mv	a1,s0
ffffffffc0204060:	8526                	mv	a0,s1
ffffffffc0204062:	995ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
ffffffffc0204066:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0204068:	2c050263          	beqz	a0,ffffffffc020432c <vmm_init+0x3ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc020406c:	00140593          	addi	a1,s0,1
ffffffffc0204070:	8526                	mv	a0,s1
ffffffffc0204072:	985ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
ffffffffc0204076:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0204078:	32050a63          	beqz	a0,ffffffffc02043ac <vmm_init+0x44e>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc020407c:	85d2                	mv	a1,s4
ffffffffc020407e:	8526                	mv	a0,s1
ffffffffc0204080:	977ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
        assert(vma3 == NULL);
ffffffffc0204084:	2e051463          	bnez	a0,ffffffffc020436c <vmm_init+0x40e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0204088:	00340593          	addi	a1,s0,3
ffffffffc020408c:	8526                	mv	a0,s1
ffffffffc020408e:	969ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
        assert(vma4 == NULL);
ffffffffc0204092:	2a051d63          	bnez	a0,ffffffffc020434c <vmm_init+0x3ee>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0204096:	00440593          	addi	a1,s0,4
ffffffffc020409a:	8526                	mv	a0,s1
ffffffffc020409c:	95bff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
        assert(vma5 == NULL);
ffffffffc02040a0:	2e051663          	bnez	a0,ffffffffc020438c <vmm_init+0x42e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02040a4:	00893783          	ld	a5,8(s2)
ffffffffc02040a8:	1e879263          	bne	a5,s0,ffffffffc020428c <vmm_init+0x32e>
ffffffffc02040ac:	01093783          	ld	a5,16(s2)
ffffffffc02040b0:	1cfa1e63          	bne	s4,a5,ffffffffc020428c <vmm_init+0x32e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02040b4:	0089b783          	ld	a5,8(s3)
ffffffffc02040b8:	1e879a63          	bne	a5,s0,ffffffffc02042ac <vmm_init+0x34e>
ffffffffc02040bc:	0109b783          	ld	a5,16(s3)
ffffffffc02040c0:	1efa1663          	bne	s4,a5,ffffffffc02042ac <vmm_init+0x34e>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02040c4:	0415                	addi	s0,s0,5
ffffffffc02040c6:	0a15                	addi	s4,s4,5
ffffffffc02040c8:	f9541be3          	bne	s0,s5,ffffffffc020405e <vmm_init+0x100>
ffffffffc02040cc:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc02040ce:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc02040d0:	85a2                	mv	a1,s0
ffffffffc02040d2:	8526                	mv	a0,s1
ffffffffc02040d4:	923ff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
ffffffffc02040d8:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc02040dc:	c90d                	beqz	a0,ffffffffc020410e <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02040de:	6914                	ld	a3,16(a0)
ffffffffc02040e0:	6510                	ld	a2,8(a0)
ffffffffc02040e2:	00003517          	auipc	a0,0x3
ffffffffc02040e6:	6ae50513          	addi	a0,a0,1710 # ffffffffc0207790 <default_pmm_manager+0x9a0>
ffffffffc02040ea:	8aafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02040ee:	00003697          	auipc	a3,0x3
ffffffffc02040f2:	6ca68693          	addi	a3,a3,1738 # ffffffffc02077b8 <default_pmm_manager+0x9c8>
ffffffffc02040f6:	00003617          	auipc	a2,0x3
ffffffffc02040fa:	94a60613          	addi	a2,a2,-1718 # ffffffffc0206a40 <commands+0x868>
ffffffffc02040fe:	1f400593          	li	a1,500
ffffffffc0204102:	00003517          	auipc	a0,0x3
ffffffffc0204106:	4b650513          	addi	a0,a0,1206 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc020410a:	b84fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc020410e:	147d                	addi	s0,s0,-1
ffffffffc0204110:	fd2410e3          	bne	s0,s2,ffffffffc02040d0 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0204114:	8526                	mv	a0,s1
ffffffffc0204116:	c37ff0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc020411a:	00003517          	auipc	a0,0x3
ffffffffc020411e:	6b650513          	addi	a0,a0,1718 # ffffffffc02077d0 <default_pmm_manager+0x9e0>
ffffffffc0204122:	872fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204126:	04000513          	li	a0,64
ffffffffc020412a:	d0ffd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc020412e:	84aa                	mv	s1,a0
    if (mm != NULL)
ffffffffc0204130:	1a050e63          	beqz	a0,ffffffffc02042ec <vmm_init+0x38e>
    elm->prev = elm->next = elm;
ffffffffc0204134:	e508                	sd	a0,8(a0)
ffffffffc0204136:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0204138:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020413c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0204140:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0204144:	02053423          	sd	zero,40(a0)
ffffffffc0204148:	02052823          	sw	zero,48(a0)
ffffffffc020414c:	02053c23          	sd	zero,56(a0)
    if ((page = alloc_page()) == NULL)
ffffffffc0204150:	4505                	li	a0,1
ffffffffc0204152:	ecbfd0ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0204156:	26050b63          	beqz	a0,ffffffffc02043cc <vmm_init+0x46e>
    return page - pages + nbase;
ffffffffc020415a:	000b2717          	auipc	a4,0xb2
ffffffffc020415e:	fde73703          	ld	a4,-34(a4) # ffffffffc02b6138 <pages>
ffffffffc0204162:	40e50733          	sub	a4,a0,a4
ffffffffc0204166:	00004797          	auipc	a5,0x4
ffffffffc020416a:	0427b783          	ld	a5,66(a5) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc020416e:	870d                	srai	a4,a4,0x3
ffffffffc0204170:	02f70733          	mul	a4,a4,a5
ffffffffc0204174:	00004697          	auipc	a3,0x4
ffffffffc0204178:	03c6b683          	ld	a3,60(a3) # ffffffffc02081b0 <nbase>
    return KADDR(page2pa(page));
ffffffffc020417c:	00c45793          	srli	a5,s0,0xc
ffffffffc0204180:	000b2617          	auipc	a2,0xb2
ffffffffc0204184:	fb063603          	ld	a2,-80(a2) # ffffffffc02b6130 <npage>
    return page - pages + nbase;
ffffffffc0204188:	9736                	add	a4,a4,a3
    return KADDR(page2pa(page));
ffffffffc020418a:	8ff9                	and	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc020418c:	00c71693          	slli	a3,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0204190:	28c7fa63          	bgeu	a5,a2,ffffffffc0204424 <vmm_init+0x4c6>
ffffffffc0204194:	000b2417          	auipc	s0,0xb2
ffffffffc0204198:	fb443403          	ld	s0,-76(s0) # ffffffffc02b6148 <va_pa_offset>
ffffffffc020419c:	9436                	add	s0,s0,a3
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020419e:	6605                	lui	a2,0x1
ffffffffc02041a0:	000b2597          	auipc	a1,0xb2
ffffffffc02041a4:	f885b583          	ld	a1,-120(a1) # ffffffffc02b6128 <boot_pgdir_va>
ffffffffc02041a8:	8522                	mv	a0,s0
ffffffffc02041aa:	5a9010ef          	jal	ra,ffffffffc0205f52 <memcpy>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02041ae:	03000513          	li	a0,48
    mm->pgdir = pgdir;
ffffffffc02041b2:	ec80                	sd	s0,24(s1)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02041b4:	c85fd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc02041b8:	842a                	mv	s0,a0
    if (vma != NULL)
ffffffffc02041ba:	10050963          	beqz	a0,ffffffffc02042cc <vmm_init+0x36e>
        vma->vm_end = vm_end;
ffffffffc02041be:	002007b7          	lui	a5,0x200
ffffffffc02041c2:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc02041c4:	4789                	li	a5,2
    }

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc02041c6:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02041c8:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc02041cc:	8526                	mv	a0,s1
        vma->vm_flags = vm_flags;
ffffffffc02041ce:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc02041d0:	aadff0ef          	jal	ra,ffffffffc0203c7c <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc02041d4:	10000593          	li	a1,256
ffffffffc02041d8:	8526                	mv	a0,s1
ffffffffc02041da:	81dff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
ffffffffc02041de:	2ca41f63          	bne	s0,a0,ffffffffc02044bc <vmm_init+0x55e>

    int ret = 0;
    ret = do_pgfault(mm, 0, addr);
ffffffffc02041e2:	10000613          	li	a2,256
ffffffffc02041e6:	4581                	li	a1,0
ffffffffc02041e8:	8526                	mv	a0,s1
ffffffffc02041ea:	84dff0ef          	jal	ra,ffffffffc0203a36 <do_pgfault>
    assert(ret == 0);
ffffffffc02041ee:	30051763          	bnez	a0,ffffffffc02044fc <vmm_init+0x59e>

    // check the correctness of page table
    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02041f2:	6c88                	ld	a0,24(s1)
ffffffffc02041f4:	4601                	li	a2,0
ffffffffc02041f6:	10000593          	li	a1,256
ffffffffc02041fa:	edbfd0ef          	jal	ra,ffffffffc02020d4 <get_pte>
    assert(ptep != NULL);
ffffffffc02041fe:	2c050f63          	beqz	a0,ffffffffc02044dc <vmm_init+0x57e>
    assert((*ptep & PTE_U) != 0);
ffffffffc0204202:	611c                	ld	a5,0(a0)
ffffffffc0204204:	0107f713          	andi	a4,a5,16
ffffffffc0204208:	26070a63          	beqz	a4,ffffffffc020447c <vmm_init+0x51e>
    assert((*ptep & PTE_W) != 0);
ffffffffc020420c:	8b91                	andi	a5,a5,4
ffffffffc020420e:	24078763          	beqz	a5,ffffffffc020445c <vmm_init+0x4fe>

    addr = 0x1000;
    ret = do_pgfault(mm, 0, addr);
ffffffffc0204212:	6605                	lui	a2,0x1
ffffffffc0204214:	4581                	li	a1,0
ffffffffc0204216:	8526                	mv	a0,s1
ffffffffc0204218:	81fff0ef          	jal	ra,ffffffffc0203a36 <do_pgfault>
    assert(ret == 0);
ffffffffc020421c:	22051063          	bnez	a0,ffffffffc020443c <vmm_init+0x4de>

    ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0204220:	6c88                	ld	a0,24(s1)
ffffffffc0204222:	4601                	li	a2,0
ffffffffc0204224:	6585                	lui	a1,0x1
ffffffffc0204226:	eaffd0ef          	jal	ra,ffffffffc02020d4 <get_pte>
    assert(ptep != NULL);
ffffffffc020422a:	1a050d63          	beqz	a0,ffffffffc02043e4 <vmm_init+0x486>
    assert((*ptep & PTE_U) != 0);
ffffffffc020422e:	611c                	ld	a5,0(a0)
ffffffffc0204230:	0107f713          	andi	a4,a5,16
ffffffffc0204234:	1c070863          	beqz	a4,ffffffffc0204404 <vmm_init+0x4a6>
    assert((*ptep & PTE_W) != 0);
ffffffffc0204238:	8b91                	andi	a5,a5,4
ffffffffc020423a:	2e078163          	beqz	a5,ffffffffc020451c <vmm_init+0x5be>

    mm_destroy(mm);
ffffffffc020423e:	8526                	mv	a0,s1
ffffffffc0204240:	b0dff0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0204244:	00003517          	auipc	a0,0x3
ffffffffc0204248:	62450513          	addi	a0,a0,1572 # ffffffffc0207868 <default_pmm_manager+0xa78>
ffffffffc020424c:	f49fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0204250:	7442                	ld	s0,48(sp)
ffffffffc0204252:	70e2                	ld	ra,56(sp)
ffffffffc0204254:	74a2                	ld	s1,40(sp)
ffffffffc0204256:	7902                	ld	s2,32(sp)
ffffffffc0204258:	69e2                	ld	s3,24(sp)
ffffffffc020425a:	6a42                	ld	s4,16(sp)
ffffffffc020425c:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020425e:	00003517          	auipc	a0,0x3
ffffffffc0204262:	62a50513          	addi	a0,a0,1578 # ffffffffc0207888 <default_pmm_manager+0xa98>
}
ffffffffc0204266:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204268:	f2dfb06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020426c:	00003697          	auipc	a3,0x3
ffffffffc0204270:	43c68693          	addi	a3,a3,1084 # ffffffffc02076a8 <default_pmm_manager+0x8b8>
ffffffffc0204274:	00002617          	auipc	a2,0x2
ffffffffc0204278:	7cc60613          	addi	a2,a2,1996 # ffffffffc0206a40 <commands+0x868>
ffffffffc020427c:	1d800593          	li	a1,472
ffffffffc0204280:	00003517          	auipc	a0,0x3
ffffffffc0204284:	33850513          	addi	a0,a0,824 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204288:	a06fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020428c:	00003697          	auipc	a3,0x3
ffffffffc0204290:	4a468693          	addi	a3,a3,1188 # ffffffffc0207730 <default_pmm_manager+0x940>
ffffffffc0204294:	00002617          	auipc	a2,0x2
ffffffffc0204298:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206a40 <commands+0x868>
ffffffffc020429c:	1e900593          	li	a1,489
ffffffffc02042a0:	00003517          	auipc	a0,0x3
ffffffffc02042a4:	31850513          	addi	a0,a0,792 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02042a8:	9e6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02042ac:	00003697          	auipc	a3,0x3
ffffffffc02042b0:	4b468693          	addi	a3,a3,1204 # ffffffffc0207760 <default_pmm_manager+0x970>
ffffffffc02042b4:	00002617          	auipc	a2,0x2
ffffffffc02042b8:	78c60613          	addi	a2,a2,1932 # ffffffffc0206a40 <commands+0x868>
ffffffffc02042bc:	1ea00593          	li	a1,490
ffffffffc02042c0:	00003517          	auipc	a0,0x3
ffffffffc02042c4:	2f850513          	addi	a0,a0,760 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02042c8:	9c6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(vma != NULL);
ffffffffc02042cc:	00003697          	auipc	a3,0x3
ffffffffc02042d0:	5d468693          	addi	a3,a3,1492 # ffffffffc02078a0 <default_pmm_manager+0xab0>
ffffffffc02042d4:	00002617          	auipc	a2,0x2
ffffffffc02042d8:	76c60613          	addi	a2,a2,1900 # ffffffffc0206a40 <commands+0x868>
ffffffffc02042dc:	20c00593          	li	a1,524
ffffffffc02042e0:	00003517          	auipc	a0,0x3
ffffffffc02042e4:	2d850513          	addi	a0,a0,728 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02042e8:	9a6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc02042ec:	00003697          	auipc	a3,0x3
ffffffffc02042f0:	35468693          	addi	a3,a3,852 # ffffffffc0207640 <default_pmm_manager+0x850>
ffffffffc02042f4:	00002617          	auipc	a2,0x2
ffffffffc02042f8:	74c60613          	addi	a2,a2,1868 # ffffffffc0206a40 <commands+0x868>
ffffffffc02042fc:	20300593          	li	a1,515
ffffffffc0204300:	00003517          	auipc	a0,0x3
ffffffffc0204304:	2b850513          	addi	a0,a0,696 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204308:	986fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020430c:	00003697          	auipc	a3,0x3
ffffffffc0204310:	38468693          	addi	a3,a3,900 # ffffffffc0207690 <default_pmm_manager+0x8a0>
ffffffffc0204314:	00002617          	auipc	a2,0x2
ffffffffc0204318:	72c60613          	addi	a2,a2,1836 # ffffffffc0206a40 <commands+0x868>
ffffffffc020431c:	1d600593          	li	a1,470
ffffffffc0204320:	00003517          	auipc	a0,0x3
ffffffffc0204324:	29850513          	addi	a0,a0,664 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204328:	966fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc020432c:	00003697          	auipc	a3,0x3
ffffffffc0204330:	3b468693          	addi	a3,a3,948 # ffffffffc02076e0 <default_pmm_manager+0x8f0>
ffffffffc0204334:	00002617          	auipc	a2,0x2
ffffffffc0204338:	70c60613          	addi	a2,a2,1804 # ffffffffc0206a40 <commands+0x868>
ffffffffc020433c:	1df00593          	li	a1,479
ffffffffc0204340:	00003517          	auipc	a0,0x3
ffffffffc0204344:	27850513          	addi	a0,a0,632 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204348:	946fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc020434c:	00003697          	auipc	a3,0x3
ffffffffc0204350:	3c468693          	addi	a3,a3,964 # ffffffffc0207710 <default_pmm_manager+0x920>
ffffffffc0204354:	00002617          	auipc	a2,0x2
ffffffffc0204358:	6ec60613          	addi	a2,a2,1772 # ffffffffc0206a40 <commands+0x868>
ffffffffc020435c:	1e500593          	li	a1,485
ffffffffc0204360:	00003517          	auipc	a0,0x3
ffffffffc0204364:	25850513          	addi	a0,a0,600 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204368:	926fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc020436c:	00003697          	auipc	a3,0x3
ffffffffc0204370:	39468693          	addi	a3,a3,916 # ffffffffc0207700 <default_pmm_manager+0x910>
ffffffffc0204374:	00002617          	auipc	a2,0x2
ffffffffc0204378:	6cc60613          	addi	a2,a2,1740 # ffffffffc0206a40 <commands+0x868>
ffffffffc020437c:	1e300593          	li	a1,483
ffffffffc0204380:	00003517          	auipc	a0,0x3
ffffffffc0204384:	23850513          	addi	a0,a0,568 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204388:	906fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc020438c:	00003697          	auipc	a3,0x3
ffffffffc0204390:	39468693          	addi	a3,a3,916 # ffffffffc0207720 <default_pmm_manager+0x930>
ffffffffc0204394:	00002617          	auipc	a2,0x2
ffffffffc0204398:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206a40 <commands+0x868>
ffffffffc020439c:	1e700593          	li	a1,487
ffffffffc02043a0:	00003517          	auipc	a0,0x3
ffffffffc02043a4:	21850513          	addi	a0,a0,536 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02043a8:	8e6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc02043ac:	00003697          	auipc	a3,0x3
ffffffffc02043b0:	34468693          	addi	a3,a3,836 # ffffffffc02076f0 <default_pmm_manager+0x900>
ffffffffc02043b4:	00002617          	auipc	a2,0x2
ffffffffc02043b8:	68c60613          	addi	a2,a2,1676 # ffffffffc0206a40 <commands+0x868>
ffffffffc02043bc:	1e100593          	li	a1,481
ffffffffc02043c0:	00003517          	auipc	a0,0x3
ffffffffc02043c4:	1f850513          	addi	a0,a0,504 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02043c8:	8c6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("setup_pgdir failed\n");
ffffffffc02043cc:	00003617          	auipc	a2,0x3
ffffffffc02043d0:	42460613          	addi	a2,a2,1060 # ffffffffc02077f0 <default_pmm_manager+0xa00>
ffffffffc02043d4:	20800593          	li	a1,520
ffffffffc02043d8:	00003517          	auipc	a0,0x3
ffffffffc02043dc:	1e050513          	addi	a0,a0,480 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02043e0:	8aefc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ptep != NULL);
ffffffffc02043e4:	00003697          	auipc	a3,0x3
ffffffffc02043e8:	44468693          	addi	a3,a3,1092 # ffffffffc0207828 <default_pmm_manager+0xa38>
ffffffffc02043ec:	00002617          	auipc	a2,0x2
ffffffffc02043f0:	65460613          	addi	a2,a2,1620 # ffffffffc0206a40 <commands+0x868>
ffffffffc02043f4:	22200593          	li	a1,546
ffffffffc02043f8:	00003517          	auipc	a0,0x3
ffffffffc02043fc:	1c050513          	addi	a0,a0,448 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204400:	88efc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) != 0);
ffffffffc0204404:	00003697          	auipc	a3,0x3
ffffffffc0204408:	43468693          	addi	a3,a3,1076 # ffffffffc0207838 <default_pmm_manager+0xa48>
ffffffffc020440c:	00002617          	auipc	a2,0x2
ffffffffc0204410:	63460613          	addi	a2,a2,1588 # ffffffffc0206a40 <commands+0x868>
ffffffffc0204414:	22300593          	li	a1,547
ffffffffc0204418:	00003517          	auipc	a0,0x3
ffffffffc020441c:	1a050513          	addi	a0,a0,416 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204420:	86efc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204424:	00003617          	auipc	a2,0x3
ffffffffc0204428:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc020442c:	08300593          	li	a1,131
ffffffffc0204430:	00003517          	auipc	a0,0x3
ffffffffc0204434:	a2050513          	addi	a0,a0,-1504 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204438:	856fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ret == 0);
ffffffffc020443c:	00003697          	auipc	a3,0x3
ffffffffc0204440:	11468693          	addi	a3,a3,276 # ffffffffc0207550 <default_pmm_manager+0x760>
ffffffffc0204444:	00002617          	auipc	a2,0x2
ffffffffc0204448:	5fc60613          	addi	a2,a2,1532 # ffffffffc0206a40 <commands+0x868>
ffffffffc020444c:	21f00593          	li	a1,543
ffffffffc0204450:	00003517          	auipc	a0,0x3
ffffffffc0204454:	16850513          	addi	a0,a0,360 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204458:	836fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_W) != 0);
ffffffffc020445c:	00003697          	auipc	a3,0x3
ffffffffc0204460:	3f468693          	addi	a3,a3,1012 # ffffffffc0207850 <default_pmm_manager+0xa60>
ffffffffc0204464:	00002617          	auipc	a2,0x2
ffffffffc0204468:	5dc60613          	addi	a2,a2,1500 # ffffffffc0206a40 <commands+0x868>
ffffffffc020446c:	21b00593          	li	a1,539
ffffffffc0204470:	00003517          	auipc	a0,0x3
ffffffffc0204474:	14850513          	addi	a0,a0,328 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204478:	816fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) != 0);
ffffffffc020447c:	00003697          	auipc	a3,0x3
ffffffffc0204480:	3bc68693          	addi	a3,a3,956 # ffffffffc0207838 <default_pmm_manager+0xa48>
ffffffffc0204484:	00002617          	auipc	a2,0x2
ffffffffc0204488:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206a40 <commands+0x868>
ffffffffc020448c:	21a00593          	li	a1,538
ffffffffc0204490:	00003517          	auipc	a0,0x3
ffffffffc0204494:	12850513          	addi	a0,a0,296 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204498:	ff7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc020449c:	00003697          	auipc	a3,0x3
ffffffffc02044a0:	1a468693          	addi	a3,a3,420 # ffffffffc0207640 <default_pmm_manager+0x850>
ffffffffc02044a4:	00002617          	auipc	a2,0x2
ffffffffc02044a8:	59c60613          	addi	a2,a2,1436 # ffffffffc0206a40 <commands+0x868>
ffffffffc02044ac:	1bf00593          	li	a1,447
ffffffffc02044b0:	00003517          	auipc	a0,0x3
ffffffffc02044b4:	10850513          	addi	a0,a0,264 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02044b8:	fd7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02044bc:	00003697          	auipc	a3,0x3
ffffffffc02044c0:	34c68693          	addi	a3,a3,844 # ffffffffc0207808 <default_pmm_manager+0xa18>
ffffffffc02044c4:	00002617          	auipc	a2,0x2
ffffffffc02044c8:	57c60613          	addi	a2,a2,1404 # ffffffffc0206a40 <commands+0x868>
ffffffffc02044cc:	21100593          	li	a1,529
ffffffffc02044d0:	00003517          	auipc	a0,0x3
ffffffffc02044d4:	0e850513          	addi	a0,a0,232 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02044d8:	fb7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ptep != NULL);
ffffffffc02044dc:	00003697          	auipc	a3,0x3
ffffffffc02044e0:	34c68693          	addi	a3,a3,844 # ffffffffc0207828 <default_pmm_manager+0xa38>
ffffffffc02044e4:	00002617          	auipc	a2,0x2
ffffffffc02044e8:	55c60613          	addi	a2,a2,1372 # ffffffffc0206a40 <commands+0x868>
ffffffffc02044ec:	21900593          	li	a1,537
ffffffffc02044f0:	00003517          	auipc	a0,0x3
ffffffffc02044f4:	0c850513          	addi	a0,a0,200 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc02044f8:	f97fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(ret == 0);
ffffffffc02044fc:	00003697          	auipc	a3,0x3
ffffffffc0204500:	05468693          	addi	a3,a3,84 # ffffffffc0207550 <default_pmm_manager+0x760>
ffffffffc0204504:	00002617          	auipc	a2,0x2
ffffffffc0204508:	53c60613          	addi	a2,a2,1340 # ffffffffc0206a40 <commands+0x868>
ffffffffc020450c:	21500593          	li	a1,533
ffffffffc0204510:	00003517          	auipc	a0,0x3
ffffffffc0204514:	0a850513          	addi	a0,a0,168 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204518:	f77fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_W) != 0);
ffffffffc020451c:	00003697          	auipc	a3,0x3
ffffffffc0204520:	33468693          	addi	a3,a3,820 # ffffffffc0207850 <default_pmm_manager+0xa60>
ffffffffc0204524:	00002617          	auipc	a2,0x2
ffffffffc0204528:	51c60613          	addi	a2,a2,1308 # ffffffffc0206a40 <commands+0x868>
ffffffffc020452c:	22400593          	li	a1,548
ffffffffc0204530:	00003517          	auipc	a0,0x3
ffffffffc0204534:	08850513          	addi	a0,a0,136 # ffffffffc02075b8 <default_pmm_manager+0x7c8>
ffffffffc0204538:	f57fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020453c <user_mem_check>:
}

bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc020453c:	7179                	addi	sp,sp,-48
ffffffffc020453e:	f022                	sd	s0,32(sp)
ffffffffc0204540:	f406                	sd	ra,40(sp)
ffffffffc0204542:	ec26                	sd	s1,24(sp)
ffffffffc0204544:	e84a                	sd	s2,16(sp)
ffffffffc0204546:	e44e                	sd	s3,8(sp)
ffffffffc0204548:	e052                	sd	s4,0(sp)
ffffffffc020454a:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc020454c:	c135                	beqz	a0,ffffffffc02045b0 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc020454e:	002007b7          	lui	a5,0x200
ffffffffc0204552:	04f5e663          	bltu	a1,a5,ffffffffc020459e <user_mem_check+0x62>
ffffffffc0204556:	00c584b3          	add	s1,a1,a2
ffffffffc020455a:	0495f263          	bgeu	a1,s1,ffffffffc020459e <user_mem_check+0x62>
ffffffffc020455e:	4785                	li	a5,1
ffffffffc0204560:	07fe                	slli	a5,a5,0x1f
ffffffffc0204562:	0297ee63          	bltu	a5,s1,ffffffffc020459e <user_mem_check+0x62>
ffffffffc0204566:	892a                	mv	s2,a0
ffffffffc0204568:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc020456a:	6a05                	lui	s4,0x1
ffffffffc020456c:	a821                	j	ffffffffc0204584 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc020456e:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0204572:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0204574:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204576:	c685                	beqz	a3,ffffffffc020459e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0204578:	c399                	beqz	a5,ffffffffc020457e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc020457a:	02e46263          	bltu	s0,a4,ffffffffc020459e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc020457e:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0204580:	04947663          	bgeu	s0,s1,ffffffffc02045cc <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0204584:	85a2                	mv	a1,s0
ffffffffc0204586:	854a                	mv	a0,s2
ffffffffc0204588:	c6eff0ef          	jal	ra,ffffffffc02039f6 <find_vma>
ffffffffc020458c:	c909                	beqz	a0,ffffffffc020459e <user_mem_check+0x62>
ffffffffc020458e:	6518                	ld	a4,8(a0)
ffffffffc0204590:	00e46763          	bltu	s0,a4,ffffffffc020459e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204594:	4d1c                	lw	a5,24(a0)
ffffffffc0204596:	fc099ce3          	bnez	s3,ffffffffc020456e <user_mem_check+0x32>
ffffffffc020459a:	8b85                	andi	a5,a5,1
ffffffffc020459c:	f3ed                	bnez	a5,ffffffffc020457e <user_mem_check+0x42>
            return 0;
ffffffffc020459e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc02045a0:	70a2                	ld	ra,40(sp)
ffffffffc02045a2:	7402                	ld	s0,32(sp)
ffffffffc02045a4:	64e2                	ld	s1,24(sp)
ffffffffc02045a6:	6942                	ld	s2,16(sp)
ffffffffc02045a8:	69a2                	ld	s3,8(sp)
ffffffffc02045aa:	6a02                	ld	s4,0(sp)
ffffffffc02045ac:	6145                	addi	sp,sp,48
ffffffffc02045ae:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc02045b0:	c02007b7          	lui	a5,0xc0200
ffffffffc02045b4:	4501                	li	a0,0
ffffffffc02045b6:	fef5e5e3          	bltu	a1,a5,ffffffffc02045a0 <user_mem_check+0x64>
ffffffffc02045ba:	962e                	add	a2,a2,a1
ffffffffc02045bc:	fec5f2e3          	bgeu	a1,a2,ffffffffc02045a0 <user_mem_check+0x64>
ffffffffc02045c0:	c8000537          	lui	a0,0xc8000
ffffffffc02045c4:	0505                	addi	a0,a0,1
ffffffffc02045c6:	00a63533          	sltu	a0,a2,a0
ffffffffc02045ca:	bfd9                	j	ffffffffc02045a0 <user_mem_check+0x64>
        return 1;
ffffffffc02045cc:	4505                	li	a0,1
ffffffffc02045ce:	bfc9                	j	ffffffffc02045a0 <user_mem_check+0x64>

ffffffffc02045d0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02045d0:	8526                	mv	a0,s1
	jalr s0
ffffffffc02045d2:	9402                	jalr	s0

	jal do_exit
ffffffffc02045d4:	65c000ef          	jal	ra,ffffffffc0204c30 <do_exit>

ffffffffc02045d8 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02045d8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02045da:	10800513          	li	a0,264
{
ffffffffc02045de:	e022                	sd	s0,0(sp)
ffffffffc02045e0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02045e2:	857fd0ef          	jal	ra,ffffffffc0201e38 <kmalloc>
ffffffffc02045e6:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02045e8:	c12d                	beqz	a0,ffffffffc020464a <alloc_proc+0x72>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc02045ea:	10800613          	li	a2,264
ffffffffc02045ee:	4581                	li	a1,0
ffffffffc02045f0:	151010ef          	jal	ra,ffffffffc0205f40 <memset>
        
        // 初始化所有字段
        proc->state = PROC_UNINIT;      // 进程状态：未初始化
ffffffffc02045f4:	57fd                	li	a5,-1
ffffffffc02045f6:	1782                	slli	a5,a5,0x20
        proc->runs = 0;                 // 运行次数：初始为0
        proc->kstack = 0;               // 内核栈：初始为0
        proc->need_resched = 0;         // 不需要重新调度
        proc->parent = NULL;            // 父进程：空
        proc->mm = NULL;                // 内存管理：空（内核线程）
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文清零
ffffffffc02045f8:	07000613          	li	a2,112
ffffffffc02045fc:	4581                	li	a1,0
        proc->state = PROC_UNINIT;      // 进程状态：未初始化
ffffffffc02045fe:	e01c                	sd	a5,0(s0)
        proc->runs = 0;                 // 运行次数：初始为0
ffffffffc0204600:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;               // 内核栈：初始为0
ffffffffc0204604:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;         // 不需要重新调度
ffffffffc0204608:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;            // 父进程：空
ffffffffc020460c:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;                // 内存管理：空（内核线程）
ffffffffc0204610:	02043423          	sd	zero,40(s0)
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文清零
ffffffffc0204614:	03040513          	addi	a0,s0,48
ffffffffc0204618:	129010ef          	jal	ra,ffffffffc0205f40 <memset>
        proc->tf = NULL;                // 陷阱帧：空
        proc->pgdir = boot_pgdir_pa;    // 页目录：使用内核页表
ffffffffc020461c:	000b2797          	auipc	a5,0xb2
ffffffffc0204620:	b047b783          	ld	a5,-1276(a5) # ffffffffc02b6120 <boot_pgdir_pa>
        proc->tf = NULL;                // 陷阱帧：空
ffffffffc0204624:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;    // 页目录：使用内核页表
ffffffffc0204628:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                // 进程标志：0
ffffffffc020462a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);  // 进程名清零
ffffffffc020462e:	4641                	li	a2,16
ffffffffc0204630:	4581                	li	a1,0
ffffffffc0204632:	0b440513          	addi	a0,s0,180
ffffffffc0204636:	10b010ef          	jal	ra,ffffffffc0205f40 <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
ffffffffc020463a:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc020463e:	10043023          	sd	zero,256(s0)
ffffffffc0204642:	0e043c23          	sd	zero,248(s0)
ffffffffc0204646:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc020464a:	60a2                	ld	ra,8(sp)
ffffffffc020464c:	8522                	mv	a0,s0
ffffffffc020464e:	6402                	ld	s0,0(sp)
ffffffffc0204650:	0141                	addi	sp,sp,16
ffffffffc0204652:	8082                	ret

ffffffffc0204654 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204654:	000b2797          	auipc	a5,0xb2
ffffffffc0204658:	b047b783          	ld	a5,-1276(a5) # ffffffffc02b6158 <current>
ffffffffc020465c:	73c8                	ld	a0,160(a5)
ffffffffc020465e:	a11fc06f          	j	ffffffffc020106e <forkrets>

ffffffffc0204662 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204662:	000b2797          	auipc	a5,0xb2
ffffffffc0204666:	af67b783          	ld	a5,-1290(a5) # ffffffffc02b6158 <current>
ffffffffc020466a:	43cc                	lw	a1,4(a5)
{
ffffffffc020466c:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020466e:	00003617          	auipc	a2,0x3
ffffffffc0204672:	24260613          	addi	a2,a2,578 # ffffffffc02078b0 <default_pmm_manager+0xac0>
ffffffffc0204676:	00003517          	auipc	a0,0x3
ffffffffc020467a:	24250513          	addi	a0,a0,578 # ffffffffc02078b8 <default_pmm_manager+0xac8>
{
ffffffffc020467e:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204680:	b15fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204684:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204688:	28478793          	addi	a5,a5,644 # a908 <_binary_obj___user_cowtest_out_size>
ffffffffc020468c:	e43e                	sd	a5,8(sp)
ffffffffc020468e:	00003517          	auipc	a0,0x3
ffffffffc0204692:	22250513          	addi	a0,a0,546 # ffffffffc02078b0 <default_pmm_manager+0xac0>
ffffffffc0204696:	0001d797          	auipc	a5,0x1d
ffffffffc020469a:	91278793          	addi	a5,a5,-1774 # ffffffffc0220fa8 <_binary_obj___user_cowtest_out_start>
ffffffffc020469e:	f03e                	sd	a5,32(sp)
ffffffffc02046a0:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc02046a2:	e802                	sd	zero,16(sp)
ffffffffc02046a4:	7fa010ef          	jal	ra,ffffffffc0205e9e <strlen>
ffffffffc02046a8:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc02046aa:	4511                	li	a0,4
ffffffffc02046ac:	55a2                	lw	a1,40(sp)
ffffffffc02046ae:	4662                	lw	a2,24(sp)
ffffffffc02046b0:	5682                	lw	a3,32(sp)
ffffffffc02046b2:	4722                	lw	a4,8(sp)
ffffffffc02046b4:	48a9                	li	a7,10
ffffffffc02046b6:	9002                	ebreak
ffffffffc02046b8:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc02046ba:	65c2                	ld	a1,16(sp)
ffffffffc02046bc:	00003517          	auipc	a0,0x3
ffffffffc02046c0:	22450513          	addi	a0,a0,548 # ffffffffc02078e0 <default_pmm_manager+0xaf0>
ffffffffc02046c4:	ad1fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc02046c8:	00003617          	auipc	a2,0x3
ffffffffc02046cc:	22860613          	addi	a2,a2,552 # ffffffffc02078f0 <default_pmm_manager+0xb00>
ffffffffc02046d0:	3ce00593          	li	a1,974
ffffffffc02046d4:	00003517          	auipc	a0,0x3
ffffffffc02046d8:	23c50513          	addi	a0,a0,572 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc02046dc:	db3fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02046e0 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02046e0:	6d14                	ld	a3,24(a0)
{
ffffffffc02046e2:	1141                	addi	sp,sp,-16
ffffffffc02046e4:	e406                	sd	ra,8(sp)
ffffffffc02046e6:	c02007b7          	lui	a5,0xc0200
ffffffffc02046ea:	04f6e163          	bltu	a3,a5,ffffffffc020472c <put_pgdir+0x4c>
ffffffffc02046ee:	000b2797          	auipc	a5,0xb2
ffffffffc02046f2:	a5a7b783          	ld	a5,-1446(a5) # ffffffffc02b6148 <va_pa_offset>
ffffffffc02046f6:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02046f8:	82b1                	srli	a3,a3,0xc
ffffffffc02046fa:	000b2797          	auipc	a5,0xb2
ffffffffc02046fe:	a367b783          	ld	a5,-1482(a5) # ffffffffc02b6130 <npage>
ffffffffc0204702:	04f6f163          	bgeu	a3,a5,ffffffffc0204744 <put_pgdir+0x64>
    return &pages[PPN(pa) - nbase];
ffffffffc0204706:	00004517          	auipc	a0,0x4
ffffffffc020470a:	aaa53503          	ld	a0,-1366(a0) # ffffffffc02081b0 <nbase>
ffffffffc020470e:	8e89                	sub	a3,a3,a0
ffffffffc0204710:	00369513          	slli	a0,a3,0x3
}
ffffffffc0204714:	60a2                	ld	ra,8(sp)
ffffffffc0204716:	96aa                	add	a3,a3,a0
ffffffffc0204718:	068e                	slli	a3,a3,0x3
    free_page(kva2page(mm->pgdir));
ffffffffc020471a:	000b2517          	auipc	a0,0xb2
ffffffffc020471e:	a1e53503          	ld	a0,-1506(a0) # ffffffffc02b6138 <pages>
ffffffffc0204722:	4585                	li	a1,1
ffffffffc0204724:	9536                	add	a0,a0,a3
}
ffffffffc0204726:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204728:	933fd06f          	j	ffffffffc020205a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc020472c:	00002617          	auipc	a2,0x2
ffffffffc0204730:	7a460613          	addi	a2,a2,1956 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0204734:	08900593          	li	a1,137
ffffffffc0204738:	00002517          	auipc	a0,0x2
ffffffffc020473c:	71850513          	addi	a0,a0,1816 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204740:	d4ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204744:	00002617          	auipc	a2,0x2
ffffffffc0204748:	7b460613          	addi	a2,a2,1972 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc020474c:	07b00593          	li	a1,123
ffffffffc0204750:	00002517          	auipc	a0,0x2
ffffffffc0204754:	70050513          	addi	a0,a0,1792 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204758:	d37fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020475c <proc_run>:
{
ffffffffc020475c:	7179                	addi	sp,sp,-48
ffffffffc020475e:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204760:	000b2917          	auipc	s2,0xb2
ffffffffc0204764:	9f890913          	addi	s2,s2,-1544 # ffffffffc02b6158 <current>
{
ffffffffc0204768:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020476a:	00093483          	ld	s1,0(s2)
{
ffffffffc020476e:	f406                	sd	ra,40(sp)
ffffffffc0204770:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0204772:	02a48863          	beq	s1,a0,ffffffffc02047a2 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204776:	100027f3          	csrr	a5,sstatus
ffffffffc020477a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020477c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020477e:	ef9d                	bnez	a5,ffffffffc02047bc <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204780:	755c                	ld	a5,168(a0)
ffffffffc0204782:	577d                	li	a4,-1
ffffffffc0204784:	177e                	slli	a4,a4,0x3f
ffffffffc0204786:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204788:	00a93023          	sd	a0,0(s2)
ffffffffc020478c:	8fd9                	or	a5,a5,a4
ffffffffc020478e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(current->context));
ffffffffc0204792:	03050593          	addi	a1,a0,48
ffffffffc0204796:	03048513          	addi	a0,s1,48
ffffffffc020479a:	0aa010ef          	jal	ra,ffffffffc0205844 <switch_to>
    if (flag)
ffffffffc020479e:	00099863          	bnez	s3,ffffffffc02047ae <proc_run+0x52>
}
ffffffffc02047a2:	70a2                	ld	ra,40(sp)
ffffffffc02047a4:	7482                	ld	s1,32(sp)
ffffffffc02047a6:	6962                	ld	s2,24(sp)
ffffffffc02047a8:	69c2                	ld	s3,16(sp)
ffffffffc02047aa:	6145                	addi	sp,sp,48
ffffffffc02047ac:	8082                	ret
ffffffffc02047ae:	70a2                	ld	ra,40(sp)
ffffffffc02047b0:	7482                	ld	s1,32(sp)
ffffffffc02047b2:	6962                	ld	s2,24(sp)
ffffffffc02047b4:	69c2                	ld	s3,16(sp)
ffffffffc02047b6:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02047b8:	9f6fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc02047bc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02047be:	9f6fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02047c2:	6522                	ld	a0,8(sp)
ffffffffc02047c4:	4985                	li	s3,1
ffffffffc02047c6:	bf6d                	j	ffffffffc0204780 <proc_run+0x24>

ffffffffc02047c8 <do_fork>:
{
ffffffffc02047c8:	7119                	addi	sp,sp,-128
ffffffffc02047ca:	f4a6                	sd	s1,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02047cc:	000b2497          	auipc	s1,0xb2
ffffffffc02047d0:	9a448493          	addi	s1,s1,-1628 # ffffffffc02b6170 <nr_process>
ffffffffc02047d4:	4098                	lw	a4,0(s1)
{
ffffffffc02047d6:	fc86                	sd	ra,120(sp)
ffffffffc02047d8:	f8a2                	sd	s0,112(sp)
ffffffffc02047da:	f0ca                	sd	s2,96(sp)
ffffffffc02047dc:	ecce                	sd	s3,88(sp)
ffffffffc02047de:	e8d2                	sd	s4,80(sp)
ffffffffc02047e0:	e4d6                	sd	s5,72(sp)
ffffffffc02047e2:	e0da                	sd	s6,64(sp)
ffffffffc02047e4:	fc5e                	sd	s7,56(sp)
ffffffffc02047e6:	f862                	sd	s8,48(sp)
ffffffffc02047e8:	f466                	sd	s9,40(sp)
ffffffffc02047ea:	f06a                	sd	s10,32(sp)
ffffffffc02047ec:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02047ee:	6785                	lui	a5,0x1
ffffffffc02047f0:	36f75663          	bge	a4,a5,ffffffffc0204b5c <do_fork+0x394>
ffffffffc02047f4:	89aa                	mv	s3,a0
ffffffffc02047f6:	892e                	mv	s2,a1
ffffffffc02047f8:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02047fa:	ddfff0ef          	jal	ra,ffffffffc02045d8 <alloc_proc>
ffffffffc02047fe:	8b2a                	mv	s6,a0
ffffffffc0204800:	32050f63          	beqz	a0,ffffffffc0204b3e <do_fork+0x376>
    proc->parent = current; 
ffffffffc0204804:	000b2c17          	auipc	s8,0xb2
ffffffffc0204808:	954c0c13          	addi	s8,s8,-1708 # ffffffffc02b6158 <current>
ffffffffc020480c:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204810:	4509                	li	a0,2
    proc->parent = current; 
ffffffffc0204812:	02fb3023          	sd	a5,32(s6)
    current->wait_state = 0;
ffffffffc0204816:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ad4>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020481a:	803fd0ef          	jal	ra,ffffffffc020201c <alloc_pages>
    if (page != NULL)
ffffffffc020481e:	30050d63          	beqz	a0,ffffffffc0204b38 <do_fork+0x370>
    return page - pages + nbase;
ffffffffc0204822:	000b2a17          	auipc	s4,0xb2
ffffffffc0204826:	916a0a13          	addi	s4,s4,-1770 # ffffffffc02b6138 <pages>
ffffffffc020482a:	000a3683          	ld	a3,0(s4)
ffffffffc020482e:	00004717          	auipc	a4,0x4
ffffffffc0204832:	97a73703          	ld	a4,-1670(a4) # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0204836:	00004a97          	auipc	s5,0x4
ffffffffc020483a:	97aa8a93          	addi	s5,s5,-1670 # ffffffffc02081b0 <nbase>
ffffffffc020483e:	40d506b3          	sub	a3,a0,a3
ffffffffc0204842:	868d                	srai	a3,a3,0x3
ffffffffc0204844:	02e686b3          	mul	a3,a3,a4
ffffffffc0204848:	000ab783          	ld	a5,0(s5)
    return KADDR(page2pa(page));
ffffffffc020484c:	000b2b97          	auipc	s7,0xb2
ffffffffc0204850:	8e4b8b93          	addi	s7,s7,-1820 # ffffffffc02b6130 <npage>
ffffffffc0204854:	5dfd                	li	s11,-1
ffffffffc0204856:	000bb603          	ld	a2,0(s7)
ffffffffc020485a:	00cddd93          	srli	s11,s11,0xc
    return page - pages + nbase;
ffffffffc020485e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204860:	01b6f5b3          	and	a1,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204864:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204866:	36c5f163          	bgeu	a1,a2,ffffffffc0204bc8 <do_fork+0x400>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020486a:	000c3583          	ld	a1,0(s8)
ffffffffc020486e:	000b2c17          	auipc	s8,0xb2
ffffffffc0204872:	8dac0c13          	addi	s8,s8,-1830 # ffffffffc02b6148 <va_pa_offset>
ffffffffc0204876:	000c3603          	ld	a2,0(s8)
ffffffffc020487a:	0285bd03          	ld	s10,40(a1) # 1028 <_binary_obj___user_faultread_out_size-0x8b98>
ffffffffc020487e:	e43e                	sd	a5,8(sp)
ffffffffc0204880:	96b2                	add	a3,a3,a2
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204882:	00db3823          	sd	a3,16(s6)
    if (oldmm == NULL)
ffffffffc0204886:	020d0a63          	beqz	s10,ffffffffc02048ba <do_fork+0xf2>
    if (clone_flags & CLONE_VM)
ffffffffc020488a:	1009f993          	andi	s3,s3,256
ffffffffc020488e:	1c098c63          	beqz	s3,ffffffffc0204a66 <do_fork+0x29e>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204892:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204896:	018d3783          	ld	a5,24(s10)
ffffffffc020489a:	c02006b7          	lui	a3,0xc0200
ffffffffc020489e:	2705                	addiw	a4,a4,1
ffffffffc02048a0:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc02048a4:	03ab3423          	sd	s10,40(s6)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02048a8:	2ed7e763          	bltu	a5,a3,ffffffffc0204b96 <do_fork+0x3ce>
ffffffffc02048ac:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02048b0:	010b3683          	ld	a3,16(s6)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02048b4:	8f99                	sub	a5,a5,a4
ffffffffc02048b6:	0afb3423          	sd	a5,168(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02048ba:	6789                	lui	a5,0x2
ffffffffc02048bc:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce0>
ffffffffc02048c0:	96be                	add	a3,a3,a5
ffffffffc02048c2:	0adb3023          	sd	a3,160(s6)
    *(proc->tf) = *tf;
ffffffffc02048c6:	87b6                	mv	a5,a3
ffffffffc02048c8:	12040813          	addi	a6,s0,288
ffffffffc02048cc:	6008                	ld	a0,0(s0)
ffffffffc02048ce:	640c                	ld	a1,8(s0)
ffffffffc02048d0:	6810                	ld	a2,16(s0)
ffffffffc02048d2:	6c18                	ld	a4,24(s0)
ffffffffc02048d4:	e388                	sd	a0,0(a5)
ffffffffc02048d6:	e78c                	sd	a1,8(a5)
ffffffffc02048d8:	eb90                	sd	a2,16(a5)
ffffffffc02048da:	ef98                	sd	a4,24(a5)
ffffffffc02048dc:	02040413          	addi	s0,s0,32
ffffffffc02048e0:	02078793          	addi	a5,a5,32
ffffffffc02048e4:	ff0414e3          	bne	s0,a6,ffffffffc02048cc <do_fork+0x104>
    proc->tf->gpr.a0 = 0;
ffffffffc02048e8:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02048ec:	14090863          	beqz	s2,ffffffffc0204a3c <do_fork+0x274>
ffffffffc02048f0:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02048f4:	00000797          	auipc	a5,0x0
ffffffffc02048f8:	d6078793          	addi	a5,a5,-672 # ffffffffc0204654 <forkret>
ffffffffc02048fc:	02fb3823          	sd	a5,48(s6)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204900:	02db3c23          	sd	a3,56(s6)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204904:	100027f3          	csrr	a5,sstatus
ffffffffc0204908:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020490a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020490c:	14079963          	bnez	a5,ffffffffc0204a5e <do_fork+0x296>
    if (++last_pid >= MAX_PID)
ffffffffc0204910:	000ad817          	auipc	a6,0xad
ffffffffc0204914:	3a880813          	addi	a6,a6,936 # ffffffffc02b1cb8 <last_pid.1>
ffffffffc0204918:	00082783          	lw	a5,0(a6)
ffffffffc020491c:	6709                	lui	a4,0x2
ffffffffc020491e:	0017851b          	addiw	a0,a5,1
ffffffffc0204922:	00a82023          	sw	a0,0(a6)
ffffffffc0204926:	0ae55463          	bge	a0,a4,ffffffffc02049ce <do_fork+0x206>
    if (last_pid >= next_safe)
ffffffffc020492a:	000ad317          	auipc	t1,0xad
ffffffffc020492e:	39230313          	addi	t1,t1,914 # ffffffffc02b1cbc <next_safe.0>
ffffffffc0204932:	00032783          	lw	a5,0(t1)
ffffffffc0204936:	000b1417          	auipc	s0,0xb1
ffffffffc020493a:	7a240413          	addi	s0,s0,1954 # ffffffffc02b60d8 <proc_list>
ffffffffc020493e:	0af55063          	bge	a0,a5,ffffffffc02049de <do_fork+0x216>
    	proc->pid = get_pid(); // 获取一个唯一的 PID
ffffffffc0204942:	00ab2223          	sw	a0,4(s6)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204946:	45a9                	li	a1,10
ffffffffc0204948:	2501                	sext.w	a0,a0
ffffffffc020494a:	150010ef          	jal	ra,ffffffffc0205a9a <hash32>
ffffffffc020494e:	02051793          	slli	a5,a0,0x20
ffffffffc0204952:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204956:	000ad797          	auipc	a5,0xad
ffffffffc020495a:	78278793          	addi	a5,a5,1922 # ffffffffc02b20d8 <hash_list>
ffffffffc020495e:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204960:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204962:	020b3683          	ld	a3,32(s6)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204966:	0d8b0793          	addi	a5,s6,216
    prev->next = next->prev = elm;
ffffffffc020496a:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020496c:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020496e:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204970:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204972:	0c8b0793          	addi	a5,s6,200
    elm->next = next;
ffffffffc0204976:	0ebb3023          	sd	a1,224(s6)
    elm->prev = prev;
ffffffffc020497a:	0cab3c23          	sd	a0,216(s6)
    prev->next = next->prev = elm;
ffffffffc020497e:	e21c                	sd	a5,0(a2)
ffffffffc0204980:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204982:	0ccb3823          	sd	a2,208(s6)
    elm->prev = prev;
ffffffffc0204986:	0c8b3423          	sd	s0,200(s6)
    proc->yptr = NULL;
ffffffffc020498a:	0e0b3c23          	sd	zero,248(s6)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020498e:	10eb3023          	sd	a4,256(s6)
ffffffffc0204992:	c319                	beqz	a4,ffffffffc0204998 <do_fork+0x1d0>
        proc->optr->yptr = proc;
ffffffffc0204994:	0f673c23          	sd	s6,248(a4) # 20f8 <_binary_obj___user_faultread_out_size-0x7ac8>
    nr_process++;
ffffffffc0204998:	409c                	lw	a5,0(s1)
    proc->parent->cptr = proc;
ffffffffc020499a:	0f66b823          	sd	s6,240(a3)
    nr_process++;
ffffffffc020499e:	2785                	addiw	a5,a5,1
ffffffffc02049a0:	c09c                	sw	a5,0(s1)
    if (flag)
ffffffffc02049a2:	1a091063          	bnez	s2,ffffffffc0204b42 <do_fork+0x37a>
    wakeup_proc(proc); // 将 proc->state 设置为 PROC_RUNNABLE
ffffffffc02049a6:	855a                	mv	a0,s6
ffffffffc02049a8:	707000ef          	jal	ra,ffffffffc02058ae <wakeup_proc>
    ret = proc->pid;
ffffffffc02049ac:	004b2503          	lw	a0,4(s6)
}
ffffffffc02049b0:	70e6                	ld	ra,120(sp)
ffffffffc02049b2:	7446                	ld	s0,112(sp)
ffffffffc02049b4:	74a6                	ld	s1,104(sp)
ffffffffc02049b6:	7906                	ld	s2,96(sp)
ffffffffc02049b8:	69e6                	ld	s3,88(sp)
ffffffffc02049ba:	6a46                	ld	s4,80(sp)
ffffffffc02049bc:	6aa6                	ld	s5,72(sp)
ffffffffc02049be:	6b06                	ld	s6,64(sp)
ffffffffc02049c0:	7be2                	ld	s7,56(sp)
ffffffffc02049c2:	7c42                	ld	s8,48(sp)
ffffffffc02049c4:	7ca2                	ld	s9,40(sp)
ffffffffc02049c6:	7d02                	ld	s10,32(sp)
ffffffffc02049c8:	6de2                	ld	s11,24(sp)
ffffffffc02049ca:	6109                	addi	sp,sp,128
ffffffffc02049cc:	8082                	ret
        last_pid = 1;
ffffffffc02049ce:	4785                	li	a5,1
ffffffffc02049d0:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02049d4:	4505                	li	a0,1
ffffffffc02049d6:	000ad317          	auipc	t1,0xad
ffffffffc02049da:	2e630313          	addi	t1,t1,742 # ffffffffc02b1cbc <next_safe.0>
    return listelm->next;
ffffffffc02049de:	000b1417          	auipc	s0,0xb1
ffffffffc02049e2:	6fa40413          	addi	s0,s0,1786 # ffffffffc02b60d8 <proc_list>
ffffffffc02049e6:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02049ea:	6789                	lui	a5,0x2
ffffffffc02049ec:	00f32023          	sw	a5,0(t1)
ffffffffc02049f0:	86aa                	mv	a3,a0
ffffffffc02049f2:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02049f4:	6e89                	lui	t4,0x2
ffffffffc02049f6:	148e0e63          	beq	t3,s0,ffffffffc0204b52 <do_fork+0x38a>
ffffffffc02049fa:	88ae                	mv	a7,a1
ffffffffc02049fc:	87f2                	mv	a5,t3
ffffffffc02049fe:	6609                	lui	a2,0x2
ffffffffc0204a00:	a811                	j	ffffffffc0204a14 <do_fork+0x24c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204a02:	00e6d663          	bge	a3,a4,ffffffffc0204a0e <do_fork+0x246>
ffffffffc0204a06:	00c75463          	bge	a4,a2,ffffffffc0204a0e <do_fork+0x246>
ffffffffc0204a0a:	863a                	mv	a2,a4
ffffffffc0204a0c:	4885                	li	a7,1
ffffffffc0204a0e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204a10:	00878d63          	beq	a5,s0,ffffffffc0204a2a <do_fork+0x262>
            if (proc->pid == last_pid)
ffffffffc0204a14:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c84>
ffffffffc0204a18:	fed715e3          	bne	a4,a3,ffffffffc0204a02 <do_fork+0x23a>
                if (++last_pid >= next_safe)
ffffffffc0204a1c:	2685                	addiw	a3,a3,1
ffffffffc0204a1e:	12c6d563          	bge	a3,a2,ffffffffc0204b48 <do_fork+0x380>
ffffffffc0204a22:	679c                	ld	a5,8(a5)
ffffffffc0204a24:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204a26:	fe8797e3          	bne	a5,s0,ffffffffc0204a14 <do_fork+0x24c>
ffffffffc0204a2a:	c581                	beqz	a1,ffffffffc0204a32 <do_fork+0x26a>
ffffffffc0204a2c:	00d82023          	sw	a3,0(a6)
ffffffffc0204a30:	8536                	mv	a0,a3
ffffffffc0204a32:	f00888e3          	beqz	a7,ffffffffc0204942 <do_fork+0x17a>
ffffffffc0204a36:	00c32023          	sw	a2,0(t1)
ffffffffc0204a3a:	b721                	j	ffffffffc0204942 <do_fork+0x17a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204a3c:	8936                	mv	s2,a3
ffffffffc0204a3e:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204a42:	00000797          	auipc	a5,0x0
ffffffffc0204a46:	c1278793          	addi	a5,a5,-1006 # ffffffffc0204654 <forkret>
ffffffffc0204a4a:	02fb3823          	sd	a5,48(s6)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204a4e:	02db3c23          	sd	a3,56(s6)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204a52:	100027f3          	csrr	a5,sstatus
ffffffffc0204a56:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204a58:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204a5a:	ea078be3          	beqz	a5,ffffffffc0204910 <do_fork+0x148>
        intr_disable();
ffffffffc0204a5e:	f57fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204a62:	4905                	li	s2,1
ffffffffc0204a64:	b575                	j	ffffffffc0204910 <do_fork+0x148>
    if ((mm = mm_create()) == NULL)
ffffffffc0204a66:	f61fe0ef          	jal	ra,ffffffffc02039c6 <mm_create>
ffffffffc0204a6a:	8caa                	mv	s9,a0
ffffffffc0204a6c:	c951                	beqz	a0,ffffffffc0204b00 <do_fork+0x338>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a6e:	4505                	li	a0,1
ffffffffc0204a70:	dacfd0ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0204a74:	c159                	beqz	a0,ffffffffc0204afa <do_fork+0x332>
    return page - pages + nbase;
ffffffffc0204a76:	000a3683          	ld	a3,0(s4)
ffffffffc0204a7a:	00003797          	auipc	a5,0x3
ffffffffc0204a7e:	72e78793          	addi	a5,a5,1838 # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0204a82:	6398                	ld	a4,0(a5)
ffffffffc0204a84:	40d506b3          	sub	a3,a0,a3
ffffffffc0204a88:	868d                	srai	a3,a3,0x3
ffffffffc0204a8a:	02e686b3          	mul	a3,a3,a4
ffffffffc0204a8e:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204a90:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc0204a94:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a96:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a9a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a9c:	12cdf663          	bgeu	s11,a2,ffffffffc0204bc8 <do_fork+0x400>
ffffffffc0204aa0:	000c3983          	ld	s3,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204aa4:	6605                	lui	a2,0x1
ffffffffc0204aa6:	000b1597          	auipc	a1,0xb1
ffffffffc0204aaa:	6825b583          	ld	a1,1666(a1) # ffffffffc02b6128 <boot_pgdir_va>
ffffffffc0204aae:	99b6                	add	s3,s3,a3
ffffffffc0204ab0:	854e                	mv	a0,s3
ffffffffc0204ab2:	4a0010ef          	jal	ra,ffffffffc0205f52 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204ab6:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204aba:	013cbc23          	sd	s3,24(s9)
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204abe:	4785                	li	a5,1
ffffffffc0204ac0:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204ac4:	8b85                	andi	a5,a5,1
ffffffffc0204ac6:	4985                	li	s3,1
ffffffffc0204ac8:	c799                	beqz	a5,ffffffffc0204ad6 <do_fork+0x30e>
    {
        schedule();
ffffffffc0204aca:	665000ef          	jal	ra,ffffffffc020592e <schedule>
ffffffffc0204ace:	413db7af          	amoor.d	a5,s3,(s11)
    while (!try_lock(lock))
ffffffffc0204ad2:	8b85                	andi	a5,a5,1
ffffffffc0204ad4:	fbfd                	bnez	a5,ffffffffc0204aca <do_fork+0x302>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204ad6:	85ea                	mv	a1,s10
ffffffffc0204ad8:	8566                	mv	a0,s9
ffffffffc0204ada:	b74ff0ef          	jal	ra,ffffffffc0203e4e <dup_mmap>
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204ade:	57f9                	li	a5,-2
ffffffffc0204ae0:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204ae4:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204ae6:	c3c1                	beqz	a5,ffffffffc0204b66 <do_fork+0x39e>
good_mm:
ffffffffc0204ae8:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204aea:	da0504e3          	beqz	a0,ffffffffc0204892 <do_fork+0xca>
    exit_mmap(mm);
ffffffffc0204aee:	8566                	mv	a0,s9
ffffffffc0204af0:	bf8ff0ef          	jal	ra,ffffffffc0203ee8 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204af4:	8566                	mv	a0,s9
ffffffffc0204af6:	bebff0ef          	jal	ra,ffffffffc02046e0 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204afa:	8566                	mv	a0,s9
ffffffffc0204afc:	a50ff0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204b00:	010b3683          	ld	a3,16(s6)
    return pa2page(PADDR(kva));
ffffffffc0204b04:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b08:	0af6e463          	bltu	a3,a5,ffffffffc0204bb0 <do_fork+0x3e8>
ffffffffc0204b0c:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204b10:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204b14:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204b18:	83b1                	srli	a5,a5,0xc
ffffffffc0204b1a:	06e7f263          	bgeu	a5,a4,ffffffffc0204b7e <do_fork+0x3b6>
    return &pages[PPN(pa) - nbase];
ffffffffc0204b1e:	000ab703          	ld	a4,0(s5)
ffffffffc0204b22:	000a3503          	ld	a0,0(s4)
ffffffffc0204b26:	4589                	li	a1,2
ffffffffc0204b28:	8f99                	sub	a5,a5,a4
ffffffffc0204b2a:	00379713          	slli	a4,a5,0x3
ffffffffc0204b2e:	97ba                	add	a5,a5,a4
ffffffffc0204b30:	078e                	slli	a5,a5,0x3
ffffffffc0204b32:	953e                	add	a0,a0,a5
ffffffffc0204b34:	d26fd0ef          	jal	ra,ffffffffc020205a <free_pages>
    kfree(proc);
ffffffffc0204b38:	855a                	mv	a0,s6
ffffffffc0204b3a:	baefd0ef          	jal	ra,ffffffffc0201ee8 <kfree>
    ret = -E_NO_MEM;
ffffffffc0204b3e:	5571                	li	a0,-4
    return ret;
ffffffffc0204b40:	bd85                	j	ffffffffc02049b0 <do_fork+0x1e8>
        intr_enable();
ffffffffc0204b42:	e6dfb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204b46:	b585                	j	ffffffffc02049a6 <do_fork+0x1de>
                    if (last_pid >= MAX_PID)
ffffffffc0204b48:	01d6c363          	blt	a3,t4,ffffffffc0204b4e <do_fork+0x386>
                        last_pid = 1;
ffffffffc0204b4c:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204b4e:	4585                	li	a1,1
ffffffffc0204b50:	b55d                	j	ffffffffc02049f6 <do_fork+0x22e>
ffffffffc0204b52:	c599                	beqz	a1,ffffffffc0204b60 <do_fork+0x398>
ffffffffc0204b54:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204b58:	8536                	mv	a0,a3
ffffffffc0204b5a:	b3e5                	j	ffffffffc0204942 <do_fork+0x17a>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204b5c:	556d                	li	a0,-5
ffffffffc0204b5e:	bd89                	j	ffffffffc02049b0 <do_fork+0x1e8>
    return last_pid;
ffffffffc0204b60:	00082503          	lw	a0,0(a6)
ffffffffc0204b64:	bbf9                	j	ffffffffc0204942 <do_fork+0x17a>
    {
        panic("Unlock failed.\n");
ffffffffc0204b66:	00003617          	auipc	a2,0x3
ffffffffc0204b6a:	dc260613          	addi	a2,a2,-574 # ffffffffc0207928 <default_pmm_manager+0xb38>
ffffffffc0204b6e:	03f00593          	li	a1,63
ffffffffc0204b72:	00003517          	auipc	a0,0x3
ffffffffc0204b76:	dc650513          	addi	a0,a0,-570 # ffffffffc0207938 <default_pmm_manager+0xb48>
ffffffffc0204b7a:	915fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204b7e:	00002617          	auipc	a2,0x2
ffffffffc0204b82:	37a60613          	addi	a2,a2,890 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc0204b86:	07b00593          	li	a1,123
ffffffffc0204b8a:	00002517          	auipc	a0,0x2
ffffffffc0204b8e:	2c650513          	addi	a0,a0,710 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204b92:	8fdfb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204b96:	86be                	mv	a3,a5
ffffffffc0204b98:	00002617          	auipc	a2,0x2
ffffffffc0204b9c:	33860613          	addi	a2,a2,824 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0204ba0:	19600593          	li	a1,406
ffffffffc0204ba4:	00003517          	auipc	a0,0x3
ffffffffc0204ba8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0204bac:	8e3fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204bb0:	00002617          	auipc	a2,0x2
ffffffffc0204bb4:	32060613          	addi	a2,a2,800 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0204bb8:	08900593          	li	a1,137
ffffffffc0204bbc:	00002517          	auipc	a0,0x2
ffffffffc0204bc0:	29450513          	addi	a0,a0,660 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204bc4:	8cbfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204bc8:	00002617          	auipc	a2,0x2
ffffffffc0204bcc:	26060613          	addi	a2,a2,608 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0204bd0:	08300593          	li	a1,131
ffffffffc0204bd4:	00002517          	auipc	a0,0x2
ffffffffc0204bd8:	27c50513          	addi	a0,a0,636 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204bdc:	8b3fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204be0 <kernel_thread>:
{
ffffffffc0204be0:	7129                	addi	sp,sp,-320
ffffffffc0204be2:	fa22                	sd	s0,304(sp)
ffffffffc0204be4:	f626                	sd	s1,296(sp)
ffffffffc0204be6:	f24a                	sd	s2,288(sp)
ffffffffc0204be8:	84ae                	mv	s1,a1
ffffffffc0204bea:	892a                	mv	s2,a0
ffffffffc0204bec:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204bee:	4581                	li	a1,0
ffffffffc0204bf0:	12000613          	li	a2,288
ffffffffc0204bf4:	850a                	mv	a0,sp
{
ffffffffc0204bf6:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204bf8:	348010ef          	jal	ra,ffffffffc0205f40 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204bfc:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204bfe:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204c00:	100027f3          	csrr	a5,sstatus
ffffffffc0204c04:	edd7f793          	andi	a5,a5,-291
ffffffffc0204c08:	1207e793          	ori	a5,a5,288
ffffffffc0204c0c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204c0e:	860a                	mv	a2,sp
ffffffffc0204c10:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204c14:	00000797          	auipc	a5,0x0
ffffffffc0204c18:	9bc78793          	addi	a5,a5,-1604 # ffffffffc02045d0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204c1c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204c1e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204c20:	ba9ff0ef          	jal	ra,ffffffffc02047c8 <do_fork>
}
ffffffffc0204c24:	70f2                	ld	ra,312(sp)
ffffffffc0204c26:	7452                	ld	s0,304(sp)
ffffffffc0204c28:	74b2                	ld	s1,296(sp)
ffffffffc0204c2a:	7912                	ld	s2,288(sp)
ffffffffc0204c2c:	6131                	addi	sp,sp,320
ffffffffc0204c2e:	8082                	ret

ffffffffc0204c30 <do_exit>:
{
ffffffffc0204c30:	7179                	addi	sp,sp,-48
ffffffffc0204c32:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204c34:	000b1417          	auipc	s0,0xb1
ffffffffc0204c38:	52440413          	addi	s0,s0,1316 # ffffffffc02b6158 <current>
ffffffffc0204c3c:	601c                	ld	a5,0(s0)
{
ffffffffc0204c3e:	f406                	sd	ra,40(sp)
ffffffffc0204c40:	ec26                	sd	s1,24(sp)
ffffffffc0204c42:	e84a                	sd	s2,16(sp)
ffffffffc0204c44:	e44e                	sd	s3,8(sp)
ffffffffc0204c46:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204c48:	000b1717          	auipc	a4,0xb1
ffffffffc0204c4c:	51873703          	ld	a4,1304(a4) # ffffffffc02b6160 <idleproc>
ffffffffc0204c50:	0ce78c63          	beq	a5,a4,ffffffffc0204d28 <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204c54:	000b1497          	auipc	s1,0xb1
ffffffffc0204c58:	51448493          	addi	s1,s1,1300 # ffffffffc02b6168 <initproc>
ffffffffc0204c5c:	6098                	ld	a4,0(s1)
ffffffffc0204c5e:	0ee78b63          	beq	a5,a4,ffffffffc0204d54 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204c62:	0287b983          	ld	s3,40(a5)
ffffffffc0204c66:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204c68:	02098663          	beqz	s3,ffffffffc0204c94 <do_exit+0x64>
ffffffffc0204c6c:	000b1797          	auipc	a5,0xb1
ffffffffc0204c70:	4b47b783          	ld	a5,1204(a5) # ffffffffc02b6120 <boot_pgdir_pa>
ffffffffc0204c74:	577d                	li	a4,-1
ffffffffc0204c76:	177e                	slli	a4,a4,0x3f
ffffffffc0204c78:	83b1                	srli	a5,a5,0xc
ffffffffc0204c7a:	8fd9                	or	a5,a5,a4
ffffffffc0204c7c:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204c80:	0309a783          	lw	a5,48(s3)
ffffffffc0204c84:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204c88:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204c8c:	cb55                	beqz	a4,ffffffffc0204d40 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204c8e:	601c                	ld	a5,0(s0)
ffffffffc0204c90:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204c94:	601c                	ld	a5,0(s0)
ffffffffc0204c96:	470d                	li	a4,3
ffffffffc0204c98:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204c9a:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204c9e:	100027f3          	csrr	a5,sstatus
ffffffffc0204ca2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204ca4:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204ca6:	e3f9                	bnez	a5,ffffffffc0204d6c <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204ca8:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204caa:	800007b7          	lui	a5,0x80000
ffffffffc0204cae:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204cb0:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204cb2:	0ec52703          	lw	a4,236(a0)
ffffffffc0204cb6:	0af70f63          	beq	a4,a5,ffffffffc0204d74 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204cba:	6018                	ld	a4,0(s0)
ffffffffc0204cbc:	7b7c                	ld	a5,240(a4)
ffffffffc0204cbe:	c3a1                	beqz	a5,ffffffffc0204cfe <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204cc0:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204cc4:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204cc6:	0985                	addi	s3,s3,1
ffffffffc0204cc8:	a021                	j	ffffffffc0204cd0 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204cca:	6018                	ld	a4,0(s0)
ffffffffc0204ccc:	7b7c                	ld	a5,240(a4)
ffffffffc0204cce:	cb85                	beqz	a5,ffffffffc0204cfe <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204cd0:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204cd4:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204cd6:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204cd8:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204cda:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204cde:	10e7b023          	sd	a4,256(a5)
ffffffffc0204ce2:	c311                	beqz	a4,ffffffffc0204ce6 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204ce4:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204ce6:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204ce8:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204cea:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204cec:	fd271fe3          	bne	a4,s2,ffffffffc0204cca <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204cf0:	0ec52783          	lw	a5,236(a0)
ffffffffc0204cf4:	fd379be3          	bne	a5,s3,ffffffffc0204cca <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204cf8:	3b7000ef          	jal	ra,ffffffffc02058ae <wakeup_proc>
ffffffffc0204cfc:	b7f9                	j	ffffffffc0204cca <do_exit+0x9a>
    if (flag)
ffffffffc0204cfe:	020a1263          	bnez	s4,ffffffffc0204d22 <do_exit+0xf2>
    schedule();
ffffffffc0204d02:	42d000ef          	jal	ra,ffffffffc020592e <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204d06:	601c                	ld	a5,0(s0)
ffffffffc0204d08:	00003617          	auipc	a2,0x3
ffffffffc0204d0c:	c6860613          	addi	a2,a2,-920 # ffffffffc0207970 <default_pmm_manager+0xb80>
ffffffffc0204d10:	25400593          	li	a1,596
ffffffffc0204d14:	43d4                	lw	a3,4(a5)
ffffffffc0204d16:	00003517          	auipc	a0,0x3
ffffffffc0204d1a:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0204d1e:	f70fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204d22:	c8dfb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204d26:	bff1                	j	ffffffffc0204d02 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204d28:	00003617          	auipc	a2,0x3
ffffffffc0204d2c:	c2860613          	addi	a2,a2,-984 # ffffffffc0207950 <default_pmm_manager+0xb60>
ffffffffc0204d30:	22000593          	li	a1,544
ffffffffc0204d34:	00003517          	auipc	a0,0x3
ffffffffc0204d38:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0204d3c:	f52fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204d40:	854e                	mv	a0,s3
ffffffffc0204d42:	9a6ff0ef          	jal	ra,ffffffffc0203ee8 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d46:	854e                	mv	a0,s3
ffffffffc0204d48:	999ff0ef          	jal	ra,ffffffffc02046e0 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204d4c:	854e                	mv	a0,s3
ffffffffc0204d4e:	ffffe0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>
ffffffffc0204d52:	bf35                	j	ffffffffc0204c8e <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204d54:	00003617          	auipc	a2,0x3
ffffffffc0204d58:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0207960 <default_pmm_manager+0xb70>
ffffffffc0204d5c:	22400593          	li	a1,548
ffffffffc0204d60:	00003517          	auipc	a0,0x3
ffffffffc0204d64:	bb050513          	addi	a0,a0,-1104 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0204d68:	f26fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204d6c:	c49fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204d70:	4a05                	li	s4,1
ffffffffc0204d72:	bf1d                	j	ffffffffc0204ca8 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204d74:	33b000ef          	jal	ra,ffffffffc02058ae <wakeup_proc>
ffffffffc0204d78:	b789                	j	ffffffffc0204cba <do_exit+0x8a>

ffffffffc0204d7a <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204d7a:	715d                	addi	sp,sp,-80
ffffffffc0204d7c:	f84a                	sd	s2,48(sp)
ffffffffc0204d7e:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204d80:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d84:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204d86:	fc26                	sd	s1,56(sp)
ffffffffc0204d88:	f052                	sd	s4,32(sp)
ffffffffc0204d8a:	ec56                	sd	s5,24(sp)
ffffffffc0204d8c:	e85a                	sd	s6,16(sp)
ffffffffc0204d8e:	e45e                	sd	s7,8(sp)
ffffffffc0204d90:	e486                	sd	ra,72(sp)
ffffffffc0204d92:	e0a2                	sd	s0,64(sp)
ffffffffc0204d94:	84aa                	mv	s1,a0
ffffffffc0204d96:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204d98:	000b1b97          	auipc	s7,0xb1
ffffffffc0204d9c:	3c0b8b93          	addi	s7,s7,960 # ffffffffc02b6158 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204da0:	00050b1b          	sext.w	s6,a0
ffffffffc0204da4:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204da8:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204daa:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204dac:	ccbd                	beqz	s1,ffffffffc0204e2a <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204dae:	0359e863          	bltu	s3,s5,ffffffffc0204dde <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204db2:	45a9                	li	a1,10
ffffffffc0204db4:	855a                	mv	a0,s6
ffffffffc0204db6:	4e5000ef          	jal	ra,ffffffffc0205a9a <hash32>
ffffffffc0204dba:	02051793          	slli	a5,a0,0x20
ffffffffc0204dbe:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204dc2:	000ad797          	auipc	a5,0xad
ffffffffc0204dc6:	31678793          	addi	a5,a5,790 # ffffffffc02b20d8 <hash_list>
ffffffffc0204dca:	953e                	add	a0,a0,a5
ffffffffc0204dcc:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204dce:	a029                	j	ffffffffc0204dd8 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204dd0:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204dd4:	02978163          	beq	a5,s1,ffffffffc0204df6 <do_wait.part.0+0x7c>
ffffffffc0204dd8:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204dda:	fe851be3          	bne	a0,s0,ffffffffc0204dd0 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204dde:	5579                	li	a0,-2
}
ffffffffc0204de0:	60a6                	ld	ra,72(sp)
ffffffffc0204de2:	6406                	ld	s0,64(sp)
ffffffffc0204de4:	74e2                	ld	s1,56(sp)
ffffffffc0204de6:	7942                	ld	s2,48(sp)
ffffffffc0204de8:	79a2                	ld	s3,40(sp)
ffffffffc0204dea:	7a02                	ld	s4,32(sp)
ffffffffc0204dec:	6ae2                	ld	s5,24(sp)
ffffffffc0204dee:	6b42                	ld	s6,16(sp)
ffffffffc0204df0:	6ba2                	ld	s7,8(sp)
ffffffffc0204df2:	6161                	addi	sp,sp,80
ffffffffc0204df4:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204df6:	000bb683          	ld	a3,0(s7)
ffffffffc0204dfa:	f4843783          	ld	a5,-184(s0)
ffffffffc0204dfe:	fed790e3          	bne	a5,a3,ffffffffc0204dde <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204e02:	f2842703          	lw	a4,-216(s0)
ffffffffc0204e06:	478d                	li	a5,3
ffffffffc0204e08:	0ef70f63          	beq	a4,a5,ffffffffc0204f06 <do_wait.part.0+0x18c>
        current->state = PROC_SLEEPING;
ffffffffc0204e0c:	4785                	li	a5,1
ffffffffc0204e0e:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204e10:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204e14:	31b000ef          	jal	ra,ffffffffc020592e <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204e18:	000bb783          	ld	a5,0(s7)
ffffffffc0204e1c:	0b07a783          	lw	a5,176(a5)
ffffffffc0204e20:	8b85                	andi	a5,a5,1
ffffffffc0204e22:	d7c9                	beqz	a5,ffffffffc0204dac <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204e24:	555d                	li	a0,-9
ffffffffc0204e26:	e0bff0ef          	jal	ra,ffffffffc0204c30 <do_exit>
        proc = current->cptr;
ffffffffc0204e2a:	000bb683          	ld	a3,0(s7)
ffffffffc0204e2e:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204e30:	d45d                	beqz	s0,ffffffffc0204dde <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204e32:	470d                	li	a4,3
ffffffffc0204e34:	a021                	j	ffffffffc0204e3c <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204e36:	10043403          	ld	s0,256(s0)
ffffffffc0204e3a:	d869                	beqz	s0,ffffffffc0204e0c <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204e3c:	401c                	lw	a5,0(s0)
ffffffffc0204e3e:	fee79ce3          	bne	a5,a4,ffffffffc0204e36 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204e42:	000b1797          	auipc	a5,0xb1
ffffffffc0204e46:	31e7b783          	ld	a5,798(a5) # ffffffffc02b6160 <idleproc>
ffffffffc0204e4a:	0c878d63          	beq	a5,s0,ffffffffc0204f24 <do_wait.part.0+0x1aa>
ffffffffc0204e4e:	000b1797          	auipc	a5,0xb1
ffffffffc0204e52:	31a7b783          	ld	a5,794(a5) # ffffffffc02b6168 <initproc>
ffffffffc0204e56:	0cf40763          	beq	s0,a5,ffffffffc0204f24 <do_wait.part.0+0x1aa>
    if (code_store != NULL)
ffffffffc0204e5a:	000a0663          	beqz	s4,ffffffffc0204e66 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204e5e:	0e842783          	lw	a5,232(s0)
ffffffffc0204e62:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204e66:	100027f3          	csrr	a5,sstatus
ffffffffc0204e6a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204e6c:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204e6e:	ebc1                	bnez	a5,ffffffffc0204efe <do_wait.part.0+0x184>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204e70:	6c70                	ld	a2,216(s0)
ffffffffc0204e72:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204e74:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204e78:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204e7a:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204e7c:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204e7e:	6470                	ld	a2,200(s0)
ffffffffc0204e80:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204e82:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204e84:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204e86:	c319                	beqz	a4,ffffffffc0204e8c <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204e88:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204e8a:	7c7c                	ld	a5,248(s0)
ffffffffc0204e8c:	c7b5                	beqz	a5,ffffffffc0204ef8 <do_wait.part.0+0x17e>
        proc->yptr->optr = proc->optr;
ffffffffc0204e8e:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204e92:	000b1717          	auipc	a4,0xb1
ffffffffc0204e96:	2de70713          	addi	a4,a4,734 # ffffffffc02b6170 <nr_process>
ffffffffc0204e9a:	431c                	lw	a5,0(a4)
ffffffffc0204e9c:	37fd                	addiw	a5,a5,-1
ffffffffc0204e9e:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204ea0:	e9a9                	bnez	a1,ffffffffc0204ef2 <do_wait.part.0+0x178>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204ea2:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204ea4:	c02007b7          	lui	a5,0xc0200
ffffffffc0204ea8:	06f6e263          	bltu	a3,a5,ffffffffc0204f0c <do_wait.part.0+0x192>
ffffffffc0204eac:	000b1797          	auipc	a5,0xb1
ffffffffc0204eb0:	29c7b783          	ld	a5,668(a5) # ffffffffc02b6148 <va_pa_offset>
ffffffffc0204eb4:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204eb8:	83b1                	srli	a5,a5,0xc
ffffffffc0204eba:	000b1717          	auipc	a4,0xb1
ffffffffc0204ebe:	27673703          	ld	a4,630(a4) # ffffffffc02b6130 <npage>
ffffffffc0204ec2:	06e7fd63          	bgeu	a5,a4,ffffffffc0204f3c <do_wait.part.0+0x1c2>
    return &pages[PPN(pa) - nbase];
ffffffffc0204ec6:	00003717          	auipc	a4,0x3
ffffffffc0204eca:	2ea73703          	ld	a4,746(a4) # ffffffffc02081b0 <nbase>
ffffffffc0204ece:	8f99                	sub	a5,a5,a4
ffffffffc0204ed0:	00379513          	slli	a0,a5,0x3
ffffffffc0204ed4:	97aa                	add	a5,a5,a0
ffffffffc0204ed6:	078e                	slli	a5,a5,0x3
ffffffffc0204ed8:	000b1517          	auipc	a0,0xb1
ffffffffc0204edc:	26053503          	ld	a0,608(a0) # ffffffffc02b6138 <pages>
ffffffffc0204ee0:	953e                	add	a0,a0,a5
ffffffffc0204ee2:	4589                	li	a1,2
ffffffffc0204ee4:	976fd0ef          	jal	ra,ffffffffc020205a <free_pages>
    kfree(proc);
ffffffffc0204ee8:	8522                	mv	a0,s0
ffffffffc0204eea:	ffffc0ef          	jal	ra,ffffffffc0201ee8 <kfree>
    return 0;
ffffffffc0204eee:	4501                	li	a0,0
ffffffffc0204ef0:	bdc5                	j	ffffffffc0204de0 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204ef2:	abdfb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204ef6:	b775                	j	ffffffffc0204ea2 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204ef8:	701c                	ld	a5,32(s0)
ffffffffc0204efa:	fbf8                	sd	a4,240(a5)
ffffffffc0204efc:	bf59                	j	ffffffffc0204e92 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204efe:	ab7fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204f02:	4585                	li	a1,1
ffffffffc0204f04:	b7b5                	j	ffffffffc0204e70 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f06:	f2840413          	addi	s0,s0,-216
ffffffffc0204f0a:	bf25                	j	ffffffffc0204e42 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204f0c:	00002617          	auipc	a2,0x2
ffffffffc0204f10:	fc460613          	addi	a2,a2,-60 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0204f14:	08900593          	li	a1,137
ffffffffc0204f18:	00002517          	auipc	a0,0x2
ffffffffc0204f1c:	f3850513          	addi	a0,a0,-200 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204f20:	d6efb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204f24:	00003617          	auipc	a2,0x3
ffffffffc0204f28:	a6c60613          	addi	a2,a2,-1428 # ffffffffc0207990 <default_pmm_manager+0xba0>
ffffffffc0204f2c:	37600593          	li	a1,886
ffffffffc0204f30:	00003517          	auipc	a0,0x3
ffffffffc0204f34:	9e050513          	addi	a0,a0,-1568 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0204f38:	d56fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204f3c:	00002617          	auipc	a2,0x2
ffffffffc0204f40:	fbc60613          	addi	a2,a2,-68 # ffffffffc0206ef8 <default_pmm_manager+0x108>
ffffffffc0204f44:	07b00593          	li	a1,123
ffffffffc0204f48:	00002517          	auipc	a0,0x2
ffffffffc0204f4c:	f0850513          	addi	a0,a0,-248 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc0204f50:	d3efb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204f54 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204f54:	1141                	addi	sp,sp,-16
ffffffffc0204f56:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204f58:	942fd0ef          	jal	ra,ffffffffc020209a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204f5c:	ed9fc0ef          	jal	ra,ffffffffc0201e34 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204f60:	4601                	li	a2,0
ffffffffc0204f62:	4581                	li	a1,0
ffffffffc0204f64:	fffff517          	auipc	a0,0xfffff
ffffffffc0204f68:	6fe50513          	addi	a0,a0,1790 # ffffffffc0204662 <user_main>
ffffffffc0204f6c:	c75ff0ef          	jal	ra,ffffffffc0204be0 <kernel_thread>
    if (pid <= 0)
ffffffffc0204f70:	00a04563          	bgtz	a0,ffffffffc0204f7a <init_main+0x26>
ffffffffc0204f74:	a071                	j	ffffffffc0205000 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204f76:	1b9000ef          	jal	ra,ffffffffc020592e <schedule>
    if (code_store != NULL)
ffffffffc0204f7a:	4581                	li	a1,0
ffffffffc0204f7c:	4501                	li	a0,0
ffffffffc0204f7e:	dfdff0ef          	jal	ra,ffffffffc0204d7a <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204f82:	d975                	beqz	a0,ffffffffc0204f76 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204f84:	00003517          	auipc	a0,0x3
ffffffffc0204f88:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02079d0 <default_pmm_manager+0xbe0>
ffffffffc0204f8c:	a08fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204f90:	000b1797          	auipc	a5,0xb1
ffffffffc0204f94:	1d87b783          	ld	a5,472(a5) # ffffffffc02b6168 <initproc>
ffffffffc0204f98:	7bf8                	ld	a4,240(a5)
ffffffffc0204f9a:	e339                	bnez	a4,ffffffffc0204fe0 <init_main+0x8c>
ffffffffc0204f9c:	7ff8                	ld	a4,248(a5)
ffffffffc0204f9e:	e329                	bnez	a4,ffffffffc0204fe0 <init_main+0x8c>
ffffffffc0204fa0:	1007b703          	ld	a4,256(a5)
ffffffffc0204fa4:	ef15                	bnez	a4,ffffffffc0204fe0 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204fa6:	000b1697          	auipc	a3,0xb1
ffffffffc0204faa:	1ca6a683          	lw	a3,458(a3) # ffffffffc02b6170 <nr_process>
ffffffffc0204fae:	4709                	li	a4,2
ffffffffc0204fb0:	0ae69463          	bne	a3,a4,ffffffffc0205058 <init_main+0x104>
    return listelm->next;
ffffffffc0204fb4:	000b1697          	auipc	a3,0xb1
ffffffffc0204fb8:	12468693          	addi	a3,a3,292 # ffffffffc02b60d8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204fbc:	6698                	ld	a4,8(a3)
ffffffffc0204fbe:	0c878793          	addi	a5,a5,200
ffffffffc0204fc2:	06f71b63          	bne	a4,a5,ffffffffc0205038 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204fc6:	629c                	ld	a5,0(a3)
ffffffffc0204fc8:	04f71863          	bne	a4,a5,ffffffffc0205018 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204fcc:	00003517          	auipc	a0,0x3
ffffffffc0204fd0:	aec50513          	addi	a0,a0,-1300 # ffffffffc0207ab8 <default_pmm_manager+0xcc8>
ffffffffc0204fd4:	9c0fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204fd8:	60a2                	ld	ra,8(sp)
ffffffffc0204fda:	4501                	li	a0,0
ffffffffc0204fdc:	0141                	addi	sp,sp,16
ffffffffc0204fde:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204fe0:	00003697          	auipc	a3,0x3
ffffffffc0204fe4:	a1868693          	addi	a3,a3,-1512 # ffffffffc02079f8 <default_pmm_manager+0xc08>
ffffffffc0204fe8:	00002617          	auipc	a2,0x2
ffffffffc0204fec:	a5860613          	addi	a2,a2,-1448 # ffffffffc0206a40 <commands+0x868>
ffffffffc0204ff0:	3e400593          	li	a1,996
ffffffffc0204ff4:	00003517          	auipc	a0,0x3
ffffffffc0204ff8:	91c50513          	addi	a0,a0,-1764 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0204ffc:	c92fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0205000:	00003617          	auipc	a2,0x3
ffffffffc0205004:	9b060613          	addi	a2,a2,-1616 # ffffffffc02079b0 <default_pmm_manager+0xbc0>
ffffffffc0205008:	3db00593          	li	a1,987
ffffffffc020500c:	00003517          	auipc	a0,0x3
ffffffffc0205010:	90450513          	addi	a0,a0,-1788 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205014:	c7afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205018:	00003697          	auipc	a3,0x3
ffffffffc020501c:	a7068693          	addi	a3,a3,-1424 # ffffffffc0207a88 <default_pmm_manager+0xc98>
ffffffffc0205020:	00002617          	auipc	a2,0x2
ffffffffc0205024:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205028:	3e700593          	li	a1,999
ffffffffc020502c:	00003517          	auipc	a0,0x3
ffffffffc0205030:	8e450513          	addi	a0,a0,-1820 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205034:	c5afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205038:	00003697          	auipc	a3,0x3
ffffffffc020503c:	a2068693          	addi	a3,a3,-1504 # ffffffffc0207a58 <default_pmm_manager+0xc68>
ffffffffc0205040:	00002617          	auipc	a2,0x2
ffffffffc0205044:	a0060613          	addi	a2,a2,-1536 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205048:	3e600593          	li	a1,998
ffffffffc020504c:	00003517          	auipc	a0,0x3
ffffffffc0205050:	8c450513          	addi	a0,a0,-1852 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205054:	c3afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0205058:	00003697          	auipc	a3,0x3
ffffffffc020505c:	9f068693          	addi	a3,a3,-1552 # ffffffffc0207a48 <default_pmm_manager+0xc58>
ffffffffc0205060:	00002617          	auipc	a2,0x2
ffffffffc0205064:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205068:	3e500593          	li	a1,997
ffffffffc020506c:	00003517          	auipc	a0,0x3
ffffffffc0205070:	8a450513          	addi	a0,a0,-1884 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205074:	c1afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205078 <do_execve>:
{
ffffffffc0205078:	7171                	addi	sp,sp,-176
ffffffffc020507a:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020507c:	000b1d97          	auipc	s11,0xb1
ffffffffc0205080:	0dcd8d93          	addi	s11,s11,220 # ffffffffc02b6158 <current>
ffffffffc0205084:	000db783          	ld	a5,0(s11)
{
ffffffffc0205088:	e94a                	sd	s2,144(sp)
ffffffffc020508a:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020508c:	0287b903          	ld	s2,40(a5)
{
ffffffffc0205090:	ed26                	sd	s1,152(sp)
ffffffffc0205092:	f8da                	sd	s6,112(sp)
ffffffffc0205094:	84aa                	mv	s1,a0
ffffffffc0205096:	8b32                	mv	s6,a2
ffffffffc0205098:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020509a:	862e                	mv	a2,a1
ffffffffc020509c:	4681                	li	a3,0
ffffffffc020509e:	85aa                	mv	a1,a0
ffffffffc02050a0:	854a                	mv	a0,s2
{
ffffffffc02050a2:	f506                	sd	ra,168(sp)
ffffffffc02050a4:	e54e                	sd	s3,136(sp)
ffffffffc02050a6:	e152                	sd	s4,128(sp)
ffffffffc02050a8:	fcd6                	sd	s5,120(sp)
ffffffffc02050aa:	f4de                	sd	s7,104(sp)
ffffffffc02050ac:	f0e2                	sd	s8,96(sp)
ffffffffc02050ae:	ece6                	sd	s9,88(sp)
ffffffffc02050b0:	e8ea                	sd	s10,80(sp)
ffffffffc02050b2:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02050b4:	c88ff0ef          	jal	ra,ffffffffc020453c <user_mem_check>
ffffffffc02050b8:	44050863          	beqz	a0,ffffffffc0205508 <do_execve+0x490>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02050bc:	4641                	li	a2,16
ffffffffc02050be:	4581                	li	a1,0
ffffffffc02050c0:	1808                	addi	a0,sp,48
ffffffffc02050c2:	67f000ef          	jal	ra,ffffffffc0205f40 <memset>
    memcpy(local_name, name, len);
ffffffffc02050c6:	47bd                	li	a5,15
ffffffffc02050c8:	8622                	mv	a2,s0
ffffffffc02050ca:	1e87ea63          	bltu	a5,s0,ffffffffc02052be <do_execve+0x246>
ffffffffc02050ce:	85a6                	mv	a1,s1
ffffffffc02050d0:	1808                	addi	a0,sp,48
ffffffffc02050d2:	681000ef          	jal	ra,ffffffffc0205f52 <memcpy>
    if (mm != NULL)
ffffffffc02050d6:	1e090b63          	beqz	s2,ffffffffc02052cc <do_execve+0x254>
        cputs("mm != NULL");
ffffffffc02050da:	00002517          	auipc	a0,0x2
ffffffffc02050de:	56650513          	addi	a0,a0,1382 # ffffffffc0207640 <default_pmm_manager+0x850>
ffffffffc02050e2:	8eafb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc02050e6:	000b1797          	auipc	a5,0xb1
ffffffffc02050ea:	03a7b783          	ld	a5,58(a5) # ffffffffc02b6120 <boot_pgdir_pa>
ffffffffc02050ee:	577d                	li	a4,-1
ffffffffc02050f0:	177e                	slli	a4,a4,0x3f
ffffffffc02050f2:	83b1                	srli	a5,a5,0xc
ffffffffc02050f4:	8fd9                	or	a5,a5,a4
ffffffffc02050f6:	18079073          	csrw	satp,a5
ffffffffc02050fa:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_exit_out_size+0xffffffff7fff4f00>
ffffffffc02050fe:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205102:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0205106:	2e070463          	beqz	a4,ffffffffc02053ee <do_execve+0x376>
        current->mm = NULL;
ffffffffc020510a:	000db783          	ld	a5,0(s11)
ffffffffc020510e:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0205112:	8b5fe0ef          	jal	ra,ffffffffc02039c6 <mm_create>
ffffffffc0205116:	842a                	mv	s0,a0
ffffffffc0205118:	1e050563          	beqz	a0,ffffffffc0205302 <do_execve+0x28a>
    if ((page = alloc_page()) == NULL)
ffffffffc020511c:	4505                	li	a0,1
ffffffffc020511e:	efffc0ef          	jal	ra,ffffffffc020201c <alloc_pages>
ffffffffc0205122:	3e050763          	beqz	a0,ffffffffc0205510 <do_execve+0x498>
    return page - pages + nbase;
ffffffffc0205126:	000b1b97          	auipc	s7,0xb1
ffffffffc020512a:	012b8b93          	addi	s7,s7,18 # ffffffffc02b6138 <pages>
ffffffffc020512e:	000bb683          	ld	a3,0(s7)
ffffffffc0205132:	00003797          	auipc	a5,0x3
ffffffffc0205136:	07678793          	addi	a5,a5,118 # ffffffffc02081a8 <error_string+0xc8>
ffffffffc020513a:	639c                	ld	a5,0(a5)
ffffffffc020513c:	40d506b3          	sub	a3,a0,a3
ffffffffc0205140:	868d                	srai	a3,a3,0x3
ffffffffc0205142:	02f686b3          	mul	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205146:	000b1c17          	auipc	s8,0xb1
ffffffffc020514a:	feac0c13          	addi	s8,s8,-22 # ffffffffc02b6130 <npage>
    return page - pages + nbase;
ffffffffc020514e:	00003717          	auipc	a4,0x3
ffffffffc0205152:	06273703          	ld	a4,98(a4) # ffffffffc02081b0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0205156:	5a7d                	li	s4,-1
ffffffffc0205158:	000c3783          	ld	a5,0(s8)
ffffffffc020515c:	00ca5613          	srli	a2,s4,0xc
    return page - pages + nbase;
ffffffffc0205160:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205162:	ec32                	sd	a2,24(sp)
    return page - pages + nbase;
ffffffffc0205164:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0205166:	00c6f733          	and	a4,a3,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020516a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020516c:	3af77663          	bgeu	a4,a5,ffffffffc0205518 <do_execve+0x4a0>
ffffffffc0205170:	000b1a97          	auipc	s5,0xb1
ffffffffc0205174:	fd8a8a93          	addi	s5,s5,-40 # ffffffffc02b6148 <va_pa_offset>
ffffffffc0205178:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020517c:	6605                	lui	a2,0x1
ffffffffc020517e:	000b1597          	auipc	a1,0xb1
ffffffffc0205182:	faa5b583          	ld	a1,-86(a1) # ffffffffc02b6128 <boot_pgdir_va>
ffffffffc0205186:	94b6                	add	s1,s1,a3
ffffffffc0205188:	8526                	mv	a0,s1
ffffffffc020518a:	5c9000ef          	jal	ra,ffffffffc0205f52 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020518e:	7782                	ld	a5,32(sp)
ffffffffc0205190:	4398                	lw	a4,0(a5)
ffffffffc0205192:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0205196:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0205198:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b944f>
ffffffffc020519c:	14f71963          	bne	a4,a5,ffffffffc02052ee <do_execve+0x276>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02051a0:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc02051a2:	4c81                	li	s9,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02051a4:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02051a8:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02051ac:	00371793          	slli	a5,a4,0x3
ffffffffc02051b0:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02051b2:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02051b4:	078e                	slli	a5,a5,0x3
ffffffffc02051b6:	97ca                	add	a5,a5,s2
ffffffffc02051b8:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02051ba:	00f97c63          	bgeu	s2,a5,ffffffffc02051d2 <do_execve+0x15a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02051be:	00092783          	lw	a5,0(s2)
ffffffffc02051c2:	4705                	li	a4,1
ffffffffc02051c4:	14e78163          	beq	a5,a4,ffffffffc0205306 <do_execve+0x28e>
    for (; ph < ph_end; ph++)
ffffffffc02051c8:	77a2                	ld	a5,40(sp)
ffffffffc02051ca:	03890913          	addi	s2,s2,56
ffffffffc02051ce:	fef968e3          	bltu	s2,a5,ffffffffc02051be <do_execve+0x146>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02051d2:	4701                	li	a4,0
ffffffffc02051d4:	46ad                	li	a3,11
ffffffffc02051d6:	00100637          	lui	a2,0x100
ffffffffc02051da:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02051de:	8522                	mv	a0,s0
ffffffffc02051e0:	bbffe0ef          	jal	ra,ffffffffc0203d9e <mm_map>
ffffffffc02051e4:	89aa                	mv	s3,a0
ffffffffc02051e6:	1e051a63          	bnez	a0,ffffffffc02053da <do_execve+0x362>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02051ea:	6c08                	ld	a0,24(s0)
ffffffffc02051ec:	467d                	li	a2,31
ffffffffc02051ee:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02051f2:	ed2fe0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc02051f6:	3a050963          	beqz	a0,ffffffffc02055a8 <do_execve+0x530>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02051fa:	6c08                	ld	a0,24(s0)
ffffffffc02051fc:	467d                	li	a2,31
ffffffffc02051fe:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205202:	ec2fe0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc0205206:	38050163          	beqz	a0,ffffffffc0205588 <do_execve+0x510>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020520a:	6c08                	ld	a0,24(s0)
ffffffffc020520c:	467d                	li	a2,31
ffffffffc020520e:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205212:	eb2fe0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc0205216:	34050963          	beqz	a0,ffffffffc0205568 <do_execve+0x4f0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020521a:	6c08                	ld	a0,24(s0)
ffffffffc020521c:	467d                	li	a2,31
ffffffffc020521e:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205222:	ea2fe0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc0205226:	32050163          	beqz	a0,ffffffffc0205548 <do_execve+0x4d0>
    mm->mm_count += 1;
ffffffffc020522a:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc020522c:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205230:	6c14                	ld	a3,24(s0)
ffffffffc0205232:	2785                	addiw	a5,a5,1
ffffffffc0205234:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0205236:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205238:	c02007b7          	lui	a5,0xc0200
ffffffffc020523c:	2ef6ea63          	bltu	a3,a5,ffffffffc0205530 <do_execve+0x4b8>
ffffffffc0205240:	000ab783          	ld	a5,0(s5)
ffffffffc0205244:	577d                	li	a4,-1
ffffffffc0205246:	177e                	slli	a4,a4,0x3f
ffffffffc0205248:	8e9d                	sub	a3,a3,a5
ffffffffc020524a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020524e:	f654                	sd	a3,168(a2)
ffffffffc0205250:	8fd9                	or	a5,a5,a4
ffffffffc0205252:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205256:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205258:	4581                	li	a1,0
ffffffffc020525a:	12000613          	li	a2,288
ffffffffc020525e:	8526                	mv	a0,s1
ffffffffc0205260:	4e1000ef          	jal	ra,ffffffffc0205f40 <memset>
    tf->epc = elf->e_entry;               // 设置程序入口点
ffffffffc0205264:	7782                	ld	a5,32(sp)
ffffffffc0205266:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;               // 设置用户栈顶指针
ffffffffc0205268:	4785                	li	a5,1
ffffffffc020526a:	07fe                	slli	a5,a5,0x1f
ffffffffc020526c:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;               // 设置程序入口点
ffffffffc020526e:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc0205272:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205276:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc020527a:	edf7f793          	andi	a5,a5,-289
ffffffffc020527e:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205282:	0b440413          	addi	s0,s0,180
ffffffffc0205286:	4641                	li	a2,16
ffffffffc0205288:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器
ffffffffc020528a:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020528e:	8522                	mv	a0,s0
ffffffffc0205290:	4b1000ef          	jal	ra,ffffffffc0205f40 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205294:	463d                	li	a2,15
ffffffffc0205296:	180c                	addi	a1,sp,48
ffffffffc0205298:	8522                	mv	a0,s0
ffffffffc020529a:	4b9000ef          	jal	ra,ffffffffc0205f52 <memcpy>
}
ffffffffc020529e:	70aa                	ld	ra,168(sp)
ffffffffc02052a0:	740a                	ld	s0,160(sp)
ffffffffc02052a2:	64ea                	ld	s1,152(sp)
ffffffffc02052a4:	694a                	ld	s2,144(sp)
ffffffffc02052a6:	6a0a                	ld	s4,128(sp)
ffffffffc02052a8:	7ae6                	ld	s5,120(sp)
ffffffffc02052aa:	7b46                	ld	s6,112(sp)
ffffffffc02052ac:	7ba6                	ld	s7,104(sp)
ffffffffc02052ae:	7c06                	ld	s8,96(sp)
ffffffffc02052b0:	6ce6                	ld	s9,88(sp)
ffffffffc02052b2:	6d46                	ld	s10,80(sp)
ffffffffc02052b4:	6da6                	ld	s11,72(sp)
ffffffffc02052b6:	854e                	mv	a0,s3
ffffffffc02052b8:	69aa                	ld	s3,136(sp)
ffffffffc02052ba:	614d                	addi	sp,sp,176
ffffffffc02052bc:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02052be:	463d                	li	a2,15
ffffffffc02052c0:	85a6                	mv	a1,s1
ffffffffc02052c2:	1808                	addi	a0,sp,48
ffffffffc02052c4:	48f000ef          	jal	ra,ffffffffc0205f52 <memcpy>
    if (mm != NULL)
ffffffffc02052c8:	e00919e3          	bnez	s2,ffffffffc02050da <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc02052cc:	000db783          	ld	a5,0(s11)
ffffffffc02052d0:	779c                	ld	a5,40(a5)
ffffffffc02052d2:	e40780e3          	beqz	a5,ffffffffc0205112 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02052d6:	00003617          	auipc	a2,0x3
ffffffffc02052da:	80260613          	addi	a2,a2,-2046 # ffffffffc0207ad8 <default_pmm_manager+0xce8>
ffffffffc02052de:	26000593          	li	a1,608
ffffffffc02052e2:	00002517          	auipc	a0,0x2
ffffffffc02052e6:	62e50513          	addi	a0,a0,1582 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc02052ea:	9a4fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc02052ee:	8522                	mv	a0,s0
ffffffffc02052f0:	bf0ff0ef          	jal	ra,ffffffffc02046e0 <put_pgdir>
    mm_destroy(mm);
ffffffffc02052f4:	8522                	mv	a0,s0
ffffffffc02052f6:	a57fe0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02052fa:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc02052fc:	854e                	mv	a0,s3
ffffffffc02052fe:	933ff0ef          	jal	ra,ffffffffc0204c30 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0205302:	59f1                	li	s3,-4
ffffffffc0205304:	bfe5                	j	ffffffffc02052fc <do_execve+0x284>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0205306:	02893603          	ld	a2,40(s2)
ffffffffc020530a:	02093783          	ld	a5,32(s2)
ffffffffc020530e:	20f66363          	bltu	a2,a5,ffffffffc0205514 <do_execve+0x49c>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0205312:	00492783          	lw	a5,4(s2)
ffffffffc0205316:	0017f693          	andi	a3,a5,1
ffffffffc020531a:	c291                	beqz	a3,ffffffffc020531e <do_execve+0x2a6>
            vm_flags |= VM_EXEC;
ffffffffc020531c:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc020531e:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205322:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205324:	0c071f63          	bnez	a4,ffffffffc0205402 <do_execve+0x38a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205328:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc020532a:	c781                	beqz	a5,ffffffffc0205332 <do_execve+0x2ba>
            vm_flags |= VM_READ;
ffffffffc020532c:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0205330:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0205332:	0026f793          	andi	a5,a3,2
ffffffffc0205336:	ebe9                	bnez	a5,ffffffffc0205408 <do_execve+0x390>
        if (vm_flags & VM_EXEC)
ffffffffc0205338:	0046f793          	andi	a5,a3,4
ffffffffc020533c:	c399                	beqz	a5,ffffffffc0205342 <do_execve+0x2ca>
            perm |= PTE_X;
ffffffffc020533e:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0205342:	01093583          	ld	a1,16(s2)
ffffffffc0205346:	4701                	li	a4,0
ffffffffc0205348:	8522                	mv	a0,s0
ffffffffc020534a:	a55fe0ef          	jal	ra,ffffffffc0203d9e <mm_map>
ffffffffc020534e:	89aa                	mv	s3,a0
ffffffffc0205350:	e549                	bnez	a0,ffffffffc02053da <do_execve+0x362>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205352:	01093b03          	ld	s6,16(s2)
ffffffffc0205356:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205358:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc020535c:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205360:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205364:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205366:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205368:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc020536a:	073b6063          	bltu	s6,s3,ffffffffc02053ca <do_execve+0x352>
ffffffffc020536e:	aa79                	j	ffffffffc020550c <do_execve+0x494>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205370:	6785                	lui	a5,0x1
ffffffffc0205372:	414b0533          	sub	a0,s6,s4
ffffffffc0205376:	9a3e                	add	s4,s4,a5
ffffffffc0205378:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc020537c:	0149f463          	bgeu	s3,s4,ffffffffc0205384 <do_execve+0x30c>
                size -= la - end;
ffffffffc0205380:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0205384:	000bb683          	ld	a3,0(s7)
ffffffffc0205388:	00003797          	auipc	a5,0x3
ffffffffc020538c:	e2078793          	addi	a5,a5,-480 # ffffffffc02081a8 <error_string+0xc8>
ffffffffc0205390:	639c                	ld	a5,0(a5)
ffffffffc0205392:	40dc86b3          	sub	a3,s9,a3
ffffffffc0205396:	868d                	srai	a3,a3,0x3
ffffffffc0205398:	02f686b3          	mul	a3,a3,a5
ffffffffc020539c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020539e:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02053a2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02053a4:	67e2                	ld	a5,24(sp)
ffffffffc02053a6:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02053aa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02053ac:	16b8f663          	bgeu	a7,a1,ffffffffc0205518 <do_execve+0x4a0>
ffffffffc02053b0:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02053b4:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc02053b6:	9b32                	add	s6,s6,a2
ffffffffc02053b8:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc02053ba:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc02053bc:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02053be:	395000ef          	jal	ra,ffffffffc0205f52 <memcpy>
            start += size, from += size;
ffffffffc02053c2:	6622                	ld	a2,8(sp)
ffffffffc02053c4:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc02053c6:	053b7363          	bgeu	s6,s3,ffffffffc020540c <do_execve+0x394>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc02053ca:	6c08                	ld	a0,24(s0)
ffffffffc02053cc:	866a                	mv	a2,s10
ffffffffc02053ce:	85d2                	mv	a1,s4
ffffffffc02053d0:	cf4fe0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc02053d4:	8caa                	mv	s9,a0
ffffffffc02053d6:	fd49                	bnez	a0,ffffffffc0205370 <do_execve+0x2f8>
        ret = -E_NO_MEM;
ffffffffc02053d8:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc02053da:	8522                	mv	a0,s0
ffffffffc02053dc:	b0dfe0ef          	jal	ra,ffffffffc0203ee8 <exit_mmap>
    put_pgdir(mm);
ffffffffc02053e0:	8522                	mv	a0,s0
ffffffffc02053e2:	afeff0ef          	jal	ra,ffffffffc02046e0 <put_pgdir>
    mm_destroy(mm);
ffffffffc02053e6:	8522                	mv	a0,s0
ffffffffc02053e8:	965fe0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>
    return ret;
ffffffffc02053ec:	bf01                	j	ffffffffc02052fc <do_execve+0x284>
            exit_mmap(mm);
ffffffffc02053ee:	854a                	mv	a0,s2
ffffffffc02053f0:	af9fe0ef          	jal	ra,ffffffffc0203ee8 <exit_mmap>
            put_pgdir(mm);
ffffffffc02053f4:	854a                	mv	a0,s2
ffffffffc02053f6:	aeaff0ef          	jal	ra,ffffffffc02046e0 <put_pgdir>
            mm_destroy(mm);
ffffffffc02053fa:	854a                	mv	a0,s2
ffffffffc02053fc:	951fe0ef          	jal	ra,ffffffffc0203d4c <mm_destroy>
ffffffffc0205400:	b329                	j	ffffffffc020510a <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0205402:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205406:	f39d                	bnez	a5,ffffffffc020532c <do_execve+0x2b4>
            perm |= (PTE_W | PTE_R);
ffffffffc0205408:	4d5d                	li	s10,23
ffffffffc020540a:	b73d                	j	ffffffffc0205338 <do_execve+0x2c0>
        end = ph->p_va + ph->p_memsz;
ffffffffc020540c:	01093683          	ld	a3,16(s2)
ffffffffc0205410:	02893483          	ld	s1,40(s2)
ffffffffc0205414:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0205416:	094b7463          	bgeu	s6,s4,ffffffffc020549e <do_execve+0x426>
            if (start == end)
ffffffffc020541a:	db6487e3          	beq	s1,s6,ffffffffc02051c8 <do_execve+0x150>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc020541e:	6785                	lui	a5,0x1
ffffffffc0205420:	00fb0533          	add	a0,s6,a5
ffffffffc0205424:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0205428:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc020542c:	0d44fb63          	bgeu	s1,s4,ffffffffc0205502 <do_execve+0x48a>
    return page - pages + nbase;
ffffffffc0205430:	000bb683          	ld	a3,0(s7)
ffffffffc0205434:	00003797          	auipc	a5,0x3
ffffffffc0205438:	d7478793          	addi	a5,a5,-652 # ffffffffc02081a8 <error_string+0xc8>
ffffffffc020543c:	639c                	ld	a5,0(a5)
ffffffffc020543e:	40dc86b3          	sub	a3,s9,a3
ffffffffc0205442:	868d                	srai	a3,a3,0x3
ffffffffc0205444:	02f686b3          	mul	a3,a3,a5
ffffffffc0205448:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020544a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc020544e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205450:	67e2                	ld	a5,24(sp)
ffffffffc0205452:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205456:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205458:	0cc5f063          	bgeu	a1,a2,ffffffffc0205518 <do_execve+0x4a0>
ffffffffc020545c:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205460:	864e                	mv	a2,s3
ffffffffc0205462:	4581                	li	a1,0
ffffffffc0205464:	96c6                	add	a3,a3,a7
ffffffffc0205466:	9536                	add	a0,a0,a3
ffffffffc0205468:	2d9000ef          	jal	ra,ffffffffc0205f40 <memset>
            start += size;
ffffffffc020546c:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205470:	0344f463          	bgeu	s1,s4,ffffffffc0205498 <do_execve+0x420>
ffffffffc0205474:	d4e48ae3          	beq	s1,a4,ffffffffc02051c8 <do_execve+0x150>
ffffffffc0205478:	00002697          	auipc	a3,0x2
ffffffffc020547c:	68868693          	addi	a3,a3,1672 # ffffffffc0207b00 <default_pmm_manager+0xd10>
ffffffffc0205480:	00001617          	auipc	a2,0x1
ffffffffc0205484:	5c060613          	addi	a2,a2,1472 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205488:	2c900593          	li	a1,713
ffffffffc020548c:	00002517          	auipc	a0,0x2
ffffffffc0205490:	48450513          	addi	a0,a0,1156 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205494:	ffbfa0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0205498:	ff4710e3          	bne	a4,s4,ffffffffc0205478 <do_execve+0x400>
ffffffffc020549c:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc020549e:	d29b75e3          	bgeu	s6,s1,ffffffffc02051c8 <do_execve+0x150>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc02054a2:	6c08                	ld	a0,24(s0)
ffffffffc02054a4:	866a                	mv	a2,s10
ffffffffc02054a6:	85d2                	mv	a1,s4
ffffffffc02054a8:	c1cfe0ef          	jal	ra,ffffffffc02038c4 <pgdir_alloc_page>
ffffffffc02054ac:	8caa                	mv	s9,a0
ffffffffc02054ae:	d50d                	beqz	a0,ffffffffc02053d8 <do_execve+0x360>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02054b0:	6785                	lui	a5,0x1
ffffffffc02054b2:	414b0533          	sub	a0,s6,s4
ffffffffc02054b6:	9a3e                	add	s4,s4,a5
ffffffffc02054b8:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc02054bc:	0144f463          	bgeu	s1,s4,ffffffffc02054c4 <do_execve+0x44c>
                size -= la - end;
ffffffffc02054c0:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc02054c4:	000bb683          	ld	a3,0(s7)
ffffffffc02054c8:	00003797          	auipc	a5,0x3
ffffffffc02054cc:	ce078793          	addi	a5,a5,-800 # ffffffffc02081a8 <error_string+0xc8>
ffffffffc02054d0:	639c                	ld	a5,0(a5)
ffffffffc02054d2:	40dc86b3          	sub	a3,s9,a3
ffffffffc02054d6:	868d                	srai	a3,a3,0x3
ffffffffc02054d8:	02f686b3          	mul	a3,a3,a5
ffffffffc02054dc:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02054de:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02054e2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02054e4:	67e2                	ld	a5,24(sp)
ffffffffc02054e6:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02054ea:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02054ec:	02b8f663          	bgeu	a7,a1,ffffffffc0205518 <do_execve+0x4a0>
ffffffffc02054f0:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc02054f4:	4581                	li	a1,0
            start += size;
ffffffffc02054f6:	9b32                	add	s6,s6,a2
ffffffffc02054f8:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc02054fa:	9536                	add	a0,a0,a3
ffffffffc02054fc:	245000ef          	jal	ra,ffffffffc0205f40 <memset>
ffffffffc0205500:	bf79                	j	ffffffffc020549e <do_execve+0x426>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205502:	416a09b3          	sub	s3,s4,s6
ffffffffc0205506:	b72d                	j	ffffffffc0205430 <do_execve+0x3b8>
        return -E_INVAL;
ffffffffc0205508:	59f5                	li	s3,-3
ffffffffc020550a:	bb51                	j	ffffffffc020529e <do_execve+0x226>
        while (start < end)
ffffffffc020550c:	86da                	mv	a3,s6
ffffffffc020550e:	b709                	j	ffffffffc0205410 <do_execve+0x398>
    int ret = -E_NO_MEM;
ffffffffc0205510:	59f1                	li	s3,-4
ffffffffc0205512:	bdd1                	j	ffffffffc02053e6 <do_execve+0x36e>
            ret = -E_INVAL_ELF;
ffffffffc0205514:	59e1                	li	s3,-8
ffffffffc0205516:	b5d1                	j	ffffffffc02053da <do_execve+0x362>
ffffffffc0205518:	00002617          	auipc	a2,0x2
ffffffffc020551c:	91060613          	addi	a2,a2,-1776 # ffffffffc0206e28 <default_pmm_manager+0x38>
ffffffffc0205520:	08300593          	li	a1,131
ffffffffc0205524:	00002517          	auipc	a0,0x2
ffffffffc0205528:	92c50513          	addi	a0,a0,-1748 # ffffffffc0206e50 <default_pmm_manager+0x60>
ffffffffc020552c:	f63fa0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205530:	00002617          	auipc	a2,0x2
ffffffffc0205534:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206ed0 <default_pmm_manager+0xe0>
ffffffffc0205538:	2e800593          	li	a1,744
ffffffffc020553c:	00002517          	auipc	a0,0x2
ffffffffc0205540:	3d450513          	addi	a0,a0,980 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205544:	f4bfa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205548:	00002697          	auipc	a3,0x2
ffffffffc020554c:	6d068693          	addi	a3,a3,1744 # ffffffffc0207c18 <default_pmm_manager+0xe28>
ffffffffc0205550:	00001617          	auipc	a2,0x1
ffffffffc0205554:	4f060613          	addi	a2,a2,1264 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205558:	2e300593          	li	a1,739
ffffffffc020555c:	00002517          	auipc	a0,0x2
ffffffffc0205560:	3b450513          	addi	a0,a0,948 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205564:	f2bfa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205568:	00002697          	auipc	a3,0x2
ffffffffc020556c:	66868693          	addi	a3,a3,1640 # ffffffffc0207bd0 <default_pmm_manager+0xde0>
ffffffffc0205570:	00001617          	auipc	a2,0x1
ffffffffc0205574:	4d060613          	addi	a2,a2,1232 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205578:	2e200593          	li	a1,738
ffffffffc020557c:	00002517          	auipc	a0,0x2
ffffffffc0205580:	39450513          	addi	a0,a0,916 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205584:	f0bfa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205588:	00002697          	auipc	a3,0x2
ffffffffc020558c:	60068693          	addi	a3,a3,1536 # ffffffffc0207b88 <default_pmm_manager+0xd98>
ffffffffc0205590:	00001617          	auipc	a2,0x1
ffffffffc0205594:	4b060613          	addi	a2,a2,1200 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205598:	2e100593          	li	a1,737
ffffffffc020559c:	00002517          	auipc	a0,0x2
ffffffffc02055a0:	37450513          	addi	a0,a0,884 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc02055a4:	eebfa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02055a8:	00002697          	auipc	a3,0x2
ffffffffc02055ac:	59868693          	addi	a3,a3,1432 # ffffffffc0207b40 <default_pmm_manager+0xd50>
ffffffffc02055b0:	00001617          	auipc	a2,0x1
ffffffffc02055b4:	49060613          	addi	a2,a2,1168 # ffffffffc0206a40 <commands+0x868>
ffffffffc02055b8:	2e000593          	li	a1,736
ffffffffc02055bc:	00002517          	auipc	a0,0x2
ffffffffc02055c0:	35450513          	addi	a0,a0,852 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc02055c4:	ecbfa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02055c8 <do_yield>:
    current->need_resched = 1;
ffffffffc02055c8:	000b1797          	auipc	a5,0xb1
ffffffffc02055cc:	b907b783          	ld	a5,-1136(a5) # ffffffffc02b6158 <current>
ffffffffc02055d0:	4705                	li	a4,1
ffffffffc02055d2:	ef98                	sd	a4,24(a5)
}
ffffffffc02055d4:	4501                	li	a0,0
ffffffffc02055d6:	8082                	ret

ffffffffc02055d8 <do_wait>:
{
ffffffffc02055d8:	1101                	addi	sp,sp,-32
ffffffffc02055da:	e822                	sd	s0,16(sp)
ffffffffc02055dc:	e426                	sd	s1,8(sp)
ffffffffc02055de:	ec06                	sd	ra,24(sp)
ffffffffc02055e0:	842e                	mv	s0,a1
ffffffffc02055e2:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc02055e4:	c999                	beqz	a1,ffffffffc02055fa <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc02055e6:	000b1797          	auipc	a5,0xb1
ffffffffc02055ea:	b727b783          	ld	a5,-1166(a5) # ffffffffc02b6158 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc02055ee:	7788                	ld	a0,40(a5)
ffffffffc02055f0:	4685                	li	a3,1
ffffffffc02055f2:	4611                	li	a2,4
ffffffffc02055f4:	f49fe0ef          	jal	ra,ffffffffc020453c <user_mem_check>
ffffffffc02055f8:	c909                	beqz	a0,ffffffffc020560a <do_wait+0x32>
ffffffffc02055fa:	85a2                	mv	a1,s0
}
ffffffffc02055fc:	6442                	ld	s0,16(sp)
ffffffffc02055fe:	60e2                	ld	ra,24(sp)
ffffffffc0205600:	8526                	mv	a0,s1
ffffffffc0205602:	64a2                	ld	s1,8(sp)
ffffffffc0205604:	6105                	addi	sp,sp,32
ffffffffc0205606:	f74ff06f          	j	ffffffffc0204d7a <do_wait.part.0>
ffffffffc020560a:	60e2                	ld	ra,24(sp)
ffffffffc020560c:	6442                	ld	s0,16(sp)
ffffffffc020560e:	64a2                	ld	s1,8(sp)
ffffffffc0205610:	5575                	li	a0,-3
ffffffffc0205612:	6105                	addi	sp,sp,32
ffffffffc0205614:	8082                	ret

ffffffffc0205616 <do_kill>:
{
ffffffffc0205616:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0205618:	6789                	lui	a5,0x2
{
ffffffffc020561a:	e406                	sd	ra,8(sp)
ffffffffc020561c:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc020561e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205622:	17f9                	addi	a5,a5,-2
ffffffffc0205624:	02e7e963          	bltu	a5,a4,ffffffffc0205656 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205628:	842a                	mv	s0,a0
ffffffffc020562a:	45a9                	li	a1,10
ffffffffc020562c:	2501                	sext.w	a0,a0
ffffffffc020562e:	46c000ef          	jal	ra,ffffffffc0205a9a <hash32>
ffffffffc0205632:	02051793          	slli	a5,a0,0x20
ffffffffc0205636:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020563a:	000ad797          	auipc	a5,0xad
ffffffffc020563e:	a9e78793          	addi	a5,a5,-1378 # ffffffffc02b20d8 <hash_list>
ffffffffc0205642:	953e                	add	a0,a0,a5
ffffffffc0205644:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0205646:	a029                	j	ffffffffc0205650 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0205648:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020564c:	00870b63          	beq	a4,s0,ffffffffc0205662 <do_kill+0x4c>
ffffffffc0205650:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205652:	fef51be3          	bne	a0,a5,ffffffffc0205648 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205656:	5475                	li	s0,-3
}
ffffffffc0205658:	60a2                	ld	ra,8(sp)
ffffffffc020565a:	8522                	mv	a0,s0
ffffffffc020565c:	6402                	ld	s0,0(sp)
ffffffffc020565e:	0141                	addi	sp,sp,16
ffffffffc0205660:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0205662:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205666:	00177693          	andi	a3,a4,1
ffffffffc020566a:	e295                	bnez	a3,ffffffffc020568e <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc020566c:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc020566e:	00176713          	ori	a4,a4,1
ffffffffc0205672:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205676:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205678:	fe06d0e3          	bgez	a3,ffffffffc0205658 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc020567c:	f2878513          	addi	a0,a5,-216
ffffffffc0205680:	22e000ef          	jal	ra,ffffffffc02058ae <wakeup_proc>
}
ffffffffc0205684:	60a2                	ld	ra,8(sp)
ffffffffc0205686:	8522                	mv	a0,s0
ffffffffc0205688:	6402                	ld	s0,0(sp)
ffffffffc020568a:	0141                	addi	sp,sp,16
ffffffffc020568c:	8082                	ret
        return -E_KILLED;
ffffffffc020568e:	545d                	li	s0,-9
ffffffffc0205690:	b7e1                	j	ffffffffc0205658 <do_kill+0x42>

ffffffffc0205692 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205692:	1101                	addi	sp,sp,-32
ffffffffc0205694:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205696:	000b1797          	auipc	a5,0xb1
ffffffffc020569a:	a4278793          	addi	a5,a5,-1470 # ffffffffc02b60d8 <proc_list>
ffffffffc020569e:	ec06                	sd	ra,24(sp)
ffffffffc02056a0:	e822                	sd	s0,16(sp)
ffffffffc02056a2:	e04a                	sd	s2,0(sp)
ffffffffc02056a4:	000ad497          	auipc	s1,0xad
ffffffffc02056a8:	a3448493          	addi	s1,s1,-1484 # ffffffffc02b20d8 <hash_list>
ffffffffc02056ac:	e79c                	sd	a5,8(a5)
ffffffffc02056ae:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02056b0:	000b1717          	auipc	a4,0xb1
ffffffffc02056b4:	a2870713          	addi	a4,a4,-1496 # ffffffffc02b60d8 <proc_list>
ffffffffc02056b8:	87a6                	mv	a5,s1
ffffffffc02056ba:	e79c                	sd	a5,8(a5)
ffffffffc02056bc:	e39c                	sd	a5,0(a5)
ffffffffc02056be:	07c1                	addi	a5,a5,16
ffffffffc02056c0:	fef71de3          	bne	a4,a5,ffffffffc02056ba <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02056c4:	f15fe0ef          	jal	ra,ffffffffc02045d8 <alloc_proc>
ffffffffc02056c8:	000b1917          	auipc	s2,0xb1
ffffffffc02056cc:	a9890913          	addi	s2,s2,-1384 # ffffffffc02b6160 <idleproc>
ffffffffc02056d0:	00a93023          	sd	a0,0(s2)
ffffffffc02056d4:	0e050f63          	beqz	a0,ffffffffc02057d2 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02056d8:	4789                	li	a5,2
ffffffffc02056da:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02056dc:	00004797          	auipc	a5,0x4
ffffffffc02056e0:	92478793          	addi	a5,a5,-1756 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02056e4:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02056e8:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc02056ea:	4785                	li	a5,1
ffffffffc02056ec:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02056ee:	4641                	li	a2,16
ffffffffc02056f0:	4581                	li	a1,0
ffffffffc02056f2:	8522                	mv	a0,s0
ffffffffc02056f4:	04d000ef          	jal	ra,ffffffffc0205f40 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02056f8:	463d                	li	a2,15
ffffffffc02056fa:	00002597          	auipc	a1,0x2
ffffffffc02056fe:	57e58593          	addi	a1,a1,1406 # ffffffffc0207c78 <default_pmm_manager+0xe88>
ffffffffc0205702:	8522                	mv	a0,s0
ffffffffc0205704:	04f000ef          	jal	ra,ffffffffc0205f52 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205708:	000b1717          	auipc	a4,0xb1
ffffffffc020570c:	a6870713          	addi	a4,a4,-1432 # ffffffffc02b6170 <nr_process>
ffffffffc0205710:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205712:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205716:	4601                	li	a2,0
    nr_process++;
ffffffffc0205718:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020571a:	4581                	li	a1,0
ffffffffc020571c:	00000517          	auipc	a0,0x0
ffffffffc0205720:	83850513          	addi	a0,a0,-1992 # ffffffffc0204f54 <init_main>
    nr_process++;
ffffffffc0205724:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205726:	000b1797          	auipc	a5,0xb1
ffffffffc020572a:	a2d7b923          	sd	a3,-1486(a5) # ffffffffc02b6158 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020572e:	cb2ff0ef          	jal	ra,ffffffffc0204be0 <kernel_thread>
ffffffffc0205732:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205734:	08a05363          	blez	a0,ffffffffc02057ba <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205738:	6789                	lui	a5,0x2
ffffffffc020573a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020573e:	17f9                	addi	a5,a5,-2
ffffffffc0205740:	2501                	sext.w	a0,a0
ffffffffc0205742:	02e7e363          	bltu	a5,a4,ffffffffc0205768 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205746:	45a9                	li	a1,10
ffffffffc0205748:	352000ef          	jal	ra,ffffffffc0205a9a <hash32>
ffffffffc020574c:	02051793          	slli	a5,a0,0x20
ffffffffc0205750:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205754:	96a6                	add	a3,a3,s1
ffffffffc0205756:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205758:	a029                	j	ffffffffc0205762 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc020575a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c94>
ffffffffc020575e:	04870b63          	beq	a4,s0,ffffffffc02057b4 <proc_init+0x122>
    return listelm->next;
ffffffffc0205762:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205764:	fef69be3          	bne	a3,a5,ffffffffc020575a <proc_init+0xc8>
    return NULL;
ffffffffc0205768:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020576a:	0b478493          	addi	s1,a5,180
ffffffffc020576e:	4641                	li	a2,16
ffffffffc0205770:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205772:	000b1417          	auipc	s0,0xb1
ffffffffc0205776:	9f640413          	addi	s0,s0,-1546 # ffffffffc02b6168 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020577a:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020577c:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020577e:	7c2000ef          	jal	ra,ffffffffc0205f40 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205782:	463d                	li	a2,15
ffffffffc0205784:	00002597          	auipc	a1,0x2
ffffffffc0205788:	51c58593          	addi	a1,a1,1308 # ffffffffc0207ca0 <default_pmm_manager+0xeb0>
ffffffffc020578c:	8526                	mv	a0,s1
ffffffffc020578e:	7c4000ef          	jal	ra,ffffffffc0205f52 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205792:	00093783          	ld	a5,0(s2)
ffffffffc0205796:	cbb5                	beqz	a5,ffffffffc020580a <proc_init+0x178>
ffffffffc0205798:	43dc                	lw	a5,4(a5)
ffffffffc020579a:	eba5                	bnez	a5,ffffffffc020580a <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020579c:	601c                	ld	a5,0(s0)
ffffffffc020579e:	c7b1                	beqz	a5,ffffffffc02057ea <proc_init+0x158>
ffffffffc02057a0:	43d8                	lw	a4,4(a5)
ffffffffc02057a2:	4785                	li	a5,1
ffffffffc02057a4:	04f71363          	bne	a4,a5,ffffffffc02057ea <proc_init+0x158>
}
ffffffffc02057a8:	60e2                	ld	ra,24(sp)
ffffffffc02057aa:	6442                	ld	s0,16(sp)
ffffffffc02057ac:	64a2                	ld	s1,8(sp)
ffffffffc02057ae:	6902                	ld	s2,0(sp)
ffffffffc02057b0:	6105                	addi	sp,sp,32
ffffffffc02057b2:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02057b4:	f2878793          	addi	a5,a5,-216
ffffffffc02057b8:	bf4d                	j	ffffffffc020576a <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02057ba:	00002617          	auipc	a2,0x2
ffffffffc02057be:	4c660613          	addi	a2,a2,1222 # ffffffffc0207c80 <default_pmm_manager+0xe90>
ffffffffc02057c2:	40a00593          	li	a1,1034
ffffffffc02057c6:	00002517          	auipc	a0,0x2
ffffffffc02057ca:	14a50513          	addi	a0,a0,330 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc02057ce:	cc1fa0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02057d2:	00002617          	auipc	a2,0x2
ffffffffc02057d6:	48e60613          	addi	a2,a2,1166 # ffffffffc0207c60 <default_pmm_manager+0xe70>
ffffffffc02057da:	3fb00593          	li	a1,1019
ffffffffc02057de:	00002517          	auipc	a0,0x2
ffffffffc02057e2:	13250513          	addi	a0,a0,306 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc02057e6:	ca9fa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02057ea:	00002697          	auipc	a3,0x2
ffffffffc02057ee:	4e668693          	addi	a3,a3,1254 # ffffffffc0207cd0 <default_pmm_manager+0xee0>
ffffffffc02057f2:	00001617          	auipc	a2,0x1
ffffffffc02057f6:	24e60613          	addi	a2,a2,590 # ffffffffc0206a40 <commands+0x868>
ffffffffc02057fa:	41100593          	li	a1,1041
ffffffffc02057fe:	00002517          	auipc	a0,0x2
ffffffffc0205802:	11250513          	addi	a0,a0,274 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205806:	c89fa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020580a:	00002697          	auipc	a3,0x2
ffffffffc020580e:	49e68693          	addi	a3,a3,1182 # ffffffffc0207ca8 <default_pmm_manager+0xeb8>
ffffffffc0205812:	00001617          	auipc	a2,0x1
ffffffffc0205816:	22e60613          	addi	a2,a2,558 # ffffffffc0206a40 <commands+0x868>
ffffffffc020581a:	41000593          	li	a1,1040
ffffffffc020581e:	00002517          	auipc	a0,0x2
ffffffffc0205822:	0f250513          	addi	a0,a0,242 # ffffffffc0207910 <default_pmm_manager+0xb20>
ffffffffc0205826:	c69fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020582a <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020582a:	1141                	addi	sp,sp,-16
ffffffffc020582c:	e022                	sd	s0,0(sp)
ffffffffc020582e:	e406                	sd	ra,8(sp)
ffffffffc0205830:	000b1417          	auipc	s0,0xb1
ffffffffc0205834:	92840413          	addi	s0,s0,-1752 # ffffffffc02b6158 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205838:	6018                	ld	a4,0(s0)
ffffffffc020583a:	6f1c                	ld	a5,24(a4)
ffffffffc020583c:	dffd                	beqz	a5,ffffffffc020583a <cpu_idle+0x10>
        {
            schedule();
ffffffffc020583e:	0f0000ef          	jal	ra,ffffffffc020592e <schedule>
ffffffffc0205842:	bfdd                	j	ffffffffc0205838 <cpu_idle+0xe>

ffffffffc0205844 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205844:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205848:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020584c:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020584e:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205850:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205854:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205858:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020585c:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205860:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205864:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205868:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020586c:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205870:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205874:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205878:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020587c:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205880:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205882:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205884:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205888:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020588c:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205890:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205894:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205898:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020589c:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02058a0:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02058a4:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02058a8:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02058ac:	8082                	ret

ffffffffc02058ae <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02058ae:	4118                	lw	a4,0(a0)
{
ffffffffc02058b0:	1101                	addi	sp,sp,-32
ffffffffc02058b2:	ec06                	sd	ra,24(sp)
ffffffffc02058b4:	e822                	sd	s0,16(sp)
ffffffffc02058b6:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02058b8:	478d                	li	a5,3
ffffffffc02058ba:	04f70b63          	beq	a4,a5,ffffffffc0205910 <wakeup_proc+0x62>
ffffffffc02058be:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02058c0:	100027f3          	csrr	a5,sstatus
ffffffffc02058c4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02058c6:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02058c8:	ef9d                	bnez	a5,ffffffffc0205906 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02058ca:	4789                	li	a5,2
ffffffffc02058cc:	02f70163          	beq	a4,a5,ffffffffc02058ee <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02058d0:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02058d2:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02058d6:	e491                	bnez	s1,ffffffffc02058e2 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02058d8:	60e2                	ld	ra,24(sp)
ffffffffc02058da:	6442                	ld	s0,16(sp)
ffffffffc02058dc:	64a2                	ld	s1,8(sp)
ffffffffc02058de:	6105                	addi	sp,sp,32
ffffffffc02058e0:	8082                	ret
ffffffffc02058e2:	6442                	ld	s0,16(sp)
ffffffffc02058e4:	60e2                	ld	ra,24(sp)
ffffffffc02058e6:	64a2                	ld	s1,8(sp)
ffffffffc02058e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02058ea:	8c4fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02058ee:	00002617          	auipc	a2,0x2
ffffffffc02058f2:	44260613          	addi	a2,a2,1090 # ffffffffc0207d30 <default_pmm_manager+0xf40>
ffffffffc02058f6:	45d1                	li	a1,20
ffffffffc02058f8:	00002517          	auipc	a0,0x2
ffffffffc02058fc:	42050513          	addi	a0,a0,1056 # ffffffffc0207d18 <default_pmm_manager+0xf28>
ffffffffc0205900:	bf7fa0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205904:	bfc9                	j	ffffffffc02058d6 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205906:	8aefb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020590a:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020590c:	4485                	li	s1,1
ffffffffc020590e:	bf75                	j	ffffffffc02058ca <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205910:	00002697          	auipc	a3,0x2
ffffffffc0205914:	3e868693          	addi	a3,a3,1000 # ffffffffc0207cf8 <default_pmm_manager+0xf08>
ffffffffc0205918:	00001617          	auipc	a2,0x1
ffffffffc020591c:	12860613          	addi	a2,a2,296 # ffffffffc0206a40 <commands+0x868>
ffffffffc0205920:	45a5                	li	a1,9
ffffffffc0205922:	00002517          	auipc	a0,0x2
ffffffffc0205926:	3f650513          	addi	a0,a0,1014 # ffffffffc0207d18 <default_pmm_manager+0xf28>
ffffffffc020592a:	b65fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020592e <schedule>:

void schedule(void)
{
ffffffffc020592e:	1141                	addi	sp,sp,-16
ffffffffc0205930:	e406                	sd	ra,8(sp)
ffffffffc0205932:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205934:	100027f3          	csrr	a5,sstatus
ffffffffc0205938:	8b89                	andi	a5,a5,2
ffffffffc020593a:	4401                	li	s0,0
ffffffffc020593c:	efbd                	bnez	a5,ffffffffc02059ba <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020593e:	000b1897          	auipc	a7,0xb1
ffffffffc0205942:	81a8b883          	ld	a7,-2022(a7) # ffffffffc02b6158 <current>
ffffffffc0205946:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020594a:	000b1517          	auipc	a0,0xb1
ffffffffc020594e:	81653503          	ld	a0,-2026(a0) # ffffffffc02b6160 <idleproc>
ffffffffc0205952:	04a88e63          	beq	a7,a0,ffffffffc02059ae <schedule+0x80>
ffffffffc0205956:	0c888693          	addi	a3,a7,200
ffffffffc020595a:	000b0617          	auipc	a2,0xb0
ffffffffc020595e:	77e60613          	addi	a2,a2,1918 # ffffffffc02b60d8 <proc_list>
        le = last;
ffffffffc0205962:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205964:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205966:	4809                	li	a6,2
ffffffffc0205968:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020596a:	00c78863          	beq	a5,a2,ffffffffc020597a <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc020596e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205972:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205976:	03070163          	beq	a4,a6,ffffffffc0205998 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020597a:	fef697e3          	bne	a3,a5,ffffffffc0205968 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020597e:	ed89                	bnez	a1,ffffffffc0205998 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205980:	451c                	lw	a5,8(a0)
ffffffffc0205982:	2785                	addiw	a5,a5,1
ffffffffc0205984:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205986:	00a88463          	beq	a7,a0,ffffffffc020598e <schedule+0x60>
        {
            proc_run(next);
ffffffffc020598a:	dd3fe0ef          	jal	ra,ffffffffc020475c <proc_run>
    if (flag)
ffffffffc020598e:	e819                	bnez	s0,ffffffffc02059a4 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205990:	60a2                	ld	ra,8(sp)
ffffffffc0205992:	6402                	ld	s0,0(sp)
ffffffffc0205994:	0141                	addi	sp,sp,16
ffffffffc0205996:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205998:	4198                	lw	a4,0(a1)
ffffffffc020599a:	4789                	li	a5,2
ffffffffc020599c:	fef712e3          	bne	a4,a5,ffffffffc0205980 <schedule+0x52>
ffffffffc02059a0:	852e                	mv	a0,a1
ffffffffc02059a2:	bff9                	j	ffffffffc0205980 <schedule+0x52>
}
ffffffffc02059a4:	6402                	ld	s0,0(sp)
ffffffffc02059a6:	60a2                	ld	ra,8(sp)
ffffffffc02059a8:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02059aa:	804fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02059ae:	000b0617          	auipc	a2,0xb0
ffffffffc02059b2:	72a60613          	addi	a2,a2,1834 # ffffffffc02b60d8 <proc_list>
ffffffffc02059b6:	86b2                	mv	a3,a2
ffffffffc02059b8:	b76d                	j	ffffffffc0205962 <schedule+0x34>
        intr_disable();
ffffffffc02059ba:	ffbfa0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02059be:	4405                	li	s0,1
ffffffffc02059c0:	bfbd                	j	ffffffffc020593e <schedule+0x10>

ffffffffc02059c2 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02059c2:	000b0797          	auipc	a5,0xb0
ffffffffc02059c6:	7967b783          	ld	a5,1942(a5) # ffffffffc02b6158 <current>
}
ffffffffc02059ca:	43c8                	lw	a0,4(a5)
ffffffffc02059cc:	8082                	ret

ffffffffc02059ce <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02059ce:	4501                	li	a0,0
ffffffffc02059d0:	8082                	ret

ffffffffc02059d2 <sys_putc>:
    cputchar(c);
ffffffffc02059d2:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02059d4:	1141                	addi	sp,sp,-16
ffffffffc02059d6:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02059d8:	ff2fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02059dc:	60a2                	ld	ra,8(sp)
ffffffffc02059de:	4501                	li	a0,0
ffffffffc02059e0:	0141                	addi	sp,sp,16
ffffffffc02059e2:	8082                	ret

ffffffffc02059e4 <sys_kill>:
    return do_kill(pid);
ffffffffc02059e4:	4108                	lw	a0,0(a0)
ffffffffc02059e6:	c31ff06f          	j	ffffffffc0205616 <do_kill>

ffffffffc02059ea <sys_yield>:
    return do_yield();
ffffffffc02059ea:	bdfff06f          	j	ffffffffc02055c8 <do_yield>

ffffffffc02059ee <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02059ee:	6d14                	ld	a3,24(a0)
ffffffffc02059f0:	6910                	ld	a2,16(a0)
ffffffffc02059f2:	650c                	ld	a1,8(a0)
ffffffffc02059f4:	6108                	ld	a0,0(a0)
ffffffffc02059f6:	e82ff06f          	j	ffffffffc0205078 <do_execve>

ffffffffc02059fa <sys_wait>:
    return do_wait(pid, store);
ffffffffc02059fa:	650c                	ld	a1,8(a0)
ffffffffc02059fc:	4108                	lw	a0,0(a0)
ffffffffc02059fe:	bdbff06f          	j	ffffffffc02055d8 <do_wait>

ffffffffc0205a02 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205a02:	000b0797          	auipc	a5,0xb0
ffffffffc0205a06:	7567b783          	ld	a5,1878(a5) # ffffffffc02b6158 <current>
ffffffffc0205a0a:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205a0c:	4501                	li	a0,0
ffffffffc0205a0e:	6a0c                	ld	a1,16(a2)
ffffffffc0205a10:	db9fe06f          	j	ffffffffc02047c8 <do_fork>

ffffffffc0205a14 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205a14:	4108                	lw	a0,0(a0)
ffffffffc0205a16:	a1aff06f          	j	ffffffffc0204c30 <do_exit>

ffffffffc0205a1a <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205a1a:	715d                	addi	sp,sp,-80
ffffffffc0205a1c:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205a1e:	000b0497          	auipc	s1,0xb0
ffffffffc0205a22:	73a48493          	addi	s1,s1,1850 # ffffffffc02b6158 <current>
ffffffffc0205a26:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205a28:	e0a2                	sd	s0,64(sp)
ffffffffc0205a2a:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205a2c:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205a2e:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205a30:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205a32:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205a36:	0327ee63          	bltu	a5,s2,ffffffffc0205a72 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205a3a:	00391713          	slli	a4,s2,0x3
ffffffffc0205a3e:	00002797          	auipc	a5,0x2
ffffffffc0205a42:	35a78793          	addi	a5,a5,858 # ffffffffc0207d98 <syscalls>
ffffffffc0205a46:	97ba                	add	a5,a5,a4
ffffffffc0205a48:	639c                	ld	a5,0(a5)
ffffffffc0205a4a:	c785                	beqz	a5,ffffffffc0205a72 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205a4c:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205a4e:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205a50:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205a52:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205a54:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205a56:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205a58:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205a5a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205a5c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205a5e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205a60:	0028                	addi	a0,sp,8
ffffffffc0205a62:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205a64:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205a66:	e828                	sd	a0,80(s0)
}
ffffffffc0205a68:	6406                	ld	s0,64(sp)
ffffffffc0205a6a:	74e2                	ld	s1,56(sp)
ffffffffc0205a6c:	7942                	ld	s2,48(sp)
ffffffffc0205a6e:	6161                	addi	sp,sp,80
ffffffffc0205a70:	8082                	ret
    print_trapframe(tf);
ffffffffc0205a72:	8522                	mv	a0,s0
ffffffffc0205a74:	930fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205a78:	609c                	ld	a5,0(s1)
ffffffffc0205a7a:	86ca                	mv	a3,s2
ffffffffc0205a7c:	00002617          	auipc	a2,0x2
ffffffffc0205a80:	2d460613          	addi	a2,a2,724 # ffffffffc0207d50 <default_pmm_manager+0xf60>
ffffffffc0205a84:	43d8                	lw	a4,4(a5)
ffffffffc0205a86:	06200593          	li	a1,98
ffffffffc0205a8a:	0b478793          	addi	a5,a5,180
ffffffffc0205a8e:	00002517          	auipc	a0,0x2
ffffffffc0205a92:	2f250513          	addi	a0,a0,754 # ffffffffc0207d80 <default_pmm_manager+0xf90>
ffffffffc0205a96:	9f9fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205a9a <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205a9a:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205a9e:	2785                	addiw	a5,a5,1
ffffffffc0205aa0:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205aa4:	02000793          	li	a5,32
ffffffffc0205aa8:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205aaa:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205aae:	8082                	ret

ffffffffc0205ab0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205ab0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205ab4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205ab6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205aba:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205abc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205ac0:	f022                	sd	s0,32(sp)
ffffffffc0205ac2:	ec26                	sd	s1,24(sp)
ffffffffc0205ac4:	e84a                	sd	s2,16(sp)
ffffffffc0205ac6:	f406                	sd	ra,40(sp)
ffffffffc0205ac8:	e44e                	sd	s3,8(sp)
ffffffffc0205aca:	84aa                	mv	s1,a0
ffffffffc0205acc:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205ace:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205ad2:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205ad4:	03067e63          	bgeu	a2,a6,ffffffffc0205b10 <printnum+0x60>
ffffffffc0205ad8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205ada:	00805763          	blez	s0,ffffffffc0205ae8 <printnum+0x38>
ffffffffc0205ade:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205ae0:	85ca                	mv	a1,s2
ffffffffc0205ae2:	854e                	mv	a0,s3
ffffffffc0205ae4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205ae6:	fc65                	bnez	s0,ffffffffc0205ade <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205ae8:	1a02                	slli	s4,s4,0x20
ffffffffc0205aea:	00002797          	auipc	a5,0x2
ffffffffc0205aee:	3ae78793          	addi	a5,a5,942 # ffffffffc0207e98 <syscalls+0x100>
ffffffffc0205af2:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205af6:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205af8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205afa:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205afe:	70a2                	ld	ra,40(sp)
ffffffffc0205b00:	69a2                	ld	s3,8(sp)
ffffffffc0205b02:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205b04:	85ca                	mv	a1,s2
ffffffffc0205b06:	87a6                	mv	a5,s1
}
ffffffffc0205b08:	6942                	ld	s2,16(sp)
ffffffffc0205b0a:	64e2                	ld	s1,24(sp)
ffffffffc0205b0c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205b0e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205b10:	03065633          	divu	a2,a2,a6
ffffffffc0205b14:	8722                	mv	a4,s0
ffffffffc0205b16:	f9bff0ef          	jal	ra,ffffffffc0205ab0 <printnum>
ffffffffc0205b1a:	b7f9                	j	ffffffffc0205ae8 <printnum+0x38>

ffffffffc0205b1c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205b1c:	7119                	addi	sp,sp,-128
ffffffffc0205b1e:	f4a6                	sd	s1,104(sp)
ffffffffc0205b20:	f0ca                	sd	s2,96(sp)
ffffffffc0205b22:	ecce                	sd	s3,88(sp)
ffffffffc0205b24:	e8d2                	sd	s4,80(sp)
ffffffffc0205b26:	e4d6                	sd	s5,72(sp)
ffffffffc0205b28:	e0da                	sd	s6,64(sp)
ffffffffc0205b2a:	fc5e                	sd	s7,56(sp)
ffffffffc0205b2c:	f06a                	sd	s10,32(sp)
ffffffffc0205b2e:	fc86                	sd	ra,120(sp)
ffffffffc0205b30:	f8a2                	sd	s0,112(sp)
ffffffffc0205b32:	f862                	sd	s8,48(sp)
ffffffffc0205b34:	f466                	sd	s9,40(sp)
ffffffffc0205b36:	ec6e                	sd	s11,24(sp)
ffffffffc0205b38:	892a                	mv	s2,a0
ffffffffc0205b3a:	84ae                	mv	s1,a1
ffffffffc0205b3c:	8d32                	mv	s10,a2
ffffffffc0205b3e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205b40:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205b44:	5b7d                	li	s6,-1
ffffffffc0205b46:	00002a97          	auipc	s5,0x2
ffffffffc0205b4a:	37ea8a93          	addi	s5,s5,894 # ffffffffc0207ec4 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205b4e:	00002b97          	auipc	s7,0x2
ffffffffc0205b52:	592b8b93          	addi	s7,s7,1426 # ffffffffc02080e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205b56:	000d4503          	lbu	a0,0(s10)
ffffffffc0205b5a:	001d0413          	addi	s0,s10,1
ffffffffc0205b5e:	01350a63          	beq	a0,s3,ffffffffc0205b72 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205b62:	c121                	beqz	a0,ffffffffc0205ba2 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205b64:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205b66:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205b68:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205b6a:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205b6e:	ff351ae3          	bne	a0,s3,ffffffffc0205b62 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b72:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205b76:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205b7a:	4c81                	li	s9,0
ffffffffc0205b7c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205b7e:	5c7d                	li	s8,-1
ffffffffc0205b80:	5dfd                	li	s11,-1
ffffffffc0205b82:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205b86:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b88:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205b8c:	0ff5f593          	zext.b	a1,a1
ffffffffc0205b90:	00140d13          	addi	s10,s0,1
ffffffffc0205b94:	04b56263          	bltu	a0,a1,ffffffffc0205bd8 <vprintfmt+0xbc>
ffffffffc0205b98:	058a                	slli	a1,a1,0x2
ffffffffc0205b9a:	95d6                	add	a1,a1,s5
ffffffffc0205b9c:	4194                	lw	a3,0(a1)
ffffffffc0205b9e:	96d6                	add	a3,a3,s5
ffffffffc0205ba0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205ba2:	70e6                	ld	ra,120(sp)
ffffffffc0205ba4:	7446                	ld	s0,112(sp)
ffffffffc0205ba6:	74a6                	ld	s1,104(sp)
ffffffffc0205ba8:	7906                	ld	s2,96(sp)
ffffffffc0205baa:	69e6                	ld	s3,88(sp)
ffffffffc0205bac:	6a46                	ld	s4,80(sp)
ffffffffc0205bae:	6aa6                	ld	s5,72(sp)
ffffffffc0205bb0:	6b06                	ld	s6,64(sp)
ffffffffc0205bb2:	7be2                	ld	s7,56(sp)
ffffffffc0205bb4:	7c42                	ld	s8,48(sp)
ffffffffc0205bb6:	7ca2                	ld	s9,40(sp)
ffffffffc0205bb8:	7d02                	ld	s10,32(sp)
ffffffffc0205bba:	6de2                	ld	s11,24(sp)
ffffffffc0205bbc:	6109                	addi	sp,sp,128
ffffffffc0205bbe:	8082                	ret
            padc = '0';
ffffffffc0205bc0:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205bc2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205bc6:	846a                	mv	s0,s10
ffffffffc0205bc8:	00140d13          	addi	s10,s0,1
ffffffffc0205bcc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205bd0:	0ff5f593          	zext.b	a1,a1
ffffffffc0205bd4:	fcb572e3          	bgeu	a0,a1,ffffffffc0205b98 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205bd8:	85a6                	mv	a1,s1
ffffffffc0205bda:	02500513          	li	a0,37
ffffffffc0205bde:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205be0:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205be4:	8d22                	mv	s10,s0
ffffffffc0205be6:	f73788e3          	beq	a5,s3,ffffffffc0205b56 <vprintfmt+0x3a>
ffffffffc0205bea:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205bee:	1d7d                	addi	s10,s10,-1
ffffffffc0205bf0:	ff379de3          	bne	a5,s3,ffffffffc0205bea <vprintfmt+0xce>
ffffffffc0205bf4:	b78d                	j	ffffffffc0205b56 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205bf6:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205bfa:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205bfe:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205c00:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205c04:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205c08:	02d86463          	bltu	a6,a3,ffffffffc0205c30 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205c0c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205c10:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205c14:	0186873b          	addw	a4,a3,s8
ffffffffc0205c18:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205c1c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205c1e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205c22:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205c24:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205c28:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205c2c:	fed870e3          	bgeu	a6,a3,ffffffffc0205c0c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205c30:	f40ddce3          	bgez	s11,ffffffffc0205b88 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205c34:	8de2                	mv	s11,s8
ffffffffc0205c36:	5c7d                	li	s8,-1
ffffffffc0205c38:	bf81                	j	ffffffffc0205b88 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205c3a:	fffdc693          	not	a3,s11
ffffffffc0205c3e:	96fd                	srai	a3,a3,0x3f
ffffffffc0205c40:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c44:	00144603          	lbu	a2,1(s0)
ffffffffc0205c48:	2d81                	sext.w	s11,s11
ffffffffc0205c4a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205c4c:	bf35                	j	ffffffffc0205b88 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205c4e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c52:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205c56:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c58:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205c5a:	bfd9                	j	ffffffffc0205c30 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205c5c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205c5e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205c62:	01174463          	blt	a4,a7,ffffffffc0205c6a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205c66:	1a088e63          	beqz	a7,ffffffffc0205e22 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205c6a:	000a3603          	ld	a2,0(s4)
ffffffffc0205c6e:	46c1                	li	a3,16
ffffffffc0205c70:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205c72:	2781                	sext.w	a5,a5
ffffffffc0205c74:	876e                	mv	a4,s11
ffffffffc0205c76:	85a6                	mv	a1,s1
ffffffffc0205c78:	854a                	mv	a0,s2
ffffffffc0205c7a:	e37ff0ef          	jal	ra,ffffffffc0205ab0 <printnum>
            break;
ffffffffc0205c7e:	bde1                	j	ffffffffc0205b56 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205c80:	000a2503          	lw	a0,0(s4)
ffffffffc0205c84:	85a6                	mv	a1,s1
ffffffffc0205c86:	0a21                	addi	s4,s4,8
ffffffffc0205c88:	9902                	jalr	s2
            break;
ffffffffc0205c8a:	b5f1                	j	ffffffffc0205b56 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205c8c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205c8e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205c92:	01174463          	blt	a4,a7,ffffffffc0205c9a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205c96:	18088163          	beqz	a7,ffffffffc0205e18 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205c9a:	000a3603          	ld	a2,0(s4)
ffffffffc0205c9e:	46a9                	li	a3,10
ffffffffc0205ca0:	8a2e                	mv	s4,a1
ffffffffc0205ca2:	bfc1                	j	ffffffffc0205c72 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205ca4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205ca8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205caa:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205cac:	bdf1                	j	ffffffffc0205b88 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205cae:	85a6                	mv	a1,s1
ffffffffc0205cb0:	02500513          	li	a0,37
ffffffffc0205cb4:	9902                	jalr	s2
            break;
ffffffffc0205cb6:	b545                	j	ffffffffc0205b56 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205cb8:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205cbc:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205cbe:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205cc0:	b5e1                	j	ffffffffc0205b88 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205cc2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205cc4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205cc8:	01174463          	blt	a4,a7,ffffffffc0205cd0 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205ccc:	14088163          	beqz	a7,ffffffffc0205e0e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205cd0:	000a3603          	ld	a2,0(s4)
ffffffffc0205cd4:	46a1                	li	a3,8
ffffffffc0205cd6:	8a2e                	mv	s4,a1
ffffffffc0205cd8:	bf69                	j	ffffffffc0205c72 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205cda:	03000513          	li	a0,48
ffffffffc0205cde:	85a6                	mv	a1,s1
ffffffffc0205ce0:	e03e                	sd	a5,0(sp)
ffffffffc0205ce2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205ce4:	85a6                	mv	a1,s1
ffffffffc0205ce6:	07800513          	li	a0,120
ffffffffc0205cea:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205cec:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205cee:	6782                	ld	a5,0(sp)
ffffffffc0205cf0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205cf2:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205cf6:	bfb5                	j	ffffffffc0205c72 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205cf8:	000a3403          	ld	s0,0(s4)
ffffffffc0205cfc:	008a0713          	addi	a4,s4,8
ffffffffc0205d00:	e03a                	sd	a4,0(sp)
ffffffffc0205d02:	14040263          	beqz	s0,ffffffffc0205e46 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205d06:	0fb05763          	blez	s11,ffffffffc0205df4 <vprintfmt+0x2d8>
ffffffffc0205d0a:	02d00693          	li	a3,45
ffffffffc0205d0e:	0cd79163          	bne	a5,a3,ffffffffc0205dd0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205d12:	00044783          	lbu	a5,0(s0)
ffffffffc0205d16:	0007851b          	sext.w	a0,a5
ffffffffc0205d1a:	cf85                	beqz	a5,ffffffffc0205d52 <vprintfmt+0x236>
ffffffffc0205d1c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205d20:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205d24:	000c4563          	bltz	s8,ffffffffc0205d2e <vprintfmt+0x212>
ffffffffc0205d28:	3c7d                	addiw	s8,s8,-1
ffffffffc0205d2a:	036c0263          	beq	s8,s6,ffffffffc0205d4e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205d2e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205d30:	0e0c8e63          	beqz	s9,ffffffffc0205e2c <vprintfmt+0x310>
ffffffffc0205d34:	3781                	addiw	a5,a5,-32
ffffffffc0205d36:	0ef47b63          	bgeu	s0,a5,ffffffffc0205e2c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205d3a:	03f00513          	li	a0,63
ffffffffc0205d3e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205d40:	000a4783          	lbu	a5,0(s4)
ffffffffc0205d44:	3dfd                	addiw	s11,s11,-1
ffffffffc0205d46:	0a05                	addi	s4,s4,1
ffffffffc0205d48:	0007851b          	sext.w	a0,a5
ffffffffc0205d4c:	ffe1                	bnez	a5,ffffffffc0205d24 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205d4e:	01b05963          	blez	s11,ffffffffc0205d60 <vprintfmt+0x244>
ffffffffc0205d52:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205d54:	85a6                	mv	a1,s1
ffffffffc0205d56:	02000513          	li	a0,32
ffffffffc0205d5a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205d5c:	fe0d9be3          	bnez	s11,ffffffffc0205d52 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205d60:	6a02                	ld	s4,0(sp)
ffffffffc0205d62:	bbd5                	j	ffffffffc0205b56 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205d64:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205d66:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205d6a:	01174463          	blt	a4,a7,ffffffffc0205d72 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205d6e:	08088d63          	beqz	a7,ffffffffc0205e08 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205d72:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205d76:	0a044d63          	bltz	s0,ffffffffc0205e30 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205d7a:	8622                	mv	a2,s0
ffffffffc0205d7c:	8a66                	mv	s4,s9
ffffffffc0205d7e:	46a9                	li	a3,10
ffffffffc0205d80:	bdcd                	j	ffffffffc0205c72 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205d82:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205d86:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205d88:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205d8a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205d8e:	8fb5                	xor	a5,a5,a3
ffffffffc0205d90:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205d94:	02d74163          	blt	a4,a3,ffffffffc0205db6 <vprintfmt+0x29a>
ffffffffc0205d98:	00369793          	slli	a5,a3,0x3
ffffffffc0205d9c:	97de                	add	a5,a5,s7
ffffffffc0205d9e:	639c                	ld	a5,0(a5)
ffffffffc0205da0:	cb99                	beqz	a5,ffffffffc0205db6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205da2:	86be                	mv	a3,a5
ffffffffc0205da4:	00000617          	auipc	a2,0x0
ffffffffc0205da8:	1f460613          	addi	a2,a2,500 # ffffffffc0205f98 <etext+0x2e>
ffffffffc0205dac:	85a6                	mv	a1,s1
ffffffffc0205dae:	854a                	mv	a0,s2
ffffffffc0205db0:	0ce000ef          	jal	ra,ffffffffc0205e7e <printfmt>
ffffffffc0205db4:	b34d                	j	ffffffffc0205b56 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205db6:	00002617          	auipc	a2,0x2
ffffffffc0205dba:	10260613          	addi	a2,a2,258 # ffffffffc0207eb8 <syscalls+0x120>
ffffffffc0205dbe:	85a6                	mv	a1,s1
ffffffffc0205dc0:	854a                	mv	a0,s2
ffffffffc0205dc2:	0bc000ef          	jal	ra,ffffffffc0205e7e <printfmt>
ffffffffc0205dc6:	bb41                	j	ffffffffc0205b56 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205dc8:	00002417          	auipc	s0,0x2
ffffffffc0205dcc:	0e840413          	addi	s0,s0,232 # ffffffffc0207eb0 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205dd0:	85e2                	mv	a1,s8
ffffffffc0205dd2:	8522                	mv	a0,s0
ffffffffc0205dd4:	e43e                	sd	a5,8(sp)
ffffffffc0205dd6:	0e2000ef          	jal	ra,ffffffffc0205eb8 <strnlen>
ffffffffc0205dda:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205dde:	01b05b63          	blez	s11,ffffffffc0205df4 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205de2:	67a2                	ld	a5,8(sp)
ffffffffc0205de4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205de8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205dea:	85a6                	mv	a1,s1
ffffffffc0205dec:	8552                	mv	a0,s4
ffffffffc0205dee:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205df0:	fe0d9ce3          	bnez	s11,ffffffffc0205de8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205df4:	00044783          	lbu	a5,0(s0)
ffffffffc0205df8:	00140a13          	addi	s4,s0,1
ffffffffc0205dfc:	0007851b          	sext.w	a0,a5
ffffffffc0205e00:	d3a5                	beqz	a5,ffffffffc0205d60 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205e02:	05e00413          	li	s0,94
ffffffffc0205e06:	bf39                	j	ffffffffc0205d24 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205e08:	000a2403          	lw	s0,0(s4)
ffffffffc0205e0c:	b7ad                	j	ffffffffc0205d76 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205e0e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205e12:	46a1                	li	a3,8
ffffffffc0205e14:	8a2e                	mv	s4,a1
ffffffffc0205e16:	bdb1                	j	ffffffffc0205c72 <vprintfmt+0x156>
ffffffffc0205e18:	000a6603          	lwu	a2,0(s4)
ffffffffc0205e1c:	46a9                	li	a3,10
ffffffffc0205e1e:	8a2e                	mv	s4,a1
ffffffffc0205e20:	bd89                	j	ffffffffc0205c72 <vprintfmt+0x156>
ffffffffc0205e22:	000a6603          	lwu	a2,0(s4)
ffffffffc0205e26:	46c1                	li	a3,16
ffffffffc0205e28:	8a2e                	mv	s4,a1
ffffffffc0205e2a:	b5a1                	j	ffffffffc0205c72 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205e2c:	9902                	jalr	s2
ffffffffc0205e2e:	bf09                	j	ffffffffc0205d40 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205e30:	85a6                	mv	a1,s1
ffffffffc0205e32:	02d00513          	li	a0,45
ffffffffc0205e36:	e03e                	sd	a5,0(sp)
ffffffffc0205e38:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205e3a:	6782                	ld	a5,0(sp)
ffffffffc0205e3c:	8a66                	mv	s4,s9
ffffffffc0205e3e:	40800633          	neg	a2,s0
ffffffffc0205e42:	46a9                	li	a3,10
ffffffffc0205e44:	b53d                	j	ffffffffc0205c72 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205e46:	03b05163          	blez	s11,ffffffffc0205e68 <vprintfmt+0x34c>
ffffffffc0205e4a:	02d00693          	li	a3,45
ffffffffc0205e4e:	f6d79de3          	bne	a5,a3,ffffffffc0205dc8 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205e52:	00002417          	auipc	s0,0x2
ffffffffc0205e56:	05e40413          	addi	s0,s0,94 # ffffffffc0207eb0 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205e5a:	02800793          	li	a5,40
ffffffffc0205e5e:	02800513          	li	a0,40
ffffffffc0205e62:	00140a13          	addi	s4,s0,1
ffffffffc0205e66:	bd6d                	j	ffffffffc0205d20 <vprintfmt+0x204>
ffffffffc0205e68:	00002a17          	auipc	s4,0x2
ffffffffc0205e6c:	049a0a13          	addi	s4,s4,73 # ffffffffc0207eb1 <syscalls+0x119>
ffffffffc0205e70:	02800513          	li	a0,40
ffffffffc0205e74:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205e78:	05e00413          	li	s0,94
ffffffffc0205e7c:	b565                	j	ffffffffc0205d24 <vprintfmt+0x208>

ffffffffc0205e7e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205e7e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205e80:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205e84:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205e86:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205e88:	ec06                	sd	ra,24(sp)
ffffffffc0205e8a:	f83a                	sd	a4,48(sp)
ffffffffc0205e8c:	fc3e                	sd	a5,56(sp)
ffffffffc0205e8e:	e0c2                	sd	a6,64(sp)
ffffffffc0205e90:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205e92:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205e94:	c89ff0ef          	jal	ra,ffffffffc0205b1c <vprintfmt>
}
ffffffffc0205e98:	60e2                	ld	ra,24(sp)
ffffffffc0205e9a:	6161                	addi	sp,sp,80
ffffffffc0205e9c:	8082                	ret

ffffffffc0205e9e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205e9e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205ea2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205ea4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205ea6:	cb81                	beqz	a5,ffffffffc0205eb6 <strlen+0x18>
        cnt ++;
ffffffffc0205ea8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205eaa:	00a707b3          	add	a5,a4,a0
ffffffffc0205eae:	0007c783          	lbu	a5,0(a5)
ffffffffc0205eb2:	fbfd                	bnez	a5,ffffffffc0205ea8 <strlen+0xa>
ffffffffc0205eb4:	8082                	ret
    }
    return cnt;
}
ffffffffc0205eb6:	8082                	ret

ffffffffc0205eb8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205eb8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205eba:	e589                	bnez	a1,ffffffffc0205ec4 <strnlen+0xc>
ffffffffc0205ebc:	a811                	j	ffffffffc0205ed0 <strnlen+0x18>
        cnt ++;
ffffffffc0205ebe:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205ec0:	00f58863          	beq	a1,a5,ffffffffc0205ed0 <strnlen+0x18>
ffffffffc0205ec4:	00f50733          	add	a4,a0,a5
ffffffffc0205ec8:	00074703          	lbu	a4,0(a4)
ffffffffc0205ecc:	fb6d                	bnez	a4,ffffffffc0205ebe <strnlen+0x6>
ffffffffc0205ece:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205ed0:	852e                	mv	a0,a1
ffffffffc0205ed2:	8082                	ret

ffffffffc0205ed4 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205ed4:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205ed6:	0005c703          	lbu	a4,0(a1)
ffffffffc0205eda:	0785                	addi	a5,a5,1
ffffffffc0205edc:	0585                	addi	a1,a1,1
ffffffffc0205ede:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205ee2:	fb75                	bnez	a4,ffffffffc0205ed6 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205ee4:	8082                	ret

ffffffffc0205ee6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205ee6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205eea:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205eee:	cb89                	beqz	a5,ffffffffc0205f00 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205ef0:	0505                	addi	a0,a0,1
ffffffffc0205ef2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205ef4:	fee789e3          	beq	a5,a4,ffffffffc0205ee6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205ef8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205efc:	9d19                	subw	a0,a0,a4
ffffffffc0205efe:	8082                	ret
ffffffffc0205f00:	4501                	li	a0,0
ffffffffc0205f02:	bfed                	j	ffffffffc0205efc <strcmp+0x16>

ffffffffc0205f04 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205f04:	c20d                	beqz	a2,ffffffffc0205f26 <strncmp+0x22>
ffffffffc0205f06:	962e                	add	a2,a2,a1
ffffffffc0205f08:	a031                	j	ffffffffc0205f14 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205f0a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205f0c:	00e79a63          	bne	a5,a4,ffffffffc0205f20 <strncmp+0x1c>
ffffffffc0205f10:	00b60b63          	beq	a2,a1,ffffffffc0205f26 <strncmp+0x22>
ffffffffc0205f14:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205f18:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205f1a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205f1e:	f7f5                	bnez	a5,ffffffffc0205f0a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205f20:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205f24:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205f26:	4501                	li	a0,0
ffffffffc0205f28:	8082                	ret

ffffffffc0205f2a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205f2a:	00054783          	lbu	a5,0(a0)
ffffffffc0205f2e:	c799                	beqz	a5,ffffffffc0205f3c <strchr+0x12>
        if (*s == c) {
ffffffffc0205f30:	00f58763          	beq	a1,a5,ffffffffc0205f3e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205f34:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205f38:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205f3a:	fbfd                	bnez	a5,ffffffffc0205f30 <strchr+0x6>
    }
    return NULL;
ffffffffc0205f3c:	4501                	li	a0,0
}
ffffffffc0205f3e:	8082                	ret

ffffffffc0205f40 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205f40:	ca01                	beqz	a2,ffffffffc0205f50 <memset+0x10>
ffffffffc0205f42:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205f44:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205f46:	0785                	addi	a5,a5,1
ffffffffc0205f48:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205f4c:	fec79de3          	bne	a5,a2,ffffffffc0205f46 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205f50:	8082                	ret

ffffffffc0205f52 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205f52:	ca19                	beqz	a2,ffffffffc0205f68 <memcpy+0x16>
ffffffffc0205f54:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205f56:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205f58:	0005c703          	lbu	a4,0(a1)
ffffffffc0205f5c:	0585                	addi	a1,a1,1
ffffffffc0205f5e:	0785                	addi	a5,a5,1
ffffffffc0205f60:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205f64:	fec59ae3          	bne	a1,a2,ffffffffc0205f58 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205f68:	8082                	ret
