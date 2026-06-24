extends RefCounted

class_name TurnState

var actor: Character = null
var action_points: int = 0:
	set(value):
		if value != action_points:
			BattleBus.action_points_changed.emit(value)
		
		action_points = value

var current_action: BattleAction = null

var active_attack_count: int = 0
var damage_instance_count: int = 0
var damage_dealt: int = 0
var healing_done: int = 0

func _init(init_actor: Character) -> void:
	actor = init_actor
	action_points = init_actor.stats.get_stat(Stats.StatRef.ACTION_POINTS)

func add_action_points(value: int) -> void:
	action_points += value

func subtract_action_points(value: int) -> void:
	action_points = max(0, action_points - value)
