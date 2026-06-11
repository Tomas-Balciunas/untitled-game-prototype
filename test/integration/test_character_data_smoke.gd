# Builds every CharacterResource under characters/ to catch broken data —
# logic tests use the synthetic fixture, so production .tres would otherwise
# never be exercised.
extends GutTest

const ROOT := "res://characters"

var _built: Array = []


func after_each() -> void:
	for c in _built:
		if c and is_instance_valid(c.state):
			c.state.free()
	_built = []


func _collect_tres(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := dir_path + "/" + entry
		if dir.current_is_dir():
			_collect_tres(path, out)
		elif entry.ends_with(".tres"):
			out.append(path)
		entry = dir.get_next()


func test_every_character_resource_builds() -> void:
	var paths: Array = []
	_collect_tres(ROOT, paths)
	assert_gt(paths.size(), 0, "no .tres found under %s" % ROOT)

	var checked := 0
	for path: String in paths:
		var res = load(path)
		if res is not CharacterResource:
			continue
		var c: Character = Character.new(res)
		_built.append(c)
		assert_not_null(c.state, "%s built without state" % path)
		assert_gt(c.stats.get_stat(Stats.StatRef.HEALTH), 0, "%s has no health" % path)
		checked += 1

	gut.p("built %d character resources" % checked)
	assert_gt(checked, 0, "no CharacterResource found under %s" % ROOT)
