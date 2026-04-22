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

	_expect(player_state_service != null, "page UI cutover resolves shared player state service")
	_expect(ui_manager != null, "page UI cutover exposes UIManager")
	_expect(loop_page.get("_camp_isometric_layer") == null, "page UI cutover does not mount the isometric play layer")
	_expect(not viewport_host.visible, "page UI cutover keeps the legacy viewport host inactive")
	_expect(ui_manager.get_active_page() == &"WorldMapPage", "page UI cutover starts on the world map page")
	_expect(ui_manager.get_active_route() == &"town", "page UI cutover starts on the town route")

	ui_manager.switch_to(&"travel_ui")
	await process_frame
	_expect(ui_manager.get_active_page() == &"TravelPage", "travel route resolves through UIManager")

	ui_manager.switch_to(&"grocery")
	await process_frame
	_expect(ui_manager.get_active_page() == &"LocationPage", "location routes resolve through UIManager")
	_expect(ui_manager.get_active_route() == &"grocery", "location route stays tracked in UIManager")

	ui_manager.switch_to(&"hobocraft")
	await process_frame
	_expect(ui_manager.get_active_page() == &"CraftingPage", "crafting routes resolve through UIManager")

	ui_manager.switch_to(&"inventory_ui")
	await process_frame
	_expect(ui_manager.get_active_page() == &"InventoryPage", "inventory overlay opens through the page router")
	_expect(inventory_overlay.visible, "inventory page controls the inventory overlay visibility")

	ui_manager.switch_to(&"passport_stats")
	await process_frame
	_expect(ui_manager.get_active_page() == &"PassportStatsPage", "passport overlay opens through the page router")
	_expect(passport_overlay.visible, "passport stats page controls the passport overlay visibility")

	ui_manager.switch_to(&"rest_camp")
	await process_frame
	_expect(ui_manager.get_active_page() == &"RestCampPage", "rest camp route resolves through UIManager")
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
