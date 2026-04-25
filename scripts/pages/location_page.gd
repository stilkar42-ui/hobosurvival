class_name LocationPage
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")
const ActionButtonWidgetScript := preload("res://scripts/ui/widgets/action_button_widget.gd")
const ActionCardWidgetScript := preload("res://scripts/ui/widgets/action_card_widget.gd")
const BasePanelWidgetScript := preload("res://scripts/ui/widgets/base_panel_widget.gd")
const DataPanelWidgetScript := preload("res://scripts/ui/widgets/data_panel_widget.gd")
const FeatureWindowWidgetScript := preload("res://scripts/ui/widgets/feature_window_widget.gd")
const ShopStockWidgetScript := preload("res://scripts/ui/widgets/shop_stock_widget.gd")
const VerticalListWidgetScript := preload("res://scripts/ui/widgets/vertical_list_widget.gd")

var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _location_manager = null
var _ui_manager = null
var _show_status := Callable()

var _panel: PanelContainer = null
var _hub_panel: PanelContainer = null
var _service_window_layer: Control = null
var _service_window = null
var _route_roots: Dictionary = {}
var _current_route: StringName = &""
var _return_route: StringName = &"town"
var _has_context_route := false
var _selected_send_amount_cents := 125

var _jobs_list_widget = null
var _send_summary_widget = null
var _send_cash_widget = null
var _send_amount_spinbox: SpinBox = null
var _send_mail_custom_button = null
var _send_telegraph_custom_button = null
var _grocery_shop_widget = null
var _hardware_shop_widget = null
var _general_shop_widget = null
var _medicine_shop_widget = null
var _doctor_summary_widget = null
var _doctor_list_widget = null
var _service_nav_buttons: Dictionary = {}


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_game_state_manager = deps.get("game_state_manager", null)
	_data_manager = deps.get("data_manager", null)
	_time_manager = deps.get("time_manager", null)
	_location_manager = deps.get("location_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_show_status = deps.get("show_status", Callable())
	_build_panel(deps.get("page_host", null))
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_context(context: Dictionary) -> void:
	_return_route = StringName(context.get("return_route", _return_route))
	var requested_route = StringName(context.get("route_id", &""))
	_has_context_route = requested_route != &"" and _route_roots.has(requested_route)
	if _has_context_route:
		_current_route = requested_route
	else:
		_current_route = &""


func set_route(route_name: StringName) -> void:
	if route_name in _route_roots:
		_current_route = route_name
	elif _location_manager != null and route_name == _location_manager.ROUTE_LOCATION_PAGE:
		if not _has_context_route:
			_current_route = &""
	_apply_visibility(true)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_visible(visible: bool) -> void:
	_apply_visibility(visible)


func refresh_from_state(player_state) -> void:
	if player_state == null or _data_manager == null:
		return
	_rebuild_job_board(player_state)
	_refresh_send_money(player_state)
	_refresh_store_stock_sections(player_state)
	_refresh_doctor_care(player_state)


func handle_input(event: InputEvent) -> bool:
	if _panel == null or not _panel.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		if _service_window != null and _service_window.visible:
			_show_hub_only()
			return true
		_go_back()
		return true
	return false


func _build_panel(page_host) -> void:
	if page_host == null:
		return
	_panel = PanelContainer.new()
	_panel.name = "LocationPagePanel"
	_panel.visible = false
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(_panel, "panel")
	page_host.add_child(_panel)

	var canvas = Control.new()
	canvas.name = "TownServicesCanvas"
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2.ZERO
	_panel.add_child(canvas)

	_hub_panel = PanelContainer.new()
	_hub_panel.name = "TownServicesHub"
	_hub_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hub_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hub_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(_hub_panel, "alt")
	canvas.add_child(_hub_panel)

	var hub_root = VBoxContainer.new()
	hub_root.name = "TownServicesHubRoot"
	hub_root.add_theme_constant_override("separation", 10)
	hub_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hub_panel.add_child(hub_root)
	hub_root.add_child(_build_service_nav_panel())
	var hub_note = Label.new()
	hub_note.text = "Choose a town service. Each service opens as a separate window over this hub."
	hub_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(hub_note)
	hub_root.add_child(hub_note)
	hub_root.add_child(_make_back_button())

	_service_window_layer = Control.new()
	_service_window_layer.name = "TownServiceWindowLayer"
	_service_window_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_service_window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_service_window_layer)

	_service_window = FeatureWindowWidgetScript.new()
	_service_window.name = "TownServiceFeatureWindow"
	_service_window.visible = false
	_service_window.closed.connect(Callable(self, "_on_service_window_closed"))
	_service_window_layer.add_child(_service_window)

	for route_id in [&"jobs_board", &"send_money", &"grocery", &"hardware", &"general_store", &"medicine", &"doctor_apothecary"]:
		var route_panel = PanelContainer.new()
		route_panel.name = "%sRoute" % String(route_id)
		route_panel.visible = false
		route_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		PageUIThemeScript.apply_panel_variant(route_panel, "dark")
		var route_root = VBoxContainer.new()
		route_root.name = "PageRoot"
		route_root.add_theme_constant_override("separation", 10)
		route_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		route_panel.add_child(route_root)
		_service_window.get_content_root().add_child(route_panel)
		_route_roots[route_id] = route_panel

	_build_jobs_board_page()
	_build_send_money_page()
	_build_grocery_page()
	_build_hardware_page()
	_build_general_store_page()
	_build_medicine_store_page()
	_build_doctor_apothecary_page()


