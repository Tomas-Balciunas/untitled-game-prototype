extends Node


func process_trigger(event: TriggerEvent) -> void:
	var start := Time.get_ticks_usec()

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
			for e in b.get_all_effects():
				if not _passes_scope(e, event):
					continue
				effects_to_run.append({ "effect": e, "owner": b })
	else:
		for p in PartyManager.members:
			for e in p.get_all_effects():
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
	var elapsed_usec := Time.get_ticks_usec() - start
	print("Took %dus (%.3f ms)" % [elapsed_usec, elapsed_usec / 1000.0])

func _sort_effects(a: Dictionary, b: Dictionary) -> int:
	var ea: Effect = a.effect
	var eb: Effect = b.effect
	return ea.priority > eb.priority

static func _passes_scope(effect: Effect, event: TriggerEvent) -> bool:
	if event.trigger not in effect.listened_triggers():
		return false

	return effect.can_process(event)
