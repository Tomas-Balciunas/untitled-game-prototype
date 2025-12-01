extends Node

class_name BattleManager

signal current_battler_change(battler: CharacterInstance, is_party_member: bool)
signal turn_started(is_party_member: bool)
signal enemy_died(dead: CharacterInstance)

const TURN_THRESHOLD = 1000

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var party_panel := get_tree().get_root().get_node("Main/UIRoot/OverworldInterface/PartyPanel")
@onready var enemy_grid: EnemyFormation = null
@onready var ally_grid: AllyFormation = null

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

var current_state := BattleState.IDLE

var party: Array[CharacterInstance] = []
var enemies: Array[CharacterInstance] = []
var battlers: Array[CharacterInstance] = []
var turn_queue: Array[CharacterInstance] = []
var enemy_slots: Array[Node] = []
var _to_cleanup: Array[CharacterInstance] = []
var _pending_action: String = ""
var _pending_entity: Variant = null
var _pending_target: CharacterInstance = null
var current_battler: CharacterInstance = null
var action_queue: Array[DamageContext] = []

func begin(_enemies: Array[CharacterInstance]) -> void:
	BattleEventBus.event_concluded.connect(Callable(self, "_on_event_concluded"))
	BattleBus.target_selected.connect(_on_target_selected)
	BattleBus.action_selected.connect(_on_player_action_selected)
	
	var party_members := PartyManager.members
	
	for b: CharacterInstance in party_members + _enemies:
		b.action_value = 10000 / (100 + b.stats.get_final_stat(Stats.SPEED))
		_register_battler(b)
		b.prepare_for_battle()
		for e: BattleEvent in b.resource.battle_events:
			var inst := e.duplicate(true)
			inst.prepare(b)
			b.battle_events.append(inst)
	
	current_state = BattleState.CHECK_END

func _process(_delta: float) -> void:
	# cleanup has potential to fuck up battle state if states arent managed carefully
	if _to_cleanup.size() > 0 and current_state != BattleState.ANIMATING:
		# TODO consider processing on death effects here
		_corpse_janny()
		
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
			_handle_end("win")
		BattleState.LOSE:
			_handle_end("lose")

func _process_turn_queue() -> void:
	var alive_battlers := battlers.filter(func(b: CharacterInstance) -> bool: return not b.is_dead)
		
	alive_battlers.sort_custom(func(a: CharacterInstance, b: CharacterInstance) -> bool:
		return a.action_value < b.action_value
	)

	turn_queue = alive_battlers.duplicate()
	
	if turn_queue.is_empty():
		current_state = BattleState.CHECK_END
		return
	
	current_battler = turn_queue.pop_front()
	current_state = BattleState.TURN_START
	
	
	BattleBus.queue_processed.emit(turn_queue)

func _on_turn_start() -> void:
	var is_party_member := current_battler in party
	emit_signal("turn_started", is_party_member)
	emit_signal("current_battler_change", current_battler, is_party_member)

	var event := TriggerEvent.new()
	event.trigger = EffectTriggers.ON_TURN_START
	event.actor = current_battler
	event.ctx = ActionContext.new()
	EffectRunner.process_trigger(event)
	disable_all_targeting()
	
	if is_party_member:
		current_state = BattleState.PLAYER_TURN
		party_panel.highlight_member(current_battler)
		_on_player_turn(event) ## handle cases like checking for hard CC
	else:
		current_state = BattleState.ENEMY_TURN
		_process_enemy_turn(event)

func _on_turn_end() -> void:
	var event := TriggerEvent.new()
	event.trigger = EffectTriggers.ON_TURN_END
	event.actor = current_battler
	event.ctx = ActionContext.new()
	EffectRunner.process_trigger(event)
	current_battler.action_value += 1000 / (100 + current_battler.stats.get_final_stat(Stats.SPEED))
	current_battler = null
	party_panel.clear_highlights()
	current_state = BattleState.CHECK_END
	
