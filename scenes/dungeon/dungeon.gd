extends Node3D

@onready var player: CharacterBody3D = get_tree().get_root().get_node("Main/Player")
@onready var transition_rect: ColorRect = $TransitionRect
var current_map_scene: Node = null

const TILE_SIZE = 2.0
const DEBUG_UPDATE_INTERVAL: float = 0.25

var _debug_layer: CanvasLayer = null
var _debug_label: Label = null
var _debug_timer: float = 0.0
var _current_map_data: Dictionary = {}

func _ready() -> void:
	LoadBus.loaded.connect(load_map)
	EncounterBus.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterBus.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	player.connect("player_moved", Callable(self, "_on_player_moved"))
	TransitionManager.connect("map_transition_started", Callable(self, "transition_to_map"))

	transition_rect.modulate.a = 0.0
	_setup_debug_overlay()
	load_map("beginning_area_01")

func _setup_debug_overlay() -> void:
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 100
	add_child(_debug_layer)
	var label := Label.new()
	label.position = Vector2(12, 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.text = "[Debug — F3]\nLoading map..."
	_debug_layer.add_child(label)
	_debug_label = label

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		if _debug_label:
			_debug_label.visible = not _debug_label.visible

func _process(delta: float) -> void:
	if _debug_label == null or not _debug_label.visible:
		return
	_debug_timer -= delta
	if _debug_timer > 0.0:
		return
	_debug_timer = DEBUG_UPDATE_INTERVAL
	_refresh_debug_overlay()

func _refresh_debug_overlay() -> void:
	if current_map_scene == null:
		_debug_label.text = "[F3] No map loaded"
		return

	var enemy_count: int = 0
	var custom_enemy_count: int = 0
	var chest_count: int = 0

	var enemies_node: Node = current_map_scene.get_node_or_null("Enemies")
	if enemies_node:
		for child in enemies_node.get_children():
			# Spawners that haven't been freed are alive enemies (or pending spawns).
			if child.has_method("update_target_location"):
				enemy_count += 1
	var enemies_custom_node: Node = current_map_scene.get_node_or_null("EnemiesCustom")
	if enemies_custom_node:
		custom_enemy_count = enemies_custom_node.get_child_count()

	var gridmap: GridMap = null
	for child in current_map_scene.get_children():
		if child is GridMap:
			gridmap = child
			break
	if gridmap:
		var chests_node: Node = gridmap.get_node_or_null("Chests")
		if chests_node:
			chest_count = chests_node.get_child_count()

	var lines: Array = []
	lines.append("[Debug — F3]")
	lines.append("Map: %s" % MapInstance.map_id)
	if _current_map_data.has("generation"):
		lines.append("Type: %s" % _current_map_data["generation"])
	var config: Dictionary = _current_map_data.get("config", {})
	if not config.is_empty():
		var layout: String = config.get("layout", "branching")
		var w: int = int(config.get("width", 0))
		var h: int = int(config.get("height", 0))
		lines.append("Layout: %s (%dx%d)" % [layout, w, h])
		if config.has("density"):
			lines.append("Density: %.2f" % float(config["density"]))
	lines.append("Player tile: %s" % str(MapInstance.player_position))
	lines.append("Enemies (procedural): %d" % enemy_count)
	if custom_enemy_count > 0:
		lines.append("Enemies (custom): %d" % custom_enemy_count)
	lines.append("Chests: %d" % chest_count)
	lines.append("Cleared encounters: %d" % MapInstance.cleared_encounters.get(MapInstance.map_id, []).size())
	lines.append("FPS: %d" % int(Engine.get_frames_per_second()))
	_debug_label.text = "\n".join(lines)

func load_map(map_id: String = "", load_data: Dictionary = {}) -> void:
	#TODO: safety
	var map_data := MapManager.get_map_data(map_id)
	_current_map_data = map_data

	_kill_map()

	if MapInstance.map_id != map_id or not MapInstance.map_id:
		print("Dungeon: Loading new map")
		MapInstance.hydrate_from_resource(map_data)

	if !load_data.is_empty():
		MapInstance.hydrate_from_load(load_data)

	var generation: String = map_data.get("generation", "handcrafted")
	if generation == "procedural":
		current_map_scene = _build_procedural_map(map_data, load_data.is_empty())
	else:
		var map_scene := MapManager.get_map(map_id)
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

func _kill_map() -> void:
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null

	for child in get_children():
		if child != player and child != transition_rect and child != _debug_layer:
			child.queue_free()

func _build_procedural_map(map_data: Dictionary, fresh_entry: bool) -> Node:
	var scene_root: Node = MapManager.get_blueprint().instantiate()
	var map_id: String = map_data["id"]
	var config: Dictionary = map_data.get("config", {})
	var tileset: String = map_data.get("tileset", "default")
	var return_map_id: String = map_data.get("return_map", "")
	var end_map_id: String = map_data.get("end_map", "")

	var seed_value: int = MapInstance.get_or_create_seed(map_id)
	var gen := MapGenerator.new(seed_value, config)
	var result: MapGenerator.Result = gen.generate()
	gen.apply_to_scene(scene_root, result, tileset, return_map_id, end_map_id)

	if fresh_entry:
		MapInstance.set_player_spawn(result.spawn)

	return scene_root
