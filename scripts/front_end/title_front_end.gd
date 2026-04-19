extends Control

const PAGE_RUN := &"run"
const PAGE_OPTIONS := &"options"
const PAGE_DEBUG := &"debug"

const DEBUG_SHELL_SCENE := preload("res://scenes/debug/main_debug_shell.tscn")
const PLAYABLE_START_SCENE := preload("res://scenes/front_end/first_playable_loop_page.tscn")
const PlaceholderPageScript := preload("res://scripts/ui/front_end_placeholder_page.gd")

@export var debug_enabled := true
@export var launch_fullscreen := true

@onready var subtitle_label = $Overlay/Margin/Layout/MenuColumn/SubTitle
@onready var start_button = $Overlay/Margin/Layout/MenuColumn/MenuPanel/MenuRoot/StartButton
@onready var options_button = $Overlay/Margin/Layout/MenuColumn/MenuPanel/MenuRoot/OptionsButton
@onready var debug_button = $Overlay/Margin/Layout/MenuColumn/MenuPanel/MenuRoot/DebugButton
@onready var quit_button = $Overlay/Margin/Layout/MenuColumn/MenuPanel/MenuRoot/QuitButton
@onready var content_column = $Overlay/Margin/Layout/ContentColumn
@onready var content_title_label = $Overlay/Margin/Layout/ContentColumn/ContentFrame/ContentRoot/ContentTitle
@onready var content_status_label = $Overlay/Margin/Layout/ContentColumn/ContentFrame/ContentRoot/ContentStatus
@onready var content_host = $Overlay/Margin/Layout/ContentColumn/ContentFrame/ContentRoot/ContentHost

var _pages := {}
var _run_page: Control = null
var _run_host: Control = null
var _current_page: StringName = &""


func _ready() -> void:
	_apply_launch_window_mode()
	_build_run_host()
	subtitle_label.text = "Labor, nutrition, weather, and distance still lie ahead. This is the threshold."
	start_button.pressed.connect(Callable(self, "_on_start_pressed"))
	options_button.pressed.connect(Callable(self, "_on_nav_pressed").bind(PAGE_OPTIONS))
	debug_button.pressed.connect(Callable(self, "_on_nav_pressed").bind(PAGE_DEBUG))
	quit_button.pressed.connect(Callable(self, "_on_quit_pressed"))
	debug_button.visible = debug_enabled
	_show_landing()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _current_page == PAGE_OPTIONS or _current_page == PAGE_DEBUG:
			_show_landing()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ENTER and event.alt_pressed:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _apply_launch_window_mode() -> void:
	if not launch_fullscreen:
		return
	if DisplayServer.get_name() == "headless":
		return
	# Fullscreen stays a front-end policy choice so later display settings can
	# toggle it without changing how run pages and front-end routes are hosted.
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_start_pressed() -> void:
	_show_page(PAGE_RUN)


func _on_nav_pressed(page_id: StringName) -> void:
	_show_page(page_id)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_landing() -> void:
	_clear_content_host()
	_clear_run_host()
	$Overlay.visible = true
	_run_host.visible = false
	content_column.visible = false
	_current_page = &""
	_refresh_navigation()


func _show_page(page_id: StringName) -> void:
	if page_id == PAGE_DEBUG and not debug_enabled:
		return
	var host = _run_host if page_id == PAGE_RUN else content_host
	if _current_page == page_id and host.get_child_count() > 0:
		return

	if page_id == PAGE_RUN:
		_clear_content_host()
		content_column.visible = false
		$Overlay.visible = false
		_run_host.visible = true
	else:
		_clear_run_host()
		$Overlay.visible = true
		_run_host.visible = false
		content_column.visible = true
		_clear_content_host()
	var page = _get_or_create_page(page_id)
	host.add_child(page)
	_current_page = page_id
	_refresh_navigation()
	if page_id != PAGE_RUN:
		_update_content_text()


func _get_or_create_page(page_id: StringName) -> Control:
	if page_id == PAGE_RUN:
		if _run_page == null:
			_run_page = PLAYABLE_START_SCENE.instantiate()
			if _run_page.has_signal("request_debug_page"):
				_run_page.connect("request_debug_page", Callable(self, "_on_run_page_request_debug"))
			if _run_page.has_signal("request_return_to_menu"):
				_run_page.connect("request_return_to_menu", Callable(self, "_on_run_page_request_return_to_menu"))
			if _run_page.has_signal("request_quit_game"):
				_run_page.connect("request_quit_game", Callable(self, "_on_quit_pressed"))
			_run_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_run_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		return _run_page

	if _pages.has(page_id):
		return _pages[page_id]

	var page: Control
	match page_id:
		PAGE_OPTIONS:
			page = _build_placeholder_page(
				"Options",
				"Settings are still ahead. This placeholder holds the place for display, audio, controls, accessibility, and debug visibility decisions later."
			)
		PAGE_DEBUG:
			page = DEBUG_SHELL_SCENE.instantiate()
		_:
			page = _build_placeholder_page("Missing Page", "No page is configured for this route yet.")

	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages[page_id] = page
	return page


func _build_placeholder_page(title_text: String, body_text: String) -> Control:
	var page = PlaceholderPageScript.new()
	page.configure(title_text, body_text)
	return page


func _refresh_navigation() -> void:
	start_button.disabled = _current_page == PAGE_RUN
	options_button.disabled = _current_page == PAGE_OPTIONS
	debug_button.disabled = _current_page == PAGE_DEBUG and debug_enabled


func _update_content_text() -> void:
	match _current_page:
		PAGE_RUN:
			content_title_label.text = "Start"
			content_status_label.text = "Work, endure, and send support home through the first playable loop."
		PAGE_OPTIONS:
			content_title_label.text = "Options"
			content_status_label.text = "Placeholder route for future settings."
		PAGE_DEBUG:
			content_title_label.text = "Debug"
			content_status_label.text = "Existing prototype shell with Passport and Inventory access."
		_:
			content_title_label.text = "Unknown"
			content_status_label.text = "No route details available."


func _clear_content_host() -> void:
	for child in content_host.get_children():
		content_host.remove_child(child)


func _clear_run_host() -> void:
	if _run_host == null:
		return
	for child in _run_host.get_children():
		_run_host.remove_child(child)


func _build_run_host() -> void:
	_run_host = Control.new()
	_run_host.name = "FullscreenRunHost"
	_run_host.visible = false
	_run_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_run_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_run_host)


func _on_run_page_request_debug() -> void:
	_show_page(PAGE_DEBUG)


func _on_run_page_request_return_to_menu() -> void:
	_show_landing()
