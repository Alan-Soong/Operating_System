
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
ffffffffc020006c:	687010ef          	jal	ra,ffffffffc0201ef2 <memset>
    dtb_init();
ffffffffc0200070:	438000ef          	jal	ra,ffffffffc02004a8 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	426000ef          	jal	ra,ffffffffc020049a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f2050513          	addi	a0,a0,-224 # ffffffffc0201f98 <etext+0x94>
ffffffffc0200080:	0ba000ef          	jal	ra,ffffffffc020013a <cputs>

    print_kerninfo();
ffffffffc0200084:	106000ef          	jal	ra,ffffffffc020018a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7dc000ef          	jal	ra,ffffffffc0200864 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	6ea010ef          	jal	ra,ffffffffc0201776 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7d4000ef          	jal	ra,ffffffffc0200864 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	3c4000ef          	jal	ra,ffffffffc0200458 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	7c0000ef          	jal	ra,ffffffffc0200858 <intr_enable>
    cprintf("\n=== TRAP TEST: generating illegal instruction ===\n");
ffffffffc020009c:	00002517          	auipc	a0,0x2
ffffffffc02000a0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0201f08 <etext+0x4>
ffffffffc02000a4:	05e000ef          	jal	ra,ffffffffc0200102 <cprintf>
ffffffffc02000a8:	0000                	unimp
ffffffffc02000aa:	0000                	unimp
    cprintf("=== TRAP TEST: generating ebreak ===\n");
ffffffffc02000ac:	00002517          	auipc	a0,0x2
ffffffffc02000b0:	e9450513          	addi	a0,a0,-364 # ffffffffc0201f40 <etext+0x3c>
ffffffffc02000b4:	04e000ef          	jal	ra,ffffffffc0200102 <cprintf>
    asm volatile("ebreak"); /* 触发 CAUSE_BREAKPOINT */
ffffffffc02000b8:	9002                	ebreak
    cprintf("=== TRAP TEST: returned (unexpected) ===\n\n");
ffffffffc02000ba:	00002517          	auipc	a0,0x2
ffffffffc02000be:	eae50513          	addi	a0,a0,-338 # ffffffffc0201f68 <etext+0x64>
ffffffffc02000c2:	040000ef          	jal	ra,ffffffffc0200102 <cprintf>
    #ifdef TRAP_TEST
        lab3_switch_tests();
    #endif

    /* do nothing */
    while (1)
ffffffffc02000c6:	a001                	j	ffffffffc02000c6 <kern_init+0x72>

ffffffffc02000c8 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000c8:	1141                	addi	sp,sp,-16
ffffffffc02000ca:	e022                	sd	s0,0(sp)
ffffffffc02000cc:	e406                	sd	ra,8(sp)
ffffffffc02000ce:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000d0:	3cc000ef          	jal	ra,ffffffffc020049c <cons_putc>
    (*cnt) ++;
ffffffffc02000d4:	401c                	lw	a5,0(s0)
}
ffffffffc02000d6:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000d8:	2785                	addiw	a5,a5,1
ffffffffc02000da:	c01c                	sw	a5,0(s0)
}
ffffffffc02000dc:	6402                	ld	s0,0(sp)
ffffffffc02000de:	0141                	addi	sp,sp,16
ffffffffc02000e0:	8082                	ret

ffffffffc02000e2 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000e2:	1101                	addi	sp,sp,-32
ffffffffc02000e4:	862a                	mv	a2,a0
ffffffffc02000e6:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e8:	00000517          	auipc	a0,0x0
ffffffffc02000ec:	fe050513          	addi	a0,a0,-32 # ffffffffc02000c8 <cputch>
ffffffffc02000f0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000f4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f6:	0cd010ef          	jal	ra,ffffffffc02019c2 <vprintfmt>
    return cnt;
}
ffffffffc02000fa:	60e2                	ld	ra,24(sp)
ffffffffc02000fc:	4532                	lw	a0,12(sp)
ffffffffc02000fe:	6105                	addi	sp,sp,32
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200102:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200104:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200108:	8e2a                	mv	t3,a0
ffffffffc020010a:	f42e                	sd	a1,40(sp)
ffffffffc020010c:	f832                	sd	a2,48(sp)
ffffffffc020010e:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200110:	00000517          	auipc	a0,0x0
ffffffffc0200114:	fb850513          	addi	a0,a0,-72 # ffffffffc02000c8 <cputch>
ffffffffc0200118:	004c                	addi	a1,sp,4
ffffffffc020011a:	869a                	mv	a3,t1
ffffffffc020011c:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020011e:	ec06                	sd	ra,24(sp)
ffffffffc0200120:	e0ba                	sd	a4,64(sp)
ffffffffc0200122:	e4be                	sd	a5,72(sp)
ffffffffc0200124:	e8c2                	sd	a6,80(sp)
ffffffffc0200126:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200128:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020012a:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012c:	097010ef          	jal	ra,ffffffffc02019c2 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200130:	60e2                	ld	ra,24(sp)
ffffffffc0200132:	4512                	lw	a0,4(sp)
ffffffffc0200134:	6125                	addi	sp,sp,96
ffffffffc0200136:	8082                	ret

ffffffffc0200138 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200138:	a695                	j	ffffffffc020049c <cons_putc>

ffffffffc020013a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020013a:	1101                	addi	sp,sp,-32
ffffffffc020013c:	e822                	sd	s0,16(sp)
ffffffffc020013e:	ec06                	sd	ra,24(sp)
ffffffffc0200140:	e426                	sd	s1,8(sp)
ffffffffc0200142:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200144:	00054503          	lbu	a0,0(a0)
ffffffffc0200148:	c51d                	beqz	a0,ffffffffc0200176 <cputs+0x3c>
ffffffffc020014a:	0405                	addi	s0,s0,1
ffffffffc020014c:	4485                	li	s1,1
ffffffffc020014e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200150:	34c000ef          	jal	ra,ffffffffc020049c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200154:	00044503          	lbu	a0,0(s0)
ffffffffc0200158:	008487bb          	addw	a5,s1,s0
ffffffffc020015c:	0405                	addi	s0,s0,1
ffffffffc020015e:	f96d                	bnez	a0,ffffffffc0200150 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200160:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200164:	4529                	li	a0,10
ffffffffc0200166:	336000ef          	jal	ra,ffffffffc020049c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020016a:	60e2                	ld	ra,24(sp)
ffffffffc020016c:	8522                	mv	a0,s0
ffffffffc020016e:	6442                	ld	s0,16(sp)
ffffffffc0200170:	64a2                	ld	s1,8(sp)
ffffffffc0200172:	6105                	addi	sp,sp,32
ffffffffc0200174:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200176:	4405                	li	s0,1
ffffffffc0200178:	b7f5                	j	ffffffffc0200164 <cputs+0x2a>

ffffffffc020017a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020017a:	1141                	addi	sp,sp,-16
ffffffffc020017c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020017e:	326000ef          	jal	ra,ffffffffc02004a4 <cons_getc>
ffffffffc0200182:	dd75                	beqz	a0,ffffffffc020017e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200184:	60a2                	ld	ra,8(sp)
ffffffffc0200186:	0141                	addi	sp,sp,16
ffffffffc0200188:	8082                	ret

ffffffffc020018a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020018a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	e2c50513          	addi	a0,a0,-468 # ffffffffc0201fb8 <etext+0xb4>
void print_kerninfo(void) {
ffffffffc0200194:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200196:	f6dff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020019a:	00000597          	auipc	a1,0x0
ffffffffc020019e:	eba58593          	addi	a1,a1,-326 # ffffffffc0200054 <kern_init>
ffffffffc02001a2:	00002517          	auipc	a0,0x2
ffffffffc02001a6:	e3650513          	addi	a0,a0,-458 # ffffffffc0201fd8 <etext+0xd4>
ffffffffc02001aa:	f59ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001ae:	00002597          	auipc	a1,0x2
ffffffffc02001b2:	d5658593          	addi	a1,a1,-682 # ffffffffc0201f04 <etext>
ffffffffc02001b6:	00002517          	auipc	a0,0x2
ffffffffc02001ba:	e4250513          	addi	a0,a0,-446 # ffffffffc0201ff8 <etext+0xf4>
ffffffffc02001be:	f45ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001c2:	00006597          	auipc	a1,0x6
ffffffffc02001c6:	e6658593          	addi	a1,a1,-410 # ffffffffc0206028 <free_area>
ffffffffc02001ca:	00002517          	auipc	a0,0x2
ffffffffc02001ce:	e4e50513          	addi	a0,a0,-434 # ffffffffc0202018 <etext+0x114>
ffffffffc02001d2:	f31ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001d6:	00006597          	auipc	a1,0x6
ffffffffc02001da:	2ca58593          	addi	a1,a1,714 # ffffffffc02064a0 <end>
ffffffffc02001de:	00002517          	auipc	a0,0x2
ffffffffc02001e2:	e5a50513          	addi	a0,a0,-422 # ffffffffc0202038 <etext+0x134>
ffffffffc02001e6:	f1dff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001ea:	00006597          	auipc	a1,0x6
ffffffffc02001ee:	6b558593          	addi	a1,a1,1717 # ffffffffc020689f <end+0x3ff>
ffffffffc02001f2:	00000797          	auipc	a5,0x0
ffffffffc02001f6:	e6278793          	addi	a5,a5,-414 # ffffffffc0200054 <kern_init>
ffffffffc02001fa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001fe:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200202:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200204:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200208:	95be                	add	a1,a1,a5
ffffffffc020020a:	85a9                	srai	a1,a1,0xa
ffffffffc020020c:	00002517          	auipc	a0,0x2
ffffffffc0200210:	e4c50513          	addi	a0,a0,-436 # ffffffffc0202058 <etext+0x154>
}
ffffffffc0200214:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200216:	b5f5                	j	ffffffffc0200102 <cprintf>

ffffffffc0200218 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200218:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020021a:	00002617          	auipc	a2,0x2
ffffffffc020021e:	e6e60613          	addi	a2,a2,-402 # ffffffffc0202088 <etext+0x184>
ffffffffc0200222:	04d00593          	li	a1,77
ffffffffc0200226:	00002517          	auipc	a0,0x2
ffffffffc020022a:	e7a50513          	addi	a0,a0,-390 # ffffffffc02020a0 <etext+0x19c>
void print_stackframe(void) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200230:	1cc000ef          	jal	ra,ffffffffc02003fc <__panic>

ffffffffc0200234 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200234:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200236:	00002617          	auipc	a2,0x2
ffffffffc020023a:	e8260613          	addi	a2,a2,-382 # ffffffffc02020b8 <etext+0x1b4>
ffffffffc020023e:	00002597          	auipc	a1,0x2
ffffffffc0200242:	e9a58593          	addi	a1,a1,-358 # ffffffffc02020d8 <etext+0x1d4>
ffffffffc0200246:	00002517          	auipc	a0,0x2
ffffffffc020024a:	e9a50513          	addi	a0,a0,-358 # ffffffffc02020e0 <etext+0x1dc>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024e:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200250:	eb3ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
ffffffffc0200254:	00002617          	auipc	a2,0x2
ffffffffc0200258:	e9c60613          	addi	a2,a2,-356 # ffffffffc02020f0 <etext+0x1ec>
ffffffffc020025c:	00002597          	auipc	a1,0x2
ffffffffc0200260:	ebc58593          	addi	a1,a1,-324 # ffffffffc0202118 <etext+0x214>
ffffffffc0200264:	00002517          	auipc	a0,0x2
ffffffffc0200268:	e7c50513          	addi	a0,a0,-388 # ffffffffc02020e0 <etext+0x1dc>
ffffffffc020026c:	e97ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
ffffffffc0200270:	00002617          	auipc	a2,0x2
ffffffffc0200274:	eb860613          	addi	a2,a2,-328 # ffffffffc0202128 <etext+0x224>
ffffffffc0200278:	00002597          	auipc	a1,0x2
ffffffffc020027c:	ed058593          	addi	a1,a1,-304 # ffffffffc0202148 <etext+0x244>
ffffffffc0200280:	00002517          	auipc	a0,0x2
ffffffffc0200284:	e6050513          	addi	a0,a0,-416 # ffffffffc02020e0 <etext+0x1dc>
ffffffffc0200288:	e7bff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    }
    return 0;
}
ffffffffc020028c:	60a2                	ld	ra,8(sp)
ffffffffc020028e:	4501                	li	a0,0
ffffffffc0200290:	0141                	addi	sp,sp,16
ffffffffc0200292:	8082                	ret

ffffffffc0200294 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200294:	1141                	addi	sp,sp,-16
ffffffffc0200296:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200298:	ef3ff0ef          	jal	ra,ffffffffc020018a <print_kerninfo>
    return 0;
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
ffffffffc020029e:	4501                	li	a0,0
ffffffffc02002a0:	0141                	addi	sp,sp,16
ffffffffc02002a2:	8082                	ret

ffffffffc02002a4 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a4:	1141                	addi	sp,sp,-16
ffffffffc02002a6:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002a8:	f71ff0ef          	jal	ra,ffffffffc0200218 <print_stackframe>
    return 0;
}
ffffffffc02002ac:	60a2                	ld	ra,8(sp)
ffffffffc02002ae:	4501                	li	a0,0
ffffffffc02002b0:	0141                	addi	sp,sp,16
ffffffffc02002b2:	8082                	ret

