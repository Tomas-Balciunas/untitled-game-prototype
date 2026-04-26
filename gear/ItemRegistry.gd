extends Node

const GEAR := "GEAR"

const WOOD := "WOOD"
const IRON := "IRON"

var items := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths: Array[String] = [
		# Weapons
		"res://gear/weapon/iron_sword.tres",
		"res://gear/weapon/steel_longsword.tres",
		"res://gear/weapon/battle_axe.tres",
		"res://gear/weapon/venom_dagger.tres",
		"res://gear/weapon/mage_staff.tres",
		"res://gear/weapon/holy_mace.tres",
		"res://gear/weapon/shadow_blade.tres",
		"res://gear/weapon/berserker_axe.tres",
		# Helmets
		"res://gear/helmet/leather_skullcap.tres",
		"res://gear/helmet/iron_helmet.tres",
		"res://gear/helmet/battle_helm.tres",
		"res://gear/helmet/mage_hood.tres",
		# Chestpieces
		"res://gear/chest/leather_armor.tres",
		"res://gear/chest/chain_mail.tres",
		"res://gear/chest/plate_armor.tres",
		"res://gear/chest/mage_robe.tres",
		# Boots
		"res://gear/boots/wanderers_boots.tres",
		"res://gear/boots/iron_greaves.tres",
		"res://gear/boots/stalkers_boots.tres",
		# Gloves
		"res://gear/gloves/combat_gloves.tres",
		"res://gear/gloves/scholars_gloves.tres",
		"res://gear/gloves/iron_gauntlets.tres",
		# Rings
		"res://gear/ring/ring_of_vitality.tres",
		"res://gear/ring/ring_of_mana.tres",
		"res://gear/ring/ring_of_speed.tres",
		# Amulets
		"res://gear/amulet/amulet_of_protection.tres",
		"res://gear/amulet/amulet_of_wisdom.tres",
		"res://gear/amulet/amulet_of_power.tres",
	]
	
	for path in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_item(res)

func register_item(item: Item) -> void:
	if item.id in items:
		push_warning("Duplicate item id: %s" % item.id)
	items[item.id] = item

func get_item(id: String) -> Item:
	if items.has(id):
		return items[id]
	return null

func get_all_items() -> Array:
	return items.values()

func get_rand_template(tier: String, type: Item.ItemType) -> Gear:
	#if !templates.has(tier):
		#return null
		#
	#if !templates[tier].has(type):
		#return null
	#
	#var gear = templates[tier][type]
	#var rand := randi() % len(gear)
	#
	#return gear[rand]
	
	var candidates := []
	for item: Item in items.values():
		if item is Gear and item.tier == tier and item.type == type:
			candidates.append(item)
	
	if candidates.is_empty():
		push_warning("No templates found for tier %s type %s" % [tier, type])
		return null
	
	return candidates.pick_random()
