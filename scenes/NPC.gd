extends Player
class_name NPC

const AGGRO_RANGE := 20.0

var input := PlayerInput.new()

func get_input(frame: int, players: Array[Player]) -> PlayerInput:
	var min_disp := Vector2.INF
	for p in players:
		var d := p.position - position
		var disp := Vector2(d.x, d.z)
		if disp.length() < min_disp.length():
			min_disp = disp

	if min_disp.length() > AGGRO_RANGE:
		input.move = Vector2.ZERO
		return

	var look_target := PI / 2.0 - min_disp.angle()
	input.look.x = lerp_angle(input.look.x, look_target, 0.1)

	var near := min_disp.length() < weapon.reach * 2
	input.move = Vector2.ZERO if near else min_disp.normalized()

	if frame % 60 == 0 and near:
		input.stance = Stance.ATTACK
	else:
		input.stance = Stance.STAND

	return input
