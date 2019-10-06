
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 00 18 10 f0       	push   $0xf0101800
f0100050:	e8 98 08 00 00       	call   f01008ed <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7f 27                	jg     f0100083 <test_backtrace+0x43>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f010005c:	83 ec 04             	sub    $0x4,%esp
f010005f:	6a 00                	push   $0x0
f0100061:	6a 00                	push   $0x0
f0100063:	6a 00                	push   $0x0
f0100065:	e8 03 07 00 00       	call   f010076d <mon_backtrace>
f010006a:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010006d:	83 ec 08             	sub    $0x8,%esp
f0100070:	53                   	push   %ebx
f0100071:	68 1c 18 10 f0       	push   $0xf010181c
f0100076:	e8 72 08 00 00       	call   f01008ed <cprintf>
}
f010007b:	83 c4 10             	add    $0x10,%esp
f010007e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100081:	c9                   	leave  
f0100082:	c3                   	ret    
		test_backtrace(x-1);
f0100083:	83 ec 0c             	sub    $0xc,%esp
f0100086:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100089:	50                   	push   %eax
f010008a:	e8 b1 ff ff ff       	call   f0100040 <test_backtrace>
f010008f:	83 c4 10             	add    $0x10,%esp
f0100092:	eb d9                	jmp    f010006d <test_backtrace+0x2d>

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 0c 13 00 00       	call   f01013bd <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 a6 04 00 00       	call   f010055c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 18 10 f0       	push   $0xf0101837
f01000c3:	e8 25 08 00 00       	call   f01008ed <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 96 06 00 00       	call   f0100777 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	74 0f                	je     f0100106 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 76 06 00 00       	call   f0100777 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <_panic+0x11>
	panicstr = fmt;
f0100106:	89 35 40 29 11 f0    	mov    %esi,0xf0112940
	__asm __volatile("cli; cld");
f010010c:	fa                   	cli    
f010010d:	fc                   	cld    
	va_start(ap, fmt);
f010010e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100111:	83 ec 04             	sub    $0x4,%esp
f0100114:	ff 75 0c             	pushl  0xc(%ebp)
f0100117:	ff 75 08             	pushl  0x8(%ebp)
f010011a:	68 52 18 10 f0       	push   $0xf0101852
f010011f:	e8 c9 07 00 00       	call   f01008ed <cprintf>
	vcprintf(fmt, ap);
f0100124:	83 c4 08             	add    $0x8,%esp
f0100127:	53                   	push   %ebx
f0100128:	56                   	push   %esi
f0100129:	e8 99 07 00 00       	call   f01008c7 <vcprintf>
	cprintf("\n");
f010012e:	c7 04 24 8e 18 10 f0 	movl   $0xf010188e,(%esp)
f0100135:	e8 b3 07 00 00       	call   f01008ed <cprintf>
f010013a:	83 c4 10             	add    $0x10,%esp
f010013d:	eb b8                	jmp    f01000f7 <_panic+0x11>

f010013f <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013f:	55                   	push   %ebp
f0100140:	89 e5                	mov    %esp,%ebp
f0100142:	53                   	push   %ebx
f0100143:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100146:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100149:	ff 75 0c             	pushl  0xc(%ebp)
f010014c:	ff 75 08             	pushl  0x8(%ebp)
f010014f:	68 6a 18 10 f0       	push   $0xf010186a
f0100154:	e8 94 07 00 00       	call   f01008ed <cprintf>
	vcprintf(fmt, ap);
f0100159:	83 c4 08             	add    $0x8,%esp
f010015c:	53                   	push   %ebx
f010015d:	ff 75 10             	pushl  0x10(%ebp)
f0100160:	e8 62 07 00 00       	call   f01008c7 <vcprintf>
	cprintf("\n");
f0100165:	c7 04 24 8e 18 10 f0 	movl   $0xf010188e,(%esp)
f010016c:	e8 7c 07 00 00       	call   f01008ed <cprintf>
	va_end(ap);
}
f0100171:	83 c4 10             	add    $0x10,%esp
f0100174:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100177:	c9                   	leave  
f0100178:	c3                   	ret    

f0100179 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100179:	55                   	push   %ebp
f010017a:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017c:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100181:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100182:	a8 01                	test   $0x1,%al
f0100184:	74 0b                	je     f0100191 <serial_proc_data+0x18>
f0100186:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010018b:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018c:	0f b6 c0             	movzbl %al,%eax
}
f010018f:	5d                   	pop    %ebp
f0100190:	c3                   	ret    
		return -1;
f0100191:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100196:	eb f7                	jmp    f010018f <serial_proc_data+0x16>

f0100198 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100198:	55                   	push   %ebp
f0100199:	89 e5                	mov    %esp,%ebp
f010019b:	53                   	push   %ebx
f010019c:	83 ec 04             	sub    $0x4,%esp
f010019f:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001a1:	ff d3                	call   *%ebx
f01001a3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a6:	74 2d                	je     f01001d5 <cons_intr+0x3d>
		if (c == 0)
f01001a8:	85 c0                	test   %eax,%eax
f01001aa:	74 f5                	je     f01001a1 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f01001ac:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001b2:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001bb:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001c1:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c7:	75 d8                	jne    f01001a1 <cons_intr+0x9>
			cons.wpos = 0;
f01001c9:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001d0:	00 00 00 
f01001d3:	eb cc                	jmp    f01001a1 <cons_intr+0x9>
	}
}
f01001d5:	83 c4 04             	add    $0x4,%esp
f01001d8:	5b                   	pop    %ebx
f01001d9:	5d                   	pop    %ebp
f01001da:	c3                   	ret    

f01001db <kbd_proc_data>:
{
f01001db:	55                   	push   %ebp
f01001dc:	89 e5                	mov    %esp,%ebp
f01001de:	53                   	push   %ebx
f01001df:	83 ec 04             	sub    $0x4,%esp
f01001e2:	ba 64 00 00 00       	mov    $0x64,%edx
f01001e7:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001e8:	a8 01                	test   $0x1,%al
f01001ea:	0f 84 f2 00 00 00    	je     f01002e2 <kbd_proc_data+0x107>
f01001f0:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f5:	ec                   	in     (%dx),%al
f01001f6:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001f8:	3c e0                	cmp    $0xe0,%al
f01001fa:	0f 84 8e 00 00 00    	je     f010028e <kbd_proc_data+0xb3>
	} else if (data & 0x80) {
f0100200:	84 c0                	test   %al,%al
f0100202:	0f 88 99 00 00 00    	js     f01002a1 <kbd_proc_data+0xc6>
	} else if (shift & E0ESC) {
f0100208:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010020e:	f6 c1 40             	test   $0x40,%cl
f0100211:	74 0e                	je     f0100221 <kbd_proc_data+0x46>
		data |= 0x80;
f0100213:	83 c8 80             	or     $0xffffff80,%eax
f0100216:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100218:	83 e1 bf             	and    $0xffffffbf,%ecx
f010021b:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	shift |= shiftcode[data];
f0100221:	0f b6 d2             	movzbl %dl,%edx
f0100224:	0f b6 82 e0 19 10 f0 	movzbl -0xfefe620(%edx),%eax
f010022b:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100231:	0f b6 8a e0 18 10 f0 	movzbl -0xfefe720(%edx),%ecx
f0100238:	31 c8                	xor    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
	c = charcode[shift & (CTL | SHIFT)][data];
f010023f:	89 c1                	mov    %eax,%ecx
f0100241:	83 e1 03             	and    $0x3,%ecx
f0100244:	8b 0c 8d c0 18 10 f0 	mov    -0xfefe740(,%ecx,4),%ecx
f010024b:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024f:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100252:	a8 08                	test   $0x8,%al
f0100254:	74 0d                	je     f0100263 <kbd_proc_data+0x88>
		if ('a' <= c && c <= 'z')
f0100256:	89 da                	mov    %ebx,%edx
f0100258:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010025b:	83 f9 19             	cmp    $0x19,%ecx
f010025e:	77 74                	ja     f01002d4 <kbd_proc_data+0xf9>
			c += 'A' - 'a';
f0100260:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100263:	f7 d0                	not    %eax
f0100265:	a8 06                	test   $0x6,%al
f0100267:	75 31                	jne    f010029a <kbd_proc_data+0xbf>
f0100269:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010026f:	75 29                	jne    f010029a <kbd_proc_data+0xbf>
		cprintf("Rebooting!\n");
f0100271:	83 ec 0c             	sub    $0xc,%esp
f0100274:	68 84 18 10 f0       	push   $0xf0101884
f0100279:	e8 6f 06 00 00       	call   f01008ed <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100283:	ba 92 00 00 00       	mov    $0x92,%edx
f0100288:	ee                   	out    %al,(%dx)
f0100289:	83 c4 10             	add    $0x10,%esp
f010028c:	eb 0c                	jmp    f010029a <kbd_proc_data+0xbf>
		shift |= E0ESC;
f010028e:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100295:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010029a:	89 d8                	mov    %ebx,%eax
f010029c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029f:	c9                   	leave  
f01002a0:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002a1:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f01002a7:	89 cb                	mov    %ecx,%ebx
f01002a9:	83 e3 40             	and    $0x40,%ebx
f01002ac:	83 e0 7f             	and    $0x7f,%eax
f01002af:	85 db                	test   %ebx,%ebx
f01002b1:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002b4:	0f b6 d2             	movzbl %dl,%edx
f01002b7:	0f b6 82 e0 19 10 f0 	movzbl -0xfefe620(%edx),%eax
f01002be:	83 c8 40             	or     $0x40,%eax
f01002c1:	0f b6 c0             	movzbl %al,%eax
f01002c4:	f7 d0                	not    %eax
f01002c6:	21 c8                	and    %ecx,%eax
f01002c8:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f01002cd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002d2:	eb c6                	jmp    f010029a <kbd_proc_data+0xbf>
		else if ('A' <= c && c <= 'Z')
f01002d4:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d7:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002da:	83 fa 1a             	cmp    $0x1a,%edx
f01002dd:	0f 42 d9             	cmovb  %ecx,%ebx
f01002e0:	eb 81                	jmp    f0100263 <kbd_proc_data+0x88>
		return -1;
f01002e2:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002e7:	eb b1                	jmp    f010029a <kbd_proc_data+0xbf>

f01002e9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e9:	55                   	push   %ebp
f01002ea:	89 e5                	mov    %esp,%ebp
f01002ec:	57                   	push   %edi
f01002ed:	56                   	push   %esi
f01002ee:	53                   	push   %ebx
f01002ef:	83 ec 1c             	sub    $0x1c,%esp
f01002f2:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01002f4:	bb 00 00 00 00       	mov    $0x0,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002fe:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100303:	eb 09                	jmp    f010030e <cons_putc+0x25>
f0100305:	89 ca                	mov    %ecx,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	ec                   	in     (%dx),%al
	     i++)
