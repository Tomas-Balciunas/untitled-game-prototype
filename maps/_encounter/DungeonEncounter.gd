extends CharacterBody3D

enum State { IDLE, PATROL, CHASE, SEARCH, GUARD, RETURN, STUNNED }

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var player: CharacterBody3D = get_tree().get_root().get_node("Main/Player")

@export var encounter_data: EncounterData
@export var enemy_scene: PackedScene

@export_group("Movement")
@export var speed := 1.2
@export var patrol_speed_scale := 0.6

@export_group("Patrol")
@export var patrol_radius := 6.0
@export var patrol_pause := Vector2(1.5, 4.0)

@export_group("Perception")
@export var sight_range := 8.0
@export var eye_height := 0.8

@export_group("Pursuit")
@export var leash_distance := 20.0
@export var search_points := 2
@export var search_radius := 4.0
## when path is blocked
@export var guard_duration := 4.0
## ignore player after dropping aggro
@export var give_up_cooldown := 3.0

@export_group("After battle")
@export var idle_duration := 2.0
@export var flee_grace_duration := 3.0

const ACTIVATION_DISTANCE := 20.0
const CONTACT_DISTANCE := 1.0
const CONTACT_HEIGHT := 1.0
const WALL_MASK := 1
const SIGHT_INTERVAL := 0.15
const REPATH_INTERVAL := 0.3
const STUCK_INTERVAL := 1.0
const STUCK_MIN_PROGRESS := 0.15
const POINT_TRIES := 6

#var visual: CharacterBody3D
var origin: Vector3
var state := State.IDLE
var last_seen := Vector3.ZERO
var can_trigger_battle := true

var _moving := false
var _in_sight := false
var _sees_player := false
var _guard_hold := false
var _search_left := 0

var _state_timer := 0.0
var _sight_timer := 0.0
var _repath_timer := 0.0
var _ignore_timer := 0.0
var _grace_timer := 0.0
var _stuck_timer := 0.0
var _stuck_anchor := Vector3.ZERO


func _ready() -> void:
	assert(encounter_data)
	#assert(enemy_scene)
	EncounterBus.encounter_ended.connect(_on_encounter_ended)
	navigation_agent_3d.velocity_computed.connect(_on_velocity_computed)

	RunState.current.map.add_encounter(encounter_data)

	if RunState.current.map.is_encounter_cleared(encounter_data.id):
		queue_free()
		return

	# disabled for now, just using shadowy forms for enemies for now
	#visual = enemy_scene.instantiate()
	#add_child(visual)

	origin = global_transform.origin
	_enter_idle()


func _physics_process(delta: float) -> void:
	if player == null:
		return

	if GameState.is_busy():
		_set_velocity(Vector3.ZERO)
		return

	_tick_timers(delta)

	if state in [State.IDLE, State.PATROL] and _flat_dist_sq(player.global_position) > ACTIVATION_DISTANCE * ACTIVATION_DISTANCE:
		_set_velocity(Vector3.ZERO)
		return

	_update_perception(delta)

	if _try_contact():
		return

	var stuck := _check_stuck(delta)

	match state:
		State.IDLE:
			if _sees_player:
				_enter_chase()
			elif _state_timer <= 0.0:
				_enter_patrol()
		State.PATROL:
			if _sees_player:
				_enter_chase()
			elif stuck or navigation_agent_3d.is_navigation_finished():
				_enter_idle()
		State.CHASE:
			_process_chase(delta, stuck)
		State.SEARCH:
			if _sees_player:
				_enter_chase()
			elif stuck or navigation_agent_3d.is_navigation_finished():
				_next_search_point()
		State.GUARD:
			_process_guard(delta)
		State.RETURN:
			if _sees_player:
				_enter_chase()
			elif stuck or navigation_agent_3d.is_navigation_finished():
				_enter_idle()
		State.STUNNED:
			if _state_timer <= 0.0:
				if _sees_player:
					_enter_chase()
				else:
					_enter_return()

	_move()


func _process_chase(delta: float, stuck: bool) -> void:
	if _beyond_leash():
		_give_up()
		return

	if not _sees_player:
		_enter_search()
		return

	if stuck:
		_enter_guard(true)
		return

	_repath_timer -= delta
	if _repath_timer > 0.0:
		return

	_repath_timer = REPATH_INTERVAL
	_go_to(player.global_position)

	if not _target_reachable():
		_enter_guard(false)


func _process_guard(delta: float) -> void:
	if _beyond_leash():
		_give_up()
		return

	if _state_timer <= 0.0:
		_give_up()
		return

	if not _sees_player or _guard_hold:
		return

	_repath_timer -= delta
	if _repath_timer > 0.0:
		return

	_repath_timer = REPATH_INTERVAL
	_go_to(player.global_position)

	if _target_reachable():
		_enter_chase()


func _enter_idle() -> void:
	state = State.IDLE
	_stop()
	_state_timer = randf_range(patrol_pause.x, patrol_pause.y)


func _enter_patrol() -> void:
	if patrol_radius <= 0.0:
		if _flat_dist_sq(origin) > 0.25:
			state = State.PATROL
			_go_to(origin)
		else:
			_enter_idle()
		return

	if not _nav_ready():
		_state_timer = 0.5
		return

	state = State.PATROL
	_go_to(_random_point_near(origin, patrol_radius))


func _enter_chase() -> void:
	state = State.CHASE
	_repath_timer = 0.0


func _enter_search() -> void:
	state = State.SEARCH
	_search_left = search_points
	_go_to(last_seen)


