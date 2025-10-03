extends Node

var level_up_screen
var to_level_up: Array[CharacterInstance] = []
@onready var player = get_tree().get_root().get_node("Main/Player")

func on_rest_button_pressed():
	to_level_up = PartyManager.members.filter(func(c): return c.current_experience > c.experience_to_next_level)
	next_character_level_up()

func next_character_level_up():
	if to_level_up.size() > 0:
		level_up_screen.show_for_character(to_level_up.pop_front())

func on_level_up_requested():
	level_up_screen = get_tree().get_root().get_node("Main/LevelUp")
	level_up_screen.show()
	on_rest_button_pressed()

func enter_rest_area():
	var dungeon = get_tree().get_root().get_node("Main/Dungeon")
	dungeon.visible = false
	dungeon.process_mode = Node.PROCESS_MODE_DISABLED
	
	var rest_area = load("res://maps/_rest/crypt/RestArea01.tscn").instantiate()
	rest_area.global_position = Vector3(10000, 0, 10000)
	get_tree().get_root().add_child(rest_area)
	
	var entry_spot = rest_area.get_node("EntrySpot")
	player.global_transform = entry_spot.global_transform
	player.reparent(rest_area)

	var spots = rest_area.get_node("PartySpots").get_children()
	var members: Array[CharacterInstance] = PartyManager.members.duplicate()

	for i in range(min(spots.size(), members.size())):
		var char: CharacterInstance = members[i]
		if char.is_main:
			continue
		var character_scene = char.resource.character_body.instantiate()

		character_scene.global_transform = spots[i].global_transform
		rest_area.add_child(character_scene)

func exit_rest_area():
	var dungeon = get_tree().get_root().get_node("Main/Dungeon")
	dungeon.visible = true
	dungeon.process_mode = Node.PROCESS_MODE_INHERIT

	var rest_area = get_tree().get_root().get_node("Main/RestArea")
	rest_area.queue_free()
