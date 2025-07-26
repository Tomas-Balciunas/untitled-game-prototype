extends Node

class_name BattleManager

signal current_battler_change(battler: CharacterInstance, is_party_member: bool)
signal turn_started(is_party_member: bool)
signal enemy_died(dead: CharacterInstance)

const TURN_THRESHOLD = 1000

@onready var dungeon = get_tree().get_root().get_node("Main/Dungeon")
@onready var player = get_tree().get_root().get_node("Main/Dungeon/Player")
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var party_panel = get_tree().get_root().get_node("Main/PartyPanel")
@onready var enemy_grid = null

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
var _to_cleanup: Array[CharacterInstance] = []
var _pending_action: String = ""
var _pending_options: Array = []
var _pending_target: CharacterInstance = null
var current_battler: CharacterInstance = null

func begin(_enemies: Array[CharacterInstance]):
	TargetingManager.configure_for_battle(camera)
	TargetingManager.connect("target_clicked", Callable(self, "_on_target_selected"))
	TargetingManager.connect("target_hovered", Callable(self, "_on_enemy_hovered"))
	TargetingManager.connect("target_unhovered", Callable(self, "_on_enemy_unhovered"))
	
	var party_members = PartyManager.members
	
	for b in party_members + _enemies:
		b.turn_meter = 0
		_register_battler(b)
	
	current_state = BattleState.PROCESS_TURNS

func _process(_delta):
	if _to_cleanup.size() > 0:
		_corpse_janny()
		current_state = BattleState.CHECK_END
		return
	
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

func _process_turn_queue():
	while turn_queue.is_empty():
		for b in battlers:
			b.turn_meter += b.stats.speed
			if b.turn_meter >= TURN_THRESHOLD and not turn_queue.has(b):
				turn_queue.append(b)

	if not turn_queue.is_empty():
		current_battler = turn_queue.pop_front()
		current_battler.turn_meter -= TURN_THRESHOLD
		current_state = BattleState.TURN_START

func _on_turn_start():
	var is_party_member = current_battler in party
	emit_signal("turn_started", is_party_member)
	emit_signal("current_battler_change", current_battler, is_party_member)

	current_battler.process_effects("on_turn_start")
	disable_all_targeting()
		
	if is_party_member:
		current_state = BattleState.PLAYER_TURN
		party_panel.highlight_member(current_battler)
		print("Player turn for:", current_battler.resource.name)
	else:
		current_state = BattleState.ENEMY_TURN

func _on_turn_end():
	current_battler.process_effects("on_turn_end")
	current_battler = null
	party_panel.clear_highlights()
	current_state = BattleState.CHECK_END
		
func _on_player_action_selected(action: String, options: Array):
	if current_state != BattleState.PLAYER_TURN:
		return
		
	_pending_action = action
	_pending_options = options
	
	match action:
		"defend":
			_handle_defend()
			current_state = BattleState.TURN_END
			return
		"flee":
			_handle_flee()
			current_state = BattleState.TURN_END
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
	if target_slot is EnemySlot:
		target_slot.unhover()
	_resolve_player_action()

func _resolve_player_action():
	_perform_player_action(_pending_action, _pending_target)
	current_state = BattleState.TURN_END

func _perform_player_action(action: String, target: CharacterInstance):
	match action:
		"attack":
			var targeting = current_battler.weapon.targeting if current_battler.weapon else TargetingManager.TargetType.SINGLE
			var _targets = get_applicable_targets(target, targeting)
			for t in _targets:
				if not t:
					continue
				if t is EnemySlot:
					t = t.character_instance
				var atk = AttackAction.new()
				atk.attacker = current_battler
				atk.defender   = t
				atk.base_value = current_battler.stats.attack
				atk.type = current_battler.damage_type
				var result    = DamageResolver.apply_attack(atk)
		"skill":
			var targeting = _pending_options[0].targeting_type
			var _targets = get_applicable_targets(target, targeting)
			var mp_cost = _pending_options[0].mp_cost
			for e in current_battler.effects:
				if e.has_method("modify_mp_cost"):
					mp_cost = e.modify_mp_cost(mp_cost)
			if current_battler.stats.current_mana < mp_cost:
				return
				
			current_battler.set_current_mana(current_battler.stats.current_mana - mp_cost)
			
			for t in _targets:
				if not t:
					continue
				if t is EnemySlot:
					t = t.character_instance
					
				if _pending_options[0] is HealingSkill:
					var skill = HealingAction.new()
					skill.provider = current_battler
					skill.receiver = t
					skill.base_value = _pending_options[0].healing_amount
					skill.effects = _pending_options[0].effects
					var result = HealingResolver.apply_heal(skill)
				elif _pending_options[0] is Skill:
					var skill = SkillAction.new()
					skill.attacker   = current_battler
					skill.defender     = t
					skill.skill = _pending_options[0]
					skill.effects = _pending_options[0].effects
					skill.modifier = _pending_options[0].modifier
					var result = DamageResolver.apply_skill(skill)
				else:
					print("Unknown skill!")
			
		"item":
			print(current_battler.resource.name, " used item")

