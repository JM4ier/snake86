global _start

;reads a buffer from stdin
;buffer address in rdi
;buffer length in rsi
stdin:
	push rsi
	push rdi
	xor rdi, rdi
	pop rsi
	pop rdx
	xor rax, rax
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
	inc rsp
	call stdin
	pop rax

_start:
	mov rdi, MSG
	mov rsi, MSG_LEN
	call stdout
	call terminate

section .rodata:
	MSG: db "Hello, Snake!", 0xA
	MSG_LEN: equ $ - MSG
