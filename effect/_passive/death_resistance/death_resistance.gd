extends BuffEffect
class_name DeathResistance

@export var stacks: int = 1

func _init() -> void:
	super()
	native = false
	battle_only = true
	expire_phase = TurnPhase.NONE

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DEATH]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_target(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	if stacks <= 0:
		on_expire()
	
	owner.is_dead = false
	owner.set_current_health(roundi(owner.stats.get_stat(Stats.StatRef.HEALTH) * 0.5))
	stacks -= 1
	
	if stacks <= 0:
		on_expire()

func get_display_stacks() -> int:
	return stacks

func _get_name() -> String:
	return "Death Resistance"

func get_priority(_stage: String = "") -> int:
	return 9999
