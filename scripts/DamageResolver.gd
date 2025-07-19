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

func apply_skill(skill: SkillAction) -> DamageContext:
	var calculated_damage = skill.attacker.stats.attack
	# apply skill modifier to attacker's att power
	if skill.modifier != 0.0:
		calculated_damage += calculated_damage * skill.modifier
	
	return _apply_core(
		skill.attacker, 				# char inst
		skill.defender, 				# char inst
		skill.skill.damage_type,		# dmg element, overrides attacker's element
		calculated_damage,			# attacker's power * skill modifier
		skill.effects				# additional skill effects
	)

func _apply_core(attacker: CharacterInstance, defender: CharacterInstance, damage_type: DamageTypes.Type, base: float, extra_effects: Array[Effect]) -> DamageContext:
	var ctx = DamageContext.new()
	ctx.attacker    = attacker
	ctx.defender    = defender
	ctx.type        = damage_type
	ctx.base_value  = base
	ctx.is_critical = false
	ctx.final_value = base
	ctx.tags        = extra_effects
	
	# attacker’s effects
	attacker.process_effects(EffectTriggers.ON_HIT, ctx)
	#print("After attacker effects: %d" % ctx.final_value)
	
	# skill effects
	for e in extra_effects:
		if e.has_method("on_trigger"):
			e.on_trigger(EffectTriggers.ON_HIT, ctx)
	#print("After attacker skill: %d" % ctx.final_value)
	
	# defender’s effects
	defender.process_effects(EffectTriggers.ON_RECEIVE_DAMAGE, ctx)

	ctx.final_value = max(ctx.final_value, 0)

	print("%s received %f %s damage from %s" % [ctx.defender.resource.name, ctx.final_value, DamageTypes.to_str(ctx.type), ctx.attacker.resource.name])
	defender.set_current_health(defender.stats.current_health - ctx.final_value)

	emit_signal("damage_resolved", ctx)

	# post‑hit skill effects
	for e in extra_effects:
		if e.has_method("on_trigger"):
			e.on_trigger(EffectTriggers.ON_POST_HIT, ctx)

	return ctx
