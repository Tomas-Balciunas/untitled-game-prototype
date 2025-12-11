extends Gear
class_name AmuletResource


func _init() -> void:
	type = Item.ItemType.AMULET
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Amulet:
	var amulet: Amulet = Amulet.new()
	amulet.id = id
	amulet.item_name = name
	amulet.item_description = description
	amulet.stats = base_stats.duplicate(true)
	amulet.base_stats = amulet.stats.duplicate(true)
	amulet.base_effects = effects.duplicate(true)
	amulet.base_modifiers = modifiers.duplicate(true)
	
	return amulet
