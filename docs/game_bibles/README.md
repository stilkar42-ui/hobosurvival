# Hobo Survival Game Bible Index

This folder holds design and reference material for Hobo Survival. Use it selectively.

## Usage Rules

- Read this index first before opening individual bible files.
- Open only files that are relevant to the task at hand.
- Do not ingest, paste, or summarize the whole folder by default.
- These bibles are reference material, not automatic marching orders.
- They provide design intent, examples, lore, historical grounding, mechanics, and long-term direction.
- Current code architecture, active scenes, and tests override older design docs when they conflict.
- If a bible suggests a major architecture change, preserve the current architecture and report the conflict before changing code.

## Current Code Baselines

Before using bible guidance about stores, medicine, economy, merchants, treatment, or long-term service systems, read:

- `AGENTS.md`
- `docs/store_medicine_general_store_baseline.md`

The game bibles may describe future medicine stores, merchants, treatment, barter, theft, or broader economy systems. Those references are design material only. Current code and `AGENTS.md` define what is implemented, prepared but inactive, and not implemented yet.

## Current Implementation Guidance

These docs are the closest to implementation-facing guidance, but they still do not override active code:

- `CODEX -HOBO SURVIVAL — CODEX IMPLEMENTATION BRIEF v1.txt`
- `Mechanics Bible v1.txt`
- `Fading.txt`
- `Best Practices and Frameworks for Systems-Heavy 2D Isometric RPG and Narrative Survival Sims.docx`
- `Codex-First Guide to Building a 2D Isometric Survival Game.docx`

Use these for direction, terminology, and design fit. Before implementing from them, verify the current architecture in `AGENTS.md`, active scripts, and tests.

## File Inventory

| File | Appears To Be For | Classification | Currency / Caution |
| --- | --- | --- | --- |
| `Best Practices and Frameworks for Systems-Heavy 2D Isometric RPG and Narrative Survival Sims.docx` | Architecture and engineering best practices for dense systemic RPG/survival sims, including decoupled domains, event boundaries, Godot scene/data separation, and global-state cautions. | Architecture / implementation reference. | Useful for broad systems thinking. Not current repo truth. Do not replace the active manager/page/state architecture just because this doc recommends a general pattern. |
| `Campcraft — Survival & Shelter Trees v1.5.txt` | Campcraft, survival, and shelter progression tree ideas, including road-born fundamentals, fire, foraging, shelter, cache, and fading-related keystones. | Lore/mechanics/design reference. | Likely future-facing and progression-heavy. Ground any implementation in the current loop, `SurvivalLoopRules`, and existing recipe/camp systems first. |
| `CODEX -HOBO SURVIVAL — CODEX IMPLEMENTATION BRIEF v1.txt` | Implementation-facing brief for core loop, body economy, stake economy, jobs, camp, inventory, appearance, travel, law, progression, and MVP priorities. | Current-ish implementation guidance. | Strong reference for design fit and milestone priorities, but active code architecture still wins. It includes future systems and should not be followed as a bulk build list. |
| `Codex-First Guide to Building a 2D Isometric Survival Game.docx` | Codex workflow and technical guide for a 2D/isometric survival game, including map authoring, tile/isometric concerns, runtime architecture, and operational safeguards. | Architecture / art / isometric implementation reference. | Partly superseded by the current active page-loop runtime. Use when planning future isometric/map work, not for ordinary page/controller tasks. |
| `Fading.txt` | Fading Meter / identity erosion system specification, including purpose, triggers, recovery factors, threshold states, UI feedback, data tracking, and acceptance criteria. | Mechanics / derived-stat reference. | Highly relevant for fading or identity-pressure work. Compare against current `FadingMeterSystem` and player state before changing behavior. |
| `Historically grounded hobo work and survival systems for 1890–1935 gameplay.docx` | Historical grounding for hobo work, seasonal labor, hiring infrastructure, rail travel, policing, camps, money pressure, and survival systems. | World/lore/mechanics reference. | Good for labor, economy, travel, social pressure, and historical texture. Use as grounding, not literal canon. |
| `Hobo 1.2.txt` | Older broad game design document for "Hobo's Journey" covering procedural world, survival, travel, crafting, NPCs, home/family, and early technical ideas. | Older design archive. | Useful for origin context. Likely superseded in tone, scope, and implementation details by `AGENTS.md`, the implementation brief, and current code. |
| `Hobo Survival Game Lore Bible Source Guide 1890–1935.docx` | Developer-facing source guide for historically grounded hobo culture, labor mobility, camps, identity, policing, and research anchors. | World/lore/historical reference. | Strong source-grounding reference. Use to avoid romanticized or inaccurate lore. Current fictional world doctrine still controls canon choices. |
| `Hobo_Survival_Design_Compendium - Copy.txt` | Very large compiled brainstorm/design archive containing early conversations, feature ideas, mechanics, world evolution, NPC systems, train-hopping, sanitation, items, and future concepts. | Duplicated/older design archive. | Use sparingly for historical context or idea recovery. It appears copied and expansive; do not treat as current scope or current architecture. |
| `Hobo_Survival_Master_Design_v1.0.docx` | High-level master design document covering vision, pillars, world structure, daily loop, survival, crafting, work, travel, NPCs, family pressure, fading, character, and development plan. | Design/lore/mechanics reference. | Useful for vision alignment. Some implementation details and future features may predate the active architecture and current milestone. |
| `Mechanics Bible v1.txt` | Historically grounded mechanics framework for body economy, stake economy, information economy, social survival, seasonal pressure, jobs, camp, travel, inventory, appearance, law, and progression. | Mechanics / implementation guidance. | One of the best references for system fit. Still verify against active state/rule code before implementing. |
| `World Bible.txt` | Concise world doctrine for the fictional mirrored nation, structural authenticity, fictional geography, flexible canon, tone preservation, and research usage. | World/lore doctrine. | Current design doctrine reference. Use for worldbuilding and tone decisions alongside `AGENTS.md`. |

