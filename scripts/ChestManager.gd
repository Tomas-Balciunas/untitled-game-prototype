extends Node


var chest: Chest = null

func _ready() -> void:
	ChestBus.open_chest_requested.connect(on_open_chest_requested)
	ChestBus.chest_opener_chosen.connect(on_chest_opener_chosen)

func on_open_chest_requested(c: Chest) -> void:
	chest = c
	if chest.key != null or chest.trap != null:
		ChestBus.display_chest_opener.emit()
	else:
		ChestBus.display_chest_content.emit(chest)

func on_chest_opener_chosen(character: Character) -> void:
	var b := EventBuilder.new()
	b.say("", ["%s attempts to open the chest..." % character.resource.name])
	
	if chest.key and used_key():
		b.say("", ["Used %s" % chest.key.get_item_name()])
	elif chest.key and !used_key():
		b.say("", ["Locked!"])
		await EventManager.process_event(b.build())
		return
	
	if chest.trap:
		if chest_disarmed(character):
			b.say("", ["Trap disarmed!"])
		else:
			b.say("", ["Oops! %s" % chest.trap.name]).trap(chest.trap, character)
	else:
		b.say("", ["Open!"])

	await EventManager.process_event(b.build())
	chest.set_not_trapped()
	chest.set_unlocked()
	ChestBus.display_chest_content.emit(chest)

func chest_disarmed(_opener: Character) -> bool:
	return randf() > 0.5

func used_key() -> bool:
	for member: Character in PartyManager.members:
		var item: Item = member.inventory.get_item_by_id(chest.key.id)
		
		if item != null and member.inventory.remove_item(item):
			return true
	
	return false
