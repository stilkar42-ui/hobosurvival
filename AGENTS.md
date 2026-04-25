# AGENTS.md

## Project Identity

Hobo Survival is a top-down 2D sandbox survival RPG built in Godot and GDScript.

The player is a working man forced onto the road by economic failure at home. He travels to find labor, survive, preserve his stake, and send money back to support his family.

This is not a vagrant simulator, a misery sandbox, or a generic survival RPG.

This is a labor, survival, movement, duty, family pressure, and dignity-under-attrition simulation.

Core truth:
- The player leaves because staying would fail the people depending on him.
- Work is the moral and structural center of the game.
- Survival supports purpose; it is not the purpose.
- Money is not progression. Money is time converted into family stability.

## Current Code Architecture Truth

These notes describe the current active repository architecture. They override older planning docs when there is a conflict.

### Active Runtime

- Main scene: `scenes/front_end/title_front_end.tscn`.
- Active playable scene: `scenes/front_end/first_playable_loop_page.tscn`.
- Active playable controller: `scripts/front_end/first_playable_loop_shell.gd`.
- `scripts/front_end/first_playable_loop_page.gd` is legacy/inactive. Do not treat it as active architecture unless the task explicitly asks for that legacy path.

### Game Bible / Reference Docs

- Design and reference bibles live in `docs/game_bibles/`.
- Start with `docs/game_bibles/README.md` before opening individual bible files.
- Open only the specific bible files relevant to the task.
- Do not paste, ingest, or summarize all bibles by default unless the task explicitly requires full design synthesis.
- Bibles provide design intent, examples, lore, mechanics, and long-term direction.
- Current code architecture and tests override older design docs when they conflict.
- If a bible suggests a major architecture change, preserve the current architecture and report the conflict before changing code.

### Managers

- Managers live under `scripts/managers`.
- Managers are manually instantiated `RefCounted` classes in the active shell, not autoload singletons, unless the code is explicitly changed later.
- `project.godot` currently has no `[autoload]` manager architecture.
- Treat managers as facades, helpers, and routers unless a task explicitly changes authority boundaries.

### State And Rule Authority

- `PlayerStateService` and `PlayerStateData` are the authoritative runtime state layer.
- `SurvivalLoopRules` is the authoritative gameplay validation and mutation layer.
- Pages and widgets must not become simulation authorities.

### Store And Medicine Baseline

- `UIManager` routes active pages, and `LocationPage` handles town service routes.
- Current reachable town services are Jobs Board, Send Money, Grocery, Hardware, General Store, Doctor / Apothecary, and Medicine Store.
- Store authority is split deliberately:
  - `data/items/inventory_catalog.tres` defines what items are.
  - `scripts/data/store_inventory_catalog.gd` defines what store types can sell.
  - `scripts/gameplay/survival_loop_rules.gd` owns weekly stock generation, purchase validation, money mutation, and inventory mutation.
  - `scripts/player/player_state_data.gd` stores generated runtime stock state.
  - `scripts/pages/location_page.gd` renders town services and dispatches player-facing store actions.
- Runtime generated store stock currently lives on `PlayerStateData.grocery_store_stock`, `PlayerStateData.hardware_store_stock`, `PlayerStateData.general_store_stock`, and `PlayerStateData.medicine_store_stock`.
- `PlayerStateData.SAVE_VERSION` is currently `12`; older saves without `medicine_store_stock` load safely with empty medicine stock.
- Grocery, Hardware, General Store, and Medicine Store have runtime weekly stock.
- Doctor / Apothecary and Medicine Store are separate routes with separate meanings:
  - Doctor / Apothecary is paid care through action cards. It affects existing condition fields only: hygiene, presentability, dampness, fatigue/stamina relief, and morale.
  - Medicine Store is buyable medical/apothecary stock through the existing store purchase pipeline.
- Doctor / Apothecary does not implement wounds, sickness, diagnosis, addiction, or full medical simulation.
- Do not put new store assortment data back into `SurvivalLoopRules`; add it to the store inventory catalog path.
- Do not conflate service care with store stock.
- Do not add `StoreManager`, injury/sickness/disease, addiction, theft/barter/credit, persistent merchant inventories, or specialist runtime stores unless the task explicitly scopes that system.

