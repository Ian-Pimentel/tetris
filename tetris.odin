package tetris

Status :: enum {
	PLAYING,
	PAUSED,
	GAME_OVER
}

GameState :: struct {
	status: Status,
	
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


init_game :: proc(game: ^GameState) { 
	game^ = GameState{level = 1, can_retrieve_piece = true, idx_piece_on_hold = -1}

	reset_bag(&game.bag)
	reset_piece_state(&game.active_piece, get_next_tetrimino_idx(&game.bag))

	game.auto_movement_timer = AUTO_MOVEMENT_DELAY
	game.lock_timer = LOCK_DELAY
}

reset_bag :: proc(bag: ^Bag) {
	bag^ = Bag{0,1,2,3,4,5,6}
	for idx in 0..<7 do bag[idx] = idx
	rand.shuffle(bag[:])
}

camera := rl.Camera2D{target = {GAME_SIZE/2, 0}, offset = {GAME_SIZE - GAME_SIZE/2, -CELL_WINDOW_RATIO * 1.2}, zoom = 1.2}
// camera := rl.Camera2D{target = {GAME_SIZE/2, 0}, offset = {GAME_SIZE - GAME_SIZE/2, 0}, zoom = 1}

get_tetrimino :: proc(idx, rotation: int) -> Tetrimino {
	return TETRIMINOS[idx][rotation]
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

// set_random_piece :: proc(state: ^PieceState) {
// 	state^ = PieceState{get_next_tetrimino_idx(), 0, PIECES_INITIAL_POSITION}
// }

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

	// can_retrieve_piece = true
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

draw_piece :: proc(state: PieceState, color := rl.PINK) {
	for cell in get_tetrimino(state.idx, state.rotation) {
		piece_pos := state.position + cell

		rl.DrawRectangle(
			i32(piece_pos.x) * CELL_SIZE + (GAME_SIZE / 2) - (PLAYFIELD_WIDTH * CELL_SIZE / 2), 
			i32(piece_pos.y) * CELL_SIZE,
		 	CELL_SIZE,
			CELL_SIZE,
			color
		)
	}
}

draw_playfield :: proc(playfield: Playfield) {
	for row, y in playfield {
		for cell, x in row {
			cell_rect := rl.Rectangle{
				f32(x) * CELL_SIZE + (GAME_SIZE / 2) - (PLAYFIELD_WIDTH * CELL_SIZE / 2), 
				f32(y) * CELL_SIZE,
			 	CELL_SIZE,
				CELL_SIZE,
			}
			if cell >= 1 do rl.DrawRectangleRec(
				cell_rect,
				rl.PINK
			)
			rl.DrawRectangleLinesEx(
				cell_rect,
				1,
				rl.PINK
			)
		}
	}
}

input :: proc(game: ^GameState, delta: f32) {
	prev_active_piece_state := game.active_piece
	
	if rl.IsKeyPressed(.LEFT) {
		move_piece_left(&game.active_piece)
		game.auto_movement_timer = AUTO_MOVEMENT_DELAY
	}
	if rl.IsKeyPressed(.RIGHT) {
		move_piece_right(&game.active_piece)
		game.auto_movement_timer = AUTO_MOVEMENT_DELAY
	}
	
	if rl.IsKeyDown(.LEFT) {
		game.auto_movement_timer -= delta
		if game.auto_movement_timer <= 0{
			move_piece_left(&game.active_piece)
			game.auto_movement_timer = AUTO_MOVEMENT_DELAY
		}
	}
	if rl.IsKeyDown(.RIGHT) {
		game.auto_movement_timer -= delta
		if game.auto_movement_timer <= 0{
			move_piece_right(&game.active_piece)
			game.auto_movement_timer = AUTO_MOVEMENT_DELAY
		}
	}

	if rl.IsKeyPressed(.Z) {
		rotate_piece_left(&game.active_piece)
	}
	if rl.IsKeyPressed(.X) {
		rotate_piece_right(&game.active_piece)
	}

	if rl.IsKeyPressed(.LEFT_SHIFT) do toggle_hold_piece(game) 

	if rl.IsKeyPressed(.P) do game.status = .PAUSED

	if is_piece_colliding(game.active_piece, game.playfield) do game.active_piece = prev_active_piece_state
	
	if rl.IsKeyPressed(.SPACE) {
		preview_state := get_preview_piece(game.active_piece, game.playfield)
		place_piece(&game.playfield, preview_state)

		reset_piece_state(&game.active_piece, get_next_tetrimino_idx(&game.bag))
		calculate_points(game, clear_lines(&game.playfield))

		game.can_retrieve_piece = true
	}
}

update :: proc(game: ^GameState, tick_timer: ^f32) {
	prev_active_piece_state := game.active_piece
	
	game.total_time += rl.GetFrameTime()
	tick_timer^ -= rl.GetFrameTime()
	
	if tick_timer^ <= 0 {
		move_piece_down(&game.active_piece)

		if is_piece_colliding(game.active_piece, game.playfield) {
			place_piece(&game.playfield, prev_active_piece_state)
			game.can_retrieve_piece = true
			calculate_points(game, clear_lines(&game.playfield))
			
			reset_piece_state(&game.active_piece, get_next_tetrimino_idx(&game.bag))
			// loose
			if is_piece_colliding(game.active_piece, game.playfield) do game.status = .GAME_OVER
		}
		
		if rl.IsKeyDown(.DOWN) do tick_timer^ = HELD_TICK_RATE + tick_timer^
		else do tick_timer^ = TICK_RATE + tick_timer^
	}
}

split_time :: proc(time: f32) -> (minutes, seconds, milliseconds: i32) {
	minutes = i32(time / 60)
	seconds = i32(int(time) % 60)
	milliseconds = i32((time - f32(i32(time))) * 100)
	return
}

draw_stats :: proc(game: GameState) {
	stats_fontsize: i32 = 13
	// SCORE
	rl.DrawText(
		cstring("POINTS:"),
	 	GAME_SIZE * 0.1 + CELL_SIZE / 2,
	 	8 * CELL_SIZE,
	 	stats_fontsize,
	 	rl.PINK
	)
	rl.DrawText(
		fmt.ctprint(game.score),
	 	GAME_SIZE * 0.1 + CELL_SIZE / 2,
	 	9 * CELL_SIZE,
	 	stats_fontsize + 5,
	 	rl.PINK
	)
	// TIME
	rl.DrawText(
		cstring("TIME:"),
	 	GAME_SIZE * 0.1 + CELL_SIZE / 2,
	 	10 * CELL_SIZE,
	 	stats_fontsize,
	 	rl.PINK
	)
	rl.DrawText(
		fmt.ctprintf("%02d:%02d:%02d", split_time(game.total_time)),
	 	GAME_SIZE * 0.1 + CELL_SIZE / 2,
	 	11 * CELL_SIZE,
	 	stats_fontsize + 5,
	 	rl.PINK
	)
	
	// LINES
	rl.DrawText(
		cstring("LINES:"),
	 	GAME_SIZE * 0.1 + CELL_SIZE / 2,
	 	13 * CELL_SIZE,
	 	stats_fontsize,
	 	rl.PINK
	)
	rl.DrawText(
		fmt.ctprint(game.total_lines),
	 	GAME_SIZE * 0.2 + CELL_SIZE / 2,
	 	13 * CELL_SIZE,
	 	stats_fontsize + 2,
	 	rl.PINK
	)
}

draw_hold_piece :: proc(game: GameState) {
	rl.DrawText(
		cstring("HOLD"),
	 	CELL_WINDOW_RATIO * 3,
	 	3 * CELL_SIZE,
	 	CELL_SIZE,
	 	rl.PINK
	)

	if !is_hold_free(game) {
		for block_position, i in get_tetrimino(game.idx_piece_on_hold, 0) {
			rl.DrawRectangle(
				(i32(block_position.x) * CELL_SIZE) + GAME_SIZE * 0.15, 
				(i32(block_position.y) + 5) * CELL_SIZE,
			 	CELL_SIZE,
				CELL_SIZE,
				PREVIEW_COLOR
			)
		}
	}
}

draw_next_piece :: proc(game: GameState) {
	rl.DrawText(
		cstring("NEXT"),
	 	GAME_SIZE - CELL_WINDOW_RATIO * 5,
	 	3 * CELL_SIZE,
	 	CELL_SIZE,
	 	rl.PINK
	)
	
	next_tetrimino_idx := game.bag[len(game.bag) - 1]

	for block_position, i in get_tetrimino(next_tetrimino_idx, 0) {
		rl.DrawRectangle(
			(i32(block_position.x) * CELL_SIZE) + GAME_SIZE - CELL_WINDOW_RATIO * 5, 
			(i32(block_position.y) + 5) * CELL_SIZE,
		 	CELL_SIZE,
			CELL_SIZE,
			PREVIEW_COLOR
		)
	}
}

draw_b2b_indicator :: proc(game: GameState) {
	time := rl.GetTime()

	b2b_text := fmt.ctprintf("B2B!! %ix", game.num_b2bs)
	font_size: f32 = 20 + f32(math.sin( time * f64(math.min(8 + game.num_b2bs, 15)) )) * (f32(math.min(2 + game.num_b2bs, 10)) * .5)
	font_spacing: f32 = 1.0
 	text_size: rl.Vector2 = rl.MeasureTextEx(
		rl.GetFontDefault(),
		b2b_text,
		font_size,
		font_spacing
	)
	
	rl.DrawTextPro(
		rl.GetFontDefault(),
		b2b_text, 
		{
			CELL_SIZE * CELL_WINDOW_RATIO * .80, 
			(CELL_SIZE * CELL_WINDOW_RATIO * .4) + f32(math.sin(time * 10)) * f32(math.min(2 + game.num_b2bs, 12)) * .5
		},
		text_size / 2,
		f32(math.sin(time * f64(math.min(1 + game.num_b2bs, 8)))) * f32(math.min(20 + game.num_b2bs, 28)),
		font_size, 
		font_spacing,
		rl.BLUE
	)
}

draw_pause_screen :: proc() {
	rl.DrawRectangleRec(rl.Rectangle{x = 0, y = 0, width = GAME_SIZE, height = GAME_SIZE}, rl.BLACK)

	pause_text := cstring("PAUSED")
	font := rl.GetFontDefault()
	font_size: f32 = 50
	font_spacing: f32 = 1.0
 	text_size: rl.Vector2 = rl.MeasureTextEx(
		font,
		pause_text,
		font_size,
		font_spacing
	)
	rl.DrawTextPro(
		font,
		pause_text, 
		{
			GAME_SIZE / 2 - text_size.x / 2, 
			GAME_SIZE / 2 - text_size.y / 2
		},
		rl.Vector2{0, CELL_WINDOW_RATIO * 1.2},
		0,
		font_size, 
		font_spacing,
		rl.PINK
	)
}

draw_game_over_screen :: proc() {
	gm_color := rl.BLACK
	gm_color.a -= gm_color.a / 4
	rl.DrawRectangleRec(rl.Rectangle{x = 0, y = 0, width = GAME_SIZE, height = GAME_SIZE}, gm_color)

	font_spacing: f32 = 1.0
	font := rl.GetFontDefault()

	gm_text := cstring("GAME OVER")
	gm_font_size: f32 = 50
 	gm_size: rl.Vector2 = rl.MeasureTextEx(
		font,
		gm_text,
		gm_font_size,
		font_spacing
	)
	rl.DrawTextPro(
		font,
		gm_text, 
		{
			GAME_SIZE / 2 - gm_size.x / 2, 
			GAME_SIZE / 2 - gm_size.y / 2
		},
		rl.Vector2{0, CELL_WINDOW_RATIO},
		0,
		gm_font_size, 
		font_spacing,
		rl.RED
	)

	gm2_text := cstring("PRESS (R) TO RESTART")
	gm2_fontsize := gm_font_size - 30
 	gm2_size: rl.Vector2 = rl.MeasureTextEx(
		font,
		gm2_text,
		gm2_fontsize,
		font_spacing
	)
	rl.DrawTextPro(
		font,
		gm2_text, 
		{
			GAME_SIZE / 2 - gm2_size.x / 2, 
			GAME_SIZE / 2 - gm2_size.y / 2
		},
		rl.Vector2{0, 0},
		0,
		gm2_fontsize, 
		font_spacing,
		rl.ORANGE
	)
}

draw :: proc(game: GameState) {
	draw_piece(game.active_piece)

	draw_playfield(game.playfield)

	preview_state := get_preview_piece(game.active_piece, game.playfield) 
	draw_piece(preview_state, PREVIEW_COLOR)

	draw_stats(game)

	draw_hold_piece(game)

	draw_next_piece(game)
	
	if game.num_b2bs >= 1 do draw_b2b_indicator(game)

	if game.status == .GAME_OVER {
		draw_game_over_screen()
	}
	
	if game.status == .PAUSED{
		draw_pause_screen()
	}
}

// DEBUG FOR B2BS
// #reverse for column, y in playfield {
// 	for row, x in column {
// 		if y >= PLAYFIELD_HEIGHT-12 && x < PLAYFIELD_WIDTH-1 do set_cell({x, y}, &playfield, 1)
// 	}
// }

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(GAME_SIZE, GAME_SIZE, "Tetris")

    rl.SetTargetFPS(60)
	
	game := GameState{}
	init_game(&game)

	tick_timer: f32 = TICK_RATE
	
	for !rl.WindowShouldClose() {
		fmt.println(game.status)
		switch game.status {
		case .PLAYING:
				input(&game, rl.GetFrameTime())
				update(&game, &tick_timer)
		case .PAUSED:
			if rl.IsKeyPressed(.P) do game.status = .PLAYING
		case .GAME_OVER:
			if rl.IsKeyPressed(.R) {
				init_game(&game)
				game.status = .PLAYING
			}
		}

		rl.BeginDrawing()
		rl.BeginMode2D(camera)

		rl.ClearBackground(rl.BLACK) 
		draw(game)
		
		rl.EndMode2D()
		rl.EndDrawing()
		
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
	fmt.println("End of game!")
}

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"
