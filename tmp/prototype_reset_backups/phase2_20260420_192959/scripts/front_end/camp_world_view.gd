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
const MIN_VIEW_ZOOM := 1.0
const MAX_VIEW_ZOOM := 2.6
const VIEW_ZOOM_STEP := 0.15
const GROUND_TILE_PATHS := {
	&"dirt": CAMP_TILE_ROOT + "dirt.png",
	&"dirt_alt": CAMP_TILE_ROOT + "dirt_alt.png",
	&"path": CAMP_TILE_ROOT + "path.png",
	&"path_light": CAMP_TILE_ROOT + "path_light.png",
	&"camp": CAMP_TILE_ROOT + "camp.png",
	&"grass": CAMP_TILE_ROOT + "grass.png",
	&"grass_alt": CAMP_TILE_ROOT + "grass_alt.png",
	&"grass_edge": CAMP_TILE_ROOT + "grass_edge.png",
	&"forest": CAMP_TILE_ROOT + "forest.png",
	&"forest_alt": CAMP_TILE_ROOT + "forest_alt.png",
	&"water": CAMP_TILE_ROOT + "mud.png",
	&"ash": CAMP_TILE_ROOT + "ash.png",
	&"cinder": CAMP_TILE_ROOT + "cinder.png",
	&"gravel": CAMP_TILE_ROOT + "gravel.png",
	&"weed_dirt": CAMP_TILE_ROOT + "weed_dirt.png",
	&"campfire_scorch": CAMP_TILE_ROOT + "campfire_scorch.png",
}
const TOWN_GROUND_TILE_PATHS := {
	&"dirt": TOWN_TILE_ROOT + "dirt.png",
	&"dirt_alt": TOWN_TILE_ROOT + "dirt_alt.png",
	&"path": TOWN_TILE_ROOT + "path.png",
	&"camp": TOWN_TILE_ROOT + "camp.png",
	&"yard": TOWN_TILE_ROOT + "yard.png",
	&"yard_alt": TOWN_TILE_ROOT + "yard_alt.png",
	&"grass": TOWN_TILE_ROOT + "grass.png",
	&"grass_alt": TOWN_TILE_ROOT + "grass_alt.png",
	&"forest": TOWN_TILE_ROOT + "forest.png",
	&"forest_alt": TOWN_TILE_ROOT + "forest_alt.png",
	&"water": TOWN_TILE_ROOT + "water.png",
	&"mud": TOWN_TILE_ROOT + "mud.png",
	&"gravel": TOWN_TILE_ROOT + "gravel.png",
	&"gravel_edge": TOWN_TILE_ROOT + "gravel_edge.png",
	&"ash": TOWN_TILE_ROOT + "ash.png",
	&"ash_edge": TOWN_TILE_ROOT + "ash_edge.png",
	&"cinder": TOWN_TILE_ROOT + "cinder.png",
	&"coal": TOWN_TILE_ROOT + "coal.png",
	&"packed_dirt": TOWN_TILE_ROOT + "packed_dirt.png",
	&"plank_path": TOWN_TILE_ROOT + "plank_path.png",
	&"plank_alt": TOWN_TILE_ROOT + "plank_alt.png",
	&"stone_dust": TOWN_TILE_ROOT + "stone_dust.png",
}
const OBJECT_TILE_PATHS := {
	&"tree": CAMP_TILE_ROOT + "brush_clump.png",
	&"bush": CAMP_TILE_ROOT + "brush_clump_alt.png",
	&"log": CAMP_TILE_ROOT + "woodpile.png",
	&"stump": CAMP_TILE_ROOT + "stump.png",
	&"rock": CAMP_TILE_ROOT + "rock_pile.png",
	&"dead_tree": CAMP_TILE_ROOT + "dead_tree.png",
	&"dead_tree_alt": CAMP_TILE_ROOT + "dead_tree_alt.png",
	&"small_tree": CAMP_TILE_ROOT + "small_tree.png",
	&"leafy_tree": CAMP_TILE_ROOT + "leafy_tree.png",
	&"snag_tree": CAMP_TILE_ROOT + "snag_tree.png",
	&"tree_pair": CAMP_TILE_ROOT + "tree_pair.png",
	&"stump_pair": CAMP_TILE_ROOT + "stump_pair.png",
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
	&"campfire_embers": CAMP_TILE_ROOT + "campfire_embers.png",
	&"coffee_setup": CAMP_TILE_ROOT + "coffee_setup.png",
	&"woodpile": CAMP_TILE_ROOT + "woodpile.png",
	&"bedroll": CAMP_TILE_ROOT + "bedroll.png",
	&"tarp_shelter": CAMP_TILE_ROOT + "tarp_shelter.png",
	&"lean_to": CAMP_TILE_ROOT + "tarp_shelter.png",
	&"tool_area": CAMP_TILE_ROOT + "tool_area.png",
	&"stash": CAMP_TILE_ROOT + "sack.png",
	&"crate": CAMP_TILE_ROOT + "crate.png",
	&"trail_sign": TOWN_OBJECT_ROOT + "camp_road_sign.png",
	&"wash_line": CAMP_TILE_ROOT + "wash_line.png",
	&"town_brush": CAMP_TILE_ROOT + "brush_clump_alt.png",
	&"town_jobs_board": TOWN_OBJECT_ROOT + "jobs_board.png",
	&"town_road_sign": TOWN_OBJECT_ROOT + "camp_road_sign.png",
	&"town_light": TOWN_OBJECT_ROOT + "street_lamp.png",
	&"town_trash": TOWN_OBJECT_ROOT + "trash_barrel.png",
	&"town_crate_stack": TOWN_OBJECT_ROOT + "crate_stack.png",
	&"town_board_stack": TOWN_OBJECT_ROOT + "board_stack.png",
	&"town_wheelbarrow": TOWN_OBJECT_ROOT + "wheelbarrow.png",
	&"town_handcart": TOWN_OBJECT_ROOT + "handcart.png",
	&"town_lantern_group": TOWN_OBJECT_ROOT + "lantern_group.png",
	&"town_church_building": TOWN_OBJECT_ROOT + "remittance_office.png",
	&"town_foreman_building": TOWN_OBJECT_ROOT + "depot_building.png",
	&"town_grocery_building": TOWN_OBJECT_ROOT + "hardware_store.png",
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
var view_zoom := 1.65
var _player_facing: StringName = &"front"
var _player_is_moving := false
var _occupied_tiles := {}
var _draw_sorted_objects: Array = []
var _interactable_hit_objects: Array = []
var _ground_textures := {}
var _town_ground_textures := {}
var _object_textures := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_load_ground_textures()


func _load_ground_textures() -> void:
	_ground_textures.clear()
	for tile_key in GROUND_TILE_PATHS.keys():
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(GROUND_TILE_PATHS[tile_key])))
		if image == null or image.is_empty():
			continue
		_ground_textures[tile_key] = ImageTexture.create_from_image(image)
	_town_ground_textures.clear()
	for tile_key in TOWN_GROUND_TILE_PATHS.keys():
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(TOWN_GROUND_TILE_PATHS[tile_key])))
		if image == null or image.is_empty():
			continue
		_town_ground_textures[tile_key] = ImageTexture.create_from_image(image)
	_object_textures.clear()
	for tile_key in OBJECT_TILE_PATHS.keys():
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(OBJECT_TILE_PATHS[tile_key])))
		if image == null or image.is_empty():
			continue
		_object_textures[tile_key] = ImageTexture.create_from_image(image)


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
	_draw_player()
	_draw_screen_fx()


