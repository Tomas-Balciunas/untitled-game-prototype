extends GutTest


func test_costs_round_up() -> void:
	var c := SkillCost.new()
	c.mana = 4.6
	c.sp = 2.2
	assert_eq(c.get_mana_cost(), 5)
	assert_eq(c.get_sp_cost(), 2)


func test_negative_costs_clamp_to_zero() -> void:
	var c := SkillCost.new()
	c.mana = -3.0
	c.sp = -1.0
	assert_eq(c.get_mana_cost(), 0)
	assert_eq(c.get_sp_cost(), 0)