## Consult By Task Type

### Architecture / Implementation Direction

Start with:

- `AGENTS.md` in the repository root.
- `CODEX -HOBO SURVIVAL — CODEX IMPLEMENTATION BRIEF v1.txt`.
- `Mechanics Bible v1.txt`.

For broad systems or future visual-runtime planning only:

- `Best Practices and Frameworks for Systems-Heavy 2D Isometric RPG and Narrative Survival Sims.docx`.
- `Codex-First Guide to Building a 2D Isometric Survival Game.docx`.

### Mechanics / Survival Systems

Consult:

- `Mechanics Bible v1.txt`.
- `CODEX -HOBO SURVIVAL — CODEX IMPLEMENTATION BRIEF v1.txt`.
- `Historically grounded hobo work and survival systems for 1890–1935 gameplay.docx`.

### World / Lore / Historical Grounding

Consult:

- `World Bible.txt`.
- `Hobo Survival Game Lore Bible Source Guide 1890–1935.docx`.
- `Historically grounded hobo work and survival systems for 1890–1935 gameplay.docx`.

### Fading / Derived Stats

Consult:

- `Fading.txt`.

Then verify against current fading support in code before implementing.

### Campcraft / Recipes

Consult:

- `Campcraft — Survival & Shelter Trees v1.5.txt`.
- `Mechanics Bible v1.txt`.
- `CODEX -HOBO SURVIVAL — CODEX IMPLEMENTATION BRIEF v1.txt`.

Treat progression trees as design reference. Current recipe/catalog/rule code determines implementation shape.

### Art / UI / Isometric Direction

Consult:

- `Codex-First Guide to Building a 2D Isometric Survival Game.docx`.
- `Best Practices and Frameworks for Systems-Heavy 2D Isometric RPG and Narrative Survival Sims.docx`.
- `Hobo_Survival_Master_Design_v1.0.docx` for broad visual direction only.

These are reference docs. The current active runtime is page/controller-driven, and ordinary UI work should follow active page and widget architecture.

## Older / Duplicated / Possibly Superseded Docs

- `Hobo_Survival_Design_Compendium - Copy.txt` appears to be a large copied brainstorm archive with duplicated and expansive early material.
- `Hobo 1.2.txt` appears older than the current doctrine and uses earlier framing such as "Hobo's Journey."
- `Hobo_Survival_Master_Design_v1.0.docx` has broad design and future features that may predate current implementation.
- The isometric-first docs are useful for future visual/runtime work, but they should not override the current active shell/page architecture.

When in doubt, treat these as historical context and ask whether the task is requesting old design recovery or current implementation work.
