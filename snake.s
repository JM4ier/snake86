global _start

%include "rawkb.s"

;important keycodes to control the game
K_UP 	equ 0x48
K_DOWN	equ 0x50
K_LEFT	equ 0x4b
K_RIGHT	equ 0x4d
K_ESC	equ 0x81

;system call numbers
;SYS_READ equ 0
;SYS_WRITE equ 1
SYS_POLL equ 7
SYS_EXIT equ 60

STDIN_FD equ 0
STDOUT_FD equ 1

DIR_NONE equ 0
DIR_LEFT equ 1
DIR_RIGHT equ 2
DIR_UP equ 3
DIR_DOWN equ 4

DIR_CHARS: db " LRUD"

system_time:
	xor rax, rax
	push rax
	mov rax, 201	;sys_time
	mov rdi, rsp	;stack
	syscall
	pop rax
	ret


stdin_ready:
	;poll info struct on stack
	xor rax, rax
	push rax	;push 64 bits on stack

	;bytes 0 to 3 for fd, keep it zero for stdin

	;bytes 4,5 for poll request
	;POLLIN, signals data to read
	mov byte [rsp+4], 1

	;bytes 6,7 as return value
	;keeping it zero and letting the kernel fill in the values

	mov rax, SYS_POLL
	mov rdi, rsp	;addr of request 'struct'
	mov rsi, 1	;number of poll requests
	mov rdx, 10	;poll timeout in ms
	syscall

	;copying return value to al register
	xor rax, rax
	mov ax, [rsp+6]

	;pop into caller saved register to reset stack to previous state
	pop r10

	ret


;reads a buffer from stdin
;buffer address in rdi
;buffer length in rsi
stdin:
	push rsi
	push rdi
	mov rdi, 0
	pop rsi
	pop rdx
	mov rax, 0
	syscall
	ret

;writes a buffer to stdout
;buffer address in rdi
;buffer length in rsi
stdout:
	push rsi
	push rdi
	mov rdi, 1
	pop rsi
	pop rdx
	mov rax, 1
	syscall
	ret

;terminates the program by notifying the system
terminate:
	mov rax, 60
	mov rdi, 0
	syscall

;reads a single char from stdin
;returns char in rax
read_char:
	push rax
	mov rdi, rsp
	mov rsi, 1
	call stdin
	pop rax
	ret

err:
	mov rdi, ERR_MSG
	mov rsi, ERR_LEN
	call stdout
	jmp terminate

_start:
	call rawkb_start;change keyboard to raw mode

.poll:
	;TODO game code

	;check if there is a new keycode
	call stdin_ready
	test al, 1
	jz .poll

	;read char
	call read_char

	;exit if escape
	cmp al, K_ESC
	je .exit

	;TODO keyboard handling

	jmp .poll
.exit:
	;clean up after ourselves
	call rawkb_restore
	call terminate

section .rodata:
	MSG: db "Hello, Snake!", 0xA
	MSG_LEN: equ $ - MSG
	ERR_MSG: db "ERR", 0xA
	ERR_LEN: equ $ - ERR_MSG
