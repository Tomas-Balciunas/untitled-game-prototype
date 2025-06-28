extends Node3D

@onready var tiles_container = $Tiles
@onready var transition_rect = get_tree().get_root().get_node("Main/TransitionRect")
@onready var transition_battle = get_tree().get_root().get_node("Main/BattleTransition")
var map_data = []
var current_map = ""
var player: Node3D

const TILE_SIZE = 2.0

func _ready():
	player = get_tree().get_root().get_node("Main/Player")
	transition_rect.modulate.a = 0.0
	transition_battle.modulate.a = 0.0
	load_map("default")

func load_map(map_name: String):
	var map_config = MapManager.maps[map_name]
	map_data = map_config.data
	var theme = map_config.theme
	var start_pos = map_config.start_pos
	current_map = map_name
	
	for child in tiles_container.get_children():
		child.queue_free()
	
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			var tile = map_data[y][x]
			var position = Vector3(x * TILE_SIZE, 0, y * TILE_SIZE)

			if tile["type"] == "floor":
				var floor_scene = TileFactory.get_tile_style(theme, tile["type"], tile["style"])
				var floor_tile = floor_scene.instantiate()
				tiles_container.add_child(floor_tile)
				floor_tile.global_position = position
				floor_tile.set_meta("event", tile["event"])
				floor_tile.set_meta("encounter", tile["encounter"])
			
			if tile["type"] == "wall":
				var wall_scene = TileFactory.get_tile_style(theme, tile["type"], tile["style"])
				var wall = wall_scene.instantiate()
				tiles_container.add_child(wall)
				wall.global_position = position + Vector3(0, 0, 0)
				wall.set_meta("event", tile["event"])
				wall.set_meta("encounter", tile["encounter"])
	
	player.set_grid_pos(start_pos)

func load_arena():
	map_data = []
	player.in_battle = true
	var tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	var arena_scene = MapManager.arenas["default"]
	for child in tiles_container.get_children():
		child.queue_free()
		
	var arena_instance = arena_scene.instantiate()
	tiles_container.add_child(arena_instance)
	
	if arena_instance.has_node("PlayerStart"):
		var player_start = arena_instance.get_node("PlayerStart")
		player.global_position = player_start.global_position
	else:
		player.global_position = Vector3(0, 1, 0)
		
	tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 0.0, 0.5)
	await tween.finished
	

func trigger_tile_event(pos: Vector2i):
	if pos.y >= 0 and pos.y < map_data.size() and pos.x >= 0 and pos.x < map_data[pos.y].size():
		var tile = map_data[pos.y][pos.x]
		if tile["event"]:
			handle_event(tile["event"])
		if tile["encounter"]:
			handle_encounter(tile["encounter"])

func handle_event(event: String):
	print(event)

func handle_encounter(encounter):
	if encounter:
		print("Encountered a %s!" % encounter)
		load_arena()

func transition_to_map(map_name: String):
	player.can_move = false
	var tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	load_map(map_name)
	tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	player.can_move = true
