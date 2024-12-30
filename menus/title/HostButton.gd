extends Button

func _pressed() -> void:
	Net.host(Settings.net_default_port.value)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
