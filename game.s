move_cursor:
	push rbx

	mov rax, rdi
	mov rbx, rsi
.move_hor:
	cmp al, 0
	je .move_hor_over
	test rbx, 0x1
	jnz .posr
	mov rdi, ANSI_LEFT
	jmp .posh
.posr:
	mov rdi, ANSI_RIGHT
.posh:
	mov rsi, ANSI_DIR_LEN
	push rax
	call write_to_buf
	pop rax
	dec al
	jmp .move_hor
.move_hor_over:
.move_ver:
	cmp ah, 0
	je .move_ver_over
	test rbx, 0x2
	jz .posd
	mov rdi, ANSI_UP
	jmp .posv
.posd:
	mov rdi, ANSI_DOWN
.posv:
	mov rsi, ANSI_DIR_LEN
	push rax
	call write_to_buf
	pop rax
	dec ah
	jmp .move_ver
.move_ver_over:

	pop rbx
	ret

;appends char given in dil to buffer
update_cursor_color:
	push rdi
	push rsi

	mov byte [gp_buffer], '#'	;space character in gp_buffer
	mov rdi, gp_buffer
	mov rsi, 1
	call write_to_buf

	;draw ANSI_LEFT to be at the same position
	mov rdi, ANSI_LEFT
	mov rsi, ANSI_DIR_LEN
	call write_to_buf

	pop rsi
	pop rdi
	ret

;fills entire screen with spaces
empty_screen:
	push rdi
	push rsi
	push rcx

	mov rsi, 0
.buffer_construction:
	mov byte [gp_buffer+rsi], '*'	;add space
	inc rsi
	cmp rsi, WIDTH
	jl .buffer_construction

	mov byte [gp_buffer+rsi], 0xA	;add newline
	inc rsi

	mov rcx, 0
.printing:
	push rsi
	push rcx

	mov rdi, gp_buffer
	call write_to_buf

	pop rcx
	pop rsi

	inc rcx
	cmp rcx, HEIGHT
	jl .printing

	pop rcx
	pop rsi
	pop rdi

	ret


draw_scene:
	mov rdi, 0xF00D0
	call debug_number

	mov qword [buffer_ptr], 0	;reset buffer

	;clear buffer
	mov rdi, ANSI_CLEAR
	mov rsi, ANSI_CLEAR_LEN
	call write_to_buf

	;fill screen with emptiness (spaces)
	call empty_screen

	;position cursor on top of snakes head
	xor rdi, rdi
	mov di, [head]
	mov rsi, 0x3
	call move_cursor

	;-------snake------
	xor rax, rax
	mov ax, [head]	;current position of snake body part that is drawn
	xor rcx, rcx

	;change color to snake color
	mov rdi, ANSI_WHITE
	mov rsi, ANSI_COL_LEN
	call write_to_buf

	xor rcx, rcx
.snake_loop:
	push rcx
	call update_cursor_color
	pop rcx
	mov rdi, rax
	mov rsi, [snake+rcx]
	push rcx
	call move_pos
	pop rcx

	xor rdi, rdi
	mov byte dil, [snake+rcx]
	cmp rdi, 3
	jg err
	lea rdi, [ANSI_DIR + 4*rdi] ;4 is length of ANSI_DIR_LEN, can't use it directly in this context

	mov rsi, ANSI_DIR_LEN
	push rcx
	call write_to_buf
	call update_cursor_color
	pop rcx

	inc rcx
	cmp byte cl, [len]
	jl .snake_loop


	;-----snake food--------

	;check if food exists
	cmp byte [food], 0
	je .no_food

	; reset cursor
	mov rdi, rax
	mov rsi, 0x0
	call move_cursor


	;move cursor to food
	mov di, [food+1]
	mov rsi, 0x3
	call move_cursor

	;draw food
	mov rdi, ANSI_GREEN
	mov rsi, ANSI_COL_LEN
	call write_to_buf
	call update_cursor_color

