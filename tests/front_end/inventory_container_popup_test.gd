extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.name = "InventoryContainerPopupTestRoot"
	root.size = Vector2i(1280, 720)
	get_root().add_child(root)

	var loop_page = FirstPlayableLoopPageScene.instantiate()
	root.add_child(loop_page)
	call_deferred("_run_checks", loop_page)


func _run_checks(loop_page: Control) -> void:
	await process_frame
	await process_frame

	var ui_manager = loop_page.get("_ui_manager")
	var inventory_page = loop_page.get("_inventory_page")
	_expect(ui_manager != null, "inventory popup test resolves UIManager")
	_expect(inventory_page != null, "inventory popup test resolves InventoryPage")
	if ui_manager == null or inventory_page == null:
		quit(1)
		return

	ui_manager.open_page(&"inventory_ui", {"return_route": &"town"})
	await process_frame
	await process_frame

	_open_provider_window(inventory_page, &"backpack_back")
	await process_frame
	var backpack_popup = _find_popup(loop_page, &"backpack_back")
	_expect(backpack_popup != null, "opening backpack creates one popup")
	_expect(_count_popups(loop_page) == 1, "one popup exists after opening backpack")
	_expect(backpack_popup != null and backpack_popup.is_visible_in_tree(), "backpack popup is visible")
	_expect(backpack_popup != null and _rect_inside(_get_inventory_window_rect(loop_page), backpack_popup.get_global_rect()), "backpack popup stays inside inventory window")

	_open_provider_window(inventory_page, &"backpack_back")
	await process_frame
	var reused_backpack_popup = _find_popup(loop_page, &"backpack_back")
	_expect(reused_backpack_popup == backpack_popup, "reopening backpack reuses existing popup")
	_expect(_count_popups(loop_page) == 1, "reopening backpack does not create duplicate popups")

	_open_provider_window(inventory_page, &"satchel_shoulder")
	await process_frame
	var satchel_popup = _find_popup(loop_page, &"satchel_shoulder")
	_expect(satchel_popup != null, "opening satchel creates a second popup")
	_expect(_count_popups(loop_page) == 2, "two different container popups can stay open")
	if backpack_popup != null and satchel_popup != null:
		_expect(backpack_popup.position != satchel_popup.position, "different container popups open at staggered positions")
		_expect(_rect_inside(_get_inventory_window_rect(loop_page), satchel_popup.get_global_rect()), "satchel popup stays inside inventory window")

	if backpack_popup != null:
		var start_position: Vector2 = backpack_popup.position
		var start_global: Vector2 = backpack_popup.get_global_rect().position + Vector2(24.0, 14.0)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.global_position = start_global
		inventory_page.call("_on_inventory_container_popup_header_gui_input", press, &"backpack_back", backpack_popup)

		var motion := InputEventMouseMotion.new()
		motion.global_position = start_global + Vector2(90.0, 60.0)
		inventory_page.call("_on_inventory_container_popup_header_gui_input", motion, &"backpack_back", backpack_popup)

		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.global_position = motion.global_position
		inventory_page.call("_on_inventory_container_popup_header_gui_input", release, &"backpack_back", backpack_popup)
		await process_frame

		_expect(backpack_popup.position != start_position, "dragging the popup header moves the popup")
		_expect(_rect_inside(_get_inventory_window_rect(loop_page), backpack_popup.get_global_rect()), "dragged popup remains inside inventory window")

	if backpack_popup != null:
		var close_button = _find_button_with_text(backpack_popup, "Close")
		_expect(close_button != null, "container popup exposes close button")
		if close_button != null:
			close_button.emit_signal("pressed")
			await process_frame
			_expect(_find_popup(loop_page, &"backpack_back") == null, "close removes the selected container popup")
			_expect(_find_popup(loop_page, &"satchel_shoulder") != null, "closing one popup leaves the other popup open")

	if _failed:
		quit(1)
		return
	quit()


func _find_popup(loop_page: Control, provider_id: StringName) -> Control:
	return loop_page.find_child("InventoryContainerPopup_%s" % String(provider_id), true, false) as Control


func _open_provider_window(inventory_page, provider_id: StringName) -> void:
	var inventory_panel = inventory_page.get("_inventory_panel")
	_expect(inventory_panel != null, "inventory page exposes inventory panel for popup test")
	if inventory_panel == null:
		return
	inventory_panel.set_selected_container_provider_id(provider_id)
	inventory_page.call("_open_selected_container")


func _count_popups(loop_page: Control) -> int:
	var count := 0
	for popup in loop_page.find_children("InventoryContainerPopup_*", "PanelContainer", true, false):
		if popup is Control and popup.is_inside_tree():
			count += 1
	return count


func _get_inventory_window_rect(loop_page: Control) -> Rect2:
	var window = loop_page.find_child("InventoryWindow", true, false) as Control
	if window != null:
		return window.get_global_rect()
	return loop_page.get_viewport_rect()


func _find_button_with_text(root: Node, expected_text: String) -> Button:
	for child in root.find_children("*", "Button", true, false):
		var button = child as Button
		if button != null and button.text == expected_text:
			return button
	return null


func _rect_inside(parent_rect: Rect2, child_rect: Rect2) -> bool:
	return child_rect.position.x >= parent_rect.position.x \
		and child_rect.position.y >= parent_rect.position.y \
		and child_rect.end.x <= parent_rect.end.x \
		and child_rect.end.y <= parent_rect.end.y


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
