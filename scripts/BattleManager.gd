extends Node

const TURN_THRESHOLD = 1000

@onready var dungeon = get_tree().get_root().get_node("Main/Dungeon")
@onready var player = get_tree().get_root().get_node("Main/Dungeon/Player")
@onready var battle_ui = $BattleUI
@onready var enemy_grid = $EnemyFormation
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var space_state = camera.get_world_3d().direct_space_state
@export var collision_mask_for_enemies: int = 1 << 2
var targeting_enabled = false
var current_hovered_enemy_slot: EnemySlot = null
var ray_query = PhysicsRayQueryParameters3D.new()
var last_mouse_pos = Vector2(-1, -1)

enum BattleState {
	IDLE,
	PROCESS_TURNS,
	PLAYER_TURN,
	ENEMY_TURN,
	ANIMATING,
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

func _ready():
	set_process_unhandled_input(true)
	battle_ui.action_selected.connect(_on_player_action_selected)
	battle_ui.hide()
	party = PartyManager.members
	var skeleton = CharacterRegistry.get_character(101)
	var instance3 = CharacterInstance.new(skeleton)
	var instance4 = CharacterInstance.new(skeleton)
	var instance5 = CharacterInstance.new(skeleton)
	var instance6 = CharacterInstance.new(skeleton)
	var instance7 = CharacterInstance.new(skeleton)
	var instance8 = CharacterInstance.new(skeleton)

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
		BattleState.PLAYER_TURN:
			pass
		BattleState.ENEMY_TURN:
			_process_enemy_turn()
		BattleState.ANIMATING:
			pass
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
		var next_battler = turn_queue.pop_front()
		next_battler.turn_meter -= TURN_THRESHOLD
		_start_turn(next_battler)

func _start_turn(battler: CharacterInstance):
	if battler.current_health <= 0:
		return
	if battler in party:
		current_state = BattleState.PLAYER_TURN
		targeting_enabled = true
		print("Player turn for:", battler.resource.name)
		battle_ui.show()
	else:
		current_state = BattleState.ENEMY_TURN
		_current_enemy = battler
		
func _on_player_action_selected(action: String):
	var target = enemies.pick_random()
	if target:
		player_action_selected(action, target)
	else:
		print("No valid enemy target.")

func _on_enemy_target_selected(target: CharacterInstance):
	print(target)
	if current_state == BattleState.PLAYER_TURN:
		targeting_enabled = false
		player_action_selected("attack", target)

func player_action_selected(action: String, target: CharacterInstance):
	if action == "attack":
		var damage = 10
		target.current_health = max(0, target.current_health - damage)
		print("Player attacked ", target.resource.name, " for ", damage)

	current_state = BattleState.CHECK_END
	if current_hovered_enemy_slot:
		current_hovered_enemy_slot.unhover()
		current_hovered_enemy_slot = null

var _current_enemy: CharacterInstance = null

func _process_enemy_turn():
	if _current_enemy == null:
		current_state = BattleState.CHECK_END
		return

	var valid_targets = party.filter(func(p): return p.current_health > 0)
	if valid_targets.is_empty():
		current_state = BattleState.CHECK_END
		return

	var target = valid_targets.pick_random()
	var damage = 5
	print(_current_enemy.resource.name, " attacked ", target.resource.name, " for ", damage)
	target.set_current_health(max(0, target.current_health - damage))

	_current_enemy = null
	current_state = BattleState.CHECK_END

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
	#dungeon.visible = true
	#player.in_battle = false
	get_tree().get_root().get_node("Main").remove_child(self)
	queue_free()

func _handle_lose():
	print("Defeat! Handle game over here.")
	EncounterManager.end_encounter("lose")
	#current_state = BattleState.IDLE
	#dungeon.visible = true
	#player.in_battle = false
	get_tree().get_root().get_node("Main").remove_child(self)
	queue_free()

func _input(event):
	if event is InputEventMouseMotion and targeting_enabled:
		if event.position != last_mouse_pos:
			last_mouse_pos = event.position
			_update_hovered_enemy(event.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_hovered_enemy_slot:
				print("Clicked on: ", current_hovered_enemy_slot.getName())

func _update_hovered_enemy(mouse_pos: Vector2):
	ray_query.from = camera.project_ray_origin(mouse_pos)
	ray_query.to = ray_query.from + camera.project_ray_normal(mouse_pos) * 500
	ray_query.collision_mask = collision_mask_for_enemies
	ray_query.exclude = []
	
	var result = space_state.intersect_ray(ray_query)
	if result and result.collider:
		var node = result.collider
		while node and not (node is EnemySlot):
			node = node.get_parent()
		var enemy_slot = node
		if enemy_slot != current_hovered_enemy_slot:
			if current_hovered_enemy_slot:
				current_hovered_enemy_slot.unhover()
			current_hovered_enemy_slot = enemy_slot
			current_hovered_enemy_slot.hover()
	else:
		if current_hovered_enemy_slot:
			current_hovered_enemy_slot.unhover()
			current_hovered_enemy_slot = null
