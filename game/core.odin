package game
import rand "core:math/rand"

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

reset_bag :: proc(bag: ^Bag) {
	bag^ = Bag{0,1,2,3,4,5,6}
	for idx in 0..<7 do bag[idx] = idx
	rand.shuffle(bag[:])
}

get_next_tetrimino_idx :: proc(bag: ^Bag) -> int {
	if len(bag) <= 1 {
		value := pop(bag)
		reset_bag(bag)
		return value
	}
	return pop(bag)
}

reset_piece_state :: proc(state: ^PieceState, piece_idx: int) {
	state^ = PieceState{piece_idx, 0, PIECES_INITIAL_POSITION}
}

is_position_outta_bounds :: proc(position: Vec2i) -> bool {
	return position.x < 0 || position.x >= PLAYFIELD_WIDTH || position.y < 0 || position.y >= PLAYFIELD_HEIGHT
}

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

get_points :: proc(lines_cleared: int) -> int { 
	assert(0 < lines_cleared && lines_cleared <= len(LINES_TO_POINTS))
	return LINES_TO_POINTS[lines_cleared - 1] 
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

calculate_points :: proc(game: ^GameState, lines_cleared: int) {
	if lines_cleared > 0 {
		points := get_points(lines_cleared)
		
		if lines_cleared >= 4 && game.prev_cleared_lines == lines_cleared {
			points = int(f32(points) * B2B_MULTIPLIER)
			game.num_b2bs += 1
		} else do game.num_b2bs = 0
		
		points *= game.level
		game.score += points
		
		game.total_lines += lines_cleared
		game.prev_cleared_lines = lines_cleared
	}
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

is_hold_free :: proc(game: GameState) -> bool {return game.idx_piece_on_hold == -1}
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

get_preview_piece :: proc(state: PieceState, playfield: Playfield) -> PieceState {
	preview_state := state

	for !is_piece_colliding(preview_state, playfield) do move_piece_down(&preview_state)
	if is_piece_colliding(preview_state, playfield) do move_piece_up(&preview_state)
	
	return preview_state
}

is_piece_suspended :: proc(state: PieceState, playfield: Playfield) -> bool {
	for block_position in get_tetrimino(state.idx, state.rotation) {
		cell_position := state.position + block_position
		cell_position.y += 1
		if is_position_outta_bounds(cell_position) || get_cell_value(cell_position, playfield) != 0 do return false
	}
	return true
}


split_time :: proc(time: f32) -> (minutes, seconds, milliseconds: i32) {
	minutes = i32(time / 60)
	seconds = i32(int(time) % 60)
	milliseconds = i32((time - f32(i32(time))) * 100)
	return
}
