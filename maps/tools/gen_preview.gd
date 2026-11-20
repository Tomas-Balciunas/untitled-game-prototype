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
	var fingerprint: bool = args.has("fingerprint")
	var combined: String = ""
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

		var levels: Array = res.tile_level.values()
		var level_lo: int = levels.min() if not levels.is_empty() else 0
		var level_hi: int = levels.max() if not levels.is_empty() else 0

		print("seed %-6d %5dms rooms=%-3d floor=%-5d doors=%-3d locked=%-2d chests=%-3d reward=%-2d lockedChests=%-2d keys(chest/enemy)=%d/%d enemies=%d ramps=%d levels=%d..%d hazards=%d" % [
			seed_value, elapsed, res.rooms.size(), res.floor_tiles.size(),
			res.door_spawns.size(), locked, res.chest_spawns.size(),
			res.reward_chests.size(), res.chest_locks.size(),
			keyed_chests, keyed_enemies, res.enemy_spawns.size(),
			res.ramps.size(), level_lo, level_hi, res.hazard_patches.size(),
		])

		for problem: String in _validate(res):
			print("    ! %s" % problem)
			failures += 1

		if fingerprint:
			var fp: String = _fingerprint(res)
			combined += fp
			print("fp %d %s" % [seed_value, fp])

	if fingerprint:
		print("fp total %s" % combined.md5_text())

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

	problems.append_array(_validate_elevation(res))
	problems.append_array(_validate_hazards(res))
	problems.append_array(_validate_portals(res))
	problems.append_array(_validate_chests(res))

	return problems

func _validate_chests(res: MapGenerator.Result) -> Array:
	var blocked: Dictionary = {}
	for t: Vector2i in res.chest_spawns:
		blocked[t] = true
	var seen: Dictionary = { res.spawn: true }
	var stack: Array = [res.spawn]
	while not stack.is_empty():
		var t: Vector2i = stack.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = t + d
			if res.floor_tiles.has(n) and not blocked.has(n) and not seen.has(n):
				seen[n] = true
				stack.push_back(n)
	var cut_off: int = res.floor_tiles.size() - blocked.size() - seen.size()
	if cut_off > 0:
		return ["chests wall off %d floor tiles" % cut_off]
	return []

func _validate_portals(res: MapGenerator.Result) -> Array:
	var problems: Array = []
	var portals: Array = [res.return_tile]
	if res.has_end:
		portals.append(res.end_tile)

	var start: Vector2i = res.spawn
	for portal: Vector2i in portals:
		var seen: Dictionary = { start: true, portal: true }
		var stack: Array = [start]
		while not stack.is_empty():
			var t: Vector2i = stack.pop_back()
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = t + d
				if res.floor_tiles.has(n) and not seen.has(n):
					seen[n] = true
					stack.push_back(n)
		if seen.size() < res.floor_tiles.size():
			problems.append("portal %s cuts off %d floor tiles" % [portal, res.floor_tiles.size() - seen.size()])

	return problems

func _validate_hazards(res: MapGenerator.Result) -> Array:
	var problems: Array = []
	var forbidden: Dictionary = {}
	for t in [res.spawn, res.return_tile] + res.chest_spawns:
		forbidden[t] = "spawn/portal/chest"
	if res.has_end:
		forbidden[res.end_tile] = "end portal"
	for entry: Dictionary in res.door_spawns:
		forbidden[entry["a"]] = "door"
		forbidden[entry["b"]] = "door"

	var seen: Dictionary = {}
	for patch: Dictionary in res.hazard_patches:
		var rect: Rect2i = patch["rect"]
		if not HazardRegistry.has_hazard(patch["id"]):
			problems.append("hazard patch uses unknown id '%s'" % patch["id"])
		var level: int = res.level_at(rect.position)
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				var t := Vector2i(x, y)
				if not res.floor_tiles.has(t):
					problems.append("hazard on non-floor tile %s" % [t])
				elif res.ramps.has(t):
					problems.append("hazard on ramp %s" % [t])
				elif res.level_at(t) != level:
					problems.append("hazard patch spans levels at %s" % [t])
				if forbidden.has(t):
					problems.append("hazard on %s tile %s" % [forbidden[t], t])
				if seen.has(t):
					problems.append("hazard patches overlap at %s" % [t])
				seen[t] = true

	return problems

func _validate_elevation(res: MapGenerator.Result) -> Array:
	var problems: Array = []

	for key in res.floor_tiles.keys():
		var t: Vector2i = key
		for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			var n: Vector2i = t + d
			if not res.floor_tiles.has(n):
				continue
			var here: int = _edge_half_levels(res, t, d)
			var there: int = _edge_half_levels(res, n, -d)
			if here == INVALID_EDGE or there == INVALID_EDGE or here != there:
				problems.append("floor %s -> %s is not walkable" % [t, n])

	var keep_flat: Array = [res.spawn, res.return_tile] + res.enemy_spawns + res.chest_spawns
	for entry: Dictionary in res.door_spawns:
		keep_flat.append(entry["a"])
		keep_flat.append(entry["b"])
	for t in keep_flat:
		if res.ramps.has(t):
			problems.append("ramp on a tile that must stay flat: %s" % [t])

	return problems

const INVALID_EDGE: int = 1 << 30

func _edge_half_levels(res: MapGenerator.Result, t: Vector2i, d: Vector2i) -> int:
	var level: int = res.level_at(t)
	if not res.ramps.has(t):
		return level * 2
	var up: Vector2i = res.ramps[t]["dir"]
	if d == up:
		return level * 2 + 2
	if d == -up:
		return level * 2
	return INVALID_EDGE

func _parse_args() -> Dictionary:
	var parsed: Dictionary = {}
	var raw: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = 0

	while i < raw.size():
		var token: String = raw[i]
		if not token.begins_with("--"):
			i += 1
		elif i + 1 < raw.size() and not raw[i + 1].begins_with("--"):
			parsed[token.substr(2)] = raw[i + 1]
			i += 2
		else:
			parsed[token.substr(2)] = "true"
			i += 1

	return parsed

func _fingerprint(res: MapGenerator.Result) -> String:
	var rooms: Array = []
	for room: MapGenerator.Room in res.rooms:
		rooms.append(Rect2i(room.x, room.y, room.w, room.h))
	var parts: Array = [
		res.spawn, res.return_tile, res.end_tile, res.has_end, rooms,
		res.floor_tiles.keys(), res.wall_tiles, res.corridor_tiles.keys(),
		res.enemy_spawns, res.enemy_depths, res.chest_spawns, res.door_spawns, res.chest_keys,
		res.chest_locks, res.enemy_keys, res.reward_chests, res.tile_level,
		res.ramps, res.hazard_patches,
	]
	return var_to_str(parts).md5_text()

func _load_config(map_id: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string("res://maps/maps.json")
	if text.is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has(map_id):
		return {}

	return parsed[map_id].get("config", {})
