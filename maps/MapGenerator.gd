extends RefCounted
class_name MapGenerator

class Room:
	var x: int
	var y: int
	var w: int
	var h: int

	func center() -> Vector2i:
		return Vector2i(x + w / 2, y + h / 2)

	func intersects(other: Room, padding: int = 1) -> bool:
		return not (
			x + w + padding <= other.x
			or other.x + other.w + padding <= x
			or y + h + padding <= other.y
			or other.y + other.h + padding <= y
		)

	func contains(p: Vector2i) -> bool:
		return p.x >= x and p.x < x + w and p.y >= y and p.y < y + h

class Result:
	var spawn: Vector2i = Vector2i.ZERO
	var return_tile: Vector2i = Vector2i.ZERO
	var end_tile: Vector2i = Vector2i.ZERO
	var has_end: bool = false
	var rooms: Array = []
	var floor_tiles: Dictionary = {}
	var wall_tiles: Dictionary = {}
	var enemy_spawns: Array = []
	# Per enemy spawn: walking distance from the spawn, 0..1 of the farthest tile.
	var enemy_depths: Array = []
	var chest_spawns: Array = []
	var corridor_tiles: Dictionary = {}
	# Door/lock output. door_spawns entries are
	# {id, a, b, locked, key_id, key_name, seal_name, trapped}; chest_keys and
	# enemy_keys map a spawn INDEX to the {id, name} keys it must hand out;
	# chest_locks maps a chest index to the lock it carries; reward_chests lists
	# the chest indices created to justify a locked door.
	var door_spawns: Array = []
	var chest_keys: Dictionary = {}
	var chest_locks: Dictionary = {}
	var enemy_keys: Dictionary = {}
	var reward_chests: Array = []
	# Elevation. tile_level holds every floor tile's level (a ramp's is its low
	# end); ramps maps tile -> {dir, style}, dir pointing uphill.
	var tile_level: Dictionary = {}
	var ramps: Dictionary = {}
	# Floor hazards: {id: String, rect: Rect2i} in tiles, each on one flat level.
	var hazard_patches: Array = []

	func level_at(t: Vector2i) -> int:
		return tile_level.get(t, 0)

	func hazard_at(t: Vector2i) -> String:
		for patch: Dictionary in hazard_patches:
			if (patch["rect"] as Rect2i).has_point(t):
				return patch["id"]
		return ""

	## World y of the walkable surface at a tile's centre.
	func surface_y(t: Vector2i) -> float:
		var y: float = float(level_at(t)) * TilesetRegistry.LEVEL_HEIGHT + TilesetRegistry.FLOOR_THICKNESS
		if ramps.has(t):
			y += TilesetRegistry.LEVEL_HEIGHT * 0.5
		return y

var _rng: RandomNumberGenerator
var _config: Dictionary
var _map_id: String = ""
var _width: int
var _height: int
var _floor: Dictionary = {}
var _corridor_path: Dictionary = {}
# tile -> room index, filled once the rooms are final.
var _room_of: Dictionary = {}
var _cut: Dictionary = {}
var _cut_ready: bool = false
# Walking distance from the spawn to every floor tile.
var _spawn_dist: Dictionary = {}
# _rng state right after doors are built. Trap picks replay from here, so draws
# added to generate() later (ramps, hazards) don't change which trap a door gets.
var _trap_rng_state: int = 0
# Set by apply_to_scene from the Result being built.
var _levels: Dictionary = {}
var _ramps: Dictionary = {}

func _init(seed_value: int, config: Dictionary, map_id: String = "") -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_config = config
	_map_id = map_id
	_width = int(_config.get("width", 30))
	_height = int(_config.get("height", 30))

func generate() -> Result:
	var room_range: Array = _config.get("room_count", [5, 8])
	var size_range: Array = _config.get("room_size", [3, 8])
	var chest_range: Array = _config.get("chest_count", [1, 3])
	var enemy_range: Array = _config.get("enemy_group_count", [2, 5])

	var target_rooms: int = _rng.randi_range(int(room_range[0]), int(room_range[1]))
	# Density: 0.0 = rooms placed uniformly anywhere in the map (long, random
	# corridors). 1.0 = rooms placed close to a deterministic target. For linear
	# layout the target is a point evenly distributed along the map's long axis,
	# so high-density linear chains stretch across the full map. For branching
	# layouts the target is the previous room's center, so high density clusters.
	var density: float = clampf(float(_config.get("density", 0.0)), 0.0, 1.0)
	var layout: String = _config.get("layout", "branching")
	var rooms: Array = []
	var attempts: int = 0
	var max_attempts: int = target_rooms * 30
	var long_axis_x: bool = _width >= _height

	while rooms.size() < target_rooms and attempts < max_attempts:
		attempts += 1
		var rw: int = _rng.randi_range(int(size_range[0]), int(size_range[1]))
		var rh: int = _rng.randi_range(int(size_range[0]), int(size_range[1]))
		var rx: int
		var ry: int
		if density <= 0.0:
			rx = _rng.randi_range(1, _width - rw - 1)
			ry = _rng.randi_range(1, _height - rh - 1)
		else:
			var seed_x: int
			var seed_y: int
			if layout == "linear" or layout == "mixed":
				# Anchor each room to a target point along the long axis. Index i
				# of N rooms targets (i + 0.5) / N of the way across the map. Add
				# a per-room jitter on the short axis so the chain wanders into
				# the otherwise-empty vertical space instead of running dead-flat.
				var t: float = (float(rooms.size()) + 0.5) / float(target_rooms)
				if long_axis_x:
					seed_x = int(lerpf(float(rw / 2 + 1), float(_width - rw / 2 - 1), t))
					var short_jitter: int = _height / 4
					seed_y = _height / 2 + _rng.randi_range(-short_jitter, short_jitter)
				else:
					var short_jitter2: int = _width / 4
					seed_x = _width / 2 + _rng.randi_range(-short_jitter2, short_jitter2)
					seed_y = int(lerpf(float(rh / 2 + 1), float(_height - rh / 2 - 1), t))
			elif layout == "maze":
				# Lay rooms in a roughly square grid covering the whole map so
				# they're uniformly spread instead of biased toward one corner.
				# Higher density snaps each room more strictly to its cell centre.
				var cols: int = maxi(1, int(ceilf(sqrt(float(target_rooms)))))
				var rows: int = maxi(1, int(ceilf(float(target_rooms) / float(cols))))
				var idx: int = rooms.size()
				var col: int = idx % cols
				var row: int = idx / cols
				seed_x = int((float(col) + 0.5) * float(_width) / float(cols))
				seed_y = int((float(row) + 0.5) * float(_height) / float(rows))
			elif rooms.is_empty():
				rx = _rng.randi_range(1, _width - rw - 1)
				ry = _rng.randi_range(1, _height - rh - 1)
				var room0 := Room.new()
				room0.x = rx; room0.y = ry; room0.w = rw; room0.h = rh
				rooms.append(room0)
				continue
			else:
				var prev: Vector2i = rooms[rooms.size() - 1].center()
				seed_x = prev.x
				seed_y = prev.y

			# Window size lerps from full map (density 0) down to a tight
			# room-sized window at density 1. The tight floor is just `room+2`
			# so density actually means "snap to target" at the high end.
			var min_window_w: int = rw + 2
			var min_window_h: int = rh + 2
			var window_w: int = int(lerpf(float(_width), float(min_window_w), density))
			var window_h: int = int(lerpf(float(_height), float(min_window_h), density))
			var half_w: int = window_w / 2
			var half_h: int = window_h / 2
			var lo_x: int = maxi(1, seed_x - half_w)
			var hi_x: int = mini(_width - rw - 1, seed_x + half_w)
			var lo_y: int = maxi(1, seed_y - half_h)
			var hi_y: int = mini(_height - rh - 1, seed_y + half_h)
			if lo_x > hi_x or lo_y > hi_y:
				continue
			rx = _rng.randi_range(lo_x, hi_x)
			ry = _rng.randi_range(lo_y, hi_y)
		var room := Room.new()
		room.x = rx
		room.y = ry
		room.w = rw
		room.h = rh
		var ok: bool = true
		for other: Room in rooms:
			if room.intersects(other):
				ok = false
				break
		if ok:
			rooms.append(room)

	if rooms.is_empty():
		push_error("MapGenerator: failed to place any rooms with config %s" % str(_config))
		return Result.new()

	_init_routing(rooms)
	for i in range(rooms.size()):
		_carve_room(rooms[i], i)

	var chain: Array = _order_chain(rooms, layout)

	var curviness: float = clampf(float(_config.get("corridor_curviness", 0.5)), 0.0, 1.0)

	# Spanning chain — guarantees every room is reachable.
	for i in range(1, chain.size()):
		_carve_winding_corridor(chain[i - 1].center(), chain[i].center(), curviness)

	# Extra connections — branching adds loops, mixed adds a couple, linear adds none.
	var extras_default: Array = _default_extras(layout)
	var extra_range: Array = _config.get("extra_corridors", extras_default)
	var extra_max: int = int(extra_range[1])
	if extra_max > 0:
		var extra_count: int = _rng.randi_range(int(extra_range[0]), extra_max)
		for _i in range(extra_count):
			if rooms.size() < 3:
				break
			var a_idx: int = _rng.randi() % rooms.size()
			var b_idx: int = _rng.randi() % rooms.size()
			if absi(a_idx - b_idx) < 2:
				continue
			_carve_winding_corridor(rooms[a_idx].center(), rooms[b_idx].center(), curviness)

	# Branch spurs — pick a chain room, run a corridor in a random direction,
	# optionally end with a small dead-end room. Adds variety to linear layouts.
	var branch_default: Array = _default_branches(layout)
	var branch_range: Array = _config.get("branch_count", branch_default)
	var branch_max: int = int(branch_range[1])
	if branch_max > 0:
		var branch_count: int = _rng.randi_range(int(branch_range[0]), branch_max)
		_add_branches(rooms, branch_count, curviness)

	_add_pillars(rooms)

	var spawn_room: Room = chain[0]
	var end_room: Room = chain[-1] if chain.size() > 1 else spawn_room

	var res := Result.new()
	res.spawn = spawn_room.center()
	res.return_tile = _pick_room_corner(spawn_room, res.spawn)
	res.rooms = rooms
	res.floor_tiles = _floor.duplicate()
	res.wall_tiles = _derive_walls(_floor)
	res.has_end = end_room != spawn_room
	if res.has_end:
		res.end_tile = _pick_room_corner(end_room, end_room.center())
	_spawn_dist = _distances_from(res.spawn)

	var enemy_pool: Array = rooms.duplicate()
	enemy_pool.erase(spawn_room)
	var enemy_excludes: Array = [res.spawn, res.return_tile]
	if res.has_end:
		enemy_excludes.append(res.end_tile)
	var enemy_total: int = _rng.randi_range(int(enemy_range[0]), int(enemy_range[1]))
	var corridor_enemy_chance: float = clampf(float(_config.get("corridor_enemy_chance", 0.2)), 0.0, 1.0)
	res.enemy_spawns = _pick_enemy_spawns(enemy_pool, enemy_total, corridor_enemy_chance, enemy_excludes)
	var farthest: int = maxi(1, _spawn_dist.values().max())
	for e: Vector2i in res.enemy_spawns:
		res.enemy_depths.append(float(_spawn_dist.get(e, 0)) / float(farthest))

	var chest_excludes: Array = [res.spawn, res.return_tile] + res.enemy_spawns
	if res.has_end:
		chest_excludes.append(res.end_tile)
	var chest_total: int = _rng.randi_range(int(chest_range[0]), int(chest_range[1]))
	res.chest_spawns = _pick_chest_spawns(rooms, spawn_room, chest_total, chest_excludes)
	res.corridor_tiles = _corridor_path.duplicate()

	_build_doors(res, rooms)
	_trap_rng_state = _rng.state
	_build_elevation(res)
	_build_hazards(res)

	return res

# ---------- hazards ----------

# Patches go in rooms (any rectangle inside one) or along straight corridor runs,
# never on the spawn, portals, door tiles, chests or ramps. Hazards only hurt, they
# never block, so connectivity and the door/key invariants are unaffected. Runs
# last so turning hazards on doesn't move anything an existing seed already has.
func _build_hazards(res: Result) -> void:
	var specs: Array = _config.get("hazards", [])
	if specs.is_empty():
		return

	var blocked: Dictionary = _reserved_tiles(res, res.ramps.keys())

	var room_pool: Array = []
	for room: Room in res.rooms:
		if not room.contains(res.spawn):
			room_pool.append(room)

	var corridor_pool: Array = []
	for key in res.corridor_tiles.keys():
		var t: Vector2i = key
		if not blocked.has(t) and not _room_of.has(t):
			corridor_pool.append(t)

	var taken: Dictionary = {}

	for spec_v in specs:
		var spec: Dictionary = spec_v
		var id: String = spec.get("id", "")
		if id.is_empty():
			push_warning("MapGenerator: hazard entry without id skipped")
			continue
		var count_range: Array = spec.get("count", [1, 2])
		var size_range: Array = spec.get("size", [1, 2])
		var corridor_chance: float = clampf(float(spec.get("corridor_chance", 0.3)), 0.0, 1.0)
		var count: int = _rng.randi_range(int(count_range[0]), int(count_range[1]))

		for _i in range(count):
			for _attempt in range(10):
				var in_corridor: bool = not corridor_pool.is_empty() and (room_pool.is_empty() or _rng.randf() < corridor_chance)
				var rect: Rect2i
				if in_corridor:
					rect = _corridor_hazard_rect(res, corridor_pool, size_range, blocked)
				elif not room_pool.is_empty():
					rect = _room_hazard_rect(room_pool, size_range)
				if not rect.has_area() or not _hazard_rect_free(res, rect, blocked, taken):
					continue
				for x in range(rect.position.x, rect.end.x):
					for y in range(rect.position.y, rect.end.y):
						taken[Vector2i(x, y)] = true
				res.hazard_patches.append({ "id": id, "rect": rect })
				break

