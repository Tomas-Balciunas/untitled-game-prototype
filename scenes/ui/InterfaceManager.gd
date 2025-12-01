extends CanvasLayer

class_name InterfaceRoot

enum Mode { OVERWORLD, BATTLE, EVENT }

@onready var overworld_interface: Control = $OverworldInterface
@onready var battle_interface: Control = $BattleInterface
@onready var event_interface: Control = $EventInterface
@onready var party_interface: Control = $PartyInterface


func _ready() -> void:
	show_overworld()

func show_overworld()-> void:
	_set_mode(Mode.OVERWORLD)

func show_battle()-> void:
	_set_mode(Mode.BATTLE)

func show_event()-> void:
	_set_mode(Mode.EVENT)

func _set_mode(mode: Mode) -> void:
	for interface: InterfaceBase in [overworld_interface, battle_interface, event_interface, party_interface]:
		interface._set_visibility(mode)
