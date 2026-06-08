extends Skill

class_name AttackSkill

@export var damage_type: DamageTypes.Type
## only matters when bounce targeting is selected
@export var bounce_instances: int = 0

@export_group("Power Scaling")
@export var attack_scale: float = 1.0
@export var magic_scale: float = 0.0
@export var divine_scale: float = 0.0


func get_resolver(ctx: ActionContext) -> DamageResolver:
	var s: Stats = ctx.source.get_actor().stats
	var raw: float = s.attack * attack_scale + s.magic_power * magic_scale + s.divine_power * divine_scale
	return DamageResolver.new(int(raw))

func get_damage_type():
	return damage_type
