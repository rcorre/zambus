extends Button

func _ready() -> void:
	grab_focus()

func _pressed() -> void:
	Net.host(Settings.net_default_port.value)
	get_tree().change_scene_to_file("res://menus/lobby/Lobby.tscn")
