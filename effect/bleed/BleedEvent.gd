extends TriggerEvent

class_name BleedEvent

var stack_snapshot: int = 0
var stack_loss: float = 0.5
var damage_per_stack: float = 0.2

func from_bleed(bleed: Bleed) -> void:
	stack_snapshot = bleed.stacks
	stack_loss = bleed.stack_loss
	damage_per_stack = bleed.damage_per_stack
