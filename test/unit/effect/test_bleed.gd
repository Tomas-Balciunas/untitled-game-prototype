extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")

var subject: FakeCharacter


func before_each() -> void:
	subject = FakeCharacter.new()


func _make_bleed(stacks: int, stack_loss: float = 0.5) -> Bleed:
	var b := Bleed.new()
	b.stacks = stacks
	b.stack_loss = stack_loss
	b.set_owner(subject)
	subject.effects.append(b)
	return b


func _event_for(b: Bleed) -> BleedEvent:
	var ev := BleedEvent.new()
	ev.from_bleed(b)
	return ev


func test_init_defaults() -> void:
	var b := Bleed.new()
	assert_true(b.battle_only)
	assert_true(b.expires_after_battle)
	assert_eq(b.get_category(), Effect.EffectCategory.STATUS)


func test_consume_stacks_halves() -> void:
	var b := _make_bleed(4, 0.5)
	b.consume_stacks(_event_for(b))
	assert_eq(b.stacks, 2)


func test_consume_stacks_rounds() -> void:
	var b := _make_bleed(5, 0.5)
	b.consume_stacks(_event_for(b))
	assert_eq(b.stacks, 3)


func test_consume_stacks_to_zero_expires() -> void:
	var b := _make_bleed(2, 0.0)
	b.consume_stacks(_event_for(b))
	assert_eq(b.stacks, 0)
	assert_false(subject.effects.has(b))


func test_event_snapshots_use_effect_values() -> void:
	var b := _make_bleed(6, 0.25)
	var ev := _event_for(b)
	assert_eq(ev.stack_snapshot, 6)
	assert_almost_eq(ev.stack_loss, 0.25, 0.0001)


func test_priority_per_stage() -> void:
	var b := Bleed.new()
	assert_eq(b.get_priority(EffectTriggers.ON_TURN_END), b.turn_end_priority)
	assert_eq(b.get_priority(EffectTriggers.ON_DAMAGE_APPLIED), b.damage_applied_priority)
	assert_eq(b.get_priority("anything_else"), 200)


func test_display_stacks_reflects_stacks() -> void:
	var b := _make_bleed(3)
	assert_eq(b.get_display_stacks(), 3)


func test_is_affected_by_bleed_true_when_present() -> void:
	_make_bleed(1)
	assert_true(Bleed.is_affected_by_bleed(subject))


func test_is_affected_by_bleed_false_when_absent() -> void:
	assert_false(Bleed.is_affected_by_bleed(subject))
