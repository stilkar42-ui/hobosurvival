class_name CampWorldView
extends Control

signal tile_clicked(grid_position: Vector2i)
signal object_clicked(object_id: StringName)
signal hovered_object_changed(object_id: StringName)

const TILE_WIDTH := 32.0
const TILE_HEIGHT := 16.0
const TILE_TEXTURE_SIZE := Vector2(32.0, 32.0)
const GAME_ASSET_ROOT := "res://assets/game/"
const CAMP_TILE_ROOT := GAME_ASSET_ROOT + "camp/tiles/"
const TOWN_TILE_ROOT := GAME_ASSET_ROOT + "town/tiles/"
const TOWN_OBJECT_ROOT := GAME_ASSET_ROOT + "town/objects/"
const CHARACTER_ROOT := GAME_ASSET_ROOT + "characters/"
const DEFAULT_WORLD_ART_ZOOM := 1.65
const SCENE_PLATE_PATHS := {
	&"camp": CAMP_TILE_ROOT + "camp_scene_composed.png",
	&"town": TOWN_TILE_ROOT + "town_scene_composed.png",
}
const SCENE_PLATE_LAYOUTS := {
	&"camp": {
		"anchor_pixel": Vector2(767.6, 446.3),
		"scale": 1.0
	},
	&"town": {
		"anchor_pixel": Vector2(724.0, 586.0),
		"scale": 1.0
	},
}
const SCENE_OBJECT_LAYOUTS := {
	&"camp": {
		&"campfire": Rect2(653.0, 340.0, 230.0, 220.0),
		&"woodpile": Rect2(286.0, 262.0, 315.0, 222.0),
		&"bedroll": Rect2(595.0, 210.0, 260.0, 160.0),
		&"tool_area": Rect2(854.0, 233.0, 288.0, 205.0),
		&"wash_line": Rect2(1034.0, 399.0, 336.0, 292.0),
		&"trail_sign": Rect2(252.0, 426.0, 180.0, 189.0),
		&"stash": Rect2(675.0, 557.0, 280.0, 210.0),
	},
	&"town": {
		&"town_jobs_board": Rect2(170.0, 338.0, 180.0, 212.0),
		&"town_church": Rect2(316.0, 74.0, 352.0, 420.0),
		&"town_grocery": Rect2(809.0, 205.0, 274.0, 242.0),
		&"town_hardware": Rect2(995.0, 238.0, 338.0, 317.0),
		&"town_camp_road": Rect2(1256.0, 462.0, 186.0, 182.0),
	},
}
const MIN_VIEW_ZOOM := 1.0
const MAX_VIEW_ZOOM := 2.6
const VIEW_ZOOM_STEP := 0.15
const GROUND_TILE_PATHS := {
	&"path": CAMP_TILE_ROOT + "path.png",
	&"camp": CAMP_TILE_ROOT + "camp.png",
	&"grass": CAMP_TILE_ROOT + "grass.png",
}
const TOWN_GROUND_TILE_PATHS := {
	&"path": TOWN_TILE_ROOT + "path.png",
	&"grass": TOWN_TILE_ROOT + "grass.png",
	&"packed_dirt": TOWN_TILE_ROOT + "packed_dirt.png",
}
const OBJECT_TILE_PATHS := {
	&"log": CAMP_TILE_ROOT + "woodpile.png",
	&"player_front_01": CHARACTER_ROOT + "hobo_front_01.png",
	&"player_front_02": CHARACTER_ROOT + "hobo_front_02.png",
	&"player_front_03": CHARACTER_ROOT + "hobo_front_03.png",
	&"player_front_04": CHARACTER_ROOT + "hobo_front_04.png",
	&"player_front_05": CHARACTER_ROOT + "hobo_front_05.png",
	&"player_back_01": CHARACTER_ROOT + "hobo_back_01.png",
	&"player_back_02": CHARACTER_ROOT + "hobo_back_02.png",
	&"player_back_03": CHARACTER_ROOT + "hobo_back_03.png",
	&"player_back_04": CHARACTER_ROOT + "hobo_back_04.png",
	&"player_back_05": CHARACTER_ROOT + "hobo_back_05.png",
	&"player_side_01": CHARACTER_ROOT + "hobo_side_01.png",
	&"player_side_02": CHARACTER_ROOT + "hobo_side_02.png",
	&"player_side_03": CHARACTER_ROOT + "hobo_side_03.png",
	&"player_side_04": CHARACTER_ROOT + "hobo_side_04.png",
	&"player_side_05": CHARACTER_ROOT + "hobo_side_05.png",
	&"campfire": CAMP_TILE_ROOT + "campfire.png",
	&"woodpile": CAMP_TILE_ROOT + "woodpile.png",
	&"bedroll": CAMP_TILE_ROOT + "bedroll.png",
	&"tool_area": CAMP_TILE_ROOT + "tool_area.png",
	&"stash": CAMP_TILE_ROOT + "sack.png",
	&"camp_exit_sign": CAMP_TILE_ROOT + "camp_exit_sign.png",
	&"wash_line": CAMP_TILE_ROOT + "wash_line.png",
	&"town_jobs_board": TOWN_OBJECT_ROOT + "jobs_board.png",
	&"town_road_sign": TOWN_OBJECT_ROOT + "camp_road_sign.png",
	&"town_church_building": TOWN_OBJECT_ROOT + "remittance_office.png",
	&"town_grocery_building": TOWN_OBJECT_ROOT + "provisions_store.png",
	&"town_hardware_building": TOWN_OBJECT_ROOT + "hardware_store.png",
}
const PLAYER_FRONT_FRAMES := [&"player_front_01", &"player_front_02", &"player_front_03", &"player_front_04", &"player_front_05"]
const PLAYER_BACK_FRAMES := [&"player_back_01", &"player_back_02", &"player_back_03", &"player_back_04", &"player_back_05"]
const PLAYER_SIDE_FRAMES := [&"player_side_01", &"player_side_02", &"player_side_03", &"player_side_04", &"player_side_05"]

var world_size := Vector2i(32, 32)
var world_objects: Array = []
var player_grid_position := Vector2i.ZERO
var player_render_position := Vector2.ZERO
var camera_render_position := Vector2.ZERO
var camp_anchor := Vector2i(16, 16)
var terrain_mode: StringName = &"camp"
var active_object_id: StringName = &""
var hovered_object_id: StringName = &""
var draw_ground_layer := true
@export var show_debug_footprints := false
var view_zoom := 1.65
var _player_facing: StringName = &"front"
var _player_is_moving := false
var _player_side_sign := 1.0
var _occupied_tiles := {}
var _draw_sorted_objects: Array = []
var _interactable_hit_objects: Array = []
var _ground_textures := {}
var _town_ground_textures := {}
var _object_textures := {}
var _scene_plate_textures := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_load_ground_textures()


func _load_ground_textures() -> void:
	_ground_textures = _load_texture_map(GROUND_TILE_PATHS)
	_town_ground_textures = _load_texture_map(TOWN_GROUND_TILE_PATHS)
	_object_textures = _load_texture_map(OBJECT_TILE_PATHS)
	_scene_plate_textures = _load_texture_map(SCENE_PLATE_PATHS)


func _load_texture_map(path_map: Dictionary) -> Dictionary:
	var textures := {}
	for key in path_map.keys():
		var texture_path = String(path_map[key])
		if not ResourceLoader.exists(texture_path):
			continue
		var texture = load(texture_path)
		if texture is Texture2D:
			textures[key] = texture
	return textures


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
		_player_is_moving = false
		return
	_update_player_facing(new_player_render_position - player_render_position)
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


func set_terrain_mode(new_terrain_mode: StringName) -> void:
	if terrain_mode == new_terrain_mode:
		return
	terrain_mode = new_terrain_mode
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


func set_zoom(new_zoom: float) -> void:
	var clamped_zoom := clampf(new_zoom, MIN_VIEW_ZOOM, MAX_VIEW_ZOOM)
	if is_equal_approx(view_zoom, clamped_zoom):
		return
	view_zoom = clamped_zoom
	queue_redraw()


func adjust_zoom(direction: float) -> void:
	set_zoom(view_zoom + signf(direction) * VIEW_ZOOM_STEP)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var next_hovered_object_id = _get_object_id_at_point(event.position)
		if hovered_object_id != next_hovered_object_id:
			hovered_object_id = next_hovered_object_id
			hovered_object_changed.emit(hovered_object_id)
			queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_zoom(1.0)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_zoom(-1.0)
			accept_event()
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
	if draw_ground_layer:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0b1220"))
		_draw_ground()
	_draw_world_objects()
	_draw_debug_footprints()
	_draw_player()
	_draw_screen_fx()


