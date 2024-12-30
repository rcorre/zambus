class_name Stance

enum {
	STAND,
	ATTACK,
	BLOCK,
	RECOIL,
	CROUCH,
	SPRINT,
	DODGE,
	INTERACT,
}

static func string(stance: int) -> String:
	match stance:
		STAND: return "STAND"
		ATTACK: return "ATTACK"
		BLOCK: return "BLOCK"
		RECOIL: return "RECOIL"
		CROUCH: return "CROUCH"
		SPRINT: return "SPRINT"
		DODGE: return "DODGE"
		INTERACT: return "INTERACT"
	return "NOSTANCE"
