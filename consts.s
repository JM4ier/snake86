;important keycodes to control the game
K_UP 	equ 0x50
K_DOWN	equ 0x48
K_LEFT	equ 0x4b
K_RIGHT	equ 0x4d
K_ESC	equ 0x81

;system call numbers
;SYS_READ equ 0
;SYS_WRITE equ 1
SYS_POLL equ 7
SYS_EXIT equ 60

STDIN_FD equ 0
STDOUT_FD equ 1

DIR_UP equ 0x0
DIR_DOWN equ 0x1
DIR_RIGHT equ 0x2
DIR_LEFT equ 0x3

;playing fields for collision detection
EMPTY_FIELD equ 0
SNAKE_FIELD equ 1
FOOD_FIELD  equ 2

WIDTH equ 20
HEIGHT equ 20

