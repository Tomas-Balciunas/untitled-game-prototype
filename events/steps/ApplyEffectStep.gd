extends EventStep
class_name ApplyEffectStep


@export var effect: Effect
@export var target_member_id: String = ""


func run(_manager: EventManager) -> void:
	if effect == null:
		push_error("ApplyEffectStep has no effect set")
		return

	var receiver := _resolve_receiver()
	if receiver == null:
		push_warning("ApplyEffectStep: no receiver found (party empty?)")
		return

	receiver.apply_effect(effect, CharacterSource.new(receiver))


func _resolve_receiver() -> Character:
	if RunState.current.party.members.is_empty():
		return null

	if target_member_id == "":
		return RunState.current.party.members[0]

	for m: Character in RunState.current.party.members:
		if m.resource.id == target_member_id:
			return m

	push_warning("ApplyEffectStep: party member %s not found" % target_member_id)
	return null
