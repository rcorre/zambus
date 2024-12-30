extends Control
class_name HUD

const GUARD_ARC_POINTS := 32
const GUARD_ARC_RADIUS := 8

@onready var health_bar: ProgressBar = find_child("HealthBar")
@onready var health_text: Label = health_bar.get_node("Label")
@onready var hurt_overlay: Control = find_child("HurtOverlay")
@onready var latency_label: LatencyLabel = find_child("LatencyLabel")

var last_state := PlayerState.new()

func set_max_health(val: int) -> void:
	health_bar.max_value = val

func update_state(state: PlayerState) -> void:
	health_bar.value = state.health
	health_text.text = "%d" % state.health
	if state.health < last_state.health:
		var tween := get_tree().create_tween()
		tween.tween_property(hurt_overlay, "modulate", Color.WHITE, 0.1)
		tween.tween_property(hurt_overlay, "modulate", Color.TRANSPARENT, 0.5)
	last_state = state
	queue_redraw()

func _draw() -> void:
	if last_state.guard <= 0:
		return
	var r := get_viewport_rect()
	var c := r.get_center()
	# TODO: use fov
	var offset := Vector2(r.size.x * last_state.guard * Global.GUARD_ANGLE / PI - GUARD_ARC_RADIUS / 2.0, 0.0)
	draw_arc(c + offset, 16.0, -PI / 3.0, PI / 3.0, GUARD_ARC_POINTS, Color.WHITE, 4.0, false)
	draw_arc(c - offset, 16.0, -2 * PI / 3.0, -4 * PI / 3.0, GUARD_ARC_POINTS, Color.WHITE, 4.0, false)

func update_latency(val: float) -> void:
	latency_label.update_latency(val)
