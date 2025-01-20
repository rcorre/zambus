extends Node3D
class_name Weapon

@export var hitscan_range := 100.0
@onready var anim: AnimationPlayer = $AnimationPlayer

func fire() -> void:
	anim.stop()
	anim.play("fire")
