# Minimal concrete Effect for exercising the base-class lifecycle.
extends StatusEffect

@export var probe_value: int = 0

func listened_triggers() -> Array:
	return []

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true
