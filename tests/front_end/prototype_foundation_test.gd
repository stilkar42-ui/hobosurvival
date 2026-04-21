extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")
const CampIsometricPlayLayerScene := preload("res://scenes/front_end/camp_isometric_play_layer.tscn")
const CampInteractionSystemScript := preload("res://scripts/front_end/camp_interaction_system.gd")
const CampWorldObjectScript := preload("res://scripts/front_end/camp_world_object.gd")
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.name = "TestRoot"
	root.size = Vector2i(1920, 1080)
	get_root().add_child(root)

	var loop_page = FirstPlayableLoopPageScene.instantiate()
	root.add_child(loop_page)
	call_deferred("_run_checks", root, loop_page)


func _run_checks(root: Window, loop_page: Control) -> void:
	await process_frame
	await process_frame
	var player_state_service = PlayerStateRuntimeScript.get_or_create_service(loop_page)
	var player_state = player_state_service.get_player_state() if player_state_service != null else null
	_expect(player_state_service != null, "front-end page can resolve the shared player state service")
	_expect(player_state != null, "front-end page loads shared player state")
	_expect(
		player_state != null and player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_TOWN,
		"first playable page does not force the starter state into camp"
	)
	var town_world_layer = loop_page.get("_camp_isometric_layer")
	_expect(town_world_layer != null and town_world_layer.get("map_mode") == &"town", "starter town opens as a walkable world layer instead of a button-only page")
	if town_world_layer != null:
		_expect(_find_world_object(town_world_layer, &"town_jobs_board") != null, "town world exposes the jobs board as an in-world object")
		_expect(_find_world_object(town_world_layer, &"town_church") != null, "town world exposes the remittance church office as an in-world object")
		_expect(_find_world_object(town_world_layer, &"town_grocery") != null, "town world exposes the grocery as an in-world object")
		_expect(_find_world_object(town_world_layer, &"town_hardware") != null, "town world exposes the hardware store as an in-world object")
		_expect(_find_world_object(town_world_layer, &"town_camp_road") != null, "town world exposes the road back to camp as an in-world object")
		_assert_prototype_world_contract(town_world_layer, &"town")
		_assert_required_objects_reachable(town_world_layer, [&"town_jobs_board", &"town_church", &"town_grocery", &"town_hardware", &"town_camp_road"])
		loop_page.call("_on_camp_interaction_activated", &"town_grocery", &"", &"grocery")
		await process_frame
		_expect(loop_page.get("_active_loop_page") == &"grocery", "using the grocery building opens the existing grocery store page")
		loop_page.call("_set_active_loop_page", &"town")
		await process_frame

	var exit_to_menu_button: Button = loop_page.get_node("Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/ReturnToMenuButton")
	var quit_button: Button = loop_page.get_node("Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/QuitGameButton")
	_expect(
		exit_to_menu_button.visible and exit_to_menu_button.pressed.is_connected(Callable(loop_page, "_on_return_to_menu_pressed")),
		"visible exit-to-menu button returns to menu instead of quitting the game"
	)
	_expect(not quit_button.visible, "direct quit button stays hidden from the routine summary column")

	var build_fire_button: Button = loop_page.find_child("BuildFireButton", true, false)
	var tend_fire_button: Button = loop_page.find_child("TendFireButton", true, false)
	var gather_kindling_button: Button = loop_page.find_child("GatherKindlingButton", true, false)
	var cooking_page_root = loop_page.get("_cooking_page_root")
	_expect(build_fire_button != null and build_fire_button.get_parent() == cooking_page_root, "build fire action remains mounted in the cooking page")
	_expect(tend_fire_button != null and tend_fire_button.get_parent() == cooking_page_root, "tend fire action remains mounted in the cooking page")
	_expect(gather_kindling_button != null and gather_kindling_button.get_parent() == cooking_page_root, "gather kindling action remains mounted in the cooking page")
	var item_catalog = player_state_service.get_item_catalog() if player_state_service != null else null
	if player_state != null and item_catalog != null:
		player_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
		player_state.set_camp_fire_level(1)
		player_state.inventory.add_item(item_catalog.get_item(&"beans_can"), 1, &"pack")
		player_state.inventory.add_item(item_catalog.get_item(&"empty_can"), 1, &"pack")
		player_state.inventory.add_item(item_catalog.get_item(&"dry_kindling"), 1, &"pack")
		player_state.inventory.add_item(item_catalog.get_item(&"baling_wire"), 1, &"pack")
		await process_frame
		var cooking_lines: PackedStringArray = loop_page.call("_build_recipe_inventory_note_lines", {
			"recipe_id": &"heat_beans",
			"display_name": "Heat Can of Beans"
		}, player_state, true)
		var cooking_note = "\n".join(cooking_lines)
		_expect(cooking_note.contains("Can of Beans:") and cooking_note.contains("/ 1"), "cooking notes show owned ingredient counts")
		_expect(cooking_note.contains("Pocket Knife x1"), "cooking notes show relevant owned tools")
		player_state.inventory.add_item(item_catalog.get_item(&"coffee_grounds"), 1, &"pack")
		player_state.camp_potable_water_units = 1
		loop_page.set("_selected_cooking_recipe_id", &"")
		var coffee_availability = player_state_service.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			{"source": "front-end-test", "recipe_id": &"brew_camp_coffee"}
		)
		_expect(coffee_availability.get("enabled", false), "coffee recipe validates as available with fire, water, grounds, and tin")
		var coffee_overlay: Dictionary = loop_page.call("_build_camp_contextual_overlay_models", player_state, loop_page.call("_get_loop_config"))
		var coffee_entries: Array = coffee_overlay.get(&"cooking", {}).get("browser", {}).get("entries", [])
		var coffee_entry_visible := false
		for entry in coffee_entries:
			if entry is Dictionary and StringName(entry.get("selection_id", &"")) == &"brew_camp_coffee":
				coffee_entry_visible = true
		_expect(coffee_entry_visible, "ready camp coffee appears in the fire/cooking overlay without hiding under a collapsed category")
		var hobocraft_lines: PackedStringArray = loop_page.call("_build_recipe_inventory_note_lines", {
			"recipe_id": &"wire_braced_tin_can_heater",
			"display_name": "Wire-Braced Tin Can on a Stick",
			"inputs": [
				{"item_id": &"empty_can", "quantity": 1},
				{"item_id": &"dry_kindling", "quantity": 1},
				{"item_id": &"baling_wire", "quantity": 1}
			]
		}, player_state, false)
		var hobocraft_note = "\n".join(hobocraft_lines)
		_expect(hobocraft_note.contains("Empty Tin Can:") and hobocraft_note.contains("/ 1"), "hobocraft notes show counted materials")
		_expect(hobocraft_note.contains("Baling Wire:") and hobocraft_note.contains("/ 1"), "hobocraft notes show each owned material requirement")

	var camp_layer = CampIsometricPlayLayerScene.instantiate()
	root.add_child(camp_layer)
	_assert_prototype_world_contract(camp_layer, &"camp")
	_assert_required_objects_reachable(camp_layer, [&"campfire", &"woodpile", &"bedroll", &"stash", &"tool_area", &"wash_line", &"trail_sign"])
	_assert_cardinal_interaction_contract()

	camp_layer.call("set_hud_snapshot", {
		"title": "Camp Condition",
		"summary": "Day 1, 8:15 AM\nWarmth steady\nFire no fire ready",
		"stats": [
			{"id": &"nutrition", "label": "Nutrition", "value": 56, "max": 100},
			{"id": &"stamina", "label": "Stamina", "value": 41, "max": 100},
			{"id": &"warmth", "label": "Warmth", "value": 63, "max": 100},
			{"id": &"morale", "label": "Morale", "value": 47, "max": 100},
			{"id": &"hygiene", "label": "Hygiene", "value": 36, "max": 100},
			{"id": &"presentability", "label": "Presentability", "value": 32, "max": 100}
		]
	})
	await process_frame

	var hud_title: Label = camp_layer.get_node("HudPanel/HudRoot/HudTitle")
	var hud_meta: Label = camp_layer.get_node("HudPanel/HudRoot/HudMeta")
	var hud_grid: GridContainer = camp_layer.get_node("HudPanel/HudRoot/HudStatsGrid")
	var nutrition_row: VBoxContainer = hud_grid.get_child(0)
	var nutrition_label: Label = nutrition_row.get_node("StatLabel")
	_expect(hud_title.text == "Camp Condition", "camp layer exposes a dedicated in-world condition HUD")
	_expect(hud_meta.text.contains("Fire no fire ready"), "camp HUD shows the routine summary text")
	_expect(nutrition_label.text == "Nutrition 56 / 100", "camp HUD shows the six condition bars with current values")

	camp_layer.call("_set_move_key_state", KEY_W, true)
	_expect(camp_layer.call("_get_screen_relative_step_from_held_keys") == Vector2i(-1, -1), "W maps to screen-up movement instead of exposed grid axes")
	camp_layer.call("_set_move_key_state", KEY_D, true)
	_expect(camp_layer.call("_get_screen_relative_step_from_held_keys") == Vector2i(0, -1), "W+D maps to the visible up-right diagonal")
	camp_layer.call("_set_move_key_state", KEY_W, false)
	camp_layer.call("_set_move_key_state", KEY_D, false)

	var wash_line = _find_world_object(camp_layer, &"wash_line")
	var campfire = _find_world_object(camp_layer, &"campfire")
	_expect(wash_line != null, "camp layer includes the wash line object")
	_expect(campfire != null, "camp layer includes the campfire object")
	_expect(
		wash_line != null and bool(wash_line.is_interactable),
		"wash line is interactable so getting-ready remains reachable from camp"
	)
	_expect(
		wash_line != null and wash_line.page_id == &"getting_ready",
		"wash line routes to the getting-ready page"
	)

	camp_layer.call("_on_prompt_changed", "Press E to Get Ready", "A place to wash, air out clothes, and put yourself back together before facing other people.", &"wash_line")
	camp_layer.call("_on_hovered_object_changed", &"wash_line")
	await process_frame
	var interaction_card: PanelContainer = camp_layer.get_node("InteractionCard")
	var hover_chip: PanelContainer = camp_layer.get_node("HoverChip")
	var hover_chip_label: Label = camp_layer.get_node("HoverChip/HoverChipRoot/HoverChipLabel")
	var interaction_button: Button = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionActionButton")
	_expect(not interaction_card.visible, "camp layer does not open a large interaction card just for standing near an object")
	_expect(hover_chip.visible, "camp layer shows a compact hover label for nearby or hovered interactables")
	_expect(hover_chip_label.text == "Wash Line", "hover label names the current interaction target")

	var loop_config = loop_page.call("_get_loop_config")
	var overlay_models: Dictionary = loop_page.call("_build_camp_contextual_overlay_models", player_state, loop_config)
	_expect(overlay_models.has(&"cooking"), "camp overlay models expose a local fire and cooking interaction model")
	_expect(overlay_models.has(&"craft"), "camp overlay models expose a local craft interaction model")
	_expect(overlay_models.has(&"ready"), "camp overlay models expose a local getting-ready interaction model")
	_expect(overlay_models.has(&"rest"), "camp overlay models expose a local sleep interaction model")

	camp_layer.call("set_contextual_overlay_models", overlay_models)
	camp_layer.call("_on_prompt_changed", "Press E to Cook", "The fire is the center of camp life: heat, boiled water, and food that gives tomorrow a chance.", &"campfire")
	camp_layer.call("_on_interaction_requested", campfire.get_interaction_payload())
	await process_frame

	var interaction_close_button: Button = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionCloseButton")
	var interaction_badge_label: Label = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionBadge/InteractionBadgeLabel")
	var interaction_subtitle: Label = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionTitleText/InteractionSubtitle")
	var interaction_section_scroll: ScrollContainer = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionSectionScroll")
	var interaction_section_list: VBoxContainer = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionSectionScroll/InteractionSectionList")
	_expect(not interaction_button.visible, "camp fire interaction opens a local overlay instead of reusing the compact prompt button")
	_expect(interaction_close_button.visible, "local camp overlays can close in-place without a page jump")
	_expect(interaction_section_scroll.visible and interaction_section_list.get_child_count() > 0, "camp fire overlay renders local action content in the world scene")
	_expect(interaction_badge_label.text == "FIRE", "camp interaction windows expose a badge home for future icons and affordances")
	_expect(interaction_subtitle.text == "coals, kettle, tins, and camp heat", "camp interaction windows expose activity-specific subtitle styling")

	var bedroll = _find_world_object(camp_layer, &"bedroll")
	camp_layer.call("_on_prompt_changed", "Press E to Rest", "Rough rest is still relief earned with preparation.", &"bedroll")
	camp_layer.call("_on_interaction_requested", bedroll.get_interaction_payload())
	await process_frame
	var bedroll_title: Label = camp_layer.get_node("InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionTitleText/InteractionTitle")
	_expect(bedroll_title.text == "Bedroll", "bedroll interaction opens a local sleep window instead of only firing the old direct action")

	camp_layer.call("_on_object_clicked", &"trail_sign")
	_expect(camp_layer.get("_pending_interaction_object_id") == &"trail_sign", "clicking a distant interactable queues movement to the object before activating it")

	var world_view = camp_layer.get_node("WorldView")
	var player_start_tile = Vector2(15, 19)
	var camp_center_screen_before = world_view.call("get_screen_position_for_grid", player_start_tile)
	camp_layer.call("_on_player_render_position_changed", player_start_tile + Vector2(1.0, 0.0))
	await process_frame
	var camp_center_screen_after = world_view.call("get_screen_position_for_grid", player_start_tile + Vector2(1.0, 0.0))
	_expect(camp_center_screen_after.distance_to(root.size * 0.5) > 8.0, "camp camera keeps a dead zone so small movement does not hard-lock the player to center")
	_expect(camp_center_screen_before.distance_to(root.size * 0.5) < 1.0, "camp camera still starts centered before the player begins moving")

	loop_page.call("_on_location_travel_pressed", SurvivalLoopRulesScript.ACTION_GO_TO_CAMP, &"camp")
	await process_frame
	var routed_camp_layer = loop_page.get("_camp_isometric_layer")
	var routed_stash = _find_world_object(routed_camp_layer, &"stash") if routed_camp_layer != null else null
	_expect(routed_stash != null, "world camp exposes the stash route for the inventory overlay")
	if routed_camp_layer != null and routed_stash != null:
		routed_camp_layer.call("_on_interaction_requested", routed_stash.get_interaction_payload())
	else:
		loop_page.call("_on_open_inventory_pressed", &"stash")
	await process_frame
	var inventory_badge: Label = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryBadge/InventoryBadgeLabel")
	var inventory_title: Label = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryTitle")
	var close_inventory_button: Button = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/CloseInventoryButton")
	var inventory_backdrop: ColorRect = loop_page.get_node("InventoryOverlay/Backdrop")
	var inventory_panel: Control = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryContentScroll/InventoryPanel")
	_expect(inventory_badge.text == "STASH", "camp stash window reserves a header badge home for future item and interaction icons")
	_expect(inventory_title.text == "Ground Stash", "camp stash opens the same inventory system as a local belongings panel")
	_expect(close_inventory_button.custom_minimum_size.x <= 150.0 and close_inventory_button.size_flags_horizontal != Control.SIZE_EXPAND_FILL, "inventory close button stays compact instead of stretching across the header")
	_expect(inventory_backdrop.color.a < 0.3, "camp inventory presentation stays light enough to keep the world scene present")
	_expect(inventory_panel.visible, "camp stash keeps the inventory panel visible instead of opening a blank slab")
	_expect(inventory_panel.get_child_count() > 0, "camp stash rebuilds the inventory panel content before presenting it")
	var inventory_window: Control = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow")
	var inventory_content_scroll: ScrollContainer = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryContentScroll")
	var inventory_actions_panel: Control = loop_page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel")
	_expect(inventory_window.custom_minimum_size.x <= 940.0 and inventory_window.custom_minimum_size.y <= 680.0, "inventory opens as a compact over-tile popup instead of a full management screen")
	_expect(inventory_content_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "compact inventory popup scrolls internally instead of growing into the playfield")
	_expect(not inventory_actions_panel.visible, "basic inventory popup does not show the old selected-container action wall")
	var inventory_text := _visible_text_under(inventory_panel)
	_expect(inventory_text.contains("Carried Gear"), "camp stash shows the readable inventory title instead of a blank surface")
	_expect(inventory_panel.find_child("InventoryBodyCenteredSurface", true, false) != null, "main inventory view uses a body-centered interaction surface instead of a provider/content split")
	var silhouette_node: Control = inventory_panel.find_child("InventoryProviderSilhouette", true, false)
	_expect(silhouette_node != null, "main inventory view keeps a central generic silhouette for provider selection")
	if silhouette_node != null:
		var panel_center_x = inventory_panel.get_global_rect().get_center().x
		var silhouette_center_x = silhouette_node.get_global_rect().get_center().x
		_expect(absf(panel_center_x - silhouette_center_x) < inventory_panel.get_global_rect().size.x * 0.18, "ragdoll silhouette stays visually central in the inventory screen")
	_expect(inventory_panel.find_child("InventoryLocationButton_head", true, false) != null, "body-centered layout includes a stable head interaction anchor")
	_expect(inventory_panel.find_child("InventoryLocationButton_slot_hand_l", true, false) != null and inventory_panel.find_child("InventoryLocationButton_slot_hand_r", true, false) != null, "body-centered layout includes stable left and right hand anchors")
	_expect(inventory_panel.find_child("InventoryLocationButton_slot_coat", true, false) != null and inventory_panel.find_child("InventoryLocationButton_slot_belt_waist", true, false) != null and inventory_panel.find_child("InventoryLocationButton_slot_pants", true, false) != null, "body-centered layout includes stable torso, belt, and pants anchors")
	_expect(inventory_panel.find_child("InventoryLocationButton_slot_shoulder_l", true, false) != null and inventory_panel.find_child("InventoryLocationButton_slot_shoulder_r", true, false) != null and inventory_panel.find_child("InventoryLocationButton_slot_back", true, false) != null, "body-centered layout includes stable shoulder and back anchors")
	_expect(inventory_panel.find_child("InventoryProviderSelector", true, false) == null, "main inventory no longer uses a provider-list selector as the primary structure")
	_expect(not inventory_text.contains("Selected Item"), "large selected-item panel is removed as the primary interaction driver")
	_expect(inventory_text.contains("Ground / Nearby"), "ground and nearby remain visible as a separate inventory area")
	_expect(inventory_text.contains("Belongings Ledger"), "full ledger remains available as a secondary control")
	_expect(not inventory_text.contains("Can of Beans"), "main inventory view does not lead with all carried item rows")
	_expect(not _visible_text_under(inventory_panel).contains("Body / Loadout"), "central inventory does not lead with RPG-style equipment slots")
	_expect(inventory_panel.has_signal("move_requested"), "inventory panel exposes one drag move request signal")
	_expect(inventory_panel.get("focused_destination_provider_id") == &"", "camp stash does not require hidden destination focus before moving items")
	var shoulder_button := inventory_panel.find_child("InventoryLocationButton_slot_shoulder_l", true, false) as Button
	_expect(shoulder_button != null and shoulder_button.get("provider_id") == InventoryScript.SLOT_SHOULDER_L, "ragdoll shoulder location is a visible provider drop target")
	if shoulder_button != null:
		shoulder_button.pressed.emit()
		await process_frame
	var container_popup: Control = loop_page.get_node_or_null("InventoryOverlay/InventoryContainerPopup_satchel_shoulder")
	_expect(container_popup != null and container_popup.visible, "clicking a worn container opens a separate rummage popup above the current tile")
	if container_popup != null:
		_expect(container_popup.get_parent() == loop_page.get_node("InventoryOverlay"), "container rummage popup lives outside the main inventory window")
		_expect(container_popup.custom_minimum_size.x <= 520.0 and container_popup.custom_minimum_size.y <= 440.0, "container rummage popup stays bounded instead of becoming a brown wall")
		_expect(not inventory_window.get_global_rect().encloses(container_popup.get_global_rect()), "container rummage popup can sit outside the main inventory window")
		var popup_text := _visible_text_under(container_popup)
		_expect(not popup_text.contains("Visible Places"), "container rummage popup omits duplicate visible-place destination lists")
		_expect(container_popup.find_child("InventoryLocationButton_slot_hand_l", true, false) == null, "container rummage popup leaves body providers in the main inventory window")
		var popup_header := container_popup.find_child("InventoryContainerPopupHeader", true, false) as Control
		if popup_header != null:
			var popup_position_before = container_popup.position
			var popup_press := InputEventMouseButton.new()
			popup_press.button_index = MOUSE_BUTTON_LEFT
			popup_press.pressed = true
			popup_press.position = Vector2(20.0, 14.0)
			popup_header.gui_input.emit(popup_press)
			var popup_drag := InputEventMouseMotion.new()
			popup_drag.relative = Vector2(36.0, 18.0)
			popup_drag.position = Vector2(56.0, 32.0)
			popup_header.gui_input.emit(popup_drag)
			var popup_release := InputEventMouseButton.new()
			popup_release.button_index = MOUSE_BUTTON_LEFT
			popup_release.pressed = false
			popup_release.position = Vector2(56.0, 32.0)
			popup_header.gui_input.emit(popup_release)
			await process_frame
			_expect(container_popup.position.distance_to(popup_position_before) > 8.0, "container rummage popup can be dragged so players can organize windows")
	_expect(inventory_panel.find_child("InventoryLocationButton_slot_coat", true, false) != null, "main ragdoll remains mounted beneath the container popup")
	var close_container_button := container_popup.find_child("CloseFocusedContainerButton", true, false) as Button if container_popup != null else null
	if close_container_button != null:
		close_container_button.pressed.emit()
		await process_frame
	_expect(loop_page.get_node_or_null("InventoryOverlay/InventoryContainerPopup_satchel_shoulder") == null, "closing the rummage popup returns to the ragdoll without closing inventory")
	var hand_button := inventory_panel.find_child("InventoryLocationButton_slot_hand_l", true, false) as Button
	_expect(hand_button != null and hand_button.get("provider_id") == InventoryScript.SLOT_HAND_L, "left hand is a visible provider drop target")
	var beans_index = _find_stack_index(player_state, &"beans_can")
	var beans_drag_payload: Dictionary = inventory_panel.call("build_stack_drag_payload", beans_index)
	var hand_preview: Dictionary = inventory_panel.call("preview_move_for_drag", beans_drag_payload, InventoryScript.SLOT_HAND_L)
	_expect(not hand_preview.get("success", false) and hand_preview.get("reason_code", &"") == &"target_occupied", "occupied hands reject drops through Inventory.move capacity validation")
	var hand_repeat_preview: Dictionary = inventory_panel.call("preview_move_for_drag", inventory_panel.call("build_stack_drag_payload", _find_stack_index(player_state, &"empty_can")), InventoryScript.SLOT_HAND_L)
	_expect(not hand_repeat_preview.get("success", false) and hand_repeat_preview.get("reason_code", &"") == &"target_occupied", "invalid drag previews surface inventory-layer failure reasons")
	var ground_preview: Dictionary = inventory_panel.call("preview_move_for_drag", beans_drag_payload, InventoryScript.CARRY_GROUND)
	_expect(ground_preview.get("success", false), "drag preview delegates stack-to-visible-ground validation to Inventory.move")
	inventory_panel.call("request_move_for_drag", beans_drag_payload, InventoryScript.CARRY_GROUND)
	await process_frame
	var dropped_beans = player_state.inventory_state.get_stack_at(_find_stack_index(player_state, &"beans_can"))
	_expect(dropped_beans != null and dropped_beans.carry_zone == InventoryScript.CARRY_GROUND, "dragging an item to visible ground commits through the same move function")
	_expect(inventory_panel.find_child("FocusedContainerOverlay", true, false) == null or not inventory_panel.find_child("FocusedContainerOverlay", true, false).visible, "basic inventory movement does not require a focused container overlay")
	var inventory_radial_menu: Control = loop_page.get_node("InventoryOverlay/InventoryRadialMenu")
	shoulder_button = inventory_panel.find_child("InventoryLocationButton_slot_shoulder_l", true, false) as Button
	if shoulder_button != null:
		var shoulder_context := InputEventMouseButton.new()
		shoulder_context.button_index = MOUSE_BUTTON_RIGHT
		shoulder_context.pressed = true
		shoulder_context.position = shoulder_button.size * 0.5
		shoulder_context.global_position = shoulder_button.get_global_rect().get_center()
		shoulder_button.gui_input.emit(shoulder_context)
		await process_frame
	_expect(inventory_radial_menu.visible, "right-clicking a body/provider location opens the inventory radial menu")
	inventory_radial_menu.call("hide_menu")
	_expect(not _visible_text_under(inventory_panel).contains("Closed on ground"), "visible containers do not require an open-container step before use")
	_expect(inventory_panel.find_child("InventoryLocationButton_slot_shoulder_l", true, false) != null, "main provider map remains available without container focus state")
	var ledger_button := inventory_panel.find_child("BelongingsLedgerToggleButton", true, false) as Button
	_expect(ledger_button != null, "Belongings Ledger is exposed as a secondary button")
	if ledger_button != null:
		ledger_button.pressed.emit()
		await process_frame
	_expect(inventory_panel.find_child("InventoryLedgerRow_0", true, false) != null, "Belongings Ledger button opens the full ledger rows only when requested")
	var ledger_row := inventory_panel.find_child("InventoryLedgerRow_0", true, false) as Button
	if ledger_row != null:
		var item_context := InputEventMouseButton.new()
		item_context.button_index = MOUSE_BUTTON_RIGHT
		item_context.pressed = true
		item_context.position = ledger_row.size * 0.5
		item_context.global_position = ledger_row.get_global_rect().get_center()
		ledger_row.gui_input.emit(item_context)
		await process_frame
	_expect(inventory_radial_menu.visible, "right-clicking an item opens the inventory radial menu")
	inventory_radial_menu.call("hide_menu")
	var carried_gear_label = inventory_panel.find_child("InventoryPanelTitle", true, false)
	_expect(carried_gear_label != null and inventory_panel.get_global_rect().intersects(carried_gear_label.get_global_rect()), "camp stash positions readable inventory content inside the visible panel")
	var resize_handle: Control = loop_page.get("_inventory_resize_handle")
	_expect(resize_handle == null or not resize_handle.visible, "normal inventory use does not expose a resize affordance")

	loop_page.call("_on_close_inventory_pressed")
	await process_frame
	_expect(not loop_page.get_node("InventoryOverlay").visible, "inventory can close before keyboard toggle check")
	var open_inventory_key := InputEventKey.new()
	open_inventory_key.keycode = KEY_I
	open_inventory_key.pressed = true
	loop_page.call("_unhandled_input", open_inventory_key)
	await process_frame
	_expect(loop_page.get_node("InventoryOverlay").visible, "I opens the compact inventory popup over the current tile")
	var close_inventory_key := InputEventKey.new()
	close_inventory_key.keycode = KEY_I
	close_inventory_key.pressed = true
	loop_page.call("_unhandled_input", close_inventory_key)
	await process_frame
	_expect(not loop_page.get_node("InventoryOverlay").visible, "I closes the compact inventory popup")

	loop_page.call("_on_close_inventory_pressed")
	player_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	loop_page.call("_set_active_loop_page", &"camp", false)
	var rest_models: Dictionary = loop_page.call("_build_camp_contextual_overlay_models", player_state, loop_config)
	routed_camp_layer.call("set_contextual_overlay_models", rest_models)
	var routed_bedroll = _find_world_object(routed_camp_layer, &"bedroll")
	routed_camp_layer.call("_on_prompt_changed", "Press E to Rest", "Rough rest is still relief earned with preparation.", &"bedroll")
	routed_camp_layer.call("_on_interaction_requested", routed_bedroll.get_interaction_payload())
	await process_frame
	var rest_section_list: VBoxContainer = routed_camp_layer.get_node("InteractionCard/InteractionRoot/InteractionSectionScroll/InteractionSectionList")
	var rest_text = _visible_text_under(rest_section_list)
	_expect(rest_text.contains("-") and rest_text.contains("+") and rest_text.contains("hours"), "sleep window renders a compact minus/current/plus hour selector")
	_expect(not rest_text.contains("1h\n2h\n3h"), "sleep window no longer renders the old long vertical hour list")
	_expect(_button_count_under(rest_section_list, "set_rest_hours") <= 3, "sleep hour selection uses compact controls instead of twelve hour buttons")

	quit(1 if _failed else 0)


