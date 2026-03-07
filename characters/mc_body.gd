extends CharacterBody

class_name MainCharacterBody

@onready var melee_attack: Sprite2D = $Attack


func play_attack(range: TargetingManager.RangeType) -> void:
	if range == TargetingManager.RangeType.MELEE:
		if animation_player.has_animation("melee_attack"):
			melee_attack.global_position = get_viewport().size / 2
			animation_player.play("melee_attack")
			await animation_player.animation_finished
			
			return
	
	if range == TargetingManager.RangeType.RANGED:
		if animation_player.has_animation("ranged_attack"):
			animation_player.play("ranged_attack")
			await animation_player.animation_finished
			
			return
	
	if animation_player.has_animation("attack"):
		melee_attack.global_position = get_viewport().size / 2
		animation_player.play("attack")
		await animation_player.animation_finished
