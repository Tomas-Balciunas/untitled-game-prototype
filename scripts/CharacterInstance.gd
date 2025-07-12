extends RefCounted

class_name CharacterInstance

signal health_changed(old_health, new_health)
signal damaged(amount: int, source: CharacterInstance)
signal healed(amount: int)
signal died()

var resource: CharacterResource
var attack_power: float
var current_health: int
var max_health: int
var current_mana: int
var max_mana: int
var speed: int
var current_experience: int
var status_effects: Array = []
var turn_meter: int = 0
var learnt_skills: Array[Skill] = []
var effects: Array[Effect] = []
var damage_type: DamageTypes.Type

func _init(res: CharacterResource) -> void:
	resource = res

	attack_power = res.attack_power
	current_health = res.health_points
	max_health = res.health_points
	current_mana = res.mana_points
	max_mana = res.mana_points
	speed = res.speed
	current_experience = res.experience
	damage_type = res.default_damage_type
	
	for skill in resource.default_skills:
		learnt_skills.append(skill)
	
	for effect in resource.default_effects:
		effects.append(effect)

func set_current_health(new_health: int) -> void:
	var old = current_health
	current_health = clamp(new_health, 0, max_health)
	if current_health < old:
		emit_signal("damaged", old - current_health, self)
	elif current_health > old:
		emit_signal("healed", current_health - old)
	emit_signal("health_changed", old, current_health)
	if current_health == 0 and old > 0:
		emit_signal("died")

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
