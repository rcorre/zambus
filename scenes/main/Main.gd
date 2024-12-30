extends Control

const HUD_SCENE := preload("res://scenes/hud/HUD.tscn")

func _ready() -> void:
	var map := preload("res://scenes/maps/Town.tscn").instantiate()
	map.name = "Map"
	var game: Game
	if is_multiplayer_authority():
		game = GameHost.new()
	else:
		game = GamePeer.new()
	game.name = "Game"
	game.add_child(map)
	game.add_child(HUD_SCENE.instantiate())
	add_child(game)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
