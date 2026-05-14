extends CharacterInteraction

class_name LiliInteractions


const PARTY_FULL_MARKER = "party_full_marker"

const FIRST_ENCOUNTER = "first_encounter"
const FIRST_ENCOUNTER_SECOND = "first_encounter_continued"
const RECRUIT_LILI_AGAIN = "recruit_lili_again"

const ALLOWED_TO_JOIN = "allowed_to_join"
const DISALLOWED_TO_JOIN = "disallowed_to_join"


var _entries: Array[InteractionEntry] = []


func _init() -> void:
	_entries = _build_entries()


func get_entries() -> Array[InteractionEntry]:
	return _entries


func _get_default_tags() -> Array[String]:
	return [FIRST_ENCOUNTER]


func _build_entries() -> Array[InteractionEntry]:
	var out: Array[InteractionEntry] = []

	out.append(_first_encounter())
	out.append(_recruit_offer())
	out.append(_recruit_lili_again())
	out.append(_idle_default())

	return out


func _first_encounter() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = FIRST_ENCOUNTER
	e.priority = 10
	e.conditions = [TagCondition.self_available(FIRST_ENCOUNTER)]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Greetings dungeon delver", "My name is Lili", "Pleasure to meet you"]),
		MarkTagStep.self_completed(FIRST_ENCOUNTER),
		MarkTagStep.self_available(FIRST_ENCOUNTER_SECOND),
	]
	e.steps = steps
	return e


func _recruit_offer() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = FIRST_ENCOUNTER_SECOND
	e.priority = 10
	e.conditions = [
		TagCondition.self_available(FIRST_ENCOUNTER_SECOND),
		PartyCondition.missing_self(),
	]

	var refused := DialogueStep.say("", ["Okay..."])
	refused.conditions = [DISALLOWED_TO_JOIN]

	var mark_done := MarkTagStep.self_completed(FIRST_ENCOUNTER_SECOND)
	mark_done.conditions = [ALLOWED_TO_JOIN]

	var recruit := RecruitCharacterStep.with_party_full_tag(PARTY_FULL_MARKER)
	recruit.conditions = [ALLOWED_TO_JOIN]

	var no_place := DialogueStep.say("", ["It seems like there's no place for me.."])
	no_place.conditions = [ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]

	var unlock_retry := MarkTagStep.self_available(RECRUIT_LILI_AGAIN)
	unlock_retry.conditions = [ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]

	var steps: Array[EventStep] = [
		DialogueStep.say("", ["My party's been..", "Perhaps I could join you?"]),
		ChoiceStep.prompt("Allow Lili to join the party?", [
			ChoiceOption.make(ALLOWED_TO_JOIN, "accept"),
			ChoiceOption.make(DISALLOWED_TO_JOIN, "refuse"),
		]),
		refused,
		mark_done,
		recruit,
		no_place,
		unlock_retry,
	]
	e.steps = steps

	return e


func _recruit_lili_again() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = RECRUIT_LILI_AGAIN
	e.priority = 50
	e.conditions = [
		TagCondition.self_available(RECRUIT_LILI_AGAIN),
		PartyCondition.missing_self(),
	]

	var refused := DialogueStep.say("", ["Just kill someone"])
	refused.conditions = [DISALLOWED_TO_JOIN]

	var mark_done := MarkTagStep.self_completed(RECRUIT_LILI_AGAIN)
	mark_done.conditions = [ALLOWED_TO_JOIN]

	var recruit := RecruitCharacterStep.with_party_full_tag(PARTY_FULL_MARKER)
	recruit.conditions = [ALLOWED_TO_JOIN]

	var no_place := DialogueStep.say("", ["It seems like there's no place for me.."])
	no_place.conditions = [ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]

	var unlock_retry := MarkTagStep.self_available(RECRUIT_LILI_AGAIN)
	unlock_retry.conditions = [ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]

	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Hey", "Have you found space for me?"]),
		ChoiceStep.prompt("Allow Lili to join the party?", [
			ChoiceOption.make(ALLOWED_TO_JOIN, "yes"),
			ChoiceOption.make(DISALLOWED_TO_JOIN, "no"),
		]),
		refused,
		mark_done,
		recruit,
		no_place,
		unlock_retry,
	]
	e.steps = steps

	return e


func _idle_default() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "idle_default"
	e.priority = 1
	e.idle = true
	e.random_pick = true
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Oh!"]),
		DialogueStep.say("", ["What's up?"]),
		DialogueStep.say("", ["Hey"]),
	]
	e.steps = steps
	return e
