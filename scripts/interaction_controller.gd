@abstract
extends Resource

class_name InteractionController

@abstract
func handle(_c: BaseCharacterResource) -> void

@abstract
func to_dict() -> Dictionary

@abstract
func from_dict(saved_flags: Dictionary) -> void
