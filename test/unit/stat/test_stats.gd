extends GutTest


func test_add_sums_all_fields() -> void:
	var a := Stats.new()
	a.attack = 10
	a.health = 50
	var b := Stats.new()
	b.attack = 5
	b.speed = 3
	a.add(b)
	assert_eq(a.attack, 15.0)
	assert_eq(a.health, 50.0)
	assert_eq(a.speed, 3.0)


func test_get_stat_rounds() -> void:
	var s := Stats.new()
	s.attack = 10.6
	assert_eq(s.get_stat(Stats.StatRef.ATTACK), 11)


func test_set_and_add_stat_by_ref() -> void:
	var s := Stats.new()
	s.set_stat(Stats.StatRef.DEFENSE, 12.0)
	assert_eq(s.defense, 12.0)
	s.add_stat(Stats.StatRef.DEFENSE, 3.0)
	assert_eq(s.defense, 15.0)


func test_percentage_stats() -> void:
	assert_true(Stats.is_percentage_stat(Stats.StatRef.HEALING_DONE))
	assert_true(Stats.is_percentage_stat(Stats.StatRef.HEALING_RECEIVED))
	assert_false(Stats.is_percentage_stat(Stats.StatRef.ATTACK))


func test_save_load_round_trip() -> void:
	var s := Stats.new()
	s.attack = 7
	s.healing_done = 110
	var restored := Stats.new()
	restored.game_load(s.game_save())
	assert_eq(restored.attack, 7.0)
	assert_eq(restored.healing_done, 110.0)
	assert_eq(restored.mana, 0.0)


func test_attributes_add_and_get() -> void:
	var a := Attributes.new()
	a.strength = 4
	var b := Attributes.new()
	b.strength = 2
	b.luck = 1
	a.add(b)
	assert_eq(a.get_attribute(Attributes.AttributeRef.STR), 6)
	assert_eq(a.get_attribute("LUK"), 1)
	assert_eq(a.get_attribute(Attributes.AttributeRef.IQ), 0)


func test_attributes_save_load_round_trip() -> void:
	var a := Attributes.new()
	a.vitality = 9
	a.dexterity = 3
	var restored := Attributes.new()
	restored.game_load(a.game_save())
	assert_eq(restored.vitality, 9)
	assert_eq(restored.dexterity, 3)
	assert_eq(restored.strength, 0)