func _build_jobs_board_page() -> void:
	var root = _get_route_root(&"jobs_board")
	_add_title(root, "Jobs Board", "Posted work is public, limited by the hour, and never promised twice.")
	_jobs_list_widget = VerticalListWidgetScript.new()
	_jobs_list_widget.name = "JobsListWidget"
	_jobs_list_widget.set_title("Posted Work")
	_jobs_list_widget.set_variant("dark")
	_configure_content_list(_jobs_list_widget)
	root.add_child(_jobs_list_widget)


func _build_send_money_page() -> void:
	var root = _get_route_root(&"send_money")
	_add_title(root, "Send Money", "A money order is not progress. It is proof the day was turned into help at home.")

	_send_summary_widget = DataPanelWidgetScript.new()
	_send_summary_widget.set_title("Obligation")
	root.add_child(_send_summary_widget)

	_send_cash_widget = DataPanelWidgetScript.new()
	_send_cash_widget.set_title("Cash on Hand", true)
	_send_cash_widget.set_variant("alt")
	root.add_child(_send_cash_widget)

	var send_small_button = ActionButtonWidgetScript.new()
	send_small_button.set_action_id(SurvivalLoopRulesScript.ACTION_SEND_SMALL)
	send_small_button.set_label("Send Small Amount")
	send_small_button.pressed.connect(Callable(self, "_on_simple_send_pressed"))
	root.add_child(send_small_button)

	var send_large_button = ActionButtonWidgetScript.new()
	send_large_button.set_action_id(SurvivalLoopRulesScript.ACTION_SEND_LARGE)
	send_large_button.set_label("Send Larger Amount")
	send_large_button.set_accent(false)
	send_large_button.pressed.connect(Callable(self, "_on_simple_send_pressed"))
	root.add_child(send_large_button)

	var custom_panel = BasePanelWidgetScript.new()
	custom_panel.set_title("Exact Amount")
	custom_panel.set_variant("dark")
	root.add_child(custom_panel)

	var custom_label = Label.new()
	custom_label.text = "Choose an exact amount to send home."
	custom_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_small_label(custom_label)
	custom_panel.get_content_root().add_child(custom_label)

	_send_amount_spinbox = SpinBox.new()
	_send_amount_spinbox.min_value = 0.01
	_send_amount_spinbox.max_value = 9999.99
	_send_amount_spinbox.step = 0.01
	_send_amount_spinbox.value = float(_selected_send_amount_cents) / 100.0
	_send_amount_spinbox.custom_minimum_size = Vector2(220.0, 0.0)
	_send_amount_spinbox.value_changed.connect(Callable(self, "_on_send_amount_changed"))
	custom_panel.get_content_root().add_child(_send_amount_spinbox)

	_send_mail_custom_button = ActionButtonWidgetScript.new()
	_send_mail_custom_button.set_action_id(&"mail")
	_send_mail_custom_button.pressed.connect(Callable(self, "_on_custom_send_pressed"))
	custom_panel.get_content_root().add_child(_send_mail_custom_button)

	_send_telegraph_custom_button = ActionButtonWidgetScript.new()
	_send_telegraph_custom_button.set_action_id(&"telegraph")
	_send_telegraph_custom_button.set_accent(false)
	_send_telegraph_custom_button.pressed.connect(Callable(self, "_on_custom_send_pressed"))
	custom_panel.get_content_root().add_child(_send_telegraph_custom_button)