func _draw_ground() -> void:
	if _has_scene_composition():
		_draw_scene_backplate()
		return
	for y in range(world_size.y):
		for x in range(world_size.x):
			var tile = Vector2i(x, y)
			var center = _world_to_screen(Vector2(tile))
			if center.x < -_zf(TILE_WIDTH) or center.x > size.x + _zf(TILE_WIDTH):
				continue
			if center.y < -_zf(TILE_HEIGHT) * 3.0 or center.y > size.y + _zf(TILE_HEIGHT) * 3.0:
				continue
			_draw_ground_tile(tile, center)


func _draw_ground_tile(tile: Vector2i, center: Vector2) -> void:
	var texture = _get_ground_texture(tile)
	if texture == null:
		_draw_fallback_ground_tile(tile, center)
		return
	_draw_fallback_ground_tile(tile, center)
	draw_texture_rect(texture, _scaled_rect(center, Vector2(-16.0, -16.0), TILE_TEXTURE_SIZE), false, Color(1.0, 1.0, 1.0, 0.56))


func _draw_scene_backplate() -> void:
	var rect = _get_scene_plate_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var texture: Texture2D = _scene_plate_textures.get(terrain_mode, null)
	if texture == null:
		return
	draw_texture_rect(texture, rect, false)


func _has_scene_composition() -> bool:
	return _scene_plate_textures.has(terrain_mode)


func _get_scene_plate_rect() -> Rect2:
	var texture: Texture2D = _scene_plate_textures.get(terrain_mode, null)
	if texture == null:
		return Rect2()
	var layout: Dictionary = SCENE_PLATE_LAYOUTS.get(terrain_mode, {})
	var texture_size = Vector2(texture.get_size())
	var anchor_pixel: Vector2 = layout.get("anchor_pixel", texture_size * 0.5)
	var base_scale := float(layout.get("scale", 1.0))
	var art_scale = (view_zoom / DEFAULT_WORLD_ART_ZOOM) * base_scale
	var draw_size = texture_size * art_scale
	var anchor_screen = _world_to_screen(Vector2(camp_anchor))
	return Rect2(anchor_screen - anchor_pixel * art_scale, draw_size)


func _get_scene_object_rect(world_object) -> Rect2:
	if not _has_scene_composition():
		return Rect2()
	var layout_map: Dictionary = SCENE_OBJECT_LAYOUTS.get(terrain_mode, {})
	if layout_map.is_empty():
		return Rect2()
	var object_rect: Rect2 = layout_map.get(world_object.id, layout_map.get(StringName(world_object.type), Rect2()))
	if object_rect.size.x <= 0.0 or object_rect.size.y <= 0.0:
		return Rect2()
	var scene_rect = _get_scene_plate_rect()
	var scale_x = scene_rect.size.x / 1536.0
	var scale_y = scene_rect.size.y / 1024.0
	return Rect2(
		scene_rect.position + Vector2(object_rect.position.x * scale_x, object_rect.position.y * scale_y),
		Vector2(object_rect.size.x * scale_x, object_rect.size.y * scale_y)
	)


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


func _draw_fallback_ground_tile(tile: Vector2i, center: Vector2) -> void:
	var fill = _get_ground_color(tile)
	var top = center + Vector2(0.0, -_zf(TILE_HEIGHT) * 0.5)
	var right = center + Vector2(_zf(TILE_WIDTH) * 0.5, 0.0)
	var bottom = center + Vector2(0.0, _zf(TILE_HEIGHT) * 0.5)
	var left = center + Vector2(-_zf(TILE_WIDTH) * 0.5, 0.0)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), fill)
	draw_colored_polygon(PackedVector2Array([center, right, bottom, left]), fill.darkened(0.08))


func _get_ground_texture(tile: Vector2i) -> Texture2D:
	var tile_key := _resolve_ground_tile_key(tile)
	if terrain_mode == &"town":
		return _town_ground_textures.get(tile_key, null)
	return _ground_textures.get(tile_key, null)


func _resolve_ground_tile_key(tile: Vector2i) -> StringName:
	if terrain_mode == &"town":
		return _resolve_town_ground_tile_key(tile)
	var distance_from_camp = Vector2(tile - camp_anchor).length()
	var path_distance = _distance_to_path(Vector2(tile), Vector2(camp_anchor), Vector2(camp_anchor + Vector2i(8, -7)))
	if tile.x < 2 or tile.y < 2 or tile.x > world_size.x - 3 or tile.y > world_size.y - 3:
		return &"grass"
	if path_distance < 1.2 and distance_from_camp > 3.0:
		return &"path"
	if distance_from_camp <= 10.5:
		return &"camp"
	return &"grass"


func _resolve_town_ground_tile_key(tile: Vector2i) -> StringName:
	var main_street_y := camp_anchor.y + 3
	var cross_street_x := camp_anchor.x - 6
	var depot_street_x := camp_anchor.x + 10
	if tile.x < 2 or tile.y < 2 or tile.x > world_size.x - 3 or tile.y > world_size.y - 3:
		return &"grass"
	if absi(tile.y - main_street_y) <= 2:
		return &"path"
	if absi(tile.x - cross_street_x) <= 1 and tile.y > 6 and tile.y < world_size.y - 5:
		return &"path"
	if absi(tile.x - depot_street_x) <= 1 and tile.y > 8 and tile.y < world_size.y - 7:
		return &"path"
	if tile.y < main_street_y - 4 and tile.x > 5 and tile.x < world_size.x - 6:
		return &"packed_dirt"
	return &"grass"


func _draw_world_objects() -> void:
	for world_object in _draw_sorted_objects:
		if world_object == null:
			continue
		if not _is_object_visible(world_object):
			continue
		if _draw_scene_composed_object(world_object):
			continue
		match String(world_object.type):
			"campfire":
				_draw_campfire(world_object)
			"coffee_setup":
				_draw_camp_dressing(world_object, &"coffee_setup", Vector2(-24.0, -28.0), Vector2(48.0, 35.0))
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
			"town_jobs_board":
				_draw_town_sign_object(world_object, "JOBS", Color("6c5131"), &"town_jobs_board")
			"town_church":
				_draw_assigned_town_building(world_object, &"town_church_building", "REMITTANCE", 0.34)
			"town_foreman":
				_draw_assigned_town_building(world_object, &"town_foreman_building", "DEPOT", 0.32)
			"town_grocery":
				_draw_assigned_town_building(world_object, &"town_grocery_building", "PROVISIONS", 0.30)
			"town_hardware":
				_draw_assigned_town_building(world_object, &"town_hardware_building", "HARDWARE", 0.32)
			"town_road_exit":
				_draw_town_sign_object(world_object, "CAMP ROAD", Color("53452f"), &"town_road_sign")
			"town_prop_light":
				_draw_town_prop(world_object, &"town_light", Vector2(-12.0, -70.0), Vector2(24.0, 78.0))
			"town_prop_trash":
				_draw_town_prop(world_object, &"town_trash", Vector2(-14.0, -28.0), Vector2(28.0, 34.0))
			"town_prop_crate_stack":
				_draw_town_prop(world_object, &"town_crate_stack", Vector2(-28.0, -34.0), Vector2(56.0, 38.0))
			"town_prop_board_stack":
				_draw_town_prop(world_object, &"town_board_stack", Vector2(-34.0, -32.0), Vector2(68.0, 34.0))
			"town_prop_wheelbarrow":
				_draw_town_prop(world_object, &"town_wheelbarrow", Vector2(-32.0, -34.0), Vector2(64.0, 38.0))
			"town_prop_handcart":
				_draw_town_prop(world_object, &"town_handcart", Vector2(-34.0, -36.0), Vector2(68.0, 40.0))
			"town_prop_lanterns":
				_draw_town_prop(world_object, &"town_lantern_group", Vector2(-24.0, -34.0), Vector2(48.0, 38.0))
			_:
				_draw_generic_object(world_object)


