extends PassiveEffect

class_name AttackBuffOnSkillUse

var mod: StatModifier
var active_mod: StatModifier = null

func _init() -> void:
	mod = StatModifier.new()
	mod.value = 5
	mod.stat = Stats.StatRef.ATTACK
	mod.type = StatModifier.Type.ADDITIVE
	show_in_status = true
	native = false
	single_instance = true
	battle_only = true
	expires_after_battle = true
	id = "priest_att_buff"

func on_apply() -> void:
	var existing_buff: AttackBuffOnSkillUse = owner.get_effect_by_id(id)
	
	if existing_buff and existing_buff is AttackBuffOnSkillUse:
		existing_buff.active_mod.value = existing_buff.active_mod.value * 2
		StatCalculator.recalculate_all_stats(owner)
	else:
		active_mod = mod.duplicate()
		owner.state.add_modifier(active_mod)
		StatCalculator.recalculate_all_stats(owner)

func listened_triggers() -> Array:
	return [EffectTriggers.ON_POST_SKILL_USE]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_actor(event)

func on_trigger(stage: String, _event: TriggerEvent) -> void:
	pass
	
	#if stage == EffectTriggers.ON_POST_SKILL_USE:
		#if active_mod:
			#_event.actor.character.state.remove_modifier(active_mod)
			#StatCalculator.recalculate_all_stats(_event.actor.character)
