extends Node

const GEAR := "GEAR"

const WOOD := "WOOD"
const IRON := "IRON"

var items := {}

var templates := {
	WOOD: {
		Item.ItemType.WEAPON: {
			Weapon.Type.SWORD: preload("uid://x83cm1imafh3"),
			Weapon.Type.AXE: preload("uid://dxgrsck30ncu7")
		},
		Item.ItemType.RING: [preload("uid://dvk8txtug6uxg")],
		Item.ItemType.HELMET: [preload("uid://nn6glbv4xa5j")],
		Item.ItemType.GLOVES: [preload("uid://cl6c0he1af8y2")],
		Item.ItemType.CHEST: [preload("uid://ctpjd254tvtop")],
		Item.ItemType.BOOTS: [preload("uid://4ifhngcl2duo")],
		Item.ItemType.AMULET: [preload("uid://b38d3s05y1whf")]
	},
	IRON: {
		Item.ItemType.WEAPON: {
			Weapon.Type.SWORD: preload("uid://dvb2c0iycjbeq"),
			Weapon.Type.AXE: preload("uid://bytf4k3v782d2")
		},
		Item.ItemType.RING: [preload("uid://ni8u8dkklu3i")],
		Item.ItemType.HELMET: [preload("uid://bg4y1usyv768r")],
		Item.ItemType.GLOVES: [preload("uid://crfi3y5s3px83")],
		Item.ItemType.CHEST: [preload("uid://dmw8hodi53e8u")],
		Item.ItemType.BOOTS: [preload("uid://dyypjqxln7mdj")],
		Item.ItemType.AMULET: [preload("uid://dynycdmvp7uom")]
	}
}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths: Array[String] = [
		"res://gear/chest/armor.tres",
		"res://gear/consumable/hp pot minor/hp_pot.tres",
		"res://gear/consumable/poison flask minor/poison_flask.tres",
		"res://gear/ring/ring1.tres",
		"res://gear/ring/ring2.tres",
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
	if !templates.has(tier):
		return null
		
	if !templates[tier].has(type):
		return null
	
	var gear = templates[tier][type]
	var rand := randi() % len(gear)
	
	return gear[rand]
