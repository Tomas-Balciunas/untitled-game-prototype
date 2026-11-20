@tool
class_name RampTile
extends Node3D


enum Style { RAMP, STAIRS }

const GROUND_LAYER: int = 16

@export var style: Style = Style.RAMP:
	set(value):
		style = value
		_queue_rebuild()
@export var rise: float = 1.0:
	set(value):
		rise = value
		_queue_rebuild()
@export var length: float = 2.0:
	set(value):
		length = value
		_queue_rebuild()
@export var width: float = 2.0:
	set(value):
		width = value
		_queue_rebuild()
@export_range(2, 16) var steps: int = 4:
	set(value):
		steps = value
		_queue_rebuild()
@export var surface_offset: float = 0.1:
	set(value):
		surface_offset = value
		_queue_rebuild()
@export var material: Material:
	set(value):
		material = value
		_queue_rebuild()
@export var build_navigation: bool = true:
	set(value):
		build_navigation = value
		_queue_rebuild()

var _built: Array[Node] = []
var _pending: bool = false

func _ready() -> void:
	_rebuild()

func _queue_rebuild() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	_rebuild.call_deferred()

func _rebuild() -> void:
	_pending = false

	for node in _built:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_built.clear()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = _build_mesh()
	mesh_instance.material_override = material
	_add_built(mesh_instance)

	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = GROUND_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var convex := ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array(_wedge_points())
	shape.shape = convex
	body.add_child(shape)
	_add_built(body)

	if build_navigation:
		var region := NavigationRegion3D.new()
		region.name = "Navigation"
		region.navigation_mesh = _build_navmesh()
		_add_built(region)

func _add_built(node: Node) -> void:
	add_child(node)
	_built.append(node)

func _wedge_points() -> Array:
	var hl: float = length * 0.5
	var hw: float = width * 0.5
	var low: float = surface_offset
	var high: float = surface_offset + rise
	return [
		Vector3(-hw, 0.0, hl), Vector3(hw, 0.0, hl), Vector3(hw, 0.0, -hl), Vector3(-hw, 0.0, -hl),
		Vector3(-hw, low, hl), Vector3(hw, low, hl), Vector3(hw, high, -hl), Vector3(-hw, high, -hl),
	]

func _build_navmesh() -> NavigationMesh:
	var p: Array = _wedge_points()
	var lift := Vector3(0.0, 0.001, 0.0)
	var nav := NavigationMesh.new()
	nav.vertices = PackedVector3Array([p[7] + lift, p[6] + lift, p[5] + lift, p[4] + lift])
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	return nav

func _build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	if style == Style.STAIRS:
		var hl: float = length * 0.5
		var hw: float = width * 0.5
		var depth: float = length / float(steps)
		for i in range(steps):
			var back: float = hl - float(i) * depth
			var top: float = surface_offset + rise * float(i + 1) / float(steps)
			_box(st, Vector3(-hw, 0.0, back - depth), Vector3(hw, top, back))
	else:
		var p: Array = _wedge_points()
		_quad(st, [p[4], p[5], p[6], p[7]], Vector3(0.0, length, rise))
		_quad(st, [p[0], p[1], p[2], p[3]], Vector3.DOWN)
		_quad(st, [p[0], p[1], p[5], p[4]], Vector3.BACK)
		_quad(st, [p[3], p[2], p[6], p[7]], Vector3.FORWARD)
		_quad(st, [p[0], p[4], p[7], p[3]], Vector3.LEFT)
		_quad(st, [p[1], p[5], p[6], p[2]], Vector3.RIGHT)

	return st.commit()

func _box(st: SurfaceTool, lo: Vector3, hi: Vector3) -> void:
	_quad(st, [Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)], Vector3.UP)
	_quad(st, [Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z)], Vector3.DOWN)
	_quad(st, [Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)], Vector3.BACK)
	_quad(st, [Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(lo.x, hi.y, lo.z)], Vector3.FORWARD)
	_quad(st, [Vector3(lo.x, lo.y, lo.z), Vector3(lo.x, lo.y, hi.z), Vector3(lo.x, hi.y, hi.z), Vector3(lo.x, hi.y, lo.z)], Vector3.LEFT)
	_quad(st, [Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, hi.y, hi.z), Vector3(hi.x, hi.y, lo.z)], Vector3.RIGHT)

func _quad(st: SurfaceTool, pts: Array, outward: Vector3) -> void:
	var a: Vector3 = pts[0]
	var b: Vector3 = pts[1]
	var c: Vector3 = pts[2]
	var d: Vector3 = pts[3]

	if (b - a).cross(c - a).dot(outward) > 0.0:
		var swap: Vector3 = b
		b = d
		d = swap

	var n: Vector3 = outward.normalized()
	for v: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(n)
		st.set_uv(_uv(v, n))
		st.add_vertex(v)

func _uv(v: Vector3, n: Vector3) -> Vector2:
	var an := n.abs()
	if an.y >= an.x and an.y >= an.z:
		return Vector2(v.x, v.z) * 0.5
	if an.x >= an.z:
		return Vector2(v.z, -v.y) * 0.5
	return Vector2(v.x, -v.y) * 0.5
