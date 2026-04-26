extends DebuffEffect

class_name BleedOnHit

@export var damage_per_turn: int = 6


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event.actor.get_actor() == owner and event.ctx.actively_cast


func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var bleed := BleedEffect.new()
	bleed.duration_turns = duration_turns
	bleed.damage_per_turn = damage_per_turn
	bleed.source = event.actor

	var app := ActionContext.new()
	app.source = event.actor
	app.set_targets(event.target)

	event.ctx.additional_procs.append({
		"resolver": EffectApplicationResolver.new(bleed),
		"ctx": app
	})


func get_description() -> String:
	return "Applies bleed on hit for %d turns dealing %d damage per turn" % [duration_turns, damage_per_turn]
