extends GutTest

const Combatant = preload("res://test/helpers/combatant.gd")
const ProbeEffect = preload("res://test/helpers/probe_effect.gd")
const RecordingEffect = preload("res://test/helpers/recording_effect.gd")

var _built: Array = []


func _make() -> Character:
	var c := Combatant.make()
	_built.append(c)
	return c


func after_each() -> void:
	Combatant.free_built(_built)
	_built = []


func test_mana_clamps_between_zero_and_max() -> void:
	var c := _make()
	c.set_current_mana(-10)
	assert_eq(c.state.current_mana, 0)
	c.set_current_mana(int(c.stats.mana) + 100)
	assert_eq(c.state.current_mana, int(c.stats.mana))


func test_mana_consumed_signal() -> void:
	var c := _make()
	c.state.current_mana = 10
	watch_signals(c)
	c.set_current_mana(4)
	assert_signal_emitted_with_parameters(c, "mana_consumed", [6, c])


func test_sp_clamps_between_zero_and_max() -> void:
	var c := _make()
	c.set_current_sp(-5)
	assert_eq(c.state.current_sp, 0)
	c.set_current_sp(int(c.stats.sp) + 100)
	assert_eq(c.state.current_sp, int(c.stats.sp))


func test_skill_cost_consume_deducts_resources() -> void:
	var c := _make()
	c.stats.mana = 50
	c.stats.sp = 50
	c.state.current_mana = 20
	c.state.current_sp = 20

	var cost := SkillCost.new()
	cost.mana = 8
	cost.sp = 3
	cost.consume(CharacterSource.new(c))

	assert_eq(c.state.current_mana, 12)
	assert_eq(c.state.current_sp, 17)


func test_cleanup_after_battle_unsubscribes_expiring_effects() -> void:
	var c := _make()
	var rec := RecordingEffect.new()
	rec.stage_name = "gut_cleanup_stage"
	rec.expires_after_battle = true
	rec.battle_only = false

	var inst: RecordingEffect = c.apply_effect(rec, CharacterSource.new(c))
	var log: Array = []
	inst.log_ref = log
	inst.tag = "leaked"

	var ev := TriggerEvent.new()
	ev.source = CharacterSource.new(c)
	ev.ctx = ActionContext.new()
	ev.ctx.source = ev.source

	EffectRunner.process_trigger(rec.stage_name, ev)
	assert_eq(log, ["leaked"], "sanity: effect fires while applied")

	c.cleanup_after_battle()

	EffectRunner.process_trigger(rec.stage_name, ev)
	assert_eq(log, ["leaked"], "removed effect must not receive triggers")
	assert_false(EffectRunner._subscriptions.get(rec.stage_name, []).has(inst))


func test_cleanup_after_battle_removes_expiring_effects() -> void:
	var c := _make()
	var battle_scoped := ProbeEffect.new()
	battle_scoped.expires_after_battle = true
	var persistent := ProbeEffect.new()
	persistent.expires_after_battle = false

	var kept := c.apply_effect(persistent, CharacterSource.new(c))
	c.apply_effect(battle_scoped, CharacterSource.new(c))

	c.cleanup_after_battle()

	assert_true(c.effects.has(kept))
	for e in c.effects:
		assert_false(e.expires_after_battle, "battle-scoped effects should be gone")
