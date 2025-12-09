extends Node
class_name StatCalculator


static func recalculate_all_stats(c: CharacterInstance, should_fill_hp: bool = false, should_fill_mp: bool = false) -> void:
	for s: Stats.StatRef in Stats.StatRef.values():
		recalculate_stat(c, s)
	

static func recalculate_stat(c: CharacterInstance, s: Stats.StatRef) -> void:
	var base_value: float = c.base_stats.get_stat(s)
	var computed_stat: float = base_value + get_attribute_contribution(s, c) + get_level_contribution(s, c)
	c.computed_stats.set_stat(s, computed_stat)
	
	var gear_value: float = 0.0
	
	for slot: ItemInstance in c.equipment.values():
		if slot == null:
			continue
		if slot is GearInstance:
			gear_value += slot.stats.get_stat(s)
		else:
			push_error("Non gear item is equipped: %s" % slot.get_item_name())
	
	var flat_bonus: float = 0.0
	var pct_bonus: float = 0.0
	
	for mod: StatModifier in c.state.get_modifiers():
		if not mod.stat == s:
			continue
		
		var val: float = mod.compute_value(c, computed_stat)
		
		## kinda redundant since we get already multiplied value but whatever
		if mod.type == StatModifier.Type.ADDITIVE:
			flat_bonus += val
		elif mod.type == StatModifier.Type.MULTIPLICATIVE:
			pct_bonus += val
		
	var final: float = computed_stat + flat_bonus + pct_bonus + gear_value
	
	c.stats.set_stat(s, final)

	if s == Stats.StatRef.HEALTH:
		CharacterBus.health_changed.emit(c, c.state.current_health, c.state.current_health)
	
	if s == Stats.StatRef.MANA:
		c.emit_signal("mana_changed", c.state.current_mana, c.state.current_mana)


static func get_attribute_contribution(stat: Stats.StatRef, c: CharacterInstance) -> float:
	var mods: Dictionary = c.job.get_stat_attribute_modifiers(stat)
	
	if mods.is_empty():
		return 0.0
	
	var calculated_value: float = 0.0
	
	for attr: String in mods.keys():
		var attribute_value := c.attributes.get_attribute(attr)
		var mult: float = mods[attr]
		
		calculated_value += attribute_value * mult
		
	return calculated_value
	
static func get_level_contribution(stat: Stats.StatRef, c: CharacterInstance) -> float:
	return c.job.stat_level_growth.get_stat(stat) * (c.level - 1) + c.resource.stat_level_growth.get_stat(stat) * (c.level - 1)
