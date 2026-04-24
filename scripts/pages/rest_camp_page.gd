class_name RestCampPage
extends RefCounted

const OverlayBuilderScript := preload("res://scripts/front_end/adapters/overlay_builder.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")
const ConditionStripWidgetScript := preload("res://scripts/ui/widgets/condition_strip_widget.gd")

var _overlay_builder = OverlayBuilderScript.new()
var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _stats_manager = null
var _ui_manager = null
var _show_status := Callable()
var _resolve_return_route := Callable()
var _return_route: StringName = &"camp"

var _overlay: Control = null
var _root: VBoxContainer = null
var _status_label: Label = null
var _stats_label: Label = null
var _close_button: Button = null
var _fetch_water_button: Button = null
var _wash_body_button: Button = null
var _wash_face_hands_button: Button = null
var _shave_button: Button = null
var _comb_groom_button: Button = null
var _air_out_clothes_button: Button = null
var _brush_clothes_button: Button = null
var _rest_sections_root: VBoxContainer = null
var _action_panel: PanelContainer = null
var _camp_state_panel: PanelContainer = null
var _stats_panel: PanelContainer = null
var _condition_widget = null

var _current_route: StringName = &"getting_ready"
var _selected_rest_hours := 8
var _selected_sleep_item_id: StringName = &""


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_game_state_manager = deps.get("game_state_manager", null)
	_data_manager = deps.get("data_manager", null)
	_time_manager = deps.get("time_manager", null)
	_stats_manager = deps.get("stats_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_overlay_builder = deps.get("overlay_builder", _overlay_builder)
	_show_status = deps.get("show_status", Callable())
	_resolve_return_route = deps.get("resolve_return_route", Callable())

	_overlay = deps.get("overlay", null)
	_root = deps.get("root", null)
	_status_label = deps.get("status_label", null)
	_stats_label = deps.get("stats_label", null)
	_close_button = deps.get("close_button", null)
	_fetch_water_button = deps.get("fetch_water_button", null)
	_wash_body_button = deps.get("wash_body_button", null)
	_wash_face_hands_button = deps.get("wash_face_hands_button", null)
	_shave_button = deps.get("shave_button", null)
	_comb_groom_button = deps.get("comb_groom_button", null)
	_air_out_clothes_button = deps.get("air_out_clothes_button", null)
	_brush_clothes_button = deps.get("brush_clothes_button", null)

	if _overlay != null:
		_overlay.visible = false
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_close")):
		_close_button.pressed.connect(Callable(self, "_close"))
	_build_overlay_layout()
	_connect_action_buttons()
	_build_rest_sections_root()
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_context(context: Dictionary) -> void:
	_return_route = StringName(context.get("return_route", _return_route))
	var requested_route = StringName(context.get("route_id", &""))
	if requested_route != &"":
		_current_route = requested_route


func set_route(route_name: StringName) -> void:
	_current_route = route_name
	set_visible(true)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_visible(visible: bool) -> void:
	if _overlay != null:
		_overlay.visible = visible


func refresh_from_state(player_state) -> void:
	if _status_label == null or _stats_label == null:
		return
	if player_state == null or player_state.passport_profile == null:
		_status_label.text = "Camp rest is unavailable until shared state is ready."
		_stats_label.text = ""
		return
	var config = _data_manager.get_loop_config() if _data_manager != null else null
	_status_label.text = "Water first, then the work of becoming fit to be seen. Relief is temporary and has to be earned."
	_stats_label.text = "Water potable %d / non-potable %d    Hygiene %d / 100    Presentability %d / 100    Stamina %d / 100    Morale %d / 100    Time %s" % [
		player_state.camp_potable_water_units,
		player_state.camp_non_potable_water_units,
		player_state.passport_profile.hygiene,
		player_state.passport_profile.presentability,
		_stats_manager.get_stamina(player_state) if _stats_manager != null else 0,
		player_state.passport_profile.morale,
		player_state.get_time_of_day_label()
	]
	if _condition_widget != null:
		_condition_widget.set_conditions(_build_condition_surface_data(player_state))
	if config == null:
		return
	var water_action_duration = config.ready_boil_water_minutes if player_state.camp_non_potable_water_units > 0 else config.ready_fetch_water_minutes
	_fetch_water_button.text = "Fetch Water / Boil Water\nrequired first | %s" % _format_duration(water_action_duration)
	_wash_body_button.text = "Wash Body\n+Hygiene, +Presentability, -Stamina | %s" % _format_duration(config.ready_wash_body_minutes)
	_wash_face_hands_button.text = "Wash Face / Hands\n+Hygiene, +Presentability | %s" % _format_duration(config.ready_wash_face_hands_minutes)
	_shave_button.text = "Shave\n+Presentability | %s" % _format_duration(config.ready_shave_minutes)
	_comb_groom_button.text = "Comb / Groom\n+Presentability | %s" % _format_duration(config.ready_comb_groom_minutes)
	_air_out_clothes_button.text = "Air Out Clothes\n+Hygiene, +Presentability | %s" % _format_duration(config.ready_air_out_clothes_minutes)
	_brush_clothes_button.text = "Brush Clothes\n+Presentability | %s" % _format_duration(config.ready_brush_clothes_minutes)
	_render_rest_sections(player_state, config)


func handle_input(event: InputEvent) -> bool:
	if _overlay == null or not _overlay.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		_close()
		return true
	return false


func _connect_action_buttons() -> void:
	_fetch_water_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER))
	_wash_body_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_WASH_BODY))
	_wash_face_hands_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS))
	_shave_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_SHAVE))
	_comb_groom_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM))
	_air_out_clothes_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES))
	_brush_clothes_button.pressed.connect(Callable(self, "_execute_action").bind(SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES))
	for button in [_fetch_water_button, _wash_body_button, _wash_face_hands_button, _shave_button, _comb_groom_button, _air_out_clothes_button, _brush_clothes_button, _close_button]:
		PageUIThemeScript.style_button(button, button != _close_button)


