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
	var chest_spawns: Array = []
	# Door/lock output. door_spawns entries are
	# {id, a, b, locked, key_id, key_name, seal_name, trap_id}; chest_keys and
	# enemy_keys map a spawn INDEX to the {id, name} keys it must hand out;
	# chest_locks maps a chest index to the lock it carries; reward_chests lists
	# the chest indices created to justify a locked door.
	var corridor_tiles: Dictionary = {}
	var door_spawns: Array = []
	var chest_keys: Dictionary = {}
	var chest_locks: Dictionary = {}
	var enemy_keys: Dictionary = {}
	var reward_chests: Array = []

var _rng: RandomNumberGenerator
var _config: Dictionary
var _map_id: String = ""
var _width: int
var _height: int
var _floor: Dictionary = {}
var _corridor_path: Dictionary = {}

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

	for room: Room in rooms:
		_carve_room(room)

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

	# Chest spawns must avoid corridor tiles even if those tiles fall inside a room
	# (corridors trace through the room interior on their way to/from the center).
	var corridor_exclusions: Array = _corridor_path.keys()

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

	var enemy_pool: Array = rooms.duplicate()
	enemy_pool.erase(spawn_room)
	var enemy_excludes: Array = [res.spawn, res.return_tile]
	if res.has_end:
		enemy_excludes.append(res.end_tile)
	var enemy_total: int = _rng.randi_range(int(enemy_range[0]), int(enemy_range[1]))
	var corridor_enemy_chance: float = clampf(float(_config.get("corridor_enemy_chance", 0.2)), 0.0, 1.0)
	res.enemy_spawns = _pick_enemy_spawns(enemy_pool, rooms, enemy_total, corridor_enemy_chance, enemy_excludes)

	var chest_excludes: Array = [res.spawn, res.return_tile] + res.enemy_spawns + corridor_exclusions
	if res.has_end:
		chest_excludes.append(res.end_tile)
	res.chest_spawns = _pick_room_tiles(rooms, _rng.randi_range(int(chest_range[0]), int(chest_range[1])), chest_excludes)
	res.corridor_tiles = _corridor_path.duplicate()

	_build_doors(res, rooms)

	return res

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
	_assign_chest_locks(res, regions, locks)
	_assign_doors(res, cands, edges, locks)

# Door ids come from tile coordinates, never from placement order, so they stay
# stable across regeneration — unlike the positional chest ids.
func _door_key(a: Vector2i, b: Vector2i) -> String:
	var lo: Vector2i = a
	if b.y < a.y or (b.y == a.y and b.x < a.x):
		lo = b
	var axis: String = "x" if a.x != b.x else "z"
	return "door_%d_%d_%s" % [lo.x, lo.y, axis]

func _pair_key(a: Vector2i, b: Vector2i) -> String:
	return _door_key(a, b)

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
	var room_of: Dictionary = {}
	for i in range(rooms.size()):
		var r: Room = rooms[i]
		for x in range(r.x, r.x + r.w):
			for y in range(r.y, r.y + r.h):
				room_of[Vector2i(x, y)] = i

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
		var nb: Array = []
		for d: Vector2i in CARDINALS:
			if floor_set.has(t + d):
				nb.append(d)
		if nb.size() != 2 or nb[0] != -nb[1]:
			continue
		straight[t] = Vector2i(absi(nb[0].x), absi(nb[0].y))

	var seen: Dictionary = {}
	var picks: Array = []
	var keys: Array = straight.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)

	for key in keys:
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
		cut[_pair_key(c["inside"], c["outside"])] = true

	var region_of: Dictionary = {}
	var regions: Array = []

	for key in floor_set.keys():
		if region_of.has(key):
			continue
		var idx: int = regions.size()
		var tiles: Array = []
		var stack: Array = [key]
		region_of[key] = idx

		while not stack.is_empty():
			var t: Vector2i = stack.pop_back()
			tiles.append(t)
			for d: Vector2i in CARDINALS:
				var n: Vector2i = t + d
				if not floor_set.has(n) or region_of.has(n):
					continue
				if cut.has(_pair_key(t, n)):
					continue
				region_of[n] = idx
				stack.push_back(n)

		regions.append({ "id": idx, "tiles": tiles, "chests": [], "enemies": [] })

	return { "region_of": region_of, "regions": regions }

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
	var adj: Array = []
	for _i in range(region_count):
		adj.append([])

	for i in range(edges.size()):
		var e: Dictionary = edges[i]
		if e["ra"] < 0 or e["rb"] < 0 or e["ra"] == e["rb"]:
			continue
		adj[e["ra"]].append({ "to": e["rb"], "edge": i })
		adj[e["rb"]].append({ "to": e["ra"], "edge": i })

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

