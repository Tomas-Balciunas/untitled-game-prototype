extends EventStep
class_name RecruitCharacterStep


const PARTY_FULL := "party_full"
const RECRUITED := "recruited"


@export var party_full_tag: String = ""


func run(manager: EventManager) -> void:
	if manager.subject == null:
		push_warning("RecruitCharacterStep has no subject on EventManager")
		return

	var res := manager.subject as CharacterResource
	if res == null:
		push_error("RecruitCharacterStep requires a CharacterResource subject, got %s" % manager.subject)
		return

	if PartyManager.is_party_full():
		manager.choices.append(PARTY_FULL)
		if party_full_tag != "":
			MarkTagStep.self_available(party_full_tag).run(manager)
		return

	PartyManager.add_member(res)
	manager.choices.append(RECRUITED)


static func with_party_full_tag(p_tag: String) -> RecruitCharacterStep:
	var s := RecruitCharacterStep.new()
	s.party_full_tag = p_tag
	return s
