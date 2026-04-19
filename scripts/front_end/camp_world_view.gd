class_name CampWorldView
extends Control

signal tile_clicked(grid_position: Vector2i)
signal object_clicked(object_id: StringName)
signal hovered_object_changed(object_id: StringName)

const TILE_WIDTH := 72.0
const TILE_HEIGHT := 36.0

var world_size := Vector2i(72, 72)
var world_objects: Array = []
var player_grid_position := Vector2i.ZERO
var player_render_position := Vector2.ZERO
var camera_render_position := Vector2.ZERO
var camp_anchor := Vector2i(36, 34)
var active_object_id: StringName = &""
var hovered_object_id: StringName = &""
var draw_ground_layer := true
var _occupied_tiles := {}
var _draw_sorted_objects: Array = []
var _interactable_hit_objects: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


func set_world_size(new_world_size: Vector2i) -> void:
	if world_size == new_world_size:
		return
	world_size = new_world_size
	queue_redraw()


func set_world_objects(new_world_objects: Array) -> void:
	world_objects = new_world_objects
	_rebuild_spatial_cache()
	queue_redraw()


func set_player_grid_position(new_player_grid_position: Vector2i) -> void:
	if player_grid_position == new_player_grid_position:
		return
	player_grid_position = new_player_grid_position
	queue_redraw()


func set_player_render_position(new_player_render_position: Vector2) -> void:
	if player_render_position.is_equal_approx(new_player_render_position):
		return
	player_render_position = new_player_render_position
	queue_redraw()


func set_camera_render_position(new_camera_render_position: Vector2) -> void:
	if camera_render_position.is_equal_approx(new_camera_render_position):
		return
	camera_render_position = new_camera_render_position
	queue_redraw()


func set_camp_anchor(new_camp_anchor: Vector2i) -> void:
	if camp_anchor == new_camp_anchor:
		return
	camp_anchor = new_camp_anchor
	queue_redraw()


func set_active_object_id(new_active_object_id: StringName) -> void:
	if active_object_id == new_active_object_id:
		return
	active_object_id = new_active_object_id
	queue_redraw()


func set_draw_ground_layer(enabled: bool) -> void:
	if draw_ground_layer == enabled:
		return
	draw_ground_layer = enabled
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var next_hovered_object_id = _get_object_id_at_point(event.position)
		if hovered_object_id != next_hovered_object_id:
			hovered_object_id = next_hovered_object_id
			hovered_object_changed.emit(hovered_object_id)
			queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var object_id = _get_object_id_at_point(event.position)
		if object_id != &"":
			object_clicked.emit(object_id)
			accept_event()
			return
		var tile = _get_tile_at_point(event.position)
		if tile.x >= 0 and tile.y >= 0:
			tile_clicked.emit(tile)
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1220"))
	if draw_ground_layer:
		_draw_ground()
	_draw_world_objects()
	_draw_player()
	_draw_screen_fx()


func _draw_ground() -> void:
	for y in range(world_size.y):
		for x in range(world_size.x):
			var tile = Vector2i(x, y)
			var center = _world_to_screen(Vector2(tile))
			if center.x < -TILE_WIDTH or center.x > size.x + TILE_WIDTH:
				continue
			if center.y < -TILE_HEIGHT * 3.0 or center.y > size.y + TILE_HEIGHT * 3.0:
				continue
			_draw_ground_tile(tile, center)


func _draw_ground_tile(tile: Vector2i, center: Vector2) -> void:
	var fill = _get_ground_color(tile)
	var top = center + Vector2(0.0, -TILE_HEIGHT * 0.5)
	var right = center + Vector2(TILE_WIDTH * 0.5, 0.0)
	var bottom = center + Vector2(0.0, TILE_HEIGHT * 0.5)
	var left = center + Vector2(-TILE_WIDTH * 0.5, 0.0)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), fill)
	draw_colored_polygon(PackedVector2Array([center, right, bottom, left]), fill.darkened(0.08))
	_draw_ground_clutter(tile, center)


func _draw_ground_clutter(tile: Vector2i, center: Vector2) -> void:
	var occupied = _tile_is_occupied(tile)
	var noise = _hash01(tile.x, tile.y)
	var distance_from_camp = Vector2(tile - camp_anchor).length()
	if not occupied and distance_from_camp > 8.5 and noise > 0.64:
		var grass_color = Color("314632").lightened((_hash01(tile.x + 9, tile.y + 17) - 0.5) * 0.25)
		for index in range(3):
			var blade_offset = Vector2(-8.0 + index * 7.0, 6.0 - float(index % 2) * 4.0)
			draw_line(center + blade_offset, center + blade_offset + Vector2(0.0, -7.0 - float(index % 2) * 2.0), grass_color, 1.5)
	elif not occupied and distance_from_camp < 8.5 and noise > 0.78:
		draw_circle(center + Vector2((_hash01(tile.y, tile.x) - 0.5) * 8.0, 7.0), 2.0 + _hash01(tile.x + 3, tile.y + 5) * 2.5, Color("625443"))


