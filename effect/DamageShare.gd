extends Effect
class_name DamageShare

@export var share_percent: float = 0.10

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED]

func on_trigger(event: TriggerEvent) -> void:
	var damaged = event.ctx.target
	
	if damaged == owner:
		return
	if owner.is_dead:
		return
	
	var transfer = ceil(event.ctx.final_value * share_percent)
	var final = floor(event.ctx.final_value - transfer)
	event.ctx.final_value = final
	owner.set_current_health(owner.stats.current_health - transfer)
	BattleTextLines.print_line(
		"%s absorbs %d damage for %s!" %
		[owner.resource.name, transfer, damaged.resource.name]
	)
