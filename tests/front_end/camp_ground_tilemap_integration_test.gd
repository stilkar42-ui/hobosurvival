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

	var ground_tilemap = layer.get_node_or_null("GroundTileMap")
	_expect(ground_tilemap != null, "camp layer exposes a dedicated ground TileMap layer")
	_expect(ground_tilemap != null and ground_tilemap is TileMapLayer, "ground layer uses TileMapLayer")
	_expect(ground_tilemap != null and ground_tilemap.tile_set != null, "ground TileMap layer has a configured TileSet resource")
	_expect(ground_tilemap != null and ground_tilemap.get_used_cells().size() > 0, "ground TileMap layer paints camp terrain cells")

	var world_view = layer.get_node("WorldView")
	_expect(world_view != null and world_view.has_method("set_draw_ground_layer"), "world view can disable its custom ground drawing")
	_expect(world_view != null and not bool(world_view.get("draw_ground_layer")), "custom ground drawing is disabled when the TileMap ground layer is active")

	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
