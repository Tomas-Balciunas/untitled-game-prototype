extends Node

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
	
	var rest_area: Node = load("res://maps/_rest/crypt/RestArea01.tscn").instantiate()
	get_tree().get_root().get_node("Main").add_child(rest_area)
	rest_area.global_position = Vector3(100, 0, 100)
	rest_area.name = "RestArea"
	
	var entry_spot: Marker3D = rest_area.get_node("EntrySpot")
	player.global_transform = entry_spot.global_transform

	var spots: Array = rest_area.get_node("PartySpots").get_children()
	var members: Array[CharacterInstance] = PartyManager.members.duplicate()
	
	spots.shuffle()
	var interactable_scene := load("res://scripts/interactables/CharacterInteractable.tscn")
	
	for i in range(members.size()):
		var chara: CharacterInstance = members[i]
		
		if chara.is_main:
			continue
			
		var rest_character := chara.get_body()
		var interactable: Interactable = interactable_scene.instantiate()
		
		interactable.add_child(rest_character)
		interactable.global_transform = spots[i].global_transform
		
		rest_area.add_child(interactable)
		
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
		member.set_current_health(member.stats.health)
		member.set_current_mana(member.stats.mana)
		
	SaveManager.save_game(0)

# TODO: game state managing to prevent transition while player is tweening

func _on_rest_character_interaction_requested(chara: CharacterInstance) -> void:
	CharacterBus.display_character_menu.emit(chara)
