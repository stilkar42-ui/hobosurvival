# Hobo Survival First-Pass Environment Tileset Spec

Date: 2026-04-18
Project: Hobo Survival
Engine Target: Godot 4.x
Scope: Standardized first-pass environment tileset foundation for camp clearings, forest edge terrain, roadside survival locations, and early shoreline/mud transitions.

## Purpose
This tileset foundation gives the repo a consistent visual and technical standard for environment art before a larger production art pass. It is deliberately scoped to current prototype needs and avoids decorative excess. The goal is a reusable, expandable standard that supports camp, forest clearing, and early labor-road traversal without locking the project into a noisy or overbuilt terrain library.

## Style Language
These reference images define:
- Palette: desaturated ember orange against cold blue-gray nights, damp earth brown, mossy olive, weathered canvas tan, soot black, stone gray, and ash-fog pale blue.
- Shape language: practical silhouettes, low ornamentation, softened but readable pixel clusters, compact props, and terrain forms that look walked, slept on, and worked around.
- Foliage density: dense at the map perimeter, restrained inside playable clearings, with vegetation acting as pressure and framing rather than visual clutter.
- Ground texture: compacted dirt first, then trampled wear, sparse grass, forest litter, mud, stones, and shoreline dampness; no bright fantasy turf.
- Readability target: immediate recognition of path, camp footprint, interactable clearings, and terrain edges in isometric view with controlled contrast and limited micro-noise.

## How This Supports The Game
### Core fantasy
The tileset reinforces endurance, earning, and return by making the world feel materially harsh but usable. Ground is not scenic filler; it shows where a man can walk, camp, work, or lose comfort.

### Survival loop
Terrain categories support the pressure -> effort -> relief loop:
- pressure in dark forest edge, wet ground, and rough roadside terrain
- effort in trampled paths, camp setup footprints, and work-worn surfaces
- relief in readable clearings, tended fire circles, and stable camp ground

### Work / travel / social systems
- Travel: path and clearing standards make route readability reliable.
- Work: labor-road spaces can share the same dirt/path/edge families as future yards, depots, camps, and temporary settlements.
- Social/world tone: muted surfaces and worn materials preserve dignity-under-attrition instead of caricature.

## Standard Tile Geometry
Use a single environment base standard for the prototype:

- Projection: 2D isometric diamond
- Base tile footprint: 128x64 px
- Logical cell: 1 ground tile = 1 terrain cell
- Recommended content safe area per base tile: 120x56 px
- Vertical object overdraw: allowed above the base footprint for props/trees, but ground atlases should stay inside the base footprint
- Tile anchor/origin: bottom-center of the diamond footprint
- Atlas padding: 8 px outer padding, 4 px spacing between atlas entries
- Variant count target:
  - hero/base terrain: 3-5 variants
  - transitions: 2-4 variants per directional family
  - scatter overlays: 4-8 lightweight variants

Rationale:
- `128x64` matches the current prototype’s readable isometric world language better than a tiny retro grid.
- It leaves enough room for subtle texture variation without forcing noisy detail.

## Value And Color Rules
- Keep base ground values in the low-mid range.
- Reserve brightest values for firelight, reflected water edges, and selective highlights on interactable props, not terrain everywhere.
- Grass should be gray-green or olive, never saturated emerald.
- Mud should skew cold brown/gray, not chocolate orange.
- Stone should read as worn river rock or fieldstone, not polished fantasy slabs.
- Use hue shifts sparingly: forest floor can lean cooler; camp footprints can lean warmer and drier.

## Terrain Category Standard
### 1. Base Ground Family
Use these as the foundational terrain set:
- `ground_dirt_compact`
- `ground_dirt_trampled`
- `ground_grass_sparse`
- `ground_forest_litter`
- `ground_camp_footprint`
- `ground_mud_damp`
- `ground_shore_wet`

### 2. Transition Family
Use terrain edge logic rather than bespoke scene painting:
- dirt <-> trampled
- dirt <-> sparse grass
- sparse grass <-> forest litter
- camp footprint <-> dirt
- mud damp <-> shore wet
- mud damp <-> dirt

### 3. Scatter Overlay Family
Keep these as overlay-capable support tiles:
- pebble clusters
- small stones
- stump cuts
- short log segments
- exposed roots
- dead grass tufts
- twig litter
- ash/char fragments near fire circles

