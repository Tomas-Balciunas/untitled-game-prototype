extends Node

var door: Door = null

func _ready() -> void:
	ObjectBus.open_door_requested.connect(on_open_door_requested)
	ObjectBus.door_opener_chosen.connect(on_door_opened_chosen)
	MapBus.map_finished_loading.connect(_on_map_loaded)

func _on_map_loaded(_map_data: Dictionary) -> void:
	for entry: Dictionary in MapInstance.take_pending_keys():
		var instance: Item = KeyFactory.rebuild(entry.get("id", ""), entry.get("name", "Key"))._build_instance()
		var delivered: bool = false

		for member: Character in PartyManager.members:
			if member.inventory.add_item(instance):
				delivered = true
				break

		if delivered:
			MapInstance.mark_key_granted(instance.id)
		else:
			MapInstance.queue_pending_key(entry)

func on_open_door_requested(d: Door) -> void:
	if d.key == null and d.trap == null:
		return

	if d.key != null and d.trap == null and !_party_has_key(d.key.id):
		var sealed := EventBuilder.new()
		sealed.say("", ["Sealed. A plate reads: \"%s\"" % _seal_label(d)])
		await EventManager.process_event(sealed.build())
		return

	door = d
	ObjectBus.display_door_opener.emit()

func on_door_opened_chosen(opener: Character) -> void:
	if door == null:
		return

	var b := EventBuilder.new()
	var had_key: bool = door.key != null
	var consumed: bool = used_key() if had_key else true

	if had_key and consumed:
		b.say("", ["Used %s" % door.key.name])
	elif had_key:
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

	door.was_locked = had_key
	door.trap = null
	door.key = null
	ObjectBus.door_unlocked.emit(door)
	ObjectBus.door_state_changed.emit(door)

func _seal_label(d: Door) -> String:
	if !d.seal_name.is_empty():
		return d.seal_name

	if !d.key_name.is_empty():
		return d.key_name

	return "an unfamiliar sigil"

func _party_has_key(key_id: String) -> bool:
	for member: Character in PartyManager.members:
		if member.inventory.get_item_by_id(key_id) != null:
			return true

	return false

func door_disarmed(_opener: Character) -> bool:
	return randf() > 0.5

func used_key() -> bool:
	for member: Character in PartyManager.members:
		var item: Item = member.inventory.get_item_by_id(door.key.id)

		if item != null and member.inventory.remove_item(item):
			return true

	return false
