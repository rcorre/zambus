extends Control

var player: Player

func _ready() -> void:
	set_process(false)
	Global.local_player_spawned.connect(set_player)

func set_player(p: Player) -> void:
	player = p
	set_process(true)

func _process(_delta: float) -> void:
	modulate = Color.TRANSPARENT.lerp(Color(1.0, 1.0, 1.0, 0.7), player.action_progress)
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam or not player:
		return
	var bounds = get_viewport_rect()
	var dist: float
	if cam.keep_aspect == Camera3D.KEEP_HEIGHT:
		dist = bounds.size.y * player.gun_spread_degrees() / cam.fov / 2
	else:
		dist = bounds.size.x * player.gun_spread_degrees() / cam.fov / 2

	draw_circle(Vector2.ZERO, 1.0, Color(1.0, 1.0, 1.0, 0.8))
	if player.gun_drawn():
		draw_line(Vector2.RIGHT * dist, Vector2.RIGHT * (dist + 8.0), Color.WHITE, 2.0)
		draw_line(Vector2.LEFT * dist, Vector2.LEFT * (dist + 8.0), Color.WHITE, 2.0)
		draw_line(Vector2.DOWN * dist, Vector2.DOWN * (dist + 8.0), Color.WHITE, 2.0)
