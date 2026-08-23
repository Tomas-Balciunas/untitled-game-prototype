extends Node

# Headless generator preview. Exercises MapGenerator.generate() without playing
# the game, so layout and door/lock output can be checked in seconds.
#
#   godot --headless --path . maps/tools/gen_preview.tscn -- --map random_crypt_01 --count 5
#
# Runs as a scene, not with -s: MapGenerator references the TilesetRegistry and
# TrapRegistry autoloads, and GDScript resolves autoload identifiers when the
# script is compiled, so a bare script run cannot load it at all.
#
# Flags: --map <id> --seed <int> --count <n> --layout <name> --density <f>
#        --width <n> --height <n> --rooms <n>

func _ready() -> void:
	_run()

func _run() -> void:
	var args: Dictionary = _parse_args()
	var map_id: String = args.get("map", "random_crypt_01")
	var config: Dictionary = _load_config(map_id)

	if config.is_empty():
		print("no procedural config found for map '%s'" % map_id)
		get_tree().quit(1)
		return

	if args.has("layout"):
		config["layout"] = args["layout"]
	if args.has("density"):
		config["density"] = float(args["density"])
	if args.has("width"):
		config["width"] = int(args["width"])
	if args.has("height"):
		config["height"] = int(args["height"])
	if args.has("rooms"):
		config["room_count"] = [int(args["rooms"]), int(args["rooms"])]

	var base_seed: int = int(args.get("seed", 1))
	var count: int = int(args.get("count", 1))
	var failures: int = 0

	print("map=%s layout=%s %dx%d density=%s" % [
		map_id, config.get("layout", "branching"),
		int(config.get("width", 30)), int(config.get("height", 30)),
		str(config.get("density", 0.0)),
	])

	for i in range(count):
		var seed_value: int = base_seed + i
		var started: int = Time.get_ticks_msec()
		var gen := MapGenerator.new(seed_value, config, map_id)
		var res: MapGenerator.Result = gen.generate()
		var elapsed: int = Time.get_ticks_msec() - started

		if res.floor_tiles.is_empty():
			print("seed %-6d FAILED: no floor" % seed_value)
			failures += 1
			continue

		var locked: int = 0
		for entry: Dictionary in res.door_spawns:
			if entry["locked"]:
				locked += 1

		var keyed_chests: int = res.chest_keys.size()
		var keyed_enemies: int = res.enemy_keys.size()

		print("seed %-6d %5dms rooms=%-3d floor=%-5d doors=%-3d locked=%-2d chests=%-3d reward=%-2d lockedChests=%-2d keys(chest/enemy)=%d/%d enemies=%d" % [
			seed_value, elapsed, res.rooms.size(), res.floor_tiles.size(),
			res.door_spawns.size(), locked, res.chest_spawns.size(),
			res.reward_chests.size(), res.chest_locks.size(),
			keyed_chests, keyed_enemies, res.enemy_spawns.size(),
		])

		for problem: String in _validate(res):
			print("    ! %s" % problem)
			failures += 1

	if failures > 0:
		print("%d problem(s)" % failures)
		get_tree().quit(1)
		return

	get_tree().quit(0)

# Every lock must have its key somewhere, and every locked door must guard a
# chest — the two invariants the placement algorithm exists to guarantee.
func _validate(res: MapGenerator.Result) -> Array:
	var problems: Array = []
	var minted: Dictionary = {}

	for bucket: Dictionary in [res.chest_keys, res.enemy_keys]:
		for idx in bucket.keys():
			for entry: Dictionary in bucket[idx]:
				minted[entry["id"]] = true

	for entry: Dictionary in res.door_spawns:
		if not entry["locked"]:
			continue
		if not minted.has(entry["key_id"]):
			problems.append("locked door %s has no key anywhere" % entry["id"])

	for idx in res.chest_locks.keys():
		if not minted.has(res.chest_locks[idx]["key_id"]):
			problems.append("locked chest %d has no key anywhere" % idx)
		if res.reward_chests.has(idx):
			problems.append("reward chest %d is itself locked" % idx)
		if res.chest_keys.has(idx):
			problems.append("chest %d is locked but holds a door key" % idx)

	for idx in res.chest_keys.keys():
		if idx >= res.chest_spawns.size():
			problems.append("key assigned to chest index %d that does not exist" % idx)

	for idx in res.enemy_keys.keys():
		if idx >= res.enemy_spawns.size():
			problems.append("key assigned to enemy index %d that does not exist" % idx)

	return problems

func _parse_args() -> Dictionary:
	var parsed: Dictionary = {}
	var raw: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = 0

	while i < raw.size():
		var token: String = raw[i]
		if token.begins_with("--") and i + 1 < raw.size():
			parsed[token.substr(2)] = raw[i + 1]
			i += 2
		else:
			i += 1

	return parsed

func _load_config(map_id: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string("res://maps/maps.json")
	if text.is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has(map_id):
		return {}

	return parsed[map_id].get("config", {})
