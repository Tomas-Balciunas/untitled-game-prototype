extends Node

class_name GearGenerator

const MAX_QUANTITY = 5

const allowed_types: Array[Item.ItemType] = [
		Item.ItemType.WEAPON, 
		Item.ItemType.CHEST, 
		#Item.ItemType.HELMET,
		#Item.ItemType.BOOTS,
		#Item.ItemType.GLOVES,
		#Item.ItemType.RING,
		#Item.ItemType.AMULET,
		#Item.ItemType.CONSUMABLE
	]
	
var quantity: int:
	set(value):
		if value < 1 or value > MAX_QUANTITY:
			quantity = randi() % MAX_QUANTITY + 1
		else:
			quantity = value
	
var requested_types: Array[Item.ItemType]:
	set(value):
		if !value is Array:
			push_error("Types passed to generator must be an array of Item.ItemType!")
		
		if value.is_empty():
			requested_types = allowed_types
			
			return
		
		var filtered_types: Array[Item.ItemType] = []
		
		for type in value:
			if allowed_types.has(type):
				filtered_types.append(type)
		
		requested_types = filtered_types

func _init(qty: int, types: Array[Item.ItemType] = []) -> void:
	quantity = qty
	requested_types = types

func generate() -> Array[ItemInstance]:
	var builder: GearBuilder = GearBuilder.new()
	var generated_gear: Array[ItemInstance] = []
	var tiers: Array = MapInstance.available_tiers
	
	for i in range(quantity):
		var tier := get_tier(tiers)
		var type: Item.ItemType = requested_types[randi() % len(requested_types)]
		var item: ItemInstance = builder.build_item(type, tier)
		
		generated_gear.append(item)
		
	return generated_gear

func get_tier(tiers: Array) -> String:
	var rand := randi() % len(tiers)
	
	return tiers[rand]
