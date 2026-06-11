extends GutTest

const Combatant = preload("res://test/helpers/combatant.gd")

var _built: Array = []


func _make() -> Character:
	var c := Combatant.make()
	_built.append(c)
	return c


func after_each() -> void:
	Combatant.free_built(_built)
	_built = []


func test_single_targets_only_the_target() -> void:
	var t := _make()
	assert_eq(TargetingManager.get_applicable_targets(t, TargetingManager.TargetType.SINGLE), [t])


func test_group_targeting_falls_back_to_target_outside_battle() -> void:
	var t := _make()
	assert_eq(TargetingManager.get_applicable_targets(t, TargetingManager.TargetType.ROW), [t])


func test_same_side_for_two_non_party_characters() -> void:
	assert_true(TargetingManager.same_side(_make(), _make()))
