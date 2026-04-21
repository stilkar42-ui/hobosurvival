# Codex Hobo Asset Intake

Imported from `C:\Users\Avery\Downloads\Codex use this Hobo`.

## Included

- `isometric_tileset/separated_images/`
  - 32x32 tile images used for the rebuilt camp map pass.
- `critters/critters/`
  - Animal sprite assets kept as source art for later wildlife work.
- `residential-as_tent/`, `sailor-tents/`, `water-sailors/`
  - Camp prop assets. The camp view currently uses clear matches for fire
    and shelter visuals.
- `icons/`
  - 46x46 UI icons copied for later interface work; not wired into the camp
    map yet.
- `premade-npc-spritesheets/`
  - Character sprite sheets retained as alternate NPC source art.
- `PostApoc_Workshop/`
  - Workshop atlas used for the camp tool area visual.
- `city_essentials/`
  - Small loose prop sprites used for the ground stash, crate, trail sign,
    street signs, lamps, and town storefront dressing.
- `villager_npc_spritesheet/`
  - Current player character source art. The world view draws
    `npc01_spritesheet.png` as the standing player frame.
- `48_Free_Minerals_Pixel_Art_Icons_Pack/`,
  `free-pirate-stuff-pixel-art-icons/`,
  `free-rpg-loot-icons-pixel-art/`,
  `free-undead-loot-pixel-art-icons/`
  - Item icon source art copied for later inventory item-sprite assignment.
- `isometric_jumpstart/license.txt`
  - License retained for the jumpstart pack. Its art is not wired into the
    camp map in this pass.
- `kenney_isometric-city/`, `kenney_isometric-landscape/`
  - Kenney public-domain modular isometric source packs. Kept as raw backup
    city and landscape construction parts.
- `Isoverse_medieval_outdoors_free/`
  - Medieval/outdoor source sheet kept for visual experiments. It is not the
    current tone match for town.

## Current Use

The camp map now uses the 32x32 tile images from:

`assets/vendor/codex_hobo/isometric_tileset/separated_images/`

This replaces the prior 128x64 TileMap visual path for the camp ground.

Mouse-wheel zoom is handled in the world view so 32x32 camp and town maps can
be read closer without changing HUD scale. The first town pass reuses the
same movement layer as camp and replaces menu-only town links with in-world
objects: jobs board, foreman's office, church office, grocery, hardware, and
the road back to camp.

Runtime code should point at `assets/game/` once a source asset has been
chosen for the playable build. This keeps the exact assigned art stable and
GitHub-trackable while `assets/vendor/` remains the larger source-library
intake area.
