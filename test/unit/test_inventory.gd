extends GutTest


func _item(item_type: int = 0) -> Weapon:
	var w := Weapon.new()
	w.item_name = "test item"
	w.type = item_type as ItemTypes.ItemType
	return w


func _inv(max_slots: int = 20) -> Inventory:
	var inv := Inventory.new()
	inv.max_slots = max_slots
	return inv


func test_add_and_has() -> void:
	var inv := _inv()
	var item := _item()
	assert_true(inv.add_item(item))
	assert_true(inv.has_item(item))


func test_add_fails_when_full() -> void:
	var inv := _inv(1)
	assert_true(inv.add_item(_item()))
	assert_false(inv.has_free_slot())
	assert_false(inv.add_item(_item()))


func test_remove_item() -> void:
	var inv := _inv()
	var item := _item()
	inv.add_item(item)
	assert_true(inv.remove_item(item))
	assert_false(inv.has_item(item))


func test_find_by_type() -> void:
	var inv := _inv()
	var a := _item(1)
	var b := _item(2)
	inv.add_item(a)
	inv.add_item(b)
	var found := inv.find_by_type(1)
	assert_eq(found, [a])


func test_get_all_items_returns_copy() -> void:
	var inv := _inv()
	inv.add_item(_item())
	var items := inv.get_all_items()
	items.clear()
	assert_eq(inv.slots.size(), 1, "mutating the returned array must not affect the inventory")
