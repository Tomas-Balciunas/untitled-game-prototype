extends GutTest


func test_additive_returns_flat_value() -> void:
	var m := StatModifier.new()
	m.type = StatModifier.Type.ADDITIVE
	m.value = 7.0
	assert_eq(m.compute_value(null, 100.0), 7.0)


func test_multiplicative_scales_derived_stat() -> void:
	var m := StatModifier.new()
	m.type = StatModifier.Type.MULTIPLICATIVE
	m.value = 0.25
	assert_eq(m.compute_value(null, 200.0), 50.0)


func test_description_formats_by_type() -> void:
	var add := StatModifier.new()
	add.stat = Stats.StatRef.ATTACK
	add.type = StatModifier.Type.ADDITIVE
	add.value = 5.0
	assert_eq(add.get_description(), "Attack ( +5)")

	var mult := StatModifier.new()
	mult.stat = Stats.StatRef.ATTACK
	mult.type = StatModifier.Type.MULTIPLICATIVE
	mult.value = 0.25
	assert_eq(mult.get_description(), "Attack (25%)")
