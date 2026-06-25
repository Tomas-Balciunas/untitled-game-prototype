@abstract
extends RefCounted
class_name BattleAction

const ON_ACTION_POINT_CONSUME = "on_action_point_consume"

var ends_turn: bool = true
var action_point_cost: int = 0


# Pure cost resolution: base cost run through the actor's cost transformers.
# Mirrors Skill.compute_cost — safe to call for previews (UI / early gate).
func _resolve_ap_cost(actor: Character) -> int:
	var cost: int = action_point_cost

	if actor:
		for e: Effect in actor.effects:
			if e._modifies_action_point_cost():
				cost = e.modify_action_point_cost(self, cost)

	return max(0, cost)


func peek_ap_cost(actor: Character) -> int:
	return _resolve_ap_cost(actor)


func can_afford(actor: Character, turn: TurnState) -> bool:
	if turn == null:
		return false

	return turn.action_points >= _resolve_ap_cost(actor)

func needs_target() -> bool:
	return true

@abstract
func build_context(actor: Character, target: Character) -> ActionContext

@abstract
func perform(ctx: ActionContext, actor: Character, attacker_slot: FormationSlot, target_slot: FormationSlot, event: BattleActionEvent) -> void

func execute(actor: Character, target: Character, attacker_slot: FormationSlot, target_slot: FormationSlot) -> BattleActionEvent:
	if actor == null or (needs_target() and (target == null or attacker_slot == null or target_slot == null)):
		var aborted: BattleActionEvent = BattleActionEvent.new()
		aborted.from_action(self)
		aborted.ends_turn = false

		return aborted

	var ctx: ActionContext = build_context(actor, target)
	var event: BattleActionEvent = consume_action_points(ctx)
	
	if not event.consumed:
		return event

	await perform(ctx, actor, attacker_slot, target_slot, event)

	return event

func consume_action_points(ctx: ActionContext) -> BattleActionEvent:
	var event: BattleActionEvent = BattleActionEvent.new()
	event.from_action(self)
	event.from_context(ctx)

	if ctx.turn == null:
		event.ends_turn = true

		return event

	event.ap_cost = _resolve_ap_cost(ctx.source.get_actor())

	if ctx.turn.action_points < event.ap_cost:
		NotificationBus.notification_requested.emit("Not enough action points!")
		event.ends_turn = false

		return event

	ctx.turn.subtract_action_points(event.ap_cost)
	EffectRunner.process_trigger(ON_ACTION_POINT_CONSUME, event)
	event.consumed = true

	return event
