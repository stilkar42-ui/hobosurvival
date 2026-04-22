class_name WorldMapPage
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")

const ROUTE_TOWN := &"town"
const ROUTE_CAMP := &"camp"

var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _stats_manager = null
var _ui_manager = null
var _show_status := Callable()
var _request_return_to_menu := Callable()
var _request_quit_game := Callable()

var _summary_title_label: Label = null
var _summary_stats_label: Label = null
var _condition_stats_label: Label = null
var _goal_label: Label = null
var _fade_debug_label: Label = null
var _open_routes_button: Button = null
var _return_to_menu_button: Button = null
var _quit_game_button: Button = null

var _panel: PanelContainer = null
var _status_label: Label = null
var _route_summary_label: Label = null
var _wait_button: Button = null
var _sell_scrap_button: Button = null
var _rest_button: Button = null
var _current_route: StringName = ROUTE_TOWN


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_game_state_manager = deps.get("game_state_manager", null)
	_data_manager = deps.get("data_manager", null)
	_time_manager = deps.get("time_manager", null)
	_stats_manager = deps.get("stats_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_show_status = deps.get("show_status", Callable())
	_request_return_to_menu = deps.get("request_return_to_menu", Callable())
	_request_quit_game = deps.get("request_quit_game", Callable())

	_summary_title_label = deps.get("summary_title_label", null)
	_summary_stats_label = deps.get("summary_stats_label", null)
	_condition_stats_label = deps.get("condition_stats_label", null)
	_goal_label = deps.get("goal_label", null)
	_fade_debug_label = deps.get("fade_debug_label", null)
	_open_routes_button = deps.get("open_routes_button", null)
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


func refresh_from_state(player_state) -> void:
	if _summary_title_label == null:
		return
	if player_state == null:
		_summary_title_label.text = "First Playable Loop"
		_summary_stats_label.text = "Shared state is unavailable."
		_condition_stats_label.text = ""
		_goal_label.text = ""
		if _status_label != null:
			_status_label.text = "The road will resolve once shared state is ready."
		if _route_summary_label != null:
			_route_summary_label.text = ""
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
	if _open_routes_button != null:
		_open_routes_button.text = "Travel / Routes"
	if _return_to_menu_button != null:
		_return_to_menu_button.text = "Exit to Menu"
		_return_to_menu_button.visible = true
	if _quit_game_button != null:
		_quit_game_button.visible = false

	var in_camp = _current_route == ROUTE_CAMP
	if _status_label != null:
		_status_label.text = "Camp is a working camp: rest, wash, cooking, and repair." if in_camp else "Town is where leads, wages, supplies, and remittance are turned into the next move."
	if _route_summary_label != null:
		_route_summary_label.text = _build_route_summary(player_state, config, in_camp)
	if _wait_button != null:
		_wait_button.visible = not in_camp
		_wait_button.text = "Wait %s" % _format_duration(config.wait_action_minutes) if config != null else "Wait"
	if _sell_scrap_button != null:
		_sell_scrap_button.visible = not in_camp
		_sell_scrap_button.text = "Sell Scrap\n%s | %s for %d scrap" % [
			_format_duration(config.sell_scrap_minutes),
			_format_cents(config.sell_scrap_pay_cents),
			config.sell_scrap_quantity
		] if config != null else "Sell Scrap"
	if _rest_button != null:
		_rest_button.visible = in_camp


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
	page_host.add_child(_panel)

	var root = VBoxContainer.new()
	root.name = "WorldMapPageRoot"
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(root)

	var title = Label.new()
	title.text = "World Map"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)

	_route_summary_label = Label.new()
	_route_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_route_summary_label)

	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	root.add_child(action_row)

	var routes_button = Button.new()
	routes_button.text = "Travel / Routes"
	routes_button.custom_minimum_size = Vector2(220.0, 44.0)
	routes_button.pressed.connect(Callable(self, "_open_routes"))
	action_row.add_child(routes_button)

	_wait_button = Button.new()
	_wait_button.custom_minimum_size = Vector2(180.0, 44.0)
	_wait_button.pressed.connect(Callable(self, "_on_wait_pressed"))
	action_row.add_child(_wait_button)

	_sell_scrap_button = Button.new()
	_sell_scrap_button.custom_minimum_size = Vector2(220.0, 44.0)
	_sell_scrap_button.pressed.connect(Callable(self, "_on_sell_scrap_pressed"))
	action_row.add_child(_sell_scrap_button)

	_rest_button = Button.new()
	_rest_button.text = "Rest / Camp"
	_rest_button.custom_minimum_size = Vector2(180.0, 44.0)
	_rest_button.pressed.connect(Callable(self, "_open_rest"))
	action_row.add_child(_rest_button)


func _connect_buttons() -> void:
	if _open_routes_button != null and not _open_routes_button.pressed.is_connected(Callable(self, "_open_routes")):
		_open_routes_button.pressed.connect(Callable(self, "_open_routes"))
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


func _on_wait_pressed() -> void:
	_execute_action(SurvivalLoopRulesScript.ACTION_WAIT, "world_map.wait")


func _on_sell_scrap_pressed() -> void:
	_execute_action(SurvivalLoopRulesScript.ACTION_SELL_SCRAP, "world_map.sell_scrap")


func _open_routes() -> void:
	if _ui_manager != null:
		_ui_manager.switch_to(&"travel_ui")


func _open_rest() -> void:
	if _ui_manager != null:
		_ui_manager.switch_to(&"rest_camp")


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
		_ui_manager.switch_to(_current_route)


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(amount_cents) / 100.0)


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes
