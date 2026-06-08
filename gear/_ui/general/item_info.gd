extends Node

@onready var item_name_label: Label = $ItemName
@onready var item_type_label: Label = $ItemType
@onready var item_quality: Label = $ItemQuality
@onready var stats_label: Label = $StatsLabel
@onready var effects_label: Label = $EffectsLabel
@onready var modifiers_label: Label = $ModifiersLabel

func show_item_info(item: Item, wielder: Character = null) -> void:
	clear_info()
	if item == null:
		self.visible = false
		return

	self.visible = true
	item_name_label.text = item.get_item_name()
	item_type_label.text = item.item_type_to_string(item.type)

	if item is Gear:
		item_quality.text = "Quality: %s" % ItemTypes.quality_to_string(item.quality as ItemTypes.Quality)

		var stat_lines: Array[String] = []

		if item is Weapon:
			stat_lines.append("Attack rate: x%s" % item.attack_rate)
			stat_lines.append("Type: %s" % _weapon_type_str(item.weapon_type))
			stat_lines.append("Range: %s" % _range_str(item.weapon_range))

		var stats: Stats = item.stats
		var is_weapon := item is Weapon

		if is_weapon:
			for power_stat: Stats.StatRef in WeaponScaling.ALLOWED_TARGET_STATS:
				var line := _weapon_power_line(item as Weapon, power_stat, wielder)
				if line != "":
					stat_lines.append(line)

		for stat: Stats.StatRef in Stats.StatRef.values():
			if is_weapon and stat in WeaponScaling.ALLOWED_TARGET_STATS:
				continue
			if stats.get_stat(stat) != 0:
				stat_lines.append("%s: %d" % [Stats.get_stat_name(stat), int(stats.get_stat(stat))])
		stats_label.text = "\n".join(stat_lines)

		if item.get_all_modifiers().size() > 0:
			var mod_lines: Array[String] = []
			for mod: StatModifier in item.get_all_modifiers():
				mod_lines.append("%s" % mod.get_description())
			modifiers_label.text = "\n".join(mod_lines)
		else:
			modifiers_label.text = ""
	else:
		stats_label.text = ""

	if item is Consumable or item is Gear:
		if item.get_all_effects().size() > 0:
			var effect_lines: Array[String] = []
			for e: Effect in item.get_all_effects():
				effect_lines.append("%s" % e.get_description())
			effects_label.text = "\n".join(effect_lines)
		else:
			effects_label.text = ""

func clear_info() -> void:
	item_name_label.text = ""
	item_type_label.text = ""
	item_quality.text = ""
	stats_label.text = ""
	effects_label.text = ""
	modifiers_label.text = ""

func hide_item_info() -> void:
	self.visible = false


func _weapon_type_str(t: ItemTypes.WeaponType) -> String:
	match t:
		ItemTypes.WeaponType.SWORD: return "Sword"
		ItemTypes.WeaponType.AXE:   return "Axe"
	return "Unknown"


func _range_str(r: TargetingManager.RangeType) -> String:
	match r:
		TargetingManager.RangeType.MELEE:  return "Melee"
		TargetingManager.RangeType.RANGED: return "Ranged"
	return "Unknown"


const _ATTRIBUTE_SHORT := {
	Attributes.AttributeRef.STR: "STR",
	Attributes.AttributeRef.IQ:  "INT",
	Attributes.AttributeRef.PIE: "PIE",
	Attributes.AttributeRef.VIT: "VIT",
	Attributes.AttributeRef.DEX: "DEX",
	Attributes.AttributeRef.SPD: "SPD",
	Attributes.AttributeRef.LUK: "LUK",
}

const _STAT_SHORT := {
	Stats.StatRef.HEALTH:        "HP",
	Stats.StatRef.MANA:          "MP",
	Stats.StatRef.SP:            "SP",
	Stats.StatRef.SPEED:         "ASPD",
	Stats.StatRef.DEFENSE:       "DEF",
	Stats.StatRef.MAGIC_DEFENSE: "MDEF",
	Stats.StatRef.RESISTANCE:    "RES",
	Stats.StatRef.ACCURACY:      "ACC",
	Stats.StatRef.EVASION:       "EVA",
	Stats.StatRef.HEALING_DONE:     "HEAL",
	Stats.StatRef.HEALING_RECEIVED: "RCV",
}


func _scaling_tier(multiplier: float) -> String:
	var m := absf(multiplier)
	if m <= 0.0:
		return ""
	if m < 0.4:
		return "+"
	if m < 0.8:
		return "++"
	if m < 1.4:
		return "+++"
	return "++++"


func _weapon_power_line(weapon: Weapon, power_stat: Stats.StatRef, wielder: Character = null) -> String:
	var base: int = int(weapon.stats.get_stat(power_stat))
	var scaling_value: float = 0.0
	if wielder != null and weapon.scaling != null:
		scaling_value = weapon.scaling.compute_contribution(power_stat, wielder)
	var total: int = int(round(base + scaling_value))
	var tags: Array[String] = []

	if weapon.scaling != null:
		for entry: WeaponScalingEntry in weapon.scaling.entries:
			if entry == null or entry.stat != power_stat:
				continue
			for am: AttributeMultiplier in entry.attribute_contributions:
				if am == null or am.multiplier == 0.0:
					continue
				var short: String = _ATTRIBUTE_SHORT.get(am.attribute, "?")
				tags.append("%s%s" % [short, _scaling_tier(am.multiplier)])
			for sm: StatMultiplier in entry.stat_contributions:
				if sm == null or sm.multiplier == 0.0:
					continue
				var short: String = _STAT_SHORT.get(sm.source_stat, "?")
				tags.append("%s%s" % [short, _scaling_tier(sm.multiplier)])

	if base == 0 and tags.is_empty():
		return ""

	var line := "%s: %d" % [Stats.get_stat_name(power_stat), total]
	if not tags.is_empty():
		line += "  " + " ".join(tags)
	return line