func _find_world_object(camp_layer: Node, object_id: StringName):
	if camp_layer == null:
		return null
	for world_object in camp_layer.get("_world_objects"):
		if world_object != null and world_object.id == object_id:
			return world_object
	return null


func _assert_prototype_world_contract(camp_layer: Node, mode: StringName) -> void:
	var world_view = camp_layer.get_node_or_null("WorldView")
	_expect(world_view != null, "%s prototype world exposes a drawable world view" % String(mode))
	if world_view == null:
		return
	var allowed_ground := {}
	var world_size := Vector2i(32, 32)
	var forbidden_objects: Array[StringName] = []
	var required_objects: Array[StringName] = []
	if mode == &"town":
		allowed_ground = {&"path": true, &"packed_dirt": true, &"grass": true}
		world_size = Vector2i(64, 32)
		required_objects = [&"town_jobs_board", &"town_church", &"town_grocery", &"town_hardware", &"town_camp_road"]
		forbidden_objects = [&"town_foreman_office", &"town_lamp_w", &"town_lamp_e", &"town_trash_grocery", &"town_crate_hardware", &"town_board_stack_depot", &"town_wheelbarrow_depot", &"town_handcart_shop", &"town_lanterns_board"]
	else:
		allowed_ground = {&"camp": true, &"path": true, &"grass": true}
		required_objects = [&"campfire", &"woodpile", &"bedroll", &"stash", &"tool_area", &"wash_line", &"trail_sign"]
		forbidden_objects = [&"lean_to_w", &"lean_to_e", &"log_sw", &"log_s", &"stump_s", &"crate_e", &"coffee_setup", &"camp_sack", &"camp_rocks"]
	var noisy_ground_hits: Array[String] = []
	for y in range(world_size.y):
		for x in range(world_size.x):
			var tile_key: StringName = world_view.call("_resolve_ground_tile_key", Vector2i(x, y))
			if not allowed_ground.has(tile_key):
				noisy_ground_hits.append("%s at %d,%d" % [String(tile_key), x, y])
	_expect(noisy_ground_hits.is_empty(), "%s terrain resolves only prototype keys; noisy hits: %s" % [String(mode), ", ".join(noisy_ground_hits)])
	for object_id in required_objects:
		_expect(_find_world_object(camp_layer, object_id) != null, "%s prototype keeps required object %s" % [String(mode), String(object_id)])
	for object_id in forbidden_objects:
		_expect(_find_world_object(camp_layer, object_id) == null, "%s prototype removes decorative object %s" % [String(mode), String(object_id)])


