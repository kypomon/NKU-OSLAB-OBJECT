
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 49 11 f0       	mov    $0xf0114970,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 58 1f 00 00       	call   f0101fb5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9f 04 00 00       	call   f0100501 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 24 10 f0       	push   $0xf0102400
f010006f:	e8 71 14 00 00       	call   f01014e5 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d0 0a 00 00       	call   f0100b49 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 96 06 00 00       	call   f010071c <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 49 11 f0 00 	cmpl   $0x0,0xf0114960
f010009a:	74 0f                	je     f01000ab <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009c:	83 ec 0c             	sub    $0xc,%esp
f010009f:	6a 00                	push   $0x0
f01000a1:	e8 76 06 00 00       	call   f010071c <monitor>
f01000a6:	83 c4 10             	add    $0x10,%esp
f01000a9:	eb f1                	jmp    f010009c <_panic+0x11>
	panicstr = fmt;
f01000ab:	89 35 60 49 11 f0    	mov    %esi,0xf0114960
	__asm __volatile("cli; cld");
f01000b1:	fa                   	cli    
f01000b2:	fc                   	cld    
	va_start(ap, fmt);
f01000b3:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b6:	83 ec 04             	sub    $0x4,%esp
f01000b9:	ff 75 0c             	pushl  0xc(%ebp)
f01000bc:	ff 75 08             	pushl  0x8(%ebp)
f01000bf:	68 1b 24 10 f0       	push   $0xf010241b
f01000c4:	e8 1c 14 00 00       	call   f01014e5 <cprintf>
	vcprintf(fmt, ap);
f01000c9:	83 c4 08             	add    $0x8,%esp
f01000cc:	53                   	push   %ebx
f01000cd:	56                   	push   %esi
f01000ce:	e8 ec 13 00 00       	call   f01014bf <vcprintf>
	cprintf("\n");
f01000d3:	c7 04 24 57 24 10 f0 	movl   $0xf0102457,(%esp)
f01000da:	e8 06 14 00 00       	call   f01014e5 <cprintf>
f01000df:	83 c4 10             	add    $0x10,%esp
f01000e2:	eb b8                	jmp    f010009c <_panic+0x11>

f01000e4 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000eb:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ee:	ff 75 0c             	pushl  0xc(%ebp)
f01000f1:	ff 75 08             	pushl  0x8(%ebp)
f01000f4:	68 33 24 10 f0       	push   $0xf0102433
f01000f9:	e8 e7 13 00 00       	call   f01014e5 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	53                   	push   %ebx
f0100102:	ff 75 10             	pushl  0x10(%ebp)
f0100105:	e8 b5 13 00 00       	call   f01014bf <vcprintf>
	cprintf("\n");
f010010a:	c7 04 24 57 24 10 f0 	movl   $0xf0102457,(%esp)
f0100111:	e8 cf 13 00 00       	call   f01014e5 <cprintf>
	va_end(ap);
}
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011c:	c9                   	leave  
f010011d:	c3                   	ret    

f010011e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011e:	55                   	push   %ebp
f010011f:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100121:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100126:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100127:	a8 01                	test   $0x1,%al
f0100129:	74 0b                	je     f0100136 <serial_proc_data+0x18>
f010012b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100130:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100131:	0f b6 c0             	movzbl %al,%eax
}
f0100134:	5d                   	pop    %ebp
f0100135:	c3                   	ret    
		return -1;
f0100136:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010013b:	eb f7                	jmp    f0100134 <serial_proc_data+0x16>

f010013d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 04             	sub    $0x4,%esp
f0100144:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100146:	ff d3                	call   *%ebx
f0100148:	83 f8 ff             	cmp    $0xffffffff,%eax
f010014b:	74 2d                	je     f010017a <cons_intr+0x3d>
		if (c == 0)
f010014d:	85 c0                	test   %eax,%eax
f010014f:	74 f5                	je     f0100146 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100151:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100157:	8d 51 01             	lea    0x1(%ecx),%edx
f010015a:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100160:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100166:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010016c:	75 d8                	jne    f0100146 <cons_intr+0x9>
			cons.wpos = 0;
f010016e:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
f0100175:	00 00 00 
f0100178:	eb cc                	jmp    f0100146 <cons_intr+0x9>
	}
}
f010017a:	83 c4 04             	add    $0x4,%esp
f010017d:	5b                   	pop    %ebx
f010017e:	5d                   	pop    %ebp
f010017f:	c3                   	ret    

