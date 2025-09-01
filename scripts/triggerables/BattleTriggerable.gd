extends Triggerable
class_name BattleTrigger

@export var encounter: EncounterData

func _fire(_data: Dictionary):
	if not encounter:
		return
	
	EncounterManager.start_encounter(encounter)
