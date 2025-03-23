extends BaseNetInput
class_name PlayerInput
@export var mouse_sensitivity: float = 0.5

var replay := false

# Local variables
var override_mouse: bool = false
var mouse_rotation: Vector2 = Vector2.ZERO
var sprint := false
var crouch := false

# Sync'd variables
var look_angle: Vector2 = Vector2.ZERO
var movement: Vector2 = Vector2.ZERO
var action: Player.Action
var stance: Player.Stance

class Inputs:
	var look_angle: Vector2 = Vector2.ZERO
	var movement: Vector2 = Vector2.ZERO
	var action: Player.Action
	var stance: Player.Stance

var inputs: Array[Inputs]

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		override_mouse = false

func _input(event: InputEvent) -> void:
	if replay or !is_multiplayer_authority():
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
	if replay:
		var i: Inputs = inputs.pop_back()
		if not i:
			look_angle = Vector2.ZERO
			movement = Vector2.ZERO
			action = Player.Action.NONE
			stance = Player.Stance.STAND if stance == Player.Stance.SPRINT else stance
			return
		look_angle = i.look_angle
		movement = i.movement
		action = i.action
		stance = i.stance
		return

	movement = Input.get_vector("left", "right", "forward", "backward")

	if Input.is_action_pressed("attack"):
		action = Player.Action.ATTACK
	elif Input.is_action_pressed("aim"):
		action = Player.Action.AIM
	elif Input.is_action_pressed("interact"):
		action = Player.Action.INTERACT
	else:
		action = Player.Action.NONE

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

	var inp := Inputs.new()
	inp.look_angle = look_angle
	inp.movement = movement
	inp.action = action
	inp.stance = stance
	inputs.push_back(inp)
