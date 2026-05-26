extends Skill

class_name HealingSkill

@export var healing_amount: int = 0
@export var scaling: float = 0.0


func get_resolver(_ctx: ActionContext) -> HealingResolver:
	return HealingResolver.new(healing_amount, scaling)
