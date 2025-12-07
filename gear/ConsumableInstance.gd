extends ItemInstance
class_name ConsumableInstance

var effects: Array[Effect] = []

func _init(item: ConsumableItem) -> void:
	template = item
	effects = []
	
	for e in item.effects:
		effects.append(e.duplicate(true))

func use_item(user: CharacterInstance, item: ConsumableInstance) -> void:
	var ctx := ConsumableContext.new()
	ctx.source = ItemSource.new(user, item)
	ctx.target = user
	ctx.consumable = item
	ctx.actively_cast = true
	ctx.temporary_effects = effects
	
	ConsumableResolver.new().execute(ctx)
	user.inventory.remove_item(item)

func get_all_effects() -> Array[Effect]:
	return effects

func to_dict() -> Dictionary:
	return {
		"resource": template.id,
	}
	
static func from_dict(dict: Dictionary) -> ConsumableInstance:
	var res := ItemsRegistry.get_item(dict.get("resource"))
	var inst := ConsumableInstance.new(res)
	
	return inst
