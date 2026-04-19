# Codex Working Rules

These rules apply to future Codex sessions working in this project.

## First Read

Before making changes, read:

1. `AGENTS.md`
2. `docs/BUILD_ANCHOR_v0.3.md`

If the requested work touches inventory, containers, cooking, recipes, camp overlays, or player-state validation, treat `BUILD_ANCHOR_v0.3.md` as a regression contract.

## Preserve Locked Systems

Future Codex sessions must preserve:

- Drag and drop as the primary inventory interaction.
- Visible providers as valid drop targets.
- Inventory-layer validation for item moves.
- Main inventory as an over-tile popup, not a separate management screen.
- Container rummage popups outside the main inventory window.
- Simplified container popups without duplicate visible-place/body-provider lists.
- Camp coffee visibility when rule validation says it is available.
- Cooking validation in gameplay rules rather than UI code.

## Change Discipline

Prefer small, surgical changes.

Do not refactor architecture unless the user explicitly asks for that refactor and the work includes regression protection. Do not introduce new systems while fixing a local bug. Do not make convenience changes that erase travel, work, camp, or survival pressure.

If a requested change risks a locked behavior, flag the risk before coding. If the request would clearly regress the anchor, refuse the risky part and propose a safer alternative.

## Validation Rules

Always use available tools and plugins for validation and planning:

- Use code search and file reads before making claims.
- Use Superpowers workflows when relevant.
- Use GitHub tooling for repository and publishing work when available.
- Use CodeRabbit or another available review tool before treating anchor-sensitive changes as ready.
- Run focused Godot tests after any touched behavior.

For changes touching inventory, containers, cooking, recipes, camp overlays, or player state, run:

- `res://tests/front_end/prototype_foundation_test.gd`
- `res://tests/inventory/inventory_mvp_test.gd`
- `res://tests/gameplay/survival_loop_rules_test.gd`

If a required tool is unavailable, state that directly in the final response and do not claim that step was completed.

## Regression Response

If a future change breaks the v0.3 anchor:

1. Stop broad feature work.
2. Restore the locked player flow.
3. Add or repair a regression test that catches the break.
4. Re-run the relevant validation commands.
5. Document any remaining gap.

## Working Principle

Hobo Survival is not a generic survival RPG. Inventory, cooking, and camp tools exist to support work, travel, family pressure, and survival under material constraint. Preserve the grounded pressure first; polish second.
