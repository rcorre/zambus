extends Resource
class_name PlayerState

# Export all fields that must be duplicated
# We extend Resource just to get a builtin duplicate
@export var pos: Vector3
@export var vel: Vector3
@export var look: Vector2
@export var stance: int  # Stance
@export var health: int
@export var guard: int
@export var action_progress: float
@export var hits: PackedInt32Array # ID of each player/NPC hit by current attack
@export var weapon_main: int # Weapon.Kind
@export var weapon_off: int # Weapon.Kind

var status: Dictionary # Player.Status -> amount (int)

func _init(buf: StreamPeerBuffer = null):
	if not buf:
		for i in range(Player.Status.MAX):
			status[i] = 0
		return # default construct

	pos.x = buf.get_float()
	pos.y = buf.get_float()
	pos.z = buf.get_float()

	vel.x = buf.get_float()
	vel.y = buf.get_float()
	vel.z = buf.get_float()

	look.x = buf.get_float()
	look.y = buf.get_float()

	stance = buf.get_u16()
	health = buf.get_u8()
	guard = buf.get_8()

	action_progress = buf.get_float()

	var hit_count := buf.get_u8()
	hits.resize(hit_count)
	for i in range(hit_count):
		hits[i] = buf.get_u64()

	weapon_main = buf.get_u16()
	weapon_off = buf.get_u16()

	var status_count := buf.get_u8()
	for i in range(status_count):
		var key := buf.get_u8()
		status[key] = buf.get_u8()

func write(buf: StreamPeerBuffer):
	buf.put_float(pos.x)
	buf.put_float(pos.y)
	buf.put_float(pos.z)

	buf.put_float(vel.x)
	buf.put_float(vel.y)
	buf.put_float(vel.z)

	buf.put_float(look.x)
	buf.put_float(look.y)

	buf.put_u16(stance)
	buf.put_u8(health)
	buf.put_8(guard)

	buf.put_float(action_progress)

	assert(hits.size() < 256, "More than 255 hits")
	buf.put_u8(hits.size())
	for i in hits:
		buf.put_u64(i)

	buf.put_u16(weapon_main)
	buf.put_u16(weapon_off)

	assert(status.size() < 256, "More than 255 statuses")
	buf.put_u8(status.size())
	for k in status:
		buf.put_u8(k as int)
		buf.put_u8(status[k] as int)

func clone() -> PlayerState:
	# Always pass false, as causes an error for custom resources
	# https://github.com/godotengine/godot/issues/70570
	# This cannot be strongly typed
	var res := duplicate(false) as PlayerState
	res.status = status.duplicate()
	return res

# Visually interpolate between two states
# Only interpolates values relevant to visual display
func interpolate(to: PlayerState, factor: float) -> PlayerState:
	var state := clone()
	state.pos = lerp(state.pos, to.pos, factor)
	state.vel = lerp(state.vel, to.vel, factor)
	if to.action_progress > state.action_progress:
		state.action_progress = lerp(state.action_progress, to.action_progress, factor)
	else:
		state.action_progress = to.action_progress
	for key in status:
		state.status[key] = lerp(state.status[key], to.status[key], factor)
	return state

func _to_string() -> String:
	return "State(pos=%s,health=%2d,guard=%2d,prog=%1.2f,stance=%s,main=%d,off=%d,hits=%s)" % [pos, health, guard, action_progress, Stance.string(stance), weapon_main, weapon_off, hits]
