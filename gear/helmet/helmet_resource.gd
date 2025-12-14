extends Gear
class_name HelmetResource


func _init() -> void:
	type = Item.ItemType.HELMET
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Helmet:
	var helmet: Helmet = Helmet.new()
	helmet.id = id
	helmet.item_name = name
	helmet.type = type
	helmet.quality = quality
	helmet.item_description = description
	helmet.stats = base_stats.duplicate(true)
	helmet.base_stats = helmet.stats.duplicate(true)
	helmet.base_effects = effects.duplicate(true)
	helmet.base_modifiers = modifiers.duplicate(true)
	
	return helmet


func get_applicable_stat_modifiers() -> Array[Stats.StatRef]:
	return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
