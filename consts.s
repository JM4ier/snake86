;important keycodes to control the game
K_UP 	equ 0x48
K_DOWN	equ 0x50
K_LEFT	equ 0x4b
K_RIGHT	equ 0x4d
K_ESC	equ 0x81

;size of playing field
SIZE equ 32

;prime used for random number generation
PRIME equ 0xFFFFFFFB

;probability of food to generate each game tick in 1024th
;e.g. 512 spawns food every second tick on average
FOOD_GEN_CHANCE equ 50

;ms of sleeping per game tick
TICK_SLEEP equ 30

;initial length of snake
INITIAL_LENGTH equ 3

