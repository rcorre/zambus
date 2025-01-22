extends NetworkWeaponHitscan3D
class_name NetworkHitScan

@onready var input: PlayerInput = $"../../Input"

var damage := 35
var fire_cooldown: float = 0.25
var last_fire: int = -1
var rng: RandomNumberGenerator

func _ready() -> void:
	if multiplayer.is_server():
		set_seed.rpc(randi())
	else:
		request_seed.rpc_id(1)

@rpc("any_peer")
func request_seed() -> void:
	assert(multiplayer.is_server())
	set_seed.rpc_id(multiplayer.get_remote_sender_id(), rng.seed)

@rpc("authority", "call_local")
func set_seed(s: int) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = s

func hitscan(hitscan_range: float, spread_degrees: float) -> void:
	var spread := deg_to_rad(spread_degrees)
	rotate_x(rng.randf_range(-spread, spread))
	rotate_z(rng.randf_range(0, TAU))
	max_distance = hitscan_range
	fire()
	rotation = Vector3.ZERO

func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == input.get_multiplayer_authority()

func _on_fire():
	last_fire = NetworkTime.tick

func _on_hit(result: Dictionary):
	var pos := result.position as Vector3
	var zombie := result.collider as Zombie
	if zombie:
		zombie.damage(damage, (damage / 50.0) * global_transform.origin.direction_to(pos))
