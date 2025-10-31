extends Node

@onready var item_name_label: Label = $ItemName
@onready var item_type_label: Label = $ItemType
@onready var stats_label: Label = $StatsLabel
@onready var effects_label: Label = $EffectsLabel
@onready var modifiers_label: Label = $ModifiersLabel

func show_item_info(item: ItemInstance) -> void:
	if item == null:
		self.visible = false
		return

	self.visible = true
	item_name_label.text = item.get_item_name()
	item_type_label.text = item.item_type_to_string(item.template.type)

	if item is GearInstance:
		var base_stats: Dictionary = item.get_base_stats()
		var stat_lines: Array[String] = []
		for stat: String in base_stats.keys():
			if base_stats[stat] != 0:
				stat_lines.append("%s: %d" % [Stats.stat_to_name(stat), base_stats[stat]])
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
	
	if item is ConsumableInstance or item is GearInstance:
		if item.get_all_effects().size() > 0:
			var effect_lines: Array[String] = []
			for e: Effect in item.get_all_effects():
				effect_lines.append("%s" % e.get_description())
			effects_label.text = "\n".join(effect_lines)
		else:
			effects_label.text = ""

func hide_item_info() -> void:
	self.visible = false
