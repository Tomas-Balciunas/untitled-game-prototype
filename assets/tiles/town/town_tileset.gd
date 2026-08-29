extends RefCounted
# Procedural town MeshLibrary. No modelling: every item is a pile of coloured
# boxes welded into one ArrayMesh, shaded by vertex colour through a single
# shared material. Facade detail (doors, windows, signs) always sits on the
# item's -Z face; the map builder rotates the cell so that face looks at the
# street. See maps/town/README.md.

const TILE: float = 2.0        # one player tile / one GridMap cell footprint
const BUILD_H: float = 3.0     # building body height
const TOWNWALL_H: float = 3.5

const STREET: int = 0
const WALL: int = 1
const WALL_WINDOW: int = 2
const WALL_DOOR: int = 3
const WALL_SHOP: int = 4
const TOWN_WALL: int = 5
const GATE: int = 6
const TREE: int = 7
const WELL: int = 8
const WALL_ALT: int = 9

const C_STREET := Color(0.44, 0.43, 0.41)
const C_CURB := Color(0.36, 0.35, 0.34)
const C_PLASTER := Color(0.78, 0.74, 0.65)
const C_PLASTER_ALT := Color(0.70, 0.63, 0.55)
const C_ROOF := Color(0.36, 0.24, 0.20)
const C_TIMBER := Color(0.30, 0.21, 0.15)
const C_DOOR := Color(0.24, 0.16, 0.11)
const C_GLASS := Color(0.16, 0.22, 0.28)
const C_SIGN := Color(0.58, 0.36, 0.14)
const C_STONE := Color(0.52, 0.52, 0.55)
const C_STONE_DARK := Color(0.40, 0.40, 0.43)
const C_TRUNK := Color(0.32, 0.24, 0.16)
const C_LEAF := Color(0.24, 0.42, 0.22)
const C_WATER := Color(0.12, 0.20, 0.26)

# Facade plane. The body front face is at z = -1, decorations stack in front of
# it so nothing z-fights.
const FRONT: float = -1.0

static func build() -> MeshLibrary:
	var lib := MeshLibrary.new()

	_add(lib, STREET, "street", _mesh_street(), [], _floor_nav())
	_add(lib, WALL, "wall", _mesh_building(C_PLASTER, []), _building_shape())
	_add(lib, WALL_ALT, "wall_alt", _mesh_building(C_PLASTER_ALT, []), _building_shape())
	_add(lib, WALL_WINDOW, "wall_window", _mesh_building(C_PLASTER, ["windows"]), _building_shape())
	_add(lib, WALL_DOOR, "wall_door", _mesh_building(C_PLASTER_ALT, ["door", "upper_window"]), _building_shape())
	_add(lib, WALL_SHOP, "wall_shop", _mesh_building(C_PLASTER, ["door", "sign", "awning"]), _building_shape())
	_add(lib, TOWN_WALL, "town_wall", _mesh_town_wall(), _box_shape(Vector3(TILE, TOWNWALL_H, TILE), TOWNWALL_H * 0.5))
	_add(lib, GATE, "gate", _mesh_gate(), [], _floor_nav())
	_add(lib, TREE, "tree", _mesh_tree(), _box_shape(Vector3(1.0, 2.8, 1.0), 1.4))
	_add(lib, WELL, "well", _mesh_well(), _box_shape(Vector3(1.6, 2.2, 1.6), 1.1))

	return lib

static func _add(lib: MeshLibrary, id: int, item_name: String, mesh: Mesh, shape: Array, nav: NavigationMesh = null) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)
	lib.set_item_mesh(id, mesh)
	# Every mesh is authored bottom-centred on the cell origin, so no offset.
	lib.set_item_mesh_transform(id, Transform3D.IDENTITY)
	if not shape.is_empty():
		lib.set_item_shapes(id, shape)
	if nav != null:
		lib.set_item_navigation_mesh(id, nav)

# --- shared material ---------------------------------------------------------

