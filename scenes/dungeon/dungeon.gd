extends Node3D

@onready var player: CharacterBody3D = get_tree().get_root().get_node("Main/Player")
@onready var transition_rect: ColorRect = $TransitionRect
var current_map_scene: Node = null

const TILE_SIZE = 2.0

func _ready() -> void:
	LoadBus.loaded.connect(load_map)
	EncounterBus.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterBus.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	player.connect("player_moved", Callable(self, "_on_player_moved"))
	TransitionManager.connect("map_transition_started", Callable(self, "transition_to_map"))
	
	transition_rect.modulate.a = 0.0
	load_map("beginning_area_01")

func load_map(map_id: String, load_data: Dictionary = {}) -> void:
	#TODO: safety
	var map_data := MapManager.get_map_data(map_id)
	var map_scene := MapManager.get_map(map_id)
	
	_kill_map()
	
	if MapInstance.map_id != map_id or not MapInstance.map_id:
		print("Dungeon: Loading new map")
		MapInstance.hydrate_from_resource(map_data)
		
	if !load_data.is_empty():
		MapInstance.hydrate_from_load(load_data)

	current_map_scene = map_scene.instantiate()
	self.add_child(current_map_scene)
	var player_position: Vector2i = MapInstance.player_previous_position
	var player_facing: Vector3 = MapInstance.player_facing
	
	if current_map_scene.has_node("Enemies"):
		if current_map_scene.get_node("Enemies").has_method("populate_enemy_spawn_points"):
			current_map_scene.get_node("Enemies").call_deferred("populate_enemy_spawn_points")
		else:
			push_error("Missing enemy spawn populate method!")
	else:
		push_error("Missing Enemies node!")
	
	player.set_grid_pos(player_position, player_facing, TILE_SIZE)
	MapBus.map_finished_loading.emit(map_data)

func _on_encounter_started(_data: EncounterData) -> void:
	call_deferred("_deactivate_dungeon")
	#if current_map_scene:
		#current_map_scene.queue_free()
		#current_map_scene = null
		
func _deactivate_dungeon() -> void:
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_DISABLED
	
func handle_event(event: String) -> void:
	print(event)

func transition_to_map(map_id: String) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	load_map(map_id)
	tween = get_tree().create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	TransitionManager.transit_to_map_end()

func _on_player_moved(data: Dictionary) -> void:
	MapInstance.update_player_position(data["grid_position"], data["grid_direction"])

func _on_encounter_ended(result: String, _data: EncounterData) -> void:
	print("Back from battle with result:", result)
	self.visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	var player_position: Vector2i = MapInstance.player_previous_position
	var player_facing: Vector3 = MapInstance.player_facing
	player.set_grid_pos(player_position, player_facing, TILE_SIZE)

	#load_map(MapInstance.map_id)

func _kill_map() -> void:
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null
	
	for child in get_children():
		if child != player and child != transition_rect:
			child.queue_free()
