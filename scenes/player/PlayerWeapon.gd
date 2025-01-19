extends NetworkWeaponHitscan3D
class_name Weapon

var damage := 35
var fire_cooldown: float = 0.25
var attack_range := 2.0

@onready var input: PlayerInput = $"../../Input"
@onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

var last_fire: int = -1

func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == input.get_multiplayer_authority()

func _on_fire():
	sound.play()

func _after_fire():
	last_fire = NetworkTime.tick

func _on_hit(result: Dictionary):
	var pos := result.position as Vector3
	if global_transform.origin.distance_to(pos) > attack_range:
		return
	var zombie := result.collider as Zombie
	if zombie:
		zombie.damage(damage, global_transform.origin.direction_to(pos))
