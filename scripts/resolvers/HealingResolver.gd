extends EffectResolver

class_name HealingResolver


var heal: int = 0
var scaling: float = 0.0


func _init(val: int, scale: float = 0.0) -> void:
	heal = val
	scaling = scale


func execute(ctx: ActionContext) -> ActionContext:
	var base: int = heal
	if scaling > 0.0 and ctx.source is CharacterSource:
		base += int(round(ctx.source.character.stats.divine_power * scaling))

	for target in ctx.targets:
		if not is_target_valid(target):
			continue

		var event := HealTriggerEvent.new(ctx, target, base, scaling)
		run_pipeline(event)

	return ctx


func run_pipeline(event: HealTriggerEvent) -> void:
	EffectRunner.process_trigger(EffectTriggers.ON_HEAL, event)

	EffectRunner.process_trigger(EffectTriggers.ON_RECEIVE_HEAL, event)
	
	
	
	if event.source is CharacterSource:
		var healing_done: float = event.source.character.stats.get_stat_raw(Stats.StatRef.HEALING_DONE)
		var healing_done_mult: float = (1 + absf(healing_done) / 100.0)
		
		if healing_done < 0.0:
			event.heal = event.heal / healing_done_mult
		elif healing_done > 0.0:
			event.heal = event.heal * healing_done_mult
	
	var healing_received: float = event.target.stats.get_stat_raw(Stats.StatRef.HEALING_RECEIVED)
	var healing_received_mult: float = (1 + absf(healing_received) / 100.0)
	
	if healing_received < 0.0:
		event.heal = event.heal / healing_received_mult
	elif healing_received > 0.0:
		event.heal = event.heal * healing_received_mult
	
	if event.ctx.turn:
		event.ctx.turn.healing_done += event.heal

	event.target.set_current_health(event.target.state.current_health + event.heal)

	BattleTextLines.print_line("%s healed %s for %d" % [event.source.get_source_name(), event.target.resource.name, event.heal])
