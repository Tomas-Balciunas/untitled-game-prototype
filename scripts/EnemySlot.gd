extends Node3D

class_name EnemySlot

var character_instance: CharacterInstance
var sprite_instance: AnimatedSprite3D
var fallback: CharacterResource = load("res://characters/foes/_fallback/boo.tres")
var home_global: Vector3

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

	var body_instance = body_scene.instantiate()
	sprite_instance = body_instance.get_node("Sprite")
	sprite_instance.animation_finished.connect(_on_anim_finish)
	self.add_child(body_instance)

	if sprite_instance and sprite_instance.sprite_frames.has_animation("idle"):
		sprite_instance.play("idle")
	else:
		print("Sprite is missing for character: %s id: %s", [getName(), character_instance.resource.id])
	
	#if character.resource.portrait:
		#$Portrait.texture = character.resource.portrait
	$NameLabel.text = character.resource.name

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

func _on_damaged(damage: int, char: CharacterInstance):
	if sprite_instance:
		sprite_instance.play("damaged")

func _on_anim_finish():
	sprite_instance.play("idle")

func perform_attack_toward_camera(strike_pos: Vector3) -> void:
	var tween = create_tween()
	if sprite_instance and sprite_instance.sprite_frames.has_animation("run_front"):
		sprite_instance.play("run_front")
	tween.tween_property(self, "position", strike_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	if sprite_instance and sprite_instance.sprite_frames.has_animation("attack"):
		sprite_instance.play("attack")
		await sprite_instance.animation_finished

func position_back():
	var tween_back = create_tween()
	if sprite_instance and sprite_instance.sprite_frames.has_animation("run_back"):
		sprite_instance.play("run_back")
	tween_back.tween_property(self, "position", home_global, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween_back.finished

	if sprite_instance and sprite_instance.sprite_frames.has_animation("idle"):
		sprite_instance.play("idle")

func capture_home() -> void:
	home_global = global_position
