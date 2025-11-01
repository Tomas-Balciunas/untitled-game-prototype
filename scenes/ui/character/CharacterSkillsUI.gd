extends Node

@onready var skills_container := $Skills
const SkillLabel = preload("res://scenes/ui/character/SkillLabel.tscn")

func bind_character(character: CharacterInstance) -> void:
	clear_skills()
	if character.learnt_skills.size() > 0:
		for skill in character.learnt_skills:
			add_skill(skill)

func clear_skills() -> void:
	for child in skills_container.get_children():
		child.queue_free()

func add_skill(skill: Skill) -> void:
	var label := SkillLabel.instantiate()
	label.text = "%s: %s" % [skill._get_name(), skill.get_description()]
	skills_container.add_child(label)
