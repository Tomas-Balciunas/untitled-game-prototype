extends Node

var tiles := {
	"default": {
		"wall": {
		},
		"floor": {
		}
	},
	"crypt": {
		"wall": {
		},
		"floor": {
		}
	},
	"castle": {
		"wall": {
		},
		"floor": {
		}
	}
}
func get_tile_style(theme: String, type: String, style: String) -> PackedScene:
	if theme in tiles and type in tiles[theme] and style in tiles[theme][type]:
		return tiles[theme][type][style]
	push_error("Missing style: %s - %s - %s" % [theme, type, style])
	return tiles[theme][type][style]

func get_tile_scene(theme: String, tile_type: String) -> PackedScene:
	if theme in tiles and tile_type in tiles[theme]:
		return tiles[theme][tile_type]
	push_error("Missing tile: %s - %s" % [theme, tile_type])
	return tiles["default"]["floor"]  # Fallback

func get_scene(theme: String):
	if theme in tiles:
		return tiles[theme]
	push_error("Missing theme: %s" % [theme])
	return tiles["default"]  # Fallback
