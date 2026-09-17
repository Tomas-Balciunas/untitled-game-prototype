extends Resource

class_name BattleEvent

signal event_resolved

var _is_connected: bool = false
var _owner: Character = null

func prepare(_own: Character) -> void:
	_own.died.connect(on_death)

func run() -> void:
	pass #execute the event

# TODO: figure out how to pause battle while event is processing - kinda done?
# TODO: need to be able to process event on specific battles
# TODO: and ability to add battle events

func on_death(_own: Character) -> void:
	
	var builer: EventBuilder = EventBuilder.new()
	builer.say("%s" % _own.name, ["test line"])
	var event = builer.build()
	_own.is_dead = false
	_own.set_current_health(200)
	EventManager.process_event(event)
