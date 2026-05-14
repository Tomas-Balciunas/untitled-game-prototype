extends EventStep
class_name GiveItemStep


@export var item: ItemResource
@export var target_member_id: String = ""


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

	if not receiver.inventory.add_item(instance):
		NotificationBus.notification_requested.emit("%s's inventory is full!" % receiver.resource.name)
		return

	NotificationBus.notification_requested.emit("%s received %s" % [receiver.resource.name, instance.get_item_name()])


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


static func to_first(p_item: ItemResource) -> GiveItemStep:
	var s := GiveItemStep.new()
	s.item = p_item
	return s


static func to_member(p_member_id: String, p_item: ItemResource) -> GiveItemStep:
	var s := GiveItemStep.new()
	s.item = p_item
	s.target_member_id = p_member_id
	return s
