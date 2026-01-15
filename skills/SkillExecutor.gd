extends RefCounted

class_name SkillExecutor

var skill: Skill = null
var caster: CharacterInstance = null
var initial_target: CharacterInstance = null

func _init(s: Skill, c: CharacterInstance, t: CharacterInstance) -> void:
	skill = s
	caster = c
	initial_target = t


func execute() -> void:
	var source: SkillSource = SkillSource.new(caster, skill)
	
	var ctx: SkillContext = build_context(source)
	SkillResolver.new().execute(ctx)


func build_context(source: SkillSource) -> SkillContext:
	var ctx := SkillContext.new()
	ctx.skill = skill
	ctx.cost = skill.compute_cost(caster)
	ctx.actively_cast = true
	ctx.source = source
	ctx.initial_target = initial_target
	ctx.targets = TargetingManager.get_applicable_targets(initial_target, skill.targeting_type)
	ctx.temporary_effects = skill.effects
	
	return ctx