f0100180 <kbd_proc_data>:
{
f0100180:	55                   	push   %ebp
f0100181:	89 e5                	mov    %esp,%ebp
f0100183:	53                   	push   %ebx
f0100184:	83 ec 04             	sub    $0x4,%esp
f0100187:	ba 64 00 00 00       	mov    $0x64,%edx
f010018c:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010018d:	a8 01                	test   $0x1,%al
f010018f:	0f 84 f2 00 00 00    	je     f0100287 <kbd_proc_data+0x107>
f0100195:	ba 60 00 00 00       	mov    $0x60,%edx
f010019a:	ec                   	in     (%dx),%al
f010019b:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010019d:	3c e0                	cmp    $0xe0,%al
f010019f:	0f 84 8e 00 00 00    	je     f0100233 <kbd_proc_data+0xb3>
	} else if (data & 0x80) {
f01001a5:	84 c0                	test   %al,%al
f01001a7:	0f 88 99 00 00 00    	js     f0100246 <kbd_proc_data+0xc6>
	} else if (shift & E0ESC) {
f01001ad:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001b3:	f6 c1 40             	test   $0x40,%cl
f01001b6:	74 0e                	je     f01001c6 <kbd_proc_data+0x46>
		data |= 0x80;
f01001b8:	83 c8 80             	or     $0xffffff80,%eax
f01001bb:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001bd:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001c0:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	shift |= shiftcode[data];
f01001c6:	0f b6 d2             	movzbl %dl,%edx
f01001c9:	0f b6 82 a0 25 10 f0 	movzbl -0xfefda60(%edx),%eax
f01001d0:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
	shift ^= togglecode[data];
f01001d6:	0f b6 8a a0 24 10 f0 	movzbl -0xfefdb60(%edx),%ecx
f01001dd:	31 c8                	xor    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
	c = charcode[shift & (CTL | SHIFT)][data];
f01001e4:	89 c1                	mov    %eax,%ecx
f01001e6:	83 e1 03             	and    $0x3,%ecx
f01001e9:	8b 0c 8d 80 24 10 f0 	mov    -0xfefdb80(,%ecx,4),%ecx
f01001f0:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01001f4:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01001f7:	a8 08                	test   $0x8,%al
f01001f9:	74 0d                	je     f0100208 <kbd_proc_data+0x88>
		if ('a' <= c && c <= 'z')
f01001fb:	89 da                	mov    %ebx,%edx
f01001fd:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100200:	83 f9 19             	cmp    $0x19,%ecx
f0100203:	77 74                	ja     f0100279 <kbd_proc_data+0xf9>
			c += 'A' - 'a';
f0100205:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100208:	f7 d0                	not    %eax
f010020a:	a8 06                	test   $0x6,%al
f010020c:	75 31                	jne    f010023f <kbd_proc_data+0xbf>
f010020e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100214:	75 29                	jne    f010023f <kbd_proc_data+0xbf>
		cprintf("Rebooting!\n");
f0100216:	83 ec 0c             	sub    $0xc,%esp
f0100219:	68 4d 24 10 f0       	push   $0xf010244d
f010021e:	e8 c2 12 00 00       	call   f01014e5 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100223:	b8 03 00 00 00       	mov    $0x3,%eax
f0100228:	ba 92 00 00 00       	mov    $0x92,%edx
f010022d:	ee                   	out    %al,(%dx)
f010022e:	83 c4 10             	add    $0x10,%esp
f0100231:	eb 0c                	jmp    f010023f <kbd_proc_data+0xbf>
		shift |= E0ESC;
f0100233:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
		return 0;
f010023a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010023f:	89 d8                	mov    %ebx,%eax
f0100241:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100244:	c9                   	leave  
f0100245:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100246:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f010024c:	89 cb                	mov    %ecx,%ebx
f010024e:	83 e3 40             	and    $0x40,%ebx
f0100251:	83 e0 7f             	and    $0x7f,%eax
f0100254:	85 db                	test   %ebx,%ebx
f0100256:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100259:	0f b6 d2             	movzbl %dl,%edx
f010025c:	0f b6 82 a0 25 10 f0 	movzbl -0xfefda60(%edx),%eax
f0100263:	83 c8 40             	or     $0x40,%eax
f0100266:	0f b6 c0             	movzbl %al,%eax
f0100269:	f7 d0                	not    %eax
f010026b:	21 c8                	and    %ecx,%eax
f010026d:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f0100272:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100277:	eb c6                	jmp    f010023f <kbd_proc_data+0xbf>
		else if ('A' <= c && c <= 'Z')
f0100279:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010027c:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010027f:	83 fa 1a             	cmp    $0x1a,%edx
f0100282:	0f 42 d9             	cmovb  %ecx,%ebx
f0100285:	eb 81                	jmp    f0100208 <kbd_proc_data+0x88>
		return -1;
f0100287:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010028c:	eb b1                	jmp    f010023f <kbd_proc_data+0xbf>

f010028e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010028e:	55                   	push   %ebp
f010028f:	89 e5                	mov    %esp,%ebp
f0100291:	57                   	push   %edi
f0100292:	56                   	push   %esi
f0100293:	53                   	push   %ebx
f0100294:	83 ec 1c             	sub    $0x1c,%esp
f0100297:	89 c7                	mov    %eax,%edi
	for (i = 0;
f0100299:	bb 00 00 00 00       	mov    $0x0,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010029e:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002a3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a8:	eb 09                	jmp    f01002b3 <cons_putc+0x25>
f01002aa:	89 ca                	mov    %ecx,%edx
f01002ac:	ec                   	in     (%dx),%al
f01002ad:	ec                   	in     (%dx),%al
f01002ae:	ec                   	in     (%dx),%al
f01002af:	ec                   	in     (%dx),%al
	     i++)
f01002b0:	83 c3 01             	add    $0x1,%ebx
f01002b3:	89 f2                	mov    %esi,%edx
f01002b5:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b6:	a8 20                	test   $0x20,%al
f01002b8:	75 08                	jne    f01002c2 <cons_putc+0x34>
f01002ba:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c0:	7e e8                	jle    f01002aa <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01002c2:	89 f8                	mov    %edi,%eax
f01002c4:	88 45 e7             	mov    %al,-0x19(%ebp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002cc:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002cd:	bb 00 00 00 00       	mov    $0x0,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d2:	be 79 03 00 00       	mov    $0x379,%esi
f01002d7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002dc:	eb 09                	jmp    f01002e7 <cons_putc+0x59>
f01002de:	89 ca                	mov    %ecx,%edx
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	ec                   	in     (%dx),%al
f01002e2:	ec                   	in     (%dx),%al
f01002e3:	ec                   	in     (%dx),%al
f01002e4:	83 c3 01             	add    $0x1,%ebx
f01002e7:	89 f2                	mov    %esi,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f0:	7f 04                	jg     f01002f6 <cons_putc+0x68>
f01002f2:	84 c0                	test   %al,%al
f01002f4:	79 e8                	jns    f01002de <cons_putc+0x50>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f6:	ba 78 03 00 00       	mov    $0x378,%edx
f01002fb:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002ff:	ee                   	out    %al,(%dx)
f0100300:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100305:	b8 0d 00 00 00       	mov    $0xd,%eax
f010030a:	ee                   	out    %al,(%dx)
f010030b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100310:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100311:	89 fa                	mov    %edi,%edx
f0100313:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100319:	89 f8                	mov    %edi,%eax
f010031b:	80 cc 07             	or     $0x7,%ah
f010031e:	85 d2                	test   %edx,%edx
f0100320:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100323:	89 f8                	mov    %edi,%eax
f0100325:	0f b6 c0             	movzbl %al,%eax
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	0f 84 b6 00 00 00    	je     f01003e7 <cons_putc+0x159>
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	7e 73                	jle    f01003a9 <cons_putc+0x11b>
f0100336:	83 f8 0a             	cmp    $0xa,%eax
f0100339:	0f 84 9b 00 00 00    	je     f01003da <cons_putc+0x14c>
f010033f:	83 f8 0d             	cmp    $0xd,%eax
f0100342:	0f 85 d6 00 00 00    	jne    f010041e <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f0100348:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010034f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100355:	c1 e8 16             	shr    $0x16,%eax
f0100358:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010035b:	c1 e0 04             	shl    $0x4,%eax
f010035e:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
	if (crt_pos >= CRT_SIZE) {
f0100364:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f010036b:	cf 07 
f010036d:	0f 87 ce 00 00 00    	ja     f0100441 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f0100373:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100379:	b8 0e 00 00 00       	mov    $0xe,%eax
f010037e:	89 ca                	mov    %ecx,%edx
f0100380:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100381:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
f0100388:	8d 71 01             	lea    0x1(%ecx),%esi
f010038b:	89 d8                	mov    %ebx,%eax
f010038d:	66 c1 e8 08          	shr    $0x8,%ax
f0100391:	89 f2                	mov    %esi,%edx
f0100393:	ee                   	out    %al,(%dx)
f0100394:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100399:	89 ca                	mov    %ecx,%edx
f010039b:	ee                   	out    %al,(%dx)
f010039c:	89 d8                	mov    %ebx,%eax
f010039e:	89 f2                	mov    %esi,%edx
f01003a0:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003a4:	5b                   	pop    %ebx
f01003a5:	5e                   	pop    %esi
f01003a6:	5f                   	pop    %edi
f01003a7:	5d                   	pop    %ebp
f01003a8:	c3                   	ret    
	switch (c & 0xff) {
f01003a9:	83 f8 08             	cmp    $0x8,%eax
f01003ac:	75 70                	jne    f010041e <cons_putc+0x190>
		if (crt_pos > 0) {
f01003ae:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003b5:	66 85 c0             	test   %ax,%ax
f01003b8:	74 b9                	je     f0100373 <cons_putc+0xe5>
			crt_pos--;
f01003ba:	83 e8 01             	sub    $0x1,%eax
f01003bd:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c3:	0f b7 c0             	movzwl %ax,%eax
f01003c6:	66 81 e7 00 ff       	and    $0xff00,%di
f01003cb:	83 cf 20             	or     $0x20,%edi
f01003ce:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003d4:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003d8:	eb 8a                	jmp    f0100364 <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f01003da:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f01003e1:	50 
f01003e2:	e9 61 ff ff ff       	jmp    f0100348 <cons_putc+0xba>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 9d fe ff ff       	call   f010028e <cons_putc>
		cons_putc(' ');
f01003f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f6:	e8 93 fe ff ff       	call   f010028e <cons_putc>
		cons_putc(' ');
f01003fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100400:	e8 89 fe ff ff       	call   f010028e <cons_putc>
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 7f fe ff ff       	call   f010028e <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 75 fe ff ff       	call   f010028e <cons_putc>
f0100419:	e9 46 ff ff ff       	jmp    f0100364 <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f010041e:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100425:	8d 50 01             	lea    0x1(%eax),%edx
f0100428:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f010042f:	0f b7 c0             	movzwl %ax,%eax
f0100432:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100438:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010043c:	e9 23 ff ff ff       	jmp    f0100364 <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100441:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f0100446:	83 ec 04             	sub    $0x4,%esp
f0100449:	68 00 0f 00 00       	push   $0xf00
f010044e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100454:	52                   	push   %edx
f0100455:	50                   	push   %eax
f0100456:	e8 a7 1b 00 00       	call   f0102002 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010045b:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100461:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100467:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010046d:	83 c4 10             	add    $0x10,%esp
f0100470:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100475:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100478:	39 d0                	cmp    %edx,%eax
f010047a:	75 f4                	jne    f0100470 <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f010047c:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100483:	50 
f0100484:	e9 ea fe ff ff       	jmp    f0100373 <cons_putc+0xe5>

f0100489 <serial_intr>:
	if (serial_exists)
f0100489:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
f0100490:	75 02                	jne    f0100494 <serial_intr+0xb>
f0100492:	f3 c3                	repz ret 
{
f0100494:	55                   	push   %ebp
f0100495:	89 e5                	mov    %esp,%ebp
f0100497:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010049a:	b8 1e 01 10 f0       	mov    $0xf010011e,%eax
f010049f:	e8 99 fc ff ff       	call   f010013d <cons_intr>
}
f01004a4:	c9                   	leave  
f01004a5:	c3                   	ret    

f01004a6 <kbd_intr>:
{
f01004a6:	55                   	push   %ebp
f01004a7:	89 e5                	mov    %esp,%ebp
f01004a9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ac:	b8 80 01 10 f0       	mov    $0xf0100180,%eax
f01004b1:	e8 87 fc ff ff       	call   f010013d <cons_intr>
}
f01004b6:	c9                   	leave  
f01004b7:	c3                   	ret    

f01004b8 <cons_getc>:
{
f01004b8:	55                   	push   %ebp
f01004b9:	89 e5                	mov    %esp,%ebp
f01004bb:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004be:	e8 c6 ff ff ff       	call   f0100489 <serial_intr>
	kbd_intr();
f01004c3:	e8 de ff ff ff       	call   f01004a6 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004c8:	8b 15 20 45 11 f0    	mov    0xf0114520,%edx
	return 0;
f01004ce:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01004d3:	3b 15 24 45 11 f0    	cmp    0xf0114524,%edx
f01004d9:	74 18                	je     f01004f3 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01004db:	8d 4a 01             	lea    0x1(%edx),%ecx
f01004de:	89 0d 20 45 11 f0    	mov    %ecx,0xf0114520
f01004e4:	0f b6 82 20 43 11 f0 	movzbl -0xfeebce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01004eb:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01004f1:	74 02                	je     f01004f5 <cons_getc+0x3d>
}
f01004f3:	c9                   	leave  
f01004f4:	c3                   	ret    
			cons.rpos = 0;
f01004f5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
f01004fc:	00 00 00 
f01004ff:	eb f2                	jmp    f01004f3 <cons_getc+0x3b>

f0100501 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100501:	55                   	push   %ebp
f0100502:	89 e5                	mov    %esp,%ebp
f0100504:	57                   	push   %edi
f0100505:	56                   	push   %esi
f0100506:	53                   	push   %ebx
f0100507:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f010050a:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100511:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100518:	5a a5 
	if (*cp != 0xA55A) {
f010051a:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100521:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100525:	0f 84 b7 00 00 00    	je     f01005e2 <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f010052b:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
f0100532:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100535:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f010053a:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
f0100540:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100545:	89 fa                	mov    %edi,%edx
f0100547:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100548:	8d 4f 01             	lea    0x1(%edi),%ecx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010054b:	89 ca                	mov    %ecx,%edx
f010054d:	ec                   	in     (%dx),%al
f010054e:	0f b6 c0             	movzbl %al,%eax
f0100551:	c1 e0 08             	shl    $0x8,%eax
f0100554:	89 c3                	mov    %eax,%ebx
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100556:	b8 0f 00 00 00       	mov    $0xf,%eax
f010055b:	89 fa                	mov    %edi,%edx
f010055d:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055e:	89 ca                	mov    %ecx,%edx
f0100560:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100561:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	pos |= inb(addr_6845 + 1);
f0100567:	0f b6 c0             	movzbl %al,%eax
f010056a:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f010056c:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100572:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100577:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f010057c:	89 d8                	mov    %ebx,%eax
f010057e:	89 ca                	mov    %ecx,%edx
f0100580:	ee                   	out    %al,(%dx)
f0100581:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100586:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010058b:	89 fa                	mov    %edi,%edx
f010058d:	ee                   	out    %al,(%dx)
f010058e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100593:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100598:	ee                   	out    %al,(%dx)
f0100599:	be f9 03 00 00       	mov    $0x3f9,%esi
f010059e:	89 d8                	mov    %ebx,%eax
f01005a0:	89 f2                	mov    %esi,%edx
f01005a2:	ee                   	out    %al,(%dx)
f01005a3:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a8:	89 fa                	mov    %edi,%edx
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005b0:	89 d8                	mov    %ebx,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	b8 01 00 00 00       	mov    $0x1,%eax
f01005b8:	89 f2                	mov    %esi,%edx
f01005ba:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bb:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c0:	ec                   	in     (%dx),%al
f01005c1:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c3:	3c ff                	cmp    $0xff,%al
f01005c5:	0f 95 05 34 45 11 f0 	setne  0xf0114534
f01005cc:	89 ca                	mov    %ecx,%edx
f01005ce:	ec                   	in     (%dx),%al
f01005cf:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005d4:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 fb ff             	cmp    $0xff,%bl
f01005d8:	74 23                	je     f01005fd <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f01005da:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005dd:	5b                   	pop    %ebx
f01005de:	5e                   	pop    %esi
f01005df:	5f                   	pop    %edi
f01005e0:	5d                   	pop    %ebp
f01005e1:	c3                   	ret    
		*cp = was;
f01005e2:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005e9:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
f01005f0:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005f3:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f01005f8:	e9 3d ff ff ff       	jmp    f010053a <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 59 24 10 f0       	push   $0xf0102459
f0100605:	e8 db 0e 00 00       	call   f01014e5 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	eb cb                	jmp    f01005da <cons_init+0xd9>

f010060f <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010060f:	55                   	push   %ebp
f0100610:	89 e5                	mov    %esp,%ebp
f0100612:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100615:	8b 45 08             	mov    0x8(%ebp),%eax
f0100618:	e8 71 fc ff ff       	call   f010028e <cons_putc>
}
f010061d:	c9                   	leave  
f010061e:	c3                   	ret    

f010061f <getchar>:

int
getchar(void)
{
f010061f:	55                   	push   %ebp
f0100620:	89 e5                	mov    %esp,%ebp
f0100622:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100625:	e8 8e fe ff ff       	call   f01004b8 <cons_getc>
f010062a:	85 c0                	test   %eax,%eax
f010062c:	74 f7                	je     f0100625 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010062e:	c9                   	leave  
f010062f:	c3                   	ret    

f0100630 <iscons>:

int
iscons(int fdnum)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100633:	b8 01 00 00 00       	mov    $0x1,%eax
f0100638:	5d                   	pop    %ebp
f0100639:	c3                   	ret    

f010063a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010063a:	55                   	push   %ebp
f010063b:	89 e5                	mov    %esp,%ebp
f010063d:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100640:	68 a0 26 10 f0       	push   $0xf01026a0
f0100645:	68 be 26 10 f0       	push   $0xf01026be
f010064a:	68 c3 26 10 f0       	push   $0xf01026c3
f010064f:	e8 91 0e 00 00       	call   f01014e5 <cprintf>
f0100654:	83 c4 0c             	add    $0xc,%esp
f0100657:	68 2c 27 10 f0       	push   $0xf010272c
f010065c:	68 cc 26 10 f0       	push   $0xf01026cc
f0100661:	68 c3 26 10 f0       	push   $0xf01026c3
f0100666:	e8 7a 0e 00 00       	call   f01014e5 <cprintf>
	return 0;
}
f010066b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
f0100675:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100678:	68 d5 26 10 f0       	push   $0xf01026d5
f010067d:	e8 63 0e 00 00       	call   f01014e5 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100682:	83 c4 08             	add    $0x8,%esp
f0100685:	68 0c 00 10 00       	push   $0x10000c
f010068a:	68 54 27 10 f0       	push   $0xf0102754
f010068f:	e8 51 0e 00 00       	call   f01014e5 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100694:	83 c4 0c             	add    $0xc,%esp
f0100697:	68 0c 00 10 00       	push   $0x10000c
f010069c:	68 0c 00 10 f0       	push   $0xf010000c
f01006a1:	68 7c 27 10 f0       	push   $0xf010277c
f01006a6:	e8 3a 0e 00 00       	call   f01014e5 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ab:	83 c4 0c             	add    $0xc,%esp
f01006ae:	68 f9 23 10 00       	push   $0x1023f9
f01006b3:	68 f9 23 10 f0       	push   $0xf01023f9
f01006b8:	68 a0 27 10 f0       	push   $0xf01027a0
f01006bd:	e8 23 0e 00 00       	call   f01014e5 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c2:	83 c4 0c             	add    $0xc,%esp
f01006c5:	68 00 43 11 00       	push   $0x114300
f01006ca:	68 00 43 11 f0       	push   $0xf0114300
f01006cf:	68 c4 27 10 f0       	push   $0xf01027c4
f01006d4:	e8 0c 0e 00 00       	call   f01014e5 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d9:	83 c4 0c             	add    $0xc,%esp
f01006dc:	68 70 49 11 00       	push   $0x114970
f01006e1:	68 70 49 11 f0       	push   $0xf0114970
f01006e6:	68 e8 27 10 f0       	push   $0xf01027e8
f01006eb:	e8 f5 0d 00 00       	call   f01014e5 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f0:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01006f3:	b8 6f 4d 11 f0       	mov    $0xf0114d6f,%eax
f01006f8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006fd:	c1 f8 0a             	sar    $0xa,%eax
f0100700:	50                   	push   %eax
f0100701:	68 0c 28 10 f0       	push   $0xf010280c
f0100706:	e8 da 0d 00 00       	call   f01014e5 <cprintf>
	return 0;
}
f010070b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100710:	c9                   	leave  
f0100711:	c3                   	ret    

f0100712 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100712:	55                   	push   %ebp
f0100713:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100715:	b8 00 00 00 00       	mov    $0x0,%eax
f010071a:	5d                   	pop    %ebp
f010071b:	c3                   	ret    

f010071c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010071c:	55                   	push   %ebp
f010071d:	89 e5                	mov    %esp,%ebp
f010071f:	57                   	push   %edi
f0100720:	56                   	push   %esi
f0100721:	53                   	push   %ebx
f0100722:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100725:	68 38 28 10 f0       	push   $0xf0102838
f010072a:	e8 b6 0d 00 00       	call   f01014e5 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010072f:	c7 04 24 5c 28 10 f0 	movl   $0xf010285c,(%esp)
f0100736:	e8 aa 0d 00 00       	call   f01014e5 <cprintf>
f010073b:	83 c4 10             	add    $0x10,%esp
f010073e:	eb 47                	jmp    f0100787 <monitor+0x6b>
		while (*buf && strchr(WHITESPACE, *buf))
f0100740:	83 ec 08             	sub    $0x8,%esp
f0100743:	0f be c0             	movsbl %al,%eax
f0100746:	50                   	push   %eax
f0100747:	68 f2 26 10 f0       	push   $0xf01026f2
f010074c:	e8 27 18 00 00       	call   f0101f78 <strchr>
f0100751:	83 c4 10             	add    $0x10,%esp
f0100754:	85 c0                	test   %eax,%eax
f0100756:	74 0a                	je     f0100762 <monitor+0x46>
			*buf++ = 0;
f0100758:	c6 03 00             	movb   $0x0,(%ebx)
f010075b:	89 f7                	mov    %esi,%edi
f010075d:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100760:	eb 6b                	jmp    f01007cd <monitor+0xb1>
		if (*buf == 0)
f0100762:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100765:	74 73                	je     f01007da <monitor+0xbe>
		if (argc == MAXARGS-1) {
f0100767:	83 fe 0f             	cmp    $0xf,%esi
f010076a:	74 09                	je     f0100775 <monitor+0x59>
		argv[argc++] = buf;
f010076c:	8d 7e 01             	lea    0x1(%esi),%edi
f010076f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100773:	eb 39                	jmp    f01007ae <monitor+0x92>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100775:	83 ec 08             	sub    $0x8,%esp
f0100778:	6a 10                	push   $0x10
f010077a:	68 f7 26 10 f0       	push   $0xf01026f7
f010077f:	e8 61 0d 00 00       	call   f01014e5 <cprintf>
f0100784:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100787:	83 ec 0c             	sub    $0xc,%esp
f010078a:	68 ee 26 10 f0       	push   $0xf01026ee
f010078f:	e8 c7 15 00 00       	call   f0101d5b <readline>
f0100794:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100796:	83 c4 10             	add    $0x10,%esp
f0100799:	85 c0                	test   %eax,%eax
f010079b:	74 ea                	je     f0100787 <monitor+0x6b>
	argv[argc] = 0;
f010079d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01007a4:	be 00 00 00 00       	mov    $0x0,%esi
f01007a9:	eb 24                	jmp    f01007cf <monitor+0xb3>
			buf++;
f01007ab:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01007ae:	0f b6 03             	movzbl (%ebx),%eax
f01007b1:	84 c0                	test   %al,%al
f01007b3:	74 18                	je     f01007cd <monitor+0xb1>
f01007b5:	83 ec 08             	sub    $0x8,%esp
f01007b8:	0f be c0             	movsbl %al,%eax
f01007bb:	50                   	push   %eax
f01007bc:	68 f2 26 10 f0       	push   $0xf01026f2
f01007c1:	e8 b2 17 00 00       	call   f0101f78 <strchr>
f01007c6:	83 c4 10             	add    $0x10,%esp
f01007c9:	85 c0                	test   %eax,%eax
f01007cb:	74 de                	je     f01007ab <monitor+0x8f>
			*buf++ = 0;
f01007cd:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f01007cf:	0f b6 03             	movzbl (%ebx),%eax
f01007d2:	84 c0                	test   %al,%al
f01007d4:	0f 85 66 ff ff ff    	jne    f0100740 <monitor+0x24>
	argv[argc] = 0;
f01007da:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007e1:	00 
	if (argc == 0)
f01007e2:	85 f6                	test   %esi,%esi
f01007e4:	74 a1                	je     f0100787 <monitor+0x6b>
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e6:	83 ec 08             	sub    $0x8,%esp
f01007e9:	68 be 26 10 f0       	push   $0xf01026be
f01007ee:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f1:	e8 24 17 00 00       	call   f0101f1a <strcmp>
f01007f6:	83 c4 10             	add    $0x10,%esp
f01007f9:	85 c0                	test   %eax,%eax
f01007fb:	74 34                	je     f0100831 <monitor+0x115>
f01007fd:	83 ec 08             	sub    $0x8,%esp
f0100800:	68 cc 26 10 f0       	push   $0xf01026cc
f0100805:	ff 75 a8             	pushl  -0x58(%ebp)
f0100808:	e8 0d 17 00 00       	call   f0101f1a <strcmp>
f010080d:	83 c4 10             	add    $0x10,%esp
f0100810:	85 c0                	test   %eax,%eax
f0100812:	74 18                	je     f010082c <monitor+0x110>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100814:	83 ec 08             	sub    $0x8,%esp
f0100817:	ff 75 a8             	pushl  -0x58(%ebp)
f010081a:	68 14 27 10 f0       	push   $0xf0102714
f010081f:	e8 c1 0c 00 00       	call   f01014e5 <cprintf>
f0100824:	83 c4 10             	add    $0x10,%esp
f0100827:	e9 5b ff ff ff       	jmp    f0100787 <monitor+0x6b>
	for (i = 0; i < NCOMMANDS; i++) {
f010082c:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100831:	83 ec 04             	sub    $0x4,%esp
f0100834:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100837:	ff 75 08             	pushl  0x8(%ebp)
f010083a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010083d:	52                   	push   %edx
f010083e:	56                   	push   %esi
f010083f:	ff 14 85 8c 28 10 f0 	call   *-0xfefd774(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100846:	83 c4 10             	add    $0x10,%esp
f0100849:	85 c0                	test   %eax,%eax
f010084b:	0f 89 36 ff ff ff    	jns    f0100787 <monitor+0x6b>
				break;
	}
}
f0100851:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100854:	5b                   	pop    %ebx
f0100855:	5e                   	pop    %esi
f0100856:	5f                   	pop    %edi
f0100857:	5d                   	pop    %ebp
f0100858:	c3                   	ret    

f0100859 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100859:	55                   	push   %ebp
f010085a:	89 e5                	mov    %esp,%ebp
f010085c:	53                   	push   %ebx
f010085d:	83 ec 04             	sub    $0x4,%esp
f0100860:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100862:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f0100869:	74 66                	je     f01008d1 <boot_alloc+0x78>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
        cprintf("boot_alloc memory at %x\n", nextfree);
f010086b:	83 ec 08             	sub    $0x8,%esp
f010086e:	ff 35 38 45 11 f0    	pushl  0xf0114538
f0100874:	68 9c 28 10 f0       	push   $0xf010289c
f0100879:	e8 67 0c 00 00       	call   f01014e5 <cprintf>
        cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
f010087e:	83 c4 08             	add    $0x8,%esp
f0100881:	89 d8                	mov    %ebx,%eax
f0100883:	03 05 38 45 11 f0    	add    0xf0114538,%eax
f0100889:	05 ff 0f 00 00       	add    $0xfff,%eax
f010088e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100893:	50                   	push   %eax
f0100894:	68 b5 28 10 f0       	push   $0xf01028b5
f0100899:	e8 47 0c 00 00       	call   f01014e5 <cprintf>
      
        char * next = nextfree;
f010089e:	a1 38 45 11 f0       	mov    0xf0114538,%eax
        nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f01008a3:	8d 8c 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%ecx
f01008aa:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01008b0:	89 0d 38 45 11 f0    	mov    %ecx,0xf0114538
        if((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
f01008b6:	8b 1d 64 49 11 f0    	mov    0xf0114964,%ebx
f01008bc:	8d 93 00 00 0f 00    	lea    0xf0000(%ebx),%edx
f01008c2:	c1 e2 0c             	shl    $0xc,%edx
f01008c5:	83 c4 10             	add    $0x10,%esp
f01008c8:	39 ca                	cmp    %ecx,%edx
f01008ca:	72 16                	jb     f01008e2 <boot_alloc+0x89>
          panic("Out of memory!\n");
        }

        return next;
}
f01008cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01008cf:	c9                   	leave  
f01008d0:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008d1:	b8 6f 59 11 f0       	mov    $0xf011596f,%eax
f01008d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008db:	a3 38 45 11 f0       	mov    %eax,0xf0114538
f01008e0:	eb 89                	jmp    f010086b <boot_alloc+0x12>
          panic("Out of memory!\n");
f01008e2:	83 ec 04             	sub    $0x4,%esp
f01008e5:	68 c8 28 10 f0       	push   $0xf01028c8
f01008ea:	6a 6b                	push   $0x6b
f01008ec:	68 d8 28 10 f0       	push   $0xf01028d8
f01008f1:	e8 95 f7 ff ff       	call   f010008b <_panic>

f01008f6 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01008f6:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f01008fc:	c1 f8 03             	sar    $0x3,%eax
f01008ff:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100902:	89 c2                	mov    %eax,%edx
f0100904:	c1 ea 0c             	shr    $0xc,%edx
f0100907:	39 15 64 49 11 f0    	cmp    %edx,0xf0114964
f010090d:	76 06                	jbe    f0100915 <page2kva+0x1f>
	return (void *)(pa + KERNBASE);
f010090f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100914:	c3                   	ret    
{
f0100915:	55                   	push   %ebp
f0100916:	89 e5                	mov    %esp,%ebp
f0100918:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010091b:	50                   	push   %eax
f010091c:	68 b4 2a 10 f0       	push   $0xf0102ab4
f0100921:	6a 52                	push   $0x52
f0100923:	68 e4 28 10 f0       	push   $0xf01028e4
f0100928:	e8 5e f7 ff ff       	call   f010008b <_panic>

f010092d <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010092d:	89 d1                	mov    %edx,%ecx
f010092f:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100932:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100935:	a8 01                	test   $0x1,%al
f0100937:	74 52                	je     f010098b <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100939:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010093e:	89 c1                	mov    %eax,%ecx
f0100940:	c1 e9 0c             	shr    $0xc,%ecx
f0100943:	3b 0d 64 49 11 f0    	cmp    0xf0114964,%ecx
f0100949:	73 25                	jae    f0100970 <check_va2pa+0x43>
	if (!(p[PTX(va)] & PTE_P))
f010094b:	c1 ea 0c             	shr    $0xc,%edx
f010094e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100954:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010095b:	89 c2                	mov    %eax,%edx
f010095d:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100960:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100965:	85 d2                	test   %edx,%edx
f0100967:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010096c:	0f 44 c2             	cmove  %edx,%eax
f010096f:	c3                   	ret    
{
f0100970:	55                   	push   %ebp
f0100971:	89 e5                	mov    %esp,%ebp
f0100973:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100976:	50                   	push   %eax
f0100977:	68 b4 2a 10 f0       	push   $0xf0102ab4
f010097c:	68 b2 02 00 00       	push   $0x2b2
f0100981:	68 d8 28 10 f0       	push   $0xf01028d8
f0100986:	e8 00 f7 ff ff       	call   f010008b <_panic>
		return ~0;
f010098b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100990:	c3                   	ret    

f0100991 <page_init>:
{
f0100991:	55                   	push   %ebp
f0100992:	89 e5                	mov    %esp,%ebp
f0100994:	57                   	push   %edi
f0100995:	56                   	push   %esi
f0100996:	53                   	push   %ebx
f0100997:	83 ec 0c             	sub    $0xc,%esp
	for (i = 0; i < npages; i++) {
f010099a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010099f:	eb 76                	jmp    f0100a17 <page_init+0x86>
            else if(i < npages_basemem){
f01009a1:	39 1d 40 45 11 f0    	cmp    %ebx,0xf0114540
f01009a7:	0f 86 93 00 00 00    	jbe    f0100a40 <page_init+0xaf>
f01009ad:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
                    pages[i].pp_ref = 0;
f01009b4:	89 c2                	mov    %eax,%edx
f01009b6:	03 15 6c 49 11 f0    	add    0xf011496c,%edx
f01009bc:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
                    pages[i].pp_link = page_free_list;
f01009c2:	8b 0d 3c 45 11 f0    	mov    0xf011453c,%ecx
f01009c8:	89 0a                	mov    %ecx,(%edx)
                    page_free_list = &pages[i];
f01009ca:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f01009d0:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
f01009d5:	8d 34 dd 00 00 00 00 	lea    0x0(,%ebx,8),%esi
	return (pp - pages) << PGSHIFT;
f01009dc:	89 f7                	mov    %esi,%edi
f01009de:	c1 e7 09             	shl    $0x9,%edi
	if((pa == 0 || (pa >= IOPHYSMEM && pa <= ((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT )) && (pages[i].pp_ref == 0))
f01009e1:	85 ff                	test   %edi,%edi
f01009e3:	74 1e                	je     f0100a03 <page_init+0x72>
f01009e5:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f01009eb:	76 27                	jbe    f0100a14 <page_init+0x83>
f01009ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01009f2:	e8 62 fe ff ff       	call   f0100859 <boot_alloc>
f01009f7:	05 00 00 00 10       	add    $0x10000000,%eax
f01009fc:	c1 e8 0c             	shr    $0xc,%eax
f01009ff:	39 f8                	cmp    %edi,%eax
f0100a01:	72 11                	jb     f0100a14 <page_init+0x83>
f0100a03:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
f0100a08:	66 83 7c 30 04 00    	cmpw   $0x0,0x4(%eax,%esi,1)
f0100a0e:	0f 84 8f 00 00 00    	je     f0100aa3 <page_init+0x112>
	for (i = 0; i < npages; i++) {
f0100a14:	83 c3 01             	add    $0x1,%ebx
f0100a17:	39 1d 64 49 11 f0    	cmp    %ebx,0xf0114964
f0100a1d:	0f 86 97 00 00 00    	jbe    f0100aba <page_init+0x129>
            if(i == 0){
f0100a23:	85 db                	test   %ebx,%ebx
f0100a25:	0f 85 76 ff ff ff    	jne    f01009a1 <page_init+0x10>
               pages[i].pp_ref = 1;
f0100a2b:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
f0100a30:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
               pages[i].pp_link = NULL;
f0100a36:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pa = page2pa(&pages[i]);
f0100a3c:	89 de                	mov    %ebx,%esi
f0100a3e:	eb c3                	jmp    f0100a03 <page_init+0x72>
            else if(i <= (EXTPHYSMEM/PGSIZE) || i < (((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT))
f0100a40:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100a46:	77 18                	ja     f0100a60 <page_init+0xcf>
		pages[i].pp_ref++;
f0100a48:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
f0100a4d:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100a50:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		pages[i].pp_link = NULL;
f0100a55:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100a5b:	e9 75 ff ff ff       	jmp    f01009d5 <page_init+0x44>
            else if(i <= (EXTPHYSMEM/PGSIZE) || i < (((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT))
f0100a60:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a65:	e8 ef fd ff ff       	call   f0100859 <boot_alloc>
f0100a6a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100a6f:	c1 e8 0c             	shr    $0xc,%eax
f0100a72:	39 d8                	cmp    %ebx,%eax
f0100a74:	77 d2                	ja     f0100a48 <page_init+0xb7>
f0100a76:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 0;
f0100a7d:	89 c2                	mov    %eax,%edx
f0100a7f:	03 15 6c 49 11 f0    	add    0xf011496c,%edx
f0100a85:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100a8b:	8b 0d 3c 45 11 f0    	mov    0xf011453c,%ecx
f0100a91:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0100a93:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100a99:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
f0100a9e:	e9 32 ff ff ff       	jmp    f01009d5 <page_init+0x44>
	panic("page error\n");
f0100aa3:	83 ec 04             	sub    $0x4,%esp
f0100aa6:	68 f2 28 10 f0       	push   $0xf01028f2
f0100aab:	68 1e 01 00 00       	push   $0x11e
f0100ab0:	68 d8 28 10 f0       	push   $0xf01028d8
f0100ab5:	e8 d1 f5 ff ff       	call   f010008b <_panic>
}
f0100aba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100abd:	5b                   	pop    %ebx
f0100abe:	5e                   	pop    %esi
f0100abf:	5f                   	pop    %edi
f0100ac0:	5d                   	pop    %ebp
f0100ac1:	c3                   	ret    

f0100ac2 <page_alloc>:
{
f0100ac2:	55                   	push   %ebp
f0100ac3:	89 e5                	mov    %esp,%ebp
f0100ac5:	53                   	push   %ebx
f0100ac6:	83 ec 04             	sub    $0x4,%esp
       page = page_free_list;
f0100ac9:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
       if(!page){
f0100acf:	85 db                	test   %ebx,%ebx
f0100ad1:	74 13                	je     f0100ae6 <page_alloc+0x24>
       page_free_list = page_free_list->pp_link;
f0100ad3:	8b 03                	mov    (%ebx),%eax
f0100ad5:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
       page->pp_link = NULL;
f0100ada:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
        if (alloc_flags & ALLOC_ZERO) 
f0100ae0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ae4:	75 07                	jne    f0100aed <page_alloc+0x2b>
}
f0100ae6:	89 d8                	mov    %ebx,%eax
f0100ae8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aeb:	c9                   	leave  
f0100aec:	c3                   	ret    
f0100aed:	89 d8                	mov    %ebx,%eax
f0100aef:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0100af5:	c1 f8 03             	sar    $0x3,%eax
f0100af8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100afb:	89 c2                	mov    %eax,%edx
f0100afd:	c1 ea 0c             	shr    $0xc,%edx
f0100b00:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0100b06:	73 1a                	jae    f0100b22 <page_alloc+0x60>
            memset(page2kva(page), 0, PGSIZE);
f0100b08:	83 ec 04             	sub    $0x4,%esp
f0100b0b:	68 00 10 00 00       	push   $0x1000
f0100b10:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100b12:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b17:	50                   	push   %eax
f0100b18:	e8 98 14 00 00       	call   f0101fb5 <memset>
f0100b1d:	83 c4 10             	add    $0x10,%esp
f0100b20:	eb c4                	jmp    f0100ae6 <page_alloc+0x24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b22:	50                   	push   %eax
f0100b23:	68 b4 2a 10 f0       	push   $0xf0102ab4
f0100b28:	6a 52                	push   $0x52
f0100b2a:	68 e4 28 10 f0       	push   $0xf01028e4
f0100b2f:	e8 57 f5 ff ff       	call   f010008b <_panic>

f0100b34 <page_free>:
{
f0100b34:	55                   	push   %ebp
f0100b35:	89 e5                	mov    %esp,%ebp
f0100b37:	8b 45 08             	mov    0x8(%ebp),%eax
        pp->pp_link = page_free_list;
f0100b3a:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100b40:	89 10                	mov    %edx,(%eax)
        page_free_list = pp;
f0100b42:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100b47:	5d                   	pop    %ebp
f0100b48:	c3                   	ret    

f0100b49 <mem_init>:
{
f0100b49:	55                   	push   %ebp
f0100b4a:	89 e5                	mov    %esp,%ebp
f0100b4c:	57                   	push   %edi
f0100b4d:	56                   	push   %esi
f0100b4e:	53                   	push   %ebx
f0100b4f:	83 ec 48             	sub    $0x48,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b52:	6a 15                	push   $0x15
f0100b54:	e8 25 09 00 00       	call   f010147e <mc146818_read>
f0100b59:	89 c3                	mov    %eax,%ebx
f0100b5b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100b62:	e8 17 09 00 00       	call   f010147e <mc146818_read>
f0100b67:	c1 e0 08             	shl    $0x8,%eax
f0100b6a:	09 d8                	or     %ebx,%eax
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100b6c:	c1 e0 0a             	shl    $0xa,%eax
f0100b6f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b75:	85 c0                	test   %eax,%eax
f0100b77:	0f 48 c2             	cmovs  %edx,%eax
f0100b7a:	c1 f8 0c             	sar    $0xc,%eax
f0100b7d:	a3 40 45 11 f0       	mov    %eax,0xf0114540
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b82:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100b89:	e8 f0 08 00 00       	call   f010147e <mc146818_read>
f0100b8e:	89 c3                	mov    %eax,%ebx
f0100b90:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100b97:	e8 e2 08 00 00       	call   f010147e <mc146818_read>
f0100b9c:	c1 e0 08             	shl    $0x8,%eax
f0100b9f:	09 d8                	or     %ebx,%eax
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100ba1:	c1 e0 0a             	shl    $0xa,%eax
f0100ba4:	89 c2                	mov    %eax,%edx
f0100ba6:	8d 80 ff 0f 00 00    	lea    0xfff(%eax),%eax
f0100bac:	83 c4 10             	add    $0x10,%esp
f0100baf:	85 d2                	test   %edx,%edx
f0100bb1:	0f 49 c2             	cmovns %edx,%eax
f0100bb4:	c1 f8 0c             	sar    $0xc,%eax
	if (npages_extmem)
f0100bb7:	85 c0                	test   %eax,%eax
f0100bb9:	75 78                	jne    f0100c33 <mem_init+0xea>
		npages = npages_basemem;
f0100bbb:	8b 15 40 45 11 f0    	mov    0xf0114540,%edx
f0100bc1:	89 15 64 49 11 f0    	mov    %edx,0xf0114964
		npages_extmem * PGSIZE / 1024);
f0100bc7:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100bca:	c1 e8 0a             	shr    $0xa,%eax
f0100bcd:	50                   	push   %eax
		npages_basemem * PGSIZE / 1024,
f0100bce:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100bd3:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100bd6:	c1 e8 0a             	shr    $0xa,%eax
f0100bd9:	50                   	push   %eax
		npages * PGSIZE / 1024,
f0100bda:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100bdf:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100be2:	c1 e8 0a             	shr    $0xa,%eax
f0100be5:	50                   	push   %eax
f0100be6:	68 d8 2a 10 f0       	push   $0xf0102ad8
f0100beb:	e8 f5 08 00 00       	call   f01014e5 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100bf0:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100bf5:	e8 5f fc ff ff       	call   f0100859 <boot_alloc>
f0100bfa:	a3 68 49 11 f0       	mov    %eax,0xf0114968
	memset(kern_pgdir, 0, PGSIZE);
f0100bff:	83 c4 0c             	add    $0xc,%esp
f0100c02:	68 00 10 00 00       	push   $0x1000
f0100c07:	6a 00                	push   $0x0
f0100c09:	50                   	push   %eax
f0100c0a:	e8 a6 13 00 00       	call   f0101fb5 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100c0f:	a1 68 49 11 f0       	mov    0xf0114968,%eax
	if ((uint32_t)kva < KERNBASE)
f0100c14:	83 c4 10             	add    $0x10,%esp
f0100c17:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100c1c:	77 23                	ja     f0100c41 <mem_init+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c1e:	50                   	push   %eax
f0100c1f:	68 14 2b 10 f0       	push   $0xf0102b14
f0100c24:	68 92 00 00 00       	push   $0x92
f0100c29:	68 d8 28 10 f0       	push   $0xf01028d8
f0100c2e:	e8 58 f4 ff ff       	call   f010008b <_panic>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100c33:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100c39:	89 15 64 49 11 f0    	mov    %edx,0xf0114964
f0100c3f:	eb 86                	jmp    f0100bc7 <mem_init+0x7e>
	return (physaddr_t)kva - KERNBASE;
f0100c41:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100c47:	83 ca 05             	or     $0x5,%edx
f0100c4a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
          pages = (struct PageInfo *)boot_alloc(npages * PageInfo_size);
f0100c50:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100c55:	c1 e0 03             	shl    $0x3,%eax
f0100c58:	e8 fc fb ff ff       	call   f0100859 <boot_alloc>
f0100c5d:	a3 6c 49 11 f0       	mov    %eax,0xf011496c
          memset(pages,0,npages * PageInfo_size);
f0100c62:	83 ec 04             	sub    $0x4,%esp
f0100c65:	8b 35 64 49 11 f0    	mov    0xf0114964,%esi
f0100c6b:	8d 14 f5 00 00 00 00 	lea    0x0(,%esi,8),%edx
f0100c72:	52                   	push   %edx
f0100c73:	6a 00                	push   $0x0
f0100c75:	50                   	push   %eax
f0100c76:	e8 3a 13 00 00       	call   f0101fb5 <memset>
	page_init();
f0100c7b:	e8 11 fd ff ff       	call   f0100991 <page_init>
	if (!page_free_list)
f0100c80:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100c85:	83 c4 10             	add    $0x10,%esp
f0100c88:	85 c0                	test   %eax,%eax
f0100c8a:	74 4c                	je     f0100cd8 <mem_init+0x18f>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c8c:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c8f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c92:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c95:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100c98:	89 c2                	mov    %eax,%edx
f0100c9a:	2b 15 6c 49 11 f0    	sub    0xf011496c,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ca0:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ca6:	0f 95 c2             	setne  %dl
f0100ca9:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100cac:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100cb0:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100cb2:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cb6:	8b 00                	mov    (%eax),%eax
f0100cb8:	85 c0                	test   %eax,%eax
f0100cba:	75 dc                	jne    f0100c98 <mem_init+0x14f>
		*tp[1] = 0;
f0100cbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cbf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100cc5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cc8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ccb:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ccd:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100cd0:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
f0100cd6:	eb 2b                	jmp    f0100d03 <mem_init+0x1ba>
		panic("'page_free_list' is a null pointer!");
f0100cd8:	83 ec 04             	sub    $0x4,%esp
f0100cdb:	68 38 2b 10 f0       	push   $0xf0102b38
f0100ce0:	68 f5 01 00 00       	push   $0x1f5
f0100ce5:	68 d8 28 10 f0       	push   $0xf01028d8
f0100cea:	e8 9c f3 ff ff       	call   f010008b <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cef:	52                   	push   %edx
f0100cf0:	68 b4 2a 10 f0       	push   $0xf0102ab4
f0100cf5:	6a 52                	push   $0x52
f0100cf7:	68 e4 28 10 f0       	push   $0xf01028e4
f0100cfc:	e8 8a f3 ff ff       	call   f010008b <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d01:	8b 1b                	mov    (%ebx),%ebx
f0100d03:	85 db                	test   %ebx,%ebx
f0100d05:	74 42                	je     f0100d49 <mem_init+0x200>
	return (pp - pages) << PGSHIFT;
f0100d07:	89 d8                	mov    %ebx,%eax
f0100d09:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0100d0f:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d12:	89 c2                	mov    %eax,%edx
f0100d14:	c1 e2 0c             	shl    $0xc,%edx
f0100d17:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100d1c:	75 e3                	jne    f0100d01 <mem_init+0x1b8>
	if (PGNUM(pa) >= npages)
f0100d1e:	89 d0                	mov    %edx,%eax
f0100d20:	c1 e8 0c             	shr    $0xc,%eax
f0100d23:	3b 05 64 49 11 f0    	cmp    0xf0114964,%eax
f0100d29:	73 c4                	jae    f0100cef <mem_init+0x1a6>
			memset(page2kva(pp), 0x97, 128);
f0100d2b:	83 ec 04             	sub    $0x4,%esp
f0100d2e:	68 80 00 00 00       	push   $0x80
f0100d33:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100d38:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100d3e:	52                   	push   %edx
f0100d3f:	e8 71 12 00 00       	call   f0101fb5 <memset>
f0100d44:	83 c4 10             	add    $0x10,%esp
f0100d47:	eb b8                	jmp    f0100d01 <mem_init+0x1b8>
	first_free_page = (char *) boot_alloc(0);
f0100d49:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d4e:	e8 06 fb ff ff       	call   f0100859 <boot_alloc>
f0100d53:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d56:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100d5c:	89 55 c4             	mov    %edx,-0x3c(%ebp)
		assert(pp >= pages);
f0100d5f:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
		assert(pp < pages + npages);
f0100d65:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100d6a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100d6d:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d70:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d73:	be 00 00 00 00       	mov    $0x0,%esi
f0100d78:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100d7b:	e9 c9 00 00 00       	jmp    f0100e49 <mem_init+0x300>
		assert(pp >= pages);
f0100d80:	68 fe 28 10 f0       	push   $0xf01028fe
f0100d85:	68 0a 29 10 f0       	push   $0xf010290a
f0100d8a:	68 0f 02 00 00       	push   $0x20f
f0100d8f:	68 d8 28 10 f0       	push   $0xf01028d8
f0100d94:	e8 f2 f2 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100d99:	68 1f 29 10 f0       	push   $0xf010291f
f0100d9e:	68 0a 29 10 f0       	push   $0xf010290a
f0100da3:	68 10 02 00 00       	push   $0x210
f0100da8:	68 d8 28 10 f0       	push   $0xf01028d8
f0100dad:	e8 d9 f2 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100db2:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100db7:	68 0a 29 10 f0       	push   $0xf010290a
f0100dbc:	68 11 02 00 00       	push   $0x211
f0100dc1:	68 d8 28 10 f0       	push   $0xf01028d8
f0100dc6:	e8 c0 f2 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != 0);
f0100dcb:	68 33 29 10 f0       	push   $0xf0102933
f0100dd0:	68 0a 29 10 f0       	push   $0xf010290a
f0100dd5:	68 14 02 00 00       	push   $0x214
f0100dda:	68 d8 28 10 f0       	push   $0xf01028d8
f0100ddf:	e8 a7 f2 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100de4:	68 44 29 10 f0       	push   $0xf0102944
f0100de9:	68 0a 29 10 f0       	push   $0xf010290a
f0100dee:	68 15 02 00 00       	push   $0x215
f0100df3:	68 d8 28 10 f0       	push   $0xf01028d8
f0100df8:	e8 8e f2 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dfd:	68 90 2b 10 f0       	push   $0xf0102b90
f0100e02:	68 0a 29 10 f0       	push   $0xf010290a
f0100e07:	68 16 02 00 00       	push   $0x216
f0100e0c:	68 d8 28 10 f0       	push   $0xf01028d8
f0100e11:	e8 75 f2 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e16:	68 5d 29 10 f0       	push   $0xf010295d
f0100e1b:	68 0a 29 10 f0       	push   $0xf010290a
f0100e20:	68 17 02 00 00       	push   $0x217
f0100e25:	68 d8 28 10 f0       	push   $0xf01028d8
f0100e2a:	e8 5c f2 ff ff       	call   f010008b <_panic>
	if (PGNUM(pa) >= npages)
f0100e2f:	89 c3                	mov    %eax,%ebx
f0100e31:	c1 eb 0c             	shr    $0xc,%ebx
f0100e34:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100e37:	76 68                	jbe    f0100ea1 <mem_init+0x358>
	return (void *)(pa + KERNBASE);
f0100e39:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e3e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100e41:	77 70                	ja     f0100eb3 <mem_init+0x36a>
			++nfree_extmem;
f0100e43:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e47:	8b 12                	mov    (%edx),%edx
f0100e49:	85 d2                	test   %edx,%edx
f0100e4b:	74 7f                	je     f0100ecc <mem_init+0x383>
		assert(pp >= pages);
f0100e4d:	39 d1                	cmp    %edx,%ecx
f0100e4f:	0f 87 2b ff ff ff    	ja     f0100d80 <mem_init+0x237>
		assert(pp < pages + npages);
f0100e55:	39 fa                	cmp    %edi,%edx
f0100e57:	0f 83 3c ff ff ff    	jae    f0100d99 <mem_init+0x250>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e5d:	89 d0                	mov    %edx,%eax
f0100e5f:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100e62:	a8 07                	test   $0x7,%al
f0100e64:	0f 85 48 ff ff ff    	jne    f0100db2 <mem_init+0x269>
	return (pp - pages) << PGSHIFT;
f0100e6a:	c1 f8 03             	sar    $0x3,%eax
f0100e6d:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100e70:	85 c0                	test   %eax,%eax
f0100e72:	0f 84 53 ff ff ff    	je     f0100dcb <mem_init+0x282>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e78:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e7d:	0f 84 61 ff ff ff    	je     f0100de4 <mem_init+0x29b>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e83:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e88:	0f 84 6f ff ff ff    	je     f0100dfd <mem_init+0x2b4>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e8e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e93:	74 81                	je     f0100e16 <mem_init+0x2cd>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e95:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e9a:	77 93                	ja     f0100e2f <mem_init+0x2e6>
			++nfree_basemem;
f0100e9c:	83 c6 01             	add    $0x1,%esi
f0100e9f:	eb a6                	jmp    f0100e47 <mem_init+0x2fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ea1:	50                   	push   %eax
f0100ea2:	68 b4 2a 10 f0       	push   $0xf0102ab4
f0100ea7:	6a 52                	push   $0x52
f0100ea9:	68 e4 28 10 f0       	push   $0xf01028e4
f0100eae:	e8 d8 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100eb3:	68 b4 2b 10 f0       	push   $0xf0102bb4
f0100eb8:	68 0a 29 10 f0       	push   $0xf010290a
f0100ebd:	68 18 02 00 00       	push   $0x218
f0100ec2:	68 d8 28 10 f0       	push   $0xf01028d8
f0100ec7:	e8 bf f1 ff ff       	call   f010008b <_panic>
f0100ecc:	8b 5d d0             	mov    -0x30(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100ecf:	85 f6                	test   %esi,%esi
f0100ed1:	7e 27                	jle    f0100efa <mem_init+0x3b1>
	assert(nfree_extmem > 0);
f0100ed3:	85 db                	test   %ebx,%ebx
f0100ed5:	7e 3c                	jle    f0100f13 <mem_init+0x3ca>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100ed7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100edc:	8b 45 c4             	mov    -0x3c(%ebp),%eax
	if (!pages)
f0100edf:	85 c9                	test   %ecx,%ecx
f0100ee1:	75 4e                	jne    f0100f31 <mem_init+0x3e8>
		panic("'pages' is a null pointer!");
f0100ee3:	83 ec 04             	sub    $0x4,%esp
f0100ee6:	68 9a 29 10 f0       	push   $0xf010299a
f0100eeb:	68 32 02 00 00       	push   $0x232
f0100ef0:	68 d8 28 10 f0       	push   $0xf01028d8
f0100ef5:	e8 91 f1 ff ff       	call   f010008b <_panic>
	assert(nfree_basemem > 0);
f0100efa:	68 77 29 10 f0       	push   $0xf0102977
f0100eff:	68 0a 29 10 f0       	push   $0xf010290a
f0100f04:	68 20 02 00 00       	push   $0x220
f0100f09:	68 d8 28 10 f0       	push   $0xf01028d8
f0100f0e:	e8 78 f1 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100f13:	68 89 29 10 f0       	push   $0xf0102989
f0100f18:	68 0a 29 10 f0       	push   $0xf010290a
f0100f1d:	68 21 02 00 00       	push   $0x221
f0100f22:	68 d8 28 10 f0       	push   $0xf01028d8
f0100f27:	e8 5f f1 ff ff       	call   f010008b <_panic>
		++nfree;
f0100f2c:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f2f:	8b 00                	mov    (%eax),%eax
f0100f31:	85 c0                	test   %eax,%eax
f0100f33:	75 f7                	jne    f0100f2c <mem_init+0x3e3>
	assert((pp0 = page_alloc(0)));
f0100f35:	83 ec 0c             	sub    $0xc,%esp
f0100f38:	6a 00                	push   $0x0
f0100f3a:	e8 83 fb ff ff       	call   f0100ac2 <page_alloc>
f0100f3f:	89 c7                	mov    %eax,%edi
f0100f41:	83 c4 10             	add    $0x10,%esp
f0100f44:	85 c0                	test   %eax,%eax
f0100f46:	0f 84 d5 01 00 00    	je     f0101121 <mem_init+0x5d8>
	assert((pp1 = page_alloc(0)));
f0100f4c:	83 ec 0c             	sub    $0xc,%esp
f0100f4f:	6a 00                	push   $0x0
f0100f51:	e8 6c fb ff ff       	call   f0100ac2 <page_alloc>
f0100f56:	89 c6                	mov    %eax,%esi
f0100f58:	83 c4 10             	add    $0x10,%esp
f0100f5b:	85 c0                	test   %eax,%eax
f0100f5d:	0f 84 d7 01 00 00    	je     f010113a <mem_init+0x5f1>
	assert((pp2 = page_alloc(0)));
f0100f63:	83 ec 0c             	sub    $0xc,%esp
f0100f66:	6a 00                	push   $0x0
f0100f68:	e8 55 fb ff ff       	call   f0100ac2 <page_alloc>
f0100f6d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100f70:	83 c4 10             	add    $0x10,%esp
f0100f73:	85 c0                	test   %eax,%eax
f0100f75:	0f 84 d8 01 00 00    	je     f0101153 <mem_init+0x60a>
	assert(pp1 && pp1 != pp0);
f0100f7b:	39 f7                	cmp    %esi,%edi
f0100f7d:	0f 84 e9 01 00 00    	je     f010116c <mem_init+0x623>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100f83:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f86:	39 c7                	cmp    %eax,%edi
f0100f88:	0f 84 f7 01 00 00    	je     f0101185 <mem_init+0x63c>
f0100f8e:	39 c6                	cmp    %eax,%esi
f0100f90:	0f 84 ef 01 00 00    	je     f0101185 <mem_init+0x63c>
	return (pp - pages) << PGSHIFT;
f0100f96:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0100f9c:	8b 15 64 49 11 f0    	mov    0xf0114964,%edx
f0100fa2:	c1 e2 0c             	shl    $0xc,%edx
f0100fa5:	89 f8                	mov    %edi,%eax
f0100fa7:	29 c8                	sub    %ecx,%eax
f0100fa9:	c1 f8 03             	sar    $0x3,%eax
f0100fac:	c1 e0 0c             	shl    $0xc,%eax
f0100faf:	39 d0                	cmp    %edx,%eax
f0100fb1:	0f 83 e7 01 00 00    	jae    f010119e <mem_init+0x655>
f0100fb7:	89 f0                	mov    %esi,%eax
f0100fb9:	29 c8                	sub    %ecx,%eax
f0100fbb:	c1 f8 03             	sar    $0x3,%eax
f0100fbe:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0100fc1:	39 c2                	cmp    %eax,%edx
f0100fc3:	0f 86 ee 01 00 00    	jbe    f01011b7 <mem_init+0x66e>
f0100fc9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fcc:	29 c8                	sub    %ecx,%eax
f0100fce:	c1 f8 03             	sar    $0x3,%eax
f0100fd1:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0100fd4:	39 c2                	cmp    %eax,%edx
f0100fd6:	0f 86 f4 01 00 00    	jbe    f01011d0 <mem_init+0x687>
	fl = page_free_list;
f0100fdc:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100fe1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0100fe4:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0100feb:	00 00 00 
	assert(!page_alloc(0));
f0100fee:	83 ec 0c             	sub    $0xc,%esp
f0100ff1:	6a 00                	push   $0x0
f0100ff3:	e8 ca fa ff ff       	call   f0100ac2 <page_alloc>
f0100ff8:	83 c4 10             	add    $0x10,%esp
f0100ffb:	85 c0                	test   %eax,%eax
f0100ffd:	0f 85 e6 01 00 00    	jne    f01011e9 <mem_init+0x6a0>
	page_free(pp0);
f0101003:	83 ec 0c             	sub    $0xc,%esp
f0101006:	57                   	push   %edi
f0101007:	e8 28 fb ff ff       	call   f0100b34 <page_free>
	page_free(pp1);
f010100c:	89 34 24             	mov    %esi,(%esp)
f010100f:	e8 20 fb ff ff       	call   f0100b34 <page_free>
	page_free(pp2);
f0101014:	83 c4 04             	add    $0x4,%esp
f0101017:	ff 75 d4             	pushl  -0x2c(%ebp)
f010101a:	e8 15 fb ff ff       	call   f0100b34 <page_free>
	assert((pp0 = page_alloc(0)));
f010101f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101026:	e8 97 fa ff ff       	call   f0100ac2 <page_alloc>
f010102b:	89 c6                	mov    %eax,%esi
f010102d:	83 c4 10             	add    $0x10,%esp
f0101030:	85 c0                	test   %eax,%eax
f0101032:	0f 84 ca 01 00 00    	je     f0101202 <mem_init+0x6b9>
	assert((pp1 = page_alloc(0)));
f0101038:	83 ec 0c             	sub    $0xc,%esp
f010103b:	6a 00                	push   $0x0
f010103d:	e8 80 fa ff ff       	call   f0100ac2 <page_alloc>
f0101042:	89 c7                	mov    %eax,%edi
f0101044:	83 c4 10             	add    $0x10,%esp
f0101047:	85 c0                	test   %eax,%eax
f0101049:	0f 84 cc 01 00 00    	je     f010121b <mem_init+0x6d2>
	assert((pp2 = page_alloc(0)));
f010104f:	83 ec 0c             	sub    $0xc,%esp
f0101052:	6a 00                	push   $0x0
f0101054:	e8 69 fa ff ff       	call   f0100ac2 <page_alloc>
f0101059:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010105c:	83 c4 10             	add    $0x10,%esp
f010105f:	85 c0                	test   %eax,%eax
f0101061:	0f 84 cd 01 00 00    	je     f0101234 <mem_init+0x6eb>
	assert(pp1 && pp1 != pp0);
f0101067:	39 fe                	cmp    %edi,%esi
f0101069:	0f 84 de 01 00 00    	je     f010124d <mem_init+0x704>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010106f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101072:	39 c6                	cmp    %eax,%esi
f0101074:	0f 84 ec 01 00 00    	je     f0101266 <mem_init+0x71d>
f010107a:	39 c7                	cmp    %eax,%edi
f010107c:	0f 84 e4 01 00 00    	je     f0101266 <mem_init+0x71d>
	assert(!page_alloc(0));
f0101082:	83 ec 0c             	sub    $0xc,%esp
f0101085:	6a 00                	push   $0x0
f0101087:	e8 36 fa ff ff       	call   f0100ac2 <page_alloc>
f010108c:	83 c4 10             	add    $0x10,%esp
f010108f:	85 c0                	test   %eax,%eax
f0101091:	0f 85 e8 01 00 00    	jne    f010127f <mem_init+0x736>
	memset(page2kva(pp0), 1, PGSIZE);
f0101097:	89 f0                	mov    %esi,%eax
f0101099:	e8 58 f8 ff ff       	call   f01008f6 <page2kva>
f010109e:	83 ec 04             	sub    $0x4,%esp
f01010a1:	68 00 10 00 00       	push   $0x1000
f01010a6:	6a 01                	push   $0x1
f01010a8:	50                   	push   %eax
f01010a9:	e8 07 0f 00 00       	call   f0101fb5 <memset>
	page_free(pp0);
f01010ae:	89 34 24             	mov    %esi,(%esp)
f01010b1:	e8 7e fa ff ff       	call   f0100b34 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01010b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01010bd:	e8 00 fa ff ff       	call   f0100ac2 <page_alloc>
f01010c2:	83 c4 10             	add    $0x10,%esp
f01010c5:	85 c0                	test   %eax,%eax
f01010c7:	0f 84 cb 01 00 00    	je     f0101298 <mem_init+0x74f>
	assert(pp && pp0 == pp);
f01010cd:	39 c6                	cmp    %eax,%esi
f01010cf:	0f 85 dc 01 00 00    	jne    f01012b1 <mem_init+0x768>
	c = page2kva(pp);
f01010d5:	e8 1c f8 ff ff       	call   f01008f6 <page2kva>
f01010da:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
		assert(c[i] == 0);
f01010e0:	80 38 00             	cmpb   $0x0,(%eax)
f01010e3:	0f 85 e1 01 00 00    	jne    f01012ca <mem_init+0x781>
f01010e9:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01010ec:	39 c2                	cmp    %eax,%edx
f01010ee:	75 f0                	jne    f01010e0 <mem_init+0x597>
	page_free_list = fl;
f01010f0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010f3:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	page_free(pp0);
f01010f8:	83 ec 0c             	sub    $0xc,%esp
f01010fb:	56                   	push   %esi
f01010fc:	e8 33 fa ff ff       	call   f0100b34 <page_free>
	page_free(pp1);
f0101101:	89 3c 24             	mov    %edi,(%esp)
f0101104:	e8 2b fa ff ff       	call   f0100b34 <page_free>
	page_free(pp2);
f0101109:	83 c4 04             	add    $0x4,%esp
f010110c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010110f:	e8 20 fa ff ff       	call   f0100b34 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101114:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101119:	83 c4 10             	add    $0x10,%esp
f010111c:	e9 c7 01 00 00       	jmp    f01012e8 <mem_init+0x79f>
	assert((pp0 = page_alloc(0)));
f0101121:	68 b5 29 10 f0       	push   $0xf01029b5
f0101126:	68 0a 29 10 f0       	push   $0xf010290a
f010112b:	68 3a 02 00 00       	push   $0x23a
f0101130:	68 d8 28 10 f0       	push   $0xf01028d8
f0101135:	e8 51 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010113a:	68 cb 29 10 f0       	push   $0xf01029cb
f010113f:	68 0a 29 10 f0       	push   $0xf010290a
f0101144:	68 3b 02 00 00       	push   $0x23b
f0101149:	68 d8 28 10 f0       	push   $0xf01028d8
f010114e:	e8 38 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101153:	68 e1 29 10 f0       	push   $0xf01029e1
f0101158:	68 0a 29 10 f0       	push   $0xf010290a
f010115d:	68 3c 02 00 00       	push   $0x23c
f0101162:	68 d8 28 10 f0       	push   $0xf01028d8
f0101167:	e8 1f ef ff ff       	call   f010008b <_panic>
	assert(pp1 && pp1 != pp0);
f010116c:	68 f7 29 10 f0       	push   $0xf01029f7
f0101171:	68 0a 29 10 f0       	push   $0xf010290a
f0101176:	68 3f 02 00 00       	push   $0x23f
f010117b:	68 d8 28 10 f0       	push   $0xf01028d8
f0101180:	e8 06 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101185:	68 fc 2b 10 f0       	push   $0xf0102bfc
f010118a:	68 0a 29 10 f0       	push   $0xf010290a
f010118f:	68 40 02 00 00       	push   $0x240
f0101194:	68 d8 28 10 f0       	push   $0xf01028d8
f0101199:	e8 ed ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f010119e:	68 09 2a 10 f0       	push   $0xf0102a09
f01011a3:	68 0a 29 10 f0       	push   $0xf010290a
f01011a8:	68 41 02 00 00       	push   $0x241
f01011ad:	68 d8 28 10 f0       	push   $0xf01028d8
f01011b2:	e8 d4 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011b7:	68 26 2a 10 f0       	push   $0xf0102a26
f01011bc:	68 0a 29 10 f0       	push   $0xf010290a
f01011c1:	68 42 02 00 00       	push   $0x242
f01011c6:	68 d8 28 10 f0       	push   $0xf01028d8
f01011cb:	e8 bb ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01011d0:	68 43 2a 10 f0       	push   $0xf0102a43
f01011d5:	68 0a 29 10 f0       	push   $0xf010290a
f01011da:	68 43 02 00 00       	push   $0x243
f01011df:	68 d8 28 10 f0       	push   $0xf01028d8
f01011e4:	e8 a2 ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011e9:	68 60 2a 10 f0       	push   $0xf0102a60
f01011ee:	68 0a 29 10 f0       	push   $0xf010290a
f01011f3:	68 4a 02 00 00       	push   $0x24a
f01011f8:	68 d8 28 10 f0       	push   $0xf01028d8
f01011fd:	e8 89 ee ff ff       	call   f010008b <_panic>
	assert((pp0 = page_alloc(0)));
f0101202:	68 b5 29 10 f0       	push   $0xf01029b5
f0101207:	68 0a 29 10 f0       	push   $0xf010290a
f010120c:	68 51 02 00 00       	push   $0x251
f0101211:	68 d8 28 10 f0       	push   $0xf01028d8
f0101216:	e8 70 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010121b:	68 cb 29 10 f0       	push   $0xf01029cb
f0101220:	68 0a 29 10 f0       	push   $0xf010290a
f0101225:	68 52 02 00 00       	push   $0x252
f010122a:	68 d8 28 10 f0       	push   $0xf01028d8
f010122f:	e8 57 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101234:	68 e1 29 10 f0       	push   $0xf01029e1
f0101239:	68 0a 29 10 f0       	push   $0xf010290a
f010123e:	68 53 02 00 00       	push   $0x253
f0101243:	68 d8 28 10 f0       	push   $0xf01028d8
f0101248:	e8 3e ee ff ff       	call   f010008b <_panic>
	assert(pp1 && pp1 != pp0);
f010124d:	68 f7 29 10 f0       	push   $0xf01029f7
f0101252:	68 0a 29 10 f0       	push   $0xf010290a
f0101257:	68 55 02 00 00       	push   $0x255
f010125c:	68 d8 28 10 f0       	push   $0xf01028d8
f0101261:	e8 25 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101266:	68 fc 2b 10 f0       	push   $0xf0102bfc
f010126b:	68 0a 29 10 f0       	push   $0xf010290a
f0101270:	68 56 02 00 00       	push   $0x256
f0101275:	68 d8 28 10 f0       	push   $0xf01028d8
f010127a:	e8 0c ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010127f:	68 60 2a 10 f0       	push   $0xf0102a60
f0101284:	68 0a 29 10 f0       	push   $0xf010290a
f0101289:	68 57 02 00 00       	push   $0x257
f010128e:	68 d8 28 10 f0       	push   $0xf01028d8
f0101293:	e8 f3 ed ff ff       	call   f010008b <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101298:	68 6f 2a 10 f0       	push   $0xf0102a6f
f010129d:	68 0a 29 10 f0       	push   $0xf010290a
f01012a2:	68 5c 02 00 00       	push   $0x25c
f01012a7:	68 d8 28 10 f0       	push   $0xf01028d8
f01012ac:	e8 da ed ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01012b1:	68 8d 2a 10 f0       	push   $0xf0102a8d
f01012b6:	68 0a 29 10 f0       	push   $0xf010290a
f01012bb:	68 5d 02 00 00       	push   $0x25d
f01012c0:	68 d8 28 10 f0       	push   $0xf01028d8
f01012c5:	e8 c1 ed ff ff       	call   f010008b <_panic>
		assert(c[i] == 0);
f01012ca:	68 9d 2a 10 f0       	push   $0xf0102a9d
f01012cf:	68 0a 29 10 f0       	push   $0xf010290a
f01012d4:	68 60 02 00 00       	push   $0x260
f01012d9:	68 d8 28 10 f0       	push   $0xf01028d8
f01012de:	e8 a8 ed ff ff       	call   f010008b <_panic>
		--nfree;
f01012e3:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012e6:	8b 00                	mov    (%eax),%eax
f01012e8:	85 c0                	test   %eax,%eax
f01012ea:	75 f7                	jne    f01012e3 <mem_init+0x79a>
	assert(nfree == 0);
f01012ec:	85 db                	test   %ebx,%ebx
f01012ee:	75 73                	jne    f0101363 <mem_init+0x81a>
	cprintf("check_page_alloc() succeeded!\n");
f01012f0:	83 ec 0c             	sub    $0xc,%esp
f01012f3:	68 1c 2c 10 f0       	push   $0xf0102c1c
f01012f8:	e8 e8 01 00 00       	call   f01014e5 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101304:	e8 b9 f7 ff ff       	call   f0100ac2 <page_alloc>
f0101309:	89 c3                	mov    %eax,%ebx
f010130b:	83 c4 10             	add    $0x10,%esp
f010130e:	85 c0                	test   %eax,%eax
f0101310:	74 6a                	je     f010137c <mem_init+0x833>
	assert((pp1 = page_alloc(0)));
f0101312:	83 ec 0c             	sub    $0xc,%esp
f0101315:	6a 00                	push   $0x0
f0101317:	e8 a6 f7 ff ff       	call   f0100ac2 <page_alloc>
f010131c:	89 c6                	mov    %eax,%esi
f010131e:	83 c4 10             	add    $0x10,%esp
f0101321:	85 c0                	test   %eax,%eax
f0101323:	74 70                	je     f0101395 <mem_init+0x84c>
	assert((pp2 = page_alloc(0)));
f0101325:	83 ec 0c             	sub    $0xc,%esp
f0101328:	6a 00                	push   $0x0
f010132a:	e8 93 f7 ff ff       	call   f0100ac2 <page_alloc>
f010132f:	83 c4 10             	add    $0x10,%esp
f0101332:	85 c0                	test   %eax,%eax
f0101334:	74 78                	je     f01013ae <mem_init+0x865>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101336:	39 f3                	cmp    %esi,%ebx
f0101338:	0f 84 89 00 00 00    	je     f01013c7 <mem_init+0x87e>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010133e:	39 c3                	cmp    %eax,%ebx
f0101340:	74 08                	je     f010134a <mem_init+0x801>
f0101342:	39 c6                	cmp    %eax,%esi
f0101344:	0f 85 96 00 00 00    	jne    f01013e0 <mem_init+0x897>
f010134a:	68 fc 2b 10 f0       	push   $0xf0102bfc
f010134f:	68 0a 29 10 f0       	push   $0xf010290a
f0101354:	68 cc 02 00 00       	push   $0x2cc
f0101359:	68 d8 28 10 f0       	push   $0xf01028d8
f010135e:	e8 28 ed ff ff       	call   f010008b <_panic>
	assert(nfree == 0);
f0101363:	68 a7 2a 10 f0       	push   $0xf0102aa7
f0101368:	68 0a 29 10 f0       	push   $0xf010290a
f010136d:	68 6d 02 00 00       	push   $0x26d
f0101372:	68 d8 28 10 f0       	push   $0xf01028d8
f0101377:	e8 0f ed ff ff       	call   f010008b <_panic>
	assert((pp0 = page_alloc(0)));
f010137c:	68 b5 29 10 f0       	push   $0xf01029b5
f0101381:	68 0a 29 10 f0       	push   $0xf010290a
f0101386:	68 c6 02 00 00       	push   $0x2c6
f010138b:	68 d8 28 10 f0       	push   $0xf01028d8
f0101390:	e8 f6 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101395:	68 cb 29 10 f0       	push   $0xf01029cb
f010139a:	68 0a 29 10 f0       	push   $0xf010290a
f010139f:	68 c7 02 00 00       	push   $0x2c7
f01013a4:	68 d8 28 10 f0       	push   $0xf01028d8
f01013a9:	e8 dd ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013ae:	68 e1 29 10 f0       	push   $0xf01029e1
f01013b3:	68 0a 29 10 f0       	push   $0xf010290a
f01013b8:	68 c8 02 00 00       	push   $0x2c8
f01013bd:	68 d8 28 10 f0       	push   $0xf01028d8
f01013c2:	e8 c4 ec ff ff       	call   f010008b <_panic>
	assert(pp1 && pp1 != pp0);
f01013c7:	68 f7 29 10 f0       	push   $0xf01029f7
f01013cc:	68 0a 29 10 f0       	push   $0xf010290a
f01013d1:	68 cb 02 00 00       	push   $0x2cb
f01013d6:	68 d8 28 10 f0       	push   $0xf01028d8
f01013db:	e8 ab ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f01013e0:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01013e7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013ea:	83 ec 0c             	sub    $0xc,%esp
f01013ed:	6a 00                	push   $0x0
f01013ef:	e8 ce f6 ff ff       	call   f0100ac2 <page_alloc>
f01013f4:	83 c4 10             	add    $0x10,%esp
f01013f7:	85 c0                	test   %eax,%eax
f01013f9:	74 19                	je     f0101414 <mem_init+0x8cb>
f01013fb:	68 60 2a 10 f0       	push   $0xf0102a60
f0101400:	68 0a 29 10 f0       	push   $0xf010290a
f0101405:	68 d3 02 00 00       	push   $0x2d3
f010140a:	68 d8 28 10 f0       	push   $0xf01028d8
f010140f:	e8 77 ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101414:	68 3c 2c 10 f0       	push   $0xf0102c3c
f0101419:	68 0a 29 10 f0       	push   $0xf010290a
f010141e:	68 d9 02 00 00       	push   $0x2d9
f0101423:	68 d8 28 10 f0       	push   $0xf01028d8
f0101428:	e8 5e ec ff ff       	call   f010008b <_panic>

f010142d <page_decref>:
{
f010142d:	55                   	push   %ebp
f010142e:	89 e5                	mov    %esp,%ebp
f0101430:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101433:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101437:	83 e8 01             	sub    $0x1,%eax
f010143a:	66 89 42 04          	mov    %ax,0x4(%edx)
f010143e:	66 85 c0             	test   %ax,%ax
f0101441:	74 02                	je     f0101445 <page_decref+0x18>
}
f0101443:	c9                   	leave  
f0101444:	c3                   	ret    
		page_free(pp);
f0101445:	52                   	push   %edx
f0101446:	e8 e9 f6 ff ff       	call   f0100b34 <page_free>
f010144b:	83 c4 04             	add    $0x4,%esp
}
f010144e:	eb f3                	jmp    f0101443 <page_decref+0x16>

f0101450 <pgdir_walk>:
{
f0101450:	55                   	push   %ebp
f0101451:	89 e5                	mov    %esp,%ebp
}
f0101453:	b8 00 00 00 00       	mov    $0x0,%eax
f0101458:	5d                   	pop    %ebp
f0101459:	c3                   	ret    

f010145a <page_insert>:
{
f010145a:	55                   	push   %ebp
f010145b:	89 e5                	mov    %esp,%ebp
}
f010145d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101462:	5d                   	pop    %ebp
f0101463:	c3                   	ret    

f0101464 <page_lookup>:
{
f0101464:	55                   	push   %ebp
f0101465:	89 e5                	mov    %esp,%ebp
}
f0101467:	b8 00 00 00 00       	mov    $0x0,%eax
f010146c:	5d                   	pop    %ebp
f010146d:	c3                   	ret    

f010146e <page_remove>:
{
f010146e:	55                   	push   %ebp
f010146f:	89 e5                	mov    %esp,%ebp
}
f0101471:	5d                   	pop    %ebp
f0101472:	c3                   	ret    

f0101473 <tlb_invalidate>:
{
f0101473:	55                   	push   %ebp
f0101474:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101476:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101479:	0f 01 38             	invlpg (%eax)
}
f010147c:	5d                   	pop    %ebp
f010147d:	c3                   	ret    

f010147e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010147e:	55                   	push   %ebp
f010147f:	89 e5                	mov    %esp,%ebp
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101481:	8b 45 08             	mov    0x8(%ebp),%eax
f0101484:	ba 70 00 00 00       	mov    $0x70,%edx
f0101489:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010148a:	ba 71 00 00 00       	mov    $0x71,%edx
f010148f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0101490:	0f b6 c0             	movzbl %al,%eax
}
f0101493:	5d                   	pop    %ebp
f0101494:	c3                   	ret    

f0101495 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101495:	55                   	push   %ebp
f0101496:	89 e5                	mov    %esp,%ebp
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101498:	8b 45 08             	mov    0x8(%ebp),%eax
f010149b:	ba 70 00 00 00       	mov    $0x70,%edx
f01014a0:	ee                   	out    %al,(%dx)
f01014a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014a4:	ba 71 00 00 00       	mov    $0x71,%edx
f01014a9:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014aa:	5d                   	pop    %ebp
f01014ab:	c3                   	ret    

f01014ac <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01014ac:	55                   	push   %ebp
f01014ad:	89 e5                	mov    %esp,%ebp
f01014af:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01014b2:	ff 75 08             	pushl  0x8(%ebp)
f01014b5:	e8 55 f1 ff ff       	call   f010060f <cputchar>
	*cnt++;
}
f01014ba:	83 c4 10             	add    $0x10,%esp
f01014bd:	c9                   	leave  
f01014be:	c3                   	ret    

f01014bf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01014bf:	55                   	push   %ebp
f01014c0:	89 e5                	mov    %esp,%ebp
f01014c2:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01014c5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01014cc:	ff 75 0c             	pushl  0xc(%ebp)
f01014cf:	ff 75 08             	pushl  0x8(%ebp)
f01014d2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01014d5:	50                   	push   %eax
f01014d6:	68 ac 14 10 f0       	push   $0xf01014ac
f01014db:	e8 c5 03 00 00       	call   f01018a5 <vprintfmt>
	return cnt;
}
f01014e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014e3:	c9                   	leave  
f01014e4:	c3                   	ret    

f01014e5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01014e5:	55                   	push   %ebp
f01014e6:	89 e5                	mov    %esp,%ebp
f01014e8:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01014eb:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01014ee:	50                   	push   %eax
f01014ef:	ff 75 08             	pushl  0x8(%ebp)
f01014f2:	e8 c8 ff ff ff       	call   f01014bf <vcprintf>
	va_end(ap);

	return cnt;
}
f01014f7:	c9                   	leave  
f01014f8:	c3                   	ret    

f01014f9 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01014f9:	55                   	push   %ebp
f01014fa:	89 e5                	mov    %esp,%ebp
f01014fc:	57                   	push   %edi
f01014fd:	56                   	push   %esi
f01014fe:	53                   	push   %ebx
f01014ff:	83 ec 14             	sub    $0x14,%esp
f0101502:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101505:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101508:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010150b:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010150e:	8b 32                	mov    (%edx),%esi
f0101510:	8b 01                	mov    (%ecx),%eax
f0101512:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101515:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010151c:	eb 2f                	jmp    f010154d <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f010151e:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0101521:	39 c6                	cmp    %eax,%esi
f0101523:	7f 49                	jg     f010156e <stab_binsearch+0x75>
f0101525:	0f b6 0a             	movzbl (%edx),%ecx
f0101528:	83 ea 0c             	sub    $0xc,%edx
f010152b:	39 f9                	cmp    %edi,%ecx
f010152d:	75 ef                	jne    f010151e <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010152f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101532:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101535:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101539:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010153c:	73 35                	jae    f0101573 <stab_binsearch+0x7a>
			*region_left = m;
f010153e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101541:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0101543:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0101546:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f010154d:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101550:	7f 4e                	jg     f01015a0 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0101552:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101555:	01 f0                	add    %esi,%eax
f0101557:	89 c3                	mov    %eax,%ebx
f0101559:	c1 eb 1f             	shr    $0x1f,%ebx
f010155c:	01 c3                	add    %eax,%ebx
f010155e:	d1 fb                	sar    %ebx
f0101560:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101563:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101566:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010156a:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f010156c:	eb b3                	jmp    f0101521 <stab_binsearch+0x28>
			l = true_m + 1;
f010156e:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0101571:	eb da                	jmp    f010154d <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0101573:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101576:	76 14                	jbe    f010158c <stab_binsearch+0x93>
			*region_right = m - 1;
f0101578:	83 e8 01             	sub    $0x1,%eax
f010157b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010157e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101581:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0101583:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010158a:	eb c1                	jmp    f010154d <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010158c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010158f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101591:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101595:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0101597:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010159e:	eb ad                	jmp    f010154d <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01015a0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01015a4:	74 16                	je     f01015bc <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015a9:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01015ab:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015ae:	8b 0e                	mov    (%esi),%ecx
f01015b0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01015b3:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01015b6:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01015ba:	eb 12                	jmp    f01015ce <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01015bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015bf:	8b 00                	mov    (%eax),%eax
f01015c1:	83 e8 01             	sub    $0x1,%eax
f01015c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01015c7:	89 07                	mov    %eax,(%edi)
f01015c9:	eb 16                	jmp    f01015e1 <stab_binsearch+0xe8>
		     l--)
f01015cb:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01015ce:	39 c1                	cmp    %eax,%ecx
f01015d0:	7d 0a                	jge    f01015dc <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01015d2:	0f b6 1a             	movzbl (%edx),%ebx
f01015d5:	83 ea 0c             	sub    $0xc,%edx
f01015d8:	39 fb                	cmp    %edi,%ebx
f01015da:	75 ef                	jne    f01015cb <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01015dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01015df:	89 07                	mov    %eax,(%edi)
	}
}
f01015e1:	83 c4 14             	add    $0x14,%esp
f01015e4:	5b                   	pop    %ebx
f01015e5:	5e                   	pop    %esi
f01015e6:	5f                   	pop    %edi
f01015e7:	5d                   	pop    %ebp
f01015e8:	c3                   	ret    

f01015e9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01015e9:	55                   	push   %ebp
f01015ea:	89 e5                	mov    %esp,%ebp
f01015ec:	57                   	push   %edi
f01015ed:	56                   	push   %esi
f01015ee:	53                   	push   %ebx
f01015ef:	83 ec 1c             	sub    $0x1c,%esp
f01015f2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015f5:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01015f8:	c7 06 6c 2c 10 f0    	movl   $0xf0102c6c,(%esi)
	info->eip_line = 0;
f01015fe:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101605:	c7 46 08 6c 2c 10 f0 	movl   $0xf0102c6c,0x8(%esi)
	info->eip_fn_namelen = 9;
f010160c:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0101613:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101616:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010161d:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0101623:	0f 86 df 00 00 00    	jbe    f0101708 <debuginfo_eip+0x11f>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101629:	b8 2d 9d 10 f0       	mov    $0xf0109d2d,%eax
f010162e:	3d ed 7f 10 f0       	cmp    $0xf0107fed,%eax
f0101633:	0f 86 61 01 00 00    	jbe    f010179a <debuginfo_eip+0x1b1>
f0101639:	80 3d 2c 9d 10 f0 00 	cmpb   $0x0,0xf0109d2c
f0101640:	0f 85 5b 01 00 00    	jne    f01017a1 <debuginfo_eip+0x1b8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101646:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010164d:	b8 ec 7f 10 f0       	mov    $0xf0107fec,%eax
f0101652:	2d b0 2e 10 f0       	sub    $0xf0102eb0,%eax
f0101657:	c1 f8 02             	sar    $0x2,%eax
f010165a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101660:	83 e8 01             	sub    $0x1,%eax
f0101663:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101666:	83 ec 08             	sub    $0x8,%esp
f0101669:	57                   	push   %edi
f010166a:	6a 64                	push   $0x64
f010166c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010166f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101672:	b8 b0 2e 10 f0       	mov    $0xf0102eb0,%eax
f0101677:	e8 7d fe ff ff       	call   f01014f9 <stab_binsearch>
	if (lfile == 0)
f010167c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010167f:	83 c4 10             	add    $0x10,%esp
f0101682:	85 c0                	test   %eax,%eax
f0101684:	0f 84 1e 01 00 00    	je     f01017a8 <debuginfo_eip+0x1bf>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010168a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010168d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101690:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101693:	83 ec 08             	sub    $0x8,%esp
f0101696:	57                   	push   %edi
f0101697:	6a 24                	push   $0x24
f0101699:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010169c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010169f:	b8 b0 2e 10 f0       	mov    $0xf0102eb0,%eax
f01016a4:	e8 50 fe ff ff       	call   f01014f9 <stab_binsearch>

	if (lfun <= rfun) {
f01016a9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01016ac:	83 c4 10             	add    $0x10,%esp
f01016af:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01016b2:	7f 68                	jg     f010171c <debuginfo_eip+0x133>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01016b4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01016b7:	c1 e0 02             	shl    $0x2,%eax
f01016ba:	8d 90 b0 2e 10 f0    	lea    -0xfefd150(%eax),%edx
f01016c0:	8b 88 b0 2e 10 f0    	mov    -0xfefd150(%eax),%ecx
f01016c6:	b8 2d 9d 10 f0       	mov    $0xf0109d2d,%eax
f01016cb:	2d ed 7f 10 f0       	sub    $0xf0107fed,%eax
f01016d0:	39 c1                	cmp    %eax,%ecx
f01016d2:	73 09                	jae    f01016dd <debuginfo_eip+0xf4>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01016d4:	81 c1 ed 7f 10 f0    	add    $0xf0107fed,%ecx
f01016da:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01016dd:	8b 42 08             	mov    0x8(%edx),%eax
f01016e0:	89 46 10             	mov    %eax,0x10(%esi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01016e3:	83 ec 08             	sub    $0x8,%esp
f01016e6:	6a 3a                	push   $0x3a
f01016e8:	ff 76 08             	pushl  0x8(%esi)
f01016eb:	e8 a9 08 00 00       	call   f0101f99 <strfind>
f01016f0:	2b 46 08             	sub    0x8(%esi),%eax
f01016f3:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01016f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01016f9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01016fc:	8d 04 85 b4 2e 10 f0 	lea    -0xfefd14c(,%eax,4),%eax
f0101703:	83 c4 10             	add    $0x10,%esp
f0101706:	eb 22                	jmp    f010172a <debuginfo_eip+0x141>
  	        panic("User address");
f0101708:	83 ec 04             	sub    $0x4,%esp
f010170b:	68 76 2c 10 f0       	push   $0xf0102c76
f0101710:	6a 7f                	push   $0x7f
f0101712:	68 83 2c 10 f0       	push   $0xf0102c83
f0101717:	e8 6f e9 ff ff       	call   f010008b <_panic>
		info->eip_fn_addr = addr;
f010171c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010171f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101722:	eb bf                	jmp    f01016e3 <debuginfo_eip+0xfa>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101724:	83 eb 01             	sub    $0x1,%ebx
f0101727:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f010172a:	39 df                	cmp    %ebx,%edi
f010172c:	7f 33                	jg     f0101761 <debuginfo_eip+0x178>
	       && stabs[lline].n_type != N_SOL
f010172e:	0f b6 10             	movzbl (%eax),%edx
f0101731:	80 fa 84             	cmp    $0x84,%dl
f0101734:	74 0b                	je     f0101741 <debuginfo_eip+0x158>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101736:	80 fa 64             	cmp    $0x64,%dl
f0101739:	75 e9                	jne    f0101724 <debuginfo_eip+0x13b>
f010173b:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f010173f:	74 e3                	je     f0101724 <debuginfo_eip+0x13b>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101741:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101744:	8b 14 85 b0 2e 10 f0 	mov    -0xfefd150(,%eax,4),%edx
f010174b:	b8 2d 9d 10 f0       	mov    $0xf0109d2d,%eax
f0101750:	2d ed 7f 10 f0       	sub    $0xf0107fed,%eax
f0101755:	39 c2                	cmp    %eax,%edx
f0101757:	73 08                	jae    f0101761 <debuginfo_eip+0x178>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101759:	81 c2 ed 7f 10 f0    	add    $0xf0107fed,%edx
f010175f:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101761:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101764:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101767:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010176c:	39 cb                	cmp    %ecx,%ebx
f010176e:	7d 44                	jge    f01017b4 <debuginfo_eip+0x1cb>
		for (lline = lfun + 1;
f0101770:	8d 53 01             	lea    0x1(%ebx),%edx
f0101773:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101776:	8d 04 85 c0 2e 10 f0 	lea    -0xfefd140(,%eax,4),%eax
f010177d:	eb 07                	jmp    f0101786 <debuginfo_eip+0x19d>
			info->eip_fn_narg++;
f010177f:	83 46 14 01          	addl   $0x1,0x14(%esi)
		     lline++)
f0101783:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0101786:	39 d1                	cmp    %edx,%ecx
f0101788:	74 25                	je     f01017af <debuginfo_eip+0x1c6>
f010178a:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010178d:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0101791:	74 ec                	je     f010177f <debuginfo_eip+0x196>
	return 0;
f0101793:	b8 00 00 00 00       	mov    $0x0,%eax
f0101798:	eb 1a                	jmp    f01017b4 <debuginfo_eip+0x1cb>
		return -1;
f010179a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010179f:	eb 13                	jmp    f01017b4 <debuginfo_eip+0x1cb>
f01017a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017a6:	eb 0c                	jmp    f01017b4 <debuginfo_eip+0x1cb>
		return -1;
f01017a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017ad:	eb 05                	jmp    f01017b4 <debuginfo_eip+0x1cb>
	return 0;
f01017af:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01017b7:	5b                   	pop    %ebx
f01017b8:	5e                   	pop    %esi
f01017b9:	5f                   	pop    %edi
f01017ba:	5d                   	pop    %ebp
f01017bb:	c3                   	ret    

f01017bc <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01017bc:	55                   	push   %ebp
f01017bd:	89 e5                	mov    %esp,%ebp
f01017bf:	57                   	push   %edi
f01017c0:	56                   	push   %esi
f01017c1:	53                   	push   %ebx
f01017c2:	83 ec 1c             	sub    $0x1c,%esp
f01017c5:	89 c7                	mov    %eax,%edi
f01017c7:	89 d6                	mov    %edx,%esi
f01017c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017cc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01017d2:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01017d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01017d8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01017dd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01017e0:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01017e3:	39 d3                	cmp    %edx,%ebx
f01017e5:	72 05                	jb     f01017ec <printnum+0x30>
f01017e7:	39 45 10             	cmp    %eax,0x10(%ebp)
f01017ea:	77 7a                	ja     f0101866 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01017ec:	83 ec 0c             	sub    $0xc,%esp
f01017ef:	ff 75 18             	pushl  0x18(%ebp)
f01017f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01017f5:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01017f8:	53                   	push   %ebx
f01017f9:	ff 75 10             	pushl  0x10(%ebp)
f01017fc:	83 ec 08             	sub    $0x8,%esp
f01017ff:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101802:	ff 75 e0             	pushl  -0x20(%ebp)
f0101805:	ff 75 dc             	pushl  -0x24(%ebp)
f0101808:	ff 75 d8             	pushl  -0x28(%ebp)
f010180b:	e8 b0 09 00 00       	call   f01021c0 <__udivdi3>
f0101810:	83 c4 18             	add    $0x18,%esp
f0101813:	52                   	push   %edx
f0101814:	50                   	push   %eax
f0101815:	89 f2                	mov    %esi,%edx
f0101817:	89 f8                	mov    %edi,%eax
f0101819:	e8 9e ff ff ff       	call   f01017bc <printnum>
f010181e:	83 c4 20             	add    $0x20,%esp
f0101821:	eb 13                	jmp    f0101836 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101823:	83 ec 08             	sub    $0x8,%esp
f0101826:	56                   	push   %esi
f0101827:	ff 75 18             	pushl  0x18(%ebp)
f010182a:	ff d7                	call   *%edi
f010182c:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010182f:	83 eb 01             	sub    $0x1,%ebx
f0101832:	85 db                	test   %ebx,%ebx
f0101834:	7f ed                	jg     f0101823 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101836:	83 ec 08             	sub    $0x8,%esp
f0101839:	56                   	push   %esi
f010183a:	83 ec 04             	sub    $0x4,%esp
f010183d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101840:	ff 75 e0             	pushl  -0x20(%ebp)
f0101843:	ff 75 dc             	pushl  -0x24(%ebp)
f0101846:	ff 75 d8             	pushl  -0x28(%ebp)
f0101849:	e8 92 0a 00 00       	call   f01022e0 <__umoddi3>
f010184e:	83 c4 14             	add    $0x14,%esp
f0101851:	0f be 80 91 2c 10 f0 	movsbl -0xfefd36f(%eax),%eax
f0101858:	50                   	push   %eax
f0101859:	ff d7                	call   *%edi
}
f010185b:	83 c4 10             	add    $0x10,%esp
f010185e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101861:	5b                   	pop    %ebx
f0101862:	5e                   	pop    %esi
f0101863:	5f                   	pop    %edi
f0101864:	5d                   	pop    %ebp
f0101865:	c3                   	ret    
f0101866:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101869:	eb c4                	jmp    f010182f <printnum+0x73>

f010186b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010186b:	55                   	push   %ebp
f010186c:	89 e5                	mov    %esp,%ebp
f010186e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101871:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101875:	8b 10                	mov    (%eax),%edx
f0101877:	3b 50 04             	cmp    0x4(%eax),%edx
f010187a:	73 0a                	jae    f0101886 <sprintputch+0x1b>
		*b->buf++ = ch;
f010187c:	8d 4a 01             	lea    0x1(%edx),%ecx
f010187f:	89 08                	mov    %ecx,(%eax)
f0101881:	8b 45 08             	mov    0x8(%ebp),%eax
f0101884:	88 02                	mov    %al,(%edx)
}
f0101886:	5d                   	pop    %ebp
f0101887:	c3                   	ret    

f0101888 <printfmt>:
{
f0101888:	55                   	push   %ebp
f0101889:	89 e5                	mov    %esp,%ebp
f010188b:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010188e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101891:	50                   	push   %eax
f0101892:	ff 75 10             	pushl  0x10(%ebp)
f0101895:	ff 75 0c             	pushl  0xc(%ebp)
f0101898:	ff 75 08             	pushl  0x8(%ebp)
f010189b:	e8 05 00 00 00       	call   f01018a5 <vprintfmt>
}
f01018a0:	83 c4 10             	add    $0x10,%esp
f01018a3:	c9                   	leave  
f01018a4:	c3                   	ret    

f01018a5 <vprintfmt>:
{
f01018a5:	55                   	push   %ebp
f01018a6:	89 e5                	mov    %esp,%ebp
f01018a8:	57                   	push   %edi
f01018a9:	56                   	push   %esi
f01018aa:	53                   	push   %ebx
f01018ab:	83 ec 2c             	sub    $0x2c,%esp
f01018ae:	8b 75 08             	mov    0x8(%ebp),%esi
f01018b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018b4:	8b 7d 10             	mov    0x10(%ebp),%edi
f01018b7:	e9 8c 03 00 00       	jmp    f0101c48 <vprintfmt+0x3a3>
		padc = ' ';
f01018bc:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01018c0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01018c7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01018ce:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01018d5:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01018da:	8d 47 01             	lea    0x1(%edi),%eax
f01018dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01018e0:	0f b6 17             	movzbl (%edi),%edx
f01018e3:	8d 42 dd             	lea    -0x23(%edx),%eax
f01018e6:	3c 55                	cmp    $0x55,%al
f01018e8:	0f 87 dd 03 00 00    	ja     f0101ccb <vprintfmt+0x426>
f01018ee:	0f b6 c0             	movzbl %al,%eax
f01018f1:	ff 24 85 20 2d 10 f0 	jmp    *-0xfefd2e0(,%eax,4)
f01018f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01018fb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01018ff:	eb d9                	jmp    f01018da <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0101901:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0101904:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101908:	eb d0                	jmp    f01018da <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f010190a:	0f b6 d2             	movzbl %dl,%edx
f010190d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101910:	b8 00 00 00 00       	mov    $0x0,%eax
f0101915:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0101918:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010191b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010191f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101922:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101925:	83 f9 09             	cmp    $0x9,%ecx
f0101928:	77 55                	ja     f010197f <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f010192a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010192d:	eb e9                	jmp    f0101918 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f010192f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101932:	8b 00                	mov    (%eax),%eax
f0101934:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101937:	8b 45 14             	mov    0x14(%ebp),%eax
f010193a:	8d 40 04             	lea    0x4(%eax),%eax
f010193d:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101940:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101943:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101947:	79 91                	jns    f01018da <vprintfmt+0x35>
				width = precision, precision = -1;
f0101949:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010194c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010194f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101956:	eb 82                	jmp    f01018da <vprintfmt+0x35>
f0101958:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010195b:	85 c0                	test   %eax,%eax
f010195d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101962:	0f 49 d0             	cmovns %eax,%edx
f0101965:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101968:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010196b:	e9 6a ff ff ff       	jmp    f01018da <vprintfmt+0x35>
f0101970:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101973:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010197a:	e9 5b ff ff ff       	jmp    f01018da <vprintfmt+0x35>
f010197f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101982:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101985:	eb bc                	jmp    f0101943 <vprintfmt+0x9e>
			lflag++;
f0101987:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f010198a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010198d:	e9 48 ff ff ff       	jmp    f01018da <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0101992:	8b 45 14             	mov    0x14(%ebp),%eax
f0101995:	8d 78 04             	lea    0x4(%eax),%edi
f0101998:	83 ec 08             	sub    $0x8,%esp
f010199b:	53                   	push   %ebx
f010199c:	ff 30                	pushl  (%eax)
f010199e:	ff d6                	call   *%esi
			break;
f01019a0:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01019a3:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01019a6:	e9 9a 02 00 00       	jmp    f0101c45 <vprintfmt+0x3a0>
			err = va_arg(ap, int);
f01019ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01019ae:	8d 78 04             	lea    0x4(%eax),%edi
f01019b1:	8b 00                	mov    (%eax),%eax
f01019b3:	99                   	cltd   
f01019b4:	31 d0                	xor    %edx,%eax
f01019b6:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01019b8:	83 f8 07             	cmp    $0x7,%eax
f01019bb:	7f 23                	jg     f01019e0 <vprintfmt+0x13b>
f01019bd:	8b 14 85 80 2e 10 f0 	mov    -0xfefd180(,%eax,4),%edx
f01019c4:	85 d2                	test   %edx,%edx
f01019c6:	74 18                	je     f01019e0 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f01019c8:	52                   	push   %edx
f01019c9:	68 1c 29 10 f0       	push   $0xf010291c
f01019ce:	53                   	push   %ebx
f01019cf:	56                   	push   %esi
f01019d0:	e8 b3 fe ff ff       	call   f0101888 <printfmt>
f01019d5:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01019d8:	89 7d 14             	mov    %edi,0x14(%ebp)
f01019db:	e9 65 02 00 00       	jmp    f0101c45 <vprintfmt+0x3a0>
				printfmt(putch, putdat, "error %d", err);
f01019e0:	50                   	push   %eax
f01019e1:	68 a9 2c 10 f0       	push   $0xf0102ca9
f01019e6:	53                   	push   %ebx
f01019e7:	56                   	push   %esi
f01019e8:	e8 9b fe ff ff       	call   f0101888 <printfmt>
f01019ed:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01019f0:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01019f3:	e9 4d 02 00 00       	jmp    f0101c45 <vprintfmt+0x3a0>
			if ((p = va_arg(ap, char *)) == NULL)
f01019f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01019fb:	83 c0 04             	add    $0x4,%eax
f01019fe:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a01:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a04:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101a06:	85 ff                	test   %edi,%edi
f0101a08:	b8 a2 2c 10 f0       	mov    $0xf0102ca2,%eax
f0101a0d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101a10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a14:	0f 8e bd 00 00 00    	jle    f0101ad7 <vprintfmt+0x232>
f0101a1a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101a1e:	75 0e                	jne    f0101a2e <vprintfmt+0x189>
f0101a20:	89 75 08             	mov    %esi,0x8(%ebp)
f0101a23:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101a26:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101a29:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101a2c:	eb 6d                	jmp    f0101a9b <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101a2e:	83 ec 08             	sub    $0x8,%esp
f0101a31:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a34:	57                   	push   %edi
f0101a35:	e8 1b 04 00 00       	call   f0101e55 <strnlen>
f0101a3a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101a3d:	29 c1                	sub    %eax,%ecx
f0101a3f:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0101a42:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101a45:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101a49:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a4c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101a4f:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101a51:	eb 0f                	jmp    f0101a62 <vprintfmt+0x1bd>
					putch(padc, putdat);
f0101a53:	83 ec 08             	sub    $0x8,%esp
f0101a56:	53                   	push   %ebx
f0101a57:	ff 75 e0             	pushl  -0x20(%ebp)
f0101a5a:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101a5c:	83 ef 01             	sub    $0x1,%edi
f0101a5f:	83 c4 10             	add    $0x10,%esp
f0101a62:	85 ff                	test   %edi,%edi
f0101a64:	7f ed                	jg     f0101a53 <vprintfmt+0x1ae>
f0101a66:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101a69:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101a6c:	85 c9                	test   %ecx,%ecx
f0101a6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a73:	0f 49 c1             	cmovns %ecx,%eax
f0101a76:	29 c1                	sub    %eax,%ecx
f0101a78:	89 75 08             	mov    %esi,0x8(%ebp)
f0101a7b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101a7e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101a81:	89 cb                	mov    %ecx,%ebx
f0101a83:	eb 16                	jmp    f0101a9b <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f0101a85:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101a89:	75 31                	jne    f0101abc <vprintfmt+0x217>
					putch(ch, putdat);
f0101a8b:	83 ec 08             	sub    $0x8,%esp
f0101a8e:	ff 75 0c             	pushl  0xc(%ebp)
f0101a91:	50                   	push   %eax
f0101a92:	ff 55 08             	call   *0x8(%ebp)
f0101a95:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101a98:	83 eb 01             	sub    $0x1,%ebx
f0101a9b:	83 c7 01             	add    $0x1,%edi
f0101a9e:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101aa2:	0f be c2             	movsbl %dl,%eax
f0101aa5:	85 c0                	test   %eax,%eax
f0101aa7:	74 59                	je     f0101b02 <vprintfmt+0x25d>
f0101aa9:	85 f6                	test   %esi,%esi
f0101aab:	78 d8                	js     f0101a85 <vprintfmt+0x1e0>
f0101aad:	83 ee 01             	sub    $0x1,%esi
f0101ab0:	79 d3                	jns    f0101a85 <vprintfmt+0x1e0>
f0101ab2:	89 df                	mov    %ebx,%edi
f0101ab4:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ab7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101aba:	eb 37                	jmp    f0101af3 <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101abc:	0f be d2             	movsbl %dl,%edx
f0101abf:	83 ea 20             	sub    $0x20,%edx
f0101ac2:	83 fa 5e             	cmp    $0x5e,%edx
f0101ac5:	76 c4                	jbe    f0101a8b <vprintfmt+0x1e6>
					putch('?', putdat);
f0101ac7:	83 ec 08             	sub    $0x8,%esp
f0101aca:	ff 75 0c             	pushl  0xc(%ebp)
f0101acd:	6a 3f                	push   $0x3f
f0101acf:	ff 55 08             	call   *0x8(%ebp)
f0101ad2:	83 c4 10             	add    $0x10,%esp
f0101ad5:	eb c1                	jmp    f0101a98 <vprintfmt+0x1f3>
f0101ad7:	89 75 08             	mov    %esi,0x8(%ebp)
f0101ada:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101add:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101ae0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101ae3:	eb b6                	jmp    f0101a9b <vprintfmt+0x1f6>
				putch(' ', putdat);
f0101ae5:	83 ec 08             	sub    $0x8,%esp
f0101ae8:	53                   	push   %ebx
f0101ae9:	6a 20                	push   $0x20
f0101aeb:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0101aed:	83 ef 01             	sub    $0x1,%edi
f0101af0:	83 c4 10             	add    $0x10,%esp
f0101af3:	85 ff                	test   %edi,%edi
f0101af5:	7f ee                	jg     f0101ae5 <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f0101af7:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101afa:	89 45 14             	mov    %eax,0x14(%ebp)
f0101afd:	e9 43 01 00 00       	jmp    f0101c45 <vprintfmt+0x3a0>
f0101b02:	89 df                	mov    %ebx,%edi
f0101b04:	8b 75 08             	mov    0x8(%ebp),%esi
f0101b07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101b0a:	eb e7                	jmp    f0101af3 <vprintfmt+0x24e>
	if (lflag >= 2)
f0101b0c:	83 f9 01             	cmp    $0x1,%ecx
f0101b0f:	7e 3f                	jle    f0101b50 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f0101b11:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b14:	8b 50 04             	mov    0x4(%eax),%edx
f0101b17:	8b 00                	mov    (%eax),%eax
f0101b19:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101b1c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101b1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b22:	8d 40 08             	lea    0x8(%eax),%eax
f0101b25:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101b28:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101b2c:	79 5c                	jns    f0101b8a <vprintfmt+0x2e5>
				putch('-', putdat);
f0101b2e:	83 ec 08             	sub    $0x8,%esp
f0101b31:	53                   	push   %ebx
f0101b32:	6a 2d                	push   $0x2d
f0101b34:	ff d6                	call   *%esi
				num = -(long long) num;
f0101b36:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101b39:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101b3c:	f7 da                	neg    %edx
f0101b3e:	83 d1 00             	adc    $0x0,%ecx
f0101b41:	f7 d9                	neg    %ecx
f0101b43:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101b46:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101b4b:	e9 db 00 00 00       	jmp    f0101c2b <vprintfmt+0x386>
	else if (lflag)
f0101b50:	85 c9                	test   %ecx,%ecx
f0101b52:	75 1b                	jne    f0101b6f <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0101b54:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b57:	8b 00                	mov    (%eax),%eax
f0101b59:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101b5c:	89 c1                	mov    %eax,%ecx
f0101b5e:	c1 f9 1f             	sar    $0x1f,%ecx
f0101b61:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101b64:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b67:	8d 40 04             	lea    0x4(%eax),%eax
f0101b6a:	89 45 14             	mov    %eax,0x14(%ebp)
f0101b6d:	eb b9                	jmp    f0101b28 <vprintfmt+0x283>
		return va_arg(*ap, long);
f0101b6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b72:	8b 00                	mov    (%eax),%eax
f0101b74:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101b77:	89 c1                	mov    %eax,%ecx
f0101b79:	c1 f9 1f             	sar    $0x1f,%ecx
f0101b7c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101b7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b82:	8d 40 04             	lea    0x4(%eax),%eax
f0101b85:	89 45 14             	mov    %eax,0x14(%ebp)
f0101b88:	eb 9e                	jmp    f0101b28 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0101b8a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101b8d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101b90:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101b95:	e9 91 00 00 00       	jmp    f0101c2b <vprintfmt+0x386>
	if (lflag >= 2)
f0101b9a:	83 f9 01             	cmp    $0x1,%ecx
f0101b9d:	7e 15                	jle    f0101bb4 <vprintfmt+0x30f>
		return va_arg(*ap, unsigned long long);
f0101b9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ba2:	8b 10                	mov    (%eax),%edx
f0101ba4:	8b 48 04             	mov    0x4(%eax),%ecx
f0101ba7:	8d 40 08             	lea    0x8(%eax),%eax
f0101baa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101bad:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101bb2:	eb 77                	jmp    f0101c2b <vprintfmt+0x386>
	else if (lflag)
f0101bb4:	85 c9                	test   %ecx,%ecx
f0101bb6:	75 17                	jne    f0101bcf <vprintfmt+0x32a>
		return va_arg(*ap, unsigned int);
f0101bb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bbb:	8b 10                	mov    (%eax),%edx
f0101bbd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101bc2:	8d 40 04             	lea    0x4(%eax),%eax
f0101bc5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101bc8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101bcd:	eb 5c                	jmp    f0101c2b <vprintfmt+0x386>
		return va_arg(*ap, unsigned long);
f0101bcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bd2:	8b 10                	mov    (%eax),%edx
f0101bd4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101bd9:	8d 40 04             	lea    0x4(%eax),%eax
f0101bdc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101bdf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101be4:	eb 45                	jmp    f0101c2b <vprintfmt+0x386>
			putch('X', putdat);
f0101be6:	83 ec 08             	sub    $0x8,%esp
f0101be9:	53                   	push   %ebx
f0101bea:	6a 58                	push   $0x58
f0101bec:	ff d6                	call   *%esi
			putch('X', putdat);
f0101bee:	83 c4 08             	add    $0x8,%esp
f0101bf1:	53                   	push   %ebx
f0101bf2:	6a 58                	push   $0x58
f0101bf4:	ff d6                	call   *%esi
			putch('X', putdat);
f0101bf6:	83 c4 08             	add    $0x8,%esp
f0101bf9:	53                   	push   %ebx
f0101bfa:	6a 58                	push   $0x58
f0101bfc:	ff d6                	call   *%esi
			break;
f0101bfe:	83 c4 10             	add    $0x10,%esp
f0101c01:	eb 42                	jmp    f0101c45 <vprintfmt+0x3a0>
			putch('0', putdat);
f0101c03:	83 ec 08             	sub    $0x8,%esp
f0101c06:	53                   	push   %ebx
f0101c07:	6a 30                	push   $0x30
f0101c09:	ff d6                	call   *%esi
			putch('x', putdat);
f0101c0b:	83 c4 08             	add    $0x8,%esp
f0101c0e:	53                   	push   %ebx
f0101c0f:	6a 78                	push   $0x78
f0101c11:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101c13:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c16:	8b 10                	mov    (%eax),%edx
f0101c18:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101c1d:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101c20:	8d 40 04             	lea    0x4(%eax),%eax
f0101c23:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101c26:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101c2b:	83 ec 0c             	sub    $0xc,%esp
f0101c2e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101c32:	57                   	push   %edi
f0101c33:	ff 75 e0             	pushl  -0x20(%ebp)
f0101c36:	50                   	push   %eax
f0101c37:	51                   	push   %ecx
f0101c38:	52                   	push   %edx
f0101c39:	89 da                	mov    %ebx,%edx
f0101c3b:	89 f0                	mov    %esi,%eax
f0101c3d:	e8 7a fb ff ff       	call   f01017bc <printnum>
			break;
f0101c42:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101c45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101c48:	83 c7 01             	add    $0x1,%edi
f0101c4b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101c4f:	83 f8 25             	cmp    $0x25,%eax
f0101c52:	0f 84 64 fc ff ff    	je     f01018bc <vprintfmt+0x17>
			if (ch == '\0')
f0101c58:	85 c0                	test   %eax,%eax
f0101c5a:	0f 84 8b 00 00 00    	je     f0101ceb <vprintfmt+0x446>
			putch(ch, putdat);
f0101c60:	83 ec 08             	sub    $0x8,%esp
f0101c63:	53                   	push   %ebx
f0101c64:	50                   	push   %eax
f0101c65:	ff d6                	call   *%esi
f0101c67:	83 c4 10             	add    $0x10,%esp
f0101c6a:	eb dc                	jmp    f0101c48 <vprintfmt+0x3a3>
	if (lflag >= 2)
f0101c6c:	83 f9 01             	cmp    $0x1,%ecx
f0101c6f:	7e 15                	jle    f0101c86 <vprintfmt+0x3e1>
		return va_arg(*ap, unsigned long long);
f0101c71:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c74:	8b 10                	mov    (%eax),%edx
f0101c76:	8b 48 04             	mov    0x4(%eax),%ecx
f0101c79:	8d 40 08             	lea    0x8(%eax),%eax
f0101c7c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101c7f:	b8 10 00 00 00       	mov    $0x10,%eax
f0101c84:	eb a5                	jmp    f0101c2b <vprintfmt+0x386>
	else if (lflag)
f0101c86:	85 c9                	test   %ecx,%ecx
f0101c88:	75 17                	jne    f0101ca1 <vprintfmt+0x3fc>
		return va_arg(*ap, unsigned int);
f0101c8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c8d:	8b 10                	mov    (%eax),%edx
f0101c8f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101c94:	8d 40 04             	lea    0x4(%eax),%eax
f0101c97:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101c9a:	b8 10 00 00 00       	mov    $0x10,%eax
f0101c9f:	eb 8a                	jmp    f0101c2b <vprintfmt+0x386>
		return va_arg(*ap, unsigned long);
f0101ca1:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ca4:	8b 10                	mov    (%eax),%edx
f0101ca6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101cab:	8d 40 04             	lea    0x4(%eax),%eax
f0101cae:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101cb1:	b8 10 00 00 00       	mov    $0x10,%eax
f0101cb6:	e9 70 ff ff ff       	jmp    f0101c2b <vprintfmt+0x386>
			putch(ch, putdat);
f0101cbb:	83 ec 08             	sub    $0x8,%esp
f0101cbe:	53                   	push   %ebx
f0101cbf:	6a 25                	push   $0x25
f0101cc1:	ff d6                	call   *%esi
			break;
f0101cc3:	83 c4 10             	add    $0x10,%esp
f0101cc6:	e9 7a ff ff ff       	jmp    f0101c45 <vprintfmt+0x3a0>
			putch('%', putdat);
f0101ccb:	83 ec 08             	sub    $0x8,%esp
f0101cce:	53                   	push   %ebx
f0101ccf:	6a 25                	push   $0x25
f0101cd1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101cd3:	83 c4 10             	add    $0x10,%esp
f0101cd6:	89 f8                	mov    %edi,%eax
f0101cd8:	eb 03                	jmp    f0101cdd <vprintfmt+0x438>
f0101cda:	83 e8 01             	sub    $0x1,%eax
f0101cdd:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101ce1:	75 f7                	jne    f0101cda <vprintfmt+0x435>
f0101ce3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101ce6:	e9 5a ff ff ff       	jmp    f0101c45 <vprintfmt+0x3a0>
}
f0101ceb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101cee:	5b                   	pop    %ebx
f0101cef:	5e                   	pop    %esi
f0101cf0:	5f                   	pop    %edi
f0101cf1:	5d                   	pop    %ebp
f0101cf2:	c3                   	ret    

f0101cf3 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101cf3:	55                   	push   %ebp
f0101cf4:	89 e5                	mov    %esp,%ebp
f0101cf6:	83 ec 18             	sub    $0x18,%esp
f0101cf9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cfc:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101cff:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d02:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101d06:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101d09:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d10:	85 c0                	test   %eax,%eax
f0101d12:	74 26                	je     f0101d3a <vsnprintf+0x47>
f0101d14:	85 d2                	test   %edx,%edx
f0101d16:	7e 22                	jle    f0101d3a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d18:	ff 75 14             	pushl  0x14(%ebp)
f0101d1b:	ff 75 10             	pushl  0x10(%ebp)
f0101d1e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d21:	50                   	push   %eax
f0101d22:	68 6b 18 10 f0       	push   $0xf010186b
f0101d27:	e8 79 fb ff ff       	call   f01018a5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d2f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d32:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d35:	83 c4 10             	add    $0x10,%esp
}
f0101d38:	c9                   	leave  
f0101d39:	c3                   	ret    
		return -E_INVAL;
f0101d3a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101d3f:	eb f7                	jmp    f0101d38 <vsnprintf+0x45>

f0101d41 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d41:	55                   	push   %ebp
f0101d42:	89 e5                	mov    %esp,%ebp
f0101d44:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d47:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d4a:	50                   	push   %eax
f0101d4b:	ff 75 10             	pushl  0x10(%ebp)
f0101d4e:	ff 75 0c             	pushl  0xc(%ebp)
f0101d51:	ff 75 08             	pushl  0x8(%ebp)
f0101d54:	e8 9a ff ff ff       	call   f0101cf3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101d59:	c9                   	leave  
f0101d5a:	c3                   	ret    

f0101d5b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101d5b:	55                   	push   %ebp
f0101d5c:	89 e5                	mov    %esp,%ebp
f0101d5e:	57                   	push   %edi
f0101d5f:	56                   	push   %esi
f0101d60:	53                   	push   %ebx
f0101d61:	83 ec 0c             	sub    $0xc,%esp
f0101d64:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101d67:	85 c0                	test   %eax,%eax
f0101d69:	74 11                	je     f0101d7c <readline+0x21>
		cprintf("%s", prompt);
f0101d6b:	83 ec 08             	sub    $0x8,%esp
f0101d6e:	50                   	push   %eax
f0101d6f:	68 1c 29 10 f0       	push   $0xf010291c
f0101d74:	e8 6c f7 ff ff       	call   f01014e5 <cprintf>
f0101d79:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101d7c:	83 ec 0c             	sub    $0xc,%esp
f0101d7f:	6a 00                	push   $0x0
f0101d81:	e8 aa e8 ff ff       	call   f0100630 <iscons>
f0101d86:	89 c7                	mov    %eax,%edi
f0101d88:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101d8b:	be 00 00 00 00       	mov    $0x0,%esi
f0101d90:	eb 3f                	jmp    f0101dd1 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101d92:	83 ec 08             	sub    $0x8,%esp
f0101d95:	50                   	push   %eax
f0101d96:	68 a0 2e 10 f0       	push   $0xf0102ea0
f0101d9b:	e8 45 f7 ff ff       	call   f01014e5 <cprintf>
			return NULL;
f0101da0:	83 c4 10             	add    $0x10,%esp
f0101da3:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101da8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101dab:	5b                   	pop    %ebx
f0101dac:	5e                   	pop    %esi
f0101dad:	5f                   	pop    %edi
f0101dae:	5d                   	pop    %ebp
f0101daf:	c3                   	ret    
			if (echoing)
f0101db0:	85 ff                	test   %edi,%edi
f0101db2:	75 05                	jne    f0101db9 <readline+0x5e>
			i--;
f0101db4:	83 ee 01             	sub    $0x1,%esi
f0101db7:	eb 18                	jmp    f0101dd1 <readline+0x76>
				cputchar('\b');
f0101db9:	83 ec 0c             	sub    $0xc,%esp
f0101dbc:	6a 08                	push   $0x8
f0101dbe:	e8 4c e8 ff ff       	call   f010060f <cputchar>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	eb ec                	jmp    f0101db4 <readline+0x59>
			buf[i++] = c;
f0101dc8:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101dce:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0101dd1:	e8 49 e8 ff ff       	call   f010061f <getchar>
f0101dd6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101dd8:	85 c0                	test   %eax,%eax
f0101dda:	78 b6                	js     f0101d92 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101ddc:	83 f8 08             	cmp    $0x8,%eax
f0101ddf:	0f 94 c2             	sete   %dl
f0101de2:	83 f8 7f             	cmp    $0x7f,%eax
f0101de5:	0f 94 c0             	sete   %al
f0101de8:	08 c2                	or     %al,%dl
f0101dea:	74 04                	je     f0101df0 <readline+0x95>
f0101dec:	85 f6                	test   %esi,%esi
f0101dee:	7f c0                	jg     f0101db0 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101df0:	83 fb 1f             	cmp    $0x1f,%ebx
f0101df3:	7e 1a                	jle    f0101e0f <readline+0xb4>
f0101df5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101dfb:	7f 12                	jg     f0101e0f <readline+0xb4>
			if (echoing)
f0101dfd:	85 ff                	test   %edi,%edi
f0101dff:	74 c7                	je     f0101dc8 <readline+0x6d>
				cputchar(c);
f0101e01:	83 ec 0c             	sub    $0xc,%esp
f0101e04:	53                   	push   %ebx
f0101e05:	e8 05 e8 ff ff       	call   f010060f <cputchar>
f0101e0a:	83 c4 10             	add    $0x10,%esp
f0101e0d:	eb b9                	jmp    f0101dc8 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0101e0f:	83 fb 0a             	cmp    $0xa,%ebx
f0101e12:	74 05                	je     f0101e19 <readline+0xbe>
f0101e14:	83 fb 0d             	cmp    $0xd,%ebx
f0101e17:	75 b8                	jne    f0101dd1 <readline+0x76>
			if (echoing)
f0101e19:	85 ff                	test   %edi,%edi
f0101e1b:	75 11                	jne    f0101e2e <readline+0xd3>
			buf[i] = 0;
f0101e1d:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101e24:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
f0101e29:	e9 7a ff ff ff       	jmp    f0101da8 <readline+0x4d>
				cputchar('\n');
f0101e2e:	83 ec 0c             	sub    $0xc,%esp
f0101e31:	6a 0a                	push   $0xa
f0101e33:	e8 d7 e7 ff ff       	call   f010060f <cputchar>
f0101e38:	83 c4 10             	add    $0x10,%esp
f0101e3b:	eb e0                	jmp    f0101e1d <readline+0xc2>

f0101e3d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e3d:	55                   	push   %ebp
f0101e3e:	89 e5                	mov    %esp,%ebp
f0101e40:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e43:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e48:	eb 03                	jmp    f0101e4d <strlen+0x10>
		n++;
f0101e4a:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101e4d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e51:	75 f7                	jne    f0101e4a <strlen+0xd>
	return n;
}
f0101e53:	5d                   	pop    %ebp
f0101e54:	c3                   	ret    

f0101e55 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e55:	55                   	push   %ebp
f0101e56:	89 e5                	mov    %esp,%ebp
f0101e58:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e5b:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e63:	eb 03                	jmp    f0101e68 <strnlen+0x13>
		n++;
f0101e65:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e68:	39 d0                	cmp    %edx,%eax
f0101e6a:	74 06                	je     f0101e72 <strnlen+0x1d>
f0101e6c:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101e70:	75 f3                	jne    f0101e65 <strnlen+0x10>
	return n;
}
f0101e72:	5d                   	pop    %ebp
f0101e73:	c3                   	ret    

f0101e74 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101e74:	55                   	push   %ebp
f0101e75:	89 e5                	mov    %esp,%ebp
f0101e77:	53                   	push   %ebx
f0101e78:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e7b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101e7e:	89 c2                	mov    %eax,%edx
f0101e80:	83 c1 01             	add    $0x1,%ecx
f0101e83:	83 c2 01             	add    $0x1,%edx
f0101e86:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101e8a:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101e8d:	84 db                	test   %bl,%bl
f0101e8f:	75 ef                	jne    f0101e80 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101e91:	5b                   	pop    %ebx
f0101e92:	5d                   	pop    %ebp
f0101e93:	c3                   	ret    

f0101e94 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101e94:	55                   	push   %ebp
f0101e95:	89 e5                	mov    %esp,%ebp
f0101e97:	53                   	push   %ebx
f0101e98:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101e9b:	53                   	push   %ebx
f0101e9c:	e8 9c ff ff ff       	call   f0101e3d <strlen>
f0101ea1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101ea4:	ff 75 0c             	pushl  0xc(%ebp)
f0101ea7:	01 d8                	add    %ebx,%eax
f0101ea9:	50                   	push   %eax
f0101eaa:	e8 c5 ff ff ff       	call   f0101e74 <strcpy>
	return dst;
}
f0101eaf:	89 d8                	mov    %ebx,%eax
f0101eb1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101eb4:	c9                   	leave  
f0101eb5:	c3                   	ret    

f0101eb6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101eb6:	55                   	push   %ebp
f0101eb7:	89 e5                	mov    %esp,%ebp
f0101eb9:	56                   	push   %esi
f0101eba:	53                   	push   %ebx
f0101ebb:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ebe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101ec1:	89 f3                	mov    %esi,%ebx
f0101ec3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ec6:	89 f2                	mov    %esi,%edx
f0101ec8:	eb 0f                	jmp    f0101ed9 <strncpy+0x23>
		*dst++ = *src;
f0101eca:	83 c2 01             	add    $0x1,%edx
f0101ecd:	0f b6 01             	movzbl (%ecx),%eax
f0101ed0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101ed3:	80 39 01             	cmpb   $0x1,(%ecx)
f0101ed6:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101ed9:	39 da                	cmp    %ebx,%edx
f0101edb:	75 ed                	jne    f0101eca <strncpy+0x14>
	}
	return ret;
}
f0101edd:	89 f0                	mov    %esi,%eax
f0101edf:	5b                   	pop    %ebx
f0101ee0:	5e                   	pop    %esi
f0101ee1:	5d                   	pop    %ebp
f0101ee2:	c3                   	ret    

f0101ee3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101ee3:	55                   	push   %ebp
f0101ee4:	89 e5                	mov    %esp,%ebp
f0101ee6:	56                   	push   %esi
f0101ee7:	53                   	push   %ebx
f0101ee8:	8b 75 08             	mov    0x8(%ebp),%esi
f0101eeb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101eee:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101ef1:	89 f0                	mov    %esi,%eax
f0101ef3:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101ef7:	85 c9                	test   %ecx,%ecx
f0101ef9:	75 0b                	jne    f0101f06 <strlcpy+0x23>
f0101efb:	eb 17                	jmp    f0101f14 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101efd:	83 c2 01             	add    $0x1,%edx
f0101f00:	83 c0 01             	add    $0x1,%eax
f0101f03:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101f06:	39 d8                	cmp    %ebx,%eax
f0101f08:	74 07                	je     f0101f11 <strlcpy+0x2e>
f0101f0a:	0f b6 0a             	movzbl (%edx),%ecx
f0101f0d:	84 c9                	test   %cl,%cl
f0101f0f:	75 ec                	jne    f0101efd <strlcpy+0x1a>
		*dst = '\0';
f0101f11:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f14:	29 f0                	sub    %esi,%eax
}
f0101f16:	5b                   	pop    %ebx
f0101f17:	5e                   	pop    %esi
f0101f18:	5d                   	pop    %ebp
f0101f19:	c3                   	ret    

f0101f1a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f1a:	55                   	push   %ebp
f0101f1b:	89 e5                	mov    %esp,%ebp
f0101f1d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f20:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f23:	eb 06                	jmp    f0101f2b <strcmp+0x11>
		p++, q++;
f0101f25:	83 c1 01             	add    $0x1,%ecx
f0101f28:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101f2b:	0f b6 01             	movzbl (%ecx),%eax
f0101f2e:	84 c0                	test   %al,%al
f0101f30:	74 04                	je     f0101f36 <strcmp+0x1c>
f0101f32:	3a 02                	cmp    (%edx),%al
f0101f34:	74 ef                	je     f0101f25 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f36:	0f b6 c0             	movzbl %al,%eax
f0101f39:	0f b6 12             	movzbl (%edx),%edx
f0101f3c:	29 d0                	sub    %edx,%eax
}
f0101f3e:	5d                   	pop    %ebp
f0101f3f:	c3                   	ret    

f0101f40 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f40:	55                   	push   %ebp
f0101f41:	89 e5                	mov    %esp,%ebp
f0101f43:	53                   	push   %ebx
f0101f44:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f47:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f4a:	89 c3                	mov    %eax,%ebx
f0101f4c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f4f:	eb 06                	jmp    f0101f57 <strncmp+0x17>
		n--, p++, q++;
f0101f51:	83 c0 01             	add    $0x1,%eax
f0101f54:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101f57:	39 d8                	cmp    %ebx,%eax
f0101f59:	74 16                	je     f0101f71 <strncmp+0x31>
f0101f5b:	0f b6 08             	movzbl (%eax),%ecx
f0101f5e:	84 c9                	test   %cl,%cl
f0101f60:	74 04                	je     f0101f66 <strncmp+0x26>
f0101f62:	3a 0a                	cmp    (%edx),%cl
f0101f64:	74 eb                	je     f0101f51 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f66:	0f b6 00             	movzbl (%eax),%eax
f0101f69:	0f b6 12             	movzbl (%edx),%edx
f0101f6c:	29 d0                	sub    %edx,%eax
}
f0101f6e:	5b                   	pop    %ebx
f0101f6f:	5d                   	pop    %ebp
f0101f70:	c3                   	ret    
		return 0;
f0101f71:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f76:	eb f6                	jmp    f0101f6e <strncmp+0x2e>

f0101f78 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101f78:	55                   	push   %ebp
f0101f79:	89 e5                	mov    %esp,%ebp
f0101f7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f7e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101f82:	0f b6 10             	movzbl (%eax),%edx
f0101f85:	84 d2                	test   %dl,%dl
f0101f87:	74 09                	je     f0101f92 <strchr+0x1a>
		if (*s == c)
f0101f89:	38 ca                	cmp    %cl,%dl
f0101f8b:	74 0a                	je     f0101f97 <strchr+0x1f>
	for (; *s; s++)
f0101f8d:	83 c0 01             	add    $0x1,%eax
f0101f90:	eb f0                	jmp    f0101f82 <strchr+0xa>
			return (char *) s;
	return 0;
f0101f92:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101f97:	5d                   	pop    %ebp
f0101f98:	c3                   	ret    

f0101f99 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101f99:	55                   	push   %ebp
f0101f9a:	89 e5                	mov    %esp,%ebp
f0101f9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f9f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fa3:	eb 03                	jmp    f0101fa8 <strfind+0xf>
f0101fa5:	83 c0 01             	add    $0x1,%eax
f0101fa8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101fab:	38 ca                	cmp    %cl,%dl
f0101fad:	74 04                	je     f0101fb3 <strfind+0x1a>
f0101faf:	84 d2                	test   %dl,%dl
f0101fb1:	75 f2                	jne    f0101fa5 <strfind+0xc>
			break;
	return (char *) s;
}
f0101fb3:	5d                   	pop    %ebp
f0101fb4:	c3                   	ret    

f0101fb5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101fb5:	55                   	push   %ebp
f0101fb6:	89 e5                	mov    %esp,%ebp
f0101fb8:	57                   	push   %edi
f0101fb9:	56                   	push   %esi
f0101fba:	53                   	push   %ebx
f0101fbb:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101fbe:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101fc1:	85 c9                	test   %ecx,%ecx
f0101fc3:	74 13                	je     f0101fd8 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101fc5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101fcb:	75 05                	jne    f0101fd2 <memset+0x1d>
f0101fcd:	f6 c1 03             	test   $0x3,%cl
f0101fd0:	74 0d                	je     f0101fdf <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101fd2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101fd5:	fc                   	cld    
f0101fd6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101fd8:	89 f8                	mov    %edi,%eax
f0101fda:	5b                   	pop    %ebx
f0101fdb:	5e                   	pop    %esi
f0101fdc:	5f                   	pop    %edi
f0101fdd:	5d                   	pop    %ebp
f0101fde:	c3                   	ret    
		c &= 0xFF;
f0101fdf:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101fe3:	89 d3                	mov    %edx,%ebx
f0101fe5:	c1 e3 08             	shl    $0x8,%ebx
f0101fe8:	89 d0                	mov    %edx,%eax
f0101fea:	c1 e0 18             	shl    $0x18,%eax
f0101fed:	89 d6                	mov    %edx,%esi
f0101fef:	c1 e6 10             	shl    $0x10,%esi
f0101ff2:	09 f0                	or     %esi,%eax
f0101ff4:	09 c2                	or     %eax,%edx
f0101ff6:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101ff8:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101ffb:	89 d0                	mov    %edx,%eax
f0101ffd:	fc                   	cld    
f0101ffe:	f3 ab                	rep stos %eax,%es:(%edi)
f0102000:	eb d6                	jmp    f0101fd8 <memset+0x23>

f0102002 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102002:	55                   	push   %ebp
f0102003:	89 e5                	mov    %esp,%ebp
f0102005:	57                   	push   %edi
f0102006:	56                   	push   %esi
f0102007:	8b 45 08             	mov    0x8(%ebp),%eax
f010200a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010200d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102010:	39 c6                	cmp    %eax,%esi
f0102012:	73 35                	jae    f0102049 <memmove+0x47>
f0102014:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102017:	39 c2                	cmp    %eax,%edx
f0102019:	76 2e                	jbe    f0102049 <memmove+0x47>
		s += n;
		d += n;
f010201b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010201e:	89 d6                	mov    %edx,%esi
f0102020:	09 fe                	or     %edi,%esi
f0102022:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102028:	74 0c                	je     f0102036 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010202a:	83 ef 01             	sub    $0x1,%edi
f010202d:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0102030:	fd                   	std    
f0102031:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102033:	fc                   	cld    
f0102034:	eb 21                	jmp    f0102057 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102036:	f6 c1 03             	test   $0x3,%cl
f0102039:	75 ef                	jne    f010202a <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010203b:	83 ef 04             	sub    $0x4,%edi
f010203e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102041:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0102044:	fd                   	std    
f0102045:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102047:	eb ea                	jmp    f0102033 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102049:	89 f2                	mov    %esi,%edx
f010204b:	09 c2                	or     %eax,%edx
f010204d:	f6 c2 03             	test   $0x3,%dl
f0102050:	74 09                	je     f010205b <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102052:	89 c7                	mov    %eax,%edi
f0102054:	fc                   	cld    
f0102055:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102057:	5e                   	pop    %esi
f0102058:	5f                   	pop    %edi
f0102059:	5d                   	pop    %ebp
f010205a:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010205b:	f6 c1 03             	test   $0x3,%cl
f010205e:	75 f2                	jne    f0102052 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0102060:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0102063:	89 c7                	mov    %eax,%edi
f0102065:	fc                   	cld    
f0102066:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102068:	eb ed                	jmp    f0102057 <memmove+0x55>

f010206a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010206a:	55                   	push   %ebp
f010206b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010206d:	ff 75 10             	pushl  0x10(%ebp)
f0102070:	ff 75 0c             	pushl  0xc(%ebp)
f0102073:	ff 75 08             	pushl  0x8(%ebp)
f0102076:	e8 87 ff ff ff       	call   f0102002 <memmove>
}
f010207b:	c9                   	leave  
f010207c:	c3                   	ret    

