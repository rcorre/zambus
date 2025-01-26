extends Node3D
class_name Weapon

@export var hitscan_range := 100.0
@export var mag_size := 12
@onready var anim: AnimationPlayer = $AnimationPlayer

@export var max_spread := 12.0
@export var min_spread := 4.0
@export var move_spread := 8.0
@export var recoil := 4.0

func fire() -> void:
	anim.stop()
	anim.play("fire")

func reload() -> void:
	anim.play("reload")
