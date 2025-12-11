extends RefCounted
class_name GearBuilder


func build_item(type: Item.ItemType, tier: String) -> ItemInstance:
	match type:
		Item.ItemType.WEAPON:
			return build_weapon(tier)
		Item.ItemType.CHEST:
			return build_chest(tier)
		Item.ItemType.HELMET:
			return
		Item.ItemType.BOOTS:
			return
		Item.ItemType.GLOVES:
			return
		Item.ItemType.RING:
			return
		Item.ItemType.AMULET:
			return
		Item.ItemType.CONSUMABLE:
			return
		_:
			return


func get_stats(range_data: Dictionary) -> Stats:
	var stats: Stats = Stats.new()
	
	if range_data.is_empty():
		return stats
	
	for stat: Stats.StatRef in range_data:
		var min: float = range_data[stat][0]
		var max: float = range_data[stat][1]
		var rand: float = randf_range(min, max)
		
		stats.set_stat(stat, rand)
	
	return stats


func build_weapon(tier: String) -> Weapon:
	var r: WeaponResource = WeaponResource.new()
	r.targeting = TargetingManager.TargetType.SINGLE
	r.accuracy_range = ItemConfig.get_accuracy(tier, r.weapon_type)
	
	var stat_range: Dictionary = ItemConfig.get_stat_range_weapon(tier, r.type, r.weapon_type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	return r._build_instance()

func build_chest(tier: String) -> Chestpiece:
	var r: ChestpieceResource = ChestpieceResource.new()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	return r._build_instance()
	
	
	
	
	
	