func _draw_world_objects() -> void:
	for world_object in _draw_sorted_objects:
		if world_object == null:
			continue
		if not _is_object_visible(world_object):
			continue
		match String(world_object.type):
			"campfire":
				_draw_campfire(world_object)
			"woodpile":
				_draw_woodpile(world_object)
			"bedroll":
				_draw_bedroll(world_object)
			"stash":
				_draw_stash(world_object)
			"tool_area":
				_draw_tool_area(world_object)
			"trail_sign":
				_draw_trail_sign(world_object)
			"tree":
				_draw_tree(world_object)
			"tarp_shelter":
				_draw_tarp_shelter(world_object)
			"log":
				_draw_log(world_object)
			"stump":
				_draw_stump(world_object)
			"crate":
				_draw_crate(world_object)
			"wash_line":
				_draw_wash_line(world_object)
			_:
				_draw_generic_object(world_object)


func _draw_player() -> void:
	var center = _world_to_screen(player_render_position)
	_draw_shadow(center + Vector2(0.0, 16.0), 22.0, 10.0, 0.28)
	draw_rect(Rect2(center + Vector2(-8.0, -20.0), Vector2(16.0, 28.0)), Color("4f5e72"))
	draw_rect(Rect2(center + Vector2(-10.0, -14.0), Vector2(6.0, 18.0)), Color("8a6e4c"))
	draw_rect(Rect2(center + Vector2(4.0, -12.0), Vector2(9.0, 14.0)), Color("8a6e4c"))
	draw_rect(Rect2(center + Vector2(-7.0, 8.0), Vector2(4.0, 15.0)), Color("3f3026"))
	draw_rect(Rect2(center + Vector2(3.0, 8.0), Vector2(4.0, 15.0)), Color("3f3026"))
	draw_circle(center + Vector2(0.0, -27.0), 7.0, Color("c8a07f"))
	draw_rect(Rect2(center + Vector2(-8.0, -35.0), Vector2(16.0, 4.0)), Color("5f4d36"))


func _draw_campfire(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 18.0), 44.0, 18.0, 0.3)
	for ring_index in range(10):
		var angle = TAU * float(ring_index) / 10.0
		draw_circle(center + Vector2(cos(angle) * 24.0, sin(angle) * 10.0 + 10.0), 6.0, Color("7a6f61"))
	draw_rect(Rect2(center + Vector2(-2.0, -38.0), Vector2(4.0, 36.0)), Color("5d452e"))
	draw_line(center + Vector2(-24.0, -12.0), center + Vector2(24.0, -12.0), Color("684c33"), 4.0)
	draw_line(center + Vector2(-18.0, -12.0), center + Vector2(-8.0, 10.0), Color("684c33"), 3.0)
	draw_line(center + Vector2(18.0, -12.0), center + Vector2(8.0, 10.0), Color("684c33"), 3.0)
	draw_rect(Rect2(center + Vector2(-10.0, -20.0), Vector2(20.0, 12.0)), Color("2c313a"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -16.0),
		center + Vector2(15.0, 8.0),
		center + Vector2(0.0, 18.0),
		center + Vector2(-15.0, 8.0)
	]), Color("f18a2a"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -10.0),
		center + Vector2(9.0, 6.0),
		center + Vector2(0.0, 12.0),
		center + Vector2(-9.0, 6.0)
	]), Color("f7d57a"))
	draw_circle(center, 62.0, Color(1.0, 0.48, 0.14, 0.06))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-52.0, -44.0), Vector2(104.0, 82.0)))


func _draw_woodpile(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 14.0), 34.0, 12.0, 0.24)
	for index in range(4):
		var offset = Vector2(-20.0 + float(index) * 10.0, -6.0 + float(index % 2) * 4.0)
		draw_rect(Rect2(center + offset, Vector2(24.0, 7.0)), Color("7a5738"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-26.0, -16.0), Vector2(52.0, 34.0)))


