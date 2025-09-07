extends CharacterBody3D

class_name CharacterBody

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var sprite: AnimatedSprite3D = $Sprite

func _ready() -> void:
	play_idle()

func play_idle():
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
		
func play_dead():
	if sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")

func play_run():
	if sprite.sprite_frames.has_animation("run_front"):
		sprite.play("run_front")
		
func play_run_back():
	if sprite.sprite_frames.has_animation("run_back"):
		sprite.play("run_back")
		
func play_run_left():
	if sprite.sprite_frames.has_animation("run_left"):
		sprite.play("run_left")

func play_run_right():
	if sprite.sprite_frames.has_animation("run_right"):
		sprite.play("run_right")

func play_attack() -> void:
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		await sprite.animation_finished

func play_damaged():
	if sprite.sprite_frames.has_animation("damaged"):
		sprite.play("damaged")

func _on_damaged(a, b):
	play_damaged()

func _on_anim_finish():
	play_idle()
