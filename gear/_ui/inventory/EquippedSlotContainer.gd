extends Node

@onready var weapon = $Weapon
@onready var helmet = $Helmet
@onready var chest = $Chest
@onready var gloves = $Gloves
@onready var boots = $Boots
@onready var ring = $Ring
@onready var amulet = $Amulet

func bind_equipped(character_instance: CharacterInstance, parent_ui: InventoryUI):
	var equipment := {
	"weapon": weapon,
	"chest": chest,
	"helmet": helmet,
	"boots": boots,
	"gloves": gloves,
	"ring": ring,
	"amulet": amulet
}
	for slot in character_instance.equipment.keys():
		var eq_slot = equipment[slot]
		eq_slot.bind(character_instance.equipment[slot])
		
		if not eq_slot.item_hovered.is_connected(parent_ui.show_item_info):
			eq_slot.item_hovered.connect(parent_ui.show_item_info)

		if not eq_slot.item_unhovered.is_connected(parent_ui.hide_item_info):
			eq_slot.item_unhovered.connect(parent_ui.hide_item_info)

		if not eq_slot.equipped_item_selected.is_connected(parent_ui._on_equipped_item_selected):
			eq_slot.equipped_item_selected.connect(parent_ui._on_equipped_item_selected)
