extends RefCounted
class_name GearBuilder


func build_item(type: GearResource.Type, tier: String) -> Gear:
	match type:
		GearResource.Type.WEAPON:
			return build_weapon(tier)
		GearResource.ItemType.CONSUMABLE, ItemResource.ItemType.QUEST:
			return null
		_:
			return build_armor(type, tier)


func get_quality() -> GearResource.Quality:
	var r: float = randf()
	if r < 0.07:   return GearResource.Quality.EXCEPTIONAL
	elif r < 0.16: return GearResource.Quality.RARE
	elif r < 0.27: return GearResource.Quality.UNCOMMON
	elif r < 0.40: return GearResource.Quality.COMMON
	return GearResource.Quality.POOR


func get_stats(range_data: Dictionary) -> Stats:
	var stats: Stats = Stats.new()
	if range_data.is_empty():
		return stats
	for stat: Stats.StatRef in range_data:
		var min: float = range_data[stat][0]
		var max: float = range_data[stat][1]
		stats.set_stat(stat, randf_range(min, max))
	return stats


func get_modifiers(tier: String, applicable: Array[Stats.StatRef], quality: GearResource.Quality) -> Array[StatModifier]:
	var amt: int = ItemConfig.get_max_modifiers(tier)
	if amt == 0:
		return []

	var mods: Array[StatModifier] = []
	var _applicable := applicable.duplicate()
	var rand_amt: int = randi_range(0, amt)

	for i: int in range(rand_amt):
		if _applicable.is_empty():
			break
		var stat: Stats.StatRef = _applicable.pick_random()
		var mod_type: StatModifier.Type = [StatModifier.Type.ADDITIVE, StatModifier.Type.MULTIPLICATIVE].pick_random()
		var range: Array = StatModifierConfig.get_range(stat, mod_type, quality)
		var value: Variant
		if mod_type == StatModifier.Type.ADDITIVE:
			value = randi_range(range[0], range[1])
		else:
			value = randf_range(range[0], range[1])
		var mod: StatModifier = StatModifier.new()
		mod.stat = stat
		mod.type = mod_type
		mod.value = value
		mods.append(mod)
		_applicable.erase(stat)

	return mods


func _create_instance(type: GearResource.Type) -> Gear:
	match type:
		GearResource.Type.CHEST:  return Chestpiece.new()
		GearResource.Type.HELMET: return Helmet.new()
		GearResource.Type.BOOTS:  return Boots.new()
		GearResource.Type.GLOVES: return Gloves.new()
		GearResource.Type.RING:   return Ring.new()
		GearResource.Type.AMULET: return Amulet.new()
	return null


func build_armor(type: GearResource.Type, tier: String) -> Gear:
	var item := _create_instance(type)
	if not item:
		push_error("gear_builder: unknown armor type %s" % type)
		return null

	item.type = ItemResource.ItemType.GEAR
	item.id = GameState.generate_id()
	item.item_name = "%s %s" % [ItemConfig.get_item_name(tier), "placeholder for gear type"]
	item.quality = get_quality()

	var stat_range := ItemConfig.get_stat_range(tier, item.get_gear_type())
	item.stats = get_stats(stat_range)
	item.base_stats = item.stats.duplicate(true)

	item.base_modifiers = get_modifiers(tier, ItemConfig.get_applicable_modifiers(type), item.quality)

	return item


func build_weapon(tier: String) -> Weapon:
	var item := Weapon.new()
	item.type = ItemResource.ItemType.GEAR
	item.id = GameState.generate_id()
	item.weapon_type = WeaponResource.WeaponType.values().pick_random()
	item.targeting = TargetingManager.TargetType.SINGLE
	item.weapon_range = TargetingManager.RangeType.MELEE
	item.accuracy_range = ItemConfig.get_accuracy(item.weapon_type)
	item.attack_rate = 1
	item.quality = get_quality()
	item.item_name = "%s %s" % [ItemConfig.get_item_name(tier), ItemResource.item_type_to_string(item.type)]

	var stat_range := ItemConfig.get_stat_range_weapon(tier, item.get_gear_type(), item.weapon_type)
	item.stats = get_stats(stat_range)
	item.base_stats = item.stats.duplicate(true)

	item.base_modifiers = get_modifiers(tier, ItemConfig.get_applicable_modifiers(item.get_gear_type()), item.quality)

	return item
