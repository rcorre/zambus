extends Node

# start at 1, 0 is reserved for null
var _next_weapon_id := 1
var _weapons := {0: null}

func register_weapon(w: MeleeWeapon) -> int:
	var id := _next_weapon_id
	_weapons[id] = w
	_next_weapon_id += 1
	return id

func get_weapon(id: int) -> MeleeWeapon:
	return _weapons[id]
