extends Node3D

@onready var model: PlayerModel = $ThirdPersonModel

func _ready() -> void:
	prints("ready")
	model.die(false)
