extends Node

var door: Door = null

func _ready() -> void:
	ObjectBus.open_door_requested.connect(on_open_door_requested)
	ObjectBus.door_opener_chosen.connect(on_door_opened_chosen)

func on_open_door_requested(d: Door) -> void:
	door = d
	if door.key != null or door.trap != null:
		ObjectBus.display_door_opener.emit()


func on_door_opened_chosen(opener: Character) -> void:
	var b := EventBuilder.new()
	
	if door.key and used_key():
		b.say("", ["Used %s" % door.key.get_item_name()])
	elif door.key and !used_key():
		b.say("", ["Locked!"])
		await EventManager.process_event(b.build())
		return
	
	if door.trap:
		b.say("", ["%s attempts to disarm the trap..." % opener.resource.name])
		
		if door_disarmed(opener):
			b.say("", ["Trap disarmed!"])
		else:
			b.say("", ["Oops! %s" % door.trap.name]).trap(door.trap, opener)
	
	await EventManager.process_event(b.build())
	door.trap = null
	door.key = null

func door_disarmed(opener: Character) -> bool:
	return randf() > 0.5

func used_key() -> bool:
	for member: Character in PartyManager.members:
		var item: Item = member.inventory.get_item_by_id(door.key.id)
		
		if item != null and member.inventory.remove_item(item):
			return true
	
	return false
