extends Node

const _ERROR_MSG = {
	ERR_ALREADY_IN_USE : "Already in use",
	ERR_CANT_CREATE    : "Can't create",
}

const MAX_PLAYERS := 4

func _fail(err: int):
	var msg: String = _ERROR_MSG.get(err, "Unknown error %d" % err)
	Log.error(msg)

func _on_disconnect():
	Log.warn("Disconnected")
	multiplayer.call_deferred("set_multiplayer_peer", null)

func _on_peer_disconnect(_id: int):
	_on_disconnect()

func host(port: int):
	Log.info("Hosting on :%d" % port)
	var peer := ENetMultiplayerPeer.new()
	peer.connect("peer_disconnected", _on_peer_disconnect)
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		_fail(err)
		return
	multiplayer.multiplayer_peer = peer

func join(address: String, port: int):
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