### Pages, Widgets, And Routes

- Active page controllers live under `scripts/pages`.
- Pages follow `bootstrap(deps)`, `set_context(context)`, `set_route(route_id)`, `set_visible(visible)`, `refresh_from_state(player_state)`, and optional `handle_input(event)`, where applicable.
- `UIManager` owns page routing through `open_page(id, context)`.
- New page routes should be registered in `scripts/front_end/first_playable_loop_shell.gd` and routed through `UIManager`.
- Reusable widgets live under `scripts/ui/widgets`.
- Widgets should remain mostly passive: setters in, signals out.
- Widgets should not call `PlayerStateService`, `GameStateManager`, or `SurvivalLoopRules` directly.
- `InventoryPanel` is a heavier UI component, but authoritative actions still flow through `InventoryPage`, managers, and rules.
- Prefer `LocationManager` constants for route IDs.
- Do not add new hardcoded route strings when a `LocationManager` constant belongs there.
- Avoid duplicating route authority across pages.

### Legacy And Inactive Paths

- Do not copy patterns from `scripts/front_end/first_playable_loop_page.gd`.
- Do not assume `camp_isometric_play_layer.tscn` is active.
- Do not treat `tmp/prototype_reset_backups` as active source.
- Debug scenes are tools, not production page architecture.

### Feature Placement

- Gameplay rules: `SurvivalLoopRules` / `SurvivalLoopConfig`.
- Runtime state: `PlayerStateData` / `PlayerStateService`.
- Page UI: `scripts/pages`.
- Reusable UI: `scripts/ui/widgets` or `scripts/ui`.
- Data catalogs/resources: `scripts/data` or `data` resources.
- Design/lore/mechanics references: `docs/game_bibles`.

## Core Fantasy

The player is not surviving for himself alone.

He is:
- enduring
- earning
- returning

Every system must reinforce:
- duty
- pressure
- movement
- work
- family obligation
- survival tied to purpose

The player fantasy is surviving the labor road, mastering hobocraft, reading the labor market, protecting a stake, and learning to live efficiently inside a hostile system.

## Tone

The tone must remain:
- grounded
- human
- reflective
- worn-down, not stylized
- harsh without parody
- poetic without abstraction

The world should feel like:
- cold mornings
- old rails
- brief kindness
- hard work
- quiet exhaustion
- small victories that matter

Do not introduce:
- comedy drift
- meme survival
- whimsical tone breaks
- poverty caricature
- loot-goblin language
- generic RPG power fantasy
- systems that make hardship cute, abstract, or convenient

## World Doctrine

The setting is a fictional mirrored nation inspired by the structural realities of America circa 1890-1935.

Use structural authenticity over literal accuracy:
- Fictional towns, regions, rail lines, employers, and institutions are valid.
- Historical research should inform labor, economics, social pressure, material culture, and risk.
- Do not turn the world into cartoon alt-history, steampunk fantasy, or exact historical reenactment.
- The world must feel materially real even when fictionalized.

## Core Loop

The primary loop is:

1. Travel or arrive.
2. Gather information.
3. Secure work or income opportunity.
4. Perform labor and risk the body.
5. Manage survival, camp, spending, and gear.
6. Preserve stake.
7. Choose the next move.

Systems should feed this loop. If a feature does not affect movement, labor, family pressure, survival constraints, social standing, information, or stake preservation, it probably does not belong yet.

## System Hierarchy

Treat systems according to this hierarchy.

Primary systems define the game. Secondary systems complicate them. Tertiary systems serve them.

### Primary Systems

Primary systems define the game and should drive most design decisions.

- Work & Economy
- Travel
- Family Pressure

Work decides opportunity and success. Travel creates distance, time cost, exposure, and uncertainty. Family pressure gives the player a reason to endure.

### Secondary Systems

Secondary systems constrain and complicate the primary systems.

