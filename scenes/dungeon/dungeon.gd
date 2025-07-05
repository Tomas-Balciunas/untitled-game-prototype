extends Node3D

@onready var tiles_container = $Tiles
@onready var transition_rect = get_tree().get_root().get_node("Main/TransitionRect")
var map_data = []
var player: Node3D

const TILE_SIZE = 2.0

func _ready():
	player = get_tree().get_root().get_node("Main/Dungeon/Player")
	
	
	EncounterManager.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterManager.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	player.connect("player_moved", Callable(self, "_on_player_moved"))
	player.connect("start_encounter", Callable(EncounterManager, "start_encounter"))
	player.connect("map_transition", Callable(self, "transition_to_map"))
	
	transition_rect.modulate.a = 0.0
	load_map("area_00")

func load_map(map_id: String):
	var map_resource = MapManager.get_map(map_id)
	print(map_resource)
	
	if MapInstance.map_id != map_id:
		print("Dungeon: Loading new map")
		MapInstance.hydrate_from_resource(map_resource)
	
	map_data = MapInstance.map_data
	var theme = MapInstance.theme
	var player_position = MapInstance.player_position
	print(player_position)
	
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
				floor_tile.set_meta("arena", tile["arena"])
			
			if tile["type"] == "wall":
				var wall_scene = TileFactory.get_tile_style(theme, tile["type"], tile["style"])
				var wall = wall_scene.instantiate()
				tiles_container.add_child(wall)
				wall.global_position = position + Vector3(0, 0, 0)
				wall.set_meta("event", tile["event"])
				wall.set_meta("encounter", tile["encounter"])
				wall.set_meta("arena", tile["arena"])
	
	player.set_grid_pos(player_position)

func _on_encounter_started(data: Dictionary):
	player.disable_all_movement()
	player.global_position = Vector3(0, 1, -8)
	player.rotation_degrees.y = 180
	self.visible = false

func handle_event(event: String):
	print(event)

func transition_to_map(map_id: String):
	player.disable_all_movement()
	var tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	load_map(map_id)
	tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	player.enable_all_movement()

func _on_player_moved(data: Dictionary):
	MapInstance.update_player_position(data["grid_position"])

func _on_encounter_ended(result):
	print("Back from battle with result:", result)
	# TODO: restore map state
	self.visible = true
	
	load_map(MapInstance.map_id)
	player.enable_all_movement()
