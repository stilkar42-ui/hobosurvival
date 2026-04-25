# UI Interaction Pattern Spec

This document records the current UI direction for interaction surfaces. Current code and `AGENTS.md` override older design notes when they conflict.

## Implemented Now

- The active runtime is page-driven through `UIManager` and `first_playable_loop_shell.gd`.
- Town, Camp, and Travel act as context layers for the survival loop.
- Several interaction surfaces already behave like windows or overlays, including Inventory, Passport, Getting Ready, and Town Service feature windows.
- The persistent Road Condition strip is shell-owned and remains available across major interaction routes.

## Guardrails

- Inventory, Cooking, Crafting, Getting Ready, Jobs, Stores, Doctor / Apothecary, Medicine Store, and Passport should be treated as interaction windows opened over the current context layer.
- Do not trap large interaction surfaces inside the panel or page that launched them.
- Prefer readable floating windows over nested scroll boxes when a task needs space for selection, detail, and action controls.
- Windows should be closable and bounded or recoverable so the player cannot lose them permanently off-screen.
- Widgets and windows remain passive UI. Gameplay validation, state mutation, purchases, item use, and care actions stay in managers, rules, and state services.

## Future Direction

- Player-arrangeable windows.
- Movable and resizable interaction surfaces where useful.
- Saved window positions.
- Reset-to-default layout.
- A broader unified overlay/window host, if explicitly scoped later.

These future systems are not implemented by this document. Do not describe them as active unless a later pass builds them.
