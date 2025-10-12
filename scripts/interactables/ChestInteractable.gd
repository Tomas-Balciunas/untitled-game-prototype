extends Interactable

class_name ChestInteractable

@export var items: Array[ItemInstance]

func _interact():
	build_items()
	for item in items:
		for member in PartyManager.members:
			if member.inventory.has_free_slot():
				member.inventory.add_item(item)

func build_items():
	if not items.is_empty():
		return
		
	var item1 = Weapon.new()
	item1.type = Gear.ItemType.WEAPON
	item1.description = "Basic Sword"
	item1.name = "Sword"
	item1.base_attack = 15
	var inst1 = GearInstance.new()
	inst1.template = item1
	
	var item2 = Gear.new()
	item2.type = Gear.ItemType.CHEST
	item2.name = "Chest Armor"
	item2.base_health = 25
	var inst2 = GearInstance.new()
	inst2.template = item2

	items.append(inst1)
	items.append(inst2)
