extends StatusEffect
class_name PoisonEffect


const ON_POISON_DAMAGE = "on_poison_damage"

@export var damage_per_turn: int = 5

func _init() -> void:
	battle_only = false
	expires_after_battle = false
	expire_phase = TurnPhase.TURN_END

func _is_stackable() -> bool:
	return true

func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END, EffectTriggers.ON_MOVEMENT]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_actor(event)

func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	trigger()

func trigger(power: float = 1.0) -> void:
	_deal_damage(power)


func _deal_damage(power: float) -> void:
	var poison_event: PoisonEvent = PoisonEvent.new()
	poison_event.from_poison(self)
	poison_event.power = power
	poison_event.source = source
	poison_event.target = owner
	poison_event.ctx = ActionContext.new()
	poison_event.ctx.source = source

	EffectRunner.process_trigger(ON_POISON_DAMAGE, poison_event)

	var amount: int = roundi(poison_event.damage_per_turn * poison_event.power)
	if amount <= 0:
		return

	var tick_ctx: ActionContext = ActionContext.new()
	tick_ctx.source = source
	tick_ctx.set_targets(owner)
	var resolver = DamageResolver.new(amount)

	#TODO: play for allies too
	if BattleContext.in_battle:
		var slot = BattleContext.enemy_formation.get_slot_for(owner)
		if slot:
			var orchestrator = ActionOrchestrator.new(owner, tick_ctx, resolver)
			orchestrator.execute_action(
				func (e: ActionEvent) -> void:
					slot.body_instance.play_poison(e),
				"poison"
			)
		else:
			resolver.execute(tick_ctx)
	else:
		resolver.execute(tick_ctx)

func on_apply() -> void:
	BattleTextLines.print_line("Poison applied to %s for %d turns" % [owner.resource.name, duration_turns])

func _get_name() -> String:
	return "Poison"

func get_description() -> String:
	return "Deals %s damage per turn, %s turns remaining" % [damage_per_turn, remaining_turns]

func get_display_turns() -> int:
	return remaining_turns

func game_save() -> Dictionary:
	var data := super.game_save()
	return data

func game_load(data: Dictionary) -> void:
	super.game_load(data)
