extends EventStep
class_name LearnSkillStep


@export var skill: Skill
@export var target_member_id: String = ""


func run(_manager: EventManager) -> void:
	if skill == null:
		push_error("LearnSkillStep has no skill set")
		return

	var receiver := _resolve_receiver()
	if receiver == null:
		push_warning("LearnSkillStep: no receiver found (party empty?)")
		return

	for known: Skill in receiver.learnt_skills:
		if known.id == skill.id:
			return

	receiver.learnt_skills.append(skill)
	NotificationBus.notification_requested.emit("%s learned %s" % [receiver.resource.name, skill.name])


func _resolve_receiver() -> Character:
	if PartyManager.members.is_empty():
		return null

	if target_member_id == "":
		return PartyManager.members[0]

	for m: Character in PartyManager.members:
		if m.resource.id == target_member_id:
			return m

	push_warning("LearnSkillStep: party member %s not found" % target_member_id)
	return null
