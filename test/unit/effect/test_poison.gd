# Damage resolution (_deal_damage) is integration-level.
extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")

var subject: FakeCharacter


func before_each() -> void:
	subject = FakeCharacter.new()


func test_init_defaults() -> void:
	var p := PoisonEffect.new()
	assert_false(p.battle_only)
	assert_false(p.expires_after_battle)
	assert_eq(p.expire_phase, Effect.TurnPhase.TURN_END)


func test_is_stackable() -> void:
	var p := PoisonEffect.new()
	assert_true(p._is_stackable())


func test_listens_to_turn_end_and_movement() -> void:
	var p := PoisonEffect.new()
	var triggers := p.listened_triggers()
	assert_has(triggers, EffectTriggers.ON_TURN_END)
	assert_has(triggers, EffectTriggers.ON_MOVEMENT)


func test_can_process_only_for_owning_actor() -> void:
	var p := PoisonEffect.new()
	p.set_owner(subject)

	var own_event := TriggerEvent.new()
	own_event.source = CharacterSource.new(subject)
	assert_true(p.can_process(EffectTriggers.ON_TURN_END, own_event))

	var other := FakeCharacter.new()
	var other_event := TriggerEvent.new()
	other_event.source = CharacterSource.new(other)
	assert_false(p.can_process(EffectTriggers.ON_TURN_END, other_event))


func test_display_turns_returns_remaining() -> void:
	var p := PoisonEffect.new()
	p.remaining_turns = 5
	assert_eq(p.get_display_turns(), 5)