func _draw_scene_composed_object(world_object) -> bool:
	if not _has_scene_composition():
		return false
	var hidden_types := PackedStringArray()
	if terrain_mode == &"camp":
		hidden_types = PackedStringArray([
			"campfire", "woodpile", "bedroll", "stash", "tool_area", "trail_sign",
			"wash_line", "tree", "tarp_shelter", "log", "stump", "crate"
		])
	else:
		hidden_types = PackedStringArray([
			"town_jobs_board", "town_church", "town_foreman", "town_grocery", "town_hardware",
			"town_road_exit", "town_prop_light", "town_prop_trash", "town_prop_crate_stack",
			"town_prop_board_stack", "town_prop_wheelbarrow", "town_prop_handcart",
			"town_prop_lanterns", "tree"
		])
	if not hidden_types.has(String(world_object.type)):
		return false
	_draw_object_highlight(world_object, _get_object_visual_rect(world_object))
	return true


func _draw_player() -> void:
	var center = _world_to_screen(player_render_position)
	_draw_shadow(center + _zv(Vector2(0.0, 12.0)), 22.0, 9.0, 0.26)
	draw_rect(_scaled_rect(center, Vector2(-8.0, -18.0), Vector2(16.0, 25.0)), Color("5b6f82"))
	draw_rect(_scaled_rect(center, Vector2(-7.0, 6.0), Vector2(4.5, 13.0)), Color("3a2f27"))
	draw_rect(_scaled_rect(center, Vector2(2.5, 6.0), Vector2(4.5, 13.0)), Color("3a2f27"))
	draw_rect(_scaled_rect(center, Vector2(-10.5, -13.0), Vector2(3.5, 14.0)), Color("8a735b"))
	draw_rect(_scaled_rect(center, Vector2(7.0, -13.0), Vector2(3.5, 14.0)), Color("8a735b"))
	draw_circle(center + _zv(Vector2(0.0, -24.0)), _zf(6.2), Color("c5a283"))
	draw_rect(_scaled_rect(center, Vector2(-8.0, -32.0), Vector2(16.0, 4.5)), Color("53463a"))
	var satchel_offset = Vector2(8.0 * _player_side_sign, -5.0) if _player_facing == &"side" else Vector2(8.0, -3.0)
	draw_rect(_scaled_rect(center, satchel_offset, Vector2(6.0, 11.0)), Color("70563d"))
	draw_colored_polygon(_get_player_facing_marker(center), Color("d8d36a"))
	draw_polyline(_get_player_facing_marker(center), Color("f3ef9d"), 2.0, true)


func _update_player_facing(delta: Vector2) -> void:
	if delta.length() < 0.01:
		_player_is_moving = false
		return
	_player_is_moving = true
	var screen_delta := Vector2(delta.x - delta.y, delta.x + delta.y)
	if absf(screen_delta.x) > absf(screen_delta.y):
		_player_facing = &"side"
		_player_side_sign = -1.0 if screen_delta.x < 0.0 else 1.0
	elif screen_delta.y < 0.0:
		_player_facing = &"back"
	else:
		_player_facing = &"front"


func _get_player_texture_key() -> StringName:
	var frames := PLAYER_FRONT_FRAMES
	if _player_facing == &"back":
		frames = PLAYER_BACK_FRAMES
	elif _player_facing == &"side":
		frames = PLAYER_SIDE_FRAMES
	var frame_index := 0
	if _player_is_moving:
		frame_index = int(Time.get_ticks_msec() / 160) % frames.size()
	return frames[frame_index]


func _get_player_facing_marker(center: Vector2) -> PackedVector2Array:
	match _player_facing:
		&"back":
			return PackedVector2Array([
				center + _zv(Vector2(0.0, -38.0)),
				center + _zv(Vector2(8.0, -27.0)),
				center + _zv(Vector2(-8.0, -27.0))
			])
		&"side":
			return PackedVector2Array([
				center + _zv(Vector2(14.0 * _player_side_sign, -23.0)),
				center + _zv(Vector2(2.0 * _player_side_sign, -31.0)),
				center + _zv(Vector2(2.0 * _player_side_sign, -14.0))
			])
		_:
			return PackedVector2Array([
				center + _zv(Vector2(0.0, -15.0)),
				center + _zv(Vector2(8.0, -27.0)),
				center + _zv(Vector2(-8.0, -27.0))
			])


func _draw_campfire(world_object) -> void:
	var base = _scale_polygon(_get_footprint_polygon(world_object), 1.35, 1.18)
	var center = _polygon_center(base)
	var ring = _offset_polygon(base, Vector2(0.0, -_zf(6.0)))
	_draw_shadow(center + _zv(Vector2(0.0, 9.0)), 64.0, 16.0, 0.24)
	draw_colored_polygon(ring, Color("4e3a2a"))
	draw_polyline(ring, Color("8f7157"), 2.0, true)
	for angle_index in range(10):
		var angle = TAU * float(angle_index) / 10.0
		var ember = center + _zv(Vector2(cos(angle) * 17.0, sin(angle) * 9.0 - 2.0))
		draw_circle(ember, _zf(4.2), Color("7b6551"))
	draw_colored_polygon(PackedVector2Array([
		center + _zv(Vector2(0.0, -48.0)),
		center + _zv(Vector2(22.0, -8.0)),
		center + _zv(Vector2(7.0, 14.0)),
		center + _zv(Vector2(-2.0, -4.0)),
		center + _zv(Vector2(-10.0, 16.0)),
		center + _zv(Vector2(-24.0, -2.0))
	]), Color("d76d25"))
	draw_colored_polygon(PackedVector2Array([
		center + _zv(Vector2(0.0, -32.0)),
		center + _zv(Vector2(14.0, -5.0)),
		center + _zv(Vector2(5.0, 10.0)),
		center + _zv(Vector2(-1.0, -1.0)),
		center + _zv(Vector2(-7.0, 10.0)),
		center + _zv(Vector2(-14.0, -1.0))
	]), Color("f0c55c"))
	draw_line(center + _zv(Vector2(-24.0, 13.0)), center + _zv(Vector2(22.0, -2.0)), Color("5a3a26"), _zf(4.0))
	draw_line(center + _zv(Vector2(-19.0, -3.0)), center + _zv(Vector2(18.0, 14.0)), Color("5a3a26"), _zf(4.0))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		ring[0], ring[1], ring[2], ring[3],
		center + _zv(Vector2(0.0, -48.0)),
		center + _zv(Vector2(22.0, -8.0)),
		center + _zv(Vector2(-24.0, -2.0))
	])))


func _draw_woodpile(world_object) -> void:
	if _draw_textured_object(world_object, &"woodpile", 0.42):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var bounds = _polygon_bounds(_get_footprint_polygon(world_object))
	var center = bounds.get_center()
	var pile_width = bounds.size.x / view_zoom + 34.0
	_draw_shadow(center + _zv(Vector2(0.0, 8.0)), bounds.size.x * 1.55, 12.0, 0.18)
	for row in range(4):
		var row_width = pile_width - float(row) * 7.0
		var row_y = 2.0 - float(row) * 8.0
		_draw_log_segment(center, Vector2(-row_width * 0.52, row_y + 1.0), Vector2(row_width * 0.40, row_y - 5.0), 8.5, Color("705134"), Color("a07a57"))
		_draw_log_segment(center, Vector2(-row_width * 0.38, row_y - 3.0), Vector2(row_width * 0.53, row_y - 8.0), 8.0, Color("7c593a"), Color("b08a63"))
	_draw_log_segment(center, Vector2(-pile_width * 0.25, 8.0), Vector2(pile_width * 0.15, 4.0), 8.0, Color("6d4f33"), Color("9a7556"))
	_draw_log_segment(center, Vector2(-pile_width * 0.02, 10.0), Vector2(pile_width * 0.36, 4.0), 8.0, Color("6d4f33"), Color("9a7556"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		center + _zv(Vector2(-(bounds.size.x / view_zoom + 42.0) * 0.5, -42.0)),
		center + _zv(Vector2((bounds.size.x / view_zoom + 42.0) * 0.5, 5.0))
	])))


func _draw_camp_dressing(world_object, texture_key: StringName, offset: Vector2, base_size: Vector2) -> void:
	if _draw_textured_object(world_object, texture_key, 0.42):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var center = _get_object_anchor_screen(world_object)
	draw_rect(_scaled_rect(center, Vector2(-10.0, -14.0), Vector2(20.0, 18.0)), Color("6f5b42"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-12.0, -16.0), Vector2(24.0, 22.0)))


