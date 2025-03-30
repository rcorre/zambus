extends Label

const MAX_PEERS := 4

func _ready():
	NetworkEvents.on_peer_join.connect(_update_count)
	NetworkEvents.on_peer_leave.connect(_update_count)
	_update_count()

func _update_count() -> void:
	# get_peers does not include self, so +1
	text = "%d/%d" % [multiplayer.get_peers().size() + 1, MAX_PEERS]
