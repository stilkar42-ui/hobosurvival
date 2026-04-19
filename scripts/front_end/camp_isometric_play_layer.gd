extends Control

const CampWorldObjectScript := preload("res://scripts/front_end/camp_world_object.gd")

const INVENTORY_UI_PAGE := &"inventory_ui"
const WORLD_BOUNDS := Rect2i(0, 0, 72, 72)
const CAMP_CENTER := Vector2i(36, 34)
const PLAYER_START_TILE := Vector2i(33, 37)
const CAMERA_DEADZONE_HALF_SIZE := Vector2(156.0, 96.0)

signal interaction_activated(route_id: StringName, action_id: StringName, page_id: StringName)
signal overlay_action_requested(command: Dictionary)

@onready var world_view = $WorldView
@onready var ground_tilemap = $GroundTileMap
@onready var hud_panel = $HudPanel
@onready var hud_title_label = $HudPanel/HudRoot/HudTitle
@onready var hud_meta_label = $HudPanel/HudRoot/HudMeta
@onready var hud_stats_grid = $HudPanel/HudRoot/HudStatsGrid
@onready var hover_chip = $HoverChip
@onready var hover_chip_label = $HoverChip/HoverChipRoot/HoverChipLabel
@onready var interaction_card = $InteractionCard
@onready var interaction_title_bar = $InteractionCard/InteractionRoot/InteractionTitleBar
@onready var interaction_badge = $InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionBadge
@onready var interaction_badge_label = $InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionBadge/InteractionBadgeLabel
@onready var interaction_title_label = $InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionTitleText/InteractionTitle
@onready var interaction_subtitle_label = $InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionTitleText/InteractionSubtitle
@onready var interaction_detail_label = $InteractionCard/InteractionRoot/InteractionDetail
@onready var interaction_action_button = $InteractionCard/InteractionRoot/InteractionActionButton
@onready var interaction_close_button = $InteractionCard/InteractionRoot/InteractionTitleBar/InteractionTitleBarRoot/InteractionCloseButton
@onready var interaction_section_scroll = $InteractionCard/InteractionRoot/InteractionSectionScroll
@onready var interaction_section_list = $InteractionCard/InteractionRoot/InteractionSectionScroll/InteractionSectionList
@onready var player_controller = $PlayerController
@onready var interaction_system = $InteractionSystem
@onready var prompt_panel = $PromptPanel
@onready var prompt_title_label = $PromptPanel/PromptRoot/PromptTitle
@onready var prompt_detail_label = $PromptPanel/PromptRoot/PromptDetail

var _world_objects: Array = []
var _interaction_by_route := {}
var _pending_interaction_object_id: StringName = &""
var _input_enabled := true
var _blocked_tiles_cache := {}
var _hud_stat_rows := {}
var _world_object_by_id := {}
var _held_move_keys := {}
var _active_prompt_object_id: StringName = &""
var _active_prompt_title := ""
var _active_prompt_detail := ""
var _overlay_models_by_route := {}
var _active_overlay_object_id: StringName = &""
var _hovered_object_id: StringName = &""
var _interaction_card_dragging := false
var _interaction_card_drag_offset := Vector2.ZERO
var _interaction_card_has_manual_position := false
var _camera_render_position := Vector2(PLAYER_START_TILE)


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	_configure_hud()
	_configure_interaction_card()
	if has_signal("resized"):
		resized.connect(Callable(self, "_sync_ground_tilemap_view"))
	_connect_runtime_nodes()
	_build_default_camp()
	set_input_enabled(true)


func set_interactions(interactions: Array) -> void:
	_interaction_by_route.clear()
	for interaction in interactions:
		if interaction is Dictionary:
			var route_id = StringName(interaction.get("route_id", &""))
			if route_id != &"":
				_interaction_by_route[route_id] = interaction.duplicate(true)
	if not is_node_ready():
		return
	_apply_interaction_overrides()
	_sync_runtime_state()


func set_contextual_overlay_models(overlay_models: Dictionary) -> void:
	_overlay_models_by_route.clear()
	for route_id in overlay_models.keys():
		var route_key := StringName(route_id)
		if route_key == &"":
			continue
		var overlay_model = overlay_models.get(route_id, {})
		if overlay_model is Dictionary:
			_overlay_models_by_route[route_key] = overlay_model.duplicate(true)
	if not is_node_ready():
		return
	_interaction_card_visibility_refresh()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if player_controller != null and player_controller.has_method("set_input_enabled"):
		player_controller.set_input_enabled(enabled)
	prompt_panel.modulate = Color(1, 1, 1, 1) if enabled else Color(0.72, 0.72, 0.72, 0.92)
	if player_controller != null and player_controller.has_method("set_intent_direction"):
		player_controller.set_intent_direction(Vector2i.ZERO)
	if not enabled:
		_held_move_keys.clear()
		_clear_contextual_overlay()
	_interaction_card_visibility_refresh()


func _process(_delta: float) -> void:
	if not _input_enabled or not visible:
		return
	if player_controller != null and player_controller.has_method("set_intent_direction"):
		player_controller.set_intent_direction(_get_screen_relative_step_from_held_keys())
	_position_hover_chip()
	_position_interaction_card()


func set_hud_snapshot(snapshot: Dictionary) -> void:
	if hud_title_label == null or hud_meta_label == null:
		return
	hud_title_label.text = String(snapshot.get("title", "Camp Condition"))
	hud_meta_label.text = String(snapshot.get("summary", "Camp routine status will appear here."))
	for stat in snapshot.get("stats", []):
		if not (stat is Dictionary):
			continue
		_set_hud_stat(
			StringName(stat.get("id", &"")),
			String(stat.get("label", "")),
			int(stat.get("value", 0)),
			int(stat.get("max", 100))
		)


func _configure_hud() -> void:
	if hud_panel == null:
		return
	_apply_hud_panel_style()
	for stat_id in [&"nutrition", &"stamina", &"warmth", &"morale", &"hygiene", &"presentability"]:
		var row = _build_hud_stat_row()
		hud_stats_grid.add_child(row)
		_hud_stat_rows[stat_id] = row
	_set_hud_stat(&"nutrition", "Nutrition", 0, 100)
	_set_hud_stat(&"stamina", "Stamina", 0, 100)
	_set_hud_stat(&"warmth", "Warmth", 0, 100)
	_set_hud_stat(&"morale", "Morale", 0, 100)
	_set_hud_stat(&"hygiene", "Hygiene", 0, 100)
	_set_hud_stat(&"presentability", "Presentability", 0, 100)
	_configure_hover_chip()


