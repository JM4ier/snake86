handle_input:
	mov byte r15b, [dir]

.repeat:
	;result in [dir]
	push r15
	call stdin_ready
	pop r15
	test al, 0x1
	jz .exit

	;input ready here
	push r15
	call read_char
	pop r15

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
	jmp .repeat
.up:
	mov byte r15b, 3
	jmp .repeat
.down:
	mov byte r15b, 1
	jmp .repeat
.left:
	mov byte r15b, 0
	jmp .repeat
.right:
	mov byte r15b, 2
	jmp .repeat
.esc:
	call terminate
.exit:
	xor rax, rax
	mov al, [dir]
	xor al, r15b
	cmp al, 0x2
	jne .mov
	ret
.mov:
	mov byte [dir], r15b
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
	call move_head	;new head position now in ax
	push rbx

	xor rbx, rbx
	mov bx, [head]	;first new body position

	;check if head is out of bounds
	cmp al, 0
	je .outofbounds
	cmp al, SIZE + 1
	je .outofbounds
	cmp ah, 0
	je .outofbounds
	cmp ah, SIZE + 1
	je .outofbounds

	jmp .inbounds
	.outofbounds:
	mov byte [running], 0
	.inbounds:



	;loop over body and check for collisions
	mov rcx, 0
.body_loop:
	;check for head-body collision
	cmp rax, rbx
	jne .no_collision
	;self collision
	mov byte [running], 0
	.no_collision:

	;move to the next body part
	push rax
	mov rdi, rbx
	xor rsi, rsi
	mov byte sil, [snake+rcx]
	call move_pos
	mov rbx, rax
	pop rax

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
	xor rcx, rcx
	mov cl, [len]
	mov dl, [snake+rcx-1]
	mov [snake+rcx], dl
	inc cl
	mov [len], cl
	mov byte [food], 0
	ret

rand_in_field:
	call next_rand
	xor rdx, rdx
	mov r10, SIZE-4
	div r10
	mov rax, rdx
	add rax, 2
	ret

generate_food:
	cmp byte [food], 0
	jg .exit
	call next_rand
	and rax, 0x3FF
	cmp rax, FOOD_GEN_CHANCE
	jge .exit
	call rand_in_field
	mov byte [food+1], al
	call rand_in_field
	mov byte [food+2], al
	mov byte [food], 1
.exit:
	ret

game_tick:
	mov rdi, TICK_SLEEP * 1000 * 1000
	call sleep_ns
	ret

init_game:
	call init_rand
	;move head of snake in middle
	mov byte [head+0], SIZE / 2
	mov byte [head+1], SIZE / 2

	;set initial length
	mov byte [len], INITIAL_LENGTH

	;reverse default direction in order not to crash into itself at start
	mov byte r10b, [dir]
	xor r10b, 2
	mov byte [dir], r10b

	;game is running
	mov byte [running], 1
	ret

check_running:
	cmp qword [running], 1
	jne .game_over
	ret
.game_over:
	call clear_screen
	mov rdi, .go_message
	mov rsi, .go_message_len
	call stdout
	xor rdi, rdi
	mov byte dil, [len]
	sub rdi, INITIAL_LENGTH
	call print_number
	jmp terminate
.go_message: db 'Game over. Your score: '
.go_message_len: equ $ - .go_message


game_over:
	call terminate
	ret