- Survival
- NPC System
- Social Survival
- Information Economy
- Seasonal and regional pressure

Survival stats are constraints on action, not goals by themselves. NPCs, reputation, gossip, and local knowledge should change what work is reachable, what travel is safe, and what help or danger appears.

### Tertiary and Expression Systems

Tertiary systems express, support, or operationalize the primary and secondary systems.

- Inventory
- Crafting
- Items
- Camp affordances
- UI panels
- Recipes
- Gear quality

Tertiary systems must serve primary systems. They must not compete with work, travel, or family pressure as the center of the game.

If a tertiary system conflicts with a primary system, the primary system must always take priority.

If a tertiary system starts to feel like a standalone RPG subsystem, redesign it.

## Design Pillars

1. Survival serves purpose, not itself.
2. Work is the primary driver of progress.
3. Movement defines the experience.
4. Family pressure is the core motivation engine.
5. Social navigation is as important as resources.
6. The player begins as a person with a life, not a blank avatar.
7. The world pushes back through systems, not arbitrary scripted cruelty.
8. Hope exists, but must be earned.

## Anti-Pillars

Do not introduce:
- fantasy inventory logic
- infinite storage
- convenience systems that erase pressure
- generic RPG abstractions that ignore physical reality
- systems disconnected from work, travel, family, survival, or social pressure
- placeholder mechanics that violate tone
- broad speculative scaffolding for future systems

If a system could exist unchanged in any generic survival game, it is likely wrong for Hobo Survival.

## Inventory Law

Inventory is not abstract RPG storage.

Inventory represents what a man can physically:
- carry
- hide
- use
- trade
- organize
- repair
- lose
- risk being seen with

Inventory must express weight, space, access, concealment, order, usefulness, and loss. It should support work, travel, camp preparation, survival, trading, theft risk, and family pressure.

Do not frame inventory as a generic body-slot or RPG loadout screen unless a specific design explicitly requires it.

Allowed inventory framing:
- belongings
- pack
- pockets
- hands
- stash
- cache
- bundle
- tools
- materials
- carried stake

Avoid:
- fantasy bags
- infinite containers
- equipment-slot-first UI
- loot rarity obsession
- convenience sorting that erases pressure
- item systems that exist only for collection or power scaling

## Hardship and Relief

Hardship is real, but relief is essential.

Relief must be:
- earned
- temporary
- meaningful

Valid relief includes:
- a safe camp after a hard journey
- sending money home
- a hot meal
- dry warmth
- clean clothes
- companionship
- a successful job run
- a repaired tool that makes tomorrow possible

The game operates on:

**pressure -> effort -> relief -> renewed pressure**

Do not remove pressure permanently unless that permanent change creates a new responsibility, cost, or vulnerability.

## Failure Philosophy

Failure is not always death.

Systems should support:
- degradation
- loss
- debt
- exhaustion
- missed obligations
- damaged reputation
- lost tools
- ruined clothing
- unsafe travel
- isolation
- fading identity

"Becoming no one" is a legitimate failure pressure for this project.

Identity erosion, neglect, alcohol, isolation, shame, and broken ties may be as dangerous as hunger or cold. Memory, dreams, work, relationships, and sending money home should resist that erosion.

## Core Systems

### Work & Economy

Work is the primary filter of success.

Work systems may include:
- seasonal labor
- casual urban labor
- skilled casual labor
- heavy camp or industrial labor
- legal and illegal work
- job leads and job boards
- employer reputation
- wage variance
- agency fees, scams, and deductions
- town economic states

Economic success is not just earning money. It is keeping enough stake to move, eat, work, and send support home.

### Travel

Travel is gameplay.

Travel systems may include:
- walking
- hitchhiking
- rail travel
- route information
- weather exposure
- time cost
- law and railroad risk
- fatigue and carry burden
- safe and unsafe camps

Distance should affect time, risk, body condition, money, work opportunity, and family pressure.

### Family Pressure

Family pressure is the core motivation engine.

It may include:
- bills
- health needs
- letters
- deadlines
- delayed support delivery
- home condition
- morale effects
- consequences for neglect

