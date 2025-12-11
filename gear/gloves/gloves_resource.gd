extends Gear
class_name GlovesResource


func _init() -> void:
	type = Item.ItemType.GLOVES
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Gloves:
	var gloves: Gloves = Gloves.new()
	gloves.id = id
	gloves.item_name = name
	gloves.item_description = description
	gloves.stats = base_stats.duplicate(true)
	gloves.base_stats = gloves.stats.duplicate(true)
	gloves.base_effects = effects.duplicate(true)
	gloves.base_modifiers = modifiers.duplicate(true)
	
	return gloves
