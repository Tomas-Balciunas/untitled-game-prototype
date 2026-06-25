extends BattleAction
class_name FleeAction


var success_rate: float = 0.5

func _init() -> void:
	action_point_cost = 2

func needs_target() -> bool:
	return false

func build_context(actor: Character, _target: Character) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(actor)
	ctx.actively_cast = true

	return ctx

func perform(_ctx: ActionContext, _actor: Character, _attacker_slot: FormationSlot, _target_slot: FormationSlot, event: BattleActionEvent) -> void:
	var success := randf() < success_rate
	
	if success:
		event.ends_battle = true
		event.end_reason = "flee"
		NotificationBus.notification_requested.emit("Party flees!")
	else:
		BattleTextLines.print_line("Party fails to flee")
