extends Game
class_name GamePeer

var last_server_frame := 0  # last frame received from server
var past_input := RingBuffer.new(HISTORY_SIZE)  # past_input.at(n) == PlayerInput at n frames in the past

func _ready() -> void:
	assert(not is_multiplayer_authority())
	super._ready()
	var no_input := PlayerInput.new()
	past_input.fill(no_input)

func _physics_process(delta: float) -> void:
	update_state()
	local_frame += 1
	Global.current_frame = local_frame
	local_input.frame = local_frame

	if is_local_alive():
		update_local_input()
		local_player().step_physics(local_input, false, delta, local_frame)
		hud.update_state(local_player().get_state())

	past_input.push(local_input.duplicate())

	# we incremented local_frame above, so offset is at least 1
	var offset := local_frame - last_server_frame
	if offset > HISTORY_SIZE:
		# Log.warn("Last server update is %d frames old" % offset)
		offset = HISTORY_SIZE

	var buf := StreamPeerBuffer.new()

	# Encode inputs from newest to oldest
	for i in range(offset):
		(past_input.at(i) as PlayerInput).write(buf)

	Net.send(get_multiplayer_authority(), buf.data_array)

	if DEBUG_NETWORK:
		print("Client|%d|%d|%s" % [local_frame, multiplayer.get_unique_id(), local_input])

# Receive a past state from the server, and reconcile to the current time by
# re-applying past inputs
func update_state():
	# TODO: take only most recent
	for msg in Net.recv():
		var buf := StreamPeerBuffer.new()
		buf.data_array = msg.data.duplicate()
		var state := GameState.new(buf)
		if state.frame < last_server_frame:
			return  # old packet

		last_server_frame = state.frame
		apply_state(state)

		var offset := local_frame - state.frame

		if offset > HISTORY_SIZE:
			Log.warn("State update %d is %d frames behind" % [state.frame, offset])
			offset = HISTORY_SIZE

		if offset < 0:
			# we fell too far behind, so the server sent the latest state
			# advance our state without reconciliation
			Log.info("Advancing frame to %d without prediction" % [state.frame])
			local_frame = state.frame
			var empty := PlayerInput.new()
			past_input.fill(empty)
			return

		hud.update_latency(get_physics_process_delta_time() * offset)

		if not local_player():
			return

		# re-simulate to current time
		for i in range(offset - 1, -1, -1):
			local_player().step_physics(past_input.at(i) as PlayerInput, false, get_physics_process_delta_time(), local_frame - i)
