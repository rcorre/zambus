extends Node
class_name PlayerSpawner

const ROUND_COUNT := 4

@export var player_scene: PackedScene

# network_id->[][]Inputs
var past_inputs: Dictionary = {}

# network_id->Player
var avatars: Dictionary = {}

# network_id->Array[Transform3D]
var spawn_points: Dictionary = {}

var current_round := 0

func _ready():
	var all_spawns := %PlayerSpawns.get_children()
	var ids := PackedInt32Array([multiplayer.get_unique_id()]) + multiplayer.get_peers()
	if ids.size() > all_spawns.size():
		push_error("%d spawns is not enough for %d players" % [all_spawns.size(), ids.size()])
	for id in ids:
		var spawns: Node3D = all_spawns.pop_front()
		var points: Array[Transform3D]
		for s in spawns.get_children():
			points.push_back((s as Node3D).global_transform)
		spawn_points[id] = points

	if multiplayer.is_server():
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
	if current_round == ROUND_COUNT:
		Log.info("Game over")
		return

	Log.info("Collecting past inputs")
	for id in avatars:
		var inputs: Array = past_inputs.get_or_add(id, [])
		var original: Player = avatars[id]
		var input := original.input.inputs.duplicate()
		input.reverse()
		inputs.push_back(input)
		Log.info("Pushed past input for player %d" % id)

	clear_players.rpc()

	# Let all the freed players be removed
	await get_tree().physics_frame

	Log.info("Spawning replays")
	for id in PackedInt32Array([multiplayer.get_unique_id()]) + multiplayer.get_peers():
		for round_idx in range(current_round):
			Log.info("Spawning replay %d for player %d" % [round_idx, id])
			spawn_replay.rpc(id, round_idx)

	Log.info("Spawning players")
	for id in PackedInt32Array([multiplayer.get_unique_id()]) + multiplayer.get_peers():
		spawn.rpc(id, current_round)

	current_round += 1

func get_spawn_point(id: int, round_idx: int) -> Transform3D:
	return spawn_points[id][round_idx]

@rpc("authority", "call_local", "reliable")
func clear_players():
	avatars.clear()
	for c in get_children():
		c.queue_free()

@rpc("authority", "call_local", "reliable")
func spawn(id: int, round_idx: int):
	var player := player_scene.instantiate() as Player
	avatars[id] = player
	player.name = "Player%d.%d" % [id, round_idx]
	player.is_local = id == multiplayer.get_unique_id()
	assert(!has_node(NodePath(player.name)))
	add_child(player as Node)
	player.global_transform = get_spawn_point(id, round_idx)

	# Avatar is always owned by server
	player.set_multiplayer_authority(1)

	print("Spawned player %s at %s" % [player.name, multiplayer.get_unique_id()])

	# Avatar's input object is owned by player
	var input = player.find_child("Input")
	if input != null:
		input.set_multiplayer_authority(id)
		print("Set input(%s) ownership to %s" % [input.name, id])

@rpc("authority", "call_local", "reliable")
func spawn_replay(id: int, round_idx: int):
	var player := player_scene.instantiate() as Player
	player.name = "Replay%d.%d" % [id, round_idx]
	assert(!has_node(NodePath(player.name)))
	add_child(player)
	if multiplayer.is_server():
		var inputs: Array[PlayerInput.Inputs] = past_inputs[id][round_idx]
		player.input.inputs = inputs.duplicate()
		player.input.inputs.reverse()
		player.input.replay = true
	player.global_transform = get_spawn_point(id, round_idx)

	player.set_multiplayer_authority(1)
	print("Spawned replay %s at %s" % [player.name, multiplayer.get_unique_id()])
