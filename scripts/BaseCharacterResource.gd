extends Resource

class_name BaseCharacterResource


@export var id: String
@export var name: String = "Unnamed"
@export var portrait: Texture
@export var character_body: PackedScene
@export var interactions: CharacterInteraction
@export var interaction_controller: InteractionController
@export var chatter: CharacterChatter


func _setup_character() -> void:
	if interactions == null:
		return

	var default_tags := interactions._get_default_tags()
	if default_tags.is_empty():
		return

	for tag: String in default_tags:
		if RunState.current.tags._has_completed_tag_for(id, tag):
			continue
		if RunState.current.tags._has_available_tag_for(id, tag):
			continue

		RunState.current.tags._add_available_tag_for(id, tag)
