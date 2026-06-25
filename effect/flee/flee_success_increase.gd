extends PassiveEffect
class_name FleeSuccessIncrease


func listened_triggers() -> Array:
	return [BattleAction.ON_ACTION_POINT_CONSUME]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	if event is BattleActionEvent and !(event as BattleActionEvent).action is FleeAction:
		return false
	
	return owner_is_actor(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var action: FleeAction = (event as BattleActionEvent).action as FleeAction
	action.success_rate *= 1.5
