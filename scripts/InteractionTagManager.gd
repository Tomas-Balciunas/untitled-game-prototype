extends Node

const AVAILABLE := "available"
const COMPLETED := "completed"

## { character_id => { available => [], completed => [] } }
var interaction_tags: Dictionary = {}

func _ensure_character(id: String) -> void:
	if not interaction_tags.has(id):
		interaction_tags[id] = {
			AVAILABLE: [],
			COMPLETED: []
		}


func _mark_tag_completed(id: String, tag: String) -> void:
	_remove_available_tag_for(id, tag)
	_add_completed_tag_for(id, tag)


func _add_available_tag_for(id: String, tag: String) -> void:
	if _has_available_tag_for(id, tag):
		push_error("trying to add already existing available tag %s for character %s" % [tag, id])
		return
		
	interaction_tags[id][AVAILABLE].append(tag)


func _add_completed_tag_for(id: String, tag: String) -> void:
	if _has_completed_tag_for(id, tag):
		push_error("trying to add already existing completed tag %s for character %s" % [tag, id])
		return
		
	interaction_tags[id][COMPLETED].append(tag)


func _remove_available_tag_for(id: String, tag: String) -> void:
	if not _has_available_tag_for(id, tag):
		push_error("trying to remove non-existent available tag %s for character %s" % [tag, id])
		
	var available_tags: Array = interaction_tags[id][AVAILABLE]
	available_tags.erase(tag)


# technically should never be called
func _remove_completed_tag_for(id: String, tag: String) -> void:
	if not _has_completed_tag_for(id, tag):
		push_error("trying to remove non-existent completed tag %s for character %s" % [tag, id])
		
	var completed_tags: Array = interaction_tags[id][COMPLETED]
	completed_tags.erase(tag)


func _has_available_tag_for(id: String, tag: String) -> bool:
	_ensure_character(id)
	var available_tags: Array = interaction_tags[id][AVAILABLE]
	
	return available_tags.has(tag)


func _has_completed_tag_for(id: String, tag: String) -> bool:
	_ensure_character(id)
	var completed_tags: Array = interaction_tags[id][COMPLETED]
	
	return completed_tags.has(tag)


func _get_tags_for(id: String) -> Dictionary:
	_ensure_character(id)
	
	return interaction_tags[id]

func game_save() -> Dictionary:
	return interaction_tags
	
func game_load(data: Dictionary) -> void:
	interaction_tags = data["interaction_tags"]
