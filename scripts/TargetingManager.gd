extends Node

enum TargetType {
	SINGLE,
	BLAST,
	ADJACENT,
	ROW,
	COLUMN,
	MASS
}

#@export var collision_mask: int
#@export var target_class: String = ""
#
#var current_hovered: Node = null
#var targeting_enabled := false
#var last_mouse_pos := Vector2(-1, -1)
#
#@onready var camera: Camera3D
#@onready var space_state: PhysicsDirectSpaceState3D
#var ray_query := PhysicsRayQueryParameters3D.new()
#
#func _ready() -> void:
	#set_process_unhandled_input(true)
#
#func _input(event) -> void:
	#if not targeting_enabled:
		#return
#
	#if event is InputEventMouseMotion:
		#if event.position != last_mouse_pos:
			#last_mouse_pos = event.position
			#_update_hovered_target(event.position)
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#if current_hovered:
			#emit_signal("target_clicked", current_hovered)
#
#func _update_hovered_target(mouse_pos: Vector2) -> void:
	#ray_query.from = camera.project_ray_origin(mouse_pos)
	#ray_query.to = ray_query.from + camera.project_ray_normal(mouse_pos) * 100
	#ray_query.collision_mask = collision_mask
	#ray_query.exclude = []
#
	#var result := space_state.intersect_ray(ray_query)
	#if result and result.collider:
		#var node = result.collider
		#while node and not (node.is_class(target_class) or is_class_custom(node)):
			#node = node.get_parent()
		#if node != current_hovered:
			#if current_hovered:
				#current_hovered.unhover()
			#current_hovered = node
			#current_hovered.hover()
	#else:
		#if current_hovered:
			#current_hovered.unhover()
			#current_hovered = null
#
#func configure_for_battle(new_camera: Camera3D) -> void:
	#targeting_enabled = true
	#target_class = "FormationSlot"
	#collision_mask = 1 << 2
	#camera = new_camera
	#space_state = camera.get_world_3d().direct_space_state
	#print("targeting configured for battle")
#
#func configure_for_overworld() -> void:
	#targeting_enabled = true
	#target_class = "InteractableObject"
	#collision_mask = 1 << 3
#
#func disable_targeting() -> void:
	#targeting_enabled = false
#
#func enable_targeting() -> void:
	#targeting_enabled = true
#
#func is_class_custom(node: Object) -> bool:
	#var script = node.get_script()
	#if script:
		#var global_class_name = script.get_global_name()
		#if global_class_name:
			#return global_class_name == target_class
	#return false
