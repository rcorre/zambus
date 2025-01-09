extends BaseNetInput
class_name PlayerInput
@export var mouse_sensitivity: float = 0.5

# Config variables
var is_setup: bool = false
var override_mouse: bool = false

# Input variables
var mouse_rotation: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
var movement: Vector2 = Vector2.ZERO
var fire: bool = false
var jump: bool = false

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		override_mouse = false

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return

	var motion := event as InputEventMouseMotion
	if motion:
		mouse_rotation.y = motion.relative.x * mouse_sensitivity
		mouse_rotation.x = motion.relative.y * mouse_sensitivity
		return

	if event.is_action_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		override_mouse = true

func _gather():
	if !is_setup:
		setup()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	movement = Input.get_vector("left", "right", "forward", "backward")

	jump = Input.is_action_pressed("jump")
	fire = Input.is_action_pressed("attack")

	if override_mouse:
		look_angle = Vector2.ZERO
		mouse_rotation = Vector2.ZERO
	else:
		look_angle = Vector2(-mouse_rotation.y * NetworkTime.ticktime, -mouse_rotation.x * NetworkTime.ticktime)
		mouse_rotation = Vector2.ZERO

func setup():
	is_setup = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
