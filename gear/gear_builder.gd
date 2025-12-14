extends RefCounted
class_name GearBuilder


func build_item(type: Item.ItemType, tier: String) -> ItemInstance:
	match type:
		Item.ItemType.WEAPON:
			return build_weapon(tier)
		Item.ItemType.CHEST:
			return build_chest(tier)
		Item.ItemType.HELMET:
			return build_helmet(tier)
		Item.ItemType.BOOTS:
			return build_boots(tier)
		Item.ItemType.GLOVES:
			return build_gloves(tier)
		Item.ItemType.RING:
			return build_ring(tier)
		Item.ItemType.AMULET:
			return build_amulet(tier)
		Item.ItemType.CONSUMABLE:
			return
		_:
			return


func get_quality() -> Gear.Quality:
	var r: float = randf()
	
	if r < 0.07:
		return Gear.Quality.EXCEPTIONAL
	elif r < 0.16:
		return Gear.Quality.RARE
	elif r < 0.27:
		return Gear.Quality.UNCOMMON
	elif r < 0.40:
		return Gear.Quality.COMMON
	
	return Gear.Quality.POOR


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


func get_modifiers(tier: String, applicable: Array[Stats.StatRef], quality: Gear.Quality) -> Array[StatModifier]:
	var amt: int = ItemConfig.get_max_modifiers(tier)
	
	if amt == 0:
		return []
	
	var mods: Array[StatModifier] = []
	var _applicable = applicable.duplicate()
	var rand_amt: int = randi_range(0, amt)
	
	for i: int in range(rand_amt):
		if _applicable.is_empty():
			break
		
		var stat: Stats.StatRef = _applicable.pick_random()
		var type: StatModifier.Type = [StatModifier.Type.ADDITIVE, StatModifier.Type.MULTIPLICATIVE].pick_random()
		var range: Array = StatModifierConfig.RAND_RANGE_VALUES[stat][type][quality]
		var value: Variant
		
		if type == StatModifier.Type.ADDITIVE:
			value = randi_range(range[0], range[1])
		else:
			value = randf_range(range[0], range[1])
		
		var mod: StatModifier = StatModifier.new()
		mod.stat = stat
		mod.type = type
		mod.value = value
		mods.append(mod)
		_applicable.erase(stat)
	
	return mods


func build_weapon(tier: String) -> Weapon:
	var r: WeaponResource = WeaponResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	r.targeting = TargetingManager.TargetType.SINGLE
	r.accuracy_range = ItemConfig.get_accuracy(r.weapon_type)
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range_weapon(tier, r.type, r.weapon_type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()


func build_chest(tier: String) -> Chestpiece:
	var r: ChestpieceResource = ChestpieceResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	r.quality = get_quality()
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()


func build_helmet(tier: String) -> Helmet:
	var r: HelmetResource = HelmetResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()
	
	
func build_boots(tier: String) -> Boots:
	var r: BootsResource = BootsResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()
	
	
func build_gloves(tier: String) -> Gloves:
	var r: GlovesResource = GlovesResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()


func build_ring(tier: String) -> Ring:
	var r: RingResource = RingResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()


func build_amulet(tier: String) -> Amulet:
	var r: AmuletResource = AmuletResource.new()
	r.name = "%s %s" % [ItemConfig.get_item_name(tier), Item.item_type_to_string(r.type)]
	
	r.quality = get_quality()
	
	var stat_range: Dictionary = ItemConfig.get_stat_range(tier, r.type)
	var stats: Stats = get_stats(stat_range)
	r.base_stats = stats
	
	var applicable_mods: Array[Stats.StatRef] = r.get_applicable_stat_modifiers()
	r.modifiers = get_modifiers(tier, applicable_mods, r.quality)
	
	return r._build_instance()
