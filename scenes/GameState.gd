extends RefCounted
class_name GameState

var frame: int
var player_states: Dictionary  # entity_id(int)->Player.State
var items: Array[MeleeWeapon.Kind]  # item at each numbered item spawn

func _init(buf: StreamPeerBuffer = null):
	if not buf:
		return

	frame = buf.get_u32()

	var player_count := buf.get_u8()

	for _i in range(player_count):
		var id := buf.get_u32()
		var p := PlayerState.new(buf)
		player_states[id] = p

	var items_count := buf.get_u8()
	items.resize(items_count)

	for i in range(items_count):
		items[i] = buf.get_u8() as MeleeWeapon.Kind

func write(buf: StreamPeerBuffer):
	buf.put_u32(frame)

	assert(player_states.size() <= 2 << 7, "too many players")
	buf.put_u8(player_states.size())
	for id in player_states:
		buf.put_u32(id as int)
		(player_states[id] as PlayerState).write(buf)

	assert(player_states.size() <= 2 << 7, "too many players")
	buf.put_u8(items.size())
	for kind in items:
		assert(kind <= 2 << 7, "item index too high")
		buf.put_u8(kind)

func _to_string() -> String:
	var s := "players={"
	for id in player_states:
		s += "%d: {%s}, " % [id, player_states[id]]
	s += "},items=["
	for i in items:
		s += "%d," % i
	return s + "]"