func _room_hazard_rect(room_pool: Array, size_range: Array) -> Rect2i:
	var room: Room = room_pool[_rng.randi() % room_pool.size()]
	var w: int = mini(room.w, _rng.randi_range(int(size_range[0]), int(size_range[1])))
	var h: int = mini(room.h, _rng.randi_range(int(size_range[0]), int(size_range[1])))
	var x: int = _rng.randi_range(room.x, room.x + room.w - w)
	var y: int = _rng.randi_range(room.y, room.y + room.h - h)
	return Rect2i(x, y, w, h)

# A run along the start tile's corridor axis (a corner tile gives a 1x1 patch).
# Consecutive flat floor tiles share a level, so the run is one height.
func _corridor_hazard_rect(res: Result, corridor_pool: Array, size_range: Array, blocked: Dictionary) -> Rect2i:
	var start: Vector2i = corridor_pool[_rng.randi() % corridor_pool.size()]
	var axis: Vector2i = _straight_axis(res.floor_tiles, start)
	var length: int = _rng.randi_range(int(size_range[0]), int(size_range[1]))
	var run: int = 1

	if axis != Vector2i.ZERO:
		var cur: Vector2i = start + axis
		while run < length and res.floor_tiles.has(cur) and not blocked.has(cur) and not _room_of.has(cur):
			run += 1
			cur += axis

	var span: Vector2i = Vector2i.ONE + axis * (run - 1)
	return Rect2i(start, span)

func _hazard_rect_free(res: Result, rect: Rect2i, blocked: Dictionary, taken: Dictionary) -> bool:
	var level: int = res.level_at(rect.position)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var t := Vector2i(x, y)
			if not res.floor_tiles.has(t) or blocked.has(t) or taken.has(t) or res.level_at(t) != level:
				return false
	return true

# ---------- elevation ----------

# Ramps only go on straight one-wide corridor tiles whose removal splits the
# floor. A ramp can therefore never sit on a loop, so the flat areas between
# ramps form a tree and any choice of level per area is consistent: every pair
# of neighbouring floor tiles stays walkable both ways, which the door/region/key
# logic relies on. Runs after doors so door tiles stay flat and existing seeds
# keep their layout (all draws here come after every earlier one).
func _build_elevation(res: Result) -> void:
	for key in res.floor_tiles.keys():
		res.tile_level[key] = 0

	var ramp_range: Array = _config.get("ramp_count", [0, 0])
	if int(ramp_range[1]) <= 0:
		return

	var level_range: Array = _config.get("level_range", [-2, 2])
	var min_level: int = mini(0, int(level_range[0]))
	var max_level: int = maxi(0, int(level_range[1]))
	if min_level == max_level:
		push_warning("MapGenerator: level_range %s leaves no room for ramps" % str(level_range))
		return

	var target: int = _rng.randi_range(int(ramp_range[0]), int(ramp_range[1]))
	var ramp_axis: Dictionary = _pick_ramp_tiles(res, target)
	if ramp_axis.is_empty():
		return

	# Flat areas: the floor flooded without crossing a ramp.
	var area_of: Dictionary = _label_components(res.floor_tiles, ramp_axis, {})["of"]

	var links: Dictionary = {}
	for key in ramp_axis.keys():
		var t: Vector2i = key
		var axis: Vector2i = ramp_axis[t]
		for area: int in [area_of[t - axis], area_of[t + axis]]:
			if not links.has(area):
				links[area] = []
			links[area].append(t)

	# Walk the area tree out from the spawn, which stays at level 0. The first ramp
	# on each way out rolls up_chance; later ones keep the previous ramp's
	# direction with ramp_trend, so a route keeps descending (or climbing) instead
	# of see-sawing. It only turns back early when the level range runs out.
	var up_chance: float = clampf(float(_config.get("ramp_up_chance", 0.3)), 0.0, 1.0)
	var trend_chance: float = clampf(float(_config.get("ramp_trend", 0.85)), 0.0, 1.0)
	var root: int = area_of[res.spawn]
	var area_level: Dictionary = { root: 0 }
	var area_trend: Dictionary = { root: 0 }
	var queue: Array = [root]

	while not queue.is_empty():
		var area: int = queue.pop_front()
		var here: int = area_level[area]
		var trend: int = area_trend[area]
		for t: Vector2i in links.get(area, []):
			if res.ramps.has(t):
				continue
			var axis: Vector2i = ramp_axis[t]
			var across: Vector2i = axis if area_of[t - axis] == area else -axis
			var step: int
			if trend == 0:
				step = 1 if _rng.randf() < up_chance else -1
			else:
				step = trend if _rng.randf() < trend_chance else -trend
			if here + step > max_level or here + step < min_level:
				step = -step
			area_level[area_of[t + across]] = here + step
			area_trend[area_of[t + across]] = step
			res.tile_level[t] = mini(here, here + step)
			res.ramps[t] = { "dir": across if step > 0 else -across, "style": _pick_ramp_style() }
			queue.push_back(area_of[t + across])

	for key in area_of.keys():
		res.tile_level[key] = area_level.get(area_of[key], 0)

## tile -> axis for up to `target` ramp sites, each a bridge of the floor graph.
func _pick_ramp_tiles(res: Result, target: int) -> Dictionary:
	var keep_flat: Dictionary = _reserved_tiles(res, res.enemy_spawns)

	var axis_of: Dictionary = {}
	for key in res.corridor_tiles.keys():
		var t: Vector2i = key
		if keep_flat.has(t) or _room_of.has(t):
			continue
		var axis: Vector2i = _straight_axis(res.floor_tiles, t)
		if axis != Vector2i.ZERO:
			axis_of[t] = axis

	var cands: Array = _sorted_row_major(axis_of.keys())
	_shuffle_in_place(cands)

	# A straight tile splits the floor exactly when it is a cut tile.
	var cut: Dictionary = _cut_tiles() if target > 0 and not cands.is_empty() else {}
	# At least 2 keeps a flat tile between ramps for them to meet; more spreads
	# them out so a corridor doesn't stack slope after slope.
	var spacing: int = maxi(2, int(_config.get("ramp_spacing", 4)))
	var picked: Dictionary = {}
	for t: Vector2i in cands:
		if picked.size() >= target:
			break
		if not cut.has(t):
			continue
		var crowded: bool = false
		for p: Vector2i in picked.keys():
			if absi(p.x - t.x) + absi(p.y - t.y) < spacing:
				crowded = true
				break
		if crowded:
			continue
		picked[t] = axis_of[t]

	if picked.size() < target:
		push_warning("MapGenerator: placed %d of %d ramps (not enough non-loop straight corridor)" % [picked.size(), target])

	return picked

## Unit axis when the tile has exactly two floor neighbours facing each other, else ZERO.
func _straight_axis(floor_set: Dictionary, t: Vector2i) -> Vector2i:
	var nb: Array = []
	for d: Vector2i in CARDINALS:
		if floor_set.has(t + d):
			nb.append(d)
	if nb.size() != 2 or nb[0] != -nb[1]:
		return Vector2i.ZERO
	return Vector2i(absi(nb[0].x), absi(nb[0].y))

## Floor tiles whose removal disconnects the floor (iterative Tarjan), computed
## once: the floor is final by the time anything asks.
func _cut_tiles() -> Dictionary:
	if _cut_ready:
		return _cut
	_cut_ready = true
	var disc: Dictionary = {}
	var low: Dictionary = {}
	var timer: int = 0
	for root in _floor.keys():
		if disc.has(root):
			continue
		disc[root] = timer
		low[root] = timer
		timer += 1
		var root_children: int = 0
		var stack: Array = [[root, root, 0]]
		while not stack.is_empty():
			var frame: Array = stack[-1]
			var v: Vector2i = frame[0]
			var i: int = frame[2]
			if i < 4:
				frame[2] = i + 1
				var n: Vector2i = v + CARDINALS[i]
				if n == frame[1] or not _floor.has(n):
					continue
				if disc.has(n):
					low[v] = mini(low[v], disc[n])
				else:
					disc[n] = timer
					low[n] = timer
					timer += 1
					stack.append([n, v, 0])
			else:
				stack.pop_back()
				if stack.is_empty():
					continue
				var p: Vector2i = frame[1]
				low[p] = mini(low[p], low[v])
				if p == root:
					root_children += 1
				elif low[v] >= disc[p]:
					_cut[p] = true
		if root_children > 1:
			_cut[root] = true
	return _cut

func _pick_ramp_style() -> String:
	var style: String = _config.get("ramp_style", "mixed")
	if style == "ramp" or style == "stairs":
		return style
	return "stairs" if _rng.randf() < 0.5 else "ramp"

# ---------- doors, locks and keys ----------

const CARDINALS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# Runs the whole door pipeline. Order matters: candidates define where the floor
# graph may be cut, the cut defines regions, only bridges of the region graph may
# be locked, and keys are sited strictly in the pre-lock reachable set.
func _build_doors(res: Result, rooms: Array) -> void:
	var cands: Array = _collect_door_candidates(rooms, res.floor_tiles)
	if cands.is_empty():
		return

	var built: Dictionary = _build_regions(res.floor_tiles, cands)
	var region_of: Dictionary = built["region_of"]
	var regions: Array = built["regions"]
	var edges: Array = _build_edges(cands, region_of)
	var bridges: Dictionary = _find_bridges(regions.size(), edges)

	var locks: Array = _assign_door_locks(res, rooms, regions, region_of, edges, bridges)
	_assign_chest_locks(res, regions)
	_assign_doors(res, cands, edges, locks)

# Door ids come from tile coordinates, never from placement order, so they stay
# stable across regeneration — unlike the positional chest ids.
func _door_key(a: Vector2i, b: Vector2i) -> String:
	var lo: Vector2i = a
	if b.y < a.y or (b.y == a.y and b.x < a.x):
		lo = b
	var axis: String = "x" if a.x != b.x else "z"
	return "door_%d_%d_%s" % [lo.x, lo.y, axis]

## Tiles nothing else may go on: spawn, portals, chests, door sides, plus `extra`.
func _reserved_tiles(res: Result, extra: Array) -> Dictionary:
	var reserved: Dictionary = {}
	for t: Vector2i in [res.spawn, res.return_tile] + res.chest_spawns + extra:
		reserved[t] = true
	if res.has_end:
		reserved[res.end_tile] = true
	for entry: Dictionary in res.door_spawns:
		reserved[entry["a"]] = true
		reserved[entry["b"]] = true
	return reserved

func _room_boundary_tiles(r: Room) -> Array:
	var tiles: Array = []
	for x in range(r.x, r.x + r.w):
		tiles.append(Vector2i(x, r.y))
		if r.h > 1:
			tiles.append(Vector2i(x, r.y + r.h - 1))
	for y in range(r.y + 1, r.y + r.h - 1):
		tiles.append(Vector2i(r.x, y))
		if r.w > 1:
			tiles.append(Vector2i(r.x + r.w - 1, y))
	return tiles

# Splits one side's entrance tiles into maximal contiguous runs along the axis
# perpendicular to the side.
func _split_runs(pairs: Array, d: Vector2i) -> Array:
	var by_coord: Dictionary = {}
	for p: Dictionary in pairs:
		var t: Vector2i = p["t"]
		by_coord[t.y if d.x != 0 else t.x] = p

	var keys: Array = by_coord.keys()
	keys.sort()

	var runs: Array = []
	var current: Array = []
	var prev: int = 0

	for k: int in keys:
		if current.is_empty() or k == prev + 1:
			current.append(by_coord[k])
		else:
			runs.append(current)
			current = [by_coord[k]]
		prev = k

	if not current.is_empty():
		runs.append(current)

	return runs

