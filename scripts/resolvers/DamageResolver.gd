extends Node

signal damage_resolved(ctx: DamageContext)

func apply_attack(action: AttackAction) -> DamageContext:
	return await _apply_core(
		action.attacker,
		action.defender,
		action.type,
		action.base_value,
		[],
		action.actively_cast,
		action.options
	)

func apply_skill(skill: SkillAction) -> DamageContext:
	var calculated_damage = skill.attacker.stats.attack
	# apply skill modifier to attacker's att power
	if skill.modifier != 0.0:
		calculated_damage += calculated_damage * skill.modifier
	
	return await _apply_core(
		skill.attacker, 				# char inst
		skill.defender, 				# char inst
		skill.skill.damage_type,		# dmg element, overrides attacker's element
		calculated_damage,			# attacker's power * skill modifier
		skill.effects,				# additional skill effects
		skill.actively_cast,
		skill.options
	)

func _apply_core(source: CharacterInstance, target: CharacterInstance, damage_type: DamageTypes.Type, base: float, extra_effects: Array[Effect], actively_cast: bool, options: Dictionary = {}) -> DamageContext:
	var ctx = DamageContext.new()
	ctx.source   		= source
	ctx.target    		= target
	ctx.type        	= damage_type
	ctx.base_value  	= base
	ctx.final_value 	= base
	ctx.tags        	= extra_effects
	ctx.options 		= options
	ctx.actively_cast 	= actively_cast
	
	var event = TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	event.trigger = EffectTriggers.ON_HIT
	if ctx.tags:
		event.tags = ctx.tags
	
	# attacker’s effects
	EffectRunner.process_trigger(event)
	
	# defender’s effects
	event.trigger = EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE
	EffectRunner.process_trigger(event)
	
	var defense_ignore = 0
	if ctx.has_meta("ignore_defense_percent"):
		defense_ignore = ctx.get_meta("ignore_defense_percent")
	
	var calculator = DamageCalculator.new(ctx, defense_ignore)
	ctx.final_value = max(calculator.get_final_damage(), 0)
	
	BattleEventBus.before_receive_damage.emit(ctx)
	await BattleFlow.wait_if_paused()
	event.trigger = EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED
	EffectRunner.process_trigger(event)
	
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [ctx.source.resource.name, ctx.final_value, DamageTypes.to_str(ctx.type), ctx.target.resource.name])
	target.set_current_health(target.stats.current_health - ctx.final_value)
	if target.is_dead:
		event.trigger = EffectTriggers.ON_DEATH
		EffectRunner.process_trigger(event)
		return ctx
	
	event.trigger = EffectTriggers.ON_DAMAGE_APPLIED
	EffectRunner.process_trigger(event)
	
	emit_signal("damage_resolved", ctx)
	
	if event.ctx.has_meta("counterattack"):
		var counter_target = ctx.get_meta("counterattack")
		var revenge = AttackAction.new()
		revenge.attacker = ctx.target
		revenge.defender = counter_target
		revenge.type = ctx.target.damage_type
		revenge.base_value = ctx.target.stats.attack
		revenge.actively_cast = false #important, setting it to false would not trigger counterattack chain
		BattleContext.manager.action_queue.append(revenge)
		BattleTextLines.print_line("%s counterattacks!" % revenge.attacker.resource.name)
	return ctx
