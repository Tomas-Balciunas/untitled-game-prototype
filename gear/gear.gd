@abstract
extends Item
class_name Gear

var enhancement_level: int = 0

var quality: ItemTypes.Quality = ItemTypes.Quality.COMMON

var stats: Stats
var base_stats: Stats

var base_effects: Array[Effect] = []
var base_modifiers: Array[StatModifier] = []

var extra_modifiers: Array[StatModifier] = []
var extra_effects: Array[Effect] = []


func get_base_stats() -> Stats:
	return base_stats

func get_all_modifiers() -> Array[StatModifier]:
	return base_modifiers + extra_modifiers

func get_all_effects() -> Array[Effect]:
	return base_effects + extra_effects


static func _modifier_to_dict(mod: StatModifier) -> Dictionary:
	return {
		"id": mod.id,
		"name": mod.name,
		"stat": mod.stat,
		"type": mod.type,
		"value": mod.value,
		"priority": mod.priority,
	}


static func _modifier_from_dict(mod_data: Dictionary) -> StatModifier:
	var mod := StatModifier.new()
	mod.id = mod_data.get("id", "")
	mod.name = mod_data.get("name", "")
	mod.stat = mod_data.get("stat", 0) as Stats.StatRef
	mod.type = mod_data.get("type", 0) as StatModifier.Type
	mod.value = mod_data.get("value", 0.0)
	mod.priority = mod_data.get("priority", 0)
	return mod


static func _effects_to_dicts(arr: Array[Effect]) -> Array:
	var out: Array = []
	for e: Effect in arr:
		out.append(e.game_save())
	return out


static func _effects_from_dicts(dicts: Array) -> Array[Effect]:
	var arr: Array[Effect] = []
	for entry: Dictionary in dicts:
		var eff := Effect.create_from_save(entry)
		if eff == null:
			continue
		eff.game_load(entry)
		arr.append(eff)
	return arr


func game_save() -> Dictionary:
	var base_mods: Array = []
	for mod: StatModifier in base_modifiers:
		base_mods.append(_modifier_to_dict(mod))

	var extra_mods: Array = []
	for mod: StatModifier in extra_modifiers:
		extra_mods.append(_modifier_to_dict(mod))

	return {
		"class":             get_class(),
		"id":                id,
		"name":              item_name,
		"description":       item_description,
		"type":              type,
		"value":             value,
		"quality":           quality,
		"enhancement_level": enhancement_level,
		"stats":             stats.game_save() if stats else {},
		"base_modifiers":    base_mods,
		"extra_modifiers":   extra_mods,
		"base_effects":      _effects_to_dicts(base_effects),
		"extra_effects":     _effects_to_dicts(extra_effects),
	}


func game_load(data: Dictionary) -> void:
	id                = data.get("id", "")
	item_name         = data.get("name", "")
	item_description  = data.get("description", "")
	type              = data.get("type", 0) as ItemTypes.ItemType
	value             = data.get("value", 0)
	quality           = data.get("quality", 0)
	enhancement_level = data.get("enhancement_level", 0)

	stats = Stats.new()
	if data.has("stats"):
		stats.game_load(data["stats"])
	base_stats = stats.duplicate(true)

	base_modifiers = []
	for mod_data: Dictionary in data.get("base_modifiers", data.get("modifiers", [])):
		base_modifiers.append(_modifier_from_dict(mod_data))

	extra_modifiers = []
	for mod_data: Dictionary in data.get("extra_modifiers", []):
		extra_modifiers.append(_modifier_from_dict(mod_data))

	base_effects = _effects_from_dicts(data.get("base_effects", []))
	extra_effects = _effects_from_dicts(data.get("extra_effects", []))


static func create_from_save(data: Dictionary) -> Gear:
	var item: Gear
	match data.get("class", ""):
		"Weapon":     item = Weapon.new()
		"Chestpiece": item = Chestpiece.new()
		"Helmet":     item = Helmet.new()
		"Boots":      item = Boots.new()
		"Gloves":     item = Gloves.new()
		"Ring":       item = Ring.new()
		"Amulet":     item = Amulet.new()
		_:
			push_error("Gear.create_from_save: unknown class '%s'" % data.get("class", ""))
			return null
	item.game_load(data)
	return item

@abstract
func get_gear_type() -> ItemTypes.GearType