func _assert_required_objects_reachable(camp_layer: Node, object_ids: Array[StringName]) -> void:
	var player_controller = camp_layer.get_node_or_null("PlayerController")
	var interaction_system = camp_layer.get_node_or_null("InteractionSystem")
	_expect(player_controller != null, "prototype layer exposes a player controller for reachability checks")
	_expect(interaction_system != null, "prototype layer exposes an interaction system for reachability checks")
	if player_controller == null or interaction_system == null:
		return
	var spawn_tile: Vector2i = player_controller.get("grid_position")
	for object_id in object_ids:
		player_controller.call("set_grid_position", spawn_tile)
		player_controller.call("clear_path")
		var reachable := false
		var candidates: Array = interaction_system.call("get_interaction_tiles", object_id)
		for candidate in candidates:
			player_controller.call("set_grid_position", spawn_tile)
			player_controller.call("clear_path")
			if bool(player_controller.call("request_path_to", candidate)):
				reachable = true
				break
		_expect(reachable, "prototype pathing reaches an interaction tile for %s" % String(object_id))


func _assert_cardinal_interaction_contract() -> void:
	var interaction_system = CampInteractionSystemScript.new()
	var facade = CampWorldObjectScript.new({
		"id": &"test_facade",
		"position": Vector2(10.5, 11.0),
		"size_tiles": Vector2i(2, 2),
		"is_interactable": true
	})
	interaction_system.set_world_objects([facade])
	interaction_system.set_player_grid_position(Vector2i(10, 10))
	_expect(not interaction_system.is_player_adjacent_to_object(&"test_facade"), "occupied object tiles do not count as interaction-adjacent")
	interaction_system.set_player_grid_position(Vector2i(9, 9))
	_expect(not interaction_system.is_player_adjacent_to_object(&"test_facade"), "diagonal-only contact does not count as interaction-adjacent")
	interaction_system.set_player_grid_position(Vector2i(9, 10))
	_expect(interaction_system.is_player_adjacent_to_object(&"test_facade"), "cardinal edge tiles count as interaction-adjacent")
	interaction_system.free()


