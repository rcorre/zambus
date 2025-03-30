extends Control

func _ready():
	NetworkEvents.on_client_stop.connect(_on_stop)
	NetworkEvents.on_server_stop.connect(_on_stop)

func _on_stop() -> void:
	Log.info("Lobby exiting")
	get_tree().change_scene_to_file("res://menus/title/Title.tscn")
