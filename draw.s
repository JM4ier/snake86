clear_screen:
	mov rdi, ANSI_CLEAR
	mov rsi, ANSI_CLEAR_LEN
	call stdout
	ret


draw_char:	;expects color in rdi
	;changes color
	mov rsi, COL_LEN
	call write_to_buf

	;writes space
	mov byte [gp_buffer], " "
	mov rdi, gp_buffer
	mov rsi, 1
	call write_to_buf
	call write_to_buf

	;change color to default
	mov rdi, COL_DEFAULT
	mov rsi, COL_LEN
	call write_to_buf

	ret

draw_border_char:
	mov rdi, COL_BORDER
	jmp draw_char

;converts coords to pointer
c2p:
	;bounds checks
	cmp rdi, SIZE
	jge .oob
	cmp rdi, 0
	jl .oob
	cmp rsi, SIZE
	jge .oob
	cmp rsi, 0
	jl .oob

	mov rax, rdi
	push rbx
	mov rbx, SIZE
	mul rbx
	pop rbx
	add rax, rsi
	add rax, game_buf
	ret
.oob:
	mov rdi, .oob_msg
	mov rsi, .oob_msg_len
	jmp errmsg
.oob_msg: db 'c2p: oob', 0xA
.oob_msg_len: equ $ - .oob_msg

reset_cursor:
	xor rbx, rbx
.loop:
	push rbx

	mov rdi, ANSI_LEFT
	mov rsi, ANSI_DIR_LEN
	call write_to_buf

	mov rdi, ANSI_UP
	mov rsi, ANSI_DIR_LEN
	call write_to_buf

	pop rbx

	inc rbx
	cmp rbx, SIZE + 3
	jl .loop
	ret

;draws horizontal border line
hor_line:
	xor rbx, rbx
.loop:
	call draw_border_char
	inc rbx
	cmp rbx, SIZE + 2
	jl .loop

	;add newline
	mov byte [gp_buffer], 0xA
	mov rdi, gp_buffer
	mov rsi, 1
	call write_to_buf

	ret

build_buffer:
	mov qword [buffer_ptr], 0 ;reset buffer
	call hor_line	;top border line

	xor rbx, rbx	;x
	xor rcx, rcx	;y
	.outer:
		push rcx
		call draw_border_char	;left border
		pop rcx

		xor rbx, rbx
		.inner:
			push rbx
			push rcx

			;convert coords to buffer pointer
			mov rdi, rbx
			mov rsi, rcx
			call c2p

			;fetch color and draw corresponding chars
			mov byte r15b, [rax]
			and r15, 3
			xor rax, rax
			mov byte al, COL_LEN
			mul r15
			lea rdi, [COL + rax]
			call draw_char

			pop rcx
			pop rbx

			inc rbx
			cmp byte bl, SIZE
			jl .inner

		push rcx
		call draw_border_char	;right border

		;draw newline
		mov byte [gp_buffer], 0xA
		mov rdi, gp_buffer
		mov rsi, 1
		call write_to_buf

		pop rcx

		;increase and loop bound check
		inc rcx
		cmp byte cl, SIZE
		jl .outer
	call hor_line
	ret

print_buffer:
	;write buffer to stdout
	mov rdi, buffer
	mov rsi, [buffer_ptr]
	call stdout
	ret

draw_snake:
	xor rax, rax
	mov ax, [head]	;current position of snake body part that is drawn

	xor rcx, rcx
.snake_loop:
	;move snake body pos
	push rcx
	mov rdi, rax
	mov rsi, [snake+rcx]
	call move_pos
	pop rcx

	;draw pixel in game buffer
	push rax
	push rsi
	dec al
	dec ah
	xor rdi, rdi
	xor rsi, rsi
	mov dil, al
	mov al, ah
	mov sil, al
	call c2p
	mov byte [rax], 0
	pop rsi
	pop rax

	;increment and loop bound check
	inc rcx
	cmp byte cl, [len]
	jl .snake_loop

	ret

draw_food:
	;check if food exists
	cmp byte [food], 0
	je .no_food

	xor rdi, rdi
	xor rsi, rsi
	mov dil, [food+1]
	mov sil, [food+2]
	dec dil
	dec sil
	call c2p
	mov byte [rax], 1

.no_food:
	ret

clear_field:
	xor rsi, rsi
.outer:
	xor rdi, rdi
.inner:
	push rdi
	push rsi
	call c2p
	pop rsi
	pop rdi

	;reset to black
	mov byte [rax], 3

	inc rdi
	cmp rdi, SIZE
	jl .inner

	inc rsi
	cmp rsi, SIZE
	jl .outer

	ret

