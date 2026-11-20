extends CharacterBody3D

signal player_moved(data: Dictionary)
signal player_fell(height: float)

const TRAVEL_TIME := 0.3
const TILE_SIZE := 2.0
const MAX_STEP_UP := 0.6
const MAX_STEP_DOWN := 0.6
const FALL_GRAVITY := 20.0
const MAX_STAIR_RISE := 2.5
const PROBE_UP := 1.5
const STAIR_PROBE_UP := MAX_STAIR_RISE + 0.1
const PROBE_DEPTH := 50.0
const WALKABLE_NORMAL_Y := 0.5
const FLAT_NORMAL_Y := 0.98
const GROUND_MASK := 1 | 16
const SETTLE_FRAMES := 5

@onready var front_ray := $FrontRay
@onready var back_ray := $BackRay
@onready var left_ray := $LeftRay
@onready var right_ray := $RightRay
@onready var camera_3d: Camera3D = $Camera3D

var can_move: bool = true
var tween : Tween
var _settle_frames: int = 0

func _ready() -> void:
	EncounterBus.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterBus.connect("encounter_ended", Callable(self, "_on_encounter_ended"))
	TransitionManager.connect("map_transition_started", Callable(self, "_on_map_transition_started"))
	TransitionManager.connect("map_transition_ended", Callable(self, "_on_map_transition_ended"))

func _physics_process(_delta: float) -> void:

	if tween is Tween:
		if tween.is_running():
			return

	if _settle_frames > 0:
		_settle()

	for move: Array in [
		["move_forward", Vector3.FORWARD, front_ray],
		["move_backwards", Vector3.BACK, back_ray],
		["strafe_left", Vector3.LEFT, left_ray],
		["strafe_right", Vector3.RIGHT, right_ray],
	]:
		if Input.is_action_pressed(move[0]):
			if GameState.is_busy():
				return
			if _try_move(move[1], move[2]):
				return

	if Input.is_action_pressed("turn_left"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, PI / 2), TRAVEL_TIME)
	if Input.is_action_pressed("turn_right"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, -PI / 2), TRAVEL_TIME)

func _blocked(ray: RayCast3D, lift: float = 0.0) -> bool:
	var space := get_world_3d().direct_space_state
	var from: Vector3 = ray.global_position + Vector3.UP * lift
	var to: Vector3 = ray.to_global(ray.target_position) + Vector3.UP * lift
	var dir: Vector3 = (to - from).normalized()

	for _i in range(4):
		var query := PhysicsRayQueryParameters3D.create(from, to, ray.collision_mask, [get_rid()])
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return false
		if hit.normal.y < WALKABLE_NORMAL_Y:
			return true
		from = hit.position + dir * 0.01

	return true

func _try_move(local_dir: Vector3, ray: RayCast3D) -> bool:
	var target: Transform3D = global_transform.translated_local(local_dir * TILE_SIZE)
	var from_y: float = global_position.y
	var standing: Dictionary = _ground_hit(global_position, from_y, PROBE_UP)
	var hit: Dictionary = _destination_ground(target.origin, from_y)
	var ground: float = hit.position.y if not hit.is_empty() else from_y
	var rise: float = ground - from_y
	var stairs: bool = _is_slope(standing) or _is_slope(hit)

	if rise > (MAX_STAIR_RISE if stairs else MAX_STEP_UP):
		return false

	if _blocked(ray, maxf(rise, 0.0)):
		return false

	var drop: float = 0.0
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if rise < -(MAX_STAIR_RISE if stairs else MAX_STEP_DOWN):
		drop = -rise
		target.origin.y = from_y
		tween.tween_property(self, "global_transform", target, TRAVEL_TIME)
		tween.tween_property(self, "global_position:y", ground, sqrt(2.0 * drop / FALL_GRAVITY)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		target.origin.y = ground
		tween.tween_property(self, "global_transform", target, TRAVEL_TIME)

	tween.finished.connect(_on_step_finished.bind(drop))
	return true

func _on_step_finished(drop: float) -> void:
	snap_to_grid()

	if drop > 0.0:
		player_fell.emit(drop)

	var grid_pos := Vector2i(roundi(global_position.x / TILE_SIZE), roundi(global_position.z / TILE_SIZE))
	var facing_vec: Vector3 = -transform.basis.z.normalized()
	emit_signal("player_moved", { "grid_position": grid_pos, "grid_direction": facing_vec, "height": global_position.y })

func _ground_height(at: Vector3, from_y: float) -> float:
	var hit: Dictionary = _ground_hit(at, from_y, PROBE_UP)
	return hit.position.y if not hit.is_empty() else from_y

func _ground_hit(at: Vector3, from_y: float, up: float) -> Dictionary:
	var top := Vector3(at.x, from_y + up, at.z)
	var bottom := Vector3(at.x, from_y - PROBE_DEPTH, at.z)
	var query := PhysicsRayQueryParameters3D.create(top, bottom, GROUND_MASK, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func _destination_ground(at: Vector3, from_y: float) -> Dictionary:
	var low: Dictionary = _ground_hit(at, from_y, PROBE_UP)
	var high: Dictionary = _ground_hit(at, from_y, STAIR_PROBE_UP)
	if _is_slope(high) and (low.is_empty() or high.position.y > low.position.y + 0.01):
		return high
	return low

func _is_slope(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var ny: float = hit.normal.y
	return ny >= WALKABLE_NORMAL_Y and ny < FLAT_NORMAL_Y

func _settle() -> void:
	_settle_frames -= 1
	var ground: float = _ground_height(global_position, global_position.y)

	if absf(ground - global_position.y) > 0.001:
		global_position.y = ground
		_settle_frames = 0

func snap_to_grid(tile_size: float = TILE_SIZE) -> void:
	var x: int = round(global_position.x / tile_size) * tile_size
	var z: int = round(global_position.z / tile_size) * tile_size
	global_position = Vector3(x, global_position.y, z)

func _on_encounter_started(_encounter_data: EncounterData) -> void:
	can_move = false
	camera_3d.current = false

func _on_encounter_ended(_result: String, _data: EncounterData) -> void:
	can_move = true
	camera_3d.current = true

func _on_map_transition_started(_id: String) -> void:
	can_move = false

func _on_map_transition_ended() -> void:
	can_move = true

func set_grid_pos(pos: Vector2i, player_facing: Vector3, tile_size: float, height: float = 0.0) -> void:
	global_position = Vector3(pos.x * tile_size, height, pos.y * tile_size)
	var target: Vector3 = global_position + player_facing
	look_at(target, Vector3.UP)
	_settle_frames = SETTLE_FRAMES
