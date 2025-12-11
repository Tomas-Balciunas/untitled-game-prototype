extends ItemInstance
class_name Consumable

var effects: Array[Effect] = []
var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE


func use_item(user: CharacterInstance) -> void:
	var ctx := ConsumableContext.new()
	ctx.source = ItemSource.new(user, self)
	ctx.target = user
	ctx.consumable = self
	ctx.actively_cast = true
	ctx.temporary_effects = effects
	
	## TODO: fix targeting
	ConsumableResolver.new().execute(ctx)
	user.inventory.remove_item(self)

func get_all_effects() -> Array[Effect]:
	return effects

func game_save() -> Dictionary:
	return {}


func game_load(_data: Dictionary) -> void:
	pass
