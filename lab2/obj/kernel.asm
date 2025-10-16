
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
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	f5450513          	addi	a0,a0,-172 # ffffffffc0201fa0 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	f5e50513          	addi	a0,a0,-162 # ffffffffc0201fc0 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	f2e58593          	addi	a1,a1,-210 # ffffffffc0201f9c <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	f6a50513          	addi	a0,a0,-150 # ffffffffc0201fe0 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	f7650513          	addi	a0,a0,-138 # ffffffffc0202000 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	2e258593          	addi	a1,a1,738 # ffffffffc0206378 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	f8250513          	addi	a0,a0,-126 # ffffffffc0202020 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	6cd58593          	addi	a1,a1,1741 # ffffffffc0206777 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	f7450513          	addi	a0,a0,-140 # ffffffffc0202040 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	29860613          	addi	a2,a2,664 # ffffffffc0206378 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	69b010ef          	jal	ra,ffffffffc0201f8a <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	f7450513          	addi	a0,a0,-140 # ffffffffc0202070 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	6eb000ef          	jal	ra,ffffffffc0200ff6 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
ffffffffc020011e:	401c                	lw	a5,0(s0)
ffffffffc0200120:	60a2                	ld	ra,8(sp)
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
ffffffffc020013c:	ec06                	sd	ra,24(sp)
ffffffffc020013e:	c602                	sw	zero,12(sp)
ffffffffc0200140:	1d3010ef          	jal	ra,ffffffffc0201b12 <vprintfmt>
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
ffffffffc020014c:	711d                	addi	sp,sp,-96
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
ffffffffc0200172:	e41a                	sd	t1,8(sp)
ffffffffc0200174:	c202                	sw	zero,4(sp)
ffffffffc0200176:	19d010ef          	jal	ra,ffffffffc0201b12 <vprintfmt>
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	16e30313          	addi	t1,t1,366 # ffffffffc0206330 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	e9e50513          	addi	a0,a0,-354 # ffffffffc0202090 <etext+0xf4>
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	e6050513          	addi	a0,a0,-416 # ffffffffc0202068 <etext+0xcc>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	4bf0106f          	j	ffffffffc0201eda <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	e8e50513          	addi	a0,a0,-370 # ffffffffc02020b0 <etext+0x114>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	e7050513          	addi	a0,a0,-400 # ffffffffc02020c0 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	e6a50513          	addi	a0,a0,-406 # ffffffffc02020d0 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	e7250513          	addi	a0,a0,-398 # ffffffffc02020e8 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9b75>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	e0890913          	addi	s2,s2,-504 # ffffffffc0202138 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	df248493          	addi	s1,s1,-526 # ffffffffc0202130 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	e1e50513          	addi	a0,a0,-482 # ffffffffc02021b0 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	e4a50513          	addi	a0,a0,-438 # ffffffffc02021e8 <etext+0x24c>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202108 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	309010ef          	jal	ra,ffffffffc0201ef4 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	36b010ef          	jal	ra,ffffffffc0201f64 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	2b7010ef          	jal	ra,ffffffffc0201f46 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	c9c50513          	addi	a0,a0,-868 # ffffffffc0202140 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00002517          	auipc	a0,0x2
ffffffffc0200576:	bee50513          	addi	a0,a0,-1042 # ffffffffc0202160 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	bf450513          	addi	a0,a0,-1036 # ffffffffc0202178 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202198 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	c4650513          	addi	a0,a0,-954 # ffffffffc02021e8 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	d887b723          	sd	s0,-626(a5) # ffffffffc0206338 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	d967b723          	sd	s6,-626(a5) # ffffffffc0206340 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	d7c53503          	ld	a0,-644(a0) # ffffffffc0206338 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	d7a53503          	ld	a0,-646(a0) # ffffffffc0206340 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0206018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	00006517          	auipc	a0,0x6
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005ec:	cd49                	beqz	a0,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02005ee:	00006617          	auipc	a2,0x6
ffffffffc02005f2:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0206018 <free_area>
ffffffffc02005f6:	01062803          	lw	a6,16(a2)
ffffffffc02005fa:	86aa                	mv	a3,a0
ffffffffc02005fc:	02081793          	slli	a5,a6,0x20
ffffffffc0200600:	9381                	srli	a5,a5,0x20
ffffffffc0200602:	08a7e063          	bltu	a5,a0,ffffffffc0200682 <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200606:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200608:	0018059b          	addiw	a1,a6,1
ffffffffc020060c:	1582                	slli	a1,a1,0x20
ffffffffc020060e:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200610:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200612:	06c78763          	beq	a5,a2,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200616:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020061a:	00d76763          	bltu	a4,a3,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
ffffffffc020061e:	00b77563          	bgeu	a4,a1,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200622:	fe878513          	addi	a0,a5,-24
ffffffffc0200626:	85ba                	mv	a1,a4
ffffffffc0200628:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020062a:	fec796e3          	bne	a5,a2,ffffffffc0200616 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc020062e:	c929                	beqz	a0,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc0200630:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200634:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200636:	710c                	ld	a1,32(a0)
ffffffffc0200638:	02089793          	slli	a5,a7,0x20
ffffffffc020063c:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020063e:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200640:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc0200642:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200646:	02f6f563          	bgeu	a3,a5,ffffffffc0200670 <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020064a:	00269793          	slli	a5,a3,0x2
ffffffffc020064e:	97b6                	add	a5,a5,a3
ffffffffc0200650:	0792                	slli	a5,a5,0x4
ffffffffc0200652:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200654:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200656:	406888bb          	subw	a7,a7,t1
ffffffffc020065a:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc020065e:	0026e693          	ori	a3,a3,2
ffffffffc0200662:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200664:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200668:	e194                	sd	a3,0(a1)
ffffffffc020066a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020066c:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc020066e:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200670:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200672:	4068083b          	subw	a6,a6,t1
ffffffffc0200676:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc020067a:	9bf5                	andi	a5,a5,-3
ffffffffc020067c:	e51c                	sd	a5,8(a0)
ffffffffc020067e:	8082                	ret
}
ffffffffc0200680:	8082                	ret
        return NULL;
ffffffffc0200682:	4501                	li	a0,0
ffffffffc0200684:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200686:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200688:	00002697          	auipc	a3,0x2
ffffffffc020068c:	b7868693          	addi	a3,a3,-1160 # ffffffffc0202200 <etext+0x264>
ffffffffc0200690:	00002617          	auipc	a2,0x2
ffffffffc0200694:	b7860613          	addi	a2,a2,-1160 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200698:	06a00593          	li	a1,106
ffffffffc020069c:	00002517          	auipc	a0,0x2
ffffffffc02006a0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0202220 <etext+0x284>
best_fit_alloc_pages(size_t n) {
ffffffffc02006a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006a6:	b1dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006aa <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02006aa:	715d                	addi	sp,sp,-80
ffffffffc02006ac:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006ae:	00006417          	auipc	s0,0x6
ffffffffc02006b2:	96a40413          	addi	s0,s0,-1686 # ffffffffc0206018 <free_area>
ffffffffc02006b6:	641c                	ld	a5,8(s0)
ffffffffc02006b8:	e486                	sd	ra,72(sp)
ffffffffc02006ba:	fc26                	sd	s1,56(sp)
ffffffffc02006bc:	f84a                	sd	s2,48(sp)
ffffffffc02006be:	f44e                	sd	s3,40(sp)
ffffffffc02006c0:	f052                	sd	s4,32(sp)
ffffffffc02006c2:	ec56                	sd	s5,24(sp)
ffffffffc02006c4:	e85a                	sd	s6,16(sp)
ffffffffc02006c6:	e45e                	sd	s7,8(sp)
ffffffffc02006c8:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ca:	26878963          	beq	a5,s0,ffffffffc020093c <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02006ce:	4481                	li	s1,0
ffffffffc02006d0:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006d2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006d6:	8b09                	andi	a4,a4,2
ffffffffc02006d8:	26070663          	beqz	a4,ffffffffc0200944 <best_fit_check+0x29a>
        count ++, total += p->property;
ffffffffc02006dc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006e0:	679c                	ld	a5,8(a5)
ffffffffc02006e2:	2905                	addiw	s2,s2,1
ffffffffc02006e4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006e6:	fe8796e3          	bne	a5,s0,ffffffffc02006d2 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006ea:	89a6                	mv	s3,s1
ffffffffc02006ec:	0ff000ef          	jal	ra,ffffffffc0200fea <nr_free_pages>
ffffffffc02006f0:	33351a63          	bne	a0,s3,ffffffffc0200a24 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006f4:	4505                	li	a0,1
ffffffffc02006f6:	0dd000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02006fa:	8a2a                	mv	s4,a0
ffffffffc02006fc:	36050463          	beqz	a0,ffffffffc0200a64 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200700:	4505                	li	a0,1
ffffffffc0200702:	0d1000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200706:	89aa                	mv	s3,a0
ffffffffc0200708:	32050e63          	beqz	a0,ffffffffc0200a44 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020070c:	4505                	li	a0,1
ffffffffc020070e:	0c5000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200712:	8aaa                	mv	s5,a0
ffffffffc0200714:	2c050863          	beqz	a0,ffffffffc02009e4 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200718:	253a0663          	beq	s4,s3,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc020071c:	24aa0463          	beq	s4,a0,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc0200720:	24a98263          	beq	s3,a0,ffffffffc0200964 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200724:	000a2783          	lw	a5,0(s4)
ffffffffc0200728:	24079e63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc020072c:	0009a783          	lw	a5,0(s3)
ffffffffc0200730:	24079a63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc0200734:	411c                	lw	a5,0(a0)
ffffffffc0200736:	24079763          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020073a:	00006797          	auipc	a5,0x6
ffffffffc020073e:	c167b783          	ld	a5,-1002(a5) # ffffffffc0206350 <pages>
ffffffffc0200742:	40fa0733          	sub	a4,s4,a5
ffffffffc0200746:	8711                	srai	a4,a4,0x4
ffffffffc0200748:	00002597          	auipc	a1,0x2
ffffffffc020074c:	7885b583          	ld	a1,1928(a1) # ffffffffc0202ed0 <error_string+0x38>
ffffffffc0200750:	02b70733          	mul	a4,a4,a1
ffffffffc0200754:	00002617          	auipc	a2,0x2
ffffffffc0200758:	78463603          	ld	a2,1924(a2) # ffffffffc0202ed8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020075c:	00006697          	auipc	a3,0x6
ffffffffc0200760:	bec6b683          	ld	a3,-1044(a3) # ffffffffc0206348 <npage>
ffffffffc0200764:	06b2                	slli	a3,a3,0xc
ffffffffc0200766:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200768:	0732                	slli	a4,a4,0xc
ffffffffc020076a:	22d77d63          	bgeu	a4,a3,ffffffffc02009a4 <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020076e:	40f98733          	sub	a4,s3,a5
ffffffffc0200772:	8711                	srai	a4,a4,0x4
ffffffffc0200774:	02b70733          	mul	a4,a4,a1
ffffffffc0200778:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020077a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020077c:	3ed77463          	bgeu	a4,a3,ffffffffc0200b64 <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200780:	40f507b3          	sub	a5,a0,a5
ffffffffc0200784:	8791                	srai	a5,a5,0x4
ffffffffc0200786:	02b787b3          	mul	a5,a5,a1
ffffffffc020078a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020078c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020078e:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200b44 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200792:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200794:	00043c03          	ld	s8,0(s0)
ffffffffc0200798:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020079c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007a0:	e400                	sd	s0,8(s0)
ffffffffc02007a2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007a4:	00006797          	auipc	a5,0x6
ffffffffc02007a8:	8807a223          	sw	zero,-1916(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007ac:	027000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007b0:	36051a63          	bnez	a0,ffffffffc0200b24 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02007b4:	4585                	li	a1,1
ffffffffc02007b6:	8552                	mv	a0,s4
ffffffffc02007b8:	027000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p1);
ffffffffc02007bc:	4585                	li	a1,1
ffffffffc02007be:	854e                	mv	a0,s3
ffffffffc02007c0:	01f000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p2);
ffffffffc02007c4:	4585                	li	a1,1
ffffffffc02007c6:	8556                	mv	a0,s5
ffffffffc02007c8:	017000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(nr_free == 3);
ffffffffc02007cc:	4818                	lw	a4,16(s0)
ffffffffc02007ce:	478d                	li	a5,3
ffffffffc02007d0:	32f71a63          	bne	a4,a5,ffffffffc0200b04 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007d4:	4505                	li	a0,1
ffffffffc02007d6:	7fc000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007da:	89aa                	mv	s3,a0
ffffffffc02007dc:	30050463          	beqz	a0,ffffffffc0200ae4 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007e0:	4505                	li	a0,1
ffffffffc02007e2:	7f0000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007e6:	8aaa                	mv	s5,a0
ffffffffc02007e8:	2c050e63          	beqz	a0,ffffffffc0200ac4 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007ec:	4505                	li	a0,1
ffffffffc02007ee:	7e4000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007f2:	8a2a                	mv	s4,a0
ffffffffc02007f4:	2a050863          	beqz	a0,ffffffffc0200aa4 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc02007f8:	4505                	li	a0,1
ffffffffc02007fa:	7d8000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007fe:	28051363          	bnez	a0,ffffffffc0200a84 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200802:	4585                	li	a1,1
ffffffffc0200804:	854e                	mv	a0,s3
ffffffffc0200806:	7d8000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020080a:	641c                	ld	a5,8(s0)
ffffffffc020080c:	1a878c63          	beq	a5,s0,ffffffffc02009c4 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200810:	4505                	li	a0,1
ffffffffc0200812:	7c0000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200816:	52a99763          	bne	s3,a0,ffffffffc0200d44 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc020081a:	4505                	li	a0,1
ffffffffc020081c:	7b6000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200820:	50051263          	bnez	a0,ffffffffc0200d24 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200824:	481c                	lw	a5,16(s0)
ffffffffc0200826:	4c079f63          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x65a>
    free_page(p);
ffffffffc020082a:	854e                	mv	a0,s3
ffffffffc020082c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020082e:	01843023          	sd	s8,0(s0)
ffffffffc0200832:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200836:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020083a:	7a4000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p1);
ffffffffc020083e:	4585                	li	a1,1
ffffffffc0200840:	8556                	mv	a0,s5
ffffffffc0200842:	79c000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p2);
ffffffffc0200846:	4585                	li	a1,1
ffffffffc0200848:	8552                	mv	a0,s4
ffffffffc020084a:	794000ef          	jal	ra,ffffffffc0200fde <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020084e:	4515                	li	a0,5
ffffffffc0200850:	782000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200854:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200856:	48050763          	beqz	a0,ffffffffc0200ce4 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc020085a:	651c                	ld	a5,8(a0)
ffffffffc020085c:	8b89                	andi	a5,a5,2
ffffffffc020085e:	46079363          	bnez	a5,ffffffffc0200cc4 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200862:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200864:	00043b03          	ld	s6,0(s0)
ffffffffc0200868:	00843a83          	ld	s5,8(s0)
ffffffffc020086c:	e000                	sd	s0,0(s0)
ffffffffc020086e:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200870:	762000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200874:	42051863          	bnez	a0,ffffffffc0200ca4 <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200878:	4589                	li	a1,2
ffffffffc020087a:	05098513          	addi	a0,s3,80
    unsigned int nr_free_store = nr_free;
ffffffffc020087e:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200882:	14098c13          	addi	s8,s3,320
    nr_free = 0;