func _draw_bedroll(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position) + Vector2(0.35, 0.2))
	_draw_shadow(center + Vector2(0.0, 16.0), 42.0, 12.0, 0.22)
	draw_rect(Rect2(center + Vector2(-34.0, -8.0), Vector2(50.0, 16.0)), Color("71614e"))
	draw_rect(Rect2(center + Vector2(-38.0, -12.0), Vector2(18.0, 20.0)), Color("5a7088"))
	draw_rect(Rect2(center + Vector2(12.0, -8.0), Vector2(10.0, 13.0)), Color("9a8566"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-42.0, -18.0), Vector2(66.0, 34.0)))


func _draw_stash(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position)) + Vector2(0.0, -10.0)
	_draw_shadow(center + Vector2(0.0, 18.0), 28.0, 10.0, 0.22)
	draw_rect(Rect2(center + Vector2(-20.0, -8.0), Vector2(40.0, 24.0)), Color("4f6138"))
	draw_rect(Rect2(center + Vector2(-14.0, -16.0), Vector2(28.0, 10.0)), Color("6d8446"))
	draw_rect(Rect2(center + Vector2(-4.0, -3.0), Vector2(8.0, 5.0)), Color("d7c489"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-24.0, -22.0), Vector2(48.0, 42.0)))


func _draw_tool_area(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 18.0), 40.0, 14.0, 0.22)
	draw_rect(Rect2(center + Vector2(-18.0, -6.0), Vector2(36.0, 16.0)), Color("6d5539"))
	draw_rect(Rect2(center + Vector2(-4.0, -28.0), Vector2(8.0, 24.0)), Color("8a7760"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-2.0, -32.0),
		center + Vector2(18.0, -16.0),
		center + Vector2(12.0, -8.0),
		center + Vector2(-8.0, -24.0)
	]), Color("8da0a8"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-28.0, -34.0), Vector2(56.0, 52.0)))


func _draw_trail_sign(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 18.0), 20.0, 8.0, 0.2)
	draw_rect(Rect2(center + Vector2(-3.0, -22.0), Vector2(6.0, 30.0)), Color("64492f"))
	draw_rect(Rect2(center + Vector2(-22.0, -32.0), Vector2(44.0, 14.0)), Color("8e7351"))
	draw_rect(Rect2(center + Vector2(-10.0, -29.0), Vector2(18.0, 4.0)), Color("5c4a32"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-24.0, -36.0), Vector2(48.0, 48.0)))


func _draw_tree(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position)) + Vector2(0.0, -26.0)
	_draw_shadow(center + Vector2(0.0, 42.0), 38.0, 14.0, 0.22)
	draw_rect(Rect2(center + Vector2(-5.0, 6.0), Vector2(10.0, 42.0)), Color("4f3c26"))
	draw_circle(center + Vector2(0.0, -10.0), 24.0, Color("29412a"))
	draw_circle(center + Vector2(-16.0, -2.0), 18.0, Color("325235"))
	draw_circle(center + Vector2(15.0, 0.0), 18.0, Color("325235"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-32.0, -34.0), Vector2(64.0, 88.0)))


func _draw_tarp_shelter(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position) + Vector2(0.5, 0.3))
	_draw_shadow(center + Vector2(0.0, 22.0), 72.0, 18.0, 0.22)
	draw_line(center + Vector2(-34.0, -6.0), center + Vector2(-34.0, 24.0), Color("654a31"), 4.0)
	draw_line(center + Vector2(30.0, -8.0), center + Vector2(30.0, 20.0), Color("654a31"), 4.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-42.0, -12.0),
		center + Vector2(32.0, -22.0),
		center + Vector2(46.0, 4.0),
		center + Vector2(-28.0, 12.0)
	]), Color("5d6f77"))
	draw_rect(Rect2(center + Vector2(-24.0, 0.0), Vector2(44.0, 18.0)), Color("43382d"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-50.0, -28.0), Vector2(102.0, 58.0)))


func _draw_log(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 12.0), 34.0, 10.0, 0.18)
	draw_rect(Rect2(center + Vector2(-26.0, -4.0), Vector2(52.0, 10.0)), Color("7f5d3c"))
	draw_circle(center + Vector2(-26.0, 1.0), 5.0, Color("98714c"))
	draw_circle(center + Vector2(26.0, 1.0), 5.0, Color("98714c"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-30.0, -10.0), Vector2(60.0, 24.0)))


func _draw_stump(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 10.0), 22.0, 8.0, 0.16)
	draw_rect(Rect2(center + Vector2(-8.0, -8.0), Vector2(16.0, 16.0)), Color("755438"))
	draw_circle(center + Vector2(0.0, -8.0), 10.0, Color("8c6a47"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-14.0, -18.0), Vector2(28.0, 30.0)))


