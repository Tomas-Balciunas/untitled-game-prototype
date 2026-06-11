extends Node3D

class_name FormationSlot

const TURN_INDICATOR_COLOR := Color(0.85, 0.1, 0.1)

@onready var targeting_area: Area3D = $Area3D
var is_slot_targeting_enabled: bool = true

var character_instance: Character
var body_instance: CharacterBody
var fallback: CharacterResource = load("res://characters/foes/_fallback/boo.tres")
var home_global: Vector3
var animation_player: AnimationPlayer
var turn_indicator: MeshInstance3D
var _indicator_tween: Tween

func _ready() -> void:
	if targeting_area:
		targeting_area.mouse_entered.connect(_on_mouse_entered)
		targeting_area.mouse_exited.connect(_on_mouse_exited)
		targeting_area.input_event.connect(_on_input_event)

	_create_turn_indicator()
	BattleBus.turn_started.connect(_on_turn_started)
	BattleBus.turn_ended.connect(_on_turn_ended)

func bind(character: Character) -> void:
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
	
	if character.is_main:
		targeting_area.queue_free()
		
		if body_instance.has_node("Camera3D"):
			var cam: Camera3D = body_instance.get_node("Camera3D")
			cam.rotation_degrees.y = 180


func _create_turn_indicator() -> void:
	turn_indicator = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.45
	ring.outer_radius = 0.6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = TURN_INDICATOR_COLOR
	ring.material = mat
	turn_indicator.mesh = ring
	turn_indicator.position.y = 0.02
	turn_indicator.visible = false
	add_child(turn_indicator)


func _on_turn_started(battler: Character, is_party_member: bool) -> void:
	if is_party_member or battler != character_instance:
		_hide_turn_indicator()
		return

	turn_indicator.visible = true
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(turn_indicator, "scale", Vector3.ONE * 1.15, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_indicator_tween.tween_property(turn_indicator, "scale", Vector3.ONE, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_turn_ended() -> void:
	_hide_turn_indicator()


func _hide_turn_indicator() -> void:
	if _indicator_tween:
		_indicator_tween.kill()
		_indicator_tween = null
	turn_indicator.visible = false
	turn_indicator.scale = Vector3.ONE


func getName() -> String:
	return character_instance.resource.name

func hover() -> void:
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_POINTING_HAND)

func unhover() -> void:
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_ARROW)

func clear() -> void:
	character_instance = null
	_hide_turn_indicator()
	unhover()
	#$Portrait.texture = null
	$NameLabel.text = ""


func _on_anim_finish(_e: StringName) -> void:
	body_instance.play_idle()


func perform_attack(event: ActionEvent, targeting_range: TargetingManager.RangeType, target: FormationSlot) -> void:
	body_instance.play_attack(event, targeting_range, target.global_position)


func perform_skill(event: ActionEvent, targeting_range: TargetingManager.RangeType, animation: String, target: FormationSlot) -> void:
	body_instance.play_skill(event, targeting_range, animation, target.global_position)


func perform_item_use(target: FormationSlot) -> void:
	await perform_run_towards_target(target)
	body_instance.play_item_use()


func perform_run_towards_target(target: FormationSlot) -> void:
	var tween: Tween = create_tween()

	var parent_space := get_parent()
	var self_pos_local: Vector3 = parent_space.to_local(global_position)
	var target_pos_local: Vector3 = parent_space.to_local(target.global_position)

	var to_target := target_pos_local - self_pos_local
	var attack_offset := to_target.normalized() * 1.0
	var stop_position_local := target_pos_local - attack_offset

	body_instance.play_run_back()

	tween.tween_property(self, "position", stop_position_local, 1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func look_at_target(target: FormationSlot) -> void:
	if not body_instance.has_node("Camera3D"):
		return
	
	var cam: Camera3D = body_instance.get_node("Camera3D")
	var target_pos := target.global_position
	var dir := (target_pos - cam.global_position).normalized()
	
	if dir.is_zero_approx():
		return
	
	var desired_yaw := atan2(-dir.x, -dir.z)
	var current_yaw := cam.rotation.y
	var angle_diff := wrapf(desired_yaw - current_yaw, -PI, PI)
	desired_yaw = current_yaw + angle_diff
	
	var tween := create_tween()
	tween.tween_property(cam, "rotation:y", desired_yaw, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished


func position_back() -> void:
	var parent_space := get_parent()
	var home_local: Vector3 = parent_space.to_local(home_global)
	var tween_back: Tween 
	
	if body_instance.has_node("Camera3D"):
		tween_back = create_tween()
		var cam: Camera3D = body_instance.get_node("Camera3D")
		tween_back.tween_property(
			cam,
			"rotation:y",
			0 + PI,
			0.3
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if position == home_local:
		return

	if !tween_back:
		tween_back = create_tween()
	
	tween_back.set_parallel()
	body_instance.play_run()
	tween_back.tween_property(self, "position", home_local, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween_back.finished

	body_instance.play_idle()

func capture_home() -> void:
	home_global = global_position

func perform_death() -> void:
	is_slot_targeting_enabled = false
	_hide_turn_indicator()
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
	if not is_slot_targeting_enabled:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if character_instance:
			CharacterBus.display_status_effects.emit(character_instance)
		return

	var is_ally := character_instance != null and PartyManager.has_member(character_instance.resource.id)
	var targeting_enabled := BattleContext.ally_targeting_enabled if is_ally else BattleContext.enemy_targeting_enabled

	if not targeting_enabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		TargetingManager.battle_target_selected.emit(character_instance)
