extends Effect

class_name ManaDrainEffect

@export var amount: float = 0.1

func listened_triggers() -> Array:
	return [EffectTriggers.ON_APPLY_EFFECT]
	
func can_process(event: TriggerEvent) -> bool:
	return owner == event.ctx.target
	
func on_apply(new_owner: CharacterInstance) -> void:
	_is_runtime_instance = true
	owner = new_owner

	_register_if_needed()

func on_expire(_owner: CharacterInstance) -> void:
	_unregister()
	owner = null

func on_trigger(event: TriggerEvent) -> void:
	var current_mana := event.ctx.target.stats.current_mana
	var new_mana := floori(current_mana * (1 - amount))
	event.ctx.target.set_current_mana(new_mana)
	
	BattleTextLines.print_line(
		"%s drains %s mana from %s!" %
		[event.ctx.source.resource.name, current_mana - new_mana, event.ctx.target.resource.name]
	)
