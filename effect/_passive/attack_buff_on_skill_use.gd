extends PassiveEffect

class_name AttackBuffOnSkillUse

var mod: StatModifier

func _init() -> void:
	mod = StatModifier.new()
	mod.value = 5
	mod.stat = Stats.Stat.ATTACK
	mod.type = StatModifier.Type.ADDITIVE

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_SKILL_USE, EffectTriggers.ON_POST_SKILL_USE]
	
func can_process(_event: TriggerEvent) -> bool:
	return _event.actor.character == owner

func on_trigger(_event: TriggerEvent) -> void:
	if _event.trigger == EffectTriggers.ON_BEFORE_SKILL_USE:
		_event.actor.stats.add_modifier(mod)
		_event.actor.stats.recalculate_stats()
	
	if _event.trigger == EffectTriggers.ON_POST_SKILL_USE:
		_event.actor.stats.remove_modifier(mod)
		_event.actor.stats.recalculate_stats()
