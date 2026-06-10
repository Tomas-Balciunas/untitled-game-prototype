# Attacker accuracy is zeroed to skip DamageCalculator's randf() variance,
# making damage deterministic: final = base * 200/(200+defense).
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


func _attack(attacker: Character, target: Character, amount: int) -> void:
	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(attacker)
	ctx.set_targets(target)
	DamageResolver.new(amount).execute(ctx)


func test_deals_full_damage_with_zero_defense() -> void:
	var attacker := _make()
	var target := _make()
	attacker.stats.accuracy = 0.0
	target.stats.defense = 0.0
	var before := target.state.current_health
	_attack(attacker, target, 20)
	assert_eq(target.state.current_health, before - 20)


func test_defense_halves_damage() -> void:
	var attacker := _make()
	var target := _make()
	attacker.stats.accuracy = 0.0
	target.stats.defense = 200.0  # 200/(200+200) = 0.5
	var before := target.state.current_health
	_attack(attacker, target, 20)
	assert_eq(target.state.current_health, before - 10)


func test_lethal_damage_marks_dead() -> void:
	var attacker := _make()
	var target := _make()
	attacker.stats.accuracy = 0.0
	target.stats.defense = 0.0
	_attack(attacker, target, target.state.current_health + 50)
	assert_eq(target.state.current_health, 0)
	assert_true(target.is_dead)


func test_is_target_valid_for_real_character() -> void:
	var r := DamageResolver.new(1)
	assert_true(r.is_target_valid(_make()))
