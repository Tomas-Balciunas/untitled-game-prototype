extends Node3D

class_name EnemySlot

var character_instance: CharacterInstance
var sprite_size
var sprite_instance: AnimatedSprite3D
@export var fallback: CharacterResource


func bind(character: CharacterInstance):
	character_instance = character
	
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()

	var body_scene = character.resource.character_body
	
	if not body_scene:
		body_scene = fallback.character_body
		print("Body is missing for character: %s id: %s. Defaulting to fallback enemy", [getName(), character_instance.resource.id])

	var body_instance = body_scene.instantiate()
	sprite_instance = body_instance.get_node("Sprite")
	self.add_child(body_instance)

	if sprite_instance:
		sprite_instance.play("Idle")
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
