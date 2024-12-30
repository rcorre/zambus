extends Node

const _ERROR_MSG = {
	ERR_ALREADY_IN_USE : "Already in use",
	ERR_CANT_CREATE    : "Can't create",
}

const MAX_PLAYERS := 2

func _ready() -> void:
	# poll from physics loop so we can move kinematic bodies from RPCs
	get_tree().multiplayer_poll = false

func _physics_process(_delta: float) -> void:
	multiplayer.poll()

func _fail(err: int):
	var msg: String = _ERROR_MSG.get(err, "Unknown error %d" % err)
	Log.error(msg)

func _on_disconnect():
	Log.warn("Disconnected")
	multiplayer.call_deferred("set_multiplayer_peer", null)

func _on_peer_disconnect(_id: int):
	_on_disconnect()

func host(port: int):
	# if Steam.isSteamRunning():
	# 	Log.info("Looking for match on Steam")
	# 	var lobby_id: int = await SteamAPI.find_or_create_lobby("RRC test lobby")
	# 	Log.info("Using lobby ID %d" % lobby_id)
	# 	var peer := SteamMultiplayerPeer.new()
	# 	peer.join_lobby(lobby_id)
	# 	Log.info("Joined lobby %d" % lobby_id)
	# 	multiplayer.multiplayer_peer = peer
	# else:
	Log.info("Hosting on :%d" % port)
	var peer := ENetMultiplayerPeer.new()
	peer.connect("peer_disconnected", _on_peer_disconnect)
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		_fail(err)
		return
	multiplayer.multiplayer_peer = peer

func join(address: String, port: int):
	# if Steam.isSteamRunning():
	# 	Log.info("Joining steam lobby")
	# 	var lobby_id: int = await SteamAPI.find_or_create_lobby("RRC test lobby")
	# 	var peer := SteamMultiplayerPeer.new()
	# 	peer.join_lobby(lobby_id)
	# 	multiplayer.multiplayer_peer = peer
	# else:
	Log.info("Joining %s:%d" % [address, port])
	var peer := ENetMultiplayerPeer.new()
	multiplayer.connect("server_disconnected", _on_disconnect)
	multiplayer.connect("connection_failed", _on_disconnect)
	var err := peer.create_client(address, port)
	if err:
		_fail(err)
		return
	multiplayer.multiplayer_peer = peer

func quit():
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

class Message:
	var peer: int
	var data: PackedByteArray

var messages: Array[Message]

func recv() -> Array[Message]:
	var res := messages.duplicate()
	messages.clear()
	return res

func send(id: int, data: PackedByteArray):
	rpc_id(id, "_send", data)

@rpc("any_peer", "unreliable") func _send(data: PackedByteArray):
	var msg := Message.new()
	msg.peer = multiplayer.get_remote_sender_id()
	msg.data = data
	messages.push_back(msg)
