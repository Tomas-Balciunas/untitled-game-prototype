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


func target_selected(c: CharacterInstance):
	if not selected_skill:
		return
	
	selected_skill.set_cost(_owner)
	_owner.set_current_mana(_owner.state.current_mana - selected_skill.final_mp_cost)
	_owner.set_current_sp(_owner.state.current_sp - selected_skill.final_sp_cost)
	var targets = TargetingManager.get_applicable_targets(c, selected_skill.targeting_type)
	for t in targets:
		var ctx := SkillContext.new()
		ctx.skill = selected_skill
		ctx.actively_cast = true
		ctx.source = SkillSource.new(_owner, selected_skill)
		ctx.target = t
		ctx.temporary_effects = selected_skill.effects
		var _ctx := SkillResolver.new().execute(ctx)


func _on_use_skill_pressed() -> void:
	TargetingManager.begin(TargetingManager.Mode.MENU_SKILL)
