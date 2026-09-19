extends PassiveEffect

class_name QueueTest

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return owner_is_actor(_event) and _event.ctx.actively_cast == true

func on_trigger(_stage: String, _ctx: TriggerEvent) -> void:
	var resolver: DamageResolver = DamageResolver.new(10)
	var context: ActionContext = ActionContext.new()
	context.set_targets((_ctx as DamageInstance).target)
	context.actively_cast = false
	context.source = _ctx.source
	
	var queue_entry: BattleQueueEntry = BattleQueueEntry.new(resolver, context, _ctx.source.get_actor())
	
	_ctx.ctx.immediate_procs.append(queue_entry)
	_ctx.ctx.deferred_procs.append(queue_entry)
