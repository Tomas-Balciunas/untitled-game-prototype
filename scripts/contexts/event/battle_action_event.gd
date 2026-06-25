extends TriggerEvent

class_name BattleActionEvent


var action: BattleAction = null
var original_ap_cost: int = 0
var ap_cost: int = 0
var ends_turn: bool = true
var consumed: bool = false
var ends_battle: bool = false
var end_reason: String = ""


func from_action(_action: BattleAction) -> void:
	action = _action
	original_ap_cost = _action.action_point_cost
	ap_cost = _action.action_point_cost
	ends_turn = _action.ends_turn