func _draw_bedroll(world_object) -> void:
	if _draw_textured_object(world_object, &"bedroll", 0.50):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var bounds = _polygon_bounds(_get_footprint_polygon(world_object))
	var center = bounds.get_center()
	var roll_width = bounds.size.x / view_zoom + 12.0
	_draw_shadow(center + _zv(Vector2(0.0, 6.0)), bounds.size.x * 1.28, 10.0, 0.14)
	var mat = PackedVector2Array([
		center + _zv(Vector2(-roll_width * 0.72, 3.0)),
		center + _zv(Vector2(-roll_width * 0.62, -6.0)),
		center + _zv(Vector2(roll_width * 0.20, -12.0)),
		center + _zv(Vector2(roll_width * 0.56, -2.0)),
		center + _zv(Vector2(roll_width * 0.44, 10.0)),
		center + _zv(Vector2(-roll_width * 0.58, 8.0))
	])
	draw_colored_polygon(mat, Color("6f835f"))
	draw_polyline(mat, Color("9ead89"), 2.0, true)
	draw_circle(center + _zv(Vector2(-roll_width * 0.50, -1.0)), _zf(10.0), Color("536148"))
	draw_circle(center + _zv(Vector2(-roll_width * 0.50, -1.0)), _zf(6.6), Color("7f9270"))
	draw_rect(_scaled_rect(center, Vector2(-roll_width * 0.16, -17.0), Vector2(20.0, 10.0)), Color("c1b39a"))
	draw_line(center + _zv(Vector2(-roll_width * 0.18, 5.0)), center + _zv(Vector2(roll_width * 0.40, -1.0)), Color("44503d"), _zf(2.0))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		center + _zv(Vector2(-roll_width * 0.60, -18.0)),
		center + _zv(Vector2(roll_width * 0.48, 7.0))
	])))


func _draw_stash(world_object) -> void:
	if _draw_textured_object(world_object, &"stash", 0.47):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var base = _scale_polygon(_get_footprint_polygon(world_object), 1.28, 1.16)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(24.0)))
	_draw_shadow(_polygon_center(base) + _zv(Vector2(0.0, 7.0)), _polygon_bounds(base).size.x * 1.08, 10.0, 0.16)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), Color("5d4a31"))
	draw_colored_polygon(PackedVector2Array([top[2], top[3], base[3], base[2]]), Color("765c3d"))
	draw_colored_polygon(top, Color("92724d"))
	var lid = _scale_polygon(top, 0.86, 0.82)
	draw_colored_polygon(PackedVector2Array([lid[1], lid[2], top[2], top[1]]), Color("7a5f3f"))
	draw_colored_polygon(PackedVector2Array([lid[2], lid[3], top[3], top[2]]), Color("8a6c47"))
	draw_colored_polygon(lid, Color("9d7a50"))
	draw_line(top[0], top[2], Color("d0bc87"), _zf(2.0))
	draw_line(base[3], base[2], Color("4f3c28"), _zf(2.0))
	draw_line(base[2], base[1], Color("4f3c28"), _zf(2.0))
	draw_rect(_scaled_rect(_polygon_center(base) + _zv(Vector2(0.0, -5.0)), Vector2(-4.0, -2.0), Vector2(8.0, 10.0)), Color("d3b86d"))
	_draw_object_highlight(world_object, _get_stand_in_block_rect(world_object, 24.0, 1.28, 1.16))


func _draw_tool_area(world_object) -> void:
	if _draw_textured_object(world_object, &"tool_area", 0.42):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var bounds = _polygon_bounds(_get_footprint_polygon(world_object))
	var center = bounds.get_center()
	var bench_width = bounds.size.x / view_zoom + 24.0
	_draw_shadow(center + _zv(Vector2(0.0, 7.0)), bounds.size.x * 1.4, 11.0, 0.14)
	var table_top = PackedVector2Array([
		center + _zv(Vector2(-bench_width * 0.54, -14.0)),
		center + _zv(Vector2(bench_width * 0.06, -22.0)),
		center + _zv(Vector2(bench_width * 0.56, -8.0)),
		center + _zv(Vector2(-bench_width * 0.04, 0.0))
	])
	draw_colored_polygon(table_top, Color("75573a"))
	draw_polyline(table_top, Color("a17e57"), 2.0, true)
	draw_line(table_top[0], center + _zv(Vector2(-bench_width * 0.46, 14.0)), Color("59442f"), _zf(3.0))
	draw_line(table_top[1], center + _zv(Vector2(bench_width * 0.01, 13.0)), Color("59442f"), _zf(3.0))
	draw_line(table_top[2], center + _zv(Vector2(bench_width * 0.48, 10.0)), Color("59442f"), _zf(3.0))
	draw_line(table_top[3], center + _zv(Vector2(-bench_width * 0.08, 14.0)), Color("59442f"), _zf(3.0))
	draw_rect(_scaled_rect(center, Vector2(-bench_width * 0.30, -26.0), Vector2(bench_width * 0.18, 10.0)), Color("8b8f75"))
	draw_rect(_scaled_rect(center, Vector2(-3.0, -28.0), Vector2(8.0, 16.0)), Color("7e8a93"))
	draw_line(center + _zv(Vector2(16.0, -25.0)), center + _zv(Vector2(30.0, -12.0)), Color("c0c7cc"), _zf(2.0))
	draw_line(center + _zv(Vector2(22.0, -28.0)), center + _zv(Vector2(34.0, -13.0)), Color("c0c7cc"), _zf(2.0))
	draw_rect(_scaled_rect(center, Vector2(32.0, -26.0), Vector2(10.0, 14.0)), Color("69553b"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		center + _zv(Vector2(-bench_width * 0.52, -24.0)),
		center + _zv(Vector2(bench_width * 0.48, 12.0))
	])))


func _draw_trail_sign(world_object) -> void:
	if _draw_textured_object(world_object, &"camp_exit_sign", 0.46):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	_draw_direction_sign(world_object, Color("b7aa68"), Color("695430"), false)


func _draw_tree(world_object) -> void:
	var center = _get_object_anchor_screen(world_object)
	draw_circle(center + _zv(Vector2(0.0, -10.0)), _zf(12.0), Color("29412a"))
	draw_rect(_scaled_rect(center, Vector2(-2.0, -3.0), Vector2(4.0, 18.0)), Color("4f3c26"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-18.0, -24.0), Vector2(36.0, 32.0)))


func _draw_tarp_shelter(world_object) -> void:
	var center = _get_object_anchor_screen(world_object)
	_draw_shadow(center + _zv(Vector2(0.0, 22.0)), 72.0, 18.0, 0.22)
	draw_line(center + _zv(Vector2(-34.0, -6.0)), center + _zv(Vector2(-34.0, 24.0)), Color("654a31"), _zf(4.0))
	draw_line(center + _zv(Vector2(30.0, -8.0)), center + _zv(Vector2(30.0, 20.0)), Color("654a31"), _zf(4.0))
	draw_colored_polygon(PackedVector2Array([
		center + _zv(Vector2(-42.0, -12.0)),
		center + _zv(Vector2(32.0, -22.0)),
		center + _zv(Vector2(46.0, 4.0)),
		center + _zv(Vector2(-28.0, 12.0))
	]), Color("5d6f77"))
	draw_rect(_scaled_rect(center, Vector2(-24.0, 0.0), Vector2(44.0, 18.0)), Color("43382d"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-50.0, -28.0), Vector2(102.0, 58.0)))


func _draw_log(world_object) -> void:
	var center = _get_object_anchor_screen(world_object)
	draw_rect(_scaled_rect(center, Vector2(-16.0, -4.0), Vector2(32.0, 8.0)), Color("7f5d3c"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-18.0, -18.0), Vector2(36.0, 34.0)))


func _draw_stump(world_object) -> void:
	var center = _get_object_anchor_screen(world_object)
	draw_rect(_scaled_rect(center, Vector2(-6.0, -7.0), Vector2(12.0, 14.0)), Color("755438"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-16.0, -18.0), Vector2(32.0, 32.0)))


func _draw_crate(world_object) -> void:
	var center = _get_object_anchor_screen(world_object)
	_draw_shadow(center + _zv(Vector2(0.0, 14.0)), 24.0, 10.0, 0.16)
	draw_rect(_scaled_rect(center, Vector2(-12.0, -7.0), Vector2(24.0, 17.0)), Color("77563a"))
	draw_line(center + _zv(Vector2(-8.0, -5.0)), center + _zv(Vector2(-8.0, 8.0)), Color("5b4128"), _zf(2.0))
	draw_line(center + _zv(Vector2(0.0, -5.0)), center + _zv(Vector2(0.0, 8.0)), Color("5b4128"), _zf(2.0))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-15.0, -12.0), Vector2(30.0, 26.0)))


