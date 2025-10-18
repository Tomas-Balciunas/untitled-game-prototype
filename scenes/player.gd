extends CharacterBody3D

signal player_moved(data)

const TRAVEL_TIME := 0.3

@onready var front_ray := $FrontRay
@onready var back_ray := $BackRay
@onready var left_ray := $LeftRay
@onready var right_ray := $RightRay

var can_move: bool = true
var tween : Tween

func _ready() -> void:
	EncounterBus.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterBus.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	TransitionManager.connect("map_transition_started", Callable(self, "_on_map_transition_started"))
	TransitionManager.connect("map_transition_ended", Callable(self, "_on_map_transition_ended"))

func _physics_process(_delta: float) -> void:
	
	if tween is Tween:
		if tween.is_running():
			return
			
	if Input.is_action_pressed("move_forward") and not front_ray.is_colliding():
		if GameState.is_busy():
			return
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.FORWARD * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos: Vector2i = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		var facing_vec: Vector3 = -transform.basis.z.normalized()
		emit_signal("player_moved", { "grid_position": grid_pos, "grid_direction": facing_vec })
		return
		
	if Input.is_action_pressed("move_backwards") and not back_ray.is_colliding():
		if GameState.is_busy():
			return
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.BACK * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos: Vector2i = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		var facing_vec: Vector3 = -transform.basis.z.normalized()
		emit_signal("player_moved", { "grid_position": grid_pos, "grid_direction": facing_vec })
		return
		
	if Input.is_action_pressed("strafe_left") and not left_ray.is_colliding():
		if GameState.is_busy():
			return
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.LEFT * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos: Vector2i = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		var facing_vec: Vector3 = -transform.basis.z.normalized()
		emit_signal("player_moved", { "grid_position": grid_pos, "grid_direction": facing_vec })
		return
		
	if Input.is_action_pressed("strafe_right") and not right_ray.is_colliding():
		if GameState.is_busy():
			return
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.RIGHT * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos: Vector2i = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		var facing_vec: Vector3 = -transform.basis.z.normalized()
		emit_signal("player_moved", { "grid_position": grid_pos, "grid_direction": facing_vec })
		return
		
	if Input.is_action_pressed("turn_left"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, PI / 2), TRAVEL_TIME)
	if Input.is_action_pressed("turn_right"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, -PI / 2), TRAVEL_TIME)

func snap_to_grid(tile_size: float = 2.0) -> void:
	var x: int = round(global_position.x / tile_size) * tile_size
	var z: int = round(global_position.z / tile_size) * tile_size
	global_position = Vector3(x, global_position.y, z)

func _on_encounter_started(_encounter_data: EncounterData) -> void:
	can_move = false
	
func _on_encounter_ended(_result: String, _data: EncounterData) -> void:
	can_move = true
	
func _on_map_transition_started(_id: String) -> void:
	can_move = false
	
func _on_map_transition_ended() -> void:
	can_move = true

func set_grid_pos(pos: Vector2i, player_facing: Vector3, tile_size: float) -> void:
	global_position = Vector3(pos.x * tile_size, 0, pos.y * tile_size)
	var target: Vector3 = global_position + player_facing
	look_at(target, Vector3.UP)
