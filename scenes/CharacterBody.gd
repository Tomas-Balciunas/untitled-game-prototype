extends CharacterBody3D
class_name CharacterBody

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var sprite: Sprite3D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

@export var blend_parameter: String = "parameters/blend_position"

@export var debug: bool = false
var _last_anim: String = ""
var _last_pos: Vector3

func _process(_delta: float) -> void:
	var pos = global_transform.origin
	var move_vec = pos - _last_pos
	move_vec.y = 0.0
	if move_vec.length() > 0.0001:
		update_animation_by_move_world(move_vec, get_viewport().get_camera_3d())
	else:
		update_animation_by_move_world(Vector3.ZERO, get_viewport().get_camera_3d())
	_last_pos = pos

func _ready() -> void:
	if animation_tree:
		animation_tree.active = true
		play_idle()
	if debug:
		print("CharacterBody ready. tree:", animation_tree, "player:", animation_player)
		if animation_player:
			print("AnimPlayer animations:", animation_player.get_animation_list())
		if sprite and sprite.sprite_frames:
			print("Sprite animations:", sprite.sprite_frames.get_animation_names())

func _set_blend(vec: Vector2) -> void:
	if not animation_tree:
		return
	vec.x = clamp(vec.x, -1.0, 1.0)
	vec.y = clamp(vec.y, -1.0, 1.0)
	animation_tree.set(blend_parameter, vec)
	if debug:
		print("blend ->", vec)

func play_idle():
	if animation_tree:
		_set_blend(Vector2.ZERO)
		return

func play_dead():
	if animation_player.has_animation("dead"):
		animation_player.play("dead")

func play_run():
	_set_blend(Vector2(0, -1))
	return

func play_run_back():
	_set_blend(Vector2(0, 1))
	return

func play_run_left():
	_set_blend(Vector2(-1, 0))
	return

func play_run_right():
	_set_blend(Vector2(1, 0))
	return

func play_attack() -> void:
	if animation_player.has_animation("attack"):
		if animation_tree:
			animation_tree.active = false
		animation_player.play("attack")
		await animation_player.animation_finished
		if animation_tree:
			animation_tree.active = true

func play_damaged():
	if animation_player.has_animation("damaged"):
		if animation_tree:
			animation_tree.active = false
		animation_player.play("damaged")
		await animation_player.animation_finished
		if animation_tree:
			animation_tree.active = true

func _on_damaged(_a, _b):
	play_damaged()
	

func _on_anim_finish():
	if animation_tree:
			animation_tree.active = true

func update_animation_by_move_world(move_dir: Vector3, cam: Camera3D = null) -> void:
	if not cam:
		cam = get_viewport().get_camera_3d()
	if not cam:
		return

	move_dir.y = 0.0
	var speed = move_dir.length()
	if speed < 0.002:
		if _last_anim != "idle":
			play_idle()
			_last_anim = "idle"
		return

	var mvn = move_dir.normalized()

	var view_dir = (cam.global_transform.origin - global_transform.origin)
	view_dir.y = 0.0
	if view_dir.length() == 0:
		view_dir = Vector3(0,0,-1)
	else:
		view_dir = view_dir.normalized()

	var cam_right = cam.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var fd = mvn.dot(view_dir)
	var rd = mvn.dot(cam_right)

	if animation_tree:
		var blend = Vector2(rd, fd)
		if animation_tree:
			animation_tree.active = true
		_set_blend(blend)
		_last_anim = "blend"
		if debug:
			print("mv=", move_dir, "fd=", fd, "rd=", rd, "blend=", blend)
		return

	if abs(fd) >= abs(rd):
		if fd > 0:
			play_run_back()
			_last_anim = "run_back"
		else:
			play_run()
			_last_anim = "run_front"
	else:
		if rd > 0:
			play_run_right()
			_last_anim = "run_right"
		else:
			play_run_left()
			_last_anim = "run_left"