func _draw_wash_line(world_object) -> void:
	if _draw_textured_object(world_object, &"wash_line", 0.48):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var bounds = _polygon_bounds(_get_footprint_polygon(world_object))
	var center = bounds.get_center()
	var span = bounds.size.x / view_zoom + 34.0
	_draw_shadow(center + _zv(Vector2(0.0, 7.0)), bounds.size.x * 1.3, 9.0, 0.12)
	draw_line(center + _zv(Vector2(-span * 0.44, -42.0)), center + _zv(Vector2(-span * 0.44, 9.0)), Color("6f5738"), _zf(4.0))
	draw_line(center + _zv(Vector2(span * 0.44, -39.0)), center + _zv(Vector2(span * 0.44, 11.0)), Color("6f5738"), _zf(4.0))
	draw_line(center + _zv(Vector2(-span * 0.42, -31.0)), center + _zv(Vector2(span * 0.42, -28.0)), Color("b8b4aa"), _zf(2.0))
	_draw_cloth_panel(center, Vector2(-span * 0.24, -28.0), Vector2(-span * 0.10, -27.0), 24.0, Color("cfc8b4"))
	_draw_cloth_panel(center, Vector2(-2.0, -27.0), Vector2(16.0, -26.0), 22.0, Color("9ea9b6"))
	_draw_cloth_panel(center, Vector2(26.0, -26.0), Vector2(42.0, -26.0), 20.0, Color("d3c6a6"))
	_draw_bucket(center, Vector2(56.0, 8.0), Color("776f63"), Color("43413e"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		center + _zv(Vector2(-span * 0.44, -42.0)),
		center + _zv(Vector2(span * 0.44, 11.0))
	])))


func _draw_generic_object(world_object) -> void:
	var center = _get_object_anchor_screen(world_object)
	draw_rect(_scaled_rect(center, Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), Color("7c6a55"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-16.0, -16.0), Vector2(32.0, 32.0)))


func _draw_assigned_town_building(world_object, texture_key: StringName, label: String, scale: float) -> void:
	var texture_scale := 0.54
	match world_object.type:
		&"town_church":
			texture_scale = 0.56
		&"town_grocery":
			texture_scale = 0.55
		&"town_hardware":
			texture_scale = 0.53
	if _draw_textured_object(world_object, texture_key, texture_scale):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var palette = _get_town_stand_in_palette(world_object.type)
	match world_object.type:
		&"town_church":
			_draw_church_mass(world_object, palette)
		&"town_grocery":
			_draw_storefront_mass(world_object, palette)
		&"town_hardware":
			_draw_hardware_mass(world_object, palette)
		_:
			_draw_building_mass(world_object, palette)


func _draw_town_sign_object(world_object, label: String, post_color: Color, texture_key: StringName) -> void:
	var texture_scale := 0.50 if world_object.type == &"town_jobs_board" else 0.48
	if _draw_textured_object(world_object, texture_key, texture_scale):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	if world_object.type == &"town_jobs_board":
		_draw_signboard(world_object, label, post_color)
	else:
		_draw_direction_sign(world_object, post_color.lightened(0.1), post_color.darkened(0.2), true)


func _draw_town_prop(world_object, texture_key: StringName, offset: Vector2, base_size: Vector2) -> void:
	if _draw_textured_object(world_object, texture_key, 0.42):
		_draw_object_highlight(world_object, _get_object_hit_rect(world_object))
		return
	var center = _get_object_anchor_screen(world_object)
	draw_rect(_scaled_rect(center, Vector2(-8.0, -22.0), Vector2(16.0, 30.0)), Color("6b6658"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-10.0, -24.0), Vector2(20.0, 34.0)))


func _draw_town_label(center: Vector2, label: String, color: Color) -> void:
	var font = get_theme_default_font()
	if font == null:
		return
	var font_size := int(maxf(8.0, 11.0 * view_zoom))
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var label_rect = Rect2(center - Vector2(text_size.x * 0.5 + 5.0, text_size.y * 0.5 + 3.0), text_size + Vector2(10.0, 6.0))
	draw_rect(label_rect, Color(0.08, 0.07, 0.05, 0.82), true)
	draw_string(font, center + Vector2(-text_size.x * 0.5, text_size.y * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_building_mass(world_object, palette: Dictionary) -> void:
	var base = _scale_polygon(_get_footprint_polygon(world_object), 1.12, 1.08)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(58.0)))
	var bounds = _polygon_bounds(base)
	var center = _polygon_center(base)
	_draw_shadow(center + _zv(Vector2(0.0, 10.0)), bounds.size.x * 1.12, maxf(bounds.size.y * 0.82, 18.0), 0.18)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), palette.side)
	draw_colored_polygon(PackedVector2Array([top[2], top[3], base[3], base[2]]), palette.front)
	draw_colored_polygon(top, palette.top)
	var awning = _offset_polygon(PackedVector2Array([
		top[3] + _zv(Vector2(-10.0, 8.0)),
		top[2] + _zv(Vector2(10.0, 8.0)),
		base[2] + _zv(Vector2(20.0, -10.0)),
		base[3] + _zv(Vector2(-20.0, -10.0))
	]), Vector2.ZERO)
	draw_colored_polygon(awning, palette.top.lightened(0.1))
	draw_polyline(top, palette.top.lightened(0.18), 2.0, true)
	_draw_facade_door(center, Vector2(0.0, -6.0), Vector2(22.0, 30.0), Color("2a2722"), Color("b7aa8d"))
	_draw_facade_window(center, Vector2(-25.0, -20.0), Vector2(18.0, 16.0), Color("706a60"), Color("94a3af"))
	_draw_facade_window(center, Vector2(25.0, -20.0), Vector2(18.0, 16.0), Color("706a60"), Color("94a3af"))
	_draw_object_highlight(world_object, _get_stand_in_block_rect(world_object, 58.0, 1.12, 1.08))


func _draw_church_mass(world_object, palette: Dictionary) -> void:
	var base = _scale_polygon(_get_footprint_polygon(world_object), 1.12, 1.1)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(72.0)))
	var bounds = _polygon_bounds(base)
	var center = _polygon_center(base)
	_draw_shadow(center + _zv(Vector2(0.0, 10.0)), bounds.size.x * 1.24, maxf(bounds.size.y * 0.9, 20.0), 0.18)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), palette.side)
	draw_colored_polygon(PackedVector2Array([top[2], top[3], base[3], base[2]]), palette.front)
	draw_colored_polygon(top, palette.top)
	draw_polyline(top, palette.top.lightened(0.16), 2.0, true)
	_draw_facade_door(center, Vector2(0.0, -10.0), Vector2(26.0, 36.0), Color("3a2d23"), Color("c7b48f"))
	_draw_facade_window(center, Vector2(-28.0, -25.0), Vector2(14.0, 18.0), Color("867d72"), Color("b7c0c6"))
	_draw_facade_window(center, Vector2(28.0, -25.0), Vector2(14.0, 18.0), Color("867d72"), Color("b7c0c6"))
	draw_circle(center + _zv(Vector2(0.0, -42.0)), _zf(9.0), Color("2e2a25"))
	draw_circle(center + _zv(Vector2(0.0, -42.0)), _zf(5.0), Color("7e7161"))
	var tower_base = center + _zv(Vector2(20.0, -54.0))
	draw_rect(_scaled_rect(tower_base, Vector2(-15.0, -40.0), Vector2(30.0, 54.0)), palette.top.lightened(0.08))
	_draw_facade_window(tower_base, Vector2(0.0, -21.0), Vector2(14.0, 12.0), Color("85796c"), Color("aeb8be"))
	draw_colored_polygon(PackedVector2Array([
		tower_base + _zv(Vector2(0.0, -96.0)),
		tower_base + _zv(Vector2(19.0, -30.0)),
		tower_base + _zv(Vector2(0.0, -10.0)),
		tower_base + _zv(Vector2(-19.0, -30.0))
	]), palette.side.darkened(0.08))
	draw_line(tower_base + _zv(Vector2(0.0, -106.0)), tower_base + _zv(Vector2(0.0, -96.0)), Color("d9ccb0"), _zf(2.0))
	draw_line(tower_base + _zv(Vector2(-5.0, -101.0)), tower_base + _zv(Vector2(5.0, -101.0)), Color("d9ccb0"), _zf(2.0))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		top[0], top[1], top[2], top[3], base[0], base[1], base[2], base[3],
		tower_base + _zv(Vector2(0.0, -96.0))
	])))


