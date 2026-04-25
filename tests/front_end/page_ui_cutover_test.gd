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
	_expect_shell_layout_reserves_condition_strip(loop_page)
	_expect(world_map_panel != null and not _control_has_label_text(world_map_panel, "Road Condition"), "world map does not duplicate the shell condition strip")
	_expect_persistent_condition_strip(loop_page, "world map")

	ui_manager.open_page(&"travel_ui", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"TravelPage", "travel route resolves through UIManager")
	var travel_panel: Control = loop_page.find_child("TravelPagePanel", true, false)
	_expect(travel_panel != null, "travel page panel exists")
	_expect(not _panel_has_button_text(travel_panel, "Jobs Board"), "travel page no longer acts as a navigation hub")
	_expect(not _panel_has_button_text(travel_panel, "Grocery"), "travel page no longer exposes town page shortcuts")

	ui_manager.open_page(&"location_page", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "base location route resolves through UIManager")
	_expect_town_services_hub(loop_page)
	_expect_no_active_feature_window(loop_page, "base location route keeps service window closed")

	ui_manager.open_page(&"send_money", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "send money route resolves through UIManager")
	_expect_feature_window(loop_page, "send money route opens a feature window")
	var send_window = loop_page.find_child("TownServiceFeatureWindow", true, false)
	_expect(send_window != null and _control_has_label_text(send_window, "Exact Amount"), "send money window keeps exact amount controls")

	ui_manager.open_page(&"location_page", {"return_route": &"town", "route_id": &"grocery"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "direct location page route resolves through UIManager")
	_expect(ui_manager.get_active_route() == &"location_page", "direct location page route is tracked in UIManager")
	_expect_persistent_condition_strip(loop_page, "location grocery")
	_expect_store_route_has_shop_widget(loop_page, "GroceryShopStockWidget", "grocery route renders shop stock window")

	ui_manager.open_page(&"hardware", {"return_route": &"town"})
	await process_frame
	_expect_store_route_has_shop_widget(loop_page, "HardwareShopStockWidget", "hardware route renders shop stock window")

	ui_manager.open_page(&"general_store", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "general store route resolves through UIManager")
	_expect_store_route_has_shop_widget(loop_page, "GeneralStoreShopStockWidget", "general store route renders shop stock window")

	ui_manager.open_page(&"medicine", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "medicine store route resolves through UIManager")
	_expect_store_route_has_shop_widget(loop_page, "MedicineStoreShopStockWidget", "medicine store route renders shop stock window")

	ui_manager.open_page(&"doctor_apothecary", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "doctor/apothecary route resolves through UIManager")
	_expect_feature_window(loop_page, "doctor/apothecary route opens a feature window")
	_expect_location_route_has_visible_cards(loop_page, "DoctorApothecaryListWidget", "Care Action", "doctor/apothecary route renders visible care cards")

	ui_manager.open_page(&"jobs_board", {"return_route": &"town"})
	await process_frame
	_expect_feature_window(loop_page, "jobs board route opens a feature window")
	_expect_location_route_has_visible_cards(loop_page, "JobsListWidget", "Take Work", "jobs board renders posted work cards")
	_close_feature_window(loop_page)
	await process_frame
	_expect_no_active_feature_window(loop_page, "closing service window returns to the hub")
	_expect_town_services_hub(loop_page)

	ui_manager.open_page(&"crafting_page", {"return_route": &"camp", "route_id": &"hobocraft"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"CraftingPage", "direct crafting page route resolves through UIManager")
	_expect_persistent_condition_strip(loop_page, "crafting")

	ui_manager.open_page(&"cooking", {"return_route": &"camp"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"CookingPage", "cooking route resolves through UIManager")
	_expect_persistent_condition_strip(loop_page, "cooking")

	ui_manager.open_page(&"inventory_ui", {"return_route": &"town"})
	await process_frame
	_expect(ui_manager.get_active_page() == &"InventoryPage", "inventory overlay opens through the page router")
	_expect(inventory_overlay.visible, "inventory page controls the inventory overlay visibility")
	_expect_persistent_condition_strip(loop_page, "inventory")

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
	_expect(not _control_has_label_text(getting_ready_overlay, "ROAD CONDITION"), "rest camp overlay does not duplicate the shell condition strip")
	_expect_persistent_condition_strip(loop_page, "rest camp")

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
	_expect(list_rect.size.x > 20.0 and list_rect.size.y >= 320.0, "%s list has large route-window height" % message)
	var list_root = list.get_list_root()
	var first_child = list_root.get_child(0) if list_root != null and list_root.get_child_count() > 0 else null
	_expect(first_child is Control, "%s first card exists" % message)
	if first_child is Control:
		var first_rect: Rect2 = first_child.get_global_rect()
		_expect(first_child.is_visible_in_tree(), "%s first card is visible" % message)
		_expect(first_rect.size.x > 20.0 and first_rect.size.y > 20.0, "%s first card has rendered size" % message)
	_expect(_panel_has_button_text(first_child, action_text), "%s exposes %s action" % [message, action_text])


func _expect_store_route_has_shop_widget(loop_page: Control, widget_name: String, message: String) -> void:
	_expect_feature_window(loop_page, "%s opens a feature window" % message)
	var widget = loop_page.find_child(widget_name, true, false)
	_expect(widget != null, "%s shop widget exists" % message)
	if widget == null:
		return
	_expect(widget.is_visible_in_tree(), "%s shop widget is visible" % message)
	var rect: Rect2 = widget.get_global_rect()
	_expect(rect.size.x > 260.0 and rect.size.y > 220.0, "%s shop widget has a usable window rect" % message)
	_expect(widget.has_method("get_stock_count") and widget.get_stock_count() > 0, "%s shop widget has stock entries" % message)
	_expect(widget.has_method("get_selected_stock_index") and widget.get_selected_stock_index() >= 0, "%s shop widget has a selected stock item" % message)
	_expect(_panel_has_button_text(widget, "Buy Stock"), "%s exposes Buy Stock action" % message)


func _expect_town_services_hub(loop_page: Control) -> void:
	var location_panel = loop_page.find_child("LocationPagePanel", true, false) as Control
	_expect(location_panel != null, "town services hub page exists")
	var nav_panel = loop_page.find_child("TownServicesNavPanel", true, false) as Control
	_expect(nav_panel != null, "town services hub nav exists")
	if nav_panel != null:
		_expect(nav_panel.is_visible_in_tree(), "town services hub nav is visible")
		for label in ["Posted Work", "Send Money", "Grocery", "Hardware", "General Store", "Medicine Store", "Doctor / Apothecary"]:
			_expect(_panel_has_button_text(nav_panel, label), "town services hub exposes %s" % label)


func _expect_no_active_feature_window(loop_page: Control, message: String) -> void:
	var window = loop_page.find_child("TownServiceFeatureWindow", true, false) as Control
	_expect(window != null, "%s feature window exists" % message)
	if window != null:
		_expect(not window.visible, "%s feature window is hidden" % message)


func _expect_feature_window(loop_page: Control, message: String) -> void:
	var window = loop_page.find_child("TownServiceFeatureWindow", true, false) as Control
	_expect(window != null, "%s" % message)
	if window == null:
		return
	_expect(window.is_visible_in_tree(), "%s is visible" % message)
	var rect: Rect2 = window.get_global_rect()
	var viewport_rect: Rect2 = loop_page.get_viewport_rect()
	_expect(rect.size.x >= 560.0 and rect.size.y >= 420.0, "%s has a large usable rect" % message)
	_expect(_rect_inside(viewport_rect, rect), "%s stays inside the viewport" % message)
	var nav_panel = window.find_child("TownServicesNavPanel", true, false)
	_expect(nav_panel == null, "%s does not duplicate town service navigation" % message)


func _close_feature_window(loop_page: Control) -> void:
	var window = loop_page.find_child("TownServiceFeatureWindow", true, false) as Control
	_expect(window != null and window.visible, "feature window can be closed from route content")
	if window == null:
		return
	var close_button = _find_button_with_text(window, "Close")
	_expect(close_button != null, "feature window exposes a close button in LocationPage")
	if close_button != null:
		close_button.emit_signal("pressed")


func _find_button_with_text(root: Node, needle: String) -> Button:
	for child in root.find_children("*", "Button", true, false):
		var button = child as Button
		if button != null and button.text.find(needle) != -1:
			return button
	return null


func _expect_persistent_condition_strip(loop_page: Control, route_label: String) -> void:
	var strip = loop_page.find_child("PersistentConditionStrip", true, false)
	_expect(strip != null, "%s keeps the persistent condition strip" % route_label)
	if strip == null:
		return
	_expect(strip.is_visible_in_tree(), "%s persistent condition strip is visible" % route_label)
	var rect: Rect2 = strip.get_global_rect()
	_expect(rect.size.x > 20.0 and rect.size.y > 20.0, "%s persistent condition strip has rendered size" % route_label)
	for label in ["Warmth", "Stamina", "Nutrition", "Water", "Morale", "Hygiene", "Presentability", "Weight", "Dampness"]:
		_expect(_control_has_label_text(strip, label), "%s persistent condition strip shows %s" % [route_label, label])


func _expect_shell_layout_reserves_condition_strip(loop_page: Control) -> void:
	var summary_root = loop_page.get_node_or_null("Root/SummaryPanel/SummaryRoot")
	var strip = loop_page.find_child("PersistentConditionStrip", true, false)
	var page_window = loop_page.find_child("PageWindowFrame", true, false)
	_expect(summary_root != null, "shell summary root exists")
	_expect(strip != null and _has_ancestor(strip, summary_root), "persistent condition strip is reserved inside the summary layout")
	_expect(page_window != null, "page window frame exists")
	if strip is Control and page_window is Control:
		var strip_rect: Rect2 = strip.get_global_rect()
		var page_rect: Rect2 = page_window.get_global_rect()
		_expect(not strip_rect.intersects(page_rect), "persistent condition strip does not overlap page window frame")
		_expect(page_rect.position.y >= strip_rect.end.y, "page window frame begins below the persistent condition strip")


func _has_ancestor(node: Node, expected_ancestor: Node) -> bool:
	var current = node
	while current != null:
		if current == expected_ancestor:
			return true
		current = current.get_parent()
	return false


func _control_has_label_text(root: Node, expected_text: String) -> bool:
	for child in root.find_children("*", "Label", true, false):
		if child is Label and child.text == expected_text:
			return true
	return false


func _rect_inside(parent_rect: Rect2, child_rect: Rect2) -> bool:
	return child_rect.position.x >= parent_rect.position.x \
		and child_rect.position.y >= parent_rect.position.y \
		and child_rect.end.x <= parent_rect.end.x \
		and child_rect.end.y <= parent_rect.end.y
