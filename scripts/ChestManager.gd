extends Node

const CHEST_OPEN_SELECT_SCENE = preload("uid://dtm4jlj3x4dlr")
const CHEST_CONTENT_SCENE = preload("uid://cyrso6ll1atiy")

var chest: Chest = null

func _ready() -> void:
	ChestBus.open_chest_requested.connect(on_open_chest_requested)

func on_open_chest_requested(c: Chest) -> void:
	chest = c
	if chest.trapped:
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
	open_chest()
	

func open_chest() -> void:
	var inst := CHEST_CONTENT_SCENE.instantiate()
	get_tree().get_root().get_node("Main").add_child(inst)
	inst.init(chest)
