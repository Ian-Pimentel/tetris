package tetris

Vec2i :: [2]int
Tetrimino :: [4]Vec2i
Playfield :: [PLAYFIELD_HEIGHT][PLAYFIELD_WIDTH]int
Bag :: [dynamic; 7]int

PieceState :: struct {
	idx: int,
	rotation: int,
	position: Vec2i
}