func _region_path_edges(from_region: int, to_region: int, region_count: int, edges: Array) -> Dictionary:
	var path: Dictionary = {}
	if from_region < 0 or to_region < 0 or from_region == to_region:
		return path

	var adj: Array = []
	for _i in range(region_count):
		adj.append([])
	for i in range(edges.size()):
		var e: Dictionary = edges[i]
		if e["ra"] < 0 or e["rb"] < 0 or e["ra"] == e["rb"]:
			continue
		adj[e["ra"]].append({ "to": e["rb"], "edge": i })
		adj[e["rb"]].append({ "to": e["ra"], "edge": i })

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

	var taken: Dictionary = {}
	for t in res.chest_spawns:
		taken[t] = true
	for t in res.enemy_spawns:
		taken[t] = true
	taken[res.spawn] = true
	taken[res.return_tile] = true
	if res.has_end:
		taken[res.end_tile] = true

	var options: Array = []
	for x in range(room.x, room.x + room.w):
		for y in range(room.y, room.y + room.h):
			var t := Vector2i(x, y)
			if taken.has(t) or _corridor_path.has(t):
				continue
			if region_of.get(t, -1) != region_idx:
				continue
			options.append(t)

	if options.is_empty():
		return false

	var idx: int = res.chest_spawns.size()
	res.chest_spawns.append(options[_rng.randi() % options.size()])
	res.reward_chests.append(idx)
	regions[region_idx]["chests"].append(idx)

	return true

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
func _assign_chest_locks(res: Result, regions: Array, _locks: Array) -> void:
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

func _add_branches(rooms: Array, count: int, curviness: float) -> void:
	if rooms.is_empty() or count <= 0:
		return
	var directions: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for i in range(count):
		var parent: Room = rooms[_rng.randi() % rooms.size()]
		var direction: Vector2i = directions[_rng.randi() % 4]
		var length: int = _rng.randi_range(5, 14)
		var endpoint: Vector2i = parent.center() + direction * length
		endpoint.x = clampi(endpoint.x, 2, _width - 3)
		endpoint.y = clampi(endpoint.y, 2, _height - 3)
		# If the clamp collapsed the offset to zero, skip — would just retrace a corridor.
		if endpoint == parent.center():
			continue

		# 60% chance the branch terminates in a small dead-end room.
		if _rng.randf() < 0.6:
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
				_carve_room(room)
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
	# Pick a size scaled to the map: roughly map_dim / 8 to give ~8 chunks per axis.
	gridmap.cell_octant_size = clampi(maxi(_width, _height) / 8, 8, 32)
	# If we're baking a combined navmesh below, the per-cell stitching is wasted.
	gridmap.bake_navigation = not bake_navmesh
	gridmap.clear()

	# Each player tile (a, b) maps to a 2x2 block of GridMap cells, matching the
	# handcrafted starting_area convention: the player at world (a*2, 0, b*2) sits
	# at the +X +Z corner of cells (a*2-1..a*2, b*2-1..b*2). Walls override floor.
	var ceiling: bool = bool(_config.get("ceiling", false))
	for cell_key in result.floor_tiles.keys():
		_set_player_tile(gridmap, cell_key, TilesetRegistry.ITEM_FLOOR)
		if ceiling:
			_set_ceiling_tile(gridmap, cell_key)

	for cell_key in result.wall_tiles.keys():
		_set_player_tile(gridmap, cell_key, TilesetRegistry.ITEM_WALL)

	if bake_navmesh:
		_build_combined_navmesh(scene_root, result.floor_tiles)
	if merge_walls:
		_build_merged_wall_colliders(scene_root, result.wall_tiles)

	_populate_enemies(scene_root, result)
	_populate_chests(gridmap, result)
	_populate_doors(gridmap, result.door_spawns)
	_populate_transition(gridmap, result.return_tile, return_map_id)
	if result.has_end and not end_map_id.is_empty():
		_populate_transition(gridmap, result.end_tile, end_map_id)

