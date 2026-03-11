extends Node

class_name StatusEffectAnimation

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

func play_poison() -> void:
	animated_sprite_3d.visible = true
	animated_sprite_3d.play('tick')
	await animated_sprite_3d.animation_finished
	animated_sprite_3d.visible = false
