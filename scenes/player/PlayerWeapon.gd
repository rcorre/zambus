extends NetworkWeaponHitscan3D
class_name NetworkHitScan

var damage := 35
var fire_cooldown: float = 0.25

@onready var input: PlayerInput = $"../../Input"

var last_fire: int = -1

func fire_range(hitscan_range: float) -> void:
	max_distance = hitscan_range
	fire()

func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == input.get_multiplayer_authority()

func _on_fire():
	prints("on fire")
	last_fire = NetworkTime.tick

func _on_hit(result: Dictionary):
	var pos := result.position as Vector3
	var zombie := result.collider as Zombie
	if zombie:
		zombie.damage(damage, global_transform.origin.direction_to(pos))
