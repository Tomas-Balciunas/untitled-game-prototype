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
	chestpiece.type = type
	chestpiece.quality = quality
	chestpiece.item_description = description
	chestpiece.stats = base_stats.duplicate(true)
	chestpiece.base_stats = chestpiece.stats.duplicate(true)
	chestpiece.base_effects = effects.duplicate(true)
	chestpiece.base_modifiers = modifiers.duplicate(true)
	
	return chestpiece


func get_applicable_stat_modifiers() -> Array[Stats.StatRef]:
	return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