func _draw_crate(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 14.0), 24.0, 10.0, 0.16)
	draw_rect(Rect2(center + Vector2(-14.0, -8.0), Vector2(28.0, 20.0)), Color("77563a"))
	draw_line(center + Vector2(-10.0, -6.0), center + Vector2(-10.0, 10.0), Color("5b4128"), 2.0)
	draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 10.0), Color("5b4128"), 2.0)
	_draw_object_highlight(world_object, Rect2(center + Vector2(-18.0, -14.0), Vector2(36.0, 30.0)))


func _draw_wash_line(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	_draw_shadow(center + Vector2(0.0, 18.0), 42.0, 10.0, 0.15)
	draw_line(center + Vector2(-28.0, -18.0), center + Vector2(-28.0, 18.0), Color("674a32"), 3.0)
	draw_line(center + Vector2(28.0, -14.0), center + Vector2(28.0, 20.0), Color("674a32"), 3.0)
	draw_line(center + Vector2(-26.0, -12.0), center + Vector2(26.0, -10.0), Color("7b6a4c"), 2.0)
	draw_rect(Rect2(center + Vector2(-6.0, -8.0), Vector2(14.0, 24.0)), Color("8f8061"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-34.0, -24.0), Vector2(68.0, 48.0)))


func _draw_generic_object(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	draw_rect(Rect2(center + Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), Color("7c6a55"))
	_draw_object_highlight(world_object, Rect2(center + Vector2(-16.0, -16.0), Vector2(32.0, 32.0)))


func _draw_object_highlight(world_object, rect: Rect2) -> void:
	if world_object.id != active_object_id and world_object.id != hovered_object_id:
		return
	var color = Color("f4d78a") if world_object.id == active_object_id else Color("a7c6d9")
	draw_rect(rect, color, false, 2.0)


func _draw_shadow(center: Vector2, width: float, height: float, alpha: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -height * 0.5),
		center + Vector2(width * 0.5, 0.0),
		center + Vector2(0.0, height * 0.5),
		center + Vector2(-width * 0.5, 0.0)
	]), Color(0, 0, 0, alpha))


func _draw_screen_fx() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.12))
	draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5, Color(1.0, 0.62, 0.18, 0.02))
	var top_fog = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size.x, 0.0),
		Vector2(size.x, size.y * 0.28),
		Vector2(0.0, size.y * 0.22)
	])
	draw_colored_polygon(top_fog, Color(0.11, 0.16, 0.27, 0.35))


func _get_ground_color(tile: Vector2i) -> Color:
	var distance_from_camp = Vector2(tile - camp_anchor).length()
	var edge_noise = (_hash01(tile.x, tile.y) - 0.5) * 2.4
	var clearing_radius = 8.0 + edge_noise
	var path_distance = _distance_to_path(Vector2(tile), Vector2(camp_anchor), Vector2(camp_anchor + Vector2i(11, -10)))
	var base_forest = Color("223426").lightened((_hash01(tile.x + 13, tile.y + 7) - 0.5) * 0.14)
	var base_clearing = Color("5a4738").lightened((_hash01(tile.x + 2, tile.y + 19) - 0.5) * 0.16)
	if path_distance < 1.2 and distance_from_camp > 4.0:
		return base_clearing.lightened(0.05)
	if distance_from_camp <= clearing_radius:
		return base_clearing
	return base_forest


func _world_to_screen(grid_position: Vector2) -> Vector2:
	var delta = grid_position - camera_render_position
	return size * 0.5 + Vector2(
		(delta.x - delta.y) * TILE_WIDTH * 0.5,
		(delta.x + delta.y) * TILE_HEIGHT * 0.5
	)


func get_screen_position_for_grid(grid_position: Vector2) -> Vector2:
	return _world_to_screen(grid_position)


func _screen_to_world(point: Vector2) -> Vector2:
	var offset = point - size * 0.5
	var dx = offset.x / (TILE_WIDTH * 0.5)
	var dy = offset.y / (TILE_HEIGHT * 0.5)
	return Vector2(
		camera_render_position.x + (dy + dx) * 0.5,
		camera_render_position.y + (dy - dx) * 0.5
	)