func _visible_text_under(node: Node) -> String:
	var lines: Array[String] = []
	_collect_visible_text(node, lines)
	return "\n".join(lines)


func _button_count_under(node: Node, command_type: String) -> int:
	var count := 0
	if node is Button and node.has_meta("command_type") and String(node.get_meta("command_type")) == command_type:
		count += 1
	for child in node.get_children():
		count += _button_count_under(child, command_type)
	return count


func _find_button_containing(node: Node, text_fragment: String) -> Button:
	if node is Button and String(node.text).contains(text_fragment):
		return node
	for child in node.get_children():
		var found := _find_button_containing(child, text_fragment)
		if found != null:
			return found
	return null


func _find_stack_index(player_state, item_id: StringName) -> int:
	if player_state == null or player_state.inventory_state == null:
		return -1
	for index in range(player_state.inventory_state.stacks.size()):
		var stack = player_state.inventory_state.get_stack_at(index)
		if stack != null and stack.item != null and stack.item.item_id == item_id:
			return index
	return -1


func _collect_visible_text(node: Node, lines: Array[String]) -> void:
	if node is CanvasItem and not node.visible:
		return
	if node is Label or node is Button:
		var text = String(node.text).strip_edges()
		if text != "":
			lines.append(text)
	for child in node.get_children():
		_collect_visible_text(child, lines)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
