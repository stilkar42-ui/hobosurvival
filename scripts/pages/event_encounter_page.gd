class_name EventEncounterPage
extends RefCounted

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")
const PlayerStateServiceScript := preload("res://scripts/player/player_state_service.gd")

var _status_label: Label = null
var _result_panel: PanelContainer = null
var _result_title_label: Label = null
var _result_body_label: Label = null
var _reset_run_button: Button = null
var _go_debug_button: Button = null
var _game_state_manager = null
var _build_action_context := Callable()
var _execute_state_action := Callable()
var _request_debug_page := Callable()

var _last_status_message := "Take stock of the day."


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_status_label = deps.get("status_label", null)
	_result_panel = deps.get("result_panel", null)
	_result_title_label = deps.get("result_title_label", null)
	_result_body_label = deps.get("result_body_label", null)
	_reset_run_button = deps.get("reset_run_button", null)
	_go_debug_button = deps.get("go_debug_button", null)
	_game_state_manager = deps.get("game_state_manager", null)
	_build_action_context = deps.get("build_action_context", Callable())
	_execute_state_action = deps.get("execute_state_action", Callable())
	_request_debug_page = deps.get("request_debug_page", Callable())

	if _reset_run_button != null and not _reset_run_button.pressed.is_connected(Callable(self, "_on_reset_run_pressed")):
		_reset_run_button.pressed.connect(Callable(self, "_on_reset_run_pressed"))
	if _go_debug_button != null and not _go_debug_button.pressed.is_connected(Callable(self, "_on_go_debug_pressed")):
		_go_debug_button.pressed.connect(Callable(self, "_on_go_debug_pressed"))
	_apply_layout_theme()
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)
	show_status(_last_status_message)


func set_visible(_visible: bool) -> void:
	pass


func set_route(_route_id: StringName) -> void:
	pass


func refresh_from_state(player_state) -> void:
	if _result_panel == null:
		return
	if player_state == null:
		_result_panel.visible = false
		return
	_result_panel.visible = player_state.prototype_loop_status != &"ongoing"
	if not _result_panel.visible:
		return
	if player_state.prototype_loop_status == &"success":
		if _result_title_label != null:
			_result_title_label.text = "Support Sent"
		if _result_body_label != null:
			_result_body_label.text = "You got enough delivered home before the month closed."
	else:
		if _result_title_label != null:
			_result_title_label.text = "Run Broken"
		if _result_body_label != null:
			_result_body_label.text = "You ran out of time, Nutrition, or strength before enough support reached home."


func show_status(message: String) -> void:
	_last_status_message = message
	if _status_label != null:
		_status_label.text = message


func show_action_result(result: Dictionary, fallback_message: String = "") -> void:
	var message = String(result.get("message", fallback_message)).strip_edges()
	if message == "":
		message = fallback_message
	show_status(message)


func handle_input(_event: InputEvent) -> bool:
	return false


func _on_reset_run_pressed() -> void:
	if _execute_state_action.is_null():
		return
	var context = _build_action_context.call("loop.reset", {})
	var result = _execute_state_action.call(PlayerStateServiceScript.ACTION_RESET_TO_STARTER, context)
	show_action_result(result, "Run reset.")


func _on_go_debug_pressed() -> void:
	if not _request_debug_page.is_null():
		_request_debug_page.call()


func _apply_layout_theme() -> void:
	PageUIThemeScript.style_body_label(_status_label)
	PageUIThemeScript.apply_panel_variant(_result_panel, "alt")
	PageUIThemeScript.style_section_label(_result_title_label, true)
	PageUIThemeScript.style_body_label(_result_body_label)
	PageUIThemeScript.style_button(_reset_run_button, true)
	PageUIThemeScript.style_button(_go_debug_button)
