extends Node


func process_trigger(event: TriggerEvent) -> void:
	var start := Time.get_ticks_usec()

	var effects_to_run: Array[Effect] = []
	
	if event.ctx.temporary_effects:
		for e in event.ctx.temporary_effects:
			e.set_owner(event.actor.character)
			e.set_source(event.actor)
			if not _passes_scope(e, event):
				continue
			effects_to_run.append(e)
	
	if BattleContext.in_battle:
		var battlers := BattleContext.manager.battlers
		for b in battlers:
			for e in b.effects:
				if not _passes_scope(e, event):
					continue
				effects_to_run.append(e)
	else:
		for p in PartyManager.members:
			for e in p.effects:
				if not _passes_scope(e, event):
					continue
				effects_to_run.append(e)

	effects_to_run.sort_custom(_sort_effects)

	for entry: Effect in effects_to_run:
		
		if event.ctx.stop_processing:
			print("[EffectProcessor] processing stopped by", entry.name)
			return

		entry.on_trigger(event)
		
		if entry.single_trigger:
			entry.remove_self()
	
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
