extends Resource

class_name BattleEvent

signal event_resolved()

var _is_connected: bool = false
var _owner: CharacterInstance = null

func prepare(_own: CharacterInstance):
	pass #connect to battle event bus so we can listen to signals emitted by battle manager

func run():
	pass #execute the event

# TODO: figure out how to pause battle while event is processing
