class_name LocationPage
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _location_manager = null
var _ui_manager = null
var _show_status := Callable()

var _panel: PanelContainer = null
var _route_roots: Dictionary = {}
var _current_route: StringName = &"jobs_board"
var _return_route: StringName = &"town"
var _selected_send_amount_cents := 125

var _jobs_list: GridContainer = null
var _send_money_summary_label: Label = null
var _pending_support_label: Label = null
var _send_amount_spinbox: SpinBox = null
var _send_mail_custom_button: Button = null
var _send_telegraph_custom_button: Button = null
var _grocery_summary_label: Label = null
var _grocery_stock_list: VBoxContainer = null
var _hardware_summary_label: Label = null
var _hardware_stock_list: VBoxContainer = null


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
	if requested_route != &"":
		_current_route = requested_route


func set_route(route_name: StringName) -> void:
	if route_name in _route_roots:
		_current_route = route_name
	elif _location_manager != null and route_name == _location_manager.ROUTE_LOCATION_PAGE:
		var player_state = _game_state_manager.get_player_state() if _game_state_manager != null else null
		var location_id = StringName(player_state.loop_location_id) if player_state != null else SurvivalLoopRulesScript.LOCATION_TOWN
		var default_route = _location_manager.get_default_location_route_for_location(location_id)
		if default_route != &"":
			_current_route = default_route
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


func handle_input(event: InputEvent) -> bool:
	if _panel == null or not _panel.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
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
	page_host.add_child(_panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(root)

	for route_id in [&"jobs_board", &"send_money", &"grocery", &"hardware"]:
		var route_panel = PanelContainer.new()
		route_panel.name = "%sRoute" % String(route_id)
		route_panel.visible = false
		route_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(route_panel)
		var route_root = VBoxContainer.new()
		route_root.name = "PageRoot"
		route_root.add_theme_constant_override("separation", 10)
		route_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		route_panel.add_child(route_root)
		_route_roots[route_id] = route_panel

	_build_jobs_board_page()
	_build_send_money_page()
	_build_grocery_page()
	_build_hardware_page()


func _build_jobs_board_page() -> void:
	var root = _get_route_root(&"jobs_board")
	_add_title(root, "Jobs Board", "Posted work is public, limited by the hour, and never promised twice.")
	root.add_child(_make_back_button())
	_jobs_list = GridContainer.new()
	_jobs_list.columns = 2
	_jobs_list.add_theme_constant_override("h_separation", 10)
	_jobs_list.add_theme_constant_override("v_separation", 10)
	root.add_child(_jobs_list)


func _build_send_money_page() -> void:
	var root = _get_route_root(&"send_money")
	_add_title(root, "Send Money", "A money order is not progress. It is proof the day was turned into help at home.")
	root.add_child(_make_back_button())
	_send_money_summary_label = Label.new()
	_send_money_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_send_money_summary_label)
	_pending_support_label = Label.new()
	_pending_support_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_pending_support_label)

	var send_small_button = Button.new()
	send_small_button.text = "Send Small Amount"
	send_small_button.pressed.connect(Callable(self, "_send_simple").bind(SurvivalLoopRulesScript.ACTION_SEND_SMALL))
	root.add_child(send_small_button)

	var send_large_button = Button.new()
	send_large_button.text = "Send Larger Amount"
	send_large_button.pressed.connect(Callable(self, "_send_simple").bind(SurvivalLoopRulesScript.ACTION_SEND_LARGE))
	root.add_child(send_large_button)

	var custom_label = Label.new()
	custom_label.text = "Choose an exact amount to send home."
	custom_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(custom_label)

	_send_amount_spinbox = SpinBox.new()
	_send_amount_spinbox.min_value = 0.01
	_send_amount_spinbox.max_value = 9999.99
	_send_amount_spinbox.step = 0.01
	_send_amount_spinbox.value = float(_selected_send_amount_cents) / 100.0
	_send_amount_spinbox.custom_minimum_size = Vector2(220.0, 0.0)
	_send_amount_spinbox.value_changed.connect(Callable(self, "_on_send_amount_changed"))
	root.add_child(_send_amount_spinbox)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)
	_send_mail_custom_button = Button.new()
	_send_mail_custom_button.pressed.connect(Callable(self, "_on_send_support_pressed").bind(&"mail"))
	row.add_child(_send_mail_custom_button)
	_send_telegraph_custom_button = Button.new()
	_send_telegraph_custom_button.pressed.connect(Callable(self, "_on_send_support_pressed").bind(&"telegraph"))
	row.add_child(_send_telegraph_custom_button)


func _build_grocery_page() -> void:
	var root = _get_route_root(&"grocery")
	_add_title(root, "Grocery Store", "Food, coffee, and small comforts bought out of the stake.")
	root.add_child(_make_back_button())
	_grocery_summary_label = Label.new()
	_grocery_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_grocery_summary_label)
	_grocery_stock_list = VBoxContainer.new()
	_grocery_stock_list.add_theme_constant_override("separation", 8)
	root.add_child(_grocery_stock_list)


func _build_hardware_page() -> void:
	var root = _get_route_root(&"hardware")
	_add_title(root, "Hardware Store", "Small practical gear for camp, fire, repair, and boiling water.")
	root.add_child(_make_back_button())
	_hardware_summary_label = Label.new()
	_hardware_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_hardware_summary_label)
	_hardware_stock_list = VBoxContainer.new()
	_hardware_stock_list.add_theme_constant_override("separation", 8)
	root.add_child(_hardware_stock_list)


