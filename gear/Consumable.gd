extends Item
class_name Consumable

var effects: Array[Effect] = []
var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE


func use_item(user: Character) -> void:
	var ctx := ConsumableContext.new()
	ctx.source = ItemSource.new(user, self)
	ctx.set_targets(user)
	ctx.actively_cast = true
	ctx.temporary_effects = effects

	## TODO: fix targeting
	ConsumableResolver.new(self).execute(ctx)
	user.inventory.remove_item(self)

func get_all_effects() -> Array[Effect]:
	return effects

func game_save() -> Dictionary:
	var effect_arr: Array = []
	for effect: Effect in effects:
		effect_arr.append(effect.game_save())

	return {
		"class": "Consumable",
		"id": id,
		"name": item_name,
		"description": item_description,
		"type": type,
		"targeting_type": targeting_type,
		"effects": effect_arr,
	}


func game_load(data: Dictionary) -> void:
	id = data.get("id", "")
	item_name = data.get("name", "")
	item_description = data.get("description", "")
	type = data.get("type", ItemTypes.ItemType.CONSUMABLE) as ItemTypes.ItemType
	targeting_type = data.get("targeting_type", TargetingManager.TargetType.SINGLE) as TargetingManager.TargetType

	effects = []
	for entry: Dictionary in data.get("effects", []):
		var eff := Effect.create_from_save(entry)
		if eff == null:
			continue
		eff.game_load(entry)
		effects.append(eff)
