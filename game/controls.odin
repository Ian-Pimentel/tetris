package game

get_action :: proc() -> game.ActionSet {
	actions: game.ActionSet
	
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

import "../game"
import rl "vendor:raylib"
