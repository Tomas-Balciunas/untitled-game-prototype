extends Gear
class_name RingResource


func _init() -> void:
	type = Item.ItemType.RING
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Ring:
	var ring: Ring = Ring.new()
	ring.id = id
	ring.item_name = name
	ring.type = type
	ring.quality = quality
	ring.item_description = description
	ring.stats = base_stats.duplicate(true)
	ring.base_stats = ring.stats.duplicate(true)
	ring.base_effects = effects.duplicate(true)
	ring.base_modifiers = modifiers.duplicate(true)
	
	return ring


func get_applicable_stat_modifiers() -> Array[Stats.StatRef]:
	return [Stats.StatRef.SP, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
