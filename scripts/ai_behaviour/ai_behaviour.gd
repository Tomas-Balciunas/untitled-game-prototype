extends Resource

class_name AiBehaviour

@export_category('Intentions')
@export var basic_attack: float = 1.0
@export var guard: float = 0.33
@export var damage: float = 0.33
@export var harm: float = 0.33
@export var sustain: float = 0.33
@export var support: float = 0.33

var skill_intention_map = {
	Skill.SkillCategory.DAMAGE: damage,
	Skill.SkillCategory.HARM: harm,
	Skill.SkillCategory.SUSTAIN: sustain,
	Skill.SkillCategory.SUPPORT: support
}

func choose_action(actor: Character, data_pool) -> Array:
	var skill_intention_roll: float = randf()
	var skill_intentions: Array[Skill.SkillCategory] = []
	
	for intention in skill_intention_map:
		if skill_intention_map[intention] <= skill_intention_roll:
			skill_intentions.append(intention)
	
	var candidates = []
	
	candidates.append([[data_pool.pick_random()[0], BasicAttack.new()], basic_attack])
	candidates.append([[null, GuardAction.new()], guard])
	
	for category in skill_intentions:
		candidates.append_array(get_candidates_for_skill_category(actor, data_pool, category))
	
	var values = []
	var weights = []
	
	for candidate in candidates:
		values.append(candidate[0])
		weights.append(candidate[1])
	
	return get_weighted_random_result(values, weights)
	
	#
	#var total: float = offense + defense
	#var rand_range: float = randf_range(0.0, total)
	#
	#var choices: Array = [
		#[OFFENSIVE_INTENTION, offense],
		#[DEFENSIVE_INTENTION, defense],
	#]
	#
	#var choice: String = OFFENSIVE_INTENTION
	#var cumulative: float = 0.0
	#
	#for val: Array in choices:
		#cumulative += val[1]
		#if rand_range <= cumulative:
			#choice = val[0]
			#break
	#
	#match choice:
		#OFFENSIVE_INTENTION:
			#return pick_offensive_action(actor, scanner)
		#DEFENSIVE_INTENTION:
			#return pick_defensive_action(actor, scanner)
		#_:
			#return [scanner.party.pick_random()[0], BasicAttack.new()]


#func pick_offensive_action(actor: Character, scanner: BattleStateScanner):
	#if actor.learnt_skills.is_empty():
		#return [scanner.party.pick_random()[0], BasicAttack.new()]
	#
	#var offensive_choice = get_weighted_random_result(["basic", "skill"], [0.7, 0.5])
	#
	#match offensive_choice:
		#"basic":
			#return [scanner.party.pick_random()[0], BasicAttack.new()]
		#"skill":
			#return [scanner.party.pick_random()[0], SkillAction.new(actor.learnt_skills.pick_random())]
	#
	#return [scanner.party.pick_random()[0], BasicAttack.new()]


#func pick_defensive_action(actor: Character, scanner: BattleStateScanner):
	#var candidates = []
	#for category in [Skill.SkillCategory.SUPPORT, Skill.SkillCategory.SUSTAIN]:
		#candidates.append_array(get_candidates_for_skill_category(actor, scanner, category))
	#
	#if candidates.is_empty():
		#var rand = randf()
		#
		#if rand > 0.5:
			#return [null, GuardAction.new()]
		#else:
			#return pick_offensive_action(actor, scanner)
		#
	#
	#var values = []
	#var weights = []
	#
	#for candidate in candidates:
		#values.append(candidate[0])
		#weights.append(candidate[1])
	#
	#return get_weighted_random_result(values, weights)
	
func get_candidates_for_skill_category(actor: Character, data_pool, category: Skill.SkillCategory):
	var candidates = []
	
	for skill in actor.learnt_skills:
		if skill.get_category() != category:
			continue
		
		if skill.can_use(actor) == false:
			continue

		for battler_data in data_pool:
			var battler = battler_data[0]
			var battler_tags = battler_data[1]
			
			if !skill.get_conditions().is_empty() and !matches_all_conditions(skill.get_conditions(), battler_tags):
				continue
			
			candidates.append([[battler, SkillAction.new(skill)], 0.5 + (matching_tags(skill.tags, battler_tags) * 0.5)])
			
	return candidates
	

func get_random_target(pool: Array[Character]) -> Character:
	return pool.pick_random()

func get_weighted_random_result(values: Array, weights: Array):
	var container: Array = []
	
	for i in len(values):
		container.append([values[i], weights[i]])
	
	var total: float = weights.reduce(func (accum, number): return accum + number, 0)
	var rand_range: float = randf_range(0.0, total)
	
	var choice = values[0]
	var cumulative: float = 0.0
	
	for val: Array in container:
		cumulative += val[1]
		if rand_range <= cumulative:
			return val[0]



func fallback_action():
	pass

func matching_tags(skill_tags, battler_tags) -> int:
	var amt: int = 0
	
	for tag in skill_tags:
		if battler_tags.has(tag):
			amt += 1
	
	return amt
		
func matches_all_conditions(conditions, tags) -> bool:
	for condition in conditions:
		if !tags.has(condition):
			return false
	
	return true
