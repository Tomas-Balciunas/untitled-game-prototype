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


func game_save() -> Dictionary:
	var mod_arr: Array = []
	for mod: StatModifier in base_modifiers:
		mod_arr.append({ "stat": mod.stat, "type": mod.type, "value": mod.value })
	return {
		"class":    get_class(),
		"id":       id,
		"name":     item_name,
		"type":     type,
		"quality":  quality,
		"stats":    stats.game_save(),
		"modifiers": mod_arr,
	}


func game_load(data: Dictionary) -> void:
	id        = data.get("id", "")
	item_name = data.get("name", "")
	type      = data.get("type", 0) as ItemTypes.ItemType
	quality   = data.get("quality", 0)

	stats = Stats.new()
	if data.has("stats"):
		stats.game_load(data["stats"])
	base_stats = stats.duplicate(true)

	base_modifiers = []
	for mod_data: Dictionary in data.get("modifiers", []):
		var mod := StatModifier.new()
		mod.stat  = mod_data.get("stat", 0) as Stats.StatRef
		mod.type  = mod_data.get("type", 0) as StatModifier.Type
		mod.value = mod_data.get("value", 0.0)
		base_modifiers.append(mod)


static func from_dict(data: Dictionary) -> Gear:
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
			push_error("Gear.from_dict: unknown class '%s'" % data.get("class", ""))
			return null
	item.game_load(data)
	return item

@abstract
func get_gear_type() -> ItemTypes.GearType
