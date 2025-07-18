extends RefCounted

class_name CharacterInstance

signal health_changed(old_health, new_health)
signal damaged(amount: int, source: CharacterInstance)
signal healed(amount: int)
signal died(ded: CharacterInstance)

var is_dead: bool = false

var resource: CharacterResource
var stats: Stats
var current_experience: int
var status_effects: Array = []
var turn_meter: int = 0
var learnt_skills: Array[Skill] = []
var effects: Array[Effect] = []
var damage_type: DamageTypes.Type
var attributes: Attributes
var job: Job
var gender: Gender
var race: Race

func _init(res: CharacterResource) -> void:
	stats = Stats.new()
	fill_stats(res)
	fill_attributes(res)
	resource = res
	
	current_experience = res.experience
	damage_type = res.default_damage_type
	
	job = res.job
	gender = res.gender
	race = res.race
	
	for skill in res.default_skills:
		if learnt_skills.has(skill):
			continue
		learnt_skills.append(skill)
		
	if res.job:
		for skill in res.job.skills:
			if learnt_skills.has(skill):
				continue
			print(skill.name)
			learnt_skills.append(skill)
	
	for effect in res.default_effects:
		if effects.has(effect):
			continue
		effects.append(effect)
	
	if res.job:
		for effect in res.job.effects:
			if effects.has(effect):
				continue
			effects.append(effect)
	
	stats.recalculate_stats(self, true)

func set_current_health(new_health: int) -> void:
	var old = stats.current_health
	var new = clamp(new_health, 0, stats.max_health)
	
	if new < old:
		stats.current_health = new
		emit_signal("damaged", old - stats.current_health, self)
	elif new > old:
		stats.current_health = new
		print("%s was healed for %s" % [resource.name, stats.current_health - old])
		emit_signal("healed", stats.current_health - old)
	emit_signal("health_changed", old, stats.current_health)
	if new == 0 and old > 0:
		stats.current_health = new
		is_dead = true
		print("%s is dead" % resource.name)
		emit_signal("died", self)
	print("%s HP %s/%s" % [resource.name, stats.current_health, stats.max_health])

func apply_effect(effect: Effect, ctx: DamageContext) -> void:
	for passive in effects.duplicate():
		passive.on_trigger(EffectTriggers.ON_APPLY_EFFECT, ctx)
			
	effect.on_apply(self)
	effects.append(effect)
		
func remove_effect(effect: Resource) -> void:
	effects.erase(effect)
	if effects.size() > 0 and effect.has_method(EffectTriggers.ON_EXPIRE):
		effect.on_expire(self)
		
func process_effects(trigger: String, ctx: DamageContext = null) -> void:
	for effect in effects.duplicate():
		effect.on_trigger(trigger, ctx)
		
func fill_stats(res: CharacterResource):
	stats.base_attack = res.attack_power
	stats.current_health = res.health_points
	stats.base_health = res.health_points
	stats.current_mana = res.mana_points
	stats.base_mana = res.mana_points
	stats.base_speed = res.speed

func fill_attributes(res: CharacterResource):
	attributes = Attributes.new()

	if res.race:
		attributes.add(res.race.attributes)
	if res.gender:
		attributes.add(res.gender.attributes)
	if res.job:
		attributes.add(res.job.attributes)

func get_attack_power():
	pass
