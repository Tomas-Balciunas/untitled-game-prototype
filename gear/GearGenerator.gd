extends Node

class_name GearGenerator

const MAX_QUANTITY = 5

const allowed_types: Array[Item.ItemType] = [
		Item.ItemType.WEAPON, 
		Item.ItemType.CHEST, 
		Item.ItemType.HELMET,
		Item.ItemType.BOOTS,
		Item.ItemType.GLOVES,
		Item.ItemType.RING,
		Item.ItemType.AMULET
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

func generate() -> Array[Gear]:
	var generated_gear: Array[Gear] = []
	for i in range(quantity):
		var type: Item.ItemType = requested_types[randi() % len(requested_types)]
		var item: Gear
		
		if type == Item.ItemType.WEAPON:
			var weapon := Weapon.new()
			weapon.type = type
			weapon.modifiers.append(BasicFlatModifierList.get_random_modifier())
			weapon.modifiers.append(BasicFlatModifierList.get_random_modifier())
			item = weapon
		else:
			var gear := Gear.new()
			gear.type = type
			gear.modifiers.append(BasicFlatModifierList.get_random_modifier())
			gear.modifiers.append(BasicFlatModifierList.get_random_modifier())
			item = gear
			
		item.base_stats = item.base_stats.duplicate(true)
		item.name = "Basic %s" % item.item_type_to_string(type)
		
		for stat: String in item.base_stats.keys():
			item.base_stats[stat] = randi() % 15
			
		generated_gear.append(item)
		
	return generated_gear
