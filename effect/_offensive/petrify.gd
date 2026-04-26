extends ControlEffect

class_name PetrifyEffect

@export var damage_reduction: float = 0.7

var turns_lasted: int = 0


func on_apply() -> void:
	BattleTextLines.print_line("%s is petrified!" % owner.resource.name)


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START, EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE, EffectTriggers.ON_TURN_END]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	if event is DamageInstance:
		return (event as DamageInstance).target == owner or event.actor.get_actor() == owner
	return owner == event.actor.get_actor()


func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_TURN_START:
		event.ctx.skip_turn = true
		return

	if stage == EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE:
		var dmg := event as DamageInstance
		if dmg.calculator.type == DamageTypes.Type.PHYSICAL:
			dmg.calculator.final_damage *= (1.0 - damage_reduction)
		return

	if stage == EffectTriggers.ON_TURN_END:
		var r := randf()
		var v := float(turns_lasted) / 12.0
		if r <= v:
			BattleTextLines.print_line("%s breaks free from petrification!" % owner.resource.name)
			owner.remove_effect(self)
			return
		turns_lasted += 1
