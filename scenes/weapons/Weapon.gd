extends Area3D
class_name Weapon

enum Kind {
	MELEE_1H,
	MELEE_2H,
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

func _ready() -> void:
	collision_layer = Global.CollisionLayer.INTERACT
	monitoring = false

	# Create outlien mesh
	var outline_mesh: Mesh
	for child in get_children():
		var child_mesh := child as MeshInstance3D
		if child_mesh:
			outline_mesh = child_mesh.mesh.create_outline(0.01)
			break

	if not outline_mesh:
		push_warning("No mesh found for item", name)
		return

	var outline := MeshInstance3D.new()
	outline.mesh = outline_mesh
	add_child(outline)

	outline_material = StandardMaterial3D.new()
	outline.material_override = outline_material
	outline_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_material.albedo_color.a = 0


func equip() -> void:
	collision_layer = 0

@rpc("authority", "call_local", "reliable")
func take() -> void:
	queue_free()

func is_gun() -> bool:
	return kind in [Kind.PISTOL]

func fire() -> void:
	anim.stop()
	anim.play("fire")

func reload() -> void:
	anim.play("reload")
