extends Node

class_name BasicAttack

var ctx: ActionContext = null
var attacker_slot: FormationSlot = null
var target_slot: FormationSlot = null


func _init(_ctx: ActionContext, attacker: FormationSlot, target: FormationSlot) -> void:
	ctx = _ctx
	attacker_slot = attacker
	target_slot = target
	
	assert(ctx)
	assert(attacker_slot)
	assert(target_slot)


func attack(targeting: TargetingManager.TargetType, targeting_range: TargetingManager.RangeType, attack_rate: int) -> void:
	if !attacker_slot or !target_slot:
		return
	
	var attacker: CharacterInstance = ctx.source.get_actor()
	
	if !attacker is CharacterInstance:
		return
	
	var resolver: DamageResolver = DamageResolver.new(attacker.stats.attack)
	
	if attacker.is_main:
		await attacker_slot.look_at_target(target_slot)
	
	if targeting_range == TargetingManager.RangeType.MELEE:
		await attacker_slot.perform_run_towards_target(target_slot)
		
	for i in range(ctx.attack_rate):
		match targeting_range:
			TargetingManager.RangeType.MELEE:
				await melee(resolver, attacker)
			TargetingManager.RangeType.RANGED:
				await ranged(resolver, targeting)
		
		await BattleContext.wait(0.1)


func melee(resolver: DamageResolver, attacker: CharacterInstance) -> void:
	var orcherstrator: ActionOrchestrator = ActionOrchestrator.new(attacker, ctx, resolver)
	
	await orcherstrator.execute_action(
			func(e: ActionEvent) -> void:
				attacker_slot.perform_attack(e, TargetingManager.RangeType.MELEE, target_slot),
			"basic melee attack",
		)
	
	
func ranged(resolver: DamageResolver, targeting: TargetingManager.TargetType) -> void:
	match targeting:
		TargetingManager.TargetType.BOUNCE:
			var launcher: BounceProjectileLauncher = BounceProjectileLauncher.new(resolver, ctx)
			await launcher.bounce(3, true, false)
		_:
			var launcher: BasicProjectileLauncher = BasicProjectileLauncher.new(resolver, ctx)
			launcher.fire(true)
	
