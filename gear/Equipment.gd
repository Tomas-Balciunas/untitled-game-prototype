extends Resource

class_name Equipment

var owner: Character = null

var weapon: Weapon = null
#var off_hand: OffHand = null
var helmet: Helmet = null
var chestpiece: Chestpiece = null
var boots: Boots = null
var gloves: Gloves = null
var ring: Ring = null
var amulet: Amulet = null

func _init(character: Character) -> void:
	assert(character)
	owner = character

func equip_item(item: Gear) -> bool:
	if !can_equip(item):
		NotificationBus.notification_requested.emit("%s cannot equip this item" % owner.resource.name)
		
		return false
	
	var equipped_item: Gear = get_equipment_by_type(item.get_gear_type())
	
	if owner.inventory.has_item(item):
		owner.inventory.remove_item(item)
	else:
		push_error("Equipping non existent item")
		return false
	
	if equipped_item:
		unset_equipment(equipped_item.get_gear_type())
		
	set_equipment(item)
	var insts: Array = []
	
	for e in item.get_all_effects():
		var inst: Effect = owner.apply_effect(e, ItemSource.new(owner, item))
		insts.append(inst)
		
	owner.gear_effects[item.get_gear_type()] = insts
	
	for m in item.get_all_modifiers():
		owner.state.add_modifier(m)
		
	StatCalculator.recalculate_all_stats(owner)
	
	return true

func unequip_slot(type: ItemTypes.GearType) -> bool:
	var item: Gear = get_equipment_by_type(type)
	
	if not item:
		push_error("Trying to unequip non existent item")
		
		return false

	for inst: Effect in owner.gear_effects.get(type, []):
		owner.remove_effect(inst)
	
	owner.gear_effects.erase(type)
		
	for m in item.get_all_modifiers():
		owner.state.remove_modifier(m)
	
	unset_equipment(type)
	owner.inventory.add_item(item)
	StatCalculator.recalculate_all_stats(owner)
	
	return true

func can_equip(item: Gear) -> bool:
	if owner.job.get_equippable_weapons().has(item.get_gear_type()):
		return true
	
	return false

func set_equipment(item: Gear) -> void:
	match item.get_gear_type():
		ItemTypes.GearType.WEAPON:
			weapon = item
		ItemTypes.GearType.HELMET:
			helmet = item
		ItemTypes.GearType.CHEST:
			chestpiece = item
		ItemTypes.GearType.BOOTS:
			boots = item
		ItemTypes.GearType.GLOVES:
			gloves= item
		ItemTypes.GearType.RING:
			ring = item
		ItemTypes.GearType.AMULET:
			amulet = item
		_:
			push_error("Attempted to equip an invalid item %s" % item.get_item_name())

func unset_equipment(type: ItemTypes.GearType) -> void:
	match type:
		ItemTypes.GearType.WEAPON:
			weapon = null
		ItemTypes.GearType.HELMET:
			helmet = null
		ItemTypes.GearType.CHEST:
			chestpiece = null
		ItemTypes.GearType.BOOTS:
			boots = null
		ItemTypes.GearType.GLOVES:
			gloves= null
		ItemTypes.GearType.RING:
			ring = null
		ItemTypes.GearType.AMULET:
			amulet = null
		_:
			push_error("Attempted to unset by an invalid item type %s" % type)

func get_equipment_by_type(type: ItemTypes.GearType) -> Gear:
	match type:
		ItemTypes.GearType.WEAPON:
			return weapon
		ItemTypes.GearType.HELMET:
			return helmet
		ItemTypes.GearType.CHEST:
			return chestpiece
		ItemTypes.GearType.BOOTS:
			return boots
		ItemTypes.GearType.GLOVES:
			return gloves
		ItemTypes.GearType.RING:
			return ring
		ItemTypes.GearType.AMULET:
			return amulet
		_:
			push_error("Attempted to get an invalid item type %s" % type)
			
			return null

func get_all_equipment() -> Array[Gear]:
	return [weapon, amulet, boots, chestpiece, gloves, helmet, ring]