ffffffffc0200886:	00005797          	auipc	a5,0x5
ffffffffc020088a:	7a07a123          	sw	zero,1954(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc020088e:	750000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200892:	8562                	mv	a0,s8
ffffffffc0200894:	4585                	li	a1,1
ffffffffc0200896:	748000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020089a:	4511                	li	a0,4
ffffffffc020089c:	736000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008a0:	3e051263          	bnez	a0,ffffffffc0200c84 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008a4:	0589b783          	ld	a5,88(s3)
ffffffffc02008a8:	8b89                	andi	a5,a5,2
ffffffffc02008aa:	3a078d63          	beqz	a5,ffffffffc0200c64 <best_fit_check+0x5ba>
ffffffffc02008ae:	0609a703          	lw	a4,96(s3)
ffffffffc02008b2:	4789                	li	a5,2
ffffffffc02008b4:	3af71863          	bne	a4,a5,ffffffffc0200c64 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008b8:	4505                	li	a0,1
ffffffffc02008ba:	718000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008be:	8a2a                	mv	s4,a0
ffffffffc02008c0:	38050263          	beqz	a0,ffffffffc0200c44 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008c4:	4509                	li	a0,2
ffffffffc02008c6:	70c000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008ca:	34050d63          	beqz	a0,ffffffffc0200c24 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc02008ce:	334c1b63          	bne	s8,s4,ffffffffc0200c04 <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008d2:	854e                	mv	a0,s3
ffffffffc02008d4:	4595                	li	a1,5
ffffffffc02008d6:	708000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008da:	4515                	li	a0,5
ffffffffc02008dc:	6f6000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008e0:	89aa                	mv	s3,a0
ffffffffc02008e2:	30050163          	beqz	a0,ffffffffc0200be4 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc02008e6:	4505                	li	a0,1
ffffffffc02008e8:	6ea000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008ec:	2c051c63          	bnez	a0,ffffffffc0200bc4 <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008f0:	481c                	lw	a5,16(s0)
ffffffffc02008f2:	2a079963          	bnez	a5,ffffffffc0200ba4 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008f6:	4595                	li	a1,5
ffffffffc02008f8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008fa:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02008fe:	01643023          	sd	s6,0(s0)
ffffffffc0200902:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200906:	6d8000ef          	jal	ra,ffffffffc0200fde <free_pages>
    return listelm->next;
ffffffffc020090a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	00878963          	beq	a5,s0,ffffffffc020091e <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200910:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200914:	679c                	ld	a5,8(a5)
ffffffffc0200916:	397d                	addiw	s2,s2,-1
ffffffffc0200918:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020091a:	fe879be3          	bne	a5,s0,ffffffffc0200910 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc020091e:	26091363          	bnez	s2,ffffffffc0200b84 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200922:	e0ed                	bnez	s1,ffffffffc0200a04 <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200924:	60a6                	ld	ra,72(sp)
ffffffffc0200926:	6406                	ld	s0,64(sp)
ffffffffc0200928:	74e2                	ld	s1,56(sp)
ffffffffc020092a:	7942                	ld	s2,48(sp)
ffffffffc020092c:	79a2                	ld	s3,40(sp)
ffffffffc020092e:	7a02                	ld	s4,32(sp)
ffffffffc0200930:	6ae2                	ld	s5,24(sp)
ffffffffc0200932:	6b42                	ld	s6,16(sp)
ffffffffc0200934:	6ba2                	ld	s7,8(sp)
ffffffffc0200936:	6c02                	ld	s8,0(sp)
ffffffffc0200938:	6161                	addi	sp,sp,80
ffffffffc020093a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020093c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020093e:	4481                	li	s1,0
ffffffffc0200940:	4901                	li	s2,0
ffffffffc0200942:	b36d                	j	ffffffffc02006ec <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200944:	00002697          	auipc	a3,0x2
ffffffffc0200948:	8f468693          	addi	a3,a3,-1804 # ffffffffc0202238 <etext+0x29c>
ffffffffc020094c:	00002617          	auipc	a2,0x2
ffffffffc0200950:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200954:	10c00593          	li	a1,268
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	8c850513          	addi	a0,a0,-1848 # ffffffffc0202220 <etext+0x284>
ffffffffc0200960:	863ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200964:	00002697          	auipc	a3,0x2
ffffffffc0200968:	96468693          	addi	a3,a3,-1692 # ffffffffc02022c8 <etext+0x32c>
ffffffffc020096c:	00002617          	auipc	a2,0x2
ffffffffc0200970:	89c60613          	addi	a2,a2,-1892 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200974:	0d800593          	li	a1,216
ffffffffc0200978:	00002517          	auipc	a0,0x2
ffffffffc020097c:	8a850513          	addi	a0,a0,-1880 # ffffffffc0202220 <etext+0x284>
ffffffffc0200980:	843ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200984:	00002697          	auipc	a3,0x2
ffffffffc0200988:	96c68693          	addi	a3,a3,-1684 # ffffffffc02022f0 <etext+0x354>
ffffffffc020098c:	00002617          	auipc	a2,0x2
ffffffffc0200990:	87c60613          	addi	a2,a2,-1924 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200994:	0d900593          	li	a1,217
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	88850513          	addi	a0,a0,-1912 # ffffffffc0202220 <etext+0x284>
ffffffffc02009a0:	823ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009a4:	00002697          	auipc	a3,0x2
ffffffffc02009a8:	98c68693          	addi	a3,a3,-1652 # ffffffffc0202330 <etext+0x394>
ffffffffc02009ac:	00002617          	auipc	a2,0x2
ffffffffc02009b0:	85c60613          	addi	a2,a2,-1956 # ffffffffc0202208 <etext+0x26c>
ffffffffc02009b4:	0db00593          	li	a1,219
ffffffffc02009b8:	00002517          	auipc	a0,0x2
ffffffffc02009bc:	86850513          	addi	a0,a0,-1944 # ffffffffc0202220 <etext+0x284>
ffffffffc02009c0:	803ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009c4:	00002697          	auipc	a3,0x2
ffffffffc02009c8:	9f468693          	addi	a3,a3,-1548 # ffffffffc02023b8 <etext+0x41c>
ffffffffc02009cc:	00002617          	auipc	a2,0x2
ffffffffc02009d0:	83c60613          	addi	a2,a2,-1988 # ffffffffc0202208 <etext+0x26c>
ffffffffc02009d4:	0f400593          	li	a1,244
ffffffffc02009d8:	00002517          	auipc	a0,0x2
ffffffffc02009dc:	84850513          	addi	a0,a0,-1976 # ffffffffc0202220 <etext+0x284>
ffffffffc02009e0:	fe2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e4:	00002697          	auipc	a3,0x2
ffffffffc02009e8:	8c468693          	addi	a3,a3,-1852 # ffffffffc02022a8 <etext+0x30c>
ffffffffc02009ec:	00002617          	auipc	a2,0x2
ffffffffc02009f0:	81c60613          	addi	a2,a2,-2020 # ffffffffc0202208 <etext+0x26c>
ffffffffc02009f4:	0d600593          	li	a1,214
ffffffffc02009f8:	00002517          	auipc	a0,0x2
ffffffffc02009fc:	82850513          	addi	a0,a0,-2008 # ffffffffc0202220 <etext+0x284>
ffffffffc0200a00:	fc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200a04:	00002697          	auipc	a3,0x2
ffffffffc0200a08:	ae468693          	addi	a3,a3,-1308 # ffffffffc02024e8 <etext+0x54c>
ffffffffc0200a0c:	00001617          	auipc	a2,0x1
ffffffffc0200a10:	7fc60613          	addi	a2,a2,2044 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200a14:	14e00593          	li	a1,334
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	80850513          	addi	a0,a0,-2040 # ffffffffc0202220 <etext+0x284>
ffffffffc0200a20:	fa2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a24:	00002697          	auipc	a3,0x2
ffffffffc0200a28:	82468693          	addi	a3,a3,-2012 # ffffffffc0202248 <etext+0x2ac>
ffffffffc0200a2c:	00001617          	auipc	a2,0x1
ffffffffc0200a30:	7dc60613          	addi	a2,a2,2012 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200a34:	10f00593          	li	a1,271
ffffffffc0200a38:	00001517          	auipc	a0,0x1
ffffffffc0200a3c:	7e850513          	addi	a0,a0,2024 # ffffffffc0202220 <etext+0x284>
ffffffffc0200a40:	f82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a44:	00002697          	auipc	a3,0x2
ffffffffc0200a48:	84468693          	addi	a3,a3,-1980 # ffffffffc0202288 <etext+0x2ec>
ffffffffc0200a4c:	00001617          	auipc	a2,0x1
ffffffffc0200a50:	7bc60613          	addi	a2,a2,1980 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200a54:	0d500593          	li	a1,213
ffffffffc0200a58:	00001517          	auipc	a0,0x1
ffffffffc0200a5c:	7c850513          	addi	a0,a0,1992 # ffffffffc0202220 <etext+0x284>
ffffffffc0200a60:	f62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a64:	00002697          	auipc	a3,0x2
ffffffffc0200a68:	80468693          	addi	a3,a3,-2044 # ffffffffc0202268 <etext+0x2cc>
ffffffffc0200a6c:	00001617          	auipc	a2,0x1
ffffffffc0200a70:	79c60613          	addi	a2,a2,1948 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200a74:	0d400593          	li	a1,212
ffffffffc0200a78:	00001517          	auipc	a0,0x1
ffffffffc0200a7c:	7a850513          	addi	a0,a0,1960 # ffffffffc0202220 <etext+0x284>
ffffffffc0200a80:	f42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a84:	00002697          	auipc	a3,0x2
ffffffffc0200a88:	90c68693          	addi	a3,a3,-1780 # ffffffffc0202390 <etext+0x3f4>
ffffffffc0200a8c:	00001617          	auipc	a2,0x1
ffffffffc0200a90:	77c60613          	addi	a2,a2,1916 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200a94:	0f100593          	li	a1,241
ffffffffc0200a98:	00001517          	auipc	a0,0x1
ffffffffc0200a9c:	78850513          	addi	a0,a0,1928 # ffffffffc0202220 <etext+0x284>
ffffffffc0200aa0:	f22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aa4:	00002697          	auipc	a3,0x2
ffffffffc0200aa8:	80468693          	addi	a3,a3,-2044 # ffffffffc02022a8 <etext+0x30c>
ffffffffc0200aac:	00001617          	auipc	a2,0x1
ffffffffc0200ab0:	75c60613          	addi	a2,a2,1884 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200ab4:	0ef00593          	li	a1,239
ffffffffc0200ab8:	00001517          	auipc	a0,0x1
ffffffffc0200abc:	76850513          	addi	a0,a0,1896 # ffffffffc0202220 <etext+0x284>
ffffffffc0200ac0:	f02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ac4:	00001697          	auipc	a3,0x1
ffffffffc0200ac8:	7c468693          	addi	a3,a3,1988 # ffffffffc0202288 <etext+0x2ec>
ffffffffc0200acc:	00001617          	auipc	a2,0x1
ffffffffc0200ad0:	73c60613          	addi	a2,a2,1852 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200ad4:	0ee00593          	li	a1,238
ffffffffc0200ad8:	00001517          	auipc	a0,0x1
ffffffffc0200adc:	74850513          	addi	a0,a0,1864 # ffffffffc0202220 <etext+0x284>
ffffffffc0200ae0:	ee2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ae4:	00001697          	auipc	a3,0x1
ffffffffc0200ae8:	78468693          	addi	a3,a3,1924 # ffffffffc0202268 <etext+0x2cc>
ffffffffc0200aec:	00001617          	auipc	a2,0x1
ffffffffc0200af0:	71c60613          	addi	a2,a2,1820 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200af4:	0ed00593          	li	a1,237
ffffffffc0200af8:	00001517          	auipc	a0,0x1
ffffffffc0200afc:	72850513          	addi	a0,a0,1832 # ffffffffc0202220 <etext+0x284>
ffffffffc0200b00:	ec2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200b04:	00002697          	auipc	a3,0x2
ffffffffc0200b08:	8a468693          	addi	a3,a3,-1884 # ffffffffc02023a8 <etext+0x40c>
ffffffffc0200b0c:	00001617          	auipc	a2,0x1
ffffffffc0200b10:	6fc60613          	addi	a2,a2,1788 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200b14:	0eb00593          	li	a1,235
ffffffffc0200b18:	00001517          	auipc	a0,0x1
ffffffffc0200b1c:	70850513          	addi	a0,a0,1800 # ffffffffc0202220 <etext+0x284>
ffffffffc0200b20:	ea2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b24:	00002697          	auipc	a3,0x2
ffffffffc0200b28:	86c68693          	addi	a3,a3,-1940 # ffffffffc0202390 <etext+0x3f4>
ffffffffc0200b2c:	00001617          	auipc	a2,0x1
ffffffffc0200b30:	6dc60613          	addi	a2,a2,1756 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200b34:	0e600593          	li	a1,230
ffffffffc0200b38:	00001517          	auipc	a0,0x1
ffffffffc0200b3c:	6e850513          	addi	a0,a0,1768 # ffffffffc0202220 <etext+0x284>
ffffffffc0200b40:	e82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b44:	00002697          	auipc	a3,0x2
ffffffffc0200b48:	82c68693          	addi	a3,a3,-2004 # ffffffffc0202370 <etext+0x3d4>
ffffffffc0200b4c:	00001617          	auipc	a2,0x1
ffffffffc0200b50:	6bc60613          	addi	a2,a2,1724 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200b54:	0dd00593          	li	a1,221
ffffffffc0200b58:	00001517          	auipc	a0,0x1
ffffffffc0200b5c:	6c850513          	addi	a0,a0,1736 # ffffffffc0202220 <etext+0x284>
ffffffffc0200b60:	e62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b64:	00001697          	auipc	a3,0x1
ffffffffc0200b68:	7ec68693          	addi	a3,a3,2028 # ffffffffc0202350 <etext+0x3b4>
ffffffffc0200b6c:	00001617          	auipc	a2,0x1
ffffffffc0200b70:	69c60613          	addi	a2,a2,1692 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200b74:	0dc00593          	li	a1,220
ffffffffc0200b78:	00001517          	auipc	a0,0x1
ffffffffc0200b7c:	6a850513          	addi	a0,a0,1704 # ffffffffc0202220 <etext+0x284>
ffffffffc0200b80:	e42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200b84:	00002697          	auipc	a3,0x2
ffffffffc0200b88:	95468693          	addi	a3,a3,-1708 # ffffffffc02024d8 <etext+0x53c>
ffffffffc0200b8c:	00001617          	auipc	a2,0x1
ffffffffc0200b90:	67c60613          	addi	a2,a2,1660 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200b94:	14d00593          	li	a1,333
ffffffffc0200b98:	00001517          	auipc	a0,0x1
ffffffffc0200b9c:	68850513          	addi	a0,a0,1672 # ffffffffc0202220 <etext+0x284>
ffffffffc0200ba0:	e22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200ba4:	00002697          	auipc	a3,0x2
ffffffffc0200ba8:	84c68693          	addi	a3,a3,-1972 # ffffffffc02023f0 <etext+0x454>
ffffffffc0200bac:	00001617          	auipc	a2,0x1
ffffffffc0200bb0:	65c60613          	addi	a2,a2,1628 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200bb4:	14200593          	li	a1,322
ffffffffc0200bb8:	00001517          	auipc	a0,0x1
ffffffffc0200bbc:	66850513          	addi	a0,a0,1640 # ffffffffc0202220 <etext+0x284>
ffffffffc0200bc0:	e02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bc4:	00001697          	auipc	a3,0x1
ffffffffc0200bc8:	7cc68693          	addi	a3,a3,1996 # ffffffffc0202390 <etext+0x3f4>
ffffffffc0200bcc:	00001617          	auipc	a2,0x1
ffffffffc0200bd0:	63c60613          	addi	a2,a2,1596 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200bd4:	13c00593          	li	a1,316
ffffffffc0200bd8:	00001517          	auipc	a0,0x1
ffffffffc0200bdc:	64850513          	addi	a0,a0,1608 # ffffffffc0202220 <etext+0x284>
ffffffffc0200be0:	de2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200be4:	00002697          	auipc	a3,0x2
ffffffffc0200be8:	8d468693          	addi	a3,a3,-1836 # ffffffffc02024b8 <etext+0x51c>
ffffffffc0200bec:	00001617          	auipc	a2,0x1
ffffffffc0200bf0:	61c60613          	addi	a2,a2,1564 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200bf4:	13b00593          	li	a1,315
ffffffffc0200bf8:	00001517          	auipc	a0,0x1
ffffffffc0200bfc:	62850513          	addi	a0,a0,1576 # ffffffffc0202220 <etext+0x284>
ffffffffc0200c00:	dc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c04:	00002697          	auipc	a3,0x2
ffffffffc0200c08:	8a468693          	addi	a3,a3,-1884 # ffffffffc02024a8 <etext+0x50c>
ffffffffc0200c0c:	00001617          	auipc	a2,0x1
ffffffffc0200c10:	5fc60613          	addi	a2,a2,1532 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200c14:	13300593          	li	a1,307
ffffffffc0200c18:	00001517          	auipc	a0,0x1
ffffffffc0200c1c:	60850513          	addi	a0,a0,1544 # ffffffffc0202220 <etext+0x284>
ffffffffc0200c20:	da2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c24:	00002697          	auipc	a3,0x2
ffffffffc0200c28:	86c68693          	addi	a3,a3,-1940 # ffffffffc0202490 <etext+0x4f4>
ffffffffc0200c2c:	00001617          	auipc	a2,0x1
ffffffffc0200c30:	5dc60613          	addi	a2,a2,1500 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200c34:	13200593          	li	a1,306
ffffffffc0200c38:	00001517          	auipc	a0,0x1
ffffffffc0200c3c:	5e850513          	addi	a0,a0,1512 # ffffffffc0202220 <etext+0x284>
ffffffffc0200c40:	d82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c44:	00002697          	auipc	a3,0x2
ffffffffc0200c48:	82c68693          	addi	a3,a3,-2004 # ffffffffc0202470 <etext+0x4d4>
ffffffffc0200c4c:	00001617          	auipc	a2,0x1
ffffffffc0200c50:	5bc60613          	addi	a2,a2,1468 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200c54:	13100593          	li	a1,305
ffffffffc0200c58:	00001517          	auipc	a0,0x1
ffffffffc0200c5c:	5c850513          	addi	a0,a0,1480 # ffffffffc0202220 <etext+0x284>
ffffffffc0200c60:	d62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c64:	00001697          	auipc	a3,0x1
ffffffffc0200c68:	7dc68693          	addi	a3,a3,2012 # ffffffffc0202440 <etext+0x4a4>
ffffffffc0200c6c:	00001617          	auipc	a2,0x1
ffffffffc0200c70:	59c60613          	addi	a2,a2,1436 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200c74:	12f00593          	li	a1,303
ffffffffc0200c78:	00001517          	auipc	a0,0x1
ffffffffc0200c7c:	5a850513          	addi	a0,a0,1448 # ffffffffc0202220 <etext+0x284>
ffffffffc0200c80:	d42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c84:	00001697          	auipc	a3,0x1
ffffffffc0200c88:	7a468693          	addi	a3,a3,1956 # ffffffffc0202428 <etext+0x48c>
ffffffffc0200c8c:	00001617          	auipc	a2,0x1
ffffffffc0200c90:	57c60613          	addi	a2,a2,1404 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200c94:	12e00593          	li	a1,302
ffffffffc0200c98:	00001517          	auipc	a0,0x1
ffffffffc0200c9c:	58850513          	addi	a0,a0,1416 # ffffffffc0202220 <etext+0x284>
ffffffffc0200ca0:	d22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ca4:	00001697          	auipc	a3,0x1
ffffffffc0200ca8:	6ec68693          	addi	a3,a3,1772 # ffffffffc0202390 <etext+0x3f4>
ffffffffc0200cac:	00001617          	auipc	a2,0x1
ffffffffc0200cb0:	55c60613          	addi	a2,a2,1372 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200cb4:	12200593          	li	a1,290
ffffffffc0200cb8:	00001517          	auipc	a0,0x1
ffffffffc0200cbc:	56850513          	addi	a0,a0,1384 # ffffffffc0202220 <etext+0x284>
ffffffffc0200cc0:	d02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cc4:	00001697          	auipc	a3,0x1
ffffffffc0200cc8:	74c68693          	addi	a3,a3,1868 # ffffffffc0202410 <etext+0x474>
ffffffffc0200ccc:	00001617          	auipc	a2,0x1
ffffffffc0200cd0:	53c60613          	addi	a2,a2,1340 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200cd4:	11900593          	li	a1,281
ffffffffc0200cd8:	00001517          	auipc	a0,0x1
ffffffffc0200cdc:	54850513          	addi	a0,a0,1352 # ffffffffc0202220 <etext+0x284>
ffffffffc0200ce0:	ce2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200ce4:	00001697          	auipc	a3,0x1
ffffffffc0200ce8:	71c68693          	addi	a3,a3,1820 # ffffffffc0202400 <etext+0x464>
ffffffffc0200cec:	00001617          	auipc	a2,0x1
ffffffffc0200cf0:	51c60613          	addi	a2,a2,1308 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200cf4:	11800593          	li	a1,280
ffffffffc0200cf8:	00001517          	auipc	a0,0x1
ffffffffc0200cfc:	52850513          	addi	a0,a0,1320 # ffffffffc0202220 <etext+0x284>
ffffffffc0200d00:	cc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200d04:	00001697          	auipc	a3,0x1
ffffffffc0200d08:	6ec68693          	addi	a3,a3,1772 # ffffffffc02023f0 <etext+0x454>
ffffffffc0200d0c:	00001617          	auipc	a2,0x1
ffffffffc0200d10:	4fc60613          	addi	a2,a2,1276 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200d14:	0fa00593          	li	a1,250
ffffffffc0200d18:	00001517          	auipc	a0,0x1
ffffffffc0200d1c:	50850513          	addi	a0,a0,1288 # ffffffffc0202220 <etext+0x284>
ffffffffc0200d20:	ca2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d24:	00001697          	auipc	a3,0x1
ffffffffc0200d28:	66c68693          	addi	a3,a3,1644 # ffffffffc0202390 <etext+0x3f4>
ffffffffc0200d2c:	00001617          	auipc	a2,0x1
ffffffffc0200d30:	4dc60613          	addi	a2,a2,1244 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200d34:	0f800593          	li	a1,248
ffffffffc0200d38:	00001517          	auipc	a0,0x1
ffffffffc0200d3c:	4e850513          	addi	a0,a0,1256 # ffffffffc0202220 <etext+0x284>
ffffffffc0200d40:	c82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d44:	00001697          	auipc	a3,0x1
ffffffffc0200d48:	68c68693          	addi	a3,a3,1676 # ffffffffc02023d0 <etext+0x434>
ffffffffc0200d4c:	00001617          	auipc	a2,0x1
ffffffffc0200d50:	4bc60613          	addi	a2,a2,1212 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200d54:	0f700593          	li	a1,247
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	4c850513          	addi	a0,a0,1224 # ffffffffc0202220 <etext+0x284>
ffffffffc0200d60:	c62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d64 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d64:	1141                	addi	sp,sp,-16
ffffffffc0200d66:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d68:	14058c63          	beqz	a1,ffffffffc0200ec0 <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0200d6c:	00259693          	slli	a3,a1,0x2
ffffffffc0200d70:	96ae                	add	a3,a3,a1
ffffffffc0200d72:	0692                	slli	a3,a3,0x4
ffffffffc0200d74:	96aa                	add	a3,a3,a0
ffffffffc0200d76:	87aa                	mv	a5,a0
ffffffffc0200d78:	00d50e63          	beq	a0,a3,ffffffffc0200d94 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d7c:	6798                	ld	a4,8(a5)
ffffffffc0200d7e:	8b0d                	andi	a4,a4,3
ffffffffc0200d80:	12071063          	bnez	a4,ffffffffc0200ea0 <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc0200d84:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d88:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d8c:	05078793          	addi	a5,a5,80
ffffffffc0200d90:	fed796e3          	bne	a5,a3,ffffffffc0200d7c <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d94:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200d98:	00005697          	auipc	a3,0x5
ffffffffc0200d9c:	28068693          	addi	a3,a3,640 # ffffffffc0206018 <free_area>
ffffffffc0200da0:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200da2:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200da4:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc0200da8:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200daa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dac:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200dae:	9f2d                	addw	a4,a4,a1
ffffffffc0200db0:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200db2:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200db6:	0ad78b63          	beq	a5,a3,ffffffffc0200e6c <best_fit_free_pages+0x108>
            struct Page* page = le2page(le, page_link);
ffffffffc0200dba:	fe878713          	addi	a4,a5,-24
ffffffffc0200dbe:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dc2:	4801                	li	a6,0
            if (base < page) {
ffffffffc0200dc4:	00e56a63          	bltu	a0,a4,ffffffffc0200dd8 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200dc8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dca:	06d70563          	beq	a4,a3,ffffffffc0200e34 <best_fit_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200dce:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200dd0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dd4:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dc8 <best_fit_free_pages+0x64>
ffffffffc0200dd8:	00080463          	beqz	a6,ffffffffc0200de0 <best_fit_free_pages+0x7c>
ffffffffc0200ddc:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200de0:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200de4:	e390                	sd	a2,0(a5)
ffffffffc0200de6:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200dea:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200dec:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200df0:	02d80463          	beq	a6,a3,ffffffffc0200e18 <best_fit_free_pages+0xb4>
        if (p + p->property == base) {
ffffffffc0200df4:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200df8:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200dfc:	020e1613          	slli	a2,t3,0x20
ffffffffc0200e00:	9201                	srli	a2,a2,0x20
ffffffffc0200e02:	00261713          	slli	a4,a2,0x2
ffffffffc0200e06:	9732                	add	a4,a4,a2
ffffffffc0200e08:	0712                	slli	a4,a4,0x4
ffffffffc0200e0a:	971a                	add	a4,a4,t1
ffffffffc0200e0c:	02e50e63          	beq	a0,a4,ffffffffc0200e48 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e10:	00d78f63          	beq	a5,a3,ffffffffc0200e2e <best_fit_free_pages+0xca>
ffffffffc0200e14:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc0200e18:	490c                	lw	a1,16(a0)
ffffffffc0200e1a:	02059613          	slli	a2,a1,0x20
ffffffffc0200e1e:	9201                	srli	a2,a2,0x20
ffffffffc0200e20:	00261693          	slli	a3,a2,0x2
ffffffffc0200e24:	96b2                	add	a3,a3,a2
ffffffffc0200e26:	0692                	slli	a3,a3,0x4
ffffffffc0200e28:	96aa                	add	a3,a3,a0
ffffffffc0200e2a:	04d70863          	beq	a4,a3,ffffffffc0200e7a <best_fit_free_pages+0x116>
}
ffffffffc0200e2e:	60a2                	ld	ra,8(sp)
ffffffffc0200e30:	0141                	addi	sp,sp,16
ffffffffc0200e32:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e34:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e36:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e38:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e3a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3c:	02d70463          	beq	a4,a3,ffffffffc0200e64 <best_fit_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc0200e40:	8332                	mv	t1,a2
ffffffffc0200e42:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc0200e44:	87ba                	mv	a5,a4
ffffffffc0200e46:	b769                	j	ffffffffc0200dd0 <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e48:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e4c:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e50:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e54:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e58:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e5c:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e60:	851a                	mv	a0,t1
ffffffffc0200e62:	b77d                	j	ffffffffc0200e10 <best_fit_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e64:	883e                	mv	a6,a5
ffffffffc0200e66:	e290                	sd	a2,0(a3)
ffffffffc0200e68:	87b6                	mv	a5,a3
ffffffffc0200e6a:	b769                	j	ffffffffc0200df4 <best_fit_free_pages+0x90>
}
ffffffffc0200e6c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200e6e:	e390                	sd	a2,0(a5)
ffffffffc0200e70:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e72:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e74:	ed1c                	sd	a5,24(a0)
ffffffffc0200e76:	0141                	addi	sp,sp,16
ffffffffc0200e78:	8082                	ret
            base->property += p->property;
ffffffffc0200e7a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e7e:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e82:	0007b803          	ld	a6,0(a5)
ffffffffc0200e86:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e88:	9db5                	addw	a1,a1,a3
ffffffffc0200e8a:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200e8c:	9b75                	andi	a4,a4,-3
ffffffffc0200e8e:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e92:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e94:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e98:	01063023          	sd	a6,0(a2)
ffffffffc0200e9c:	0141                	addi	sp,sp,16
ffffffffc0200e9e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ea0:	00001697          	auipc	a3,0x1
ffffffffc0200ea4:	65868693          	addi	a3,a3,1624 # ffffffffc02024f8 <etext+0x55c>
ffffffffc0200ea8:	00001617          	auipc	a2,0x1
ffffffffc0200eac:	36060613          	addi	a2,a2,864 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200eb0:	09200593          	li	a1,146
ffffffffc0200eb4:	00001517          	auipc	a0,0x1
ffffffffc0200eb8:	36c50513          	addi	a0,a0,876 # ffffffffc0202220 <etext+0x284>
ffffffffc0200ebc:	b06ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200ec0:	00001697          	auipc	a3,0x1
ffffffffc0200ec4:	34068693          	addi	a3,a3,832 # ffffffffc0202200 <etext+0x264>
ffffffffc0200ec8:	00001617          	auipc	a2,0x1
ffffffffc0200ecc:	34060613          	addi	a2,a2,832 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200ed0:	08f00593          	li	a1,143
ffffffffc0200ed4:	00001517          	auipc	a0,0x1
ffffffffc0200ed8:	34c50513          	addi	a0,a0,844 # ffffffffc0202220 <etext+0x284>
ffffffffc0200edc:	ae6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ee0 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200ee0:	1141                	addi	sp,sp,-16
ffffffffc0200ee2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ee4:	c5f9                	beqz	a1,ffffffffc0200fb2 <best_fit_init_memmap+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0200ee6:	00259693          	slli	a3,a1,0x2
ffffffffc0200eea:	96ae                	add	a3,a3,a1
ffffffffc0200eec:	0692                	slli	a3,a3,0x4
ffffffffc0200eee:	96aa                	add	a3,a3,a0
ffffffffc0200ef0:	87aa                	mv	a5,a0
ffffffffc0200ef2:	00d50f63          	beq	a0,a3,ffffffffc0200f10 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ef6:	6798                	ld	a4,8(a5)
ffffffffc0200ef8:	8b05                	andi	a4,a4,1
ffffffffc0200efa:	cf41                	beqz	a4,ffffffffc0200f92 <best_fit_init_memmap+0xb2>
        p->flags = p->property = 0;
ffffffffc0200efc:	0007a823          	sw	zero,16(a5)
ffffffffc0200f00:	0007b423          	sd	zero,8(a5)
ffffffffc0200f04:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f08:	05078793          	addi	a5,a5,80
ffffffffc0200f0c:	fed795e3          	bne	a5,a3,ffffffffc0200ef6 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f10:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f12:	00005697          	auipc	a3,0x5
ffffffffc0200f16:	10668693          	addi	a3,a3,262 # ffffffffc0206018 <free_area>
ffffffffc0200f1a:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f1c:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200f1e:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc0200f22:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200f24:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f26:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f28:	9db9                	addw	a1,a1,a4
ffffffffc0200f2a:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f2c:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200f30:	04d78a63          	beq	a5,a3,ffffffffc0200f84 <best_fit_init_memmap+0xa4>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f34:	fe878713          	addi	a4,a5,-24
ffffffffc0200f38:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f3c:	4581                	li	a1,0
            if (base < page) {
ffffffffc0200f3e:	00e56a63          	bltu	a0,a4,ffffffffc0200f52 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f42:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f44:	02d70263          	beq	a4,a3,ffffffffc0200f68 <best_fit_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc0200f48:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f4a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f4e:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f42 <best_fit_init_memmap+0x62>
ffffffffc0200f52:	c199                	beqz	a1,ffffffffc0200f58 <best_fit_init_memmap+0x78>
ffffffffc0200f54:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f58:	6398                	ld	a4,0(a5)
}
ffffffffc0200f5a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f5c:	e390                	sd	a2,0(a5)
ffffffffc0200f5e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200f60:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f62:	ed18                	sd	a4,24(a0)
ffffffffc0200f64:	0141                	addi	sp,sp,16
ffffffffc0200f66:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f68:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f6a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f6c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f6e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f70:	00d70663          	beq	a4,a3,ffffffffc0200f7c <best_fit_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc0200f74:	8832                	mv	a6,a2
ffffffffc0200f76:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0200f78:	87ba                	mv	a5,a4
ffffffffc0200f7a:	bfc1                	j	ffffffffc0200f4a <best_fit_init_memmap+0x6a>
}
ffffffffc0200f7c:	60a2                	ld	ra,8(sp)
ffffffffc0200f7e:	e290                	sd	a2,0(a3)
ffffffffc0200f80:	0141                	addi	sp,sp,16
ffffffffc0200f82:	8082                	ret
ffffffffc0200f84:	60a2                	ld	ra,8(sp)
ffffffffc0200f86:	e390                	sd	a2,0(a5)
ffffffffc0200f88:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f8a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f8c:	ed1c                	sd	a5,24(a0)
ffffffffc0200f8e:	0141                	addi	sp,sp,16
ffffffffc0200f90:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f92:	00001697          	auipc	a3,0x1
ffffffffc0200f96:	58e68693          	addi	a3,a3,1422 # ffffffffc0202520 <etext+0x584>
ffffffffc0200f9a:	00001617          	auipc	a2,0x1
ffffffffc0200f9e:	26e60613          	addi	a2,a2,622 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200fa2:	04a00593          	li	a1,74
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	27a50513          	addi	a0,a0,634 # ffffffffc0202220 <etext+0x284>
ffffffffc0200fae:	a14ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200fb2:	00001697          	auipc	a3,0x1
ffffffffc0200fb6:	24e68693          	addi	a3,a3,590 # ffffffffc0202200 <etext+0x264>
ffffffffc0200fba:	00001617          	auipc	a2,0x1
ffffffffc0200fbe:	24e60613          	addi	a2,a2,590 # ffffffffc0202208 <etext+0x26c>
ffffffffc0200fc2:	04700593          	li	a1,71
ffffffffc0200fc6:	00001517          	auipc	a0,0x1
ffffffffc0200fca:	25a50513          	addi	a0,a0,602 # ffffffffc0202220 <etext+0x284>
ffffffffc0200fce:	9f4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200fd2 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fd2:	00005797          	auipc	a5,0x5
ffffffffc0200fd6:	3867b783          	ld	a5,902(a5) # ffffffffc0206358 <pmm_manager>
ffffffffc0200fda:	6f9c                	ld	a5,24(a5)
ffffffffc0200fdc:	8782                	jr	a5

