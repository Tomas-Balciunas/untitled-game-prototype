extends BattleAction
class_name GuardAction


func needs_target() -> bool:
	return false


func build_context(actor: Character, _target: Character) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(actor)

	return ctx


func perform(_ctx: ActionContext, _actor: Character, _attacker_slot: FormationSlot, _target_slot: FormationSlot) -> void:
	pass
