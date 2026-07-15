package core

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

get_points :: proc(lines_cleared: int) -> int {
	assert(0 < lines_cleared && lines_cleared <= len(LINES_TO_POINTS))
	return LINES_TO_POINTS[lines_cleared - 1] 
}
