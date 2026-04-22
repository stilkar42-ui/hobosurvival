extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")
const CampIsometricPlayLayerScene := preload("res://scenes/front_end/camp_isometric_play_layer.tscn")
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
	call_deferred("_run_checks", root, loop_page)


func _run_checks(root: Window, loop_page: Control) -> void:
	await process_frame
	await process_frame

	var player_state_service = PlayerStateRuntimeScript.get_or_create_service(loop_page)
	var player_state = player_state_service.get_player_state() if player_state_service != null else null
	var item_catalog = player_state_service.get_item_catalog() if player_state_service != null else null
	var loop_config = player_state_service.get_loop_config() if player_state_service != null else null
	_expect(player_state_service != null, "loop page resolves player state service")
	_expect(player_state != null, "loop page exposes player state")
	_expect(item_catalog != null, "loop page exposes item catalog")
	_expect(loop_config != null, "loop page exposes loop config")

	if player_state == null or item_catalog == null or loop_config == null:
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
	if cooking_material_snapshot.size() == 1:
		var beans_entry: Dictionary = cooking_material_snapshot[0]
		_expect(StringName(beans_entry.get("item_id", &"")) == &"beans_can", "cooking snapshot keeps the same material identity")
		_expect(int(beans_entry.get("have", 0)) >= 1 and int(beans_entry.get("need", 0)) == 1, "cooking snapshot preserves held and needed bean counts")

	var hobocraft_material_snapshot = SurvivalLoopRulesScript.get_hobocraft_recipe_material_snapshot(player_state, {
		"recipe_id": &"wire_braced_tin_can_heater",
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		]
	}, item_catalog)
	_expect(hobocraft_material_snapshot.size() == 3, "hobocraft snapshot returns one row per explicit input")
	if hobocraft_material_snapshot.size() == 3:
		_expect(int(hobocraft_material_snapshot[0].get("have", 0)) == 1, "hobocraft snapshot counts owned empty cans")
		_expect(int(hobocraft_material_snapshot[1].get("have", 0)) == 1, "hobocraft snapshot counts owned dry kindling")
		_expect(int(hobocraft_material_snapshot[2].get("have", 0)) == 1, "hobocraft snapshot counts owned baling wire")

	var relevant_cooking_items = SurvivalLoopRulesScript.get_recipe_relevant_item_snapshot(player_state, {
		"recipe_id": &"heat_beans"
	}, true, item_catalog)
	_expect(relevant_cooking_items.size() >= 1, "relevant cooking item snapshot stays available for UI notes")
	if relevant_cooking_items.size() >= 1:
		_expect(String(relevant_cooking_items[0].get("label", "")).contains("Pocket Knife"), "relevant cooking item snapshot preserves carried opener labels")

	_expect(
		SurvivalLoopRulesScript.get_available_potable_water_units(player_state, loop_config) == int(player_state.camp_potable_water_units),
		"potable water snapshot reports current camp potable water without mutation"
	)

	var cooking_lines: PackedStringArray = loop_page.call("_build_recipe_inventory_note_lines", {
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans"
	}, player_state, true)
	var cooking_note = "\n".join(cooking_lines)
	_expect(cooking_note.contains("Can of Beans:") and cooking_note.contains("/ 1"), "cooking note counts owned ingredients")
	_expect(cooking_note.contains("Pocket Knife x1"), "cooking note lists relevant owned tools")

	var hobocraft_lines: PackedStringArray = loop_page.call("_build_recipe_inventory_note_lines", {
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
	_expect(hobocraft_note.contains("Baling Wire:") and hobocraft_note.contains("/ 1"), "hobocraft note keeps material counts visible")

	var cooking_layout = loop_page.get_node("Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/CookingPage/PageRoot/CookingLayout")
	var hobocraft_layout = loop_page.get_node("Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/HobocraftPage/PageRoot/HobocraftLayout")
	_expect(cooking_layout.get_child(0) is PanelContainer, "cooking layout uses a fixed list panel instead of an inner scroll")
	_expect(cooking_layout.get_child(1) is PanelContainer, "cooking layout uses a fixed detail panel instead of an inner scroll")
	_expect(hobocraft_layout.get_child(0) is PanelContainer, "hobocraft layout uses a fixed list panel instead of an inner scroll")
	_expect(hobocraft_layout.get_child(1) is PanelContainer, "hobocraft layout uses a fixed detail panel instead of an inner scroll")

	var cooking_availability = player_state_service.get_loop_action_availability_with_context(
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		loop_page.call("_build_action_context", "recipe.card.test", {"recipe_id": &"heat_beans"})
	)
	var cooking_workspace: Control = loop_page.call("_build_recipe_workspace", {
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans",
		"summary": "Warm a can of beans over the fire and eat it hot instead of cold from the tin.",
		"inputs_text": "can of beans + fire + small cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; leaves an empty tin",
		"category": "Hot Food"
	}, player_state, cooking_availability, true, Callable(loop_page, "_on_cooking_recipe_pressed").bind(&"heat_beans"))
	_expect(cooking_workspace.get_child_count() == 2, "recipe workspace renders note and index card columns")
	_expect(cooking_workspace.get_child(0).name == "RecipeInventoryNote", "workspace left column is the inventory note")
	_expect(cooking_workspace.get_child(1).name == "RecipeIndexCard", "workspace right column is the recipe card")

	var overlay_workspace_data: Dictionary = loop_page.call("_build_overlay_recipe_workspace_data", {
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans",
		"summary": "Warm a can of beans over the fire and eat it hot instead of cold from the tin."
	}, player_state, SurvivalLoopRulesScript.ACTION_COOK_RECIPE, "recipe.card.test.overlay", "Cook %s", true)
	var overlay_card_sections: Array = overlay_workspace_data.get("card", {}).get("sections", [])
	var held_section: Dictionary = overlay_card_sections[0] if not overlay_card_sections.is_empty() else {}
	_expect(String(held_section.get("title", "")) == "Held", "camp overlay card puts held ingredient counts on the recipe card")
	_expect(String(held_section.get("body", "")).contains("held (needs 1)"), "camp overlay card shows counted held materials on the recipe card")

	var camp_layer = CampIsometricPlayLayerScene.instantiate()
	root.add_child(camp_layer)
	var overlay_models: Dictionary = loop_page.call("_build_camp_contextual_overlay_models", player_state, loop_page.call("_get_loop_config"))
	camp_layer.call("set_contextual_overlay_models", overlay_models)
	var campfire = _find_world_object(camp_layer, &"campfire")
	var stash = _find_world_object(camp_layer, &"stash")
	_expect(campfire != null, "camp layer exposes the campfire object for contextual recipe rendering")
	_expect(stash != null, "camp layer exposes the stash object for inventory handoff")
	camp_layer.call("_on_prompt_changed", "Press E to Cook", "The fire is the center of camp life.", &"campfire")
	camp_layer.call("_on_interaction_requested", campfire.get_interaction_payload())
	await process_frame
	var interaction_section_list: VBoxContainer = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionSectionScroll/InteractionSectionList")
	var overlay_workspace = interaction_section_list.get_child(0) if interaction_section_list.get_child_count() > 0 else null
	_expect(overlay_workspace != null and overlay_workspace.name == "RecipeBrowserWorkspace", "camp overlay renders the recipe workspace instead of the old browser split")
	if overlay_workspace != null:
		_expect(overlay_workspace.get_child_count() == 2, "camp overlay workspace uses recipe list and recipe card columns")
		if overlay_workspace.get_child_count() >= 2:
			_expect(overlay_workspace.get_child(0).name == "OverlayRecipeList", "camp overlay left column is the recipe list")
			_expect(overlay_workspace.get_child(1).name == "OverlayRecipeCard", "camp overlay right column is the recipe card panel")
			var overlay_list = overlay_workspace.get_child(0)
			var overlay_card = overlay_workspace.get_child(1)
			_expect(overlay_card.find_child("OverlayRecipeCardLeft", true, false) != null, "recipe card uses a landscape left column")
			_expect(overlay_card.find_child("OverlayRecipeCardRight", true, false) != null, "recipe card uses a landscape right column")
			var list_scroll = overlay_list.get_child(0)
			var list_root = list_scroll.get_child(0)
			var first_button = null
			for child in list_root.get_children():
				if child is Button:
					first_button = child
					break
			_expect(first_button is Button, "recipe categories render as collapsible buttons instead of static labels")

	var activation_payload := {}
	camp_layer.interaction_activated.connect(func(route_id: StringName, action_id: StringName, page_id: StringName):
		activation_payload = {"route_id": route_id, "action_id": action_id, "page_id": page_id}
	, CONNECT_ONE_SHOT)
	camp_layer.call("_on_prompt_changed", "Press E to Open the Stash", "What you carry is never abstract.", &"stash")
	camp_layer.call("_on_interaction_requested", stash.get_interaction_payload())
	await process_frame
	_expect(camp_layer.get("_active_overlay_object_id") == &"", "stash interaction clears any active contextual overlay before opening inventory")

	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)


func _find_world_object(camp_layer: Node, object_id: StringName):
	for world_object in camp_layer.get("_world_objects"):
		if world_object != null and world_object.id == object_id:
			return world_object
	return null
