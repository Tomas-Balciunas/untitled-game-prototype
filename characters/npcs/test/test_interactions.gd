extends CharacterInteraction

class_name TestNPCInteractions


const LILI_ID := "a_lili_1"

const FIRST_GREET := "first_greet"
const MAIN_CHATTER := "main_chatter"
const QUEST_OFFERED := "quest_offered"
const QUEST_DONE := "quest_done"

const ACCEPT := "accept"
const DECLINE := "decline"

const HP_POT: ItemResource = preload("res://gear/consumable/hp pot minor/hp_pot.tres")
const CHEAT_SWORD: ItemResource = preload("res://gear/weapon/cheat_sword.tres")
const ARCANE_RESONANCE: Effect = preload("res://effect/_passive/arcane_resonance/arcane_resonance.tres")
const ARCANE_BOLT: Skill = preload("res://skills/_offensive/arcane_bolt.tres")


var _entries: Array[InteractionEntry] = []


func _init() -> void:
	_entries = _build_entries()


func get_entries() -> Array[InteractionEntry]:
	return _entries


func _get_default_tags() -> Array[String]:
	return [FIRST_GREET]


func _build_entries() -> Array[InteractionEntry]:
	var out: Array[InteractionEntry] = []

	out.append(_greet())
	out.append(_quest_turn_in())
	out.append(_quest_nag())
	out.append(_quest_offer())
	out.append(_post_quest())
	out.append(_skill_ack())
	out.append(_effect_ack())
	out.append(_lili_in_party())
	out.append(_lili_met_elsewhere())
	out.append(_secret_combo())
	out.append(_combat_challenge())
	out.append(_party_alone())
	out.append(_idle_default())

	return out


# Priority 100 — fires exactly once (default tag FIRST_GREET is available at setup).
func _greet() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = FIRST_GREET
	e.priority = 100
	e.conditions = [TagCondition.self_available(FIRST_GREET)]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Oh, a traveler!", "I'm the test dummy.", "Talk to me again — I do a lot of things."]),
		MarkTagStep.self_completed(FIRST_GREET),
		MarkTagStep.self_available(MAIN_CHATTER),
	]
	e.steps = steps
	return e


# Priority 90 — quest turn-in beats the offer once you actually have the item.
func _quest_turn_in() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "quest_turn_in"
	e.priority = 90
	e.conditions = [
		TagCondition.self_completed(QUEST_OFFERED),
		TagCondition.self_not_completed(QUEST_DONE),
		InventoryCondition.any_has("hp pot"),
	]
	var lili_chime := DialogueStep.say("Lili", ["Generous of him.", "Don't say I never bring you anywhere good."])
	lili_chime.world_conditions = [PartyCondition.has(LILI_ID)]

	var steps: Array[EventStep] = [
		DialogueStep.say("", ["You brought it!", "Here, take this in return."]),
		GiveItemStep.to_first(CHEAT_SWORD),
		ApplyEffectStep.to_first(ARCANE_RESONANCE),
		LearnSkillStep.to_first(ARCANE_BOLT),
		MarkTagStep.self_completed(QUEST_DONE),
		DialogueStep.say("", ["A sword, a blessing, and a new spell.", "Use them well."]),
		lili_chime,
	]
	e.steps = steps
	return e


# Priority 80 — nag if quest offered but no item brought yet.
func _quest_nag() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "quest_nag"
	e.priority = 80
	e.conditions = [
		TagCondition.self_completed(QUEST_OFFERED),
		TagCondition.self_not_completed(QUEST_DONE),
		NotCondition.of(InventoryCondition.any_has("hp pot")),
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Still thirsty.", "Find me an hp pot if you would."]),
	]
	e.steps = steps
	return e


# Priority 70 — first offer of the quest.
func _quest_offer() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "quest_offer"
	e.priority = 70
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		TagCondition.self_not_completed(QUEST_OFFERED),
		TagCondition.self_not_completed(QUEST_DONE),
		PartyCondition.has_free_slot(),  # arbitrary extra condition exercising party check
	]

	var thanks := DialogueStep.say("", ["Bless you, traveler."])
	thanks.conditions = [ACCEPT]

	var bummer := DialogueStep.say("", ["Suit yourself."])
	bummer.conditions = [DECLINE]

	var mark := MarkTagStep.self_completed(QUEST_OFFERED)
	mark.conditions = [ACCEPT]

	var steps: Array[EventStep] = [
		DialogueStep.say("", ["I've a parched throat.", "Bring me an hp pot — I'll make it worth your while."]),
		ChoiceStep.prompt("Take the request?", [
			ChoiceOption.make(ACCEPT, "Accept"),
			ChoiceOption.make(DECLINE, "Decline"),
		]),
		thanks,
		bummer,
		mark,
	]
	e.steps = steps
	return e