# Only width-1 openings become doors. A wider run is an archway: not cut, not
# doored, never lockable — which keeps one door equal to one panel with one id.
func _collect_door_candidates(rooms: Array, floor_set: Dictionary) -> Array:
	var room_of: Dictionary = _room_of
	var cands: Dictionary = {}
	var max_width: int = int(_config.get("max_door_width", 1))

	for i in range(rooms.size()):
		var r: Room = rooms[i]
		var by_side: Dictionary = {}

		for t: Vector2i in _room_boundary_tiles(r):
			for d: Vector2i in CARDINALS:
				var o: Vector2i = t + d
				if not floor_set.has(o):
					continue
				if room_of.get(o, -1) == i:
					continue
				if not by_side.has(d):
					by_side[d] = []
				by_side[d].append({ "t": t, "o": o })

		if by_side.is_empty():
			push_warning("MapGenerator: room %d has no entrance" % i)
			continue

		for d: Vector2i in by_side.keys():
			for run: Array in _split_runs(by_side[d], d):
				if run.size() > max_width:
					continue
				for pair: Dictionary in run:
					var id: String = _door_key(pair["t"], pair["o"])
					if cands.has(id):
						continue
					cands[id] = {
						"id": id, "inside": pair["t"], "outside": pair["o"],
						"kind": "room", "room_idx": i,
					}

	for pick: Dictionary in _corridor_chokepoints(floor_set, room_of):
		var t: Vector2i = pick["tile"]
		var o: Vector2i = t + pick["axis"]
		var id: String = _door_key(t, o)
		if cands.has(id):
			continue
		cands[id] = { "id": id, "inside": t, "outside": o, "kind": "corridor", "room_idx": -1 }

	return cands.values()

# One candidate per maximal straight corridor run, not one per tile: the per-tile
# version yields thousands of candidates and near-single-tile regions, plus a
# redundant second door right outside every room entrance.
func _corridor_chokepoints(floor_set: Dictionary, room_of: Dictionary) -> Array:
	var straight: Dictionary = {}

	for key in _corridor_path.keys():
		var t: Vector2i = key
		if room_of.has(t):
			continue
		var axis: Vector2i = _straight_axis(floor_set, t)
		if axis != Vector2i.ZERO:
			straight[t] = axis

	var seen: Dictionary = {}
	var picks: Array = []

	for key in _sorted_row_major(straight.keys()):
		var start: Vector2i = key
		if seen.has(start):
			continue
		var axis: Vector2i = straight[start]
		var run: Array = [start]
		seen[start] = true

		for step: Vector2i in [axis, -axis]:
			var cur: Vector2i = start + step
			while straight.has(cur) and straight[cur] == axis and not seen.has(cur):
				seen[cur] = true
				if step == axis:
					run.append(cur)
				else:
					run.push_front(cur)
				cur += step

		if run.size() < 3:
			continue

		var mid: Vector2i = run[run.size() / 2]
		if room_of.has(mid + axis):
			continue
		picks.append({ "tile": mid, "axis": axis })

	return picks

# Floods the floor graph while refusing to step across a candidate threshold, so
# each region is a section of the dungeon a door can seal off.
func _build_regions(floor_set: Dictionary, cands: Array) -> Dictionary:
	var cut: Dictionary = {}
	for c: Dictionary in cands:
		cut[_door_key(c["inside"], c["outside"])] = true

	var labelled: Dictionary = _label_components(floor_set, {}, cut)
	var regions: Array = []
	for idx in range(int(labelled["count"])):
		regions.append({ "id": idx, "chests": [], "enemies": [] })

	return { "region_of": labelled["of"], "regions": regions }

## Labels the connected parts of `tiles` without entering `skip` tiles or stepping
## across a `cut` threshold (keyed by _door_key). Returns {of: tile -> index, count}.
func _label_components(tiles: Dictionary, skip: Dictionary, cut: Dictionary) -> Dictionary:
	var label: Dictionary = {}
	var count: int = 0
	for key in tiles.keys():
		if skip.has(key) or label.has(key):
			continue
		label[key] = count
		var stack: Array = [key]
		while not stack.is_empty():
			var t: Vector2i = stack.pop_back()
			for d: Vector2i in CARDINALS:
				var n: Vector2i = t + d
				if not tiles.has(n) or skip.has(n) or label.has(n):
					continue
				if not cut.is_empty() and cut.has(_door_key(t, n)):
					continue
				label[n] = count
				stack.push_back(n)
		count += 1
	return { "of": label, "count": count }

# A threshold whose two sides are the same region is a loop, and two thresholds
# joining the same pair of regions are a way around each other. Neither may be
# locked, so both are marked unlockable before bridge detection even runs.
func _build_edges(cands: Array, region_of: Dictionary) -> Array:
	var edges: Array = []
	var multiplicity: Dictionary = {}

	for c: Dictionary in cands:
		var ra: int = region_of.get(c["inside"], -1)
		var rb: int = region_of.get(c["outside"], -1)
		var edge: Dictionary = {
			"id": c["id"], "ra": ra, "rb": rb,
			"kind": c["kind"], "room_idx": c["room_idx"],
			"lockable": ra >= 0 and rb >= 0 and ra != rb,
		}
		if edge["lockable"]:
			var pk: String = "%d_%d" % [mini(ra, rb), maxi(ra, rb)]
			multiplicity[pk] = int(multiplicity.get(pk, 0)) + 1
		edges.append(edge)

	for edge: Dictionary in edges:
		if not edge["lockable"]:
			continue
		var pk: String = "%d_%d" % [mini(edge["ra"], edge["rb"]), maxi(edge["ra"], edge["rb"])]
		if int(multiplicity[pk]) > 1:
			edge["lockable"] = false

	return edges

# Iterative Tarjan. Skips the traversing EDGE INDEX rather than the parent
# vertex: skipping by vertex reports both of two parallel edges as bridges, which
# is exactly the two-entrance room the player would walk around.
func _find_bridges(region_count: int, edges: Array) -> Dictionary:
	var adj: Array = _region_adjacency(region_count, edges)

	var disc: Array = []
	var low: Array = []
	for _i in range(region_count):
		disc.append(-1)
		low.append(-1)

	var bridges: Dictionary = {}
	var timer: int = 0

	for start in range(region_count):
		if disc[start] != -1:
			continue
		disc[start] = timer
		low[start] = timer
		timer += 1
		var stack: Array = [[start, -1, 0]]

		while not stack.is_empty():
			var frame: Array = stack[stack.size() - 1]
			var node: int = frame[0]
			var cursor: int = frame[2]

			if cursor < adj[node].size():
				frame[2] = cursor + 1
				var link: Dictionary = adj[node][cursor]
				if link["edge"] == frame[1]:
					continue
				var to: int = link["to"]
				if disc[to] == -1:
					disc[to] = timer
					low[to] = timer
					timer += 1
					stack.append([to, link["edge"], 0])
				else:
					low[node] = mini(low[node], disc[to])
			else:
				stack.pop_back()
				if stack.is_empty():
					continue
				var parent: int = stack[stack.size() - 1][0]
				low[parent] = mini(low[parent], low[node])
				if low[node] > disc[parent]:
					bridges[frame[1]] = true

	return bridges

## region -> [{to, edge}] over the edges joining two different regions.
func _region_adjacency(region_count: int, edges: Array) -> Array:
	var adj: Array = []
	for _i in range(region_count):
		adj.append([])
	for i in range(edges.size()):
		var e: Dictionary = edges[i]
		if e["ra"] < 0 or e["rb"] < 0 or e["ra"] == e["rb"]:
			continue
		adj[e["ra"]].append({ "to": e["rb"], "edge": i })
		adj[e["rb"]].append({ "to": e["ra"], "edge": i })
	return adj

func _region_path_edges(from_region: int, to_region: int, region_count: int, edges: Array) -> Dictionary:
	var path: Dictionary = {}
	if from_region < 0 or to_region < 0 or from_region == to_region:
		return path

	var adj: Array = _region_adjacency(region_count, edges)

	var came_from: Dictionary = { from_region: -1 }
	var queue: Array = [from_region]
	var head: int = 0

	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if node == to_region:
			break
		for link: Dictionary in adj[node]:
			if came_from.has(link["to"]):
				continue
			came_from[link["to"]] = link["edge"]
			queue.append(link["to"])

	if not came_from.has(to_region):
		return path

	var cur: int = to_region
	while cur != from_region:
		var edge_idx: int = came_from[cur]
		if edge_idx < 0:
			break
		path[edge_idx] = true
		var e: Dictionary = edges[edge_idx]
		cur = e["ra"] if e["rb"] == cur else e["rb"]

	return path

func _pick_region_room(region_idx: int, rooms: Array, region_of: Dictionary) -> int:
	var found: Array = []

	for i in range(rooms.size()):
		var r: Room = rooms[i]
		var hit: bool = false
		for x in range(r.x, r.x + r.w):
			for y in range(r.y, r.y + r.h):
				if region_of.get(Vector2i(x, y), -1) == region_idx:
					hit = true
					break
			if hit:
				break
		if hit:
			found.append(i)

	if found.is_empty():
		return -1

	return found[_rng.randi() % found.size()]

# A locked door has to be worth opening, so the region behind it gets a chest if
# it has none. Constrained to tiles actually inside that region, or the "reward"
# could sit on the wrong side of the lock.
func _ensure_region_chest(res: Result, regions: Array, region_idx: int, room: Room, region_of: Dictionary) -> bool:
	if not regions[region_idx]["chests"].is_empty():
		return true

	var taken: Dictionary = _reserved_tiles(res, res.enemy_spawns)

	var options: Array = []
	for x in range(room.x, room.x + room.w):
		for y in range(room.y, room.y + room.h):
			var t := Vector2i(x, y)
			if taken.has(t) or _corridor_path.has(t):
				continue
			if region_of.get(t, -1) != region_idx:
				continue
			options.append(t)

	while not options.is_empty():
		var pick: int = _rng.randi() % options.size()
		var tile: Vector2i = options[pick]
		if _chest_blocks(tile, res.chest_spawns, res.spawn):
			options.remove_at(pick)
			continue
		var idx: int = res.chest_spawns.size()
		res.chest_spawns.append(tile)
		res.reward_chests.append(idx)
		regions[region_idx]["chests"].append(idx)
		return true

	return false

# Chooses a container to hold one key. Callers pass only regions that are
# reachable without the lock this key opens, which is what keeps the dungeon
# completable.
func _pick_key_site(res: Result, regions: Array, region_ids: Array, exclude_chests: Dictionary, enemy_chance: float) -> Dictionary:
	var chests: Array = []
	var enemies: Array = []

	for region_idx in region_ids:
		for idx: int in regions[region_idx]["chests"]:
			if exclude_chests.has(idx) or res.chest_locks.has(idx):
				continue
			chests.append(idx)
		for idx: int in regions[region_idx]["enemies"]:
			enemies.append(idx)

	var fresh_chests: Array = chests.filter(func(i: int) -> bool: return not res.chest_keys.has(i))
	var fresh_enemies: Array = enemies.filter(func(i: int) -> bool: return not res.enemy_keys.has(i))

	var chest_pool: Array = fresh_chests if not fresh_chests.is_empty() else chests
	var enemy_pool: Array = fresh_enemies if not fresh_enemies.is_empty() else enemies

	var want_enemy: bool = _rng.randf() < enemy_chance and not enemy_pool.is_empty()
	if not want_enemy and chest_pool.is_empty():
		want_enemy = not enemy_pool.is_empty()

	if want_enemy:
		return { "kind": "enemy", "index": enemy_pool[_rng.randi() % enemy_pool.size()] }

	if chest_pool.is_empty():
		return {}

	return { "kind": "chest", "index": chest_pool[_rng.randi() % chest_pool.size()] }

func _register_key(res: Result, site: Dictionary, key_id: String, key_name: String) -> void:
	var bucket: Dictionary = res.enemy_keys if site["kind"] == "enemy" else res.chest_keys
	var idx: int = site["index"]
	if not bucket.has(idx):
		bucket[idx] = []
	bucket[idx].append({ "id": key_id, "name": key_name })

