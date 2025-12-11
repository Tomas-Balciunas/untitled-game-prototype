extends Gear
class_name ChestpieceResource


func _init() -> void:
	type = Item.ItemType.CHEST
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Chestpiece:
	var chestpiece: Chestpiece = Chestpiece.new()
	chestpiece.id = id
	chestpiece.item_name = name
	chestpiece.item_description = description
	chestpiece.stats = base_stats.duplicate(true)
	chestpiece.base_stats = chestpiece.stats.duplicate(true)
	chestpiece.base_effects = effects.duplicate(true)
	chestpiece.base_modifiers = modifiers.duplicate(true)
	
	return chestpiece
