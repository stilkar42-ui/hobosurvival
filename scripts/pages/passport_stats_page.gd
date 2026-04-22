class_name PassportStatsPage
extends RefCounted

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _overlay: Control = null
var _close_button: Button = null
var _open_passport_button: Button = null
var _passport_panel = null
var _game_state_manager = null
var _ui_manager = null
var _resolve_return_route := Callable()
var _return_route: StringName = &"town"


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_overlay = deps.get("overlay", null)
	_close_button = deps.get("close_button", null)
	_open_passport_button = deps.get("open_passport_button", null)
	_passport_panel = deps.get("passport_panel", null)
	_game_state_manager = deps.get("game_state_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_resolve_return_route = deps.get("resolve_return_route", Callable())

	if _overlay != null:
		_overlay.visible = false
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_close")):
		_close_button.pressed.connect(Callable(self, "_close"))
	if _open_passport_button != null:
		_open_passport_button.text = "Open Passport"
		if not _open_passport_button.pressed.is_connected(Callable(self, "_open")):
			_open_passport_button.pressed.connect(Callable(self, "_open"))
	_apply_layout_theme()
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_context(context: Dictionary) -> void:
	_return_route = StringName(context.get("return_route", _return_route))


func set_route(_route_name: StringName) -> void:
	pass


func set_visible(visible: bool) -> void:
	if _overlay != null:
		_overlay.visible = visible


func refresh_from_state(player_state) -> void:
	if _passport_panel == null:
		return
	if player_state == null:
		_passport_panel.set_passport_data(null)
		return
	_passport_panel.set_passport_data(player_state.passport_profile)


func handle_input(event: InputEvent) -> bool:
	if _overlay == null or not _overlay.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		_close()
		return true
	return false


func _apply_layout_theme() -> void:
	if _overlay != null:
		PageUIThemeScript.style_overlay_backdrop(_overlay.get_node_or_null("Backdrop"))
		var window = _overlay.get_node_or_null("PassportMargin/PassportWindow") as PanelContainer
		PageUIThemeScript.apply_panel_variant(window, "panel")
		var title = _overlay.get_node_or_null("PassportMargin/PassportWindow/PassportRoot/PassportHeader/PassportTitle") as Label
		PageUIThemeScript.style_header_label(title, true)
	if _close_button != null:
		PageUIThemeScript.style_button(_close_button)
	if _open_passport_button != null:
		PageUIThemeScript.style_button(_open_passport_button, true)


func _open() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(&"passport_stats", {"return_route": _ui_manager.get_active_route()})


func _close() -> void:
	if _ui_manager == null:
		return
	var route = _return_route
	if route == &"" and not _resolve_return_route.is_null():
		route = StringName(_resolve_return_route.call())
	_ui_manager.open_page(route)
