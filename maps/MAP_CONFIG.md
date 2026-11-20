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
| `starting_height` | float | Optional, default `0.0`. World y of the spawn tile's floor, for maps that start on a raised level. The player settles onto the floor below it within a few frames. |
| `random` | string | Legacy flag, currently unused by the loader. |

Elevation in a handcrafted map needs **collision on every walkable surface** (physics layer 1 or the `ground` layer 5): the player finds its height by casting a ray down at the destination tile, and a floor with no collider is invisible to it (the move then keeps the current height, which is how flat maps without floor collision keep working). Use `RampTile` (`maps/_ramp/ramp_tile.gd`, `@tool`) for slopes: add it as a node, pick `RAMP` or `STAIRS`, and rotate it so its local -Z points uphill. It builds its own mesh, ground-layer collision and a sloped navigation region. Ledge faces should have layer-1 collision so the movement rays block them. Custom stairs (any mesh) work if their collider is one smooth slope of at most 60° (a convex hull over the steps is ideal) on layer 1 or 5: on or onto a slope the party can climb or descend up to 2.5 per tile. Every floor at the top and bottom needs collision too, and the top of the stairs should meet its floor.

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
| `corridor_curviness` | float `0.0–1.0` | `0.5` | Probability that any given corridor leg takes a perpendicular-offset midpoint waypoint. Affects the visible "wiggle" of corridors. Note: regardless of this setting, any corridor longer than 8 tiles in a single direction is automatically subdivided into segments about 8 tiles long, with each waypoint offset perpendicularly — so long corridors always zigzag and never run dead-flat. The leg between two waypoints is routed, not drawn as a fixed L: see **Corridor routing** below. |
| `room_count` | int range | `[5, 8]` | How many rooms to place. |
| `room_size` | int range | `[3, 8]` | Both width and height of each room sampled independently in this range, so rooms vary from tight closets to large halls. |
| `chest_count` | int range | `[1, 3]` | How many chests to place. Bare dead-end tips (spurs at least two tiles long) are filled first, up to half the count, so dead ends are worth walking; the rest go on non-corridor tiles of rooms other than the spawn room. Chests block movement, so no two ever touch (even diagonally) and none is placed where it would wall off floor. |
| `enemy_group_count` | int range | `[2, 5]` | How many enemy spawn markers to place. Distributed across non-spawn rooms and (with lower probability) pure corridor cells — see `corridor_enemy_chance`. A cramped map may place fewer: see `enemy_spacing` / `enemy_spawn_clearance`. |
| `enemy_spacing` | int | `4` | Minimum Manhattan distance between two enemy spawns, so fights don't chain back to back. |
| `enemy_spawn_clearance` | int | `6` | Minimum walking distance (steps) from the player spawn to any enemy spawn. |
| `pillar_chance` | float `0.0–1.0` | `0.3` | Chance a room at least `pillar_min_size` on both sides gets a pillar grid: single-tile pillars at odd offsets from the room centre on both axes, off the outer ring. No two pillars touch, so the room stays connected and its centre (the spawn) stays clear. Pillars are ordinary wall tiles. |
| `pillar_min_size` | int | `5` | Smallest room side that can get pillars (never below 5). |
| `corridor_enemy_chance` | float `0.0–1.0` | `0.2` | Probability per enemy that the spawner lands on a pure corridor tile (one outside every room) instead of inside a room. `0.0` keeps the original room-only behavior; `0.2` means roughly one in five enemies will be patrolling a hallway. Falls back to the other pool if the chosen one is exhausted. |
| `extra_corridors` | int range | depends on layout | Number of extra corridors added beyond the spanning chain. Defaults: branching `[1, 3]`, mixed `[1, 2]`, linear `[0, 0]`. Override to force a specific feel. |
| `branch_count` | int range | depends on layout | Number of dead-end spur corridors added after the main chain. Each picks a random existing room and runs 5–14 tiles in a random cardinal direction, ending in a small extra room when one fits; a branch with no room leaves a bare tip, which chest placement fills first. Defaults: linear `[1, 3]`, mixed `[1, 2]`, branching `[0, 0]`. |
| `enemy_level_range` | int range | `[1, 3]` | Enemy levels, scaled by walking distance from the spawn: each marker's range tops out at `min + round(depth × (max − min))` (depth 0 at the spawn, 1 at the farthest tile) and starts one below that (never under `min`). `EnemyController` rolls each enemy's level inside the marker's range. |
| `ceiling` | bool | `false` | When true, places `ITEM_CEILING` tiles at GridMap y-layer 2 over every floor cell. Closes off the top of the dungeon so the player sees a roof above instead of skybox. No collision (player can't reach it anyway). Combine with darker lighting for claustrophobic crawls. |
| `bake_navmesh` | bool | `true` | When true, the generator builds one combined `NavigationMesh` with greedy-merged rectangular polygons over all floor tiles and assigns it to the parent `NavigationRegion3D`. The per-cell navmesh stitching that `GridMap.bake_navigation` would otherwise do is disabled. **Effect**: a 5-tile corridor becomes one polygon instead of five; a 10×10 room becomes one instead of one hundred. NavigationAgent A* cost drops by ~10–50× on large maps. Disable only if you want per-cell precision for very irregular tile shapes. |
| `merge_walls` | bool | `true` | When true, the per-cell wall `BoxShape3D` is dropped from the `MeshLibrary` and the generator instead places a single `StaticBody3D` (named `MergedWalls`) with greedy-merged box shapes — long walls become one collider each. Drops collider count from ~30k to typically a few hundred on big maps. Disable if you want per-cell collision boundaries for some custom interaction. |

### Corridor routing

Each corridor leg is the cheapest path between its two waypoints (weighted A* over tile + heading, `MapGenerator._route`). The costs, not config keys, decide the look — they're the `ROUTE_*` constants at the top of the routing section:

| Step | Cost | Effect |
|---|---|---|
| New tile | 1 | |
| New tile with floor directly beside it (across the direction of travel) | +8 per side | Corridors stay one tile wide, never hug a room wall, and enter rooms straight through one wall tile — so openings stay doorable instead of becoming archways. |
| New tile with an existing corridor two tiles to its side | +1 per side | Discourages thin parallel corridors and twin entrances next to an existing one. |
| Existing corridor | 0.75 | A corridor joins one going its way instead of laying a parallel copy. |
| Room the corridor starts or ends in | 1 | |
| Any other room | 3 | A corridor cuts through a third room only when going round is much longer. |
| New opening through a room's corner tile | +4 | Keeps entrances off corners (portals live there). Walking an existing corner opening is free. |
| Turn | 0.6 | Legs stay L-shaped; the old coin flip for which way the L bends now breaks ties. |

A leg can't start by doubling back on the previous leg's heading, which used to leave the overshoot past each waypoint as a dead-end stub. Routing changes corridor shapes only; rooms, the chain order and every invariant below are unchanged, and `gen_preview` validates them.

### Doors, locks and keys

| Field | Type | Default | Effect |
|---|---|---|---|
| `door_chance` | float `0.0–1.0` | `0.30` | Probability a room's chosen entrance becomes a door. At most one door per room. |
| `corridor_door_chance` | float `0.0–1.0` | `0.12` | Same for corridor chokepoints (the midpoint of a straight run of ≥ 3 pure-corridor tiles). |
| `max_door_width` | int | `1` | Openings wider than this are **archways**: never cut, never doored, never lockable. Keeps one door equal to one panel with one id. |
| `max_doors` | int | `12` | Ceiling. Locked doors are retained first, then the remainder round-robin by region so density stays spatially even. |
| `door_lock_chance` | float `0.0–1.0` | `0.35` | Probability an eligible threshold is locked. |
| `max_locked_doors` | int | `3` | A **ceiling, not a quota**. Only bridges of the region graph are lockable, and loop corridors destroy bridges — so a heavily looped seed legitimately yields fewer locks, or none, and warns. |
| `door_trap_chance` | float `0.0–1.0` | `0.04` | Never rolled on a locked door: one obstacle per threshold. |
| `max_trapped_doors` | int | `2` | Bounds how many opener dialogs a map can demand. |
| `chest_lock_chance` | float `0.0–1.0` | `0.25` | Probability a chest is locked. Inert while `max_locked_chests` is 0. |
| `max_locked_chests` | int | `0` | Only chests in regions reachable before any door lock are eligible, so a locked chest is never behind a locked door. |
| `key_enemy_drop_chance` | float `0.0–1.0` | `0.0` | Probability a key is carried by an enemy group instead of sitting in a chest. |
| `reward_chest_quantity` | int | `4` | Items in the chest a locked door guards. Those chests also use `Contents.BOTH` and are never trapped. |

**Invariants an implementer must not break.**

1. Door ids come from tile coordinates (`door_<x>_<y>_<axis>`), so they are stable across regeneration and across any change in generation order — unlike the positional chest ids.
2. Only **bridge** edges of the region graph may be locked, and every key is sited strictly inside the region set reachable *before* that lock is placed. By induction the locks are openable in placement order, so the dungeon is always completable.
3. A key is never placed inside a locked container, which makes dependency cycles impossible.
4. A locked door always guards a region containing a chest — `_ensure_region_chest` adds one, constrained to tiles inside that region, and the lock is abandoned if it cannot.
5. The first eligible bridge on the spawn → end-portal path is locked deliberately, so the feature gates progression rather than only decorating side rooms.

### Elevation (ramps and stairs)

Off unless `ramp_count` is set. One level is `TilesetRegistry.LEVEL_HEIGHT` (1.0, one GridMap y-layer); a ramp tile climbs exactly one level, so two moves (tile edge → ramp centre → next tile) each rise half a level.

| Field | Type | Default | Effect |
|---|---|---|---|
| `ramp_count` | int range | `[0, 0]` | How many ramp tiles to place. A **ceiling, not a quota**: see the invariant below. Loop-heavy layouts (`branching`, `maze`) often place fewer and warn. |
| `level_range` | int range | `[-2, 2]` | Lowest and highest level an area may sit at. The spawn area is always level 0, so the range is widened to include 0. |
| `ramp_style` | `"ramp"` \| `"stairs"` \| `"mixed"` | `"mixed"` | Visual only; collision is the same smooth wedge for both. `mixed` picks per ramp. |
| `ramp_up_chance` | float `0.0–1.0` | `0.3` | Probability the **first** ramp on each route out of the spawn area climbs rather than descends. Flipped when it would leave `level_range`. |
| `ramp_trend` | float `0.0–1.0` | `0.85` | Probability each later ramp keeps the direction of the ramp before it on the same route, so routes keep descending (or climbing) instead of see-sawing. A route still turns back when it reaches the edge of `level_range`, so a long descent needs a range with room below 0 (with 3–6 ramps, `[-2, 2]` gives about 1 reversal per spawn → end route, `[-5, 0]` about 0.6). |
| `ramp_spacing` | int | `4` | Minimum Manhattan distance between two ramps (at least 2, which keeps a flat tile between them). |

**Invariant.** A ramp only goes on a straight, one-wide, pure-corridor tile that is a **bridge** of the floor graph (removing it disconnects its two ends). So no ramp is ever on a loop, the flat areas between ramps form a tree, and any per-area level is consistent: every pair of neighbouring floor tiles still meets at the same height, so the floor stays one walkable graph and the door/region/key logic above is untouched. Ramps also avoid the spawn, portals, chests, enemy spawns, door tiles and each other's ends. Elevation runs **after** doors, so turning it on doesn't change an existing seed's rooms, doors, chests or enemies. `gen_preview` validates the invariant on every seed.

Geometry: floors go on y-layer `level`; walls stack whole `ITEM_WALL` pieces covering at least the lowest neighbouring floor to two levels above the highest, **widened to even levels** so every piece starts on an even layer. That keeps the wall texture aligned between neighbouring columns; the extra level sits below every adjacent floor or above the ceiling. Never scale a wall piece to fill an odd span: the crypt wall's `BoxMesh` UVs stretch over the whole box, so a half-height copy squashes the texture (this happened, and is why there is no low-wall item). Ceilings sit at `level + 2`; over a ramp the uphill half's ceiling is one level higher, and an `ITEM_WALL` block at `level + 2` over the downhill half closes the step (its top level is above every ceiling, and its one visible face has no coplanar wall beside it, so its texture phase doesn't matter). Ramps are `RampTile` nodes under a `Ramps` node. `MergedFloors` (ground layer) gives the player's ground probe something to hit; the combined navmesh merges flat tiles per level and adds one sloped quad per ramp.

### Floor hazards

Off unless `hazards` is set. Each entry places patches of one hazard (a `Hazard` resource under `res://hazard/`, looked up by `id`):

```json
"hazards": [
	{ "id": "poison_floor", "count": [1, 3], "size": [1, 3], "corridor_chance": 0.3 },
	{ "id": "fire_floor",   "count": [0, 2], "size": [1, 2], "corridor_chance": 0.4 }
]
```

| Field | Type | Default | Effect |
|---|---|---|---|
| `id` | string | — | Hazard id. Unknown ids are skipped with a warning when the scene is built. |
| `count` | int range | `[1, 2]` | Patches of this hazard. Each gets 10 placement attempts and is dropped if none fit. |
| `size` | int range | `[1, 2]` | Room patches: width and height, each rolled separately and clipped to the room. Corridor patches: run length along the corridor. |
| `corridor_chance` | float `0.0–1.0` | `0.3` | Probability a patch goes on a pure-corridor run instead of inside a (non-spawn) room. A one-wide corridor patch can't be walked around. |

Patches never cover the spawn, portals, chests, door tiles, ramps or another patch, and each sits on a single level. Hazards hurt but never block, so connectivity and the door/key invariants don't change. They're placed last, so adding `hazards` to an existing map doesn't move anything else in its seeds. `gen_preview` validates all of this.

**Handcrafted maps:** add a `HazardTile` node (`hazard/hazard_tile.gd`, `@tool`) at the centre of a patch's first tile, set its `hazard` and `size` (tiles toward +X/+Z; rotation is ignored), and match its `surface_offset` to the floor's thickness.

**New hazard types:** make a `Hazard` `.tres` anywhere under `res://hazard/` with a unique `id`. Fields: `damage` (flat) + `max_hp_ratio` (share of max HP) per step, `damage_type`, an optional `effect` (refreshed rather than stacked if the member already has one with the same script), and `color` / `opacity` / `flow_speed` / `light_energy` for the look.

`generate()` must stay free of autoload references, including in functions it never calls: GDScript resolves autoload identifiers when the script is compiled, so one reference anywhere stops the whole generator loading outside a running project. Trap *selection* therefore happens in `_populate_doors`, not during generation.

### Layouts

- **`branching`** — random room placement order; spanning chain in placement order; extra loops linking non-consecutive rooms. Explorable dungeon with side paths.
- **`linear`** — rooms sorted by Manhattan distance from `rooms[0]` to form a single chain; long-axis targeting at density > 0; no extra corridors by default; 1–3 dead-end branches. Clear start → end progression.
- **`mixed`** — same distance-ordered chain as linear, plus 1–2 extra corridors for occasional shortcuts.
- **`maze`** — rooms placed in a roughly square grid spanning the whole map (cells × rows ≈ ⌈√room_count⌉²); spanning chain in **randomized** order so corridors weave across the grid; default `extra_corridors: [3, 6]` adds many loops; default `branch_count: [4, 8]` adds many dead ends. Uniform spread, lots of paths, easy to get turned around. Pair with a higher `room_count` (e.g. `[10, 16]`) for the full effect.

### Portals

Both portals (`return_map`, `end_map`) are placed at a corner of the relevant room. The corner is chosen to minimise overlap with corridor entry sides — corners adjacent to a side with a corridor are penalised, ties broken by distance from the room's spawn point. A corridor running along the room's edge can pass through a corner; a corner that is then the only way between two parts of the floor (a cut tile) is avoided, since stepping on a portal leaves the map. `gen_preview` validates this.

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
| `0` | `ITEM_FLOOR` | Placed on GridMap y-layer `level` for every flat walkable tile (0 without elevation). Carries the floor mesh **and** a per-tile `NavigationMesh` polygon used by AI pathfinding. |
| `1` | `ITEM_WALL` | Two levels tall, stacked on even y-layers. Carries the wall mesh **and** a `BoxShape3D` collision shape that blocks the player. |
| `2` | `ITEM_CEILING` | Placed on y-layer `level + 2` over every floor tile when `ceiling: true`. Mesh only, no collision or navmesh. |

Ramps reuse the theme's floor colour via `TilesetRegistry.get_floor_material(theme)`; a custom floor mesh override is not applied to them.

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
