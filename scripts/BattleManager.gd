extends Node

class_name BattleManager

signal current_battler_change(battler: CharacterInstance, is_party_member: bool)
signal turn_started(is_party_member: bool)
signal enemy_died(dead: CharacterInstance)

const TURN_THRESHOLD = 1000

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var party_panel = get_tree().get_root().get_node("Main/PartyPanel")
@onready var enemy_grid = null
@onready var ally_grid = null

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
var action_queue: Array[AttackAction] = []

func begin(_enemies: Array[CharacterInstance]) -> void:
	BattleEventBus.event_concluded.connect(Callable(self, "_on_event_concluded"))
	TargetingManager.configure_for_battle(camera)
	TargetingManager.connect("target_clicked", Callable(self, "_on_target_selected"))
	
	
	var party_members := PartyManager.members
	
	for b: CharacterInstance in party_members + _enemies:
		b.turn_meter = 0
		_register_battler(b)
		b.prepare_for_battle()
		for e: BattleEvent in b.resource.battle_events:
			var inst = e.duplicate(true)
			inst.prepare(b)
			b.battle_events.append(inst)
	
	current_state = BattleState.CHECK_END

func _process(_delta) -> void:
	# cleanup has potential to fuck up battle state if states arent managed carefully
	# due to forced CHECK_END
	if _to_cleanup.size() > 0 and current_state != BattleState.ANIMATING:
		_corpse_janny()
		current_state = BattleState.CHECK_END
		return
		
	if BattleContext.event_running:
		current_state = BattleState.ANIMATING
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

func _process_turn_queue() -> void:
	if turn_queue.is_empty():
		var alive_battlers = battlers.filter(func(b): return not b.is_dead)
		
		alive_battlers.sort_custom(func(a, b):
			return a.stats.get_final_stat(Stats.SPEED) > b.stats.get_final_stat(Stats.SPEED)
		)

		turn_queue = alive_battlers.duplicate()

	if not turn_queue.is_empty():
		current_battler = turn_queue.pop_front()
		current_state = BattleState.TURN_START

func _on_turn_start() -> void:
	var is_party_member := current_battler in party
	emit_signal("turn_started", is_party_member)
	emit_signal("current_battler_change", current_battler, is_party_member)

	var event := TriggerEvent.new()
	event.trigger = EffectTriggers.ON_TURN_START
	event.actor = current_battler
	EffectRunner.process_trigger(event)
	disable_all_targeting()
		
	if is_party_member:
		current_state = BattleState.PLAYER_TURN
		party_panel.highlight_member(current_battler)
	else:
		current_state = BattleState.ENEMY_TURN
	
	print("Player turn for:", current_battler.resource.name)

func _on_turn_end() -> void:
	var event := TriggerEvent.new()
	event.trigger = EffectTriggers.ON_TURN_END
	event.actor = current_battler
	EffectRunner.process_trigger(event)
	current_battler = null
	party_panel.clear_highlights()
	current_state = BattleState.CHECK_END
		
func _on_player_action_selected(action: String, options: Array) -> void:
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

func _on_target_selected(target_slot: FormationSlot) -> void:
	disable_all_targeting()
	_pending_target = target_slot.character_instance
	if target_slot is FormationSlot:
		target_slot.unhover()
	_resolve_player_action()

func _resolve_player_action() -> void:
	await _perform_player_action(_pending_action, _pending_target)
	current_state = BattleState.TURN_END

func _perform_player_action(action: String, target: CharacterInstance) -> void:
	var attacker_slot = get_slot(current_battler)
	var target_slot = get_slot(target)
	
	match action:
		"attack":
			var targeting = current_battler.equipment["weapon"].template.targeting if current_battler.equipment["weapon"] else TargetingManager.TargetType.SINGLE
			var _targets = get_applicable_targets(target, targeting)
			
			current_state = BattleState.ANIMATING
			await attacker_slot.perform_attack_toward_target(target_slot)
			
			for t in _targets:
				if not t:
					continue
				if t is FormationSlot:
					t = t.character_instance
				var atk = AttackAction.new()
				atk.attacker = current_battler
				atk.defender   = t
				atk.base_value = current_battler.stats.get_final_stat(Stats.ATTACK)
				atk.type = current_battler.damage_type
				atk.actively_cast = true
				await DamageResolver.apply_attack(atk)
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
			
			current_state = BattleState.ANIMATING
			attacker_slot.perform_attack_toward_target(target_slot)
			
			for t in _targets:
				if not t:
					continue
				if t is FormationSlot:
					t = t.character_instance
					
				if _pending_options[0] is HealingSkill:
					var skill = HealingAction.new()
					skill.provider = current_battler
					skill.receiver = t
					skill.base_value = _pending_options[0].healing_amount
					skill.effects = _pending_options[0].effects
					skill.actively_cast = true
					HealingResolver.apply_heal(skill)
				elif _pending_options[0] is Skill:
					var skill = SkillAction.new()
					skill.attacker   = current_battler
					skill.defender     = t
					skill.skill = _pending_options[0]
					skill.effects = _pending_options[0].effects
					skill.modifier = _pending_options[0].modifier
					skill.actively_cast = true
					DamageResolver.apply_skill(skill)
				else:
					print("Unknown skill!")
			
		"item":
			var targeting = _pending_options[0].template.targeting_type
			var _targets = get_applicable_targets(target, targeting)
			
			current_state = BattleState.ANIMATING
			await attacker_slot.perform_attack_toward_target(target_slot)
			
			for t in _targets:
				if not t:
					continue
				if t is FormationSlot:
					t = t.character_instance
				var cons = ConsumableAction.new()
				cons.consumable = _pending_options[0]
				cons.source = current_battler
				cons.target = t
				cons.actively_cast = true
				ConsumableResolver.apply_consumable(cons)
				
	await attacker_slot.position_back()
	await process_queue()