func _draw_ground() -> void:
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
	var noise := _hash01(tile.x, tile.y)
	if tile.x < 2 or tile.y < 2 or tile.x > world_size.x - 3 or tile.y > world_size.y - 3:
		return &"forest_alt" if noise > 0.58 else (&"grass_alt" if noise > 0.34 else &"forest")
	if path_distance < 1.2 and distance_from_camp > 3.0:
		return &"path_light" if noise > 0.62 else &"path"
	if distance_from_camp <= 1.8:
		return &"campfire_scorch" if noise > 0.52 else &"ash"
	if distance_from_camp <= 4.5:
		return &"camp" if noise > 0.34 else (&"ash_edge" if noise > 0.16 else &"cinder")
	if distance_from_camp <= 7.5:
		if noise > 0.72:
			return &"weed_dirt"
		return &"dirt_alt" if noise > 0.52 else &"dirt"
	if distance_from_camp <= 10.5:
		return &"grass_edge" if noise > 0.66 else (&"grass_alt" if noise > 0.45 else &"grass")
	return &"forest_alt" if noise > 0.62 else (&"grass_alt" if noise > 0.36 else &"forest")


func _resolve_town_ground_tile_key(tile: Vector2i) -> StringName:
	var noise := _hash01(tile.x, tile.y)
	var main_street_y := camp_anchor.y + 3
	var cross_street_x := camp_anchor.x - 6
	var depot_street_x := camp_anchor.x + 10
	if tile.x < 2 or tile.y < 2 or tile.x > world_size.x - 3 or tile.y > world_size.y - 3:
		return &"forest_alt" if noise > 0.72 else (&"grass_alt" if noise > 0.42 else &"grass")
	if absi(tile.y - main_street_y) <= 2:
		if noise > 0.72:
			return &"mud"
		if noise < 0.08:
			return &"plank_path"
		return &"packed_dirt" if noise > 0.34 else &"path"
	if absi(tile.x - cross_street_x) <= 1 and tile.y > 6 and tile.y < world_size.y - 5:
		return &"path" if noise > 0.28 else &"yard"
	if absi(tile.x - depot_street_x) <= 1 and tile.y > 8 and tile.y < world_size.y - 7:
		return &"coal" if noise > 0.72 else (&"cinder" if noise > 0.38 else &"gravel")
	if tile.y < main_street_y - 4 and tile.x > 5 and tile.x < world_size.x - 6:
		return &"yard_alt" if noise > 0.64 else (&"dirt_alt" if noise < 0.12 else &"yard")
	return &"grass_alt" if noise > 0.58 else (&"gravel_edge" if noise < 0.08 else &"grass")


