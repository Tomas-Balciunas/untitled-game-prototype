extends GutTest

const Combatant = preload("res://test/helpers/combatant.gd")

var _built: Array = []
var _battle_log: RichTextLabel


func before_all() -> void:
	_battle_log = RichTextLabel.new()
	BattleTextLines.register_label(_battle_log)


func after_all() -> void:
	BattleTextLines.register_label(null)
	_battle_log.free()


func _make() -> Character:
	var c := Combatant.make()
	_built.append(c)
	return c


func after_each() -> void:
	Combatant.free_built(_built)
	_built = []


func test_level_up_after_enough_experience() -> void:
	var c := _make()
	var xp: ExperienceManager = c.experience_manager
	var start_level := c.level
	var start_points := c.unspent_attribute_points

	xp.grant_experience_to_character(c, xp.exp_for_level(start_level + 1) - c.current_experience)
	xp.level_up_character(c)

	assert_eq(c.level, start_level + 1)
	assert_eq(c.unspent_attribute_points, start_points + 2)


func test_no_level_up_without_enough_experience() -> void:
	var c := _make()
	var start_level := c.level
	c.experience_manager.level_up_character(c)
	assert_eq(c.level, start_level)


func test_multi_level_up_in_one_call() -> void:
	var c := _make()
	var xp: ExperienceManager = c.experience_manager
	var start_level := c.level

	xp.grant_experience_to_character(c, xp.exp_for_level(start_level + 2) - c.current_experience)
	xp.level_up_character(c)

	assert_eq(c.level, start_level + 2)
