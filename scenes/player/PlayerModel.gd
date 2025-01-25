extends Node3D
class_name PlayerModel

const BASE_FOV := 90.0
const AIM_FOV := 70.0

@onready var camera: Camera3D = $Armature/Skeleton3D/Camera_2/Camera_2

@onready var anim: AnimationTree = $AnimationTree
@onready var skel: Skeleton3D = $Armature/Skeleton3D

@onready var right_hand: BoneAttachment3D = $Armature/Skeleton3D/RightHand
@onready var left_hand: BoneAttachment3D = $Armature/Skeleton3D/LeftHand

var weapon: Weapon
var last_action: Player.Action

func die(local: bool):
	skel.physical_bones_start_simulation()

	if local:
		# local player
		var death_cam: Camera3D = $SpringArm3D/DeathCam
		if death_cam:
			death_cam.make_current()

func set_velocity(vel: Vector3, stance: Player.Stance):
	var stance_name := (Player.Stance.keys()[stance] as String).to_lower()
	anim.set("parameters/stance/transition_request", stance_name)

	# vel is global, so un-rotate to get local velocity
	# X is flipped from the player due to camera orientation
	var speed_mult: float = anim.get("parameters/move_speed/scale")
	var xz := Vector2(-vel.x, vel.z).rotated(-global_rotation.y) / speed_mult
	anim.set("parameters/move/blend_position", xz)

func set_look_y(look: float):
	anim.set("parameters/look_y/add_amount", 2.0 * look / PI)

# func set_action(action: Player.Action, action_progress: float):
# 	match action:
# 		Player.Action.NONE:
# 			anim.set("parameters/attack/blend_amount", 0.0)
# 			anim.set("parameters/attack_swing/blend_position", 0.0)
# 		Player.Action.AIM:
# 			anim.set("parameters/attack/blend_amount", action_progress)
# 		Player.Action.ATTACK:
# 			anim.set("parameters/attack/blend_amount", 1.0)
# 			anim.set("parameters/attack_swing/blend_position", action_progress)
# 		Player.Action.RECOIL:
# 			anim.set("parameters/attack/blend_amount", 1.0 - action_progress)
# 			anim.set("parameters/attack_swing/blend_position", 1.0)

func set_action(action: Player.Action, action_progress: float):
	# action progress should never go outside [0.0, 1.0], but clamp here to be safe
	var progress := clamp(action_progress, 0.0, 1.0) as float

	if action == Player.Action.RECOIL and action != last_action:
		weapon.fire()

	last_action = action

	# pistol_action is a 1D blend space going from idle (0.0) -> aim (1.0) -> recoil (2.0)
	match action:
		Player.Action.NONE:
			anim.set("parameters/pistol_action/blend_position", 0.0)
			camera.fov = BASE_FOV
		Player.Action.AIM:
			anim.set("parameters/pistol_action/blend_position", progress)
			camera.fov = lerp(BASE_FOV, AIM_FOV, progress)
		Player.Action.RECOIL:
			anim.set("parameters/pistol_action/blend_position", 2.0 - progress)

func equip(new_weapon: Weapon):
	weapon = new_weapon
	for child in right_hand.get_children():
		child.queue_free()

	right_hand.add_child(weapon)

func hurt():
	anim.set("parameters/hurt/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