func _build_hud_stat_row() -> VBoxContainer:
	var row = VBoxContainer.new()
	row.custom_minimum_size = Vector2(162.0, 0.0)
	row.add_theme_constant_override("separation", 2)
	var label = Label.new()
	label.name = "StatLabel"
	label.modulate = Color("e8dcc6")
	row.add_child(label)
	var bar = ProgressBar.new()
	bar.name = "StatBar"
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _make_hud_bar_style(Color("14120f"), Color("4b4033"), 1, 4))
	row.add_child(bar)
	return row


func _set_hud_stat(stat_id: StringName, label_text: String, current_value: int, max_value: int) -> void:
	var row = _hud_stat_rows.get(stat_id, null)
	if row == null:
		return
	var label: Label = row.get_node("StatLabel")
	var bar: ProgressBar = row.get_node("StatBar")
	var clamped_value = clampi(current_value, 0, max(max_value, 1))
	label.text = "%s %d / %d" % [label_text, clamped_value, max(max_value, 1)]
	bar.max_value = max(max_value, 1)
	bar.value = clamped_value
	bar.add_theme_stylebox_override("fill", _make_hud_bar_style(_get_hud_bar_color(float(bar.value) / float(bar.max_value)), Color(0.0, 0.0, 0.0, 0.0), 0, 4))


func _apply_hud_panel_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.10, 0.09, 0.86)
	style.border_color = Color("6f5d47")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	hud_panel.add_theme_stylebox_override("panel", style)


func _make_hud_bar_style(bg: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style


func _get_hud_bar_color(ratio: float) -> Color:
	if ratio <= 0.25:
		return Color("9a4e3f")
	if ratio <= 0.50:
		return Color("a17b43")
	return Color("6f8857")


func _configure_interaction_card() -> void:
	if interaction_card == null:
		return
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.09, 0.94)
	style.border_color = Color("7d6748")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	interaction_card.add_theme_stylebox_override("panel", style)
	interaction_action_button.custom_minimum_size = Vector2(0.0, 42.0)
	interaction_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interaction_action_button.pressed.connect(Callable(self, "_on_interaction_card_pressed"))
	interaction_close_button.custom_minimum_size = Vector2(0.0, 38.0)
	interaction_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interaction_close_button.pressed.connect(Callable(self, "_on_interaction_close_pressed"))
	if interaction_title_bar != null:
		interaction_title_bar.gui_input.connect(Callable(self, "_on_interaction_title_bar_gui_input"))
		var title_bar_style = StyleBoxFlat.new()
		title_bar_style.bg_color = Color(0.19, 0.16, 0.12, 0.98)
		title_bar_style.corner_radius_top_left = 8
		title_bar_style.corner_radius_top_right = 8
		title_bar_style.corner_radius_bottom_left = 4
		title_bar_style.corner_radius_bottom_right = 4
		title_bar_style.content_margin_left = 8
		title_bar_style.content_margin_top = 8
		title_bar_style.content_margin_right = 8
		title_bar_style.content_margin_bottom = 8
		interaction_title_bar.add_theme_stylebox_override("panel", title_bar_style)
	if interaction_badge != null:
		var badge_style = StyleBoxFlat.new()
		badge_style.bg_color = Color(0.29, 0.22, 0.14, 1.0)
		badge_style.corner_radius_top_left = 6
		badge_style.corner_radius_top_right = 6
		badge_style.corner_radius_bottom_left = 6
		badge_style.corner_radius_bottom_right = 6
		badge_style.content_margin_left = 6
		badge_style.content_margin_top = 6
		badge_style.content_margin_right = 6
		badge_style.content_margin_bottom = 6
		interaction_badge.add_theme_stylebox_override("panel", badge_style)
	interaction_card.visible = false


func _configure_hover_chip() -> void:
	if hover_chip == null:
		return
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.07, 0.90)
	style.border_color = Color("7d6748")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	hover_chip.add_theme_stylebox_override("panel", style)
	hover_chip.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_clear_contextual_overlay()
				get_viewport().set_input_as_handled()
			KEY_E:
				interaction_system.request_active_interaction()
				get_viewport().set_input_as_handled()
			KEY_UP, KEY_W, KEY_DOWN, KEY_S, KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D:
				_set_move_key_state(event.keycode, true)
				if _attempt_held_movement_step():
					get_viewport().set_input_as_handled()
	if event is InputEventKey and not event.pressed:
		match event.keycode:
			KEY_UP, KEY_W, KEY_DOWN, KEY_S, KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D:
				_set_move_key_state(event.keycode, false)


func _connect_runtime_nodes() -> void:
	world_view.tile_clicked.connect(Callable(self, "_on_tile_clicked"))
	world_view.object_clicked.connect(Callable(self, "_on_object_clicked"))
	world_view.hovered_object_changed.connect(Callable(self, "_on_hovered_object_changed"))
	player_controller.position_changed.connect(Callable(self, "_on_player_position_changed"))
	player_controller.render_position_changed.connect(Callable(self, "_on_player_render_position_changed"))
	interaction_system.prompt_changed.connect(Callable(self, "_on_prompt_changed"))
	interaction_system.interaction_requested.connect(Callable(self, "_on_interaction_requested"))


