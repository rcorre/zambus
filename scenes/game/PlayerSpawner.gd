extends Node
class_name PlayerSpawner

@export var player_scene: PackedScene
@onready var spawns := %PlayerSpawns

var avatars: Dictionary = {}

func _ready():
	if not multiplayer.is_server():
		return

	NetworkEvents.on_peer_leave.connect(_handle_leave)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_server_stop.connect(_handle_stop)

func _handle_leave(_id: int) -> void:
	# TODO
	return

func _handle_stop() -> void:
	# TODO
	return

func start_round() -> void:
	Log.info("Spawner starting round")
	var i := 0
	for id in PackedInt32Array([multiplayer.get_unique_id()]) + multiplayer.get_peers():
		var points := spawns.get_child(i)
		i += 1
		var pos := (points.get_child(0) as Node3D).global_transform
		prints(id, pos)
		spawn.rpc(id, pos.origin)

@rpc("authority", "call_local", "reliable")
func spawn(id: int, pos: Vector3):
	prints(id, pos)
	var player := player_scene.instantiate() as Player
	avatars[id] = player
	player.name += " #%d" % id
	player.is_local = id == multiplayer.get_unique_id()
	add_child(player as Node)
	player.global_position = pos

	# Avatar is always owned by server
	player.set_multiplayer_authority(1)

	print("Spawned player %s at %s" % [player.name, multiplayer.get_unique_id()])

	# Avatar's input object is owned by player
	var input = player.find_child("Input")
	if input != null:
		input.set_multiplayer_authority(id)
		print("Set input(%s) ownership to %s" % [input.name, id])

@rpc("authority", "call_local", "reliable")
func spawn_replay(id: int, pos: Vector3):
	var player := player_scene.instantiate() as Player
	var original: Player = avatars[id]
	add_child(player)
	player.input.inputs = original.input.inputs.duplicate()
	player.input.inputs.reverse()
	player.input.replay = true
	player.global_position = pos

	player.set_multiplayer_authority(1)
	print("Spawned replay %s at %s" % [player.name, multiplayer.get_unique_id()])