f010207d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010207d:	55                   	push   %ebp
f010207e:	89 e5                	mov    %esp,%ebp
f0102080:	56                   	push   %esi
f0102081:	53                   	push   %ebx
f0102082:	8b 45 08             	mov    0x8(%ebp),%eax
f0102085:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102088:	89 c6                	mov    %eax,%esi
f010208a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010208d:	39 f0                	cmp    %esi,%eax
f010208f:	74 1c                	je     f01020ad <memcmp+0x30>
		if (*s1 != *s2)
f0102091:	0f b6 08             	movzbl (%eax),%ecx
f0102094:	0f b6 1a             	movzbl (%edx),%ebx
f0102097:	38 d9                	cmp    %bl,%cl
f0102099:	75 08                	jne    f01020a3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010209b:	83 c0 01             	add    $0x1,%eax
f010209e:	83 c2 01             	add    $0x1,%edx
f01020a1:	eb ea                	jmp    f010208d <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01020a3:	0f b6 c1             	movzbl %cl,%eax
f01020a6:	0f b6 db             	movzbl %bl,%ebx
f01020a9:	29 d8                	sub    %ebx,%eax
f01020ab:	eb 05                	jmp    f01020b2 <memcmp+0x35>
	}

	return 0;
f01020ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020b2:	5b                   	pop    %ebx
f01020b3:	5e                   	pop    %esi
f01020b4:	5d                   	pop    %ebp
f01020b5:	c3                   	ret    

