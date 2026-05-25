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

var _rng: RandomNumberGenerator
var _config: Dictionary
var _width: int
var _height: int
var _floor: Dictionary = {}
var _corridor_path: Dictionary = {}

func _init(seed_value: int, config: Dictionary) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_config = config
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
	return res

func _order_chain(rooms: Array, layout: String) -> Array:
	if layout == "branching":
		return rooms
	if layout == "maze":
		# Random shuffle so the spanning chain weaves across the grid instead of
		# snaking row-by-row. Deterministic with the map seed via Fisher-Yates.
		var shuffled: Array = rooms.duplicate()
		for i in range(shuffled.size() - 1, 0, -1):
			var j: int = _rng.randi() % (i + 1)
			var tmp = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = tmp
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

	_populate_enemies(scene_root, result.enemy_spawns)
	_populate_chests(gridmap, result.chest_spawns)
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
	var navmesh := NavigationMesh.new()
	var verts := PackedVector3Array()
	var y: float = TilesetRegistry.FLOOR_THICKNESS + 0.001  # just above floor surface
	for rect in rects:
		var b: Dictionary = bounds.call(rect)
		var base: int = verts.size()
		verts.append(Vector3(b.lo_x, y, b.lo_z))
		verts.append(Vector3(b.hi_x, y, b.lo_z))
		verts.append(Vector3(b.hi_x, y, b.hi_z))
		verts.append(Vector3(b.lo_x, y, b.hi_z))
		navmesh.add_polygon(PackedInt32Array([base, base + 1, base + 2, base + 3]))
	navmesh.vertices = verts
	# Adjacent polygons share an edge by construction (greedy fills the grid
	# with integer-aligned rectangles), so no edge-connection tolerance needed.
	nav_region.navigation_mesh = navmesh

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
	corridor_pool.shuffle()  # cheap variety, fine even though it uses engine RNG

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

func _populate_enemies(scene_root: Node, spawns: Array) -> void:
	var enemies_node: Node = scene_root.get_node_or_null("Enemies")
	if enemies_node == null:
		push_warning("MapGenerator: no Enemies node in scene root; skipping enemy spawns")
		return
	var spawn_script: Script = load("res://scripts/SpawnId.gd")
	var idx: int = 0
	
	## level range is converted to floats
	var levels_parsed: Array = _config.get("enemy_level_range", [])
		
	if levels_parsed.is_empty() or len(levels_parsed) != 2:
		push_warning("MapGenerator: no enemy level range set or incorrect value provided")
		return
	
	var levels: Array = []
	
	for value in levels_parsed:
		levels.append(int(value))
	
	for tile_v in spawns:
		var tile: Vector2i = tile_v
		var marker := Marker3D.new()
		marker.set_script(spawn_script)
		marker.spawn_id = "proc_spawn_%02d" % idx
		marker.level_range = levels
		marker.position = _to_world(tile) + Vector3(0, 0.1, 0)
		enemies_node.add_child(marker)
		idx += 1

func _populate_chests(gridmap: GridMap, spawns: Array) -> void:
	var chests_node: Node = gridmap.get_node_or_null("Chests")
	if chests_node == null:
		return
	var chest_scene: PackedScene = load("res://scenes/ChestBasic.tscn")
	if chest_scene == null:
		push_warning("MapGenerator: ChestBasic.tscn not found; skipping chests")
		return
	var idx: int = 0
	for tile_v in spawns:
		var tile: Vector2i = tile_v
		var chest := chest_scene.instantiate()
		chest.position = _to_world(tile) + Vector3(0, 0.5, 0)
		if "id" in chest:
			chest.id = "proc_chest_%02d" % idx
		if "random" in chest:
			chest.random = true
		chests_node.add_child(chest)
		idx += 1

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
