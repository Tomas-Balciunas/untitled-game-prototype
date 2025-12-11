extends Gear
class_name BootsResource


func _init() -> void:
	type = Item.ItemType.BOOTS
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Boots:
	var boots: Boots = Boots.new()
	boots.id = id
	boots.item_name = name
	boots.item_description = description
	boots.stats = base_stats.duplicate(true)
	boots.base_stats = boots.stats.duplicate(true)
	boots.base_effects = effects.duplicate(true)
	boots.base_modifiers = modifiers.duplicate(true)
	
	return boots
