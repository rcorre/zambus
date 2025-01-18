extends Node3D
class_name ZombieModel

@onready var camera: Camera3D = $Armature/Skeleton3D/Camera_2/Camera_2

@onready var anim: AnimationTree = $AnimationTree
@onready var skel: Skeleton3D = $Armature/Skeleton3D

func die():
	skel.physical_bones_start_simulation()

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
