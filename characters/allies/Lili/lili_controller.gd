extends InteractionController

class_name LiliController

const RECRUIT_LILI = "recruit_lili"

func _init() -> void:
	pass

func recruit_lili(_ctx: EventContext, c: CharacterResource) -> void:
	if PartyManager.is_party_full():
		InteractionTagManager._add_available_tag_for(c.id, LiliInteractions.RECRUIT_PARTY_FULL)
		handle(c)
	else:
		PartyManager.add_member(c)
