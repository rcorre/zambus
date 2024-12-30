extends Node3D
class_name Game

# Godot network peer IDs are 31-bit integers
# We set the top bit to indicate that an ID indicates an enemy
const ENEMY_ID_BIT := 1 << 31

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/player/Enemy.tscn")
const MOUSE_SENSITIVITY := 0.001
const HISTORY_SIZE := 32

@onready var hud: HUD = $HUD

var DEBUG_NETWORK := OS.is_debug_build() and "--debug-network" in OS.get_cmdline_args()

var players := {}  # network_id(int)->Player

var local_frame := 0  # frame on this client
var local_input := PlayerInput.new()

var items: Array[ItemSpawn]

func _ready() -> void:
	for c in $Map/Items.get_children():  # added in Main.gd
		items.push_back(c as ItemSpawn)

func local_player() -> Player:
	return players.get(multiplayer.get_unique_id())

func get_player(id: int) -> Player:
	return players.get(id)

func spawn_player(id: int, state: PlayerState):
	Log.info("Spawning %d with state %s" % [id, state])
	assert(id not in players, "Player exists: %d" % id)

	var scene := ENEMY_SCENE if (id & ENEMY_ID_BIT) else PLAYER_SCENE
	var player: Player = scene.instantiate()
	players[id] = player
	player.name = "Player_%d" % id
	player.id = id
	player.is_local = id == multiplayer.get_unique_id()
	player.position = state.pos
	add_child(player)
	if player.weapon:
		state.weapon_main = player.weapon.kind
	if player.offhand:
		state.weapon_off = player.offhand.kind
	player.set_state(state)
	if player.is_local:
		local_input.look.x = player.rotation.y
		local_input.look.y = 0
		Log.info("Set look to %s" % local_input.look.x)
		hud.set_max_health(player.health)

func _handle_action(action: String, stance: int, toggle: bool) -> void:
	if local_input.stance == Stance.STAND and Input.is_action_just_pressed(action):
		local_input.stance = stance
	elif toggle and local_input.stance == stance and Input.is_action_just_pressed(action):
		local_input.stance = Stance.STAND
	elif (not toggle) and local_input.stance == stance and Input.is_action_just_released(action):
		local_input.stance = Stance.STAND

func update_local_input() -> void:
	if not is_local_alive():
		local_input.move = Vector2.ZERO
		local_input.look = Vector2.ZERO
		local_input.stance = Stance.STAND
		return

	local_input.move = Input.get_vector("right", "left", "back", "forward").rotated(-local_input.look.x)

	_handle_action("block", Stance.BLOCK, Settings.input_toggle_block.value)
	_handle_action("dodge", Stance.DODGE, false)
	_handle_action("attack", Stance.ATTACK, false)
	_handle_action("interact", Stance.INTERACT, false)

func apply_state(state: GameState):
	for id in state.player_states.keys():
		if (not (id & ENEMY_ID_BIT)) and is_multiplayer_authority() and id != get_multiplayer_authority() and not id in multiplayer.get_peers():
			# player left, but still exists in a past state
			continue
		var player: Player = players.get(id)
		var player_state: PlayerState = state.player_states[id]
		if player and player.is_local or is_multiplayer_authority():
			player.set_state(player_state)
		elif player:
			# for remote players, interpolate to the new state
			player.queue_state(player_state, state.frame)
		else:
			spawn_player(id as int, player_state)
	assert(state.items.size() == items.size(), "Expected %d items, got %d" % [items.size(), state.items.size()])
	for i in state.items.size():
		items[i].set_item(state.items[i])

func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseMotion
	if mouse and local_player() and local_player().can_look():
		local_input.look -= mouse.relative * Settings.input_sensitivity.value * MOUSE_SENSITIVITY
		local_input.look.x = wrapf(local_input.look.x, -PI, PI)
		local_input.look.y = clamp(local_input.look.y, -PI / 3.0, PI / 3.0)

func is_local_alive() -> bool:
	var p := local_player()
	return p and is_instance_valid(p) and p.is_alive()
