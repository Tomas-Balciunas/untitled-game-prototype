extends Node


func process_trigger(event: TriggerEvent) -> void:
	var effects_to_run := []
	
	if event.ctx.temporary_effects:
		for e in event.ctx.temporary_effects:
			e.owner = event.actor
			if not _passes_scope(e, event):
				continue
			effects_to_run.append({ "effect": e, "owner": event.actor })
	
	if BattleContext.in_battle:
		var battlers := BattleContext.manager.battlers
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

	for entry: Dictionary in effects_to_run:
		var e: Effect = entry.effect
		
		if event.ctx.stop_processing:
			print("[EffectProcessor] processing stopped by", e.name)
			return

		e.on_trigger(event)
		
		if e.single_trigger:
			e.remove_self()


func _sort_effects(a, b) -> int:
	var ea: Effect = a.effect
	var eb: Effect = b.effect
	var pa := int(ea.get_meta("priority")) if ea.has_meta("priority") else 0
	var pb := int(eb.get_meta("priority")) if eb.has_meta("priority") else 0
	return -1 if pa > pb else (1 if pa < pb else 0)

static func _passes_scope(effect: Effect, event: TriggerEvent) -> bool:
	if event.trigger not in effect.listened_triggers():
		return false

	return effect.can_process(event)
