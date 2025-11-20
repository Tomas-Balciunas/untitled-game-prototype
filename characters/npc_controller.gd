extends Node

func _ready() -> void:
	for child: OverworldNPC in get_children():
		if not child._should_spawn():
			child.queue_free()