f010030b:	83 c3 01             	add    $0x1,%ebx
f010030e:	89 f2                	mov    %esi,%edx
f0100310:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100311:	a8 20                	test   $0x20,%al
f0100313:	75 08                	jne    f010031d <cons_putc+0x34>
f0100315:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010031b:	7e e8                	jle    f0100305 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f010031d:	89 f8                	mov    %edi,%eax
f010031f:	88 45 e7             	mov    %al,-0x19(%ebp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100322:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100327:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100328:	bb 00 00 00 00       	mov    $0x0,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010032d:	be 79 03 00 00       	mov    $0x379,%esi
f0100332:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100337:	eb 09                	jmp    f0100342 <cons_putc+0x59>
f0100339:	89 ca                	mov    %ecx,%edx
f010033b:	ec                   	in     (%dx),%al
f010033c:	ec                   	in     (%dx),%al
f010033d:	ec                   	in     (%dx),%al
f010033e:	ec                   	in     (%dx),%al
f010033f:	83 c3 01             	add    $0x1,%ebx
f0100342:	89 f2                	mov    %esi,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010034b:	7f 04                	jg     f0100351 <cons_putc+0x68>
f010034d:	84 c0                	test   %al,%al
f010034f:	79 e8                	jns    f0100339 <cons_putc+0x50>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100351:	ba 78 03 00 00       	mov    $0x378,%edx
f0100356:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010035a:	ee                   	out    %al,(%dx)
f010035b:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100360:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100365:	ee                   	out    %al,(%dx)
f0100366:	b8 08 00 00 00       	mov    $0x8,%eax
f010036b:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010036c:	89 fa                	mov    %edi,%edx
f010036e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100374:	89 f8                	mov    %edi,%eax
f0100376:	80 cc 07             	or     $0x7,%ah
f0100379:	85 d2                	test   %edx,%edx
f010037b:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f010037e:	89 f8                	mov    %edi,%eax
f0100380:	0f b6 c0             	movzbl %al,%eax
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	0f 84 b6 00 00 00    	je     f0100442 <cons_putc+0x159>
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	7e 73                	jle    f0100404 <cons_putc+0x11b>
f0100391:	83 f8 0a             	cmp    $0xa,%eax
f0100394:	0f 84 9b 00 00 00    	je     f0100435 <cons_putc+0x14c>
f010039a:	83 f8 0d             	cmp    $0xd,%eax
f010039d:	0f 85 d6 00 00 00    	jne    f0100479 <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f01003a3:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003aa:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b0:	c1 e8 16             	shr    $0x16,%eax
f01003b3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b6:	c1 e0 04             	shl    $0x4,%eax
f01003b9:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
	if (crt_pos >= CRT_SIZE) {
f01003bf:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f01003c6:	cf 07 
f01003c8:	0f 87 ce 00 00 00    	ja     f010049c <cons_putc+0x1b3>
	outb(addr_6845, 14);
f01003ce:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01003d4:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003d9:	89 ca                	mov    %ecx,%edx
f01003db:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003dc:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01003e3:	8d 71 01             	lea    0x1(%ecx),%esi
f01003e6:	89 d8                	mov    %ebx,%eax
f01003e8:	66 c1 e8 08          	shr    $0x8,%ax
f01003ec:	89 f2                	mov    %esi,%edx
f01003ee:	ee                   	out    %al,(%dx)
f01003ef:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003f4:	89 ca                	mov    %ecx,%edx
f01003f6:	ee                   	out    %al,(%dx)
f01003f7:	89 d8                	mov    %ebx,%eax
f01003f9:	89 f2                	mov    %esi,%edx
f01003fb:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003ff:	5b                   	pop    %ebx
f0100400:	5e                   	pop    %esi
f0100401:	5f                   	pop    %edi
f0100402:	5d                   	pop    %ebp
f0100403:	c3                   	ret    
	switch (c & 0xff) {
f0100404:	83 f8 08             	cmp    $0x8,%eax
f0100407:	75 70                	jne    f0100479 <cons_putc+0x190>
		if (crt_pos > 0) {
f0100409:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100410:	66 85 c0             	test   %ax,%ax
f0100413:	74 b9                	je     f01003ce <cons_putc+0xe5>
			crt_pos--;
f0100415:	83 e8 01             	sub    $0x1,%eax
f0100418:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010041e:	0f b7 c0             	movzwl %ax,%eax
f0100421:	66 81 e7 00 ff       	and    $0xff00,%di
f0100426:	83 cf 20             	or     $0x20,%edi
f0100429:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010042f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100433:	eb 8a                	jmp    f01003bf <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f0100435:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f010043c:	50 
f010043d:	e9 61 ff ff ff       	jmp    f01003a3 <cons_putc+0xba>
		cons_putc(' ');
f0100442:	b8 20 00 00 00       	mov    $0x20,%eax
f0100447:	e8 9d fe ff ff       	call   f01002e9 <cons_putc>
		cons_putc(' ');
f010044c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100451:	e8 93 fe ff ff       	call   f01002e9 <cons_putc>
		cons_putc(' ');
f0100456:	b8 20 00 00 00       	mov    $0x20,%eax
f010045b:	e8 89 fe ff ff       	call   f01002e9 <cons_putc>
		cons_putc(' ');
f0100460:	b8 20 00 00 00       	mov    $0x20,%eax
f0100465:	e8 7f fe ff ff       	call   f01002e9 <cons_putc>
		cons_putc(' ');
f010046a:	b8 20 00 00 00       	mov    $0x20,%eax
f010046f:	e8 75 fe ff ff       	call   f01002e9 <cons_putc>
f0100474:	e9 46 ff ff ff       	jmp    f01003bf <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100479:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100480:	8d 50 01             	lea    0x1(%eax),%edx
f0100483:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010048a:	0f b7 c0             	movzwl %ax,%eax
f010048d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100493:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100497:	e9 23 ff ff ff       	jmp    f01003bf <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010049c:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f01004a1:	83 ec 04             	sub    $0x4,%esp
f01004a4:	68 00 0f 00 00       	push   $0xf00
f01004a9:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004af:	52                   	push   %edx
f01004b0:	50                   	push   %eax
f01004b1:	e8 54 0f 00 00       	call   f010140a <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004b6:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01004bc:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004c2:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004c8:	83 c4 10             	add    $0x10,%esp
f01004cb:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004d0:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004d3:	39 d0                	cmp    %edx,%eax
f01004d5:	75 f4                	jne    f01004cb <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f01004d7:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004de:	50 
f01004df:	e9 ea fe ff ff       	jmp    f01003ce <cons_putc+0xe5>

f01004e4 <serial_intr>:
	if (serial_exists)
f01004e4:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004eb:	75 02                	jne    f01004ef <serial_intr+0xb>
f01004ed:	f3 c3                	repz ret 
{
f01004ef:	55                   	push   %ebp
f01004f0:	89 e5                	mov    %esp,%ebp
f01004f2:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004f5:	b8 79 01 10 f0       	mov    $0xf0100179,%eax
f01004fa:	e8 99 fc ff ff       	call   f0100198 <cons_intr>
}
f01004ff:	c9                   	leave  
f0100500:	c3                   	ret    

f0100501 <kbd_intr>:
{
f0100501:	55                   	push   %ebp
f0100502:	89 e5                	mov    %esp,%ebp
f0100504:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100507:	b8 db 01 10 f0       	mov    $0xf01001db,%eax
f010050c:	e8 87 fc ff ff       	call   f0100198 <cons_intr>
}
f0100511:	c9                   	leave  
f0100512:	c3                   	ret    

f0100513 <cons_getc>:
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f0100519:	e8 c6 ff ff ff       	call   f01004e4 <serial_intr>
	kbd_intr();
f010051e:	e8 de ff ff ff       	call   f0100501 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100523:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
	return 0;
f0100529:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f010052e:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100534:	74 18                	je     f010054e <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f0100536:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100539:	89 0d 20 25 11 f0    	mov    %ecx,0xf0112520
f010053f:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f0100546:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010054c:	74 02                	je     f0100550 <cons_getc+0x3d>
}
f010054e:	c9                   	leave  
f010054f:	c3                   	ret    
			cons.rpos = 0;
f0100550:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100557:	00 00 00 
f010055a:	eb f2                	jmp    f010054e <cons_getc+0x3b>

f010055c <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010055c:	55                   	push   %ebp
f010055d:	89 e5                	mov    %esp,%ebp
f010055f:	57                   	push   %edi
f0100560:	56                   	push   %esi
f0100561:	53                   	push   %ebx
f0100562:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100565:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100573:	5a a5 
	if (*cp != 0xA55A) {
f0100575:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100580:	0f 84 b7 00 00 00    	je     f010063d <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f0100586:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058d:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100590:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100595:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f010059b:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005a0:	89 fa                	mov    %edi,%edx
f01005a2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a3:	8d 4f 01             	lea    0x1(%edi),%ecx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a6:	89 ca                	mov    %ecx,%edx
f01005a8:	ec                   	in     (%dx),%al
f01005a9:	0f b6 c0             	movzbl %al,%eax
f01005ac:	c1 e0 08             	shl    $0x8,%eax
f01005af:	89 c3                	mov    %eax,%ebx
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b6:	89 fa                	mov    %edi,%edx
f01005b8:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b9:	89 ca                	mov    %ecx,%edx
f01005bb:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005bc:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	pos |= inb(addr_6845 + 1);
f01005c2:	0f b6 c0             	movzbl %al,%eax
f01005c5:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01005c7:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005cd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01005d2:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f01005d7:	89 d8                	mov    %ebx,%eax
f01005d9:	89 ca                	mov    %ecx,%edx
f01005db:	ee                   	out    %al,(%dx)
f01005dc:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01005e1:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005e6:	89 fa                	mov    %edi,%edx
f01005e8:	ee                   	out    %al,(%dx)
f01005e9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ee:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005f3:	ee                   	out    %al,(%dx)
f01005f4:	be f9 03 00 00       	mov    $0x3f9,%esi
f01005f9:	89 d8                	mov    %ebx,%eax
f01005fb:	89 f2                	mov    %esi,%edx
f01005fd:	ee                   	out    %al,(%dx)
f01005fe:	b8 03 00 00 00       	mov    $0x3,%eax
f0100603:	89 fa                	mov    %edi,%edx
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010060b:	89 d8                	mov    %ebx,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100613:	89 f2                	mov    %esi,%edx
f0100615:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100616:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061b:	ec                   	in     (%dx),%al
f010061c:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010061e:	3c ff                	cmp    $0xff,%al
f0100620:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100627:	89 ca                	mov    %ecx,%edx
f0100629:	ec                   	in     (%dx),%al
f010062a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010062f:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 fb ff             	cmp    $0xff,%bl
f0100633:	74 23                	je     f0100658 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f0100635:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100638:	5b                   	pop    %ebx
f0100639:	5e                   	pop    %esi
f010063a:	5f                   	pop    %edi
f010063b:	5d                   	pop    %ebp
f010063c:	c3                   	ret    
		*cp = was;
f010063d:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100644:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010064b:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010064e:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100653:	e9 3d ff ff ff       	jmp    f0100595 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f0100658:	83 ec 0c             	sub    $0xc,%esp
f010065b:	68 90 18 10 f0       	push   $0xf0101890
f0100660:	e8 88 02 00 00       	call   f01008ed <cprintf>
f0100665:	83 c4 10             	add    $0x10,%esp
}
f0100668:	eb cb                	jmp    f0100635 <cons_init+0xd9>

f010066a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
f010066d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100670:	8b 45 08             	mov    0x8(%ebp),%eax
f0100673:	e8 71 fc ff ff       	call   f01002e9 <cons_putc>
}
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <getchar>:

int
getchar(void)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100680:	e8 8e fe ff ff       	call   f0100513 <cons_getc>
f0100685:	85 c0                	test   %eax,%eax
f0100687:	74 f7                	je     f0100680 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100689:	c9                   	leave  
f010068a:	c3                   	ret    

f010068b <iscons>:

int
iscons(int fdnum)
{
f010068b:	55                   	push   %ebp
f010068c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010068e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    

f0100695 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100695:	55                   	push   %ebp
f0100696:	89 e5                	mov    %esp,%ebp
f0100698:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010069b:	68 e0 1a 10 f0       	push   $0xf0101ae0
f01006a0:	68 fe 1a 10 f0       	push   $0xf0101afe
f01006a5:	68 03 1b 10 f0       	push   $0xf0101b03
f01006aa:	e8 3e 02 00 00       	call   f01008ed <cprintf>
f01006af:	83 c4 0c             	add    $0xc,%esp
f01006b2:	68 6c 1b 10 f0       	push   $0xf0101b6c
f01006b7:	68 0c 1b 10 f0       	push   $0xf0101b0c
f01006bc:	68 03 1b 10 f0       	push   $0xf0101b03
f01006c1:	e8 27 02 00 00       	call   f01008ed <cprintf>
	return 0;
}
f01006c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cb:	c9                   	leave  
f01006cc:	c3                   	ret    

f01006cd <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006cd:	55                   	push   %ebp
f01006ce:	89 e5                	mov    %esp,%ebp
f01006d0:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006d3:	68 15 1b 10 f0       	push   $0xf0101b15
f01006d8:	e8 10 02 00 00       	call   f01008ed <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006dd:	83 c4 08             	add    $0x8,%esp
f01006e0:	68 0c 00 10 00       	push   $0x10000c
f01006e5:	68 94 1b 10 f0       	push   $0xf0101b94
f01006ea:	e8 fe 01 00 00       	call   f01008ed <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 0c 00 10 00       	push   $0x10000c
f01006f7:	68 0c 00 10 f0       	push   $0xf010000c
f01006fc:	68 bc 1b 10 f0       	push   $0xf0101bbc
f0100701:	e8 e7 01 00 00       	call   f01008ed <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 f9 17 10 00       	push   $0x1017f9
f010070e:	68 f9 17 10 f0       	push   $0xf01017f9
f0100713:	68 e0 1b 10 f0       	push   $0xf0101be0
f0100718:	e8 d0 01 00 00       	call   f01008ed <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010071d:	83 c4 0c             	add    $0xc,%esp
f0100720:	68 00 23 11 00       	push   $0x112300
f0100725:	68 00 23 11 f0       	push   $0xf0112300
f010072a:	68 04 1c 10 f0       	push   $0xf0101c04
f010072f:	e8 b9 01 00 00       	call   f01008ed <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100734:	83 c4 0c             	add    $0xc,%esp
f0100737:	68 44 29 11 00       	push   $0x112944
f010073c:	68 44 29 11 f0       	push   $0xf0112944
f0100741:	68 28 1c 10 f0       	push   $0xf0101c28
f0100746:	e8 a2 01 00 00       	call   f01008ed <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074b:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010074e:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100753:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100758:	c1 f8 0a             	sar    $0xa,%eax
f010075b:	50                   	push   %eax
f010075c:	68 4c 1c 10 f0       	push   $0xf0101c4c
f0100761:	e8 87 01 00 00       	call   f01008ed <cprintf>
	return 0;
}
f0100766:	b8 00 00 00 00       	mov    $0x0,%eax
f010076b:	c9                   	leave  
f010076c:	c3                   	ret    

f010076d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010076d:	55                   	push   %ebp
f010076e:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	5d                   	pop    %ebp
f0100776:	c3                   	ret    

f0100777 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	57                   	push   %edi
f010077b:	56                   	push   %esi
f010077c:	53                   	push   %ebx
f010077d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100780:	68 78 1c 10 f0       	push   $0xf0101c78
f0100785:	e8 63 01 00 00       	call   f01008ed <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010078a:	c7 04 24 9c 1c 10 f0 	movl   $0xf0101c9c,(%esp)
f0100791:	e8 57 01 00 00       	call   f01008ed <cprintf>
f0100796:	83 c4 10             	add    $0x10,%esp
f0100799:	eb 47                	jmp    f01007e2 <monitor+0x6b>
		while (*buf && strchr(WHITESPACE, *buf))
f010079b:	83 ec 08             	sub    $0x8,%esp
f010079e:	0f be c0             	movsbl %al,%eax
f01007a1:	50                   	push   %eax
f01007a2:	68 32 1b 10 f0       	push   $0xf0101b32
f01007a7:	e8 d4 0b 00 00       	call   f0101380 <strchr>
f01007ac:	83 c4 10             	add    $0x10,%esp
f01007af:	85 c0                	test   %eax,%eax
f01007b1:	74 0a                	je     f01007bd <monitor+0x46>
			*buf++ = 0;
f01007b3:	c6 03 00             	movb   $0x0,(%ebx)
f01007b6:	89 f7                	mov    %esi,%edi
f01007b8:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007bb:	eb 6b                	jmp    f0100828 <monitor+0xb1>
		if (*buf == 0)
f01007bd:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007c0:	74 73                	je     f0100835 <monitor+0xbe>
		if (argc == MAXARGS-1) {
f01007c2:	83 fe 0f             	cmp    $0xf,%esi
f01007c5:	74 09                	je     f01007d0 <monitor+0x59>
		argv[argc++] = buf;
f01007c7:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ca:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007ce:	eb 39                	jmp    f0100809 <monitor+0x92>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007d0:	83 ec 08             	sub    $0x8,%esp
f01007d3:	6a 10                	push   $0x10
f01007d5:	68 37 1b 10 f0       	push   $0xf0101b37
f01007da:	e8 0e 01 00 00       	call   f01008ed <cprintf>
f01007df:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007e2:	83 ec 0c             	sub    $0xc,%esp
f01007e5:	68 2e 1b 10 f0       	push   $0xf0101b2e
f01007ea:	e8 74 09 00 00       	call   f0101163 <readline>
f01007ef:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f1:	83 c4 10             	add    $0x10,%esp
f01007f4:	85 c0                	test   %eax,%eax
f01007f6:	74 ea                	je     f01007e2 <monitor+0x6b>
	argv[argc] = 0;
f01007f8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01007ff:	be 00 00 00 00       	mov    $0x0,%esi
f0100804:	eb 24                	jmp    f010082a <monitor+0xb3>
			buf++;
f0100806:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100809:	0f b6 03             	movzbl (%ebx),%eax
f010080c:	84 c0                	test   %al,%al
f010080e:	74 18                	je     f0100828 <monitor+0xb1>
f0100810:	83 ec 08             	sub    $0x8,%esp
f0100813:	0f be c0             	movsbl %al,%eax
f0100816:	50                   	push   %eax
f0100817:	68 32 1b 10 f0       	push   $0xf0101b32
f010081c:	e8 5f 0b 00 00       	call   f0101380 <strchr>
f0100821:	83 c4 10             	add    $0x10,%esp
f0100824:	85 c0                	test   %eax,%eax
f0100826:	74 de                	je     f0100806 <monitor+0x8f>
			*buf++ = 0;
f0100828:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f010082a:	0f b6 03             	movzbl (%ebx),%eax
f010082d:	84 c0                	test   %al,%al
f010082f:	0f 85 66 ff ff ff    	jne    f010079b <monitor+0x24>
	argv[argc] = 0;
f0100835:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010083c:	00 
	if (argc == 0)
f010083d:	85 f6                	test   %esi,%esi
f010083f:	74 a1                	je     f01007e2 <monitor+0x6b>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100841:	83 ec 08             	sub    $0x8,%esp
f0100844:	68 fe 1a 10 f0       	push   $0xf0101afe
f0100849:	ff 75 a8             	pushl  -0x58(%ebp)
f010084c:	e8 d1 0a 00 00       	call   f0101322 <strcmp>
f0100851:	83 c4 10             	add    $0x10,%esp
f0100854:	85 c0                	test   %eax,%eax
f0100856:	74 34                	je     f010088c <monitor+0x115>
f0100858:	83 ec 08             	sub    $0x8,%esp
f010085b:	68 0c 1b 10 f0       	push   $0xf0101b0c
f0100860:	ff 75 a8             	pushl  -0x58(%ebp)
f0100863:	e8 ba 0a 00 00       	call   f0101322 <strcmp>
f0100868:	83 c4 10             	add    $0x10,%esp
f010086b:	85 c0                	test   %eax,%eax
f010086d:	74 18                	je     f0100887 <monitor+0x110>
	cprintf("Unknown command '%s'\n", argv[0]);
f010086f:	83 ec 08             	sub    $0x8,%esp
f0100872:	ff 75 a8             	pushl  -0x58(%ebp)
f0100875:	68 54 1b 10 f0       	push   $0xf0101b54
f010087a:	e8 6e 00 00 00       	call   f01008ed <cprintf>
f010087f:	83 c4 10             	add    $0x10,%esp
f0100882:	e9 5b ff ff ff       	jmp    f01007e2 <monitor+0x6b>
	for (i = 0; i < NCOMMANDS; i++) {
f0100887:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f010088c:	83 ec 04             	sub    $0x4,%esp
f010088f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100892:	ff 75 08             	pushl  0x8(%ebp)
f0100895:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100898:	52                   	push   %edx
f0100899:	56                   	push   %esi
f010089a:	ff 14 85 cc 1c 10 f0 	call   *-0xfefe334(,%eax,4)
			if (runcmd(buf, tf) < 0)
f01008a1:	83 c4 10             	add    $0x10,%esp
f01008a4:	85 c0                	test   %eax,%eax
f01008a6:	0f 89 36 ff ff ff    	jns    f01007e2 <monitor+0x6b>
				break;
	}
}
f01008ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008af:	5b                   	pop    %ebx
f01008b0:	5e                   	pop    %esi
f01008b1:	5f                   	pop    %edi
f01008b2:	5d                   	pop    %ebp
f01008b3:	c3                   	ret    

f01008b4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008b4:	55                   	push   %ebp
f01008b5:	89 e5                	mov    %esp,%ebp
f01008b7:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008ba:	ff 75 08             	pushl  0x8(%ebp)
f01008bd:	e8 a8 fd ff ff       	call   f010066a <cputchar>
	*cnt++;
}
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	c9                   	leave  
f01008c6:	c3                   	ret    

