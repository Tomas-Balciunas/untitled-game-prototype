extends Area3D
class_name Interactable

@export var interact_distance: float = 3.0
@export var highlight_on_hover: bool = true

@onready var player: Node3D = get_tree().get_root().get_node("Main/Player")

var was_in_range := false

func _ready() -> void:
	if not $CollisionShape3D:
		push_warning("Interactable requires a CollisionShape3D child")

	self.input_event.connect(_on_input_event)
	MapBus.map_finished_loading.connect(on_map_loaded)

func _on_input_event(_camera: Camera3D, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _can_interact():
			_interact()

func _can_interact() -> bool:
	if player == null:
		return false
		
	return player.global_position.distance_to(global_position) <= interact_distance

func _interact() -> void:
	print("Interacted with ", name)

func _process(_delta: float) -> void:
	var dist := player.global_position.distance_to(global_position)
	var in_range := dist <= interact_distance
	
	if highlight_on_hover and player != null:
		_set_highlight(dist <= interact_distance)
		
	if was_in_range and not in_range:
		InteractableBus.interactable_area_left.emit(self)

	was_in_range = in_range

func _set_highlight(enable: bool) -> void:
	for child in get_children():
		if child is MeshInstance3D:
			if not child.material_override:
				child.material_override = StandardMaterial3D.new()
			
			var color := Color(0.88, 0.588, 0.88) if enable else Color(1, 1, 1)
			child.material_override.albedo_color = color

func on_map_loaded(_map_data: Dictionary) -> void:
	pass
