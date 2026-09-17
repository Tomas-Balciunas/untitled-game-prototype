extends AiBehaviour

class_name SkellyPriestAi

var skill_list: Array[Skill] = []

func choose_action(scanner: BattleStateScanner, event: TurnStateEvent) -> AiActionCandidate:
	if skill_list.is_empty():
		var skill1: AttackSkill = AttackSkill.new()
		skill1.name = "Smite"
		skill1.attack_scale = 1.0
		skill1.category = Skill.SkillCategory.DAMAGE
		
		var skill2: CastSkill = CastSkill.new()
		skill2.effect = AttackBuffOnSkillUse.new()
		skill2.name = "Att buff"
		skill2.category = Skill.SkillCategory.SUPPORT
		
		skill_list.append(skill1)
		skill_list.append(skill2)
	
	var skill: Skill = skill_list.pop_front()
	skill_list.append(skill)
	var skill_action = SkillAction.new(skill)
	
	var pool = resolve_pool(event, scanner, skill.is_skill_offensive())
	var candidates = get_candidates_for_skill_category([skill], event, scanner, skill.get_category(), intention_for(skill.get_category()))
	
	var values: Array[AiActionCandidate] = []
	var weights: Array[float] = []
	
	for candidate in candidates:
		values.append(candidate)
		weights.append(candidate.target_weight)
	
	if candidates.is_empty():
		return fallback_action(event, scanner)
	
	return get_weighted_random_result(values, weights)
