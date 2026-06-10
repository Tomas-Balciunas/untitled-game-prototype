# Healing = round(base * healing_received/100 * healing_done/100), where
# base = heal + round(divine_power * scaling). Multipliers are set to 100% so
# the assertions are exact
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


func _heal(healer: Character, target: Character, amount: int, scaling: float = 0.0) -> void:
	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(healer)
	ctx.set_targets(target)
	HealingResolver.new(amount, scaling).execute(ctx)


func test_flat_heal_at_full_multipliers() -> void:
	var healer := _make()
	var target := _make()
	healer.stats.healing_done = 100.0
	target.stats.healing_received = 100.0
	target.state.current_health = 1
	_heal(healer, target, 10)
	assert_eq(target.state.current_health, 11)


func test_divine_power_scaling_adds_to_base() -> void:
	var healer := _make()
	var target := _make()
	healer.stats.healing_done = 100.0
	healer.stats.divine_power = 10.0
	target.stats.healing_received = 100.0
	target.state.current_health = 1
	_heal(healer, target, 0, 2.0)  # base = 0 + round(10 * 2) = 20
	assert_eq(target.state.current_health, 21)


func test_heal_clamps_to_max_health() -> void:
	var healer := _make()
	var target := _make()
	healer.stats.healing_done = 100.0
	target.stats.healing_received = 100.0
	target.state.current_health = int(target.stats.health) - 2
	_heal(healer, target, 100)
	assert_eq(target.state.current_health, int(target.stats.health))
