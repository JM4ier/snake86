;writes argument from address rdi with length rsi to buffer
write_to_buf:
	cmp rsi, 0
	jg .nonzero
	call err
	ret
.nonzero:
	xor rax, rax
	mov rcx, [buffer_ptr]
.loop:
	mov byte dl, [rdi + rax]
	mov byte [buffer + rcx], dl

	inc rcx
	inc rax

	cmp rax, rsi
	jl .loop

	mov [buffer_ptr], rcx
	ret

system_time:
	xor rax, rax
	push rax
	mov rax, 201	;sys_time
	mov rdi, rsp	;stack
	syscall
	pop rax
	ret

sleep_ns:
	mov rax, 35	;sys_nanosleep
	mov r10, rdi	;rdi nanos
	push r10
	xor r10, r10	;0 seconds
	push r10
	mov rdi, rsp
	xor rsi, rsi
	syscall
	pop r10
	pop r10
	ret

;returns 1 in rax if there is pending input
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
	call rawkb_restore
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

