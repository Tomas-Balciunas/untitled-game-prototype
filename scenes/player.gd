extends Node3D

signal player_moved(data: Dictionary)
signal start_encounter(data: Dictionary)
signal map_transition(data: Dictionary)

var grid_pos = Vector2i(0, 0)

var dir_vectors = {
	0: Vector2i(0, -1),
	90: Vector2i(-1, 0),
	180: Vector2i(0, 1),
	270: Vector2i(1, 0),
}

const TILE_SIZE = 2.0
var can_move = true
var in_battle = false
var can_rotate = true

func _ready():
	print("Player instance: %s" % self)
	grid_pos = Vector2i(1, 1)
	global_position = Vector3(grid_pos.x * TILE_SIZE, 0, grid_pos.y * TILE_SIZE)
	rotation_degrees = Vector3(0, 0, 0)

func set_grid_pos(pos: Vector2i):
	grid_pos = pos
	global_position = Vector3(pos.x * TILE_SIZE, 0, pos.y * TILE_SIZE)

func get_facing_direction_deg() -> int:
	var rot = fmod(rotation_degrees.y, 360)
	if rot < 0:
		rot += 360
	return int(round(rot / 90.0)) * 90 % 360

func _unhandled_input(event):
	if not is_all_movement_enabled():
		return

	if event.is_action_pressed("move_forward"):
		move_player("forward")
	elif event.is_action_pressed("move_backwards"):
		move_player("backward")
	elif event.is_action_pressed("strafe_left"):
		move_player("left")
	elif event.is_action_pressed("strafe_right"):
		move_player("right")
	elif event.is_action_pressed("turn_left"):
		rotate_player(90)
	elif event.is_action_pressed("turn_right"):
		rotate_player(-90)

func move_player(direction: String):
	if not is_all_movement_enabled():
		return
	disable_all_movement()
	var facing_deg = get_facing_direction_deg()
	var dir = Vector2i(0, 0)

	match direction:
		"forward":
			dir = dir_vectors.get(facing_deg, Vector2i(0, 0))
		"backward":
			dir = dir_vectors.get((facing_deg + 180) % 360, Vector2i(0, 0))
		"left":
			dir = dir_vectors.get((facing_deg + 90) % 360, Vector2i(0, 0))
		"right":
			dir = dir_vectors.get((facing_deg + 270) % 360, Vector2i(0, 0))

	var target_tile = grid_pos + dir

	# oob check
	if target_tile.y < 0 or target_tile.y >= MapInstance.map_data.size() or target_tile.x < 0 or target_tile.x >= MapInstance.map_data[0].size():
		enable_all_movement()
		print("oob")
		return

	# wall check
	var target_tile_data = MapInstance.map_data[target_tile.y][target_tile.x]
	if target_tile_data["type"] == "wall":
		enable_all_movement()
		return

	grid_pos = target_tile
	var move_offset = Vector3(dir.x * TILE_SIZE, 0, dir.y * TILE_SIZE)
	var target_position = global_position + move_offset

	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 0.25)
	await tween.finished
	print("Emitting player moved signal...")
	emit_signal("player_moved", {
		"grid_position": grid_pos
	})
	
	if EventManager.is_event(target_tile_data):
		EventManager.process_event(target_tile_data["event"])

	if MapManager.is_transition(target_tile_data):
		emit_signal("map_transition", target_tile_data["transition"])
		return
	
	if EncounterManager.is_encounter(target_tile_data):
		var encounter = target_tile_data["encounter"]
		var arena = target_tile_data["arena"]
		emit_signal("start_encounter", {"arena": arena, "enemy": encounter})
		return
	
	enable_all_movement()

func rotate_player(degrees: float):
	if not is_all_movement_enabled():
		return

	var tween = get_tree().create_tween()
	var target_rotation = rotation_degrees
	target_rotation.y += degrees

	tween.tween_property(self, "rotation_degrees", target_rotation, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	var snapped_y = int(round(rotation_degrees.y / 90.0)) * 90 % 360
	rotation_degrees.y = snapped_y if snapped_y >= 0 else snapped_y + 360

	enable_all_movement()

func disable_all_movement() -> void:
	can_rotate = false
	can_move = false
func enable_all_movement() -> void:
	can_rotate = true
	can_move = true
	
func is_all_movement_enabled() -> bool:
	return can_move and can_rotate
