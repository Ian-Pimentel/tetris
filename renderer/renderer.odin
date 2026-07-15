package renderer

draw :: proc(game_state: game.GameState) {
	rl.DrawText(fmt.ctprintf("lock timer %.1f", game_state.lock_timer), game.CELL_SIZE * 3, game.CELL_SIZE * 15, 15, rl.PINK)
	
	draw_piece(game_state.active_piece)

	draw_playfield(game_state.playfield)

	preview_state := game.get_preview_piece(game_state.active_piece, game_state.playfield) 
	draw_piece(preview_state, PREVIEW_COLOR)

	draw_stats(game_state)

	draw_hold_piece(game_state)

	draw_next_piece(game_state)
	
	if game_state.num_b2bs >= 1 do draw_b2b_indicator(game_state)

	if game_state.status == .GAME_OVER {
		draw_game_over_screen()
	}
	
	if game_state.status == .PAUSED{
		draw_pause_screen()
	}
}

draw_piece :: proc(state: game.PieceState, color := rl.PINK) {
	for cell in game.get_tetrimino(state.idx, state.rotation) {
		piece_pos := state.position + cell

		rl.DrawRectangle(
			i32(piece_pos.x) * game.CELL_SIZE + (game.GAME_SIZE / 2) - (game.PLAYFIELD_WIDTH * game.CELL_SIZE / 2), 
			i32(piece_pos.y) * game.CELL_SIZE,
		 	game.CELL_SIZE,
				game.CELL_SIZE,
			color
		)
	}
}

