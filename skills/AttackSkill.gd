extends Skill

class_name AttackSkill

@export var modifier: float = 1.0
@export var damage_type: DamageTypes.Type
## only matters when bounce targeting is selected
@export var bounce_instances: int = 0

func build_context(_source: SkillSource, _target: CharacterInstance) -> DamageContext:
	var ctx := DamageContext.new()
	ctx.base_value = _source.character.stats.attack * modifier
	ctx.final_value = _source.character.stats.attack * modifier
	ctx.source = _source
	ctx.target = _target
	ctx.temporary_effects = effects
	ctx.actively_cast = true
	
	return ctx

func get_resolver() -> DamageResolver:
	return DamageResolver.new()