func _on_player_turn(event: TriggerEvent) -> void:
	if event.ctx.skip_turn:
		current_state = BattleState.TURN_END
		return
	
	if event.ctx.force_action:
		if !event.ctx.target:
			push_error("Forced action for %s did not have a target" % current_battler.resource.name)
			current_state = BattleState.TURN_END
			return
			
		await _perform_player_action("attack", event.ctx.target)
		current_state = BattleState.TURN_END
		return
		
func _on_player_action_selected(action: String, entity: Variant) -> void:
	if current_state != BattleState.PLAYER_TURN:
		return
		
	_pending_action = action
	_pending_entity = entity
	
	match action:
		BattleBus.DEFEND:
			_handle_defend()
			current_state = BattleState.TURN_END
			return
		BattleBus.FLEE:
			_handle_end(BattleBus.FLEE)
			current_state = BattleState.TURN_END
			return
		BattleBus.ATTACK:
			enable_all_targeting()
			return
		BattleBus.SKILL:
			enable_all_targeting()
			return
		BattleBus.ITEM:
			enable_all_targeting()
			return

func _on_target_selected(target: CharacterInstance) -> void:
	disable_all_targeting()
	_pending_target = target
	_resolve_player_action()

func _resolve_player_action() -> void:
	await _perform_player_action(_pending_action, _pending_target)
	current_state = BattleState.TURN_END

func _perform_player_action(action: String, target: CharacterInstance) -> void:
	var attacker_slot := get_slot(current_battler)
	var target_slot := get_slot(target)
	
	match action:
		BattleBus.ATTACK:
			var targeting: TargetingManager.TargetType = current_battler.equipment["weapon"].template.targeting if current_battler.equipment["weapon"] else TargetingManager.TargetType.SINGLE
			var _targets := get_applicable_targets(target, targeting)
			
			current_state = BattleState.ANIMATING
			ChatEventBus.chat_event.emit(ChatterManager.ATTACKING, {
				"source": current_battler,
				"target": _targets
			})
			await attacker_slot.perform_attack_toward_target(target_slot)
			
			for t in _targets:
				if not t:
					continue
				var dmg := DamageContext.new()
				dmg.source = current_battler
				dmg.target   = t
				dmg.base_value = current_battler.stats.get_final_stat(Stats.ATTACK)
				dmg.final_value = current_battler.stats.get_final_stat(Stats.ATTACK)
				dmg.type = current_battler.damage_type
				dmg.actively_cast = true
				var _ctx := await DamageResolver.new().execute(dmg)
		BattleBus.SKILL:
			if _pending_entity is not Skill:
				push_error("Selected skill action entity is not skill!")
				return
				
			var skill := _pending_entity as Skill
				
			var targeting: TargetingManager.TargetType = skill.targeting_type
			var _targets := get_applicable_targets(target, targeting)
			
			current_state = BattleState.ANIMATING
			await attacker_slot.perform_attack_toward_target(target_slot)
			
			var mp_cost: int = skill.mp_cost
			for e in current_battler.effects:
				if e.has_method("modify_mp_cost"):
					mp_cost = e.modify_mp_cost(mp_cost)
			if current_battler.stats.current_mana < mp_cost:
				return
				
			current_battler.set_current_mana(current_battler.stats.current_mana - mp_cost)
			
			for t in _targets:
				if not t:
					continue
					
				var ctx := SkillContext.new()
				ctx.skill = skill
				ctx.actively_cast = true
				ctx.source = current_battler
				ctx.target = t
				ctx.temporary_effects = skill.effects
				var _ctx := SkillResolver.new().execute(ctx)
			
		BattleBus.ITEM:
			if _pending_entity is not ConsumableInstance:
				push_error("Selected item action entity is not item!")
				return
				
			var item := _pending_entity as ConsumableInstance
			
			var targeting: TargetingManager.TargetType = item.template.targeting_type
			var _targets := get_applicable_targets(target, targeting)
			
			current_state = BattleState.ANIMATING
			await attacker_slot.perform_attack_toward_target(target_slot)
			
			for t in _targets:
				if not t:
					continue
				
				var cons := ConsumableContext.new()
				cons.consumable = item
				cons.source = current_battler
				cons.target = t
				cons.temporary_effects = item.get_all_effects()
				cons.actively_cast = true
				var _ctx := ConsumableResolver.new().execute(cons)
				
	await attacker_slot.position_back()
	await process_queue()

