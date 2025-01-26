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
	# Fade out as we fill
	var color := Color(1.0, 1.0, 1.0, 0.7).lerp(Color.TRANSPARENT, player.stamina / player.max_stamina())
	var dist := player.stamina / 2.0
	draw_line(Vector2.LEFT * dist, Vector2.RIGHT * dist, color, 2.0)