f01020b6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020b6:	55                   	push   %ebp
f01020b7:	89 e5                	mov    %esp,%ebp
f01020b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01020bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01020bf:	89 c2                	mov    %eax,%edx
f01020c1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01020c4:	39 d0                	cmp    %edx,%eax
f01020c6:	73 09                	jae    f01020d1 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01020c8:	38 08                	cmp    %cl,(%eax)
f01020ca:	74 05                	je     f01020d1 <memfind+0x1b>
	for (; s < ends; s++)
f01020cc:	83 c0 01             	add    $0x1,%eax
f01020cf:	eb f3                	jmp    f01020c4 <memfind+0xe>
			break;
	return (void *) s;
}
f01020d1:	5d                   	pop    %ebp
f01020d2:	c3                   	ret    

f01020d3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01020d3:	55                   	push   %ebp
f01020d4:	89 e5                	mov    %esp,%ebp
f01020d6:	57                   	push   %edi
f01020d7:	56                   	push   %esi
f01020d8:	53                   	push   %ebx
f01020d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01020dc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01020df:	eb 03                	jmp    f01020e4 <strtol+0x11>
		s++;
f01020e1:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01020e4:	0f b6 01             	movzbl (%ecx),%eax
f01020e7:	3c 20                	cmp    $0x20,%al
f01020e9:	74 f6                	je     f01020e1 <strtol+0xe>
f01020eb:	3c 09                	cmp    $0x9,%al
f01020ed:	74 f2                	je     f01020e1 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01020ef:	3c 2b                	cmp    $0x2b,%al
f01020f1:	74 2e                	je     f0102121 <strtol+0x4e>
	int neg = 0;
