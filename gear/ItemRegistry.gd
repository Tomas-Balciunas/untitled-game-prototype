extends Node

const GEAR := "GEAR"

const WOOD := "WOOD"
const IRON := "IRON"

var items := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths: Array[String] = [
	]
	
	for path in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_item(res)

func register_item(item: Item) -> void:
	if item.id in items:
		push_warning("Duplicate item id: %s" % item.id)
	items[item.id] = item

func get_item(id: String) -> Item:
	if items.has(id):
		return items[id]
	return null

func get_all_items() -> Array:
	return items.values()

func get_rand_template(tier: String, type: Item.ItemType) -> Gear:
	#if !templates.has(tier):
		#return null
		#
	#if !templates[tier].has(type):
		#return null
	#
	#var gear = templates[tier][type]
	#var rand := randi() % len(gear)
	#
	#return gear[rand]
	
	var candidates := []
	for item: Item in items.values():
		if item is Gear and item.tier == tier and item.type == type:
			candidates.append(item)
	
	if candidates.is_empty():
		push_warning("No templates found for tier %s type %s" % [tier, type])
		return null
	
	return candidates.pick_random()