func _apply_visibility(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible
	for route_name in _route_roots.keys():
		var route_panel = _route_roots[route_name]
		route_panel.visible = visible and StringName(route_name) == _current_route


func _rebuild_job_board(player_state) -> void:
	_clear_children(_jobs_list)
	if player_state == null or player_state.daily_job_board.is_empty():
		_jobs_list.add_child(_wrapped_label("No work is posted right now."))
		return
	for job in player_state.daily_job_board:
		if not (job is Dictionary):
			continue
		var instance_id = StringName(job.get("instance_id", &""))
		var availability = _game_state_manager.get_job_action_availability(instance_id) if _game_state_manager != null else {"enabled": false, "reason": "Unavailable"}
		_jobs_list.add_child(_build_job_board_entry(job, availability))


func _refresh_send_money(player_state) -> void:
	var config = _data_manager.get_loop_config()
	_send_money_summary_label.text = _build_send_money_summary(player_state, config)
	_pending_support_label.text = "Current cash on hand: %s" % _format_cents(player_state.money_cents)
	_send_mail_custom_button.text = _build_send_method_button_text(config, &"mail", _selected_send_amount_cents)
	_send_telegraph_custom_button.text = _build_send_method_button_text(config, &"telegraph", _selected_send_amount_cents)
	if _send_amount_spinbox != null:
		_send_amount_spinbox.value = float(_selected_send_amount_cents) / 100.0


func _refresh_store_stock_sections(player_state) -> void:
	var config = _data_manager.get_loop_config()
	var item_catalog = _data_manager.get_item_catalog()
	var week_index = player_state.store_stock_week_index
	_grocery_summary_label.text = "Week %d town stock. It changes each week; quality and price both matter." % week_index
	_hardware_summary_label.text = "Week %d hardware stock. Camp utility, repair bits, and small road materials." % week_index
	_rebuild_store_stock_list(_grocery_stock_list, SurvivalLoopRulesScript.STORE_GROCERY, SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_GROCERY))
	_rebuild_store_stock_list(_hardware_stock_list, SurvivalLoopRulesScript.STORE_HARDWARE, SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_HARDWARE))


func _rebuild_store_stock_list(list_root: VBoxContainer, store_id: StringName, stock: Array) -> void:
	_clear_children(list_root)
	if stock.is_empty():
		list_root.add_child(_wrapped_label("No usable stock came in this week."))
		return
	for index in range(stock.size()):
		var entry = stock[index]
		if not (entry is Dictionary):
			continue
		var item = _data_manager.get_item_definition(StringName(entry.get("item_id", &"")))
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 64.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_store_stock_button_text(entry, item)
		button.pressed.connect(Callable(self, "_on_store_stock_pressed").bind(store_id, index))
		list_root.add_child(button)


func _build_job_board_entry(job: Dictionary, availability: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 180.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel.add_child(root)
	var title = _wrapped_label(String(job.get("title", "Job")))
	title.add_theme_font_size_override("font_size", 17)
	root.add_child(title)
	root.add_child(_wrapped_label(String(job.get("summary", ""))))
	root.add_child(_wrapped_label("%s | %s | %s | %s" % [
		_format_job_category(StringName(job.get("job_category", &"day_labor"))),
		_format_duration(int(job.get("duration_minutes", 0))),
		_format_cents(int(job.get("pay_cents", 0))),
		_format_job_expiry_text(job)
	]))
	root.add_child(_wrapped_label("Tradeoff: %s" % _format_job_consequence_text(job)))
	root.add_child(_wrapped_label("Requires: %s" % _format_job_appearance_requirement(job)))
	root.add_child(_wrapped_label("Now: %s" % ("eligible" if bool(availability.get("enabled", false)) else String(availability.get("reason", "not eligible")))))
	var action_button = Button.new()
	action_button.text = "Take Work"
	action_button.disabled = not bool(availability.get("enabled", false))
	action_button.pressed.connect(Callable(self, "_on_job_pressed").bind(StringName(job.get("instance_id", &""))))
	root.add_child(action_button)
	return panel


func _send_simple(action_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(action_id), {"source": "location.send_simple"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_send_amount_changed(value: float) -> void:
	_selected_send_amount_cents = max(int(round(value * 100.0)), 1)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_send_support_pressed(method_id: StringName) -> void:
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


func _on_store_stock_pressed(store_id: StringName, stock_index: int) -> void:
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK), {
		"source": "location.store.stock",
		"store_id": store_id,
		"selected_stack_index": stock_index
	})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _make_back_button() -> Button:
	var button = Button.new()
	button.text = "Back to World"
	button.custom_minimum_size = Vector2(180.0, 40.0)
	button.pressed.connect(Callable(self, "_go_back"))
	return button


func _add_title(parent: VBoxContainer, title_text: String, body_text: String) -> void:
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	parent.add_child(title)
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _format_store_stock_button_text(entry: Dictionary, item) -> String:
	var quality_tier = int(entry.get("quality_tier", 1))
	var item_name = item.display_name if item != null else String(entry.get("item_id", "Unknown")).replace("_", " ")
	var quality_name = item.get_quality_name(quality_tier) if item != null else "common"
	return "%s %s\n%s | Week %d" % [
		quality_name.capitalize(),
		item_name,
		_format_cents(int(entry.get("price_cents", 0))),
		int(entry.get("week_index", 0))
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


func _wrapped_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _go_back() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(_return_route)


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(amount_cents) / 100.0)
