extends Area3D
class_name MeleeWeapon

enum Mode {
	PICKUP, # laying on the ground, can be picked up
	PHYSICAL, # not visible, used for physics
	VISUAL, # visible, no real physics interaction
}

enum Hand {
	MAIN,
	OFF,
	BOTH,
}

enum Kind {
	NONE,
	CLUB,
	SWORD,
	AXE,
	SHIELD,
}

const _items := {
	Kind.NONE: preload("res://scenes/weapons/NoItem.tscn"),
	Kind.CLUB: preload("res://scenes/weapons/Club.tscn"),
	Kind.SWORD: preload("res://scenes/weapons/BroadSword.tscn"),
	Kind.AXE: preload("res://scenes/weapons/BattleAxe.tscn"),
	Kind.SHIELD: preload("res://scenes/weapons/RoundShield.tscn"),
}

const GROUP := "item"

@export var hand: Hand
@export var damage := 5
@export var attack_speed := 1.0
@export var guard := 4

@onready var raycast: RayCast3D = $RayCast3D

var kind: MeleeWeapon.Kind

# Player IDs hit by the current swing
var hits: PackedInt32Array
var last_hit_pos: Vector3

var reach: float:
	get: return raycast.target_position.length()

func _ready() -> void:
	raycast.enabled = false
	raycast.collide_with_areas = true

# returns true if deflected
func step() -> bool:
	raycast.force_raycast_update()

	var col := raycast.get_collider()
	var hitbox := col as HitBox

	if hitbox and not (hitbox.player.id in hits):
		# first contact with a player, do damage
		hits.push_back(hitbox.player.id)
		hitbox.player.hurt(damage, raycast.get_collision_point())
		return false
	elif hitbox:
		# continuing contact with player
		return false

	# return true (deflected) if it hit a non-player (shield/terrain)
	return col != null

func hit_pos() -> Vector3:
	return raycast.get_collision_point()

func show_sparks() -> void:
	if has_node("HitParticles"):
		var particles: GPUParticles3D = $HitParticles
		particles.emitting = true

func _to_string() -> String:
	return "%s" % name

static func create(item_kind: Kind, mode: Mode) -> MeleeWeapon:
	var scene: PackedScene = _items.get(item_kind)
	if not scene:
		push_error("Unknown weapon kind %d" % item_kind)
		return null
	var ret: MeleeWeapon = scene.instantiate()
	ret.kind = item_kind

	ret.set_process(mode == Mode.VISUAL)
	# onready raycast not available yet
	var ray := ret.get_node("RayCast3D") as RayCast3D
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.hit_from_inside = false
	match mode:
		Mode.VISUAL:
			ret.collision_layer = 0
			ray.collision_mask = Global.CollisionLayer.GUARD
			ray.hit_from_inside = true
		Mode.PHYSICAL:
			ray.collision_mask = Global.CollisionLayer.DEFAULT | Global.CollisionLayer.HITBOX | Global.CollisionLayer.WEAPON
			ret.collision_layer = Global.CollisionLayer.WEAPON
		Mode.PICKUP:
			ret.collision_layer = Global.CollisionLayer.INTERACT
		_:
			ray.collision_mask = 0
	return ret

func add_exception(body: CollisionObject3D) -> void:
	# onready raycast not available yet
	var ray := get_node("RayCast3D") as RayCast3D
	ray.add_exception(body)
