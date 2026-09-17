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
		
		if mod.type == StatModifier.Type.MULTIPLICATIVE and s in Stats.PERCENTAGE_STATS:
			push_error("multiplicative modifier not allowed on percentage stat %s (modifier '%s')" % [Stats.get_stat_name(s), mod.id])
			continue
		
		mod_bonus += mod.compute_value(c, computed)

	var modified_value: float = computed + mod_bonus
	c.modified_stats.set_stat(s, modified_value)
	_set_final(c, s, modified_value)


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


static func _set_final(c: Character, s: Stats.StatRef, value: float) -> void:
	if c.stats.get_stat_raw(s) == value:
		return

	c.stats.set_stat(s, value)

	CharacterBus.stat_changed.emit(c, s)


static func get_attribute_contribution(stat: Stats.StatRef, c: Character) -> float:
	var growth: StatAttributeGrowth = c.resource.stat_attribute_growth

	if not growth:
		push_error("StatAttributeGrowth missing on character '%s'" % c.resource.name)
		return 0.0

	return growth.get_contribution(stat, c.attributes)

static func get_level_contribution(stat: Stats.StatRef, c: Character) -> float:
	return c.resource.get_stat_level_growth().get_stat(stat) * (c.level - 1)

static func apply_percentage_stat_multiplier(_stat: Stats.StatRef, character: Character, value: float) -> float:
	if Stats.is_percentage_stat(_stat) == false:
		push_error("%s is not a percentage stat!" % Stats.get_stat_name(_stat))
		
		return 1.0
	
	var stat: float = character.stats.get_stat_raw(_stat)
	var stat_multiplier: float = (1 + absf(stat) / 100.0)
	var final_value: float = value
	
	if stat < 0.0:
		final_value = value / stat_multiplier
	elif stat > 0.0:
		final_value = value * stat_multiplier
	
	return final_value
