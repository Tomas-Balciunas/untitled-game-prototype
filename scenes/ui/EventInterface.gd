extends InterfaceBase

enum Mode { CONVERSATION, CHOICE }

@onready var conversation_interface: Control = %ConversationInterface
@onready var choice_interface: Control = %ChoiceInterface


func _ready() -> void:
	ConversationBus.request_conversation.connect(_on_request_conversation)
	ConversationBus.request_choice.connect(_on_request_choice)


func _set_visibility(mode: InterfaceRoot.Mode) -> void:
	visible = mode == InterfaceRoot.Mode.EVENT


func _set_mode(mode: Mode) -> void:
	conversation_interface.visible = mode == Mode.CONVERSATION
	choice_interface.visible = mode == Mode.CHOICE


func _on_request_conversation(speaker: String, lines: Array) -> void:
	set_mode.emit(InterfaceRoot.Mode.EVENT)
	_set_mode(Mode.CONVERSATION)
	conversation_interface.init_conversation(speaker, lines)


func _on_request_choice(text: String, choices: Array) -> void:
	set_mode.emit(InterfaceRoot.Mode.EVENT)
	_set_mode(Mode.CHOICE)
	choice_interface.init_choice(text, choices)