ffffffffc0200fde <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fde:	00005797          	auipc	a5,0x5
ffffffffc0200fe2:	37a7b783          	ld	a5,890(a5) # ffffffffc0206358 <pmm_manager>
ffffffffc0200fe6:	739c                	ld	a5,32(a5)
ffffffffc0200fe8:	8782                	jr	a5

ffffffffc0200fea <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fea:	00005797          	auipc	a5,0x5
ffffffffc0200fee:	36e7b783          	ld	a5,878(a5) # ffffffffc0206358 <pmm_manager>
ffffffffc0200ff2:	779c                	ld	a5,40(a5)
ffffffffc0200ff4:	8782                	jr	a5

ffffffffc0200ff6 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ff6:	00001797          	auipc	a5,0x1
ffffffffc0200ffa:	55278793          	addi	a5,a5,1362 # ffffffffc0202548 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ffe:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201000:	7179                	addi	sp,sp,-48
ffffffffc0201002:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201004:	00001517          	auipc	a0,0x1
ffffffffc0201008:	57c50513          	addi	a0,a0,1404 # ffffffffc0202580 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020100c:	00005417          	auipc	s0,0x5
ffffffffc0201010:	34c40413          	addi	s0,s0,844 # ffffffffc0206358 <pmm_manager>
void pmm_init(void) {
ffffffffc0201014:	f406                	sd	ra,40(sp)
ffffffffc0201016:	ec26                	sd	s1,24(sp)
ffffffffc0201018:	e44e                	sd	s3,8(sp)
ffffffffc020101a:	e84a                	sd	s2,16(sp)
ffffffffc020101c:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020101e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201020:	92cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0201024:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201026:	00005497          	auipc	s1,0x5
ffffffffc020102a:	34a48493          	addi	s1,s1,842 # ffffffffc0206370 <va_pa_offset>
    pmm_manager->init();
ffffffffc020102e:	679c                	ld	a5,8(a5)
ffffffffc0201030:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201032:	57f5                	li	a5,-3
ffffffffc0201034:	07fa                	slli	a5,a5,0x1e
ffffffffc0201036:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201038:	d84ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc020103c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020103e:	d88ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201042:	16050063          	beqz	a0,ffffffffc02011a2 <pmm_init+0x1ac>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201046:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201048:	00001517          	auipc	a0,0x1
ffffffffc020104c:	58050513          	addi	a0,a0,1408 # ffffffffc02025c8 <best_fit_pmm_manager+0x80>
ffffffffc0201050:	8fcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201054:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201058:	864e                	mv	a2,s3
ffffffffc020105a:	fffa0693          	addi	a3,s4,-1
ffffffffc020105e:	85ca                	mv	a1,s2
ffffffffc0201060:	00001517          	auipc	a0,0x1
ffffffffc0201064:	58050513          	addi	a0,a0,1408 # ffffffffc02025e0 <best_fit_pmm_manager+0x98>
ffffffffc0201068:	8e4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020106c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201070:	8652                	mv	a2,s4
ffffffffc0201072:	0d47e763          	bltu	a5,s4,ffffffffc0201140 <pmm_init+0x14a>
ffffffffc0201076:	00006797          	auipc	a5,0x6
ffffffffc020107a:	30178793          	addi	a5,a5,769 # ffffffffc0207377 <end+0xfff>
ffffffffc020107e:	757d                	lui	a0,0xfffff
ffffffffc0201080:	8d7d                	and	a0,a0,a5
ffffffffc0201082:	8231                	srli	a2,a2,0xc
ffffffffc0201084:	00005797          	auipc	a5,0x5
ffffffffc0201088:	2cc7b223          	sd	a2,708(a5) # ffffffffc0206348 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020108c:	00005797          	auipc	a5,0x5
ffffffffc0201090:	2ca7b223          	sd	a0,708(a5) # ffffffffc0206350 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201094:	000807b7          	lui	a5,0x80
ffffffffc0201098:	002005b7          	lui	a1,0x200
ffffffffc020109c:	02f60563          	beq	a2,a5,ffffffffc02010c6 <pmm_init+0xd0>
ffffffffc02010a0:	00261593          	slli	a1,a2,0x2
ffffffffc02010a4:	00c586b3          	add	a3,a1,a2
ffffffffc02010a8:	fd8007b7          	lui	a5,0xfd800
ffffffffc02010ac:	97aa                	add	a5,a5,a0
ffffffffc02010ae:	0692                	slli	a3,a3,0x4
ffffffffc02010b0:	96be                	add	a3,a3,a5
ffffffffc02010b2:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02010b4:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010b6:	05078793          	addi	a5,a5,80 # fffffffffd800050 <end+0x3d5f9cd8>
        SetPageReserved(pages + i);
ffffffffc02010ba:	00176713          	ori	a4,a4,1
ffffffffc02010be:	fae7bc23          	sd	a4,-72(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010c2:	fef699e3          	bne	a3,a5,ffffffffc02010b4 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c6:	95b2                	add	a1,a1,a2
ffffffffc02010c8:	fd8006b7          	lui	a3,0xfd800
ffffffffc02010cc:	96aa                	add	a3,a3,a0
ffffffffc02010ce:	0592                	slli	a1,a1,0x4
ffffffffc02010d0:	96ae                	add	a3,a3,a1
ffffffffc02010d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02010d6:	0af6ea63          	bltu	a3,a5,ffffffffc020118a <pmm_init+0x194>
ffffffffc02010da:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010dc:	77fd                	lui	a5,0xfffff
ffffffffc02010de:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e2:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010e4:	06b6e163          	bltu	a3,a1,ffffffffc0201146 <pmm_init+0x150>
    slub_init();
    slub_check();
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010e8:	601c                	ld	a5,0(s0)
ffffffffc02010ea:	7b9c                	ld	a5,48(a5)
ffffffffc02010ec:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	57a50513          	addi	a0,a0,1402 # ffffffffc0202668 <best_fit_pmm_manager+0x120>
ffffffffc02010f6:	856ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010fa:	00004597          	auipc	a1,0x4
ffffffffc02010fe:	f0658593          	addi	a1,a1,-250 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201102:	00005797          	auipc	a5,0x5
ffffffffc0201106:	26b7b323          	sd	a1,614(a5) # ffffffffc0206368 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020110a:	c02007b7          	lui	a5,0xc0200
ffffffffc020110e:	0af5e663          	bltu	a1,a5,ffffffffc02011ba <pmm_init+0x1c4>
ffffffffc0201112:	6090                	ld	a2,0(s1)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201114:	00001517          	auipc	a0,0x1
ffffffffc0201118:	57450513          	addi	a0,a0,1396 # ffffffffc0202688 <best_fit_pmm_manager+0x140>
    satp_physical = PADDR(satp_virtual);
ffffffffc020111c:	40c58633          	sub	a2,a1,a2
ffffffffc0201120:	00005797          	auipc	a5,0x5
ffffffffc0201124:	24c7b023          	sd	a2,576(a5) # ffffffffc0206360 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201128:	824ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    slub_init();
ffffffffc020112c:	3c6000ef          	jal	ra,ffffffffc02014f2 <slub_init>
}
ffffffffc0201130:	7402                	ld	s0,32(sp)
ffffffffc0201132:	70a2                	ld	ra,40(sp)
ffffffffc0201134:	64e2                	ld	s1,24(sp)
ffffffffc0201136:	6942                	ld	s2,16(sp)
ffffffffc0201138:	69a2                	ld	s3,8(sp)
ffffffffc020113a:	6a02                	ld	s4,0(sp)
ffffffffc020113c:	6145                	addi	sp,sp,48
    slub_check();
ffffffffc020113e:	a325                	j	ffffffffc0201666 <slub_check>
    npage = maxpa / PGSIZE;
ffffffffc0201140:	c8000637          	lui	a2,0xc8000
ffffffffc0201144:	bf0d                	j	ffffffffc0201076 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201146:	6705                	lui	a4,0x1
ffffffffc0201148:	177d                	addi	a4,a4,-1
ffffffffc020114a:	96ba                	add	a3,a3,a4
ffffffffc020114c:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020114e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201152:	02c7f063          	bgeu	a5,a2,ffffffffc0201172 <pmm_init+0x17c>
    pmm_manager->init_memmap(base, n);
ffffffffc0201156:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201158:	fff80737          	lui	a4,0xfff80
ffffffffc020115c:	973e                	add	a4,a4,a5
ffffffffc020115e:	00271793          	slli	a5,a4,0x2
ffffffffc0201162:	97ba                	add	a5,a5,a4
ffffffffc0201164:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201166:	8d95                	sub	a1,a1,a3
ffffffffc0201168:	0792                	slli	a5,a5,0x4
    pmm_manager->init_memmap(base, n);
ffffffffc020116a:	81b1                	srli	a1,a1,0xc
ffffffffc020116c:	953e                	add	a0,a0,a5
ffffffffc020116e:	9702                	jalr	a4
}
ffffffffc0201170:	bfa5                	j	ffffffffc02010e8 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201172:	00001617          	auipc	a2,0x1
ffffffffc0201176:	4c660613          	addi	a2,a2,1222 # ffffffffc0202638 <best_fit_pmm_manager+0xf0>
ffffffffc020117a:	06a00593          	li	a1,106
ffffffffc020117e:	00001517          	auipc	a0,0x1
ffffffffc0201182:	4da50513          	addi	a0,a0,1242 # ffffffffc0202658 <best_fit_pmm_manager+0x110>
ffffffffc0201186:	83cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020118a:	00001617          	auipc	a2,0x1
ffffffffc020118e:	48660613          	addi	a2,a2,1158 # ffffffffc0202610 <best_fit_pmm_manager+0xc8>
ffffffffc0201192:	07100593          	li	a1,113
ffffffffc0201196:	00001517          	auipc	a0,0x1
ffffffffc020119a:	42250513          	addi	a0,a0,1058 # ffffffffc02025b8 <best_fit_pmm_manager+0x70>
ffffffffc020119e:	824ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc02011a2:	00001617          	auipc	a2,0x1
ffffffffc02011a6:	3f660613          	addi	a2,a2,1014 # ffffffffc0202598 <best_fit_pmm_manager+0x50>
ffffffffc02011aa:	05900593          	li	a1,89
ffffffffc02011ae:	00001517          	auipc	a0,0x1
ffffffffc02011b2:	40a50513          	addi	a0,a0,1034 # ffffffffc02025b8 <best_fit_pmm_manager+0x70>
ffffffffc02011b6:	80cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011ba:	86ae                	mv	a3,a1
ffffffffc02011bc:	00001617          	auipc	a2,0x1
ffffffffc02011c0:	45460613          	addi	a2,a2,1108 # ffffffffc0202610 <best_fit_pmm_manager+0xc8>
ffffffffc02011c4:	08c00593          	li	a1,140
ffffffffc02011c8:	00001517          	auipc	a0,0x1
ffffffffc02011cc:	3f050513          	addi	a0,a0,1008 # ffffffffc02025b8 <best_fit_pmm_manager+0x70>
ffffffffc02011d0:	ff3fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011d4 <kmem_cache_free.part.0>:
    }
    return obj;
}