func _draw_world_objects() -> void:
	for world_object in _draw_sorted_objects:
		if world_object == null:
			continue
		if not _is_object_visible(world_object):
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


func _draw_player() -> void:
	var center = _world_to_screen(player_render_position)
	var texture: Texture2D = _object_textures.get(_get_player_texture_key(), null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 10.0)), 19.0, 8.0, 0.24)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-29.0, -91.0), Vector2(58.0, 94.0)), false)
		return
	_draw_shadow(center + _zv(Vector2(0.0, 10.0)), 15.0, 7.0, 0.28)
	draw_rect(_scaled_rect(center, Vector2(-5.0, -13.0), Vector2(10.0, 19.0)), Color("4f5e72"))
	draw_rect(_scaled_rect(center, Vector2(-7.0, -9.0), Vector2(4.0, 13.0)), Color("8a6e4c"))
	draw_rect(_scaled_rect(center, Vector2(3.0, -8.0), Vector2(5.0, 11.0)), Color("8a6e4c"))
	draw_rect(_scaled_rect(center, Vector2(-5.0, 6.0), Vector2(3.0, 10.0)), Color("3f3026"))
	draw_rect(_scaled_rect(center, Vector2(2.0, 6.0), Vector2(3.0, 10.0)), Color("3f3026"))
	draw_circle(center + _zv(Vector2(0.0, -18.0)), _zf(4.8), Color("c8a07f"))
	draw_rect(_scaled_rect(center, Vector2(-5.5, -24.0), Vector2(11.0, 3.0)), Color("5f4d36"))


func _update_player_facing(delta: Vector2) -> void:
	if delta.length() < 0.01:
		_player_is_moving = false
		return
	_player_is_moving = true
	var screen_delta := Vector2(delta.x - delta.y, delta.x + delta.y)
	if absf(screen_delta.x) > absf(screen_delta.y):
		_player_facing = &"side"
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


