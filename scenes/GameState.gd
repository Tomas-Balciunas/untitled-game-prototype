extends Node3D

enum States {
	IDLE,
	MAP_TRANSITION,
	IN_BATTLE,
	MENU,
	CUTSCENE,
	EVENT
}

var gold: int = 1000

var current_state: States = States.IDLE

func is_busy() -> bool:
	return current_state != States.IDLE

func set_idle() -> void:
	current_state = States.IDLE

func set_event() -> void:
	current_state = States.EVENT

func game_save() -> int:
	return gold
	
func game_load(data: Dictionary) -> void:
	gold = data["gold"]
