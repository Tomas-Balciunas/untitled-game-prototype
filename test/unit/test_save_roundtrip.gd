extends GutTest

const SLOT := 98


func _slot_path() -> String:
	return "user://save_slot_%d.save" % SLOT


func after_each() -> void:
	var dir := DirAccess.open("user://")
	for p: String in [_slot_path(), _slot_path() + ".tmp"]:
		if dir.file_exists(p):
			dir.remove(p)


# Push a dict through the real save file so EncodedObjectAsID behaviour applies.
func _through_file(d: Dictionary) -> Dictionary:
	var f := FileAccess.open(_slot_path(), FileAccess.WRITE)
	f.store_var(d)
	f.close()
	var f2 := FileAccess.open(_slot_path(), FileAccess.READ)
	var back: Variant = f2.get_var()
	f2.close()
	return back


func _make_weapon() -> Weapon:
	var w := Weapon.new()
	w.id = "tmp_sword"
	w.item_name = "Tmp Sword"
	w.type = ItemTypes.ItemType.EQUIPMENT
	w.value = 42
	w.quality = ItemTypes.Quality.RARE
	w.stats = Stats.new()
	w.stats.attack = 7.0
	w.scaling = WeaponScaling.new()
	w.attack_rate = 2
	return w


func test_gear_class_tag_is_the_script_class() -> void:
	assert_eq(_make_weapon().game_save()["class"], "Weapon")


func test_gear_survives_the_file_roundtrip() -> void:
	var back := _through_file(_make_weapon().game_save())
	var item := Item.create_from_save(back)
	assert_not_null(item, "gear should rebuild")
	assert_true(item is Weapon, "should come back as a Weapon")
	assert_eq(item.id, "tmp_sword")
	assert_eq(item.get_item_name(), "Tmp Sword")
	assert_eq((item as Weapon).attack_rate, 2)
	assert_eq((item as Weapon).stats.attack, 7.0)
	assert_eq((item as Weapon).quality, ItemTypes.Quality.RARE)


func test_effect_keeps_remaining_turns() -> void:
	var p := PoisonEffect.new()
	p.id = "tmp_poison"
	p.duration_turns = 5
	p.remaining_turns = 3
	var back := _through_file(p.game_save())
	var restored := Effect.create_from_save(back)
	assert_not_null(restored)
	restored.game_load(back)
	assert_eq(restored.remaining_turns, 3, "duration must survive the save")
	assert_eq(restored.duration_turns, 5)


func _make_character(char_name: String) -> Character:
	var proto: CharacterResource = CharacterRegistry.get_character("mc")
	var res: CharacterResource = proto.duplicate()
	res.name = char_name
	res.race = RaceRegistry.get_by_name("Human")
	res.job = JobRegistry.get_by_name("Fighter")
	return Character.new(res)


func test_character_name_survives() -> void:
	var c := _make_character("Bilbo")
	var back := _through_file(c.game_save())
	var restored := Character.create_from_save(back)
	assert_not_null(restored)
	assert_eq(restored.resource.name, "Bilbo", "name shown in UI")
	assert_eq(restored.name, "Bilbo")


func test_load_does_not_mutate_the_registry() -> void:
	var proto: CharacterResource = CharacterRegistry.get_character("mc")
	var before := proto.name
	var c := _make_character("Frodo")
	Character.create_from_save(_through_file(c.game_save()))
	assert_eq(CharacterRegistry.get_character("mc").name, before, "registry must stay untouched")


func test_character_keeps_gear_and_death() -> void:
	var c := _make_character("Sam")
	c.inventory.add_item(_make_weapon())
	c.is_dead = true
	c.state.current_health = 0

	var restored := Character.create_from_save(_through_file(c.game_save()))
	assert_not_null(restored)
	assert_true(restored.is_dead, "death must survive")

	var found := restored.inventory.get_item_by_id("tmp_sword")
	assert_not_null(found, "gear must still be in the inventory")
	assert_true(found is Weapon)


func test_unknown_race_and_job_resolve() -> void:
	assert_not_null(RaceRegistry.get_by_name(RaceRegistry.type_to_string(Race.Name.UNKNOWN)))
	assert_not_null(JobRegistry.get_by_name(JobRegistry.type_to_string(Job.Name.UNKNOWN)))


func test_formation_order_survives() -> void:
	var p := Party.new()
	var a := _make_character("A")
	var b := _make_character("B")
	p.members = [a, b]
	p.formation = [null, b, null, a]

	var p2 := Party.new()
	p2.game_load(_through_file(p.game_save()))
	assert_eq(p2.members.size(), 2)
	assert_null(p2.formation[0])
	assert_eq((p2.formation[1] as Character).resource.name, "B")
	assert_null(p2.formation[2])
	assert_eq((p2.formation[3] as Character).resource.name, "A")
