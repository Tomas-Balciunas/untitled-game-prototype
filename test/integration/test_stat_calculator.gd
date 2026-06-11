# computed_stats holds the pre-gear/pre-modifier value, so expectations are
# derived from it rather than replicating attribute/level growth math.
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


func _mod(stat: Stats.StatRef, type: StatModifier.Type, value: float) -> StatModifier:
	var m := StatModifier.new()
	m.id = "gut_mod"
	m.stat = stat
	m.type = type
	m.value = value
	return m


func test_additive_modifier_adds_flat() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)
	var before := c.stats.get_stat(Stats.StatRef.DEFENSE)

	c.state.add_modifier(_mod(Stats.StatRef.DEFENSE, StatModifier.Type.ADDITIVE, 10.0))
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)

	assert_eq(c.stats.get_stat(Stats.StatRef.DEFENSE), before + 10)


func test_multiplicative_modifier_scales_computed() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)
	var before := c.stats.get_stat(Stats.StatRef.DEFENSE)

	c.state.add_modifier(_mod(Stats.StatRef.DEFENSE, StatModifier.Type.MULTIPLICATIVE, 1.0))
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)

	# a 100% multiplicative mod adds exactly computed_stats worth (±1 rounding)
	var delta := c.stats.get_stat(Stats.StatRef.DEFENSE) - before
	assert_almost_eq(delta, roundi(c.computed_stats.defense), 1)


func test_percentage_stat_baseline_is_100() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.HEALING_DONE)
	assert_eq(c.stats.get_stat(Stats.StatRef.HEALING_DONE), 100)


func test_percentage_stat_takes_multiplicative_modifier() -> void:
	var c := _make()
	c.state.add_modifier(_mod(Stats.StatRef.HEALING_DONE, StatModifier.Type.MULTIPLICATIVE, 0.2))
	StatCalculator.recalculate_stat(c, Stats.StatRef.HEALING_DONE)
	assert_eq(c.stats.get_stat(Stats.StatRef.HEALING_DONE), 120)


func test_temporary_modifiers_cleared_after_battle() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)
	var before := c.stats.get_stat(Stats.StatRef.DEFENSE)

	c.state.add_temporary_modifier(_mod(Stats.StatRef.DEFENSE, StatModifier.Type.ADDITIVE, 10.0))
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)
	assert_eq(c.stats.get_stat(Stats.StatRef.DEFENSE), before + 10)

	c.cleanup_after_battle()
	assert_eq(c.stats.get_stat(Stats.StatRef.DEFENSE), before)


func test_weapon_scaling_adds_attribute_contribution() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.ATTACK)
	var before := c.stats.get_stat(Stats.StatRef.ATTACK)

	var am := AttributeMultiplier.new()
	am.attribute = Attributes.AttributeRef.STR
	am.multiplier = 2.0
	var entry := WeaponScalingEntry.new()
	entry.stat = Stats.StatRef.ATTACK
	entry.attribute_contributions = [am]
	var scaling := WeaponScaling.new()
	scaling.entries = [entry]

	var w := Weapon.new()
	w.item_name = "gut sword"
	w.stats = Stats.new()
	w.base_stats = Stats.new()
	w.scaling = scaling
	c.equipment.weapon = w

	StatCalculator.recalculate_stat(c, Stats.StatRef.ATTACK)
	var str_value: int = c.attributes.get_attribute(Attributes.AttributeRef.STR)
	assert_eq(c.stats.get_stat(Stats.StatRef.ATTACK), before + roundi(str_value * 2.0))
