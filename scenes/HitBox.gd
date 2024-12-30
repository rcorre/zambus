extends Area3D
class_name HitBox

var player: Player

func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = Global.CollisionLayer.HITBOX
	var parent = self
	while player == null:
		parent = parent.get_parent()
		if not parent:
			Log.warn("HitBox has no player parent: %s" % get_path())
			queue_free()
			return
		player = parent as Player
		if player:
			return
