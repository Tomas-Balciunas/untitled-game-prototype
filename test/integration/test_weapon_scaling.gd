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


func _scaling_with_attribute(stat: Stats.StatRef, attr: Attributes.AttributeRef, mult: float) -> WeaponScaling:
	var am := AttributeMultiplier.new()
	am.attribute = attr
	am.multiplier = mult
	var entry := WeaponScalingEntry.new()
	entry.stat = stat
	entry.attribute_contributions = [am]
	var s := WeaponScaling.new()
	s.entries = [entry]
	return s


func test_attribute_contribution() -> void:
	var c := _make()
	c.attributes.strength = 8
	var s := _scaling_with_attribute(Stats.StatRef.ATTACK, Attributes.AttributeRef.STR, 1.5)
	assert_eq(s.compute_contribution(Stats.StatRef.ATTACK, c), 12.0)


func test_stat_contribution() -> void:
	var c := _make()
	c.stats.speed = 10
	var sm := StatMultiplier.new()
	sm.source_stat = Stats.StatRef.SPEED
	sm.multiplier = 0.5
	var entry := WeaponScalingEntry.new()
	entry.stat = Stats.StatRef.ATTACK
	entry.stat_contributions = [sm]
	var s := WeaponScaling.new()
	s.entries = [entry]
	assert_eq(s.compute_contribution(Stats.StatRef.ATTACK, c), 5.0)


func test_non_power_target_contributes_nothing() -> void:
	var c := _make()
	var s := _scaling_with_attribute(Stats.StatRef.ATTACK, Attributes.AttributeRef.STR, 1.5)
	assert_eq(s.compute_contribution(Stats.StatRef.SPEED, c), 0.0)


func test_save_load_round_trip() -> void:
	var s := _scaling_with_attribute(Stats.StatRef.MAGIC_POWER, Attributes.AttributeRef.IQ, 2.0)
	var restored := WeaponScaling.new()
	restored.game_load(s.game_save())

	assert_eq(restored.entries.size(), 1)
	assert_eq(restored.entries[0].stat, Stats.StatRef.MAGIC_POWER)
	assert_eq(restored.entries[0].attribute_contributions[0].attribute, Attributes.AttributeRef.IQ)
	assert_eq(restored.entries[0].attribute_contributions[0].multiplier, 2.0)