void
kmem_cache_free(kmem_cache_t *cache, void *obj) {
ffffffffc02011d4:	1141                	addi	sp,sp,-16
ffffffffc02011d6:	e406                	sd	ra,8(sp)
    return pa2page(PADDR(obj));
ffffffffc02011d8:	c02007b7          	lui	a5,0xc0200
ffffffffc02011dc:	0cf5e663          	bltu	a1,a5,ffffffffc02012a8 <kmem_cache_free.part.0+0xd4>
ffffffffc02011e0:	00005797          	auipc	a5,0x5
ffffffffc02011e4:	1907b783          	ld	a5,400(a5) # ffffffffc0206370 <va_pa_offset>
ffffffffc02011e8:	40f587b3          	sub	a5,a1,a5
    if (PPN(pa) >= npage) {
ffffffffc02011ec:	83b1                	srli	a5,a5,0xc
ffffffffc02011ee:	00005717          	auipc	a4,0x5
ffffffffc02011f2:	15a73703          	ld	a4,346(a4) # ffffffffc0206348 <npage>
ffffffffc02011f6:	08e7fd63          	bgeu	a5,a4,ffffffffc0201290 <kmem_cache_free.part.0+0xbc>
    return &pages[PPN(pa) - nbase];
ffffffffc02011fa:	86aa                	mv	a3,a0
ffffffffc02011fc:	00002517          	auipc	a0,0x2
ffffffffc0201200:	cdc53503          	ld	a0,-804(a0) # ffffffffc0202ed8 <nbase>
ffffffffc0201204:	8f89                	sub	a5,a5,a0
ffffffffc0201206:	00279713          	slli	a4,a5,0x2
ffffffffc020120a:	97ba                	add	a5,a5,a4
ffffffffc020120c:	00479713          	slli	a4,a5,0x4
ffffffffc0201210:	00005797          	auipc	a5,0x5
ffffffffc0201214:	1407b783          	ld	a5,320(a5) # ffffffffc0206350 <pages>
ffffffffc0201218:	00e78533          	add	a0,a5,a4

    struct Page *slab_page = obj_to_page(obj);
    uintptr_t intr_flag;

    if (cache == NULL) {
        cache = slab_page->cache;
ffffffffc020121c:	7518                	ld	a4,40(a0)
    if (cache == NULL) {
ffffffffc020121e:	c299                	beqz	a3,ffffffffc0201224 <kmem_cache_free.part.0+0x50>
    }
    assert(cache == slab_page->cache);
ffffffffc0201220:	0ae69163          	bne	a3,a4,ffffffffc02012c2 <kmem_cache_free.part.0+0xee>

    local_intr_save(intr_flag);
ffffffffc0201224:	10002673          	csrr	a2,sstatus
ffffffffc0201228:	4789                	li	a5,2
ffffffffc020122a:	1007b073          	csrc	sstatus,a5
    {
        *(void**)obj = slab_page->freelist;
ffffffffc020122e:	7d1c                	ld	a5,56(a0)
        slab_page->freelist = obj;
        slab_page->inuse--;
ffffffffc0201230:	5914                	lw	a3,48(a0)

        if (slab_page->inuse == cache->objects_per_slab - 1) {
ffffffffc0201232:	01472803          	lw	a6,20(a4)
        *(void**)obj = slab_page->freelist;
ffffffffc0201236:	e19c                	sd	a5,0(a1)
        slab_page->inuse--;
ffffffffc0201238:	fff6879b          	addiw	a5,a3,-1
        slab_page->freelist = obj;
ffffffffc020123c:	fd0c                	sd	a1,56(a0)
        slab_page->inuse--;
ffffffffc020123e:	d91c                	sw	a5,48(a0)
        if (slab_page->inuse == cache->objects_per_slab - 1) {
ffffffffc0201240:	00d80863          	beq	a6,a3,ffffffffc0201250 <kmem_cache_free.part.0+0x7c>
            list_del(&(slab_page->slab_link));
            list_add(&(cache->partial_slabs), &(slab_page->slab_link));
        } else if (slab_page->inuse == 0) {
ffffffffc0201244:	cf85                	beqz	a5,ffffffffc020127c <kmem_cache_free.part.0+0xa8>
            local_intr_restore(intr_flag);
            free_page(slab_page);
            return;
        }
    }
    local_intr_restore(intr_flag);
ffffffffc0201246:	10061073          	csrw	sstatus,a2
}
ffffffffc020124a:	60a2                	ld	ra,8(sp)
ffffffffc020124c:	0141                	addi	sp,sp,16
ffffffffc020124e:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201250:	04053803          	ld	a6,64(a0)
ffffffffc0201254:	652c                	ld	a1,72(a0)
            list_add(&(cache->partial_slabs), &(slab_page->slab_link));
ffffffffc0201256:	04050693          	addi	a3,a0,64
ffffffffc020125a:	01870893          	addi	a7,a4,24
    prev->next = next;
ffffffffc020125e:	00b83423          	sd	a1,8(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201262:	731c                	ld	a5,32(a4)
    next->prev = prev;
ffffffffc0201264:	0105b023          	sd	a6,0(a1)
    prev->next = next->prev = elm;
ffffffffc0201268:	e394                	sd	a3,0(a5)
ffffffffc020126a:	f314                	sd	a3,32(a4)
    elm->next = next;
ffffffffc020126c:	e53c                	sd	a5,72(a0)
    elm->prev = prev;
ffffffffc020126e:	05153023          	sd	a7,64(a0)
    local_intr_restore(intr_flag);
ffffffffc0201272:	10061073          	csrw	sstatus,a2
}
ffffffffc0201276:	60a2                	ld	ra,8(sp)
ffffffffc0201278:	0141                	addi	sp,sp,16
ffffffffc020127a:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020127c:	6138                	ld	a4,64(a0)
ffffffffc020127e:	653c                	ld	a5,72(a0)
    prev->next = next;
ffffffffc0201280:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201282:	e398                	sd	a4,0(a5)
            local_intr_restore(intr_flag);
ffffffffc0201284:	10061073          	csrw	sstatus,a2
}
ffffffffc0201288:	60a2                	ld	ra,8(sp)
            free_page(slab_page);
ffffffffc020128a:	4585                	li	a1,1
}
ffffffffc020128c:	0141                	addi	sp,sp,16
            free_page(slab_page);
ffffffffc020128e:	bb81                	j	ffffffffc0200fde <free_pages>
        panic("pa2page called with invalid pa");
ffffffffc0201290:	00001617          	auipc	a2,0x1
ffffffffc0201294:	3a860613          	addi	a2,a2,936 # ffffffffc0202638 <best_fit_pmm_manager+0xf0>
ffffffffc0201298:	06a00593          	li	a1,106
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	3bc50513          	addi	a0,a0,956 # ffffffffc0202658 <best_fit_pmm_manager+0x110>
ffffffffc02012a4:	f1ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    return pa2page(PADDR(obj));
ffffffffc02012a8:	86ae                	mv	a3,a1
ffffffffc02012aa:	00001617          	auipc	a2,0x1
ffffffffc02012ae:	36660613          	addi	a2,a2,870 # ffffffffc0202610 <best_fit_pmm_manager+0xc8>
ffffffffc02012b2:	04d00593          	li	a1,77
ffffffffc02012b6:	00001517          	auipc	a0,0x1
ffffffffc02012ba:	41250513          	addi	a0,a0,1042 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02012be:	f05fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache == slab_page->cache);
ffffffffc02012c2:	00001697          	auipc	a3,0x1
ffffffffc02012c6:	41e68693          	addi	a3,a3,1054 # ffffffffc02026e0 <best_fit_pmm_manager+0x198>
ffffffffc02012ca:	00001617          	auipc	a2,0x1
ffffffffc02012ce:	f3e60613          	addi	a2,a2,-194 # ffffffffc0202208 <etext+0x26c>
ffffffffc02012d2:	0a900593          	li	a1,169
ffffffffc02012d6:	00001517          	auipc	a0,0x1
ffffffffc02012da:	3f250513          	addi	a0,a0,1010 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02012de:	ee5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02012e2 <kfree.part.0>:
    int index = size_to_index(size);
    return kmem_cache_alloc(kmalloc_caches[index]);
}

void
kfree(void *obj) {
ffffffffc02012e2:	1141                	addi	sp,sp,-16
ffffffffc02012e4:	e406                	sd	ra,8(sp)
ffffffffc02012e6:	e022                	sd	s0,0(sp)
    return pa2page(PADDR(obj));
ffffffffc02012e8:	c02007b7          	lui	a5,0xc0200
kfree(void *obj) {
ffffffffc02012ec:	85aa                	mv	a1,a0
    return pa2page(PADDR(obj));
ffffffffc02012ee:	04f56f63          	bltu	a0,a5,ffffffffc020134c <kfree.part.0+0x6a>
ffffffffc02012f2:	00005797          	auipc	a5,0x5
ffffffffc02012f6:	07e7b783          	ld	a5,126(a5) # ffffffffc0206370 <va_pa_offset>
ffffffffc02012fa:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02012fe:	83b1                	srli	a5,a5,0xc
ffffffffc0201300:	00005717          	auipc	a4,0x5
ffffffffc0201304:	04873703          	ld	a4,72(a4) # ffffffffc0206348 <npage>
ffffffffc0201308:	04e7ff63          	bgeu	a5,a4,ffffffffc0201366 <kfree.part.0+0x84>
    return &pages[PPN(pa) - nbase];
ffffffffc020130c:	00002717          	auipc	a4,0x2
ffffffffc0201310:	bcc73703          	ld	a4,-1076(a4) # ffffffffc0202ed8 <nbase>
ffffffffc0201314:	8f99                	sub	a5,a5,a4
ffffffffc0201316:	00279713          	slli	a4,a5,0x2
ffffffffc020131a:	97ba                	add	a5,a5,a4
ffffffffc020131c:	0792                	slli	a5,a5,0x4
ffffffffc020131e:	00005417          	auipc	s0,0x5
ffffffffc0201322:	03243403          	ld	s0,50(s0) # ffffffffc0206350 <pages>
ffffffffc0201326:	943e                	add	s0,s0,a5
    if (obj == NULL) return;

    struct Page *slab_page = obj_to_page(obj);
    
    if (slab_page->cache == NULL) {
ffffffffc0201328:	7408                	ld	a0,40(s0)
ffffffffc020132a:	c509                	beqz	a0,ffffffffc0201334 <kfree.part.0+0x52>
        free_page(slab_page);
        return;
    }

    kmem_cache_free(slab_page->cache, obj);
}
ffffffffc020132c:	6402                	ld	s0,0(sp)
ffffffffc020132e:	60a2                	ld	ra,8(sp)
ffffffffc0201330:	0141                	addi	sp,sp,16
ffffffffc0201332:	b54d                	j	ffffffffc02011d4 <kmem_cache_free.part.0>
        cprintf("Warning: kfree called on non-slub page. Using free_pages.\n");
ffffffffc0201334:	00001517          	auipc	a0,0x1
ffffffffc0201338:	3cc50513          	addi	a0,a0,972 # ffffffffc0202700 <best_fit_pmm_manager+0x1b8>
ffffffffc020133c:	e11fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_page(slab_page);
ffffffffc0201340:	8522                	mv	a0,s0
}
ffffffffc0201342:	6402                	ld	s0,0(sp)
ffffffffc0201344:	60a2                	ld	ra,8(sp)
        free_page(slab_page);
ffffffffc0201346:	4585                	li	a1,1
}
ffffffffc0201348:	0141                	addi	sp,sp,16
        free_page(slab_page);
ffffffffc020134a:	b951                	j	ffffffffc0200fde <free_pages>
    return pa2page(PADDR(obj));
