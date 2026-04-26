extends ControlEffect

class_name SilenceEffect

var turns_lasted: int = 0


func on_apply() -> void:
	BattleTextLines.print_line("%s is silenced!" % owner.resource.name)


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	var r := randf()
	var v := float(turns_lasted) / 8.0
	if r <= v:
		BattleTextLines.print_line("%s can speak again!" % owner.resource.name)
		owner.remove_effect(self)
		return
	turns_lasted += 1


func _modifies_skill_cost() -> bool:
	return true


func modify_skill_cost(_skill: Skill, sc: SkillCost) -> SkillCost:
	sc.mana = 999999
	sc.sp = 999999
	return sc
