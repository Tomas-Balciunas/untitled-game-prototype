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

func generate() -> Array[GearInstance]:
	var generated_gear: Array[GearInstance] = []
	for i in range(quantity):
		var type: Item.ItemType = requested_types[randi() % len(requested_types)]
		var item: GearInstance
		
		if type == Item.ItemType.WEAPON:
			var weapon := Weapon.new()
			weapon.type = type
			weapon.modifiers.append(BasicFlatModifierList.get_random_modifier())
			weapon.modifiers.append(BasicFlatModifierList.get_random_modifier())
			var inst := GearInstance.new()
			inst.template = weapon
			inst.template.name = "Basic %s" % inst.item_type_to_string(type)
			inst.extra_modifiers = weapon.modifiers
			
			item = inst
		else:
			var gear := Gear.new()
			gear.type = type
			gear.modifiers.append(BasicFlatModifierList.get_random_modifier())
			gear.modifiers.append(BasicFlatModifierList.get_random_modifier())
			var instance := GearInstance.new()
			instance.template = gear
			instance.template.name = "Basic %s" % instance.item_type_to_string(type)
			instance.extra_modifiers = gear.modifiers
			
			item = instance
			
		item.template.base_attack = randi() % 15 + 1
		item.template.base_defense = randi() % 10 + 1
		item.template.base_divine_power = randi() % 10 + 1
		item.template.base_health = randi() % 20 + 1
		item.template.base_magic_defense = randi() % 10 + 1
		item.template.base_magic_power = randi() % 10 + 1
		item.template.base_mana = randi() % 10 + 1
		item.template.base_resistance = randi() % 10 + 1
		item.template.base_speed = randi() % 5 + 1
		
		generated_gear.append(item)
		
	return generated_gear
