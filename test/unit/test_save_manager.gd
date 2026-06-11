extends GutTest

const SLOT := 99


func _slot_path() -> String:
	return "user://save_slot_%d.save" % SLOT


func after_each() -> void:
	SaveManager.load_issues.clear()
	var dir := DirAccess.open("user://")
	for p: String in [_slot_path(), _slot_path() + ".tmp"]:
		if dir.file_exists(p):
			dir.remove(p)


func test_save_stamps_version() -> void:
	SaveManager.save_game(SLOT)
	var data := SaveManager.load_game(SLOT)
	assert_eq(data.get("version", -1), SaveManager.SAVE_VERSION)


func test_save_leaves_no_tmp_file() -> void:
	SaveManager.save_game(SLOT)
	assert_true(FileAccess.file_exists(_slot_path()))
	assert_false(FileAccess.file_exists(_slot_path() + ".tmp"))


func test_save_overwrites_existing_slot() -> void:
	SaveManager.save_game(SLOT)
	SaveManager.save_game(SLOT)
	assert_true(FileAccess.file_exists(_slot_path()))
	assert_false(FileAccess.file_exists(_slot_path() + ".tmp"))


func test_load_recovers_from_orphaned_tmp() -> void:
	var file := FileAccess.open(_slot_path() + ".tmp", FileAccess.WRITE)
	file.store_var({"version": SaveManager.SAVE_VERSION, "marker": true})
	file.close()
	var data := SaveManager.load_game(SLOT)
	assert_true(data.get("marker", false))


func test_load_missing_slot_returns_empty() -> void:
	assert_eq(SaveManager.load_game(SLOT), {})


func test_corrupt_save_returns_empty() -> void:
	var file := FileAccess.open(_slot_path(), FileAccess.WRITE)
	file.store_var(42)
	file.close()
	assert_eq(SaveManager.load_game(SLOT), {})


func test_migrate_stamps_unversioned_save() -> void:
	var state := {"game_state": {}}
	SaveManager._migrate(state)
	assert_eq(state["version"], SaveManager.SAVE_VERSION)


func test_migrate_keeps_current_version() -> void:
	var state := {"version": SaveManager.SAVE_VERSION}
	SaveManager._migrate(state)
	assert_eq(state["version"], SaveManager.SAVE_VERSION)


func test_report_load_issue_collects() -> void:
	SaveManager.report_load_issue("gut test issue")
	assert_eq(SaveManager.load_issues, ["gut test issue"])
