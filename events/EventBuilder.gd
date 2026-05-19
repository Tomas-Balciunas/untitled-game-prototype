extends RefCounted
class_name EventBuilder


var _steps: Array[EventStep] = []
var _pending_conditions: Array[String] = []
var _pending_world: Array[InteractionCondition] = []


func build() -> Array[EventStep]:
	return _steps


# --- gating (applies to the next appended step only) ---

func when(p_conditions: Array[String]) -> EventBuilder:
	_pending_conditions = p_conditions
	return self


func only_if(p_world: Array[InteractionCondition]) -> EventBuilder:
	_pending_world = p_world
	return self


# --- dialogue / choice ---

func say(speaker: String, lines: Array) -> EventBuilder:
	var s := DialogueStep.new()
	s.speaker = speaker
	var typed: Array[String] = []
	for l in lines:
		typed.append(l)
	s.lines = typed
	return _push(s)


func choose(text: String, options: Array[ChoiceOption]) -> EventBuilder:
	var s := ChoiceStep.new()
	s.text = text
	s.choices = options
	return _push(s)


# --- world ---

func encounter(arena: String, enemies: Array) -> EventBuilder:
	var s := EncounterStep.new()
	s.arena = arena
	var typed: Array[String] = []
	for e in enemies:
		typed.append(e)
	s.enemies = typed
	return _push(s)


func trap(t: Trap, target: Character) -> EventBuilder:
	var s := TrapStep.new()
	s.trap = t
	s.target = target
	return _push(s)


# --- tags ---

func mark_self(tag: String, completed: bool = true) -> EventBuilder:
	var s := MarkTagStep.new()
	s.state = MarkTagStep.State.COMPLETED if completed else MarkTagStep.State.AVAILABLE
	s.tag = tag
	return _push(s)


func mark_other(other_id: String, tag: String, completed: bool = true) -> EventBuilder:
	var s := MarkTagStep.new()
	s.state = MarkTagStep.State.COMPLETED if completed else MarkTagStep.State.AVAILABLE
	s.target = MarkTagStep.Target.OTHER
	s.target_id = other_id
	s.tag = tag
	return _push(s)


# --- rewards / mutations ---

func give_gold(amount: int, notify: bool = true) -> EventBuilder:
	var s := GiveGoldStep.new()
	s.amount = amount
	s.notify = notify
	return _push(s)


func give_item(item: ItemResource, notify: bool = true) -> EventBuilder:
	var s := GiveItemStep.new()
	s.item = item
	s.notify = notify
	return _push(s)


func give_item_to(member_id: String, item: ItemResource, notify: bool = true) -> EventBuilder:
	var s := GiveItemStep.new()
	s.item = item
	s.target_member_id = member_id
	s.notify = notify
	return _push(s)


func apply_effect(effect: Effect) -> EventBuilder:
	var s := ApplyEffectStep.new()
	s.effect = effect
	return _push(s)


func apply_effect_to(member_id: String, effect: Effect) -> EventBuilder:
	var s := ApplyEffectStep.new()
	s.effect = effect
	s.target_member_id = member_id
	return _push(s)


func learn_skill(skill: Skill) -> EventBuilder:
	var s := LearnSkillStep.new()
	s.skill = skill
	return _push(s)


func learn_skill_for(member_id: String, skill: Skill) -> EventBuilder:
	var s := LearnSkillStep.new()
	s.skill = skill
	s.target_member_id = member_id
	return _push(s)


func recruit(party_full_tag: String = "") -> EventBuilder:
	var s := RecruitCharacterStep.new()
	s.party_full_tag = party_full_tag
	return _push(s)


# --- internal ---

func _push(step: EventStep) -> EventBuilder:
	if not _pending_conditions.is_empty():
		step.conditions = _pending_conditions
		_pending_conditions = []
	if not _pending_world.is_empty():
		step.world_conditions = _pending_world
		_pending_world = []
	_steps.append(step)
	return self