f01008c7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008c7:	55                   	push   %ebp
f01008c8:	89 e5                	mov    %esp,%ebp
f01008ca:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008d4:	ff 75 0c             	pushl  0xc(%ebp)
f01008d7:	ff 75 08             	pushl  0x8(%ebp)
f01008da:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008dd:	50                   	push   %eax
f01008de:	68 b4 08 10 f0       	push   $0xf01008b4
f01008e3:	e8 c5 03 00 00       	call   f0100cad <vprintfmt>
	return cnt;
}
f01008e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008eb:	c9                   	leave  
f01008ec:	c3                   	ret    

f01008ed <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008ed:	55                   	push   %ebp
f01008ee:	89 e5                	mov    %esp,%ebp
f01008f0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008f3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008f6:	50                   	push   %eax
f01008f7:	ff 75 08             	pushl  0x8(%ebp)
f01008fa:	e8 c8 ff ff ff       	call   f01008c7 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008ff:	c9                   	leave  
f0100900:	c3                   	ret    

f0100901 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100901:	55                   	push   %ebp
f0100902:	89 e5                	mov    %esp,%ebp
f0100904:	57                   	push   %edi
f0100905:	56                   	push   %esi
f0100906:	53                   	push   %ebx
f0100907:	83 ec 14             	sub    $0x14,%esp
f010090a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010090d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100910:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100913:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100916:	8b 32                	mov    (%edx),%esi
f0100918:	8b 01                	mov    (%ecx),%eax
f010091a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010091d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100924:	eb 2f                	jmp    f0100955 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100926:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100929:	39 c6                	cmp    %eax,%esi
f010092b:	7f 49                	jg     f0100976 <stab_binsearch+0x75>
f010092d:	0f b6 0a             	movzbl (%edx),%ecx
f0100930:	83 ea 0c             	sub    $0xc,%edx
f0100933:	39 f9                	cmp    %edi,%ecx
f0100935:	75 ef                	jne    f0100926 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100937:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010093a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010093d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100941:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100944:	73 35                	jae    f010097b <stab_binsearch+0x7a>
			*region_left = m;
f0100946:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100949:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010094b:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010094e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100955:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100958:	7f 4e                	jg     f01009a8 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f010095a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010095d:	01 f0                	add    %esi,%eax
f010095f:	89 c3                	mov    %eax,%ebx
f0100961:	c1 eb 1f             	shr    $0x1f,%ebx
f0100964:	01 c3                	add    %eax,%ebx
f0100966:	d1 fb                	sar    %ebx
f0100968:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010096b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010096e:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100972:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100974:	eb b3                	jmp    f0100929 <stab_binsearch+0x28>
			l = true_m + 1;
f0100976:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100979:	eb da                	jmp    f0100955 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010097b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010097e:	76 14                	jbe    f0100994 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100980:	83 e8 01             	sub    $0x1,%eax
f0100983:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100986:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100989:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010098b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100992:	eb c1                	jmp    f0100955 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100994:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100997:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100999:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010099d:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010099f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009a6:	eb ad                	jmp    f0100955 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01009a8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009ac:	74 16                	je     f01009c4 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009b1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009b3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009b6:	8b 0e                	mov    (%esi),%ecx
f01009b8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009bb:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01009be:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01009c2:	eb 12                	jmp    f01009d6 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01009c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009c7:	8b 00                	mov    (%eax),%eax
f01009c9:	83 e8 01             	sub    $0x1,%eax
f01009cc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01009cf:	89 07                	mov    %eax,(%edi)
f01009d1:	eb 16                	jmp    f01009e9 <stab_binsearch+0xe8>
		     l--)
f01009d3:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01009d6:	39 c1                	cmp    %eax,%ecx
f01009d8:	7d 0a                	jge    f01009e4 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01009da:	0f b6 1a             	movzbl (%edx),%ebx
f01009dd:	83 ea 0c             	sub    $0xc,%edx
f01009e0:	39 fb                	cmp    %edi,%ebx
f01009e2:	75 ef                	jne    f01009d3 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01009e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009e7:	89 07                	mov    %eax,(%edi)
	}
}
f01009e9:	83 c4 14             	add    $0x14,%esp
f01009ec:	5b                   	pop    %ebx
f01009ed:	5e                   	pop    %esi
f01009ee:	5f                   	pop    %edi
f01009ef:	5d                   	pop    %ebp
f01009f0:	c3                   	ret    

f01009f1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009f1:	55                   	push   %ebp
f01009f2:	89 e5                	mov    %esp,%ebp
f01009f4:	57                   	push   %edi
f01009f5:	56                   	push   %esi
f01009f6:	53                   	push   %ebx
f01009f7:	83 ec 1c             	sub    $0x1c,%esp
f01009fa:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009fd:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a00:	c7 06 dc 1c 10 f0    	movl   $0xf0101cdc,(%esi)
	info->eip_line = 0;
f0100a06:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a0d:	c7 46 08 dc 1c 10 f0 	movl   $0xf0101cdc,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a14:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a1b:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a1e:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a25:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a2b:	0f 86 df 00 00 00    	jbe    f0100b10 <debuginfo_eip+0x11f>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a31:	b8 bd 74 10 f0       	mov    $0xf01074bd,%eax
f0100a36:	3d 31 5b 10 f0       	cmp    $0xf0105b31,%eax
f0100a3b:	0f 86 61 01 00 00    	jbe    f0100ba2 <debuginfo_eip+0x1b1>
f0100a41:	80 3d bc 74 10 f0 00 	cmpb   $0x0,0xf01074bc
f0100a48:	0f 85 5b 01 00 00    	jne    f0100ba9 <debuginfo_eip+0x1b8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a4e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a55:	b8 30 5b 10 f0       	mov    $0xf0105b30,%eax
f0100a5a:	2d 30 1f 10 f0       	sub    $0xf0101f30,%eax
f0100a5f:	c1 f8 02             	sar    $0x2,%eax
f0100a62:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a68:	83 e8 01             	sub    $0x1,%eax
f0100a6b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a6e:	83 ec 08             	sub    $0x8,%esp
f0100a71:	57                   	push   %edi
f0100a72:	6a 64                	push   $0x64
f0100a74:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a77:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a7a:	b8 30 1f 10 f0       	mov    $0xf0101f30,%eax
f0100a7f:	e8 7d fe ff ff       	call   f0100901 <stab_binsearch>
	if (lfile == 0)
