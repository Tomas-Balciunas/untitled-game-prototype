@abstract
extends RefCounted

class_name EffectResolver

@abstract
func execute(_ctx: ActionContext) -> ActionContext

func is_target_valid(target: Variant) -> bool:
	if !target or !target is CharacterInstance:
		push_error("Provided target is not character")
		
		return false
	
	return true
