extends Node

const CHEST_OPEN_SELECT_SCENE = preload("uid://dtm4jlj3x4dlr")
const CHEST_CONTENT_SCENE = preload("uid://cyrso6ll1atiy")

var chest: Chest = null

func _ready() -> void:
	ChestBus.open_chest_requested.connect(on_open_chest_requested)

func on_open_chest_requested(c: Chest) -> void:
	chest = c
	if chest.locked:
		var inst := CHEST_OPEN_SELECT_SCENE.instantiate()
		inst.chest_opener_chosen.connect(on_chest_opener_chosen, CONNECT_ONE_SHOT)
		get_tree().get_root().get_node("Main").add_child(inst)
		inst.init()
	else:
		open_chest()
	
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
	
	if randf() > 0.5:
		event.append({
			"type": "text",
			"text": [
				"Oops! Poison dart!",
			]
		})
		
		event.append({
			"type": "trap",
			"id": "poison_dart",
			"damage": 10
		})
	else:
		event.append({
			"type": "text",
			"text": [
				"Open!",
			]
		})
	

	await EventManager.process_event(event)
	chest.locked = false
	open_chest()
	

func open_chest() -> void:
	var inst := CHEST_CONTENT_SCENE.instantiate()
	get_tree().get_root().get_node("Main").add_child(inst)
	inst.init(chest)