f0100a84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a87:	83 c4 10             	add    $0x10,%esp
f0100a8a:	85 c0                	test   %eax,%eax
f0100a8c:	0f 84 1e 01 00 00    	je     f0100bb0 <debuginfo_eip+0x1bf>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a92:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100a95:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a98:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100a9b:	83 ec 08             	sub    $0x8,%esp
f0100a9e:	57                   	push   %edi
f0100a9f:	6a 24                	push   $0x24
f0100aa1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aa4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aa7:	b8 30 1f 10 f0       	mov    $0xf0101f30,%eax
f0100aac:	e8 50 fe ff ff       	call   f0100901 <stab_binsearch>

	if (lfun <= rfun) {
f0100ab1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ab4:	83 c4 10             	add    $0x10,%esp
f0100ab7:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100aba:	7f 68                	jg     f0100b24 <debuginfo_eip+0x133>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100abc:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100abf:	c1 e0 02             	shl    $0x2,%eax
f0100ac2:	8d 90 30 1f 10 f0    	lea    -0xfefe0d0(%eax),%edx
f0100ac8:	8b 88 30 1f 10 f0    	mov    -0xfefe0d0(%eax),%ecx
f0100ace:	b8 bd 74 10 f0       	mov    $0xf01074bd,%eax
f0100ad3:	2d 31 5b 10 f0       	sub    $0xf0105b31,%eax
f0100ad8:	39 c1                	cmp    %eax,%ecx
f0100ada:	73 09                	jae    f0100ae5 <debuginfo_eip+0xf4>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100adc:	81 c1 31 5b 10 f0    	add    $0xf0105b31,%ecx
f0100ae2:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ae5:	8b 42 08             	mov    0x8(%edx),%eax
f0100ae8:	89 46 10             	mov    %eax,0x10(%esi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100aeb:	83 ec 08             	sub    $0x8,%esp
f0100aee:	6a 3a                	push   $0x3a
f0100af0:	ff 76 08             	pushl  0x8(%esi)
f0100af3:	e8 a9 08 00 00       	call   f01013a1 <strfind>
f0100af8:	2b 46 08             	sub    0x8(%esi),%eax
f0100afb:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100afe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b01:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b04:	8d 04 85 34 1f 10 f0 	lea    -0xfefe0cc(,%eax,4),%eax
f0100b0b:	83 c4 10             	add    $0x10,%esp
f0100b0e:	eb 22                	jmp    f0100b32 <debuginfo_eip+0x141>
  	        panic("User address");
f0100b10:	83 ec 04             	sub    $0x4,%esp
f0100b13:	68 e6 1c 10 f0       	push   $0xf0101ce6
f0100b18:	6a 7f                	push   $0x7f
f0100b1a:	68 f3 1c 10 f0       	push   $0xf0101cf3
f0100b1f:	e8 c2 f5 ff ff       	call   f01000e6 <_panic>
		info->eip_fn_addr = addr;
f0100b24:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b27:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b2a:	eb bf                	jmp    f0100aeb <debuginfo_eip+0xfa>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b2c:	83 eb 01             	sub    $0x1,%ebx
f0100b2f:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100b32:	39 df                	cmp    %ebx,%edi
f0100b34:	7f 33                	jg     f0100b69 <debuginfo_eip+0x178>
	       && stabs[lline].n_type != N_SOL
f0100b36:	0f b6 10             	movzbl (%eax),%edx
f0100b39:	80 fa 84             	cmp    $0x84,%dl
f0100b3c:	74 0b                	je     f0100b49 <debuginfo_eip+0x158>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b3e:	80 fa 64             	cmp    $0x64,%dl
f0100b41:	75 e9                	jne    f0100b2c <debuginfo_eip+0x13b>
f0100b43:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100b47:	74 e3                	je     f0100b2c <debuginfo_eip+0x13b>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b49:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b4c:	8b 14 85 30 1f 10 f0 	mov    -0xfefe0d0(,%eax,4),%edx
f0100b53:	b8 bd 74 10 f0       	mov    $0xf01074bd,%eax
f0100b58:	2d 31 5b 10 f0       	sub    $0xf0105b31,%eax
f0100b5d:	39 c2                	cmp    %eax,%edx
f0100b5f:	73 08                	jae    f0100b69 <debuginfo_eip+0x178>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b61:	81 c2 31 5b 10 f0    	add    $0xf0105b31,%edx
f0100b67:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b69:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b6c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b6f:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100b74:	39 cb                	cmp    %ecx,%ebx
f0100b76:	7d 44                	jge    f0100bbc <debuginfo_eip+0x1cb>
		for (lline = lfun + 1;
f0100b78:	8d 53 01             	lea    0x1(%ebx),%edx
f0100b7b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b7e:	8d 04 85 40 1f 10 f0 	lea    -0xfefe0c0(,%eax,4),%eax
f0100b85:	eb 07                	jmp    f0100b8e <debuginfo_eip+0x19d>
			info->eip_fn_narg++;
f0100b87:	83 46 14 01          	addl   $0x1,0x14(%esi)
		     lline++)
f0100b8b:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100b8e:	39 d1                	cmp    %edx,%ecx
f0100b90:	74 25                	je     f0100bb7 <debuginfo_eip+0x1c6>
f0100b92:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b95:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100b99:	74 ec                	je     f0100b87 <debuginfo_eip+0x196>
	return 0;
f0100b9b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ba0:	eb 1a                	jmp    f0100bbc <debuginfo_eip+0x1cb>
		return -1;
f0100ba2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ba7:	eb 13                	jmp    f0100bbc <debuginfo_eip+0x1cb>
f0100ba9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bae:	eb 0c                	jmp    f0100bbc <debuginfo_eip+0x1cb>
		return -1;
f0100bb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bb5:	eb 05                	jmp    f0100bbc <debuginfo_eip+0x1cb>
	return 0;
f0100bb7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bbf:	5b                   	pop    %ebx
f0100bc0:	5e                   	pop    %esi
f0100bc1:	5f                   	pop    %edi
f0100bc2:	5d                   	pop    %ebp
f0100bc3:	c3                   	ret    

f0100bc4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bc4:	55                   	push   %ebp
f0100bc5:	89 e5                	mov    %esp,%ebp
f0100bc7:	57                   	push   %edi
f0100bc8:	56                   	push   %esi
f0100bc9:	53                   	push   %ebx
f0100bca:	83 ec 1c             	sub    $0x1c,%esp
f0100bcd:	89 c7                	mov    %eax,%edi
f0100bcf:	89 d6                	mov    %edx,%esi
f0100bd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bd4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bd7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bda:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bdd:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100be0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100be5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100be8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100beb:	39 d3                	cmp    %edx,%ebx
f0100bed:	72 05                	jb     f0100bf4 <printnum+0x30>
f0100bef:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100bf2:	77 7a                	ja     f0100c6e <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bf4:	83 ec 0c             	sub    $0xc,%esp
f0100bf7:	ff 75 18             	pushl  0x18(%ebp)
f0100bfa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bfd:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c00:	53                   	push   %ebx
f0100c01:	ff 75 10             	pushl  0x10(%ebp)
f0100c04:	83 ec 08             	sub    $0x8,%esp
f0100c07:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c0a:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c0d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c10:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c13:	e8 a8 09 00 00       	call   f01015c0 <__udivdi3>
f0100c18:	83 c4 18             	add    $0x18,%esp
f0100c1b:	52                   	push   %edx
f0100c1c:	50                   	push   %eax
f0100c1d:	89 f2                	mov    %esi,%edx
f0100c1f:	89 f8                	mov    %edi,%eax
f0100c21:	e8 9e ff ff ff       	call   f0100bc4 <printnum>
f0100c26:	83 c4 20             	add    $0x20,%esp
f0100c29:	eb 13                	jmp    f0100c3e <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c2b:	83 ec 08             	sub    $0x8,%esp
f0100c2e:	56                   	push   %esi
f0100c2f:	ff 75 18             	pushl  0x18(%ebp)
f0100c32:	ff d7                	call   *%edi
f0100c34:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100c37:	83 eb 01             	sub    $0x1,%ebx
f0100c3a:	85 db                	test   %ebx,%ebx
f0100c3c:	7f ed                	jg     f0100c2b <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c3e:	83 ec 08             	sub    $0x8,%esp
f0100c41:	56                   	push   %esi
f0100c42:	83 ec 04             	sub    $0x4,%esp
f0100c45:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c48:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c4b:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c4e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c51:	e8 8a 0a 00 00       	call   f01016e0 <__umoddi3>
f0100c56:	83 c4 14             	add    $0x14,%esp
f0100c59:	0f be 80 01 1d 10 f0 	movsbl -0xfefe2ff(%eax),%eax
f0100c60:	50                   	push   %eax
f0100c61:	ff d7                	call   *%edi
}
f0100c63:	83 c4 10             	add    $0x10,%esp
f0100c66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c69:	5b                   	pop    %ebx
f0100c6a:	5e                   	pop    %esi
f0100c6b:	5f                   	pop    %edi
f0100c6c:	5d                   	pop    %ebp
f0100c6d:	c3                   	ret    
f0100c6e:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c71:	eb c4                	jmp    f0100c37 <printnum+0x73>

f0100c73 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c73:	55                   	push   %ebp
f0100c74:	89 e5                	mov    %esp,%ebp
f0100c76:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100c79:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100c7d:	8b 10                	mov    (%eax),%edx
f0100c7f:	3b 50 04             	cmp    0x4(%eax),%edx
f0100c82:	73 0a                	jae    f0100c8e <sprintputch+0x1b>
		*b->buf++ = ch;
f0100c84:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100c87:	89 08                	mov    %ecx,(%eax)
f0100c89:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c8c:	88 02                	mov    %al,(%edx)
}
f0100c8e:	5d                   	pop    %ebp
f0100c8f:	c3                   	ret    

f0100c90 <printfmt>:
{
f0100c90:	55                   	push   %ebp
f0100c91:	89 e5                	mov    %esp,%ebp
f0100c93:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100c96:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100c99:	50                   	push   %eax
f0100c9a:	ff 75 10             	pushl  0x10(%ebp)
f0100c9d:	ff 75 0c             	pushl  0xc(%ebp)
f0100ca0:	ff 75 08             	pushl  0x8(%ebp)
f0100ca3:	e8 05 00 00 00       	call   f0100cad <vprintfmt>
}
f0100ca8:	83 c4 10             	add    $0x10,%esp
f0100cab:	c9                   	leave  
f0100cac:	c3                   	ret    

