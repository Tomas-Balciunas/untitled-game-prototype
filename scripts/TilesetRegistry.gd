extends Node

const TILE_SIZE: float = 2.0
const CELL_SIZE: float = 1.0
const WALL_HEIGHT: float = 2.0
const FLOOR_THICKNESS: float = 0.1

const ITEM_FLOOR: int = 0
const ITEM_WALL: int = 1
const ITEM_CEILING: int = 2

# y-layer of the GridMap where ceiling cells live (cell_size.y = 1 so layer 2 sits at world y=2).
const CEILING_Y: int = 2

# Filesystem convention for per-theme art overrides. If a file exists at
# `<TILE_ASSET_ROOT>/<theme>/<slot>.<ext>` it is loaded and used in place of the
# procedural BoxMesh below. Slots are "floor", "wall", "ceiling". Supported
# extensions are tried in this order; first match wins.
const TILE_ASSET_ROOT: String = "res://assets/tiles"
const TILE_ASSET_EXTS: Array = [".tres", ".res", ".glb", ".gltf", ".obj"]

const THEMES: Dictionary = {
	"default": { "floor_color": Color(0.65, 0.65, 0.65), "wall_color": Color(0.45, 0.45, 0.5), "ceiling_color": Color(0.20, 0.20, 0.22) },
	"crypt":   { "floor_color": Color(0.32, 0.30, 0.32), "wall_color": Color(0.24, 0.22, 0.28), "ceiling_color": Color(0.14, 0.13, 0.16) },
	"castle":  { "floor_color": Color(0.72, 0.62, 0.50), "wall_color": Color(0.55, 0.48, 0.42), "ceiling_color": Color(0.40, 0.35, 0.30) },
}

var _cache: Dictionary = {}

# When `with_wall_collision` is true, the wall item carries a per-cell BoxShape3D
# (used by handcrafted maps and procedural maps that don't merge walls). When
# false, walls render-only; the caller is expected to provide its own merged
# collision body. The two variants are cached separately.
func get_mesh_library(theme: String, with_wall_collision: bool = true) -> MeshLibrary:
	var key: String = theme
	if not THEMES.has(key):
		push_warning("TilesetRegistry: unknown theme '%s', using 'default'" % key)
		key = "default"
	var cache_key: String = "%s|%s" % [key, "col" if with_wall_collision else "nocol"]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var lib: MeshLibrary = _build(key, with_wall_collision)
	_cache[cache_key] = lib
	return lib

func _build(theme: String, with_wall_collision: bool = true) -> MeshLibrary:
	var cfg: Dictionary = THEMES[theme]
	var lib := MeshLibrary.new()

	# --- Floor ---
	lib.create_item(ITEM_FLOOR)
	lib.set_item_name(ITEM_FLOOR, "floor")
	var floor_mesh: Mesh = _try_load_tile(theme, "floor")
	if floor_mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, FLOOR_THICKNESS, CELL_SIZE)
		box.material = _make_material(cfg["floor_color"])
		floor_mesh = box
		lib.set_item_mesh_transform(ITEM_FLOOR, Transform3D(Basis(), Vector3(0, FLOOR_THICKNESS * 0.5, 0)))
	else:
		# Custom meshes are expected to author their own origin (typically at
		# the bottom of the tile). No additional transform applied.
		lib.set_item_mesh_transform(ITEM_FLOOR, Transform3D.IDENTITY)
	lib.set_item_mesh(ITEM_FLOOR, floor_mesh)

	# Per-cell navigation polygon — GridMap automatically stitches these into a
	# navigation region for the whole map. No runtime bake needed.
	var floor_navmesh := NavigationMesh.new()
	var h: float = CELL_SIZE * 0.5
	floor_navmesh.vertices = PackedVector3Array([
		Vector3(-h, FLOOR_THICKNESS, -h),
		Vector3( h, FLOOR_THICKNESS, -h),
		Vector3( h, FLOOR_THICKNESS,  h),
		Vector3(-h, FLOOR_THICKNESS,  h),
	])
	floor_navmesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	lib.set_item_navigation_mesh(ITEM_FLOOR, floor_navmesh)

	# --- Wall ---
	lib.create_item(ITEM_WALL)
	lib.set_item_name(ITEM_WALL, "wall")
	var wall_mesh: Mesh = _try_load_tile(theme, "wall")
	if wall_mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
		box.material = _make_material(cfg["wall_color"])
		wall_mesh = box
		lib.set_item_mesh_transform(ITEM_WALL, Transform3D(Basis(), Vector3(0, WALL_HEIGHT * 0.5, 0)))
	else:
		lib.set_item_mesh_transform(ITEM_WALL, Transform3D(Basis(), Vector3(0, WALL_HEIGHT * 0.5, 0)))
	lib.set_item_mesh(ITEM_WALL, wall_mesh)

	# Collision shape stays cubic regardless of the wall mesh — the player needs
	# predictable, grid-aligned blockers. Override in a forked MeshLibrary if
	# you need non-cubic wall collision. Skipped entirely in `nocol` builds, used
	# when MapGenerator provides merged wall colliders externally.
	if with_wall_collision:
		var wall_shape := BoxShape3D.new()
		wall_shape.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
		var shape_xform := Transform3D(Basis(), Vector3(0, WALL_HEIGHT * 0.5, 0))
		lib.set_item_shapes(ITEM_WALL, [wall_shape, shape_xform])

	# --- Ceiling ---
	# Placed in a separate y-layer of the GridMap so it can be enabled/disabled
	# per map without rebuilding the library. No collision.
	lib.create_item(ITEM_CEILING)
	lib.set_item_name(ITEM_CEILING, "ceiling")
	var ceiling_mesh: Mesh = _try_load_tile(theme, "ceiling")
	if ceiling_mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, FLOOR_THICKNESS, CELL_SIZE)
		box.material = _make_material(cfg["ceiling_color"])
		ceiling_mesh = box
		# Cell origin sits at world y = CEILING_Y, so to position the slab at
		# the top of the wall envelope we lift it by (WALL_HEIGHT - CEILING_Y).
		lib.set_item_mesh_transform(ITEM_CEILING, Transform3D(Basis(), Vector3(0, WALL_HEIGHT - CEILING_Y - FLOOR_THICKNESS * 0.5, 0)))
	else:
		lib.set_item_mesh_transform(ITEM_CEILING, Transform3D.IDENTITY)
	lib.set_item_mesh(ITEM_CEILING, ceiling_mesh)

	return lib

# Tries `res://art/tiles/<theme>/<slot>.<ext>` for each supported extension.
# Returns the first matching Mesh, or null if no override exists.
func _try_load_tile(theme: String, slot: String) -> Mesh:
	for ext: String in TILE_ASSET_EXTS:
		var path: String = "%s/%s/%s%s" % [TILE_ASSET_ROOT, theme, slot, ext]
		if not ResourceLoader.exists(path):
			continue
		var res: Resource = load(path)
		if res == null:
			continue
		if res is Mesh:
			return res
		if res is PackedScene:
			var inst: Node = res.instantiate()
			var found: Mesh = _first_mesh_in(inst)
			inst.queue_free()
			if found != null:
				return found
	return null

func _first_mesh_in(node: Node) -> Mesh:
	if node is MeshInstance3D and node.mesh != null:
		return node.mesh
	for child in node.get_children():
		var m: Mesh = _first_mesh_in(child)
		if m != null:
			return m
	return null

func _make_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
