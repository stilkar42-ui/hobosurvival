extends SceneTree

const FirstPlayableLoopNavigationControllerScript := preload("res://scripts/front_end/first_playable_loop_navigation_controller.gd")

var _failed := false


func _init() -> void:
	var controller = FirstPlayableLoopNavigationControllerScript.new()
	var town_panel = Control.new()
	var camp_panel = Control.new()
	var getting_ready_panel = Control.new()
	var page_nav_row = Control.new()
	var camp_nav_panel = Control.new()

	controller.configure(
		{
			&"town": town_panel,
			&"camp": camp_panel,
			&"getting_ready": getting_ready_panel
		},
		page_nav_row,
		camp_nav_panel
	)

	controller.set_active_page(&"town")
	_expect(town_panel.visible, "town page is visible when selected")
	_expect(not camp_panel.visible, "camp page is hidden when town is active")

	controller.set_active_page(&"camp")
	_expect(camp_panel.visible, "camp page is visible when selected")
	_expect(not town_panel.visible, "town page is hidden when camp is active")

	controller.sync_active_page_for_location(&"town", &"town", &"camp", &"town", &"camp", [&"town"], [&"camp", &"getting_ready"])
	_expect(controller.get_active_page() == &"town", "camp-only pages collapse back to town while in town")

	controller.set_active_page(&"camp")
	controller.refresh_navigation_visibility(&"camp", &"camp", &"camp", [&"getting_ready"])
	_expect(not page_nav_row.visible, "top page navigation hides for the camp world page")

	controller.set_active_page(&"getting_ready")
	controller.refresh_navigation_visibility(&"camp", &"camp", &"camp", [&"getting_ready"])
	_expect(camp_nav_panel.visible, "camp subsystem navigation shows for camp interior pages")

	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
