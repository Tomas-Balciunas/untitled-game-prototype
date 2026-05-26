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

	var mult: float = event.target.stats.healing_received / 100.0
	if event.ctx.source is CharacterSource:
		mult *= event.ctx.source.character.stats.healing_done / 100.0
	event.heal = int(round(event.heal * mult))

	event.target.set_current_health(event.target.state.current_health + event.heal)

	BattleTextLines.print_line("%s healed %s for %d" % [event.source.get_source_name(), event.target.resource.name, event.heal])
