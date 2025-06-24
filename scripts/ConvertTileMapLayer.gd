extends Node

@export var map_layer: TileMapLayer
@export var event_layer: TileMapLayer
@export var output_resource_path: String = "res://maps/handcrafted_map.tres"
@export var map_theme: String = "crypt"
@export var start_pos: Vector2i = Vector2i(2, 1)
@export var transitions: Dictionary = {}

func _ready():
	convert_to_resource()

func convert_to_resource():
	if not map_layer or not event_layer:
		push_error("MapLayer or EventLayer not assigned.")
		return

	# Get dimensions from MapLayer
	var used_rect = map_layer.get_used_rect()
	var map_width = used_rect.size.x
	var map_height = used_rect.size.y

	var data = []
	for y in range(used_rect.position.y, used_rect.position.y + map_height):
		var row = []
		for x in range(used_rect.position.x, used_rect.position.x + map_width):
			var tile = {"type": "empty", "style": "default", "event": null, "encounter": null}

			# Process MapLayer
			var map_cell = map_layer.get_cell_source_id(Vector2i(x, y))
			if map_cell != -1:
				var map_tile_data = map_layer.get_cell_tile_data(Vector2i(x, y))
				if map_tile_data:
					tile["type"] = map_tile_data.get_custom_data("type") if map_tile_data.get_custom_data("type") else "empty"
					tile["style"] = map_tile_data.get_custom_data("style") if map_tile_data.get_custom_data("style") else "default"

			# Process EventLayer
			var event_cell = event_layer.get_cell_source_id(Vector2i(x, y))
			if event_cell != -1:
				var event_tile_data = event_layer.get_cell_tile_data(Vector2i(x, y))
				if event_tile_data:
					var event = event_tile_data.get_custom_data("event")
					var encounter = event_tile_data.get_custom_data("encounter")
					tile["event"] = event if event and event != "" else null
					tile["encounter"] = encounter if encounter and encounter != "" else null

			row.append(tile)
		data.append(row)

	# Create or update the map resource
	var map_resource = MapData.new()
	map_resource.data = data
	map_resource.theme = map_theme
	map_resource.start_pos = start_pos
	map_resource.transitions = transitions

	ResourceSaver.save(map_resource, output_resource_path)
	print("Map resource saved to: %s" % output_resource_path)
