extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")
const ProbeEffect = preload("res://test/helpers/probe_effect.gd")

var subject: FakeCharacter


func before_each() -> void:
	subject = FakeCharacter.new()


func _make(duration: int) -> ProbeEffect:
	var e := ProbeEffect.new()
	e.duration_turns = duration
	e.remaining_turns = duration
	e.set_owner(subject)
	subject.effects.append(e)
	return e


func test_is_turn_based_false_when_no_duration() -> void:
	var e := ProbeEffect.new()
	e.duration_turns = -1
	assert_false(e.is_turn_based())


func test_is_turn_based_true_when_duration_set() -> void:
	var e := ProbeEffect.new()
	e.duration_turns = 3
	assert_true(e.is_turn_based())


func test_consume_duration_decrements_remaining() -> void:
	var e := _make(3)
	e.consume_duration()
	assert_eq(e.remaining_turns, 2)


func test_consume_duration_amount() -> void:
	var e := _make(5)
	e.consume_duration(2)
	assert_eq(e.remaining_turns, 3)


func test_consume_duration_noop_when_not_turn_based() -> void:
	var e := _make(-1)
	e.consume_duration()
	assert_eq(e.remaining_turns, -1)


func test_expiry_removes_effect_from_owner() -> void:
	var e := _make(1)
	e.consume_duration()
	assert_eq(e.remaining_turns, 0)
	assert_false(subject.effects.has(e))


func test_tick_only_fires_on_matching_phase() -> void:
	var e := _make(3)
	e.expire_phase = Effect.TurnPhase.TURN_END
	e.on_turn_start()
	assert_eq(e.remaining_turns, 3)
	e.on_turn_end()
	assert_eq(e.remaining_turns, 2)


func test_display_turns_for_turn_end_effect() -> void:
	var e := _make(4)
	e.expire_phase = Effect.TurnPhase.TURN_END
	assert_eq(e.get_display_turns(), 4)


func test_display_turns_hidden_for_custom_phase() -> void:
	var e := _make(4)
	e.expire_phase = Effect.TurnPhase.CUSTOM
	assert_eq(e.get_display_turns(), -1)


func test_display_turns_hidden_when_not_turn_based() -> void:
	var e := ProbeEffect.new()
	e.duration_turns = -1
	assert_eq(e.get_display_turns(), -1)


func test_save_load_round_trip_preserves_exports() -> void:
	var e := ProbeEffect.new()
	e.id = "probe_x"
	e.probe_value = 42
	e.duration_turns = 7

	var data := e.game_save()

	var restored := ProbeEffect.new()
	restored.game_load(data)

	assert_eq(restored.id, "probe_x")
	assert_eq(restored.probe_value, 42)
	assert_eq(restored.duration_turns, 7)
