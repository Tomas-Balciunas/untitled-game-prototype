extends Node


var chest: Chest = null

func _ready() -> void:
	ChestBus.open_chest_requested.connect(on_open_chest_requested)
	ChestBus.chest_opener_chosen.connect(on_chest_opener_chosen)

func on_open_chest_requested(c: Chest) -> void:
	chest = c
	if chest.trapped:
		ChestBus.display_chest_opener.emit()
	else:
		ChestBus.display_chest_content.emit(chest)

func on_chest_opener_chosen(character: Character) -> void:
	var line_1 := "%s attempts to open the chest..." % character.resource.name
	var trap: Trap
	if chest.trap:
		trap = chest.trap
	else:
		trap = TrapRegistry.get_random_trap()

	var b := EventBuilder.new().say("", [line_1])
	if randf() > 0:
		b.say("", ["Oops! %s" % trap.name]).trap(trap, character)
	else:
		b.say("", ["Open!"])

	await EventManager.process_event(b.build())
	chest.set_trapped(false)
	ChestBus.display_chest_content.emit(chest)
