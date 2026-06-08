extends Gear
class_name Weapon

var targeting: TargetingManager.TargetType
var attack_rate: int = 1
var weapon_range: TargetingManager.RangeType = TargetingManager.RangeType.MELEE
var weapon_type: ItemTypes.WeaponType
var accuracy_range: int = 0
var scaling: WeaponScaling


func game_save() -> Dictionary:
	var data := super.game_save()
	data["weapon_type"]    = weapon_type
	data["weapon_range"]   = weapon_range
	data["accuracy_range"] = accuracy_range
	data["attack_rate"]    = attack_rate
	data["scaling"]        = scaling.game_save() if scaling else {}
	return data


func game_load(data: Dictionary) -> void:
	super.game_load(data)
	weapon_type    = data.get("weapon_type", ItemTypes.WeaponType.SWORD) as ItemTypes.WeaponType
	weapon_range   = data.get("weapon_range", TargetingManager.RangeType.MELEE) as TargetingManager.RangeType
	accuracy_range = data.get("accuracy_range", 0)
	attack_rate    = data.get("attack_rate", 1)
	targeting      = TargetingManager.TargetType.SINGLE
	scaling        = WeaponScaling.new()
	scaling.game_load(data.get("scaling", {}))

func get_gear_type() -> ItemTypes.GearType:
	return ItemTypes.GearType.WEAPON
