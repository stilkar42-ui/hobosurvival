extends SceneTree

const FirstPlayableLoopPageScene := preload("res://scenes/front_end/first_playable_loop_page.tscn")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.name = "CleanupRoot"
	root.size = Vector2i(1600, 900)
	get_root().add_child(root)
	var loop_page = FirstPlayableLoopPageScene.instantiate()
	root.add_child(loop_page)
	call_deferred("_run_checks", loop_page)


func _run_checks(loop_page: Control) -> void:
	await process_frame
	await process_frame

	_expect(loop_page.find_child("PageHost", true, false) != null, "runtime builds a dedicated page host instead of legacy page panels")
	_expect(loop_page.find_child("TownPage", true, false) == null, "legacy town page panel is no longer built by runtime")
	_expect(loop_page.find_child("JobsBoardPage", true, false) == null, "legacy jobs page panel is no longer built by runtime")
	_expect(loop_page.find_child("CampSubsystemNav", true, false) == null, "legacy camp subsystem nav is no longer built by runtime")
	_expect(not loop_page.has_method("_refresh_inventory_summary"), "active shell no longer owns inventory refresh logic")
	_expect(not loop_page.has_method("_refresh_hobocraft_recipes"), "active shell no longer owns crafting refresh logic")
	_expect(not loop_page.has_method("_refresh_cooking_panel"), "active shell no longer owns cooking refresh logic")
	_expect(not loop_page.has_method("_rebuild_job_board"), "active shell no longer owns jobs board rendering")
	_expect(not loop_page.has_method("_refresh_store_stock_sections"), "active shell no longer owns store rendering")
	_expect(not loop_page.has_method("_refresh_getting_ready_panel"), "active shell no longer owns getting-ready rendering")
	_expect(not loop_page.has_method("_refresh_page_navigation_buttons"), "active shell no longer owns page navigation rendering")
	_expect(not loop_page.has_method("_on_open_inventory_pressed"), "active shell no longer owns inventory open/close flow")

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
