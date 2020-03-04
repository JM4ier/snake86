global _start

%include "rawkb.s"
%include "consts.s"
%include "util.s"
%include "game.s"
%include "draw.s"
%include "rand.s"

_start:
	call rawkb_start;change keyboard to raw mode
	call init_game

	call clear_screen

	call build_buffer
	call reset_cursor
	call print_buffer

	mov byte [draw_scene_enabled], 0
	mov byte [debug], 1

.loop:
	;input and game logic
	call handle_input
	call move_snake
	call generate_food

	;drawing
	call clear_field
	call draw_snake
	call draw_food
	call build_buffer
	call reset_cursor
	call print_buffer

	;sleep
	call game_tick

	call check_running
	call check_food_eaten

	;repeat
	jmp .loop


section .rodata:
	ERR_MSG:	db "ERR", 0xA
	ERR_LEN:	equ $ - ERR_MSG

	;ansi escape codes
	ANSI_CLEAR:	db 0x1b, 0x5b, 0x48, 0x1b, 0x5b, 0x4a, 0x1b, 0x5b, 0x33, 0x4a
	ANSI_CLEAR_LEN:	equ $ - ANSI_CLEAR

	ANSI_DIR:
	ANSI_LEFT:	db 0x1b, "[1D"
	ANSI_UP:	db 0x1b, "[1A"
	ANSI_RIGHT:	db 0x1b, "[1C"
	ANSI_DOWN:	db 0x1b, "[1B"
	ANSI_DIR_LEN:	equ $ - ANSI_DOWN

	COL:
	COL_SNAKE:	db 0x1b, "[42m"
	COL_FOOD:	db 0x1b, "[41m"
	COL_BORDER:	db 0x1b, "[47m"
	COL_DEFAULT:	db 0x1b, "[40m"
	COL_LEN:	equ $ - COL_DEFAULT

	DIRS:		db 3, 1, 0, 2

align 4
section .bss
	randq		resq 1		;random number
	head		resw 1		;position of head of snake
	dir		resb 1		;direction the snake is heading
	snake		resb 128	;direction of snake's body for each part
	len		resb 1		;length of snake
	food		resb 3		;is there food? x, y
	buffer		resb 0x10000	;text buffer
	buffer_size	equ $ - buffer	;buffer size
	buffer_ptr	resq 1		;position in buffer
	gp_buffer	resb 1024	;general purpose buffer
	draw_scene_enabled	resb 1	;is the scene being rendered?
	debug		resb 1		;enable debug print statements?
	running		resq 1
	game_buf	resb SIZE*SIZE