# Frontier walk outward from the spawn region. A lock is only ever placed on a
# bridge, and its key only ever inside the region set already reachable at that
# moment — so by induction every lock is openable in placement order and the map
# is always completable. The first eligible bridge on the spawn -> exit path is
# locked deliberately, so the feature actually gates progression.
func _assign_door_locks(res: Result, rooms: Array, regions: Array, region_of: Dictionary, edges: Array, bridges: Dictionary) -> Array:
	var spawn_region: int = region_of.get(res.spawn, -1)
	if spawn_region < 0:
		return []

	if _map_id.is_empty():
		push_error("MapGenerator: no map_id, refusing to mint keys with an empty namespace")
		return []

	for idx in range(res.chest_spawns.size()):
		var r: int = region_of.get(res.chest_spawns[idx], -1)
		if r >= 0:
			regions[r]["chests"].append(idx)

	for idx in range(res.enemy_spawns.size()):
		var r: int = region_of.get(res.enemy_spawns[idx], -1)
		if r >= 0:
			regions[r]["enemies"].append(idx)

	for region: Dictionary in regions:
		region["depth"] = 0

	var main_path: Dictionary = {}
	if res.has_end:
		main_path = _region_path_edges(spawn_region, region_of.get(res.end_tile, -1), regions.size(), edges)

	var budget: int = int(_config.get("max_locked_doors", 3))
	var chance: float = clampf(float(_config.get("door_lock_chance", 0.35)), 0.0, 1.0)
	var enemy_chance: float = clampf(float(_config.get("key_enemy_drop_chance", 0.0)), 0.0, 1.0)

	var reachable: Dictionary = { spawn_region: true }
	var resolved: Dictionary = {}
	var locks: Array = []
	var ordinal: int = 0
	var forced_main: bool = false

	while true:
		var frontier: Array = []
		for i in range(edges.size()):
			if resolved.has(i):
				continue
			var e: Dictionary = edges[i]
			if e["ra"] < 0 or e["rb"] < 0 or e["ra"] == e["rb"]:
				continue
			if reachable.has(e["ra"]) == reachable.has(e["rb"]):
				continue
			frontier.append(i)

		if frontier.is_empty():
			break

		var pick: int = -1
		if not forced_main:
			for i: int in frontier:
				if main_path.has(i) and bridges.has(i) and edges[i]["lockable"]:
					pick = i
					break
		if pick < 0:
			pick = frontier[_rng.randi() % frontier.size()]

		var edge: Dictionary = edges[pick]
		var old_r: int = edge["ra"] if reachable.has(edge["ra"]) else edge["rb"]
		var new_r: int = edge["rb"] if old_r == edge["ra"] else edge["ra"]
		var eligible: bool = edge["lockable"] and bridges.has(pick) and locks.size() < budget
		var want_main: bool = eligible and not forced_main and main_path.has(pick)
		var do_lock: bool = eligible and (want_main or _rng.randf() < chance)

		if do_lock:
			var guard_room: int = _pick_region_room(new_r, rooms, region_of)
			var site: Dictionary = _pick_key_site(res, regions, reachable.keys(), {}, enemy_chance)

			if guard_room < 0 or site.is_empty() or not _ensure_region_chest(res, regions, new_r, rooms[guard_room], region_of):
				do_lock = false
			else:
				var kid: String = KeyFactory.key_id(_map_id, edge["id"])
				var kname: String = KeyFactory.key_name(ordinal)
				_register_key(res, site, kid, kname)
				locks.append({
					"id": edge["id"], "region": new_r,
					"key_id": kid, "key_name": kname,
					"seal_name": KeyFactory.seal_word(ordinal),
				})
				ordinal += 1
				if want_main:
					forced_main = true

		regions[new_r]["depth"] = int(regions[old_r]["depth"]) + (1 if do_lock else 0)
		reachable[new_r] = true
		resolved[pick] = true

	if locks.size() < budget:
		push_warning("MapGenerator: placed %d/%d locked doors (no further bridge candidates)" % [locks.size(), budget])

	return locks

# A locked chest never holds a door key and never sits behind a locked door, so
# it can only ever add a short detour, never a dependency chain.
func _assign_chest_locks(res: Result, regions: Array) -> void:
	var max_locked: int = int(_config.get("max_locked_chests", 0))
	if max_locked <= 0:
		return

	var chance: float = clampf(float(_config.get("chest_lock_chance", 0.25)), 0.0, 1.0)
	var enemy_chance: float = clampf(float(_config.get("key_enemy_drop_chance", 0.0)), 0.0, 1.0)

	var open_regions: Array = []
	var region_of_chest: Dictionary = {}

	for region: Dictionary in regions:
		if int(region.get("depth", 0)) != 0:
			continue
		open_regions.append(region["id"])
		for idx: int in region["chests"]:
			region_of_chest[idx] = region["id"]

	var locked: int = 0
	var ordinal: int = 0

	for idx in range(res.chest_spawns.size()):
		if locked >= max_locked:
			break
		if res.chest_keys.has(idx) or res.reward_chests.has(idx):
			continue
		if not region_of_chest.has(idx):
			continue
		if _rng.randf() >= chance:
			continue

		var site: Dictionary = _pick_key_site(res, regions, open_regions, { idx: true }, enemy_chance)
		if site.is_empty():
			continue

		var kid: String = KeyFactory.key_id(_map_id, "chest_%02d" % idx)
		var kname: String = KeyFactory.key_name(ordinal + 3)
		_register_key(res, site, kid, kname)
		res.chest_locks[idx] = { "key_id": kid, "key_name": kname, "trap_id": "" }
		ordinal += 1
		locked += 1

# Locked thresholds are kept unconditionally. The rest are rolled per kind, then
# capped round-robin by region so density stays spatially even instead of
# exhausting the budget on the first rooms of a chain.
func _assign_doors(res: Result, cands: Array, edges: Array, locks: Array) -> void:
	var lock_by_id: Dictionary = {}
	for l: Dictionary in locks:
		lock_by_id[l["id"]] = l

	var edge_by_id: Dictionary = {}
	for e: Dictionary in edges:
		edge_by_id[e["id"]] = e

	var door_chance: float = clampf(float(_config.get("door_chance", 0.30)), 0.0, 1.0)
	var corridor_chance: float = clampf(float(_config.get("corridor_door_chance", 0.12)), 0.0, 1.0)
	var max_doors: int = int(_config.get("max_doors", 12))
	var trap_chance: float = clampf(float(_config.get("door_trap_chance", 0.04)), 0.0, 1.0)
	var max_trapped: int = int(_config.get("max_trapped_doors", 2))

	var locked_first: Array = []
	var rest: Array = []
	var room_used: Dictionary = {}

	for c: Dictionary in cands:
		if not lock_by_id.has(c["id"]):
			continue
		locked_first.append(c)
		if c["kind"] == "room":
			room_used[c["room_idx"]] = true

	for c: Dictionary in cands:
		if lock_by_id.has(c["id"]):
			continue
		if c["kind"] == "room":
			if room_used.has(c["room_idx"]) or _rng.randf() >= door_chance:
				continue
			room_used[c["room_idx"]] = true
		elif _rng.randf() >= corridor_chance:
			continue
		rest.append(c)

	var by_region: Dictionary = {}
	for c: Dictionary in rest:
		var r: int = edge_by_id[c["id"]]["ra"]
		if not by_region.has(r):
			by_region[r] = []
		by_region[r].append(c)

	var region_keys: Array = by_region.keys()
	region_keys.sort()

	var final: Array = locked_first.duplicate()
	var round_idx: int = 0

	while final.size() < max_doors:
		var added: bool = false
		for rk in region_keys:
			if final.size() >= max_doors:
				break
			var bucket: Array = by_region[rk]
			if round_idx < bucket.size():
				final.append(bucket[round_idx])
				added = true
		if not added:
			break
		round_idx += 1

	var trapped: int = 0

	for c: Dictionary in final:
		var lock: Dictionary = lock_by_id.get(c["id"], {})
		# Only whether it is trapped is decided here. Which trap is resolved in
		# _populate_doors, so generate() stays free of autoload dependencies and
		# can run headless.
		var is_trapped: bool = lock.is_empty() and trapped < max_trapped and _rng.randf() < trap_chance

		if is_trapped:
			trapped += 1

		res.door_spawns.append({
			"id": c["id"], "a": c["inside"], "b": c["outside"],
			"locked": not lock.is_empty(),
			"key_id": lock.get("key_id", ""),
			"key_name": lock.get("key_name", ""),
			"seal_name": lock.get("seal_name", ""),
			"trapped": is_trapped,
		})

