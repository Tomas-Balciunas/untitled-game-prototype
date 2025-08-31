extends Area3D
class_name Interactable

@export var interact_distance: float = 3.0
@export var highlight_on_hover: bool = true

@onready var player: Node3D = get_tree().get_root().get_node("Main/Dungeon/Player")

func _ready():
	if not $CollisionShape3D:
		push_warning("Interactable requires a CollisionShape3D child")

	self.input_event.connect(_on_input_event)

func _on_input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _can_interact():
			_interact()

func _can_interact() -> bool:
	if player == null:
		return true
	return player.global_position.distance_to(global_position) <= interact_distance

func _interact():
	print("Interacted with ", name)

func _process(delta):
	if highlight_on_hover and player != null:
		var dist = player.global_position.distance_to(global_position)
		_set_highlight(dist <= interact_distance)

func _set_highlight(enable: bool):
	for child in get_children():
		if child is MeshInstance3D:
			if not child.material_override:
				child.material_override = StandardMaterial3D.new()
			
			var color = Color(0.88, 0.588, 0.88) if enable else Color(1, 1, 1)
			child.material_override.albedo_color = color
