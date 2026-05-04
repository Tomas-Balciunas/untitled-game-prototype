extends GearInstance
class_name Weapon

var targeting: TargetingManager.TargetType
var attack_rate: int = 1
var weapon_range: TargetingManager.RangeType = TargetingManager.RangeType.MELEE
var weapon_type: WeaponResource.Type
var accuracy_range: int = 0


func game_save() -> Dictionary:
	var data := super.game_save()
	data["weapon_type"]    = weapon_type
	data["weapon_range"]   = weapon_range
	data["accuracy_range"] = accuracy_range
	data["attack_rate"]    = attack_rate
	return data


func game_load(data: Dictionary) -> void:
	super.game_load(data)
	weapon_type    = data.get("weapon_type", WeaponResource.Type.SWORD) as WeaponResource.Type
	weapon_range   = data.get("weapon_range", TargetingManager.RangeType.MELEE) as TargetingManager.RangeType
	accuracy_range = data.get("accuracy_range", 0)
	attack_rate    = data.get("attack_rate", 1)
	targeting      = TargetingManager.TargetType.SINGLE
