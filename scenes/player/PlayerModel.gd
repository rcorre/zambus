extends Node3D
class_name PlayerModel

@onready var camera: Camera3D = $Armature/Skeleton3D/Camera_2/Camera_2

@onready var anim: AnimationTree = $AnimationTree
@onready var skel: Skeleton3D = $Armature/Skeleton3D

@onready var right_hand: BoneAttachment3D = $Armature/Skeleton3D/RightHand
@onready var left_hand: BoneAttachment3D = $Armature/Skeleton3D/LeftHand

func _ready():
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func equip(hand: MeleeWeapon.Hand, w: MeleeWeapon):
	var bone := right_hand if w.hand == MeleeWeapon.Hand.MAIN else left_hand
	for c in bone.get_children():
		c.queue_free()
	if w:
		w.transform = Transform3D()
		bone.add_child(w)

func interact() -> MeleeWeapon:
	var ray: RayCast3D = $Armature/Skeleton3D/Camera_2/InteractRay
	ray.force_raycast_update()
	return ray.get_collider() as MeleeWeapon

func hitboxes() -> Array[Node]:
	return find_children("Hitbox")

func die(local: bool):
	skel.physical_bones_start_simulation()

	if local:
		# local player
		var death_cam: Camera3D = $SpringArm3D/DeathCam
		if death_cam:
			death_cam.make_current()

func update_state(state: PlayerState, delta: float) -> void:
	var vel := state.vel

	# vel is global, so un-rotate to get local velocity
	# X is flipped from the player due to camera orientation
	var speed_mult: float = anim.get("parameters/move_speed/scale")
	var xz := Vector2(-vel.x, vel.z).rotated(-global_rotation.y) / speed_mult
	anim.set("parameters/move/blend_position", xz)

	anim.set("parameters/look_y/add_amount", 2.0 * state.look.y / PI)

	if state.stance == Stance.ATTACK or state.stance == Stance.RECOIL:
		anim.set("parameters/attack_blend/blend_amount", 1.0)
		prints(state.action_progress)
		anim.set("parameters/attack_seek/seek_request", state.action_progress)
	else:
		anim.set("parameters/attack_blend/blend_amount", 0.0)

	if state.stance == Stance.BLOCK:
		anim.set("parameters/block_blend/blend_amount", state.action_progress)
	else:
		anim.set("parameters/block_blend/blend_amount", 0)

	if state.stance == Stance.INTERACT:
		anim.set("parameters/equip_blend/blend_amount", 1.0)
		prints(state.action_progress)
		anim.set("parameters/equip_seek/seek_request", state.action_progress)
	else:
		anim.set("parameters/equip_blend/blend_amount", 0)

	anim.set("parameters/hurt/add_amount", state.status[Player.Status.FLINCH] / 20.0)

	# once we've set up our seeks, force the animations/skeleton to update
	anim.advance(delta)
	skel.force_update_all_bone_transforms()