func _build_default_camp() -> void:
	_world_objects = [
		CampWorldObjectScript.new({
			"id": &"campfire",
			"position": CAMP_CENTER,
			"type": &"campfire",
			"interaction_type": &"page",
			"route_id": &"cooking",
			"display_name": "Campfire",
			"prompt_action": "Cook",
			"page_id": &"cooking",
			"detail_text": "The fire is the center of camp life: heat, boiled water, and food that gives tomorrow a chance."
		}),
		CampWorldObjectScript.new({
			"id": &"woodpile",
			"position": CAMP_CENTER + Vector2i(-4, 0),
			"type": &"woodpile",
			"interaction_type": &"action",
			"route_id": &"fire",
			"display_name": "Woodpile",
			"prompt_action": "Build the Fire",
			"detail_text": "Fuel is the difference between shelter and exposure."
		}),
		CampWorldObjectScript.new({
			"id": &"bedroll",
			"position": CAMP_CENTER + Vector2i(-4, 4),
			"type": &"bedroll",
			"interaction_type": &"action",
			"route_id": &"rest",
			"display_name": "Bedroll",
			"prompt_action": "Rest",
			"action_id": &"sleep_rough",
			"size_tiles": Vector2i(2, 1),
			"detail_text": "Rough rest is still relief earned with preparation."
		}),
		CampWorldObjectScript.new({
			"id": &"stash",
			"position": CAMP_CENTER + Vector2i(4, 3),
			"type": &"stash",
			"interaction_type": &"ui",
			"route_id": &"stash",
			"display_name": "Ground Stash",
			"prompt_action": "Open the Stash",
			"page_id": INVENTORY_UI_PAGE,
			"detail_text": "What you carry is never abstract. Weight, space, and order decide the next day."
		}),
		CampWorldObjectScript.new({
			"id": &"tool_area",
			"position": CAMP_CENTER + Vector2i(5, -2),
			"type": &"tool_area",
			"interaction_type": &"page",
			"route_id": &"craft",
			"display_name": "Tool Area",
			"prompt_action": "Craft",
			"page_id": &"hobocraft",
			"detail_text": "Camp craft is repair, patching, and staying usable."
		}),
		CampWorldObjectScript.new({
			"id": &"trail_sign",
			"position": CAMP_CENTER + Vector2i(10, -9),
			"type": &"trail_sign",
			"interaction_type": &"action",
			"route_id": &"exit",
			"display_name": "Path to Town",
			"prompt_action": "Leave for Town",
			"detail_text": "The town is back down the path: wages, errands, scrutiny, and noise."
		}),
		CampWorldObjectScript.new({"id": &"lean_to_w", "position": CAMP_CENTER + Vector2i(-8, -3), "type": &"tarp_shelter", "interaction_type": &"", "display_name": "Lean-to", "size_tiles": Vector2i(3, 2), "is_interactable": false}),
		CampWorldObjectScript.new({"id": &"lean_to_e", "position": CAMP_CENTER + Vector2i(5, -6), "type": &"tarp_shelter", "interaction_type": &"", "display_name": "Lean-to", "size_tiles": Vector2i(3, 2), "is_interactable": false}),
		CampWorldObjectScript.new({"id": &"log_sw", "position": CAMP_CENTER + Vector2i(-7, 6), "type": &"log", "interaction_type": &"", "display_name": "Log Seat", "is_interactable": false}),
		CampWorldObjectScript.new({"id": &"log_s", "position": CAMP_CENTER + Vector2i(1, 8), "type": &"log", "interaction_type": &"", "display_name": "Log Seat", "is_interactable": false}),
		CampWorldObjectScript.new({"id": &"stump_s", "position": CAMP_CENTER + Vector2i(-1, 7), "type": &"stump", "interaction_type": &"", "display_name": "Stump", "is_interactable": false}),
		CampWorldObjectScript.new({"id": &"crate_e", "position": CAMP_CENTER + Vector2i(7, 2), "type": &"crate", "interaction_type": &"", "display_name": "Crate", "is_interactable": false}),
		CampWorldObjectScript.new({
			"id": &"wash_line",
			"position": CAMP_CENTER + Vector2i(8, -4),
			"type": &"wash_line",
			"interaction_type": &"page",
			"route_id": &"ready",
			"display_name": "Wash Line",
			"prompt_action": "Get Ready",
			"page_id": &"getting_ready",
			"size_tiles": Vector2i(2, 1),
			"detail_text": "A place to wash, air out clothes, and put yourself back together before facing other people."
		})
	]
	_add_environment_ring()
	_rebuild_world_object_cache()
	_apply_interaction_overrides()
	player_controller.set_grid_position(PLAYER_START_TILE)
	_sync_runtime_state()


func _add_environment_ring() -> void:
	for y in range(WORLD_BOUNDS.size.y):
		for x in range(WORLD_BOUNDS.size.x):
			var tile = Vector2i(x, y)
			if Vector2(tile - CAMP_CENTER).length() < 10.0:
				continue
			if not _is_tree_tile(tile):
				continue
			_world_objects.append(CampWorldObjectScript.new({
				"id": StringName("tree_%d_%d" % [x, y]),
				"position": tile,
				"type": &"tree",
				"interaction_type": &"",
				"display_name": "Pine",
				"is_interactable": false
			}))


func _is_tree_tile(tile: Vector2i) -> bool:
	if tile.x < 2 or tile.y < 2 or tile.x > WORLD_BOUNDS.size.x - 3 or tile.y > WORLD_BOUNDS.size.y - 3:
		return true
	var distance_from_camp = Vector2(tile - CAMP_CENTER).length()
	if distance_from_camp < 10.0:
		return false
	var path_distance = _distance_to_path(Vector2(tile), Vector2(CAMP_CENTER), Vector2(CAMP_CENTER + Vector2i(11, -10)))
	if path_distance < 1.4 and distance_from_camp < 16.0:
		return false
	var hash = _hash01(tile.x, tile.y)
	return hash > 0.76 or (distance_from_camp > 18.0 and hash > 0.52)


func _apply_interaction_overrides() -> void:
	for world_object in _world_objects:
		if world_object == null or world_object.route_id == &"" or not _interaction_by_route.has(world_object.route_id):
			_apply_default_object_binding(world_object)
			continue
		var interaction: Dictionary = _interaction_by_route.get(world_object.route_id, {})
		world_object.action_id = StringName(interaction.get("action_id", world_object.action_id))
		world_object.page_id = StringName(interaction.get("page_id", world_object.page_id))
		world_object.detail_text = String(interaction.get("consequence_text", world_object.detail_text))
		world_object.prompt_action = _resolve_prompt_action(world_object.route_id, String(interaction.get("label", world_object.prompt_action)))


func _apply_default_object_binding(world_object) -> void:
	if world_object == null:
		return
	match world_object.route_id:
		&"rest":
			world_object.action_id = &"sleep_rough"
			world_object.page_id = &""
		&"craft":
			world_object.page_id = &"hobocraft"
		&"cooking":
			world_object.page_id = &"cooking"
		&"exit":
			world_object.action_id = &"return_to_town"
		&"stash":
			world_object.page_id = INVENTORY_UI_PAGE
		&"ready":
			world_object.page_id = &"getting_ready"


func _resolve_prompt_action(route_id: StringName, label: String) -> String:
	match route_id:
		&"fire":
			return "Build the Fire" if label.find("Tend") == -1 else "Tend the Fire"
		&"rest":
			return "Rest"
		&"craft":
			return "Craft"
		&"cooking":
			return "Cook"
		&"exit":
			return "Leave for Town"
		&"stash":
			return "Open the Stash"
		&"ready":
			return "Get Ready"
		_:
			return label


func _sync_runtime_state() -> void:
	_rebuild_world_object_cache()
	if ground_tilemap != null and ground_tilemap.has_method("setup_ground"):
		ground_tilemap.setup_ground(WORLD_BOUNDS, CAMP_CENTER)
		world_view.set_draw_ground_layer(false)
	world_view.set_world_size(WORLD_BOUNDS.size)
	world_view.set_world_objects(_world_objects)
	world_view.set_camp_anchor(CAMP_CENTER)
	world_view.set_player_grid_position(player_controller.grid_position)
	world_view.set_player_render_position(player_controller.render_position)
	_camera_render_position = player_controller.render_position
	world_view.set_camera_render_position(_camera_render_position)
	_rebuild_blocked_tiles_cache()
	player_controller.set_navigation_data(WORLD_BOUNDS, _blocked_tiles_cache)
	interaction_system.set_world_objects(_world_objects)
	interaction_system.set_player_grid_position(player_controller.grid_position)
	_sync_ground_tilemap_view()
	_interaction_card_visibility_refresh()


