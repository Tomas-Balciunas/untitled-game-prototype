extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")

var _row: MinionRow


func before_each() -> void:
	_row = MinionRow.new()
	add_child_autofree(_row)


func _minion(health: int = 5, max_health: int = 10) -> FakeCharacter:
	var c := FakeCharacter.new()
	c.name = "Bones"
	c.stats = Stats.new()
	c.stats.health = max_health
	c.state = autofree(CharacterState.new(c.stats))
	c.state.current_health = health
	return c


func test_row_starts_hidden() -> void:
	assert_false(_row.visible)


func test_minion_added_spawns_a_slot_and_shows_the_row() -> void:
	BattleBus.minion_added.emit(_minion())
	assert_eq(_row.get_child_count(), 1)
	assert_true(_row.visible)


func test_same_minion_is_not_added_twice() -> void:
	var m := _minion()
	BattleBus.minion_added.emit(m)
	BattleBus.minion_added.emit(m)
	assert_eq(_row.get_child_count(), 1)


func test_removed_minion_hides_the_empty_row() -> void:
	var m := _minion()
	BattleBus.minion_added.emit(m)
	BattleBus.minion_removed.emit(m)
	assert_false(_row.visible)


func test_battle_end_clears_the_row() -> void:
	BattleBus.minion_added.emit(_minion())
	BattleBus.minion_added.emit(_minion())
	BattleBus.battle_end.emit()
	assert_false(_row.visible)
	await wait_process_frames(1)
	assert_eq(_row.get_child_count(), 0)


func test_slot_shows_health_and_dims_on_death() -> void:
	var m := _minion(5, 10)
	BattleBus.minion_added.emit(m)
	var slot: MinionSlot = _row.get_child(0)
	assert_eq(slot._hp_label.text, "5/10")
	assert_eq(slot.modulate, Color.WHITE)
	m.is_dead = true
	m.died.emit(m)
	assert_eq(slot.modulate, MinionSlot.DEAD_TINT)
