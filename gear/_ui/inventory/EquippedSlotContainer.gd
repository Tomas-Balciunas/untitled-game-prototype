extends Node

@onready var weapon := $Weapon
@onready var helmet := $Helmet
@onready var chest := $Chest
@onready var gloves := $Gloves
@onready var boots := $Boots
@onready var ring := $Ring
@onready var amulet := $Amulet

func bind_equipped(character_instance: Character, parent_ui: InventoryUI) -> void:
	var equipment := {
	ItemTypes.GearType.WEAPON: weapon,
	ItemTypes.GearType.CHEST: chest,
	ItemTypes.GearType.HELMET: helmet,
	ItemTypes.GearType.BOOTS: boots,
	ItemTypes.GearType.GLOVES: gloves,
	ItemTypes.GearType.RING: ring,
	ItemTypes.GearType.AMULET: amulet
}
	for slot: int in ItemTypes.GearType.values():
		var eq_slot: PanelContainer = equipment[slot]
		eq_slot.bind(character_instance.equipment.get_equipment_by_type(slot))

		var info_panel := parent_ui.item_info_panel
		var hover_cb := func(item: Item) -> void:
			info_panel.show_item_info(item, character_instance)

		for c: Dictionary in eq_slot.item_hovered.get_connections():
			eq_slot.item_hovered.disconnect(c.callable)
		eq_slot.item_hovered.connect(hover_cb)

		if not eq_slot.item_unhovered.is_connected(info_panel.hide_item_info):
			eq_slot.item_unhovered.connect(info_panel.hide_item_info)

		if not eq_slot.equipped_item_selected.is_connected(parent_ui._on_equipped_item_selected):
			eq_slot.equipped_item_selected.connect(parent_ui._on_equipped_item_selected)