ffffffffc020134c:	86aa                	mv	a3,a0
ffffffffc020134e:	00001617          	auipc	a2,0x1
ffffffffc0201352:	2c260613          	addi	a2,a2,706 # ffffffffc0202610 <best_fit_pmm_manager+0xc8>
ffffffffc0201356:	04d00593          	li	a1,77
ffffffffc020135a:	00001517          	auipc	a0,0x1
ffffffffc020135e:	36e50513          	addi	a0,a0,878 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201362:	e61fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201366:	00001617          	auipc	a2,0x1
ffffffffc020136a:	2d260613          	addi	a2,a2,722 # ffffffffc0202638 <best_fit_pmm_manager+0xf0>
ffffffffc020136e:	06a00593          	li	a1,106
ffffffffc0201372:	00001517          	auipc	a0,0x1
ffffffffc0201376:	2e650513          	addi	a0,a0,742 # ffffffffc0202658 <best_fit_pmm_manager+0x110>
ffffffffc020137a:	e49fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020137e <kmem_cache_alloc>:
kmem_cache_alloc(kmem_cache_t *cache) {
ffffffffc020137e:	715d                	addi	sp,sp,-80
ffffffffc0201380:	f44e                	sd	s3,40(sp)
ffffffffc0201382:	e486                	sd	ra,72(sp)
ffffffffc0201384:	e0a2                	sd	s0,64(sp)
ffffffffc0201386:	fc26                	sd	s1,56(sp)
ffffffffc0201388:	f84a                	sd	s2,48(sp)
ffffffffc020138a:	f052                	sd	s4,32(sp)
ffffffffc020138c:	ec56                	sd	s5,24(sp)
ffffffffc020138e:	e85a                	sd	s6,16(sp)
ffffffffc0201390:	e45e                	sd	s7,8(sp)
ffffffffc0201392:	89aa                	mv	s3,a0
    local_intr_save(intr_flag);
ffffffffc0201394:	100026f3          	csrr	a3,sstatus
ffffffffc0201398:	4789                	li	a5,2
ffffffffc020139a:	1007b073          	csrc	sstatus,a5
    return list->next == list;
ffffffffc020139e:	02053a03          	ld	s4,32(a0)
        if (!list_empty(&(cache->partial_slabs))) {
ffffffffc02013a2:	01850793          	addi	a5,a0,24
ffffffffc02013a6:	12fa1863          	bne	s4,a5,ffffffffc02014d6 <kmem_cache_alloc+0x158>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02013aa:	00005b97          	auipc	s7,0x5
ffffffffc02013ae:	fa6b8b93          	addi	s7,s7,-90 # ffffffffc0206350 <pages>
ffffffffc02013b2:	00002497          	auipc	s1,0x2
ffffffffc02013b6:	b1e4b483          	ld	s1,-1250(s1) # ffffffffc0202ed0 <error_string+0x38>
ffffffffc02013ba:	00002b17          	auipc	s6,0x2
ffffffffc02013be:	b1eb0b13          	addi	s6,s6,-1250 # ffffffffc0202ed8 <nbase>
    void *slab_addr = page2kva(slab_page);
ffffffffc02013c2:	00005a97          	auipc	s5,0x5
ffffffffc02013c6:	faea8a93          	addi	s5,s5,-82 # ffffffffc0206370 <va_pa_offset>
            local_intr_save(intr_flag);
ffffffffc02013ca:	4409                	li	s0,2
            local_intr_restore(intr_flag);
ffffffffc02013cc:	10069073          	csrw	sstatus,a3
    struct Page *slab_page = alloc_page();
ffffffffc02013d0:	4505                	li	a0,1
ffffffffc02013d2:	c01ff0ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02013d6:	892a                	mv	s2,a0
    if (slab_page == NULL) {
ffffffffc02013d8:	c969                	beqz	a0,ffffffffc02014aa <kmem_cache_alloc+0x12c>
ffffffffc02013da:	000bb603          	ld	a2,0(s7)
ffffffffc02013de:	000b3703          	ld	a4,0(s6)
    for (int i = 0; i < cache->objects_per_slab; ++i) {
ffffffffc02013e2:	0149a303          	lw	t1,20(s3)
ffffffffc02013e6:	40c50633          	sub	a2,a0,a2
ffffffffc02013ea:	8611                	srai	a2,a2,0x4
ffffffffc02013ec:	02960633          	mul	a2,a2,s1
    void *slab_addr = page2kva(slab_page);
ffffffffc02013f0:	000ab783          	ld	a5,0(s5)
    slab_page->cache = cache;
ffffffffc02013f4:	03353423          	sd	s3,40(a0)
    slab_page->inuse = 0;
ffffffffc02013f8:	02052823          	sw	zero,48(a0)
    slab_page->freelist = NULL;
ffffffffc02013fc:	02053c23          	sd	zero,56(a0)
ffffffffc0201400:	963a                	add	a2,a2,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201402:	0632                	slli	a2,a2,0xc
    void *slab_addr = page2kva(slab_page);
ffffffffc0201404:	963e                	add	a2,a2,a5
    for (int i = 0; i < cache->objects_per_slab; ++i) {
ffffffffc0201406:	02030863          	beqz	t1,ffffffffc0201436 <kmem_cache_alloc+0xb8>
        void *obj = (char*)slab_addr + i * cache->object_size;
ffffffffc020140a:	0109ae03          	lw	t3,16(s3)
ffffffffc020140e:	2301                	sext.w	t1,t1
ffffffffc0201410:	4681                	li	a3,0
ffffffffc0201412:	4781                	li	a5,0
    for (int i = 0; i < cache->objects_per_slab; ++i) {
ffffffffc0201414:	4701                	li	a4,0
        void *obj = (char*)slab_addr + i * cache->object_size;
ffffffffc0201416:	02069893          	slli	a7,a3,0x20
ffffffffc020141a:	0208d893          	srli	a7,a7,0x20
ffffffffc020141e:	883e                	mv	a6,a5
ffffffffc0201420:	011607b3          	add	a5,a2,a7
        *(void**)obj = slab_page->freelist;
ffffffffc0201424:	0107b023          	sd	a6,0(a5)
        slab_page->freelist = obj;
ffffffffc0201428:	02f93c23          	sd	a5,56(s2)
    for (int i = 0; i < cache->objects_per_slab; ++i) {
ffffffffc020142c:	2705                	addiw	a4,a4,1
ffffffffc020142e:	00de06bb          	addw	a3,t3,a3
ffffffffc0201432:	fe6712e3          	bne	a4,t1,ffffffffc0201416 <kmem_cache_alloc+0x98>
            local_intr_save(intr_flag);
ffffffffc0201436:	100026f3          	csrr	a3,sstatus
ffffffffc020143a:	10043073          	csrc	sstatus,s0
    __list_add(elm, listelm, listelm->next);
ffffffffc020143e:	0209b783          	ld	a5,32(s3)
            list_add(&(cache->partial_slabs), &(slab_page->slab_link));
ffffffffc0201442:	04090713          	addi	a4,s2,64
    prev->next = next->prev = elm;
ffffffffc0201446:	e398                	sd	a4,0(a5)
ffffffffc0201448:	02e9b023          	sd	a4,32(s3)
    elm->next = next;
ffffffffc020144c:	04f93423          	sd	a5,72(s2)
    return list->next == list;
ffffffffc0201450:	0209b783          	ld	a5,32(s3)
    elm->prev = prev;
ffffffffc0201454:	05493023          	sd	s4,64(s2)
        if (!list_empty(&(cache->partial_slabs))) {
ffffffffc0201458:	f7478ae3          	beq	a5,s4,ffffffffc02013cc <kmem_cache_alloc+0x4e>
        if (slab_page->freelist != NULL) {
ffffffffc020145c:	ff87b903          	ld	s2,-8(a5)
ffffffffc0201460:	06090d63          	beqz	s2,ffffffffc02014da <kmem_cache_alloc+0x15c>
            slab_page->inuse++;
ffffffffc0201464:	ff07a703          	lw	a4,-16(a5)
            slab_page->freelist = *(void**)obj;
ffffffffc0201468:	00093603          	ld	a2,0(s2)
            if (slab_page->inuse == cache->objects_per_slab) {
ffffffffc020146c:	0149a583          	lw	a1,20(s3)
            slab_page->inuse++;
ffffffffc0201470:	2705                	addiw	a4,a4,1
            slab_page->freelist = *(void**)obj;
ffffffffc0201472:	fec7bc23          	sd	a2,-8(a5)
            slab_page->inuse++;
ffffffffc0201476:	fee7a823          	sw	a4,-16(a5)
ffffffffc020147a:	0007061b          	sext.w	a2,a4
            if (slab_page->inuse == cache->objects_per_slab) {
ffffffffc020147e:	02c58e63          	beq	a1,a2,ffffffffc02014ba <kmem_cache_alloc+0x13c>
    local_intr_restore(intr_flag);
ffffffffc0201482:	10069073          	csrw	sstatus,a3
        memset(obj, 0, cache->object_size);
ffffffffc0201486:	0109e603          	lwu	a2,16(s3)
ffffffffc020148a:	4581                	li	a1,0
ffffffffc020148c:	854a                	mv	a0,s2
ffffffffc020148e:	2fd000ef          	jal	ra,ffffffffc0201f8a <memset>
}
ffffffffc0201492:	60a6                	ld	ra,72(sp)
ffffffffc0201494:	6406                	ld	s0,64(sp)
ffffffffc0201496:	74e2                	ld	s1,56(sp)
ffffffffc0201498:	79a2                	ld	s3,40(sp)
ffffffffc020149a:	7a02                	ld	s4,32(sp)
ffffffffc020149c:	6ae2                	ld	s5,24(sp)
ffffffffc020149e:	6b42                	ld	s6,16(sp)
ffffffffc02014a0:	6ba2                	ld	s7,8(sp)
ffffffffc02014a2:	854a                	mv	a0,s2
ffffffffc02014a4:	7942                	ld	s2,48(sp)
ffffffffc02014a6:	6161                	addi	sp,sp,80
ffffffffc02014a8:	8082                	ret
        cprintf("kmem_cache_grow: failed to allocate page for cache %s\n", cache->name);
ffffffffc02014aa:	85ce                	mv	a1,s3
ffffffffc02014ac:	00001517          	auipc	a0,0x1
ffffffffc02014b0:	29450513          	addi	a0,a0,660 # ffffffffc0202740 <best_fit_pmm_manager+0x1f8>
ffffffffc02014b4:	c99fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            if (slab_page == NULL) return NULL;
ffffffffc02014b8:	bfe9                	j	ffffffffc0201492 <kmem_cache_alloc+0x114>
    __list_del(listelm->prev, listelm->next);
ffffffffc02014ba:	6388                	ld	a0,0(a5)
ffffffffc02014bc:	678c                	ld	a1,8(a5)
                list_add(&(cache->full_slabs), &(slab_page->slab_link));
ffffffffc02014be:	02898713          	addi	a4,s3,40
    prev->next = next;
ffffffffc02014c2:	e50c                	sd	a1,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc02014c4:	0309b603          	ld	a2,48(s3)
    next->prev = prev;
ffffffffc02014c8:	e188                	sd	a0,0(a1)
    prev->next = next->prev = elm;
ffffffffc02014ca:	e21c                	sd	a5,0(a2)
ffffffffc02014cc:	02f9b823          	sd	a5,48(s3)
    elm->next = next;
ffffffffc02014d0:	e790                	sd	a2,8(a5)
    elm->prev = prev;
ffffffffc02014d2:	e398                	sd	a4,0(a5)
}
ffffffffc02014d4:	b77d                	j	ffffffffc0201482 <kmem_cache_alloc+0x104>
        if (!list_empty(&(cache->partial_slabs))) {
ffffffffc02014d6:	87d2                	mv	a5,s4
ffffffffc02014d8:	b751                	j	ffffffffc020145c <kmem_cache_alloc+0xde>
            panic("SLUB: slab on partial list has no free objects!");
ffffffffc02014da:	00001617          	auipc	a2,0x1
ffffffffc02014de:	29e60613          	addi	a2,a2,670 # ffffffffc0202778 <best_fit_pmm_manager+0x230>
ffffffffc02014e2:	09400593          	li	a1,148
ffffffffc02014e6:	00001517          	auipc	a0,0x1
ffffffffc02014ea:	1e250513          	addi	a0,a0,482 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02014ee:	cd5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02014f2 <slub_init>:
slub_init(void) {
ffffffffc02014f2:	7159                	addi	sp,sp,-112
    cprintf("slub_init: initializing kmalloc caches...\n");
ffffffffc02014f4:	00001517          	auipc	a0,0x1
ffffffffc02014f8:	2b450513          	addi	a0,a0,692 # ffffffffc02027a8 <best_fit_pmm_manager+0x260>
slub_init(void) {
ffffffffc02014fc:	f0a2                	sd	s0,96(sp)
ffffffffc02014fe:	e8ca                	sd	s2,80(sp)
ffffffffc0201500:	e0d2                	sd	s4,64(sp)
ffffffffc0201502:	fc56                	sd	s5,56(sp)
ffffffffc0201504:	f85a                	sd	s6,48(sp)
ffffffffc0201506:	f45e                	sd	s7,40(sp)
ffffffffc0201508:	f062                	sd	s8,32(sp)
ffffffffc020150a:	ec66                	sd	s9,24(sp)
ffffffffc020150c:	f486                	sd	ra,104(sp)
ffffffffc020150e:	eca6                	sd	s1,88(sp)
ffffffffc0201510:	e4ce                	sd	s3,72(sp)
ffffffffc0201512:	e86a                	sd	s10,16(sp)
ffffffffc0201514:	00005417          	auipc	s0,0x5
ffffffffc0201518:	b3440413          	addi	s0,s0,-1228 # ffffffffc0206048 <caches_storage.0+0x18>
    cprintf("slub_init: initializing kmalloc caches...\n");
ffffffffc020151c:	c31fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 12; i++) {
ffffffffc0201520:	00005a17          	auipc	s4,0x5
ffffffffc0201524:	db0a0a13          	addi	s4,s4,-592 # ffffffffc02062d0 <kmalloc_caches>
ffffffffc0201528:	4901                	li	s2,0
        size_t size = KMALLOC_MIN_SIZE << i;
ffffffffc020152a:	4ca1                	li	s9,8
        snprintf(name, 16, "kmalloc-%d", size);
ffffffffc020152c:	00001c17          	auipc	s8,0x1
ffffffffc0201530:	2acc0c13          	addi	s8,s8,684 # ffffffffc02027d8 <best_fit_pmm_manager+0x290>
        cache->objects_per_slab = PGSIZE / size;
ffffffffc0201534:	6b85                	lui	s7,0x1
        cprintf("  - created cache '%s'\n", cache->name);
ffffffffc0201536:	00001b17          	auipc	s6,0x1
ffffffffc020153a:	2b2b0b13          	addi	s6,s6,690 # ffffffffc02027e8 <best_fit_pmm_manager+0x2a0>
    for (int i = 0; i < 12; i++) {
ffffffffc020153e:	4ab1                	li	s5,12
        size_t size = KMALLOC_MIN_SIZE << i;
ffffffffc0201540:	012c94bb          	sllw	s1,s9,s2
        snprintf(name, 16, "kmalloc-%d", size);
ffffffffc0201544:	86a6                	mv	a3,s1
ffffffffc0201546:	8662                	mv	a2,s8
ffffffffc0201548:	45c1                	li	a1,16
ffffffffc020154a:	850a                	mv	a0,sp
ffffffffc020154c:	149000ef          	jal	ra,ffffffffc0201e94 <snprintf>
ffffffffc0201550:	fe840993          	addi	s3,s0,-24
        strncpy(cache->name, name, sizeof(cache->name) - 1);
ffffffffc0201554:	858a                	mv	a1,sp
ffffffffc0201556:	463d                	li	a2,15
ffffffffc0201558:	854e                	mv	a0,s3
ffffffffc020155a:	1d1000ef          	jal	ra,ffffffffc0201f2a <strncpy>
        size_t size = KMALLOC_MIN_SIZE << i;
ffffffffc020155e:	8d26                	mv	s10,s1
        cache->objects_per_slab = PGSIZE / size;
ffffffffc0201560:	029bd4b3          	divu	s1,s7,s1
ffffffffc0201564:	01040793          	addi	a5,s0,16
        cache->name[sizeof(cache->name) - 1] = '\0';
ffffffffc0201568:	fe040ba3          	sb	zero,-9(s0)
        cache->object_size = size;
ffffffffc020156c:	ffa42c23          	sw	s10,-8(s0)
    elm->prev = elm->next = elm;
ffffffffc0201570:	e400                	sd	s0,8(s0)
ffffffffc0201572:	e000                	sd	s0,0(s0)
ffffffffc0201574:	ec1c                	sd	a5,24(s0)
ffffffffc0201576:	e81c                	sd	a5,16(s0)
    for (int i = 0; i < 12; i++) {
ffffffffc0201578:	2905                	addiw	s2,s2,1
        cprintf("  - created cache '%s'\n", cache->name);
ffffffffc020157a:	85ce                	mv	a1,s3
ffffffffc020157c:	855a                	mv	a0,s6
        kmalloc_caches[i] = cache;
ffffffffc020157e:	013a3023          	sd	s3,0(s4)
    for (int i = 0; i < 12; i++) {
ffffffffc0201582:	03840413          	addi	s0,s0,56
ffffffffc0201586:	0a21                	addi	s4,s4,8
        cache->objects_per_slab = PGSIZE / size;
ffffffffc0201588:	fc942223          	sw	s1,-60(s0)
        cprintf("  - created cache '%s'\n", cache->name);
ffffffffc020158c:	bc1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 12; i++) {
ffffffffc0201590:	fb5918e3          	bne	s2,s5,ffffffffc0201540 <slub_init+0x4e>
}
ffffffffc0201594:	70a6                	ld	ra,104(sp)
ffffffffc0201596:	7406                	ld	s0,96(sp)
ffffffffc0201598:	64e6                	ld	s1,88(sp)
ffffffffc020159a:	6946                	ld	s2,80(sp)
ffffffffc020159c:	69a6                	ld	s3,72(sp)
ffffffffc020159e:	6a06                	ld	s4,64(sp)
ffffffffc02015a0:	7ae2                	ld	s5,56(sp)
ffffffffc02015a2:	7b42                	ld	s6,48(sp)
ffffffffc02015a4:	7ba2                	ld	s7,40(sp)
ffffffffc02015a6:	7c02                	ld	s8,32(sp)
ffffffffc02015a8:	6ce2                	ld	s9,24(sp)
ffffffffc02015aa:	6d42                	ld	s10,16(sp)
ffffffffc02015ac:	6165                	addi	sp,sp,112
ffffffffc02015ae:	8082                	ret

ffffffffc02015b0 <kmalloc>:
    if (kmalloc_caches[0] == NULL) {
ffffffffc02015b0:	00005697          	auipc	a3,0x5
ffffffffc02015b4:	d2068693          	addi	a3,a3,-736 # ffffffffc02062d0 <kmalloc_caches>
ffffffffc02015b8:	629c                	ld	a5,0(a3)
kmalloc(size_t size) {
ffffffffc02015ba:	1141                	addi	sp,sp,-16
ffffffffc02015bc:	e022                	sd	s0,0(sp)
ffffffffc02015be:	e406                	sd	ra,8(sp)
ffffffffc02015c0:	842a                	mv	s0,a0
    if (kmalloc_caches[0] == NULL) {
ffffffffc02015c2:	cb85                	beqz	a5,ffffffffc02015f2 <kmalloc+0x42>
    if (size == 0) return NULL;
ffffffffc02015c4:	c141                	beqz	a0,ffffffffc0201644 <kmalloc+0x94>
    if (size > KMALLOC_MAX_SIZE) {
ffffffffc02015c6:	6705                	lui	a4,0x1
ffffffffc02015c8:	08a76363          	bltu	a4,a0,ffffffffc020164e <kmalloc+0x9e>
    if (size <= 8) return 0;
ffffffffc02015cc:	4721                	li	a4,8
ffffffffc02015ce:	00a77d63          	bgeu	a4,a0,ffffffffc02015e8 <kmalloc+0x38>
    return simple_fls(size - 1) - 3;
ffffffffc02015d2:	357d                	addiw	a0,a0,-1
    int position = 0;
ffffffffc02015d4:	4781                	li	a5,0
        temp >>= 1;
ffffffffc02015d6:	0015551b          	srliw	a0,a0,0x1
        position++;
ffffffffc02015da:	873e                	mv	a4,a5
ffffffffc02015dc:	2785                	addiw	a5,a5,1
    while (temp > 0) {
ffffffffc02015de:	fd65                	bnez	a0,ffffffffc02015d6 <kmalloc+0x26>
    return kmem_cache_alloc(kmalloc_caches[index]);
ffffffffc02015e0:	3779                	addiw	a4,a4,-2
ffffffffc02015e2:	070e                	slli	a4,a4,0x3
ffffffffc02015e4:	9736                	add	a4,a4,a3
ffffffffc02015e6:	631c                	ld	a5,0(a4)
}
ffffffffc02015e8:	6402                	ld	s0,0(sp)
ffffffffc02015ea:	60a2                	ld	ra,8(sp)
    return kmem_cache_alloc(kmalloc_caches[index]);
ffffffffc02015ec:	853e                	mv	a0,a5
}
ffffffffc02015ee:	0141                	addi	sp,sp,16
    return kmem_cache_alloc(kmalloc_caches[index]);
ffffffffc02015f0:	b379                	j	ffffffffc020137e <kmem_cache_alloc>
        cprintf("Warning: kmalloc called before slub_init. Falling back to alloc_pages.\n");
ffffffffc02015f2:	00001517          	auipc	a0,0x1
ffffffffc02015f6:	20e50513          	addi	a0,a0,526 # ffffffffc0202800 <best_fit_pmm_manager+0x2b8>
ffffffffc02015fa:	b53fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        int num_pages = (size + PGSIZE - 1) / PGSIZE;
ffffffffc02015fe:	6505                	lui	a0,0x1
ffffffffc0201600:	157d                	addi	a0,a0,-1
ffffffffc0201602:	9522                	add	a0,a0,s0
ffffffffc0201604:	8131                	srli	a0,a0,0xc
        struct Page *p = alloc_pages(num_pages);
ffffffffc0201606:	2501                	sext.w	a0,a0
ffffffffc0201608:	9cbff0ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
        if (p == NULL) return NULL;
ffffffffc020160c:	cd05                	beqz	a0,ffffffffc0201644 <kmalloc+0x94>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020160e:	00005797          	auipc	a5,0x5
ffffffffc0201612:	d427b783          	ld	a5,-702(a5) # ffffffffc0206350 <pages>
ffffffffc0201616:	8d1d                	sub	a0,a0,a5
ffffffffc0201618:	8511                	srai	a0,a0,0x4
ffffffffc020161a:	00002797          	auipc	a5,0x2
ffffffffc020161e:	8b67b783          	ld	a5,-1866(a5) # ffffffffc0202ed0 <error_string+0x38>
ffffffffc0201622:	02f50533          	mul	a0,a0,a5
}
ffffffffc0201626:	60a2                	ld	ra,8(sp)
ffffffffc0201628:	00002797          	auipc	a5,0x2
ffffffffc020162c:	8b07b783          	ld	a5,-1872(a5) # ffffffffc0202ed8 <nbase>
ffffffffc0201630:	6402                	ld	s0,0(sp)
ffffffffc0201632:	953e                	add	a0,a0,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201634:	0532                	slli	a0,a0,0xc
        return page2kva(p);
ffffffffc0201636:	00005797          	auipc	a5,0x5
ffffffffc020163a:	d3a7b783          	ld	a5,-710(a5) # ffffffffc0206370 <va_pa_offset>
ffffffffc020163e:	953e                	add	a0,a0,a5
}
ffffffffc0201640:	0141                	addi	sp,sp,16
ffffffffc0201642:	8082                	ret
ffffffffc0201644:	60a2                	ld	ra,8(sp)
ffffffffc0201646:	6402                	ld	s0,0(sp)
        if (p == NULL) return NULL;
ffffffffc0201648:	4501                	li	a0,0
}
ffffffffc020164a:	0141                	addi	sp,sp,16
ffffffffc020164c:	8082                	ret
        panic("kmalloc does not support size > 4096 in this simplified version");
ffffffffc020164e:	00001617          	auipc	a2,0x1
ffffffffc0201652:	1fa60613          	addi	a2,a2,506 # ffffffffc0202848 <best_fit_pmm_manager+0x300>
ffffffffc0201656:	0e100593          	li	a1,225
ffffffffc020165a:	00001517          	auipc	a0,0x1
ffffffffc020165e:	06e50513          	addi	a0,a0,110 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201662:	b61fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201666 <slub_check>:

void
slub_check(void) {
ffffffffc0201666:	7159                	addi	sp,sp,-112
    cprintf("\n--- Running SLUB Allocator Check ---\n");
ffffffffc0201668:	00001517          	auipc	a0,0x1
ffffffffc020166c:	22050513          	addi	a0,a0,544 # ffffffffc0202888 <best_fit_pmm_manager+0x340>
slub_check(void) {
ffffffffc0201670:	f486                	sd	ra,104(sp)
ffffffffc0201672:	f0a2                	sd	s0,96(sp)
ffffffffc0201674:	eca6                	sd	s1,88(sp)
ffffffffc0201676:	e8ca                	sd	s2,80(sp)
ffffffffc0201678:	e4ce                	sd	s3,72(sp)
ffffffffc020167a:	e0d2                	sd	s4,64(sp)
ffffffffc020167c:	fc56                	sd	s5,56(sp)
ffffffffc020167e:	f85a                	sd	s6,48(sp)
ffffffffc0201680:	f45e                	sd	s7,40(sp)
ffffffffc0201682:	f062                	sd	s8,32(sp)
ffffffffc0201684:	ec66                	sd	s9,24(sp)
ffffffffc0201686:	e86a                	sd	s10,16(sp)
ffffffffc0201688:	e46e                	sd	s11,8(sp)
    cprintf("\n--- Running SLUB Allocator Check ---\n");
ffffffffc020168a:	ac3fe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("1. Basic allocation and free test...\n");
ffffffffc020168e:	00001517          	auipc	a0,0x1
ffffffffc0201692:	22250513          	addi	a0,a0,546 # ffffffffc02028b0 <best_fit_pmm_manager+0x368>
ffffffffc0201696:	ab7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *p1 = kmalloc(30);
ffffffffc020169a:	4579                	li	a0,30
ffffffffc020169c:	f15ff0ef          	jal	ra,ffffffffc02015b0 <kmalloc>
    assert(p1 != NULL);
ffffffffc02016a0:	2e050963          	beqz	a0,ffffffffc0201992 <slub_check+0x32c>
    return pa2page(PADDR(obj));
ffffffffc02016a4:	c02007b7          	lui	a5,0xc0200
ffffffffc02016a8:	842a                	mv	s0,a0
ffffffffc02016aa:	36f56463          	bltu	a0,a5,ffffffffc0201a12 <slub_check+0x3ac>
ffffffffc02016ae:	00005d17          	auipc	s10,0x5
ffffffffc02016b2:	cc2d0d13          	addi	s10,s10,-830 # ffffffffc0206370 <va_pa_offset>
ffffffffc02016b6:	000d3783          	ld	a5,0(s10)
    if (PPN(pa) >= npage) {
ffffffffc02016ba:	00005c97          	auipc	s9,0x5
ffffffffc02016be:	c8ec8c93          	addi	s9,s9,-882 # ffffffffc0206348 <npage>
ffffffffc02016c2:	000cb703          	ld	a4,0(s9)
ffffffffc02016c6:	40f507b3          	sub	a5,a0,a5
ffffffffc02016ca:	83b1                	srli	a5,a5,0xc
ffffffffc02016cc:	22e7fa63          	bgeu	a5,a4,ffffffffc0201900 <slub_check+0x29a>
    return &pages[PPN(pa) - nbase];
ffffffffc02016d0:	00002b97          	auipc	s7,0x2
ffffffffc02016d4:	808bbb83          	ld	s7,-2040(s7) # ffffffffc0202ed8 <nbase>
ffffffffc02016d8:	417787b3          	sub	a5,a5,s7
    struct Page *page1 = obj_to_page(p1);
    assert(page1->cache == kmalloc_caches[size_to_index(30)]);
ffffffffc02016dc:	00005c17          	auipc	s8,0x5
ffffffffc02016e0:	c74c0c13          	addi	s8,s8,-908 # ffffffffc0206350 <pages>
ffffffffc02016e4:	000c3683          	ld	a3,0(s8)
ffffffffc02016e8:	00279713          	slli	a4,a5,0x2
ffffffffc02016ec:	97ba                	add	a5,a5,a4
ffffffffc02016ee:	0792                	slli	a5,a5,0x4
ffffffffc02016f0:	97b6                	add	a5,a5,a3
ffffffffc02016f2:	00005a97          	auipc	s5,0x5
ffffffffc02016f6:	bdea8a93          	addi	s5,s5,-1058 # ffffffffc02062d0 <kmalloc_caches>
ffffffffc02016fa:	778c                	ld	a1,40(a5)
ffffffffc02016fc:	010ab783          	ld	a5,16(s5)
ffffffffc0201700:	26f59963          	bne	a1,a5,ffffffffc0201972 <slub_check+0x30c>
    cprintf("   - kmalloc(30) allocated from '%s'. OK.\n", page1->cache->name);
ffffffffc0201704:	00001517          	auipc	a0,0x1
ffffffffc0201708:	21c50513          	addi	a0,a0,540 # ffffffffc0202920 <best_fit_pmm_manager+0x3d8>
ffffffffc020170c:	a41fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (obj == NULL) return;
ffffffffc0201710:	8522                	mv	a0,s0
ffffffffc0201712:	bd1ff0ef          	jal	ra,ffffffffc02012e2 <kfree.part.0>
    kfree(p1);
    cprintf("   - kfree(p1) OK.\n");
ffffffffc0201716:	00001517          	auipc	a0,0x1
ffffffffc020171a:	23a50513          	addi	a0,a0,570 # ffffffffc0202950 <best_fit_pmm_manager+0x408>
ffffffffc020171e:	a2ffe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("2. Slab state transition test (using kmalloc-128)...\n");
ffffffffc0201722:	00001517          	auipc	a0,0x1
ffffffffc0201726:	24650513          	addi	a0,a0,582 # ffffffffc0202968 <best_fit_pmm_manager+0x420>
ffffffffc020172a:	a23fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    kmem_cache_t *cache128 = kmalloc_caches[size_to_index(128)];
ffffffffc020172e:	020ab403          	ld	s0,32(s5)
    int count = cache128->objects_per_slab;
ffffffffc0201732:	01442903          	lw	s2,20(s0)
    void **arr = kmalloc(sizeof(void*) * count);
ffffffffc0201736:	00391a13          	slli	s4,s2,0x3
ffffffffc020173a:	8552                	mv	a0,s4
ffffffffc020173c:	e75ff0ef          	jal	ra,ffffffffc02015b0 <kmalloc>
ffffffffc0201740:	89aa                	mv	s3,a0
    int count = cache128->objects_per_slab;
ffffffffc0201742:	00090b1b          	sext.w	s6,s2
    assert(arr != NULL);
ffffffffc0201746:	2e050363          	beqz	a0,ffffffffc0201a2c <slub_check+0x3c6>

    cprintf("   - Allocating %d objects to fill a slab...\n", count);
ffffffffc020174a:	85da                	mv	a1,s6
ffffffffc020174c:	00001517          	auipc	a0,0x1
ffffffffc0201750:	26450513          	addi	a0,a0,612 # ffffffffc02029b0 <best_fit_pmm_manager+0x468>
ffffffffc0201754:	9f9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < count; i++) {
ffffffffc0201758:	03605263          	blez	s6,ffffffffc020177c <slub_check+0x116>
ffffffffc020175c:	02091793          	slli	a5,s2,0x20
ffffffffc0201760:	01d7d493          	srli	s1,a5,0x1d
ffffffffc0201764:	8dce                	mv	s11,s3
ffffffffc0201766:	94ce                	add	s1,s1,s3
        arr[i] = kmem_cache_alloc(cache128);
ffffffffc0201768:	8522                	mv	a0,s0
ffffffffc020176a:	c15ff0ef          	jal	ra,ffffffffc020137e <kmem_cache_alloc>
ffffffffc020176e:	00adb023          	sd	a0,0(s11)
        assert(arr[i] != NULL);
ffffffffc0201772:	16050763          	beqz	a0,ffffffffc02018e0 <slub_check+0x27a>
    for (int i = 0; i < count; i++) {
ffffffffc0201776:	0da1                	addi	s11,s11,8
ffffffffc0201778:	fe9d98e3          	bne	s11,s1,ffffffffc0201768 <slub_check+0x102>
    }
    assert(list_empty(&(cache128->partial_slabs)));
ffffffffc020177c:	701c                	ld	a5,32(s0)
ffffffffc020177e:	01840d93          	addi	s11,s0,24
ffffffffc0201782:	2cfd9563          	bne	s11,a5,ffffffffc0201a4c <slub_check+0x3e6>
    assert(!list_empty(&(cache128->full_slabs)));
ffffffffc0201786:	781c                	ld	a5,48(s0)
ffffffffc0201788:	02840493          	addi	s1,s0,40
ffffffffc020178c:	22f48363          	beq	s1,a5,ffffffffc02019b2 <slub_check+0x34c>
    cprintf("   - Slab moved to 'full' list. OK.\n");
ffffffffc0201790:	00001517          	auipc	a0,0x1
ffffffffc0201794:	2b050513          	addi	a0,a0,688 # ffffffffc0202a40 <best_fit_pmm_manager+0x4f8>
ffffffffc0201798:	9b5fe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("   - Freeing one object...\n");
ffffffffc020179c:	00001517          	auipc	a0,0x1
ffffffffc02017a0:	2cc50513          	addi	a0,a0,716 # ffffffffc0202a68 <best_fit_pmm_manager+0x520>
ffffffffc02017a4:	9a9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    kfree(arr[count-1]);
ffffffffc02017a8:	9a4e                	add	s4,s4,s3
ffffffffc02017aa:	ff8a3503          	ld	a0,-8(s4)
    if (obj == NULL) return;
ffffffffc02017ae:	c119                	beqz	a0,ffffffffc02017b4 <slub_check+0x14e>
ffffffffc02017b0:	b33ff0ef          	jal	ra,ffffffffc02012e2 <kfree.part.0>
    assert(!list_empty(&(cache128->partial_slabs)));
ffffffffc02017b4:	701c                	ld	a5,32(s0)
ffffffffc02017b6:	22fd8e63          	beq	s11,a5,ffffffffc02019f2 <slub_check+0x38c>
    assert(list_empty(&(cache128->full_slabs)));
ffffffffc02017ba:	781c                	ld	a5,48(s0)
ffffffffc02017bc:	20f49b63          	bne	s1,a5,ffffffffc02019d2 <slub_check+0x36c>
    cprintf("   - Slab moved back to 'partial' list. OK.\n");
ffffffffc02017c0:	00001517          	auipc	a0,0x1
ffffffffc02017c4:	31850513          	addi	a0,a0,792 # ffffffffc0202ad8 <best_fit_pmm_manager+0x590>
ffffffffc02017c8:	985fe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("   - Freeing all remaining objects...\n");
ffffffffc02017cc:	00001517          	auipc	a0,0x1
ffffffffc02017d0:	33c50513          	addi	a0,a0,828 # ffffffffc0202b08 <best_fit_pmm_manager+0x5c0>
ffffffffc02017d4:	979fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < count - 1; i++) {
ffffffffc02017d8:	4785                	li	a5,1
ffffffffc02017da:	0367d163          	bge	a5,s6,ffffffffc02017fc <slub_check+0x196>
ffffffffc02017de:	3979                	addiw	s2,s2,-2
ffffffffc02017e0:	02091793          	slli	a5,s2,0x20
ffffffffc02017e4:	01d7d913          	srli	s2,a5,0x1d
ffffffffc02017e8:	0921                	addi	s2,s2,8
ffffffffc02017ea:	84ce                	mv	s1,s3
ffffffffc02017ec:	994e                	add	s2,s2,s3
        kfree(arr[i]);
ffffffffc02017ee:	6088                	ld	a0,0(s1)
    if (obj == NULL) return;
ffffffffc02017f0:	c119                	beqz	a0,ffffffffc02017f6 <slub_check+0x190>
ffffffffc02017f2:	af1ff0ef          	jal	ra,ffffffffc02012e2 <kfree.part.0>
    for (int i = 0; i < count - 1; i++) {
ffffffffc02017f6:	04a1                	addi	s1,s1,8
ffffffffc02017f8:	fe991be3          	bne	s2,s1,ffffffffc02017ee <slub_check+0x188>
    }
    assert(list_empty(&(cache128->partial_slabs)));
ffffffffc02017fc:	701c                	ld	a5,32(s0)
ffffffffc02017fe:	26fd9763          	bne	s11,a5,ffffffffc0201a6c <slub_check+0x406>
    cprintf("   - Slab was freed back to page manager. OK.\n");
ffffffffc0201802:	00001517          	auipc	a0,0x1
ffffffffc0201806:	32e50513          	addi	a0,a0,814 # ffffffffc0202b30 <best_fit_pmm_manager+0x5e8>
ffffffffc020180a:	943fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (obj == NULL) return;
ffffffffc020180e:	854e                	mv	a0,s3
ffffffffc0201810:	ad3ff0ef          	jal	ra,ffffffffc02012e2 <kfree.part.0>
    kfree(arr);

    cprintf("3. Multi-cache test...\n");
ffffffffc0201814:	00001517          	auipc	a0,0x1
ffffffffc0201818:	34c50513          	addi	a0,a0,844 # ffffffffc0202b60 <best_fit_pmm_manager+0x618>
ffffffffc020181c:	931fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *p_small = kmalloc(8);
ffffffffc0201820:	4521                	li	a0,8
ffffffffc0201822:	d8fff0ef          	jal	ra,ffffffffc02015b0 <kmalloc>
ffffffffc0201826:	84aa                	mv	s1,a0
    void *p_large = kmalloc(1000);
ffffffffc0201828:	3e800513          	li	a0,1000
ffffffffc020182c:	d85ff0ef          	jal	ra,ffffffffc02015b0 <kmalloc>
    return pa2page(PADDR(obj));
ffffffffc0201830:	c0200837          	lui	a6,0xc0200
    void *p_large = kmalloc(1000);
ffffffffc0201834:	842a                	mv	s0,a0
    return pa2page(PADDR(obj));
ffffffffc0201836:	1304e163          	bltu	s1,a6,ffffffffc0201958 <slub_check+0x2f2>
ffffffffc020183a:	000d3783          	ld	a5,0(s10)
    if (PPN(pa) >= npage) {
ffffffffc020183e:	000cb583          	ld	a1,0(s9)
ffffffffc0201842:	40f48733          	sub	a4,s1,a5
ffffffffc0201846:	8331                	srli	a4,a4,0xc
ffffffffc0201848:	0ab77c63          	bgeu	a4,a1,ffffffffc0201900 <slub_check+0x29a>
    return &pages[PPN(pa) - nbase];
ffffffffc020184c:	41770633          	sub	a2,a4,s7
    assert(obj_to_page(p_small)->cache == kmalloc_caches[0]);
ffffffffc0201850:	00261713          	slli	a4,a2,0x2
ffffffffc0201854:	000c3683          	ld	a3,0(s8)
ffffffffc0201858:	9732                	add	a4,a4,a2
ffffffffc020185a:	0712                	slli	a4,a4,0x4
ffffffffc020185c:	9736                	add	a4,a4,a3
ffffffffc020185e:	7710                	ld	a2,40(a4)
ffffffffc0201860:	000ab703          	ld	a4,0(s5)
ffffffffc0201864:	0ce61a63          	bne	a2,a4,ffffffffc0201938 <slub_check+0x2d2>
    return pa2page(PADDR(obj));
ffffffffc0201868:	1b056563          	bltu	a0,a6,ffffffffc0201a12 <slub_check+0x3ac>
ffffffffc020186c:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc0201870:	83b1                	srli	a5,a5,0xc
ffffffffc0201872:	08b7f763          	bgeu	a5,a1,ffffffffc0201900 <slub_check+0x29a>
    return &pages[PPN(pa) - nbase];
ffffffffc0201876:	41778bb3          	sub	s7,a5,s7
    assert(obj_to_page(p_large)->cache == kmalloc_caches[size_to_index(1000)]);
ffffffffc020187a:	002b9793          	slli	a5,s7,0x2
ffffffffc020187e:	9bbe                	add	s7,s7,a5
ffffffffc0201880:	0b92                	slli	s7,s7,0x4
ffffffffc0201882:	9bb6                	add	s7,s7,a3
ffffffffc0201884:	028bb703          	ld	a4,40(s7)
ffffffffc0201888:	038ab783          	ld	a5,56(s5)
ffffffffc020188c:	08f71663          	bne	a4,a5,ffffffffc0201918 <slub_check+0x2b2>
    cprintf("   - kmalloc(8) and kmalloc(1000) allocated from correct caches. OK.\n");
ffffffffc0201890:	00001517          	auipc	a0,0x1
ffffffffc0201894:	36850513          	addi	a0,a0,872 # ffffffffc0202bf8 <best_fit_pmm_manager+0x6b0>
ffffffffc0201898:	8b5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (obj == NULL) return;
ffffffffc020189c:	c481                	beqz	s1,ffffffffc02018a4 <slub_check+0x23e>
ffffffffc020189e:	8526                	mv	a0,s1
ffffffffc02018a0:	a43ff0ef          	jal	ra,ffffffffc02012e2 <kfree.part.0>
ffffffffc02018a4:	c401                	beqz	s0,ffffffffc02018ac <slub_check+0x246>
ffffffffc02018a6:	8522                	mv	a0,s0
ffffffffc02018a8:	a3bff0ef          	jal	ra,ffffffffc02012e2 <kfree.part.0>
    kfree(p_small);
    kfree(p_large);
    cprintf("   - Both objects freed. OK.\n");
ffffffffc02018ac:	00001517          	auipc	a0,0x1
ffffffffc02018b0:	39450513          	addi	a0,a0,916 # ffffffffc0202c40 <best_fit_pmm_manager+0x6f8>
ffffffffc02018b4:	899fe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("--- SLUB Allocator Check Passed ---\n\n");
ffffffffc02018b8:	7406                	ld	s0,96(sp)
ffffffffc02018ba:	70a6                	ld	ra,104(sp)
ffffffffc02018bc:	64e6                	ld	s1,88(sp)
ffffffffc02018be:	6946                	ld	s2,80(sp)
ffffffffc02018c0:	69a6                	ld	s3,72(sp)
ffffffffc02018c2:	6a06                	ld	s4,64(sp)
ffffffffc02018c4:	7ae2                	ld	s5,56(sp)
ffffffffc02018c6:	7b42                	ld	s6,48(sp)
ffffffffc02018c8:	7ba2                	ld	s7,40(sp)
ffffffffc02018ca:	7c02                	ld	s8,32(sp)
ffffffffc02018cc:	6ce2                	ld	s9,24(sp)
ffffffffc02018ce:	6d42                	ld	s10,16(sp)
ffffffffc02018d0:	6da2                	ld	s11,8(sp)
    cprintf("--- SLUB Allocator Check Passed ---\n\n");
ffffffffc02018d2:	00001517          	auipc	a0,0x1
ffffffffc02018d6:	38e50513          	addi	a0,a0,910 # ffffffffc0202c60 <best_fit_pmm_manager+0x718>
ffffffffc02018da:	6165                	addi	sp,sp,112
    cprintf("--- SLUB Allocator Check Passed ---\n\n");
ffffffffc02018dc:	871fe06f          	j	ffffffffc020014c <cprintf>
        assert(arr[i] != NULL);
ffffffffc02018e0:	00001697          	auipc	a3,0x1
ffffffffc02018e4:	10068693          	addi	a3,a3,256 # ffffffffc02029e0 <best_fit_pmm_manager+0x498>
ffffffffc02018e8:	00001617          	auipc	a2,0x1
ffffffffc02018ec:	92060613          	addi	a2,a2,-1760 # ffffffffc0202208 <etext+0x26c>
ffffffffc02018f0:	10d00593          	li	a1,269
ffffffffc02018f4:	00001517          	auipc	a0,0x1
ffffffffc02018f8:	dd450513          	addi	a0,a0,-556 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02018fc:	8c7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201900:	00001617          	auipc	a2,0x1
ffffffffc0201904:	d3860613          	addi	a2,a2,-712 # ffffffffc0202638 <best_fit_pmm_manager+0xf0>
ffffffffc0201908:	06a00593          	li	a1,106
ffffffffc020190c:	00001517          	auipc	a0,0x1
ffffffffc0201910:	d4c50513          	addi	a0,a0,-692 # ffffffffc0202658 <best_fit_pmm_manager+0x110>
ffffffffc0201914:	8affe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(obj_to_page(p_large)->cache == kmalloc_caches[size_to_index(1000)]);
ffffffffc0201918:	00001697          	auipc	a3,0x1
ffffffffc020191c:	29868693          	addi	a3,a3,664 # ffffffffc0202bb0 <best_fit_pmm_manager+0x668>
ffffffffc0201920:	00001617          	auipc	a2,0x1
ffffffffc0201924:	8e860613          	addi	a2,a2,-1816 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201928:	12500593          	li	a1,293
ffffffffc020192c:	00001517          	auipc	a0,0x1
ffffffffc0201930:	d9c50513          	addi	a0,a0,-612 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201934:	88ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(obj_to_page(p_small)->cache == kmalloc_caches[0]);
ffffffffc0201938:	00001697          	auipc	a3,0x1
ffffffffc020193c:	24068693          	addi	a3,a3,576 # ffffffffc0202b78 <best_fit_pmm_manager+0x630>
ffffffffc0201940:	00001617          	auipc	a2,0x1
ffffffffc0201944:	8c860613          	addi	a2,a2,-1848 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201948:	12400593          	li	a1,292
ffffffffc020194c:	00001517          	auipc	a0,0x1
ffffffffc0201950:	d7c50513          	addi	a0,a0,-644 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201954:	86ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    return pa2page(PADDR(obj));
ffffffffc0201958:	86a6                	mv	a3,s1
ffffffffc020195a:	00001617          	auipc	a2,0x1
ffffffffc020195e:	cb660613          	addi	a2,a2,-842 # ffffffffc0202610 <best_fit_pmm_manager+0xc8>
ffffffffc0201962:	04d00593          	li	a1,77
ffffffffc0201966:	00001517          	auipc	a0,0x1
ffffffffc020196a:	d6250513          	addi	a0,a0,-670 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc020196e:	855fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page1->cache == kmalloc_caches[size_to_index(30)]);
ffffffffc0201972:	00001697          	auipc	a3,0x1
ffffffffc0201976:	f7668693          	addi	a3,a3,-138 # ffffffffc02028e8 <best_fit_pmm_manager+0x3a0>
ffffffffc020197a:	00001617          	auipc	a2,0x1
ffffffffc020197e:	88e60613          	addi	a2,a2,-1906 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201982:	0ff00593          	li	a1,255
ffffffffc0201986:	00001517          	auipc	a0,0x1
ffffffffc020198a:	d4250513          	addi	a0,a0,-702 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc020198e:	835fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc0201992:	00001697          	auipc	a3,0x1
ffffffffc0201996:	f4668693          	addi	a3,a3,-186 # ffffffffc02028d8 <best_fit_pmm_manager+0x390>
ffffffffc020199a:	00001617          	auipc	a2,0x1
ffffffffc020199e:	86e60613          	addi	a2,a2,-1938 # ffffffffc0202208 <etext+0x26c>
ffffffffc02019a2:	0fd00593          	li	a1,253
ffffffffc02019a6:	00001517          	auipc	a0,0x1
ffffffffc02019aa:	d2250513          	addi	a0,a0,-734 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02019ae:	815fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&(cache128->full_slabs)));
ffffffffc02019b2:	00001697          	auipc	a3,0x1
ffffffffc02019b6:	06668693          	addi	a3,a3,102 # ffffffffc0202a18 <best_fit_pmm_manager+0x4d0>
ffffffffc02019ba:	00001617          	auipc	a2,0x1
ffffffffc02019be:	84e60613          	addi	a2,a2,-1970 # ffffffffc0202208 <etext+0x26c>
ffffffffc02019c2:	11000593          	li	a1,272
ffffffffc02019c6:	00001517          	auipc	a0,0x1
ffffffffc02019ca:	d0250513          	addi	a0,a0,-766 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02019ce:	ff4fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&(cache128->full_slabs)));
ffffffffc02019d2:	00001697          	auipc	a3,0x1
ffffffffc02019d6:	0de68693          	addi	a3,a3,222 # ffffffffc0202ab0 <best_fit_pmm_manager+0x568>
ffffffffc02019da:	00001617          	auipc	a2,0x1
ffffffffc02019de:	82e60613          	addi	a2,a2,-2002 # ffffffffc0202208 <etext+0x26c>
ffffffffc02019e2:	11600593          	li	a1,278
ffffffffc02019e6:	00001517          	auipc	a0,0x1
ffffffffc02019ea:	ce250513          	addi	a0,a0,-798 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc02019ee:	fd4fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&(cache128->partial_slabs)));
ffffffffc02019f2:	00001697          	auipc	a3,0x1
ffffffffc02019f6:	09668693          	addi	a3,a3,150 # ffffffffc0202a88 <best_fit_pmm_manager+0x540>
ffffffffc02019fa:	00001617          	auipc	a2,0x1
ffffffffc02019fe:	80e60613          	addi	a2,a2,-2034 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201a02:	11500593          	li	a1,277
ffffffffc0201a06:	00001517          	auipc	a0,0x1
ffffffffc0201a0a:	cc250513          	addi	a0,a0,-830 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201a0e:	fb4fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    return pa2page(PADDR(obj));
ffffffffc0201a12:	86a2                	mv	a3,s0
ffffffffc0201a14:	00001617          	auipc	a2,0x1
ffffffffc0201a18:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0202610 <best_fit_pmm_manager+0xc8>
ffffffffc0201a1c:	04d00593          	li	a1,77
ffffffffc0201a20:	00001517          	auipc	a0,0x1
ffffffffc0201a24:	ca850513          	addi	a0,a0,-856 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201a28:	f9afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(arr != NULL);
ffffffffc0201a2c:	00001697          	auipc	a3,0x1
ffffffffc0201a30:	f7468693          	addi	a3,a3,-140 # ffffffffc02029a0 <best_fit_pmm_manager+0x458>
ffffffffc0201a34:	00000617          	auipc	a2,0x0
ffffffffc0201a38:	7d460613          	addi	a2,a2,2004 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201a3c:	10800593          	li	a1,264
ffffffffc0201a40:	00001517          	auipc	a0,0x1
ffffffffc0201a44:	c8850513          	addi	a0,a0,-888 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201a48:	f7afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&(cache128->partial_slabs)));
ffffffffc0201a4c:	00001697          	auipc	a3,0x1
ffffffffc0201a50:	fa468693          	addi	a3,a3,-92 # ffffffffc02029f0 <best_fit_pmm_manager+0x4a8>
ffffffffc0201a54:	00000617          	auipc	a2,0x0
ffffffffc0201a58:	7b460613          	addi	a2,a2,1972 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201a5c:	10f00593          	li	a1,271
ffffffffc0201a60:	00001517          	auipc	a0,0x1
ffffffffc0201a64:	c6850513          	addi	a0,a0,-920 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201a68:	f5afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&(cache128->partial_slabs)));
ffffffffc0201a6c:	00001697          	auipc	a3,0x1
ffffffffc0201a70:	f8468693          	addi	a3,a3,-124 # ffffffffc02029f0 <best_fit_pmm_manager+0x4a8>
ffffffffc0201a74:	00000617          	auipc	a2,0x0
ffffffffc0201a78:	79460613          	addi	a2,a2,1940 # ffffffffc0202208 <etext+0x26c>
ffffffffc0201a7c:	11d00593          	li	a1,285
ffffffffc0201a80:	00001517          	auipc	a0,0x1
ffffffffc0201a84:	c4850513          	addi	a0,a0,-952 # ffffffffc02026c8 <best_fit_pmm_manager+0x180>
ffffffffc0201a88:	f3afe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201a8c <printnum>:
ffffffffc0201a8c:	02069813          	slli	a6,a3,0x20
ffffffffc0201a90:	7179                	addi	sp,sp,-48
ffffffffc0201a92:	02085813          	srli	a6,a6,0x20
ffffffffc0201a96:	e052                	sd	s4,0(sp)
ffffffffc0201a98:	03067a33          	remu	s4,a2,a6
ffffffffc0201a9c:	f022                	sd	s0,32(sp)
ffffffffc0201a9e:	ec26                	sd	s1,24(sp)
ffffffffc0201aa0:	e84a                	sd	s2,16(sp)
ffffffffc0201aa2:	f406                	sd	ra,40(sp)
ffffffffc0201aa4:	e44e                	sd	s3,8(sp)
ffffffffc0201aa6:	84aa                	mv	s1,a0
ffffffffc0201aa8:	892e                	mv	s2,a1
ffffffffc0201aaa:	fff7041b          	addiw	s0,a4,-1
ffffffffc0201aae:	2a01                	sext.w	s4,s4
ffffffffc0201ab0:	03067e63          	bgeu	a2,a6,ffffffffc0201aec <printnum+0x60>
ffffffffc0201ab4:	89be                	mv	s3,a5
ffffffffc0201ab6:	00805763          	blez	s0,ffffffffc0201ac4 <printnum+0x38>
ffffffffc0201aba:	347d                	addiw	s0,s0,-1
ffffffffc0201abc:	85ca                	mv	a1,s2
ffffffffc0201abe:	854e                	mv	a0,s3
ffffffffc0201ac0:	9482                	jalr	s1
ffffffffc0201ac2:	fc65                	bnez	s0,ffffffffc0201aba <printnum+0x2e>
ffffffffc0201ac4:	1a02                	slli	s4,s4,0x20
ffffffffc0201ac6:	00001797          	auipc	a5,0x1
ffffffffc0201aca:	1c278793          	addi	a5,a5,450 # ffffffffc0202c88 <best_fit_pmm_manager+0x740>
ffffffffc0201ace:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201ad2:	9a3e                	add	s4,s4,a5
ffffffffc0201ad4:	7402                	ld	s0,32(sp)
ffffffffc0201ad6:	000a4503          	lbu	a0,0(s4)
ffffffffc0201ada:	70a2                	ld	ra,40(sp)
ffffffffc0201adc:	69a2                	ld	s3,8(sp)
ffffffffc0201ade:	6a02                	ld	s4,0(sp)
ffffffffc0201ae0:	85ca                	mv	a1,s2
ffffffffc0201ae2:	87a6                	mv	a5,s1
ffffffffc0201ae4:	6942                	ld	s2,16(sp)
ffffffffc0201ae6:	64e2                	ld	s1,24(sp)
ffffffffc0201ae8:	6145                	addi	sp,sp,48
ffffffffc0201aea:	8782                	jr	a5
ffffffffc0201aec:	03065633          	divu	a2,a2,a6
ffffffffc0201af0:	8722                	mv	a4,s0
ffffffffc0201af2:	f9bff0ef          	jal	ra,ffffffffc0201a8c <printnum>
ffffffffc0201af6:	b7f9                	j	ffffffffc0201ac4 <printnum+0x38>

ffffffffc0201af8 <sprintputch>:
ffffffffc0201af8:	499c                	lw	a5,16(a1)
ffffffffc0201afa:	6198                	ld	a4,0(a1)
ffffffffc0201afc:	6594                	ld	a3,8(a1)
ffffffffc0201afe:	2785                	addiw	a5,a5,1
ffffffffc0201b00:	c99c                	sw	a5,16(a1)
ffffffffc0201b02:	00d77763          	bgeu	a4,a3,ffffffffc0201b10 <sprintputch+0x18>
ffffffffc0201b06:	00170793          	addi	a5,a4,1 # 1001 <kern_entry-0xffffffffc01fefff>
ffffffffc0201b0a:	e19c                	sd	a5,0(a1)
ffffffffc0201b0c:	00a70023          	sb	a0,0(a4)
ffffffffc0201b10:	8082                	ret

ffffffffc0201b12 <vprintfmt>:
ffffffffc0201b12:	7119                	addi	sp,sp,-128
ffffffffc0201b14:	f4a6                	sd	s1,104(sp)
ffffffffc0201b16:	f0ca                	sd	s2,96(sp)
ffffffffc0201b18:	ecce                	sd	s3,88(sp)
ffffffffc0201b1a:	e8d2                	sd	s4,80(sp)
ffffffffc0201b1c:	e4d6                	sd	s5,72(sp)
ffffffffc0201b1e:	e0da                	sd	s6,64(sp)
ffffffffc0201b20:	fc5e                	sd	s7,56(sp)
ffffffffc0201b22:	f06a                	sd	s10,32(sp)
ffffffffc0201b24:	fc86                	sd	ra,120(sp)
ffffffffc0201b26:	f8a2                	sd	s0,112(sp)
ffffffffc0201b28:	f862                	sd	s8,48(sp)
ffffffffc0201b2a:	f466                	sd	s9,40(sp)
ffffffffc0201b2c:	ec6e                	sd	s11,24(sp)
ffffffffc0201b2e:	892a                	mv	s2,a0
ffffffffc0201b30:	84ae                	mv	s1,a1
ffffffffc0201b32:	8d32                	mv	s10,a2
ffffffffc0201b34:	8a36                	mv	s4,a3
ffffffffc0201b36:	02500993          	li	s3,37
ffffffffc0201b3a:	5b7d                	li	s6,-1
ffffffffc0201b3c:	00001a97          	auipc	s5,0x1
ffffffffc0201b40:	180a8a93          	addi	s5,s5,384 # ffffffffc0202cbc <best_fit_pmm_manager+0x774>
ffffffffc0201b44:	00001b97          	auipc	s7,0x1
ffffffffc0201b48:	354b8b93          	addi	s7,s7,852 # ffffffffc0202e98 <error_string>
ffffffffc0201b4c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201b50:	001d0413          	addi	s0,s10,1
ffffffffc0201b54:	01350a63          	beq	a0,s3,ffffffffc0201b68 <vprintfmt+0x56>
ffffffffc0201b58:	c121                	beqz	a0,ffffffffc0201b98 <vprintfmt+0x86>
ffffffffc0201b5a:	85a6                	mv	a1,s1
ffffffffc0201b5c:	0405                	addi	s0,s0,1
ffffffffc0201b5e:	9902                	jalr	s2
ffffffffc0201b60:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201b64:	ff351ae3          	bne	a0,s3,ffffffffc0201b58 <vprintfmt+0x46>
ffffffffc0201b68:	00044603          	lbu	a2,0(s0)
ffffffffc0201b6c:	02000793          	li	a5,32
ffffffffc0201b70:	4c81                	li	s9,0
ffffffffc0201b72:	4881                	li	a7,0
ffffffffc0201b74:	5c7d                	li	s8,-1
ffffffffc0201b76:	5dfd                	li	s11,-1
ffffffffc0201b78:	05500513          	li	a0,85
ffffffffc0201b7c:	4825                	li	a6,9
ffffffffc0201b7e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b82:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b86:	00140d13          	addi	s10,s0,1
ffffffffc0201b8a:	04b56263          	bltu	a0,a1,ffffffffc0201bce <vprintfmt+0xbc>
ffffffffc0201b8e:	058a                	slli	a1,a1,0x2
ffffffffc0201b90:	95d6                	add	a1,a1,s5
ffffffffc0201b92:	4194                	lw	a3,0(a1)
ffffffffc0201b94:	96d6                	add	a3,a3,s5
ffffffffc0201b96:	8682                	jr	a3
ffffffffc0201b98:	70e6                	ld	ra,120(sp)
ffffffffc0201b9a:	7446                	ld	s0,112(sp)
ffffffffc0201b9c:	74a6                	ld	s1,104(sp)
ffffffffc0201b9e:	7906                	ld	s2,96(sp)
ffffffffc0201ba0:	69e6                	ld	s3,88(sp)
ffffffffc0201ba2:	6a46                	ld	s4,80(sp)
ffffffffc0201ba4:	6aa6                	ld	s5,72(sp)
ffffffffc0201ba6:	6b06                	ld	s6,64(sp)
ffffffffc0201ba8:	7be2                	ld	s7,56(sp)
ffffffffc0201baa:	7c42                	ld	s8,48(sp)
ffffffffc0201bac:	7ca2                	ld	s9,40(sp)
ffffffffc0201bae:	7d02                	ld	s10,32(sp)
ffffffffc0201bb0:	6de2                	ld	s11,24(sp)
ffffffffc0201bb2:	6109                	addi	sp,sp,128
ffffffffc0201bb4:	8082                	ret
ffffffffc0201bb6:	87b2                	mv	a5,a2
ffffffffc0201bb8:	00144603          	lbu	a2,1(s0)
ffffffffc0201bbc:	846a                	mv	s0,s10
ffffffffc0201bbe:	00140d13          	addi	s10,s0,1
ffffffffc0201bc2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201bc6:	0ff5f593          	zext.b	a1,a1
ffffffffc0201bca:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b8e <vprintfmt+0x7c>
ffffffffc0201bce:	85a6                	mv	a1,s1
ffffffffc0201bd0:	02500513          	li	a0,37
ffffffffc0201bd4:	9902                	jalr	s2
ffffffffc0201bd6:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201bda:	8d22                	mv	s10,s0
ffffffffc0201bdc:	f73788e3          	beq	a5,s3,ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201be0:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201be4:	1d7d                	addi	s10,s10,-1
ffffffffc0201be6:	ff379de3          	bne	a5,s3,ffffffffc0201be0 <vprintfmt+0xce>
ffffffffc0201bea:	b78d                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201bec:	fd060c1b          	addiw	s8,a2,-48
ffffffffc0201bf0:	00144603          	lbu	a2,1(s0)
ffffffffc0201bf4:	846a                	mv	s0,s10
ffffffffc0201bf6:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201bfa:	0006059b          	sext.w	a1,a2
ffffffffc0201bfe:	02d86463          	bltu	a6,a3,ffffffffc0201c26 <vprintfmt+0x114>
ffffffffc0201c02:	00144603          	lbu	a2,1(s0)
ffffffffc0201c06:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201c0a:	0186873b          	addw	a4,a3,s8
ffffffffc0201c0e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201c12:	9f2d                	addw	a4,a4,a1
ffffffffc0201c14:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201c18:	0405                	addi	s0,s0,1
ffffffffc0201c1a:	fd070c1b          	addiw	s8,a4,-48
ffffffffc0201c1e:	0006059b          	sext.w	a1,a2
ffffffffc0201c22:	fed870e3          	bgeu	a6,a3,ffffffffc0201c02 <vprintfmt+0xf0>
ffffffffc0201c26:	f40ddce3          	bgez	s11,ffffffffc0201b7e <vprintfmt+0x6c>
ffffffffc0201c2a:	8de2                	mv	s11,s8
ffffffffc0201c2c:	5c7d                	li	s8,-1
ffffffffc0201c2e:	bf81                	j	ffffffffc0201b7e <vprintfmt+0x6c>
ffffffffc0201c30:	fffdc693          	not	a3,s11
ffffffffc0201c34:	96fd                	srai	a3,a3,0x3f
ffffffffc0201c36:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201c3a:	00144603          	lbu	a2,1(s0)
ffffffffc0201c3e:	2d81                	sext.w	s11,s11
ffffffffc0201c40:	846a                	mv	s0,s10
ffffffffc0201c42:	bf35                	j	ffffffffc0201b7e <vprintfmt+0x6c>
ffffffffc0201c44:	000a2c03          	lw	s8,0(s4)
ffffffffc0201c48:	00144603          	lbu	a2,1(s0)
ffffffffc0201c4c:	0a21                	addi	s4,s4,8
ffffffffc0201c4e:	846a                	mv	s0,s10
ffffffffc0201c50:	bfd9                	j	ffffffffc0201c26 <vprintfmt+0x114>
ffffffffc0201c52:	4705                	li	a4,1
ffffffffc0201c54:	008a0593          	addi	a1,s4,8
ffffffffc0201c58:	01174463          	blt	a4,a7,ffffffffc0201c60 <vprintfmt+0x14e>
ffffffffc0201c5c:	1a088e63          	beqz	a7,ffffffffc0201e18 <vprintfmt+0x306>
ffffffffc0201c60:	000a3603          	ld	a2,0(s4)
ffffffffc0201c64:	46c1                	li	a3,16
ffffffffc0201c66:	8a2e                	mv	s4,a1
ffffffffc0201c68:	2781                	sext.w	a5,a5
ffffffffc0201c6a:	876e                	mv	a4,s11
ffffffffc0201c6c:	85a6                	mv	a1,s1
ffffffffc0201c6e:	854a                	mv	a0,s2
ffffffffc0201c70:	e1dff0ef          	jal	ra,ffffffffc0201a8c <printnum>
ffffffffc0201c74:	bde1                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201c76:	000a2503          	lw	a0,0(s4)
ffffffffc0201c7a:	85a6                	mv	a1,s1
ffffffffc0201c7c:	0a21                	addi	s4,s4,8
ffffffffc0201c7e:	9902                	jalr	s2
ffffffffc0201c80:	b5f1                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201c82:	4705                	li	a4,1
ffffffffc0201c84:	008a0593          	addi	a1,s4,8
ffffffffc0201c88:	01174463          	blt	a4,a7,ffffffffc0201c90 <vprintfmt+0x17e>
ffffffffc0201c8c:	18088163          	beqz	a7,ffffffffc0201e0e <vprintfmt+0x2fc>
ffffffffc0201c90:	000a3603          	ld	a2,0(s4)
ffffffffc0201c94:	46a9                	li	a3,10
ffffffffc0201c96:	8a2e                	mv	s4,a1
ffffffffc0201c98:	bfc1                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201c9a:	00144603          	lbu	a2,1(s0)
ffffffffc0201c9e:	4c85                	li	s9,1
ffffffffc0201ca0:	846a                	mv	s0,s10
ffffffffc0201ca2:	bdf1                	j	ffffffffc0201b7e <vprintfmt+0x6c>
ffffffffc0201ca4:	85a6                	mv	a1,s1
ffffffffc0201ca6:	02500513          	li	a0,37
ffffffffc0201caa:	9902                	jalr	s2
ffffffffc0201cac:	b545                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201cae:	00144603          	lbu	a2,1(s0)
ffffffffc0201cb2:	2885                	addiw	a7,a7,1
ffffffffc0201cb4:	846a                	mv	s0,s10
ffffffffc0201cb6:	b5e1                	j	ffffffffc0201b7e <vprintfmt+0x6c>
ffffffffc0201cb8:	4705                	li	a4,1
ffffffffc0201cba:	008a0593          	addi	a1,s4,8
ffffffffc0201cbe:	01174463          	blt	a4,a7,ffffffffc0201cc6 <vprintfmt+0x1b4>
ffffffffc0201cc2:	14088163          	beqz	a7,ffffffffc0201e04 <vprintfmt+0x2f2>
ffffffffc0201cc6:	000a3603          	ld	a2,0(s4)
ffffffffc0201cca:	46a1                	li	a3,8
ffffffffc0201ccc:	8a2e                	mv	s4,a1
ffffffffc0201cce:	bf69                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201cd0:	03000513          	li	a0,48
ffffffffc0201cd4:	85a6                	mv	a1,s1
ffffffffc0201cd6:	e03e                	sd	a5,0(sp)
ffffffffc0201cd8:	9902                	jalr	s2
ffffffffc0201cda:	85a6                	mv	a1,s1
ffffffffc0201cdc:	07800513          	li	a0,120
ffffffffc0201ce0:	9902                	jalr	s2
ffffffffc0201ce2:	0a21                	addi	s4,s4,8
ffffffffc0201ce4:	6782                	ld	a5,0(sp)
ffffffffc0201ce6:	46c1                	li	a3,16
ffffffffc0201ce8:	ff8a3603          	ld	a2,-8(s4)
ffffffffc0201cec:	bfb5                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201cee:	000a3403          	ld	s0,0(s4)
ffffffffc0201cf2:	008a0713          	addi	a4,s4,8
ffffffffc0201cf6:	e03a                	sd	a4,0(sp)
ffffffffc0201cf8:	14040263          	beqz	s0,ffffffffc0201e3c <vprintfmt+0x32a>
ffffffffc0201cfc:	0fb05763          	blez	s11,ffffffffc0201dea <vprintfmt+0x2d8>
ffffffffc0201d00:	02d00693          	li	a3,45
ffffffffc0201d04:	0cd79163          	bne	a5,a3,ffffffffc0201dc6 <vprintfmt+0x2b4>
ffffffffc0201d08:	00044783          	lbu	a5,0(s0)
ffffffffc0201d0c:	0007851b          	sext.w	a0,a5
ffffffffc0201d10:	cf85                	beqz	a5,ffffffffc0201d48 <vprintfmt+0x236>
ffffffffc0201d12:	00140a13          	addi	s4,s0,1
ffffffffc0201d16:	05e00413          	li	s0,94
ffffffffc0201d1a:	000c4563          	bltz	s8,ffffffffc0201d24 <vprintfmt+0x212>
ffffffffc0201d1e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201d20:	036c0263          	beq	s8,s6,ffffffffc0201d44 <vprintfmt+0x232>
ffffffffc0201d24:	85a6                	mv	a1,s1
ffffffffc0201d26:	0e0c8e63          	beqz	s9,ffffffffc0201e22 <vprintfmt+0x310>
ffffffffc0201d2a:	3781                	addiw	a5,a5,-32
ffffffffc0201d2c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201e22 <vprintfmt+0x310>
ffffffffc0201d30:	03f00513          	li	a0,63
ffffffffc0201d34:	9902                	jalr	s2
ffffffffc0201d36:	000a4783          	lbu	a5,0(s4)
ffffffffc0201d3a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d3c:	0a05                	addi	s4,s4,1
ffffffffc0201d3e:	0007851b          	sext.w	a0,a5
ffffffffc0201d42:	ffe1                	bnez	a5,ffffffffc0201d1a <vprintfmt+0x208>
ffffffffc0201d44:	01b05963          	blez	s11,ffffffffc0201d56 <vprintfmt+0x244>
ffffffffc0201d48:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d4a:	85a6                	mv	a1,s1
ffffffffc0201d4c:	02000513          	li	a0,32
ffffffffc0201d50:	9902                	jalr	s2
ffffffffc0201d52:	fe0d9be3          	bnez	s11,ffffffffc0201d48 <vprintfmt+0x236>
ffffffffc0201d56:	6a02                	ld	s4,0(sp)
ffffffffc0201d58:	bbd5                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201d5a:	4705                	li	a4,1
ffffffffc0201d5c:	008a0c93          	addi	s9,s4,8
ffffffffc0201d60:	01174463          	blt	a4,a7,ffffffffc0201d68 <vprintfmt+0x256>
ffffffffc0201d64:	08088d63          	beqz	a7,ffffffffc0201dfe <vprintfmt+0x2ec>
ffffffffc0201d68:	000a3403          	ld	s0,0(s4)
ffffffffc0201d6c:	0a044d63          	bltz	s0,ffffffffc0201e26 <vprintfmt+0x314>
ffffffffc0201d70:	8622                	mv	a2,s0
ffffffffc0201d72:	8a66                	mv	s4,s9
ffffffffc0201d74:	46a9                	li	a3,10
ffffffffc0201d76:	bdcd                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201d78:	000a2783          	lw	a5,0(s4)
ffffffffc0201d7c:	4719                	li	a4,6
ffffffffc0201d7e:	0a21                	addi	s4,s4,8
ffffffffc0201d80:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d84:	8fb5                	xor	a5,a5,a3
ffffffffc0201d86:	40d786bb          	subw	a3,a5,a3
ffffffffc0201d8a:	02d74163          	blt	a4,a3,ffffffffc0201dac <vprintfmt+0x29a>
ffffffffc0201d8e:	00369793          	slli	a5,a3,0x3
ffffffffc0201d92:	97de                	add	a5,a5,s7
ffffffffc0201d94:	639c                	ld	a5,0(a5)
ffffffffc0201d96:	cb99                	beqz	a5,ffffffffc0201dac <vprintfmt+0x29a>
ffffffffc0201d98:	86be                	mv	a3,a5
ffffffffc0201d9a:	00001617          	auipc	a2,0x1
ffffffffc0201d9e:	f1e60613          	addi	a2,a2,-226 # ffffffffc0202cb8 <best_fit_pmm_manager+0x770>
ffffffffc0201da2:	85a6                	mv	a1,s1
ffffffffc0201da4:	854a                	mv	a0,s2
ffffffffc0201da6:	0ce000ef          	jal	ra,ffffffffc0201e74 <printfmt>
ffffffffc0201daa:	b34d                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201dac:	00001617          	auipc	a2,0x1
ffffffffc0201db0:	efc60613          	addi	a2,a2,-260 # ffffffffc0202ca8 <best_fit_pmm_manager+0x760>
ffffffffc0201db4:	85a6                	mv	a1,s1
ffffffffc0201db6:	854a                	mv	a0,s2
ffffffffc0201db8:	0bc000ef          	jal	ra,ffffffffc0201e74 <printfmt>
ffffffffc0201dbc:	bb41                	j	ffffffffc0201b4c <vprintfmt+0x3a>
ffffffffc0201dbe:	00001417          	auipc	s0,0x1
ffffffffc0201dc2:	ee240413          	addi	s0,s0,-286 # ffffffffc0202ca0 <best_fit_pmm_manager+0x758>
ffffffffc0201dc6:	85e2                	mv	a1,s8
ffffffffc0201dc8:	8522                	mv	a0,s0
ffffffffc0201dca:	e43e                	sd	a5,8(sp)
ffffffffc0201dcc:	142000ef          	jal	ra,ffffffffc0201f0e <strnlen>
ffffffffc0201dd0:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201dd4:	01b05b63          	blez	s11,ffffffffc0201dea <vprintfmt+0x2d8>
ffffffffc0201dd8:	67a2                	ld	a5,8(sp)
ffffffffc0201dda:	00078a1b          	sext.w	s4,a5
ffffffffc0201dde:	3dfd                	addiw	s11,s11,-1
ffffffffc0201de0:	85a6                	mv	a1,s1
ffffffffc0201de2:	8552                	mv	a0,s4
ffffffffc0201de4:	9902                	jalr	s2
ffffffffc0201de6:	fe0d9ce3          	bnez	s11,ffffffffc0201dde <vprintfmt+0x2cc>
ffffffffc0201dea:	00044783          	lbu	a5,0(s0)
ffffffffc0201dee:	00140a13          	addi	s4,s0,1
ffffffffc0201df2:	0007851b          	sext.w	a0,a5
ffffffffc0201df6:	d3a5                	beqz	a5,ffffffffc0201d56 <vprintfmt+0x244>
ffffffffc0201df8:	05e00413          	li	s0,94
ffffffffc0201dfc:	bf39                	j	ffffffffc0201d1a <vprintfmt+0x208>
ffffffffc0201dfe:	000a2403          	lw	s0,0(s4)
ffffffffc0201e02:	b7ad                	j	ffffffffc0201d6c <vprintfmt+0x25a>
ffffffffc0201e04:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e08:	46a1                	li	a3,8
ffffffffc0201e0a:	8a2e                	mv	s4,a1
ffffffffc0201e0c:	bdb1                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201e0e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e12:	46a9                	li	a3,10
ffffffffc0201e14:	8a2e                	mv	s4,a1
ffffffffc0201e16:	bd89                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201e18:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e1c:	46c1                	li	a3,16
ffffffffc0201e1e:	8a2e                	mv	s4,a1
ffffffffc0201e20:	b5a1                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201e22:	9902                	jalr	s2
ffffffffc0201e24:	bf09                	j	ffffffffc0201d36 <vprintfmt+0x224>
ffffffffc0201e26:	85a6                	mv	a1,s1
ffffffffc0201e28:	02d00513          	li	a0,45
ffffffffc0201e2c:	e03e                	sd	a5,0(sp)
ffffffffc0201e2e:	9902                	jalr	s2
ffffffffc0201e30:	6782                	ld	a5,0(sp)
ffffffffc0201e32:	8a66                	mv	s4,s9
ffffffffc0201e34:	40800633          	neg	a2,s0
ffffffffc0201e38:	46a9                	li	a3,10
ffffffffc0201e3a:	b53d                	j	ffffffffc0201c68 <vprintfmt+0x156>
ffffffffc0201e3c:	03b05163          	blez	s11,ffffffffc0201e5e <vprintfmt+0x34c>
ffffffffc0201e40:	02d00693          	li	a3,45
ffffffffc0201e44:	f6d79de3          	bne	a5,a3,ffffffffc0201dbe <vprintfmt+0x2ac>
ffffffffc0201e48:	00001417          	auipc	s0,0x1
ffffffffc0201e4c:	e5840413          	addi	s0,s0,-424 # ffffffffc0202ca0 <best_fit_pmm_manager+0x758>
ffffffffc0201e50:	02800793          	li	a5,40
ffffffffc0201e54:	02800513          	li	a0,40
ffffffffc0201e58:	00140a13          	addi	s4,s0,1
ffffffffc0201e5c:	bd6d                	j	ffffffffc0201d16 <vprintfmt+0x204>
ffffffffc0201e5e:	00001a17          	auipc	s4,0x1
ffffffffc0201e62:	e43a0a13          	addi	s4,s4,-445 # ffffffffc0202ca1 <best_fit_pmm_manager+0x759>
ffffffffc0201e66:	02800513          	li	a0,40
ffffffffc0201e6a:	02800793          	li	a5,40
ffffffffc0201e6e:	05e00413          	li	s0,94
ffffffffc0201e72:	b565                	j	ffffffffc0201d1a <vprintfmt+0x208>

ffffffffc0201e74 <printfmt>:
ffffffffc0201e74:	715d                	addi	sp,sp,-80
ffffffffc0201e76:	02810313          	addi	t1,sp,40
ffffffffc0201e7a:	f436                	sd	a3,40(sp)
ffffffffc0201e7c:	869a                	mv	a3,t1
ffffffffc0201e7e:	ec06                	sd	ra,24(sp)
ffffffffc0201e80:	f83a                	sd	a4,48(sp)
ffffffffc0201e82:	fc3e                	sd	a5,56(sp)
ffffffffc0201e84:	e0c2                	sd	a6,64(sp)
ffffffffc0201e86:	e4c6                	sd	a7,72(sp)
ffffffffc0201e88:	e41a                	sd	t1,8(sp)
ffffffffc0201e8a:	c89ff0ef          	jal	ra,ffffffffc0201b12 <vprintfmt>
ffffffffc0201e8e:	60e2                	ld	ra,24(sp)
ffffffffc0201e90:	6161                	addi	sp,sp,80
ffffffffc0201e92:	8082                	ret

ffffffffc0201e94 <snprintf>:
ffffffffc0201e94:	711d                	addi	sp,sp,-96
ffffffffc0201e96:	15fd                	addi	a1,a1,-1
ffffffffc0201e98:	03810313          	addi	t1,sp,56
ffffffffc0201e9c:	95aa                	add	a1,a1,a0
ffffffffc0201e9e:	f406                	sd	ra,40(sp)
ffffffffc0201ea0:	fc36                	sd	a3,56(sp)
ffffffffc0201ea2:	e0ba                	sd	a4,64(sp)
ffffffffc0201ea4:	e4be                	sd	a5,72(sp)
ffffffffc0201ea6:	e8c2                	sd	a6,80(sp)
ffffffffc0201ea8:	ecc6                	sd	a7,88(sp)
ffffffffc0201eaa:	e01a                	sd	t1,0(sp)
ffffffffc0201eac:	e42a                	sd	a0,8(sp)
ffffffffc0201eae:	e82e                	sd	a1,16(sp)
ffffffffc0201eb0:	cc02                	sw	zero,24(sp)
ffffffffc0201eb2:	c115                	beqz	a0,ffffffffc0201ed6 <snprintf+0x42>
ffffffffc0201eb4:	02a5e163          	bltu	a1,a0,ffffffffc0201ed6 <snprintf+0x42>
ffffffffc0201eb8:	00000517          	auipc	a0,0x0
ffffffffc0201ebc:	c4050513          	addi	a0,a0,-960 # ffffffffc0201af8 <sprintputch>
ffffffffc0201ec0:	869a                	mv	a3,t1
ffffffffc0201ec2:	002c                	addi	a1,sp,8
ffffffffc0201ec4:	c4fff0ef          	jal	ra,ffffffffc0201b12 <vprintfmt>
ffffffffc0201ec8:	67a2                	ld	a5,8(sp)
ffffffffc0201eca:	00078023          	sb	zero,0(a5)
ffffffffc0201ece:	4562                	lw	a0,24(sp)
ffffffffc0201ed0:	70a2                	ld	ra,40(sp)
ffffffffc0201ed2:	6125                	addi	sp,sp,96
ffffffffc0201ed4:	8082                	ret
ffffffffc0201ed6:	5575                	li	a0,-3
ffffffffc0201ed8:	bfe5                	j	ffffffffc0201ed0 <snprintf+0x3c>

ffffffffc0201eda <sbi_console_putchar>:
ffffffffc0201eda:	4781                	li	a5,0
ffffffffc0201edc:	00004717          	auipc	a4,0x4
ffffffffc0201ee0:	13473703          	ld	a4,308(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201ee4:	88ba                	mv	a7,a4
ffffffffc0201ee6:	852a                	mv	a0,a0
ffffffffc0201ee8:	85be                	mv	a1,a5
ffffffffc0201eea:	863e                	mv	a2,a5
ffffffffc0201eec:	00000073          	ecall
ffffffffc0201ef0:	87aa                	mv	a5,a0
ffffffffc0201ef2:	8082                	ret

ffffffffc0201ef4 <strlen>:
ffffffffc0201ef4:	00054783          	lbu	a5,0(a0)
ffffffffc0201ef8:	872a                	mv	a4,a0
ffffffffc0201efa:	4501                	li	a0,0
ffffffffc0201efc:	cb81                	beqz	a5,ffffffffc0201f0c <strlen+0x18>
ffffffffc0201efe:	0505                	addi	a0,a0,1
ffffffffc0201f00:	00a707b3          	add	a5,a4,a0
ffffffffc0201f04:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f08:	fbfd                	bnez	a5,ffffffffc0201efe <strlen+0xa>
ffffffffc0201f0a:	8082                	ret
ffffffffc0201f0c:	8082                	ret

ffffffffc0201f0e <strnlen>:
ffffffffc0201f0e:	4781                	li	a5,0
ffffffffc0201f10:	e589                	bnez	a1,ffffffffc0201f1a <strnlen+0xc>
ffffffffc0201f12:	a811                	j	ffffffffc0201f26 <strnlen+0x18>
ffffffffc0201f14:	0785                	addi	a5,a5,1
ffffffffc0201f16:	00f58863          	beq	a1,a5,ffffffffc0201f26 <strnlen+0x18>
ffffffffc0201f1a:	00f50733          	add	a4,a0,a5
ffffffffc0201f1e:	00074703          	lbu	a4,0(a4)
ffffffffc0201f22:	fb6d                	bnez	a4,ffffffffc0201f14 <strnlen+0x6>
ffffffffc0201f24:	85be                	mv	a1,a5
ffffffffc0201f26:	852e                	mv	a0,a1
ffffffffc0201f28:	8082                	ret

ffffffffc0201f2a <strncpy>:
ffffffffc0201f2a:	ce09                	beqz	a2,ffffffffc0201f44 <strncpy+0x1a>
ffffffffc0201f2c:	962a                	add	a2,a2,a0
ffffffffc0201f2e:	87aa                	mv	a5,a0
ffffffffc0201f30:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f34:	0785                	addi	a5,a5,1
ffffffffc0201f36:	00e036b3          	snez	a3,a4
ffffffffc0201f3a:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0201f3e:	95b6                	add	a1,a1,a3
ffffffffc0201f40:	fec798e3          	bne	a5,a2,ffffffffc0201f30 <strncpy+0x6>
ffffffffc0201f44:	8082                	ret

ffffffffc0201f46 <strcmp>:
ffffffffc0201f46:	00054783          	lbu	a5,0(a0)
ffffffffc0201f4a:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f4e:	cb89                	beqz	a5,ffffffffc0201f60 <strcmp+0x1a>
ffffffffc0201f50:	0505                	addi	a0,a0,1
ffffffffc0201f52:	0585                	addi	a1,a1,1
ffffffffc0201f54:	fee789e3          	beq	a5,a4,ffffffffc0201f46 <strcmp>
ffffffffc0201f58:	0007851b          	sext.w	a0,a5
ffffffffc0201f5c:	9d19                	subw	a0,a0,a4
ffffffffc0201f5e:	8082                	ret
ffffffffc0201f60:	4501                	li	a0,0
ffffffffc0201f62:	bfed                	j	ffffffffc0201f5c <strcmp+0x16>

ffffffffc0201f64 <strncmp>:
ffffffffc0201f64:	c20d                	beqz	a2,ffffffffc0201f86 <strncmp+0x22>
ffffffffc0201f66:	962e                	add	a2,a2,a1
ffffffffc0201f68:	a031                	j	ffffffffc0201f74 <strncmp+0x10>
ffffffffc0201f6a:	0505                	addi	a0,a0,1
ffffffffc0201f6c:	00e79a63          	bne	a5,a4,ffffffffc0201f80 <strncmp+0x1c>
ffffffffc0201f70:	00b60b63          	beq	a2,a1,ffffffffc0201f86 <strncmp+0x22>
ffffffffc0201f74:	00054783          	lbu	a5,0(a0)
ffffffffc0201f78:	0585                	addi	a1,a1,1
ffffffffc0201f7a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201f7e:	f7f5                	bnez	a5,ffffffffc0201f6a <strncmp+0x6>
ffffffffc0201f80:	40e7853b          	subw	a0,a5,a4
ffffffffc0201f84:	8082                	ret
ffffffffc0201f86:	4501                	li	a0,0
ffffffffc0201f88:	8082                	ret

ffffffffc0201f8a <memset>:
ffffffffc0201f8a:	ca01                	beqz	a2,ffffffffc0201f9a <memset+0x10>
ffffffffc0201f8c:	962a                	add	a2,a2,a0
ffffffffc0201f8e:	87aa                	mv	a5,a0
ffffffffc0201f90:	0785                	addi	a5,a5,1
ffffffffc0201f92:	feb78fa3          	sb	a1,-1(a5)
ffffffffc0201f96:	fec79de3          	bne	a5,a2,ffffffffc0201f90 <memset+0x6>
ffffffffc0201f9a:	8082                	ret
