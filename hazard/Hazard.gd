extends Resource
class_name Hazard

@export var id: String
@export var name: String = "Hazard"
@export var damage: int = 0
@export_range(0.0, 1.0) var max_hp_ratio: float = 0.0
@export var damage_type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
@export var effect: Effect

@export_group("Look")
@export var color: Color = Color(0.4, 0.9, 0.3)
@export_range(0.0, 1.0) var opacity: float = 0.6
@export var flow_speed: float = 0.6
@export var light_energy: float = 0.6

func apply_to_party(members: Array) -> void:
	for member: Character in members:
		if not member.is_dead:
			apply_to(member)

func apply_to(target: Character) -> void:
	var source := HazardSource.new(self)
	var amount: int = damage + roundi(target.stats.health * max_hp_ratio)

	if amount > 0:
		var ctx := ActionContext.new()
		ctx.source = source
		ctx.set_targets(target)
		DamageResolver.new(amount).execute(ctx)

	if effect == null or target.is_dead:
		return

	var existing: Effect = _same_effect_on(target)
	if existing:
		existing.remaining_turns = maxi(existing.remaining_turns, effect.duration_turns)
		return

	var act := ActionContext.new()
	act.source = source
	act.set_targets(target)
	EffectApplicationResolver.new(effect).execute(act)

func _same_effect_on(target: Character) -> Effect:
	for e: Effect in target.effects:
		if e.get_script() == effect.get_script():
			return e
	return null
