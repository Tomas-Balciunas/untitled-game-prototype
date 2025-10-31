extends Node

@onready var label: Label = $Label
@onready var button: Button = $Button
var character: CharacterInstance = null

func _ready() -> void:
	InventoryBus.character_slots_changed.connect(on_character_slots_changed)
	
func init(c: CharacterInstance) -> void:
	character = c
	update_label(c, len(c.inventory.slots))
	
func on_character_slots_changed(c: CharacterInstance, qty: int) -> void:
	update_label(c, qty)
	
func update_label(c: CharacterInstance, qty: int) -> void:
	if c.resource.id == character.resource.id:
		label.text = "%s %s/%s" % [character.resource.name, qty, character.inventory.max_slots]