func _collect_blocked_tiles() -> Dictionary:
	var blocked := {}
	for world_object in _world_objects:
		if world_object == null or not world_object.blocks_movement:
			continue
		for tile in world_object.get_occupied_tiles():
			blocked[_tile_key(tile)] = true
	blocked.erase(_tile_key(player_controller.grid_position))
	return blocked


func _rebuild_blocked_tiles_cache() -> void:
	_blocked_tiles_cache = _collect_blocked_tiles()


func _attempt_step(direction: Vector2i) -> void:
	if player_controller.request_step(direction):
		_pending_interaction_object_id = &""
		get_viewport().set_input_as_handled()


func _attempt_held_movement_step() -> bool:
	var direction = _get_screen_relative_step_from_held_keys()
	if direction == Vector2i.ZERO:
		return false
	if player_controller != null and player_controller.has_method("set_intent_direction"):
		player_controller.set_intent_direction(direction)
	if player_controller.request_step(direction):
		_pending_interaction_object_id = &""
		return true
	return false


func _on_tile_clicked(grid_position: Vector2i) -> void:
	_pending_interaction_object_id = &""
	_clear_contextual_overlay()
	player_controller.request_path_to(grid_position)
	grab_focus()


func _on_object_clicked(object_id: StringName) -> void:
	grab_focus()
	if interaction_system.is_player_adjacent_to_object(object_id):
		_pending_interaction_object_id = &""
		interaction_system.request_object_interaction(object_id)
		return
	var candidates = interaction_system.get_interaction_tiles(object_id)
	candidates.sort_custom(func(a, b):
		var a_distance = absi(player_controller.grid_position.x - int(a.x)) + absi(player_controller.grid_position.y - int(a.y))
		var b_distance = absi(player_controller.grid_position.x - int(b.x)) + absi(player_controller.grid_position.y - int(b.y))
		return a_distance < b_distance
	)
	for candidate in candidates:
		if not WORLD_BOUNDS.has_point(candidate):
			continue
		if player_controller.request_path_to(candidate):
			_pending_interaction_object_id = object_id
			return


func _on_player_position_changed(grid_position: Vector2i) -> void:
	world_view.set_player_grid_position(grid_position)
	player_controller.set_navigation_data(WORLD_BOUNDS, _blocked_tiles_cache)
	interaction_system.set_player_grid_position(grid_position)
	if _active_overlay_object_id != &"" and not interaction_system.is_player_adjacent_to_object(_active_overlay_object_id):
		_clear_contextual_overlay()
	if _pending_interaction_object_id != &"" and interaction_system.is_player_adjacent_to_object(_pending_interaction_object_id):
		var pending_object_id = _pending_interaction_object_id
		_pending_interaction_object_id = &""
		interaction_system.request_object_interaction(pending_object_id)
	_refresh_hover_chip()
	_interaction_card_visibility_refresh()


func _on_player_render_position_changed(render_position: Vector2) -> void:
	world_view.set_player_render_position(render_position)
	_update_camera_render_position(render_position)
	_sync_ground_tilemap_view()
	_position_hover_chip()
	_position_interaction_card()


func _on_prompt_changed(title: String, detail: String, object_id: StringName) -> void:
	prompt_title_label.text = title
	prompt_detail_label.text = detail
	world_view.set_active_object_id(object_id)
	_active_prompt_object_id = object_id
	_active_prompt_title = title
	_active_prompt_detail = detail
	if object_id != _active_overlay_object_id and not interaction_system.is_player_adjacent_to_object(_active_overlay_object_id):
		_clear_contextual_overlay()
	_refresh_hover_chip()
	_interaction_card_visibility_refresh()


func _on_hovered_object_changed(object_id: StringName) -> void:
	_hovered_object_id = object_id
	_refresh_hover_chip()


func _on_interaction_requested(payload: Dictionary) -> void:
	var object_id := StringName(payload.get("id", &""))
	var route_id := StringName(payload.get("route_id", &""))
	if _has_contextual_overlay(route_id):
		_open_contextual_overlay(object_id)
		return
	_clear_contextual_overlay()
	interaction_activated.emit(
		route_id,
		StringName(payload.get("action_id", &"")),
		StringName(payload.get("page_id", &""))
	)


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


func _sync_ground_tilemap_view() -> void:
	if ground_tilemap == null or not ground_tilemap.has_method("sync_to_player"):
		return
	ground_tilemap.sync_to_player(player_controller.render_position, size, _camera_render_position)


func _update_camera_render_position(render_position: Vector2, force_center: bool = false) -> void:
	if world_view == null:
		_camera_render_position = render_position
		return
	if force_center:
		_camera_render_position = render_position
		world_view.set_camera_render_position(_camera_render_position)
		return
	var player_screen_position = world_view.get_screen_position_for_grid(render_position)
	var screen_center = size * 0.5
	var overflow = Vector2.ZERO
	if player_screen_position.x < screen_center.x - CAMERA_DEADZONE_HALF_SIZE.x:
		overflow.x = player_screen_position.x - (screen_center.x - CAMERA_DEADZONE_HALF_SIZE.x)
	elif player_screen_position.x > screen_center.x + CAMERA_DEADZONE_HALF_SIZE.x:
		overflow.x = player_screen_position.x - (screen_center.x + CAMERA_DEADZONE_HALF_SIZE.x)
	if player_screen_position.y < screen_center.y - CAMERA_DEADZONE_HALF_SIZE.y:
		overflow.y = player_screen_position.y - (screen_center.y - CAMERA_DEADZONE_HALF_SIZE.y)
	elif player_screen_position.y > screen_center.y + CAMERA_DEADZONE_HALF_SIZE.y:
		overflow.y = player_screen_position.y - (screen_center.y + CAMERA_DEADZONE_HALF_SIZE.y)
	if overflow == Vector2.ZERO:
		return
	_camera_render_position += _screen_offset_to_world_delta(overflow)
	world_view.set_camera_render_position(_camera_render_position)


func _screen_offset_to_world_delta(screen_offset: Vector2) -> Vector2:
	var dx = screen_offset.x / 36.0
	var dy = screen_offset.y / 18.0
	return Vector2(
		(dy + dx) * 0.5,
		(dy - dx) * 0.5
	)


func _rebuild_world_object_cache() -> void:
	_world_object_by_id.clear()
	for world_object in _world_objects:
		if world_object == null:
			continue
		_world_object_by_id[world_object.id] = world_object


func _set_move_key_state(keycode: Key, pressed: bool) -> void:
	match keycode:
		KEY_W, KEY_UP:
			_held_move_keys[&"up"] = pressed
		KEY_S, KEY_DOWN:
			_held_move_keys[&"down"] = pressed
		KEY_A, KEY_LEFT:
			_held_move_keys[&"left"] = pressed
		KEY_D, KEY_RIGHT:
			_held_move_keys[&"right"] = pressed


