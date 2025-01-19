extends CharacterBody3D
class_name Player

const GROUP := "player"

@export var speed := 5.0
@export var jump_strength := 5.0

@onready var model: PlayerModel = $ThirdPersonModel
@onready var display_name := $DisplayNameLabel3D as Label3D
@onready var input := $Input as PlayerInput
@onready var tick_interpolator := $TickInterpolator as TickInterpolator
@onready var rollback_synchronizer := $RollbackSynchronizer as RollbackSynchronizer
@onready var head := $Head as Node3D
@onready var weapon: Weapon = $Head/Weapon

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: int = 100
var death_tick: int = -1
var respawn_position: Vector3
var did_respawn := false
var deaths := 0
var is_local := false
var look_y := 0.0

func _enter_tree():
	add_to_group(GROUP)

func _ready():
	display_name.text = name

	NetworkTime.on_tick.connect(_tick)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)

	# Need to interpolate the whole transform (not individual rotations)
	# otherwise angle wrapping is not handled properly
	tick_interpolator.add_property(self, "transform")
	tick_interpolator.add_property(self, "look_y")

	# For rollback, sync the minimum we need
	# position + x/y rotation, not the whole transform
	rollback_synchronizer.add_state(self, "position")
	rollback_synchronizer.add_state(self, "rotation:y")
	rollback_synchronizer.add_state(self, "velocity")
	rollback_synchronizer.add_state(self, "did_respawn")
	rollback_synchronizer.add_state(self, "look_y")

	rollback_synchronizer.add_input(input, "movement")
	rollback_synchronizer.add_input(input, "jump")
	rollback_synchronizer.add_input(input, "attack")
	rollback_synchronizer.add_input(input, "look_angle")

	if is_local:
		model.camera.make_current()

func _tick(_dt: float, _tick_num: int):
	model.set_velocity(velocity)
	if input.attack:
		weapon.fire()
		model.attack()
	if health <= 0:
		deaths += 1
		die()

func _after_tick_loop():
	if did_respawn:
		tick_interpolator.teleport()

# TODO: setting look in both process and _rollback_tick may not be correct.
# I'm doing this to have both accurate aiming and a smooth camera.
# I may need a separate first-person model.
# I could also try interpolating the camera.
func _process(_delta: float) -> void:
	model.set_look_y(look_y)

func _rollback_tick(delta: float, tick: int, _is_fresh: bool) -> void:
	# Handle respawn
	if tick == death_tick:
		global_position = respawn_position
		did_respawn = true
	else:
		did_respawn = false

	# Gravity
	_force_update_is_on_floor()
	if is_on_floor():
		if input.jump:
			velocity.y = jump_strength
	else:
		velocity.y -= gravity * delta

	# Handle look left and right
	rotate_object_local(Vector3(0, 1, 0), input.look_angle.x)

	# Handle look up and down
	look_y = clamp(look_y + input.look_angle.y, -1.57, 1.57)
	model.set_look_y(look_y)

	# Apply movement
	var direction = (transform.basis * Vector3(input.movement.x, 0, input.movement.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

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
	model.die(is_local)

	if not is_multiplayer_authority():
		return

	prints("%s died", [name])
	# TODO: handle spawning in parent class
	@warning_ignore("unsafe_method_access")
	respawn_position = get_parent().get_next_spawn_point(get_player_id(), deaths)
	death_tick = NetworkTime.tick

	health = 100

func get_player_id() -> int:
	return input.get_multiplayer_authority()