func _draw_campfire(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"campfire", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 13.0)), 42.0, 12.0, 0.24)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-29.0, -26.0), Vector2(58.0, 42.0)), false)
		draw_circle(center + _zv(Vector2(0.0, -4.0)), _zf(34.0), Color(1.0, 0.48, 0.14, 0.05))
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-32.0, -29.0), Vector2(64.0, 48.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 18.0)), 44.0, 18.0, 0.3)
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
	var texture: Texture2D = _object_textures.get(&"woodpile", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 14.0)), 34.0, 12.0, 0.2)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-28.0, -20.0), Vector2(56.0, 34.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-30.0, -22.0), Vector2(60.0, 39.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 14.0)), 34.0, 12.0, 0.24)
	for index in range(4):
		var offset = Vector2(-20.0 + float(index) * 10.0, -6.0 + float(index % 2) * 4.0)
		draw_rect(_scaled_rect(center, offset, Vector2(24.0, 7.0)), Color("7a5738"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-26.0, -16.0), Vector2(52.0, 34.0)))


func _draw_camp_dressing(world_object, texture_key: StringName, offset: Vector2, base_size: Vector2) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(texture_key, null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 10.0)), base_size.x * 0.64, 8.0, 0.14)
		draw_texture_rect(texture, _scaled_rect(center, offset, base_size), false)
	else:
		draw_rect(_scaled_rect(center, Vector2(-10.0, -14.0), Vector2(20.0, 18.0)), Color("6f5b42"))
	_draw_object_highlight(world_object, _scaled_rect(center, offset, base_size))


func _draw_bedroll(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position) + Vector2(0.35, 0.2))
	var texture: Texture2D = _object_textures.get(&"bedroll", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 16.0)), 42.0, 12.0, 0.2)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-28.0, -32.0), Vector2(56.0, 44.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-30.0, -34.0), Vector2(60.0, 48.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 16.0)), 42.0, 12.0, 0.22)
	draw_rect(_scaled_rect(center, Vector2(-28.0, -7.0), Vector2(42.0, 14.0)), Color("71614e"))
	draw_rect(_scaled_rect(center, Vector2(-31.0, -10.0), Vector2(15.0, 17.0)), Color("5a7088"))
	draw_rect(_scaled_rect(center, Vector2(10.0, -7.0), Vector2(8.0, 11.0)), Color("9a8566"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-34.0, -16.0), Vector2(55.0, 30.0)))


func _draw_stash(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position)) + _zv(Vector2(0.0, -10.0))
	var texture: Texture2D = _object_textures.get(&"stash", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 13.0)), 36.0, 10.0, 0.18)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-24.0, -28.0), Vector2(48.0, 36.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-26.0, -30.0), Vector2(52.0, 41.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 18.0)), 28.0, 10.0, 0.22)
	draw_rect(_scaled_rect(center, Vector2(-16.0, -6.0), Vector2(32.0, 20.0)), Color("4f6138"))
	draw_rect(_scaled_rect(center, Vector2(-11.0, -13.0), Vector2(22.0, 8.0)), Color("6d8446"))
	draw_rect(_scaled_rect(center, Vector2(-3.0, -2.0), Vector2(6.0, 4.0)), Color("d7c489"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-20.0, -18.0), Vector2(40.0, 35.0)))


func _draw_tool_area(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"tool_area", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 13.0)), 58.0, 12.0, 0.18)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-38.0, -26.0), Vector2(76.0, 36.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-40.0, -28.0), Vector2(80.0, 41.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 18.0)), 40.0, 14.0, 0.22)
	draw_rect(_scaled_rect(center, Vector2(-16.0, -5.0), Vector2(32.0, 14.0)), Color("6d5539"))
	draw_rect(_scaled_rect(center, Vector2(-3.0, -23.0), Vector2(6.0, 20.0)), Color("8a7760"))
	draw_colored_polygon(PackedVector2Array([
		center + _zv(Vector2(-2.0, -27.0)),
		center + _zv(Vector2(15.0, -14.0)),
		center + _zv(Vector2(10.0, -7.0)),
		center + _zv(Vector2(-7.0, -21.0))
	]), Color("8da0a8"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-24.0, -29.0), Vector2(48.0, 45.0)))


func _draw_trail_sign(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"trail_sign", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 13.0)), 24.0, 8.0, 0.16)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-15.0, -44.0), Vector2(30.0, 58.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-17.0, -46.0), Vector2(34.0, 63.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 18.0)), 20.0, 8.0, 0.2)
	draw_rect(_scaled_rect(center, Vector2(-2.0, -20.0), Vector2(4.0, 28.0)), Color("64492f"))
	draw_rect(_scaled_rect(center, Vector2(-18.0, -29.0), Vector2(36.0, 12.0)), Color("8e7351"))
	draw_rect(_scaled_rect(center, Vector2(-8.0, -26.0), Vector2(15.0, 3.0)), Color("5c4a32"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-20.0, -32.0), Vector2(40.0, 44.0)))