func _build_overlay_layout() -> void:
	if _root == null or _root.get_node_or_null("RestPageLayout") != null:
		return
	var status_parent = _status_label.get_parent()
	var stats_parent = _stats_label.get_parent()
	status_parent.remove_child(_status_label)
	stats_parent.remove_child(_stats_label)
	var actions_parent = _fetch_water_button.get_parent()
	var actions_children := [
		_fetch_water_button,
		_wash_body_button,
		_wash_face_hands_button,
		_shave_button,
		_comb_groom_button,
		_air_out_clothes_button,
		_brush_clothes_button
	]
	for button in actions_children:
		actions_parent.remove_child(button)
	var layout := HBoxContainer.new()
	layout.name = "RestPageLayout"
	layout.add_theme_constant_override("separation", 12)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(layout)
	_action_panel = PageUIThemeScript.create_section_panel("CAMP ACTIONS", "alt").panel
	_action_panel.custom_minimum_size = Vector2(260.0, 0.0)
	var action_root: VBoxContainer = _action_panel.get_child(0)
	var action_grid := VBoxContainer.new()
	action_grid.name = "RestActionStack"
	action_grid.add_theme_constant_override("separation", 8)
	for button in actions_children:
		action_grid.add_child(button)
	action_root.add_child(action_grid)
	layout.add_child(_action_panel)
	_camp_state_panel = PageUIThemeScript.create_section_panel("CAMP STATE", "panel").panel
	var camp_state_root: VBoxContainer = _camp_state_panel.get_child(0)
	camp_state_root.add_child(_status_label)
	layout.add_child(_camp_state_panel)
	_stats_panel = PageUIThemeScript.create_section_panel("ROAD CONDITION", "highlight").panel
	_stats_panel.custom_minimum_size = Vector2(280.0, 0.0)
	var stats_root: VBoxContainer = _stats_panel.get_child(0)
	stats_root.add_child(_stats_label)
	_condition_widget = ConditionStripWidgetScript.new()
	_condition_widget.set_title("Working Condition")
	_condition_widget.set_variant("dark")
	_condition_widget.set_columns(2)
	stats_root.add_child(_condition_widget)
	layout.add_child(_stats_panel)


