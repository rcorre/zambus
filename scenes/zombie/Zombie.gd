extends CharacterBody3D
class_name Zombie

const AGGRO_RANGE := 20.0

@export var speed := 0.85
@export var jump_strength := 5.0

@onready var model: ZombieModel = $ZombieModel
@onready var display_name := $DisplayNameLabel3D as Label3D
@onready var tick_interpolator := $TickInterpolator as TickInterpolator
@onready var state_synchronizer := $StateSynchronizer as StateSynchronizer
@onready var head := $Head as Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: int = 100
var respawn_position: Vector3

func _ready():
	NetworkTime.on_tick.connect(_on_tick)

	# Need to interpolate the whole transform (not individual rotations)
	# otherwise angle wrapping is not handled properly
	tick_interpolator.add_property(self, "transform")

	# For rollback, sync the minimum we need
	# position + y rotation, not the whole transform
	state_synchronizer.add_state(self, "position")
	state_synchronizer.add_state(self, "rotation:y")
	state_synchronizer.add_state(self, "velocity")

# returns null if no player in aggro range
func _nearest_player() -> Node3D:
	var min_dist := AGGRO_RANGE
	var target: Node3D = null
	for player in get_tree().get_nodes_in_group(Player.GROUP):
		var player3d := player as Node3D
		var dist := transform.origin.distance_to(player3d.transform.origin)
		if dist < min_dist:
			min_dist = dist
			target = player3d
	prints(target)
	return target

func _on_tick(delta: float, _tick: int):
	model.set_velocity(velocity)
	if health <= 0:
		die()

	# Gravity
	_force_update_is_on_floor()
	if !is_on_floor():
		velocity.y -= gravity * delta

	# TODO: update periodically instead of every frame
	var target := _nearest_player()
	if not target:
		velocity.z = 0
		move_and_slide()
		return

	# Handle look left and right
	var look_target := transform.looking_at(target.transform.origin)
	# TODO: interpolate speed
	transform = look_target

	# Zombies only walk in the direction they face
	velocity.x = -speed

	# move_and_slide assumes physics delta
	# multiplying velocity by NetworkTime.physics_factor compensates for it
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity

func damage():
	if is_multiplayer_authority():
		health -= 34
		prints("%s HP now at %s", [name, health])

func die():
	model.die()
