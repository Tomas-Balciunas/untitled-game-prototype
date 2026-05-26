extends Node
class_name StatCalculator


static func recalculate_all_stats(c: Character) -> void:
	for s: Stats.StatRef in Stats.StatRef.values():
		recalculate_stat(c, s)
	

static func recalculate_stat(c: Character, s: Stats.StatRef) -> void:
	# Percentage stats start from a fixed baseline and only take multiplicative
	# modifiers — they ignore base/attribute/level/gear contributions entirely.
	if Stats.is_percentage_stat(s):
		_recalculate_percentage_stat(c, s)
		return

	var base_value: float = c.base_stats.get_stat(s)
	var computed_stat: float = base_value + get_attribute_contribution(s, c) + get_level_contribution(s, c)
	c.computed_stats.set_stat(s, computed_stat)

	var gear_value: float = 0.0

	for slot: Gear in c.equipment.get_all_equipment():
		if slot == null:
			continue
		if slot is Gear:
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

	var final: float = round(computed_stat + flat_bonus + pct_bonus + gear_value)

	c.stats.set_stat(s, final)

	CharacterBus.stat_changed.emit(c, s)


static func _recalculate_percentage_stat(c: Character, s: Stats.StatRef) -> void:
	c.computed_stats.set_stat(s, Stats.PERCENTAGE_BASE)

	var total: float = Stats.PERCENTAGE_BASE

	for mod: StatModifier in c.state.get_modifiers():
		if mod.stat != s:
			continue
		if mod.type == StatModifier.Type.ADDITIVE:
			push_error("Flat (ADDITIVE) modifier not allowed on percentage stat %s (modifier '%s')" % [Stats.get_stat_name(s), mod.id])
			continue
		total += mod.compute_value(c, Stats.PERCENTAGE_BASE)

	c.stats.set_stat(s, round(total))

	CharacterBus.stat_changed.emit(c, s)


static func get_attribute_contribution(stat: Stats.StatRef, c: Character) -> float:
	var total: float = 0.0

	var sources: Array = [
		[c.job.stat_attribute_growth, "job '%s'" % c.job.name],
		[c.resource.stat_attribute_growth, "character '%s'" % c.resource.name],
		[c.race.stat_attribute_growth, "race '%s'" % c.race.name],
	]

	for source in sources:
		var growth: StatAttributeGrowth = source[0]
		if not growth:
			push_error("StatAttributeGrowth missing on %s" % source[1])
			continue
		total += growth.get_contribution(stat, c.attributes)

	return total
	
static func get_level_contribution(stat: Stats.StatRef, c: Character) -> float:
	return c.job.get_stat_level_growth().get_stat(stat) * (c.level - 1) + c.resource.get_stat_level_growth().get_stat(stat) * (c.level - 1)
