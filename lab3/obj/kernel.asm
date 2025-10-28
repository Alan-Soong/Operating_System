
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
ffffffffc0200034:	18029073          	csrw	satp,t0
ffffffffc0200038:	12000073          	sfence.vma
ffffffffc020003c:	c0205137          	lui	sp,0xc0205
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
ffffffffc0200044:	00030313          	mv	t1,t1
ffffffffc0200048:	811a                	mv	sp,t1
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
ffffffffc020006a:	e406                	sd	ra,8(sp)
ffffffffc020006c:	65f010ef          	jal	ffffffffc0201eca <memset>
ffffffffc0200070:	40e000ef          	jal	ffffffffc020047e <dtb_init>
ffffffffc0200074:	3fc000ef          	jal	ffffffffc0200470 <cons_init>
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e6850513          	addi	a0,a0,-408 # ffffffffc0201ee0 <etext+0x4>
ffffffffc0200080:	090000ef          	jal	ffffffffc0200110 <cputs>
ffffffffc0200084:	0dc000ef          	jal	ffffffffc0200160 <print_kerninfo>
ffffffffc0200088:	7b2000ef          	jal	ffffffffc020083a <idt_init>
ffffffffc020008c:	6c2010ef          	jal	ffffffffc020174e <pmm_init>
ffffffffc0200090:	7aa000ef          	jal	ffffffffc020083a <idt_init>
ffffffffc0200094:	39a000ef          	jal	ffffffffc020042e <clock_init>
ffffffffc0200098:	796000ef          	jal	ffffffffc020082e <intr_enable>
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
ffffffffc02000a6:	3cc000ef          	jal	ffffffffc0200472 <cons_putc>
ffffffffc02000aa:	401c                	lw	a5,0(s0)
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
ffffffffc02000ca:	c602                	sw	zero,12(sp)
ffffffffc02000cc:	0cf010ef          	jal	ffffffffc020199a <vprintfmt>
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
ffffffffc02000d8:	711d                	addi	sp,sp,-96
ffffffffc02000da:	02810313          	addi	t1,sp,40
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
ffffffffc0200100:	c202                	sw	zero,4(sp)
ffffffffc0200102:	099010ef          	jal	ffffffffc020199a <vprintfmt>
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:
ffffffffc020010e:	a695                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200110 <cputs>:
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
ffffffffc0200126:	34c000ef          	jal	ffffffffc0200472 <cons_putc>
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	336000ef          	jal	ffffffffc0200472 <cons_putc>
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
ffffffffc0200154:	326000ef          	jal	ffffffffc020047a <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <print_kerninfo>:
ffffffffc0200160:	1141                	addi	sp,sp,-16
ffffffffc0200162:	00002517          	auipc	a0,0x2
ffffffffc0200166:	d9e50513          	addi	a0,a0,-610 # ffffffffc0201f00 <etext+0x24>
ffffffffc020016a:	e406                	sd	ra,8(sp)
ffffffffc020016c:	f6dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200170:	00000597          	auipc	a1,0x0
ffffffffc0200174:	ee458593          	addi	a1,a1,-284 # ffffffffc0200054 <kern_init>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	da850513          	addi	a0,a0,-600 # ffffffffc0201f20 <etext+0x44>
ffffffffc0200180:	f59ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200184:	00002597          	auipc	a1,0x2
ffffffffc0200188:	d5858593          	addi	a1,a1,-680 # ffffffffc0201edc <etext>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	db450513          	addi	a0,a0,-588 # ffffffffc0201f40 <etext+0x64>
ffffffffc0200194:	f45ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	e9058593          	addi	a1,a1,-368 # ffffffffc0206028 <free_area>
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	dc050513          	addi	a0,a0,-576 # ffffffffc0201f60 <etext+0x84>
ffffffffc02001a8:	f31ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02001ac:	00006597          	auipc	a1,0x6
ffffffffc02001b0:	2f458593          	addi	a1,a1,756 # ffffffffc02064a0 <end>
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	dcc50513          	addi	a0,a0,-564 # ffffffffc0201f80 <etext+0xa4>
ffffffffc02001bc:	f1dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02001c0:	00006597          	auipc	a1,0x6
ffffffffc02001c4:	6df58593          	addi	a1,a1,1759 # ffffffffc020689f <end+0x3ff>
ffffffffc02001c8:	00000797          	auipc	a5,0x0
ffffffffc02001cc:	e8c78793          	addi	a5,a5,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	40f587b3          	sub	a5,a1,a5
ffffffffc02001d4:	43f7d593          	srai	a1,a5,0x3f
ffffffffc02001d8:	60a2                	ld	ra,8(sp)
ffffffffc02001da:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001de:	95be                	add	a1,a1,a5
ffffffffc02001e0:	85a9                	srai	a1,a1,0xa
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	dbe50513          	addi	a0,a0,-578 # ffffffffc0201fa0 <etext+0xc4>
ffffffffc02001ea:	0141                	addi	sp,sp,16
ffffffffc02001ec:	b5f5                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001ee <print_stackframe>:
ffffffffc02001ee:	1141                	addi	sp,sp,-16
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	de060613          	addi	a2,a2,-544 # ffffffffc0201fd0 <etext+0xf4>
ffffffffc02001f8:	04d00593          	li	a1,77
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	dec50513          	addi	a0,a0,-532 # ffffffffc0201fe8 <etext+0x10c>
ffffffffc0200204:	e406                	sd	ra,8(sp)
ffffffffc0200206:	1cc000ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc020020a <mon_help>:
ffffffffc020020a:	1141                	addi	sp,sp,-16
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	df460613          	addi	a2,a2,-524 # ffffffffc0202000 <etext+0x124>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	e0c58593          	addi	a1,a1,-500 # ffffffffc0202020 <etext+0x144>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	e0c50513          	addi	a0,a0,-500 # ffffffffc0202028 <etext+0x14c>
ffffffffc0200224:	e406                	sd	ra,8(sp)
ffffffffc0200226:	eb3ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	e0e60613          	addi	a2,a2,-498 # ffffffffc0202038 <etext+0x15c>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	e2e58593          	addi	a1,a1,-466 # ffffffffc0202060 <etext+0x184>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	dee50513          	addi	a0,a0,-530 # ffffffffc0202028 <etext+0x14c>
ffffffffc0200242:	e97ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	e2a60613          	addi	a2,a2,-470 # ffffffffc0202070 <etext+0x194>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	e4258593          	addi	a1,a1,-446 # ffffffffc0202090 <etext+0x1b4>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	dd250513          	addi	a0,a0,-558 # ffffffffc0202028 <etext+0x14c>
ffffffffc020025e:	e7bff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <mon_kerninfo>:
ffffffffc020026a:	1141                	addi	sp,sp,-16
ffffffffc020026c:	e406                	sd	ra,8(sp)
ffffffffc020026e:	ef3ff0ef          	jal	ffffffffc0200160 <print_kerninfo>
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_backtrace>:
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
ffffffffc020027e:	f71ff0ef          	jal	ffffffffc02001ee <print_stackframe>
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <kmonitor>:
ffffffffc020028a:	7115                	addi	sp,sp,-224
ffffffffc020028c:	ed5e                	sd	s7,152(sp)
ffffffffc020028e:	8baa                	mv	s7,a0
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	e1050513          	addi	a0,a0,-496 # ffffffffc02020a0 <etext+0x1c4>
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
ffffffffc02002ae:	e2bff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	e1650513          	addi	a0,a0,-490 # ffffffffc02020c8 <etext+0x1ec>
ffffffffc02002ba:	e1fff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02002be:	000b8563          	beqz	s7,ffffffffc02002c8 <kmonitor+0x3e>
ffffffffc02002c2:	855e                	mv	a0,s7
ffffffffc02002c4:	756000ef          	jal	ffffffffc0200a1a <print_trapframe>
ffffffffc02002c8:	00003c17          	auipc	s8,0x3
ffffffffc02002cc:	a40c0c13          	addi	s8,s8,-1472 # ffffffffc0202d08 <commands>
ffffffffc02002d0:	00002917          	auipc	s2,0x2
ffffffffc02002d4:	e2090913          	addi	s2,s2,-480 # ffffffffc02020f0 <etext+0x214>
ffffffffc02002d8:	00002497          	auipc	s1,0x2
ffffffffc02002dc:	e2048493          	addi	s1,s1,-480 # ffffffffc02020f8 <etext+0x21c>
ffffffffc02002e0:	49bd                	li	s3,15
ffffffffc02002e2:	00002b17          	auipc	s6,0x2
ffffffffc02002e6:	e1eb0b13          	addi	s6,s6,-482 # ffffffffc0202100 <etext+0x224>
ffffffffc02002ea:	00002a17          	auipc	s4,0x2
ffffffffc02002ee:	d36a0a13          	addi	s4,s4,-714 # ffffffffc0202020 <etext+0x144>
ffffffffc02002f2:	4a8d                	li	s5,3
ffffffffc02002f4:	854a                	mv	a0,s2
ffffffffc02002f6:	227010ef          	jal	ffffffffc0201d1c <readline>
ffffffffc02002fa:	842a                	mv	s0,a0
ffffffffc02002fc:	dd65                	beqz	a0,ffffffffc02002f4 <kmonitor+0x6a>
ffffffffc02002fe:	00054583          	lbu	a1,0(a0)
ffffffffc0200302:	4c81                	li	s9,0
ffffffffc0200304:	e1bd                	bnez	a1,ffffffffc020036a <kmonitor+0xe0>
ffffffffc0200306:	fe0c87e3          	beqz	s9,ffffffffc02002f4 <kmonitor+0x6a>
ffffffffc020030a:	6582                	ld	a1,0(sp)
ffffffffc020030c:	00003d17          	auipc	s10,0x3
ffffffffc0200310:	9fcd0d13          	addi	s10,s10,-1540 # ffffffffc0202d08 <commands>
ffffffffc0200314:	8552                	mv	a0,s4
ffffffffc0200316:	4401                	li	s0,0
ffffffffc0200318:	0d61                	addi	s10,s10,24
ffffffffc020031a:	357010ef          	jal	ffffffffc0201e70 <strcmp>
ffffffffc020031e:	c919                	beqz	a0,ffffffffc0200334 <kmonitor+0xaa>
ffffffffc0200320:	2405                	addiw	s0,s0,1
ffffffffc0200322:	0b540063          	beq	s0,s5,ffffffffc02003c2 <kmonitor+0x138>
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	6582                	ld	a1,0(sp)
ffffffffc020032c:	0d61                	addi	s10,s10,24
ffffffffc020032e:	343010ef          	jal	ffffffffc0201e70 <strcmp>
ffffffffc0200332:	f57d                	bnez	a0,ffffffffc0200320 <kmonitor+0x96>
ffffffffc0200334:	00141793          	slli	a5,s0,0x1
ffffffffc0200338:	97a2                	add	a5,a5,s0
ffffffffc020033a:	078e                	slli	a5,a5,0x3
ffffffffc020033c:	97e2                	add	a5,a5,s8
ffffffffc020033e:	6b9c                	ld	a5,16(a5)
ffffffffc0200340:	865e                	mv	a2,s7
ffffffffc0200342:	002c                	addi	a1,sp,8
ffffffffc0200344:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200348:	9782                	jalr	a5
ffffffffc020034a:	fa0555e3          	bgez	a0,ffffffffc02002f4 <kmonitor+0x6a>
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
ffffffffc020036a:	8526                	mv	a0,s1
ffffffffc020036c:	349010ef          	jal	ffffffffc0201eb4 <strchr>
ffffffffc0200370:	c901                	beqz	a0,ffffffffc0200380 <kmonitor+0xf6>
ffffffffc0200372:	00144583          	lbu	a1,1(s0)
ffffffffc0200376:	00040023          	sb	zero,0(s0)
ffffffffc020037a:	0405                	addi	s0,s0,1
ffffffffc020037c:	d5c9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc020037e:	b7f5                	j	ffffffffc020036a <kmonitor+0xe0>
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	d3c9                	beqz	a5,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc0200386:	033c8963          	beq	s9,s3,ffffffffc02003b8 <kmonitor+0x12e>
ffffffffc020038a:	003c9793          	slli	a5,s9,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
ffffffffc020039a:	2c85                	addiw	s9,s9,1
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11e>
ffffffffc020039e:	b7b5                	j	ffffffffc020030a <kmonitor+0x80>
ffffffffc02003a0:	00144583          	lbu	a1,1(s0)
ffffffffc02003a4:	0405                	addi	s0,s0,1
ffffffffc02003a6:	d1a5                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003a8:	8526                	mv	a0,s1
ffffffffc02003aa:	30b010ef          	jal	ffffffffc0201eb4 <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x116>
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	d9a9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003b6:	bf55                	j	ffffffffc020036a <kmonitor+0xe0>
ffffffffc02003b8:	45c1                	li	a1,16
ffffffffc02003ba:	855a                	mv	a0,s6
ffffffffc02003bc:	d1dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02003c0:	b7e9                	j	ffffffffc020038a <kmonitor+0x100>
ffffffffc02003c2:	6582                	ld	a1,0(sp)
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	d5c50513          	addi	a0,a0,-676 # ffffffffc0202120 <etext+0x244>
ffffffffc02003cc:	d0dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02003d0:	b715                	j	ffffffffc02002f4 <kmonitor+0x6a>

ffffffffc02003d2 <__panic>:
ffffffffc02003d2:	00006317          	auipc	t1,0x6
ffffffffc02003d6:	06e30313          	addi	t1,t1,110 # ffffffffc0206440 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	e822                	sd	s0,16(sp)
ffffffffc02003e4:	f436                	sd	a3,40(sp)
ffffffffc02003e6:	f83a                	sd	a4,48(sp)
ffffffffc02003e8:	fc3e                	sd	a5,56(sp)
ffffffffc02003ea:	e0c2                	sd	a6,64(sp)
ffffffffc02003ec:	e4c6                	sd	a7,72(sp)
ffffffffc02003ee:	020e1a63          	bnez	t3,ffffffffc0200422 <__panic+0x50>
ffffffffc02003f2:	4785                	li	a5,1
ffffffffc02003f4:	00f32023          	sw	a5,0(t1)
ffffffffc02003f8:	8432                	mv	s0,a2
ffffffffc02003fa:	103c                	addi	a5,sp,40
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	d3850513          	addi	a0,a0,-712 # ffffffffc0202138 <etext+0x25c>
ffffffffc0200408:	e43e                	sd	a5,8(sp)
ffffffffc020040a:	ccfff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	ca7ff0ef          	jal	ffffffffc02000b8 <vcprintf>
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	d4250513          	addi	a0,a0,-702 # ffffffffc0202158 <etext+0x27c>
ffffffffc020041e:	cbbff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200422:	412000ef          	jal	ffffffffc0200834 <intr_disable>
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e63ff0ef          	jal	ffffffffc020028a <kmonitor>
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x54>

ffffffffc020042e <clock_init>:
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
ffffffffc020043a:	c0102573          	rdtime	a0
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	1a5010ef          	jal	ffffffffc0201dea <sbi_set_timer>
ffffffffc020044a:	60a2                	ld	ra,8(sp)
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	fe07be23          	sd	zero,-4(a5) # ffffffffc0206448 <ticks>
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	d0c50513          	addi	a0,a0,-756 # ffffffffc0202160 <etext+0x284>
ffffffffc020045c:	0141                	addi	sp,sp,16
ffffffffc020045e:	b9ad                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200460 <clock_set_next_event>:
ffffffffc0200460:	c0102573          	rdtime	a0
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	17f0106f          	j	ffffffffc0201dea <sbi_set_timer>

ffffffffc0200470 <cons_init>:
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:
ffffffffc0200472:	0ff57513          	zext.b	a0,a0
ffffffffc0200476:	15b0106f          	j	ffffffffc0201dd0 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
ffffffffc020047a:	18b0106f          	j	ffffffffc0201e04 <sbi_console_getchar>

