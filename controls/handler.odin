package controls

handle_actions :: proc(actions: ActionSet, game_state: ^game.GameState, delta: f32) {
	if .PAUSE in actions do game.toggle_pause(game_state)
	
	prev_active_piece_state := game_state.active_piece
	if .MOVE_LEFT in actions {
		game.move_piece_left(&game_state.active_piece)
		game_state.auto_movement_timer = game.AUTO_MOVEMENT_DELAY
	}
	if .MOVE_RIGHT in actions {
		game.move_piece_right(&game_state.active_piece)
		game_state.auto_movement_timer = game.AUTO_MOVEMENT_DELAY
	}
	if .HOLD_LEFT in actions {
		game_state.auto_movement_timer -= delta
		if game_state.auto_movement_timer <= 0{
			game.move_piece_left(&game_state.active_piece)
			game_state.auto_movement_timer = game.AUTO_MOVEMENT_DELAY
		}
	}
	if .HOLD_RIGHT in actions {
		game_state.auto_movement_timer -= delta
		if game_state.auto_movement_timer <= 0{
			game.move_piece_right(&game_state.active_piece)
			game_state.auto_movement_timer = game.AUTO_MOVEMENT_DELAY
		}
	}
	if .ROTATE_LEFT in actions do game.rotate_piece_left(&game_state.active_piece)
	if .ROTATE_RIGHT in actions do game.rotate_piece_right(&game_state.active_piece)
	
	if game.is_piece_colliding(game_state.active_piece, game_state.playfield) do game_state.active_piece = prev_active_piece_state

	if .HOLD_PIECE in actions do game.toggle_hold_piece(game_state)
	if .HARD_DROP in actions {
		preview_state := game.get_preview_piece(game_state.active_piece, game_state.playfield)
		game.place_piece(&game_state.playfield, preview_state)

		game.reset_piece_state(&game_state.active_piece, game.get_next_tetrimino_idx(&game_state.bag))
		game.calculate_points(game_state, game.clear_lines(&game_state.playfield))

		game_state.can_retrieve_piece = true
	}
}

import "../game"
