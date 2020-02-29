move_cursor:
	push rbx
	mov rax, rdi
	mov rbx, rsi
.move_hor:
	cmp al, 0
	je .move_hor_over
	push rax
	test rbx, 0x1
	jz .posr
	mov rdi, ANSI_LEFT
	jmp .posh
.posr:
	mov rdi, ANSI_RIGHT
.posh:
	mov rsi, ANSI_DIR_LEN
	call write_to_buf
	pop rax
	dec al
	jmp .move_hor
.move_hor_over:
.move_ver:
	cmp ah, 0
	je .move_ver_over
	push rax
	test rbx, 0x2
	jz .posd
	mov rdi, ANSI_UP
	jmp .posv
.posd:
	mov rdi, ANSI_DOWN
.posv:
	mov rsi, ANSI_DIR_LEN
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

	;draw space char
	xor r10, r10
	mov r10b, 0x20
	push r10
	mov rdi, rsp
	mov rsi, 1
	call write_to_buf
	pop r10

	;draw ANSI_LEFT to be at the same position
	mov rdi, ANSI_LEFT
	mov rsi, ANSI_DIR_LEN
	call write_to_buf

	pop rsi
	pop rdi
	ret

draw_scene:
	mov byte [buffer_ptr], 0	;reset buffer

	;clear buffer
	mov rdi, ANSI_CLEAR
	mov rsi, ANSI_CLEAR_LEN
	call write_to_buf

	;position cursor on top of snakes head
	mov di, [head]
	mov rsi, 0x3
	call move_cursor

	;-------snake------
	mov ax, [head]	;current position of snake body part that is drawn
	xor rcx, rcx

	;change color to snake color
	mov rdi, ANSI_WHITE
	mov rsi, ANSI_COL_LEN
	call write_to_buf

.snake_loop:
	call update_cursor_color
	mov rdi, rax
	mov rsi, [snake+rcx]
	call move_pos


	mov rdi, [snake+rcx]
	lea rdi, [ANSI_DIR + 4*rdi] ;4 is length of ANSI_DIR_LEN, can't use it directly in this context

	mov rsi, ANSI_DIR_LEN
	call write_to_buf
	call update_cursor_color

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
	call stdout

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

;move position given in rdi by direction given in rsi
move_pos:
	mov rax, rdi
	test rsi, 0x1	;vertical?
	jz .hor

	;vertical
	test rsi, 0x2	;up or down?
	jz .down
	;up
	dec ah
	ret
.down:	;down
	inc ah
	ret

.hor:	;horizontal
	test rsi, 0x2	;left or right?
	jz .left
	;right
	inc al
	ret
.left:	;left
	dec al
	ret

move_head:
	xor rax, rax
	mov ax, [head]
	mov rdi, rax
	xor rax, rax
	mov al, [dir]
	mov rsi, rax
	call move_pos
	ret

move_snake:
	call move_head	;new head position now in ax
	push rbx
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
	mov sil, [snake+rcx]
	call move_pos
	mov rbx, rax
	pop rax

	;counter increment and repeating
	inc rcx
	cmp rcx, [len]
	jl .body_loop

	;store new head position
	mov [head], ax

	;store direction in bl
	;revert moving direction to point to next body
	mov bl, [dir]
	xor bl, 0x2

	;shift entire snake body
	mov rcx, 0
.update_loop:
	;swap with next
	xor bl, [snake+rcx]
	xor [snake+rcx], bl
	xor bl, [snake+rcx]

	;counter and repeat
	inc rcx
	cmp rcx, [len]
	jl .update_loop

	pop rbx
	ret
.outofbounds:
	call game_over
	pop rbx
	ret
.self_collision:
	call game_over
	pop rbx
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
	mov rdi, 999 * 1000 * 1000
	call sleep_ns
	ret

init_game:
	;move head of snake in middle
	mov byte [head+0], WIDTH / 2
	mov byte [head+1], HEIGHT / 2

	;initial length of 3
	mov byte [len], 3

	;reverse default direction in order not to crash into itself at start
	mov byte r10b, [dir]
	xor r10b, 1
	mov byte [dir], r10b

	ret

game_over:
	call terminate
	ret
