# Player.gd
extends Node3D

var grid_pos = Vector2i(0, 0)
@onready var dungeon = get_tree().get_root().get_node("Main/Dungeon")  # Adjust path if necessary

var dir_vectors = {
	0: Vector2i(0, -1),
	90: Vector2i(-1, 0),
	180: Vector2i(0, 1),
	270: Vector2i(1, 0),
}

const TILE_SIZE = 2.0
var can_move = true
var rotating = false

func _ready():
	grid_pos = Vector2i(1, 1)  # Initial position, will be overridden by dungeon
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

func _process(_delta):
	if can_move and not rotating:
		if Input.is_action_just_pressed("move_forward"):
			move_player("forward")
		elif Input.is_action_just_pressed("move_backwards"):
			move_player("backward")
		elif Input.is_action_just_pressed("strafe_left"):
			move_player("left")
		elif Input.is_action_just_pressed("strafe_right"):
			move_player("right")
		elif Input.is_action_just_pressed("turn_left"):
			rotate_player(90)
		elif Input.is_action_just_pressed("turn_right"):
			rotate_player(-90)

func move_player(direction: String):
	if not can_move or rotating:
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

	# Out-of-bounds check
	if target_tile.y < 0 or target_tile.y >= dungeon.map_data.size() or target_tile.x < 0 or target_tile.x >= dungeon.map_data[0].size():
		can_move = true
		return

	# Wall check
	var target_tile_data = dungeon.map_data[target_tile.y][target_tile.x]
	if target_tile_data["type"] == "wall":
		can_move = true
		return

	grid_pos = target_tile
	var move_offset = Vector3(dir.x * TILE_SIZE, 0, dir.y * TILE_SIZE)
	var target_position = global_position + move_offset

	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 0.25)
	await tween.finished
	can_move = true

	# Check for map transition
	if grid_pos in MapManager.maps[dungeon.current_map]["transitions"]:
		can_move = false
		var target_map = MapManager.maps[dungeon.current_map]["transitions"][grid_pos]
		dungeon.transition_to_map(target_map)
	
	#if "encounter" in target_tile_data:
		#var encounter = target_tile_data["encounter"]
		#print(encounter)

func rotate_player(degrees: float):
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

func spawn_enemy(enemy_type: String):
	# Logic to spawn an enemy (e.g., instantiate an enemy scene)
	print("Spawning a %s!" % enemy_type)
