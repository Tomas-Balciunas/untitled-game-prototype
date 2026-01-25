extends Node

@onready var skills_container := $Skills
@onready var use_skill: Button = $UseSkill
const SKILL_BOX = preload("uid://bpkmimsr5asu2")
var _owner: CharacterInstance = null
var selected_skill: Skill = null


func bind_character(character: CharacterInstance) -> void:
	use_skill.visible = false
	clear_skills()
	_owner = character
	
	TargetingManager.menu_skill_target_selected.connect(target_selected)
	
	if character.learnt_skills.size() > 0:
		for skill: Skill in character.learnt_skills:
			add_skill(skill)

func clear_skills() -> void:
	for child in skills_container.get_children():
		child.queue_free()

func add_skill(skill: Skill) -> void:
	if not _owner:
		push_warning("Error: Skill UI unable to add skill")
		
		return
	
	var skill_box: HBoxContainer = SKILL_BOX.instantiate()
	skills_container.add_child(skill_box)
	skill_box.init(skill, _owner)
	skill_box.skill_selected.connect(_on_skill_selected)


func _on_skill_selected(skill: Skill) -> void:
	if not skill.can_select(_owner):
		use_skill.visible = false
		selected_skill = null
		
		return
	
	selected_skill = skill
	use_skill.visible = true


func target_selected(t: CharacterInstance) -> void:
	if not selected_skill:
		return
	
	var targets := TargetingManager.get_applicable_targets(t, selected_skill.targeting_type)
	var ctx: ActionContext = ActionContext.new()
	ctx.set_targets(t, targets)
	ctx.source = SkillSource.new(_owner, selected_skill)
	
	SkillResolver.new(selected_skill).execute(ctx)


func _on_use_skill_pressed() -> void:
	TargetingManager.begin(TargetingManager.Mode.MENU_SKILL)