func _build_grocery_page() -> void:
	var root = _get_route_root(&"grocery")
	_add_title(root, "Grocery Store", "Food, coffee, and small comforts bought out of the stake.")
	_grocery_shop_widget = _build_shop_widget("GroceryShopStockWidget")
	root.add_child(_grocery_shop_widget)


func _build_hardware_page() -> void:
	var root = _get_route_root(&"hardware")
	_add_title(root, "Hardware Store", "Small practical gear for camp, fire, repair, and boiling water.")
	_hardware_shop_widget = _build_shop_widget("HardwareShopStockWidget")
	root.add_child(_hardware_shop_widget)


func _build_general_store_page() -> void:
	var root = _get_route_root(&"general_store")
	_add_title(root, "General Store", "A limited shelf of food, camp goods, and small household necessities.")
	_general_shop_widget = _build_shop_widget("GeneralStoreShopStockWidget")
	root.add_child(_general_shop_widget)


func _build_medicine_store_page() -> void:
	var root = _get_route_root(&"medicine")
	_add_title(root, "Medicine Store", "Apothecary stock for cleaning up, foot care, common remedies, and trade. Paid care is handled at Doctor / Apothecary.")
	_medicine_shop_widget = _build_shop_widget("MedicineStoreShopStockWidget")
	root.add_child(_medicine_shop_widget)


func _build_doctor_apothecary_page() -> void:
	var root = _get_route_root(&"doctor_apothecary")
	_add_title(root, "Doctor / Apothecary", "Basic paid care, remedies, and advice. It can steady a man; it does not resolve wounds or sickness.")
	_doctor_summary_widget = DataPanelWidgetScript.new()
	_doctor_summary_widget.set_title("Care Summary")
	_configure_compact_panel(_doctor_summary_widget)
	root.add_child(_doctor_summary_widget)
	_doctor_list_widget = VerticalListWidgetScript.new()
	_doctor_list_widget.name = "DoctorApothecaryListWidget"
	_doctor_list_widget.set_title("Available Care")
	_doctor_list_widget.set_variant("dark")
	_configure_content_list(_doctor_list_widget)
	root.add_child(_doctor_list_widget)


