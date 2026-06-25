extends Node

class_name BattleManager

const ATTACK_CONNECTED_TIMEOUT = 1.0

@onready var enemy_grid: EnemyFormation = null
@onready var ally_grid: AllyFormation = null

enum BattleState {
	IDLE,
	PROCESS_TURNS,
	TURN_START,
	PLAYER_TURN,
	ACTION_QUEUE,
	ENEMY_TURN,
	ANIMATING,
	TURN_END,
	CHECK_END,
	WIN,
	LOSE
}

var current_state := BattleState.IDLE

var party: Array[Character] = []
var enemies: Array[Character] = []
var battlers: Array[Character] = []
var turn_queue: Array[Character] = []
var enemy_slots: Array[Node] = []
var _to_cleanup: Array[Character] = []
var current_battler: Character = null
var turn_state: TurnState = null
var action_queue: Array[ActionEvent] = []


func begin(_enemies: Array[Character]) -> void:
	BattleEventBus.event_concluded.connect(Callable(self, "_on_event_concluded"))
	TargetingManager.battle_target_selected.connect(_on_target_selected)
	BattleBus.action_selected.connect(_on_player_action_selected)
	BattleBus.control_selected.connect(_on_control_selected)
	
	var party_members := PartyManager.members
	
	for b: Character in party_members + _enemies:
		b.action_value = 10000 / (100 + b.stats.speed)
		_register_battler(b)
		b.prepare_for_battle()
		for e: BattleEvent in b.resource.battle_events:
			var inst := e.duplicate(true)
			inst.prepare(b)
			b.battle_events.append(inst)
	
	BattleBus.battle_start.emit()
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
		BattleState.ACTION_QUEUE:
			await_action_queue()
		BattleState.ENEMY_TURN:
			pass
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
	var alive_battlers := battlers.filter(func(b: Character) -> bool: return not b.is_dead)
		
	alive_battlers.sort_custom(func(a: Character, b: Character) -> bool:
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
	disable_all_targeting()
	turn_state = TurnState.new(current_battler)
	
	var is_party_member: bool = current_battler in party
	BattleBus.turn_started.emit(current_battler, is_party_member)

	var ctx: ActionContext = ActionContext.new()
	var resolver: TurnStageResolver = TurnStageResolver.new(EffectTriggers.ON_TURN_START, current_battler)
	resolver.execute(ctx)

	current_battler.on_turn_start()

	if is_party_member:
		current_state = BattleState.PLAYER_TURN
		_on_player_turn(ctx)
	else:
		current_state = BattleState.ENEMY_TURN
		_process_enemy_turn(ctx)

func _on_turn_end() -> void:
	var ctx: ActionContext = ActionContext.new()
	var resolver: TurnStageResolver = TurnStageResolver.new(EffectTriggers.ON_TURN_END, current_battler)
	resolver.execute(ctx)

	current_battler.on_turn_end()

	current_battler.action_value += 1000 / (100 + current_battler.stats.speed)
	BattleBus.turn_ended.emit()
	current_battler = null
	current_state = BattleState.CHECK_END
	
func _on_player_turn(ctx: ActionContext) -> void:
	BattleBus.ally_turn_started.emit(current_battler)
	
	if ctx.skip_turn:
		current_state = BattleState.TURN_END
		return
	
	if ctx.force_action:
		if !ctx.initial_target:
			push_error("Forced action for %s did not have a target" % current_battler.resource.name)
			current_state = BattleState.TURN_END
			return
		
		await _run_action(BasicAttack.new(), ctx.initial_target)
		current_state = BattleState.TURN_END
		
func _on_player_action_selected(action: BattleAction) -> void:
	if current_state != BattleState.PLAYER_TURN:
		return

	if not action.can_afford(current_battler, turn_state):
		NotificationBus.notification_requested.emit("Not enough action points!")
		return

	turn_state.current_action = action

	if action.needs_target():
		enable_all_targeting()
	else:
		await _run_action(action, null)


func _on_control_selected(kind: String) -> void:
	if current_state != BattleState.PLAYER_TURN:
		return

	match kind:
		BattleBus.END_TURN:
			current_state = BattleState.TURN_END


func _on_target_selected(target: Character) -> void:
	disable_all_targeting()
	var action: BattleAction = turn_state.current_action

	if action == null:
		current_state = BattleState.PLAYER_TURN
		return

	await _run_action(action, target)
	enable_all_targeting()


func _run_action(action: BattleAction, target: Character = null) -> void:
	var attacker_slot: FormationSlot = get_slot(current_battler)
	var target_slot: FormationSlot = null
	
	if target:
		target_slot = get_slot(target)
	
	if !attacker_slot or (target != null and target_slot == null):
		return

	current_state = BattleState.ANIMATING

	var event: BattleActionEvent = await action.execute(current_battler, target, attacker_slot, target_slot)
	
	if event.ends_battle:
		_handle_end(event.end_reason)
		return

	if event.ends_turn:
		current_state = BattleState.TURN_END
	else:
		current_state = BattleState.PLAYER_TURN


func await_action_queue() -> void:
	var remaining: Array[ActionEvent] = []
	
	for action in action_queue:
		if !action.finished:
			remaining.append(action)
	
	if !remaining.is_empty():
		action_queue = remaining
		
		return
	
	current_state = BattleState.TURN_END


func _process_enemy_turn(ctx: ActionContext) -> void:
	if current_battler == null:
		current_state = BattleState.CHECK_END
		return
		
	if ctx.skip_turn:
		current_state = BattleState.TURN_END
		return
	
	var weapon: Weapon = current_battler.equipment["weapon"] if current_battler.equipment["weapon"] else null
	
	var targeting: TargetingManager.TargetType
	var attack_rate: int
	
	if weapon:
		targeting = weapon.targeting
		attack_rate = weapon.attack_rate
	else:
		targeting = TargetingManager.TargetType.SINGLE
		attack_rate = 1
	
	var target: Character = null
	
	if ctx.force_action:
		if !ctx.initial_target:
			push_error("Forced action for %s did not have a target" % current_battler.resource.name)
			current_state = BattleState.TURN_END
			return
			
		target = ctx.initial_target

	if !target:
		var valid_targets := party.filter(func(p: Character) -> bool: return p.is_dead == false)
		if valid_targets.is_empty():
			current_state = BattleState.CHECK_END
			return

		target = valid_targets.pick_random()
	
	
	var attacker_slot := get_slot(current_battler)
	var target_slot := get_slot(target)
	
	var atk := ActionContext.new()
	atk.source = CharacterSource.new(current_battler)
	atk.set_targets(target)
	atk.actively_cast = true
	
	ChatEventBus.chat_event.emit(ChatterManager.ATTACKING, {
				"source": current_battler,
				"target": [target]
			})
	
	current_state = BattleState.ANIMATING
	
	await get_tree().create_timer(0.6).timeout
		
	for i in range(attack_rate):
		
		var resolver: DamageResolver = DamageResolver.new(current_battler.stats.attack)
		var orchertrator: ActionOrchestrator = ActionOrchestrator.new(current_battler, atk, resolver)
		await orchertrator.execute_action(
			func (e: ActionEvent) -> void:
				attacker_slot.perform_attack(e, target_slot)
		)
		
		if i < attack_rate - 1:
			await get_tree().create_timer(0.18).timeout
	
	await attacker_slot.position_back()
	
	current_state = BattleState.ACTION_QUEUE

func _handle_defend() -> void:
	print(current_battler.resource.name, " is defending!")

func _check_end_conditions() -> void:
	if party.all(func(p: Character) -> bool: return p.is_dead):
		current_state = BattleState.LOSE
	elif enemies.is_empty():
		current_state = BattleState.WIN
	else:
		current_state = BattleState.PROCESS_TURNS

func _handle_end(result: String) -> void:
	match result:
		"win":
			_handle_win()
		"lose":
			_handle_lose()
		"flee":
			_handle_flee()

func _handle_win() -> void:
	for member: Character in party:
		member.cleanup_after_battle()
	BattleBus.battle_end.emit()
	EncounterBus.encounter_ended.emit("win", BattleContext.encounter_data)
	current_state = BattleState.IDLE

func _handle_lose() -> void:
	for member: Character in party:
		member.cleanup_after_battle()
	BattleBus.battle_end.emit()
	EncounterBus.encounter_ended.emit("lose", BattleContext.encounter_data)
	current_state = BattleState.IDLE

func _handle_flee() -> void:
	for member: Character in party:
		member.cleanup_after_battle()
	
	BattleBus.battle_end.emit()
	EncounterBus.encounter_ended.emit("flee", BattleContext.encounter_data)
	current_state = BattleState.IDLE
	
func _register_battler(battler: Character) -> void:
	battlers.append(battler)
	
	if battler in PartyManager.members:
		party.append(battler)
	else:
		enemies.append(battler)
		
	battler.died.connect(Callable(self, "_on_battler_died"))
	
func _on_battler_died(rip: Character) -> void:
	if rip not in party:
		_to_cleanup.append(rip)
	
func _corpse_janny() -> void:
	for dead in _to_cleanup:
		var slot = get_slot(dead)
		await slot.perform_death()
		dead.cleanup_after_battle()
		battlers.erase(dead)
		#party.erase(dead)
		enemies.erase(dead)
		turn_queue.erase(dead)
		#battle_ui.remove_character(dead)
	_to_cleanup.clear()

func disable_all_targeting() -> void:
	BattleContext.enemy_targeting_enabled = false
	BattleContext.ally_targeting_enabled = false
	TargetingManager.end()

func enable_all_targeting() -> void:
	BattleContext.enemy_targeting_enabled = true
	BattleContext.ally_targeting_enabled = true
	TargetingManager.begin(TargetingManager.Mode.BATTLE)

func enable_enemy_targeting() -> void:
	BattleContext.enemy_targeting_enabled = true

func disable_enemy_targeting() -> void:
	BattleContext.enemy_targeting_enabled = false

func enable_ally_targeting() -> void:
	BattleContext.ally_targeting_enabled = true
	
func disable_ally_targeting() -> void:
	BattleContext.ally_targeting_enabled = false


func _on_event_concluded() -> void:
	BattleContext.event_running = false

func process_queue() -> void:
	# TODO need to consider clean up and end checks
	pass
	#while action_queue.size() > 0:
		#var a: ActionContext = action_queue[0]
		#var target := get_slot(a.target)
		#var attacker: FormationSlot = get_slot(a.source.character)
		#
		#if !attacker:
			#continue
		#
		#await attacker.perform_run_towards_target(target)
		#attacker.perform_attack()
		#var timed_out: bool = await SignalFailsafe.await_signal_or_timeout(self, BattleBus.attack_connected, ATTACK_CONNECTED_TIMEOUT)
#
		#if timed_out:
			#push_error("Attack connected signal timed out for character: %s, %s " % [current_battler.resource.name, current_battler.resource.id])
		#
		#await DamageResolver.new().execute(a)
		#await attacker.position_back()
		#action_queue.pop_front()
		
func get_slot(chara: Character) -> FormationSlot:
	if enemies.has(chara):
		return enemy_grid.get_slot_for(chara)
	if party.has(chara):
		return ally_grid.get_slot_for(chara)
	
	push_error("Orphaned character! - %s" % chara.resource.name)
	return null
