# Game Asset Assignments

This folder holds art that the game currently references at runtime.

## Tilesmith-Only Runtime Policy

Camp, town, foliage, title, and hobo/player runtime art now come from Avery's
current Codex intake set. The raw intake folder stays in the project root:

- `Codex use this/`

The import pipeline copies those labeled PNGs into the active internal source
folder:

- `assets/game/source/codex_use_this_current/`

The runtime map layer should not use older vendor, generated, or placeholder
camp/town/character assets unless Avery explicitly approves a new source.

## Runtime Layout

- `camp/tiles/`
  - Camp ground tiles, camp props, and camp foliage extracted from the new
    Tilesmith camp sheets.
- `town/tiles/`
  - Town ground tiles extracted from the new Tilesmith town ground sheet.
- `town/objects/`
  - Town buildings, signs, lamps, crates, and dressing extracted from the new
    Tilesmith town object sheet.
- `characters/`
  - Hobo/player walk frames extracted from the new Tilesmith hobo sheets.
- `title/`
  - Title page and wood-button states extracted from the Codex title sheets.
- `items/`
  - Reserved for inventory item icons once item sprites are assigned.
- `source/`
  - Source sheets used by the repeatable import pipeline.

## Import Pipeline

Run `tools/import_hobo_tilesmith_assets.ps1` to rebuild the runtime art from
`Codex use this/`. The importer copies source sheets into `source/`, clears the
current runtime camp/town/character/title art folders, removes baked checker or
presentation backgrounds, and exports engine-ready PNGs.

Ground tile contract:

- Runtime ground tiles are `32x32`.
- The visible isometric footprint is a centered `32x16` diamond.
- Pixels outside the diamond must remain transparent.

Prop and character contract:

- Runtime sprites must be transparent cutouts.
- Props and buildings should be bottom-center anchored in the renderer.
- Hobo frames use a shared `96x128` canvas for stable walking animation.
- Title buttons use extracted normal, hover, and pressed texture states.
