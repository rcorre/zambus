extends Node3D

@onready var model: ZombieModel = $ZombieModel

func _ready() -> void:
	prints("ready")
	model.die()

