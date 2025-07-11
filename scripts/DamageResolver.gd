extends Node
class_name DamageManager

signal damage_resolved(ctx: DamageContext)

func apply_attack(action: AttackAction) -> DamageContext:
	return _apply_core(
		action.attacker,
		action.defender,
		action.type,
		action.base_value,
		[]
	)

func apply_skill(action: SkillAction) -> DamageContext:
	return _apply_core(
		action.attacker,
		action.defender,
		action.type,
		action.base_value,
		action.effects
	)

func _apply_core(attacker: CharacterInstance, defender: CharacterInstance, damage_type: DamageTypes.Type, base: int, extra_effects: Array[Effect]) -> DamageContext:
	var ctx = DamageContext.new()
	ctx.attacker    = attacker
	ctx.defender    = defender
	ctx.type        = damage_type
	ctx.base_value  = base
	ctx.is_critical = false
	ctx.final_value = base
	ctx.tags        = extra_effects

	var damage_type_str = DamageTypes.to_str(ctx.type)
	
	# 1) Attacker’s passives & buffs
	attacker.process_effects("on_pre_hit", ctx)
	#print("After attacker effects: %d" % ctx.final_value)
	
	# 2) Skill‑specific effects (e.g. defense ignore)
	for e in extra_effects:
		if e.has_method("on_trigger"):
			e.on_trigger("on_skill_pre_hit", ctx)
	#print("After attacker skill: %d" % ctx.final_value)
	
	# 3) Defender’s passives & defenses
	defender.process_effects("on_receive_damage", ctx)

	# 4) Clamp & apply
	ctx.final_value = max(ctx.final_value, 0)

	defender.set_current_health(defender.current_health - ctx.final_value)

	emit_signal("damage_resolved", ctx)

	# 5) Post‑hit skill effects (e.g. poison)
	for e in extra_effects:
		if e.has_method("on_trigger"):
			e.on_trigger("on_post_hit", ctx)

	return ctx
