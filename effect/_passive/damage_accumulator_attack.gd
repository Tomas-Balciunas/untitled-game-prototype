extends PassiveEffect

class_name DamageAccumulatorAttack

var accumulator: int = 0
const THRESHOLD: int = 10 

func _init() -> void:
	name = "Lash"
	description = "Damage is accumulated, upon reaching a certain threshold the next attack unleashes the accumulated damage"

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]
	
func can_process(_stage: String, event: TriggerEvent) -> bool:
	if !event is DamageTriggerEvent:
		return false
	
	return event.target == owner or (event.actor.get_actor() == owner and event.target != owner)

func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	var event: DamageTriggerEvent = _event
	
	if event.target == owner:
		accumulator += event.calculator.final_value
		BattleTextLines.print_line("Accumulated %s, total: %s" % [event.calculator.get_final_damage(), accumulator])
		if accumulator >= THRESHOLD:
			BattleTextLines.print_line("Lash will be unleashed!")
		return
	
	if event.actor.get_actor() == owner and event.target != owner:
		if _event.ctx.actively_cast == false:
			return
		
		if accumulator <= THRESHOLD:
			return
		
		var tgt: CharacterInstance = event.target
		var adjacent := TargetingManager.get_applicable_targets(tgt, TargetingManager.TargetType.ADJACENT)
		
		BattleTextLines.print_line("Lash activated!")
		var resolver := DamageResolver.new(accumulator)
		var lash_ctx: ActionContext = ActionContext.new()
		lash_ctx.actively_cast = false
		lash_ctx.source = CharacterSource.new(owner)
		lash_ctx.set_targets(tgt, adjacent)
		resolver.execute(lash_ctx)
		
		accumulator = 0
		
