extends PanelContainer

const CHARACTER_ITEM_TRANSFER_SLOT = preload("uid://bn884jwltf8gy")
@onready var selections: VBoxContainer = $Container/Selections
@onready var header_label: Label = $Container/Info/HeaderLabel


var _item: Item = null
var _from: Character = null

func bind(from: Character, item: Item) -> void:
	if !item:
		NotificationBus.notification_requested.emit("ItemResource not selected!")
		queue_free()
	
	InventoryBus.inventory_closed.connect(_on_inventory_closed)
	_item = item
	_from = from
	header_label.text = "%s wants to transfer %s to.." % [from.resource.name, item.get_item_name()]
	
	var applicable_allies: Array[Character] = []
	
	for member:Character in PartyManager.members:
		if !member == _from:
			applicable_allies.append(member)
	
	for ally: Character in applicable_allies:
		var inst := CHARACTER_ITEM_TRANSFER_SLOT.instantiate()
		selections.add_child(inst)
		inst.bind(ally)
		inst.transfer_character_chosen.connect(_on_transfer_character_chosen)


func _on_transfer_character_chosen(c: Character) -> void:
	_from.inventory.transfer_item(_from, c, _item)
	queue_free()
	InventoryBus.request_inventory_refresh.emit()

func _on_inventory_closed() -> void:
	queue_free()