func _draw_tree(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture_key := _get_foliage_texture_key(world_object)
	var texture: Texture2D = _object_textures.get(texture_key, null)
	if texture != null:
		var draw_size := _get_foliage_draw_size(texture_key)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-draw_size.x * 0.5, -draw_size.y + 8.0), draw_size), false)
	else:
		draw_circle(center + _zv(Vector2(0.0, -10.0)), _zf(12.0), Color("29412a"))
		draw_rect(_scaled_rect(center, Vector2(-2.0, -3.0), Vector2(4.0, 18.0)), Color("4f3c26"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-18.0, -24.0), Vector2(36.0, 32.0)))


func _get_foliage_texture_key(world_object) -> StringName:
	if terrain_mode == &"town":
		return &"town_brush"
	var noise := _hash01(int(world_object.position.x), int(world_object.position.y))
	if noise > 0.992:
		return &"leafy_tree"
	if noise > 0.972:
		return &"dead_tree"
	if noise > 0.955:
		return &"small_tree"
	if noise > 0.90:
		return &"stump_pair"
	if noise > 0.76:
		return &"bush"
	return &"tree"


func _get_foliage_draw_size(texture_key: StringName) -> Vector2:
	match texture_key:
		&"leafy_tree":
			return Vector2(42.0, 46.0)
		&"dead_tree", &"dead_tree_alt", &"small_tree", &"snag_tree":
			return Vector2(36.0, 48.0)
		&"tree_pair":
			return Vector2(44.0, 42.0)
		&"stump_pair":
			return Vector2(32.0, 24.0)
		&"stump":
			return Vector2(28.0, 20.0)
		&"town_brush":
			return Vector2(24.0, 17.0)
		_:
			return Vector2(30.0, 20.0)


func _draw_tarp_shelter(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position) + Vector2(0.5, 0.3))
	var texture_key := &"lean_to" if String(world_object.id).find("lean_to") != -1 else &"tarp_shelter"
	var texture: Texture2D = _object_textures.get(texture_key, null)
	if texture != null:
		var draw_size := Vector2(132.0, 88.0) if texture_key == &"lean_to" else Vector2(150.0, 96.0)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-draw_size.x * 0.5, -82.0), draw_size), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-draw_size.x * 0.5 - 2.0, -84.0), draw_size + Vector2(4.0, 8.0)))
		return
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
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"log", null)
	if texture != null:
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-16.0, -18.0), Vector2(32.0, 32.0)), false)
	else:
		draw_rect(_scaled_rect(center, Vector2(-16.0, -4.0), Vector2(32.0, 8.0)), Color("7f5d3c"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-18.0, -18.0), Vector2(36.0, 34.0)))


func _draw_stump(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"stump", null)
	if texture != null:
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-16.0, -18.0), Vector2(32.0, 32.0)), false)
	else:
		draw_rect(_scaled_rect(center, Vector2(-6.0, -7.0), Vector2(12.0, 14.0)), Color("755438"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-16.0, -18.0), Vector2(32.0, 32.0)))


func _draw_crate(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"crate", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 11.0)), 28.0, 8.0, 0.16)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-18.0, -24.0), Vector2(36.0, 27.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-20.0, -26.0), Vector2(40.0, 32.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 14.0)), 24.0, 10.0, 0.16)
	draw_rect(_scaled_rect(center, Vector2(-12.0, -7.0), Vector2(24.0, 17.0)), Color("77563a"))
	draw_line(center + _zv(Vector2(-8.0, -5.0)), center + _zv(Vector2(-8.0, 8.0)), Color("5b4128"), _zf(2.0))
	draw_line(center + _zv(Vector2(0.0, -5.0)), center + _zv(Vector2(0.0, 8.0)), Color("5b4128"), _zf(2.0))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-15.0, -12.0), Vector2(30.0, 26.0)))


