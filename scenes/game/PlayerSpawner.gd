extends Node
class_name PlayerSpawner

@export var player_scene: PackedScene
@onready var spawns := %PlayerSpawns

# network_id->[][]Inputs
var past_inputs: Dictionary = {}

# network_id->Player
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
	Log.info("Collecting past inputs")
	for id in avatars:
		var inputs: Array = past_inputs.get_or_add(id, [])
		var original: Player = avatars[id]
		var input := original.input.inputs.duplicate()
		input.reverse()
		inputs.push_back(input)
		Log.info("Pushed past input for player %d" % id)
	avatars.clear()
	for c in get_children():
		c.queue_free()

	Log.info("Spawning replays")
	var player_idx := 0
	for id in PackedInt32Array([multiplayer.get_unique_id()]) + multiplayer.get_peers():
		var inputs: Array = past_inputs.get(id, [])
		var points := spawns.get_child(player_idx)
		for round_idx in inputs.size():
			Log.info("Spawning replay %d for player %d" % [round_idx, player_idx])
			var pos := (points.get_child(round_idx) as Node3D).global_transform
			spawn_replay.rpc(id, pos.origin, round_idx)
		player_idx += 1

	Log.info("Spawning players")
	player_idx = 0
	for id in PackedInt32Array([multiplayer.get_unique_id()]) + multiplayer.get_peers():
		var points := spawns.get_child(player_idx)
		player_idx += 1
		var inputs: Array = past_inputs.get(id, [])
		var round_idx := inputs.size()
		if round_idx >= points.get_child_count():
			Log.info("Game over")
			return
		var pos := (points.get_child(round_idx) as Node3D).global_transform
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
func spawn_replay(id: int, pos: Vector3, round_idx: int):
	var player := player_scene.instantiate() as Player
	add_child(player)
	if multiplayer.is_server():
		var inputs: Array[PlayerInput.Inputs] = past_inputs[id][round_idx]
		player.input.inputs = inputs.duplicate()
		player.input.inputs.reverse()
		player.input.replay = true
	player.global_position = pos

	player.set_multiplayer_authority(1)
	print("Spawned replay %s at %s" % [player.name, multiplayer.get_unique_id()])
