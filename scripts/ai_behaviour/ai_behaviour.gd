extends Resource

class_name AiBehaviour

@export_category('Intentions')
@export var basic_attack: float = 1.0
@export var guard: float = 0.2
@export var skill: float = 0.7

@export_category('Skill intentions')
@export var damage: float = 0.33
@export var harm: float = 0.33
@export var sustain: float = 0.33
@export var support: float = 0.33

var skill_intention_map: Dictionary = {
	Skill.SkillCategory.DAMAGE: damage,
	Skill.SkillCategory.HARM: harm,
	Skill.SkillCategory.SUSTAIN: sustain,
	Skill.SkillCategory.SUPPORT: support
}

func choose_action(scanner: BattleStateScanner, event: TurnStateEvent) -> AiActionCandidate:
	var base_action: String = get_weighted_random_result(["1", "2", "3"], [basic_attack, guard, skill])
	
	## TODO need to figure out self targeting restrictions
	match base_action:
		"1":
			return choose_basic_attack(event, scanner)
		"2":
			return AiActionCandidate.new(GuardAction.new())
		"3":
			return choose_skill(scanner, event)
		_:
			return null
	

func choose_skill(scanner: BattleStateScanner, event: TurnStateEvent) -> AiActionCandidate:
	var allowed_categories: Array[Skill.SkillCategory] = event.turn_options.allowed_skill_categories
	
	if allowed_categories.is_empty():
		return fallback_action(event, scanner)
	
	var candidates: Array[AiActionCandidate] = []
	
	for category: Skill.SkillCategory in event.turn_options.allowed_skill_categories:
		var base_weight: float = skill_intention_map[category]
		candidates.append_array(get_candidates_for_skill_category(event, scanner, category, base_weight))
	
	var values: Array[AiActionCandidate] = []
	var weights: Array[float] = []
	
	for candidate in candidates:
		values.append(candidate)
		weights.append(candidate.target_weight)
	
	if candidates.is_empty():
		return fallback_action(event, scanner)
	
	return get_weighted_random_result(values, weights)
	
func get_candidates_for_skill_category(
		event: TurnStateEvent,
		scanner: BattleStateScanner,
		category: Skill.SkillCategory,
		base_weight: float
	) -> Array[AiActionCandidate]:
	var candidates: Array[AiActionCandidate] = []
	
	for skill in event.turn_options.actor.learnt_skills:
		if skill.get_category() != category:
			continue
		
		if skill.can_use(event.turn_options.actor) == false:
			continue
		
		var is_offensive: bool = skill.is_skill_offensive()
		
		var pool: Array[BattleScanEntry] = resolve_pool(event, scanner, is_offensive)

		for entry in pool:
			if !skill.get_conditions().is_empty() and !matches_all_conditions(skill.get_conditions(), entry.tags):
				continue
			
			var computed_aggro: float = base_weight + (float(matching_tags(skill.tags, entry.tags)) * 0.5)
			var final_aggro: float = StatCalculator.apply_percentage_stat_multiplier(Stats.StatRef.AGGRAVATION, entry.battler, computed_aggro)
			
			candidates.append(AiActionCandidate.new(SkillAction.new(skill),entry.battler, final_aggro))
			
	return candidates

func choose_basic_attack(event: TurnStateEvent, scanner: BattleStateScanner,) -> AiActionCandidate:
	var candidates: Array[AiActionCandidate] = get_candidates_for_basic_attack(event, scanner)
	
	if candidates.is_empty():
		push_error("Basic attack couldn't find targets!")
		
		return AiActionCandidate.new(GuardAction.new())
	
	var values: Array[AiActionCandidate] = []
	var weights: Array[float] = []
	
	for candidate in candidates:
		values.append(candidate)
		weights.append(candidate.target_weight)
	
	return get_weighted_random_result(values, weights)

func get_candidates_for_basic_attack(
		event: TurnStateEvent,
		scanner: BattleStateScanner,
	) -> Array[AiActionCandidate]:
	var candidates: Array[AiActionCandidate] = []
	var pool: Array[BattleScanEntry] = resolve_pool(event, scanner, true)
	
	for entry in pool:
		var final_aggro: float = StatCalculator.apply_percentage_stat_multiplier(Stats.StatRef.AGGRAVATION, entry.battler, basic_attack)
		
		candidates.append(AiActionCandidate.new(BasicAttack.new(), entry.battler, final_aggro))
	
	return candidates

func resolve_pool(event: TurnStateEvent, scanner: BattleStateScanner, is_offensive: bool) -> Array[BattleScanEntry]:
	if event.turn_options.forced_targets.is_empty() == false:
		return event.turn_options.forced_targets
	
	match event.turn_options.allowed_sides:
		TurnOptions.AllowedSides.DEFAULT:
			if is_offensive:
				return scanner.enemies
			else:
				return scanner.allies
		TurnOptions.AllowedSides.BOTH:
			return scanner.enemies + scanner.allies
		TurnOptions.AllowedSides.INVERTED:
			if is_offensive:
				return scanner.allies
			else:
				return scanner.enemies
		_:
			push_error("Error in resolving character pool")
			return []

func get_random_target(pool: Array[Character]) -> Character:
	return pool.pick_random()

func get_weighted_random_result(values: Array, weights: Array) -> Variant:
	var container: Array = []
	
	for i in len(values):
		container.append([values[i], weights[i]])
	
	var total: float = weights.reduce(func (accum, number): return accum + number, 0)
	var rand_range: float = randf_range(0.0, total)
	
	var choice: Variant = values[0]
	var cumulative: float = 0.0
	
	for val: Array in container:
		cumulative += val[1]
		if rand_range <= cumulative:
			return val[0]
	
	return null


func fallback_action(event: TurnStateEvent, scanner: BattleStateScanner) -> AiActionCandidate:
	var val: float = randf()
	if val > 0.2:
		return choose_basic_attack(event, scanner)
	else:
		return AiActionCandidate.new(GuardAction.new())

func matching_tags(skill_tags: Array[String], battler_tags: Array[String]) -> int:
	var amt: int = 0
	
	for tag: String in skill_tags:
		if battler_tags.has(tag):
			amt += 1
	
	return amt
		
func matches_all_conditions(conditions: Array[String], tags: Array[String]) -> bool:
	for condition in conditions:
		if !tags.has(condition):
			return false
	
	return true