func _draw_wash_line(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(&"wash_line", null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 18.0)), 56.0, 10.0, 0.15)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-52.0, -44.0), Vector2(104.0, 50.0)), false)
		_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-54.0, -46.0), Vector2(108.0, 55.0)))
		return
	_draw_shadow(center + _zv(Vector2(0.0, 18.0)), 42.0, 10.0, 0.15)
	draw_line(center + _zv(Vector2(-24.0, -16.0)), center + _zv(Vector2(-24.0, 16.0)), Color("674a32"), _zf(3.0))
	draw_line(center + _zv(Vector2(24.0, -13.0)), center + _zv(Vector2(24.0, 18.0)), Color("674a32"), _zf(3.0))
	draw_line(center + _zv(Vector2(-22.0, -11.0)), center + _zv(Vector2(22.0, -9.0)), Color("7b6a4c"), _zf(2.0))
	draw_rect(_scaled_rect(center, Vector2(-5.0, -7.0), Vector2(12.0, 21.0)), Color("8f8061"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-29.0, -22.0), Vector2(58.0, 43.0)))


func _draw_generic_object(world_object) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	draw_rect(_scaled_rect(center, Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), Color("7c6a55"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-16.0, -16.0), Vector2(32.0, 32.0)))


func _draw_assigned_town_building(world_object, texture_key: StringName, label: String, scale: float) -> void:
	var center = _world_to_screen(Vector2(world_object.position) + Vector2(1.0, 0.7))
	var texture: Texture2D = _object_textures.get(texture_key, null)
	if texture == null:
		_draw_town_building_base(center, Vector2(96.0, 76.0), Color("5a5345"), Color("332b22"), false)
		_draw_town_label(center + _zv(Vector2(0.0, -82.0)), label, Color("efe1c0"))
		_draw_object_highlight(world_object, _get_town_building_rect(world_object))
		return
	var draw_size = texture.get_size() * scale
	_draw_shadow(center + _zv(Vector2(0.0, 12.0)), draw_size.x * 0.68, 14.0, 0.16)
	draw_texture_rect(texture, _scaled_rect(center, Vector2(-draw_size.x * 0.5, -draw_size.y + 8.0), draw_size), false)
	_draw_object_highlight(world_object, _get_town_building_rect(world_object))


func _draw_town_building_base(center: Vector2, base_size: Vector2, wall_color: Color, roof_color: Color, cross: bool) -> void:
	_draw_shadow(center + _zv(Vector2(0.0, 28.0)), base_size.x, 24.0, 0.22)
	draw_rect(_scaled_rect(center, Vector2(-base_size.x * 0.5, -54.0), Vector2(base_size.x, base_size.y)), wall_color)
	draw_rect(_scaled_rect(center, Vector2(-base_size.x * 0.58, -70.0), Vector2(base_size.x * 1.16, 18.0)), roof_color)
	draw_rect(_scaled_rect(center, Vector2(-28.0, -22.0), Vector2(18.0, 28.0)), Color("2b2722"))
	draw_rect(_scaled_rect(center, Vector2(12.0, -34.0), Vector2(18.0, 18.0)), Color("87939b"))
	if cross:
		draw_line(center + _zv(Vector2(0.0, -94.0)), center + _zv(Vector2(0.0, -64.0)), Color("d8cba5"), _zf(3.0))
		draw_line(center + _zv(Vector2(-10.0, -82.0)), center + _zv(Vector2(10.0, -82.0)), Color("d8cba5"), _zf(3.0))


func _draw_town_sign_object(world_object, label: String, post_color: Color, texture_key: StringName) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(texture_key, null)
	_draw_shadow(center + _zv(Vector2(0.0, 14.0)), 34.0, 9.0, 0.16)
	if texture != null:
		var draw_size := Vector2(44.0, 50.0) if texture_key == &"town_jobs_board" else Vector2(47.0, 54.0)
		draw_texture_rect(texture, _scaled_rect(center, Vector2(-draw_size.x * 0.5, -draw_size.y + 12.0), draw_size), false)
	else:
		draw_rect(_scaled_rect(center, Vector2(-24.0, -35.0), Vector2(48.0, 22.0)), post_color)
		draw_rect(_scaled_rect(center, Vector2(-2.0, -12.0), Vector2(4.0, 24.0)), post_color.darkened(0.2))
		_draw_town_label(center + _zv(Vector2(0.0, -32.0)), label, Color("f0dfb8"))
	_draw_object_highlight(world_object, _scaled_rect(center, Vector2(-28.0, -40.0), Vector2(56.0, 56.0)))