ffffffffc02002b4 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002b4:	7115                	addi	sp,sp,-224
ffffffffc02002b6:	ed5e                	sd	s7,152(sp)
ffffffffc02002b8:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ba:	00002517          	auipc	a0,0x2
ffffffffc02002be:	e9e50513          	addi	a0,a0,-354 # ffffffffc0202158 <etext+0x254>
kmonitor(struct trapframe *tf) {
ffffffffc02002c2:	ed86                	sd	ra,216(sp)
ffffffffc02002c4:	e9a2                	sd	s0,208(sp)
ffffffffc02002c6:	e5a6                	sd	s1,200(sp)
ffffffffc02002c8:	e1ca                	sd	s2,192(sp)
ffffffffc02002ca:	fd4e                	sd	s3,184(sp)
ffffffffc02002cc:	f952                	sd	s4,176(sp)
ffffffffc02002ce:	f556                	sd	s5,168(sp)
ffffffffc02002d0:	f15a                	sd	s6,160(sp)
ffffffffc02002d2:	e962                	sd	s8,144(sp)
ffffffffc02002d4:	e566                	sd	s9,136(sp)
ffffffffc02002d6:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002d8:	e2bff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002dc:	00002517          	auipc	a0,0x2
ffffffffc02002e0:	ea450513          	addi	a0,a0,-348 # ffffffffc0202180 <etext+0x27c>
ffffffffc02002e4:	e1fff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    if (tf != NULL) {
ffffffffc02002e8:	000b8563          	beqz	s7,ffffffffc02002f2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002ec:	855e                	mv	a0,s7
ffffffffc02002ee:	756000ef          	jal	ra,ffffffffc0200a44 <print_trapframe>
ffffffffc02002f2:	00002c17          	auipc	s8,0x2
ffffffffc02002f6:	efec0c13          	addi	s8,s8,-258 # ffffffffc02021f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fa:	00002917          	auipc	s2,0x2
ffffffffc02002fe:	eae90913          	addi	s2,s2,-338 # ffffffffc02021a8 <etext+0x2a4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200302:	00002497          	auipc	s1,0x2
ffffffffc0200306:	eae48493          	addi	s1,s1,-338 # ffffffffc02021b0 <etext+0x2ac>
        if (argc == MAXARGS - 1) {
ffffffffc020030a:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020030c:	00002b17          	auipc	s6,0x2
ffffffffc0200310:	eacb0b13          	addi	s6,s6,-340 # ffffffffc02021b8 <etext+0x2b4>
        argv[argc ++] = buf;
ffffffffc0200314:	00002a17          	auipc	s4,0x2
ffffffffc0200318:	dc4a0a13          	addi	s4,s4,-572 # ffffffffc02020d8 <etext+0x1d4>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031c:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020031e:	854a                	mv	a0,s2
ffffffffc0200320:	225010ef          	jal	ra,ffffffffc0201d44 <readline>
ffffffffc0200324:	842a                	mv	s0,a0
ffffffffc0200326:	dd65                	beqz	a0,ffffffffc020031e <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200328:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020032c:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020032e:	e1bd                	bnez	a1,ffffffffc0200394 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200330:	fe0c87e3          	beqz	s9,ffffffffc020031e <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200334:	6582                	ld	a1,0(sp)
ffffffffc0200336:	00002d17          	auipc	s10,0x2
ffffffffc020033a:	ebad0d13          	addi	s10,s10,-326 # ffffffffc02021f0 <commands>
        argv[argc ++] = buf;
ffffffffc020033e:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200340:	4401                	li	s0,0
ffffffffc0200342:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200344:	355010ef          	jal	ra,ffffffffc0201e98 <strcmp>
ffffffffc0200348:	c919                	beqz	a0,ffffffffc020035e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034a:	2405                	addiw	s0,s0,1
ffffffffc020034c:	0b540063          	beq	s0,s5,ffffffffc02003ec <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200350:	000d3503          	ld	a0,0(s10)
ffffffffc0200354:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200358:	341010ef          	jal	ra,ffffffffc0201e98 <strcmp>
ffffffffc020035c:	f57d                	bnez	a0,ffffffffc020034a <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020035e:	00141793          	slli	a5,s0,0x1
ffffffffc0200362:	97a2                	add	a5,a5,s0
ffffffffc0200364:	078e                	slli	a5,a5,0x3
ffffffffc0200366:	97e2                	add	a5,a5,s8
ffffffffc0200368:	6b9c                	ld	a5,16(a5)
ffffffffc020036a:	865e                	mv	a2,s7
ffffffffc020036c:	002c                	addi	a1,sp,8
ffffffffc020036e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200372:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200374:	fa0555e3          	bgez	a0,ffffffffc020031e <kmonitor+0x6a>
}
ffffffffc0200378:	60ee                	ld	ra,216(sp)
ffffffffc020037a:	644e                	ld	s0,208(sp)
ffffffffc020037c:	64ae                	ld	s1,200(sp)
ffffffffc020037e:	690e                	ld	s2,192(sp)
ffffffffc0200380:	79ea                	ld	s3,184(sp)
ffffffffc0200382:	7a4a                	ld	s4,176(sp)
ffffffffc0200384:	7aaa                	ld	s5,168(sp)
ffffffffc0200386:	7b0a                	ld	s6,160(sp)
ffffffffc0200388:	6bea                	ld	s7,152(sp)
ffffffffc020038a:	6c4a                	ld	s8,144(sp)
ffffffffc020038c:	6caa                	ld	s9,136(sp)
ffffffffc020038e:	6d0a                	ld	s10,128(sp)
ffffffffc0200390:	612d                	addi	sp,sp,224
ffffffffc0200392:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200394:	8526                	mv	a0,s1
ffffffffc0200396:	347010ef          	jal	ra,ffffffffc0201edc <strchr>
ffffffffc020039a:	c901                	beqz	a0,ffffffffc02003aa <kmonitor+0xf6>
ffffffffc020039c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003a0:	00040023          	sb	zero,0(s0)
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a6:	d5c9                	beqz	a1,ffffffffc0200330 <kmonitor+0x7c>
ffffffffc02003a8:	b7f5                	j	ffffffffc0200394 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003aa:	00044783          	lbu	a5,0(s0)
ffffffffc02003ae:	d3c9                	beqz	a5,ffffffffc0200330 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003b0:	033c8963          	beq	s9,s3,ffffffffc02003e2 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003b4:	003c9793          	slli	a5,s9,0x3
ffffffffc02003b8:	0118                	addi	a4,sp,128
ffffffffc02003ba:	97ba                	add	a5,a5,a4
ffffffffc02003bc:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003c0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003c4:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003c6:	e591                	bnez	a1,ffffffffc02003d2 <kmonitor+0x11e>
ffffffffc02003c8:	b7b5                	j	ffffffffc0200334 <kmonitor+0x80>
ffffffffc02003ca:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d0:	d1a5                	beqz	a1,ffffffffc0200330 <kmonitor+0x7c>
ffffffffc02003d2:	8526                	mv	a0,s1
ffffffffc02003d4:	309010ef          	jal	ra,ffffffffc0201edc <strchr>
ffffffffc02003d8:	d96d                	beqz	a0,ffffffffc02003ca <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003da:	00044583          	lbu	a1,0(s0)
ffffffffc02003de:	d9a9                	beqz	a1,ffffffffc0200330 <kmonitor+0x7c>
ffffffffc02003e0:	bf55                	j	ffffffffc0200394 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003e2:	45c1                	li	a1,16
ffffffffc02003e4:	855a                	mv	a0,s6
ffffffffc02003e6:	d1dff0ef          	jal	ra,ffffffffc0200102 <cprintf>
ffffffffc02003ea:	b7e9                	j	ffffffffc02003b4 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003ec:	6582                	ld	a1,0(sp)
ffffffffc02003ee:	00002517          	auipc	a0,0x2
ffffffffc02003f2:	dea50513          	addi	a0,a0,-534 # ffffffffc02021d8 <etext+0x2d4>
ffffffffc02003f6:	d0dff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    return 0;
ffffffffc02003fa:	b715                	j	ffffffffc020031e <kmonitor+0x6a>

ffffffffc02003fc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003fc:	00006317          	auipc	t1,0x6
ffffffffc0200400:	04430313          	addi	t1,t1,68 # ffffffffc0206440 <is_panic>
ffffffffc0200404:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200408:	715d                	addi	sp,sp,-80
ffffffffc020040a:	ec06                	sd	ra,24(sp)
ffffffffc020040c:	e822                	sd	s0,16(sp)
ffffffffc020040e:	f436                	sd	a3,40(sp)
ffffffffc0200410:	f83a                	sd	a4,48(sp)
ffffffffc0200412:	fc3e                	sd	a5,56(sp)
ffffffffc0200414:	e0c2                	sd	a6,64(sp)
ffffffffc0200416:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200418:	020e1a63          	bnez	t3,ffffffffc020044c <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020041c:	4785                	li	a5,1
ffffffffc020041e:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200422:	8432                	mv	s0,a2
ffffffffc0200424:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200426:	862e                	mv	a2,a1
ffffffffc0200428:	85aa                	mv	a1,a0
ffffffffc020042a:	00002517          	auipc	a0,0x2
ffffffffc020042e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202238 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200432:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200434:	ccfff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200438:	65a2                	ld	a1,8(sp)
ffffffffc020043a:	8522                	mv	a0,s0
ffffffffc020043c:	ca7ff0ef          	jal	ra,ffffffffc02000e2 <vcprintf>
    cprintf("\n");
ffffffffc0200440:	00002517          	auipc	a0,0x2
ffffffffc0200444:	c4050513          	addi	a0,a0,-960 # ffffffffc0202080 <etext+0x17c>
ffffffffc0200448:	cbbff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020044c:	412000ef          	jal	ra,ffffffffc020085e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200450:	4501                	li	a0,0
ffffffffc0200452:	e63ff0ef          	jal	ra,ffffffffc02002b4 <kmonitor>
    while (1) {
ffffffffc0200456:	bfed                	j	ffffffffc0200450 <__panic+0x54>

ffffffffc0200458 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200458:	1141                	addi	sp,sp,-16
ffffffffc020045a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020045c:	02000793          	li	a5,32
ffffffffc0200460:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200464:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200468:	67e1                	lui	a5,0x18
ffffffffc020046a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046e:	953e                	add	a0,a0,a5
ffffffffc0200470:	1a3010ef          	jal	ra,ffffffffc0201e12 <sbi_set_timer>
}
ffffffffc0200474:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200476:	00006797          	auipc	a5,0x6
ffffffffc020047a:	fc07b923          	sd	zero,-46(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020047e:	00002517          	auipc	a0,0x2
ffffffffc0200482:	dda50513          	addi	a0,a0,-550 # ffffffffc0202258 <commands+0x68>
}
ffffffffc0200486:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200488:	b9ad                	j	ffffffffc0200102 <cprintf>

ffffffffc020048a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020048a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020048e:	67e1                	lui	a5,0x18
ffffffffc0200490:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200494:	953e                	add	a0,a0,a5
ffffffffc0200496:	17d0106f          	j	ffffffffc0201e12 <sbi_set_timer>

ffffffffc020049a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020049a:	8082                	ret

ffffffffc020049c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020049c:	0ff57513          	zext.b	a0,a0
ffffffffc02004a0:	1590106f          	j	ffffffffc0201df8 <sbi_console_putchar>

ffffffffc02004a4 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004a4:	1890106f          	j	ffffffffc0201e2c <sbi_console_getchar>

ffffffffc02004a8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004a8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	dce50513          	addi	a0,a0,-562 # ffffffffc0202278 <commands+0x88>
void dtb_init(void) {
ffffffffc02004b2:	fc86                	sd	ra,120(sp)
ffffffffc02004b4:	f8a2                	sd	s0,112(sp)
ffffffffc02004b6:	e8d2                	sd	s4,80(sp)
ffffffffc02004b8:	f4a6                	sd	s1,104(sp)
ffffffffc02004ba:	f0ca                	sd	s2,96(sp)
ffffffffc02004bc:	ecce                	sd	s3,88(sp)
ffffffffc02004be:	e4d6                	sd	s5,72(sp)
ffffffffc02004c0:	e0da                	sd	s6,64(sp)
ffffffffc02004c2:	fc5e                	sd	s7,56(sp)
ffffffffc02004c4:	f862                	sd	s8,48(sp)
ffffffffc02004c6:	f466                	sd	s9,40(sp)
ffffffffc02004c8:	f06a                	sd	s10,32(sp)
ffffffffc02004ca:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004cc:	c37ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004d0:	00006597          	auipc	a1,0x6
ffffffffc02004d4:	b305b583          	ld	a1,-1232(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004d8:	00002517          	auipc	a0,0x2
ffffffffc02004dc:	db050513          	addi	a0,a0,-592 # ffffffffc0202288 <commands+0x98>
ffffffffc02004e0:	c23ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004e4:	00006417          	auipc	s0,0x6
ffffffffc02004e8:	b2440413          	addi	s0,s0,-1244 # ffffffffc0206008 <boot_dtb>
ffffffffc02004ec:	600c                	ld	a1,0(s0)
ffffffffc02004ee:	00002517          	auipc	a0,0x2
ffffffffc02004f2:	daa50513          	addi	a0,a0,-598 # ffffffffc0202298 <commands+0xa8>
ffffffffc02004f6:	c0dff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004fa:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	db250513          	addi	a0,a0,-590 # ffffffffc02022b0 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc0200506:	120a0463          	beqz	s4,ffffffffc020062e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020050a:	57f5                	li	a5,-3
ffffffffc020050c:	07fa                	slli	a5,a5,0x1e
ffffffffc020050e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200512:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200514:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200518:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020051e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200530:	8ec9                	or	a3,a3,a0
ffffffffc0200532:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200536:	1b7d                	addi	s6,s6,-1
ffffffffc0200538:	0167f7b3          	and	a5,a5,s6
ffffffffc020053c:	8dd5                	or	a1,a1,a3
ffffffffc020053e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200540:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200544:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200546:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc020054a:	10f59163          	bne	a1,a5,ffffffffc020064c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020054e:	471c                	lw	a5,8(a4)
ffffffffc0200550:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200552:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200554:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200558:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020055c:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200560:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200568:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020056c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200574:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057c:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020057e:	01146433          	or	s0,s0,a7
ffffffffc0200582:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200586:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200590:	8c49                	or	s0,s0,a0
ffffffffc0200592:	0166f6b3          	and	a3,a3,s6
ffffffffc0200596:	00ca6a33          	or	s4,s4,a2
ffffffffc020059a:	0167f7b3          	and	a5,a5,s6
ffffffffc020059e:	8c55                	or	s0,s0,a3
ffffffffc02005a0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005a4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005a6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005a8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005aa:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005ae:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b0:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005b6:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005b8:	00002917          	auipc	s2,0x2
ffffffffc02005bc:	d4890913          	addi	s2,s2,-696 # ffffffffc0202300 <commands+0x110>
ffffffffc02005c0:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005c2:	4d91                	li	s11,4
ffffffffc02005c4:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005c6:	00002497          	auipc	s1,0x2
ffffffffc02005ca:	d3248493          	addi	s1,s1,-718 # ffffffffc02022f8 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005ce:	000a2703          	lw	a4,0(s4)
ffffffffc02005d2:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d6:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005da:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005de:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e6:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005ea:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f0:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005f4:	8fd5                	or	a5,a5,a3
ffffffffc02005f6:	00eb7733          	and	a4,s6,a4
ffffffffc02005fa:	8fd9                	or	a5,a5,a4
ffffffffc02005fc:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005fe:	09778c63          	beq	a5,s7,ffffffffc0200696 <dtb_init+0x1ee>
ffffffffc0200602:	00fbea63          	bltu	s7,a5,ffffffffc0200616 <dtb_init+0x16e>
ffffffffc0200606:	07a78663          	beq	a5,s10,ffffffffc0200672 <dtb_init+0x1ca>
ffffffffc020060a:	4709                	li	a4,2
ffffffffc020060c:	00e79763          	bne	a5,a4,ffffffffc020061a <dtb_init+0x172>
ffffffffc0200610:	4c81                	li	s9,0
ffffffffc0200612:	8a56                	mv	s4,s5
ffffffffc0200614:	bf6d                	j	ffffffffc02005ce <dtb_init+0x126>
ffffffffc0200616:	ffb78ee3          	beq	a5,s11,ffffffffc0200612 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020061a:	00002517          	auipc	a0,0x2
ffffffffc020061e:	d5e50513          	addi	a0,a0,-674 # ffffffffc0202378 <commands+0x188>
ffffffffc0200622:	ae1ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200626:	00002517          	auipc	a0,0x2
ffffffffc020062a:	d8a50513          	addi	a0,a0,-630 # ffffffffc02023b0 <commands+0x1c0>
}
ffffffffc020062e:	7446                	ld	s0,112(sp)
ffffffffc0200630:	70e6                	ld	ra,120(sp)
ffffffffc0200632:	74a6                	ld	s1,104(sp)
ffffffffc0200634:	7906                	ld	s2,96(sp)
ffffffffc0200636:	69e6                	ld	s3,88(sp)
ffffffffc0200638:	6a46                	ld	s4,80(sp)
ffffffffc020063a:	6aa6                	ld	s5,72(sp)
ffffffffc020063c:	6b06                	ld	s6,64(sp)
ffffffffc020063e:	7be2                	ld	s7,56(sp)
ffffffffc0200640:	7c42                	ld	s8,48(sp)
ffffffffc0200642:	7ca2                	ld	s9,40(sp)
ffffffffc0200644:	7d02                	ld	s10,32(sp)
ffffffffc0200646:	6de2                	ld	s11,24(sp)
ffffffffc0200648:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020064a:	bc65                	j	ffffffffc0200102 <cprintf>
}
ffffffffc020064c:	7446                	ld	s0,112(sp)
ffffffffc020064e:	70e6                	ld	ra,120(sp)
ffffffffc0200650:	74a6                	ld	s1,104(sp)
ffffffffc0200652:	7906                	ld	s2,96(sp)
ffffffffc0200654:	69e6                	ld	s3,88(sp)
ffffffffc0200656:	6a46                	ld	s4,80(sp)
ffffffffc0200658:	6aa6                	ld	s5,72(sp)
ffffffffc020065a:	6b06                	ld	s6,64(sp)
ffffffffc020065c:	7be2                	ld	s7,56(sp)
ffffffffc020065e:	7c42                	ld	s8,48(sp)
ffffffffc0200660:	7ca2                	ld	s9,40(sp)
ffffffffc0200662:	7d02                	ld	s10,32(sp)
ffffffffc0200664:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200666:	00002517          	auipc	a0,0x2
ffffffffc020066a:	c6a50513          	addi	a0,a0,-918 # ffffffffc02022d0 <commands+0xe0>
}
ffffffffc020066e:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200670:	bc49                	j	ffffffffc0200102 <cprintf>
                int name_len = strlen(name);
ffffffffc0200672:	8556                	mv	a0,s5
ffffffffc0200674:	7ee010ef          	jal	ra,ffffffffc0201e62 <strlen>
ffffffffc0200678:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020067a:	4619                	li	a2,6
ffffffffc020067c:	85a6                	mv	a1,s1
ffffffffc020067e:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200680:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200682:	035010ef          	jal	ra,ffffffffc0201eb6 <strncmp>
ffffffffc0200686:	e111                	bnez	a0,ffffffffc020068a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200688:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020068a:	0a91                	addi	s5,s5,4
ffffffffc020068c:	9ad2                	add	s5,s5,s4
ffffffffc020068e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200692:	8a56                	mv	s4,s5
ffffffffc0200694:	bf2d                	j	ffffffffc02005ce <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200696:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020069a:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006a2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006b2:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b6:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ba:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006be:	00eaeab3          	or	s5,s5,a4
ffffffffc02006c2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006c6:	00faeab3          	or	s5,s5,a5
ffffffffc02006ca:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006cc:	000c9c63          	bnez	s9,ffffffffc02006e4 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006d0:	1a82                	slli	s5,s5,0x20
ffffffffc02006d2:	00368793          	addi	a5,a3,3
ffffffffc02006d6:	020ada93          	srli	s5,s5,0x20
ffffffffc02006da:	9abe                	add	s5,s5,a5
ffffffffc02006dc:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006e0:	8a56                	mv	s4,s5
ffffffffc02006e2:	b5f5                	j	ffffffffc02005ce <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006e4:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006e8:	85ca                	mv	a1,s2
ffffffffc02006ea:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ec:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f0:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f4:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006f8:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006fc:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200700:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0087979b          	slliw	a5,a5,0x8
ffffffffc020070a:	8d59                	or	a0,a0,a4
ffffffffc020070c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200710:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200712:	1502                	slli	a0,a0,0x20
ffffffffc0200714:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200716:	9522                	add	a0,a0,s0
ffffffffc0200718:	780010ef          	jal	ra,ffffffffc0201e98 <strcmp>
ffffffffc020071c:	66a2                	ld	a3,8(sp)
ffffffffc020071e:	f94d                	bnez	a0,ffffffffc02006d0 <dtb_init+0x228>
ffffffffc0200720:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006d0 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200724:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200728:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202308 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200734:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020073c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200744:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200750:	0187d693          	srli	a3,a5,0x18
ffffffffc0200754:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200758:	0087579b          	srliw	a5,a4,0x8
ffffffffc020075c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200760:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200764:	010f6f33          	or	t5,t5,a6
ffffffffc0200768:	0187529b          	srliw	t0,a4,0x18
ffffffffc020076c:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200774:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200778:	0186f6b3          	and	a3,a3,s8
ffffffffc020077c:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200780:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200788:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	8361                	srli	a4,a4,0x18
ffffffffc020078e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200792:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200796:	01e6e6b3          	or	a3,a3,t5
ffffffffc020079a:	00cb7633          	and	a2,s6,a2
ffffffffc020079e:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007a2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007a6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007aa:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ae:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b2:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007b6:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007ba:	011b78b3          	and	a7,s6,a7
ffffffffc02007be:	005eeeb3          	or	t4,t4,t0
ffffffffc02007c2:	00c6e733          	or	a4,a3,a2
ffffffffc02007c6:	006c6c33          	or	s8,s8,t1
ffffffffc02007ca:	010b76b3          	and	a3,s6,a6
ffffffffc02007ce:	00bb7b33          	and	s6,s6,a1
ffffffffc02007d2:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007d6:	016c6b33          	or	s6,s8,s6
ffffffffc02007da:	01146433          	or	s0,s0,a7
ffffffffc02007de:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007e0:	1702                	slli	a4,a4,0x20
ffffffffc02007e2:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007e4:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007e8:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007ea:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ee:	0167eb33          	or	s6,a5,s6
ffffffffc02007f2:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007f4:	90fff0ef          	jal	ra,ffffffffc0200102 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007f8:	85a2                	mv	a1,s0
ffffffffc02007fa:	00002517          	auipc	a0,0x2
ffffffffc02007fe:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0202328 <commands+0x138>
ffffffffc0200802:	901ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200806:	014b5613          	srli	a2,s6,0x14
ffffffffc020080a:	85da                	mv	a1,s6
ffffffffc020080c:	00002517          	auipc	a0,0x2
ffffffffc0200810:	b3450513          	addi	a0,a0,-1228 # ffffffffc0202340 <commands+0x150>
ffffffffc0200814:	8efff0ef          	jal	ra,ffffffffc0200102 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200818:	008b05b3          	add	a1,s6,s0
ffffffffc020081c:	15fd                	addi	a1,a1,-1
ffffffffc020081e:	00002517          	auipc	a0,0x2
ffffffffc0200822:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202360 <commands+0x170>
ffffffffc0200826:	8ddff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020082a:	00002517          	auipc	a0,0x2
ffffffffc020082e:	b8650513          	addi	a0,a0,-1146 # ffffffffc02023b0 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200832:	00006797          	auipc	a5,0x6
ffffffffc0200836:	c087bf23          	sd	s0,-994(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc020083a:	00006797          	auipc	a5,0x6
ffffffffc020083e:	c167bf23          	sd	s6,-994(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200842:	b3f5                	j	ffffffffc020062e <dtb_init+0x186>

ffffffffc0200844 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200844:	00006517          	auipc	a0,0x6
ffffffffc0200848:	c0c53503          	ld	a0,-1012(a0) # ffffffffc0206450 <memory_base>
ffffffffc020084c:	8082                	ret

ffffffffc020084e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020084e:	00006517          	auipc	a0,0x6
ffffffffc0200852:	c0a53503          	ld	a0,-1014(a0) # ffffffffc0206458 <memory_size>
ffffffffc0200856:	8082                	ret

ffffffffc0200858 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200858:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020085c:	8082                	ret

ffffffffc020085e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020085e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200864:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200868:	00000797          	auipc	a5,0x0
ffffffffc020086c:	39478793          	addi	a5,a5,916 # ffffffffc0200bfc <__alltraps>
ffffffffc0200870:	10579073          	csrw	stvec,a5
}
ffffffffc0200874:	8082                	ret

ffffffffc0200876 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200876:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200878:	1141                	addi	sp,sp,-16
ffffffffc020087a:	e022                	sd	s0,0(sp)
ffffffffc020087c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020087e:	00002517          	auipc	a0,0x2
ffffffffc0200882:	b4a50513          	addi	a0,a0,-1206 # ffffffffc02023c8 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200886:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200888:	87bff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020088c:	640c                	ld	a1,8(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	b5250513          	addi	a0,a0,-1198 # ffffffffc02023e0 <commands+0x1f0>
ffffffffc0200896:	86dff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020089a:	680c                	ld	a1,16(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02023f8 <commands+0x208>
ffffffffc02008a4:	85fff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008a8:	6c0c                	ld	a1,24(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	b6650513          	addi	a0,a0,-1178 # ffffffffc0202410 <commands+0x220>
ffffffffc02008b2:	851ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008b6:	700c                	ld	a1,32(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0202428 <commands+0x238>
ffffffffc02008c0:	843ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008c4:	740c                	ld	a1,40(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0202440 <commands+0x250>
ffffffffc02008ce:	835ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008d2:	780c                	ld	a1,48(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	b8450513          	addi	a0,a0,-1148 # ffffffffc0202458 <commands+0x268>
ffffffffc02008dc:	827ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008e0:	7c0c                	ld	a1,56(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0202470 <commands+0x280>
ffffffffc02008ea:	819ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008ee:	602c                	ld	a1,64(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	b9850513          	addi	a0,a0,-1128 # ffffffffc0202488 <commands+0x298>
ffffffffc02008f8:	80bff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008fc:	642c                	ld	a1,72(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	ba250513          	addi	a0,a0,-1118 # ffffffffc02024a0 <commands+0x2b0>
ffffffffc0200906:	ffcff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020090a:	682c                	ld	a1,80(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	bac50513          	addi	a0,a0,-1108 # ffffffffc02024b8 <commands+0x2c8>
ffffffffc0200914:	feeff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200918:	6c2c                	ld	a1,88(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	bb650513          	addi	a0,a0,-1098 # ffffffffc02024d0 <commands+0x2e0>
ffffffffc0200922:	fe0ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200926:	702c                	ld	a1,96(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	bc050513          	addi	a0,a0,-1088 # ffffffffc02024e8 <commands+0x2f8>
ffffffffc0200930:	fd2ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200934:	742c                	ld	a1,104(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	bca50513          	addi	a0,a0,-1078 # ffffffffc0202500 <commands+0x310>
ffffffffc020093e:	fc4ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200942:	782c                	ld	a1,112(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	bd450513          	addi	a0,a0,-1068 # ffffffffc0202518 <commands+0x328>
ffffffffc020094c:	fb6ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200950:	7c2c                	ld	a1,120(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	bde50513          	addi	a0,a0,-1058 # ffffffffc0202530 <commands+0x340>
ffffffffc020095a:	fa8ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020095e:	604c                	ld	a1,128(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	be850513          	addi	a0,a0,-1048 # ffffffffc0202548 <commands+0x358>
ffffffffc0200968:	f9aff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020096c:	644c                	ld	a1,136(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	bf250513          	addi	a0,a0,-1038 # ffffffffc0202560 <commands+0x370>
ffffffffc0200976:	f8cff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020097a:	684c                	ld	a1,144(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0202578 <commands+0x388>
ffffffffc0200984:	f7eff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200988:	6c4c                	ld	a1,152(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202590 <commands+0x3a0>
ffffffffc0200992:	f70ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200996:	704c                	ld	a1,160(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	c1050513          	addi	a0,a0,-1008 # ffffffffc02025a8 <commands+0x3b8>
ffffffffc02009a0:	f62ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009a4:	744c                	ld	a1,168(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	c1a50513          	addi	a0,a0,-998 # ffffffffc02025c0 <commands+0x3d0>
ffffffffc02009ae:	f54ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009b2:	784c                	ld	a1,176(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	c2450513          	addi	a0,a0,-988 # ffffffffc02025d8 <commands+0x3e8>
ffffffffc02009bc:	f46ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009c0:	7c4c                	ld	a1,184(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	c2e50513          	addi	a0,a0,-978 # ffffffffc02025f0 <commands+0x400>
ffffffffc02009ca:	f38ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ce:	606c                	ld	a1,192(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	c3850513          	addi	a0,a0,-968 # ffffffffc0202608 <commands+0x418>
ffffffffc02009d8:	f2aff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009dc:	646c                	ld	a1,200(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	c4250513          	addi	a0,a0,-958 # ffffffffc0202620 <commands+0x430>
ffffffffc02009e6:	f1cff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009ea:	686c                	ld	a1,208(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202638 <commands+0x448>
ffffffffc02009f4:	f0eff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009f8:	6c6c                	ld	a1,216(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	c5650513          	addi	a0,a0,-938 # ffffffffc0202650 <commands+0x460>
ffffffffc0200a02:	f00ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a06:	706c                	ld	a1,224(s0)
ffffffffc0200a08:	00002517          	auipc	a0,0x2
ffffffffc0200a0c:	c6050513          	addi	a0,a0,-928 # ffffffffc0202668 <commands+0x478>
ffffffffc0200a10:	ef2ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a14:	746c                	ld	a1,232(s0)
ffffffffc0200a16:	00002517          	auipc	a0,0x2
ffffffffc0200a1a:	c6a50513          	addi	a0,a0,-918 # ffffffffc0202680 <commands+0x490>
ffffffffc0200a1e:	ee4ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a22:	786c                	ld	a1,240(s0)
ffffffffc0200a24:	00002517          	auipc	a0,0x2
ffffffffc0200a28:	c7450513          	addi	a0,a0,-908 # ffffffffc0202698 <commands+0x4a8>
ffffffffc0200a2c:	ed6ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a30:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a32:	6402                	ld	s0,0(sp)
ffffffffc0200a34:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a36:	00002517          	auipc	a0,0x2
ffffffffc0200a3a:	c7a50513          	addi	a0,a0,-902 # ffffffffc02026b0 <commands+0x4c0>
}
ffffffffc0200a3e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a40:	ec2ff06f          	j	ffffffffc0200102 <cprintf>

ffffffffc0200a44 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a44:	1141                	addi	sp,sp,-16
ffffffffc0200a46:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a48:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a4a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	c7c50513          	addi	a0,a0,-900 # ffffffffc02026c8 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a54:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a56:	eacff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a5a:	8522                	mv	a0,s0
ffffffffc0200a5c:	e1bff0ef          	jal	ra,ffffffffc0200876 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a60:	10043583          	ld	a1,256(s0)
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	c7c50513          	addi	a0,a0,-900 # ffffffffc02026e0 <commands+0x4f0>
ffffffffc0200a6c:	e96ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a70:	10843583          	ld	a1,264(s0)
ffffffffc0200a74:	00002517          	auipc	a0,0x2
ffffffffc0200a78:	c8450513          	addi	a0,a0,-892 # ffffffffc02026f8 <commands+0x508>
ffffffffc0200a7c:	e86ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a80:	11043583          	ld	a1,272(s0)
ffffffffc0200a84:	00002517          	auipc	a0,0x2
ffffffffc0200a88:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202710 <commands+0x520>
ffffffffc0200a8c:	e76ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a90:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a94:	6402                	ld	s0,0(sp)
ffffffffc0200a96:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a98:	00002517          	auipc	a0,0x2
ffffffffc0200a9c:	c9050513          	addi	a0,a0,-880 # ffffffffc0202728 <commands+0x538>
}
ffffffffc0200aa0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aa2:	e60ff06f          	j	ffffffffc0200102 <cprintf>

ffffffffc0200aa6 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200aa6:	11853783          	ld	a5,280(a0)
ffffffffc0200aaa:	472d                	li	a4,11
ffffffffc0200aac:	0786                	slli	a5,a5,0x1
ffffffffc0200aae:	8385                	srli	a5,a5,0x1
ffffffffc0200ab0:	08f76263          	bltu	a4,a5,ffffffffc0200b34 <interrupt_handler+0x8e>
ffffffffc0200ab4:	00002717          	auipc	a4,0x2
ffffffffc0200ab8:	d5470713          	addi	a4,a4,-684 # ffffffffc0202808 <commands+0x618>
ffffffffc0200abc:	078a                	slli	a5,a5,0x2
ffffffffc0200abe:	97ba                	add	a5,a5,a4
ffffffffc0200ac0:	439c                	lw	a5,0(a5)
ffffffffc0200ac2:	97ba                	add	a5,a5,a4
ffffffffc0200ac4:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200ac6:	00002517          	auipc	a0,0x2
ffffffffc0200aca:	cda50513          	addi	a0,a0,-806 # ffffffffc02027a0 <commands+0x5b0>
ffffffffc0200ace:	e34ff06f          	j	ffffffffc0200102 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ad2:	00002517          	auipc	a0,0x2
ffffffffc0200ad6:	cae50513          	addi	a0,a0,-850 # ffffffffc0202780 <commands+0x590>
ffffffffc0200ada:	e28ff06f          	j	ffffffffc0200102 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ade:	00002517          	auipc	a0,0x2
ffffffffc0200ae2:	c6250513          	addi	a0,a0,-926 # ffffffffc0202740 <commands+0x550>
ffffffffc0200ae6:	e1cff06f          	j	ffffffffc0200102 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	cd650513          	addi	a0,a0,-810 # ffffffffc02027c0 <commands+0x5d0>
ffffffffc0200af2:	e10ff06f          	j	ffffffffc0200102 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200af6:	1141                	addi	sp,sp,-16
ffffffffc0200af8:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200afa:	991ff0ef          	jal	ra,ffffffffc020048a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200afe:	00006697          	auipc	a3,0x6
ffffffffc0200b02:	94a68693          	addi	a3,a3,-1718 # ffffffffc0206448 <ticks>
ffffffffc0200b06:	629c                	ld	a5,0(a3)
ffffffffc0200b08:	06400713          	li	a4,100
ffffffffc0200b0c:	0785                	addi	a5,a5,1
ffffffffc0200b0e:	02e7f733          	remu	a4,a5,a4
ffffffffc0200b12:	e29c                	sd	a5,0(a3)
ffffffffc0200b14:	c30d                	beqz	a4,ffffffffc0200b36 <interrupt_handler+0x90>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b16:	60a2                	ld	ra,8(sp)
ffffffffc0200b18:	0141                	addi	sp,sp,16
ffffffffc0200b1a:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b1c:	00002517          	auipc	a0,0x2
ffffffffc0200b20:	ccc50513          	addi	a0,a0,-820 # ffffffffc02027e8 <commands+0x5f8>
ffffffffc0200b24:	ddeff06f          	j	ffffffffc0200102 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b28:	00002517          	auipc	a0,0x2
ffffffffc0200b2c:	c3850513          	addi	a0,a0,-968 # ffffffffc0202760 <commands+0x570>
ffffffffc0200b30:	dd2ff06f          	j	ffffffffc0200102 <cprintf>
            print_trapframe(tf);
ffffffffc0200b34:	bf01                	j	ffffffffc0200a44 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b36:	06400593          	li	a1,100
ffffffffc0200b3a:	00002517          	auipc	a0,0x2
ffffffffc0200b3e:	c9e50513          	addi	a0,a0,-866 # ffffffffc02027d8 <commands+0x5e8>
ffffffffc0200b42:	dc0ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
                print_count++;
ffffffffc0200b46:	00006717          	auipc	a4,0x6
ffffffffc0200b4a:	91a70713          	addi	a4,a4,-1766 # ffffffffc0206460 <print_count.0>
ffffffffc0200b4e:	431c                	lw	a5,0(a4)
                if (print_count == 10) {
ffffffffc0200b50:	46a9                	li	a3,10
                print_count++;
ffffffffc0200b52:	0017861b          	addiw	a2,a5,1
ffffffffc0200b56:	c310                	sw	a2,0(a4)
                if (print_count == 10) {
ffffffffc0200b58:	fad61fe3          	bne	a2,a3,ffffffffc0200b16 <interrupt_handler+0x70>
}
ffffffffc0200b5c:	60a2                	ld	ra,8(sp)
ffffffffc0200b5e:	0141                	addi	sp,sp,16
                    sbi_shutdown(); // 关机
ffffffffc0200b60:	2e80106f          	j	ffffffffc0201e48 <sbi_shutdown>

ffffffffc0200b64 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b64:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b68:	1141                	addi	sp,sp,-16
ffffffffc0200b6a:	e022                	sd	s0,0(sp)
ffffffffc0200b6c:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b6e:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b70:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b72:	04e78763          	beq	a5,a4,ffffffffc0200bc0 <exception_handler+0x5c>
ffffffffc0200b76:	02f76d63          	bltu	a4,a5,ffffffffc0200bb0 <exception_handler+0x4c>
ffffffffc0200b7a:	4709                	li	a4,2
ffffffffc0200b7c:	02e79663          	bne	a5,a4,ffffffffc0200ba8 <exception_handler+0x44>
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            // 非法指令异常处理
            // LAB3 CHALLENGE3   YOUR CODE : 2311095
            cprintf("Illegal instruction caught at 0x%08x, epc = 0x%lx\n", tf->epc, tf->epc); // (1)
ffffffffc0200b80:	10843603          	ld	a2,264(s0)
ffffffffc0200b84:	00002517          	auipc	a0,0x2
ffffffffc0200b88:	cb450513          	addi	a0,a0,-844 # ffffffffc0202838 <commands+0x648>
ffffffffc0200b8c:	85b2                	mv	a1,a2
ffffffffc0200b8e:	d74ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
            cprintf("Exception type:Illegal instruction\n"); // (2)
ffffffffc0200b92:	00002517          	auipc	a0,0x2
ffffffffc0200b96:	cde50513          	addi	a0,a0,-802 # ffffffffc0202870 <commands+0x680>
ffffffffc0200b9a:	d68ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200b9e:	10843783          	ld	a5,264(s0)
ffffffffc0200ba2:	0791                	addi	a5,a5,4
ffffffffc0200ba4:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ba8:	60a2                	ld	ra,8(sp)
ffffffffc0200baa:	6402                	ld	s0,0(sp)
ffffffffc0200bac:	0141                	addi	sp,sp,16
ffffffffc0200bae:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bb0:	17f1                	addi	a5,a5,-4
ffffffffc0200bb2:	471d                	li	a4,7
ffffffffc0200bb4:	fef77ae3          	bgeu	a4,a5,ffffffffc0200ba8 <exception_handler+0x44>
}
ffffffffc0200bb8:	6402                	ld	s0,0(sp)
ffffffffc0200bba:	60a2                	ld	ra,8(sp)
ffffffffc0200bbc:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200bbe:	b559                	j	ffffffffc0200a44 <print_trapframe>
            cprintf("eBreak caught at 0x%08x, epc = 0x%lx\n", tf->epc, tf->epc); // (1)
ffffffffc0200bc0:	10843603          	ld	a2,264(s0)
ffffffffc0200bc4:	00002517          	auipc	a0,0x2
ffffffffc0200bc8:	cd450513          	addi	a0,a0,-812 # ffffffffc0202898 <commands+0x6a8>
ffffffffc0200bcc:	85b2                	mv	a1,a2
ffffffffc0200bce:	d34ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
            cprintf("Exception type:Breakpoint\n"); // (2)
ffffffffc0200bd2:	00002517          	auipc	a0,0x2
ffffffffc0200bd6:	cee50513          	addi	a0,a0,-786 # ffffffffc02028c0 <commands+0x6d0>
ffffffffc0200bda:	d28ff0ef          	jal	ra,ffffffffc0200102 <cprintf>
            tf->epc += 2; // (3) 指向下一条指令，防止死循环
ffffffffc0200bde:	10843783          	ld	a5,264(s0)
}
ffffffffc0200be2:	60a2                	ld	ra,8(sp)
            tf->epc += 2; // (3) 指向下一条指令，防止死循环
ffffffffc0200be4:	0789                	addi	a5,a5,2
ffffffffc0200be6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200bea:	6402                	ld	s0,0(sp)
ffffffffc0200bec:	0141                	addi	sp,sp,16
ffffffffc0200bee:	8082                	ret

ffffffffc0200bf0 <trap>:


static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bf0:	11853783          	ld	a5,280(a0)
ffffffffc0200bf4:	0007c363          	bltz	a5,ffffffffc0200bfa <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bf8:	b7b5                	j	ffffffffc0200b64 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bfa:	b575                	j	ffffffffc0200aa6 <interrupt_handler>

ffffffffc0200bfc <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200bfc:	14011073          	csrw	sscratch,sp
ffffffffc0200c00:	712d                	addi	sp,sp,-288
ffffffffc0200c02:	e002                	sd	zero,0(sp)
ffffffffc0200c04:	e406                	sd	ra,8(sp)
ffffffffc0200c06:	ec0e                	sd	gp,24(sp)
ffffffffc0200c08:	f012                	sd	tp,32(sp)
ffffffffc0200c0a:	f416                	sd	t0,40(sp)
ffffffffc0200c0c:	f81a                	sd	t1,48(sp)
ffffffffc0200c0e:	fc1e                	sd	t2,56(sp)
ffffffffc0200c10:	e0a2                	sd	s0,64(sp)
ffffffffc0200c12:	e4a6                	sd	s1,72(sp)
ffffffffc0200c14:	e8aa                	sd	a0,80(sp)
ffffffffc0200c16:	ecae                	sd	a1,88(sp)
ffffffffc0200c18:	f0b2                	sd	a2,96(sp)
ffffffffc0200c1a:	f4b6                	sd	a3,104(sp)
ffffffffc0200c1c:	f8ba                	sd	a4,112(sp)
ffffffffc0200c1e:	fcbe                	sd	a5,120(sp)
ffffffffc0200c20:	e142                	sd	a6,128(sp)
ffffffffc0200c22:	e546                	sd	a7,136(sp)
ffffffffc0200c24:	e94a                	sd	s2,144(sp)
ffffffffc0200c26:	ed4e                	sd	s3,152(sp)
ffffffffc0200c28:	f152                	sd	s4,160(sp)
ffffffffc0200c2a:	f556                	sd	s5,168(sp)
ffffffffc0200c2c:	f95a                	sd	s6,176(sp)
ffffffffc0200c2e:	fd5e                	sd	s7,184(sp)
ffffffffc0200c30:	e1e2                	sd	s8,192(sp)
ffffffffc0200c32:	e5e6                	sd	s9,200(sp)
ffffffffc0200c34:	e9ea                	sd	s10,208(sp)
ffffffffc0200c36:	edee                	sd	s11,216(sp)
ffffffffc0200c38:	f1f2                	sd	t3,224(sp)
ffffffffc0200c3a:	f5f6                	sd	t4,232(sp)
ffffffffc0200c3c:	f9fa                	sd	t5,240(sp)
ffffffffc0200c3e:	fdfe                	sd	t6,248(sp)
ffffffffc0200c40:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c44:	100024f3          	csrr	s1,sstatus
ffffffffc0200c48:	14102973          	csrr	s2,sepc
ffffffffc0200c4c:	143029f3          	csrr	s3,stval
ffffffffc0200c50:	14202a73          	csrr	s4,scause
ffffffffc0200c54:	e822                	sd	s0,16(sp)
ffffffffc0200c56:	e226                	sd	s1,256(sp)
ffffffffc0200c58:	e64a                	sd	s2,264(sp)
ffffffffc0200c5a:	ea4e                	sd	s3,272(sp)
ffffffffc0200c5c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c5e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c60:	f91ff0ef          	jal	ra,ffffffffc0200bf0 <trap>

ffffffffc0200c64 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c64:	6492                	ld	s1,256(sp)
ffffffffc0200c66:	6932                	ld	s2,264(sp)
ffffffffc0200c68:	10049073          	csrw	sstatus,s1
ffffffffc0200c6c:	14191073          	csrw	sepc,s2
ffffffffc0200c70:	60a2                	ld	ra,8(sp)
ffffffffc0200c72:	61e2                	ld	gp,24(sp)
ffffffffc0200c74:	7202                	ld	tp,32(sp)
ffffffffc0200c76:	72a2                	ld	t0,40(sp)
ffffffffc0200c78:	7342                	ld	t1,48(sp)
ffffffffc0200c7a:	73e2                	ld	t2,56(sp)
ffffffffc0200c7c:	6406                	ld	s0,64(sp)
ffffffffc0200c7e:	64a6                	ld	s1,72(sp)
ffffffffc0200c80:	6546                	ld	a0,80(sp)
ffffffffc0200c82:	65e6                	ld	a1,88(sp)
ffffffffc0200c84:	7606                	ld	a2,96(sp)
ffffffffc0200c86:	76a6                	ld	a3,104(sp)
ffffffffc0200c88:	7746                	ld	a4,112(sp)
ffffffffc0200c8a:	77e6                	ld	a5,120(sp)
ffffffffc0200c8c:	680a                	ld	a6,128(sp)
ffffffffc0200c8e:	68aa                	ld	a7,136(sp)
ffffffffc0200c90:	694a                	ld	s2,144(sp)
ffffffffc0200c92:	69ea                	ld	s3,152(sp)
ffffffffc0200c94:	7a0a                	ld	s4,160(sp)
ffffffffc0200c96:	7aaa                	ld	s5,168(sp)
ffffffffc0200c98:	7b4a                	ld	s6,176(sp)
ffffffffc0200c9a:	7bea                	ld	s7,184(sp)
ffffffffc0200c9c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c9e:	6cae                	ld	s9,200(sp)
ffffffffc0200ca0:	6d4e                	ld	s10,208(sp)
ffffffffc0200ca2:	6dee                	ld	s11,216(sp)
ffffffffc0200ca4:	7e0e                	ld	t3,224(sp)
ffffffffc0200ca6:	7eae                	ld	t4,232(sp)
ffffffffc0200ca8:	7f4e                	ld	t5,240(sp)
ffffffffc0200caa:	7fee                	ld	t6,248(sp)
ffffffffc0200cac:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200cae:	10200073          	sret

ffffffffc0200cb2 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200cb2:	00005797          	auipc	a5,0x5
ffffffffc0200cb6:	37678793          	addi	a5,a5,886 # ffffffffc0206028 <free_area>
ffffffffc0200cba:	e79c                	sd	a5,8(a5)
ffffffffc0200cbc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200cbe:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200cc2:	8082                	ret

ffffffffc0200cc4 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cc4:	00005517          	auipc	a0,0x5
ffffffffc0200cc8:	37456503          	lwu	a0,884(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200ccc:	8082                	ret

ffffffffc0200cce <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200cce:	c14d                	beqz	a0,ffffffffc0200d70 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200cd0:	00005617          	auipc	a2,0x5
ffffffffc0200cd4:	35860613          	addi	a2,a2,856 # ffffffffc0206028 <free_area>
ffffffffc0200cd8:	01062803          	lw	a6,16(a2)
ffffffffc0200cdc:	86aa                	mv	a3,a0
ffffffffc0200cde:	02081793          	slli	a5,a6,0x20
ffffffffc0200ce2:	9381                	srli	a5,a5,0x20
ffffffffc0200ce4:	08a7e463          	bltu	a5,a0,ffffffffc0200d6c <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ce8:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200cea:	0018059b          	addiw	a1,a6,1
ffffffffc0200cee:	1582                	slli	a1,a1,0x20
ffffffffc0200cf0:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200cf2:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cf4:	06c78b63          	beq	a5,a2,ffffffffc0200d6a <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200cf8:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200cfc:	00d76763          	bltu	a4,a3,ffffffffc0200d0a <best_fit_alloc_pages+0x3c>
ffffffffc0200d00:	00b77563          	bgeu	a4,a1,ffffffffc0200d0a <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200d04:	fe878513          	addi	a0,a5,-24
ffffffffc0200d08:	85ba                	mv	a1,a4
ffffffffc0200d0a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d0c:	fec796e3          	bne	a5,a2,ffffffffc0200cf8 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200d10:	cd29                	beqz	a0,ffffffffc0200d6a <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d12:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200d14:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200d16:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200d18:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d1c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200d1e:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200d20:	02059793          	slli	a5,a1,0x20
ffffffffc0200d24:	9381                	srli	a5,a5,0x20
ffffffffc0200d26:	02f6f863          	bgeu	a3,a5,ffffffffc0200d56 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200d2a:	00269793          	slli	a5,a3,0x2
ffffffffc0200d2e:	97b6                	add	a5,a5,a3
ffffffffc0200d30:	078e                	slli	a5,a5,0x3
ffffffffc0200d32:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200d34:	411585bb          	subw	a1,a1,a7
ffffffffc0200d38:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d3a:	4689                	li	a3,2
ffffffffc0200d3c:	00878593          	addi	a1,a5,8
ffffffffc0200d40:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d44:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200d46:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200d4a:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200d4e:	e28c                	sd	a1,0(a3)
ffffffffc0200d50:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200d52:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200d54:	ef98                	sd	a4,24(a5)
ffffffffc0200d56:	4118083b          	subw	a6,a6,a7
ffffffffc0200d5a:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200d5e:	57f5                	li	a5,-3
ffffffffc0200d60:	00850713          	addi	a4,a0,8
ffffffffc0200d64:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200d68:	8082                	ret
}
ffffffffc0200d6a:	8082                	ret
        return NULL;
ffffffffc0200d6c:	4501                	li	a0,0
ffffffffc0200d6e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200d70:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200d72:	00002697          	auipc	a3,0x2
ffffffffc0200d76:	b6e68693          	addi	a3,a3,-1170 # ffffffffc02028e0 <commands+0x6f0>
ffffffffc0200d7a:	00002617          	auipc	a2,0x2
ffffffffc0200d7e:	b6e60613          	addi	a2,a2,-1170 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0200d82:	06b00593          	li	a1,107
ffffffffc0200d86:	00002517          	auipc	a0,0x2
ffffffffc0200d8a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0202900 <commands+0x710>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d8e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d90:	e6cff0ef          	jal	ra,ffffffffc02003fc <__panic>

ffffffffc0200d94 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200d94:	715d                	addi	sp,sp,-80
ffffffffc0200d96:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200d98:	00005417          	auipc	s0,0x5
ffffffffc0200d9c:	29040413          	addi	s0,s0,656 # ffffffffc0206028 <free_area>
ffffffffc0200da0:	641c                	ld	a5,8(s0)
ffffffffc0200da2:	e486                	sd	ra,72(sp)
ffffffffc0200da4:	fc26                	sd	s1,56(sp)
ffffffffc0200da6:	f84a                	sd	s2,48(sp)
ffffffffc0200da8:	f44e                	sd	s3,40(sp)
ffffffffc0200daa:	f052                	sd	s4,32(sp)
ffffffffc0200dac:	ec56                	sd	s5,24(sp)
ffffffffc0200dae:	e85a                	sd	s6,16(sp)
ffffffffc0200db0:	e45e                	sd	s7,8(sp)
ffffffffc0200db2:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200db4:	26878b63          	beq	a5,s0,ffffffffc020102a <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200db8:	4481                	li	s1,0
ffffffffc0200dba:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200dbc:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200dc0:	8b09                	andi	a4,a4,2
ffffffffc0200dc2:	26070863          	beqz	a4,ffffffffc0201032 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200dc6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200dca:	679c                	ld	a5,8(a5)
ffffffffc0200dcc:	2905                	addiw	s2,s2,1
ffffffffc0200dce:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dd0:	fe8796e3          	bne	a5,s0,ffffffffc0200dbc <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200dd4:	89a6                	mv	s3,s1
ffffffffc0200dd6:	167000ef          	jal	ra,ffffffffc020173c <nr_free_pages>
ffffffffc0200dda:	33351c63          	bne	a0,s3,ffffffffc0201112 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dde:	4505                	li	a0,1
ffffffffc0200de0:	0df000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200de4:	8a2a                	mv	s4,a0
ffffffffc0200de6:	36050663          	beqz	a0,ffffffffc0201152 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dea:	4505                	li	a0,1
ffffffffc0200dec:	0d3000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200df0:	89aa                	mv	s3,a0
ffffffffc0200df2:	34050063          	beqz	a0,ffffffffc0201132 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200df6:	4505                	li	a0,1
ffffffffc0200df8:	0c7000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200dfc:	8aaa                	mv	s5,a0
ffffffffc0200dfe:	2c050a63          	beqz	a0,ffffffffc02010d2 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e02:	253a0863          	beq	s4,s3,ffffffffc0201052 <best_fit_check+0x2be>
ffffffffc0200e06:	24aa0663          	beq	s4,a0,ffffffffc0201052 <best_fit_check+0x2be>
ffffffffc0200e0a:	24a98463          	beq	s3,a0,ffffffffc0201052 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e0e:	000a2783          	lw	a5,0(s4)
ffffffffc0200e12:	26079063          	bnez	a5,ffffffffc0201072 <best_fit_check+0x2de>
ffffffffc0200e16:	0009a783          	lw	a5,0(s3)
ffffffffc0200e1a:	24079c63          	bnez	a5,ffffffffc0201072 <best_fit_check+0x2de>
ffffffffc0200e1e:	411c                	lw	a5,0(a0)
ffffffffc0200e20:	24079963          	bnez	a5,ffffffffc0201072 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e24:	00005797          	auipc	a5,0x5
ffffffffc0200e28:	64c7b783          	ld	a5,1612(a5) # ffffffffc0206470 <pages>
ffffffffc0200e2c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e30:	870d                	srai	a4,a4,0x3
ffffffffc0200e32:	00002597          	auipc	a1,0x2
ffffffffc0200e36:	1be5b583          	ld	a1,446(a1) # ffffffffc0202ff0 <error_string+0x38>
ffffffffc0200e3a:	02b70733          	mul	a4,a4,a1
ffffffffc0200e3e:	00002617          	auipc	a2,0x2
ffffffffc0200e42:	1ba63603          	ld	a2,442(a2) # ffffffffc0202ff8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e46:	00005697          	auipc	a3,0x5
ffffffffc0200e4a:	6226b683          	ld	a3,1570(a3) # ffffffffc0206468 <npage>
ffffffffc0200e4e:	06b2                	slli	a3,a3,0xc
ffffffffc0200e50:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e52:	0732                	slli	a4,a4,0xc
ffffffffc0200e54:	22d77f63          	bgeu	a4,a3,ffffffffc0201092 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e58:	40f98733          	sub	a4,s3,a5
ffffffffc0200e5c:	870d                	srai	a4,a4,0x3
ffffffffc0200e5e:	02b70733          	mul	a4,a4,a1
ffffffffc0200e62:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e64:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e66:	3ed77663          	bgeu	a4,a3,ffffffffc0201252 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e6a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e6e:	878d                	srai	a5,a5,0x3
ffffffffc0200e70:	02b787b3          	mul	a5,a5,a1
ffffffffc0200e74:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e76:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e78:	3ad7fd63          	bgeu	a5,a3,ffffffffc0201232 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200e7c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e7e:	00043c03          	ld	s8,0(s0)
ffffffffc0200e82:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e86:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e8a:	e400                	sd	s0,8(s0)
ffffffffc0200e8c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e8e:	00005797          	auipc	a5,0x5
ffffffffc0200e92:	1a07a523          	sw	zero,426(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e96:	029000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200e9a:	36051c63          	bnez	a0,ffffffffc0201212 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200e9e:	4585                	li	a1,1
ffffffffc0200ea0:	8552                	mv	a0,s4
ffffffffc0200ea2:	05b000ef          	jal	ra,ffffffffc02016fc <free_pages>
    free_page(p1);
ffffffffc0200ea6:	4585                	li	a1,1
ffffffffc0200ea8:	854e                	mv	a0,s3
ffffffffc0200eaa:	053000ef          	jal	ra,ffffffffc02016fc <free_pages>
    free_page(p2);
ffffffffc0200eae:	4585                	li	a1,1
ffffffffc0200eb0:	8556                	mv	a0,s5
ffffffffc0200eb2:	04b000ef          	jal	ra,ffffffffc02016fc <free_pages>
    assert(nr_free == 3);
ffffffffc0200eb6:	4818                	lw	a4,16(s0)
ffffffffc0200eb8:	478d                	li	a5,3
ffffffffc0200eba:	32f71c63          	bne	a4,a5,ffffffffc02011f2 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ebe:	4505                	li	a0,1
ffffffffc0200ec0:	7fe000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200ec4:	89aa                	mv	s3,a0
ffffffffc0200ec6:	30050663          	beqz	a0,ffffffffc02011d2 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200eca:	4505                	li	a0,1
ffffffffc0200ecc:	7f2000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200ed0:	8aaa                	mv	s5,a0
ffffffffc0200ed2:	2e050063          	beqz	a0,ffffffffc02011b2 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ed6:	4505                	li	a0,1
ffffffffc0200ed8:	7e6000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200edc:	8a2a                	mv	s4,a0
ffffffffc0200ede:	2a050a63          	beqz	a0,ffffffffc0201192 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200ee2:	4505                	li	a0,1
ffffffffc0200ee4:	7da000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200ee8:	28051563          	bnez	a0,ffffffffc0201172 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200eec:	4585                	li	a1,1
ffffffffc0200eee:	854e                	mv	a0,s3
ffffffffc0200ef0:	00d000ef          	jal	ra,ffffffffc02016fc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ef4:	641c                	ld	a5,8(s0)
ffffffffc0200ef6:	1a878e63          	beq	a5,s0,ffffffffc02010b2 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200efa:	4505                	li	a0,1
ffffffffc0200efc:	7c2000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200f00:	52a99963          	bne	s3,a0,ffffffffc0201432 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200f04:	4505                	li	a0,1
ffffffffc0200f06:	7b8000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200f0a:	50051463          	bnez	a0,ffffffffc0201412 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200f0e:	481c                	lw	a5,16(s0)
ffffffffc0200f10:	4e079163          	bnez	a5,ffffffffc02013f2 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200f14:	854e                	mv	a0,s3
ffffffffc0200f16:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f18:	01843023          	sd	s8,0(s0)
ffffffffc0200f1c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f20:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f24:	7d8000ef          	jal	ra,ffffffffc02016fc <free_pages>
    free_page(p1);
ffffffffc0200f28:	4585                	li	a1,1
ffffffffc0200f2a:	8556                	mv	a0,s5
ffffffffc0200f2c:	7d0000ef          	jal	ra,ffffffffc02016fc <free_pages>
    free_page(p2);
ffffffffc0200f30:	4585                	li	a1,1
ffffffffc0200f32:	8552                	mv	a0,s4
ffffffffc0200f34:	7c8000ef          	jal	ra,ffffffffc02016fc <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f38:	4515                	li	a0,5
ffffffffc0200f3a:	784000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200f3e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f40:	48050963          	beqz	a0,ffffffffc02013d2 <best_fit_check+0x63e>
ffffffffc0200f44:	651c                	ld	a5,8(a0)
ffffffffc0200f46:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f48:	8b85                	andi	a5,a5,1
ffffffffc0200f4a:	46079463          	bnez	a5,ffffffffc02013b2 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f4e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f50:	00043a83          	ld	s5,0(s0)
ffffffffc0200f54:	00843a03          	ld	s4,8(s0)
ffffffffc0200f58:	e000                	sd	s0,0(s0)
ffffffffc0200f5a:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f5c:	762000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200f60:	42051963          	bnez	a0,ffffffffc0201392 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f64:	4589                	li	a1,2
ffffffffc0200f66:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200f6a:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200f6e:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200f72:	00005797          	auipc	a5,0x5
ffffffffc0200f76:	0c07a323          	sw	zero,198(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200f7a:	782000ef          	jal	ra,ffffffffc02016fc <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200f7e:	8562                	mv	a0,s8
ffffffffc0200f80:	4585                	li	a1,1
ffffffffc0200f82:	77a000ef          	jal	ra,ffffffffc02016fc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f86:	4511                	li	a0,4
ffffffffc0200f88:	736000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200f8c:	3e051363          	bnez	a0,ffffffffc0201372 <best_fit_check+0x5de>
ffffffffc0200f90:	0309b783          	ld	a5,48(s3)
ffffffffc0200f94:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f96:	8b85                	andi	a5,a5,1
ffffffffc0200f98:	3a078d63          	beqz	a5,ffffffffc0201352 <best_fit_check+0x5be>
ffffffffc0200f9c:	0389a703          	lw	a4,56(s3)
ffffffffc0200fa0:	4789                	li	a5,2
ffffffffc0200fa2:	3af71863          	bne	a4,a5,ffffffffc0201352 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200fa6:	4505                	li	a0,1
ffffffffc0200fa8:	716000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200fac:	8baa                	mv	s7,a0
ffffffffc0200fae:	38050263          	beqz	a0,ffffffffc0201332 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200fb2:	4509                	li	a0,2
ffffffffc0200fb4:	70a000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200fb8:	34050d63          	beqz	a0,ffffffffc0201312 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200fbc:	337c1b63          	bne	s8,s7,ffffffffc02012f2 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200fc0:	854e                	mv	a0,s3
ffffffffc0200fc2:	4595                	li	a1,5
ffffffffc0200fc4:	738000ef          	jal	ra,ffffffffc02016fc <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200fc8:	4515                	li	a0,5
ffffffffc0200fca:	6f4000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200fce:	89aa                	mv	s3,a0
ffffffffc0200fd0:	30050163          	beqz	a0,ffffffffc02012d2 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200fd4:	4505                	li	a0,1
ffffffffc0200fd6:	6e8000ef          	jal	ra,ffffffffc02016be <alloc_pages>
ffffffffc0200fda:	2c051c63          	bnez	a0,ffffffffc02012b2 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200fde:	481c                	lw	a5,16(s0)
ffffffffc0200fe0:	2a079963          	bnez	a5,ffffffffc0201292 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fe4:	4595                	li	a1,5
ffffffffc0200fe6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200fe8:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200fec:	01543023          	sd	s5,0(s0)
ffffffffc0200ff0:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200ff4:	708000ef          	jal	ra,ffffffffc02016fc <free_pages>
    return listelm->next;
ffffffffc0200ff8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ffa:	00878963          	beq	a5,s0,ffffffffc020100c <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200ffe:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201002:	679c                	ld	a5,8(a5)
ffffffffc0201004:	397d                	addiw	s2,s2,-1
ffffffffc0201006:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201008:	fe879be3          	bne	a5,s0,ffffffffc0200ffe <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc020100c:	26091363          	bnez	s2,ffffffffc0201272 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0201010:	e0ed                	bnez	s1,ffffffffc02010f2 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0201012:	60a6                	ld	ra,72(sp)
ffffffffc0201014:	6406                	ld	s0,64(sp)
ffffffffc0201016:	74e2                	ld	s1,56(sp)
ffffffffc0201018:	7942                	ld	s2,48(sp)
ffffffffc020101a:	79a2                	ld	s3,40(sp)
ffffffffc020101c:	7a02                	ld	s4,32(sp)
ffffffffc020101e:	6ae2                	ld	s5,24(sp)
ffffffffc0201020:	6b42                	ld	s6,16(sp)
ffffffffc0201022:	6ba2                	ld	s7,8(sp)
ffffffffc0201024:	6c02                	ld	s8,0(sp)
ffffffffc0201026:	6161                	addi	sp,sp,80
ffffffffc0201028:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020102a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020102c:	4481                	li	s1,0
ffffffffc020102e:	4901                	li	s2,0
ffffffffc0201030:	b35d                	j	ffffffffc0200dd6 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0201032:	00002697          	auipc	a3,0x2
ffffffffc0201036:	8e668693          	addi	a3,a3,-1818 # ffffffffc0202918 <commands+0x728>
ffffffffc020103a:	00002617          	auipc	a2,0x2
ffffffffc020103e:	8ae60613          	addi	a2,a2,-1874 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201042:	10d00593          	li	a1,269
ffffffffc0201046:	00002517          	auipc	a0,0x2
ffffffffc020104a:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0202900 <commands+0x710>
ffffffffc020104e:	baeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201052:	00002697          	auipc	a3,0x2
ffffffffc0201056:	95668693          	addi	a3,a3,-1706 # ffffffffc02029a8 <commands+0x7b8>
ffffffffc020105a:	00002617          	auipc	a2,0x2
ffffffffc020105e:	88e60613          	addi	a2,a2,-1906 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201062:	0d900593          	li	a1,217
ffffffffc0201066:	00002517          	auipc	a0,0x2
ffffffffc020106a:	89a50513          	addi	a0,a0,-1894 # ffffffffc0202900 <commands+0x710>
ffffffffc020106e:	b8eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201072:	00002697          	auipc	a3,0x2
ffffffffc0201076:	95e68693          	addi	a3,a3,-1698 # ffffffffc02029d0 <commands+0x7e0>
ffffffffc020107a:	00002617          	auipc	a2,0x2
ffffffffc020107e:	86e60613          	addi	a2,a2,-1938 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201082:	0da00593          	li	a1,218
ffffffffc0201086:	00002517          	auipc	a0,0x2
ffffffffc020108a:	87a50513          	addi	a0,a0,-1926 # ffffffffc0202900 <commands+0x710>
ffffffffc020108e:	b6eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201092:	00002697          	auipc	a3,0x2
ffffffffc0201096:	97e68693          	addi	a3,a3,-1666 # ffffffffc0202a10 <commands+0x820>
ffffffffc020109a:	00002617          	auipc	a2,0x2
ffffffffc020109e:	84e60613          	addi	a2,a2,-1970 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02010a2:	0dc00593          	li	a1,220
ffffffffc02010a6:	00002517          	auipc	a0,0x2
ffffffffc02010aa:	85a50513          	addi	a0,a0,-1958 # ffffffffc0202900 <commands+0x710>
ffffffffc02010ae:	b4eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010b2:	00002697          	auipc	a3,0x2
ffffffffc02010b6:	9e668693          	addi	a3,a3,-1562 # ffffffffc0202a98 <commands+0x8a8>
ffffffffc02010ba:	00002617          	auipc	a2,0x2
ffffffffc02010be:	82e60613          	addi	a2,a2,-2002 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02010c2:	0f500593          	li	a1,245
ffffffffc02010c6:	00002517          	auipc	a0,0x2
ffffffffc02010ca:	83a50513          	addi	a0,a0,-1990 # ffffffffc0202900 <commands+0x710>
ffffffffc02010ce:	b2eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010d2:	00002697          	auipc	a3,0x2
ffffffffc02010d6:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202988 <commands+0x798>
ffffffffc02010da:	00002617          	auipc	a2,0x2
ffffffffc02010de:	80e60613          	addi	a2,a2,-2034 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02010e2:	0d700593          	li	a1,215
ffffffffc02010e6:	00002517          	auipc	a0,0x2
ffffffffc02010ea:	81a50513          	addi	a0,a0,-2022 # ffffffffc0202900 <commands+0x710>
ffffffffc02010ee:	b0eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(total == 0);
ffffffffc02010f2:	00002697          	auipc	a3,0x2
ffffffffc02010f6:	ad668693          	addi	a3,a3,-1322 # ffffffffc0202bc8 <commands+0x9d8>
ffffffffc02010fa:	00001617          	auipc	a2,0x1
ffffffffc02010fe:	7ee60613          	addi	a2,a2,2030 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201102:	14f00593          	li	a1,335
ffffffffc0201106:	00001517          	auipc	a0,0x1
ffffffffc020110a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0202900 <commands+0x710>
ffffffffc020110e:	aeeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(total == nr_free_pages());
ffffffffc0201112:	00002697          	auipc	a3,0x2
ffffffffc0201116:	81668693          	addi	a3,a3,-2026 # ffffffffc0202928 <commands+0x738>
ffffffffc020111a:	00001617          	auipc	a2,0x1
ffffffffc020111e:	7ce60613          	addi	a2,a2,1998 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201122:	11000593          	li	a1,272
ffffffffc0201126:	00001517          	auipc	a0,0x1
ffffffffc020112a:	7da50513          	addi	a0,a0,2010 # ffffffffc0202900 <commands+0x710>
ffffffffc020112e:	aceff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201132:	00002697          	auipc	a3,0x2
ffffffffc0201136:	83668693          	addi	a3,a3,-1994 # ffffffffc0202968 <commands+0x778>
ffffffffc020113a:	00001617          	auipc	a2,0x1
ffffffffc020113e:	7ae60613          	addi	a2,a2,1966 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201142:	0d600593          	li	a1,214
ffffffffc0201146:	00001517          	auipc	a0,0x1
ffffffffc020114a:	7ba50513          	addi	a0,a0,1978 # ffffffffc0202900 <commands+0x710>
ffffffffc020114e:	aaeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201152:	00001697          	auipc	a3,0x1
ffffffffc0201156:	7f668693          	addi	a3,a3,2038 # ffffffffc0202948 <commands+0x758>
ffffffffc020115a:	00001617          	auipc	a2,0x1
ffffffffc020115e:	78e60613          	addi	a2,a2,1934 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201162:	0d500593          	li	a1,213
ffffffffc0201166:	00001517          	auipc	a0,0x1
ffffffffc020116a:	79a50513          	addi	a0,a0,1946 # ffffffffc0202900 <commands+0x710>
ffffffffc020116e:	a8eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201172:	00002697          	auipc	a3,0x2
ffffffffc0201176:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0202a70 <commands+0x880>
ffffffffc020117a:	00001617          	auipc	a2,0x1
ffffffffc020117e:	76e60613          	addi	a2,a2,1902 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201182:	0f200593          	li	a1,242
ffffffffc0201186:	00001517          	auipc	a0,0x1
ffffffffc020118a:	77a50513          	addi	a0,a0,1914 # ffffffffc0202900 <commands+0x710>
ffffffffc020118e:	a6eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201192:	00001697          	auipc	a3,0x1
ffffffffc0201196:	7f668693          	addi	a3,a3,2038 # ffffffffc0202988 <commands+0x798>
ffffffffc020119a:	00001617          	auipc	a2,0x1
ffffffffc020119e:	74e60613          	addi	a2,a2,1870 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02011a2:	0f000593          	li	a1,240
ffffffffc02011a6:	00001517          	auipc	a0,0x1
ffffffffc02011aa:	75a50513          	addi	a0,a0,1882 # ffffffffc0202900 <commands+0x710>
ffffffffc02011ae:	a4eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011b2:	00001697          	auipc	a3,0x1
ffffffffc02011b6:	7b668693          	addi	a3,a3,1974 # ffffffffc0202968 <commands+0x778>
ffffffffc02011ba:	00001617          	auipc	a2,0x1
ffffffffc02011be:	72e60613          	addi	a2,a2,1838 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02011c2:	0ef00593          	li	a1,239
ffffffffc02011c6:	00001517          	auipc	a0,0x1
ffffffffc02011ca:	73a50513          	addi	a0,a0,1850 # ffffffffc0202900 <commands+0x710>
ffffffffc02011ce:	a2eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011d2:	00001697          	auipc	a3,0x1
ffffffffc02011d6:	77668693          	addi	a3,a3,1910 # ffffffffc0202948 <commands+0x758>
ffffffffc02011da:	00001617          	auipc	a2,0x1
ffffffffc02011de:	70e60613          	addi	a2,a2,1806 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02011e2:	0ee00593          	li	a1,238
ffffffffc02011e6:	00001517          	auipc	a0,0x1
ffffffffc02011ea:	71a50513          	addi	a0,a0,1818 # ffffffffc0202900 <commands+0x710>
ffffffffc02011ee:	a0eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(nr_free == 3);
ffffffffc02011f2:	00002697          	auipc	a3,0x2
ffffffffc02011f6:	89668693          	addi	a3,a3,-1898 # ffffffffc0202a88 <commands+0x898>
ffffffffc02011fa:	00001617          	auipc	a2,0x1
ffffffffc02011fe:	6ee60613          	addi	a2,a2,1774 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201202:	0ec00593          	li	a1,236
ffffffffc0201206:	00001517          	auipc	a0,0x1
ffffffffc020120a:	6fa50513          	addi	a0,a0,1786 # ffffffffc0202900 <commands+0x710>
ffffffffc020120e:	9eeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201212:	00002697          	auipc	a3,0x2
ffffffffc0201216:	85e68693          	addi	a3,a3,-1954 # ffffffffc0202a70 <commands+0x880>
ffffffffc020121a:	00001617          	auipc	a2,0x1
ffffffffc020121e:	6ce60613          	addi	a2,a2,1742 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201222:	0e700593          	li	a1,231
ffffffffc0201226:	00001517          	auipc	a0,0x1
ffffffffc020122a:	6da50513          	addi	a0,a0,1754 # ffffffffc0202900 <commands+0x710>
ffffffffc020122e:	9ceff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201232:	00002697          	auipc	a3,0x2
ffffffffc0201236:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202a50 <commands+0x860>
ffffffffc020123a:	00001617          	auipc	a2,0x1
ffffffffc020123e:	6ae60613          	addi	a2,a2,1710 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201242:	0de00593          	li	a1,222
ffffffffc0201246:	00001517          	auipc	a0,0x1
ffffffffc020124a:	6ba50513          	addi	a0,a0,1722 # ffffffffc0202900 <commands+0x710>
ffffffffc020124e:	9aeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201252:	00001697          	auipc	a3,0x1
ffffffffc0201256:	7de68693          	addi	a3,a3,2014 # ffffffffc0202a30 <commands+0x840>
ffffffffc020125a:	00001617          	auipc	a2,0x1
ffffffffc020125e:	68e60613          	addi	a2,a2,1678 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201262:	0dd00593          	li	a1,221
ffffffffc0201266:	00001517          	auipc	a0,0x1
ffffffffc020126a:	69a50513          	addi	a0,a0,1690 # ffffffffc0202900 <commands+0x710>
ffffffffc020126e:	98eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(count == 0);
ffffffffc0201272:	00002697          	auipc	a3,0x2
ffffffffc0201276:	94668693          	addi	a3,a3,-1722 # ffffffffc0202bb8 <commands+0x9c8>
ffffffffc020127a:	00001617          	auipc	a2,0x1
ffffffffc020127e:	66e60613          	addi	a2,a2,1646 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201282:	14e00593          	li	a1,334
ffffffffc0201286:	00001517          	auipc	a0,0x1
ffffffffc020128a:	67a50513          	addi	a0,a0,1658 # ffffffffc0202900 <commands+0x710>
ffffffffc020128e:	96eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(nr_free == 0);
ffffffffc0201292:	00002697          	auipc	a3,0x2
ffffffffc0201296:	83e68693          	addi	a3,a3,-1986 # ffffffffc0202ad0 <commands+0x8e0>
ffffffffc020129a:	00001617          	auipc	a2,0x1
ffffffffc020129e:	64e60613          	addi	a2,a2,1614 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02012a2:	14300593          	li	a1,323
ffffffffc02012a6:	00001517          	auipc	a0,0x1
ffffffffc02012aa:	65a50513          	addi	a0,a0,1626 # ffffffffc0202900 <commands+0x710>
ffffffffc02012ae:	94eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012b2:	00001697          	auipc	a3,0x1
ffffffffc02012b6:	7be68693          	addi	a3,a3,1982 # ffffffffc0202a70 <commands+0x880>
ffffffffc02012ba:	00001617          	auipc	a2,0x1
ffffffffc02012be:	62e60613          	addi	a2,a2,1582 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02012c2:	13d00593          	li	a1,317
ffffffffc02012c6:	00001517          	auipc	a0,0x1
ffffffffc02012ca:	63a50513          	addi	a0,a0,1594 # ffffffffc0202900 <commands+0x710>
ffffffffc02012ce:	92eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012d2:	00002697          	auipc	a3,0x2
ffffffffc02012d6:	8c668693          	addi	a3,a3,-1850 # ffffffffc0202b98 <commands+0x9a8>
ffffffffc02012da:	00001617          	auipc	a2,0x1
ffffffffc02012de:	60e60613          	addi	a2,a2,1550 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02012e2:	13c00593          	li	a1,316
ffffffffc02012e6:	00001517          	auipc	a0,0x1
ffffffffc02012ea:	61a50513          	addi	a0,a0,1562 # ffffffffc0202900 <commands+0x710>
ffffffffc02012ee:	90eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(p0 + 4 == p1);
ffffffffc02012f2:	00002697          	auipc	a3,0x2
ffffffffc02012f6:	89668693          	addi	a3,a3,-1898 # ffffffffc0202b88 <commands+0x998>
ffffffffc02012fa:	00001617          	auipc	a2,0x1
ffffffffc02012fe:	5ee60613          	addi	a2,a2,1518 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201302:	13400593          	li	a1,308
ffffffffc0201306:	00001517          	auipc	a0,0x1
ffffffffc020130a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0202900 <commands+0x710>
ffffffffc020130e:	8eeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201312:	00002697          	auipc	a3,0x2
ffffffffc0201316:	85e68693          	addi	a3,a3,-1954 # ffffffffc0202b70 <commands+0x980>
ffffffffc020131a:	00001617          	auipc	a2,0x1
ffffffffc020131e:	5ce60613          	addi	a2,a2,1486 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201322:	13300593          	li	a1,307
ffffffffc0201326:	00001517          	auipc	a0,0x1
ffffffffc020132a:	5da50513          	addi	a0,a0,1498 # ffffffffc0202900 <commands+0x710>
ffffffffc020132e:	8ceff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201332:	00002697          	auipc	a3,0x2
ffffffffc0201336:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202b50 <commands+0x960>
ffffffffc020133a:	00001617          	auipc	a2,0x1
ffffffffc020133e:	5ae60613          	addi	a2,a2,1454 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201342:	13200593          	li	a1,306
ffffffffc0201346:	00001517          	auipc	a0,0x1
ffffffffc020134a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0202900 <commands+0x710>
ffffffffc020134e:	8aeff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201352:	00001697          	auipc	a3,0x1
ffffffffc0201356:	7ce68693          	addi	a3,a3,1998 # ffffffffc0202b20 <commands+0x930>
ffffffffc020135a:	00001617          	auipc	a2,0x1
ffffffffc020135e:	58e60613          	addi	a2,a2,1422 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201362:	13000593          	li	a1,304
ffffffffc0201366:	00001517          	auipc	a0,0x1
ffffffffc020136a:	59a50513          	addi	a0,a0,1434 # ffffffffc0202900 <commands+0x710>
ffffffffc020136e:	88eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201372:	00001697          	auipc	a3,0x1
ffffffffc0201376:	79668693          	addi	a3,a3,1942 # ffffffffc0202b08 <commands+0x918>
ffffffffc020137a:	00001617          	auipc	a2,0x1
ffffffffc020137e:	56e60613          	addi	a2,a2,1390 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201382:	12f00593          	li	a1,303
ffffffffc0201386:	00001517          	auipc	a0,0x1
ffffffffc020138a:	57a50513          	addi	a0,a0,1402 # ffffffffc0202900 <commands+0x710>
ffffffffc020138e:	86eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201392:	00001697          	auipc	a3,0x1
ffffffffc0201396:	6de68693          	addi	a3,a3,1758 # ffffffffc0202a70 <commands+0x880>
ffffffffc020139a:	00001617          	auipc	a2,0x1
ffffffffc020139e:	54e60613          	addi	a2,a2,1358 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02013a2:	12300593          	li	a1,291
ffffffffc02013a6:	00001517          	auipc	a0,0x1
ffffffffc02013aa:	55a50513          	addi	a0,a0,1370 # ffffffffc0202900 <commands+0x710>
ffffffffc02013ae:	84eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(!PageProperty(p0));
ffffffffc02013b2:	00001697          	auipc	a3,0x1
ffffffffc02013b6:	73e68693          	addi	a3,a3,1854 # ffffffffc0202af0 <commands+0x900>
ffffffffc02013ba:	00001617          	auipc	a2,0x1
ffffffffc02013be:	52e60613          	addi	a2,a2,1326 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02013c2:	11a00593          	li	a1,282
ffffffffc02013c6:	00001517          	auipc	a0,0x1
ffffffffc02013ca:	53a50513          	addi	a0,a0,1338 # ffffffffc0202900 <commands+0x710>
ffffffffc02013ce:	82eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(p0 != NULL);
ffffffffc02013d2:	00001697          	auipc	a3,0x1
ffffffffc02013d6:	70e68693          	addi	a3,a3,1806 # ffffffffc0202ae0 <commands+0x8f0>
ffffffffc02013da:	00001617          	auipc	a2,0x1
ffffffffc02013de:	50e60613          	addi	a2,a2,1294 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02013e2:	11900593          	li	a1,281
ffffffffc02013e6:	00001517          	auipc	a0,0x1
ffffffffc02013ea:	51a50513          	addi	a0,a0,1306 # ffffffffc0202900 <commands+0x710>
ffffffffc02013ee:	80eff0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(nr_free == 0);
ffffffffc02013f2:	00001697          	auipc	a3,0x1
ffffffffc02013f6:	6de68693          	addi	a3,a3,1758 # ffffffffc0202ad0 <commands+0x8e0>
ffffffffc02013fa:	00001617          	auipc	a2,0x1
ffffffffc02013fe:	4ee60613          	addi	a2,a2,1262 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201402:	0fb00593          	li	a1,251
ffffffffc0201406:	00001517          	auipc	a0,0x1
ffffffffc020140a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0202900 <commands+0x710>
ffffffffc020140e:	feffe0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201412:	00001697          	auipc	a3,0x1
ffffffffc0201416:	65e68693          	addi	a3,a3,1630 # ffffffffc0202a70 <commands+0x880>
ffffffffc020141a:	00001617          	auipc	a2,0x1
ffffffffc020141e:	4ce60613          	addi	a2,a2,1230 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201422:	0f900593          	li	a1,249
ffffffffc0201426:	00001517          	auipc	a0,0x1
ffffffffc020142a:	4da50513          	addi	a0,a0,1242 # ffffffffc0202900 <commands+0x710>
ffffffffc020142e:	fcffe0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201432:	00001697          	auipc	a3,0x1
ffffffffc0201436:	67e68693          	addi	a3,a3,1662 # ffffffffc0202ab0 <commands+0x8c0>
ffffffffc020143a:	00001617          	auipc	a2,0x1
ffffffffc020143e:	4ae60613          	addi	a2,a2,1198 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc0201442:	0f800593          	li	a1,248
ffffffffc0201446:	00001517          	auipc	a0,0x1
ffffffffc020144a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0202900 <commands+0x710>
ffffffffc020144e:	faffe0ef          	jal	ra,ffffffffc02003fc <__panic>

ffffffffc0201452 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201452:	1141                	addi	sp,sp,-16
ffffffffc0201454:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201456:	14058a63          	beqz	a1,ffffffffc02015aa <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020145a:	00259693          	slli	a3,a1,0x2
ffffffffc020145e:	96ae                	add	a3,a3,a1
ffffffffc0201460:	068e                	slli	a3,a3,0x3
ffffffffc0201462:	96aa                	add	a3,a3,a0
ffffffffc0201464:	87aa                	mv	a5,a0
ffffffffc0201466:	02d50263          	beq	a0,a3,ffffffffc020148a <best_fit_free_pages+0x38>
ffffffffc020146a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020146c:	8b05                	andi	a4,a4,1
ffffffffc020146e:	10071e63          	bnez	a4,ffffffffc020158a <best_fit_free_pages+0x138>
ffffffffc0201472:	6798                	ld	a4,8(a5)
ffffffffc0201474:	8b09                	andi	a4,a4,2
ffffffffc0201476:	10071a63          	bnez	a4,ffffffffc020158a <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc020147a:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020147e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201482:	02878793          	addi	a5,a5,40
ffffffffc0201486:	fed792e3          	bne	a5,a3,ffffffffc020146a <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc020148a:	2581                	sext.w	a1,a1
ffffffffc020148c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020148e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201492:	4789                	li	a5,2
ffffffffc0201494:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	b9068693          	addi	a3,a3,-1136 # ffffffffc0206028 <free_area>
ffffffffc02014a0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014a2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014a4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014a8:	9db9                	addw	a1,a1,a4
ffffffffc02014aa:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014ac:	0ad78863          	beq	a5,a3,ffffffffc020155c <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014b0:	fe878713          	addi	a4,a5,-24
ffffffffc02014b4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014b8:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014ba:	00e56a63          	bltu	a0,a4,ffffffffc02014ce <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc02014be:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014c0:	06d70263          	beq	a4,a3,ffffffffc0201524 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014c4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014c6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014ca:	fee57ae3          	bgeu	a0,a4,ffffffffc02014be <best_fit_free_pages+0x6c>
ffffffffc02014ce:	c199                	beqz	a1,ffffffffc02014d4 <best_fit_free_pages+0x82>
ffffffffc02014d0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014d4:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02014d6:	e390                	sd	a2,0(a5)
ffffffffc02014d8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014da:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014dc:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02014de:	02d70063          	beq	a4,a3,ffffffffc02014fe <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02014e2:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014e6:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02014ea:	02081613          	slli	a2,a6,0x20
ffffffffc02014ee:	9201                	srli	a2,a2,0x20
ffffffffc02014f0:	00261793          	slli	a5,a2,0x2
ffffffffc02014f4:	97b2                	add	a5,a5,a2
ffffffffc02014f6:	078e                	slli	a5,a5,0x3
ffffffffc02014f8:	97ae                	add	a5,a5,a1
ffffffffc02014fa:	02f50f63          	beq	a0,a5,ffffffffc0201538 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02014fe:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201500:	00d70f63          	beq	a4,a3,ffffffffc020151e <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201504:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201506:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020150a:	02059613          	slli	a2,a1,0x20
ffffffffc020150e:	9201                	srli	a2,a2,0x20
ffffffffc0201510:	00261793          	slli	a5,a2,0x2
ffffffffc0201514:	97b2                	add	a5,a5,a2
ffffffffc0201516:	078e                	slli	a5,a5,0x3
ffffffffc0201518:	97aa                	add	a5,a5,a0
ffffffffc020151a:	04f68863          	beq	a3,a5,ffffffffc020156a <best_fit_free_pages+0x118>
}
ffffffffc020151e:	60a2                	ld	ra,8(sp)
ffffffffc0201520:	0141                	addi	sp,sp,16
ffffffffc0201522:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201524:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201526:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201528:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020152a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020152c:	02d70563          	beq	a4,a3,ffffffffc0201556 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201530:	8832                	mv	a6,a2
ffffffffc0201532:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201534:	87ba                	mv	a5,a4
ffffffffc0201536:	bf41                	j	ffffffffc02014c6 <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc0201538:	491c                	lw	a5,16(a0)
ffffffffc020153a:	0107883b          	addw	a6,a5,a6
ffffffffc020153e:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201542:	57f5                	li	a5,-3
ffffffffc0201544:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201548:	6d10                	ld	a2,24(a0)
ffffffffc020154a:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020154c:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc020154e:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201550:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201552:	e390                	sd	a2,0(a5)
ffffffffc0201554:	b775                	j	ffffffffc0201500 <best_fit_free_pages+0xae>
ffffffffc0201556:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201558:	873e                	mv	a4,a5
ffffffffc020155a:	b761                	j	ffffffffc02014e2 <best_fit_free_pages+0x90>
}
ffffffffc020155c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020155e:	e390                	sd	a2,0(a5)
ffffffffc0201560:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201562:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201564:	ed1c                	sd	a5,24(a0)
ffffffffc0201566:	0141                	addi	sp,sp,16
ffffffffc0201568:	8082                	ret
            base->property += p->property;
ffffffffc020156a:	ff872783          	lw	a5,-8(a4)
ffffffffc020156e:	ff070693          	addi	a3,a4,-16
ffffffffc0201572:	9dbd                	addw	a1,a1,a5
ffffffffc0201574:	c90c                	sw	a1,16(a0)
ffffffffc0201576:	57f5                	li	a5,-3
ffffffffc0201578:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020157c:	6314                	ld	a3,0(a4)
ffffffffc020157e:	671c                	ld	a5,8(a4)
}
ffffffffc0201580:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201582:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201584:	e394                	sd	a3,0(a5)
ffffffffc0201586:	0141                	addi	sp,sp,16
ffffffffc0201588:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020158a:	00001697          	auipc	a3,0x1
ffffffffc020158e:	64e68693          	addi	a3,a3,1614 # ffffffffc0202bd8 <commands+0x9e8>
ffffffffc0201592:	00001617          	auipc	a2,0x1
ffffffffc0201596:	35660613          	addi	a2,a2,854 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc020159a:	09300593          	li	a1,147
ffffffffc020159e:	00001517          	auipc	a0,0x1
ffffffffc02015a2:	36250513          	addi	a0,a0,866 # ffffffffc0202900 <commands+0x710>
ffffffffc02015a6:	e57fe0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(n > 0);
ffffffffc02015aa:	00001697          	auipc	a3,0x1
ffffffffc02015ae:	33668693          	addi	a3,a3,822 # ffffffffc02028e0 <commands+0x6f0>
ffffffffc02015b2:	00001617          	auipc	a2,0x1
ffffffffc02015b6:	33660613          	addi	a2,a2,822 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02015ba:	09000593          	li	a1,144
ffffffffc02015be:	00001517          	auipc	a0,0x1
ffffffffc02015c2:	34250513          	addi	a0,a0,834 # ffffffffc0202900 <commands+0x710>
ffffffffc02015c6:	e37fe0ef          	jal	ra,ffffffffc02003fc <__panic>

ffffffffc02015ca <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02015ca:	1141                	addi	sp,sp,-16
ffffffffc02015cc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015ce:	c9e1                	beqz	a1,ffffffffc020169e <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02015d0:	00259693          	slli	a3,a1,0x2
ffffffffc02015d4:	96ae                	add	a3,a3,a1
ffffffffc02015d6:	068e                	slli	a3,a3,0x3
ffffffffc02015d8:	96aa                	add	a3,a3,a0
ffffffffc02015da:	87aa                	mv	a5,a0
ffffffffc02015dc:	00d50f63          	beq	a0,a3,ffffffffc02015fa <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02015e0:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02015e2:	8b05                	andi	a4,a4,1
ffffffffc02015e4:	cf49                	beqz	a4,ffffffffc020167e <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02015e6:	0007a823          	sw	zero,16(a5)
ffffffffc02015ea:	0007b423          	sd	zero,8(a5)
ffffffffc02015ee:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015f2:	02878793          	addi	a5,a5,40
ffffffffc02015f6:	fed795e3          	bne	a5,a3,ffffffffc02015e0 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02015fa:	2581                	sext.w	a1,a1
ffffffffc02015fc:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015fe:	4789                	li	a5,2
ffffffffc0201600:	00850713          	addi	a4,a0,8
ffffffffc0201604:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201608:	00005697          	auipc	a3,0x5
ffffffffc020160c:	a2068693          	addi	a3,a3,-1504 # ffffffffc0206028 <free_area>
ffffffffc0201610:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201612:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201614:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201618:	9db9                	addw	a1,a1,a4
ffffffffc020161a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020161c:	04d78a63          	beq	a5,a3,ffffffffc0201670 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201620:	fe878713          	addi	a4,a5,-24
ffffffffc0201624:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201628:	4581                	li	a1,0
            if (base < page) {
ffffffffc020162a:	00e56a63          	bltu	a0,a4,ffffffffc020163e <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc020162e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201630:	02d70263          	beq	a4,a3,ffffffffc0201654 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201634:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201636:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020163a:	fee57ae3          	bgeu	a0,a4,ffffffffc020162e <best_fit_init_memmap+0x64>
ffffffffc020163e:	c199                	beqz	a1,ffffffffc0201644 <best_fit_init_memmap+0x7a>
ffffffffc0201640:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201644:	6398                	ld	a4,0(a5)
}
ffffffffc0201646:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201648:	e390                	sd	a2,0(a5)
ffffffffc020164a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020164c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020164e:	ed18                	sd	a4,24(a0)
ffffffffc0201650:	0141                	addi	sp,sp,16
ffffffffc0201652:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201654:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201656:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201658:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020165a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020165c:	00d70663          	beq	a4,a3,ffffffffc0201668 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201660:	8832                	mv	a6,a2
ffffffffc0201662:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201664:	87ba                	mv	a5,a4
ffffffffc0201666:	bfc1                	j	ffffffffc0201636 <best_fit_init_memmap+0x6c>
}
ffffffffc0201668:	60a2                	ld	ra,8(sp)
ffffffffc020166a:	e290                	sd	a2,0(a3)
ffffffffc020166c:	0141                	addi	sp,sp,16
ffffffffc020166e:	8082                	ret
ffffffffc0201670:	60a2                	ld	ra,8(sp)
ffffffffc0201672:	e390                	sd	a2,0(a5)
ffffffffc0201674:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201676:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201678:	ed1c                	sd	a5,24(a0)
ffffffffc020167a:	0141                	addi	sp,sp,16
ffffffffc020167c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020167e:	00001697          	auipc	a3,0x1
ffffffffc0201682:	58268693          	addi	a3,a3,1410 # ffffffffc0202c00 <commands+0xa10>
ffffffffc0201686:	00001617          	auipc	a2,0x1
ffffffffc020168a:	26260613          	addi	a2,a2,610 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc020168e:	04b00593          	li	a1,75
ffffffffc0201692:	00001517          	auipc	a0,0x1
ffffffffc0201696:	26e50513          	addi	a0,a0,622 # ffffffffc0202900 <commands+0x710>
ffffffffc020169a:	d63fe0ef          	jal	ra,ffffffffc02003fc <__panic>
    assert(n > 0);
ffffffffc020169e:	00001697          	auipc	a3,0x1
ffffffffc02016a2:	24268693          	addi	a3,a3,578 # ffffffffc02028e0 <commands+0x6f0>
ffffffffc02016a6:	00001617          	auipc	a2,0x1
ffffffffc02016aa:	24260613          	addi	a2,a2,578 # ffffffffc02028e8 <commands+0x6f8>
ffffffffc02016ae:	04800593          	li	a1,72
ffffffffc02016b2:	00001517          	auipc	a0,0x1
ffffffffc02016b6:	24e50513          	addi	a0,a0,590 # ffffffffc0202900 <commands+0x710>
ffffffffc02016ba:	d43fe0ef          	jal	ra,ffffffffc02003fc <__panic>

ffffffffc02016be <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016be:	100027f3          	csrr	a5,sstatus
ffffffffc02016c2:	8b89                	andi	a5,a5,2
ffffffffc02016c4:	e799                	bnez	a5,ffffffffc02016d2 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016c6:	00005797          	auipc	a5,0x5
ffffffffc02016ca:	db27b783          	ld	a5,-590(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016ce:	6f9c                	ld	a5,24(a5)
ffffffffc02016d0:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02016d2:	1141                	addi	sp,sp,-16
ffffffffc02016d4:	e406                	sd	ra,8(sp)
ffffffffc02016d6:	e022                	sd	s0,0(sp)
ffffffffc02016d8:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02016da:	984ff0ef          	jal	ra,ffffffffc020085e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016de:	00005797          	auipc	a5,0x5
ffffffffc02016e2:	d9a7b783          	ld	a5,-614(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016e6:	6f9c                	ld	a5,24(a5)
ffffffffc02016e8:	8522                	mv	a0,s0
ffffffffc02016ea:	9782                	jalr	a5
ffffffffc02016ec:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02016ee:	96aff0ef          	jal	ra,ffffffffc0200858 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02016f2:	60a2                	ld	ra,8(sp)
ffffffffc02016f4:	8522                	mv	a0,s0
ffffffffc02016f6:	6402                	ld	s0,0(sp)
ffffffffc02016f8:	0141                	addi	sp,sp,16
ffffffffc02016fa:	8082                	ret

ffffffffc02016fc <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016fc:	100027f3          	csrr	a5,sstatus
ffffffffc0201700:	8b89                	andi	a5,a5,2
ffffffffc0201702:	e799                	bnez	a5,ffffffffc0201710 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201704:	00005797          	auipc	a5,0x5
ffffffffc0201708:	d747b783          	ld	a5,-652(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020170c:	739c                	ld	a5,32(a5)
ffffffffc020170e:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201710:	1101                	addi	sp,sp,-32
ffffffffc0201712:	ec06                	sd	ra,24(sp)
ffffffffc0201714:	e822                	sd	s0,16(sp)
ffffffffc0201716:	e426                	sd	s1,8(sp)
ffffffffc0201718:	842a                	mv	s0,a0
ffffffffc020171a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020171c:	942ff0ef          	jal	ra,ffffffffc020085e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201720:	00005797          	auipc	a5,0x5
ffffffffc0201724:	d587b783          	ld	a5,-680(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201728:	739c                	ld	a5,32(a5)
ffffffffc020172a:	85a6                	mv	a1,s1
ffffffffc020172c:	8522                	mv	a0,s0
ffffffffc020172e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201730:	6442                	ld	s0,16(sp)
ffffffffc0201732:	60e2                	ld	ra,24(sp)
ffffffffc0201734:	64a2                	ld	s1,8(sp)
ffffffffc0201736:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201738:	920ff06f          	j	ffffffffc0200858 <intr_enable>

ffffffffc020173c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020173c:	100027f3          	csrr	a5,sstatus
ffffffffc0201740:	8b89                	andi	a5,a5,2
ffffffffc0201742:	e799                	bnez	a5,ffffffffc0201750 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201744:	00005797          	auipc	a5,0x5
ffffffffc0201748:	d347b783          	ld	a5,-716(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020174c:	779c                	ld	a5,40(a5)
ffffffffc020174e:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201750:	1141                	addi	sp,sp,-16
ffffffffc0201752:	e406                	sd	ra,8(sp)
ffffffffc0201754:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201756:	908ff0ef          	jal	ra,ffffffffc020085e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020175a:	00005797          	auipc	a5,0x5
ffffffffc020175e:	d1e7b783          	ld	a5,-738(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201762:	779c                	ld	a5,40(a5)
ffffffffc0201764:	9782                	jalr	a5
ffffffffc0201766:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201768:	8f0ff0ef          	jal	ra,ffffffffc0200858 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	8522                	mv	a0,s0
ffffffffc0201770:	6402                	ld	s0,0(sp)
ffffffffc0201772:	0141                	addi	sp,sp,16
ffffffffc0201774:	8082                	ret

ffffffffc0201776 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201776:	00001797          	auipc	a5,0x1
ffffffffc020177a:	4b278793          	addi	a5,a5,1202 # ffffffffc0202c28 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020177e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201780:	7179                	addi	sp,sp,-48
ffffffffc0201782:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201784:	00001517          	auipc	a0,0x1
ffffffffc0201788:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202c60 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020178c:	00005417          	auipc	s0,0x5
ffffffffc0201790:	cec40413          	addi	s0,s0,-788 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201794:	f406                	sd	ra,40(sp)
ffffffffc0201796:	ec26                	sd	s1,24(sp)
ffffffffc0201798:	e44e                	sd	s3,8(sp)
ffffffffc020179a:	e84a                	sd	s2,16(sp)
ffffffffc020179c:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020179e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017a0:	963fe0ef          	jal	ra,ffffffffc0200102 <cprintf>
    pmm_manager->init();
ffffffffc02017a4:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017a6:	00005497          	auipc	s1,0x5
ffffffffc02017aa:	cea48493          	addi	s1,s1,-790 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017ae:	679c                	ld	a5,8(a5)
ffffffffc02017b0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017b2:	57f5                	li	a5,-3
ffffffffc02017b4:	07fa                	slli	a5,a5,0x1e
ffffffffc02017b6:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017b8:	88cff0ef          	jal	ra,ffffffffc0200844 <get_memory_base>
ffffffffc02017bc:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017be:	890ff0ef          	jal	ra,ffffffffc020084e <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017c2:	16050163          	beqz	a0,ffffffffc0201924 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017c6:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02017c8:	00001517          	auipc	a0,0x1
ffffffffc02017cc:	4e050513          	addi	a0,a0,1248 # ffffffffc0202ca8 <best_fit_pmm_manager+0x80>
ffffffffc02017d0:	933fe0ef          	jal	ra,ffffffffc0200102 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017d4:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02017d8:	864e                	mv	a2,s3
ffffffffc02017da:	fffa0693          	addi	a3,s4,-1
ffffffffc02017de:	85ca                	mv	a1,s2
ffffffffc02017e0:	00001517          	auipc	a0,0x1
ffffffffc02017e4:	4e050513          	addi	a0,a0,1248 # ffffffffc0202cc0 <best_fit_pmm_manager+0x98>
ffffffffc02017e8:	91bfe0ef          	jal	ra,ffffffffc0200102 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02017ec:	c80007b7          	lui	a5,0xc8000
ffffffffc02017f0:	8652                	mv	a2,s4
ffffffffc02017f2:	0d47e863          	bltu	a5,s4,ffffffffc02018c2 <pmm_init+0x14c>
ffffffffc02017f6:	00006797          	auipc	a5,0x6
ffffffffc02017fa:	ca978793          	addi	a5,a5,-855 # ffffffffc020749f <end+0xfff>
ffffffffc02017fe:	757d                	lui	a0,0xfffff
ffffffffc0201800:	8d7d                	and	a0,a0,a5
ffffffffc0201802:	8231                	srli	a2,a2,0xc
ffffffffc0201804:	00005597          	auipc	a1,0x5
ffffffffc0201808:	c6458593          	addi	a1,a1,-924 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020180c:	00005817          	auipc	a6,0x5
ffffffffc0201810:	c6480813          	addi	a6,a6,-924 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201814:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201816:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020181a:	000807b7          	lui	a5,0x80
ffffffffc020181e:	02f60663          	beq	a2,a5,ffffffffc020184a <pmm_init+0xd4>
ffffffffc0201822:	4701                	li	a4,0
ffffffffc0201824:	4781                	li	a5,0
ffffffffc0201826:	4305                	li	t1,1
ffffffffc0201828:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc020182c:	953a                	add	a0,a0,a4
ffffffffc020182e:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc0201832:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201836:	6190                	ld	a2,0(a1)
ffffffffc0201838:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020183a:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020183e:	011606b3          	add	a3,a2,a7
ffffffffc0201842:	02870713          	addi	a4,a4,40
ffffffffc0201846:	fed7e3e3          	bltu	a5,a3,ffffffffc020182c <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020184a:	00261693          	slli	a3,a2,0x2
ffffffffc020184e:	96b2                	add	a3,a3,a2
ffffffffc0201850:	fec007b7          	lui	a5,0xfec00
ffffffffc0201854:	97aa                	add	a5,a5,a0
ffffffffc0201856:	068e                	slli	a3,a3,0x3
ffffffffc0201858:	96be                	add	a3,a3,a5
ffffffffc020185a:	c02007b7          	lui	a5,0xc0200
ffffffffc020185e:	0af6e763          	bltu	a3,a5,ffffffffc020190c <pmm_init+0x196>
ffffffffc0201862:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201864:	77fd                	lui	a5,0xfffff
ffffffffc0201866:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020186a:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020186c:	04b6ee63          	bltu	a3,a1,ffffffffc02018c8 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201870:	601c                	ld	a5,0(s0)
ffffffffc0201872:	7b9c                	ld	a5,48(a5)
ffffffffc0201874:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201876:	00001517          	auipc	a0,0x1
ffffffffc020187a:	4d250513          	addi	a0,a0,1234 # ffffffffc0202d48 <best_fit_pmm_manager+0x120>
ffffffffc020187e:	885fe0ef          	jal	ra,ffffffffc0200102 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201882:	00003597          	auipc	a1,0x3
ffffffffc0201886:	77e58593          	addi	a1,a1,1918 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020188a:	00005797          	auipc	a5,0x5
ffffffffc020188e:	beb7bf23          	sd	a1,-1026(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201892:	c02007b7          	lui	a5,0xc0200
ffffffffc0201896:	0af5e363          	bltu	a1,a5,ffffffffc020193c <pmm_init+0x1c6>
ffffffffc020189a:	6090                	ld	a2,0(s1)
}
ffffffffc020189c:	7402                	ld	s0,32(sp)
ffffffffc020189e:	70a2                	ld	ra,40(sp)
ffffffffc02018a0:	64e2                	ld	s1,24(sp)
ffffffffc02018a2:	6942                	ld	s2,16(sp)
ffffffffc02018a4:	69a2                	ld	s3,8(sp)
ffffffffc02018a6:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018a8:	40c58633          	sub	a2,a1,a2
ffffffffc02018ac:	00005797          	auipc	a5,0x5
ffffffffc02018b0:	bcc7ba23          	sd	a2,-1068(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018b4:	00001517          	auipc	a0,0x1
ffffffffc02018b8:	4b450513          	addi	a0,a0,1204 # ffffffffc0202d68 <best_fit_pmm_manager+0x140>
}
ffffffffc02018bc:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018be:	845fe06f          	j	ffffffffc0200102 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018c2:	c8000637          	lui	a2,0xc8000
ffffffffc02018c6:	bf05                	j	ffffffffc02017f6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018c8:	6705                	lui	a4,0x1
ffffffffc02018ca:	177d                	addi	a4,a4,-1
ffffffffc02018cc:	96ba                	add	a3,a3,a4
ffffffffc02018ce:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018d0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018d4:	02c7f063          	bgeu	a5,a2,ffffffffc02018f4 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02018d8:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02018da:	fff80737          	lui	a4,0xfff80
ffffffffc02018de:	973e                	add	a4,a4,a5
ffffffffc02018e0:	00271793          	slli	a5,a4,0x2
ffffffffc02018e4:	97ba                	add	a5,a5,a4
ffffffffc02018e6:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02018e8:	8d95                	sub	a1,a1,a3
ffffffffc02018ea:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02018ec:	81b1                	srli	a1,a1,0xc
ffffffffc02018ee:	953e                	add	a0,a0,a5
ffffffffc02018f0:	9702                	jalr	a4
}
ffffffffc02018f2:	bfbd                	j	ffffffffc0201870 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02018f4:	00001617          	auipc	a2,0x1
ffffffffc02018f8:	42460613          	addi	a2,a2,1060 # ffffffffc0202d18 <best_fit_pmm_manager+0xf0>
ffffffffc02018fc:	06b00593          	li	a1,107
ffffffffc0201900:	00001517          	auipc	a0,0x1
ffffffffc0201904:	43850513          	addi	a0,a0,1080 # ffffffffc0202d38 <best_fit_pmm_manager+0x110>
ffffffffc0201908:	af5fe0ef          	jal	ra,ffffffffc02003fc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020190c:	00001617          	auipc	a2,0x1
ffffffffc0201910:	3e460613          	addi	a2,a2,996 # ffffffffc0202cf0 <best_fit_pmm_manager+0xc8>
ffffffffc0201914:	07100593          	li	a1,113
ffffffffc0201918:	00001517          	auipc	a0,0x1
ffffffffc020191c:	38050513          	addi	a0,a0,896 # ffffffffc0202c98 <best_fit_pmm_manager+0x70>
ffffffffc0201920:	addfe0ef          	jal	ra,ffffffffc02003fc <__panic>
        panic("DTB memory info not available");
ffffffffc0201924:	00001617          	auipc	a2,0x1
ffffffffc0201928:	35460613          	addi	a2,a2,852 # ffffffffc0202c78 <best_fit_pmm_manager+0x50>
ffffffffc020192c:	05a00593          	li	a1,90
ffffffffc0201930:	00001517          	auipc	a0,0x1
ffffffffc0201934:	36850513          	addi	a0,a0,872 # ffffffffc0202c98 <best_fit_pmm_manager+0x70>
ffffffffc0201938:	ac5fe0ef          	jal	ra,ffffffffc02003fc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020193c:	86ae                	mv	a3,a1
ffffffffc020193e:	00001617          	auipc	a2,0x1
ffffffffc0201942:	3b260613          	addi	a2,a2,946 # ffffffffc0202cf0 <best_fit_pmm_manager+0xc8>
ffffffffc0201946:	08c00593          	li	a1,140
ffffffffc020194a:	00001517          	auipc	a0,0x1
ffffffffc020194e:	34e50513          	addi	a0,a0,846 # ffffffffc0202c98 <best_fit_pmm_manager+0x70>
ffffffffc0201952:	aabfe0ef          	jal	ra,ffffffffc02003fc <__panic>

ffffffffc0201956 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201956:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020195a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020195c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201960:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201962:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201966:	f022                	sd	s0,32(sp)
ffffffffc0201968:	ec26                	sd	s1,24(sp)
ffffffffc020196a:	e84a                	sd	s2,16(sp)
ffffffffc020196c:	f406                	sd	ra,40(sp)
ffffffffc020196e:	e44e                	sd	s3,8(sp)
ffffffffc0201970:	84aa                	mv	s1,a0
ffffffffc0201972:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201974:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201978:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020197a:	03067e63          	bgeu	a2,a6,ffffffffc02019b6 <printnum+0x60>
ffffffffc020197e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201980:	00805763          	blez	s0,ffffffffc020198e <printnum+0x38>
ffffffffc0201984:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201986:	85ca                	mv	a1,s2
ffffffffc0201988:	854e                	mv	a0,s3
ffffffffc020198a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020198c:	fc65                	bnez	s0,ffffffffc0201984 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020198e:	1a02                	slli	s4,s4,0x20
ffffffffc0201990:	00001797          	auipc	a5,0x1
ffffffffc0201994:	41878793          	addi	a5,a5,1048 # ffffffffc0202da8 <best_fit_pmm_manager+0x180>
ffffffffc0201998:	020a5a13          	srli	s4,s4,0x20
ffffffffc020199c:	9a3e                	add	s4,s4,a5
}
ffffffffc020199e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019a0:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019a4:	70a2                	ld	ra,40(sp)
ffffffffc02019a6:	69a2                	ld	s3,8(sp)
ffffffffc02019a8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019aa:	85ca                	mv	a1,s2
ffffffffc02019ac:	87a6                	mv	a5,s1
}
ffffffffc02019ae:	6942                	ld	s2,16(sp)
ffffffffc02019b0:	64e2                	ld	s1,24(sp)
ffffffffc02019b2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019b4:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019b6:	03065633          	divu	a2,a2,a6
ffffffffc02019ba:	8722                	mv	a4,s0
ffffffffc02019bc:	f9bff0ef          	jal	ra,ffffffffc0201956 <printnum>
ffffffffc02019c0:	b7f9                	j	ffffffffc020198e <printnum+0x38>

ffffffffc02019c2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019c2:	7119                	addi	sp,sp,-128
ffffffffc02019c4:	f4a6                	sd	s1,104(sp)
ffffffffc02019c6:	f0ca                	sd	s2,96(sp)
ffffffffc02019c8:	ecce                	sd	s3,88(sp)
ffffffffc02019ca:	e8d2                	sd	s4,80(sp)
ffffffffc02019cc:	e4d6                	sd	s5,72(sp)
ffffffffc02019ce:	e0da                	sd	s6,64(sp)
ffffffffc02019d0:	fc5e                	sd	s7,56(sp)
ffffffffc02019d2:	f06a                	sd	s10,32(sp)
ffffffffc02019d4:	fc86                	sd	ra,120(sp)
ffffffffc02019d6:	f8a2                	sd	s0,112(sp)
ffffffffc02019d8:	f862                	sd	s8,48(sp)
ffffffffc02019da:	f466                	sd	s9,40(sp)
ffffffffc02019dc:	ec6e                	sd	s11,24(sp)
ffffffffc02019de:	892a                	mv	s2,a0
ffffffffc02019e0:	84ae                	mv	s1,a1
ffffffffc02019e2:	8d32                	mv	s10,a2
ffffffffc02019e4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019e6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02019ea:	5b7d                	li	s6,-1
ffffffffc02019ec:	00001a97          	auipc	s5,0x1
ffffffffc02019f0:	3f0a8a93          	addi	s5,s5,1008 # ffffffffc0202ddc <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019f4:	00001b97          	auipc	s7,0x1
ffffffffc02019f8:	5c4b8b93          	addi	s7,s7,1476 # ffffffffc0202fb8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019fc:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a00:	001d0413          	addi	s0,s10,1
ffffffffc0201a04:	01350a63          	beq	a0,s3,ffffffffc0201a18 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a08:	c121                	beqz	a0,ffffffffc0201a48 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a0a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a0c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a0e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a10:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a14:	ff351ae3          	bne	a0,s3,ffffffffc0201a08 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a18:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a1c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a20:	4c81                	li	s9,0
ffffffffc0201a22:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a24:	5c7d                	li	s8,-1
ffffffffc0201a26:	5dfd                	li	s11,-1
ffffffffc0201a28:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a2c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a2e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a32:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a36:	00140d13          	addi	s10,s0,1
ffffffffc0201a3a:	04b56263          	bltu	a0,a1,ffffffffc0201a7e <vprintfmt+0xbc>
ffffffffc0201a3e:	058a                	slli	a1,a1,0x2
ffffffffc0201a40:	95d6                	add	a1,a1,s5
ffffffffc0201a42:	4194                	lw	a3,0(a1)
ffffffffc0201a44:	96d6                	add	a3,a3,s5
ffffffffc0201a46:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a48:	70e6                	ld	ra,120(sp)
ffffffffc0201a4a:	7446                	ld	s0,112(sp)
ffffffffc0201a4c:	74a6                	ld	s1,104(sp)
ffffffffc0201a4e:	7906                	ld	s2,96(sp)
ffffffffc0201a50:	69e6                	ld	s3,88(sp)
ffffffffc0201a52:	6a46                	ld	s4,80(sp)
ffffffffc0201a54:	6aa6                	ld	s5,72(sp)
ffffffffc0201a56:	6b06                	ld	s6,64(sp)
ffffffffc0201a58:	7be2                	ld	s7,56(sp)
ffffffffc0201a5a:	7c42                	ld	s8,48(sp)
ffffffffc0201a5c:	7ca2                	ld	s9,40(sp)
ffffffffc0201a5e:	7d02                	ld	s10,32(sp)
ffffffffc0201a60:	6de2                	ld	s11,24(sp)
ffffffffc0201a62:	6109                	addi	sp,sp,128
ffffffffc0201a64:	8082                	ret
            padc = '0';
ffffffffc0201a66:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a68:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a6c:	846a                	mv	s0,s10
ffffffffc0201a6e:	00140d13          	addi	s10,s0,1
ffffffffc0201a72:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a76:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a7a:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a3e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201a7e:	85a6                	mv	a1,s1
ffffffffc0201a80:	02500513          	li	a0,37
ffffffffc0201a84:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a86:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a8a:	8d22                	mv	s10,s0
ffffffffc0201a8c:	f73788e3          	beq	a5,s3,ffffffffc02019fc <vprintfmt+0x3a>
ffffffffc0201a90:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a94:	1d7d                	addi	s10,s10,-1
ffffffffc0201a96:	ff379de3          	bne	a5,s3,ffffffffc0201a90 <vprintfmt+0xce>
ffffffffc0201a9a:	b78d                	j	ffffffffc02019fc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201a9c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201aa0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa4:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201aa6:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201aaa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201aae:	02d86463          	bltu	a6,a3,ffffffffc0201ad6 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201ab2:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201ab6:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201aba:	0186873b          	addw	a4,a3,s8
ffffffffc0201abe:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201ac2:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201ac4:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201ac8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201aca:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201ace:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201ad2:	fed870e3          	bgeu	a6,a3,ffffffffc0201ab2 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201ad6:	f40ddce3          	bgez	s11,ffffffffc0201a2e <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201ada:	8de2                	mv	s11,s8
ffffffffc0201adc:	5c7d                	li	s8,-1
ffffffffc0201ade:	bf81                	j	ffffffffc0201a2e <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201ae0:	fffdc693          	not	a3,s11
ffffffffc0201ae4:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ae6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aea:	00144603          	lbu	a2,1(s0)
ffffffffc0201aee:	2d81                	sext.w	s11,s11
ffffffffc0201af0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201af2:	bf35                	j	ffffffffc0201a2e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201af4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201afc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201afe:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b00:	bfd9                	j	ffffffffc0201ad6 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b02:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b04:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b08:	01174463          	blt	a4,a7,ffffffffc0201b10 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b0c:	1a088e63          	beqz	a7,ffffffffc0201cc8 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b10:	000a3603          	ld	a2,0(s4)
ffffffffc0201b14:	46c1                	li	a3,16
ffffffffc0201b16:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b18:	2781                	sext.w	a5,a5
ffffffffc0201b1a:	876e                	mv	a4,s11
ffffffffc0201b1c:	85a6                	mv	a1,s1
ffffffffc0201b1e:	854a                	mv	a0,s2
ffffffffc0201b20:	e37ff0ef          	jal	ra,ffffffffc0201956 <printnum>
            break;
ffffffffc0201b24:	bde1                	j	ffffffffc02019fc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b26:	000a2503          	lw	a0,0(s4)
ffffffffc0201b2a:	85a6                	mv	a1,s1
ffffffffc0201b2c:	0a21                	addi	s4,s4,8
ffffffffc0201b2e:	9902                	jalr	s2
            break;
ffffffffc0201b30:	b5f1                	j	ffffffffc02019fc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b32:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b34:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b38:	01174463          	blt	a4,a7,ffffffffc0201b40 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b3c:	18088163          	beqz	a7,ffffffffc0201cbe <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b40:	000a3603          	ld	a2,0(s4)
ffffffffc0201b44:	46a9                	li	a3,10
ffffffffc0201b46:	8a2e                	mv	s4,a1
ffffffffc0201b48:	bfc1                	j	ffffffffc0201b18 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b4a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b4e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b50:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b52:	bdf1                	j	ffffffffc0201a2e <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b54:	85a6                	mv	a1,s1
ffffffffc0201b56:	02500513          	li	a0,37
ffffffffc0201b5a:	9902                	jalr	s2
            break;
ffffffffc0201b5c:	b545                	j	ffffffffc02019fc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b5e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b62:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b64:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b66:	b5e1                	j	ffffffffc0201a2e <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b68:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b6a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b6e:	01174463          	blt	a4,a7,ffffffffc0201b76 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b72:	14088163          	beqz	a7,ffffffffc0201cb4 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b76:	000a3603          	ld	a2,0(s4)
ffffffffc0201b7a:	46a1                	li	a3,8
ffffffffc0201b7c:	8a2e                	mv	s4,a1
ffffffffc0201b7e:	bf69                	j	ffffffffc0201b18 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201b80:	03000513          	li	a0,48
ffffffffc0201b84:	85a6                	mv	a1,s1
ffffffffc0201b86:	e03e                	sd	a5,0(sp)
ffffffffc0201b88:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b8a:	85a6                	mv	a1,s1
ffffffffc0201b8c:	07800513          	li	a0,120
ffffffffc0201b90:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b92:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b94:	6782                	ld	a5,0(sp)
ffffffffc0201b96:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b98:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201b9c:	bfb5                	j	ffffffffc0201b18 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b9e:	000a3403          	ld	s0,0(s4)
ffffffffc0201ba2:	008a0713          	addi	a4,s4,8
ffffffffc0201ba6:	e03a                	sd	a4,0(sp)
ffffffffc0201ba8:	14040263          	beqz	s0,ffffffffc0201cec <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201bac:	0fb05763          	blez	s11,ffffffffc0201c9a <vprintfmt+0x2d8>
ffffffffc0201bb0:	02d00693          	li	a3,45
ffffffffc0201bb4:	0cd79163          	bne	a5,a3,ffffffffc0201c76 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bb8:	00044783          	lbu	a5,0(s0)
ffffffffc0201bbc:	0007851b          	sext.w	a0,a5
ffffffffc0201bc0:	cf85                	beqz	a5,ffffffffc0201bf8 <vprintfmt+0x236>
ffffffffc0201bc2:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bc6:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bca:	000c4563          	bltz	s8,ffffffffc0201bd4 <vprintfmt+0x212>
ffffffffc0201bce:	3c7d                	addiw	s8,s8,-1
ffffffffc0201bd0:	036c0263          	beq	s8,s6,ffffffffc0201bf4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201bd4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bd6:	0e0c8e63          	beqz	s9,ffffffffc0201cd2 <vprintfmt+0x310>
ffffffffc0201bda:	3781                	addiw	a5,a5,-32
ffffffffc0201bdc:	0ef47b63          	bgeu	s0,a5,ffffffffc0201cd2 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201be0:	03f00513          	li	a0,63
ffffffffc0201be4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201be6:	000a4783          	lbu	a5,0(s4)
ffffffffc0201bea:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bec:	0a05                	addi	s4,s4,1
ffffffffc0201bee:	0007851b          	sext.w	a0,a5
ffffffffc0201bf2:	ffe1                	bnez	a5,ffffffffc0201bca <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201bf4:	01b05963          	blez	s11,ffffffffc0201c06 <vprintfmt+0x244>
ffffffffc0201bf8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201bfa:	85a6                	mv	a1,s1
ffffffffc0201bfc:	02000513          	li	a0,32
ffffffffc0201c00:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c02:	fe0d9be3          	bnez	s11,ffffffffc0201bf8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c06:	6a02                	ld	s4,0(sp)
ffffffffc0201c08:	bbd5                	j	ffffffffc02019fc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c0a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c0c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c10:	01174463          	blt	a4,a7,ffffffffc0201c18 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c14:	08088d63          	beqz	a7,ffffffffc0201cae <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c18:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c1c:	0a044d63          	bltz	s0,ffffffffc0201cd6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c20:	8622                	mv	a2,s0
ffffffffc0201c22:	8a66                	mv	s4,s9
ffffffffc0201c24:	46a9                	li	a3,10
ffffffffc0201c26:	bdcd                	j	ffffffffc0201b18 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c28:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c2c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c2e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c30:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c34:	8fb5                	xor	a5,a5,a3
ffffffffc0201c36:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c3a:	02d74163          	blt	a4,a3,ffffffffc0201c5c <vprintfmt+0x29a>
ffffffffc0201c3e:	00369793          	slli	a5,a3,0x3
ffffffffc0201c42:	97de                	add	a5,a5,s7
ffffffffc0201c44:	639c                	ld	a5,0(a5)
ffffffffc0201c46:	cb99                	beqz	a5,ffffffffc0201c5c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c48:	86be                	mv	a3,a5
ffffffffc0201c4a:	00001617          	auipc	a2,0x1
ffffffffc0201c4e:	18e60613          	addi	a2,a2,398 # ffffffffc0202dd8 <best_fit_pmm_manager+0x1b0>
ffffffffc0201c52:	85a6                	mv	a1,s1
ffffffffc0201c54:	854a                	mv	a0,s2
ffffffffc0201c56:	0ce000ef          	jal	ra,ffffffffc0201d24 <printfmt>
ffffffffc0201c5a:	b34d                	j	ffffffffc02019fc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c5c:	00001617          	auipc	a2,0x1
ffffffffc0201c60:	16c60613          	addi	a2,a2,364 # ffffffffc0202dc8 <best_fit_pmm_manager+0x1a0>
ffffffffc0201c64:	85a6                	mv	a1,s1
ffffffffc0201c66:	854a                	mv	a0,s2
ffffffffc0201c68:	0bc000ef          	jal	ra,ffffffffc0201d24 <printfmt>
ffffffffc0201c6c:	bb41                	j	ffffffffc02019fc <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c6e:	00001417          	auipc	s0,0x1
ffffffffc0201c72:	15240413          	addi	s0,s0,338 # ffffffffc0202dc0 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c76:	85e2                	mv	a1,s8
ffffffffc0201c78:	8522                	mv	a0,s0
ffffffffc0201c7a:	e43e                	sd	a5,8(sp)
ffffffffc0201c7c:	200000ef          	jal	ra,ffffffffc0201e7c <strnlen>
ffffffffc0201c80:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c84:	01b05b63          	blez	s11,ffffffffc0201c9a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201c88:	67a2                	ld	a5,8(sp)
ffffffffc0201c8a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c8e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201c90:	85a6                	mv	a1,s1
ffffffffc0201c92:	8552                	mv	a0,s4
ffffffffc0201c94:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c96:	fe0d9ce3          	bnez	s11,ffffffffc0201c8e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c9a:	00044783          	lbu	a5,0(s0)
ffffffffc0201c9e:	00140a13          	addi	s4,s0,1
ffffffffc0201ca2:	0007851b          	sext.w	a0,a5
ffffffffc0201ca6:	d3a5                	beqz	a5,ffffffffc0201c06 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ca8:	05e00413          	li	s0,94
ffffffffc0201cac:	bf39                	j	ffffffffc0201bca <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201cae:	000a2403          	lw	s0,0(s4)
ffffffffc0201cb2:	b7ad                	j	ffffffffc0201c1c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cb4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cb8:	46a1                	li	a3,8
ffffffffc0201cba:	8a2e                	mv	s4,a1
ffffffffc0201cbc:	bdb1                	j	ffffffffc0201b18 <vprintfmt+0x156>
ffffffffc0201cbe:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cc2:	46a9                	li	a3,10
ffffffffc0201cc4:	8a2e                	mv	s4,a1
ffffffffc0201cc6:	bd89                	j	ffffffffc0201b18 <vprintfmt+0x156>
ffffffffc0201cc8:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ccc:	46c1                	li	a3,16
ffffffffc0201cce:	8a2e                	mv	s4,a1
ffffffffc0201cd0:	b5a1                	j	ffffffffc0201b18 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201cd2:	9902                	jalr	s2
ffffffffc0201cd4:	bf09                	j	ffffffffc0201be6 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201cd6:	85a6                	mv	a1,s1
ffffffffc0201cd8:	02d00513          	li	a0,45
ffffffffc0201cdc:	e03e                	sd	a5,0(sp)
ffffffffc0201cde:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201ce0:	6782                	ld	a5,0(sp)
ffffffffc0201ce2:	8a66                	mv	s4,s9
ffffffffc0201ce4:	40800633          	neg	a2,s0
ffffffffc0201ce8:	46a9                	li	a3,10
ffffffffc0201cea:	b53d                	j	ffffffffc0201b18 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201cec:	03b05163          	blez	s11,ffffffffc0201d0e <vprintfmt+0x34c>
ffffffffc0201cf0:	02d00693          	li	a3,45
ffffffffc0201cf4:	f6d79de3          	bne	a5,a3,ffffffffc0201c6e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201cf8:	00001417          	auipc	s0,0x1
ffffffffc0201cfc:	0c840413          	addi	s0,s0,200 # ffffffffc0202dc0 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d00:	02800793          	li	a5,40
ffffffffc0201d04:	02800513          	li	a0,40
ffffffffc0201d08:	00140a13          	addi	s4,s0,1
ffffffffc0201d0c:	bd6d                	j	ffffffffc0201bc6 <vprintfmt+0x204>
ffffffffc0201d0e:	00001a17          	auipc	s4,0x1
ffffffffc0201d12:	0b3a0a13          	addi	s4,s4,179 # ffffffffc0202dc1 <best_fit_pmm_manager+0x199>
ffffffffc0201d16:	02800513          	li	a0,40
ffffffffc0201d1a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d1e:	05e00413          	li	s0,94
ffffffffc0201d22:	b565                	j	ffffffffc0201bca <vprintfmt+0x208>

ffffffffc0201d24 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d24:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d26:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d2a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d2c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d2e:	ec06                	sd	ra,24(sp)
ffffffffc0201d30:	f83a                	sd	a4,48(sp)
ffffffffc0201d32:	fc3e                	sd	a5,56(sp)
ffffffffc0201d34:	e0c2                	sd	a6,64(sp)
ffffffffc0201d36:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d38:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d3a:	c89ff0ef          	jal	ra,ffffffffc02019c2 <vprintfmt>
}
ffffffffc0201d3e:	60e2                	ld	ra,24(sp)
ffffffffc0201d40:	6161                	addi	sp,sp,80
ffffffffc0201d42:	8082                	ret

ffffffffc0201d44 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d44:	715d                	addi	sp,sp,-80
ffffffffc0201d46:	e486                	sd	ra,72(sp)
ffffffffc0201d48:	e0a6                	sd	s1,64(sp)
ffffffffc0201d4a:	fc4a                	sd	s2,56(sp)
ffffffffc0201d4c:	f84e                	sd	s3,48(sp)
ffffffffc0201d4e:	f452                	sd	s4,40(sp)
ffffffffc0201d50:	f056                	sd	s5,32(sp)
ffffffffc0201d52:	ec5a                	sd	s6,24(sp)
ffffffffc0201d54:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d56:	c901                	beqz	a0,ffffffffc0201d66 <readline+0x22>
ffffffffc0201d58:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d5a:	00001517          	auipc	a0,0x1
ffffffffc0201d5e:	07e50513          	addi	a0,a0,126 # ffffffffc0202dd8 <best_fit_pmm_manager+0x1b0>
ffffffffc0201d62:	ba0fe0ef          	jal	ra,ffffffffc0200102 <cprintf>
readline(const char *prompt) {
ffffffffc0201d66:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d68:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d6a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d6c:	4aa9                	li	s5,10
ffffffffc0201d6e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d70:	00004b97          	auipc	s7,0x4
ffffffffc0201d74:	2d0b8b93          	addi	s7,s7,720 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d78:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201d7c:	bfefe0ef          	jal	ra,ffffffffc020017a <getchar>
        if (c < 0) {
ffffffffc0201d80:	00054a63          	bltz	a0,ffffffffc0201d94 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d84:	00a95a63          	bge	s2,a0,ffffffffc0201d98 <readline+0x54>
ffffffffc0201d88:	029a5263          	bge	s4,s1,ffffffffc0201dac <readline+0x68>
        c = getchar();
ffffffffc0201d8c:	beefe0ef          	jal	ra,ffffffffc020017a <getchar>
        if (c < 0) {
ffffffffc0201d90:	fe055ae3          	bgez	a0,ffffffffc0201d84 <readline+0x40>
            return NULL;
ffffffffc0201d94:	4501                	li	a0,0
ffffffffc0201d96:	a091                	j	ffffffffc0201dda <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201d98:	03351463          	bne	a0,s3,ffffffffc0201dc0 <readline+0x7c>
ffffffffc0201d9c:	e8a9                	bnez	s1,ffffffffc0201dee <readline+0xaa>
        c = getchar();
ffffffffc0201d9e:	bdcfe0ef          	jal	ra,ffffffffc020017a <getchar>
        if (c < 0) {
ffffffffc0201da2:	fe0549e3          	bltz	a0,ffffffffc0201d94 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201da6:	fea959e3          	bge	s2,a0,ffffffffc0201d98 <readline+0x54>
ffffffffc0201daa:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201dac:	e42a                	sd	a0,8(sp)
ffffffffc0201dae:	b8afe0ef          	jal	ra,ffffffffc0200138 <cputchar>
            buf[i ++] = c;
ffffffffc0201db2:	6522                	ld	a0,8(sp)
ffffffffc0201db4:	009b87b3          	add	a5,s7,s1
ffffffffc0201db8:	2485                	addiw	s1,s1,1
ffffffffc0201dba:	00a78023          	sb	a0,0(a5)
ffffffffc0201dbe:	bf7d                	j	ffffffffc0201d7c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201dc0:	01550463          	beq	a0,s5,ffffffffc0201dc8 <readline+0x84>
ffffffffc0201dc4:	fb651ce3          	bne	a0,s6,ffffffffc0201d7c <readline+0x38>
            cputchar(c);
ffffffffc0201dc8:	b70fe0ef          	jal	ra,ffffffffc0200138 <cputchar>
            buf[i] = '\0';
ffffffffc0201dcc:	00004517          	auipc	a0,0x4
ffffffffc0201dd0:	27450513          	addi	a0,a0,628 # ffffffffc0206040 <buf>
ffffffffc0201dd4:	94aa                	add	s1,s1,a0
ffffffffc0201dd6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201dda:	60a6                	ld	ra,72(sp)
ffffffffc0201ddc:	6486                	ld	s1,64(sp)
ffffffffc0201dde:	7962                	ld	s2,56(sp)
ffffffffc0201de0:	79c2                	ld	s3,48(sp)
ffffffffc0201de2:	7a22                	ld	s4,40(sp)
ffffffffc0201de4:	7a82                	ld	s5,32(sp)
ffffffffc0201de6:	6b62                	ld	s6,24(sp)
ffffffffc0201de8:	6bc2                	ld	s7,16(sp)
ffffffffc0201dea:	6161                	addi	sp,sp,80
ffffffffc0201dec:	8082                	ret
            cputchar(c);
ffffffffc0201dee:	4521                	li	a0,8
ffffffffc0201df0:	b48fe0ef          	jal	ra,ffffffffc0200138 <cputchar>
            i --;
ffffffffc0201df4:	34fd                	addiw	s1,s1,-1
ffffffffc0201df6:	b759                	j	ffffffffc0201d7c <readline+0x38>

ffffffffc0201df8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201df8:	4781                	li	a5,0
ffffffffc0201dfa:	00004717          	auipc	a4,0x4
ffffffffc0201dfe:	21e73703          	ld	a4,542(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e02:	88ba                	mv	a7,a4
ffffffffc0201e04:	852a                	mv	a0,a0
ffffffffc0201e06:	85be                	mv	a1,a5
ffffffffc0201e08:	863e                	mv	a2,a5
ffffffffc0201e0a:	00000073          	ecall
ffffffffc0201e0e:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e10:	8082                	ret

ffffffffc0201e12 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e12:	4781                	li	a5,0
ffffffffc0201e14:	00004717          	auipc	a4,0x4
ffffffffc0201e18:	68473703          	ld	a4,1668(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e1c:	88ba                	mv	a7,a4
ffffffffc0201e1e:	852a                	mv	a0,a0
ffffffffc0201e20:	85be                	mv	a1,a5
ffffffffc0201e22:	863e                	mv	a2,a5
ffffffffc0201e24:	00000073          	ecall
ffffffffc0201e28:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e2a:	8082                	ret

ffffffffc0201e2c <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e2c:	4501                	li	a0,0
ffffffffc0201e2e:	00004797          	auipc	a5,0x4
ffffffffc0201e32:	1e27b783          	ld	a5,482(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e36:	88be                	mv	a7,a5
ffffffffc0201e38:	852a                	mv	a0,a0
ffffffffc0201e3a:	85aa                	mv	a1,a0
ffffffffc0201e3c:	862a                	mv	a2,a0
ffffffffc0201e3e:	00000073          	ecall
ffffffffc0201e42:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e44:	2501                	sext.w	a0,a0
ffffffffc0201e46:	8082                	ret

ffffffffc0201e48 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e48:	4781                	li	a5,0
ffffffffc0201e4a:	00004717          	auipc	a4,0x4
ffffffffc0201e4e:	1d673703          	ld	a4,470(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e52:	88ba                	mv	a7,a4
ffffffffc0201e54:	853e                	mv	a0,a5
ffffffffc0201e56:	85be                	mv	a1,a5
ffffffffc0201e58:	863e                	mv	a2,a5
ffffffffc0201e5a:	00000073          	ecall
ffffffffc0201e5e:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e60:	8082                	ret

ffffffffc0201e62 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e62:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e66:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e68:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e6a:	cb81                	beqz	a5,ffffffffc0201e7a <strlen+0x18>
        cnt ++;
ffffffffc0201e6c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e6e:	00a707b3          	add	a5,a4,a0
ffffffffc0201e72:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e76:	fbfd                	bnez	a5,ffffffffc0201e6c <strlen+0xa>
ffffffffc0201e78:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e7a:	8082                	ret

ffffffffc0201e7c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e7c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e7e:	e589                	bnez	a1,ffffffffc0201e88 <strnlen+0xc>
ffffffffc0201e80:	a811                	j	ffffffffc0201e94 <strnlen+0x18>
        cnt ++;
ffffffffc0201e82:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e84:	00f58863          	beq	a1,a5,ffffffffc0201e94 <strnlen+0x18>
ffffffffc0201e88:	00f50733          	add	a4,a0,a5
ffffffffc0201e8c:	00074703          	lbu	a4,0(a4)
ffffffffc0201e90:	fb6d                	bnez	a4,ffffffffc0201e82 <strnlen+0x6>
ffffffffc0201e92:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e94:	852e                	mv	a0,a1
ffffffffc0201e96:	8082                	ret

ffffffffc0201e98 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e98:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e9c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ea0:	cb89                	beqz	a5,ffffffffc0201eb2 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201ea2:	0505                	addi	a0,a0,1
ffffffffc0201ea4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ea6:	fee789e3          	beq	a5,a4,ffffffffc0201e98 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eaa:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201eae:	9d19                	subw	a0,a0,a4
ffffffffc0201eb0:	8082                	ret
ffffffffc0201eb2:	4501                	li	a0,0
ffffffffc0201eb4:	bfed                	j	ffffffffc0201eae <strcmp+0x16>

ffffffffc0201eb6 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201eb6:	c20d                	beqz	a2,ffffffffc0201ed8 <strncmp+0x22>
ffffffffc0201eb8:	962e                	add	a2,a2,a1
ffffffffc0201eba:	a031                	j	ffffffffc0201ec6 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201ebc:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ebe:	00e79a63          	bne	a5,a4,ffffffffc0201ed2 <strncmp+0x1c>
ffffffffc0201ec2:	00b60b63          	beq	a2,a1,ffffffffc0201ed8 <strncmp+0x22>
ffffffffc0201ec6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201eca:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ecc:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201ed0:	f7f5                	bnez	a5,ffffffffc0201ebc <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201ed6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed8:	4501                	li	a0,0
ffffffffc0201eda:	8082                	ret

ffffffffc0201edc <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201edc:	00054783          	lbu	a5,0(a0)
ffffffffc0201ee0:	c799                	beqz	a5,ffffffffc0201eee <strchr+0x12>
        if (*s == c) {
ffffffffc0201ee2:	00f58763          	beq	a1,a5,ffffffffc0201ef0 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201ee6:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201eea:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201eec:	fbfd                	bnez	a5,ffffffffc0201ee2 <strchr+0x6>
    }
    return NULL;
ffffffffc0201eee:	4501                	li	a0,0
}
ffffffffc0201ef0:	8082                	ret

ffffffffc0201ef2 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ef2:	ca01                	beqz	a2,ffffffffc0201f02 <memset+0x10>
ffffffffc0201ef4:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ef6:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ef8:	0785                	addi	a5,a5,1
ffffffffc0201efa:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201efe:	fec79de3          	bne	a5,a2,ffffffffc0201ef8 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f02:	8082                	ret
