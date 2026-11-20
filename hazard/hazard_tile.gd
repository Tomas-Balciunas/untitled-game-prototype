@tool
class_name HazardTile
extends Node3D


const TILE_SIZE: float = 2.0
const GROUP: StringName = &"hazard_tile"
const HEIGHT_TOLERANCE: float = 0.75
const SHADER: Shader = preload("res://hazard/hazard_floor.gdshader")

@export var hazard: Hazard:
	set(value):
		hazard = value
		_queue_rebuild()
@export var size: Vector2i = Vector2i.ONE:
	set(value):
		size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		_queue_rebuild()
@export var surface_offset: float = 0.11:
	set(value):
		surface_offset = value
		_queue_rebuild()

var _built: Array[Node] = []
var _pending: bool = false

func _ready() -> void:
	add_to_group(GROUP)
	_rebuild()

func covers(tile: Vector2i, height: float) -> bool:
	var origin := Vector2i(roundi(global_position.x / TILE_SIZE), roundi(global_position.z / TILE_SIZE))
	var rel: Vector2i = tile - origin
	if rel.x < 0 or rel.y < 0 or rel.x >= size.x or rel.y >= size.y:
		return false
	return absf(height - (global_position.y + surface_offset)) <= HEIGHT_TOLERANCE

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

	if hazard == null:
		return

	var extent := Vector2(size) * TILE_SIZE
	var centre := Vector3((size.x - 1) * TILE_SIZE * 0.5, surface_offset, (size.y - 1) * TILE_SIZE * 0.5)

	var plane := PlaneMesh.new()
	plane.size = extent

	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("hazard_color", hazard.color)
	material.set_shader_parameter("opacity", hazard.opacity)
	material.set_shader_parameter("flow_speed", hazard.flow_speed)
	material.set_shader_parameter("patch_size", extent)

	var overlay := MeshInstance3D.new()
	overlay.name = "Overlay"
	overlay.mesh = plane
	overlay.material_override = material
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay.position = centre
	_add_built(overlay)

	if hazard.light_energy > 0.0:
		var light := OmniLight3D.new()
		light.name = "Glow"
		light.light_color = hazard.color
		light.light_energy = hazard.light_energy
		light.omni_range = maxf(extent.x, extent.y) * 0.5 + 2.0
		light.shadow_enabled = false
		light.position = centre + Vector3(0.0, 0.5, 0.0)
		_add_built(light)

func _add_built(node: Node) -> void:
	add_child(node)
	_built.append(node)
