# Draggable Camp Windows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current fixed dark camp interaction cards with draggable, themed local windows for stash, cooking, crafting, and getting ready while preserving the existing survival and inventory logic.

**Architecture:** Add one reusable draggable window shell in the camp front-end layer and feed it activity-specific themed content models from the existing loop page/controller code. Keep action execution in the shared player-state/survival-rule path so the new windows are presentation-only.

**Tech Stack:** Godot 4.x, GDScript, existing front-end scene tree, existing inventory and survival-loop services

---

### Task 1: Shared Window Shell

**Files:**
- Modify: `C:\Users\Avery\Documents\hobosurvival\scenes\front_end\camp_isometric_play_layer.tscn`
- Modify: `C:\Users\Avery\Documents\hobosurvival\scripts\front_end\camp_isometric_play_layer.gd`
- Test: `C:\Users\Avery\Documents\hobosurvival\tests\front_end\prototype_foundation_test.gd`

- [ ] Add a draggable title bar and shared themed window regions to the camp scene.
- [ ] Store per-window position in the camp layer so moved windows reopen where the player left them during the scene.
- [ ] Keep hover labels small and non-blocking when no window is open.

### Task 2: Activity-Themed Content

**Files:**
- Modify: `C:\Users\Avery\Documents\hobosurvival\scripts\front_end\camp_isometric_play_layer.gd`
- Modify: `C:\Users\Avery\Documents\hobosurvival\scripts\front_end\first_playable_loop_page.gd`
- Test: `C:\Users\Avery\Documents\hobosurvival\tests\front_end\prototype_foundation_test.gd`

- [ ] Expand the contextual overlay model to include theme metadata, icon/home slots, and section styling hooks for cooking, crafting, getting ready, and stash.
- [ ] Open the real local window directly on click for each supported camp object.
- [ ] Preserve the current action execution bridge so buttons still call the same authoritative action handlers.

### Task 3: Camp-Side Inventory Window

**Files:**
- Modify: `C:\Users\Avery\Documents\hobosurvival\scripts\front_end\first_playable_loop_page.gd`
- Test: `C:\Users\Avery\Documents\hobosurvival\tests\front_end\prototype_foundation_test.gd`

- [ ] Keep the existing inventory system but restyle and dock it as a draggable local belongings window in camp.
- [ ] Give stash/inventory a stronger item-centric layout that leaves obvious space for future item and interaction icons.
- [ ] Preserve right-click and selected-item behavior.

### Task 4: Verification

**Files:**
- Test: `C:\Users\Avery\Documents\hobosurvival\tests\front_end\prototype_foundation_test.gd`
- Test: `C:\Users\Avery\Documents\hobosurvival\tests\gameplay\survival_loop_rules_test.gd`

- [ ] Verify the new window shell compiles.
- [ ] Verify camp interaction windows open directly and remain local.
- [ ] Verify gameplay tests still pass unchanged.
