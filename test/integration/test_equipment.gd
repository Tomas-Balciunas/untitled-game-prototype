extends GutTest

const Combatant = preload("res://test/helpers/combatant.gd")

var _built: Array = []


func _make() -> Character:
	var c := Combatant.make()
	_built.append(c)
	return c


func after_each() -> void:
	Combatant.free_built(_built)
	_built = []


func _sword(attack: float = 5.0) -> Weapon:
	var w := Weapon.new()
	w.item_name = "gut sword"
	w.stats = Stats.new()
	w.stats.attack = attack
	w.base_stats = w.stats.duplicate(true)
	return w


func test_equip_moves_item_from_inventory_to_slot() -> void:
	var c := _make()
	var w := _sword()
	c.inventory.add_item(w)

	assert_true(c.equipment.equip_item(w))
	assert_eq(c.equipment.weapon, w)
	assert_false(c.inventory.has_item(w))


func test_equip_adds_gear_stats() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.ATTACK)
	var before := c.stats.get_stat(Stats.StatRef.ATTACK)

	var w := _sword(5.0)
	c.inventory.add_item(w)
	c.equipment.equip_item(w)

	assert_eq(c.stats.get_stat(Stats.StatRef.ATTACK), before + 5)


func test_unequip_returns_item_and_restores_stats() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.ATTACK)
	var before := c.stats.get_stat(Stats.StatRef.ATTACK)

	var w := _sword(5.0)
	c.inventory.add_item(w)
	c.equipment.equip_item(w)

	assert_true(c.equipment.unequip_slot(ItemTypes.GearType.WEAPON))
	assert_null(c.equipment.weapon)
	assert_true(c.inventory.has_item(w))
	assert_eq(c.stats.get_stat(Stats.StatRef.ATTACK), before)


func test_equip_replaces_existing_item() -> void:
	var c := _make()
	var first := _sword(5.0)
	var second := _sword(8.0)
	c.inventory.add_item(first)
	c.inventory.add_item(second)

	c.equipment.equip_item(first)
	c.equipment.equip_item(second)

	assert_eq(c.equipment.weapon, second)
	assert_true(c.inventory.has_item(first), "replaced item goes back to inventory")


func test_gear_modifiers_apply_and_remove() -> void:
	var c := _make()
	StatCalculator.recalculate_stat(c, Stats.StatRef.DEFENSE)
	var before := c.stats.get_stat(Stats.StatRef.DEFENSE)

	var w := _sword(0.0)
	var m := StatModifier.new()
	m.stat = Stats.StatRef.DEFENSE
	m.type = StatModifier.Type.ADDITIVE
	m.value = 7.0
	w.base_modifiers = [m]

	c.inventory.add_item(w)
	c.equipment.equip_item(w)
	assert_eq(c.stats.get_stat(Stats.StatRef.DEFENSE), before + 7)

	c.equipment.unequip_slot(ItemTypes.GearType.WEAPON)
	assert_eq(c.stats.get_stat(Stats.StatRef.DEFENSE), before)
