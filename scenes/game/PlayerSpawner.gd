extends Node

@export var player_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []

var avatars: Dictionary = {}

func _ready():
	if not multiplayer.is_server():
		return

	NetworkEvents.on_peer_join.connect(_handle_new_peer)
	NetworkEvents.on_peer_leave.connect(_handle_leave)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_server_stop.connect(_handle_stop)

	server_spawn(multiplayer.get_unique_id())

func _handle_new_peer(id: int):
	for key in avatars.keys():
		prints("Telling new player", id, "about player", key)
		var avatar := avatars[key] as Node3D
		spawn.rpc_id(id, key, avatar.position)
	server_spawn(id)

func _handle_leave(id: int):
	if not avatars.has(id):
		return

	var avatar = avatars[id] as Node
	avatar.queue_free()
	avatars.erase(id)

func _handle_stop():
	# Remove all avatars on game end
	for avatar in avatars.values():
		(avatar as Node).queue_free()
	avatars.clear()

func server_spawn(id: int):
	prints("Spawning player", id)
	var pos := get_next_spawn_point(id)
	spawn.rpc(id, pos)

@rpc("authority", "call_local")
func spawn(id: int, pos: Vector3):
	var player = player_scene.instantiate() as Player
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

func get_next_spawn_point(peer_id: int, spawn_idx: int = 0) -> Vector3:
	var idx := peer_id * 37 + spawn_idx * 19
	idx = hash(idx)
	idx = idx % spawn_points.size()

	return spawn_points[idx].position