static func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	# Matches the dungeon tileset: culling off keeps winding order a non-issue
	# for hand-emitted geometry.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	m.metallic = 0.0
	return m

# --- geometry helpers --------------------------------------------------------

# Per-face brightness so flat colours still read as volume under one light.
const _FACE_SHADE := [1.00, 0.86, 0.93, 0.93, 1.10, 0.62]  # -Z +Z +X -X +Y -Y

static func _add_box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h: Vector3 = size * 0.5
	var c := [
		center + Vector3(-h.x, -h.y, -h.z),
		center + Vector3( h.x, -h.y, -h.z),
		center + Vector3( h.x,  h.y, -h.z),
		center + Vector3(-h.x,  h.y, -h.z),
		center + Vector3(-h.x, -h.y,  h.z),
		center + Vector3( h.x, -h.y,  h.z),
		center + Vector3( h.x,  h.y,  h.z),
		center + Vector3(-h.x,  h.y,  h.z),
	]
	var faces := [
		[0, 1, 2, 3, Vector3(0, 0, -1)],
		[5, 4, 7, 6, Vector3(0, 0, 1)],
		[1, 5, 6, 2, Vector3(1, 0, 0)],
		[4, 0, 3, 7, Vector3(-1, 0, 0)],
		[3, 2, 6, 7, Vector3(0, 1, 0)],
		[4, 5, 1, 0, Vector3(0, -1, 0)],
	]
	for i in faces.size():
		var f: Array = faces[i]
		var n: Vector3 = f[4]
		var shade: float = _FACE_SHADE[i]
		var col := Color(color.r * shade, color.g * shade, color.b * shade, 1.0)
		var quad := [c[f[0]], c[f[1]], c[f[2]], c[f[3]]]
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for vi: int in tri:
				st.set_color(col)
				st.set_normal(n)
				st.add_vertex(quad[vi])

static func _finish(st: SurfaceTool) -> ArrayMesh:
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, _material())
	return mesh

static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

# --- items -------------------------------------------------------------------

static func _mesh_street() -> Mesh:
	var st := _begin()
	_add_box(st, Vector3(0, 0.05, 0), Vector3(TILE, 0.10, TILE), C_STREET)
	# Faint seam so the grid is legible while grey-boxing.
	_add_box(st, Vector3(0, 0.11, 0), Vector3(TILE - 0.12, 0.02, TILE - 0.12), C_CURB)
	return _finish(st)

# `parts` selects which facade decorations sit on the -Z face.
static func _mesh_building(body: Color, parts: Array) -> Mesh:
	var st := _begin()
	_add_box(st, Vector3(0, BUILD_H * 0.5, 0), Vector3(TILE, BUILD_H, TILE), body)
	# stone plinth + overhanging eaves: cheap silhouette, sells the shape
	_add_box(st, Vector3(0, 0.13, 0), Vector3(TILE + 0.08, 0.26, TILE + 0.08), C_STONE_DARK)
	_add_box(st, Vector3(0, BUILD_H - 0.14, 0), Vector3(TILE + 0.22, 0.28, TILE + 0.22), C_ROOF)

	if parts.has("windows"):
		_window(st, Vector3(-0.45, 1.05, 0))
		_window(st, Vector3(0.45, 1.05, 0))
		_window(st, Vector3(0.0, 2.15, 0))
	if parts.has("upper_window"):
		_window(st, Vector3(0.0, 2.15, 0))
	if parts.has("door"):
		_add_box(st, Vector3(0, 1.00, FRONT + 0.03), Vector3(1.12, 2.00, 0.06), C_TIMBER)
		_add_box(st, Vector3(0, 0.90, FRONT - 0.04), Vector3(0.88, 1.80, 0.10), C_DOOR)
	if parts.has("awning"):
		_add_box(st, Vector3(0, 2.02, FRONT - 0.30), Vector3(1.70, 0.10, 0.62), C_SIGN)
	if parts.has("sign"):
		_add_box(st, Vector3(0, 2.42, FRONT - 0.10), Vector3(1.30, 0.46, 0.12), C_TIMBER)
		_add_box(st, Vector3(0, 2.42, FRONT - 0.17), Vector3(1.10, 0.30, 0.04), C_SIGN)
	return _finish(st)

