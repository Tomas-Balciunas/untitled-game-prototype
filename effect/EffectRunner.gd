extends Node

var _subscriptions: Dictionary = {}


func subscribe(effect: Effect) -> void:
	for stage in effect.listened_triggers():
		if not _subscriptions.has(stage):
			_subscriptions[stage] = []
		if not _subscriptions[stage].has(effect):
			_subscriptions[stage].append(effect)


func unsubscribe(effect: Effect) -> void:
	for stage in effect.listened_triggers():
		if _subscriptions.has(stage):
			_subscriptions[stage].erase(effect)


func process_trigger(stage: String, event: TriggerEvent) -> void:
	var ctx: ActionContext = event.ctx

	if ctx.temporary_effects:
		for e: Effect in ctx.temporary_effects:
			e.set_owner(ctx.source.get_actor())
			e.set_source(ctx.source)
			if not _passes_filters(e, event):
				continue
			if stage not in e.listened_triggers():
				continue
			if not _scope_matches(e, event):
				continue
			if not e.can_process(stage, event):
				continue
			e.on_trigger(stage, event)
			if e.single_trigger:
				e.remove_self()

	var subscribers: Array = _subscriptions.get(stage, []).duplicate()
	subscribers.sort_custom(_sort_by_priority)

	for effect: Effect in subscribers:
		if ctx.stop_processing:
			break
		if not _passes_filters(effect, event):
			continue
		if not _scope_matches(effect, event):
			continue
		if not effect.can_process(stage, event):
			continue
		effect.on_trigger(stage, event)
		if effect.single_trigger:
			effect.remove_self()


func build_subscriptions(characters: Array[CharacterInstance]) -> void:
	_subscriptions.clear()
	for character in characters:
		for effect in character.effects:
			subscribe(effect)


func post_battle_cleanup(party: Array[CharacterInstance]) -> void:
	for member: CharacterInstance in party:
		for effect: Effect in member.effects:
			if effect.expires_after_battle:
				push_warning("[EffectRunner] post_battle_cleanup: leaked expires_after_battle effect '%s' on '%s'" % [effect.name, member.resource.name])

	build_subscriptions(party)


static func _passes_filters(effect: Effect, event: TriggerEvent) -> bool:
	if not BattleContext.in_battle and effect.battle_only:
		return false
	return true


static func _scope_matches(effect: Effect, event: TriggerEvent) -> bool:
	match effect.get_scope():
		Effect.EffectScope.OWNER_IS_ACTOR:
			return event.actor != null and event.actor.get_actor() == effect.owner
		Effect.EffectScope.OWNER_IS_TARGET:
			var direct_target = event.get("target")
			if direct_target != null:
				return direct_target == effect.owner
			return event.ctx != null and event.ctx.targets.has(effect.owner)
		Effect.EffectScope.GLOBAL:
			return true
	return true


static func _sort_by_priority(a: Effect, b: Effect) -> bool:
	return a.priority > b.priority
