extends Node

var debug := true

func process_trigger(event: TriggerEvent) -> void:
	var effects_to_run := []
	
	if event.tags:
		for e in event.tags:
			if not _passes_scope(e, event, true):
				continue
			effects_to_run.append({ "effect": e, "owner": event.actor })
	
	if BattleContext.in_battle:
		var battlers = BattleContext.manager.battlers
		for b in battlers:
			for e in b.effects:
				if not _passes_scope(e, event):
					continue
				effects_to_run.append({ "effect": e, "owner": b })
	else:
		for p in PartyManager.members:
			for e in p.effects:
				if not _passes_scope(e, event):
					continue
				effects_to_run.append({ "effect": e, "owner": p })

	effects_to_run.sort_custom(_sort_effects)

	for entry in effects_to_run:
		var e: Effect = entry.effect
		var owner_for_entry = entry.owner if "owner" in entry else null

		var prev_actor = event.actor
		event.actor = owner_for_entry

		if e.has_method("on_trigger"):
			e.on_trigger(event)
			if debug:
				var owner_name = owner_for_entry and owner_for_entry.resource.name if owner_for_entry.resource else "none"
				print("[EffectProcessor] Running ", e.name, " for trigger ", event.trigger, " owner: ", owner_name)

		event.actor = prev_actor

		#if event.ctx != null and event.ctx.has_method("has_meta") and event.ctx.has_meta("stop_processing"):
			#if event.ctx.get_meta("stop_processing"):
				#if debug: print("[EffectProcessor] processing stopped by", e.name)
				#return

func _sort_effects(a, b) -> int:
	var ea: Effect = a.effect
	var eb: Effect = b.effect
	var pa := int(ea.get_meta("priority")) if ea.has_meta("priority") else 0
	var pb := int(eb.get_meta("priority")) if eb.has_meta("priority") else 0
	return -1 if pa > pb else (1 if pa < pb else 0)

static func _passes_scope(effect: Effect, event: TriggerEvent, is_template = false) -> bool:
	if event.trigger not in effect.listened_triggers():
		return false

	if effect.owner != null:
		match effect.activation_scope:
			EffectTriggers.ActivationScope.OWNER_ONLY:
				return event.actor == effect.owner
			EffectTriggers.ActivationScope.OWNER_SIDE:
				if not BattleContext.in_battle:
					return true
				return BattleContext.manager.same_side(effect.owner, event.ctx.target)
			EffectTriggers.ActivationScope.OPPOSITE_SIDE:
				if not BattleContext.in_battle:
					return false
				return not BattleContext.manager.same_side(effect.owner, event.ctx.target)
			EffectTriggers.ActivationScope.ALL:
				return true
		return false

	if is_template:
		if event.ctx != null:
			var src = event.ctx.source if "source" in event.ctx else null
			var tgt = event.ctx.target if "target" in event.ctx else null
			if event.actor == src or event.actor == tgt:
				return true
		return false

	return false
