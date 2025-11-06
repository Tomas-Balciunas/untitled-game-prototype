extends Effect

class_name DamageAccumulatorAttack

var accumulator: int = 0
const THRESHOLD: int = 20 

func _init() -> void:
	name = "Lash"
	description = "Damage is accumulated, upon reaching a certain threshold the next attack unleashes the accumulated damage"

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]
	
func can_process(_event: TriggerEvent) -> bool:
	return _event.ctx.target == owner or (_event.actor == owner and _event.ctx.target != owner)

func on_trigger(_event: TriggerEvent) -> void:
	if _event.ctx.target == owner:
		accumulator += _event.ctx.final_value
		BattleTextLines.print_line("Accumulated %s, total: %s" % [_event.ctx.final_value, accumulator])
		return
	
	if _event.actor == owner and _event.ctx.target != owner:
		if accumulator < THRESHOLD:
			return
		
		var tgt: CharacterInstance = _event.ctx.target
		var adjacent := BattleContext.manager.get_applicable_targets(tgt, TargetingManager.TargetType.ADJACENT)
		
		
		
		BattleTextLines.print_line("Lash activated!")
		
		for t: CharacterInstance in adjacent:
			var lash_ctx := DamageContext.new()
			lash_ctx.base_value = tgt.stats.get_final_stat(Stats.ATTACK) + accumulator
			lash_ctx.final_value = tgt.stats.get_final_stat(Stats.ATTACK) + accumulator
			lash_ctx.actively_cast = false
			lash_ctx.source = owner
			lash_ctx.target = t
			DamageResolver.new().execute(lash_ctx)
		
		accumulator = 0
		
		
