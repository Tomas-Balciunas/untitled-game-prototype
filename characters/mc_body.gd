extends CharacterBody

class_name MainCharacterBody

@onready var melee_attack: Sprite2D = $Attack
@onready var camera_3d: Camera3D = $Camera3D


func play_attack(event: ActionEvent, targeting_range: TargetingManager.RangeType, target_pos: Vector3) -> void:
	if targeting_range == TargetingManager.RangeType.RANGED:
			fire_projectile(event, target_pos)
			
			return
	
	if animation_player.has_animation("attack"):
		animation_player.stop()
		melee_attack.global_position = get_viewport().size / 2
		melee_attack.rotation_degrees = randf_range(-150.0, 50.0)
		animation_player.play("attack")
		await hit_confirmed
		event.confirm()
		await animation_player.animation_finished


func set_projectile_spawn_point() -> void:
	if (camera_3d.has_node("ProjectileSpawn")):
		projectile_spawn = camera_3d.get_node("ProjectileSpawn")