func _get_tile_at_point(point: Vector2) -> Vector2i:
	var estimate = _screen_to_world(point)
	var base_tile = Vector2i(floori(estimate.x), floori(estimate.y))
	for y in range(base_tile.y - 2, base_tile.y + 3):
		for x in range(base_tile.x - 2, base_tile.x + 3):
			var tile = Vector2i(x, y)
			if not Rect2i(Vector2i.ZERO, world_size).has_point(tile):
				continue
			if Geometry2D.is_point_in_polygon(point, _get_tile_polygon(tile)):
				return tile
	var rounded = Vector2i(roundi(estimate.x), roundi(estimate.y))
	return rounded if Rect2i(Vector2i.ZERO, world_size).has_point(rounded) else Vector2i(-1, -1)


func _get_object_id_at_point(point: Vector2) -> StringName:
	for world_object in _interactable_hit_objects:
		if world_object == null:
			continue
		if _get_object_hit_rect(world_object).has_point(point):
			return world_object.id
	return &""


func _get_tile_polygon(tile: Vector2i) -> PackedVector2Array:
	var center = _world_to_screen(Vector2(tile))
	return PackedVector2Array([
		center + Vector2(0.0, -TILE_HEIGHT * 0.5),
		center + Vector2(TILE_WIDTH * 0.5, 0.0),
		center + Vector2(0.0, TILE_HEIGHT * 0.5),
		center + Vector2(-TILE_WIDTH * 0.5, 0.0)
	])


func _get_object_hit_rect(world_object) -> Rect2:
	var center = _world_to_screen(Vector2(world_object.position))
	match String(world_object.type):
		"campfire":
			return Rect2(center + Vector2(-52.0, -44.0), Vector2(104.0, 82.0))
		"woodpile":
			return Rect2(center + Vector2(-26.0, -16.0), Vector2(52.0, 34.0))
		"bedroll":
			return Rect2(center + Vector2(-42.0, -18.0), Vector2(66.0, 34.0))
		"stash":
			return Rect2(center + Vector2(-24.0, -32.0), Vector2(48.0, 52.0))
		"tool_area":
			return Rect2(center + Vector2(-28.0, -34.0), Vector2(56.0, 52.0))
		"trail_sign":
			return Rect2(center + Vector2(-24.0, -36.0), Vector2(48.0, 48.0))
		"tree":
			return Rect2(center + Vector2(-32.0, -60.0), Vector2(64.0, 114.0))
		_:
			return Rect2(center + Vector2(-18.0, -18.0), Vector2(36.0, 36.0))


func _get_object_sort_y(world_object) -> int:
	if world_object == null:
		return 0
	var bottom_y = world_object.position.y + max(world_object.size_tiles.y, 1)
	return bottom_y


func _is_object_visible(world_object) -> bool:
	return _expanded_view_rect(96.0).intersects(_get_object_hit_rect(world_object))


func _tile_is_occupied(tile: Vector2i) -> bool:
	return _occupied_tiles.has(_tile_key(tile))


func _expanded_view_rect(margin: float) -> Rect2:
	return Rect2(Vector2(-margin, -margin), size + Vector2.ONE * margin * 2.0)


func has_cached_occupied_tile(tile: Vector2i) -> bool:
	return _occupied_tiles.has(_tile_key(tile))


func get_cached_interactable_objects() -> Array:
	return _interactable_hit_objects


func _rebuild_spatial_cache() -> void:
	_occupied_tiles.clear()
	_draw_sorted_objects = world_objects.duplicate()
	_draw_sorted_objects.sort_custom(func(a, b):
		var a_y = _get_object_sort_y(a)
		var b_y = _get_object_sort_y(b)
		if a_y == b_y:
			return int(a.position.x) < int(b.position.x)
		return a_y < b_y
	)
	_interactable_hit_objects = []
	for index in range(_draw_sorted_objects.size() - 1, -1, -1):
		var world_object = _draw_sorted_objects[index]
		if world_object == null:
			continue
		for occupied_tile in world_object.get_occupied_tiles():
			_occupied_tiles[_tile_key(occupied_tile)] = true
		if world_object.is_interactable:
			_interactable_hit_objects.append(world_object)


func _tile_key(tile: Vector2i) -> String:
	return "%d:%d" % [tile.x, tile.y]


func _hash01(x: int, y: int) -> float:
	var value = int((x * 73856093) ^ (y * 19349663))
	value = abs(value % 1000)
	return float(value) / 999.0


func _distance_to_path(point: Vector2, path_start: Vector2, path_end: Vector2) -> float:
	var segment = path_end - path_start
	if segment.length_squared() <= 0.001:
		return point.distance_to(path_start)
	var progress = clampf((point - path_start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(path_start + segment * progress)
