extends Node3D

class_name FormationSlot

@onready var targeting_area: Area3D = $Area3D
@onready var number_display: FormationSlotNumbers = $NumberDisplay

var character_instance: CharacterInstance
var sprite_instance: Sprite3D
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
	CharacterBus.character_damaged.connect(_on_damaged)
	CharacterBus.character_healed.connect(_on_healed)
	
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()

	var body_scene := character.resource.character_body
	
	if not body_scene:
		body_scene = fallback.character_body
		print("Body is missing for character: %s id: %s. Defaulting to fallback enemy", [getName(), character_instance.resource.id])

	body_instance = body_scene.instantiate()
	sprite_instance = body_instance.get_node("Sprite") as Sprite3D
	animation_player = body_instance.get_node("AnimationPlayer") as AnimationPlayer
	animation_player.animation_finished.connect(_on_anim_finish)
	self.add_child(body_instance)

	if not sprite_instance:
		print("Sprite is missing for character: %s id: %s", [getName(), character_instance.resource.id])
	
	#if character.resource.portrait:
		#$Portrait.texture = character.resource.portrait

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

func _on_damaged(who: CharacterInstance, amt: int) -> void:
	if character_instance == who:
		body_instance.play_damaged()
		number_display.display_damage(amt)

func _on_healed(who: CharacterInstance, amt: int) -> void:
	if character_instance == who:
		number_display.display_heal(amt)

func _on_anim_finish(_e) -> void:
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
	tween.tween_property(self, "position", stop_position_local, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	body_instance.play_run_back()
	tween_back.tween_property(self, "position", home_local, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween_back.finished

	body_instance.play_idle()

func capture_home() -> void:
	home_global = global_position

func on_ded() -> void:
	await body_instance.play_dead()

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
