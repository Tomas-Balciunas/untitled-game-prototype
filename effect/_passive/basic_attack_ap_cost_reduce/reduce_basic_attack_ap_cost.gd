extends PassiveEffect
class_name ReduceBasicAttackApCost

func listened_triggers() -> Array:
	return []

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false

func _modifies_action_point_cost() -> bool:
	return true

func modify_action_point_cost(action: BattleAction, cost: int) -> int:
	if action is BasicAttack:
		return cost - 1

	return cost