static func _window(st: SurfaceTool, at: Vector3) -> void:
	_add_box(st, at + Vector3(0, 0, FRONT + 0.03), Vector3(0.86, 0.86, 0.06), C_TIMBER)
	_add_box(st, at + Vector3(0, 0, FRONT - 0.02), Vector3(0.66, 0.66, 0.08), C_GLASS)

static func _mesh_town_wall() -> Mesh:
	var st := _begin()
	_add_box(st, Vector3(0, TOWNWALL_H * 0.5, 0), Vector3(TILE, TOWNWALL_H, TILE), C_STONE)
	_add_box(st, Vector3(0, TOWNWALL_H - 0.15, 0), Vector3(TILE + 0.16, 0.30, TILE + 0.16), C_STONE_DARK)
	return _finish(st)

static func _mesh_gate() -> Mesh:
	var st := _begin()
	_add_box(st, Vector3(0, 0.05, 0), Vector3(TILE, 0.10, TILE), C_STREET)
	# Two pillars flanking the walkable lane, plus a lintel overhead.
	for sx: float in [-1.0, 1.0]:
		_add_box(st, Vector3(sx * 0.82, 1.40, 0), Vector3(0.36, 2.80, TILE), C_STONE)
	_add_box(st, Vector3(0, 3.15, 0), Vector3(TILE, 0.70, TILE), C_STONE)
	_add_box(st, Vector3(0, 3.45, 0), Vector3(TILE + 0.16, 0.24, TILE + 0.16), C_STONE_DARK)
	return _finish(st)

static func _mesh_tree() -> Mesh:
	var st := _begin()
	# Props stand on a street tile, so each carries its own ground slab - a
	# GridMap cell holds one item, and the street item can't share it.
	_add_box(st, Vector3(0, 0.05, 0), Vector3(TILE, 0.10, TILE), C_STREET)
	_add_box(st, Vector3(0, 0.65, 0), Vector3(0.28, 1.30, 0.28), C_TRUNK)
	_add_box(st, Vector3(0, 1.75, 0), Vector3(1.50, 0.90, 1.50), C_LEAF)
	_add_box(st, Vector3(0, 2.40, 0), Vector3(1.05, 0.65, 1.05), C_LEAF)
	return _finish(st)

static func _mesh_well() -> Mesh:
	var st := _begin()
	_add_box(st, Vector3(0, 0.05, 0), Vector3(TILE, 0.10, TILE), C_STREET)
	_add_box(st, Vector3(0, 0.35, 0), Vector3(1.50, 0.70, 1.50), C_STONE)
	_add_box(st, Vector3(0, 0.72, 0), Vector3(1.05, 0.05, 1.05), C_WATER)
	for sx: float in [-1.0, 1.0]:
		_add_box(st, Vector3(sx * 0.58, 1.30, 0), Vector3(0.16, 1.30, 0.16), C_TIMBER)
	_add_box(st, Vector3(0, 2.02, 0), Vector3(1.70, 0.14, 1.30), C_ROOF)
	return _finish(st)

# --- collision / navigation --------------------------------------------------

static func _building_shape() -> Array:
	return _box_shape(Vector3(TILE, BUILD_H, TILE), BUILD_H * 0.5)

static func _box_shape(size: Vector3, y_center: float) -> Array:
	var box := BoxShape3D.new()
	box.size = size
	return [box, Transform3D(Basis(), Vector3(0, y_center, 0))]

static func _floor_nav() -> NavigationMesh:
	var nav := NavigationMesh.new()
	var h: float = TILE * 0.5
	nav.vertices = PackedVector3Array([
		Vector3(-h, 0.11, -h),
		Vector3(h, 0.11, -h),
		Vector3(h, 0.11, h),
		Vector3(-h, 0.11, h),
	])
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	return nav
