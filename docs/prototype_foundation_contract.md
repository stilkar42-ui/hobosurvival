# Prototype Foundation Contract

## Status

This is an ugly-but-working prototype phase.

The goal is gameplay clarity, not beauty. The current world presentation exists
to support movement, collision clarity, interaction approach, simple town
navigation, and continued loop construction.

Do not treat the current visual foundation as final art direction.

## Temporary Art Policy

Current runtime camp, town, and player art is placeholder/template material.

It exists to keep the prototype readable while the game loop is rebuilt. These
assets are not the long-term art standard. They are expected to be replaced by
hand-drawn CorelDraw-based production assets later.

Do not casually add more AI-generated runtime art to this phase.

## Active Terrain Classes

Only these terrain classes are active in the visible prototype foundation:

- `road`
  - runtime keys: `path`
- `field_grass`
  - runtime keys: `grass`
- `camp_ground`
  - runtime keys: `camp`
- `town_hardpack`
  - runtime keys: `packed_dirt`

Town currently resolves only:

- `path`
- `packed_dirt`
- `grass`

Camp currently resolves only:

- `camp`
- `path`
- `grass`

## Active Gameplay Node Classes

Town node classes:

- `jobs_or_work_access`
  - current node: `town_jobs_board`
- `store`
  - current nodes: `town_grocery`, `town_hardware`
  - kept separate because current page wiring still exposes separate grocery and
    hardware pages
- `remittance_office`
  - current node: `town_church`
- `camp_exit`
  - current node: `town_camp_road`

Camp node classes:

- `campfire`
- `woodpile`
- `bedroll`
- `stash`
- `tool_area`
- `wash_line`
- `trail_sign`

## Interaction Rule

Prototype interaction is intentionally simple:

- the player must stand on a walkable tile
- the tile must be directly cardinal-adjacent to the object footprint
- occupied object tiles do not count
- diagonal-only contact does not count

No heavier front-side metadata system is active yet. Layout should visually
encourage front-side interaction by placement.

## Frozen / Quarantined Material

Do not casually reintroduce:

- decorative town clutter
- decorative camp clutter
- dense edge brush and filler props
- terrain micro-variation for its own sake
- alternate ground variants that reduce readability

Quarantined runtime assets live under:

- `assets/game/_inactive/`

These remain preserved as source material, not active prototype content.

## Scripts Enforcing Prototype Behavior

Primary enforcement points:

- `scripts/front_end/camp_world_view.gd`
  - visible terrain resolution
  - active runtime texture loading
- `scripts/front_end/camp_isometric_play_layer.gd`
  - default town/camp object lists
  - placement and object footprint defaults
- `scripts/front_end/camp_interaction_system.gd`
  - interaction adjacency rule

Related but intentionally not driving this pass:

- `scripts/front_end/camp_ground_tilemap_layer.gd`
  - hidden legacy TileMap/atlas path

## Technical Debt To Leave Alone For Now

- `town_foreman` route wiring still exists upstream even though the default town
  no longer spawns a foreman object
- grocery and hardware remain separate store nodes because current page routing
  still depends on both
- the current prototype relies on placement rather than explicit front-side
  interaction metadata

## What Not To Reintroduce

Do not casually add back:

- street lamps
- trash barrels
- crate stacks
- board stacks
- wheelbarrows
- handcarts
- lantern clusters
- extra shelter props
- extra camp logs/stumps/crates
- terrain noise such as yard variants, forest variants, ash/cinder/gravel swaps,
  plank paths, mud/coal/stone dust accents, or similar readability drift

If a future change does not directly support movement, interaction readability,
collision honesty, town navigation, or the playable loop, it should not enter
this foundation layer.