f0100cad <vprintfmt>:
{
f0100cad:	55                   	push   %ebp
f0100cae:	89 e5                	mov    %esp,%ebp
f0100cb0:	57                   	push   %edi
f0100cb1:	56                   	push   %esi
f0100cb2:	53                   	push   %ebx
f0100cb3:	83 ec 2c             	sub    $0x2c,%esp
f0100cb6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100cb9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100cbc:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100cbf:	e9 8c 03 00 00       	jmp    f0101050 <vprintfmt+0x3a3>
		padc = ' ';
f0100cc4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100cc8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100ccf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100cd6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100cdd:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0100ce2:	8d 47 01             	lea    0x1(%edi),%eax
f0100ce5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ce8:	0f b6 17             	movzbl (%edi),%edx
f0100ceb:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100cee:	3c 55                	cmp    $0x55,%al
f0100cf0:	0f 87 dd 03 00 00    	ja     f01010d3 <vprintfmt+0x426>
f0100cf6:	0f b6 c0             	movzbl %al,%eax
f0100cf9:	ff 24 85 a0 1d 10 f0 	jmp    *-0xfefe260(,%eax,4)
f0100d00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100d03:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100d07:	eb d9                	jmp    f0100ce2 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0100d09:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100d0c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d10:	eb d0                	jmp    f0100ce2 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0100d12:	0f b6 d2             	movzbl %dl,%edx
f0100d15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100d18:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0100d20:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d23:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d27:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d2a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d2d:	83 f9 09             	cmp    $0x9,%ecx
f0100d30:	77 55                	ja     f0100d87 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f0100d32:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100d35:	eb e9                	jmp    f0100d20 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f0100d37:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d3a:	8b 00                	mov    (%eax),%eax
f0100d3c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d3f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d42:	8d 40 04             	lea    0x4(%eax),%eax
f0100d45:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100d48:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100d4b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d4f:	79 91                	jns    f0100ce2 <vprintfmt+0x35>
				width = precision, precision = -1;
f0100d51:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d54:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d57:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d5e:	eb 82                	jmp    f0100ce2 <vprintfmt+0x35>
f0100d60:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d63:	85 c0                	test   %eax,%eax
f0100d65:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d6a:	0f 49 d0             	cmovns %eax,%edx
f0100d6d:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100d70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d73:	e9 6a ff ff ff       	jmp    f0100ce2 <vprintfmt+0x35>
f0100d78:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100d7b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100d82:	e9 5b ff ff ff       	jmp    f0100ce2 <vprintfmt+0x35>
f0100d87:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d8a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d8d:	eb bc                	jmp    f0100d4b <vprintfmt+0x9e>
			lflag++;
f0100d8f:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0100d92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100d95:	e9 48 ff ff ff       	jmp    f0100ce2 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0100d9a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d9d:	8d 78 04             	lea    0x4(%eax),%edi
f0100da0:	83 ec 08             	sub    $0x8,%esp
f0100da3:	53                   	push   %ebx
f0100da4:	ff 30                	pushl  (%eax)
f0100da6:	ff d6                	call   *%esi
			break;
f0100da8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100dab:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100dae:	e9 9a 02 00 00       	jmp    f010104d <vprintfmt+0x3a0>
			err = va_arg(ap, int);
f0100db3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100db6:	8d 78 04             	lea    0x4(%eax),%edi
f0100db9:	8b 00                	mov    (%eax),%eax
f0100dbb:	99                   	cltd   
f0100dbc:	31 d0                	xor    %edx,%eax
f0100dbe:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100dc0:	83 f8 07             	cmp    $0x7,%eax
f0100dc3:	7f 23                	jg     f0100de8 <vprintfmt+0x13b>
f0100dc5:	8b 14 85 00 1f 10 f0 	mov    -0xfefe100(,%eax,4),%edx
f0100dcc:	85 d2                	test   %edx,%edx
f0100dce:	74 18                	je     f0100de8 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0100dd0:	52                   	push   %edx
f0100dd1:	68 22 1d 10 f0       	push   $0xf0101d22
f0100dd6:	53                   	push   %ebx
f0100dd7:	56                   	push   %esi
f0100dd8:	e8 b3 fe ff ff       	call   f0100c90 <printfmt>
f0100ddd:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100de0:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100de3:	e9 65 02 00 00       	jmp    f010104d <vprintfmt+0x3a0>
				printfmt(putch, putdat, "error %d", err);
f0100de8:	50                   	push   %eax
f0100de9:	68 19 1d 10 f0       	push   $0xf0101d19
f0100dee:	53                   	push   %ebx
f0100def:	56                   	push   %esi
f0100df0:	e8 9b fe ff ff       	call   f0100c90 <printfmt>
f0100df5:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100df8:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100dfb:	e9 4d 02 00 00       	jmp    f010104d <vprintfmt+0x3a0>
			if ((p = va_arg(ap, char *)) == NULL)
f0100e00:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e03:	83 c0 04             	add    $0x4,%eax
f0100e06:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e09:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e0c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100e0e:	85 ff                	test   %edi,%edi
f0100e10:	b8 12 1d 10 f0       	mov    $0xf0101d12,%eax
f0100e15:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100e18:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e1c:	0f 8e bd 00 00 00    	jle    f0100edf <vprintfmt+0x232>
f0100e22:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e26:	75 0e                	jne    f0100e36 <vprintfmt+0x189>
f0100e28:	89 75 08             	mov    %esi,0x8(%ebp)
f0100e2b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100e2e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100e31:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100e34:	eb 6d                	jmp    f0100ea3 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e36:	83 ec 08             	sub    $0x8,%esp
f0100e39:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e3c:	57                   	push   %edi
f0100e3d:	e8 1b 04 00 00       	call   f010125d <strnlen>
f0100e42:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e45:	29 c1                	sub    %eax,%ecx
f0100e47:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100e4a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100e4d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100e51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e54:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e57:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e59:	eb 0f                	jmp    f0100e6a <vprintfmt+0x1bd>
					putch(padc, putdat);
f0100e5b:	83 ec 08             	sub    $0x8,%esp
f0100e5e:	53                   	push   %ebx
f0100e5f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e62:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e64:	83 ef 01             	sub    $0x1,%edi
f0100e67:	83 c4 10             	add    $0x10,%esp
f0100e6a:	85 ff                	test   %edi,%edi
f0100e6c:	7f ed                	jg     f0100e5b <vprintfmt+0x1ae>
f0100e6e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e71:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100e74:	85 c9                	test   %ecx,%ecx
f0100e76:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e7b:	0f 49 c1             	cmovns %ecx,%eax
f0100e7e:	29 c1                	sub    %eax,%ecx
f0100e80:	89 75 08             	mov    %esi,0x8(%ebp)
f0100e83:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100e86:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100e89:	89 cb                	mov    %ecx,%ebx
f0100e8b:	eb 16                	jmp    f0100ea3 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f0100e8d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e91:	75 31                	jne    f0100ec4 <vprintfmt+0x217>
					putch(ch, putdat);
f0100e93:	83 ec 08             	sub    $0x8,%esp
f0100e96:	ff 75 0c             	pushl  0xc(%ebp)
f0100e99:	50                   	push   %eax
f0100e9a:	ff 55 08             	call   *0x8(%ebp)
f0100e9d:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ea0:	83 eb 01             	sub    $0x1,%ebx
f0100ea3:	83 c7 01             	add    $0x1,%edi
f0100ea6:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0100eaa:	0f be c2             	movsbl %dl,%eax
f0100ead:	85 c0                	test   %eax,%eax
f0100eaf:	74 59                	je     f0100f0a <vprintfmt+0x25d>
f0100eb1:	85 f6                	test   %esi,%esi
f0100eb3:	78 d8                	js     f0100e8d <vprintfmt+0x1e0>
f0100eb5:	83 ee 01             	sub    $0x1,%esi
f0100eb8:	79 d3                	jns    f0100e8d <vprintfmt+0x1e0>
f0100eba:	89 df                	mov    %ebx,%edi
f0100ebc:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ebf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ec2:	eb 37                	jmp    f0100efb <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0100ec4:	0f be d2             	movsbl %dl,%edx
f0100ec7:	83 ea 20             	sub    $0x20,%edx
f0100eca:	83 fa 5e             	cmp    $0x5e,%edx
f0100ecd:	76 c4                	jbe    f0100e93 <vprintfmt+0x1e6>
					putch('?', putdat);
f0100ecf:	83 ec 08             	sub    $0x8,%esp
f0100ed2:	ff 75 0c             	pushl  0xc(%ebp)
f0100ed5:	6a 3f                	push   $0x3f
f0100ed7:	ff 55 08             	call   *0x8(%ebp)
f0100eda:	83 c4 10             	add    $0x10,%esp
f0100edd:	eb c1                	jmp    f0100ea0 <vprintfmt+0x1f3>
f0100edf:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ee2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ee5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ee8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100eeb:	eb b6                	jmp    f0100ea3 <vprintfmt+0x1f6>
				putch(' ', putdat);
f0100eed:	83 ec 08             	sub    $0x8,%esp
f0100ef0:	53                   	push   %ebx
f0100ef1:	6a 20                	push   $0x20
f0100ef3:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0100ef5:	83 ef 01             	sub    $0x1,%edi
f0100ef8:	83 c4 10             	add    $0x10,%esp
f0100efb:	85 ff                	test   %edi,%edi
f0100efd:	7f ee                	jg     f0100eed <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f0100eff:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f02:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f05:	e9 43 01 00 00       	jmp    f010104d <vprintfmt+0x3a0>
f0100f0a:	89 df                	mov    %ebx,%edi
f0100f0c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f0f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f12:	eb e7                	jmp    f0100efb <vprintfmt+0x24e>
	if (lflag >= 2)
f0100f14:	83 f9 01             	cmp    $0x1,%ecx
f0100f17:	7e 3f                	jle    f0100f58 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f0100f19:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1c:	8b 50 04             	mov    0x4(%eax),%edx
f0100f1f:	8b 00                	mov    (%eax),%eax
f0100f21:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f24:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f27:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2a:	8d 40 08             	lea    0x8(%eax),%eax
f0100f2d:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0100f30:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f34:	79 5c                	jns    f0100f92 <vprintfmt+0x2e5>
				putch('-', putdat);
f0100f36:	83 ec 08             	sub    $0x8,%esp
f0100f39:	53                   	push   %ebx
f0100f3a:	6a 2d                	push   $0x2d
f0100f3c:	ff d6                	call   *%esi
				num = -(long long) num;
f0100f3e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f41:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f44:	f7 da                	neg    %edx
f0100f46:	83 d1 00             	adc    $0x0,%ecx
f0100f49:	f7 d9                	neg    %ecx
f0100f4b:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0100f4e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f53:	e9 db 00 00 00       	jmp    f0101033 <vprintfmt+0x386>
	else if (lflag)
f0100f58:	85 c9                	test   %ecx,%ecx
f0100f5a:	75 1b                	jne    f0100f77 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0100f5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f5f:	8b 00                	mov    (%eax),%eax
f0100f61:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f64:	89 c1                	mov    %eax,%ecx
f0100f66:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f69:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f6c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6f:	8d 40 04             	lea    0x4(%eax),%eax
f0100f72:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f75:	eb b9                	jmp    f0100f30 <vprintfmt+0x283>
		return va_arg(*ap, long);
f0100f77:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7a:	8b 00                	mov    (%eax),%eax
f0100f7c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f7f:	89 c1                	mov    %eax,%ecx
f0100f81:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f84:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f87:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8a:	8d 40 04             	lea    0x4(%eax),%eax
f0100f8d:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f90:	eb 9e                	jmp    f0100f30 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0100f92:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f95:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0100f98:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f9d:	e9 91 00 00 00       	jmp    f0101033 <vprintfmt+0x386>
	if (lflag >= 2)
f0100fa2:	83 f9 01             	cmp    $0x1,%ecx
f0100fa5:	7e 15                	jle    f0100fbc <vprintfmt+0x30f>
		return va_arg(*ap, unsigned long long);
f0100fa7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100faa:	8b 10                	mov    (%eax),%edx
f0100fac:	8b 48 04             	mov    0x4(%eax),%ecx
f0100faf:	8d 40 08             	lea    0x8(%eax),%eax
f0100fb2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0100fb5:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fba:	eb 77                	jmp    f0101033 <vprintfmt+0x386>
	else if (lflag)
f0100fbc:	85 c9                	test   %ecx,%ecx
f0100fbe:	75 17                	jne    f0100fd7 <vprintfmt+0x32a>
		return va_arg(*ap, unsigned int);
f0100fc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc3:	8b 10                	mov    (%eax),%edx
f0100fc5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fca:	8d 40 04             	lea    0x4(%eax),%eax
f0100fcd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0100fd0:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fd5:	eb 5c                	jmp    f0101033 <vprintfmt+0x386>
		return va_arg(*ap, unsigned long);
f0100fd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fda:	8b 10                	mov    (%eax),%edx
f0100fdc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fe1:	8d 40 04             	lea    0x4(%eax),%eax
f0100fe4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0100fe7:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fec:	eb 45                	jmp    f0101033 <vprintfmt+0x386>
			putch('X', putdat);
f0100fee:	83 ec 08             	sub    $0x8,%esp
f0100ff1:	53                   	push   %ebx
f0100ff2:	6a 58                	push   $0x58
f0100ff4:	ff d6                	call   *%esi
			putch('X', putdat);
f0100ff6:	83 c4 08             	add    $0x8,%esp
f0100ff9:	53                   	push   %ebx
f0100ffa:	6a 58                	push   $0x58
f0100ffc:	ff d6                	call   *%esi
			putch('X', putdat);
f0100ffe:	83 c4 08             	add    $0x8,%esp
f0101001:	53                   	push   %ebx
f0101002:	6a 58                	push   $0x58
f0101004:	ff d6                	call   *%esi
			break;
f0101006:	83 c4 10             	add    $0x10,%esp
f0101009:	eb 42                	jmp    f010104d <vprintfmt+0x3a0>
			putch('0', putdat);
f010100b:	83 ec 08             	sub    $0x8,%esp
f010100e:	53                   	push   %ebx
f010100f:	6a 30                	push   $0x30
f0101011:	ff d6                	call   *%esi
			putch('x', putdat);
f0101013:	83 c4 08             	add    $0x8,%esp
f0101016:	53                   	push   %ebx
f0101017:	6a 78                	push   $0x78
f0101019:	ff d6                	call   *%esi
			num = (unsigned long long)
f010101b:	8b 45 14             	mov    0x14(%ebp),%eax
f010101e:	8b 10                	mov    (%eax),%edx
f0101020:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101025:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101028:	8d 40 04             	lea    0x4(%eax),%eax
f010102b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010102e:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101033:	83 ec 0c             	sub    $0xc,%esp
f0101036:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010103a:	57                   	push   %edi
f010103b:	ff 75 e0             	pushl  -0x20(%ebp)
f010103e:	50                   	push   %eax
f010103f:	51                   	push   %ecx
f0101040:	52                   	push   %edx
f0101041:	89 da                	mov    %ebx,%edx
f0101043:	89 f0                	mov    %esi,%eax
f0101045:	e8 7a fb ff ff       	call   f0100bc4 <printnum>
			break;
f010104a:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010104d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101050:	83 c7 01             	add    $0x1,%edi
f0101053:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101057:	83 f8 25             	cmp    $0x25,%eax
f010105a:	0f 84 64 fc ff ff    	je     f0100cc4 <vprintfmt+0x17>
			if (ch == '\0')
f0101060:	85 c0                	test   %eax,%eax
f0101062:	0f 84 8b 00 00 00    	je     f01010f3 <vprintfmt+0x446>
			putch(ch, putdat);
f0101068:	83 ec 08             	sub    $0x8,%esp
f010106b:	53                   	push   %ebx
f010106c:	50                   	push   %eax
f010106d:	ff d6                	call   *%esi
f010106f:	83 c4 10             	add    $0x10,%esp
f0101072:	eb dc                	jmp    f0101050 <vprintfmt+0x3a3>
	if (lflag >= 2)
f0101074:	83 f9 01             	cmp    $0x1,%ecx
f0101077:	7e 15                	jle    f010108e <vprintfmt+0x3e1>
		return va_arg(*ap, unsigned long long);
f0101079:	8b 45 14             	mov    0x14(%ebp),%eax
f010107c:	8b 10                	mov    (%eax),%edx
f010107e:	8b 48 04             	mov    0x4(%eax),%ecx
f0101081:	8d 40 08             	lea    0x8(%eax),%eax
f0101084:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101087:	b8 10 00 00 00       	mov    $0x10,%eax
f010108c:	eb a5                	jmp    f0101033 <vprintfmt+0x386>
	else if (lflag)
f010108e:	85 c9                	test   %ecx,%ecx
f0101090:	75 17                	jne    f01010a9 <vprintfmt+0x3fc>
		return va_arg(*ap, unsigned int);
f0101092:	8b 45 14             	mov    0x14(%ebp),%eax
f0101095:	8b 10                	mov    (%eax),%edx
f0101097:	b9 00 00 00 00       	mov    $0x0,%ecx
f010109c:	8d 40 04             	lea    0x4(%eax),%eax
f010109f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01010a2:	b8 10 00 00 00       	mov    $0x10,%eax
f01010a7:	eb 8a                	jmp    f0101033 <vprintfmt+0x386>
		return va_arg(*ap, unsigned long);
f01010a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ac:	8b 10                	mov    (%eax),%edx
f01010ae:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010b3:	8d 40 04             	lea    0x4(%eax),%eax
f01010b6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01010b9:	b8 10 00 00 00       	mov    $0x10,%eax
f01010be:	e9 70 ff ff ff       	jmp    f0101033 <vprintfmt+0x386>
			putch(ch, putdat);
f01010c3:	83 ec 08             	sub    $0x8,%esp
f01010c6:	53                   	push   %ebx
f01010c7:	6a 25                	push   $0x25
f01010c9:	ff d6                	call   *%esi
			break;
f01010cb:	83 c4 10             	add    $0x10,%esp
f01010ce:	e9 7a ff ff ff       	jmp    f010104d <vprintfmt+0x3a0>
			putch('%', putdat);
f01010d3:	83 ec 08             	sub    $0x8,%esp
f01010d6:	53                   	push   %ebx
f01010d7:	6a 25                	push   $0x25
f01010d9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010db:	83 c4 10             	add    $0x10,%esp
f01010de:	89 f8                	mov    %edi,%eax
f01010e0:	eb 03                	jmp    f01010e5 <vprintfmt+0x438>
f01010e2:	83 e8 01             	sub    $0x1,%eax
f01010e5:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01010e9:	75 f7                	jne    f01010e2 <vprintfmt+0x435>
f01010eb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010ee:	e9 5a ff ff ff       	jmp    f010104d <vprintfmt+0x3a0>
}
f01010f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010f6:	5b                   	pop    %ebx
f01010f7:	5e                   	pop    %esi
f01010f8:	5f                   	pop    %edi
f01010f9:	5d                   	pop    %ebp
f01010fa:	c3                   	ret    

