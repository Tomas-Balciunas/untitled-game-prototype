extends Node


func process_trigger(stage: String, event: TriggerEvent) -> void:
	var start := Time.get_ticks_usec()

	var ctx: ActionContext = event.ctx
	var effects_to_run: Array[Effect] = []
	
	if ctx.temporary_effects:
		for e in ctx.temporary_effects:
			e.set_owner(ctx.source.get_actor())
			e.set_source(ctx.source)
			if not _passes_scope(e, stage, event):
				continue
			effects_to_run.append(e)
	
	if BattleContext.in_battle:
		var battlers := BattleContext.manager.battlers
		for b in battlers:
			for e in b.effects:
				if not _passes_scope(e, stage, event):
					continue
				effects_to_run.append(e)
	else:
		for p in PartyManager.members:
			for e in p.effects:
				if not _passes_scope(e, stage, event):
					continue
				effects_to_run.append(e)

	#effects_to_run.sort_custom(_sort_effects)

	for entry: Effect in effects_to_run:
		
		if ctx.stop_processing:
			print("[EffectProcessor] processing stopped by", entry.name)
			return

		entry.on_trigger(stage, event)
		
		if entry.single_trigger:
			entry.remove_self()
	
	var elapsed_usec := Time.get_ticks_usec() - start
	print("Took %dus (%.3f ms)" % [elapsed_usec, elapsed_usec / 1000.0])

func _sort_effects(a: Dictionary, b: Dictionary) -> int:
	var ea: Effect = a.effect
	var eb: Effect = b.effect
	return ea.priority > eb.priority

static func _passes_scope(effect: Effect, stage: String, event: TriggerEvent) -> bool:
	if !BattleContext.in_battle and effect.battle_only:
		return false
	
	if stage not in effect.listened_triggers():
		return false

	return effect.can_process(stage, event)
