extends Node

signal skill_selected(skill: Skill)

@onready var skill_label: Label = $SkillLabel

var skill: Skill = null

func init(_skill: Skill, _owner: CharacterInstance) -> void:
	var costs: SkillCost = _skill.compute_cost(_owner)
	skill = _skill
	skill_label.text = "%s: %s MP/%s SP" % [skill._get_name(), costs.get_mana_cost(), costs.get_sp_cost()]


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not skill:
			push_error("Skill use error: skill is null")
			
			return
		
		skill_selected.emit(skill)
