extends Node3D
class_name ZombieModel

@onready var anim: AnimationTree = $AnimationTree
@onready var bones: PhysicalBoneSimulator3D = $Armature/Skeleton3D/PhysicalBoneSimulator3D

func die(impact: Vector3):
	prints("ZombieModel die:", impact)
	bones.physical_bones_start_simulation()
	for child in bones.get_children():
		var bone := child as PhysicalBone3D
		if bone:
			bone.apply_central_impulse(impact)

func set_velocity(vel: Vector3):
	# vel is global, so un-rotate to get local velocity
	# X is flipped from the player due to camera orientation
	var speed_mult: float = anim.get("parameters/move_speed/scale")
	var speed := Vector2(-vel.x, vel.z).length() / speed_mult
	anim.set("parameters/move/blend_position", speed)

func attack():
	anim.set("parameters/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func hurt():
	anim.set("parameters/hurt/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
