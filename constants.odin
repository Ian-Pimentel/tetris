package tetris

import rl "vendor:raylib"

GAME_SIZE :: 600

CELL_SIZE :: 20
CELL_WINDOW_RATIO :: GAME_SIZE / CELL_SIZE

PLAYFIELD_WIDTH :: 10
PLAYFIELD_HEIGHT :: 22

TICK_RATE :: 0.3
HELD_TICK_RATE :: 0.1
AUTO_MOVEMENT_DELAY :: 0.15
LOCK_DELAY :: 0.5

NUM_PIECES :: 7
NUM_ROTATIONS :: 4

PIECES_INITIAL_POSITION :: Vec2i{0, 0}

PREVIEW_COLOR :: rl.Color{rl.PINK.r, rl.PINK.g, rl.PINK.b, rl.PINK.a / 2}

@(rodata)
LINES_TO_POINTS := [4]int{100, 300, 500, 800}
B2B_MULTIPLIER :: 1.5

// não se escore na abstração alheia, modularize! o core da aplicação não deve depender da impls 
// import rl "vendor:raylib"
// @(rodata)
// COLORS := [NUM_PIECES]rl.Color{
// 	rl.BLUE,
// 	rl.DARKBLUE,
// 	rl.ORANGE,
// 	rl.YELLOW,
// 	rl.PURPLE,
// 	rl.GREEN,
// 	rl.RED,
// }

@(rodata)
TETRIMINOS := [NUM_PIECES][NUM_ROTATIONS]Tetrimino{
    { // I
        {{0,1}, {1,1}, {2,1}, {3,1}},
        {{2,0}, {2,1}, {2,2}, {2,3}},
        {{0,2}, {1,2}, {2,2}, {3,2}},
        {{1,0}, {1,1}, {1,2}, {1,3}} 
    },
    { // J
        {{0,0}, {0,1}, {1,1}, {2,1}},
        {{1,0}, {2,0}, {1,1}, {1,2}},
        {{0,1}, {1,1}, {2,1}, {2,2}},
        {{1,0}, {1,1}, {0,2}, {1,2}}
    },
    { // L
        {{2,0}, {0,1}, {1,1}, {2,1}},
        {{1,0}, {1,1}, {1,2}, {2,2}},
        {{0,1}, {1,1}, {2,1}, {0,2}},
        {{0,0}, {1,0}, {1,1}, {1,2}}
    },
    { // O
        {{1,0}, {2,0}, {1,1}, {2,1}},
        {{1,0}, {2,0}, {1,1}, {2,1}},
        {{1,0}, {2,0}, {1,1}, {2,1}},
        {{1,0}, {2,0}, {1,1}, {2,1}}
    },
    { // S
        {{1,0}, {2,0}, {0,1}, {1,1}},
        {{1,0}, {1,1}, {2,1}, {2,2}},
        {{1,1}, {2,1}, {0,2}, {1,2}},
        {{0,0}, {0,1}, {1,1}, {1,2}}
    },
    { // T
        {{1,0}, {0,1}, {1,1}, {2,1}},
        {{1,0}, {1,1}, {2,1}, {1,2}},
        {{0,1}, {1,1}, {2,1}, {1,2}},
        {{1,0}, {0,1}, {1,1}, {1,2}}
    },
    { // Z
        {{0,0}, {1,0}, {1,1}, {2,1}},
        {{2,0}, {1,1}, {2,1}, {1,2}},
        {{0,1}, {1,1}, {1,2}, {2,2}},
        {{1,0}, {0,1}, {1,1}, {0,2}}
    }
};
