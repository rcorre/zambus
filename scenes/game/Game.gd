extends Node

func _ready() -> void:
	set_process_unhandled_key_input(OS.is_debug_build())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.keycode == KEY_ESCAPE:
		get_tree().quit()