func _get_screen_relative_step_from_held_keys() -> Vector2i:
	var vertical = int(bool(_held_move_keys.get(&"down", false))) - int(bool(_held_move_keys.get(&"up", false)))
	var horizontal = int(bool(_held_move_keys.get(&"right", false))) - int(bool(_held_move_keys.get(&"left", false)))
	if vertical == 0 and horizontal == 0:
		return Vector2i.ZERO
	var step = Vector2i(horizontal + vertical, vertical - horizontal)
	return Vector2i(clampi(step.x, -1, 1), clampi(step.y, -1, 1))


func _interaction_card_visibility_refresh() -> void:
	if interaction_card == null:
		return
	var display_object_id = _active_overlay_object_id
	var world_object = _world_object_by_id.get(display_object_id, null)
	var show_card = _input_enabled and world_object != null and world_object.is_interactable and _active_overlay_object_id != &""
	interaction_card.visible = show_card
	if not show_card:
		return
	interaction_title_label.text = world_object.display_name if world_object.display_name != "" else _active_prompt_title
	if _has_contextual_overlay(world_object.route_id):
		_render_contextual_overlay(world_object)
	else:
		interaction_detail_label.text = _active_prompt_detail
		interaction_action_button.text = _build_interaction_card_button_text(world_object)
		interaction_action_button.visible = true
		interaction_close_button.visible = false
		interaction_section_scroll.visible = false
		_clear_children(interaction_section_list)
	_position_interaction_card()


func _build_interaction_card_button_text(world_object) -> String:
	if world_object == null:
		return "Act"
	if world_object.page_id != &"":
		return "Open %s" % world_object.prompt_action
	return world_object.prompt_action


func _refresh_hover_chip() -> void:
	if hover_chip == null:
		return
	if not _input_enabled or _active_overlay_object_id != &"":
		hover_chip.visible = false
		return
	var object_id = _hovered_object_id if _hovered_object_id != &"" else _active_prompt_object_id
	var world_object = _world_object_by_id.get(object_id, null)
	if world_object == null or not world_object.is_interactable:
		hover_chip.visible = false
		return
	hover_chip_label.text = world_object.display_name
	hover_chip.visible = true
	_position_hover_chip()


func _position_hover_chip() -> void:
	if hover_chip == null or not hover_chip.visible:
		return
	var object_id = _hovered_object_id if _hovered_object_id != &"" else _active_prompt_object_id
	var world_object = _world_object_by_id.get(object_id, null)
	if world_object == null or world_view == null or not world_view.has_method("get_screen_position_for_grid"):
		hover_chip.visible = false
		return
	var screen_position = world_view.get_screen_position_for_grid(Vector2(world_object.position))
	var preferred = screen_position + Vector2(-hover_chip.size.x * 0.5, -52.0)
	var max_x = maxf(size.x - hover_chip.size.x - 12.0, 12.0)
	var max_y = maxf(size.y - hover_chip.size.y - 96.0, 12.0)
	hover_chip.position = Vector2(
		clampf(preferred.x, 12.0, max_x),
		clampf(preferred.y, 12.0, max_y)
	)


func _position_interaction_card() -> void:
	if interaction_card == null or not interaction_card.visible:
		return
	if _interaction_card_has_manual_position:
		var max_x_manual = maxf(size.x - interaction_card.size.x - 12.0, 12.0)
		var max_y_manual = maxf(size.y - interaction_card.size.y - 96.0, 12.0)
		interaction_card.position = Vector2(
			clampf(interaction_card.position.x, 12.0, max_x_manual),
			clampf(interaction_card.position.y, 12.0, max_y_manual)
		)
		return
	var world_object = _world_object_by_id.get(_active_overlay_object_id, null)
	if world_object == null or world_view == null or not world_view.has_method("get_screen_position_for_grid"):
		return
	var screen_position = world_view.get_screen_position_for_grid(Vector2(world_object.position))
	var preferred = screen_position + Vector2(54.0, -132.0)
	var max_x = maxf(size.x - interaction_card.size.x - 12.0, 12.0)
	var max_y = maxf(size.y - interaction_card.size.y - 96.0, 12.0)
	interaction_card.position = Vector2(
		clampf(preferred.x, 12.0, max_x),
		clampf(preferred.y, 12.0, max_y)
	)


func _on_interaction_title_bar_gui_input(event: InputEvent) -> void:
	if interaction_card == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_interaction_card_dragging = true
			_interaction_card_has_manual_position = true
			_interaction_card_drag_offset = event.global_position - interaction_card.global_position
			get_viewport().set_input_as_handled()
		else:
			_interaction_card_dragging = false
	elif event is InputEventMouseMotion and _interaction_card_dragging:
		var canvas_position = get_global_transform_with_canvas().origin
		interaction_card.position = event.global_position - canvas_position - _interaction_card_drag_offset
		_position_interaction_card()
		get_viewport().set_input_as_handled()


func _on_interaction_card_pressed() -> void:
	if _active_prompt_object_id == &"":
		return
	if interaction_system != null:
		interaction_system.request_object_interaction(_active_prompt_object_id)


func _on_interaction_close_pressed() -> void:
	_clear_contextual_overlay()


func _has_contextual_overlay(route_id: StringName) -> bool:
	return route_id != &"" and _overlay_models_by_route.has(route_id)


func _open_contextual_overlay(object_id: StringName) -> void:
	if object_id == &"":
		return
	_active_overlay_object_id = object_id
	_hovered_object_id = object_id
	_refresh_hover_chip()
	_interaction_card_visibility_refresh()


func _clear_contextual_overlay() -> void:
	if _active_overlay_object_id == &"":
		return
	_active_overlay_object_id = &""
	_refresh_hover_chip()
	_interaction_card_visibility_refresh()