## Every draw in this file must come from `_rng`, or the same seed stops
## producing the same map — and because enemy and chest state is keyed by
## positional index, a reshuffle rebinds saved state to the wrong objects.
func _shuffle_in_place(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _order_chain(rooms: Array, layout: String) -> Array:
	if layout == "branching":
		return rooms
	if layout == "maze":
		# Shuffled so the spanning chain weaves across the grid instead of
		# snaking row-by-row.
		var shuffled: Array = rooms.duplicate()
		_shuffle_in_place(shuffled)
		return shuffled
	# linear/mixed: chain rooms by distance from the first room so the path
	# progresses outward instead of jumping around.
	var origin: Vector2i = rooms[0].center()
	var sorted: Array = rooms.duplicate()
	sorted.sort_custom(func(a: Room, b: Room) -> bool:
		var da: int = absi(a.center().x - origin.x) + absi(a.center().y - origin.y)
		var db: int = absi(b.center().x - origin.x) + absi(b.center().y - origin.y)
		return da < db
	)
	return sorted

func _default_extras(layout: String) -> Array:
	match layout:
		"linear":  return [0, 0]
		"mixed":   return [1, 2]
		"maze":    return [3, 6]
		_:         return [1, 3]

func _default_branches(layout: String) -> Array:
	match layout:
		"linear":  return [1, 3]
		"mixed":   return [1, 2]
		"maze":    return [4, 8]
		_:         return [0, 0]

# Large rooms may get a grid of single-tile pillars: tiles at an odd offset from
# the centre on both axes, never on the outer ring. No two pillars touch, so the
# room stays one connected floor, and the centre (the spawn) stays clear.
func _add_pillars(rooms: Array) -> void:
	var chance: float = clampf(float(_config.get("pillar_chance", 0.3)), 0.0, 1.0)
	var min_size: int = maxi(5, int(_config.get("pillar_min_size", 5)))
	if chance <= 0.0:
		return
	for r: Room in rooms:
		if mini(r.w, r.h) < min_size or _rng.randf() >= chance:
			continue
		var c: Vector2i = r.center()
		for x in range(r.x + 1, r.x + r.w - 1):
			for y in range(r.y + 1, r.y + r.h - 1):
				if posmod(x - c.x, 2) == 1 and posmod(y - c.y, 2) == 1:
					_floor.erase(Vector2i(x, y))
					_corridor_path.erase(Vector2i(x, y))
					_cell[y * _width + x] = CELL_ROCK

func _add_branches(rooms: Array, count: int, curviness: float) -> void:
	if rooms.is_empty() or count <= 0:
		return
	for i in range(count):
		var parent: Room = rooms[_rng.randi() % rooms.size()]
		var direction: Vector2i = CARDINALS[_rng.randi() % 4]
		var length: int = _rng.randi_range(5, 14)
		var endpoint: Vector2i = parent.center() + direction * length
		endpoint.x = clampi(endpoint.x, 2, _width - 3)
		endpoint.y = clampi(endpoint.y, 2, _height - 3)
		# If the clamp collapsed the offset to zero, skip — would just retrace a corridor.
		if endpoint == parent.center():
			continue

		# The branch ends in a small room when one fits; otherwise its bare tip
		# becomes a preferred chest spot (see _pick_chest_spawns).
		var w: int = _rng.randi_range(3, 5)
		var h: int = _rng.randi_range(3, 5)
		var room := Room.new()
		room.x = clampi(endpoint.x - w / 2, 1, _width - w - 1)
		room.y = clampi(endpoint.y - h / 2, 1, _height - h - 1)
		room.w = w
		room.h = h
		var ok: bool = true
		for other: Room in rooms:
			if room.intersects(other):
				ok = false
				break
		if ok:
			_carve_room(room, rooms.size())
			rooms.append(room)
			endpoint = room.center()

		_carve_winding_corridor(parent.center(), endpoint, curviness)

func apply_to_scene(scene_root: Node, result: Result, tileset: String, return_map_id: String, end_map_id: String = "") -> void:
	var gridmap: GridMap = _find_gridmap(scene_root)
	if gridmap == null:
		push_error("MapGenerator: no GridMap child found in blueprint")
		return

	# Performance toggles. Both default to true because their cost on small
	# maps is negligible and the win on large maps is substantial.
	var bake_navmesh: bool = bool(_config.get("bake_navmesh", true))
	var merge_walls: bool = bool(_config.get("merge_walls", true))

	gridmap.mesh_library = TilesetRegistry.get_mesh_library(tileset, not merge_walls)
	gridmap.cell_size = Vector3(TilesetRegistry.CELL_SIZE, TilesetRegistry.CELL_SIZE, TilesetRegistry.CELL_SIZE)
	gridmap.cell_center_y = false
	# Larger octants = fewer chunks = less per-chunk overhead on huge sparse maps.
	# Each tile is 2x2 cells; aim for ~8 octants per axis.
	gridmap.cell_octant_size = clampi(maxi(_width, _height) / 4, 8, 32)
	# If we're baking a combined navmesh below, the per-cell stitching is wasted.
	gridmap.bake_navigation = not bake_navmesh
	gridmap.clear()

	# Each player tile (a, b) maps to a 2x2 block of GridMap cells, matching the
	# handcrafted starting_area convention: the player at world (a*2, 0, b*2) sits
	# at the +X +Z corner of cells (a*2-1..a*2, b*2-1..b*2). Walls override floor.
	# One GridMap y-layer per elevation level. Ramp tiles get no floor item;
	# their RampTile node is the surface.
	_levels = result.tile_level
	_ramps = result.ramps
	var ceiling: bool = bool(_config.get("ceiling", false))
	for cell_key in result.floor_tiles.keys():
		var tile: Vector2i = cell_key
		var level: int = _level(tile)
		if _ramps.has(tile):
			if ceiling:
				_set_ramp_ceiling(gridmap, tile, level, _ramps[tile]["dir"])
			continue
		_set_player_tile(gridmap, tile, TilesetRegistry.ITEM_FLOOR, level)
		if ceiling:
			_set_ceiling_tile(gridmap, tile, level)

	var wall_spans: Dictionary = _wall_spans(result)
	for cell_key in wall_spans.keys():
		_set_wall_column(gridmap, cell_key, wall_spans[cell_key])

	var bounds: Callable = _tile_bounds_resolver(gridmap)
	var door_nav: Dictionary = {}
	if bake_navmesh:
		door_nav = _build_combined_navmesh(scene_root, bounds, result.floor_tiles, result.door_spawns)
	if merge_walls:
		_build_merged_wall_colliders(scene_root, bounds, wall_spans)
	_build_merged_floor_colliders(scene_root, bounds, result.floor_tiles)
	_populate_ramps(scene_root, tileset, not bake_navmesh)
	_populate_hazards(scene_root, result)

	_populate_enemies(scene_root, result)
	_populate_chests(gridmap, result)
	_populate_doors(gridmap, result.door_spawns, door_nav)
	_populate_transition(gridmap, result.return_tile, return_map_id)
	if result.has_end and not end_map_id.is_empty():
		_populate_transition(gridmap, result.end_tile, end_map_id)

# Returns a Callable that, given a Rect of player tiles, computes the world-space
# bounding box matching what the GridMap actually renders. Reading the GridMap's
# `cell_center_x`/`z` flags here means merged colliders and baked navmeshes stay
# aligned with the visual cells even if the defaults differ or the blueprint
# scene overrides them.
func _tile_bounds_resolver(gridmap: GridMap) -> Callable:
	var cs_x: float = gridmap.cell_size.x
	var cs_z: float = gridmap.cell_size.z
	var ccx: bool = gridmap.cell_center_x
	var ccz: bool = gridmap.cell_center_z
	# Godot's `cell_center_x=true` shifts cell origins by +cs/2, so a cell at
	# coord c spans [c*cs, (c+1)*cs]. When false, the cell spans [c*cs - cs/2,
	# c*cs + cs/2]. Mismatching these offsets shifts colliders/navmesh by half
	# a cell on the corresponding axis.
	var x_lo_off: float = 0.0        if ccx else -cs_x * 0.5
	var x_hi_off: float = cs_x       if ccx else  cs_x * 0.5
	var z_lo_off: float = 0.0        if ccz else -cs_z * 0.5
	var z_hi_off: float = cs_z       if ccz else  cs_z * 0.5
	return func(rect: Rect) -> Dictionary:
		# Player tile (a, b) maps to GridMap cells at coords (a*2, b*2),
		# (a*2-1, b*2), (a*2, b*2-1), (a*2-1, b*2-1). So a rect of player tiles
		# from (rect.x, rect.y) to (rect.x+w-1, rect.y+h-1) spans cell coords
		# [rect.x*2-1, (rect.x+w-1)*2] × [rect.y*2-1, (rect.y+h-1)*2].
		var min_cx: int = rect.x * 2 - 1
		var max_cx: int = (rect.x + rect.w - 1) * 2
		var min_cz: int = rect.y * 2 - 1
		var max_cz: int = (rect.y + rect.h - 1) * 2
		return {
			"lo_x": float(min_cx) * cs_x + x_lo_off,
			"hi_x": float(max_cx) * cs_x + x_hi_off,
			"lo_z": float(min_cz) * cs_z + z_lo_off,
			"hi_z": float(max_cz) * cs_z + z_hi_off,
		}

# ---------- baked navmesh ----------

# Builds one NavigationMesh: flat floor greedily merged into rectangles per
# level, plus one sloped quad per ramp, so the navmesh has tens or hundreds of
# polygons instead of one-per-cell. NavigationAgent A* cost is roughly
# proportional to polygon count, so this is the dominant perf win for AI.
## Returns door id -> the NavigationRegion3D strip bridging that door, which the
## door toggles. Door tiles are kept out of the merged mesh so a closed door
## really splits the navmesh.
func _build_combined_navmesh(scene_root: Node, bounds: Callable, floor_tiles: Dictionary, doors: Array) -> Dictionary:
	var nav_region: NavigationRegion3D = scene_root if scene_root is NavigationRegion3D else null
	if nav_region == null:
		for child in scene_root.get_children():
			if child is NavigationRegion3D:
				nav_region = child
				break
	if nav_region == null:
		push_warning("MapGenerator: no NavigationRegion3D; navmesh bake skipped")
		return {}

	var door_sides: Dictionary = _door_tile_sides(doors)
	var main_tiles: Dictionary = floor_tiles.duplicate()
	for tile in door_sides.keys():
		main_tiles.erase(tile)

	# Flat tiles merge only within their own level; each ramp is its own sloped quad.
	var by_level: Dictionary = _flat_by_level(main_tiles)

	var rects: Array = []
	for level: int in by_level.keys():
		for rect: Rect in _greedy_rectangles(by_level[level]):
			rect.level = level
			rects.append(rect)

	for key in _ramps.keys():
		if not main_tiles.has(key):
			continue
		var ramp: Rect = _tile_rect(key)
		ramp.level = _level(key)
		ramp.ramp_dir = _ramps[key]["dir"]
		rects.append(ramp)

	# Godot merges navmesh edges by quantized endpoint POSITION, so coincident
	# corners already match. What does not match is a T-junction: a wide room
	# rect's edge spans straight past a 1-tile corridor rect's shorter edge, and
	# an edge pair only merges when both endpoints agree. So every rect edge has
	# to carry the boundary points its neighbours introduce along it, or a room
	# and the corridor leaving it stay unconnected and enemies cannot path out.
	var x_breaks: Dictionary = {}
	var z_breaks: Dictionary = {}

	for rect in rects:
		var x_hi: int = rect.x + rect.w
		var z_hi: int = rect.y + rect.h

		for z_line in [rect.y, z_hi]:
			if not x_breaks.has(z_line):
				x_breaks[z_line] = {}
			x_breaks[z_line][rect.x] = true
			x_breaks[z_line][x_hi] = true

		for x_line in [rect.x, x_hi]:
			if not z_breaks.has(x_line):
				z_breaks[x_line] = {}
			z_breaks[x_line][rect.y] = true
			z_breaks[x_line][z_hi] = true

	# Breaks are keyed by line only, so a rect can pick up a break from another
	# level's rect on the same line. That only adds a collinear vertex at its own
	# height, and vertices are interned by full position, so levels never fuse.
	var navmesh := NavigationMesh.new()
	var verts := PackedVector3Array()
	var index_of: Dictionary = {}

	for rect in rects:
		var b: Dictionary = bounds.call(rect)
		var x_hi: int = rect.x + rect.w
		var z_hi: int = rect.y + rect.h
		var poly := PackedInt32Array()

		# Winding: +x along the near edge, +z along the far side,
		# then back. Each side emits its start corner plus its interior breaks;
		# the next side emits the shared corner.
		for bx in _interior_breaks(x_breaks.get(rect.y, {}), rect.x, x_hi, false):
			poly.append(_intern_vertex(verts, index_of, _nav_point(rect, b, _axis_world(bx, rect.x, x_hi, b.lo_x, b.hi_x), b.lo_z)))

		for bz in _interior_breaks(z_breaks.get(x_hi, {}), rect.y, z_hi, false):
			poly.append(_intern_vertex(verts, index_of, _nav_point(rect, b, b.hi_x, _axis_world(bz, rect.y, z_hi, b.lo_z, b.hi_z))))

		for bx in _interior_breaks(x_breaks.get(z_hi, {}), rect.x, x_hi, true):
			poly.append(_intern_vertex(verts, index_of, _nav_point(rect, b, _axis_world(bx, rect.x, x_hi, b.lo_x, b.hi_x), b.hi_z)))

		for bz in _interior_breaks(z_breaks.get(rect.x, {}), rect.y, z_hi, true):
			poly.append(_intern_vertex(verts, index_of, _nav_point(rect, b, b.lo_x, _axis_world(bz, rect.y, z_hi, b.lo_z, b.hi_z))))

		navmesh.add_polygon(poly)

	navmesh.vertices = verts
	nav_region.navigation_mesh = navmesh

	return _build_door_navigation(nav_region, bounds, doors, door_sides)

const NAV_LIFT: float = 0.001

## Navmesh point just above the walkable surface; ramps interpolate uphill along their dir.
func _nav_point(rect: Rect, b: Dictionary, x: float, z: float) -> Vector3:
	var y: float = float(rect.level) * TilesetRegistry.LEVEL_HEIGHT + TilesetRegistry.FLOOR_THICKNESS + NAV_LIFT
	var d: Vector2i = rect.ramp_dir
	if d != Vector2i.ZERO:
		var t: float
		if d.x != 0:
			t = inverse_lerp(b.lo_x, b.hi_x, x)
			if d.x < 0:
				t = 1.0 - t
		else:
			t = inverse_lerp(b.lo_z, b.hi_z, z)
			if d.y < 0:
				t = 1.0 - t
		y += t * TilesetRegistry.LEVEL_HEIGHT
	return Vector3(x, y, z)

func _flat_nav_y(tile: Vector2i) -> float:
	return float(_level(tile)) * TilesetRegistry.LEVEL_HEIGHT + TilesetRegistry.FLOOR_THICKNESS + NAV_LIFT

# Half the gap left on each side of a door line. Total gap (1.0) must exceed the
# map's edge_connection_margin (0.25) so the two sides never auto-connect.
const DOOR_NAV_GAP: float = 0.5

## tile -> directions (Vector2i) in which that tile touches a door.
func _door_tile_sides(doors: Array) -> Dictionary:
	var sides: Dictionary = {}

	for entry in doors:
		var a: Vector2i = entry["a"]
		var b: Vector2i = entry["b"]

		if not sides.has(a):
			sides[a] = []
		if not sides.has(b):
			sides[b] = []

		sides[a].append(b - a)
		sides[b].append(a - b)

	return sides

## Each door tile becomes its own region, pulled back from its door line(s); they
## join the main mesh through edge connections. A disabled strip per door spans
## the gap and is enabled while the door is open.
func _build_door_navigation(nav_region: NavigationRegion3D, bounds: Callable, doors: Array, door_sides: Dictionary) -> Dictionary:
	var door_nav: Dictionary = {}

	if doors.is_empty():
		return door_nav

	var holder := Node3D.new()
	holder.name = "DoorNavigation"
	nav_region.add_child(holder)

	for tile in door_sides.keys():
		var b: Dictionary = _tile_world_bounds(bounds, tile)

		for dir: Vector2i in door_sides[tile]:
			if dir.x > 0:
				b.hi_x -= DOOR_NAV_GAP
			elif dir.x < 0:
				b.lo_x += DOOR_NAV_GAP
			elif dir.y > 0:
				b.hi_z -= DOOR_NAV_GAP
			elif dir.y < 0:
				b.lo_z += DOOR_NAV_GAP

		holder.add_child(_quad_region("DoorTile_%d_%d" % [tile.x, tile.y], b.lo_x, b.hi_x, b.lo_z, b.hi_z, _flat_nav_y(tile), true))

	# Both sides of a door are flat and share a level; ramps never touch door tiles.
	for entry in doors:
		var a: Vector2i = entry["a"]
		var dir: Vector2i = entry["b"] - a
		var ab: Dictionary = _tile_world_bounds(bounds, a)
		var y: float = _flat_nav_y(a)
		var strip: NavigationRegion3D

		if dir.x != 0:
			var line_x: float = ab.hi_x if dir.x > 0 else ab.lo_x
			strip = _quad_region("DoorStrip_" + str(entry["id"]), line_x - DOOR_NAV_GAP, line_x + DOOR_NAV_GAP, ab.lo_z, ab.hi_z, y, false)
		else:
			var line_z: float = ab.hi_z if dir.y > 0 else ab.lo_z
			strip = _quad_region("DoorStrip_" + str(entry["id"]), ab.lo_x, ab.hi_x, line_z - DOOR_NAV_GAP, line_z + DOOR_NAV_GAP, y, false)

		holder.add_child(strip)
		door_nav[entry["id"]] = strip

	return door_nav

func _tile_world_bounds(bounds: Callable, tile: Vector2i) -> Dictionary:
	return bounds.call(_tile_rect(tile))

func _tile_rect(t: Vector2i) -> Rect:
	var rect := Rect.new()
	rect.x = t.x
	rect.y = t.y
	rect.w = 1
	rect.h = 1
	return rect

func _quad_region(region_name: String, lo_x: float, hi_x: float, lo_z: float, hi_z: float, y: float, enabled: bool) -> NavigationRegion3D:
	var navmesh := NavigationMesh.new()
	navmesh.vertices = PackedVector3Array([
		Vector3(lo_x, y, lo_z),
		Vector3(hi_x, y, lo_z),
		Vector3(hi_x, y, hi_z),
		Vector3(lo_x, y, hi_z),
	])
	navmesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))

	var region := NavigationRegion3D.new()
	region.name = region_name
	region.navigation_mesh = navmesh
	region.enabled = enabled

	return region

