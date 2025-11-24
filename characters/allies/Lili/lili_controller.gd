extends InteractionController

class_name LiliController

func _init() -> void:
	pass

func recruit_lili(ctx: EventContext, c: CharacterResource) -> void:
	PartyManager.add_member(c)