# Returns a Callable that, given a Rect of player tiles, computes the world-space
# bounding box matching what the GridMap actually renders. Reading the GridMap's
# `cell_center_x`/`z` flags here means merged colliders and baked navmeshes stay
# aligned with the visual cells even if the defaults differ or the blueprint
# scene overrides them.
func _tile_bounds_resolver(gridmap: GridMap) -> Callable:
	var cs_x: float = TilesetRegistry.CELL_SIZE
	var cs_z: float = TilesetRegistry.CELL_SIZE
	if gridmap != null:
		cs_x = gridmap.cell_size.x
		cs_z = gridmap.cell_size.z
	# When a cell is "centered", its world span is cell_pos ± cs/2.
	# When not centered, its span is [cell_pos, cell_pos + cs].
	var ccx: bool = true if gridmap == null else gridmap.cell_center_x
	var ccz: bool = true if gridmap == null else gridmap.cell_center_z
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

# Builds one NavigationMesh covering every floor tile, with greedily-merged
# rectangular polygons so the navmesh has tens or hundreds of polygons instead
# of one-per-cell. NavigationAgent A* cost is roughly proportional to polygon
# count, so this is the dominant perf win for AI on large maps.
func _build_combined_navmesh(scene_root: Node, floor_tiles: Dictionary) -> void:
	var nav_region: NavigationRegion3D = scene_root if scene_root is NavigationRegion3D else null
	if nav_region == null:
		for child in scene_root.get_children():
			if child is NavigationRegion3D:
				nav_region = child
				break
	if nav_region == null:
		push_warning("MapGenerator: no NavigationRegion3D; navmesh bake skipped")
		return

	var gridmap: GridMap = _find_gridmap(scene_root)
	var bounds: Callable = _tile_bounds_resolver(gridmap)

	var rects: Array = _greedy_rectangles(floor_tiles)

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

	var navmesh := NavigationMesh.new()
	var verts := PackedVector3Array()
	var index_of: Dictionary = {}
	var y: float = TilesetRegistry.FLOOR_THICKNESS + 0.001  # just above floor surface

	for rect in rects:
		var b: Dictionary = bounds.call(rect)
		var x_hi: int = rect.x + rect.w
		var z_hi: int = rect.y + rect.h
		var poly := PackedInt32Array()

		# Same winding as before: +x along the near edge, +z along the far side,
		# then back. Each side emits its start corner plus its interior breaks;
		# the next side emits the shared corner.
		for bx in _interior_breaks(x_breaks.get(rect.y, {}), rect.x, x_hi, false):
			poly.append(_intern_vertex(verts, index_of, Vector3(_axis_world(bx, rect.x, x_hi, b.lo_x, b.hi_x), y, b.lo_z)))

		for bz in _interior_breaks(z_breaks.get(x_hi, {}), rect.y, z_hi, false):
			poly.append(_intern_vertex(verts, index_of, Vector3(b.hi_x, y, _axis_world(bz, rect.y, z_hi, b.lo_z, b.hi_z))))

		for bx in _interior_breaks(x_breaks.get(z_hi, {}), rect.x, x_hi, true):
			poly.append(_intern_vertex(verts, index_of, Vector3(_axis_world(bx, rect.x, x_hi, b.lo_x, b.hi_x), y, b.hi_z)))

		for bz in _interior_breaks(z_breaks.get(rect.x, {}), rect.y, z_hi, true):
			poly.append(_intern_vertex(verts, index_of, Vector3(b.lo_x, y, _axis_world(bz, rect.y, z_hi, b.lo_z, b.hi_z))))

		navmesh.add_polygon(poly)

	navmesh.vertices = verts
	nav_region.navigation_mesh = navmesh

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
func _build_merged_wall_colliders(scene_root: Node, wall_tiles: Dictionary) -> void:
	if wall_tiles.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "MergedWalls"
	body.collision_layer = 1
	body.collision_mask = 0
	var gridmap: GridMap = _find_gridmap(scene_root)
	var bounds: Callable = _tile_bounds_resolver(gridmap)
	var rects: Array = _greedy_rectangles(wall_tiles)
	for rect in rects:
		var b: Dictionary = bounds.call(rect)
		var lo_x: float = b.lo_x
		var hi_x: float = b.hi_x
		var lo_z: float = b.lo_z
		var hi_z: float = b.hi_z
		var height: float = TilesetRegistry.WALL_HEIGHT
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(hi_x - lo_x, height, hi_z - lo_z)
		col.shape = box
		col.position = Vector3((lo_x + hi_x) * 0.5, height * 0.5, (lo_z + hi_z) * 0.5)
		body.add_child(col)
	scene_root.add_child(body)

