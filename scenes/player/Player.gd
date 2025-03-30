extends CharacterBody3D
class_name Player

const GROUP := "player"

enum Stance {
	STAND,
	CROUCH,
	SPRINT,
}

enum Action {
	NONE,
	AIM,
	ATTACK,
	RECOIL,
}

const ACCEL := 16.0
const CROUCH_SPEED := 2.0
const WALK_SPEED := 4.0
const SPRINT_SPEED := 6.0
const AIM_SPEED := 4.0
const ATTACK_SPEED := 8.0

@onready var model: PlayerModel = $ThirdPersonModel
@onready var display_name := $DisplayNameLabel3D as Label3D
@onready var input := $Input as PlayerInput
@onready var tick_interpolator := $TickInterpolator as TickInterpolator
@onready var rollback_synchronizer := $RollbackSynchronizer as RollbackSynchronizer
@onready var hitscan: NetworkHitScan = model.camera.get_node("NetworkHitScan")

var weapon: Weapon
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: int = 100
var respawn_position: Vector3
var deaths := 0
var is_local := false

# Rollback properties
var look_y := 0.0
var stance: Stance
var action: Action
var action_progress := 0.0
var stamina := 100.0
var ammo := 0
var spread := 0.0

func _enter_tree():
	add_to_group(GROUP)

func _ready():
	display_name.text = name

	NetworkTime.on_tick.connect(_on_tick)

	# Need to interpolate the whole transform (not individual rotations)
	# otherwise angle wrapping is not handled properly
	tick_interpolator.add_property(self, "transform")
	tick_interpolator.add_property(self, "look_y")
	tick_interpolator.add_property(self, "action_progress")
	tick_interpolator.add_property(self, "stamina")
	rollback_synchronizer.add_state(self, "spread")

	# For rollback, sync the minimum we need
	# position + x/y rotation, not the whole transform
	rollback_synchronizer.add_state(self, "position")
	rollback_synchronizer.add_state(self, "rotation:y")
	rollback_synchronizer.add_state(self, "velocity")
	rollback_synchronizer.add_state(self, "look_y")
	rollback_synchronizer.add_state(self, "stance")
	rollback_synchronizer.add_state(self, "action")
	rollback_synchronizer.add_state(self, "action_progress")
	rollback_synchronizer.add_state(self, "stamina")
	rollback_synchronizer.add_state(self, "ammo")
	rollback_synchronizer.add_state(self, "spread")

	rollback_synchronizer.add_input(input, "look_angle")
	rollback_synchronizer.add_input(input, "movement")
	rollback_synchronizer.add_input(input, "action")
	rollback_synchronizer.add_input(input, "stance")

	weapon = preload("res://scenes/items/Pistol.tscn").instantiate()
	model.equip(weapon)
	if is_local:
		model.camera.make_current()
		Global.local_player_spawned.emit(self)

# Number of degrees bullets will spread from center
func gun_spread_degrees() -> float:
	return spread + velocity.length() * weapon.move_spread / WALK_SPEED

func stamina_regen() -> float:
	return 10.0

func stamina_cost_sprint() -> float:
	return 15.0

func max_stamina() -> float:
	return 100.0

func recoil_recovery() -> float:
	return 4.0

func aim_speed() -> float:
	return 8.0

func gun_drawn() -> bool:
	return weapon.is_gun() and action in [Action.AIM, Action.RECOIL]

func _on_tick(_delta: float, _tick_num: int):
	model.set_velocity(velocity, stance)

	if health <= 0:
		deaths += 1
		die()

# TODO: setting look in both process and _rollback_tick may not be correct.
# I'm doing this to have both accurate aiming and a smooth camera.
# I may need a separate first-person model.
# I could also try interpolating the camera.
func _process(_delta: float) -> void:
	model.set_look_y(look_y)
	model.set_action(action, action_progress)

func _rollback_tick(delta: float, _tick: int, _is_fresh: bool) -> void:
	spread = clampf(spread - aim_speed() * delta, weapon.min_spread, weapon.max_spread)

	# Gravity
	_force_update_is_on_floor()
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle look left and right
	rotate_object_local(Vector3(0, 1, 0), input.look_angle.x)

	# Handle look up and down
	look_y = clamp(look_y + input.look_angle.y, -1.57, 1.57)
	model.set_look_y(look_y)

	match input.stance:
		Stance.STAND:
			stance = Stance.STAND
		Stance.CROUCH:
			stance = Stance.CROUCH
		Stance.SPRINT:
			if stamina >= 10.0:
				stance = Stance.SPRINT

	var speed := WALK_SPEED
	match stance:
		Stance.SPRINT:
			speed = SPRINT_SPEED
		Stance.CROUCH:
			speed = CROUCH_SPEED
	match action:
		Action.AIM, Action.ATTACK, Action.RECOIL:
			speed /= 2

	var input_dir := Vector3(input.movement.x, 0, input.movement.y)
	if stance == Stance.SPRINT:
		action = Action.NONE
		input_dir = Vector3.FORWARD
		stamina -= stamina_cost_sprint() * delta
		if stamina <= 0.0:
			stance = Stance.STAND
	else:
		stamina += stamina_regen() * delta

	stamina = clampf(stamina, 0, max_stamina())

	var move_target := (transform.basis * input_dir).normalized() * speed

	velocity.x = move_toward(velocity.x, move_target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, move_target.z, ACCEL * delta)

	# move_and_slide assumes physics delta
	# multiplying velocity by NetworkTime.physics_factor compensates for it
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

	if stance != Stance.SPRINT:
		var last_action := action
		match weapon.kind:
			Weapon.Kind.NONE:
				pass
			Weapon.Kind.PISTOL:
				handle_gun_action(delta)
		if action != last_action:
			# we started a new action, so reset interpolation
			tick_interpolator.teleport()

func handle_gun_action(delta: float):
	if action == Action.NONE:
		if input.action == Action.AIM:
			action = Action.AIM
			spread = weapon.max_spread
	elif action == Action.AIM:
		if input.action == Action.ATTACK:
			hitscan.hitscan(weapon.hitscan_range, gun_spread_degrees())
			spread += weapon.recoil
			action = Action.RECOIL
			action_progress = 0.0
		elif input.action == Action.AIM:
			action_progress = move_toward(action_progress, 1.0, delta * AIM_SPEED)
		else:
			action_progress = move_toward(action_progress, 0.0, delta * AIM_SPEED)
			if action_progress <= 0.0:
				action = Action.NONE
	elif action == Action.RECOIL:
		action_progress += delta * AIM_SPEED
		if action_progress >= 1.0:
			action = Action.AIM

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity

func damage(amount: int, _impact: Vector3):
	if is_multiplayer_authority() and health > 0:
		health -= amount
		if health <= 0:
			get_tree().create_timer(5.0).timeout.connect(queue_free)

func die():
	model.die(is_local)
	collision_layer = 0
	collision_mask = 0

	if not is_multiplayer_authority():
		return

	prints("%s died", [name])

func get_player_id() -> int:
	return input.get_multiplayer_authority()
