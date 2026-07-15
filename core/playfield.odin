package core

get_cell_value :: proc(position: Vec2i, playfield: Playfield) -> int {
	assert(!is_position_outta_bounds(position))
	return playfield[position.y][position.x]
}

set_cell :: proc(position: Vec2i, playfield: ^Playfield, value: int) {
	assert(!is_position_outta_bounds(position))
	playfield[position.y][position.x] = value
}

is_piece_colliding :: proc(state: PieceState, playfield: Playfield) -> bool {
	for block_position in get_tetrimino(state.idx, state.rotation) {
		cell_position := state.position + block_position
		if is_position_outta_bounds(cell_position) || get_cell_value(cell_position, playfield) != 0 do return true
	}
	return false
}

place_piece :: proc(playfield: ^Playfield, state: PieceState) {
	for block_position in get_tetrimino(state.idx, state.rotation) {
		cell_position := state.position + block_position
		set_cell(cell_position, playfield, 1)
	}
}

clear_lines :: proc(playfield: ^Playfield) -> int{
	cleared_lines := 0
	for y := PLAYFIELD_HEIGHT - 1; y >= 0; y -= 1 {
		is_row_clear := true
		
		for x in 0..<PLAYFIELD_WIDTH {
			if get_cell_value({x, y}, playfield^) == 0 {
				is_row_clear = false
				break
			}
		}

		row := playfield^[y]

		if is_row_clear {
			cleared_lines += 1
			row = [PLAYFIELD_WIDTH]int{}
		}
		else if cleared_lines > 0 {
			playfield^[y + cleared_lines] = row
			row = [PLAYFIELD_WIDTH]int{}
		}
	}

	return cleared_lines
}

is_position_outta_bounds :: proc(position: Vec2i) -> bool {
	return position.x < 0 || position.x >= PLAYFIELD_WIDTH || position.y < 0 || position.y >= PLAYFIELD_HEIGHT
}
