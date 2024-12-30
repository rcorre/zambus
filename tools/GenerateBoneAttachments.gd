@tool
extends Skeleton3D

@export var run: bool:
	set(value):
		if value:
			_run()

func _run() -> void:
	for i in get_bone_count():
		var bone := BoneAttachment3D.new()
		add_child(bone)
		bone.set_owner(get_tree().edited_scene_root)
		bone.name = get_bone_name(i)
		bone.bone_idx = i
		var area := Area3D.new()
		bone.add_child(area)
		area.set_owner(get_tree().edited_scene_root)
		area.name = "Hitbox"
		var col := CollisionShape3D.new()
		area.add_child(col)
		var shape := CylinderShape3D.new()
		col.shape = shape
		col.set_owner(get_tree().edited_scene_root)
		col.name = "CollisionShape3D"
		shape.radius = 0.1
		shape.height = 0.3
