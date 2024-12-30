extends Node3D
class_name ItemSpawn

@export var kind: MeleeWeapon.Kind

func _ready() -> void:
	var item := MeleeWeapon.create(kind, MeleeWeapon.Mode.PICKUP)
	item.transform = transform
	add_child.call_deferred(item)

func set_item(item_kind: MeleeWeapon.Kind):
	if kind == item_kind:
		return

	for c in get_children():
		c.queue_free()
		Log.info("%s removed item %s" % [name, c])

	kind = item_kind
	var item := MeleeWeapon.create(kind, MeleeWeapon.Mode.PICKUP)
	item.transform = transform
	add_child(item)
	Log.info("%s added item %s" % [name, item])
