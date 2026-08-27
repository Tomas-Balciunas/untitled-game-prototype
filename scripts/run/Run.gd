extends RefCounted

class_name Run

## One playthrough. Starting a new run replaces this object rather than
## resetting fields, so new run-scoped state can't be forgotten.

var party := Party.new()
var map := DungeonState.new()
var tags := InteractionTags.new()
var flags := EventFlagState.new()
var gold: int = 0

## Nested one level down: a battle happens within a run. Always non-null, and
## replaced rather than cleared so no flag can survive a battle.
var battle := BattleSession.new()

var current_state: GameState.States = GameState.States.IDLE


func begin_battle(m: BattleManager, enemies: EnemyFormation, allies: AllyFormation, data: EncounterData) -> void:
	battle = BattleSession.new()
	battle.in_battle = true
	battle.manager = m
	battle.enemy_formation = enemies
	battle.ally_formation = allies
	battle.encounter_data = data

func end_battle() -> void:
	battle = BattleSession.new()

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
		"game_state": {"gold": gold},
		"party": party.game_save(),
		"dungeon": map.game_save(),
		"interaction_state": tags.game_save(),
		"event_flags": flags.game_save(),
	}

func game_load(state: Dictionary) -> void:
	gold = state.get("game_state", {}).get("gold", 0)
	CurrencyBus.gold_changed.emit(gold)
	if state.has("party"):
		party.game_load(state["party"])
	if state.has("dungeon"):
		map.game_load(state["dungeon"])
	if state.has("interaction_state"):
		tags.game_load(state["interaction_state"])
	if state.has("event_flags"):
		flags.game_load(state["event_flags"])
