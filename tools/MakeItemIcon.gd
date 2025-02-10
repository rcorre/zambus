extends Node3D

const PADDING := 1.0

@onready var viewport: SubViewport = $SubViewport
@onready var camera: Camera3D = $SubViewport/Camera3D

func _ready() -> void:
	var root := "res://assets/models/items"
	var dir := DirAccess.open(root)
	var files := dir.get_files()
	for file in files:
		if not file.ends_with(".blend"):
			prints("Skipping", file)
			continue
		var scene := load(root.path_join(file)) as PackedScene
		var item := scene.instantiate() as Node3D
		add_child(item)
		item.rotate_x(PI / 4.0)
		fit_camera_to_target(item)
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		var dst := "res://assets/icons/items/".path_join(file.replace(".blend", ".png"))
		image.save_png(dst)
		prints("Saved to", dst)
		item.queue_free()

func fit_camera_to_target(target: Node3D):
	var aabb := AABB()

	for child in target.get_children():
		var vis := child as VisualInstance3D
		if vis and vis.visible:
			aabb = aabb.merge(vis.get_aabb())
			vis.get_aabb()

	aabb = target.global_transform * aabb

	# Calculate the distance from the camera to the target
	camera.size = (max(aabb.size.z, aabb.size.y) / 2.0) * (1 + PADDING)
	camera.position.y = aabb.get_center().y
	camera.position.z = aabb.get_center().z
