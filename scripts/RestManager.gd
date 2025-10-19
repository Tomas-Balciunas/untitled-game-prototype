extends Node

var to_level_up: Array[CharacterInstance] = []
var _last_position: Vector2i
var _last_facing: Vector3

func _ready() -> void:
	RestBus.enter_rest_area_requested.connect(enter_rest_area)
	RestBus.exit_rest_area_requested.connect(exit_rest_area)
	RestBus.rest_character_interaction_requested.connect(_on_rest_character_interaction_requested)

func enter_rest_area() -> void:
	var dungeon := get_tree().get_root().get_node("Main/Dungeon")
	var player := get_tree().get_root().get_node("Main/Player")
	_last_position = MapInstance.player_previous_position
	_last_facing = MapInstance.player_facing
	dungeon.visible = false
	dungeon.process_mode = Node.PROCESS_MODE_DISABLED
	
	var rest_area = load("res://maps/_rest/crypt/RestArea01.tscn").instantiate()
	get_tree().get_root().get_node("Main").add_child(rest_area)
	rest_area.global_position = Vector3(100, 0, 100)
	rest_area.name = "RestArea"
	
	var entry_spot = rest_area.get_node("EntrySpot")
	player.global_transform = entry_spot.global_transform

	var spots = rest_area.get_node("PartySpots").get_children()
	var members: Array[CharacterInstance] = PartyManager.members.duplicate()
	
	spots.shuffle()
	var interactable_scene := load("res://scripts/interactables/CharacterInteractable.tscn")
	
	for i in range(members.size()):
		var chara: CharacterInstance = members[i]
		
		if chara.is_main:
			continue
			
		var rest_character := chara.resource.character_body.instantiate()
		var interactable: Interactable = interactable_scene.instantiate()
		
		rest_character.global_transform = spots[i].global_transform
		interactable.global_transform = spots[i].global_transform
		
		rest_area.add_child(interactable)
		rest_area.add_child(rest_character)
		
		interactable.set_character(chara)
		rest_character.collision.disabled = true
		
	for member in PartyManager.members:
		var manager: ExperienceManager = member.resource.experience_manager
		manager.level_up_character(member)

func exit_rest_area() -> void:
	var dungeon := get_tree().get_root().get_node("Main/Dungeon")
	var player := get_tree().get_root().get_node("Main/Player")
	var rest_area := get_tree().get_root().get_node("Main/RestArea")
	
	rest_area.queue_free()
	dungeon.visible = true
	player.set_grid_pos(_last_position, _last_facing, 2.0)
	dungeon.process_mode = Node.PROCESS_MODE_INHERIT
	
	for member in PartyManager.members:
		member.set_current_health(member.stats.get_final_stat(Stats.HEALTH))
		member.set_current_mana(member.stats.get_final_stat(Stats.MANA))
		
	SaveManager.save_game(0)

# TODO: game state managing to prevent transition while player is tweening

func _on_rest_character_interaction_requested(chara: CharacterInstance) -> void:
	var menu := get_tree().root.get_node("CharacterMenu")
	
	if !menu:
		push_error("Menu not found")
		
	menu.bind(chara)
	menu.show()
