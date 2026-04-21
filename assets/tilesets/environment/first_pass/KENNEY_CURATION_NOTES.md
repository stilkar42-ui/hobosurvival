# Kenney First-Pass Camp Ground Curation

Date: 2026-04-19

This pass uses selected tiles from `assets/vendor/kenney/isometric_landscape/`
as a quick visual upgrade for the current camp ground atlas.

## Scope

- Replaced `atlases/env_ground_base_a01_placeholder.png` in place.
- Preserved the runtime atlas size: `1024x256`.
- Preserved the runtime tile cell size: `128x64`.
- Preserved the existing `CampGroundTilemapLayer` code and atlas coordinates.
- Added `atlases/env_ground_base_a01_placeholder_pre_kenney.png` as the prior
  placeholder backup.

No inventory, cooking, UI, or gameplay validation systems were changed.

## Source Pack

- Kenney Isometric Landscape
- Local source: `assets/vendor/kenney/isometric_landscape/`
- License: CC0, retained in the vendor folder.

## Mapping

The current camp layer uses these base atlas cells:

- `(0,0)` to `(2,0)`: compact dirt
- `(3,0)` to `(5,0)`: trampled dirt / camp wear
- `(6,0)`, `(7,0)`, `(0,1)`: sparse grass
- `(1,1)` to `(3,1)`: forest litter approximation
- `(4,1)`, `(5,1)`: camp footprint

The remaining filled cells are spare candidates for future shoreline and water
experiments but are not currently painted by the camp layer.

## Limitations

The Kenney source tiles are isometric block tiles, not flat ground diamonds.
This pass crops and mutes them to fit the existing atlas contract, but the art
still reads more like raised block terrain than final Hobo Survival ground.

Treat this as a working visual bridge, not production art.

## Next Pass

For a better camp look, build a true flat diamond ground atlas from either:

- edited Kenney top surfaces with side faces removed, or
- original ground tiles painted to the first-pass environment spec.
