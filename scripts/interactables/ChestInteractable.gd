extends Interactable

class_name ChestInteractable

@export var items: Array[ItemInstance]

func _interact() -> void:
	build_items()
	
	if items.is_empty():
		NotificationBus.notification_requested.emit("Chest is empty!")
		return
		
	
	for member in PartyManager.members:
		if items.is_empty():
			break
			
		for item: ItemInstance in items.duplicate():
			if member.inventory.has_free_slot():
				member.inventory.add_item(item)
				NotificationBus.notification_requested.emit(
					"%s has obtained %s from the chest!" % 
						[member.resource.name, item.get_item_name()]
					)
				items.erase(item)

func build_items() -> void:
	if not items.is_empty():
		return
		
	var generator := GearGenerator.new(3)
	items.append_array(generator.generate())
		
	#var item1: Weapon = Weapon.new()
	#item1.type = Gear.ItemType.WEAPON
	#item1.description = "Basic Sword"
	#item1.name = "Sword"
	#item1.base_attack = 15
	#var inst1: GearInstance = GearInstance.new()
	#inst1.template = item1
	#
	#var item2: Gear = Gear.new()
	#item2.type = Gear.ItemType.CHEST
	#item2.name = "Chest Armor"
	#item2.base_health = 25
	#var inst2: GearInstance = GearInstance.new()
	#inst2.template = item2
#
	#items.append(inst1)
	#items.append(inst2)
