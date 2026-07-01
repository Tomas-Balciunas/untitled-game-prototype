extends Interactable
class_name DoorInteractable

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var is_open: bool = false



func _interact() -> void:
	if !is_open:
		animation_player.play("open")
		is_open = true
	else:
		animation_player.play("close")
		is_open = false
