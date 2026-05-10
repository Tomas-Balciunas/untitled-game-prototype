extends PassiveEffect
class_name DamageShare

@export var share_percent: float = 0.10

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	if BattleContext.in_battle:
		if not TargetingManager.same_side(owner, event.target):
			return false
	
	return !owner_is_target(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var dmg: DamageInstance = event as DamageInstance
	var damaged := dmg.target
	var transfer := ceili(dmg.calculator.get_final_damage() * share_percent)
	dmg.calculator.final_damage = floori(dmg.calculator.final_damage - transfer)
	
	owner.set_current_health(owner.state.current_health - transfer)
	
	BattleTextLines.print_line(
		"%s absorbs %d damage for %s!" %
		[owner.resource.name, transfer, damaged.resource.name]
	)
