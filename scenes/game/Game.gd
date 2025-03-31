extends Node

const ROUND_DURATION_SECS = 3.0

@onready var players: PlayerSpawner = $Players

var ready_peers: PackedInt32Array

var round_time_left: float

func _ready() -> void:
	Log.info("ready")
	set_process_unhandled_key_input(OS.is_debug_build())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	report_ready.rpc_id(1)
	NetworkTime.on_tick.connect(_on_tick)

func _on_tick(delta: float, _tick: int) -> void:
	if round_time_left <= 0:
		return
	round_time_left = move_toward(round_time_left, 0, delta)
	if multiplayer.is_server() and round_time_left <= 0:
		start_round()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.keycode == KEY_ESCAPE:
		get_tree().quit()

func start_round() -> void:
	players.start_round()
	round_time_left = ROUND_DURATION_SECS

@rpc("any_peer", "call_local", "reliable")
func report_ready() -> void:
	var id := multiplayer.get_remote_sender_id()
	Log.info("%d is ready" % id)
	if not ready_peers.count(id):
		ready_peers.push_back(id)
	if ready_peers.size() == multiplayer.get_peers().size() + 1:
		start_round()
