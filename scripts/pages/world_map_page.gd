class_name WorldMapPage
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")
const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")
const ActionButtonWidgetScript := preload("res://scripts/ui/widgets/action_button_widget.gd")
const ConditionStripWidgetScript := preload("res://scripts/ui/widgets/condition_strip_widget.gd")
const DataPanelWidgetScript := preload("res://scripts/ui/widgets/data_panel_widget.gd")
const BasePanelWidgetScript := preload("res://scripts/ui/widgets/base_panel_widget.gd")

const ROUTE_TOWN := &"town"
const ROUTE_CAMP := &"camp"

const NAV_TRAVEL := &"nav.travel"
const NAV_LOCATION := &"nav.location"
const NAV_CRAFTING := &"nav.crafting"
const NAV_COOKING := &"nav.cooking"
const NAV_REST := &"nav.rest"
const NAV_INVENTORY := &"nav.inventory"
const NAV_PASSPORT := &"nav.passport"
const ACTION_WAIT_PAGE := &"action.wait"
const ACTION_SELL_SCRAP_PAGE := &"action.sell_scrap"

var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _stats_manager = null
var _location_manager = null
var _ui_manager = null
var _show_status := Callable()
var _request_return_to_menu := Callable()
var _request_quit_game := Callable()

var _summary_title_label: Label = null
var _summary_stats_label: Label = null
var _condition_stats_label: Label = null
var _goal_label: Label = null
var _fade_debug_label: Label = null
var _open_inventory_button: Button = null
var _open_passport_button: Button = null
var _open_travel_button: Button = null
var _return_to_menu_button: Button = null
var _quit_game_button: Button = null

