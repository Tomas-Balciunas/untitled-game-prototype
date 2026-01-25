extends Skill

class_name AttackSkill

@export var modifier: float = 1.0
@export var damage_type: DamageTypes.Type
## only matters when bounce targeting is selected
@export var bounce_instances: int = 0


func get_resolver(ctx: ActionContext) -> DamageResolver:
	var value: int = ctx.source.get_actor().stats.attack * modifier
	return DamageResolver.new(value)