# ---------- greedy rectangle decomposition ----------

class Rect:
	var x: int
	var y: int
	var w: int
	var h: int

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
	var keys: Array = tiles.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)
	for k in keys:
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

# ---------- cell placement ----------

func _set_player_tile(gridmap: GridMap, tile: Vector2i, item: int) -> void:
	var bx: int = tile.x * 2
	var bz: int = tile.y * 2
	gridmap.set_cell_item(Vector3i(bx,     0, bz),     item)
	gridmap.set_cell_item(Vector3i(bx - 1, 0, bz),     item)
	gridmap.set_cell_item(Vector3i(bx,     0, bz - 1), item)
	gridmap.set_cell_item(Vector3i(bx - 1, 0, bz - 1), item)

func _set_ceiling_tile(gridmap: GridMap, tile: Vector2i) -> void:
	var bx: int = tile.x * 2
	var bz: int = tile.y * 2
	var y: int = TilesetRegistry.CEILING_Y
	gridmap.set_cell_item(Vector3i(bx,     y, bz),     TilesetRegistry.ITEM_CEILING)
	gridmap.set_cell_item(Vector3i(bx - 1, y, bz),     TilesetRegistry.ITEM_CEILING)
	gridmap.set_cell_item(Vector3i(bx,     y, bz - 1), TilesetRegistry.ITEM_CEILING)
	gridmap.set_cell_item(Vector3i(bx - 1, y, bz - 1), TilesetRegistry.ITEM_CEILING)

# ---------- internals ----------

func _carve_room(r: Room) -> void:
	for y in range(r.y, r.y + r.h):
		for x in range(r.x, r.x + r.w):
			_floor[Vector2i(x, y)] = true

const MAX_CORRIDOR_LEG: int = 8

func _carve_winding_corridor(a: Vector2i, b: Vector2i, curviness: float) -> void:
	# Subdivide long corridors so no single L-leg ever runs more than
	# MAX_CORRIDOR_LEG tiles in a row. Each intermediate waypoint gets a small
	# perpendicular offset, so a long corridor turns into a wandering zigzag
	# instead of a single boring straight line.
	var dx: int = b.x - a.x
	var dy: int = b.y - a.y
	var max_span: int = maxi(absi(dx), absi(dy))

	var segments: int = maxi(1, (max_span + MAX_CORRIDOR_LEG - 1) / MAX_CORRIDOR_LEG)
	# Short corridors still get an optional one-time curve so they don't all
	# look identical.
	if segments == 1 and curviness > 0.0 and max_span >= 4 and _rng.randf() < curviness:
		segments = 2

	if segments == 1:
		_carve_corridor(a, b)
		return

	var prev: Vector2i = a
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
		_carve_corridor(prev, pt)
		prev = pt
	_carve_corridor(prev, b)

func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var cur := a
	if _rng.randi() % 2 == 0:
		while cur.x != b.x:
			_mark_corridor(cur)
			cur.x += signi(b.x - cur.x)
		while cur.y != b.y:
			_mark_corridor(cur)
			cur.y += signi(b.y - cur.y)
	else:
		while cur.y != b.y:
			_mark_corridor(cur)
			cur.y += signi(b.y - cur.y)
		while cur.x != b.x:
			_mark_corridor(cur)
			cur.x += signi(b.x - cur.x)
	_mark_corridor(cur)

