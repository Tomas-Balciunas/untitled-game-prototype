extends Node

signal skill_selected(skill: Skill)

@onready var skill_label: Label = $SkillLabel

var skill: Skill = null

func init(_skill: Skill, _owner: CharacterInstance) -> void:
	skill = _skill
	skill_label.text = "%s: %s" % [skill._get_name(), skill.get_description()]


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not skill:
			push_error("Skill use error: skill is null")
			
			return
		
		skill_selected.emit(skill)
