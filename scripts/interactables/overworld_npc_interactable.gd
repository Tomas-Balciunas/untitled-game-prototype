extends Interactable
class_name OverworldNPCInteractable

signal overworld_npc_interact_request

func _interact() -> void:
	overworld_npc_interact_request.emit()