Sending money home should create relief, but also renew pressure. The player is never simply accumulating wealth.

### Survival

Survival stats are constraints on action.

Core survival pressures include:
- hunger or nutrition
- warmth
- fatigue
- hygiene
- morale
- injury and sickness when implemented

Survival should shape decisions about work, travel, appearance, camp, and spending. It must not become a detached meter-management minigame.

Survival systems must never become the dominant objective over work, travel, or family pressure.

### NPC and Social Survival

NPC systems should make the road socially legible and dangerous.

Use grounded archetypes and roles carefully:
- workers
- drifters
- dependents
- employers
- railroad men
- town officials
- camp regulars
- helpers, rivals, and predators

NPCs should support:
- trust
- betrayal
- reputation
- gossip
- work access
- camp access
- warnings
- scams
- social memory

Social systems must affect practical survival, work, travel, and identity.

### Information Economy

Knowledge is a resource.

Information may include:
- job leads
- wage expectations
- seasonal forecasts
- safe camp locations
- police or railroad activity
- route timing
- scam warnings
- local hostility
- NPC reliability

Information should have confidence, source, age, and risk when appropriate.

Information should never be perfect, complete, or free by default. It should have uncertainty, cost, risk, or degradation over time.

### Crafting and Hobocraft

Crafting is hobo ingenuity under constraint.

Crafting should:
- use grounded materials
- respect item quality
- compete with buying, finding, and trading
- produce practical survival, work, camp, or travel benefits
- remain modular and realistic

Example: a stove is not just an item. It is heat, food access, water access, morale, and a survival multiplier.

## Milestone and Scope Control

Build only what is required for the current milestone.

Do not:
- anticipate future systems unless explicitly instructed
- partially implement broad future architecture
- add abstractions without immediate pressure
- create placeholder systems that violate tone
- expand content breadth before the current loop works
- expand a system beyond what is required to validate its role in the core loop

Prefer:
- minimal, correct, expandable systems
- small interfaces
- clear state
- focused tests
- production-shaped foundations without speculative bulk

If future expansion is obvious, expose clean data and seams. Do not build the future feature.

## System Construction Rules

Systems must be:
- modular
- testable
- grounded
- readable
- deterministic where practical
- simple before clever

Implementation rules:
- Prefer data-driven values for items, jobs, recipes, stats, prices, durations, and world modifiers.
- Keep long-lived game logic outside fragile UI code when possible.
- UI should display state and issue commands; simulation systems should validate and apply effects.
- Avoid hardcoded assumptions that would force full replacement later.
- Expose state cleanly for save/load and future expansion.
- Preserve existing architecture unless there is a clear reason to change it.
- Keep code scoped to the requested behavior.

## Before Coding Hard Gate

Before building any non-trivial feature, Codex must explain:

1. How the feature supports the core fantasy.
2. How it fits the core loop.
3. Which primary or secondary systems it connects to.
4. Whether it affects work, travel, family pressure, survival, social pressure, information, or stake preservation.
5. The minimal implementation that satisfies the current milestone.

If this explanation is missing, weak, or generic, do not implement the feature.

Reject or redesign any feature that:
- does not connect to the system hierarchy
- exists only because generic RPGs have it
- makes hardship convenient without cost
- ignores the player's family obligation
- turns the game into loot progression or meter maintenance

## Definition of Done

A feature is complete only if:
- it works technically
- it fits the tone and world
- it reinforces at least one primary or secondary system
- tertiary systems serve the primary loop
- it connects cleanly to existing state
- it has focused verification appropriate to its risk
- it does not require full replacement later
- it avoids generic survival/RPG drift

## Development Philosophy

Build minimal, correct systems first.

Expand through iteration.

Prefer grounded mechanics over abstraction.

Prefer clear pressure over feature count.

Prefer a small working loop over broad unfinished scaffolding.

## Final Rule

If a system:
- feels generic
- breaks immersion
- ignores physical reality
- ignores work, travel, or family pressure
- treats survival as the whole purpose
- forgets the player is a working man trying to support home

It must be rejected and redesigned.
