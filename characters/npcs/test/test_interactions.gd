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


func _greet() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = FIRST_GREET
	e.priority = 100
	e.conditions = [TagCondition.self_available(FIRST_GREET)]
	e.steps = EventBuilder.new() \
		.say("", ["Oh, a traveler!", "I'm the test dummy.", "Talk to me again — I do a lot of things."]) \
		.mark_self(FIRST_GREET) \
		.mark_self(MAIN_CHATTER, false) \
		.build()
	return e


func _quest_turn_in() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "quest_turn_in"
	e.priority = 90
	e.conditions = [
		TagCondition.self_completed(QUEST_OFFERED),
		TagCondition.self_not_completed(QUEST_DONE),
		InventoryCondition.any_has("hp pot"),
	]
	var lili_only: Array[InteractionCondition] = [PartyCondition.has(LILI_ID)]
	e.steps = EventBuilder.new() \
		.say("", ["You brought it!", "Here, take this in return."]) \
		.give_item(CHEAT_SWORD) \
		.apply_effect(ARCANE_RESONANCE) \
		.learn_skill(ARCANE_BOLT) \
		.mark_self(QUEST_DONE) \
		.say("", ["A sword, a blessing, and a new spell.", "Use them well."]) \
		.only_if(lili_only).say("Lili", ["Generous of him.", "Don't say I never bring you anywhere good."]) \
		.build()
	return e


func _quest_nag() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "quest_nag"
	e.priority = 80
	e.conditions = [
		TagCondition.self_completed(QUEST_OFFERED),
		TagCondition.self_not_completed(QUEST_DONE),
		NotCondition.of(InventoryCondition.any_has("hp pot")),
	]
	e.steps = EventBuilder.new() \
		.say("", ["Still thirsty.", "Find me an hp pot if you would."]) \
		.build()
	return e


func _quest_offer() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "quest_offer"
	e.priority = 70
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		TagCondition.self_not_completed(QUEST_OFFERED),
		TagCondition.self_not_completed(QUEST_DONE),
		PartyCondition.has_free_slot(),
	]
	e.steps = EventBuilder.new() \
		.say("", ["I've a parched throat.", "Bring me an hp pot — I'll make it worth your while."]) \
		.choose("Take the request?", [
			ChoiceOption.make(ACCEPT, "Accept"),
			ChoiceOption.make(DECLINE, "Decline"),
		]) \
		.when([ACCEPT]).say("", ["Bless you, traveler."]) \
		.when([DECLINE]).say("", ["Suit yourself."]) \
		.when([ACCEPT]).mark_self(QUEST_OFFERED) \
		.build()
	return e


func _post_quest() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "post_quest"
	e.priority = 10
	e.idle = true
	e.conditions = [TagCondition.self_completed(QUEST_DONE)]
	e.random_pick = true
	e.steps = EventBuilder.new() \
		.say("", ["Thanks again for the hp pot."]) \
		.say("", ["May your blade stay sharp."]) \
		.say("", ["The resonance suits you."]) \
		.build()
	return e


func _skill_ack() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "skill_ack"
	e.priority = 60
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		HasSkillCondition.any_knows("arcane_bolt"),
		TagCondition.self_not_completed("skill_ack_done"),
	]
	e.steps = EventBuilder.new() \
		.say("", ["Arcane bolt, eh?", "Decent pick."]) \
		.mark_self("skill_ack_done") \
		.build()
	return e


func _effect_ack() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "effect_ack"
	e.priority = 55
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		HasEffectCondition.any_has("arcane_resonance"),
		TagCondition.self_not_completed("effect_ack_done"),
	]
	e.steps = EventBuilder.new() \
		.say("", ["I feel the weave humming around you.", "Arcane resonance — nice."]) \
		.mark_self("effect_ack_done") \
		.build()
	return e


func _lili_in_party() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "lili_in_party"
	e.priority = 50
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		PartyCondition.has(LILI_ID),
		TagCondition.self_not_completed("lili_party_ack"),
	]
	e.steps = EventBuilder.new() \
		.say("", ["Lili made it onto your team — well done.", "Tell her I said hi."]) \
		.mark_self("lili_party_ack") \
		.build()
	return e


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
	e.steps = EventBuilder.new() \
		.say("", ["You've met Lili, but she's not with you?", "Strange days."]) \
		.mark_self("lili_seen_ack") \
		.build()
	return e


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
	e.steps = EventBuilder.new() \
		.say("", ["Few make it this far.", "Whether by numbers or by deed — well met."]) \
		.mark_self("secret_done") \
		.build()
	return e


func _combat_challenge() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = "combat_challenge"
	e.priority = 35
	e.conditions = [
		TagCondition.self_available(MAIN_CHATTER),
		TagCondition.self_not_completed("combat_done"),
		PartyCondition.has_free_slot(),
	]
	e.steps = EventBuilder.new() \
		.say("", ["Fancy a scrap?"]) \
		.choose("Fight the test dummy?", [
			ChoiceOption.make(ACCEPT, "Bring it"),
			ChoiceOption.make(DECLINE, "Pass"),
		]) \
		.when([ACCEPT]).say("", ["Then have at thee!"]) \
		.when([ACCEPT]).encounter("arena_default_00", ["0000"]) \
		.when([ACCEPT]).say("", ["Well struck.", "I yield."]) \
		.when([ACCEPT]).mark_self("combat_done") \
		.when([DECLINE]).say("", ["Coward."]) \
		.build()
	return e


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
	e.steps = EventBuilder.new() \
		.say("", ["No companions?", "Brave. Or foolish."]) \
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
		.say("", ["Hey there."]) \
		.say("", ["Hm?"]) \
		.say("", ["..."]) \
		.build()
	return e
