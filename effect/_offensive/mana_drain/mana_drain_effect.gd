extends PassiveEffect

class_name ManaDrainEffect

@export var amount: float = 0.1

func listened_triggers() -> Array:
	return [EffectTriggers.ON_APPLY_EFFECT]
	
func can_process(event: TriggerEvent) -> bool:
	return owner == event.ctx.target



func on_trigger(event: TriggerEvent) -> void:
	var current_mana := event.ctx.target.state.current_mana
	var new_mana := floori(current_mana * (1 - amount))
	event.ctx.target.set_current_mana(new_mana)
	
	BattleTextLines.print_line(
		"%s drains %s mana from %s!" %
		[event.ctx.source.resource.name, current_mana - new_mana, event.ctx.target.resource.name]
	)
