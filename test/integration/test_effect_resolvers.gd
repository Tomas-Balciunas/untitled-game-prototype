extends GutTest

const Combatant = preload("res://test/helpers/combatant.gd")
const FakeCharacter = preload("res://test/helpers/fake_character.gd")
const ProbeEffect = preload("res://test/helpers/probe_effect.gd")
const RecordingEffect = preload("res://test/helpers/recording_effect.gd")

const STAGE := "test_turn_stage"

var _built: Array = []
var _spawned: Array = []


func after_each() -> void:
	Combatant.free_built(_built)
	_built = []
	for e in _spawned:
		EffectRunner.unsubscribe(e)
	_spawned = []


func _make() -> Character:
	var c := Combatant.make()
	_built.append(c)
	return c


# --- EffectApplicationResolver ---

func test_application_adds_and_subscribes_effect() -> void:
	var target := _make()
	var attacker := _make()
	var before := target.effects.size()

	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(attacker)
	ctx.set_targets(target)
	EffectApplicationResolver.new(ProbeEffect.new()).execute(ctx)

	assert_eq(target.effects.size(), before + 1)
	assert_true(target.effects.back() is ProbeEffect)


# --- TurnStageResolver ---

func test_turn_stage_fires_subscribed_effect_for_stage() -> void:
	var owner := FakeCharacter.new()
	var log: Array = []

	var rec := RecordingEffect.new()
	rec.tag = "fired"
	rec.log_ref = log
	rec.stage_name = STAGE
	rec.battle_only = false
	rec.set_owner(owner)
	EffectRunner.subscribe(rec)
	_spawned.append(rec)

	TurnStageResolver.new(STAGE, owner).execute(ActionContext.new())

	assert_eq(log, ["fired"])
