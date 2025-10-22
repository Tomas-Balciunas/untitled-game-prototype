extends Button

signal transfer_character_chosen(c: CharacterInstance)

var _character: CharacterInstance = null

func bind(character: CharacterInstance) -> void:
	_character = character
	var max_slots := character.inventory.max_slots
	var current_slots := len(character.inventory.slots)
	
	self.text = "%s: %s/%s" % [character.resource.name, current_slots, max_slots]


func _on_pressed() -> void:
	transfer_character_chosen.emit(_character)
