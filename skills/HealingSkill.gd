extends Skill

class_name HealingSkill

@export var healing_amount: int = 0


func get_resolver(_ctx: ActionContext) -> HealingResolver:
	return HealingResolver.new(healing_amount)
