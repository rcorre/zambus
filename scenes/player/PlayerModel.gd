extends Node3D
class_name PlayerModel

@onready var camera: Camera3D = $Armature/Skeleton3D/Camera_2/Camera_2

@onready var anim: AnimationTree = $AnimationTree
@onready var skel: Skeleton3D = $Armature/Skeleton3D

@onready var right_hand: BoneAttachment3D = $Armature/Skeleton3D/RightHand
@onready var left_hand: BoneAttachment3D = $Armature/Skeleton3D/LeftHand

func die(local: bool):
	skel.physical_bones_start_simulation()

	if local:
		# local player
		var death_cam: Camera3D = $SpringArm3D/DeathCam
		if death_cam:
			death_cam.make_current()

func set_velocity(vel: Vector3):
	# vel is global, so un-rotate to get local velocity
	# X is flipped from the player due to camera orientation
	var speed_mult: float = anim.get("parameters/move_speed/scale")
	var xz := Vector2(-vel.x, vel.z).rotated(-global_rotation.y) / speed_mult
	anim.set("parameters/move/blend_position", xz)

func set_look_y(look: float):
	anim.set("parameters/look_y/add_amount", 2.0 * look / PI)

func attack():
	anim.set("parameters/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func equip():
	anim.set("parameters/equip/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func hurt():
	anim.set("parameters/hurt/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