f01010fb <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01010fb:	55                   	push   %ebp
f01010fc:	89 e5                	mov    %esp,%ebp
f01010fe:	83 ec 18             	sub    $0x18,%esp
f0101101:	8b 45 08             	mov    0x8(%ebp),%eax
f0101104:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101107:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010110a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010110e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101111:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101118:	85 c0                	test   %eax,%eax
f010111a:	74 26                	je     f0101142 <vsnprintf+0x47>
f010111c:	85 d2                	test   %edx,%edx
f010111e:	7e 22                	jle    f0101142 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101120:	ff 75 14             	pushl  0x14(%ebp)
f0101123:	ff 75 10             	pushl  0x10(%ebp)
f0101126:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101129:	50                   	push   %eax
f010112a:	68 73 0c 10 f0       	push   $0xf0100c73
f010112f:	e8 79 fb ff ff       	call   f0100cad <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101134:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101137:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010113a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010113d:	83 c4 10             	add    $0x10,%esp
}
f0101140:	c9                   	leave  
f0101141:	c3                   	ret    
		return -E_INVAL;
f0101142:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101147:	eb f7                	jmp    f0101140 <vsnprintf+0x45>

f0101149 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101149:	55                   	push   %ebp
f010114a:	89 e5                	mov    %esp,%ebp
f010114c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010114f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101152:	50                   	push   %eax
f0101153:	ff 75 10             	pushl  0x10(%ebp)
f0101156:	ff 75 0c             	pushl  0xc(%ebp)
f0101159:	ff 75 08             	pushl  0x8(%ebp)
f010115c:	e8 9a ff ff ff       	call   f01010fb <vsnprintf>
	va_end(ap);

	return rc;
}
f0101161:	c9                   	leave  
f0101162:	c3                   	ret    

f0101163 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101163:	55                   	push   %ebp
f0101164:	89 e5                	mov    %esp,%ebp
f0101166:	57                   	push   %edi
f0101167:	56                   	push   %esi
f0101168:	53                   	push   %ebx
f0101169:	83 ec 0c             	sub    $0xc,%esp
f010116c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010116f:	85 c0                	test   %eax,%eax
f0101171:	74 11                	je     f0101184 <readline+0x21>
		cprintf("%s", prompt);
f0101173:	83 ec 08             	sub    $0x8,%esp
f0101176:	50                   	push   %eax
f0101177:	68 22 1d 10 f0       	push   $0xf0101d22
f010117c:	e8 6c f7 ff ff       	call   f01008ed <cprintf>
f0101181:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101184:	83 ec 0c             	sub    $0xc,%esp
f0101187:	6a 00                	push   $0x0
f0101189:	e8 fd f4 ff ff       	call   f010068b <iscons>
f010118e:	89 c7                	mov    %eax,%edi
f0101190:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101193:	be 00 00 00 00       	mov    $0x0,%esi
f0101198:	eb 3f                	jmp    f01011d9 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010119a:	83 ec 08             	sub    $0x8,%esp
f010119d:	50                   	push   %eax
f010119e:	68 20 1f 10 f0       	push   $0xf0101f20
f01011a3:	e8 45 f7 ff ff       	call   f01008ed <cprintf>
			return NULL;
f01011a8:	83 c4 10             	add    $0x10,%esp
f01011ab:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01011b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011b3:	5b                   	pop    %ebx
f01011b4:	5e                   	pop    %esi
f01011b5:	5f                   	pop    %edi
f01011b6:	5d                   	pop    %ebp
f01011b7:	c3                   	ret    
			if (echoing)
f01011b8:	85 ff                	test   %edi,%edi
f01011ba:	75 05                	jne    f01011c1 <readline+0x5e>
			i--;
f01011bc:	83 ee 01             	sub    $0x1,%esi
f01011bf:	eb 18                	jmp    f01011d9 <readline+0x76>
				cputchar('\b');
f01011c1:	83 ec 0c             	sub    $0xc,%esp
f01011c4:	6a 08                	push   $0x8
f01011c6:	e8 9f f4 ff ff       	call   f010066a <cputchar>
f01011cb:	83 c4 10             	add    $0x10,%esp
f01011ce:	eb ec                	jmp    f01011bc <readline+0x59>
			buf[i++] = c;
f01011d0:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01011d6:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01011d9:	e8 9c f4 ff ff       	call   f010067a <getchar>
f01011de:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011e0:	85 c0                	test   %eax,%eax
f01011e2:	78 b6                	js     f010119a <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011e4:	83 f8 08             	cmp    $0x8,%eax
f01011e7:	0f 94 c2             	sete   %dl
f01011ea:	83 f8 7f             	cmp    $0x7f,%eax
f01011ed:	0f 94 c0             	sete   %al
f01011f0:	08 c2                	or     %al,%dl
f01011f2:	74 04                	je     f01011f8 <readline+0x95>
f01011f4:	85 f6                	test   %esi,%esi
f01011f6:	7f c0                	jg     f01011b8 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011f8:	83 fb 1f             	cmp    $0x1f,%ebx
f01011fb:	7e 1a                	jle    f0101217 <readline+0xb4>
f01011fd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101203:	7f 12                	jg     f0101217 <readline+0xb4>
			if (echoing)
f0101205:	85 ff                	test   %edi,%edi
f0101207:	74 c7                	je     f01011d0 <readline+0x6d>
				cputchar(c);
f0101209:	83 ec 0c             	sub    $0xc,%esp
f010120c:	53                   	push   %ebx
f010120d:	e8 58 f4 ff ff       	call   f010066a <cputchar>
f0101212:	83 c4 10             	add    $0x10,%esp
f0101215:	eb b9                	jmp    f01011d0 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0101217:	83 fb 0a             	cmp    $0xa,%ebx
f010121a:	74 05                	je     f0101221 <readline+0xbe>
f010121c:	83 fb 0d             	cmp    $0xd,%ebx
f010121f:	75 b8                	jne    f01011d9 <readline+0x76>
			if (echoing)
f0101221:	85 ff                	test   %edi,%edi
f0101223:	75 11                	jne    f0101236 <readline+0xd3>
			buf[i] = 0;
f0101225:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010122c:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
f0101231:	e9 7a ff ff ff       	jmp    f01011b0 <readline+0x4d>
				cputchar('\n');
f0101236:	83 ec 0c             	sub    $0xc,%esp
f0101239:	6a 0a                	push   $0xa
f010123b:	e8 2a f4 ff ff       	call   f010066a <cputchar>
f0101240:	83 c4 10             	add    $0x10,%esp
f0101243:	eb e0                	jmp    f0101225 <readline+0xc2>

f0101245 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101245:	55                   	push   %ebp
f0101246:	89 e5                	mov    %esp,%ebp
f0101248:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010124b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101250:	eb 03                	jmp    f0101255 <strlen+0x10>
		n++;
f0101252:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101255:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101259:	75 f7                	jne    f0101252 <strlen+0xd>
	return n;
}
f010125b:	5d                   	pop    %ebp
f010125c:	c3                   	ret    

f010125d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010125d:	55                   	push   %ebp
f010125e:	89 e5                	mov    %esp,%ebp
f0101260:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101263:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101266:	b8 00 00 00 00       	mov    $0x0,%eax
f010126b:	eb 03                	jmp    f0101270 <strnlen+0x13>
		n++;
f010126d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101270:	39 d0                	cmp    %edx,%eax
f0101272:	74 06                	je     f010127a <strnlen+0x1d>
f0101274:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101278:	75 f3                	jne    f010126d <strnlen+0x10>
	return n;
}
f010127a:	5d                   	pop    %ebp
f010127b:	c3                   	ret    

f010127c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010127c:	55                   	push   %ebp
f010127d:	89 e5                	mov    %esp,%ebp
f010127f:	53                   	push   %ebx
f0101280:	8b 45 08             	mov    0x8(%ebp),%eax
f0101283:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101286:	89 c2                	mov    %eax,%edx
f0101288:	83 c1 01             	add    $0x1,%ecx
f010128b:	83 c2 01             	add    $0x1,%edx
f010128e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101292:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101295:	84 db                	test   %bl,%bl
f0101297:	75 ef                	jne    f0101288 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101299:	5b                   	pop    %ebx
f010129a:	5d                   	pop    %ebp
f010129b:	c3                   	ret    

f010129c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010129c:	55                   	push   %ebp
f010129d:	89 e5                	mov    %esp,%ebp
f010129f:	53                   	push   %ebx
f01012a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012a3:	53                   	push   %ebx
f01012a4:	e8 9c ff ff ff       	call   f0101245 <strlen>
f01012a9:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012ac:	ff 75 0c             	pushl  0xc(%ebp)
f01012af:	01 d8                	add    %ebx,%eax
f01012b1:	50                   	push   %eax
f01012b2:	e8 c5 ff ff ff       	call   f010127c <strcpy>
	return dst;
}
f01012b7:	89 d8                	mov    %ebx,%eax
f01012b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012bc:	c9                   	leave  
f01012bd:	c3                   	ret    

f01012be <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012be:	55                   	push   %ebp
f01012bf:	89 e5                	mov    %esp,%ebp
f01012c1:	56                   	push   %esi
f01012c2:	53                   	push   %ebx
f01012c3:	8b 75 08             	mov    0x8(%ebp),%esi
f01012c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012c9:	89 f3                	mov    %esi,%ebx
f01012cb:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012ce:	89 f2                	mov    %esi,%edx
f01012d0:	eb 0f                	jmp    f01012e1 <strncpy+0x23>
		*dst++ = *src;
f01012d2:	83 c2 01             	add    $0x1,%edx
f01012d5:	0f b6 01             	movzbl (%ecx),%eax
f01012d8:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012db:	80 39 01             	cmpb   $0x1,(%ecx)
f01012de:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01012e1:	39 da                	cmp    %ebx,%edx
f01012e3:	75 ed                	jne    f01012d2 <strncpy+0x14>
	}
	return ret;
}
f01012e5:	89 f0                	mov    %esi,%eax
f01012e7:	5b                   	pop    %ebx
f01012e8:	5e                   	pop    %esi
f01012e9:	5d                   	pop    %ebp
f01012ea:	c3                   	ret    

f01012eb <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012eb:	55                   	push   %ebp
f01012ec:	89 e5                	mov    %esp,%ebp
f01012ee:	56                   	push   %esi
f01012ef:	53                   	push   %ebx
f01012f0:	8b 75 08             	mov    0x8(%ebp),%esi
f01012f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01012f6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01012f9:	89 f0                	mov    %esi,%eax
f01012fb:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012ff:	85 c9                	test   %ecx,%ecx
f0101301:	75 0b                	jne    f010130e <strlcpy+0x23>
f0101303:	eb 17                	jmp    f010131c <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101305:	83 c2 01             	add    $0x1,%edx
f0101308:	83 c0 01             	add    $0x1,%eax
f010130b:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f010130e:	39 d8                	cmp    %ebx,%eax
f0101310:	74 07                	je     f0101319 <strlcpy+0x2e>
f0101312:	0f b6 0a             	movzbl (%edx),%ecx
f0101315:	84 c9                	test   %cl,%cl
f0101317:	75 ec                	jne    f0101305 <strlcpy+0x1a>
		*dst = '\0';
f0101319:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010131c:	29 f0                	sub    %esi,%eax
}
f010131e:	5b                   	pop    %ebx
f010131f:	5e                   	pop    %esi
f0101320:	5d                   	pop    %ebp
f0101321:	c3                   	ret    

f0101322 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101322:	55                   	push   %ebp
f0101323:	89 e5                	mov    %esp,%ebp
f0101325:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101328:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010132b:	eb 06                	jmp    f0101333 <strcmp+0x11>
		p++, q++;
f010132d:	83 c1 01             	add    $0x1,%ecx
f0101330:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101333:	0f b6 01             	movzbl (%ecx),%eax
f0101336:	84 c0                	test   %al,%al
f0101338:	74 04                	je     f010133e <strcmp+0x1c>
f010133a:	3a 02                	cmp    (%edx),%al
f010133c:	74 ef                	je     f010132d <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010133e:	0f b6 c0             	movzbl %al,%eax
f0101341:	0f b6 12             	movzbl (%edx),%edx
f0101344:	29 d0                	sub    %edx,%eax
}
f0101346:	5d                   	pop    %ebp
f0101347:	c3                   	ret    

