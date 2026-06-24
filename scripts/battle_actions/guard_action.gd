extends BattleAction
class_name GuardAction


func _init() -> void:
	action_point_cost = 2

func needs_target() -> bool:
	return false


func build_context(actor: Character, _target: Character) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(actor)
	ctx.actively_cast = true

	return ctx


func perform(_ctx: ActionContext, actor: Character, _attacker_slot: FormationSlot, _target_slot: FormationSlot) -> void:
	var guard_effect: GuardEffect = GuardEffect.new()
	guard_effect.native = false
	guard_effect.show_in_status = true
	guard_effect.expires_after_battle = true
	guard_effect.battle_only = true
	guard_effect.duration_turns = 1
	guard_effect.expire_phase = Effect.TurnPhase.TURN_START
	
	actor.apply_effect(guard_effect, CharacterSource.new(actor))
