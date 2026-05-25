# Map Configuration Reference

All maps are declared in [`maps.json`](maps.json). Each top-level key is a map id used by `MapTransitionTriggerable.map_data.id` and `MapManager.get_map_data`.

## Common fields (handcrafted and procedural)

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Must match the JSON key. |
| `name` | string | yes | Display name. |
| `generation` | `"handcrafted"` \| `"procedural"` | yes | Selects the loader path in `dungeon.gd`. |
| `available_enemies` | string[] | yes | Character ids passed to `MapInstance.available_enemies` for random encounter composition. |
| `gear_tiers` | string[] | yes | Loot tiers used by `GearGenerator`. |

## Handcrafted-only fields

| Field | Type | Notes |
|---|---|---|
| `starting_position` | string `"(x, y)"` | Parsed as `Vector2i`. Player spawn tile. |
| `random` | string | Legacy flag, currently unused by the loader. |

A handcrafted map must also be registered in `MapManager.maps` (a dict of `id → PackedScene`).

## Procedural-only fields

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `tileset` | string | yes | — | One of `"default"`, `"crypt"`, `"castle"` (themes in `TilesetRegistry.THEMES`). |
| `return_map` | string | no | `""` | Map id reached via a portal placed at a corner of the spawn room. |
| `end_map` | string | no | `""` | Map id reached via a second portal placed at a corner of the farthest room. Only used when more than one room is generated. |
| `config` | object | yes | — | Generator parameters — see below. |

### `config` object

All ranges are `[min, max]` integer pairs and are inclusive on both ends.

