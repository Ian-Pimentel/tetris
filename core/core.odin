package core

init_game :: proc(game: ^GameState) {
	game^ = GameState{level = 1, can_retrieve_piece = true, idx_piece_on_hold = -1}

	reset_bag(&game.bag)
	reset_piece_state(&game.active_piece, get_next_tetrimino_idx(&game.bag))

	game.auto_movement_timer = AUTO_MOVEMENT_DELAY
	game.lock_timer = LOCK_DELAY
}

input :: proc(actions: ActionSet, game_state: ^GameState, delta: f32) {
	if .PAUSE in actions do toggle_pause(game_state)
	
	prev_active_piece_state := game_state.active_piece
	if .MOVE_LEFT in actions {
		move_piece_left(&game_state.active_piece)
		game_state.auto_movement_timer = AUTO_MOVEMENT_DELAY
	}
	if .MOVE_RIGHT in actions {
		move_piece_right(&game_state.active_piece)
		game_state.auto_movement_timer = AUTO_MOVEMENT_DELAY
	}
	if .HOLD_LEFT in actions {
		game_state.auto_movement_timer -= delta
		if game_state.auto_movement_timer <= 0{
			move_piece_left(&game_state.active_piece)
			game_state.auto_movement_timer = AUTO_MOVEMENT_DELAY
		}
	}
	if .HOLD_RIGHT in actions {		
		game_state.auto_movement_timer -= delta
		if game_state.auto_movement_timer <= 0{
			move_piece_right(&game_state.active_piece)
			game_state.auto_movement_timer = AUTO_MOVEMENT_DELAY
		}
	}
	if .ROTATE_LEFT in actions do rotate_piece_left(&game_state.active_piece)
	if .ROTATE_RIGHT in actions do rotate_piece_right(&game_state.active_piece)
	
	if is_piece_colliding(game_state.active_piece, game_state.playfield) do game_state.active_piece = prev_active_piece_state

	if .HOLD_PIECE in actions do toggle_hold_piece(game_state) 
	if .HARD_DROP in actions {
		preview_state := get_preview_piece(game_state.active_piece, game_state.playfield)
		place_piece(&game_state.playfield, preview_state)

		reset_piece_state(&game_state.active_piece, get_next_tetrimino_idx(&game_state.bag))
		calculate_points(game_state, clear_lines(&game_state.playfield))

		game_state.can_retrieve_piece = true
	}
}

update :: proc(action: ActionSet, game_state: ^GameState, tick_timer: ^f32, delta: f32) {
	input(action, game_state, delta)

	game_state.total_time += delta
	
	prev_active_piece_state := game_state.active_piece
	
	tick_timer^ -= delta
	if tick_timer^ <= 0 {
		if is_piece_suspended(game_state.active_piece, game_state.playfield) {
			move_piece_down(&game_state.active_piece)
			game_state.lock_timer = LOCK_DELAY
		}

		if .SOFT_DROP in action do tick_timer^ += HELD_TICK_RATE
		else do tick_timer^ += TICK_RATE
	}

	if !is_piece_suspended(game_state.active_piece, game_state.playfield) {
		game_state.lock_timer -= delta

		if game_state.lock_timer <= 0 {
			game_state.lock_timer += LOCK_DELAY

			place_piece(&game_state.playfield, prev_active_piece_state)
			game_state.can_retrieve_piece = true
			calculate_points(game_state, clear_lines(&game_state.playfield))
			
			reset_piece_state(&game_state.active_piece, get_next_tetrimino_idx(&game_state.bag))
			// loose
			if is_piece_colliding(game_state.active_piece, game_state.playfield) do game_state.status = .GAME_OVER
		}
	}
}

toggle_pause :: proc(game_state: ^GameState) {
	if game_state.status == .PAUSED do game_state.status = .PLAYING
	else do game_state.status = .PAUSED
}

is_hold_free :: proc(game: GameState) -> bool {return game.idx_piece_on_hold == -1}

split_time :: proc(time: f32) -> (minutes, seconds, milliseconds: i32) {
	minutes = i32(time / 60)
	seconds = i32(int(time) % 60)
	milliseconds = i32((time - f32(i32(time))) * 100)
	return
}
