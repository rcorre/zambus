extends Resource
class_name PlayerInput

# Export all fields that must be duplicated
# We extend Resource just to get a builtin duplicate
@export var frame: int
@export var move: Vector2
@export var look: Vector2
@export var stance: int  # Stance

static func get_frame(buf: StreamPeerBuffer) -> int:
	return buf.get_u32()

func write(buf: StreamPeerBuffer):
	buf.put_u32(frame)

	buf.put_float(move.x)
	buf.put_float(move.y)

	buf.put_float(look.x)
	buf.put_float(look.y)

	buf.put_u16(stance)

func _init(buf: StreamPeerBuffer = null):
	if not buf:
		return

	frame = buf.get_u32()

	move.x = buf.get_float()
	move.y = buf.get_float()

	look.x = buf.get_float()
	look.y = buf.get_float()

	stance = buf.get_u16()

func _to_string() -> String:
	return "Inputs(frame=%d,move=%s,look=%s,stance=%x)" % [frame, move, look, stance]
