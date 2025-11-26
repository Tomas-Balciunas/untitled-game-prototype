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
		
		var event: Array = conversation[CharacterInteraction.EVENT]
		var ctx: EventContext
		
		if conversation.has(CharacterInteraction.RANDOM) and conversation[CharacterInteraction.RANDOM]:
			var random_event: Dictionary = event.pick_random()
			ctx = await EventManager.process_event([random_event])
		else:
			ctx = await EventManager.process_event(event)
		
		_run_completion_check(c, conversation, ctx)
		_run_callback(c, conversation, ctx)
		
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


func _run_completion_check(c: BaseCharacterResource, conversation: Dictionary, ctx: EventContext) -> void:
	if not conversation.has(CharacterInteraction.ON_COMPLETED):
		return
	
	var on_completed: Dictionary = conversation.get(CharacterInteraction.ON_COMPLETED, {})
	
	for type: String in on_completed:
		match type:
			CharacterInteraction.MARK_COMPLETED:
				var entries: Array = on_completed[type]
				
				for entry: Dictionary in entries:
					var tag: String = entry[CharacterInteraction.ID]
					
					if entry.has(CharacterInteraction.CONDITIONS):
						var conditions: Dictionary = entry[CharacterInteraction.CONDITIONS]
						
						for condition: Variant in conditions:
							if not _valid_completion_condition(c, conversation, conditions, ctx, condition):
								return
					
					_check_recurring(c.id, tag, conversation)
					InteractionTagManager._mark_tag_completed(c.id, tag)
					
			CharacterInteraction.MARK_AVAILABLE:
				var entries: Array = on_completed[type]
				
				for entry: Dictionary in entries:
					var tag: String = entry[CharacterInteraction.ID]
					
					if entry.has(CharacterInteraction.CONDITIONS):
						var conditions: Dictionary = entry[CharacterInteraction.CONDITIONS]
						
						for condition: Variant in conditions:
							if not _valid_completion_condition(c, conversation, conditions, ctx, condition):
								return
					
					_check_recurring(c.id, tag, conversation)
					InteractionTagManager._add_available_tag_for(c.id, tag)
			_:
				_err(c, conversation, "unsupported completion parameter!")


func _valid_completion_condition(c: BaseCharacterResource, conversation: Dictionary, conditions: Dictionary, ctx: EventContext, condition: String) -> bool:
	match condition:
		CharacterInteraction.CHOICES:
			var choices: Array = conditions[condition]
			
			for choice: String in choices:
				if not ctx.choices.has(choice):
					return false
		_:
			_err(c, conversation, "somehow unsupported callback condition made through")
			return false
	
	return true


func _sanity_check(c: BaseCharacterResource, conversation: Dictionary) -> void:
	if conversation.has(CharacterInteraction.PERSISTENT) and conversation[CharacterInteraction.PERSISTENT] == true:
		return
		
	_warn(c,conversation, "has no completion parameter and wasn't marked as persistent, consider investigating")


func _check_recurring(character_id: String, tag: String, conversation: Dictionary) -> void:
	if conversation.has(CharacterInteraction.RECURRING):
		var recurring: bool = conversation[CharacterInteraction.RECURRING]
		
		if recurring:
			if InteractionTagManager._has_completed_tag_for(character_id, tag):
				InteractionTagManager._remove_completed_tag_for(character_id, tag)


func _run_callback(c: BaseCharacterResource, conversation: Dictionary, ctx: EventContext) -> void:
	if not conversation.has(CharacterInteraction.CALLBACK):
		return
	
	var callback: Dictionary = conversation[CharacterInteraction.CALLBACK]
	var func_name: String = callback[CharacterInteraction.FUNC]
	
	if callback.has(CharacterInteraction.CONDITIONS):
		var conditions: Dictionary = callback[CharacterInteraction.CONDITIONS]
		
		for condition: String in conditions:
			if not _valid_callback_condition(c, conversation, ctx, conditions, condition):
				return
		
	if c.interaction_controller.has_method(func_name):
		c.interaction_controller.call(func_name, ctx, c)

