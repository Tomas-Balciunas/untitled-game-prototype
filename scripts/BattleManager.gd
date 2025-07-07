extends Node

class_name BattleManager

const TURN_THRESHOLD = 1000

@onready var dungeon = get_tree().get_root().get_node("Main/Dungeon")
@onready var player = get_tree().get_root().get_node("Main/Dungeon/Player")
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var battle_ui = $BattleUI
@onready var party_panel = get_tree().get_root().get_node("Main/PartyPanel")
@onready var enemy_grid = $EnemyFormation

enum BattleState {
	IDLE,
	PROCESS_TURNS,
	TURN_START,
	PLAYER_TURN,
	ENEMY_TURN,
	ANIMATING,
	TURN_END,
	CHECK_END,
	WIN,
	LOSE
}

var current_state = BattleState.IDLE

var party: Array[CharacterInstance] = []
var enemies: Array[CharacterInstance] = []
var battlers: Array[CharacterInstance] = []
var turn_queue: Array[CharacterInstance] = []
var enemy_slots: Array[Node] = []
var _pending_action: String = ""
var _pending_options: Array = []
var _pending_target: CharacterInstance = null
var current_battler: CharacterInstance = null

func _ready():
	TargetingManager.configure_for_battle(camera)
	TargetingManager.connect("target_clicked", Callable(self, "_on_target_selected"))
	TargetingManager.connect("target_hovered", Callable(self, "_on_enemy_hovered"))
	TargetingManager.connect("target_unhovered", Callable(self, "_on_enemy_unhovered"))
	battle_ui.action_selected.connect(_on_player_action_selected)
	battle_ui.hide()
	
	party = PartyManager.members
	
	var balmer = CharacterRegistry.get_character(102)
	var skeltal = CharacterRegistry.get_character(101)
	var instance3 = CharacterInstance.new(balmer)
	var instance4 = CharacterInstance.new(skeltal)

	enemies.append(instance3)
	enemies.append(instance4)
	
	load_enemies()

	battlers = party + enemies
	for b in battlers:
		b.turn_meter = 0

	current_state = BattleState.PROCESS_TURNS

func _process(_delta):
	match current_state:
		BattleState.PROCESS_TURNS:
			_process_turn_queue()
		BattleState.TURN_START:
			_on_turn_start()
		BattleState.PLAYER_TURN:
			pass
		BattleState.ENEMY_TURN:
			_process_enemy_turn()
		BattleState.ANIMATING:
			pass
		BattleState.TURN_END:
			_on_turn_end()
		BattleState.CHECK_END:
			_check_end_conditions()
		BattleState.WIN:
			_handle_win()
		BattleState.LOSE:
			_handle_lose()

func load_enemies():
	enemy_grid.place_all_enemies(enemies)

func _process_turn_queue():
	while turn_queue.is_empty():
		for b in battlers:
			if b.current_health <= 0:
				continue
			b.turn_meter += b.speed
			if b.turn_meter >= TURN_THRESHOLD and not turn_queue.has(b):
				turn_queue.append(b)

	if not turn_queue.is_empty():
		current_battler = turn_queue.pop_front()
		current_battler.turn_meter -= TURN_THRESHOLD
		current_state = BattleState.TURN_START

func _on_turn_start():
	battle_ui._reset_all_button_highlights()
	if current_battler.current_health <= 0:
		return

	current_battler.process_effects("on_turn_start")
	disable_all_targeting()
		
	if current_battler in party:
		current_state = BattleState.PLAYER_TURN
		print("Player turn for:", current_battler.resource.name)
		battle_ui.show()
		_on_player_action_selected("attack", [])
	else:
		battle_ui.hide()
		current_state = BattleState.ENEMY_TURN

func _on_turn_end():
	current_battler.process_effects("on_turn_end")
	current_battler = null
	current_state = BattleState.CHECK_END
		
func _on_player_action_selected(action: String, options: Array):
	_pending_action = action
	_pending_options = options
	battle_ui.highlight_action(action)
	
	match action:
		"defend":
			_handle_defend()
			current_state = BattleState.CHECK_END
			return
		"flee":
			_handle_flee()
			current_state = BattleState.CHECK_END
			return
		"attack":
			enable_all_targeting()
			return
		"skill":
			enable_all_targeting()
			return
		"item":
			enable_all_targeting()
			return

func _on_target_selected(target_slot):
	disable_all_targeting()
	_pending_target = target_slot.character_instance
	_resolve_player_action()

func _resolve_player_action():
	current_battler.process_effects("on_action", {
		"action":_pending_action,
		"target":_pending_target
	})
	_perform_player_action(_pending_action, _pending_target)
	current_state = BattleState.TURN_END

func _perform_player_action(action: String, target: CharacterInstance):
	match action:
		"attack":
			var damage = current_battler.attack_power
			target.set_current_health(max(0, target.current_health - damage))
			print(current_battler.resource.name, " attacked ", target.resource.name, " for ", damage)
		"skill":
			print(current_battler.resource.name, " used ", _pending_options[0]["name"])
		"item":
			print(current_battler.resource.name, " used item")

func _process_enemy_turn():
	if current_battler == null:
		current_state = BattleState.CHECK_END
		return

	var valid_targets = party.filter(func(p): return p.current_health > 0)
	if valid_targets.is_empty():
		current_state = BattleState.CHECK_END
		return

	var target = valid_targets.pick_random()
	var damage = 5
	current_state = BattleState.ANIMATING
	await get_tree().create_timer(0.5).timeout
	print(current_battler.resource.name, " attacked ", target.resource.name, " for ", damage)
	target.set_current_health(max(0, target.current_health - damage))

	current_state = BattleState.TURN_END

func _handle_defend():
	print(current_battler.resource.name, " is defending!")

func _handle_flee():
	var success = randf() < 0.5
	if success:
		print("Party flees successfully!")
		EncounterManager.end_encounter("flee")
		current_state = BattleState.IDLE
		get_tree().get_root().get_node("Main").remove_child(self)
		queue_free()
	else:
		print("Failed to flee!")

func _check_end_conditions():
	if party.all(func(p): return p.current_health <= 0):
		current_state = BattleState.LOSE
	elif enemies.all(func(e): return e.current_health <= 0):
		current_state = BattleState.WIN
	else:
		current_state = BattleState.PROCESS_TURNS

func _handle_win():
	print("Victory! Handle rewards here.")
	EncounterManager.end_encounter("win")
	current_state = BattleState.IDLE
	get_tree().get_root().get_node("Main").remove_child(self)
	queue_free()

func _handle_lose():
	print("Defeat! Handle game over here.")
	EncounterManager.end_encounter("lose")
	current_state = BattleState.IDLE
	get_tree().get_root().get_node("Main").remove_child(self)
	queue_free()

func _on_enemy_hovered(target: EnemySlot):
	target.hover()
	
func _on_enemy_unhovered(target: EnemySlot):
	target.unhover()

func disable_all_targeting():
	TargetingManager.disable_targeting()
	party_panel.disable_targeting()

func enable_all_targeting():
	TargetingManager.enable_targeting()
	party_panel.enable_targeting()

func enable_enemy_targeting():
	TargetingManager.enable_targeting()

func disable_enemy_targeting():
	TargetingManager.disable_targeting()

func enable_ally_targeting():
	party_panel.enable_targeting()
	
func disable_ally_targeting():
	party_panel.disable_targeting()
