extends CharacterBody

class_name MainCharacterBody

@onready var melee_attack: Sprite2D = $Attack


func play_attack(range: TargetingManager.RangeType, target_pos: Vector3) -> void:
	if range == TargetingManager.RangeType.RANGED:
			fire_projectile(target_pos)
			
			return
	
	if animation_player.has_animation("attack"):
		animation_player.stop()
		melee_attack.global_position = get_viewport().size / 2
		melee_attack.rotation_degrees = randf_range(-150.0, 50.0)
		animation_player.play("attack")
		await animation_player.animation_finished
