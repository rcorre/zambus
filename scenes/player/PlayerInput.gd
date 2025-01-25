extends BaseNetInput
class_name PlayerInput
@export var mouse_sensitivity: float = 0.5

# Config variables
var override_mouse: bool = false

# Input variables
var mouse_rotation: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
var movement: Vector2 = Vector2.ZERO
var attack := false
var aim := false
var stance: Player.Stance

var sprint := false
var crouch := false

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		override_mouse = false

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return

	var sensitivity := mouse_sensitivity
	if Input.is_action_pressed("aim"):
		sensitivity /= 2.0
	var motion := event as InputEventMouseMotion
	if motion:
		mouse_rotation.y = motion.relative.x * sensitivity
		mouse_rotation.x = motion.relative.y * sensitivity
		return

	if event.is_action_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		override_mouse = true

func _gather():
	movement = Input.get_vector("left", "right", "forward", "backward")

	attack = Input.is_action_pressed("attack")
	aim = Input.is_action_pressed("aim")

	if Input.is_action_pressed("sprint") and Input.is_action_pressed("forward"):
		stance = Player.Stance.SPRINT
	elif Input.is_action_pressed("crouch"):
		stance = Player.Stance.CROUCH
	else:
		stance = Player.Stance.STAND

	if override_mouse:
		look_angle = Vector2.ZERO
		mouse_rotation = Vector2.ZERO
	else:
		look_angle = Vector2(-mouse_rotation.y * NetworkTime.ticktime, -mouse_rotation.x * NetworkTime.ticktime)
		mouse_rotation = Vector2.ZERO