func _mark_corridor(p: Vector2i) -> void:
	_floor[p] = true
	_corridor_path[p] = true

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
	# Corner cells themselves are never on corridor paths (corridors enter/exit
	# through middle rows/columns). But when a room has corridors on two adjacent
	# sides, the corner BETWEEN those sides becomes part of the natural traversal
	# path — placing a portal there causes accidental transitions. Score each
	# corner by how many of its two adjacent sides actually have a corridor entry,
	# and prefer corners with the fewest entry-side neighbors. Ties broken by
	# distance from spawn so the portal still feels far from the start.
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
		var dist: int = absi(c.x - spawn.x) + absi(c.y - spawn.y)
		var score: int = -penalty * 1000 + dist
		if score > best_score:
			best_score = score
			best = c
	return best

func _pick_room_tiles(rooms: Array, count: int, exclude: Array) -> Array:
	var picks: Array = []
	if rooms.is_empty() or count <= 0:
		return picks
	var attempts: int = 0
	var max_attempts: int = count * 30
	while picks.size() < count and attempts < max_attempts:
		attempts += 1
		var room: Room = rooms[_rng.randi() % rooms.size()]
		var rx := _rng.randi_range(room.x, room.x + room.w - 1)
		var ry := _rng.randi_range(room.y, room.y + room.h - 1)
		var p := Vector2i(rx, ry)
		if p in exclude or p in picks:
			continue
		picks.append(p)
	return picks

# Picks enemy spawn tiles from both rooms (excluding the spawn room) and pure
# corridor cells (corridor tiles that don't pass through any room interior).
# Each spawn rolls against `corridor_chance` to decide which pool to sample.
# Falls back to the other pool if the chosen one is exhausted.
func _pick_enemy_spawns(room_pool: Array, all_rooms: Array, count: int, corridor_chance: float, exclude: Array) -> Array:
	var picks: Array = []
	if count <= 0:
		return picks
	# Pure corridor tiles = tiles in _corridor_path that aren't inside any room.
	var corridor_pool: Array = []
	for tile_key in _corridor_path.keys():
		var t: Vector2i = tile_key
		if not _is_in_any_room(t, all_rooms):
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
		if p in exclude or p in picks:
			continue
		picks.append(p)
	return picks

func _is_in_any_room(tile: Vector2i, rooms: Array) -> bool:
	for r: Room in rooms:
		if r.contains(tile):
			return true
	return false

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

func _to_world(p: Vector2i) -> Vector3:
	return Vector3(p.x * TilesetRegistry.TILE_SIZE, 0.0, p.y * TilesetRegistry.TILE_SIZE)

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
		marker.level_range = levels
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

func _populate_doors(gridmap: GridMap, doors: Array) -> void:
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

	for entry_v in doors:
		var entry: Dictionary = entry_v
		var a: Vector2i = entry["a"]
		var b: Vector2i = entry["b"]
		var node: Node3D = door_scene.instantiate()
		# Tile t sits at world t * TILE_SIZE, so the shared boundary midpoint is
		# just the summed coordinates at TILE_SIZE 2.
		node.position = Vector3(float(a.x + b.x), 0.0, float(a.y + b.y))
		# The closed leaf is thin on local Z, so yaw 0 seals a north/south step.
		node.rotation = Vector3(0.0, PI * 0.5 if (b - a).x != 0 else 0.0, 0.0)
		node.door_id = entry["id"]
		node.locked = entry["locked"]
		node.key_id = entry["key_id"]
		node.key_name = entry["key_name"]
		node.seal_name = entry["seal_name"]
		node.trap_id = _pick_trap_id(entry["trapped"])
		doors_node.add_child(node)

func _pick_trap_id(is_trapped: bool) -> String:
	if not is_trapped or TrapRegistry.basic_traps.is_empty():
		return ""

	return TrapRegistry.basic_traps[_rng.randi() % TrapRegistry.basic_traps.size()].id

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
