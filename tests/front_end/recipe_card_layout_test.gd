extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.name = "RecipeCardLayoutRoot"
	root.size = Vector2i(1280, 720)
	get_root().add_child(root)

	var loop_page = FirstPlayableLoopPageScene.instantiate()
	root.add_child(loop_page)
	call_deferred("_run_checks", loop_page)


func _run_checks(loop_page: Control) -> void:
	await process_frame
	await process_frame

	var player_state_service = PlayerStateRuntimeScript.get_or_create_service(loop_page)
	var player_state = player_state_service.get_player_state() if player_state_service != null else null
	var item_catalog = player_state_service.get_item_catalog() if player_state_service != null else null
	var loop_config = player_state_service.get_loop_config() if player_state_service != null else null
	var crafting_page = loop_page.get("_crafting_page")
	var ui_manager = loop_page.get("_ui_manager")
	_expect(player_state_service != null, "loop page resolves player state service")
	_expect(player_state != null, "loop page exposes player state")
	_expect(item_catalog != null, "loop page exposes item catalog")
	_expect(loop_config != null, "loop page exposes loop config")
	_expect(crafting_page != null, "loop page exposes the crafting page controller")
	_expect(ui_manager != null, "loop page exposes UIManager")

	if player_state == null or item_catalog == null or loop_config == null or crafting_page == null or ui_manager == null:
		quit(1)
		return

	player_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	player_state.set_camp_fire_level(1)
	player_state.inventory.add_item(item_catalog.get_item(&"beans_can"), 1, &"pack")
	player_state.inventory.add_item(item_catalog.get_item(&"empty_can"), 1, &"pack")
	player_state.inventory.add_item(item_catalog.get_item(&"dry_kindling"), 1, &"pack")
	player_state.inventory.add_item(item_catalog.get_item(&"baling_wire"), 1, &"pack")

	var cooking_material_snapshot = SurvivalLoopRulesScript.get_cooking_recipe_material_snapshot(player_state, loop_config, {
		"recipe_id": &"heat_beans"
	}, item_catalog)
	_expect(cooking_material_snapshot.size() == 1, "cooking snapshot returns the expected counted ingredient rows")

	var hobocraft_material_snapshot = SurvivalLoopRulesScript.get_hobocraft_recipe_material_snapshot(player_state, {
		"recipe_id": &"wire_braced_tin_can_heater",
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		]
	}, item_catalog)
	_expect(hobocraft_material_snapshot.size() == 3, "hobocraft snapshot returns one row per explicit input")

	var cooking_lines: PackedStringArray = crafting_page.build_recipe_inventory_note_lines({
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans"
	}, player_state, true)
	var cooking_note = "\n".join(cooking_lines)
	_expect(cooking_note.contains("Can of Beans:") and cooking_note.contains("/ 1"), "cooking note counts owned ingredients")

	var hobocraft_lines: PackedStringArray = crafting_page.build_recipe_inventory_note_lines({
		"recipe_id": &"wire_braced_tin_can_heater",
		"display_name": "Wire-Braced Tin Can on a Stick",
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		],
		"output_item_id": &"wire_braced_tin_can_heater"
	}, player_state, false)
	var hobocraft_note = "\n".join(hobocraft_lines)
	_expect(hobocraft_note.contains("Empty Tin Can:") and hobocraft_note.contains("/ 1"), "hobocraft note counts owned materials")

	ui_manager.open_page(&"crafting_page", {"return_route": &"camp", "route_id": &"cooking"})
	await process_frame
	var cooking_layout = loop_page.find_child("CookingLayout", true, false)
	var hobocraft_layout = loop_page.find_child("HobocraftLayout", true, false)
	_expect(cooking_layout != null and cooking_layout.get_child(0) is PanelContainer, "cooking layout uses a fixed list panel instead of an inner scroll")
	_expect(cooking_layout != null and cooking_layout.get_child(1) is PanelContainer, "cooking layout uses a fixed detail panel instead of an inner scroll")
	_expect(hobocraft_layout != null and hobocraft_layout.get_child(0) is PanelContainer, "hobocraft layout uses a fixed list panel instead of an inner scroll")
	_expect(hobocraft_layout != null and hobocraft_layout.get_child(1) is PanelContainer, "hobocraft layout uses a fixed detail panel instead of an inner scroll")

	var cooking_availability = player_state_service.get_loop_action_availability_with_context(
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		{"source": "recipe.card.test", "recipe_id": &"heat_beans"}
	)
	var cooking_workspace: Control = crafting_page.build_recipe_workspace({
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans",
		"summary": "Warm a can of beans over the fire and eat it hot instead of cold from the tin.",
		"inputs_text": "can of beans + fire + small cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; leaves an empty tin",
		"category": "Hot Food"
	}, player_state, cooking_availability, true, Callable(loop_page, "queue_redraw"))
	_expect(cooking_workspace.get_child_count() == 2, "recipe workspace renders note and index card columns")
	_expect(cooking_workspace.get_child(0).name == "RecipeInventoryNote", "workspace left column is the inventory note")
	_expect(cooking_workspace.get_child(1).name == "RecipeIndexCard", "workspace right column is the recipe card")

	var overlay_workspace_data: Dictionary = crafting_page.build_overlay_recipe_workspace_data({
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans",
		"summary": "Warm a can of beans over the fire and eat it hot instead of cold from the tin."
	}, player_state, SurvivalLoopRulesScript.ACTION_COOK_RECIPE, "recipe.card.test.overlay", "Cook %s", true)
	var overlay_card_sections: Array = overlay_workspace_data.get("card", {}).get("sections", [])
	var held_section: Dictionary = overlay_card_sections[0] if not overlay_card_sections.is_empty() else {}
	_expect(String(held_section.get("title", "")) == "Held", "overlay card puts held ingredient counts on the recipe card")
	_expect(String(held_section.get("body", "")).contains("held (needs 1)"), "overlay card shows counted held materials on the recipe card")

	if _failed:
		quit(1)
		return
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
