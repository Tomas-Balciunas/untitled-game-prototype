extends Effect
class_name DamageShare

@export var share_percent: float = 0.10

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED]
	
func can_process(event: TriggerEvent) -> bool:
	if BattleContext.in_battle:
		if not BattleContext.manager.same_side(owner, event.ctx.target):
			return false
	return event.ctx.target != owner and not owner.is_dead

func on_trigger(event: TriggerEvent) -> void:
	var damaged = event.ctx.target
	var transfer = ceil(event.ctx.final_value * share_percent)
	var final = floor(event.ctx.final_value - transfer)
	event.ctx.final_value = final
	owner.set_current_health(owner.stats.current_health - transfer)
	BattleTextLines.print_line(
		"%s absorbs %d damage for %s!" %
		[owner.resource.name, transfer, damaged.resource.name]
	)
