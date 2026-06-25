extends Gear
class_name Weapon

var targeting: TargetingManager.TargetType
var attack_rate: int = 1
var weapon_type: ItemTypes.WeaponType
var accuracy_range: int = 0
var scaling: WeaponScaling
## only matters when bounce targeting is selected
var bounce_instances: int = 1
## only matters when salvo targeting is selected
var salvo_pellets: int = 1


func game_save() -> Dictionary:
	var data := super.game_save()
	data["weapon_type"]      = weapon_type
	data["accuracy_range"]   = accuracy_range
	data["attack_rate"]      = attack_rate
	data["targeting"]        = targeting
	data["bounce_instances"] = bounce_instances
	data["salvo_pellets"]    = salvo_pellets
	data["scaling"]          = scaling.game_save() if scaling else {}
	return data


func game_load(data: Dictionary) -> void:
	super.game_load(data)
	weapon_type      = data.get("weapon_type", ItemTypes.WeaponType.SWORD) as ItemTypes.WeaponType
	accuracy_range   = data.get("accuracy_range", 0)
	attack_rate      = data.get("attack_rate", 1)
	targeting        = data.get("targeting", TargetingManager.TargetType.SINGLE) as TargetingManager.TargetType
	bounce_instances = data.get("bounce_instances", 1)
	salvo_pellets    = data.get("salvo_pellets", 1)
	scaling          = WeaponScaling.new()
	scaling.game_load(data.get("scaling", {}))

func get_gear_type() -> ItemTypes.GearType:
	return ItemTypes.GearType.WEAPON
