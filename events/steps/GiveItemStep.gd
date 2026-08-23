extends EventStep
class_name GiveItemStep


@export var item: ItemResource
@export var target_member_id: String = ""
@export var notify: bool = true


func run(_manager: EventManager) -> void:
	if item == null:
		push_error("GiveItemStep has no item set")
		return

	var receiver := _resolve_receiver()
	if receiver == null:
		push_warning("GiveItemStep: no receiver found (party empty?)")
		return

	var instance: Item = item._build_instance()
	if instance == null:
		push_error("GiveItemStep: item._build_instance() returned null")
		return

	var holder := receiver

	if not holder.inventory.add_item(instance):
		holder = null

		for m: Character in PartyManager.members:
			if m == receiver:
				continue
			if m.inventory.add_item(instance):
				holder = m
				break

	if holder == null:
		NotificationBus.notification_requested.emit("%s's inventory is full!" % receiver.resource.name)

		if instance.type == ItemTypes.ItemType.QUEST:
			MapInstance.queue_pending_key({ "id": instance.id, "name": instance.get_item_name() })

		return

	if instance.type == ItemTypes.ItemType.QUEST:
		MapInstance.mark_key_granted(instance.id)

	if notify:
		NotificationBus.notification_requested.emit("%s received %s" % [holder.resource.name, instance.get_item_name()])


func _resolve_receiver() -> Character:
	if PartyManager.members.is_empty():
		return null

	if target_member_id == "":
		return PartyManager.members[0]

	for m: Character in PartyManager.members:
		if m.resource.id == target_member_id:
			return m

	push_warning("GiveItemStep: party member %s not found" % target_member_id)
	return null
