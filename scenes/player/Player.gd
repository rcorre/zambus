extends CharacterBody3D
class_name Player

enum Status {
	FLINCH,
	MAX,
}

const JUMP_SPEED := 4.0
const CROUCH_SPEED_MULTIPLIER := 0.5
const BLOCK_SPEED_MULTIPLIER := 0.5
const ATTACK_SPEED_MULTIPLIER := 0.8
const SPRINT_SPEED_MULTIPLIER := 1.5
const BLOCK_SPEED := 6.0
const GRAVITY := 9.8
const ATTACK_SPEED := 1.0

@export var max_health := 15
@export var accel := 16.0
@export var walk_speed := 3.0
@export var dodge_speed := 6.0
@export var dodge_rate := 2.0
@export var attack_speed := 4.0
@export var base_guard := 0.0

@onready var model: PlayerModel = $Model
@onready var stand_collider: CollisionShape3D = $StandCollider
@onready var crouch_collider: CollisionShape3D = $CrouchCollider

@onready var stand_height := (stand_collider.shape as CapsuleShape3D).height
@onready var crouch_height := (crouch_collider.shape as CapsuleShape3D).height

@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var jump_sound: AudioStreamPlayer3D = $JumpSound
@onready var land_sound: AudioStreamPlayer3D = $LandSound
@onready var hit_sound: AudioStreamPlayer3D = $HitSound
@onready var block_sound: AudioStreamPlayer3D = $BlockSound
@onready var swing_sound: AudioStreamPlayer3D = $SwingSound

# set from Game, matches the unique_id of the peer it belongs to
var id: int
var is_local: bool

var look := Vector2.ZERO
var health := max_health
var stance := 0  # Stance
var action_progress := 0.0
var guard := 8
var status: Dictionary # Status.Kind -> amount

var step_time := 0.5

var weapon: MeleeWeapon
var offhand: MeleeWeapon

var last_state: PlayerState
var next_state: PlayerState

var last_state_frame: int
var next_state_frame: int
var state_interpolation: float

func _ready() -> void:
	if is_local:
		model.camera.make_current()

	equip(MeleeWeapon.Hand.MAIN, MeleeWeapon.Kind.CLUB)

func get_state() -> PlayerState:
	var ret := PlayerState.new()
	ret.pos = position
	ret.vel = velocity
	ret.look = look
	ret.health = health
	ret.guard = guard
	ret.stance = stance
	ret.action_progress = action_progress
	ret.weapon_main = weapon.kind if weapon else MeleeWeapon.Kind.NONE
	ret.weapon_off =  offhand.kind if offhand else MeleeWeapon.Kind.NONE
	ret.status = status.duplicate()
	if weapon:
		ret.hits = weapon.hits.duplicate()
	return ret

func set_state(state: PlayerState, delta := 0.0):
	velocity = state.vel
	position = state.pos
	look = state.look
	rotation.y = look.x
	health = state.health
	guard = state.guard
	stance = state.stance
	action_progress = state.action_progress
	collision_mask = (Global.CollisionLayer.PLAYER | Global.CollisionLayer.DEFAULT) if health > 0 else 0
	collision_layer = Global.CollisionLayer.PLAYER if health > 0 else 0
	status = state.status.duplicate()

	equip(MeleeWeapon.Hand.MAIN, state.weapon_main)
	equip(MeleeWeapon.Hand.OFF, state.weapon_off)

	weapon.hits = state.hits.duplicate()

	model.update_state(state, delta)

func queue_state(state: PlayerState, frame: int):
	if last_state and next_state:
		_process_state(last_state, next_state)
	last_state = next_state if next_state else state
	next_state = state

	last_state_frame = next_state_frame
	next_state_frame = frame

	state_interpolation = 0.0

	if last_state.health <= 0:
		model.die(is_local)