ffffffffc020047e <dtb_init>:
ffffffffc020047e:	7119                	addi	sp,sp,-128
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	d0050513          	addi	a0,a0,-768 # ffffffffc0202180 <etext+0x2a4>
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
ffffffffc02004a2:	c37ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02004a6:	00006597          	auipc	a1,0x6
ffffffffc02004aa:	b5a5b583          	ld	a1,-1190(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004ae:	00002517          	auipc	a0,0x2
ffffffffc02004b2:	ce250513          	addi	a0,a0,-798 # ffffffffc0202190 <etext+0x2b4>
ffffffffc02004b6:	c23ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02004ba:	00006417          	auipc	s0,0x6
ffffffffc02004be:	b4e40413          	addi	s0,s0,-1202 # ffffffffc0206008 <boot_dtb>
ffffffffc02004c2:	600c                	ld	a1,0(s0)
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	cdc50513          	addi	a0,a0,-804 # ffffffffc02021a0 <etext+0x2c4>
ffffffffc02004cc:	c0dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02004d0:	00043a03          	ld	s4,0(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	ce450513          	addi	a0,a0,-796 # ffffffffc02021b8 <etext+0x2dc>
ffffffffc02004dc:	120a0463          	beqz	s4,ffffffffc0200604 <dtb_init+0x186>
ffffffffc02004e0:	57f5                	li	a5,-3
ffffffffc02004e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004e4:	00fa0733          	add	a4,s4,a5
ffffffffc02004e8:	431c                	lw	a5,0(a4)
ffffffffc02004ea:	00ff0637          	lui	a2,0xff0
ffffffffc02004ee:	6b41                	lui	s6,0x10
ffffffffc02004f0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004f4:	0187969b          	slliw	a3,a5,0x18
ffffffffc02004f8:	0187d51b          	srliw	a0,a5,0x18
ffffffffc02004fc:	0105959b          	slliw	a1,a1,0x10
ffffffffc0200500:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200504:	8df1                	and	a1,a1,a2
ffffffffc0200506:	8ec9                	or	a3,a3,a0
ffffffffc0200508:	0087979b          	slliw	a5,a5,0x8
ffffffffc020050c:	1b7d                	addi	s6,s6,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc020050e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200512:	8dd5                	or	a1,a1,a3
ffffffffc0200514:	8ddd                	or	a1,a1,a5
ffffffffc0200516:	d00e07b7          	lui	a5,0xd00e0
ffffffffc020051a:	2581                	sext.w	a1,a1
ffffffffc020051c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200520:	10f59163          	bne	a1,a5,ffffffffc0200622 <dtb_init+0x1a4>
ffffffffc0200524:	471c                	lw	a5,8(a4)
ffffffffc0200526:	4754                	lw	a3,12(a4)
ffffffffc0200528:	4c81                	li	s9,0
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200532:	0186941b          	slliw	s0,a3,0x18
ffffffffc0200536:	0186d89b          	srliw	a7,a3,0x18
ffffffffc020053a:	01879a1b          	slliw	s4,a5,0x18
ffffffffc020053e:	0187d81b          	srliw	a6,a5,0x18
ffffffffc0200542:	0105151b          	slliw	a0,a0,0x10
ffffffffc0200546:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020054a:	0105959b          	slliw	a1,a1,0x10
ffffffffc020054e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200552:	8d71                	and	a0,a0,a2
ffffffffc0200554:	01146433          	or	s0,s0,a7
ffffffffc0200558:	0086969b          	slliw	a3,a3,0x8
ffffffffc020055c:	010a6a33          	or	s4,s4,a6
ffffffffc0200560:	8e6d                	and	a2,a2,a1
ffffffffc0200562:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200566:	8c49                	or	s0,s0,a0
ffffffffc0200568:	0166f6b3          	and	a3,a3,s6
ffffffffc020056c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200570:	0167f7b3          	and	a5,a5,s6
ffffffffc0200574:	8c55                	or	s0,s0,a3
ffffffffc0200576:	00fa6a33          	or	s4,s4,a5
ffffffffc020057a:	1402                	slli	s0,s0,0x20
ffffffffc020057c:	1a02                	slli	s4,s4,0x20
ffffffffc020057e:	9001                	srli	s0,s0,0x20
ffffffffc0200580:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200584:	943a                	add	s0,s0,a4
ffffffffc0200586:	9a3a                	add	s4,s4,a4
ffffffffc0200588:	00ff0c37          	lui	s8,0xff0
ffffffffc020058c:	4b8d                	li	s7,3
ffffffffc020058e:	00002917          	auipc	s2,0x2
ffffffffc0200592:	c7a90913          	addi	s2,s2,-902 # ffffffffc0202208 <etext+0x32c>
ffffffffc0200596:	49bd                	li	s3,15
ffffffffc0200598:	4d91                	li	s11,4
ffffffffc020059a:	4d05                	li	s10,1
ffffffffc020059c:	00002497          	auipc	s1,0x2
ffffffffc02005a0:	c6448493          	addi	s1,s1,-924 # ffffffffc0202200 <etext+0x324>
ffffffffc02005a4:	000a2703          	lw	a4,0(s4)
ffffffffc02005a8:	004a0a93          	addi	s5,s4,4
ffffffffc02005ac:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b0:	0187179b          	slliw	a5,a4,0x18
ffffffffc02005b4:	0187561b          	srliw	a2,a4,0x18
ffffffffc02005b8:	0106969b          	slliw	a3,a3,0x10
ffffffffc02005bc:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c0:	8fd1                	or	a5,a5,a2
ffffffffc02005c2:	0186f6b3          	and	a3,a3,s8
ffffffffc02005c6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ca:	8fd5                	or	a5,a5,a3
ffffffffc02005cc:	00eb7733          	and	a4,s6,a4
ffffffffc02005d0:	8fd9                	or	a5,a5,a4
ffffffffc02005d2:	2781                	sext.w	a5,a5
ffffffffc02005d4:	09778c63          	beq	a5,s7,ffffffffc020066c <dtb_init+0x1ee>
ffffffffc02005d8:	00fbea63          	bltu	s7,a5,ffffffffc02005ec <dtb_init+0x16e>
ffffffffc02005dc:	07a78663          	beq	a5,s10,ffffffffc0200648 <dtb_init+0x1ca>
ffffffffc02005e0:	4709                	li	a4,2
ffffffffc02005e2:	00e79763          	bne	a5,a4,ffffffffc02005f0 <dtb_init+0x172>
ffffffffc02005e6:	4c81                	li	s9,0
ffffffffc02005e8:	8a56                	mv	s4,s5
ffffffffc02005ea:	bf6d                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc02005ec:	ffb78ee3          	beq	a5,s11,ffffffffc02005e8 <dtb_init+0x16a>
ffffffffc02005f0:	00002517          	auipc	a0,0x2
ffffffffc02005f4:	c9050513          	addi	a0,a0,-880 # ffffffffc0202280 <etext+0x3a4>
ffffffffc02005f8:	ae1ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	cbc50513          	addi	a0,a0,-836 # ffffffffc02022b8 <etext+0x3dc>
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
ffffffffc0200620:	bc65                	j	ffffffffc02000d8 <cprintf>
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
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	b9c50513          	addi	a0,a0,-1124 # ffffffffc02021d8 <etext+0x2fc>
ffffffffc0200644:	6109                	addi	sp,sp,128
ffffffffc0200646:	bc49                	j	ffffffffc02000d8 <cprintf>
ffffffffc0200648:	8556                	mv	a0,s5
ffffffffc020064a:	7f0010ef          	jal	ffffffffc0201e3a <strlen>
ffffffffc020064e:	8a2a                	mv	s4,a0
ffffffffc0200650:	4619                	li	a2,6
ffffffffc0200652:	85a6                	mv	a1,s1
ffffffffc0200654:	8556                	mv	a0,s5
ffffffffc0200656:	2a01                	sext.w	s4,s4
ffffffffc0200658:	037010ef          	jal	ffffffffc0201e8e <strncmp>
ffffffffc020065c:	e111                	bnez	a0,ffffffffc0200660 <dtb_init+0x1e2>
ffffffffc020065e:	4c85                	li	s9,1
ffffffffc0200660:	0a91                	addi	s5,s5,4
ffffffffc0200662:	9ad2                	add	s5,s5,s4
ffffffffc0200664:	ffcafa93          	andi	s5,s5,-4
ffffffffc0200668:	8a56                	mv	s4,s5
ffffffffc020066a:	bf2d                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc020066c:	004a2783          	lw	a5,4(s4)
ffffffffc0200670:	00ca0693          	addi	a3,s4,12
ffffffffc0200674:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200678:	01879a9b          	slliw	s5,a5,0x18
ffffffffc020067c:	0187d61b          	srliw	a2,a5,0x18
ffffffffc0200680:	0107171b          	slliw	a4,a4,0x10
ffffffffc0200684:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200688:	00caeab3          	or	s5,s5,a2
ffffffffc020068c:	01877733          	and	a4,a4,s8
ffffffffc0200690:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200694:	00eaeab3          	or	s5,s5,a4
ffffffffc0200698:	00fb77b3          	and	a5,s6,a5
ffffffffc020069c:	00faeab3          	or	s5,s5,a5
ffffffffc02006a0:	2a81                	sext.w	s5,s5
ffffffffc02006a2:	000c9c63          	bnez	s9,ffffffffc02006ba <dtb_init+0x23c>
ffffffffc02006a6:	1a82                	slli	s5,s5,0x20
ffffffffc02006a8:	00368793          	addi	a5,a3,3
ffffffffc02006ac:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b0:	9abe                	add	s5,s5,a5
ffffffffc02006b2:	ffcafa93          	andi	s5,s5,-4
ffffffffc02006b6:	8a56                	mv	s4,s5
ffffffffc02006b8:	b5f5                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc02006ba:	008a2783          	lw	a5,8(s4)
ffffffffc02006be:	85ca                	mv	a1,s2
ffffffffc02006c0:	e436                	sd	a3,8(sp)
ffffffffc02006c2:	0087d51b          	srliw	a0,a5,0x8
ffffffffc02006c6:	0187d61b          	srliw	a2,a5,0x18
ffffffffc02006ca:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006ce:	0105151b          	slliw	a0,a0,0x10
ffffffffc02006d2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006d6:	8f51                	or	a4,a4,a2
ffffffffc02006d8:	01857533          	and	a0,a0,s8
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8d59                	or	a0,a0,a4
ffffffffc02006e2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006e6:	8d5d                	or	a0,a0,a5
ffffffffc02006e8:	1502                	slli	a0,a0,0x20
ffffffffc02006ea:	9101                	srli	a0,a0,0x20
ffffffffc02006ec:	9522                	add	a0,a0,s0
ffffffffc02006ee:	782010ef          	jal	ffffffffc0201e70 <strcmp>
ffffffffc02006f2:	66a2                	ld	a3,8(sp)
ffffffffc02006f4:	f94d                	bnez	a0,ffffffffc02006a6 <dtb_init+0x228>
ffffffffc02006f6:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006a6 <dtb_init+0x228>
ffffffffc02006fa:	00ca3783          	ld	a5,12(s4)
ffffffffc02006fe:	014a3703          	ld	a4,20(s4)
ffffffffc0200702:	00002517          	auipc	a0,0x2
ffffffffc0200706:	b0e50513          	addi	a0,a0,-1266 # ffffffffc0202210 <etext+0x334>
ffffffffc020070a:	4207d613          	srai	a2,a5,0x20
ffffffffc020070e:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200712:	42075593          	srai	a1,a4,0x20
ffffffffc0200716:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020071a:	0186581b          	srliw	a6,a2,0x18
ffffffffc020071e:	0187941b          	slliw	s0,a5,0x18
ffffffffc0200722:	0107d89b          	srliw	a7,a5,0x10
ffffffffc0200726:	0187d693          	srli	a3,a5,0x18
ffffffffc020072a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020072e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200732:	0103131b          	slliw	t1,t1,0x10
ffffffffc0200736:	0106561b          	srliw	a2,a2,0x10
ffffffffc020073a:	010f6f33          	or	t5,t5,a6
ffffffffc020073e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200742:	0185df9b          	srliw	t6,a1,0x18
ffffffffc0200746:	01837333          	and	t1,t1,s8
ffffffffc020074a:	01c46433          	or	s0,s0,t3
ffffffffc020074e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200752:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200756:	01871e9b          	slliw	t4,a4,0x18
ffffffffc020075a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020075e:	0086161b          	slliw	a2,a2,0x8
ffffffffc0200762:	8361                	srli	a4,a4,0x18
ffffffffc0200764:	0107979b          	slliw	a5,a5,0x10
ffffffffc0200768:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020076c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200770:	00cb7633          	and	a2,s6,a2
ffffffffc0200774:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200778:	0085959b          	slliw	a1,a1,0x8
ffffffffc020077c:	00646433          	or	s0,s0,t1
ffffffffc0200780:	0187f7b3          	and	a5,a5,s8
ffffffffc0200784:	01fe6333          	or	t1,t3,t6
ffffffffc0200788:	01877c33          	and	s8,a4,s8
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
ffffffffc02007b6:	1702                	slli	a4,a4,0x20
ffffffffc02007b8:	1b02                	slli	s6,s6,0x20
ffffffffc02007ba:	1782                	slli	a5,a5,0x20
ffffffffc02007bc:	9301                	srli	a4,a4,0x20
ffffffffc02007be:	1402                	slli	s0,s0,0x20
ffffffffc02007c0:	020b5b13          	srli	s6,s6,0x20
ffffffffc02007c4:	0167eb33          	or	s6,a5,s6
ffffffffc02007c8:	8c59                	or	s0,s0,a4
ffffffffc02007ca:	90fff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02007ce:	85a2                	mv	a1,s0
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	a6050513          	addi	a0,a0,-1440 # ffffffffc0202230 <etext+0x354>
ffffffffc02007d8:	901ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02007dc:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e0:	85da                	mv	a1,s6
ffffffffc02007e2:	00002517          	auipc	a0,0x2
ffffffffc02007e6:	a6650513          	addi	a0,a0,-1434 # ffffffffc0202248 <etext+0x36c>
ffffffffc02007ea:	8efff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02007ee:	008b05b3          	add	a1,s6,s0
ffffffffc02007f2:	15fd                	addi	a1,a1,-1
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	a7450513          	addi	a0,a0,-1420 # ffffffffc0202268 <etext+0x38c>
ffffffffc02007fc:	8ddff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	ab850513          	addi	a0,a0,-1352 # ffffffffc02022b8 <etext+0x3dc>
ffffffffc0200808:	00006797          	auipc	a5,0x6
ffffffffc020080c:	c487b423          	sd	s0,-952(a5) # ffffffffc0206450 <memory_base>
ffffffffc0200810:	00006797          	auipc	a5,0x6
ffffffffc0200814:	c567b423          	sd	s6,-952(a5) # ffffffffc0206458 <memory_size>
ffffffffc0200818:	b3f5                	j	ffffffffc0200604 <dtb_init+0x186>

ffffffffc020081a <get_memory_base>:
ffffffffc020081a:	00006517          	auipc	a0,0x6
ffffffffc020081e:	c3653503          	ld	a0,-970(a0) # ffffffffc0206450 <memory_base>
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <get_memory_size>:
ffffffffc0200824:	00006517          	auipc	a0,0x6
ffffffffc0200828:	c3453503          	ld	a0,-972(a0) # ffffffffc0206458 <memory_size>
ffffffffc020082c:	8082                	ret

ffffffffc020082e <intr_enable>:
ffffffffc020082e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <intr_disable>:
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
ffffffffc0200842:	39678793          	addi	a5,a5,918 # ffffffffc0200bd4 <__alltraps>
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
ffffffffc0200858:	a7c50513          	addi	a0,a0,-1412 # ffffffffc02022d0 <etext+0x3f4>
void print_regs(struct pushregs *gpr) {
ffffffffc020085c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085e:	87bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200862:	640c                	ld	a1,8(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	a8450513          	addi	a0,a0,-1404 # ffffffffc02022e8 <etext+0x40c>
ffffffffc020086c:	86dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200870:	680c                	ld	a1,16(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0202300 <etext+0x424>
ffffffffc020087a:	85fff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020087e:	6c0c                	ld	a1,24(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	a9850513          	addi	a0,a0,-1384 # ffffffffc0202318 <etext+0x43c>
ffffffffc0200888:	851ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088c:	700c                	ld	a1,32(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	aa250513          	addi	a0,a0,-1374 # ffffffffc0202330 <etext+0x454>
ffffffffc0200896:	843ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089a:	740c                	ld	a1,40(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	aac50513          	addi	a0,a0,-1364 # ffffffffc0202348 <etext+0x46c>
ffffffffc02008a4:	835ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008a8:	780c                	ld	a1,48(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	ab650513          	addi	a0,a0,-1354 # ffffffffc0202360 <etext+0x484>
ffffffffc02008b2:	827ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b6:	7c0c                	ld	a1,56(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	ac050513          	addi	a0,a0,-1344 # ffffffffc0202378 <etext+0x49c>
ffffffffc02008c0:	819ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c4:	602c                	ld	a1,64(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	aca50513          	addi	a0,a0,-1334 # ffffffffc0202390 <etext+0x4b4>
ffffffffc02008ce:	80bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d2:	642c                	ld	a1,72(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	ad450513          	addi	a0,a0,-1324 # ffffffffc02023a8 <etext+0x4cc>
ffffffffc02008dc:	ffcff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e0:	682c                	ld	a1,80(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	ade50513          	addi	a0,a0,-1314 # ffffffffc02023c0 <etext+0x4e4>
ffffffffc02008ea:	feeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008ee:	6c2c                	ld	a1,88(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	ae850513          	addi	a0,a0,-1304 # ffffffffc02023d8 <etext+0x4fc>
ffffffffc02008f8:	fe0ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fc:	702c                	ld	a1,96(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	af250513          	addi	a0,a0,-1294 # ffffffffc02023f0 <etext+0x514>
ffffffffc0200906:	fd2ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090a:	742c                	ld	a1,104(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	afc50513          	addi	a0,a0,-1284 # ffffffffc0202408 <etext+0x52c>
ffffffffc0200914:	fc4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200918:	782c                	ld	a1,112(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	b0650513          	addi	a0,a0,-1274 # ffffffffc0202420 <etext+0x544>
ffffffffc0200922:	fb6ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200926:	7c2c                	ld	a1,120(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0202438 <etext+0x55c>
ffffffffc0200930:	fa8ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200934:	604c                	ld	a1,128(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0202450 <etext+0x574>
ffffffffc020093e:	f9aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200942:	644c                	ld	a1,136(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202468 <etext+0x58c>
ffffffffc020094c:	f8cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200950:	684c                	ld	a1,144(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0202480 <etext+0x5a4>
ffffffffc020095a:	f7eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020095e:	6c4c                	ld	a1,152(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	b3850513          	addi	a0,a0,-1224 # ffffffffc0202498 <etext+0x5bc>
ffffffffc0200968:	f70ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096c:	704c                	ld	a1,160(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	b4250513          	addi	a0,a0,-1214 # ffffffffc02024b0 <etext+0x5d4>
ffffffffc0200976:	f62ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097a:	744c                	ld	a1,168(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	b4c50513          	addi	a0,a0,-1204 # ffffffffc02024c8 <etext+0x5ec>
ffffffffc0200984:	f54ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200988:	784c                	ld	a1,176(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	b5650513          	addi	a0,a0,-1194 # ffffffffc02024e0 <etext+0x604>
ffffffffc0200992:	f46ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200996:	7c4c                	ld	a1,184(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	b6050513          	addi	a0,a0,-1184 # ffffffffc02024f8 <etext+0x61c>
ffffffffc02009a0:	f38ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a4:	606c                	ld	a1,192(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0202510 <etext+0x634>
ffffffffc02009ae:	f2aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b2:	646c                	ld	a1,200(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	b7450513          	addi	a0,a0,-1164 # ffffffffc0202528 <etext+0x64c>
ffffffffc02009bc:	f1cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c0:	686c                	ld	a1,208(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0202540 <etext+0x664>
ffffffffc02009ca:	f0eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009ce:	6c6c                	ld	a1,216(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	b8850513          	addi	a0,a0,-1144 # ffffffffc0202558 <etext+0x67c>
ffffffffc02009d8:	f00ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009dc:	706c                	ld	a1,224(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	b9250513          	addi	a0,a0,-1134 # ffffffffc0202570 <etext+0x694>
ffffffffc02009e6:	ef2ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ea:	746c                	ld	a1,232(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0202588 <etext+0x6ac>
ffffffffc02009f4:	ee4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009f8:	786c                	ld	a1,240(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	ba650513          	addi	a0,a0,-1114 # ffffffffc02025a0 <etext+0x6c4>
ffffffffc0200a02:	ed6ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a06:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a08:	6402                	ld	s0,0(sp)
ffffffffc0200a0a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0c:	00002517          	auipc	a0,0x2
ffffffffc0200a10:	bac50513          	addi	a0,a0,-1108 # ffffffffc02025b8 <etext+0x6dc>
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
ffffffffc0200a26:	bae50513          	addi	a0,a0,-1106 # ffffffffc02025d0 <etext+0x6f4>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2c:	eacff0ef          	jal	ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a30:	8522                	mv	a0,s0
ffffffffc0200a32:	e1bff0ef          	jal	ffffffffc020084c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a36:	10043583          	ld	a1,256(s0)
ffffffffc0200a3a:	00002517          	auipc	a0,0x2
ffffffffc0200a3e:	bae50513          	addi	a0,a0,-1106 # ffffffffc02025e8 <etext+0x70c>
ffffffffc0200a42:	e96ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a46:	10843583          	ld	a1,264(s0)
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	bb650513          	addi	a0,a0,-1098 # ffffffffc0202600 <etext+0x724>
ffffffffc0200a52:	e86ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a56:	11043583          	ld	a1,272(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202618 <etext+0x73c>
ffffffffc0200a62:	e76ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a66:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6a:	6402                	ld	s0,0(sp)
ffffffffc0200a6c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6e:	00002517          	auipc	a0,0x2
ffffffffc0200a72:	bc250513          	addi	a0,a0,-1086 # ffffffffc0202630 <etext+0x754>
}
ffffffffc0200a76:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7c <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc0200a7c:	11853783          	ld	a5,280(a0)
ffffffffc0200a80:	472d                	li	a4,11
ffffffffc0200a82:	0786                	slli	a5,a5,0x1
ffffffffc0200a84:	8385                	srli	a5,a5,0x1
ffffffffc0200a86:	08f76263          	bltu	a4,a5,ffffffffc0200b0a <interrupt_handler+0x8e>
ffffffffc0200a8a:	00002717          	auipc	a4,0x2
ffffffffc0200a8e:	2c670713          	addi	a4,a4,710 # ffffffffc0202d50 <commands+0x48>
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
ffffffffc0200aa0:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02026a8 <etext+0x7cc>
ffffffffc0200aa4:	e34ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	be050513          	addi	a0,a0,-1056 # ffffffffc0202688 <etext+0x7ac>
ffffffffc0200ab0:	e28ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab4:	00002517          	auipc	a0,0x2
ffffffffc0200ab8:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202648 <etext+0x76c>
ffffffffc0200abc:	e1cff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	c0850513          	addi	a0,a0,-1016 # ffffffffc02026c8 <etext+0x7ec>
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
ffffffffc0200ad0:	991ff0ef          	jal	ffffffffc0200460 <clock_set_next_event>
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
ffffffffc0200af6:	bfe50513          	addi	a0,a0,-1026 # ffffffffc02026f0 <etext+0x814>
ffffffffc0200afa:	ddeff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200afe:	00002517          	auipc	a0,0x2
ffffffffc0200b02:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0202668 <etext+0x78c>
ffffffffc0200b06:	dd2ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b0a:	bf01                	j	ffffffffc0200a1a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b0c:	06400593          	li	a1,100
ffffffffc0200b10:	00002517          	auipc	a0,0x2
ffffffffc0200b14:	bd050513          	addi	a0,a0,-1072 # ffffffffc02026e0 <etext+0x804>
ffffffffc0200b18:	dc0ff0ef          	jal	ffffffffc02000d8 <cprintf>
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
ffffffffc0200b36:	2ea0106f          	j	ffffffffc0201e20 <sbi_shutdown>

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
ffffffffc0200b48:	04e78763          	beq	a5,a4,ffffffffc0200b96 <exception_handler+0x5c>
ffffffffc0200b4c:	02f76d63          	bltu	a4,a5,ffffffffc0200b86 <exception_handler+0x4c>
ffffffffc0200b50:	4709                	li	a4,2
ffffffffc0200b52:	02e79663          	bne	a5,a4,ffffffffc0200b7e <exception_handler+0x44>
        case CAUSE_FAULT_FETCH:
            break;
case CAUSE_ILLEGAL_INSTRUCTION:
            // 非法指令异常处理
            // LAB3 CHALLENGE3   YOUR CODE : 
            cprintf("Illegal instruction caught at 0x%08x, epc = 0x%lx\n", tf->epc, tf->epc); // (1)
ffffffffc0200b56:	10843603          	ld	a2,264(s0)
ffffffffc0200b5a:	00002517          	auipc	a0,0x2
ffffffffc0200b5e:	bb650513          	addi	a0,a0,-1098 # ffffffffc0202710 <etext+0x834>
ffffffffc0200b62:	85b2                	mv	a1,a2
ffffffffc0200b64:	d74ff0ef          	jal	ffffffffc02000d8 <cprintf>
            cprintf("Exception type:Illegal instruction\n"); // (2)
ffffffffc0200b68:	00002517          	auipc	a0,0x2
ffffffffc0200b6c:	be050513          	addi	a0,a0,-1056 # ffffffffc0202748 <etext+0x86c>
ffffffffc0200b70:	d68ff0ef          	jal	ffffffffc02000d8 <cprintf>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200b74:	10843783          	ld	a5,264(s0)
ffffffffc0200b78:	0791                	addi	a5,a5,4
ffffffffc0200b7a:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b7e:	60a2                	ld	ra,8(sp)
ffffffffc0200b80:	6402                	ld	s0,0(sp)
ffffffffc0200b82:	0141                	addi	sp,sp,16
ffffffffc0200b84:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b86:	17f1                	addi	a5,a5,-4
ffffffffc0200b88:	471d                	li	a4,7
ffffffffc0200b8a:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b7e <exception_handler+0x44>
}
ffffffffc0200b8e:	6402                	ld	s0,0(sp)
ffffffffc0200b90:	60a2                	ld	ra,8(sp)
ffffffffc0200b92:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b94:	b559                	j	ffffffffc0200a1a <print_trapframe>
            cprintf("Breakpoint caught at 0x%08x, epc = 0x%lx\n", tf->epc, tf->epc); // (1)
ffffffffc0200b96:	10843603          	ld	a2,264(s0)
ffffffffc0200b9a:	00002517          	auipc	a0,0x2
ffffffffc0200b9e:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202770 <etext+0x894>
ffffffffc0200ba2:	85b2                	mv	a1,a2
ffffffffc0200ba4:	d34ff0ef          	jal	ffffffffc02000d8 <cprintf>
            cprintf("Exception type:Breakpoint\n"); // (2)
ffffffffc0200ba8:	00002517          	auipc	a0,0x2
ffffffffc0200bac:	bf850513          	addi	a0,a0,-1032 # ffffffffc02027a0 <etext+0x8c4>
ffffffffc0200bb0:	d28ff0ef          	jal	ffffffffc02000d8 <cprintf>
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200bb4:	10843783          	ld	a5,264(s0)
}
ffffffffc0200bb8:	60a2                	ld	ra,8(sp)
            tf->epc += 4; // (3) 指向下一条指令，防止死循环
ffffffffc0200bba:	0791                	addi	a5,a5,4
ffffffffc0200bbc:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200bc0:	6402                	ld	s0,0(sp)
ffffffffc0200bc2:	0141                	addi	sp,sp,16
ffffffffc0200bc4:	8082                	ret

ffffffffc0200bc6 <trap>:


static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bc6:	11853783          	ld	a5,280(a0)
ffffffffc0200bca:	0007c363          	bltz	a5,ffffffffc0200bd0 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bce:	b7b5                	j	ffffffffc0200b3a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bd0:	b575                	j	ffffffffc0200a7c <interrupt_handler>
	...

ffffffffc0200bd4 <__alltraps>:
ffffffffc0200bd4:	14011073          	csrw	sscratch,sp
ffffffffc0200bd8:	712d                	addi	sp,sp,-288
ffffffffc0200bda:	e002                	sd	zero,0(sp)
ffffffffc0200bdc:	e406                	sd	ra,8(sp)
ffffffffc0200bde:	ec0e                	sd	gp,24(sp)
ffffffffc0200be0:	f012                	sd	tp,32(sp)
ffffffffc0200be2:	f416                	sd	t0,40(sp)
ffffffffc0200be4:	f81a                	sd	t1,48(sp)
ffffffffc0200be6:	fc1e                	sd	t2,56(sp)
ffffffffc0200be8:	e0a2                	sd	s0,64(sp)
ffffffffc0200bea:	e4a6                	sd	s1,72(sp)
ffffffffc0200bec:	e8aa                	sd	a0,80(sp)
ffffffffc0200bee:	ecae                	sd	a1,88(sp)
ffffffffc0200bf0:	f0b2                	sd	a2,96(sp)
ffffffffc0200bf2:	f4b6                	sd	a3,104(sp)
ffffffffc0200bf4:	f8ba                	sd	a4,112(sp)
ffffffffc0200bf6:	fcbe                	sd	a5,120(sp)
ffffffffc0200bf8:	e142                	sd	a6,128(sp)
ffffffffc0200bfa:	e546                	sd	a7,136(sp)
ffffffffc0200bfc:	e94a                	sd	s2,144(sp)
ffffffffc0200bfe:	ed4e                	sd	s3,152(sp)
ffffffffc0200c00:	f152                	sd	s4,160(sp)
ffffffffc0200c02:	f556                	sd	s5,168(sp)
ffffffffc0200c04:	f95a                	sd	s6,176(sp)
ffffffffc0200c06:	fd5e                	sd	s7,184(sp)
ffffffffc0200c08:	e1e2                	sd	s8,192(sp)
ffffffffc0200c0a:	e5e6                	sd	s9,200(sp)
ffffffffc0200c0c:	e9ea                	sd	s10,208(sp)
ffffffffc0200c0e:	edee                	sd	s11,216(sp)
ffffffffc0200c10:	f1f2                	sd	t3,224(sp)
ffffffffc0200c12:	f5f6                	sd	t4,232(sp)
ffffffffc0200c14:	f9fa                	sd	t5,240(sp)
ffffffffc0200c16:	fdfe                	sd	t6,248(sp)
ffffffffc0200c18:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c1c:	100024f3          	csrr	s1,sstatus
ffffffffc0200c20:	14102973          	csrr	s2,sepc
ffffffffc0200c24:	143029f3          	csrr	s3,stval
ffffffffc0200c28:	14202a73          	csrr	s4,scause
ffffffffc0200c2c:	e822                	sd	s0,16(sp)
ffffffffc0200c2e:	e226                	sd	s1,256(sp)
ffffffffc0200c30:	e64a                	sd	s2,264(sp)
ffffffffc0200c32:	ea4e                	sd	s3,272(sp)
ffffffffc0200c34:	ee52                	sd	s4,280(sp)
ffffffffc0200c36:	850a                	mv	a0,sp
ffffffffc0200c38:	f8fff0ef          	jal	ffffffffc0200bc6 <trap>

ffffffffc0200c3c <__trapret>:
ffffffffc0200c3c:	6492                	ld	s1,256(sp)
ffffffffc0200c3e:	6932                	ld	s2,264(sp)
ffffffffc0200c40:	10049073          	csrw	sstatus,s1
ffffffffc0200c44:	14191073          	csrw	sepc,s2
ffffffffc0200c48:	60a2                	ld	ra,8(sp)
ffffffffc0200c4a:	61e2                	ld	gp,24(sp)
ffffffffc0200c4c:	7202                	ld	tp,32(sp)
ffffffffc0200c4e:	72a2                	ld	t0,40(sp)
ffffffffc0200c50:	7342                	ld	t1,48(sp)
ffffffffc0200c52:	73e2                	ld	t2,56(sp)
ffffffffc0200c54:	6406                	ld	s0,64(sp)
ffffffffc0200c56:	64a6                	ld	s1,72(sp)
ffffffffc0200c58:	6546                	ld	a0,80(sp)
ffffffffc0200c5a:	65e6                	ld	a1,88(sp)
ffffffffc0200c5c:	7606                	ld	a2,96(sp)
ffffffffc0200c5e:	76a6                	ld	a3,104(sp)
ffffffffc0200c60:	7746                	ld	a4,112(sp)
ffffffffc0200c62:	77e6                	ld	a5,120(sp)
ffffffffc0200c64:	680a                	ld	a6,128(sp)
ffffffffc0200c66:	68aa                	ld	a7,136(sp)
ffffffffc0200c68:	694a                	ld	s2,144(sp)
ffffffffc0200c6a:	69ea                	ld	s3,152(sp)
ffffffffc0200c6c:	7a0a                	ld	s4,160(sp)
ffffffffc0200c6e:	7aaa                	ld	s5,168(sp)
ffffffffc0200c70:	7b4a                	ld	s6,176(sp)
ffffffffc0200c72:	7bea                	ld	s7,184(sp)
ffffffffc0200c74:	6c0e                	ld	s8,192(sp)
ffffffffc0200c76:	6cae                	ld	s9,200(sp)
ffffffffc0200c78:	6d4e                	ld	s10,208(sp)
ffffffffc0200c7a:	6dee                	ld	s11,216(sp)
ffffffffc0200c7c:	7e0e                	ld	t3,224(sp)
ffffffffc0200c7e:	7eae                	ld	t4,232(sp)
ffffffffc0200c80:	7f4e                	ld	t5,240(sp)
ffffffffc0200c82:	7fee                	ld	t6,248(sp)
ffffffffc0200c84:	6142                	ld	sp,16(sp)
ffffffffc0200c86:	10200073          	sret

ffffffffc0200c8a <best_fit_init>:
ffffffffc0200c8a:	00005797          	auipc	a5,0x5
ffffffffc0200c8e:	39e78793          	addi	a5,a5,926 # ffffffffc0206028 <free_area>
ffffffffc0200c92:	e79c                	sd	a5,8(a5)
ffffffffc0200c94:	e39c                	sd	a5,0(a5)
ffffffffc0200c96:	0007a823          	sw	zero,16(a5)
ffffffffc0200c9a:	8082                	ret

ffffffffc0200c9c <best_fit_nr_free_pages>:
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	39c56503          	lwu	a0,924(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200ca4:	8082                	ret

ffffffffc0200ca6 <best_fit_alloc_pages>:
ffffffffc0200ca6:	c14d                	beqz	a0,ffffffffc0200d48 <best_fit_alloc_pages+0xa2>
ffffffffc0200ca8:	00005617          	auipc	a2,0x5
ffffffffc0200cac:	38060613          	addi	a2,a2,896 # ffffffffc0206028 <free_area>
ffffffffc0200cb0:	01062803          	lw	a6,16(a2)
ffffffffc0200cb4:	86aa                	mv	a3,a0
ffffffffc0200cb6:	02081793          	slli	a5,a6,0x20
ffffffffc0200cba:	9381                	srli	a5,a5,0x20
ffffffffc0200cbc:	08a7e463          	bltu	a5,a0,ffffffffc0200d44 <best_fit_alloc_pages+0x9e>
ffffffffc0200cc0:	661c                	ld	a5,8(a2)
ffffffffc0200cc2:	0018059b          	addiw	a1,a6,1
ffffffffc0200cc6:	1582                	slli	a1,a1,0x20
ffffffffc0200cc8:	9181                	srli	a1,a1,0x20
ffffffffc0200cca:	4501                	li	a0,0
ffffffffc0200ccc:	06c78b63          	beq	a5,a2,ffffffffc0200d42 <best_fit_alloc_pages+0x9c>
ffffffffc0200cd0:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200cd4:	00d76763          	bltu	a4,a3,ffffffffc0200ce2 <best_fit_alloc_pages+0x3c>
ffffffffc0200cd8:	00b77563          	bgeu	a4,a1,ffffffffc0200ce2 <best_fit_alloc_pages+0x3c>
ffffffffc0200cdc:	fe878513          	addi	a0,a5,-24
ffffffffc0200ce0:	85ba                	mv	a1,a4
ffffffffc0200ce2:	679c                	ld	a5,8(a5)
ffffffffc0200ce4:	fec796e3          	bne	a5,a2,ffffffffc0200cd0 <best_fit_alloc_pages+0x2a>
ffffffffc0200ce8:	cd29                	beqz	a0,ffffffffc0200d42 <best_fit_alloc_pages+0x9c>
ffffffffc0200cea:	711c                	ld	a5,32(a0)
ffffffffc0200cec:	6d18                	ld	a4,24(a0)
ffffffffc0200cee:	490c                	lw	a1,16(a0)
ffffffffc0200cf0:	0006889b          	sext.w	a7,a3
ffffffffc0200cf4:	e71c                	sd	a5,8(a4)
ffffffffc0200cf6:	e398                	sd	a4,0(a5)
ffffffffc0200cf8:	02059793          	slli	a5,a1,0x20
ffffffffc0200cfc:	9381                	srli	a5,a5,0x20
ffffffffc0200cfe:	02f6f863          	bgeu	a3,a5,ffffffffc0200d2e <best_fit_alloc_pages+0x88>
ffffffffc0200d02:	00269793          	slli	a5,a3,0x2
ffffffffc0200d06:	97b6                	add	a5,a5,a3
ffffffffc0200d08:	078e                	slli	a5,a5,0x3
ffffffffc0200d0a:	97aa                	add	a5,a5,a0
ffffffffc0200d0c:	411585bb          	subw	a1,a1,a7
ffffffffc0200d10:	cb8c                	sw	a1,16(a5)
ffffffffc0200d12:	4689                	li	a3,2
ffffffffc0200d14:	00878593          	addi	a1,a5,8
ffffffffc0200d18:	40d5b02f          	amoor.d	zero,a3,(a1)
ffffffffc0200d1c:	6714                	ld	a3,8(a4)
ffffffffc0200d1e:	01878593          	addi	a1,a5,24
ffffffffc0200d22:	01062803          	lw	a6,16(a2)
ffffffffc0200d26:	e28c                	sd	a1,0(a3)
ffffffffc0200d28:	e70c                	sd	a1,8(a4)
ffffffffc0200d2a:	f394                	sd	a3,32(a5)
ffffffffc0200d2c:	ef98                	sd	a4,24(a5)
ffffffffc0200d2e:	4118083b          	subw	a6,a6,a7
ffffffffc0200d32:	01062823          	sw	a6,16(a2)
ffffffffc0200d36:	57f5                	li	a5,-3
ffffffffc0200d38:	00850713          	addi	a4,a0,8
ffffffffc0200d3c:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc0200d40:	8082                	ret
ffffffffc0200d42:	8082                	ret
ffffffffc0200d44:	4501                	li	a0,0
ffffffffc0200d46:	8082                	ret
ffffffffc0200d48:	1141                	addi	sp,sp,-16
ffffffffc0200d4a:	00002697          	auipc	a3,0x2
ffffffffc0200d4e:	a7668693          	addi	a3,a3,-1418 # ffffffffc02027c0 <etext+0x8e4>
ffffffffc0200d52:	00002617          	auipc	a2,0x2
ffffffffc0200d56:	a7660613          	addi	a2,a2,-1418 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc0200d5a:	06b00593          	li	a1,107
ffffffffc0200d5e:	00002517          	auipc	a0,0x2
ffffffffc0200d62:	a8250513          	addi	a0,a0,-1406 # ffffffffc02027e0 <etext+0x904>
ffffffffc0200d66:	e406                	sd	ra,8(sp)
ffffffffc0200d68:	e6aff0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc0200d6c <best_fit_check>:
ffffffffc0200d6c:	715d                	addi	sp,sp,-80
ffffffffc0200d6e:	e0a2                	sd	s0,64(sp)
ffffffffc0200d70:	00005417          	auipc	s0,0x5
ffffffffc0200d74:	2b840413          	addi	s0,s0,696 # ffffffffc0206028 <free_area>
ffffffffc0200d78:	641c                	ld	a5,8(s0)
ffffffffc0200d7a:	e486                	sd	ra,72(sp)
ffffffffc0200d7c:	fc26                	sd	s1,56(sp)
ffffffffc0200d7e:	f84a                	sd	s2,48(sp)
ffffffffc0200d80:	f44e                	sd	s3,40(sp)
ffffffffc0200d82:	f052                	sd	s4,32(sp)
ffffffffc0200d84:	ec56                	sd	s5,24(sp)
ffffffffc0200d86:	e85a                	sd	s6,16(sp)
ffffffffc0200d88:	e45e                	sd	s7,8(sp)
ffffffffc0200d8a:	e062                	sd	s8,0(sp)
ffffffffc0200d8c:	26878b63          	beq	a5,s0,ffffffffc0201002 <best_fit_check+0x296>
ffffffffc0200d90:	4481                	li	s1,0
ffffffffc0200d92:	4901                	li	s2,0
ffffffffc0200d94:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200d98:	8b09                	andi	a4,a4,2
ffffffffc0200d9a:	26070863          	beqz	a4,ffffffffc020100a <best_fit_check+0x29e>
ffffffffc0200d9e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200da2:	679c                	ld	a5,8(a5)
ffffffffc0200da4:	2905                	addiw	s2,s2,1
ffffffffc0200da6:	9cb9                	addw	s1,s1,a4
ffffffffc0200da8:	fe8796e3          	bne	a5,s0,ffffffffc0200d94 <best_fit_check+0x28>
ffffffffc0200dac:	89a6                	mv	s3,s1
ffffffffc0200dae:	167000ef          	jal	ffffffffc0201714 <nr_free_pages>
ffffffffc0200db2:	33351c63          	bne	a0,s3,ffffffffc02010ea <best_fit_check+0x37e>
ffffffffc0200db6:	4505                	li	a0,1
ffffffffc0200db8:	0df000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200dbc:	8a2a                	mv	s4,a0
ffffffffc0200dbe:	36050663          	beqz	a0,ffffffffc020112a <best_fit_check+0x3be>
ffffffffc0200dc2:	4505                	li	a0,1
ffffffffc0200dc4:	0d3000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200dc8:	89aa                	mv	s3,a0
ffffffffc0200dca:	34050063          	beqz	a0,ffffffffc020110a <best_fit_check+0x39e>
ffffffffc0200dce:	4505                	li	a0,1
ffffffffc0200dd0:	0c7000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200dd4:	8aaa                	mv	s5,a0
ffffffffc0200dd6:	2c050a63          	beqz	a0,ffffffffc02010aa <best_fit_check+0x33e>
ffffffffc0200dda:	253a0863          	beq	s4,s3,ffffffffc020102a <best_fit_check+0x2be>
ffffffffc0200dde:	24aa0663          	beq	s4,a0,ffffffffc020102a <best_fit_check+0x2be>
ffffffffc0200de2:	24a98463          	beq	s3,a0,ffffffffc020102a <best_fit_check+0x2be>
ffffffffc0200de6:	000a2783          	lw	a5,0(s4)
ffffffffc0200dea:	26079063          	bnez	a5,ffffffffc020104a <best_fit_check+0x2de>
ffffffffc0200dee:	0009a783          	lw	a5,0(s3)
ffffffffc0200df2:	24079c63          	bnez	a5,ffffffffc020104a <best_fit_check+0x2de>
ffffffffc0200df6:	411c                	lw	a5,0(a0)
ffffffffc0200df8:	24079963          	bnez	a5,ffffffffc020104a <best_fit_check+0x2de>
ffffffffc0200dfc:	00005797          	auipc	a5,0x5
ffffffffc0200e00:	6747b783          	ld	a5,1652(a5) # ffffffffc0206470 <pages>
ffffffffc0200e04:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e08:	870d                	srai	a4,a4,0x3
ffffffffc0200e0a:	00002597          	auipc	a1,0x2
ffffffffc0200e0e:	13e5b583          	ld	a1,318(a1) # ffffffffc0202f48 <error_string+0x38>
ffffffffc0200e12:	02b70733          	mul	a4,a4,a1
ffffffffc0200e16:	00002617          	auipc	a2,0x2
ffffffffc0200e1a:	13a63603          	ld	a2,314(a2) # ffffffffc0202f50 <nbase>
ffffffffc0200e1e:	00005697          	auipc	a3,0x5
ffffffffc0200e22:	64a6b683          	ld	a3,1610(a3) # ffffffffc0206468 <npage>
ffffffffc0200e26:	06b2                	slli	a3,a3,0xc
ffffffffc0200e28:	9732                	add	a4,a4,a2
ffffffffc0200e2a:	0732                	slli	a4,a4,0xc
ffffffffc0200e2c:	22d77f63          	bgeu	a4,a3,ffffffffc020106a <best_fit_check+0x2fe>
ffffffffc0200e30:	40f98733          	sub	a4,s3,a5
ffffffffc0200e34:	870d                	srai	a4,a4,0x3
ffffffffc0200e36:	02b70733          	mul	a4,a4,a1
ffffffffc0200e3a:	9732                	add	a4,a4,a2
ffffffffc0200e3c:	0732                	slli	a4,a4,0xc
ffffffffc0200e3e:	3ed77663          	bgeu	a4,a3,ffffffffc020122a <best_fit_check+0x4be>
ffffffffc0200e42:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e46:	878d                	srai	a5,a5,0x3
ffffffffc0200e48:	02b787b3          	mul	a5,a5,a1
ffffffffc0200e4c:	97b2                	add	a5,a5,a2
ffffffffc0200e4e:	07b2                	slli	a5,a5,0xc
ffffffffc0200e50:	3ad7fd63          	bgeu	a5,a3,ffffffffc020120a <best_fit_check+0x49e>
ffffffffc0200e54:	4505                	li	a0,1
ffffffffc0200e56:	00043c03          	ld	s8,0(s0)
ffffffffc0200e5a:	00843b83          	ld	s7,8(s0)
ffffffffc0200e5e:	01042b03          	lw	s6,16(s0)
ffffffffc0200e62:	e400                	sd	s0,8(s0)
ffffffffc0200e64:	e000                	sd	s0,0(s0)
ffffffffc0200e66:	00005797          	auipc	a5,0x5
ffffffffc0200e6a:	1c07a923          	sw	zero,466(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200e6e:	029000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200e72:	36051c63          	bnez	a0,ffffffffc02011ea <best_fit_check+0x47e>
ffffffffc0200e76:	4585                	li	a1,1
ffffffffc0200e78:	8552                	mv	a0,s4
ffffffffc0200e7a:	05b000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200e7e:	4585                	li	a1,1
ffffffffc0200e80:	854e                	mv	a0,s3
ffffffffc0200e82:	053000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200e86:	4585                	li	a1,1
ffffffffc0200e88:	8556                	mv	a0,s5
ffffffffc0200e8a:	04b000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200e8e:	4818                	lw	a4,16(s0)
ffffffffc0200e90:	478d                	li	a5,3
ffffffffc0200e92:	32f71c63          	bne	a4,a5,ffffffffc02011ca <best_fit_check+0x45e>
ffffffffc0200e96:	4505                	li	a0,1
ffffffffc0200e98:	7fe000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200e9c:	89aa                	mv	s3,a0
ffffffffc0200e9e:	30050663          	beqz	a0,ffffffffc02011aa <best_fit_check+0x43e>
ffffffffc0200ea2:	4505                	li	a0,1
ffffffffc0200ea4:	7f2000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200ea8:	8aaa                	mv	s5,a0
ffffffffc0200eaa:	2e050063          	beqz	a0,ffffffffc020118a <best_fit_check+0x41e>
ffffffffc0200eae:	4505                	li	a0,1
ffffffffc0200eb0:	7e6000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200eb4:	8a2a                	mv	s4,a0
ffffffffc0200eb6:	2a050a63          	beqz	a0,ffffffffc020116a <best_fit_check+0x3fe>
ffffffffc0200eba:	4505                	li	a0,1
ffffffffc0200ebc:	7da000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200ec0:	28051563          	bnez	a0,ffffffffc020114a <best_fit_check+0x3de>
ffffffffc0200ec4:	4585                	li	a1,1
ffffffffc0200ec6:	854e                	mv	a0,s3
ffffffffc0200ec8:	00d000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200ecc:	641c                	ld	a5,8(s0)
ffffffffc0200ece:	1a878e63          	beq	a5,s0,ffffffffc020108a <best_fit_check+0x31e>
ffffffffc0200ed2:	4505                	li	a0,1
ffffffffc0200ed4:	7c2000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200ed8:	52a99963          	bne	s3,a0,ffffffffc020140a <best_fit_check+0x69e>
ffffffffc0200edc:	4505                	li	a0,1
ffffffffc0200ede:	7b8000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200ee2:	50051463          	bnez	a0,ffffffffc02013ea <best_fit_check+0x67e>
ffffffffc0200ee6:	481c                	lw	a5,16(s0)
ffffffffc0200ee8:	4e079163          	bnez	a5,ffffffffc02013ca <best_fit_check+0x65e>
ffffffffc0200eec:	854e                	mv	a0,s3
ffffffffc0200eee:	4585                	li	a1,1
ffffffffc0200ef0:	01843023          	sd	s8,0(s0)
ffffffffc0200ef4:	01743423          	sd	s7,8(s0)
ffffffffc0200ef8:	01642823          	sw	s6,16(s0)
ffffffffc0200efc:	7d8000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200f00:	4585                	li	a1,1
ffffffffc0200f02:	8556                	mv	a0,s5
ffffffffc0200f04:	7d0000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200f08:	4585                	li	a1,1
ffffffffc0200f0a:	8552                	mv	a0,s4
ffffffffc0200f0c:	7c8000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200f10:	4515                	li	a0,5
ffffffffc0200f12:	784000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200f16:	89aa                	mv	s3,a0
ffffffffc0200f18:	48050963          	beqz	a0,ffffffffc02013aa <best_fit_check+0x63e>
ffffffffc0200f1c:	651c                	ld	a5,8(a0)
ffffffffc0200f1e:	8385                	srli	a5,a5,0x1
ffffffffc0200f20:	8b85                	andi	a5,a5,1
ffffffffc0200f22:	46079463          	bnez	a5,ffffffffc020138a <best_fit_check+0x61e>
ffffffffc0200f26:	4505                	li	a0,1
ffffffffc0200f28:	00043a83          	ld	s5,0(s0)
ffffffffc0200f2c:	00843a03          	ld	s4,8(s0)
ffffffffc0200f30:	e000                	sd	s0,0(s0)
ffffffffc0200f32:	e400                	sd	s0,8(s0)
ffffffffc0200f34:	762000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200f38:	42051963          	bnez	a0,ffffffffc020136a <best_fit_check+0x5fe>
ffffffffc0200f3c:	4589                	li	a1,2
ffffffffc0200f3e:	02898513          	addi	a0,s3,40
ffffffffc0200f42:	01042b03          	lw	s6,16(s0)
ffffffffc0200f46:	0a098c13          	addi	s8,s3,160
ffffffffc0200f4a:	00005797          	auipc	a5,0x5
ffffffffc0200f4e:	0e07a723          	sw	zero,238(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200f52:	782000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200f56:	8562                	mv	a0,s8
ffffffffc0200f58:	4585                	li	a1,1
ffffffffc0200f5a:	77a000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200f5e:	4511                	li	a0,4
ffffffffc0200f60:	736000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200f64:	3e051363          	bnez	a0,ffffffffc020134a <best_fit_check+0x5de>
ffffffffc0200f68:	0309b783          	ld	a5,48(s3)
ffffffffc0200f6c:	8385                	srli	a5,a5,0x1
ffffffffc0200f6e:	8b85                	andi	a5,a5,1
ffffffffc0200f70:	3a078d63          	beqz	a5,ffffffffc020132a <best_fit_check+0x5be>
ffffffffc0200f74:	0389a703          	lw	a4,56(s3)
ffffffffc0200f78:	4789                	li	a5,2
ffffffffc0200f7a:	3af71863          	bne	a4,a5,ffffffffc020132a <best_fit_check+0x5be>
ffffffffc0200f7e:	4505                	li	a0,1
ffffffffc0200f80:	716000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200f84:	8baa                	mv	s7,a0
ffffffffc0200f86:	38050263          	beqz	a0,ffffffffc020130a <best_fit_check+0x59e>
ffffffffc0200f8a:	4509                	li	a0,2
ffffffffc0200f8c:	70a000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200f90:	34050d63          	beqz	a0,ffffffffc02012ea <best_fit_check+0x57e>
ffffffffc0200f94:	337c1b63          	bne	s8,s7,ffffffffc02012ca <best_fit_check+0x55e>
ffffffffc0200f98:	854e                	mv	a0,s3
ffffffffc0200f9a:	4595                	li	a1,5
ffffffffc0200f9c:	738000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200fa0:	4515                	li	a0,5
ffffffffc0200fa2:	6f4000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200fa6:	89aa                	mv	s3,a0
ffffffffc0200fa8:	30050163          	beqz	a0,ffffffffc02012aa <best_fit_check+0x53e>
ffffffffc0200fac:	4505                	li	a0,1
ffffffffc0200fae:	6e8000ef          	jal	ffffffffc0201696 <alloc_pages>
ffffffffc0200fb2:	2c051c63          	bnez	a0,ffffffffc020128a <best_fit_check+0x51e>
ffffffffc0200fb6:	481c                	lw	a5,16(s0)
ffffffffc0200fb8:	2a079963          	bnez	a5,ffffffffc020126a <best_fit_check+0x4fe>
ffffffffc0200fbc:	4595                	li	a1,5
ffffffffc0200fbe:	854e                	mv	a0,s3
ffffffffc0200fc0:	01642823          	sw	s6,16(s0)
ffffffffc0200fc4:	01543023          	sd	s5,0(s0)
ffffffffc0200fc8:	01443423          	sd	s4,8(s0)
ffffffffc0200fcc:	708000ef          	jal	ffffffffc02016d4 <free_pages>
ffffffffc0200fd0:	641c                	ld	a5,8(s0)
ffffffffc0200fd2:	00878963          	beq	a5,s0,ffffffffc0200fe4 <best_fit_check+0x278>
ffffffffc0200fd6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fda:	679c                	ld	a5,8(a5)
ffffffffc0200fdc:	397d                	addiw	s2,s2,-1
ffffffffc0200fde:	9c99                	subw	s1,s1,a4
ffffffffc0200fe0:	fe879be3          	bne	a5,s0,ffffffffc0200fd6 <best_fit_check+0x26a>
ffffffffc0200fe4:	26091363          	bnez	s2,ffffffffc020124a <best_fit_check+0x4de>
ffffffffc0200fe8:	e0ed                	bnez	s1,ffffffffc02010ca <best_fit_check+0x35e>
ffffffffc0200fea:	60a6                	ld	ra,72(sp)
ffffffffc0200fec:	6406                	ld	s0,64(sp)
ffffffffc0200fee:	74e2                	ld	s1,56(sp)
ffffffffc0200ff0:	7942                	ld	s2,48(sp)
ffffffffc0200ff2:	79a2                	ld	s3,40(sp)
ffffffffc0200ff4:	7a02                	ld	s4,32(sp)
ffffffffc0200ff6:	6ae2                	ld	s5,24(sp)
ffffffffc0200ff8:	6b42                	ld	s6,16(sp)
ffffffffc0200ffa:	6ba2                	ld	s7,8(sp)
ffffffffc0200ffc:	6c02                	ld	s8,0(sp)
ffffffffc0200ffe:	6161                	addi	sp,sp,80
ffffffffc0201000:	8082                	ret
ffffffffc0201002:	4981                	li	s3,0
ffffffffc0201004:	4481                	li	s1,0
ffffffffc0201006:	4901                	li	s2,0
ffffffffc0201008:	b35d                	j	ffffffffc0200dae <best_fit_check+0x42>
ffffffffc020100a:	00001697          	auipc	a3,0x1
ffffffffc020100e:	7ee68693          	addi	a3,a3,2030 # ffffffffc02027f8 <etext+0x91c>
ffffffffc0201012:	00001617          	auipc	a2,0x1
ffffffffc0201016:	7b660613          	addi	a2,a2,1974 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020101a:	10d00593          	li	a1,269
ffffffffc020101e:	00001517          	auipc	a0,0x1
ffffffffc0201022:	7c250513          	addi	a0,a0,1986 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201026:	bacff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020102a:	00002697          	auipc	a3,0x2
ffffffffc020102e:	85e68693          	addi	a3,a3,-1954 # ffffffffc0202888 <etext+0x9ac>
ffffffffc0201032:	00001617          	auipc	a2,0x1
ffffffffc0201036:	79660613          	addi	a2,a2,1942 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020103a:	0d900593          	li	a1,217
ffffffffc020103e:	00001517          	auipc	a0,0x1
ffffffffc0201042:	7a250513          	addi	a0,a0,1954 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201046:	b8cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020104a:	00002697          	auipc	a3,0x2
ffffffffc020104e:	86668693          	addi	a3,a3,-1946 # ffffffffc02028b0 <etext+0x9d4>
ffffffffc0201052:	00001617          	auipc	a2,0x1
ffffffffc0201056:	77660613          	addi	a2,a2,1910 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020105a:	0da00593          	li	a1,218
ffffffffc020105e:	00001517          	auipc	a0,0x1
ffffffffc0201062:	78250513          	addi	a0,a0,1922 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201066:	b6cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020106a:	00002697          	auipc	a3,0x2
ffffffffc020106e:	88668693          	addi	a3,a3,-1914 # ffffffffc02028f0 <etext+0xa14>
ffffffffc0201072:	00001617          	auipc	a2,0x1
ffffffffc0201076:	75660613          	addi	a2,a2,1878 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020107a:	0dc00593          	li	a1,220
ffffffffc020107e:	00001517          	auipc	a0,0x1
ffffffffc0201082:	76250513          	addi	a0,a0,1890 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201086:	b4cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020108a:	00002697          	auipc	a3,0x2
ffffffffc020108e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0202978 <etext+0xa9c>
ffffffffc0201092:	00001617          	auipc	a2,0x1
ffffffffc0201096:	73660613          	addi	a2,a2,1846 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020109a:	0f500593          	li	a1,245
ffffffffc020109e:	00001517          	auipc	a0,0x1
ffffffffc02010a2:	74250513          	addi	a0,a0,1858 # ffffffffc02027e0 <etext+0x904>
ffffffffc02010a6:	b2cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02010aa:	00001697          	auipc	a3,0x1
ffffffffc02010ae:	7be68693          	addi	a3,a3,1982 # ffffffffc0202868 <etext+0x98c>
ffffffffc02010b2:	00001617          	auipc	a2,0x1
ffffffffc02010b6:	71660613          	addi	a2,a2,1814 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02010ba:	0d700593          	li	a1,215
ffffffffc02010be:	00001517          	auipc	a0,0x1
ffffffffc02010c2:	72250513          	addi	a0,a0,1826 # ffffffffc02027e0 <etext+0x904>
ffffffffc02010c6:	b0cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02010ca:	00002697          	auipc	a3,0x2
ffffffffc02010ce:	9de68693          	addi	a3,a3,-1570 # ffffffffc0202aa8 <etext+0xbcc>
ffffffffc02010d2:	00001617          	auipc	a2,0x1
ffffffffc02010d6:	6f660613          	addi	a2,a2,1782 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02010da:	14f00593          	li	a1,335
ffffffffc02010de:	00001517          	auipc	a0,0x1
ffffffffc02010e2:	70250513          	addi	a0,a0,1794 # ffffffffc02027e0 <etext+0x904>
ffffffffc02010e6:	aecff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02010ea:	00001697          	auipc	a3,0x1
ffffffffc02010ee:	71e68693          	addi	a3,a3,1822 # ffffffffc0202808 <etext+0x92c>
ffffffffc02010f2:	00001617          	auipc	a2,0x1
ffffffffc02010f6:	6d660613          	addi	a2,a2,1750 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02010fa:	11000593          	li	a1,272
ffffffffc02010fe:	00001517          	auipc	a0,0x1
ffffffffc0201102:	6e250513          	addi	a0,a0,1762 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201106:	accff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020110a:	00001697          	auipc	a3,0x1
ffffffffc020110e:	73e68693          	addi	a3,a3,1854 # ffffffffc0202848 <etext+0x96c>
ffffffffc0201112:	00001617          	auipc	a2,0x1
ffffffffc0201116:	6b660613          	addi	a2,a2,1718 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020111a:	0d600593          	li	a1,214
ffffffffc020111e:	00001517          	auipc	a0,0x1
ffffffffc0201122:	6c250513          	addi	a0,a0,1730 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201126:	aacff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020112a:	00001697          	auipc	a3,0x1
ffffffffc020112e:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202828 <etext+0x94c>
ffffffffc0201132:	00001617          	auipc	a2,0x1
ffffffffc0201136:	69660613          	addi	a2,a2,1686 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020113a:	0d500593          	li	a1,213
ffffffffc020113e:	00001517          	auipc	a0,0x1
ffffffffc0201142:	6a250513          	addi	a0,a0,1698 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201146:	a8cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020114a:	00002697          	auipc	a3,0x2
ffffffffc020114e:	80668693          	addi	a3,a3,-2042 # ffffffffc0202950 <etext+0xa74>
ffffffffc0201152:	00001617          	auipc	a2,0x1
ffffffffc0201156:	67660613          	addi	a2,a2,1654 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020115a:	0f200593          	li	a1,242
ffffffffc020115e:	00001517          	auipc	a0,0x1
ffffffffc0201162:	68250513          	addi	a0,a0,1666 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201166:	a6cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020116a:	00001697          	auipc	a3,0x1
ffffffffc020116e:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202868 <etext+0x98c>
ffffffffc0201172:	00001617          	auipc	a2,0x1
ffffffffc0201176:	65660613          	addi	a2,a2,1622 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020117a:	0f000593          	li	a1,240
ffffffffc020117e:	00001517          	auipc	a0,0x1
ffffffffc0201182:	66250513          	addi	a0,a0,1634 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201186:	a4cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020118a:	00001697          	auipc	a3,0x1
ffffffffc020118e:	6be68693          	addi	a3,a3,1726 # ffffffffc0202848 <etext+0x96c>
ffffffffc0201192:	00001617          	auipc	a2,0x1
ffffffffc0201196:	63660613          	addi	a2,a2,1590 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020119a:	0ef00593          	li	a1,239
ffffffffc020119e:	00001517          	auipc	a0,0x1
ffffffffc02011a2:	64250513          	addi	a0,a0,1602 # ffffffffc02027e0 <etext+0x904>
ffffffffc02011a6:	a2cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02011aa:	00001697          	auipc	a3,0x1
ffffffffc02011ae:	67e68693          	addi	a3,a3,1662 # ffffffffc0202828 <etext+0x94c>
ffffffffc02011b2:	00001617          	auipc	a2,0x1
ffffffffc02011b6:	61660613          	addi	a2,a2,1558 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02011ba:	0ee00593          	li	a1,238
ffffffffc02011be:	00001517          	auipc	a0,0x1
ffffffffc02011c2:	62250513          	addi	a0,a0,1570 # ffffffffc02027e0 <etext+0x904>
ffffffffc02011c6:	a0cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02011ca:	00001697          	auipc	a3,0x1
ffffffffc02011ce:	79e68693          	addi	a3,a3,1950 # ffffffffc0202968 <etext+0xa8c>
ffffffffc02011d2:	00001617          	auipc	a2,0x1
ffffffffc02011d6:	5f660613          	addi	a2,a2,1526 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02011da:	0ec00593          	li	a1,236
ffffffffc02011de:	00001517          	auipc	a0,0x1
ffffffffc02011e2:	60250513          	addi	a0,a0,1538 # ffffffffc02027e0 <etext+0x904>
ffffffffc02011e6:	9ecff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02011ea:	00001697          	auipc	a3,0x1
ffffffffc02011ee:	76668693          	addi	a3,a3,1894 # ffffffffc0202950 <etext+0xa74>
ffffffffc02011f2:	00001617          	auipc	a2,0x1
ffffffffc02011f6:	5d660613          	addi	a2,a2,1494 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02011fa:	0e700593          	li	a1,231
ffffffffc02011fe:	00001517          	auipc	a0,0x1
ffffffffc0201202:	5e250513          	addi	a0,a0,1506 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201206:	9ccff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020120a:	00001697          	auipc	a3,0x1
ffffffffc020120e:	72668693          	addi	a3,a3,1830 # ffffffffc0202930 <etext+0xa54>
ffffffffc0201212:	00001617          	auipc	a2,0x1
ffffffffc0201216:	5b660613          	addi	a2,a2,1462 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020121a:	0de00593          	li	a1,222
ffffffffc020121e:	00001517          	auipc	a0,0x1
ffffffffc0201222:	5c250513          	addi	a0,a0,1474 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201226:	9acff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020122a:	00001697          	auipc	a3,0x1
ffffffffc020122e:	6e668693          	addi	a3,a3,1766 # ffffffffc0202910 <etext+0xa34>
ffffffffc0201232:	00001617          	auipc	a2,0x1
ffffffffc0201236:	59660613          	addi	a2,a2,1430 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020123a:	0dd00593          	li	a1,221
ffffffffc020123e:	00001517          	auipc	a0,0x1
ffffffffc0201242:	5a250513          	addi	a0,a0,1442 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201246:	98cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020124a:	00002697          	auipc	a3,0x2
ffffffffc020124e:	84e68693          	addi	a3,a3,-1970 # ffffffffc0202a98 <etext+0xbbc>
ffffffffc0201252:	00001617          	auipc	a2,0x1
ffffffffc0201256:	57660613          	addi	a2,a2,1398 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020125a:	14e00593          	li	a1,334
ffffffffc020125e:	00001517          	auipc	a0,0x1
ffffffffc0201262:	58250513          	addi	a0,a0,1410 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201266:	96cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020126a:	00001697          	auipc	a3,0x1
ffffffffc020126e:	74668693          	addi	a3,a3,1862 # ffffffffc02029b0 <etext+0xad4>
ffffffffc0201272:	00001617          	auipc	a2,0x1
ffffffffc0201276:	55660613          	addi	a2,a2,1366 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020127a:	14300593          	li	a1,323
ffffffffc020127e:	00001517          	auipc	a0,0x1
ffffffffc0201282:	56250513          	addi	a0,a0,1378 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201286:	94cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020128a:	00001697          	auipc	a3,0x1
ffffffffc020128e:	6c668693          	addi	a3,a3,1734 # ffffffffc0202950 <etext+0xa74>
ffffffffc0201292:	00001617          	auipc	a2,0x1
ffffffffc0201296:	53660613          	addi	a2,a2,1334 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020129a:	13d00593          	li	a1,317
ffffffffc020129e:	00001517          	auipc	a0,0x1
ffffffffc02012a2:	54250513          	addi	a0,a0,1346 # ffffffffc02027e0 <etext+0x904>
ffffffffc02012a6:	92cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02012aa:	00001697          	auipc	a3,0x1
ffffffffc02012ae:	7ce68693          	addi	a3,a3,1998 # ffffffffc0202a78 <etext+0xb9c>
ffffffffc02012b2:	00001617          	auipc	a2,0x1
ffffffffc02012b6:	51660613          	addi	a2,a2,1302 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02012ba:	13c00593          	li	a1,316
ffffffffc02012be:	00001517          	auipc	a0,0x1
ffffffffc02012c2:	52250513          	addi	a0,a0,1314 # ffffffffc02027e0 <etext+0x904>
ffffffffc02012c6:	90cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02012ca:	00001697          	auipc	a3,0x1
ffffffffc02012ce:	79e68693          	addi	a3,a3,1950 # ffffffffc0202a68 <etext+0xb8c>
ffffffffc02012d2:	00001617          	auipc	a2,0x1
ffffffffc02012d6:	4f660613          	addi	a2,a2,1270 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02012da:	13400593          	li	a1,308
ffffffffc02012de:	00001517          	auipc	a0,0x1
ffffffffc02012e2:	50250513          	addi	a0,a0,1282 # ffffffffc02027e0 <etext+0x904>
ffffffffc02012e6:	8ecff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02012ea:	00001697          	auipc	a3,0x1
ffffffffc02012ee:	76668693          	addi	a3,a3,1894 # ffffffffc0202a50 <etext+0xb74>
ffffffffc02012f2:	00001617          	auipc	a2,0x1
ffffffffc02012f6:	4d660613          	addi	a2,a2,1238 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02012fa:	13300593          	li	a1,307
ffffffffc02012fe:	00001517          	auipc	a0,0x1
ffffffffc0201302:	4e250513          	addi	a0,a0,1250 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201306:	8ccff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020130a:	00001697          	auipc	a3,0x1
ffffffffc020130e:	72668693          	addi	a3,a3,1830 # ffffffffc0202a30 <etext+0xb54>
ffffffffc0201312:	00001617          	auipc	a2,0x1
ffffffffc0201316:	4b660613          	addi	a2,a2,1206 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020131a:	13200593          	li	a1,306
ffffffffc020131e:	00001517          	auipc	a0,0x1
ffffffffc0201322:	4c250513          	addi	a0,a0,1218 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201326:	8acff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020132a:	00001697          	auipc	a3,0x1
ffffffffc020132e:	6d668693          	addi	a3,a3,1750 # ffffffffc0202a00 <etext+0xb24>
ffffffffc0201332:	00001617          	auipc	a2,0x1
ffffffffc0201336:	49660613          	addi	a2,a2,1174 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020133a:	13000593          	li	a1,304
ffffffffc020133e:	00001517          	auipc	a0,0x1
ffffffffc0201342:	4a250513          	addi	a0,a0,1186 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201346:	88cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020134a:	00001697          	auipc	a3,0x1
ffffffffc020134e:	69e68693          	addi	a3,a3,1694 # ffffffffc02029e8 <etext+0xb0c>
ffffffffc0201352:	00001617          	auipc	a2,0x1
ffffffffc0201356:	47660613          	addi	a2,a2,1142 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020135a:	12f00593          	li	a1,303
ffffffffc020135e:	00001517          	auipc	a0,0x1
ffffffffc0201362:	48250513          	addi	a0,a0,1154 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201366:	86cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020136a:	00001697          	auipc	a3,0x1
ffffffffc020136e:	5e668693          	addi	a3,a3,1510 # ffffffffc0202950 <etext+0xa74>
ffffffffc0201372:	00001617          	auipc	a2,0x1
ffffffffc0201376:	45660613          	addi	a2,a2,1110 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020137a:	12300593          	li	a1,291
ffffffffc020137e:	00001517          	auipc	a0,0x1
ffffffffc0201382:	46250513          	addi	a0,a0,1122 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201386:	84cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020138a:	00001697          	auipc	a3,0x1
ffffffffc020138e:	64668693          	addi	a3,a3,1606 # ffffffffc02029d0 <etext+0xaf4>
ffffffffc0201392:	00001617          	auipc	a2,0x1
ffffffffc0201396:	43660613          	addi	a2,a2,1078 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020139a:	11a00593          	li	a1,282
ffffffffc020139e:	00001517          	auipc	a0,0x1
ffffffffc02013a2:	44250513          	addi	a0,a0,1090 # ffffffffc02027e0 <etext+0x904>
ffffffffc02013a6:	82cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02013aa:	00001697          	auipc	a3,0x1
ffffffffc02013ae:	61668693          	addi	a3,a3,1558 # ffffffffc02029c0 <etext+0xae4>
ffffffffc02013b2:	00001617          	auipc	a2,0x1
ffffffffc02013b6:	41660613          	addi	a2,a2,1046 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02013ba:	11900593          	li	a1,281
ffffffffc02013be:	00001517          	auipc	a0,0x1
ffffffffc02013c2:	42250513          	addi	a0,a0,1058 # ffffffffc02027e0 <etext+0x904>
ffffffffc02013c6:	80cff0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02013ca:	00001697          	auipc	a3,0x1
ffffffffc02013ce:	5e668693          	addi	a3,a3,1510 # ffffffffc02029b0 <etext+0xad4>
ffffffffc02013d2:	00001617          	auipc	a2,0x1
ffffffffc02013d6:	3f660613          	addi	a2,a2,1014 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02013da:	0fb00593          	li	a1,251
ffffffffc02013de:	00001517          	auipc	a0,0x1
ffffffffc02013e2:	40250513          	addi	a0,a0,1026 # ffffffffc02027e0 <etext+0x904>
ffffffffc02013e6:	fedfe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02013ea:	00001697          	auipc	a3,0x1
ffffffffc02013ee:	56668693          	addi	a3,a3,1382 # ffffffffc0202950 <etext+0xa74>
ffffffffc02013f2:	00001617          	auipc	a2,0x1
ffffffffc02013f6:	3d660613          	addi	a2,a2,982 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc02013fa:	0f900593          	li	a1,249
ffffffffc02013fe:	00001517          	auipc	a0,0x1
ffffffffc0201402:	3e250513          	addi	a0,a0,994 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201406:	fcdfe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc020140a:	00001697          	auipc	a3,0x1
ffffffffc020140e:	58668693          	addi	a3,a3,1414 # ffffffffc0202990 <etext+0xab4>
ffffffffc0201412:	00001617          	auipc	a2,0x1
ffffffffc0201416:	3b660613          	addi	a2,a2,950 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc020141a:	0f800593          	li	a1,248
ffffffffc020141e:	00001517          	auipc	a0,0x1
ffffffffc0201422:	3c250513          	addi	a0,a0,962 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201426:	fadfe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc020142a <best_fit_free_pages>:
ffffffffc020142a:	1141                	addi	sp,sp,-16
ffffffffc020142c:	e406                	sd	ra,8(sp)
ffffffffc020142e:	14058a63          	beqz	a1,ffffffffc0201582 <best_fit_free_pages+0x158>
ffffffffc0201432:	00259693          	slli	a3,a1,0x2
ffffffffc0201436:	96ae                	add	a3,a3,a1
ffffffffc0201438:	068e                	slli	a3,a3,0x3
ffffffffc020143a:	96aa                	add	a3,a3,a0
ffffffffc020143c:	87aa                	mv	a5,a0
ffffffffc020143e:	02d50263          	beq	a0,a3,ffffffffc0201462 <best_fit_free_pages+0x38>
ffffffffc0201442:	6798                	ld	a4,8(a5)
ffffffffc0201444:	8b05                	andi	a4,a4,1
ffffffffc0201446:	10071e63          	bnez	a4,ffffffffc0201562 <best_fit_free_pages+0x138>
ffffffffc020144a:	6798                	ld	a4,8(a5)
ffffffffc020144c:	8b09                	andi	a4,a4,2
ffffffffc020144e:	10071a63          	bnez	a4,ffffffffc0201562 <best_fit_free_pages+0x138>
ffffffffc0201452:	0007b423          	sd	zero,8(a5)
ffffffffc0201456:	0007a023          	sw	zero,0(a5)
ffffffffc020145a:	02878793          	addi	a5,a5,40
ffffffffc020145e:	fed792e3          	bne	a5,a3,ffffffffc0201442 <best_fit_free_pages+0x18>
ffffffffc0201462:	2581                	sext.w	a1,a1
ffffffffc0201464:	c90c                	sw	a1,16(a0)
ffffffffc0201466:	00850893          	addi	a7,a0,8
ffffffffc020146a:	4789                	li	a5,2
ffffffffc020146c:	40f8b02f          	amoor.d	zero,a5,(a7)
ffffffffc0201470:	00005697          	auipc	a3,0x5
ffffffffc0201474:	bb868693          	addi	a3,a3,-1096 # ffffffffc0206028 <free_area>
ffffffffc0201478:	4a98                	lw	a4,16(a3)
ffffffffc020147a:	669c                	ld	a5,8(a3)
ffffffffc020147c:	01850613          	addi	a2,a0,24
ffffffffc0201480:	9db9                	addw	a1,a1,a4
ffffffffc0201482:	ca8c                	sw	a1,16(a3)
ffffffffc0201484:	0ad78863          	beq	a5,a3,ffffffffc0201534 <best_fit_free_pages+0x10a>
ffffffffc0201488:	fe878713          	addi	a4,a5,-24
ffffffffc020148c:	0006b803          	ld	a6,0(a3)
ffffffffc0201490:	4581                	li	a1,0
ffffffffc0201492:	00e56a63          	bltu	a0,a4,ffffffffc02014a6 <best_fit_free_pages+0x7c>
ffffffffc0201496:	6798                	ld	a4,8(a5)
ffffffffc0201498:	06d70263          	beq	a4,a3,ffffffffc02014fc <best_fit_free_pages+0xd2>
ffffffffc020149c:	87ba                	mv	a5,a4
ffffffffc020149e:	fe878713          	addi	a4,a5,-24
ffffffffc02014a2:	fee57ae3          	bgeu	a0,a4,ffffffffc0201496 <best_fit_free_pages+0x6c>
ffffffffc02014a6:	c199                	beqz	a1,ffffffffc02014ac <best_fit_free_pages+0x82>
ffffffffc02014a8:	0106b023          	sd	a6,0(a3)
ffffffffc02014ac:	6398                	ld	a4,0(a5)
ffffffffc02014ae:	e390                	sd	a2,0(a5)
ffffffffc02014b0:	e710                	sd	a2,8(a4)
ffffffffc02014b2:	f11c                	sd	a5,32(a0)
ffffffffc02014b4:	ed18                	sd	a4,24(a0)
ffffffffc02014b6:	02d70063          	beq	a4,a3,ffffffffc02014d6 <best_fit_free_pages+0xac>
ffffffffc02014ba:	ff872803          	lw	a6,-8(a4)
ffffffffc02014be:	fe870593          	addi	a1,a4,-24
ffffffffc02014c2:	02081613          	slli	a2,a6,0x20
ffffffffc02014c6:	9201                	srli	a2,a2,0x20
ffffffffc02014c8:	00261793          	slli	a5,a2,0x2
ffffffffc02014cc:	97b2                	add	a5,a5,a2
ffffffffc02014ce:	078e                	slli	a5,a5,0x3
ffffffffc02014d0:	97ae                	add	a5,a5,a1
ffffffffc02014d2:	02f50f63          	beq	a0,a5,ffffffffc0201510 <best_fit_free_pages+0xe6>
ffffffffc02014d6:	7118                	ld	a4,32(a0)
ffffffffc02014d8:	00d70f63          	beq	a4,a3,ffffffffc02014f6 <best_fit_free_pages+0xcc>
ffffffffc02014dc:	490c                	lw	a1,16(a0)
ffffffffc02014de:	fe870693          	addi	a3,a4,-24
ffffffffc02014e2:	02059613          	slli	a2,a1,0x20
ffffffffc02014e6:	9201                	srli	a2,a2,0x20
ffffffffc02014e8:	00261793          	slli	a5,a2,0x2
ffffffffc02014ec:	97b2                	add	a5,a5,a2
ffffffffc02014ee:	078e                	slli	a5,a5,0x3
ffffffffc02014f0:	97aa                	add	a5,a5,a0
ffffffffc02014f2:	04f68863          	beq	a3,a5,ffffffffc0201542 <best_fit_free_pages+0x118>
ffffffffc02014f6:	60a2                	ld	ra,8(sp)
ffffffffc02014f8:	0141                	addi	sp,sp,16
ffffffffc02014fa:	8082                	ret
ffffffffc02014fc:	e790                	sd	a2,8(a5)
ffffffffc02014fe:	f114                	sd	a3,32(a0)
ffffffffc0201500:	6798                	ld	a4,8(a5)
ffffffffc0201502:	ed1c                	sd	a5,24(a0)
ffffffffc0201504:	02d70563          	beq	a4,a3,ffffffffc020152e <best_fit_free_pages+0x104>
ffffffffc0201508:	8832                	mv	a6,a2
ffffffffc020150a:	4585                	li	a1,1
ffffffffc020150c:	87ba                	mv	a5,a4
ffffffffc020150e:	bf41                	j	ffffffffc020149e <best_fit_free_pages+0x74>
ffffffffc0201510:	491c                	lw	a5,16(a0)
ffffffffc0201512:	0107883b          	addw	a6,a5,a6
ffffffffc0201516:	ff072c23          	sw	a6,-8(a4)
ffffffffc020151a:	57f5                	li	a5,-3
ffffffffc020151c:	60f8b02f          	amoand.d	zero,a5,(a7)
ffffffffc0201520:	6d10                	ld	a2,24(a0)
ffffffffc0201522:	711c                	ld	a5,32(a0)
ffffffffc0201524:	852e                	mv	a0,a1
ffffffffc0201526:	e61c                	sd	a5,8(a2)
ffffffffc0201528:	6718                	ld	a4,8(a4)
ffffffffc020152a:	e390                	sd	a2,0(a5)
ffffffffc020152c:	b775                	j	ffffffffc02014d8 <best_fit_free_pages+0xae>
ffffffffc020152e:	e290                	sd	a2,0(a3)
ffffffffc0201530:	873e                	mv	a4,a5
ffffffffc0201532:	b761                	j	ffffffffc02014ba <best_fit_free_pages+0x90>
ffffffffc0201534:	60a2                	ld	ra,8(sp)
ffffffffc0201536:	e390                	sd	a2,0(a5)
ffffffffc0201538:	e790                	sd	a2,8(a5)
ffffffffc020153a:	f11c                	sd	a5,32(a0)
ffffffffc020153c:	ed1c                	sd	a5,24(a0)
ffffffffc020153e:	0141                	addi	sp,sp,16
ffffffffc0201540:	8082                	ret
ffffffffc0201542:	ff872783          	lw	a5,-8(a4)
ffffffffc0201546:	ff070693          	addi	a3,a4,-16
ffffffffc020154a:	9dbd                	addw	a1,a1,a5
ffffffffc020154c:	c90c                	sw	a1,16(a0)
ffffffffc020154e:	57f5                	li	a5,-3
ffffffffc0201550:	60f6b02f          	amoand.d	zero,a5,(a3)
ffffffffc0201554:	6314                	ld	a3,0(a4)
ffffffffc0201556:	671c                	ld	a5,8(a4)
ffffffffc0201558:	60a2                	ld	ra,8(sp)
ffffffffc020155a:	e69c                	sd	a5,8(a3)
ffffffffc020155c:	e394                	sd	a3,0(a5)
ffffffffc020155e:	0141                	addi	sp,sp,16
ffffffffc0201560:	8082                	ret
ffffffffc0201562:	00001697          	auipc	a3,0x1
ffffffffc0201566:	55668693          	addi	a3,a3,1366 # ffffffffc0202ab8 <etext+0xbdc>
ffffffffc020156a:	00001617          	auipc	a2,0x1
ffffffffc020156e:	25e60613          	addi	a2,a2,606 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc0201572:	09300593          	li	a1,147
ffffffffc0201576:	00001517          	auipc	a0,0x1
ffffffffc020157a:	26a50513          	addi	a0,a0,618 # ffffffffc02027e0 <etext+0x904>
ffffffffc020157e:	e55fe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc0201582:	00001697          	auipc	a3,0x1
ffffffffc0201586:	23e68693          	addi	a3,a3,574 # ffffffffc02027c0 <etext+0x8e4>
ffffffffc020158a:	00001617          	auipc	a2,0x1
ffffffffc020158e:	23e60613          	addi	a2,a2,574 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc0201592:	09000593          	li	a1,144
ffffffffc0201596:	00001517          	auipc	a0,0x1
ffffffffc020159a:	24a50513          	addi	a0,a0,586 # ffffffffc02027e0 <etext+0x904>
ffffffffc020159e:	e35fe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc02015a2 <best_fit_init_memmap>:
ffffffffc02015a2:	1141                	addi	sp,sp,-16
ffffffffc02015a4:	e406                	sd	ra,8(sp)
ffffffffc02015a6:	c9e1                	beqz	a1,ffffffffc0201676 <best_fit_init_memmap+0xd4>
ffffffffc02015a8:	00259693          	slli	a3,a1,0x2
ffffffffc02015ac:	96ae                	add	a3,a3,a1
ffffffffc02015ae:	068e                	slli	a3,a3,0x3
ffffffffc02015b0:	96aa                	add	a3,a3,a0
ffffffffc02015b2:	87aa                	mv	a5,a0
ffffffffc02015b4:	00d50f63          	beq	a0,a3,ffffffffc02015d2 <best_fit_init_memmap+0x30>
ffffffffc02015b8:	6798                	ld	a4,8(a5)
ffffffffc02015ba:	8b05                	andi	a4,a4,1
ffffffffc02015bc:	cf49                	beqz	a4,ffffffffc0201656 <best_fit_init_memmap+0xb4>
ffffffffc02015be:	0007a823          	sw	zero,16(a5)
ffffffffc02015c2:	0007b423          	sd	zero,8(a5)
ffffffffc02015c6:	0007a023          	sw	zero,0(a5)
ffffffffc02015ca:	02878793          	addi	a5,a5,40
ffffffffc02015ce:	fed795e3          	bne	a5,a3,ffffffffc02015b8 <best_fit_init_memmap+0x16>
ffffffffc02015d2:	2581                	sext.w	a1,a1
ffffffffc02015d4:	c90c                	sw	a1,16(a0)
ffffffffc02015d6:	4789                	li	a5,2
ffffffffc02015d8:	00850713          	addi	a4,a0,8
ffffffffc02015dc:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc02015e0:	00005697          	auipc	a3,0x5
ffffffffc02015e4:	a4868693          	addi	a3,a3,-1464 # ffffffffc0206028 <free_area>
ffffffffc02015e8:	4a98                	lw	a4,16(a3)
ffffffffc02015ea:	669c                	ld	a5,8(a3)
ffffffffc02015ec:	01850613          	addi	a2,a0,24
ffffffffc02015f0:	9db9                	addw	a1,a1,a4
ffffffffc02015f2:	ca8c                	sw	a1,16(a3)
ffffffffc02015f4:	04d78a63          	beq	a5,a3,ffffffffc0201648 <best_fit_init_memmap+0xa6>
ffffffffc02015f8:	fe878713          	addi	a4,a5,-24
ffffffffc02015fc:	0006b803          	ld	a6,0(a3)
ffffffffc0201600:	4581                	li	a1,0
ffffffffc0201602:	00e56a63          	bltu	a0,a4,ffffffffc0201616 <best_fit_init_memmap+0x74>
ffffffffc0201606:	6798                	ld	a4,8(a5)
ffffffffc0201608:	02d70263          	beq	a4,a3,ffffffffc020162c <best_fit_init_memmap+0x8a>
ffffffffc020160c:	87ba                	mv	a5,a4
ffffffffc020160e:	fe878713          	addi	a4,a5,-24
ffffffffc0201612:	fee57ae3          	bgeu	a0,a4,ffffffffc0201606 <best_fit_init_memmap+0x64>
ffffffffc0201616:	c199                	beqz	a1,ffffffffc020161c <best_fit_init_memmap+0x7a>
ffffffffc0201618:	0106b023          	sd	a6,0(a3)
ffffffffc020161c:	6398                	ld	a4,0(a5)
ffffffffc020161e:	60a2                	ld	ra,8(sp)
ffffffffc0201620:	e390                	sd	a2,0(a5)
ffffffffc0201622:	e710                	sd	a2,8(a4)
ffffffffc0201624:	f11c                	sd	a5,32(a0)
ffffffffc0201626:	ed18                	sd	a4,24(a0)
ffffffffc0201628:	0141                	addi	sp,sp,16
ffffffffc020162a:	8082                	ret
ffffffffc020162c:	e790                	sd	a2,8(a5)
ffffffffc020162e:	f114                	sd	a3,32(a0)
ffffffffc0201630:	6798                	ld	a4,8(a5)
ffffffffc0201632:	ed1c                	sd	a5,24(a0)
ffffffffc0201634:	00d70663          	beq	a4,a3,ffffffffc0201640 <best_fit_init_memmap+0x9e>
ffffffffc0201638:	8832                	mv	a6,a2
ffffffffc020163a:	4585                	li	a1,1
ffffffffc020163c:	87ba                	mv	a5,a4
ffffffffc020163e:	bfc1                	j	ffffffffc020160e <best_fit_init_memmap+0x6c>
ffffffffc0201640:	60a2                	ld	ra,8(sp)
ffffffffc0201642:	e290                	sd	a2,0(a3)
ffffffffc0201644:	0141                	addi	sp,sp,16
ffffffffc0201646:	8082                	ret
ffffffffc0201648:	60a2                	ld	ra,8(sp)
ffffffffc020164a:	e390                	sd	a2,0(a5)
ffffffffc020164c:	e790                	sd	a2,8(a5)
ffffffffc020164e:	f11c                	sd	a5,32(a0)
ffffffffc0201650:	ed1c                	sd	a5,24(a0)
ffffffffc0201652:	0141                	addi	sp,sp,16
ffffffffc0201654:	8082                	ret
ffffffffc0201656:	00001697          	auipc	a3,0x1
ffffffffc020165a:	48a68693          	addi	a3,a3,1162 # ffffffffc0202ae0 <etext+0xc04>
ffffffffc020165e:	00001617          	auipc	a2,0x1
ffffffffc0201662:	16a60613          	addi	a2,a2,362 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc0201666:	04b00593          	li	a1,75
ffffffffc020166a:	00001517          	auipc	a0,0x1
ffffffffc020166e:	17650513          	addi	a0,a0,374 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201672:	d61fe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc0201676:	00001697          	auipc	a3,0x1
ffffffffc020167a:	14a68693          	addi	a3,a3,330 # ffffffffc02027c0 <etext+0x8e4>
ffffffffc020167e:	00001617          	auipc	a2,0x1
ffffffffc0201682:	14a60613          	addi	a2,a2,330 # ffffffffc02027c8 <etext+0x8ec>
ffffffffc0201686:	04800593          	li	a1,72
ffffffffc020168a:	00001517          	auipc	a0,0x1
ffffffffc020168e:	15650513          	addi	a0,a0,342 # ffffffffc02027e0 <etext+0x904>
ffffffffc0201692:	d41fe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc0201696 <alloc_pages>:
ffffffffc0201696:	100027f3          	csrr	a5,sstatus
ffffffffc020169a:	8b89                	andi	a5,a5,2
ffffffffc020169c:	e799                	bnez	a5,ffffffffc02016aa <alloc_pages+0x14>
ffffffffc020169e:	00005797          	auipc	a5,0x5
ffffffffc02016a2:	dda7b783          	ld	a5,-550(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016a6:	6f9c                	ld	a5,24(a5)
ffffffffc02016a8:	8782                	jr	a5
ffffffffc02016aa:	1141                	addi	sp,sp,-16
ffffffffc02016ac:	e406                	sd	ra,8(sp)
ffffffffc02016ae:	e022                	sd	s0,0(sp)
ffffffffc02016b0:	842a                	mv	s0,a0
ffffffffc02016b2:	982ff0ef          	jal	ffffffffc0200834 <intr_disable>
ffffffffc02016b6:	00005797          	auipc	a5,0x5
ffffffffc02016ba:	dc27b783          	ld	a5,-574(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016be:	6f9c                	ld	a5,24(a5)
ffffffffc02016c0:	8522                	mv	a0,s0
ffffffffc02016c2:	9782                	jalr	a5
ffffffffc02016c4:	842a                	mv	s0,a0
ffffffffc02016c6:	968ff0ef          	jal	ffffffffc020082e <intr_enable>
ffffffffc02016ca:	60a2                	ld	ra,8(sp)
ffffffffc02016cc:	8522                	mv	a0,s0
ffffffffc02016ce:	6402                	ld	s0,0(sp)
ffffffffc02016d0:	0141                	addi	sp,sp,16
ffffffffc02016d2:	8082                	ret

ffffffffc02016d4 <free_pages>:
ffffffffc02016d4:	100027f3          	csrr	a5,sstatus
ffffffffc02016d8:	8b89                	andi	a5,a5,2
ffffffffc02016da:	e799                	bnez	a5,ffffffffc02016e8 <free_pages+0x14>
ffffffffc02016dc:	00005797          	auipc	a5,0x5
ffffffffc02016e0:	d9c7b783          	ld	a5,-612(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016e4:	739c                	ld	a5,32(a5)
ffffffffc02016e6:	8782                	jr	a5
ffffffffc02016e8:	1101                	addi	sp,sp,-32
ffffffffc02016ea:	ec06                	sd	ra,24(sp)
ffffffffc02016ec:	e822                	sd	s0,16(sp)
ffffffffc02016ee:	e426                	sd	s1,8(sp)
ffffffffc02016f0:	842a                	mv	s0,a0
ffffffffc02016f2:	84ae                	mv	s1,a1
ffffffffc02016f4:	940ff0ef          	jal	ffffffffc0200834 <intr_disable>
ffffffffc02016f8:	00005797          	auipc	a5,0x5
ffffffffc02016fc:	d807b783          	ld	a5,-640(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201700:	739c                	ld	a5,32(a5)
ffffffffc0201702:	85a6                	mv	a1,s1
ffffffffc0201704:	8522                	mv	a0,s0
ffffffffc0201706:	9782                	jalr	a5
ffffffffc0201708:	6442                	ld	s0,16(sp)
ffffffffc020170a:	60e2                	ld	ra,24(sp)
ffffffffc020170c:	64a2                	ld	s1,8(sp)
ffffffffc020170e:	6105                	addi	sp,sp,32
ffffffffc0201710:	91eff06f          	j	ffffffffc020082e <intr_enable>

ffffffffc0201714 <nr_free_pages>:
ffffffffc0201714:	100027f3          	csrr	a5,sstatus
ffffffffc0201718:	8b89                	andi	a5,a5,2
ffffffffc020171a:	e799                	bnez	a5,ffffffffc0201728 <nr_free_pages+0x14>
ffffffffc020171c:	00005797          	auipc	a5,0x5
ffffffffc0201720:	d5c7b783          	ld	a5,-676(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201724:	779c                	ld	a5,40(a5)
ffffffffc0201726:	8782                	jr	a5
ffffffffc0201728:	1141                	addi	sp,sp,-16
ffffffffc020172a:	e406                	sd	ra,8(sp)
ffffffffc020172c:	e022                	sd	s0,0(sp)
ffffffffc020172e:	906ff0ef          	jal	ffffffffc0200834 <intr_disable>
ffffffffc0201732:	00005797          	auipc	a5,0x5
ffffffffc0201736:	d467b783          	ld	a5,-698(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020173a:	779c                	ld	a5,40(a5)
ffffffffc020173c:	9782                	jalr	a5
ffffffffc020173e:	842a                	mv	s0,a0
ffffffffc0201740:	8eeff0ef          	jal	ffffffffc020082e <intr_enable>
ffffffffc0201744:	60a2                	ld	ra,8(sp)
ffffffffc0201746:	8522                	mv	a0,s0
ffffffffc0201748:	6402                	ld	s0,0(sp)
ffffffffc020174a:	0141                	addi	sp,sp,16
ffffffffc020174c:	8082                	ret

ffffffffc020174e <pmm_init>:
ffffffffc020174e:	00001797          	auipc	a5,0x1
ffffffffc0201752:	63278793          	addi	a5,a5,1586 # ffffffffc0202d80 <best_fit_pmm_manager>
ffffffffc0201756:	638c                	ld	a1,0(a5)
ffffffffc0201758:	7179                	addi	sp,sp,-48
ffffffffc020175a:	f022                	sd	s0,32(sp)
ffffffffc020175c:	00001517          	auipc	a0,0x1
ffffffffc0201760:	3ac50513          	addi	a0,a0,940 # ffffffffc0202b08 <etext+0xc2c>
ffffffffc0201764:	00005417          	auipc	s0,0x5
ffffffffc0201768:	d1440413          	addi	s0,s0,-748 # ffffffffc0206478 <pmm_manager>
ffffffffc020176c:	f406                	sd	ra,40(sp)
ffffffffc020176e:	ec26                	sd	s1,24(sp)
ffffffffc0201770:	e44e                	sd	s3,8(sp)
ffffffffc0201772:	e84a                	sd	s2,16(sp)
ffffffffc0201774:	e052                	sd	s4,0(sp)
ffffffffc0201776:	e01c                	sd	a5,0(s0)
ffffffffc0201778:	961fe0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020177c:	601c                	ld	a5,0(s0)
ffffffffc020177e:	00005497          	auipc	s1,0x5
ffffffffc0201782:	d1248493          	addi	s1,s1,-750 # ffffffffc0206490 <va_pa_offset>
ffffffffc0201786:	679c                	ld	a5,8(a5)
ffffffffc0201788:	9782                	jalr	a5
ffffffffc020178a:	57f5                	li	a5,-3
ffffffffc020178c:	07fa                	slli	a5,a5,0x1e
ffffffffc020178e:	e09c                	sd	a5,0(s1)
ffffffffc0201790:	88aff0ef          	jal	ffffffffc020081a <get_memory_base>
ffffffffc0201794:	89aa                	mv	s3,a0
ffffffffc0201796:	88eff0ef          	jal	ffffffffc0200824 <get_memory_size>
ffffffffc020179a:	16050163          	beqz	a0,ffffffffc02018fc <pmm_init+0x1ae>
ffffffffc020179e:	892a                	mv	s2,a0
ffffffffc02017a0:	00001517          	auipc	a0,0x1
ffffffffc02017a4:	3b050513          	addi	a0,a0,944 # ffffffffc0202b50 <etext+0xc74>
ffffffffc02017a8:	931fe0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02017ac:	01298a33          	add	s4,s3,s2
ffffffffc02017b0:	864e                	mv	a2,s3
ffffffffc02017b2:	fffa0693          	addi	a3,s4,-1
ffffffffc02017b6:	85ca                	mv	a1,s2
ffffffffc02017b8:	00001517          	auipc	a0,0x1
ffffffffc02017bc:	3b050513          	addi	a0,a0,944 # ffffffffc0202b68 <etext+0xc8c>
ffffffffc02017c0:	919fe0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc02017c4:	c80007b7          	lui	a5,0xc8000
ffffffffc02017c8:	8652                	mv	a2,s4
ffffffffc02017ca:	0d47e863          	bltu	a5,s4,ffffffffc020189a <pmm_init+0x14c>
ffffffffc02017ce:	00006797          	auipc	a5,0x6
ffffffffc02017d2:	cd178793          	addi	a5,a5,-815 # ffffffffc020749f <end+0xfff>
ffffffffc02017d6:	757d                	lui	a0,0xfffff
ffffffffc02017d8:	8d7d                	and	a0,a0,a5
ffffffffc02017da:	8231                	srli	a2,a2,0xc
ffffffffc02017dc:	00005597          	auipc	a1,0x5
ffffffffc02017e0:	c8c58593          	addi	a1,a1,-884 # ffffffffc0206468 <npage>
ffffffffc02017e4:	00005817          	auipc	a6,0x5
ffffffffc02017e8:	c8c80813          	addi	a6,a6,-884 # ffffffffc0206470 <pages>
ffffffffc02017ec:	e190                	sd	a2,0(a1)
ffffffffc02017ee:	00a83023          	sd	a0,0(a6)
ffffffffc02017f2:	000807b7          	lui	a5,0x80
ffffffffc02017f6:	02f60663          	beq	a2,a5,ffffffffc0201822 <pmm_init+0xd4>
ffffffffc02017fa:	4701                	li	a4,0
ffffffffc02017fc:	4781                	li	a5,0
ffffffffc02017fe:	4305                	li	t1,1
ffffffffc0201800:	fff808b7          	lui	a7,0xfff80
ffffffffc0201804:	953a                	add	a0,a0,a4
ffffffffc0201806:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc020180a:	4066b02f          	amoor.d	zero,t1,(a3)
ffffffffc020180e:	6190                	ld	a2,0(a1)
ffffffffc0201810:	0785                	addi	a5,a5,1 # 80001 <kern_entry-0xffffffffc017ffff>
ffffffffc0201812:	00083503          	ld	a0,0(a6)
ffffffffc0201816:	011606b3          	add	a3,a2,a7
ffffffffc020181a:	02870713          	addi	a4,a4,40
ffffffffc020181e:	fed7e3e3          	bltu	a5,a3,ffffffffc0201804 <pmm_init+0xb6>
ffffffffc0201822:	00261693          	slli	a3,a2,0x2
ffffffffc0201826:	96b2                	add	a3,a3,a2
ffffffffc0201828:	fec007b7          	lui	a5,0xfec00
ffffffffc020182c:	97aa                	add	a5,a5,a0
ffffffffc020182e:	068e                	slli	a3,a3,0x3
ffffffffc0201830:	96be                	add	a3,a3,a5
ffffffffc0201832:	c02007b7          	lui	a5,0xc0200
ffffffffc0201836:	0af6e763          	bltu	a3,a5,ffffffffc02018e4 <pmm_init+0x196>
ffffffffc020183a:	6098                	ld	a4,0(s1)
ffffffffc020183c:	77fd                	lui	a5,0xfffff
ffffffffc020183e:	00fa75b3          	and	a1,s4,a5
ffffffffc0201842:	8e99                	sub	a3,a3,a4
ffffffffc0201844:	04b6ee63          	bltu	a3,a1,ffffffffc02018a0 <pmm_init+0x152>
ffffffffc0201848:	601c                	ld	a5,0(s0)
ffffffffc020184a:	7b9c                	ld	a5,48(a5)
ffffffffc020184c:	9782                	jalr	a5
ffffffffc020184e:	00001517          	auipc	a0,0x1
ffffffffc0201852:	3a250513          	addi	a0,a0,930 # ffffffffc0202bf0 <etext+0xd14>
ffffffffc0201856:	883fe0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020185a:	00003597          	auipc	a1,0x3
ffffffffc020185e:	7a658593          	addi	a1,a1,1958 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201862:	00005797          	auipc	a5,0x5
ffffffffc0201866:	c2b7b323          	sd	a1,-986(a5) # ffffffffc0206488 <satp_virtual>
ffffffffc020186a:	c02007b7          	lui	a5,0xc0200
ffffffffc020186e:	0af5e363          	bltu	a1,a5,ffffffffc0201914 <pmm_init+0x1c6>
ffffffffc0201872:	6090                	ld	a2,0(s1)
ffffffffc0201874:	7402                	ld	s0,32(sp)
ffffffffc0201876:	70a2                	ld	ra,40(sp)
ffffffffc0201878:	64e2                	ld	s1,24(sp)
ffffffffc020187a:	6942                	ld	s2,16(sp)
ffffffffc020187c:	69a2                	ld	s3,8(sp)
ffffffffc020187e:	6a02                	ld	s4,0(sp)
ffffffffc0201880:	40c58633          	sub	a2,a1,a2
ffffffffc0201884:	00005797          	auipc	a5,0x5
ffffffffc0201888:	bec7be23          	sd	a2,-1028(a5) # ffffffffc0206480 <satp_physical>
ffffffffc020188c:	00001517          	auipc	a0,0x1
ffffffffc0201890:	38450513          	addi	a0,a0,900 # ffffffffc0202c10 <etext+0xd34>
ffffffffc0201894:	6145                	addi	sp,sp,48
ffffffffc0201896:	843fe06f          	j	ffffffffc02000d8 <cprintf>
ffffffffc020189a:	c8000637          	lui	a2,0xc8000
ffffffffc020189e:	bf05                	j	ffffffffc02017ce <pmm_init+0x80>
ffffffffc02018a0:	6705                	lui	a4,0x1
ffffffffc02018a2:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02018a4:	96ba                	add	a3,a3,a4
ffffffffc02018a6:	8efd                	and	a3,a3,a5
ffffffffc02018a8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018ac:	02c7f063          	bgeu	a5,a2,ffffffffc02018cc <pmm_init+0x17e>
ffffffffc02018b0:	6010                	ld	a2,0(s0)
ffffffffc02018b2:	fff80737          	lui	a4,0xfff80
ffffffffc02018b6:	973e                	add	a4,a4,a5
ffffffffc02018b8:	00271793          	slli	a5,a4,0x2
ffffffffc02018bc:	97ba                	add	a5,a5,a4
ffffffffc02018be:	6a18                	ld	a4,16(a2)
ffffffffc02018c0:	8d95                	sub	a1,a1,a3
ffffffffc02018c2:	078e                	slli	a5,a5,0x3
ffffffffc02018c4:	81b1                	srli	a1,a1,0xc
ffffffffc02018c6:	953e                	add	a0,a0,a5
ffffffffc02018c8:	9702                	jalr	a4
ffffffffc02018ca:	bfbd                	j	ffffffffc0201848 <pmm_init+0xfa>
ffffffffc02018cc:	00001617          	auipc	a2,0x1
ffffffffc02018d0:	2f460613          	addi	a2,a2,756 # ffffffffc0202bc0 <etext+0xce4>
ffffffffc02018d4:	06b00593          	li	a1,107
ffffffffc02018d8:	00001517          	auipc	a0,0x1
ffffffffc02018dc:	30850513          	addi	a0,a0,776 # ffffffffc0202be0 <etext+0xd04>
ffffffffc02018e0:	af3fe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02018e4:	00001617          	auipc	a2,0x1
ffffffffc02018e8:	2b460613          	addi	a2,a2,692 # ffffffffc0202b98 <etext+0xcbc>
ffffffffc02018ec:	07100593          	li	a1,113
ffffffffc02018f0:	00001517          	auipc	a0,0x1
ffffffffc02018f4:	25050513          	addi	a0,a0,592 # ffffffffc0202b40 <etext+0xc64>
ffffffffc02018f8:	adbfe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc02018fc:	00001617          	auipc	a2,0x1
ffffffffc0201900:	22460613          	addi	a2,a2,548 # ffffffffc0202b20 <etext+0xc44>
ffffffffc0201904:	05a00593          	li	a1,90
ffffffffc0201908:	00001517          	auipc	a0,0x1
ffffffffc020190c:	23850513          	addi	a0,a0,568 # ffffffffc0202b40 <etext+0xc64>
ffffffffc0201910:	ac3fe0ef          	jal	ffffffffc02003d2 <__panic>
ffffffffc0201914:	86ae                	mv	a3,a1
ffffffffc0201916:	00001617          	auipc	a2,0x1
ffffffffc020191a:	28260613          	addi	a2,a2,642 # ffffffffc0202b98 <etext+0xcbc>
ffffffffc020191e:	08c00593          	li	a1,140
ffffffffc0201922:	00001517          	auipc	a0,0x1
ffffffffc0201926:	21e50513          	addi	a0,a0,542 # ffffffffc0202b40 <etext+0xc64>
ffffffffc020192a:	aa9fe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc020192e <printnum>:
ffffffffc020192e:	02069813          	slli	a6,a3,0x20
ffffffffc0201932:	7179                	addi	sp,sp,-48
ffffffffc0201934:	02085813          	srli	a6,a6,0x20
ffffffffc0201938:	e052                	sd	s4,0(sp)
ffffffffc020193a:	03067a33          	remu	s4,a2,a6
ffffffffc020193e:	f022                	sd	s0,32(sp)
ffffffffc0201940:	ec26                	sd	s1,24(sp)
ffffffffc0201942:	e84a                	sd	s2,16(sp)
ffffffffc0201944:	f406                	sd	ra,40(sp)
ffffffffc0201946:	e44e                	sd	s3,8(sp)
ffffffffc0201948:	84aa                	mv	s1,a0
ffffffffc020194a:	892e                	mv	s2,a1
ffffffffc020194c:	fff7041b          	addiw	s0,a4,-1 # fffffffffff7ffff <end+0x3fd79b5f>
ffffffffc0201950:	2a01                	sext.w	s4,s4
ffffffffc0201952:	03067e63          	bgeu	a2,a6,ffffffffc020198e <printnum+0x60>
ffffffffc0201956:	89be                	mv	s3,a5
ffffffffc0201958:	00805763          	blez	s0,ffffffffc0201966 <printnum+0x38>
ffffffffc020195c:	347d                	addiw	s0,s0,-1
ffffffffc020195e:	85ca                	mv	a1,s2
ffffffffc0201960:	854e                	mv	a0,s3
ffffffffc0201962:	9482                	jalr	s1
ffffffffc0201964:	fc65                	bnez	s0,ffffffffc020195c <printnum+0x2e>
ffffffffc0201966:	1a02                	slli	s4,s4,0x20
ffffffffc0201968:	00001797          	auipc	a5,0x1
ffffffffc020196c:	2e878793          	addi	a5,a5,744 # ffffffffc0202c50 <etext+0xd74>
ffffffffc0201970:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201974:	9a3e                	add	s4,s4,a5
ffffffffc0201976:	7402                	ld	s0,32(sp)
ffffffffc0201978:	000a4503          	lbu	a0,0(s4)
ffffffffc020197c:	70a2                	ld	ra,40(sp)
ffffffffc020197e:	69a2                	ld	s3,8(sp)
ffffffffc0201980:	6a02                	ld	s4,0(sp)
ffffffffc0201982:	85ca                	mv	a1,s2
ffffffffc0201984:	87a6                	mv	a5,s1
ffffffffc0201986:	6942                	ld	s2,16(sp)
ffffffffc0201988:	64e2                	ld	s1,24(sp)
ffffffffc020198a:	6145                	addi	sp,sp,48
ffffffffc020198c:	8782                	jr	a5
ffffffffc020198e:	03065633          	divu	a2,a2,a6
ffffffffc0201992:	8722                	mv	a4,s0
ffffffffc0201994:	f9bff0ef          	jal	ffffffffc020192e <printnum>
ffffffffc0201998:	b7f9                	j	ffffffffc0201966 <printnum+0x38>

ffffffffc020199a <vprintfmt>:
ffffffffc020199a:	7119                	addi	sp,sp,-128
ffffffffc020199c:	f4a6                	sd	s1,104(sp)
ffffffffc020199e:	f0ca                	sd	s2,96(sp)
ffffffffc02019a0:	ecce                	sd	s3,88(sp)
ffffffffc02019a2:	e8d2                	sd	s4,80(sp)
ffffffffc02019a4:	e4d6                	sd	s5,72(sp)
ffffffffc02019a6:	e0da                	sd	s6,64(sp)
ffffffffc02019a8:	fc5e                	sd	s7,56(sp)
ffffffffc02019aa:	f06a                	sd	s10,32(sp)
ffffffffc02019ac:	fc86                	sd	ra,120(sp)
ffffffffc02019ae:	f8a2                	sd	s0,112(sp)
ffffffffc02019b0:	f862                	sd	s8,48(sp)
ffffffffc02019b2:	f466                	sd	s9,40(sp)
ffffffffc02019b4:	ec6e                	sd	s11,24(sp)
ffffffffc02019b6:	892a                	mv	s2,a0
ffffffffc02019b8:	84ae                	mv	s1,a1
ffffffffc02019ba:	8d32                	mv	s10,a2
ffffffffc02019bc:	8a36                	mv	s4,a3
ffffffffc02019be:	02500993          	li	s3,37
ffffffffc02019c2:	5b7d                	li	s6,-1
ffffffffc02019c4:	00001a97          	auipc	s5,0x1
ffffffffc02019c8:	3f4a8a93          	addi	s5,s5,1012 # ffffffffc0202db8 <best_fit_pmm_manager+0x38>
ffffffffc02019cc:	00001b97          	auipc	s7,0x1
ffffffffc02019d0:	544b8b93          	addi	s7,s7,1348 # ffffffffc0202f10 <error_string>
ffffffffc02019d4:	000d4503          	lbu	a0,0(s10)
ffffffffc02019d8:	001d0413          	addi	s0,s10,1
ffffffffc02019dc:	01350a63          	beq	a0,s3,ffffffffc02019f0 <vprintfmt+0x56>
ffffffffc02019e0:	c121                	beqz	a0,ffffffffc0201a20 <vprintfmt+0x86>
ffffffffc02019e2:	85a6                	mv	a1,s1
ffffffffc02019e4:	0405                	addi	s0,s0,1
ffffffffc02019e6:	9902                	jalr	s2
ffffffffc02019e8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02019ec:	ff351ae3          	bne	a0,s3,ffffffffc02019e0 <vprintfmt+0x46>
ffffffffc02019f0:	00044603          	lbu	a2,0(s0)
ffffffffc02019f4:	02000793          	li	a5,32
ffffffffc02019f8:	4c81                	li	s9,0
ffffffffc02019fa:	4881                	li	a7,0
ffffffffc02019fc:	5c7d                	li	s8,-1
ffffffffc02019fe:	5dfd                	li	s11,-1
ffffffffc0201a00:	05500513          	li	a0,85
ffffffffc0201a04:	4825                	li	a6,9
ffffffffc0201a06:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a0a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a0e:	00140d13          	addi	s10,s0,1
ffffffffc0201a12:	04b56263          	bltu	a0,a1,ffffffffc0201a56 <vprintfmt+0xbc>
ffffffffc0201a16:	058a                	slli	a1,a1,0x2
ffffffffc0201a18:	95d6                	add	a1,a1,s5
ffffffffc0201a1a:	4194                	lw	a3,0(a1)
ffffffffc0201a1c:	96d6                	add	a3,a3,s5
ffffffffc0201a1e:	8682                	jr	a3
ffffffffc0201a20:	70e6                	ld	ra,120(sp)
ffffffffc0201a22:	7446                	ld	s0,112(sp)
ffffffffc0201a24:	74a6                	ld	s1,104(sp)
ffffffffc0201a26:	7906                	ld	s2,96(sp)
ffffffffc0201a28:	69e6                	ld	s3,88(sp)
ffffffffc0201a2a:	6a46                	ld	s4,80(sp)
ffffffffc0201a2c:	6aa6                	ld	s5,72(sp)
ffffffffc0201a2e:	6b06                	ld	s6,64(sp)
ffffffffc0201a30:	7be2                	ld	s7,56(sp)
ffffffffc0201a32:	7c42                	ld	s8,48(sp)
ffffffffc0201a34:	7ca2                	ld	s9,40(sp)
ffffffffc0201a36:	7d02                	ld	s10,32(sp)
ffffffffc0201a38:	6de2                	ld	s11,24(sp)
ffffffffc0201a3a:	6109                	addi	sp,sp,128
ffffffffc0201a3c:	8082                	ret
ffffffffc0201a3e:	87b2                	mv	a5,a2
ffffffffc0201a40:	00144603          	lbu	a2,1(s0)
ffffffffc0201a44:	846a                	mv	s0,s10
ffffffffc0201a46:	00140d13          	addi	s10,s0,1
ffffffffc0201a4a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a4e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a52:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a16 <vprintfmt+0x7c>
ffffffffc0201a56:	85a6                	mv	a1,s1
ffffffffc0201a58:	02500513          	li	a0,37
ffffffffc0201a5c:	9902                	jalr	s2
ffffffffc0201a5e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a62:	8d22                	mv	s10,s0
ffffffffc0201a64:	f73788e3          	beq	a5,s3,ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201a68:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a6c:	1d7d                	addi	s10,s10,-1
ffffffffc0201a6e:	ff379de3          	bne	a5,s3,ffffffffc0201a68 <vprintfmt+0xce>
ffffffffc0201a72:	b78d                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201a74:	fd060c1b          	addiw	s8,a2,-48
ffffffffc0201a78:	00144603          	lbu	a2,1(s0)
ffffffffc0201a7c:	846a                	mv	s0,s10
ffffffffc0201a7e:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201a82:	0006059b          	sext.w	a1,a2
ffffffffc0201a86:	02d86463          	bltu	a6,a3,ffffffffc0201aae <vprintfmt+0x114>
ffffffffc0201a8a:	00144603          	lbu	a2,1(s0)
ffffffffc0201a8e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201a92:	0186873b          	addw	a4,a3,s8
ffffffffc0201a96:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201a9a:	9f2d                	addw	a4,a4,a1
ffffffffc0201a9c:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201aa0:	0405                	addi	s0,s0,1
ffffffffc0201aa2:	fd070c1b          	addiw	s8,a4,-48
ffffffffc0201aa6:	0006059b          	sext.w	a1,a2
ffffffffc0201aaa:	fed870e3          	bgeu	a6,a3,ffffffffc0201a8a <vprintfmt+0xf0>
ffffffffc0201aae:	f40ddce3          	bgez	s11,ffffffffc0201a06 <vprintfmt+0x6c>
ffffffffc0201ab2:	8de2                	mv	s11,s8
ffffffffc0201ab4:	5c7d                	li	s8,-1
ffffffffc0201ab6:	bf81                	j	ffffffffc0201a06 <vprintfmt+0x6c>
ffffffffc0201ab8:	fffdc693          	not	a3,s11
ffffffffc0201abc:	96fd                	srai	a3,a3,0x3f
ffffffffc0201abe:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201ac2:	00144603          	lbu	a2,1(s0)
ffffffffc0201ac6:	2d81                	sext.w	s11,s11
ffffffffc0201ac8:	846a                	mv	s0,s10
ffffffffc0201aca:	bf35                	j	ffffffffc0201a06 <vprintfmt+0x6c>
ffffffffc0201acc:	000a2c03          	lw	s8,0(s4)
ffffffffc0201ad0:	00144603          	lbu	a2,1(s0)
ffffffffc0201ad4:	0a21                	addi	s4,s4,8
ffffffffc0201ad6:	846a                	mv	s0,s10
ffffffffc0201ad8:	bfd9                	j	ffffffffc0201aae <vprintfmt+0x114>
ffffffffc0201ada:	4705                	li	a4,1
ffffffffc0201adc:	008a0593          	addi	a1,s4,8
ffffffffc0201ae0:	01174463          	blt	a4,a7,ffffffffc0201ae8 <vprintfmt+0x14e>
ffffffffc0201ae4:	1a088e63          	beqz	a7,ffffffffc0201ca0 <vprintfmt+0x306>
ffffffffc0201ae8:	000a3603          	ld	a2,0(s4)
ffffffffc0201aec:	46c1                	li	a3,16
ffffffffc0201aee:	8a2e                	mv	s4,a1
ffffffffc0201af0:	2781                	sext.w	a5,a5
ffffffffc0201af2:	876e                	mv	a4,s11
ffffffffc0201af4:	85a6                	mv	a1,s1
ffffffffc0201af6:	854a                	mv	a0,s2
ffffffffc0201af8:	e37ff0ef          	jal	ffffffffc020192e <printnum>
ffffffffc0201afc:	bde1                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201afe:	000a2503          	lw	a0,0(s4)
ffffffffc0201b02:	85a6                	mv	a1,s1
ffffffffc0201b04:	0a21                	addi	s4,s4,8
ffffffffc0201b06:	9902                	jalr	s2
ffffffffc0201b08:	b5f1                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201b0a:	4705                	li	a4,1
ffffffffc0201b0c:	008a0593          	addi	a1,s4,8
ffffffffc0201b10:	01174463          	blt	a4,a7,ffffffffc0201b18 <vprintfmt+0x17e>
ffffffffc0201b14:	18088163          	beqz	a7,ffffffffc0201c96 <vprintfmt+0x2fc>
ffffffffc0201b18:	000a3603          	ld	a2,0(s4)
ffffffffc0201b1c:	46a9                	li	a3,10
ffffffffc0201b1e:	8a2e                	mv	s4,a1
ffffffffc0201b20:	bfc1                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201b22:	00144603          	lbu	a2,1(s0)
ffffffffc0201b26:	4c85                	li	s9,1
ffffffffc0201b28:	846a                	mv	s0,s10
ffffffffc0201b2a:	bdf1                	j	ffffffffc0201a06 <vprintfmt+0x6c>
ffffffffc0201b2c:	85a6                	mv	a1,s1
ffffffffc0201b2e:	02500513          	li	a0,37
ffffffffc0201b32:	9902                	jalr	s2
ffffffffc0201b34:	b545                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201b36:	00144603          	lbu	a2,1(s0)
ffffffffc0201b3a:	2885                	addiw	a7,a7,1 # fffffffffff80001 <end+0x3fd79b61>
ffffffffc0201b3c:	846a                	mv	s0,s10
ffffffffc0201b3e:	b5e1                	j	ffffffffc0201a06 <vprintfmt+0x6c>
ffffffffc0201b40:	4705                	li	a4,1
ffffffffc0201b42:	008a0593          	addi	a1,s4,8
ffffffffc0201b46:	01174463          	blt	a4,a7,ffffffffc0201b4e <vprintfmt+0x1b4>
ffffffffc0201b4a:	14088163          	beqz	a7,ffffffffc0201c8c <vprintfmt+0x2f2>
ffffffffc0201b4e:	000a3603          	ld	a2,0(s4)
ffffffffc0201b52:	46a1                	li	a3,8
ffffffffc0201b54:	8a2e                	mv	s4,a1
ffffffffc0201b56:	bf69                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201b58:	03000513          	li	a0,48
ffffffffc0201b5c:	85a6                	mv	a1,s1
ffffffffc0201b5e:	e03e                	sd	a5,0(sp)
ffffffffc0201b60:	9902                	jalr	s2
ffffffffc0201b62:	85a6                	mv	a1,s1
ffffffffc0201b64:	07800513          	li	a0,120
ffffffffc0201b68:	9902                	jalr	s2
ffffffffc0201b6a:	0a21                	addi	s4,s4,8
ffffffffc0201b6c:	6782                	ld	a5,0(sp)
ffffffffc0201b6e:	46c1                	li	a3,16
ffffffffc0201b70:	ff8a3603          	ld	a2,-8(s4)
ffffffffc0201b74:	bfb5                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201b76:	000a3403          	ld	s0,0(s4)
ffffffffc0201b7a:	008a0713          	addi	a4,s4,8
ffffffffc0201b7e:	e03a                	sd	a4,0(sp)
ffffffffc0201b80:	14040263          	beqz	s0,ffffffffc0201cc4 <vprintfmt+0x32a>
ffffffffc0201b84:	0fb05763          	blez	s11,ffffffffc0201c72 <vprintfmt+0x2d8>
ffffffffc0201b88:	02d00693          	li	a3,45
ffffffffc0201b8c:	0cd79163          	bne	a5,a3,ffffffffc0201c4e <vprintfmt+0x2b4>
ffffffffc0201b90:	00044783          	lbu	a5,0(s0)
ffffffffc0201b94:	0007851b          	sext.w	a0,a5
ffffffffc0201b98:	cf85                	beqz	a5,ffffffffc0201bd0 <vprintfmt+0x236>
ffffffffc0201b9a:	00140a13          	addi	s4,s0,1
ffffffffc0201b9e:	05e00413          	li	s0,94
ffffffffc0201ba2:	000c4563          	bltz	s8,ffffffffc0201bac <vprintfmt+0x212>
ffffffffc0201ba6:	3c7d                	addiw	s8,s8,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0201ba8:	036c0263          	beq	s8,s6,ffffffffc0201bcc <vprintfmt+0x232>
ffffffffc0201bac:	85a6                	mv	a1,s1
ffffffffc0201bae:	0e0c8e63          	beqz	s9,ffffffffc0201caa <vprintfmt+0x310>
ffffffffc0201bb2:	3781                	addiw	a5,a5,-32
ffffffffc0201bb4:	0ef47b63          	bgeu	s0,a5,ffffffffc0201caa <vprintfmt+0x310>
ffffffffc0201bb8:	03f00513          	li	a0,63
ffffffffc0201bbc:	9902                	jalr	s2
ffffffffc0201bbe:	000a4783          	lbu	a5,0(s4)
ffffffffc0201bc2:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bc4:	0a05                	addi	s4,s4,1
ffffffffc0201bc6:	0007851b          	sext.w	a0,a5
ffffffffc0201bca:	ffe1                	bnez	a5,ffffffffc0201ba2 <vprintfmt+0x208>
ffffffffc0201bcc:	01b05963          	blez	s11,ffffffffc0201bde <vprintfmt+0x244>
ffffffffc0201bd0:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bd2:	85a6                	mv	a1,s1
ffffffffc0201bd4:	02000513          	li	a0,32
ffffffffc0201bd8:	9902                	jalr	s2
ffffffffc0201bda:	fe0d9be3          	bnez	s11,ffffffffc0201bd0 <vprintfmt+0x236>
ffffffffc0201bde:	6a02                	ld	s4,0(sp)
ffffffffc0201be0:	bbd5                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201be2:	4705                	li	a4,1
ffffffffc0201be4:	008a0c93          	addi	s9,s4,8
ffffffffc0201be8:	01174463          	blt	a4,a7,ffffffffc0201bf0 <vprintfmt+0x256>
ffffffffc0201bec:	08088d63          	beqz	a7,ffffffffc0201c86 <vprintfmt+0x2ec>
ffffffffc0201bf0:	000a3403          	ld	s0,0(s4)
ffffffffc0201bf4:	0a044d63          	bltz	s0,ffffffffc0201cae <vprintfmt+0x314>
ffffffffc0201bf8:	8622                	mv	a2,s0
ffffffffc0201bfa:	8a66                	mv	s4,s9
ffffffffc0201bfc:	46a9                	li	a3,10
ffffffffc0201bfe:	bdcd                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201c00:	000a2783          	lw	a5,0(s4)
ffffffffc0201c04:	4719                	li	a4,6
ffffffffc0201c06:	0a21                	addi	s4,s4,8
ffffffffc0201c08:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c0c:	8fb5                	xor	a5,a5,a3
ffffffffc0201c0e:	40d786bb          	subw	a3,a5,a3
ffffffffc0201c12:	02d74163          	blt	a4,a3,ffffffffc0201c34 <vprintfmt+0x29a>
ffffffffc0201c16:	00369793          	slli	a5,a3,0x3
ffffffffc0201c1a:	97de                	add	a5,a5,s7
ffffffffc0201c1c:	639c                	ld	a5,0(a5)
ffffffffc0201c1e:	cb99                	beqz	a5,ffffffffc0201c34 <vprintfmt+0x29a>
ffffffffc0201c20:	86be                	mv	a3,a5
ffffffffc0201c22:	00001617          	auipc	a2,0x1
ffffffffc0201c26:	05e60613          	addi	a2,a2,94 # ffffffffc0202c80 <etext+0xda4>
ffffffffc0201c2a:	85a6                	mv	a1,s1
ffffffffc0201c2c:	854a                	mv	a0,s2
ffffffffc0201c2e:	0ce000ef          	jal	ffffffffc0201cfc <printfmt>
ffffffffc0201c32:	b34d                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201c34:	00001617          	auipc	a2,0x1
ffffffffc0201c38:	03c60613          	addi	a2,a2,60 # ffffffffc0202c70 <etext+0xd94>
ffffffffc0201c3c:	85a6                	mv	a1,s1
ffffffffc0201c3e:	854a                	mv	a0,s2
ffffffffc0201c40:	0bc000ef          	jal	ffffffffc0201cfc <printfmt>
ffffffffc0201c44:	bb41                	j	ffffffffc02019d4 <vprintfmt+0x3a>
ffffffffc0201c46:	00001417          	auipc	s0,0x1
ffffffffc0201c4a:	02240413          	addi	s0,s0,34 # ffffffffc0202c68 <etext+0xd8c>
ffffffffc0201c4e:	85e2                	mv	a1,s8
ffffffffc0201c50:	8522                	mv	a0,s0
ffffffffc0201c52:	e43e                	sd	a5,8(sp)
ffffffffc0201c54:	200000ef          	jal	ffffffffc0201e54 <strnlen>
ffffffffc0201c58:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c5c:	01b05b63          	blez	s11,ffffffffc0201c72 <vprintfmt+0x2d8>
ffffffffc0201c60:	67a2                	ld	a5,8(sp)
ffffffffc0201c62:	00078a1b          	sext.w	s4,a5
ffffffffc0201c66:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c68:	85a6                	mv	a1,s1
ffffffffc0201c6a:	8552                	mv	a0,s4
ffffffffc0201c6c:	9902                	jalr	s2
ffffffffc0201c6e:	fe0d9ce3          	bnez	s11,ffffffffc0201c66 <vprintfmt+0x2cc>
ffffffffc0201c72:	00044783          	lbu	a5,0(s0)
ffffffffc0201c76:	00140a13          	addi	s4,s0,1
ffffffffc0201c7a:	0007851b          	sext.w	a0,a5
ffffffffc0201c7e:	d3a5                	beqz	a5,ffffffffc0201bde <vprintfmt+0x244>
ffffffffc0201c80:	05e00413          	li	s0,94
ffffffffc0201c84:	bf39                	j	ffffffffc0201ba2 <vprintfmt+0x208>
ffffffffc0201c86:	000a2403          	lw	s0,0(s4)
ffffffffc0201c8a:	b7ad                	j	ffffffffc0201bf4 <vprintfmt+0x25a>
ffffffffc0201c8c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c90:	46a1                	li	a3,8
ffffffffc0201c92:	8a2e                	mv	s4,a1
ffffffffc0201c94:	bdb1                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201c96:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c9a:	46a9                	li	a3,10
ffffffffc0201c9c:	8a2e                	mv	s4,a1
ffffffffc0201c9e:	bd89                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201ca0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ca4:	46c1                	li	a3,16
ffffffffc0201ca6:	8a2e                	mv	s4,a1
ffffffffc0201ca8:	b5a1                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201caa:	9902                	jalr	s2
ffffffffc0201cac:	bf09                	j	ffffffffc0201bbe <vprintfmt+0x224>
ffffffffc0201cae:	85a6                	mv	a1,s1
ffffffffc0201cb0:	02d00513          	li	a0,45
ffffffffc0201cb4:	e03e                	sd	a5,0(sp)
ffffffffc0201cb6:	9902                	jalr	s2
ffffffffc0201cb8:	6782                	ld	a5,0(sp)
ffffffffc0201cba:	8a66                	mv	s4,s9
ffffffffc0201cbc:	40800633          	neg	a2,s0
ffffffffc0201cc0:	46a9                	li	a3,10
ffffffffc0201cc2:	b53d                	j	ffffffffc0201af0 <vprintfmt+0x156>
ffffffffc0201cc4:	03b05163          	blez	s11,ffffffffc0201ce6 <vprintfmt+0x34c>
ffffffffc0201cc8:	02d00693          	li	a3,45
ffffffffc0201ccc:	f6d79de3          	bne	a5,a3,ffffffffc0201c46 <vprintfmt+0x2ac>
ffffffffc0201cd0:	00001417          	auipc	s0,0x1
ffffffffc0201cd4:	f9840413          	addi	s0,s0,-104 # ffffffffc0202c68 <etext+0xd8c>
ffffffffc0201cd8:	02800793          	li	a5,40
ffffffffc0201cdc:	02800513          	li	a0,40
ffffffffc0201ce0:	00140a13          	addi	s4,s0,1
ffffffffc0201ce4:	bd6d                	j	ffffffffc0201b9e <vprintfmt+0x204>
ffffffffc0201ce6:	00001a17          	auipc	s4,0x1
ffffffffc0201cea:	f83a0a13          	addi	s4,s4,-125 # ffffffffc0202c69 <etext+0xd8d>
ffffffffc0201cee:	02800513          	li	a0,40
ffffffffc0201cf2:	02800793          	li	a5,40
ffffffffc0201cf6:	05e00413          	li	s0,94
ffffffffc0201cfa:	b565                	j	ffffffffc0201ba2 <vprintfmt+0x208>

ffffffffc0201cfc <printfmt>:
ffffffffc0201cfc:	715d                	addi	sp,sp,-80
ffffffffc0201cfe:	02810313          	addi	t1,sp,40
ffffffffc0201d02:	f436                	sd	a3,40(sp)
ffffffffc0201d04:	869a                	mv	a3,t1
ffffffffc0201d06:	ec06                	sd	ra,24(sp)
ffffffffc0201d08:	f83a                	sd	a4,48(sp)
ffffffffc0201d0a:	fc3e                	sd	a5,56(sp)
ffffffffc0201d0c:	e0c2                	sd	a6,64(sp)
ffffffffc0201d0e:	e4c6                	sd	a7,72(sp)
ffffffffc0201d10:	e41a                	sd	t1,8(sp)
ffffffffc0201d12:	c89ff0ef          	jal	ffffffffc020199a <vprintfmt>
ffffffffc0201d16:	60e2                	ld	ra,24(sp)
ffffffffc0201d18:	6161                	addi	sp,sp,80
ffffffffc0201d1a:	8082                	ret

ffffffffc0201d1c <readline>:
ffffffffc0201d1c:	715d                	addi	sp,sp,-80
ffffffffc0201d1e:	e486                	sd	ra,72(sp)
ffffffffc0201d20:	e0a6                	sd	s1,64(sp)
ffffffffc0201d22:	fc4a                	sd	s2,56(sp)
ffffffffc0201d24:	f84e                	sd	s3,48(sp)
ffffffffc0201d26:	f452                	sd	s4,40(sp)
ffffffffc0201d28:	f056                	sd	s5,32(sp)
ffffffffc0201d2a:	ec5a                	sd	s6,24(sp)
ffffffffc0201d2c:	e85e                	sd	s7,16(sp)
ffffffffc0201d2e:	c901                	beqz	a0,ffffffffc0201d3e <readline+0x22>
ffffffffc0201d30:	85aa                	mv	a1,a0
ffffffffc0201d32:	00001517          	auipc	a0,0x1
ffffffffc0201d36:	f4e50513          	addi	a0,a0,-178 # ffffffffc0202c80 <etext+0xda4>
ffffffffc0201d3a:	b9efe0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0201d3e:	4481                	li	s1,0
ffffffffc0201d40:	497d                	li	s2,31
ffffffffc0201d42:	49a1                	li	s3,8
ffffffffc0201d44:	4aa9                	li	s5,10
ffffffffc0201d46:	4b35                	li	s6,13
ffffffffc0201d48:	00004b97          	auipc	s7,0x4
ffffffffc0201d4c:	2f8b8b93          	addi	s7,s7,760 # ffffffffc0206040 <buf>
ffffffffc0201d50:	3fe00a13          	li	s4,1022
ffffffffc0201d54:	bfcfe0ef          	jal	ffffffffc0200150 <getchar>
ffffffffc0201d58:	00054a63          	bltz	a0,ffffffffc0201d6c <readline+0x50>
ffffffffc0201d5c:	00a95a63          	bge	s2,a0,ffffffffc0201d70 <readline+0x54>
ffffffffc0201d60:	029a5263          	bge	s4,s1,ffffffffc0201d84 <readline+0x68>
ffffffffc0201d64:	becfe0ef          	jal	ffffffffc0200150 <getchar>
ffffffffc0201d68:	fe055ae3          	bgez	a0,ffffffffc0201d5c <readline+0x40>
ffffffffc0201d6c:	4501                	li	a0,0
ffffffffc0201d6e:	a091                	j	ffffffffc0201db2 <readline+0x96>
ffffffffc0201d70:	03351463          	bne	a0,s3,ffffffffc0201d98 <readline+0x7c>
ffffffffc0201d74:	e8a9                	bnez	s1,ffffffffc0201dc6 <readline+0xaa>
ffffffffc0201d76:	bdafe0ef          	jal	ffffffffc0200150 <getchar>
ffffffffc0201d7a:	fe0549e3          	bltz	a0,ffffffffc0201d6c <readline+0x50>
ffffffffc0201d7e:	fea959e3          	bge	s2,a0,ffffffffc0201d70 <readline+0x54>
ffffffffc0201d82:	4481                	li	s1,0
ffffffffc0201d84:	e42a                	sd	a0,8(sp)
ffffffffc0201d86:	b88fe0ef          	jal	ffffffffc020010e <cputchar>
ffffffffc0201d8a:	6522                	ld	a0,8(sp)
ffffffffc0201d8c:	009b87b3          	add	a5,s7,s1
ffffffffc0201d90:	2485                	addiw	s1,s1,1
ffffffffc0201d92:	00a78023          	sb	a0,0(a5)
ffffffffc0201d96:	bf7d                	j	ffffffffc0201d54 <readline+0x38>
ffffffffc0201d98:	01550463          	beq	a0,s5,ffffffffc0201da0 <readline+0x84>
ffffffffc0201d9c:	fb651ce3          	bne	a0,s6,ffffffffc0201d54 <readline+0x38>
ffffffffc0201da0:	b6efe0ef          	jal	ffffffffc020010e <cputchar>
ffffffffc0201da4:	00004517          	auipc	a0,0x4
ffffffffc0201da8:	29c50513          	addi	a0,a0,668 # ffffffffc0206040 <buf>
ffffffffc0201dac:	94aa                	add	s1,s1,a0
ffffffffc0201dae:	00048023          	sb	zero,0(s1)
ffffffffc0201db2:	60a6                	ld	ra,72(sp)
ffffffffc0201db4:	6486                	ld	s1,64(sp)
ffffffffc0201db6:	7962                	ld	s2,56(sp)
ffffffffc0201db8:	79c2                	ld	s3,48(sp)
ffffffffc0201dba:	7a22                	ld	s4,40(sp)
ffffffffc0201dbc:	7a82                	ld	s5,32(sp)
ffffffffc0201dbe:	6b62                	ld	s6,24(sp)
ffffffffc0201dc0:	6bc2                	ld	s7,16(sp)
ffffffffc0201dc2:	6161                	addi	sp,sp,80
ffffffffc0201dc4:	8082                	ret
ffffffffc0201dc6:	4521                	li	a0,8
ffffffffc0201dc8:	b46fe0ef          	jal	ffffffffc020010e <cputchar>
ffffffffc0201dcc:	34fd                	addiw	s1,s1,-1
ffffffffc0201dce:	b759                	j	ffffffffc0201d54 <readline+0x38>

ffffffffc0201dd0 <sbi_console_putchar>:
ffffffffc0201dd0:	4781                	li	a5,0
ffffffffc0201dd2:	00004717          	auipc	a4,0x4
ffffffffc0201dd6:	24673703          	ld	a4,582(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dda:	88ba                	mv	a7,a4
ffffffffc0201ddc:	852a                	mv	a0,a0
ffffffffc0201dde:	85be                	mv	a1,a5
ffffffffc0201de0:	863e                	mv	a2,a5
ffffffffc0201de2:	00000073          	ecall
ffffffffc0201de6:	87aa                	mv	a5,a0
ffffffffc0201de8:	8082                	ret

ffffffffc0201dea <sbi_set_timer>:
ffffffffc0201dea:	4781                	li	a5,0
ffffffffc0201dec:	00004717          	auipc	a4,0x4
ffffffffc0201df0:	6ac73703          	ld	a4,1708(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201df4:	88ba                	mv	a7,a4
ffffffffc0201df6:	852a                	mv	a0,a0
ffffffffc0201df8:	85be                	mv	a1,a5
ffffffffc0201dfa:	863e                	mv	a2,a5
ffffffffc0201dfc:	00000073          	ecall
ffffffffc0201e00:	87aa                	mv	a5,a0
ffffffffc0201e02:	8082                	ret

ffffffffc0201e04 <sbi_console_getchar>:
ffffffffc0201e04:	4501                	li	a0,0
ffffffffc0201e06:	00004797          	auipc	a5,0x4
ffffffffc0201e0a:	20a7b783          	ld	a5,522(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e0e:	88be                	mv	a7,a5
ffffffffc0201e10:	852a                	mv	a0,a0
ffffffffc0201e12:	85aa                	mv	a1,a0
ffffffffc0201e14:	862a                	mv	a2,a0
ffffffffc0201e16:	00000073          	ecall
ffffffffc0201e1a:	852a                	mv	a0,a0
ffffffffc0201e1c:	2501                	sext.w	a0,a0
ffffffffc0201e1e:	8082                	ret

ffffffffc0201e20 <sbi_shutdown>:
ffffffffc0201e20:	4781                	li	a5,0
ffffffffc0201e22:	00004717          	auipc	a4,0x4
ffffffffc0201e26:	1fe73703          	ld	a4,510(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e2a:	88ba                	mv	a7,a4
ffffffffc0201e2c:	853e                	mv	a0,a5
ffffffffc0201e2e:	85be                	mv	a1,a5
ffffffffc0201e30:	863e                	mv	a2,a5
ffffffffc0201e32:	00000073          	ecall
ffffffffc0201e36:	87aa                	mv	a5,a0
ffffffffc0201e38:	8082                	ret

ffffffffc0201e3a <strlen>:
ffffffffc0201e3a:	00054783          	lbu	a5,0(a0)
ffffffffc0201e3e:	872a                	mv	a4,a0
ffffffffc0201e40:	4501                	li	a0,0
ffffffffc0201e42:	cb81                	beqz	a5,ffffffffc0201e52 <strlen+0x18>
ffffffffc0201e44:	0505                	addi	a0,a0,1
ffffffffc0201e46:	00a707b3          	add	a5,a4,a0
ffffffffc0201e4a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e4e:	fbfd                	bnez	a5,ffffffffc0201e44 <strlen+0xa>
ffffffffc0201e50:	8082                	ret
ffffffffc0201e52:	8082                	ret

ffffffffc0201e54 <strnlen>:
ffffffffc0201e54:	4781                	li	a5,0
ffffffffc0201e56:	e589                	bnez	a1,ffffffffc0201e60 <strnlen+0xc>
ffffffffc0201e58:	a811                	j	ffffffffc0201e6c <strnlen+0x18>
ffffffffc0201e5a:	0785                	addi	a5,a5,1
ffffffffc0201e5c:	00f58863          	beq	a1,a5,ffffffffc0201e6c <strnlen+0x18>
ffffffffc0201e60:	00f50733          	add	a4,a0,a5
ffffffffc0201e64:	00074703          	lbu	a4,0(a4)
ffffffffc0201e68:	fb6d                	bnez	a4,ffffffffc0201e5a <strnlen+0x6>
ffffffffc0201e6a:	85be                	mv	a1,a5
ffffffffc0201e6c:	852e                	mv	a0,a1
ffffffffc0201e6e:	8082                	ret

ffffffffc0201e70 <strcmp>:
ffffffffc0201e70:	00054783          	lbu	a5,0(a0)
ffffffffc0201e74:	0005c703          	lbu	a4,0(a1)
ffffffffc0201e78:	cb89                	beqz	a5,ffffffffc0201e8a <strcmp+0x1a>
ffffffffc0201e7a:	0505                	addi	a0,a0,1
ffffffffc0201e7c:	0585                	addi	a1,a1,1
ffffffffc0201e7e:	fee789e3          	beq	a5,a4,ffffffffc0201e70 <strcmp>
ffffffffc0201e82:	0007851b          	sext.w	a0,a5
ffffffffc0201e86:	9d19                	subw	a0,a0,a4
ffffffffc0201e88:	8082                	ret
ffffffffc0201e8a:	4501                	li	a0,0
ffffffffc0201e8c:	bfed                	j	ffffffffc0201e86 <strcmp+0x16>

ffffffffc0201e8e <strncmp>:
ffffffffc0201e8e:	c20d                	beqz	a2,ffffffffc0201eb0 <strncmp+0x22>
ffffffffc0201e90:	962e                	add	a2,a2,a1
ffffffffc0201e92:	a031                	j	ffffffffc0201e9e <strncmp+0x10>
ffffffffc0201e94:	0505                	addi	a0,a0,1
ffffffffc0201e96:	00e79a63          	bne	a5,a4,ffffffffc0201eaa <strncmp+0x1c>
ffffffffc0201e9a:	00b60b63          	beq	a2,a1,ffffffffc0201eb0 <strncmp+0x22>
ffffffffc0201e9e:	00054783          	lbu	a5,0(a0)
ffffffffc0201ea2:	0585                	addi	a1,a1,1
ffffffffc0201ea4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201ea8:	f7f5                	bnez	a5,ffffffffc0201e94 <strncmp+0x6>
ffffffffc0201eaa:	40e7853b          	subw	a0,a5,a4
ffffffffc0201eae:	8082                	ret
ffffffffc0201eb0:	4501                	li	a0,0
ffffffffc0201eb2:	8082                	ret

ffffffffc0201eb4 <strchr>:
ffffffffc0201eb4:	00054783          	lbu	a5,0(a0)
ffffffffc0201eb8:	c799                	beqz	a5,ffffffffc0201ec6 <strchr+0x12>
ffffffffc0201eba:	00f58763          	beq	a1,a5,ffffffffc0201ec8 <strchr+0x14>
ffffffffc0201ebe:	00154783          	lbu	a5,1(a0)
ffffffffc0201ec2:	0505                	addi	a0,a0,1
ffffffffc0201ec4:	fbfd                	bnez	a5,ffffffffc0201eba <strchr+0x6>
ffffffffc0201ec6:	4501                	li	a0,0
ffffffffc0201ec8:	8082                	ret

ffffffffc0201eca <memset>:
ffffffffc0201eca:	ca01                	beqz	a2,ffffffffc0201eda <memset+0x10>
ffffffffc0201ecc:	962a                	add	a2,a2,a0
ffffffffc0201ece:	87aa                	mv	a5,a0
ffffffffc0201ed0:	0785                	addi	a5,a5,1
ffffffffc0201ed2:	feb78fa3          	sb	a1,-1(a5)
ffffffffc0201ed6:	fec79de3          	bne	a5,a2,ffffffffc0201ed0 <memset+0x6>
ffffffffc0201eda:	8082                	ret
