package game

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

import rand "core:math/rand"