func _process_enemy_turn() -> void:
	if current_battler == null:
		current_state = BattleState.CHECK_END
		return

	var valid_targets = party.filter(func(p: CharacterInstance): return p.is_dead == false)
	if valid_targets.is_empty():
		current_state = BattleState.CHECK_END
		return

	var target = valid_targets.pick_random()
	current_state = BattleState.ANIMATING
	var attacker_slot = get_slot(current_battler)
	var target_slot = get_slot(target)
	
	var atk := AttackAction.new()
	atk.attacker = current_battler
	atk.defender   = target
	atk.base_value = current_battler.stats.get_final_stat(Stats.ATTACK)
	atk.actively_cast = true

	await attacker_slot.perform_attack_toward_target(target_slot)
	
	await DamageResolver.apply_attack(atk)
	
	await attacker_slot.position_back()
	await process_queue()
	
	current_state = BattleState.TURN_END

func _handle_defend() -> void:
	print(current_battler.resource.name, " is defending!")

func _handle_flee() -> void:
	var success := randf() < 1
	if success:
		print("Party flees successfully!")
		EncounterBus.encounter_ended.emit("flee", BattleContext.encounter_data)
		current_state = BattleState.IDLE
	else:
		print("Failed to flee!")

func _check_end_conditions() -> void:
	if party.all(func(p: CharacterInstance): return p.is_dead):
		current_state = BattleState.LOSE
	elif enemies.is_empty():
		current_state = BattleState.WIN
	else:
		current_state = BattleState.PROCESS_TURNS

func _handle_win() -> void:
	print("Victory! Handle rewards here.")
	EncounterBus.encounter_ended.emit("win", BattleContext.encounter_data)
	current_state = BattleState.IDLE

func _handle_lose() -> void:
	print("Defeat! Handle game over here.")
	EncounterBus.encounter_ended.emit("lose", BattleContext.encounter_data)
	current_state = BattleState.IDLE
	
func _register_battler(battler: CharacterInstance) -> void:
	battlers.append(battler)
	
	if battler in PartyManager.members:
		party.append(battler)
	else:
		enemies.append(battler)
		
	battler.died.connect(Callable(self, "_on_battler_died"))
	
func _on_battler_died(rip: CharacterInstance) -> void:
	if rip not in party:
		_to_cleanup.append(rip)
	
func _corpse_janny() -> void:
	for dead in _to_cleanup:
		battlers.erase(dead)
		#party.erase(dead)
		enemies.erase(dead)
		turn_queue.erase(dead)
		#battle_ui.remove_character(dead)
		
		emit_signal("enemy_died", dead)
	_to_cleanup.clear()

func disable_all_targeting() -> void:
	TargetingManager.disable_targeting()
	party_panel.disable_targeting()

func enable_all_targeting() -> void:
	TargetingManager.enable_targeting()
	party_panel.enable_targeting()

func enable_enemy_targeting() -> void:
	TargetingManager.enable_targeting()

func disable_enemy_targeting() -> void:
	TargetingManager.disable_targeting()

func enable_ally_targeting() -> void:
	party_panel.enable_targeting()
	
func disable_ally_targeting() -> void:
	party_panel.disable_targeting()

func get_applicable_targets(current: CharacterInstance, type: TargetingManager.TargetType) -> Array[CharacterInstance]:
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
		
func same_side(a: CharacterInstance, b: CharacterInstance) -> bool:
	return (a in party) == (b in party)

func _on_event_concluded() -> void:
	BattleContext.event_running = false

func process_queue() -> void:
	# TODO need to consider clean up and end checks
	while action_queue.size() > 0:
		var a = action_queue[0]
		var target = get_slot(a.defender)
		var attacker: FormationSlot = get_slot(a.attacker)
		await attacker.perform_attack_toward_target(target)
		await DamageResolver.apply_attack(a)
		await attacker.position_back()
		action_queue.pop_front()
		
func get_slot(chara: CharacterInstance):
	if enemies.has(chara):
		return enemy_grid.get_slot_for(chara)
	if party.has(chara):
		return ally_grid.get_slot_for(chara)
	
	push_error("Orphaned character! - %s" % chara.resource.name)
