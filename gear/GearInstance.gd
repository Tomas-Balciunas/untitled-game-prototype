extends ItemInstance
class_name GearInstance

var enhancement_level: int = 0

var stats: Stats

var effects: Array[Effect] = []
var modifiers: Array[StatModifier] = []

var extra_modifiers: Array[StatModifier] = []
var extra_effects: Array[Effect] = []

func _init(resource: Gear) -> void:
	template = resource
	stats = resource.base_stats.duplicate(true)
	
	modifiers = []
	for m in resource.modifiers:
		modifiers.append(m.duplicate(true))
	
	effects = []
	for e in resource.effects:
		effects.append(e.duplicate(true))

	extra_modifiers = []
	extra_effects = []

func get_base_stats() -> Stats:
	return template.base_stats

func get_all_modifiers() -> Array[StatModifier]:
	var mods: Array[StatModifier] = []
	mods.append_array(modifiers)
	mods.append_array(extra_modifiers)
	
	return mods

func get_all_effects() -> Array[Effect]:
	var mods: Array[Effect] = []
	mods.append_array(effects)
	mods.append_array(extra_effects)
	
	return mods

func to_dict() -> Dictionary:
	var mods: Array[String] = []
	
	for mod: StatModifier in modifiers:
		mods.append(mod.id)
	
	return {
		"resource": self.template.id,
		"modifiers": mods
	}
	
static func from_dict(dict: Dictionary) -> GearInstance:
	var res := ItemsRegistry.get_item(dict.get("resource"))
	var inst := GearInstance.new(res)
	
	var mods: Array[String] = dict.get("modifiers")
	
	for id: String in mods:
		var mod: StatModifier = StatModifierRegistry.get_modifier(id)
		
		if mod:
			inst.modifiers.append(mod)
	
	return inst
