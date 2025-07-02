extends Node3D

class_name EnemySlot

var character_instance: CharacterInstance
var sprite_size
@export var enemy_name: String = ""

func bind(character: CharacterInstance):
	var sprite = $Sprite3D
	character_instance = character
	#if character.resource.portrait:
		#$Portrait.texture = character.resource.portrait
	$NameLabel.text = character.resource.name
	var collision = $CollisionShape3D
	setup_collision_to_match_sprite(sprite, collision)

func setup_collision_to_match_sprite(sprite: Sprite3D, collider: CollisionShape3D):
	var texture_size = sprite.texture.get_size() * sprite.pixel_size
	var scale = sprite.scale
	var sprite_size = Vector2(texture_size.x * scale.x, texture_size.y * scale.y)

	var box_shape = BoxShape3D.new()
	box_shape.extents = Vector3(sprite_size.x / 2, sprite_size.y / 2, 0.05)

	collider.shape = box_shape

func getName():
	return character_instance.resource.name

func hover():
	if character_instance:
		$NameLabel.add_theme_color_override("font_color", Color.RED)
	$Sprite3D.modulate = Color(1,1,1)

func unhover():
	$NameLabel.add_theme_color_override("font_color", Color.WHITE)
	$Sprite3D.modulate = Color(240, 240, 240)

func clear():
	character_instance = null
	unhover()
	#$Portrait.texture = null
	$NameLabel.text = ""
