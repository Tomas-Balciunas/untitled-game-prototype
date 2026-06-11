extends RefCounted

const HEALTH := 100.0
const MANA := 50.0
const SP := 30.0
const ATTACK := 10.0
const DEFENSE := 10.0
const SPEED := 5.0
const STRENGTH := 5


static func make() -> Character:
	return Character.new(make_resource())


static func make_resource() -> CharacterResource:
	var res := CharacterResource.new()
	res.id = "gut_fixture"
	res.name = "Gut Fixture"

	res.race = Race.new()
	res.race.attributes = Attributes.new()
	res.race.stat_attribute_growth = StatAttributeGrowth.new()

	res.job = Job.new()
	res.job.attributes = Attributes.new()
	res.job.stat_level_growth = Stats.new()
	res.job.stat_attribute_growth = StatAttributeGrowth.new()

	res.attributes = Attributes.new()
	res.attributes.strength = STRENGTH

	res.base_stats = Stats.new()
	res.base_stats.health = HEALTH
	res.base_stats.mana = MANA
	res.base_stats.sp = SP
	res.base_stats.attack = ATTACK
	res.base_stats.defense = DEFENSE
	res.base_stats.speed = SPEED

	res.stat_level_growth = Stats.new()
	res.stat_attribute_growth = StatAttributeGrowth.new()
	res.experience_manager = ExperienceManager.new()
	return res


static func free_built(chars: Array) -> void:
	for c in chars:
		if c and is_instance_valid(c.state):
			c.state.free()
