extends GearInstance
class_name WeaponInstance

var targeting: TargetingManager.TargetType
var weapon_type: Weapon.Type
var accuracy_range: int = 0

func _init() -> void:
	type = Item.ItemType.WEAPON

func hydrate(weapon: Weapon) -> void:
	id = weapon.id
	item_name = weapon.name
	item_description = weapon.description
	stats = weapon.base_stats.duplicate(true)
	base_stats = stats.duplicate(true)
	base_effects = weapon.effects.duplicate(true)
	base_modifiers = weapon.modifiers.duplicate(true)
	targeting = weapon.targeting
	weapon_type = weapon.weapon_type
	accuracy_range = weapon.accuracy_range

func game_save() -> Dictionary:
	return {}


func game_load() -> void:
	pass
