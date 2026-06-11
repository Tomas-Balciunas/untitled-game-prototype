# Curve: each level costs round(100 * 1.45^(lvl-2)) on top of the previous total.
extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")

var xp: ExperienceManager


func before_each() -> void:
	xp = ExperienceManager.new()


func test_level_one_and_below_cost_nothing() -> void:
	assert_eq(xp.exp_for_level(0), 0)
	assert_eq(xp.exp_for_level(1), 0)


func test_curve_values() -> void:
	assert_eq(xp.exp_for_level(2), 100)
	assert_eq(xp.exp_for_level(3), 245)   # 100 + 145
	assert_eq(xp.exp_for_level(4), 455)   # 245 + round(210.25)


func test_can_level_up_thresholds() -> void:
	var c := FakeCharacter.new()
	c.level = 1
	c.current_experience = 99
	assert_false(xp.can_level_up(c))
	c.current_experience = 100
	assert_true(xp.can_level_up(c))


func test_grant_experience_accumulates() -> void:
	var c := FakeCharacter.new()
	c.current_experience = 10
	xp.grant_experience_to_character(c, 15)
	assert_eq(c.current_experience, 25)
