extends Node

const DAMAGED := "damaged"
const ATTACKING := "attacking"

func _ready() -> void:
	ChatEventBus.chat_event.connect(_on_chatter_event_received)
	
func _on_chatter_event_received(e: String, data: Dictionary) -> void:
	match e:
		DAMAGED: 
			_on_damaged_event(data)
		ATTACKING:
			_on_attacking_event(data)

func _on_damaged_event(data: Dictionary) -> void:
	var amount: int = data.get("amount", null)
	var target: CharacterInstance = data.get("target", null)
	var ctx: ActionContext = data.get("ctx", null)
	
	if target == null:
		if ctx and ctx.target:
			target = ctx.target
		else:
			push_error("context and target missing in chatter manager damaged event")
			return
	
	if !target.interactions:
		return
	
	var line: String = target.interactions.get_damaged_line(DAMAGED, amount, ctx)
		
	if !line == "":
		ChatEventBus.chat.emit(target, line)

func _on_attacking_event(data: Dictionary) -> void:
	var source: CharacterInstance = data.get("source", null)
	var targets: Array = data.get("target", [])
	
	if !source:
		push_error("target missing in chatter manager attacking event")
		return
	
	if !source.interactions:
		return
		
	var line: String = source.interactions.get_attacking_line(ATTACKING, source, targets)
	
	if !line == "":
		ChatEventBus.chat.emit(source, line)