func step_physics(input: PlayerInput, is_server_step: bool, delta: float, frame: int):
	for i in get_shape_owners():
		shape_owner_set_disabled(i, health <= 0)

	if health <= 0:
		return

	for key in status:
		status[key] = max(0, status[key] - 1)

	rotation.y = look.x

	if not is_on_floor() or stance != Stance.STAND:
		# cannot change stance while falling
		# cannot change stance from anything other than STAND
		pass
	elif input.stance == Stance.DODGE:
		stance = Stance.DODGE
		# fix dodge direction to the current input direction
		# the length doesn't matter, the model just needs the direction
		var xz := input.move.normalized()
		velocity.x = xz.x
		velocity.z = xz.y
	elif input.stance == Stance.BLOCK:
		stance = Stance.BLOCK
	elif input.stance == Stance.ATTACK:
		stance = Stance.ATTACK
	elif input.stance == Stance.SPRINT:
		stance = Stance.SPRINT
	elif is_server_step and input.stance == Stance.INTERACT and model.interact():
		stance = Stance.INTERACT

	if stance == Stance.INTERACT:
		var last_progress := action_progress
		_advance_action(delta)
		if is_server_step and last_progress < 0.5 and action_progress >= 0.5:
			var w := model.interact()
			if w:
				var spawn := w.get_parent() as ItemSpawn
				assert(spawn, "Parent %s of %s is not ItemSpawn" % [w.get_parent(), w])
				var dropped := equip(w.hand, w.kind)
				spawn.set_item(dropped)

	stand_collider.disabled = stance == Stance.CROUCH
	crouch_collider.disabled = stance != Stance.CROUCH

	if stance == Stance.DODGE:
		# fix direction when starting dodge/attack
		var xy := ((
			input.move if action_progress == 0.0 else
			Vector2(velocity.x, velocity.z)
		).normalized() * dodge_speed).lerp(Vector2.ZERO, action_progress)

		velocity.x = xy.x
		velocity.z = xy.y
		velocity.y -= GRAVITY * delta
	else:
		var speed := walk_speed * (
			0.0 if stance == Stance.INTERACT
			else SPRINT_SPEED_MULTIPLIER if stance == Stance.SPRINT
			else CROUCH_SPEED_MULTIPLIER if (stance == Stance.CROUCH)
			else BLOCK_SPEED_MULTIPLIER if (stance == Stance.BLOCK)
			else ATTACK_SPEED_MULTIPLIER if (stance in [Stance.RECOIL, Stance.ATTACK])
			else 1.0
		)
		velocity.x = move_toward(velocity.x, input.move.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, input.move.y * speed, accel * delta)
		velocity.y -= GRAVITY * delta

	set_up_direction(Vector3.UP)
	move_and_slide()
	if can_look():
		look = input.look

	match stance:
		Stance.ATTACK: _advance_action(delta * weapon.attack_speed)
		Stance.RECOIL: _advance_action(-delta * weapon.attack_speed)
		Stance.DODGE: _advance_action(delta * dodge_rate)
		Stance.BLOCK:
			if input.stance == Stance.BLOCK:
				_advance_action(delta * BLOCK_SPEED)
			else:
				_advance_action(-delta * BLOCK_SPEED)

	var state := get_state()
	model.update_state(state, 0.0)

	# only detect hits in the last half of the attack, the first half is prep
	if stance == Stance.ATTACK:
		if action_progress < 0.5:
			weapon.hits.clear()
		elif action_progress > 0.5 and weapon.step():
			# attack was blocked
			stance = Stance.RECOIL
			weapon.show_sparks()

	if is_server_step and frame % 60 == 0:
		guard = min(guard + 1, max_guard())

# returns true if hit, false if blocked
func hurt(damage: int, _pos: Vector3) -> bool:
	status[Status.FLINCH] = 20
	if is_multiplayer_authority():
		# only the server can confirm damage
		health = max(0.0, health - damage)
	return true

func _process_state(prev: PlayerState, next: PlayerState):
	if next.health < prev.health:
		hit_sound.play()

	if next.stance == Stance.ATTACK and next.action_progress > 0.5 and prev.action_progress < 0.5:
		swing_sound.play()

	if next.stance != prev.stance:
		# entering new stance
		match next.stance:
			Stance.RECOIL:
				block_sound.play()
			Stance.DODGE:
				jump_sound.play()

func _process(delta: float) -> void:
	if stance != Stance.DODGE:
		step_time -= get_process_delta_time() * Vector2(velocity.x, velocity.z).length() / 4.0
		if step_time <= 0:
			step_time = 0.5
			step_sound.play()

	if is_local:
		model.update_state(get_state(), delta)
	elif last_state and next_state:
		var full_time := (next_state_frame - last_state_frame) * get_physics_process_delta_time()
		state_interpolation = min(1.0, state_interpolation + delta / full_time)
		set_state(last_state.interpolate(next_state, state_interpolation), delta)

func is_alive() -> bool:
	return collision_layer > 0

# returns the kind of the item replaced
func equip(hand: MeleeWeapon.Hand, kind: MeleeWeapon.Kind) -> MeleeWeapon.Kind:
	var current := weapon if hand == MeleeWeapon.Hand.MAIN else offhand
	var current_kind := current.kind if current else MeleeWeapon.Kind.NONE

	if kind == current_kind:
		# no change, already equipped
		return current_kind

	var ret := current_kind

	# PlayerModel.equip frees the prior items
	var phys := MeleeWeapon.create(kind, MeleeWeapon.Mode.PHYSICAL)
	model.equip(hand, phys)
	if hand == MeleeWeapon.Hand.MAIN:
		weapon = phys
	elif hand == MeleeWeapon.Hand.OFF:
		offhand = phys
	else:
		assert(false, "Cannot handle two handed weapons yet")

	for hitbox in model.hitboxes():
		phys.raycast.add_exception(hitbox as CollisionObject3D)

	return ret

func can_look() -> bool:
	return not stance == Stance.INTERACT

func _advance_action(amount: float) -> bool:
	action_progress = clamp(action_progress + amount, 0, 1)
	if stance != Stance.BLOCK and action_progress >= 1.0 or action_progress <= 0.0:
		action_progress = 0
		stance = Stance.STAND
		return true
	return false

func max_guard() -> int:
	return base_guard + max(
		weapon.guard if weapon else 0,
		offhand.guard if offhand else 0,
	)