func _draw_storefront_mass(world_object, palette: Dictionary) -> void:
	var base = _scale_polygon(_get_footprint_polygon(world_object), 1.14, 1.08)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(60.0)))
	var bounds = _polygon_bounds(base)
	var center = _polygon_center(base)
	_draw_shadow(center + _zv(Vector2(0.0, 10.0)), bounds.size.x * 1.22, maxf(bounds.size.y * 0.82, 18.0), 0.18)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), palette.side)
	draw_colored_polygon(PackedVector2Array([top[2], top[3], base[3], base[2]]), palette.front)
	draw_colored_polygon(top, palette.top)
	draw_colored_polygon(PackedVector2Array([
		top[3] + _zv(Vector2(-12.0, 11.0)),
		top[2] + _zv(Vector2(12.0, 11.0)),
		base[2] + _zv(Vector2(20.0, -10.0)),
		base[3] + _zv(Vector2(-20.0, -10.0))
	]), palette.top.lightened(0.14))
	draw_polyline(top, palette.top.lightened(0.18), 2.0, true)
	for stripe in range(6):
		var stripe_x = -34.0 + float(stripe) * 11.5
		draw_rect(_scaled_rect(center + _zv(Vector2(0.0, -37.0)), Vector2(stripe_x, -5.0), Vector2(6.5, 9.0)), Color("e6d6aa" if stripe % 2 == 0 else "7d8f5a"))
	_draw_facade_door(center, Vector2(0.0, -3.0), Vector2(28.0, 28.0), Color("25231e"), Color("cdb78d"))
	_draw_facade_window(center, Vector2(-31.0, -14.0), Vector2(24.0, 16.0), Color("54634b"), Color("a9b8bb"))
	_draw_facade_window(center, Vector2(31.0, -14.0), Vector2(24.0, 16.0), Color("54634b"), Color("a9b8bb"))
	_draw_small_crate(center, Vector2(34.0, 10.0), Vector2(12.0, 10.0), Color("7b5d3d"), Color("5b412b"))
	_draw_small_crate(center, Vector2(46.0, 6.0), Vector2(11.0, 9.0), Color("745638"), Color("5b412b"))
	_draw_barrel(center, Vector2(-44.0, 10.0), Vector2(10.0, 16.0), Color("7b6545"), Color("4d463a"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		top[0], top[1], top[2], top[3],
		base[0] + _zv(Vector2(-20.0, 0.0)),
		base[1] + _zv(Vector2(20.0, 0.0))
	])))


func _draw_hardware_mass(world_object, palette: Dictionary) -> void:
	var base = _scale_polygon(_get_footprint_polygon(world_object), 1.14, 1.08)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(62.0)))
	var bounds = _polygon_bounds(base)
	var center = _polygon_center(base)
	_draw_shadow(center + _zv(Vector2(0.0, 10.0)), bounds.size.x * 1.22, maxf(bounds.size.y * 0.84, 18.0), 0.18)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), palette.side)
	draw_colored_polygon(PackedVector2Array([top[2], top[3], base[3], base[2]]), palette.front)
	draw_colored_polygon(top, palette.top)
	draw_polyline(top, palette.top.lightened(0.18), 2.0, true)
	_draw_facade_door(center, Vector2(0.0, -4.0), Vector2(32.0, 32.0), Color("23231f"), Color("8e938f"))
	_draw_facade_window(center, Vector2(-30.0, -14.0), Vector2(20.0, 15.0), Color("596877"), Color("9daab5"))
	_draw_facade_window(center, Vector2(30.0, -14.0), Vector2(20.0, 15.0), Color("596877"), Color("9daab5"))
	draw_rect(_scaled_rect(center + _zv(Vector2(36.0, -44.0)), Vector2(-4.0, -22.0), Vector2(8.0, 34.0)), Color("6f6a5b"))
	draw_line(center + _zv(Vector2(-42.0, -35.0)), center + _zv(Vector2(42.0, -35.0)), Color("d3d0bf"), _zf(2.0))
	draw_line(center + _zv(Vector2(-24.0, -35.0)), center + _zv(Vector2(-24.0, -18.0)), Color("d3d0bf"), _zf(2.0))
	draw_line(center + _zv(Vector2(0.0, -35.0)), center + _zv(Vector2(0.0, -18.0)), Color("d3d0bf"), _zf(2.0))
	draw_line(center + _zv(Vector2(24.0, -35.0)), center + _zv(Vector2(24.0, -18.0)), Color("d3d0bf"), _zf(2.0))
	_draw_small_crate(center, Vector2(-44.0, 10.0), Vector2(12.0, 10.0), Color("725638"), Color("4d3b2a"))
	_draw_small_crate(center, Vector2(-32.0, 5.0), Vector2(14.0, 12.0), Color("7a5d3d"), Color("4d3b2a"))
	_draw_barrel(center, Vector2(50.0, 11.0), Vector2(10.0, 16.0), Color("72624b"), Color("45433f"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		top[0], top[1], top[2], top[3],
		center + _zv(Vector2(36.0, -66.0))
	])))


func _draw_signboard(world_object, label: String, post_color: Color) -> void:
	var base = _get_footprint_polygon(world_object)
	var center = _polygon_center(base)
	_draw_shadow(center + _zv(Vector2(0.0, 5.0)), 34.0, 9.0, 0.14)
	draw_rect(_scaled_rect(center, Vector2(-16.0, -24.0), Vector2(5.0, 31.0)), post_color.darkened(0.2))
	draw_rect(_scaled_rect(center, Vector2(11.0, -24.0), Vector2(5.0, 31.0)), post_color.darkened(0.2))
	draw_line(center + _zv(Vector2(-12.0, -6.0)), center + _zv(Vector2(-24.0, -24.0)), post_color.darkened(0.28), _zf(2.0))
	draw_line(center + _zv(Vector2(12.0, -6.0)), center + _zv(Vector2(24.0, -24.0)), post_color.darkened(0.28), _zf(2.0))
	draw_rect(_scaled_rect(center, Vector2(-34.0, -56.0), Vector2(68.0, 38.0)), post_color.lightened(0.08))
	draw_rect(_scaled_rect(center, Vector2(-26.0, -46.0), Vector2(52.0, 5.0)), Color("efe5c2"))
	draw_rect(_scaled_rect(center, Vector2(-26.0, -36.0), Vector2(45.0, 4.0)), Color("efe5c2"))
	draw_rect(_scaled_rect(center, Vector2(-26.0, -28.0), Vector2(36.0, 4.0)), Color("efe5c2"))
	_draw_object_highlight(world_object, _get_stand_in_marker_rect(world_object, 56.0, 1.18, 1.0))


func _draw_direction_sign(world_object, cap_color: Color, post_color: Color, arrow_right: bool) -> void:
	var base = _get_footprint_polygon(world_object)
	var center = _polygon_center(base)
	var direction = 1.0 if arrow_right else -1.0
	_draw_shadow(center + _zv(Vector2(0.0, 5.0)), 28.0, 8.0, 0.14)
	draw_rect(_scaled_rect(center, Vector2(-4.0, -21.0), Vector2(5.0, 29.0)), post_color)
	draw_colored_polygon(PackedVector2Array([
		center + _zv(Vector2(-22.0 * direction, -36.0)),
		center + _zv(Vector2(14.0 * direction, -36.0)),
		center + _zv(Vector2(28.0 * direction, -28.0)),
		center + _zv(Vector2(14.0 * direction, -20.0)),
		center + _zv(Vector2(-22.0 * direction, -20.0))
	]), cap_color)
	draw_line(center + _zv(Vector2(-2.0, -8.0)), center + _zv(Vector2(12.0 * direction, -20.0)), post_color.darkened(0.22), _zf(2.0))
	_draw_object_highlight(world_object, _get_stand_in_marker_rect(world_object, 42.0, 1.16, 1.0))


func _draw_object_highlight(world_object, rect: Rect2) -> void:
	if world_object.id != active_object_id and world_object.id != hovered_object_id:
		return
	var color = Color("f4d78a") if world_object.id == active_object_id else Color("a7c6d9")
	draw_rect(rect, color, false, 2.0)


