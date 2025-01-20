extends Control

var player: Player

func _ready() -> void:
	set_process(false)
	Global.local_player_spawned.connect(set_player)

func set_player(p: Player) -> void:
	player = p
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var bounds = get_viewport_rect()
	var dist: float
	if cam.keep_aspect == Camera3D.KEEP_HEIGHT:
		dist = bounds.size.y * player.gun_spread() / cam.fov / 2
	else:
		dist = bounds.size.x * player.gun_spread() / cam.fov / 2

	draw_line(Vector2.RIGHT * dist, Vector2.RIGHT * (dist + 8.0), Color.WHITE, 2.0)
	draw_line(Vector2.LEFT * dist, Vector2.LEFT * (dist + 8.0), Color.WHITE, 2.0)
	draw_line(Vector2.DOWN * dist, Vector2.DOWN * (dist + 8.0), Color.WHITE, 2.0)

# called via propagate_call
func _on_set_crosshairs_visible(on: bool):
	set_visible(on)

