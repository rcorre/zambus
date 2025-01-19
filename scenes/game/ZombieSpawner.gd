extends Node

const ZOMBIE_SCENE := preload("res://scenes/zombie/Zombie.tscn")
@export var spawn_points: Node

var zombie_idx := 0
var zombies: Array[Zombie]

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
	spawn.rpc(zombie_idx, trans, Zombie.MAX_HEALTH)
	zombie_idx += 1

@rpc("authority", "call_local", "reliable")
func spawn(id: int, trans: Transform3D, health: int):
	var zombie := ZOMBIE_SCENE.instantiate() as Zombie
	zombies.push_back(zombie)
	zombie.id = id
	zombie.name = str(id)
	zombie.health = health
	add_child(zombie)
	zombie.transform = trans
	zombie.tree_exited.connect(remove_zombie.bind(zombie))
	print("Spawned zombie %s at %s" % [zombie.name, trans.origin])

func remove_zombie(zombie: Zombie):
	prints("Removing zombie", zombie)
	zombies.erase(zombie)

@rpc("any_peer", "reliable")
func join():
	assert(multiplayer.is_server())
	var player_id := multiplayer.get_remote_sender_id()
	prints("ZombieSpawner handling player join: ", player_id)
	for zombie in zombies:
		spawn.rpc_id(player_id, zombie.id, zombie.transform, zombie.health)

func get_next_spawn_point() -> Transform3D:
	var idx := randi_range(0, spawn_points.get_child_count() - 1)
	return (spawn_points.get_child(idx) as Node3D).transform