func _process_enemy_turn():
	if current_battler == null:
		current_state = BattleState.CHECK_END
		return

	var valid_targets = party.filter(func(p: CharacterInstance): return p.is_dead == false)
	if valid_targets.is_empty():
		current_state = BattleState.CHECK_END
		return

	var target = valid_targets.pick_random()
	current_state = BattleState.ANIMATING
	await get_tree().create_timer(0.5).timeout

	var atk = AttackAction.new()
	atk.attacker = current_battler
	atk.defender   = target
	atk.base_value = current_battler.stats.attack
	var result    = DamageResolver.apply_attack(atk)
	
	current_state = BattleState.TURN_END

func _handle_defend():
	print(current_battler.resource.name, " is defending!")

func _handle_flee():
	var success = randf() < 0.5
	if success:
		print("Party flees successfully!")
		EncounterManager.end_encounter("flee")
		current_state = BattleState.IDLE
		queue_free()
	else:
		print("Failed to flee!")

func _check_end_conditions():
	if party.all(func(p: CharacterInstance): return p.is_dead):
		current_state = BattleState.LOSE
	elif enemies.is_empty():
		current_state = BattleState.WIN
	else:
		current_state = BattleState.PROCESS_TURNS

func _handle_win():
	print("Victory! Handle rewards here.")
	EncounterManager.end_encounter("win")
	current_state = BattleState.IDLE
	queue_free()

func _handle_lose():
	print("Defeat! Handle game over here.")
	EncounterManager.end_encounter("lose")
	current_state = BattleState.IDLE
	queue_free()
	
func _register_battler(battler: CharacterInstance):
	battlers.append(battler)
	
	if battler in PartyManager.members:
		party.append(battler)
	else:
		enemies.append(battler)
		
	battler.died.connect(Callable(self, "_on_battler_died"))
	
func _on_battler_died(rip: CharacterInstance) -> void:
	if rip not in party:
		_to_cleanup.append(rip)
	
func _corpse_janny():
	for dead in _to_cleanup:
		battlers.erase(dead)
		#party.erase(dead)
		enemies.erase(dead)
		turn_queue.erase(dead)
		#battle_ui.remove_character(dead)
		
		emit_signal("enemy_died", dead)
		#_play_death_animation(dead)
	_to_cleanup.clear()

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

func get_applicable_targets(current: CharacterInstance, type: TargetingManager.TargetType):

	match type:
		TargetingManager.TargetType.SINGLE:
			return [current]
		TargetingManager.TargetType.COLUMN:
			if party.has(current):
				return PartyManager.get_column_allies(current)
			return enemy_grid.get_column_enemies(current)
		TargetingManager.TargetType.ROW:
			if party.has(current):
				return PartyManager.get_row_allies(current)
			return enemy_grid.get_row_enemies(current)
		TargetingManager.TargetType.BLAST:
			if party.has(current):
				return PartyManager.get_blast_allies(current)
			return enemy_grid.get_blast_enemies(current)
		TargetingManager.TargetType.ADJACENT:
			if party.has(current):
				return PartyManager.get_adjacent_allies(current)
			return enemy_grid.get_adjacent_enemies(current)
		TargetingManager.TargetType.MASS:
			if party.has(current):
				return PartyManager.get_mass_allies()
			return enemy_grid.get_mass_enemies()
		#TODO: bounce targeting
	return [current]
		
		
