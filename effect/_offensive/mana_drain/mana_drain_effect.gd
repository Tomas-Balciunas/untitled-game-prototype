extends PassiveEffect

class_name ManaDrainEffect

@export var amount: float = 0.1


func listened_triggers() -> Array:
	return [EffectTriggers.ON_APPLY_EFFECT]

func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.OWNER_IS_TARGET

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true


func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var current_mana: int = event.target.state.current_mana
	var new_mana := floori(current_mana * (1 - amount))
	event.target.set_current_mana(new_mana)
	
	BattleTextLines.print_line(
		"%s drains %s mana from %s!" %
		[event.ctx.source.get_source_name(), current_mana - new_mana, event.target.resource.name]
	)

func _get_name() -> String:
	return "Mana Drain"

func get_description() -> String:
	return "Drains a portion of mana"
