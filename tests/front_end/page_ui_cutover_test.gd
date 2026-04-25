extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.name = "TestRoot"
	root.size = Vector2i(1600, 900)
	get_root().add_child(root)

	var loop_page = FirstPlayableLoopPageScene.instantiate()
	root.add_child(loop_page)
	call_deferred("_run_checks", loop_page)


func _run_checks(loop_page: Control) -> void:
	await process_frame
	await process_frame

	var player_state_service = PlayerStateRuntimeScript.get_or_create_service(loop_page)
	var ui_manager = loop_page.get("_ui_manager")
	var viewport_host: Control = loop_page.get_node("CampViewportHost")
	var inventory_overlay: Control = loop_page.get_node("InventoryOverlay")
	var passport_overlay: Control = loop_page.get_node("PassportOverlay")
	var getting_ready_overlay: Control = loop_page.get_node("GettingReadyOverlay")
	var world_map_panel: Control = loop_page.find_child("WorldMapPagePanel", true, false)

	_expect(player_state_service != null, "page UI cutover resolves shared player state service")
	_expect(ui_manager != null, "page UI cutover exposes UIManager")
	_expect(loop_page.get("_camp_isometric_layer") == null, "page UI cutover does not mount the isometric play layer")
	_expect(not viewport_host.visible, "page UI cutover keeps the legacy viewport host inactive")
	_expect(ui_manager.get_active_page() == &"WorldMapPage", "page UI cutover starts on the world map page")
	_expect(ui_manager.get_active_route() == &"town", "page UI cutover starts on the town route")
	_expect(world_map_panel != null, "world map page panel exists")
	_expect(not _panel_has_button_text(world_map_panel, "Status / Result"), "world map no longer exposes the ambiguous status/result route")

	ui_manager.open_page(&"travel_ui", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"TravelPage", "travel route resolves through UIManager")
	var travel_panel: Control = loop_page.find_child("TravelPagePanel", true, false)
	_expect(travel_panel != null, "travel page panel exists")
	_expect(not _panel_has_button_text(travel_panel, "Jobs Board"), "travel page no longer acts as a navigation hub")
	_expect(not _panel_has_button_text(travel_panel, "Grocery"), "travel page no longer exposes town page shortcuts")

	ui_manager.open_page(&"location_page", {"return_route": &"town", "route_id": &"grocery"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "direct location page route resolves through UIManager")
	_expect(ui_manager.get_active_route() == &"location_page", "direct location page route is tracked in UIManager")
	_expect_location_route_has_visible_cards(loop_page, "GroceryListWidget", "Buy Stock", "grocery route renders visible stock cards")

	ui_manager.open_page(&"hardware", {"return_route": &"town"})
	await process_frame
	_expect_location_route_has_visible_cards(loop_page, "HardwareListWidget", "Buy Stock", "hardware route renders visible stock cards")

	ui_manager.open_page(&"general_store", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "general store route resolves through UIManager")
	_expect_location_route_has_visible_cards(loop_page, "GeneralStoreListWidget", "Buy Stock", "general store route renders visible stock cards")

	ui_manager.open_page(&"doctor_apothecary", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "doctor/apothecary route resolves through UIManager")
	_expect_location_route_has_visible_cards(loop_page, "DoctorApothecaryListWidget", "Care Action", "doctor/apothecary route renders visible care cards")

	ui_manager.open_page(&"jobs_board", {"return_route": &"town"})
	await process_frame
	_expect_location_route_has_visible_cards(loop_page, "JobsListWidget", "Take Work", "jobs board renders posted work cards")

	ui_manager.open_page(&"crafting_page", {"return_route": &"camp", "route_id": &"hobocraft"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"CraftingPage", "direct crafting page route resolves through UIManager")

	ui_manager.open_page(&"cooking", {"return_route": &"camp"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"CookingPage", "cooking route resolves through UIManager")

	ui_manager.open_page(&"inventory_ui", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"InventoryPage", "inventory overlay opens through the page router")
	_expect(inventory_overlay.visible, "inventory page controls the inventory overlay visibility")

	ui_manager.open_page(&"passport_stats", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"PassportStatsPage", "passport overlay opens through the page router")
	_expect(passport_overlay.visible, "passport stats page controls the passport overlay visibility")
	var passport_panel: Control = loop_page.get_node("PassportOverlay/PassportMargin/PassportWindow/PassportRoot/PassportPanel")
	var passport_buttons := passport_panel.find_children("*", "Button", true, false)
	for button in passport_buttons:
		if button is Button and button.text != "Close":
			button.emit_signal("pressed")
			break
	await process_frame
	await process_frame
	_expect(passport_overlay.visible, "passport interactions do not freeze or collapse the overlay")

	ui_manager.open_page(&"rest_camp_page", {"return_route": &"camp", "route_id": &"rest_camp"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"RestCampPage", "direct rest camp page route resolves through UIManager")
	_expect(getting_ready_overlay.visible, "rest camp page controls the camp rest overlay visibility")

	_expect(loop_page.find_child("CampIsometricPlayLayer", true, false) == null, "no isometric play layer node exists in the runtime tree")

	if _failed:
		quit(1)
		return
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true


func _panel_has_button_text(root: Node, text: String) -> bool:
	for child in root.find_children("*", "Button", true, false):
		if child is Button and child.text == text:
			return true
	return false


func _expect_location_route_has_visible_cards(loop_page: Control, list_name: String, action_text: String, message: String) -> void:
	var list = loop_page.find_child(list_name, true, false)
	_expect(list != null, "%s list exists" % message)
	if list == null:
		return
	_expect(list.get_item_count() > 0, "%s list has cards" % message)
	_expect(list.is_visible_in_tree(), "%s list is visible" % message)
	var list_rect: Rect2 = list.get_global_rect()
	_expect(list_rect.size.x > 20.0 and list_rect.size.y >= 160.0, "%s list has usable visible height" % message)
	var list_root = list.get_list_root()
	var first_child = list_root.get_child(0) if list_root != null and list_root.get_child_count() > 0 else null
	_expect(first_child is Control, "%s first card exists" % message)
	if first_child is Control:
		var first_rect: Rect2 = first_child.get_global_rect()
		_expect(first_child.is_visible_in_tree(), "%s first card is visible" % message)
		_expect(first_rect.size.x > 20.0 and first_rect.size.y > 20.0, "%s first card has rendered size" % message)
	_expect(_panel_has_button_text(first_child, action_text), "%s exposes %s action" % [message, action_text])
