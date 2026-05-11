extends Node

class_name GearGenerator

const MAX_QUANTITY = 10

const allowed_types: Array[GearResource.Type] = [
		GearResource.Type.WEAPON, 
		GearResource.Type.CHEST, 
		GearResource.Type.HELMET,
		GearResource.Type.BOOTS,
		GearResource.Type.GLOVES,
		GearResource.Type.RING,
		GearResource.Type.AMULET,
		#ItemResource.ItemType.CONSUMABLE
	]
	
var quantity: int:
	set(value):
		if value < 1 or value > MAX_QUANTITY:
			quantity = randi() % MAX_QUANTITY + 1
		else:
			quantity = value
	
var requested_types: Array[GearResource.Type]:
	set(value):
		if !value is Array:
			push_error("Types passed to generator must be an array of ItemResource.ItemType!")
		
		if value.is_empty():
			requested_types = allowed_types
			
			return
		
		var filtered_types: Array[GearResource.Type] = []
		
		for type in value:
			if allowed_types.has(type):
				filtered_types.append(type)
		
		requested_types = filtered_types

func _init(qty: int, types: Array[GearResource.Type] = []) -> void:
	quantity = qty
	requested_types = types

func generate() -> Array[Gear]:
	var builder: GearBuilder = GearBuilder.new()
	var generated_gear: Array[Gear] = []
	var tiers: Array = MapInstance.available_tiers
	
	for i in range(quantity):
		var tier := get_tier(tiers)
		var type: GearResource.Type = requested_types[randi() % len(requested_types)]
		var item: Gear = builder.build_item(type, tier)
		
		if item:
			generated_gear.append(item)
		else:
			push_error("item could not be generated: %s %s" % [tier, type])
		
	return generated_gear

func get_tier(tiers: Array) -> String:
	var rand := randi() % len(tiers)
	
	return tiers[rand]
