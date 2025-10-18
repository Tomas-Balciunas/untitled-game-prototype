extends Node

class_name BasicFlatModifierList

const ATTACK_FLAT = preload("uid://xrdswjnhmfp2")
const DEFENSE_FLAT = preload("uid://dsmi8iu6gtp6x")
const HEALTH_FLAT = preload("uid://bpmq3mht31ne4")
const MANA_FLAT = preload("uid://bww60nna6ps8c")
const SPEED_FLAT = preload("uid://c1x6oj5j0rm1f")


static var list := [
	ATTACK_FLAT,
	DEFENSE_FLAT,
	HEALTH_FLAT,
	MANA_FLAT,
	SPEED_FLAT,
]

static func get_random_modifier() -> Resource:
	return list[randi() % len(list)]
