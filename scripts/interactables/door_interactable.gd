extends Interactable
class_name DoorInteractable

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var door: Door = null

func _interact() -> void:
	if door == null:
		door = Door.new()
	
	if door.key != null or door.trap != null:
		ObjectBus.open_door_requested.emit(door)
		return
	
	if !door.is_open:
		animation_player.play("open")
		door.is_open = true
	else:
		animation_player.play("close")
		door.is_open = false
