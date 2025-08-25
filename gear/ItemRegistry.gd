extends Node
class_name ItemRegistry

var items := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths = [
		"res://gear/chest/armor.tres",
		"res://gear/consumable/hp pot minor/hp_pot.tres",
		"res://gear/consumable/poison flask minor/poison_flask.tres",
		"res://gear/ring/ring1.tres",
		"res://gear/ring/ring2.tres",
		"res://gear/weapon/wooden_sword.tres",
	]
	
	for path in res_paths:
		var res = ResourceLoader.load(path)
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