## One side of a rectangle, as boundary indices: the start corner followed by any
## neighbour-introduced breaks strictly inside it. The end corner belongs to the
## next side. `reverse` walks the side backwards, so winding stays consistent.
func _interior_breaks(candidates: Dictionary, lo: int, hi: int, reverse: bool) -> Array:
	var inner: Array = []

	for key in candidates.keys():
		var value: int = key
		if value > lo and value < hi:
			inner.append(value)

	inner.sort()

	var points: Array = [hi] if reverse else [lo]

	if reverse:
		inner.reverse()

	points.append_array(inner)

	return points

## Maps a tile-boundary index on one axis to its world coordinate, using the
## rect's own already-resolved world span so cell centring stays consistent.
func _axis_world(boundary: int, lo: int, hi: int, lo_world: float, hi_world: float) -> float:
	if boundary <= lo:
		return lo_world
	if boundary >= hi:
		return hi_world

	var t: float = float(boundary - lo) / float(hi - lo)

	return lerpf(lo_world, hi_world, t)

func _intern_vertex(verts: PackedVector3Array, index_of: Dictionary, pos: Vector3) -> int:
	var key := Vector3i(roundi(pos.x * 100.0), roundi(pos.y * 100.0), roundi(pos.z * 100.0))

	if index_of.has(key):
		return index_of[key]

	var idx: int = verts.size()
	verts.append(pos)
	index_of[key] = idx

	return idx

# ---------- merged wall colliders ----------

# Replaces the per-cell wall collision (one StaticBody3D per wall cell) with
# a single StaticBody3D holding greedy-merged box shapes. For long stretches
# of wall this collapses ~30k colliders into a few hundred.
## wall_spans: tile -> Vector2i(bottom level, top level). Tiles merge only with
## others of the same span.
func _build_merged_wall_colliders(scene_root: Node, bounds: Callable, wall_spans: Dictionary) -> void:
	if wall_spans.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "MergedWalls"
	body.collision_layer = 1
	body.collision_mask = 0

	var by_span: Dictionary = {}
	for key in wall_spans.keys():
		var span: Vector2i = wall_spans[key]
		if not by_span.has(span):
			by_span[span] = {}
		by_span[span][key] = true

	var shapes: Dictionary = {}
	for span: Vector2i in by_span.keys():
		var bottom: float = float(span.x) * TilesetRegistry.LEVEL_HEIGHT
		var height: float = float(span.y - span.x) * TilesetRegistry.LEVEL_HEIGHT
		_add_boxes(body, bounds, by_span[span], bottom, height, shapes)
	scene_root.add_child(body)

# The player's ground probe reads these. Ground layer only: off the movement
# rays' mask (1) and the overworld enemies' mask, so neither is affected.
func _build_merged_floor_colliders(scene_root: Node, bounds: Callable, floor_tiles: Dictionary) -> void:
	var by_level: Dictionary = _flat_by_level(floor_tiles)
	if by_level.is_empty():
		return

	var body := StaticBody3D.new()
	body.name = "MergedFloors"
	body.collision_layer = TilesetRegistry.GROUND_LAYER
	body.collision_mask = 0

	var shapes: Dictionary = {}
	for level: int in by_level.keys():
		_add_boxes(body, bounds, by_level[level], float(level) * TilesetRegistry.LEVEL_HEIGHT, TilesetRegistry.FLOOR_THICKNESS, shapes)
	scene_root.add_child(body)

## One box per greedy rect, `height` tall from `bottom`, added straight to the
## body as shape owners (no node per box); equal sizes share one shape.
func _add_boxes(body: StaticBody3D, bounds: Callable, tiles: Dictionary, bottom: float, height: float, shapes: Dictionary) -> void:
	for rect: Rect in _greedy_rectangles(tiles):
		var b: Dictionary = bounds.call(rect)
		var size := Vector3(b.hi_x - b.lo_x, height, b.hi_z - b.lo_z)
		var box: BoxShape3D = shapes.get(size)
		if box == null:
			box = BoxShape3D.new()
			box.size = size
			shapes[size] = box
		var owner_id: int = body.create_shape_owner(body)
		body.shape_owner_add_shape(owner_id, box)
		body.shape_owner_set_transform(owner_id, Transform3D(Basis(), Vector3((b.lo_x + b.hi_x) * 0.5, bottom + height * 0.5, (b.lo_z + b.hi_z) * 0.5)))

## level -> {tile: true} for every non-ramp tile.
func _flat_by_level(tiles: Dictionary) -> Dictionary:
	var by_level: Dictionary = {}
	for key in tiles.keys():
		if _ramps.has(key):
			continue
		var level: int = _level(key)
		if not by_level.has(level):
			by_level[level] = {}
		by_level[level][key] = true
	return by_level

## tile -> Vector2i(bottom, top) in levels: at least from the lowest neighbouring
## floor up to a full wall above the highest (a ramp counts as both its levels),
## widened to even levels. Every wall piece then starts on an even level, so the
## texture lines up across neighbouring columns and no piece is ever squashed.
## The extra level goes below every adjacent floor or above the ceiling.
func _wall_spans(result: Result) -> Dictionary:
	var spans: Dictionary = {}
	for key in result.wall_tiles.keys():
		var w: Vector2i = key
		var lo: int = 1 << 30
		var hi: int = -(1 << 30)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n := Vector2i(w.x + dx, w.y + dy)
				if not result.floor_tiles.has(n):
					continue
				var level: int = result.level_at(n)
				lo = mini(lo, level)
				hi = maxi(hi, level + (1 if result.ramps.has(n) else 0))
		if lo > hi:
			lo = 0
			hi = 0
		var step: int = TilesetRegistry.WALL_LEVELS
		var top: int = hi + step
		spans[w] = Vector2i(lo - posmod(lo, step), top + posmod(-top, step))
	return spans

# ---------- greedy rectangle decomposition ----------

class Rect:
	var x: int
	var y: int
	var w: int
	var h: int
	var level: int = 0
	var ramp_dir: Vector2i = Vector2i.ZERO

# Classic tile-merging algorithm: walk tiles in row-major order; for each
# unprocessed tile, expand the rectangle right (same row only) while cells
# remain available, then expand down while every cell in the current x-range
# remains available. Produces an over-counted-but-correct decomposition into
# axis-aligned rectangles. Not optimal (an optimal partition is NP-hard) but
# linear and gets within ~1.5× of optimal on dungeon-shaped tilesets.
func _greedy_rectangles(tiles: Dictionary) -> Array:
	var rects: Array = []
	if tiles.is_empty():
		return rects
	var processed: Dictionary = {}
	for k in _sorted_row_major(tiles.keys()):
		var start: Vector2i = k
		if processed.has(start):
			continue
		# Expand right.
		var x_end: int = start.x
		while tiles.has(Vector2i(x_end + 1, start.y)) and not processed.has(Vector2i(x_end + 1, start.y)):
			x_end += 1
		# Expand down (only if every cell in x-range is still available).
		var y_end: int = start.y
		while true:
			var next_y: int = y_end + 1
			var row_ok: bool = true
			for tx in range(start.x, x_end + 1):
				var t := Vector2i(tx, next_y)
				if not tiles.has(t) or processed.has(t):
					row_ok = false
					break
			if not row_ok:
				break
			y_end = next_y
		for tx in range(start.x, x_end + 1):
			for ty in range(start.y, y_end + 1):
				processed[Vector2i(tx, ty)] = true
		var r := Rect.new()
		r.x = start.x
		r.y = start.y
		r.w = x_end - start.x + 1
		r.h = y_end - start.y + 1
		rects.append(r)
	return rects

## Unique tiles sorted by y, then x. Swapping the components lets the native
## Vector2i sort do it instead of a script comparator.
func _sorted_row_major(tiles: Array) -> Array:
	var swapped: Array = []
	for t: Vector2i in tiles:
		swapped.append(Vector2i(t.y, t.x))
	swapped.sort()
	for i in range(swapped.size()):
		var s: Vector2i = swapped[i]
		swapped[i] = Vector2i(s.y, s.x)
	return swapped

# ---------- cell placement ----------

func _set_player_tile(gridmap: GridMap, tile: Vector2i, item: int, y: int) -> void:
	var bx: int = tile.x * 2
	var bz: int = tile.y * 2
	gridmap.set_cell_item(Vector3i(bx,     y, bz),     item)
	gridmap.set_cell_item(Vector3i(bx - 1, y, bz),     item)
	gridmap.set_cell_item(Vector3i(bx,     y, bz - 1), item)
	gridmap.set_cell_item(Vector3i(bx - 1, y, bz - 1), item)

func _set_ceiling_tile(gridmap: GridMap, tile: Vector2i, level: int) -> void:
	_set_player_tile(gridmap, tile, TilesetRegistry.ITEM_CEILING, level + TilesetRegistry.CEILING_Y)

# Spans from _wall_spans are even-aligned, so full pieces fill them exactly.
func _set_wall_column(gridmap: GridMap, tile: Vector2i, span: Vector2i) -> void:
	for y in range(span.x, span.y, TilesetRegistry.WALL_LEVELS):
		_set_player_tile(gridmap, tile, TilesetRegistry.ITEM_WALL, y)

# The uphill half's ceiling sits a level higher. A wall block over the downhill
# half carries the lower ceiling and closes the step between the two; its upper
# level is above every ceiling around it. Its one visible face has no coplanar
# wall beside it, so its texture phase doesn't need to match the columns.
func _set_ramp_ceiling(gridmap: GridMap, tile: Vector2i, level: int, dir: Vector2i) -> void:
	var bx: int = tile.x * 2
	var bz: int = tile.y * 2
	for cx: int in [bx - 1, bx]:
		for cz: int in [bz - 1, bz]:
			var uphill: bool = (dir.x > 0 and cx == bx) or (dir.x < 0 and cx == bx - 1) \
				or (dir.y > 0 and cz == bz) or (dir.y < 0 and cz == bz - 1)
			if uphill:
				gridmap.set_cell_item(Vector3i(cx, level + 1 + TilesetRegistry.CEILING_Y, cz), TilesetRegistry.ITEM_CEILING)
			else:
				gridmap.set_cell_item(Vector3i(cx, level + TilesetRegistry.CEILING_Y, cz), TilesetRegistry.ITEM_WALL)

# ---------- internals ----------

func _carve_room(r: Room, idx: int) -> void:
	for y in range(r.y, r.y + r.h):
		for x in range(r.x, r.x + r.w):
			_floor[Vector2i(x, y)] = true
			_room_of[Vector2i(x, y)] = idx
			_cell[y * _width + x] = idx

const MAX_CORRIDOR_LEG: int = 8

func _carve_winding_corridor(a: Vector2i, b: Vector2i, curviness: float) -> void:
	# Subdivide long corridors into legs between waypoints about
	# MAX_CORRIDOR_LEG tiles apart. Each intermediate waypoint gets a small
	# perpendicular offset, so a long corridor turns into a wandering zigzag
	# instead of a single boring straight line.
	var dx: int = b.x - a.x
	var dy: int = b.y - a.y
	var max_span: int = maxi(absi(dx), absi(dy))

	# Rooms the corridor starts or ends in are free to cross.
	var ends: Dictionary = {}
	for p: Vector2i in [a, b]:
		var c: int = _cell[p.y * _width + p.x]
		if c >= 0:
			ends[c] = true

	var segments: int = maxi(1, (max_span + MAX_CORRIDOR_LEG - 1) / MAX_CORRIDOR_LEG)
	# Short corridors still get an optional one-time curve so they don't all
	# look identical.
	if segments == 1 and curviness > 0.0 and max_span >= 4 and _rng.randf() < curviness:
		segments = 2

	if segments == 1:
		_carve_corridor(a, b, ends, 4)
		return

	var prev: Vector2i = a
	var heading: int = 4
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var pt := Vector2i(
			int(lerpf(float(a.x), float(b.x), t)),
			int(lerpf(float(a.y), float(b.y), t))
		)
		var offset: int = _rng.randi_range(-3, 3)
		if absi(dx) >= absi(dy):
			pt.y += offset
		else:
			pt.x += offset
		pt.x = clampi(pt.x, 1, _width - 2)
		pt.y = clampi(pt.y, 1, _height - 2)
		heading = _carve_corridor(prev, pt, ends, heading)
		prev = pt
	_carve_corridor(prev, b, ends, heading)

# One leg, routed by _route. The coin flip that used to pick which way the L
# bends now only breaks ties between equally good routes. `heading` is the
# CARDINALS index the previous leg arrived with (4 = none): the leg may not
# start by doubling back, which would leave the overshoot as a dead-end stub.
# Returns the heading this leg arrives with.
func _carve_corridor(a: Vector2i, b: Vector2i, ends: Dictionary, heading: int) -> int:
	var x_first: bool = _rng.randi() % 2 == 0
	var path: Array = _route(a, b, ends, x_first, heading)
	if path.is_empty():
		push_warning("MapGenerator: corridor search gave up between %s and %s; carving a plain L" % [a, b])
		path = _l_path(a, b, x_first)
	for p: Vector2i in path:
		_mark_corridor(p)
	if path.size() < 2:
		return heading
	return CARDINALS.find(path[-1] - path[-2])

