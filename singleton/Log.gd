extends Node

enum Level {
	DEBUG,
	INFO,
	WARN,
	ERROR,
}

signal logged(msg, lvl)

func _fmt(msg: Variant) -> String:
	return "%d (%s): %s" % [NetworkTime.tick, multiplayer.get_unique_id(), msg]

func debug(msg: Variant):
	if OS.is_debug_build():
		print(_fmt(msg))
		logged.emit(msg, Level.DEBUG)

func info(msg: Variant):
	print(_fmt(msg))
	logged.emit(msg, Level.INFO)

func warn(msg: Variant):
	push_warning(_fmt(msg))
	logged.emit(msg, Level.WARN)

func error(msg: Variant):
	push_error(_fmt(msg))
	logged.emit(msg, Level.ERROR)

func trace(msg: Variant, period: int = 60):
	if get_tree().get_frame() % period == 0:
		print(_fmt(msg))
