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

func set_equipment(item: Gear) -> void:
	match item.get_gear_type():
		GearResource.Type.WEAPON:
			weapon = item
		GearResource.Type.HELMET:
			helmet = item
		GearResource.Type.CHEST:
			chestpiece = item
		GearResource.Type.BOOTS:
			boots = item
		GearResource.Type.GLOVES:
			gloves= item
		GearResource.Type.RING:
			ring = item
		GearResource.Type.AMULET:
			amulet = item
		_:
			push_error("Attempted to equip an invalid item %s" % item.get_item_name())

func unset_equipment(type: GearResource.Type) -> void:
	match type:
		GearResource.Type.WEAPON:
			weapon = null
		GearResource.Type.HELMET:
			helmet = null
		GearResource.Type.CHEST:
			chestpiece = null
		GearResource.Type.BOOTS:
			boots = null
		GearResource.Type.GLOVES:
			gloves= null
		GearResource.Type.RING:
			ring = null
		GearResource.Type.AMULET:
			amulet = null
		_:
			push_error("Attempted to unset by an invalid item type %s" % type)

func get_equipment_by_type(type: GearResource.Type) -> Gear:
	match type:
		GearResource.Type.WEAPON:
			return weapon
		GearResource.Type.HELMET:
			return helmet
		GearResource.Type.CHEST:
			return chestpiece
		GearResource.Type.BOOTS:
			return boots
		GearResource.Type.GLOVES:
			return gloves
		GearResource.Type.RING:
			return ring
		GearResource.Type.AMULET:
			return amulet
		_:
			push_error("Attempted to get an invalid item type %s" % type)
			
			return null

func get_all_equipment() -> Array[Gear]:
	return [weapon, amulet, boots, chestpiece, gloves, helmet, ring]
