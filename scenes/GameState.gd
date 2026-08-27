extends Node3D

const GAME_OVER_PATH := "uid://cy7lwg2h0ca1g"

enum States {
	IDLE,
	MAP_TRANSITION,
	IN_BATTLE,
	MENU,
	CUTSCENE,
	EVENT
}

var gold: int:
	get: return RunState.current.gold
	set(value): RunState.current.gold = value

var current_state: States:
	get: return RunState.current.current_state
	set(value): RunState.current.current_state = value

func is_busy() -> bool:
	return current_state != States.IDLE

func set_idle() -> void:
	current_state = States.IDLE

func set_menu() -> void:
	current_state = States.MENU

func set_event() -> void:
	current_state = States.EVENT

func add_gold(amount: int) -> void:
	RunState.current.add_gold(amount)

func spend_gold(amount: int) -> bool:
	return RunState.current.spend_gold(amount)

func on_character_death() -> void:
	var party_dead: bool = true
	
	for member in RunState.current.party.members:
		if !member.is_dead:
			party_dead = false
	
	if party_dead:
		get_tree().change_scene_to_file(GAME_OVER_PATH)

func generate_id() -> String:
	var a: float = randi()
	var b: float = randi()
	var c: float = randi()
	var d: float = randi()
	return "%08x%08x%08x%08x" % [a, b, c, d]
