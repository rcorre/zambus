extends Game
class_name GameHost

var next_enemy_id := ENEMY_ID_BIT

var peer_frame := {}  # network_id(int)->frame_number(int)
var latest_peer_frame := {}  # network_id(int)->frame_number(int)
var latest_peer_input := {}  # network_id(int)->PackedByteArray

var past_state := RingBuffer.new(HISTORY_SIZE)  # past_input.at(n) == GameState at n frames in the past
var past_input := RingBuffer.new(HISTORY_SIZE)  # past_input.at(n) == {id -> PlayerInput}

func _ready() -> void:
	assert(is_multiplayer_authority())
	super._ready()
	var base_state := get_state(0)
	past_state.fill(base_state)
	past_input.fill({})
	add_player(multiplayer.get_unique_id())  # add ourself
	for id in multiplayer.get_peers():
		add_player(id)
	multiplayer.connect("peer_connected", Callable(self, "add_player"))
	multiplayer.connect("peer_disconnected", Callable(self, "remove_player"))

	if OS.is_debug_build() and "--no-enemies" in OS.get_cmdline_args():
		return

	for node in get_tree().get_nodes_in_group("enemy_spawn"):
		var s := node as Node3D
		next_enemy_id += 1
		var state := PlayerState.new()
		state.pos = s.position
		state.look.x = s.rotation.y
		state.health = 15
		spawn_player(next_enemy_id, state)

func add_player(id: int):
	Log.info("Adding player %d" % id)
	peer_frame[id] = 0
	latest_peer_frame[id] = 0
	respawn(id)

func remove_player(id: int):
	Log.info("Removing player %d" % id)
	peer_frame.erase(id)
	latest_peer_frame.erase(id)
	latest_peer_input.erase(id)
	var p: Node = players.get(id)
	if p:
		Log.info("Removing player character %d" % id)
		p.queue_free()
		players.erase(id)

func respawn(id: int):
	Log.info("%d requested respawn" % id)

	var spawns := get_tree().get_nodes_in_group("spawn")
	var best_spawn: Node3D = spawns[0]
	var best_spawn_score := 0.0
	for s in spawns:
		var score := 0.0
		for v in players.values():
			var p := v as Player
			var dist := p.global_position.distance_to((s as Node3D).global_position)
			score = max(score, dist)
		if score > best_spawn_score:
			best_spawn_score = score
			best_spawn = s

	# TODO: pick state based on unit type, e.g. load protobuf from JSON?
	var state := PlayerState.new()
	state.pos = best_spawn.position
	state.look.x = best_spawn.rotation.y
	state.health = 15

	spawn_player(id, state)

func _physics_process(delta: float) -> void:
	if local_frame % Global.SERVER_STEP == 0:
		update_input()
		server_step()
		var s := get_state(0).player_states
		for id in s:
			if id != multiplayer.get_unique_id():
				get_player(id as int).queue_state(s[id] as PlayerState, local_frame)

	local_frame += 1
	Global.current_frame = local_frame

	update_local_input()
	local_player().step_physics(local_input, false, delta, local_frame)

	var inputs := {multiplayer.get_unique_id(): local_input.duplicate()}

	var human_players: Array[Player] = []
	for id in players:
		if not (id & ENEMY_ID_BIT):
			human_players.push_back(players[id])

	for id in players:
		if id & ENEMY_ID_BIT:
			var enemy: NPC = players[id]
			var input := enemy.get_input(local_frame, human_players)
			inputs[id] = input

	# The host is always the first to process a frame
	# At first this frame will only have the host's inputs
	# As peers send input updates, we will fill their past inputs in
	past_input.push(inputs)
	past_state.push(get_state(local_frame))
	hud.update_state(local_player().get_state())

# data is a list of serialized inputs, newest to oldest
func update_input():
	for msg in Net.recv():
		var id := msg.peer
		if not id in latest_peer_frame:
			# player left
			continue
		var buf := StreamPeerBuffer.new()
		buf.data_array = msg.data.duplicate()
		var frame := PlayerInput.new(buf).frame

		if frame <= latest_peer_frame[id]:
			Log.info("Got old message for frame %d from %d" % [frame, id])
			return

		latest_peer_frame[id] = frame
		latest_peer_input[id] = msg.data

func process_inputs():
	for id in latest_peer_input:
		var frame: int = latest_peer_frame[id]
		var offset := local_frame - frame
		if offset > HISTORY_SIZE:
			# TODO: we could still apply inputs that are < HISTORY_SIZE
			return
		elif offset < 0:
			Log.warn("Negative offset %d for frame %d from %d" % [offset, frame, id])
			return

		var buf := StreamPeerBuffer.new()
		buf.data_array = latest_peer_input[id]
		while buf.get_available_bytes() > 0 and offset < HISTORY_SIZE:
			past_input.at(offset)[id] = PlayerInput.new(buf)
			offset += 1

func server_step():
	process_inputs()

	var oldest: int = peer_frame.values().min()
	if local_frame - oldest > HISTORY_SIZE - 2:
		oldest = local_frame - HISTORY_SIZE + 2

	# Rollback to prior state
	apply_state(past_state.at(local_frame - oldest) as GameState)

	# re-simulate to current time with player inputs
	for frame in range(oldest + 1, local_frame + 1):
		Global.current_frame = frame
		var offset := local_frame - frame
		for id in players:
			var player: Player = players[id]
			if id == get_multiplayer_authority() or (id & ENEMY_ID_BIT) or latest_peer_frame[id] >= frame:
				var input: PlayerInput = (past_input.at(offset) as Dictionary).get(id)
				if not input:
					continue
				peer_frame[id] = frame
				player.step_physics(input, true, get_physics_process_delta_time(), frame)
				if DEBUG_NETWORK and id != get_multiplayer_authority():
					print("Server|%d|%d|%s" % [frame, id, input])
		past_state.put(offset, get_state(frame))

	for id in players:
		if id != get_multiplayer_authority() and not (id & ENEMY_ID_BIT):
			var frame: int = peer_frame[id]
			var offset := local_frame - frame
			if offset >= HISTORY_SIZE:
				Log.info("Peer %d is %d frames behind, sending most recent state" % [id, offset])
				Net.send(id as int, build_state_packet(0))
			else:
				Net.send(id as int, build_state_packet(offset))

func get_state(frame: int) -> GameState:
	var state := GameState.new()

	state.frame = frame

	for pid in players:
		var p: Player = players[pid]
		state.player_states[pid] = p.get_state()

	state.items.resize(items.size())
	for i in items.size():
		state.items[i] = items[i].kind

	return state

func build_state_packet(offset: int) -> PackedByteArray:
	var state: GameState = past_state.at(offset)
	assert(state.frame == local_frame - offset)
	var buf := StreamPeerBuffer.new()
	state.write(buf)
	return buf.data_array
