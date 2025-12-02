extends Node


var chest: Chest = null

func _ready() -> void:
	ChestBus.open_chest_requested.connect(on_open_chest_requested)
	ChestBus.chest_opener_chosen.connect(on_chest_opener_chosen)

func on_open_chest_requested(c: Chest) -> void:
	chest = c
	if chest.trapped:
		ChestBus.display_chest_opener.emit()
	else:
		ChestBus.display_chest_content.emit(chest)
	
func on_chest_opener_chosen(character: CharacterInstance) -> void:
	var line_1 := "%s attempts to open the chest..." % character.resource.name
	var event := [
			{
				"type": "text",
				"text": [
					line_1,
				]
			}
		]
		
	var trap: Trap
	
	if chest.trap:
		trap = chest.trap
	else:
		trap = TrapRegistry.get_random_trap()	
	
	if randf() > 0:
		event.append({
			"type": "text",
			"text": [
				"Oops! %s" % trap.name,
			]
		})
		
		event.append({
			"type": "trap",
			"trap": trap,
			"target": character
		})
	else:
		event.append({
			"type": "text",
			"text": [
				"Open!",
			]
		})
	

	await EventManager.process_event(event)
	chest.set_trapped(false)
	ChestBus.display_chest_content.emit(chest)
