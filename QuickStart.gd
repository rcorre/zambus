extends Node

# helper to skip directly to game
func _ready():
	var args := OS.get_cmdline_args()
	if len(args) < 2:
		push_error("Usage: godot QuickStart.tscn host [mode] [level]|join")
		get_tree().quit()
		return

	match args[1]:
		"host":
			Net.host(Settings.net_default_port.value)
			multiplayer.connect("peer_disconnected", Callable(get_tree(), "quit"))
		"join":
			Net.join(Settings.net_default_address.value, Settings.net_default_port.value)
			await multiplayer.connected_to_server
			multiplayer.connect("server_disconnected", Callable(get_tree(), "quit"))
			Log.info("Server connected, starting game")
		_:
			push_error("Usage: godot QuickStart.tscn host|join")
			get_tree().quit()

	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

