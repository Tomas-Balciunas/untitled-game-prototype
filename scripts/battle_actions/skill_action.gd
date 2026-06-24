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

	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(actor)
	ctx.set_targets(target, targets)
	ctx.actively_cast = true
	ctx.temporary_effects = skill.effects

	return ctx


func perform(ctx: ActionContext, actor: Character, attacker_slot: FormationSlot, target_slot: FormationSlot) -> void:
	var resolver: SkillResolver = SkillResolver.new(skill)
	var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, ctx, resolver)

	await orchestrator.execute_action(
		func (e: ActionEvent) -> void:
			attacker_slot.perform_skill(e, skill.animation_name, target_slot),
		"skill %s" % skill.name
	)
