extends Node

# const LOBBY_MAX_MEMBERS := 10

# func _ready() -> void:
# 	if not Steam.isSteamRunning():
# 		Log.info("Steam not running")
# 		return

# 	var res := Steam.steamInit()
# 	if res.status != 1:
# 		Log.error("Failed to initialize steam: %s" % res.verbal)
# 		set_physics_process(false)
# 		return

# 	Log.info("Steam initialized: %s" % res)

# # Join an available lobby if there is one, else host a new one
# # Returns the lobby ID async
# func find_or_create_lobby(lobby_name: String) -> int:
# 	Log.info("Searching for lobbies")
# 	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
# 	Steam.addRequestLobbyListStringFilter("name", lobby_name, Steam.LOBBY_COMPARISON_EQUAL)
# 	Steam.requestLobbyList()

# 	var lobbies: Array = await Steam.lobby_match_list
# 	if lobbies.is_empty():
# 		Log.info("No lobby named %s found, creating one" % lobby_name)
# 		return await create_lobby(lobby_name)
# 	var id: int = lobbies[0]
# 	Log.info("Found lobby %d" % id)
# 	return id

# # Returns the ID of the created lobby, or 0 if it failed
# func create_lobby(lobby_name: String) -> int:
# 	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, LOBBY_MAX_MEMBERS)
# 	# res: [response, lobby_id]
# 	var res: Array = await Steam.lobby_created
# 	if res[0] != 1:
# 		Log.error("Failed to create steam lobby: %s" % Steam.getAPICallFailureReason())
# 		return 0
# 	var id: int = res[1]
# 	Log.info("Created steam lobby: %d" % id)
# 	Steam.setLobbyJoinable(id, true)
# 	Steam.setLobbyData(id, "name", lobby_name)
# 	if Steam.allowP2PPacketRelay(true):
# 		Log.info("Enabled steam relay backup")
# 	else:
# 		Log.warn("Steam relay backup unavailable")
# 	return id

# func _physics_process(_delta: float) -> void:
# 	Steam.run_callbacks()

# func _check_command_line() -> void:
# 	var arguments := OS.get_cmdline_args()
# 	var connect_idx := arguments.find("+connect_lobby")
# 	if connect_idx >= 0 and connect_idx < arguments.size() - 1:
# 		var arg := arguments[connect_idx + 1]
# 		var id := int(arg)
# 		if id == 0:
# 			Log.error("Failed to parse lobby id from arg: %s" % arg)
# 		else:
# 			Log.error("Joining lobby from CLI args: %d" % id)
# 			# join_lobby(id)
