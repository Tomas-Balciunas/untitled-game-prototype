extends Resource

class_name WeaponScaling

const ALLOWED_TARGET_STATS: Array[Stats.StatRef] = [
	Stats.StatRef.ATTACK,
	Stats.StatRef.MAGIC_POWER,
	Stats.StatRef.DIVINE_POWER,
]

@export var entries: Array[WeaponScalingEntry] = []


func compute_contribution(target_stat: Stats.StatRef, c: Character) -> float:
	if target_stat not in ALLOWED_TARGET_STATS:
		return 0.0

	var total: float = 0.0

	for entry: WeaponScalingEntry in entries:
		if entry == null or entry.stat != target_stat:
			continue

		for am: AttributeMultiplier in entry.attribute_contributions:
			if am == null or am.multiplier == 0.0:
				continue
			total += c.attributes.get_attribute(am.attribute) * am.multiplier

		for sm: StatMultiplier in entry.stat_contributions:
			if sm == null or sm.multiplier == 0.0:
				continue
			if sm.source_stat in ALLOWED_TARGET_STATS:
				push_error("WeaponScaling: source_stat '%s' cannot be a power stat (target '%s')" % [
					Stats.get_stat_name(sm.source_stat),
					Stats.get_stat_name(target_stat),
				])
				continue
			total += c.stats.get_stat(sm.source_stat) * sm.multiplier

	return total


func game_save() -> Dictionary:
	var entry_dicts: Array = []
	for entry: WeaponScalingEntry in entries:
		if entry == null:
			continue

		var attr_dicts: Array = []
		for am: AttributeMultiplier in entry.attribute_contributions:
			if am == null:
				continue
			attr_dicts.append({
				"attribute": am.attribute,
				"multiplier": am.multiplier,
			})

		var stat_dicts: Array = []
		for sm: StatMultiplier in entry.stat_contributions:
			if sm == null:
				continue
			stat_dicts.append({
				"source_stat": sm.source_stat,
				"multiplier": sm.multiplier,
			})

		entry_dicts.append({
			"stat": entry.stat,
			"attribute_contributions": attr_dicts,
			"stat_contributions": stat_dicts,
		})

	return {"entries": entry_dicts}


func game_load(data: Dictionary) -> void:
	entries = []
	for entry_data: Dictionary in data.get("entries", []):
		var entry := WeaponScalingEntry.new()
		entry.stat = entry_data.get("stat", Stats.StatRef.ATTACK) as Stats.StatRef

		var attr_arr: Array[AttributeMultiplier] = []
		for am_data: Dictionary in entry_data.get("attribute_contributions", []):
			var am := AttributeMultiplier.new()
			am.attribute = am_data.get("attribute", Attributes.AttributeRef.STR) as Attributes.AttributeRef
			am.multiplier = am_data.get("multiplier", 0.0)
			attr_arr.append(am)
		entry.attribute_contributions = attr_arr

		var stat_arr: Array[StatMultiplier] = []
		for sm_data: Dictionary in entry_data.get("stat_contributions", []):
			var sm := StatMultiplier.new()
			sm.source_stat = sm_data.get("source_stat", Stats.StatRef.HEALTH) as Stats.StatRef
			sm.multiplier = sm_data.get("multiplier", 0.0)
			stat_arr.append(sm)
		entry.stat_contributions = stat_arr

		entries.append(entry)