func _valid_callback_condition(c: BaseCharacterResource, conversation: Dictionary, ctx: EventContext, conditions: Dictionary, condition: String) -> bool:
	match condition:
		CharacterInteraction.CHOICES:
			var choices: Array = conditions[condition]
			
			for choice: String in choices:
				if not ctx.choices.has(choice):
					return false
		_:
			_err(c, conversation, "somehow unsupported callback condition made through")
			return false
	
	return true

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
		
	if conversation.has(CharacterInteraction.RECURRING):
		if typeof(conversation[CharacterInteraction.RECURRING]) != TYPE_BOOL:
			_err(c, conversation, "recurring must be bool")
			valid = false
		
	if conversation.has(CharacterInteraction.PERSISTENT):
		if typeof(conversation[CharacterInteraction.PERSISTENT]) != TYPE_BOOL:
			_err(c, conversation, "persistent must be bool")
			valid = false
		
	if conversation.has(CharacterInteraction.RANDOM):
		if typeof(conversation[CharacterInteraction.RANDOM]) != TYPE_BOOL:
			_err(c, conversation, "random must be bool")
			valid = false
		
	if conversation.has(CharacterInteraction.CONDITIONS):
		var conditions: Variant = conversation[CharacterInteraction.CONDITIONS]
		
		if typeof(conditions) != TYPE_ARRAY:
			_err(c, conversation, "conditions must be Array of Dictionaries")
			valid = false
		elif conditions.is_empty():
				_err(c, conversation, "conditions are defined but empty")
				valid = false
		else:
			for condition: Variant in conditions:
				if typeof(condition) != TYPE_DICTIONARY:
					_err(c, conversation, "condition entry must be Dictionary")
					valid = false
				else:
					if not _valid_condition(c, condition, conversation):
						valid = false
	
	if conversation.has(CharacterInteraction.CALLBACK):
		var callback: Variant = conversation[CharacterInteraction.CALLBACK]
		
		if typeof(callback) != TYPE_DICTIONARY:
			_err(c, conversation, "callback entry must be Dictionary")
			valid = false
		else:
			var func_name: Variant = callback.get(CharacterInteraction.FUNC, null)
			var conditions: Variant = callback.get(CharacterInteraction.CONDITIONS, null)
			
			if not func_name:
				_err(c, conversation, "callback func does not exist")
				valid = false
			elif typeof(func_name) != TYPE_STRING:
				_err(c, conversation, "callback func must be a string")
				valid = false
			
			if conditions != null:
				if typeof(conditions) != TYPE_DICTIONARY:
					_err(c, conversation, "callback conditions must be Dictionary")
					valid = false
				elif conditions.is_empty():
					_err(c, conversation, "callback conditions are defined but empty")
					valid = false
				else:
					for condition: Variant in conditions:
						match condition:
							CharacterInteraction.CHOICES:
								var choices: Variant = conditions[condition]
								
								if typeof(choices) != TYPE_ARRAY:
									_err(c, conversation, "callback condition choices must be Array")
									valid = false
								elif choices.is_empty():
									_err(c, conversation, "callback condition choices are defined but empty")
									valid = false
								else:
									for choice: Variant in choices:
										if typeof(choice) != TYPE_STRING:
											_err(c, conversation, "callback condition choices entry must be string")
											valid = false
							_:
								_err(c, condition, "unsupported callback condition")
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

	for type: Variant in on_completed.keys():
		if typeof(on_completed[type]) != TYPE_ARRAY:
			_err(c, conversation, "%s must be Array" % type)
			valid = false

		if on_completed[type].is_empty():
			_err(c, conversation, "%s has no tags" % type)
			valid = false
		else:
			for entry: Variant in on_completed[type]:
				if typeof(entry) != TYPE_DICTIONARY:
					_err(c, conversation, "%s entry must be Dictionary" % type)
					valid = false
				elif on_completed.is_empty():
					_err(c, conversation, "on_completed is empty")
					valid = false
				else:
					var id: Variant = entry.get(CharacterInteraction.ID, null)
					var conditions: Variant = entry.get(CharacterInteraction.CONDITIONS, null)
					
					if not id:
						_err(c, conversation, "on_completed tag id is missing")
						valid = false
					
					if conditions != null:
						if typeof(conditions) != TYPE_DICTIONARY:
							_err(c, conversation, "on_completed conditions must be Dictionary")
							valid = false
						elif conditions.is_empty():
							_err(c, conversation, "on_completed conditions are defined but empty")
							valid = false
						else:
							for condition: Variant in conditions:
									match condition:
										CharacterInteraction.CHOICES:
											var choices: Variant = conditions[condition]
											
											if typeof(choices) != TYPE_ARRAY:
												_err(c, conversation, "on_completed condition choices must be Array")
												valid = false
											elif choices.is_empty():
												_err(c, conversation, "on_completed condition choices are defined but empty")
												valid = false
											else:
												for choice: Variant in choices:
													if typeof(choice) != TYPE_STRING:
														_err(c, conversation, "on_completed condition choices entry must be string")
														valid = false
										_:
											_err(c, condition, "unsupported callback condition")
											valid = false
	
	return valid


func _err(c: BaseCharacterResource, conversation: Dictionary, msg: String) -> void:
	var conv_id: String = conversation.get(CharacterInteraction.ID, "<no ID>")
	push_error("Character %s, Conversation id %s: %s. Full conversation: %s" % [c.id, conv_id, msg, conversation])


func _warn(c: BaseCharacterResource, conversation: Dictionary, msg: String) -> void:
	var conv_id: String = conversation.get(CharacterInteraction.ID, "<no ID>")
	push_warning("Character %s, Conversation id %s: %s. Full conversation: %s" % [c.id, conv_id, msg, conversation])
