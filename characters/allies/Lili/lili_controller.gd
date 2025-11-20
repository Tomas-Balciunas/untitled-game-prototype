extends InteractionController

class_name LiliController

var pending := ["first_encounter"]
var completed := []

#TODO: make generic and expand conditions/completed states and add global storage for states
func handle(c: BaseCharacterResource) -> void:
	var interactions := c.interactions.get_conversation()
	interactions.sort_custom(func (a, b): return a["priority"] > b["priority"])
	
	for conversation in interactions:
		if conversation.has("conditions"):
			var meets := true
			
			for condition in conversation["conditions"]:
				if not pending.has(condition):
					meets = false
			
			if not meets:
				continue
		
		await EventManager.process_event(conversation["event"])
		
		if conversation.has("on_completed"):
			pending.append(conversation["on_completed"])
			
		if conversation.has("conditions"):
			for condition in conversation["conditions"]:
				pending.erase(condition)
				
		break
		
	
func to_dict() -> Dictionary:
	return {}
	
func from_dict(saved_flags: Dictionary) -> void:
	pass
	#if saved_flags:
		#flags = saved_flags
