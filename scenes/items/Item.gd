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
	var path := "res://scenes/items/%s.tscn" % key
	var scene := load(path) as PackedScene
	if not scene:
		push_error("Scene not found for item", id, path)
		return null
	return scene.instantiate() as Item

static func load_icon(id: ID) -> Texture2D:
	var key: String = ID.keys()[id]
	key = key.capitalize().replace(" ", "")
	var path := "res://assets/icons/items/%s.tscn" % key
	var icon := load(path) as Texture2D
	if not icon:
		push_error("Icon not found for item", id, path)
		return null
	return icon
