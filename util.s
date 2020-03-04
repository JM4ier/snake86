;prints rdi to stdout in hex format
print_number:
	push rax
	push rcx
	push rdx

	mov r10, 2
	mov cl, 64	;position of hex digit
	xor r11, r11	;temp storage to move from buffer to buffer
	xor rdx, rdx	;has the number started?
.loop:
	sub cl, 4

	mov rax, rdi
	shr rax, cl
	and rax, 0xF

	or rdx, rax
	cmp rdx, 0
	je .zero

	;nonzero or number has started --> write digit
	mov byte r11b, [hex_table + rax]
	mov byte [gp_buffer + r10], r11b
	inc r10
.zero:

	cmp cl, 0
	jg .loop


	cmp rdx, 0
	jne .nonzero
	;if entire number is zero, write a '0'
	mov byte [gp_buffer+r10], '0'
	inc r10
	.nonzero:

	;write hex prefix '0x' and end with newline
	mov byte [gp_buffer+0], '0'
	mov byte [gp_buffer+1], 'x'
	mov byte [gp_buffer+r10], 0xA	;newline
	inc r10

	;print to stdout
	mov rdi, gp_buffer
	mov rsi, r10
	call stdout

	pop rdx
	pop rcx
	pop rax
	ret

hex_table:	db "0123456789ABCDEF"


system_time:
	xor rax, rax
	push rax
	mov rax, 201	;SYS_TIME
	mov rdi, rsp	;stack
	syscall
	pop rax
	ret

sleep_ns:
	mov rax, 35	;SYS_NANOSLEEP
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

	mov rax, 7	;SYS_POLL
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
	mov rdi, 0	;FD 0 is stdin
	pop rsi		;buffer address in rsi
	pop rdx		;buffer length in rdx
	mov rax, 0	;SYS_READ
	syscall
	ret

;writes a buffer to stdout
;buffer address in rdi
;buffer length in rsi
stdout:
	push rsi
	push rdi
	mov rdi, 1	;FD 1 is stdout
	pop rsi		;buffer address in rsi
	pop rdx		;buffer length in rdx
	mov rax, 1	;SYS_WRITE
	syscall
	ret

;terminates the program by notifying the system
terminate:
	;restore to original keyboard config
	call rawkb_restore

	;print trailing newline
	mov byte [gp_buffer], 0xA
	mov rdi, gp_buffer
	mov rsi, 1
	call stdout

	;tell kernel to stop this thread
	mov rax, 60	;SYS_EXIT
	mov rdi, 0	;success
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

;prints 'ERR' to stdout and terminates
err:
	mov rdi, ERR_MSG
	mov rsi, ERR_LEN
	call stdout
	jmp terminate

;prints a buffer given by rdi:rsi and terminates
errmsg:
	call stdout
	jmp terminate

;writes argument from address rdi with length rsi to buffer
write_to_buf:
	;check if src buffer has non zero length
	cmp rsi, 0
	jg .ok1
	call err
	ret
.ok1:
	;check if dest buffer has space
	mov r10, rsi
	add r10, [buffer_ptr]
	cmp r10, buffer_size
	jl .ok2
	call err
	ret

.ok2:
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

