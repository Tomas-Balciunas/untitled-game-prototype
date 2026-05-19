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
	e.steps = EventBuilder.new() \
		.say("", ["Greetings dungeon delver", "My name is Lili", "Pleasure to meet you"]) \
		.mark_self(FIRST_ENCOUNTER) \
		.mark_self(FIRST_ENCOUNTER_SECOND, false) \
		.build()
	return e


func _recruit_offer() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = FIRST_ENCOUNTER_SECOND
	e.priority = 10
	e.conditions = [
		TagCondition.self_available(FIRST_ENCOUNTER_SECOND),
		PartyCondition.missing_self(),
	]
	e.steps = EventBuilder.new() \
		.say("", ["My party's been..", "Perhaps I could join you?"]) \
		.choose("Allow Lili to join the party?", [
			ChoiceOption.make(ALLOWED_TO_JOIN, "accept"),
			ChoiceOption.make(DISALLOWED_TO_JOIN, "refuse"),
		]) \
		.when([DISALLOWED_TO_JOIN]).say("", ["Okay..."]) \
		.when([ALLOWED_TO_JOIN]).mark_self(FIRST_ENCOUNTER_SECOND) \
		.when([ALLOWED_TO_JOIN]).recruit(PARTY_FULL_MARKER) \
		.when([ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]).say("", ["It seems like there's no place for me.."]) \
		.when([ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]).mark_self(RECRUIT_LILI_AGAIN, false) \
		.build()
	return e


func _recruit_lili_again() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = RECRUIT_LILI_AGAIN
	e.priority = 50
	e.conditions = [
		TagCondition.self_available(RECRUIT_LILI_AGAIN),
		PartyCondition.missing_self(),
	]
	e.steps = EventBuilder.new() \
		.say("", ["Hey", "Have you found space for me?"]) \
		.choose("Allow Lili to join the party?", [
			ChoiceOption.make(ALLOWED_TO_JOIN, "yes"),
			ChoiceOption.make(DISALLOWED_TO_JOIN, "no"),
		]) \
		.when([DISALLOWED_TO_JOIN]).say("", ["Just kill someone"]) \
		.when([ALLOWED_TO_JOIN]).mark_self(RECRUIT_LILI_AGAIN) \
		.when([ALLOWED_TO_JOIN]).recruit(PARTY_FULL_MARKER) \
		.when([ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]).say("", ["It seems like there's no place for me.."]) \
		.when([ALLOWED_TO_JOIN, RecruitCharacterStep.PARTY_FULL]).mark_self(RECRUIT_LILI_AGAIN, false) \
		.build()
	return e


func _idle_default() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "idle_default"
	e.priority = 1
	e.idle = true
	e.random_pick = true
	e.steps = EventBuilder.new() \
		.say("", ["Oh!"]) \
		.say("", ["What's up?"]) \
		.say("", ["Hey"]) \
		.build()
	return e
