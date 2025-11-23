extends Resource

class_name InteractionController


func _get_default_tags() -> Array:
	return []


func handle(c: BaseCharacterResource) -> void:
	var interactions := c.interactions.get_interactions()
	interactions.sort_custom(func (a, b): return a["priority"] > b["priority"])
	
	for conversation: Dictionary in interactions:
		if not _valid_conversation(c, conversation):
			continue
		
		if not _meets_conditions(c, conversation):
			continue
		
		await EventManager.process_event(conversation["event"])
		
		_run_completion_check(c, conversation)
		
		break


func _meets_conditions(c: BaseCharacterResource, conversation: Dictionary) -> bool:
	if not conversation.has(CharacterInteraction.CONDITIONS):
		return true
	
	for condition: Dictionary in conversation[CharacterInteraction.CONDITIONS]:
		if not _check_condition(c, condition, conversation):
			return false
			
	return true


func _check_condition(c: BaseCharacterResource, condition: Dictionary, conversation: Dictionary) -> bool:
	var type: String = condition[CharacterInteraction.TYPE]
	var state: String = condition[CharacterInteraction.STATE]
	var contains: bool = condition[CharacterInteraction.CONTAINS]
	var tags: Array = condition[CharacterInteraction.TAGS]
	var id: String = condition.get(CharacterInteraction.ID, "")
	
	match type:
		CharacterInteraction.SELF:
			id = c.id
		CharacterInteraction.CHARACTER:
			if id == "":
				_err(c, conversation, "condition type is character but has no character id")
				return false
		_:
			_err(c, conversation, "unsupported  condition type!")
			return false

	for tag: String in tags:
		var result: bool
			
		match state:
			CharacterInteraction.AVAILABLE:
				result = InteractionTagManager._has_available_tag_for(id, tag)
			CharacterInteraction.COMPLETED:
				result = InteractionTagManager._has_completed_tag_for(id, tag)
			_:
				_err(c, conversation, "unsupported condition state!")
				return false
			
		if contains != result:
			return false

	return true


func _run_completion_check(c: BaseCharacterResource, conversation: Dictionary) -> void:
	var on_completed: Dictionary = conversation.get(CharacterInteraction.ON_COMPLETED, {})
	
	for action: String in on_completed:
		match action:
			CharacterInteraction.MARK_COMPLETED:
				var tags: Array = on_completed.get(action, [])
				
				for tag: String in tags:
					InteractionTagManager._mark_tag_completed(c.id, tag)
			CharacterInteraction.MARK_AVAILABLE:
				var tags: Array = on_completed.get(action, [])
				
				for tag: String in tags:
					InteractionTagManager._add_available_tag_for(c.id, tag)
			_:
				_err(c, conversation, "unsupported completion parameter!")


func _sanity_check(c: BaseCharacterResource, conversation: Dictionary) -> void:
	if conversation.has(CharacterInteraction.PERSISTENT) and conversation[CharacterInteraction.PERSISTENT] == true:
		return
		
	_warn(c,conversation, "has no completion parameter and wasn't marked as persistent, consider investigating")


func _valid_conversation(c: BaseCharacterResource, conversation: Dictionary) -> bool:
	var valid := true
	
	if not conversation.has(CharacterInteraction.ID):
		_warn(c, conversation, "conversation has no ID; debugging will be harder")
		
	if not conversation.has(CharacterInteraction.PRIORITY):
		_err(c, conversation, "missing priority")
		valid = false
	elif typeof(conversation[CharacterInteraction.PRIORITY]) != TYPE_INT:
		_err(c, conversation, "priority must be int")
		valid = false
		
	if not conversation.has(CharacterInteraction.EVENT):
		_err(c, conversation, "missing event")
		valid = false
	elif typeof(conversation[CharacterInteraction.EVENT]) != TYPE_ARRAY:
		_err(c, conversation, "event must be Array of steps")
		valid = false
		
	if conversation.has(CharacterInteraction.CONDITIONS):
		var conditions: Variant = conversation[CharacterInteraction.CONDITIONS]
		
		if typeof(conditions) != TYPE_ARRAY:
			_err(c, conversation, "conditions must be Array of Dictionaries")
			valid = false
		else:
			for condition: Variant in conditions:
				if typeof(condition) != TYPE_DICTIONARY:
					_err(c, conversation, "condition entry must be Dictionary")
					valid = false
				else:
					if not _valid_condition(c, condition, conversation):
						valid = false
	
	if conversation.has(CharacterInteraction.ON_COMPLETED):
		if not _valid_on_completed(c, conversation, conversation[CharacterInteraction.ON_COMPLETED]):
			valid = false
	else:
		_sanity_check(c, conversation)
	
	return valid


func _valid_condition(c: BaseCharacterResource, condition: Dictionary, conversation: Dictionary) -> bool:
	var valid := true
	
	if not condition.has(CharacterInteraction.TYPE):
		_err(c, conversation, "missing condition param %s" % CharacterInteraction.TYPE)
		valid = false
	elif typeof(condition[CharacterInteraction.TYPE]) != TYPE_STRING:
		_err(c, conversation, "invalid type of condition param %s" % CharacterInteraction.TYPE)
		valid = false
		
	if not condition.has(CharacterInteraction.STATE):
		_err(c, conversation, "missing condition param %s" % CharacterInteraction.STATE)
		valid = false
	elif typeof(condition[CharacterInteraction.STATE]) != TYPE_STRING:
		_err(c, conversation, "invalid type of condition param %s" % CharacterInteraction.STATE)
		valid = false
		
	if not condition.has(CharacterInteraction.CONTAINS):
		_err(c, conversation, "missing condition param %s" % CharacterInteraction.CONTAINS)
		valid = false
	elif typeof(condition[CharacterInteraction.CONTAINS]) != TYPE_BOOL:
		_err(c, conversation, "invalid type of condition param %s" % CharacterInteraction.CONTAINS)
		valid = false
		
	if not condition.has(CharacterInteraction.TAGS):
		_err(c, conversation, "missing condition param %s" % CharacterInteraction.TAGS)
		valid = false
	elif typeof(condition[CharacterInteraction.TAGS]) != TYPE_ARRAY:
		_err(c, conversation, "invalid type of condition param %s" % CharacterInteraction.TAGS)
		valid = false
	
	
	return valid


func _valid_on_completed(c: BaseCharacterResource, conversation: Dictionary, on_completed: Variant) -> bool:
	var valid := true
	
	if typeof(on_completed) != TYPE_DICTIONARY:
		_err(c, conversation, "on_completed must be Dictionary")
		valid = false

	if on_completed.is_empty():
		_err(c, conversation, "on_completed is empty")
		valid = false

	for action: Variant in on_completed.keys():
		if typeof(on_completed[action]) != TYPE_ARRAY:
			_err(c, conversation, "%s tags must be Array" % action)
			valid = false

		if on_completed[action].is_empty():
			_err(c, conversation, "%s has no tags" % action)
			valid = false
	
	return valid


func _err(c: BaseCharacterResource, conversation: Dictionary, msg: String) -> void:
	var conv_id: String = conversation.get(CharacterInteraction.ID, "<no ID>")
	push_error("Character %s, Conversation id %s: %s. Full conversation: %s" % [c.id, conv_id, msg, conversation])


func _warn(c: BaseCharacterResource, conversation: Dictionary, msg: String) -> void:
	var conv_id: String = conversation.get(CharacterInteraction.ID, "<no ID>")
	push_warning("Character %s, Conversation id %s: %s. Full conversation: %s" % [c.id, conv_id, msg, conversation])
