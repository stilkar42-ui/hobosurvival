# Store, Medicine, and General Store Baseline

This document records the current store, medicine, and Doctor / Apothecary implementation baseline for future Codex runs. It is descriptive: it separates what exists now from prepared inactive content and planned systems that do not exist yet.

Current code and `AGENTS.md` override older design docs and game bibles when they conflict.

## Implemented Now

- The active playable runtime is page-driven, not isometric.
- `UIManager` owns page routing.
- `LocationPage` handles town service routes and renders the player-facing town service UI.
- Current reachable town services are:
  - Jobs Board
  - Send Money
  - Grocery
  - Hardware
  - General Store
  - Doctor / Apothecary
  - Medicine Store
- Grocery, Hardware, General Store, and Medicine Store have generated weekly runtime stock.
- Generated runtime stock is stored on `PlayerStateData`:
  - `grocery_store_stock`
  - `hardware_store_stock`
  - `general_store_stock`
  - `medicine_store_stock`
- `PlayerStateData.SAVE_VERSION` is currently `12`.
- Existing save/load supports older saves without `medicine_store_stock`; missing medicine stock loads as a safe empty array.
- `SurvivalLoopRules` owns weekly stock generation, purchase validation, money mutation, and inventory mutation.
- `SurvivalLoopRules` generates Medicine Store stock from `StoreInventoryCatalog.STORE_MEDICINE`.
- `LocationPage` renders generated store stock as stock cards and dispatches buy actions through the existing store purchase flow.
- Doctor / Apothecary is a paid-care town service route, not a store stock route.
- Doctor / Apothecary care actions currently affect existing condition fields only:
  - hygiene
  - presentability
  - dampness
  - fatigue/stamina relief
  - morale
- Doctor / Apothecary does not implement wounds, sickness, diagnosis, addiction, or full medical simulation.
- Medicine Store is a runtime-visible store route that sells generated medical/apothecary stock through the existing store purchase pipeline.
- Doctor / Apothecary and Medicine Store are separate routes:
  - Doctor / Apothecary = paid care actions.
  - Medicine Store = buyable medical goods.

## Authority Split

- `data/items/inventory_catalog.tres` is the item-definition authority: what an item is.
- `scripts/data/store_inventory_catalog.gd` is the store-assortment authority: what each store type can sell.
- `scripts/gameplay/survival_loop_rules.gd` is the runtime rule authority for stock generation, purchases, and paid care actions.
- `scripts/player/player_state_data.gd` is the runtime state authority for generated stock arrays.
- `scripts/pages/location_page.gd` is the page renderer and town-service action dispatcher.

Do not move store assortment data back into `SurvivalLoopRules`. New store stock pools, store profiles, and store quality intent belong in `scripts/data/store_inventory_catalog.gd` unless a future task explicitly changes the catalog architecture.

Do not conflate paid care with store stock. Doctor / Apothecary service actions and Medicine Store purchases are separate runtime paths.

## Prepared But Inactive

- Medicine goods exist as inventory item definitions in `data/items/inventory_catalog.tres`.
- Some medical goods have bounded inventory `Use` effects through the existing inventory use path.
- Medicine goods do not cure wounds, cure sickness, diagnose conditions, or implement addiction/substance mechanics.
- Specialist store profiles exist in `scripts/data/store_inventory_catalog.gd` as future/profile-only entries.
- Specialist stores are not runtime-visible and do not generate stock.

## Planned But Not Implemented

These systems do not exist yet:

- `StoreManager`
- persistent merchant inventories
- restock schedules independent of player action
- town-specific merchants
- merchant relationships
- store reputation affecting price or access
- regional and seasonal supply/demand
- theft, shoplifting, barter, or credit
- specialist runtime stores
- full medical treatment system
- wound or injury system
- sickness or disease system
- diagnosis system
- addiction or substance dependence system
- broader medicine or doctor service economy

Do not describe these as active systems in future docs or implementation notes unless a later pass implements them.

## Likely Next Implementation Sequence

If future work continues this area, the likely order is:

1. Doctor / Apothecary and Medicine Store manual click-through polish.
2. Broader medical treatment item effects, if explicitly scoped.
3. Doctor / Apothecary service expansion, if explicitly scoped.
4. StoreManager design and implementation.
5. Persistent merchants, reputation, barter, theft, and regional supply rules.

This list is planning context only. It is not permission to implement those systems without an explicit task.

## Codex Guardrails

- Keep store content data-driven through `StoreInventoryCatalog`.
- Keep runtime generation and purchase mutation in `SurvivalLoopRules` until a future task explicitly changes authority.
- Keep generated stock on `PlayerStateData` unless a future persistence design replaces that shape.
- Keep `LocationPage` as renderer/dispatcher, not a simulation authority.
- Keep Doctor / Apothecary paid care separate from Medicine Store stock.
- Do not make medicine items cure or treat wounds/sickness unless a treatment pass is explicitly requested.
- Do not implement `StoreManager`, persistent merchants, theft/barter/credit, specialist runtime stores, injury/sickness/disease systems, diagnosis, or addiction systems unless explicitly scoped.
- Treat older game bibles as design reference, not current architecture truth.
