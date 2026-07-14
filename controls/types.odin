package controls

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
