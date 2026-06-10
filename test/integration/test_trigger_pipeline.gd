extends GutTest

const FakeCharacter = preload("res://test/helpers/fake_character.gd")
const RecordingEffect = preload("res://test/helpers/recording_effect.gd")

const STAGE := "test_pipeline_stage"

var subject: FakeCharacter
var _spawned: Array = []


func before_each() -> void:
	subject = FakeCharacter.new()
	_spawned = []


func after_each() -> void:
	for e in _spawned:
		EffectRunner.unsubscribe(e)


func _recorder(tag: String, priority: int, log_ref: Array, stops: bool = false) -> RecordingEffect:
	var e := RecordingEffect.new()
	e.tag = tag
	e.priority = priority
	e.log_ref = log_ref
	e.stage_name = STAGE
	e.stops = stops
	e.battle_only = false
	e.set_owner(subject)
	EffectRunner.subscribe(e)
	_spawned.append(e)
	return e


func _fire() -> void:
	var ev := TriggerEvent.new()
	ev.source = CharacterSource.new(subject)
	ev.ctx = ActionContext.new()
	ev.ctx.source = ev.source
	EffectRunner.process_trigger(STAGE, ev)


func test_effects_fire_in_priority_order() -> void:
	var log: Array = []
	_recorder("low", 100, log)
	_recorder("high", 900, log)
	_recorder("mid", 500, log)

	_fire()

	assert_eq(log, ["high", "mid", "low"])


func test_stop_processing_short_circuits() -> void:
	var log: Array = []
	_recorder("first", 900, log, true)
	_recorder("second", 100, log)

	_fire()

	assert_eq(log, ["first"])
