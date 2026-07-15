package game

is_piece_suspended :: proc(state: PieceState, playfield: Playfield) -> bool {
	for block_position in get_tetrimino(state.idx, state.rotation) {
		cell_position := state.position + block_position
		cell_position.y += 1
		if is_position_outta_bounds(cell_position) || get_cell_value(cell_position, playfield) != 0 do return false
	}
	return true
}

get_preview_piece :: proc(state: PieceState, playfield: Playfield) -> PieceState {
	preview_state := state

	for !is_piece_colliding(preview_state, playfield) do move_piece_down(&preview_state)
	if is_piece_colliding(preview_state, playfield) do move_piece_up(&preview_state)
	
	return preview_state
}

toggle_hold_piece :: proc(game: ^GameState) {
	if is_hold_free(game^) {
		game.idx_piece_on_hold = game.active_piece.idx
		reset_piece_state(&game.active_piece, get_next_tetrimino_idx(&game.bag))
		// append_fixed_capacity_elem(&bag, idx_piece_on_hold)
	}
	else if game.can_retrieve_piece {
		curr_idx := game.active_piece.idx
		reset_piece_state(&game.active_piece, game.idx_piece_on_hold)
		game.idx_piece_on_hold = curr_idx
	}
	game.can_retrieve_piece = false
}

reset_piece_state :: proc(state: ^PieceState, piece_idx: int) {
	state^ = PieceState{piece_idx, 0, PIECES_INITIAL_POSITION}
}

move_piece_left  :: proc(state: ^PieceState) { 
	state.position += {-1, 0}
}
move_piece_right :: proc(state: ^PieceState) { 
	state.position += {1, 0} 
}
move_piece_up  :: proc(state: ^PieceState) { 
	state.position += {0, -1}
}
move_piece_down  :: proc(state: ^PieceState) { 
	state.position += {0, 1} 
}
rotate_piece_left :: proc(state: ^PieceState) {
	if state^.rotation <= 0 do state^.rotation = NUM_ROTATIONS - 1
	else do state^.rotation -= 1
}
rotate_piece_right :: proc(state: ^PieceState) {
	state.rotation = (state.rotation + 1) % 4
}
