extends CanvasLayer

class_name InterfaceRoot

enum Mode { OVERWORLD, BATTLE, EVENT }

@onready var overworld_interface: InterfaceBase = $OverworldInterface
@onready var battle_interface: InterfaceBase = $BattleInterface
@onready var event_interface: InterfaceBase = $EventInterface
@onready var party_interface: InterfaceBase = $PartyInterface


func _ready() -> void:
	show_overworld()
	BattleBus.battle_start.connect(show_battle)
	BattleBus.battle_end.connect(show_overworld)
	
	overworld_interface.set_mode.connect(_set_mode)
	battle_interface.set_mode.connect(_set_mode)
	event_interface.set_mode.connect(_set_mode)
	party_interface.set_mode.connect(_set_mode)
	
	ConversationBus.event_concluded.connect(_on_event_concluded)

func show_overworld()-> void:
	_set_mode(Mode.OVERWORLD)

func show_battle()-> void:
	_set_mode(Mode.BATTLE)

func show_event()-> void:
	_set_mode(Mode.EVENT)

func _set_mode(mode: Mode) -> void:
	for interface: InterfaceBase in [overworld_interface, battle_interface, event_interface, party_interface]:
		interface._set_visibility(mode)

func _on_event_concluded() -> void:
	if BattleContext.in_battle:
		show_battle()
	else:
		show_overworld()
