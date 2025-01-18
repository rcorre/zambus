extends Node

const ZOMBIE_SCENE := preload("res://scenes/zombie/Zombie.tscn")
@export var spawn_points: Node

var zombie_idx := 0
var zombies: Array[Node3D]

func _ready():
	if multiplayer.is_server():
		NetworkTime.on_tick.connect(self._on_tick)
	else:
		join.rpc_id(1)

func _on_tick(_delta, tick):
	var interval := NetworkTime.seconds_to_ticks(5.0)
	if tick % interval != 0:
		return
	var trans := get_next_spawn_point()
	spawn.rpc(zombie_idx, trans)
	zombie_idx += 1

@rpc("authority", "call_local")
func spawn(id: int, trans: Transform3D):
	var zombie = ZOMBIE_SCENE.instantiate() as Node3D
	zombies.push_back(zombie)
	zombie.name = str(id)
	add_child(zombie as Node)
	zombie.transform = trans
	print("Spawned zombie %s at %s" % [zombie.name, multiplayer.get_unique_id()])

@rpc("any_peer")
func join():
	assert(multiplayer.is_server())
	var player_id := multiplayer.get_remote_sender_id()
	prints("ZombieSpawner handling player join: ", player_id)
	for zombie in zombies:
		var zombie_id := zombie.name.to_int()
		spawn.rpc_id(player_id, zombie_id, zombie.transform)

func get_next_spawn_point() -> Transform3D:
	var idx := randi_range(0, spawn_points.get_child_count() - 1)
	return (spawn_points.get_child(idx) as Node3D).transform
