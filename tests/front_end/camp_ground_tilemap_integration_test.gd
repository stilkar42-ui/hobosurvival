extends SceneTree

const CampLayerScene := preload("res://scenes/front_end/camp_isometric_play_layer.tscn")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.size = Vector2i(1280, 720)
	get_root().add_child(root)

	var layer = CampLayerScene.instantiate()
	root.add_child(layer)
	call_deferred("_run_checks", layer)


func _run_checks(layer: Control) -> void:
	await process_frame
	await process_frame

	var world_view = layer.get_node("WorldView")
	var ground_tilemap = layer.get_node_or_null("GroundTileMap")
	_expect(world_view != null, "camp layer exposes a world view")
	_expect(world_view != null and bool(world_view.get("draw_ground_layer")), "world view owns the rebuilt 32x32 ground drawing")
	_expect(world_view != null and not bool(world_view.get("show_debug_footprints")), "debug footprint overlay stays off during normal play")
	var has_zoom := world_view != null and world_view.has_method("adjust_zoom")
	_expect(has_zoom, "world view exposes mouse-wheel zoom control")
	if has_zoom:
		_expect(float(world_view.get("view_zoom")) > 1.0, "camp starts zoomed in for the 32x32 tile scale")
	var object_textures: Dictionary = world_view.get("_object_textures")
	_expect(object_textures.is_empty(), "world view no longer loads runtime image textures for player or object art")
	_expect(not object_textures.has(&"tarp_shelter"), "inactive camp shelter texture is not loaded for the prototype foundation")
	_expect(not object_textures.has(&"crate"), "inactive crate texture is not loaded for the prototype foundation")
	_expect(world_view != null and world_view.has_method("_resolve_ground_tile_key"), "world view resolves 32x32 camp terrain tiles")
	_expect(
		StringName(world_view.call("_resolve_ground_tile_key", Vector2i(16, 16))) in [&"camp", &"path"],
		"camp center resolves to camp-worn 32x32 terrain"
	)
	_expect(ground_tilemap == null or not ground_tilemap.visible, "legacy 128x64 TileMap ground is hidden")
	if has_zoom:
		var zoom_before := float(world_view.get("view_zoom"))
		world_view.call("adjust_zoom", 1.0)
		_expect(float(world_view.get("view_zoom")) > zoom_before, "mouse-wheel zoom can move the camp camera closer")
		world_view.call("adjust_zoom", -1.0)
		_expect(float(world_view.get("view_zoom")) <= zoom_before + 0.01, "mouse-wheel zoom can back the camp camera away")

	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