.no_food:

	;reset color to black
	mov rdi, ANSI_BLACK
	mov rsi, ANSI_COL_LEN
	call write_to_buf

	;append newline and null character to buffer
	mov r10, 0x0
	push r10
	mov rdi, rsp
	mov rsi, 1
	call write_to_buf
	pop r10

	;write buffer to stdout
	mov rdi, buffer
	mov rsi, [buffer_ptr]
	test byte [draw_scene_enabled], 1
	jz .ret
	call stdout
.ret:
	ret

handle_input:
	;result in [dir]
	call stdin_ready
	test al, 0x1
	jz .exit
	;input ready here
	call read_char

	;best coding practice right here
	cmp rax, K_UP
	je .up
	cmp rax, K_DOWN
	je .down
	cmp rax, K_LEFT
	je .left
	cmp rax, K_RIGHT
	je .right
	cmp rax, K_ESC
	je .esc
	jmp .none
.up:
	mov byte [dir], 3
	jmp .none
.down:
	mov byte [dir], 1
	jmp .none
.left:
	mov byte [dir], 0
	jmp .none
.right:
	mov byte [dir], 2
	jmp .none
.esc:
	call terminate
	jmp .none
.none:
	;repeat until no char left
	jmp handle_input
.exit:
	ret

;move position given in di by direction given in sil
move_pos:
	mov rax, rdi
	test sil, 0x1	;vertical?
	jz .hor

	;vertical
	test sil, 0x2	;up or down?
	jz .down
	;up
	dec ah
	ret
.down:	;down
	inc ah
	ret

.hor:	;horizontal
	test sil, 0x2	;left or right?
	jz .left
	;right
	inc al
	ret
.left:	;left
	dec al
	ret

;moves the head to the given dir and returns the new position in ax
move_head:
	xor rdi, rdi
	mov word di, [head]
	xor rsi, rsi
	mov byte sil, [dir]
	call move_pos
	ret

move_snake:
	push rdi
	mov rdi, 0xF00A1
	call debug_number
	pop rdi

	call move_head	;new head position now in ax
	push rbx

	xor rbx, rbx
	mov bx, [head]	;first new body position

	;check if head is out of bounds
	cmp al, 0
	je .outofbounds
	cmp al, WIDTH
	je .outofbounds
	cmp ah, 0
	je .outofbounds
	cmp ah, HEIGHT
	je .outofbounds


	;loop over body and check for collisions
	mov rcx, 0
.body_loop:
	;check for head-body collision
	cmp rax, rbx
	je .self_collision

	;move to the next body part
	push rax
	mov rdi, rbx
	xor rsi, rsi
	mov byte sil, [snake+rcx]
	call move_pos
	mov rbx, rax
	pop rax

	push rdi
	mov rdi, 0xF00A4
	call debug_number
	pop rdi

	;counter increment and repeating
	inc rcx
	cmp byte cl, [len]
	jl .body_loop


	;store new head position
	mov word [head], ax

	;store direction in bl
	;revert moving direction to point to next body
	mov byte bl, [dir]
	xor byte bl, 0x2

	push rdi
	mov rdi, 0xF00A5
	call debug_number
	pop rdi

	;shift entire snake body
	mov rcx, 0
.update_loop:
	;swap with next
	xor byte bl, [snake+rcx]
	xor byte [snake+rcx], bl
	xor byte bl, [snake+rcx]

	;counter and repeat
	inc rcx
	cmp byte cl, [len]
	jl .update_loop

	pop rbx
	ret
.outofbounds:
.self_collision:
	pop rbx
	call game_over
	ret

check_food_eaten:
	cmp byte [food], 0
	jg .food
	ret
.food:
	mov cx, [head]
	cmp cx, [food+1]
	je .eaten
	ret
.eaten:
	;increase length and remove food
	mov cl, [len]
	inc cl
	mov [len], cl
	mov byte [food], 0
	ret

game_tick:
	;sleep 0.999s
	mov rdi, 200 * 1000 * 1000
	call sleep_ns
	ret

init_game:
	;move head of snake in middle
	mov byte [head+0], WIDTH / 2
	mov byte [head+1], HEIGHT / 2

	;initial length of 3
	mov byte [len], 5

	;reverse default direction in order not to crash into itself at start
	mov byte r10b, [dir]
	xor r10b, 2
	mov byte [dir], r10b

	ret

game_over:
	call terminate
	ret
