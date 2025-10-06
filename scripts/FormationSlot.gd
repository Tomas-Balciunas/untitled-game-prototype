extends Node3D

class_name FormationSlot

var character_instance: CharacterInstance
var sprite_instance: Sprite3D
var body_instance: CharacterBody
var fallback: CharacterResource = load("res://characters/foes/_fallback/boo.tres")
var home_global: Vector3
var animation_player: AnimationPlayer

func bind(character: CharacterInstance):
	character_instance = character
	character_instance.damaged.connect(Callable(self, "_on_damaged"))
	
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()

	var body_scene = character.resource.character_body
	
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

func getName():
	return character_instance.resource.name

func hover():
	sprite_instance.modulate = Color(1.0, 0.6, 0.6)

func unhover():
	sprite_instance.modulate = Color(1.0, 1.0, 1.0)

func clear():
	character_instance = null
	unhover()
	#$Portrait.texture = null
	$NameLabel.text = ""

func _on_damaged(_damage: int, _char: CharacterInstance):
	body_instance.play_damaged()

func _on_anim_finish(e):
	print(e)
	body_instance.play_idle()

func perform_attack_toward_target(target: FormationSlot) -> void:
	var tween = create_tween()

	var parent_space = get_parent()
	var self_pos_local = parent_space.to_local(global_position)
	var target_pos_local = parent_space.to_local(target.global_position)

	var to_target = target_pos_local - self_pos_local
	var attack_offset = to_target.normalized() * 1.0
	var stop_position_local = target_pos_local - attack_offset

	tween.tween_property(self, "position", stop_position_local, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await body_instance.play_attack()


func position_back():
	if animation_player.is_playing() and animation_player.current_animation:
		var anim = animation_player.current_animation
		if not animation_player.get_animation(anim).loop_mode:
			await animation_player.animation_finished

	var parent_space = get_parent()
	var home_local = parent_space.to_local(home_global)

	if position == home_local:
		return

	var tween_back = create_tween()
	body_instance.play_run_back()
	tween_back.tween_property(self, "position", home_local, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween_back.finished

	body_instance.play_idle()

func capture_home() -> void:
	home_global = global_position

func on_ded():
	await body_instance.play_dead()
