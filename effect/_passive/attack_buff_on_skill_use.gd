extends PassiveEffect

class_name AttackBuffOnSkillUse

var mod: StatModifier
var active_mod: StatModifier = null

func _init() -> void:
	mod = StatModifier.new()
	mod.value = 5
	mod.stat = Stats.StatRef.ATTACK
	mod.type = StatModifier.Type.ADDITIVE

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_SKILL_USE, EffectTriggers.ON_POST_SKILL_USE]
	
func can_process(_event: TriggerEvent) -> bool:
	return _event.actor.character == owner

func on_trigger(_event: TriggerEvent) -> void:
	if _event.trigger == EffectTriggers.ON_BEFORE_SKILL_USE:
		active_mod = mod.duplicate()
		_event.actor.character.stats.add_modifier(active_mod)
		_event.actor.character.stats.recalculate_stats()
	
	if _event.trigger == EffectTriggers.ON_POST_SKILL_USE:
		active_mod = mod.duplicate()
		_event.actor.character.stats.remove_modifier(active_mod)
		_event.actor.character.stats.recalculate_stats()