# Themed idle once the quest is done; wins over the generic idle but loses to anything non-idle.
func _post_quest() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "post_quest"
	e.priority = 10
	e.idle = true
	e.conditions = [TagCondition.self_completed(QUEST_DONE)]
	e.random_pick = true
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Thanks again for the hp pot."]),
		DialogueStep.say("", ["May your blade stay sharp."]),
		DialogueStep.say("", ["The resonance suits you."]),
	]
	e.steps = steps
	return e


# Priority 60 — acknowledges a granted skill anywhere in the party.
func _skill_ack() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "skill_ack"
	e.priority = 60
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		HasSkillCondition.any_knows("arcane_bolt"),
		TagCondition.self_not_completed("skill_ack_done"),
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Arcane bolt, eh?", "Decent pick."]),
		MarkTagStep.self_completed("skill_ack_done"),
	]
	e.steps = steps
	return e


# Priority 55 — acknowledges a granted effect anywhere in the party.
func _effect_ack() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "effect_ack"
	e.priority = 55
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		HasEffectCondition.any_has("arcane_resonance"),
		TagCondition.self_not_completed("effect_ack_done"),
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["I feel the weave humming around you.", "Arcane resonance — nice."]),
		MarkTagStep.self_completed("effect_ack_done"),
	]
	e.steps = steps
	return e


# Priority 50 — Lili is currently in the party.
func _lili_in_party() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "lili_in_party"
	e.priority = 50
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		PartyCondition.has(LILI_ID),
		TagCondition.self_not_completed("lili_party_ack"),
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Lili made it onto your team — well done.", "Tell her I said hi."]),
		MarkTagStep.self_completed("lili_party_ack"),
	]
	e.steps = steps
	return e


# Priority 45 — Lili was met but isn't in the party.
func _lili_met_elsewhere() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "lili_met_elsewhere"
	e.priority = 45
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		TagCondition.other_completed(LILI_ID, LiliInteractions.FIRST_ENCOUNTER),
		PartyCondition.missing(LILI_ID),
		TagCondition.self_not_completed("lili_seen_ack"),
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["You've met Lili, but she's not with you?", "Strange days."]),
		MarkTagStep.self_completed("lili_seen_ack"),
	]
	e.steps = steps
	return e


# Priority 40 — OR-condition across systems: party of 3+, OR you've cleared the test event.
func _secret_combo() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "secret_combo"
	e.priority = 40
	var size_3 := PartyCondition.new()
	size_3.check = PartyCondition.Check.SIZE_AT_LEAST
	size_3.size = 3
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		AnyOfCondition.of([
			size_3,
			EventCompletedCondition.completed("test_event_000"),
		]),
		TagCondition.self_not_completed("secret_done"),
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Few make it this far.", "Whether by numbers or by deed — well met."]),
		MarkTagStep.self_completed("secret_done"),
	]
	e.steps = steps
	return e


# Priority 35 — combat challenge launched from dialogue.
func _combat_challenge() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "combat_challenge"
	e.priority = 35
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		TagCondition.self_not_completed("combat_done"),
		PartyCondition.has_free_slot(),  # don't pick a fight with a full party? arbitrary
	]

	var coward := DialogueStep.say("", ["Coward."])
	coward.conditions = [DECLINE]

	var pre_fight := DialogueStep.say("", ["Then have at thee!"])
	pre_fight.conditions = [ACCEPT]

	var fight := EncounterStep.against("arena_default_00", ["0000"])
	fight.conditions = [ACCEPT]

	var post := DialogueStep.say("", ["Well struck.", "I yield."])
	post.conditions = [ACCEPT]

	var done := MarkTagStep.self_completed("combat_done")
	done.conditions = [ACCEPT]

	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Fancy a scrap?"]),
		ChoiceStep.prompt("Fight the test dummy?", [
			ChoiceOption.make(ACCEPT, "Bring it"),
			ChoiceOption.make(DECLINE, "Pass"),
		]),
		pre_fight,
		fight,
		post,
		done,
		coward,
	]
	e.steps = steps
	return e


# Priority 30 — fires when no companions have joined the MC yet.
func _party_alone() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "party_alone"
	e.priority = 30
	var size_1 := PartyCondition.new()
	size_1.check = PartyCondition.Check.SIZE_AT_MOST
	size_1.size = 1
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		size_1,
	]
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["No companions?", "Brave. Or foolish."]),
	]
	e.steps = steps
	return e


# Generic idle fallback — random one-liner when nothing else (idle or otherwise) matches.
func _idle_default() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "idle_default"
	e.priority = 1
	e.idle = true
	e.random_pick = true
	var steps: Array[EventStep] = [
		DialogueStep.say("", ["Oh!"]),
		DialogueStep.say("", ["Hey there."]),
		DialogueStep.say("", ["Hm?"]),
		DialogueStep.say("", ["..."]),
	]
	e.steps = steps
	return e
