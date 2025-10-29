extends Interactable

class_name ChestInteractable

@export var quantity: int = 1
var chest: Chest = null

func _interact() -> void:
	build_items()
	
	if !chest:
		chest = Chest.new()
		chest.locked = true
		chest.items = build_items()
	
	ChestBus.open_chest_requested.emit(chest)
	
	#if items.is_empty():
		#NotificationBus.notification_requested.emit("Chest is empty!")
		#return
		
	
	#for member in PartyManager.members:
		#if items.is_empty():
			#break
			#
		#for item: Item in items.duplicate():
			#if member.inventory.has_free_slot():
				#var inst := item.instantiate()
				#member.inventory.add_item(inst)
				#NotificationBus.notification_requested.emit(
					#"%s has obtained %s from the chest!" % 
						#[member.resource.name, inst.get_item_name()]
					#)
				#items.erase(item)

func build_items() -> Array[Item]:
	var generator := GearGenerator.new(quantity)
	return generator.generate()
