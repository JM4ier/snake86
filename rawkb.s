;****************************************************************************
;****************************************************************************
;*
;* USING THE RAW KEYBOARD MODE UNDER LINUX
;*
;* written by Karsten Scheibler, 2003-DEC-08
;*
;****************************************************************************
;****************************************************************************





global rawkb_start



;****************************************************************************
;* some assign's
;****************************************************************************
%assign SYS_READ			3
%assign SYS_WRITE			4
%assign SYS_OPEN			5
%assign SYS_CLOSE			6
%assign SYS_IOCTL			54

%assign TCGETS				0x00005401
%assign TCSETSW				0x00005403
%assign KDGKBMODE			0x00004b44
%assign KDSKBMODE			0x00004b45
%assign K_RAW				0

%assign ISTRIP				000400q
%assign INLCR				000100q
%assign IGNCR				000200q
%assign ICRNL				000400q
%assign IXON				002000q
%assign IXOFF				010000q

%assign ISIG				1
%assign ICANON				2
%assign ECHO				8

%assign STDIN				0
%assign STDOUT				1

%assign O_RDWR				2

%assign STATE_TERMIOS_SAVED		0x01
%assign STATE_KBMODE_SAVED		0x02

					struc	ttermios
					alignb	4
termios_input_flags:			resd	1
termios_output_flags:			resd	1
termios_control_flags:			resd	1
termios_local_flags:			resd	1
termios_line_discipline:		resb	1
termios_control_characters:		resb	64
					endstruc



;****************************************************************************
;* data
;****************************************************************************
section .data
					align	4
tty_state:				dd	0

section .bss
	align	4
tty_termios_saved:			resb	ttermios_size
tty_kbmode_saved:			resd	1
tty_termios:				resb	ttermios_size
hex_number:				resd	1
character:				resb	1



;****************************************************************************
;* rawkb_start
;****************************************************************************
section .text
rawkb_start:

	;save terminal state

	mov	dword eax, SYS_IOCTL
	mov	dword ebx, STDIN
	mov	dword ecx, KDGKBMODE
	mov	dword edx, tty_kbmode_saved
	int	byte  0x80
	test	dword eax, eax
	js	near  rawkb_error
	or	dword [tty_state], STATE_KBMODE_SAVED

	mov	dword eax, SYS_IOCTL
	mov	dword ebx, STDIN
	mov	dword ecx, TCGETS
	mov	dword edx, tty_termios_saved
	int	byte  0x80
	test	dword eax, eax
	js	near  rawkb_error
	or	dword [tty_state], STATE_TERMIOS_SAVED

	;set terminal values

	cld
	mov	dword ecx, ttermios_size
	mov	dword esi, tty_termios_saved
	mov	dword edi, tty_termios
	rep movsb

	and	dword [tty_termios + termios_input_flags], (~(ISTRIP | INLCR | ICRNL | IGNCR | IXON | IXOFF))
	and	dword [tty_termios + termios_local_flags], (~(ECHO | ICANON | ISIG))

	mov	dword eax, SYS_IOCTL
	mov	dword ebx, STDIN
	mov	dword ecx, TCSETSW
	mov	dword edx, tty_termios
	int	byte  0x80
	test	dword eax, eax
	js	near  rawkb_error

	mov	dword eax, SYS_IOCTL
	mov	dword ebx, STDIN
	mov	dword ecx, KDSKBMODE
	mov	dword edx, K_RAW
	int	byte  0x80
	test	dword eax, eax
	js	near  rawkb_error

	;display the hex codes of all pressed keys, ESC exits

.display:
	mov	dword eax, SYS_READ
	mov	dword ebx, STDIN
	mov	dword ecx, character
	mov	dword edx, 1
	int	byte  0x80
	xor	dword ebx, ebx
	xor	dword ecx, ecx
	mov	byte  bl, [character]
	mov	byte  cl, bl
	cmp	byte  bl, 0x01
	je	near  rawkb_end
	shr	dword ecx, 4
	and	byte  bl, 0x0f
	mov	dword eax, 0x0a680000
	mov	byte  ah, [.hex_table + ebx]
	mov	byte  al, [.hex_table + ecx]
	mov	dword [hex_number], eax
	mov	dword eax, SYS_WRITE
	mov	dword ebx, STDOUT
	mov	dword ecx, hex_number
	mov	dword edx, 4
	int	byte  0x80
	jmp	short .display

.hex_table:				db	"0123456789abcdef"



;****************************************************************************
;* rawkb_restore ************************************************************
;****************************************************************************
section .text
rawkb_restore:
	test	dword [tty_state], STATE_KBMODE_SAVED
	jz	short .no_kbmode
	mov	dword eax, SYS_IOCTL
	mov	dword ebx, STDIN
	mov	dword ecx, KDSKBMODE
	mov	dword edx, [tty_kbmode_saved]
	int	byte  0x80
.no_kbmode:
	test	dword [tty_state], STATE_TERMIOS_SAVED
	jz	short .no_termios
	mov	dword eax, SYS_IOCTL
	mov	dword ebx, STDIN
	mov	dword ecx, TCSETSW
	mov	dword edx, tty_termios_saved
	int	byte  0x80
.no_termios:
	ret



;****************************************************************************
;* rawkb_error **************************************************************
;****************************************************************************
section .text
rawkb_error:
	call	near  rawkb_restore
	xor	dword eax, eax
	inc	dword eax
	mov	dword ebx, eax
	int	byte  0x80



;****************************************************************************
;* rawkb_end
;****************************************************************************
section .text
rawkb_end:
	call	near  rawkb_restore
	xor	dword eax, eax
	mov	dword ebx, eax
	inc	dword eax
	int	byte  0x80
;*********************************************** linuxassembly@unusedino.de *