f0101348 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101348:	55                   	push   %ebp
f0101349:	89 e5                	mov    %esp,%ebp
f010134b:	53                   	push   %ebx
f010134c:	8b 45 08             	mov    0x8(%ebp),%eax
f010134f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101352:	89 c3                	mov    %eax,%ebx
f0101354:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101357:	eb 06                	jmp    f010135f <strncmp+0x17>
		n--, p++, q++;
f0101359:	83 c0 01             	add    $0x1,%eax
f010135c:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010135f:	39 d8                	cmp    %ebx,%eax
f0101361:	74 16                	je     f0101379 <strncmp+0x31>
f0101363:	0f b6 08             	movzbl (%eax),%ecx
f0101366:	84 c9                	test   %cl,%cl
f0101368:	74 04                	je     f010136e <strncmp+0x26>
f010136a:	3a 0a                	cmp    (%edx),%cl
f010136c:	74 eb                	je     f0101359 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010136e:	0f b6 00             	movzbl (%eax),%eax
f0101371:	0f b6 12             	movzbl (%edx),%edx
f0101374:	29 d0                	sub    %edx,%eax
}
f0101376:	5b                   	pop    %ebx
f0101377:	5d                   	pop    %ebp
f0101378:	c3                   	ret    
		return 0;
f0101379:	b8 00 00 00 00       	mov    $0x0,%eax
f010137e:	eb f6                	jmp    f0101376 <strncmp+0x2e>

f0101380 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101380:	55                   	push   %ebp
f0101381:	89 e5                	mov    %esp,%ebp
f0101383:	8b 45 08             	mov    0x8(%ebp),%eax
f0101386:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010138a:	0f b6 10             	movzbl (%eax),%edx
f010138d:	84 d2                	test   %dl,%dl
f010138f:	74 09                	je     f010139a <strchr+0x1a>
		if (*s == c)
f0101391:	38 ca                	cmp    %cl,%dl
f0101393:	74 0a                	je     f010139f <strchr+0x1f>
	for (; *s; s++)
f0101395:	83 c0 01             	add    $0x1,%eax
f0101398:	eb f0                	jmp    f010138a <strchr+0xa>
			return (char *) s;
	return 0;
f010139a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010139f:	5d                   	pop    %ebp
f01013a0:	c3                   	ret    

f01013a1 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013a1:	55                   	push   %ebp
f01013a2:	89 e5                	mov    %esp,%ebp
f01013a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01013a7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013ab:	eb 03                	jmp    f01013b0 <strfind+0xf>
f01013ad:	83 c0 01             	add    $0x1,%eax
f01013b0:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013b3:	38 ca                	cmp    %cl,%dl
f01013b5:	74 04                	je     f01013bb <strfind+0x1a>
f01013b7:	84 d2                	test   %dl,%dl
f01013b9:	75 f2                	jne    f01013ad <strfind+0xc>
			break;
	return (char *) s;
}
f01013bb:	5d                   	pop    %ebp
f01013bc:	c3                   	ret    

f01013bd <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013bd:	55                   	push   %ebp
f01013be:	89 e5                	mov    %esp,%ebp
f01013c0:	57                   	push   %edi
f01013c1:	56                   	push   %esi
f01013c2:	53                   	push   %ebx
f01013c3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013c6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013c9:	85 c9                	test   %ecx,%ecx
f01013cb:	74 13                	je     f01013e0 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013cd:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013d3:	75 05                	jne    f01013da <memset+0x1d>
f01013d5:	f6 c1 03             	test   $0x3,%cl
f01013d8:	74 0d                	je     f01013e7 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01013da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013dd:	fc                   	cld    
f01013de:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01013e0:	89 f8                	mov    %edi,%eax
f01013e2:	5b                   	pop    %ebx
f01013e3:	5e                   	pop    %esi
f01013e4:	5f                   	pop    %edi
f01013e5:	5d                   	pop    %ebp
f01013e6:	c3                   	ret    
		c &= 0xFF;
f01013e7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013eb:	89 d3                	mov    %edx,%ebx
f01013ed:	c1 e3 08             	shl    $0x8,%ebx
f01013f0:	89 d0                	mov    %edx,%eax
f01013f2:	c1 e0 18             	shl    $0x18,%eax
f01013f5:	89 d6                	mov    %edx,%esi
f01013f7:	c1 e6 10             	shl    $0x10,%esi
f01013fa:	09 f0                	or     %esi,%eax
f01013fc:	09 c2                	or     %eax,%edx
f01013fe:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101400:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101403:	89 d0                	mov    %edx,%eax
f0101405:	fc                   	cld    
f0101406:	f3 ab                	rep stos %eax,%es:(%edi)
f0101408:	eb d6                	jmp    f01013e0 <memset+0x23>

f010140a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010140a:	55                   	push   %ebp
f010140b:	89 e5                	mov    %esp,%ebp
f010140d:	57                   	push   %edi
f010140e:	56                   	push   %esi
f010140f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101412:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101415:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101418:	39 c6                	cmp    %eax,%esi
f010141a:	73 35                	jae    f0101451 <memmove+0x47>
f010141c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010141f:	39 c2                	cmp    %eax,%edx
f0101421:	76 2e                	jbe    f0101451 <memmove+0x47>
		s += n;
		d += n;
f0101423:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101426:	89 d6                	mov    %edx,%esi
f0101428:	09 fe                	or     %edi,%esi
f010142a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101430:	74 0c                	je     f010143e <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101432:	83 ef 01             	sub    $0x1,%edi
f0101435:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101438:	fd                   	std    
f0101439:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010143b:	fc                   	cld    
f010143c:	eb 21                	jmp    f010145f <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010143e:	f6 c1 03             	test   $0x3,%cl
f0101441:	75 ef                	jne    f0101432 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101443:	83 ef 04             	sub    $0x4,%edi
f0101446:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101449:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010144c:	fd                   	std    
f010144d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010144f:	eb ea                	jmp    f010143b <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101451:	89 f2                	mov    %esi,%edx
f0101453:	09 c2                	or     %eax,%edx
f0101455:	f6 c2 03             	test   $0x3,%dl
f0101458:	74 09                	je     f0101463 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010145a:	89 c7                	mov    %eax,%edi
f010145c:	fc                   	cld    
f010145d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010145f:	5e                   	pop    %esi
f0101460:	5f                   	pop    %edi
f0101461:	5d                   	pop    %ebp
f0101462:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101463:	f6 c1 03             	test   $0x3,%cl
f0101466:	75 f2                	jne    f010145a <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101468:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010146b:	89 c7                	mov    %eax,%edi
f010146d:	fc                   	cld    
f010146e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101470:	eb ed                	jmp    f010145f <memmove+0x55>

f0101472 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101472:	55                   	push   %ebp
f0101473:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101475:	ff 75 10             	pushl  0x10(%ebp)
f0101478:	ff 75 0c             	pushl  0xc(%ebp)
f010147b:	ff 75 08             	pushl  0x8(%ebp)
f010147e:	e8 87 ff ff ff       	call   f010140a <memmove>
}
f0101483:	c9                   	leave  
f0101484:	c3                   	ret    

f0101485 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101485:	55                   	push   %ebp
f0101486:	89 e5                	mov    %esp,%ebp
f0101488:	56                   	push   %esi
f0101489:	53                   	push   %ebx
f010148a:	8b 45 08             	mov    0x8(%ebp),%eax
f010148d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101490:	89 c6                	mov    %eax,%esi
f0101492:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101495:	39 f0                	cmp    %esi,%eax
f0101497:	74 1c                	je     f01014b5 <memcmp+0x30>
		if (*s1 != *s2)
f0101499:	0f b6 08             	movzbl (%eax),%ecx
f010149c:	0f b6 1a             	movzbl (%edx),%ebx
f010149f:	38 d9                	cmp    %bl,%cl
f01014a1:	75 08                	jne    f01014ab <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01014a3:	83 c0 01             	add    $0x1,%eax
f01014a6:	83 c2 01             	add    $0x1,%edx
f01014a9:	eb ea                	jmp    f0101495 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01014ab:	0f b6 c1             	movzbl %cl,%eax
f01014ae:	0f b6 db             	movzbl %bl,%ebx
f01014b1:	29 d8                	sub    %ebx,%eax
f01014b3:	eb 05                	jmp    f01014ba <memcmp+0x35>
	}

	return 0;
f01014b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014ba:	5b                   	pop    %ebx
f01014bb:	5e                   	pop    %esi
f01014bc:	5d                   	pop    %ebp
f01014bd:	c3                   	ret    

f01014be <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014be:	55                   	push   %ebp
f01014bf:	89 e5                	mov    %esp,%ebp
f01014c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01014c7:	89 c2                	mov    %eax,%edx
f01014c9:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01014cc:	39 d0                	cmp    %edx,%eax
f01014ce:	73 09                	jae    f01014d9 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014d0:	38 08                	cmp    %cl,(%eax)
f01014d2:	74 05                	je     f01014d9 <memfind+0x1b>
	for (; s < ends; s++)
f01014d4:	83 c0 01             	add    $0x1,%eax
f01014d7:	eb f3                	jmp    f01014cc <memfind+0xe>
			break;
	return (void *) s;
}
f01014d9:	5d                   	pop    %ebp
f01014da:	c3                   	ret    

f01014db <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014db:	55                   	push   %ebp
f01014dc:	89 e5                	mov    %esp,%ebp
f01014de:	57                   	push   %edi
f01014df:	56                   	push   %esi
f01014e0:	53                   	push   %ebx
f01014e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014e4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014e7:	eb 03                	jmp    f01014ec <strtol+0x11>
		s++;
f01014e9:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01014ec:	0f b6 01             	movzbl (%ecx),%eax
f01014ef:	3c 20                	cmp    $0x20,%al
f01014f1:	74 f6                	je     f01014e9 <strtol+0xe>
f01014f3:	3c 09                	cmp    $0x9,%al
f01014f5:	74 f2                	je     f01014e9 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01014f7:	3c 2b                	cmp    $0x2b,%al
f01014f9:	74 2e                	je     f0101529 <strtol+0x4e>
	int neg = 0;
f01014fb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101500:	3c 2d                	cmp    $0x2d,%al
f0101502:	74 2f                	je     f0101533 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101504:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010150a:	75 05                	jne    f0101511 <strtol+0x36>
f010150c:	80 39 30             	cmpb   $0x30,(%ecx)
f010150f:	74 2c                	je     f010153d <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101511:	85 db                	test   %ebx,%ebx
f0101513:	75 0a                	jne    f010151f <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101515:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010151a:	80 39 30             	cmpb   $0x30,(%ecx)
f010151d:	74 28                	je     f0101547 <strtol+0x6c>
		base = 10;
f010151f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101524:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101527:	eb 50                	jmp    f0101579 <strtol+0x9e>
		s++;
f0101529:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010152c:	bf 00 00 00 00       	mov    $0x0,%edi
f0101531:	eb d1                	jmp    f0101504 <strtol+0x29>
		s++, neg = 1;
f0101533:	83 c1 01             	add    $0x1,%ecx
f0101536:	bf 01 00 00 00       	mov    $0x1,%edi
f010153b:	eb c7                	jmp    f0101504 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010153d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101541:	74 0e                	je     f0101551 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101543:	85 db                	test   %ebx,%ebx
f0101545:	75 d8                	jne    f010151f <strtol+0x44>
		s++, base = 8;
f0101547:	83 c1 01             	add    $0x1,%ecx
f010154a:	bb 08 00 00 00       	mov    $0x8,%ebx
f010154f:	eb ce                	jmp    f010151f <strtol+0x44>
		s += 2, base = 16;
f0101551:	83 c1 02             	add    $0x2,%ecx
f0101554:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101559:	eb c4                	jmp    f010151f <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010155b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010155e:	89 f3                	mov    %esi,%ebx
f0101560:	80 fb 19             	cmp    $0x19,%bl
f0101563:	77 29                	ja     f010158e <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101565:	0f be d2             	movsbl %dl,%edx
f0101568:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010156b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010156e:	7d 30                	jge    f01015a0 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101570:	83 c1 01             	add    $0x1,%ecx
f0101573:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101577:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101579:	0f b6 11             	movzbl (%ecx),%edx
f010157c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010157f:	89 f3                	mov    %esi,%ebx
f0101581:	80 fb 09             	cmp    $0x9,%bl
f0101584:	77 d5                	ja     f010155b <strtol+0x80>
			dig = *s - '0';
f0101586:	0f be d2             	movsbl %dl,%edx
f0101589:	83 ea 30             	sub    $0x30,%edx
f010158c:	eb dd                	jmp    f010156b <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f010158e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101591:	89 f3                	mov    %esi,%ebx
f0101593:	80 fb 19             	cmp    $0x19,%bl
f0101596:	77 08                	ja     f01015a0 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101598:	0f be d2             	movsbl %dl,%edx
f010159b:	83 ea 37             	sub    $0x37,%edx
f010159e:	eb cb                	jmp    f010156b <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01015a0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015a4:	74 05                	je     f01015ab <strtol+0xd0>
		*endptr = (char *) s;
