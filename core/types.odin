package core

Vec2i :: [2]int
Tetrimino :: [4]Vec2i
Playfield :: [PLAYFIELD_HEIGHT][PLAYFIELD_WIDTH]int
Bag :: [dynamic; 7]int

PieceState :: struct {
	idx: int,
	rotation: int,
	position: Vec2i
}

GameStatus :: enum {
	PLAYING,
	PAUSED,
	GAME_OVER
}

GameState :: struct {
	status: GameStatus,
	
	playfield: Playfield,
	active_piece: PieceState,
	total_time: f32,

	total_lines: int,
	prev_cleared_lines: int,
	num_b2bs: int,
	level: int,
	score: int,

	bag: Bag,
	can_retrieve_piece: bool,
	idx_piece_on_hold: int,

	auto_movement_timer: f32,
	lock_timer: f32
}

Action :: enum {
	MOVE_LEFT,
	MOVE_RIGHT,
	HOLD_LEFT,
	HOLD_RIGHT,

	ROTATE_LEFT,
	ROTATE_RIGHT,

	SOFT_DROP,
	HARD_DROP,

	HOLD_PIECE,

	PAUSE
}
ActionSet :: bit_set[Action]
