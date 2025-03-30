extends Button

func _pressed() -> void:
	Net.join(Settings.net_default_address.value, Settings.net_default_port.value)
	await multiplayer.connected_to_server
	Log.info("Server connected, starting game")
	get_tree().change_scene_to_file("res://menus/lobby/Lobby.tscn")
