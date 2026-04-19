# Build Anchor v0.3 - Inventory Stable Anchor

Date locked: 2026-04-19

This document defines the v0.3 stable anchor for Hobo Survival. Future work must treat this build as a known-good baseline. The systems named here are not perfect, but they are functional enough to protect while the game continues to grow.

## Purpose

This anchor protects a stable inventory and camp-cooking interaction baseline.

Inventory is a tertiary system in Hobo Survival. It must serve travel, work readiness, camp survival, stake protection, and physical belongings management. It must not become a generic RPG loadout system or a feature playground.

## Stable And Locked Systems

The following systems are considered stable for v0.3:

- Main inventory popup opens over the current tile and keeps the world scene present.
- Main inventory uses the body-centered provider surface with visible hands, body slots, containers, ledger, and ground/nearby stash.
- Inventory movement uses drag and drop as the primary interaction.
- Visible providers are the movement targets: hands, worn/body providers, containers, and ground.
- Item movement is validated through the inventory layer, not by UI-side movement logic.
- Provider-backed containers can be opened as separate rummage popups outside the main inventory window.
- Container rummage popups remain draggable and close independently of the main inventory popup.
- Container rummage popups show only information unique to that container: mount/access/weight and the container's own contents/capacity.
- Container rummage popups do not duplicate the main inventory's visible provider/body-place controls.
- Camp cooking uses the existing recipe list and rule validation in `SurvivalLoopRules`.
- Camp coffee appears in the fire/cooking overlay when the real rule check says it is valid.
- Camp coffee validation accepts the current intended conditions: camp location, active fire, potable water or clean water item, coffee grounds, and an empty can or valid cooking heat tool.

## Allowed Changes

Future work may make small, surgical changes in these areas:

- UI polish that preserves the same interaction model.
- Window sizing, spacing, typography, and local visual clarity.
- Better labels or copy that keep the grounded tone.
- Additional regression tests around the locked behavior.
- Small bug fixes that preserve current player-facing flow.
- Internal cleanup only when it is directly required for a bug fix and covered by tests.

Any allowed change must keep the player on the current tile, preserve drag-to-visible-provider behavior, and keep validation in the simulation/inventory layer.

## Must Not Change

Future work must not change the following without explicitly creating a new build anchor:

- Do not replace drag and drop as the primary inventory interaction.
- Do not restore multi-step selection flows for basic item movement.
- Do not require inspect, focus, or hidden state before dragging an item.
- Do not make the main inventory a separate full-screen management page.
- Do not move container rummage back inside the main inventory window.
- Do not reintroduce duplicate "Visible Places" or body-provider lists inside container popups.
- Do not add UI-side inventory movement commits that bypass `Inventory.move()` or equivalent inventory-layer validation.
- Do not weaken provider capacity or constraint validation.
- Do not remove hands as simple visible providers with capacity 1.
- Do not change camp coffee requirements casually or hide valid coffee behind collapsed UI categories.
- Do not make cooking validation UI-driven.
- Do not introduce a broad recipe refactor unless the work is explicitly scoped and regression-tested.

## Known Acceptable Imperfections

These are known limitations that are acceptable in v0.3:

- Inventory window sizing and layout can still feel rough in some viewport compositions.
- The body silhouette is functional but not final art.
- Container popup placement is serviceable, not polished.
- Recipe definitions are not yet in a single master recipe file.
- Cooking and hobocraft recipes are centralized in code constants, but validation remains per-recipe rule code.
- Some older context-menu code still exists for secondary actions.
- The UI vocabulary still mixes "inventory", "belongings", "pack", and "stash" in places.

These imperfections are not permission to redesign the system. They are reminders for future focused cleanup.

## Regression Definition

A future change is a regression if any of the following becomes true:

- The player cannot move a visible item to a visible valid provider with drag and drop.
- A basic move requires a prior click, inspect step, focus state, radial menu, or hidden selection state.
- Item movement succeeds or fails because of UI-side logic instead of inventory-layer validation.
- Hands, ground, worn containers, or body slots stop acting as visible providers.
- The main inventory leaves the current tile or becomes a separate full-screen management mode.
- Opening a worn or held container replaces the main inventory instead of opening a separate rummage popup.
- Container popups show duplicate visible-place/body-provider controls.
- Container popups cannot be closed independently.
- Camp coffee is valid by rule checks but absent from the cooking overlay.
- Camp coffee validation no longer respects fire, water, coffee grounds, and tin/cookware requirements.
- Cooking recipes become UI-driven rather than rule-driven.
- Existing regression tests for inventory movement, container popups, or cooking visibility are removed or weakened without replacement.

## Required Regression Checks

Future changes touching inventory, containers, camp overlay UI, cooking, recipes, or player state must run the relevant checks:

- `res://tests/front_end/prototype_foundation_test.gd`
- `res://tests/inventory/inventory_mvp_test.gd`
- `res://tests/gameplay/survival_loop_rules_test.gd`

Passing these tests does not automatically approve broad refactors. It only proves the current regression net did not catch a failure.

## Anchor Rule

When in doubt, preserve the v0.3 player flow:

Open the local inventory over the current tile. See the belongings. Drag visible things to visible places. Open containers as small movable rummage windows. Cook from rule-validated camp conditions.