func _apply_visibility(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible
	if not visible:
		if _service_window != null:
			_service_window.visible = false
		_set_route_panel_visibility(&"")
	elif _current_route != &"":
		_open_service_window(_current_route)
	else:
		_show_hub_only()
	_refresh_service_nav()


func _rebuild_job_board(player_state) -> void:
	_jobs_list_widget.clear_items()
	if player_state == null or player_state.daily_job_board.is_empty():
		var empty_widget = DataPanelWidgetScript.new()
		empty_widget.set_title("No Work")
		empty_widget.set_data("No work is posted right now.")
		_jobs_list_widget.add_item(empty_widget)
		return
	for job in player_state.daily_job_board:
		if not (job is Dictionary):
			continue
		var instance_id = StringName(job.get("instance_id", &""))
		var availability = _game_state_manager.get_job_action_availability(instance_id) if _game_state_manager != null else {"enabled": false, "reason": "Unavailable"}
		var card = ActionCardWidgetScript.new()
		card.set_data({
			"action_id": instance_id,
			"title": String(job.get("title", "Job")),
			"description": String(job.get("summary", "")),
			"requirements": [
				"%s | %s | %s | %s" % [
					_format_job_category(StringName(job.get("job_category", &"day_labor"))),
					_format_duration(int(job.get("duration_minutes", 0))),
					_format_cents(int(job.get("pay_cents", 0))),
					_format_job_expiry_text(job)
				],
				"Requires: %s" % _format_job_appearance_requirement(job)
			],
			"status": "Tradeoff: %s\nNow: %s" % [
				_format_job_consequence_text(job),
				"eligible" if bool(availability.get("enabled", false)) else String(availability.get("reason", "not eligible"))
			],
			"enabled": bool(availability.get("enabled", false)),
			"action_label": "Take Work",
			"tooltip_text": String(job.get("summary", ""))
		})
		card.selected.connect(Callable(self, "_on_job_pressed"))
		_jobs_list_widget.add_item(card)


func _refresh_send_money(player_state) -> void:
	var config = _data_manager.get_loop_config()
	_send_summary_widget.set_data(_build_send_money_summary(player_state, config))
	_send_cash_widget.set_data("Current cash on hand: %s" % _format_cents(player_state.money_cents))
	_send_mail_custom_button.set_label(_build_send_method_button_text(config, &"mail", _selected_send_amount_cents))
	_send_telegraph_custom_button.set_label(_build_send_method_button_text(config, &"telegraph", _selected_send_amount_cents))
	if _send_amount_spinbox != null:
		_send_amount_spinbox.value = float(_selected_send_amount_cents) / 100.0


func _refresh_store_stock_sections(player_state) -> void:
	var config = _data_manager.get_loop_config()
	var item_catalog = _data_manager.get_item_catalog()
	var week_index = player_state.store_stock_week_index
	_refresh_store_shop_widget(
		_grocery_shop_widget,
		SurvivalLoopRulesScript.STORE_GROCERY,
		"Grocery Stock",
		"Week %d town stock. It changes each week; quality and price both matter." % week_index,
		SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_GROCERY)
	)
	_refresh_store_shop_widget(
		_hardware_shop_widget,
		SurvivalLoopRulesScript.STORE_HARDWARE,
		"Hardware Stock",
		"Week %d hardware stock. Camp utility, repair bits, and small road materials." % week_index,
		SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_HARDWARE)
	)
	_refresh_store_shop_widget(
		_general_shop_widget,
		SurvivalLoopRulesScript.STORE_GENERAL,
		"General Store Stock",
		"Week %d general stock. Limited crossover goods for food, camp, and keeping clean." % week_index,
		SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_GENERAL)
	)
	_refresh_store_shop_widget(
		_medicine_shop_widget,
		SurvivalLoopRulesScript.STORE_MEDICINE,
		"Medicine Store Stock",
		"Week %d medicine stock. Apothecary goods are for inventory use and trade; paid care is separate." % week_index,
		SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_MEDICINE)
	)


func _refresh_doctor_care(_player_state) -> void:
	if _doctor_summary_widget == null or _doctor_list_widget == null:
		return
	var config = _data_manager.get_loop_config()
	_doctor_summary_widget.set_data("Paid town care can clean a man up, ease the road from his feet, and steady his morale. It does not treat wounds, disease, or dependence.")
	_doctor_list_widget.clear_items()
	var care_actions = SurvivalLoopRulesScript.get_doctor_care_actions(config)
	if care_actions.is_empty():
		var empty_widget = DataPanelWidgetScript.new()
		empty_widget.set_title("No Care")
		empty_widget.set_data("No doctor or apothecary care is available in this town.")
		_doctor_list_widget.add_item(empty_widget)
		return
	for care_action in care_actions:
		var action_id = StringName(care_action.get("action_id", &""))
		var availability = _game_state_manager.get_loop_action_availability(action_id) if _game_state_manager != null else {"enabled": false, "reason": "Unavailable"}
		var requirements: Array[String] = [
			"%s | %s" % [
				_format_cents(int(care_action.get("cost_cents", 0))),
				_format_duration(int(care_action.get("minutes", 0)))
			],
			_format_doctor_effects(care_action)
		]
		var blocked_reason = String(availability.get("reason", "")).strip_edges()
		if blocked_reason != "":
			requirements.append(blocked_reason)
		var card = ActionCardWidgetScript.new()
		card.set_data({
			"action_id": action_id,
			"title": String(care_action.get("title", "Care")),
			"description": String(care_action.get("description", "")),
			"requirements": requirements,
			"status": _format_cents(int(care_action.get("cost_cents", 0))),
			"enabled": bool(availability.get("enabled", false)),
			"action_label": "Care Action"
		})
		card.selected.connect(Callable(self, "_on_doctor_care_selected"))
		_doctor_list_widget.add_item(card)


func _refresh_store_shop_widget(widget, store_id: StringName, title: String, summary: String, stock: Array) -> void:
	if widget == null:
		return
	var selected_index: int = widget.get_selected_stock_index() if widget.has_method("get_selected_stock_index") else 0
	if selected_index < 0:
		selected_index = 0
	widget.set_store_title(title, summary)
	widget.set_stock_items(store_id, _build_shop_stock_entries(stock), selected_index)


