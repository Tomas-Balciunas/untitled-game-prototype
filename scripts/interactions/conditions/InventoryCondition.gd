extends InteractionCondition

class_name InventoryCondition


@export var item_name: String = ""
@export var target_member_id: String = ""


func matches(_c: BaseCharacterResource) -> bool:
	if item_name == "":
		push_error("InventoryCondition has empty item_name")
		return false

	if target_member_id != "":
		for m: Character in PartyManager.members:
			if m.resource.id == target_member_id:
				return _member_has_item(m)
		return false

	for m: Character in PartyManager.members:
		if _member_has_item(m):
			return true

	return false


func _member_has_item(m: Character) -> bool:
	for item: Item in m.inventory.get_all_items():
		if item.get_item_name() == item_name:
			return true
	return false


static func any_has(p_item_name: String) -> InventoryCondition:
	var c := InventoryCondition.new()
	c.item_name = p_item_name
	return c


static func member_has(p_member_id: String, p_item_name: String) -> InventoryCondition:
	var c := InventoryCondition.new()
	c.item_name = p_item_name
	c.target_member_id = p_member_id
	return c