draw_playfield :: proc(playfield: game.Playfield) {
	for row, y in playfield {
		for cell, x in row {
			cell_rect := rl.Rectangle{
				f32(x) * game.CELL_SIZE + (game.GAME_SIZE / 2) - (game.PLAYFIELD_WIDTH * game.CELL_SIZE / 2), 
				f32(y) * game.CELL_SIZE,
			 	game.CELL_SIZE,
					game.CELL_SIZE,
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

draw_stats :: proc(game_state: game.GameState) {
	stats_fontsize: i32 = 13
	// SCORE
	rl.DrawText(
		cstring("POINTS:"),
	 	game.GAME_SIZE * 0.1 + game.CELL_SIZE / 2,
	 	8 * game.CELL_SIZE,
	 	stats_fontsize,
	 	rl.PINK
	)
	rl.DrawText(
		fmt.ctprint(game_state.score),
	 	game.GAME_SIZE * 0.1 + game.CELL_SIZE / 2,
	 	9 * game.CELL_SIZE,
	 	stats_fontsize + 5,
	 	rl.PINK
	)
	// TIME
	rl.DrawText(
		cstring("TIME:"),
	 	game.GAME_SIZE * 0.1 + game.CELL_SIZE / 2,
	 	10 * game.CELL_SIZE,
	 	stats_fontsize,
	 	rl.PINK
	)
	rl.DrawText(
		fmt.ctprintf("%02d:%02d:%02d", game.split_time(game_state.total_time)),
	 	game.GAME_SIZE * 0.1 + game.CELL_SIZE / 2,
	 	11 * game.CELL_SIZE,
	 	stats_fontsize + 5,
	 	rl.PINK
	)
	
	// LINES
	rl.DrawText(
		cstring("LINES:"),
	 	game.GAME_SIZE * 0.1 + game.CELL_SIZE / 2,
	 	13 * game.CELL_SIZE,
	 	stats_fontsize,
	 	rl.PINK
	)
	rl.DrawText(
		fmt.ctprint(game_state.total_lines),
	 	game.GAME_SIZE * 0.2 + game.CELL_SIZE / 2,
	 	13 * game.CELL_SIZE,
	 	stats_fontsize + 2,
	 	rl.PINK
	)
}

draw_hold_piece :: proc(game_state: game.GameState) {
	rl.DrawText(
		cstring("HOLD"),
	 	game.CELL_WINDOW_RATIO * 3,
	 	3 * game.CELL_SIZE,
	 	game.CELL_SIZE,
	 	rl.PINK
	)

	if !game.is_hold_free(game_state) {
		for block_position, i in game.get_tetrimino(game_state.idx_piece_on_hold, 0) {
			rl.DrawRectangle(
				(i32(block_position.x) * game.CELL_SIZE) + game.GAME_SIZE * 0.15, 
				(i32(block_position.y) + 5) * game.CELL_SIZE,
			 	game.CELL_SIZE,
					game.CELL_SIZE,
				PREVIEW_COLOR
			)
		}
	}
}

draw_next_piece :: proc(game_state: game.GameState) {
	rl.DrawText(
		cstring("NEXT"),
	 	game.GAME_SIZE - game.CELL_WINDOW_RATIO * 5,
	 	3 * game.CELL_SIZE,
	 	game.CELL_SIZE,
	 	rl.PINK
	)
	
	next_tetrimino_idx := game_state.bag[len(game_state.bag) - 1]

	for block_position, i in game.get_tetrimino(next_tetrimino_idx, 0) {
		rl.DrawRectangle(
			(i32(block_position.x) * game.CELL_SIZE) + game.GAME_SIZE - game.CELL_WINDOW_RATIO * 5, 
			(i32(block_position.y) + 5) * game.CELL_SIZE,
		 	game.CELL_SIZE,
				game.CELL_SIZE,
			PREVIEW_COLOR
		)
	}
}

draw_b2b_indicator :: proc(game_state: game.GameState) {
	time := rl.GetTime()

	b2b_text := fmt.ctprintf("B2B!! %ix", game_state.num_b2bs)
	font_size: f32 = 20 + f32(math.sin( time * f64(math.min(8 + game_state.num_b2bs, 15)) )) * (f32(math.min(2 + game_state.num_b2bs, 10)) * .5)
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
			game.CELL_SIZE * game.CELL_WINDOW_RATIO * .80, 
			(game.CELL_SIZE * game.CELL_WINDOW_RATIO * .4) + f32(math.sin(time * 10)) * f32(math.min(2 + game_state.num_b2bs, 12)) * .5
		},
		text_size / 2,
		f32(math.sin(time * f64(math.min(1 + game_state.num_b2bs, 8)))) * f32(math.min(20 + game_state.num_b2bs, 28)),
		font_size, 
		font_spacing,
		rl.BLUE
	)
}

draw_pause_screen :: proc() {
	rl.DrawRectangleRec(rl.Rectangle{x = 0, y = 0, width = game.GAME_SIZE, height = game.GAME_SIZE}, rl.BLACK)

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
			game.GAME_SIZE / 2 - text_size.x / 2, 
			game.GAME_SIZE / 2 - text_size.y / 2
		},
		rl.Vector2{0, game.CELL_WINDOW_RATIO * 1.2},
		0,
		font_size, 
		font_spacing,
		rl.PINK
	)
}

draw_game_over_screen :: proc() {
	gm_color := rl.BLACK
	gm_color.a -= gm_color.a / 4
	rl.DrawRectangleRec(rl.Rectangle{x = 0, y = 0, width = game.GAME_SIZE, height = game.GAME_SIZE}, gm_color)

	font_spacing: f32 = 2.0
	font := rl.GetFontDefault()

	gm_text := cstring("GAME OVER")
	gm_font_size: f32 = 50
 	gm_size: rl.Vector2 = rl.MeasureTextEx(
		font,
		gm_text,
		gm_font_size + 4,
		font_spacing
	)
	rl.DrawTextPro(
		font,
		gm_text, 
		{
			game.GAME_SIZE / 2 - gm_size.x / 2, 
			game.GAME_SIZE / 2 - gm_size.y / 2
		},
		rl.Vector2{0, game.CELL_WINDOW_RATIO},
		0,
		gm_font_size, 
		font_spacing + 4,
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
			game.GAME_SIZE / 2 - gm2_size.x / 2, 
			game.GAME_SIZE / 2 - gm2_size.y / 2
		},
		rl.Vector2{0, 0},
		0,
		gm2_fontsize, 
		font_spacing,
		rl.ORANGE
	)
}

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import "../game"
