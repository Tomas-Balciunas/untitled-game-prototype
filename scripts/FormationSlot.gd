extends Node3D

class_name FormationSlot

@onready var targeting_area: Area3D = $Area3D

var character_instance: CharacterInstance
var body_instance: CharacterBody
var fallback: CharacterResource = load("res://characters/foes/_fallback/boo.tres")
var home_global: Vector3
var animation_player: AnimationPlayer

func _ready() -> void:
	if targeting_area:
		targeting_area.mouse_entered.connect(_on_mouse_entered)
		targeting_area.mouse_exited.connect(_on_mouse_exited)
		targeting_area.input_event.connect(_on_input_event)

func bind(character: CharacterInstance) -> void:
	character_instance = character
	
	for child in get_children():
		if child is CharacterBody3D:
			child.queue_free()

	var body_scene := character.get_body()
	
	if not body_scene:
		push_error("Body scene missing for character: %s id: %s. Defaulting to fallback enemy", [getName(), character_instance.resource.id])
		return

	body_instance = body_scene
	animation_player = body_instance.get_node("AnimationPlayer") as AnimationPlayer
	animation_player.animation_finished.connect(_on_anim_finish)
	self.add_child(body_instance)


func getName() -> String:
	return character_instance.resource.name

func hover() -> void:
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_POINTING_HAND)

func unhover() -> void:
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_ARROW)

func clear() -> void:
	character_instance = null
	unhover()
	#$Portrait.texture = null
	$NameLabel.text = ""


func _on_anim_finish(_e: StringName) -> void:
	body_instance.play_idle()

func perform_attack_toward_target(target: FormationSlot) -> void:
	var tween := create_tween()

	var parent_space := get_parent()
	var self_pos_local: Vector3 = parent_space.to_local(global_position)
	var target_pos_local: Vector3 = parent_space.to_local(target.global_position)

	var to_target := target_pos_local - self_pos_local
	var attack_offset := to_target.normalized() * 1.0
	var stop_position_local := target_pos_local - attack_offset

	body_instance.play_run()

	if character_instance.is_main:
		if has_node("Player/Camera3D"):
			var cam := get_node("Player/Camera3D") as Camera3D
			var target_pos := target.global_position
			var dir := (target_pos - cam.global_position).normalized()
			var desired_yaw := atan2(dir.x, dir.z)
			tween.set_parallel()
			tween.tween_property(cam, "rotation:y", desired_yaw, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position", stop_position_local, 0.7)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await body_instance.play_attack()


func position_back() -> void:
	if animation_player.is_playing() and animation_player.current_animation:
		var anim := animation_player.current_animation
		if not animation_player.get_animation(anim).loop_mode:
			await animation_player.animation_finished

	var parent_space := get_parent()
	var home_local: Vector3 = parent_space.to_local(home_global)

	if position == home_local:
		return

	var tween_back := create_tween()
	tween_back.set_parallel()
	body_instance.play_run_back()
	tween_back.tween_property(self, "position", home_local, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if character_instance.is_main and has_node("Player/Camera3D"):
		var cam := get_node("Player/Camera3D") as Camera3D
		
		tween_back.tween_property(
			cam,
			"rotation:y",
			0,
			0.3
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween_back.finished

	body_instance.play_idle()

func capture_home() -> void:
	home_global = global_position

func on_ded() -> void:
	body_instance.play_dead()

func _on_mouse_entered() -> void:
	if not character_instance:
		return
	hover()

func _on_mouse_exited() -> void:
	if not character_instance:
		return
	unhover()

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if !BattleContext.enemy_targeting_enabled:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		BattleBus.target_selected.emit(character_instance)