### 4. Footprint/Use-Space Family
These are not gameplay systems. They are visual support tiles:
- fire ring ground
- tent apron wear
- work table wear
- log seating wear
- wash line damp patch
- stash traffic patch

### 5. Overlay/Shadow Family
Optional first-pass support:
- soft camp shadow wedge
- tree canopy shadow patch
- fire warmth tint overlay
- soot/ash overlay

Use these lightly. They should support readability, not become a second terrain system.

## Naming Convention
Format:

`env_<zone>_<family>_<material>_<shape>_<variant>`

Rules:
- lowercase only
- words separated with underscores
- no abbreviations except controlled suffixes
- two-digit variants: `v01`, `v02`, `v03`
- directional transitions use cardinal edge descriptors relative to the isometric atlas logic

Examples:
- `env_camp_ground_dirt_compact_full_v01`
- `env_camp_ground_dirt_trampled_full_v03`
- `env_forest_ground_grass_sparse_full_v02`
- `env_forest_transition_grass_to_litter_edge_ne_v01`
- `env_shore_transition_mud_to_water_corner_sw_v02`
- `env_camp_scatter_log_short_full_v01`
- `env_camp_overlay_shadow_soft_full_v01`

Controlled tokens:
- zones: `camp`, `forest`, `road`, `shore`, `common`
- families: `ground`, `transition`, `scatter`, `footprint`, `overlay`
- shapes:
  - `full`
  - `edge_nw`, `edge_ne`, `edge_se`, `edge_sw`
  - `corner_nw`, `corner_ne`, `corner_se`, `corner_sw`
  - `inner_nw`, `inner_ne`, `inner_se`, `inner_sw`
  - `strip_h`, `strip_v`

## Folder Structure
Create and maintain this structure:

```text
assets/
  tilesets/
    environment/
      first_pass/
        README.md
        manifest.json
        atlases/
          env_ground_base_a01_placeholder.svg
          env_ground_transition_a01_placeholder.svg
          env_scatter_overlays_a01_placeholder.svg
```

Future expansion:

```text
assets/
  tilesets/
    environment/
      first_pass/
      second_pass/
      production/
```

## Atlas Organization Standard
### Atlas A01: Ground Base
File: `env_ground_base_a01`

Contains:
- compact dirt full variants
- trampled dirt full variants
- sparse grass full variants
- forest litter full variants
- camp footprint full variants
- mud damp full variants
- shore wet full variants

Recommended atlas size:
- 2048x2048 px
- 8 columns x 8 rows capacity at `128x64` plus spacing/padding if exported as a packed raster sheet

### Atlas A02: Ground Transitions
File: `env_ground_transition_a01`

Contains:
- directional edges
- outer corners
- inner corners
- narrow strip transitions if needed

Recommended atlas size:
- 2048x2048 px

### Atlas A03: Scatter And Overlays
File: `env_scatter_overlays_a01`

Contains:
- logs
- stumps
- rocks
- roots
- ash
- mud patches
- soft overlays/shadows
- camp-use footprints

Recommended atlas size:
- 2048x2048 px

## First-Pass Tile List
This is the standard first-pass scope for the current prototype.

### Ground/Base
- `env_common_ground_dirt_compact_full_v01`
- `env_common_ground_dirt_compact_full_v02`
- `env_common_ground_dirt_compact_full_v03`
- `env_common_ground_dirt_trampled_full_v01`
- `env_common_ground_dirt_trampled_full_v02`
- `env_common_ground_dirt_trampled_full_v03`
- `env_common_ground_grass_sparse_full_v01`
- `env_common_ground_grass_sparse_full_v02`
- `env_common_ground_grass_sparse_full_v03`
- `env_forest_ground_forest_litter_full_v01`
- `env_forest_ground_forest_litter_full_v02`
- `env_forest_ground_forest_litter_full_v03`
- `env_camp_ground_camp_footprint_full_v01`
- `env_camp_ground_camp_footprint_full_v02`
- `env_shore_ground_mud_damp_full_v01`
- `env_shore_ground_mud_damp_full_v02`
- `env_shore_ground_shore_wet_full_v01`
- `env_shore_ground_shore_wet_full_v02`

