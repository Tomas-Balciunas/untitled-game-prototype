extends Node

class_name DamageCalculator

## Damage roll skew: exponent spans [1/N, N] across the accuracy advantage
const DAMAGE_SKEW_RANGE := 3.0

## Accuracy advantage (-1..1) below which crits cannot happen at all (~2x evasion)
const CRITICAL_GATE := 0.34
## Advantage at which crit chance reaches its ceiling (~9x evasion)
const CRITICAL_FULL := 0.80
const CRITICAL_CHANCE_MAX := 0.15

var context: ActionContext = null
var source: ContextSource = null
var actor: Character = null
var target: Character = null

var type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
var final_damage: float = 0.0
var base_damage: float = 0.0
var accuracy: float = 0.0
var damage_variance: int = 0
var defense_ignore: int = 0
var is_critical: bool = false
var critical_damage: float = Stats.CRITICAL_DAMAGE_BASE / 100.0
var damage_reduction: float = 0.0

func _init(event: DamageInstance) -> void:
	context = event.ctx
	base_damage = event.damage
	final_damage = event.damage
	source = event.source
	target = event.target
	actor = source.get_actor()
	
	if actor:
		accuracy = actor.stats.accuracy
		critical_damage = actor.stats.get_critical_multiplier()

	assert(target)
	
	set_damage_type()
	set_damage_variance()

func calculate_final_damage() -> void:
	apply_damage_variance()

	var defense: float = max(0.0, target.stats.defense)
	var defense_constant: float = 200.0
	var multiplier := defense_constant / (defense_constant + defense)
	final_damage *= multiplier

	if is_critical:
		final_damage *= critical_damage

	final_damage *= (1.0 - damage_reduction)

func apply_damage_variance() -> void:
	if damage_variance == 0:
		final_damage = base_damage
		is_critical = false
		return

	var acc: float = max(1.0, accuracy)
	var evasion: float = max(1.0, target.stats.evasion)

	var advantage: float = (acc - evasion) / (acc + evasion)

	var exponent: float = pow(DAMAGE_SKEW_RANGE, -advantage)
	var roll: float = pow(randf(), exponent)

	# crit is the top slice of that same roll, so it stays a near-max hit.
	# roll has CDF x ** (1/exponent), so the slice of size `chance` starts at
	# (1 - chance) ** exponent — which makes the rate exactly `chance`.
	var crit_chance: float = CRITICAL_CHANCE_MAX * clampf(
		inverse_lerp(CRITICAL_GATE, CRITICAL_FULL, advantage), 0.0, 1.0)
	is_critical = crit_chance > 0.0 and roll >= pow(1.0 - crit_chance, exponent)

	var variance_pct: float = damage_variance / 100.0
	var damage_min: float = base_damage * (1.0 - variance_pct)
	var damage_max: float = base_damage * (1.0 + variance_pct)

	final_damage = lerpf(damage_min, damage_max, roll)

	if DEBUG_ROLLS:
		_debug_log(acc, evasion, advantage, crit_chance, roll, damage_min, damage_max)


const DEBUG_ROLLS := true
static var _debug_buckets: Dictionary = {}

func _debug_log(acc: float, evasion: float, advantage: float, crit_chance: float, roll: float, dmg_min: float, dmg_max: float) -> void:
	var key: String = "%.2f" % advantage

	var bucket: Array = _debug_buckets.get(key, [0, 0])
	bucket[0] += 1
	if is_critical:
		bucket[1] += 1
	_debug_buckets[key] = bucket

	var actual_crit: float = 100.0 * bucket[1] / bucket[0]

	print("[dmg] acc %.1f ev %.1f (adv=%+.2f) | roll %.3f%s | base %d band %.1f-%.1f -> %.2f | crit %d/%d = %.1f%% (expect %.1f%%)" % [
		acc, evasion, advantage,
		roll, " *CRIT*" if is_critical else "",
		base_damage, dmg_min, dmg_max, final_damage,
		bucket[1], bucket[0], actual_crit, 100.0 * crit_chance,
	])

func get_final_damage() -> int:
	return max(0, round(final_damage))

func set_damage_type() -> void:
	if source.skill and source.skill.get_damage_type():
		type = source.skill.get_damage_type()
		return
	type = DamageTypes.Type.PHYSICAL

func set_damage_variance() -> void:
	var weapon: Weapon = actor.equipment.get("weapon") if actor else null
	damage_variance = weapon.damage_variance if weapon else 0
