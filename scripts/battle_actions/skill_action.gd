extends BattleAction
class_name SkillAction


var skill: Skill = null


func _init(_skill: Skill) -> void:
	assert(_skill)
	skill = _skill
	ends_turn = false
	action_point_cost = _skill.action_point_cost


func build_context(actor: Character, target: Character) -> ActionContext:
	var targets := TargetingManager.get_applicable_targets(target, skill.targeting_type)
	var weapon: Weapon = actor.equipment.weapon if actor.equipment.weapon else null

	var ctx := ActionContext.new()
	ctx.source = SkillSource.new(actor, skill)
	ctx.set_targets(target, targets)
	ctx.actively_cast = true
	ctx.temporary_effects = skill.effects
	ctx.targeting = skill.targeting_type
	
	if skill.uses_weapons_attack_rate and weapon != null:
		ctx.targeting = weapon.targeting

	return ctx


func perform(ctx: ActionContext, actor: Character, attacker_slot: FormationSlot, target_slot: FormationSlot, _event: BattleActionEvent) -> void:
	var resolver: SkillResolver = SkillResolver.new(skill)
	var weapon: Weapon = actor.equipment.weapon if actor.equipment.weapon else null
	
	var attack_rate: int = skill.attack_rate
	
	if skill.uses_weapons_attack_rate and weapon != null:
		attack_rate = weapon.attack_rate
	
	for i in range(attack_rate):
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, ctx, resolver)

		await orchestrator.execute_action(
			func (e: ActionEvent) -> void:
				attacker_slot.perform_skill(e, skill.animation_name, target_slot),
			"skill %s" % skill.name
		)
		
		if ctx.targeting == TargetingManager.TargetType.BOUNCE:
			var bounces: int = skill.bounce_instances
			
			if skill.uses_weapons_attack_rate and weapon != null:
				bounces = weapon.bounce_instances
			
			var launcher: BounceLauncher = BounceLauncher.new(resolver, ctx)
			await launcher.bounce(bounces, true)
		
		elif ctx.targeting == TargetingManager.TargetType.SALVO:
			var pellets: int = skill.salvo_pellets
			
			if skill.uses_weapons_attack_rate and weapon != null:
				pellets = weapon.salvo_pellets
			
			var launcher: SalvoLauncher = SalvoLauncher.new(resolver, ctx)
			launcher.shrapnel(pellets)
		
		await BattleContext.wait(0.2)