func _build_shop_widget(widget_name: String):
	var widget = ShopStockWidgetScript.new()
	widget.name = widget_name
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	widget.size_flags_vertical = Control.SIZE_EXPAND_FILL
	widget.custom_minimum_size = Vector2(0.0, 420.0)
	widget.buy_requested.connect(Callable(self, "_on_shop_stock_buy_requested"))
	return widget


func _build_shop_stock_entries(stock: Array) -> Array:
	var entries: Array = []
	for index in range(stock.size()):
		var entry = stock[index]
		if not (entry is Dictionary):
			continue
		var item = _data_manager.get_item_definition(StringName(entry.get("item_id", &""))) if _data_manager != null else null
		entries.append({
			"stock_index": index,
			"title": _format_store_stock_title(entry, item),
			"button_text": _format_store_stock_button_text(entry, item),
			"description": _format_store_stock_description(entry, item),
			"detail_lines": _build_store_stock_detail_lines(entry, item),
			"tooltip_text": _format_store_stock_description(entry, item),
			"enabled": true
		})
	return entries


func _on_simple_send_pressed(action_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(action_id), {"source": "location.send_simple"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_send_amount_changed(value: float) -> void:
	_selected_send_amount_cents = max(int(round(value * 100.0)), 1)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_custom_send_pressed(method_id: StringName) -> void:
	var context = {
		"source": "location.send_money.custom",
		"amount_cents": _selected_send_amount_cents,
		"method_id": method_id
	}
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_SEND_SUPPORT), context)
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_job_pressed(instance_id: StringName) -> void:
	var result = _game_state_manager.perform_job_action(instance_id)
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_shop_stock_buy_requested(store_id: StringName, stock_index: int) -> void:
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK), {
		"source": "location.store.stock",
		"store_id": store_id,
		"selected_stack_index": stock_index
	})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_doctor_care_selected(action_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(action_id), {"source": "location.doctor_apothecary"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _build_service_nav_panel() -> Control:
	var panel = BasePanelWidgetScript.new()
	panel.name = "TownServicesNavPanel"
	panel.set_title("Town Services")
	panel.set_variant("panel")
	_configure_compact_panel(panel)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.get_content_root().add_child(grid)

	for action_data in [
		{"route_id": &"jobs_board", "label": "Posted Work"},
		{"route_id": &"send_money", "label": "Send Money"},
		{"route_id": &"grocery", "label": "Grocery"},
		{"route_id": &"hardware", "label": "Hardware"},
		{"route_id": &"general_store", "label": "General Store"},
		{"route_id": &"medicine", "label": "Medicine Store"},
		{"route_id": &"doctor_apothecary", "label": "Doctor / Apothecary"}
	]:
		var button = ActionButtonWidgetScript.new()
		button.set_action_id(action_data.route_id)
		button.set_label(String(action_data.label))
		button.pressed.connect(Callable(self, "_on_service_nav_pressed"))
		grid.add_child(button)
		var bucket: Array = _service_nav_buttons.get(action_data.route_id, [])
		bucket.append(button)
		_service_nav_buttons[action_data.route_id] = bucket
	return panel


func _configure_content_list(list_widget: Control) -> void:
	list_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_widget.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_widget.custom_minimum_size = Vector2(0.0, 360.0)


func _configure_compact_panel(panel: Control) -> void:
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _refresh_service_nav() -> void:
	for route_id in _service_nav_buttons.keys():
		var buttons: Array = _service_nav_buttons.get(route_id, [])
		for button in buttons:
			if button == null:
				continue
			button.set_enabled(true)
			button.set_accent(StringName(route_id) == _current_route)


func _on_service_nav_pressed(route_id: StringName) -> void:
	_open_service_window(route_id)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _open_service_window(route_id: StringName) -> void:
	if _service_window == null or not _route_roots.has(route_id):
		return
	_current_route = route_id
	_set_route_panel_visibility(route_id)
	_service_window.set_window_title(_get_route_window_title(route_id))
	_service_window.visible = true
	_size_service_window()
	call_deferred("_size_service_window")
	_refresh_service_nav()


func _show_hub_only() -> void:
	_current_route = &""
	_set_route_panel_visibility(&"")
	if _service_window != null:
		_service_window.visible = false
	_refresh_service_nav()


func _set_route_panel_visibility(route_id: StringName) -> void:
	for route_name in _route_roots.keys():
		var route_panel = _route_roots[route_name]
		if route_panel != null:
			route_panel.visible = route_id != &"" and StringName(route_name) == route_id


func _size_service_window() -> void:
	if _service_window == null or _service_window_layer == null:
		return
	var layer_size = _service_window_layer.get_rect().size
	if layer_size == Vector2.ZERO:
		return
	var window_size = Vector2(
		max(min(layer_size.x - 28.0, 900.0), min(layer_size.x, 560.0)),
		max(min(layer_size.y - 28.0, 560.0), min(layer_size.y, 420.0))
	)
	_service_window.set_window_size(window_size)
	_service_window.center_in_parent()


func _get_route_window_title(route_id: StringName) -> String:
	match route_id:
		&"jobs_board":
			return "Jobs Board"
		&"send_money":
			return "Send Money"
		&"grocery":
			return "Grocery Store"
		&"hardware":
			return "Hardware Store"
		&"general_store":
			return "General Store"
		&"medicine":
			return "Medicine Store"
		&"doctor_apothecary":
			return "Doctor / Apothecary"
		_:
			return "Town Service"


func _on_service_window_closed() -> void:
	_show_hub_only()


func _make_back_button():
	var button = ActionButtonWidgetScript.new()
	button.set_action_id(&"back")
	button.set_label("Back to World")
	button.set_accent(false)
	button.pressed.connect(Callable(self, "_on_back_pressed"))
	return button


func _on_back_pressed(_action_id: StringName) -> void:
	_go_back()


func _add_title(parent: VBoxContainer, title_text: String, body_text: String) -> void:
	var title = Label.new()
	title.text = title_text
	PageUIThemeScript.style_header_label(title, true)
	parent.add_child(title)
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(body)
	parent.add_child(body)


func _get_route_root(route_id: StringName) -> VBoxContainer:
	var panel = _route_roots.get(route_id, null)
	return panel.get_child(0) if panel != null else null


func _build_send_money_summary(player_state, config) -> String:
	var current_obligation = player_state.get_current_support_obligation()
	var obligation_text = "No open support due."
	if not current_obligation.is_empty():
		obligation_text = "%s: %s delivered toward %s, due end of Day %d." % [
			String(current_obligation.get("label", "Support")),
			_format_cents(int(current_obligation.get("delivered_cents", 0))),
			_format_cents(int(current_obligation.get("target_cents", 0))),
			int(current_obligation.get("checkpoint_day", player_state.day_limit))
		]
	return "%s\nMonth: %s delivered toward %s. Mail is cheap but only counts when it arrives; telegraph costs more and counts today." % [
		obligation_text,
		_format_cents(player_state.support_delivered_total_cents),
		_format_cents(player_state.monthly_support_target_cents)
	]


func _build_send_method_button_text(config, method_id: StringName, amount_cents: int) -> String:
	var method = _find_send_method(config, method_id)
	if method.is_empty():
		return "Send %s Home\nmethod unavailable" % _format_cents(amount_cents)
	var fee_cents = int(method.get("fee_cents", 0))
	var delay_days = int(method.get("delivery_delay_days", 0))
	var timing = "counts today" if delay_days <= 0 else "arrives after %d day%s" % [delay_days, "" if delay_days == 1 else "s"]
	return "%s: Send %s\nfee %s | %s" % [
		String(method.get("display_name", String(method_id).capitalize())),
		_format_cents(amount_cents),
		_format_cents(fee_cents),
		timing
	]


func _find_send_method(config, method_id: StringName) -> Dictionary:
	if config == null:
		return {}
	for method in SurvivalLoopRulesScript.get_support_send_methods(config):
		if method is Dictionary and StringName(method.get("method_id", &"")) == method_id:
			return method
	return {}


func _format_store_stock_title(entry: Dictionary, item) -> String:
	var quality_tier = int(entry.get("quality_tier", 1))
	var item_name = item.display_name if item != null else String(entry.get("item_id", "Unknown")).replace("_", " ")
	var quality_name = item.get_quality_name(quality_tier) if item != null else "common"
	return "%s %s" % [quality_name.capitalize(), item_name]


func _format_store_stock_requirements(entry: Dictionary, item) -> String:
	return "%s | Week %d" % [
		_format_cents(int(entry.get("price_cents", 0))),
		int(entry.get("week_index", 0))
	]


func _format_store_stock_button_text(entry: Dictionary, item) -> String:
	var item_name = item.display_name if item != null else String(entry.get("item_id", "Unknown")).replace("_", " ")
	return "%s\n%s" % [
		item_name,
		_format_cents(int(entry.get("price_cents", 0)))
	]


func _format_store_stock_description(entry: Dictionary, item) -> String:
	var description = String(item.description).strip_edges() if item != null else ""
	if description != "":
		return description
	return "Town week %d stock." % int(entry.get("week_index", 0))


func _build_store_stock_detail_lines(entry: Dictionary, item) -> Array[String]:
	var quality_tier = int(entry.get("quality_tier", 1))
	var quality_name = item.get_quality_name(quality_tier).capitalize() if item != null else "Common"
	return [
		"Quality: %s" % quality_name,
		"Price: %s" % _format_cents(int(entry.get("price_cents", 0))),
		"Store week: %d" % int(entry.get("week_index", 0)),
		"Item id: %s" % String(entry.get("item_id", "unknown"))
	]


func _format_job_category(category_id: StringName) -> String:
	return String(category_id).replace("_", " ").capitalize()


func _format_job_expiry_text(job: Dictionary) -> String:
	var player_state = _game_state_manager.get_player_state() if _game_state_manager != null else null
	if player_state == null:
		return "expiry unknown"
	var expires_on_day = int(job.get("expires_on_day", player_state.current_day))
	if expires_on_day <= player_state.current_day:
		return "expires tonight"
	return "expires Day %d" % expires_on_day


func _format_job_appearance_requirement(job: Dictionary) -> String:
	var explicit_text = String(job.get("appearance_requirement_text", "")).strip_edges()
	if explicit_text != "":
		return explicit_text
	var config = _data_manager.get_loop_config() if _data_manager != null else null
	var min_tier = StringName(job.get("min_appearance_tier", &""))
	var max_tier = StringName(job.get("max_appearance_tier", &""))
	if min_tier != &"":
		return "at least %s" % SurvivalLoopRulesScript.get_appearance_label(min_tier, config)
	if max_tier != &"":
		return "%s or rougher" % SurvivalLoopRulesScript.get_appearance_label(max_tier, config)
	return "no posted appearance requirement"


func _format_job_consequence_text(job: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append("%s for %s" % [_format_duration(int(job.get("duration_minutes", 0))), _format_cents(int(job.get("pay_cents", 0)))])
	var nutrition_drain = int(job.get("nutrition_drain", 0))
	var fatigue_delta = int(job.get("fatigue_delta", 0))
	var hygiene_delta = int(job.get("hygiene_delta", 0))
	var morale_delta = int(job.get("morale_delta", 0))
	if nutrition_drain > 0:
		parts.append("Nutrition -%d" % nutrition_drain)
	if fatigue_delta != 0:
		parts.append("Stamina %+d" % fatigue_delta)
	if hygiene_delta != 0:
		parts.append("Hygiene %+d" % hygiene_delta)
	if morale_delta != 0:
		parts.append("Morale %+d" % morale_delta)
	if StringName(job.get("required_item_id", &"")) != &"":
		parts.append("requires %s" % String(job.get("required_item_id", "")).replace("_", " "))
	return ", ".join(parts)


func _go_back() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(_return_route)


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(amount_cents) / 100.0)


func _format_doctor_effects(care_action: Dictionary) -> String:
	var parts: Array[String] = []
	var hygiene_gain = int(care_action.get("hygiene_gain", 0))
	var presentability_gain = int(care_action.get("presentability_gain", 0))
	var dampness_relief = int(care_action.get("dampness_relief", 0))
	var fatigue_relief = int(care_action.get("fatigue_relief", 0))
	var morale_gain = int(care_action.get("morale_gain", 0))
	if hygiene_gain > 0:
		parts.append("+%d Hygiene" % hygiene_gain)
	if presentability_gain > 0:
		parts.append("+%d Presentability" % presentability_gain)
	if dampness_relief > 0:
		parts.append("-%d Dampness" % dampness_relief)
	if fatigue_relief > 0:
		parts.append("+%d Stamina" % fatigue_relief)
	if morale_gain > 0:
		parts.append("+%d Morale" % morale_gain)
	if parts.is_empty():
		return "Effects: no condition change"
	return "Effects: %s" % ", ".join(parts)