func _render_contextual_overlay(world_object) -> void:
	var overlay_model: Dictionary = _overlay_models_by_route.get(world_object.route_id, {})
	var theme: Dictionary = overlay_model.get("theme", {})
	var badge_text = String(theme.get("badge_text", world_object.display_name.substr(0, min(3, world_object.display_name.length())).to_upper()))
	var title_bar_color = Color(theme.get("title_bar_color", "3a2f22"))
	var badge_color = Color(theme.get("badge_color", "5a432b"))
	var body_color = Color(theme.get("body_color", "1f1b16"))
	var border_color = Color(theme.get("border_color", "7d6748"))
	var accent_color = Color(theme.get("accent_color", "d2b07c"))
	_apply_interaction_card_theme(title_bar_color, badge_color, body_color, border_color)
	interaction_badge_label.text = badge_text
	interaction_badge_label.modulate = accent_color.lightened(0.25)
	interaction_title_label.text = String(overlay_model.get("title", world_object.display_name))
	interaction_title_label.modulate = Color("f5ead6")
	interaction_subtitle_label.text = String(overlay_model.get("subtitle", world_object.detail_text))
	interaction_subtitle_label.modulate = accent_color
	interaction_detail_label.text = String(overlay_model.get("summary", _active_prompt_detail))
	interaction_detail_label.modulate = Color("e2d5c2")
	interaction_action_button.visible = false
	interaction_close_button.visible = true
	interaction_section_scroll.visible = true
	_clear_children(interaction_section_list)
	if String(overlay_model.get("layout", "")) == "recipe_browser":
		interaction_section_list.add_child(_build_recipe_browser_panel(overlay_model, theme, border_color, accent_color))
		return
	for section in overlay_model.get("sections", []):
		if not (section is Dictionary):
			continue
		var section_title = String(section.get("title", "")).strip_edges()
		if section_title != "":
			var section_panel = PanelContainer.new()
			section_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			section_panel.add_theme_stylebox_override("panel", _make_overlay_panel_style(
				Color(theme.get("section_color", "2a241d")),
				border_color.darkened(0.1),
				1,
				6
			))
			var section_root = VBoxContainer.new()
			section_root.add_theme_constant_override("separation", 6)
			section_panel.add_child(section_root)
			var title_label = Label.new()
			title_label.text = section_title
			title_label.modulate = accent_color
			title_label.add_theme_font_size_override("font_size", 17)
			section_root.add_child(title_label)
			var section_detail = String(section.get("detail", "")).strip_edges()
			if section_detail != "":
				var detail_label = Label.new()
				detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail_label.text = section_detail
				detail_label.modulate = Color("d7c9b6")
				section_root.add_child(detail_label)
			for action_entry in section.get("actions", []):
				if not (action_entry is Dictionary):
					continue
				var action_button = Button.new()
				action_button.custom_minimum_size = Vector2(0.0, 54.0)
				action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				action_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				action_button.text = String(action_entry.get("label", "Act"))
				action_button.tooltip_text = String(action_entry.get("tooltip_text", ""))
				action_button.disabled = bool(action_entry.get("disabled", false))
				action_button.add_theme_stylebox_override("normal", _make_overlay_panel_style(
					Color(theme.get("button_color", "3a3126")),
					border_color,
					1,
					6
				))
				action_button.add_theme_stylebox_override("hover", _make_overlay_panel_style(
					Color(theme.get("button_hover_color", "4a3b2a")),
					accent_color,
					1,
					6
				))
				action_button.add_theme_stylebox_override("pressed", _make_overlay_panel_style(
					Color(theme.get("button_pressed_color", "54432f")),
					accent_color,
					1,
					6
				))
				action_button.pressed.connect(Callable(self, "_on_overlay_action_button_pressed").bind(action_entry.duplicate(true)))
				section_root.add_child(action_button)
			interaction_section_list.add_child(section_panel)


func _build_recipe_browser_panel(overlay_model: Dictionary, theme: Dictionary, border_color: Color, accent_color: Color) -> Control:
	var browser: Dictionary = overlay_model.get("browser", {})
	var detail: Dictionary = browser.get("detail", {})
	if detail.has("workspace"):
		return _build_recipe_browser_workspace(browser, detail.get("workspace", {}), theme, border_color, accent_color)
	var browser_panel = PanelContainer.new()
	browser_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser_panel.custom_minimum_size = Vector2(0.0, 320.0)
	browser_panel.add_theme_stylebox_override("panel", _make_overlay_panel_style(
		Color(theme.get("section_color", "2a241d")),
		border_color.darkened(0.1),
		1,
		6
	))
	var split = HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = int(browser.get("split_offset", 218))
	browser_panel.add_child(split)

	var list_scroll = ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.custom_minimum_size = Vector2(220.0, 0.0)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list_root = VBoxContainer.new()
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_root.add_theme_constant_override("separation", 6)
	list_scroll.add_child(list_root)
	split.add_child(list_scroll)

	var detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var detail_root = VBoxContainer.new()
	detail_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_root.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(detail_root)
	split.add_child(detail_scroll)

	var list_title = String(browser.get("list_title", "")).strip_edges()
	if list_title != "":
		var list_title_label = Label.new()
		list_title_label.text = list_title
		list_title_label.modulate = accent_color
		list_title_label.add_theme_font_size_override("font_size", 17)
		list_root.add_child(list_title_label)

	for entry in browser.get("entries", []):
		if not (entry is Dictionary):
			continue
		var entry_kind = String(entry.get("entry_kind", "recipe"))
		if entry_kind == "category":
			var category_button = Button.new()
			category_button.custom_minimum_size = Vector2(0.0, 44.0)
			category_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			category_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			category_button.text = String(entry.get("label", ""))
			category_button.tooltip_text = "Collapse or expand this recipe category."
			category_button.add_theme_stylebox_override("normal", _make_overlay_panel_style(
				Color(theme.get("section_color", "2a241d")).lightened(0.05),
				accent_color.darkened(0.1),
				1,
				6
			))
			category_button.add_theme_stylebox_override("hover", _make_overlay_panel_style(
				Color(theme.get("button_hover_color", "4a3b2a")),
				accent_color,
				1,
				6
			))
			category_button.add_theme_stylebox_override("pressed", _make_overlay_panel_style(
				Color(theme.get("button_pressed_color", "54432f")),
				accent_color,
				1,
				6
			))
			category_button.pressed.connect(Callable(self, "_on_overlay_action_button_pressed").bind(entry.duplicate(true)))
			list_root.add_child(category_button)
			continue
		var entry_button = Button.new()
		entry_button.custom_minimum_size = Vector2(0.0, 56.0)
		entry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_button.text = String(entry.get("label", "Select"))
		var entry_selected = bool(entry.get("selected", false))
		entry_button.tooltip_text = String(entry.get("tooltip_text", ""))
		entry_button.disabled = bool(entry.get("disabled", false))
		entry_button.add_theme_stylebox_override("normal", _make_overlay_panel_style(
			Color(theme.get("button_color", "3a3126")).lightened(0.08) if entry_selected else Color(theme.get("button_color", "3a3126")),
			accent_color if entry_selected else border_color,
			1,
			6
		))
		entry_button.add_theme_stylebox_override("hover", _make_overlay_panel_style(
			Color(theme.get("button_hover_color", "4a3b2a")),
			accent_color,
			1,
			6
		))
		entry_button.add_theme_stylebox_override("pressed", _make_overlay_panel_style(
			Color(theme.get("button_pressed_color", "54432f")),
			accent_color,
			1,
			6
		))
		entry_button.pressed.connect(Callable(self, "_on_overlay_action_button_pressed").bind(entry.duplicate(true)))
		list_root.add_child(entry_button)

	var detail_title = String(detail.get("title", "")).strip_edges()
	if detail_title != "":
		var detail_title_label = Label.new()
		detail_title_label.text = detail_title
		detail_title_label.modulate = Color("f5ead6")
		detail_title_label.add_theme_font_size_override("font_size", 19)
		detail_root.add_child(detail_title_label)
	var detail_summary = String(detail.get("summary", "")).strip_edges()
	if detail_summary != "":
		var summary_label = Label.new()
		summary_label.text = detail_summary
		summary_label.modulate = Color("d7c9b6")
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_root.add_child(summary_label)
	for section in detail.get("sections", []):
		if not (section is Dictionary):
			continue
		var section_panel = PanelContainer.new()
		section_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section_panel.add_theme_stylebox_override("panel", _make_overlay_panel_style(
			Color(theme.get("button_color", "3a3126")).darkened(0.08),
			border_color.darkened(0.1),
			1,
			6
		))
		var section_root = VBoxContainer.new()
		section_root.add_theme_constant_override("separation", 6)
		section_panel.add_child(section_root)
		var section_title = String(section.get("title", "")).strip_edges()
		if section_title != "":
			var section_title_label = Label.new()
			section_title_label.text = section_title
			section_title_label.modulate = accent_color
			section_title_label.add_theme_font_size_override("font_size", 17)
			section_root.add_child(section_title_label)
		var section_summary = String(section.get("summary", "")).strip_edges()
		if section_summary != "":
			var section_summary_label = Label.new()
			section_summary_label.text = section_summary
			section_summary_label.modulate = Color("d7c9b6")
			section_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			section_root.add_child(section_summary_label)
		for line in section.get("lines", []):
			var line_text = String(line).strip_edges()
			if line_text == "":
				continue
			var line_label = Label.new()
			line_label.text = line_text
			line_label.modulate = Color("d7c9b6")
			line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			section_root.add_child(line_label)
		for action_entry in section.get("actions", []):
			if not (action_entry is Dictionary):
				continue
			var action_button = Button.new()
			action_button.custom_minimum_size = Vector2(0.0, 52.0)
			action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			action_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			action_button.text = String(action_entry.get("label", "Act"))
			action_button.tooltip_text = String(action_entry.get("tooltip_text", ""))
			action_button.disabled = bool(action_entry.get("disabled", false))
			action_button.add_theme_stylebox_override("normal", _make_overlay_panel_style(
				Color(theme.get("button_color", "3a3126")),
				border_color,
				1,
				6
			))
			action_button.add_theme_stylebox_override("hover", _make_overlay_panel_style(
				Color(theme.get("button_hover_color", "4a3b2a")),
				accent_color,
				1,
				6
			))
			action_button.add_theme_stylebox_override("pressed", _make_overlay_panel_style(
				Color(theme.get("button_pressed_color", "54432f")),
				accent_color,
				1,
				6
			))
			action_button.pressed.connect(Callable(self, "_on_overlay_action_button_pressed").bind(action_entry.duplicate(true)))
			section_root.add_child(action_button)
		detail_root.add_child(section_panel)
	return browser_panel


