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
	RELOAD,
	STOW,
	DRAW,
	INTERACT,
}

const ACCEL := 16.0
const CROUCH_SPEED := 2.0
const WALK_SPEED := 4.0
const SPRINT_SPEED := 6.0
const AIM_SPEED := 4.0
const ATTACK_SPEED := 8.0
const RELOAD_SPEED := 0.5

@onready var model: PlayerModel = $ThirdPersonModel
@onready var display_name := $DisplayNameLabel3D as Label3D
@onready var input := $Input as PlayerInput
@onready var tick_interpolator := $TickInterpolator as TickInterpolator
@onready var rollback_synchronizer := $RollbackSynchronizer as RollbackSynchronizer
@onready var hitscan: NetworkHitScan = model.camera.get_node("NetworkHitScan")

var inventory: Array[Item.ID]
var weapon: Weapon
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: int = 100
var death_tick: int = -1
var respawn_position: Vector3
var did_respawn := false
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

	NetworkTime.on_tick.connect(_tick)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)

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
	rollback_synchronizer.add_state(self, "did_respawn")
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
	rollback_synchronizer.add_input(input, "equip")

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

func equip_speed() -> float:
	return 1.0

func gun_drawn() -> bool:
	return weapon.is_gun() and action in [Action.AIM, Action.RECOIL]

func _tick(_delta: float, _tick_num: int):
	model.set_velocity(velocity, stance)

	if health <= 0:
		deaths += 1
		die()

func _after_tick_loop():
	if did_respawn:
		tick_interpolator.teleport()

func equip(idx: int) -> void:
	if input.equip >= inventory.size():
		push_warning("Equip request for item", input.equip, "out of range", inventory.size())
		return
	var item_id := inventory[idx]
	var item := Item.load(item_id) as Weapon
	if not item:
		push_warning("Cannot equip", item)
		return
	weapon = item
	action = Action.STOW

@rpc("authority", "call_local", "reliable")
func take_item(item: Item.ID) -> void:
	inventory.push_back(item)

# TODO: setting look in both process and _rollback_tick may not be correct.
# I'm doing this to have both accurate aiming and a smooth camera.
# I may need a separate first-person model.
# I could also try interpolating the camera.
func _process(_delta: float) -> void:
	model.set_look_y(look_y)
	model.set_action(action, action_progress)

	# Highlight focused item for the local player if not performing any action
	if is_local and action == Action.NONE:
		var col := model.interact_ray.get_collider() as Pickup
		if col:
			col.focused = true

func _rollback_tick(delta: float, tick: int, _is_fresh: bool) -> void:
	# Handle respawn
	if tick == death_tick:
		global_position = respawn_position
		did_respawn = true
	else:
		did_respawn = false

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

	# TODO: should go in tick instead?
	if input.equip >= 0:
		equip(input.equip)

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

	if input.action == Action.INTERACT:
		if multiplayer.is_server():
			model.interact_ray.force_raycast_update()
			var col := model.interact_ray.get_collider() as Pickup
			if col:
				col.take.rpc()
				take_item.rpc(col.item_id)
	elif action == Action.STOW:
		action_progress += equip_speed() * delta
		if action_progress >= 1.0:
			action_progress = 0.0
			tick_interpolator.teleport()
			action = Action.DRAW
			model.equip(weapon)
	elif action == Action.DRAW:
		action_progress += equip_speed() * delta
		if action_progress >= 1.0:
			action_progress = 0.0
			tick_interpolator.teleport()
			action = Action.NONE
	elif stance != Stance.SPRINT:
		var last_action := action
		match weapon.kind:
			Weapon.Kind.MELEE_1H, Weapon.Kind.MELEE_2H:
				handle_melee_action(delta)
			Weapon.Kind.PISTOL:
				handle_gun_action(delta)
		if action != last_action:
			# we started a new action, so reset interpolation
			tick_interpolator.teleport()

func handle_melee_action(delta: float):
	if action == Action.NONE:
		if input.action == Action.ATTACK and stamina > weapon.stamina_cost:
			action = Action.AIM
			action_progress = 0.0
	elif action_progress >= 1.0:
		match action:
			Action.AIM:
				# Hold the attack "charged" until the attack button is released
				if input.action != Action.ATTACK:
					if stamina > weapon.stamina_cost:
						action = Action.ATTACK
						action_progress = 0.0
						stamina -= weapon.stamina_cost
					else:
						action = Action.RECOIL
						action_progress = 0.0
			Action.ATTACK:
				hitscan.hitscan(weapon.hitscan_range, 0.0)
				action = Action.RECOIL
				action_progress = 0.0
			Action.RECOIL:
				action = Action.NONE
				action_progress = 0.0
	else:
		match action:
			Action.AIM:
				action_progress += delta * AIM_SPEED
			Action.ATTACK:
				action_progress += delta * ATTACK_SPEED
			Action.RECOIL:
				action_progress += delta * ATTACK_SPEED

func handle_gun_action(delta: float):
	if action == Action.NONE:
		if input.action == Action.AIM:
			action = Action.AIM
			spread = weapon.max_spread
		elif input.action == Action.RELOAD:
			action = Action.RELOAD
	elif action == Action.AIM:
		if input.action == Action.ATTACK:
			if ammo > 0:
				ammo -= 1
				hitscan.hitscan(weapon.hitscan_range, gun_spread_degrees())
				spread += weapon.recoil
				action = Action.RECOIL
				action_progress = 0.0
			else:
				action = Action.RELOAD
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
	elif action == Action.RELOAD:
		action_progress += delta * RELOAD_SPEED
		if action_progress >= 1.0:
			ammo = weapon.mag_size
			action = Action.NONE
			action_progress = 0.0

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
