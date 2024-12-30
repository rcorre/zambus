extends Node3D

func _unhandled_key_input(_event: InputEvent) -> void:
	var model: PlayerModel = $PlayerModel

	var state := PlayerState.new()
	state.health = 5
	model.update_state(state, false)

	var state2 := PlayerState.new()
	state2.health = 0
	model.update_state(state2, false)

	set_process_unhandled_key_input(false)
