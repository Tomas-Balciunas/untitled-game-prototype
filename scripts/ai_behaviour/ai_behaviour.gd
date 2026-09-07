extends Resource

class_name AiBehaviour

@export_category('Intentions')
@export var basic_attack: float = 1.0
@export var guard: float = 0.33
@export var skill: float = 0.5

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

func choose_action(actor: Character, scanner: BattleStateScanner, event: TurnStateEvent) -> Array:
	var base_action: String = get_weighted_random_result(["1", "2", "3"], [basic_attack, guard, skill])
	
	match base_action:
		"1":
			var pool = resolve_pool(event, scanner, Skill.SkillCategory.DAMAGE)
			return [pool.pick_random()[0], BasicAttack.new()]
		"2":
			return [null, GuardAction.new()]
		"3":
			return choose_skill(scanner, event)
		_:
			return []
	

func choose_skill(scanner: BattleStateScanner, event: TurnStateEvent) -> Array:
	var allowed_categories = event.turn_options.allowed_skill_categories
	if allowed_categories.is_empty():
		return fallback_action(event, scanner)
	
	
	var candidates = []
	
	for category: Skill.SkillCategory in event.turn_options.allowed_skill_categories:
		var base_weight: float = skill_intention_map[category]
		candidates.append_array(get_candidates_for_skill_category(event, scanner, category, base_weight))
	
	var values = []
	var weights = []
	
	for candidate in candidates:
		values.append(candidate[0])
		weights.append(candidate[1])
	
	if candidates.is_empty():
		return fallback_action(event, scanner)
	
	return get_weighted_random_result(values, weights)
	
func get_candidates_for_skill_category(
		event: TurnStateEvent,
		scanner: BattleStateScanner,
		category: Skill.SkillCategory,
		base_weight: float
	) -> Array:
	var candidates = []
	
	for skill in event.turn_options.actor.learnt_skills:
		if skill.get_category() != category:
			continue
		
		if skill.can_use(event.turn_options.actor) == false:
			continue
		
		var pool = resolve_pool(event, scanner, category)

		for battler_data in pool:
			var battler = battler_data[0]
			var battler_tags = battler_data[1]
			
			if !skill.get_conditions().is_empty() and !matches_all_conditions(skill.get_conditions(), battler_tags):
				continue
			
			candidates.append([[battler, SkillAction.new(skill)], base_weight + (matching_tags(skill.tags, battler_tags) * 0.5)])
			
	return candidates
	
func resolve_pool(event: TurnStateEvent, scanner: BattleStateScanner, category: Skill.SkillCategory) -> Array:
	if event.turn_options.forced_targets.is_empty() == false:
		return event.turn_options.forced_targets
	
	match event.turn_options.allowed_sides:
		TurnOptions.AllowedSides.DEFAULT:
			if category in [Skill.SkillCategory.DAMAGE, Skill.SkillCategory.HARM]:
				return scanner.enemies
			else:
				return scanner.allies
		TurnOptions.AllowedSides.BOTH:
			return scanner.enemies + scanner.allies
		TurnOptions.AllowedSides.INVERTED:
			if category in [Skill.SkillCategory.DAMAGE, Skill.SkillCategory.HARM]:
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
	
	var choice = values[0]
	var cumulative: float = 0.0
	
	for val: Array in container:
		cumulative += val[1]
		if rand_range <= cumulative:
			return val[0]
	
	return null



func fallback_action(event: TurnStateEvent, scanner: BattleStateScanner) -> Array:
	var val = randf()
	if val > 0.3:
		var pool = resolve_pool(event, scanner, Skill.SkillCategory.DAMAGE)
		return [pool.pick_random()[0], BasicAttack.new()]
	else:
		return [null, GuardAction.new()]

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
