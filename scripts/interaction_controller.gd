extends Resource

class_name InteractionController


#TODO: expand conditions/completed states and add global storage for states
func handle(c: BaseCharacterResource) -> void:
	var interactions := c.interactions.get_conversation()
	interactions.sort_custom(func (a, b): return a["priority"] > b["priority"])
	
	for conversation: Dictionary in interactions:
		if not _meets_conditions(c, conversation):
			continue
		
		await EventManager.process_event(conversation["event"])
		
		#if conversation.has("on_completed"):
			#pending.append(conversation["on_completed"])
			#
		#if conversation.has("conditions"):
			#for condition in conversation["conditions"]:
				#pending.erase(condition)
				
		break
		
func _meets_conditions(c: BaseCharacterResource, conversation: Dictionary) -> bool:
	if not conversation.has(CharacterInteraction.CONDITIONS):
		return true
	
	for condition: Dictionary in conversation[CharacterInteraction.CONDITIONS]:
		if not _check_condition(c, condition, conversation):
			return false
			
	return true


func _check_condition(c: BaseCharacterResource, condition: Dictionary, conversation: Dictionary) -> bool:
	var type: String = condition.get(CharacterInteraction.TYPE, null)
	var state: String = condition.get(CharacterInteraction.STATE, null)
	var contains: bool = condition.get(CharacterInteraction.CONTAINS, null)
	var tags: Array = condition.get(CharacterInteraction.TAGS, null)
	var id: String = condition.get(CharacterInteraction.ID, null)

	if not type or not state or not contains or not tags:
		push_error("missing condition param(s) for character: %s and conversation: %s" % [c.id, conversation.get("id", "missing id")])
		return false
		
	if typeof(contains) != TYPE_BOOL:
		push_error("invalid condition contains assigned to character: %s and conversation: %s" % [c.id, conversation.get("id", "missing id")])
		return false
		
	match type:
		CharacterInteraction.SELF:
			id = c.id
		CharacterInteraction.CHARACTER:
			if not id:
				push_error("character id not assigned to condition for character: %s and conversation: %s" % [c.id, conversation.get("id", "missing id")])
				return false
		_:
			push_error("invalid condition type assigned to character: %s and conversation: %s" % [c.id, conversation.get("id", "missing id")])
			return false

	for tag: String in tags:
		var result: bool
			
		match state:
			CharacterInteraction.AVAILABLE:
				result = InteractionTagManager._has_available_tag_for(id, tag)
			CharacterInteraction.COMPLETED:
				result = InteractionTagManager._has_completed_tag_for(id, tag)
			_:
				push_error("invalid condition state assigned to character: %s and conversation: %s" % [c.id, conversation.get("id", "missing id")])
				return false
			
		if contains != result:
			return false

	return true