var _panel: PanelContainer = null
var _status_widget = null
var _route_summary_widget = null
var _condition_widget = null
var _page_actions_root: GridContainer = null
var _world_actions_root: HBoxContainer = null
var _button_widgets: Dictionary = {}
var _current_route: StringName = ROUTE_TOWN


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_game_state_manager = deps.get("game_state_manager", null)
	_data_manager = deps.get("data_manager", null)
	_time_manager = deps.get("time_manager", null)
	_stats_manager = deps.get("stats_manager", null)
	_location_manager = deps.get("location_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_show_status = deps.get("show_status", Callable())
	_request_return_to_menu = deps.get("request_return_to_menu", Callable())
	_request_quit_game = deps.get("request_quit_game", Callable())

	_summary_title_label = deps.get("summary_title_label", null)
	_summary_stats_label = deps.get("summary_stats_label", null)
	_condition_stats_label = deps.get("condition_stats_label", null)
	_goal_label = deps.get("goal_label", null)
	_fade_debug_label = deps.get("fade_debug_label", null)
	_open_inventory_button = deps.get("open_inventory_button", null)
	_open_passport_button = deps.get("open_passport_button", null)
	_open_travel_button = deps.get("open_routes_button", null)
	_return_to_menu_button = deps.get("return_to_menu_button", null)
	_quit_game_button = deps.get("quit_game_button", null)

	_build_panel(deps.get("page_host", null))
	_connect_buttons()
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible


func set_route(route_id: StringName) -> void:
	if route_id == ROUTE_TOWN or route_id == ROUTE_CAMP:
		_current_route = route_id
	set_visible(true)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_context(_context: Dictionary) -> void:
	pass


func refresh_from_state(player_state) -> void:
	if _summary_title_label == null:
		return
	if player_state == null:
		_summary_title_label.text = "First Playable Loop"
		_summary_stats_label.text = "Shared state is unavailable."
		_condition_stats_label.text = ""
		_goal_label.text = ""
		if _status_widget != null:
			_status_widget.set_data("The road will resolve once shared state is ready.")
		if _route_summary_widget != null:
			_route_summary_widget.set_data("")
		if _condition_widget != null:
			_condition_widget.clear_conditions()
		return

	var config = _data_manager.get_loop_config() if _data_manager != null else null
	var current_obligation = player_state.get_current_support_obligation()
	var obligation_label = "No open support due"
	if not current_obligation.is_empty():
		obligation_label = "%s %s/%s by Day %d" % [
			String(current_obligation.get("label", "Support")),
			_format_cents(int(current_obligation.get("delivered_cents", 0))),
			_format_cents(int(current_obligation.get("target_cents", 0))),
			int(current_obligation.get("checkpoint_day", player_state.day_limit))
		]

	_summary_title_label.text = "First Playable Survival Loop"
	_summary_stats_label.text = "%s    %s    Week %d    %d days left    %s    Cash %s    %s    Carry %.2f kg    Fire %s" % [
		player_state.get_time_of_day_label(),
		"Camp" if player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_CAMP else "Town",
		player_state.get_current_week_index(),
		player_state.get_days_remaining_in_month(),
		obligation_label,
		player_state.get_money_label(),
		player_state.get_support_progress_label(),
		player_state.inventory_state.get_total_weight_kg(),
		player_state.get_camp_fire_status_label()
	]
	var appearance_tier = SurvivalLoopRulesScript.get_appearance_tier(player_state, config)
	_condition_stats_label.text = "Status %s    Appearance: %s" % [
		player_state.get_loop_status_label(),
		String(appearance_tier.get("label", "Unkept"))
	]
	_goal_label.text = player_state.passport_profile.current_goal
	if _fade_debug_label != null:
		_fade_debug_label.text = "Current Fade Value: %d / 100\nCurrent Fade State: %s\nLast Daily Delta: %s%d" % [
			player_state.fade_value,
			FadingMeterSystemScript.get_state_display_name(player_state.fade_state),
			"+" if player_state.fade_last_daily_delta >= 0 else "",
			player_state.fade_last_daily_delta
		]
	if _open_inventory_button != null:
		_open_inventory_button.text = "Open Inventory"
	if _open_passport_button != null:
		_open_passport_button.text = "Open Passport"
	if _open_travel_button != null:
		_open_travel_button.text = "Open Travel"
	if _return_to_menu_button != null:
		_return_to_menu_button.text = "Exit to Menu"
		_return_to_menu_button.visible = true
	if _quit_game_button != null:
		_quit_game_button.visible = false

	var in_camp = _current_route == ROUTE_CAMP
	if _status_widget != null:
		_status_widget.set_data("Camp is a working camp: rest, wash, cooking, and craft keep the body usable." if in_camp else "Town is where leads, wages, supplies, and remittance are turned into the next move.")
	if _route_summary_widget != null:
		_route_summary_widget.set_data(_build_route_summary(player_state, config, in_camp))
	if _condition_widget != null:
		_condition_widget.set_conditions(_build_condition_surface_data(player_state))

	_set_button_state(NAV_TRAVEL, "Travel", true)
	_set_button_state(NAV_LOCATION, "Town Services", not in_camp)
	_set_button_state(NAV_CRAFTING, "Crafting", in_camp)
	_set_button_state(NAV_COOKING, "Cooking", in_camp)
	_set_button_state(NAV_REST, "Rest / Camp", in_camp)
	_set_button_state(NAV_INVENTORY, "Inventory", true)
	_set_button_state(NAV_PASSPORT, "Passport / Stats", true)
	_set_button_state(ACTION_WAIT_PAGE, "Wait %s" % _format_duration(config.wait_action_minutes) if config != null else "Wait", not in_camp)
	_set_button_state(ACTION_SELL_SCRAP_PAGE, "Sell Scrap\n%s | %s for %d scrap" % [
		_format_duration(config.sell_scrap_minutes),
		_format_cents(config.sell_scrap_pay_cents),
		config.sell_scrap_quantity
	] if config != null else "Sell Scrap", not in_camp)


func handle_input(_event: InputEvent) -> bool:
	return false


func _build_panel(page_host) -> void:
	if page_host == null:
		return
	_panel = PanelContainer.new()
	_panel.name = "WorldMapPagePanel"
	_panel.visible = false
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(_panel, "panel")
	page_host.add_child(_panel)

	var root = VBoxContainer.new()
	root.name = "WorldMapPageRoot"
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(root)

	var title = Label.new()
	title.text = "World Map"
	PageUIThemeScript.style_header_label(title, true)
	root.add_child(title)

	_status_widget = DataPanelWidgetScript.new()
	_status_widget.set_title("Road Status", true)
	_status_widget.set_variant("highlight")
	root.add_child(_status_widget)

	_route_summary_widget = DataPanelWidgetScript.new()
	_route_summary_widget.set_title("Current Position")
	_route_summary_widget.set_variant("alt")
	root.add_child(_route_summary_widget)

	var page_actions = BasePanelWidgetScript.new()
	page_actions.set_title("Direct Pages")
	root.add_child(page_actions)
	_page_actions_root = GridContainer.new()
	_page_actions_root.columns = 2
	_page_actions_root.add_theme_constant_override("h_separation", 10)
	_page_actions_root.add_theme_constant_override("v_separation", 10)
	_page_actions_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_actions.get_content_root().add_child(_page_actions_root)

	for action_id in [NAV_TRAVEL, NAV_LOCATION, NAV_CRAFTING, NAV_COOKING, NAV_REST, NAV_INVENTORY, NAV_PASSPORT]:
		_page_actions_root.add_child(_make_action_button(action_id))

	var world_actions = BasePanelWidgetScript.new()
	world_actions.set_title("Available Actions")
	world_actions.set_variant("alt")
	root.add_child(world_actions)
	_world_actions_root = HBoxContainer.new()
	_world_actions_root.add_theme_constant_override("separation", 8)
	_world_actions_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_actions.get_content_root().add_child(_world_actions_root)

	for action_id in [ACTION_WAIT_PAGE, ACTION_SELL_SCRAP_PAGE]:
		_world_actions_root.add_child(_make_action_button(action_id))


func _make_action_button(action_id: StringName):
	var button = ActionButtonWidgetScript.new()
	button.set_action_id(action_id)
	button.pressed.connect(Callable(self, "_on_action_widget_pressed"))
	_button_widgets[action_id] = button
	return button


func _set_button_state(action_id: StringName, label_text: String, enabled: bool) -> void:
	var widget = _button_widgets.get(action_id, null)
	if widget == null:
		return
	widget.set_label(label_text)
	widget.set_enabled(enabled)


func _connect_buttons() -> void:
	if _open_travel_button != null and not _open_travel_button.pressed.is_connected(Callable(self, "_open_travel")):
		_open_travel_button.pressed.connect(Callable(self, "_open_travel"))
	if _return_to_menu_button != null and not _return_to_menu_button.pressed.is_connected(Callable(self, "_return_to_menu")):
		_return_to_menu_button.pressed.connect(Callable(self, "_return_to_menu"))
	if _quit_game_button != null and not _quit_game_button.pressed.is_connected(Callable(self, "_quit_game")):
		_quit_game_button.pressed.connect(Callable(self, "_quit_game"))


func _build_route_summary(player_state, config, in_camp: bool) -> String:
	if in_camp:
		return "Camp fire %s. Potable water %d. Non-potable water %d. Hygiene %d. Presentability %d. Stamina %d." % [
			player_state.get_camp_fire_status_label(),
			int(player_state.camp_potable_water_units),
			int(player_state.camp_non_potable_water_units),
			int(player_state.passport_profile.hygiene),
			int(player_state.passport_profile.presentability),
			_stats_manager.get_stamina(player_state) if _stats_manager != null else 0
		]
	if config == null:
		return "Town pressure is active."
	return "Town work and errands convert time into stake. Waiting costs %s. Scrap sells for %s per %d." % [
		_format_duration(config.wait_action_minutes),
		_format_cents(config.sell_scrap_pay_cents),
		config.sell_scrap_quantity
	]


func _build_condition_surface_data(player_state) -> Array:
	var conditions: Array = []
	if player_state == null:
		return conditions
	var inventory = player_state.inventory_state
	var max_weight = inventory.max_total_weight_kg if inventory != null else 0.0
	var total_weight = inventory.get_total_weight_kg() if inventory != null else 0.0
	var passport = player_state.passport_profile
	if passport == null:
		return conditions
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
		"note": "Carry weight decides how hard the body works to keep moving.",
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


func _on_action_widget_pressed(action_id: StringName) -> void:
	match action_id:
		NAV_TRAVEL:
			_open_travel()
		NAV_LOCATION:
			_open_location_page()
		NAV_CRAFTING:
			_open_crafting_page()
		NAV_COOKING:
			_open_cooking_page()
		NAV_REST:
			_open_rest_page()
		NAV_INVENTORY:
			_open_inventory()
		NAV_PASSPORT:
			_open_passport()
		ACTION_WAIT_PAGE:
			_execute_action(SurvivalLoopRulesScript.ACTION_WAIT, "world_map.wait")
		ACTION_SELL_SCRAP_PAGE:
			_execute_action(SurvivalLoopRulesScript.ACTION_SELL_SCRAP, "world_map.sell_scrap")


func _open_travel() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(&"travel_ui", {"return_route": _current_route})


func _open_location_page() -> void:
	if _ui_manager == null or _location_manager == null or _current_route != ROUTE_TOWN:
		return
	_ui_manager.open_page(_location_manager.ROUTE_LOCATION_PAGE, {
		"return_route": _current_route,
		"route_id": _location_manager.get_default_location_route_for_location(SurvivalLoopRulesScript.LOCATION_TOWN)
	})


func _open_crafting_page() -> void:
	if _ui_manager == null or _location_manager == null or _current_route != ROUTE_CAMP:
		return
	_ui_manager.open_page(_location_manager.ROUTE_CRAFTING_PAGE, {
		"return_route": _current_route,
		"route_id": _location_manager.PAGE_HOBOCRAFT
	})


func _open_cooking_page() -> void:
	if _ui_manager == null or _location_manager == null or _current_route != ROUTE_CAMP:
		return
	_ui_manager.open_page(_location_manager.PAGE_COOKING, {"return_route": _current_route})


func _open_rest_page() -> void:
	if _ui_manager == null or _location_manager == null or _current_route != ROUTE_CAMP:
		return
	_ui_manager.open_page(_location_manager.ROUTE_REST_PAGE, {
		"return_route": _current_route,
		"route_id": _location_manager.get_default_rest_route_for_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	})


func _open_inventory() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(&"inventory_ui", {"return_route": _current_route})


func _open_passport() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(&"passport_stats", {"return_route": _current_route})


func _return_to_menu() -> void:
	if not _request_return_to_menu.is_null():
		_request_return_to_menu.call()


func _quit_game() -> void:
	if not _request_quit_game.is_null():
		_request_quit_game.call()


func _execute_action(action_id: StringName, source: String) -> void:
	if _game_state_manager == null:
		return
	var result = _game_state_manager.execute_action(String(action_id), {"source": source})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))
	if _ui_manager != null:
		_ui_manager.open_page(_current_route)


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(amount_cents) / 100.0)


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes
