# Skills and Recipes v1

## Purpose

Reference structure for future skill, crafting, and cooking passes. This file defines practical rules for skills, recipe types, requirements, tools, and outputs.

## 1. Core Principles

- Systems must stay grounded and materially plausible.
- Recipes should follow real-world logic, not abstract crafting.
- Inputs, tools, location, fire, water, and player condition can matter.
- Outputs should be able to reflect input quality later.
- Crafting and cooking should support survival, work, and travel pressure.
- Avoid generic RPG recipes that ignore material reality.

## 2. Skill Categories

Skills are not fully implemented yet. Treat these as future-facing categories, not leveling rules.

| Skill | Scope |
| --- | --- |
| Campcraft | Fire, shelter, bedroll setup, field improvisation, basic camp routines |
| Cooking | Food prep, heating canned food, boiling water, coffee, simple stews |
| Tinkering | Repair, assembly, utility items, tool use, small practical rigs |

Initial behavior:

- Skills may later affect speed, success chance, output quality, waste, or durability.
- Current recipes should be structured so skill checks can be added without rewrites.
- Do not assume every recipe needs a skill gate.

## 3. Recipe Types

### Fixed Recipes

Fixed recipes require exact inputs and conditions.

Examples:

- Brew Coffee: coffee grounds + clean water + heat-safe vessel + fire/heat source.
- Tin Can Heater: empty can + dry kindling, optionally wire/bracing materials.

Use fixed recipes when the real object or action depends on specific materials.

### Flexible Recipes

Flexible recipes accept input categories instead of exact item ids.

Example:

- Mulligan Stew: base liquid + bulk food + optional protein/fat + optional filler.

Initial input categories:

| Category | Examples |
| --- | --- |
| base liquid | clean water, boiled water, broth |
| bulk food | beans, oats, potatoes, stale bread |
| protein/fat | potted meat, lard, scraps of meat |
| filler | dried beans, vegetables, hard bread, grain |

Use flexible recipes when the result is plausible from many poor-but-usable inputs.

## 4. Recipe Requirements

Recipes can require:

- Items: beans, coffee grounds, dry kindling, empty can.
- Tools: tin can heater, pot, knife, church key, coffee can.
- Conditions: active fire, boiled water, clean water, camp access, time of day.
- Location: camp, town kitchen, rail yard, shelter, or other future workspaces.

Rules:

- Requirements should live in recipe data or rules helpers, not UI-only checks.
- Missing requirements should produce clear blocked reasons.
- Tools and conditions should be checked separately from consumed inputs.

## 5. Tool Interaction

- Tools enable actions such as heating, boiling, cutting, opening, cooking, or carrying.
- Tools are not always consumed.
- Tools can later improve speed, safety, durability, or output quality.
- Poor tools may work but cost more time or produce weaker outcomes.

Example: Tin Can on a Stick

- Enables safer heating over a fire.
- Should not be consumed by heating one meal.
- May later reduce burn risk, improve warmth gain, or degrade with repeated use.

## 6. Output Rules

- Heated food should provide warmth and a small morale bonus.
- Coffee should support warmth/morale and may later affect fatigue.
- Better inputs should be able to produce better outcomes later.
- Poor inputs should be able to reduce morale, nutrition, safety, or reliability later.
- No full quality system is required yet, but recipe output data should allow it.

## 7. Known vs Available Recipes

Known recipes:

- Recipes the player understands or has learned.
- May later come from background, books, NPCs, practice, or hobo lore.

Available recipes:

- Known recipes that current items, tools, conditions, and location allow.
- A recipe can be known but unavailable if the player lacks fire, water, tools, or inputs.

UI rule:

- Show known recipes with clear availability state.
- Block unavailable recipes with practical reasons, not vague failure text.
