extends Node
class_name StatCalculator


static func recalculate_all_stats(c: Character) -> void:
	for s: Stats.StatRef in Stats.StatRef.values():
		_recalculate_modified(c, s)

	for s: Stats.StatRef in Stats.StatRef.values():
		_apply_dependent_modifiers(c, s)

	for s: Stats.StatRef in WeaponScaling.ALLOWED_TARGET_STATS:
		_apply_weapon_scaling(c, s)


static func _recalculate_modified(c: Character, s: Stats.StatRef) -> void:
	if Stats.is_percentage_stat(s):
		_recalculate_percentage_stat(c, s)
		return

	var gear_value: float = 0.0

	for slot: Gear in c.equipment.get_all_equipment():
		if slot == null:
			continue
		if slot is Gear:
			gear_value += slot.stats.get_stat(s)
		else:
			push_error("Non gear item is equipped: %s" % slot.get_item_name())

	var computed: float = c.base_stats.get_stat(s) \
		+ get_attribute_contribution(s, c) \
		+ get_level_contribution(s, c) \
		+ gear_value

	c.computed_stats.set_stat(s, computed)

	var mod_bonus: float = 0.0

	for mod: StatModifier in c.state.get_modifiers():
		if mod.stat != s or mod.depends_on_another_stat:
			continue
		mod_bonus += mod.compute_value(c, computed)

	c.modified_stats.set_stat(s, computed + mod_bonus)


static func _apply_dependent_modifiers(c: Character, s: Stats.StatRef) -> void:
	if Stats.is_percentage_stat(s):
		return

	var modified: float = c.modified_stats.get_stat_raw(s)
	var bonus: float = 0.0

	for mod: StatModifier in c.state.get_modifiers():
		if mod.stat != s or not mod.depends_on_another_stat:
			continue
		bonus += mod.compute_value(c, modified)

	_set_final(c, s, round(modified + bonus))


static func _apply_weapon_scaling(c: Character, s: Stats.StatRef) -> void:
	var scaling_total: float = 0.0

	for slot: Gear in c.equipment.get_all_equipment():
		if slot == null or not (slot is Weapon):
			continue
		var weapon := slot as Weapon
		if weapon.scaling == null:
			continue
		scaling_total += weapon.scaling.compute_contribution(s, c)

	if scaling_total == 0.0:
		return

	_set_final(c, s, round(c.stats.get_stat_raw(s) + scaling_total))


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

	c.modified_stats.set_stat(s, total)

	_set_final(c, s, round(total))


static func _set_final(c: Character, s: Stats.StatRef, value: float) -> void:
	if c.stats.get_stat_raw(s) == value:
		return

	c.stats.set_stat(s, value)

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
