extends DebuffEffect
class_name ConfusionEffect

var turns_lasted: int = 0


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START, EffectTriggers.ON_TURN_END]
	
func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()
	
func on_apply() -> void:
	is_battle_only = true
	BattleTextLines.print_line("%s is confused!" % owner.resource.name)

	
func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_TURN_START:
		event.ctx.force_action = true
		event.ctx.target = BattleContext.manager.battlers.pick_random()
	
	if stage == EffectTriggers.ON_TURN_END:
		var r: float = randf()
		var v: float = float(turns_lasted) / 10
		if r <= v:
			BattleTextLines.print_line("%s has recovered from confusion!" % owner.resource.name)
			owner.remove_effect(self)
			
			return
			
		turns_lasted += 1
