extends Node3D

signal player_moved(data)

const TRAVEL_TIME := 0.3

@onready var front_ray := $FrontRay
@onready var back_ray := $BackRay
@onready var left_ray := $LeftRay
@onready var right_ray := $RightRay

var can_move = true
var tween : Tween

func _ready():
	EncounterManager.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterManager.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	TransitionManager.connect("map_transition_started", Callable(self, "_on_map_transition_started"))
	TransitionManager.connect("map_transition_ended", Callable(self, "_on_map_transition_ended"))

func _physics_process(_delta):
	if GameState.is_busy():
		return
	if tween is Tween:
		if tween.is_running():
			return
	if Input.is_action_pressed("move_forward") and not front_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.FORWARD * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		emit_signal("player_moved", { "grid_position": grid_pos })
	if Input.is_action_pressed("move_backwards") and not back_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.BACK * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		emit_signal("player_moved", { "grid_position": grid_pos })
	if Input.is_action_pressed("strafe_left") and not left_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.LEFT * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		emit_signal("player_moved", { "grid_position": grid_pos })
	if Input.is_action_pressed("strafe_right") and not right_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.RIGHT * 2), TRAVEL_TIME)
		await tween.finished
		snap_to_grid()
		var grid_pos = Vector2i(round(global_position.x / 2.0), round(global_position.z / 2.0))
		emit_signal("player_moved", { "grid_position": grid_pos })
	if Input.is_action_pressed("turn_left"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, PI / 2), TRAVEL_TIME)
	if Input.is_action_pressed("turn_right"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, -PI / 2), TRAVEL_TIME)

func snap_to_grid(tile_size: float = 2.0):
	var x = round(global_position.x / tile_size) * tile_size
	var z = round(global_position.z / tile_size) * tile_size
	global_position = Vector3(x, global_position.y, z)

func _on_encounter_started(_encounter_data):
	can_move = false
	
func _on_encounter_ended(_result):
	can_move = true
	
func _on_map_transition_started(_id):
	can_move = false
	
func _on_map_transition_ended():
	can_move = true

func set_grid_pos(pos: Vector2i, tile_size: float):
	global_position = Vector3(pos.x * tile_size, 0, pos.y * tile_size)