func _build_rest_sections_root() -> void:
	if _camp_state_panel == null:
		return
	_rest_sections_root = _camp_state_panel.get_node_or_null("RestSectionsRoot")
	if _rest_sections_root != null:
		return
	_rest_sections_root = VBoxContainer.new()
	_rest_sections_root.name = "RestSectionsRoot"
	_rest_sections_root.add_theme_constant_override("separation", 10)
	_rest_sections_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rest_sections_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var camp_state_root = _camp_state_panel.get_child(0) as VBoxContainer
	if camp_state_root != null:
		camp_state_root.add_child(_rest_sections_root)


func _render_rest_sections(player_state, config) -> void:
	_clear_children(_rest_sections_root)
	var rest_model = _overlay_builder.build_camp_contextual_overlay_models(
		player_state,
		config,
		_get_ui_state(),
		_get_overlay_builder_deps()
	).get(&"rest", {})
	for section_model in rest_model.get("sections", []):
		if section_model is Dictionary:
			_rest_sections_root.add_child(_build_rest_section(section_model))


func _build_rest_section(section_model: Dictionary) -> Control:
	var panel = PanelContainer.new()
	PageUIThemeScript.apply_panel_variant(panel, "dark")
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var title = Label.new()
	title.text = String(section_model.get("title", "Section"))
	PageUIThemeScript.style_section_label(title)
	root.add_child(title)
	var detail = Label.new()
	detail.text = String(section_model.get("detail", ""))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(detail)
	root.add_child(detail)
	var layout = String(section_model.get("layout", ""))
	var action_host: Control = HBoxContainer.new() if layout == "compact_controls" else VBoxContainer.new()
	if action_host is BoxContainer:
		action_host.add_theme_constant_override("separation", 8)
	action_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(action_host)
	for action_model in section_model.get("actions", []):
		if not (action_model is Dictionary):
			continue
		var button = Button.new()
		button.text = String(action_model.get("label", "Action"))
		button.custom_minimum_size = Vector2(0.0, 42.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = bool(action_model.get("disabled", false))
		button.tooltip_text = String(action_model.get("tooltip_text", ""))
		PageUIThemeScript.style_button(button, true)
		button.pressed.connect(Callable(self, "_on_rest_command_pressed").bind(action_model))
		action_host.add_child(button)
	return panel


func _on_rest_command_pressed(command: Dictionary) -> void:
	var command_type = String(command.get("command_type", ""))
	match command_type:
		"set_rest_hours":
			_selected_rest_hours = clampi(int(command.get("hours", _selected_rest_hours)), 1, 12)
		"adjust_rest_hours":
			_selected_rest_hours = clampi(_selected_rest_hours + int(command.get("delta", 0)), 1, 12)
		"set_sleep_item":
			_selected_sleep_item_id = StringName(command.get("sleep_item_id", &""))
		_:
			var action_id = StringName(command.get("action_id", &""))
			if action_id != &"":
				var context = command.get("context", {})
				var payload = context.duplicate(true) if context is Dictionary else {}
				payload["source"] = String(command.get("context_source", "rest.page"))
				var result = _game_state_manager.execute_action(String(action_id), payload)
				if not _show_status.is_null():
					_show_status.call(String(result.get("message", "No result.")))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _execute_action(action_id: StringName) -> void:
	if _game_state_manager == null:
		return
	var result = _game_state_manager.execute_action(String(action_id), {"source": "rest.ready"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _get_ui_state() -> Dictionary:
	return {
		"selected_rest_hours": _selected_rest_hours,
		"selected_sleep_item_id": _selected_sleep_item_id,
		"selected_cooking_recipe_id": &"",
		"selected_hobocraft_recipe_id": &"",
		"expanded_cooking_overlay_categories": {},
		"expanded_hobocraft_overlay_categories": {}
	}


func _get_overlay_builder_deps() -> Dictionary:
	return {
		"build_action_context": Callable(self, "_build_action_context"),
		"format_duration": Callable(self, "_format_duration"),
		"format_warmth_breakdown": Callable(self, "_format_warmth_breakdown"),
		"get_action_availability": Callable(self, "_get_action_availability"),
		"get_item_catalog": Callable(self, "_get_item_catalog"),
		"get_item_definition": Callable(self, "_get_item_definition"),
		"get_stamina_value": Callable(self, "_get_stamina_value")
	}


func _build_action_context(source: String, values: Dictionary = {}) -> Dictionary:
	var context = values.duplicate(true)
	context["source"] = source
	return context


func _get_action_availability(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	if _game_state_manager == null:
		return {"enabled": false, "reason": "Action is unavailable."}
	if context.is_empty():
		return _game_state_manager.get_loop_action_availability(action_id)
	return _game_state_manager.get_loop_action_availability_with_context(action_id, context)


func _get_item_catalog():
	return _data_manager.get_item_catalog() if _data_manager != null else null


func _get_item_definition(item_id: StringName):
	return _data_manager.get_item_definition(item_id) if _data_manager != null else null


func _get_stamina_value(player_state) -> int:
	return _stats_manager.get_stamina(player_state) if _stats_manager != null else 0


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes


func _format_warmth_breakdown(breakdown: Dictionary) -> String:
	if breakdown.is_empty():
		return "not available"
	var parts: Array[String] = []
	for entry in breakdown.get("contributors", []):
		if entry is Dictionary:
			parts.append("%s %+d" % [String(entry.get("label", "warmth")), int(entry.get("value", 0))])
	parts.append("net %+d" % int(breakdown.get("net_warmth_change", 0)))
	return ", ".join(parts)


func _build_condition_surface_data(player_state) -> Array:
	var conditions: Array = []
	if player_state == null or player_state.passport_profile == null:
		return conditions
	var passport = player_state.passport_profile
	var inventory = player_state.inventory_state
	var max_weight = inventory.max_total_weight_kg if inventory != null else 0.0
	var total_weight = inventory.get_total_weight_kg() if inventory != null else 0.0
	conditions.append(_make_condition_entry(&"warmth", "Warmth", passport.warmth))
	conditions.append(_make_condition_entry(&"stamina", "Stamina", _stats_manager.get_stamina(player_state) if _stats_manager != null else 0))
	conditions.append(_make_condition_entry(&"nutrition", "Nutrition", passport.nutrition))
	conditions.append({
		"stat_id": &"water",
		"label": "Water",
		"value_text": "ready %d | raw %d" % [int(player_state.camp_potable_water_units), int(player_state.camp_non_potable_water_units)],
		"note": "Camp water on hand for washing, coffee, and cooking.",
		"display_as_bar": false
	})
	conditions.append(_make_condition_entry(&"morale", "Morale", passport.morale))
	conditions.append(_make_condition_entry(&"presentability", "Presentability", passport.presentability))
	conditions.append(_make_condition_entry(&"hygiene", "Hygiene", passport.hygiene))
	conditions.append({
		"stat_id": &"weight",
		"label": "Weight",
		"value_text": "%.1f / %.1f kg" % [total_weight, max_weight],
		"note": "Carry weight still matters when breaking or making camp.",
		"display_as_bar": false
	})
	conditions.append(_make_condition_entry(&"dampness", "Dampness", passport.dampness))
	return conditions


func _make_condition_entry(stat_id: StringName, label: String, value: int) -> Dictionary:
	return {
		"stat_id": stat_id,
		"label": label,
		"value_text": "%d / 100" % clampi(value, 0, 100),
		"current": clampi(value, 0, 100),
		"max": 100,
		"display_as_bar": true
	}


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _close() -> void:
	if _ui_manager == null:
		return
	var route = _return_route
	if route == &"" and not _resolve_return_route.is_null():
		route = StringName(_resolve_return_route.call())
	_ui_manager.open_page(route)
