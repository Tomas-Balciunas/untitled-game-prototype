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

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	CurrencyBus.gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount:
		return false
	gold -= amount
	CurrencyBus.gold_changed.emit(gold)
	return true

func game_save() -> Dictionary:
	return {
		"gold": gold,
	}

func on_character_death() -> void:
	var party_dead: bool = true
	
	for member in PartyManager.members:
		if !member.is_dead:
			party_dead = false
	
	if party_dead:
		get_tree().change_scene_to_file(GAME_OVER_PATH)

func game_load(data: Dictionary) -> void:
	gold = data.get("gold", 0)
	CurrencyBus.gold_changed.emit(gold)

func generate_id() -> String:
	var a: float = randi()
	var b: float = randi()
	var c: float = randi()
	var d: float = randi()
	return "%08x%08x%08x%08x" % [a, b, c, d]
