extends EventStep
class_name MarkTagStep


enum State { AVAILABLE, COMPLETED }
enum Target { SELF, OTHER }


@export var state: State = State.COMPLETED
@export var target: Target = Target.SELF
@export var target_id: String = ""
@export var tag: String = ""


func run(manager: EventManager) -> void:
	var id := _resolve_id(manager)
	if id == "":
		return

	match state:
		State.COMPLETED:
			if RunState.current.tags._has_completed_tag_for(id, tag):
				return
			RunState.current.tags._mark_tag_completed(id, tag)
		State.AVAILABLE:
			if RunState.current.tags._has_completed_tag_for(id, tag):
				RunState.current.tags._remove_completed_tag_for(id, tag)
			if RunState.current.tags._has_available_tag_for(id, tag):
				return
			RunState.current.tags._add_available_tag_for(id, tag)


func _resolve_id(manager: EventManager) -> String:
	match target:
		Target.SELF:
			if manager.subject == null:
				push_warning("MarkTagStep targets SELF but EventManager has no subject")
				return ""
			return manager.subject.id
		Target.OTHER:
			if target_id == "":
				push_error("MarkTagStep targets OTHER but target_id is empty")
				return ""
			return target_id

	return ""