func _next_search_point() -> void:
	if _search_left <= 0 or not _nav_ready():
		_enter_return()
		return

	_search_left -= 1
	_go_to(_random_point_near(last_seen, search_radius))


func _enter_guard(hold: bool) -> void:
	state = State.GUARD
	_guard_hold = hold
	_state_timer = guard_duration
	_repath_timer = REPATH_INTERVAL

	if hold:
		_stop()


func _enter_return() -> void:
	state = State.RETURN
	_go_to(origin)


func _enter_stunned(duration: float) -> void:
	state = State.STUNNED
	_state_timer = duration
	_stop()


func _give_up() -> void:
	_ignore_timer = give_up_cooldown
	_sees_player = false
	_enter_return()


func _update_perception(delta: float) -> void:
	_sight_timer -= delta
	if _sight_timer > 0.0:
		return

	_sight_timer = SIGHT_INTERVAL
	_in_sight = _can_see_player()
	_sees_player = _in_sight and _ignore_timer <= 0.0

	if _sees_player:
		last_seen = player.global_position


func _can_see_player() -> bool:
	var eye := global_position + Vector3.UP * eye_height
	var target := player.global_position + Vector3.UP * eye_height

	if eye.distance_squared_to(target) > sight_range * sight_range:
		return false

	var query := PhysicsRayQueryParameters3D.create(eye, target, WALL_MASK, [get_rid(), player.get_rid()])

	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _try_contact() -> bool:
	if not can_trigger_battle or not _in_sight:
		return false

	if _flat_dist_sq(player.global_position) > CONTACT_DISTANCE * CONTACT_DISTANCE:
		return false

	if absf(player.global_position.y - global_position.y) > CONTACT_HEIGHT:
		return false

	_set_velocity(Vector3.ZERO)
	EncounterBus.encounter_started.emit(encounter_data)

	return true


func _go_to(target: Vector3) -> void:
	navigation_agent_3d.target_position = target
	_moving = true
	_reset_stuck()


func _stop() -> void:
	_moving = false
	_set_velocity(Vector3.ZERO)


func _move() -> void:
	if not _moving or navigation_agent_3d.is_navigation_finished():
		_set_velocity(Vector3.ZERO)
		return

	var direction := navigation_agent_3d.get_next_path_position() - global_position
	direction.y = 0.0
	_set_velocity(direction.normalized() * _current_speed())


func _current_speed() -> float:
	if state in [State.PATROL, State.RETURN]:
		return speed * patrol_speed_scale

	return speed


func _set_velocity(value: Vector3) -> void:
	if navigation_agent_3d.avoidance_enabled:
		navigation_agent_3d.velocity = value
	else:
		_apply_velocity(value)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	_apply_velocity(safe_velocity)


func _apply_velocity(value: Vector3) -> void:
	velocity = value

	if value != Vector3.ZERO:
		move_and_slide()
		_follow_ground()


func _follow_ground() -> void:
	if not _nav_ready():
		return

	var map := navigation_agent_3d.get_navigation_map()
	global_position.y = NavigationServer3D.map_get_closest_point(map, global_position).y


func _check_stuck(delta: float) -> bool:
	if not _moving or navigation_agent_3d.is_navigation_finished():
		_reset_stuck()
		return false

	_stuck_timer -= delta
	if _stuck_timer > 0.0:
		return false

	var progress := global_position.distance_to(_stuck_anchor)
	_reset_stuck()

	return progress < STUCK_MIN_PROGRESS


func _reset_stuck() -> void:
	_stuck_timer = STUCK_INTERVAL
	_stuck_anchor = global_position



func _nav_ready() -> bool:
	return NavigationServer3D.map_get_iteration_id(navigation_agent_3d.get_navigation_map()) > 0


func _target_reachable() -> bool:
	navigation_agent_3d.get_next_path_position()
	return navigation_agent_3d.is_target_reachable()


func _random_point_near(center: Vector3, radius: float) -> Vector3:
	var map := navigation_agent_3d.get_navigation_map()

	for _i in POINT_TRIES:
		var angle := randf() * TAU
		var dist := randf_range(radius * 0.3, radius)
		var point := NavigationServer3D.map_get_closest_point(map, center + Vector3(cos(angle), 0.0, sin(angle)) * dist)

		if _flat_dist_sq_between(point, center) > radius * radius:
			continue

		var path := NavigationServer3D.map_get_path(map, global_position, point, true)

		if path.is_empty() or _flat_dist_sq_between(path[path.size() - 1], point) > 0.25:
			continue

		if _path_length(path) > radius * 3.0:
			continue

		return point

	return center


func _path_length(path: PackedVector3Array) -> float:
	var length := 0.0

	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])

	return length


func _beyond_leash() -> bool:
	return _flat_dist_sq(origin) > leash_distance * leash_distance


func _flat_dist_sq(point: Vector3) -> float:
	return _flat_dist_sq_between(global_position, point)


func _flat_dist_sq_between(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length_squared()


func _tick_timers(delta: float) -> void:
	_state_timer -= delta
	_ignore_timer -= delta

	if not can_trigger_battle:
		_grace_timer -= delta
		if _grace_timer <= 0.0:
			can_trigger_battle = true



func _on_encounter_ended(_res: String, data: EncounterData) -> void:
	if data.id != encounter_data.id:
		return

	if RunState.current.map.is_encounter_cleared(data.id):
		queue_free()
		return

	can_trigger_battle = false
	_grace_timer = flee_grace_duration
	_enter_stunned(idle_duration)
