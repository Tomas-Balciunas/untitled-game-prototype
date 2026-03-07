extends GearInstance
class_name Weapon

var targeting: TargetingManager.TargetType
var weapon_range: TargetingManager.RangeType = TargetingManager.RangeType.MELEE
var weapon_type: WeaponResource.Type
var accuracy_range: int = 0


func game_save() -> Dictionary:
	return {
		"class": get_class()
	}


func game_load(_data: Dictionary) -> void:
	pass