func _draw_stand_in_block(world_object, top_color: Color, front_color: Color, side_color: Color, height_px: float, label: String = "") -> void:
	var base = _get_footprint_polygon(world_object)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(height_px)))
	var bounds = _polygon_bounds(base)
	_draw_shadow(bounds.get_center() + _zv(Vector2(0.0, 6.0)), maxf(bounds.size.x * 0.8, 20.0), maxf(bounds.size.y * 0.5, 8.0), 0.16)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), side_color)
	draw_colored_polygon(PackedVector2Array([top[2], top[3], base[3], base[2]]), front_color)
	draw_colored_polygon(top, top_color)
	draw_polyline(top, top_color.lightened(0.22), 2.0, true)
	draw_polyline(PackedVector2Array([top[1], top[2], base[2], base[1]]), side_color.darkened(0.18), 2.0, true)
	draw_polyline(PackedVector2Array([top[2], top[3], base[3], base[2]]), front_color.darkened(0.18), 2.0, true)
	if label != "":
		_draw_town_label(_polygon_center(top), label, Color("f2ead7"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		top[0], top[1], top[2], top[3], base[0], base[1], base[2], base[3]
	])))


func _draw_stand_in_marker(world_object, cap_color: Color, post_color: Color, label: String = "") -> void:
	var base = _get_footprint_polygon(world_object)
	var center = _polygon_center(base)
	var marker_base = _offset_polygon(base, Vector2(0.0, -_zf(10.0)))
	var cap = _offset_polygon(base, Vector2(0.0, -_zf(28.0)))
	var post_width = maxf(_zf(4.0), 3.0)
	var post_height = _zf(18.0)
	_draw_shadow(center + _zv(Vector2(0.0, 6.0)), maxf(_polygon_bounds(base).size.x * 0.7, 16.0), 7.0, 0.15)
	draw_colored_polygon(marker_base, cap_color.darkened(0.2))
	draw_rect(Rect2(center + Vector2(-post_width * 0.5, -post_height), Vector2(post_width, post_height)), post_color)
	draw_colored_polygon(cap, cap_color)
	draw_polyline(cap, cap_color.lightened(0.22), 2.0, true)
	if label != "":
		_draw_town_label(_polygon_center(cap), label, Color("f2ead7"))
	_draw_object_highlight(world_object, _polygon_bounds(PackedVector2Array([
		cap[0], cap[1], cap[2], cap[3], marker_base[0], marker_base[1], marker_base[2], marker_base[3]
	])))


func _get_footprint_polygon(world_object) -> PackedVector2Array:
	var origin = world_object.get_footprint_origin()
	var width = float(max(world_object.size_tiles.x, 1))
	var height = float(max(world_object.size_tiles.y, 1))
	return PackedVector2Array([
		_world_to_screen(Vector2(origin) + Vector2((width - 1.0) * 0.5, -0.5)),
		_world_to_screen(Vector2(origin) + Vector2(width - 0.5, (height - 1.0) * 0.5)),
		_world_to_screen(Vector2(origin) + Vector2((width - 1.0) * 0.5, height - 0.5)),
		_world_to_screen(Vector2(origin) + Vector2(-0.5, (height - 1.0) * 0.5))
	])


func _offset_polygon(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	return shifted


func _scale_polygon(points: PackedVector2Array, scale_x: float, scale_y: float) -> PackedVector2Array:
	var center := _polygon_center(points)
	var scaled := PackedVector2Array()
	for point in points:
		var offset = point - center
		scaled.append(center + Vector2(offset.x * scale_x, offset.y * scale_y))
	return scaled


func _draw_textured_object(world_object, texture_key: StringName, base_scale: float = 1.0, offset: Vector2 = Vector2.ZERO) -> bool:
	var texture: Texture2D = _object_textures.get(texture_key, null)
	if texture == null:
		return false
	var art_scale = (view_zoom / DEFAULT_WORLD_ART_ZOOM) * base_scale
	var draw_size = texture.get_size() * art_scale
	var anchor = _get_object_anchor_screen(world_object) + offset * art_scale
	var rect = Rect2(anchor + Vector2(-draw_size.x * 0.5, -draw_size.y), draw_size)
	draw_texture_rect(texture, rect, false)
	return true


func _draw_log_segment(center: Vector2, start_offset: Vector2, end_offset: Vector2, thickness: float, bark_color: Color, cut_color: Color) -> void:
	var start = center + _zv(start_offset)
	var end = center + _zv(end_offset)
	draw_line(start, end, bark_color, _zf(thickness))
	draw_circle(start, _zf(thickness * 0.48), cut_color)
	draw_circle(end, _zf(thickness * 0.48), cut_color)


func _draw_facade_window(center: Vector2, offset: Vector2, pane_size: Vector2, frame_color: Color, pane_color: Color) -> void:
	var window_center = center + _zv(offset)
	draw_rect(_scaled_rect(window_center, Vector2(-pane_size.x * 0.5, -pane_size.y * 0.5), pane_size), frame_color)
	draw_rect(_scaled_rect(window_center, Vector2(-pane_size.x * 0.37, -pane_size.y * 0.37), pane_size * 0.74), pane_color)
	draw_line(window_center + _zv(Vector2(0.0, -pane_size.y * 0.37)), window_center + _zv(Vector2(0.0, pane_size.y * 0.37)), frame_color.darkened(0.12), _zf(1.5))
	draw_line(window_center + _zv(Vector2(-pane_size.x * 0.37, 0.0)), window_center + _zv(Vector2(pane_size.x * 0.37, 0.0)), frame_color.darkened(0.12), _zf(1.5))


func _draw_facade_door(center: Vector2, offset: Vector2, door_size: Vector2, door_color: Color, trim_color: Color) -> void:
	var door_center = center + _zv(offset)
	draw_rect(_scaled_rect(door_center, Vector2(-door_size.x * 0.5, -door_size.y * 0.5), door_size), door_color)
	draw_rect(_scaled_rect(door_center, Vector2(-door_size.x * 0.5 - 2.0, -door_size.y * 0.5 - 2.0), Vector2(door_size.x + 4.0, 4.0)), trim_color)
	draw_line(door_center + _zv(Vector2(0.0, -door_size.y * 0.5)), door_center + _zv(Vector2(0.0, door_size.y * 0.5)), door_color.lightened(0.08), _zf(1.5))
	draw_circle(door_center + _zv(Vector2(door_size.x * 0.23, 1.0)), _zf(1.8), trim_color.darkened(0.1))


func _draw_small_crate(center: Vector2, offset: Vector2, crate_size: Vector2, fill_color: Color, line_color: Color) -> void:
	var crate_center = center + _zv(offset)
	draw_rect(_scaled_rect(crate_center, Vector2(-crate_size.x * 0.5, -crate_size.y * 0.5), crate_size), fill_color)
	draw_line(crate_center + _zv(Vector2(-crate_size.x * 0.34, -crate_size.y * 0.30)), crate_center + _zv(Vector2(-crate_size.x * 0.34, crate_size.y * 0.30)), line_color, _zf(1.5))
	draw_line(crate_center + _zv(Vector2(0.0, -crate_size.y * 0.30)), crate_center + _zv(Vector2(0.0, crate_size.y * 0.30)), line_color, _zf(1.5))


func _draw_barrel(center: Vector2, offset: Vector2, barrel_size: Vector2, body_color: Color, hoop_color: Color) -> void:
	var barrel_center = center + _zv(offset)
	draw_rect(_scaled_rect(barrel_center, Vector2(-barrel_size.x * 0.5, -barrel_size.y * 0.5), barrel_size), body_color)
	draw_line(barrel_center + _zv(Vector2(-barrel_size.x * 0.5, -barrel_size.y * 0.18)), barrel_center + _zv(Vector2(barrel_size.x * 0.5, -barrel_size.y * 0.18)), hoop_color, _zf(1.5))
	draw_line(barrel_center + _zv(Vector2(-barrel_size.x * 0.5, barrel_size.y * 0.22)), barrel_center + _zv(Vector2(barrel_size.x * 0.5, barrel_size.y * 0.22)), hoop_color, _zf(1.5))


func _draw_cloth_panel(center: Vector2, left_anchor: Vector2, right_anchor: Vector2, drop: float, cloth_color: Color) -> void:
	var cloth = PackedVector2Array([
		center + _zv(left_anchor),
		center + _zv(right_anchor),
		center + _zv(right_anchor + Vector2(1.0, drop * 0.82)),
		center + _zv(left_anchor + Vector2(-2.0, drop))
	])
	draw_colored_polygon(cloth, cloth_color)
	draw_polyline(cloth, cloth_color.darkened(0.18), 1.5, true)


func _draw_bucket(center: Vector2, offset: Vector2, body_color: Color, rim_color: Color) -> void:
	var bucket_center = center + _zv(offset)
	draw_rect(_scaled_rect(bucket_center, Vector2(-7.0, -8.0), Vector2(14.0, 12.0)), body_color)
	draw_line(bucket_center + _zv(Vector2(-7.0, -6.0)), bucket_center + _zv(Vector2(7.0, -6.0)), rim_color, _zf(1.5))


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_x := points[0].x
	var max_x := points[0].x
	var min_y := points[0].y
	var max_y := points[0].y
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _polygon_center(points: PackedVector2Array) -> Vector2:
	var bounds = _polygon_bounds(points)
	return bounds.get_center()


func _get_town_stand_in_palette(object_type: StringName) -> Dictionary:
	match object_type:
		&"town_church":
			return {
				"top": Color("91816b"),
				"front": Color("776b59"),
				"side": Color("625849")
			}
		&"town_grocery":
			return {
				"top": Color("729660"),
				"front": Color("5f7e4f"),
				"side": Color("4e6742")
			}
		&"town_hardware":
			return {
				"top": Color("718497"),
				"front": Color("5d6e7d"),
				"side": Color("4e5d69")
			}
		_:
			return {
				"top": Color("8a6f5a"),
				"front": Color("705846"),
				"side": Color("5d493a")
			}


func _draw_debug_footprints() -> void:
	if not show_debug_footprints:
		return
	for world_object in _draw_sorted_objects:
		if world_object == null:
			continue
		for tile in world_object.get_occupied_tiles():
			if not Rect2i(Vector2i.ZERO, world_size).has_point(tile):
				continue
			draw_polyline(_get_tile_polygon(tile), Color(0.22, 0.85, 0.85, 0.75), 2.0, true)


func _draw_shadow(center: Vector2, width: float, height: float, alpha: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -_zf(height) * 0.5),
		center + Vector2(_zf(width) * 0.5, 0.0),
		center + Vector2(0.0, _zf(height) * 0.5),
		center + Vector2(-_zf(width) * 0.5, 0.0)
	]), Color(0, 0, 0, alpha))


