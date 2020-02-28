global _start

%include "rawkb.s"

;important keycodes to control the game
K_UP 	equ 0x48
K_DOWN	equ 0x50
K_LEFT	equ 0x4b
K_RIGHT	equ 0x4d
K_ESC	equ 0x01


stdin_ready:
	mov rsp, rdi	;ptr to poll info struct
	mov ax, 0
	push word ax	;requested fd, 0 is stdin
	push byte al	;requested polling info, unclear
	push byte al	;returned polling info
	
	
	


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
	call achar
	call rawkb_restore
	mov rdi, MSG
	mov rsi, MSG_LEN
	call stdout
	call terminate

section .rodata:
	MSG: db "Hello, Snake!", 0xA
	MSG_LEN: equ $ - MSG