func _process_enemy_turn(event: TriggerEvent = null) -> void:
	if current_battler == null:
		current_state = BattleState.CHECK_END
		return
		
	if event and event.ctx.skip_turn:
		current_state = BattleState.TURN_END
		return
	
	var target: CharacterInstance = null
	
	if event and event.ctx.force_action:
		if !event.ctx.target:
			push_error("Forced action for %s did not have a target" % current_battler.resource.name)
			current_state = BattleState.TURN_END
			return
			
		target = event.ctx.target

	if !target:
		var valid_targets := party.filter(func(p: CharacterInstance) -> bool: return p.is_dead == false)
		if valid_targets.is_empty():
			current_state = BattleState.CHECK_END
			return

		target = valid_targets.pick_random()
	
	current_state = BattleState.ANIMATING
	var attacker_slot := get_slot(current_battler)
	var target_slot := get_slot(target)
	
	var atk := DamageContext.new()
	atk.source = current_battler
	atk.target   = target
	atk.base_value = current_battler.stats.get_final_stat(Stats.ATTACK)
	atk.final_value = current_battler.stats.get_final_stat(Stats.ATTACK)
	atk.actively_cast = true
	
	ChatEventBus.chat_event.emit(ChatterManager.ATTACKING, {
				"source": current_battler,
				"target": [target]
			})
	await attacker_slot.perform_attack_toward_target(target_slot)
	
	var _ctx := await DamageResolver.new().execute(atk)
	
	await attacker_slot.position_back()
	await process_queue()
	
	current_state = BattleState.TURN_END

func _handle_defend() -> void:
	print(current_battler.resource.name, " is defending!")

func _check_end_conditions() -> void:
	if party.all(func(p: CharacterInstance) -> bool: return p.is_dead):
		current_state = BattleState.LOSE
	elif enemies.is_empty():
		current_state = BattleState.WIN
	else:
		current_state = BattleState.PROCESS_TURNS

func _handle_end(result: String) -> void:
	for member: CharacterInstance in party:
		member.cleanup_after_battle()
	
	match result:
		"win":
			_handle_win()
		"lose":
			_handle_lose()
		"flee":
			_handle_flee()

func _handle_win() -> void:
	EncounterBus.encounter_ended.emit("win", BattleContext.encounter_data)
	current_state = BattleState.IDLE

func _handle_lose() -> void:
	EncounterBus.encounter_ended.emit("lose", BattleContext.encounter_data)
	current_state = BattleState.IDLE
	
func _handle_flee() -> void:
	var success := randf() < 0.5
	if success:
		print("Party flees successfully!")
		EncounterBus.encounter_ended.emit("flee", BattleContext.encounter_data)
		current_state = BattleState.IDLE
	else:
		print("Failed to flee!")
	
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
	party_panel.disable_targeting()
	BattleContext.enemy_targeting_enabled = false

func enable_all_targeting() -> void:
	party_panel.enable_targeting()
	BattleContext.enemy_targeting_enabled = true

func enable_enemy_targeting() -> void:
	BattleContext.enemy_targeting_enabled = true

func disable_enemy_targeting() -> void:
	BattleContext.enemy_targeting_enabled = false

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
		var a: ActionContext = action_queue[0]
		var target := get_slot(a.target)
		var attacker: FormationSlot = get_slot(a.source)
		await attacker.perform_attack_toward_target(target)
		await DamageResolver.new().execute(a)
		await attacker.position_back()
		action_queue.pop_front()
		
func get_slot(chara: CharacterInstance) -> FormationSlot:
	if enemies.has(chara):
		return enemy_grid.get_slot_for(chara)
	if party.has(chara):
		return ally_grid.get_slot_for(chara)
	
	push_error("Orphaned character! - %s" % chara.resource.name)
	return null
