package tetris

get_action :: proc() -> core.ActionSet {
	actions: core.ActionSet
	
	if rl.IsKeyPressed(.P) 			do actions += {.PAUSE}
	
	if rl.IsKeyPressed(.LEFT) 		do actions += {.MOVE_LEFT}
	if rl.IsKeyPressed(.RIGHT) 		do actions += {.MOVE_RIGHT}
	
	if rl.IsKeyPressed(.Z) 			do actions += {.ROTATE_LEFT}
	if rl.IsKeyPressed(.X) 			do actions += {.ROTATE_RIGHT}
	
	if rl.IsKeyPressed(.LEFT_SHIFT) do actions += {.HOLD_PIECE} 
	
	if rl.IsKeyPressed(.SPACE) 		do actions += {.HARD_DROP}
	if rl.IsKeyDown(.DOWN) 			do actions += {.SOFT_DROP}

	if rl.IsKeyDown(.LEFT) 			do actions += {.HOLD_LEFT}
	if rl.IsKeyDown(.RIGHT) 		do actions += {.HOLD_RIGHT}
	
	return actions
}

// DEBUG FOR B2BS
// #reverse for column, y in playfield {
// 	for row, x in column {
// 		if y >= PLAYFIELD_HEIGHT-12 && x < PLAYFIELD_WIDTH-1 do set_cell({x, y}, &playfield, 1)
// 	}
// }

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})

	rl.InitWindow(core.GAME_SIZE, core.GAME_SIZE, "Tetris")
	defer rl.CloseWindow() 

	icon_image := rl.LoadImage("icon.png")
	defer rl.UnloadImage(icon_image)
	rl.SetWindowIcon(icon_image)

	icon_texture := rl.LoadTextureFromImage(icon_image)
	defer rl.UnloadTexture(icon_texture)

    rl.SetTargetFPS(60)
    
    camera := rl.Camera2D{
    	target = {
     		core.GAME_SIZE/2,
       		0
     	},
      	offset = {
       		core.GAME_SIZE - core.GAME_SIZE/2,
         	-core.CELL_WINDOW_RATIO * 1.2
       	},
        zoom = 1.2
    }
	
	game_state := core.GameState{}
	core.init_game(&game_state)

	tick_timer: f32 = core.TICK_RATE
	
	for !rl.WindowShouldClose() {
		switch game_state.status {
		case .PLAYING:	
				core.update(get_action(), &game_state, &tick_timer, rl.GetFrameTime())
		case .PAUSED:
			if rl.IsKeyPressed(.P) do game_state.status = .PLAYING
		case .GAME_OVER:
			if rl.IsKeyPressed(.R) {
				core.init_game(&game_state)
				game_state.status = .PLAYING
			}
		}

		rl.BeginDrawing()
		rl.BeginMode2D(camera)

		rl.ClearBackground(rl.BLACK) 
		renderer.draw(game_state)
		
		rl.EndMode2D()
		rl.EndDrawing()
		
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
	fmt.println("End of game!")
}

import "core:fmt"
import "core"
import "renderer"
import rl "vendor:raylib"
