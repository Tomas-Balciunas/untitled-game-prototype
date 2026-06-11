extends GutTest

const ProbeEffect = preload("res://test/helpers/probe_effect.gd")

const PROBE_ID := "gut_probe_effect"


func after_each() -> void:
	EffectRegistry.effects.erase(PROBE_ID)
	SaveManager.load_issues.clear()


func test_restores_from_script_path() -> void:
	var e := ProbeEffect.new()
	e.id = PROBE_ID
	var restored := Effect.create_from_save(e.game_save())
	assert_not_null(restored)
	assert_true(restored is ProbeEffect)


func test_broken_script_path_falls_back_to_registry() -> void:
	var proto := ProbeEffect.new()
	proto.id = PROBE_ID
	EffectRegistry.register_effect(proto)

	var data := {
		"script": "res://moved_or_renamed.gd",
		"props": {"id": PROBE_ID, "duration_turns": 3, "probe_value": 7},
	}
	var restored := Effect.create_from_save(data)
	assert_not_null(restored)
	assert_true(restored is ProbeEffect)

	restored.game_load(data)
	assert_eq(restored.duration_turns, 3)
	assert_eq(restored.probe_value, 7)


func test_unrestorable_effect_reports_issue() -> void:
	var data := {"script": "res://moved_or_renamed.gd", "props": {"id": "unknown_id"}}
	var restored := Effect.create_from_save(data)
	assert_null(restored)
	assert_eq(SaveManager.load_issues.size(), 1)


func test_registry_auto_scan_registers_known_effects() -> void:
	assert_not_null(EffectRegistry.get_effect("poison_resistance_00"))
	assert_not_null(EffectRegistry.get_effect("heal_on_consume_00"))
	# Picked up by the scan despite never being in the old hand-maintained list.
	assert_not_null(EffectRegistry.get_effect("confusion"))
