extends BattleAction
class_name BasicAttack


func _init() -> void:
	ends_turn = false
	action_point_cost = 2


func build_context(actor: Character, target: Character) -> ActionContext:
	var weapon: Weapon = actor.equipment["weapon"] if actor.equipment["weapon"] else null
	var targeting: TargetingManager.TargetType = weapon.targeting if weapon else TargetingManager.TargetType.SINGLE
	var attack_rate: int = weapon.attack_rate if weapon else 1
	var targets := TargetingManager.get_applicable_targets(target, targeting)

	var ctx := ActionContext.new()
	ctx.source = CharacterSource.new(actor)
	ctx.set_targets(target, targets)
	ctx.actively_cast = true
	ctx.targeting = targeting
	ctx.attack_rate = attack_rate

	return ctx


func perform(ctx: ActionContext, actor: Character, attacker_slot: FormationSlot, target_slot: FormationSlot, _event: BattleActionEvent) -> void:
	var resolver: DamageResolver = DamageResolver.new(1)

	for i in range(ctx.attack_rate):
		var orcherstrator: ActionOrchestrator = ActionOrchestrator.new(actor, ctx, resolver)

		await orcherstrator.execute_action(
				func(e: ActionEvent) -> void:
					attacker_slot.perform_attack(e, target_slot),
				"basic melee attack",
			)
		
		if ctx.targeting == TargetingManager.TargetType.BOUNCE:
			var launcher: BounceLauncher = BounceLauncher.new(resolver, ctx)
			await launcher.bounce(50)
		elif ctx.targeting == TargetingManager.TargetType.SALVO:
			var launcher: SalvoLauncher = SalvoLauncher.new(resolver, ctx)
			launcher.shrapnel(50)

		await BattleContext.wait(0.2)
