package tetris

// DEBUG FOR B2BS
// #reverse for column, y in playfield {
// 	for row, x in column {
// 		if y >= PLAYFIELD_HEIGHT-12 && x < PLAYFIELD_WIDTH-1 do set_cell({x, y}, &playfield, 1)
// 	}
// }

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})

	rl.InitWindow(game.GAME_SIZE, game.GAME_SIZE, "Tetris")
	defer rl.CloseWindow() 

	icon_image := rl.LoadImage("icon.png")
	defer rl.UnloadImage(icon_image)
	rl.SetWindowIcon(icon_image)

	icon_texture := rl.LoadTextureFromImage(icon_image)
	defer rl.UnloadTexture(icon_texture)

    rl.SetTargetFPS(60)
    
    camera := rl.Camera2D{
    	target = {
     		game.GAME_SIZE/2,
       		0
     	},
      	offset = {
       		game.GAME_SIZE - game.GAME_SIZE/2,
         	-game.CELL_WINDOW_RATIO * 1.2
       	},
        zoom = 1.2
    }
	
	game_state := game.GameState{}
	game.init_game(&game_state)

	tick_timer: f32 = game.TICK_RATE
	
	for !rl.WindowShouldClose() {
		switch game_state.status {
		case .PLAYING:	
			action := controls.poll_input()
			delta := rl.GetFrameTime()
			controls.handle_actions(action, &game_state, delta)
			tick_rate: f32 = game.TICK_RATE if .SOFT_DROP not_in action else game.HELD_TICK_RATE
			game.update(tick_rate, &game_state, &tick_timer, delta)
		case .PAUSED:
			if rl.IsKeyPressed(.P) do game_state.status = .PLAYING
		case .GAME_OVER:
			if rl.IsKeyPressed(.R) {
				game.init_game(&game_state)
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
import "controls"
import "game"
import "renderer"
import rl "vendor:raylib"
