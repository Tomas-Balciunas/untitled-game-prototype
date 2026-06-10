# Effect double that records trigger order, for EffectRunner pipeline tests.
extends StatusEffect

var tag: String = ""
var log_ref: Array = []
var stage_name: String = ""
var stops: bool = false

func listened_triggers() -> Array:
	return [stage_name]

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	log_ref.append(tag)
	if stops and event.ctx:
		event.ctx.stop_processing = true
