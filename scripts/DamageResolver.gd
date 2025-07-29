extends Node
class_name DamageManager

signal damage_resolved(ctx: DamageContext)

func apply_attack(action: AttackAction) -> DamageContext:
	return _apply_core(
		action.attacker,
		action.defender,
		action.type,
		action.base_value,
		[],
		action.options
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
		skill.effects,				# additional skill effects
		skill.options
	)

func _apply_core(source: CharacterInstance, target: CharacterInstance, damage_type: DamageTypes.Type, base: float, extra_effects: Array[Effect], options: Dictionary = {}) -> DamageContext:
	var ctx = DamageContext.new()
	ctx.source    = source
	ctx.target    = target
	ctx.type        = damage_type
	ctx.base_value  = base
	ctx.final_value = base
	ctx.tags        = extra_effects
	ctx.options = options
	
	# attacker’s effects
	source.process_effects(EffectTriggers.ON_HIT, ctx)
	#print("After attacker effects: %d" % ctx.final_value)
	
	# skill effects
	for e in extra_effects:
		if e.has_method("on_trigger"):
			e.on_trigger(EffectTriggers.ON_HIT, ctx)
	#print("After attacker skill: %d" % ctx.final_value)
	
	# defender’s effects
	target.process_effects(EffectTriggers.ON_RECEIVE_DAMAGE, ctx)
	
	var defense_ignore = 0
	if ctx.has_meta("ignore_defense_percent"):
		defense_ignore = ctx.get_meta("ignore_defense_percent")

	

	
	var calculator = DamageCalculator.new(ctx, defense_ignore)
	ctx.final_value = max(calculator.get_final_damage(), 0)
	BattleEventBus.emit_signal("damage_about_to_be_applied", ctx)
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [ctx.source.resource.name, ctx.final_value, DamageTypes.to_str(ctx.type), ctx.target.resource.name])
	target.set_current_health(target.stats.current_health - ctx.final_value)
	BattleEventBus.emit_signal("damage_applied", ctx)
	emit_signal("damage_resolved", ctx)

	# post‑hit effects
	for e in extra_effects:
		if e.has_method("on_trigger"):
			e.on_trigger(EffectTriggers.ON_POST_HIT, ctx)
	
	if ctx.has_meta("counterattack"):
		var counter_target = ctx.get_meta("counterattack")
		var revenge = AttackAction.new()
		revenge.attacker = ctx.target
		revenge.defender = counter_target
		revenge.type = ctx.target.damage_type
		revenge.base_value = ctx.target.stats.attack
		BattleTextLines.print_line("%s counterattacks!" % ctx.target.resource.name)
		self.apply_attack(revenge)

	return ctx
