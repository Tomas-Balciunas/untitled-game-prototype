extends RefCounted

class_name Run


var party := Party.new()
var map := DungeonState.new()
var tags := InteractionTags.new()
var flags := EventFlagState.new()
var gold: int = 0

var shop_stock: Dictionary = {}

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
	TargetingManager.end()

## -1 means unlimited.
func get_shop_stock(shop_id: String, entry: ShopEntry) -> int:
	if entry.is_infinite() or entry.item == null:
		return -1
	return shop_stock.get(shop_id, {}).get(entry.item.id, entry.stock)

func consume_shop_stock(shop_id: String, entry: ShopEntry) -> void:
	if entry.is_infinite() or entry.item == null:
		return
	if not shop_stock.has(shop_id):
		shop_stock[shop_id] = {}
	shop_stock[shop_id][entry.item.id] = max(0, get_shop_stock(shop_id, entry) - 1)

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
		"shops": shop_stock,
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
	shop_stock = state.get("shops", {})
