extends Node3D
class_name Item

enum ID {
	NONE,
	BAT,
	PISTOL,
}

@export var weight := 1.0

var icon: Texture2D

static func load(item_id: ID) -> Item:
	var key: String = ID.keys()[item_id]
	key = key.capitalize().replace(" ", "")
	var path := "res://scenes/items/%s.tscn" % key
	var scene := load(path) as PackedScene
	if not scene:
		push_error("Scene not found for item", item_id, path)
		return null
	var item := scene.instantiate() as Item
	item.icon = load_icon(item_id)
	return item

static func load_icon(item_id: int) -> Texture2D:
	var key: String = ID.keys()[item_id]
	key = key.capitalize().replace(" ", "")
	var path := "res://assets/icons/items/%s.png" % key
	var item_icon := load(path) as Texture2D
	if not item_icon:
		push_error("Icon not found for item", item_id, path)
		return null
	return item_icon
