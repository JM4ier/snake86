global _start

%include "rawkb.s"

;important keycodes to control the game
K_UP 	equ 0x48
K_DOWN	equ 0x50
K_LEFT	equ 0x4b
K_RIGHT	equ 0x4d
K_ESC	equ 0x01

;system call numbers
;SYS_READ equ 0
;SYS_WRITE equ 1
SYS_POLL equ 7
SYS_EXIT equ 60

STDIN_FD equ 0
STDOUT_FD equ 1

stdin_ready:
	;poll info struct on stack
	dec rsp
	mov byte [rsp], 0	;zero is initial return info, kernel fills it with data

	dec rsp
	mov byte [rsp], 1	;POLLIN const, signals data to read

	dec rsp		;zero is input fd
	mov byte [rsp], 0
	dec rsp
	mov byte [rsp], 0
	

	mov rax, SYS_POLL
	mov rdi, rsp	;ptr to poll info struct on stack
	mov rsi, 1	;n=1 poll info
	mov rdx, 10	;polling timeout in ms

	syscall

	inc rsp
	inc rsp
	inc rsp
	xor rax, rax
	mov al, [rsp]	;move result into al
	inc rsp		;restore stack
	
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
achar:
	push rax
	mov rdi, rsp
	mov rsi, 1
	call stdin
	pop rax
	ret

_start:
	call rawkb_start
	mov r10, 0

.poll:
	call stdin_ready
	cmp al, 1
	jle .poll

	;print char
	push rax
	mov rdi, rsp
	mov rsi, 1
	call stdin
	mov rdi, rsp
	mov rsi, 1
	call stdout
	pop rax

	;exit after 10 chars
	inc r10
	cmp r10, 10
	jl .poll

	call rawkb_restore
	mov rdi, MSG
	mov rsi, MSG_LEN
	call stdout
	call terminate

section .rodata:
	MSG: db "Hello, Snake!", 0xA
	MSG_LEN: equ $ - MSG
