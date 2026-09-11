extends RefCounted

class_name AiActionCandidate

var battler: Character = null
var action: BattleAction = null
var target_weight: float = 0.5

func _init(_action: BattleAction,_battler: Character = null, _target_weight: float = 0.5) -> void:
	battler = _battler
	action = _action
	target_weight = _target_weight
