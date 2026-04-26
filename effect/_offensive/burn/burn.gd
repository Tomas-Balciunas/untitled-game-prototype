extends StatusEffect

class_name BurnEffect

@export var damage_per_turn: int = 4

var _remaining: int


func _init() -> void:
	battle_only = false


func listened_triggers() -> Array:
	return []


func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false


func on_apply() -> void:
	_remaining = duration_turns
	BattleTextLines.print_line("%s is burning!" % owner.resource.name)


func tick(ctx: ActionContext) -> void:
	if owner == null or owner.is_dead:
		return

	var tick_ctx := ActionContext.new()
	tick_ctx.source = source
	tick_ctx.set_targets(owner)
	var resolver := DamageResolver.new(damage_per_turn * ctx.tick_power)

	if BattleContext.in_battle:
		resolver.execute(tick_ctx)
	else:
		resolver.execute(tick_ctx)

	if ctx.should_tick_consume_duration:
		_remaining -= 1

	if _remaining <= 0:
		BattleTextLines.print_line("Burn faded on %s" % owner.resource.name)
		on_expire()
