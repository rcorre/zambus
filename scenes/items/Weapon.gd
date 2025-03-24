extends Item
class_name Weapon

enum Kind {
	NONE,
	PISTOL
}

@onready var anim: AnimationPlayer = $AnimationPlayer

@export var hitscan_range := 100.0
@export var mag_size := 12

@export var kind: Kind
@export var max_spread := 12.0
@export var min_spread := 4.0
@export var move_spread := 8.0
@export var recoil := 4.0
@export var stamina_cost := 20.0

var outline_material: StandardMaterial3D

func is_gun() -> bool:
	return kind in [Kind.PISTOL]

func fire() -> void:
	anim.stop()
	anim.play("fire")
