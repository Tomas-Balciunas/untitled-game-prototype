extends GearResource

class_name WeaponResource

@export var targeting: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
@export var attack_rate: int = 1
@export var weapon_range: TargetingManager.RangeType = TargetingManager.RangeType.MELEE
@export var weapon_type: ItemTypes.WeaponType = ItemTypes.WeaponType.SWORD
@export var accuracy_range: int = 0


func _init() -> void:
	type = ItemTypes.ItemType.EQUIPMENT
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Weapon:
	var weapon: Weapon = Weapon.new()
	weapon.id = id
	weapon.item_name = name
	weapon.type = type
	weapon.quality = quality
	weapon.item_description = description
	weapon.value = value
	weapon.stats = base_stats.duplicate(true)
	weapon.base_stats = weapon.stats.duplicate(true)
	weapon.base_effects = effects.duplicate(true)
	weapon.base_modifiers = modifiers.duplicate(true)
	weapon.targeting = targeting
	weapon.weapon_type = weapon_type
	weapon.weapon_range = weapon_range
	weapon.accuracy_range = accuracy_range
	weapon.attack_rate = attack_rate
	
	return weapon


func get_applicable_stat_modifiers() -> Array[Stats.StatRef]:
	return [Stats.StatRef.ATTACK, Stats.StatRef.MAGIC_POWER, Stats.StatRef.DIVINE_POWER]