func _draw_town_prop(world_object, texture_key: StringName, offset: Vector2, base_size: Vector2) -> void:
	var center = _world_to_screen(Vector2(world_object.position))
	var texture: Texture2D = _object_textures.get(texture_key, null)
	if texture != null:
		_draw_shadow(center + _zv(Vector2(0.0, 10.0)), base_size.x * 0.72, 8.0, 0.14)
		draw_texture_rect(texture, _scaled_rect(center, offset, base_size), false)
	else:
		draw_rect(_scaled_rect(center, Vector2(-8.0, -22.0), Vector2(16.0, 30.0)), Color("6b6658"))
	_draw_object_highlight(world_object, _scaled_rect(center, offset, base_size))


func _draw_town_label(center: Vector2, label: String, color: Color) -> void:
	var font = get_theme_default_font()
	if font == null:
		return
	var font_size := int(maxf(8.0, 11.0 * view_zoom))
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var label_rect = Rect2(center - Vector2(text_size.x * 0.5 + 5.0, text_size.y * 0.5 + 3.0), text_size + Vector2(10.0, 6.0))
	draw_rect(label_rect, Color(0.08, 0.07, 0.05, 0.82), true)
	draw_string(font, center + Vector2(-text_size.x * 0.5, text_size.y * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_object_highlight(world_object, rect: Rect2) -> void:
	if world_object.id != active_object_id and world_object.id != hovered_object_id:
		return
	var color = Color("f4d78a") if world_object.id == active_object_id else Color("a7c6d9")
	draw_rect(rect, color, false, 2.0)


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
	var center = _world_to_screen(Vector2(world_object.position))
	match String(world_object.type):
		"campfire":
			return _scaled_rect(center, Vector2(-32.0, -29.0), Vector2(64.0, 48.0))
		"woodpile":
			return _scaled_rect(center, Vector2(-30.0, -22.0), Vector2(60.0, 39.0))
		"bedroll":
			return _scaled_rect(center, Vector2(-34.0, -16.0), Vector2(55.0, 30.0))
		"stash":
			return _scaled_rect(center + _zv(Vector2(0.0, -10.0)), Vector2(-20.0, -26.0), Vector2(40.0, 39.0))
		"tool_area":
			return _scaled_rect(center, Vector2(-40.0, -28.0), Vector2(80.0, 41.0))
		"trail_sign":
			return _scaled_rect(center, Vector2(-17.0, -46.0), Vector2(34.0, 63.0))
		"tree":
			return _scaled_rect(center, Vector2(-18.0, -24.0), Vector2(36.0, 32.0))
		"tarp_shelter":
			return _scaled_rect(_world_to_screen(Vector2(world_object.position) + Vector2(0.5, 0.3)), Vector2(-77.0, -54.0), Vector2(154.0, 66.0))
		"crate":
			return _scaled_rect(center, Vector2(-20.0, -26.0), Vector2(40.0, 32.0))
		"wash_line":
			return _scaled_rect(center, Vector2(-54.0, -46.0), Vector2(108.0, 55.0))
		"town_church", "town_foreman", "town_grocery", "town_hardware":
			return _get_town_building_rect(world_object)
		"town_jobs_board", "town_road_exit":
			return _scaled_rect(center, Vector2(-24.0, -42.0), Vector2(48.0, 54.0))
		_:
			return _scaled_rect(center, Vector2(-18.0, -18.0), Vector2(36.0, 36.0))


func _get_town_building_rect(world_object) -> Rect2:
	var center = _world_to_screen(Vector2(world_object.position) + Vector2(1.0, 0.7))
	return _scaled_rect(center, Vector2(-58.0, -94.0), Vector2(116.0, 106.0))


func _scaled_rect(center: Vector2, offset: Vector2, base_size: Vector2) -> Rect2:
	return Rect2(center + _zv(offset), base_size * view_zoom)


func _zv(value: Vector2) -> Vector2:
	return value * view_zoom


func _zf(value: float) -> float:
	return value * view_zoom


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
