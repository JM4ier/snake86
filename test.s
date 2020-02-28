global _start


;terminates the program by notifying the system
terminate:
	mov rax, 60
	mov rdi, 0
	syscall

stdout:
	mov eax, 4
	mov ebx, 1
	mov ecx, MSG
	mov edx, MSG_LEN
	int 0x80
	ret

_start:
	call stdout	
	call terminate

section .rodata:
	MSG: db "Hello, Snake!", 0xA
	MSG_LEN: equ $ - MSG
