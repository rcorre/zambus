extends Node

var awaiting_peers: int

# helper to skip directly to game
func _ready():
	var args := OS.get_cmdline_args()
	if len(args) < 2:
		push_error("Usage: godot QuickStart.tscn host [guest_count]|join")
		get_tree().quit()
		return

	match args[1]:
		"host":
			Net.host(Settings.net_default_port.value)
			multiplayer.connect("peer_disconnected", Callable(get_tree(), "quit"))

			# guest_count + 1 for the host
			awaiting_peers = args[2].to_int() + 1
			multiplayer.peer_connected.connect(_on_peer_connected)
			_on_peer_connected(0)
		"join":
			Net.join(Settings.net_default_address.value, Settings.net_default_port.value)
			await multiplayer.connected_to_server
			multiplayer.connect("server_disconnected", Callable(get_tree(), "quit"))
			Log.info("Server connected, starting game")
			get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
		_:
			push_error("Usage: godot QuickStart.tscn host|join")
			get_tree().quit()

func _on_peer_connected(_id: int) -> void:
	awaiting_peers -= 1
	if awaiting_peers <= 0:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