| Field | Type | Default | Effect |
|---|---|---|---|
| `width` | int | `30` | Map width in player tiles. |
| `height` | int | `30` | Map height in player tiles. |
| `layout` | `"branching"` \| `"linear"` \| `"mixed"` \| `"maze"` | `"branching"` | Chain ordering + extra-corridor budget + room placement strategy. See **Layouts** below. |
| `density` | float `0.0–1.0` | `0.0` | Room placement tightness around a per-layout target. `0.0` = uniform random across the whole map; the layout's target is ignored. `1.0` = each room hugs its target within a window only slightly larger than the room itself. **For `linear`/`mixed`** the long-axis target is `(i + 0.5) / N` along the map; the short-axis target is the map center with up to ±25% jitter so the chain wanders into vertical empty space. **For `branching`** the target is the previous room's center, so high density clusters rooms tightly. |
| `corridor_curviness` | float `0.0–1.0` | `0.5` | Probability that any given corridor leg takes a perpendicular-offset midpoint waypoint. Affects the visible "wiggle" of corridors. Note: regardless of this setting, any corridor longer than 8 tiles in a single direction is automatically subdivided into multiple segments of ≤ 8 tiles each, with each waypoint offset perpendicularly — so long corridors always zigzag and never run dead-flat. |
| `room_count` | int range | `[5, 8]` | How many rooms to place. |
| `room_size` | int range | `[3, 8]` | Both width and height of each room sampled independently in this range, so rooms vary from tight closets to large halls. |
| `chest_count` | int range | `[1, 3]` | How many chests to scatter across rooms (corridor tiles excluded). |
| `enemy_group_count` | int range | `[2, 5]` | How many enemy spawn markers to place. Distributed across non-spawn rooms and (with lower probability) pure corridor cells — see `corridor_enemy_chance`. |
| `corridor_enemy_chance` | float `0.0–1.0` | `0.2` | Probability per enemy that the spawner lands on a pure corridor tile (one outside every room) instead of inside a room. `0.0` keeps the original room-only behavior; `0.2` means roughly one in five enemies will be patrolling a hallway. Falls back to the other pool if the chosen one is exhausted. |
| `extra_corridors` | int range | depends on layout | Number of extra corridors added beyond the spanning chain. Defaults: branching `[1, 3]`, mixed `[1, 2]`, linear `[0, 0]`. Override to force a specific feel. |
| `branch_count` | int range | depends on layout | Number of dead-end spur corridors added after the main chain. Each picks a random existing room and runs 5–14 tiles in a random cardinal direction; 60% of branches end in a small extra room. Defaults: linear `[1, 3]`, mixed `[1, 2]`, branching `[0, 0]`. |
| `enemy_level_range` | int range | `[1, 3]` | Reserved — not currently consumed by the encounter builder. |
| `ceiling` | bool | `false` | When true, places `ITEM_CEILING` tiles at GridMap y-layer 2 over every floor cell. Closes off the top of the dungeon so the player sees a roof above instead of skybox. No collision (player can't reach it anyway). Combine with darker lighting for claustrophobic crawls. |
| `bake_navmesh` | bool | `true` | When true, the generator builds one combined `NavigationMesh` with greedy-merged rectangular polygons over all floor tiles and assigns it to the parent `NavigationRegion3D`. The per-cell navmesh stitching that `GridMap.bake_navigation` would otherwise do is disabled. **Effect**: a 5-tile corridor becomes one polygon instead of five; a 10×10 room becomes one instead of one hundred. NavigationAgent A* cost drops by ~10–50× on large maps. Disable only if you want per-cell precision for very irregular tile shapes. |
| `merge_walls` | bool | `true` | When true, the per-cell wall `BoxShape3D` is dropped from the `MeshLibrary` and the generator instead places a single `StaticBody3D` (named `MergedWalls`) with greedy-merged box shapes — long walls become one collider each. Drops collider count from ~30k to typically a few hundred on big maps. Disable if you want per-cell collision boundaries for some custom interaction. |

### Layouts

- **`branching`** — random room placement order; spanning chain in placement order; extra loops linking non-consecutive rooms. Explorable dungeon with side paths.
- **`linear`** — rooms sorted by Manhattan distance from `rooms[0]` to form a single chain; long-axis targeting at density > 0; no extra corridors by default; 1–3 dead-end branches. Clear start → end progression.
- **`mixed`** — same distance-ordered chain as linear, plus 1–2 extra corridors for occasional shortcuts.
- **`maze`** — rooms placed in a roughly square grid spanning the whole map (cells × rows ≈ ⌈√room_count⌉²); spanning chain in **randomized** order so corridors weave across the grid; default `extra_corridors: [3, 6]` adds many loops; default `branch_count: [4, 8]` adds many dead ends. Uniform spread, lots of paths, easy to get turned around. Pair with a higher `room_count` (e.g. `[10, 16]`) for the full effect.

### Portals

Both portals (`return_map`, `end_map`) are placed at a corner of the relevant room. The corner is chosen to minimise overlap with corridor entry sides — corners adjacent to a side with a corridor are penalised, ties broken by distance from the room's spawn point.

Each portal is rendered as a glowing blue cylinder + `OmniLight3D` via `MapGenerator._add_portal_visual`. Edit `MapGenerator.PORTAL_COLOR` to change the colour.

### Tilesets

Defined in `TilesetRegistry.THEMES` as `{ floor_color, wall_color, ceiling_color }` per theme. To add a new theme, append an entry to the dict and reference its key as `tileset` in a procedural map config.

```gdscript
const THEMES := {
	"default": { "floor_color": Color(0.65, 0.65, 0.65), "wall_color": Color(0.45, 0.45, 0.5), "ceiling_color": Color(0.20, 0.20, 0.22) },
	"crypt":   { "floor_color": Color(0.32, 0.30, 0.32), "wall_color": Color(0.24, 0.22, 0.28), "ceiling_color": Color(0.14, 0.13, 0.16) },
	"castle":  { "floor_color": Color(0.72, 0.62, 0.50), "wall_color": Color(0.55, 0.48, 0.42), "ceiling_color": Color(0.40, 0.35, 0.30) },
}
```

#### How tiles are consumed by the generator

The generator never touches mesh files directly. It calls `TilesetRegistry.get_mesh_library(theme)`, which returns a `MeshLibrary` containing three items keyed by integer ids:

| Id | Constant | Purpose |
|---|---|---|
| `0` | `ITEM_FLOOR` | Placed on GridMap y-layer 0 for every walkable tile. Carries the floor mesh **and** a per-tile `NavigationMesh` polygon used by AI pathfinding. |
| `1` | `ITEM_WALL` | Placed on y-layer 0 for every wall tile. Carries the wall mesh **and** a `BoxShape3D` collision shape that blocks the player. |
| `2` | `ITEM_CEILING` | Placed on y-layer 2 over every floor tile when `ceiling: true`. Mesh only, no collision or navmesh. |

`apply_to_scene` writes these items into a runtime `GridMap` (4 GridMap cells per player tile, matching the existing handcrafted map convention).

#### Tile asset overrides (filesystem-driven)

`TilesetRegistry` checks `res://art/tiles/<theme>/<slot>.<ext>` for each tile slot before falling back to the procedural BoxMesh. Drop a file in and it's picked up the next time the theme's `MeshLibrary` is built (typically next game start, since the result is cached).

| Slot | Required file (one of these) |
|---|---|
| Floor | `res://art/tiles/<theme>/floor.{tres,res,glb,gltf,obj}` |
| Wall  | `res://art/tiles/<theme>/wall.{tres,res,glb,gltf,obj}` |
| Ceiling | `res://art/tiles/<theme>/ceiling.{tres,res,glb,gltf,obj}` |

Each path is checked in the extension order shown; first hit wins. The loaded resource may be either:

- A `Mesh` resource (`.tres`/`.res`) — used directly.
- A `PackedScene` (`.glb`/`.gltf`/`.tscn`) — the first `MeshInstance3D` found via depth-first walk supplies the mesh.

The custom mesh is expected to author its own origin (typically at the bottom of the tile). The registry applies an identity transform when a custom mesh is found, vs the procedural Y-offset used for the box fallback. Wall collision and floor navigation polygons stay the same regardless of the visual mesh — only the visual is swapped.

Any slot that doesn't have an override file falls back to the colored box for that theme. So you can ship art for only walls if you want, and the floor + ceiling will keep the procedural look.

#### Other customization paths

**1. Tint only.** Change the `Color` entries in `THEMES`. Simplest, keeps the box-shaped tiles.

**2. Textured boxes.** Edit `_make_material` in `TilesetRegistry.gd` to return a `StandardMaterial3D` with `albedo_texture` set instead of `albedo_color`. Add a per-theme texture path to the `THEMES` dict if you want different art per theme:

```gdscript
const THEMES := {
	"crypt": { "floor_tex": preload("res://art/floor_stone.png"), ... },
}

func _make_material(theme_cfg: Dictionary, slot: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = theme_cfg["%s_tex" % slot]
	return m
```

Update the `_build` calls accordingly.

**3. Custom meshes (full models).** Replace the `BoxMesh.new()` calls in `_build` with `load("res://art/tiles/floor.glb")` (or `.gltf`/`.tres`). The library entry accepts any `Mesh` resource. Adjust `set_item_mesh_transform` so the loaded mesh's origin aligns with the cell origin:

```gdscript
var floor_mesh: Mesh = load("res://art/crypt/floor_tile.glb").get_meshes()[0]
lib.set_item_mesh(ITEM_FLOOR, floor_mesh)
lib.set_item_mesh_transform(ITEM_FLOOR, Transform3D(Basis(), Vector3(0, 0, 0)))
```

If your mesh has extra detail (decorative pillars, trim), it'll appear in every cell — keep variations subtle or carve them out via different item ids.

#### Pre-baked MeshLibrary (alternative)

If you already have a `MeshLibrary` `.tres` (the way `tileset white.tres` and `maps/crypt/mesh/crypt_00.tres` are authored in the editor), you can skip `TilesetRegistry`'s runtime build entirely. Edit `get_mesh_library` to load and return your pre-baked library for that theme:

```gdscript
func get_mesh_library(theme: String) -> MeshLibrary:
	if theme == "crypt":
		return load("res://art/crypt/crypt_tileset.tres")
	# ...fall through to runtime build for other themes
```

Important when authoring a `.tres` MeshLibrary manually: keep the item ids matching `ITEM_FLOOR=0`, `ITEM_WALL=1`, `ITEM_CEILING=2`, and make sure floor items carry a `NavigationMesh` resource so AI pathfinding still works.

## Persistence

Procedural map state survives save/load:
- The RNG `seed` per map id is stored in `MapInstance.seeds` and regenerates the same layout on load.
- Cleared encounters, chest state, player position, and per-map encounter compositions are all preserved.

To force a fresh layout for a map, clear its entry from `MapInstance.seeds` before re-entering.

## Example — procedural

```json
"random_crypt_01": {
	"id": "random_crypt_01",
	"name": "Random Crypt",
	"generation": "procedural",
	"tileset": "crypt",
	"return_map": "beginning_area_01",
	"end_map": "beginning_area_01",
	"config": {
		"width": 140,
		"height": 80,
		"layout": "linear",
		"density": 0.7,
		"room_count": [5, 9],
		"room_size": [3, 6],
		"chest_count": [2, 4],
		"enemy_group_count": [3, 5]
	},
	"available_enemies": ["0000", "e_enemy_002", "e_enemy_001"],
	"gear_tiers": ["tier_1", "tier_2"]
}
```

## Example — handcrafted

```json
"beginning_area_01": {
	"id": "beginning_area_01",
	"name": "Beginning Area",
	"generation": "handcrafted",
	"starting_position": "(0, 0)",
	"available_enemies": ["0000", "e_enemy_002", "e_enemy_001"],
	"gear_tiers": ["tier_1", "tier_2"]
}
```
