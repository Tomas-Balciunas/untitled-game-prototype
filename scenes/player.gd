extends Node3D

signal player_moved(data: Dictionary)
signal start_encounter(data: Dictionary)

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
var rotating = false

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
	if not can_move and rotating:
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
	if not can_move or rotating or in_battle:
		return
	can_move = false
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
		can_move = true
		print("oob")
		return

	# Wall check
	var target_tile_data = MapInstance.map_data[target_tile.y][target_tile.x]
	if target_tile_data["type"] == "wall":
		can_move = true
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
	can_move = true

	#if grid_pos in MapInstance.transitions:
		#can_move = false
		#var target_map = MapManager.maps[MapInstance.current_map]["transitions"][grid_pos]
		#dungeon.transition_to_map(target_map)
	
	if EncounterManager.is_encounter(target_tile_data):
		var encounter = target_tile_data["encounter"]
		emit_signal("start_encounter", {"type": encounter})

func rotate_player(degrees: float):
	if in_battle:
		return
	
	rotating = true
	can_move = false

	var tween = get_tree().create_tween()
	var target_rotation = rotation_degrees
	target_rotation.y += degrees

	tween.tween_property(self, "rotation_degrees", target_rotation, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	var snapped_y = int(round(rotation_degrees.y / 90.0)) * 90 % 360
	rotation_degrees.y = snapped_y if snapped_y >= 0 else snapped_y + 360

	rotating = false
	can_move = true
