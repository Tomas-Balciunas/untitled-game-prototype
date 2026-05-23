extends CharacterInteraction

class_name ShopTestInteractions

const SHOP = preload("uid://c1wunoveqkbnx")

const FIRST_GREET = "first_greet"

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
	out.append(_shop())

	return out

func _greet() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.id = FIRST_GREET
	e.priority = 100
	e.conditions = [TagCondition.self_available(FIRST_GREET)]
	e.steps = EventBuilder.new() \
		.say("", ["Greetings", "Lots of good things on sale"]) \
		.mark_self(FIRST_GREET) \
		.build()
	return e

func _shop() -> InteractionEntry:
	var e := InteractionEntry.new()
	e.priority = 110
	e.conditions = [TagCondition.self_completed(FIRST_GREET)]
	e.steps = EventBuilder.new() \
		.say("", ["Have a look around"]) \
		.open_shop(SHOP) \
		.build()
	
	return e