f01020f3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01020f8:	3c 2d                	cmp    $0x2d,%al
f01020fa:	74 2f                	je     f010212b <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01020fc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102102:	75 05                	jne    f0102109 <strtol+0x36>
f0102104:	80 39 30             	cmpb   $0x30,(%ecx)
f0102107:	74 2c                	je     f0102135 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102109:	85 db                	test   %ebx,%ebx
f010210b:	75 0a                	jne    f0102117 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010210d:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0102112:	80 39 30             	cmpb   $0x30,(%ecx)
f0102115:	74 28                	je     f010213f <strtol+0x6c>
		base = 10;
f0102117:	b8 00 00 00 00       	mov    $0x0,%eax
f010211c:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010211f:	eb 50                	jmp    f0102171 <strtol+0x9e>
		s++;
f0102121:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0102124:	bf 00 00 00 00       	mov    $0x0,%edi
f0102129:	eb d1                	jmp    f01020fc <strtol+0x29>
		s++, neg = 1;
f010212b:	83 c1 01             	add    $0x1,%ecx
f010212e:	bf 01 00 00 00       	mov    $0x1,%edi
f0102133:	eb c7                	jmp    f01020fc <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102135:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102139:	74 0e                	je     f0102149 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010213b:	85 db                	test   %ebx,%ebx
f010213d:	75 d8                	jne    f0102117 <strtol+0x44>
		s++, base = 8;
