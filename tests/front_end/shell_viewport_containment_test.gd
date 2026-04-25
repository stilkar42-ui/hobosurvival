extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")

var _failed := false
var _baseline_strip_y := 0.0
var _baseline_strip_height := 0.0


func _init() -> void:
	var root = Window.new()
	root.name = "ShellContainmentRoot"
	root.size = Vector2i(1280, 720)
	get_root().add_child(root)

	var loop_page = FirstPlayableLoopPageScene.instantiate()
	root.add_child(loop_page)
	call_deferred("_run_checks", loop_page)


func _run_checks(loop_page: Control) -> void:
	await process_frame
	await process_frame

	var ui_manager = loop_page.get("_ui_manager")
	_expect(ui_manager != null, "shell containment resolves UIManager")
	if ui_manager == null:
		quit(1)
		return

	_assert_shell_contained(loop_page, "world map", true)

	for route_data in [
		{"page_id": &"location_page", "context": {"return_route": &"town", "route_id": &"jobs_board"}, "label": "town services"},
		{"page_id": &"grocery", "context": {"return_route": &"town"}, "label": "grocery"},
		{"page_id": &"medicine", "context": {"return_route": &"town"}, "label": "medicine store"},
		{"page_id": &"doctor_apothecary", "context": {"return_route": &"town"}, "label": "doctor/apothecary"},
		{"page_id": &"cooking", "context": {"return_route": &"camp"}, "label": "cooking"},
		{"page_id": &"crafting_page", "context": {"return_route": &"camp", "route_id": &"hobocraft"}, "label": "crafting"},
		{"page_id": &"rest_camp_page", "context": {"return_route": &"camp", "route_id": &"rest_camp"}, "label": "rest camp"},
		{"page_id": &"inventory_ui", "context": {"return_route": &"town"}, "label": "inventory"}
	]:
		ui_manager.open_page(route_data.page_id, route_data.context)
		await process_frame
		await process_frame
		_assert_shell_contained(loop_page, String(route_data.label), false)

	if _failed:
		quit(1)
		return
	quit()


func _assert_shell_contained(loop_page: Control, route_label: String, capture_baseline: bool) -> void:
	var strip = loop_page.find_child("PersistentConditionStrip", true, false) as Control
	var page_frame = loop_page.find_child("PageWindowFrame", true, false) as Control
	var viewport_rect := loop_page.get_viewport_rect()

	for control_name in ["Root", "SummaryPanel", "PersistentConditionStrip", "MainRow", "PageWindowFrame", "PageHost", "RightColumn"]:
		var control = loop_page.find_child(control_name, true, false) as Control
		_expect(control != null, "%s has %s" % [route_label, control_name])
		if control != null:
			_expect(_rect_inside(viewport_rect, control.get_global_rect()), "%s %s stays inside viewport" % [route_label, control_name])

	if strip != null and page_frame != null:
		var strip_rect := strip.get_global_rect()
		var page_rect := page_frame.get_global_rect()
		_expect(strip.is_visible_in_tree(), "%s persistent strip is visible" % route_label)
		_expect(not strip_rect.intersects(page_rect), "%s persistent strip does not overlap PageWindowFrame" % route_label)
		_expect(page_rect.position.y >= strip_rect.end.y, "%s PageWindowFrame begins below persistent strip" % route_label)
		if capture_baseline:
			_baseline_strip_y = strip_rect.position.y
			_baseline_strip_height = strip_rect.size.y
		else:
			_expect(absf(strip_rect.position.y - _baseline_strip_y) <= 2.0, "%s persistent strip y is stable" % route_label)
			_expect(absf(strip_rect.size.y - _baseline_strip_height) <= 2.0, "%s persistent strip height is stable" % route_label)


func _rect_inside(viewport_rect: Rect2, rect: Rect2) -> bool:
	return rect.position.x >= viewport_rect.position.x \
		and rect.position.y >= viewport_rect.position.y \
		and rect.end.x <= viewport_rect.end.x \
		and rect.end.y <= viewport_rect.end.y


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
