extends Node

class_name SlotMarker

var slot: FormationSlot = null


func occupy(s: FormationSlot) -> void:
	slot = s


func vacate() -> void:
	slot = null
