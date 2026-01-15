extends Node3D

enum States {
	IDLE,
	MAP_TRANSITION,
	IN_BATTLE,
	MENU,
	CUTSCENE,
	EVENT
}

var gold: int = 0

var current_state: States = States.IDLE

func is_busy() -> bool:
	return current_state != States.IDLE

func set_idle() -> void:
	current_state = States.IDLE

func set_menu() -> void:
	current_state = States.MENU

func set_event() -> void:
	current_state = States.EVENT

func game_save() -> int:
	return gold
	
func game_load(data: Dictionary) -> void:
	gold = data["gold"]

func generate_id() -> String:
	var a: float = randi()
	var b: float = randi()
	var c: float = randi()
	var d: float = randi()
	return "%08x%08x%08x%08x" % [a, b, c, d]
