global _start


;terminates the program by notifying the system
terminate:
	mov rax, 60
	mov rdi, 0
	syscall

stdout:
	mov rax, 1
	mov rdi, 1
	mov rsi, MSG
	mov rdx, MSG_LEN
	syscall
	ret

_start:
	call stdout	
	call terminate

section .rodata:
	MSG: db "Hello, Snake!", 0xA
	MSG_LEN: equ $ - MSG
