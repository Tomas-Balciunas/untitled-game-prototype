extends Skill

class_name AttackSkill

@export var modifier: float = 1.0
@export var damage_type: DamageTypes.Type
## only matters when bounce targeting is selected
@export var bounce_instances: int = 0

func build_context(skill_ctx: SkillContext) -> DamageContext:
	var actor: CharacterInstance = skill_ctx.source.get_actor()
	var damage: float = actor.stats.attack * modifier
	
	var ctx: DamageContext = DamageContext.new(damage)
	ctx.source = skill_ctx.source
	ctx.initial_target = skill_ctx.initial_target
	ctx.targets = skill_ctx.targets
	ctx.temporary_effects = effects
	ctx.actively_cast = true
	
	return ctx

func get_resolver() -> DamageResolver:
	return DamageResolver.new()
