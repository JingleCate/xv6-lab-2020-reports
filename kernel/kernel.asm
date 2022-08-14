
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0ac78793          	addi	a5,a5,172 # 80006110 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffba7d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	1d878793          	addi	a5,a5,472 # 80001286 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	be0080e7          	jalr	-1056(ra) # 80000cf4 <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	6d6080e7          	jalr	1750(ra) # 80002804 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	c6e080e7          	jalr	-914(ra) # 80000dc4 <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	b4e080e7          	jalr	-1202(ra) # 80000cf4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	b66080e7          	jalr	-1178(ra) # 80001d3c <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	366080e7          	jalr	870(ra) # 8000254c <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	58c080e7          	jalr	1420(ra) # 800027ae <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	b86080e7          	jalr	-1146(ra) # 80000dc4 <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	b70080e7          	jalr	-1168(ra) # 80000dc4 <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a0e080e7          	jalr	-1522(ra) # 80000cf4 <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	556080e7          	jalr	1366(ra) # 8000285a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	ab0080e7          	jalr	-1360(ra) # 80000dc4 <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	27a080e7          	jalr	634(ra) # 800026d2 <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	9f6080e7          	jalr	-1546(ra) # 80000e70 <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	0003e797          	auipc	a5,0x3e
    8000048e:	3ce78793          	addi	a5,a5,974 # 8003e858 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	be250513          	addi	a0,a0,-1054 # 80008160 <digits+0x120>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	6e2080e7          	jalr	1762(ra) # 80000cf4 <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	64e080e7          	jalr	1614(ra) # 80000dc4 <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	6d4080e7          	jalr	1748(ra) # 80000e70 <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	67e080e7          	jalr	1662(ra) # 80000e70 <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	49a080e7          	jalr	1178(ra) # 80000ca8 <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	524080e7          	jalr	1316(ra) # 80000d64 <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e14080e7          	jalr	-492(ra) # 800026d2 <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	3f2080e7          	jalr	1010(ra) # 80000cf4 <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	bf4080e7          	jalr	-1036(ra) # 8000254c <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	428080e7          	jalr	1064(ra) # 80000dc4 <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	2ec080e7          	jalr	748(ra) # 80000cf4 <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	3aa080e7          	jalr	938(ra) # 80000dc4 <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3c1                	bnez	a5,80000ac2 <kfree+0x96>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	00043797          	auipc	a5,0x43
    80000a4a:	5e278793          	addi	a5,a5,1506 # 80044028 <end>
    80000a4e:	06f56a63          	bltu	a0,a5,80000ac2 <kfree+0x96>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57663          	bgeu	a0,a5,80000ac2 <kfree+0x96>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	676080e7          	jalr	1654(ra) # 800010d4 <memset>

  r = (struct run*)pa;

  push_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	242080e7          	jalr	578(ra) # 80000ca8 <push_off>
  int ncpu = cpuid();
    80000a6e:	00001097          	auipc	ra,0x1
    80000a72:	2a2080e7          	jalr	674(ra) # 80001d10 <cpuid>

  acquire(&kmem[ncpu].lock);
    80000a76:	00011a97          	auipc	s5,0x11
    80000a7a:	812a8a93          	addi	s5,s5,-2030 # 80011288 <kmem>
    80000a7e:	00251993          	slli	s3,a0,0x2
    80000a82:	00a98933          	add	s2,s3,a0
    80000a86:	090e                	slli	s2,s2,0x3
    80000a88:	9956                	add	s2,s2,s5
    80000a8a:	854a                	mv	a0,s2
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	268080e7          	jalr	616(ra) # 80000cf4 <acquire>
  r->next = kmem[ncpu].freelist;
    80000a94:	02093783          	ld	a5,32(s2)
    80000a98:	e09c                	sd	a5,0(s1)
  kmem[ncpu].freelist = r;
    80000a9a:	02993023          	sd	s1,32(s2)
  release(&kmem[ncpu].lock);
    80000a9e:	854a                	mv	a0,s2
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	324080e7          	jalr	804(ra) # 80000dc4 <release>
  pop_off();
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	2bc080e7          	jalr	700(ra) # 80000d64 <pop_off>
}
    80000ab0:	70e2                	ld	ra,56(sp)
    80000ab2:	7442                	ld	s0,48(sp)
    80000ab4:	74a2                	ld	s1,40(sp)
    80000ab6:	7902                	ld	s2,32(sp)
    80000ab8:	69e2                	ld	s3,24(sp)
    80000aba:	6a42                	ld	s4,16(sp)
    80000abc:	6aa2                	ld	s5,8(sp)
    80000abe:	6121                	addi	sp,sp,64
    80000ac0:	8082                	ret
    panic("kfree");
    80000ac2:	00007517          	auipc	a0,0x7
    80000ac6:	59e50513          	addi	a0,a0,1438 # 80008060 <digits+0x20>
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	a86080e7          	jalr	-1402(ra) # 80000550 <panic>

0000000080000ad2 <freerange>:
{
    80000ad2:	7179                	addi	sp,sp,-48
    80000ad4:	f406                	sd	ra,40(sp)
    80000ad6:	f022                	sd	s0,32(sp)
    80000ad8:	ec26                	sd	s1,24(sp)
    80000ada:	e84a                	sd	s2,16(sp)
    80000adc:	e44e                	sd	s3,8(sp)
    80000ade:	e052                	sd	s4,0(sp)
    80000ae0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae2:	6785                	lui	a5,0x1
    80000ae4:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ae8:	94aa                	add	s1,s1,a0
    80000aea:	757d                	lui	a0,0xfffff
    80000aec:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3a>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f2e080e7          	jalr	-210(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x28>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	7179                	addi	sp,sp,-48
    80000b1e:	f406                	sd	ra,40(sp)
    80000b20:	f022                	sd	s0,32(sp)
    80000b22:	ec26                	sd	s1,24(sp)
    80000b24:	e84a                	sd	s2,16(sp)
    80000b26:	e44e                	sd	s3,8(sp)
    80000b28:	1800                	addi	s0,sp,48
  for (int i = 0; i < NCPU; i++) {
    80000b2a:	00010497          	auipc	s1,0x10
    80000b2e:	75e48493          	addi	s1,s1,1886 # 80011288 <kmem>
    80000b32:	00011997          	auipc	s3,0x11
    80000b36:	89698993          	addi	s3,s3,-1898 # 800113c8 <lock_locks>
    initlock(&kmem[i].lock, "kmem");
    80000b3a:	00007917          	auipc	s2,0x7
    80000b3e:	52e90913          	addi	s2,s2,1326 # 80008068 <digits+0x28>
    80000b42:	85ca                	mv	a1,s2
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	32a080e7          	jalr	810(ra) # 80000e70 <initlock>
  for (int i = 0; i < NCPU; i++) {
    80000b4e:	02848493          	addi	s1,s1,40
    80000b52:	ff3498e3          	bne	s1,s3,80000b42 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b56:	45c5                	li	a1,17
    80000b58:	05ee                	slli	a1,a1,0x1b
    80000b5a:	00043517          	auipc	a0,0x43
    80000b5e:	4ce50513          	addi	a0,a0,1230 # 80044028 <end>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	f70080e7          	jalr	-144(ra) # 80000ad2 <freerange>
}
    80000b6a:	70a2                	ld	ra,40(sp)
    80000b6c:	7402                	ld	s0,32(sp)
    80000b6e:	64e2                	ld	s1,24(sp)
    80000b70:	6942                	ld	s2,16(sp)
    80000b72:	69a2                	ld	s3,8(sp)
    80000b74:	6145                	addi	sp,sp,48
    80000b76:	8082                	ret

0000000080000b78 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b78:	715d                	addi	sp,sp,-80
    80000b7a:	e486                	sd	ra,72(sp)
    80000b7c:	e0a2                	sd	s0,64(sp)
    80000b7e:	fc26                	sd	s1,56(sp)
    80000b80:	f84a                	sd	s2,48(sp)
    80000b82:	f44e                	sd	s3,40(sp)
    80000b84:	f052                	sd	s4,32(sp)
    80000b86:	ec56                	sd	s5,24(sp)
    80000b88:	e85a                	sd	s6,16(sp)
    80000b8a:	e45e                	sd	s7,8(sp)
    80000b8c:	0880                	addi	s0,sp,80
  struct run *r;

  push_off();
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	11a080e7          	jalr	282(ra) # 80000ca8 <push_off>
  int ncpu = cpuid();
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	17a080e7          	jalr	378(ra) # 80001d10 <cpuid>
    80000b9e:	892a                	mv	s2,a0

  acquire(&kmem[ncpu].lock);
    80000ba0:	00251493          	slli	s1,a0,0x2
    80000ba4:	94aa                	add	s1,s1,a0
    80000ba6:	00349793          	slli	a5,s1,0x3
    80000baa:	00010497          	auipc	s1,0x10
    80000bae:	6de48493          	addi	s1,s1,1758 # 80011288 <kmem>
    80000bb2:	94be                	add	s1,s1,a5
    80000bb4:	8526                	mv	a0,s1
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	13e080e7          	jalr	318(ra) # 80000cf4 <acquire>
  r = kmem[ncpu].freelist;
    80000bbe:	0204ba03          	ld	s4,32(s1)
  if(r) {
    80000bc2:	0a0a0063          	beqz	s4,80000c62 <kalloc+0xea>
    kmem[ncpu].freelist = r->next;
    80000bc6:	000a3703          	ld	a4,0(s4) # fffffffffffff000 <end+0xffffffff7ffbafd8>
    80000bca:	f098                	sd	a4,32(s1)
  } 
  release(&kmem[ncpu].lock);
    80000bcc:	8526                	mv	a0,s1
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1f6080e7          	jalr	502(ra) # 80000dc4 <release>
        break;
      }
      release(&kmem[i].lock);
    }
  }
  pop_off();
    80000bd6:	00000097          	auipc	ra,0x0
    80000bda:	18e080e7          	jalr	398(ra) # 80000d64 <pop_off>
  
  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bde:	6605                	lui	a2,0x1
    80000be0:	4595                	li	a1,5
    80000be2:	8552                	mv	a0,s4
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	4f0080e7          	jalr	1264(ra) # 800010d4 <memset>
  return (void*)r;
}
    80000bec:	8552                	mv	a0,s4
    80000bee:	60a6                	ld	ra,72(sp)
    80000bf0:	6406                	ld	s0,64(sp)
    80000bf2:	74e2                	ld	s1,56(sp)
    80000bf4:	7942                	ld	s2,48(sp)
    80000bf6:	79a2                	ld	s3,40(sp)
    80000bf8:	7a02                	ld	s4,32(sp)
    80000bfa:	6ae2                	ld	s5,24(sp)
    80000bfc:	6b42                	ld	s6,16(sp)
    80000bfe:	6ba2                	ld	s7,8(sp)
    80000c00:	6161                	addi	sp,sp,80
    80000c02:	8082                	ret
        kmem[i].freelist = r->next;
    80000c04:	000ab703          	ld	a4,0(s5)
    80000c08:	00299793          	slli	a5,s3,0x2
    80000c0c:	99be                	add	s3,s3,a5
    80000c0e:	098e                	slli	s3,s3,0x3
    80000c10:	00010797          	auipc	a5,0x10
    80000c14:	67878793          	addi	a5,a5,1656 # 80011288 <kmem>
    80000c18:	99be                	add	s3,s3,a5
    80000c1a:	02e9b023          	sd	a4,32(s3)
        release(&kmem[i].lock);
    80000c1e:	8526                	mv	a0,s1
    80000c20:	00000097          	auipc	ra,0x0
    80000c24:	1a4080e7          	jalr	420(ra) # 80000dc4 <release>
      r = kmem[i].freelist;     
    80000c28:	8a56                	mv	s4,s5
        break;
    80000c2a:	b775                	j	80000bd6 <kalloc+0x5e>
    for (int i = 0; i < NCPU; i++) {
    80000c2c:	2985                	addiw	s3,s3,1
    80000c2e:	02848493          	addi	s1,s1,40
    80000c32:	03698363          	beq	s3,s6,80000c58 <kalloc+0xe0>
      if (i == ncpu) continue;
    80000c36:	ff390be3          	beq	s2,s3,80000c2c <kalloc+0xb4>
      acquire(&kmem[i].lock);
    80000c3a:	8526                	mv	a0,s1
    80000c3c:	00000097          	auipc	ra,0x0
    80000c40:	0b8080e7          	jalr	184(ra) # 80000cf4 <acquire>
      r = kmem[i].freelist;     
    80000c44:	0204ba83          	ld	s5,32(s1)
      if (r) {
    80000c48:	fa0a9ee3          	bnez	s5,80000c04 <kalloc+0x8c>
      release(&kmem[i].lock);
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	176080e7          	jalr	374(ra) # 80000dc4 <release>
    80000c56:	bfd9                	j	80000c2c <kalloc+0xb4>
  pop_off();
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	10c080e7          	jalr	268(ra) # 80000d64 <pop_off>
  return (void*)r;
    80000c60:	b771                	j	80000bec <kalloc+0x74>
  release(&kmem[ncpu].lock);
    80000c62:	8526                	mv	a0,s1
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	160080e7          	jalr	352(ra) # 80000dc4 <release>
    for (int i = 0; i < NCPU; i++) {
    80000c6c:	00010497          	auipc	s1,0x10
    80000c70:	61c48493          	addi	s1,s1,1564 # 80011288 <kmem>
    80000c74:	4981                	li	s3,0
    80000c76:	4b21                	li	s6,8
    80000c78:	bf7d                	j	80000c36 <kalloc+0xbe>

0000000080000c7a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c7a:	411c                	lw	a5,0(a0)
    80000c7c:	e399                	bnez	a5,80000c82 <holding+0x8>
    80000c7e:	4501                	li	a0,0
  return r;
}
    80000c80:	8082                	ret
{
    80000c82:	1101                	addi	sp,sp,-32
    80000c84:	ec06                	sd	ra,24(sp)
    80000c86:	e822                	sd	s0,16(sp)
    80000c88:	e426                	sd	s1,8(sp)
    80000c8a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c8c:	6904                	ld	s1,16(a0)
    80000c8e:	00001097          	auipc	ra,0x1
    80000c92:	092080e7          	jalr	146(ra) # 80001d20 <mycpu>
    80000c96:	40a48533          	sub	a0,s1,a0
    80000c9a:	00153513          	seqz	a0,a0
}
    80000c9e:	60e2                	ld	ra,24(sp)
    80000ca0:	6442                	ld	s0,16(sp)
    80000ca2:	64a2                	ld	s1,8(sp)
    80000ca4:	6105                	addi	sp,sp,32
    80000ca6:	8082                	ret

0000000080000ca8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ca8:	1101                	addi	sp,sp,-32
    80000caa:	ec06                	sd	ra,24(sp)
    80000cac:	e822                	sd	s0,16(sp)
    80000cae:	e426                	sd	s1,8(sp)
    80000cb0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb2:	100024f3          	csrr	s1,sstatus
    80000cb6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cbc:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cc0:	00001097          	auipc	ra,0x1
    80000cc4:	060080e7          	jalr	96(ra) # 80001d20 <mycpu>
    80000cc8:	5d3c                	lw	a5,120(a0)
    80000cca:	cf89                	beqz	a5,80000ce4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ccc:	00001097          	auipc	ra,0x1
    80000cd0:	054080e7          	jalr	84(ra) # 80001d20 <mycpu>
    80000cd4:	5d3c                	lw	a5,120(a0)
    80000cd6:	2785                	addiw	a5,a5,1
    80000cd8:	dd3c                	sw	a5,120(a0)
}
    80000cda:	60e2                	ld	ra,24(sp)
    80000cdc:	6442                	ld	s0,16(sp)
    80000cde:	64a2                	ld	s1,8(sp)
    80000ce0:	6105                	addi	sp,sp,32
    80000ce2:	8082                	ret
    mycpu()->intena = old;
    80000ce4:	00001097          	auipc	ra,0x1
    80000ce8:	03c080e7          	jalr	60(ra) # 80001d20 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cec:	8085                	srli	s1,s1,0x1
    80000cee:	8885                	andi	s1,s1,1
    80000cf0:	dd64                	sw	s1,124(a0)
    80000cf2:	bfe9                	j	80000ccc <push_off+0x24>

0000000080000cf4 <acquire>:
{
    80000cf4:	1101                	addi	sp,sp,-32
    80000cf6:	ec06                	sd	ra,24(sp)
    80000cf8:	e822                	sd	s0,16(sp)
    80000cfa:	e426                	sd	s1,8(sp)
    80000cfc:	1000                	addi	s0,sp,32
    80000cfe:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d00:	00000097          	auipc	ra,0x0
    80000d04:	fa8080e7          	jalr	-88(ra) # 80000ca8 <push_off>
  if(holding(lk))
    80000d08:	8526                	mv	a0,s1
    80000d0a:	00000097          	auipc	ra,0x0
    80000d0e:	f70080e7          	jalr	-144(ra) # 80000c7a <holding>
    80000d12:	e911                	bnez	a0,80000d26 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d14:	4785                	li	a5,1
    80000d16:	01c48713          	addi	a4,s1,28
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d22:	4705                	li	a4,1
    80000d24:	a839                	j	80000d42 <acquire+0x4e>
    panic("acquire");
    80000d26:	00007517          	auipc	a0,0x7
    80000d2a:	34a50513          	addi	a0,a0,842 # 80008070 <digits+0x30>
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	822080e7          	jalr	-2014(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d36:	01848793          	addi	a5,s1,24
    80000d3a:	0f50000f          	fence	iorw,ow
    80000d3e:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d42:	87ba                	mv	a5,a4
    80000d44:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d48:	2781                	sext.w	a5,a5
    80000d4a:	f7f5                	bnez	a5,80000d36 <acquire+0x42>
  __sync_synchronize();
    80000d4c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d50:	00001097          	auipc	ra,0x1
    80000d54:	fd0080e7          	jalr	-48(ra) # 80001d20 <mycpu>
    80000d58:	e888                	sd	a0,16(s1)
}
    80000d5a:	60e2                	ld	ra,24(sp)
    80000d5c:	6442                	ld	s0,16(sp)
    80000d5e:	64a2                	ld	s1,8(sp)
    80000d60:	6105                	addi	sp,sp,32
    80000d62:	8082                	ret

0000000080000d64 <pop_off>:

void
pop_off(void)
{
    80000d64:	1141                	addi	sp,sp,-16
    80000d66:	e406                	sd	ra,8(sp)
    80000d68:	e022                	sd	s0,0(sp)
    80000d6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d6c:	00001097          	auipc	ra,0x1
    80000d70:	fb4080e7          	jalr	-76(ra) # 80001d20 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d7a:	e78d                	bnez	a5,80000da4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d7c:	5d3c                	lw	a5,120(a0)
    80000d7e:	02f05b63          	blez	a5,80000db4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d82:	37fd                	addiw	a5,a5,-1
    80000d84:	0007871b          	sext.w	a4,a5
    80000d88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d8a:	eb09                	bnez	a4,80000d9c <pop_off+0x38>
    80000d8c:	5d7c                	lw	a5,124(a0)
    80000d8e:	c799                	beqz	a5,80000d9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d9c:	60a2                	ld	ra,8(sp)
    80000d9e:	6402                	ld	s0,0(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret
    panic("pop_off - interruptible");
    80000da4:	00007517          	auipc	a0,0x7
    80000da8:	2d450513          	addi	a0,a0,724 # 80008078 <digits+0x38>
    80000dac:	fffff097          	auipc	ra,0xfffff
    80000db0:	7a4080e7          	jalr	1956(ra) # 80000550 <panic>
    panic("pop_off");
    80000db4:	00007517          	auipc	a0,0x7
    80000db8:	2dc50513          	addi	a0,a0,732 # 80008090 <digits+0x50>
    80000dbc:	fffff097          	auipc	ra,0xfffff
    80000dc0:	794080e7          	jalr	1940(ra) # 80000550 <panic>

0000000080000dc4 <release>:
{
    80000dc4:	1101                	addi	sp,sp,-32
    80000dc6:	ec06                	sd	ra,24(sp)
    80000dc8:	e822                	sd	s0,16(sp)
    80000dca:	e426                	sd	s1,8(sp)
    80000dcc:	1000                	addi	s0,sp,32
    80000dce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dd0:	00000097          	auipc	ra,0x0
    80000dd4:	eaa080e7          	jalr	-342(ra) # 80000c7a <holding>
    80000dd8:	c115                	beqz	a0,80000dfc <release+0x38>
  lk->cpu = 0;
    80000dda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de2:	0f50000f          	fence	iorw,ow
    80000de6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dea:	00000097          	auipc	ra,0x0
    80000dee:	f7a080e7          	jalr	-134(ra) # 80000d64 <pop_off>
}
    80000df2:	60e2                	ld	ra,24(sp)
    80000df4:	6442                	ld	s0,16(sp)
    80000df6:	64a2                	ld	s1,8(sp)
    80000df8:	6105                	addi	sp,sp,32
    80000dfa:	8082                	ret
    panic("release");
    80000dfc:	00007517          	auipc	a0,0x7
    80000e00:	29c50513          	addi	a0,a0,668 # 80008098 <digits+0x58>
    80000e04:	fffff097          	auipc	ra,0xfffff
    80000e08:	74c080e7          	jalr	1868(ra) # 80000550 <panic>

0000000080000e0c <freelock>:
{
    80000e0c:	1101                	addi	sp,sp,-32
    80000e0e:	ec06                	sd	ra,24(sp)
    80000e10:	e822                	sd	s0,16(sp)
    80000e12:	e426                	sd	s1,8(sp)
    80000e14:	1000                	addi	s0,sp,32
    80000e16:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e18:	00010517          	auipc	a0,0x10
    80000e1c:	5b050513          	addi	a0,a0,1456 # 800113c8 <lock_locks>
    80000e20:	00000097          	auipc	ra,0x0
    80000e24:	ed4080e7          	jalr	-300(ra) # 80000cf4 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e28:	00010717          	auipc	a4,0x10
    80000e2c:	5c070713          	addi	a4,a4,1472 # 800113e8 <locks>
    80000e30:	4781                	li	a5,0
    80000e32:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e36:	6314                	ld	a3,0(a4)
    80000e38:	00968763          	beq	a3,s1,80000e46 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e3c:	2785                	addiw	a5,a5,1
    80000e3e:	0721                	addi	a4,a4,8
    80000e40:	fec79be3          	bne	a5,a2,80000e36 <freelock+0x2a>
    80000e44:	a809                	j	80000e56 <freelock+0x4a>
      locks[i] = 0;
    80000e46:	078e                	slli	a5,a5,0x3
    80000e48:	00010717          	auipc	a4,0x10
    80000e4c:	5a070713          	addi	a4,a4,1440 # 800113e8 <locks>
    80000e50:	97ba                	add	a5,a5,a4
    80000e52:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e56:	00010517          	auipc	a0,0x10
    80000e5a:	57250513          	addi	a0,a0,1394 # 800113c8 <lock_locks>
    80000e5e:	00000097          	auipc	ra,0x0
    80000e62:	f66080e7          	jalr	-154(ra) # 80000dc4 <release>
}
    80000e66:	60e2                	ld	ra,24(sp)
    80000e68:	6442                	ld	s0,16(sp)
    80000e6a:	64a2                	ld	s1,8(sp)
    80000e6c:	6105                	addi	sp,sp,32
    80000e6e:	8082                	ret

0000000080000e70 <initlock>:
{
    80000e70:	1101                	addi	sp,sp,-32
    80000e72:	ec06                	sd	ra,24(sp)
    80000e74:	e822                	sd	s0,16(sp)
    80000e76:	e426                	sd	s1,8(sp)
    80000e78:	1000                	addi	s0,sp,32
    80000e7a:	84aa                	mv	s1,a0
  lk->name = name;
    80000e7c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e7e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e82:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e86:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e8a:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e8e:	00010517          	auipc	a0,0x10
    80000e92:	53a50513          	addi	a0,a0,1338 # 800113c8 <lock_locks>
    80000e96:	00000097          	auipc	ra,0x0
    80000e9a:	e5e080e7          	jalr	-418(ra) # 80000cf4 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e9e:	00010717          	auipc	a4,0x10
    80000ea2:	54a70713          	addi	a4,a4,1354 # 800113e8 <locks>
    80000ea6:	4781                	li	a5,0
    80000ea8:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000eac:	6310                	ld	a2,0(a4)
    80000eae:	ce09                	beqz	a2,80000ec8 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000eb0:	2785                	addiw	a5,a5,1
    80000eb2:	0721                	addi	a4,a4,8
    80000eb4:	fed79ce3          	bne	a5,a3,80000eac <initlock+0x3c>
  panic("findslot");
    80000eb8:	00007517          	auipc	a0,0x7
    80000ebc:	1e850513          	addi	a0,a0,488 # 800080a0 <digits+0x60>
    80000ec0:	fffff097          	auipc	ra,0xfffff
    80000ec4:	690080e7          	jalr	1680(ra) # 80000550 <panic>
      locks[i] = lk;
    80000ec8:	078e                	slli	a5,a5,0x3
    80000eca:	00010717          	auipc	a4,0x10
    80000ece:	51e70713          	addi	a4,a4,1310 # 800113e8 <locks>
    80000ed2:	97ba                	add	a5,a5,a4
    80000ed4:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000ed6:	00010517          	auipc	a0,0x10
    80000eda:	4f250513          	addi	a0,a0,1266 # 800113c8 <lock_locks>
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	ee6080e7          	jalr	-282(ra) # 80000dc4 <release>
}
    80000ee6:	60e2                	ld	ra,24(sp)
    80000ee8:	6442                	ld	s0,16(sp)
    80000eea:	64a2                	ld	s1,8(sp)
    80000eec:	6105                	addi	sp,sp,32
    80000eee:	8082                	ret

0000000080000ef0 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000ef0:	4e5c                	lw	a5,28(a2)
    80000ef2:	00f04463          	bgtz	a5,80000efa <snprint_lock+0xa>
  int n = 0;
    80000ef6:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ef8:	8082                	ret
{
    80000efa:	1141                	addi	sp,sp,-16
    80000efc:	e406                	sd	ra,8(sp)
    80000efe:	e022                	sd	s0,0(sp)
    80000f00:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f02:	4e18                	lw	a4,24(a2)
    80000f04:	6614                	ld	a3,8(a2)
    80000f06:	00007617          	auipc	a2,0x7
    80000f0a:	1aa60613          	addi	a2,a2,426 # 800080b0 <digits+0x70>
    80000f0e:	00006097          	auipc	ra,0x6
    80000f12:	a04080e7          	jalr	-1532(ra) # 80006912 <snprintf>
}
    80000f16:	60a2                	ld	ra,8(sp)
    80000f18:	6402                	ld	s0,0(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret

0000000080000f1e <statslock>:

int
statslock(char *buf, int sz) {
    80000f1e:	7159                	addi	sp,sp,-112
    80000f20:	f486                	sd	ra,104(sp)
    80000f22:	f0a2                	sd	s0,96(sp)
    80000f24:	eca6                	sd	s1,88(sp)
    80000f26:	e8ca                	sd	s2,80(sp)
    80000f28:	e4ce                	sd	s3,72(sp)
    80000f2a:	e0d2                	sd	s4,64(sp)
    80000f2c:	fc56                	sd	s5,56(sp)
    80000f2e:	f85a                	sd	s6,48(sp)
    80000f30:	f45e                	sd	s7,40(sp)
    80000f32:	f062                	sd	s8,32(sp)
    80000f34:	ec66                	sd	s9,24(sp)
    80000f36:	e86a                	sd	s10,16(sp)
    80000f38:	e46e                	sd	s11,8(sp)
    80000f3a:	1880                	addi	s0,sp,112
    80000f3c:	8aaa                	mv	s5,a0
    80000f3e:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f40:	00010517          	auipc	a0,0x10
    80000f44:	48850513          	addi	a0,a0,1160 # 800113c8 <lock_locks>
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	dac080e7          	jalr	-596(ra) # 80000cf4 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f50:	00007617          	auipc	a2,0x7
    80000f54:	19060613          	addi	a2,a2,400 # 800080e0 <digits+0xa0>
    80000f58:	85da                	mv	a1,s6
    80000f5a:	8556                	mv	a0,s5
    80000f5c:	00006097          	auipc	ra,0x6
    80000f60:	9b6080e7          	jalr	-1610(ra) # 80006912 <snprintf>
    80000f64:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f66:	00010c97          	auipc	s9,0x10
    80000f6a:	482c8c93          	addi	s9,s9,1154 # 800113e8 <locks>
    80000f6e:	00011c17          	auipc	s8,0x11
    80000f72:	41ac0c13          	addi	s8,s8,1050 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f76:	84e6                	mv	s1,s9
  int tot = 0;
    80000f78:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f7a:	00007b97          	auipc	s7,0x7
    80000f7e:	186b8b93          	addi	s7,s7,390 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f82:	00007d17          	auipc	s10,0x7
    80000f86:	0e6d0d13          	addi	s10,s10,230 # 80008068 <digits+0x28>
    80000f8a:	a01d                	j	80000fb0 <statslock+0x92>
      tot += locks[i]->nts;
    80000f8c:	0009b603          	ld	a2,0(s3)
    80000f90:	4e1c                	lw	a5,24(a2)
    80000f92:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f96:	412b05bb          	subw	a1,s6,s2
    80000f9a:	012a8533          	add	a0,s5,s2
    80000f9e:	00000097          	auipc	ra,0x0
    80000fa2:	f52080e7          	jalr	-174(ra) # 80000ef0 <snprint_lock>
    80000fa6:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000faa:	04a1                	addi	s1,s1,8
    80000fac:	05848763          	beq	s1,s8,80000ffa <statslock+0xdc>
    if(locks[i] == 0)
    80000fb0:	89a6                	mv	s3,s1
    80000fb2:	609c                	ld	a5,0(s1)
    80000fb4:	c3b9                	beqz	a5,80000ffa <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fb6:	0087bd83          	ld	s11,8(a5)
    80000fba:	855e                	mv	a0,s7
    80000fbc:	00000097          	auipc	ra,0x0
    80000fc0:	2a0080e7          	jalr	672(ra) # 8000125c <strlen>
    80000fc4:	0005061b          	sext.w	a2,a0
    80000fc8:	85de                	mv	a1,s7
    80000fca:	856e                	mv	a0,s11
    80000fcc:	00000097          	auipc	ra,0x0
    80000fd0:	1e4080e7          	jalr	484(ra) # 800011b0 <strncmp>
    80000fd4:	dd45                	beqz	a0,80000f8c <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fd6:	609c                	ld	a5,0(s1)
    80000fd8:	0087bd83          	ld	s11,8(a5)
    80000fdc:	856a                	mv	a0,s10
    80000fde:	00000097          	auipc	ra,0x0
    80000fe2:	27e080e7          	jalr	638(ra) # 8000125c <strlen>
    80000fe6:	0005061b          	sext.w	a2,a0
    80000fea:	85ea                	mv	a1,s10
    80000fec:	856e                	mv	a0,s11
    80000fee:	00000097          	auipc	ra,0x0
    80000ff2:	1c2080e7          	jalr	450(ra) # 800011b0 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ff6:	f955                	bnez	a0,80000faa <statslock+0x8c>
    80000ff8:	bf51                	j	80000f8c <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000ffa:	00007617          	auipc	a2,0x7
    80000ffe:	10e60613          	addi	a2,a2,270 # 80008108 <digits+0xc8>
    80001002:	412b05bb          	subw	a1,s6,s2
    80001006:	012a8533          	add	a0,s5,s2
    8000100a:	00006097          	auipc	ra,0x6
    8000100e:	908080e7          	jalr	-1784(ra) # 80006912 <snprintf>
    80001012:	012509bb          	addw	s3,a0,s2
    80001016:	4b95                	li	s7,5
  int last = 100000000;
    80001018:	05f5e537          	lui	a0,0x5f5e
    8000101c:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80001020:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001022:	00010497          	auipc	s1,0x10
    80001026:	3c648493          	addi	s1,s1,966 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    8000102a:	1f400913          	li	s2,500
    8000102e:	a881                	j	8000107e <statslock+0x160>
    80001030:	2705                	addiw	a4,a4,1
    80001032:	06a1                	addi	a3,a3,8
    80001034:	03270063          	beq	a4,s2,80001054 <statslock+0x136>
      if(locks[i] == 0)
    80001038:	629c                	ld	a5,0(a3)
    8000103a:	cf89                	beqz	a5,80001054 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000103c:	4f90                	lw	a2,24(a5)
    8000103e:	00359793          	slli	a5,a1,0x3
    80001042:	97a6                	add	a5,a5,s1
    80001044:	639c                	ld	a5,0(a5)
    80001046:	4f9c                	lw	a5,24(a5)
    80001048:	fec7d4e3          	bge	a5,a2,80001030 <statslock+0x112>
    8000104c:	fea652e3          	bge	a2,a0,80001030 <statslock+0x112>
    80001050:	85ba                	mv	a1,a4
    80001052:	bff9                	j	80001030 <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    80001054:	058e                	slli	a1,a1,0x3
    80001056:	00b48d33          	add	s10,s1,a1
    8000105a:	000d3603          	ld	a2,0(s10)
    8000105e:	413b05bb          	subw	a1,s6,s3
    80001062:	013a8533          	add	a0,s5,s3
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	e8a080e7          	jalr	-374(ra) # 80000ef0 <snprint_lock>
    8000106e:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    80001072:	000d3783          	ld	a5,0(s10)
    80001076:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001078:	3bfd                	addiw	s7,s7,-1
    8000107a:	000b8663          	beqz	s7,80001086 <statslock+0x168>
  int tot = 0;
    8000107e:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    80001080:	8762                	mv	a4,s8
    int top = 0;
    80001082:	85e2                	mv	a1,s8
    80001084:	bf55                	j	80001038 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001086:	86d2                	mv	a3,s4
    80001088:	00007617          	auipc	a2,0x7
    8000108c:	0a060613          	addi	a2,a2,160 # 80008128 <digits+0xe8>
    80001090:	413b05bb          	subw	a1,s6,s3
    80001094:	013a8533          	add	a0,s5,s3
    80001098:	00006097          	auipc	ra,0x6
    8000109c:	87a080e7          	jalr	-1926(ra) # 80006912 <snprintf>
    800010a0:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    800010a4:	00010517          	auipc	a0,0x10
    800010a8:	32450513          	addi	a0,a0,804 # 800113c8 <lock_locks>
    800010ac:	00000097          	auipc	ra,0x0
    800010b0:	d18080e7          	jalr	-744(ra) # 80000dc4 <release>
  return n;
}
    800010b4:	854e                	mv	a0,s3
    800010b6:	70a6                	ld	ra,104(sp)
    800010b8:	7406                	ld	s0,96(sp)
    800010ba:	64e6                	ld	s1,88(sp)
    800010bc:	6946                	ld	s2,80(sp)
    800010be:	69a6                	ld	s3,72(sp)
    800010c0:	6a06                	ld	s4,64(sp)
    800010c2:	7ae2                	ld	s5,56(sp)
    800010c4:	7b42                	ld	s6,48(sp)
    800010c6:	7ba2                	ld	s7,40(sp)
    800010c8:	7c02                	ld	s8,32(sp)
    800010ca:	6ce2                	ld	s9,24(sp)
    800010cc:	6d42                	ld	s10,16(sp)
    800010ce:	6da2                	ld	s11,8(sp)
    800010d0:	6165                	addi	sp,sp,112
    800010d2:	8082                	ret

00000000800010d4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010d4:	1141                	addi	sp,sp,-16
    800010d6:	e422                	sd	s0,8(sp)
    800010d8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010da:	ce09                	beqz	a2,800010f4 <memset+0x20>
    800010dc:	87aa                	mv	a5,a0
    800010de:	fff6071b          	addiw	a4,a2,-1
    800010e2:	1702                	slli	a4,a4,0x20
    800010e4:	9301                	srli	a4,a4,0x20
    800010e6:	0705                	addi	a4,a4,1
    800010e8:	972a                	add	a4,a4,a0
    cdst[i] = c;
    800010ea:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010ee:	0785                	addi	a5,a5,1
    800010f0:	fee79de3          	bne	a5,a4,800010ea <memset+0x16>
  }
  return dst;
}
    800010f4:	6422                	ld	s0,8(sp)
    800010f6:	0141                	addi	sp,sp,16
    800010f8:	8082                	ret

00000000800010fa <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010fa:	1141                	addi	sp,sp,-16
    800010fc:	e422                	sd	s0,8(sp)
    800010fe:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80001100:	ca05                	beqz	a2,80001130 <memcmp+0x36>
    80001102:	fff6069b          	addiw	a3,a2,-1
    80001106:	1682                	slli	a3,a3,0x20
    80001108:	9281                	srli	a3,a3,0x20
    8000110a:	0685                	addi	a3,a3,1
    8000110c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    8000110e:	00054783          	lbu	a5,0(a0)
    80001112:	0005c703          	lbu	a4,0(a1)
    80001116:	00e79863          	bne	a5,a4,80001126 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000111a:	0505                	addi	a0,a0,1
    8000111c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    8000111e:	fed518e3          	bne	a0,a3,8000110e <memcmp+0x14>
  }

  return 0;
    80001122:	4501                	li	a0,0
    80001124:	a019                	j	8000112a <memcmp+0x30>
      return *s1 - *s2;
    80001126:	40e7853b          	subw	a0,a5,a4
}
    8000112a:	6422                	ld	s0,8(sp)
    8000112c:	0141                	addi	sp,sp,16
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	bfe5                	j	8000112a <memcmp+0x30>

0000000080001134 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e422                	sd	s0,8(sp)
    80001138:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000113a:	00a5f963          	bgeu	a1,a0,8000114c <memmove+0x18>
    8000113e:	02061713          	slli	a4,a2,0x20
    80001142:	9301                	srli	a4,a4,0x20
    80001144:	00e587b3          	add	a5,a1,a4
    80001148:	02f56563          	bltu	a0,a5,80001172 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    8000114c:	fff6069b          	addiw	a3,a2,-1
    80001150:	ce11                	beqz	a2,8000116c <memmove+0x38>
    80001152:	1682                	slli	a3,a3,0x20
    80001154:	9281                	srli	a3,a3,0x20
    80001156:	0685                	addi	a3,a3,1
    80001158:	96ae                	add	a3,a3,a1
    8000115a:	87aa                	mv	a5,a0
      *d++ = *s++;
    8000115c:	0585                	addi	a1,a1,1
    8000115e:	0785                	addi	a5,a5,1
    80001160:	fff5c703          	lbu	a4,-1(a1)
    80001164:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80001168:	fed59ae3          	bne	a1,a3,8000115c <memmove+0x28>

  return dst;
}
    8000116c:	6422                	ld	s0,8(sp)
    8000116e:	0141                	addi	sp,sp,16
    80001170:	8082                	ret
    d += n;
    80001172:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80001174:	fff6069b          	addiw	a3,a2,-1
    80001178:	da75                	beqz	a2,8000116c <memmove+0x38>
    8000117a:	02069613          	slli	a2,a3,0x20
    8000117e:	9201                	srli	a2,a2,0x20
    80001180:	fff64613          	not	a2,a2
    80001184:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001186:	17fd                	addi	a5,a5,-1
    80001188:	177d                	addi	a4,a4,-1
    8000118a:	0007c683          	lbu	a3,0(a5)
    8000118e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80001192:	fec79ae3          	bne	a5,a2,80001186 <memmove+0x52>
    80001196:	bfd9                	j	8000116c <memmove+0x38>

0000000080001198 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001198:	1141                	addi	sp,sp,-16
    8000119a:	e406                	sd	ra,8(sp)
    8000119c:	e022                	sd	s0,0(sp)
    8000119e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800011a0:	00000097          	auipc	ra,0x0
    800011a4:	f94080e7          	jalr	-108(ra) # 80001134 <memmove>
}
    800011a8:	60a2                	ld	ra,8(sp)
    800011aa:	6402                	ld	s0,0(sp)
    800011ac:	0141                	addi	sp,sp,16
    800011ae:	8082                	ret

00000000800011b0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011b0:	1141                	addi	sp,sp,-16
    800011b2:	e422                	sd	s0,8(sp)
    800011b4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011b6:	ce11                	beqz	a2,800011d2 <strncmp+0x22>
    800011b8:	00054783          	lbu	a5,0(a0)
    800011bc:	cf89                	beqz	a5,800011d6 <strncmp+0x26>
    800011be:	0005c703          	lbu	a4,0(a1)
    800011c2:	00f71a63          	bne	a4,a5,800011d6 <strncmp+0x26>
    n--, p++, q++;
    800011c6:	367d                	addiw	a2,a2,-1
    800011c8:	0505                	addi	a0,a0,1
    800011ca:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011cc:	f675                	bnez	a2,800011b8 <strncmp+0x8>
  if(n == 0)
    return 0;
    800011ce:	4501                	li	a0,0
    800011d0:	a809                	j	800011e2 <strncmp+0x32>
    800011d2:	4501                	li	a0,0
    800011d4:	a039                	j	800011e2 <strncmp+0x32>
  if(n == 0)
    800011d6:	ca09                	beqz	a2,800011e8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011d8:	00054503          	lbu	a0,0(a0)
    800011dc:	0005c783          	lbu	a5,0(a1)
    800011e0:	9d1d                	subw	a0,a0,a5
}
    800011e2:	6422                	ld	s0,8(sp)
    800011e4:	0141                	addi	sp,sp,16
    800011e6:	8082                	ret
    return 0;
    800011e8:	4501                	li	a0,0
    800011ea:	bfe5                	j	800011e2 <strncmp+0x32>

00000000800011ec <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011ec:	1141                	addi	sp,sp,-16
    800011ee:	e422                	sd	s0,8(sp)
    800011f0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011f2:	872a                	mv	a4,a0
    800011f4:	8832                	mv	a6,a2
    800011f6:	367d                	addiw	a2,a2,-1
    800011f8:	01005963          	blez	a6,8000120a <strncpy+0x1e>
    800011fc:	0705                	addi	a4,a4,1
    800011fe:	0005c783          	lbu	a5,0(a1)
    80001202:	fef70fa3          	sb	a5,-1(a4)
    80001206:	0585                	addi	a1,a1,1
    80001208:	f7f5                	bnez	a5,800011f4 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000120a:	00c05d63          	blez	a2,80001224 <strncpy+0x38>
    8000120e:	86ba                	mv	a3,a4
    *s++ = 0;
    80001210:	0685                	addi	a3,a3,1
    80001212:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001216:	fff6c793          	not	a5,a3
    8000121a:	9fb9                	addw	a5,a5,a4
    8000121c:	010787bb          	addw	a5,a5,a6
    80001220:	fef048e3          	bgtz	a5,80001210 <strncpy+0x24>
  return os;
}
    80001224:	6422                	ld	s0,8(sp)
    80001226:	0141                	addi	sp,sp,16
    80001228:	8082                	ret

000000008000122a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000122a:	1141                	addi	sp,sp,-16
    8000122c:	e422                	sd	s0,8(sp)
    8000122e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001230:	02c05363          	blez	a2,80001256 <safestrcpy+0x2c>
    80001234:	fff6069b          	addiw	a3,a2,-1
    80001238:	1682                	slli	a3,a3,0x20
    8000123a:	9281                	srli	a3,a3,0x20
    8000123c:	96ae                	add	a3,a3,a1
    8000123e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001240:	00d58963          	beq	a1,a3,80001252 <safestrcpy+0x28>
    80001244:	0585                	addi	a1,a1,1
    80001246:	0785                	addi	a5,a5,1
    80001248:	fff5c703          	lbu	a4,-1(a1)
    8000124c:	fee78fa3          	sb	a4,-1(a5)
    80001250:	fb65                	bnez	a4,80001240 <safestrcpy+0x16>
    ;
  *s = 0;
    80001252:	00078023          	sb	zero,0(a5)
  return os;
}
    80001256:	6422                	ld	s0,8(sp)
    80001258:	0141                	addi	sp,sp,16
    8000125a:	8082                	ret

000000008000125c <strlen>:

int
strlen(const char *s)
{
    8000125c:	1141                	addi	sp,sp,-16
    8000125e:	e422                	sd	s0,8(sp)
    80001260:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001262:	00054783          	lbu	a5,0(a0)
    80001266:	cf91                	beqz	a5,80001282 <strlen+0x26>
    80001268:	0505                	addi	a0,a0,1
    8000126a:	87aa                	mv	a5,a0
    8000126c:	4685                	li	a3,1
    8000126e:	9e89                	subw	a3,a3,a0
    80001270:	00f6853b          	addw	a0,a3,a5
    80001274:	0785                	addi	a5,a5,1
    80001276:	fff7c703          	lbu	a4,-1(a5)
    8000127a:	fb7d                	bnez	a4,80001270 <strlen+0x14>
    ;
  return n;
}
    8000127c:	6422                	ld	s0,8(sp)
    8000127e:	0141                	addi	sp,sp,16
    80001280:	8082                	ret
  for(n = 0; s[n]; n++)
    80001282:	4501                	li	a0,0
    80001284:	bfe5                	j	8000127c <strlen+0x20>

0000000080001286 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001286:	1141                	addi	sp,sp,-16
    80001288:	e406                	sd	ra,8(sp)
    8000128a:	e022                	sd	s0,0(sp)
    8000128c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000128e:	00001097          	auipc	ra,0x1
    80001292:	a82080e7          	jalr	-1406(ra) # 80001d10 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001296:	00008717          	auipc	a4,0x8
    8000129a:	d7670713          	addi	a4,a4,-650 # 8000900c <started>
  if(cpuid() == 0){
    8000129e:	c139                	beqz	a0,800012e4 <main+0x5e>
    while(started == 0)
    800012a0:	431c                	lw	a5,0(a4)
    800012a2:	2781                	sext.w	a5,a5
    800012a4:	dff5                	beqz	a5,800012a0 <main+0x1a>
      ;
    __sync_synchronize();
    800012a6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800012aa:	00001097          	auipc	ra,0x1
    800012ae:	a66080e7          	jalr	-1434(ra) # 80001d10 <cpuid>
    800012b2:	85aa                	mv	a1,a0
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e9c50513          	addi	a0,a0,-356 # 80008150 <digits+0x110>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	2de080e7          	jalr	734(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	186080e7          	jalr	390(ra) # 8000144a <kvminithart>
    trapinithart();   // install kernel trap vector
    800012cc:	00001097          	auipc	ra,0x1
    800012d0:	6ce080e7          	jalr	1742(ra) # 8000299a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012d4:	00005097          	auipc	ra,0x5
    800012d8:	e7c080e7          	jalr	-388(ra) # 80006150 <plicinithart>
  }

  scheduler();        
    800012dc:	00001097          	auipc	ra,0x1
    800012e0:	f90080e7          	jalr	-112(ra) # 8000226c <scheduler>
    consoleinit();
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	17e080e7          	jalr	382(ra) # 80000462 <consoleinit>
    statsinit();
    800012ec:	00005097          	auipc	ra,0x5
    800012f0:	54a080e7          	jalr	1354(ra) # 80006836 <statsinit>
    printfinit();
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	48c080e7          	jalr	1164(ra) # 80000780 <printfinit>
    printf("\n");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e6450513          	addi	a0,a0,-412 # 80008160 <digits+0x120>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	296080e7          	jalr	662(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    8000130c:	00007517          	auipc	a0,0x7
    80001310:	e2c50513          	addi	a0,a0,-468 # 80008138 <digits+0xf8>
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	286080e7          	jalr	646(ra) # 8000059a <printf>
    printf("\n");
    8000131c:	00007517          	auipc	a0,0x7
    80001320:	e4450513          	addi	a0,a0,-444 # 80008160 <digits+0x120>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	276080e7          	jalr	630(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7f0080e7          	jalr	2032(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80001334:	00000097          	auipc	ra,0x0
    80001338:	242080e7          	jalr	578(ra) # 80001576 <kvminit>
    kvminithart();   // turn on paging
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	10e080e7          	jalr	270(ra) # 8000144a <kvminithart>
    procinit();      // process table
    80001344:	00001097          	auipc	ra,0x1
    80001348:	8fc080e7          	jalr	-1796(ra) # 80001c40 <procinit>
    trapinit();      // trap vectors
    8000134c:	00001097          	auipc	ra,0x1
    80001350:	626080e7          	jalr	1574(ra) # 80002972 <trapinit>
    trapinithart();  // install kernel trap vector
    80001354:	00001097          	auipc	ra,0x1
    80001358:	646080e7          	jalr	1606(ra) # 8000299a <trapinithart>
    plicinit();      // set up interrupt controller
    8000135c:	00005097          	auipc	ra,0x5
    80001360:	dde080e7          	jalr	-546(ra) # 8000613a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001364:	00005097          	auipc	ra,0x5
    80001368:	dec080e7          	jalr	-532(ra) # 80006150 <plicinithart>
    binit();         // buffer cache
    8000136c:	00002097          	auipc	ra,0x2
    80001370:	dc0080e7          	jalr	-576(ra) # 8000312c <binit>
    iinit();         // inode cache
    80001374:	00002097          	auipc	ra,0x2
    80001378:	5f6080e7          	jalr	1526(ra) # 8000396a <iinit>
    fileinit();      // file table
    8000137c:	00003097          	auipc	ra,0x3
    80001380:	5a6080e7          	jalr	1446(ra) # 80004922 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001384:	00005097          	auipc	ra,0x5
    80001388:	eee080e7          	jalr	-274(ra) # 80006272 <virtio_disk_init>
    userinit();      // first user process
    8000138c:	00001097          	auipc	ra,0x1
    80001390:	c7a080e7          	jalr	-902(ra) # 80002006 <userinit>
    __sync_synchronize();
    80001394:	0ff0000f          	fence
    started = 1;
    80001398:	4785                	li	a5,1
    8000139a:	00008717          	auipc	a4,0x8
    8000139e:	c6f72923          	sw	a5,-910(a4) # 8000900c <started>
    800013a2:	bf2d                	j	800012dc <main+0x56>

00000000800013a4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800013a4:	7139                	addi	sp,sp,-64
    800013a6:	fc06                	sd	ra,56(sp)
    800013a8:	f822                	sd	s0,48(sp)
    800013aa:	f426                	sd	s1,40(sp)
    800013ac:	f04a                	sd	s2,32(sp)
    800013ae:	ec4e                	sd	s3,24(sp)
    800013b0:	e852                	sd	s4,16(sp)
    800013b2:	e456                	sd	s5,8(sp)
    800013b4:	e05a                	sd	s6,0(sp)
    800013b6:	0080                	addi	s0,sp,64
    800013b8:	84aa                	mv	s1,a0
    800013ba:	89ae                	mv	s3,a1
    800013bc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013be:	57fd                	li	a5,-1
    800013c0:	83e9                	srli	a5,a5,0x1a
    800013c2:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013c4:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013c6:	04b7f263          	bgeu	a5,a1,8000140a <walk+0x66>
    panic("walk");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d9e50513          	addi	a0,a0,-610 # 80008168 <digits+0x128>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	17e080e7          	jalr	382(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013da:	060a8663          	beqz	s5,80001446 <walk+0xa2>
    800013de:	fffff097          	auipc	ra,0xfffff
    800013e2:	79a080e7          	jalr	1946(ra) # 80000b78 <kalloc>
    800013e6:	84aa                	mv	s1,a0
    800013e8:	c529                	beqz	a0,80001432 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013ea:	6605                	lui	a2,0x1
    800013ec:	4581                	li	a1,0
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	ce6080e7          	jalr	-794(ra) # 800010d4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013f6:	00c4d793          	srli	a5,s1,0xc
    800013fa:	07aa                	slli	a5,a5,0xa
    800013fc:	0017e793          	ori	a5,a5,1
    80001400:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001404:	3a5d                	addiw	s4,s4,-9
    80001406:	036a0063          	beq	s4,s6,80001426 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000140a:	0149d933          	srl	s2,s3,s4
    8000140e:	1ff97913          	andi	s2,s2,511
    80001412:	090e                	slli	s2,s2,0x3
    80001414:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001416:	00093483          	ld	s1,0(s2)
    8000141a:	0014f793          	andi	a5,s1,1
    8000141e:	dfd5                	beqz	a5,800013da <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001420:	80a9                	srli	s1,s1,0xa
    80001422:	04b2                	slli	s1,s1,0xc
    80001424:	b7c5                	j	80001404 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001426:	00c9d513          	srli	a0,s3,0xc
    8000142a:	1ff57513          	andi	a0,a0,511
    8000142e:	050e                	slli	a0,a0,0x3
    80001430:	9526                	add	a0,a0,s1
}
    80001432:	70e2                	ld	ra,56(sp)
    80001434:	7442                	ld	s0,48(sp)
    80001436:	74a2                	ld	s1,40(sp)
    80001438:	7902                	ld	s2,32(sp)
    8000143a:	69e2                	ld	s3,24(sp)
    8000143c:	6a42                	ld	s4,16(sp)
    8000143e:	6aa2                	ld	s5,8(sp)
    80001440:	6b02                	ld	s6,0(sp)
    80001442:	6121                	addi	sp,sp,64
    80001444:	8082                	ret
        return 0;
    80001446:	4501                	li	a0,0
    80001448:	b7ed                	j	80001432 <walk+0x8e>

000000008000144a <kvminithart>:
{
    8000144a:	1141                	addi	sp,sp,-16
    8000144c:	e422                	sd	s0,8(sp)
    8000144e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001450:	00008797          	auipc	a5,0x8
    80001454:	bc07b783          	ld	a5,-1088(a5) # 80009010 <kernel_pagetable>
    80001458:	83b1                	srli	a5,a5,0xc
    8000145a:	577d                	li	a4,-1
    8000145c:	177e                	slli	a4,a4,0x3f
    8000145e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001460:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001464:	12000073          	sfence.vma
}
    80001468:	6422                	ld	s0,8(sp)
    8000146a:	0141                	addi	sp,sp,16
    8000146c:	8082                	ret

000000008000146e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000146e:	57fd                	li	a5,-1
    80001470:	83e9                	srli	a5,a5,0x1a
    80001472:	00b7f463          	bgeu	a5,a1,8000147a <walkaddr+0xc>
    return 0;
    80001476:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001478:	8082                	ret
{
    8000147a:	1141                	addi	sp,sp,-16
    8000147c:	e406                	sd	ra,8(sp)
    8000147e:	e022                	sd	s0,0(sp)
    80001480:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001482:	4601                	li	a2,0
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f20080e7          	jalr	-224(ra) # 800013a4 <walk>
  if(pte == 0)
    8000148c:	c105                	beqz	a0,800014ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000148e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001490:	0117f693          	andi	a3,a5,17
    80001494:	4745                	li	a4,17
    return 0;
    80001496:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001498:	00e68663          	beq	a3,a4,800014a4 <walkaddr+0x36>
}
    8000149c:	60a2                	ld	ra,8(sp)
    8000149e:	6402                	ld	s0,0(sp)
    800014a0:	0141                	addi	sp,sp,16
    800014a2:	8082                	ret
  pa = PTE2PA(*pte);
    800014a4:	00a7d513          	srli	a0,a5,0xa
    800014a8:	0532                	slli	a0,a0,0xc
  return pa;
    800014aa:	bfcd                	j	8000149c <walkaddr+0x2e>
    return 0;
    800014ac:	4501                	li	a0,0
    800014ae:	b7fd                	j	8000149c <walkaddr+0x2e>

00000000800014b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014b0:	715d                	addi	sp,sp,-80
    800014b2:	e486                	sd	ra,72(sp)
    800014b4:	e0a2                	sd	s0,64(sp)
    800014b6:	fc26                	sd	s1,56(sp)
    800014b8:	f84a                	sd	s2,48(sp)
    800014ba:	f44e                	sd	s3,40(sp)
    800014bc:	f052                	sd	s4,32(sp)
    800014be:	ec56                	sd	s5,24(sp)
    800014c0:	e85a                	sd	s6,16(sp)
    800014c2:	e45e                	sd	s7,8(sp)
    800014c4:	0880                	addi	s0,sp,80
    800014c6:	8aaa                	mv	s5,a0
    800014c8:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014ca:	777d                	lui	a4,0xfffff
    800014cc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014d0:	167d                	addi	a2,a2,-1
    800014d2:	00b609b3          	add	s3,a2,a1
    800014d6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014da:	893e                	mv	s2,a5
    800014dc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014e0:	6b85                	lui	s7,0x1
    800014e2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014e6:	4605                	li	a2,1
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8556                	mv	a0,s5
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	eb8080e7          	jalr	-328(ra) # 800013a4 <walk>
    800014f4:	c51d                	beqz	a0,80001522 <mappages+0x72>
    if(*pte & PTE_V)
    800014f6:	611c                	ld	a5,0(a0)
    800014f8:	8b85                	andi	a5,a5,1
    800014fa:	ef81                	bnez	a5,80001512 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014fc:	80b1                	srli	s1,s1,0xc
    800014fe:	04aa                	slli	s1,s1,0xa
    80001500:	0164e4b3          	or	s1,s1,s6
    80001504:	0014e493          	ori	s1,s1,1
    80001508:	e104                	sd	s1,0(a0)
    if(a == last)
    8000150a:	03390863          	beq	s2,s3,8000153a <mappages+0x8a>
    a += PGSIZE;
    8000150e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001510:	bfc9                	j	800014e2 <mappages+0x32>
      panic("remap");
    80001512:	00007517          	auipc	a0,0x7
    80001516:	c5e50513          	addi	a0,a0,-930 # 80008170 <digits+0x130>
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	036080e7          	jalr	54(ra) # 80000550 <panic>
      return -1;
    80001522:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001524:	60a6                	ld	ra,72(sp)
    80001526:	6406                	ld	s0,64(sp)
    80001528:	74e2                	ld	s1,56(sp)
    8000152a:	7942                	ld	s2,48(sp)
    8000152c:	79a2                	ld	s3,40(sp)
    8000152e:	7a02                	ld	s4,32(sp)
    80001530:	6ae2                	ld	s5,24(sp)
    80001532:	6b42                	ld	s6,16(sp)
    80001534:	6ba2                	ld	s7,8(sp)
    80001536:	6161                	addi	sp,sp,80
    80001538:	8082                	ret
  return 0;
    8000153a:	4501                	li	a0,0
    8000153c:	b7e5                	j	80001524 <mappages+0x74>

000000008000153e <kvmmap>:
{
    8000153e:	1141                	addi	sp,sp,-16
    80001540:	e406                	sd	ra,8(sp)
    80001542:	e022                	sd	s0,0(sp)
    80001544:	0800                	addi	s0,sp,16
    80001546:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001548:	86ae                	mv	a3,a1
    8000154a:	85aa                	mv	a1,a0
    8000154c:	00008517          	auipc	a0,0x8
    80001550:	ac453503          	ld	a0,-1340(a0) # 80009010 <kernel_pagetable>
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f5c080e7          	jalr	-164(ra) # 800014b0 <mappages>
    8000155c:	e509                	bnez	a0,80001566 <kvmmap+0x28>
}
    8000155e:	60a2                	ld	ra,8(sp)
    80001560:	6402                	ld	s0,0(sp)
    80001562:	0141                	addi	sp,sp,16
    80001564:	8082                	ret
    panic("kvmmap");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	c1250513          	addi	a0,a0,-1006 # 80008178 <digits+0x138>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fe2080e7          	jalr	-30(ra) # 80000550 <panic>

0000000080001576 <kvminit>:
{
    80001576:	1101                	addi	sp,sp,-32
    80001578:	ec06                	sd	ra,24(sp)
    8000157a:	e822                	sd	s0,16(sp)
    8000157c:	e426                	sd	s1,8(sp)
    8000157e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001580:	fffff097          	auipc	ra,0xfffff
    80001584:	5f8080e7          	jalr	1528(ra) # 80000b78 <kalloc>
    80001588:	00008797          	auipc	a5,0x8
    8000158c:	a8a7b423          	sd	a0,-1400(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001590:	6605                	lui	a2,0x1
    80001592:	4581                	li	a1,0
    80001594:	00000097          	auipc	ra,0x0
    80001598:	b40080e7          	jalr	-1216(ra) # 800010d4 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000159c:	4699                	li	a3,6
    8000159e:	6605                	lui	a2,0x1
    800015a0:	100005b7          	lui	a1,0x10000
    800015a4:	10000537          	lui	a0,0x10000
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	f96080e7          	jalr	-106(ra) # 8000153e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015b0:	4699                	li	a3,6
    800015b2:	6605                	lui	a2,0x1
    800015b4:	100015b7          	lui	a1,0x10001
    800015b8:	10001537          	lui	a0,0x10001
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	f82080e7          	jalr	-126(ra) # 8000153e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015c4:	4699                	li	a3,6
    800015c6:	00400637          	lui	a2,0x400
    800015ca:	0c0005b7          	lui	a1,0xc000
    800015ce:	0c000537          	lui	a0,0xc000
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	f6c080e7          	jalr	-148(ra) # 8000153e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015da:	00007497          	auipc	s1,0x7
    800015de:	a2648493          	addi	s1,s1,-1498 # 80008000 <etext>
    800015e2:	46a9                	li	a3,10
    800015e4:	80007617          	auipc	a2,0x80007
    800015e8:	a1c60613          	addi	a2,a2,-1508 # 8000 <_entry-0x7fff8000>
    800015ec:	4585                	li	a1,1
    800015ee:	05fe                	slli	a1,a1,0x1f
    800015f0:	852e                	mv	a0,a1
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	f4c080e7          	jalr	-180(ra) # 8000153e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015fa:	4699                	li	a3,6
    800015fc:	4645                	li	a2,17
    800015fe:	066e                	slli	a2,a2,0x1b
    80001600:	8e05                	sub	a2,a2,s1
    80001602:	85a6                	mv	a1,s1
    80001604:	8526                	mv	a0,s1
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	f38080e7          	jalr	-200(ra) # 8000153e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000160e:	46a9                	li	a3,10
    80001610:	6605                	lui	a2,0x1
    80001612:	00006597          	auipc	a1,0x6
    80001616:	9ee58593          	addi	a1,a1,-1554 # 80007000 <_trampoline>
    8000161a:	04000537          	lui	a0,0x4000
    8000161e:	157d                	addi	a0,a0,-1
    80001620:	0532                	slli	a0,a0,0xc
    80001622:	00000097          	auipc	ra,0x0
    80001626:	f1c080e7          	jalr	-228(ra) # 8000153e <kvmmap>
}
    8000162a:	60e2                	ld	ra,24(sp)
    8000162c:	6442                	ld	s0,16(sp)
    8000162e:	64a2                	ld	s1,8(sp)
    80001630:	6105                	addi	sp,sp,32
    80001632:	8082                	ret

0000000080001634 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001634:	715d                	addi	sp,sp,-80
    80001636:	e486                	sd	ra,72(sp)
    80001638:	e0a2                	sd	s0,64(sp)
    8000163a:	fc26                	sd	s1,56(sp)
    8000163c:	f84a                	sd	s2,48(sp)
    8000163e:	f44e                	sd	s3,40(sp)
    80001640:	f052                	sd	s4,32(sp)
    80001642:	ec56                	sd	s5,24(sp)
    80001644:	e85a                	sd	s6,16(sp)
    80001646:	e45e                	sd	s7,8(sp)
    80001648:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000164a:	03459793          	slli	a5,a1,0x34
    8000164e:	e795                	bnez	a5,8000167a <uvmunmap+0x46>
    80001650:	8a2a                	mv	s4,a0
    80001652:	892e                	mv	s2,a1
    80001654:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001656:	0632                	slli	a2,a2,0xc
    80001658:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000165c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000165e:	6b05                	lui	s6,0x1
    80001660:	0735e863          	bltu	a1,s3,800016d0 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001664:	60a6                	ld	ra,72(sp)
    80001666:	6406                	ld	s0,64(sp)
    80001668:	74e2                	ld	s1,56(sp)
    8000166a:	7942                	ld	s2,48(sp)
    8000166c:	79a2                	ld	s3,40(sp)
    8000166e:	7a02                	ld	s4,32(sp)
    80001670:	6ae2                	ld	s5,24(sp)
    80001672:	6b42                	ld	s6,16(sp)
    80001674:	6ba2                	ld	s7,8(sp)
    80001676:	6161                	addi	sp,sp,80
    80001678:	8082                	ret
    panic("uvmunmap: not aligned");
    8000167a:	00007517          	auipc	a0,0x7
    8000167e:	b0650513          	addi	a0,a0,-1274 # 80008180 <digits+0x140>
    80001682:	fffff097          	auipc	ra,0xfffff
    80001686:	ece080e7          	jalr	-306(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    8000168a:	00007517          	auipc	a0,0x7
    8000168e:	b0e50513          	addi	a0,a0,-1266 # 80008198 <digits+0x158>
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	ebe080e7          	jalr	-322(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	b0e50513          	addi	a0,a0,-1266 # 800081a8 <digits+0x168>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	eae080e7          	jalr	-338(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    800016aa:	00007517          	auipc	a0,0x7
    800016ae:	b1650513          	addi	a0,a0,-1258 # 800081c0 <digits+0x180>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	e9e080e7          	jalr	-354(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    800016ba:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016bc:	0532                	slli	a0,a0,0xc
    800016be:	fffff097          	auipc	ra,0xfffff
    800016c2:	36e080e7          	jalr	878(ra) # 80000a2c <kfree>
    *pte = 0;
    800016c6:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016ca:	995a                	add	s2,s2,s6
    800016cc:	f9397ce3          	bgeu	s2,s3,80001664 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016d0:	4601                	li	a2,0
    800016d2:	85ca                	mv	a1,s2
    800016d4:	8552                	mv	a0,s4
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	cce080e7          	jalr	-818(ra) # 800013a4 <walk>
    800016de:	84aa                	mv	s1,a0
    800016e0:	d54d                	beqz	a0,8000168a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016e2:	6108                	ld	a0,0(a0)
    800016e4:	00157793          	andi	a5,a0,1
    800016e8:	dbcd                	beqz	a5,8000169a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016ea:	3ff57793          	andi	a5,a0,1023
    800016ee:	fb778ee3          	beq	a5,s7,800016aa <uvmunmap+0x76>
    if(do_free){
    800016f2:	fc0a8ae3          	beqz	s5,800016c6 <uvmunmap+0x92>
    800016f6:	b7d1                	j	800016ba <uvmunmap+0x86>

00000000800016f8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016f8:	1101                	addi	sp,sp,-32
    800016fa:	ec06                	sd	ra,24(sp)
    800016fc:	e822                	sd	s0,16(sp)
    800016fe:	e426                	sd	s1,8(sp)
    80001700:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001702:	fffff097          	auipc	ra,0xfffff
    80001706:	476080e7          	jalr	1142(ra) # 80000b78 <kalloc>
    8000170a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000170c:	c519                	beqz	a0,8000171a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000170e:	6605                	lui	a2,0x1
    80001710:	4581                	li	a1,0
    80001712:	00000097          	auipc	ra,0x0
    80001716:	9c2080e7          	jalr	-1598(ra) # 800010d4 <memset>
  return pagetable;
}
    8000171a:	8526                	mv	a0,s1
    8000171c:	60e2                	ld	ra,24(sp)
    8000171e:	6442                	ld	s0,16(sp)
    80001720:	64a2                	ld	s1,8(sp)
    80001722:	6105                	addi	sp,sp,32
    80001724:	8082                	ret

0000000080001726 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001726:	7179                	addi	sp,sp,-48
    80001728:	f406                	sd	ra,40(sp)
    8000172a:	f022                	sd	s0,32(sp)
    8000172c:	ec26                	sd	s1,24(sp)
    8000172e:	e84a                	sd	s2,16(sp)
    80001730:	e44e                	sd	s3,8(sp)
    80001732:	e052                	sd	s4,0(sp)
    80001734:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001736:	6785                	lui	a5,0x1
    80001738:	04f67863          	bgeu	a2,a5,80001788 <uvminit+0x62>
    8000173c:	8a2a                	mv	s4,a0
    8000173e:	89ae                	mv	s3,a1
    80001740:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	436080e7          	jalr	1078(ra) # 80000b78 <kalloc>
    8000174a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000174c:	6605                	lui	a2,0x1
    8000174e:	4581                	li	a1,0
    80001750:	00000097          	auipc	ra,0x0
    80001754:	984080e7          	jalr	-1660(ra) # 800010d4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001758:	4779                	li	a4,30
    8000175a:	86ca                	mv	a3,s2
    8000175c:	6605                	lui	a2,0x1
    8000175e:	4581                	li	a1,0
    80001760:	8552                	mv	a0,s4
    80001762:	00000097          	auipc	ra,0x0
    80001766:	d4e080e7          	jalr	-690(ra) # 800014b0 <mappages>
  memmove(mem, src, sz);
    8000176a:	8626                	mv	a2,s1
    8000176c:	85ce                	mv	a1,s3
    8000176e:	854a                	mv	a0,s2
    80001770:	00000097          	auipc	ra,0x0
    80001774:	9c4080e7          	jalr	-1596(ra) # 80001134 <memmove>
}
    80001778:	70a2                	ld	ra,40(sp)
    8000177a:	7402                	ld	s0,32(sp)
    8000177c:	64e2                	ld	s1,24(sp)
    8000177e:	6942                	ld	s2,16(sp)
    80001780:	69a2                	ld	s3,8(sp)
    80001782:	6a02                	ld	s4,0(sp)
    80001784:	6145                	addi	sp,sp,48
    80001786:	8082                	ret
    panic("inituvm: more than a page");
    80001788:	00007517          	auipc	a0,0x7
    8000178c:	a5050513          	addi	a0,a0,-1456 # 800081d8 <digits+0x198>
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	dc0080e7          	jalr	-576(ra) # 80000550 <panic>

0000000080001798 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001798:	1101                	addi	sp,sp,-32
    8000179a:	ec06                	sd	ra,24(sp)
    8000179c:	e822                	sd	s0,16(sp)
    8000179e:	e426                	sd	s1,8(sp)
    800017a0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017a2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017a4:	00b67d63          	bgeu	a2,a1,800017be <uvmdealloc+0x26>
    800017a8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017aa:	6785                	lui	a5,0x1
    800017ac:	17fd                	addi	a5,a5,-1
    800017ae:	00f60733          	add	a4,a2,a5
    800017b2:	767d                	lui	a2,0xfffff
    800017b4:	8f71                	and	a4,a4,a2
    800017b6:	97ae                	add	a5,a5,a1
    800017b8:	8ff1                	and	a5,a5,a2
    800017ba:	00f76863          	bltu	a4,a5,800017ca <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017be:	8526                	mv	a0,s1
    800017c0:	60e2                	ld	ra,24(sp)
    800017c2:	6442                	ld	s0,16(sp)
    800017c4:	64a2                	ld	s1,8(sp)
    800017c6:	6105                	addi	sp,sp,32
    800017c8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017ca:	8f99                	sub	a5,a5,a4
    800017cc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017ce:	4685                	li	a3,1
    800017d0:	0007861b          	sext.w	a2,a5
    800017d4:	85ba                	mv	a1,a4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	e5e080e7          	jalr	-418(ra) # 80001634 <uvmunmap>
    800017de:	b7c5                	j	800017be <uvmdealloc+0x26>

00000000800017e0 <uvmalloc>:
  if(newsz < oldsz)
    800017e0:	0ab66163          	bltu	a2,a1,80001882 <uvmalloc+0xa2>
{
    800017e4:	7139                	addi	sp,sp,-64
    800017e6:	fc06                	sd	ra,56(sp)
    800017e8:	f822                	sd	s0,48(sp)
    800017ea:	f426                	sd	s1,40(sp)
    800017ec:	f04a                	sd	s2,32(sp)
    800017ee:	ec4e                	sd	s3,24(sp)
    800017f0:	e852                	sd	s4,16(sp)
    800017f2:	e456                	sd	s5,8(sp)
    800017f4:	0080                	addi	s0,sp,64
    800017f6:	8aaa                	mv	s5,a0
    800017f8:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017fa:	6985                	lui	s3,0x1
    800017fc:	19fd                	addi	s3,s3,-1
    800017fe:	95ce                	add	a1,a1,s3
    80001800:	79fd                	lui	s3,0xfffff
    80001802:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001806:	08c9f063          	bgeu	s3,a2,80001886 <uvmalloc+0xa6>
    8000180a:	894e                	mv	s2,s3
    mem = kalloc();
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	36c080e7          	jalr	876(ra) # 80000b78 <kalloc>
    80001814:	84aa                	mv	s1,a0
    if(mem == 0){
    80001816:	c51d                	beqz	a0,80001844 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001818:	6605                	lui	a2,0x1
    8000181a:	4581                	li	a1,0
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	8b8080e7          	jalr	-1864(ra) # 800010d4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001824:	4779                	li	a4,30
    80001826:	86a6                	mv	a3,s1
    80001828:	6605                	lui	a2,0x1
    8000182a:	85ca                	mv	a1,s2
    8000182c:	8556                	mv	a0,s5
    8000182e:	00000097          	auipc	ra,0x0
    80001832:	c82080e7          	jalr	-894(ra) # 800014b0 <mappages>
    80001836:	e905                	bnez	a0,80001866 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001838:	6785                	lui	a5,0x1
    8000183a:	993e                	add	s2,s2,a5
    8000183c:	fd4968e3          	bltu	s2,s4,8000180c <uvmalloc+0x2c>
  return newsz;
    80001840:	8552                	mv	a0,s4
    80001842:	a809                	j	80001854 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001844:	864e                	mv	a2,s3
    80001846:	85ca                	mv	a1,s2
    80001848:	8556                	mv	a0,s5
    8000184a:	00000097          	auipc	ra,0x0
    8000184e:	f4e080e7          	jalr	-178(ra) # 80001798 <uvmdealloc>
      return 0;
    80001852:	4501                	li	a0,0
}
    80001854:	70e2                	ld	ra,56(sp)
    80001856:	7442                	ld	s0,48(sp)
    80001858:	74a2                	ld	s1,40(sp)
    8000185a:	7902                	ld	s2,32(sp)
    8000185c:	69e2                	ld	s3,24(sp)
    8000185e:	6a42                	ld	s4,16(sp)
    80001860:	6aa2                	ld	s5,8(sp)
    80001862:	6121                	addi	sp,sp,64
    80001864:	8082                	ret
      kfree(mem);
    80001866:	8526                	mv	a0,s1
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	1c4080e7          	jalr	452(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001870:	864e                	mv	a2,s3
    80001872:	85ca                	mv	a1,s2
    80001874:	8556                	mv	a0,s5
    80001876:	00000097          	auipc	ra,0x0
    8000187a:	f22080e7          	jalr	-222(ra) # 80001798 <uvmdealloc>
      return 0;
    8000187e:	4501                	li	a0,0
    80001880:	bfd1                	j	80001854 <uvmalloc+0x74>
    return oldsz;
    80001882:	852e                	mv	a0,a1
}
    80001884:	8082                	ret
  return newsz;
    80001886:	8532                	mv	a0,a2
    80001888:	b7f1                	j	80001854 <uvmalloc+0x74>

000000008000188a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000188a:	7179                	addi	sp,sp,-48
    8000188c:	f406                	sd	ra,40(sp)
    8000188e:	f022                	sd	s0,32(sp)
    80001890:	ec26                	sd	s1,24(sp)
    80001892:	e84a                	sd	s2,16(sp)
    80001894:	e44e                	sd	s3,8(sp)
    80001896:	e052                	sd	s4,0(sp)
    80001898:	1800                	addi	s0,sp,48
    8000189a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000189c:	84aa                	mv	s1,a0
    8000189e:	6905                	lui	s2,0x1
    800018a0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018a2:	4985                	li	s3,1
    800018a4:	a821                	j	800018bc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800018a6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800018a8:	0532                	slli	a0,a0,0xc
    800018aa:	00000097          	auipc	ra,0x0
    800018ae:	fe0080e7          	jalr	-32(ra) # 8000188a <freewalk>
      pagetable[i] = 0;
    800018b2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018b6:	04a1                	addi	s1,s1,8
    800018b8:	03248163          	beq	s1,s2,800018da <freewalk+0x50>
    pte_t pte = pagetable[i];
    800018bc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018be:	00f57793          	andi	a5,a0,15
    800018c2:	ff3782e3          	beq	a5,s3,800018a6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018c6:	8905                	andi	a0,a0,1
    800018c8:	d57d                	beqz	a0,800018b6 <freewalk+0x2c>
      panic("freewalk: leaf");
    800018ca:	00007517          	auipc	a0,0x7
    800018ce:	92e50513          	addi	a0,a0,-1746 # 800081f8 <digits+0x1b8>
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	c7e080e7          	jalr	-898(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    800018da:	8552                	mv	a0,s4
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	150080e7          	jalr	336(ra) # 80000a2c <kfree>
}
    800018e4:	70a2                	ld	ra,40(sp)
    800018e6:	7402                	ld	s0,32(sp)
    800018e8:	64e2                	ld	s1,24(sp)
    800018ea:	6942                	ld	s2,16(sp)
    800018ec:	69a2                	ld	s3,8(sp)
    800018ee:	6a02                	ld	s4,0(sp)
    800018f0:	6145                	addi	sp,sp,48
    800018f2:	8082                	ret

00000000800018f4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018f4:	1101                	addi	sp,sp,-32
    800018f6:	ec06                	sd	ra,24(sp)
    800018f8:	e822                	sd	s0,16(sp)
    800018fa:	e426                	sd	s1,8(sp)
    800018fc:	1000                	addi	s0,sp,32
    800018fe:	84aa                	mv	s1,a0
  if(sz > 0)
    80001900:	e999                	bnez	a1,80001916 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001902:	8526                	mv	a0,s1
    80001904:	00000097          	auipc	ra,0x0
    80001908:	f86080e7          	jalr	-122(ra) # 8000188a <freewalk>
}
    8000190c:	60e2                	ld	ra,24(sp)
    8000190e:	6442                	ld	s0,16(sp)
    80001910:	64a2                	ld	s1,8(sp)
    80001912:	6105                	addi	sp,sp,32
    80001914:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001916:	6605                	lui	a2,0x1
    80001918:	167d                	addi	a2,a2,-1
    8000191a:	962e                	add	a2,a2,a1
    8000191c:	4685                	li	a3,1
    8000191e:	8231                	srli	a2,a2,0xc
    80001920:	4581                	li	a1,0
    80001922:	00000097          	auipc	ra,0x0
    80001926:	d12080e7          	jalr	-750(ra) # 80001634 <uvmunmap>
    8000192a:	bfe1                	j	80001902 <uvmfree+0xe>

000000008000192c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000192c:	c679                	beqz	a2,800019fa <uvmcopy+0xce>
{
    8000192e:	715d                	addi	sp,sp,-80
    80001930:	e486                	sd	ra,72(sp)
    80001932:	e0a2                	sd	s0,64(sp)
    80001934:	fc26                	sd	s1,56(sp)
    80001936:	f84a                	sd	s2,48(sp)
    80001938:	f44e                	sd	s3,40(sp)
    8000193a:	f052                	sd	s4,32(sp)
    8000193c:	ec56                	sd	s5,24(sp)
    8000193e:	e85a                	sd	s6,16(sp)
    80001940:	e45e                	sd	s7,8(sp)
    80001942:	0880                	addi	s0,sp,80
    80001944:	8b2a                	mv	s6,a0
    80001946:	8aae                	mv	s5,a1
    80001948:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000194a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000194c:	4601                	li	a2,0
    8000194e:	85ce                	mv	a1,s3
    80001950:	855a                	mv	a0,s6
    80001952:	00000097          	auipc	ra,0x0
    80001956:	a52080e7          	jalr	-1454(ra) # 800013a4 <walk>
    8000195a:	c531                	beqz	a0,800019a6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000195c:	6118                	ld	a4,0(a0)
    8000195e:	00177793          	andi	a5,a4,1
    80001962:	cbb1                	beqz	a5,800019b6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001964:	00a75593          	srli	a1,a4,0xa
    80001968:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000196c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001970:	fffff097          	auipc	ra,0xfffff
    80001974:	208080e7          	jalr	520(ra) # 80000b78 <kalloc>
    80001978:	892a                	mv	s2,a0
    8000197a:	c939                	beqz	a0,800019d0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000197c:	6605                	lui	a2,0x1
    8000197e:	85de                	mv	a1,s7
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	7b4080e7          	jalr	1972(ra) # 80001134 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001988:	8726                	mv	a4,s1
    8000198a:	86ca                	mv	a3,s2
    8000198c:	6605                	lui	a2,0x1
    8000198e:	85ce                	mv	a1,s3
    80001990:	8556                	mv	a0,s5
    80001992:	00000097          	auipc	ra,0x0
    80001996:	b1e080e7          	jalr	-1250(ra) # 800014b0 <mappages>
    8000199a:	e515                	bnez	a0,800019c6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000199c:	6785                	lui	a5,0x1
    8000199e:	99be                	add	s3,s3,a5
    800019a0:	fb49e6e3          	bltu	s3,s4,8000194c <uvmcopy+0x20>
    800019a4:	a081                	j	800019e4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800019a6:	00007517          	auipc	a0,0x7
    800019aa:	86250513          	addi	a0,a0,-1950 # 80008208 <digits+0x1c8>
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	ba2080e7          	jalr	-1118(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    800019b6:	00007517          	auipc	a0,0x7
    800019ba:	87250513          	addi	a0,a0,-1934 # 80008228 <digits+0x1e8>
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	b92080e7          	jalr	-1134(ra) # 80000550 <panic>
      kfree(mem);
    800019c6:	854a                	mv	a0,s2
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	064080e7          	jalr	100(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019d0:	4685                	li	a3,1
    800019d2:	00c9d613          	srli	a2,s3,0xc
    800019d6:	4581                	li	a1,0
    800019d8:	8556                	mv	a0,s5
    800019da:	00000097          	auipc	ra,0x0
    800019de:	c5a080e7          	jalr	-934(ra) # 80001634 <uvmunmap>
  return -1;
    800019e2:	557d                	li	a0,-1
}
    800019e4:	60a6                	ld	ra,72(sp)
    800019e6:	6406                	ld	s0,64(sp)
    800019e8:	74e2                	ld	s1,56(sp)
    800019ea:	7942                	ld	s2,48(sp)
    800019ec:	79a2                	ld	s3,40(sp)
    800019ee:	7a02                	ld	s4,32(sp)
    800019f0:	6ae2                	ld	s5,24(sp)
    800019f2:	6b42                	ld	s6,16(sp)
    800019f4:	6ba2                	ld	s7,8(sp)
    800019f6:	6161                	addi	sp,sp,80
    800019f8:	8082                	ret
  return 0;
    800019fa:	4501                	li	a0,0
}
    800019fc:	8082                	ret

00000000800019fe <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a06:	4601                	li	a2,0
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	99c080e7          	jalr	-1636(ra) # 800013a4 <walk>
  if(pte == 0)
    80001a10:	c901                	beqz	a0,80001a20 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a12:	611c                	ld	a5,0(a0)
    80001a14:	9bbd                	andi	a5,a5,-17
    80001a16:	e11c                	sd	a5,0(a0)
}
    80001a18:	60a2                	ld	ra,8(sp)
    80001a1a:	6402                	ld	s0,0(sp)
    80001a1c:	0141                	addi	sp,sp,16
    80001a1e:	8082                	ret
    panic("uvmclear");
    80001a20:	00007517          	auipc	a0,0x7
    80001a24:	82850513          	addi	a0,a0,-2008 # 80008248 <digits+0x208>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	b28080e7          	jalr	-1240(ra) # 80000550 <panic>

0000000080001a30 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a30:	c6bd                	beqz	a3,80001a9e <copyout+0x6e>
{
    80001a32:	715d                	addi	sp,sp,-80
    80001a34:	e486                	sd	ra,72(sp)
    80001a36:	e0a2                	sd	s0,64(sp)
    80001a38:	fc26                	sd	s1,56(sp)
    80001a3a:	f84a                	sd	s2,48(sp)
    80001a3c:	f44e                	sd	s3,40(sp)
    80001a3e:	f052                	sd	s4,32(sp)
    80001a40:	ec56                	sd	s5,24(sp)
    80001a42:	e85a                	sd	s6,16(sp)
    80001a44:	e45e                	sd	s7,8(sp)
    80001a46:	e062                	sd	s8,0(sp)
    80001a48:	0880                	addi	s0,sp,80
    80001a4a:	8b2a                	mv	s6,a0
    80001a4c:	8c2e                	mv	s8,a1
    80001a4e:	8a32                	mv	s4,a2
    80001a50:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a52:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a54:	6a85                	lui	s5,0x1
    80001a56:	a015                	j	80001a7a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a58:	9562                	add	a0,a0,s8
    80001a5a:	0004861b          	sext.w	a2,s1
    80001a5e:	85d2                	mv	a1,s4
    80001a60:	41250533          	sub	a0,a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	6d0080e7          	jalr	1744(ra) # 80001134 <memmove>

    len -= n;
    80001a6c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a70:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a72:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a76:	02098263          	beqz	s3,80001a9a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a7a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a7e:	85ca                	mv	a1,s2
    80001a80:	855a                	mv	a0,s6
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	9ec080e7          	jalr	-1556(ra) # 8000146e <walkaddr>
    if(pa0 == 0)
    80001a8a:	cd01                	beqz	a0,80001aa2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a8c:	418904b3          	sub	s1,s2,s8
    80001a90:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a92:	fc99f3e3          	bgeu	s3,s1,80001a58 <copyout+0x28>
    80001a96:	84ce                	mv	s1,s3
    80001a98:	b7c1                	j	80001a58 <copyout+0x28>
  }
  return 0;
    80001a9a:	4501                	li	a0,0
    80001a9c:	a021                	j	80001aa4 <copyout+0x74>
    80001a9e:	4501                	li	a0,0
}
    80001aa0:	8082                	ret
      return -1;
    80001aa2:	557d                	li	a0,-1
}
    80001aa4:	60a6                	ld	ra,72(sp)
    80001aa6:	6406                	ld	s0,64(sp)
    80001aa8:	74e2                	ld	s1,56(sp)
    80001aaa:	7942                	ld	s2,48(sp)
    80001aac:	79a2                	ld	s3,40(sp)
    80001aae:	7a02                	ld	s4,32(sp)
    80001ab0:	6ae2                	ld	s5,24(sp)
    80001ab2:	6b42                	ld	s6,16(sp)
    80001ab4:	6ba2                	ld	s7,8(sp)
    80001ab6:	6c02                	ld	s8,0(sp)
    80001ab8:	6161                	addi	sp,sp,80
    80001aba:	8082                	ret

0000000080001abc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001abc:	c6bd                	beqz	a3,80001b2a <copyin+0x6e>
{
    80001abe:	715d                	addi	sp,sp,-80
    80001ac0:	e486                	sd	ra,72(sp)
    80001ac2:	e0a2                	sd	s0,64(sp)
    80001ac4:	fc26                	sd	s1,56(sp)
    80001ac6:	f84a                	sd	s2,48(sp)
    80001ac8:	f44e                	sd	s3,40(sp)
    80001aca:	f052                	sd	s4,32(sp)
    80001acc:	ec56                	sd	s5,24(sp)
    80001ace:	e85a                	sd	s6,16(sp)
    80001ad0:	e45e                	sd	s7,8(sp)
    80001ad2:	e062                	sd	s8,0(sp)
    80001ad4:	0880                	addi	s0,sp,80
    80001ad6:	8b2a                	mv	s6,a0
    80001ad8:	8a2e                	mv	s4,a1
    80001ada:	8c32                	mv	s8,a2
    80001adc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001ade:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ae0:	6a85                	lui	s5,0x1
    80001ae2:	a015                	j	80001b06 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ae4:	9562                	add	a0,a0,s8
    80001ae6:	0004861b          	sext.w	a2,s1
    80001aea:	412505b3          	sub	a1,a0,s2
    80001aee:	8552                	mv	a0,s4
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	644080e7          	jalr	1604(ra) # 80001134 <memmove>

    len -= n;
    80001af8:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001afc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001afe:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b02:	02098263          	beqz	s3,80001b26 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b06:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b0a:	85ca                	mv	a1,s2
    80001b0c:	855a                	mv	a0,s6
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	960080e7          	jalr	-1696(ra) # 8000146e <walkaddr>
    if(pa0 == 0)
    80001b16:	cd01                	beqz	a0,80001b2e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b18:	418904b3          	sub	s1,s2,s8
    80001b1c:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b1e:	fc99f3e3          	bgeu	s3,s1,80001ae4 <copyin+0x28>
    80001b22:	84ce                	mv	s1,s3
    80001b24:	b7c1                	j	80001ae4 <copyin+0x28>
  }
  return 0;
    80001b26:	4501                	li	a0,0
    80001b28:	a021                	j	80001b30 <copyin+0x74>
    80001b2a:	4501                	li	a0,0
}
    80001b2c:	8082                	ret
      return -1;
    80001b2e:	557d                	li	a0,-1
}
    80001b30:	60a6                	ld	ra,72(sp)
    80001b32:	6406                	ld	s0,64(sp)
    80001b34:	74e2                	ld	s1,56(sp)
    80001b36:	7942                	ld	s2,48(sp)
    80001b38:	79a2                	ld	s3,40(sp)
    80001b3a:	7a02                	ld	s4,32(sp)
    80001b3c:	6ae2                	ld	s5,24(sp)
    80001b3e:	6b42                	ld	s6,16(sp)
    80001b40:	6ba2                	ld	s7,8(sp)
    80001b42:	6c02                	ld	s8,0(sp)
    80001b44:	6161                	addi	sp,sp,80
    80001b46:	8082                	ret

0000000080001b48 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b48:	c6c5                	beqz	a3,80001bf0 <copyinstr+0xa8>
{
    80001b4a:	715d                	addi	sp,sp,-80
    80001b4c:	e486                	sd	ra,72(sp)
    80001b4e:	e0a2                	sd	s0,64(sp)
    80001b50:	fc26                	sd	s1,56(sp)
    80001b52:	f84a                	sd	s2,48(sp)
    80001b54:	f44e                	sd	s3,40(sp)
    80001b56:	f052                	sd	s4,32(sp)
    80001b58:	ec56                	sd	s5,24(sp)
    80001b5a:	e85a                	sd	s6,16(sp)
    80001b5c:	e45e                	sd	s7,8(sp)
    80001b5e:	0880                	addi	s0,sp,80
    80001b60:	8a2a                	mv	s4,a0
    80001b62:	8b2e                	mv	s6,a1
    80001b64:	8bb2                	mv	s7,a2
    80001b66:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b68:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b6a:	6985                	lui	s3,0x1
    80001b6c:	a035                	j	80001b98 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b6e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b72:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b74:	0017b793          	seqz	a5,a5
    80001b78:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b7c:	60a6                	ld	ra,72(sp)
    80001b7e:	6406                	ld	s0,64(sp)
    80001b80:	74e2                	ld	s1,56(sp)
    80001b82:	7942                	ld	s2,48(sp)
    80001b84:	79a2                	ld	s3,40(sp)
    80001b86:	7a02                	ld	s4,32(sp)
    80001b88:	6ae2                	ld	s5,24(sp)
    80001b8a:	6b42                	ld	s6,16(sp)
    80001b8c:	6ba2                	ld	s7,8(sp)
    80001b8e:	6161                	addi	sp,sp,80
    80001b90:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b92:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b96:	c8a9                	beqz	s1,80001be8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001b98:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b9c:	85ca                	mv	a1,s2
    80001b9e:	8552                	mv	a0,s4
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	8ce080e7          	jalr	-1842(ra) # 8000146e <walkaddr>
    if(pa0 == 0)
    80001ba8:	c131                	beqz	a0,80001bec <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001baa:	41790833          	sub	a6,s2,s7
    80001bae:	984e                	add	a6,a6,s3
    if(n > max)
    80001bb0:	0104f363          	bgeu	s1,a6,80001bb6 <copyinstr+0x6e>
    80001bb4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bb6:	955e                	add	a0,a0,s7
    80001bb8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bbc:	fc080be3          	beqz	a6,80001b92 <copyinstr+0x4a>
    80001bc0:	985a                	add	a6,a6,s6
    80001bc2:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bc4:	41650633          	sub	a2,a0,s6
    80001bc8:	14fd                	addi	s1,s1,-1
    80001bca:	9b26                	add	s6,s6,s1
    80001bcc:	00f60733          	add	a4,a2,a5
    80001bd0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbafd8>
    80001bd4:	df49                	beqz	a4,80001b6e <copyinstr+0x26>
        *dst = *p;
    80001bd6:	00e78023          	sb	a4,0(a5)
      --max;
    80001bda:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001bde:	0785                	addi	a5,a5,1
    while(n > 0){
    80001be0:	ff0796e3          	bne	a5,a6,80001bcc <copyinstr+0x84>
      dst++;
    80001be4:	8b42                	mv	s6,a6
    80001be6:	b775                	j	80001b92 <copyinstr+0x4a>
    80001be8:	4781                	li	a5,0
    80001bea:	b769                	j	80001b74 <copyinstr+0x2c>
      return -1;
    80001bec:	557d                	li	a0,-1
    80001bee:	b779                	j	80001b7c <copyinstr+0x34>
  int got_null = 0;
    80001bf0:	4781                	li	a5,0
  if(got_null){
    80001bf2:	0017b793          	seqz	a5,a5
    80001bf6:	40f00533          	neg	a0,a5
}
    80001bfa:	8082                	ret

0000000080001bfc <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	1000                	addi	s0,sp,32
    80001c06:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	072080e7          	jalr	114(ra) # 80000c7a <holding>
    80001c10:	c909                	beqz	a0,80001c22 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c12:	789c                	ld	a5,48(s1)
    80001c14:	00978f63          	beq	a5,s1,80001c32 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c18:	60e2                	ld	ra,24(sp)
    80001c1a:	6442                	ld	s0,16(sp)
    80001c1c:	64a2                	ld	s1,8(sp)
    80001c1e:	6105                	addi	sp,sp,32
    80001c20:	8082                	ret
    panic("wakeup1");
    80001c22:	00006517          	auipc	a0,0x6
    80001c26:	63650513          	addi	a0,a0,1590 # 80008258 <digits+0x218>
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	926080e7          	jalr	-1754(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c32:	5098                	lw	a4,32(s1)
    80001c34:	4785                	li	a5,1
    80001c36:	fef711e3          	bne	a4,a5,80001c18 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c3a:	4789                	li	a5,2
    80001c3c:	d09c                	sw	a5,32(s1)
}
    80001c3e:	bfe9                	j	80001c18 <wakeup1+0x1c>

0000000080001c40 <procinit>:
{
    80001c40:	715d                	addi	sp,sp,-80
    80001c42:	e486                	sd	ra,72(sp)
    80001c44:	e0a2                	sd	s0,64(sp)
    80001c46:	fc26                	sd	s1,56(sp)
    80001c48:	f84a                	sd	s2,48(sp)
    80001c4a:	f44e                	sd	s3,40(sp)
    80001c4c:	f052                	sd	s4,32(sp)
    80001c4e:	ec56                	sd	s5,24(sp)
    80001c50:	e85a                	sd	s6,16(sp)
    80001c52:	e45e                	sd	s7,8(sp)
    80001c54:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c56:	00006597          	auipc	a1,0x6
    80001c5a:	60a58593          	addi	a1,a1,1546 # 80008260 <digits+0x220>
    80001c5e:	00010517          	auipc	a0,0x10
    80001c62:	72a50513          	addi	a0,a0,1834 # 80012388 <pid_lock>
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	20a080e7          	jalr	522(ra) # 80000e70 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6e:	00011917          	auipc	s2,0x11
    80001c72:	b3a90913          	addi	s2,s2,-1222 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c76:	00006b97          	auipc	s7,0x6
    80001c7a:	5f2b8b93          	addi	s7,s7,1522 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c7e:	8b4a                	mv	s6,s2
    80001c80:	00006a97          	auipc	s5,0x6
    80001c84:	380a8a93          	addi	s5,s5,896 # 80008000 <etext>
    80001c88:	040009b7          	lui	s3,0x4000
    80001c8c:	19fd                	addi	s3,s3,-1
    80001c8e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	00016a17          	auipc	s4,0x16
    80001c94:	718a0a13          	addi	s4,s4,1816 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c98:	85de                	mv	a1,s7
    80001c9a:	854a                	mv	a0,s2
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	1d4080e7          	jalr	468(ra) # 80000e70 <initlock>
      char *pa = kalloc();
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ed4080e7          	jalr	-300(ra) # 80000b78 <kalloc>
    80001cac:	85aa                	mv	a1,a0
      if(pa == 0)
    80001cae:	c929                	beqz	a0,80001d00 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001cb0:	416904b3          	sub	s1,s2,s6
    80001cb4:	8491                	srai	s1,s1,0x4
    80001cb6:	000ab783          	ld	a5,0(s5)
    80001cba:	02f484b3          	mul	s1,s1,a5
    80001cbe:	2485                	addiw	s1,s1,1
    80001cc0:	00d4949b          	slliw	s1,s1,0xd
    80001cc4:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cc8:	4699                	li	a3,6
    80001cca:	6605                	lui	a2,0x1
    80001ccc:	8526                	mv	a0,s1
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	870080e7          	jalr	-1936(ra) # 8000153e <kvmmap>
      p->kstack = va;
    80001cd6:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cda:	17090913          	addi	s2,s2,368
    80001cde:	fb491de3          	bne	s2,s4,80001c98 <procinit+0x58>
  kvminithart();
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	768080e7          	jalr	1896(ra) # 8000144a <kvminithart>
}
    80001cea:	60a6                	ld	ra,72(sp)
    80001cec:	6406                	ld	s0,64(sp)
    80001cee:	74e2                	ld	s1,56(sp)
    80001cf0:	7942                	ld	s2,48(sp)
    80001cf2:	79a2                	ld	s3,40(sp)
    80001cf4:	7a02                	ld	s4,32(sp)
    80001cf6:	6ae2                	ld	s5,24(sp)
    80001cf8:	6b42                	ld	s6,16(sp)
    80001cfa:	6ba2                	ld	s7,8(sp)
    80001cfc:	6161                	addi	sp,sp,80
    80001cfe:	8082                	ret
        panic("kalloc");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	57050513          	addi	a0,a0,1392 # 80008270 <digits+0x230>
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	848080e7          	jalr	-1976(ra) # 80000550 <panic>

0000000080001d10 <cpuid>:
{
    80001d10:	1141                	addi	sp,sp,-16
    80001d12:	e422                	sd	s0,8(sp)
    80001d14:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d16:	8512                	mv	a0,tp
}
    80001d18:	2501                	sext.w	a0,a0
    80001d1a:	6422                	ld	s0,8(sp)
    80001d1c:	0141                	addi	sp,sp,16
    80001d1e:	8082                	ret

0000000080001d20 <mycpu>:
mycpu(void) {
    80001d20:	1141                	addi	sp,sp,-16
    80001d22:	e422                	sd	s0,8(sp)
    80001d24:	0800                	addi	s0,sp,16
    80001d26:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d28:	2781                	sext.w	a5,a5
    80001d2a:	079e                	slli	a5,a5,0x7
}
    80001d2c:	00010517          	auipc	a0,0x10
    80001d30:	67c50513          	addi	a0,a0,1660 # 800123a8 <cpus>
    80001d34:	953e                	add	a0,a0,a5
    80001d36:	6422                	ld	s0,8(sp)
    80001d38:	0141                	addi	sp,sp,16
    80001d3a:	8082                	ret

0000000080001d3c <myproc>:
myproc(void) {
    80001d3c:	1101                	addi	sp,sp,-32
    80001d3e:	ec06                	sd	ra,24(sp)
    80001d40:	e822                	sd	s0,16(sp)
    80001d42:	e426                	sd	s1,8(sp)
    80001d44:	1000                	addi	s0,sp,32
  push_off();
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	f62080e7          	jalr	-158(ra) # 80000ca8 <push_off>
    80001d4e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d50:	2781                	sext.w	a5,a5
    80001d52:	079e                	slli	a5,a5,0x7
    80001d54:	00010717          	auipc	a4,0x10
    80001d58:	63470713          	addi	a4,a4,1588 # 80012388 <pid_lock>
    80001d5c:	97ba                	add	a5,a5,a4
    80001d5e:	7384                	ld	s1,32(a5)
  pop_off();
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	004080e7          	jalr	4(ra) # 80000d64 <pop_off>
}
    80001d68:	8526                	mv	a0,s1
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6105                	addi	sp,sp,32
    80001d72:	8082                	ret

0000000080001d74 <forkret>:
{
    80001d74:	1141                	addi	sp,sp,-16
    80001d76:	e406                	sd	ra,8(sp)
    80001d78:	e022                	sd	s0,0(sp)
    80001d7a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	fc0080e7          	jalr	-64(ra) # 80001d3c <myproc>
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	040080e7          	jalr	64(ra) # 80000dc4 <release>
  if (first) {
    80001d8c:	00007797          	auipc	a5,0x7
    80001d90:	b247a783          	lw	a5,-1244(a5) # 800088b0 <first.1672>
    80001d94:	eb89                	bnez	a5,80001da6 <forkret+0x32>
  usertrapret();
    80001d96:	00001097          	auipc	ra,0x1
    80001d9a:	c1c080e7          	jalr	-996(ra) # 800029b2 <usertrapret>
}
    80001d9e:	60a2                	ld	ra,8(sp)
    80001da0:	6402                	ld	s0,0(sp)
    80001da2:	0141                	addi	sp,sp,16
    80001da4:	8082                	ret
    first = 0;
    80001da6:	00007797          	auipc	a5,0x7
    80001daa:	b007a523          	sw	zero,-1270(a5) # 800088b0 <first.1672>
    fsinit(ROOTDEV);
    80001dae:	4505                	li	a0,1
    80001db0:	00002097          	auipc	ra,0x2
    80001db4:	b3a080e7          	jalr	-1222(ra) # 800038ea <fsinit>
    80001db8:	bff9                	j	80001d96 <forkret+0x22>

0000000080001dba <allocpid>:
allocpid() {
    80001dba:	1101                	addi	sp,sp,-32
    80001dbc:	ec06                	sd	ra,24(sp)
    80001dbe:	e822                	sd	s0,16(sp)
    80001dc0:	e426                	sd	s1,8(sp)
    80001dc2:	e04a                	sd	s2,0(sp)
    80001dc4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dc6:	00010917          	auipc	s2,0x10
    80001dca:	5c290913          	addi	s2,s2,1474 # 80012388 <pid_lock>
    80001dce:	854a                	mv	a0,s2
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	f24080e7          	jalr	-220(ra) # 80000cf4 <acquire>
  pid = nextpid;
    80001dd8:	00007797          	auipc	a5,0x7
    80001ddc:	adc78793          	addi	a5,a5,-1316 # 800088b4 <nextpid>
    80001de0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001de2:	0014871b          	addiw	a4,s1,1
    80001de6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001de8:	854a                	mv	a0,s2
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	fda080e7          	jalr	-38(ra) # 80000dc4 <release>
}
    80001df2:	8526                	mv	a0,s1
    80001df4:	60e2                	ld	ra,24(sp)
    80001df6:	6442                	ld	s0,16(sp)
    80001df8:	64a2                	ld	s1,8(sp)
    80001dfa:	6902                	ld	s2,0(sp)
    80001dfc:	6105                	addi	sp,sp,32
    80001dfe:	8082                	ret

0000000080001e00 <proc_pagetable>:
{
    80001e00:	1101                	addi	sp,sp,-32
    80001e02:	ec06                	sd	ra,24(sp)
    80001e04:	e822                	sd	s0,16(sp)
    80001e06:	e426                	sd	s1,8(sp)
    80001e08:	e04a                	sd	s2,0(sp)
    80001e0a:	1000                	addi	s0,sp,32
    80001e0c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	8ea080e7          	jalr	-1814(ra) # 800016f8 <uvmcreate>
    80001e16:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e18:	c121                	beqz	a0,80001e58 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e1a:	4729                	li	a4,10
    80001e1c:	00005697          	auipc	a3,0x5
    80001e20:	1e468693          	addi	a3,a3,484 # 80007000 <_trampoline>
    80001e24:	6605                	lui	a2,0x1
    80001e26:	040005b7          	lui	a1,0x4000
    80001e2a:	15fd                	addi	a1,a1,-1
    80001e2c:	05b2                	slli	a1,a1,0xc
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	682080e7          	jalr	1666(ra) # 800014b0 <mappages>
    80001e36:	02054863          	bltz	a0,80001e66 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e3a:	4719                	li	a4,6
    80001e3c:	06093683          	ld	a3,96(s2)
    80001e40:	6605                	lui	a2,0x1
    80001e42:	020005b7          	lui	a1,0x2000
    80001e46:	15fd                	addi	a1,a1,-1
    80001e48:	05b6                	slli	a1,a1,0xd
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	664080e7          	jalr	1636(ra) # 800014b0 <mappages>
    80001e54:	02054163          	bltz	a0,80001e76 <proc_pagetable+0x76>
}
    80001e58:	8526                	mv	a0,s1
    80001e5a:	60e2                	ld	ra,24(sp)
    80001e5c:	6442                	ld	s0,16(sp)
    80001e5e:	64a2                	ld	s1,8(sp)
    80001e60:	6902                	ld	s2,0(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret
    uvmfree(pagetable, 0);
    80001e66:	4581                	li	a1,0
    80001e68:	8526                	mv	a0,s1
    80001e6a:	00000097          	auipc	ra,0x0
    80001e6e:	a8a080e7          	jalr	-1398(ra) # 800018f4 <uvmfree>
    return 0;
    80001e72:	4481                	li	s1,0
    80001e74:	b7d5                	j	80001e58 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e76:	4681                	li	a3,0
    80001e78:	4605                	li	a2,1
    80001e7a:	040005b7          	lui	a1,0x4000
    80001e7e:	15fd                	addi	a1,a1,-1
    80001e80:	05b2                	slli	a1,a1,0xc
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	7b0080e7          	jalr	1968(ra) # 80001634 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e8c:	4581                	li	a1,0
    80001e8e:	8526                	mv	a0,s1
    80001e90:	00000097          	auipc	ra,0x0
    80001e94:	a64080e7          	jalr	-1436(ra) # 800018f4 <uvmfree>
    return 0;
    80001e98:	4481                	li	s1,0
    80001e9a:	bf7d                	j	80001e58 <proc_pagetable+0x58>

0000000080001e9c <proc_freepagetable>:
{
    80001e9c:	1101                	addi	sp,sp,-32
    80001e9e:	ec06                	sd	ra,24(sp)
    80001ea0:	e822                	sd	s0,16(sp)
    80001ea2:	e426                	sd	s1,8(sp)
    80001ea4:	e04a                	sd	s2,0(sp)
    80001ea6:	1000                	addi	s0,sp,32
    80001ea8:	84aa                	mv	s1,a0
    80001eaa:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eac:	4681                	li	a3,0
    80001eae:	4605                	li	a2,1
    80001eb0:	040005b7          	lui	a1,0x4000
    80001eb4:	15fd                	addi	a1,a1,-1
    80001eb6:	05b2                	slli	a1,a1,0xc
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	77c080e7          	jalr	1916(ra) # 80001634 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ec0:	4681                	li	a3,0
    80001ec2:	4605                	li	a2,1
    80001ec4:	020005b7          	lui	a1,0x2000
    80001ec8:	15fd                	addi	a1,a1,-1
    80001eca:	05b6                	slli	a1,a1,0xd
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	766080e7          	jalr	1894(ra) # 80001634 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ed6:	85ca                	mv	a1,s2
    80001ed8:	8526                	mv	a0,s1
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	a1a080e7          	jalr	-1510(ra) # 800018f4 <uvmfree>
}
    80001ee2:	60e2                	ld	ra,24(sp)
    80001ee4:	6442                	ld	s0,16(sp)
    80001ee6:	64a2                	ld	s1,8(sp)
    80001ee8:	6902                	ld	s2,0(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret

0000000080001eee <freeproc>:
{
    80001eee:	1101                	addi	sp,sp,-32
    80001ef0:	ec06                	sd	ra,24(sp)
    80001ef2:	e822                	sd	s0,16(sp)
    80001ef4:	e426                	sd	s1,8(sp)
    80001ef6:	1000                	addi	s0,sp,32
    80001ef8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001efa:	7128                	ld	a0,96(a0)
    80001efc:	c509                	beqz	a0,80001f06 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	b2e080e7          	jalr	-1234(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f06:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f0a:	6ca8                	ld	a0,88(s1)
    80001f0c:	c511                	beqz	a0,80001f18 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f0e:	68ac                	ld	a1,80(s1)
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	f8c080e7          	jalr	-116(ra) # 80001e9c <proc_freepagetable>
  p->pagetable = 0;
    80001f18:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f1c:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f20:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f24:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f28:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f2c:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f30:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f34:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f38:	0204a023          	sw	zero,32(s1)
}
    80001f3c:	60e2                	ld	ra,24(sp)
    80001f3e:	6442                	ld	s0,16(sp)
    80001f40:	64a2                	ld	s1,8(sp)
    80001f42:	6105                	addi	sp,sp,32
    80001f44:	8082                	ret

0000000080001f46 <allocproc>:
{
    80001f46:	1101                	addi	sp,sp,-32
    80001f48:	ec06                	sd	ra,24(sp)
    80001f4a:	e822                	sd	s0,16(sp)
    80001f4c:	e426                	sd	s1,8(sp)
    80001f4e:	e04a                	sd	s2,0(sp)
    80001f50:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f52:	00011497          	auipc	s1,0x11
    80001f56:	85648493          	addi	s1,s1,-1962 # 800127a8 <proc>
    80001f5a:	00016917          	auipc	s2,0x16
    80001f5e:	44e90913          	addi	s2,s2,1102 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	d90080e7          	jalr	-624(ra) # 80000cf4 <acquire>
    if(p->state == UNUSED) {
    80001f6c:	509c                	lw	a5,32(s1)
    80001f6e:	cf81                	beqz	a5,80001f86 <allocproc+0x40>
      release(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	e52080e7          	jalr	-430(ra) # 80000dc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f7a:	17048493          	addi	s1,s1,368
    80001f7e:	ff2492e3          	bne	s1,s2,80001f62 <allocproc+0x1c>
  return 0;
    80001f82:	4481                	li	s1,0
    80001f84:	a0b9                	j	80001fd2 <allocproc+0x8c>
  p->pid = allocpid();
    80001f86:	00000097          	auipc	ra,0x0
    80001f8a:	e34080e7          	jalr	-460(ra) # 80001dba <allocpid>
    80001f8e:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	be8080e7          	jalr	-1048(ra) # 80000b78 <kalloc>
    80001f98:	892a                	mv	s2,a0
    80001f9a:	f0a8                	sd	a0,96(s1)
    80001f9c:	c131                	beqz	a0,80001fe0 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	e60080e7          	jalr	-416(ra) # 80001e00 <proc_pagetable>
    80001fa8:	892a                	mv	s2,a0
    80001faa:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001fac:	c129                	beqz	a0,80001fee <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001fae:	07000613          	li	a2,112
    80001fb2:	4581                	li	a1,0
    80001fb4:	06848513          	addi	a0,s1,104
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	11c080e7          	jalr	284(ra) # 800010d4 <memset>
  p->context.ra = (uint64)forkret;
    80001fc0:	00000797          	auipc	a5,0x0
    80001fc4:	db478793          	addi	a5,a5,-588 # 80001d74 <forkret>
    80001fc8:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fca:	64bc                	ld	a5,72(s1)
    80001fcc:	6705                	lui	a4,0x1
    80001fce:	97ba                	add	a5,a5,a4
    80001fd0:	f8bc                	sd	a5,112(s1)
}
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret
    release(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	de2080e7          	jalr	-542(ra) # 80000dc4 <release>
    return 0;
    80001fea:	84ca                	mv	s1,s2
    80001fec:	b7dd                	j	80001fd2 <allocproc+0x8c>
    freeproc(p);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	00000097          	auipc	ra,0x0
    80001ff4:	efe080e7          	jalr	-258(ra) # 80001eee <freeproc>
    release(&p->lock);
    80001ff8:	8526                	mv	a0,s1
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	dca080e7          	jalr	-566(ra) # 80000dc4 <release>
    return 0;
    80002002:	84ca                	mv	s1,s2
    80002004:	b7f9                	j	80001fd2 <allocproc+0x8c>

0000000080002006 <userinit>:
{
    80002006:	1101                	addi	sp,sp,-32
    80002008:	ec06                	sd	ra,24(sp)
    8000200a:	e822                	sd	s0,16(sp)
    8000200c:	e426                	sd	s1,8(sp)
    8000200e:	1000                	addi	s0,sp,32
  p = allocproc();
    80002010:	00000097          	auipc	ra,0x0
    80002014:	f36080e7          	jalr	-202(ra) # 80001f46 <allocproc>
    80002018:	84aa                	mv	s1,a0
  initproc = p;
    8000201a:	00007797          	auipc	a5,0x7
    8000201e:	fea7bf23          	sd	a0,-2(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002022:	03400613          	li	a2,52
    80002026:	00007597          	auipc	a1,0x7
    8000202a:	89a58593          	addi	a1,a1,-1894 # 800088c0 <initcode>
    8000202e:	6d28                	ld	a0,88(a0)
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	6f6080e7          	jalr	1782(ra) # 80001726 <uvminit>
  p->sz = PGSIZE;
    80002038:	6785                	lui	a5,0x1
    8000203a:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    8000203c:	70b8                	ld	a4,96(s1)
    8000203e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002042:	70b8                	ld	a4,96(s1)
    80002044:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002046:	4641                	li	a2,16
    80002048:	00006597          	auipc	a1,0x6
    8000204c:	23058593          	addi	a1,a1,560 # 80008278 <digits+0x238>
    80002050:	16048513          	addi	a0,s1,352
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	1d6080e7          	jalr	470(ra) # 8000122a <safestrcpy>
  p->cwd = namei("/");
    8000205c:	00006517          	auipc	a0,0x6
    80002060:	22c50513          	addi	a0,a0,556 # 80008288 <digits+0x248>
    80002064:	00002097          	auipc	ra,0x2
    80002068:	2b2080e7          	jalr	690(ra) # 80004316 <namei>
    8000206c:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80002070:	4789                	li	a5,2
    80002072:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002074:	8526                	mv	a0,s1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	d4e080e7          	jalr	-690(ra) # 80000dc4 <release>
}
    8000207e:	60e2                	ld	ra,24(sp)
    80002080:	6442                	ld	s0,16(sp)
    80002082:	64a2                	ld	s1,8(sp)
    80002084:	6105                	addi	sp,sp,32
    80002086:	8082                	ret

0000000080002088 <growproc>:
{
    80002088:	1101                	addi	sp,sp,-32
    8000208a:	ec06                	sd	ra,24(sp)
    8000208c:	e822                	sd	s0,16(sp)
    8000208e:	e426                	sd	s1,8(sp)
    80002090:	e04a                	sd	s2,0(sp)
    80002092:	1000                	addi	s0,sp,32
    80002094:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	ca6080e7          	jalr	-858(ra) # 80001d3c <myproc>
    8000209e:	892a                	mv	s2,a0
  sz = p->sz;
    800020a0:	692c                	ld	a1,80(a0)
    800020a2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800020a6:	00904f63          	bgtz	s1,800020c4 <growproc+0x3c>
  } else if(n < 0){
    800020aa:	0204cc63          	bltz	s1,800020e2 <growproc+0x5a>
  p->sz = sz;
    800020ae:	1602                	slli	a2,a2,0x20
    800020b0:	9201                	srli	a2,a2,0x20
    800020b2:	04c93823          	sd	a2,80(s2)
  return 0;
    800020b6:	4501                	li	a0,0
}
    800020b8:	60e2                	ld	ra,24(sp)
    800020ba:	6442                	ld	s0,16(sp)
    800020bc:	64a2                	ld	s1,8(sp)
    800020be:	6902                	ld	s2,0(sp)
    800020c0:	6105                	addi	sp,sp,32
    800020c2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020c4:	9e25                	addw	a2,a2,s1
    800020c6:	1602                	slli	a2,a2,0x20
    800020c8:	9201                	srli	a2,a2,0x20
    800020ca:	1582                	slli	a1,a1,0x20
    800020cc:	9181                	srli	a1,a1,0x20
    800020ce:	6d28                	ld	a0,88(a0)
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	710080e7          	jalr	1808(ra) # 800017e0 <uvmalloc>
    800020d8:	0005061b          	sext.w	a2,a0
    800020dc:	fa69                	bnez	a2,800020ae <growproc+0x26>
      return -1;
    800020de:	557d                	li	a0,-1
    800020e0:	bfe1                	j	800020b8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020e2:	9e25                	addw	a2,a2,s1
    800020e4:	1602                	slli	a2,a2,0x20
    800020e6:	9201                	srli	a2,a2,0x20
    800020e8:	1582                	slli	a1,a1,0x20
    800020ea:	9181                	srli	a1,a1,0x20
    800020ec:	6d28                	ld	a0,88(a0)
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	6aa080e7          	jalr	1706(ra) # 80001798 <uvmdealloc>
    800020f6:	0005061b          	sext.w	a2,a0
    800020fa:	bf55                	j	800020ae <growproc+0x26>

00000000800020fc <fork>:
{
    800020fc:	7179                	addi	sp,sp,-48
    800020fe:	f406                	sd	ra,40(sp)
    80002100:	f022                	sd	s0,32(sp)
    80002102:	ec26                	sd	s1,24(sp)
    80002104:	e84a                	sd	s2,16(sp)
    80002106:	e44e                	sd	s3,8(sp)
    80002108:	e052                	sd	s4,0(sp)
    8000210a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	c30080e7          	jalr	-976(ra) # 80001d3c <myproc>
    80002114:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	e30080e7          	jalr	-464(ra) # 80001f46 <allocproc>
    8000211e:	c175                	beqz	a0,80002202 <fork+0x106>
    80002120:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002122:	05093603          	ld	a2,80(s2)
    80002126:	6d2c                	ld	a1,88(a0)
    80002128:	05893503          	ld	a0,88(s2)
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	800080e7          	jalr	-2048(ra) # 8000192c <uvmcopy>
    80002134:	04054863          	bltz	a0,80002184 <fork+0x88>
  np->sz = p->sz;
    80002138:	05093783          	ld	a5,80(s2)
    8000213c:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    80002140:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    80002144:	06093683          	ld	a3,96(s2)
    80002148:	87b6                	mv	a5,a3
    8000214a:	0609b703          	ld	a4,96(s3)
    8000214e:	12068693          	addi	a3,a3,288
    80002152:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002156:	6788                	ld	a0,8(a5)
    80002158:	6b8c                	ld	a1,16(a5)
    8000215a:	6f90                	ld	a2,24(a5)
    8000215c:	01073023          	sd	a6,0(a4)
    80002160:	e708                	sd	a0,8(a4)
    80002162:	eb0c                	sd	a1,16(a4)
    80002164:	ef10                	sd	a2,24(a4)
    80002166:	02078793          	addi	a5,a5,32
    8000216a:	02070713          	addi	a4,a4,32
    8000216e:	fed792e3          	bne	a5,a3,80002152 <fork+0x56>
  np->trapframe->a0 = 0;
    80002172:	0609b783          	ld	a5,96(s3)
    80002176:	0607b823          	sd	zero,112(a5)
    8000217a:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000217e:	15800a13          	li	s4,344
    80002182:	a03d                	j	800021b0 <fork+0xb4>
    freeproc(np);
    80002184:	854e                	mv	a0,s3
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	d68080e7          	jalr	-664(ra) # 80001eee <freeproc>
    release(&np->lock);
    8000218e:	854e                	mv	a0,s3
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	c34080e7          	jalr	-972(ra) # 80000dc4 <release>
    return -1;
    80002198:	54fd                	li	s1,-1
    8000219a:	a899                	j	800021f0 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000219c:	00003097          	auipc	ra,0x3
    800021a0:	818080e7          	jalr	-2024(ra) # 800049b4 <filedup>
    800021a4:	009987b3          	add	a5,s3,s1
    800021a8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021aa:	04a1                	addi	s1,s1,8
    800021ac:	01448763          	beq	s1,s4,800021ba <fork+0xbe>
    if(p->ofile[i])
    800021b0:	009907b3          	add	a5,s2,s1
    800021b4:	6388                	ld	a0,0(a5)
    800021b6:	f17d                	bnez	a0,8000219c <fork+0xa0>
    800021b8:	bfcd                	j	800021aa <fork+0xae>
  np->cwd = idup(p->cwd);
    800021ba:	15893503          	ld	a0,344(s2)
    800021be:	00002097          	auipc	ra,0x2
    800021c2:	966080e7          	jalr	-1690(ra) # 80003b24 <idup>
    800021c6:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021ca:	4641                	li	a2,16
    800021cc:	16090593          	addi	a1,s2,352
    800021d0:	16098513          	addi	a0,s3,352
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	056080e7          	jalr	86(ra) # 8000122a <safestrcpy>
  pid = np->pid;
    800021dc:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    800021e0:	4789                	li	a5,2
    800021e2:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    800021e6:	854e                	mv	a0,s3
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	bdc080e7          	jalr	-1060(ra) # 80000dc4 <release>
}
    800021f0:	8526                	mv	a0,s1
    800021f2:	70a2                	ld	ra,40(sp)
    800021f4:	7402                	ld	s0,32(sp)
    800021f6:	64e2                	ld	s1,24(sp)
    800021f8:	6942                	ld	s2,16(sp)
    800021fa:	69a2                	ld	s3,8(sp)
    800021fc:	6a02                	ld	s4,0(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret
    return -1;
    80002202:	54fd                	li	s1,-1
    80002204:	b7f5                	j	800021f0 <fork+0xf4>

0000000080002206 <reparent>:
{
    80002206:	7179                	addi	sp,sp,-48
    80002208:	f406                	sd	ra,40(sp)
    8000220a:	f022                	sd	s0,32(sp)
    8000220c:	ec26                	sd	s1,24(sp)
    8000220e:	e84a                	sd	s2,16(sp)
    80002210:	e44e                	sd	s3,8(sp)
    80002212:	e052                	sd	s4,0(sp)
    80002214:	1800                	addi	s0,sp,48
    80002216:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002218:	00010497          	auipc	s1,0x10
    8000221c:	59048493          	addi	s1,s1,1424 # 800127a8 <proc>
      pp->parent = initproc;
    80002220:	00007a17          	auipc	s4,0x7
    80002224:	df8a0a13          	addi	s4,s4,-520 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002228:	00016997          	auipc	s3,0x16
    8000222c:	18098993          	addi	s3,s3,384 # 800183a8 <tickslock>
    80002230:	a029                	j	8000223a <reparent+0x34>
    80002232:	17048493          	addi	s1,s1,368
    80002236:	03348363          	beq	s1,s3,8000225c <reparent+0x56>
    if(pp->parent == p){
    8000223a:	749c                	ld	a5,40(s1)
    8000223c:	ff279be3          	bne	a5,s2,80002232 <reparent+0x2c>
      acquire(&pp->lock);
    80002240:	8526                	mv	a0,s1
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	ab2080e7          	jalr	-1358(ra) # 80000cf4 <acquire>
      pp->parent = initproc;
    8000224a:	000a3783          	ld	a5,0(s4)
    8000224e:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	b72080e7          	jalr	-1166(ra) # 80000dc4 <release>
    8000225a:	bfe1                	j	80002232 <reparent+0x2c>
}
    8000225c:	70a2                	ld	ra,40(sp)
    8000225e:	7402                	ld	s0,32(sp)
    80002260:	64e2                	ld	s1,24(sp)
    80002262:	6942                	ld	s2,16(sp)
    80002264:	69a2                	ld	s3,8(sp)
    80002266:	6a02                	ld	s4,0(sp)
    80002268:	6145                	addi	sp,sp,48
    8000226a:	8082                	ret

000000008000226c <scheduler>:
{
    8000226c:	711d                	addi	sp,sp,-96
    8000226e:	ec86                	sd	ra,88(sp)
    80002270:	e8a2                	sd	s0,80(sp)
    80002272:	e4a6                	sd	s1,72(sp)
    80002274:	e0ca                	sd	s2,64(sp)
    80002276:	fc4e                	sd	s3,56(sp)
    80002278:	f852                	sd	s4,48(sp)
    8000227a:	f456                	sd	s5,40(sp)
    8000227c:	f05a                	sd	s6,32(sp)
    8000227e:	ec5e                	sd	s7,24(sp)
    80002280:	e862                	sd	s8,16(sp)
    80002282:	e466                	sd	s9,8(sp)
    80002284:	1080                	addi	s0,sp,96
    80002286:	8792                	mv	a5,tp
  int id = r_tp();
    80002288:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000228a:	00779c13          	slli	s8,a5,0x7
    8000228e:	00010717          	auipc	a4,0x10
    80002292:	0fa70713          	addi	a4,a4,250 # 80012388 <pid_lock>
    80002296:	9762                	add	a4,a4,s8
    80002298:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    8000229c:	00010717          	auipc	a4,0x10
    800022a0:	11470713          	addi	a4,a4,276 # 800123b0 <cpus+0x8>
    800022a4:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800022a6:	4a89                	li	s5,2
        c->proc = p;
    800022a8:	079e                	slli	a5,a5,0x7
    800022aa:	00010b17          	auipc	s6,0x10
    800022ae:	0deb0b13          	addi	s6,s6,222 # 80012388 <pid_lock>
    800022b2:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b4:	00016a17          	auipc	s4,0x16
    800022b8:	0f4a0a13          	addi	s4,s4,244 # 800183a8 <tickslock>
    int nproc = 0;
    800022bc:	4c81                	li	s9,0
    800022be:	a8a1                	j	80002316 <scheduler+0xaa>
        p->state = RUNNING;
    800022c0:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022c4:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022c8:	06848593          	addi	a1,s1,104
    800022cc:	8562                	mv	a0,s8
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	63a080e7          	jalr	1594(ra) # 80002908 <swtch>
        c->proc = 0;
    800022d6:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	ae8080e7          	jalr	-1304(ra) # 80000dc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022e4:	17048493          	addi	s1,s1,368
    800022e8:	01448d63          	beq	s1,s4,80002302 <scheduler+0x96>
      acquire(&p->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	a06080e7          	jalr	-1530(ra) # 80000cf4 <acquire>
      if(p->state != UNUSED) {
    800022f6:	509c                	lw	a5,32(s1)
    800022f8:	d3ed                	beqz	a5,800022da <scheduler+0x6e>
        nproc++;
    800022fa:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022fc:	fd579fe3          	bne	a5,s5,800022da <scheduler+0x6e>
    80002300:	b7c1                	j	800022c0 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002302:	013aca63          	blt	s5,s3,80002316 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002306:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000230a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000230e:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002312:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002316:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000231a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000231e:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002322:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002324:	00010497          	auipc	s1,0x10
    80002328:	48448493          	addi	s1,s1,1156 # 800127a8 <proc>
        p->state = RUNNING;
    8000232c:	4b8d                	li	s7,3
    8000232e:	bf7d                	j	800022ec <scheduler+0x80>

0000000080002330 <sched>:
{
    80002330:	7179                	addi	sp,sp,-48
    80002332:	f406                	sd	ra,40(sp)
    80002334:	f022                	sd	s0,32(sp)
    80002336:	ec26                	sd	s1,24(sp)
    80002338:	e84a                	sd	s2,16(sp)
    8000233a:	e44e                	sd	s3,8(sp)
    8000233c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	9fe080e7          	jalr	-1538(ra) # 80001d3c <myproc>
    80002346:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	932080e7          	jalr	-1742(ra) # 80000c7a <holding>
    80002350:	c93d                	beqz	a0,800023c6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002352:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002354:	2781                	sext.w	a5,a5
    80002356:	079e                	slli	a5,a5,0x7
    80002358:	00010717          	auipc	a4,0x10
    8000235c:	03070713          	addi	a4,a4,48 # 80012388 <pid_lock>
    80002360:	97ba                	add	a5,a5,a4
    80002362:	0987a703          	lw	a4,152(a5)
    80002366:	4785                	li	a5,1
    80002368:	06f71763          	bne	a4,a5,800023d6 <sched+0xa6>
  if(p->state == RUNNING)
    8000236c:	5098                	lw	a4,32(s1)
    8000236e:	478d                	li	a5,3
    80002370:	06f70b63          	beq	a4,a5,800023e6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002374:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002378:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000237a:	efb5                	bnez	a5,800023f6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000237c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000237e:	00010917          	auipc	s2,0x10
    80002382:	00a90913          	addi	s2,s2,10 # 80012388 <pid_lock>
    80002386:	2781                	sext.w	a5,a5
    80002388:	079e                	slli	a5,a5,0x7
    8000238a:	97ca                	add	a5,a5,s2
    8000238c:	09c7a983          	lw	s3,156(a5)
    80002390:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002392:	2781                	sext.w	a5,a5
    80002394:	079e                	slli	a5,a5,0x7
    80002396:	00010597          	auipc	a1,0x10
    8000239a:	01a58593          	addi	a1,a1,26 # 800123b0 <cpus+0x8>
    8000239e:	95be                	add	a1,a1,a5
    800023a0:	06848513          	addi	a0,s1,104
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	564080e7          	jalr	1380(ra) # 80002908 <swtch>
    800023ac:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023ae:	2781                	sext.w	a5,a5
    800023b0:	079e                	slli	a5,a5,0x7
    800023b2:	97ca                	add	a5,a5,s2
    800023b4:	0937ae23          	sw	s3,156(a5)
}
    800023b8:	70a2                	ld	ra,40(sp)
    800023ba:	7402                	ld	s0,32(sp)
    800023bc:	64e2                	ld	s1,24(sp)
    800023be:	6942                	ld	s2,16(sp)
    800023c0:	69a2                	ld	s3,8(sp)
    800023c2:	6145                	addi	sp,sp,48
    800023c4:	8082                	ret
    panic("sched p->lock");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	eca50513          	addi	a0,a0,-310 # 80008290 <digits+0x250>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	182080e7          	jalr	386(ra) # 80000550 <panic>
    panic("sched locks");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	eca50513          	addi	a0,a0,-310 # 800082a0 <digits+0x260>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	172080e7          	jalr	370(ra) # 80000550 <panic>
    panic("sched running");
    800023e6:	00006517          	auipc	a0,0x6
    800023ea:	eca50513          	addi	a0,a0,-310 # 800082b0 <digits+0x270>
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	162080e7          	jalr	354(ra) # 80000550 <panic>
    panic("sched interruptible");
    800023f6:	00006517          	auipc	a0,0x6
    800023fa:	eca50513          	addi	a0,a0,-310 # 800082c0 <digits+0x280>
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	152080e7          	jalr	338(ra) # 80000550 <panic>

0000000080002406 <exit>:
{
    80002406:	7179                	addi	sp,sp,-48
    80002408:	f406                	sd	ra,40(sp)
    8000240a:	f022                	sd	s0,32(sp)
    8000240c:	ec26                	sd	s1,24(sp)
    8000240e:	e84a                	sd	s2,16(sp)
    80002410:	e44e                	sd	s3,8(sp)
    80002412:	e052                	sd	s4,0(sp)
    80002414:	1800                	addi	s0,sp,48
    80002416:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	924080e7          	jalr	-1756(ra) # 80001d3c <myproc>
    80002420:	89aa                	mv	s3,a0
  if(p == initproc)
    80002422:	00007797          	auipc	a5,0x7
    80002426:	bf67b783          	ld	a5,-1034(a5) # 80009018 <initproc>
    8000242a:	0d850493          	addi	s1,a0,216
    8000242e:	15850913          	addi	s2,a0,344
    80002432:	02a79363          	bne	a5,a0,80002458 <exit+0x52>
    panic("init exiting");
    80002436:	00006517          	auipc	a0,0x6
    8000243a:	ea250513          	addi	a0,a0,-350 # 800082d8 <digits+0x298>
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	112080e7          	jalr	274(ra) # 80000550 <panic>
      fileclose(f);
    80002446:	00002097          	auipc	ra,0x2
    8000244a:	5c0080e7          	jalr	1472(ra) # 80004a06 <fileclose>
      p->ofile[fd] = 0;
    8000244e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002452:	04a1                	addi	s1,s1,8
    80002454:	01248563          	beq	s1,s2,8000245e <exit+0x58>
    if(p->ofile[fd]){
    80002458:	6088                	ld	a0,0(s1)
    8000245a:	f575                	bnez	a0,80002446 <exit+0x40>
    8000245c:	bfdd                	j	80002452 <exit+0x4c>
  begin_op();
    8000245e:	00002097          	auipc	ra,0x2
    80002462:	0d4080e7          	jalr	212(ra) # 80004532 <begin_op>
  iput(p->cwd);
    80002466:	1589b503          	ld	a0,344(s3)
    8000246a:	00002097          	auipc	ra,0x2
    8000246e:	8b2080e7          	jalr	-1870(ra) # 80003d1c <iput>
  end_op();
    80002472:	00002097          	auipc	ra,0x2
    80002476:	140080e7          	jalr	320(ra) # 800045b2 <end_op>
  p->cwd = 0;
    8000247a:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000247e:	00007497          	auipc	s1,0x7
    80002482:	b9a48493          	addi	s1,s1,-1126 # 80009018 <initproc>
    80002486:	6088                	ld	a0,0(s1)
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	86c080e7          	jalr	-1940(ra) # 80000cf4 <acquire>
  wakeup1(initproc);
    80002490:	6088                	ld	a0,0(s1)
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	76a080e7          	jalr	1898(ra) # 80001bfc <wakeup1>
  release(&initproc->lock);
    8000249a:	6088                	ld	a0,0(s1)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	928080e7          	jalr	-1752(ra) # 80000dc4 <release>
  acquire(&p->lock);
    800024a4:	854e                	mv	a0,s3
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	84e080e7          	jalr	-1970(ra) # 80000cf4 <acquire>
  struct proc *original_parent = p->parent;
    800024ae:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024b2:	854e                	mv	a0,s3
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	910080e7          	jalr	-1776(ra) # 80000dc4 <release>
  acquire(&original_parent->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	836080e7          	jalr	-1994(ra) # 80000cf4 <acquire>
  acquire(&p->lock);
    800024c6:	854e                	mv	a0,s3
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	82c080e7          	jalr	-2004(ra) # 80000cf4 <acquire>
  reparent(p);
    800024d0:	854e                	mv	a0,s3
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	d34080e7          	jalr	-716(ra) # 80002206 <reparent>
  wakeup1(original_parent);
    800024da:	8526                	mv	a0,s1
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	720080e7          	jalr	1824(ra) # 80001bfc <wakeup1>
  p->xstate = status;
    800024e4:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024e8:	4791                	li	a5,4
    800024ea:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	8d4080e7          	jalr	-1836(ra) # 80000dc4 <release>
  sched();
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	e38080e7          	jalr	-456(ra) # 80002330 <sched>
  panic("zombie exit");
    80002500:	00006517          	auipc	a0,0x6
    80002504:	de850513          	addi	a0,a0,-536 # 800082e8 <digits+0x2a8>
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	048080e7          	jalr	72(ra) # 80000550 <panic>

0000000080002510 <yield>:
{
    80002510:	1101                	addi	sp,sp,-32
    80002512:	ec06                	sd	ra,24(sp)
    80002514:	e822                	sd	s0,16(sp)
    80002516:	e426                	sd	s1,8(sp)
    80002518:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	822080e7          	jalr	-2014(ra) # 80001d3c <myproc>
    80002522:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	7d0080e7          	jalr	2000(ra) # 80000cf4 <acquire>
  p->state = RUNNABLE;
    8000252c:	4789                	li	a5,2
    8000252e:	d09c                	sw	a5,32(s1)
  sched();
    80002530:	00000097          	auipc	ra,0x0
    80002534:	e00080e7          	jalr	-512(ra) # 80002330 <sched>
  release(&p->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	88a080e7          	jalr	-1910(ra) # 80000dc4 <release>
}
    80002542:	60e2                	ld	ra,24(sp)
    80002544:	6442                	ld	s0,16(sp)
    80002546:	64a2                	ld	s1,8(sp)
    80002548:	6105                	addi	sp,sp,32
    8000254a:	8082                	ret

000000008000254c <sleep>:
{
    8000254c:	7179                	addi	sp,sp,-48
    8000254e:	f406                	sd	ra,40(sp)
    80002550:	f022                	sd	s0,32(sp)
    80002552:	ec26                	sd	s1,24(sp)
    80002554:	e84a                	sd	s2,16(sp)
    80002556:	e44e                	sd	s3,8(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	89aa                	mv	s3,a0
    8000255c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	7de080e7          	jalr	2014(ra) # 80001d3c <myproc>
    80002566:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002568:	05250663          	beq	a0,s2,800025b4 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	788080e7          	jalr	1928(ra) # 80000cf4 <acquire>
    release(lk);
    80002574:	854a                	mv	a0,s2
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	84e080e7          	jalr	-1970(ra) # 80000dc4 <release>
  p->chan = chan;
    8000257e:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002582:	4785                	li	a5,1
    80002584:	d09c                	sw	a5,32(s1)
  sched();
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	daa080e7          	jalr	-598(ra) # 80002330 <sched>
  p->chan = 0;
    8000258e:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002592:	8526                	mv	a0,s1
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	830080e7          	jalr	-2000(ra) # 80000dc4 <release>
    acquire(lk);
    8000259c:	854a                	mv	a0,s2
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	756080e7          	jalr	1878(ra) # 80000cf4 <acquire>
}
    800025a6:	70a2                	ld	ra,40(sp)
    800025a8:	7402                	ld	s0,32(sp)
    800025aa:	64e2                	ld	s1,24(sp)
    800025ac:	6942                	ld	s2,16(sp)
    800025ae:	69a2                	ld	s3,8(sp)
    800025b0:	6145                	addi	sp,sp,48
    800025b2:	8082                	ret
  p->chan = chan;
    800025b4:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025b8:	4785                	li	a5,1
    800025ba:	d11c                	sw	a5,32(a0)
  sched();
    800025bc:	00000097          	auipc	ra,0x0
    800025c0:	d74080e7          	jalr	-652(ra) # 80002330 <sched>
  p->chan = 0;
    800025c4:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025c8:	bff9                	j	800025a6 <sleep+0x5a>

00000000800025ca <wait>:
{
    800025ca:	715d                	addi	sp,sp,-80
    800025cc:	e486                	sd	ra,72(sp)
    800025ce:	e0a2                	sd	s0,64(sp)
    800025d0:	fc26                	sd	s1,56(sp)
    800025d2:	f84a                	sd	s2,48(sp)
    800025d4:	f44e                	sd	s3,40(sp)
    800025d6:	f052                	sd	s4,32(sp)
    800025d8:	ec56                	sd	s5,24(sp)
    800025da:	e85a                	sd	s6,16(sp)
    800025dc:	e45e                	sd	s7,8(sp)
    800025de:	e062                	sd	s8,0(sp)
    800025e0:	0880                	addi	s0,sp,80
    800025e2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	758080e7          	jalr	1880(ra) # 80001d3c <myproc>
    800025ec:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025ee:	8c2a                	mv	s8,a0
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	704080e7          	jalr	1796(ra) # 80000cf4 <acquire>
    havekids = 0;
    800025f8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025fa:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800025fc:	00016997          	auipc	s3,0x16
    80002600:	dac98993          	addi	s3,s3,-596 # 800183a8 <tickslock>
        havekids = 1;
    80002604:	4a85                	li	s5,1
    havekids = 0;
    80002606:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002608:	00010497          	auipc	s1,0x10
    8000260c:	1a048493          	addi	s1,s1,416 # 800127a8 <proc>
    80002610:	a08d                	j	80002672 <wait+0xa8>
          pid = np->pid;
    80002612:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002616:	000b0e63          	beqz	s6,80002632 <wait+0x68>
    8000261a:	4691                	li	a3,4
    8000261c:	03c48613          	addi	a2,s1,60
    80002620:	85da                	mv	a1,s6
    80002622:	05893503          	ld	a0,88(s2)
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	40a080e7          	jalr	1034(ra) # 80001a30 <copyout>
    8000262e:	02054263          	bltz	a0,80002652 <wait+0x88>
          freeproc(np);
    80002632:	8526                	mv	a0,s1
    80002634:	00000097          	auipc	ra,0x0
    80002638:	8ba080e7          	jalr	-1862(ra) # 80001eee <freeproc>
          release(&np->lock);
    8000263c:	8526                	mv	a0,s1
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	786080e7          	jalr	1926(ra) # 80000dc4 <release>
          release(&p->lock);
    80002646:	854a                	mv	a0,s2
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	77c080e7          	jalr	1916(ra) # 80000dc4 <release>
          return pid;
    80002650:	a8a9                	j	800026aa <wait+0xe0>
            release(&np->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	770080e7          	jalr	1904(ra) # 80000dc4 <release>
            release(&p->lock);
    8000265c:	854a                	mv	a0,s2
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	766080e7          	jalr	1894(ra) # 80000dc4 <release>
            return -1;
    80002666:	59fd                	li	s3,-1
    80002668:	a089                	j	800026aa <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000266a:	17048493          	addi	s1,s1,368
    8000266e:	03348463          	beq	s1,s3,80002696 <wait+0xcc>
      if(np->parent == p){
    80002672:	749c                	ld	a5,40(s1)
    80002674:	ff279be3          	bne	a5,s2,8000266a <wait+0xa0>
        acquire(&np->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	67a080e7          	jalr	1658(ra) # 80000cf4 <acquire>
        if(np->state == ZOMBIE){
    80002682:	509c                	lw	a5,32(s1)
    80002684:	f94787e3          	beq	a5,s4,80002612 <wait+0x48>
        release(&np->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	73a080e7          	jalr	1850(ra) # 80000dc4 <release>
        havekids = 1;
    80002692:	8756                	mv	a4,s5
    80002694:	bfd9                	j	8000266a <wait+0xa0>
    if(!havekids || p->killed){
    80002696:	c701                	beqz	a4,8000269e <wait+0xd4>
    80002698:	03892783          	lw	a5,56(s2)
    8000269c:	c785                	beqz	a5,800026c4 <wait+0xfa>
      release(&p->lock);
    8000269e:	854a                	mv	a0,s2
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	724080e7          	jalr	1828(ra) # 80000dc4 <release>
      return -1;
    800026a8:	59fd                	li	s3,-1
}
    800026aa:	854e                	mv	a0,s3
    800026ac:	60a6                	ld	ra,72(sp)
    800026ae:	6406                	ld	s0,64(sp)
    800026b0:	74e2                	ld	s1,56(sp)
    800026b2:	7942                	ld	s2,48(sp)
    800026b4:	79a2                	ld	s3,40(sp)
    800026b6:	7a02                	ld	s4,32(sp)
    800026b8:	6ae2                	ld	s5,24(sp)
    800026ba:	6b42                	ld	s6,16(sp)
    800026bc:	6ba2                	ld	s7,8(sp)
    800026be:	6c02                	ld	s8,0(sp)
    800026c0:	6161                	addi	sp,sp,80
    800026c2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026c4:	85e2                	mv	a1,s8
    800026c6:	854a                	mv	a0,s2
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	e84080e7          	jalr	-380(ra) # 8000254c <sleep>
    havekids = 0;
    800026d0:	bf1d                	j	80002606 <wait+0x3c>

00000000800026d2 <wakeup>:
{
    800026d2:	7139                	addi	sp,sp,-64
    800026d4:	fc06                	sd	ra,56(sp)
    800026d6:	f822                	sd	s0,48(sp)
    800026d8:	f426                	sd	s1,40(sp)
    800026da:	f04a                	sd	s2,32(sp)
    800026dc:	ec4e                	sd	s3,24(sp)
    800026de:	e852                	sd	s4,16(sp)
    800026e0:	e456                	sd	s5,8(sp)
    800026e2:	0080                	addi	s0,sp,64
    800026e4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e6:	00010497          	auipc	s1,0x10
    800026ea:	0c248493          	addi	s1,s1,194 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026ee:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026f0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f2:	00016917          	auipc	s2,0x16
    800026f6:	cb690913          	addi	s2,s2,-842 # 800183a8 <tickslock>
    800026fa:	a821                	j	80002712 <wakeup+0x40>
      p->state = RUNNABLE;
    800026fc:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    80002700:	8526                	mv	a0,s1
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	6c2080e7          	jalr	1730(ra) # 80000dc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000270a:	17048493          	addi	s1,s1,368
    8000270e:	01248e63          	beq	s1,s2,8000272a <wakeup+0x58>
    acquire(&p->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	5e0080e7          	jalr	1504(ra) # 80000cf4 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000271c:	509c                	lw	a5,32(s1)
    8000271e:	ff3791e3          	bne	a5,s3,80002700 <wakeup+0x2e>
    80002722:	789c                	ld	a5,48(s1)
    80002724:	fd479ee3          	bne	a5,s4,80002700 <wakeup+0x2e>
    80002728:	bfd1                	j	800026fc <wakeup+0x2a>
}
    8000272a:	70e2                	ld	ra,56(sp)
    8000272c:	7442                	ld	s0,48(sp)
    8000272e:	74a2                	ld	s1,40(sp)
    80002730:	7902                	ld	s2,32(sp)
    80002732:	69e2                	ld	s3,24(sp)
    80002734:	6a42                	ld	s4,16(sp)
    80002736:	6aa2                	ld	s5,8(sp)
    80002738:	6121                	addi	sp,sp,64
    8000273a:	8082                	ret

000000008000273c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000273c:	7179                	addi	sp,sp,-48
    8000273e:	f406                	sd	ra,40(sp)
    80002740:	f022                	sd	s0,32(sp)
    80002742:	ec26                	sd	s1,24(sp)
    80002744:	e84a                	sd	s2,16(sp)
    80002746:	e44e                	sd	s3,8(sp)
    80002748:	1800                	addi	s0,sp,48
    8000274a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000274c:	00010497          	auipc	s1,0x10
    80002750:	05c48493          	addi	s1,s1,92 # 800127a8 <proc>
    80002754:	00016997          	auipc	s3,0x16
    80002758:	c5498993          	addi	s3,s3,-940 # 800183a8 <tickslock>
    acquire(&p->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	596080e7          	jalr	1430(ra) # 80000cf4 <acquire>
    if(p->pid == pid){
    80002766:	40bc                	lw	a5,64(s1)
    80002768:	01278d63          	beq	a5,s2,80002782 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000276c:	8526                	mv	a0,s1
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	656080e7          	jalr	1622(ra) # 80000dc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002776:	17048493          	addi	s1,s1,368
    8000277a:	ff3491e3          	bne	s1,s3,8000275c <kill+0x20>
  }
  return -1;
    8000277e:	557d                	li	a0,-1
    80002780:	a829                	j	8000279a <kill+0x5e>
      p->killed = 1;
    80002782:	4785                	li	a5,1
    80002784:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002786:	5098                	lw	a4,32(s1)
    80002788:	4785                	li	a5,1
    8000278a:	00f70f63          	beq	a4,a5,800027a8 <kill+0x6c>
      release(&p->lock);
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	634080e7          	jalr	1588(ra) # 80000dc4 <release>
      return 0;
    80002798:	4501                	li	a0,0
}
    8000279a:	70a2                	ld	ra,40(sp)
    8000279c:	7402                	ld	s0,32(sp)
    8000279e:	64e2                	ld	s1,24(sp)
    800027a0:	6942                	ld	s2,16(sp)
    800027a2:	69a2                	ld	s3,8(sp)
    800027a4:	6145                	addi	sp,sp,48
    800027a6:	8082                	ret
        p->state = RUNNABLE;
    800027a8:	4789                	li	a5,2
    800027aa:	d09c                	sw	a5,32(s1)
    800027ac:	b7cd                	j	8000278e <kill+0x52>

00000000800027ae <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ae:	7179                	addi	sp,sp,-48
    800027b0:	f406                	sd	ra,40(sp)
    800027b2:	f022                	sd	s0,32(sp)
    800027b4:	ec26                	sd	s1,24(sp)
    800027b6:	e84a                	sd	s2,16(sp)
    800027b8:	e44e                	sd	s3,8(sp)
    800027ba:	e052                	sd	s4,0(sp)
    800027bc:	1800                	addi	s0,sp,48
    800027be:	84aa                	mv	s1,a0
    800027c0:	892e                	mv	s2,a1
    800027c2:	89b2                	mv	s3,a2
    800027c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	576080e7          	jalr	1398(ra) # 80001d3c <myproc>
  if(user_dst){
    800027ce:	c08d                	beqz	s1,800027f0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027d0:	86d2                	mv	a3,s4
    800027d2:	864e                	mv	a2,s3
    800027d4:	85ca                	mv	a1,s2
    800027d6:	6d28                	ld	a0,88(a0)
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	258080e7          	jalr	600(ra) # 80001a30 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027e0:	70a2                	ld	ra,40(sp)
    800027e2:	7402                	ld	s0,32(sp)
    800027e4:	64e2                	ld	s1,24(sp)
    800027e6:	6942                	ld	s2,16(sp)
    800027e8:	69a2                	ld	s3,8(sp)
    800027ea:	6a02                	ld	s4,0(sp)
    800027ec:	6145                	addi	sp,sp,48
    800027ee:	8082                	ret
    memmove((char *)dst, src, len);
    800027f0:	000a061b          	sext.w	a2,s4
    800027f4:	85ce                	mv	a1,s3
    800027f6:	854a                	mv	a0,s2
    800027f8:	fffff097          	auipc	ra,0xfffff
    800027fc:	93c080e7          	jalr	-1732(ra) # 80001134 <memmove>
    return 0;
    80002800:	8526                	mv	a0,s1
    80002802:	bff9                	j	800027e0 <either_copyout+0x32>

0000000080002804 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002804:	7179                	addi	sp,sp,-48
    80002806:	f406                	sd	ra,40(sp)
    80002808:	f022                	sd	s0,32(sp)
    8000280a:	ec26                	sd	s1,24(sp)
    8000280c:	e84a                	sd	s2,16(sp)
    8000280e:	e44e                	sd	s3,8(sp)
    80002810:	e052                	sd	s4,0(sp)
    80002812:	1800                	addi	s0,sp,48
    80002814:	892a                	mv	s2,a0
    80002816:	84ae                	mv	s1,a1
    80002818:	89b2                	mv	s3,a2
    8000281a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	520080e7          	jalr	1312(ra) # 80001d3c <myproc>
  if(user_src){
    80002824:	c08d                	beqz	s1,80002846 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002826:	86d2                	mv	a3,s4
    80002828:	864e                	mv	a2,s3
    8000282a:	85ca                	mv	a1,s2
    8000282c:	6d28                	ld	a0,88(a0)
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	28e080e7          	jalr	654(ra) # 80001abc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002836:	70a2                	ld	ra,40(sp)
    80002838:	7402                	ld	s0,32(sp)
    8000283a:	64e2                	ld	s1,24(sp)
    8000283c:	6942                	ld	s2,16(sp)
    8000283e:	69a2                	ld	s3,8(sp)
    80002840:	6a02                	ld	s4,0(sp)
    80002842:	6145                	addi	sp,sp,48
    80002844:	8082                	ret
    memmove(dst, (char*)src, len);
    80002846:	000a061b          	sext.w	a2,s4
    8000284a:	85ce                	mv	a1,s3
    8000284c:	854a                	mv	a0,s2
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	8e6080e7          	jalr	-1818(ra) # 80001134 <memmove>
    return 0;
    80002856:	8526                	mv	a0,s1
    80002858:	bff9                	j	80002836 <either_copyin+0x32>

000000008000285a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000285a:	715d                	addi	sp,sp,-80
    8000285c:	e486                	sd	ra,72(sp)
    8000285e:	e0a2                	sd	s0,64(sp)
    80002860:	fc26                	sd	s1,56(sp)
    80002862:	f84a                	sd	s2,48(sp)
    80002864:	f44e                	sd	s3,40(sp)
    80002866:	f052                	sd	s4,32(sp)
    80002868:	ec56                	sd	s5,24(sp)
    8000286a:	e85a                	sd	s6,16(sp)
    8000286c:	e45e                	sd	s7,8(sp)
    8000286e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002870:	00006517          	auipc	a0,0x6
    80002874:	8f050513          	addi	a0,a0,-1808 # 80008160 <digits+0x120>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d22080e7          	jalr	-734(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002880:	00010497          	auipc	s1,0x10
    80002884:	08848493          	addi	s1,s1,136 # 80012908 <proc+0x160>
    80002888:	00016917          	auipc	s2,0x16
    8000288c:	c8090913          	addi	s2,s2,-896 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002890:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002892:	00006997          	auipc	s3,0x6
    80002896:	a6698993          	addi	s3,s3,-1434 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    8000289a:	00006a97          	auipc	s5,0x6
    8000289e:	a66a8a93          	addi	s5,s5,-1434 # 80008300 <digits+0x2c0>
    printf("\n");
    800028a2:	00006a17          	auipc	s4,0x6
    800028a6:	8bea0a13          	addi	s4,s4,-1858 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028aa:	00006b97          	auipc	s7,0x6
    800028ae:	a8eb8b93          	addi	s7,s7,-1394 # 80008338 <states.1712>
    800028b2:	a00d                	j	800028d4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028b4:	ee06a583          	lw	a1,-288(a3)
    800028b8:	8556                	mv	a0,s5
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	ce0080e7          	jalr	-800(ra) # 8000059a <printf>
    printf("\n");
    800028c2:	8552                	mv	a0,s4
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	cd6080e7          	jalr	-810(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028cc:	17048493          	addi	s1,s1,368
    800028d0:	03248163          	beq	s1,s2,800028f2 <procdump+0x98>
    if(p->state == UNUSED)
    800028d4:	86a6                	mv	a3,s1
    800028d6:	ec04a783          	lw	a5,-320(s1)
    800028da:	dbed                	beqz	a5,800028cc <procdump+0x72>
      state = "???";
    800028dc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028de:	fcfb6be3          	bltu	s6,a5,800028b4 <procdump+0x5a>
    800028e2:	1782                	slli	a5,a5,0x20
    800028e4:	9381                	srli	a5,a5,0x20
    800028e6:	078e                	slli	a5,a5,0x3
    800028e8:	97de                	add	a5,a5,s7
    800028ea:	6390                	ld	a2,0(a5)
    800028ec:	f661                	bnez	a2,800028b4 <procdump+0x5a>
      state = "???";
    800028ee:	864e                	mv	a2,s3
    800028f0:	b7d1                	j	800028b4 <procdump+0x5a>
  }
}
    800028f2:	60a6                	ld	ra,72(sp)
    800028f4:	6406                	ld	s0,64(sp)
    800028f6:	74e2                	ld	s1,56(sp)
    800028f8:	7942                	ld	s2,48(sp)
    800028fa:	79a2                	ld	s3,40(sp)
    800028fc:	7a02                	ld	s4,32(sp)
    800028fe:	6ae2                	ld	s5,24(sp)
    80002900:	6b42                	ld	s6,16(sp)
    80002902:	6ba2                	ld	s7,8(sp)
    80002904:	6161                	addi	sp,sp,80
    80002906:	8082                	ret

0000000080002908 <swtch>:
    80002908:	00153023          	sd	ra,0(a0)
    8000290c:	00253423          	sd	sp,8(a0)
    80002910:	e900                	sd	s0,16(a0)
    80002912:	ed04                	sd	s1,24(a0)
    80002914:	03253023          	sd	s2,32(a0)
    80002918:	03353423          	sd	s3,40(a0)
    8000291c:	03453823          	sd	s4,48(a0)
    80002920:	03553c23          	sd	s5,56(a0)
    80002924:	05653023          	sd	s6,64(a0)
    80002928:	05753423          	sd	s7,72(a0)
    8000292c:	05853823          	sd	s8,80(a0)
    80002930:	05953c23          	sd	s9,88(a0)
    80002934:	07a53023          	sd	s10,96(a0)
    80002938:	07b53423          	sd	s11,104(a0)
    8000293c:	0005b083          	ld	ra,0(a1)
    80002940:	0085b103          	ld	sp,8(a1)
    80002944:	6980                	ld	s0,16(a1)
    80002946:	6d84                	ld	s1,24(a1)
    80002948:	0205b903          	ld	s2,32(a1)
    8000294c:	0285b983          	ld	s3,40(a1)
    80002950:	0305ba03          	ld	s4,48(a1)
    80002954:	0385ba83          	ld	s5,56(a1)
    80002958:	0405bb03          	ld	s6,64(a1)
    8000295c:	0485bb83          	ld	s7,72(a1)
    80002960:	0505bc03          	ld	s8,80(a1)
    80002964:	0585bc83          	ld	s9,88(a1)
    80002968:	0605bd03          	ld	s10,96(a1)
    8000296c:	0685bd83          	ld	s11,104(a1)
    80002970:	8082                	ret

0000000080002972 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002972:	1141                	addi	sp,sp,-16
    80002974:	e406                	sd	ra,8(sp)
    80002976:	e022                	sd	s0,0(sp)
    80002978:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000297a:	00006597          	auipc	a1,0x6
    8000297e:	9e658593          	addi	a1,a1,-1562 # 80008360 <states.1712+0x28>
    80002982:	00016517          	auipc	a0,0x16
    80002986:	a2650513          	addi	a0,a0,-1498 # 800183a8 <tickslock>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	4e6080e7          	jalr	1254(ra) # 80000e70 <initlock>
}
    80002992:	60a2                	ld	ra,8(sp)
    80002994:	6402                	ld	s0,0(sp)
    80002996:	0141                	addi	sp,sp,16
    80002998:	8082                	ret

000000008000299a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000299a:	1141                	addi	sp,sp,-16
    8000299c:	e422                	sd	s0,8(sp)
    8000299e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a0:	00003797          	auipc	a5,0x3
    800029a4:	6e078793          	addi	a5,a5,1760 # 80006080 <kernelvec>
    800029a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029ac:	6422                	ld	s0,8(sp)
    800029ae:	0141                	addi	sp,sp,16
    800029b0:	8082                	ret

00000000800029b2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e406                	sd	ra,8(sp)
    800029b6:	e022                	sd	s0,0(sp)
    800029b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	382080e7          	jalr	898(ra) # 80001d3c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029cc:	00004617          	auipc	a2,0x4
    800029d0:	63460613          	addi	a2,a2,1588 # 80007000 <_trampoline>
    800029d4:	00004697          	auipc	a3,0x4
    800029d8:	62c68693          	addi	a3,a3,1580 # 80007000 <_trampoline>
    800029dc:	8e91                	sub	a3,a3,a2
    800029de:	040007b7          	lui	a5,0x4000
    800029e2:	17fd                	addi	a5,a5,-1
    800029e4:	07b2                	slli	a5,a5,0xc
    800029e6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ec:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029ee:	180026f3          	csrr	a3,satp
    800029f2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029f4:	7138                	ld	a4,96(a0)
    800029f6:	6534                	ld	a3,72(a0)
    800029f8:	6585                	lui	a1,0x1
    800029fa:	96ae                	add	a3,a3,a1
    800029fc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029fe:	7138                	ld	a4,96(a0)
    80002a00:	00000697          	auipc	a3,0x0
    80002a04:	13868693          	addi	a3,a3,312 # 80002b38 <usertrap>
    80002a08:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a0a:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a0c:	8692                	mv	a3,tp
    80002a0e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a10:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a14:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a18:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a20:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a22:	6f18                	ld	a4,24(a4)
    80002a24:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a28:	6d2c                	ld	a1,88(a0)
    80002a2a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a2c:	00004717          	auipc	a4,0x4
    80002a30:	66470713          	addi	a4,a4,1636 # 80007090 <userret>
    80002a34:	8f11                	sub	a4,a4,a2
    80002a36:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a38:	577d                	li	a4,-1
    80002a3a:	177e                	slli	a4,a4,0x3f
    80002a3c:	8dd9                	or	a1,a1,a4
    80002a3e:	02000537          	lui	a0,0x2000
    80002a42:	157d                	addi	a0,a0,-1
    80002a44:	0536                	slli	a0,a0,0xd
    80002a46:	9782                	jalr	a5
}
    80002a48:	60a2                	ld	ra,8(sp)
    80002a4a:	6402                	ld	s0,0(sp)
    80002a4c:	0141                	addi	sp,sp,16
    80002a4e:	8082                	ret

0000000080002a50 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a50:	1101                	addi	sp,sp,-32
    80002a52:	ec06                	sd	ra,24(sp)
    80002a54:	e822                	sd	s0,16(sp)
    80002a56:	e426                	sd	s1,8(sp)
    80002a58:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a5a:	00016497          	auipc	s1,0x16
    80002a5e:	94e48493          	addi	s1,s1,-1714 # 800183a8 <tickslock>
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	290080e7          	jalr	656(ra) # 80000cf4 <acquire>
  ticks++;
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	5b450513          	addi	a0,a0,1460 # 80009020 <ticks>
    80002a74:	411c                	lw	a5,0(a0)
    80002a76:	2785                	addiw	a5,a5,1
    80002a78:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	c58080e7          	jalr	-936(ra) # 800026d2 <wakeup>
  release(&tickslock);
    80002a82:	8526                	mv	a0,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	340080e7          	jalr	832(ra) # 80000dc4 <release>
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aa4:	00074d63          	bltz	a4,80002abe <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aa8:	57fd                	li	a5,-1
    80002aaa:	17fe                	slli	a5,a5,0x3f
    80002aac:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aae:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ab0:	06f70363          	beq	a4,a5,80002b16 <devintr+0x80>
  }
}
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6105                	addi	sp,sp,32
    80002abc:	8082                	ret
     (scause & 0xff) == 9){
    80002abe:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ac2:	46a5                	li	a3,9
    80002ac4:	fed792e3          	bne	a5,a3,80002aa8 <devintr+0x12>
    int irq = plic_claim();
    80002ac8:	00003097          	auipc	ra,0x3
    80002acc:	6c0080e7          	jalr	1728(ra) # 80006188 <plic_claim>
    80002ad0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ad2:	47a9                	li	a5,10
    80002ad4:	02f50763          	beq	a0,a5,80002b02 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ad8:	4785                	li	a5,1
    80002ada:	02f50963          	beq	a0,a5,80002b0c <devintr+0x76>
    return 1;
    80002ade:	4505                	li	a0,1
    } else if(irq){
    80002ae0:	d8f1                	beqz	s1,80002ab4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ae2:	85a6                	mv	a1,s1
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	88450513          	addi	a0,a0,-1916 # 80008368 <states.1712+0x30>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	aae080e7          	jalr	-1362(ra) # 8000059a <printf>
      plic_complete(irq);
    80002af4:	8526                	mv	a0,s1
    80002af6:	00003097          	auipc	ra,0x3
    80002afa:	6b6080e7          	jalr	1718(ra) # 800061ac <plic_complete>
    return 1;
    80002afe:	4505                	li	a0,1
    80002b00:	bf55                	j	80002ab4 <devintr+0x1e>
      uartintr();
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	eda080e7          	jalr	-294(ra) # 800009dc <uartintr>
    80002b0a:	b7ed                	j	80002af4 <devintr+0x5e>
      virtio_disk_intr();
    80002b0c:	00004097          	auipc	ra,0x4
    80002b10:	b80080e7          	jalr	-1152(ra) # 8000668c <virtio_disk_intr>
    80002b14:	b7c5                	j	80002af4 <devintr+0x5e>
    if(cpuid() == 0){
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	1fa080e7          	jalr	506(ra) # 80001d10 <cpuid>
    80002b1e:	c901                	beqz	a0,80002b2e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b20:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b24:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b26:	14479073          	csrw	sip,a5
    return 2;
    80002b2a:	4509                	li	a0,2
    80002b2c:	b761                	j	80002ab4 <devintr+0x1e>
      clockintr();
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	f22080e7          	jalr	-222(ra) # 80002a50 <clockintr>
    80002b36:	b7ed                	j	80002b20 <devintr+0x8a>

0000000080002b38 <usertrap>:
{
    80002b38:	1101                	addi	sp,sp,-32
    80002b3a:	ec06                	sd	ra,24(sp)
    80002b3c:	e822                	sd	s0,16(sp)
    80002b3e:	e426                	sd	s1,8(sp)
    80002b40:	e04a                	sd	s2,0(sp)
    80002b42:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b44:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b48:	1007f793          	andi	a5,a5,256
    80002b4c:	e3ad                	bnez	a5,80002bae <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b4e:	00003797          	auipc	a5,0x3
    80002b52:	53278793          	addi	a5,a5,1330 # 80006080 <kernelvec>
    80002b56:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	1e2080e7          	jalr	482(ra) # 80001d3c <myproc>
    80002b62:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b64:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b66:	14102773          	csrr	a4,sepc
    80002b6a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b70:	47a1                	li	a5,8
    80002b72:	04f71c63          	bne	a4,a5,80002bca <usertrap+0x92>
    if(p->killed)
    80002b76:	5d1c                	lw	a5,56(a0)
    80002b78:	e3b9                	bnez	a5,80002bbe <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b7a:	70b8                	ld	a4,96(s1)
    80002b7c:	6f1c                	ld	a5,24(a4)
    80002b7e:	0791                	addi	a5,a5,4
    80002b80:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b82:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b86:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	2e0080e7          	jalr	736(ra) # 80002e6e <syscall>
  if(p->killed)
    80002b96:	5c9c                	lw	a5,56(s1)
    80002b98:	ebc1                	bnez	a5,80002c28 <usertrap+0xf0>
  usertrapret();
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	e18080e7          	jalr	-488(ra) # 800029b2 <usertrapret>
}
    80002ba2:	60e2                	ld	ra,24(sp)
    80002ba4:	6442                	ld	s0,16(sp)
    80002ba6:	64a2                	ld	s1,8(sp)
    80002ba8:	6902                	ld	s2,0(sp)
    80002baa:	6105                	addi	sp,sp,32
    80002bac:	8082                	ret
    panic("usertrap: not from user mode");
    80002bae:	00005517          	auipc	a0,0x5
    80002bb2:	7da50513          	addi	a0,a0,2010 # 80008388 <states.1712+0x50>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	99a080e7          	jalr	-1638(ra) # 80000550 <panic>
      exit(-1);
    80002bbe:	557d                	li	a0,-1
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	846080e7          	jalr	-1978(ra) # 80002406 <exit>
    80002bc8:	bf4d                	j	80002b7a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	ecc080e7          	jalr	-308(ra) # 80002a96 <devintr>
    80002bd2:	892a                	mv	s2,a0
    80002bd4:	c501                	beqz	a0,80002bdc <usertrap+0xa4>
  if(p->killed)
    80002bd6:	5c9c                	lw	a5,56(s1)
    80002bd8:	c3a1                	beqz	a5,80002c18 <usertrap+0xe0>
    80002bda:	a815                	j	80002c0e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bdc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002be0:	40b0                	lw	a2,64(s1)
    80002be2:	00005517          	auipc	a0,0x5
    80002be6:	7c650513          	addi	a0,a0,1990 # 800083a8 <states.1712+0x70>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	9b0080e7          	jalr	-1616(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	7de50513          	addi	a0,a0,2014 # 800083d8 <states.1712+0xa0>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	998080e7          	jalr	-1640(ra) # 8000059a <printf>
    p->killed = 1;
    80002c0a:	4785                	li	a5,1
    80002c0c:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c0e:	557d                	li	a0,-1
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	7f6080e7          	jalr	2038(ra) # 80002406 <exit>
  if(which_dev == 2)
    80002c18:	4789                	li	a5,2
    80002c1a:	f8f910e3          	bne	s2,a5,80002b9a <usertrap+0x62>
    yield();
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	8f2080e7          	jalr	-1806(ra) # 80002510 <yield>
    80002c26:	bf95                	j	80002b9a <usertrap+0x62>
  int which_dev = 0;
    80002c28:	4901                	li	s2,0
    80002c2a:	b7d5                	j	80002c0e <usertrap+0xd6>

0000000080002c2c <kerneltrap>:
{
    80002c2c:	7179                	addi	sp,sp,-48
    80002c2e:	f406                	sd	ra,40(sp)
    80002c30:	f022                	sd	s0,32(sp)
    80002c32:	ec26                	sd	s1,24(sp)
    80002c34:	e84a                	sd	s2,16(sp)
    80002c36:	e44e                	sd	s3,8(sp)
    80002c38:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c42:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c46:	1004f793          	andi	a5,s1,256
    80002c4a:	cb85                	beqz	a5,80002c7a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c50:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c52:	ef85                	bnez	a5,80002c8a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	e42080e7          	jalr	-446(ra) # 80002a96 <devintr>
    80002c5c:	cd1d                	beqz	a0,80002c9a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c5e:	4789                	li	a5,2
    80002c60:	06f50a63          	beq	a0,a5,80002cd4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c64:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c68:	10049073          	csrw	sstatus,s1
}
    80002c6c:	70a2                	ld	ra,40(sp)
    80002c6e:	7402                	ld	s0,32(sp)
    80002c70:	64e2                	ld	s1,24(sp)
    80002c72:	6942                	ld	s2,16(sp)
    80002c74:	69a2                	ld	s3,8(sp)
    80002c76:	6145                	addi	sp,sp,48
    80002c78:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	77e50513          	addi	a0,a0,1918 # 800083f8 <states.1712+0xc0>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8ce080e7          	jalr	-1842(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c8a:	00005517          	auipc	a0,0x5
    80002c8e:	79650513          	addi	a0,a0,1942 # 80008420 <states.1712+0xe8>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8be080e7          	jalr	-1858(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002c9a:	85ce                	mv	a1,s3
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	7a450513          	addi	a0,a0,1956 # 80008440 <states.1712+0x108>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	8f6080e7          	jalr	-1802(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cb0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	79c50513          	addi	a0,a0,1948 # 80008450 <states.1712+0x118>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8de080e7          	jalr	-1826(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	7a450513          	addi	a0,a0,1956 # 80008468 <states.1712+0x130>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	884080e7          	jalr	-1916(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	068080e7          	jalr	104(ra) # 80001d3c <myproc>
    80002cdc:	d541                	beqz	a0,80002c64 <kerneltrap+0x38>
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	05e080e7          	jalr	94(ra) # 80001d3c <myproc>
    80002ce6:	5118                	lw	a4,32(a0)
    80002ce8:	478d                	li	a5,3
    80002cea:	f6f71de3          	bne	a4,a5,80002c64 <kerneltrap+0x38>
    yield();
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	822080e7          	jalr	-2014(ra) # 80002510 <yield>
    80002cf6:	b7bd                	j	80002c64 <kerneltrap+0x38>

0000000080002cf8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cf8:	1101                	addi	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	e426                	sd	s1,8(sp)
    80002d00:	1000                	addi	s0,sp,32
    80002d02:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	038080e7          	jalr	56(ra) # 80001d3c <myproc>
  switch (n) {
    80002d0c:	4795                	li	a5,5
    80002d0e:	0497e163          	bltu	a5,s1,80002d50 <argraw+0x58>
    80002d12:	048a                	slli	s1,s1,0x2
    80002d14:	00005717          	auipc	a4,0x5
    80002d18:	78c70713          	addi	a4,a4,1932 # 800084a0 <states.1712+0x168>
    80002d1c:	94ba                	add	s1,s1,a4
    80002d1e:	409c                	lw	a5,0(s1)
    80002d20:	97ba                	add	a5,a5,a4
    80002d22:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d24:	713c                	ld	a5,96(a0)
    80002d26:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret
    return p->trapframe->a1;
    80002d32:	713c                	ld	a5,96(a0)
    80002d34:	7fa8                	ld	a0,120(a5)
    80002d36:	bfcd                	j	80002d28 <argraw+0x30>
    return p->trapframe->a2;
    80002d38:	713c                	ld	a5,96(a0)
    80002d3a:	63c8                	ld	a0,128(a5)
    80002d3c:	b7f5                	j	80002d28 <argraw+0x30>
    return p->trapframe->a3;
    80002d3e:	713c                	ld	a5,96(a0)
    80002d40:	67c8                	ld	a0,136(a5)
    80002d42:	b7dd                	j	80002d28 <argraw+0x30>
    return p->trapframe->a4;
    80002d44:	713c                	ld	a5,96(a0)
    80002d46:	6bc8                	ld	a0,144(a5)
    80002d48:	b7c5                	j	80002d28 <argraw+0x30>
    return p->trapframe->a5;
    80002d4a:	713c                	ld	a5,96(a0)
    80002d4c:	6fc8                	ld	a0,152(a5)
    80002d4e:	bfe9                	j	80002d28 <argraw+0x30>
  panic("argraw");
    80002d50:	00005517          	auipc	a0,0x5
    80002d54:	72850513          	addi	a0,a0,1832 # 80008478 <states.1712+0x140>
    80002d58:	ffffd097          	auipc	ra,0xffffd
    80002d5c:	7f8080e7          	jalr	2040(ra) # 80000550 <panic>

0000000080002d60 <fetchaddr>:
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	e04a                	sd	s2,0(sp)
    80002d6a:	1000                	addi	s0,sp,32
    80002d6c:	84aa                	mv	s1,a0
    80002d6e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	fcc080e7          	jalr	-52(ra) # 80001d3c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d78:	693c                	ld	a5,80(a0)
    80002d7a:	02f4f863          	bgeu	s1,a5,80002daa <fetchaddr+0x4a>
    80002d7e:	00848713          	addi	a4,s1,8
    80002d82:	02e7e663          	bltu	a5,a4,80002dae <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d86:	46a1                	li	a3,8
    80002d88:	8626                	mv	a2,s1
    80002d8a:	85ca                	mv	a1,s2
    80002d8c:	6d28                	ld	a0,88(a0)
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	d2e080e7          	jalr	-722(ra) # 80001abc <copyin>
    80002d96:	00a03533          	snez	a0,a0
    80002d9a:	40a00533          	neg	a0,a0
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6902                	ld	s2,0(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret
    return -1;
    80002daa:	557d                	li	a0,-1
    80002dac:	bfcd                	j	80002d9e <fetchaddr+0x3e>
    80002dae:	557d                	li	a0,-1
    80002db0:	b7fd                	j	80002d9e <fetchaddr+0x3e>

0000000080002db2 <fetchstr>:
{
    80002db2:	7179                	addi	sp,sp,-48
    80002db4:	f406                	sd	ra,40(sp)
    80002db6:	f022                	sd	s0,32(sp)
    80002db8:	ec26                	sd	s1,24(sp)
    80002dba:	e84a                	sd	s2,16(sp)
    80002dbc:	e44e                	sd	s3,8(sp)
    80002dbe:	1800                	addi	s0,sp,48
    80002dc0:	892a                	mv	s2,a0
    80002dc2:	84ae                	mv	s1,a1
    80002dc4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	f76080e7          	jalr	-138(ra) # 80001d3c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dce:	86ce                	mv	a3,s3
    80002dd0:	864a                	mv	a2,s2
    80002dd2:	85a6                	mv	a1,s1
    80002dd4:	6d28                	ld	a0,88(a0)
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	d72080e7          	jalr	-654(ra) # 80001b48 <copyinstr>
  if(err < 0)
    80002dde:	00054763          	bltz	a0,80002dec <fetchstr+0x3a>
  return strlen(buf);
    80002de2:	8526                	mv	a0,s1
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	478080e7          	jalr	1144(ra) # 8000125c <strlen>
}
    80002dec:	70a2                	ld	ra,40(sp)
    80002dee:	7402                	ld	s0,32(sp)
    80002df0:	64e2                	ld	s1,24(sp)
    80002df2:	6942                	ld	s2,16(sp)
    80002df4:	69a2                	ld	s3,8(sp)
    80002df6:	6145                	addi	sp,sp,48
    80002df8:	8082                	ret

0000000080002dfa <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	1000                	addi	s0,sp,32
    80002e04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	ef2080e7          	jalr	-270(ra) # 80002cf8 <argraw>
    80002e0e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e10:	4501                	li	a0,0
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	64a2                	ld	s1,8(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	1000                	addi	s0,sp,32
    80002e26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	ed0080e7          	jalr	-304(ra) # 80002cf8 <argraw>
    80002e30:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e32:	4501                	li	a0,0
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6105                	addi	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	e04a                	sd	s2,0(sp)
    80002e48:	1000                	addi	s0,sp,32
    80002e4a:	84ae                	mv	s1,a1
    80002e4c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e4e:	00000097          	auipc	ra,0x0
    80002e52:	eaa080e7          	jalr	-342(ra) # 80002cf8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e56:	864a                	mv	a2,s2
    80002e58:	85a6                	mv	a1,s1
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	f58080e7          	jalr	-168(ra) # 80002db2 <fetchstr>
}
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6902                	ld	s2,0(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	e04a                	sd	s2,0(sp)
    80002e78:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	ec2080e7          	jalr	-318(ra) # 80001d3c <myproc>
    80002e82:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e84:	06053903          	ld	s2,96(a0)
    80002e88:	0a893783          	ld	a5,168(s2)
    80002e8c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e90:	37fd                	addiw	a5,a5,-1
    80002e92:	4751                	li	a4,20
    80002e94:	00f76f63          	bltu	a4,a5,80002eb2 <syscall+0x44>
    80002e98:	00369713          	slli	a4,a3,0x3
    80002e9c:	00005797          	auipc	a5,0x5
    80002ea0:	61c78793          	addi	a5,a5,1564 # 800084b8 <syscalls>
    80002ea4:	97ba                	add	a5,a5,a4
    80002ea6:	639c                	ld	a5,0(a5)
    80002ea8:	c789                	beqz	a5,80002eb2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002eaa:	9782                	jalr	a5
    80002eac:	06a93823          	sd	a0,112(s2)
    80002eb0:	a839                	j	80002ece <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eb2:	16048613          	addi	a2,s1,352
    80002eb6:	40ac                	lw	a1,64(s1)
    80002eb8:	00005517          	auipc	a0,0x5
    80002ebc:	5c850513          	addi	a0,a0,1480 # 80008480 <states.1712+0x148>
    80002ec0:	ffffd097          	auipc	ra,0xffffd
    80002ec4:	6da080e7          	jalr	1754(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec8:	70bc                	ld	a5,96(s1)
    80002eca:	577d                	li	a4,-1
    80002ecc:	fbb8                	sd	a4,112(a5)
  }
}
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6902                	ld	s2,0(sp)
    80002ed6:	6105                	addi	sp,sp,32
    80002ed8:	8082                	ret

0000000080002eda <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ee2:	fec40593          	addi	a1,s0,-20
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	f12080e7          	jalr	-238(ra) # 80002dfa <argint>
    return -1;
    80002ef0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef2:	00054963          	bltz	a0,80002f04 <sys_exit+0x2a>
  exit(n);
    80002ef6:	fec42503          	lw	a0,-20(s0)
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	50c080e7          	jalr	1292(ra) # 80002406 <exit>
  return 0;  // not reached
    80002f02:	4781                	li	a5,0
}
    80002f04:	853e                	mv	a0,a5
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret

0000000080002f0e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f0e:	1141                	addi	sp,sp,-16
    80002f10:	e406                	sd	ra,8(sp)
    80002f12:	e022                	sd	s0,0(sp)
    80002f14:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	e26080e7          	jalr	-474(ra) # 80001d3c <myproc>
}
    80002f1e:	4128                	lw	a0,64(a0)
    80002f20:	60a2                	ld	ra,8(sp)
    80002f22:	6402                	ld	s0,0(sp)
    80002f24:	0141                	addi	sp,sp,16
    80002f26:	8082                	ret

0000000080002f28 <sys_fork>:

uint64
sys_fork(void)
{
    80002f28:	1141                	addi	sp,sp,-16
    80002f2a:	e406                	sd	ra,8(sp)
    80002f2c:	e022                	sd	s0,0(sp)
    80002f2e:	0800                	addi	s0,sp,16
  return fork();
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	1cc080e7          	jalr	460(ra) # 800020fc <fork>
}
    80002f38:	60a2                	ld	ra,8(sp)
    80002f3a:	6402                	ld	s0,0(sp)
    80002f3c:	0141                	addi	sp,sp,16
    80002f3e:	8082                	ret

0000000080002f40 <sys_wait>:

uint64
sys_wait(void)
{
    80002f40:	1101                	addi	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f48:	fe840593          	addi	a1,s0,-24
    80002f4c:	4501                	li	a0,0
    80002f4e:	00000097          	auipc	ra,0x0
    80002f52:	ece080e7          	jalr	-306(ra) # 80002e1c <argaddr>
    80002f56:	87aa                	mv	a5,a0
    return -1;
    80002f58:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f5a:	0007c863          	bltz	a5,80002f6a <sys_wait+0x2a>
  return wait(p);
    80002f5e:	fe843503          	ld	a0,-24(s0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	668080e7          	jalr	1640(ra) # 800025ca <wait>
}
    80002f6a:	60e2                	ld	ra,24(sp)
    80002f6c:	6442                	ld	s0,16(sp)
    80002f6e:	6105                	addi	sp,sp,32
    80002f70:	8082                	ret

0000000080002f72 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f72:	7179                	addi	sp,sp,-48
    80002f74:	f406                	sd	ra,40(sp)
    80002f76:	f022                	sd	s0,32(sp)
    80002f78:	ec26                	sd	s1,24(sp)
    80002f7a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f7c:	fdc40593          	addi	a1,s0,-36
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	e78080e7          	jalr	-392(ra) # 80002dfa <argint>
    80002f8a:	87aa                	mv	a5,a0
    return -1;
    80002f8c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f8e:	0207c063          	bltz	a5,80002fae <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	daa080e7          	jalr	-598(ra) # 80001d3c <myproc>
    80002f9a:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f9c:	fdc42503          	lw	a0,-36(s0)
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	0e8080e7          	jalr	232(ra) # 80002088 <growproc>
    80002fa8:	00054863          	bltz	a0,80002fb8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fac:	8526                	mv	a0,s1
}
    80002fae:	70a2                	ld	ra,40(sp)
    80002fb0:	7402                	ld	s0,32(sp)
    80002fb2:	64e2                	ld	s1,24(sp)
    80002fb4:	6145                	addi	sp,sp,48
    80002fb6:	8082                	ret
    return -1;
    80002fb8:	557d                	li	a0,-1
    80002fba:	bfd5                	j	80002fae <sys_sbrk+0x3c>

0000000080002fbc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fbc:	7139                	addi	sp,sp,-64
    80002fbe:	fc06                	sd	ra,56(sp)
    80002fc0:	f822                	sd	s0,48(sp)
    80002fc2:	f426                	sd	s1,40(sp)
    80002fc4:	f04a                	sd	s2,32(sp)
    80002fc6:	ec4e                	sd	s3,24(sp)
    80002fc8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fca:	fcc40593          	addi	a1,s0,-52
    80002fce:	4501                	li	a0,0
    80002fd0:	00000097          	auipc	ra,0x0
    80002fd4:	e2a080e7          	jalr	-470(ra) # 80002dfa <argint>
    return -1;
    80002fd8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fda:	06054563          	bltz	a0,80003044 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fde:	00015517          	auipc	a0,0x15
    80002fe2:	3ca50513          	addi	a0,a0,970 # 800183a8 <tickslock>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	d0e080e7          	jalr	-754(ra) # 80000cf4 <acquire>
  ticks0 = ticks;
    80002fee:	00006917          	auipc	s2,0x6
    80002ff2:	03292903          	lw	s2,50(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ff6:	fcc42783          	lw	a5,-52(s0)
    80002ffa:	cf85                	beqz	a5,80003032 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ffc:	00015997          	auipc	s3,0x15
    80003000:	3ac98993          	addi	s3,s3,940 # 800183a8 <tickslock>
    80003004:	00006497          	auipc	s1,0x6
    80003008:	01c48493          	addi	s1,s1,28 # 80009020 <ticks>
    if(myproc()->killed){
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	d30080e7          	jalr	-720(ra) # 80001d3c <myproc>
    80003014:	5d1c                	lw	a5,56(a0)
    80003016:	ef9d                	bnez	a5,80003054 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003018:	85ce                	mv	a1,s3
    8000301a:	8526                	mv	a0,s1
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	530080e7          	jalr	1328(ra) # 8000254c <sleep>
  while(ticks - ticks0 < n){
    80003024:	409c                	lw	a5,0(s1)
    80003026:	412787bb          	subw	a5,a5,s2
    8000302a:	fcc42703          	lw	a4,-52(s0)
    8000302e:	fce7efe3          	bltu	a5,a4,8000300c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003032:	00015517          	auipc	a0,0x15
    80003036:	37650513          	addi	a0,a0,886 # 800183a8 <tickslock>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	d8a080e7          	jalr	-630(ra) # 80000dc4 <release>
  return 0;
    80003042:	4781                	li	a5,0
}
    80003044:	853e                	mv	a0,a5
    80003046:	70e2                	ld	ra,56(sp)
    80003048:	7442                	ld	s0,48(sp)
    8000304a:	74a2                	ld	s1,40(sp)
    8000304c:	7902                	ld	s2,32(sp)
    8000304e:	69e2                	ld	s3,24(sp)
    80003050:	6121                	addi	sp,sp,64
    80003052:	8082                	ret
      release(&tickslock);
    80003054:	00015517          	auipc	a0,0x15
    80003058:	35450513          	addi	a0,a0,852 # 800183a8 <tickslock>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	d68080e7          	jalr	-664(ra) # 80000dc4 <release>
      return -1;
    80003064:	57fd                	li	a5,-1
    80003066:	bff9                	j	80003044 <sys_sleep+0x88>

0000000080003068 <sys_kill>:

uint64
sys_kill(void)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003070:	fec40593          	addi	a1,s0,-20
    80003074:	4501                	li	a0,0
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	d84080e7          	jalr	-636(ra) # 80002dfa <argint>
    8000307e:	87aa                	mv	a5,a0
    return -1;
    80003080:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003082:	0007c863          	bltz	a5,80003092 <sys_kill+0x2a>
  return kill(pid);
    80003086:	fec42503          	lw	a0,-20(s0)
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	6b2080e7          	jalr	1714(ra) # 8000273c <kill>
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret

000000008000309a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a4:	00015517          	auipc	a0,0x15
    800030a8:	30450513          	addi	a0,a0,772 # 800183a8 <tickslock>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	c48080e7          	jalr	-952(ra) # 80000cf4 <acquire>
  xticks = ticks;
    800030b4:	00006497          	auipc	s1,0x6
    800030b8:	f6c4a483          	lw	s1,-148(s1) # 80009020 <ticks>
  release(&tickslock);
    800030bc:	00015517          	auipc	a0,0x15
    800030c0:	2ec50513          	addi	a0,a0,748 # 800183a8 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	d00080e7          	jalr	-768(ra) # 80000dc4 <release>
  return xticks;
}
    800030cc:	02049513          	slli	a0,s1,0x20
    800030d0:	9101                	srli	a0,a0,0x20
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret

00000000800030dc <hash>:
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf head[NBUCKET];
} bcache;

int hash (int n) {
    800030dc:	1141                	addi	sp,sp,-16
    800030de:	e422                	sd	s0,8(sp)
    800030e0:	0800                	addi	s0,sp,16
  int result = n % NBUCKET;
  return result;
}
    800030e2:	47b5                	li	a5,13
    800030e4:	02f5653b          	remw	a0,a0,a5
    800030e8:	6422                	ld	s0,8(sp)
    800030ea:	0141                	addi	sp,sp,16
    800030ec:	8082                	ret

00000000800030ee <can_lock>:

int can_lock(int id, int j) {
    800030ee:	1141                	addi	sp,sp,-16
    800030f0:	e422                	sd	s0,8(sp)
    800030f2:	0800                	addi	s0,sp,16
    800030f4:	87aa                	mv	a5,a0
  int num = NBUCKET/2;
  if (id <= num) {
    800030f6:	4719                	li	a4,6
    800030f8:	00a74a63          	blt	a4,a0,8000310c <can_lock+0x1e>
  } else {
    if ((id < j && j < NBUCKET) || (j <= (id+num)%NBUCKET)) {
      return 0;
    }
  }
  return 1;
    800030fc:	4505                	li	a0,1
    if (j > id && j <= (id+num))
    800030fe:	02b7d463          	bge	a5,a1,80003126 <can_lock+0x38>
    80003102:	0067851b          	addiw	a0,a5,6
      return 0;
    80003106:	00b52533          	slt	a0,a0,a1
    8000310a:	a831                	j	80003126 <can_lock+0x38>
    if ((id < j && j < NBUCKET) || (j <= (id+num)%NBUCKET)) {
    8000310c:	00b55663          	bge	a0,a1,80003118 <can_lock+0x2a>
    80003110:	4731                	li	a4,12
      return 0;
    80003112:	4501                	li	a0,0
    if ((id < j && j < NBUCKET) || (j <= (id+num)%NBUCKET)) {
    80003114:	00b75963          	bge	a4,a1,80003126 <can_lock+0x38>
    80003118:	0067851b          	addiw	a0,a5,6
    8000311c:	47b5                	li	a5,13
    8000311e:	02f5653b          	remw	a0,a0,a5
  return 1;
    80003122:	00b52533          	slt	a0,a0,a1
}
    80003126:	6422                	ld	s0,8(sp)
    80003128:	0141                	addi	sp,sp,16
    8000312a:	8082                	ret

000000008000312c <binit>:

void
binit(void)
{
    8000312c:	7179                	addi	sp,sp,-48
    8000312e:	f406                	sd	ra,40(sp)
    80003130:	f022                	sd	s0,32(sp)
    80003132:	ec26                	sd	s1,24(sp)
    80003134:	e84a                	sd	s2,16(sp)
    80003136:	e44e                	sd	s3,8(sp)
    80003138:	1800                	addi	s0,sp,48
  struct buf *b;

  for (int i = 0; i < NBUCKET; i++) {
    8000313a:	00015497          	auipc	s1,0x15
    8000313e:	28e48493          	addi	s1,s1,654 # 800183c8 <bcache>
    80003142:	00015997          	auipc	s3,0x15
    80003146:	42698993          	addi	s3,s3,1062 # 80018568 <bcache+0x1a0>
    initlock(&bcache.lock[i], "bcache");
    8000314a:	00005917          	auipc	s2,0x5
    8000314e:	fb690913          	addi	s2,s2,-74 # 80008100 <digits+0xc0>
    80003152:	85ca                	mv	a1,s2
    80003154:	8526                	mv	a0,s1
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	d1a080e7          	jalr	-742(ra) # 80000e70 <initlock>
  for (int i = 0; i < NBUCKET; i++) {
    8000315e:	02048493          	addi	s1,s1,32
    80003162:	ff3498e3          	bne	s1,s3,80003152 <binit+0x26>
  }

  bcache.head[0].next = &bcache.buf[0];
    80003166:	00015497          	auipc	s1,0x15
    8000316a:	40248493          	addi	s1,s1,1026 # 80018568 <bcache+0x1a0>
    8000316e:	00036797          	auipc	a5,0x36
    80003172:	1497b523          	sd	s1,330(a5) # 800392b8 <bcache+0x20ef0>
  // for initialization, append all bufs to bucket 0
  for (b = bcache.buf; b < bcache.buf+NBUF-1; b++) {
    b->next = b+1;
    initsleeplock(&b->lock, "buffer");
    80003176:	00005997          	auipc	s3,0x5
    8000317a:	3f298993          	addi	s3,s3,1010 # 80008568 <syscalls+0xb0>
  for (b = bcache.buf; b < bcache.buf+NBUF-1; b++) {
    8000317e:	00036917          	auipc	s2,0x36
    80003182:	c8a90913          	addi	s2,s2,-886 # 80038e08 <bcache+0x20a40>
    b->next = b+1;
    80003186:	46048493          	addi	s1,s1,1120
    8000318a:	be94b823          	sd	s1,-1040(s1)
    initsleeplock(&b->lock, "buffer");
    8000318e:	85ce                	mv	a1,s3
    80003190:	bb048513          	addi	a0,s1,-1104
    80003194:	00001097          	auipc	ra,0x1
    80003198:	664080e7          	jalr	1636(ra) # 800047f8 <initsleeplock>
  for (b = bcache.buf; b < bcache.buf+NBUF-1; b++) {
    8000319c:	ff2495e3          	bne	s1,s2,80003186 <binit+0x5a>
  }
}
    800031a0:	70a2                	ld	ra,40(sp)
    800031a2:	7402                	ld	s0,32(sp)
    800031a4:	64e2                	ld	s1,24(sp)
    800031a6:	6942                	ld	s2,16(sp)
    800031a8:	69a2                	ld	s3,8(sp)
    800031aa:	6145                	addi	sp,sp,48
    800031ac:	8082                	ret

00000000800031ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031ae:	7119                	addi	sp,sp,-128
    800031b0:	fc86                	sd	ra,120(sp)
    800031b2:	f8a2                	sd	s0,112(sp)
    800031b4:	f4a6                	sd	s1,104(sp)
    800031b6:	f0ca                	sd	s2,96(sp)
    800031b8:	ecce                	sd	s3,88(sp)
    800031ba:	e8d2                	sd	s4,80(sp)
    800031bc:	e4d6                	sd	s5,72(sp)
    800031be:	e0da                	sd	s6,64(sp)
    800031c0:	fc5e                	sd	s7,56(sp)
    800031c2:	f862                	sd	s8,48(sp)
    800031c4:	f466                	sd	s9,40(sp)
    800031c6:	f06a                	sd	s10,32(sp)
    800031c8:	ec6e                	sd	s11,24(sp)
    800031ca:	0100                	addi	s0,sp,128
    800031cc:	8caa                	mv	s9,a0
    800031ce:	8b2e                	mv	s6,a1
  int result = n % NBUCKET;
    800031d0:	44b5                	li	s1,13
    800031d2:	0295e4bb          	remw	s1,a1,s1
  acquire(&bcache.lock[id]);
    800031d6:	00549c13          	slli	s8,s1,0x5
    800031da:	00015917          	auipc	s2,0x15
    800031de:	1ee90913          	addi	s2,s2,494 # 800183c8 <bcache>
    800031e2:	9c4a                	add	s8,s8,s2
    800031e4:	8562                	mv	a0,s8
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	b0e080e7          	jalr	-1266(ra) # 80000cf4 <acquire>
  b = bcache.head[id].next;
    800031ee:	46000793          	li	a5,1120
    800031f2:	02f487b3          	mul	a5,s1,a5
    800031f6:	993e                	add	s2,s2,a5
    800031f8:	000217b7          	lui	a5,0x21
    800031fc:	993e                	add	s2,s2,a5
    800031fe:	ef093983          	ld	s3,-272(s2)
  while (b) {
    80003202:	02099863          	bnez	s3,80003232 <bread+0x84>
    80003206:	00015b97          	auipc	s7,0x15
    8000320a:	1c2b8b93          	addi	s7,s7,450 # 800183c8 <bcache>
    8000320e:	00036d17          	auipc	s10,0x36
    80003212:	0aad0d13          	addi	s10,s10,170 # 800392b8 <bcache+0x20ef0>
{
    80003216:	5afd                	li	s5,-1
    80003218:	597d                	li	s2,-1
    8000321a:	4981                	li	s3,0
    8000321c:	a8f1                	j	800032f8 <bread+0x14a>
        release(&bcache.lock[id]);
    8000321e:	8562                	mv	a0,s8
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	ba4080e7          	jalr	-1116(ra) # 80000dc4 <release>
    80003228:	a805                	j	80003258 <bread+0xaa>
    b = b->next;
    8000322a:	0509b983          	ld	s3,80(s3)
  while (b) {
    8000322e:	fc098ce3          	beqz	s3,80003206 <bread+0x58>
    if (b->dev == dev && b->blockno == blockno) {
    80003232:	0089a783          	lw	a5,8(s3)
    80003236:	ff979ae3          	bne	a5,s9,8000322a <bread+0x7c>
    8000323a:	00c9a783          	lw	a5,12(s3)
    8000323e:	ff6796e3          	bne	a5,s6,8000322a <bread+0x7c>
      b->refcnt++;
    80003242:	0489a783          	lw	a5,72(s3)
    80003246:	2785                	addiw	a5,a5,1
    80003248:	04f9a423          	sw	a5,72(s3)
      if (holding(&bcache.lock[id]))
    8000324c:	8562                	mv	a0,s8
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	a2c080e7          	jalr	-1492(ra) # 80000c7a <holding>
    80003256:	f561                	bnez	a0,8000321e <bread+0x70>
      acquiresleep(&b->lock);
    80003258:	01098513          	addi	a0,s3,16
    8000325c:	00001097          	auipc	ra,0x1
    80003260:	5d6080e7          	jalr	1494(ra) # 80004832 <acquiresleep>
      return b;
    80003264:	a2a5                	j	800033cc <bread+0x21e>
    } else if (!can_lock(id, j)) {
    80003266:	85ce                	mv	a1,s3
    80003268:	854e                	mv	a0,s3
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	e84080e7          	jalr	-380(ra) # 800030ee <can_lock>
    80003272:	c93d                	beqz	a0,800032e8 <bread+0x13a>
    b = bcache.head[j].next;
    80003274:	000d3a03          	ld	s4,0(s10)
    while (b) {
    80003278:	060a0863          	beqz	s4,800032e8 <bread+0x13a>
{
    8000327c:	87d6                	mv	a5,s5
    8000327e:	f9343423          	sd	s3,-120(s0)
    80003282:	a039                	j	80003290 <bread+0xe2>
    80003284:	8abe                	mv	s5,a5
      b = b->next;
    80003286:	050a3a03          	ld	s4,80(s4)
    while (b) {
    8000328a:	040a0a63          	beqz	s4,800032de <bread+0x130>
    8000328e:	87d6                	mv	a5,s5
      if (b->refcnt == 0) {
    80003290:	048a2703          	lw	a4,72(s4)
    80003294:	8abe                	mv	s5,a5
    80003296:	fb65                	bnez	a4,80003286 <bread+0xd8>
        if (b->time < smallest_tick) {
    80003298:	458a2a83          	lw	s5,1112(s4)
    8000329c:	fefaf4e3          	bgeu	s5,a5,80003284 <bread+0xd6>
          if (index != -1 && index != j && holding(&bcache.lock[index])) release(&bcache.lock[index]);
    800032a0:	57fd                	li	a5,-1
    800032a2:	02f90b63          	beq	s2,a5,800032d8 <bread+0x12a>
    800032a6:	ff2980e3          	beq	s3,s2,80003286 <bread+0xd8>
    800032aa:	0916                	slli	s2,s2,0x5
    800032ac:	00015797          	auipc	a5,0x15
    800032b0:	11c78793          	addi	a5,a5,284 # 800183c8 <bcache>
    800032b4:	00f90db3          	add	s11,s2,a5
    800032b8:	856e                	mv	a0,s11
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	9c0080e7          	jalr	-1600(ra) # 80000c7a <holding>
    800032c2:	f8843903          	ld	s2,-120(s0)
    800032c6:	d161                	beqz	a0,80003286 <bread+0xd8>
    800032c8:	856e                	mv	a0,s11
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	afa080e7          	jalr	-1286(ra) # 80000dc4 <release>
    800032d2:	f8843903          	ld	s2,-120(s0)
    800032d6:	bf45                	j	80003286 <bread+0xd8>
    800032d8:	f8843903          	ld	s2,-120(s0)
    800032dc:	b76d                	j	80003286 <bread+0xd8>
    if (j!=id && j!=index && holding(&bcache.lock[j])) release(&bcache.lock[j]);
    800032de:	01348563          	beq	s1,s3,800032e8 <bread+0x13a>
    800032e2:	03391e63          	bne	s2,s3,8000331e <bread+0x170>
    800032e6:	894e                	mv	s2,s3
  for (int j = 0; j < NBUCKET; ++j) {
    800032e8:	2985                	addiw	s3,s3,1
    800032ea:	020b8b93          	addi	s7,s7,32
    800032ee:	460d0d13          	addi	s10,s10,1120
    800032f2:	47b5                	li	a5,13
    800032f4:	04f98163          	beq	s3,a5,80003336 <bread+0x188>
    if (j!=id && can_lock(id, j)) {
    800032f8:	f73487e3          	beq	s1,s3,80003266 <bread+0xb8>
    800032fc:	85ce                	mv	a1,s3
    800032fe:	8526                	mv	a0,s1
    80003300:	00000097          	auipc	ra,0x0
    80003304:	dee080e7          	jalr	-530(ra) # 800030ee <can_lock>
    80003308:	d165                	beqz	a0,800032e8 <bread+0x13a>
      acquire(&bcache.lock[j]);
    8000330a:	855e                	mv	a0,s7
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	9e8080e7          	jalr	-1560(ra) # 80000cf4 <acquire>
    b = bcache.head[j].next;
    80003314:	000d3a03          	ld	s4,0(s10)
    while (b) {
    80003318:	f60a12e3          	bnez	s4,8000327c <bread+0xce>
    8000331c:	b7d9                	j	800032e2 <bread+0x134>
    if (j!=id && j!=index && holding(&bcache.lock[j])) release(&bcache.lock[j]);
    8000331e:	855e                	mv	a0,s7
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	95a080e7          	jalr	-1702(ra) # 80000c7a <holding>
    80003328:	d161                	beqz	a0,800032e8 <bread+0x13a>
    8000332a:	855e                	mv	a0,s7
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	a98080e7          	jalr	-1384(ra) # 80000dc4 <release>
    80003334:	bf55                	j	800032e8 <bread+0x13a>
  if (index == -1) panic("bget: no buffers");
    80003336:	57fd                	li	a5,-1
    80003338:	0af90d63          	beq	s2,a5,800033f2 <bread+0x244>
  b = &bcache.head[index];
    8000333c:	854a                	mv	a0,s2
    8000333e:	46000993          	li	s3,1120
    80003342:	033909b3          	mul	s3,s2,s3
    80003346:	000217b7          	lui	a5,0x21
    8000334a:	ea078793          	addi	a5,a5,-352 # 20ea0 <_entry-0x7ffdf160>
    8000334e:	99be                	add	s3,s3,a5
    80003350:	00015797          	auipc	a5,0x15
    80003354:	07878793          	addi	a5,a5,120 # 800183c8 <bcache>
    80003358:	99be                	add	s3,s3,a5
    if ((b->next)->refcnt == 0 && (b->next)->time == smallest_tick) {
    8000335a:	874e                	mv	a4,s3
    8000335c:	0509b983          	ld	s3,80(s3)
    80003360:	0489a783          	lw	a5,72(s3)
    80003364:	fbfd                	bnez	a5,8000335a <bread+0x1ac>
    80003366:	4589a783          	lw	a5,1112(s3)
    8000336a:	ff5798e3          	bne	a5,s5,8000335a <bread+0x1ac>
      b->next = b->next->next;
    8000336e:	0509b783          	ld	a5,80(s3)
    80003372:	eb3c                	sd	a5,80(a4)
  if (index != id && holding(&bcache.lock[index])) release(&bcache.lock[index]);
    80003374:	08991763          	bne	s2,s1,80003402 <bread+0x254>
  b = &bcache.head[id];
    80003378:	46000793          	li	a5,1120
    8000337c:	02f484b3          	mul	s1,s1,a5
    80003380:	000217b7          	lui	a5,0x21
    80003384:	ea078793          	addi	a5,a5,-352 # 20ea0 <_entry-0x7ffdf160>
    80003388:	94be                	add	s1,s1,a5
    8000338a:	00015797          	auipc	a5,0x15
    8000338e:	03e78793          	addi	a5,a5,62 # 800183c8 <bcache>
    80003392:	94be                	add	s1,s1,a5
  while (b->next) {
    80003394:	87a6                	mv	a5,s1
    80003396:	68a4                	ld	s1,80(s1)
    80003398:	fcf5                	bnez	s1,80003394 <bread+0x1e6>
  b->next = selected;
    8000339a:	0537b823          	sd	s3,80(a5)
  selected->next = 0;
    8000339e:	0409b823          	sd	zero,80(s3)
  selected->dev = dev;
    800033a2:	0199a423          	sw	s9,8(s3)
  selected->blockno = blockno;
    800033a6:	0169a623          	sw	s6,12(s3)
  selected->valid = 0;
    800033aa:	0009a023          	sw	zero,0(s3)
  selected->refcnt = 1;
    800033ae:	4785                	li	a5,1
    800033b0:	04f9a423          	sw	a5,72(s3)
  if (holding(&bcache.lock[id]))
    800033b4:	8562                	mv	a0,s8
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	8c4080e7          	jalr	-1852(ra) # 80000c7a <holding>
    800033be:	e525                	bnez	a0,80003426 <bread+0x278>
  acquiresleep(&selected->lock);
    800033c0:	01098513          	addi	a0,s3,16
    800033c4:	00001097          	auipc	ra,0x1
    800033c8:	46e080e7          	jalr	1134(ra) # 80004832 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033cc:	0009a783          	lw	a5,0(s3)
    800033d0:	c3ad                	beqz	a5,80003432 <bread+0x284>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033d2:	854e                	mv	a0,s3
    800033d4:	70e6                	ld	ra,120(sp)
    800033d6:	7446                	ld	s0,112(sp)
    800033d8:	74a6                	ld	s1,104(sp)
    800033da:	7906                	ld	s2,96(sp)
    800033dc:	69e6                	ld	s3,88(sp)
    800033de:	6a46                	ld	s4,80(sp)
    800033e0:	6aa6                	ld	s5,72(sp)
    800033e2:	6b06                	ld	s6,64(sp)
    800033e4:	7be2                	ld	s7,56(sp)
    800033e6:	7c42                	ld	s8,48(sp)
    800033e8:	7ca2                	ld	s9,40(sp)
    800033ea:	7d02                	ld	s10,32(sp)
    800033ec:	6de2                	ld	s11,24(sp)
    800033ee:	6109                	addi	sp,sp,128
    800033f0:	8082                	ret
  if (index == -1) panic("bget: no buffers");
    800033f2:	00005517          	auipc	a0,0x5
    800033f6:	17e50513          	addi	a0,a0,382 # 80008570 <syscalls+0xb8>
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	156080e7          	jalr	342(ra) # 80000550 <panic>
  if (index != id && holding(&bcache.lock[index])) release(&bcache.lock[index]);
    80003402:	0516                	slli	a0,a0,0x5
    80003404:	00015917          	auipc	s2,0x15
    80003408:	fc490913          	addi	s2,s2,-60 # 800183c8 <bcache>
    8000340c:	992a                	add	s2,s2,a0
    8000340e:	854a                	mv	a0,s2
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	86a080e7          	jalr	-1942(ra) # 80000c7a <holding>
    80003418:	d125                	beqz	a0,80003378 <bread+0x1ca>
    8000341a:	854a                	mv	a0,s2
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	9a8080e7          	jalr	-1624(ra) # 80000dc4 <release>
    80003424:	bf91                	j	80003378 <bread+0x1ca>
    release(&bcache.lock[id]);
    80003426:	8562                	mv	a0,s8
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	99c080e7          	jalr	-1636(ra) # 80000dc4 <release>
    80003430:	bf41                	j	800033c0 <bread+0x212>
    virtio_disk_rw(b, 0);
    80003432:	4581                	li	a1,0
    80003434:	854e                	mv	a0,s3
    80003436:	00003097          	auipc	ra,0x3
    8000343a:	f80080e7          	jalr	-128(ra) # 800063b6 <virtio_disk_rw>
    b->valid = 1;
    8000343e:	4785                	li	a5,1
    80003440:	00f9a023          	sw	a5,0(s3)
  return b;
    80003444:	b779                	j	800033d2 <bread+0x224>

0000000080003446 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003446:	1101                	addi	sp,sp,-32
    80003448:	ec06                	sd	ra,24(sp)
    8000344a:	e822                	sd	s0,16(sp)
    8000344c:	e426                	sd	s1,8(sp)
    8000344e:	1000                	addi	s0,sp,32
    80003450:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003452:	0541                	addi	a0,a0,16
    80003454:	00001097          	auipc	ra,0x1
    80003458:	478080e7          	jalr	1144(ra) # 800048cc <holdingsleep>
    8000345c:	cd01                	beqz	a0,80003474 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000345e:	4585                	li	a1,1
    80003460:	8526                	mv	a0,s1
    80003462:	00003097          	auipc	ra,0x3
    80003466:	f54080e7          	jalr	-172(ra) # 800063b6 <virtio_disk_rw>
}
    8000346a:	60e2                	ld	ra,24(sp)
    8000346c:	6442                	ld	s0,16(sp)
    8000346e:	64a2                	ld	s1,8(sp)
    80003470:	6105                	addi	sp,sp,32
    80003472:	8082                	ret
    panic("bwrite");
    80003474:	00005517          	auipc	a0,0x5
    80003478:	11450513          	addi	a0,a0,276 # 80008588 <syscalls+0xd0>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	0d4080e7          	jalr	212(ra) # 80000550 <panic>

0000000080003484 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	e426                	sd	s1,8(sp)
    8000348c:	e04a                	sd	s2,0(sp)
    8000348e:	1000                	addi	s0,sp,32
    80003490:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    80003492:	01050493          	addi	s1,a0,16
    80003496:	8526                	mv	a0,s1
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	434080e7          	jalr	1076(ra) # 800048cc <holdingsleep>
    800034a0:	cd39                	beqz	a0,800034fe <brelse+0x7a>
    panic("brelse");

  releasesleep(&b->lock);
    800034a2:	8526                	mv	a0,s1
    800034a4:	00001097          	auipc	ra,0x1
    800034a8:	3e4080e7          	jalr	996(ra) # 80004888 <releasesleep>
  int result = n % NBUCKET;
    800034ac:	00c92483          	lw	s1,12(s2)

  int id = hash(b->blockno);
  acquire(&bcache.lock[id]);
    800034b0:	47b5                	li	a5,13
    800034b2:	02f4e4bb          	remw	s1,s1,a5
    800034b6:	0496                	slli	s1,s1,0x5
    800034b8:	00015797          	auipc	a5,0x15
    800034bc:	f1078793          	addi	a5,a5,-240 # 800183c8 <bcache>
    800034c0:	94be                	add	s1,s1,a5
    800034c2:	8526                	mv	a0,s1
    800034c4:	ffffe097          	auipc	ra,0xffffe
    800034c8:	830080e7          	jalr	-2000(ra) # 80000cf4 <acquire>
  b->refcnt--;
    800034cc:	04892783          	lw	a5,72(s2)
    800034d0:	37fd                	addiw	a5,a5,-1
    800034d2:	0007871b          	sext.w	a4,a5
    800034d6:	04f92423          	sw	a5,72(s2)
  if (b->refcnt == 0) {
    800034da:	e719                	bnez	a4,800034e8 <brelse+0x64>
    b->time = ticks;
    800034dc:	00006797          	auipc	a5,0x6
    800034e0:	b447a783          	lw	a5,-1212(a5) # 80009020 <ticks>
    800034e4:	44f92c23          	sw	a5,1112(s2)
  }
  
  release(&bcache.lock[id]);
    800034e8:	8526                	mv	a0,s1
    800034ea:	ffffe097          	auipc	ra,0xffffe
    800034ee:	8da080e7          	jalr	-1830(ra) # 80000dc4 <release>
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6902                	ld	s2,0(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret
    panic("brelse");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	09250513          	addi	a0,a0,146 # 80008590 <syscalls+0xd8>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	04a080e7          	jalr	74(ra) # 80000550 <panic>

000000008000350e <bpin>:

void
bpin(struct buf *b) {
    8000350e:	1101                	addi	sp,sp,-32
    80003510:	ec06                	sd	ra,24(sp)
    80003512:	e822                	sd	s0,16(sp)
    80003514:	e426                	sd	s1,8(sp)
    80003516:	e04a                	sd	s2,0(sp)
    80003518:	1000                	addi	s0,sp,32
    8000351a:	892a                	mv	s2,a0
  int result = n % NBUCKET;
    8000351c:	4544                	lw	s1,12(a0)
  int id = hash(b->blockno);
  acquire(&bcache.lock[id]);
    8000351e:	47b5                	li	a5,13
    80003520:	02f4e4bb          	remw	s1,s1,a5
    80003524:	0496                	slli	s1,s1,0x5
    80003526:	00015797          	auipc	a5,0x15
    8000352a:	ea278793          	addi	a5,a5,-350 # 800183c8 <bcache>
    8000352e:	94be                	add	s1,s1,a5
    80003530:	8526                	mv	a0,s1
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	7c2080e7          	jalr	1986(ra) # 80000cf4 <acquire>
  b->refcnt++;
    8000353a:	04892783          	lw	a5,72(s2)
    8000353e:	2785                	addiw	a5,a5,1
    80003540:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[id]);
    80003544:	8526                	mv	a0,s1
    80003546:	ffffe097          	auipc	ra,0xffffe
    8000354a:	87e080e7          	jalr	-1922(ra) # 80000dc4 <release>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	64a2                	ld	s1,8(sp)
    80003554:	6902                	ld	s2,0(sp)
    80003556:	6105                	addi	sp,sp,32
    80003558:	8082                	ret

000000008000355a <bunpin>:

void
bunpin(struct buf *b) {
    8000355a:	1101                	addi	sp,sp,-32
    8000355c:	ec06                	sd	ra,24(sp)
    8000355e:	e822                	sd	s0,16(sp)
    80003560:	e426                	sd	s1,8(sp)
    80003562:	e04a                	sd	s2,0(sp)
    80003564:	1000                	addi	s0,sp,32
    80003566:	892a                	mv	s2,a0
  int result = n % NBUCKET;
    80003568:	4544                	lw	s1,12(a0)
  int id = hash(b->blockno);
  acquire(&bcache.lock[id]);
    8000356a:	47b5                	li	a5,13
    8000356c:	02f4e4bb          	remw	s1,s1,a5
    80003570:	0496                	slli	s1,s1,0x5
    80003572:	00015797          	auipc	a5,0x15
    80003576:	e5678793          	addi	a5,a5,-426 # 800183c8 <bcache>
    8000357a:	94be                	add	s1,s1,a5
    8000357c:	8526                	mv	a0,s1
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	776080e7          	jalr	1910(ra) # 80000cf4 <acquire>
  b->refcnt--;
    80003586:	04892783          	lw	a5,72(s2)
    8000358a:	37fd                	addiw	a5,a5,-1
    8000358c:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[id]);
    80003590:	8526                	mv	a0,s1
    80003592:	ffffe097          	auipc	ra,0xffffe
    80003596:	832080e7          	jalr	-1998(ra) # 80000dc4 <release>
}
    8000359a:	60e2                	ld	ra,24(sp)
    8000359c:	6442                	ld	s0,16(sp)
    8000359e:	64a2                	ld	s1,8(sp)
    800035a0:	6902                	ld	s2,0(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret

00000000800035a6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035a6:	1101                	addi	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	e426                	sd	s1,8(sp)
    800035ae:	e04a                	sd	s2,0(sp)
    800035b0:	1000                	addi	s0,sp,32
    800035b2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035b4:	00d5d59b          	srliw	a1,a1,0xd
    800035b8:	00039797          	auipc	a5,0x39
    800035bc:	5ac7a783          	lw	a5,1452(a5) # 8003cb64 <sb+0x1c>
    800035c0:	9dbd                	addw	a1,a1,a5
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	bec080e7          	jalr	-1044(ra) # 800031ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035ca:	0074f713          	andi	a4,s1,7
    800035ce:	4785                	li	a5,1
    800035d0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035d4:	14ce                	slli	s1,s1,0x33
    800035d6:	90d9                	srli	s1,s1,0x36
    800035d8:	00950733          	add	a4,a0,s1
    800035dc:	05874703          	lbu	a4,88(a4)
    800035e0:	00e7f6b3          	and	a3,a5,a4
    800035e4:	c69d                	beqz	a3,80003612 <bfree+0x6c>
    800035e6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035e8:	94aa                	add	s1,s1,a0
    800035ea:	fff7c793          	not	a5,a5
    800035ee:	8ff9                	and	a5,a5,a4
    800035f0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035f4:	00001097          	auipc	ra,0x1
    800035f8:	116080e7          	jalr	278(ra) # 8000470a <log_write>
  brelse(bp);
    800035fc:	854a                	mv	a0,s2
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	e86080e7          	jalr	-378(ra) # 80003484 <brelse>
}
    80003606:	60e2                	ld	ra,24(sp)
    80003608:	6442                	ld	s0,16(sp)
    8000360a:	64a2                	ld	s1,8(sp)
    8000360c:	6902                	ld	s2,0(sp)
    8000360e:	6105                	addi	sp,sp,32
    80003610:	8082                	ret
    panic("freeing free block");
    80003612:	00005517          	auipc	a0,0x5
    80003616:	f8650513          	addi	a0,a0,-122 # 80008598 <syscalls+0xe0>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	f36080e7          	jalr	-202(ra) # 80000550 <panic>

0000000080003622 <balloc>:
{
    80003622:	711d                	addi	sp,sp,-96
    80003624:	ec86                	sd	ra,88(sp)
    80003626:	e8a2                	sd	s0,80(sp)
    80003628:	e4a6                	sd	s1,72(sp)
    8000362a:	e0ca                	sd	s2,64(sp)
    8000362c:	fc4e                	sd	s3,56(sp)
    8000362e:	f852                	sd	s4,48(sp)
    80003630:	f456                	sd	s5,40(sp)
    80003632:	f05a                	sd	s6,32(sp)
    80003634:	ec5e                	sd	s7,24(sp)
    80003636:	e862                	sd	s8,16(sp)
    80003638:	e466                	sd	s9,8(sp)
    8000363a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000363c:	00039797          	auipc	a5,0x39
    80003640:	5107a783          	lw	a5,1296(a5) # 8003cb4c <sb+0x4>
    80003644:	cbd1                	beqz	a5,800036d8 <balloc+0xb6>
    80003646:	8baa                	mv	s7,a0
    80003648:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000364a:	00039b17          	auipc	s6,0x39
    8000364e:	4feb0b13          	addi	s6,s6,1278 # 8003cb48 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003652:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003654:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003656:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003658:	6c89                	lui	s9,0x2
    8000365a:	a831                	j	80003676 <balloc+0x54>
    brelse(bp);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	e26080e7          	jalr	-474(ra) # 80003484 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003666:	015c87bb          	addw	a5,s9,s5
    8000366a:	00078a9b          	sext.w	s5,a5
    8000366e:	004b2703          	lw	a4,4(s6)
    80003672:	06eaf363          	bgeu	s5,a4,800036d8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003676:	41fad79b          	sraiw	a5,s5,0x1f
    8000367a:	0137d79b          	srliw	a5,a5,0x13
    8000367e:	015787bb          	addw	a5,a5,s5
    80003682:	40d7d79b          	sraiw	a5,a5,0xd
    80003686:	01cb2583          	lw	a1,28(s6)
    8000368a:	9dbd                	addw	a1,a1,a5
    8000368c:	855e                	mv	a0,s7
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	b20080e7          	jalr	-1248(ra) # 800031ae <bread>
    80003696:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003698:	004b2503          	lw	a0,4(s6)
    8000369c:	000a849b          	sext.w	s1,s5
    800036a0:	8662                	mv	a2,s8
    800036a2:	faa4fde3          	bgeu	s1,a0,8000365c <balloc+0x3a>
      m = 1 << (bi % 8);
    800036a6:	41f6579b          	sraiw	a5,a2,0x1f
    800036aa:	01d7d69b          	srliw	a3,a5,0x1d
    800036ae:	00c6873b          	addw	a4,a3,a2
    800036b2:	00777793          	andi	a5,a4,7
    800036b6:	9f95                	subw	a5,a5,a3
    800036b8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036bc:	4037571b          	sraiw	a4,a4,0x3
    800036c0:	00e906b3          	add	a3,s2,a4
    800036c4:	0586c683          	lbu	a3,88(a3)
    800036c8:	00d7f5b3          	and	a1,a5,a3
    800036cc:	cd91                	beqz	a1,800036e8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ce:	2605                	addiw	a2,a2,1
    800036d0:	2485                	addiw	s1,s1,1
    800036d2:	fd4618e3          	bne	a2,s4,800036a2 <balloc+0x80>
    800036d6:	b759                	j	8000365c <balloc+0x3a>
  panic("balloc: out of blocks");
    800036d8:	00005517          	auipc	a0,0x5
    800036dc:	ed850513          	addi	a0,a0,-296 # 800085b0 <syscalls+0xf8>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	e70080e7          	jalr	-400(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036e8:	974a                	add	a4,a4,s2
    800036ea:	8fd5                	or	a5,a5,a3
    800036ec:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036f0:	854a                	mv	a0,s2
    800036f2:	00001097          	auipc	ra,0x1
    800036f6:	018080e7          	jalr	24(ra) # 8000470a <log_write>
        brelse(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	d88080e7          	jalr	-632(ra) # 80003484 <brelse>
  bp = bread(dev, bno);
    80003704:	85a6                	mv	a1,s1
    80003706:	855e                	mv	a0,s7
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	aa6080e7          	jalr	-1370(ra) # 800031ae <bread>
    80003710:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003712:	40000613          	li	a2,1024
    80003716:	4581                	li	a1,0
    80003718:	05850513          	addi	a0,a0,88
    8000371c:	ffffe097          	auipc	ra,0xffffe
    80003720:	9b8080e7          	jalr	-1608(ra) # 800010d4 <memset>
  log_write(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00001097          	auipc	ra,0x1
    8000372a:	fe4080e7          	jalr	-28(ra) # 8000470a <log_write>
  brelse(bp);
    8000372e:	854a                	mv	a0,s2
    80003730:	00000097          	auipc	ra,0x0
    80003734:	d54080e7          	jalr	-684(ra) # 80003484 <brelse>
}
    80003738:	8526                	mv	a0,s1
    8000373a:	60e6                	ld	ra,88(sp)
    8000373c:	6446                	ld	s0,80(sp)
    8000373e:	64a6                	ld	s1,72(sp)
    80003740:	6906                	ld	s2,64(sp)
    80003742:	79e2                	ld	s3,56(sp)
    80003744:	7a42                	ld	s4,48(sp)
    80003746:	7aa2                	ld	s5,40(sp)
    80003748:	7b02                	ld	s6,32(sp)
    8000374a:	6be2                	ld	s7,24(sp)
    8000374c:	6c42                	ld	s8,16(sp)
    8000374e:	6ca2                	ld	s9,8(sp)
    80003750:	6125                	addi	sp,sp,96
    80003752:	8082                	ret

0000000080003754 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003754:	7179                	addi	sp,sp,-48
    80003756:	f406                	sd	ra,40(sp)
    80003758:	f022                	sd	s0,32(sp)
    8000375a:	ec26                	sd	s1,24(sp)
    8000375c:	e84a                	sd	s2,16(sp)
    8000375e:	e44e                	sd	s3,8(sp)
    80003760:	e052                	sd	s4,0(sp)
    80003762:	1800                	addi	s0,sp,48
    80003764:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003766:	47ad                	li	a5,11
    80003768:	04b7fe63          	bgeu	a5,a1,800037c4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000376c:	ff45849b          	addiw	s1,a1,-12
    80003770:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003774:	0ff00793          	li	a5,255
    80003778:	0ae7e363          	bltu	a5,a4,8000381e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000377c:	08852583          	lw	a1,136(a0)
    80003780:	c5ad                	beqz	a1,800037ea <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003782:	00092503          	lw	a0,0(s2)
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	a28080e7          	jalr	-1496(ra) # 800031ae <bread>
    8000378e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003790:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003794:	02049593          	slli	a1,s1,0x20
    80003798:	9181                	srli	a1,a1,0x20
    8000379a:	058a                	slli	a1,a1,0x2
    8000379c:	00b784b3          	add	s1,a5,a1
    800037a0:	0004a983          	lw	s3,0(s1)
    800037a4:	04098d63          	beqz	s3,800037fe <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037a8:	8552                	mv	a0,s4
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	cda080e7          	jalr	-806(ra) # 80003484 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037b2:	854e                	mv	a0,s3
    800037b4:	70a2                	ld	ra,40(sp)
    800037b6:	7402                	ld	s0,32(sp)
    800037b8:	64e2                	ld	s1,24(sp)
    800037ba:	6942                	ld	s2,16(sp)
    800037bc:	69a2                	ld	s3,8(sp)
    800037be:	6a02                	ld	s4,0(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037c4:	02059493          	slli	s1,a1,0x20
    800037c8:	9081                	srli	s1,s1,0x20
    800037ca:	048a                	slli	s1,s1,0x2
    800037cc:	94aa                	add	s1,s1,a0
    800037ce:	0584a983          	lw	s3,88(s1)
    800037d2:	fe0990e3          	bnez	s3,800037b2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037d6:	4108                	lw	a0,0(a0)
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	e4a080e7          	jalr	-438(ra) # 80003622 <balloc>
    800037e0:	0005099b          	sext.w	s3,a0
    800037e4:	0534ac23          	sw	s3,88(s1)
    800037e8:	b7e9                	j	800037b2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037ea:	4108                	lw	a0,0(a0)
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	e36080e7          	jalr	-458(ra) # 80003622 <balloc>
    800037f4:	0005059b          	sext.w	a1,a0
    800037f8:	08b92423          	sw	a1,136(s2)
    800037fc:	b759                	j	80003782 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037fe:	00092503          	lw	a0,0(s2)
    80003802:	00000097          	auipc	ra,0x0
    80003806:	e20080e7          	jalr	-480(ra) # 80003622 <balloc>
    8000380a:	0005099b          	sext.w	s3,a0
    8000380e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003812:	8552                	mv	a0,s4
    80003814:	00001097          	auipc	ra,0x1
    80003818:	ef6080e7          	jalr	-266(ra) # 8000470a <log_write>
    8000381c:	b771                	j	800037a8 <bmap+0x54>
  panic("bmap: out of range");
    8000381e:	00005517          	auipc	a0,0x5
    80003822:	daa50513          	addi	a0,a0,-598 # 800085c8 <syscalls+0x110>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	d2a080e7          	jalr	-726(ra) # 80000550 <panic>

000000008000382e <iget>:
{
    8000382e:	7179                	addi	sp,sp,-48
    80003830:	f406                	sd	ra,40(sp)
    80003832:	f022                	sd	s0,32(sp)
    80003834:	ec26                	sd	s1,24(sp)
    80003836:	e84a                	sd	s2,16(sp)
    80003838:	e44e                	sd	s3,8(sp)
    8000383a:	e052                	sd	s4,0(sp)
    8000383c:	1800                	addi	s0,sp,48
    8000383e:	89aa                	mv	s3,a0
    80003840:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003842:	00039517          	auipc	a0,0x39
    80003846:	32650513          	addi	a0,a0,806 # 8003cb68 <icache>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	4aa080e7          	jalr	1194(ra) # 80000cf4 <acquire>
  empty = 0;
    80003852:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003854:	00039497          	auipc	s1,0x39
    80003858:	33448493          	addi	s1,s1,820 # 8003cb88 <icache+0x20>
    8000385c:	0003b697          	auipc	a3,0x3b
    80003860:	f4c68693          	addi	a3,a3,-180 # 8003e7a8 <log>
    80003864:	a039                	j	80003872 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003866:	02090b63          	beqz	s2,8000389c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000386a:	09048493          	addi	s1,s1,144
    8000386e:	02d48a63          	beq	s1,a3,800038a2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003872:	449c                	lw	a5,8(s1)
    80003874:	fef059e3          	blez	a5,80003866 <iget+0x38>
    80003878:	4098                	lw	a4,0(s1)
    8000387a:	ff3716e3          	bne	a4,s3,80003866 <iget+0x38>
    8000387e:	40d8                	lw	a4,4(s1)
    80003880:	ff4713e3          	bne	a4,s4,80003866 <iget+0x38>
      ip->ref++;
    80003884:	2785                	addiw	a5,a5,1
    80003886:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003888:	00039517          	auipc	a0,0x39
    8000388c:	2e050513          	addi	a0,a0,736 # 8003cb68 <icache>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	534080e7          	jalr	1332(ra) # 80000dc4 <release>
      return ip;
    80003898:	8926                	mv	s2,s1
    8000389a:	a03d                	j	800038c8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000389c:	f7f9                	bnez	a5,8000386a <iget+0x3c>
    8000389e:	8926                	mv	s2,s1
    800038a0:	b7e9                	j	8000386a <iget+0x3c>
  if(empty == 0)
    800038a2:	02090c63          	beqz	s2,800038da <iget+0xac>
  ip->dev = dev;
    800038a6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038aa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038ae:	4785                	li	a5,1
    800038b0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038b4:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800038b8:	00039517          	auipc	a0,0x39
    800038bc:	2b050513          	addi	a0,a0,688 # 8003cb68 <icache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	504080e7          	jalr	1284(ra) # 80000dc4 <release>
}
    800038c8:	854a                	mv	a0,s2
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6a02                	ld	s4,0(sp)
    800038d6:	6145                	addi	sp,sp,48
    800038d8:	8082                	ret
    panic("iget: no inodes");
    800038da:	00005517          	auipc	a0,0x5
    800038de:	d0650513          	addi	a0,a0,-762 # 800085e0 <syscalls+0x128>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	c6e080e7          	jalr	-914(ra) # 80000550 <panic>

00000000800038ea <fsinit>:
fsinit(int dev) {
    800038ea:	7179                	addi	sp,sp,-48
    800038ec:	f406                	sd	ra,40(sp)
    800038ee:	f022                	sd	s0,32(sp)
    800038f0:	ec26                	sd	s1,24(sp)
    800038f2:	e84a                	sd	s2,16(sp)
    800038f4:	e44e                	sd	s3,8(sp)
    800038f6:	1800                	addi	s0,sp,48
    800038f8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038fa:	4585                	li	a1,1
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	8b2080e7          	jalr	-1870(ra) # 800031ae <bread>
    80003904:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003906:	00039997          	auipc	s3,0x39
    8000390a:	24298993          	addi	s3,s3,578 # 8003cb48 <sb>
    8000390e:	02000613          	li	a2,32
    80003912:	05850593          	addi	a1,a0,88
    80003916:	854e                	mv	a0,s3
    80003918:	ffffe097          	auipc	ra,0xffffe
    8000391c:	81c080e7          	jalr	-2020(ra) # 80001134 <memmove>
  brelse(bp);
    80003920:	8526                	mv	a0,s1
    80003922:	00000097          	auipc	ra,0x0
    80003926:	b62080e7          	jalr	-1182(ra) # 80003484 <brelse>
  if(sb.magic != FSMAGIC)
    8000392a:	0009a703          	lw	a4,0(s3)
    8000392e:	102037b7          	lui	a5,0x10203
    80003932:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003936:	02f71263          	bne	a4,a5,8000395a <fsinit+0x70>
  initlog(dev, &sb);
    8000393a:	00039597          	auipc	a1,0x39
    8000393e:	20e58593          	addi	a1,a1,526 # 8003cb48 <sb>
    80003942:	854a                	mv	a0,s2
    80003944:	00001097          	auipc	ra,0x1
    80003948:	b4a080e7          	jalr	-1206(ra) # 8000448e <initlog>
}
    8000394c:	70a2                	ld	ra,40(sp)
    8000394e:	7402                	ld	s0,32(sp)
    80003950:	64e2                	ld	s1,24(sp)
    80003952:	6942                	ld	s2,16(sp)
    80003954:	69a2                	ld	s3,8(sp)
    80003956:	6145                	addi	sp,sp,48
    80003958:	8082                	ret
    panic("invalid file system");
    8000395a:	00005517          	auipc	a0,0x5
    8000395e:	c9650513          	addi	a0,a0,-874 # 800085f0 <syscalls+0x138>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	bee080e7          	jalr	-1042(ra) # 80000550 <panic>

000000008000396a <iinit>:
{
    8000396a:	7179                	addi	sp,sp,-48
    8000396c:	f406                	sd	ra,40(sp)
    8000396e:	f022                	sd	s0,32(sp)
    80003970:	ec26                	sd	s1,24(sp)
    80003972:	e84a                	sd	s2,16(sp)
    80003974:	e44e                	sd	s3,8(sp)
    80003976:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003978:	00005597          	auipc	a1,0x5
    8000397c:	c9058593          	addi	a1,a1,-880 # 80008608 <syscalls+0x150>
    80003980:	00039517          	auipc	a0,0x39
    80003984:	1e850513          	addi	a0,a0,488 # 8003cb68 <icache>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	4e8080e7          	jalr	1256(ra) # 80000e70 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003990:	00039497          	auipc	s1,0x39
    80003994:	20848493          	addi	s1,s1,520 # 8003cb98 <icache+0x30>
    80003998:	0003b997          	auipc	s3,0x3b
    8000399c:	e2098993          	addi	s3,s3,-480 # 8003e7b8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800039a0:	00005917          	auipc	s2,0x5
    800039a4:	c7090913          	addi	s2,s2,-912 # 80008610 <syscalls+0x158>
    800039a8:	85ca                	mv	a1,s2
    800039aa:	8526                	mv	a0,s1
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	e4c080e7          	jalr	-436(ra) # 800047f8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039b4:	09048493          	addi	s1,s1,144
    800039b8:	ff3498e3          	bne	s1,s3,800039a8 <iinit+0x3e>
}
    800039bc:	70a2                	ld	ra,40(sp)
    800039be:	7402                	ld	s0,32(sp)
    800039c0:	64e2                	ld	s1,24(sp)
    800039c2:	6942                	ld	s2,16(sp)
    800039c4:	69a2                	ld	s3,8(sp)
    800039c6:	6145                	addi	sp,sp,48
    800039c8:	8082                	ret

00000000800039ca <ialloc>:
{
    800039ca:	715d                	addi	sp,sp,-80
    800039cc:	e486                	sd	ra,72(sp)
    800039ce:	e0a2                	sd	s0,64(sp)
    800039d0:	fc26                	sd	s1,56(sp)
    800039d2:	f84a                	sd	s2,48(sp)
    800039d4:	f44e                	sd	s3,40(sp)
    800039d6:	f052                	sd	s4,32(sp)
    800039d8:	ec56                	sd	s5,24(sp)
    800039da:	e85a                	sd	s6,16(sp)
    800039dc:	e45e                	sd	s7,8(sp)
    800039de:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e0:	00039717          	auipc	a4,0x39
    800039e4:	17472703          	lw	a4,372(a4) # 8003cb54 <sb+0xc>
    800039e8:	4785                	li	a5,1
    800039ea:	04e7fa63          	bgeu	a5,a4,80003a3e <ialloc+0x74>
    800039ee:	8aaa                	mv	s5,a0
    800039f0:	8bae                	mv	s7,a1
    800039f2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039f4:	00039a17          	auipc	s4,0x39
    800039f8:	154a0a13          	addi	s4,s4,340 # 8003cb48 <sb>
    800039fc:	00048b1b          	sext.w	s6,s1
    80003a00:	0044d593          	srli	a1,s1,0x4
    80003a04:	018a2783          	lw	a5,24(s4)
    80003a08:	9dbd                	addw	a1,a1,a5
    80003a0a:	8556                	mv	a0,s5
    80003a0c:	fffff097          	auipc	ra,0xfffff
    80003a10:	7a2080e7          	jalr	1954(ra) # 800031ae <bread>
    80003a14:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a16:	05850993          	addi	s3,a0,88
    80003a1a:	00f4f793          	andi	a5,s1,15
    80003a1e:	079a                	slli	a5,a5,0x6
    80003a20:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a22:	00099783          	lh	a5,0(s3)
    80003a26:	c785                	beqz	a5,80003a4e <ialloc+0x84>
    brelse(bp);
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	a5c080e7          	jalr	-1444(ra) # 80003484 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a30:	0485                	addi	s1,s1,1
    80003a32:	00ca2703          	lw	a4,12(s4)
    80003a36:	0004879b          	sext.w	a5,s1
    80003a3a:	fce7e1e3          	bltu	a5,a4,800039fc <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a3e:	00005517          	auipc	a0,0x5
    80003a42:	bda50513          	addi	a0,a0,-1062 # 80008618 <syscalls+0x160>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	b0a080e7          	jalr	-1270(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    80003a4e:	04000613          	li	a2,64
    80003a52:	4581                	li	a1,0
    80003a54:	854e                	mv	a0,s3
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	67e080e7          	jalr	1662(ra) # 800010d4 <memset>
      dip->type = type;
    80003a5e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	ca6080e7          	jalr	-858(ra) # 8000470a <log_write>
      brelse(bp);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	a16080e7          	jalr	-1514(ra) # 80003484 <brelse>
      return iget(dev, inum);
    80003a76:	85da                	mv	a1,s6
    80003a78:	8556                	mv	a0,s5
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	db4080e7          	jalr	-588(ra) # 8000382e <iget>
}
    80003a82:	60a6                	ld	ra,72(sp)
    80003a84:	6406                	ld	s0,64(sp)
    80003a86:	74e2                	ld	s1,56(sp)
    80003a88:	7942                	ld	s2,48(sp)
    80003a8a:	79a2                	ld	s3,40(sp)
    80003a8c:	7a02                	ld	s4,32(sp)
    80003a8e:	6ae2                	ld	s5,24(sp)
    80003a90:	6b42                	ld	s6,16(sp)
    80003a92:	6ba2                	ld	s7,8(sp)
    80003a94:	6161                	addi	sp,sp,80
    80003a96:	8082                	ret

0000000080003a98 <iupdate>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	e04a                	sd	s2,0(sp)
    80003aa2:	1000                	addi	s0,sp,32
    80003aa4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aa6:	415c                	lw	a5,4(a0)
    80003aa8:	0047d79b          	srliw	a5,a5,0x4
    80003aac:	00039597          	auipc	a1,0x39
    80003ab0:	0b45a583          	lw	a1,180(a1) # 8003cb60 <sb+0x18>
    80003ab4:	9dbd                	addw	a1,a1,a5
    80003ab6:	4108                	lw	a0,0(a0)
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	6f6080e7          	jalr	1782(ra) # 800031ae <bread>
    80003ac0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ac2:	05850793          	addi	a5,a0,88
    80003ac6:	40c8                	lw	a0,4(s1)
    80003ac8:	893d                	andi	a0,a0,15
    80003aca:	051a                	slli	a0,a0,0x6
    80003acc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ace:	04c49703          	lh	a4,76(s1)
    80003ad2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ad6:	04e49703          	lh	a4,78(s1)
    80003ada:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ade:	05049703          	lh	a4,80(s1)
    80003ae2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ae6:	05249703          	lh	a4,82(s1)
    80003aea:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003aee:	48f8                	lw	a4,84(s1)
    80003af0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003af2:	03400613          	li	a2,52
    80003af6:	05848593          	addi	a1,s1,88
    80003afa:	0531                	addi	a0,a0,12
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	638080e7          	jalr	1592(ra) # 80001134 <memmove>
  log_write(bp);
    80003b04:	854a                	mv	a0,s2
    80003b06:	00001097          	auipc	ra,0x1
    80003b0a:	c04080e7          	jalr	-1020(ra) # 8000470a <log_write>
  brelse(bp);
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	974080e7          	jalr	-1676(ra) # 80003484 <brelse>
}
    80003b18:	60e2                	ld	ra,24(sp)
    80003b1a:	6442                	ld	s0,16(sp)
    80003b1c:	64a2                	ld	s1,8(sp)
    80003b1e:	6902                	ld	s2,0(sp)
    80003b20:	6105                	addi	sp,sp,32
    80003b22:	8082                	ret

0000000080003b24 <idup>:
{
    80003b24:	1101                	addi	sp,sp,-32
    80003b26:	ec06                	sd	ra,24(sp)
    80003b28:	e822                	sd	s0,16(sp)
    80003b2a:	e426                	sd	s1,8(sp)
    80003b2c:	1000                	addi	s0,sp,32
    80003b2e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b30:	00039517          	auipc	a0,0x39
    80003b34:	03850513          	addi	a0,a0,56 # 8003cb68 <icache>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	1bc080e7          	jalr	444(ra) # 80000cf4 <acquire>
  ip->ref++;
    80003b40:	449c                	lw	a5,8(s1)
    80003b42:	2785                	addiw	a5,a5,1
    80003b44:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b46:	00039517          	auipc	a0,0x39
    80003b4a:	02250513          	addi	a0,a0,34 # 8003cb68 <icache>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	276080e7          	jalr	630(ra) # 80000dc4 <release>
}
    80003b56:	8526                	mv	a0,s1
    80003b58:	60e2                	ld	ra,24(sp)
    80003b5a:	6442                	ld	s0,16(sp)
    80003b5c:	64a2                	ld	s1,8(sp)
    80003b5e:	6105                	addi	sp,sp,32
    80003b60:	8082                	ret

0000000080003b62 <ilock>:
{
    80003b62:	1101                	addi	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	e426                	sd	s1,8(sp)
    80003b6a:	e04a                	sd	s2,0(sp)
    80003b6c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b6e:	c115                	beqz	a0,80003b92 <ilock+0x30>
    80003b70:	84aa                	mv	s1,a0
    80003b72:	451c                	lw	a5,8(a0)
    80003b74:	00f05f63          	blez	a5,80003b92 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b78:	0541                	addi	a0,a0,16
    80003b7a:	00001097          	auipc	ra,0x1
    80003b7e:	cb8080e7          	jalr	-840(ra) # 80004832 <acquiresleep>
  if(ip->valid == 0){
    80003b82:	44bc                	lw	a5,72(s1)
    80003b84:	cf99                	beqz	a5,80003ba2 <ilock+0x40>
}
    80003b86:	60e2                	ld	ra,24(sp)
    80003b88:	6442                	ld	s0,16(sp)
    80003b8a:	64a2                	ld	s1,8(sp)
    80003b8c:	6902                	ld	s2,0(sp)
    80003b8e:	6105                	addi	sp,sp,32
    80003b90:	8082                	ret
    panic("ilock");
    80003b92:	00005517          	auipc	a0,0x5
    80003b96:	a9e50513          	addi	a0,a0,-1378 # 80008630 <syscalls+0x178>
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	9b6080e7          	jalr	-1610(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba2:	40dc                	lw	a5,4(s1)
    80003ba4:	0047d79b          	srliw	a5,a5,0x4
    80003ba8:	00039597          	auipc	a1,0x39
    80003bac:	fb85a583          	lw	a1,-72(a1) # 8003cb60 <sb+0x18>
    80003bb0:	9dbd                	addw	a1,a1,a5
    80003bb2:	4088                	lw	a0,0(s1)
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	5fa080e7          	jalr	1530(ra) # 800031ae <bread>
    80003bbc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bbe:	05850593          	addi	a1,a0,88
    80003bc2:	40dc                	lw	a5,4(s1)
    80003bc4:	8bbd                	andi	a5,a5,15
    80003bc6:	079a                	slli	a5,a5,0x6
    80003bc8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bca:	00059783          	lh	a5,0(a1)
    80003bce:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003bd2:	00259783          	lh	a5,2(a1)
    80003bd6:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003bda:	00459783          	lh	a5,4(a1)
    80003bde:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003be2:	00659783          	lh	a5,6(a1)
    80003be6:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003bea:	459c                	lw	a5,8(a1)
    80003bec:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bee:	03400613          	li	a2,52
    80003bf2:	05b1                	addi	a1,a1,12
    80003bf4:	05848513          	addi	a0,s1,88
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	53c080e7          	jalr	1340(ra) # 80001134 <memmove>
    brelse(bp);
    80003c00:	854a                	mv	a0,s2
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	882080e7          	jalr	-1918(ra) # 80003484 <brelse>
    ip->valid = 1;
    80003c0a:	4785                	li	a5,1
    80003c0c:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003c0e:	04c49783          	lh	a5,76(s1)
    80003c12:	fbb5                	bnez	a5,80003b86 <ilock+0x24>
      panic("ilock: no type");
    80003c14:	00005517          	auipc	a0,0x5
    80003c18:	a2450513          	addi	a0,a0,-1500 # 80008638 <syscalls+0x180>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	934080e7          	jalr	-1740(ra) # 80000550 <panic>

0000000080003c24 <iunlock>:
{
    80003c24:	1101                	addi	sp,sp,-32
    80003c26:	ec06                	sd	ra,24(sp)
    80003c28:	e822                	sd	s0,16(sp)
    80003c2a:	e426                	sd	s1,8(sp)
    80003c2c:	e04a                	sd	s2,0(sp)
    80003c2e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c30:	c905                	beqz	a0,80003c60 <iunlock+0x3c>
    80003c32:	84aa                	mv	s1,a0
    80003c34:	01050913          	addi	s2,a0,16
    80003c38:	854a                	mv	a0,s2
    80003c3a:	00001097          	auipc	ra,0x1
    80003c3e:	c92080e7          	jalr	-878(ra) # 800048cc <holdingsleep>
    80003c42:	cd19                	beqz	a0,80003c60 <iunlock+0x3c>
    80003c44:	449c                	lw	a5,8(s1)
    80003c46:	00f05d63          	blez	a5,80003c60 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c4a:	854a                	mv	a0,s2
    80003c4c:	00001097          	auipc	ra,0x1
    80003c50:	c3c080e7          	jalr	-964(ra) # 80004888 <releasesleep>
}
    80003c54:	60e2                	ld	ra,24(sp)
    80003c56:	6442                	ld	s0,16(sp)
    80003c58:	64a2                	ld	s1,8(sp)
    80003c5a:	6902                	ld	s2,0(sp)
    80003c5c:	6105                	addi	sp,sp,32
    80003c5e:	8082                	ret
    panic("iunlock");
    80003c60:	00005517          	auipc	a0,0x5
    80003c64:	9e850513          	addi	a0,a0,-1560 # 80008648 <syscalls+0x190>
    80003c68:	ffffd097          	auipc	ra,0xffffd
    80003c6c:	8e8080e7          	jalr	-1816(ra) # 80000550 <panic>

0000000080003c70 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c70:	7179                	addi	sp,sp,-48
    80003c72:	f406                	sd	ra,40(sp)
    80003c74:	f022                	sd	s0,32(sp)
    80003c76:	ec26                	sd	s1,24(sp)
    80003c78:	e84a                	sd	s2,16(sp)
    80003c7a:	e44e                	sd	s3,8(sp)
    80003c7c:	e052                	sd	s4,0(sp)
    80003c7e:	1800                	addi	s0,sp,48
    80003c80:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c82:	05850493          	addi	s1,a0,88
    80003c86:	08850913          	addi	s2,a0,136
    80003c8a:	a021                	j	80003c92 <itrunc+0x22>
    80003c8c:	0491                	addi	s1,s1,4
    80003c8e:	01248d63          	beq	s1,s2,80003ca8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c92:	408c                	lw	a1,0(s1)
    80003c94:	dde5                	beqz	a1,80003c8c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c96:	0009a503          	lw	a0,0(s3)
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	90c080e7          	jalr	-1780(ra) # 800035a6 <bfree>
      ip->addrs[i] = 0;
    80003ca2:	0004a023          	sw	zero,0(s1)
    80003ca6:	b7dd                	j	80003c8c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ca8:	0889a583          	lw	a1,136(s3)
    80003cac:	e185                	bnez	a1,80003ccc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cae:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003cb2:	854e                	mv	a0,s3
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	de4080e7          	jalr	-540(ra) # 80003a98 <iupdate>
}
    80003cbc:	70a2                	ld	ra,40(sp)
    80003cbe:	7402                	ld	s0,32(sp)
    80003cc0:	64e2                	ld	s1,24(sp)
    80003cc2:	6942                	ld	s2,16(sp)
    80003cc4:	69a2                	ld	s3,8(sp)
    80003cc6:	6a02                	ld	s4,0(sp)
    80003cc8:	6145                	addi	sp,sp,48
    80003cca:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ccc:	0009a503          	lw	a0,0(s3)
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	4de080e7          	jalr	1246(ra) # 800031ae <bread>
    80003cd8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cda:	05850493          	addi	s1,a0,88
    80003cde:	45850913          	addi	s2,a0,1112
    80003ce2:	a811                	j	80003cf6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ce4:	0009a503          	lw	a0,0(s3)
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	8be080e7          	jalr	-1858(ra) # 800035a6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003cf0:	0491                	addi	s1,s1,4
    80003cf2:	01248563          	beq	s1,s2,80003cfc <itrunc+0x8c>
      if(a[j])
    80003cf6:	408c                	lw	a1,0(s1)
    80003cf8:	dde5                	beqz	a1,80003cf0 <itrunc+0x80>
    80003cfa:	b7ed                	j	80003ce4 <itrunc+0x74>
    brelse(bp);
    80003cfc:	8552                	mv	a0,s4
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	786080e7          	jalr	1926(ra) # 80003484 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d06:	0889a583          	lw	a1,136(s3)
    80003d0a:	0009a503          	lw	a0,0(s3)
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	898080e7          	jalr	-1896(ra) # 800035a6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d16:	0809a423          	sw	zero,136(s3)
    80003d1a:	bf51                	j	80003cae <itrunc+0x3e>

0000000080003d1c <iput>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	e04a                	sd	s2,0(sp)
    80003d26:	1000                	addi	s0,sp,32
    80003d28:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003d2a:	00039517          	auipc	a0,0x39
    80003d2e:	e3e50513          	addi	a0,a0,-450 # 8003cb68 <icache>
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	fc2080e7          	jalr	-62(ra) # 80000cf4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d3a:	4498                	lw	a4,8(s1)
    80003d3c:	4785                	li	a5,1
    80003d3e:	02f70363          	beq	a4,a5,80003d64 <iput+0x48>
  ip->ref--;
    80003d42:	449c                	lw	a5,8(s1)
    80003d44:	37fd                	addiw	a5,a5,-1
    80003d46:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003d48:	00039517          	auipc	a0,0x39
    80003d4c:	e2050513          	addi	a0,a0,-480 # 8003cb68 <icache>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	074080e7          	jalr	116(ra) # 80000dc4 <release>
}
    80003d58:	60e2                	ld	ra,24(sp)
    80003d5a:	6442                	ld	s0,16(sp)
    80003d5c:	64a2                	ld	s1,8(sp)
    80003d5e:	6902                	ld	s2,0(sp)
    80003d60:	6105                	addi	sp,sp,32
    80003d62:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d64:	44bc                	lw	a5,72(s1)
    80003d66:	dff1                	beqz	a5,80003d42 <iput+0x26>
    80003d68:	05249783          	lh	a5,82(s1)
    80003d6c:	fbf9                	bnez	a5,80003d42 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d6e:	01048913          	addi	s2,s1,16
    80003d72:	854a                	mv	a0,s2
    80003d74:	00001097          	auipc	ra,0x1
    80003d78:	abe080e7          	jalr	-1346(ra) # 80004832 <acquiresleep>
    release(&icache.lock);
    80003d7c:	00039517          	auipc	a0,0x39
    80003d80:	dec50513          	addi	a0,a0,-532 # 8003cb68 <icache>
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	040080e7          	jalr	64(ra) # 80000dc4 <release>
    itrunc(ip);
    80003d8c:	8526                	mv	a0,s1
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	ee2080e7          	jalr	-286(ra) # 80003c70 <itrunc>
    ip->type = 0;
    80003d96:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	cfc080e7          	jalr	-772(ra) # 80003a98 <iupdate>
    ip->valid = 0;
    80003da4:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003da8:	854a                	mv	a0,s2
    80003daa:	00001097          	auipc	ra,0x1
    80003dae:	ade080e7          	jalr	-1314(ra) # 80004888 <releasesleep>
    acquire(&icache.lock);
    80003db2:	00039517          	auipc	a0,0x39
    80003db6:	db650513          	addi	a0,a0,-586 # 8003cb68 <icache>
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	f3a080e7          	jalr	-198(ra) # 80000cf4 <acquire>
    80003dc2:	b741                	j	80003d42 <iput+0x26>

0000000080003dc4 <iunlockput>:
{
    80003dc4:	1101                	addi	sp,sp,-32
    80003dc6:	ec06                	sd	ra,24(sp)
    80003dc8:	e822                	sd	s0,16(sp)
    80003dca:	e426                	sd	s1,8(sp)
    80003dcc:	1000                	addi	s0,sp,32
    80003dce:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	e54080e7          	jalr	-428(ra) # 80003c24 <iunlock>
  iput(ip);
    80003dd8:	8526                	mv	a0,s1
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	f42080e7          	jalr	-190(ra) # 80003d1c <iput>
}
    80003de2:	60e2                	ld	ra,24(sp)
    80003de4:	6442                	ld	s0,16(sp)
    80003de6:	64a2                	ld	s1,8(sp)
    80003de8:	6105                	addi	sp,sp,32
    80003dea:	8082                	ret

0000000080003dec <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dec:	1141                	addi	sp,sp,-16
    80003dee:	e422                	sd	s0,8(sp)
    80003df0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003df2:	411c                	lw	a5,0(a0)
    80003df4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003df6:	415c                	lw	a5,4(a0)
    80003df8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dfa:	04c51783          	lh	a5,76(a0)
    80003dfe:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e02:	05251783          	lh	a5,82(a0)
    80003e06:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e0a:	05456783          	lwu	a5,84(a0)
    80003e0e:	e99c                	sd	a5,16(a1)
}
    80003e10:	6422                	ld	s0,8(sp)
    80003e12:	0141                	addi	sp,sp,16
    80003e14:	8082                	ret

0000000080003e16 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e16:	497c                	lw	a5,84(a0)
    80003e18:	0ed7e963          	bltu	a5,a3,80003f0a <readi+0xf4>
{
    80003e1c:	7159                	addi	sp,sp,-112
    80003e1e:	f486                	sd	ra,104(sp)
    80003e20:	f0a2                	sd	s0,96(sp)
    80003e22:	eca6                	sd	s1,88(sp)
    80003e24:	e8ca                	sd	s2,80(sp)
    80003e26:	e4ce                	sd	s3,72(sp)
    80003e28:	e0d2                	sd	s4,64(sp)
    80003e2a:	fc56                	sd	s5,56(sp)
    80003e2c:	f85a                	sd	s6,48(sp)
    80003e2e:	f45e                	sd	s7,40(sp)
    80003e30:	f062                	sd	s8,32(sp)
    80003e32:	ec66                	sd	s9,24(sp)
    80003e34:	e86a                	sd	s10,16(sp)
    80003e36:	e46e                	sd	s11,8(sp)
    80003e38:	1880                	addi	s0,sp,112
    80003e3a:	8baa                	mv	s7,a0
    80003e3c:	8c2e                	mv	s8,a1
    80003e3e:	8ab2                	mv	s5,a2
    80003e40:	84b6                	mv	s1,a3
    80003e42:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e44:	9f35                	addw	a4,a4,a3
    return 0;
    80003e46:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e48:	0ad76063          	bltu	a4,a3,80003ee8 <readi+0xd2>
  if(off + n > ip->size)
    80003e4c:	00e7f463          	bgeu	a5,a4,80003e54 <readi+0x3e>
    n = ip->size - off;
    80003e50:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e54:	0a0b0963          	beqz	s6,80003f06 <readi+0xf0>
    80003e58:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e5e:	5cfd                	li	s9,-1
    80003e60:	a82d                	j	80003e9a <readi+0x84>
    80003e62:	020a1d93          	slli	s11,s4,0x20
    80003e66:	020ddd93          	srli	s11,s11,0x20
    80003e6a:	05890613          	addi	a2,s2,88
    80003e6e:	86ee                	mv	a3,s11
    80003e70:	963a                	add	a2,a2,a4
    80003e72:	85d6                	mv	a1,s5
    80003e74:	8562                	mv	a0,s8
    80003e76:	fffff097          	auipc	ra,0xfffff
    80003e7a:	938080e7          	jalr	-1736(ra) # 800027ae <either_copyout>
    80003e7e:	05950d63          	beq	a0,s9,80003ed8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e82:	854a                	mv	a0,s2
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	600080e7          	jalr	1536(ra) # 80003484 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e8c:	013a09bb          	addw	s3,s4,s3
    80003e90:	009a04bb          	addw	s1,s4,s1
    80003e94:	9aee                	add	s5,s5,s11
    80003e96:	0569f763          	bgeu	s3,s6,80003ee4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e9a:	000ba903          	lw	s2,0(s7)
    80003e9e:	00a4d59b          	srliw	a1,s1,0xa
    80003ea2:	855e                	mv	a0,s7
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	8b0080e7          	jalr	-1872(ra) # 80003754 <bmap>
    80003eac:	0005059b          	sext.w	a1,a0
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	2fc080e7          	jalr	764(ra) # 800031ae <bread>
    80003eba:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ebc:	3ff4f713          	andi	a4,s1,1023
    80003ec0:	40ed07bb          	subw	a5,s10,a4
    80003ec4:	413b06bb          	subw	a3,s6,s3
    80003ec8:	8a3e                	mv	s4,a5
    80003eca:	2781                	sext.w	a5,a5
    80003ecc:	0006861b          	sext.w	a2,a3
    80003ed0:	f8f679e3          	bgeu	a2,a5,80003e62 <readi+0x4c>
    80003ed4:	8a36                	mv	s4,a3
    80003ed6:	b771                	j	80003e62 <readi+0x4c>
      brelse(bp);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	fffff097          	auipc	ra,0xfffff
    80003ede:	5aa080e7          	jalr	1450(ra) # 80003484 <brelse>
      tot = -1;
    80003ee2:	59fd                	li	s3,-1
  }
  return tot;
    80003ee4:	0009851b          	sext.w	a0,s3
}
    80003ee8:	70a6                	ld	ra,104(sp)
    80003eea:	7406                	ld	s0,96(sp)
    80003eec:	64e6                	ld	s1,88(sp)
    80003eee:	6946                	ld	s2,80(sp)
    80003ef0:	69a6                	ld	s3,72(sp)
    80003ef2:	6a06                	ld	s4,64(sp)
    80003ef4:	7ae2                	ld	s5,56(sp)
    80003ef6:	7b42                	ld	s6,48(sp)
    80003ef8:	7ba2                	ld	s7,40(sp)
    80003efa:	7c02                	ld	s8,32(sp)
    80003efc:	6ce2                	ld	s9,24(sp)
    80003efe:	6d42                	ld	s10,16(sp)
    80003f00:	6da2                	ld	s11,8(sp)
    80003f02:	6165                	addi	sp,sp,112
    80003f04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f06:	89da                	mv	s3,s6
    80003f08:	bff1                	j	80003ee4 <readi+0xce>
    return 0;
    80003f0a:	4501                	li	a0,0
}
    80003f0c:	8082                	ret

0000000080003f0e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f0e:	497c                	lw	a5,84(a0)
    80003f10:	10d7e763          	bltu	a5,a3,8000401e <writei+0x110>
{
    80003f14:	7159                	addi	sp,sp,-112
    80003f16:	f486                	sd	ra,104(sp)
    80003f18:	f0a2                	sd	s0,96(sp)
    80003f1a:	eca6                	sd	s1,88(sp)
    80003f1c:	e8ca                	sd	s2,80(sp)
    80003f1e:	e4ce                	sd	s3,72(sp)
    80003f20:	e0d2                	sd	s4,64(sp)
    80003f22:	fc56                	sd	s5,56(sp)
    80003f24:	f85a                	sd	s6,48(sp)
    80003f26:	f45e                	sd	s7,40(sp)
    80003f28:	f062                	sd	s8,32(sp)
    80003f2a:	ec66                	sd	s9,24(sp)
    80003f2c:	e86a                	sd	s10,16(sp)
    80003f2e:	e46e                	sd	s11,8(sp)
    80003f30:	1880                	addi	s0,sp,112
    80003f32:	8baa                	mv	s7,a0
    80003f34:	8c2e                	mv	s8,a1
    80003f36:	8ab2                	mv	s5,a2
    80003f38:	8936                	mv	s2,a3
    80003f3a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f3c:	00e687bb          	addw	a5,a3,a4
    80003f40:	0ed7e163          	bltu	a5,a3,80004022 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f44:	00043737          	lui	a4,0x43
    80003f48:	0cf76f63          	bltu	a4,a5,80004026 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f4c:	0a0b0863          	beqz	s6,80003ffc <writei+0xee>
    80003f50:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f52:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f56:	5cfd                	li	s9,-1
    80003f58:	a091                	j	80003f9c <writei+0x8e>
    80003f5a:	02099d93          	slli	s11,s3,0x20
    80003f5e:	020ddd93          	srli	s11,s11,0x20
    80003f62:	05848513          	addi	a0,s1,88
    80003f66:	86ee                	mv	a3,s11
    80003f68:	8656                	mv	a2,s5
    80003f6a:	85e2                	mv	a1,s8
    80003f6c:	953a                	add	a0,a0,a4
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	896080e7          	jalr	-1898(ra) # 80002804 <either_copyin>
    80003f76:	07950263          	beq	a0,s9,80003fda <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003f7a:	8526                	mv	a0,s1
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	78e080e7          	jalr	1934(ra) # 8000470a <log_write>
    brelse(bp);
    80003f84:	8526                	mv	a0,s1
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	4fe080e7          	jalr	1278(ra) # 80003484 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f8e:	01498a3b          	addw	s4,s3,s4
    80003f92:	0129893b          	addw	s2,s3,s2
    80003f96:	9aee                	add	s5,s5,s11
    80003f98:	056a7763          	bgeu	s4,s6,80003fe6 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f9c:	000ba483          	lw	s1,0(s7)
    80003fa0:	00a9559b          	srliw	a1,s2,0xa
    80003fa4:	855e                	mv	a0,s7
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	7ae080e7          	jalr	1966(ra) # 80003754 <bmap>
    80003fae:	0005059b          	sext.w	a1,a0
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	1fa080e7          	jalr	506(ra) # 800031ae <bread>
    80003fbc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fbe:	3ff97713          	andi	a4,s2,1023
    80003fc2:	40ed07bb          	subw	a5,s10,a4
    80003fc6:	414b06bb          	subw	a3,s6,s4
    80003fca:	89be                	mv	s3,a5
    80003fcc:	2781                	sext.w	a5,a5
    80003fce:	0006861b          	sext.w	a2,a3
    80003fd2:	f8f674e3          	bgeu	a2,a5,80003f5a <writei+0x4c>
    80003fd6:	89b6                	mv	s3,a3
    80003fd8:	b749                	j	80003f5a <writei+0x4c>
      brelse(bp);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	4a8080e7          	jalr	1192(ra) # 80003484 <brelse>
      n = -1;
    80003fe4:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003fe6:	054ba783          	lw	a5,84(s7)
    80003fea:	0127f463          	bgeu	a5,s2,80003ff2 <writei+0xe4>
      ip->size = off;
    80003fee:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003ff2:	855e                	mv	a0,s7
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	aa4080e7          	jalr	-1372(ra) # 80003a98 <iupdate>
  }

  return n;
    80003ffc:	000b051b          	sext.w	a0,s6
}
    80004000:	70a6                	ld	ra,104(sp)
    80004002:	7406                	ld	s0,96(sp)
    80004004:	64e6                	ld	s1,88(sp)
    80004006:	6946                	ld	s2,80(sp)
    80004008:	69a6                	ld	s3,72(sp)
    8000400a:	6a06                	ld	s4,64(sp)
    8000400c:	7ae2                	ld	s5,56(sp)
    8000400e:	7b42                	ld	s6,48(sp)
    80004010:	7ba2                	ld	s7,40(sp)
    80004012:	7c02                	ld	s8,32(sp)
    80004014:	6ce2                	ld	s9,24(sp)
    80004016:	6d42                	ld	s10,16(sp)
    80004018:	6da2                	ld	s11,8(sp)
    8000401a:	6165                	addi	sp,sp,112
    8000401c:	8082                	ret
    return -1;
    8000401e:	557d                	li	a0,-1
}
    80004020:	8082                	ret
    return -1;
    80004022:	557d                	li	a0,-1
    80004024:	bff1                	j	80004000 <writei+0xf2>
    return -1;
    80004026:	557d                	li	a0,-1
    80004028:	bfe1                	j	80004000 <writei+0xf2>

000000008000402a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000402a:	1141                	addi	sp,sp,-16
    8000402c:	e406                	sd	ra,8(sp)
    8000402e:	e022                	sd	s0,0(sp)
    80004030:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004032:	4639                	li	a2,14
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	17c080e7          	jalr	380(ra) # 800011b0 <strncmp>
}
    8000403c:	60a2                	ld	ra,8(sp)
    8000403e:	6402                	ld	s0,0(sp)
    80004040:	0141                	addi	sp,sp,16
    80004042:	8082                	ret

0000000080004044 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004044:	7139                	addi	sp,sp,-64
    80004046:	fc06                	sd	ra,56(sp)
    80004048:	f822                	sd	s0,48(sp)
    8000404a:	f426                	sd	s1,40(sp)
    8000404c:	f04a                	sd	s2,32(sp)
    8000404e:	ec4e                	sd	s3,24(sp)
    80004050:	e852                	sd	s4,16(sp)
    80004052:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004054:	04c51703          	lh	a4,76(a0)
    80004058:	4785                	li	a5,1
    8000405a:	00f71a63          	bne	a4,a5,8000406e <dirlookup+0x2a>
    8000405e:	892a                	mv	s2,a0
    80004060:	89ae                	mv	s3,a1
    80004062:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004064:	497c                	lw	a5,84(a0)
    80004066:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004068:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406a:	e79d                	bnez	a5,80004098 <dirlookup+0x54>
    8000406c:	a8a5                	j	800040e4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000406e:	00004517          	auipc	a0,0x4
    80004072:	5e250513          	addi	a0,a0,1506 # 80008650 <syscalls+0x198>
    80004076:	ffffc097          	auipc	ra,0xffffc
    8000407a:	4da080e7          	jalr	1242(ra) # 80000550 <panic>
      panic("dirlookup read");
    8000407e:	00004517          	auipc	a0,0x4
    80004082:	5ea50513          	addi	a0,a0,1514 # 80008668 <syscalls+0x1b0>
    80004086:	ffffc097          	auipc	ra,0xffffc
    8000408a:	4ca080e7          	jalr	1226(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408e:	24c1                	addiw	s1,s1,16
    80004090:	05492783          	lw	a5,84(s2)
    80004094:	04f4f763          	bgeu	s1,a5,800040e2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004098:	4741                	li	a4,16
    8000409a:	86a6                	mv	a3,s1
    8000409c:	fc040613          	addi	a2,s0,-64
    800040a0:	4581                	li	a1,0
    800040a2:	854a                	mv	a0,s2
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	d72080e7          	jalr	-654(ra) # 80003e16 <readi>
    800040ac:	47c1                	li	a5,16
    800040ae:	fcf518e3          	bne	a0,a5,8000407e <dirlookup+0x3a>
    if(de.inum == 0)
    800040b2:	fc045783          	lhu	a5,-64(s0)
    800040b6:	dfe1                	beqz	a5,8000408e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040b8:	fc240593          	addi	a1,s0,-62
    800040bc:	854e                	mv	a0,s3
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	f6c080e7          	jalr	-148(ra) # 8000402a <namecmp>
    800040c6:	f561                	bnez	a0,8000408e <dirlookup+0x4a>
      if(poff)
    800040c8:	000a0463          	beqz	s4,800040d0 <dirlookup+0x8c>
        *poff = off;
    800040cc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040d0:	fc045583          	lhu	a1,-64(s0)
    800040d4:	00092503          	lw	a0,0(s2)
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	756080e7          	jalr	1878(ra) # 8000382e <iget>
    800040e0:	a011                	j	800040e4 <dirlookup+0xa0>
  return 0;
    800040e2:	4501                	li	a0,0
}
    800040e4:	70e2                	ld	ra,56(sp)
    800040e6:	7442                	ld	s0,48(sp)
    800040e8:	74a2                	ld	s1,40(sp)
    800040ea:	7902                	ld	s2,32(sp)
    800040ec:	69e2                	ld	s3,24(sp)
    800040ee:	6a42                	ld	s4,16(sp)
    800040f0:	6121                	addi	sp,sp,64
    800040f2:	8082                	ret

00000000800040f4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040f4:	711d                	addi	sp,sp,-96
    800040f6:	ec86                	sd	ra,88(sp)
    800040f8:	e8a2                	sd	s0,80(sp)
    800040fa:	e4a6                	sd	s1,72(sp)
    800040fc:	e0ca                	sd	s2,64(sp)
    800040fe:	fc4e                	sd	s3,56(sp)
    80004100:	f852                	sd	s4,48(sp)
    80004102:	f456                	sd	s5,40(sp)
    80004104:	f05a                	sd	s6,32(sp)
    80004106:	ec5e                	sd	s7,24(sp)
    80004108:	e862                	sd	s8,16(sp)
    8000410a:	e466                	sd	s9,8(sp)
    8000410c:	1080                	addi	s0,sp,96
    8000410e:	84aa                	mv	s1,a0
    80004110:	8b2e                	mv	s6,a1
    80004112:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004114:	00054703          	lbu	a4,0(a0)
    80004118:	02f00793          	li	a5,47
    8000411c:	02f70363          	beq	a4,a5,80004142 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004120:	ffffe097          	auipc	ra,0xffffe
    80004124:	c1c080e7          	jalr	-996(ra) # 80001d3c <myproc>
    80004128:	15853503          	ld	a0,344(a0)
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	9f8080e7          	jalr	-1544(ra) # 80003b24 <idup>
    80004134:	89aa                	mv	s3,a0
  while(*path == '/')
    80004136:	02f00913          	li	s2,47
  len = path - s;
    8000413a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000413c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000413e:	4c05                	li	s8,1
    80004140:	a865                	j	800041f8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004142:	4585                	li	a1,1
    80004144:	4505                	li	a0,1
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	6e8080e7          	jalr	1768(ra) # 8000382e <iget>
    8000414e:	89aa                	mv	s3,a0
    80004150:	b7dd                	j	80004136 <namex+0x42>
      iunlockput(ip);
    80004152:	854e                	mv	a0,s3
    80004154:	00000097          	auipc	ra,0x0
    80004158:	c70080e7          	jalr	-912(ra) # 80003dc4 <iunlockput>
      return 0;
    8000415c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000415e:	854e                	mv	a0,s3
    80004160:	60e6                	ld	ra,88(sp)
    80004162:	6446                	ld	s0,80(sp)
    80004164:	64a6                	ld	s1,72(sp)
    80004166:	6906                	ld	s2,64(sp)
    80004168:	79e2                	ld	s3,56(sp)
    8000416a:	7a42                	ld	s4,48(sp)
    8000416c:	7aa2                	ld	s5,40(sp)
    8000416e:	7b02                	ld	s6,32(sp)
    80004170:	6be2                	ld	s7,24(sp)
    80004172:	6c42                	ld	s8,16(sp)
    80004174:	6ca2                	ld	s9,8(sp)
    80004176:	6125                	addi	sp,sp,96
    80004178:	8082                	ret
      iunlock(ip);
    8000417a:	854e                	mv	a0,s3
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	aa8080e7          	jalr	-1368(ra) # 80003c24 <iunlock>
      return ip;
    80004184:	bfe9                	j	8000415e <namex+0x6a>
      iunlockput(ip);
    80004186:	854e                	mv	a0,s3
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	c3c080e7          	jalr	-964(ra) # 80003dc4 <iunlockput>
      return 0;
    80004190:	89d2                	mv	s3,s4
    80004192:	b7f1                	j	8000415e <namex+0x6a>
  len = path - s;
    80004194:	40b48633          	sub	a2,s1,a1
    80004198:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000419c:	094cd463          	bge	s9,s4,80004224 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041a0:	4639                	li	a2,14
    800041a2:	8556                	mv	a0,s5
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	f90080e7          	jalr	-112(ra) # 80001134 <memmove>
  while(*path == '/')
    800041ac:	0004c783          	lbu	a5,0(s1)
    800041b0:	01279763          	bne	a5,s2,800041be <namex+0xca>
    path++;
    800041b4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041b6:	0004c783          	lbu	a5,0(s1)
    800041ba:	ff278de3          	beq	a5,s2,800041b4 <namex+0xc0>
    ilock(ip);
    800041be:	854e                	mv	a0,s3
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	9a2080e7          	jalr	-1630(ra) # 80003b62 <ilock>
    if(ip->type != T_DIR){
    800041c8:	04c99783          	lh	a5,76(s3)
    800041cc:	f98793e3          	bne	a5,s8,80004152 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041d0:	000b0563          	beqz	s6,800041da <namex+0xe6>
    800041d4:	0004c783          	lbu	a5,0(s1)
    800041d8:	d3cd                	beqz	a5,8000417a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041da:	865e                	mv	a2,s7
    800041dc:	85d6                	mv	a1,s5
    800041de:	854e                	mv	a0,s3
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	e64080e7          	jalr	-412(ra) # 80004044 <dirlookup>
    800041e8:	8a2a                	mv	s4,a0
    800041ea:	dd51                	beqz	a0,80004186 <namex+0x92>
    iunlockput(ip);
    800041ec:	854e                	mv	a0,s3
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	bd6080e7          	jalr	-1066(ra) # 80003dc4 <iunlockput>
    ip = next;
    800041f6:	89d2                	mv	s3,s4
  while(*path == '/')
    800041f8:	0004c783          	lbu	a5,0(s1)
    800041fc:	05279763          	bne	a5,s2,8000424a <namex+0x156>
    path++;
    80004200:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004202:	0004c783          	lbu	a5,0(s1)
    80004206:	ff278de3          	beq	a5,s2,80004200 <namex+0x10c>
  if(*path == 0)
    8000420a:	c79d                	beqz	a5,80004238 <namex+0x144>
    path++;
    8000420c:	85a6                	mv	a1,s1
  len = path - s;
    8000420e:	8a5e                	mv	s4,s7
    80004210:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004212:	01278963          	beq	a5,s2,80004224 <namex+0x130>
    80004216:	dfbd                	beqz	a5,80004194 <namex+0xa0>
    path++;
    80004218:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000421a:	0004c783          	lbu	a5,0(s1)
    8000421e:	ff279ce3          	bne	a5,s2,80004216 <namex+0x122>
    80004222:	bf8d                	j	80004194 <namex+0xa0>
    memmove(name, s, len);
    80004224:	2601                	sext.w	a2,a2
    80004226:	8556                	mv	a0,s5
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	f0c080e7          	jalr	-244(ra) # 80001134 <memmove>
    name[len] = 0;
    80004230:	9a56                	add	s4,s4,s5
    80004232:	000a0023          	sb	zero,0(s4)
    80004236:	bf9d                	j	800041ac <namex+0xb8>
  if(nameiparent){
    80004238:	f20b03e3          	beqz	s6,8000415e <namex+0x6a>
    iput(ip);
    8000423c:	854e                	mv	a0,s3
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	ade080e7          	jalr	-1314(ra) # 80003d1c <iput>
    return 0;
    80004246:	4981                	li	s3,0
    80004248:	bf19                	j	8000415e <namex+0x6a>
  if(*path == 0)
    8000424a:	d7fd                	beqz	a5,80004238 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000424c:	0004c783          	lbu	a5,0(s1)
    80004250:	85a6                	mv	a1,s1
    80004252:	b7d1                	j	80004216 <namex+0x122>

0000000080004254 <dirlink>:
{
    80004254:	7139                	addi	sp,sp,-64
    80004256:	fc06                	sd	ra,56(sp)
    80004258:	f822                	sd	s0,48(sp)
    8000425a:	f426                	sd	s1,40(sp)
    8000425c:	f04a                	sd	s2,32(sp)
    8000425e:	ec4e                	sd	s3,24(sp)
    80004260:	e852                	sd	s4,16(sp)
    80004262:	0080                	addi	s0,sp,64
    80004264:	892a                	mv	s2,a0
    80004266:	8a2e                	mv	s4,a1
    80004268:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000426a:	4601                	li	a2,0
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	dd8080e7          	jalr	-552(ra) # 80004044 <dirlookup>
    80004274:	e93d                	bnez	a0,800042ea <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004276:	05492483          	lw	s1,84(s2)
    8000427a:	c49d                	beqz	s1,800042a8 <dirlink+0x54>
    8000427c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000427e:	4741                	li	a4,16
    80004280:	86a6                	mv	a3,s1
    80004282:	fc040613          	addi	a2,s0,-64
    80004286:	4581                	li	a1,0
    80004288:	854a                	mv	a0,s2
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	b8c080e7          	jalr	-1140(ra) # 80003e16 <readi>
    80004292:	47c1                	li	a5,16
    80004294:	06f51163          	bne	a0,a5,800042f6 <dirlink+0xa2>
    if(de.inum == 0)
    80004298:	fc045783          	lhu	a5,-64(s0)
    8000429c:	c791                	beqz	a5,800042a8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000429e:	24c1                	addiw	s1,s1,16
    800042a0:	05492783          	lw	a5,84(s2)
    800042a4:	fcf4ede3          	bltu	s1,a5,8000427e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042a8:	4639                	li	a2,14
    800042aa:	85d2                	mv	a1,s4
    800042ac:	fc240513          	addi	a0,s0,-62
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	f3c080e7          	jalr	-196(ra) # 800011ec <strncpy>
  de.inum = inum;
    800042b8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042bc:	4741                	li	a4,16
    800042be:	86a6                	mv	a3,s1
    800042c0:	fc040613          	addi	a2,s0,-64
    800042c4:	4581                	li	a1,0
    800042c6:	854a                	mv	a0,s2
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	c46080e7          	jalr	-954(ra) # 80003f0e <writei>
    800042d0:	872a                	mv	a4,a0
    800042d2:	47c1                	li	a5,16
  return 0;
    800042d4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042d6:	02f71863          	bne	a4,a5,80004306 <dirlink+0xb2>
}
    800042da:	70e2                	ld	ra,56(sp)
    800042dc:	7442                	ld	s0,48(sp)
    800042de:	74a2                	ld	s1,40(sp)
    800042e0:	7902                	ld	s2,32(sp)
    800042e2:	69e2                	ld	s3,24(sp)
    800042e4:	6a42                	ld	s4,16(sp)
    800042e6:	6121                	addi	sp,sp,64
    800042e8:	8082                	ret
    iput(ip);
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	a32080e7          	jalr	-1486(ra) # 80003d1c <iput>
    return -1;
    800042f2:	557d                	li	a0,-1
    800042f4:	b7dd                	j	800042da <dirlink+0x86>
      panic("dirlink read");
    800042f6:	00004517          	auipc	a0,0x4
    800042fa:	38250513          	addi	a0,a0,898 # 80008678 <syscalls+0x1c0>
    800042fe:	ffffc097          	auipc	ra,0xffffc
    80004302:	252080e7          	jalr	594(ra) # 80000550 <panic>
    panic("dirlink");
    80004306:	00004517          	auipc	a0,0x4
    8000430a:	49250513          	addi	a0,a0,1170 # 80008798 <syscalls+0x2e0>
    8000430e:	ffffc097          	auipc	ra,0xffffc
    80004312:	242080e7          	jalr	578(ra) # 80000550 <panic>

0000000080004316 <namei>:

struct inode*
namei(char *path)
{
    80004316:	1101                	addi	sp,sp,-32
    80004318:	ec06                	sd	ra,24(sp)
    8000431a:	e822                	sd	s0,16(sp)
    8000431c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000431e:	fe040613          	addi	a2,s0,-32
    80004322:	4581                	li	a1,0
    80004324:	00000097          	auipc	ra,0x0
    80004328:	dd0080e7          	jalr	-560(ra) # 800040f4 <namex>
}
    8000432c:	60e2                	ld	ra,24(sp)
    8000432e:	6442                	ld	s0,16(sp)
    80004330:	6105                	addi	sp,sp,32
    80004332:	8082                	ret

0000000080004334 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004334:	1141                	addi	sp,sp,-16
    80004336:	e406                	sd	ra,8(sp)
    80004338:	e022                	sd	s0,0(sp)
    8000433a:	0800                	addi	s0,sp,16
    8000433c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000433e:	4585                	li	a1,1
    80004340:	00000097          	auipc	ra,0x0
    80004344:	db4080e7          	jalr	-588(ra) # 800040f4 <namex>
}
    80004348:	60a2                	ld	ra,8(sp)
    8000434a:	6402                	ld	s0,0(sp)
    8000434c:	0141                	addi	sp,sp,16
    8000434e:	8082                	ret

0000000080004350 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004350:	1101                	addi	sp,sp,-32
    80004352:	ec06                	sd	ra,24(sp)
    80004354:	e822                	sd	s0,16(sp)
    80004356:	e426                	sd	s1,8(sp)
    80004358:	e04a                	sd	s2,0(sp)
    8000435a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000435c:	0003a917          	auipc	s2,0x3a
    80004360:	44c90913          	addi	s2,s2,1100 # 8003e7a8 <log>
    80004364:	02092583          	lw	a1,32(s2)
    80004368:	03092503          	lw	a0,48(s2)
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	e42080e7          	jalr	-446(ra) # 800031ae <bread>
    80004374:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004376:	03492683          	lw	a3,52(s2)
    8000437a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000437c:	02d05763          	blez	a3,800043aa <write_head+0x5a>
    80004380:	0003a797          	auipc	a5,0x3a
    80004384:	46078793          	addi	a5,a5,1120 # 8003e7e0 <log+0x38>
    80004388:	05c50713          	addi	a4,a0,92
    8000438c:	36fd                	addiw	a3,a3,-1
    8000438e:	1682                	slli	a3,a3,0x20
    80004390:	9281                	srli	a3,a3,0x20
    80004392:	068a                	slli	a3,a3,0x2
    80004394:	0003a617          	auipc	a2,0x3a
    80004398:	45060613          	addi	a2,a2,1104 # 8003e7e4 <log+0x3c>
    8000439c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000439e:	4390                	lw	a2,0(a5)
    800043a0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043a2:	0791                	addi	a5,a5,4
    800043a4:	0711                	addi	a4,a4,4
    800043a6:	fed79ce3          	bne	a5,a3,8000439e <write_head+0x4e>
  }
  bwrite(buf);
    800043aa:	8526                	mv	a0,s1
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	09a080e7          	jalr	154(ra) # 80003446 <bwrite>
  brelse(buf);
    800043b4:	8526                	mv	a0,s1
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	0ce080e7          	jalr	206(ra) # 80003484 <brelse>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ca:	0003a797          	auipc	a5,0x3a
    800043ce:	4127a783          	lw	a5,1042(a5) # 8003e7dc <log+0x34>
    800043d2:	0af05d63          	blez	a5,8000448c <install_trans+0xc2>
{
    800043d6:	7139                	addi	sp,sp,-64
    800043d8:	fc06                	sd	ra,56(sp)
    800043da:	f822                	sd	s0,48(sp)
    800043dc:	f426                	sd	s1,40(sp)
    800043de:	f04a                	sd	s2,32(sp)
    800043e0:	ec4e                	sd	s3,24(sp)
    800043e2:	e852                	sd	s4,16(sp)
    800043e4:	e456                	sd	s5,8(sp)
    800043e6:	e05a                	sd	s6,0(sp)
    800043e8:	0080                	addi	s0,sp,64
    800043ea:	8b2a                	mv	s6,a0
    800043ec:	0003aa97          	auipc	s5,0x3a
    800043f0:	3f4a8a93          	addi	s5,s5,1012 # 8003e7e0 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043f6:	0003a997          	auipc	s3,0x3a
    800043fa:	3b298993          	addi	s3,s3,946 # 8003e7a8 <log>
    800043fe:	a035                	j	8000442a <install_trans+0x60>
      bunpin(dbuf);
    80004400:	8526                	mv	a0,s1
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	158080e7          	jalr	344(ra) # 8000355a <bunpin>
    brelse(lbuf);
    8000440a:	854a                	mv	a0,s2
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	078080e7          	jalr	120(ra) # 80003484 <brelse>
    brelse(dbuf);
    80004414:	8526                	mv	a0,s1
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	06e080e7          	jalr	110(ra) # 80003484 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000441e:	2a05                	addiw	s4,s4,1
    80004420:	0a91                	addi	s5,s5,4
    80004422:	0349a783          	lw	a5,52(s3)
    80004426:	04fa5963          	bge	s4,a5,80004478 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000442a:	0209a583          	lw	a1,32(s3)
    8000442e:	014585bb          	addw	a1,a1,s4
    80004432:	2585                	addiw	a1,a1,1
    80004434:	0309a503          	lw	a0,48(s3)
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	d76080e7          	jalr	-650(ra) # 800031ae <bread>
    80004440:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004442:	000aa583          	lw	a1,0(s5)
    80004446:	0309a503          	lw	a0,48(s3)
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	d64080e7          	jalr	-668(ra) # 800031ae <bread>
    80004452:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004454:	40000613          	li	a2,1024
    80004458:	05890593          	addi	a1,s2,88
    8000445c:	05850513          	addi	a0,a0,88
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	cd4080e7          	jalr	-812(ra) # 80001134 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004468:	8526                	mv	a0,s1
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	fdc080e7          	jalr	-36(ra) # 80003446 <bwrite>
    if(recovering == 0)
    80004472:	f80b1ce3          	bnez	s6,8000440a <install_trans+0x40>
    80004476:	b769                	j	80004400 <install_trans+0x36>
}
    80004478:	70e2                	ld	ra,56(sp)
    8000447a:	7442                	ld	s0,48(sp)
    8000447c:	74a2                	ld	s1,40(sp)
    8000447e:	7902                	ld	s2,32(sp)
    80004480:	69e2                	ld	s3,24(sp)
    80004482:	6a42                	ld	s4,16(sp)
    80004484:	6aa2                	ld	s5,8(sp)
    80004486:	6b02                	ld	s6,0(sp)
    80004488:	6121                	addi	sp,sp,64
    8000448a:	8082                	ret
    8000448c:	8082                	ret

000000008000448e <initlog>:
{
    8000448e:	7179                	addi	sp,sp,-48
    80004490:	f406                	sd	ra,40(sp)
    80004492:	f022                	sd	s0,32(sp)
    80004494:	ec26                	sd	s1,24(sp)
    80004496:	e84a                	sd	s2,16(sp)
    80004498:	e44e                	sd	s3,8(sp)
    8000449a:	1800                	addi	s0,sp,48
    8000449c:	892a                	mv	s2,a0
    8000449e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044a0:	0003a497          	auipc	s1,0x3a
    800044a4:	30848493          	addi	s1,s1,776 # 8003e7a8 <log>
    800044a8:	00004597          	auipc	a1,0x4
    800044ac:	1e058593          	addi	a1,a1,480 # 80008688 <syscalls+0x1d0>
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	9be080e7          	jalr	-1602(ra) # 80000e70 <initlock>
  log.start = sb->logstart;
    800044ba:	0149a583          	lw	a1,20(s3)
    800044be:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800044c0:	0109a783          	lw	a5,16(s3)
    800044c4:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800044c6:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044ca:	854a                	mv	a0,s2
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	ce2080e7          	jalr	-798(ra) # 800031ae <bread>
  log.lh.n = lh->n;
    800044d4:	4d3c                	lw	a5,88(a0)
    800044d6:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044d8:	02f05563          	blez	a5,80004502 <initlog+0x74>
    800044dc:	05c50713          	addi	a4,a0,92
    800044e0:	0003a697          	auipc	a3,0x3a
    800044e4:	30068693          	addi	a3,a3,768 # 8003e7e0 <log+0x38>
    800044e8:	37fd                	addiw	a5,a5,-1
    800044ea:	1782                	slli	a5,a5,0x20
    800044ec:	9381                	srli	a5,a5,0x20
    800044ee:	078a                	slli	a5,a5,0x2
    800044f0:	06050613          	addi	a2,a0,96
    800044f4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044f6:	4310                	lw	a2,0(a4)
    800044f8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800044fa:	0711                	addi	a4,a4,4
    800044fc:	0691                	addi	a3,a3,4
    800044fe:	fef71ce3          	bne	a4,a5,800044f6 <initlog+0x68>
  brelse(buf);
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	f82080e7          	jalr	-126(ra) # 80003484 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000450a:	4505                	li	a0,1
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	ebe080e7          	jalr	-322(ra) # 800043ca <install_trans>
  log.lh.n = 0;
    80004514:	0003a797          	auipc	a5,0x3a
    80004518:	2c07a423          	sw	zero,712(a5) # 8003e7dc <log+0x34>
  write_head(); // clear the log
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	e34080e7          	jalr	-460(ra) # 80004350 <write_head>
}
    80004524:	70a2                	ld	ra,40(sp)
    80004526:	7402                	ld	s0,32(sp)
    80004528:	64e2                	ld	s1,24(sp)
    8000452a:	6942                	ld	s2,16(sp)
    8000452c:	69a2                	ld	s3,8(sp)
    8000452e:	6145                	addi	sp,sp,48
    80004530:	8082                	ret

0000000080004532 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000453e:	0003a517          	auipc	a0,0x3a
    80004542:	26a50513          	addi	a0,a0,618 # 8003e7a8 <log>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	7ae080e7          	jalr	1966(ra) # 80000cf4 <acquire>
  while(1){
    if(log.committing){
    8000454e:	0003a497          	auipc	s1,0x3a
    80004552:	25a48493          	addi	s1,s1,602 # 8003e7a8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004556:	4979                	li	s2,30
    80004558:	a039                	j	80004566 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000455a:	85a6                	mv	a1,s1
    8000455c:	8526                	mv	a0,s1
    8000455e:	ffffe097          	auipc	ra,0xffffe
    80004562:	fee080e7          	jalr	-18(ra) # 8000254c <sleep>
    if(log.committing){
    80004566:	54dc                	lw	a5,44(s1)
    80004568:	fbed                	bnez	a5,8000455a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000456a:	549c                	lw	a5,40(s1)
    8000456c:	0017871b          	addiw	a4,a5,1
    80004570:	0007069b          	sext.w	a3,a4
    80004574:	0027179b          	slliw	a5,a4,0x2
    80004578:	9fb9                	addw	a5,a5,a4
    8000457a:	0017979b          	slliw	a5,a5,0x1
    8000457e:	58d8                	lw	a4,52(s1)
    80004580:	9fb9                	addw	a5,a5,a4
    80004582:	00f95963          	bge	s2,a5,80004594 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004586:	85a6                	mv	a1,s1
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffe097          	auipc	ra,0xffffe
    8000458e:	fc2080e7          	jalr	-62(ra) # 8000254c <sleep>
    80004592:	bfd1                	j	80004566 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004594:	0003a517          	auipc	a0,0x3a
    80004598:	21450513          	addi	a0,a0,532 # 8003e7a8 <log>
    8000459c:	d514                	sw	a3,40(a0)
      release(&log.lock);
    8000459e:	ffffd097          	auipc	ra,0xffffd
    800045a2:	826080e7          	jalr	-2010(ra) # 80000dc4 <release>
      break;
    }
  }
}
    800045a6:	60e2                	ld	ra,24(sp)
    800045a8:	6442                	ld	s0,16(sp)
    800045aa:	64a2                	ld	s1,8(sp)
    800045ac:	6902                	ld	s2,0(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret

00000000800045b2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045b2:	7139                	addi	sp,sp,-64
    800045b4:	fc06                	sd	ra,56(sp)
    800045b6:	f822                	sd	s0,48(sp)
    800045b8:	f426                	sd	s1,40(sp)
    800045ba:	f04a                	sd	s2,32(sp)
    800045bc:	ec4e                	sd	s3,24(sp)
    800045be:	e852                	sd	s4,16(sp)
    800045c0:	e456                	sd	s5,8(sp)
    800045c2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045c4:	0003a497          	auipc	s1,0x3a
    800045c8:	1e448493          	addi	s1,s1,484 # 8003e7a8 <log>
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	726080e7          	jalr	1830(ra) # 80000cf4 <acquire>
  log.outstanding -= 1;
    800045d6:	549c                	lw	a5,40(s1)
    800045d8:	37fd                	addiw	a5,a5,-1
    800045da:	0007891b          	sext.w	s2,a5
    800045de:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800045e0:	54dc                	lw	a5,44(s1)
    800045e2:	efb9                	bnez	a5,80004640 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045e4:	06091663          	bnez	s2,80004650 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045e8:	0003a497          	auipc	s1,0x3a
    800045ec:	1c048493          	addi	s1,s1,448 # 8003e7a8 <log>
    800045f0:	4785                	li	a5,1
    800045f2:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045f4:	8526                	mv	a0,s1
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	7ce080e7          	jalr	1998(ra) # 80000dc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045fe:	58dc                	lw	a5,52(s1)
    80004600:	06f04763          	bgtz	a5,8000466e <end_op+0xbc>
    acquire(&log.lock);
    80004604:	0003a497          	auipc	s1,0x3a
    80004608:	1a448493          	addi	s1,s1,420 # 8003e7a8 <log>
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	6e6080e7          	jalr	1766(ra) # 80000cf4 <acquire>
    log.committing = 0;
    80004616:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffe097          	auipc	ra,0xffffe
    80004620:	0b6080e7          	jalr	182(ra) # 800026d2 <wakeup>
    release(&log.lock);
    80004624:	8526                	mv	a0,s1
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	79e080e7          	jalr	1950(ra) # 80000dc4 <release>
}
    8000462e:	70e2                	ld	ra,56(sp)
    80004630:	7442                	ld	s0,48(sp)
    80004632:	74a2                	ld	s1,40(sp)
    80004634:	7902                	ld	s2,32(sp)
    80004636:	69e2                	ld	s3,24(sp)
    80004638:	6a42                	ld	s4,16(sp)
    8000463a:	6aa2                	ld	s5,8(sp)
    8000463c:	6121                	addi	sp,sp,64
    8000463e:	8082                	ret
    panic("log.committing");
    80004640:	00004517          	auipc	a0,0x4
    80004644:	05050513          	addi	a0,a0,80 # 80008690 <syscalls+0x1d8>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	f08080e7          	jalr	-248(ra) # 80000550 <panic>
    wakeup(&log);
    80004650:	0003a497          	auipc	s1,0x3a
    80004654:	15848493          	addi	s1,s1,344 # 8003e7a8 <log>
    80004658:	8526                	mv	a0,s1
    8000465a:	ffffe097          	auipc	ra,0xffffe
    8000465e:	078080e7          	jalr	120(ra) # 800026d2 <wakeup>
  release(&log.lock);
    80004662:	8526                	mv	a0,s1
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	760080e7          	jalr	1888(ra) # 80000dc4 <release>
  if(do_commit){
    8000466c:	b7c9                	j	8000462e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000466e:	0003aa97          	auipc	s5,0x3a
    80004672:	172a8a93          	addi	s5,s5,370 # 8003e7e0 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004676:	0003aa17          	auipc	s4,0x3a
    8000467a:	132a0a13          	addi	s4,s4,306 # 8003e7a8 <log>
    8000467e:	020a2583          	lw	a1,32(s4)
    80004682:	012585bb          	addw	a1,a1,s2
    80004686:	2585                	addiw	a1,a1,1
    80004688:	030a2503          	lw	a0,48(s4)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	b22080e7          	jalr	-1246(ra) # 800031ae <bread>
    80004694:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004696:	000aa583          	lw	a1,0(s5)
    8000469a:	030a2503          	lw	a0,48(s4)
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	b10080e7          	jalr	-1264(ra) # 800031ae <bread>
    800046a6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046a8:	40000613          	li	a2,1024
    800046ac:	05850593          	addi	a1,a0,88
    800046b0:	05848513          	addi	a0,s1,88
    800046b4:	ffffd097          	auipc	ra,0xffffd
    800046b8:	a80080e7          	jalr	-1408(ra) # 80001134 <memmove>
    bwrite(to);  // write the log
    800046bc:	8526                	mv	a0,s1
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	d88080e7          	jalr	-632(ra) # 80003446 <bwrite>
    brelse(from);
    800046c6:	854e                	mv	a0,s3
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	dbc080e7          	jalr	-580(ra) # 80003484 <brelse>
    brelse(to);
    800046d0:	8526                	mv	a0,s1
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	db2080e7          	jalr	-590(ra) # 80003484 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046da:	2905                	addiw	s2,s2,1
    800046dc:	0a91                	addi	s5,s5,4
    800046de:	034a2783          	lw	a5,52(s4)
    800046e2:	f8f94ee3          	blt	s2,a5,8000467e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	c6a080e7          	jalr	-918(ra) # 80004350 <write_head>
    install_trans(0); // Now install writes to home locations
    800046ee:	4501                	li	a0,0
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	cda080e7          	jalr	-806(ra) # 800043ca <install_trans>
    log.lh.n = 0;
    800046f8:	0003a797          	auipc	a5,0x3a
    800046fc:	0e07a223          	sw	zero,228(a5) # 8003e7dc <log+0x34>
    write_head();    // Erase the transaction from the log
    80004700:	00000097          	auipc	ra,0x0
    80004704:	c50080e7          	jalr	-944(ra) # 80004350 <write_head>
    80004708:	bdf5                	j	80004604 <end_op+0x52>

000000008000470a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000470a:	1101                	addi	sp,sp,-32
    8000470c:	ec06                	sd	ra,24(sp)
    8000470e:	e822                	sd	s0,16(sp)
    80004710:	e426                	sd	s1,8(sp)
    80004712:	e04a                	sd	s2,0(sp)
    80004714:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004716:	0003a717          	auipc	a4,0x3a
    8000471a:	0c672703          	lw	a4,198(a4) # 8003e7dc <log+0x34>
    8000471e:	47f5                	li	a5,29
    80004720:	08e7c063          	blt	a5,a4,800047a0 <log_write+0x96>
    80004724:	84aa                	mv	s1,a0
    80004726:	0003a797          	auipc	a5,0x3a
    8000472a:	0a67a783          	lw	a5,166(a5) # 8003e7cc <log+0x24>
    8000472e:	37fd                	addiw	a5,a5,-1
    80004730:	06f75863          	bge	a4,a5,800047a0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004734:	0003a797          	auipc	a5,0x3a
    80004738:	09c7a783          	lw	a5,156(a5) # 8003e7d0 <log+0x28>
    8000473c:	06f05a63          	blez	a5,800047b0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004740:	0003a917          	auipc	s2,0x3a
    80004744:	06890913          	addi	s2,s2,104 # 8003e7a8 <log>
    80004748:	854a                	mv	a0,s2
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	5aa080e7          	jalr	1450(ra) # 80000cf4 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004752:	03492603          	lw	a2,52(s2)
    80004756:	06c05563          	blez	a2,800047c0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000475a:	44cc                	lw	a1,12(s1)
    8000475c:	0003a717          	auipc	a4,0x3a
    80004760:	08470713          	addi	a4,a4,132 # 8003e7e0 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004764:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004766:	4314                	lw	a3,0(a4)
    80004768:	04b68d63          	beq	a3,a1,800047c2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000476c:	2785                	addiw	a5,a5,1
    8000476e:	0711                	addi	a4,a4,4
    80004770:	fec79be3          	bne	a5,a2,80004766 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004774:	0631                	addi	a2,a2,12
    80004776:	060a                	slli	a2,a2,0x2
    80004778:	0003a797          	auipc	a5,0x3a
    8000477c:	03078793          	addi	a5,a5,48 # 8003e7a8 <log>
    80004780:	963e                	add	a2,a2,a5
    80004782:	44dc                	lw	a5,12(s1)
    80004784:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004786:	8526                	mv	a0,s1
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	d86080e7          	jalr	-634(ra) # 8000350e <bpin>
    log.lh.n++;
    80004790:	0003a717          	auipc	a4,0x3a
    80004794:	01870713          	addi	a4,a4,24 # 8003e7a8 <log>
    80004798:	5b5c                	lw	a5,52(a4)
    8000479a:	2785                	addiw	a5,a5,1
    8000479c:	db5c                	sw	a5,52(a4)
    8000479e:	a83d                	j	800047dc <log_write+0xd2>
    panic("too big a transaction");
    800047a0:	00004517          	auipc	a0,0x4
    800047a4:	f0050513          	addi	a0,a0,-256 # 800086a0 <syscalls+0x1e8>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	da8080e7          	jalr	-600(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    800047b0:	00004517          	auipc	a0,0x4
    800047b4:	f0850513          	addi	a0,a0,-248 # 800086b8 <syscalls+0x200>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	d98080e7          	jalr	-616(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800047c0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800047c2:	00c78713          	addi	a4,a5,12
    800047c6:	00271693          	slli	a3,a4,0x2
    800047ca:	0003a717          	auipc	a4,0x3a
    800047ce:	fde70713          	addi	a4,a4,-34 # 8003e7a8 <log>
    800047d2:	9736                	add	a4,a4,a3
    800047d4:	44d4                	lw	a3,12(s1)
    800047d6:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047d8:	faf607e3          	beq	a2,a5,80004786 <log_write+0x7c>
  }
  release(&log.lock);
    800047dc:	0003a517          	auipc	a0,0x3a
    800047e0:	fcc50513          	addi	a0,a0,-52 # 8003e7a8 <log>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	5e0080e7          	jalr	1504(ra) # 80000dc4 <release>
}
    800047ec:	60e2                	ld	ra,24(sp)
    800047ee:	6442                	ld	s0,16(sp)
    800047f0:	64a2                	ld	s1,8(sp)
    800047f2:	6902                	ld	s2,0(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret

00000000800047f8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047f8:	1101                	addi	sp,sp,-32
    800047fa:	ec06                	sd	ra,24(sp)
    800047fc:	e822                	sd	s0,16(sp)
    800047fe:	e426                	sd	s1,8(sp)
    80004800:	e04a                	sd	s2,0(sp)
    80004802:	1000                	addi	s0,sp,32
    80004804:	84aa                	mv	s1,a0
    80004806:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004808:	00004597          	auipc	a1,0x4
    8000480c:	ed058593          	addi	a1,a1,-304 # 800086d8 <syscalls+0x220>
    80004810:	0521                	addi	a0,a0,8
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	65e080e7          	jalr	1630(ra) # 80000e70 <initlock>
  lk->name = name;
    8000481a:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    8000481e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004822:	0204a823          	sw	zero,48(s1)
}
    80004826:	60e2                	ld	ra,24(sp)
    80004828:	6442                	ld	s0,16(sp)
    8000482a:	64a2                	ld	s1,8(sp)
    8000482c:	6902                	ld	s2,0(sp)
    8000482e:	6105                	addi	sp,sp,32
    80004830:	8082                	ret

0000000080004832 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004832:	1101                	addi	sp,sp,-32
    80004834:	ec06                	sd	ra,24(sp)
    80004836:	e822                	sd	s0,16(sp)
    80004838:	e426                	sd	s1,8(sp)
    8000483a:	e04a                	sd	s2,0(sp)
    8000483c:	1000                	addi	s0,sp,32
    8000483e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004840:	00850913          	addi	s2,a0,8
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	4ae080e7          	jalr	1198(ra) # 80000cf4 <acquire>
  while (lk->locked) {
    8000484e:	409c                	lw	a5,0(s1)
    80004850:	cb89                	beqz	a5,80004862 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004852:	85ca                	mv	a1,s2
    80004854:	8526                	mv	a0,s1
    80004856:	ffffe097          	auipc	ra,0xffffe
    8000485a:	cf6080e7          	jalr	-778(ra) # 8000254c <sleep>
  while (lk->locked) {
    8000485e:	409c                	lw	a5,0(s1)
    80004860:	fbed                	bnez	a5,80004852 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004862:	4785                	li	a5,1
    80004864:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004866:	ffffd097          	auipc	ra,0xffffd
    8000486a:	4d6080e7          	jalr	1238(ra) # 80001d3c <myproc>
    8000486e:	413c                	lw	a5,64(a0)
    80004870:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004872:	854a                	mv	a0,s2
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	550080e7          	jalr	1360(ra) # 80000dc4 <release>
}
    8000487c:	60e2                	ld	ra,24(sp)
    8000487e:	6442                	ld	s0,16(sp)
    80004880:	64a2                	ld	s1,8(sp)
    80004882:	6902                	ld	s2,0(sp)
    80004884:	6105                	addi	sp,sp,32
    80004886:	8082                	ret

0000000080004888 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004888:	1101                	addi	sp,sp,-32
    8000488a:	ec06                	sd	ra,24(sp)
    8000488c:	e822                	sd	s0,16(sp)
    8000488e:	e426                	sd	s1,8(sp)
    80004890:	e04a                	sd	s2,0(sp)
    80004892:	1000                	addi	s0,sp,32
    80004894:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004896:	00850913          	addi	s2,a0,8
    8000489a:	854a                	mv	a0,s2
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	458080e7          	jalr	1112(ra) # 80000cf4 <acquire>
  lk->locked = 0;
    800048a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048a8:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffe097          	auipc	ra,0xffffe
    800048b2:	e24080e7          	jalr	-476(ra) # 800026d2 <wakeup>
  release(&lk->lk);
    800048b6:	854a                	mv	a0,s2
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	50c080e7          	jalr	1292(ra) # 80000dc4 <release>
}
    800048c0:	60e2                	ld	ra,24(sp)
    800048c2:	6442                	ld	s0,16(sp)
    800048c4:	64a2                	ld	s1,8(sp)
    800048c6:	6902                	ld	s2,0(sp)
    800048c8:	6105                	addi	sp,sp,32
    800048ca:	8082                	ret

00000000800048cc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048cc:	7179                	addi	sp,sp,-48
    800048ce:	f406                	sd	ra,40(sp)
    800048d0:	f022                	sd	s0,32(sp)
    800048d2:	ec26                	sd	s1,24(sp)
    800048d4:	e84a                	sd	s2,16(sp)
    800048d6:	e44e                	sd	s3,8(sp)
    800048d8:	1800                	addi	s0,sp,48
    800048da:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048dc:	00850913          	addi	s2,a0,8
    800048e0:	854a                	mv	a0,s2
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	412080e7          	jalr	1042(ra) # 80000cf4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	ef99                	bnez	a5,8000490a <holdingsleep+0x3e>
    800048ee:	4481                	li	s1,0
  release(&lk->lk);
    800048f0:	854a                	mv	a0,s2
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	4d2080e7          	jalr	1234(ra) # 80000dc4 <release>
  return r;
}
    800048fa:	8526                	mv	a0,s1
    800048fc:	70a2                	ld	ra,40(sp)
    800048fe:	7402                	ld	s0,32(sp)
    80004900:	64e2                	ld	s1,24(sp)
    80004902:	6942                	ld	s2,16(sp)
    80004904:	69a2                	ld	s3,8(sp)
    80004906:	6145                	addi	sp,sp,48
    80004908:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000490a:	0304a983          	lw	s3,48(s1)
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	42e080e7          	jalr	1070(ra) # 80001d3c <myproc>
    80004916:	4124                	lw	s1,64(a0)
    80004918:	413484b3          	sub	s1,s1,s3
    8000491c:	0014b493          	seqz	s1,s1
    80004920:	bfc1                	j	800048f0 <holdingsleep+0x24>

0000000080004922 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004922:	1141                	addi	sp,sp,-16
    80004924:	e406                	sd	ra,8(sp)
    80004926:	e022                	sd	s0,0(sp)
    80004928:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000492a:	00004597          	auipc	a1,0x4
    8000492e:	dbe58593          	addi	a1,a1,-578 # 800086e8 <syscalls+0x230>
    80004932:	0003a517          	auipc	a0,0x3a
    80004936:	fc650513          	addi	a0,a0,-58 # 8003e8f8 <ftable>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	536080e7          	jalr	1334(ra) # 80000e70 <initlock>
}
    80004942:	60a2                	ld	ra,8(sp)
    80004944:	6402                	ld	s0,0(sp)
    80004946:	0141                	addi	sp,sp,16
    80004948:	8082                	ret

000000008000494a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000494a:	1101                	addi	sp,sp,-32
    8000494c:	ec06                	sd	ra,24(sp)
    8000494e:	e822                	sd	s0,16(sp)
    80004950:	e426                	sd	s1,8(sp)
    80004952:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004954:	0003a517          	auipc	a0,0x3a
    80004958:	fa450513          	addi	a0,a0,-92 # 8003e8f8 <ftable>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	398080e7          	jalr	920(ra) # 80000cf4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004964:	0003a497          	auipc	s1,0x3a
    80004968:	fb448493          	addi	s1,s1,-76 # 8003e918 <ftable+0x20>
    8000496c:	0003b717          	auipc	a4,0x3b
    80004970:	f4c70713          	addi	a4,a4,-180 # 8003f8b8 <ftable+0xfc0>
    if(f->ref == 0){
    80004974:	40dc                	lw	a5,4(s1)
    80004976:	cf99                	beqz	a5,80004994 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004978:	02848493          	addi	s1,s1,40
    8000497c:	fee49ce3          	bne	s1,a4,80004974 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004980:	0003a517          	auipc	a0,0x3a
    80004984:	f7850513          	addi	a0,a0,-136 # 8003e8f8 <ftable>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	43c080e7          	jalr	1084(ra) # 80000dc4 <release>
  return 0;
    80004990:	4481                	li	s1,0
    80004992:	a819                	j	800049a8 <filealloc+0x5e>
      f->ref = 1;
    80004994:	4785                	li	a5,1
    80004996:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004998:	0003a517          	auipc	a0,0x3a
    8000499c:	f6050513          	addi	a0,a0,-160 # 8003e8f8 <ftable>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	424080e7          	jalr	1060(ra) # 80000dc4 <release>
}
    800049a8:	8526                	mv	a0,s1
    800049aa:	60e2                	ld	ra,24(sp)
    800049ac:	6442                	ld	s0,16(sp)
    800049ae:	64a2                	ld	s1,8(sp)
    800049b0:	6105                	addi	sp,sp,32
    800049b2:	8082                	ret

00000000800049b4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049b4:	1101                	addi	sp,sp,-32
    800049b6:	ec06                	sd	ra,24(sp)
    800049b8:	e822                	sd	s0,16(sp)
    800049ba:	e426                	sd	s1,8(sp)
    800049bc:	1000                	addi	s0,sp,32
    800049be:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049c0:	0003a517          	auipc	a0,0x3a
    800049c4:	f3850513          	addi	a0,a0,-200 # 8003e8f8 <ftable>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	32c080e7          	jalr	812(ra) # 80000cf4 <acquire>
  if(f->ref < 1)
    800049d0:	40dc                	lw	a5,4(s1)
    800049d2:	02f05263          	blez	a5,800049f6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049d6:	2785                	addiw	a5,a5,1
    800049d8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049da:	0003a517          	auipc	a0,0x3a
    800049de:	f1e50513          	addi	a0,a0,-226 # 8003e8f8 <ftable>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	3e2080e7          	jalr	994(ra) # 80000dc4 <release>
  return f;
}
    800049ea:	8526                	mv	a0,s1
    800049ec:	60e2                	ld	ra,24(sp)
    800049ee:	6442                	ld	s0,16(sp)
    800049f0:	64a2                	ld	s1,8(sp)
    800049f2:	6105                	addi	sp,sp,32
    800049f4:	8082                	ret
    panic("filedup");
    800049f6:	00004517          	auipc	a0,0x4
    800049fa:	cfa50513          	addi	a0,a0,-774 # 800086f0 <syscalls+0x238>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	b52080e7          	jalr	-1198(ra) # 80000550 <panic>

0000000080004a06 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a06:	7139                	addi	sp,sp,-64
    80004a08:	fc06                	sd	ra,56(sp)
    80004a0a:	f822                	sd	s0,48(sp)
    80004a0c:	f426                	sd	s1,40(sp)
    80004a0e:	f04a                	sd	s2,32(sp)
    80004a10:	ec4e                	sd	s3,24(sp)
    80004a12:	e852                	sd	s4,16(sp)
    80004a14:	e456                	sd	s5,8(sp)
    80004a16:	0080                	addi	s0,sp,64
    80004a18:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a1a:	0003a517          	auipc	a0,0x3a
    80004a1e:	ede50513          	addi	a0,a0,-290 # 8003e8f8 <ftable>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	2d2080e7          	jalr	722(ra) # 80000cf4 <acquire>
  if(f->ref < 1)
    80004a2a:	40dc                	lw	a5,4(s1)
    80004a2c:	06f05163          	blez	a5,80004a8e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a30:	37fd                	addiw	a5,a5,-1
    80004a32:	0007871b          	sext.w	a4,a5
    80004a36:	c0dc                	sw	a5,4(s1)
    80004a38:	06e04363          	bgtz	a4,80004a9e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a3c:	0004a903          	lw	s2,0(s1)
    80004a40:	0094ca83          	lbu	s5,9(s1)
    80004a44:	0104ba03          	ld	s4,16(s1)
    80004a48:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a4c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a50:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a54:	0003a517          	auipc	a0,0x3a
    80004a58:	ea450513          	addi	a0,a0,-348 # 8003e8f8 <ftable>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	368080e7          	jalr	872(ra) # 80000dc4 <release>

  if(ff.type == FD_PIPE){
    80004a64:	4785                	li	a5,1
    80004a66:	04f90d63          	beq	s2,a5,80004ac0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a6a:	3979                	addiw	s2,s2,-2
    80004a6c:	4785                	li	a5,1
    80004a6e:	0527e063          	bltu	a5,s2,80004aae <fileclose+0xa8>
    begin_op();
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	ac0080e7          	jalr	-1344(ra) # 80004532 <begin_op>
    iput(ff.ip);
    80004a7a:	854e                	mv	a0,s3
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	2a0080e7          	jalr	672(ra) # 80003d1c <iput>
    end_op();
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	b2e080e7          	jalr	-1234(ra) # 800045b2 <end_op>
    80004a8c:	a00d                	j	80004aae <fileclose+0xa8>
    panic("fileclose");
    80004a8e:	00004517          	auipc	a0,0x4
    80004a92:	c6a50513          	addi	a0,a0,-918 # 800086f8 <syscalls+0x240>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	aba080e7          	jalr	-1350(ra) # 80000550 <panic>
    release(&ftable.lock);
    80004a9e:	0003a517          	auipc	a0,0x3a
    80004aa2:	e5a50513          	addi	a0,a0,-422 # 8003e8f8 <ftable>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	31e080e7          	jalr	798(ra) # 80000dc4 <release>
  }
}
    80004aae:	70e2                	ld	ra,56(sp)
    80004ab0:	7442                	ld	s0,48(sp)
    80004ab2:	74a2                	ld	s1,40(sp)
    80004ab4:	7902                	ld	s2,32(sp)
    80004ab6:	69e2                	ld	s3,24(sp)
    80004ab8:	6a42                	ld	s4,16(sp)
    80004aba:	6aa2                	ld	s5,8(sp)
    80004abc:	6121                	addi	sp,sp,64
    80004abe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ac0:	85d6                	mv	a1,s5
    80004ac2:	8552                	mv	a0,s4
    80004ac4:	00000097          	auipc	ra,0x0
    80004ac8:	372080e7          	jalr	882(ra) # 80004e36 <pipeclose>
    80004acc:	b7cd                	j	80004aae <fileclose+0xa8>

0000000080004ace <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ace:	715d                	addi	sp,sp,-80
    80004ad0:	e486                	sd	ra,72(sp)
    80004ad2:	e0a2                	sd	s0,64(sp)
    80004ad4:	fc26                	sd	s1,56(sp)
    80004ad6:	f84a                	sd	s2,48(sp)
    80004ad8:	f44e                	sd	s3,40(sp)
    80004ada:	0880                	addi	s0,sp,80
    80004adc:	84aa                	mv	s1,a0
    80004ade:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ae0:	ffffd097          	auipc	ra,0xffffd
    80004ae4:	25c080e7          	jalr	604(ra) # 80001d3c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ae8:	409c                	lw	a5,0(s1)
    80004aea:	37f9                	addiw	a5,a5,-2
    80004aec:	4705                	li	a4,1
    80004aee:	04f76763          	bltu	a4,a5,80004b3c <filestat+0x6e>
    80004af2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004af4:	6c88                	ld	a0,24(s1)
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	06c080e7          	jalr	108(ra) # 80003b62 <ilock>
    stati(f->ip, &st);
    80004afe:	fb840593          	addi	a1,s0,-72
    80004b02:	6c88                	ld	a0,24(s1)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	2e8080e7          	jalr	744(ra) # 80003dec <stati>
    iunlock(f->ip);
    80004b0c:	6c88                	ld	a0,24(s1)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	116080e7          	jalr	278(ra) # 80003c24 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b16:	46e1                	li	a3,24
    80004b18:	fb840613          	addi	a2,s0,-72
    80004b1c:	85ce                	mv	a1,s3
    80004b1e:	05893503          	ld	a0,88(s2)
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	f0e080e7          	jalr	-242(ra) # 80001a30 <copyout>
    80004b2a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b2e:	60a6                	ld	ra,72(sp)
    80004b30:	6406                	ld	s0,64(sp)
    80004b32:	74e2                	ld	s1,56(sp)
    80004b34:	7942                	ld	s2,48(sp)
    80004b36:	79a2                	ld	s3,40(sp)
    80004b38:	6161                	addi	sp,sp,80
    80004b3a:	8082                	ret
  return -1;
    80004b3c:	557d                	li	a0,-1
    80004b3e:	bfc5                	j	80004b2e <filestat+0x60>

0000000080004b40 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b40:	7179                	addi	sp,sp,-48
    80004b42:	f406                	sd	ra,40(sp)
    80004b44:	f022                	sd	s0,32(sp)
    80004b46:	ec26                	sd	s1,24(sp)
    80004b48:	e84a                	sd	s2,16(sp)
    80004b4a:	e44e                	sd	s3,8(sp)
    80004b4c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b4e:	00854783          	lbu	a5,8(a0)
    80004b52:	c3d5                	beqz	a5,80004bf6 <fileread+0xb6>
    80004b54:	84aa                	mv	s1,a0
    80004b56:	89ae                	mv	s3,a1
    80004b58:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b5a:	411c                	lw	a5,0(a0)
    80004b5c:	4705                	li	a4,1
    80004b5e:	04e78963          	beq	a5,a4,80004bb0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b62:	470d                	li	a4,3
    80004b64:	04e78d63          	beq	a5,a4,80004bbe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b68:	4709                	li	a4,2
    80004b6a:	06e79e63          	bne	a5,a4,80004be6 <fileread+0xa6>
    ilock(f->ip);
    80004b6e:	6d08                	ld	a0,24(a0)
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	ff2080e7          	jalr	-14(ra) # 80003b62 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b78:	874a                	mv	a4,s2
    80004b7a:	5094                	lw	a3,32(s1)
    80004b7c:	864e                	mv	a2,s3
    80004b7e:	4585                	li	a1,1
    80004b80:	6c88                	ld	a0,24(s1)
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	294080e7          	jalr	660(ra) # 80003e16 <readi>
    80004b8a:	892a                	mv	s2,a0
    80004b8c:	00a05563          	blez	a0,80004b96 <fileread+0x56>
      f->off += r;
    80004b90:	509c                	lw	a5,32(s1)
    80004b92:	9fa9                	addw	a5,a5,a0
    80004b94:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b96:	6c88                	ld	a0,24(s1)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	08c080e7          	jalr	140(ra) # 80003c24 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ba0:	854a                	mv	a0,s2
    80004ba2:	70a2                	ld	ra,40(sp)
    80004ba4:	7402                	ld	s0,32(sp)
    80004ba6:	64e2                	ld	s1,24(sp)
    80004ba8:	6942                	ld	s2,16(sp)
    80004baa:	69a2                	ld	s3,8(sp)
    80004bac:	6145                	addi	sp,sp,48
    80004bae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bb0:	6908                	ld	a0,16(a0)
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	422080e7          	jalr	1058(ra) # 80004fd4 <piperead>
    80004bba:	892a                	mv	s2,a0
    80004bbc:	b7d5                	j	80004ba0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bbe:	02451783          	lh	a5,36(a0)
    80004bc2:	03079693          	slli	a3,a5,0x30
    80004bc6:	92c1                	srli	a3,a3,0x30
    80004bc8:	4725                	li	a4,9
    80004bca:	02d76863          	bltu	a4,a3,80004bfa <fileread+0xba>
    80004bce:	0792                	slli	a5,a5,0x4
    80004bd0:	0003a717          	auipc	a4,0x3a
    80004bd4:	c8870713          	addi	a4,a4,-888 # 8003e858 <devsw>
    80004bd8:	97ba                	add	a5,a5,a4
    80004bda:	639c                	ld	a5,0(a5)
    80004bdc:	c38d                	beqz	a5,80004bfe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bde:	4505                	li	a0,1
    80004be0:	9782                	jalr	a5
    80004be2:	892a                	mv	s2,a0
    80004be4:	bf75                	j	80004ba0 <fileread+0x60>
    panic("fileread");
    80004be6:	00004517          	auipc	a0,0x4
    80004bea:	b2250513          	addi	a0,a0,-1246 # 80008708 <syscalls+0x250>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	962080e7          	jalr	-1694(ra) # 80000550 <panic>
    return -1;
    80004bf6:	597d                	li	s2,-1
    80004bf8:	b765                	j	80004ba0 <fileread+0x60>
      return -1;
    80004bfa:	597d                	li	s2,-1
    80004bfc:	b755                	j	80004ba0 <fileread+0x60>
    80004bfe:	597d                	li	s2,-1
    80004c00:	b745                	j	80004ba0 <fileread+0x60>

0000000080004c02 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c02:	00954783          	lbu	a5,9(a0)
    80004c06:	14078563          	beqz	a5,80004d50 <filewrite+0x14e>
{
    80004c0a:	715d                	addi	sp,sp,-80
    80004c0c:	e486                	sd	ra,72(sp)
    80004c0e:	e0a2                	sd	s0,64(sp)
    80004c10:	fc26                	sd	s1,56(sp)
    80004c12:	f84a                	sd	s2,48(sp)
    80004c14:	f44e                	sd	s3,40(sp)
    80004c16:	f052                	sd	s4,32(sp)
    80004c18:	ec56                	sd	s5,24(sp)
    80004c1a:	e85a                	sd	s6,16(sp)
    80004c1c:	e45e                	sd	s7,8(sp)
    80004c1e:	e062                	sd	s8,0(sp)
    80004c20:	0880                	addi	s0,sp,80
    80004c22:	892a                	mv	s2,a0
    80004c24:	8aae                	mv	s5,a1
    80004c26:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c28:	411c                	lw	a5,0(a0)
    80004c2a:	4705                	li	a4,1
    80004c2c:	02e78263          	beq	a5,a4,80004c50 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c30:	470d                	li	a4,3
    80004c32:	02e78563          	beq	a5,a4,80004c5c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c36:	4709                	li	a4,2
    80004c38:	10e79463          	bne	a5,a4,80004d40 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c3c:	0ec05e63          	blez	a2,80004d38 <filewrite+0x136>
    int i = 0;
    80004c40:	4981                	li	s3,0
    80004c42:	6b05                	lui	s6,0x1
    80004c44:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c48:	6b85                	lui	s7,0x1
    80004c4a:	c00b8b9b          	addiw	s7,s7,-1024
    80004c4e:	a851                	j	80004ce2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c50:	6908                	ld	a0,16(a0)
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	25e080e7          	jalr	606(ra) # 80004eb0 <pipewrite>
    80004c5a:	a85d                	j	80004d10 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c5c:	02451783          	lh	a5,36(a0)
    80004c60:	03079693          	slli	a3,a5,0x30
    80004c64:	92c1                	srli	a3,a3,0x30
    80004c66:	4725                	li	a4,9
    80004c68:	0ed76663          	bltu	a4,a3,80004d54 <filewrite+0x152>
    80004c6c:	0792                	slli	a5,a5,0x4
    80004c6e:	0003a717          	auipc	a4,0x3a
    80004c72:	bea70713          	addi	a4,a4,-1046 # 8003e858 <devsw>
    80004c76:	97ba                	add	a5,a5,a4
    80004c78:	679c                	ld	a5,8(a5)
    80004c7a:	cff9                	beqz	a5,80004d58 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004c7c:	4505                	li	a0,1
    80004c7e:	9782                	jalr	a5
    80004c80:	a841                	j	80004d10 <filewrite+0x10e>
    80004c82:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c86:	00000097          	auipc	ra,0x0
    80004c8a:	8ac080e7          	jalr	-1876(ra) # 80004532 <begin_op>
      ilock(f->ip);
    80004c8e:	01893503          	ld	a0,24(s2)
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	ed0080e7          	jalr	-304(ra) # 80003b62 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c9a:	8762                	mv	a4,s8
    80004c9c:	02092683          	lw	a3,32(s2)
    80004ca0:	01598633          	add	a2,s3,s5
    80004ca4:	4585                	li	a1,1
    80004ca6:	01893503          	ld	a0,24(s2)
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	264080e7          	jalr	612(ra) # 80003f0e <writei>
    80004cb2:	84aa                	mv	s1,a0
    80004cb4:	02a05f63          	blez	a0,80004cf2 <filewrite+0xf0>
        f->off += r;
    80004cb8:	02092783          	lw	a5,32(s2)
    80004cbc:	9fa9                	addw	a5,a5,a0
    80004cbe:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cc2:	01893503          	ld	a0,24(s2)
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	f5e080e7          	jalr	-162(ra) # 80003c24 <iunlock>
      end_op();
    80004cce:	00000097          	auipc	ra,0x0
    80004cd2:	8e4080e7          	jalr	-1820(ra) # 800045b2 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004cd6:	049c1963          	bne	s8,s1,80004d28 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004cda:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cde:	0349d663          	bge	s3,s4,80004d0a <filewrite+0x108>
      int n1 = n - i;
    80004ce2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ce6:	84be                	mv	s1,a5
    80004ce8:	2781                	sext.w	a5,a5
    80004cea:	f8fb5ce3          	bge	s6,a5,80004c82 <filewrite+0x80>
    80004cee:	84de                	mv	s1,s7
    80004cf0:	bf49                	j	80004c82 <filewrite+0x80>
      iunlock(f->ip);
    80004cf2:	01893503          	ld	a0,24(s2)
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	f2e080e7          	jalr	-210(ra) # 80003c24 <iunlock>
      end_op();
    80004cfe:	00000097          	auipc	ra,0x0
    80004d02:	8b4080e7          	jalr	-1868(ra) # 800045b2 <end_op>
      if(r < 0)
    80004d06:	fc04d8e3          	bgez	s1,80004cd6 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004d0a:	8552                	mv	a0,s4
    80004d0c:	033a1863          	bne	s4,s3,80004d3c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d10:	60a6                	ld	ra,72(sp)
    80004d12:	6406                	ld	s0,64(sp)
    80004d14:	74e2                	ld	s1,56(sp)
    80004d16:	7942                	ld	s2,48(sp)
    80004d18:	79a2                	ld	s3,40(sp)
    80004d1a:	7a02                	ld	s4,32(sp)
    80004d1c:	6ae2                	ld	s5,24(sp)
    80004d1e:	6b42                	ld	s6,16(sp)
    80004d20:	6ba2                	ld	s7,8(sp)
    80004d22:	6c02                	ld	s8,0(sp)
    80004d24:	6161                	addi	sp,sp,80
    80004d26:	8082                	ret
        panic("short filewrite");
    80004d28:	00004517          	auipc	a0,0x4
    80004d2c:	9f050513          	addi	a0,a0,-1552 # 80008718 <syscalls+0x260>
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	820080e7          	jalr	-2016(ra) # 80000550 <panic>
    int i = 0;
    80004d38:	4981                	li	s3,0
    80004d3a:	bfc1                	j	80004d0a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004d3c:	557d                	li	a0,-1
    80004d3e:	bfc9                	j	80004d10 <filewrite+0x10e>
    panic("filewrite");
    80004d40:	00004517          	auipc	a0,0x4
    80004d44:	9e850513          	addi	a0,a0,-1560 # 80008728 <syscalls+0x270>
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	808080e7          	jalr	-2040(ra) # 80000550 <panic>
    return -1;
    80004d50:	557d                	li	a0,-1
}
    80004d52:	8082                	ret
      return -1;
    80004d54:	557d                	li	a0,-1
    80004d56:	bf6d                	j	80004d10 <filewrite+0x10e>
    80004d58:	557d                	li	a0,-1
    80004d5a:	bf5d                	j	80004d10 <filewrite+0x10e>

0000000080004d5c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d5c:	7179                	addi	sp,sp,-48
    80004d5e:	f406                	sd	ra,40(sp)
    80004d60:	f022                	sd	s0,32(sp)
    80004d62:	ec26                	sd	s1,24(sp)
    80004d64:	e84a                	sd	s2,16(sp)
    80004d66:	e44e                	sd	s3,8(sp)
    80004d68:	e052                	sd	s4,0(sp)
    80004d6a:	1800                	addi	s0,sp,48
    80004d6c:	84aa                	mv	s1,a0
    80004d6e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d70:	0005b023          	sd	zero,0(a1)
    80004d74:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d78:	00000097          	auipc	ra,0x0
    80004d7c:	bd2080e7          	jalr	-1070(ra) # 8000494a <filealloc>
    80004d80:	e088                	sd	a0,0(s1)
    80004d82:	c551                	beqz	a0,80004e0e <pipealloc+0xb2>
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	bc6080e7          	jalr	-1082(ra) # 8000494a <filealloc>
    80004d8c:	00aa3023          	sd	a0,0(s4)
    80004d90:	c92d                	beqz	a0,80004e02 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	de6080e7          	jalr	-538(ra) # 80000b78 <kalloc>
    80004d9a:	892a                	mv	s2,a0
    80004d9c:	c125                	beqz	a0,80004dfc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d9e:	4985                	li	s3,1
    80004da0:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004da4:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004da8:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004dac:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004db0:	00004597          	auipc	a1,0x4
    80004db4:	98858593          	addi	a1,a1,-1656 # 80008738 <syscalls+0x280>
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	0b8080e7          	jalr	184(ra) # 80000e70 <initlock>
  (*f0)->type = FD_PIPE;
    80004dc0:	609c                	ld	a5,0(s1)
    80004dc2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dc6:	609c                	ld	a5,0(s1)
    80004dc8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dcc:	609c                	ld	a5,0(s1)
    80004dce:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dd2:	609c                	ld	a5,0(s1)
    80004dd4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dd8:	000a3783          	ld	a5,0(s4)
    80004ddc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004de0:	000a3783          	ld	a5,0(s4)
    80004de4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004de8:	000a3783          	ld	a5,0(s4)
    80004dec:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004df0:	000a3783          	ld	a5,0(s4)
    80004df4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004df8:	4501                	li	a0,0
    80004dfa:	a025                	j	80004e22 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dfc:	6088                	ld	a0,0(s1)
    80004dfe:	e501                	bnez	a0,80004e06 <pipealloc+0xaa>
    80004e00:	a039                	j	80004e0e <pipealloc+0xb2>
    80004e02:	6088                	ld	a0,0(s1)
    80004e04:	c51d                	beqz	a0,80004e32 <pipealloc+0xd6>
    fileclose(*f0);
    80004e06:	00000097          	auipc	ra,0x0
    80004e0a:	c00080e7          	jalr	-1024(ra) # 80004a06 <fileclose>
  if(*f1)
    80004e0e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e12:	557d                	li	a0,-1
  if(*f1)
    80004e14:	c799                	beqz	a5,80004e22 <pipealloc+0xc6>
    fileclose(*f1);
    80004e16:	853e                	mv	a0,a5
    80004e18:	00000097          	auipc	ra,0x0
    80004e1c:	bee080e7          	jalr	-1042(ra) # 80004a06 <fileclose>
  return -1;
    80004e20:	557d                	li	a0,-1
}
    80004e22:	70a2                	ld	ra,40(sp)
    80004e24:	7402                	ld	s0,32(sp)
    80004e26:	64e2                	ld	s1,24(sp)
    80004e28:	6942                	ld	s2,16(sp)
    80004e2a:	69a2                	ld	s3,8(sp)
    80004e2c:	6a02                	ld	s4,0(sp)
    80004e2e:	6145                	addi	sp,sp,48
    80004e30:	8082                	ret
  return -1;
    80004e32:	557d                	li	a0,-1
    80004e34:	b7fd                	j	80004e22 <pipealloc+0xc6>

0000000080004e36 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e36:	1101                	addi	sp,sp,-32
    80004e38:	ec06                	sd	ra,24(sp)
    80004e3a:	e822                	sd	s0,16(sp)
    80004e3c:	e426                	sd	s1,8(sp)
    80004e3e:	e04a                	sd	s2,0(sp)
    80004e40:	1000                	addi	s0,sp,32
    80004e42:	84aa                	mv	s1,a0
    80004e44:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	eae080e7          	jalr	-338(ra) # 80000cf4 <acquire>
  if(writable){
    80004e4e:	04090263          	beqz	s2,80004e92 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004e52:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004e56:	22048513          	addi	a0,s1,544
    80004e5a:	ffffe097          	auipc	ra,0xffffe
    80004e5e:	878080e7          	jalr	-1928(ra) # 800026d2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e62:	2284b783          	ld	a5,552(s1)
    80004e66:	ef9d                	bnez	a5,80004ea4 <pipeclose+0x6e>
    release(&pi->lock);
    80004e68:	8526                	mv	a0,s1
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	f5a080e7          	jalr	-166(ra) # 80000dc4 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004e72:	8526                	mv	a0,s1
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	f98080e7          	jalr	-104(ra) # 80000e0c <freelock>
#endif    
    kfree((char*)pi);
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	bae080e7          	jalr	-1106(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004e86:	60e2                	ld	ra,24(sp)
    80004e88:	6442                	ld	s0,16(sp)
    80004e8a:	64a2                	ld	s1,8(sp)
    80004e8c:	6902                	ld	s2,0(sp)
    80004e8e:	6105                	addi	sp,sp,32
    80004e90:	8082                	ret
    pi->readopen = 0;
    80004e92:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004e96:	22448513          	addi	a0,s1,548
    80004e9a:	ffffe097          	auipc	ra,0xffffe
    80004e9e:	838080e7          	jalr	-1992(ra) # 800026d2 <wakeup>
    80004ea2:	b7c1                	j	80004e62 <pipeclose+0x2c>
    release(&pi->lock);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	f1e080e7          	jalr	-226(ra) # 80000dc4 <release>
}
    80004eae:	bfe1                	j	80004e86 <pipeclose+0x50>

0000000080004eb0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eb0:	7119                	addi	sp,sp,-128
    80004eb2:	fc86                	sd	ra,120(sp)
    80004eb4:	f8a2                	sd	s0,112(sp)
    80004eb6:	f4a6                	sd	s1,104(sp)
    80004eb8:	f0ca                	sd	s2,96(sp)
    80004eba:	ecce                	sd	s3,88(sp)
    80004ebc:	e8d2                	sd	s4,80(sp)
    80004ebe:	e4d6                	sd	s5,72(sp)
    80004ec0:	e0da                	sd	s6,64(sp)
    80004ec2:	fc5e                	sd	s7,56(sp)
    80004ec4:	f862                	sd	s8,48(sp)
    80004ec6:	f466                	sd	s9,40(sp)
    80004ec8:	f06a                	sd	s10,32(sp)
    80004eca:	ec6e                	sd	s11,24(sp)
    80004ecc:	0100                	addi	s0,sp,128
    80004ece:	84aa                	mv	s1,a0
    80004ed0:	8cae                	mv	s9,a1
    80004ed2:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	e68080e7          	jalr	-408(ra) # 80001d3c <myproc>
    80004edc:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	e14080e7          	jalr	-492(ra) # 80000cf4 <acquire>
  for(i = 0; i < n; i++){
    80004ee8:	0d605963          	blez	s6,80004fba <pipewrite+0x10a>
    80004eec:	89a6                	mv	s3,s1
    80004eee:	3b7d                	addiw	s6,s6,-1
    80004ef0:	1b02                	slli	s6,s6,0x20
    80004ef2:	020b5b13          	srli	s6,s6,0x20
    80004ef6:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ef8:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004efc:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f00:	5dfd                	li	s11,-1
    80004f02:	000b8d1b          	sext.w	s10,s7
    80004f06:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f08:	2204a783          	lw	a5,544(s1)
    80004f0c:	2244a703          	lw	a4,548(s1)
    80004f10:	2007879b          	addiw	a5,a5,512
    80004f14:	02f71b63          	bne	a4,a5,80004f4a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004f18:	2284a783          	lw	a5,552(s1)
    80004f1c:	cbad                	beqz	a5,80004f8e <pipewrite+0xde>
    80004f1e:	03892783          	lw	a5,56(s2)
    80004f22:	e7b5                	bnez	a5,80004f8e <pipewrite+0xde>
      wakeup(&pi->nread);
    80004f24:	8556                	mv	a0,s5
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	7ac080e7          	jalr	1964(ra) # 800026d2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f2e:	85ce                	mv	a1,s3
    80004f30:	8552                	mv	a0,s4
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	61a080e7          	jalr	1562(ra) # 8000254c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f3a:	2204a783          	lw	a5,544(s1)
    80004f3e:	2244a703          	lw	a4,548(s1)
    80004f42:	2007879b          	addiw	a5,a5,512
    80004f46:	fcf709e3          	beq	a4,a5,80004f18 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f4a:	4685                	li	a3,1
    80004f4c:	019b8633          	add	a2,s7,s9
    80004f50:	f8f40593          	addi	a1,s0,-113
    80004f54:	05893503          	ld	a0,88(s2)
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	b64080e7          	jalr	-1180(ra) # 80001abc <copyin>
    80004f60:	05b50e63          	beq	a0,s11,80004fbc <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f64:	2244a783          	lw	a5,548(s1)
    80004f68:	0017871b          	addiw	a4,a5,1
    80004f6c:	22e4a223          	sw	a4,548(s1)
    80004f70:	1ff7f793          	andi	a5,a5,511
    80004f74:	97a6                	add	a5,a5,s1
    80004f76:	f8f44703          	lbu	a4,-113(s0)
    80004f7a:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004f7e:	001d0c1b          	addiw	s8,s10,1
    80004f82:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004f86:	036b8b63          	beq	s7,s6,80004fbc <pipewrite+0x10c>
    80004f8a:	8bbe                	mv	s7,a5
    80004f8c:	bf9d                	j	80004f02 <pipewrite+0x52>
        release(&pi->lock);
    80004f8e:	8526                	mv	a0,s1
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	e34080e7          	jalr	-460(ra) # 80000dc4 <release>
        return -1;
    80004f98:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004f9a:	8562                	mv	a0,s8
    80004f9c:	70e6                	ld	ra,120(sp)
    80004f9e:	7446                	ld	s0,112(sp)
    80004fa0:	74a6                	ld	s1,104(sp)
    80004fa2:	7906                	ld	s2,96(sp)
    80004fa4:	69e6                	ld	s3,88(sp)
    80004fa6:	6a46                	ld	s4,80(sp)
    80004fa8:	6aa6                	ld	s5,72(sp)
    80004faa:	6b06                	ld	s6,64(sp)
    80004fac:	7be2                	ld	s7,56(sp)
    80004fae:	7c42                	ld	s8,48(sp)
    80004fb0:	7ca2                	ld	s9,40(sp)
    80004fb2:	7d02                	ld	s10,32(sp)
    80004fb4:	6de2                	ld	s11,24(sp)
    80004fb6:	6109                	addi	sp,sp,128
    80004fb8:	8082                	ret
  for(i = 0; i < n; i++){
    80004fba:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004fbc:	22048513          	addi	a0,s1,544
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	712080e7          	jalr	1810(ra) # 800026d2 <wakeup>
  release(&pi->lock);
    80004fc8:	8526                	mv	a0,s1
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	dfa080e7          	jalr	-518(ra) # 80000dc4 <release>
  return i;
    80004fd2:	b7e1                	j	80004f9a <pipewrite+0xea>

0000000080004fd4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fd4:	715d                	addi	sp,sp,-80
    80004fd6:	e486                	sd	ra,72(sp)
    80004fd8:	e0a2                	sd	s0,64(sp)
    80004fda:	fc26                	sd	s1,56(sp)
    80004fdc:	f84a                	sd	s2,48(sp)
    80004fde:	f44e                	sd	s3,40(sp)
    80004fe0:	f052                	sd	s4,32(sp)
    80004fe2:	ec56                	sd	s5,24(sp)
    80004fe4:	e85a                	sd	s6,16(sp)
    80004fe6:	0880                	addi	s0,sp,80
    80004fe8:	84aa                	mv	s1,a0
    80004fea:	892e                	mv	s2,a1
    80004fec:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	d4e080e7          	jalr	-690(ra) # 80001d3c <myproc>
    80004ff6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ff8:	8b26                	mv	s6,s1
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	cf8080e7          	jalr	-776(ra) # 80000cf4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005004:	2204a703          	lw	a4,544(s1)
    80005008:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000500c:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005010:	02f71463          	bne	a4,a5,80005038 <piperead+0x64>
    80005014:	22c4a783          	lw	a5,556(s1)
    80005018:	c385                	beqz	a5,80005038 <piperead+0x64>
    if(pr->killed){
    8000501a:	038a2783          	lw	a5,56(s4)
    8000501e:	ebc1                	bnez	a5,800050ae <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005020:	85da                	mv	a1,s6
    80005022:	854e                	mv	a0,s3
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	528080e7          	jalr	1320(ra) # 8000254c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000502c:	2204a703          	lw	a4,544(s1)
    80005030:	2244a783          	lw	a5,548(s1)
    80005034:	fef700e3          	beq	a4,a5,80005014 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005038:	09505263          	blez	s5,800050bc <piperead+0xe8>
    8000503c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005040:	2204a783          	lw	a5,544(s1)
    80005044:	2244a703          	lw	a4,548(s1)
    80005048:	02f70d63          	beq	a4,a5,80005082 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000504c:	0017871b          	addiw	a4,a5,1
    80005050:	22e4a023          	sw	a4,544(s1)
    80005054:	1ff7f793          	andi	a5,a5,511
    80005058:	97a6                	add	a5,a5,s1
    8000505a:	0207c783          	lbu	a5,32(a5)
    8000505e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005062:	4685                	li	a3,1
    80005064:	fbf40613          	addi	a2,s0,-65
    80005068:	85ca                	mv	a1,s2
    8000506a:	058a3503          	ld	a0,88(s4)
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	9c2080e7          	jalr	-1598(ra) # 80001a30 <copyout>
    80005076:	01650663          	beq	a0,s6,80005082 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507a:	2985                	addiw	s3,s3,1
    8000507c:	0905                	addi	s2,s2,1
    8000507e:	fd3a91e3          	bne	s5,s3,80005040 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005082:	22448513          	addi	a0,s1,548
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	64c080e7          	jalr	1612(ra) # 800026d2 <wakeup>
  release(&pi->lock);
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	d34080e7          	jalr	-716(ra) # 80000dc4 <release>
  return i;
}
    80005098:	854e                	mv	a0,s3
    8000509a:	60a6                	ld	ra,72(sp)
    8000509c:	6406                	ld	s0,64(sp)
    8000509e:	74e2                	ld	s1,56(sp)
    800050a0:	7942                	ld	s2,48(sp)
    800050a2:	79a2                	ld	s3,40(sp)
    800050a4:	7a02                	ld	s4,32(sp)
    800050a6:	6ae2                	ld	s5,24(sp)
    800050a8:	6b42                	ld	s6,16(sp)
    800050aa:	6161                	addi	sp,sp,80
    800050ac:	8082                	ret
      release(&pi->lock);
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	d14080e7          	jalr	-748(ra) # 80000dc4 <release>
      return -1;
    800050b8:	59fd                	li	s3,-1
    800050ba:	bff9                	j	80005098 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050bc:	4981                	li	s3,0
    800050be:	b7d1                	j	80005082 <piperead+0xae>

00000000800050c0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050c0:	df010113          	addi	sp,sp,-528
    800050c4:	20113423          	sd	ra,520(sp)
    800050c8:	20813023          	sd	s0,512(sp)
    800050cc:	ffa6                	sd	s1,504(sp)
    800050ce:	fbca                	sd	s2,496(sp)
    800050d0:	f7ce                	sd	s3,488(sp)
    800050d2:	f3d2                	sd	s4,480(sp)
    800050d4:	efd6                	sd	s5,472(sp)
    800050d6:	ebda                	sd	s6,464(sp)
    800050d8:	e7de                	sd	s7,456(sp)
    800050da:	e3e2                	sd	s8,448(sp)
    800050dc:	ff66                	sd	s9,440(sp)
    800050de:	fb6a                	sd	s10,432(sp)
    800050e0:	f76e                	sd	s11,424(sp)
    800050e2:	0c00                	addi	s0,sp,528
    800050e4:	84aa                	mv	s1,a0
    800050e6:	dea43c23          	sd	a0,-520(s0)
    800050ea:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050ee:	ffffd097          	auipc	ra,0xffffd
    800050f2:	c4e080e7          	jalr	-946(ra) # 80001d3c <myproc>
    800050f6:	892a                	mv	s2,a0

  begin_op();
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	43a080e7          	jalr	1082(ra) # 80004532 <begin_op>

  if((ip = namei(path)) == 0){
    80005100:	8526                	mv	a0,s1
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	214080e7          	jalr	532(ra) # 80004316 <namei>
    8000510a:	c92d                	beqz	a0,8000517c <exec+0xbc>
    8000510c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	a54080e7          	jalr	-1452(ra) # 80003b62 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005116:	04000713          	li	a4,64
    8000511a:	4681                	li	a3,0
    8000511c:	e4840613          	addi	a2,s0,-440
    80005120:	4581                	li	a1,0
    80005122:	8526                	mv	a0,s1
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	cf2080e7          	jalr	-782(ra) # 80003e16 <readi>
    8000512c:	04000793          	li	a5,64
    80005130:	00f51a63          	bne	a0,a5,80005144 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005134:	e4842703          	lw	a4,-440(s0)
    80005138:	464c47b7          	lui	a5,0x464c4
    8000513c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005140:	04f70463          	beq	a4,a5,80005188 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005144:	8526                	mv	a0,s1
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	c7e080e7          	jalr	-898(ra) # 80003dc4 <iunlockput>
    end_op();
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	464080e7          	jalr	1124(ra) # 800045b2 <end_op>
  }
  return -1;
    80005156:	557d                	li	a0,-1
}
    80005158:	20813083          	ld	ra,520(sp)
    8000515c:	20013403          	ld	s0,512(sp)
    80005160:	74fe                	ld	s1,504(sp)
    80005162:	795e                	ld	s2,496(sp)
    80005164:	79be                	ld	s3,488(sp)
    80005166:	7a1e                	ld	s4,480(sp)
    80005168:	6afe                	ld	s5,472(sp)
    8000516a:	6b5e                	ld	s6,464(sp)
    8000516c:	6bbe                	ld	s7,456(sp)
    8000516e:	6c1e                	ld	s8,448(sp)
    80005170:	7cfa                	ld	s9,440(sp)
    80005172:	7d5a                	ld	s10,432(sp)
    80005174:	7dba                	ld	s11,424(sp)
    80005176:	21010113          	addi	sp,sp,528
    8000517a:	8082                	ret
    end_op();
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	436080e7          	jalr	1078(ra) # 800045b2 <end_op>
    return -1;
    80005184:	557d                	li	a0,-1
    80005186:	bfc9                	j	80005158 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005188:	854a                	mv	a0,s2
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	c76080e7          	jalr	-906(ra) # 80001e00 <proc_pagetable>
    80005192:	8baa                	mv	s7,a0
    80005194:	d945                	beqz	a0,80005144 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005196:	e6842983          	lw	s3,-408(s0)
    8000519a:	e8045783          	lhu	a5,-384(s0)
    8000519e:	c7ad                	beqz	a5,80005208 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051a0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051a2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800051a4:	6c85                	lui	s9,0x1
    800051a6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051aa:	def43823          	sd	a5,-528(s0)
    800051ae:	a42d                	j	800053d8 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051b0:	00003517          	auipc	a0,0x3
    800051b4:	59050513          	addi	a0,a0,1424 # 80008740 <syscalls+0x288>
    800051b8:	ffffb097          	auipc	ra,0xffffb
    800051bc:	398080e7          	jalr	920(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051c0:	8756                	mv	a4,s5
    800051c2:	012d86bb          	addw	a3,s11,s2
    800051c6:	4581                	li	a1,0
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	c4c080e7          	jalr	-948(ra) # 80003e16 <readi>
    800051d2:	2501                	sext.w	a0,a0
    800051d4:	1aaa9963          	bne	s5,a0,80005386 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051d8:	6785                	lui	a5,0x1
    800051da:	0127893b          	addw	s2,a5,s2
    800051de:	77fd                	lui	a5,0xfffff
    800051e0:	01478a3b          	addw	s4,a5,s4
    800051e4:	1f897163          	bgeu	s2,s8,800053c6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051e8:	02091593          	slli	a1,s2,0x20
    800051ec:	9181                	srli	a1,a1,0x20
    800051ee:	95ea                	add	a1,a1,s10
    800051f0:	855e                	mv	a0,s7
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	27c080e7          	jalr	636(ra) # 8000146e <walkaddr>
    800051fa:	862a                	mv	a2,a0
    if(pa == 0)
    800051fc:	d955                	beqz	a0,800051b0 <exec+0xf0>
      n = PGSIZE;
    800051fe:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005200:	fd9a70e3          	bgeu	s4,s9,800051c0 <exec+0x100>
      n = sz - i;
    80005204:	8ad2                	mv	s5,s4
    80005206:	bf6d                	j	800051c0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005208:	4901                	li	s2,0
  iunlockput(ip);
    8000520a:	8526                	mv	a0,s1
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	bb8080e7          	jalr	-1096(ra) # 80003dc4 <iunlockput>
  end_op();
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	39e080e7          	jalr	926(ra) # 800045b2 <end_op>
  p = myproc();
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	b20080e7          	jalr	-1248(ra) # 80001d3c <myproc>
    80005224:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005226:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000522a:	6785                	lui	a5,0x1
    8000522c:	17fd                	addi	a5,a5,-1
    8000522e:	993e                	add	s2,s2,a5
    80005230:	757d                	lui	a0,0xfffff
    80005232:	00a977b3          	and	a5,s2,a0
    80005236:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000523a:	6609                	lui	a2,0x2
    8000523c:	963e                	add	a2,a2,a5
    8000523e:	85be                	mv	a1,a5
    80005240:	855e                	mv	a0,s7
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	59e080e7          	jalr	1438(ra) # 800017e0 <uvmalloc>
    8000524a:	8b2a                	mv	s6,a0
  ip = 0;
    8000524c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000524e:	12050c63          	beqz	a0,80005386 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005252:	75f9                	lui	a1,0xffffe
    80005254:	95aa                	add	a1,a1,a0
    80005256:	855e                	mv	a0,s7
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	7a6080e7          	jalr	1958(ra) # 800019fe <uvmclear>
  stackbase = sp - PGSIZE;
    80005260:	7c7d                	lui	s8,0xfffff
    80005262:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005264:	e0043783          	ld	a5,-512(s0)
    80005268:	6388                	ld	a0,0(a5)
    8000526a:	c535                	beqz	a0,800052d6 <exec+0x216>
    8000526c:	e8840993          	addi	s3,s0,-376
    80005270:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005274:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	fe6080e7          	jalr	-26(ra) # 8000125c <strlen>
    8000527e:	2505                	addiw	a0,a0,1
    80005280:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005284:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005288:	13896363          	bltu	s2,s8,800053ae <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000528c:	e0043d83          	ld	s11,-512(s0)
    80005290:	000dba03          	ld	s4,0(s11)
    80005294:	8552                	mv	a0,s4
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	fc6080e7          	jalr	-58(ra) # 8000125c <strlen>
    8000529e:	0015069b          	addiw	a3,a0,1
    800052a2:	8652                	mv	a2,s4
    800052a4:	85ca                	mv	a1,s2
    800052a6:	855e                	mv	a0,s7
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	788080e7          	jalr	1928(ra) # 80001a30 <copyout>
    800052b0:	10054363          	bltz	a0,800053b6 <exec+0x2f6>
    ustack[argc] = sp;
    800052b4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052b8:	0485                	addi	s1,s1,1
    800052ba:	008d8793          	addi	a5,s11,8
    800052be:	e0f43023          	sd	a5,-512(s0)
    800052c2:	008db503          	ld	a0,8(s11)
    800052c6:	c911                	beqz	a0,800052da <exec+0x21a>
    if(argc >= MAXARG)
    800052c8:	09a1                	addi	s3,s3,8
    800052ca:	fb3c96e3          	bne	s9,s3,80005276 <exec+0x1b6>
  sz = sz1;
    800052ce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052d2:	4481                	li	s1,0
    800052d4:	a84d                	j	80005386 <exec+0x2c6>
  sp = sz;
    800052d6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052d8:	4481                	li	s1,0
  ustack[argc] = 0;
    800052da:	00349793          	slli	a5,s1,0x3
    800052de:	f9040713          	addi	a4,s0,-112
    800052e2:	97ba                	add	a5,a5,a4
    800052e4:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800052e8:	00148693          	addi	a3,s1,1
    800052ec:	068e                	slli	a3,a3,0x3
    800052ee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052f2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052f6:	01897663          	bgeu	s2,s8,80005302 <exec+0x242>
  sz = sz1;
    800052fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052fe:	4481                	li	s1,0
    80005300:	a059                	j	80005386 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005302:	e8840613          	addi	a2,s0,-376
    80005306:	85ca                	mv	a1,s2
    80005308:	855e                	mv	a0,s7
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	726080e7          	jalr	1830(ra) # 80001a30 <copyout>
    80005312:	0a054663          	bltz	a0,800053be <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005316:	060ab783          	ld	a5,96(s5)
    8000531a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000531e:	df843783          	ld	a5,-520(s0)
    80005322:	0007c703          	lbu	a4,0(a5)
    80005326:	cf11                	beqz	a4,80005342 <exec+0x282>
    80005328:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000532a:	02f00693          	li	a3,47
    8000532e:	a029                	j	80005338 <exec+0x278>
  for(last=s=path; *s; s++)
    80005330:	0785                	addi	a5,a5,1
    80005332:	fff7c703          	lbu	a4,-1(a5)
    80005336:	c711                	beqz	a4,80005342 <exec+0x282>
    if(*s == '/')
    80005338:	fed71ce3          	bne	a4,a3,80005330 <exec+0x270>
      last = s+1;
    8000533c:	def43c23          	sd	a5,-520(s0)
    80005340:	bfc5                	j	80005330 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005342:	4641                	li	a2,16
    80005344:	df843583          	ld	a1,-520(s0)
    80005348:	160a8513          	addi	a0,s5,352
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	ede080e7          	jalr	-290(ra) # 8000122a <safestrcpy>
  oldpagetable = p->pagetable;
    80005354:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005358:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    8000535c:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005360:	060ab783          	ld	a5,96(s5)
    80005364:	e6043703          	ld	a4,-416(s0)
    80005368:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000536a:	060ab783          	ld	a5,96(s5)
    8000536e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005372:	85ea                	mv	a1,s10
    80005374:	ffffd097          	auipc	ra,0xffffd
    80005378:	b28080e7          	jalr	-1240(ra) # 80001e9c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000537c:	0004851b          	sext.w	a0,s1
    80005380:	bbe1                	j	80005158 <exec+0x98>
    80005382:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005386:	e0843583          	ld	a1,-504(s0)
    8000538a:	855e                	mv	a0,s7
    8000538c:	ffffd097          	auipc	ra,0xffffd
    80005390:	b10080e7          	jalr	-1264(ra) # 80001e9c <proc_freepagetable>
  if(ip){
    80005394:	da0498e3          	bnez	s1,80005144 <exec+0x84>
  return -1;
    80005398:	557d                	li	a0,-1
    8000539a:	bb7d                	j	80005158 <exec+0x98>
    8000539c:	e1243423          	sd	s2,-504(s0)
    800053a0:	b7dd                	j	80005386 <exec+0x2c6>
    800053a2:	e1243423          	sd	s2,-504(s0)
    800053a6:	b7c5                	j	80005386 <exec+0x2c6>
    800053a8:	e1243423          	sd	s2,-504(s0)
    800053ac:	bfe9                	j	80005386 <exec+0x2c6>
  sz = sz1;
    800053ae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053b2:	4481                	li	s1,0
    800053b4:	bfc9                	j	80005386 <exec+0x2c6>
  sz = sz1;
    800053b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ba:	4481                	li	s1,0
    800053bc:	b7e9                	j	80005386 <exec+0x2c6>
  sz = sz1;
    800053be:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c2:	4481                	li	s1,0
    800053c4:	b7c9                	j	80005386 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053c6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ca:	2b05                	addiw	s6,s6,1
    800053cc:	0389899b          	addiw	s3,s3,56
    800053d0:	e8045783          	lhu	a5,-384(s0)
    800053d4:	e2fb5be3          	bge	s6,a5,8000520a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053d8:	2981                	sext.w	s3,s3
    800053da:	03800713          	li	a4,56
    800053de:	86ce                	mv	a3,s3
    800053e0:	e1040613          	addi	a2,s0,-496
    800053e4:	4581                	li	a1,0
    800053e6:	8526                	mv	a0,s1
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	a2e080e7          	jalr	-1490(ra) # 80003e16 <readi>
    800053f0:	03800793          	li	a5,56
    800053f4:	f8f517e3          	bne	a0,a5,80005382 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053f8:	e1042783          	lw	a5,-496(s0)
    800053fc:	4705                	li	a4,1
    800053fe:	fce796e3          	bne	a5,a4,800053ca <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005402:	e3843603          	ld	a2,-456(s0)
    80005406:	e3043783          	ld	a5,-464(s0)
    8000540a:	f8f669e3          	bltu	a2,a5,8000539c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000540e:	e2043783          	ld	a5,-480(s0)
    80005412:	963e                	add	a2,a2,a5
    80005414:	f8f667e3          	bltu	a2,a5,800053a2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005418:	85ca                	mv	a1,s2
    8000541a:	855e                	mv	a0,s7
    8000541c:	ffffc097          	auipc	ra,0xffffc
    80005420:	3c4080e7          	jalr	964(ra) # 800017e0 <uvmalloc>
    80005424:	e0a43423          	sd	a0,-504(s0)
    80005428:	d141                	beqz	a0,800053a8 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000542a:	e2043d03          	ld	s10,-480(s0)
    8000542e:	df043783          	ld	a5,-528(s0)
    80005432:	00fd77b3          	and	a5,s10,a5
    80005436:	fba1                	bnez	a5,80005386 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005438:	e1842d83          	lw	s11,-488(s0)
    8000543c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005440:	f80c03e3          	beqz	s8,800053c6 <exec+0x306>
    80005444:	8a62                	mv	s4,s8
    80005446:	4901                	li	s2,0
    80005448:	b345                	j	800051e8 <exec+0x128>

000000008000544a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000544a:	7179                	addi	sp,sp,-48
    8000544c:	f406                	sd	ra,40(sp)
    8000544e:	f022                	sd	s0,32(sp)
    80005450:	ec26                	sd	s1,24(sp)
    80005452:	e84a                	sd	s2,16(sp)
    80005454:	1800                	addi	s0,sp,48
    80005456:	892e                	mv	s2,a1
    80005458:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000545a:	fdc40593          	addi	a1,s0,-36
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	99c080e7          	jalr	-1636(ra) # 80002dfa <argint>
    80005466:	04054063          	bltz	a0,800054a6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000546a:	fdc42703          	lw	a4,-36(s0)
    8000546e:	47bd                	li	a5,15
    80005470:	02e7ed63          	bltu	a5,a4,800054aa <argfd+0x60>
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	8c8080e7          	jalr	-1848(ra) # 80001d3c <myproc>
    8000547c:	fdc42703          	lw	a4,-36(s0)
    80005480:	01a70793          	addi	a5,a4,26
    80005484:	078e                	slli	a5,a5,0x3
    80005486:	953e                	add	a0,a0,a5
    80005488:	651c                	ld	a5,8(a0)
    8000548a:	c395                	beqz	a5,800054ae <argfd+0x64>
    return -1;
  if(pfd)
    8000548c:	00090463          	beqz	s2,80005494 <argfd+0x4a>
    *pfd = fd;
    80005490:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005494:	4501                	li	a0,0
  if(pf)
    80005496:	c091                	beqz	s1,8000549a <argfd+0x50>
    *pf = f;
    80005498:	e09c                	sd	a5,0(s1)
}
    8000549a:	70a2                	ld	ra,40(sp)
    8000549c:	7402                	ld	s0,32(sp)
    8000549e:	64e2                	ld	s1,24(sp)
    800054a0:	6942                	ld	s2,16(sp)
    800054a2:	6145                	addi	sp,sp,48
    800054a4:	8082                	ret
    return -1;
    800054a6:	557d                	li	a0,-1
    800054a8:	bfcd                	j	8000549a <argfd+0x50>
    return -1;
    800054aa:	557d                	li	a0,-1
    800054ac:	b7fd                	j	8000549a <argfd+0x50>
    800054ae:	557d                	li	a0,-1
    800054b0:	b7ed                	j	8000549a <argfd+0x50>

00000000800054b2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054b2:	1101                	addi	sp,sp,-32
    800054b4:	ec06                	sd	ra,24(sp)
    800054b6:	e822                	sd	s0,16(sp)
    800054b8:	e426                	sd	s1,8(sp)
    800054ba:	1000                	addi	s0,sp,32
    800054bc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054be:	ffffd097          	auipc	ra,0xffffd
    800054c2:	87e080e7          	jalr	-1922(ra) # 80001d3c <myproc>
    800054c6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054c8:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffbb0b0>
    800054cc:	4501                	li	a0,0
    800054ce:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054d0:	6398                	ld	a4,0(a5)
    800054d2:	cb19                	beqz	a4,800054e8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054d4:	2505                	addiw	a0,a0,1
    800054d6:	07a1                	addi	a5,a5,8
    800054d8:	fed51ce3          	bne	a0,a3,800054d0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054dc:	557d                	li	a0,-1
}
    800054de:	60e2                	ld	ra,24(sp)
    800054e0:	6442                	ld	s0,16(sp)
    800054e2:	64a2                	ld	s1,8(sp)
    800054e4:	6105                	addi	sp,sp,32
    800054e6:	8082                	ret
      p->ofile[fd] = f;
    800054e8:	01a50793          	addi	a5,a0,26
    800054ec:	078e                	slli	a5,a5,0x3
    800054ee:	963e                	add	a2,a2,a5
    800054f0:	e604                	sd	s1,8(a2)
      return fd;
    800054f2:	b7f5                	j	800054de <fdalloc+0x2c>

00000000800054f4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054f4:	715d                	addi	sp,sp,-80
    800054f6:	e486                	sd	ra,72(sp)
    800054f8:	e0a2                	sd	s0,64(sp)
    800054fa:	fc26                	sd	s1,56(sp)
    800054fc:	f84a                	sd	s2,48(sp)
    800054fe:	f44e                	sd	s3,40(sp)
    80005500:	f052                	sd	s4,32(sp)
    80005502:	ec56                	sd	s5,24(sp)
    80005504:	0880                	addi	s0,sp,80
    80005506:	89ae                	mv	s3,a1
    80005508:	8ab2                	mv	s5,a2
    8000550a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000550c:	fb040593          	addi	a1,s0,-80
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	e24080e7          	jalr	-476(ra) # 80004334 <nameiparent>
    80005518:	892a                	mv	s2,a0
    8000551a:	12050f63          	beqz	a0,80005658 <create+0x164>
    return 0;

  ilock(dp);
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	644080e7          	jalr	1604(ra) # 80003b62 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005526:	4601                	li	a2,0
    80005528:	fb040593          	addi	a1,s0,-80
    8000552c:	854a                	mv	a0,s2
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	b16080e7          	jalr	-1258(ra) # 80004044 <dirlookup>
    80005536:	84aa                	mv	s1,a0
    80005538:	c921                	beqz	a0,80005588 <create+0x94>
    iunlockput(dp);
    8000553a:	854a                	mv	a0,s2
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	888080e7          	jalr	-1912(ra) # 80003dc4 <iunlockput>
    ilock(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	61c080e7          	jalr	1564(ra) # 80003b62 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000554e:	2981                	sext.w	s3,s3
    80005550:	4789                	li	a5,2
    80005552:	02f99463          	bne	s3,a5,8000557a <create+0x86>
    80005556:	04c4d783          	lhu	a5,76(s1)
    8000555a:	37f9                	addiw	a5,a5,-2
    8000555c:	17c2                	slli	a5,a5,0x30
    8000555e:	93c1                	srli	a5,a5,0x30
    80005560:	4705                	li	a4,1
    80005562:	00f76c63          	bltu	a4,a5,8000557a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005566:	8526                	mv	a0,s1
    80005568:	60a6                	ld	ra,72(sp)
    8000556a:	6406                	ld	s0,64(sp)
    8000556c:	74e2                	ld	s1,56(sp)
    8000556e:	7942                	ld	s2,48(sp)
    80005570:	79a2                	ld	s3,40(sp)
    80005572:	7a02                	ld	s4,32(sp)
    80005574:	6ae2                	ld	s5,24(sp)
    80005576:	6161                	addi	sp,sp,80
    80005578:	8082                	ret
    iunlockput(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	848080e7          	jalr	-1976(ra) # 80003dc4 <iunlockput>
    return 0;
    80005584:	4481                	li	s1,0
    80005586:	b7c5                	j	80005566 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005588:	85ce                	mv	a1,s3
    8000558a:	00092503          	lw	a0,0(s2)
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	43c080e7          	jalr	1084(ra) # 800039ca <ialloc>
    80005596:	84aa                	mv	s1,a0
    80005598:	c529                	beqz	a0,800055e2 <create+0xee>
  ilock(ip);
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	5c8080e7          	jalr	1480(ra) # 80003b62 <ilock>
  ip->major = major;
    800055a2:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800055a6:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800055aa:	4785                	li	a5,1
    800055ac:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	4e6080e7          	jalr	1254(ra) # 80003a98 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055ba:	2981                	sext.w	s3,s3
    800055bc:	4785                	li	a5,1
    800055be:	02f98a63          	beq	s3,a5,800055f2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055c2:	40d0                	lw	a2,4(s1)
    800055c4:	fb040593          	addi	a1,s0,-80
    800055c8:	854a                	mv	a0,s2
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	c8a080e7          	jalr	-886(ra) # 80004254 <dirlink>
    800055d2:	06054b63          	bltz	a0,80005648 <create+0x154>
  iunlockput(dp);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	7ec080e7          	jalr	2028(ra) # 80003dc4 <iunlockput>
  return ip;
    800055e0:	b759                	j	80005566 <create+0x72>
    panic("create: ialloc");
    800055e2:	00003517          	auipc	a0,0x3
    800055e6:	17e50513          	addi	a0,a0,382 # 80008760 <syscalls+0x2a8>
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	f66080e7          	jalr	-154(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    800055f2:	05295783          	lhu	a5,82(s2)
    800055f6:	2785                	addiw	a5,a5,1
    800055f8:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800055fc:	854a                	mv	a0,s2
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	49a080e7          	jalr	1178(ra) # 80003a98 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005606:	40d0                	lw	a2,4(s1)
    80005608:	00003597          	auipc	a1,0x3
    8000560c:	16858593          	addi	a1,a1,360 # 80008770 <syscalls+0x2b8>
    80005610:	8526                	mv	a0,s1
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	c42080e7          	jalr	-958(ra) # 80004254 <dirlink>
    8000561a:	00054f63          	bltz	a0,80005638 <create+0x144>
    8000561e:	00492603          	lw	a2,4(s2)
    80005622:	00003597          	auipc	a1,0x3
    80005626:	15658593          	addi	a1,a1,342 # 80008778 <syscalls+0x2c0>
    8000562a:	8526                	mv	a0,s1
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	c28080e7          	jalr	-984(ra) # 80004254 <dirlink>
    80005634:	f80557e3          	bgez	a0,800055c2 <create+0xce>
      panic("create dots");
    80005638:	00003517          	auipc	a0,0x3
    8000563c:	14850513          	addi	a0,a0,328 # 80008780 <syscalls+0x2c8>
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	f10080e7          	jalr	-240(ra) # 80000550 <panic>
    panic("create: dirlink");
    80005648:	00003517          	auipc	a0,0x3
    8000564c:	14850513          	addi	a0,a0,328 # 80008790 <syscalls+0x2d8>
    80005650:	ffffb097          	auipc	ra,0xffffb
    80005654:	f00080e7          	jalr	-256(ra) # 80000550 <panic>
    return 0;
    80005658:	84aa                	mv	s1,a0
    8000565a:	b731                	j	80005566 <create+0x72>

000000008000565c <sys_dup>:
{
    8000565c:	7179                	addi	sp,sp,-48
    8000565e:	f406                	sd	ra,40(sp)
    80005660:	f022                	sd	s0,32(sp)
    80005662:	ec26                	sd	s1,24(sp)
    80005664:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005666:	fd840613          	addi	a2,s0,-40
    8000566a:	4581                	li	a1,0
    8000566c:	4501                	li	a0,0
    8000566e:	00000097          	auipc	ra,0x0
    80005672:	ddc080e7          	jalr	-548(ra) # 8000544a <argfd>
    return -1;
    80005676:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005678:	02054363          	bltz	a0,8000569e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000567c:	fd843503          	ld	a0,-40(s0)
    80005680:	00000097          	auipc	ra,0x0
    80005684:	e32080e7          	jalr	-462(ra) # 800054b2 <fdalloc>
    80005688:	84aa                	mv	s1,a0
    return -1;
    8000568a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000568c:	00054963          	bltz	a0,8000569e <sys_dup+0x42>
  filedup(f);
    80005690:	fd843503          	ld	a0,-40(s0)
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	320080e7          	jalr	800(ra) # 800049b4 <filedup>
  return fd;
    8000569c:	87a6                	mv	a5,s1
}
    8000569e:	853e                	mv	a0,a5
    800056a0:	70a2                	ld	ra,40(sp)
    800056a2:	7402                	ld	s0,32(sp)
    800056a4:	64e2                	ld	s1,24(sp)
    800056a6:	6145                	addi	sp,sp,48
    800056a8:	8082                	ret

00000000800056aa <sys_read>:
{
    800056aa:	7179                	addi	sp,sp,-48
    800056ac:	f406                	sd	ra,40(sp)
    800056ae:	f022                	sd	s0,32(sp)
    800056b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b2:	fe840613          	addi	a2,s0,-24
    800056b6:	4581                	li	a1,0
    800056b8:	4501                	li	a0,0
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	d90080e7          	jalr	-624(ra) # 8000544a <argfd>
    return -1;
    800056c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c4:	04054163          	bltz	a0,80005706 <sys_read+0x5c>
    800056c8:	fe440593          	addi	a1,s0,-28
    800056cc:	4509                	li	a0,2
    800056ce:	ffffd097          	auipc	ra,0xffffd
    800056d2:	72c080e7          	jalr	1836(ra) # 80002dfa <argint>
    return -1;
    800056d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d8:	02054763          	bltz	a0,80005706 <sys_read+0x5c>
    800056dc:	fd840593          	addi	a1,s0,-40
    800056e0:	4505                	li	a0,1
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	73a080e7          	jalr	1850(ra) # 80002e1c <argaddr>
    return -1;
    800056ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ec:	00054d63          	bltz	a0,80005706 <sys_read+0x5c>
  return fileread(f, p, n);
    800056f0:	fe442603          	lw	a2,-28(s0)
    800056f4:	fd843583          	ld	a1,-40(s0)
    800056f8:	fe843503          	ld	a0,-24(s0)
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	444080e7          	jalr	1092(ra) # 80004b40 <fileread>
    80005704:	87aa                	mv	a5,a0
}
    80005706:	853e                	mv	a0,a5
    80005708:	70a2                	ld	ra,40(sp)
    8000570a:	7402                	ld	s0,32(sp)
    8000570c:	6145                	addi	sp,sp,48
    8000570e:	8082                	ret

0000000080005710 <sys_write>:
{
    80005710:	7179                	addi	sp,sp,-48
    80005712:	f406                	sd	ra,40(sp)
    80005714:	f022                	sd	s0,32(sp)
    80005716:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005718:	fe840613          	addi	a2,s0,-24
    8000571c:	4581                	li	a1,0
    8000571e:	4501                	li	a0,0
    80005720:	00000097          	auipc	ra,0x0
    80005724:	d2a080e7          	jalr	-726(ra) # 8000544a <argfd>
    return -1;
    80005728:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572a:	04054163          	bltz	a0,8000576c <sys_write+0x5c>
    8000572e:	fe440593          	addi	a1,s0,-28
    80005732:	4509                	li	a0,2
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	6c6080e7          	jalr	1734(ra) # 80002dfa <argint>
    return -1;
    8000573c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000573e:	02054763          	bltz	a0,8000576c <sys_write+0x5c>
    80005742:	fd840593          	addi	a1,s0,-40
    80005746:	4505                	li	a0,1
    80005748:	ffffd097          	auipc	ra,0xffffd
    8000574c:	6d4080e7          	jalr	1748(ra) # 80002e1c <argaddr>
    return -1;
    80005750:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005752:	00054d63          	bltz	a0,8000576c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005756:	fe442603          	lw	a2,-28(s0)
    8000575a:	fd843583          	ld	a1,-40(s0)
    8000575e:	fe843503          	ld	a0,-24(s0)
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	4a0080e7          	jalr	1184(ra) # 80004c02 <filewrite>
    8000576a:	87aa                	mv	a5,a0
}
    8000576c:	853e                	mv	a0,a5
    8000576e:	70a2                	ld	ra,40(sp)
    80005770:	7402                	ld	s0,32(sp)
    80005772:	6145                	addi	sp,sp,48
    80005774:	8082                	ret

0000000080005776 <sys_close>:
{
    80005776:	1101                	addi	sp,sp,-32
    80005778:	ec06                	sd	ra,24(sp)
    8000577a:	e822                	sd	s0,16(sp)
    8000577c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000577e:	fe040613          	addi	a2,s0,-32
    80005782:	fec40593          	addi	a1,s0,-20
    80005786:	4501                	li	a0,0
    80005788:	00000097          	auipc	ra,0x0
    8000578c:	cc2080e7          	jalr	-830(ra) # 8000544a <argfd>
    return -1;
    80005790:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005792:	02054463          	bltz	a0,800057ba <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005796:	ffffc097          	auipc	ra,0xffffc
    8000579a:	5a6080e7          	jalr	1446(ra) # 80001d3c <myproc>
    8000579e:	fec42783          	lw	a5,-20(s0)
    800057a2:	07e9                	addi	a5,a5,26
    800057a4:	078e                	slli	a5,a5,0x3
    800057a6:	97aa                	add	a5,a5,a0
    800057a8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800057ac:	fe043503          	ld	a0,-32(s0)
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	256080e7          	jalr	598(ra) # 80004a06 <fileclose>
  return 0;
    800057b8:	4781                	li	a5,0
}
    800057ba:	853e                	mv	a0,a5
    800057bc:	60e2                	ld	ra,24(sp)
    800057be:	6442                	ld	s0,16(sp)
    800057c0:	6105                	addi	sp,sp,32
    800057c2:	8082                	ret

00000000800057c4 <sys_fstat>:
{
    800057c4:	1101                	addi	sp,sp,-32
    800057c6:	ec06                	sd	ra,24(sp)
    800057c8:	e822                	sd	s0,16(sp)
    800057ca:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057cc:	fe840613          	addi	a2,s0,-24
    800057d0:	4581                	li	a1,0
    800057d2:	4501                	li	a0,0
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	c76080e7          	jalr	-906(ra) # 8000544a <argfd>
    return -1;
    800057dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057de:	02054563          	bltz	a0,80005808 <sys_fstat+0x44>
    800057e2:	fe040593          	addi	a1,s0,-32
    800057e6:	4505                	li	a0,1
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	634080e7          	jalr	1588(ra) # 80002e1c <argaddr>
    return -1;
    800057f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057f2:	00054b63          	bltz	a0,80005808 <sys_fstat+0x44>
  return filestat(f, st);
    800057f6:	fe043583          	ld	a1,-32(s0)
    800057fa:	fe843503          	ld	a0,-24(s0)
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	2d0080e7          	jalr	720(ra) # 80004ace <filestat>
    80005806:	87aa                	mv	a5,a0
}
    80005808:	853e                	mv	a0,a5
    8000580a:	60e2                	ld	ra,24(sp)
    8000580c:	6442                	ld	s0,16(sp)
    8000580e:	6105                	addi	sp,sp,32
    80005810:	8082                	ret

0000000080005812 <sys_link>:
{
    80005812:	7169                	addi	sp,sp,-304
    80005814:	f606                	sd	ra,296(sp)
    80005816:	f222                	sd	s0,288(sp)
    80005818:	ee26                	sd	s1,280(sp)
    8000581a:	ea4a                	sd	s2,272(sp)
    8000581c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000581e:	08000613          	li	a2,128
    80005822:	ed040593          	addi	a1,s0,-304
    80005826:	4501                	li	a0,0
    80005828:	ffffd097          	auipc	ra,0xffffd
    8000582c:	616080e7          	jalr	1558(ra) # 80002e3e <argstr>
    return -1;
    80005830:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005832:	10054e63          	bltz	a0,8000594e <sys_link+0x13c>
    80005836:	08000613          	li	a2,128
    8000583a:	f5040593          	addi	a1,s0,-176
    8000583e:	4505                	li	a0,1
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	5fe080e7          	jalr	1534(ra) # 80002e3e <argstr>
    return -1;
    80005848:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000584a:	10054263          	bltz	a0,8000594e <sys_link+0x13c>
  begin_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	ce4080e7          	jalr	-796(ra) # 80004532 <begin_op>
  if((ip = namei(old)) == 0){
    80005856:	ed040513          	addi	a0,s0,-304
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	abc080e7          	jalr	-1348(ra) # 80004316 <namei>
    80005862:	84aa                	mv	s1,a0
    80005864:	c551                	beqz	a0,800058f0 <sys_link+0xde>
  ilock(ip);
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	2fc080e7          	jalr	764(ra) # 80003b62 <ilock>
  if(ip->type == T_DIR){
    8000586e:	04c49703          	lh	a4,76(s1)
    80005872:	4785                	li	a5,1
    80005874:	08f70463          	beq	a4,a5,800058fc <sys_link+0xea>
  ip->nlink++;
    80005878:	0524d783          	lhu	a5,82(s1)
    8000587c:	2785                	addiw	a5,a5,1
    8000587e:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	214080e7          	jalr	532(ra) # 80003a98 <iupdate>
  iunlock(ip);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	396080e7          	jalr	918(ra) # 80003c24 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005896:	fd040593          	addi	a1,s0,-48
    8000589a:	f5040513          	addi	a0,s0,-176
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	a96080e7          	jalr	-1386(ra) # 80004334 <nameiparent>
    800058a6:	892a                	mv	s2,a0
    800058a8:	c935                	beqz	a0,8000591c <sys_link+0x10a>
  ilock(dp);
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	2b8080e7          	jalr	696(ra) # 80003b62 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058b2:	00092703          	lw	a4,0(s2)
    800058b6:	409c                	lw	a5,0(s1)
    800058b8:	04f71d63          	bne	a4,a5,80005912 <sys_link+0x100>
    800058bc:	40d0                	lw	a2,4(s1)
    800058be:	fd040593          	addi	a1,s0,-48
    800058c2:	854a                	mv	a0,s2
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	990080e7          	jalr	-1648(ra) # 80004254 <dirlink>
    800058cc:	04054363          	bltz	a0,80005912 <sys_link+0x100>
  iunlockput(dp);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	4f2080e7          	jalr	1266(ra) # 80003dc4 <iunlockput>
  iput(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	440080e7          	jalr	1088(ra) # 80003d1c <iput>
  end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	cce080e7          	jalr	-818(ra) # 800045b2 <end_op>
  return 0;
    800058ec:	4781                	li	a5,0
    800058ee:	a085                	j	8000594e <sys_link+0x13c>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	cc2080e7          	jalr	-830(ra) # 800045b2 <end_op>
    return -1;
    800058f8:	57fd                	li	a5,-1
    800058fa:	a891                	j	8000594e <sys_link+0x13c>
    iunlockput(ip);
    800058fc:	8526                	mv	a0,s1
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	4c6080e7          	jalr	1222(ra) # 80003dc4 <iunlockput>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	cac080e7          	jalr	-852(ra) # 800045b2 <end_op>
    return -1;
    8000590e:	57fd                	li	a5,-1
    80005910:	a83d                	j	8000594e <sys_link+0x13c>
    iunlockput(dp);
    80005912:	854a                	mv	a0,s2
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	4b0080e7          	jalr	1200(ra) # 80003dc4 <iunlockput>
  ilock(ip);
    8000591c:	8526                	mv	a0,s1
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	244080e7          	jalr	580(ra) # 80003b62 <ilock>
  ip->nlink--;
    80005926:	0524d783          	lhu	a5,82(s1)
    8000592a:	37fd                	addiw	a5,a5,-1
    8000592c:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	166080e7          	jalr	358(ra) # 80003a98 <iupdate>
  iunlockput(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	488080e7          	jalr	1160(ra) # 80003dc4 <iunlockput>
  end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	c6e080e7          	jalr	-914(ra) # 800045b2 <end_op>
  return -1;
    8000594c:	57fd                	li	a5,-1
}
    8000594e:	853e                	mv	a0,a5
    80005950:	70b2                	ld	ra,296(sp)
    80005952:	7412                	ld	s0,288(sp)
    80005954:	64f2                	ld	s1,280(sp)
    80005956:	6952                	ld	s2,272(sp)
    80005958:	6155                	addi	sp,sp,304
    8000595a:	8082                	ret

000000008000595c <sys_unlink>:
{
    8000595c:	7151                	addi	sp,sp,-240
    8000595e:	f586                	sd	ra,232(sp)
    80005960:	f1a2                	sd	s0,224(sp)
    80005962:	eda6                	sd	s1,216(sp)
    80005964:	e9ca                	sd	s2,208(sp)
    80005966:	e5ce                	sd	s3,200(sp)
    80005968:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000596a:	08000613          	li	a2,128
    8000596e:	f3040593          	addi	a1,s0,-208
    80005972:	4501                	li	a0,0
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	4ca080e7          	jalr	1226(ra) # 80002e3e <argstr>
    8000597c:	18054163          	bltz	a0,80005afe <sys_unlink+0x1a2>
  begin_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	bb2080e7          	jalr	-1102(ra) # 80004532 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005988:	fb040593          	addi	a1,s0,-80
    8000598c:	f3040513          	addi	a0,s0,-208
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	9a4080e7          	jalr	-1628(ra) # 80004334 <nameiparent>
    80005998:	84aa                	mv	s1,a0
    8000599a:	c979                	beqz	a0,80005a70 <sys_unlink+0x114>
  ilock(dp);
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	1c6080e7          	jalr	454(ra) # 80003b62 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059a4:	00003597          	auipc	a1,0x3
    800059a8:	dcc58593          	addi	a1,a1,-564 # 80008770 <syscalls+0x2b8>
    800059ac:	fb040513          	addi	a0,s0,-80
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	67a080e7          	jalr	1658(ra) # 8000402a <namecmp>
    800059b8:	14050a63          	beqz	a0,80005b0c <sys_unlink+0x1b0>
    800059bc:	00003597          	auipc	a1,0x3
    800059c0:	dbc58593          	addi	a1,a1,-580 # 80008778 <syscalls+0x2c0>
    800059c4:	fb040513          	addi	a0,s0,-80
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	662080e7          	jalr	1634(ra) # 8000402a <namecmp>
    800059d0:	12050e63          	beqz	a0,80005b0c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059d4:	f2c40613          	addi	a2,s0,-212
    800059d8:	fb040593          	addi	a1,s0,-80
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	666080e7          	jalr	1638(ra) # 80004044 <dirlookup>
    800059e6:	892a                	mv	s2,a0
    800059e8:	12050263          	beqz	a0,80005b0c <sys_unlink+0x1b0>
  ilock(ip);
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	176080e7          	jalr	374(ra) # 80003b62 <ilock>
  if(ip->nlink < 1)
    800059f4:	05291783          	lh	a5,82(s2)
    800059f8:	08f05263          	blez	a5,80005a7c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059fc:	04c91703          	lh	a4,76(s2)
    80005a00:	4785                	li	a5,1
    80005a02:	08f70563          	beq	a4,a5,80005a8c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a06:	4641                	li	a2,16
    80005a08:	4581                	li	a1,0
    80005a0a:	fc040513          	addi	a0,s0,-64
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	6c6080e7          	jalr	1734(ra) # 800010d4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a16:	4741                	li	a4,16
    80005a18:	f2c42683          	lw	a3,-212(s0)
    80005a1c:	fc040613          	addi	a2,s0,-64
    80005a20:	4581                	li	a1,0
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	4ea080e7          	jalr	1258(ra) # 80003f0e <writei>
    80005a2c:	47c1                	li	a5,16
    80005a2e:	0af51563          	bne	a0,a5,80005ad8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a32:	04c91703          	lh	a4,76(s2)
    80005a36:	4785                	li	a5,1
    80005a38:	0af70863          	beq	a4,a5,80005ae8 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	386080e7          	jalr	902(ra) # 80003dc4 <iunlockput>
  ip->nlink--;
    80005a46:	05295783          	lhu	a5,82(s2)
    80005a4a:	37fd                	addiw	a5,a5,-1
    80005a4c:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005a50:	854a                	mv	a0,s2
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	046080e7          	jalr	70(ra) # 80003a98 <iupdate>
  iunlockput(ip);
    80005a5a:	854a                	mv	a0,s2
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	368080e7          	jalr	872(ra) # 80003dc4 <iunlockput>
  end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	b4e080e7          	jalr	-1202(ra) # 800045b2 <end_op>
  return 0;
    80005a6c:	4501                	li	a0,0
    80005a6e:	a84d                	j	80005b20 <sys_unlink+0x1c4>
    end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	b42080e7          	jalr	-1214(ra) # 800045b2 <end_op>
    return -1;
    80005a78:	557d                	li	a0,-1
    80005a7a:	a05d                	j	80005b20 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a7c:	00003517          	auipc	a0,0x3
    80005a80:	d2450513          	addi	a0,a0,-732 # 800087a0 <syscalls+0x2e8>
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	acc080e7          	jalr	-1332(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a8c:	05492703          	lw	a4,84(s2)
    80005a90:	02000793          	li	a5,32
    80005a94:	f6e7f9e3          	bgeu	a5,a4,80005a06 <sys_unlink+0xaa>
    80005a98:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a9c:	4741                	li	a4,16
    80005a9e:	86ce                	mv	a3,s3
    80005aa0:	f1840613          	addi	a2,s0,-232
    80005aa4:	4581                	li	a1,0
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	36e080e7          	jalr	878(ra) # 80003e16 <readi>
    80005ab0:	47c1                	li	a5,16
    80005ab2:	00f51b63          	bne	a0,a5,80005ac8 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ab6:	f1845783          	lhu	a5,-232(s0)
    80005aba:	e7a1                	bnez	a5,80005b02 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005abc:	29c1                	addiw	s3,s3,16
    80005abe:	05492783          	lw	a5,84(s2)
    80005ac2:	fcf9ede3          	bltu	s3,a5,80005a9c <sys_unlink+0x140>
    80005ac6:	b781                	j	80005a06 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ac8:	00003517          	auipc	a0,0x3
    80005acc:	cf050513          	addi	a0,a0,-784 # 800087b8 <syscalls+0x300>
    80005ad0:	ffffb097          	auipc	ra,0xffffb
    80005ad4:	a80080e7          	jalr	-1408(ra) # 80000550 <panic>
    panic("unlink: writei");
    80005ad8:	00003517          	auipc	a0,0x3
    80005adc:	cf850513          	addi	a0,a0,-776 # 800087d0 <syscalls+0x318>
    80005ae0:	ffffb097          	auipc	ra,0xffffb
    80005ae4:	a70080e7          	jalr	-1424(ra) # 80000550 <panic>
    dp->nlink--;
    80005ae8:	0524d783          	lhu	a5,82(s1)
    80005aec:	37fd                	addiw	a5,a5,-1
    80005aee:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	fa4080e7          	jalr	-92(ra) # 80003a98 <iupdate>
    80005afc:	b781                	j	80005a3c <sys_unlink+0xe0>
    return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	a005                	j	80005b20 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b02:	854a                	mv	a0,s2
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	2c0080e7          	jalr	704(ra) # 80003dc4 <iunlockput>
  iunlockput(dp);
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	2b6080e7          	jalr	694(ra) # 80003dc4 <iunlockput>
  end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	a9c080e7          	jalr	-1380(ra) # 800045b2 <end_op>
  return -1;
    80005b1e:	557d                	li	a0,-1
}
    80005b20:	70ae                	ld	ra,232(sp)
    80005b22:	740e                	ld	s0,224(sp)
    80005b24:	64ee                	ld	s1,216(sp)
    80005b26:	694e                	ld	s2,208(sp)
    80005b28:	69ae                	ld	s3,200(sp)
    80005b2a:	616d                	addi	sp,sp,240
    80005b2c:	8082                	ret

0000000080005b2e <sys_open>:

uint64
sys_open(void)
{
    80005b2e:	7131                	addi	sp,sp,-192
    80005b30:	fd06                	sd	ra,184(sp)
    80005b32:	f922                	sd	s0,176(sp)
    80005b34:	f526                	sd	s1,168(sp)
    80005b36:	f14a                	sd	s2,160(sp)
    80005b38:	ed4e                	sd	s3,152(sp)
    80005b3a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b3c:	08000613          	li	a2,128
    80005b40:	f5040593          	addi	a1,s0,-176
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	2f8080e7          	jalr	760(ra) # 80002e3e <argstr>
    return -1;
    80005b4e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b50:	0c054163          	bltz	a0,80005c12 <sys_open+0xe4>
    80005b54:	f4c40593          	addi	a1,s0,-180
    80005b58:	4505                	li	a0,1
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	2a0080e7          	jalr	672(ra) # 80002dfa <argint>
    80005b62:	0a054863          	bltz	a0,80005c12 <sys_open+0xe4>

  begin_op();
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	9cc080e7          	jalr	-1588(ra) # 80004532 <begin_op>

  if(omode & O_CREATE){
    80005b6e:	f4c42783          	lw	a5,-180(s0)
    80005b72:	2007f793          	andi	a5,a5,512
    80005b76:	cbdd                	beqz	a5,80005c2c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b78:	4681                	li	a3,0
    80005b7a:	4601                	li	a2,0
    80005b7c:	4589                	li	a1,2
    80005b7e:	f5040513          	addi	a0,s0,-176
    80005b82:	00000097          	auipc	ra,0x0
    80005b86:	972080e7          	jalr	-1678(ra) # 800054f4 <create>
    80005b8a:	892a                	mv	s2,a0
    if(ip == 0){
    80005b8c:	c959                	beqz	a0,80005c22 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b8e:	04c91703          	lh	a4,76(s2)
    80005b92:	478d                	li	a5,3
    80005b94:	00f71763          	bne	a4,a5,80005ba2 <sys_open+0x74>
    80005b98:	04e95703          	lhu	a4,78(s2)
    80005b9c:	47a5                	li	a5,9
    80005b9e:	0ce7ec63          	bltu	a5,a4,80005c76 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	da8080e7          	jalr	-600(ra) # 8000494a <filealloc>
    80005baa:	89aa                	mv	s3,a0
    80005bac:	10050263          	beqz	a0,80005cb0 <sys_open+0x182>
    80005bb0:	00000097          	auipc	ra,0x0
    80005bb4:	902080e7          	jalr	-1790(ra) # 800054b2 <fdalloc>
    80005bb8:	84aa                	mv	s1,a0
    80005bba:	0e054663          	bltz	a0,80005ca6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bbe:	04c91703          	lh	a4,76(s2)
    80005bc2:	478d                	li	a5,3
    80005bc4:	0cf70463          	beq	a4,a5,80005c8c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bc8:	4789                	li	a5,2
    80005bca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bd2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bd6:	f4c42783          	lw	a5,-180(s0)
    80005bda:	0017c713          	xori	a4,a5,1
    80005bde:	8b05                	andi	a4,a4,1
    80005be0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005be4:	0037f713          	andi	a4,a5,3
    80005be8:	00e03733          	snez	a4,a4
    80005bec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bf0:	4007f793          	andi	a5,a5,1024
    80005bf4:	c791                	beqz	a5,80005c00 <sys_open+0xd2>
    80005bf6:	04c91703          	lh	a4,76(s2)
    80005bfa:	4789                	li	a5,2
    80005bfc:	08f70f63          	beq	a4,a5,80005c9a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c00:	854a                	mv	a0,s2
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	022080e7          	jalr	34(ra) # 80003c24 <iunlock>
  end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	9a8080e7          	jalr	-1624(ra) # 800045b2 <end_op>

  return fd;
}
    80005c12:	8526                	mv	a0,s1
    80005c14:	70ea                	ld	ra,184(sp)
    80005c16:	744a                	ld	s0,176(sp)
    80005c18:	74aa                	ld	s1,168(sp)
    80005c1a:	790a                	ld	s2,160(sp)
    80005c1c:	69ea                	ld	s3,152(sp)
    80005c1e:	6129                	addi	sp,sp,192
    80005c20:	8082                	ret
      end_op();
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	990080e7          	jalr	-1648(ra) # 800045b2 <end_op>
      return -1;
    80005c2a:	b7e5                	j	80005c12 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c2c:	f5040513          	addi	a0,s0,-176
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	6e6080e7          	jalr	1766(ra) # 80004316 <namei>
    80005c38:	892a                	mv	s2,a0
    80005c3a:	c905                	beqz	a0,80005c6a <sys_open+0x13c>
    ilock(ip);
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	f26080e7          	jalr	-218(ra) # 80003b62 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c44:	04c91703          	lh	a4,76(s2)
    80005c48:	4785                	li	a5,1
    80005c4a:	f4f712e3          	bne	a4,a5,80005b8e <sys_open+0x60>
    80005c4e:	f4c42783          	lw	a5,-180(s0)
    80005c52:	dba1                	beqz	a5,80005ba2 <sys_open+0x74>
      iunlockput(ip);
    80005c54:	854a                	mv	a0,s2
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	16e080e7          	jalr	366(ra) # 80003dc4 <iunlockput>
      end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	954080e7          	jalr	-1708(ra) # 800045b2 <end_op>
      return -1;
    80005c66:	54fd                	li	s1,-1
    80005c68:	b76d                	j	80005c12 <sys_open+0xe4>
      end_op();
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	948080e7          	jalr	-1720(ra) # 800045b2 <end_op>
      return -1;
    80005c72:	54fd                	li	s1,-1
    80005c74:	bf79                	j	80005c12 <sys_open+0xe4>
    iunlockput(ip);
    80005c76:	854a                	mv	a0,s2
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	14c080e7          	jalr	332(ra) # 80003dc4 <iunlockput>
    end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	932080e7          	jalr	-1742(ra) # 800045b2 <end_op>
    return -1;
    80005c88:	54fd                	li	s1,-1
    80005c8a:	b761                	j	80005c12 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c8c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c90:	04e91783          	lh	a5,78(s2)
    80005c94:	02f99223          	sh	a5,36(s3)
    80005c98:	bf2d                	j	80005bd2 <sys_open+0xa4>
    itrunc(ip);
    80005c9a:	854a                	mv	a0,s2
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	fd4080e7          	jalr	-44(ra) # 80003c70 <itrunc>
    80005ca4:	bfb1                	j	80005c00 <sys_open+0xd2>
      fileclose(f);
    80005ca6:	854e                	mv	a0,s3
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	d5e080e7          	jalr	-674(ra) # 80004a06 <fileclose>
    iunlockput(ip);
    80005cb0:	854a                	mv	a0,s2
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	112080e7          	jalr	274(ra) # 80003dc4 <iunlockput>
    end_op();
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	8f8080e7          	jalr	-1800(ra) # 800045b2 <end_op>
    return -1;
    80005cc2:	54fd                	li	s1,-1
    80005cc4:	b7b9                	j	80005c12 <sys_open+0xe4>

0000000080005cc6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cc6:	7175                	addi	sp,sp,-144
    80005cc8:	e506                	sd	ra,136(sp)
    80005cca:	e122                	sd	s0,128(sp)
    80005ccc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	864080e7          	jalr	-1948(ra) # 80004532 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cd6:	08000613          	li	a2,128
    80005cda:	f7040593          	addi	a1,s0,-144
    80005cde:	4501                	li	a0,0
    80005ce0:	ffffd097          	auipc	ra,0xffffd
    80005ce4:	15e080e7          	jalr	350(ra) # 80002e3e <argstr>
    80005ce8:	02054963          	bltz	a0,80005d1a <sys_mkdir+0x54>
    80005cec:	4681                	li	a3,0
    80005cee:	4601                	li	a2,0
    80005cf0:	4585                	li	a1,1
    80005cf2:	f7040513          	addi	a0,s0,-144
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	7fe080e7          	jalr	2046(ra) # 800054f4 <create>
    80005cfe:	cd11                	beqz	a0,80005d1a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	0c4080e7          	jalr	196(ra) # 80003dc4 <iunlockput>
  end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	8aa080e7          	jalr	-1878(ra) # 800045b2 <end_op>
  return 0;
    80005d10:	4501                	li	a0,0
}
    80005d12:	60aa                	ld	ra,136(sp)
    80005d14:	640a                	ld	s0,128(sp)
    80005d16:	6149                	addi	sp,sp,144
    80005d18:	8082                	ret
    end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	898080e7          	jalr	-1896(ra) # 800045b2 <end_op>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	b7fd                	j	80005d12 <sys_mkdir+0x4c>

0000000080005d26 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d26:	7135                	addi	sp,sp,-160
    80005d28:	ed06                	sd	ra,152(sp)
    80005d2a:	e922                	sd	s0,144(sp)
    80005d2c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	804080e7          	jalr	-2044(ra) # 80004532 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d36:	08000613          	li	a2,128
    80005d3a:	f7040593          	addi	a1,s0,-144
    80005d3e:	4501                	li	a0,0
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	0fe080e7          	jalr	254(ra) # 80002e3e <argstr>
    80005d48:	04054a63          	bltz	a0,80005d9c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d4c:	f6c40593          	addi	a1,s0,-148
    80005d50:	4505                	li	a0,1
    80005d52:	ffffd097          	auipc	ra,0xffffd
    80005d56:	0a8080e7          	jalr	168(ra) # 80002dfa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d5a:	04054163          	bltz	a0,80005d9c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d5e:	f6840593          	addi	a1,s0,-152
    80005d62:	4509                	li	a0,2
    80005d64:	ffffd097          	auipc	ra,0xffffd
    80005d68:	096080e7          	jalr	150(ra) # 80002dfa <argint>
     argint(1, &major) < 0 ||
    80005d6c:	02054863          	bltz	a0,80005d9c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d70:	f6841683          	lh	a3,-152(s0)
    80005d74:	f6c41603          	lh	a2,-148(s0)
    80005d78:	458d                	li	a1,3
    80005d7a:	f7040513          	addi	a0,s0,-144
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	776080e7          	jalr	1910(ra) # 800054f4 <create>
     argint(2, &minor) < 0 ||
    80005d86:	c919                	beqz	a0,80005d9c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	03c080e7          	jalr	60(ra) # 80003dc4 <iunlockput>
  end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	822080e7          	jalr	-2014(ra) # 800045b2 <end_op>
  return 0;
    80005d98:	4501                	li	a0,0
    80005d9a:	a031                	j	80005da6 <sys_mknod+0x80>
    end_op();
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	816080e7          	jalr	-2026(ra) # 800045b2 <end_op>
    return -1;
    80005da4:	557d                	li	a0,-1
}
    80005da6:	60ea                	ld	ra,152(sp)
    80005da8:	644a                	ld	s0,144(sp)
    80005daa:	610d                	addi	sp,sp,160
    80005dac:	8082                	ret

0000000080005dae <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dae:	7135                	addi	sp,sp,-160
    80005db0:	ed06                	sd	ra,152(sp)
    80005db2:	e922                	sd	s0,144(sp)
    80005db4:	e526                	sd	s1,136(sp)
    80005db6:	e14a                	sd	s2,128(sp)
    80005db8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dba:	ffffc097          	auipc	ra,0xffffc
    80005dbe:	f82080e7          	jalr	-126(ra) # 80001d3c <myproc>
    80005dc2:	892a                	mv	s2,a0
  
  begin_op();
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	76e080e7          	jalr	1902(ra) # 80004532 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dcc:	08000613          	li	a2,128
    80005dd0:	f6040593          	addi	a1,s0,-160
    80005dd4:	4501                	li	a0,0
    80005dd6:	ffffd097          	auipc	ra,0xffffd
    80005dda:	068080e7          	jalr	104(ra) # 80002e3e <argstr>
    80005dde:	04054b63          	bltz	a0,80005e34 <sys_chdir+0x86>
    80005de2:	f6040513          	addi	a0,s0,-160
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	530080e7          	jalr	1328(ra) # 80004316 <namei>
    80005dee:	84aa                	mv	s1,a0
    80005df0:	c131                	beqz	a0,80005e34 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	d70080e7          	jalr	-656(ra) # 80003b62 <ilock>
  if(ip->type != T_DIR){
    80005dfa:	04c49703          	lh	a4,76(s1)
    80005dfe:	4785                	li	a5,1
    80005e00:	04f71063          	bne	a4,a5,80005e40 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	e1e080e7          	jalr	-482(ra) # 80003c24 <iunlock>
  iput(p->cwd);
    80005e0e:	15893503          	ld	a0,344(s2)
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	f0a080e7          	jalr	-246(ra) # 80003d1c <iput>
  end_op();
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	798080e7          	jalr	1944(ra) # 800045b2 <end_op>
  p->cwd = ip;
    80005e22:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e26:	4501                	li	a0,0
}
    80005e28:	60ea                	ld	ra,152(sp)
    80005e2a:	644a                	ld	s0,144(sp)
    80005e2c:	64aa                	ld	s1,136(sp)
    80005e2e:	690a                	ld	s2,128(sp)
    80005e30:	610d                	addi	sp,sp,160
    80005e32:	8082                	ret
    end_op();
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	77e080e7          	jalr	1918(ra) # 800045b2 <end_op>
    return -1;
    80005e3c:	557d                	li	a0,-1
    80005e3e:	b7ed                	j	80005e28 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	f82080e7          	jalr	-126(ra) # 80003dc4 <iunlockput>
    end_op();
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	768080e7          	jalr	1896(ra) # 800045b2 <end_op>
    return -1;
    80005e52:	557d                	li	a0,-1
    80005e54:	bfd1                	j	80005e28 <sys_chdir+0x7a>

0000000080005e56 <sys_exec>:

uint64
sys_exec(void)
{
    80005e56:	7145                	addi	sp,sp,-464
    80005e58:	e786                	sd	ra,456(sp)
    80005e5a:	e3a2                	sd	s0,448(sp)
    80005e5c:	ff26                	sd	s1,440(sp)
    80005e5e:	fb4a                	sd	s2,432(sp)
    80005e60:	f74e                	sd	s3,424(sp)
    80005e62:	f352                	sd	s4,416(sp)
    80005e64:	ef56                	sd	s5,408(sp)
    80005e66:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e68:	08000613          	li	a2,128
    80005e6c:	f4040593          	addi	a1,s0,-192
    80005e70:	4501                	li	a0,0
    80005e72:	ffffd097          	auipc	ra,0xffffd
    80005e76:	fcc080e7          	jalr	-52(ra) # 80002e3e <argstr>
    return -1;
    80005e7a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e7c:	0c054a63          	bltz	a0,80005f50 <sys_exec+0xfa>
    80005e80:	e3840593          	addi	a1,s0,-456
    80005e84:	4505                	li	a0,1
    80005e86:	ffffd097          	auipc	ra,0xffffd
    80005e8a:	f96080e7          	jalr	-106(ra) # 80002e1c <argaddr>
    80005e8e:	0c054163          	bltz	a0,80005f50 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e92:	10000613          	li	a2,256
    80005e96:	4581                	li	a1,0
    80005e98:	e4040513          	addi	a0,s0,-448
    80005e9c:	ffffb097          	auipc	ra,0xffffb
    80005ea0:	238080e7          	jalr	568(ra) # 800010d4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ea4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ea8:	89a6                	mv	s3,s1
    80005eaa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eac:	02000a13          	li	s4,32
    80005eb0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005eb4:	00391513          	slli	a0,s2,0x3
    80005eb8:	e3040593          	addi	a1,s0,-464
    80005ebc:	e3843783          	ld	a5,-456(s0)
    80005ec0:	953e                	add	a0,a0,a5
    80005ec2:	ffffd097          	auipc	ra,0xffffd
    80005ec6:	e9e080e7          	jalr	-354(ra) # 80002d60 <fetchaddr>
    80005eca:	02054a63          	bltz	a0,80005efe <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ece:	e3043783          	ld	a5,-464(s0)
    80005ed2:	c3b9                	beqz	a5,80005f18 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ed4:	ffffb097          	auipc	ra,0xffffb
    80005ed8:	ca4080e7          	jalr	-860(ra) # 80000b78 <kalloc>
    80005edc:	85aa                	mv	a1,a0
    80005ede:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ee2:	cd11                	beqz	a0,80005efe <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ee4:	6605                	lui	a2,0x1
    80005ee6:	e3043503          	ld	a0,-464(s0)
    80005eea:	ffffd097          	auipc	ra,0xffffd
    80005eee:	ec8080e7          	jalr	-312(ra) # 80002db2 <fetchstr>
    80005ef2:	00054663          	bltz	a0,80005efe <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ef6:	0905                	addi	s2,s2,1
    80005ef8:	09a1                	addi	s3,s3,8
    80005efa:	fb491be3          	bne	s2,s4,80005eb0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005efe:	10048913          	addi	s2,s1,256
    80005f02:	6088                	ld	a0,0(s1)
    80005f04:	c529                	beqz	a0,80005f4e <sys_exec+0xf8>
    kfree(argv[i]);
    80005f06:	ffffb097          	auipc	ra,0xffffb
    80005f0a:	b26080e7          	jalr	-1242(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f0e:	04a1                	addi	s1,s1,8
    80005f10:	ff2499e3          	bne	s1,s2,80005f02 <sys_exec+0xac>
  return -1;
    80005f14:	597d                	li	s2,-1
    80005f16:	a82d                	j	80005f50 <sys_exec+0xfa>
      argv[i] = 0;
    80005f18:	0a8e                	slli	s5,s5,0x3
    80005f1a:	fc040793          	addi	a5,s0,-64
    80005f1e:	9abe                	add	s5,s5,a5
    80005f20:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f24:	e4040593          	addi	a1,s0,-448
    80005f28:	f4040513          	addi	a0,s0,-192
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	194080e7          	jalr	404(ra) # 800050c0 <exec>
    80005f34:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f36:	10048993          	addi	s3,s1,256
    80005f3a:	6088                	ld	a0,0(s1)
    80005f3c:	c911                	beqz	a0,80005f50 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	aee080e7          	jalr	-1298(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f46:	04a1                	addi	s1,s1,8
    80005f48:	ff3499e3          	bne	s1,s3,80005f3a <sys_exec+0xe4>
    80005f4c:	a011                	j	80005f50 <sys_exec+0xfa>
  return -1;
    80005f4e:	597d                	li	s2,-1
}
    80005f50:	854a                	mv	a0,s2
    80005f52:	60be                	ld	ra,456(sp)
    80005f54:	641e                	ld	s0,448(sp)
    80005f56:	74fa                	ld	s1,440(sp)
    80005f58:	795a                	ld	s2,432(sp)
    80005f5a:	79ba                	ld	s3,424(sp)
    80005f5c:	7a1a                	ld	s4,416(sp)
    80005f5e:	6afa                	ld	s5,408(sp)
    80005f60:	6179                	addi	sp,sp,464
    80005f62:	8082                	ret

0000000080005f64 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f64:	7139                	addi	sp,sp,-64
    80005f66:	fc06                	sd	ra,56(sp)
    80005f68:	f822                	sd	s0,48(sp)
    80005f6a:	f426                	sd	s1,40(sp)
    80005f6c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f6e:	ffffc097          	auipc	ra,0xffffc
    80005f72:	dce080e7          	jalr	-562(ra) # 80001d3c <myproc>
    80005f76:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f78:	fd840593          	addi	a1,s0,-40
    80005f7c:	4501                	li	a0,0
    80005f7e:	ffffd097          	auipc	ra,0xffffd
    80005f82:	e9e080e7          	jalr	-354(ra) # 80002e1c <argaddr>
    return -1;
    80005f86:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f88:	0e054063          	bltz	a0,80006068 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f8c:	fc840593          	addi	a1,s0,-56
    80005f90:	fd040513          	addi	a0,s0,-48
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	dc8080e7          	jalr	-568(ra) # 80004d5c <pipealloc>
    return -1;
    80005f9c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f9e:	0c054563          	bltz	a0,80006068 <sys_pipe+0x104>
  fd0 = -1;
    80005fa2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fa6:	fd043503          	ld	a0,-48(s0)
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	508080e7          	jalr	1288(ra) # 800054b2 <fdalloc>
    80005fb2:	fca42223          	sw	a0,-60(s0)
    80005fb6:	08054c63          	bltz	a0,8000604e <sys_pipe+0xea>
    80005fba:	fc843503          	ld	a0,-56(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	4f4080e7          	jalr	1268(ra) # 800054b2 <fdalloc>
    80005fc6:	fca42023          	sw	a0,-64(s0)
    80005fca:	06054863          	bltz	a0,8000603a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fce:	4691                	li	a3,4
    80005fd0:	fc440613          	addi	a2,s0,-60
    80005fd4:	fd843583          	ld	a1,-40(s0)
    80005fd8:	6ca8                	ld	a0,88(s1)
    80005fda:	ffffc097          	auipc	ra,0xffffc
    80005fde:	a56080e7          	jalr	-1450(ra) # 80001a30 <copyout>
    80005fe2:	02054063          	bltz	a0,80006002 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fe6:	4691                	li	a3,4
    80005fe8:	fc040613          	addi	a2,s0,-64
    80005fec:	fd843583          	ld	a1,-40(s0)
    80005ff0:	0591                	addi	a1,a1,4
    80005ff2:	6ca8                	ld	a0,88(s1)
    80005ff4:	ffffc097          	auipc	ra,0xffffc
    80005ff8:	a3c080e7          	jalr	-1476(ra) # 80001a30 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ffc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ffe:	06055563          	bgez	a0,80006068 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006002:	fc442783          	lw	a5,-60(s0)
    80006006:	07e9                	addi	a5,a5,26
    80006008:	078e                	slli	a5,a5,0x3
    8000600a:	97a6                	add	a5,a5,s1
    8000600c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006010:	fc042503          	lw	a0,-64(s0)
    80006014:	0569                	addi	a0,a0,26
    80006016:	050e                	slli	a0,a0,0x3
    80006018:	9526                	add	a0,a0,s1
    8000601a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000601e:	fd043503          	ld	a0,-48(s0)
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	9e4080e7          	jalr	-1564(ra) # 80004a06 <fileclose>
    fileclose(wf);
    8000602a:	fc843503          	ld	a0,-56(s0)
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	9d8080e7          	jalr	-1576(ra) # 80004a06 <fileclose>
    return -1;
    80006036:	57fd                	li	a5,-1
    80006038:	a805                	j	80006068 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000603a:	fc442783          	lw	a5,-60(s0)
    8000603e:	0007c863          	bltz	a5,8000604e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006042:	01a78513          	addi	a0,a5,26
    80006046:	050e                	slli	a0,a0,0x3
    80006048:	9526                	add	a0,a0,s1
    8000604a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000604e:	fd043503          	ld	a0,-48(s0)
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	9b4080e7          	jalr	-1612(ra) # 80004a06 <fileclose>
    fileclose(wf);
    8000605a:	fc843503          	ld	a0,-56(s0)
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	9a8080e7          	jalr	-1624(ra) # 80004a06 <fileclose>
    return -1;
    80006066:	57fd                	li	a5,-1
}
    80006068:	853e                	mv	a0,a5
    8000606a:	70e2                	ld	ra,56(sp)
    8000606c:	7442                	ld	s0,48(sp)
    8000606e:	74a2                	ld	s1,40(sp)
    80006070:	6121                	addi	sp,sp,64
    80006072:	8082                	ret
	...

0000000080006080 <kernelvec>:
    80006080:	7111                	addi	sp,sp,-256
    80006082:	e006                	sd	ra,0(sp)
    80006084:	e40a                	sd	sp,8(sp)
    80006086:	e80e                	sd	gp,16(sp)
    80006088:	ec12                	sd	tp,24(sp)
    8000608a:	f016                	sd	t0,32(sp)
    8000608c:	f41a                	sd	t1,40(sp)
    8000608e:	f81e                	sd	t2,48(sp)
    80006090:	fc22                	sd	s0,56(sp)
    80006092:	e0a6                	sd	s1,64(sp)
    80006094:	e4aa                	sd	a0,72(sp)
    80006096:	e8ae                	sd	a1,80(sp)
    80006098:	ecb2                	sd	a2,88(sp)
    8000609a:	f0b6                	sd	a3,96(sp)
    8000609c:	f4ba                	sd	a4,104(sp)
    8000609e:	f8be                	sd	a5,112(sp)
    800060a0:	fcc2                	sd	a6,120(sp)
    800060a2:	e146                	sd	a7,128(sp)
    800060a4:	e54a                	sd	s2,136(sp)
    800060a6:	e94e                	sd	s3,144(sp)
    800060a8:	ed52                	sd	s4,152(sp)
    800060aa:	f156                	sd	s5,160(sp)
    800060ac:	f55a                	sd	s6,168(sp)
    800060ae:	f95e                	sd	s7,176(sp)
    800060b0:	fd62                	sd	s8,184(sp)
    800060b2:	e1e6                	sd	s9,192(sp)
    800060b4:	e5ea                	sd	s10,200(sp)
    800060b6:	e9ee                	sd	s11,208(sp)
    800060b8:	edf2                	sd	t3,216(sp)
    800060ba:	f1f6                	sd	t4,224(sp)
    800060bc:	f5fa                	sd	t5,232(sp)
    800060be:	f9fe                	sd	t6,240(sp)
    800060c0:	b6dfc0ef          	jal	ra,80002c2c <kerneltrap>
    800060c4:	6082                	ld	ra,0(sp)
    800060c6:	6122                	ld	sp,8(sp)
    800060c8:	61c2                	ld	gp,16(sp)
    800060ca:	7282                	ld	t0,32(sp)
    800060cc:	7322                	ld	t1,40(sp)
    800060ce:	73c2                	ld	t2,48(sp)
    800060d0:	7462                	ld	s0,56(sp)
    800060d2:	6486                	ld	s1,64(sp)
    800060d4:	6526                	ld	a0,72(sp)
    800060d6:	65c6                	ld	a1,80(sp)
    800060d8:	6666                	ld	a2,88(sp)
    800060da:	7686                	ld	a3,96(sp)
    800060dc:	7726                	ld	a4,104(sp)
    800060de:	77c6                	ld	a5,112(sp)
    800060e0:	7866                	ld	a6,120(sp)
    800060e2:	688a                	ld	a7,128(sp)
    800060e4:	692a                	ld	s2,136(sp)
    800060e6:	69ca                	ld	s3,144(sp)
    800060e8:	6a6a                	ld	s4,152(sp)
    800060ea:	7a8a                	ld	s5,160(sp)
    800060ec:	7b2a                	ld	s6,168(sp)
    800060ee:	7bca                	ld	s7,176(sp)
    800060f0:	7c6a                	ld	s8,184(sp)
    800060f2:	6c8e                	ld	s9,192(sp)
    800060f4:	6d2e                	ld	s10,200(sp)
    800060f6:	6dce                	ld	s11,208(sp)
    800060f8:	6e6e                	ld	t3,216(sp)
    800060fa:	7e8e                	ld	t4,224(sp)
    800060fc:	7f2e                	ld	t5,232(sp)
    800060fe:	7fce                	ld	t6,240(sp)
    80006100:	6111                	addi	sp,sp,256
    80006102:	10200073          	sret
    80006106:	00000013          	nop
    8000610a:	00000013          	nop
    8000610e:	0001                	nop

0000000080006110 <timervec>:
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	e10c                	sd	a1,0(a0)
    80006116:	e510                	sd	a2,8(a0)
    80006118:	e914                	sd	a3,16(a0)
    8000611a:	6d0c                	ld	a1,24(a0)
    8000611c:	7110                	ld	a2,32(a0)
    8000611e:	6194                	ld	a3,0(a1)
    80006120:	96b2                	add	a3,a3,a2
    80006122:	e194                	sd	a3,0(a1)
    80006124:	4589                	li	a1,2
    80006126:	14459073          	csrw	sip,a1
    8000612a:	6914                	ld	a3,16(a0)
    8000612c:	6510                	ld	a2,8(a0)
    8000612e:	610c                	ld	a1,0(a0)
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	30200073          	mret
	...

000000008000613a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000613a:	1141                	addi	sp,sp,-16
    8000613c:	e422                	sd	s0,8(sp)
    8000613e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006140:	0c0007b7          	lui	a5,0xc000
    80006144:	4705                	li	a4,1
    80006146:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006148:	c3d8                	sw	a4,4(a5)
}
    8000614a:	6422                	ld	s0,8(sp)
    8000614c:	0141                	addi	sp,sp,16
    8000614e:	8082                	ret

0000000080006150 <plicinithart>:

void
plicinithart(void)
{
    80006150:	1141                	addi	sp,sp,-16
    80006152:	e406                	sd	ra,8(sp)
    80006154:	e022                	sd	s0,0(sp)
    80006156:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	bb8080e7          	jalr	-1096(ra) # 80001d10 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006160:	0085171b          	slliw	a4,a0,0x8
    80006164:	0c0027b7          	lui	a5,0xc002
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	40200713          	li	a4,1026
    8000616e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006172:	00d5151b          	slliw	a0,a0,0xd
    80006176:	0c2017b7          	lui	a5,0xc201
    8000617a:	953e                	add	a0,a0,a5
    8000617c:	00052023          	sw	zero,0(a0)
}
    80006180:	60a2                	ld	ra,8(sp)
    80006182:	6402                	ld	s0,0(sp)
    80006184:	0141                	addi	sp,sp,16
    80006186:	8082                	ret

0000000080006188 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006188:	1141                	addi	sp,sp,-16
    8000618a:	e406                	sd	ra,8(sp)
    8000618c:	e022                	sd	s0,0(sp)
    8000618e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006190:	ffffc097          	auipc	ra,0xffffc
    80006194:	b80080e7          	jalr	-1152(ra) # 80001d10 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006198:	00d5179b          	slliw	a5,a0,0xd
    8000619c:	0c201537          	lui	a0,0xc201
    800061a0:	953e                	add	a0,a0,a5
  return irq;
}
    800061a2:	4148                	lw	a0,4(a0)
    800061a4:	60a2                	ld	ra,8(sp)
    800061a6:	6402                	ld	s0,0(sp)
    800061a8:	0141                	addi	sp,sp,16
    800061aa:	8082                	ret

00000000800061ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ac:	1101                	addi	sp,sp,-32
    800061ae:	ec06                	sd	ra,24(sp)
    800061b0:	e822                	sd	s0,16(sp)
    800061b2:	e426                	sd	s1,8(sp)
    800061b4:	1000                	addi	s0,sp,32
    800061b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061b8:	ffffc097          	auipc	ra,0xffffc
    800061bc:	b58080e7          	jalr	-1192(ra) # 80001d10 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061c0:	00d5151b          	slliw	a0,a0,0xd
    800061c4:	0c2017b7          	lui	a5,0xc201
    800061c8:	97aa                	add	a5,a5,a0
    800061ca:	c3c4                	sw	s1,4(a5)
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret

00000000800061d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061d6:	1141                	addi	sp,sp,-16
    800061d8:	e406                	sd	ra,8(sp)
    800061da:	e022                	sd	s0,0(sp)
    800061dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061de:	479d                	li	a5,7
    800061e0:	06a7c963          	blt	a5,a0,80006252 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061e4:	0003a797          	auipc	a5,0x3a
    800061e8:	e1c78793          	addi	a5,a5,-484 # 80040000 <disk>
    800061ec:	00a78733          	add	a4,a5,a0
    800061f0:	6789                	lui	a5,0x2
    800061f2:	97ba                	add	a5,a5,a4
    800061f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061f8:	e7ad                	bnez	a5,80006262 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061fa:	00451793          	slli	a5,a0,0x4
    800061fe:	0003c717          	auipc	a4,0x3c
    80006202:	e0270713          	addi	a4,a4,-510 # 80042000 <disk+0x2000>
    80006206:	6314                	ld	a3,0(a4)
    80006208:	96be                	add	a3,a3,a5
    8000620a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000620e:	6314                	ld	a3,0(a4)
    80006210:	96be                	add	a3,a3,a5
    80006212:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006216:	6314                	ld	a3,0(a4)
    80006218:	96be                	add	a3,a3,a5
    8000621a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000621e:	6318                	ld	a4,0(a4)
    80006220:	97ba                	add	a5,a5,a4
    80006222:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006226:	0003a797          	auipc	a5,0x3a
    8000622a:	dda78793          	addi	a5,a5,-550 # 80040000 <disk>
    8000622e:	97aa                	add	a5,a5,a0
    80006230:	6509                	lui	a0,0x2
    80006232:	953e                	add	a0,a0,a5
    80006234:	4785                	li	a5,1
    80006236:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000623a:	0003c517          	auipc	a0,0x3c
    8000623e:	dde50513          	addi	a0,a0,-546 # 80042018 <disk+0x2018>
    80006242:	ffffc097          	auipc	ra,0xffffc
    80006246:	490080e7          	jalr	1168(ra) # 800026d2 <wakeup>
}
    8000624a:	60a2                	ld	ra,8(sp)
    8000624c:	6402                	ld	s0,0(sp)
    8000624e:	0141                	addi	sp,sp,16
    80006250:	8082                	ret
    panic("free_desc 1");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	58e50513          	addi	a0,a0,1422 # 800087e0 <syscalls+0x328>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2f6080e7          	jalr	758(ra) # 80000550 <panic>
    panic("free_desc 2");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	58e50513          	addi	a0,a0,1422 # 800087f0 <syscalls+0x338>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2e6080e7          	jalr	742(ra) # 80000550 <panic>

0000000080006272 <virtio_disk_init>:
{
    80006272:	1101                	addi	sp,sp,-32
    80006274:	ec06                	sd	ra,24(sp)
    80006276:	e822                	sd	s0,16(sp)
    80006278:	e426                	sd	s1,8(sp)
    8000627a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000627c:	00002597          	auipc	a1,0x2
    80006280:	58458593          	addi	a1,a1,1412 # 80008800 <syscalls+0x348>
    80006284:	0003c517          	auipc	a0,0x3c
    80006288:	ea450513          	addi	a0,a0,-348 # 80042128 <disk+0x2128>
    8000628c:	ffffb097          	auipc	ra,0xffffb
    80006290:	be4080e7          	jalr	-1052(ra) # 80000e70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006294:	100017b7          	lui	a5,0x10001
    80006298:	4398                	lw	a4,0(a5)
    8000629a:	2701                	sext.w	a4,a4
    8000629c:	747277b7          	lui	a5,0x74727
    800062a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062a4:	0ef71163          	bne	a4,a5,80006386 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062a8:	100017b7          	lui	a5,0x10001
    800062ac:	43dc                	lw	a5,4(a5)
    800062ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062b0:	4705                	li	a4,1
    800062b2:	0ce79a63          	bne	a5,a4,80006386 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062b6:	100017b7          	lui	a5,0x10001
    800062ba:	479c                	lw	a5,8(a5)
    800062bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062be:	4709                	li	a4,2
    800062c0:	0ce79363          	bne	a5,a4,80006386 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062c4:	100017b7          	lui	a5,0x10001
    800062c8:	47d8                	lw	a4,12(a5)
    800062ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062cc:	554d47b7          	lui	a5,0x554d4
    800062d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062d4:	0af71963          	bne	a4,a5,80006386 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	4705                	li	a4,1
    800062de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062e0:	470d                	li	a4,3
    800062e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062e6:	c7ffe737          	lui	a4,0xc7ffe
    800062ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fba737>
    800062ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062f0:	2701                	sext.w	a4,a4
    800062f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f4:	472d                	li	a4,11
    800062f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f8:	473d                	li	a4,15
    800062fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062fc:	6705                	lui	a4,0x1
    800062fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006300:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006304:	5bdc                	lw	a5,52(a5)
    80006306:	2781                	sext.w	a5,a5
  if(max == 0)
    80006308:	c7d9                	beqz	a5,80006396 <virtio_disk_init+0x124>
  if(max < NUM)
    8000630a:	471d                	li	a4,7
    8000630c:	08f77d63          	bgeu	a4,a5,800063a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006310:	100014b7          	lui	s1,0x10001
    80006314:	47a1                	li	a5,8
    80006316:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006318:	6609                	lui	a2,0x2
    8000631a:	4581                	li	a1,0
    8000631c:	0003a517          	auipc	a0,0x3a
    80006320:	ce450513          	addi	a0,a0,-796 # 80040000 <disk>
    80006324:	ffffb097          	auipc	ra,0xffffb
    80006328:	db0080e7          	jalr	-592(ra) # 800010d4 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000632c:	0003a717          	auipc	a4,0x3a
    80006330:	cd470713          	addi	a4,a4,-812 # 80040000 <disk>
    80006334:	00c75793          	srli	a5,a4,0xc
    80006338:	2781                	sext.w	a5,a5
    8000633a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000633c:	0003c797          	auipc	a5,0x3c
    80006340:	cc478793          	addi	a5,a5,-828 # 80042000 <disk+0x2000>
    80006344:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006346:	0003a717          	auipc	a4,0x3a
    8000634a:	d3a70713          	addi	a4,a4,-710 # 80040080 <disk+0x80>
    8000634e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006350:	0003b717          	auipc	a4,0x3b
    80006354:	cb070713          	addi	a4,a4,-848 # 80041000 <disk+0x1000>
    80006358:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000635a:	4705                	li	a4,1
    8000635c:	00e78c23          	sb	a4,24(a5)
    80006360:	00e78ca3          	sb	a4,25(a5)
    80006364:	00e78d23          	sb	a4,26(a5)
    80006368:	00e78da3          	sb	a4,27(a5)
    8000636c:	00e78e23          	sb	a4,28(a5)
    80006370:	00e78ea3          	sb	a4,29(a5)
    80006374:	00e78f23          	sb	a4,30(a5)
    80006378:	00e78fa3          	sb	a4,31(a5)
}
    8000637c:	60e2                	ld	ra,24(sp)
    8000637e:	6442                	ld	s0,16(sp)
    80006380:	64a2                	ld	s1,8(sp)
    80006382:	6105                	addi	sp,sp,32
    80006384:	8082                	ret
    panic("could not find virtio disk");
    80006386:	00002517          	auipc	a0,0x2
    8000638a:	48a50513          	addi	a0,a0,1162 # 80008810 <syscalls+0x358>
    8000638e:	ffffa097          	auipc	ra,0xffffa
    80006392:	1c2080e7          	jalr	450(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    80006396:	00002517          	auipc	a0,0x2
    8000639a:	49a50513          	addi	a0,a0,1178 # 80008830 <syscalls+0x378>
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	1b2080e7          	jalr	434(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	4aa50513          	addi	a0,a0,1194 # 80008850 <syscalls+0x398>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	1a2080e7          	jalr	418(ra) # 80000550 <panic>

00000000800063b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063b6:	7159                	addi	sp,sp,-112
    800063b8:	f486                	sd	ra,104(sp)
    800063ba:	f0a2                	sd	s0,96(sp)
    800063bc:	eca6                	sd	s1,88(sp)
    800063be:	e8ca                	sd	s2,80(sp)
    800063c0:	e4ce                	sd	s3,72(sp)
    800063c2:	e0d2                	sd	s4,64(sp)
    800063c4:	fc56                	sd	s5,56(sp)
    800063c6:	f85a                	sd	s6,48(sp)
    800063c8:	f45e                	sd	s7,40(sp)
    800063ca:	f062                	sd	s8,32(sp)
    800063cc:	ec66                	sd	s9,24(sp)
    800063ce:	e86a                	sd	s10,16(sp)
    800063d0:	1880                	addi	s0,sp,112
    800063d2:	892a                	mv	s2,a0
    800063d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063d6:	00c52c83          	lw	s9,12(a0)
    800063da:	001c9c9b          	slliw	s9,s9,0x1
    800063de:	1c82                	slli	s9,s9,0x20
    800063e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063e4:	0003c517          	auipc	a0,0x3c
    800063e8:	d4450513          	addi	a0,a0,-700 # 80042128 <disk+0x2128>
    800063ec:	ffffb097          	auipc	ra,0xffffb
    800063f0:	908080e7          	jalr	-1784(ra) # 80000cf4 <acquire>
  for(int i = 0; i < 3; i++){
    800063f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063f8:	0003ab97          	auipc	s7,0x3a
    800063fc:	c08b8b93          	addi	s7,s7,-1016 # 80040000 <disk>
    80006400:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006402:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006404:	8a4e                	mv	s4,s3
    80006406:	a051                	j	8000648a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006408:	00fb86b3          	add	a3,s7,a5
    8000640c:	96da                	add	a3,a3,s6
    8000640e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006412:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006414:	0207c563          	bltz	a5,8000643e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006418:	2485                	addiw	s1,s1,1
    8000641a:	0711                	addi	a4,a4,4
    8000641c:	25548063          	beq	s1,s5,8000665c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006420:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006422:	0003c697          	auipc	a3,0x3c
    80006426:	bf668693          	addi	a3,a3,-1034 # 80042018 <disk+0x2018>
    8000642a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000642c:	0006c583          	lbu	a1,0(a3)
    80006430:	fde1                	bnez	a1,80006408 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006432:	2785                	addiw	a5,a5,1
    80006434:	0685                	addi	a3,a3,1
    80006436:	ff879be3          	bne	a5,s8,8000642c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000643a:	57fd                	li	a5,-1
    8000643c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000643e:	02905a63          	blez	s1,80006472 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006442:	f9042503          	lw	a0,-112(s0)
    80006446:	00000097          	auipc	ra,0x0
    8000644a:	d90080e7          	jalr	-624(ra) # 800061d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000644e:	4785                	li	a5,1
    80006450:	0297d163          	bge	a5,s1,80006472 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006454:	f9442503          	lw	a0,-108(s0)
    80006458:	00000097          	auipc	ra,0x0
    8000645c:	d7e080e7          	jalr	-642(ra) # 800061d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006460:	4789                	li	a5,2
    80006462:	0097d863          	bge	a5,s1,80006472 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006466:	f9842503          	lw	a0,-104(s0)
    8000646a:	00000097          	auipc	ra,0x0
    8000646e:	d6c080e7          	jalr	-660(ra) # 800061d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006472:	0003c597          	auipc	a1,0x3c
    80006476:	cb658593          	addi	a1,a1,-842 # 80042128 <disk+0x2128>
    8000647a:	0003c517          	auipc	a0,0x3c
    8000647e:	b9e50513          	addi	a0,a0,-1122 # 80042018 <disk+0x2018>
    80006482:	ffffc097          	auipc	ra,0xffffc
    80006486:	0ca080e7          	jalr	202(ra) # 8000254c <sleep>
  for(int i = 0; i < 3; i++){
    8000648a:	f9040713          	addi	a4,s0,-112
    8000648e:	84ce                	mv	s1,s3
    80006490:	bf41                	j	80006420 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006492:	20058713          	addi	a4,a1,512
    80006496:	00471693          	slli	a3,a4,0x4
    8000649a:	0003a717          	auipc	a4,0x3a
    8000649e:	b6670713          	addi	a4,a4,-1178 # 80040000 <disk>
    800064a2:	9736                	add	a4,a4,a3
    800064a4:	4685                	li	a3,1
    800064a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064aa:	20058713          	addi	a4,a1,512
    800064ae:	00471693          	slli	a3,a4,0x4
    800064b2:	0003a717          	auipc	a4,0x3a
    800064b6:	b4e70713          	addi	a4,a4,-1202 # 80040000 <disk>
    800064ba:	9736                	add	a4,a4,a3
    800064bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064c4:	7679                	lui	a2,0xffffe
    800064c6:	963e                	add	a2,a2,a5
    800064c8:	0003c697          	auipc	a3,0x3c
    800064cc:	b3868693          	addi	a3,a3,-1224 # 80042000 <disk+0x2000>
    800064d0:	6298                	ld	a4,0(a3)
    800064d2:	9732                	add	a4,a4,a2
    800064d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064d6:	6298                	ld	a4,0(a3)
    800064d8:	9732                	add	a4,a4,a2
    800064da:	4541                	li	a0,16
    800064dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064de:	6298                	ld	a4,0(a3)
    800064e0:	9732                	add	a4,a4,a2
    800064e2:	4505                	li	a0,1
    800064e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064e8:	f9442703          	lw	a4,-108(s0)
    800064ec:	6288                	ld	a0,0(a3)
    800064ee:	962a                	add	a2,a2,a0
    800064f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffb9fe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064f4:	0712                	slli	a4,a4,0x4
    800064f6:	6290                	ld	a2,0(a3)
    800064f8:	963a                	add	a2,a2,a4
    800064fa:	05890513          	addi	a0,s2,88
    800064fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006500:	6294                	ld	a3,0(a3)
    80006502:	96ba                	add	a3,a3,a4
    80006504:	40000613          	li	a2,1024
    80006508:	c690                	sw	a2,8(a3)
  if(write)
    8000650a:	140d0063          	beqz	s10,8000664a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000650e:	0003c697          	auipc	a3,0x3c
    80006512:	af26b683          	ld	a3,-1294(a3) # 80042000 <disk+0x2000>
    80006516:	96ba                	add	a3,a3,a4
    80006518:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000651c:	0003a817          	auipc	a6,0x3a
    80006520:	ae480813          	addi	a6,a6,-1308 # 80040000 <disk>
    80006524:	0003c517          	auipc	a0,0x3c
    80006528:	adc50513          	addi	a0,a0,-1316 # 80042000 <disk+0x2000>
    8000652c:	6114                	ld	a3,0(a0)
    8000652e:	96ba                	add	a3,a3,a4
    80006530:	00c6d603          	lhu	a2,12(a3)
    80006534:	00166613          	ori	a2,a2,1
    80006538:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000653c:	f9842683          	lw	a3,-104(s0)
    80006540:	6110                	ld	a2,0(a0)
    80006542:	9732                	add	a4,a4,a2
    80006544:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006548:	20058613          	addi	a2,a1,512
    8000654c:	0612                	slli	a2,a2,0x4
    8000654e:	9642                	add	a2,a2,a6
    80006550:	577d                	li	a4,-1
    80006552:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006556:	00469713          	slli	a4,a3,0x4
    8000655a:	6114                	ld	a3,0(a0)
    8000655c:	96ba                	add	a3,a3,a4
    8000655e:	03078793          	addi	a5,a5,48
    80006562:	97c2                	add	a5,a5,a6
    80006564:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006566:	611c                	ld	a5,0(a0)
    80006568:	97ba                	add	a5,a5,a4
    8000656a:	4685                	li	a3,1
    8000656c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000656e:	611c                	ld	a5,0(a0)
    80006570:	97ba                	add	a5,a5,a4
    80006572:	4809                	li	a6,2
    80006574:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006578:	611c                	ld	a5,0(a0)
    8000657a:	973e                	add	a4,a4,a5
    8000657c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006580:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006584:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006588:	6518                	ld	a4,8(a0)
    8000658a:	00275783          	lhu	a5,2(a4)
    8000658e:	8b9d                	andi	a5,a5,7
    80006590:	0786                	slli	a5,a5,0x1
    80006592:	97ba                	add	a5,a5,a4
    80006594:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006598:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000659c:	6518                	ld	a4,8(a0)
    8000659e:	00275783          	lhu	a5,2(a4)
    800065a2:	2785                	addiw	a5,a5,1
    800065a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065ac:	100017b7          	lui	a5,0x10001
    800065b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065b4:	00492703          	lw	a4,4(s2)
    800065b8:	4785                	li	a5,1
    800065ba:	02f71163          	bne	a4,a5,800065dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065be:	0003c997          	auipc	s3,0x3c
    800065c2:	b6a98993          	addi	s3,s3,-1174 # 80042128 <disk+0x2128>
  while(b->disk == 1) {
    800065c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065c8:	85ce                	mv	a1,s3
    800065ca:	854a                	mv	a0,s2
    800065cc:	ffffc097          	auipc	ra,0xffffc
    800065d0:	f80080e7          	jalr	-128(ra) # 8000254c <sleep>
  while(b->disk == 1) {
    800065d4:	00492783          	lw	a5,4(s2)
    800065d8:	fe9788e3          	beq	a5,s1,800065c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065dc:	f9042903          	lw	s2,-112(s0)
    800065e0:	20090793          	addi	a5,s2,512
    800065e4:	00479713          	slli	a4,a5,0x4
    800065e8:	0003a797          	auipc	a5,0x3a
    800065ec:	a1878793          	addi	a5,a5,-1512 # 80040000 <disk>
    800065f0:	97ba                	add	a5,a5,a4
    800065f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065f6:	0003c997          	auipc	s3,0x3c
    800065fa:	a0a98993          	addi	s3,s3,-1526 # 80042000 <disk+0x2000>
    800065fe:	00491713          	slli	a4,s2,0x4
    80006602:	0009b783          	ld	a5,0(s3)
    80006606:	97ba                	add	a5,a5,a4
    80006608:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000660c:	854a                	mv	a0,s2
    8000660e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006612:	00000097          	auipc	ra,0x0
    80006616:	bc4080e7          	jalr	-1084(ra) # 800061d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000661a:	8885                	andi	s1,s1,1
    8000661c:	f0ed                	bnez	s1,800065fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000661e:	0003c517          	auipc	a0,0x3c
    80006622:	b0a50513          	addi	a0,a0,-1270 # 80042128 <disk+0x2128>
    80006626:	ffffa097          	auipc	ra,0xffffa
    8000662a:	79e080e7          	jalr	1950(ra) # 80000dc4 <release>
}
    8000662e:	70a6                	ld	ra,104(sp)
    80006630:	7406                	ld	s0,96(sp)
    80006632:	64e6                	ld	s1,88(sp)
    80006634:	6946                	ld	s2,80(sp)
    80006636:	69a6                	ld	s3,72(sp)
    80006638:	6a06                	ld	s4,64(sp)
    8000663a:	7ae2                	ld	s5,56(sp)
    8000663c:	7b42                	ld	s6,48(sp)
    8000663e:	7ba2                	ld	s7,40(sp)
    80006640:	7c02                	ld	s8,32(sp)
    80006642:	6ce2                	ld	s9,24(sp)
    80006644:	6d42                	ld	s10,16(sp)
    80006646:	6165                	addi	sp,sp,112
    80006648:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000664a:	0003c697          	auipc	a3,0x3c
    8000664e:	9b66b683          	ld	a3,-1610(a3) # 80042000 <disk+0x2000>
    80006652:	96ba                	add	a3,a3,a4
    80006654:	4609                	li	a2,2
    80006656:	00c69623          	sh	a2,12(a3)
    8000665a:	b5c9                	j	8000651c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000665c:	f9042583          	lw	a1,-112(s0)
    80006660:	20058793          	addi	a5,a1,512
    80006664:	0792                	slli	a5,a5,0x4
    80006666:	0003a517          	auipc	a0,0x3a
    8000666a:	a4250513          	addi	a0,a0,-1470 # 800400a8 <disk+0xa8>
    8000666e:	953e                	add	a0,a0,a5
  if(write)
    80006670:	e20d11e3          	bnez	s10,80006492 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006674:	20058713          	addi	a4,a1,512
    80006678:	00471693          	slli	a3,a4,0x4
    8000667c:	0003a717          	auipc	a4,0x3a
    80006680:	98470713          	addi	a4,a4,-1660 # 80040000 <disk>
    80006684:	9736                	add	a4,a4,a3
    80006686:	0a072423          	sw	zero,168(a4)
    8000668a:	b505                	j	800064aa <virtio_disk_rw+0xf4>

000000008000668c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000668c:	1101                	addi	sp,sp,-32
    8000668e:	ec06                	sd	ra,24(sp)
    80006690:	e822                	sd	s0,16(sp)
    80006692:	e426                	sd	s1,8(sp)
    80006694:	e04a                	sd	s2,0(sp)
    80006696:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006698:	0003c517          	auipc	a0,0x3c
    8000669c:	a9050513          	addi	a0,a0,-1392 # 80042128 <disk+0x2128>
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	654080e7          	jalr	1620(ra) # 80000cf4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066a8:	10001737          	lui	a4,0x10001
    800066ac:	533c                	lw	a5,96(a4)
    800066ae:	8b8d                	andi	a5,a5,3
    800066b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066b6:	0003c797          	auipc	a5,0x3c
    800066ba:	94a78793          	addi	a5,a5,-1718 # 80042000 <disk+0x2000>
    800066be:	6b94                	ld	a3,16(a5)
    800066c0:	0207d703          	lhu	a4,32(a5)
    800066c4:	0026d783          	lhu	a5,2(a3)
    800066c8:	06f70163          	beq	a4,a5,8000672a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066cc:	0003a917          	auipc	s2,0x3a
    800066d0:	93490913          	addi	s2,s2,-1740 # 80040000 <disk>
    800066d4:	0003c497          	auipc	s1,0x3c
    800066d8:	92c48493          	addi	s1,s1,-1748 # 80042000 <disk+0x2000>
    __sync_synchronize();
    800066dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066e0:	6898                	ld	a4,16(s1)
    800066e2:	0204d783          	lhu	a5,32(s1)
    800066e6:	8b9d                	andi	a5,a5,7
    800066e8:	078e                	slli	a5,a5,0x3
    800066ea:	97ba                	add	a5,a5,a4
    800066ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066ee:	20078713          	addi	a4,a5,512
    800066f2:	0712                	slli	a4,a4,0x4
    800066f4:	974a                	add	a4,a4,s2
    800066f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066fa:	e731                	bnez	a4,80006746 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066fc:	20078793          	addi	a5,a5,512
    80006700:	0792                	slli	a5,a5,0x4
    80006702:	97ca                	add	a5,a5,s2
    80006704:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006706:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000670a:	ffffc097          	auipc	ra,0xffffc
    8000670e:	fc8080e7          	jalr	-56(ra) # 800026d2 <wakeup>

    disk.used_idx += 1;
    80006712:	0204d783          	lhu	a5,32(s1)
    80006716:	2785                	addiw	a5,a5,1
    80006718:	17c2                	slli	a5,a5,0x30
    8000671a:	93c1                	srli	a5,a5,0x30
    8000671c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006720:	6898                	ld	a4,16(s1)
    80006722:	00275703          	lhu	a4,2(a4)
    80006726:	faf71be3          	bne	a4,a5,800066dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000672a:	0003c517          	auipc	a0,0x3c
    8000672e:	9fe50513          	addi	a0,a0,-1538 # 80042128 <disk+0x2128>
    80006732:	ffffa097          	auipc	ra,0xffffa
    80006736:	692080e7          	jalr	1682(ra) # 80000dc4 <release>
}
    8000673a:	60e2                	ld	ra,24(sp)
    8000673c:	6442                	ld	s0,16(sp)
    8000673e:	64a2                	ld	s1,8(sp)
    80006740:	6902                	ld	s2,0(sp)
    80006742:	6105                	addi	sp,sp,32
    80006744:	8082                	ret
      panic("virtio_disk_intr status");
    80006746:	00002517          	auipc	a0,0x2
    8000674a:	12a50513          	addi	a0,a0,298 # 80008870 <syscalls+0x3b8>
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	e02080e7          	jalr	-510(ra) # 80000550 <panic>

0000000080006756 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006756:	1141                	addi	sp,sp,-16
    80006758:	e422                	sd	s0,8(sp)
    8000675a:	0800                	addi	s0,sp,16
  return -1;
}
    8000675c:	557d                	li	a0,-1
    8000675e:	6422                	ld	s0,8(sp)
    80006760:	0141                	addi	sp,sp,16
    80006762:	8082                	ret

0000000080006764 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006764:	7179                	addi	sp,sp,-48
    80006766:	f406                	sd	ra,40(sp)
    80006768:	f022                	sd	s0,32(sp)
    8000676a:	ec26                	sd	s1,24(sp)
    8000676c:	e84a                	sd	s2,16(sp)
    8000676e:	e44e                	sd	s3,8(sp)
    80006770:	e052                	sd	s4,0(sp)
    80006772:	1800                	addi	s0,sp,48
    80006774:	892a                	mv	s2,a0
    80006776:	89ae                	mv	s3,a1
    80006778:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000677a:	0003d517          	auipc	a0,0x3d
    8000677e:	88650513          	addi	a0,a0,-1914 # 80043000 <stats>
    80006782:	ffffa097          	auipc	ra,0xffffa
    80006786:	572080e7          	jalr	1394(ra) # 80000cf4 <acquire>

  if(stats.sz == 0) {
    8000678a:	0003e797          	auipc	a5,0x3e
    8000678e:	8967a783          	lw	a5,-1898(a5) # 80044020 <stats+0x1020>
    80006792:	cbb5                	beqz	a5,80006806 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006794:	0003e797          	auipc	a5,0x3e
    80006798:	86c78793          	addi	a5,a5,-1940 # 80044000 <stats+0x1000>
    8000679c:	53d8                	lw	a4,36(a5)
    8000679e:	539c                	lw	a5,32(a5)
    800067a0:	9f99                	subw	a5,a5,a4
    800067a2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800067a6:	06d05e63          	blez	a3,80006822 <statsread+0xbe>
    if(m > n)
    800067aa:	8a3e                	mv	s4,a5
    800067ac:	00d4d363          	bge	s1,a3,800067b2 <statsread+0x4e>
    800067b0:	8a26                	mv	s4,s1
    800067b2:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800067b6:	86a6                	mv	a3,s1
    800067b8:	0003d617          	auipc	a2,0x3d
    800067bc:	86860613          	addi	a2,a2,-1944 # 80043020 <stats+0x20>
    800067c0:	963a                	add	a2,a2,a4
    800067c2:	85ce                	mv	a1,s3
    800067c4:	854a                	mv	a0,s2
    800067c6:	ffffc097          	auipc	ra,0xffffc
    800067ca:	fe8080e7          	jalr	-24(ra) # 800027ae <either_copyout>
    800067ce:	57fd                	li	a5,-1
    800067d0:	00f50a63          	beq	a0,a5,800067e4 <statsread+0x80>
      stats.off += m;
    800067d4:	0003e717          	auipc	a4,0x3e
    800067d8:	82c70713          	addi	a4,a4,-2004 # 80044000 <stats+0x1000>
    800067dc:	535c                	lw	a5,36(a4)
    800067de:	014787bb          	addw	a5,a5,s4
    800067e2:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800067e4:	0003d517          	auipc	a0,0x3d
    800067e8:	81c50513          	addi	a0,a0,-2020 # 80043000 <stats>
    800067ec:	ffffa097          	auipc	ra,0xffffa
    800067f0:	5d8080e7          	jalr	1496(ra) # 80000dc4 <release>
  return m;
}
    800067f4:	8526                	mv	a0,s1
    800067f6:	70a2                	ld	ra,40(sp)
    800067f8:	7402                	ld	s0,32(sp)
    800067fa:	64e2                	ld	s1,24(sp)
    800067fc:	6942                	ld	s2,16(sp)
    800067fe:	69a2                	ld	s3,8(sp)
    80006800:	6a02                	ld	s4,0(sp)
    80006802:	6145                	addi	sp,sp,48
    80006804:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006806:	6585                	lui	a1,0x1
    80006808:	0003d517          	auipc	a0,0x3d
    8000680c:	81850513          	addi	a0,a0,-2024 # 80043020 <stats+0x20>
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	70e080e7          	jalr	1806(ra) # 80000f1e <statslock>
    80006818:	0003e797          	auipc	a5,0x3e
    8000681c:	80a7a423          	sw	a0,-2040(a5) # 80044020 <stats+0x1020>
    80006820:	bf95                	j	80006794 <statsread+0x30>
    stats.sz = 0;
    80006822:	0003d797          	auipc	a5,0x3d
    80006826:	7de78793          	addi	a5,a5,2014 # 80044000 <stats+0x1000>
    8000682a:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000682e:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006832:	54fd                	li	s1,-1
    80006834:	bf45                	j	800067e4 <statsread+0x80>

0000000080006836 <statsinit>:

void
statsinit(void)
{
    80006836:	1141                	addi	sp,sp,-16
    80006838:	e406                	sd	ra,8(sp)
    8000683a:	e022                	sd	s0,0(sp)
    8000683c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000683e:	00002597          	auipc	a1,0x2
    80006842:	04a58593          	addi	a1,a1,74 # 80008888 <syscalls+0x3d0>
    80006846:	0003c517          	auipc	a0,0x3c
    8000684a:	7ba50513          	addi	a0,a0,1978 # 80043000 <stats>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	622080e7          	jalr	1570(ra) # 80000e70 <initlock>

  devsw[STATS].read = statsread;
    80006856:	00038797          	auipc	a5,0x38
    8000685a:	00278793          	addi	a5,a5,2 # 8003e858 <devsw>
    8000685e:	00000717          	auipc	a4,0x0
    80006862:	f0670713          	addi	a4,a4,-250 # 80006764 <statsread>
    80006866:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006868:	00000717          	auipc	a4,0x0
    8000686c:	eee70713          	addi	a4,a4,-274 # 80006756 <statswrite>
    80006870:	f798                	sd	a4,40(a5)
}
    80006872:	60a2                	ld	ra,8(sp)
    80006874:	6402                	ld	s0,0(sp)
    80006876:	0141                	addi	sp,sp,16
    80006878:	8082                	ret

000000008000687a <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000687a:	1101                	addi	sp,sp,-32
    8000687c:	ec22                	sd	s0,24(sp)
    8000687e:	1000                	addi	s0,sp,32
    80006880:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006882:	c299                	beqz	a3,80006888 <sprintint+0xe>
    80006884:	0805c163          	bltz	a1,80006906 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006888:	2581                	sext.w	a1,a1
    8000688a:	4301                	li	t1,0

  i = 0;
    8000688c:	fe040713          	addi	a4,s0,-32
    80006890:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006892:	2601                	sext.w	a2,a2
    80006894:	00002697          	auipc	a3,0x2
    80006898:	ffc68693          	addi	a3,a3,-4 # 80008890 <digits>
    8000689c:	88aa                	mv	a7,a0
    8000689e:	2505                	addiw	a0,a0,1
    800068a0:	02c5f7bb          	remuw	a5,a1,a2
    800068a4:	1782                	slli	a5,a5,0x20
    800068a6:	9381                	srli	a5,a5,0x20
    800068a8:	97b6                	add	a5,a5,a3
    800068aa:	0007c783          	lbu	a5,0(a5)
    800068ae:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800068b2:	0005879b          	sext.w	a5,a1
    800068b6:	02c5d5bb          	divuw	a1,a1,a2
    800068ba:	0705                	addi	a4,a4,1
    800068bc:	fec7f0e3          	bgeu	a5,a2,8000689c <sprintint+0x22>

  if(sign)
    800068c0:	00030b63          	beqz	t1,800068d6 <sprintint+0x5c>
    buf[i++] = '-';
    800068c4:	ff040793          	addi	a5,s0,-16
    800068c8:	97aa                	add	a5,a5,a0
    800068ca:	02d00713          	li	a4,45
    800068ce:	fee78823          	sb	a4,-16(a5)
    800068d2:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800068d6:	02a05c63          	blez	a0,8000690e <sprintint+0x94>
    800068da:	fe040793          	addi	a5,s0,-32
    800068de:	00a78733          	add	a4,a5,a0
    800068e2:	87c2                	mv	a5,a6
    800068e4:	0805                	addi	a6,a6,1
    800068e6:	fff5061b          	addiw	a2,a0,-1
    800068ea:	1602                	slli	a2,a2,0x20
    800068ec:	9201                	srli	a2,a2,0x20
    800068ee:	9642                	add	a2,a2,a6
  *s = c;
    800068f0:	fff74683          	lbu	a3,-1(a4)
    800068f4:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800068f8:	177d                	addi	a4,a4,-1
    800068fa:	0785                	addi	a5,a5,1
    800068fc:	fec79ae3          	bne	a5,a2,800068f0 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006900:	6462                	ld	s0,24(sp)
    80006902:	6105                	addi	sp,sp,32
    80006904:	8082                	ret
    x = -xx;
    80006906:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    8000690a:	4305                	li	t1,1
    x = -xx;
    8000690c:	b741                	j	8000688c <sprintint+0x12>
  while(--i >= 0)
    8000690e:	4501                	li	a0,0
    80006910:	bfc5                	j	80006900 <sprintint+0x86>

0000000080006912 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006912:	7171                	addi	sp,sp,-176
    80006914:	fc86                	sd	ra,120(sp)
    80006916:	f8a2                	sd	s0,112(sp)
    80006918:	f4a6                	sd	s1,104(sp)
    8000691a:	f0ca                	sd	s2,96(sp)
    8000691c:	ecce                	sd	s3,88(sp)
    8000691e:	e8d2                	sd	s4,80(sp)
    80006920:	e4d6                	sd	s5,72(sp)
    80006922:	e0da                	sd	s6,64(sp)
    80006924:	fc5e                	sd	s7,56(sp)
    80006926:	f862                	sd	s8,48(sp)
    80006928:	f466                	sd	s9,40(sp)
    8000692a:	f06a                	sd	s10,32(sp)
    8000692c:	ec6e                	sd	s11,24(sp)
    8000692e:	0100                	addi	s0,sp,128
    80006930:	e414                	sd	a3,8(s0)
    80006932:	e818                	sd	a4,16(s0)
    80006934:	ec1c                	sd	a5,24(s0)
    80006936:	03043023          	sd	a6,32(s0)
    8000693a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000693e:	ca0d                	beqz	a2,80006970 <snprintf+0x5e>
    80006940:	8baa                	mv	s7,a0
    80006942:	89ae                	mv	s3,a1
    80006944:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006946:	00840793          	addi	a5,s0,8
    8000694a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000694e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006950:	4901                	li	s2,0
    80006952:	02b05763          	blez	a1,80006980 <snprintf+0x6e>
    if(c != '%'){
    80006956:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000695a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000695e:	02800d93          	li	s11,40
  *s = c;
    80006962:	02500d13          	li	s10,37
    switch(c){
    80006966:	07800c93          	li	s9,120
    8000696a:	06400c13          	li	s8,100
    8000696e:	a01d                	j	80006994 <snprintf+0x82>
    panic("null fmt");
    80006970:	00001517          	auipc	a0,0x1
    80006974:	6b850513          	addi	a0,a0,1720 # 80008028 <etext+0x28>
    80006978:	ffffa097          	auipc	ra,0xffffa
    8000697c:	bd8080e7          	jalr	-1064(ra) # 80000550 <panic>
  int off = 0;
    80006980:	4481                	li	s1,0
    80006982:	a86d                	j	80006a3c <snprintf+0x12a>
  *s = c;
    80006984:	009b8733          	add	a4,s7,s1
    80006988:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000698c:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000698e:	2905                	addiw	s2,s2,1
    80006990:	0b34d663          	bge	s1,s3,80006a3c <snprintf+0x12a>
    80006994:	012a07b3          	add	a5,s4,s2
    80006998:	0007c783          	lbu	a5,0(a5)
    8000699c:	0007871b          	sext.w	a4,a5
    800069a0:	cfd1                	beqz	a5,80006a3c <snprintf+0x12a>
    if(c != '%'){
    800069a2:	ff5711e3          	bne	a4,s5,80006984 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800069a6:	2905                	addiw	s2,s2,1
    800069a8:	012a07b3          	add	a5,s4,s2
    800069ac:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800069b0:	c7d1                	beqz	a5,80006a3c <snprintf+0x12a>
    switch(c){
    800069b2:	05678c63          	beq	a5,s6,80006a0a <snprintf+0xf8>
    800069b6:	02fb6763          	bltu	s6,a5,800069e4 <snprintf+0xd2>
    800069ba:	0b578763          	beq	a5,s5,80006a68 <snprintf+0x156>
    800069be:	0b879b63          	bne	a5,s8,80006a74 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800069c2:	f8843783          	ld	a5,-120(s0)
    800069c6:	00878713          	addi	a4,a5,8
    800069ca:	f8e43423          	sd	a4,-120(s0)
    800069ce:	4685                	li	a3,1
    800069d0:	4629                	li	a2,10
    800069d2:	438c                	lw	a1,0(a5)
    800069d4:	009b8533          	add	a0,s7,s1
    800069d8:	00000097          	auipc	ra,0x0
    800069dc:	ea2080e7          	jalr	-350(ra) # 8000687a <sprintint>
    800069e0:	9ca9                	addw	s1,s1,a0
      break;
    800069e2:	b775                	j	8000698e <snprintf+0x7c>
    switch(c){
    800069e4:	09979863          	bne	a5,s9,80006a74 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800069e8:	f8843783          	ld	a5,-120(s0)
    800069ec:	00878713          	addi	a4,a5,8
    800069f0:	f8e43423          	sd	a4,-120(s0)
    800069f4:	4685                	li	a3,1
    800069f6:	4641                	li	a2,16
    800069f8:	438c                	lw	a1,0(a5)
    800069fa:	009b8533          	add	a0,s7,s1
    800069fe:	00000097          	auipc	ra,0x0
    80006a02:	e7c080e7          	jalr	-388(ra) # 8000687a <sprintint>
    80006a06:	9ca9                	addw	s1,s1,a0
      break;
    80006a08:	b759                	j	8000698e <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006a0a:	f8843783          	ld	a5,-120(s0)
    80006a0e:	00878713          	addi	a4,a5,8
    80006a12:	f8e43423          	sd	a4,-120(s0)
    80006a16:	639c                	ld	a5,0(a5)
    80006a18:	c3b1                	beqz	a5,80006a5c <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006a1a:	0007c703          	lbu	a4,0(a5)
    80006a1e:	db25                	beqz	a4,8000698e <snprintf+0x7c>
    80006a20:	0134de63          	bge	s1,s3,80006a3c <snprintf+0x12a>
    80006a24:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006a28:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006a2c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006a2e:	0785                	addi	a5,a5,1
    80006a30:	0007c703          	lbu	a4,0(a5)
    80006a34:	df29                	beqz	a4,8000698e <snprintf+0x7c>
    80006a36:	0685                	addi	a3,a3,1
    80006a38:	fe9998e3          	bne	s3,s1,80006a28 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006a3c:	8526                	mv	a0,s1
    80006a3e:	70e6                	ld	ra,120(sp)
    80006a40:	7446                	ld	s0,112(sp)
    80006a42:	74a6                	ld	s1,104(sp)
    80006a44:	7906                	ld	s2,96(sp)
    80006a46:	69e6                	ld	s3,88(sp)
    80006a48:	6a46                	ld	s4,80(sp)
    80006a4a:	6aa6                	ld	s5,72(sp)
    80006a4c:	6b06                	ld	s6,64(sp)
    80006a4e:	7be2                	ld	s7,56(sp)
    80006a50:	7c42                	ld	s8,48(sp)
    80006a52:	7ca2                	ld	s9,40(sp)
    80006a54:	7d02                	ld	s10,32(sp)
    80006a56:	6de2                	ld	s11,24(sp)
    80006a58:	614d                	addi	sp,sp,176
    80006a5a:	8082                	ret
        s = "(null)";
    80006a5c:	00001797          	auipc	a5,0x1
    80006a60:	5c478793          	addi	a5,a5,1476 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006a64:	876e                	mv	a4,s11
    80006a66:	bf6d                	j	80006a20 <snprintf+0x10e>
  *s = c;
    80006a68:	009b87b3          	add	a5,s7,s1
    80006a6c:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006a70:	2485                	addiw	s1,s1,1
      break;
    80006a72:	bf31                	j	8000698e <snprintf+0x7c>
  *s = c;
    80006a74:	009b8733          	add	a4,s7,s1
    80006a78:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006a7c:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006a80:	975e                	add	a4,a4,s7
    80006a82:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006a86:	2489                	addiw	s1,s1,2
      break;
    80006a88:	b719                	j	8000698e <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
