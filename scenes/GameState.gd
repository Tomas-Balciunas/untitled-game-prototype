extends Node3D

enum States {
	IDLE,
	MAP_TRANSITION,
	IN_BATTLE,
	MENU,
	CUTSCENE
}

var current_state: States = States.IDLE

func is_busy() -> bool:
	return current_state != States.IDLE