func _build_recipe_browser_workspace(browser: Dictionary, workspace_data: Dictionary, theme: Dictionary, border_color: Color, accent_color: Color) -> Control:
	var workspace = HBoxContainer.new()
	workspace.name = "RecipeBrowserWorkspace"
	workspace.add_theme_constant_override("separation", 14)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var list_panel = PanelContainer.new()
	list_panel.name = "OverlayRecipeList"
	list_panel.custom_minimum_size = Vector2(250.0, 0.0)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", _make_overlay_panel_style(
		Color(theme.get("section_color", "2a241d")),
		border_color.darkened(0.1),
		1,
		8
	))
	workspace.add_child(list_panel)

	var list_scroll = ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)

	var list_root = VBoxContainer.new()
	list_root.add_theme_constant_override("separation", 6)
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list_root)

	var list_title = String(browser.get("list_title", "")).strip_edges()
	if list_title != "":
		var list_title_label = Label.new()
		list_title_label.text = list_title
		list_title_label.modulate = accent_color
		list_title_label.add_theme_font_size_override("font_size", 18)
		list_root.add_child(list_title_label)

	for entry in browser.get("entries", []):
		if not (entry is Dictionary):
			continue
		var entry_kind = String(entry.get("entry_kind", "recipe"))
		if entry_kind == "category":
			var category_label = Label.new()
			category_label.text = String(entry.get("label", ""))
			category_label.modulate = accent_color.lightened(0.08)
			category_label.add_theme_font_size_override("font_size", 16)
			list_root.add_child(category_label)
			continue
		var entry_button = Button.new()
		entry_button.custom_minimum_size = Vector2(0.0, 56.0)
		entry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_button.text = String(entry.get("label", "Select"))
		entry_button.tooltip_text = String(entry.get("tooltip_text", ""))
		entry_button.disabled = bool(entry.get("disabled", false))
		var entry_selected = bool(entry.get("selected", false))
		entry_button.add_theme_stylebox_override("normal", _make_overlay_panel_style(
			Color(theme.get("button_color", "3a3126")).lightened(0.08) if entry_selected else Color(theme.get("button_color", "3a3126")),
			accent_color if entry_selected else border_color,
			1,
			6
		))
		entry_button.add_theme_stylebox_override("hover", _make_overlay_panel_style(
			Color(theme.get("button_hover_color", "4a3b2a")),
			accent_color,
			1,
			6
		))
		entry_button.add_theme_stylebox_override("pressed", _make_overlay_panel_style(
			Color(theme.get("button_pressed_color", "54432f")),
			accent_color,
			1,
			6
		))
		entry_button.pressed.connect(Callable(self, "_on_overlay_action_button_pressed").bind(entry.duplicate(true)))
		list_root.add_child(entry_button)

	var card_data: Dictionary = workspace_data.get("card", {})
	var card_panel = PanelContainer.new()
	card_panel.name = "OverlayRecipeCard"
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_panel.custom_minimum_size = Vector2(520.0, 0.0)
	card_panel.add_theme_stylebox_override("panel", _make_overlay_panel_style(Color("efe2c8"), Color("8e7452"), 2, 8))
	workspace.add_child(card_panel)

	var card_root = VBoxContainer.new()
	card_root.add_theme_constant_override("separation", 10)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.add_child(card_root)

	var card_header = HBoxContainer.new()
	card_header.add_theme_constant_override("separation", 10)
	card_root.add_child(card_header)

	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(54.0, 54.0)
	badge.add_theme_stylebox_override("panel", _make_overlay_panel_style(Color("d8c19a"), Color("755b3e"), 2, 8))
	card_header.add_child(badge)

	var badge_label = Label.new()
	badge_label.text = String(card_data.get("badge_text", "CARD"))
	badge_label.modulate = Color("191510")
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 16)
	badge.add_child(badge_label)

	var title_root = VBoxContainer.new()
	title_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_root.add_theme_constant_override("separation", 4)
	card_header.add_child(title_root)

	var card_title = Label.new()
	card_title.text = String(card_data.get("title", "Recipe"))
	card_title.modulate = Color("18130e")
	card_title.add_theme_font_size_override("font_size", 22)
	title_root.add_child(card_title)

	var card_subtitle = Label.new()
	card_subtitle.text = String(card_data.get("subtitle", ""))
	card_subtitle.modulate = Color("5b4b3b")
	title_root.add_child(card_subtitle)

	var card_summary = String(card_data.get("summary", "")).strip_edges()
	if card_summary != "":
		var summary_label = Label.new()
		summary_label.text = card_summary
		summary_label.modulate = Color("201913")
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_root.add_child(summary_label)

	var card_body = HBoxContainer.new()
	card_body.name = "OverlayRecipeCardBody"
	card_body.add_theme_constant_override("separation", 14)
	card_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.add_child(card_body)

	var left_column = VBoxContainer.new()
	left_column.name = "OverlayRecipeCardLeft"
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 8)
	card_body.add_child(left_column)

	var right_column = VBoxContainer.new()
	right_column.name = "OverlayRecipeCardRight"
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 8)
	card_body.add_child(right_column)

	for utility in workspace_data.get("utility_sections", []):
		if not (utility is Dictionary):
			continue
		left_column.add_child(_build_overlay_action_section(utility, theme, border_color, accent_color))

	var section_index := 0
	for section in card_data.get("sections", []):
		if not (section is Dictionary):
			continue
		var target_column = left_column if section_index % 2 == 0 else right_column
		target_column.add_child(_build_overlay_recipe_card_section(section))
		section_index += 1

	var action_entry: Dictionary = card_data.get("action", {})
	if not action_entry.is_empty():
		var action_button = _build_overlay_action_button(action_entry, theme, border_color, accent_color)
		action_button.text = String(action_entry.get("label", "Act"))
		card_root.add_child(action_button)

	return workspace