### Path And Clearing Transitions
- `env_common_transition_dirt_to_trampled_edge_nw_v01`
- `env_common_transition_dirt_to_trampled_edge_ne_v01`
- `env_common_transition_dirt_to_trampled_edge_se_v01`
- `env_common_transition_dirt_to_trampled_edge_sw_v01`
- `env_common_transition_dirt_to_trampled_corner_nw_v01`
- `env_common_transition_dirt_to_trampled_corner_ne_v01`
- `env_common_transition_dirt_to_trampled_corner_se_v01`
- `env_common_transition_dirt_to_trampled_corner_sw_v01`
- `env_common_transition_dirt_to_grass_edge_nw_v01`
- `env_common_transition_dirt_to_grass_edge_ne_v01`
- `env_common_transition_dirt_to_grass_edge_se_v01`
- `env_common_transition_dirt_to_grass_edge_sw_v01`
- `env_forest_transition_grass_to_litter_edge_nw_v01`
- `env_forest_transition_grass_to_litter_edge_ne_v01`
- `env_forest_transition_grass_to_litter_edge_se_v01`
- `env_forest_transition_grass_to_litter_edge_sw_v01`
- `env_camp_transition_footprint_to_dirt_edge_nw_v01`
- `env_camp_transition_footprint_to_dirt_edge_ne_v01`
- `env_camp_transition_footprint_to_dirt_edge_se_v01`
- `env_camp_transition_footprint_to_dirt_edge_sw_v01`
- `env_shore_transition_mud_to_water_edge_nw_v01`
- `env_shore_transition_mud_to_water_edge_ne_v01`
- `env_shore_transition_mud_to_water_edge_se_v01`
- `env_shore_transition_mud_to_water_edge_sw_v01`

### Scatter Variants
- `env_common_scatter_rock_small_full_v01`
- `env_common_scatter_rock_small_full_v02`
- `env_common_scatter_rock_cluster_full_v01`
- `env_common_scatter_log_short_full_v01`
- `env_common_scatter_log_short_full_v02`
- `env_common_scatter_stump_cut_full_v01`
- `env_common_scatter_stump_cut_full_v02`
- `env_common_scatter_root_exposed_full_v01`
- `env_common_scatter_dead_grass_tuft_full_v01`
- `env_common_scatter_dead_grass_tuft_full_v02`
- `env_camp_scatter_ash_patch_full_v01`
- `env_camp_scatter_ash_patch_full_v02`

### Camp Footprint Support
- `env_camp_footprint_fire_ring_full_v01`
- `env_camp_footprint_tent_apron_full_v01`
- `env_camp_footprint_stash_wear_full_v01`
- `env_camp_footprint_work_area_full_v01`
- `env_camp_footprint_wash_line_damp_full_v01`

### Optional Overlay Support
- `env_common_overlay_shadow_soft_full_v01`
- `env_forest_overlay_canopy_shadow_full_v01`
- `env_camp_overlay_fire_warmth_full_v01`

## Godot 4.x Import Recommendations
For raster atlas exports:
- Compression: Lossless
- Mipmaps: Off
- Filter: Off
- Repeat: Disabled
- Detect 3D: Off
- Premult Alpha: Off unless the export pipeline requires it

For prototype placeholder atlases:
- Keep source files in SVG or layered PSD outside runtime if possible
- Export runtime atlases as PNG once art is approved

TileSet setup recommendations:
- Use Atlas Source per file
- Cell size: `128x64`
- Tile origin: bottom center
- Terrain sets:
  - `terrain_ground_base`
  - `terrain_path_wear`
  - `terrain_forest_edge`
  - `terrain_shore_mud`
- Keep scatter and overlays as separate atlas sources or scene tiles, not mixed into terrain autotiling unless repetition proves acceptable

## Packing Instructions
When the art pass begins:
1. Paint full ground variants first.
2. Paint edge transitions against final approved base variants.
3. Paint scatter on transparent backgrounds as separate atlas entries.
4. Keep each tile centered on the same diamond footprint grid.
5. Leave 4 px transparent buffer around every exported tile region to avoid bleeding.
6. Do not anti-alias outside the intended pixel-art treatment.
7. Test every atlas in Godot against:
   - camp clearing
   - forest edge
   - path through sparse grass
   - muddy shoreline edge

## Placeholder Atlas Policy
The placeholder atlases added in this pass are layout blueprints, not final art. They exist to:
- standardize atlas dimensions
- standardize naming
- lock the packing plan
- let future tools and artists work against a stable target

## Out Of Scope
This pass does not add:
- town pavement sets
- rail yard ties and ballast sets
- interior floor libraries
- weather-state swaps
- seasonal atlas swaps
- object sprite sheets for tents, trees, or characters

Those should be layered on top of this environment foundation rather than mixed into it prematurely.
