class_name TravelPage
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _location_manager = null
var _ui_manager = null
var _show_status := Callable()

var _panel: PanelContainer = null
var _summary_label: Label = null
var _back_button: Button = null
var _go_to_camp_button: Button = null
var _return_to_town_button: Button = null
var _return_route: StringName = &"town"


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


func set_route(_route_name: StringName) -> void:
	set_visible(true)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible


func refresh_from_state(player_state) -> void:
	if _summary_label == null:
		return
	if player_state == null:
		_summary_label.text = "Travel and route context are unavailable."
		return
	var config = _data_manager.get_loop_config() if _data_manager != null else null
	var in_town = _location_manager.is_town_location(player_state.loop_location_id) if _location_manager != null else true
	var at_camp = _location_manager.is_camp_location(player_state.loop_location_id) if _location_manager != null else false
	_summary_label.text = "Travel only handles movement. Distance costs time, alters exposure, and changes which town or camp pressures you can act on next."
	if _go_to_camp_button != null:
		_go_to_camp_button.visible = in_town
		_go_to_camp_button.text = "Go to Camp\n%s travel" % _format_duration(config.town_to_camp_travel_minutes) if config != null else "Go to Camp"
	if _return_to_town_button != null:
		_return_to_town_button.visible = at_camp
		_return_to_town_button.text = "Return to Town\n%s travel" % _format_duration(config.camp_to_town_travel_minutes) if config != null else "Return to Town"


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
	_panel.name = "TravelPagePanel"
	_panel.visible = false
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.add_child(_panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(root)
	PageUIThemeScript.apply_panel_variant(_panel, "panel")

	var title = Label.new()
	title.text = "Travel"
	PageUIThemeScript.style_header_label(title, true)
	root.add_child(title)

	var summary_section := PageUIThemeScript.create_section_panel("MOVEMENT", "highlight")
	root.add_child(summary_section.panel)
	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_summary_label)
	summary_section.root.add_child(_summary_label)

	_back_button = Button.new()
	_back_button.text = "Back to World"
	_back_button.custom_minimum_size = Vector2(220.0, 42.0)
	_back_button.pressed.connect(Callable(self, "_go_back"))
	PageUIThemeScript.style_button(_back_button)
	root.add_child(_back_button)

	var movement_section := PageUIThemeScript.create_section_panel("TRAVEL OPTIONS")
	root.add_child(movement_section.panel)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	movement_section.root.add_child(grid)

	_go_to_camp_button = _make_button("Go to Camp", Callable(self, "_travel_to_camp"))
	_return_to_town_button = _make_button("Return to Town", Callable(self, "_travel_to_town"))

	grid.add_child(_go_to_camp_button)
	grid.add_child(_return_to_town_button)


func _make_button(label_text: String, pressed_callable: Callable) -> Button:
	var button = Button.new()
	button.text = label_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(pressed_callable)
	PageUIThemeScript.style_button(button, true)
	return button


func _travel_to_camp() -> void:
	_execute_travel(SurvivalLoopRulesScript.ACTION_GO_TO_CAMP)


func _travel_to_town() -> void:
	_execute_travel(SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN)


func _execute_travel(action_id: StringName) -> void:
	if _game_state_manager == null or _ui_manager == null:
		return
	var result = _game_state_manager.execute_action(String(action_id), {"source": "travel.page"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))
	var player_state = _game_state_manager.get_player_state()
	var destination = _location_manager.get_default_route_for_location(player_state.loop_location_id) if player_state != null and _location_manager != null else &"town"
	_ui_manager.open_page(destination)


func _go_back() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(_return_route)


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes
