global _start

%include "rawkb.s"
%include "consts.s"
%include "util.s"
%include "game.s"

_start:
	call rawkb_start;change keyboard to raw mode
	call init_game

.loop:
	call handle_input
	call move_snake
	call draw_scene
	call game_tick
	jmp .loop


align 4
section .bss
	head		resb 2		;position of head of snake
	dir		resb 1		;direction the snake is heading
	snake		resb 128	;direction of snake's body for each part
	len		resb 1		;length of snake
	food		resb 3		;is there food? x, y
	buffer		resb 1024	;text buffer
	buffer_ptr	resq 1		;position in buffer

section .rodata:
	MSG:		db "Hello, Snake!", 0xA
	MSG_LEN:	equ $ - MSG
	ERR_MSG:	db "ERR", 0xA
	ERR_LEN:	equ $ - ERR_MSG

	;ansi escape codes
	ANSI_CLEAR:	db 0x1b, 0x5b, 0x48, 0x1b, 0x5b, 0x4a, 0x1b, 0x5b, 0x33, 0x4a
	ANSI_CLEAR_LEN:	equ $ - ANSI_CLEAR

ANSI_DIR:
	ANSI_LEFT:	db 0x1b, "[1D"
	ANSI_RIGHT:	db 0x1b, "[1C"
	ANSI_DOWN:	db 0x1b, "[1B"
	ANSI_UP:	db 0x1b, "[1A"
	ANSI_DIR_LEN:	equ $ - ANSI_UP

	ANSI_WHITE:	db 0x1b, "[47m"
	ANSI_GREEN:	db 0x1b, "[42m"
	ANSI_BLACK:	db 0x1b, "[40m"
	ANSI_COL_LEN:	equ $ - ANSI_BLACK

	DIRS:		db 3, 1, 0, 2

