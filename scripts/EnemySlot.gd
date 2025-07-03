extends StaticBody3D

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
	$Sprite3D.modulate = Color(1.0, 0.6, 0.6)

func unhover():
	$Sprite3D.modulate = Color(1.0, 1.0, 1.0)

func clear():
	character_instance = null
	unhover()
	#$Portrait.texture = null
	$NameLabel.text = ""
