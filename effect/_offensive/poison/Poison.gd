extends StatusEffect
class_name PoisonEffect

@export var damage_per_turn: int = 5
var stacks: int = 1
var _remaining: int = 0
var _should_refresh_duration: bool = true


func _init() -> void:
	battle_only = false


func _is_stackable() -> bool:
	return true


func listened_triggers() -> Array:
	return []


func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false


func on_apply() -> void:
	_remaining = duration_turns
	# TODO tidy this up
	#for effect in owner.effects:
		#if effect is PoisonEffect:
			#_should_append = false
			#effect.stacks += 1
			#
			#if _should_refresh_duration:
				#effect._remaining = duration_turns
			
	BattleTextLines.print_line("Poison applied to %s for %d turns" % [owner.resource.name, duration_turns])


func _get_name() -> String:
	return "Poison"


func get_description() -> String:
	return "Deals %s damage per turn, %s turns remaining" % [damage_per_turn * stacks, _remaining]


func tick(ctx: ActionContext) -> void:
	if owner == null:
		push_error("PoisonEffect: Owner is null during on_turn_end tick.")
		return
	
	if owner.is_dead:
		return
	
	var tick_ctx: ActionContext = ActionContext.new()
	tick_ctx.source = source
	tick_ctx.set_targets(owner)
	tick_ctx.options = tick_ctx.options.duplicate() if tick_ctx.options else {}
	var resolver = DamageResolver.new((damage_per_turn * stacks) * ctx.tick_power)
	
	if BattleContext.in_battle:
		var slot = BattleContext.enemy_formation.get_slot_for(owner)
		var orchestrator = ActionOrchestrator.new(owner, tick_ctx, resolver)
		orchestrator.execute_action(
			func (e: ActionEvent) -> void:
				slot.body_instance.play_poison(e)
		)
	else:
		resolver.execute(tick_ctx)

	if ctx.should_tick_consume_duration:
		_remaining -= 1
	
	#print("Poison tick: %s takes %d from %s — remaining %d" % [owner.resource.name, damage_per_turn * ctx.tick_power, tick_ctx.source.get_source_name(), _remaining])

	if _remaining <= 0:
		print("Poison expired on %s" % owner.resource.name)
		on_expire()
