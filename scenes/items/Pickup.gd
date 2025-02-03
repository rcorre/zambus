extends Area3D
class_name Pickup

@export var item_id: Item.ID
var item: Item

var outline_material: StandardMaterial3D

# Set every frame by Player if under the cursor
var focused := false

func _ready() -> void:
	item = Item.load(item_id)
	add_child(item)

	collision_layer = Global.CollisionLayer.INTERACT
	monitoring = false

	# Create outline mesh
	var outline_mesh: Mesh
	for child in item.get_children():
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

	var shape := CollisionShape3D.new()
	add_child(shape)
	shape.shape = outline_mesh.create_convex_shape(true, true)

func _process(delta: float) -> void:
	var albedo_target := 1 if focused else 0
	focused = false
	outline_material.albedo_color.a = move_toward(outline_material.albedo_color.a, albedo_target, delta * 3.0)

@rpc("authority", "call_local", "reliable")
func take() -> void:
	queue_free()