func _l_path(a: Vector2i, b: Vector2i, x_first: bool) -> Array:
	var path: Array = [a]
	var cur := a
	for leg in range(2):
		if (leg == 0) == x_first:
			while cur.x != b.x:
				cur.x += signi(b.x - cur.x)
				path.append(cur)
		else:
			while cur.y != b.y:
				cur.y += signi(b.y - cur.y)
				path.append(cur)
	return path

func _mark_corridor(p: Vector2i) -> void:
	_floor[p] = true
	_corridor_path[p] = true
	var i: int = p.y * _width + p.x
	if _cell[i] == CELL_ROCK:
		_cell[i] = CELL_CORRIDOR

# ---------- corridor routing ----------

# Per-step costs. A new tile next to existing floor across the direction of
# travel is what made corridors run two wide or hug room walls, so it costs far
# more than a detour; walking an existing corridor is cheap, so a corridor joins
# one instead of laying a parallel copy beside it.
const ROUTE_REUSE: float = 0.75
const ROUTE_TOUCH: float = 8.0
const ROUTE_NEAR: float = 1.0
const ROUTE_ROOM: float = 3.0
const ROUTE_CORNER: float = 4.0
const ROUTE_TURN: float = 0.6
const ROUTE_MAX_EXPANSIONS: int = 50000
const OPPOSITE: Array[int] = [1, 0, 3, 2]

# _cell: one entry per tile, CELL_ROCK, CELL_CORRIDOR or the room's index.
const CELL_ROCK: int = -1
const CELL_CORRIDOR: int = -2
var _cell: PackedInt32Array = PackedInt32Array()
var _route_rooms: Array = []
# Search state per (tile, arrival direction); index = tile * 5 + dir, dir 4 = start.
var _route_g: PackedFloat64Array = PackedFloat64Array()
var _route_parent: PackedInt32Array = PackedInt32Array()
var _route_seen: PackedInt32Array = PackedInt32Array()
var _route_done: PackedInt32Array = PackedInt32Array()
var _route_id: int = 0
var _heap_p: PackedFloat64Array = PackedFloat64Array()
var _heap_s: PackedInt32Array = PackedInt32Array()
var _heap_n: int = 0

func _init_routing(rooms: Array) -> void:
	_route_rooms = rooms
	var tiles: int = _width * _height
	_cell.resize(tiles)
	_cell.fill(CELL_ROCK)
	_route_g.resize(tiles * 5)
	_route_parent.resize(tiles * 5)
	_route_seen.resize(tiles * 5)
	_route_seen.fill(0)
	_route_done.resize(tiles * 5)
	_route_done.fill(0)

## Cheapest 4-connected path a -> b (both included) inside the map border, by
## weighted A* over (tile, arrival direction) so turns can be priced. Returns []
## if the search gives up. Step costs: existing corridor ROUTE_REUSE; a room the
## corridor starts or ends in 1, any other room ROUTE_ROOM; a new tile 1 plus
## ROUTE_TOUCH per floor tile beside it; plus ROUTE_CORNER to cross a room's edge
## at a corner tile and ROUTE_TURN per turn. `heading` (4 = none) is the
## direction already travelling at `a`: no reversing out of it, turns cost.
func _route(a: Vector2i, b: Vector2i, ends: Dictionary, x_first: bool, heading: int) -> Array:
	if a == b:
		return [a]
	var w: int = _width
	_route_id += 1
	_heap_n = 0
	var start: int = (a.y * w + a.x) * 5 + heading
	_route_seen[start] = _route_id
	_route_g[start] = 0.0
	_route_parent[start] = -1
	_heap_push(float(absi(b.x - a.x) + absi(b.y - a.y)), start)

	var found: int = -1
	var expansions: int = 0
	while _heap_n > 0:
		var s: int = _heap_pop()
		if _route_done[s] == _route_id:
			continue
		_route_done[s] = _route_id
		var tile: int = s / 5
		var dir: int = s % 5
		var x: int = tile % w
		var y: int = tile / w
		if x == b.x and y == b.y:
			found = s
			break
		expansions += 1
		if expansions > ROUTE_MAX_EXPANSIONS:
			break
		var here: int = _cell[tile]
		var gs: float = _route_g[s]
		for nd in range(4):
			if dir < 4 and nd == OPPOSITE[dir]:
				continue
			var d: Vector2i = CARDINALS[nd]
			var nx: int = x + d.x
			var ny: int = y + d.y
			if nx < 1 or ny < 1 or nx > w - 2 or ny > _height - 2:
				continue
			var ns: int = (ny * w + nx) * 5 + nd
			if _route_done[ns] == _route_id:
				continue
			var cost: float = _step_cost(here, x, y, nx, ny, d, ends)
			if dir < 4:
				if nd != dir:
					cost += ROUTE_TURN
			elif (d.x != 0) != x_first:
				cost += 0.01
			var ng: float = gs + cost
			if _route_seen[ns] == _route_id and _route_g[ns] <= ng:
				continue
			_route_seen[ns] = _route_id
			_route_g[ns] = ng
			_route_parent[ns] = s
			# Slightly over 1 so ties go to the state nearer the goal.
			_heap_push(ng + float(absi(b.x - nx) + absi(b.y - ny)) * 1.001, ns)

	if found < 0:
		return []
	var path: Array = []
	var cur: int = found
	while cur >= 0:
		var t: int = cur / 5
		path.append(Vector2i(t % w, t / w))
		cur = _route_parent[cur]
	path.reverse()
	return path

func _step_cost(here: int, x: int, y: int, nx: int, ny: int, d: Vector2i, ends: Dictionary) -> float:
	var w: int = _width
	var there: int = _cell[ny * w + nx]
	var cost: float = 1.0
	if there == CELL_CORRIDOR:
		cost = ROUTE_REUSE
	elif there >= 0:
		if not ends.has(there):
			cost = ROUTE_ROOM
	else:
		# The two tiles beside the new one, across the direction of travel, and
		# the corridor tiles one further out (thin parallel runs, twin entrances).
		if _cell[(ny + d.x) * w + nx + d.y] != CELL_ROCK:
			cost += ROUTE_TOUCH
		elif _cell_at(nx + 2 * d.y, ny + 2 * d.x) == CELL_CORRIDOR:
			cost += ROUTE_NEAR
		if _cell[(ny - d.x) * w + nx - d.y] != CELL_ROCK:
			cost += ROUTE_TOUCH
		elif _cell_at(nx - 2 * d.y, ny - 2 * d.x) == CELL_CORRIDOR:
			cost += ROUTE_NEAR
	# Opening a new way through a room's corner tile. Using an opening that
	# already exists is free, or the next corridor would cut a twin beside it.
	if (here >= 0) != (there >= 0) and (there if here >= 0 else here) == CELL_ROCK:
		var room: int = here if here >= 0 else there
		var at: Vector2i = Vector2i(x, y) if here >= 0 else Vector2i(nx, ny)
		var r: Room = _route_rooms[room]
		if (at.x == r.x or at.x == r.x + r.w - 1) and (at.y == r.y or at.y == r.y + r.h - 1):
			cost += ROUTE_CORNER
	return cost

func _cell_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= _width or y >= _height:
		return CELL_ROCK
	return _cell[y * _width + x]

func _heap_push(p: float, s: int) -> void:
	if _heap_n == _heap_p.size():
		_heap_p.resize(maxi(256, _heap_n * 2))
		_heap_s.resize(maxi(256, _heap_n * 2))
	var i: int = _heap_n
	_heap_n += 1
	while i > 0:
		var up: int = (i - 1) >> 1
		if _heap_p[up] <= p:
			break
		_heap_p[i] = _heap_p[up]
		_heap_s[i] = _heap_s[up]
		i = up
	_heap_p[i] = p
	_heap_s[i] = s

func _heap_pop() -> int:
	var top: int = _heap_s[0]
	_heap_n -= 1
	if _heap_n > 0:
		var p: float = _heap_p[_heap_n]
		var s: int = _heap_s[_heap_n]
		var i: int = 0
		while true:
			var c: int = i * 2 + 1
			if c >= _heap_n:
				break
			if c + 1 < _heap_n and _heap_p[c + 1] < _heap_p[c]:
				c += 1
			if _heap_p[c] >= p:
				break
			_heap_p[i] = _heap_p[c]
			_heap_s[i] = _heap_s[c]
			i = c
		_heap_p[i] = p
		_heap_s[i] = s
	return top

func _derive_walls(floor_set: Dictionary) -> Dictionary:
	var walls: Dictionary = {}
	for k in floor_set.keys():
		var c: Vector2i = k
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var n := Vector2i(c.x + dx, c.y + dy)
				if not floor_set.has(n):
					walls[n] = true
	return walls

func _pick_room_corner(room: Room, spawn: Vector2i) -> Vector2i:
	# When a room has corridors on two adjacent sides, the corner BETWEEN those
	# sides becomes part of the natural traversal path — placing a portal there
	# causes accidental transitions. Score each corner by how many of its two
	# adjacent sides actually have a corridor entry, and prefer corners with the
	# fewest entry-side neighbors. Ties broken by distance from spawn so the
	# portal still feels far from the start. A corridor leg running along the
	# room's edge can pass through a corner; if that corner is the only way out
	# (a cut tile), a portal there would make the rest of the map unreachable.
	var entry_n: bool = false
	var entry_s: bool = false
	var entry_w: bool = false
	var entry_e: bool = false
	for y in range(room.y, room.y + room.h):
		if _corridor_path.has(Vector2i(room.x - 1, y)):
			entry_w = true
		if _corridor_path.has(Vector2i(room.x + room.w, y)):
			entry_e = true
	for x in range(room.x, room.x + room.w):
		if _corridor_path.has(Vector2i(x, room.y - 1)):
			entry_n = true
		if _corridor_path.has(Vector2i(x, room.y + room.h)):
			entry_s = true

	var corners: Array = [
		{ "pos": Vector2i(room.x,              room.y),              "n": true,  "s": false, "w": true,  "e": false },
		{ "pos": Vector2i(room.x + room.w - 1, room.y),              "n": true,  "s": false, "w": false, "e": true  },
		{ "pos": Vector2i(room.x,              room.y + room.h - 1), "n": false, "s": true,  "w": true,  "e": false },
		{ "pos": Vector2i(room.x + room.w - 1, room.y + room.h - 1), "n": false, "s": true,  "w": false, "e": true  },
	]

	var best: Vector2i = corners[0]["pos"]
	var best_score: int = -1000000
	for c_info in corners:
		var c: Vector2i = c_info["pos"]
		if c == spawn:
			continue
		var penalty: int = 0
		if c_info["n"] and entry_n: penalty += 1
		if c_info["s"] and entry_s: penalty += 1
		if c_info["w"] and entry_w: penalty += 1
		if c_info["e"] and entry_e: penalty += 1
		if _corridor_path.has(c) and _cut_tiles().has(c): penalty += 10
		var dist: int = absi(c.x - spawn.x) + absi(c.y - spawn.y)
		var score: int = -penalty * 1000 + dist
		if score > best_score:
			best_score = score
			best = c
	return best

# Bare dead-end tips (spurs at least two tiles long) are filled first, up to half
# the chests, so a dead end is worth walking down. The rest go on non-corridor
# room tiles, outside the spawn room when there is another. Chests block
# movement, so no two ever touch, even diagonally.
func _pick_chest_spawns(rooms: Array, spawn_room: Room, count: int, exclude: Array) -> Array:
	var picks: Array = []
	if rooms.is_empty() or count <= 0:
		return picks
	var excluded: Dictionary = {}
	for t: Vector2i in exclude:
		excluded[t] = true

	var tips: Array = []
	for key in _corridor_path.keys():
		var t: Vector2i = key
		if _room_of.has(t) or excluded.has(t):
			continue
		var exits: Array = CARDINALS.filter(func(d: Vector2i) -> bool: return _floor.has(t + d))
		if exits.size() == 1 and not _room_of.has(t + exits[0]):
			tips.append(t)
	_shuffle_in_place(tips)

	var tip_quota: int = mini(tips.size(), ceili(count / 2.0))
	for t: Vector2i in tips:
		if picks.size() >= tip_quota:
			break
		if not _touches_any(t, picks):
			picks.append(t)

	var pool: Array = rooms.filter(func(r: Room) -> bool: return r != spawn_room)
	if pool.is_empty():
		pool = rooms
	var attempts: int = 0
	var max_attempts: int = count * 30
	while picks.size() < count and attempts < max_attempts:
		attempts += 1
		var room: Room = pool[_rng.randi() % pool.size()]
		var p := Vector2i(_rng.randi_range(room.x, room.x + room.w - 1), _rng.randi_range(room.y, room.y + room.h - 1))
		if excluded.has(p) or not _floor.has(p) or _corridor_path.has(p) or _touches_any(p, picks):
			continue
		if _chest_blocks(p, picks, spawn_room.center()):
			continue
		picks.append(p)
	return picks