f010213f:	83 c1 01             	add    $0x1,%ecx
f0102142:	bb 08 00 00 00       	mov    $0x8,%ebx
f0102147:	eb ce                	jmp    f0102117 <strtol+0x44>
		s += 2, base = 16;
f0102149:	83 c1 02             	add    $0x2,%ecx
f010214c:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102151:	eb c4                	jmp    f0102117 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0102153:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102156:	89 f3                	mov    %esi,%ebx
f0102158:	80 fb 19             	cmp    $0x19,%bl
f010215b:	77 29                	ja     f0102186 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010215d:	0f be d2             	movsbl %dl,%edx
f0102160:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0102163:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102166:	7d 30                	jge    f0102198 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0102168:	83 c1 01             	add    $0x1,%ecx
f010216b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010216f:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0102171:	0f b6 11             	movzbl (%ecx),%edx
f0102174:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102177:	89 f3                	mov    %esi,%ebx
f0102179:	80 fb 09             	cmp    $0x9,%bl
f010217c:	77 d5                	ja     f0102153 <strtol+0x80>
			dig = *s - '0';
f010217e:	0f be d2             	movsbl %dl,%edx
f0102181:	83 ea 30             	sub    $0x30,%edx
f0102184:	eb dd                	jmp    f0102163 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0102186:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102189:	89 f3                	mov    %esi,%ebx
f010218b:	80 fb 19             	cmp    $0x19,%bl
f010218e:	77 08                	ja     f0102198 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0102190:	0f be d2             	movsbl %dl,%edx
f0102193:	83 ea 37             	sub    $0x37,%edx
f0102196:	eb cb                	jmp    f0102163 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0102198:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010219c:	74 05                	je     f01021a3 <strtol+0xd0>
		*endptr = (char *) s;