f01015a6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015a9:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01015ab:	89 c2                	mov    %eax,%edx
f01015ad:	f7 da                	neg    %edx
f01015af:	85 ff                	test   %edi,%edi
f01015b1:	0f 45 c2             	cmovne %edx,%eax
}
f01015b4:	5b                   	pop    %ebx
f01015b5:	5e                   	pop    %esi
f01015b6:	5f                   	pop    %edi
f01015b7:	5d                   	pop    %ebp
f01015b8:	c3                   	ret    
f01015b9:	66 90                	xchg   %ax,%ax
f01015bb:	66 90                	xchg   %ax,%ax
f01015bd:	66 90                	xchg   %ax,%ax
f01015bf:	90                   	nop

f01015c0 <__udivdi3>:
f01015c0:	55                   	push   %ebp
f01015c1:	57                   	push   %edi
f01015c2:	56                   	push   %esi
f01015c3:	53                   	push   %ebx
f01015c4:	83 ec 1c             	sub    $0x1c,%esp
f01015c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01015cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01015cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01015d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01015d7:	85 d2                	test   %edx,%edx
f01015d9:	75 35                	jne    f0101610 <__udivdi3+0x50>
f01015db:	39 f3                	cmp    %esi,%ebx
f01015dd:	0f 87 bd 00 00 00    	ja     f01016a0 <__udivdi3+0xe0>
f01015e3:	85 db                	test   %ebx,%ebx
f01015e5:	89 d9                	mov    %ebx,%ecx
f01015e7:	75 0b                	jne    f01015f4 <__udivdi3+0x34>
f01015e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01015ee:	31 d2                	xor    %edx,%edx
f01015f0:	f7 f3                	div    %ebx
f01015f2:	89 c1                	mov    %eax,%ecx
f01015f4:	31 d2                	xor    %edx,%edx
f01015f6:	89 f0                	mov    %esi,%eax
f01015f8:	f7 f1                	div    %ecx
f01015fa:	89 c6                	mov    %eax,%esi
f01015fc:	89 e8                	mov    %ebp,%eax
f01015fe:	89 f7                	mov    %esi,%edi
f0101600:	f7 f1                	div    %ecx
f0101602:	89 fa                	mov    %edi,%edx
f0101604:	83 c4 1c             	add    $0x1c,%esp
f0101607:	5b                   	pop    %ebx
f0101608:	5e                   	pop    %esi
f0101609:	5f                   	pop    %edi
f010160a:	5d                   	pop    %ebp
f010160b:	c3                   	ret    
f010160c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101610:	39 f2                	cmp    %esi,%edx
f0101612:	77 7c                	ja     f0101690 <__udivdi3+0xd0>
f0101614:	0f bd fa             	bsr    %edx,%edi
f0101617:	83 f7 1f             	xor    $0x1f,%edi
f010161a:	0f 84 98 00 00 00    	je     f01016b8 <__udivdi3+0xf8>
f0101620:	89 f9                	mov    %edi,%ecx
f0101622:	b8 20 00 00 00       	mov    $0x20,%eax
f0101627:	29 f8                	sub    %edi,%eax
f0101629:	d3 e2                	shl    %cl,%edx
f010162b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010162f:	89 c1                	mov    %eax,%ecx
f0101631:	89 da                	mov    %ebx,%edx
f0101633:	d3 ea                	shr    %cl,%edx
f0101635:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101639:	09 d1                	or     %edx,%ecx
f010163b:	89 f2                	mov    %esi,%edx
f010163d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101641:	89 f9                	mov    %edi,%ecx
f0101643:	d3 e3                	shl    %cl,%ebx
f0101645:	89 c1                	mov    %eax,%ecx
f0101647:	d3 ea                	shr    %cl,%edx
f0101649:	89 f9                	mov    %edi,%ecx
f010164b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010164f:	d3 e6                	shl    %cl,%esi
f0101651:	89 eb                	mov    %ebp,%ebx
f0101653:	89 c1                	mov    %eax,%ecx
f0101655:	d3 eb                	shr    %cl,%ebx
f0101657:	09 de                	or     %ebx,%esi
f0101659:	89 f0                	mov    %esi,%eax
f010165b:	f7 74 24 08          	divl   0x8(%esp)
f010165f:	89 d6                	mov    %edx,%esi
f0101661:	89 c3                	mov    %eax,%ebx
f0101663:	f7 64 24 0c          	mull   0xc(%esp)
f0101667:	39 d6                	cmp    %edx,%esi
f0101669:	72 0c                	jb     f0101677 <__udivdi3+0xb7>
f010166b:	89 f9                	mov    %edi,%ecx
f010166d:	d3 e5                	shl    %cl,%ebp
f010166f:	39 c5                	cmp    %eax,%ebp
f0101671:	73 5d                	jae    f01016d0 <__udivdi3+0x110>
f0101673:	39 d6                	cmp    %edx,%esi
f0101675:	75 59                	jne    f01016d0 <__udivdi3+0x110>
f0101677:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010167a:	31 ff                	xor    %edi,%edi
f010167c:	89 fa                	mov    %edi,%edx
f010167e:	83 c4 1c             	add    $0x1c,%esp
f0101681:	5b                   	pop    %ebx
f0101682:	5e                   	pop    %esi
f0101683:	5f                   	pop    %edi
f0101684:	5d                   	pop    %ebp
f0101685:	c3                   	ret    
f0101686:	8d 76 00             	lea    0x0(%esi),%esi
f0101689:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101690:	31 ff                	xor    %edi,%edi
f0101692:	31 c0                	xor    %eax,%eax
f0101694:	89 fa                	mov    %edi,%edx
f0101696:	83 c4 1c             	add    $0x1c,%esp
f0101699:	5b                   	pop    %ebx
f010169a:	5e                   	pop    %esi
f010169b:	5f                   	pop    %edi
f010169c:	5d                   	pop    %ebp
f010169d:	c3                   	ret    
f010169e:	66 90                	xchg   %ax,%ax
f01016a0:	31 ff                	xor    %edi,%edi
f01016a2:	89 e8                	mov    %ebp,%eax
f01016a4:	89 f2                	mov    %esi,%edx
f01016a6:	f7 f3                	div    %ebx
f01016a8:	89 fa                	mov    %edi,%edx
f01016aa:	83 c4 1c             	add    $0x1c,%esp
f01016ad:	5b                   	pop    %ebx
f01016ae:	5e                   	pop    %esi
f01016af:	5f                   	pop    %edi
f01016b0:	5d                   	pop    %ebp
f01016b1:	c3                   	ret    
f01016b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016b8:	39 f2                	cmp    %esi,%edx
f01016ba:	72 06                	jb     f01016c2 <__udivdi3+0x102>
f01016bc:	31 c0                	xor    %eax,%eax
f01016be:	39 eb                	cmp    %ebp,%ebx
f01016c0:	77 d2                	ja     f0101694 <__udivdi3+0xd4>
f01016c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01016c7:	eb cb                	jmp    f0101694 <__udivdi3+0xd4>
f01016c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016d0:	89 d8                	mov    %ebx,%eax
f01016d2:	31 ff                	xor    %edi,%edi
f01016d4:	eb be                	jmp    f0101694 <__udivdi3+0xd4>
f01016d6:	66 90                	xchg   %ax,%ax
f01016d8:	66 90                	xchg   %ax,%ax
f01016da:	66 90                	xchg   %ax,%ax
f01016dc:	66 90                	xchg   %ax,%ax
f01016de:	66 90                	xchg   %ax,%ax

f01016e0 <__umoddi3>:
f01016e0:	55                   	push   %ebp
f01016e1:	57                   	push   %edi
f01016e2:	56                   	push   %esi
f01016e3:	53                   	push   %ebx
f01016e4:	83 ec 1c             	sub    $0x1c,%esp
f01016e7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01016eb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01016ef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01016f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016f7:	85 ed                	test   %ebp,%ebp
f01016f9:	89 f0                	mov    %esi,%eax
f01016fb:	89 da                	mov    %ebx,%edx
f01016fd:	75 19                	jne    f0101718 <__umoddi3+0x38>
f01016ff:	39 df                	cmp    %ebx,%edi
f0101701:	0f 86 b1 00 00 00    	jbe    f01017b8 <__umoddi3+0xd8>
f0101707:	f7 f7                	div    %edi
f0101709:	89 d0                	mov    %edx,%eax
f010170b:	31 d2                	xor    %edx,%edx
f010170d:	83 c4 1c             	add    $0x1c,%esp
f0101710:	5b                   	pop    %ebx
f0101711:	5e                   	pop    %esi
f0101712:	5f                   	pop    %edi
f0101713:	5d                   	pop    %ebp
f0101714:	c3                   	ret    
f0101715:	8d 76 00             	lea    0x0(%esi),%esi
f0101718:	39 dd                	cmp    %ebx,%ebp
f010171a:	77 f1                	ja     f010170d <__umoddi3+0x2d>
f010171c:	0f bd cd             	bsr    %ebp,%ecx
f010171f:	83 f1 1f             	xor    $0x1f,%ecx
f0101722:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101726:	0f 84 b4 00 00 00    	je     f01017e0 <__umoddi3+0x100>
f010172c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101731:	89 c2                	mov    %eax,%edx
f0101733:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101737:	29 c2                	sub    %eax,%edx
f0101739:	89 c1                	mov    %eax,%ecx
f010173b:	89 f8                	mov    %edi,%eax
f010173d:	d3 e5                	shl    %cl,%ebp
f010173f:	89 d1                	mov    %edx,%ecx
f0101741:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101745:	d3 e8                	shr    %cl,%eax
f0101747:	09 c5                	or     %eax,%ebp
f0101749:	8b 44 24 04          	mov    0x4(%esp),%eax
f010174d:	89 c1                	mov    %eax,%ecx
f010174f:	d3 e7                	shl    %cl,%edi
f0101751:	89 d1                	mov    %edx,%ecx
f0101753:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101757:	89 df                	mov    %ebx,%edi
f0101759:	d3 ef                	shr    %cl,%edi
f010175b:	89 c1                	mov    %eax,%ecx
f010175d:	89 f0                	mov    %esi,%eax
f010175f:	d3 e3                	shl    %cl,%ebx
f0101761:	89 d1                	mov    %edx,%ecx
f0101763:	89 fa                	mov    %edi,%edx
f0101765:	d3 e8                	shr    %cl,%eax
f0101767:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010176c:	09 d8                	or     %ebx,%eax
f010176e:	f7 f5                	div    %ebp
f0101770:	d3 e6                	shl    %cl,%esi
f0101772:	89 d1                	mov    %edx,%ecx
f0101774:	f7 64 24 08          	mull   0x8(%esp)
f0101778:	39 d1                	cmp    %edx,%ecx
f010177a:	89 c3                	mov    %eax,%ebx
f010177c:	89 d7                	mov    %edx,%edi
f010177e:	72 06                	jb     f0101786 <__umoddi3+0xa6>
f0101780:	75 0e                	jne    f0101790 <__umoddi3+0xb0>
f0101782:	39 c6                	cmp    %eax,%esi
f0101784:	73 0a                	jae    f0101790 <__umoddi3+0xb0>
f0101786:	2b 44 24 08          	sub    0x8(%esp),%eax
f010178a:	19 ea                	sbb    %ebp,%edx
f010178c:	89 d7                	mov    %edx,%edi
f010178e:	89 c3                	mov    %eax,%ebx
f0101790:	89 ca                	mov    %ecx,%edx
f0101792:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101797:	29 de                	sub    %ebx,%esi
f0101799:	19 fa                	sbb    %edi,%edx
f010179b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010179f:	89 d0                	mov    %edx,%eax
f01017a1:	d3 e0                	shl    %cl,%eax
f01017a3:	89 d9                	mov    %ebx,%ecx
f01017a5:	d3 ee                	shr    %cl,%esi
f01017a7:	d3 ea                	shr    %cl,%edx
f01017a9:	09 f0                	or     %esi,%eax
f01017ab:	83 c4 1c             	add    $0x1c,%esp
f01017ae:	5b                   	pop    %ebx
f01017af:	5e                   	pop    %esi
f01017b0:	5f                   	pop    %edi
f01017b1:	5d                   	pop    %ebp
f01017b2:	c3                   	ret    
f01017b3:	90                   	nop
f01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	85 ff                	test   %edi,%edi
f01017ba:	89 f9                	mov    %edi,%ecx
f01017bc:	75 0b                	jne    f01017c9 <__umoddi3+0xe9>
f01017be:	b8 01 00 00 00       	mov    $0x1,%eax
f01017c3:	31 d2                	xor    %edx,%edx
f01017c5:	f7 f7                	div    %edi
f01017c7:	89 c1                	mov    %eax,%ecx
f01017c9:	89 d8                	mov    %ebx,%eax
f01017cb:	31 d2                	xor    %edx,%edx
f01017cd:	f7 f1                	div    %ecx
f01017cf:	89 f0                	mov    %esi,%eax
f01017d1:	f7 f1                	div    %ecx
f01017d3:	e9 31 ff ff ff       	jmp    f0101709 <__umoddi3+0x29>
f01017d8:	90                   	nop
f01017d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017e0:	39 dd                	cmp    %ebx,%ebp
f01017e2:	72 08                	jb     f01017ec <__umoddi3+0x10c>
f01017e4:	39 f7                	cmp    %esi,%edi
f01017e6:	0f 87 21 ff ff ff    	ja     f010170d <__umoddi3+0x2d>
f01017ec:	89 da                	mov    %ebx,%edx
f01017ee:	89 f0                	mov    %esi,%eax
f01017f0:	29 f8                	sub    %edi,%eax
f01017f2:	19 ea                	sbb    %ebp,%edx
f01017f4:	e9 14 ff ff ff       	jmp    f010170d <__umoddi3+0x2d>