## True when a chest at `p`, beside the `chests` already placed, would wall off
## any floor (two chests can seal a ring tile against a pillar, for one).
func _chest_blocks(p: Vector2i, chests: Array, start: Vector2i) -> bool:
	var blocked: Dictionary = { p: true }
	for c: Vector2i in chests:
		blocked[c] = true
	var seen: Dictionary = { start: true }
	var stack: Array = [start]
	while not stack.is_empty():
		var t: Vector2i = stack.pop_back()
		for d: Vector2i in CARDINALS:
			var n: Vector2i = t + d
			if _floor.has(n) and not blocked.has(n) and not seen.has(n):
				seen[n] = true
				stack.push_back(n)
	return seen.size() < _floor.size() - blocked.size()

## True when `t` is within one tile (8-neighbourhood) of any tile in `others`.
func _touches_any(t: Vector2i, others: Array) -> bool:
	for o: Vector2i in others:
		if absi(o.x - t.x) <= 1 and absi(o.y - t.y) <= 1:
			return true
	return false

func _distances_from(start: Vector2i) -> Dictionary:
	var dist: Dictionary = { start: 0 }
	var queue: Array = [start]
	var head: int = 0
	while head < queue.size():
		var t: Vector2i = queue[head]
		head += 1
		for d: Vector2i in CARDINALS:
			var n: Vector2i = t + d
			if _floor.has(n) and not dist.has(n):
				dist[n] = dist[t] + 1
				queue.append(n)
	return dist

# Picks enemy spawn tiles from both rooms (excluding the spawn room) and pure
# corridor cells (corridor tiles that don't pass through any room interior).
# Each spawn rolls against `corridor_chance` to decide which pool to sample.
# Falls back to the other pool if the chosen one is exhausted.
# Groups keep `enemy_spacing` tiles apart and at least `enemy_spawn_clearance`
# steps of walking from the spawn, so fights don't chain back to back or start
# on the doorstep; a cramped map may place fewer than `count`.
func _pick_enemy_spawns(room_pool: Array, count: int, corridor_chance: float, exclude: Array) -> Array:
	var picks: Array = []
	if count <= 0:
		return picks
	var spacing: int = maxi(1, int(_config.get("enemy_spacing", 4)))
	var clearance: int = maxi(0, int(_config.get("enemy_spawn_clearance", 6)))
	# Pure corridor tiles = tiles in _corridor_path that aren't inside any room.
	var corridor_pool: Array = []
	for tile_key in _corridor_path.keys():
		var t: Vector2i = tile_key
		if not _room_of.has(t):
			corridor_pool.append(t)
	_shuffle_in_place(corridor_pool)

	var attempts: int = 0
	var max_attempts: int = count * 30
	while picks.size() < count and attempts < max_attempts:
		attempts += 1
		var try_corridor: bool = _rng.randf() < corridor_chance and not corridor_pool.is_empty()
		if not try_corridor and room_pool.is_empty():
			try_corridor = not corridor_pool.is_empty()
		var p: Vector2i
		if try_corridor:
			p = corridor_pool.pop_back()
		elif not room_pool.is_empty():
			var room: Room = room_pool[_rng.randi() % room_pool.size()]
			var rx := _rng.randi_range(room.x, room.x + room.w - 1)
			var ry := _rng.randi_range(room.y, room.y + room.h - 1)
			p = Vector2i(rx, ry)
		else:
			break
		if p in exclude or not _floor.has(p) or int(_spawn_dist.get(p, 0)) < clearance:
			continue
		var crowded: bool = false
		for o: Vector2i in picks:
			if absi(o.x - p.x) + absi(o.y - p.y) < spacing:
				crowded = true
				break
		if crowded:
			continue
		picks.append(p)
	return picks

func _find_gridmap(root: Node) -> GridMap:
	if root is GridMap:
		return root
	for child in root.get_children():
		if child is GridMap:
			return child
		var found := _find_gridmap(child)
		if found:
			return found
	return null

func _level(t: Vector2i) -> int:
	return _levels.get(t, 0)

## Tile centre at the base of its level (a ramp's is its low end).
func _to_world(p: Vector2i) -> Vector3:
	return Vector3(p.x * TilesetRegistry.TILE_SIZE, float(_level(p)) * TilesetRegistry.LEVEL_HEIGHT, p.y * TilesetRegistry.TILE_SIZE)

func _populate_hazards(scene_root: Node, result: Result) -> void:
	if result.hazard_patches.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Hazards"

	for patch: Dictionary in result.hazard_patches:
		var hazard: Hazard = HazardRegistry.get_hazard(patch["id"])
		if hazard == null:
			continue
		var rect: Rect2i = patch["rect"]
		var node := HazardTile.new()
		node.hazard = hazard
		node.size = rect.size
		node.surface_offset = TilesetRegistry.FLOOR_THICKNESS + 0.01
		node.position = _to_world(rect.position)
		holder.add_child(node)

	scene_root.add_child(holder)

## own_navigation: true when no combined navmesh is baked, so each ramp needs its own region.
func _populate_ramps(scene_root: Node, tileset: String, own_navigation: bool) -> void:
	if _ramps.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Ramps"
	var material: Material = TilesetRegistry.get_floor_material(tileset)

	for key in _ramps.keys():
		var tile: Vector2i = key
		var info: Dictionary = _ramps[tile]
		var dir: Vector2i = info["dir"]
		var ramp := RampTile.new()
		ramp.style = RampTile.Style.STAIRS if info["style"] == "stairs" else RampTile.Style.RAMP
		ramp.rise = TilesetRegistry.LEVEL_HEIGHT
		ramp.length = TilesetRegistry.TILE_SIZE
		ramp.width = TilesetRegistry.TILE_SIZE
		ramp.surface_offset = TilesetRegistry.FLOOR_THICKNESS
		ramp.material = material
		ramp.build_navigation = own_navigation
		ramp.position = _to_world(tile)
		# RampTile climbs toward its local -Z.
		ramp.rotation.y = atan2(-float(dir.x), -float(dir.y))
		holder.add_child(ramp)

	scene_root.add_child(holder)

func _populate_enemies(scene_root: Node, result: Result) -> void:
	var spawns: Array = result.enemy_spawns
	var enemies_node: Node = scene_root.get_node_or_null("Enemies")
	if enemies_node == null:
		push_warning("MapGenerator: no Enemies node in scene root; skipping enemy spawns")
		return
	var spawn_script: Script = load("res://scripts/SpawnId.gd")
	var idx: int = 0
	
	var levels_parsed: Array = _config.get("enemy_level_range", [])
	var levels: Array = [1, 3]

	# MAP_CONFIG.md already documents [1, 3] as the default. Returning early
	# here instead left the whole map with zero enemy markers.
	if levels_parsed.size() != 2:
		push_warning("MapGenerator: enemy_level_range missing or malformed, using %s" % str(levels))
	else:
		levels = [int(levels_parsed[0]), int(levels_parsed[1])]


	for tile_v in spawns:
		var tile: Vector2i = tile_v
		var marker := Marker3D.new()
		marker.set_script(spawn_script)
		marker.spawn_id = "proc_spawn_%02d" % idx
		# Deeper groups roll higher: the top of the range climbs with walking
		# distance from the spawn, and a group may roll one level below it.
		var depth: float = result.enemy_depths[idx] if idx < result.enemy_depths.size() else 0.0
		var top: int = int(levels[0]) + roundi(depth * float(int(levels[1]) - int(levels[0])))
		marker.level_range = [maxi(int(levels[0]), top - 1), top]
		marker.reward_keys = result.enemy_keys.get(idx, [])
		marker.position = _to_world(tile) + Vector3(0, 0.1, 0)
		enemies_node.add_child(marker)
		idx += 1

## RunState.current.map.chest_state is keyed on the bare chest id, so two procedural maps
## both numbering from proc_chest_00 shared one saved state.
func _chest_id(idx: int) -> String:
	if _map_id.is_empty():
		push_error("MapGenerator: no map_id given, procedural chest ids will collide across maps")
		return "proc_chest_%02d" % idx

	return "%s_chest_%02d" % [_map_id, idx]

func _populate_chests(gridmap: GridMap, result: Result) -> void:
	var chests_node: Node = gridmap.get_node_or_null("Chests")
	if chests_node == null:
		push_warning("MapGenerator: no Chests node in blueprint; skipping chests")
		return
	var chest_scene: PackedScene = load("res://scenes/ChestBasic.tscn")
	if chest_scene == null:
		push_warning("MapGenerator: ChestBasic.tscn not found; skipping chests")
		return
	var reward_quantity: int = int(_config.get("reward_chest_quantity", 4))
	var idx: int = 0
	for tile_v in result.chest_spawns:
		var tile: Vector2i = tile_v
		var chest := chest_scene.instantiate()
		chest.position = _to_world(tile) + Vector3(0, 0.5, 0)
		if "id" in chest:
			chest.id = _chest_id(idx)
		if "random" in chest:
			chest.random = true
		if "forced_keys" in chest:
			chest.forced_keys = result.chest_keys.get(idx, [])
		if "lock_spec" in chest:
			chest.lock_spec = result.chest_locks.get(idx, {})
		# The payoff for a key hunt must not be the same two random items every
		# corridor chest gives.
		if result.reward_chests.has(idx):
			if "quantity" in chest:
				chest.quantity = reward_quantity
			if "contents" in chest:
				chest.contents = ChestInteractable.Contents.BOTH
		chests_node.add_child(chest)
		idx += 1

func _populate_doors(gridmap: GridMap, doors: Array, door_nav: Dictionary = {}) -> void:
	if doors.is_empty():
		return
	var doors_node: Node = gridmap.get_node_or_null("Doors")
	if doors_node == null:
		push_warning("MapGenerator: no Doors node in blueprint; skipping %d doors" % doors.size())
		return
	var door_scene: PackedScene = load("res://maps/_door/proc_door.tscn")
	if door_scene == null:
		push_warning("MapGenerator: proc_door.tscn not found; skipping doors")
		return

	var trap_rng := RandomNumberGenerator.new()
	trap_rng.state = _trap_rng_state

	for entry_v in doors:
		var entry: Dictionary = entry_v
		var a: Vector2i = entry["a"]
		var b: Vector2i = entry["b"]
		var node: Node3D = door_scene.instantiate()
		# Tile t sits at world t * TILE_SIZE, so the shared boundary midpoint is
		# just the summed coordinates at TILE_SIZE 2.
		node.position = Vector3(float(a.x + b.x), float(_level(a)) * TilesetRegistry.LEVEL_HEIGHT, float(a.y + b.y))
		# The closed leaf is thin on local Z, so yaw 0 seals a north/south step.
		node.rotation = Vector3(0.0, PI * 0.5 if (b - a).x != 0 else 0.0, 0.0)
		node.door_id = entry["id"]
		node.locked = entry["locked"]
		node.key_id = entry["key_id"]
		node.key_name = entry["key_name"]
		node.seal_name = entry["seal_name"]
		node.trap_id = _pick_trap_id(entry["trapped"], trap_rng)
		node.nav_region = door_nav.get(entry["id"])
		doors_node.add_child(node)

func _pick_trap_id(is_trapped: bool, rng: RandomNumberGenerator) -> String:
	if not is_trapped or TrapRegistry.basic_traps.is_empty():
		return ""

	return TrapRegistry.basic_traps[rng.randi() % TrapRegistry.basic_traps.size()].id

const PORTAL_COLOR: Color = Color(0.30, 0.60, 1.00)

func _populate_transition(gridmap: GridMap, tile: Vector2i, target_map_id: String) -> void:
	if target_map_id.is_empty():
		return
	var transitions_node: Node = gridmap.get_node_or_null("Transitions")
	if transitions_node == null:
		return
	var trigger_script: Script = load("res://scripts/triggerables/MapTransitionTriggerable.gd")
	var area := Area3D.new()
	area.set_script(trigger_script)
	area.position = _to_world(tile) + Vector3(0, 1, 0)
	var map_data := MapData.new()
	map_data.id = target_map_id
	area.map_data = map_data

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 2.0, 1.5)
	shape.shape = box
	area.add_child(shape)

	_add_portal_visual(area)

	transitions_node.add_child(area)

func _add_portal_visual(area: Area3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.4
	cylinder.bottom_radius = 0.4
	cylinder.height = 1.6
	mesh_instance.mesh = cylinder
	# Area sits at y=+1 above floor; offset the mesh down so its base meets the floor.
	mesh_instance.position = Vector3(0, -0.2, 0)

	var material := StandardMaterial3D.new()
	material.albedo_color = PORTAL_COLOR
	material.emission_enabled = true
	material.emission = PORTAL_COLOR
	material.emission_energy_multiplier = 3.0
	mesh_instance.material_override = material
	area.add_child(mesh_instance)

	var light := OmniLight3D.new()
	light.light_color = PORTAL_COLOR
	light.light_energy = 2.0
	light.omni_range = 5.0
	area.add_child(light)
