extends Node3D
class_name Item

enum ID {
	BAT,
	PISTOL,
}

@export var weight := 1.0

static func load(id: ID) -> Item:
	var key: String = ID.keys()[id]
	key = key.capitalize().replace(" ", "")
	var path := "res://scenes/weapons/%s.tscn" % key
	var scene := load(path) as PackedScene
	if not scene:
		push_error("Scene not found for item", id, path)
		return null
	return scene.instantiate() as Item
