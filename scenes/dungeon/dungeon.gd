extends Node3D

@onready var transition_rect = get_tree().get_root().get_node("Main/TransitionRect")
var player: Node3D
var current_map_scene: Node = null

const TILE_SIZE = 2.0

func _ready():
	player = get_tree().get_root().get_node("Main/Dungeon/Player")
	
	EncounterManager.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterManager.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	player.connect("player_moved", Callable(self, "_on_player_moved"))
	TransitionManager.connect("map_transition_started", Callable(self, "transition_to_map"))
	
	transition_rect.modulate.a = 0.0
	load_map("area_00")

func load_map(map_id: String, load_data = null):
	var map_resource = MapManager.get_map(map_id)
	
	_kill_map()
	
	if MapInstance.map_id != map_id or not MapInstance.map_id:
		print("Dungeon: Loading new map")
		MapInstance.hydrate_from_resource(map_resource)
		
	if load_data:
		MapInstance.hydrate_from_load(load_data)

	current_map_scene = MapInstance.map_data.instantiate()
	self.add_child(current_map_scene)
	var player_position = MapInstance.player_previous_position
	var player_facing = MapInstance.player_facing
	
	player.set_grid_pos(player_position, player_facing, TILE_SIZE)

func _on_encounter_started(_data: EncounterData):
	player.global_position = Vector3(0, 0, -7)
	player.rotation_degrees.y = 180
	self.visible = false
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null

func handle_event(event: String):
	print(event)

func transition_to_map(map_id: String):
	var tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	load_map(map_id)
	tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	TransitionManager.transit_to_map_end()

func _on_player_moved(data: Dictionary):
	MapInstance.update_player_position(data["grid_position"], data["grid_direction"])

func _on_encounter_ended(result):
	print("Back from battle with result:", result)
	self.visible = true
	
	load_map(MapInstance.map_id)

func _kill_map():
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null
	
	for child in get_children():
		if child != player and child != transition_rect:
			child.queue_free()
