extends GridMap

@export var texture: Texture = null


func _ready() -> void:
	if texture == null:
		return
	
	for id: int in self.mesh_library.get_item_list():
		var item: ArrayMesh = self.mesh_library.get_item_mesh(id)
		var test: StandardMaterial3D = item.surface_get_material(0)
		test.albedo_texture = texture
