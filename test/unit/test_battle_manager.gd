# Covers the dependency-light state-machine logic: end-condition checks and
# turn-queue ordering. The rest of BattleManager is a bus/scene-driven loop
extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")


func _bm() -> BattleManager:
	return autofree(BattleManager.new())


func _battler(action_value: float = 0.0, dead: bool = false) -> FakeCharacter:
	var c := FakeCharacter.new()
	c.action_value = action_value
	c.is_dead = dead
	return c


# --- _check_end_conditions ---

func test_all_party_dead_is_lose() -> void:
	var bm := _bm()
	bm.party = [_battler(0, true), _battler(0, true)]
	bm.enemies = [_battler()]
	bm._check_end_conditions()
	assert_eq(bm.current_state, BattleManager.BattleState.LOSE)


func test_no_enemies_is_win() -> void:
	var bm := _bm()
	bm.party = [_battler()]
	bm.enemies = []
	bm._check_end_conditions()
	assert_eq(bm.current_state, BattleManager.BattleState.WIN)


func test_otherwise_processes_turns() -> void:
	var bm := _bm()
	bm.party = [_battler()]
	bm.enemies = [_battler()]
	bm._check_end_conditions()
	assert_eq(bm.current_state, BattleManager.BattleState.PROCESS_TURNS)


func test_minions_do_not_prevent_lose() -> void:
	var bm := _bm()
	bm.party = [_battler(0, true)]
	bm.minions = [_battler()]
	bm.enemies = [_battler()]
	bm._check_end_conditions()
	assert_eq(bm.current_state, BattleManager.BattleState.LOSE)


# --- sides ---

func test_register_battler_sorts_by_role() -> void:
	var bm := _bm()
	var member := _battler()
	var minion := _battler()
	var enemy := _battler()
	bm._register_battler(member, BattleManager.Role.PARTY)
	bm._register_battler(minion, BattleManager.Role.MINION)
	bm._register_battler(enemy, BattleManager.Role.ENEMY)
	assert_eq(bm.party, [member])
	assert_eq(bm.minions, [minion])
	assert_eq(bm.enemies, [enemy])
	assert_eq(bm.battlers.size(), 3)


func test_only_minions_are_announced_to_the_hud() -> void:
	var bm := _bm()
	var minion := _battler()
	var enemy := _battler()
	watch_signals(BattleBus)
	bm._register_battler(enemy, BattleManager.Role.ENEMY)
	assert_signal_not_emitted(BattleBus, "minion_added")
	bm._register_battler(minion, BattleManager.Role.MINION)
	assert_signal_emitted_with_parameters(BattleBus, "minion_added", [minion])


func test_minion_is_player_side_but_not_player_controlled() -> void:
	var bm := _bm()
	var member := _battler()
	var minion := _battler()
	var enemy := _battler()
	bm._register_battler(member, BattleManager.Role.PARTY)
	bm._register_battler(minion, BattleManager.Role.MINION)
	bm._register_battler(enemy, BattleManager.Role.ENEMY)
	assert_true(bm.is_player_side(member))
	assert_true(bm.is_player_controlled(member))
	assert_true(bm.is_player_side(minion))
	assert_false(bm.is_player_controlled(minion))
	assert_false(bm.is_player_side(enemy))
	assert_false(bm.is_player_controlled(enemy))


# --- _process_turn_queue ---

func test_lowest_action_value_acts_first() -> void:
	var bm := _bm()
	var slow := _battler(5.0)
	var fast := _battler(1.0)
	var mid := _battler(3.0)
	bm.battlers = [slow, fast, mid]

	bm._process_turn_queue()

	assert_eq(bm.current_battler, fast, "lowest action_value is the current battler")
	assert_eq(bm.turn_queue, [mid, slow], "remaining queue stays ordered ascending")
	assert_eq(bm.current_state, BattleManager.BattleState.TURN_START)


func test_dead_battlers_excluded_from_queue() -> void:
	var bm := _bm()
	var alive := _battler(2.0)
	var corpse := _battler(1.0, true)
	bm.battlers = [corpse, alive]

	bm._process_turn_queue()

	assert_eq(bm.current_battler, alive, "dead battlers don't take turns")


func test_no_alive_battlers_goes_to_check_end() -> void:
	var bm := _bm()
	bm.battlers = [_battler(1.0, true)]

	bm._process_turn_queue()

	assert_eq(bm.current_state, BattleManager.BattleState.CHECK_END)