f010219e:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021a1:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01021a3:	89 c2                	mov    %eax,%edx
f01021a5:	f7 da                	neg    %edx
f01021a7:	85 ff                	test   %edi,%edi
f01021a9:	0f 45 c2             	cmovne %edx,%eax
}
f01021ac:	5b                   	pop    %ebx
f01021ad:	5e                   	pop    %esi
f01021ae:	5f                   	pop    %edi
f01021af:	5d                   	pop    %ebp
f01021b0:	c3                   	ret    
f01021b1:	66 90                	xchg   %ax,%ax
f01021b3:	66 90                	xchg   %ax,%ax
f01021b5:	66 90                	xchg   %ax,%ax
f01021b7:	66 90                	xchg   %ax,%ax
f01021b9:	66 90                	xchg   %ax,%ax
f01021bb:	66 90                	xchg   %ax,%ax
f01021bd:	66 90                	xchg   %ax,%ax
f01021bf:	90                   	nop

f01021c0 <__udivdi3>:
f01021c0:	55                   	push   %ebp
f01021c1:	57                   	push   %edi
f01021c2:	56                   	push   %esi
f01021c3:	53                   	push   %ebx
f01021c4:	83 ec 1c             	sub    $0x1c,%esp
f01021c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01021cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01021cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01021d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01021d7:	85 d2                	test   %edx,%edx
f01021d9:	75 35                	jne    f0102210 <__udivdi3+0x50>
f01021db:	39 f3                	cmp    %esi,%ebx
f01021dd:	0f 87 bd 00 00 00    	ja     f01022a0 <__udivdi3+0xe0>
f01021e3:	85 db                	test   %ebx,%ebx
f01021e5:	89 d9                	mov    %ebx,%ecx
f01021e7:	75 0b                	jne    f01021f4 <__udivdi3+0x34>
f01021e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01021ee:	31 d2                	xor    %edx,%edx
f01021f0:	f7 f3                	div    %ebx
f01021f2:	89 c1                	mov    %eax,%ecx
f01021f4:	31 d2                	xor    %edx,%edx
f01021f6:	89 f0                	mov    %esi,%eax
f01021f8:	f7 f1                	div    %ecx
f01021fa:	89 c6                	mov    %eax,%esi
f01021fc:	89 e8                	mov    %ebp,%eax
f01021fe:	89 f7                	mov    %esi,%edi
f0102200:	f7 f1                	div    %ecx
f0102202:	89 fa                	mov    %edi,%edx
f0102204:	83 c4 1c             	add    $0x1c,%esp
f0102207:	5b                   	pop    %ebx
f0102208:	5e                   	pop    %esi
f0102209:	5f                   	pop    %edi
f010220a:	5d                   	pop    %ebp
f010220b:	c3                   	ret    
f010220c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102210:	39 f2                	cmp    %esi,%edx
f0102212:	77 7c                	ja     f0102290 <__udivdi3+0xd0>
f0102214:	0f bd fa             	bsr    %edx,%edi
f0102217:	83 f7 1f             	xor    $0x1f,%edi
f010221a:	0f 84 98 00 00 00    	je     f01022b8 <__udivdi3+0xf8>
f0102220:	89 f9                	mov    %edi,%ecx
f0102222:	b8 20 00 00 00       	mov    $0x20,%eax
f0102227:	29 f8                	sub    %edi,%eax
f0102229:	d3 e2                	shl    %cl,%edx
f010222b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010222f:	89 c1                	mov    %eax,%ecx
f0102231:	89 da                	mov    %ebx,%edx
f0102233:	d3 ea                	shr    %cl,%edx
f0102235:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0102239:	09 d1                	or     %edx,%ecx
f010223b:	89 f2                	mov    %esi,%edx
f010223d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102241:	89 f9                	mov    %edi,%ecx
f0102243:	d3 e3                	shl    %cl,%ebx
f0102245:	89 c1                	mov    %eax,%ecx
f0102247:	d3 ea                	shr    %cl,%edx
f0102249:	89 f9                	mov    %edi,%ecx
f010224b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010224f:	d3 e6                	shl    %cl,%esi
f0102251:	89 eb                	mov    %ebp,%ebx
f0102253:	89 c1                	mov    %eax,%ecx
f0102255:	d3 eb                	shr    %cl,%ebx
f0102257:	09 de                	or     %ebx,%esi
f0102259:	89 f0                	mov    %esi,%eax
f010225b:	f7 74 24 08          	divl   0x8(%esp)
f010225f:	89 d6                	mov    %edx,%esi
f0102261:	89 c3                	mov    %eax,%ebx
f0102263:	f7 64 24 0c          	mull   0xc(%esp)
f0102267:	39 d6                	cmp    %edx,%esi
f0102269:	72 0c                	jb     f0102277 <__udivdi3+0xb7>
f010226b:	89 f9                	mov    %edi,%ecx
f010226d:	d3 e5                	shl    %cl,%ebp
f010226f:	39 c5                	cmp    %eax,%ebp
f0102271:	73 5d                	jae    f01022d0 <__udivdi3+0x110>
f0102273:	39 d6                	cmp    %edx,%esi
f0102275:	75 59                	jne    f01022d0 <__udivdi3+0x110>
f0102277:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010227a:	31 ff                	xor    %edi,%edi
f010227c:	89 fa                	mov    %edi,%edx
f010227e:	83 c4 1c             	add    $0x1c,%esp
f0102281:	5b                   	pop    %ebx
f0102282:	5e                   	pop    %esi
f0102283:	5f                   	pop    %edi
f0102284:	5d                   	pop    %ebp
f0102285:	c3                   	ret    
f0102286:	8d 76 00             	lea    0x0(%esi),%esi
f0102289:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102290:	31 ff                	xor    %edi,%edi
f0102292:	31 c0                	xor    %eax,%eax
f0102294:	89 fa                	mov    %edi,%edx
f0102296:	83 c4 1c             	add    $0x1c,%esp
f0102299:	5b                   	pop    %ebx
f010229a:	5e                   	pop    %esi
f010229b:	5f                   	pop    %edi
f010229c:	5d                   	pop    %ebp
f010229d:	c3                   	ret    
f010229e:	66 90                	xchg   %ax,%ax
f01022a0:	31 ff                	xor    %edi,%edi
f01022a2:	89 e8                	mov    %ebp,%eax
f01022a4:	89 f2                	mov    %esi,%edx
f01022a6:	f7 f3                	div    %ebx
f01022a8:	89 fa                	mov    %edi,%edx
f01022aa:	83 c4 1c             	add    $0x1c,%esp
f01022ad:	5b                   	pop    %ebx
f01022ae:	5e                   	pop    %esi
f01022af:	5f                   	pop    %edi
f01022b0:	5d                   	pop    %ebp
f01022b1:	c3                   	ret    
f01022b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01022b8:	39 f2                	cmp    %esi,%edx
f01022ba:	72 06                	jb     f01022c2 <__udivdi3+0x102>
f01022bc:	31 c0                	xor    %eax,%eax
f01022be:	39 eb                	cmp    %ebp,%ebx
f01022c0:	77 d2                	ja     f0102294 <__udivdi3+0xd4>
f01022c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01022c7:	eb cb                	jmp    f0102294 <__udivdi3+0xd4>
f01022c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022d0:	89 d8                	mov    %ebx,%eax
f01022d2:	31 ff                	xor    %edi,%edi
f01022d4:	eb be                	jmp    f0102294 <__udivdi3+0xd4>
f01022d6:	66 90                	xchg   %ax,%ax
f01022d8:	66 90                	xchg   %ax,%ax
f01022da:	66 90                	xchg   %ax,%ax
f01022dc:	66 90                	xchg   %ax,%ax
f01022de:	66 90                	xchg   %ax,%ax