func _build_overlay_recipe_card_section(section: Dictionary) -> Control:
	var section_root = VBoxContainer.new()
	section_root.add_theme_constant_override("separation", 4)

	var section_title = String(section.get("title", "")).strip_edges()
	if section_title != "":
		var title_label = Label.new()
		title_label.text = section_title
		title_label.modulate = Color("5d4c39")
		title_label.add_theme_font_size_override("font_size", 16)
		section_root.add_child(title_label)

	var body_label = Label.new()
	body_label.text = String(section.get("body", ""))
	body_label.modulate = Color("201913")
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_root.add_child(body_label)

	return section_root


func _build_overlay_action_section(section: Dictionary, theme: Dictionary, border_color: Color, accent_color: Color) -> Control:
	var section_panel = PanelContainer.new()
	section_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_panel.add_theme_stylebox_override("panel", _make_overlay_panel_style(
		Color(theme.get("button_color", "3a3126")).darkened(0.08),
		border_color.darkened(0.1),
		1,
		6
	))
	var section_root = VBoxContainer.new()
	section_root.add_theme_constant_override("separation", 6)
	section_panel.add_child(section_root)
	var section_title = String(section.get("title", "")).strip_edges()
	if section_title != "":
		var title_label = Label.new()
		title_label.text = section_title
		title_label.modulate = accent_color
		title_label.add_theme_font_size_override("font_size", 17)
		section_root.add_child(title_label)
	var section_summary = String(section.get("summary", "")).strip_edges()
	if section_summary != "":
		var summary_label = Label.new()
		summary_label.text = section_summary
		summary_label.modulate = Color("d7c9b6")
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section_root.add_child(summary_label)
	var action_parent: Control = section_root
	if String(section.get("layout", "")) == "compact_controls":
		var compact_row = HBoxContainer.new()
		compact_row.name = "OverlayCompactControls"
		compact_row.add_theme_constant_override("separation", 8)
		compact_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section_root.add_child(compact_row)
		action_parent = compact_row
	for action_entry in section.get("actions", []):
		if not (action_entry is Dictionary):
			continue
		action_parent.add_child(_build_overlay_action_button(action_entry, theme, border_color, accent_color))
	return section_panel


func _build_overlay_action_button(action_entry: Dictionary, theme: Dictionary, border_color: Color, accent_color: Color) -> Button:
	var action_button = Button.new()
	action_button.custom_minimum_size = Vector2(0.0, 52.0)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	action_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_button.text = String(action_entry.get("label", "Act"))
	action_button.tooltip_text = String(action_entry.get("tooltip_text", ""))
	action_button.disabled = bool(action_entry.get("disabled", false))
	if action_entry.has("command_type"):
		action_button.set_meta("command_type", String(action_entry.get("command_type", "")))
	action_button.add_theme_stylebox_override("normal", _make_overlay_panel_style(
		Color(theme.get("button_color", "3a3126")),
		border_color,
		1,
		6
	))
	action_button.add_theme_stylebox_override("hover", _make_overlay_panel_style(
		Color(theme.get("button_hover_color", "4a3b2a")),
		accent_color,
		1,
		6
	))
	action_button.add_theme_stylebox_override("pressed", _make_overlay_panel_style(
		Color(theme.get("button_pressed_color", "54432f")),
		accent_color,
		1,
		6
	))
	action_button.pressed.connect(Callable(self, "_on_overlay_action_button_pressed").bind(action_entry.duplicate(true)))
	return action_button


func _on_overlay_action_button_pressed(action_entry: Dictionary) -> void:
	overlay_action_requested.emit(action_entry.duplicate(true))


func _apply_interaction_card_theme(title_bar_color: Color, badge_color: Color, body_color: Color, border_color: Color) -> void:
	interaction_card.add_theme_stylebox_override("panel", _make_overlay_panel_style(body_color, border_color, 1, 8))
	if interaction_title_bar != null:
		interaction_title_bar.add_theme_stylebox_override("panel", _make_overlay_panel_style(title_bar_color, border_color, 1, 8, 8, 4, 4))
	if interaction_badge != null:
		interaction_badge.add_theme_stylebox_override("panel", _make_overlay_panel_style(badge_color, border_color.lightened(0.15), 1, 6))


func _make_overlay_panel_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int, top_left: int = -1, top_right: int = -1, bottom_right: int = -1, bottom_left: int = -1) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius if top_left < 0 else top_left
	style.corner_radius_top_right = corner_radius if top_right < 0 else top_right
	style.corner_radius_bottom_right = corner_radius if bottom_right < 0 else bottom_right
	style.corner_radius_bottom_left = corner_radius if bottom_left < 0 else bottom_left
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.queue_free()