func _draw_screen_fx() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.06))
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
	var path_distance = _distance_to_path(Vector2(tile), Vector2(camp_anchor), Vector2(camp_anchor + Vector2i(8, -7)))
	var base_forest = Color("223426").lightened((_hash01(tile.x + 13, tile.y + 7) - 0.5) * 0.14)
	var base_clearing = Color("5a4738").lightened((_hash01(tile.x + 2, tile.y + 19) - 0.5) * 0.16)
	if path_distance < 1.2 and distance_from_camp > 4.0:
		return base_clearing.lightened(0.05)
	if distance_from_camp <= clearing_radius * 0.72:
		return base_clearing
	return base_forest


func _world_to_screen(grid_position: Vector2) -> Vector2:
	var delta = grid_position - camera_render_position
	return size * 0.5 + Vector2(
		(delta.x - delta.y) * TILE_WIDTH * 0.5 * view_zoom,
		(delta.x + delta.y) * TILE_HEIGHT * 0.5 * view_zoom
	)


func get_screen_position_for_grid(grid_position: Vector2) -> Vector2:
	return _world_to_screen(grid_position)


func _screen_to_world(point: Vector2) -> Vector2:
	var offset = point - size * 0.5
	var dx = offset.x / (TILE_WIDTH * 0.5 * view_zoom)
	var dy = offset.y / (TILE_HEIGHT * 0.5 * view_zoom)
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
		center + Vector2(0.0, -_zf(TILE_HEIGHT) * 0.5),
		center + Vector2(_zf(TILE_WIDTH) * 0.5, 0.0),
		center + Vector2(0.0, _zf(TILE_HEIGHT) * 0.5),
		center + Vector2(-_zf(TILE_WIDTH) * 0.5, 0.0)
	])


func _get_object_hit_rect(world_object) -> Rect2:
	var logical_rect = _get_logical_object_hit_rect(world_object)
	var scene_rect = _get_scene_object_rect(world_object)
	if scene_rect.size.x > 0.0 and scene_rect.size.y > 0.0:
		return scene_rect.merge(logical_rect)
	return logical_rect


func _get_object_visual_rect(world_object) -> Rect2:
	var scene_rect = _get_scene_object_rect(world_object)
	if scene_rect.size.x > 0.0 and scene_rect.size.y > 0.0:
		return scene_rect
	return _get_logical_object_hit_rect(world_object)


func _get_logical_object_hit_rect(world_object) -> Rect2:
	match String(world_object.type):
		"campfire":
			return _get_stand_in_marker_rect(world_object, 48.0, 1.35, 1.18)
		"woodpile":
			return _get_stand_in_block_rect(world_object, 42.0, 1.38, 1.12)
		"bedroll":
			return _get_stand_in_block_rect(world_object, 18.0, 1.2, 1.0)
		"stash":
			return _get_stand_in_block_rect(world_object, 24.0, 1.28, 1.16)
		"tool_area":
			return _get_stand_in_block_rect(world_object, 24.0, 1.16, 1.0)
		"trail_sign":
			return _get_stand_in_marker_rect(world_object, 42.0, 1.16, 1.0)
		"tree":
			var center = _get_object_anchor_screen(world_object)
			return _scaled_rect(center, Vector2(-18.0, -24.0), Vector2(36.0, 32.0))
		"tarp_shelter":
			var center = _get_object_anchor_screen(world_object)
			return _scaled_rect(center, Vector2(-77.0, -54.0), Vector2(154.0, 66.0))
		"crate":
			var center = _get_object_anchor_screen(world_object)
			return _scaled_rect(center, Vector2(-20.0, -26.0), Vector2(40.0, 32.0))
		"wash_line":
			return _get_stand_in_block_rect(world_object, 42.0, 1.2, 1.0)
		"town_church":
			return _get_stand_in_block_rect(world_object, 96.0, 1.12, 1.1)
		"town_foreman", "town_grocery", "town_hardware":
			return _get_stand_in_block_rect(world_object, 62.0, 1.14, 1.08)
		"town_jobs_board", "town_road_exit":
			return _get_stand_in_marker_rect(world_object, 56.0, 1.18, 1.0)
		_:
			var center = _get_object_anchor_screen(world_object)
			return _scaled_rect(center, Vector2(-18.0, -18.0), Vector2(36.0, 36.0))


func _get_town_building_rect(world_object) -> Rect2:
	var center = _get_object_anchor_screen(world_object)
	return _scaled_rect(center, Vector2(-58.0, -94.0), Vector2(116.0, 106.0))


func _get_stand_in_block_rect(world_object, height_px: float, scale_x: float = 1.0, scale_y: float = 1.0) -> Rect2:
	var base = _scale_polygon(_get_footprint_polygon(world_object), scale_x, scale_y)
	var top = _offset_polygon(base, Vector2(0.0, -_zf(height_px)))
	return _polygon_bounds(PackedVector2Array([
		top[0], top[1], top[2], top[3], base[0], base[1], base[2], base[3]
	]))


func _get_stand_in_marker_rect(world_object, cap_height_px: float, scale_x: float = 1.0, scale_y: float = 1.0) -> Rect2:
	var base = _scale_polygon(_get_footprint_polygon(world_object), scale_x, scale_y)
	var cap = _offset_polygon(base, Vector2(0.0, -_zf(cap_height_px)))
	return _polygon_bounds(PackedVector2Array([
		cap[0], cap[1], cap[2], cap[3], base[0], base[1], base[2], base[3]
	]))


func _get_object_anchor_screen(world_object) -> Vector2:
	if world_object != null and world_object.has_method("get_ground_contact_position"):
		return _world_to_screen(world_object.get_ground_contact_position())
	return _world_to_screen(Vector2(world_object.position))


func _scaled_rect(center: Vector2, offset: Vector2, base_size: Vector2) -> Rect2:
	return Rect2(center + _zv(offset), base_size * view_zoom)


func _zv(value: Vector2) -> Vector2:
	return value * view_zoom


func _zf(value: float) -> float:
	return value * view_zoom


func _get_object_sort_y(world_object) -> int:
	if world_object == null:
		return 0
	return roundi(world_object.get_ground_contact_position().y) + 1


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