f01022e0 <__umoddi3>:
f01022e0:	55                   	push   %ebp
f01022e1:	57                   	push   %edi
f01022e2:	56                   	push   %esi
f01022e3:	53                   	push   %ebx
f01022e4:	83 ec 1c             	sub    $0x1c,%esp
f01022e7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01022eb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01022ef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01022f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01022f7:	85 ed                	test   %ebp,%ebp
f01022f9:	89 f0                	mov    %esi,%eax
f01022fb:	89 da                	mov    %ebx,%edx
f01022fd:	75 19                	jne    f0102318 <__umoddi3+0x38>
f01022ff:	39 df                	cmp    %ebx,%edi
f0102301:	0f 86 b1 00 00 00    	jbe    f01023b8 <__umoddi3+0xd8>
f0102307:	f7 f7                	div    %edi
f0102309:	89 d0                	mov    %edx,%eax
f010230b:	31 d2                	xor    %edx,%edx
f010230d:	83 c4 1c             	add    $0x1c,%esp
f0102310:	5b                   	pop    %ebx
f0102311:	5e                   	pop    %esi
f0102312:	5f                   	pop    %edi
f0102313:	5d                   	pop    %ebp
f0102314:	c3                   	ret    
f0102315:	8d 76 00             	lea    0x0(%esi),%esi
f0102318:	39 dd                	cmp    %ebx,%ebp
f010231a:	77 f1                	ja     f010230d <__umoddi3+0x2d>
f010231c:	0f bd cd             	bsr    %ebp,%ecx
f010231f:	83 f1 1f             	xor    $0x1f,%ecx
f0102322:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0102326:	0f 84 b4 00 00 00    	je     f01023e0 <__umoddi3+0x100>
f010232c:	b8 20 00 00 00       	mov    $0x20,%eax
f0102331:	89 c2                	mov    %eax,%edx
f0102333:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102337:	29 c2                	sub    %eax,%edx
f0102339:	89 c1                	mov    %eax,%ecx
f010233b:	89 f8                	mov    %edi,%eax
f010233d:	d3 e5                	shl    %cl,%ebp
f010233f:	89 d1                	mov    %edx,%ecx
f0102341:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102345:	d3 e8                	shr    %cl,%eax
f0102347:	09 c5                	or     %eax,%ebp
f0102349:	8b 44 24 04          	mov    0x4(%esp),%eax
f010234d:	89 c1                	mov    %eax,%ecx
f010234f:	d3 e7                	shl    %cl,%edi
f0102351:	89 d1                	mov    %edx,%ecx
f0102353:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0102357:	89 df                	mov    %ebx,%edi
f0102359:	d3 ef                	shr    %cl,%edi
f010235b:	89 c1                	mov    %eax,%ecx
f010235d:	89 f0                	mov    %esi,%eax
f010235f:	d3 e3                	shl    %cl,%ebx
f0102361:	89 d1                	mov    %edx,%ecx
f0102363:	89 fa                	mov    %edi,%edx
f0102365:	d3 e8                	shr    %cl,%eax
f0102367:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010236c:	09 d8                	or     %ebx,%eax
f010236e:	f7 f5                	div    %ebp
f0102370:	d3 e6                	shl    %cl,%esi
f0102372:	89 d1                	mov    %edx,%ecx
f0102374:	f7 64 24 08          	mull   0x8(%esp)
f0102378:	39 d1                	cmp    %edx,%ecx
f010237a:	89 c3                	mov    %eax,%ebx
f010237c:	89 d7                	mov    %edx,%edi
f010237e:	72 06                	jb     f0102386 <__umoddi3+0xa6>
f0102380:	75 0e                	jne    f0102390 <__umoddi3+0xb0>
f0102382:	39 c6                	cmp    %eax,%esi
f0102384:	73 0a                	jae    f0102390 <__umoddi3+0xb0>
f0102386:	2b 44 24 08          	sub    0x8(%esp),%eax
f010238a:	19 ea                	sbb    %ebp,%edx
f010238c:	89 d7                	mov    %edx,%edi
f010238e:	89 c3                	mov    %eax,%ebx
f0102390:	89 ca                	mov    %ecx,%edx
f0102392:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0102397:	29 de                	sub    %ebx,%esi
f0102399:	19 fa                	sbb    %edi,%edx
f010239b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010239f:	89 d0                	mov    %edx,%eax
f01023a1:	d3 e0                	shl    %cl,%eax
f01023a3:	89 d9                	mov    %ebx,%ecx
f01023a5:	d3 ee                	shr    %cl,%esi
f01023a7:	d3 ea                	shr    %cl,%edx
f01023a9:	09 f0                	or     %esi,%eax
f01023ab:	83 c4 1c             	add    $0x1c,%esp
f01023ae:	5b                   	pop    %ebx
f01023af:	5e                   	pop    %esi
f01023b0:	5f                   	pop    %edi
f01023b1:	5d                   	pop    %ebp
f01023b2:	c3                   	ret    
f01023b3:	90                   	nop
f01023b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01023b8:	85 ff                	test   %edi,%edi
f01023ba:	89 f9                	mov    %edi,%ecx
f01023bc:	75 0b                	jne    f01023c9 <__umoddi3+0xe9>
f01023be:	b8 01 00 00 00       	mov    $0x1,%eax
f01023c3:	31 d2                	xor    %edx,%edx
f01023c5:	f7 f7                	div    %edi
f01023c7:	89 c1                	mov    %eax,%ecx
f01023c9:	89 d8                	mov    %ebx,%eax
f01023cb:	31 d2                	xor    %edx,%edx
f01023cd:	f7 f1                	div    %ecx
f01023cf:	89 f0                	mov    %esi,%eax
f01023d1:	f7 f1                	div    %ecx
f01023d3:	e9 31 ff ff ff       	jmp    f0102309 <__umoddi3+0x29>
f01023d8:	90                   	nop
f01023d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01023e0:	39 dd                	cmp    %ebx,%ebp
f01023e2:	72 08                	jb     f01023ec <__umoddi3+0x10c>
f01023e4:	39 f7                	cmp    %esi,%edi
f01023e6:	0f 87 21 ff ff ff    	ja     f010230d <__umoddi3+0x2d>
f01023ec:	89 da                	mov    %ebx,%edx
f01023ee:	89 f0                	mov    %esi,%eax
f01023f0:	29 f8                	sub    %edi,%eax
f01023f2:	19 ea                	sbb    %ebp,%edx
f01023f4:	e9 14 ff ff ff       	jmp    f010230d <__umoddi3+0x2d>
