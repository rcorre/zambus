extends Button

func _ready() -> void:
	grab_focus()

func _pressed() -> void:
	start.rpc()

@rpc("authority", "call_local", "reliable")
func start() -> void:
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

